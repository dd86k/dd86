module vcpu.modrm;

import vcpu.core : CPU;
import vcpu.mm;
import err;

extern (C):

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

/**
 * Get effective address from a R/M byte.
 * Takes account of the preferred segment register.
 * MOD and RM fields are used, and Seg is reset (SEG_NONE).
 * The instruction pointer is adjusted.
 * Params:
 *   rm = R/M BYTE
 *   wide = wide bit set in opcode
 * Returns: Effective Address
 */
uint modrm16(ubyte modrm, ubyte wide = 0) {
	uint r = void;
	//TODO: Reset Seg to SEG_NONE
	//TODO: Use general purpose variable to hold segreg value
	switch (modrm & RM_MOD) { // MOD
	case RM_MOD_00: // MOD 00, Memory Mode, no displacement
		switch (modrm & RM_RM) { // R/M
		case RM_RM_000: r = CPU.SI + CPU.BX; break;
		case RM_RM_001: r = CPU.DI + CPU.BX; break;
		case RM_RM_010: r = CPU.SI + CPU.BP; break;
		case RM_RM_011: r = CPU.DI + CPU.BP; break;
		case RM_RM_100: r = CPU.SI; break;
		case RM_RM_101: r = CPU.DI; break;
		case RM_RM_110: r = mmfu16_i(1); break;
		case RM_RM_111: r = CPU.BX; break;
		default:
		}
		break; // MOD 00
	case RM_MOD_01: { // MOD 01, Memory Mode, 8-bit displacement follows
		switch (modrm & RM_RM) {
		case RM_RM_000: r = CPU.SI + CPU.BX + mmfi8_i(1); break;
		case RM_RM_001: r = CPU.DI + CPU.BX + mmfi8_i(1); break;
		case RM_RM_010: r = CPU.SI + CPU.BP + mmfi8_i(1); break;
		case RM_RM_011: r = CPU.DI + CPU.BP + mmfi8_i(1); break;
		case RM_RM_100: r = CPU.SI + mmfi8_i(1); break;
		case RM_RM_101: r = CPU.DI + mmfi8_i(1); break;
		case RM_RM_110: r = CPU.BP + mmfi8_i(1); break;
		case RM_RM_111: r = CPU.BX + mmfi8_i(1); break;
		default:
		}
		++CPU.EIP;
		break; // MOD 01
	}
	case RM_MOD_10: // MOD 10, Memory Mode, 16-bit displacement follows
		switch (modrm & RM_RM) { // R/M
		case RM_RM_000: r = CPU.SI + CPU.BX + mmfi16_i(1); break;
		case RM_RM_001: r = CPU.DI + CPU.BX + mmfi16_i(1); break;
		case RM_RM_010: r = CPU.SI + CPU.BP + mmfi16_i(1); break;
		case RM_RM_011: r = CPU.DI + CPU.BP + mmfi16_i(1); break;
		case RM_RM_100: r = CPU.SI + mmfi16_i(1); break;
		case RM_RM_101: r = CPU.DI + mmfi16_i(1); break;
		case RM_RM_110: r = CPU.BP + mmfi16_i(1); break;
		case RM_RM_111: r = CPU.BX + mmfi16_i(1); break;
		default:
		}
		CPU.EIP += 2;
		break; // MOD 10
	case RM_MOD_11: // MOD 11, Register Mode
		r = modrm16_reg(modrm, wide);
		break; // MOD 11
	default:
	}

	vmerr = E_MM_OK;
	return r;
}

ushort modrm16_reg(ubyte modrm, int wide) {
	ushort r = void;
	switch (modrm & RM_REG) {
	case RM_REG_000: r = wide ? CPU.AX : CPU.AL; break;
	case RM_REG_001: r = wide ? CPU.CX : CPU.CL; break;
	case RM_REG_010: r = wide ? CPU.DX : CPU.DL; break;
	case RM_REG_011: r = wide ? CPU.BX : CPU.BL; break;
	case RM_REG_100: r = wide ? CPU.SP : CPU.AH; break;
	case RM_REG_101: r = wide ? CPU.BP : CPU.CH; break;
	case RM_REG_110: r = wide ? CPU.SI : CPU.DH; break;
	case RM_REG_111: r = wide ? CPU.DI : CPU.BH; break;
	default: // Never
	}
	return r;
}

/**
 * Calculates the effective address from the given ModR/M byte and is used
 * under 32-bit modes. This function updates EIP.
 * Params:
 *   rm = ModR/M byte
 *   wide = WIDE bit
 * Returns: Calculated address
 */
uint modrm32(ubyte rm, ubyte wide = 0) {
	//TODO: segment overload support
	uint r = void;
	switch (rm & RM_MOD) { // MOD
	case RM_MOD_00: // MOD 00, Memory Mode, no displacement
		switch (rm & RM_RM) {
		case RM_RM_000: r = CPU.EAX; break;
		case RM_RM_001: r = CPU.ECX; break;
		case RM_RM_010: r = CPU.EDX; break;
		case RM_RM_011: r = CPU.EBX; break;
		case RM_RM_100: /*TODO: SIB mode*/ break;
		case RM_RM_101: r = mmfi32_i(1); break;
		case RM_RM_110: r = CPU.ESI; break;
		case RM_RM_111: r = CPU.EDI; break;
		default:
		}
		break; // MOD 00
	case RM_MOD_01: { // MOD 01, Memory Mode, 8-bit displacement follows
		switch (rm & RM_RM) {
		case RM_RM_000: r = CPU.EAX + mmfi8_i(1); break;
		case RM_RM_001: r = CPU.ECX + mmfi8_i(1); break;
		case RM_RM_010: r = CPU.EDX + mmfi8_i(1); break;
		case RM_RM_011: r = CPU.EBX + mmfi8_i(1); break;
		case RM_RM_100: /*TODO: SIB mode + D8*/ break;
		case RM_RM_101: r = CPU.EBP + mmfi8_i(1); break;
		case RM_RM_110: r = CPU.ESI + mmfi8_i(1); break;
		case RM_RM_111: r = CPU.EDI + mmfi8_i(1); break;
		default:
		}
		++CPU.EIP;
		break; // MOD 01
	}
	case RM_MOD_10: // MOD 10, Memory Mode, 32-bit displacement follows
		switch (rm & RM_RM) { // R/M
		case RM_RM_000: r = CPU.EAX + mmfi32_i(1); break;
		case RM_RM_001: r = CPU.ECX + mmfi32_i(1); break;
		case RM_RM_010: r = CPU.EDX + mmfi32_i(1); break;
		case RM_RM_011: r = CPU.EBX + mmfi32_i(1); break;
		case RM_RM_100: /*TODO: SIB mode + D32*/ break;
		case RM_RM_101: r = CPU.EBP + mmfi32_i(1); break;
		case RM_RM_110: r = CPU.ESI + mmfi32_i(1); break;
		case RM_RM_111: r = CPU.EDI + mmfi32_i(1); break;
		default:
		}
		CPU.EIP += 2;
		break; // MOD 10
	case RM_MOD_11: // MOD 11, Register Mode
		const ubyte m = rm & RM_RM;
		if (wide)
			switch (m) {
			case RM_RM_000: r = CPU.EAX; break;
			case RM_RM_001: r = CPU.ECX; break;
			case RM_RM_010: r = CPU.EDX; break;
			case RM_RM_011: r = CPU.EBX; break;
			case RM_RM_100: r = CPU.ESP; break;
			case RM_RM_101: r = CPU.EBP; break;
			case RM_RM_110: r = CPU.ESI; break;
			case RM_RM_111: r = CPU.EDI; break;
			default:
			}
		else
			switch (m) {
			//TODO: Check CPU.OPSIZE AX/CX/etc.
			case RM_RM_000: r = CPU.AL; break;
			case RM_RM_001: r = CPU.CL; break;
			case RM_RM_010: r = CPU.DL; break;
			case RM_RM_011: r = CPU.BL; break;
			case RM_RM_100: r = CPU.AH; break;
			case RM_RM_101: r = CPU.CH; break;
			case RM_RM_110: r = CPU.DH; break;
			case RM_RM_111: r = CPU.BH; break;
			default:
			}
		break; // MOD 11
	default:
	}

	vmerr = E_MM_OK;
	return r;
}