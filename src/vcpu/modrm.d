module vcpu.modrm;

import vcpu.core : CPU;
import vcpu.mm;
import err;

extern (C):

enum {
	X86_WIDTH_BYTE,	/// 8-bit value
	X86_WIDTH_WIDE,	/// 16-bit value
	X86_WIDTH_EXT,	/// 32-bit value
}

enum {
	MODRM_MOD_00 =   0,	/// MOD 00, Memory Mode, no displacement
	MODRM_MOD_01 =  64,	/// MOD 01, Memory Mode, 8-bit displacement
	MODRM_MOD_10 = 128,	/// MOD 10, Memory Mode, 16-bit displacement
	MODRM_MOD_11 = 192,	/// MOD 11, Register Mode
	MODRM_MOD = MODRM_MOD_11,	/// Used for masking the MOD bits (11 000 000)

	MODRM_REG_000 =  0,	/// AL/AX
	MODRM_REG_001 =  8,	/// CL/CX
	MODRM_REG_010 = 16,	/// DL/DX
	MODRM_REG_011 = 24,	/// BL/BX
	MODRM_REG_100 = 32,	/// AH/SP
	MODRM_REG_101 = 40,	/// CH/BP
	MODRM_REG_110 = 48,	/// DH/SI
	MODRM_REG_111 = 56,	/// BH/DI
	MODRM_REG = MODRM_REG_111,	/// Used for masking the REG bits (00 111 000)

	MODRM_RM_000 = 0,	/// R/M 000 bits
	MODRM_RM_001 = 1,	/// R/M 001 bits
	MODRM_RM_010 = 2,	/// R/M 010 bits
	MODRM_RM_011 = 3,	/// R/M 011 bits
	MODRM_RM_100 = 4,	/// R/M 100 bits
	MODRM_RM_101 = 5,	/// R/M 101 bits
	MODRM_RM_110 = 6,	/// R/M 110 bits
	MODRM_RM_111 = 7,	/// R/M 111 bits
	MODRM_RM = MODRM_RM_111,	/// Used for masking the R/M bits (00 000 111)
}

//
// ANCHOR Real mode
//

int modrm16frm(int modrm, int wide) {
	int m = void;
	if ((modrm & MODRM_MOD) != MODRM_MOD_11) {
		m = modrm16freg(modrm, wide);
	} else {
		int addr = modrm16rm(modrm);
		if (wide)
			m = mmfu16(addr);
		else
			m = mmfu8(addr);
	}
	return m;
}

void modrm16irm(int modrm, int wide, int val) {
	if ((modrm & MODRM_MOD) != MODRM_MOD_11) {
		int addr = modrm16rm(modrm);
		if (wide)
			mmiu16(addr, val);
		else
			mmiu8(addr, val);
	} else {
		int reg = modrm & MODRM_RM;
		if (wide) {
			ushort m = cast(ushort)val;
			switch (reg) {
			case MODRM_RM_000: CPU.AX = m; return;
			case MODRM_RM_001: CPU.CX = m; return;
			case MODRM_RM_010: CPU.DX = m; return;
			case MODRM_RM_011: CPU.BX = m; return;
			case MODRM_RM_100: CPU.SP = m; return;
			case MODRM_RM_101: CPU.BP = m; return;
			case MODRM_RM_110: CPU.SI = m; return;
			default:           CPU.DI = m; return;
			}
		} else {
			ubyte m = cast(ubyte)val;
			switch (reg) {
			case MODRM_RM_000: CPU.AL = m; return;
			case MODRM_RM_001: CPU.CL = m; return;
			case MODRM_RM_010: CPU.DL = m; return;
			case MODRM_RM_011: CPU.BL = m; return;
			case MODRM_RM_100: CPU.AH = m; return;
			case MODRM_RM_101: CPU.CH = m; return;
			case MODRM_RM_110: CPU.DH = m; return;
			default:           CPU.BH = m; return;
			}
		}
	}
}

int modrm16freg(int modrm, int wide) {
	int r = void;
	switch (modrm & MODRM_REG) {
	case MODRM_REG_000: r = wide ? CPU.AX : CPU.AL; break;
	case MODRM_REG_001: r = wide ? CPU.CX : CPU.CL; break;
	case MODRM_REG_010: r = wide ? CPU.DX : CPU.DL; break;
	case MODRM_REG_011: r = wide ? CPU.BX : CPU.BL; break;
	case MODRM_REG_100: r = wide ? CPU.SP : CPU.AH; break;
	case MODRM_REG_101: r = wide ? CPU.BP : CPU.CH; break;
	case MODRM_REG_110: r = wide ? CPU.SI : CPU.DH; break;
	case MODRM_REG_111: r = wide ? CPU.DI : CPU.BH; break;
	default: // Never
	}
	return r;
}

void modrm16ireg(int modrm, int wide, int val) {
	int reg = modrm & MODRM_REG;
	if (wide) {
		ushort m = cast(ushort)val;
		switch (reg) {
		case MODRM_REG_000: CPU.AX = m; return;
		case MODRM_REG_001: CPU.CX = m; return;
		case MODRM_REG_010: CPU.DX = m; return;
		case MODRM_REG_011: CPU.BX = m; return;
		case MODRM_REG_100: CPU.SP = m; return;
		case MODRM_REG_101: CPU.BP = m; return;
		case MODRM_REG_110: CPU.SI = m; return;
		default:            CPU.DI = m; return;
		}
	} else {
		ubyte m = cast(ubyte)val;
		switch (reg) {
		case MODRM_REG_000: CPU.AL = m; return;
		case MODRM_REG_001: CPU.CL = m; return;
		case MODRM_REG_010: CPU.DL = m; return;
		case MODRM_REG_011: CPU.BL = m; return;
		case MODRM_REG_100: CPU.AH = m; return;
		case MODRM_REG_101: CPU.CH = m; return;
		case MODRM_REG_110: CPU.DH = m; return;
		default:            CPU.BH = m; return;
		}
	}
}

int modrm16rm(int modrm) {
	int rm = modrm & MODRM_RM;
	switch (modrm & MODRM_MOD) { // MOD
	case MODRM_MOD_00: // MOD 00, Memory Mode, no displacement
		switch (rm) { // R/M
		case MODRM_RM_000: return CPU.SI + CPU.BX;
		case MODRM_RM_001: return CPU.DI + CPU.BX;
		case MODRM_RM_010: return CPU.SI + CPU.BP;
		case MODRM_RM_011: return CPU.DI + CPU.BP;
		case MODRM_RM_100: return CPU.SI;
		case MODRM_RM_101: return CPU.DI;
		case MODRM_RM_110: return mmfu16_i;
		default:           return CPU.BX;
		}
	case MODRM_MOD_01: // MOD 01, Memory Mode, 8-bit displacement follows
		switch (rm) {
		case MODRM_RM_000: return CPU.SI + CPU.BX + mmfi8_i;
		case MODRM_RM_001: return CPU.DI + CPU.BX + mmfi8_i;
		case MODRM_RM_010: return CPU.SI + CPU.BP + mmfi8_i;
		case MODRM_RM_011: return CPU.DI + CPU.BP + mmfi8_i;
		case MODRM_RM_100: return CPU.SI + mmfi8_i;
		case MODRM_RM_101: return CPU.DI + mmfi8_i;
		case MODRM_RM_110: return CPU.BP + mmfi8_i;
		default:           return CPU.BX + mmfi8_i;
		}
	case MODRM_MOD_10: // MOD 10, Memory Mode, 16-bit displacement follows
		switch (rm) { // R/M
		case MODRM_RM_000: return CPU.SI + CPU.BX + mmfi16_i;
		case MODRM_RM_001: return CPU.DI + CPU.BX + mmfi16_i;
		case MODRM_RM_010: return CPU.SI + CPU.BP + mmfi16_i;
		case MODRM_RM_011: return CPU.DI + CPU.BP + mmfi16_i;
		case MODRM_RM_100: return CPU.SI + mmfi16_i;
		case MODRM_RM_101: return CPU.DI + mmfi16_i;
		case MODRM_RM_110: return CPU.BP + mmfi16_i;
		default:           return CPU.BX + mmfi16_i;
		}
	default: return 0;
	}
}

//
// ANCHOR Protected mode
//
