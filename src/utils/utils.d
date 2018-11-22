/**
 * utils.d: Generic utilities
 */

module utils;

import vcpu : MEMORY;
import core.stdc.string : strlen;
import core.stdc.stdlib : malloc;
import core.stdc.string : strncpy, strlen;

/**
 * CLI argument splitter, supports quoting.
 * This function use multiple malloc calls, which must be freed by the caller.
 * Params:
 *   t = User input
 *   argv = argument vector buffer
 * Returns: argument vector string array
 * Notes: Original function by Nuke928. Modified by dd86k.
 */
extern (C)
int sargs(const char *t, char **argv) {
	//TODO: Use memory locations from MEMORY instead of malloc
	int j, a;
	//char* mloc = cast(char*)MEMORY;

	const size_t sl = strlen(t);

	for (int i = 0; i <= sl; ++i) {
		if (t[i] == 0 || t[i] == ' ' || t[i] == '\n') {
			argv[a] = cast(char*)malloc(i - j + 1);
			//mloc +=
			//argv[a] = cast(char*)(MEMORY + 0x1200);
			strncpy(argv[a], t + j, i - j);
			argv[a][i - j] = 0;
			while (t[i + 1] == ' ') ++i;
			j = i + 1;
			++a;
		} else if (t[i] == '\"') {
			j = ++i;
			while (t[i] != '\"' && t[i] != 0) ++i;
			if (t[i] == 0) continue;
			argv[a] = cast(char*)malloc(i - j + 1);
			//argv[a] = cast(char*)(MEMORY + 0x1200);
			strncpy(argv[a], t + j, i - j);
			argv[a][i - j] = 0;
			while(t[i + 1] == ' ') ++i;
			j = ++i;
			++a;
		}
	}

	return --a;
}

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

extern (C)
void lowercase(char *c) {
	while (*c) {
		if (*c >= 'A' && *c <= 'Z')
			*c = cast(char)(*c + 32);
		++c;
	}
}

/**
 * Byte swap a 2-byte number.
 * Params: n = 2-byte number to swap.
 * Returns: Byte swapped number.
 */
pragma(inline, true)
extern (C)
ushort bswap16(ushort n) {
	return (n >> 8) | (n & 0xFF) << 8;
}

/**
 * Byte swap a 4-byte number.
 * Params: n = 4-byte number to swap.
 * Returns: Byte swapped number.
 */
pragma(inline, true)
extern (C)
uint bswap32(uint n) {
	return
		(n >> 24) | (n & 0xFF_0000) >> 8 |
		(n & 0xFF00) << 8 | (n << 24);
}

// Disable bswap64 as long as we don't need it
version (0)
/**
 * Byte swap a 8-byte number.
 * Params: num = 8-byte number to swap.
 * Returns: Byte swapped number.
 */
pragma(inline, true)
extern (C)
ulong bswap64(ulong n) {
	// NOTE: D compilers (at least DMD) does not allow bit-shifting past
	// 32 bits
	uint* p = cast(uint*)n;
	const uint a = bswap32(p[0]);
	p[0] = bswap32(p[1]);
	p[1] = a;
	/*ubyte* p = cast(ubyte*)&n;
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
	} else { // LDC/GDC
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
	}*/
	return n;
}