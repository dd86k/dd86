/**
 * Core of x86 machine code interpreter
 *
 * The virtual CPU module must initiated first.
 */
module vcpu.core;

import logger : log_info;
import vcpu.v16, vcpu.v32, vcpu.mm, vcpu.utils;
import appconfig : INIT_MEM, TSC_SLEEP;

extern (C):
nothrow:

// Current CPU. So far only 8086 and 80486 are supported
enum : ubyte {
	CPU_8086,
	CPU_80286,
	CPU_80386,
	CPU_80486,
	CPU_PENTIUM
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
	MASK_CF = 1,
	MASK_PF = 4,
	MASK_AF = 0x10,
	MASK_ZF = 0x40,
	MASK_SF = 0x80,
	MASK_TF = 0x100,
	MASK_IF = 0x200,
	MASK_DF = 0x400,
	MASK_OF = 0x800,
	// i286
	MASK_IOPL = 0x3000, // Bit 13:12
	MASK_NT = 0x4000, // Bit 14
	// i386
	MASK_RF = 0x1_0000, // Bit 16
	MASK_VM = 0x2_0000 // Bit 17
}

/// CPU structure
struct CPU_t { extern (C): nothrow:
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
	uint CR0, CR1, CR2, CR3;
	uint DR0, DR1, DR2, DR3, DR4, DR5, DR6, DR7;

	// Flags are bytes because single flags are affected a lot more often than
	// whole CPU.FLAG operations, e.g. PUSHDF.
	align(2) ubyte
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

	/// Preferred Segment register, defaults to SEG_NONE
	ubyte Segment;
	/// Current operation mode, defaults to CPU_MODE_REAL
	ubyte Mode;
	/// Set if OPCODE PREFIX (66h) has been set
	ubyte Prefix_Operand;
	/// Set if ADDRESS PREFIX (67h) has been set
	ubyte Prefix_Address;
	/// CPU model: 8086, 80486, etc.
	ubyte Model;

	//TODO: step(ubyte bytes = 1, ushort time = 0)

	//
	// Stack handling
	//

	/**
	* (8086) Push a WORD value into stack.
	* Params: value = WORD value to PUSH
	*/
	void push16(ushort value) {
		CPU.SP -= 2;
		mmiu16(value, address(CPU.SS, CPU.SP));
	}

	/**
	* (80206+) Push a WORD value into stack.
	* Params: value = WORD value to PUSH
	*/
	void push16a(ushort value) {
		mmiu16(value, address(CPU.SS, CPU.SP));
		CPU.SP -= 2;
	}

	/**
	* Pop a WORD value from stack.
	* Returns: WORD value
	*/
	ushort pop16() {
		const uint addr = address(CPU.SS, CPU.SP);
		CPU.SP += 2;
		return mmfu16(addr);
	}

	/**
	* Push a DWORD value into stack.
	* Params: value = DWORD value
	*/
	void push32(uint value) {
		CPU.SP -= 4;
		mmiu32(value, address(CPU.SS, CPU.SP));
	}

	/**
	* Pop a DWORD value from stack.
	* Returns: WORD value
	*/
	uint pop32() {
		const uint addr = address(CPU.SS, CPU.SP);
		CPU.SP += 2;
		return mmfu32(addr);
	}

	extern (D):
	@property:

	/**
	* Get CPU.FLAG as WORD.
	* Returns: CPU.FLAG as byte
	*/
	ubyte FLAGB() {
		ubyte b = 2; // bit 1 always set
		if (CPU.SF) b |= MASK_SF;
		if (CPU.ZF) b |= MASK_ZF;
		if (CPU.AF) b |= MASK_AF;
		if (CPU.PF) b |= MASK_PF;
		if (CPU.CF) b |= MASK_CF;
		return b;
	}

	/// Set CPU.FLAG as BYTE.
	/// Params: flag = CPU.FLAG byte
	void FLAGB(ubyte flag) {
		CPU.SF = flag & MASK_SF;
		CPU.ZF = flag & MASK_ZF;
		CPU.AF = flag & MASK_AF;
		CPU.PF = flag & MASK_PF;
		CPU.CF = flag & MASK_CF;
	}

	/**
	* Get CPU.FLAG as WORD.
	* Returns: CPU.FLAG (WORD)
	*/
	ushort FLAG() {
		ushort b = CPU.FLAGB;
		if (CPU.OF) b |= MASK_OF;
		if (CPU.DF) b |= MASK_DF;
		if (CPU.IF) b |= MASK_IF;
		if (CPU.TF) b |= MASK_TF;
		return b;
	}

	/// Set CPU.FLAG as WORD.
	/// Params: flag = CPU.FLAG word
	void FLAG(ushort flag) {
		CPU.OF = (flag & MASK_OF) != 0;
		CPU.DF = (flag & MASK_DF) != 0;
		CPU.IF = (flag & MASK_IF) != 0;
		CPU.TF = (flag & MASK_TF) != 0;
		CPU.IOPL = (flag & MASK_IOPL) >> 12;
		CPU.NT = (flag & MASK_NT) != 0;
		CPU.FLAGB = cast(ubyte)flag;
	}

	/**
	* Get ECPU.FLAG as DWORD.
	* Returns: ECPU.FLAG (DWORD)
	*/
	uint EFLAG() {
		uint b = CPU.FLAG;
		if (CPU.RF) b |= MASK_RF;
		if (CPU.VM) b |= MASK_VM;
		return b;
	}

	/// Set ECPU.FLAG as DWORD.
	/// Params: flag = ECPU.FLAG dword
	void EFLAG(uint flag) {
		CPU.RF = (flag & MASK_RF) != 0;
		CPU.VM = (flag & MASK_VM) != 0;
		CPU.FLAG = cast(ushort)flag;
	}
}

static assert(__traits(isPOD, CPU_t));

/// Main Central Processing Unit
public __gshared CPU_t CPU = void;

/**
 * Runnning level.
 *
 * Used to determine the "level of execution", such as the "deepness" of a program.
 * When a program terminates, RLEVEL is decreased.
 * If HLT is sent, RLEVEL is set to 0.
 * If RLEVEL reaches 0 (or lower), the emulator either stops, or returns to the
 * virtual shell.
 *
 * tl;dr: Emulates CALLs
 */
__gshared short RLEVEL = 1;
__gshared ubyte opt_sleep = 1; /// Is sleeping available to use? If so, use it
__gshared ubyte *MEMORY = void; /// Memory bank
__gshared int MEMORYSIZE = INIT_MEM; /// Memory size

/// CPU Mode function table
//TODO: Consider going for switch/case for mode
__gshared void function(ubyte) [4]MODE_MAP;
/// Real-mode instructions function table
__gshared void function() [256]REAL_MAP;
/// Protected-mode instructions function table
__gshared void function() [256]PROT_MAP;

/// Initiate x86 interpreter
void vcpu_init() {
	import core.stdc.stdlib : realloc;
	MEMORY = cast(ubyte*)realloc(MEMORY, INIT_MEM); // in case of re-init
	CPU.CS = 0xFFFF;

	MODE_MAP[CPU_MODE_REAL] = &exec16;
	REAL_MAP[0x00] = &v16_00;
	REAL_MAP[0x01] = &v16_01;
	REAL_MAP[0x02] = &v16_02;
	REAL_MAP[0x03] = &v16_03;
	REAL_MAP[0x04] = &v16_04;
	REAL_MAP[0x05] = &v16_05;
	REAL_MAP[0x06] = &v16_06;
	REAL_MAP[0x07] = &v16_07;
	REAL_MAP[0x08] = &v16_08;
	REAL_MAP[0x09] = &v16_09;
	REAL_MAP[0x0A] = &v16_0A;
	REAL_MAP[0x0B] = &v16_0B;
	REAL_MAP[0x0C] = &v16_0C;
	REAL_MAP[0x0D] = &v16_0D;
	REAL_MAP[0x0E] = &v16_0E;
	REAL_MAP[0x0F] = &v16_illegal;
	REAL_MAP[0x10] = &v16_10;
	REAL_MAP[0x11] = &v16_11;
	REAL_MAP[0x12] = &v16_12;
	REAL_MAP[0x13] = &v16_13;
	REAL_MAP[0x14] = &v16_14;
	REAL_MAP[0x15] = &v16_15;
	REAL_MAP[0x16] = &v16_16;
	REAL_MAP[0x17] = &v16_17;
	REAL_MAP[0x18] = &v16_18;
	REAL_MAP[0x19] = &v16_19;
	REAL_MAP[0x1A] = &v16_1A;
	REAL_MAP[0x1B] = &v16_1B;
	REAL_MAP[0x1C] = &v16_1C;
	REAL_MAP[0x1D] = &v16_1D;
	REAL_MAP[0x1E] = &v16_1E;
	REAL_MAP[0x1F] = &v16_1F;
	REAL_MAP[0x20] = &v16_20;
	REAL_MAP[0x21] = &v16_21;
	REAL_MAP[0x22] = &v16_22;
	REAL_MAP[0x23] = &v16_23;
	REAL_MAP[0x24] = &v16_24;
	REAL_MAP[0x25] = &v16_25;
	REAL_MAP[0x26] = &v16_26;
	REAL_MAP[0x27] = &v16_27;
	REAL_MAP[0x28] = &v16_28;
	REAL_MAP[0x29] = &v16_29;
	REAL_MAP[0x2A] = &v16_2A;
	REAL_MAP[0x2B] = &v16_2B;
	REAL_MAP[0x2C] = &v16_2C;
	REAL_MAP[0x2D] = &v16_2D;
	REAL_MAP[0x2E] = &v16_2E;
	REAL_MAP[0x2F] = &v16_2F;
	REAL_MAP[0x30] = &v16_30;
	REAL_MAP[0x31] = &v16_31;
	REAL_MAP[0x32] = &v16_32;
	REAL_MAP[0x33] = &v16_33;
	REAL_MAP[0x34] = &v16_34;
	REAL_MAP[0x35] = &v16_35;
	REAL_MAP[0x36] = &v16_36;
	REAL_MAP[0x37] = &v16_37;
	REAL_MAP[0x38] = &v16_38;
	REAL_MAP[0x39] = &v16_39;
	REAL_MAP[0x3A] = &v16_3A;
	REAL_MAP[0x3B] = &v16_3B;
	REAL_MAP[0x3C] = &v16_3C;
	REAL_MAP[0x3D] = &v16_3D;
	REAL_MAP[0x3E] = &v16_3E;
	REAL_MAP[0x3F] = &v16_3F;
	REAL_MAP[0x40] = &v16_40;
	REAL_MAP[0x41] = &v16_41;
	REAL_MAP[0x42] = &v16_42;
	REAL_MAP[0x43] = &v16_43;
	REAL_MAP[0x44] = &v16_44;
	REAL_MAP[0x45] = &v16_45;
	REAL_MAP[0x46] = &v16_46;
	REAL_MAP[0x47] = &v16_47;
	REAL_MAP[0x48] = &v16_48;
	REAL_MAP[0x49] = &v16_49;
	REAL_MAP[0x4A] = &v16_4A;
	REAL_MAP[0x4B] = &v16_4B;
	REAL_MAP[0x4C] = &v16_4C;
	REAL_MAP[0x4D] = &v16_4D;
	REAL_MAP[0x4E] = &v16_4E;
	REAL_MAP[0x4F] = &v16_4F;
	REAL_MAP[0x50] = &v16_50;
	REAL_MAP[0x51] = &v16_51;
	REAL_MAP[0x52] = &v16_52;
	REAL_MAP[0x53] = &v16_53;
	REAL_MAP[0x54] = &v16_54;
	REAL_MAP[0x55] = &v16_55;
	REAL_MAP[0x56] = &v16_56;
	REAL_MAP[0x57] = &v16_57;
	REAL_MAP[0x58] = &v16_58;
	REAL_MAP[0x59] = &v16_59;
	REAL_MAP[0x5A] = &v16_5A;
	REAL_MAP[0x5B] = &v16_5B;
	REAL_MAP[0x5C] = &v16_5C;
	REAL_MAP[0x5D] = &v16_5D;
	REAL_MAP[0x5E] = &v16_5E;
	REAL_MAP[0x5F] = &v16_illegal;
	REAL_MAP[0x70] = &v16_70;
	REAL_MAP[0x71] = &v16_71;
	REAL_MAP[0x72] = &v16_72;
	REAL_MAP[0x73] = &v16_73;
	REAL_MAP[0x74] = &v16_74;
	REAL_MAP[0x75] = &v16_75;
	REAL_MAP[0x76] = &v16_76;
	REAL_MAP[0x77] = &v16_77;
	REAL_MAP[0x78] = &v16_78;
	REAL_MAP[0x79] = &v16_79;
	REAL_MAP[0x7A] = &v16_7A;
	REAL_MAP[0x7B] = &v16_7B;
	REAL_MAP[0x7C] = &v16_7C;
	REAL_MAP[0x7D] = &v16_7D;
	REAL_MAP[0x7E] = &v16_7E;
	REAL_MAP[0x7F] = &v16_7F;
	REAL_MAP[0x80] = &v16_80;
	REAL_MAP[0x81] = &v16_81;
	REAL_MAP[0x82] = &v16_82;
	REAL_MAP[0x83] = &v16_83;
	REAL_MAP[0x84] = &v16_84;
	REAL_MAP[0x85] = &v16_85;
	REAL_MAP[0x86] = &v16_86;
	REAL_MAP[0x87] = &v16_87;
	REAL_MAP[0x88] = &v16_88;
	REAL_MAP[0x89] = &v16_89;
	REAL_MAP[0x8A] = &v16_8A;
	REAL_MAP[0x8B] = &v16_8B;
	REAL_MAP[0x8C] = &v16_8C;
	REAL_MAP[0x8D] = &v16_8D;
	REAL_MAP[0x8E] = &v16_8E;
	REAL_MAP[0x8F] = &v16_8F;
	REAL_MAP[0x90] = &v16_90;
	REAL_MAP[0x91] = &v16_91;
	REAL_MAP[0x92] = &v16_92;
	REAL_MAP[0x93] = &v16_93;
	REAL_MAP[0x94] = &v16_94;
	REAL_MAP[0x95] = &v16_95;
	REAL_MAP[0x96] = &v16_96;
	REAL_MAP[0x97] = &v16_97;
	REAL_MAP[0x98] = &v16_98;
	REAL_MAP[0x99] = &v16_99;
	REAL_MAP[0x9A] = &v16_9A;
	REAL_MAP[0x9B] = &v16_9B;
	REAL_MAP[0x9C] = &v16_9C;
	REAL_MAP[0x9D] = &v16_9D;
	REAL_MAP[0x9E] = &v16_9E;
	REAL_MAP[0x9F] = &v16_9F;
	REAL_MAP[0xA0] = &v16_A0;
	REAL_MAP[0xA1] = &v16_A1;
	REAL_MAP[0xA2] = &v16_A2;
	REAL_MAP[0xA3] = &v16_A3;
	REAL_MAP[0xA4] = &v16_A4;
	REAL_MAP[0xA5] = &v16_A5;
	REAL_MAP[0xA6] = &v16_A6;
	REAL_MAP[0xA7] = &v16_A7;
	REAL_MAP[0xA8] = &v16_A8;
	REAL_MAP[0xA9] = &v16_A9;
	REAL_MAP[0xAA] = &v16_AA;
	REAL_MAP[0xAB] = &v16_AB;
	REAL_MAP[0xAC] = &v16_AC;
	REAL_MAP[0xAD] = &v16_AD;
	REAL_MAP[0xAE] = &v16_AE;
	REAL_MAP[0xAF] = &v16_AF;
	REAL_MAP[0xB0] = &v16_B0;
	REAL_MAP[0xB1] = &v16_B1;
	REAL_MAP[0xB2] = &v16_B2;
	REAL_MAP[0xB3] = &v16_B3;
	REAL_MAP[0xB4] = &v16_B4;
	REAL_MAP[0xB5] = &v16_B5;
	REAL_MAP[0xB6] = &v16_B6;
	REAL_MAP[0xB7] = &v16_B7;
	REAL_MAP[0xB8] = &v16_B8;
	REAL_MAP[0xB9] = &v16_B9;
	REAL_MAP[0xBA] = &v16_BA;
	REAL_MAP[0xBB] = &v16_BB;
	REAL_MAP[0xBC] = &v16_BC;
	REAL_MAP[0xBD] = &v16_BD;
	REAL_MAP[0xBE] = &v16_BE;
	REAL_MAP[0xBF] = &v16_BF;
	REAL_MAP[0xC0] = &v16_illegal;
	REAL_MAP[0xC1] = &v16_illegal;
	REAL_MAP[0xC2] = &v16_C2;
	REAL_MAP[0xC3] = &v16_C3;
	REAL_MAP[0xC4] = &v16_C4;
	REAL_MAP[0xC5] = &v16_C5;
	REAL_MAP[0xC6] = &v16_C6;
	REAL_MAP[0xC7] = &v16_C7;
	REAL_MAP[0xC8] = &v16_illegal;
	REAL_MAP[0xC9] = &v16_illegal;
	REAL_MAP[0xCA] = &v16_CA;
	REAL_MAP[0xCB] = &v16_CB;
	REAL_MAP[0xCC] = &v16_CC;
	REAL_MAP[0xCD] = &v16_CD;
	REAL_MAP[0xCE] = &v16_CE;
	REAL_MAP[0xCF] = &v16_CF;
	REAL_MAP[0xD0] = &v16_D0;
	REAL_MAP[0xD1] = &v16_D1;
	REAL_MAP[0xD2] = &v16_D2;
	REAL_MAP[0xD3] = &v16_D3;
	REAL_MAP[0xD4] = &v16_D4;
	REAL_MAP[0xD5] = &v16_D5;
	REAL_MAP[0xD6] = &v16_illegal;
	REAL_MAP[0xD7] = &v16_D7;
	REAL_MAP[0xD8] = &v16_illegal;
	REAL_MAP[0xD9] = &v16_illegal;
	REAL_MAP[0xDA] = &v16_illegal;
	REAL_MAP[0xDB] = &v16_illegal;
	REAL_MAP[0xDC] = &v16_illegal;
	REAL_MAP[0xDD] = &v16_illegal;
	REAL_MAP[0xDE] = &v16_illegal;
	REAL_MAP[0xDF] = &v16_illegal;
	REAL_MAP[0xE0] = &v16_E0;
	REAL_MAP[0xE1] = &v16_E1;
	REAL_MAP[0xE2] = &v16_E2;
	REAL_MAP[0xE3] = &v16_E3;
	REAL_MAP[0xE4] = &v16_E4;
	REAL_MAP[0xE5] = &v16_E5;
	REAL_MAP[0xE6] = &v16_E6;
	REAL_MAP[0xE7] = &v16_E7;
	REAL_MAP[0xE8] = &v16_E8;
	REAL_MAP[0xE9] = &v16_E9;
	REAL_MAP[0xEA] = &v16_EA;
	REAL_MAP[0xEB] = &v16_EB;
	REAL_MAP[0xEC] = &v16_EC;
	REAL_MAP[0xED] = &v16_ED;
	REAL_MAP[0xEE] = &v16_EE;
	REAL_MAP[0xEF] = &v16_EF;
	REAL_MAP[0xF0] = &v16_F0;
	REAL_MAP[0xF1] = &v16_illegal;
	REAL_MAP[0xF2] = &v16_F2;
	REAL_MAP[0xF3] = &v16_F3;
	REAL_MAP[0xF4] = &v16_F4;
	REAL_MAP[0xF5] = &v16_F5;
	REAL_MAP[0xF6] = &v16_F6;
	REAL_MAP[0xF7] = &v16_F7;
	REAL_MAP[0xF8] = &v16_F8;
	REAL_MAP[0xF9] = &v16_F9;
	REAL_MAP[0xFA] = &v16_FA;
	REAL_MAP[0xFB] = &v16_FB;
	REAL_MAP[0xFC] = &v16_FC;
	REAL_MAP[0xFD] = &v16_FD;
	REAL_MAP[0xFE] = &v16_FE;
	REAL_MAP[0xFF] = &v16_FF;
	switch (CPU.Model) {
	case CPU_8086:
		// While it is possible to map a range, range sets relie on
		// memset32/64 which DMD linkers will not find
		for (size_t i = 0x60; i < 0x70; ++i)
			REAL_MAP[i] = &v16_illegal;
		break;
	case CPU_80486:
		MODE_MAP[CPU_MODE_PROTECTED] = &exec32;
		//REAL_MAP[0x60] =
		//REAL_MAP[0x61] =
		//REAL_MAP[0x62] =
		//REAL_MAP[0x63] =
		//REAL_MAP[0x64] =
		//REAL_MAP[0x65] =
		REAL_MAP[0x66] = &v16_66;
		//REAL_MAP[0x67] =
		//REAL_MAP[0x68] =
		//REAL_MAP[0x69] =
		//REAL_MAP[0x6A] =
		//REAL_MAP[0x6B] =
		//REAL_MAP[0x6C] =
		//REAL_MAP[0x6D] =
		//REAL_MAP[0x6E] =
		//REAL_MAP[0x6F] =
		break;
	default:
	}

	for (size_t i; i < 256; ++i) { // Sanity checker
		import core.stdc.stdio : printf;
		import core.stdc.stdlib : exit;
		if (REAL_MAP[i] == null) {
			printf("Assert: REAL_MAP[%02Xh] is NULL!\n", i);
			exit(1);
		}
		/*if (PROT_MAP[i] == null) {
			printf("Assert: PROT_MAP[%02Xh] is NULL!\n", i);
			exit(1);
		}*/
	}
}

/// Start the emulator at CS:IP (default: FFFF:0000h)
void vcpu_run() {
	const int sleep = opt_sleep;
	while (RLEVEL > 0) {
		CPU.EIP = get_ip;
		const ubyte op = MEMORY[CPU.EIP];
		MODE_MAP[CPU.Mode](op);
	}
}

//
// CPU utilities
//

/// Processor RESET function
private void RESET() {
	CPU.Mode = CPU_MODE_REAL;
	CPU.Segment = SEG_NONE;

	CPU.OF = CPU.DF = CPU.IF = CPU.TF = CPU.SF =
	CPU.ZF = CPU.AF = CPU.PF = CPU.CF = 0;
	CPU.CS = 0xFFFF;
	CPU.EIP = CPU.DS = CPU.SS = CPU.ES = 0;
	// Empty Queue Bus
}

/// Resets the entire vcpu. Does not refer to the RESET instruction!
/// This sets all registers to 0. Segment is set to SEG_NONE, and Mode is set
/// to CPU_MODE_REAL. Useful in unittesting.
void fullreset() {
	CPU = CPU_t();
}