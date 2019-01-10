module vcpu.v16; // 8086

import vcpu.core, vcpu.v32, vcpu.mm, vcpu.utils;
import vdos.interrupts;
import logger;

//TODO: Call table (#2)

/**
 * Execute an instruction in REAL mode
 * Params: op = opcode
 */
extern (C)
void exec16(ubyte op) {
	// Every instruction has their own local variables, since referencing
	// one variable at the top of this function for every instructions will
	// increase binary size due to the amount of translation the compiler
	// will have to perform. This has been tested on the godbolt.org
	// platform with DMD, GDC, and LDC. Remember, this is D, not C.
	switch (op) {
	case 0x00: { // ADD R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r += CPU.AL; break;
		case RM_REG_001: r += CPU.CL; break;
		case RM_REG_010: r += CPU.DL; break;
		case RM_REG_011: r += CPU.BL; break;
		case RM_REG_100: r += CPU.AH; break;
		case RM_REG_101: r += CPU.CH; break;
		case RM_REG_110: r += CPU.DH; break;
		case RM_REG_111: r += CPU.BH; break;
		default:
		}
		__hflag8_1(r);
		__iu8(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x01: { // ADD R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r += CPU.AX; break;
		case RM_REG_001: r += CPU.CX; break;
		case RM_REG_010: r += CPU.DX; break;
		case RM_REG_011: r += CPU.BX; break;
		case RM_REG_100: r += CPU.SP; break;
		case RM_REG_101: r += CPU.BP; break;
		case RM_REG_110: r += CPU.SI; break;
		case RM_REG_111: r += CPU.DI; break;
		default:
		}
		__hflag16_1(r);
		__iu16(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x02: { // ADD REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = CPU.AL + r;
			CPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r = CPU.CL + r;
			CPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r = CPU.DL + r;
			CPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r = CPU.BL + r;
			CPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r = CPU.AH + r;
			CPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r = CPU.CH + r;
			CPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r = CPU.DH + r;
			CPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r = CPU.BH + r;
			CPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_1(r);
		CPU.EIP += 2;
		return;
	}
	case 0x03: { // ADD REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = CPU.AX + r;
			CPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r = CPU.CX + r;
			CPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r = CPU.DX + r;
			CPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r = CPU.BX + r;
			CPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r = CPU.SP + r;
			CPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r = CPU.BP + r;
			CPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r = CPU.SI + r;
			CPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r = CPU.DI + r;
			CPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_1(r);
		CPU.EIP += 2;
		return;
	}
	case 0x04: { // ADD AL, IMM8
		const int r = CPU.AL + __fu8_i;
		__hflag8_1(r);
		CPU.AL = cast(ubyte)r;
		CPU.EIP += 2;
		return;
	}
	case 0x05: { // ADD CPU.AX, IMM16
		const int r = CPU.AX + __fu16_i;
		__hflag16_1(r);
		CPU.AX = cast(ushort)r;
		CPU.EIP += 2;
		return;
	}
	case 0x06: // PUSH ES
		push16(CPU.ES);
		++CPU.EIP;
		return;
	case 0x07: // POP ES
		CPU.ES = pop16;
		++CPU.EIP;
		return;
	case 0x08: { // OR R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r |= CPU.AL; break;
		case RM_REG_001: r |= CPU.CL; break;
		case RM_REG_010: r |= CPU.DL; break;
		case RM_REG_011: r |= CPU.BL; break;
		case RM_REG_100: r |= CPU.AH; break;
		case RM_REG_101: r |= CPU.CH; break;
		case RM_REG_110: r |= CPU.DH; break;
		case RM_REG_111: r |= CPU.BH; break;
		default:
		}
		__hflag8_3(r);
		__iu8(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x09: { // OR R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r |= CPU.AX; break;
		case RM_REG_001: r |= CPU.CX; break;
		case RM_REG_010: r |= CPU.DX; break;
		case RM_REG_011: r |= CPU.BX; break;
		case RM_REG_100: r |= CPU.SP; break;
		case RM_REG_101: r |= CPU.BP; break;
		case RM_REG_110: r |= CPU.SI; break;
		case RM_REG_111: r |= CPU.DI; break;
		default:
		}
		__hflag16_3(r);
		__iu16(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x0A: { // OR REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r |= CPU.AL;
			CPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r |= CPU.CL;
			CPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r |= CPU.DL;
			CPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r |= CPU.BL;
			CPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r |= CPU.AH;
			CPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r |= CPU.CH;
			CPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r |= CPU.DH;
			CPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r |= CPU.BH;
			CPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x0B: { // OR REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r |= CPU.AX;
			CPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r |= CPU.CX;
			CPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r |= CPU.DX;
			CPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r |= CPU.BX;
			CPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r |= CPU.SP;
			CPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r |= CPU.BP;
			CPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r |= CPU.SI;
			CPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r |= CPU.DI;
			CPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x0C: { // OR AL, IMM8
		const int r = CPU.AL | __fu8_i;
		__hflag8_3(r);
		CPU.AL = cast(ubyte)r;
		CPU.EIP += 2;
		return;
	}
	case 0x0D: { // OR AX, IMM16
		const int r = CPU.AX | __fu16_i;
		__hflag16_3(r);
		CPU.AX = cast(ushort)r;
		CPU.EIP += 3;
		return;
	}
	case 0x0E: // PUSH CS
		push16(CPU.CS);
		++CPU.EIP;
		return;
	case 0x10: { // ADC R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r += CPU.AL; break;
		case RM_REG_001: r += CPU.CL; break;
		case RM_REG_010: r += CPU.DL; break;
		case RM_REG_011: r += CPU.BL; break;
		case RM_REG_100: r += CPU.AH; break;
		case RM_REG_101: r += CPU.CH; break;
		case RM_REG_110: r += CPU.DH; break;
		case RM_REG_111: r += CPU.BH; break;
		default:
		}
		if (CPU.CF) ++r;
		__hflag8_3(r);
		__iu8(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x11: { // ADC R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r += CPU.AX; break;
		case RM_REG_001: r += CPU.CX; break;
		case RM_REG_010: r += CPU.DX; break;
		case RM_REG_011: r += CPU.BX; break;
		case RM_REG_100: r += CPU.SP; break;
		case RM_REG_101: r += CPU.BP; break;
		case RM_REG_110: r += CPU.SI; break;
		case RM_REG_111: r += CPU.DI; break;
		default:
		}
		if (CPU.CF) ++r;
		__hflag16_3(r);
		__iu16(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x12: { // ADC REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r += CPU.AL;
			if (CPU.CF) ++r;
			CPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r += CPU.CL;
			if (CPU.CF) ++r;
			CPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r += CPU.DL;
			if (CPU.CF) ++r;
			CPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r += CPU.BL;
			if (CPU.CF) ++r;
			CPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r += CPU.AH;
			if (CPU.CF) ++r;
			CPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r += CPU.CH;
			if (CPU.CF) ++r;
			CPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r += CPU.DH;
			if (CPU.CF) ++r;
			CPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r += CPU.BH;
			if (CPU.CF) ++r;
			CPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x13: { // ADC REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r += CPU.AX;
			if (CPU.CF) ++r;
			CPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r += CPU.CX;
			if (CPU.CF) ++r;
			CPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r += CPU.DX;
			if (CPU.CF) ++r;
			CPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r += CPU.BX;
			if (CPU.CF) ++r;
			CPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r += CPU.SP;
			if (CPU.CF) ++r;
			CPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r += CPU.BP;
			if (CPU.CF) ++r;
			CPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r += CPU.SI;
			if (CPU.CF) ++r;
			CPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r += CPU.DI;
			if (CPU.CF) ++r;
			CPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x14: { // ADC AL, IMM8
		int r = CPU.AL + __fu8_i;
		__hflag8_1(r);
		if (CPU.CF) ++r;
		CPU.AL = cast(ubyte)r;
		CPU.EIP += 2;
		return;
	}
	case 0x15: { // ADC AX, IMM16
		int r = CPU.AX + __fu16_i;
		__hflag16_1(r);
		if (CPU.CF) ++r;
		CPU.AX = cast(ushort)r;
		CPU.EIP += 3;
		return;
	}
	case 0x16: // PUSH SS
		push16(CPU.SS);
		++CPU.EIP;
		return;
	case 0x17: // POP SS
		CPU.SS = pop16;
		++CPU.EIP;
		return;
	case 0x18: { // SBB R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= CPU.AL; break;
		case RM_REG_001: r -= CPU.CL; break;
		case RM_REG_010: r -= CPU.DL; break;
		case RM_REG_011: r -= CPU.BL; break;
		case RM_REG_100: r -= CPU.AH; break;
		case RM_REG_101: r -= CPU.CH; break;
		case RM_REG_110: r -= CPU.DH; break;
		case RM_REG_111: r -= CPU.BH; break;
		default:
		}
		if (CPU.CF) --r;
		__hflag8_3(r);
		__iu8(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x19: { // SBB R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= CPU.AX; break;
		case RM_REG_001: r -= CPU.CX; break;
		case RM_REG_010: r -= CPU.DX; break;
		case RM_REG_011: r -= CPU.BX; break;
		case RM_REG_100: r -= CPU.SP; break;
		case RM_REG_101: r -= CPU.BP; break;
		case RM_REG_110: r -= CPU.SI; break;
		case RM_REG_111: r -= CPU.DI; break;
		default:
		}
		if (CPU.CF) --r;
		__hflag16_3(r);
		__iu16(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x1A: { // SBB REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r -= CPU.AL;
			if (CPU.CF) --r;
			CPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r -= CPU.CL;
			if (CPU.CF) --r;
			CPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r -= CPU.DL;
			if (CPU.CF) --r;
			CPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r -= CPU.BL;
			if (CPU.CF) --r;
			CPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r -= CPU.AH;
			if (CPU.CF) --r;
			CPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r -= CPU.CH;
			if (CPU.CF) --r;
			CPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r -= CPU.DH;
			if (CPU.CF) --r;
			CPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r -= CPU.BH;
			if (CPU.CF) --r;
			CPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x1B: { // SBB REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r -= CPU.AX;
			if (CPU.CF) --r;
			CPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r -= CPU.CX;
			if (CPU.CF) --r;
			CPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r -= CPU.DX;
			if (CPU.CF) --r;
			CPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r -= CPU.BX;
			if (CPU.CF) --r;
			CPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r -= CPU.SP;
			if (CPU.CF) --r;
			CPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r -= CPU.BP;
			if (CPU.CF) --r;
			CPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r -= CPU.SI;
			if (CPU.CF) --r;
			CPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r -= CPU.DI;
			if (CPU.CF) --r;
			CPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x1C: { // SBB AL, IMM8
		int r = CPU.AL - __fu8_i;
		if (CPU.CF) --r;
		__hflag8_3(r);
		CPU.AL = cast(ubyte)r;
		CPU.EIP += 2;
		return;
	}
	case 0x1D: { // SBB AX, IMM16
		int r = CPU.AX - __fu16_i;
		if (CPU.CF) --r;
		__hflag16_3(r);
		CPU.AX = cast(ushort)r;
		CPU.EIP += 3;
		return;
	}
	case 0x1E: // PUSH DS
		push16(CPU.DS);
		++CPU.EIP;
		return;
	case 0x1F: // POP DS
		CPU.DS = pop16;
		++CPU.EIP;
		return;
	case 0x20: { // AND R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r &= CPU.AH; break;
		case RM_REG_001: r &= CPU.CH; break;
		case RM_REG_010: r &= CPU.DH; break;
		case RM_REG_011: r &= CPU.BH; break;
		case RM_REG_100: r &= CPU.AL; break;
		case RM_REG_101: r &= CPU.CL; break;
		case RM_REG_110: r &= CPU.DL; break;
		case RM_REG_111: r &= CPU.BL; break;
		default:
		}
		__hflag8_3(r);
		__iu8(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x21: { // AND R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r &= CPU.AX; break;
		case RM_REG_001: r &= CPU.CX; break;
		case RM_REG_010: r &= CPU.DX; break;
		case RM_REG_011: r &= CPU.BX; break;
		case RM_REG_100: r &= CPU.SP; break;
		case RM_REG_101: r &= CPU.BP; break;
		case RM_REG_110: r &= CPU.SI; break;
		case RM_REG_111: r &= CPU.DI; break;
		default:
		}
		__hflag16_3(r);
		__iu16(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x22: { // AND REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = CPU.AL & r;
			CPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r = CPU.CL & r;
			CPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r = CPU.DL & r;
			CPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r = CPU.BL & r;
			CPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r = CPU.AH & r;
			CPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r = CPU.CH & r;
			CPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r = CPU.DH & r;
			CPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r = CPU.BH & r;
			CPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x23: { // AND REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = CPU.AX & r;
			CPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r = CPU.CX & r;
			CPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r = CPU.DX & r;
			CPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r = CPU.BX & r;
			CPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r = CPU.SP & r;
			CPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r = CPU.BP & r;
			CPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r = CPU.SI & r;
			CPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r = CPU.DI & r;
			CPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x24: { // AND AL, IMM8
		const int r = CPU.AL & __fu8_i;
		__hflag8_3(r);
		CPU.AL = cast(ubyte)r;
		CPU.EIP += 2;
		return;
	}
	case 0x25: { // AND AX, IMM16
		const int r = CPU.AX & __fu16_i;
		__hflag16_3(r);
		CPU.AX = cast(ushort)r;
		CPU.EIP += 3;
		return;
	}
	case 0x26: // ES: (Segment override prefix)
		CPU.Segment = SEG_ES;
		++CPU.EIP;
		return;
	case 0x27: { // DAA
		// This instruction is difficult to emulate properly. Both
		// Bosch and DOSBox fail the examples cited in the Intel
		// reference manual. Even following Intel's manual, their
		// examples fails, so this code is adapted from DOSBox.
		int r = CPU.AL;

		if (((CPU.AL & 0xF) > 9) || CPU.AF) {
			if ((CPU.AL > 0x99) || CPU.CF) {
				r += 0x60;
				CPU.CF = 1;
			} else {
				CPU.CF = 0;
			}
			r += 6;
			CPU.AF = 1;
		} else {
			if ((CPU.AL > 0x99) || CPU.CF) {
				r += 0x60;
				CPU.CF = 1;
			} else {
				CPU.CF = 0;
			}
			CPU.AF = 0;
		}


		CPU.ZF = r == 0;
		CPU.SF = r & 0x80;
		setPF_8(r);
		CPU.AL = cast(ubyte)r;

		++CPU.EIP;
		return;
	}
	case 0x28: { // SUB R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= CPU.AL; break;
		case RM_REG_001: r -= CPU.CL; break;
		case RM_REG_010: r -= CPU.DL; break;
		case RM_REG_011: r -= CPU.BL; break;
		case RM_REG_100: r -= CPU.AH; break;
		case RM_REG_101: r -= CPU.CH; break;
		case RM_REG_110: r -= CPU.DH; break;
		case RM_REG_111: r -= CPU.BH; break;
		default:
		}
		__hflag8_1(r);
		__iu8(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x29: { // SUB R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= CPU.AX; break;
		case RM_REG_001: r -= CPU.CX; break;
		case RM_REG_010: r -= CPU.DX; break;
		case RM_REG_011: r -= CPU.BX; break;
		case RM_REG_100: r -= CPU.SP; break;
		case RM_REG_101: r -= CPU.BP; break;
		case RM_REG_110: r -= CPU.SI; break;
		case RM_REG_111: r -= CPU.DI; break;
		default:
		}
		__hflag16_1(r);
		__iu16(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x2A: { // SUB REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = CPU.AL - r;
			CPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r = CPU.CL - r;
			CPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r = CPU.DL - r;
			CPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r = CPU.BL - r;
			CPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r = CPU.AH - r;
			CPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r = CPU.CH - r;
			CPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r = CPU.DH - r;
			CPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r = CPU.BH - r;
			CPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_1(r);
		CPU.EIP += 2;
		return;
	}
	case 0x2B: { // SUB REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = CPU.AX - r;
			CPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r = CPU.CX - r;
			CPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r = CPU.DX - r;
			CPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r = CPU.BX - r;
			CPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r = CPU.SP - r;
			CPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r = CPU.BP - r;
			CPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r = CPU.SI - r;
			CPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r = CPU.DI - r;
			CPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_1(r);
		CPU.EIP += 2;
		return;
	}
	case 0x2C: { // SUB AL, IMM8
		const int r = CPU.AL - __fu8_i;
		__hflag8_1(r);
		CPU.AL = cast(ubyte)r;
		CPU.EIP += 2;
		return;
	}
	case 0x2D: { // SUB AX, IMM16
		const int r = CPU.AX - __fu16_i;
		__hflag16_1(r);
		CPU.AX = cast(ushort)r;
		CPU.EIP += 3;
		return;
	}
	case 0x2E: // CS:
		CPU.Segment = SEG_CS;
		++CPU.EIP;
		return;
	case 0x2F: { // DAS
		const ubyte oldAL = CPU.AL;
		const ubyte oldCF = CPU.CF;
		CPU.CF = 0;

		if (((oldAL & 0xF) > 9) || CPU.AF) {
			CPU.AL = cast(ubyte)(CPU.AL - 6);
			CPU.CF = oldCF || (CPU.AL & 0x80);
			CPU.AF = 1;
		} else CPU.AF = 0;

		if ((oldAL > 0x99) || oldCF) {
			CPU.AL = cast(ubyte)(CPU.AL - 0x60);
			CPU.CF = 1;
		} else CPU.CF = 0;

		++CPU.EIP;
		return;
	}
	case 0x30: { // XOR R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r ^= CPU.AL; break;
		case RM_REG_001: r ^= CPU.CL; break;
		case RM_REG_010: r ^= CPU.DL; break;
		case RM_REG_011: r ^= CPU.BL; break;
		case RM_REG_100: r ^= CPU.AH; break;
		case RM_REG_101: r ^= CPU.CH; break;
		case RM_REG_110: r ^= CPU.DH; break;
		case RM_REG_111: r ^= CPU.BH; break;
		default:
		}
		__hflag8_3(r);
		__iu8(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x31: { // XOR R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r ^= CPU.AX; break;
		case RM_REG_001: r ^= CPU.CX; break;
		case RM_REG_010: r ^= CPU.DX; break;
		case RM_REG_011: r ^= CPU.BX; break;
		case RM_REG_100: r ^= CPU.SP; break;
		case RM_REG_101: r ^= CPU.BP; break;
		case RM_REG_110: r ^= CPU.SI; break;
		case RM_REG_111: r ^= CPU.DI; break;
		default:
		}
		__hflag16_3(r);
		__iu16(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x32: { // XOR REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = CPU.AL ^ r;
			CPU.AL = cast(ubyte)r;
			break;
		case RM_REG_001:
			r = CPU.CL ^ r;
			CPU.CL = cast(ubyte)r;
			break;
		case RM_REG_010:
			r = CPU.DL ^ r;
			CPU.DL = cast(ubyte)r;
			break;
		case RM_REG_011:
			r = CPU.BL ^ r;
			CPU.BL = cast(ubyte)r;
			break;
		case RM_REG_100:
			r = CPU.AH ^ r;
			CPU.AH = cast(ubyte)r;
			break;
		case RM_REG_101:
			r = CPU.CH ^ r;
			CPU.CH = cast(ubyte)r;
			break;
		case RM_REG_110:
			r = CPU.DH ^ r;
			CPU.DH = cast(ubyte)r;
			break;
		case RM_REG_111:
			r = CPU.BH ^ r;
			CPU.BH = cast(ubyte)r;
			break;
		default:
		}
		__hflag8_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x33: { // XOR REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = CPU.AX ^ r;
			CPU.AX = cast(ushort)r;
			break;
		case RM_REG_001:
			r = CPU.CX ^ r;
			CPU.CX = cast(ushort)r;
			break;
		case RM_REG_010:
			r = CPU.DX ^ r;
			CPU.DX = cast(ushort)r;
			break;
		case RM_REG_011:
			r = CPU.BX ^ r;
			CPU.BX = cast(ushort)r;
			break;
		case RM_REG_100:
			r = CPU.SP ^ r;
			CPU.SP = cast(ushort)r;
			break;
		case RM_REG_101:
			r = CPU.BP ^ r;
			CPU.BP = cast(ushort)r;
			break;
		case RM_REG_110:
			r = CPU.SI ^ r;
			CPU.SI = cast(ushort)r;
			break;
		case RM_REG_111:
			r = CPU.DI ^ r;
			CPU.DI = cast(ushort)r;
			break;
		default:
		}
		__hflag16_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x34: { // XOR AL, IMM8
		const int r = CPU.AL ^ __fu8_i;
		__hflag8_3(r);
		CPU.AL = cast(ubyte)r;
		CPU.EIP += 2;
		return;
	}
	case 0x35: { // XOR AX, IMM16
		const int r = CPU.AX ^ __fu16_i;
		__hflag16_3(r);
		CPU.AX = cast(ushort)r;
		CPU.EIP += 3;
		return;
	}
	case 0x36: // SS:
		CPU.Segment = SEG_SS;
		++CPU.EIP;
		return;
	case 0x37: // AAA
		if (((CPU.AL & 0xF) > 9) || CPU.AF) {
			CPU.AX = cast(ushort)(CPU.AX + 0x106);
			CPU.AF = CPU.CF = 1;
		} else CPU.AF = CPU.CF = 0;
		CPU.AL = cast(ubyte)(CPU.AL & 0xF);
		++CPU.EIP;
		return;
	case 0x38: { // CMP R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= CPU.AL; break;
		case RM_REG_001: r -= CPU.CL; break;
		case RM_REG_010: r -= CPU.DL; break;
		case RM_REG_011: r -= CPU.BL; break;
		case RM_REG_100: r -= CPU.AH; break;
		case RM_REG_101: r -= CPU.CH; break;
		case RM_REG_110: r -= CPU.DH; break;
		case RM_REG_111: r -= CPU.BH; break;
		default:
		}
		__hflag8_1(r);
		CPU.EIP += 2;
		return;
	}
	case 0x39: { // CMP R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= CPU.AX; break;
		case RM_REG_001: r -= CPU.CX; break;
		case RM_REG_010: r -= CPU.DX; break;
		case RM_REG_011: r -= CPU.BX; break;
		case RM_REG_100: r -= CPU.SP; break;
		case RM_REG_101: r -= CPU.BP; break;
		case RM_REG_110: r -= CPU.SI; break;
		case RM_REG_111: r -= CPU.DI; break;
		default:
		}
		__hflag16_1(r);
		CPU.EIP += 2;
		return;
	}
	case 0x3A: { // CMP REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r = CPU.AL - r; break;
		case RM_REG_001: r = CPU.CL - r; break;
		case RM_REG_010: r = CPU.DL - r; break;
		case RM_REG_011: r = CPU.BL - r; break;
		case RM_REG_100: r = CPU.AH - r; break;
		case RM_REG_101: r = CPU.CH - r; break;
		case RM_REG_110: r = CPU.DH - r; break;
		case RM_REG_111: r = CPU.BH - r; break;
		default:
		}
		__hflag8_1(r);
		CPU.EIP += 2;
		return;
	}
	case 0x3B: { // CMP REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r = CPU.AX - r; break;
		case RM_REG_001: r = CPU.CX - r; break;
		case RM_REG_010: r = CPU.DX - r; break;
		case RM_REG_011: r = CPU.BX - r; break;
		case RM_REG_100: r = CPU.SP - r; break;
		case RM_REG_101: r = CPU.BP - r; break;
		case RM_REG_110: r = CPU.SI - r; break;
		case RM_REG_111: r = CPU.DI - r; break;
		default:
		}
		__hflag16_1(r);
		CPU.EIP += 2;
		return;
	}
	case 0x3C: { // CMP AL, IMM8
		__hflag8_1(CPU.AL - __fu8_i);
		CPU.EIP += 2;
		return;
	}
	case 0x3D: { // CMP AX, IMM16
		__hflag16_1(CPU.AX - __fu16_i);
		CPU.EIP += 3;
		return;
	}
	case 0x3E: // DS:
		CPU.Segment = SEG_DS;
		++CPU.EIP;
		return;
	case 0x3F: // AAS
		if (((CPU.AL & 0xF) > 9) || CPU.AF) {
			CPU.AX = cast(ushort)(CPU.AX - 6);
			CPU.AH = cast(ubyte)(CPU.AH - 1);
			CPU.AF = CPU.CF = 1;
		} else {
			CPU.AF = CPU.CF = 0;
		}
		CPU.AL = cast(ubyte)(CPU.AL & 0xF);
		++CPU.EIP;
		return;
	case 0x40: { // INC AX
		const int r = CPU.AX + 1;
		__hflag16_2(r);
		CPU.AX = cast(ubyte)r;
		++CPU.EIP;
		return;
	}
	case 0x41: { // INC CX
		const int r = CPU.CX + 1;
		__hflag16_2(r);
		CPU.CX = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x42: { // INC DX
		const int r = CPU.DX + 1;
		__hflag16_2(r);
		CPU.DX = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x43: { // INC BX
		const int r = CPU.BX + 1;
		__hflag16_2(r);
		CPU.BX = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x44: { // INC SP
		const int r = CPU.SP + 1;
		__hflag16_2(r);
		CPU.SP = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x45: { // INC BP
		const int r = CPU.BP + 1;
		__hflag16_2(r);
		CPU.BP = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x46: { // INC SI
		const int r = CPU.SI + 1;
		__hflag16_2(r);
		CPU.SI = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x47: { // INC DI
		const int r = CPU.DI + 1;
		__hflag16_2(r);
		CPU.DI = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x48: { // DEC AX
		const int r = CPU.AX - 1;
		__hflag16_2(r);
		CPU.AX = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x49: { // DEC CX
		const int r = CPU.CX - 1;
		__hflag16_2(r);
		CPU.CX = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x4A: { // DEC DX
		const int r = CPU.DX - 1;
		__hflag16_2(r);
		CPU.DX = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x4B: { // DEC BX
		const int r = CPU.BX - 1;
		__hflag16_2(r);
		CPU.BX = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x4C: { // DEC SP
		const int r = CPU.SP - 1;
		__hflag16_2(r);
		CPU.SP = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x4D: { // DEC BP
		const int r = CPU.BP - 1;
		__hflag16_2(r);
		CPU.BP = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x4E: { // DEC SI
		const int r = CPU.SI - 1;
		__hflag16_2(r);
		CPU.SI = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x4F: { // DEC DI
		const int r = CPU.DI - 1;
		__hflag16_2(r);
		CPU.DI = cast(ushort)r;
		++CPU.EIP;
		return;
	}
	case 0x50: // PUSH AX
		push16(CPU.AX);
		++CPU.EIP;
		return;
	case 0x51: // PUSH CX
		push16(CPU.CX);
		++CPU.EIP;
		return;
	case 0x52: // PUSH DX
		push16(CPU.DX);
		++CPU.EIP;
		return;
	case 0x53: // PUSH BX
		push16(CPU.BX);
		++CPU.EIP;
		return;
	case 0x54: // PUSH SP
		push16(CPU.SP);
		++CPU.EIP;
		return;
	case 0x55: // PUSH BP
		push16(CPU.BP);
		++CPU.EIP;
		return;
	case 0x56: // PUSH SI
		push16(CPU.SI);
		++CPU.EIP;
		return;
	case 0x57: // PUSH DI
		push16(CPU.DI);
		++CPU.EIP;
		return;
	case 0x58: // POP AX
		CPU.AX = pop16;
		++CPU.EIP;
		return;
	case 0x59: // POP CX
		CPU.CX = pop16;
		++CPU.EIP;
		return;
	case 0x5A: // POP DX
		CPU.DX = pop16;
		++CPU.EIP;
		return;
	case 0x5B: // POP BX
		CPU.BX = pop16;
		++CPU.EIP;
		return;
	case 0x5C: // POP SP
		CPU.SP = pop16;
		++CPU.EIP;
		return;
	case 0x5D: // POP BP
		CPU.BP = pop16;
		++CPU.EIP;
		return;
	case 0x5E: // POP SI
		CPU.SI = pop16;
		++CPU.EIP;
		return;
	case 0x5F: // POP DI
		CPU.DI = pop16;
		++CPU.EIP;
		return;
	case 0x66: // 80286 OPCODE PREFIX
		++CPU.EIP;
		exec32(MEMORY[CPU.EIP]);
		return;
	case 0x70: // JO          SHORT-LABEL
		CPU.EIP += CPU.OF ? __fi8_i + 2 : 2;
		return;
	case 0x71: // JNO         SHORT-LABEL
		CPU.EIP += CPU.OF ? 2 : __fi8_i + 2;
		return;
	case 0x72: // JB/JNAE/JC  SHORT-LABEL
		CPU.EIP += CPU.CF ? __fi8_i + 2 : 2;
		return;
	case 0x73: // JNB/JAE/JNC SHORT-LABEL
		CPU.EIP += CPU.CF ? 2 : __fi8_i + 2;
		return;
	case 0x74: // JE/JZ       SHORT-LABEL
		CPU.EIP += CPU.ZF ? __fi8_i + 2 : 2;
		return;
	case 0x75: // JNE/JNZ     SHORT-LABEL
		CPU.EIP += CPU.ZF ? 2 : __fi8_i + 2;
		return;
	case 0x76: // JBE/JNA     SHORT-LABEL
		CPU.EIP += (CPU.CF || CPU.ZF) ? __fi8_i + 2 : 2;
		return;
	case 0x77: // JNBE/JA     SHORT-LABEL
		CPU.EIP += CPU.CF == 0 && CPU.ZF == 0 ? __fi8_i + 2 : 2;
		return;
	case 0x78: // JS          SHORT-LABEL
		CPU.EIP += CPU.SF ? __fi8_i + 2 : 2;
		return;
	case 0x79: // JNS         SHORT-LABEL
		CPU.EIP += CPU.SF ? 2 : __fi8_i + 2;
		return;
	case 0x7A: // JP/JPE      SHORT-LABEL
		CPU.EIP += CPU.PF ? __fi8_i + 2 : 2;
		return;
	case 0x7B: // JNP/JPO     SHORT-LABEL
		CPU.EIP += CPU.PF ? 2 : __fi8_i + 2;
		return;
	case 0x7C: // JL/JNGE     SHORT-LABEL
		CPU.EIP += CPU.SF != CPU.OF ? __fi8_i + 2 : 2;
		return;
	case 0x7D: // JNL/JGE     SHORT-LABEL
		CPU.EIP += CPU.SF == CPU.OF ? __fi8_i + 2 : 2;
		return;
	case 0x7E: // JLE/JNG     SHORT-LABEL
		CPU.EIP += CPU.SF != CPU.OF || CPU.ZF ? __fi8_i + 2 : 2;
		return;
	case 0x7F: // JNLE/JG     SHORT-LABEL
		CPU.EIP += CPU.SF == CPU.OF && CPU.ZF == 0 ? __fi8_i + 2 : 2;
		return;
	case 0x80: { // GRP1 R/M8, IMM8
		const ubyte rm = __fu8_i; // Get ModR/M byte
		const ushort im = __fu8_i(1);
		const int addr = get_rm16(rm);
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
			if (CPU.CF) ++r;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (CPU.CF) --r;
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
			log_info("Invalid ModR/M from GRP1_8");
			goto EXEC16_ILLEGAL;
		}
		CPU.EIP += 3;
		return;
	}
	case 0x81: { // GRP1 R/M16, IMM16
		const ubyte rm = __fu8_i; // Get ModR/M byte
		const ushort im = __fu16_i(1);
		const int addr = get_rm16(rm, 1);
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
			if (CPU.CF) ++r;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (CPU.CF) --r;
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
			log_info("Invalid ModR/M from GRP1_16");
			goto EXEC16_ILLEGAL;
		}
		CPU.EIP += 4;
		return;
	}
	case 0x82: { // GRP2 R/M8, IMM8
		const ubyte rm = __fu8_i; // Get ModR/M byte
		const ushort im = __fu8_i(1);
		const int addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) { // ModRM REG
		case RM_REG_000: // 000 - ADD
			r += im;
			__iu8(r, addr);
			break;
		case RM_REG_010: // 010 - ADC
			r += im;
			if (CPU.CF) ++r;
			__iu8(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (CPU.CF) --r;
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
			log_info("Invalid ModR/M for GRP2_8");
			goto EXEC16_ILLEGAL;
		}
		__hflag8_1(r);
		CPU.EIP += 3;
		return;
	}
	case 0x83: { // GRP2 R/M16, IMM8
		const ubyte rm = __fu8_i; // Get ModR/M byte
		const ushort im = __fu8_i(1);
		const int addr = get_rm16(rm, 1);
		int r = __fu8(addr);
		switch (rm & RM_REG) { // ModRM REG
		case RM_REG_000: // 000 - ADD
			r += im;
			__iu16(r, addr);
			break;
		case RM_REG_010: // 010 - ADC
			r += im;
			if (CPU.CF) ++r;
			__iu16(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (CPU.CF) --r;
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
			log_info("Invalid ModR/M for GRP2_16");
			goto EXEC16_ILLEGAL;
		}
		__hflag16_1(r);
		CPU.EIP += 3;
		return;
	}
	case 0x84: { // TEST R/M8, REG8
		const ubyte rm = __fu8_i;
		const int n = __fu8(get_rm16(rm));
		int r = void;
		switch (rm & RM_REG) {
		case RM_REG_000: r = CPU.AL & n; break;
		case RM_REG_001: r = CPU.CL & n; break;
		case RM_REG_010: r = CPU.DL & n; break;
		case RM_REG_011: r = CPU.BL & n; break;
		case RM_REG_100: r = CPU.AH & n; break;
		case RM_REG_101: r = CPU.CH & n; break;
		case RM_REG_110: r = CPU.DH & n; break;
		case RM_REG_111: r = CPU.BH & n; break;
		default:
		}
		__hflag8_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x85: { // TEST R/M16, REG16
		const ubyte rm = __fu8_i;
		const int n = __fu16(get_rm16(rm, 1));
		int r = void;
		switch (rm & RM_REG) {
		case RM_REG_000: r = CPU.AX & n; break;
		case RM_REG_001: r = CPU.CX & n; break;
		case RM_REG_010: r = CPU.DX & n; break;
		case RM_REG_011: r = CPU.BX & n; break;
		case RM_REG_100: r = CPU.SP & n; break;
		case RM_REG_101: r = CPU.BP & n; break;
		case RM_REG_110: r = CPU.SI & n; break;
		case RM_REG_111: r = CPU.DI & n; break;
		default:
		}
		__hflag16_3(r);
		CPU.EIP += 2;
		return;
	}
	case 0x86: { // XCHG REG8, R/M8
		const ubyte rm = __fu8_i;
		const int addr = get_rm16(rm);
		const ubyte s = __fu8(addr);
		// temp <- REG
		// REG  <- MEM
		// MEM  <- temp
		ubyte r = void;
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = CPU.AL; CPU.AL = s;
			break;
		case RM_REG_001:
			r = CPU.CL; CPU.CL = s;
			break;
		case RM_REG_010:
			r = CPU.DL; CPU.DL = s;
			break;
		case RM_REG_011:
			r = CPU.BL; CPU.BL = s;
			break;
		case RM_REG_100:
			r = CPU.AH; CPU.AH = s;
			break;
		case RM_REG_101:
			r = CPU.CH; CPU.CH = s;
			break;
		case RM_REG_110:
			r = CPU.DH; CPU.DH = s;
			break;
		case RM_REG_111:
			r = CPU.BH; CPU.BH = s;
			break;
		default:
		}
		__iu8(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x87: { // XCHG REG16, R/M16
		const ubyte rm = __fu8_i;
		const int addr = get_rm16(rm, 1);
		// temp <- REG
		// REG  <- MEM
		// MEM  <- temp
		ushort r = void; const ushort s = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = CPU.AX; CPU.AX = s;
			break;
		case RM_REG_001:
			r = CPU.CX; CPU.CX = s;
			break;
		case RM_REG_010:
			r = CPU.DX; CPU.DX = s;
			break;
		case RM_REG_011:
			r = CPU.BX; CPU.BX = s;
			break;
		case RM_REG_100:
			r = CPU.SP; CPU.SP = s;
			break;
		case RM_REG_101:
			r = CPU.BP; CPU.BP = s;
			break;
		case RM_REG_110:
			r = CPU.SI; CPU.SI = s;
			break;
		case RM_REG_111:
			r = CPU.DI; CPU.DI = s;
			break;
		default:
		}
		__iu16(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0x88: { // MOV R/M8, REG8
		const ubyte rm = __fu8_i;
		int addr = get_rm16(rm);
		switch (rm & RM_REG) {
		case RM_REG_000: __iu8(CPU.AL, addr); break;
		case RM_REG_001: __iu8(CPU.CL, addr); break;
		case RM_REG_010: __iu8(CPU.DL, addr); break;
		case RM_REG_011: __iu8(CPU.BL, addr); break;
		case RM_REG_100: __iu8(CPU.AH, addr); break;
		case RM_REG_101: __iu8(CPU.CH, addr); break;
		case RM_REG_110: __iu8(CPU.DH, addr); break;
		case RM_REG_111: __iu8(CPU.BH, addr); break;
		default:
		}
		CPU.EIP += 2;
		return;
	}
	case 0x89: { // MOV R/M16, REG16
		const ubyte rm = __fu8_i;
		int addr = get_rm16(rm, 1);
		switch (rm & RM_REG) {
		case RM_REG_000: __iu16(CPU.AX, addr); break;
		case RM_REG_001: __iu16(CPU.CX, addr); break;
		case RM_REG_010: __iu16(CPU.DX, addr); break;
		case RM_REG_011: __iu16(CPU.BX, addr); break;
		case RM_REG_100: __iu16(CPU.SP, addr); break;
		case RM_REG_101: __iu16(CPU.BP, addr); break;
		case RM_REG_110: __iu16(CPU.SI, addr); break;
		case RM_REG_111: __iu16(CPU.DI, addr); break;
		default:
		}
		CPU.EIP += 2;
		return;
	}
	case 0x8A: { // MOV REG8, R/M8
		const ubyte rm = __fu8_i;
		const int addr = get_rm16(rm);
		const ubyte r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: CPU.AL = r; break;
		case RM_REG_001: CPU.CL = r; break;
		case RM_REG_010: CPU.DL = r; break;
		case RM_REG_011: CPU.BL = r; break;
		case RM_REG_100: CPU.AH = r; break;
		case RM_REG_101: CPU.CH = r; break;
		case RM_REG_110: CPU.DH = r; break;
		case RM_REG_111: CPU.BH = r; break;
		default:
		}
		CPU.EIP += 2;
		return;
	}
	case 0x8B: { // MOV REG16, R/M16
		const ubyte rm = __fu8_i;
		const int addr = get_rm16(rm, 1);
		const ushort r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: CPU.AX = r; break;
		case RM_REG_001: CPU.CX = r; break;
		case RM_REG_010: CPU.DX = r; break;
		case RM_REG_011: CPU.BX = r; break;
		case RM_REG_100: CPU.SP = r; break;
		case RM_REG_101: CPU.BP = r; break;
		case RM_REG_110: CPU.SI = r; break;
		case RM_REG_111: CPU.DI = r; break;
		default:
		}
		CPU.EIP += 2;
		return;
	}
	case 0x8C: { // MOV R/M16, SEGREG
		// MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
		const byte rm = __fu8_i;
		const int addr = get_rm16(rm, 1);
		switch (rm & RM_REG) { // if REG[3] is clear, trip to default
		case RM_REG_100: __iu16(CPU.ES, addr); break;
		case RM_REG_101: __iu16(CPU.CS, addr); break;
		case RM_REG_110: __iu16(CPU.SS, addr); break;
		case RM_REG_111: __iu16(CPU.DS, addr); break;
		default: // when bit 6 is clear (REG[3])
			log_info("Invalid ModR/M for SEGREG->RM");
			goto EXEC16_ILLEGAL;
		}
		CPU.EIP += 2;
		return;
	}
	case 0x8D: { // LEA REG16, MEM16
		const ubyte rm = __fu8_i;
		const ushort addr = cast(ushort)get_rm16(rm, 1);
		switch (rm & RM_REG) {
		case RM_REG_000: CPU.AX = addr; break;
		case RM_REG_001: CPU.CX = addr; break;
		case RM_REG_010: CPU.DX = addr; break;
		case RM_REG_011: CPU.BX = addr; break;
		case RM_REG_100: CPU.BP = addr; break;
		case RM_REG_101: CPU.SP = addr; break;
		case RM_REG_110: CPU.SI = addr; break;
		case RM_REG_111: CPU.DI = addr; break;
		default: // Never happens
		}
		CPU.EIP += 2;
		return;
	}
	case 0x8E: { // MOV SEGREG, R/M16
		// MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
		const byte rm = __fu8_i;
		const ushort addr = __fu16(get_rm16(rm, 1));
		switch (rm & RM_REG) { // if REG[3] is clear, trip to default
		case RM_REG_100: CPU.ES = addr; break;
		case RM_REG_101: CPU.CS = addr; break;
		case RM_REG_110: CPU.SS = addr; break;
		case RM_REG_111: CPU.DS = addr; break;
		default: // when bit 6 is clear (REG[3])
			log_info("Invalid ModR/M for SEGREG<-RM");
			goto EXEC16_ILLEGAL;
		}
		CPU.EIP += 2;
		return;
	}
	case 0x8F: { // POP R/M16
		const ubyte rm = __fu8_i;
		if (rm & RM_REG) { // REG must be 000
			log_info("Invalid ModR/M for POP R/M16");
			goto EXEC16_ILLEGAL;
		}
		__iu16(pop16, get_rm16(rm, 1));
		CPU.EIP += 2;
		return;
	}
	case 0x90: // NOP (aka XCHG AX, AX)
		++CPU.EIP;
		return;
	case 0x91: { // XCHG AX, CX
		const ushort r = CPU.AX;
		CPU.AX = CPU.CX;
		CPU.CX = r;
		++CPU.EIP;
		return;
	}
	case 0x92: { // XCHG AX, DX
		const ushort r = CPU.AX;
		CPU.AX = CPU.DX;
		CPU.DX = r;
		++CPU.EIP;
		return;
	}
	case 0x93: { // XCHG AX, BX
		const ushort r = CPU.AX;
		CPU.AX = CPU.BX;
		CPU.BX = r;
		++CPU.EIP;
		return;
	}
	case 0x94: { // XCHG AX, SP
		const ushort r = CPU.AX;
		CPU.AX = CPU.SP;
		CPU.SP = r;
		++CPU.EIP;
		return;
	}
	case 0x95: { // XCHG AX, BP
		const ushort r = CPU.AX;
		CPU.AX = CPU.BP;
		CPU.BP = r;
		++CPU.EIP;
		return;
	}
	case 0x96: { // XCHG AX, SI
		const ushort r = CPU.AX;
		CPU.AX = CPU.SI;
		CPU.SI = r;
		++CPU.EIP;
		return;
	}
	case 0x97: { // XCHG AX, DI
		const ushort r = CPU.AX;
		CPU.AX = CPU.DI;
		CPU.DI = r;
		++CPU.EIP;
		return;
	}
	case 0x98: // CBW
		CPU.AH = CPU.AL & 0x80 ? 0xFF : 0;
		++CPU.EIP;
		return;
	case 0x99: // CWD
		CPU.DX = CPU.AX & 0x8000 ? 0xFFFF : 0;
		++CPU.EIP;
		return;
	case 0x9A: { // CALL FAR_PROC
		const ushort cs = __fu16_i;
		const ushort ip = __fu16_i(2);
		push16(CPU.CS);
		push16(CPU.IP);
		CPU.CS = cs;
		CPU.IP = ip;
		return;
	}
	case 0x9B: // WAIT
	// Causes the processor to check for and handle pending, unmasked,
	// floating-point exceptions before proceeding.
	//TODO: WAIT
		++CPU.EIP;
		return;
	case 0x9C: // PUSHF
		push16(FLAG);
		++CPU.EIP;
		return;
	case 0x9D: // POPF
		FLAG = pop16;
		++CPU.EIP;
		return;
	case 0x9E: // SAHF (AH to Flags)
		FLAGB = CPU.AH;
		++CPU.EIP;
		return;
	case 0x9F: // LAHF (Flags to AH)
		CPU.AH = FLAGB;
		++CPU.EIP;
		return;
	case 0xA0: // MOV AL, MEM8
		CPU.AL = __fu8(__fu16_i);
		CPU.EIP += 2;
		return;
	case 0xA1: // MOV AX, MEM16
		CPU.AX = __fu16(__fu16_i);
		CPU.EIP += 3;
		return;
	case 0xA2: // MOV MEM8, AL
		__iu8(CPU.AL, __fu16_i);
		CPU.EIP += 2;
		return;
	case 0xA3: // MOV MEM16, AX
		__iu16(CPU.AX, __fu16_i);
		CPU.EIP += 3;
		return;
	case 0xA4: // MOVS DEST-STR8, SRC-STR8

		return;
	case 0xA5: // MOVS DEST-STR16, SRC-STR16

		return;
	case 0xA6: // CMPS DEST-STR8, SRC-STR8
		__hflag8_1(
			__fu8(get_ad(CPU.DS, CPU.SI)) - __fu8(get_ad(CPU.ES, CPU.DI))
		);
		if (CPU.DF) {
			--CPU.DI;
			--CPU.SI;
		} else {
			++CPU.DI;
			++CPU.SI;
		}
		return;
	case 0xA7: // CMPSW DEST-STR16, SRC-STR16
		__hflag16_1(
			__fu16(get_ad(CPU.DS, CPU.SI)) - __fu16(get_ad(CPU.ES, CPU.DI))
		);
		if (CPU.DF) {
			CPU.DI -= 2;
			CPU.SI -= 2;
		} else {
			CPU.DI += 2;
			CPU.SI += 2;
		}
		return;
	case 0xA8: // TEST AL, IMM8
		__hflag8_3(CPU.AL & __fu8_i);
		CPU.EIP += 2;
		return;
	case 0xA9: // TEST AX, IMM16
		__hflag16_3(CPU.AX & __fu16_i);
		CPU.EIP += 3;
		return;
	case 0xAA: // STOS DEST-STR8
		__iu8(CPU.AL, get_ad(CPU.ES, CPU.DI));
		//CPU.DI = DF ? CPU.DI - 1 : CPU.DI + 1;
		if (CPU.DF) --CPU.DI; else ++CPU.DI;
		++CPU.EIP;
		return;
	case 0xAB: // STOS DEST-STR16
		__iu16(CPU.AX, get_ad(CPU.ES, CPU.DI));
		//CPU.DI = DF ? CPU.DI - 2 : CPU.DI + 2;
		if (CPU.DF) CPU.DI -= 2; else CPU.DI += 2;
		++CPU.EIP;
		return;
	case 0xAC: // LODS SRC-STR8
		CPU.AL = __fu8(get_ad(CPU.DS, CPU.SI));
		//CPU.SI = DF ? CPU.SI - 1 : CPU.SI + 1;
		if (CPU.DF) --CPU.SI; else ++CPU.SI;
		++CPU.EIP;
		return;
	case 0xAD: // LODS SRC-STR16
		CPU.AX = __fu16(get_ad(CPU.DS, CPU.SI));
		//CPU.SI = DF ? CPU.SI - 2 : CPU.SI + 2;
		if (CPU.DF) CPU.SI -= 2; else CPU.SI += 2;
		++CPU.EIP;
		return;
	case 0xAE: // SCAS DEST-STR8
		__hflag8_1(CPU.AL - __fu8(get_ad(CPU.ES, CPU.DI)));
		//CPU.DI = DF ? CPU.DI - 1 : CPU.DI + 1;
		if (CPU.DF) --CPU.DI; else ++CPU.DI;
		++CPU.EIP;
		return;
	case 0xAF: // SCAS DEST-STR16
		__hflag16_1(CPU.AX - __fu16(get_ad(CPU.ES, CPU.DI)));
		//CPU.DI = DF ? CPU.DI - 2 : CPU.DI + 2;
		if (CPU.DF) CPU.DI -= 2; else CPU.DI += 2;
		++CPU.EIP;
		return;
	case 0xB0: // MOV AL, IMM8
		CPU.AL = __fu8_i;
		CPU.EIP += 2;
		return;
	case 0xB1: // MOV CL, IMM8
		CPU.CL = __fu8_i;
		CPU.EIP += 2;
		return;
	case 0xB2: // MOV DL, IMM8
		CPU.DL = __fu8_i;
		CPU.EIP += 2;
		return;
	case 0xB3: // MOV BL, IMM8
		CPU.BL = __fu8_i;
		CPU.EIP += 2;
		return;
	case 0xB4: // MOV AH, IMM8
		CPU.AH = __fu8_i;
		CPU.EIP += 2;
		return;
	case 0xB5: // MOV CH, IMM8
		CPU.CH = __fu8_i;
		CPU.EIP += 2;
		return;
	case 0xB6: // MOV DH, IMM8  
		CPU.DH = __fu8_i;
		CPU.EIP += 2;
		return;
	case 0xB7: // MOV BH, IMM8
		CPU.BH = __fu8_i;
		CPU.EIP += 2;
		return;
	case 0xB8: // MOV AX, IMM16
		CPU.AX = __fu16_i;
		CPU.EIP += 3;
		return;
	case 0xB9: // MOV CX, IMM16
		CPU.CX = __fu16_i;
		CPU.EIP += 3;
		return;
	case 0xBA: // MOV DX, IMM16
		CPU.DX = __fu16_i;
		CPU.EIP += 3;
		return;
	case 0xBB: // MOV BX, IMM16
		CPU.BX = __fu16_i;
		CPU.EIP += 3;
		return;
	case 0xBC: // MOV SP, IMM16
		CPU.SP = __fu16_i;
		CPU.EIP += 3;
		return;
	case 0xBD: // MOV BP, IMM16
		CPU.BP = __fu16_i;
		CPU.EIP += 3;
		return;
	case 0xBE: // MOV SI, IMM16
		CPU.SI = __fu16_i;
		CPU.EIP += 3;
		return;
	case 0xBF: // MOV DI, IMM16
		CPU.DI = __fu16_i;
		CPU.EIP += 3;
		return;
	case 0xC2: { // RET IMM16 (NEAR)
		const ushort sp = __fi16_i;
		CPU.IP = pop16;
		CPU.SP += sp;
		return;
	}
	case 0xC3: // RET (NEAR)
		CPU.IP = pop16;
		return;
	case 0xC4, 0xC5: { // LES/LDS REG16, MEM16
		// Load into REG and ES/DS
		const ubyte rm = __fu8_i;
		const ushort r = __fu16(get_rm16(rm, 1));
		CPU.Segment = op == 0xC4 ? SEG_ES : SEG_DS; // "Segment selector"
		switch (rm & RM_REG) {
		case RM_REG_000: CPU.AX = r; break;
		case RM_REG_001: CPU.CX = r; break;
		case RM_REG_010: CPU.DX = r; break;
		case RM_REG_011: CPU.BX = r; break;
		case RM_REG_100: CPU.SP = r; break;
		case RM_REG_101: CPU.BP = r; break;
		case RM_REG_110: CPU.SI = r; break;
		case RM_REG_111: CPU.DI = r; break;
		default:
		}
		CPU.EIP += 2;
		return;
	}
	case 0xC6: { // MOV MEM8, IMM8
		const ubyte rm = __fu8_i;
		if (rm & RM_REG) { // No register operation allowed
			log_info("Invalid ModR/M for MOV MEM8");
			goto EXEC16_ILLEGAL;
		}
		__iu8(__fu8_i(1), get_rm16(rm));
		return;
	}
	case 0xC7: { // MOV MEM16, IMM16
		const ubyte rm = __fu8_i;
		if (rm & RM_REG) { // No register operation allowed
			log_info("Invalid ModR/M for MOV MEM16");
			goto EXEC16_ILLEGAL;
		}
		__iu16(__fu16_i(1), get_rm16(rm, 1));
		return;
	}
	case 0xCA: { // RET IMM16 (FAR)
		const uint addr = CPU.EIP + 1;
		CPU.IP = pop16;
		CPU.CS = pop16;
		CPU.SP += __fi16(addr);
		return;
	}
	case 0xCB: // RET (FAR)
		CPU.IP = pop16;
		CPU.CS = pop16;
		return;
	case 0xCC: // INT 3
		INT(3);
		++CPU.EIP;
		return;
	case 0xCD: // INT IMM8
		INT(__fu8_i);
		CPU.EIP += 2;
		return;
	case 0xCE: // INTO
		if (CPU.CF) INT(4);
		++CPU.EIP;
		return;
	case 0xCF: // IRET
		CPU.IP = pop16;
		CPU.CS = pop16;
		FLAG = pop16;
		++CPU.EIP;
		return;
	case 0xD0: { // GRP2 R/M8, 1
		const ubyte rm = __fu8_i;
		const int addr = get_rm16(rm);
		int r = __fu8(addr);
		//TODO: handle flags accordingly
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - ROL
			r <<= 1;
			if (r & 0x100) r |= 1;
			break;
		case RM_REG_001: // 001 - ROR
			if (r & 1) r |= 0x100;
			r >>= 1;
			break;
		case RM_REG_010: // 010 - RCL
			r <<= 1;
			if (r & 0x200) r |= 1;
			break;
		case RM_REG_011: // 011 - RCR
			if (r & 1) r |= 0x200;
			r >>= 1;
			break;
		case RM_REG_100: // 100 - SAL/SHL
			r <<= 1;
			break;
		case RM_REG_101: // 101 - SHR
			r >>= 1;
			break;
		case RM_REG_111: // 111 - SAR
			if (r & 0x80) r |= 0x100;
			r >>= 1;
			break;
		default: // 110
			log_info("Invalid ModR/M for GRP2 R/M8, 1");
			goto EXEC16_ILLEGAL;
		}
		__iu8(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0xD1: { // GRP2 R/M16, 1
		const ubyte rm = __fu8_i;
		const int addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - ROL
			r <<= 1;
			if (r & 0x1_0000) r |= 1;
			break;
		case RM_REG_001: // 001 - ROR
			if (r & 1) r |= 0x1_0000;
			r >>= 1;
			break;
		case RM_REG_010: // 010 - RCL
			r <<= 1;
			if (r & 0x2_0000) r |= 1;
			break;
		case RM_REG_011: // 011 - RCR
			if (r & 1) r |= 0x2_0000;
			r >>= 1;
			break;
		case RM_REG_100: // 100 - SAL/SHL
			r <<= 1;
			break;
		case RM_REG_101: // 101 - SHR
			r >>= 1;
			break;
		case RM_REG_111: // 111 - SAR
			if (r & 0x8000) r |= 0x1_0000;
			r >>= 1;
			break;
		default: // 110
			log_info("Invalid ModR/M for GRP2 R/M16, 1");
			goto EXEC16_ILLEGAL;
		}
		//TODO: handle flags accordingly
		__iu16(r, addr);
		CPU.EIP += 2;
		return;
	}
	case 0xD2: // GRP2 R/M8, CL
	// The 8086 does not mask the rotation count.
		/*const ubyte rm = __fu8_i;
		const int addr = get_rm16(rm);
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
			log_info("Invalid ModR/M for GRP2 R/M8, CL");
			goto EXEC16_ILLEGAL;
		}*/
		CPU.EIP += 2;
		return;
	case 0xD3: // GRP2 R/M16, CL
	// The 8086 does not mask the rotation count.
		/*const ubyte rm = __fu8_i;
		const int addr = get_rm16(rm, 1);
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
			log_info("Invalid ModR/M for GRP2 R/M16, CL");
			goto EXEC16_ILLEGAL;
		}*/
		CPU.EIP += 2;
		return;
	case 0xD4: // AAM
		int r = CPU.AL % 0xA;
		__hflag8_5(r);
		CPU.AL = cast(ubyte)r;
		CPU.AH = cast(ubyte)(r / 0xA);
		++CPU.EIP;
		return;
	case 0xD5: // AAD
		int r = CPU.AL + (CPU.AH * 0xA);
		__hflag8_5(r);
		CPU.AL = cast(ubyte)r;
		CPU.AH = 0;
		++CPU.EIP;
		return;
	case 0xD7: // XLAT SOURCE-TABLE
		CPU.AL = __fu8(get_ad(CPU.DS, CPU.BX) + cast(byte)CPU.AL);
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
		--CPU.CX;
		if (CPU.CX && CPU.ZF == 0) CPU.EIP += __fi8_i;
		else CPU.EIP += 2;
		return;
	case 0xE1: // LOOPE/LOOPZ   SHORT-LABEL
		--CPU.CX;
		if (CPU.CX && CPU.ZF) CPU.EIP += __fi8_i;
		else CPU.EIP += 2;
		return;
	case 0xE2: // LOOP  SHORT-LABEL
		--CPU.CX;
		if (CPU.CX) CPU.EIP += __fi8_i;
		else CPU.EIP += 2;
		return;
	case 0xE3: // JCXZ  SHORT-LABEL
		if (CPU.CX == 0) CPU.EIP += __fi8_i;
		else CPU.EIP += 2;
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
		push16(CPU.IP);
		CPU.EIP += __fi16_i; // Direct within segment
		return;
	case 0xE9: // JMP NEAR-LABEL
		CPU.EIP += __fi16_i + 3; // ±32 KB
		return;
	case 0xEA: // JMP FAR-LABEL
		// Any segment, any fragment, 5 byte instruction.
		// EAh (LO-CPU.IP) (HI-CPU.IP) (LO-CPU.CS) (HI-CPU.CS)
		CPU.IP = __fu16_i;
		CPU.CS = __fu16_i(2);
		return;
	case 0xEB: // JMP SHORT-LABEL
		CPU.EIP += __fi8_i + 2; // ±128 B
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
		++CPU.EIP;
		return;
	case 0xF2: // REPNE/REPNZ
		while (CPU.CX > 0) {
			//TODO: Finish REPNE/REPNZ properly?
			exec16(0xA6);
			--CPU.CX;
			if (CPU.ZF == 0) break;
		}
		++CPU.EIP;
		return;
	case 0xF3: // REP/REPE/REPNZ

		return;
	case 0xF4: // HLT
		RLEVEL = 0;
		++CPU.EIP;
		return;
	case 0xF5: // CMC
		CPU.CF = !CPU.CF;
		++CPU.EIP;
		return;
	case 0xF6: { // GRP3 R/M8, IMM8
		const ubyte rm = __fu8_i; // Get ModR/M byte
		ubyte im = __fu8_i(1);
		int addr = get_rm16(rm);
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
			CPU.CF = cast(ubyte)r;
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
			const ubyte d = __fu8(addr);
			r = CPU.AX / d;
			CPU.AH = cast(ubyte)(CPU.AX % d);
			CPU.AL = cast(ubyte)(r);
			break;
		case RM_REG_111: // 111 - IDIV
		//TODO: Check if im == 0 (#DE), IDIV
			const byte d = __fi8(addr);
			r = cast(short)CPU.AX / d;
			CPU.AH = cast(ubyte)(cast(short)CPU.AX % d);
			CPU.AL = cast(ubyte)r;
			break;
		default:
			log_info("Invalid ModR/M on GRP3_8");
			goto EXEC16_ILLEGAL;
		}
		CPU.EIP += 3;
		return;
	}
	case 0xF7: { // GRP3 R/M16, IMM16
		const ubyte rm = __fu8_i; // Get ModR/M byte
		ushort im = __fu16_i(1);
		int addr = get_rm16(rm, 1);
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
			CPU.CF = cast(ubyte)r;
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
			log_info("Invalid ModR/M on GRP3_8");
			goto EXEC16_ILLEGAL;
		}
		CPU.EIP += 4;
		return;
	}
	case 0xF8: // CLC
		CPU.CF = 0;
		++CPU.EIP;
		return;
	case 0xF9: // STC
		CPU.CF = 1;
		++CPU.EIP;
		return;
	case 0xFA: // CLI
		CPU.IF = 0;
		++CPU.EIP;
		return;
	case 0xFB: // STI
		CPU.IF = 1;
		++CPU.EIP;
		return;
	case 0xFC: // CLD
		CPU.DF = 0;
		++CPU.EIP;
		return;
	case 0xFD: // STD
		CPU.DF = 1;
		++CPU.EIP;
		return;
	case 0xFE: { // GRP4 R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - INC
			++r;
			break;
		case RM_REG_001: // 001 - DEC
			--r;
			break;
		default:
			log_info("Invalid ModR/M on GRP4_8");
			goto EXEC16_ILLEGAL;
		}
		__iu16(r, addr);
		__hflag16_2(r);
		CPU.EIP += 2;
		return;
	}
	case 0xFF: { // GRP5 R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_rm16(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - INC
			++r;
			__hflag16_2(r);
			__iu16(r, addr);
			CPU.EIP += 2;
			return;
		case RM_REG_001: // 001 - DEC
			--r;
			__hflag16_2(r);
			__iu16(r, addr);
			CPU.EIP += 2;
			break;
		case RM_REG_010: // 010 - CALL R/M16 (near) -- Indirect within segment
			push16(CPU.IP);
			CPU.IP = cast(ushort)r;
			break;
		case RM_REG_011: { // 011 - CALL MEM16 (far) -- Indirect outside segment
			ushort nip = cast(ushort)get_ad(__fu16(addr + 2), r);
			push16(CPU.CS);
			push16(CPU.IP);
			CPU.IP = nip;
			break;
		}
		case RM_REG_100: // 100 - JMP R/M16 (near) -- Indirect within segment
			CPU.IP = cast(ushort)(r + 2);
			break;
		case RM_REG_101: // 101 - JMP MEM16 (far) -- Indirect outside segment
			CPU.IP = cast(ushort)get_ad(__fu16(addr), r + 2);
			break;
		case RM_REG_110: // 110 - PUSH MEM16
			push16(__fu16(get_ad(__fu16(addr + 2), r)));
			CPU.EIP += 2;
			break;
		default:
			log_info("Invalid ModR/M on GRP5_16");
			goto EXEC16_ILLEGAL;
		}
		return;
	}
	default: // Illegal instruction
EXEC16_ILLEGAL:
		log_info("INVALID OPERATION CODE");
		//TODO: Raise vector on illegal op
		return;
	}
}