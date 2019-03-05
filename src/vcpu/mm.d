/**
 * mm: Processor memory manager
 * ---
 * The following function names are encoded using this example.
 * mmfu16_i
 * ||||||++- Immediate (fetch only, optional)
 * |||+++--- Type (unsigned 16-bit)
 * ||+------ Fetch (f), can also be Insert (i)
 * ++------- Memory Manager
 * ---
 * While functions require an asbolute memory location, immediate functions
 * may accept an optional memory offset from EIP + 1.
 *
 * Functions to handle ModR/M and SIB bytes: `mmrm16`, `mmrm32`, `mmsib32`
 */
module vcpu.mm;

import core.stdc.string : memcpy, strcpy, strlen;
import core.stdc.wchar_ : wchar_t, wcscpy;
import vcpu.core;
import vdos.codes : PANIC_MEMORY_ACCESS;
import logger;

extern (C):
nothrow:


//
// Insert into memory functions
//

/**
 * Insert a BYTE in MEMORY
 * Params:
 *   op = BYTE value
 *   addr = Memory address
 */
void mmiu8(int op, int addr) {
	if (C_OVERFLOW(addr)) log_crit("ACCESS VIOLATION IN mmiu8", PANIC_MEMORY_ACCESS);
	MEMORY[addr] = cast(ubyte)op;
}

/**
 * Insert a WORD in MEMORY
 * Params:
 *   data = WORD value (will be casted)
 *   addr = Memory address
 */
void mmiu16(int data, int addr) {
	if (C_OVERFLOW(addr)) log_crit("ACCESS VIOLATION IN mmiu16", PANIC_MEMORY_ACCESS);
	*cast(ushort*)(MEMORY + addr) = cast(ushort)data;
}

/**
 * Insert a DWORD in MEMORY
 * Params:
 *   op = DWORD value
 *   addr = Memory address
 */
void mmiu32(int op, int addr) {
	if (C_OVERFLOW(addr)) log_crit("ACCESS VIOLATION IN mmiu32", PANIC_MEMORY_ACCESS);
	*cast(uint*)(MEMORY + addr) = op;
}

/**
 * Insert data in MEMORY
 * Params:
 *   ops = Data
 *   size = Data size
 *   addr = Memory location
 */
void mmiarr(void *ops, size_t size, size_t addr) {
	if (C_OVERFLOW(addr)) log_crit("ACCESS VIOLATION IN mmiarr", PANIC_MEMORY_ACCESS);
	memcpy(MEMORY + addr, ops, size);
}

/**
 * Insert an ASCIZ string in MEMORY
 * Params:
 *   data = String value
 *   addr = Memory address, default: EIP
 */
void mmistr(const(char) *data, size_t addr = CPU.EIP) {
	if (C_OVERFLOW(addr)) log_crit("ACCESS VIOLATION IN mmistr", PANIC_MEMORY_ACCESS);
	strcpy(cast(char*)(MEMORY + addr), data);
}

/**
 * Insert a null-terminated wide string in MEMORY
 * Params:
 *   data = Wide wtring data
 *   addr = Memory Address (EIP by default)
 */
void mmiwstr(immutable(wchar)[] data, size_t addr = CPU.EIP) {
	if (C_OVERFLOW(addr)) log_crit("ACCESS VIOLATION IN mmiwstr", PANIC_MEMORY_ACCESS);
	wcscpy(cast(wchar_t*)(MEMORY + addr), cast(wchar_t*)data);
}

//
// Fetch from memory function
//

/**
 * Fetch an unsigned byte (ubyte).
 * Params: addr = Memory address
 * Returns: BYTE
 */
ubyte mmfu8(uint addr) {
	if (C_OVERFLOW(addr)) log_crit("ACCESS VIOLATION IN mmfu8", PANIC_MEMORY_ACCESS);
	return MEMORY[addr];
}

/**
 * Fetch an unsigned byte (ubyte).
 * Params: addr = Memory address
 * Returns: BYTE
 */
byte mmfi8(uint addr) {
	if (C_OVERFLOW(addr)) log_crit("ACCESS VIOLATION IN mmfi8", PANIC_MEMORY_ACCESS);
	return cast(byte)MEMORY[addr];
}

/**
 * Fetch a WORD from MEMORY
 * Params: addr = Memory address
 * Returns: WORD
 */
ushort mmfu16(uint addr) {
	if (C_OVERFLOW(addr)) log_crit("ACCESS VIOLATION IN mmfu16", PANIC_MEMORY_ACCESS);
	return *cast(ushort*)(MEMORY + addr);
}

/**
 * Fetch a signed WORD from memory
 * Params: addr = Memory address
 * Returns: signed WORD
 */
short mmfi16(uint addr) {
	if (C_OVERFLOW(addr)) log_crit("ACCESS VIOLATION IN mmfi16", PANIC_MEMORY_ACCESS);
	return *cast(short*)(MEMORY + addr);
}

/**
 * Fetch a DWORD from MEMORY
 * Params: addr = Memory address
 * Returns: DWORD
 */
uint mmfu32(uint addr) {
	if (C_OVERFLOW(addr)) log_crit("ACCESS VIOLATION IN mmfu32", PANIC_MEMORY_ACCESS);
	return *cast(uint*)(MEMORY + addr);
}

/**
 * Fetches a string from MEMORY.
 * Params: pos = Starting position
 * Returns: String
 */
char[] MemString(uint pos) {
//TODO: Check overflows
	return cast(char[])
		MEMORY[pos..pos + strlen(cast(char*)MEMORY + pos)];
}

//
// Fetch immediates from memory functions
//

//TODO: Proper calculated bounds checking

/**
 * Fetch an immediate BYTE at CPU.EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: BYTE
 */
ubyte mmfu8_i(int n = 0) {
	return MEMORY[CPU.EIP + 1 + n];
}

/**
 * Fetch a signed byte (byte).
 * Params: n = Optional offset from EIP+1
 * Returns: Signed BYTE
 */
byte mmfi8_i(int n = 0) {
	return cast(byte)MEMORY[CPU.EIP + 1 + n];
}

/**
 * Fetch an immediate WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: WORD
 */
ushort mmfu16_i(int n = 0) {
	return *cast(ushort*)(MEMORY + CPU.EIP + 1 + n);
}

/**
 * Fetch an immediate signed WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: signed WORD
 */
short mmfi16_i(int n = 0) {
	return *cast(short*)(MEMORY + CPU.EIP + 1 + n);
}

/**
 * Fetch an immediate signed WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: signed WORD
 */
int mmfi32_i(int n = 0) {
	return *cast(int*)(MEMORY + CPU.EIP + 1 + n);
}

//
// Utilities utilities
//

/**
 * Check for overflow from MEMORY.
 * Params: addr = virtual memory address
 * Returns: True if overflowed
 */
pragma(inline, true)
private
bool C_OVERFLOW(size_t addr) {
	return addr < 0 || addr > MEMORYSIZE;
}

//
// ModR/M and SIB bytes
//

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
uint mmrm16(ubyte rm, ubyte wide = 0) {
	//uint r = void;
	//TODO: Reset Seg to SEG_NONE
	//TODO: Use general purpose variable to hold segreg value
	switch (rm & RM_MOD) { // MOD
	case RM_MOD_00: // MOD 00, Memory Mode, no displacement
		switch (rm & RM_RM) { // R/M
		case RM_RM_000: return CPU.SI + CPU.BX;
		case RM_RM_001: return CPU.DI + CPU.BX;
		case RM_RM_010: return CPU.SI + CPU.BP;
		case RM_RM_011: return CPU.DI + CPU.BP;
		case RM_RM_100: return CPU.SI;
		case RM_RM_101: return CPU.DI;
		case RM_RM_110: return mmfu16_i(1);
		case RM_RM_111: return CPU.BX;
		default:
		}
		break; // MOD 00
	case RM_MOD_01: { // MOD 01, Memory Mode, 8-bit displacement follows
		switch (rm & RM_RM) {
		case RM_RM_000: return CPU.SI + CPU.BX + mmfi8_i(1);
		case RM_RM_001: return CPU.DI + CPU.BX + mmfi8_i(1);
		case RM_RM_010: return CPU.SI + CPU.BP + mmfi8_i(1);
		case RM_RM_011: return CPU.DI + CPU.BP + mmfi8_i(1);
		case RM_RM_100: return CPU.SI + mmfi8_i(1);
		case RM_RM_101: return CPU.DI + mmfi8_i(1);
		case RM_RM_110: return CPU.BP + mmfi8_i(1);
		case RM_RM_111: return CPU.BX + mmfi8_i(1);
		default:
		}
		++CPU.EIP;
		break; // MOD 01
	}
	case RM_MOD_10: // MOD 10, Memory Mode, 16-bit displacement follows
		switch (rm & RM_RM) { // R/M
		case RM_RM_000: return CPU.SI + CPU.BX + mmfi16_i(1);
		case RM_RM_001: return CPU.DI + CPU.BX + mmfi16_i(1);
		case RM_RM_010: return CPU.SI + CPU.BP + mmfi16_i(1);
		case RM_RM_011: return CPU.DI + CPU.BP + mmfi16_i(1);
		case RM_RM_100: return CPU.SI + mmfi16_i(1);
		case RM_RM_101: return CPU.DI + mmfi16_i(1);
		case RM_RM_110: return CPU.BP + mmfi16_i(1);
		case RM_RM_111: return CPU.BX + mmfi16_i(1);
		default:
		}
		CPU.EIP += 2;
		break; // MOD 10
	case RM_MOD_11: // MOD 11, Register Mode
		if (wide)
			switch (rm & RM_RM) {
			case RM_RM_000: return CPU.AX;
			case RM_RM_001: return CPU.CX;
			case RM_RM_010: return CPU.DX;
			case RM_RM_011: return CPU.BX;
			case RM_RM_100: return CPU.SP;
			case RM_RM_101: return CPU.BP;
			case RM_RM_110: return CPU.SI;
			case RM_RM_111: return CPU.DI;
			default:
			}
		else
			switch (rm & RM_RM) {
			case RM_RM_000: return CPU.AL;
			case RM_RM_001: return CPU.CL;
			case RM_RM_010: return CPU.DL;
			case RM_RM_011: return CPU.BL;
			case RM_RM_100: return CPU.AH;
			case RM_RM_101: return CPU.CH;
			case RM_RM_110: return CPU.DH;
			case RM_RM_111: return CPU.BH;
			default:
			}
		break; // MOD 11
	default:
	}

	return 0;
}

/**
 * Calculates the effective address from the given ModR/M byte and is used
 * under 32-bit modes. This function updates EIP.
 * Params:
 *   rm = ModR/M byte
 *   wide = WIDE bit
 * Returns: Calculated address
 */
uint mmrm32(ubyte rm, ubyte wide = 0) {
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
		if (wide) switch (m) {
		case RM_RM_000: return CPU.EAX;
		case RM_RM_001: return CPU.ECX;
		case RM_RM_010: return CPU.EDX;
		case RM_RM_011: return CPU.EBX;
		case RM_RM_100: return CPU.ESP;
		case RM_RM_101: return CPU.EBP;
		case RM_RM_110: return CPU.ESI;
		case RM_RM_111: return CPU.EDI;
		default:
		} else switch (m) {
		//TODO: Check CPU.OPSIZE AX/CX/etc.
		case RM_RM_000: return CPU.AL;
		case RM_RM_001: return CPU.CL;
		case RM_RM_010: return CPU.DL;
		case RM_RM_011: return CPU.BL;
		case RM_RM_100: return CPU.AH;
		case RM_RM_101: return CPU.CH;
		case RM_RM_110: return CPU.DH;
		case RM_RM_111: return CPU.BH;
		default:
		}
		break; // MOD 11
	default:
	}

	return r;
}