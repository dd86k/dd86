/**
 * Execution core
 */
module vcpu.exec;

import vcpu.core, vcpu.mm, vcpu.utils, vcpu.modrm;
import vdos.interrupts, vdos.io;
import logger;

extern (C):

//TODO: Consider grouping by 6 bits
//      * CPU can shift by 2 bits
//      - D/W bits need to be set somewhere and be accessed fast

/**
 * Execute an instruction
 * Params: op = opcode
 */
void execop(ubyte op) {
	OPMAP1[op]();
}

void exec00() {	// 00h ADD R/M8, REG8
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	int b = modrm16freg(modrm, 0);
	int r = a + b;
	cpuf8_1(r);
	modrm16irm(modrm, 0, r);
}

void exec01() {	// 01h ADD R/M16, REG16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	int b = modrm16freg(modrm, 1);
	int r = a + b;
	cpuf16_1(r);
	modrm16irm(modrm, 1, r);
}

void exec02() {	// 02h ADD REG8, R/M8
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 0);
	int b = modrm16frm(modrm, 0);
	int r = a + b;
	cpuf8_1(r);
	modrm16ireg(modrm, 0, r);
}

void exec03() {	// 03h ADD REG16, R/M16
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 1);
	int b = modrm16frm(modrm, 1);
	int r = a + b;
	cpuf16_1(r);
	modrm16ireg(modrm, 1, r);
}

void exec04() {	// 04h ADD AL, IMM8
	int r = CPU.AL + mmfu8_i;
	cpuf8_1(r);
	CPU.AL = cast(ubyte)r;
}

void exec05() {	// 05h ADD AX, IMM16
	int r = CPU.AX + mmfu16_i;
	cpuf16_1(r);
	CPU.AX = cast(ushort)r;
}

void exec06() {	// 06h PUSH ES
	CPU.push16(CPU.ES);
}

void exec07() {	// 07h POP ES
	CPU.ES = CPU.pop16;
}

void exec08() {	// 08h OR R/M8, REG8
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	int b = modrm16freg(modrm, 0);
	int r = a | b;
	cpuf8_3(r);
	modrm16irm(modrm, 0, r);
}

void exec09() {	// 09h OR R/M16, REG16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	int b = modrm16freg(modrm, 1);
	int r = a | b;
	cpuf16_3(r);
	modrm16irm(modrm, 1, r);
}

void exec0A() {	// 0Ah OR REG8, R/M8
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 0);
	int b = modrm16frm(modrm, 0);
	int r = a | b;
	cpuf8_3(r);
	modrm16ireg(modrm, 0, r);
}

void exec0B() {	// 0Bh OR REG16, R/M16
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 1);
	int b = modrm16frm(modrm, 1);
	int r = a | b;
	cpuf16_3(r);
	modrm16ireg(modrm, 1, r);
}

void exec0C() {	// 0Ch OR AL, IMM8
	int r = CPU.AL | mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
}

void exec0D() {	// 0Dh OR AX, IMM16
	int r = CPU.AX | mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
}

void exec0E() {	// 0Eh PUSH CS
	CPU.push16(CPU.CS);
}

void exec0F() { // 0Fh two-byte map
}

void exec10() {	// 10h ADC R/M8, REG8
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	int b = modrm16freg(modrm, 0);
	int r = a + b;
	if (CPU.CF) ++r;
	cpuf8_3(r);
	modrm16irm(modrm, 0, r);
}

void exec11() {	// 11h ADC R/M16, REG16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	int b = modrm16freg(modrm, 1);
	int r = a + b;
	if (CPU.CF) ++r;
	cpuf16_3(r);
	modrm16irm(modrm, 1, r);
}

void exec12() {	// 12h ADC REG8, R/M8
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 0);
	int b = modrm16frm(modrm, 0);
	int r = a + b;
	if (CPU.CF) ++r;
	cpuf8_3(r);
	modrm16ireg(modrm, 0, r);
}

void exec13() {	// 13h ADC REG16, R/M16
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 1);
	int b = modrm16frm(modrm, 1);
	int r = a + b;
	if (CPU.CF) ++r;
	cpuf16_3(r);
	modrm16ireg(modrm, 1, r);
}

void exec14() {	// 14h ADC AL, IMM8
	int r = CPU.AL + mmfu8_i;
	if (CPU.CF) ++r;
	cpuf8_1(r);
	CPU.AL = cast(ubyte)r;
}

void exec15() {	// 15h ADC AX, IMM16
	int r = CPU.AX + mmfu16_i;
	if (CPU.CF) ++r;
	cpuf16_1(r);
	CPU.AX = cast(ushort)r;
}

void exec16() {	// 16h PUSH SS
	CPU.push16(CPU.SS);
}

void exec17() {	// 17h POP SS
	CPU.SS = CPU.pop16;
}

void exec18() {	// 18h SBB R/M8, REG8
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	int b = modrm16freg(modrm, 0);
	int r = a - b;
	if (CPU.CF) --r;
	cpuf8_3(r);
	modrm16irm(modrm, 0, r);
}

void exec19() {	// 19h SBB R/M16, REG16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	int b = modrm16freg(modrm, 1);
	int r = a - b;
	if (CPU.CF) --r;
	cpuf8_3(r);
	modrm16irm(modrm, 1, r);
}

void exec1A() {	// 1Ah SBB REG8, R/M8
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 0);
	int b = modrm16frm(modrm, 0);
	int r = a - b;
	if (CPU.CF) --r;
	cpuf8_3(r);
	modrm16ireg(modrm, 0, r);
}

void exec1B() {	// 1Bh SBB REG16, R/M16
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 1);
	int b = modrm16frm(modrm, 1);
	int r = a - b;
	if (CPU.CF) --r;
	cpuf16_3(r);
	modrm16ireg(modrm, 1, r);
}

void exec1C() {	// 1Ch SBB AL, IMM8
	int r = CPU.AL - mmfu8_i;
	if (CPU.CF) --r;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
}

void exec1D() {	// 1Dh SBB AX, IMM16
	int r = CPU.AX - mmfu16_i;
	if (CPU.CF) --r;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
}

void exec1E() {	// 1Eh PUSH DS
	CPU.push16(CPU.DS);
}

void exec1F() {	// 1Fh POP DS
	CPU.DS = CPU.pop16;
}

void exec20() {	// 20h AND R/M8, REG8
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	int b = modrm16freg(modrm, 0);
	int r = a & b;
	cpuf8_3(r);
	modrm16irm(modrm, 0, r);
}

void exec21() {	// 21h AND R/M16, REG16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	int b = modrm16freg(modrm, 1);
	int r = a & b;
	cpuf16_3(r);
	modrm16irm(modrm, 1, r);
}

void exec22() {	// 22h AND REG8, R/M8
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 0);
	int b = modrm16frm(modrm, 0);
	int r = a & b;
	cpuf8_3(r);
	modrm16ireg(modrm, 0, r);
}

void exec23() {	// 23h AND REG16, R/M16
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 1);
	int b = modrm16frm(modrm, 1);
	int r = a & b;
	cpuf16_3(r);
	modrm16ireg(modrm, 1, r);
}

void exec24() {	// 24h AND AL, IMM8
	int r = CPU.AL & mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
}

void exec25() {	// 25h AND AX, IMM16
	int r = CPU.AX & mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
}

void exec26() {	// 26h ES: (Segment override prefix)
	CPU.segment = SEG_ES;
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
}

void exec28() {	// 28h SUB R/M8, REG8
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	int b = modrm16freg(modrm, 0);
	int r = a - b;
	cpuf8_1(r);
	modrm16irm(modrm, 0, r);
}

void exec29() {	// 29h SUB R/M16, REG16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	int b = modrm16freg(modrm, 1);
	int r = a - b;
	cpuf16_1(r);
	modrm16irm(modrm, 1, r);
}

void exec2A() {	// 2Ah SUB REG8, R/M8
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 0);
	int b = modrm16frm(modrm, 0);
	int r = a - b;
	cpuf8_1(r);
	modrm16ireg(modrm, 0, r);
}

void exec2B() {	// 2Bh SUB REG16, R/M16
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 1);
	int b = modrm16frm(modrm, 1);
	int r = a - b;
	cpuf16_1(r);
	modrm16ireg(modrm, 1, r);
}

void exec2C() {	// 2Ch SUB AL, IMM8
	int r = CPU.AL - mmfu8_i;
	cpuf8_1(r);
	CPU.AL = cast(ubyte)r;
}

void exec2D() {	// 2Dh SUB AX, IMM16
	int r = CPU.AX - mmfu16_i;
	cpuf16_1(r);
	CPU.AX = cast(ushort)r;
}

void exec2E() {	// 2Eh CS:
	CPU.segment = SEG_CS;
}

void exec2F() {	// 2Fh DAS
	ubyte oldAL = CPU.AL;
	ubyte oldCF = CPU.CF;
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
}

void exec30() {	// 30h XOR R/M8, REG8
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	int b = modrm16freg(modrm, 0);
	int r = a ^ b;
	cpuf8_3(r);
	modrm16irm(modrm, 0, r);
}

void exec31() {	// 31h XOR R/M16, REG16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	int b = modrm16freg(modrm, 1);
	int r = a ^ b;
	cpuf16_3(r);
	modrm16irm(modrm, 1, r);
}

void exec32() {	// 32h XOR REG8, R/M8
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 0);
	int b = modrm16frm(modrm, 0);
	int r = a ^ b;
	cpuf8_3(r);
	modrm16ireg(modrm, 0, r);
}

void exec33() {	// 33h XOR REG16, R/M16
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 1);
	int b = modrm16frm(modrm, 1);
	int r = a ^ b;
	cpuf16_3(r);
	modrm16ireg(modrm, 1, r);
}

void exec34() {	// 34h XOR AL, IMM8
	int r = CPU.AL ^ mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
}

void exec35() {	// 35h XOR AX, IMM16
	int r = CPU.AX ^ mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
}

void exec36() {	// 36h SS:
	CPU.segment = SEG_SS;
}

void exec37() {	// 37h AAA
	if (((CPU.AL & 0xF) > 9) || CPU.AF) {
		CPU.AX += 0x106;
		CPU.AF = CPU.CF = 1;
	} else CPU.AF = CPU.CF = 0;
	CPU.AL &= 0xF;
}

void exec38() {	// 38h CMP R/M8, REG8
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	int b = modrm16freg(modrm, 0);
	int r = a ^ b;
	cpuf8_1(r);
	modrm16irm(modrm, 0, r);
}

void exec39() {	// 39h CMP R/M16, REG16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	int b = modrm16freg(modrm, 1);
	int r = a ^ b;
	cpuf16_1(r);
	modrm16irm(modrm, 1, r);
}

void exec3A() {	// 3Ah CMP REG8, R/M8
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 0);
	int b = modrm16frm(modrm, 0);
	int r = a ^ b;
	cpuf8_1(r);
	modrm16ireg(modrm, 0, r);
}

void exec3B() {	// 3Bh CMP REG16, R/M16
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 1);
	int b = modrm16frm(modrm, 1);
	int r = a ^ b;
	cpuf16_1(r);
	modrm16ireg(modrm, 1, r);
}

void exec3C() {	// 3Ch CMP AL, IMM8
	cpuf8_1(CPU.AL - mmfu8_i);
}

void exec3D() {	// 3Dh CMP AX, IMM16
	cpuf16_1(CPU.AX - mmfu16_i);
}

void exec3E() {	// 3Eh DS:
	CPU.segment = SEG_DS;
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
}

void exec40() {	// 40h INC AX
	int r = CPU.AX + 1;
	cpuf16_2(r);
	CPU.AX = cast(ubyte)r;
}

void exec41() {	// 41h INC CX
	int r = CPU.CX + 1;
	cpuf16_2(r);
	CPU.CX = cast(ushort)r;
}

void exec42() {	// 42h INC DX
	int r = CPU.DX + 1;
	cpuf16_2(r);
	CPU.DX = cast(ushort)r;
	++CPU.EIP;
}

void exec43() {	// 43h INC BX
	int r = CPU.BX + 1;
	cpuf16_2(r);
	CPU.BX = cast(ushort)r;
}

void exec44() {	// 44h INC SP
	int r = CPU.SP + 1;
	cpuf16_2(r);
	CPU.SP = cast(ushort)r;
}

void exec45() {	// 45h INC BP
	int r = CPU.BP + 1;
	cpuf16_2(r);
	CPU.BP = cast(ushort)r;
}

void exec46() {	// 46h INC SI
	int r = CPU.SI + 1;
	cpuf16_2(r);
	CPU.SI = cast(ushort)r;
}

void exec47() {	// 47h INC DI
	int r = CPU.DI + 1;
	cpuf16_2(r);
	CPU.DI = cast(ushort)r;
}

void exec48() {	// 48h DEC AX
	int r = CPU.AX - 1;
	cpuf16_2(r);
	CPU.AX = cast(ushort)r;
}

void exec49() {	// 49h DEC CX
	int r = CPU.CX - 1;
	cpuf16_2(r);
	CPU.CX = cast(ushort)r;
}

void exec4A() {	// 4Ah DEC DX
	int r = CPU.DX - 1;
	cpuf16_2(r);
	CPU.DX = cast(ushort)r;
}

void exec4B() {	// 4Bh DEC BX
	int r = CPU.BX - 1;
	cpuf16_2(r);
	CPU.BX = cast(ushort)r;
}

void exec4C() {	// 4Ch DEC SP
	int r = CPU.SP - 1;
	cpuf16_2(r);
	CPU.SP = cast(ushort)r;
}

void exec4D() {	// 4Dh DEC BP
	int r = CPU.BP - 1;
	cpuf16_2(r);
	CPU.BP = cast(ushort)r;
}

void exec4E() {	// 4Eh DEC SI
	int r = CPU.SI - 1;
	cpuf16_2(r);
	CPU.SI = cast(ushort)r;
}

void exec4F() {	// 4Fh DEC DI
	int r = CPU.DI - 1;
	cpuf16_2(r);
	CPU.DI = cast(ushort)r;
}

void exec50() {	// 50h PUSH AX
	CPU.push16(CPU.AX);
}

void exec51() {	// 51h PUSH CX
	CPU.push16(CPU.CX);
}

void exec52() {	// 52h PUSH DX
	CPU.push16(CPU.DX);
}

void exec53() {	// 53h PUSH BX
	CPU.push16(CPU.BX);
}

void exec54() {	// 54h PUSH SP
	CPU.push16(CPU.SP);
}

void exec55() {	// 55h PUSH BP
	CPU.push16(CPU.BP);
}

void exec56() {	// 56h PUSH SI
	CPU.push16(CPU.SI);
}

void exec57() {	// 57h PUSH DI
	CPU.push16(CPU.DI);
}

void exec58() {	// 58h POP AX
	CPU.AX = CPU.pop16;
}

void exec59() {	// 59h POP CX
	CPU.CX = CPU.pop16;
}

void exec5A() {	// 5Ah POP DX
	CPU.DX = CPU.pop16;
}

void exec5B() {	// 5Bh POP BX
	CPU.BX = CPU.pop16;
}

void exec5C() {	// 5Ch POP SP
	CPU.SP = CPU.pop16;
}

void exec5D() {	// 5Dh POP BP
	CPU.BP = CPU.pop16;
}

void exec5E() {	// 5Eh POP SI
	CPU.SI = CPU.pop16;
}

void exec5F() {	// 5Fh POP DI
	CPU.DI = CPU.pop16;
}

void exec66() {	// 66h OPERAND OVERRIDE
	CPU.pf_operand = 0x66;
}

void exec67() {	// 67h ADDRESS OVERRIDE
	CPU.pf_address = 0x67;
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
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	int b = mmfu8_i;
	switch (modrm & MODRM_REG) { // REG
	case MODRM_REG_000: // 000 - ADD
		a += b; modrm16irm(modrm, 0, a); break;
	case MODRM_REG_001: // 001 - OR
		a |= b; modrm16irm(modrm, 0, a); break;
	case MODRM_REG_010: // 010 - ADC
		a += b; if (CPU.CF) ++a; modrm16irm(modrm, 0, a); break;
	case MODRM_REG_011: // 011 - SBB
		a -= b; if (CPU.CF) --a; modrm16irm(modrm, 0, a); break;
	case MODRM_REG_100: // 100 - AND
		a &= b; modrm16irm(modrm, 0, a); break;
	case MODRM_REG_101: // 101 - SUB
		a -= b; modrm16irm(modrm, 0, a); break;
	case MODRM_REG_110: // 110 - XOR
		a ^= b; modrm16irm(modrm, 0, a); break;
	default: // 111 - CMP
		a -= b; break;
	}
	cpuf8_1(a);
}

void exec81() {	// 81h GRP1 R/M16, IMM16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	int b = mmfu16_i;
	switch (modrm & MODRM_REG) { // REG
	case MODRM_REG_000: // 000 - ADD
		a += b; modrm16irm(modrm, 1, a); break;
	case MODRM_REG_001: // 001 - OR
		a |= b; modrm16irm(modrm, 1, a); break;
	case MODRM_REG_010: // 010 - ADC
		a += b; if (CPU.CF) ++a; modrm16irm(modrm, 1, a); break;
	case MODRM_REG_011: // 011 - SBB
		a -= b; if (CPU.CF) --a; modrm16irm(modrm, 1, a); break;
	case MODRM_REG_100: // 100 - AND
		a &= b; modrm16irm(modrm, 1, a); break;
	case MODRM_REG_101: // 101 - SUB
		a -= b; modrm16irm(modrm, 1, a); break;
	case MODRM_REG_110: // 110 - XOR
		a ^= b; modrm16irm(modrm, 1, a); break;
	default: // 111 - CMP
		a -= b; break;
	}
	cpuf16_1(a);
}

void exec82() {	// 82h GRP2 R/M8, IMM8
	ubyte modrm = mmfu8_i; // Get ModR/M byte
	int a = modrm16frm(modrm, 0);
	int b = mmfu8_i;
	switch (modrm & MODRM_REG) { // ModRM REG
	case MODRM_REG_000: // 000 - ADD
		a += b; modrm16irm(modrm, 0, a); break;
	case MODRM_REG_010: // 010 - ADC
		a += b; if (CPU.CF) ++a; modrm16irm(modrm, 0, a); break;
	case MODRM_REG_011: // 011 - SBB
		a -= b; if (CPU.CF) --a; modrm16irm(modrm, 0, a); break;
	case MODRM_REG_101: // 101 - SUB
		a -= b; modrm16irm(modrm, 0, a); break;
	case MODRM_REG_111: // 111 - CMP
		a -= b; break;
	default:
		log_info("Invalid ModR/M for GRP2_8");
		execill;
		return;
	}
	cpuf8_1(a);
}

void exec83() {	// 83h GRP2 R/M16, IMM8
	ubyte modrm = mmfu8_i; // Get ModR/M byte
	int a = modrm16frm(modrm, 1);
	int b = mmfu8_i;
	switch (modrm & MODRM_REG) { // ModRM REG
	case MODRM_REG_000: // 000 - ADD
		a += b; modrm16irm(modrm, 0, a); break;
	case MODRM_REG_010: // 010 - ADC
		a += b; if (CPU.CF) ++a; modrm16irm(modrm, 1, a); break;
	case MODRM_REG_011: // 011 - SBB
		a -= b; if (CPU.CF) --a; modrm16irm(modrm, 1, a); break;
	case MODRM_REG_101: // 101 - SUB
		a -= b; modrm16irm(modrm, 1, a); break;
	case MODRM_REG_111: // 111 - CMP
		a -= b; break;
	default:
		log_info("Invalid ModR/M for GRP2_16");
		execill;
		return;
	}
	cpuf16_1(a);
}

void exec84() {	// 84h TEST R/M8, REG8
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	int b = modrm16freg(modrm, 0);
	cpuf8_3(a & b);
}

void exec85() {	// 85h TEST R/M16, REG16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	int b = modrm16freg(modrm, 1);
	cpuf16_3(a & b);
}

void exec86() {	// 86h XCHG REG8, R/M8
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 0);
	int b = modrm16frm(modrm, 0);
	modrm16ireg(modrm, 0, b);
	modrm16irm(modrm, 0, a);
}

void exec87() {	// 87h XCHG REG16, R/M16
	ubyte modrm = mmfu8_i;
	int a = modrm16freg(modrm, 1);
	int b = modrm16frm(modrm, 1);
	modrm16ireg(modrm, 1, b);
	modrm16irm(modrm, 1, a);
}

void exec88() {	// 88h MOV R/M8, REG8
	ubyte modrm = mmfu8_i;
	modrm16irm(modrm, 0, modrm16freg(modrm, 0));
}

void exec89() {	// 89h MOV R/M16, REG16
	ubyte modrm = mmfu8_i;
	modrm16irm(modrm, 1, modrm16freg(modrm, 1));
}

void exec8A() {	// 8Ah MOV REG8, R/M8
	ubyte modrm = mmfu8_i;
	modrm16ireg(modrm, 0, modrm16frm(modrm, 0));
}

void exec8B() {	// 8Bh MOV REG16, R/M16
	ubyte modrm = mmfu8_i;
	modrm16ireg(modrm, 1, modrm16frm(modrm, 1));
}

void exec8C() {	// 8Ch MOV R/M16, SEGREG
	// MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
	int modrm = mmfu8_i;
	int a = void;
	switch (modrm & MODRM_REG) { // if REG[3] is clear, trip to default
	case MODRM_REG_100: a = CPU.ES; break;
	case MODRM_REG_101: a = CPU.CS; break;
	case MODRM_REG_110: a = CPU.SS; break;
	case MODRM_REG_111: a = CPU.DS; break;
	default: // when bit 6 is clear (REG[3])
		log_info("Invalid ModR/M for SEGREG->RM");
		execill;
		return;
	}
	modrm16irm(modrm, 1, a);
}

void exec8D() {	// 8Dh LEA REG16, MEM16
	ubyte modrm = mmfu8_i;
	if ((modrm & MODRM_MOD) == MODRM_MOD_11) {
		execill;
		return;
	}
	int a = modrm16rm(modrm);
	modrm16ireg(modrm, 1, a);
}

void exec8E() {	// 8Eh MOV SEGREG, R/M16
	// MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
	int modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	switch (modrm & MODRM_REG) { // if REG[3] is clear, trip to default
	case MODRM_REG_100: CPU.ES = cast(ushort)a; break;
	case MODRM_REG_101: CPU.CS = cast(ushort)a; break;
	case MODRM_REG_110: CPU.SS = cast(ushort)a; break;
	case MODRM_REG_111: CPU.DS = cast(ushort)a; break;
	default: // when bit 6 is clear (REG[3])
		log_info("Invalid ModR/M for SEGREG->RM");
		execill;
		return;
	}
}

void exec8F() {	// 8Fh POP R/M16
	ubyte modrm = mmfu8_i;
	if (modrm & MODRM_REG) { // REG must be 000
		log_info("Invalid ModR/M for POP R/M16");
		execill;
		return;
	}
	CPU.push16(cast(ushort)modrm16frm(modrm, 1));
}

void exec90() {	// 90h NOP (aka XCHG AX, AX)
}

void exec91() {	// 91h XCHG AX, CX
	ushort r = CPU.AX;
	CPU.AX = CPU.CX;
	CPU.CX = r;
}

void exec92() {	// 92h XCHG AX, DX
	ushort r = CPU.AX;
	CPU.AX = CPU.DX;
	CPU.DX = r;
}

void exec93() {	// 93h XCHG AX, BX
	ushort r = CPU.AX;
	CPU.AX = CPU.BX;
	CPU.BX = r;
}

void exec94() {	// 94h XCHG AX, SP
	ushort r = CPU.AX;
	CPU.AX = CPU.SP;
	CPU.SP = r;
}

void exec95() {	// 95h XCHG AX, BP
	ushort r = CPU.AX;
	CPU.AX = CPU.BP;
	CPU.BP = r;
}

void exec96() {	// 96h XCHG AX, SI
	ushort r = CPU.AX;
	CPU.AX = CPU.SI;
	CPU.SI = r;
}

void exec97() {	// 97h XCHG AX, DI
	ushort r = CPU.AX;
	CPU.AX = CPU.DI;
	CPU.DI = r;
}

void exec98() {	// 98h CBW
	CPU.AH = CPU.AL & 0x80 ? 0xFF : 0;
}

void exec99() {	// 99h CWD
	CPU.DX = CPU.AX & 0x8000 ? 0xFFFF : 0;
}

void exec9A() {	// 9Ah CALL FAR_PROC
	CPU.push16(CPU.CS);
	CPU.push16(CPU.IP);
	CPU.CS = mmfu16_i;
	CPU.IP = mmfu16_i;
}

void exec9B() {	// 9Bh WAIT
	CPU.wait;
}

void exec9C() {	// 9Ch PUSHF
	CPU.push16(CPU.FLAGS);
}

void exec9D() {	// 9Dh POPF
	CPU.FLAGS = CPU.pop16;
}

void exec9E() {	// 9Eh SAHF (Save AH to Flags)
	CPU.FLAG = CPU.AH;
}

void exec9F() {	// 9Fh LAHF (Load AH from Flags)
	CPU.AH = CPU.FLAG;
}

void execA0() {	// A0h MOV AL, MEM8
	int a = mmfu16_i;
	CPU.AL = mmfu8(address(getseg(CPU, SEG_DS), a));
}

void execA1() {	// A1h MOV AX, MEM16
	int a = mmfu16_i;
	CPU.AX = mmfu16(address(getseg(CPU, SEG_DS), a));
}

void execA2() {	// A2h MOV MEM8, AL
	int a = mmfu16_i;
	mmiu8(address(getseg(CPU, SEG_DS), a), CPU.AL);
}

void execA3() {	// A3h MOV MEM16, AX
	int a = mmfu16_i;
	mmiu16(address(getseg(CPU, SEG_DS), a), CPU.AX);
}

void execA4() {	// A4h MOVS DEST-STR8, SRC-STR8
	int a = address(CPU.ES, CPU.DI); // DEST
	int b = address(getseg(CPU, CPU.DS), CPU.SI); // SRC
	mmiu8(a, mmfu8(b));
	if (CPU.DF) {
		--CPU.SI;
		--CPU.DI;
	} else {
		++CPU.SI;
		++CPU.DI;
	}
}

void execA5() {	// A5h MOVS DEST-STR16, SRC-STR16
	int a = address(CPU.ES, CPU.DI); // DEST
	int b = address(getseg(CPU, CPU.DS), CPU.SI); // SRC
	mmiu16(a, mmfu16(b));
	if (CPU.DF) {
		--CPU.SI;
		--CPU.DI;
	} else {
		++CPU.SI;
		++CPU.DI;
	}
}

void execA6() {	// A6h CMPS DEST-STR8, SRC-STR8
	int a = address(CPU.ES, CPU.DI); // DEST
	int b = address(getseg(CPU, CPU.DS), CPU.SI); // SRC
	cpuf8_1(mmfu8(a) - mmfu8(b));
	if (CPU.DF) {
		--CPU.DI;
		--CPU.SI;
	} else {
		++CPU.DI;
		++CPU.SI;
	}
}

void execA7() {	// A7h CMPSW DEST-STR16, SRC-STR16
	int a = address(CPU.ES, CPU.DI); // DEST
	int b = address(getseg(CPU, CPU.DS), CPU.SI); // SRC
	cpuf16_1(mmfu16(a) - mmfu16(b));
	if (CPU.DF) {
		CPU.DI -= 2;
		CPU.SI -= 2;
	} else {
		CPU.DI += 2;
		CPU.SI += 2;
	}
}

void execA8() {	// A8h TEST AL, IMM8
	cpuf8_3(CPU.AL & mmfu8_i);
}

void execA9() {	// A9h TEST AX, IMM16
	cpuf16_3(CPU.AX & mmfu16_i);
}

void execAA() {	// AAh STOS DEST-STR8
	int a = address(CPU.ES, CPU.DI);
	mmiu8(a, CPU.AL);
	if (CPU.DF) --CPU.DI; else ++CPU.DI;
}

void execAB() {	// ABh STOS DEST-STR16
	int a = address(CPU.ES, CPU.DI);
	mmiu16(a, CPU.AX);
	if (CPU.DF) CPU.DI -= 2; else CPU.DI += 2;
}

void execAC() {	// ACh LODS SRC-STR8
	int a = address(getseg(CPU, CPU.DS), CPU.SI);
	CPU.AL = mmfu8(a);
	if (CPU.DF) --CPU.SI; else ++CPU.SI;
}

void execAD() {	// ADh LODS SRC-STR16
	int a = address(getseg(CPU, CPU.DS), CPU.SI);
	CPU.AX = mmfu16(a);
	if (CPU.DF) CPU.SI -= 2; else CPU.SI += 2;
}

void execAE() {	// AEh SCAS DEST-STR8
	cpuf8_1(CPU.AL - mmfu8(address(CPU.ES, CPU.DI)));
	if (CPU.DF) --CPU.DI; else ++CPU.DI;
}

void execAF() {	// AFh SCAS DEST-STR16
	cpuf16_1(CPU.AX - mmfu16(address(CPU.ES, CPU.DI)));
	if (CPU.DF) CPU.DI -= 2; else CPU.DI += 2;
}

void execB0() {	// B0h MOV AL, IMM8
	CPU.AL = mmfu8_i;
}

void execB1() {	// B1h MOV CL, IMM8
	CPU.CL = mmfu8_i;
}

void execB2() {	// B2h MOV DL, IMM8
	CPU.DL = mmfu8_i;
}

void execB3() {	// B3h MOV BL, IMM8
	CPU.BL = mmfu8_i;
}

void execB4() {	// B4h MOV AH, IMM8
	CPU.AH = mmfu8_i;
}

void execB5() {	// B5h MOV CH, IMM8
	CPU.CH = mmfu8_i;
}

void execB6() {	// B6h MOV DH, IMM8  
	CPU.DH = mmfu8_i;
}

void execB7() {	// B7h MOV BH, IMM8
	CPU.BH = mmfu8_i;
}

void execB8() {	// B8h MOV AX, IMM16
	CPU.AX = mmfu16_i;
}

void execB9() {	// B9h MOV CX, IMM16
	CPU.CX = mmfu16_i;
}

void execBA() {	// BAh MOV DX, IMM16
	CPU.DX = mmfu16_i;
}

void execBB() {	// BBh MOV BX, IMM16
	CPU.BX = mmfu16_i;
}

void execBC() {	// BCh MOV SP, IMM16
	CPU.SP = mmfu16_i;
}

void execBD() {	// BDh MOV BP, IMM16
	CPU.BP = mmfu16_i;
}

void execBE() {	// BEh MOV SI, IMM16
	CPU.SI = mmfu16_i;
}

void execBF() {	// BFh MOV DI, IMM16
	CPU.DI = mmfu16_i;
}

void execC2() {	// C2 RET IMM16 (NEAR)
	ushort sp = mmfi16_i;
	CPU.IP = CPU.pop16;
	CPU.SP += sp;
}

void execC3() {	// C3h RET (NEAR)
	CPU.IP = CPU.pop16;
}

void execC4() {	// C4h LES REG16, MEM16
	ubyte modrm = mmfu8_i;
	if ((modrm & MODRM_MOD) == MODRM_MOD_11) {
		execill;
		return;
	}
	int a = modrm16frm(modrm, 1);
	modrm16ireg(modrm, 1, a);
	CPU.segment = SEG_ES;
}

void execC5() {	// C5h LDS REG16, MEM16
	ubyte modrm = mmfu8_i;
	if ((modrm & MODRM_MOD) == MODRM_MOD_11) {
		execill;
		return;
	}
	int a = modrm16frm(modrm, 1);
	modrm16ireg(modrm, 1, a);
	CPU.segment = SEG_DS;
}

void execC6() {	// C6h MOV MEM8, IMM8
	ubyte modrm = mmfu8_i;
	if ((modrm & MODRM_REG) || (modrm & MODRM_MOD) == MODRM_MOD_11) {
		log_info("Invalid ModR/M for MOV MEM8");
		execill;
	}
	int a = modrm16rm(modrm);
	mmiu8(a, mmfu8_i);
}

void execC7() {	// C7h MOV MEM16, IMM16
	ubyte modrm = mmfu8_i;
	if ((modrm & MODRM_REG) || (modrm & MODRM_MOD) == MODRM_MOD_11) {
		log_info("Invalid ModR/M for MOV MEM8");
		execill;
	}
	int a = modrm16rm(modrm);
	mmiu16(a, mmfu16_i);
}

void execCA() {	// CAh RET IMM16 (FAR)
	uint addr = CPU.EIP;
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
}

void execCD() {	// CDh INT IMM8
	INT(mmfu8_i);
}

void execCE() {	// CEh INTO
	if (CPU.CF) INT(4);
}

void execCF() {	// CFh IRET
	CPU.IP = CPU.pop16;
	CPU.CS = CPU.pop16;
	CPU.FLAGS = CPU.pop16;
}

void execD0() {	// D0h GRP2 R/M8, 1
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	switch (modrm & MODRM_REG) {
	case MODRM_REG_000: // 000 - ROL
		a <<= 1;
		if (a & 0x100) {
			a |= 1; CPU.OF = 1;
		}
		break;
	case MODRM_REG_001: // 001 - ROR
		if (a & 1) {
			a |= 0x100; CPU.OF = 1;
		}
		a >>= 1;
		break;
	case MODRM_REG_010: // 010 - RCL
		a <<= 1;
		if (a & 0x200) {
			a |= 1; CPU.OF = 1;
		}
		break;
	case MODRM_REG_011: // 011 - RCR
		if (a & 1) {
			a |= 0x200; CPU.OF = 1;
		}
		a >>= 1;
		break;
	case MODRM_REG_100: // 100 - SAL/SHL
		a <<= 1;
		cpuf8_1(a);
		break;
	case MODRM_REG_101: // 101 - SHR
		a >>= 1;
		cpuf8_1(a);
		break;
	case MODRM_REG_111: // 111 - SAR
		if (a & 0x80) a |= 0x100;
		a >>= 1;
		cpuf8_1(a);
		break;
	default: // 110
		log_info("Invalid ModR/M for GRP2 R/M8, 1");
		execill;
		return;
	}
	modrm16irm(modrm, 0, a);
}

void execD1() {	// D1h GRP2 R/M16, 1
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	switch (modrm & MODRM_REG) {
	case MODRM_REG_000: // 000 - ROL
		a <<= 1;
		if (a & 0x1_0000) {
			a |= 1; CPU.OF = 1;
		}
		break;
	case MODRM_REG_001: // 001 - ROR
		if (a & 1) {
			a |= 0x1_0000; CPU.OF = 1;
		}
		a >>= 1;
		break;
	case MODRM_REG_010: // 010 - RCL
		a <<= 1;
		if (a & 0x2_0000) {
			a |= 1; CPU.OF = 1;
		}
		break;
	case MODRM_REG_011: // 011 - RCR
		if (a & 1) {
			a |= 0x2_0000; CPU.OF = 1;
		}
		a >>= 1;
		break;
	case MODRM_REG_100: // 100 - SAL/SHL
		a <<= 1;
		cpuf16_1(a);
		break;
	case MODRM_REG_101: // 101 - SHR
		a >>= 1;
		cpuf16_1(a);
		break;
	case MODRM_REG_111: // 111 - SAR
		if (a & 0x8000) a |= 0x1_0000;
		a >>= 1;
		cpuf16_1(a);
		break;
	default: // 110
		log_info("Invalid ModR/M for GRP2 R/M16, 1");
		execill;
		return;
	}
	modrm16irm(modrm, 1, a);
}

void execD2() {	// D2h GRP2 R/M8, CL
	ubyte rm = mmfu8_i;
	int c = CPU.CL;	/// Count
	if (CPU.model != CPU_8086) // vm8086 still falls here
		c &= 31; // 5 bits

	CPU.EIP += 2;
	if (c == 0) return; // NOP IF COUNT = 0

	int addr = modrm16rm(rm);
	__mi32 r = cast(__mi32)mmfu8(addr);

	switch (rm & MODRM_REG) {
	case MODRM_REG_000: // 000 - ROL
		r <<= c;
		if (r > 0xFF) {
			r |= r.u8[1]; CPU.OF = 1;
		}
		break;
	case MODRM_REG_001: // 001 - ROR
		r.u8[1] = r.u8[0];
		r >>= c;
		if (r.u8[1] == 0) { //TODO: Check accuracy
			CPU.OF = 1;
		}
		break;
	case MODRM_REG_010: //TODO: 010 - RCL
		break;
	case MODRM_REG_011: //TODO: 011 - RCR
		break;
	case MODRM_REG_100: // 100 - SAL/SHL
		break;
	case MODRM_REG_101: // 101 - SHR
		break;
	case MODRM_REG_111: // 111 - SAR
		break;
	default:
		log_info("Invalid ModR/M for GRP2 R/M8, CL");
		execill;
	}
	mmiu8(r, addr);
}

void execD3() {	// D3h GRP2 R/M16, CL
	ubyte rm = mmfu8_i;
	int c = CPU.CL;	/// Count
	if (CPU.model != CPU_8086) // vm8086 still falls here
		c &= 31; // 5 bits

	CPU.EIP += 2;
	if (c == 0) return; // NOP IF COUNT = 0

	int addr = modrm16rm(rm);
	__mi32 r = cast(__mi32)mmfu16(addr);

	switch (rm & MODRM_REG) {
	case MODRM_REG_000: // 000 - ROL
		r <<= c;
		if (r > 0xFF) {
			r |= r.u16[1]; CPU.OF = 1;
		}
		break;
	case MODRM_REG_001: // 001 - ROR
		r.u16[1] = r.u16[0];
		r >>= c;
		if (r.u16[1] == 0) { //TODO: Check accuracy
			CPU.OF = 1;
		}
		break;
	case MODRM_REG_010: //TODO: 010 - RCL
		break;
	case MODRM_REG_011: //TODO: 011 - RCR
		break;
	case MODRM_REG_100: // 100 - SAL/SHL
		break;
	case MODRM_REG_101: // 101 - SHR
		break;
	case MODRM_REG_111: // 111 - SAR
		break;
	default:
		log_info("Invalid ModR/M for GRP2 R/M16, CL");
		execill;
	}
	mmiu16(r, addr);
}

void execD4() {	// D4h AAM
	ubyte v = mmfu8_i;
	CPU.AH = cast(ubyte)(CPU.AL / v);
	CPU.AL = cast(ubyte)(CPU.AL % v);
	cpuf8_5(CPU.AL);
}

void execD5() {	// D5h AAD
	ubyte v = mmfu8_i;
	int r = CPU.AL + (CPU.AH * v);
	cpuf8_5(r);
	CPU.AL = cast(ubyte)r;
	CPU.AH = 0;
}

void execD7() {	// D7h XLAT SOURCE-TABLE
	CPU.AL = mmfu8(address(getseg(CPU, CPU.DS), CPU.BX) + CPU.AL);
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
	uint csip = mmfu32_i;
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
	CPU.lock = 0xF0;
}

void execF2() {	// F2h REPNE/REPNZ
	//TODO: Verify operation
	while (CPU.CX > 0) {
		execA6;
		--CPU.CX;
		if (CPU.ZF == 0) break;
	}
}

void execF3() {	// F3h REP/REPE/REPNZ
	ushort c = CPU.CX;
	ubyte op = mmfi8_i; // next op

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
	CPU.segment = SEG_NONE;
/*	if (c) {
		if (CPU.ZF && ((op & 6) != 6))
			// TODO: IP gets "previous IP"
	}*/
	CPU.EIP -= (c - 1);
}

void execF4() {	// F4h HLT
	CPU.level = 0;
}

void execF5() {	// F5h CMC
	CPU.CF = !CPU.CF;
}

void execF6() {	// F6h GRP3 R/M8
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	switch (modrm & MODRM_REG) {
	case MODRM_REG_000: // 000 - TEST
		cpuf8_3(a & mmfu8_i);
		return;
	case MODRM_REG_010: // 010 - NOT
		CPU.CF = a != 0;
		modrm16irm(modrm, 0, ~a);
		return;
	case MODRM_REG_011: // 011 - NEG
		CPU.CF = a != 0;
		a = cast(ubyte)-a;
		OF8(a); SF8(a); ZF16(a); PF8(a);
		modrm16irm(modrm, 0, a);
		return;
	case MODRM_REG_100: // 100 - MUL
		CPU.AX = cast(ushort)(CPU.AL * a);
		CPU.CF = CPU.OF = CPU.AH;
		return;
	case MODRM_REG_101: // 101 - IMUL
		CPU.AX = cast(ushort)(CPU.AL * cast(byte)a);
		CPU.CF = CPU.OF = CPU.AH;
		return;
	case MODRM_REG_110: // 110 - DIV
		if (a == 0) INT(0);
		CPU.AL = cast(ubyte)(CPU.AL / a);
		CPU.AH = cast(ubyte)(CPU.AL % a);
		return;
	case MODRM_REG_111: // 111 - IDIV
		if (a == 0) INT(0);
		CPU.AL = cast(ubyte)(CPU.AX / cast(byte)a);
		CPU.AH = cast(ubyte)(CPU.AX % cast(byte)a);
		return;
	default:
		log_info("Invalid ModR/M on GRP3_8");
		execill;
	}
}

void execF7() {	// F7h GRP3 R/M16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	switch (modrm & MODRM_REG) {
	case MODRM_REG_000: // 000 - TEST
		cpuf16_3(a & mmfu16_i);
		break;
	case MODRM_REG_010: // 010 - NOT
		CPU.CF = a != 0;
		modrm16irm(modrm, 1, ~a);
		break;
	case MODRM_REG_011: // 011 - NEG
		CPU.CF = a != 0;
		a = cast(ushort)-a;
		OF16(a); SF16(a); ZF16(a); PF16(a);
		modrm16irm(modrm, 1, a);
		break;
	case MODRM_REG_100: // 100 - MUL
		__mi32 d = cast(__mi32)(CPU.AX * a);
		CPU.DX = d.u16[1];
		CPU.AX = d.u16[0];
		CPU.CF = CPU.OF = CPU.DX != 0;
		break;
	case MODRM_REG_101: // 101 - IMUL
		__mi32 d = cast(__mi32)(CPU.AX * cast(short)a);
		CPU.DX = d.u16[1];
		CPU.AX = d.u16[0];
		CPU.CF = CPU.OF = CPU.DX != 0;
		break;
	case MODRM_REG_110: // 110 - DIV
		if (a == 0) INT(0);
		__mi32 d = void;
		d.u16[1] = CPU.DX; d.u16[0] = CPU.AX;
		CPU.AX = cast(ushort)(d / a);
		CPU.DX = cast(ushort)(d % a);
		break;
	case MODRM_REG_111: // 111 - IDIV
		if (a == 0) INT(0);
		__mi32 d = void;
		d.u16[1] = CPU.DX; d.u16[0] = CPU.AX;
		CPU.AX = cast(ushort)(d / cast(short)a);
		CPU.DX = cast(ushort)(d % cast(short)a);
		break;
	default:
		log_info("Invalid ModR/M on GRP3_8");
		execill;
	}
}

void execF8() {	// F8h CLC
	CPU.CF = 0;
}

void execF9() {	// F9h STC
	CPU.CF = 1;
}

void execFA() {	// FAh CLI
	CPU.IF = 0;
}

void execFB() {	// FBh STI
	CPU.IF = 1;
}

void execFC() {	// FCh CLD
	CPU.DF = 0;
}

void execFD() {	// FDh STD
	CPU.DF = 1;
}

void execFE() {	// FEh GRP4 R/M8
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 0);
	switch (modrm & MODRM_REG) {
	case MODRM_REG_000: // 000 - INC
		++a;
		break;
	case MODRM_REG_001: // 001 - DEC
		--a;
		break;
	default:
		log_info("Invalid ModR/M on GRP4_8");
		execill;
		return;
	}
	cpuf16_2(a);
	modrm16irm(modrm, 0, a);
}

void execFF() {	// FFh GRP5 R/M16
	ubyte modrm = mmfu8_i;
	int a = modrm16frm(modrm, 1);
	switch (modrm & MODRM_REG) {
	case MODRM_REG_000: // 000 - INC
		++a;
		cpuf16_2(a);
		modrm16irm(modrm, 1, a);
		return;
	case MODRM_REG_001: // 001 - DEC
		--a;
		cpuf16_2(a);
		modrm16irm(modrm, 1, a);
		return;
	case MODRM_REG_010: // 010 - CALL R/M16 (near) -- Indirect within segment
		CPU.push16(CPU.IP);
		CPU.IP = cast(ushort)a;
		return;
	case MODRM_REG_011: // 011 - CALL MEM16 (far) -- Indirect outside segment
		if ((modrm & MODRM_MOD) == MODRM_MOD_11) {
			execill;
			return;
		}
		uint csip = mmfu32(modrm16rm(modrm));
		CPU.push16(CPU.CS);
		CPU.push16(CPU.IP);
		CPU.CS = cast(ushort)csip;
		CPU.IP = csip >> 16;
		return;
	case MODRM_REG_100: // 100 - JMP R/M16 (near) -- Indirect within segment
		CPU.IP = cast(ushort)(a + 2);
		return;
	case MODRM_REG_101: // 101 - JMP MEM16 (far) -- Indirect outside segment
		//TODO: Validate
		CPU.IP = cast(ushort)address(mmfu16(a), a + 2);
		return;
	case MODRM_REG_110: // 110 - PUSH MEM16
		if ((modrm & MODRM_MOD) == MODRM_MOD_11) {
			execill;
			return;
		}
		CPU.push16(mmfu16(modrm16rm(modrm)));
		return;
	default:
		log_info("Invalid ModR/M on GRP5_16");
		execill;
	}
}

void execill() {	// Illegal instruction
	INT(6);
}