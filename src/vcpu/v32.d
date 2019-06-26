/**
 * Protected-mode instructions.
 */
module vcpu.v32; // 80386/80486+

import vcpu.core, vcpu.mm;
import vcpu.v16 : exec16;
import vcpu.protection, vcpu.utils, vdos.interrupts;
import logger;

extern (C):

pragma(inline, true)
void exec32(ubyte op) {
	PROT_MAP[op]();
}

void v32_00() {	//TODO: 00h ADD R/M8, REG8
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

void v32_01() {	//TODO: 01h ADD R/M32, REG32
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm32(rm, 1);
	long r = mmfu32(addr);
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
	cpuf32_1(r);
	mmiu32(cast(int)r, addr);
	CPU.EIP += 2;
}

void v32_02() {	//TODO: 02h ADD REG8, R/M8
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

void v32_03() {	//TODO: 03h ADD REG16, R/M16
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

void v32_04() {	//TODO: 04h ADD AL, IMM8
	const int r = CPU.AL + mmfu8_i;
	cpuf8_1(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v32_05() {	//TODO: 05h ADD AX, IMM16
	const int r = CPU.AX + mmfu16_i;
	cpuf16_1(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 2;
}

void v32_06() {	//TODO: 06h PUSH ES
	CPU.push16(CPU.ES);
	++CPU.EIP;
}

void v32_07() {	//TODO: 07h POP ES
	CPU.ES = CPU.pop16;
	++CPU.EIP;
}

void v32_08() {	//TODO: 08h OR R/M8, REG8
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

void v32_09() {	//TODO: 09h OR R/M16, REG16
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

void v32_0A() {	//TODO: 0Ah OR REG8, R/M8
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

void v32_0B() {	//TODO: 0Bh OR REG16, R/M16
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

void v32_0C() {	//TODO: 0Ch OR AL, IMM8
	const int r = CPU.AL | mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v32_0D() {	//TODO: 0Dh OR AX, IMM16
	const int r = CPU.AX | mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v32_0E() {	//TODO: 0Eh PUSH CS
	CPU.push16(CPU.CS);
	++CPU.EIP;
}

void v32_0F() {	//TODO: 0Fh Two-byte escape
	++CPU.EIP;
	//TODO: check memory bound
	switch (MEMORY[CPU.EIP]) {
	case 0x00: //TODO: GRP6
	
		break;
	case 0x01: //TODO: GRP7
	
		break;
	case 0x02: //TODO: LAR REG32, R/M16
	
		break;
	case 0x03: //TODO: LSL REG32, R/M16
	
		break;
	case 0x05: // LOADALL (i286), undocumented
		//TODO: #GP on != CPU_MDOEL_286
		//CPU.MSW = mmfu16(0x806); // Machine Status Word
		//CPU.TR = mmfu16(0x816); // Task Register
		CPU.FLAG = mmfu16(0x818);
		CPU.IP = mmfu16(0x81A);
		//CPU.LDTR = mmfu16(0x81C); // Local Descriptor Table Register
		CPU.DS = mmfu16(0x81E); // segments
		CPU.SS = mmfu16(0x820);
		CPU.CS = mmfu16(0x822);
		CPU.ES = mmfu16(0x824);
		CPU.DI = mmfu16(0x826); // index/pointer
		CPU.SI = mmfu16(0x828);
		CPU.BP = mmfu16(0x82A);
		CPU.SP = mmfu16(0x82C);
		CPU.BX = mmfu16(0x82E); // generic
		CPU.DX = mmfu16(0x830);
		CPU.CX = mmfu16(0x832);
		CPU.AX = mmfu16(0x834);
		//CPU. = mmfu16(0x836); // es // seg. desc.
		//CPU. = mmfu32(0x838);
		//CPU. = mmfu16(0x83C); // cs
		//CPU. = mmfu32(0x83E);
		//CPU. = mmfu16(0x842); // ss
		//CPU. = mmfu32(0x844);
		//CPU. = mmfu16(0x848); // ds
		//CPU. = mmfu32(0x84C);
		//CPU. = mmfu16(0x84E); // gpt // seg. desc.
		//CPU. = mmfu32(0x850);
		//CPU. = mmfu16(0x854); // ldt
		//CPU. = mmfu32(0x856);
		//CPU. = mmfu16(0x85A); // idt
		//CPU. = mmfu32(0x85C);
		//CPU. = mmfu16(0x860); // tss
		//CPU. = mmfu32(0x862);
		++CPU.EIP;
		break;
	case 0x06: //TODO: CLTS
		
		break;
	case 0x07: // LOADALL (i386), undocumented
		//TODO: #GP on != CPU_MDOEL_386
		const uint ad = address(ES, EDI); //OP: uint* from MEMORY
		CPU.CR0 = mmfu32(ad);
		CPU.EFLAGS = mmfu32(ad + 4);
		CPU.EIP = mmfu32(ad + 8);
		CPU.EDI = mmfu32(ad + 0xC);
		CPU.ESI = mmfu32(ad + 0x10);
		CPU.EBP = mmfu32(ad + 0x14);
		CPU.ESP = mmfu32(ad + 0x18);
		CPU.EBX = mmfu32(ad + 0x1C);
		CPU.EDX = mmfu32(ad + 0x20);
		CPU.ECX = mmfu32(ad + 0x24);
		CPU.EAX = mmfu32(ad + 0x28);
		CPU.DR6 = mmfu32(ad + 0x2C);
		CPU.DR7 = mmfu32(ad + 0x30);
		//CPU.TR = mmfu32(ad + 0x34); // Task Register / State Selector
		//CPU.LDTR = mmfu32(ad + 0x38); // Local Descriptor Table Register
		CPU.GS = mmfu16(ad + 0x3C);
		CPU.FS = mmfu16(ad + 0x3E);
		CPU.DS = mmfu16(ad + 0x44);
		CPU.SS = mmfu16(ad + 0x48);
		CPU.CS = mmfu16(ad + 0x4C);
		CPU.ES = mmfu16(ad + 0x50);
		//CPU.TSS = 12B desc
		//CPU.IDT = 12B desc
		//CPU.GDT = 12B desc
		//CPU.LDT = 12B desc
		//CPU.GS = 12B desc
		//CPU.FS = 12B desc
		//CPU.DS = 12B desc
		//CPU.SS = 12B desc
		//CPU.CS = 12B desc
		//CPU.ES = 12B desc
		++CPU.EIP;
		break;
	case 0x08: //TODO: INVD
	
		break;
	case 0x09: //TODO: WBINVD
	
		break;
	case 0x20: //TODO: MOV CR*, REG32
	
		break;
	case 0x21: //TODO: MOV DR*, REG32
	
		break;
	case 0x22: //TODO: MOV REG32, CR*
	
		break;
	case 0x23: //TODO: MOV REG32, DR*
	
		break;
	case 0x24: //TODO: MOV TR*, REG32
	
		break;
	case 0x26: //TODO: MOV REG32, TR*
	
		break;
	case 0x80: //TODO: JO IMM32
	
		break;
	case 0x81: //TODO: JNO IMM32
	
		break;
	case 0x82: //TODO: JB IMM32
	
		break;
	case 0x83: //TODO: JNB IMM32
	
		break;
	case 0x84: //TODO: JZ IMM32
	
		break;
	case 0x85: //TODO: JNZ IMM32
	
		break;
	case 0x86: //TODO: JBE IMM32
	
		break;
	case 0x87: //TODO: JNBE IMM32
	
		break;
	case 0x88: //TODO: JS IMM32
	
		break;
	case 0x89: //TODO: JNO IMM32
	
		break;
	case 0x8A: //TODO: JP IMM32
	
		break;
	case 0x8B: //TODO: JNP IMM32
	
		break;
	case 0x8C: //TODO: JL IMM32
	
		break;
	case 0x8D: //TODO: JNL IMM32
	
		break;
	case 0x8E: //TODO: JLE IMM32
	
		break;
	case 0x8F: //TODO: JNLE IMM32
	
		break;
	case 0x90: //TODO: SETO IMM32
	
		break;
	case 0x91: //TODO: SETNO IMM32
	
		break;
	case 0x92: //TODO: SETB IMM32
	
		break;
	case 0x93: //TODO: SETNB IMM32
	
		break;
	case 0x94: //TODO: SETZ IMM32
	
		break;
	case 0x95: //TODO: SETNZ IMM32
	
		break;
	case 0x96: //TODO: SETBE IMM32
	
		break;
	case 0x97: //TODO: SETNBE IMM32
	
		break;
	case 0x98: //TODO: SETS IMM32
	
		break;
	case 0x99: //TODO: SETNO IMM32
	
		break;
	case 0x9A: //TODO: SETP IMM32
	
		break;
	case 0x9B: //TODO: SETNP IMM32
	
		break;
	case 0x9C: //TODO: SETL IMM32
	
		break;
	case 0x9D: //TODO: SETNL IMM32
	
		break;
	case 0x9E: //TODO: SETLE IMM32
	
		break;
	case 0x9F: //TODO: SETNLE IMM32
	
		break;
	case 0xA0: //TODO: PUSH FS
	
		break;
	case 0xA1: //TODO: POP FS
	
		break;
	case 0xA3: //TODO: BT R/M32, REG32
	
		break;
	case 0xA4: //TODO: SHLD R/M32, IMM32
	
		break;
	case 0xA5: //TODO: SHLD R/M32, CR*
	
		break;
	case 0xA6: //TODO: CMPXCHG R/M8, REG8
	
		break;
	case 0xA7: //TODO: CMPXCHG REG32, R/M32
	
		break;
	case 0xA8: //TODO: PUSH GS
	
		break;
	case 0xA9: //TODO: POP GS
	
		break;
	case 0xAB: //TODO: BTS R/M32, REG32
	
		break;
	case 0xAC: //TODO: SHRD R/M32, IMM32
	
		break;
	case 0xAD: //TODO: SHRD R/M32, CR*
	
		break;
	case 0xAF: //TODO: IMUL REG32, R/M32
	
		break;
	case 0xB2: //TODO: LSS MEM32/48
	
		break;
	case 0xB3: //TODO: BTR R/M32, REG32
	
		break;
	case 0xB4: //TODO: LFS MEM32/48
	
		break;
	case 0xB5: //TODO: LGS MEM32/48
	
		break;
	case 0xB6: //TODO: MOVZX REG32, R/M8
	
		break;
	case 0xB7: //TODO: MOVZX REG32, R/M16
	
		break;
	case 0xBA: //TODO: GRP8 R/M32, IMM8
	
		break;
	case 0xBB: //TODO: BTC R/M32, REG32
	
		break;
	case 0xBC: //TODO: BSF REG32, R/M32
	
		break;
	case 0xBD: //TODO: BSR REG32, R/M32
	
		break;
	case 0xBE: //TODO: MOVSX REG32, R/M8
	
		break;
	case 0xBF: //TODO: MOVSX REG32, R/M16
	
		break;
	case 0xC0: //TODO: XADD R/M8, REG8
	
		break;
	case 0xC1: //TODO: XADD R/M32, REG32
	
		break;
	case 0xC8: //TODO: BSWAP EAX
	
		break;
	case 0xC9: //TODO: BSWAP ECX
	
		break;
	case 0xCA: //TODO: BSWAP EDX
	
		break;
	case 0xCB: //TODO: BSWAP EBX
	
		break;
	case 0xCC: //TODO: BSWAP ESP
	
		break;
	case 0xCD: //TODO: BSWAP EBP
	
		break;
	case 0xCE: //TODO: BSWAP ESI
	
		break;
	case 0xCF: //TODO: BSWAP EDI
	
		break;
	default:
		v32_illegal;
	}
}

void v32_10() {	//TODO: 10h ADC R/M8, REG8
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

void v32_11() {	//TODO: 11h ADC R/M16, REG16
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

void v32_12() {	//TODO: 12h ADC REG8, R/M8
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

void v32_13() {	//TODO: 13h ADC REG16, R/M16
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

void v32_14() {	//TODO: 14h ADC AL, IMM8
	int r = CPU.AL + mmfu8_i;
	cpuf8_1(r);
	if (CPU.CF) ++r;
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v32_15() {	//TODO: 15h ADC AX, IMM16
	int r = CPU.AX + mmfu16_i;
	cpuf16_1(r);
	if (CPU.CF) ++r;
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v32_16() {	//TODO: 16h PUSH SS
	CPU.push16(CPU.SS);
	++CPU.EIP;
}

void v32_17() {	//TODO: 17h POP SS
	CPU.SS = CPU.pop16;
	++CPU.EIP;
}

void v32_18() {	//TODO: 18h SBB R/M8, REG8
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

void v32_19() {	//TODO: 19h SBB R/M16, REG16
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

void v32_1A() {	//TODO: 1Ah SBB REG8, R/M8
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

void v32_1B() {	//TODO: 1Bh SBB REG16, R/M16
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

void v32_1C() {	//TODO: 1Ch SBB AL, IMM8
	int r = CPU.AL - mmfu8_i;
	if (CPU.CF) --r;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v32_1D() {	//TODO: 1Dh SBB AX, IMM16
	int r = CPU.AX - mmfu16_i;
	if (CPU.CF) --r;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v32_1E() {	//TODO: 1Eh PUSH DS
	CPU.push16(CPU.DS);
	++CPU.EIP;
}

void v32_1F() {	//TODO: 1Fh POP DS
	CPU.DS = CPU.pop16;
	++CPU.EIP;
}

void v32_20() {	//TODO: 20h AND R/M8, REG8
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

void v32_21() {	//TODO: 21h AND R/M16, REG16
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

void v32_22() {	//TODO: 22h AND REG8, R/M8
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

void v32_23() {	//TODO: 23h AND REG16, R/M16
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

void v32_24() {	//TODO: 24h AND AL, IMM8
	const int r = CPU.AL & mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v32_25() {	//TODO: 25h AND AX, IMM16
	const int r = CPU.AX & mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v32_26() {	//TODO: 26h ES: (Segment override prefix)
	CPU.Segment = SEG_ES;
	++CPU.EIP;
}

void v32_27() {	//TODO: 27h DAA
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

void v32_28() {	//TODO: 28h SUB R/M8, REG8
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

void v32_29() {	//TODO: 29h SUB R/M16, REG16
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

void v32_2A() {	//TODO: 2Ah SUB REG8, R/M8
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

void v32_2B() {	//TODO: 2Bh SUB REG16, R/M16
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

void v32_2C() {	//TODO: 2Ch SUB AL, IMM8
	const int r = CPU.AL - mmfu8_i;
	cpuf8_1(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v32_2D() {	//TODO: 2Dh SUB AX, IMM16
	const int r = CPU.AX - mmfu16_i;
	cpuf16_1(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v32_2E() {	//TODO: 2Eh CS:
	CPU.Segment = SEG_CS;
	++CPU.EIP;
}

void v32_2F() {	//TODO: 2Fh DAS
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

void v32_30() {	//TODO: 30h XOR R/M8, REG8
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

void v32_31() {	//TODO: 31h XOR R/M16, REG16
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

void v32_32() {	//TODO: 32h XOR REG8, R/M8
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

void v32_33() {	//TODO: 33h XOR REG16, R/M16
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

void v32_34() {	//TODO: 34h XOR AL, IMM8
	const int r = CPU.AL ^ mmfu8_i;
	cpuf8_3(r);
	CPU.AL = cast(ubyte)r;
	CPU.EIP += 2;
}

void v32_35() {	//TODO: 35h XOR AX, IMM16
	const int r = CPU.AX ^ mmfu16_i;
	cpuf16_3(r);
	CPU.AX = cast(ushort)r;
	CPU.EIP += 3;
}

void v32_36() {	//TODO: 36h SS:
	CPU.Segment = SEG_SS;
	++CPU.EIP;
}

void v32_37() {	//TODO: 37h AAA
	if (((CPU.AL & 0xF) > 9) || CPU.AF) {
		CPU.AX += 0x106;
		CPU.AF = CPU.CF = 1;
	} else CPU.AF = CPU.CF = 0;
	CPU.AL &= 0xF;
	++CPU.EIP;
}

void v32_38() {	//TODO: 38h CMP R/M8, REG8
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

void v32_39() {	//TODO: 39h CMP R/M16, REG16
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

void v32_3A() {	//TODO: 3Ah CMP REG8, R/M8
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

void v32_3B() {	//TODO: 3Bh CMP REG16, R/M16
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

void v32_3C() {	//TODO: 3Ch CMP AL, IMM8
	cpuf8_1(CPU.AL - mmfu8_i);
	CPU.EIP += 2;
}

void v32_3D() {	//TODO: 3Dh CMP AX, IMM16
	cpuf16_1(CPU.AX - mmfu16_i);
	CPU.EIP += 3;
}

void v32_3E() {	//TODO: 3Eh DS:
	CPU.Segment = SEG_DS;
	++CPU.EIP;
}

void v32_3F() {	//TODO: 3Fh AAS
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

void v32_40() {	//TODO: 40h INC AX
	const int r = CPU.AX + 1;
	cpuf16_2(r);
	CPU.AX = cast(ubyte)r;
	++CPU.EIP;
}

void v32_41() {	//TODO: 41h INC CX
	const int r = CPU.CX + 1;
	cpuf16_2(r);
	CPU.CX = cast(ushort)r;
	++CPU.EIP;
}

void v32_42() {	//TODO: 42h INC DX
	const int r = CPU.DX + 1;
	cpuf16_2(r);
	CPU.DX = cast(ushort)r;
	++CPU.EIP;
}

void v32_43() {	//TODO: 43h INC BX
	const int r = CPU.BX + 1;
	cpuf16_2(r);
	CPU.BX = cast(ushort)r;
	++CPU.EIP;
}

void v32_44() {	//TODO: 44h INC SP
	const int r = CPU.SP + 1;
	cpuf16_2(r);
	CPU.SP = cast(ushort)r;
	++CPU.EIP;
}

void v32_45() {	//TODO: 45h INC BP
	const int r = CPU.BP + 1;
	cpuf16_2(r);
	CPU.BP = cast(ushort)r;
	++CPU.EIP;
}

void v32_46() {	//TODO: 46h INC SI
	const int r = CPU.SI + 1;
	cpuf16_2(r);
	CPU.SI = cast(ushort)r;
	++CPU.EIP;
}

void v32_47() {	//TODO: 47h INC DI
	const int r = CPU.DI + 1;
	cpuf16_2(r);
	CPU.DI = cast(ushort)r;
	++CPU.EIP;
}

void v32_48() {	//TODO: 48h DEC AX
	const int r = CPU.AX - 1;
	cpuf16_2(r);
	CPU.AX = cast(ushort)r;
	++CPU.EIP;
}

void v32_49() {	//TODO: 49h DEC CX
	const int r = CPU.CX - 1;
	cpuf16_2(r);
	CPU.CX = cast(ushort)r;
	++CPU.EIP;
}

void v32_4A() {	//TODO: 4Ah DEC DX
	const int r = CPU.DX - 1;
	cpuf16_2(r);
	CPU.DX = cast(ushort)r;
	++CPU.EIP;
}

void v32_4B() {	//TODO: 4Bh DEC BX
	const int r = CPU.BX - 1;
	cpuf16_2(r);
	CPU.BX = cast(ushort)r;
	++CPU.EIP;
}

void v32_4C() {	//TODO: 4Ch DEC SP
	const int r = CPU.SP - 1;
	cpuf16_2(r);
	CPU.SP = cast(ushort)r;
	++CPU.EIP;
}

void v32_4D() {	//TODO: 4Dh DEC BP
	const int r = CPU.BP - 1;
	cpuf16_2(r);
	CPU.BP = cast(ushort)r;
	++CPU.EIP;
}

void v32_4E() {	//TODO: 4Eh DEC SI
	const int r = CPU.SI - 1;
	cpuf16_2(r);
	CPU.SI = cast(ushort)r;
	++CPU.EIP;
}

void v32_4F() {	//TODO: 4Fh DEC DI
	const int r = CPU.DI - 1;
	cpuf16_2(r);
	CPU.DI = cast(ushort)r;
	++CPU.EIP;
}

void v32_50() {	//TODO: 50h PUSH AX
	CPU.push16(CPU.AX);
	++CPU.EIP;
}

void v32_51() {	//TODO: 51h PUSH CX
	CPU.push16(CPU.CX);
	++CPU.EIP;
}

void v32_52() {	//TODO: 52h PUSH DX
	CPU.push16(CPU.DX);
	++CPU.EIP;
}

void v32_53() {	//TODO: 53h PUSH BX
	CPU.push16(CPU.BX);
	++CPU.EIP;
}

void v32_54() {	//TODO: 54h PUSH SP
	CPU.push16(CPU.SP);
	++CPU.EIP;
}

void v32_55() {	//TODO: 55h PUSH BP
	CPU.push16(CPU.BP);
	++CPU.EIP;
}

void v32_56() {	//TODO: 56h PUSH SI
	CPU.push16(CPU.SI);
	++CPU.EIP;
}

void v32_57() {	//TODO: 57h PUSH DI
	CPU.push16(CPU.DI);
	++CPU.EIP;
}

void v32_58() {	//TODO: 58h POP AX
	CPU.AX = CPU.pop16;
	++CPU.EIP;
}

void v32_59() {	//TODO: 59h POP CX
	CPU.CX = CPU.pop16;
	++CPU.EIP;
}

void v32_5A() {	//TODO: 5Ah POP DX
	CPU.DX = CPU.pop16;
	++CPU.EIP;
}

void v32_5B() {	//TODO: 5Bh POP BX
	CPU.BX = CPU.pop16;
	++CPU.EIP;
}

void v32_5C() {	//TODO: 5Ch POP SP
	CPU.SP = CPU.pop16;
	++CPU.EIP;
}

void v32_5D() {	//TODO: 5Dh POP BP
	CPU.BP = CPU.pop16;
	++CPU.EIP;
}

void v32_5E() {	//TODO: 5Eh POP SI
	CPU.SI = CPU.pop16;
	++CPU.EIP;
}

void v32_5F() {	//TODO: 5Fh POP DI
	CPU.DI = CPU.pop16;
	++CPU.EIP;
}

void v32_66() {	//TODO: 66h OPERAND OVERRIDE
	//TODO: CHECK ACCESS
	exec16(MEMORY[CPU.EIP]);
	++CPU.EIP;
}

void v32_67() {	//TODO: 67h ADDRESS OVERRIDE
	//TODO: CPU.AddressPrefix
	++CPU.EIP;
}

void v32_70() {	//TODO: 70h JO SHORT-LABEL
	CPU.EIP += CPU.OF ? mmfi8_i + 2 : 2;
}

void v32_71() {	//TODO: 71h JNO SHORT-LABEL
	CPU.EIP += CPU.OF ? 2 : mmfi8_i + 2;
}

void v32_72() {	//TODO: 72h JB/JNAE/JC SHORT-LABEL
	CPU.EIP += CPU.CF ? mmfi8_i + 2 : 2;
}

void v32_73() {	//TODO: 73h JNB/JAE/JNC SHORT-LABEL
	CPU.EIP += CPU.CF ? 2 : mmfi8_i + 2;
}

void v32_74() {	//TODO: 74h JE/NZ SHORT-LABEL
	CPU.EIP += CPU.ZF ? mmfi8_i + 2 : 2;
}

void v32_75() {	//TODO: 75h JNE/JNZ SHORT-LABEL
	CPU.EIP += CPU.ZF ? 2 : mmfi8_i + 2;
}

void v32_76() {	//TODO: 76h JBE/JNA SHORT-LABEL
	CPU.EIP += (CPU.CF || CPU.ZF) ? mmfi8_i + 2 : 2;
}

void v32_77() {	//TODO: 77h JNBE/JA SHORT-LABEL
	CPU.EIP += CPU.CF == 0 && CPU.ZF == 0 ? mmfi8_i + 2 : 2;
}

void v32_78() {	//TODO: 78h JS SHORT-LABEL
	CPU.EIP += CPU.SF ? mmfi8_i + 2 : 2;
}

void v32_79() {	//TODO: 79h JNS SHORT-LABEL
	CPU.EIP += CPU.SF ? 2 : mmfi8_i + 2;
}

void v32_7A() {	//TODO: 7Ah JP/JPE SHORT-LABEL
	CPU.EIP += CPU.PF ? mmfi8_i + 2 : 2;
}

void v32_7B() {	//TODO: 7Bh JNP/JPO SHORT-LABEL
	CPU.EIP += CPU.PF ? 2 : mmfi8_i + 2;
}

void v32_7C() {	//TODO: 7Ch JL/JNGE SHORT-LABEL
	CPU.EIP += CPU.SF != CPU.OF ? mmfi8_i + 2 : 2;
}

void v32_7D() {	//TODO: 7Dh JNL/JGE SHORT-LABEL
	CPU.EIP += CPU.SF == CPU.OF ? mmfi8_i + 2 : 2;
}

void v32_7E() {	//TODO: 7Eh JLE/JNG SHORT-LABEL
	CPU.EIP += CPU.SF != CPU.OF || CPU.ZF ? mmfi8_i + 2 : 2;
}

void v32_7F() {	//TODO: 7Fh JNLE/JG SHORT-LABEL
	CPU.EIP += CPU.SF == CPU.OF && CPU.ZF == 0 ? mmfi8_i + 2 : 2;
}

void v32_80() {	//TODO: 80h GRP1 R/M8, IMM8
	const ubyte rm = mmfu8_i; //TODO: Get ModR/M byte
	const ushort im = mmfu8_i(1);
	const int addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) { //TODO: REG
	case RM_REG_000: //TODO: 000 - ADD
		r += im; mmiu16(r, addr); break;
	case RM_REG_001: //TODO: 001 - OR
		r |= im; mmiu16(r, addr); break;
	case RM_REG_010: //TODO: 010 - ADC
		r += im; if (CPU.CF) ++r; mmiu16(r, addr); break;
	case RM_REG_011: //TODO: 011 - SBB
		r -= im; if (CPU.CF) --r; mmiu16(r, addr); break;
	case RM_REG_100: //TODO: 100 - AND
		r &= im; mmiu16(r, addr); break;
	case RM_REG_101: //TODO: 101 - SUB
		r -= im; mmiu16(r, addr); break;
	case RM_REG_110: //TODO: 110 - XOR
		r ^= im; mmiu16(r, addr); break;
	case RM_REG_111: //TODO: 111 - CMP
		r -= im; break;
	default:
		log_info("Invalid ModR/M from GRP1_8");
		v32_illegal;
	}
	cpuf8_1(r);
	CPU.EIP += 3;
}

void v32_81() {	//TODO: 81h GRP1 R/M16, IMM16
	const ubyte rm = mmfu8_i; //TODO: Get ModR/M byte
	const ushort im = mmfu16_i(1);
	const int addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) { //TODO: REG
	case RM_REG_000: //TODO: 000 - ADD
		r += im; mmiu16(r, addr); break;
	case RM_REG_001: //TODO: 001 - OR
		r |= im; mmiu16(r, addr); break;
	case RM_REG_010: //TODO: 010 - ADC
		r += im; if (CPU.CF) ++r; mmiu16(r, addr); break;
	case RM_REG_011: //TODO: 011 - SBB
		r -= im; if (CPU.CF) --r; mmiu16(r, addr); break;
	case RM_REG_100: //TODO: 100 - AND
		r &= im; mmiu16(r, addr); break;
	case RM_REG_101: //TODO: 101 - SUB
		r -= im; mmiu16(r, addr); break;
	case RM_REG_110: //TODO: 110 - XOR
		r ^= im; mmiu16(r, addr); break;
	case RM_REG_111: //TODO: 111 - CMP
		r -= im;  break;
	default:
		log_info("Invalid ModR/M from GRP1_16");
		v32_illegal;
	}
	cpuf16_1(r);
	CPU.EIP += 4;
}

void v32_82() {	//TODO: 82h GRP2 R/M8, IMM8
	const ubyte rm = mmfu8_i; //TODO: Get ModR/M byte
	const ushort im = mmfu8_i(1);
	const int addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) { //TODO: ModRM REG
	case RM_REG_000: //TODO: 000 - ADD
		r += im; mmiu8(r, addr); break;
	case RM_REG_010: //TODO: 010 - ADC
		r += im; if (CPU.CF) ++r; mmiu8(r, addr); break;
	case RM_REG_011: //TODO: 011 - SBB
		r -= im; if (CPU.CF) --r; mmiu8(r, addr); break;
	case RM_REG_101: //TODO: 101 - SUB
		r -= im; mmiu8(r, addr); break;
	case RM_REG_111: //TODO: 111 - CMP
		r -= im; break;
	default:
		log_info("Invalid ModR/M for GRP2_8");
		v32_illegal;
	}
	cpuf8_1(r);
	CPU.EIP += 3;
}

void v32_83() {	//TODO: 83h GRP2 R/M16, IMM8
	const ubyte rm = mmfu8_i; //TODO: Get ModR/M byte
	const ushort im = mmfu8_i(1);
	const int addr = mmrm16(rm, 1);
	int r = mmfu8(addr);
	switch (rm & RM_REG) { //TODO: ModRM REG
	case RM_REG_000: //TODO: 000 - ADD
		r += im; mmiu16(r, addr); break;
	case RM_REG_010: //TODO: 010 - ADC
		r += im; if (CPU.CF) ++r; mmiu16(r, addr);
		break;
	case RM_REG_011: //TODO: 011 - SBB
		r -= im; if (CPU.CF) --r; mmiu16(r, addr);
		break;
	case RM_REG_101: //TODO: 101 - SUB
		r -= im; mmiu16(r, addr); break;
	case RM_REG_111: //TODO: 111 - CMP
		r -= im; break;
	default:
		log_info("Invalid ModR/M for GRP2_16");
		v32_illegal;
	}
	cpuf16_1(r);
	CPU.EIP += 3;
}

void v32_84() {	//TODO: 84h TEST R/M8, REG8
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

void v32_85() {	//TODO: 85h TEST R/M16, REG16
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

void v32_86() {	//TODO: 86h XCHG REG8, R/M8
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm);
	const ubyte s = mmfu8(addr);
	//TODO: temp <- REG
	//TODO: REG  <- MEM
	//TODO: MEM  <- temp
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

void v32_87() {	//TODO: 87h XCHG REG16, R/M16
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
	//TODO: temp <- REG
	//TODO: REG  <- MEM
	//TODO: MEM  <- temp
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

void v32_88() {	//TODO: 88h MOV R/M8, REG8
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

void v32_89() {	//TODO: 89h MOV R/M16, REG16
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

void v32_8A() {	//TODO: 8Ah MOV REG8, R/M8
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

void v32_8B() {	//TODO: 8Bh MOV REG16, R/M16
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

void v32_8C() {	//TODO: 8Ch MOV R/M16, SEGREG
	//TODO: MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
	const byte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
	switch (rm & RM_REG) { //TODO: if REG[3] is clear, trip to default
	case RM_REG_100: mmiu16(CPU.ES, addr); break;
	case RM_REG_101: mmiu16(CPU.CS, addr); break;
	case RM_REG_110: mmiu16(CPU.SS, addr); break;
	case RM_REG_111: mmiu16(CPU.DS, addr); break;
	default: //TODO: when bit 6 is clear (REG[3])
		log_info("Invalid ModR/M for SEGREG->RM");
		v32_illegal;
	}
	CPU.EIP += 2;
}

void v32_8D() {	//TODO: 8Dh LEA REG16, MEM16
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
	default: //TODO: Never happens
	}
	CPU.EIP += 2;
}

void v32_8E() {	//TODO: 8Eh MOV SEGREG, R/M16
	//TODO: MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
	const byte rm = mmfu8_i;
	const ushort addr = mmfu16(mmrm16(rm, 1));
	switch (rm & RM_REG) {
	case RM_REG_100: CPU.ES = addr; break;
	case RM_REG_101: CPU.CS = addr; break;
	case RM_REG_110: CPU.SS = addr; break;
	case RM_REG_111: CPU.DS = addr; break;
	default: //TODO: when bit 5 is clear (REG[3])
		log_info("Invalid ModR/M for SEGREG<-RM");
		v32_illegal;
	}
	CPU.EIP += 2;
}

void v32_8F() {	//TODO: 8Fh POP R/M16
	const ubyte rm = mmfu8_i;
	if (rm & RM_REG) { //TODO: REG must be 000
		log_info("Invalid ModR/M for POP R/M16");
		v32_illegal;
	}
	mmiu16(CPU.pop16, mmrm16(rm, 1));
	CPU.EIP += 2;
}

void v32_90() {	//TODO: 90h NOP (aka XCHG AX, AX)
	++CPU.EIP;
}

void v32_91() {	//TODO: 91h XCHG AX, CX
	const ushort r = CPU.AX;
	CPU.AX = CPU.CX;
	CPU.CX = r;
	++CPU.EIP;
}

void v32_92() {	//TODO: 92h XCHG AX, DX
	const ushort r = CPU.AX;
	CPU.AX = CPU.DX;
	CPU.DX = r;
	++CPU.EIP;
}

void v32_93() {	//TODO: 93h XCHG AX, BX
	const ushort r = CPU.AX;
	CPU.AX = CPU.BX;
	CPU.BX = r;
	++CPU.EIP;
}

void v32_94() {	//TODO: 94h XCHG AX, SP
	const ushort r = CPU.AX;
	CPU.AX = CPU.SP;
	CPU.SP = r;
	++CPU.EIP;
}

void v32_95() {	//TODO: 95h XCHG AX, BP
	const ushort r = CPU.AX;
	CPU.AX = CPU.BP;
	CPU.BP = r;
	++CPU.EIP;
}

void v32_96() {	//TODO: 96h XCHG AX, SI
	const ushort r = CPU.AX;
	CPU.AX = CPU.SI;
	CPU.SI = r;
	++CPU.EIP;
}

void v32_97() {	//TODO: 97h XCHG AX, DI
	const ushort r = CPU.AX;
	CPU.AX = CPU.DI;
	CPU.DI = r;
	++CPU.EIP;
}

void v32_98() {	//TODO: 98h CBW
	CPU.AH = CPU.AL & 0x80 ? 0xFF : 0;
	++CPU.EIP;
}

void v32_99() {	//TODO: 99h CWD
	CPU.DX = CPU.AX & 0x8000 ? 0xFFFF : 0;
	++CPU.EIP;
}

void v32_9A() {	//TODO: 9Ah CALL FAR_PROC
	CPU.push16(CPU.CS);
	CPU.push16(CPU.IP);
	CPU.CS = mmfu16_i;
	CPU.IP = mmfu16_i(2);
}

void v32_9B() {	//TODO: 9Bh WAIT
	//TODO: WAIT
	++CPU.EIP;
}

void v32_9C() {	//TODO: 9Ch PUSHF
	CPU.push16(CPU.FLAGS);
	++CPU.EIP;
}

void v32_9D() {	//TODO: 9Dh POPF
	CPU.FLAGS = CPU.pop16;
	++CPU.EIP;
}

void v32_9E() {	//TODO: 9Eh SAHF (Save AH to Flags)
	CPU.FLAG = CPU.AH;
	++CPU.EIP;
}

void v32_9F() {	//TODO: 9Fh LAHF (Load AH from Flags)
	CPU.AH = CPU.FLAG;
	++CPU.EIP;
}

void v32_A0() {	//TODO: A0h MOV AL, MEM8
	CPU.AL = mmfu8(mmfu16_i);
	CPU.EIP += 2;
}

void v32_A1() {	//TODO: A1h MOV AX, MEM16
	CPU.AX = mmfu16(mmfu16_i);
	CPU.EIP += 3;
}

void v32_A2() {	//TODO: A2h MOV MEM8, AL
	mmiu8(CPU.AL, mmfu16_i);
	CPU.EIP += 2;
}

void v32_A3() {	//TODO: A3h MOV MEM16, AX
	mmiu16(CPU.AX, mmfu16_i);
	CPU.EIP += 3;
}

void v32_A4() {	//TODO: A4h MOVS DEST-STR8, SRC-STR8
}

void v32_A5() {	//TODO: A5h MOVS DEST-STR16, SRC-STR16
}

void v32_A6() {	//TODO: A6h CMPS DEST-STR8, SRC-STR8
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
}

void v32_A7() {	//TODO: A7h CMPSW DEST-STR16, SRC-STR16
	cpuf16_1(
		mmfu16(address(CPU.DS, CPU.SI)) - mmfu16(address(CPU.ES, CPU.DI))
	);
	if (CPU.DF) {
		CPU.DI -= 2;
		CPU.SI -= 2;
	} else {
		CPU.DI += 2;
		CPU.SI += 2;
	}
}

void v32_A8() {	//TODO: A8h TEST AL, IMM8
	cpuf8_3(CPU.AL & mmfu8_i);
	CPU.EIP += 2;
}

void v32_A9() {	//TODO: A9h TEST AX, IMM16
	cpuf16_3(CPU.AX & mmfu16_i);
	CPU.EIP += 3;
}

void v32_AA() {	//TODO: AAh STOS DEST-STR8
	mmiu8(CPU.AL, address(CPU.ES, CPU.DI));
	if (CPU.DF) --CPU.DI; else ++CPU.DI;
	++CPU.EIP;
}

void v32_AB() {	//TODO: ABh STOS DEST-STR16
	mmiu16(CPU.AX, address(CPU.ES, CPU.DI));
	if (CPU.DF) CPU.DI -= 2; else CPU.DI += 2;
	++CPU.EIP;
}

void v32_AC() {	//TODO: ACh LODS SRC-STR8
	CPU.AL = mmfu8(address(CPU.DS, CPU.SI));
	if (CPU.DF) --CPU.SI; else ++CPU.SI;
	++CPU.EIP;
}

void v32_AD() {	//TODO: ADh LODS SRC-STR16
	CPU.AX = mmfu16(address(CPU.DS, CPU.SI));
	if (CPU.DF) CPU.SI -= 2; else CPU.SI += 2;
	++CPU.EIP;
}

void v32_AE() {	//TODO: AEh SCAS DEST-STR8
	cpuf8_1(CPU.AL - mmfu8(address(CPU.ES, CPU.DI)));
	if (CPU.DF) --CPU.DI; else ++CPU.DI;
	++CPU.EIP;
}

void v32_AF() {	//TODO: AFh SCAS DEST-STR16
	cpuf16_1(CPU.AX - mmfu16(address(CPU.ES, CPU.DI)));
	if (CPU.DF) CPU.DI -= 2; else CPU.DI += 2;
	++CPU.EIP;
}

void v32_B0() {	//TODO: B0h MOV AL, IMM8
	CPU.AL = mmfu8_i;
	CPU.EIP += 2;
}

void v32_B1() {	//TODO: B1h MOV CL, IMM8
	CPU.CL = mmfu8_i;
	CPU.EIP += 2;
}

void v32_B2() {	//TODO: B2h MOV DL, IMM8
	CPU.DL = mmfu8_i;
	CPU.EIP += 2;
}

void v32_B3() {	//TODO: B3h MOV BL, IMM8
	CPU.BL = mmfu8_i;
	CPU.EIP += 2;
}

void v32_B4() {	//TODO: B4h MOV AH, IMM8
	CPU.AH = mmfu8_i;
	CPU.EIP += 2;
}

void v32_B5() {	//TODO: B5h MOV CH, IMM8
	CPU.CH = mmfu8_i;
	CPU.EIP += 2;
}

void v32_B6() {	//TODO: B6h MOV DH, IMM8  
	CPU.DH = mmfu8_i;
	CPU.EIP += 2;
}

void v32_B7() {	//TODO: B7h MOV BH, IMM8
	CPU.BH = mmfu8_i;
	CPU.EIP += 2;
}

void v32_B8() {	//TODO: B8h MOV AX, IMM16
	CPU.AX = mmfu16_i;
	CPU.EIP += 3;
}

void v32_B9() {	//TODO: B9h MOV CX, IMM16
	CPU.CX = mmfu16_i;
	CPU.EIP += 3;
}

void v32_BA() {	//TODO: BAh MOV DX, IMM16
	CPU.DX = mmfu16_i;
	CPU.EIP += 3;
}

void v32_BB() {	//TODO: BBh MOV BX, IMM16
	CPU.BX = mmfu16_i;
	CPU.EIP += 3;
}

void v32_BC() {	//TODO: BCh MOV SP, IMM16
	CPU.SP = mmfu16_i;
	CPU.EIP += 3;
}

void v32_BD() {	//TODO: BDh MOV BP, IMM16
	CPU.BP = mmfu16_i;
	CPU.EIP += 3;
}

void v32_BE() {	//TODO: BEh MOV SI, IMM16
	CPU.SI = mmfu16_i;
	CPU.EIP += 3;
}

void v32_BF() {	//TODO: BFh MOV DI, IMM16
	CPU.DI = mmfu16_i;
	CPU.EIP += 3;
}

void v32_C2() {	//TODO: C2 RET IMM16 (NEAR)
	const ushort sp = mmfi16_i;
	CPU.IP = CPU.pop16;
	CPU.SP += sp;
}

void v32_C3() {	//TODO: C3h RET (NEAR)
	CPU.IP = CPU.pop16;
}

void v32_C4() {	//TODO: C4h LES REG16, MEM16
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

void v32_C5() {	//TODO: C5h LDS REG16, MEM16
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

void v32_C6() {	//TODO: C6h MOV MEM8, IMM8
	const ubyte rm = mmfu8_i;
	if (rm & RM_REG) { //TODO: No register operation allowed
		log_info("Invalid ModR/M for MOV MEM8");
		v32_illegal;
	}
	mmiu8(mmfu8_i(1), mmrm16(rm));
}

void v32_C7() {	//TODO: C7h MOV MEM16, IMM16
	const ubyte rm = mmfu8_i;
	if (rm & RM_REG) { //TODO: No register operation allowed
		log_info("Invalid ModR/M for MOV MEM16");
		v32_illegal;
	}
	mmiu16(mmfu16_i(1), mmrm16(rm, 1));
}

void v32_CA() {	//TODO: CAh RET IMM16 (FAR)
	const uint addr = CPU.EIP + 1;
	CPU.IP = CPU.pop16;
	CPU.CS = CPU.pop16;
	CPU.SP += mmfi16(addr);
}

void v32_CB() {	//TODO: CBh RET (FAR)
	CPU.IP = CPU.pop16;
	CPU.CS = CPU.pop16;
}

void v32_CC() {	//TODO: CCh INT 3
	INT(3);
	++CPU.EIP;
}

void v32_CD() {	//TODO: CDh INT IMM8
	INT(mmfu8_i);
	CPU.EIP += 2;
}

void v32_CE() {	//TODO: CEh INTO
	if (CPU.CF) INT(4);
	++CPU.EIP;
}

void v32_CF() {	//TODO: CFh IRET
	CPU.IP = CPU.pop16;
	CPU.CS = CPU.pop16;
	CPU.FLAGS = CPU.pop16;
	++CPU.EIP;
}

void v32_D0() {	//TODO: D0h GRP2 R/M8, 1
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: //TODO: 000 - ROL
		r <<= 1; if (r & 0x100) { r |= 1; CPU.OF = 1; } break;
	case RM_REG_001: //TODO: 001 - ROR
		if (r & 1) { r |= 0x100; CPU.OF = 1; } r >>= 1; break;
	case RM_REG_010: //TODO: 010 - RCL
		r <<= 1; if (r & 0x200) { r |= 1; CPU.OF = 1; } break;
	case RM_REG_011: //TODO: 011 - RCR
		if (r & 1) { r |= 0x200; CPU.OF = 1; } r >>= 1; break;
	case RM_REG_100: //TODO: 100 - SAL/SHL
		r <<= 1; cpuf8_1(r); break;
	case RM_REG_101: //TODO: 101 - SHR
		r >>= 1; cpuf8_1(r); break;
	case RM_REG_111: //TODO: 111 - SAR
		if (r & 0x80) r |= 0x100; r >>= 1; cpuf8_1(r); break;
	default: //TODO: 110
		log_info("Invalid ModR/M for GRP2 R/M8, 1");
		v32_illegal;
	}
	mmiu8(r, addr);
	CPU.EIP += 2;
}

void v32_D1() {	//TODO: D1h GRP2 R/M16, 1
	const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: //TODO: 000 - ROL
		r <<= 1; if (r & 0x1_0000) { r |= 1; CPU.OF = 1; } break;
	case RM_REG_001: //TODO: 001 - ROR
		if (r & 1) { r |= 0x1_0000; CPU.OF = 1; } r >>= 1; break;
	case RM_REG_010: //TODO: 010 - RCL
		r <<= 1; if (r & 0x2_0000) { r |= 1; CPU.OF = 1; } break;
	case RM_REG_011: //TODO: 011 - RCR
		if (r & 1) { r |= 0x2_0000; CPU.OF = 1; } r >>= 1; break;
	case RM_REG_100: //TODO: 100 - SAL/SHL
		r <<= 1; cpuf16_1(r); break;
	case RM_REG_101: //TODO: 101 - SHR
		r >>= 1; cpuf16_1(r); break;
	case RM_REG_111: //TODO: 111 - SAR
		if (r & 0x8000) r |= 0x1_0000; r >>= 1; cpuf16_1(r); break;
	default: //TODO: 110
		log_info("Invalid ModR/M for GRP2 R/M16, 1");
		v32_illegal;
	}
	mmiu16(r, addr);
	CPU.EIP += 2;
}

void v32_D2() {	//TODO: D2h GRP2 R/M8, CL
	//TODO: The 8086 does not mask the rotation count.
	/*const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm);
	switch (rm & RM_REG) {
	case RM_REG_000: //TODO: 000 - ROL

		break;
	case RM_REG_001: //TODO: 001 - ROR

		break;
	case RM_REG_010: //TODO: 010 - RCL

		break;
	case RM_REG_011: //TODO: 011 - RCR

		break;
	case RM_REG_100: //TODO: 100 - SAL/SHL

		break;
	case RM_REG_101: //TODO: 101 - SHR

		break;
	case RM_REG_111: //TODO: 111 - SAR

		break;
	default:
		log_info("Invalid ModR/M for GRP2 R/M8, CL");
		v32_illegal;
	}*/
	CPU.EIP += 2;
}

void v32_D3() {	//TODO: D3h GRP2 R/M16, CL
	//TODO: The 8086 does not mask the rotation count.
	/*const ubyte rm = mmfu8_i;
	const int addr = mmrm16(rm, 1);
	switch (rm & RM_REG) {
	case RM_REG_000: //TODO: 000 - ROL

		break;
	case RM_REG_001: //TODO: 001 - ROR

		break;
	case RM_REG_010: //TODO: 010 - RCL

		break;
	case RM_REG_011: //TODO: 011 - RCR

		break;
	case RM_REG_100: //TODO: 100 - SAL/SHL

		break;
	case RM_REG_101: //TODO: 101 - SHR

		break;
	case RM_REG_111: //TODO: 111 - SAR

		break;
	default:
		log_info("Invalid ModR/M for GRP2 R/M16, CL");
		v32_illegal;
	}*/
	CPU.EIP += 2;
}

void v32_D4() {	//TODO: D4h AAM
	const int r = CPU.AL % 0xA;
	cpuf8_5(r);
	CPU.AL = cast(ubyte)r;
	CPU.AH = cast(ubyte)(r / 0xA);
	++CPU.EIP;
}

void v32_D5() {	//TODO: D5h AAD
	const int r = CPU.AL + (CPU.AH * 0xA);
	cpuf8_5(r);
	CPU.AL = cast(ubyte)r;
	CPU.AH = 0;
	++CPU.EIP;
}

void v32_D7() {	//TODO: D7h XLAT SOURCE-TABLE
	CPU.AL = mmfu8(address(CPU.DS, CPU.BX) + cast(byte)CPU.AL);
	++CPU.EIP;
}

void v32_E0() {	//TODO: E0h LOOPNE/LOOPNZ SHORT-LABEL
	--CPU.CX;
	if (CPU.CX && CPU.ZF == 0) CPU.EIP += mmfi8_i;
	else CPU.EIP += 2;
}

void v32_E1() {	//TODO: E1h LOOPE/LOOPZ SHORT-LABEL
	--CPU.CX;
	if (CPU.CX && CPU.ZF) CPU.EIP += mmfi8_i;
	else CPU.EIP += 2;
}

void v32_E2() {	//TODO: E2h LOOP SHORT-LABEL
	--CPU.CX;
	if (CPU.CX) CPU.EIP += mmfi8_i;
	else CPU.EIP += 2;
}

 void v32_E3() {	//TODO: E3 JCXZ SHORT-LABEL
	if (CPU.CX == 0) CPU.EIP += mmfi8_i;
	else CPU.EIP += 2;
 }
 
 void v32_E4() {	//TODO: E4h IN AL, IMM8
 }
 
 void v32_E5() {	//TODO: E5h IN AX, IMM8
 }
 
 void v32_E6() {	//TODO: E6h OUT IMM8, AL
 }
 
 void v32_E7() {	//TODO: E7h OUT IMM8, AX
 }
 
 void v32_E8() {	//TODO: E8h CALL NEAR-PROC
	CPU.push16(CPU.IP);
	CPU.EIP += mmfi16_i; //TODO: Direct within segment
 }
 
 void v32_E9() {	//TODO: E9h JMP NEAR-LABEL
	CPU.EIP += mmfi16_i + 3; //TODO: ±32 KB
 }
 
 void v32_EA() {	//TODO: EAh JMP FAR-LABEL
	//TODO: Any segment, any fragment, 5 byte instruction.
	//TODO: EAh (LO-CPU.IP) (HI-CPU.IP) (LO-CPU.CS) (HI-CPU.CS)
	const ushort ip = mmfu16_i;
	const ushort cs = mmfu16_i(2);
	CPU.IP = ip;
	CPU.CS = cs;
 }
 
 void v32_EB() {	//TODO: EBh JMP SHORT-LABEL
	CPU.EIP += mmfi8_i + 2; //TODO: ±128 B
 }
 
 void v32_EC() {	//TODO: ECh IN AL, DX
 }
 
 void v32_ED() {	//TODO: EDh IN AX, DX
 }
 
 void v32_EE() {	//TODO: EEh OUT AL, DX
 }
 
 void v32_EF() {	//TODO: EFh OUT AX, DX
 }
 
 void v32_F0() {	//TODO: F0h LOCK (prefix)
	//CPU.Lock = 1;
	++CPU.EIP;
 }
 
 void v32_F2() {	//TODO: F2h REPNE/REPNZ
	while (CPU.CX > 0) {
		//TODO: Finish REPNE/REPNZ properly?
		v32_A6;
		--CPU.CX;
		if (CPU.ZF == 0) break;
	}
	++CPU.EIP;
 }
 
 void v32_F3() {	//TODO: F3h REP/REPE/REPNZ
	//TODO: REAL F3h REP/REPE/REPNZ
 }
 
 void v32_F4() {	//TODO: F4h HLT
	RLEVEL = 0;
	++CPU.EIP;
 }
 
 void v32_F5() {	//TODO: F5h CMCCMC
	CPU.CF = !CPU.CF;
	++CPU.EIP;
 }
 
 void v32_F6() {	//TODO: F6h GRP3 R/M8, IMM8
	const ubyte rm = mmfu8_i;
	const ubyte im = mmfu8_i(1);
	const int addr = mmrm16(rm);
	int r = void;
	switch (rm & RM_REG) {
	case RM_REG_000: //TODO: 000 - TEST
		cpuf8_1(im & mmfu8(addr)); break;
	case RM_REG_010: //TODO: 010 - NOT
		mmiu8(~mmfu8(addr), addr); break;
	case RM_REG_011: //TODO: 011 - NEG
		import core.stdc.stdio : printf;
		r = cast(ubyte)-mmfi8(addr);
		cpuf8_1(r);
		CPU.CF = cast(ubyte)r;
		mmiu8(r, addr);
		break;
	case RM_REG_100: //TODO: 100 - MUL
		r = im * mmfu8(addr);
		cpuf8_4(r);
		mmiu8(r, addr);
		break;
	case RM_REG_101: //TODO: 101 - IMUL
		r = cast(ubyte)(cast(byte)im * mmfi8(addr));
		cpuf8_4(r);
		mmiu8(r, addr);
		break;
	case RM_REG_110: //TODO: 110 - DIV
	//TODO: Check if im == 0 (#DE), DIV
		const ubyte d = mmfu8(addr);
		r = CPU.AX / d;
		CPU.AH = cast(ubyte)(CPU.AX % d);
		CPU.AL = cast(ubyte)(r);
		break;
	case RM_REG_111: //TODO: 111 - IDIV
	//TODO: Check if im == 0 (#DE), IDIV
		const byte d = mmfi8(addr);
		r = cast(short)CPU.AX / d;
		CPU.AH = cast(ubyte)(cast(short)CPU.AX % d);
		CPU.AL = cast(ubyte)r;
		break;
	default:
		log_info("Invalid ModR/M on GRP3_8");
		v32_illegal;
	}
	CPU.EIP += 3;
 }
 
 void v32_F7() {	//TODO: F7 GRP3 R/M16, IMM16
	const ubyte rm = mmfu8_i; //TODO: Get ModR/M byte
	ushort im = mmfu16_i(1);
	int addr = mmrm16(rm, 1);
	int r = void;
	switch (rm & RM_REG) {
	case RM_REG_000: //TODO: 000 - TEST
		cpuf16_1(im & mmfu16(addr)); break;
	case RM_REG_010: //TODO: 010 - NOT
		mmiu16(~im, addr); break;
	case RM_REG_011: //TODO: 011 - NEG
		r = -mmfi16(addr);
		cpuf16_1(r);
		CPU.CF = cast(ubyte)r;
		mmiu16(r, addr);
		break;
	case RM_REG_100: //TODO: 100 - MUL
		r = im * mmfu16(addr);
		cpuf16_4(r);
		mmiu16(r, addr);
		break;
	case RM_REG_101: //TODO: 101 - IMUL
		r = im * mmfi16(addr);
		cpuf16_4(r);
		mmiu16(r, addr);
		break;
	case RM_REG_110: //TODO: 110 - DIV
		r = im / mmfu16(addr);
		cpuf16_4(r);
		mmiu16(r, addr);
		break;
	case RM_REG_111: //TODO: 111 - IDIV
		r = im / mmfi16(addr);
		cpuf16_4(r);
		mmiu16(r, addr);
		break;
	default:
		log_info("Invalid ModR/M on GRP3_8");
		v32_illegal;
	}
	CPU.EIP += 4;
}

void v32_F8() {	//TODO: F8h CLC
	CPU.CF = 0;
	++CPU.EIP;
}

void v32_F9() {	//TODO: F9h STC
	CPU.CF = 1;
	++CPU.EIP;
}

void v32_FA() {	//TODO: FAh CLI
	CPU.IF = 0;
	++CPU.EIP;
}

void v32_FB() {	//TODO: FBh STI
	CPU.IF = 1;
	++CPU.EIP;
}

void v32_FC() {	//TODO: FCh CLD
	CPU.DF = 0;
	++CPU.EIP;
}

void v32_FD() {	//TODO: FDh STD
	CPU.DF = 1;
	++CPU.EIP;
}

void v32_FE() {	//TODO: FEh GRP4 R/M8
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm);
	int r = mmfu8(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: //TODO: 000 - INC
		++r;
		break;
	case RM_REG_001: //TODO: 001 - DEC
		--r;
		break;
	default:
		log_info("Invalid ModR/M on GRP4_8");
		v32_illegal;
	}
	mmiu16(r, addr);
	cpuf16_2(r);
	CPU.EIP += 2;
}

void v32_FF() {	//TODO: FFh GRP5 R/M16
	const ubyte rm = mmfu8_i;
	const uint addr = mmrm16(rm, 1);
	int r = mmfu16(addr);
	switch (rm & RM_REG) {
	case RM_REG_000: //TODO: 000 - INC
		++r;
		cpuf16_2(r);
		mmiu16(r, addr);
		CPU.EIP += 2;
		return;
	case RM_REG_001: //TODO: 001 - DEC
		--r;
		cpuf16_2(r);
		mmiu16(r, addr);
		CPU.EIP += 2;
		break;
	case RM_REG_010: //TODO: 010 - CALL R/M16 (near) -- Indirect within segment
		CPU.push16(CPU.IP);
		CPU.IP = cast(ushort)r;
		break;
	case RM_REG_011: //TODO: 011 - CALL MEM16 (far) -- Indirect outside segment
		ushort nip = cast(ushort)address(mmfu16(addr + 2), r);
		CPU.push16(CPU.CS);
		CPU.push16(CPU.IP);
		CPU.IP = nip;
		break;
	case RM_REG_100: //TODO: 100 - JMP R/M16 (near) -- Indirect within segment
		CPU.IP = cast(ushort)(r + 2);
		break;
	case RM_REG_101: //TODO: 101 - JMP MEM16 (far) -- Indirect outside segment
		CPU.IP = cast(ushort)address(mmfu16(addr), r + 2);
		break;
	case RM_REG_110: //TODO: 110 - PUSH MEM16
		CPU.push16(mmfu16(address(mmfu16(addr + 2), r)));
		CPU.EIP += 2;
		break;
	default:
		log_info("Invalid ModR/M on GRP5_16");
		v32_illegal;
	}
}

void v32_illegal() {	//TODO: Illegal instruction
	log_info("INVALID OPERATION CODE");
	//TODO: Raise vector on illegal op
}