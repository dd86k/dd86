/**
 * Core of x86 machine code interpreter
 *
 * The virtual CPU module must initiated first.
 */
module vcpu.core;

import logger : log_info;
import vcpu.exec, vcpu.mm, vcpu.utils;
import config : INIT_MEM, FLAG_ALIGNMENT;

extern (C):
__gshared:

// Current CPU. So far only 8086 and 80486 are supported
enum : ubyte {
	CPU_8086,	/// Intel 8086/8088
	CPU_80286,	/// Intel i286
	CPU_80386,	/// Intel i386
	CPU_80486,	/// Intel i486 DX3
	CPU_PENTIUM	/// Intel Pentium
}

enum : ubyte { // Current CPU Mode
	CPU_MODE_REAL,	/// Read-address mode
	CPU_MODE_PROTECTED,	/// Protected mode
	CPU_MODE_VM8086,	/// 8086 Virtual Mode
	CPU_MODE_SMM,	/// System Management Mode
}

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
	RM_MOD_00 =   0,	/// MOD 00, Memory Mode, no displacement
	RM_MOD_01 =  64,	/// MOD 01, Memory Mode, 8-bit displacement
	RM_MOD_10 = 128,	/// MOD 10, Memory Mode, 16-bit displacement
	RM_MOD_11 = 192,	/// MOD 11, Register Mode
	RM_MOD = RM_MOD_11,	/// Used for masking the MOD bits (11 000 000)

	RM_REG_000 =  0,	/// AL/AX
	RM_REG_001 =  8,	/// CL/CX
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

/// Flag masks
private enum : uint {
	MASK_CF = 1,	/// Bit 0
	MASK_PF = 4,	/// Bit 2
	MASK_AF = 0x10,	/// Bit 4
	MASK_ZF = 0x40,	/// Bit 6
	MASK_SF = 0x80,	/// Bit 7
	MASK_TF = 0x100,	/// Bit 8
	MASK_IF = 0x200,	/// Bit 9
	MASK_DF = 0x400,	/// Bit 10
	MASK_OF = 0x800,	/// Bit 11

	// i286
	MASK_IOPL = 0x3000,	/// Bit 13:12
	MASK_NT   = 0x4000,	/// Bit 14

	// i386
	MASK_RF = 0x1_0000,	/// Bit 16
	MASK_VM = 0x2_0000,	/// Bit 17

	// CR0
	MASK_CR0_PE = 1,	/// Bit 0
	MASK_CR0_MP = 2,	/// Bit 1
	MASK_CR0_EM = 4,	/// Bit 2
	MASK_CR0_TS = 8,	/// Bit 3
	MASK_CR0_ET = 0x10,	/// Bit 4
	MASK_CR0_NE = 0x20,	/// Bit 5
	MASK_CR0_WP = 0x1_0000,	/// Bit 16
	MASK_CR0_AM = 0x4_0000,	/// Bit 18
	MASK_CR0_PG = 0x8000_0000, /// Bit 31

	// CR3
	MASK_CR3_PWT = 8,	/// Bit 3
	MASK_CR3_PCD = 0x10	/// Bit 4
}

/// CPU structure, represents one processing unit
struct CPU_t {
	union {
		uint EIP;	/// Extended Instruction Pointer
		ushort IP;	/// Instruction Pointer
	}
	union {
		uint EAX;	/// Extended Accumulator Register
		ushort AX;	/// Accumulator
		struct { ubyte AL, AH; }
	}
	union {
		uint EBX;	/// Extended Base Register
		ushort BX;	/// Base Register
		struct { ubyte BL, BH; }
	}
	union {
		uint ECX;	/// Extended Count Register
		ushort CX;	/// Count Register
		struct { ubyte CL, CH; }
	}
	union {
		uint EDX;	/// Extended Data Register
		ushort DX;	/// Data Register
		struct { ubyte DL, DH; }
	}
	union {
		uint ESI;	/// Extended Source Index
		ushort SI;	/// Source Index
	}
	union {
		uint EDI;	/// Extended Data Index
		ushort DI;	/// Data Index
	}
	union {
		uint EBP;	/// Extended Base Pointer
		ushort BP;	/// Base Pointer
	}
	union {
		uint ESP;	/// Extended Stack Pointer
		ushort SP;	/// Stack Pointer
	}
	ushort CS, SS, DS, ES, FS, GS;
	uint TR3, TR4, TR5, TR6, TR7;
	uint DR0, DR1, DR2, DR3, DR4, DR5, DR6, DR7;
	// CR0 and CR3 are function properties, and CR1 is never used
	uint CR2; /// Holds Page-Fault Linear Address
	uint PBDR;	/// Page Directory Base Register

	align(FLAG_ALIGNMENT) ubyte // CR0
	PE,	/// Bit  0, Protection Enable
	MP,	/// Bit  1, Math Present
	EM,	/// Bit  2, Emulation
	TS,	/// Bit  3, Task Switched
	ET,	/// Bit  4, Extension Type (for 387 DX math co-processor)
	NE,	/// Bit  5, Numeric Error
	WP,	/// Bit 16, Write Protect
	AM,	/// Bit 18, Alignement Mask
	NW,	/// Bit 29, No Write-through
	CD,	/// Bit 30, Cache Disable
	PG;	/// Bit 31, Paging bit

	align(FLAG_ALIGNMENT) ubyte // CR3
	PWT,	/// Bit 3, Page-level Writes Transparent
	PCD;	/// Bit 4, Page-level Cache Disable

	@property uint CR0() {
		//TODO: CR0
		return 0;
	}

	@property void CR0(uint r) {
		//TODO: CR0
	}

	@property uint CR3() {
		//TODO: CR3
		return 0;
	}

	@property void CR3(uint r) {
		//TODO: CR3
	}

	align(FLAG_ALIGNMENT) ubyte // EFLAGS
	CF,	/// Bit  0, Carry Flag
	PF,	/// Bit  2, Parity Flag
	AF,	/// Bit  4, Auxiliary Flag (aka Half-carry Flag, Adjust Flag)
	ZF,	/// Bit  6, Zero Flag
	SF,	/// Bit  7, Sign Flag
	TF,	/// Bit  8, Trap Flag
	IF,	/// Bit  9, Interrupt Flag
	DF,	/// Bit 10, Direction Flag
	OF,	/// Bit 11, Overflow Flag
	// i286
	IOPL,	/// Bit 13:12, I/O Privilege Level
	NT,	/// Bit 14, Nested task Flag
	// i386
	RF,	/// Bit 16, Resume Flag
	VM;	/// Bit 17, Virtual 8086 Mode

	//
	// CPU internals
	//

	/// Preferred Segment register, defaults to SEG_NONE
	ubyte Segment;
	/// Current operation mode, defaults to CPU_MODE_REAL
	ubyte Mode;
	/// Current execution level (ring)
	byte Ring;
	/// Elapsed cycles
	uint Cycles;

	/// Set if OPCODE PREFIX (66h) has been set
	ubyte Prefix_Operand;
	/// Set if ADDRESS PREFIX (67h) has been set
	ubyte Prefix_Address;
	/// LOCK prefix
	ubyte Lock;

	/// CPU model: 8086, 80486, etc.
	ubyte Model;
	/// Is sleeping available to use? If so, use it
	bool sleep = 1;

	/**
	 * Runnning level.
	 *
	 * Used to determine the "level of execution", such as the "deepness" of a program.
	 * When a program terminates, level is decreased.
	 * If HLT is sent, level is set to 0.
	 * If level reaches 0 (or lower), the emulator either stops, or returns to the
	 * virtual shell.
	 *
	 * tl;dr: Emulates CALLs
	 */
	short level = 1;

	extern (D):
	@property:

	/**
	* Get FLAG as BYTE.
	* Returns: FLAG as byte
	*/
	ubyte FLAG() {
		ubyte b = 2; // bit 1 always set
		if (SF) b |= MASK_SF;
		if (ZF) b |= MASK_ZF;
		if (AF) b |= MASK_AF;
		if (PF) b |= MASK_PF;
		if (CF) b |= MASK_CF;
		return b;
	}

	/**
	* Set FLAG as BYTE.
	* Params: flag = BYTE
	*/
	void FLAG(ubyte flag) {
		SF = flag & MASK_SF;
		ZF = flag & MASK_ZF;
		AF = flag & MASK_AF;
		PF = flag & MASK_PF;
		CF = flag & MASK_CF;
	}

	/**
	* Get FLAGS
	* Returns: WORD
	*/
	ushort FLAGS() {
		ushort b = CPU.FLAG;
		if (OF) b |= MASK_OF;
		if (DF) b |= MASK_DF;
		if (IF) b |= MASK_IF;
		if (TF) b |= MASK_TF;
		return b;
	}

	/// Set FLAGS
	/// Params: flag = WORD
	void FLAGS(ushort flag) {
		OF = (flag & MASK_OF) != 0;
		DF = (flag & MASK_DF) != 0;
		IF = (flag & MASK_IF) != 0;
		TF = (flag & MASK_TF) != 0;
		IOPL = (flag & MASK_IOPL) >> 12;
		NT = (flag & MASK_NT) != 0;
		FLAG = cast(ubyte)flag;
	}

	/**
	* Get EFLAGS as DWORD
	* Returns: DWORD
	*/
	uint EFLAGS() {
		uint b = CPU.FLAGS;
		if (RF) b |= MASK_RF;
		if (VM) b |= MASK_VM;
		return b;
	}

	/**
	* Set EFLAGS as DWORD
	* Params: flag = DWORD
	*/
	void EFLAGS(uint flag) {
		RF = (flag & MASK_RF) != 0;
		VM = (flag & MASK_VM) != 0;
		FLAGS = cast(ushort)flag;
	}
}

/// Machine int "type" with type aliases to avoid using explicit pointer use.
struct __mi32 { align(1):
	alias i32 this;
	union {
		uint u32;
		int  i32;
		ushort[2] u16;
		short[2]  i16;
		ubyte[4]  u8;
		byte[4]   i8;
	}
}

/// Main Central Processing Unit
public CPU_t CPU = void;
ubyte *MEM = void; /// Memory bank
int MEMSIZE = INIT_MEM; /// Memory size

/// Instructions function table
void function() [256]OPMAP;

/// Initiate virtual CPU
/// Params: cpu = CPU_t structure
void vcpu_init(ref CPU_t cpu = CPU) {
	import core.stdc.stdlib : realloc;
	MEM = cast(ubyte*)realloc(MEM, INIT_MEM); // in case of re-init
	cpu.CS = 0xFFFF;

	push16 = cpu.Model == CPU_8086 ? &push16a : &push16b;

	OPMAP[0x00] = &exec00;
	OPMAP[0x01] = &exec01;
	OPMAP[0x02] = &exec02;
	OPMAP[0x03] = &exec03;
	OPMAP[0x04] = &exec04;
	OPMAP[0x05] = &exec05;
	OPMAP[0x06] = &exec06;
	OPMAP[0x07] = &exec07;
	OPMAP[0x08] = &exec08;
	OPMAP[0x09] = &exec09;
	OPMAP[0x0A] = &exec0A;
	OPMAP[0x0B] = &exec0B;
	OPMAP[0x0C] = &exec0C;
	OPMAP[0x0D] = &exec0D;
	OPMAP[0x0E] = &exec0E;
	OPMAP[0x10] = &exec10;
	OPMAP[0x11] = &exec11;
	OPMAP[0x12] = &exec12;
	OPMAP[0x13] = &exec13;
	OPMAP[0x14] = &exec14;
	OPMAP[0x15] = &exec15;
	OPMAP[0x16] = &exec16;
	OPMAP[0x17] = &exec17;
	OPMAP[0x18] = &exec18;
	OPMAP[0x19] = &exec19;
	OPMAP[0x1A] = &exec1A;
	OPMAP[0x1B] = &exec1B;
	OPMAP[0x1C] = &exec1C;
	OPMAP[0x1D] = &exec1D;
	OPMAP[0x1E] = &exec1E;
	OPMAP[0x1F] = &exec1F;
	OPMAP[0x20] = &exec20;
	OPMAP[0x21] = &exec21;
	OPMAP[0x22] = &exec22;
	OPMAP[0x23] = &exec23;
	OPMAP[0x24] = &exec24;
	OPMAP[0x25] = &exec25;
	OPMAP[0x26] = &exec26;
	OPMAP[0x27] = &exec27;
	OPMAP[0x28] = &exec28;
	OPMAP[0x29] = &exec29;
	OPMAP[0x2A] = &exec2A;
	OPMAP[0x2B] = &exec2B;
	OPMAP[0x2C] = &exec2C;
	OPMAP[0x2D] = &exec2D;
	OPMAP[0x2E] = &exec2E;
	OPMAP[0x2F] = &exec2F;
	OPMAP[0x30] = &exec30;
	OPMAP[0x31] = &exec31;
	OPMAP[0x32] = &exec32;
	OPMAP[0x33] = &exec33;
	OPMAP[0x34] = &exec34;
	OPMAP[0x35] = &exec35;
	OPMAP[0x36] = &exec36;
	OPMAP[0x37] = &exec37;
	OPMAP[0x38] = &exec38;
	OPMAP[0x39] = &exec39;
	OPMAP[0x3A] = &exec3A;
	OPMAP[0x3B] = &exec3B;
	OPMAP[0x3C] = &exec3C;
	OPMAP[0x3D] = &exec3D;
	OPMAP[0x3E] = &exec3E;
	OPMAP[0x3F] = &exec3F;
	OPMAP[0x40] = &exec40;
	OPMAP[0x41] = &exec41;
	OPMAP[0x42] = &exec42;
	OPMAP[0x43] = &exec43;
	OPMAP[0x44] = &exec44;
	OPMAP[0x45] = &exec45;
	OPMAP[0x46] = &exec46;
	OPMAP[0x47] = &exec47;
	OPMAP[0x48] = &exec48;
	OPMAP[0x49] = &exec49;
	OPMAP[0x4A] = &exec4A;
	OPMAP[0x4B] = &exec4B;
	OPMAP[0x4C] = &exec4C;
	OPMAP[0x4D] = &exec4D;
	OPMAP[0x4E] = &exec4E;
	OPMAP[0x4F] = &exec4F;
	OPMAP[0x50] = &exec50;
	OPMAP[0x51] = &exec51;
	OPMAP[0x52] = &exec52;
	OPMAP[0x53] = &exec53;
	OPMAP[0x54] = &exec54;
	OPMAP[0x55] = &exec55;
	OPMAP[0x56] = &exec56;
	OPMAP[0x57] = &exec57;
	OPMAP[0x58] = &exec58;
	OPMAP[0x59] = &exec59;
	OPMAP[0x5A] = &exec5A;
	OPMAP[0x5B] = &exec5B;
	OPMAP[0x5C] = &exec5C;
	OPMAP[0x5D] = &exec5D;
	OPMAP[0x5E] = &exec5E;
	OPMAP[0x5F] = &exec5F;
	OPMAP[0x70] = &exec70;
	OPMAP[0x71] = &exec71;
	OPMAP[0x72] = &exec72;
	OPMAP[0x73] = &exec73;
	OPMAP[0x74] = &exec74;
	OPMAP[0x75] = &exec75;
	OPMAP[0x76] = &exec76;
	OPMAP[0x77] = &exec77;
	OPMAP[0x78] = &exec78;
	OPMAP[0x79] = &exec79;
	OPMAP[0x7A] = &exec7A;
	OPMAP[0x7B] = &exec7B;
	OPMAP[0x7C] = &exec7C;
	OPMAP[0x7D] = &exec7D;
	OPMAP[0x7E] = &exec7E;
	OPMAP[0x7F] = &exec7F;
	OPMAP[0x80] = &exec80;
	OPMAP[0x81] = &exec81;
	OPMAP[0x82] = &exec82;
	OPMAP[0x83] = &exec83;
	OPMAP[0x84] = &exec84;
	OPMAP[0x85] = &exec85;
	OPMAP[0x86] = &exec86;
	OPMAP[0x87] = &exec87;
	OPMAP[0x88] = &exec88;
	OPMAP[0x89] = &exec89;
	OPMAP[0x8A] = &exec8A;
	OPMAP[0x8B] = &exec8B;
	OPMAP[0x8C] = &exec8C;
	OPMAP[0x8D] = &exec8D;
	OPMAP[0x8E] = &exec8E;
	OPMAP[0x8F] = &exec8F;
	OPMAP[0x90] = &exec90;
	OPMAP[0x91] = &exec91;
	OPMAP[0x92] = &exec92;
	OPMAP[0x93] = &exec93;
	OPMAP[0x94] = &exec94;
	OPMAP[0x95] = &exec95;
	OPMAP[0x96] = &exec96;
	OPMAP[0x97] = &exec97;
	OPMAP[0x98] = &exec98;
	OPMAP[0x99] = &exec99;
	OPMAP[0x9A] = &exec9A;
	OPMAP[0x9B] = &exec9B;
	OPMAP[0x9C] = &exec9C;
	OPMAP[0x9D] = &exec9D;
	OPMAP[0x9E] = &exec9E;
	OPMAP[0x9F] = &exec9F;
	OPMAP[0xA0] = &execA0;
	OPMAP[0xA1] = &execA1;
	OPMAP[0xA2] = &execA2;
	OPMAP[0xA3] = &execA3;
	OPMAP[0xA4] = &execA4;
	OPMAP[0xA5] = &execA5;
	OPMAP[0xA6] = &execA6;
	OPMAP[0xA7] = &execA7;
	OPMAP[0xA8] = &execA8;
	OPMAP[0xA9] = &execA9;
	OPMAP[0xAA] = &execAA;
	OPMAP[0xAB] = &execAB;
	OPMAP[0xAC] = &execAC;
	OPMAP[0xAD] = &execAD;
	OPMAP[0xAE] = &execAE;
	OPMAP[0xAF] = &execAF;
	OPMAP[0xB0] = &execB0;
	OPMAP[0xB1] = &execB1;
	OPMAP[0xB2] = &execB2;
	OPMAP[0xB3] = &execB3;
	OPMAP[0xB4] = &execB4;
	OPMAP[0xB5] = &execB5;
	OPMAP[0xB6] = &execB6;
	OPMAP[0xB7] = &execB7;
	OPMAP[0xB8] = &execB8;
	OPMAP[0xB9] = &execB9;
	OPMAP[0xBA] = &execBA;
	OPMAP[0xBB] = &execBB;
	OPMAP[0xBC] = &execBC;
	OPMAP[0xBD] = &execBD;
	OPMAP[0xBE] = &execBE;
	OPMAP[0xBF] = &execBF;
	OPMAP[0xC2] = &execC2;
	OPMAP[0xC3] = &execC3;
	OPMAP[0xC4] = &execC4;
	OPMAP[0xC5] = &execC5;
	OPMAP[0xC6] = &execC6;
	OPMAP[0xC7] = &execC7;
	OPMAP[0xCA] = &execCA;
	OPMAP[0xCB] = &execCB;
	OPMAP[0xCC] = &execCC;
	OPMAP[0xCD] = &execCD;
	OPMAP[0xCE] = &execCE;
	OPMAP[0xCF] = &execCF;
	OPMAP[0xD0] = &execD0;
	OPMAP[0xD1] = &execD1;
	OPMAP[0xD2] = &execD2;
	OPMAP[0xD3] = &execD3;
	OPMAP[0xD4] = &execD4;
	OPMAP[0xD5] = &execD5;
	OPMAP[0xD7] = &execD7;
	OPMAP[0xE0] = &execE0;
	OPMAP[0xE1] = &execE1;
	OPMAP[0xE2] = &execE2;
	OPMAP[0xE3] = &execE3;
	OPMAP[0xE4] = &execE4;
	OPMAP[0xE5] = &execE5;
	OPMAP[0xE6] = &execE6;
	OPMAP[0xE7] = &execE7;
	OPMAP[0xE8] = &execE8;
	OPMAP[0xE9] = &execE9;
	OPMAP[0xEA] = &execEA;
	OPMAP[0xEB] = &execEB;
	OPMAP[0xEC] = &execEC;
	OPMAP[0xED] = &execED;
	OPMAP[0xEE] = &execEE;
	OPMAP[0xEF] = &execEF;
	OPMAP[0xF0] = &execF0;
	OPMAP[0xF2] = &execF2;
	OPMAP[0xF3] = &execF3;
	OPMAP[0xF4] = &execF4;
	OPMAP[0xF5] = &execF5;
	OPMAP[0xF6] = &execF6;
	OPMAP[0xF7] = &execF7;
	OPMAP[0xF8] = &execF8;
	OPMAP[0xF9] = &execF9;
	OPMAP[0xFA] = &execFA;
	OPMAP[0xFB] = &execFB;
	OPMAP[0xFC] = &execFC;
	OPMAP[0xFD] = &execFD;
	OPMAP[0xFE] = &execFE;
	OPMAP[0xFF] = &execFF;
	OPMAP[0xD6] =
	OPMAP[0xC8] =
	OPMAP[0xC9] =
	OPMAP[0x0F] =
	OPMAP[0xC0] =
	OPMAP[0xC1] =
	OPMAP[0xD8] =
	OPMAP[0xD9] =
	OPMAP[0xDA] =
	OPMAP[0xDB] =
	OPMAP[0xDC] =
	OPMAP[0xDD] =
	OPMAP[0xDE] =
	OPMAP[0xDF] =
	OPMAP[0xF1] = &execill;
	switch (cpu.Model) {
	case CPU_8086:
		// While it is possible to map a range, range sets rely on
		// memset32/64 which DMD linkers will not find
		for (size_t i = 0x60; i < 0x70; ++i)
			OPMAP[i] = &execill;
		break;
	case CPU_80486:
		OPMAP[0x60] =
		OPMAP[0x61] =
		OPMAP[0x62] =
		OPMAP[0x63] =
		OPMAP[0x64] =
		OPMAP[0x65] =
		OPMAP[0x68] =
		OPMAP[0x69] =
		OPMAP[0x6A] =
		OPMAP[0x6B] =
		OPMAP[0x6C] =
		OPMAP[0x6D] =
		OPMAP[0x6E] =
		OPMAP[0x6F] = &execill;
		OPMAP[0x66] = &exec66;
		OPMAP[0x67] = &exec67;
		break;
	default:
	}

	for (size_t i; i < 256; ++i) { // Sanity checker
		assert(OPMAP[i], "REAL_MAP missed spot");
	}
}

/// Start the emulator at CS:IP (default: FFFF:0000h)
/// Params: cpu = CPU reference (default: global CPU structure)
void vcpu_run(ref CPU_t cpu = CPU) {
	while (CPU.level > 0) {
		cpu.EIP = get_ip;
		const ubyte op = MEM[cpu.EIP];
		OPMAP[op]();
	}
}

//
// CPU utilities
//

/// Processor RESET function.
/// Does not empty queue bus, since it does not have one.
void reset(ref CPU_t cpu) {
	cpu.Mode = CPU_MODE_REAL;
	cpu.Segment = SEG_NONE;

	cpu.OF = cpu.DF = cpu.IF = cpu.TF = cpu.SF =
	cpu.ZF = cpu.AF = cpu.PF = cpu.CF =
	cpu.EIP = cpu.DS = cpu.SS = cpu.ES = 0;
	cpu.CS = 0xFFFF;
}

/// Resets the entire vcpu. Does not refer to the RESET instruction!
/// This sets all registers to 0. Segment is set to SEG_NONE, and Mode is set
/// to CPU_MODE_REAL. Useful in unittesting.
void fullreset(ref CPU_t cpu) {
	cpu = CPU_t();
}

/// WAIT suspends execution of instructions until the BUSY# pin is
/// inactive (high). The BUSY# pin is driven by the numeric processor
/// extension.
void wait(ref CPU_t cpu) {
	//TODO: CPU.wait()
}

/// Get segment register value from CPU.Segment.
/// Returns: Segment register value
ushort getseg(ref CPU_t cpu) {
	ushort s = void;
	switch (cpu.Segment) {
	case SEG_NONE:	s = 0;  break;
	case SEG_CS:	s = cpu.CS; break;
	case SEG_DS:	s = cpu.DS; break;
	case SEG_ES:	s = cpu.ES; break;
	case SEG_SS:	s = cpu.SS; break;
	case SEG_GS:	s = cpu.GS; break;
	case SEG_FS:	s = cpu.FS; break;
	default: assert(0, "Unknown segment type");
	}
	return s;
}

//
// Stack handling
//

/**
 * Push a WORD value into stack. Adjusts SP properly according to CPU
 * Model.
 */
void function(ref CPU_t, ushort) push16;

/**
 * Pop a WORD value from stack.
 * Returns: WORD value
 */
ushort pop16(ref CPU_t cpu) {
	const uint addr = address(cpu.SS, cpu.SP);
	cpu.SP += 2;
	return mmfu16(addr);
}

/**
 * Push a DWORD value into stack.
 * Params: value = DWORD value
 */
void push32(ref CPU_t cpu, uint value) {
	cpu.SP -= 4;
	mmiu32(value, address(cpu.SS, cpu.SP));
}

/**
 * Pop a DWORD value from stack.
 * Returns: DWORD value
 */
uint pop32(ref CPU_t cpu) {
	const uint addr = address(cpu.SS, cpu.SP);
	cpu.SP += 2;
	return mmfu32(addr);
}

private:

// 8086
void push16a(ref CPU_t cpu, ushort value) {
	cpu.SP -= 2;
	mmiu16(value, address(cpu.SS, cpu.SP));
}
// 8086+
void push16b(ref CPU_t cpu, ushort value) {
	mmiu16(value, address(cpu.SS, cpu.SP));
	cpu.SP -= 2;
}