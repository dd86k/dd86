/**
 * Utilities.d: Generic utilities
 */

module Utilities;

pragma(msg, "Compiling utils"); // temporary

import Interpreter : MEMORY;
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
		MEMORY[
			pos..pos + strlen(cast(char*)MEMORY + pos)
		];
}

/**
 * Compare constant string. This function is mostly to compare constant strings.
 * Note: 
 * Params:
 *   a = Input string
 *   b = Constant string
 *   c = String length
 * Returns: 0 if same, 1 if different.
 */
extern (C)
int _strcmp_c(char* a, immutable(char)* b, size_t c) {
	while (--c)
		if (*--a != *--b) return 1;
	return 0;
}

/**
 * Compare constant string. This function is mostly used in vshell
 * Note: 
 * Params:
 *   a = Input string
 *   b = Constant string
 *   c = String length
 * Returns: 0 if same, 1 if different.
 */
extern (C)
int _argcmp_s(char* a, immutable(char)* b) {
	while (*a != ' ' && *a != 0) {
		if (*a != *b) return 0;
		++a; ++b;
	}
	return 1;
}

/**
 * Byte swap a 2-byte number.
 * Params: num = 2-byte number to swap.
 * Returns: Byte swapped number.
 */
extern (C)
ushort bswap16(ushort num) {
	version (X86) asm { naked;
		xchg AH, AL;
		ret;
	} else version (X86_64) {
		version (Windows) asm { naked;
			mov AX, CX;
			xchg AL, AH;
			ret;
		} else asm { naked; // System V AMD64 ABI
			mov EAX, EDI;
			xchg AL, AH;
			ret;
		}
	} else {
		if (num) {
			ubyte* p = cast(ubyte*)&num;
			return p[1] | p[0] << 8;
		} else return num;
	}
}

/**
 * Byte swap a 4-byte number.
 * Params: num = 4-byte number to swap.
 * Returns: Byte swapped number.
 */
extern (C)
uint bswap32(uint num) {
	version (X86) asm { naked;
		bswap EAX;
		ret;
	} else version (X86_64) {
		version (Windows) asm { naked;
			mov EAX, ECX;
			bswap EAX;
			ret;
		} else asm { naked; // System V AMD64 ABI
			mov RAX, RDI;
			bswap EAX;
			ret;
		}
	} else {
		if (num) {
			ubyte* p = cast(ubyte*)&num;
			return p[3] | p[2] << 8 | p[1] << 16 | p[0] << 24;
		} else return 0;
	}
}

/**
 * Byte swap a 8-byte number.
 * Params: num = 8-byte number to swap.
 * Returns: Byte swapped number.
 */
extern (C)
ulong bswap64(ulong num) {
	version (X86) {
		version (Windows) {
			asm { // Temporary solution
			// Likely due to a PUSH/POP argument handling, broken in DMD 2.074.0?
			//TODO: Check for v2.079.0
				lea EDI, num;
				mov EAX, [EDI];
				mov EDX, [EDI+4];
				bswap EAX;
				bswap EDX;
				xchg EAX, EDX;
				mov [EDI], EAX;
				mov [EDI+4], EDX;
			}
			return num;
		} else asm { naked; // System V
			xchg EAX, EDX;
			bswap EDX;
			bswap EAX;
			ret;
		}
	} else version (X86_64) {
		version (Windows) asm { naked;
			mov RAX, RCX;
			bswap RAX;
			ret;
		} else asm { naked; // System V AMD64 ABI
			mov RAX, RDI;
			bswap RAX;
			ret;
		}
	} else {
		if (num) {
			ubyte* p = cast(ubyte*)&num;
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
		}
		return num;
	}
}