/**
 * v16: Real-mode and v8086 instructions
 */
module vcpu.v16; // 8086

import vcpu.core, vcpu.v32, vcpu.mm, vcpu.utils;
import vdos.interrupts;
import logger;

extern (C):
nothrow:

/**
 * Execute an instruction in REAL mode
 * Params: op = opcode
 */
pragma(inline, true)
void exec16(ubyte op) {
	REAL_MAP[op]();
}

void v16_add_rm8_reg8() {	// 00h ADD R/M8, REG8
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

void v16_add_rm16_reg16() {	// 01h ADD R/M16, REG16
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

void v16_add_reg8_rm8() {	// 02h ADD REG8, R/M8
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

void v16_add_reg16_rm16() {	// 03h ADD REG16, R/M16
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

void v16_add_al_imm8() {	// 04h ADD AL, IMM8
	const int r = CPU.AL + mmfu8_i;
	cpuf8_1(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v16_add_ax_imm16() {	// 05h ADD AX, IMM16
	const int r = CPU.AX + mmfu16_i;
	cpuf16_1(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 2;
}

void v16_push_es() {	// 06h PUSH ES
	push16(CPU.ES);
	++CPU.EIP;
}

void v16_pop_es() {	// 07h POP ES
	CPU.ES = pop16;
	++CPU.EIP;
}

void v16_or_rm8_reg8() {	// 08h OR R/M8, REG8
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

void v16_or_rm16_reg16() {	// 09h OR R/M16, REG16
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

void v16_or_reg8_rm8() {	// 0Ah OR REG8, R/M8
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

void v16_or_reg16_rm16() {	// 0Bh OR REG16, R/M16
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

void v16_or_al_imm8() {	// 0Ch OR AL, IMM8
	const int r = CPU.AL | mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v16_or_ax_imm16() {	// 0Dh OR AX, IMM16
	const int r = CPU.AX | mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v16_push_cs() {	// 0Eh PUSH CS
	push16(CPU.CS);
	++CPU.EIP;
}

void v16_adc_rm8_reg8() {	// 10h ADC R/M8, REG8
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

void v16_adc_rm16_reg16() {	// 11h ADC R/M16, REG16
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

void v16_adc_reg8_rm8() {	// 12h ADC REG8, R/M8
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

void v16_adc_reg16_rm16() {	// 13h ADC REG16, R/M16
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

void v16_adc_al_imm8() {	// 14h ADC AL, IMM8
	int r = CPU.AL + mmfu8_i;
	cpuf8_1(r);
	if (CPU.CF) ++r;
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v16_adc_ax_imm16() {	// 15h ADC AX, IMM16
	int r = CPU.AX + mmfu16_i;
	cpuf16_1(r);
	if (CPU.CF) ++r;
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v16_push_ss() {	// 16h PUSH SS
	push16(CPU.SS);
	++CPU.EIP;
}

void v16_pop_ss() {	// 17h POP SS
	CPU.SS = pop16;
	++CPU.EIP;
}

void v16_sbb_rm8_reg8() {	// 18h SBB R/M8, REG8
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

void v16_sbb_rm16_reg16() {	// 19h SBB R/M16, REG16
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

void v16_sbb_reg8_rm8() {	// 1Ah SBB REG8, R/M8
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

void v16_sbb_reg16_rm16() {	// 1Bh SBB REG16, R/M16
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

void v16_sbb_al_imm8() {	// 1Ch SBB AL, IMM8
	int r = CPU.AL - mmfu8_i;
	if (CPU.CF) --r;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v16_sbb_ax_imm16() {	// 1Dh SBB AX, IMM16
	int r = CPU.AX - mmfu16_i;
	if (CPU.CF) --r;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v16_push_ds() {	// 1Eh PUSH DS
	push16(CPU.DS);
	++CPU.EIP;
}

void v16_pop_ds() {	// 1Fh POP DS
	CPU.DS = pop16;
	++CPU.EIP;
}

void v16_and_rm8_reg8() {	// 20h AND R/M8, REG8
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

void v16_and_rm16_reg16() {	// 21h AND R/M16, REG16
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

void v16_and_reg8_rm8() {	// 22h AND REG8, R/M8
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

void v16_and_reg16_rm16() {	// 23h AND REG16, R/M16
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

void v16_and_al_imm8() {	// 24h AND AL, IMM8
	const int r = CPU.AL & mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v16_and_ax_imm16() {	// 25h AND AX, IMM16
	const int r = CPU.AX & mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v16_es() {	// 26h ES: (Segment override prefix)
	CPU.Segment = SEG_ES;
	++CPU.EIP;
}

void v16_daa() {	// 27h DAA
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

void v16_sub_rm8_reg8() {	// 28h SUB R/M8, REG8
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

void v16_sub_rm16_reg16() {	// 29h SUB R/M16, REG16
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

void v16_sub_reg8_rm8() {	// 2Ah SUB REG8, R/M8
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

void v16_sub_reg16_rm16() {	// 2Bh SUB REG16, R/M16
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

void v16_sub_al_imm8() {	// 2Ch SUB AL, IMM8
	const int r = CPU.AL - mmfu8_i;
	cpuf8_1(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v16_sub_ax_imm16() {	// 2Dh SUB AX, IMM16
	const int r = CPU.AX - mmfu16_i;
	cpuf16_1(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v16_cs() {	// 2Eh CS:
	CPU.Segment = SEG_CS;
	++CPU.EIP;
}

void v16_das() {	// 2Fh DAS
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

void v16_xor_rm8_reg8() {	// 30h XOR R/M8, REG8
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

void v16_xor_rm16_reg16() {	// 31h XOR R/M16, REG16
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

void v16_xor_reg8_rm8() {	// 32h XOR REG8, R/M8
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

void v16_xor_reg16_rm16() {	// 33h XOR REG16, R/M16
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

void v16_xor_al_imm8() {	// 34h XOR AL, IMM8
	const int r = CPU.AL ^ mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v16_xor_ax_imm16() {	// 35h XOR AX, IMM16
	const int r = CPU.AX ^ mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v16_ss() {	// 36h SS:
	CPU.Segment = SEG_SS;
	++CPU.EIP;
}

void v16_aaa() {	// 37h AAA
	if (((CPU.AL & 0xF) > 9) || CPU.AF) {
		CPU.AX += 0x106;
		CPU.AF = CPU.CF = 1;
	} else CPU.AF = CPU.CF = 0;
	CPU.AL &= 0xF;
	++CPU.EIP;
}

void v16_cmp_rm8_reg8() {	// 38h CMP R/M8, REG8
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

void v16_cmp_rm16_reg16() {	// 39h CMP R/M16, REG16
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

void v16_cmp_reg8_rm8() {	// 3Ah CMP REG8, R/M8
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

void v16_cmp_reg16_rm16() {	// 3Bh CMP REG16, R/M16
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

void v16_cmp_al_imm8() {	// 3Ch CMP AL, IMM8
	cpuf8_1(CPU.AL - mmfu8_i);
	CPU.EIP += 2;
}

void v16_cmp_ax_imm16() {	// 3Dh CMP AX, IMM16
	cpuf16_1(CPU.AX - mmfu16_i);
	CPU.EIP += 3;
}

void v16_ds() {	// 3Eh DS:
	CPU.Segment = SEG_DS;
	++CPU.EIP;
}

void v16_aas() {	// 3Fh AAS
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

void v16_inc_ax() {	// 40h INC AX
	const int r = CPU.AX + 1;
	cpuf16_2(r);
	CPU.AX = cast(ubyte)r;
	++CPU.EIP;
}

void v16_inc_cx() {	// 41h INC CX
	const int r = CPU.CX + 1;
	cpuf16_2(r);
	CPU.CX = cast(ushort)r;
	++CPU.EIP;
}

void v16_inc_dx() {	// 42h INC DX
	const int r = CPU.DX + 1;
	cpuf16_2(r);
	CPU.DX = cast(ushort)r;
	++CPU.EIP;
}

void v16_inc_bx() {	// 43h INC BX
	const int r = CPU.BX + 1;
	cpuf16_2(r);
	CPU.BX = cast(ushort)r;
	++CPU.EIP;
}

void v16_inc_sp() {	// 44h INC SP
	const int r = CPU.SP + 1;
	cpuf16_2(r);
	CPU.SP = cast(ushort)r;
	++CPU.EIP;
}

void v16_inc_bp() {	// 45h INC BP
	const int r = CPU.BP + 1;
	cpuf16_2(r);
	CPU.BP = cast(ushort)r;
	++CPU.EIP;
}

void v16_inc_si() {	// 46h INC SI
	const int r = CPU.SI + 1;
	cpuf16_2(r);
	CPU.SI = cast(ushort)r;
	++CPU.EIP;
}

void v16_inc_di() {	// 47h INC DI
	const int r = CPU.DI + 1;
	cpuf16_2(r);
	CPU.DI = cast(ushort)r;
	++CPU.EIP;
}

void v16_dec_ax() {	// 48h DEC AX
	const int r = CPU.AX - 1;
	cpuf16_2(r);
	CPU.AX = cast(ushort)r;
	++CPU.EIP;
}

void v16_dec_cx() {	// 49h DEC CX
	const int r = CPU.CX - 1;
	cpuf16_2(r);
	CPU.CX = cast(ushort)r;
	++CPU.EIP;
}

void v16_dec_dx() {	// 4Ah DEC DX
	const int r = CPU.DX - 1;
	cpuf16_2(r);
	CPU.DX = cast(ushort)r;
	++CPU.EIP;
}

void v16_dec_bx() {	// 4Bh DEC BX
	const int r = CPU.BX - 1;
	cpuf16_2(r);
	CPU.BX = cast(ushort)r;
	++CPU.EIP;
}

void v16_dec_sp() {	// 4Ch DEC SP
	const int r = CPU.SP - 1;
	cpuf16_2(r);
	CPU.SP = cast(ushort)r;
	++CPU.EIP;
}

void v16_dec_bp() {	// 4Dh DEC BP
	const int r = CPU.BP - 1;
	cpuf16_2(r);
	CPU.BP = cast(ushort)r;
	++CPU.EIP;
}

void v16_dec_si() {	// 4Eh DEC SI
	const int r = CPU.SI - 1;
	cpuf16_2(r);
	CPU.SI = cast(ushort)r;
	++CPU.EIP;
}

void v16_dec_di() {	// 4Fh DEC DI
	const int r = CPU.DI - 1;
	cpuf16_2(r);
	CPU.DI = cast(ushort)r;
	++CPU.EIP;
}

void v16_push_ax() {	// 50h PUSH AX
	push16(CPU.AX);
	++CPU.EIP;
}

void v16_push_cx() {	// 51h PUSH CX
	push16(CPU.CX);
	++CPU.EIP;
}

void v16_push_dx() {	// 52h PUSH DX
	push16(CPU.DX);
	++CPU.EIP;
}

void v16_push_bx() {	// 53h PUSH BX
	push16(CPU.BX);
	++CPU.EIP;
}

void v16_push_sp() {	// 54h PUSH SP
	push16(CPU.SP);
	++CPU.EIP;
}

void v16_push_bp() {	// 55h PUSH BP
	push16(CPU.BP);
	++CPU.EIP;
}

void v16_push_si() {	// 56h PUSH SI
	push16(CPU.SI);
	++CPU.EIP;
}

void v16_push_di() {	// 57h PUSH DI
	push16(CPU.DI);
	++CPU.EIP;
}

void v16_pop_ax() {	// 58h POP AX
	CPU.AX = pop16;
	++CPU.EIP;
}

void v16_pop_cx() {	// 59h POP CX
	CPU.CX = pop16;
	++CPU.EIP;
}

void v16_pop_dx() {	// 5Ah POP DX
	CPU.DX = pop16;
	++CPU.EIP;
}

void v16_pop_bx() {	// 5Bh POP BX
	CPU.BX = pop16;
	++CPU.EIP;
}

void v16_pop_sp() {	// 5Ch POP SP
	CPU.SP = pop16;
	++CPU.EIP;
}

void v16_pop_bp() {	// 5Dh POP BP
	CPU.BP = pop16;
	++CPU.EIP;
}

void v16_pop_si() {	// 5Eh POP SI
	CPU.SI = pop16;
	++CPU.EIP;
}

void v16_pop_di() {	// 5Fh POP DI
	CPU.DI = pop16;
	++CPU.EIP;
}

void v16_operand_override() {	// 66h OPERAND OVERRIDE
	exec32(MEMORY[CPU.EIP]);
	++CPU.EIP;
}

void v16_address_override() {	// 67h ADDRESS OVERRIDE
	//TODO: CPU.AddressPrefix
	++CPU.EIP;
}

void v16_jo_short() {	// 70h JO SHORT-LABEL
	CPU.EIP += CPU.OF ? mmfi8_i + 2 : 2;
}

void v16_jno_short() {	// 71h JNO SHORT-LABEL
	CPU.EIP += CPU.OF ? 2 : mmfi8_i + 2;
}

void v16_jb_short() {	// 72h JB/JNAE/JC SHORT-LABEL
	CPU.EIP += CPU.CF ? mmfi8_i + 2 : 2;
}

void v16_jnb_short() {	// 73h JNB/JAE/JNC SHORT-LABEL
	CPU.EIP += CPU.CF ? 2 : mmfi8_i + 2;
}

void v16_je_short() {	// 74h JE/NZ SHORT-LABEL
	CPU.EIP += CPU.ZF ? mmfi8_i + 2 : 2;
}

void v16_jne_short() {	// 75h JNE/JNZ SHORT-LABEL
	CPU.EIP += CPU.ZF ? 2 : mmfi8_i + 2;
}

void v16_jbe_short() {	// 76h JBE/JNA SHORT-LABEL
	CPU.EIP += (CPU.CF || CPU.ZF) ? mmfi8_i + 2 : 2;
}

void v16_jnbe_short() {	// 77h JNBE/JA SHORT-LABEL
	CPU.EIP += CPU.CF == 0 && CPU.ZF == 0 ? mmfi8_i + 2 : 2;
}

void v16_js_short() {	// 78h JS SHORT-LABEL
	CPU.EIP += CPU.SF ? mmfi8_i + 2 : 2;
}

void v16_jns_short() {	// 79h JNS SHORT-LABEL
	CPU.EIP += CPU.SF ? 2 : mmfi8_i + 2;
}

void v16_jp_short() {	// 7Ah JP/JPE SHORT-LABEL
	CPU.EIP += CPU.PF ? mmfi8_i + 2 : 2;
}

void v16_jnp_short() {	// 7Bh JNP/JPO SHORT-LABEL
	CPU.EIP += CPU.PF ? 2 : mmfi8_i + 2;
}

void v16_jl_short() {	// 7Ch JL/JNGE SHORT-LABEL
	CPU.EIP += CPU.SF != CPU.OF ? mmfi8_i + 2 : 2;
}

void v16_jnl_short() {	// 7Dh JNL/JGE SHORT-LABEL
	CPU.EIP += CPU.SF == CPU.OF ? mmfi8_i + 2 : 2;
}

void v16_jle_short() {	// 7Eh JLE/JNG SHORT-LABEL
	CPU.EIP += CPU.SF != CPU.OF || CPU.ZF ? mmfi8_i + 2 : 2;
}

void v16_jnle_short() {	// 7Fh JNLE/JG SHORT-LABEL
	CPU.EIP += CPU.SF == CPU.OF && CPU.ZF == 0 ? mmfi8_i + 2 : 2;
}

void v16_grp1_rm8_imm8() {	// 80h GRP1 R/M8, IMM8
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
		v16_illegal;
	}
	cpuf8_1(r);
	CPU.EIP += 3;
}

void v16_grp1_rm16_imm16() {	// 81h GRP1 R/M16, IMM16
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
		r -= im;  break;
	default:
		log_info("Invalid ModR/M from GRP1_16");
		v16_illegal;
	}
	cpuf16_1(r);
	CPU.EIP += 4;
}

void v16_grp2_rm8_imm8() {	// 82h GRP2 R/M8, IMM8
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
		v16_illegal;
	}
	cpuf8_1(r);
	CPU.EIP += 3;
}

void v16_grp2_rm16_imm8() {	// 83h GRP2 R/M16, IMM8
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
		v16_illegal;
	}
	cpuf16_1(r);
	CPU.EIP += 3;
}

void v16_test_rm8_reg8() {	// 84h TEST R/M8, REG8
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

void v16_test_rm16_reg16() {	// 85h TEST R/M16, REG16
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

void v16_xchg_reg8_rm8() {	// 86h XCHG REG8, R/M8
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

void v16_xchx_reg16_rm16() {	// 87h XCHG REG16, R/M16
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
	// temp <- REG
	// REG  <- MEM
	// MEM  <- temp
	ushort r = void; const ushort s = mmfu16(addr);
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

void v16_mov_rm8_reg8() {	// 88h MOV R/M8, REG8
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

void v16_mov_rm16_reg16() {	// 89h MOV R/M16, REG16
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

void v16_mov_reg8() {	// 8Ah MOV REG8, R/M8
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

void v16_mov_reg16_rm16() {	// 8Bh MOV REG16, R/M16
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

void v16_mov_rm16_seg() {	// 8Ch MOV R/M16, SEGREG
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
		v16_illegal;
	}
	CPU.EIP += 2;
}

void v16_lea_reg16_mem16() {	// 8Dh LEA REG16, MEM16
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

void v16_mov_seg_rm16() {	// 8Eh MOV SEGREG, R/M16
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
		v16_illegal;
	}
	CPU.EIP += 2;
}

void v16_pop_rm16() {	// 8Fh POP R/M16
	const ubyte rm = mmfu8_i;
	if (rm & RM_REG) { // REG must be 000
		log_info("Invalid ModR/M for POP R/M16");
		v16_illegal;
	}
	mmiu16(pop16, mmrm16(rm, 1));
	CPU.EIP += 2;
}

void v16_nop() {	// 90h NOP (aka XCHG AX, AX)
	++CPU.EIP;
}

void v16_xchg_ax_cx() {	// 91h XCHG AX, CX
	const ushort r = CPU.AX;
	CPU.AX = CPU.CX;
	CPU.CX = r;
	++CPU.EIP;
}

void v16_xchg_ax_dx() {	// 92h XCHG AX, DX
	const ushort r = CPU.AX;
	CPU.AX = CPU.DX;
	CPU.DX = r;
	++CPU.EIP;
}

void v16_xchg_ax_bx() {	// 93h XCHG AX, BX
	const ushort r = CPU.AX;
	CPU.AX = CPU.BX;
	CPU.BX = r;
	++CPU.EIP;
}

void v16_xchg_ax_sp() {	// 94h XCHG AX, SP
	const ushort r = CPU.AX;
	CPU.AX = CPU.SP;
	CPU.SP = r;
	++CPU.EIP;
}

void v16_xchg_ax_bp() {	// 95h XCHG AX, BP
	const ushort r = CPU.AX;
	CPU.AX = CPU.BP;
	CPU.BP = r;
	++CPU.EIP;
}

void v16_xchg_ax_si() {	// 96h XCHG AX, SI
	const ushort r = CPU.AX;
	CPU.AX = CPU.SI;
	CPU.SI = r;
	++CPU.EIP;
}

void v16_xchg_ax_di() {	// 97h XCHG AX, DI
	const ushort r = CPU.AX;
	CPU.AX = CPU.DI;
	CPU.DI = r;
	++CPU.EIP;
}

void v16_cbw() {	// 98h CBW
	CPU.AH = CPU.AL & 0x80 ? 0xFF : 0;
	++CPU.EIP;
}

void v16_cwd() {	// 99h CWD
	CPU.DX = CPU.AX & 0x8000 ? 0xFFFF : 0;
	++CPU.EIP;
}

void v16_call_far() {	// 9Ah CALL FAR_PROC
	push16(CPU.CS);
	push16(CPU.IP);
	CPU.CS = mmfu16_i;
	CPU.IP = mmfu16_i(2);
}

void v16_wait() {	// 9Bh WAIT
	//TODO: WAIT
	++CPU.EIP;
}

void v16_pushf() {	// 9Ch PUSHF
	push16(FLAG);
	++CPU.EIP;
}

void v16_popf() {	// 9Dh POPF
	FLAG = pop16;
	++CPU.EIP;
}

void v16_sahf() {	// 9Eh SAHF (Save AH to Flags)
	FLAGB = CPU.AH;
	++CPU.EIP;
}

void v16_lahf() {	// 9Fh LAHF (Load AH from Flags)
	CPU.AH = FLAGB;
	++CPU.EIP;
}

void v16_mov_al_mem8() {	// A0h MOV AL, MEM8
	CPU.AL = mmfu8(mmfu16_i);
	CPU.EIP += 2;
}

void v16_mov_ax_mem16() {	// A1h MOV AX, MEM16
	CPU.AX = mmfu16(mmfu16_i);
	CPU.EIP += 3;
}

void v16_mov_mem8_al() {	// A2h MOV MEM8, AL
	mmiu8(CPU.AL, mmfu16_i);
	CPU.EIP += 2;
}

void v16_mov_mem16_ax() {	// A3h MOV MEM16, AX
	mmiu16(CPU.AX, mmfu16_i);
	CPU.EIP += 3;
}

void v16_movs_str8() {	// A4h MOVS DEST-STR8, SRC-STR8
}

void v16_movs_str16() {	// A5h MOVS DEST-STR16, SRC-STR16
}

void v16_cmps_str8() {	// A6h CMPS DEST-STR8, SRC-STR8
	cpuf8_1(
		mmfu8(get_ad(CPU.DS, CPU.SI)) -
		mmfu8(get_ad(CPU.ES, CPU.DI))
	);
	if (CPU.DF) {
		--CPU.DI;
		--CPU.SI;
	} else {
		++CPU.DI;
		++CPU.SI;
	}
}

void v16_cmps_str16() {	// A7h CMPSW DEST-STR16, SRC-STR16
	cpuf16_1(
		mmfu16(get_ad(CPU.DS, CPU.SI)) - mmfu16(get_ad(CPU.ES, CPU.DI))
	);
	if (CPU.DF) {
		CPU.DI -= 2;
		CPU.SI -= 2;
	} else {
		CPU.DI += 2;
		CPU.SI += 2;
	}
}

void v16_test_al_imm8() {	// A8h TEST AL, IMM8
	cpuf8_3(CPU.AL & mmfu8_i);
	CPU.EIP += 2;
}

void v16_test_ax_imm16() {	// A9h TEST AX, IMM16
	cpuf16_3(CPU.AX & mmfu16_i);
	CPU.EIP += 3;
}

void v16_stos_str8() {	// AAh STOS DEST-STR8
	mmiu8(CPU.AL, get_ad(CPU.ES, CPU.DI));
	if (CPU.DF) --CPU.DI; else ++CPU.DI;
	++CPU.EIP;
}

void v16_stos_str16() {	// ABh STOS DEST-STR16
	mmiu16(CPU.AX, get_ad(CPU.ES, CPU.DI));
	if (CPU.DF) CPU.DI -= 2; else CPU.DI += 2;
	++CPU.EIP;
}

void v16_lods_str8() {	// ACh LODS SRC-STR8
	CPU.AL = mmfu8(get_ad(CPU.DS, CPU.SI));
	if (CPU.DF) --CPU.SI; else ++CPU.SI;
	++CPU.EIP;
}

void v16_lods_str16() {	// ADh LODS SRC-STR16
	CPU.AX = mmfu16(get_ad(CPU.DS, CPU.SI));
	if (CPU.DF) CPU.SI -= 2; else CPU.SI += 2;
	++CPU.EIP;
}

void v16_scas_str8() {	// AEh SCAS DEST-STR8
	cpuf8_1(CPU.AL - mmfu8(get_ad(CPU.ES, CPU.DI)));
	if (CPU.DF) --CPU.DI; else ++CPU.DI;
	++CPU.EIP;
}

void v16_scas_str16() {	// AFh SCAS DEST-STR16
	cpuf16_1(CPU.AX - mmfu16(get_ad(CPU.ES, CPU.DI)));
	if (CPU.DF) CPU.DI -= 2; else CPU.DI += 2;
	++CPU.EIP;
}

void v16_mov_al_imm8() {	// B0h MOV AL, IMM8
	CPU.AL = mmfu8_i;
	CPU.EIP += 2;
}

void v16_mov_cl_imm8() {	// B1h MOV CL, IMM8
	CPU.CL = mmfu8_i;
	CPU.EIP += 2;
}

void v16_mov_dl_imm8() {	// B2h MOV DL, IMM8
	CPU.DL = mmfu8_i;
	CPU.EIP += 2;
}

void v16_mov_bl_imm8() {	// B3h MOV BL, IMM8
	CPU.BL = mmfu8_i;
	CPU.EIP += 2;
}

void v16_mov_ah_imm8() {	// B4h MOV AH, IMM8
	CPU.AH = mmfu8_i;
	CPU.EIP += 2;
}

void v16_mov_ch_imm8() {	// B5h MOV CH, IMM8
	CPU.CH = mmfu8_i;
	CPU.EIP += 2;
}

void v16_mov_dh_imm8() {	// B6h MOV DH, IMM8  
	CPU.DH = mmfu8_i;
	CPU.EIP += 2;
}

void v16_mov_bh_imm8() {	// B7h MOV BH, IMM8
	CPU.BH = mmfu8_i;
	CPU.EIP += 2;
}

void v16_mov_ax_imm16() {	// B8h MOV AX, IMM16
	CPU.AX = mmfu16_i;
	CPU.EIP += 3;
}

void v16_mov_cx_imm16() {	// B9h MOV CX, IMM16
	CPU.CX = mmfu16_i;
	CPU.EIP += 3;
}

void v16_mov_dx_imm16() {	// BAh MOV DX, IMM16
	CPU.DX = mmfu16_i;
	CPU.EIP += 3;
}

void v16_mov_bx_imm16() {	// BBh MOV BX, IMM16
	CPU.BX = mmfu16_i;
	CPU.EIP += 3;
}

void v16_mov_sp_imm16() {	// BCh MOV SP, IMM16
	CPU.SP = mmfu16_i;
	CPU.EIP += 3;
}

void v16_mov_bp_imm16() {	// BDh MOV BP, IMM16
	CPU.BP = mmfu16_i;
	CPU.EIP += 3;
}

void v16_mov_si_imm16() {	// BEh MOV SI, IMM16
	CPU.SI = mmfu16_i;
	CPU.EIP += 3;
}

void v16_mov_di_imm16() {	// BFh MOV DI, IMM16
	CPU.DI = mmfu16_i;
	CPU.EIP += 3;
}

void v16_ret_imm16_near() {	// C2 RET IMM16 (NEAR)
	const ushort sp = mmfi16_i;
	CPU.IP = pop16;
	CPU.SP += sp;
}

void v16_ret_near() {	// C3h RET (NEAR)
	CPU.IP = pop16;
}

void v16_les_reg16_mem16() {	// C4h LES REG16, MEM16
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

void v16_lds_reg16_mem16() {	// C5h LDS REG16, MEM16
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

void v16_mov_mem8_imm8() {	// C6h MOV MEM8, IMM8
	const ubyte rm = mmfu8_i;
	if (rm & RM_REG) { // No register operation allowed
		log_info("Invalid ModR/M for MOV MEM8");
		v16_illegal;
	}
	mmiu8(mmfu8_i(1), mmrm16(rm));
}

void v16_mov_mem16_imm16() {	// C7h MOV MEM16, IMM16
	const ubyte rm = mmfu8_i;
	if (rm & RM_REG) { // No register operation allowed
		log_info("Invalid ModR/M for MOV MEM16");
		v16_illegal;
	}
	mmiu16(mmfu16_i(1), mmrm16(rm, 1));
}

void v16_ret_imm16_far() {	// CAh RET IMM16 (FAR)
	const uint addr = CPU.EIP + 1;
	CPU.IP = pop16;
	CPU.CS = pop16;
	CPU.SP += mmfi16(addr);
}

void v16_ret_far() {	// CBh RET (FAR)
	CPU.IP = pop16;
	CPU.CS = pop16;
}

void v16_int3() {	// CCh INT 3
	INT(3);
	++CPU.EIP;
}

void v16_int_imm8() {	// CDh INT IMM8
	INT(mmfu8_i);
	CPU.EIP += 2;
}

void v16_into() {	// CEh INTO
	if (CPU.CF) INT(4);
	++CPU.EIP;
}

void v16_iret() {	// CFh IRET
	CPU.IP = pop16;
	CPU.CS = pop16;
	FLAG = pop16;
	++CPU.EIP;
}

void v16_grp2_rm8_1() {	// D0h GRP2 R/M8, 1
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - ROL
		r <<= 1; if (r & 0x100) { r |= 1; CPU.OF = 1; } break;
	case RM_REG_001: // 001 - ROR
		if (r & 1) { r |= 0x100; CPU.OF = 1; } r >>= 1; break;
	case RM_REG_010: // 010 - RCL
		r <<= 1; if (r & 0x200) { r |= 1; CPU.OF = 1; } break;
	case RM_REG_011: // 011 - RCR
		if (r & 1) { r |= 0x200; CPU.OF = 1; } r >>= 1; break;
	case RM_REG_100: // 100 - SAL/SHL
		r <<= 1; cpuf8_1(r); break;
	case RM_REG_101: // 101 - SHR
		r >>= 1; cpuf8_1(r); break;
	case RM_REG_111: // 111 - SAR
		if (r & 0x80) r |= 0x100; r >>= 1; cpuf8_1(r); break;
	default: // 110
		log_info("Invalid ModR/M for GRP2 R/M8, 1");
		v16_illegal;
	}
	mmiu8(r, addr);
	CPU.EIP += 2;
}

void v16_grp2_rm16_1() {	// D1h GRP2 R/M16, 1
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - ROL
		r <<= 1; if (r & 0x1_0000) { r |= 1; CPU.OF = 1; } break;
	case RM_REG_001: // 001 - ROR
		if (r & 1) { r |= 0x1_0000; CPU.OF = 1; } r >>= 1; break;
	case RM_REG_010: // 010 - RCL
		r <<= 1; if (r & 0x2_0000) { r |= 1; CPU.OF = 1; } break;
	case RM_REG_011: // 011 - RCR
		if (r & 1) { r |= 0x2_0000; CPU.OF = 1; } r >>= 1; break;
	case RM_REG_100: // 100 - SAL/SHL
		r <<= 1; cpuf16_1(r); break;
	case RM_REG_101: // 101 - SHR
		r >>= 1; cpuf16_1(r); break;
	case RM_REG_111: // 111 - SAR
		if (r & 0x8000) r |= 0x1_0000; r >>= 1; cpuf16_1(r); break;
	default: // 110
		log_info("Invalid ModR/M for GRP2 R/M16, 1");
		v16_illegal;
	}
	mmiu16(r, addr);
	CPU.EIP += 2;
}

void v16_grp2_rm8_cl() {	// D2h GRP2 R/M8, CL
	// The 8086 does not mask the rotation count.
	/*const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm);
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
		v16_illegal;
	}*/
	CPU.EIP += 2;
}

void v16_grp2_rm16_cl() {	// D3h GRP2 R/M16, CL
	// The 8086 does not mask the rotation count.
	/*const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
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
		v16_illegal;
	}*/
	CPU.EIP += 2;
}

void v16_aam() {	// D4h AAM
	const int r = CPU.AL % 0xA;
	cpuf8_5(r);
	CPU.AL = cast(ubyte)r;
	CPU.AH = cast(ubyte)(r / 0xA);
	++CPU.EIP;
}

void v16_aad() {	// D5h AAD
	const int r = CPU.AL + (CPU.AH * 0xA);
	cpuf8_5(r);
	CPU.AL = cast(ubyte)r;
	CPU.AH = 0;
	++CPU.EIP;
}

void v16_xlat() {	// D7h XLAT SOURCE-TABLE
	CPU.AL = mmfu8(get_ad(CPU.DS, CPU.BX) + cast(byte)CPU.AL);
	++CPU.EIP;
}

void v16_loopne() {	// E0h LOOPNE/LOOPNZ SHORT-LABEL
	--CPU.CX;
	if (CPU.CX && CPU.ZF == 0) CPU.EIP += mmfi8_i;
	else CPU.EIP += 2;
}

void v16_loope() {	// E1h LOOPE/LOOPZ SHORT-LABEL
	--CPU.CX;
	if (CPU.CX && CPU.ZF) CPU.EIP += mmfi8_i;
	else CPU.EIP += 2;
}

void v16_loop() {	// E2h LOOP SHORT-LABEL
	--CPU.CX;
	if (CPU.CX) CPU.EIP += mmfi8_i;
	else CPU.EIP += 2;
}

 void v16_jcxz() {	// E3 JCXZ SHORT-LABEL
	if (CPU.CX == 0) CPU.EIP += mmfi8_i;
	else CPU.EIP += 2;
 }
 
 void v16_in_al_imm8() {	// E4h IN AL, IMM8
 }
 
 void v16_in_ax_imm8() {	// E5h IN AX, IMM8
 }
 
 void v16_out_imm8_al() {	// E6h OUT IMM8, AL
 }
 
 void v16_out_imm8_ax() {	// E7h OUT IMM8, AX
 }
 
 void v16_call_near() {	// E8h CALL NEAR-PROC
	push16(CPU.IP);
	CPU.EIP += mmfi16_i; // Direct within segment
 }
 
 void v16_jmp_near() {	// E9h JMP NEAR-LABEL
	CPU.EIP += mmfi16_i + 3; // ±32 KB
 }
 
 void v16_jmp_Far() {	// EAh JMP FAR-LABEL
	// Any segment, any fragment, 5 byte instruction.
	// EAh (LO-CPU.IP) (HI-CPU.IP) (LO-CPU.CS) (HI-CPU.CS)
	const ushort ip = mmfu16_i;
	const ushort cs = mmfu16_i(2);
	CPU.IP = ip;
	CPU.CS = cs;
 }
 
 void v16_jmp_short() {	// EBh JMP SHORT-LABEL
	CPU.EIP += mmfi8_i + 2; // ±128 B
 }
 
 void v16_in_al_dx() {	// ECh IN AL, DX
 }
 
 void v16_in_ax_dx() {	// EDh IN AX, DX
 }
 
 void v16_out_al_dx() {	// EEh OUT AL, DX
 }
 
 void v16_out_ax_dx() {	// EFh OUT AX, DX
 }
 
 void v16_lock() {	// F0h LOCK (prefix)
	//CPU.Lock = 1;
	++CPU.EIP;
 }
 
 void v16_repne() {	// F2h REPNE/REPNZ
	while (CPU.CX > 0) {
		//TODO: Finish REPNE/REPNZ properly?
		v16_cmps_str8;
		--CPU.CX;
		if (CPU.ZF == 0) break;
	}
	++CPU.EIP;
 }
 
 void v16_rep() {	// F3h REP/REPE/REPNZ
 }
 
 void v16_hlt() {	// F4h HLT
	RLEVEL = 0;
	++CPU.EIP;
 }
 
 void v16_cmc() {	// F5h CMCCMC
	CPU.CF = !CPU.CF;
	++CPU.EIP;
 }
 
 void v16_grp3_rm8_imm8() {	// F6h GRP3 R/M8, IMM8
	const ubyte rm = mmfu8_i;
	const ubyte im = mmfu8_i(1);
	const int addr = mmrm16(rm);
	int r = void;
	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - TEST
		cpuf8_1(im & mmfu8(addr)); break;
	case RM_REG_010: // 010 - NOT
		mmiu8(~mmfu8(addr), addr); break;
	case RM_REG_011: // 011 - NEG
		import core.stdc.stdio : printf;
		r = cast(ubyte)-mmfi8(addr);
		cpuf8_1(r);
		CPU.CF = cast(ubyte)r;
		mmiu8(r, addr);
		break;
	case RM_REG_100: // 100 - MUL
		r = im * mmfu8(addr);
		cpuf8_4(r);
		mmiu8(r, addr);
		break;
	case RM_REG_101: // 101 - IMUL
		r = cast(ubyte)(cast(byte)im * mmfi8(addr));
		cpuf8_4(r);
		mmiu8(r, addr);
		break;
	case RM_REG_110: // 110 - DIV
	//TODO: Check if im == 0 (#DE), DIV
		const ubyte d = mmfu8(addr);
		r = CPU.AX / d;
		CPU.AH = cast(ubyte)(CPU.AX % d);
		CPU.AL = cast(ubyte)(r);
		break;
	case RM_REG_111: // 111 - IDIV
	//TODO: Check if im == 0 (#DE), IDIV
		const byte d = mmfi8(addr);
		r = cast(short)CPU.AX / d;
		CPU.AH = cast(ubyte)(cast(short)CPU.AX % d);
		CPU.AL = cast(ubyte)r;
		break;
	default:
		log_info("Invalid ModR/M on GRP3_8");
		v16_illegal;
	}
	CPU.EIP += 3;
 }
 
 void v16_grp3_rm16_imm16() {	// F7 GRP3 R/M16, IMM16
	const ubyte rm = mmfu8_i; // Get ModR/M byte
	ushort im = mmfu16_i(1);
	int addr = mmrm16(rm, 1);
	int r = void;
	switch (rm & RM_REG) {
	case RM_REG_000: // 000 - TEST
		cpuf16_1(im & mmfu16(addr)); break;
	case RM_REG_010: // 010 - NOT
		mmiu16(~im, addr); break;
	case RM_REG_011: // 011 - NEG
		r = -mmfi16(addr);
		cpuf16_1(r);
		CPU.CF = cast(ubyte)r;
		mmiu16(r, addr);
		break;
	case RM_REG_100: // 100 - MUL
		r = im * mmfu16(addr);
		cpuf16_4(r);
		mmiu16(r, addr);
		break;
	case RM_REG_101: // 101 - IMUL
		r = im * mmfi16(addr);
		cpuf16_4(r);
		mmiu16(r, addr);
		break;
	case RM_REG_110: // 110 - DIV
		r = im / mmfu16(addr);
		cpuf16_4(r);
		mmiu16(r, addr);
		break;
	case RM_REG_111: // 111 - IDIV
		r = im / mmfi16(addr);
		cpuf16_4(r);
		mmiu16(r, addr);
		break;
	default:
		log_info("Invalid ModR/M on GRP3_8");
		v16_illegal;
	}
	CPU.EIP += 4;
}

void v16_clc() {	// F8h CLC
	CPU.CF = 0;
	++CPU.EIP;
}

void v16_stc() {	// F9h STC
	CPU.CF = 1;
	++CPU.EIP;
}

void v16_cli() {	// FAh CLI
	CPU.IF = 0;
	++CPU.EIP;
}

void v16_sti() {	// FBh STI
	CPU.IF = 1;
	++CPU.EIP;
}

void v16_cld() {	// FCh CLD
	CPU.DF = 0;
	++CPU.EIP;
}

void v16_std() {	// FDh STD
	CPU.DF = 1;
	++CPU.EIP;
}

void v16_grp4_rm8() {	// FEh GRP4 R/M8
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
		v16_illegal;
	}
	mmiu16(r, addr);
	cpuf16_2(r);
	CPU.EIP += 2;
}

void v16_grp4_rm16() {	// FFh GRP5 R/M16
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
		break;
	case RM_REG_010: // 010 - CALL R/M16 (near) -- Indirect within segment
		push16(CPU.IP);
		CPU.IP = cast(ushort)r;
		break;
	case RM_REG_011: { // 011 - CALL MEM16 (far) -- Indirect outside segment
		ushort nip = cast(ushort)get_ad(mmfu16(addr + 2), r);
		push16(CPU.CS);
		push16(CPU.IP);
		CPU.IP = nip;
		break;
	}
	case RM_REG_100: // 100 - JMP R/M16 (near) -- Indirect within segment
		CPU.IP = cast(ushort)(r + 2);
		break;
	case RM_REG_101: // 101 - JMP MEM16 (far) -- Indirect outside segment
		CPU.IP = cast(ushort)get_ad(mmfu16(addr), r + 2);
		break;
	case RM_REG_110: // 110 - PUSH MEM16
		push16(mmfu16(get_ad(mmfu16(addr + 2), r)));
		CPU.EIP += 2;
		break;
	default:
		log_info("Invalid ModR/M on GRP5_16");
		v16_illegal;
	}
}

void v16_illegal() {	// Illegal instruction
	log_info("INVALID OPERATION CODE");
	//TODO: Raise vector on illegal op
}