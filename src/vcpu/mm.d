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
 * While functions require an asbolute memory location, immediate functions (_i)
 * may accept an optional memory offset from EIP + 1.
 *
 * Functions taking account of the virtual memory feature, these functions have
 * the `mmv` prefix (e.g. `mmvfu32`).
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

//TODO: Get rid of vmerr, call INT directly (#GP?)

//
// INSERT
//

/**
 * Insert a BYTE in MEMORY
 * Params:
 *   addr = Memory address
 *   val = BYTE value
 */
void mmiu8(int addr, int val) {
	if (addr >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return;
	}
	MEM[addr] = cast(ubyte)val;
	vmerr = E_MM_OK;
}

/**
 * Insert a WORD in MEMORY
 * Params:
 *   val = WORD value
 *   addr = Memory address
 */
void mmiu16(int addr, int val) {
	if (addr + 1 >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return;
	}
	*cast(ushort*)(MEM + addr) = cast(ushort)val;
	vmerr = E_MM_OK;
}

/**
 * Insert a DWORD in MEMORY
 * Params:
 *   op = DWORD value
 *   addr = Memory address
 */
void mmiu32(int op, int addr) {
	if (addr + 3 >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return;
	}
	*cast(uint*)(MEM + addr) = op;
	vmerr = E_MM_OK;
}

/**
 * Insert array in MEMORY
 * Params:
 *   ops = Data
 *   size = Data size
 *   addr = Memory location
 */
void mmiarr(void *ops, size_t size, size_t addr) {
	if (addr + size >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return;
	}
	memcpy(MEM + addr, ops, size);
	vmerr = E_MM_OK;
}

/**
 * Insert an ASCIZ string in MEMORY
 * Params:
 *   data = String value
 *   addr = Memory address, default: EIP
 */
void mmistr(const(char) *data, size_t addr = CPU.EIP) {
	//TODO: Check string size
	if (addr >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return;
	}
	strcpy(cast(char*)(MEM + addr), data);
	vmerr = E_MM_OK;
}

/**
 * Insert a null-terminated wide string in MEMORY
 * Params:
 *   data = Wide wtring data
 *   addr = Memory Address (EIP by default)
 */
void mmiwstr(immutable(wchar)[] data, size_t addr = CPU.EIP) {
	//TODO: Check string size
	if (addr >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return;
	}
	//TODO: Replace wcscpy
/*	ushort *m = cast(ushort*)(MEM + addr);
	const(ushort) *d = cast(const(ushort)*)data.ptr;
	do {
		*m = *d;
		++d;
	} while (*d);*/
	wcscpy(cast(wchar_t*)(MEM + addr), cast(wchar_t*)data);
	vmerr = E_MM_OK;
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
	if (addr >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return 0;
	}
	vmerr = E_MM_OK;
	return MEM[addr];
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
	if (addr + 1 >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return 0;
	}
	vmerr = E_MM_OK;
	return *cast(ushort*)(MEM + addr);
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
	if (addr + 3 >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return 0;
	}
	vmerr = E_MM_OK;
	return *cast(uint*)(MEM + addr);
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
	if (addr >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return null;
	}
	size_t strl;
	char *p = cast(char*)(MEM + addr);
	while (p[strl] && strl < STR_LIMIT) {
		++strl;
	}
	if (addr + strl >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return null;
	}
	if (length) *length = cast(int)strl;
	vmerr = E_MM_OK;
	return p;
}

//
// FETCH IMMEDIATE
//

/**
 * Fetch an immediate BYTE at CPU.EIP. Modifies EIP
 * Returns: BYTE
 */
ubyte mmfu8_i() {
	size_t addr = CPU.EIP;
	if (addr >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return 0;
	}
	vmerr = E_MM_OK;
	++CPU.EIP;
	return MEM[addr];
}

/**
 * Fetch a signed byte (byte).
 * Returns: Signed BYTE
 */
pragma(inline, true)
byte mmfi8_i() {
	return cast(byte)mmfu8_i;
}

/**
 * Fetch an immediate WORD at EIP+1+n
 * Returns: WORD
 */
ushort mmfu16_i() {
	size_t addr = CPU.EIP;
	if (addr + 1 >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return 0;
	}
	CPU.EIP += 2;
	vmerr = E_MM_OK;
	return *cast(ushort*)(MEM + addr);
}

/**
 * Fetch an immediate signed WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: signed WORD
 */
pragma(inline, true)
short mmfi16_i() {
	return cast(short)mmfu16_i;
}

/**
 * Fetch an immediate signed WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: signed WORD
 */
uint mmfu32_i() {
	size_t addr = CPU.EIP;
	if (addr + 3 >= MEMSIZE) {
		vmerr = E_MM_OVRFLW;
		return 0;
	}
	vmerr = E_MM_OK;
	CPU.EIP += 4;
	return *cast(uint*)(MEM + addr);
}

/**
 * Fetch an immediate signed WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: signed WORD
 */
pragma(inline, true)
int mmfi32_i() {
	return cast(int)mmfu32_i;
}
