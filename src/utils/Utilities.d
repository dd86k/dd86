/**
 * utils.d: Generic utilities
 */

module utils;

import vcpu : MEMORY, MEMORYSIZE;
import core.stdc.string : strlen;

/**
 * Fetches a string from MEMORY.
 * Params:
 *   pos = Starting position
 * Returns: String
 */
extern (C)
char[] MemString(uint pos) {
//TODO: Check overflows
    return cast(char[])
		MEMORY[pos..pos + strlen(cast(char*)MEMORY + pos)];
}

/// Maximum string length
//private enum STRING_MAX = 0x100; // Seems like a decent maximum length
/// Global string buffer, mostly used with mstring.
/// Avoids pre-allocating other strings.
//__gshared char[STRING_MAX] __GBUF;

/**
 * Fetch a string from MEMORY into an input buffer. If the function reaches
 * STRING_MAX, the function returns -2.
 * Params:
 *   c = Input buffer
 *   p = Memory position
 * Returns:
 *   On sucess, the function returns the number of characters read
 *   On failure, the function returns a negative value
 *     -1 = Memory Overflow
 *     -2 = STRING_MAX Overflow
 */
/*extern (C)
int mstring(char* c, int p) {
	if (p < 0 || p > MEMORYSIZE) return -1;
	int r; /// Result
	char* m = cast(char*)MEMORY + p;
	while (*m != 0) {
		if (p >= MEMORYSIZE) return -1;
		if (r > STRING_MAX) return -2;
		*c = *m;
		++c; ++m;
		++p; ++c; ++r;
	}
	return r;
}*/

extern (C)
void lowercase(char* c) {
	while (*c) {
		switch (*c) {
		case 'A': .. case 'Z':
			*c = cast(char)(*c + 32);
			break;
		default:
		}
		++c;
	}
}

/**
 * Byte swap a 2-byte number.
 * Params: num = 2-byte number to swap.
 * Returns: Byte swapped number.
 */
pragma(inline, true)
extern (C)
ushort bswap16(ushort n) {
	return (n >> 8) | (n & 0xFF) << 8;
}

/**
 * Byte swap a 4-byte number.
 * Params: num = 4-byte number to swap.
 * Returns: Byte swapped number.
 */
pragma(inline, true)
extern (C)
uint bswap32(uint n) {
	return  (n >> 24) | (n & 0xFF_0000) >> 8 |
			(n & 0xFF00) << 8 | (n << 24);
}

/**
 * Byte swap a 8-byte number.
 * Params: num = 8-byte number to swap.
 * Returns: Byte swapped number.
 */
pragma(inline, true)
extern (C)
ulong bswap64(ulong n) {
	ubyte* p = cast(ubyte*)&n;
	version (DigitarMars) { // Compiler optimized
		ubyte c = *p;
		*p = *(p + 7);
		*(p + 7) = c;
		c = *(p + 1);
		*(p + 1) = *(p + 6);
		*(p + 6) = c;
		c = *(p + 2);
		*(p + 2) = *(p + 5);
		*(p + 5) = c;
		c = *(p + 3);
		*(p + 3) = *(p + 4);
		*(p + 4) = c;
	} else { // LDC
		uint i = *cast(uint*)&n;
		ubyte* ip = cast(ubyte*)&i;
		*(p + 0) = *(p + 7);
		*(p + 1) = *(p + 6);
		*(p + 2) = *(p + 5);
		*(p + 3) = *(p + 4);
		*(p + 4) = *(ip + 3);
		*(p + 5) = *(ip + 2);
		*(p + 6) = *(ip + 1);
		*(p + 7) = *(ip + 0);
	}
	return n;
}