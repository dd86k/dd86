module vcpu_8086;

import vcpu, vcpu_utils;
import Logger;
import vdos : Raise;

/**
 * Execute an 8086 opcode
 * Params: op = 8086 opcode
 */
extern (C)
void exec16(ubyte op) {
	/*
	 * Legend:
	 * R/M - Mod Register/Memory byte
	 * IMM - Immediate value
	 * REG - Register
	 * MEM - Memory location
	 * SEGREG - Segment register
	 */
	// Every instruction has their own local variables, since referencing one
	// variable at the top of the stack increases binary size in general.
	switch (op) {
	case 0x00: { // ADD R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r += vCPU.AL; break;
		case RM_REG_001: r += vCPU.CL; break;
		case RM_REG_010: r += vCPU.DL; break;
		case RM_REG_011: r += vCPU.BL; break;
		case RM_REG_100: r += vCPU.AH; break;
		case RM_REG_101: r += vCPU.CH; break;
		case RM_REG_110: r += vCPU.DH; break;
		case RM_REG_111: r += vCPU.BH; break;
		default:
		}
		__hflag8_1(r);
		__iu8(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x01: { // ADD R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r += vCPU.AX; break;
		case RM_REG_001: r += vCPU.CX; break;
		case RM_REG_010: r += vCPU.DX; break;
		case RM_REG_011: r += vCPU.BX; break;
		case RM_REG_100: r += vCPU.SP; break;
		case RM_REG_101: r += vCPU.BP; break;
		case RM_REG_110: r += vCPU.SI; break;
		case RM_REG_111: r += vCPU.DI; break;
		default:
		}
		__hflag16_1(r);
		__iu16(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x02: { // ADD REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AL + r;
			vCPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r = vCPU.CL + r;
			vCPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r = vCPU.DL + r;
			vCPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r = vCPU.BL + r;
			vCPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r = vCPU.AH + r;
			vCPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r = vCPU.CH + r;
			vCPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r = vCPU.DH + r;
			vCPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r = vCPU.BH + r;
			vCPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_1(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x03: { // ADD REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AX + r;
			vCPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r = vCPU.CX + r;
			vCPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r = vCPU.DX + r;
			vCPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r = vCPU.BX + r;
			vCPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r = vCPU.SP + r;
			vCPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r = vCPU.BP + r;
			vCPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r = vCPU.SI + r;
			vCPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r = vCPU.DI + r;
			vCPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_1(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x04: { // ADD AL, IMM8
		int r = vCPU.AL + __fu8_i;
		__hflag8_1(r);
		vCPU.AL = cast(ubyte)r;
		vCPU.EIP += 2;
		return;
	}
	case 0x05: { // ADD vCPU.AX, IMM16
		int r = vCPU.AX + __fu16_i;
		__hflag16_1(r);
		vCPU.AX = cast(ushort)r;
		vCPU.EIP += 2;
		return;
	}
	case 0x06: // PUSH ES
		push(vCPU.ES);
		++vCPU.EIP;
		return;
	case 0x07: // POP ES
		vCPU.ES = pop;
		++vCPU.EIP;
		return;
	case 0x08: { // OR R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r |= vCPU.AL; break;
		case RM_REG_001: r |= vCPU.CL; break;
		case RM_REG_010: r |= vCPU.DL; break;
		case RM_REG_011: r |= vCPU.BL; break;
		case RM_REG_100: r |= vCPU.AH; break;
		case RM_REG_101: r |= vCPU.CH; break;
		case RM_REG_110: r |= vCPU.DH; break;
		case RM_REG_111: r |= vCPU.BH; break;
		default:
		}
		__hflag8_3(r);
		__iu8(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x09: { // OR R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r |= vCPU.AX; break;
		case RM_REG_001: r |= vCPU.CX; break;
		case RM_REG_010: r |= vCPU.DX; break;
		case RM_REG_011: r |= vCPU.BX; break;
		case RM_REG_100: r |= vCPU.SP; break;
		case RM_REG_101: r |= vCPU.BP; break;
		case RM_REG_110: r |= vCPU.SI; break;
		case RM_REG_111: r |= vCPU.DI; break;
		default:
		}
		__hflag16_3(r);
		__iu16(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x0A: { // OR REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AL | r;
			vCPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r = vCPU.CL | r;
			vCPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r = vCPU.DL | r;
			vCPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r = vCPU.BL | r;
			vCPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r = vCPU.AH | r;
			vCPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r = vCPU.CH | r;
			vCPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r = vCPU.DH | r;
			vCPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r = vCPU.BH | r;
			vCPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_3(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x0B: { // OR REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AX | r;
			vCPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r = vCPU.CX | r;
			vCPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r = vCPU.DX | r;
			vCPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r = vCPU.BX | r;
			vCPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r = vCPU.SP | r;
			vCPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r |= vCPU.BP;
			vCPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r = vCPU.SI | r;
			vCPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r = vCPU.DI | r;
			vCPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_3(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x0C: { // OR AL, IMM8
		int r = vCPU.AL | __fu8_i;
		__hflag8_3(r);
		vCPU.AL = cast(ubyte)r;
		vCPU.EIP += 2;
		return;
	}
	case 0x0D: { // OR AX, IMM16
		int r = vCPU.AX | __fu16_i;
		__hflag16_3(r);
		vCPU.AX = cast(ushort)r;
		vCPU.EIP += 3;
		return;
	}
	case 0x0E: // PUSH CS
		push(vCPU.CS);
		++vCPU.EIP;
		return;
	case 0x10: { // ADC R/M8, REG8

		return;
	}
	case 0x11: { // ADC R/M16, REG16

		return;
	}
	case 0x12: { // ADC REG8, R/M8

		return;
	}
	case 0x13: { // ADC REG16, R/M16

		return;
	}
	case 0x14: { // ADC AL, IMM8
		int r = vCPU.AL + __fu8_i;
		__hflag8_1(r);
		if (vCPU.CF) ++r;
		vCPU.AL = cast(ubyte)r;
		vCPU.EIP += 2;
		return;
	}
	case 0x15: { // ADC AX, IMM16
		int r = vCPU.AX + __fu16_i;
		__hflag16_1(r);
		if (vCPU.CF) ++r;
		vCPU.AX = cast(ushort)r;
		vCPU.EIP += 3;
		return;
	}
	case 0x16: // PUSH SS
		push(vCPU.SS);
		++vCPU.EIP;
		return;
	case 0x17: // POP SS
		vCPU.SS = pop;
		++vCPU.EIP;
		return;
	case 0x18: // SBB R/M8, REG8

		return;
	case 0x19: // SBB R/M16, REG16

		return;
	case 0x1A: // SBB REG8, R/M16

		return;
	case 0x1B: // SBB REG16, R/M16

		return;
	case 0x1C: { // SBB AL, IMM8
		int r = vCPU.AL - __fu8_i;
		if (vCPU.CF) --r;
		__hflag8_3(r);
		vCPU.AL = cast(ubyte)r;
		vCPU.EIP += 2;
		return;
	}
	case 0x1D: { // SBB AX, IMM16
		int r = vCPU.AX - __fu16_i;
		if (vCPU.CF) --r;
		__hflag16_3(r);
		vCPU.AX = cast(ushort)r;
		vCPU.EIP += 3;
		return;
	}
	case 0x1E: // PUSH DS
		push(vCPU.DS);
		++vCPU.EIP;
		return;
	case 0x1F: // POP DS
		vCPU.DS = pop;
		++vCPU.EIP;
		return;
	case 0x20: { // AND R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r &= vCPU.AH; break;
		case RM_REG_001: r &= vCPU.CH; break;
		case RM_REG_010: r &= vCPU.DH; break;
		case RM_REG_011: r &= vCPU.BH; break;
		case RM_REG_100: r &= vCPU.AL; break;
		case RM_REG_101: r &= vCPU.CL; break;
		case RM_REG_110: r &= vCPU.DL; break;
		case RM_REG_111: r &= vCPU.BL; break;
		default:
		}
		__hflag8_3(r);
		__iu8(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x21: { // AND R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r &= vCPU.AX; break;
		case RM_REG_001: r &= vCPU.CX; break;
		case RM_REG_010: r &= vCPU.DX; break;
		case RM_REG_011: r &= vCPU.BX; break;
		case RM_REG_100: r &= vCPU.SP; break;
		case RM_REG_101: r &= vCPU.BP; break;
		case RM_REG_110: r &= vCPU.SI; break;
		case RM_REG_111: r &= vCPU.DI; break;
		default:
		}
		__hflag16_3(r);
		__iu16(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x22: { // AND REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AL & r;
			vCPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r = vCPU.CL & r;
			vCPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r = vCPU.DL & r;
			vCPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r = vCPU.BL & r;
			vCPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r = vCPU.AH & r;
			vCPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r = vCPU.CH & r;
			vCPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r = vCPU.DH & r;
			vCPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r = vCPU.BH & r;
			vCPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_3(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x23: { // AND REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AX & r;
			vCPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r = vCPU.CX & r;
			vCPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r = vCPU.DX & r;
			vCPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r = vCPU.BX & r;
			vCPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r = vCPU.SP & r;
			vCPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r = vCPU.BP & r;
			vCPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r = vCPU.SI & r;
			vCPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r = vCPU.DI & r;
			vCPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_3(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x24: { // AND AL, IMM8
		int r = vCPU.AL & __fu8_i;
		__hflag8_3(r);
		vCPU.AL = cast(ubyte)r;
		vCPU.EIP += 2;
		return;
	}
	case 0x25: { // AND AX, IMM16
		int r = vCPU.AX & __fu16_i;
		__hflag16_3(r);
		vCPU.AX = cast(ushort)r;
		vCPU.EIP += 3;
		return;
	}
	case 0x26: // ES: (Segment override prefix)
		Seg = SEG_ES;
		++vCPU.EIP;
		return;
	case 0x27: { // DAA
		const ubyte oldAL = vCPU.AL;
		const ubyte oldCF = vCPU.CF;
		vCPU.CF = 0;

		if (((oldAL & 0xF) > 9) || vCPU.AF) {
			vCPU.AL = cast(ubyte)(vCPU.AL + 6);
			vCPU.CF = oldCF || (vCPU.AL & 0x80);
			vCPU.AF = 1;
		} else vCPU.AF = 0;

		if ((oldAL > 0x99) || oldCF) {
			vCPU.AL = cast(ubyte)(vCPU.AL + 0x60);
			vCPU.CF = 1;
		} else vCPU.CF = 0;

		++vCPU.EIP;
		return;
	}
	case 0x28: { // SUB R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= vCPU.AL; break;
		case RM_REG_001: r -= vCPU.CL; break;
		case RM_REG_010: r -= vCPU.DL; break;
		case RM_REG_011: r -= vCPU.BL; break;
		case RM_REG_100: r -= vCPU.AH; break;
		case RM_REG_101: r -= vCPU.CH; break;
		case RM_REG_110: r -= vCPU.DH; break;
		case RM_REG_111: r -= vCPU.BH; break;
		default:
		}
		__hflag8_1(r);
		__iu8(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x29: { // SUB R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= vCPU.AX; break;
		case RM_REG_001: r -= vCPU.CX; break;
		case RM_REG_010: r -= vCPU.DX; break;
		case RM_REG_011: r -= vCPU.BX; break;
		case RM_REG_100: r -= vCPU.SP; break;
		case RM_REG_101: r -= vCPU.BP; break;
		case RM_REG_110: r -= vCPU.SI; break;
		case RM_REG_111: r -= vCPU.DI; break;
		default:
		}
		__hflag16_1(r);
		__iu16(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x2A: { // SUB REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AL - r;
			vCPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r = vCPU.CL - r;
			vCPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r = vCPU.DL - r;
			vCPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r = vCPU.BL - r;
			vCPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r = vCPU.AH - r;
			vCPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r = vCPU.CH - r;
			vCPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r = vCPU.DH - r;
			vCPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r = vCPU.BH - r;
			vCPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_1(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x2B: { // SUB REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AX - r;
			vCPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r = vCPU.CX - r;
			vCPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r = vCPU.DX - r;
			vCPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r = vCPU.BX - r;
			vCPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r = vCPU.SP - r;
			vCPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r = vCPU.BP - r;
			vCPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r = vCPU.SI - r;
			vCPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r = vCPU.DI - r;
			vCPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_1(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x2C: { // SUB AL, IMM8
		int r = vCPU.AL - __fu8_i;
		__hflag8_1(r);
		vCPU.AL = cast(ubyte)r;
		vCPU.EIP += 2;
		return;
	}
	case 0x2D: { // SUB AX, IMM16
		int r = vCPU.AX - __fu16_i;
		__hflag16_1(r);
		vCPU.AX = cast(ushort)r;
		vCPU.EIP += 3;
		return;
	}
	case 0x2E: // CS:
		Seg = SEG_CS;
		++vCPU.EIP;
		return;
	case 0x2F: { // DAS
		const ubyte oldAL = vCPU.AL;
		const ubyte oldCF = vCPU.CF;
		vCPU.CF = 0;

		if (((oldAL & 0xF) > 9) || vCPU.AF) {
			vCPU.AL = cast(ubyte)(vCPU.AL - 6);
			vCPU.CF = oldCF || (vCPU.AL & 0x80);
			vCPU.AF = 1;
		} else vCPU.AF = 0;

		if ((oldAL > 0x99) || oldCF) {
			vCPU.AL = cast(ubyte)(vCPU.AL - 0x60);
			vCPU.CF = 1;
		} else vCPU.CF = 0;

		++vCPU.EIP;
		return;
	}
	case 0x30: { // XOR R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r ^= vCPU.AL; break;
		case RM_REG_001: r ^= vCPU.CL; break;
		case RM_REG_010: r ^= vCPU.DL; break;
		case RM_REG_011: r ^= vCPU.BL; break;
		case RM_REG_100: r ^= vCPU.AH; break;
		case RM_REG_101: r ^= vCPU.CH; break;
		case RM_REG_110: r ^= vCPU.DH; break;
		case RM_REG_111: r ^= vCPU.BH; break;
		default:
		}
		__hflag8_3(r);
		__iu8(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x31: { // XOR R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r ^= vCPU.AX; break;
		case RM_REG_001: r ^= vCPU.CX; break;
		case RM_REG_010: r ^= vCPU.DX; break;
		case RM_REG_011: r ^= vCPU.BX; break;
		case RM_REG_100: r ^= vCPU.SP; break;
		case RM_REG_101: r ^= vCPU.BP; break;
		case RM_REG_110: r ^= vCPU.SI; break;
		case RM_REG_111: r ^= vCPU.DI; break;
		default:
		}
		__hflag16_3(r);
		__iu16(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x32: { // XOR REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AL ^ r;
			vCPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r = vCPU.CL ^ r;
			vCPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r = vCPU.DL ^ r;
			vCPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r = vCPU.BL ^ r;
			vCPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r = vCPU.AH ^ r;
			vCPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r = vCPU.CH ^ r;
			vCPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r = vCPU.DH ^ r;
			vCPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r = vCPU.BH ^ r;
			vCPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_3(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x33: { // XOR REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AX ^ r;
			vCPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r = vCPU.CX ^ r;
			vCPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r = vCPU.DX ^ r;
			vCPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r = vCPU.BX ^ r;
			vCPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r = vCPU.SP ^ r;
			vCPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r = vCPU.BP ^ r;
			vCPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r = vCPU.SI ^ r;
			vCPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r = vCPU.DI ^ r;
			vCPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_3(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x34: { // XOR AL, IMM8
		int r = vCPU.AL ^ __fu8_i;
		__hflag8_3(r);
		vCPU.AL = cast(ubyte)r;
		vCPU.EIP += 2;
		return;
	}
	case 0x35: { // XOR AX, IMM16
		int r = vCPU.AX ^ __fu16_i;
		__hflag16_3(r);
		vCPU.AX = cast(ushort)r;
		vCPU.EIP += 3;
		return;
	}
	case 0x36: // SS:
		Seg = SEG_SS;
		++vCPU.EIP;
		return;
	case 0x37: // AAA
		if (((vCPU.AL & 0xF) > 9) || vCPU.AF) {
			vCPU.AX = cast(ushort)(vCPU.AX + 0x106);
			vCPU.AF = vCPU.CF = 1;
		} else vCPU.AF = vCPU.CF = 0;
		vCPU.AL = cast(ubyte)(vCPU.AL & 0xF);
		++vCPU.EIP;
		return;
	case 0x38: { // CMP R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= vCPU.AL; break;
		case RM_REG_001: r -= vCPU.CL; break;
		case RM_REG_010: r -= vCPU.DL; break;
		case RM_REG_011: r -= vCPU.BL; break;
		case RM_REG_100: r -= vCPU.AH; break;
		case RM_REG_101: r -= vCPU.CH; break;
		case RM_REG_110: r -= vCPU.DH; break;
		case RM_REG_111: r -= vCPU.BH; break;
		default:
		}
		__hflag8_1(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x39: { // CMP R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= vCPU.AX; break;
		case RM_REG_001: r -= vCPU.CX; break;
		case RM_REG_010: r -= vCPU.DX; break;
		case RM_REG_011: r -= vCPU.BX; break;
		case RM_REG_100: r -= vCPU.SP; break;
		case RM_REG_101: r -= vCPU.BP; break;
		case RM_REG_110: r -= vCPU.SI; break;
		case RM_REG_111: r -= vCPU.DI; break;
		default:
		}
		__hflag16_1(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x3A: { // CMP REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r = vCPU.AL - r; break;
		case RM_REG_001: r = vCPU.CL - r; break;
		case RM_REG_010: r = vCPU.DL - r; break;
		case RM_REG_011: r = vCPU.BL - r; break;
		case RM_REG_100: r = vCPU.AH - r; break;
		case RM_REG_101: r = vCPU.CH - r; break;
		case RM_REG_110: r = vCPU.DH - r; break;
		case RM_REG_111: r = vCPU.BH - r; break;
		default:
		}
		__hflag8_1(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x3B: { // CMP REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r = vCPU.AX - r; break;
		case RM_REG_001: r = vCPU.CX - r; break;
		case RM_REG_010: r = vCPU.DX - r; break;
		case RM_REG_011: r = vCPU.BX - r; break;
		case RM_REG_100: r = vCPU.SP - r; break;
		case RM_REG_101: r = vCPU.BP - r; break;
		case RM_REG_110: r = vCPU.SI - r; break;
		case RM_REG_111: r = vCPU.DI - r; break;
		default:
		}
		__hflag16_1(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x3C: { // CMP AL, IMM8
		__hflag8_1(vCPU.AL - __fu8_i);
		vCPU.EIP += 2;
		return;
	}
	case 0x3D: { // CMP AX, IMM16
		__hflag16_1(vCPU.AX - __fu16_i);
		vCPU.EIP += 3;
		return;
	}
	case 0x3E: // DS:
		Seg = SEG_DS;
		++vCPU.EIP;
		return;
	case 0x3F: // AAS
		if (((vCPU.AL & 0xF) > 9) || vCPU.AF) {
			vCPU.AX = cast(ushort)(vCPU.AX - 6);
			vCPU.AH = cast(ubyte)(vCPU.AH - 1);
			vCPU.AF = vCPU.CF = 1;
		} else {
			vCPU.AF = vCPU.CF = 0;
		}
		vCPU.AL = cast(ubyte)(vCPU.AL & 0xF);
		++vCPU.EIP;
		return;
	case 0x40: { // INC AX
		const int r = vCPU.AX + 1;
		__hflag16_2(r);
		vCPU.AX = cast(ubyte)r;
		++vCPU.EIP;
		return;
	}
	case 0x41: { // INC CX
		const int r = vCPU.CX + 1;
		__hflag16_2(r);
		vCPU.CX = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x42: { // INC DX
		const int r = vCPU.DX + 1;
		__hflag16_2(r);
		vCPU.DX = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x43: { // INC BX
		const int r = vCPU.BX + 1;
		__hflag16_2(r);
		vCPU.BX = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x44: { // INC SP
		const int r = vCPU.SP + 1;
		__hflag16_2(r);
		vCPU.SP = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x45: { // INC BP
		const int r = vCPU.BP + 1;
		__hflag16_2(r);
		vCPU.BP = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x46: { // INC SI
		const int r = vCPU.SI + 1;
		__hflag16_2(r);
		vCPU.SI = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x47: { // INC DI
		const int r = vCPU.DI + 1;
		__hflag16_2(r);
		vCPU.DI = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x48: { // DEC AX
		const int r = vCPU.AX - 1;
		__hflag16_2(r);
		vCPU.AX = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x49: { // DEC CX
		const int r = vCPU.CX - 1;
		__hflag16_2(r);
		vCPU.CX = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x4A: { // DEC DX
		const int r = vCPU.DX - 1;
		__hflag16_2(r);
		vCPU.DX = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x4B: { // DEC BX
		const int r = vCPU.BX - 1;
		__hflag16_2(r);
		vCPU.BX = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x4C: { // DEC SP
		const int r = vCPU.SP - 1;
		__hflag16_2(r);
		vCPU.SP = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x4D: { // DEC BP
		const int r = vCPU.BP - 1;
		__hflag16_2(r);
		vCPU.BP = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x4E: { // DEC SI
		const int r = vCPU.SI - 1;
		__hflag16_2(r);
		vCPU.SI = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x4F: { // DEC DI
		const int r = vCPU.DI - 1;
		__hflag16_2(r);
		vCPU.DI = cast(ushort)r;
		++vCPU.EIP;
		return;
	}
	case 0x50: // PUSH AX
		push(vCPU.AX);
		++vCPU.EIP;
		return;
	case 0x51: // PUSH CX
		push(vCPU.CX);
		++vCPU.EIP;
		return;
	case 0x52: // PUSH DX
		push(vCPU.DX);
		++vCPU.EIP;
		return;
	case 0x53: // PUSH BX
		push(vCPU.BX);
		++vCPU.EIP;
		return;
	case 0x54: // PUSH SP
		push(vCPU.SP);
		++vCPU.EIP;
		return;
	case 0x55: // PUSH BP
		push(vCPU.BP);
		++vCPU.EIP;
		return;
	case 0x56: // PUSH SI
		push(vCPU.SI);
		++vCPU.EIP;
		return;
	case 0x57: // PUSH DI
		push(vCPU.DI);
		++vCPU.EIP;
		return;
	case 0x58: // POP AX
		vCPU.AX = pop;
		++vCPU.EIP;
		return;
	case 0x59: // POP CX
		vCPU.CX = pop;
		++vCPU.EIP;
		return;
	case 0x5A: // POP DX
		vCPU.DX = pop;
		++vCPU.EIP;
		return;
	case 0x5B: // POP BX
		vCPU.BX = pop;
		++vCPU.EIP;
		return;
	case 0x5C: // POP SP
		vCPU.SP = pop;
		++vCPU.EIP;
		return;
	case 0x5D: // POP BP
		vCPU.BP = pop;
		++vCPU.EIP;
		return;
	case 0x5E: // POP SI
		vCPU.SI = pop;
		++vCPU.EIP;
		return;
	case 0x5F: // POP DI
		vCPU.DI = pop;
		++vCPU.EIP;
		return;
	case 0x70: // JO            SHORT-LABEL
		vCPU.EIP += vCPU.OF ? __fi8_i : 2;
		return;
	case 0x71: // JNO           SHORT-LABEL
		vCPU.EIP += vCPU.OF ? 2 : __fi8_i;
		return;
	case 0x72: // JB/JNAE/JC    SHORT-LABEL
		vCPU.EIP += vCPU.CF ? __fi8_i : 2;
		return;
	case 0x73: // JNB/JAE/JNC   SHORT-LABEL
		vCPU.EIP += vCPU.CF ? 2 : __fi8_i;
		return;
	case 0x74: // JE/JZ         SHORT-LABEL
		vCPU.EIP += vCPU.ZF ? __fi8_i : 2;
		return;
	case 0x75: // JNE/JNZ       SHORT-LABEL
		vCPU.EIP += vCPU.ZF ? 2 : __fi8_i;
		return;
	case 0x76: // JBE/JNA       SHORT-LABEL
		vCPU.EIP += (vCPU.CF || vCPU.ZF) ? __fi8_i : 2;
		return;
	case 0x77: // JNBE/JA       SHORT-LABEL
		vCPU.EIP += vCPU.CF == 0 && vCPU.ZF == 0 ? __fi8_i : 2;
		return;
	case 0x78: // JS            SHORT-LABEL
		vCPU.EIP += vCPU.SF ? __fi8_i : 2;
		return;
	case 0x79: // JNS           SHORT-LABEL
		vCPU.EIP += vCPU.SF ? 2 : __fi8_i;
		return;
	case 0x7A: // JP/JPE        SHORT-LABEL
		vCPU.EIP += vCPU.PF ? __fi8_i : 2;
		return;
	case 0x7B: // JNP/JPO       SHORT-LABEL
		vCPU.EIP += vCPU.PF ? 2 : __fi8_i;
		return;
	case 0x7C: // JL/JNGE       SHORT-LABEL
		vCPU.EIP += vCPU.SF != vCPU.OF ? __fi8_i : 2;
		return;
	case 0x7D: // JNL/JGE       SHORT-LABEL
		vCPU.EIP += vCPU.SF == vCPU.OF ? __fi8_i : 2;
		return;
	case 0x7E: // JLE/JNG       SHORT-LABEL
		vCPU.EIP += vCPU.SF != vCPU.OF || vCPU.ZF ? __fi8_i : 2;
		return;
	case 0x7F: // JNLE/JG       SHORT-LABEL
		vCPU.EIP += vCPU.SF == vCPU.OF && vCPU.ZF == 0 ? __fi8_i : 2;
		return;
	case 0x80: { // GRP1 R/M8, IMM8
		const ubyte rm = __fu8_i; // Get ModR/M byte
		const ushort im = __fu8_i(1);
		const int addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) { // REG
		case RM_REG_000: // 000 - ADD
			r += im;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_001: // 001 - OR
			r |= im;
			__hflag16_3(r);
			__iu16(r, addr);
			break;
		case RM_REG_010: // 010 - ADC
			r += im;
			if (vCPU.CF) ++r;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (vCPU.CF) --r;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_100: // 100 - AND
			r &= im;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_101: // 101 - SUB
			r -= im;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_110: // 110 - XOR
			r ^= im;
			__hflag16_3(r);
			__iu16(r, addr);
			break;
		case RM_REG_111: // 111 - CMP
			r -= im;
			__hflag16_3(r);
			break;
		default:
			info("Invalid ModR/M from GRP1_8");
			goto EXEC16_ILLEGAL;
		}
		vCPU.EIP += 3;
		return;
	}
	case 0x81: { // GRP1 R/M16, IMM16
		const ubyte rm = __fu8_i; // Get ModR/M byte
		const ushort im = __fu16_i(1);
		const int addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) { // REG
		case RM_REG_000: // 000 - ADD
			r += im;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_001: // 001 - OR
			r |= im;
			__hflag16_3(r);
			__iu16(r, addr);
			break;
		case RM_REG_010: // 010 - ADC
			r += im;
			if (vCPU.CF) ++r;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (vCPU.CF) --r;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_100: // 100 - AND
			r &= im;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_101: // 101 - SUB
			r -= im;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_110: // 110 - XOR
			r ^= im;
			__hflag16_3(r);
			__iu16(r, addr);
			break;
		case RM_REG_111: // 111 - CMP
			r -= im;
			__hflag16_3(r);
			break;
		default:
			info("Invalid ModR/M from GRP1_16");
			goto EXEC16_ILLEGAL;
		}
		vCPU.EIP += 4;
		return;
	}
	case 0x82: { // GRP2 R/M8, IMM8
		const ubyte rm = __fu8_i; // Get ModR/M byte
		const ushort im = __fu8_i(1);
		const int addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) { // ModRM REG
		case RM_REG_000: // 000 - ADD
			r += im;
			__iu8(r, addr);
			break;
		case RM_REG_010: // 010 - ADC
			r += im;
			if (vCPU.CF) ++r;
			__iu8(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (vCPU.CF) --r;
			__iu8(r, addr);
			break;
		case RM_REG_101: // 101 - SUB
			r -= im;
			__iu8(r, addr);
			break;
		case RM_REG_111: // 111 - CMP
			r -= im;
			break;
		default:
			info("Invalid ModR/M for GRP2_8");
			goto EXEC16_ILLEGAL;
		}
		__hflag8_1(r);
		vCPU.EIP += 3;
		return;
	}
	case 0x83: { // GRP2 R/M16, IMM8
		const ubyte rm = __fu8_i; // Get ModR/M byte
		const ushort im = __fu8_i(1);
		const int addr = get_ea(rm, 1);
		int r = __fu8(addr);
		switch (rm & RM_REG) { // ModRM REG
		case RM_REG_000: // 000 - ADD
			r += im;
			__iu16(r, addr);
			break;
		case RM_REG_010: // 010 - ADC
			r += im;
			if (vCPU.CF) ++r;
			__iu16(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (vCPU.CF) --r;
			__iu16(r, addr);
			break;
		case RM_REG_101: // 101 - SUB
			r -= im;
			__iu16(r, addr);
			break;
		case RM_REG_111: // 111 - CMP
			r -= im;
			break;
		default:
			info("Invalid ModR/M for GRP2_16");
			goto EXEC16_ILLEGAL;
		}
		__hflag16_1(r);
		vCPU.EIP += 3;
		return;
	}
	case 0x84: { // TEST R/M8, REG8
		const ubyte rm = __fu8_i;
		int n = __fu8(get_ea(rm));
		int r = void;
		switch (rm & RM_REG) {
		case RM_REG_000: r = vCPU.AL & n; break;
		case RM_REG_001: r = vCPU.CL & n; break;
		case RM_REG_010: r = vCPU.DL & n; break;
		case RM_REG_011: r = vCPU.BL & n; break;
		case RM_REG_100: r = vCPU.AH & n; break;
		case RM_REG_101: r = vCPU.CH & n; break;
		case RM_REG_110: r = vCPU.DH & n; break;
		case RM_REG_111: r = vCPU.BH & n; break;
		default:
		}
		__hflag8_3(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x85: { // TEST R/M16, REG16
		const ubyte rm = __fu8_i;
		int n = __fu16(get_ea(rm, 1));
		int r = void;
		switch (rm & RM_REG) {
		case RM_REG_000: r = vCPU.AX & n; break;
		case RM_REG_001: r = vCPU.CX & n; break;
		case RM_REG_010: r = vCPU.DX & n; break;
		case RM_REG_011: r = vCPU.BX & n; break;
		case RM_REG_100: r = vCPU.SP & n; break;
		case RM_REG_101: r = vCPU.BP & n; break;
		case RM_REG_110: r = vCPU.SI & n; break;
		case RM_REG_111: r = vCPU.DI & n; break;
		default:
		}
		__hflag16_3(r);
		vCPU.EIP += 2;
		return;
	}
	case 0x86: { // XCHG REG8, R/M8
		const ubyte rm = __fu8_i;
		const int addr = get_ea(rm);
		// temp <- REG
		// REG  <- MEM
		// MEM  <- temp
		ubyte r = void; ubyte s = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AL; vCPU.AL = s;
			break;
		case RM_REG_001:
			r = vCPU.CL; vCPU.CL = s;
			break;
		case RM_REG_010:
			r = vCPU.DL; vCPU.DL = s;
			break;
		case RM_REG_011:
			r = vCPU.BL; vCPU.BL = s;
			break;
		case RM_REG_100:
			r = vCPU.AH; vCPU.AH = s;
			break;
		case RM_REG_101:
			r = vCPU.CH; vCPU.CH = s;
			break;
		case RM_REG_110:
			r = vCPU.DH; vCPU.DH = s;
			break;
		case RM_REG_111:
			r = vCPU.BH; vCPU.BH = s;
			break;
		default:
		}
		__iu8(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x87: { // XCHG REG16, R/M16
		const ubyte rm = __fu8_i;
		const int addr = get_ea(rm, 1);
		// temp <- REG
		// REG  <- MEM
		// MEM  <- temp
		ushort r = void; ushort s = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = vCPU.AX; vCPU.AX = s;
			break;
		case RM_REG_001:
			r = vCPU.CX; vCPU.CX = s;
			break;
		case RM_REG_010:
			r = vCPU.DX; vCPU.DX = s;
			break;
		case RM_REG_011:
			r = vCPU.BX; vCPU.BX = s;
			break;
		case RM_REG_100:
			r = vCPU.SP; vCPU.SP = s;
			break;
		case RM_REG_101:
			r = vCPU.BP; vCPU.BP = s;
			break;
		case RM_REG_110:
			r = vCPU.SI; vCPU.SI = s;
			break;
		case RM_REG_111:
			r = vCPU.DI; vCPU.DI = s;
			break;
		default:
		}
		__iu16(r, addr);
		vCPU.EIP += 2;
		return;
	}
	case 0x88: { // MOV R/M8, REG8
		const ubyte rm = __fu8_i;
		int addr = get_ea(rm);
		switch (rm & RM_REG) {
		case RM_REG_000: __iu8(vCPU.AL, addr); break;
		case RM_REG_001: __iu8(vCPU.CL, addr); break;
		case RM_REG_010: __iu8(vCPU.DL, addr); break;
		case RM_REG_011: __iu8(vCPU.BL, addr); break;
		case RM_REG_100: __iu8(vCPU.AH, addr); break;
		case RM_REG_101: __iu8(vCPU.CH, addr); break;
		case RM_REG_110: __iu8(vCPU.DH, addr); break;
		case RM_REG_111: __iu8(vCPU.BH, addr); break;
		default:
		}
		vCPU.EIP += 2;
		return;
	}
	case 0x89: { // MOV R/M16, REG16
		const ubyte rm = __fu8_i;
		int addr = get_ea(rm, 1);
		switch (rm & RM_REG) {
		case RM_REG_000: __iu16(vCPU.AX, addr); break;
		case RM_REG_001: __iu16(vCPU.CX, addr); break;
		case RM_REG_010: __iu16(vCPU.DX, addr); break;
		case RM_REG_011: __iu16(vCPU.BX, addr); break;
		case RM_REG_100: __iu16(vCPU.SP, addr); break;
		case RM_REG_101: __iu16(vCPU.BP, addr); break;
		case RM_REG_110: __iu16(vCPU.SI, addr); break;
		case RM_REG_111: __iu16(vCPU.DI, addr); break;
		default:
		}
		vCPU.EIP += 2;
		return;
	}
	case 0x8A: { // MOV REG8, R/M8
		const ubyte rm = __fu8_i;
		int addr = get_ea(rm);
		switch (rm & RM_REG) {
		case RM_REG_000: vCPU.AL = __fu8(addr); break;
		case RM_REG_001: vCPU.CL = __fu8(addr); break;
		case RM_REG_010: vCPU.DL = __fu8(addr); break;
		case RM_REG_011: vCPU.BL = __fu8(addr); break;
		case RM_REG_100: vCPU.AH = __fu8(addr); break;
		case RM_REG_101: vCPU.CH = __fu8(addr); break;
		case RM_REG_110: vCPU.DH = __fu8(addr); break;
		case RM_REG_111: vCPU.BH = __fu8(addr); break;
		default:
		}
		vCPU.EIP += 2;
		return;
	}
	case 0x8B: { // MOV REG16, R/M16
		const ubyte rm = __fu8_i;
		int addr = get_ea(rm, 1);
		switch (rm & RM_REG) {
		case RM_REG_000: vCPU.AX = __fu16(addr); break;
		case RM_REG_001: vCPU.CX = __fu16(addr); break;
		case RM_REG_010: vCPU.DX = __fu16(addr); break;
		case RM_REG_011: vCPU.BX = __fu16(addr); break;
		case RM_REG_100: vCPU.SP = __fu16(addr); break;
		case RM_REG_101: vCPU.BP = __fu16(addr); break;
		case RM_REG_110: vCPU.SI = __fu16(addr); break;
		case RM_REG_111: vCPU.DI = __fu16(addr); break;
		default:
		}
		vCPU.EIP += 2;
		return;
	}
	case 0x8C: { // MOV R/M16, SEGREG
		// MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
		const byte rm = __fu8_i;
		const int addr = get_ea(rm, 1);
		switch (rm & RM_REG) { // if REG[3] is clear, trip to default
		case RM_REG_100: __iu16(vCPU.ES, addr); break;
		case RM_REG_101: __iu16(vCPU.CS, addr); break;
		case RM_REG_110: __iu16(vCPU.SS, addr); break;
		case RM_REG_111: __iu16(vCPU.DS, addr); break;
		default: // when bit 6 is clear (REG[3])
			info("Invalid ModR/M for SEGREG->RM");
			goto EXEC16_ILLEGAL;
		}
		vCPU.EIP += 2;
		return;
	}
	case 0x8D: { // LEA REG16, MEM16
		const ubyte rm = __fu8_i;
		const ushort addr = cast(ushort)get_ea(rm);
		switch (rm & RM_REG) {
		case RM_REG_000: vCPU.AX = addr; break;
		case RM_REG_001: vCPU.CX = addr; break;
		case RM_REG_010: vCPU.DX = addr; break;
		case RM_REG_011: vCPU.BX = addr; break;
		case RM_REG_100: vCPU.BP = addr; break;
		case RM_REG_101: vCPU.SP = addr; break;
		case RM_REG_110: vCPU.SI = addr; break;
		case RM_REG_111: vCPU.DI = addr; break;
		default: // Never happens
		}
		vCPU.EIP += 2;
		return;
	}
	case 0x8E: { // MOV SEGREG, R/M16
		// MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
		const byte rm = __fu8_i;
		const int addr = get_ea(rm, 1);
		switch (rm & RM_REG) { // if REG[3] is clear, trip to default
		case RM_REG_100: vCPU.ES = __fu16(addr); break;
		case RM_REG_101: vCPU.CS = __fu16(addr); break;
		case RM_REG_110: vCPU.SS = __fu16(addr); break;
		case RM_REG_111: vCPU.DS = __fu16(addr); break;
		default: // when bit 6 is clear (REG[3])
			info("Invalid ModR/M for SEGREG<-RM");
			goto EXEC16_ILLEGAL;
		}
		vCPU.EIP += 2;
		return;
	}
	case 0x8F: { // POP R/M16
		const ubyte rm = __fu8_i;
		if (rm & RM_REG) { // REG MUST be 000
			info("Invalid ModR/M for POP R/M16");
			goto EXEC16_ILLEGAL;
		}
		push(__fu16(get_ea(rm, 1)));
		vCPU.EIP += 2;
		return;
	}
	case 0x90: // NOP (aka XCHG AX, AX)
		++vCPU.EIP;
		return;
	case 0x91: { // XCHG AX, CX
		const ushort r = vCPU.AX;
		vCPU.AX = vCPU.CX;
		vCPU.CX = r;
		++vCPU.EIP;
		return;
	}
	case 0x92: { // XCHG AX, DX
		const ushort r = vCPU.AX;
		vCPU.AX = vCPU.DX;
		vCPU.DX = r;
		++vCPU.EIP;
		return;
	}
	case 0x93: { // XCHG AX, BX
		const ushort r = vCPU.AX;
		vCPU.AX = vCPU.BX;
		vCPU.BX = r;
		++vCPU.EIP;
		return;
	}
	case 0x94: { // XCHG AX, SP
		const ushort r = vCPU.AX;
		vCPU.AX = vCPU.SP;
		vCPU.SP = r;
		++vCPU.EIP;
		return;
	}
	case 0x95: { // XCHG AX, BP
		const ushort r = vCPU.AX;
		vCPU.AX = vCPU.BP;
		vCPU.BP = r;
		++vCPU.EIP;
		return;
	}
	case 0x96: { // XCHG AX, SI
		const ushort r = vCPU.AX;
		vCPU.AX = vCPU.SI;
		vCPU.SI = r;
		++vCPU.EIP;
		return;
	}
	case 0x97: { // XCHG AX, DI
		const ushort r = vCPU.AX;
		vCPU.AX = vCPU.DI;
		vCPU.DI = r;
		++vCPU.EIP;
		return;
	}
	case 0x98: // CBW
		vCPU.AH = vCPU.AL & 0x80 ? 0xFF : 0;
		++vCPU.EIP;
		return;
	case 0x99: // CWD
		vCPU.DX = vCPU.AX & 0x8000 ? 0xFFFF : 0;
		++vCPU.EIP;
		return;
	case 0x9A: // CALL FAR_PROC
		push(vCPU.CS);
		push(vCPU.IP);
		vCPU.CS = __fu16_i;
		vCPU.IP = __fu16_i(2);
		return;
	case 0x9B: // WAIT
	// Causes the processor to check for and handle pending, unmasked,
	// floating-point exceptions before proceeding.
	//TODO: WAIT
		++vCPU.EIP;
		return;
	case 0x9C: // PUSHF
		push(FLAG);
		++vCPU.EIP;
		return;
	case 0x9D: // POPF
		FLAG = pop;
		++vCPU.EIP;
		return;
	case 0x9E: // SAHF (AH to Flags)
		FLAGB = vCPU.AH;
		++vCPU.EIP;
		return;
	case 0x9F: // LAHF (Flags to AH)
		vCPU.AH = FLAGB;
		++vCPU.EIP;
		return;
	case 0xA0: // MOV AL, MEM8
		vCPU.AL = __fu8(__fu16_i);
		vCPU.EIP += 2;
		return;
	case 0xA1: // MOV AX, MEM16
		vCPU.AX = __fu16(__fu16_i);
		vCPU.EIP += 3;
		return;
	case 0xA2: // MOV MEM8, AL
		__iu8(vCPU.AL, __fu16_i);
		vCPU.EIP += 2;
		return;
	case 0xA3: // MOV MEM16, AX
		__iu16(vCPU.AX, __fu16_i);
		vCPU.EIP += 3;
		return;
	case 0xA4: // MOVS DEST-STR8, SRC-STR8

		return;
	case 0xA5: // MOVS DEST-STR16, SRC-STR16

		return;
	case 0xA6: // CMPS DEST-STR8, SRC-STR8
		__hflag8_1(
			__fu8(get_ad(vCPU.DS, vCPU.SI)) - __fu8(get_ad(vCPU.ES, vCPU.DI))
		);
		if (vCPU.DF) {
			--vCPU.DI;
			--vCPU.SI;
		} else {
			++vCPU.DI;
			++vCPU.SI;
		}
		return;
	case 0xA7: // CMPSW DEST-STR16, SRC-STR16
		__hflag16_1(
			__fu16(get_ad(vCPU.DS, vCPU.SI)) - __fu16(get_ad(vCPU.ES, vCPU.DI))
		);
		if (vCPU.DF) {
			vCPU.DI -= 2;
			vCPU.SI -= 2;
		} else {
			vCPU.DI += 2;
			vCPU.SI += 2;
		}
		return;
	case 0xA8: // TEST AL, IMM8
		__hflag8_3(vCPU.AL & __fu8_i);
		vCPU.EIP += 2;
		return;
	case 0xA9: // TEST AX, IMM16
		__hflag16_3(vCPU.AX & __fu16_i);
		vCPU.EIP += 3;
		return;
	case 0xAA: // STOS DEST-STR8
		__iu8(vCPU.AL, get_ad(vCPU.ES, vCPU.DI));
		//vCPU.DI = DF ? vCPU.DI - 1 : vCPU.DI + 1;
		if (vCPU.DF) --vCPU.DI; else ++vCPU.DI;
		++vCPU.EIP;
		return;
	case 0xAB: // STOS DEST-STR16
		__iu16(vCPU.AX, get_ad(vCPU.ES, vCPU.DI));
		//vCPU.DI = DF ? vCPU.DI - 2 : vCPU.DI + 2;
		if (vCPU.DF) vCPU.DI -= 2; else vCPU.DI += 2;
		++vCPU.EIP;
		return;
	case 0xAC: // LODS SRC-STR8
		vCPU.AL = __fu8(get_ad(vCPU.DS, vCPU.SI));
		//vCPU.SI = DF ? vCPU.SI - 1 : vCPU.SI + 1;
		if (vCPU.DF) --vCPU.SI; else ++vCPU.SI;
		++vCPU.EIP;
		return;
	case 0xAD: // LODS SRC-STR16
		vCPU.AX = __fu16(get_ad(vCPU.DS, vCPU.SI));
		//vCPU.SI = DF ? vCPU.SI - 2 : vCPU.SI + 2;
		if (vCPU.DF) vCPU.SI -= 2; else vCPU.SI += 2;
		++vCPU.EIP;
		return;
	case 0xAE: // SCAS DEST-STR8
		__hflag8_1(vCPU.AL - __fu8(get_ad(vCPU.ES, vCPU.DI)));
		//vCPU.DI = DF ? vCPU.DI - 1 : vCPU.DI + 1;
		if (vCPU.DF) --vCPU.DI; else ++vCPU.DI;
		++vCPU.EIP;
		return;
	case 0xAF: // SCAS DEST-STR16
		__hflag16_1(vCPU.AX - __fu16(get_ad(vCPU.ES, vCPU.DI)));
		//vCPU.DI = DF ? vCPU.DI - 2 : vCPU.DI + 2;
		if (vCPU.DF) vCPU.DI -= 2; else vCPU.DI += 2;
		++vCPU.EIP;
		return;
	case 0xB0: // MOV AL, IMM8
		vCPU.AL = __fu8_i;
		vCPU.EIP += 2;
		return;
	case 0xB1: // MOV CL, IMM8
		vCPU.CL = __fu8_i;
		vCPU.EIP += 2;
		return;
	case 0xB2: // MOV DL, IMM8
		vCPU.DL = __fu8_i;
		vCPU.EIP += 2;
		return;
	case 0xB3: // MOV BL, IMM8
		vCPU.BL = __fu8_i;
		vCPU.EIP += 2;
		return;
	case 0xB4: // MOV AH, IMM8
		vCPU.AH = __fu8_i;
		vCPU.EIP += 2;
		return;
	case 0xB5: // MOV CH, IMM8
		vCPU.CH = __fu8_i;
		vCPU.EIP += 2;
		return;
	case 0xB6: // MOV DH, IMM8  
		vCPU.DH = __fu8_i;
		vCPU.EIP += 2;
		return;
	case 0xB7: // MOV BH, IMM8
		vCPU.BH = __fu8_i;
		vCPU.EIP += 2;
		return;
	case 0xB8: // MOV AX, IMM16
		vCPU.AX = __fu16_i;
		vCPU.EIP += 3;
		return;
	case 0xB9: // MOV CX, IMM16
		vCPU.CX = __fu16_i;
		vCPU.EIP += 3;
		return;
	case 0xBA: // MOV DX, IMM16
		vCPU.DX = __fu16_i;
		vCPU.EIP += 3;
		return;
	case 0xBB: // MOV BX, IMM16
		vCPU.BX = __fu16_i;
		vCPU.EIP += 3;
		return;
	case 0xBC: // MOV SP, IMM16
		vCPU.SP = __fu16_i;
		vCPU.EIP += 3;
		return;
	case 0xBD: // MOV BP, IMM16
		vCPU.BP = __fu16_i;
		vCPU.EIP += 3;
		return;
	case 0xBE: // MOV SI, IMM16
		vCPU.SI = __fu16_i;
		vCPU.EIP += 3;
		return;
	case 0xBF: // MOV DI, IMM16
		vCPU.DI = __fu16_i;
		vCPU.EIP += 3;
		return;
	case 0xC2: // RET IMM16 (NEAR)
		vCPU.IP = pop;
		vCPU.SP += __fu16_i;
		return;
	case 0xC3: // RET (NEAR)
		vCPU.IP = pop;
		return;
	case 0xC4, 0xC5: { // LES/LDS REG16, MEM16
		// Load into REG and ES/DS
		const ubyte rm = __fu8_i;
		const ushort r = __fu16(get_ea(rm, 1));
		if (op == 0xC4)
			vCPU.ES = r;
		else
			vCPU.DS = r;
		switch (rm & RM_REG) {
		case RM_REG_000: vCPU.AX = r; break;
		case RM_REG_001: vCPU.CX = r; break;
		case RM_REG_010: vCPU.DX = r; break;
		case RM_REG_011: vCPU.BX = r; break;
		case RM_REG_100: vCPU.SP = r; break;
		case RM_REG_101: vCPU.BP = r; break;
		case RM_REG_110: vCPU.SI = r; break;
		case RM_REG_111: vCPU.DI = r; break;
		default:
		}
		vCPU.EIP += 2;
		return;
	}
	case 0xC6: { // MOV MEM8, IMM8
		const ubyte rm = __fu8_i;
		if (rm & RM_REG) { // No register operation allowed
			info("Invalid ModR/M for MOV MEM8");
			goto EXEC16_ILLEGAL;
		}
		__iu8(__fu8_i(1), get_ea(rm));
		return;
	}
	case 0xC7: { // MOV MEM16, IMM16
		const ubyte rm = __fu8_i;
		if (rm & RM_REG) { // No register operation allowed
			info("Invalid ModR/M for MOV MEM16");
			goto EXEC16_ILLEGAL;
		}
		__iu16(__fu16_i(1), get_ea(rm, 1));
		return;
	}
	case 0xCA: // RET IMM16 (FAR)
		vCPU.IP = pop;
		vCPU.CS = pop;
		vCPU.SP += __fu16_i;
		return;
	case 0xCB: // RET (FAR)
		vCPU.IP = pop;
		vCPU.CS = pop;
		return;
	case 0xCC: // INT 3
		Raise(3);
		++vCPU.EIP;
		return;
	case 0xCD: // INT IMM8
		Raise(__fu8_i);
		vCPU.EIP += 2;
		return;
	case 0xCE: // INTO
		if (vCPU.CF) Raise(4);
		++vCPU.EIP;
		return;
	case 0xCF: // IRET
		vCPU.IP = pop;
		vCPU.CS = pop;
		FLAG = pop;
		++vCPU.EIP;
		return;
	case 0xD0: { // GRP2 R/M8, 1
		/*const ubyte rm = __fu8_i;
		const int addr = get_ea(rm);
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - ROL

			break;
		case RM_REG_001: // 001 - ROR

			break;
		case RM_REG_010: // 010 - RCL

			break;
		case RM_REG_011: // 011 - RCR

			break;
		case RM_REG_100: // 100 - SAL/SHL

			break;
		case RM_REG_101: // 101 - SHR

			break;
		case RM_REG_111: // 111 - SAR

			break;
		default:
			info("Invalid ModR/M for GRP2 R/M8, 1");
			goto EXEC16_ILLEGAL;
		}*/
		vCPU.EIP += 2;
		return;
	}
	case 0xD1: // GRP2 R/M16, 1
		/*const ubyte rm = __fu8_i;
		const int addr = get_ea(rm);
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - ROL

			break;
		case RM_REG_001: // 001 - ROR

			break;
		case RM_REG_010: // 010 - RCL

			break;
		case RM_REG_011: // 011 - RCR

			break;
		case RM_REG_100: // 100 - SAL/SHL

			break;
		case RM_REG_101: // 101 - SHR

			break;
		case RM_REG_111: // 111 - SAR

			break;
		default:
			info("Invalid ModR/M for GRP2 R/M16, 1");
			goto EXEC16_ILLEGAL;
		}*/
		vCPU.EIP += 2;
		return;
	case 0xD2: // GRP2 R/M8, CL
		/*const ubyte rm = __fu8_i;
		const int addr = get_ea(rm);
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - ROL

			break;
		case RM_REG_001: // 001 - ROR

			break;
		case RM_REG_010: // 010 - RCL

			break;
		case RM_REG_011: // 011 - RCR

			break;
		case RM_REG_100: // 100 - SAL/SHL

			break;
		case RM_REG_101: // 101 - SHR

			break;
		case RM_REG_111: // 111 - SAR

			break;
		default:
			info("Invalid ModR/M for GRP2 R/M8, CL");
			goto EXEC16_ILLEGAL;
		}*/
		vCPU.EIP += 2;
		return;
	case 0xD3: // GRP2 R/M16, CL
		/*const ubyte rm = __fu8_i;
		const int addr = get_ea(rm, 1);
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - ROL

			break;
		case RM_REG_001: // 001 - ROR

			break;
		case RM_REG_010: // 010 - RCL

			break;
		case RM_REG_011: // 011 - RCR

			break;
		case RM_REG_100: // 100 - SAL/SHL

			break;
		case RM_REG_101: // 101 - SHR

			break;
		case RM_REG_111: // 111 - SAR

			break;
		default:
			info("Invalid ModR/M for GRP2 R/M16, CL");
			goto EXEC16_ILLEGAL;
		}*/
		vCPU.EIP += 2;
		return;
	case 0xD4: // AAM
		int r = vCPU.AL % 0xA;
		__hflag8_5(r);
		vCPU.AL = cast(ubyte)r;
		vCPU.AH = cast(ubyte)(r / 0xA);
		++vCPU.EIP;
		return;
	case 0xD5: // AAD
		int r = vCPU.AL + (vCPU.AH * 0xA);
		__hflag8_5(r);
		vCPU.AL = cast(ubyte)r;
		vCPU.AH = 0;
		++vCPU.EIP;
		return;
	case 0xD7: // XLAT SOURCE-TABLE
		vCPU.AL = __fu8(get_ad(vCPU.DS, vCPU.BX) + cast(byte)vCPU.AL);
		return;
	/*
	 * ESC OPCODE, SOURCE
	 * Used to escape to another co-processor.
	 * 1101 1XXX - MOD YYY R/M
	 */
	/*case 0xD8:
	..
	case 0xDF: break;*/
	case 0xE0: // LOOPNE/LOOPNZ SHORT-LABEL
		--vCPU.CX;
		if (vCPU.CX && vCPU.ZF == 0) vCPU.EIP += __fi8_i;
		else vCPU.EIP += 2;
		return;
	case 0xE1: // LOOPE/LOOPZ   SHORT-LABEL
		--vCPU.CX;
		if (vCPU.CX && vCPU.ZF) vCPU.EIP += __fi8_i;
		else vCPU.EIP += 2;
		return;
	case 0xE2: // LOOP  SHORT-LABEL
		--vCPU.CX;
		if (vCPU.CX) vCPU.EIP += __fi8_i;
		else vCPU.EIP += 2;
		return;
	case 0xE3: // JCXZ  SHORT-LABEL
		if (vCPU.CX == 0) vCPU.EIP += __fi8_i;
		else vCPU.EIP += 2;
		return;
	case 0xE4: // IN AL, IMM8

		return;
	case 0xE5: // IN AX, IMM8

		return;
	case 0xE6: // OUT AL, IMM8

		return;
	case 0xE7: // OUT AX, IMM8

		return;
	case 0xE8: // CALL NEAR-PROC
		push(vCPU.IP);
		vCPU.EIP += __fi16_i; // Direct within segment
		return;
	case 0xE9: // JMP NEAR-LABEL
		vCPU.EIP += __fi16_i; // ±32 KB
		return;
	case 0xEA: // JMP FAR-LABEL
		// Any segment, any fragment, 5 byte instruction.
		// EAh (LO-vCPU.IP) (HI-vCPU.IP) (LO-vCPU.CS) (HI-vCPU.CS)
		vCPU.IP = __fu16_i;
		vCPU.CS = __fu16_i(2);
		return;
	case 0xEB: // JMP SHORT-LABEL
		vCPU.EIP += __fi8_i; // ±128 B
		return;
	case 0xEC: // IN AL, DX

		return;
	case 0xED: // IN AX, DX

		return;
	case 0xEE: // OUT AL, DX

		return;
	case 0xEF: // OUT AX, DX

		return;
	case 0xF0: // LOCK (prefix)
	// http://qcd.phys.cmu.edu/QCDcluster/intel/vtune/reference/vc160.htm
		++vCPU.EIP;
		return;
	case 0xF2: // REPNE/REPNZ
/*EXEC16_REPNE:
		if (vCPU.CX) {
			//TODO: Finish REPNE/REPNZ properly?
			exec16(0xA6);
			--vCPU.CX;
			if (vCPU.ZF == 0) goto EXEC16_REPNE;
		}*/
		while (vCPU.CX) {
			//TODO: Finish REPNE/REPNZ properly?
			exec16(0xA6);
			--vCPU.CX;
			if (vCPU.ZF == 0) break;
		}
		++vCPU.EIP;
		return;
	case 0xF3: // REP/REPE/REPNZ

		return;
	case 0xF4: // HLT
		RLEVEL = 0;
		++vCPU.EIP;
		return;
	case 0xF5: // CMC
		vCPU.CF = !vCPU.CF;
		++vCPU.EIP;
		return;
	case 0xF6: { // GRP3 R/M8, IMM8
		const ubyte rm = __fu8_i; // Get ModR/M byte
		ubyte im = __fu8_i(1);
		int addr = get_ea(rm);
		int r = void;
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - TEST
			__hflag8_1(im & __fu8(addr));
			break;
		case RM_REG_010: // 010 - NOT
			__iu8(~__fu8(addr), addr);
			break;
		case RM_REG_011: // 011 - NEG
			r = cast(ubyte)-__fu8(addr);
			vCPU.CF = cast(ubyte)r;
			__hflag8_2(r);
			__iu8(r, addr);
			break;
		case RM_REG_100: // 100 - MUL
			r = im * __fu8(addr);
			__hflag8_4(r);
			__iu8(r, addr);
			break;
		case RM_REG_101: // 101 - IMUL
			r = cast(ubyte)(cast(byte)im * __fi8(addr));
			__hflag8_4(r);
			__iu8(r, addr);
			break;
		case RM_REG_110: // 110 - DIV
		//TODO: Check if im == 0 (#DE), DIV
			ubyte d = __fu8(addr);
			r = vCPU.AX / d;
			vCPU.AH = cast(ubyte)(vCPU.AX % d);
			vCPU.AL = cast(ubyte)(r);
			break;
		case RM_REG_111: // 111 - IDIV
		//TODO: Check if im == 0 (#DE), IDIV
			byte d = __fi8(addr);
			r = cast(short)vCPU.AX / d;
			vCPU.AH = cast(ubyte)(cast(short)vCPU.AX % d);
			vCPU.AL = cast(ubyte)r;
			break;
		default:
			info("Invalid ModR/M on GRP3_8");
			goto EXEC16_ILLEGAL;
		}
		vCPU.EIP += 3;
		return;
	}
	case 0xF7: { // GRP3 R/M16, IMM16
		const ubyte rm = __fu8_i; // Get ModR/M byte
		ushort im = __fu16_i(1);
		int addr = get_ea(rm, 1);
		int r = void;
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - TEST
			__hflag16_1(im & __fu16(addr));
			break;
		case RM_REG_010: // 010 - NOT
			__iu16(~im, addr);
			break;
		case RM_REG_011: // 011 - NEG
			r = -__fu16(addr);
			vCPU.CF = cast(ubyte)r;
			__iu16(r, addr);
			break;
		case RM_REG_100: // 100 - MUL
			r = im * __fu16(addr);
			__hflag16_4(r);
			__iu16(r, addr);
			break;
		case RM_REG_101: // 101 - IMUL
			r = im * __fi16(addr);
			__hflag16_4(r);
			__iu16(r, addr);
			break;
		case RM_REG_110: // 110 - DIV
			r = im / __fu16(addr);
			__hflag16_4(r);
			__iu16(r, addr);
			break;
		case RM_REG_111: // 111 - IDIV
			r = im / __fi16(addr);
			__hflag16_4(r);
			__iu16(r, addr);
			break;
		default:
			info("Invalid ModR/M on GRP3_8");
			goto EXEC16_ILLEGAL;
		}
		vCPU.EIP += 4;
		return;
	}
	case 0xF8: // CLC
		vCPU.CF = 0;
		++vCPU.EIP;
		return;
	case 0xF9: // STC
		vCPU.CF = 1;
		++vCPU.EIP;
		return;
	case 0xFA: // CLI
		vCPU.IF = 0;
		++vCPU.EIP;
		return;
	case 0xFB: // STI
		vCPU.IF = 1;
		++vCPU.EIP;
		return;
	case 0xFC: // CLD
		vCPU.DF = 0;
		++vCPU.EIP;
		return;
	case 0xFD: // STD
		vCPU.DF = 1;
		++vCPU.EIP;
		return;
	case 0xFE: { // GRP4 R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - INC
			++r;
			break;
		case RM_REG_001: // 001 - DEC
			--r;
			break;
		default:
			info("Invalid ModR/M on GRP4_8");
			goto EXEC16_ILLEGAL;
		}
		__iu16(r, addr);
		__hflag16_2(r);
		vCPU.EIP += 2;
		return;
	}
	case 0xFF: { // GRP5 R/M16
		const ubyte rm = __fu8_i;
		uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - INC
			++r;
			__iu16(r, addr);
			__hflag16_2(r);
			vCPU.EIP += 2;
			return;
		case RM_REG_001: // 001 - DEC
			--r;
			__iu16(r, addr);
			__hflag16_2(r);
			vCPU.EIP += 2;
			break;
		case RM_REG_010: // 010 - CALL R/M16 (near) -- Indirect within segment
			push(vCPU.IP);
			vCPU.EIP = r;
			break;
		case RM_REG_011: // 011 - CALL MEM16 (far) -- Indirect outside segment
			push(vCPU.CS);
			push(vCPU.IP);
			vCPU.EIP = get_ad(__fu16(addr + 2), r);
			break;
		case RM_REG_100: // 100 - JMP R/M16 (near) -- Indirect within segment
			vCPU.EIP = r;
			break;
		case RM_REG_101: // 101 - JMP MEM16 (far) -- Indirect outside segment
			vCPU.EIP = get_ad(__fu16(addr + 2), r);
			break;
		case RM_REG_110: // 110 - PUSH MEM16
			push(__fu16(get_ad(__fu16(addr + 2), r)));
			vCPU.EIP += 2;
			break;
		default:
			info("Invalid ModR/M on GRP5_16");
			goto EXEC16_ILLEGAL;
		}
		return;
	}
	default: // Illegal instruction
EXEC16_ILLEGAL:
		info("INVALID OPERATION CODE");
		//TODO: Raise vector on illegal op
		return;
	}
}