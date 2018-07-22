/*
 * vcpu.d: x86 machine code interpreter.
 */

module vcpu;

import sleep;
import Logger : info;
debug import Logger : logexec;
import vdos : Raise; // Interrupt handler
import vcpu_8086 : exec16;
import vcpu_utils;
import vcpu_config;

/*enum : ubyte { // Emulated CPU
	CPU_8086,
	CPU_80486
}*/

/*enum : ubyte { // CPU Mode
	CPU_MODE_REAL,
	CPU_MODE_PROTECTED,
	CPU_MODE_EXTENDED,
	// No LONG modes
}*/

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
 * Runnning level.
 * Used to determine the "level of execution", such as the
 * "deepness" of a program. When a program terminates, its ERRORLEVEL is decreased.
 * If RLEVEL reaches 0, the emulator either stops, or returns to the virtual shell.
 * tl;dr: Emulates CALLs
 */
__gshared short RLEVEL = 1;
__gshared ubyte opt_sleep = 1; /// If set, the vcpu sleeps between cycles

enum MEMORY_P = cast(ubyte*)MEMORY; /// Memory pointer enum to avoid explicit casting
__gshared ubyte[INIT_MEM] MEMORY; /// Main memory bank
__gshared uint MEMORYSIZE = INIT_MEM; /// Current memory MEMORY size

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
		exec16(MEMORY[EIP]);

		if (opt_sleep) {
			++tsc;
			if (tsc == TSC_SLEEP) {
				SLEEP;
				tsc = 0;
			}
		}
	}
}

/**
 * Get memory address out of a segment and a register value.
 * Params:
 *   s = Segment register value
 *   o = Generic register value
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