/**
 * utils.d: Generic utilities
 */

module utils;

import vcpu : MEMORY;
import core.stdc.string : strlen;
import core.stdc.string : strncpy, strlen;

/**
 * CLI argument splitter, supports argument quoting.
 * This function inserts null-terminators.
 * Uses memory base 1400h for arguments and increments per argument lengths.
 * Params:
 *   t = User input
 *   argv = argument vector buffer
 * Returns: argument count
 * Notes: Original function by Nuke928. Modified by dd86k.
 */
extern (C)
int sargs(const char *t, char **argv) {
	int j, a;
	char* mloc = cast(char*)MEMORY + 0x1400;

	const size_t sl = strlen(t);

	for (int i = 0; i <= sl; ++i) {
		if (t[i] == 0 || t[i] == ' ' || t[i] == '\n') {
			argv[a] = mloc;
			mloc += i - j + 1;
			strncpy(argv[a], t + j, i - j);
			argv[a][i - j] = 0;
			while (t[i + 1] == ' ') ++i;
			j = i + 1;
			++a;
		} else if (t[i] == '\"') {
			j = ++i;
			while (t[i] != '\"' && t[i] != 0) ++i;
			if (t[i] == 0) continue;
			argv[a] = mloc;
			mloc += i - j + 1;
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
	return cast(ushort)(n >> 8 | n << 8);
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

static assert(char.sizeof == 1);