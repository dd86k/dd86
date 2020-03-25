/**
 * Execution core
 */
module vcpu.exec;

import vcpu.core, vcpu.mm, vcpu.utils;
import vdos.interrupts, vdos.io;
import logger;

extern (C):

/**
 * Execute an instruction
 * Params: op = opcode
 */
void execop(ubyte op) {
	OPMAP[op]();
}

void exec00() {	// 00h ADD R/M8, REG8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
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
	cpuf8_1(r);
	mmiu8(r, addr);
	CPU.EIP += 2;
}

void exec01() {	// 01h ADD R/M16, REG16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
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
	cpuf16_1(r);
	mmiu16(r, addr);
	CPU.EIP += 2;
}

void exec02() {	// 02h ADD REG8, R/M8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: r += CPU.AL; CPU.AL = cast(ubyte)r; break;
	case RM_REG_001: r += CPU.CL; CPU.CL = cast(ubyte)r; break;
	case RM_REG_010: r += CPU.DL; CPU.DL = cast(ubyte)r; break;
	case RM_REG_011: r += CPU.BL; CPU.BL = cast(ubyte)r; break;
	case RM_REG_100: r += CPU.AH; CPU.AH = cast(ubyte)r; break;
	case RM_REG_101: r += CPU.CH; CPU.CH = cast(ubyte)r; break;
	case RM_REG_110: r += CPU.DH; CPU.DH = cast(ubyte)r; break;
	case RM_REG_111: r += CPU.BH; CPU.BH = cast(ubyte)r; break;
	default:
	}
	cpuf8_1(r);
	CPU.EIP += 2;
}

void exec03() {	// 03h ADD REG16, R/M16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: r += CPU.AX; CPU.AX = cast(ushort)r; break;
	case RM_REG_001: r += CPU.CX; CPU.CX = cast(ushort)r; break;
	case RM_REG_010: r += CPU.DX; CPU.DX = cast(ushort)r; break;
	case RM_REG_011: r += CPU.BX; CPU.BX = cast(ushort)r; break;
	case RM_REG_100: r += CPU.SP; CPU.SP = cast(ushort)r; break;
	case RM_REG_101: r += CPU.BP; CPU.BP = cast(ushort)r; break;
	case RM_REG_110: r += CPU.SI; CPU.SI = cast(ushort)r; break;
	case RM_REG_111: r += CPU.DI; CPU.DI = cast(ushort)r; break;
	default:
	}
	cpuf16_1(r);
	CPU.EIP += 2;
}

void exec04() {	// 04h ADD AL, IMM8
	const int r = CPU.AL + mmfu8_i;
	cpuf8_1(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void exec05() {	// 05h ADD AX, IMM16
	const int r = CPU.AX + mmfu16_i;
	cpuf16_1(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 2;
}

void exec06() {	// 06h PUSH ES
	CPU.push16(CPU.ES);
	++CPU.EIP;
}

void exec07() {	// 07h POP ES
	CPU.ES = CPU.pop16;
	++CPU.EIP;
}

void exec08() {	// 08h OR R/M8, REG8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
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
	cpuf8_3(r);
	mmiu8(r, addr);
	CPU.EIP += 2;
}

void exec09() {	// 09h OR R/M16, REG16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
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
	cpuf16_3(r);
	mmiu16(r, addr);
	CPU.EIP += 2;
}

void exec0A() {	// 0Ah OR REG8, R/M8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: r |= CPU.AL; CPU.AL = cast(ubyte)r; break;
	case RM_REG_001: r |= CPU.CL; CPU.CL = cast(ubyte)r; break;
	case RM_REG_010: r |= CPU.DL; CPU.DL = cast(ubyte)r; break;
	case RM_REG_011: r |= CPU.BL; CPU.BL = cast(ubyte)r; break;
	case RM_REG_100: r |= CPU.AH; CPU.AH = cast(ubyte)r; break;
	case RM_REG_101: r |= CPU.CH; CPU.CH = cast(ubyte)r; break;
	case RM_REG_110: r |= CPU.DH; CPU.DH = cast(ubyte)r; break;
	case RM_REG_111: r |= CPU.BH; CPU.BH = cast(ubyte)r; break;
	default:
	}
	cpuf8_3(r);
	CPU.EIP += 2;
}

void exec0B() {	// 0Bh OR REG16, R/M16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: r |= CPU.AX; CPU.AX = cast(ushort)r; break;
	case RM_REG_001: r |= CPU.CX; CPU.CX = cast(ushort)r; break;
	case RM_REG_010: r |= CPU.DX; CPU.DX = cast(ushort)r; break;
	case RM_REG_011: r |= CPU.BX; CPU.BX = cast(ushort)r; break;
	case RM_REG_100: r |= CPU.SP; CPU.SP = cast(ushort)r; break;
	case RM_REG_101: r |= CPU.BP; CPU.BP = cast(ushort)r; break;
	case RM_REG_110: r |= CPU.SI; CPU.SI = cast(ushort)r; break;
	case RM_REG_111: r |= CPU.DI; CPU.DI = cast(ushort)r; break;
	default:
	}
	cpuf16_3(r);
	CPU.EIP += 2;
}

void exec0C() {	// 0Ch OR AL, IMM8
	const int r = CPU.AL | mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void exec0D() {	// 0Dh OR AX, IMM16
	const int r = CPU.AX | mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void exec0E() {	// 0Eh PUSH CS
	CPU.push16(CPU.CS);
	++CPU.EIP;
}

void exec10() {	// 10h ADC R/M8, REG8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
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
	cpuf8_3(r);
	mmiu8(r, addr);
	CPU.EIP += 2;
}

void exec11() {	// 11h ADC R/M16, REG16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
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
	cpuf16_3(r);
	mmiu16(r, addr);
	CPU.EIP += 2;
}

void exec12() {	// 12h ADC REG8, R/M8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
	if (CPU.CF) ++r;
	switch (rm & RM_REG) {
	case RM_REG_000: r += CPU.AL; CPU.AL = cast(ubyte)r; break;
	case RM_REG_001: r += CPU.CL; CPU.CL = cast(ubyte)r; break;
	case RM_REG_010: r += CPU.DL; CPU.DL = cast(ubyte)r; break;
	case RM_REG_011: r += CPU.BL; CPU.BL = cast(ubyte)r; break;
	case RM_REG_100: r += CPU.AH; CPU.AH = cast(ubyte)r; break;
	case RM_REG_101: r += CPU.CH; CPU.CH = cast(ubyte)r; break;
	case RM_REG_110: r += CPU.DH; CPU.DH = cast(ubyte)r; break;
	case RM_REG_111: r += CPU.BH; CPU.BH = cast(ubyte)r; break;
	default:
	}
	cpuf8_3(r);
	CPU.EIP += 2;
}

void exec13() {	// 13h ADC REG16, R/M16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	if (CPU.CF) ++r;
	switch (rm & RM_REG) {
	case RM_REG_000: r += CPU.AX; CPU.AX = cast(ushort)r; break;
	case RM_REG_001: r += CPU.CX; CPU.CX = cast(ushort)r; break;
	case RM_REG_010: r += CPU.DX; CPU.DX = cast(ushort)r; break;
	case RM_REG_011: r += CPU.BX; CPU.BX = cast(ushort)r; break;
	case RM_REG_100: r += CPU.SP; CPU.SP = cast(ushort)r; break;
	case RM_REG_101: r += CPU.BP; CPU.BP = cast(ushort)r; break;
	case RM_REG_110: r += CPU.SI; CPU.SI = cast(ushort)r; break;
	case RM_REG_111: r += CPU.DI; CPU.DI = cast(ushort)r; break;
	default:
	}
	cpuf16_3(r);
	CPU.EIP += 2;
}

void exec14() {	// 14h ADC AL, IMM8
	int r = CPU.AL + mmfu8_i;
	cpuf8_1(r);
	if (CPU.CF) ++r;
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void exec15() {	// 15h ADC AX, IMM16
	int r = CPU.AX + mmfu16_i;
	cpuf16_1(r);
	if (CPU.CF) ++r;
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void exec16() {	// 16h PUSH SS
	CPU.push16(CPU.SS);
	++CPU.EIP;
}

void exec17() {	// 17h POP SS
	CPU.SS = CPU.pop16;
	++CPU.EIP;
}

void exec18() {	// 18h SBB R/M8, REG8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
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
	cpuf8_3(r);
	mmiu8(r, addr);
	CPU.EIP += 2;
}

void exec19() {	// 19h SBB R/M16, REG16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
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
	cpuf16_3(r);
	mmiu16(r, addr);
	CPU.EIP += 2;
}

void exec1A() {	// 1Ah SBB REG8, R/M8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
	if (CPU.CF) --r;
	switch (rm & RM_REG) {
	case RM_REG_000: r = CPU.AL - r; CPU.AL = cast(ubyte)r; break;
	case RM_REG_001: r = CPU.CL - r; CPU.CL = cast(ubyte)r; break;
	case RM_REG_010: r = CPU.DL - r; CPU.DL = cast(ubyte)r; break;
	case RM_REG_011: r = CPU.BL - r; CPU.BL = cast(ubyte)r; break;
	case RM_REG_100: r = CPU.AH - r; CPU.AH = cast(ubyte)r; break;
	case RM_REG_101: r = CPU.CH - r; CPU.CH = cast(ubyte)r; break;
	case RM_REG_110: r = CPU.DH - r; CPU.DH = cast(ubyte)r; break;
	case RM_REG_111: r = CPU.BH - r; CPU.BH = cast(ubyte)r; break;
	default:
	}
	cpuf8_3(r);
	CPU.EIP += 2;
}

void exec1B() {	// 1Bh SBB REG16, R/M16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	if (CPU.CF) --r;
	switch (rm & RM_REG) {
	case RM_REG_000: r = CPU.AX - r; CPU.AX = cast(ushort)r; break;
	case RM_REG_001: r = CPU.CX - r; CPU.CX = cast(ushort)r; break;
	case RM_REG_010: r = CPU.DX - r; CPU.DX = cast(ushort)r; break;
	case RM_REG_011: r = CPU.BX - r; CPU.BX = cast(ushort)r; break;
	case RM_REG_100: r = CPU.SP - r; CPU.SP = cast(ushort)r; break;
	case RM_REG_101: r = CPU.BP - r; CPU.BP = cast(ushort)r; break;
	case RM_REG_110: r = CPU.SI - r; CPU.SI = cast(ushort)r; break;
	case RM_REG_111: r = CPU.DI - r; CPU.DI = cast(ushort)r; break;
	default:
	}
	cpuf16_3(r);
	CPU.EIP += 2;
}

void exec1C() {	// 1Ch SBB AL, IMM8
	int r = CPU.AL - mmfu8_i;
	if (CPU.CF) --r;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void exec1D() {	// 1Dh SBB AX, IMM16
	int r = CPU.AX - mmfu16_i;
	if (CPU.CF) --r;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void exec1E() {	// 1Eh PUSH DS
	CPU.push16(CPU.DS);
	++CPU.EIP;
}

void exec1F() {	// 1Fh POP DS
	CPU.DS = CPU.pop16;
	++CPU.EIP;
}

void exec20() {	// 20h AND R/M8, REG8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
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
	cpuf8_3(r);
	mmiu8(r, addr);
	CPU.EIP += 2;
}

void exec21() {	// 21h AND R/M16, REG16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
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
	cpuf16_3(r);
	mmiu16(r, addr);
	CPU.EIP += 2;
}

void exec22() {	// 22h AND REG8, R/M8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: r = CPU.AL & r; CPU.AL = cast(ubyte)r; break;
	case RM_REG_001: r = CPU.CL & r; CPU.CL = cast(ubyte)r; break;
	case RM_REG_010: r = CPU.DL & r; CPU.DL = cast(ubyte)r; break;
	case RM_REG_011: r = CPU.BL & r; CPU.BL = cast(ubyte)r; break;
	case RM_REG_100: r = CPU.AH & r; CPU.AH = cast(ubyte)r; break;
	case RM_REG_101: r = CPU.CH & r; CPU.CH = cast(ubyte)r; break;
	case RM_REG_110: r = CPU.DH & r; CPU.DH = cast(ubyte)r; break;
	case RM_REG_111: r = CPU.BH & r; CPU.BH = cast(ubyte)r; break;
	default:
	}
	cpuf8_3(r);
	CPU.EIP += 2;
}

void exec23() {	// 23h AND REG16, R/M16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: r = CPU.AX & r; CPU.AX = cast(ushort)r; break;
	case RM_REG_001: r = CPU.CX & r; CPU.CX = cast(ushort)r; break;
	case RM_REG_010: r = CPU.DX & r; CPU.DX = cast(ushort)r; break;
	case RM_REG_011: r = CPU.BX & r; CPU.BX = cast(ushort)r; break;
	case RM_REG_100: r = CPU.SP & r; CPU.SP = cast(ushort)r; break;
	case RM_REG_101: r = CPU.BP & r; CPU.BP = cast(ushort)r; break;
	case RM_REG_110: r = CPU.SI & r; CPU.SI = cast(ushort)r; break;
	case RM_REG_111: r = CPU.DI & r; CPU.DI = cast(ushort)r; break;
	default:
	}
	cpuf16_3(r);
	CPU.EIP += 2;
}

void exec24() {	// 24h AND AL, IMM8
	const int r = CPU.AL & mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void exec25() {	// 25h AND AX, IMM16
	const int r = CPU.AX & mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void exec26() {	// 26h ES: (Segment override prefix)
	CPU.Segment = SEG_ES;
	++CPU.EIP;
}

void exec27() {	// 27h DAA
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
	PF8(r);
	CPU.AL = cast(ubyte)r;

	++CPU.EIP;
}

void exec28() {	// 28h SUB R/M8, REG8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
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
	cpuf8_1(r);
	mmiu8(r, addr);
	CPU.EIP += 2;
}

void exec29() {	// 29h SUB R/M16, REG16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
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
	cpuf16_1(r);
	mmiu16(r, addr);
	CPU.EIP += 2;
}

void exec2A() {	// 2Ah SUB REG8, R/M8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: r = CPU.AL - r; CPU.AL = cast(ubyte)r; break;
	case RM_REG_001: r = CPU.CL - r; CPU.CL = cast(ubyte)r; break;
	case RM_REG_010: r = CPU.DL - r; CPU.DL = cast(ubyte)r; break;
	case RM_REG_011: r = CPU.BL - r; CPU.BL = cast(ubyte)r; break;
	case RM_REG_100: r = CPU.AH - r; CPU.AH = cast(ubyte)r; break;
	case RM_REG_101: r = CPU.CH - r; CPU.CH = cast(ubyte)r; break;
	case RM_REG_110: r = CPU.DH - r; CPU.DH = cast(ubyte)r; break;
	case RM_REG_111: r = CPU.BH - r; CPU.BH = cast(ubyte)r; break;
	default:
	}
	cpuf8_1(r);
	CPU.EIP += 2;
}

void exec2B() {	// 2Bh SUB REG16, R/M16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: r = CPU.AX - r; CPU.AX = cast(ushort)r; break;
	case RM_REG_001: r = CPU.CX - r; CPU.CX = cast(ushort)r; break;
	case RM_REG_010: r = CPU.DX - r; CPU.DX = cast(ushort)r; break;
	case RM_REG_011: r = CPU.BX - r; CPU.BX = cast(ushort)r; break;
	case RM_REG_100: r = CPU.SP - r; CPU.SP = cast(ushort)r; break;
	case RM_REG_101: r = CPU.BP - r; CPU.BP = cast(ushort)r; break;
	case RM_REG_110: r = CPU.SI - r; CPU.SI = cast(ushort)r; break;
	case RM_REG_111: r = CPU.DI - r; CPU.DI = cast(ushort)r; break;
	default:
	}
	cpuf16_1(r);
	CPU.EIP += 2;
}

void exec2C() {	// 2Ch SUB AL, IMM8
	const int r = CPU.AL - mmfu8_i;
	cpuf8_1(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void exec2D() {	// 2Dh SUB AX, IMM16
	const int r = CPU.AX - mmfu16_i;
	cpuf16_1(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void exec2E() {	// 2Eh CS:
	CPU.Segment = SEG_CS;
	++CPU.EIP;
}

void exec2F() {	// 2Fh DAS
	const ubyte oldAL = CPU.AL;
	const ubyte oldCF = CPU.CF;
	CPU.CF = 0;

	if (((oldAL & 0xF) > 9) || CPU.AF) {
		CPU.AL -= 6;
		CPU.CF = oldCF || (CPU.AL & 0x80);
		CPU.AF = 1;
	} else CPU.AF = 0;

	if ((oldAL > 0x99) || oldCF) {
		CPU.AL -= 0x60;
		CPU.CF = 1;
	} else CPU.CF = 0;

	++CPU.EIP;
}

void exec30() {	// 30h XOR R/M8, REG8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
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
	cpuf8_3(r);
	mmiu8(r, addr);
	CPU.EIP += 2;
}

void exec31() {	// 31h XOR R/M16, REG16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
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
	cpuf16_3(r);
	mmiu16(r, addr);
	CPU.EIP += 2;
}

void exec32() {	// 32h XOR REG8, R/M8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: r = CPU.AL ^ r; CPU.AL = cast(ubyte)r; break;
	case RM_REG_001: r = CPU.CL ^ r; CPU.CL = cast(ubyte)r; break;
	case RM_REG_010: r = CPU.DL ^ r; CPU.DL = cast(ubyte)r; break;
	case RM_REG_011: r = CPU.BL ^ r; CPU.BL = cast(ubyte)r; break;
	case RM_REG_100: r = CPU.AH ^ r; CPU.AH = cast(ubyte)r; break;
	case RM_REG_101: r = CPU.CH ^ r; CPU.CH = cast(ubyte)r; break;
	case RM_REG_110: r = CPU.DH ^ r; CPU.DH = cast(ubyte)r; break;
	case RM_REG_111: r = CPU.BH ^ r; CPU.BH = cast(ubyte)r; break;
	default:
	}
	cpuf8_3(r);
	CPU.EIP += 2;
}

void exec33() {	// 33h XOR REG16, R/M16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: r = CPU.AX ^ r; CPU.AX = cast(ushort)r; break;
	case RM_REG_001: r = CPU.CX ^ r; CPU.CX = cast(ushort)r; break;
	case RM_REG_010: r = CPU.DX ^ r; CPU.DX = cast(ushort)r; break;
	case RM_REG_011: r = CPU.BX ^ r; CPU.BX = cast(ushort)r; break;
	case RM_REG_100: r = CPU.SP ^ r; CPU.SP = cast(ushort)r; break;
	case RM_REG_101: r = CPU.BP ^ r; CPU.BP = cast(ushort)r; break;
	case RM_REG_110: r = CPU.SI ^ r; CPU.SI = cast(ushort)r; break;
	case RM_REG_111: r = CPU.DI ^ r; CPU.DI = cast(ushort)r; break;
	default:
	}
	cpuf16_3(r);
	CPU.EIP += 2;
}

void exec34() {	// 34h XOR AL, IMM8
	const int r = CPU.AL ^ mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void exec35() {	// 35h XOR AX, IMM16
	const int r = CPU.AX ^ mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void exec36() {	// 36h SS:
	CPU.Segment = SEG_SS;
	++CPU.EIP;
}

void exec37() {	// 37h AAA
	if (((CPU.AL & 0xF) > 9) || CPU.AF) {
		CPU.AX += 0x106;
		CPU.AF = CPU.CF = 1;
	} else CPU.AF = CPU.CF = 0;
	CPU.AL &= 0xF;
	++CPU.EIP;
}

void exec38() {	// 38h CMP R/M8, REG8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
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
	cpuf8_1(r);
	CPU.EIP += 2;
}

void exec39() {	// 39h CMP R/M16, REG16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
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
	cpuf16_1(r);
	CPU.EIP += 2;
}

void exec3A() {	// 3Ah CMP REG8, R/M8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
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
	cpuf8_1(r);
	CPU.EIP += 2;
}

void exec3B() {	// 3Bh CMP REG16, R/M16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
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
	cpuf16_1(r);
	CPU.EIP += 2;
}

void exec3C() {	// 3Ch CMP AL, IMM8
	cpuf8_1(CPU.AL - mmfu8_i);
	CPU.EIP += 2;
}

void exec3D() {	// 3Dh CMP AX, IMM16
	cpuf16_1(CPU.AX - mmfu16_i);
	CPU.EIP += 3;
}

void exec3E() {	// 3Eh DS:
	CPU.Segment = SEG_DS;
	++CPU.EIP;
}

void exec3F() {	// 3Fh AAS
	if (((CPU.AL & 0xF) > 9) || CPU.AF) {
		CPU.AX -= 6;
		CPU.AH -= 1;
		CPU.AF = CPU.CF = 1;
	} else {
		CPU.AF = CPU.CF = 0;
	}
	CPU.AL &= 0xF;
	++CPU.EIP;
}

void exec40() {	// 40h INC AX
	const int r = CPU.AX + 1;
	cpuf16_2(r);
	CPU.AX = cast(ubyte)r;
	++CPU.EIP;
}

void exec41() {	// 41h INC CX
	const int r = CPU.CX + 1;
	cpuf16_2(r);
	CPU.CX = cast(ushort)r;
	++CPU.EIP;
}

void exec42() {	// 42h INC DX
	const int r = CPU.DX + 1;
	cpuf16_2(r);
	CPU.DX = cast(ushort)r;
	++CPU.EIP;
}

void exec43() {	// 43h INC BX
	const int r = CPU.BX + 1;
	cpuf16_2(r);
	CPU.BX = cast(ushort)r;
	++CPU.EIP;
}

void exec44() {	// 44h INC SP
	const int r = CPU.SP + 1;
	cpuf16_2(r);
	CPU.SP = cast(ushort)r;
	++CPU.EIP;
}

void exec45() {	// 45h INC BP
	const int r = CPU.BP + 1;
	cpuf16_2(r);
	CPU.BP = cast(ushort)r;
	++CPU.EIP;
}

void exec46() {	// 46h INC SI
	const int r = CPU.SI + 1;
	cpuf16_2(r);
	CPU.SI = cast(ushort)r;
	++CPU.EIP;
}

void exec47() {	// 47h INC DI
	const int r = CPU.DI + 1;
	cpuf16_2(r);
	CPU.DI = cast(ushort)r;
	++CPU.EIP;
}

void exec48() {	// 48h DEC AX
	const int r = CPU.AX - 1;
	cpuf16_2(r);
	CPU.AX = cast(ushort)r;
	++CPU.EIP;
}

void exec49() {	// 49h DEC CX
	const int r = CPU.CX - 1;
	cpuf16_2(r);
	CPU.CX = cast(ushort)r;
	++CPU.EIP;
}

void exec4A() {	// 4Ah DEC DX
	const int r = CPU.DX - 1;
	cpuf16_2(r);
	CPU.DX = cast(ushort)r;
	++CPU.EIP;
}

void exec4B() {	// 4Bh DEC BX
	const int r = CPU.BX - 1;
	cpuf16_2(r);
	CPU.BX = cast(ushort)r;
	++CPU.EIP;
}

void exec4C() {	// 4Ch DEC SP
	const int r = CPU.SP - 1;
	cpuf16_2(r);
	CPU.SP = cast(ushort)r;
	++CPU.EIP;
}

void exec4D() {	// 4Dh DEC BP
	const int r = CPU.BP - 1;
	cpuf16_2(r);
	CPU.BP = cast(ushort)r;
	++CPU.EIP;
}

void exec4E() {	// 4Eh DEC SI
	const int r = CPU.SI - 1;
	cpuf16_2(r);
	CPU.SI = cast(ushort)r;
	++CPU.EIP;
}

void exec4F() {	// 4Fh DEC DI
	const int r = CPU.DI - 1;
	cpuf16_2(r);
	CPU.DI = cast(ushort)r;
	++CPU.EIP;
}

void exec50() {	// 50h PUSH AX
	CPU.push16(CPU.AX);
	++CPU.EIP;
}

void exec51() {	// 51h PUSH CX
	CPU.push16(CPU.CX);
	++CPU.EIP;
}

void exec52() {	// 52h PUSH DX
	CPU.push16(CPU.DX);
	++CPU.EIP;
}

void exec53() {	// 53h PUSH BX
	CPU.push16(CPU.BX);
	++CPU.EIP;
}

void exec54() {	// 54h PUSH SP
	CPU.push16(CPU.SP);
	++CPU.EIP;
}

void exec55() {	// 55h PUSH BP
	CPU.push16(CPU.BP);
	++CPU.EIP;
}

void exec56() {	// 56h PUSH SI
	CPU.push16(CPU.SI);
	++CPU.EIP;
}

void exec57() {	// 57h PUSH DI
	CPU.push16(CPU.DI);
	++CPU.EIP;
}

void exec58() {	// 58h POP AX
	CPU.AX = CPU.pop16;
	++CPU.EIP;
}

void exec59() {	// 59h POP CX
	CPU.CX = CPU.pop16;
	++CPU.EIP;
}

void exec5A() {	// 5Ah POP DX
	CPU.DX = CPU.pop16;
	++CPU.EIP;
}

void exec5B() {	// 5Bh POP BX
	CPU.BX = CPU.pop16;
	++CPU.EIP;
}

void exec5C() {	// 5Ch POP SP
	CPU.SP = CPU.pop16;
	++CPU.EIP;
}

void exec5D() {	// 5Dh POP BP
	CPU.BP = CPU.pop16;
	++CPU.EIP;
}

void exec5E() {	// 5Eh POP SI
	CPU.SI = CPU.pop16;
	++CPU.EIP;
}

void exec5F() {	// 5Fh POP DI
	CPU.DI = CPU.pop16;
	++CPU.EIP;
}

void exec66() {	// 66h OPERAND OVERRIDE
	CPU.Prefix_Operand = 0x66;
	++CPU.EIP;
}

void exec67() {	// 67h ADDRESS OVERRIDE
	CPU.Prefix_Address = 0x67;
	++CPU.EIP;
}

void exec70() {	// 70h JO SHORT-LABEL
	CPU.EIP += CPU.OF ? mmfi8_i + 2 : 2;
}

void exec71() {	// 71h JNO SHORT-LABEL
	CPU.EIP += CPU.OF ? 2 : mmfi8_i + 2;
}

void exec72() {	// 72h JB/JNAE/JC SHORT-LABEL
	CPU.EIP += CPU.CF ? mmfi8_i + 2 : 2;
}

void exec73() {	// 73h JNB/JAE/JNC SHORT-LABEL
	CPU.EIP += CPU.CF ? 2 : mmfi8_i + 2;
}

void exec74() {	// 74h JE/NZ SHORT-LABEL
	CPU.EIP += CPU.ZF ? mmfi8_i + 2 : 2;
}

void exec75() {	// 75h JNE/JNZ SHORT-LABEL
	CPU.EIP += CPU.ZF ? 2 : mmfi8_i + 2;
}

void exec76() {	// 76h JBE/JNA SHORT-LABEL
	CPU.EIP += (CPU.CF || CPU.ZF) ? mmfi8_i + 2 : 2;
}

void exec77() {	// 77h JNBE/JA SHORT-LABEL
	CPU.EIP += CPU.CF == 0 && CPU.ZF == 0 ? mmfi8_i + 2 : 2;
}

void exec78() {	// 78h JS SHORT-LABEL
	CPU.EIP += CPU.SF ? mmfi8_i + 2 : 2;
}

void exec79() {	// 79h JNS SHORT-LABEL
	CPU.EIP += CPU.SF ? 2 : mmfi8_i + 2;
}

void exec7A() {	// 7Ah JP/JPE SHORT-LABEL
	CPU.EIP += CPU.PF ? mmfi8_i + 2 : 2;
}

void exec7B() {	// 7Bh JNP/JPO SHORT-LABEL
	CPU.EIP += CPU.PF ? 2 : mmfi8_i + 2;
}

void exec7C() {	// 7Ch JL/JNGE SHORT-LABEL
	CPU.EIP += CPU.SF != CPU.OF ? mmfi8_i + 2 : 2;
}

void exec7D() {	// 7Dh JNL/JGE SHORT-LABEL
	CPU.EIP += CPU.SF == CPU.OF ? mmfi8_i + 2 : 2;
}

void exec7E() {	// 7Eh JLE/JNG SHORT-LABEL
	CPU.EIP += CPU.SF != CPU.OF || CPU.ZF ? mmfi8_i + 2 : 2;
}

void exec7F() {	// 7Fh JNLE/JG SHORT-LABEL
	CPU.EIP += CPU.SF == CPU.OF && CPU.ZF == 0 ? mmfi8_i + 2 : 2;
}

void exec80() {	// 80h GRP1 R/M8, IMM8
	const ubyte rm = mmfu8_i; // Get ModR/M byte
	const ushort im = mmfu8_i(1);
	const int addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) { // REG
	case RM_REG_000: // 000 - ADD
		r += im; mmiu16(r, addr); break;
	case RM_REG_001: // 001 - OR
		r |= im; mmiu16(r, addr); break;
	case RM_REG_010: // 010 - ADC
		r += im; if (CPU.CF) ++r; mmiu16(r, addr); break;
	case RM_REG_011: // 011 - SBB
		r -= im; if (CPU.CF) --r; mmiu16(r, addr); break;
	case RM_REG_100: // 100 - AND
		r &= im; mmiu16(r, addr); break;
	case RM_REG_101: // 101 - SUB
		r -= im; mmiu16(r, addr); break;
	case RM_REG_110: // 110 - XOR
		r ^= im; mmiu16(r, addr); break;
	case RM_REG_111: // 111 - CMP
		r -= im; break;
	default:
		log_info("Invalid ModR/M from GRP1_8");
		execill;
	}
	cpuf8_1(r);
	CPU.EIP += 3;
}

void exec81() {	// 81h GRP1 R/M16, IMM16
	const ubyte rm = mmfu8_i; // Get ModR/M byte
	const ushort im = mmfu16_i(1);
	const int addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) { // REG
	case RM_REG_000: // 000 - ADD
		r += im; mmiu16(r, addr); break;
	case RM_REG_001: // 001 - OR
		r |= im; mmiu16(r, addr); break;
	case RM_REG_010: // 010 - ADC
		r += im; if (CPU.CF) ++r; mmiu16(r, addr); break;
	case RM_REG_011: // 011 - SBB
		r -= im; if (CPU.CF) --r; mmiu16(r, addr); break;
	case RM_REG_100: // 100 - AND
		r &= im; mmiu16(r, addr); break;
	case RM_REG_101: // 101 - SUB
		r -= im; mmiu16(r, addr); break;
	case RM_REG_110: // 110 - XOR
		r ^= im; mmiu16(r, addr); break;
	case RM_REG_111: // 111 - CMP
		r -= im; break;
	default:
		log_info("Invalid ModR/M from GRP1_16");
		execill;
	}
	cpuf16_1(r);
	CPU.EIP += 4;
}

void exec82() {	// 82h GRP2 R/M8, IMM8
	const ubyte rm = mmfu8_i; // Get ModR/M byte
	const ushort im = mmfu8_i(1);
	const int addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) { // ModRM REG
	case RM_REG_000: // 000 - ADD
		r += im; mmiu8(r, addr); break;
	case RM_REG_010: // 010 - ADC
		r += im; if (CPU.CF) ++r; mmiu8(r, addr); break;
	case RM_REG_011: // 011 - SBB
		r -= im; if (CPU.CF) --r; mmiu8(r, addr); break;
	case RM_REG_101: // 101 - SUB
		r -= im; mmiu8(r, addr); break;
	case RM_REG_111: // 111 - CMP
		r -= im; break;
	default:
		log_info("Invalid ModR/M for GRP2_8");
		execill;
	}
	cpuf8_1(r);
	CPU.EIP += 3;
}

void exec83() {	// 83h GRP2 R/M16, IMM8
	const ubyte rm = mmfu8_i; // Get ModR/M byte
	const ushort im = mmfu8_i(1);
	const int addr = mmrm16(rm, 1);
	int r = mmfu8(addr);
	switch (rm & RM_REG) { // ModRM REG
	case RM_REG_000: // 000 - ADD
		r += im; mmiu16(r, addr); break;
	case RM_REG_010: // 010 - ADC
		r += im; if (CPU.CF) ++r; mmiu16(r, addr);
		break;
	case RM_REG_011: // 011 - SBB
		r -= im; if (CPU.CF) --r; mmiu16(r, addr);
		break;
	case RM_REG_101: // 101 - SUB
		r -= im; mmiu16(r, addr); break;
	case RM_REG_111: // 111 - CMP
		r -= im; break;
	default:
		log_info("Invalid ModR/M for GRP2_16");
		execill;
	}
	cpuf16_1(r);
	CPU.EIP += 3;
}

void exec84() {	// 84h TEST R/M8, REG8
	const ubyte rm = mmfu8_i;
	const int n = mmfu8(mmrm16(rm));
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
	cpuf8_3(r);
	CPU.EIP += 2;
}

void exec85() {	// 85h TEST R/M16, REG16
	const ubyte rm = mmfu8_i;
	const int n = mmfu16(mmrm16(rm, 1));
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
	cpuf16_3(r);
	CPU.EIP += 2;
}

void exec86() {	// 86h XCHG REG8, R/M8
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm);
	const ubyte s = mmfu8(addr);
	// temp <- REG
	// REG  <- MEM
	// MEM  <- temp
	ubyte r = void;
	switch (rm & RM_REG) {
	case RM_REG_000: r = CPU.AL; CPU.AL = s; break;
	case RM_REG_001: r = CPU.CL; CPU.CL = s; break;
	case RM_REG_010: r = CPU.DL; CPU.DL = s; break;
	case RM_REG_011: r = CPU.BL; CPU.BL = s; break;
	case RM_REG_100: r = CPU.AH; CPU.AH = s; break;
	case RM_REG_101: r = CPU.CH; CPU.CH = s; break;
	case RM_REG_110: r = CPU.DH; CPU.DH = s; break;
	case RM_REG_111: r = CPU.BH; CPU.BH = s; break;
	default:
	}
	mmiu8(r, addr);
	CPU.EIP += 2;
}

void exec87() {	// 87h XCHG REG16, R/M16
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
	const ushort s = mmfu16(addr);
	// temp <- REG
	// REG  <- MEM
	// MEM  <- temp
	ushort r = void;
	switch (rm & RM_REG) {
	case RM_REG_000: r = CPU.AX; CPU.AX = s; break;
	case RM_REG_001: r = CPU.CX; CPU.CX = s; break;
	case RM_REG_010: r = CPU.DX; CPU.DX = s; break;
	case RM_REG_011: r = CPU.BX; CPU.BX = s; break;
	case RM_REG_100: r = CPU.SP; CPU.SP = s; break;
	case RM_REG_101: r = CPU.BP; CPU.BP = s; break;
	case RM_REG_110: r = CPU.SI; CPU.SI = s; break;
	case RM_REG_111: r = CPU.DI; CPU.DI = s; break;
	default:
	}
	mmiu16(r, addr);
	CPU.EIP += 2;
}

void exec88() {	// 88h MOV R/M8, REG8
	const ubyte rm = mmfu8_i;
	int addr = mmrm16(rm);
	switch (rm & RM_REG) {
	case RM_REG_000: mmiu8(CPU.AL, addr); break;
	case RM_REG_001: mmiu8(CPU.CL, addr); break;
	case RM_REG_010: mmiu8(CPU.DL, addr); break;
	case RM_REG_011: mmiu8(CPU.BL, addr); break;
	case RM_REG_100: mmiu8(CPU.AH, addr); break;
	case RM_REG_101: mmiu8(CPU.CH, addr); break;
	case RM_REG_110: mmiu8(CPU.DH, addr); break;
	case RM_REG_111: mmiu8(CPU.BH, addr); break;
	default:
	}
	CPU.EIP += 2;
}

void exec89() {	// 89h MOV R/M16, REG16
	const ubyte rm = mmfu8_i;
	int addr = mmrm16(rm, 1);
	switch (rm & RM_REG) {
	case RM_REG_000: mmiu16(CPU.AX, addr); break;
	case RM_REG_001: mmiu16(CPU.CX, addr); break;
	case RM_REG_010: mmiu16(CPU.DX, addr); break;
	case RM_REG_011: mmiu16(CPU.BX, addr); break;
	case RM_REG_100: mmiu16(CPU.SP, addr); break;
	case RM_REG_101: mmiu16(CPU.BP, addr); break;
	case RM_REG_110: mmiu16(CPU.SI, addr); break;
	case RM_REG_111: mmiu16(CPU.DI, addr); break;
	default:
	}
	CPU.EIP += 2;
}

void exec8A() {	// 8Ah MOV REG8, R/M8
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm);
	const ubyte r = mmfu8(addr);
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
}

void exec8B() {	// 8Bh MOV REG16, R/M16
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
	const ushort r = mmfu16(addr);
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
}

void exec8C() {	// 8Ch MOV R/M16, SEGREG
	// MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
	const byte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
	switch (rm & RM_REG) { // if REG[3] is clear, trip to default
	case RM_REG_100: mmiu16(CPU.ES, addr); break;
	case RM_REG_101: mmiu16(CPU.CS, addr); break;
	case RM_REG_110: mmiu16(CPU.SS, addr); break;
	case RM_REG_111: mmiu16(CPU.DS, addr); break;
	default: // when bit 6 is clear (REG[3])
		log_info("Invalid ModR/M for SEGREG->RM");
		execill;
	}
	CPU.EIP += 2;
}

void exec8D() {	// 8Dh LEA REG16, MEM16
	const ubyte rm = mmfu8_i;
	const ushort addr = cast(ushort)mmrm16(rm, 1);
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
}

void exec8E() {	// 8Eh MOV SEGREG, R/M16
	// MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
	const byte rm = mmfu8_i;
	const ushort addr = mmfu16(mmrm16(rm, 1));
	switch (rm & RM_REG) {
	case RM_REG_100: CPU.ES = addr; break;
	case RM_REG_101: CPU.CS = addr; break;
	case RM_REG_110: CPU.SS = addr; break;
	case RM_REG_111: CPU.DS = addr; break;
	default: // when bit 5 is clear (REG[3])
		log_info("Invalid ModR/M for SEGREG<-RM");
		execill;
	}
	CPU.EIP += 2;
}

void exec8F() {	// 8Fh POP R/M16
	const ubyte rm = mmfu8_i;
	if (rm & RM_REG) { // REG must be 000
		log_info("Invalid ModR/M for POP R/M16");
		execill;
	}
	mmiu16(CPU.pop16, mmrm16(rm, 1));
	CPU.EIP += 2;
}

void exec90() {	// 90h NOP (aka XCHG AX, AX)
	++CPU.EIP;
}

void exec91() {	// 91h XCHG AX, CX
	const ushort r = CPU.AX;
	CPU.AX = CPU.CX;
	CPU.CX = r;
	++CPU.EIP;
}

void exec92() {	// 92h XCHG AX, DX
	const ushort r = CPU.AX;
	CPU.AX = CPU.DX;
	CPU.DX = r;
	++CPU.EIP;
}

void exec93() {	// 93h XCHG AX, BX
	const ushort r = CPU.AX;
	CPU.AX = CPU.BX;
	CPU.BX = r;
	++CPU.EIP;
}

void exec94() {	// 94h XCHG AX, SP
	const ushort r = CPU.AX;
	CPU.AX = CPU.SP;
	CPU.SP = r;
	++CPU.EIP;
}

void exec95() {	// 95h XCHG AX, BP
	const ushort r = CPU.AX;
	CPU.AX = CPU.BP;
	CPU.BP = r;
	++CPU.EIP;
}

void exec96() {	// 96h XCHG AX, SI
	const ushort r = CPU.AX;
	CPU.AX = CPU.SI;
	CPU.SI = r;
	++CPU.EIP;
}

void exec97() {	// 97h XCHG AX, DI
	const ushort r = CPU.AX;
	CPU.AX = CPU.DI;
	CPU.DI = r;
	++CPU.EIP;
}

void exec98() {	// 98h CBW
	CPU.AH = CPU.AL & 0x80 ? 0xFF : 0;
	++CPU.EIP;
}

void exec99() {	// 99h CWD
	CPU.DX = CPU.AX & 0x8000 ? 0xFFFF : 0;
	++CPU.EIP;
}

void exec9A() {	// 9Ah CALL FAR_PROC
	CPU.push16(CPU.CS);
	CPU.push16(CPU.IP);
	CPU.CS = mmfu16_i;
	CPU.IP = mmfu16_i(2);
}

void exec9B() {	// 9Bh WAIT
	CPU.wait;
	++CPU.EIP;
}

void exec9C() {	// 9Ch PUSHF
	CPU.push16(CPU.FLAGS);
	++CPU.EIP;
}

void exec9D() {	// 9Dh POPF
	CPU.FLAGS = CPU.pop16;
	++CPU.EIP;
}

void exec9E() {	// 9Eh SAHF (Save AH to Flags)
	CPU.FLAG = CPU.AH;
	++CPU.EIP;
}

void exec9F() {	// 9Fh LAHF (Load AH from Flags)
	CPU.AH = CPU.FLAG;
	++CPU.EIP;
}

void execA0() {	// A0h MOV AL, MEM8
	CPU.AL = mmfu8(mmfu16_i);
	CPU.EIP += 2;
}

void execA1() {	// A1h MOV AX, MEM16
	CPU.AX = mmfu16(mmfu16_i);
	CPU.EIP += 3;
}

void execA2() {	// A2h MOV MEM8, AL
	mmiu8(CPU.AL, mmfu16_i);
	CPU.EIP += 2;
}

void execA3() {	// A3h MOV MEM16, AX
	mmiu16(CPU.AX, mmfu16_i);
	CPU.EIP += 3;
}

void execA4() {	// A4h MOVS DEST-STR8, SRC-STR8
	mmiu8(mmfu8(address(CPU.getseg, CPU.SI)),
		address(CPU.ES, CPU.DI));
	if (CPU.DF) {
		--CPU.SI;
		--CPU.DI;
	} else {
		++CPU.SI;
		++CPU.DI;
	}
	++CPU.EIP;
}

void execA5() {	// A5h MOVS DEST-STR16, SRC-STR16
	mmiu16(mmfu16(address(CPU.getseg, CPU.SI)),
		address(CPU.ES, CPU.DI));
	if (CPU.DF) {
		--CPU.SI;
		--CPU.DI;
	} else {
		++CPU.SI;
		++CPU.DI;
	}
	++CPU.EIP;
}

void execA6() {	// A6h CMPS DEST-STR8, SRC-STR8
	cpuf8_1(
		mmfu8(address(CPU.DS, CPU.SI)) -
		mmfu8(address(CPU.ES, CPU.DI))
	);
	if (CPU.DF) {
		--CPU.DI;
		--CPU.SI;
	} else {
		++CPU.DI;
		++CPU.SI;
	}
	++CPU.EIP;
}

void execA7() {	// A7h CMPSW DEST-STR16, SRC-STR16
	cpuf16_1(
		mmfu16(address(CPU.DS, CPU.SI)) -
		mmfu16(address(CPU.ES, CPU.DI))
	);
	if (CPU.DF) {
		CPU.DI -= 2;
		CPU.SI -= 2;
	} else {
		CPU.DI += 2;
		CPU.SI += 2;
	}
	++CPU.EIP;
}

void execA8() {	// A8h TEST AL, IMM8
	cpuf8_3(CPU.AL & mmfu8_i);
	CPU.EIP += 2;
}

void execA9() {	// A9h TEST AX, IMM16
	cpuf16_3(CPU.AX & mmfu16_i);
	CPU.EIP += 3;
}

void execAA() {	// AAh STOS DEST-STR8
	mmiu8(CPU.AL, address(CPU.ES, CPU.DI));
	if (CPU.DF) --CPU.DI; else ++CPU.DI;
	++CPU.EIP;
}

void execAB() {	// ABh STOS DEST-STR16
	mmiu16(CPU.AX, address(CPU.ES, CPU.DI));
	if (CPU.DF) CPU.DI -= 2; else CPU.DI += 2;
	++CPU.EIP;
}

void execAC() {	// ACh LODS SRC-STR8
	CPU.AL = mmfu8(address(CPU.DS, CPU.SI));
	if (CPU.DF) --CPU.SI; else ++CPU.SI;
	++CPU.EIP;
}

void execAD() {	// ADh LODS SRC-STR16
	CPU.AX = mmfu16(address(CPU.DS, CPU.SI));
	if (CPU.DF) CPU.SI -= 2; else CPU.SI += 2;
	++CPU.EIP;
}

void execAE() {	// AEh SCAS DEST-STR8
	cpuf8_1(CPU.AL - mmfu8(address(CPU.ES, CPU.DI)));
	if (CPU.DF) --CPU.DI; else ++CPU.DI;
	++CPU.EIP;
}

void execAF() {	// AFh SCAS DEST-STR16
	cpuf16_1(CPU.AX - mmfu16(address(CPU.ES, CPU.DI)));
	if (CPU.DF) CPU.DI -= 2; else CPU.DI += 2;
	++CPU.EIP;
}

void execB0() {	// B0h MOV AL, IMM8
	CPU.AL = mmfu8_i;
	CPU.EIP += 2;
}

void execB1() {	// B1h MOV CL, IMM8
	CPU.CL = mmfu8_i;
	CPU.EIP += 2;
}

void execB2() {	// B2h MOV DL, IMM8
	CPU.DL = mmfu8_i;
	CPU.EIP += 2;
}

void execB3() {	// B3h MOV BL, IMM8
	CPU.BL = mmfu8_i;
	CPU.EIP += 2;
}

void execB4() {	// B4h MOV AH, IMM8
	CPU.AH = mmfu8_i;
	CPU.EIP += 2;
}

void execB5() {	// B5h MOV CH, IMM8
	CPU.CH = mmfu8_i;
	CPU.EIP += 2;
}

void execB6() {	// B6h MOV DH, IMM8  
	CPU.DH = mmfu8_i;
	CPU.EIP += 2;
}

void execB7() {	// B7h MOV BH, IMM8
	CPU.BH = mmfu8_i;
	CPU.EIP += 2;
}

void execB8() {	// B8h MOV AX, IMM16
	CPU.AX = mmfu16_i;
	CPU.EIP += 3;
}

void execB9() {	// B9h MOV CX, IMM16
	CPU.CX = mmfu16_i;
	CPU.EIP += 3;
}

void execBA() {	// BAh MOV DX, IMM16
	CPU.DX = mmfu16_i;
	CPU.EIP += 3;
}

void execBB() {	// BBh MOV BX, IMM16
	CPU.BX = mmfu16_i;
	CPU.EIP += 3;
}

void execBC() {	// BCh MOV SP, IMM16
	CPU.SP = mmfu16_i;
	CPU.EIP += 3;
}

void execBD() {	// BDh MOV BP, IMM16
	CPU.BP = mmfu16_i;
	CPU.EIP += 3;
}

void execBE() {	// BEh MOV SI, IMM16
	CPU.SI = mmfu16_i;
	CPU.EIP += 3;
}

void execBF() {	// BFh MOV DI, IMM16
	CPU.DI = mmfu16_i;
	CPU.EIP += 3;
}

void execC2() {	// C2 RET IMM16 (NEAR)
	const ushort sp = mmfi16_i;
	CPU.IP = CPU.pop16;
	CPU.SP += sp;
}

void execC3() {	// C3h RET (NEAR)
	CPU.IP = CPU.pop16;
}

void execC4() {	// C4h LES REG16, MEM16
	const ubyte rm = mmfu8_i;
	const ushort r = mmfu16(mmrm16(rm, 1));
	CPU.Segment = SEG_ES;
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
}

void execC5() {	// C5h LDS REG16, MEM16
	const ubyte rm = mmfu8_i;
	const ushort r = mmfu16(mmrm16(rm, 1));
	CPU.Segment = SEG_DS;
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
}

void execC6() {	// C6h MOV MEM8, IMM8
	const ubyte rm = mmfu8_i;
	if (rm & RM_REG) { // No register operation allowed
		log_info("Invalid ModR/M for MOV MEM8");
		execill;
	}
	mmiu8(mmfu8_i(1), mmrm16(rm));
}

void execC7() {	// C7h MOV MEM16, IMM16
	const ubyte rm = mmfu8_i;
	if (rm & RM_REG) { // No register operation allowed
		log_info("Invalid ModR/M for MOV MEM16");
		execill;
	}
	mmiu16(mmfu16_i(1), mmrm16(rm, 1));
}

void execCA() {	// CAh RET IMM16 (FAR)
	const uint addr = CPU.EIP + 1;
	CPU.IP = CPU.pop16;
	CPU.CS = CPU.pop16;
	CPU.SP += mmfi16(addr);
}

void execCB() {	// CBh RET (FAR)
	CPU.IP = CPU.pop16;
	CPU.CS = CPU.pop16;
}

void execCC() {	// CCh INT 3
	INT(3);
	++CPU.EIP;
}

void execCD() {	// CDh INT IMM8
	INT(mmfu8_i);
	CPU.EIP += 2;
}

void execCE() {	// CEh INTO
	if (CPU.CF) INT(4);
	++CPU.EIP;
}

void execCF() {	// CFh IRET
	CPU.IP = CPU.pop16;
	CPU.CS = CPU.pop16;
	CPU.FLAGS = CPU.pop16;
	++CPU.EIP;
}

void execD0() {	// D0h GRP2 R/M8, 1
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - ROL
		r <<= 1;
		if (r & 0x100) {
			r |= 1; CPU.OF = 1;
		}
		break;
	case RM_REG_001: // 001 - ROR
		if (r & 1) {
			r |= 0x100; CPU.OF = 1;
		}
		r >>= 1;
		break;
	case RM_REG_010: // 010 - RCL
		r <<= 1;
		if (r & 0x200) {
			r |= 1; CPU.OF = 1;
		}
		break;
	case RM_REG_011: // 011 - RCR
		if (r & 1) {
			r |= 0x200; CPU.OF = 1;
		}
		r >>= 1;
		break;
	case RM_REG_100: // 100 - SAL/SHL
		r <<= 1;
		cpuf8_1(r);
		break;
	case RM_REG_101: // 101 - SHR
		r >>= 1;
		cpuf8_1(r);
		break;
	case RM_REG_111: // 111 - SAR
		if (r & 0x80) r |= 0x100;
		r >>= 1;
		cpuf8_1(r);
		break;
	default: // 110
		log_info("Invalid ModR/M for GRP2 R/M8, 1");
		execill;
	}
	mmiu8(r, addr);
	CPU.EIP += 2;
}

void execD1() {	// D1h GRP2 R/M16, 1
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - ROL
		r <<= 1;
		if (r & 0x1_0000) {
			r |= 1; CPU.OF = 1;
		}
		break;
	case RM_REG_001: // 001 - ROR
		if (r & 1) {
			r |= 0x1_0000; CPU.OF = 1;
		}
		r >>= 1;
		break;
	case RM_REG_010: // 010 - RCL
		r <<= 1;
		if (r & 0x2_0000) {
			r |= 1; CPU.OF = 1;
		}
		break;
	case RM_REG_011: // 011 - RCR
		if (r & 1) {
			r |= 0x2_0000; CPU.OF = 1;
		}
		r >>= 1;
		break;
	case RM_REG_100: // 100 - SAL/SHL
		r <<= 1;
		cpuf16_1(r);
		break;
	case RM_REG_101: // 101 - SHR
		r >>= 1;
		cpuf16_1(r);
		break;
	case RM_REG_111: // 111 - SAR
		if (r & 0x8000) r |= 0x1_0000;
		r >>= 1;
		cpuf16_1(r);
		break;
	default: // 110
		log_info("Invalid ModR/M for GRP2 R/M16, 1");
		execill;
	}
	mmiu16(r, addr);
	CPU.EIP += 2;
}

void execD2() {	// D2h GRP2 R/M8, CL
	const ubyte rm = mmfu8_i;
	int c = CPU.CL;	/// Count
	if (CPU.Model != CPU_8086) // vm8086 still falls here
		c &= 31; // 5 bits

	CPU.EIP += 2;
	if (c == 0) return; // NOP IF COUNT = 0

	const int addr = mmrm16(rm);
	__mi32 r = cast(__mi32)mmfu8(addr);

	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - ROL
		r <<= c;
		if (r > 0xFF) {
			r |= r.u8[1]; CPU.OF = 1;
		}
		break;
	case RM_REG_001: // 001 - ROR
		r.u8[1] = r.u8[0];
		r >>= c;
		if (r.u8[1] == 0) { //TODO: Check accuracy
			CPU.OF = 1;
		}
		break;
	case RM_REG_010: //TODO: 010 - RCL
		break;
	case RM_REG_011: //TODO: 011 - RCR
		break;
	case RM_REG_100: // 100 - SAL/SHL
		break;
	case RM_REG_101: // 101 - SHR
		break;
	case RM_REG_111: // 111 - SAR
		break;
	default:
		log_info("Invalid ModR/M for GRP2 R/M8, CL");
		execill;
	}
	mmiu8(r, addr);
}

void execD3() {	// D3h GRP2 R/M16, CL
	const ubyte rm = mmfu8_i;
	int c = CPU.CL;	/// Count
	if (CPU.Model != CPU_8086) // vm8086 still falls here
		c &= 31; // 5 bits

	CPU.EIP += 2;
	if (c == 0) return; // NOP IF COUNT = 0

	const int addr = mmrm16(rm, 1);
	__mi32 r = cast(__mi32)mmfu16(addr);

	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - ROL
		r <<= c;
		if (r > 0xFF) {
			r |= r.u16[1]; CPU.OF = 1;
		}
		break;
	case RM_REG_001: // 001 - ROR
		r.u16[1] = r.u16[0];
		r >>= c;
		if (r.u16[1] == 0) { //TODO: Check accuracy
			CPU.OF = 1;
		}
		break;
	case RM_REG_010: //TODO: 010 - RCL
		break;
	case RM_REG_011: //TODO: 011 - RCR
		break;
	case RM_REG_100: // 100 - SAL/SHL
		break;
	case RM_REG_101: // 101 - SHR
		break;
	case RM_REG_111: // 111 - SAR
		break;
	default:
		log_info("Invalid ModR/M for GRP2 R/M16, CL");
		execill;
	}
	mmiu16(r, addr);
}

void execD4() {	// D4h AAM
	const ubyte v = mmfu8_i;
	CPU.AH = cast(ubyte)(CPU.AL / v);
	CPU.AL = cast(ubyte)(CPU.AL % v);
	cpuf8_5(CPU.AL);
	CPU.EIP += 2;
}

void execD5() {	// D5h AAD
	const ubyte v = mmfu8_i;
	const int r = CPU.AL + (CPU.AH * v);
	cpuf8_5(r);
	CPU.AL = cast(ubyte)r;
	CPU.AH = 0;
	CPU.EIP += 2;
}

void execD7() {	// D7h XLAT SOURCE-TABLE
	CPU.AL = mmfu8(address(CPU.DS, CPU.BX) + cast(byte)CPU.AL);
	++CPU.EIP;
}

void execE0() {	// E0h LOOPNE/LOOPNZ SHORT-LABEL
	--CPU.CX;
	if (CPU.CX && CPU.ZF == 0) CPU.EIP += mmfi8_i;
	else CPU.EIP += 2;
}

void execE1() {	// E1h LOOPE/LOOPZ SHORT-LABEL
	--CPU.CX;
	if (CPU.CX && CPU.ZF) CPU.EIP += mmfi8_i;
	else CPU.EIP += 2;
}

void execE2() {	// E2h LOOP SHORT-LABEL
	CPU.EIP += --CPU.CX ? mmfi8_i : 2;
}

void execE3() {	// E3 JCXZ SHORT-LABEL
	CPU.EIP += CPU.CX ? 2 : mmfi8_i;
}

void execE4() {	// E4h IN AL, IMM8
	int r = void;
	io(IO_IN, mmfu8_i, IO_BYTE, &r);
	CPU.AL = cast(ubyte)r;
}

void execE5() {	// E5h IN AX, IMM8
	int r = void;
	io(IO_IN, mmfu8_i, IO_WORD, &r);
	CPU.AX = cast(ushort)r;
}

void execE6() {	// E6h OUT IMM8, AL
	int r = CPU.AL;
	io(IO_OUT, mmfu8_i, IO_BYTE, &r);
}

void execE7() {	// E7h OUT IMM8, AX
	int r = CPU.AX;
	io(IO_OUT, mmfu8_i, IO_WORD, &r);
}

void execE8() {	// E8h CALL NEAR-PROC
	CPU.push16(CPU.IP);
	CPU.EIP += mmfi16_i; // Direct within segment
}

void execE9() {	// E9h JMP NEAR-LABEL
	CPU.EIP += mmfi16_i + 3; // ±32 KB
}

void execEA() {	// EAh JMP FAR-LABEL
	// Any segment, any fragment, 5 byte instruction.
	// EAh (LO-CPU.IP) (HI-CPU.IP) (LO-CPU.CS) (HI-CPU.CS)
	const uint csip = mmfu32_i;
	CPU.IP = cast(ushort)csip;
	CPU.CS = csip >> 16;
}

void execEB() {	// EBh JMP SHORT-LABEL
	CPU.EIP += mmfi8_i + 2; // ±128 B
}

void execEC() {	// ECh IN AL, DX
	int r = void;
	io(IO_IN, CPU.DX, IO_BYTE, &r);
	CPU.AL = cast(ubyte)r;
}

void execED() {	// EDh IN AX, DX
	int r = void;
	io(IO_IN, CPU.DX, IO_WORD, &r);
	CPU.AX = cast(ushort)r;
}

void execEE() {	// EEh OUT AL, DX
	int r = CPU.AL;
	io(IO_IN, CPU.DX, IO_BYTE, &r);
}

void execEF() {	// EFh OUT AX, DX
	int r = CPU.AX;
	io(IO_IN, CPU.DX, IO_WORD, &r);
}

void execF0() {	// F0h LOCK (prefix)
	CPU.Lock = 1;
	++CPU.EIP;
}

void execF2() {	// F2h REPNE/REPNZ
	//TODO: Verify operation
	while (CPU.CX > 0) {
		execA6;
		--CPU.CX;
		if (CPU.ZF == 0) break;
	}
	++CPU.EIP;
}

void execF3() {	// F3h REP/REPE/REPNZ
	ushort c = CPU.CX;
	const ubyte op = mmfi8_i; // next op

	if (c == 0) {
		++CPU.EIP;
		return;
	}

	//TODO: Is there a better way?
	switch (op) { // None of these fetch from [E]IP
	case 0xa4:
		do { execA4(); --c; } while (c);
		break;
	case 0xa5:
		do { execA5(); --c; } while (c);
		break;
	case 0xa6:
		do { execA6(); --c; } while (c && CPU.ZF);
		break;
	case 0xa7:
		do { execA7(); --c; } while (c && CPU.ZF);
		break;
	case 0xaa:
		do { execAA(); --c; } while (c);
		break;
	case 0xab:
		do { execAB(); --c; } while (c);
		break;
	case 0xac:
		do { execAC(); --c; } while (c);
		break;
	case 0xad:
		do { execAD(); --c; } while (c);
		break;
	case 0xae:
		do { execAE(); --c; } while (c && CPU.ZF);
		break;
	case 0xaf:
		do { execAF(); --c; } while (c && CPU.ZF);
		break;
	default:
//		++CPU.EIP;
		execill;
		return;
	}
	CPU.CX = c;
	CPU.Segment = SEG_NONE;
/*	if (c) {
		if (CPU.ZF && ((op & 6) != 6))
			// TODO: IP gets "previous IP"
	}*/
	CPU.EIP -= (c - 1);
}

void execF4() {	// F4h HLT
	CPU.level = 0;
	++CPU.EIP;
}

void execF5() {	// F5h CMC
	CPU.CF = !CPU.CF;
	++CPU.EIP;
}

void execF6() {	// F6h GRP3 R/M8, IMM8
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm);
	const ubyte v = mmfu8(addr);
	int r = void;
	int ip = void;
	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - TEST
		cpuf8_3(v & mmfu8_i(1));
		ip = 3;
		break;
	case RM_REG_010: // 010 - NOT
		CPU.CF = v != 0;
		mmiu8(~v, addr);
		ip = 2;
		break;
	case RM_REG_011: // 011 - NEG
		CPU.CF = v != 0;
		r = cast(ubyte)-v;
		OF8(r); SF8(r); ZF16(r); PF8(r);
		mmiu8(r, addr);
		ip = 2;
		break;
	case RM_REG_100: // 100 - MUL
		CPU.AX = cast(ushort)(CPU.AL * v);
		CPU.CF = CPU.OF = CPU.AH;
		ip = 2;
		break;
	case RM_REG_101: // 101 - IMUL
		CPU.AX = cast(ushort)(CPU.AL * cast(byte)v);
		CPU.CF = CPU.OF = CPU.AH;
		ip = 2;
		break;
	case RM_REG_110: // 110 - DIV
		if (v == 0) INT(0);
		CPU.AL = cast(ubyte)(CPU.AL / v);
		CPU.AH = cast(ubyte)(CPU.AL % v);
		ip = 2;
		break;
	case RM_REG_111: // 111 - IDIV
		if (v == 0) INT(0);
		CPU.AL = cast(ubyte)(CPU.AX / cast(byte)v);
		CPU.AH = cast(ubyte)(CPU.AX % cast(byte)v);
		ip = 2;
		break;
	default:
		log_info("Invalid ModR/M on GRP3_8");
		execill;
	}
	CPU.EIP += ip;
}

void execF7() {	// F7h GRP3 R/M16, IMM16
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
	const ushort v = mmfu16(addr);
	int r = void;
	int ip = void;
	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - TEST
		cpuf16_3(v & mmfu16_i(1));
		ip = 4;
		break;
	case RM_REG_010: // 010 - NOT
		CPU.CF = v != 0;
		mmiu16(~v, addr);
		ip = 2;
		break;
	case RM_REG_011: // 011 - NEG
		CPU.CF = v != 0;
		r = cast(ubyte)-v;
		OF16(r); SF16(r); ZF16(r); PF16(r);
		mmiu16(r, addr);
		ip = 2;
		break;
	case RM_REG_100: // 100 - MUL
		__mi32 d = cast(__mi32)(CPU.AX * v);
		CPU.DX = d.u16[1];
		CPU.AX = d.u16[0];
		CPU.CF = CPU.OF = CPU.DX != 0;
		ip = 2;
		break;
	case RM_REG_101: // 101 - IMUL
		__mi32 d = cast(__mi32)(CPU.AX * cast(short)v);
		CPU.DX = d.u16[1];
		CPU.AX = d.u16[0];
		CPU.CF = CPU.OF = CPU.DX != 0;
		ip = 2;
		break;
	case RM_REG_110: // 110 - DIV
		if (v == 0) INT(0);
		__mi32 d = void;
		d.u16[1] = CPU.DX; d.u16[0] = CPU.AX;
		CPU.AX = cast(ushort)(d / v);
		CPU.DX = cast(ushort)(d % v);
		ip = 2;
		break;
	case RM_REG_111: // 111 - IDIV
		if (v == 0) INT(0);
		__mi32 d = void;
		d.u16[1] = CPU.DX; d.u16[0] = CPU.AX;
		CPU.AX = cast(ushort)(d / cast(short)v);
		CPU.DX = cast(ushort)(d % cast(short)v);
		ip = 2;
		break;
	default:
		log_info("Invalid ModR/M on GRP3_8");
		execill;
	}
	CPU.EIP += ip;
}

void execF8() {	// F8h CLC
	CPU.CF = 0;
	++CPU.EIP;
}

void execF9() {	// F9h STC
	CPU.CF = 1;
	++CPU.EIP;
}

void execFA() {	// FAh CLI
	CPU.IF = 0;
	++CPU.EIP;
}

void execFB() {	// FBh STI
	CPU.IF = 1;
	++CPU.EIP;
}

void execFC() {	// FCh CLD
	CPU.DF = 0;
	++CPU.EIP;
}

void execFD() {	// FDh STD
	CPU.DF = 1;
	++CPU.EIP;
}

void execFE() {	// FEh GRP4 R/M8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - INC
		++r;
		break;
	case RM_REG_001: // 001 - DEC
		--r;
		break;
	default:
		log_info("Invalid ModR/M on GRP4_8");
		execill;
	}
	mmiu16(r, addr);
	cpuf16_2(r);
	CPU.EIP += 2;
}

void execFF() {	// FFh GRP5 R/M16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - INC
		++r;
		cpuf16_2(r);
		mmiu16(r, addr);
		CPU.EIP += 2;
		return;
	case RM_REG_001: // 001 - DEC
		--r;
		cpuf16_2(r);
		mmiu16(r, addr);
		CPU.EIP += 2;
		return;
	case RM_REG_010: // 010 - CALL R/M16 (near) -- Indirect within segment
		CPU.push16(CPU.IP);
		CPU.IP = cast(ushort)r;
		return;
	case RM_REG_011: // 011 - CALL MEM16 (far) -- Indirect outside segment
		ushort nip = cast(ushort)address(mmfu16(addr + 2), r);
		CPU.push16(CPU.CS);
		CPU.push16(CPU.IP);
		CPU.IP = nip;
		return;
	case RM_REG_100: // 100 - JMP R/M16 (near) -- Indirect within segment
		CPU.IP = cast(ushort)(r + 2);
		return;
	case RM_REG_101: // 101 - JMP MEM16 (far) -- Indirect outside segment
		CPU.IP = cast(ushort)address(mmfu16(addr), r + 2);
		return;
	case RM_REG_110: // 110 - PUSH MEM16
		CPU.push16(mmfu16(address(mmfu16(addr + 2), r)));
		CPU.EIP += 2;
		return;
	default:
		log_info("Invalid ModR/M on GRP5_16");
		execill;
	}
}

void execill() {	// Illegal instruction
	INT(6);
}