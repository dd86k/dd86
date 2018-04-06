/*
 * Interpreter.d: Legacy machine code interpreter.
 * 
 * Right now it's closest to an 8086 (REAL-MODE)
 * I hope to make it closer to an i486 whenever possible.
 */

module Interpreter;

import core.stdc.stdlib : exit; // Temporary
import core.stdc.stdio : printf, puts;
import dd_dos, InterpreterUtils;
debug import Logger : logexec;

/// Initial and maximum amount of memory if not specified in settings.
enum MAX_MEM = 0x10_0000;
// 0x4_0000    256K -- MS-DOS 256K minimum
// 0xA_0000    640K
// 0x10_0000  1024K
// 0x20_0000  2048K

/// Sleep for n hecto-nanoseconds
extern (C)
private void HSLEEP(int n) {
	//TODO: HSLEEP
}

/// Sleep for n nanoseconds
extern (C)
private void NSLEEP(int n) {
	//TODO: NSLEEP
}

/// Initiate machine (memory, etc.)
extern (C)
void Initiate() {
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

	IP = 0x100; // Temporary

	//TODO: Probably do a FAR JMP to "BIOS" or something else
}

/// Start the emulator at CS:IP (usually 0000h:0100h)
extern (C)
void Run() {
	if (Verbose) puts("[INFO] Interpreter::Run");
	++RLEVEL;
	while (RLEVEL) {
		EIP = GetIPAddress;
		debug logexec(CS, IP, MEMORY[EIP]);
		Execute(MEMORY[EIP]);
		Seg = SEG_NONE; // Reset SEG PREFERENCE after instruction
		if (Sleep) HSLEEP(2); // Intel 8086@~5MHz
	}
}

__gshared ushort RLEVEL; /// Runnning level
__gshared byte Sleep = 1; /// Is vcpu sleeping between cycles?
debug __gshared byte Verbose = 1; /// Is Verbose mode set?
else  __gshared byte Verbose = 0; /// Is Verbose mode set?

/// Main memory brank
// Currently pre-allocated until I do a setting to make that variable
__gshared ubyte[MAX_MEM] MEMORY;
/// Current memory MEMORY size. Default: MAX_MEM
__gshared size_t MEMORYSIZE = MAX_MEM;

/**
 * Get memory address out of a segment and a register value.
 * Params:
 *   s = Segment register value
 *   o  = Generic register value
 * Returns: SEG:ADDR Location
 */
extern (C)
uint GetAddress(int s, int o) {
	return (s << 4) + o;
}
/**
 * Get next instruction location
 * Returns: CS:IP effective address
 */
extern (C)
uint GetIPAddress() {
	return GetAddress(CS, IP);
}

/// RESET instruction function
extern (C)
void Reset() {
	OF = DF = IF = TF = SF =
		ZF = AF = PF = CF = 0;
	CS = 0xFFFF;
	EIP = DS = SS = ES = 0;
	// Empty Queue Bus
}

/// Resets the entire vcpu. Does not refer to the RESET instruction!
extern (C)
void FullReset() {
	Reset();
	EAX = EBX = ECX = EDX =
	EBP = ESP = EDI = ESI = 0;
}

/// Generic register
__gshared uint EAX, EBX, ECX, EDX;
private __gshared ubyte* ALp, BLp, CLp, DLp;
private __gshared ushort* AXp, BXp, CXp, DXp;

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

/*
 * FLAGS
 */

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

__gshared bool
OF, /// Bit 11, Overflow Flag
DF, /// Bit 10, Direction Flag
IF, /// Bit  9, Interrupt Enable Flag
TF, /// Bit  8, Trap Flag
SF, /// Bit  7, Sign Flag
ZF, /// Bit  6, Zero Flag
AF, /// Bit  4, Auxiliary Carry Flag (aka Adjust Flag)
PF, /// Bit  2, Parity Flag
CF; /// Bit  0, Carry Flag

enum : ubyte {
	RM_MOD_00 = 0,   /// MOD 00, Memory Mode, no displacement
	RM_MOD_01 = 64,  /// MOD 01, Memory Mode, 8-bit displacement
	RM_MOD_10 = 128, /// MOD 10, Memory Mode, 16-bit displacement
	RM_MOD_11 = 192, /// MOD 11, Register Mode
	RM_MOD = 192, /// Used for masking the MOD bits

	RM_REG_000 = 0,  /// AX
	RM_REG_001 = 8,  /// CX
	RM_REG_010 = 16, /// DX
	RM_REG_011 = 24, /// BX
	RM_REG_100 = 32, /// SP
	RM_REG_101 = 40, /// BP
	RM_REG_110 = 48, /// SI
	RM_REG_111 = 56, /// DI
	RM_REG = 56, /// Used for masking the REG bits

	RM_RM_000 = 0, /// R/M 000 bits
	RM_RM_001 = 1, /// R/M 001 bits
	RM_RM_010 = 2, /// R/M 010 bits
	RM_RM_011 = 3, /// R/M 011 bits
	RM_RM_100 = 4, /// R/M 100 bits
	RM_RM_101 = 5, /// R/M 101 bits
	RM_RM_110 = 6, /// R/M 110 bits
	RM_RM_111 = 7, /// R/M 111 bits
	RM_RM = 7, /// Used for masking the R/M bits
}

/**
 * Push a WORD value into memory.
 * Params: value = WORD value to PUSH
 */
extern (C)
void Push(ushort value) {
	SP = SP - 2;
	InsertWord(value, GetAddress(SS, SP));
}
/**
 * Push a DWORD value into memory.
 * Params: value = DWORD value
 */
extern (C)
void EPush(uint value) {
	SP = SP - 2;
	InsertDWord(value, GetAddress(SS, SP));
}
/**
 * Pop a WORD value from stack.
 * Returns: WORD value
 */
extern (C)
ushort Pop() {
	const uint addr = GetAddress(SS, SP);
	SP = SP + 2;
	return FetchWord(addr);
}
/**
 * Pop a WORD value from stack.
 * Returns: WORD value
 */
extern (C)
uint EPop() {
	const uint addr = GetAddress(SS, SP);
	SP = SP + 2;
	return FetchDWord(addr);
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
	SF = (flag & MASK_SF) != 0;
	ZF = (flag & MASK_ZF) != 0;
	AF = (flag & MASK_AF) != 0;
	PF = (flag & MASK_PF) != 0;
	CF = (flag & MASK_CF) != 0;
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

enum : ubyte { // Segment override (for Seg)
	SEG_NONE, /// Default, only exists to "reset" the preference.
	SEG_CS, /// CS
	SEG_DS, /// DS
	SEG_ES, /// ES
	SEG_SS  /// SS
}
/// Preferred Segment register
__gshared ubyte Seg; // See above enumeration

//TODO: Step function for increasing IP value (and StepL for multiple steps)
//      This would assure CS:IP/EIP proper incrementing depending on mode

// Rest of the source here is solely this function.
/**
 * Execute an operation code, acts like the ALU from an Intel 8086.
 * Params: op = Operation Code
 */
extern (C)
void Execute(ubyte op) {
	/*
	 * Legend:
	 * R/M - Mod Register/Memory byte
	 * IMM - Immediate value
	 * REG - Register
	 * MEM - Memory location
	 * SEGREG - Segment register
	 * 
	 * The number represents bitness.
	 */
	switch (op) {
		// case 0 is temporary commented to avoid log spam while debugging
	/*case 0x00: { // ADD R/M8, REG8

		return;
	}*/
	case 0x01: { // ADD R/M16, REG16
		const ubyte rm = FetchImmByte;
		const uint addr = GetEA(rm);
		switch (rm & RM_MOD) {
		case RM_MOD_00:
			switch (rm & RM_REG) {
			case RM_REG_000: // AX
				InsertWord(FetchWord(addr) + AX, addr);
				break;
			case RM_REG_001: // CX
				InsertWord(FetchWord(addr) + CX, addr);
				break;
			case RM_REG_010: // DX
				InsertWord(FetchWord(addr) + DX, addr);
				break;
			case RM_REG_011: // BX
				InsertWord(FetchWord(addr) + BX, addr);
				break;
			case RM_REG_100: // SP
				InsertWord(FetchWord(addr) + SP, addr);
				break;
			case RM_REG_101: // BP
				InsertWord(FetchWord(addr) + BP, addr);
				break;
			case RM_REG_110: // SI
				InsertWord(FetchWord(addr) + SI, addr);
				break;
			case RM_REG_111: // DI
				InsertWord(FetchWord(addr) + DI, addr);
				break;
			default:
			}
			break; // MOD 00
		case RM_MOD_01:

			EIP += 1;
			break; // MOD 01
		case RM_MOD_10:

			EIP += 2;
			break; // MOD 10
		case RM_MOD_11:
			switch (rm & RM_REG) {
			default:
			}
			break; // MOD 11
		default:
		}
		EIP += 2;
		return;
	}
	case 0x02: { // ADD REG8, R/M8

		return;
	}
	case 0x03: { // ADD REG16, R/M16

		return;
	}
	case 0x04: // ADD AL, IMM8
		AL = AL + FetchByte(GetIPAddress);
		SF = CF = (AL & 0x80) != 0;
		PF = (AL & 1) != 0;
		AF = (AL & 0x10) != 0;
		ZF = AL == 0;
		//TODO: OF
		//OF = 
		EIP += 2;
		return;
	case 0x05: // ADD AX, IMM16
		AX = AX + FetchWord(GetIPAddress);
		//TODO: Fill
		EIP += 2;
		return;
	case 0x06: // PUSH ES
		Push(ES);
		++EIP;
		return;
	case 0x07: // POP ES
		ES = Pop();
		++EIP;
		return;
	case 0x08: { // OR R/M8, REG8

		return;
	}
	case 0x09: { // OR R/M16, REG16

		return;
	}
	case 0x0A: { // OR REG8, R/M8
	
		return;
	}
	case 0x0B: { // OR REG16, R/M16

		return;
	}
	case 0x0C: // OR AL, IMM8
		AL = AL | FetchImmByte;
		EIP += 2;
		return;
	case 0x0D: // OR AX, IMM16
		AX = AX | FetchImmWord;
		EIP += 3;
		return;
	case 0x0E: // PUSH CS
		Push(CS);
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
		int t = AL + FetchImmByte;
		if (CF) ++t;
		AL = t;
		EIP += 2;
		return;
	}
	case 0x15: { // ADC AX, IMM16
		int t = AX + FetchImmWord;
		if (CF) ++t;
		AX = t;
		EIP += 3;
		return;
	}
	case 0x16: // PUSH SS
		Push(SS);
		++EIP;
		return;
	case 0x17: // POP SS
		SS = Pop();
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
		int t = AL - FetchImmByte;
		if (CF) --t;
		AL = t;
		EIP += 2;
		return;
	}
	case 0x1D: { // SBB AX, IMM16
		int t = AX - FetchImmByte;
		if (CF) --t;
		AX = t;
		EIP += 3;
		return;
	}
	case 0x1E: // PUSH DS
		Push(DS);
		++EIP;
		return;
	case 0x1F: // POP DS
		DS = Pop();
		++EIP;
		return;
	case 0x20: // AND R/M8, REG8

		return;
	case 0x21: // AND R/M16, REG16

		return;
	case 0x22: // AND REG8, R/M8

		return;
	case 0x23: // AND REG16, R/M16

		return;
	case 0x24: // AND AL, IMM8
		AL = AL & FetchByte(GetIPAddress);
		EIP += 2;
		return;
	case 0x25: // AND AX, IMM16
		AX = AX & FetchWord(GetIPAddress);
		EIP += 3;
		return;
	case 0x26: // ES: (Segment override prefix)
		Seg = SEG_ES;
		++EIP;
		return;
	case 0x27: { // DAA
		const ubyte oldAL = AL;
		const bool oldCF = CF;
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
	case 0x28: // SUB R/M8, REG8

		return;
	case 0x29: // SUB R/M16, REG16

		return;
	case 0x2A: // SUB REG8, R/M8
	
		return;
	case 0x2B: // SUB REG16, R/M16

		return;
	case 0x2C: // SUB AL, IMM8
		AL = AL - FetchByte(GetIPAddress);
		EIP += 2;
		return;
	case 0x2D: // SUB AX, IMM16
		AX = AX - FetchWord(GetIPAddress);
		EIP += 3;
		return;
	case 0x2E: // CS:
		Seg = SEG_CS;
		++EIP;
		return;
	case 0x2F: { // DAS
		const ubyte oldAL = AL;
		const bool oldCF = CF;
		CF = 0;

		if (((oldAL & 0xF) > 9) || AF) {
			AL = AL - 6;
			CF = oldCF || (AL & 0b10000000);
			AF = 1;
		} else AF = 0;

		if ((oldAL > 0x99) || oldCF) {
			AL = AL - 0x60;
			CF = 1;
		} else CF = 0;

		++EIP;
		return;
	}
	case 0x30: // XOR R/M8, REG8

		return;
	case 0x31: // XOR R/M16, REG16

		return;
	case 0x32: // XOR REG8, R/M8

		return;
	case 0x33: // XOR REG16, R/M16

		return;
	case 0x34: // XOR AL, IMM8
		AL = AL ^ FetchImmByte;
		EIP += 2;
		return;
	case 0x35: // XOR AX, IMM16
		AX = AX ^ FetchImmWord;
		EIP += 3;
		return;
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
	case 0x38: // CMP R/M8, REG8

		return;
	case 0x39: // CMP R/M16, REG16

		return;
	case 0x3A: // CMP REG8, R/M8

		return;
	case 0x3B: // CMP REG16, R/M16

		return;
	case 0x3C: { // CMP AL, IMM8
		const ubyte b = FetchByte(GetIPAddress);
		const int r = AL - b;
		CF = SF = (r & 0x80) != 0;
		OF = r < 0;
		ZF = r == 0;
		AF = (r & 0x10) != 0; //((AL & 0b1000) - (b & 0b1000)) < 0;
		//PF =
		EIP += 2;
		return;
	}
	case 0x3D: { // CMP AX, IMM16
		const ushort w = FetchWord(GetIPAddress);
		const int r = AL - w;
		SF = (r & 0x8000) != 0;
		OF = r < 0;
		ZF = r == 0;
		//AF = 
		//PF =
		//CF =
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
		ZF = r == 0;
		SF = (r & 0x8000) != 0;
		AF = (r & 0x10) != 0;
		//PF =
		//OF =
		AX = r;
		++EIP;
		return;
	}
	case 0x41: // INC CX
		CX = CX + 1;
		++EIP;
		return;
	case 0x42: // INC DX
		DX = DX + 1;
		++EIP;
		return;
	case 0x43: // INC BX
		BX = BX + 1;
		++EIP;
		return;
	case 0x44: // INC SP
		SP = SP + 1;
		++EIP;
		return;
	case 0x45: // INC BP
		BP = BP + 1;
		++EIP;
		return;
	case 0x46: // INC SI
		SI = SI + 1;
		++EIP;
		return;
	case 0x47: // INC DI
		DI = DI + 1;
		++EIP;
		return;
	case 0x48: // DEC AX
		AX = AX - 1;
		++EIP;
		return;
	case 0x49: // DEC CX
		CX = CX - 1;
		++EIP;
		return;
	case 0x4A: // DEC DX
		DX = DX - 1;
		++EIP;
		return;
	case 0x4B: // DEC BX
		BX = BX - 1;
		++EIP;
		return;
	case 0x4C: // DEC SP
		SP = SP - 1;
		++EIP;
		return;
	case 0x4D: // DEC BP
		BP = BP - 1;
		++EIP;
		return;
	case 0x4E: // DEC SI
		SI = SI - 1;
		++EIP;
		return;
	case 0x4F: // DEC DI
		DI = DI - 1;
		++EIP;
		return;
	case 0x50: // PUSH AX
		Push(AX);
		++EIP;
		return;
	case 0x51: // PUSH CX
		Push(CX);
		++EIP;
		return;
	case 0x52: // PUSH DX
		Push(DX);
		++EIP;
		return;
	case 0x53: // PUSH BX
		Push(BX);
		++EIP;
		return;
	case 0x54: // PUSH SP
		Push(SP);
		++EIP;
		return;
	case 0x55: // PUSH BP
		Push(BP);
		++EIP;
		return;
	case 0x56: // PUSH SI
		Push(SI);
		++EIP;
		return;
	case 0x57: // PUSH DI
		Push(DI);
		++EIP;
		return;
	case 0x58: // POP AX
		AX = Pop();
		++EIP;
		return;
	case 0x59: // POP CX
		CX = Pop();
		++EIP;
		return;
	case 0x5A: // POP DX
		DX = Pop();
		++EIP;
		return;
	case 0x5B: // POP BX
		BX = Pop();
		++EIP;
		return;
	case 0x5C: // POP SP
		SP = Pop();
		++EIP;
		return;
	case 0x5D: // POP BP
		BP = Pop();
		++EIP;
		return;
	case 0x5E: // POP SI
		SI = Pop();
		++EIP;
		return;
	case 0x5F: // POP DI
		DI = Pop();
		++EIP;
		return;
	case 0x70: // JO            SHORT-LABEL
		EIP += OF ? FetchImmSByte : 2;
		return;
	case 0x71: // JNO           SHORT-LABEL
		EIP += OF ? 2 : FetchImmSByte;
		return;
	case 0x72: // JB/JNAE/JC    SHORT-LABEL
		EIP += CF ? FetchImmSByte : 2;
		return;
	case 0x73: // JNB/JAE/JNC   SHORT-LABEL
		EIP += CF ? 2 : FetchImmSByte;
		return;
	case 0x74: // JE/JZ         SHORT-LABEL
		EIP += ZF ? FetchImmSByte : 2;
		return;
	case 0x75: // JNE/JNZ       SHORT-LABEL
		EIP += ZF ? 2 : FetchImmSByte;
		return;
	case 0x76: // JBE/JNA       SHORT-LABEL
		EIP += (CF || ZF) ? FetchImmSByte : 2;
		return;
	case 0x77: // JNBE/JA       SHORT-LABEL
		EIP += CF == 0 && ZF == 0 ? FetchImmSByte : 2;
		return;
	case 0x78: // JS            SHORT-LABEL
		EIP += SF ? FetchImmSByte : 2;
		return;
	case 0x79: // JNS           SHORT-LABEL
		EIP += SF ? 2 : FetchImmSByte;
		return;
	case 0x7A: // JP/JPE        SHORT-LABEL
		EIP += PF ? FetchImmSByte : 2;
		return;
	case 0x7B: // JNP/JPO       SHORT-LABEL
		EIP += PF ? 2 : FetchImmSByte;
		return;
	case 0x7C: // JL/JNGE       SHORT-LABEL
		EIP += SF != OF ? FetchImmSByte : 2;
		return;
	case 0x7D: // JNL/JGE       SHORT-LABEL
		EIP += SF == OF ? FetchImmSByte : 2;
		return;
	case 0x7E: // JLE/JNG       SHORT-LABEL
		EIP += SF != OF || ZF ? FetchImmSByte : 2;
		return;
	case 0x7F: // JNLE/JG       SHORT-LABEL
		EIP += SF == OF && ZF == 0 ? FetchImmSByte : 2;
		return;
	case 0x80: { // GRP1 R/M8, IMM8
		const ubyte rm = FetchImmByte; // Get ModR/M byte
		const ubyte im = FetchImmByte(2); // 8-bit Immediate after modr/m
		switch (rm & RM_MOD) {
		case RM_MOD_00: // No displacement
			switch (rm & RM_REG) { // REG
			case RM_REG_000: // 000 - ADD
				switch (rm & RM_RM) {
				case RM_RM_000:
					AL = AL + im;
					break;
				case RM_RM_001:
					CL = CL + im;
					break;
				case RM_RM_010:
					DL = DL + im;
					break;
				case RM_RM_011:
					BL = BL + im;
					break;
				case RM_RM_100:
					AH = AH + im;
					break;
				case RM_RM_101:
					CH = CH + im;
					break;
				case RM_RM_110:
					DH = DH + im;
					break;
				case RM_RM_111:
					BH = BH + im;
					break;
				default:
				}
				break;
			case RM_REG_001: // 001 - OR

				break;
			case RM_REG_010: // 010 - ADC

				break;
			case RM_REG_011: // 011 - SBB

				break;
			case RM_REG_100: // 100 - AND

				break;
			case RM_REG_101: // 101 - SUB

				break;
			case RM_REG_110: // 110 - XOR

				break;
			case RM_REG_111: // 111 - CMP

				break;
			default:
			}
			break; // case 0
		case RM_MOD_01: // 8-bit displacement

			break; // case 01
		default:
		}
		EIP += 3;
		return;
	}
	case 0x81: { // GRP1 R/M16, IMM16

		EIP += 4;
		return;
	}
	case 0x82: // GRP2 R/M8, IMM8

		EIP += 3;
		return;
	case 0x83: // GRP2 R/M16, IMM16
		const ubyte rm = FetchImmByte; // Get ModR/M byte
		const ushort im = FetchImmWord(2);
		switch (rm & 0b111_000) { // ModRM REG
		case 0b000_000: // 000 - ADD

			break;
		case 0b010_000: // 010 - ADC

			break;
		case 0b011_000: // 011 - SBB

			break;
		case 0b101_000: // 101 - SUB

			break;
		case 0b111_000: // 111 - CMP

			break;
		default:
			
			break;
		}
		EIP += 4;
		return;
	case 0x84: // TEST R/M8, REG8

		return;
	case 0x85: // TEST R/M16, REG16

		return;
	case 0x86: // XCHG REG8, R/M8

		return;
	case 0x87: // XCHG REG16, R/M16

		return;
	case 0x88: { // MOV R/M8, REG8

		EIP += 2;
		return;
	}
	case 0x89: { // MOV R/M16, REG16
		const ubyte rm = FetchImmByte;
		switch (rm & 0b1100_0000) {
		case RM_MOD_00:
			switch (rm & 0b111_000) {
			case RM_REG_000: // AX
				InsertWord(AX, GetEA(rm));
				break;
			case RM_REG_001: // CX
				InsertWord(CX, GetEA(rm));
				break;
			case RM_REG_010: // DX
				InsertWord(DX, GetEA(rm));
				break;
			case RM_REG_011: // BX
				InsertWord(BX, GetEA(rm));
				break;
			case RM_REG_100: // SP
				InsertWord(SP, GetEA(rm));
				break;
			case RM_REG_101: // BP
				InsertWord(BP, GetEA(rm));
				break;
			case RM_REG_110: // SI
				InsertWord(SI, GetEA(rm));
				break;
			case RM_REG_111: // DI
				InsertWord(DI, GetEA(rm));
				break;
			default:
			}
			break; // MOD 00
		case RM_MOD_01:

			EIP += 1;
			break; // MOD 01
		case RM_MOD_10:

			EIP += 2;
			break; // MOD 10
		case RM_MOD_11:
			switch (rm & 0b111_000) {
			/*case 0: AX =  break;
			case 0b00_1000: CX =  break;
			case 0b01_0000: DX =  break;
			case 0b01_1000: BX =  break;
			case 0b10_0000: SP =  break;
			case 0b10_1000: BP =  break;
			case 0b11_0000: SI =  break;
			case 0b11_1000: DI =  break;*/
			/*case 0: AX = getRMRegWord(rm); break;
			case 0b00_1000: CX = getRMRegWord(rm); break;
			case 0b01_0000: DX = getRMRegWord(rm); break;
			case 0b01_1000: BX = getRMRegWord(rm); break;
			case 0b10_0000: SP = getRMRegWord(rm); break;
			case 0b10_1000: BP = getRMRegWord(rm); break;
			case 0b11_0000: SI = getRMRegWord(rm); break;
			case 0b11_1000: DI = getRMRegWord(rm); break;*/
			default:
			}
			break; // MOD 11
		default:
		}
		EIP += 2;
		return;
	}
	case 0x8A: { // MOV REG8, R/M8

		EIP += 2;
		return;
	}
	case 0x8B: { // MOV REG16, R/M16

		EIP += 2;
		return;
	}
	case 0x8C: { // MOV R/M16, SEGREG
		// MOD 1SR R/M (SR: 00=ES, 01=CS, 10=SS, 11=DS)
		const byte rm = FetchImmByte;
		const int ea = GetEA(rm);
		switch (rm & 24) { // 00 011 000
		case 0: // ES
			InsertWord(ES, ea);
			break;
		case 8: // CS
			InsertWord(CS, ea);
			break;
		case 16: // SS
			InsertWord(SS, ea);
			break;
		case 24: // DS
			InsertWord(DS, ea);
			break;
		default:
		}
		EIP += 2;
		return;
	}
	case 0x8D: // LEA REG16, MEM16

		return;
	case 0x8E: // MOV SEGREG, R/M16
		// MOD 0SR R/M
		// SR: 00=ES, 01=CS, 10=SS, 11=DS

		return;
	case 0x8F: { // POP R/M16
		const byte rm = FetchImmByte;
		const ushort add = FetchImmWord(1);
		if (rm & 0b00111000) { // MOD 000 R/M only
			//TODO: Raise illegal instruction
		} else { // REMINDER: REG = 000 and D is SET
			//TODO: POP R/RM16
			switch (rm & 0b11_000000) {
			case 0: // Memory

				break;
			case 0b01_000000: // Memory + D8

				EIP += 1;
				break;
			case 0b10_000000: // Memory + D16

				EIP += 2;
				break;
			case 0b11_000000: // Register
			
				break;
			default:
			}
		}
		EIP += 2;
		return;
	}
	case 0x90: // NOP (aka XCHG AX, AX)
		++EIP;
		return;
	case 0x91: { // XCHG AX, CX
		const ushort t = AX;
		AX = CX;
		CX = t;
		return;
	}
	case 0x92: { // XCHG AX, DX
		const ushort t = AX;
		AX = DX;
		DX = t;
		return;
	}
	case 0x93: { // XCHG AX, BX
		const ushort t = AX;
		AX = BX;
		BX = t;
		return;
	}
	case 0x94: { // XCHG AX, SP
		const ushort t = AX;
		AX = SP;
		SP = t;
		return;
	}
	case 0x95: { // XCHG AX, BP
		const ushort t = AX;
		AX = BP;
		BP = t;
		return;
	}
	case 0x96: { // XCHG AX, SI
		const ushort t = AX;
		AX = SI;
		SI = t;
		return;
	}
	case 0x97: { // XCHG AX, DI
		const ushort t = AX;
		AX = DI;
		DI = t;
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
		Push(CS);
		Push(IP);
		CS = FetchImmWord;
		IP = FetchImmWord(2);
		return;
	case 0x9B: // WAIT
	//TODO: WAIT
	/* Causes the processor to check for and handle pending, unmasked,
	   floating-point exceptions before proceeding.*/
		++EIP;
		return;
	case 0x9C: // PUSHF
		Push(FLAG);
		++EIP;
		return;
	case 0x9D: // POPF
		FLAG = Pop();
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
		AL = MEMORY[FetchImmByte];
		EIP += 2;
		return;
	case 0xA1: // MOV AX, MEM16
		AX = FetchWord(FetchImmWord);
		EIP += 3;
		return;
	case 0xA2: // MOV MEM8, AL
		MEMORY[FetchImmByte] = AL;
		return;
	case 0xA3: // MOV MEM16, AX
		InsertWord(AX, FetchImmWord);
		return;
	case 0xA4: // MOVS DEST-STR8, SRC-STR8

		return;
	case 0xA5: // MOVS DEST-STR16, SRC-STR16

		return;
	case 0xA6: { // CMPS DEST-STR8, SRC-STR8
		const int t =
			MEMORY[GetAddress(DS, SI)] - MEMORY[GetAddress(ES, DI)];
		//TODO: CMPS PF
		ZF = t == 0;
		AF = (t & 0x10) != 0;
		CF = SF = (t & 0x80) != 0;
		OF = (t < 0) || (t > 0xFF);
		if (DF) {
			DI = DI - 1;
			SI = SI - 1;
		} else {
			DI = DI + 1;
			SI = SI + 1;
		}
		return;
	}
	case 0xA7: { // CMPSW DEST-STR16, SRC-STR16
		const int t =
			FetchWord(GetAddress(DS, SI)) - FetchWord(GetAddress(ES, DI));
		//TODO: CMPSW PF
		ZF = t == 0;
		AF = (t & 0x10) != 0;
		CF = SF = (t & 0x80) != 0;
		OF = (t < 0) || (t > 0xFFFF);
		if (DF) {
			DI = DI - 2;
			SI = SI - 2;
		} else {
			DI = DI + 2;
			SI = SI + 2;
		}
		return;
	}
	case 0xA8: { // TEST AL, IMM8
		const int r = AL & FetchImmByte;
		//TODO: TEST ZF SF PF

		CF = OF = 0;
		EIP += 2;
		return;
	}
	case 0xA9: { // TEST AX, IMM16
		const int r = AX & FetchImmWord;
		//TODO: TEST ZF SF PF

		CF = OF = 0;
		EIP += 3;
		return;
	}
	case 0xAA: // STOS DEST-STR8
		MEMORY[GetAddress(ES, DI)] = AL;
		if (DF == 0) DI = DI + 1;
		else         DI = DI - 1;
		++EIP;
		return;
	case 0xAB: // STOS DEST-STR16
		InsertWord(AX, GetAddress(ES, DI));
		if (DF == 0) DI = DI + 2;
		else         DI = DI - 2;
		++EIP;
		return;
	case 0xAC: // LODS SRC-STR8
		AL = MEMORY[GetAddress(DS, SI)];
		if (DF == 0) SI = SI + 1;
		else         SI = SI - 1;
		++EIP;
		return;
	case 0xAD: // LODS SRC-STR16
		AX = FetchWord(GetAddress(DS, SI));
		if (DF == 0) SI = SI + 2;
		else         SI = SI - 2;
		++EIP;
		return;
	case 0xAE: { // SCAS DEST-STR8
		const int r = AL - MEMORY[GetAddress(ES, DI)];
		//TODO: SCAS OF, PF
		ZF = r == 0;
		AF = (r & 0x10) != 0;
		CF = SF = (r & 0x80) != 0;
		if (DF == 0) DI = DI + 1;
		else         DI = DI - 1;
		++EIP;
		return;
	}
	case 0xAF: { // SCAS DEST-STR16
		const int r = AX - FetchWord(GetAddress(ES, DI));
		//TODO: SCAS OF, PF
		ZF = r == 0;
		AF = (r & 0x10) != 0;
		CF = SF = (r & 0x80) != 0;
		if (DF == 0) DI = DI + 2;
		else         DI = DI - 2;
		++EIP;
		return;
	}
	case 0xB0: // MOV AL, IMM8
		AL = FetchImmByte;
		EIP += 2;
		return;
	case 0xB1: // MOV CL, IMM8
		CL = FetchImmByte;
		EIP += 2;
		return;
	case 0xB2: // MOV DL, IMM8
		DL = FetchImmByte;
		EIP += 2;
		return;
	case 0xB3: // MOV BL, IMM8
		BL = FetchImmByte;
		EIP += 2;
		return;
	case 0xB4: // MOV AH, IMM8
		AH = FetchImmByte;
		EIP += 2;
		return;
	case 0xB5: // MOV CH, IMM8
		CH = FetchImmByte;
		EIP += 2;
		return;
	case 0xB6: // MOV DH, IMM8  
		DH = FetchImmByte;
		EIP += 2;
		return;
	case 0xB7: // MOV BH, IMM8
		BH = FetchImmByte;
		EIP += 2;
		return;
	case 0xB8: // MOV AX, IMM16
		AX = FetchImmWord;
		EIP += 3;
		return;
	case 0xB9: // MOV CX, IMM16
		CX = FetchImmWord;
		EIP += 3;
		return;
	case 0xBA: // MOV DX, IMM16
		DX = FetchImmWord;
		EIP += 3;
		return;
	case 0xBB: // MOV BX, IMM16
		BX = FetchImmWord;
		EIP += 3;
		return;
	case 0xBC: // MOV SP, IMM16
		SP = FetchImmWord;
		EIP += 3;
		return;
	case 0xBD: // MOV BP, IMM16
		BP = FetchImmWord;
		EIP += 3;
		return;
	case 0xBE: // MOV SI, IMM16
		SI = FetchImmWord;
		EIP += 3;
		return;
	case 0xBF: // MOV DI, IMM16
		DI = FetchImmWord;
		EIP += 3;
		return;
	case 0xC2: // RET IMM16 (NEAR)
		IP = Pop();
		SP = cast(ushort)(SP + FetchImmWord);
		//EIP += 3; ?
		return;
	case 0xC3: // RET (NEAR)
		IP = Pop();
		return;
	case 0xC4: // LES REG16, MEM16
// Load into REG and ES
		
		return;
	case 0xC5: // LDS REG16, MEM16
// Load into REG and DS

		return;
	case 0xC6: { // MOV MEM8, IMM8
		// MOD 000 R/M only
		const ubyte rm = FetchImmByte;
		const ubyte imm = FetchImmByte(1);
		if (rm & 38) { // 111 000
			//TODO: Raise GP
		} else {

		}
		return;
	}
	case 0xC7: { // MOV MEM16, IMM16
		// MOD 000 R/M only
		const ubyte rm = FetchImmByte;
		const ushort imm = FetchImmWord(1);
		if (rm & 38) { // 111 000
			//TODO: Raise GP
		} else {

		}
		return;
	}
	case 0xCA: // RET IMM16 (FAR)
		IP = Pop();
		CS = Pop();
		SP = SP + FetchImmWord;
		return;
	case 0xCB: // RET (FAR)
		IP = Pop();
		CS = Pop();
		return;
	case 0xCC: // INT 3
		Raise(3);
		++EIP; //TODO: Check: is this correct?
		return;
	case 0xCD: // INT IMM8
		Raise(FetchImmByte);
		EIP += 2; //TODO: Check: is this correct?
		return;
	case 0xCE: // INTO
		if (CF) Raise(4);
		++EIP; //TODO: Check: is this correct?
		return;
	case 0xCF: // IRET
		IP = Pop();
		CS = Pop();
		FLAG = Pop();
		++EIP;
		return;
	case 0xD0: // GRP2 R/M8, 1
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
	// D6 is illegal under 8086
	case 0xD7: // XLAT SOURCE-TABLE
		AL = MEMORY[GetAddress(DS, BX) + AL];
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
		if (CX && ZF == 0) EIP += FetchImmSByte;
		else               EIP += 2;
		return;
	case 0xE1: // LOOPE/LOOPZ   SHORT-LABEL
		CX = CX - 1;
		if (CX && ZF) EIP += FetchImmSByte;
		else          EIP += 2;
		return;
	case 0xE2: // LOOP  SHORT-LABEL
		CX = CX - 1;
		if (CX) EIP += FetchImmSByte;
		else    EIP += 2;
		return;
	case 0xE3: // JCXZ  SHORT-LABEL
		if (CX == 0) EIP += FetchImmSByte;
		else         EIP += 2;
		return;
	/*case 0xE4: // IN AL, IMM8

		return;
	case 0xE5: // IN AX, IMM8

		return;
	case 0xE6: // OUT AL, IMM8

		return;
	case 0xE7: // OUT AX, IMM8

		return;*/
	case 0xE8: // CALL NEAR-PROC
		Push(IP);
		EIP += FetchImmSWord; // Direct within segment
		return;
	case 0xE9: // JMP    NEAR-LABEL
		EIP += FetchImmSWord; // ±32 KB
		return;
	case 0xEA: // JMP  FAR-LABEL
		// Any segment, any fragment, 5 byte instruction.
		// EAh (LO-IP) (HI-IP) (LO-CS) (HI-CS)
		IP = FetchImmWord;
		CS = FetchImmWord(2);
		return;
	case 0xEB: // JMP  SHORT-LABEL
		EIP += FetchImmSByte; // ±128 B
		return;
	/*case 0xEC: // IN AL, DX

		return;
	case 0xED: // IN AX, DX

		return;
	case 0xEE: // OUT AL, DX

		return;
	case 0xEF: // OUT AX, DX

		return;
	case 0xF0: // LOCK (prefix)
// http://qcd.phys.cmu.edu/QCDcluster/intel/vtune/reference/vc160.htm

		return;*/
	case 0xF2: // REPNE/REPNZ
_F2_CX:
		if (CX) {
			//TODO: Finish REPNE/REPNZ properly?
			Execute(0xA6);
			CX = CX - 1;
			if (ZF == 0) goto _F2_CX;
		} else ++EIP;
		return;
	case 0xF3: // REP/REPE/REPNZ

		return;
	case 0xF4: // HLT
	//TODO: HLT
		++EIP;
		return;
	case 0xF5: // CMC
		CF = !CF;
		++EIP;
		return;
	case 0xF6: // GRP3a R/M8, IMM8
		/*byte rm; // Get ModR/M byte
		switch (rm & 0b00111000) {
		case 0b00000000: // 000 - TEST

		break;
		case 0b00010000: // 010 - NOT

		break;
		case 0b00011000: // 011 - NEG

		break;
		case 0b00100000: // 100 - MUL

		break;
		case 0b00101000: // 101 - IMUL

		break;
		case 0b00110000: // 110 - DIV

		break;
		case 0b00111000: // 111 - IDIV

		break;
		default:

		break;
		}*/
		return;
	case 0xF7: // GRP3b R/M16, IMM16
		/*byte rm; // Get ModR/M byte
		switch (rm & 0b00111000) {
		case 0b00000000: // 000 - TEST

		break;
		case 0b00010000: // 010 - NOT

		break;
		case 0b00011000: // 011 - NEG

		break;
		case 0b00100000: // 100 - MUL

		break;
		case 0b00101000: // 101 - IMUL

		break;
		case 0b00110000: // 110 - DIV

		break;
		case 0b00111000: // 111 - IDIV

		break;
		default:

		break;
		}*/
		return;
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
	case 0xFE: // GRP4 R/M8
		/*byte rm; // Get ModR/M byte
		switch (rm & 0b00111000) {
		case 0b00000000: // 000 - INC

			break;
		case 0b00001000: // 001 - DEC

			break;
		default:

			break;
		}*/
		return;
	case 0xFF: // GRP5 R/M16
		/*byte rm; // Get ModR/M byte
		switch (rm & 0b00111000) {
		case 0b00000000: // 000 - INC

		break;
		case 0b00001000: // 001 - DEC

		break;
		case 0b00010000: // 010 - CALL R/M16 (intra)

		break;
		case 0b00011000: // 011 - CALL MEM16 (inter)

		break;
		case 0b00100000: // 100 - JMP R/M16 (intra)

		break;
		case 0b00101000: // 101 - JMP MEM16 (inter)

		break;
		case 0b00110000: // 110 - PUSH MEM16

		break;
		default:

		break;
		}*/
		break;
	default: // Illegal instruction
		//TODO: Raise vector on illegal op
		
		panic("INVALID OPERATION CODE");

		exit(0); // Temporary
		return;
	}
}