/**
 * mm: Processor memory manager
 * ---
 * The following function names are encoded using this example.
 * mmfu16_i
 * |||||| +- Immediate (fetch only, optional)
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
import err;
import logger;

extern (C):

//
// INSERT
//

/**
 * Insert a BYTE in MEMORY
 * Params:
 *   op = BYTE value
 *   addr = Memory address
 */
void mmiu8(int op, int addr) {
	if (addr >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return;
	}
	MEMORY[addr] = cast(ubyte)op;
	errno = E_MM_OK;
}

/**
 * Insert a WORD in MEMORY
 * Params:
 *   data = WORD value (will be casted)
 *   addr = Memory address
 */
void mmiu16(int data, int addr) {
	if (addr + 1 >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return;
	}
	*cast(ushort*)(MEMORY + addr) = cast(ushort)data;
	errno = E_MM_OK;
}

/**
 * Insert a DWORD in MEMORY
 * Params:
 *   op = DWORD value
 *   addr = Memory address
 */
void mmiu32(int op, int addr) {
	if (addr + 3 >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return;
	}
	*cast(uint*)(MEMORY + addr) = op;
	errno = E_MM_OK;
}

/**
 * Insert array in MEMORY
 * Params:
 *   ops = Data
 *   size = Data size
 *   addr = Memory location
 */
void mmiarr(void *ops, size_t size, size_t addr) {
	if (addr + size >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return;
	}
	memcpy(MEMORY + addr, ops, size);
	errno = E_MM_OK;
}

/**
 * Insert an ASCIZ string in MEMORY
 * Params:
 *   data = String value
 *   addr = Memory address, default: EIP
 */
void mmistr(const(char) *data, size_t addr = CPU.EIP) {
	//TODO: Check string size
	if (addr >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return;
	}
	strcpy(cast(char*)(MEMORY + addr), data);
	errno = E_MM_OK;
}

/**
 * Insert a null-terminated wide string in MEMORY
 * Params:
 *   data = Wide wtring data
 *   addr = Memory Address (EIP by default)
 */
void mmiwstr(immutable(wchar)[] data, size_t addr = CPU.EIP) {
	//TODO: Check string size
	if (addr >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return;
	}
	wcscpy(cast(wchar_t*)(MEMORY + addr), cast(wchar_t*)data);
	errno = E_MM_OK;
}

//
// FETCH
//

/**
 * Fetch an unsigned byte (ubyte).
 * Params: addr = Memory address
 * Returns: BYTE
 */
ubyte mmfu8(uint addr) {
	if (addr >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return 0;
	}
	errno = E_MM_OK;
	return MEMORY[addr];
}

/**
 * Fetch an unsigned byte (ubyte).
 * Params: addr = Memory address
 * Returns: BYTE
 */
byte mmfi8(uint addr) {
	return cast(byte)mmfu8(addr);
}

/**
 * Fetch a WORD from MEMORY
 * Params: addr = Memory address
 * Returns: WORD
 */
ushort mmfu16(uint addr) {
	if (addr + 1 >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return 0;
	}
	errno = E_MM_OK;
	return *cast(ushort*)(MEMORY + addr);
}

/**
 * Fetch a signed WORD from memory
 * Params: addr = Memory address
 * Returns: signed WORD
 */
pragma(inline, true)
short mmfi16(uint addr) {
	return cast(short)mmfu16(addr);
}

/**
 * Fetch a DWORD from MEMORY
 * Params: addr = Memory address
 * Returns: DWORD
 */
uint mmfu32(uint addr) {
	if (addr + 3 >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return 0;
	}
	errno = E_MM_OK;
	return *cast(uint*)(MEMORY + addr);
}

/**
 * Fetch a string pointer from MEMORY. This function calculates the length of
 * the memory string and limits its operation to 4096 characters or until it
 * hits a null byte (zero). If a length (int*) pointer is provided, it will
 * be updated.
 * Params:
 *   addr = Memory position in bytes
 *   length = Length pointer
 * Returns: String pointer. Never null
 */
const(char) *mmfstr(uint addr, int *length = null) {
	enum size_t STR_LIMIT = 65535;
	if (addr >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return null;
	}
	size_t strl;
	char *p = cast(char*)(MEMORY + addr);
	while (p[strl] && strl < STR_LIMIT) {
		++strl;
	}
	if (addr + strl >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return null;
	}
	if (length) *length = cast(int)strl;
	errno = E_MM_OK;
	return p;
}

//
// FETCH IMMEDIATE
//

/**
 * Fetch an immediate BYTE at CPU.EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: BYTE
 */
ubyte mmfu8_i(int n = 0) {
	size_t addr = CPU.EIP + 1 + n;
	if (addr >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return 0;
	}
	errno = E_MM_OK;
	return MEMORY[addr];
}

/**
 * Fetch a signed byte (byte).
 * Params: n = Optional offset from EIP+1
 * Returns: Signed BYTE
 */
//pragma(inline, true)
byte mmfi8_i(int n = 0) {
	return cast(byte)mmfu8_i(n);
}

/**
 * Fetch an immediate WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: WORD
 */
ushort mmfu16_i(int n = 0) {
	size_t addr = CPU.EIP + 1 + n;
	if (addr + 1>= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return 0;
	}
	errno = E_MM_OK;
	return *cast(ushort*)(MEMORY + addr);
}

/**
 * Fetch an immediate signed WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: signed WORD
 */
pragma(inline, true)
short mmfi16_i(int n = 0) {
	return cast(short)mmfu16_i(n);
}

/**
 * Fetch an immediate signed WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: signed WORD
 */
uint mmfu32_i(int n = 0) {
	size_t addr = CPU.EIP + 1 + n;
	if (addr + 3 >= MEMORYSIZE) {
		errno = E_MM_OVRFLW;
		return 0;
	}
	errno = E_MM_OK;
	return *cast(uint*)(MEMORY + addr);
}

/**
 * Fetch an immediate signed WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: signed WORD
 */
pragma(inline, true)
int mmfi32_i(int n = 0) {
	return cast(int)mmfu32_i(n);
}

//
// ModR/M / SIB bytes
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
	uint r = void;
	//TODO: Reset Seg to SEG_NONE
	//TODO: Use general purpose variable to hold segreg value
	switch (rm & RM_MOD) { // MOD
	case RM_MOD_00: // MOD 00, Memory Mode, no displacement
		switch (rm & RM_RM) { // R/M
		case RM_RM_000: r = CPU.SI + CPU.BX; break;
		case RM_RM_001: r = CPU.DI + CPU.BX; break;
		case RM_RM_010: r = CPU.SI + CPU.BP; break;
		case RM_RM_011: r = CPU.DI + CPU.BP; break;
		case RM_RM_100: r = CPU.SI; break;
		case RM_RM_101: r = CPU.DI; break;
		case RM_RM_110: r = mmfu16_i(1); break;
		case RM_RM_111: r = CPU.BX; break;
		default:
		}
		break; // MOD 00
	case RM_MOD_01: { // MOD 01, Memory Mode, 8-bit displacement follows
		switch (rm & RM_RM) {
		case RM_RM_000: r = CPU.SI + CPU.BX + mmfi8_i(1); break;
		case RM_RM_001: r = CPU.DI + CPU.BX + mmfi8_i(1); break;
		case RM_RM_010: r = CPU.SI + CPU.BP + mmfi8_i(1); break;
		case RM_RM_011: r = CPU.DI + CPU.BP + mmfi8_i(1); break;
		case RM_RM_100: r = CPU.SI + mmfi8_i(1); break;
		case RM_RM_101: r = CPU.DI + mmfi8_i(1); break;
		case RM_RM_110: r = CPU.BP + mmfi8_i(1); break;
		case RM_RM_111: r = CPU.BX + mmfi8_i(1); break;
		default:
		}
		++CPU.EIP;
		break; // MOD 01
	}
	case RM_MOD_10: // MOD 10, Memory Mode, 16-bit displacement follows
		switch (rm & RM_RM) { // R/M
		case RM_RM_000: r = CPU.SI + CPU.BX + mmfi16_i(1); break;
		case RM_RM_001: r = CPU.DI + CPU.BX + mmfi16_i(1); break;
		case RM_RM_010: r = CPU.SI + CPU.BP + mmfi16_i(1); break;
		case RM_RM_011: r = CPU.DI + CPU.BP + mmfi16_i(1); break;
		case RM_RM_100: r = CPU.SI + mmfi16_i(1); break;
		case RM_RM_101: r = CPU.DI + mmfi16_i(1); break;
		case RM_RM_110: r = CPU.BP + mmfi16_i(1); break;
		case RM_RM_111: r = CPU.BX + mmfi16_i(1); break;
		default:
		}
		CPU.EIP += 2;
		break; // MOD 10
	case RM_MOD_11: // MOD 11, Register Mode
		if (wide)
			switch (rm & RM_RM) {
			case RM_RM_000: r = CPU.AX; break;
			case RM_RM_001: r = CPU.CX; break;
			case RM_RM_010: r = CPU.DX; break;
			case RM_RM_011: r = CPU.BX; break;
			case RM_RM_100: r = CPU.SP; break;
			case RM_RM_101: r = CPU.BP; break;
			case RM_RM_110: r = CPU.SI; break;
			case RM_RM_111: r = CPU.DI; break;
			default:
			}
		else
			switch (rm & RM_RM) {
			case RM_RM_000: r = CPU.AL; break;
			case RM_RM_001: r = CPU.CL; break;
			case RM_RM_010: r = CPU.DL; break;
			case RM_RM_011: r = CPU.BL; break;
			case RM_RM_100: r = CPU.AH; break;
			case RM_RM_101: r = CPU.CH; break;
			case RM_RM_110: r = CPU.DH; break;
			case RM_RM_111: r = CPU.BH; break;
			default:
			}
		break; // MOD 11
	default:
	}

	errno = E_MM_OK;
	return r;
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
		case RM_RM_000: r = CPU.EAX; break;
		case RM_RM_001: r = CPU.ECX; break;
		case RM_RM_010: r = CPU.EDX; break;
		case RM_RM_011: r = CPU.EBX; break;
		case RM_RM_100: r = CPU.ESP; break;
		case RM_RM_101: r = CPU.EBP; break;
		case RM_RM_110: r = CPU.ESI; break;
		case RM_RM_111: r = CPU.EDI; break;
		default:
		} else switch (m) {
		//TODO: Check CPU.OPSIZE AX/CX/etc.
		case RM_RM_000: r = CPU.AL; break;
		case RM_RM_001: r = CPU.CL; break;
		case RM_RM_010: r = CPU.DL; break;
		case RM_RM_011: r = CPU.BL; break;
		case RM_RM_100: r = CPU.AH; break;
		case RM_RM_101: r = CPU.CH; break;
		case RM_RM_110: r = CPU.DH; break;
		case RM_RM_111: r = CPU.BH; break;
		default:
		}
		break; // MOD 11
	default:
	}

	errno = E_MM_OK;
	return r;
}