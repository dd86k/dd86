/**
 * core: Core of x86 machine code interpreter
 */
module vcpu.core;

import logger : log_info;
import vcpu.v16;
import vcpu.v32;
import vcpu.mm;
import appconfig : INIT_MEM, TSC_SLEEP;

enum : ubyte { // Emulated CPU
	CPU_8086,
	CPU_80486
}

enum : ubyte { // CPU Mode
	CPU_MODE_REAL,
	CPU_MODE_PROTECTED,
	CPU_MODE_VM8086,
	//CPU_MODE_SMM
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

/// CPU structure, 
extern (C)
struct CPU_t {
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
	// EFLAGS operations, e.g. PUSHDF.
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
	/// Current mode, defaults to CPU_MODE_REAL
	ubyte Mode;
	/// CPU Type: 8086, 80486, etc.
	ubyte Type;
}

/// Main Central Processing Unit
public __gshared CPU_t CPU = void;

/**
 * Runnning level.$(BR)
 * Used to determine the "level of execution", such as the "deepness" of a program.
 * When a program terminates, RLEVEL is decreased.
 * If HLT is sent, RLEVEL is set to 0.
 * If RLEVEL reaches 0 (or lower), the emulator either stops, or returns to the virtual shell.$(BR)
 * tl;dr: Emulates CALLs
 */
__gshared short RLEVEL = 1;
__gshared ubyte opt_sleep = 1; /// Is sleeping available to use? If so, use it
__gshared ubyte *MEMORY = void; /// Memory bank
__gshared int MEMORYSIZE = INIT_MEM; /// Memory size

// Functions could be put in these tables at compile time. However, that would
// remove the flexibility of choosing the functions per cpu type at
// initialization.
/// CPU Mode function table
extern (C) __gshared void function(ubyte)[4] MODE_MAP;
/// Real-mode instructions function table
extern (C) __gshared void function()[256] REAL_MAP;
/// Protected-mode instructions function table
extern (C) __gshared void function()[256] PROT_MAP;

/// Initiate interpreter
extern (C)
void vcpu_init() {
	import core.stdc.stdlib : realloc;
	MEMORY = cast(ubyte*)realloc(MEMORY, INIT_MEM); // in case of re-init
	CPU.CS = 0xFFFF;
	MODE_MAP[0] = &exec16;
	
	REAL_MAP[0x00] = &v16_add_rm8_reg8;
	REAL_MAP[0x01] = &v16_add_rm16_reg16;
	REAL_MAP[0x02] = &v16_add_reg8_rm8;
	REAL_MAP[0x03] = &v16_add_reg16_rm16;
	REAL_MAP[0x04] = &v16_add_al_imm8;
	REAL_MAP[0x05] = &v16_add_ax_imm16;
	REAL_MAP[0x06] = &v16_push_es;
	REAL_MAP[0x07] = &v16_pop_es;
	REAL_MAP[0x08] = &v16_or_rm8_reg8;
	REAL_MAP[0x09] = &v16_or_rm16_reg16;
	REAL_MAP[0x0A] = &v16_or_reg8_rm8;
	REAL_MAP[0x0B] = &v16_or_reg16_rm16;
	REAL_MAP[0x0C] = &v16_or_al_imm8;
	REAL_MAP[0x0D] = &v16_or_ax_imm16;
	REAL_MAP[0x0E] = &v16_push_cs;
	REAL_MAP[0x10] = &v16_adc_rm8_reg8;
	REAL_MAP[0x11] = &v16_adc_rm16_reg16;
	REAL_MAP[0x12] = &v16_adc_reg8_rm8;
	REAL_MAP[0x13] = &v16_adc_reg16_rm16;
	REAL_MAP[0x14] = &v16_adc_al_imm8;
	REAL_MAP[0x15] = &v16_adc_ax_imm16;
	REAL_MAP[0x16] = &v16_push_ss;
	REAL_MAP[0x17] = &v16_pop_ss;
	REAL_MAP[0x18] = &v16_sbb_rm8_reg8;
	REAL_MAP[0x19] = &v16_sbb_rm16_reg16;
	REAL_MAP[0x1A] = &v16_sbb_reg8_rm8;
	REAL_MAP[0x1B] = &v16_sbb_reg16_rm16;
	REAL_MAP[0x1C] = &v16_sbb_al_imm8;
	REAL_MAP[0x1D] = &v16_sbb_ax_imm16;
	REAL_MAP[0x1E] = &v16_push_ds;
	REAL_MAP[0x1F] = &v16_pop_ds;
	REAL_MAP[0x20] = &v16_and_rm8_reg8;
	REAL_MAP[0x21] = &v16_and_rm16_reg16;
	REAL_MAP[0x22] = &v16_and_reg8_rm8;
	REAL_MAP[0x23] = &v16_and_reg16_rm16;
	REAL_MAP[0x24] = &v16_and_al_imm8;
	REAL_MAP[0x25] = &v16_and_ax_imm16;
	REAL_MAP[0x26] = &v16_es;
	REAL_MAP[0x27] = &v16_daa;
	REAL_MAP[0x28] = &v16_sub_rm8_reg8;
	REAL_MAP[0x29] = &v16_sub_rm16_reg16;
	REAL_MAP[0x2A] = &v16_sub_reg8_rm8;
	REAL_MAP[0x2B] = &v16_sub_reg16_rm16;
	REAL_MAP[0x2C] = &v16_sub_al_imm8;
	REAL_MAP[0x2D] = &v16_sub_ax_imm16;
	REAL_MAP[0x2E] = &v16_cs;
	REAL_MAP[0x2F] = &v16_das;
	REAL_MAP[0x30] = &v16_xor_rm8_reg8;
	REAL_MAP[0x31] = &v16_xor_rm16_reg16;
	REAL_MAP[0x32] = &v16_xor_reg8_rm8;
	REAL_MAP[0x33] = &v16_xor_reg16_rm16;
	REAL_MAP[0x34] = &v16_xor_al_imm8;
	REAL_MAP[0x35] = &v16_xor_ax_imm16;
	REAL_MAP[0x36] = &v16_ss;
	REAL_MAP[0x37] = &v16_aaa;
	REAL_MAP[0x38] = &v16_cmp_rm8_reg8;
	REAL_MAP[0x39] = &v16_cmp_rm16_reg16;
	REAL_MAP[0x3A] = &v16_cmp_reg8_rm8;
	REAL_MAP[0x3B] = &v16_cmp_reg16_rm16;
	REAL_MAP[0x3C] = &v16_cmp_al_imm8;
	REAL_MAP[0x3D] = &v16_cmp_ax_imm16;
	REAL_MAP[0x3E] = &v16_ds;
	REAL_MAP[0x3F] = &v16_aas;
	REAL_MAP[0x40] = &v16_inc_ax;
	REAL_MAP[0x41] = &v16_inc_cx;
	REAL_MAP[0x42] = &v16_inc_dx;
	REAL_MAP[0x43] = &v16_inc_bx;
	REAL_MAP[0x44] = &v16_inc_sp;
	REAL_MAP[0x45] = &v16_inc_bp;
	REAL_MAP[0x46] = &v16_inc_si;
	REAL_MAP[0x47] = &v16_inc_di;
	REAL_MAP[0x48] = &v16_dec_ax;
	REAL_MAP[0x49] = &v16_dec_cx;
	REAL_MAP[0x4A] = &v16_dec_dx;
	REAL_MAP[0x4B] = &v16_dec_bx;
	REAL_MAP[0x4C] = &v16_dec_sp;
	REAL_MAP[0x4D] = &v16_dec_bp;
	REAL_MAP[0x4E] = &v16_dec_si;
	REAL_MAP[0x4F] = &v16_dec_di;
	REAL_MAP[0x50] = &v16_push_ax;
	REAL_MAP[0x51] = &v16_push_cx;
	REAL_MAP[0x52] = &v16_push_dx;
	REAL_MAP[0x53] = &v16_push_bx;
	REAL_MAP[0x54] = &v16_push_sp;
	REAL_MAP[0x55] = &v16_push_bp;
	REAL_MAP[0x56] = &v16_push_si;
	REAL_MAP[0x57] = &v16_push_di;
	REAL_MAP[0x58] = &v16_pop_ax;
	REAL_MAP[0x59] = &v16_pop_cx;
	REAL_MAP[0x5A] = &v16_pop_dx;
	REAL_MAP[0x5B] = &v16_pop_bx;
	REAL_MAP[0x5C] = &v16_pop_sp;
	REAL_MAP[0x5D] = &v16_pop_bp;
	REAL_MAP[0x5E] = &v16_pop_si;
	REAL_MAP[0x5F] = &v16_pop_di;
	REAL_MAP[0x70] = &v16_jo_short;
	REAL_MAP[0x71] = &v16_jno_short;
	REAL_MAP[0x72] = &v16_jb_short;
	REAL_MAP[0x73] = &v16_jnb_short;
	REAL_MAP[0x74] = &v16_je_short;
	REAL_MAP[0x75] = &v16_jne_short;
	REAL_MAP[0x76] = &v16_jbe_short;
	REAL_MAP[0x77] = &v16_jnbe_short;
	REAL_MAP[0x78] = &v16_js_short;
	REAL_MAP[0x79] = &v16_jns_short;
	REAL_MAP[0x7A] = &v16_jp_short;
	REAL_MAP[0x7B] = &v16_jnp_short;
	REAL_MAP[0x7C] = &v16_jl_short;
	REAL_MAP[0x7D] = &v16_jnl_short;
	REAL_MAP[0x7E] = &v16_jle_short;
	REAL_MAP[0x7F] = &v16_jnle_short;
	REAL_MAP[0x80] = &v16_grp1_rm8_imm8;
	REAL_MAP[0x81] = &v16_grp1_rm16_imm16;
	REAL_MAP[0x82] = &v16_grp2_rm8_imm8;
	REAL_MAP[0x83] = &v16_grp2_rm16_imm8;
	REAL_MAP[0x84] = &v16_test_rm8_reg8;
	REAL_MAP[0x85] = &v16_test_rm16_reg16;
	REAL_MAP[0x86] = &v16_xchg_reg8_rm8;
	REAL_MAP[0x87] = &v16_xchx_reg16_rm16;
	REAL_MAP[0x88] = &v16_mov_rm8_reg8;
	REAL_MAP[0x89] = &v16_mov_rm16_reg16;
	REAL_MAP[0x8A] = &v16_mov_reg8;
	REAL_MAP[0x8B] = &v16_mov_reg16_rm16;
	REAL_MAP[0x8C] = &v16_mov_rm16_seg;
	REAL_MAP[0x8D] = &v16_lea_reg16_mem16;
	REAL_MAP[0x8E] = &v16_mov_seg_rm16;
	REAL_MAP[0x8F] = &v16_pop_rm16;
	REAL_MAP[0x90] = &v16_nop;
	REAL_MAP[0x91] = &v16_xchg_ax_cx;
	REAL_MAP[0x92] = &v16_xchg_ax_dx;
	REAL_MAP[0x93] = &v16_xchg_ax_bx;
	REAL_MAP[0x94] = &v16_xchg_ax_sp;
	REAL_MAP[0x95] = &v16_xchg_ax_bp;
	REAL_MAP[0x96] = &v16_xchg_ax_si;
	REAL_MAP[0x97] = &v16_xchg_ax_di;
	REAL_MAP[0x98] = &v16_cbw;
	REAL_MAP[0x99] = &v16_cwd;
	REAL_MAP[0x9A] = &v16_call_far;
	REAL_MAP[0x9B] = &v16_wait;
	REAL_MAP[0x9C] = &v16_pushf;
	REAL_MAP[0x9D] = &v16_popf;
	REAL_MAP[0x9E] = &v16_sahf;
	REAL_MAP[0x9F] = &v16_lahf;
	REAL_MAP[0xA0] = &v16_mov_al_mem8;
	REAL_MAP[0xA1] = &v16_mov_ax_mem16;
	REAL_MAP[0xA2] = &v16_mov_mem8_al;
	REAL_MAP[0xA3] = &v16_mov_mem16_ax;
	REAL_MAP[0xA4] = &v16_movs_str8;
	REAL_MAP[0xA5] = &v16_movs_str16;
	REAL_MAP[0xA6] = &v16_cmps_str8;
	REAL_MAP[0xA7] = &v16_cmps_str16;
	REAL_MAP[0xA8] = &v16_test_al_imm8;
	REAL_MAP[0xA9] = &v16_test_ax_imm16;
	REAL_MAP[0xAA] = &v16_stos_str8;
	REAL_MAP[0xAB] = &v16_stos_str16;
	REAL_MAP[0xAC] = &v16_lods_str8;
	REAL_MAP[0xAD] = &v16_lods_str16;
	REAL_MAP[0xAE] = &v16_scas_str8;
	REAL_MAP[0xAF] = &v16_scas_str16;
	REAL_MAP[0xB0] = &v16_mov_al_imm8;
	REAL_MAP[0xB1] = &v16_mov_cl_imm8;
	REAL_MAP[0xB2] = &v16_mov_dl_imm8;
	REAL_MAP[0xB3] = &v16_mov_bl_imm8;
	REAL_MAP[0xB4] = &v16_mov_ah_imm8;
	REAL_MAP[0xB5] = &v16_mov_ch_imm8;
	REAL_MAP[0xB6] = &v16_mov_dh_imm8;
	REAL_MAP[0xB7] = &v16_mov_bh_imm8;
	REAL_MAP[0xB8] = &v16_mov_ax_imm16;
	REAL_MAP[0xB9] = &v16_mov_cx_imm16;
	REAL_MAP[0xBA] = &v16_mov_dx_imm16;
	REAL_MAP[0xBB] = &v16_mov_bx_imm16;
	REAL_MAP[0xBC] = &v16_mov_sp_imm16;
	REAL_MAP[0xBD] = &v16_mov_bp_imm16;
	REAL_MAP[0xBE] = &v16_mov_si_imm16;
	REAL_MAP[0xBF] = &v16_mov_di_imm16;
	REAL_MAP[0xC0] = &v16_illegal;
	REAL_MAP[0xC1] = &v16_illegal;
	REAL_MAP[0xC2] = &v16_ret_imm16_near;
	REAL_MAP[0xC3] = &v16_ret_near;
	REAL_MAP[0xC4] = &v16_les_reg16_mem16;
	REAL_MAP[0xC5] = &v16_lds_reg16_mem16;
	REAL_MAP[0xC6] = &v16_mov_mem8_imm8;
	REAL_MAP[0xC7] = &v16_mov_mem16_imm16;
	REAL_MAP[0xC8] = &v16_illegal;
	REAL_MAP[0xC9] = &v16_illegal;
	REAL_MAP[0xCA] = &v16_ret_imm16_far;
	REAL_MAP[0xCB] = &v16_ret_far;
	REAL_MAP[0xCC] = &v16_int3;
	REAL_MAP[0xCD] = &v16_int_imm8;
	REAL_MAP[0xCE] = &v16_into;
	REAL_MAP[0xCF] = &v16_iret;
	REAL_MAP[0xD0] = &v16_grp2_rm8_1;
	REAL_MAP[0xD1] = &v16_grp2_rm16_1;
	REAL_MAP[0xD2] = &v16_grp2_rm8_cl;
	REAL_MAP[0xD3] = &v16_grp2_rm16_cl;
	REAL_MAP[0xD4] = &v16_aam;
	REAL_MAP[0xD5] = &v16_aad;
	REAL_MAP[0xD6] = &v16_illegal;
	REAL_MAP[0xD7] = &v16_xlat;
	REAL_MAP[0xD8] = &v16_illegal;
	REAL_MAP[0xD9] = &v16_illegal;
	REAL_MAP[0xDA] = &v16_illegal;
	REAL_MAP[0xDB] = &v16_illegal;
	REAL_MAP[0xDC] = &v16_illegal;
	REAL_MAP[0xDD] = &v16_illegal;
	REAL_MAP[0xDE] = &v16_illegal;
	REAL_MAP[0xDF] = &v16_illegal;
	REAL_MAP[0xE0] = &v16_loope;
	REAL_MAP[0xE1] = &v16_loop;
	REAL_MAP[0xE2] = &v16_jcxz;
	REAL_MAP[0xE3] = &v16_jcxz;
	REAL_MAP[0xE4] = &v16_in_al_imm8;
	REAL_MAP[0xE5] = &v16_in_ax_imm8;
	REAL_MAP[0xE6] = &v16_out_imm8_al;
	REAL_MAP[0xE7] = &v16_out_imm8_ax;
	REAL_MAP[0xE8] = &v16_call_near;
	REAL_MAP[0xE9] = &v16_jmp_near;
	REAL_MAP[0xEA] = &v16_jmp_Far;
	REAL_MAP[0xEB] = &v16_jmp_short;
	REAL_MAP[0xEC] = &v16_in_al_dx;
	REAL_MAP[0xED] = &v16_in_ax_dx;
	REAL_MAP[0xEE] = &v16_out_al_dx;
	REAL_MAP[0xEF] = &v16_out_ax_dx;
	REAL_MAP[0xF0] = &v16_lock;
	REAL_MAP[0xF1] = &v16_lock;
	REAL_MAP[0xF2] = &v16_repne;
	REAL_MAP[0xF3] = &v16_rep;
	REAL_MAP[0xF4] = &v16_hlt;
	REAL_MAP[0xF5] = &v16_cmc;
	REAL_MAP[0xF6] = &v16_grp3_rm8_imm8;
	REAL_MAP[0xF7] = &v16_grp3_rm16_imm16;
	REAL_MAP[0xF8] = &v16_clc;
	REAL_MAP[0xF9] = &v16_stc;
	REAL_MAP[0xFA] = &v16_cli;
	REAL_MAP[0xFB] = &v16_sti;
	REAL_MAP[0xFC] = &v16_cld;
	REAL_MAP[0xFD] = &v16_std;
	REAL_MAP[0xFE] = &v16_grp4_rm8;
	REAL_MAP[0xFF] = &v16_grp4_rm16;
	switch (CPU.Type) {
	case CPU_8086:
		MODE_MAP[1] = &mode_invalid;
		MODE_MAP[2] = &mode_invalid;
		MODE_MAP[3] = &mode_invalid;
		// While it is possible to map a range, it relies on
		// memset32/64 which DMD linkers will not find
		for (size_t i = 0x60; i < 0x70; ++i)
			REAL_MAP[i] = &v16_illegal;
		break;
	case CPU_80486:
		MODE_MAP[1] = &exec32;
		MODE_MAP[2] = &mode_invalid;
		MODE_MAP[3] = &mode_invalid;
		
		//REAL_MAP[0x60] =
		//REAL_MAP[0x61] =
		//REAL_MAP[0x62] =
		//REAL_MAP[0x63] =
		//REAL_MAP[0x64] =
		//REAL_MAP[0x65] =
		REAL_MAP[0x66] = &v16_operand_override;
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
	
	for (size_t i; i < 256; ++i) { // Sanity check
		import core.stdc.stdio: printf;
		import core.stdc.stdlib: exit;
		/*if (REAL_MAP[i] == null) {
			printf("REAL_MAP[%02Xh] is NULL!\n", i);
			exit(1);
		}*/
		/*if (PROT_MAP[i] == null) {
			printf("REAL_MAP[%02Xh] is NULL!\n", i);
			exit(1);
		}*/
	}
}

/// Start the emulator at CS:IP (default: FFFF:0000h)
extern (C)
void vcpu_run() {
	int sleep = opt_sleep;
	while (RLEVEL > 0) {
		CPU.EIP = get_ip;
		//TODO: Check CPU.EIP against segments and memory size

		ubyte op = MEMORY[CPU.EIP];
		MODE_MAP[CPU.Mode](op);
	}
}

extern (C)
void mode_invalid(ubyte op) {
}

//
// CPU utilities
//

//TODO: step(ubyte) instead of incrementing EIP manually?
//      otherwise it's manual checking before executing ops

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
	return (s << 4) | o;
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

/// RESET instruction function
/// This function does not perform security checks
extern (C)
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
/// This sets all registers to 0. Segment is set to SET_NONE, and Mode is set
/// to CPU_MODE_REAL. Useful in unittesting.
extern (C)
void fullreset() {
	CPU = CPU_t();
}

//
// Flag handling
//

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

/**
 * Get EFLAG as DWORD.
 * Returns: EFLAG (DWORD)
 */
@property uint EFLAG() {
	ushort b = FLAG;
	//TODO: EFLAG
	return b;
}

/// Set EFLAG as DWORD.
/// Params: flag = EFLAG dword
@property void EFLAG(uint flag) {
	//TODO: EFLAG
}

//
// Stack handling
//

/**
 * (8086) Push a WORD value into stack.
 * Params: value = WORD value to PUSH
 */
extern (C)
void push16(ushort value) {
	CPU.SP -= 2;
	mmiu16(value, get_ad(CPU.SS, CPU.SP));
}

/**
 * (80206+) Push a WORD value into stack.
 * Params: value = WORD value to PUSH
 */
extern (C)
void push16a(ushort value) {
	mmiu16(value, get_ad(CPU.SS, CPU.SP));
	CPU.SP -= 2;
}

/**
 * Pop a WORD value from stack.
 * Returns: WORD value
 */
extern (C)
ushort pop16() {
	const uint addr = get_ad(CPU.SS, CPU.SP);
	CPU.SP += 2;
	return mmfu16(addr);
}

/**
 * Push a DWORD value into stack.
 * Params: value = DWORD value
 */
extern (C)
void push32(uint value) {
	CPU.SP -= 4;
	mmiu32(value, get_ad(CPU.SS, CPU.SP));
}

/**
 * Pop a DWORD value from stack.
 * Returns: WORD value
 */
extern (C)
uint pop32() {
	const uint addr = get_ad(CPU.SS, CPU.SP);
	CPU.SP += 2;
	return mmfu32(addr);
}