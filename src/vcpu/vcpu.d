/*
 * vcpu.d: Legacy machine code interpreter.
 * 
 * Right now it's closest to an 8086 (REAL-MODE)
 * I hope to make it closer to an i486 whenever possible.
 */

module vcpu;

import core.stdc.stdio : printf, puts; // should be removed in the future
import vcpu_config;
import vcpu_utils;
import sleep;
import Logger; // crit and logexec
import vdos : Raise; // Interrupt handler

/*enum CPU_MODE : ubyte {
	i8086,
	i486
}*/

/// Initiate interpreter
extern (C)
void vcpu_init() {
	SLEEP_SET;

	IPp = cast(ushort*)&EIP;

	AXp = cast(ushort*)&EAX;
	BXp = cast(ushort*)&EBX;
	CXp = cast(ushort*)&ECX;
	DXp = cast(ushort*)&EDX;

	SIp = cast(ushort*)&ESI;
	DIp = cast(ushort*)&EDI;
	BPp = cast(ushort*)&EBP;
	SPp = cast(ushort*)&ESP;

	ALp = cast(ubyte*)AXp;
	BLp = cast(ubyte*)BXp;
	CLp = cast(ubyte*)CXp;
	DLp = cast(ubyte*)DXp;

	//CS = 0xFFFF;
}

/// Start the emulator at CS:IP (usually 0000h:0100h)
extern (C)
void vcpu_run() {
	info("CALL vcpu_run");
	uint tsc; /// tick count for thread sleeping purposes
	while (RLEVEL > 0) {
		EIP = get_ip; // CS:IP->EIP (important)
		debug logexec(CS, IP, MEMORY[EIP]);
		exec(MEMORY[EIP]);

		if (opt_sleep) {
			++tsc;
			if (tsc == TSC_SLEEP) {
				SLEEP;
				tsc = 0;
			}
		}
	}
}

__gshared ubyte opt_sleep = 1; /// If set, the vcpu sleeps between cycles

/**
 * Runnning level.
 * Used to determine the "level of execution", such as the
 * "deepness" of a program. When a program terminates, its ERRORLEVEL is decreased.
 * If RLEVEL reaches 0, the emulator either stops, or returns to the virtual shell.
 * tl;dr: Emulates CALLs
 */
__gshared short RLEVEL = 1;

enum MEMORY_P = cast(ubyte*)MEMORY; /// Memory pointer to avoid typing cast() everytime
__gshared ubyte[INIT_MEM] MEMORY; /// Main memory bank
__gshared uint MEMORYSIZE = INIT_MEM; /// Current memory MEMORY size

/**
 * Get memory address out of a segment and a register value.
 * Params:
 *   s = Segment register value
 *   o  = Generic register value
 * Returns: SEG:ADDR Location
 */
extern (C)
pragma(inline, true)
uint get_ad(int s, int o) {
	return (s << 4) + o;
}

/**
 * Get next instruction location
 * Returns: CS:IP effective address
 */
extern (C)
pragma(inline, true)
uint get_ip() {
	return get_ad(CS, IP);
}

/// RESET instruction function
extern (C)
private void reset() {
	OF = DF = IF = TF = SF =
		ZF = AF = PF = CF = 0;
	CS = 0xFFFF;
	EIP = DS = SS = ES = 0;
	// Empty Queue Bus
}

/// Resets the entire vcpu. Does not refer to the RESET instruction!
extern (C)
void fullreset() {
	reset;
	EAX = EBX = ECX = EDX =
		EBP = ESP = EDI = ESI = 0;
}

/// Generic register
__gshared uint EAX, EBX, ECX, EDX;
private __gshared ushort* AXp, BXp, CXp, DXp;
private __gshared ubyte* ALp, BLp, CLp, DLp;

/*
 * Register properties.
 * Getters and setters, respectively.
 */

/// Get AX
/// Returns: WORD
@property
ushort AX() { return *AXp; }
/// Get AH
/// Returns: BYTE
@property
ubyte  AH() { return *(ALp + 1); }
/// Get AL
/// Returns: BYTE
@property
ubyte  AL() { return *ALp; }
/// Set AX
/// Params: v = WORD
@property
void   AX(int v) { *AXp = cast(ushort)v; }
/// Set AH
/// Params: v = BYTE
@property
void   AH(int v) { *(ALp + 1) = cast(ubyte)v; }
/// Set AL
/// Params: v = BYTE
@property
void   AL(int v) { *ALp = cast(ubyte)v; }

/// Get BX
/// Returns: WORD
@property
ushort BX() { return *BXp; }
/// Get BH
/// Returns: BYTE
@property
ubyte  BH() { return *(BLp + 1); }
/// Get BL
/// Returns: BYTE
@property
ubyte  BL() { return *BLp; }
/// Set BX
/// Params: v = WORD
@property
void   BX(int v) { *BXp = cast(ushort)v; }
/// Set BH
/// Params: v = BYTE
@property
void   BH(int v) { *(BLp + 1) = cast(ubyte)v; }
/// Set BL
/// Params: v = BYTE
@property
void   BL(int v) { *BLp = cast(ubyte)v; }

/// Get CX
/// Returns: WORD
@property
ushort CX() { return *CXp; }
/// Get CH
/// Returns: BYTE
@property
ubyte  CH() { return *(CLp + 1); }
/// Get CL
/// Returns: BYTE
@property
ubyte  CL() { return *CLp; }
/// Set CX
/// Params: v = WORD
@property
void   CX(int v) { *CXp = cast(ushort)v; }
/// Set CH
/// Params: v = BYTE
@property
void   CH(int v) { *(CLp + 1) = cast(ubyte)v; }
/// Set CL
/// Params: v = BYTE
@property
void   CL(int v) { *CLp = cast(ubyte)v; }

/// Get DX
/// Returns: WORD
@property
ushort DX() { return *DXp; }
/// Get DH
/// Returns: BYTE
@property
ubyte  DH() { return *(DLp + 1); }
/// Get CL
/// Returns: BYTE
@property
ubyte  DL() { return *DLp; }
/// Set DX
/// Params: v = WORD
@property
void   DX(int v) { *DXp = cast(ushort)v; }
/// Set DH
/// Params: v = BYTE
@property
void   DH(int v) { *(DLp + 1) = cast(ubyte)v; }
/// Set DL
/// Params: v = BYTE
@property
void   DL(int v) { *DLp = cast(ubyte)v; }

/// Index register
__gshared uint ESI, EDI, EBP, ESP;
private __gshared ushort* SIp, DIp, BPp, SPp;

/// Get SI register
/// Returns: SI
@property
ushort SI() { return *SIp; }
/// Get DI register
/// Returns: DI
@property
ushort DI() { return *DIp; }
/// Get BP register
/// Returns: BP
@property
ushort BP() { return *BPp; }
/// Get SP register
/// Returns: SP
@property
ushort SP() { return *SPp; }
/// Set SI register
/// Params: v = Set SI value
@property
void SI(int v) { *SIp = cast(ushort)v; }
/// Set DI register
/// Params: v = Set DI value
@property
void DI(int v) { *DIp = cast(ushort)v; }
/// Set BP register
/// Params: v = Set BP value
@property
void BP(int v) { *BPp = cast(ushort)v; }
/// Set SP register
/// Params: v = Set SP value
@property
void SP(int v) { *SPp = cast(ushort)v; }

/// Segment register
__gshared ushort CS, SS, DS, ES,
	   FS, GS; // i386

/// Program Counter
__gshared uint EIP;
private __gshared ushort* IPp;
/// Get Instruction Pointer
/// Returns: IP
@property ushort IP() { return *IPp; }
/// Set Instruction Pointer
/// Params: v = Set IP value
@property void IP(int v) { *IPp = cast(ushort)v; }

/**********************************************************
 * FLAGS
 **********************************************************/

// Flags are bytes because single flags are affected a lot more often than
// flag-whole operations, like PUSHF.
__gshared ubyte
CF, /// Bit  0, Carry Flag
PF, /// Bit  2, Parity Flag
AF, /// Bit  4, Auxiliary Flag (aka Half-carry Flag, Adjust Flag)
ZF, /// Bit  6, Zero Flag
SF, /// Bit  7, Sign Flag
TF, /// Bit  8, Trap Flag
IF, /// Bit  9, Interrupt Flag
DF, /// Bit 10, Direction Flag
OF; /// Bit 11, Overflow Flag

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
	ubyte b;
	if (SF) b |= MASK_SF;
	if (ZF) b |= MASK_ZF;
	if (AF) b |= MASK_AF;
	if (PF) b |= MASK_PF;
	if (CF) b |= MASK_CF;
	return b;
}

/// Set FLAG as BYTE.
/// Params: flag = FLAG byte
@property void FLAGB(ubyte flag) {
	SF = flag & MASK_SF;
	ZF = flag & MASK_ZF;
	AF = flag & MASK_AF;
	PF = flag & MASK_PF;
	CF = flag & MASK_CF;
}

/**
 * Get FLAG as WORD.
 * Returns: FLAG (WORD)
 */
@property ushort FLAG() {
	ushort b = FLAGB;
	if (OF) b |= MASK_OF;
	if (DF) b |= MASK_DF;
	if (IF) b |= MASK_IF;
	if (TF) b |= MASK_TF;
	return b;
}

/// Set FLAG as WORD.
/// Params: flag = FLAG word
@property void FLAG(ushort flag) {
	OF = (flag & MASK_OF) != 0;
	DF = (flag & MASK_DF) != 0;
	IF = (flag & MASK_IF) != 0;
	TF = (flag & MASK_TF) != 0;
	FLAGB = cast(ubyte)flag;
}

enum : ubyte {
	RM_MOD_00 = 0,	/// MOD 00, Memory Mode, no displacement
	RM_MOD_01 = 64,	/// MOD 01, Memory Mode, 8-bit displacement
	RM_MOD_10 = 128,	/// MOD 10, Memory Mode, 16-bit displacement
	RM_MOD_11 = 192,	/// MOD 11, Register Mode
	RM_MOD = 192,	/// Used for masking the MOD bits (11 000 000)

	RM_REG_000 = 0,	/// AL/AX
	RM_REG_001 = 8,	/// CL/CX
	RM_REG_010 = 16,	/// DL/DX
	RM_REG_011 = 24,	/// BL/BX
	RM_REG_100 = 32,	/// AH/SP
	RM_REG_101 = 40,	/// CH/BP
	RM_REG_110 = 48,	/// DH/SI
	RM_REG_111 = 56,	/// BH/DI
	RM_REG = 56,	/// Used for masking the REG bits (00 111 000)

	RM_RM_000 = 0,	/// R/M 000 bits
	RM_RM_001 = 1,	/// R/M 001 bits
	RM_RM_010 = 2,	/// R/M 010 bits
	RM_RM_011 = 3,	/// R/M 011 bits
	RM_RM_100 = 4,	/// R/M 100 bits
	RM_RM_101 = 5,	/// R/M 101 bits
	RM_RM_110 = 6,	/// R/M 110 bits
	RM_RM_111 = 7,	/// R/M 111 bits
	RM_RM = 7,	/// Used for masking the R/M bits (00 000 111)
}

/**
 * Push a WORD value into stack.
 * Params: value = WORD value to PUSH
 */
extern (C)
void push(ushort value) {
	SP = SP - 2;
	__iu16(value, get_ad(SS, SP));
}

/**
 * Pop a WORD value from stack.
 * Returns: WORD value
 */
extern (C)
ushort pop() {
	const uint addr = get_ad(SS, SP);
	SP = SP + 2;
	return __fu16(addr);
}

/**
 * Push a DWORD value into stack.
 * Params: value = DWORD value
 */
extern (C)
void epush(uint value) {
	SP = SP - 2;
	__iu32(value, get_ad(SS, SP));
}

/**
 * Pop a DWORD value from stack.
 * Returns: WORD value
 */
extern (C)
uint epop() {
	const uint addr = get_ad(SS, SP);
	SP = SP + 2;
	return __fu32(addr);
}

/// Preferred Segment register
__gshared ubyte Seg;
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

// Rest of the source here is solely this function.
/**
 * Execute an 8086 opcode
 * Params: op = 8086 opcode
 */
extern (C)
void exec(ubyte op) {
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
		case RM_REG_000: r += AL; break;
		case RM_REG_001: r += CL; break;
		case RM_REG_010: r += DL; break;
		case RM_REG_011: r += BL; break;
		case RM_REG_100: r += AH; break;
		case RM_REG_101: r += CH; break;
		case RM_REG_110: r += DH; break;
		case RM_REG_111: r += BH; break;
		default:
		}
		__hflag8_1(r);
		__iu8(r, addr);
		EIP += 2;
		return;
	}
	case 0x01: { // ADD R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r += AX; break;
		case RM_REG_001: r += CX; break;
		case RM_REG_010: r += DX; break;
		case RM_REG_011: r += BX; break;
		case RM_REG_100: r += SP; break;
		case RM_REG_101: r += BP; break;
		case RM_REG_110: r += SI; break;
		case RM_REG_111: r += DI; break;
		default:
		}
		__hflag16_1(r);
		__iu16(r, addr);
		EIP += 2;
		return;
	}
	case 0x02: { // ADD REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = AL + r;
			AL = r;
			break;
		case RM_REG_001:
			r = CL + r;
			CL = r;
			break;
		case RM_REG_010:
			r = DL + r;
			DL = r;
			break;
		case RM_REG_011:
			r = BL + r;
			BL = r;
			break;
		case RM_REG_100:
			r = AH + r;
			AH = r;
			break;
		case RM_REG_101:
			r = CH + r;
			CH = r;
			break;
		case RM_REG_110:
			r = DH + r;
			DH = r;
			break;
		case RM_REG_111:
			r = BH + r;
			BH = r;
			break;
		default:
		}
		__hflag8_1(r);
		EIP += 2;
		return;
	}
	case 0x03: { // ADD REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = AX + r;
			AX = r;
			break;
		case RM_REG_001:
			r = CX + r;
			CX = r;
			break;
		case RM_REG_010:
			r = DX + r;
			DX = r;
			break;
		case RM_REG_011:
			r = BX + r;
			BX = r;
			break;
		case RM_REG_100:
			r = SP + r;
			SP = r;
			break;
		case RM_REG_101:
			r = BP + r;
			BP = r;
			break;
		case RM_REG_110:
			r = SI + r;
			SI = r;
			break;
		case RM_REG_111:
			r = DI + r;
			DI = r;
			break;
		default:
		}
		__hflag16_1(r);
		EIP += 2;
		return;
	}
	case 0x04: { // ADD AL, IMM8
		int r = AL + __fu8_i;
		__hflag8_1(r);
		AL = r;
		EIP += 2;
		return;
	}
	case 0x05: { // ADD AX, IMM16
		int r = AX + __fu16_i;
		__hflag16_1(r);
		AX = r;
		EIP += 2;
		return;
	}
	case 0x06: // PUSH ES
		push(ES);
		++EIP;
		return;
	case 0x07: // POP ES
		ES = pop();
		++EIP;
		return;
	case 0x08: { // OR R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r |= AL; break;
		case RM_REG_001: r |= CL; break;
		case RM_REG_010: r |= DL; break;
		case RM_REG_011: r |= BL; break;
		case RM_REG_100: r |= AH; break;
		case RM_REG_101: r |= CH; break;
		case RM_REG_110: r |= DH; break;
		case RM_REG_111: r |= BH; break;
		default:
		}
		__hflag8_3(r);
		__iu8(r, addr);
		EIP += 2;
		return;
	}
	case 0x09: { // OR R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r |= AX; break;
		case RM_REG_001: r |= CX; break;
		case RM_REG_010: r |= DX; break;
		case RM_REG_011: r |= BX; break;
		case RM_REG_100: r |= SP; break;
		case RM_REG_101: r |= BP; break;
		case RM_REG_110: r |= SI; break;
		case RM_REG_111: r |= DI; break;
		default:
		}
		__hflag16_3(r);
		__iu16(r, addr);
		EIP += 2;
		return;
	}
	case 0x0A: { // OR REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = AL | r;
			AL = r;
			break;
		case RM_REG_001:
			r = CL | r;
			CL = r;
			break;
		case RM_REG_010:
			r = DL | r;
			DL = r;
			break;
		case RM_REG_011:
			r = BL | r;
			BL = r;
			break;
		case RM_REG_100:
			r = AH | r;
			AH = r;
			break;
		case RM_REG_101:
			r = CH | r;
			CH = r;
			break;
		case RM_REG_110:
			r = DH | r;
			DH = r;
			break;
		case RM_REG_111:
			r = BH | r;
			BH = r;
			break;
		default:
		}
		__hflag8_3(r);
		EIP += 2;
		return;
	}
	case 0x0B: { // OR REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = AX | r;
			AX = r;
			break;
		case RM_REG_001:
			r = CX | r;
			CX = r;
			break;
		case RM_REG_010:
			r = DX | r;
			DX = r;
			break;
		case RM_REG_011:
			r = BX | r;
			BX = r;
			break;
		case RM_REG_100:
			r = SP | r;
			SP = r;
			break;
		case RM_REG_101:
			r |= BP;
			BP = r;
			break;
		case RM_REG_110:
			r = SI | r;
			SI = r;
			break;
		case RM_REG_111:
			r = DI | r;
			DI = r;
			break;
		default:
		}
		__hflag16_3(r);
		EIP += 2;
		return;
	}
	case 0x0C: { // OR AL, IMM8
		int r = AL | __fu8_i;
		__hflag8_3(r);
		AX = r;
		EIP += 2;
		return;
	}
	case 0x0D: { // OR AX, IMM16
		int r = AX | __fu16_i;
		__hflag16_3(r);
		AX = r;
		EIP += 3;
		return;
	}
	case 0x0E: // PUSH CS
		push(CS);
		++EIP;
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
		int r = AL + __fu8_i;
		__hflag8_1(r);
		if (CF) ++r;
		AL = r;
		EIP += 2;
		return;
	}
	case 0x15: { // ADC AX, IMM16
		int r = AX + __fu16_i;
		__hflag16_1(r);
		if (CF) ++r;
		AX = r;
		EIP += 3;
		return;
	}
	case 0x16: // PUSH SS
		push(SS);
		++EIP;
		return;
	case 0x17: // POP SS
		SS = pop;
		++EIP;
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
		int t = AL - __fu8_i;
		if (CF) --t;
		__hflag8_3(t);
		AL = t;
		EIP += 2;
		return;
	}
	case 0x1D: { // SBB AX, IMM16
		int t = AX - __fu16_i;
		if (CF) --t;
		__hflag16_3(t);
		AX = t;
		EIP += 3;
		return;
	}
	case 0x1E: // PUSH DS
		push(DS);
		++EIP;
		return;
	case 0x1F: // POP DS
		DS = pop;
		++EIP;
		return;
	case 0x20: { // AND R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r &= AH; break;
		case RM_REG_001: r &= CH; break;
		case RM_REG_010: r &= DH; break;
		case RM_REG_011: r &= BH; break;
		case RM_REG_100: r &= AL; break;
		case RM_REG_101: r &= CL; break;
		case RM_REG_110: r &= DL; break;
		case RM_REG_111: r &= BL; break;
		default:
		}
		__hflag8_3(r);
		__iu8(r, addr);
		EIP += 2;
		return;
	}
	case 0x21: { // AND R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r &= AX; break;
		case RM_REG_001: r &= CX; break;
		case RM_REG_010: r &= DX; break;
		case RM_REG_011: r &= BX; break;
		case RM_REG_100: r &= SP; break;
		case RM_REG_101: r &= BP; break;
		case RM_REG_110: r &= SI; break;
		case RM_REG_111: r &= DI; break;
		default:
		}
		__hflag16_3(r);
		__iu16(r, addr);
		EIP += 2;
		return;
	}
	case 0x22: { // AND REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = AL & r;
			AL = r;
			break;
		case RM_REG_001:
			r = CL & r;
			CL = r;
			break;
		case RM_REG_010:
			r = DL & r;
			DL = r;
			break;
		case RM_REG_011:
			r = BL & r;
			BL = r;
			break;
		case RM_REG_100:
			r = AH & r;
			AH = r;
			break;
		case RM_REG_101:
			r = CH & r;
			CH = r;
			break;
		case RM_REG_110:
			r = DH & r;
			DH = r;
			break;
		case RM_REG_111:
			r = BH & r;
			BH = r;
			break;
		default:
		}
		__hflag8_3(r);
		EIP += 2;
		return;
	}
	case 0x23: { // AND REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = AX & r;
			AX = r;
			break;
		case RM_REG_001:
			r = CX & r;
			CX = r;
			break;
		case RM_REG_010:
			r = DX & r;
			DX = r;
			break;
		case RM_REG_011:
			r = BX & r;
			BX = r;
			break;
		case RM_REG_100:
			r = SP & r;
			SP = r;
			break;
		case RM_REG_101:
			r = BP & r;
			BP = r;
			break;
		case RM_REG_110:
			r = SI & r;
			SI = r;
			break;
		case RM_REG_111:
			r = DI & r;
			DI = r;
			break;
		default:
		}
		__hflag16_3(r);
		EIP += 2;
		return;
	}
	case 0x24: { // AND AL, IMM8
		int r = AL & __fu8_i;
		__hflag8_3(r);
		AL = r;
		EIP += 2;
		return;
	}
	case 0x25: { // AND AX, IMM16
		int r = AX & __fu16_i;
		__hflag16_3(r);
		AX = r;
		EIP += 3;
		return;
	}
	case 0x26: // ES: (Segment override prefix)
		Seg = SEG_ES;
		++EIP;
		return;
	case 0x27: { // DAA
		const ubyte oldAL = AL;
		const ubyte oldCF = CF;
		CF = 0;

		if (((oldAL & 0xF) > 9) || AF) {
			AL = AL + 6;
			CF = oldCF || (AL & 0x80);
			AF = 1;
		} else AF = 0;

		if ((oldAL > 0x99) || oldCF) {
			AL = AL + 0x60;
			CF = 1;
		} else CF = 0;

		++EIP;
		return;
	}
	case 0x28: { // SUB R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= AL; break;
		case RM_REG_001: r -= CL; break;
		case RM_REG_010: r -= DL; break;
		case RM_REG_011: r -= BL; break;
		case RM_REG_100: r -= AH; break;
		case RM_REG_101: r -= CH; break;
		case RM_REG_110: r -= DH; break;
		case RM_REG_111: r -= BH; break;
		default:
		}
		__hflag8_1(r);
		__iu8(r, addr);
		EIP += 2;
		return;
	}
	case 0x29: { // SUB R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= AX; break;
		case RM_REG_001: r -= CX; break;
		case RM_REG_010: r -= DX; break;
		case RM_REG_011: r -= BX; break;
		case RM_REG_100: r -= SP; break;
		case RM_REG_101: r -= BP; break;
		case RM_REG_110: r -= SI; break;
		case RM_REG_111: r -= DI; break;
		default:
		}
		__hflag16_1(r);
		__iu16(r, addr);
		EIP += 2;
		return;
	}
	case 0x2A: { // SUB REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = AL - r;
			AL = r;
			break;
		case RM_REG_001:
			r = CL - r;
			CL = r;
			break;
		case RM_REG_010:
			r = DL - r;
			DL = r;
			break;
		case RM_REG_011:
			r = BL - r;
			BL = r;
			break;
		case RM_REG_100:
			r = AH - r;
			AH = r;
			break;
		case RM_REG_101:
			r = CH - r;
			CH = r;
			break;
		case RM_REG_110:
			r = DH - r;
			DH = r;
			break;
		case RM_REG_111:
			r = BH - r;
			BH = r;
			break;
		default:
		}
		__hflag8_1(r);
		EIP += 2;
		return;
	}
	case 0x2B: { // SUB REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = AX - r;
			AX = r;
			break;
		case RM_REG_001:
			r = CX - r;
			CX = r;
			break;
		case RM_REG_010:
			r = DX - r;
			DX = r;
			break;
		case RM_REG_011:
			r = BX - r;
			BX = r;
			break;
		case RM_REG_100:
			r = SP - r;
			SP = r;
			break;
		case RM_REG_101:
			r = BP - r;
			BP = r;
			break;
		case RM_REG_110:
			r = SI - r;
			SI = r;
			break;
		case RM_REG_111:
			r = DI - r;
			DI = r;
			break;
		default:
		}
		__hflag16_1(r);
		EIP += 2;
		return;
	}
	case 0x2C: { // SUB AL, IMM8
		int r = AL - __fu8_i;
		__hflag8_1(r);
		AL = r;
		EIP += 2;
		return;
	}
	case 0x2D: { // SUB AX, IMM16
		int r = AX - __fu16_i;
		__hflag16_1(r);
		AX = r;
		EIP += 3;
		return;
	}
	case 0x2E: // CS:
		Seg = SEG_CS;
		++EIP;
		return;
	case 0x2F: { // DAS
		const ubyte oldAL = AL;
		const ubyte oldCF = CF;
		CF = 0;

		if (((oldAL & 0xF) > 9) || AF) {
			AL = AL - 6;
			CF = oldCF || (AL & 0x80);
			AF = 1;
		} else AF = 0;

		if ((oldAL > 0x99) || oldCF) {
			AL = AL - 0x60;
			CF = 1;
		} else CF = 0;

		++EIP;
		return;
	}
	case 0x30: { // XOR R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r ^= AL; break;
		case RM_REG_001: r ^= CL; break;
		case RM_REG_010: r ^= DL; break;
		case RM_REG_011: r ^= BL; break;
		case RM_REG_100: r ^= AH; break;
		case RM_REG_101: r ^= CH; break;
		case RM_REG_110: r ^= DH; break;
		case RM_REG_111: r ^= BH; break;
		default:
		}
		__hflag8_3(r);
		__iu8(r, addr);
		EIP += 2;
		return;
	}
	case 0x31: { // XOR R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r ^= AX; break;
		case RM_REG_001: r ^= CX; break;
		case RM_REG_010: r ^= DX; break;
		case RM_REG_011: r ^= BX; break;
		case RM_REG_100: r ^= SP; break;
		case RM_REG_101: r ^= BP; break;
		case RM_REG_110: r ^= SI; break;
		case RM_REG_111: r ^= DI; break;
		default:
		}
		__hflag16_3(r);
		__iu16(r, addr);
		EIP += 2;
		return;
	}
	case 0x32: { // XOR REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = AL ^ r;
			AL = r;
			break;
		case RM_REG_001:
			r = CL ^ r;
			CL = r;
			break;
		case RM_REG_010:
			r = DL ^ r;
			DL = r;
			break;
		case RM_REG_011:
			r = BL ^ r;
			BL = r;
			break;
		case RM_REG_100:
			r = AH ^ r;
			AH = r;
			break;
		case RM_REG_101:
			r = CH ^ r;
			CH = r;
			break;
		case RM_REG_110:
			r = DH ^ r;
			DH = r;
			break;
		case RM_REG_111:
			r = BH ^ r;
			BH = r;
			break;
		default:
		}
		__hflag8_3(r);
		EIP += 2;
		return;
	}
	case 0x33: { // XOR REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000:
			r = AX ^ r;
			AX = r;
			break;
		case RM_REG_001:
			r = CX ^ r;
			CX = r;
			break;
		case RM_REG_010:
			r = DX ^ r;
			DX = r;
			break;
		case RM_REG_011:
			r = BX ^ r;
			BX = r;
			break;
		case RM_REG_100:
			r = SP ^ r;
			SP = r;
			break;
		case RM_REG_101:
			r = BP ^ r;
			BP = r;
			break;
		case RM_REG_110:
			r = SI ^ r;
			SI = r;
			break;
		case RM_REG_111:
			r = DI ^ r;
			DI = r;
			break;
		default:
		}
		__hflag16_3(r);
		EIP += 2;
		return;
	}
	case 0x34: { // XOR AL, IMM8
		int r = AL ^ __fu8_i;
		__hflag8_3(r);
		AL = r;
		EIP += 2;
		return;
	}
	case 0x35: { // XOR AX, IMM16
		int r = AX ^ __fu16_i;
		__hflag16_3(r);
		AX = r;
		EIP += 3;
		return;
	}
	case 0x36: // SS:
		Seg = SEG_SS;
		++EIP;
		return;
	case 0x37: // AAA
		if (((AL & 0xF) > 9) || AF) {
			AX = AX + 0x106;
			AF = CF = 1;
		} else AF = CF = 0;
		AL = AL & 0xF;
		++EIP;
		return;
	case 0x38: { // CMP R/M8, REG8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= AL; break;
		case RM_REG_001: r -= CL; break;
		case RM_REG_010: r -= DL; break;
		case RM_REG_011: r -= BL; break;
		case RM_REG_100: r -= AH; break;
		case RM_REG_101: r -= CH; break;
		case RM_REG_110: r -= DH; break;
		case RM_REG_111: r -= BH; break;
		default:
		}
		__hflag8_1(r);
		EIP += 2;
		return;
	}
	case 0x39: { // CMP R/M16, REG16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r -= AX; break;
		case RM_REG_001: r -= CX; break;
		case RM_REG_010: r -= DX; break;
		case RM_REG_011: r -= BX; break;
		case RM_REG_100: r -= SP; break;
		case RM_REG_101: r -= BP; break;
		case RM_REG_110: r -= SI; break;
		case RM_REG_111: r -= DI; break;
		default:
		}
		__hflag16_1(r);
		EIP += 2;
		return;
	}
	case 0x3A: { // CMP REG8, R/M8
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r = AL - r; break;
		case RM_REG_001: r = CL - r; break;
		case RM_REG_010: r = DL - r; break;
		case RM_REG_011: r = BL - r; break;
		case RM_REG_100: r = AH - r; break;
		case RM_REG_101: r = CH - r; break;
		case RM_REG_110: r = DH - r; break;
		case RM_REG_111: r = BH - r; break;
		default:
		}
		__hflag8_1(r);
		EIP += 2;
		return;
	}
	case 0x3B: { // CMP REG16, R/M16
		const ubyte rm = __fu8_i;
		const uint addr = get_ea(rm, 1);
		int r = __fu16(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: r = AX - r; break;
		case RM_REG_001: r = CX - r; break;
		case RM_REG_010: r = DX - r; break;
		case RM_REG_011: r = BX - r; break;
		case RM_REG_100: r = SP - r; break;
		case RM_REG_101: r = BP - r; break;
		case RM_REG_110: r = SI - r; break;
		case RM_REG_111: r = DI - r; break;
		default:
		}
		__hflag16_1(r);
		EIP += 2;
		return;
	}
	case 0x3C: { // CMP AL, IMM8
		__hflag8_1(AL - __fu8_i);
		EIP += 2;
		return;
	}
	case 0x3D: { // CMP AX, IMM16
		__hflag16_1(AX - __fu16_i);
		EIP += 3;
		return;
	}
	case 0x3E: // DS:
		Seg = SEG_DS;
		++EIP;
		return;
	case 0x3F: // AAS
		if (((AL & 0xF) > 9) || AF) {
			AX = AX - 6;
			AH = AH - 1;
			AF = CF = 1;
		} else {
			AF = CF = 0;
		}
		AL = AL & 0xF;
		++EIP;
		return;
	case 0x40: { // INC AX
		const int r = AX + 1;
		__hflag16_2(r);
		AX = r;
		++EIP;
		return;
	}
	case 0x41: { // INC CX
		const int r = CX + 1;
		__hflag16_2(r);
		CX = r;
		++EIP;
		return;
	}
	case 0x42: { // INC DX
		const int r = DX + 1;
		__hflag16_2(r);
		DX = r;
		++EIP;
		return;
	}
	case 0x43: { // INC BX
		const int r = BX + 1;
		__hflag16_2(r);
		BX = r;
		++EIP;
		return;
	}
	case 0x44: { // INC SP
		const int r = SP + 1;
		__hflag16_2(r);
		SP = r;
		++EIP;
		return;
	}
	case 0x45: { // INC BP
		const int r = BP + 1;
		__hflag16_2(r);
		BP = r;
		++EIP;
		return;
	}
	case 0x46: { // INC SI
		const int r = SI + 1;
		__hflag16_2(r);
		SI = r;
		++EIP;
		return;
	}
	case 0x47: { // INC DI
		const int r = DI + 1;
		__hflag16_2(r);
		DI = r;
		++EIP;
		return;
	}
	case 0x48: { // DEC AX
		const int r = AX - 1;
		__hflag16_2(r);
		AX = r;
		++EIP;
		return;
	}
	case 0x49: { // DEC CX
		const int r = CX - 1;
		__hflag16_2(r);
		CX = r;
		++EIP;
		return;
	}
	case 0x4A: { // DEC DX
		const int r = DX - 1;
		__hflag16_2(r);
		DX = r;
		++EIP;
		return;
	}
	case 0x4B: { // DEC BX
		const int r = BX - 1;
		__hflag16_2(r);
		BX = r;
		++EIP;
		return;
	}
	case 0x4C: { // DEC SP
		const int r = SP - 1;
		__hflag16_2(r);
		SP = r;
		++EIP;
		return;
	}
	case 0x4D: { // DEC BP
		const int r = BP - 1;
		__hflag16_2(r);
		BP = r;
		++EIP;
		return;
	}
	case 0x4E: { // DEC SI
		const int r = SI - 1;
		__hflag16_2(r);
		SI = r;
		++EIP;
		return;
	}
	case 0x4F: { // DEC DI
		const int r = DI - 1;
		__hflag16_2(r);
		DI = r;
		++EIP;
		return;
	}
	case 0x50: // PUSH AX
		push(AX);
		++EIP;
		return;
	case 0x51: // PUSH CX
		push(CX);
		++EIP;
		return;
	case 0x52: // PUSH DX
		push(DX);
		++EIP;
		return;
	case 0x53: // PUSH BX
		push(BX);
		++EIP;
		return;
	case 0x54: // PUSH SP
		push(SP);
		++EIP;
		return;
	case 0x55: // PUSH BP
		push(BP);
		++EIP;
		return;
	case 0x56: // PUSH SI
		push(SI);
		++EIP;
		return;
	case 0x57: // PUSH DI
		push(DI);
		++EIP;
		return;
	case 0x58: // POP AX
		AX = pop;
		++EIP;
		return;
	case 0x59: // POP CX
		CX = pop;
		++EIP;
		return;
	case 0x5A: // POP DX
		DX = pop;
		++EIP;
		return;
	case 0x5B: // POP BX
		BX = pop;
		++EIP;
		return;
	case 0x5C: // POP SP
		SP = pop;
		++EIP;
		return;
	case 0x5D: // POP BP
		BP = pop;
		++EIP;
		return;
	case 0x5E: // POP SI
		SI = pop;
		++EIP;
		return;
	case 0x5F: // POP DI
		DI = pop;
		++EIP;
		return;
	case 0x70: // JO            SHORT-LABEL
		EIP += OF ? __fi8_i : 2;
		return;
	case 0x71: // JNO           SHORT-LABEL
		EIP += OF ? 2 : __fi8_i;
		return;
	case 0x72: // JB/JNAE/JC    SHORT-LABEL
		EIP += CF ? __fi8_i : 2;
		return;
	case 0x73: // JNB/JAE/JNC   SHORT-LABEL
		EIP += CF ? 2 : __fi8_i;
		return;
	case 0x74: // JE/JZ         SHORT-LABEL
		EIP += ZF ? __fi8_i : 2;
		return;
	case 0x75: // JNE/JNZ       SHORT-LABEL
		EIP += ZF ? 2 : __fi8_i;
		return;
	case 0x76: // JBE/JNA       SHORT-LABEL
		EIP += (CF || ZF) ? __fi8_i : 2;
		return;
	case 0x77: // JNBE/JA       SHORT-LABEL
		EIP += CF == 0 && ZF == 0 ? __fi8_i : 2;
		return;
	case 0x78: // JS            SHORT-LABEL
		EIP += SF ? __fi8_i : 2;
		return;
	case 0x79: // JNS           SHORT-LABEL
		EIP += SF ? 2 : __fi8_i;
		return;
	case 0x7A: // JP/JPE        SHORT-LABEL
		EIP += PF ? __fi8_i : 2;
		return;
	case 0x7B: // JNP/JPO       SHORT-LABEL
		EIP += PF ? 2 : __fi8_i;
		return;
	case 0x7C: // JL/JNGE       SHORT-LABEL
		EIP += SF != OF ? __fi8_i : 2;
		return;
	case 0x7D: // JNL/JGE       SHORT-LABEL
		EIP += SF == OF ? __fi8_i : 2;
		return;
	case 0x7E: // JLE/JNG       SHORT-LABEL
		EIP += SF != OF || ZF ? __fi8_i : 2;
		return;
	case 0x7F: // JNLE/JG       SHORT-LABEL
		EIP += SF == OF && ZF == 0 ? __fi8_i : 2;
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
			if (CF) ++r;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (CF) --r;
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
			crit("Invalid ModR/M from GRP1_8");
			goto EXEC_ILLEGAL;
		}
		EIP += 3;
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
			if (CF) ++r;
			__hflag16_1(r);
			__iu16(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (CF) --r;
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
			crit("Invalid ModR/M from GRP1_16");
			goto EXEC_ILLEGAL;
		}
		EIP += 4;
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
			if (CF) ++r;
			__iu8(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (CF) --r;
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
			crit("Invalid ModR/M for GRP2_8");
			goto EXEC_ILLEGAL;
		}
		__hflag8_1(r);
		EIP += 3;
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
			if (CF) ++r;
			__iu16(r, addr);
			break;
		case RM_REG_011: // 011 - SBB
			r -= im;
			if (CF) --r;
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
			crit("Invalid ModR/M for GRP2_16");
			goto EXEC_ILLEGAL;
		}
		__hflag16_1(r);
		EIP += 3;
		return;
	}
	case 0x84: { // TEST R/M8, REG8
		const ubyte rm = __fu8_i;
		int n = __fu8(get_ea(rm));
		int r = void;
		switch (rm & RM_REG) {
		case RM_REG_000: r = AL & n; break;
		case RM_REG_001: r = CL & n; break;
		case RM_REG_010: r = DL & n; break;
		case RM_REG_011: r = BL & n; break;
		case RM_REG_100: r = AH & n; break;
		case RM_REG_101: r = CH & n; break;
		case RM_REG_110: r = DH & n; break;
		case RM_REG_111: r = BH & n; break;
		default:
		}
		__hflag8_3(r);
		EIP += 2;
		return;
	}
	case 0x85: { // TEST R/M16, REG16
		const ubyte rm = __fu8_i;
		int n = __fu16(get_ea(rm, 1));
		int r = void;
		switch (rm & RM_REG) {
		case RM_REG_000: r = AX & n; break;
		case RM_REG_001: r = CX & n; break;
		case RM_REG_010: r = DX & n; break;
		case RM_REG_011: r = BX & n; break;
		case RM_REG_100: r = SP & n; break;
		case RM_REG_101: r = BP & n; break;
		case RM_REG_110: r = SI & n; break;
		case RM_REG_111: r = DI & n; break;
		default:
		}
		__hflag16_3(r);
		EIP += 2;
		return;
	}
	case 0x86: // XCHG REG8, R/M8

		return;
	case 0x87: // XCHG REG16, R/M16

		return;
	case 0x88: { // MOV R/M8, REG8
		const ubyte rm = __fu8_i;
		int addr = get_ea(rm);
		switch (rm & RM_REG) {
		case RM_REG_000: __iu8(AL, addr); break;
		case RM_REG_001: __iu8(CL, addr); break;
		case RM_REG_010: __iu8(DL, addr); break;
		case RM_REG_011: __iu8(BL, addr); break;
		case RM_REG_100: __iu8(AH, addr); break;
		case RM_REG_101: __iu8(CH, addr); break;
		case RM_REG_110: __iu8(DH, addr); break;
		case RM_REG_111: __iu8(BH, addr); break;
		default:
		}
		EIP += 2;
		return;
	}
	case 0x89: { // MOV R/M16, REG16
		const ubyte rm = __fu8_i;
		int addr = get_ea(rm, 1);
		switch (rm & RM_REG) {
		case RM_REG_000: __iu16(AX, addr); break;
		case RM_REG_001: __iu16(CX, addr); break;
		case RM_REG_010: __iu16(DX, addr); break;
		case RM_REG_011: __iu16(BX, addr); break;
		case RM_REG_100: __iu16(SP, addr); break;
		case RM_REG_101: __iu16(BP, addr); break;
		case RM_REG_110: __iu16(SI, addr); break;
		case RM_REG_111: __iu16(DI, addr); break;
		default:
		}
		EIP += 2;
		return;
	}
	case 0x8A: { // MOV REG8, R/M8
		const ubyte rm = __fu8_i;
		int addr = get_ea(rm);
		switch (rm & RM_REG) {
		case RM_REG_000: AL = __fu8(addr); break;
		case RM_REG_001: CL = __fu8(addr); break;
		case RM_REG_010: DL = __fu8(addr); break;
		case RM_REG_011: BL = __fu8(addr); break;
		case RM_REG_100: AH = __fu8(addr); break;
		case RM_REG_101: CH = __fu8(addr); break;
		case RM_REG_110: DH = __fu8(addr); break;
		case RM_REG_111: BH = __fu8(addr); break;
		default:
		}
		EIP += 2;
		return;
	}
	case 0x8B: { // MOV REG16, R/M16
		const ubyte rm = __fu8_i;
		int addr = get_ea(rm, 1);
		switch (rm & RM_REG) {
		case RM_REG_000: AX = __fu16(addr); break;
		case RM_REG_001: CX = __fu16(addr); break;
		case RM_REG_010: DX = __fu16(addr); break;
		case RM_REG_011: BX = __fu16(addr); break;
		case RM_REG_100: SP = __fu16(addr); break;
		case RM_REG_101: BP = __fu16(addr); break;
		case RM_REG_110: SI = __fu16(addr); break;
		case RM_REG_111: DI = __fu16(addr); break;
		default:
		}
		EIP += 2;
		return;
	}
	case 0x8C: { // MOV R/M16, SEGREG
		// MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
		const byte rm = __fu8_i;
		const int ea = get_ea(rm, 1);
		switch (rm & RM_REG) { // if REG[3] is clear, trip to default
		case RM_REG_100: // ES
			__iu16(ES, ea);
			break;
		case RM_REG_101: // CS
			__iu16(CS, ea);
			break;
		case RM_REG_110: // SS
			__iu16(SS, ea);
			break;
		case RM_REG_111: // DS
			__iu16(DS, ea);
			break;
		default: // when 100_000 is clear
			crit("Invalid ModR/M for SEGREG->RM");
			goto EXEC_ILLEGAL;
		}
		EIP += 2;
		return;
	}
	case 0x8D: { // LEA REG16, MEM16
		const ubyte rm = __fu8_i;
		int addr = get_ea(rm);
		switch (rm & RM_REG) {
		case RM_REG_000: AX = cast(ushort)addr; break;
		case RM_REG_001: CX = cast(ushort)addr; break;
		case RM_REG_010: DX = cast(ushort)addr; break;
		case RM_REG_011: BX = cast(ushort)addr; break;
		case RM_REG_100: BP = cast(ushort)addr; break;
		case RM_REG_101: SP = cast(ushort)addr; break;
		case RM_REG_110: SI = cast(ushort)addr; break;
		case RM_REG_111: DI = cast(ushort)addr; break;
		default: // Never happens
		}
		EIP += 2;
		return;
	}
	case 0x8E: { // MOV SEGREG, R/M16
		// MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
		const byte rm = __fu8_i;
		const int ea = get_ea(rm, 1);
		switch (rm & RM_REG) { // if bit 10_0000 is clear, trip to default
		case RM_REG_100: // ES
			ES = __fu16(ea);
			break;
		case RM_REG_101: // CS
			CS = __fu16(ea);
			break;
		case RM_REG_110: // SS
			SS = __fu16(ea);
			break;
		case RM_REG_111: // DS
			DS = __fu16(ea);
			break;
		default: // when 100_000 is clear
			crit("Invalid ModR/M for SEGREG<-RM");
			goto EXEC_ILLEGAL;
		}
		EIP += 2;
		return;
	}
	case 0x8F: { // POP R/M16
		const ubyte rm = __fu8_i;
		if (rm & RM_REG) { // REG MUST be 000
			//TODO: Raise illegal instruction
			crit("Invalid ModR/M for POP");
			goto EXEC_ILLEGAL;
		} else {
			const ushort imm = __fu16_i(1);
			//TODO: POP R/M16
		}
		EIP += 2;
		return;
	}
	case 0x90: // NOP (aka XCHG AX, AX)
		++EIP;
		return;
	case 0x91: { // XCHG AX, CX
		const ushort r = AX;
		AX = CX;
		CX = r;
		++EIP;
		return;
	}
	case 0x92: { // XCHG AX, DX
		const ushort r = AX;
		AX = DX;
		DX = r;
		++EIP;
		return;
	}
	case 0x93: { // XCHG AX, BX
		const ushort r = AX;
		AX = BX;
		BX = r;
		++EIP;
		return;
	}
	case 0x94: { // XCHG AX, SP
		const ushort r = AX;
		AX = SP;
		SP = r;
		++EIP;
		return;
	}
	case 0x95: { // XCHG AX, BP
		const ushort r = AX;
		AX = BP;
		BP = r;
		++EIP;
		return;
	}
	case 0x96: { // XCHG AX, SI
		const ushort r = AX;
		AX = SI;
		SI = r;
		++EIP;
		return;
	}
	case 0x97: { // XCHG AX, DI
		const ushort r = AX;
		AX = DI;
		DI = r;
		++EIP;
		return;
	}
	case 0x98: // CBW
		AH = AL & 0x80 ? 0xFF : 0;
		++EIP;
		return;
	case 0x99: // CWD
		DX = AX & 0x8000 ? 0xFFFF : 0;
		++EIP;
		return;
	case 0x9A: // CALL FAR_PROC
		push(CS);
		push(IP);
		CS = __fu16_i;
		IP = __fu16_i(2);
		return;
	case 0x9B: // WAIT
	/* Causes the processor to check for and handle pending, unmasked,
	   floating-point exceptions before proceeding. */
	//TODO: WAIT
		++EIP;
		return;
	case 0x9C: // PUSHF
		push(FLAG);
		++EIP;
		return;
	case 0x9D: // POPF
		FLAG = pop;
		++EIP;
		return;
	case 0x9E: // SAHF (AH to Flags)
		FLAGB = AH;
		++EIP;
		return;
	case 0x9F: // LAHF (Flags to AH)
		AH = FLAGB;
		++EIP;
		return;
	case 0xA0: // MOV AL, MEM8
		AL = __fu8(__fu16_i);
		EIP += 2;
		return;
	case 0xA1: // MOV AX, MEM16
		AX = __fu16(__fu16_i);
		EIP += 3;
		return;
	case 0xA2: // MOV MEM8, AL
		__iu8(AL, __fu16_i);
		EIP += 2;
		return;
	case 0xA3: // MOV MEM16, AX
		__iu16(AX, __fu16_i);
		EIP += 3;
		return;
	case 0xA4: // MOVS DEST-STR8, SRC-STR8

		return;
	case 0xA5: // MOVS DEST-STR16, SRC-STR16

		return;
	case 0xA6: // CMPS DEST-STR8, SRC-STR8
		__hflag8_1(
			__fu8(get_ad(DS, SI)) - __fu8(get_ad(ES, DI))
		);
		if (DF) {
			DI = DI - 1;
			SI = SI - 1;
		} else {
			DI = DI + 1;
			SI = SI + 1;
		}
		return;
	case 0xA7: // CMPSW DEST-STR16, SRC-STR16
		__hflag16_1(
			__fu16(get_ad(DS, SI)) - __fu16(get_ad(ES, DI))
		);
		if (DF) {
			DI = DI - 2;
			SI = SI - 2;
		} else {
			DI = DI + 2;
			SI = SI + 2;
		}
		return;
	case 0xA8: // TEST AL, IMM8
		__hflag8_3(AL & __fu8_i);
		EIP += 2;
		return;
	case 0xA9: // TEST AX, IMM16
		__hflag16_3(AX & __fu16_i);
		EIP += 3;
		return;
	case 0xAA: // STOS DEST-STR8
		__iu8(AL, get_ad(ES, DI));
		DI = DF ? DI - 1 : DI + 1;
		++EIP;
		return;
	case 0xAB: // STOS DEST-STR16
		__iu16(AX, get_ad(ES, DI));
		DI = DF ? DI - 2 : DI + 2;
		++EIP;
		return;
	case 0xAC: // LODS SRC-STR8
		AL = __fu8(get_ad(DS, SI));
		SI = DF ? SI - 1 : SI + 1;
		++EIP;
		return;
	case 0xAD: // LODS SRC-STR16
		AX = __fu16(get_ad(DS, SI));
		SI = DF ? SI - 2 : SI + 2;
		++EIP;
		return;
	case 0xAE: // SCAS DEST-STR8
		__hflag8_1(AL - __fu8(get_ad(ES, DI)));
		DI = DF ? DI - 1 : DI + 1;
		++EIP;
		return;
	case 0xAF: // SCAS DEST-STR16
		__hflag16_1(AX - __fu16(get_ad(ES, DI)));
		DI = DF ? DI - 2 : DI + 2;
		++EIP;
		return;
	case 0xB0: // MOV AL, IMM8
		AL = __fu8_i;
		EIP += 2;
		return;
	case 0xB1: // MOV CL, IMM8
		CL = __fu8_i;
		EIP += 2;
		return;
	case 0xB2: // MOV DL, IMM8
		DL = __fu8_i;
		EIP += 2;
		return;
	case 0xB3: // MOV BL, IMM8
		BL = __fu8_i;
		EIP += 2;
		return;
	case 0xB4: // MOV AH, IMM8
		AH = __fu8_i;
		EIP += 2;
		return;
	case 0xB5: // MOV CH, IMM8
		CH = __fu8_i;
		EIP += 2;
		return;
	case 0xB6: // MOV DH, IMM8  
		DH = __fu8_i;
		EIP += 2;
		return;
	case 0xB7: // MOV BH, IMM8
		BH = __fu8_i;
		EIP += 2;
		return;
	case 0xB8: // MOV AX, IMM16
		AX = __fu16_i;
		EIP += 3;
		return;
	case 0xB9: // MOV CX, IMM16
		CX = __fu16_i;
		EIP += 3;
		return;
	case 0xBA: // MOV DX, IMM16
		DX = __fu16_i;
		EIP += 3;
		return;
	case 0xBB: // MOV BX, IMM16
		BX = __fu16_i;
		EIP += 3;
		return;
	case 0xBC: // MOV SP, IMM16
		SP = __fu16_i;
		EIP += 3;
		return;
	case 0xBD: // MOV BP, IMM16
		BP = __fu16_i;
		EIP += 3;
		return;
	case 0xBE: // MOV SI, IMM16
		SI = __fu16_i;
		EIP += 3;
		return;
	case 0xBF: // MOV DI, IMM16
		DI = __fu16_i;
		EIP += 3;
		return;
	case 0xC2: // RET IMM16 (NEAR)
		IP = pop;
		SP = cast(ushort)(SP + __fu16_i);
		//EIP += 3; ?
		return;
	case 0xC3: // RET (NEAR)
		IP = pop;
		return;
	case 0xC4: // LES REG16, MEM16
		// Load into REG and ES
		
		return;
	case 0xC5: // LDS REG16, MEM16
		// Load into REG and DS

		return;
	case 0xC6: { // MOV MEM8, IMM8
		const ubyte rm = __fu8_i;
		if (rm & RM_REG) { // No register operation allowed
			//TODO: Raise #GP
			crit("Invalid ModR/M for MOV MEM8");
		} else {
			__iu8(__fu8_i(1), get_ea(rm));
		}
		return;
	}
	case 0xC7: { // MOV MEM16, IMM16
		const ubyte rm = __fu8_i;
		if (rm & RM_REG) { // No register operation allowed
			//TODO: Raise #GP
			crit("Invalid ModR/M for MOV MEM16");
		} else {
			__iu16(__fu16_i(1), get_ea(rm));
		}
		return;
	}
	case 0xCA: // RET IMM16 (FAR)
		IP = pop;
		CS = pop;
		SP = SP + __fu16_i;
		return;
	case 0xCB: // RET (FAR)
		IP = pop;
		CS = pop;
		return;
	case 0xCC: // INT 3
		Raise(3);
		++EIP;
		return;
	case 0xCD: // INT IMM8
		Raise(__fu8_i);
		EIP += 2;
		return;
	case 0xCE: // INTO
		if (CF) Raise(4);
		++EIP;
		return;
	case 0xCF: // IRET
		IP = pop;
		CS = pop;
		FLAG = pop;
		++EIP;
		return;
	case 0xD0: { // GRP2 R/M8, 1
		/*byte rm; // Get ModR/M byte
		switch (rm & 0b00111000) {
		case 0b00000000: // 000 - ROL

		break;
		case 0b00001000: // 001 - ROR

		break;
		case 0b00010000: // 010 - RCL

		break;
		case 0b00011000: // 011 - RCR

		break;
		case 0b00100000: // 100 - SAL/SHL

		break;
		case 0b00101000: // 101 - SHR

		break;
		case 0b00111000: // 111 - SAR

		break;
		default:
			
			break;
		}*/
		return;
	}
	case 0xD1: // GRP2 R/M16, 1
		/*byte rm; // Get ModR/M byte
		switch (rm & 0b00111000) {
		case 0b00000000: // 000 - ROL

		break;
		case 0b00001000: // 001 - ROR

		break;
		case 0b00010000: // 010 - RCL

		break;
		case 0b00011000: // 011 - RCR

		break;
		case 0b00100000: // 100 - SAL/SHL

		break;
		case 0b00101000: // 101 - SHR

		break;
		case 0b00111000: // 111 - SAR

		break;
		default:

		break;
		}*/
		return;
	case 0xD2: // GRP2 R/M8, CL
		/*byte rm; // Get ModR/M byte
		switch (rm & 0b00111000) {
		case 0b00000000: // 000 - ROL

		break;
		case 0b00001000: // 001 - ROR

		break;
		case 0b00010000: // 010 - RCL

		break;
		case 0b00011000: // 011 - RCR

		break;
		case 0b00100000: // 100 - SAL/SHL

		break;
		case 0b00101000: // 101 - SHR

		break;
		case 0b00111000: // 111 - SAR

		break;
		default:

		break;
		}*/
		return;
	case 0xD3: // GRP2 R/M16, CL
		/*byte rm; // Get ModR/M byte
		switch (rm & 0b00111000) {
		case 0b00000000: // 000 - ROL

		break;
		case 0b00001000: // 001 - ROR

		break;
		case 0b00010000: // 010 - RCL

		break;
		case 0b00011000: // 011 - RCR

		break;
		case 0b00100000: // 100 - SAL/SHL

		break;
		case 0b00101000: // 101 - SHR

		break;
		case 0b00111000: // 111 - SAR

		break;
		default:

		break;
		}*/
		return;
	case 0xD4: // AAM
		AH = cast(ubyte)(AL / 0xA);
		AL = cast(ubyte)(AL % 0xA);
		++EIP;
		return;
	case 0xD5: // AAD
		AL = cast(ubyte)(AL + (AH * 0xA));
		AH = 0;
		++EIP;
		return;
	// D6h is illegal under 8086
	case 0xD7: // XLAT SOURCE-TABLE
		AL = __fu8(get_ad(DS, BX) + AL);
		return;
	/*case 0xD8: // ESC OPCODE, SOURCE
	case 0xD9: // 1101 1XXX - MOD YYY R/M
	case 0xDA: // Used to escape to another co-processor.
	case 0xDB: 
	case 0xDC: 
	case 0xDD:
	case 0xDE:
	case 0xDF:

		break;*/
	case 0xE0: // LOOPNE/LOOPNZ SHORT-LABEL
		CX = CX - 1;
		if (CX && ZF == 0) EIP += __fi8_i;
		else               EIP += 2;
		return;
	case 0xE1: // LOOPE/LOOPZ   SHORT-LABEL
		CX = CX - 1;
		if (CX && ZF) EIP += __fi8_i;
		else          EIP += 2;
		return;
	case 0xE2: // LOOP  SHORT-LABEL
		CX = CX - 1;
		if (CX) EIP += __fi8_i;
		else    EIP += 2;
		return;
	case 0xE3: // JCXZ  SHORT-LABEL
		if (CX == 0) EIP += __fi8_i;
		else         EIP += 2;
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
		push(IP);
		EIP += __fi16_i; // Direct within segment
		return;
	case 0xE9: // JMP    NEAR-LABEL
		EIP += __fi16_i; // ±32 KB
		return;
	case 0xEA: // JMP  FAR-LABEL
		// Any segment, any fragment, 5 byte instruction.
		// EAh (LO-IP) (HI-IP) (LO-CS) (HI-CS)
		IP = __fu16_i;
		CS = __fu16_i(2);
		return;
	case 0xEB: // JMP  SHORT-LABEL
		EIP += __fi8_i; // ±128 B
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
		++EIP;
		return;
	case 0xF2: // REPNE/REPNZ
_F2_CX:	if (CX) {
			//TODO: Finish REPNE/REPNZ properly?
			exec(0xA6);
			CX = CX - 1;
			if (ZF == 0) goto _F2_CX;
		} else ++EIP;
		return;
	case 0xF3: // REP/REPE/REPNZ

		return;
	case 0xF4: // HLT
		RLEVEL = 0;
		++EIP;
		return;
	case 0xF5: // CMC
		CF = !CF;
		++EIP;
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
			CF = cast(ubyte)r;
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
			r = AX / d;
			AH = cast(ubyte)(AX % d);
			AL = cast(ubyte)(r);
			break;
		case RM_REG_111: // 111 - IDIV
		//TODO: Check if im == 0 (#DE), IDIV
			byte d = __fi8(addr);
			r = cast(short)AX / d;
			AH = cast(short)AX % d;
			AL = cast(ubyte)r;
			break;
		default:
			crit("Invalid ModR/M on GRP3_8");
		}
		EIP += 3;
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
			CF = cast(ubyte)r;
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
			error("Invalid ModR/M on GRP3_8");
		}
		EIP += 4;
		return;
	}
	case 0xF8: // CLC
		CF = 0;
		++EIP;
		return;
	case 0xF9: // STC
		CF = 1;
		++EIP;
		return;
	case 0xFA: // CLI
		IF = 0;
		++EIP;
		return;
	case 0xFB: // STI
		IF = 1;
		++EIP;
		return;
	case 0xFC: // CLD
		DF = 0;
		++EIP;
		return;
	case 0xFD: // STD
		DF = 1;
		++EIP;
		return;
	case 0xFE: { // GRP4 R/M8
		const ubyte rm = __fu8_i;
		uint addr = get_ea(rm);
		int r = __fu8(addr);
		switch (rm & RM_REG) {
		case RM_REG_000: // 000 - INC
			++r;
			break;
		case RM_REG_001: // 001 - DEC
			--r;
			break;
		default:
			error("Invalid ModR/M on GRP4_8");
			goto EXEC_ILLEGAL;
		}
		__iu16(r, addr);
		__hflag16_2(r);
		EIP += 2;
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
			EIP += 2;
			return;
		case RM_REG_001: // 001 - DEC
			--r;
			__iu16(r, addr);
			__hflag16_2(r);
			EIP += 2;
			break;
		case RM_REG_010: // 010 - CALL R/M16 (near) -- Indirect within segment
			push(IP);
			EIP = r;
			break;
		case RM_REG_011: // 011 - CALL MEM16 (far) -- Indirect outside segment
			push(CS);
			push(IP);
			EIP = get_ad(__fu16(addr + 2), r);
			break;
		case RM_REG_100: // 100 - JMP R/M16 (near) -- Indirect within segment
			EIP = r;
			break;
		case RM_REG_101: // 101 - JMP MEM16 (far) -- Indirect outside segment
			EIP = get_ad(__fu16(addr + 2), r);
			break;
		case RM_REG_110: // 110 - PUSH MEM16
			push(__fu16(get_ad(__fu16(addr + 2), r)));
			EIP += 2;
			break;
		default:
			error("Invalid ModR/M on GRP5_16");
			goto EXEC_ILLEGAL;
		}
		return;
	}
	default: // Illegal instruction
EXEC_ILLEGAL:
		error("INVALID OPERATION CODE");
		//TODO: Raise vector on illegal op
		return;
	}
}