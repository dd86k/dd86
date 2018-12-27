/*
 * vcpu.d: core of x86 machine code interpreter.
 */

module vcpu;

import sleep;
import Logger : log_info;
import vcpu16 : exec16;
import vcpu_utils;
import compile_config : INIT_MEM, TSC_SLEEP;

/*enum : ubyte { // Emulated CPU
	CPU_8086,
	CPU_80486
}*/

/*enum : ubyte { // CPU Mode
	CPU_MODE_REAL,
	CPU_MODE_PROTECTED,
	CPU_MODE_VM8086,
	CPU_MODE_SMM
}*/

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

	RM_REG_000 = 0,	/// AL/AX
	RM_REG_001 = 8,	/// CL/CX
	RM_REG_010 = 16,	/// DL/DX
	RM_REG_011 = 24,	/// BL/BX
	RM_REG_100 = 32,	/// AH/SP
	RM_REG_101 = 40,	/// CH/BP
	RM_REG_110 = 48,	/// DH/SI
	RM_REG_111 = 56,	/// BH/DI
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

__gshared ubyte Seg; /// Preferred Segment register, defaults to SEG_NONE

/**
 * Runnning level.
 * Used to determine the "level of execution", such as the "deepness" of a program.
 * When a program terminates, RLEVEL is decreased.
 * If HLT is sent, RLEVEL is set to 0.
 * If RLEVEL reaches 0 (or lower), the emulator either stops, or returns to the virtual shell.
 * tl;dr: Emulates CALLs
 */
__gshared short RLEVEL = 1;
__gshared ubyte opt_sleep = 1; /// Is sleeping available to use? If so, use it

__gshared ubyte *MEMORY = void; /// Main memory bank

/**
 * Get the system's memory size in bytes.
 * This function retrieves from SYSTEM.memsize (BIOS+413h), which is in
 * kilobytes.
 * Returns: Memory size in bytes
 */
pragma(inline, true)
extern (C) public @property
int MEMORYSIZE() {
	import vdos : SYSTEM;
	return SYSTEM.memsize << 10;
}

/*
 * Code might be ugly, but:
 * - No more pointers to initialize and explicitly use
 * - Avoids calling pretty function (@property), uses MOV directly (x86)
 * - Alls major fields are initialized to 0 (.init) (.zero CPU_t.sizeof)
 */
extern (C) struct CPU_t {
	union {
		uint EIP;
		ushort IP;
	}
	union {
		uint EAX;
		ushort AX;
		struct { ubyte AL, AH; }
	}
	union {
		uint EBX;
		ushort BX;
		struct { ubyte BL, BH; }
	}
	union {
		uint ECX;
		ushort CX;
		struct { ubyte CL, CH; }
	}
	union {
		uint EDX;
		ushort DX;
		struct { ubyte DL, DH; }
	}
	union {
		uint ESI;
		ushort SI;
	}
	union {
		uint EDI;
		ushort DI;
	}
	union {
		uint EBP;
		ushort BP;
	}
	union {
		uint ESP;
		ushort SP;
	}
	ushort CS, SS, DS, ES, FS, GS;
	uint CR0, CR2, CR3;
	uint DR0, DR1, DR2, DR3, DR4, DR5, DR6, DR7;

	// Flags are bytes because single flags are affected a lot more often than
	// EFLAGS operations, e.g. PUSHDF.
	align(2):
	__gshared ubyte
	CF,	/// Bit  0, Carry Flag
	PF,	/// Bit  2, Parity Flag
	AF,	/// Bit  4, Auxiliary Flag (aka Half-carry Flag, Adjust Flag)
	ZF,	/// Bit  6, Zero Flag
	SF,	/// Bit  7, Sign Flag
	TF,	/// Bit  8, Trap Flag
	IF,	/// Bit  9, Interrupt Flag
	DF,	/// Bit 10, Direction Flag
	OF,	/// Bit 11, Overflow Flag
	// i486
	IOPL,	/// Bit 13:12, I/O Privilege Level
	NT,	/// Bit 14, Nested task Flag
	RF,	/// Bit 16, Resume Flag
	VM;	/// Bit 17, Virtual 8086 Mode
}

/// Main Central Processing Unit
public __gshared CPU_t CPU = void;

/// Initiate interpreter
extern (C)
void vcpu_init() {
	import core.stdc.stdlib : malloc;
	RESET;
	MEMORY = cast(ubyte*)malloc(INIT_MEM);
}

/// Start the emulator at CS:IP (usually 0000h:0100h)
extern (C)
void vcpu_run() {
	debug import Logger : logexec;

	//log_info("CALL vcpu_run");
	//uint tsc; /// tick count for thread sleeping purposes
	while (RLEVEL > 0) {
		CPU.EIP = get_ip; // CS:IP->EIP (important)
		//debug logexec(CPU.CS, CPU.IP, MEMORY[CPU.EIP]);
		exec16(MEMORY[CPU.EIP]);

		/*if (opt_sleep) { // TODO: Redo sleeping procedure (#20)
			++tsc;
			if (tsc == TSC_SLEEP) {
				SLEEP;
				tsc = 0;
			}
		}*/
	}
}

//TODO: step(ubyte) instead of incrementing EIP manually

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
	return get_ad(CPU.CS, CPU.IP);
}

/// (8086, 80486) RESET instruction function
extern (C)
private void RESET() {
	CPU.OF = CPU.DF = CPU.IF = CPU.TF = CPU.SF =
	CPU.ZF = CPU.AF = CPU.PF = CPU.CF = 0;
	CPU.CS = 0xFFFF;
	CPU.EIP = CPU.DS = CPU.SS = CPU.ES = 0;
	// Empty Queue Bus
}

/// Resets the entire vcpu. Does not refer to the RESET instruction!
extern (C)
void fullreset() {
	RESET;
	CPU.EAX = CPU.EBX = CPU.ECX = CPU.EDX =
	CPU.EBP = CPU.ESP = CPU.EDI = CPU.ESI = 0;
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
	ubyte b = 2; // bit 1 always set
	if (CPU.SF) b |= MASK_SF;
	if (CPU.ZF) b |= MASK_ZF;
	if (CPU.AF) b |= MASK_AF;
	if (CPU.PF) b |= MASK_PF;
	if (CPU.CF) b |= MASK_CF;
	return b;
}

/// Set FLAG as BYTE.
/// Params: flag = FLAG byte
@property void FLAGB(ubyte flag) {
	CPU.SF = flag & MASK_SF;
	CPU.ZF = flag & MASK_ZF;
	CPU.AF = flag & MASK_AF;
	CPU.PF = flag & MASK_PF;
	CPU.CF = flag & MASK_CF;
}

/**
 * Get FLAG as WORD.
 * Returns: FLAG (WORD)
 */
@property ushort FLAG() {
	ushort b = FLAGB;
	if (CPU.OF) b |= MASK_OF;
	if (CPU.DF) b |= MASK_DF;
	if (CPU.IF) b |= MASK_IF;
	if (CPU.TF) b |= MASK_TF;
	return b;
}

/// Set FLAG as WORD.
/// Params: flag = FLAG word
@property void FLAG(ushort flag) {
	CPU.OF = (flag & MASK_OF) != 0;
	CPU.DF = (flag & MASK_DF) != 0;
	CPU.IF = (flag & MASK_IF) != 0;
	CPU.TF = (flag & MASK_TF) != 0;
	FLAGB = cast(ubyte)flag;
}

/**********************************************************
 * STACK
 **********************************************************/

/**
 * Push a WORD value into stack.
 * Params: value = WORD value to PUSH
 */
extern (C)
void push16(ushort value) {
	CPU.SP -= 2; // decrement after push is 286+
	__iu16(value, get_ad(CPU.SS, CPU.SP));
}

/**
 * Pop a WORD value from stack.
 * Returns: WORD value
 */
extern (C)
ushort pop16() {
	const uint addr = get_ad(CPU.SS, CPU.SP);
	CPU.SP += 2;
	return __fu16(addr);
}

/**
 * Push a DWORD value into stack.
 * Params: value = DWORD value
 */
extern (C)
void push32(uint value) {
	CPU.SP -= 4;
	__iu32(value, get_ad(CPU.SS, CPU.SP));
}

/**
 * Pop a DWORD value from stack.
 * Returns: WORD value
 */
extern (C)
uint pop32() {
	const uint addr = get_ad(CPU.SS, CPU.SP);
	CPU.SP += 2;
	return __fu32(addr);
}