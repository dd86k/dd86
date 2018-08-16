/*
 * vcpu.d: x86 machine code interpreter.
 */

module vcpu;

import sleep;
import Logger : info;
import vdos : Raise; // Interrupt handler
import vcpu_8086 : exec16;
import vcpu_utils;
import vcpu_config;

/*enum : ubyte { // Emulated CPU
	CPU_8086,
	CPU_80486
}*/

/*enum : ubyte { // CPU Mode
	CPU_MODE_REAL,
	CPU_MODE_PROTECTED,
	CPU_MODE_EXTENDED,
	// No LONG modes
}*/

/// Preferred Segment register
__gshared ubyte Seg;
enum : ubyte { // Segment override (for Seg)
	SEG_NONE,	/// None, default
	SEG_CS,	/// CS segment
	SEG_DS,	/// DS segment
	SEG_ES,	/// ES segment
	SEG_SS,	/// SS segment
	// i386
	SEG_FS,	/// FS segment
	SEG_GS	/// GS segment
}

enum : ubyte {
	RM_MOD_00 = 0,	/// MOD 00, Memory Mode, no displacement
	RM_MOD_01 = 64,	/// MOD 01, Memory Mode, 8-bit displacement
	RM_MOD_10 = 128,	/// MOD 10, Memory Mode, 16-bit displacement
	RM_MOD_11 = 192,	/// MOD 11, Register Mode
	RM_MOD = RM_MOD_11,	/// Used for masking the MOD bits (11 000 000)

	RM_REG_000 = 0,	/// vCPU.AL/vCPU.AX
	RM_REG_001 = 8,	/// vCPU.CL/vCPU.CX
	RM_REG_010 = 16,	/// vCPU.DL/vCPU.DX
	RM_REG_011 = 24,	/// vCPU.BL/vCPU.BX
	RM_REG_100 = 32,	/// vCPU.AH/vCPU.SP
	RM_REG_101 = 40,	/// vCPU.CH/vCPU.BP
	RM_REG_110 = 48,	/// vCPU.DH/vCPU.SI
	RM_REG_111 = 56,	/// vCPU.BH/vCPU.DI
	RM_REG = RM_REG_111,	/// Used for masking the REG bits (00 111 000)

	RM_RM_000 = 0,	/// R/M 000 bits
	RM_RM_001 = 1,	/// R/M 001 bits
	RM_RM_010 = 2,	/// R/M 010 bits
	RM_RM_011 = 3,	/// R/M 011 bits
	RM_RM_100 = 4,	/// R/M 100 bits
	RM_RM_101 = 5,	/// R/M 101 bits
	RM_RM_110 = 6,	/// R/M 110 bits
	RM_RM_111 = 7,	/// R/M 111 bits
	RM_RM = RM_RM_111,	/// Used for masking the R/M bits (00 000 111)
}

/**
 * Runnning level.
 * Used to determine the "level of execution", such as the "deepness" of a program.
 * When a program terminates, RLEVEL is decreased.
 * If HLT is sent, RLEVEL is set to 0, and the emulator stops.
 * If RLEVEL reaches 0, the emulator either stops, or returns to the virtual shell.
 * tl;dr: Emulates CALLs
 */
__gshared short RLEVEL = 1;
__gshared ubyte opt_sleep = 1; /// If set, the vcpu sleeps

enum MEMORY_P = cast(ubyte*)MEMORY; /// Memory pointer enum to avoid explicit casting
__gshared ubyte[INIT_MEM] MEMORY; /// Main memory bank
__gshared uint MEMORYSIZE = INIT_MEM; /// Current memory MEMORY size

/*
 * Code might be ugly, but:
 * - No more pointers to initialize and explicitly use
 * - Avoids calling pretty function (@property), uses MOV directly (x86)
 * - Alls major fields are initialized to 0 (.init) (.zero __CPU.sizeof)
 */
extern (C) struct __CPU {
	union {
		uint EIP;
		union { ushort IP; }
	}
	union {
		uint EAX;
		union {
			ushort AX;
			union { struct { ubyte AL, AH; } }
		}
	}
	union {
		uint EBX;
		union {
			ushort BX;
			union { struct { ubyte BL, BH; } }
		}
	}
	union {
		uint ECX;
		union {
			ushort CX;
			union { struct { ubyte CL, CH; } }
		}
	}
	union {
		uint EDX;
		union {
			ushort DX;
			union { struct { ubyte DL, DH; } }
		}
	}
	union {
		uint ESI;
		union { ushort SI; }
	}
	union {
		uint EDI;
		union { ushort DI; }
	}
	union {
		uint EBP;
		union { ushort BP; }
	}
	union {
		uint ESP;
		union { ushort SP; }
	}
	ushort CS, SS, DS, ES, FS, GS;

	// Flags are bytes because single flags are affected a lot more often than
	// flag-whole operations, like PUSHF.
	__gshared ubyte
	CF, /// Bit  0, Carry Flag
	PF, /// Bit  2, Parity Flag
	AF, /// Bit  4, Auxiliary Flag (aka Half-carry Flag, Adjust Flag)
	ZF, /// Bit  6, Zero Flag
	SF, /// Bit  7, Sign Flag
	TF, /// Bit  8, Trap Flag
	IF, /// Bit  9, Interrupt Flag
	DF, /// Bit 10, Direction Flag
	OF; /// Bit 11, Overflow Flag
}

public __gshared __CPU vCPU;

/// Initiate interpreter
extern (C)
void vcpu_init() {
	SLEEP_SET;
	//RESET;
}

/// Start the emulator at CS:IP (usually 0000h:0100h)
extern (C)
void vcpu_run() {
	debug import Logger : logexec;

	info("CALL vcpu_run");
	uint tsc; /// tick count for thread sleeping purposes
	while (RLEVEL > 0) {
		vCPU.EIP = get_ip; // CS:IP->EIP (important)
		debug logexec(vCPU.CS, vCPU.IP, MEMORY[vCPU.EIP]);
		exec16(MEMORY[vCPU.EIP]);

		if (opt_sleep) { // TODO: Redo sleeping procedure (#20)
			++tsc;
			if (tsc == TSC_SLEEP) {
				SLEEP;
				tsc = 0;
			}
		}
	}
}

/**
 * Get memory address out of a segment and a register value.
 * Params:
 *   s = Segment register value
 *   o = Generic register value
 * Returns: SEG:ADDR Location
 */
extern (C)
pragma(inline, true)
uint get_ad(int s, int o) {
	return (s << 4) + o;
}

/**
 * (8086) Get next instruction location
 * Returns: CS:IP effective address
 */
extern (C)
pragma(inline, true)
uint get_ip() {
	return get_ad(vCPU.CS, vCPU.IP);
}

/// (8086, 80486) RESET instruction function
extern (C)
private void RESET() {
	vCPU.OF = vCPU.DF = vCPU.IF = vCPU.TF = vCPU.SF =
	vCPU.ZF = vCPU.AF = vCPU.PF = vCPU.CF = 0;
	vCPU.CS = 0xFFFF;
	vCPU.EIP = vCPU.DS = vCPU.SS = vCPU.ES = 0;
	// Empty Queue Bus
}

/// Resets the entire vcpu. Does not refer to the RESET instruction!
extern (C)
void fullreset() {
	RESET;
	vCPU.EAX = vCPU.EBX = vCPU.ECX = vCPU.EDX =
	vCPU.EBP = vCPU.ESP = vCPU.EDI = vCPU.ESI = 0;
}

/**********************************************************
 * FLAGS
 **********************************************************/

/// Flag mask
private enum : ushort {
	MASK_CF = 1,
	MASK_PF = 4,
	MASK_AF = 0x10,
	MASK_ZF = 0x40,
	MASK_SF = 0x80,
	MASK_TF = 0x100,
	MASK_IF = 0x200,
	MASK_DF = 0x400,
	MASK_OF = 0x800
	// i486
}

/**
 * Get FLAG as WORD.
 * Returns: FLAG as byte
 */
@property ubyte FLAGB() {
	ubyte b;
	if (vCPU.SF) b |= MASK_SF;
	if (vCPU.ZF) b |= MASK_ZF;
	if (vCPU.AF) b |= MASK_AF;
	if (vCPU.PF) b |= MASK_PF;
	if (vCPU.CF) b |= MASK_CF;
	return b;
}

/// Set FLAG as BYTE.
/// Params: flag = FLAG byte
@property void FLAGB(ubyte flag) {
	vCPU.SF = flag & MASK_SF;
	vCPU.ZF = flag & MASK_ZF;
	vCPU.AF = flag & MASK_AF;
	vCPU.PF = flag & MASK_PF;
	vCPU.CF = flag & MASK_CF;
}

/**
 * Get FLAG as WORD.
 * Returns: FLAG (WORD)
 */
@property ushort FLAG() {
	ushort b = FLAGB;
	if (vCPU.OF) b |= MASK_OF;
	if (vCPU.DF) b |= MASK_DF;
	if (vCPU.IF) b |= MASK_IF;
	if (vCPU.TF) b |= MASK_TF;
	return b;
}

/// Set FLAG as WORD.
/// Params: flag = FLAG word
@property void FLAG(ushort flag) {
	vCPU.OF = (flag & MASK_OF) != 0;
	vCPU.DF = (flag & MASK_DF) != 0;
	vCPU.IF = (flag & MASK_IF) != 0;
	vCPU.TF = (flag & MASK_TF) != 0;
	FLAGB = cast(ubyte)flag;
}

/**********************************************************
 * STACK
 **********************************************************/

/**
 * (8086) Push a WORD value into stack.
 * Params: value = WORD value to PUSH
 */
extern (C)
void push16(ushort value) {
	vCPU.SP = cast(ushort)(vCPU.SP - 2);
	__iu16(value, get_ad(vCPU.SS, vCPU.SP));
}

/**
 * (8086) Pop a WORD value from stack.
 * Returns: WORD value
 */
extern (C)
ushort pop16() {
	const uint addr = get_ad(vCPU.SS, vCPU.SP);
	vCPU.SP = cast(ushort)(vCPU.SP + 2);
	return __fu16(addr);
}

/**
 * (80486) Push a DWORD value into stack.
 * Params: value = DWORD value
 */
extern (C)
void push32(uint value) {
	vCPU.SP = cast(ushort)(vCPU.SP - 4);
	__iu32(value, get_ad(vCPU.SS, vCPU.SP));
}

/**
 * (80486) Pop a DWORD value from stack.
 * Returns: WORD value
 */
extern (C)
uint pop32() {
	const uint addr = get_ad(vCPU.SS, vCPU.SP);
	vCPU.SP = cast(ushort)(vCPU.SP + 4);
	return __fu32(addr);
}