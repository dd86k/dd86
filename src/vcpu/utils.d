/**
 * utils: Processor utilities
 *
 * Flag handling, bswap utils, and interrupt utils
 */
module vcpu.utils;

import vcpu.core, vcpu.mm;
import logger;




//
// CPU Flag handling utilities
//

/**
 * Handle result for GROUP1 (UNSIGNED BYTE)
 * Affected: OF, SF, ZF, AF, CF, PF
 * Params: r = Operation result
 */
extern (C)
void cpuf8_1(int r) {
	ZF(r);
	AF8(r);
	SF8(r);
	PF8(r);
	OF8(r);
	CF8(r);
}

/**
 * Handle result for BYTE
 * Affected: SF, ZF, PF
 * Undefined: OF, CF, AF
 * Params: r = Input number
 */
extern (C)
void cpuf8_5(int r) {
	ZF(r);
	SF8(r);
	PF8(r);
}

/**
 * Handle result for GROUP2 (UNSIGNED BYTE)
 * Affected: OF, SF, ZF, AF, PF
 * Undefined: CF undefined
 * Params: r = Operation result
 */
extern (C)
void cpuf8_2(int r) {
	ZF(r);
	AF8(r);
	SF8(r);
	PF8(r);
	OF8(r);
}

/**
 * Handle result for TEST (BYTE)
 * Affected: SF, ZF, PF
 * Cleared: OF, CF
 * Undefined: AF
 * Params: r = Input number
 */
extern (C)
void cpuf8_3(int r) {
	ZF(r);
	SF8(r);
	PF8(r);
	CPU.OF = CPU.CF = 0;
}

/**
 * Handle result for MUL (BYTE)
 * Affected: OF, CF
 * Undefined: SF, ZF, AF, PF
 * Params: r = Input number
 */
extern (C)
void cpuf8_4(int r) {
	OF8(r);
	CF8(r);
}

/**
 * Handle result for GROUP1 (UNSIGNED WORD)
 * Affected: OF, SF, ZF, AF, CF, PF
 * Params: r = Operation result
 */
extern (C)
void cpuf16_1(int r) {
	ZF(r);
	AF16(r);
	SF16(r);
	PF16(r);
	OF16(r);
	CF16(r);
}

/**
 * Handle result for GROUP2 (UNSIGNED WORD)
 * Affected: OF, SF, ZF, AF, PF
 * Undefined: CF
 * Params: r = Operation result
 */
extern (C)
void cpuf16_2(int r) {
	ZF(r);
	AF16(r);
	SF16(r);
	PF16(r);
	OF16(r);
}

/**
 * Handle result for TEST (WORD)
 * Affected: SF, ZF, PF
 * Cleared: OF, CF
 * Undefined: AF
 * Params: r = Input number
 */
extern (C)
void cpuf16_3(int r) {
	ZF(r);
	SF16(r);
	PF16(r);
	CPU.OF = CPU.CF = 0;
}

/**
 * Handle result for MUL (WORD)
 * Affected: OF, CF
 * Undefined: SF, ZF, AF, PF
 * Params: r = Input number
 */
extern (C)
void cpuf16_4(int r) {
	OF16(r);
	CF16(r);
}

/**
 * Handle result for WORD
 * Affected: SF, ZF, PF
 * Undefined: OF, CF, AF
 * Params: r = Input number
 */
extern (C)
void cpuf16_5(int r) {
	ZF(r);
	SF16(r);
	PF16(r);
}

/**
 * Handle result for DWORD.
 * Affected: ZF, AF, SF, PF, OF, CF
 * Params: r = DWORD result
 */
pragma(inline, true)
void cpuf32_1(long r) {
	ZF(r);
	AF32(r);
	SF32(r);
	PF32(r);
	OF32(r);
	CF32(r);
}

/**
 * Handle result for DWORD.
 * Affected: OF, SF, ZF, AF, PF
 * Undefined: CF undefined
 * Params: r = DWORD result
 */
pragma(inline, true)
void cpuf32_2(long r) {
	ZF(r);
	AF32(r);
	SF32(r);
	PF32(r);
	OF32(r);
}

/**
 * Handle result for DWORD.
 * Affected: SF, ZF, PF
 * Cleared: OF, CF
 * Undefined: AF
 * Params: r = DWORD result
 */
pragma(inline, true)
void cpuf32_3(long r) {
	CPU.OF = CPU.CF = 0;
	ZF(r);
	SF32(r);
	PF32(r);
}

/**
 * Handle result for MUL (DWORD)
 * Affected: OF, CF
 * Undefined: SF, ZF, AF, PF
 * Params: r = Input number
 */
pragma(inline, true)
void cpuf32_4(long r) {
	OF32(r);
	CF32(r);
}

/**
 * Handle result for DWORD
 * Affected: SF, ZF, PF
 * Undefined: OF, CF, AF
 * Params: r = Input number
 */
pragma(inline, true)
void cpuf16_5(long r) {
	ZF(r);
	SF32(r);
	PF32(r);
}

//
// Conditional flag handlers
//

pragma(inline, true) {
	void ZF(int r) {
		CPU.ZF = r == 0;
	}
	void ZF(long r) {
		CPU.ZF = r == 0;
	}
	void CF8(int r) {
		CPU.CF = (r & 0x100) != 0;
	}
	void PF8(int r) {
		CPU.PF = ~(cast(ubyte)r ^ cast(ubyte)r) != 0; // XNOR(TEMP[0:7]);
	}
	void SF8(int r) {
		CPU.SF = (r & 0x80) != 0;
	}
	void AF8(int r) {
		CPU.AF = (r & 0x10) != 0;
	}
	void OF8(int r) {
		CPU.OF = r > 0xFF || r < 0;
	}
	void PF16(int r) {
		CPU.PF = ~(cast(ushort)r ^ cast(ushort)r) != 0;
	}
	void CF16(int r) {
		CPU.CF = (r & 0x1_0000) != 0;
	}
	void AF16(int r) {
		CPU.AF = (r & 0x100) != 0;
	}
	void SF16(int r) {
		CPU.SF = (r & 0x8000) != 0;
	}
	void OF16(int r) {
		CPU.OF = r > 0xFFFF || r < 0;
	}
	void PF32(long r) {
		CPU.PF = ~(cast(uint)r ^ cast(uint)r) != 0;
	}
	void CF32(long r) {
		CPU.CF = (r & 0x1_0000_0000) != 0;
	}
	void AF32(long r) {
		CPU.AF = (r & 0x100_0000) != 0;
	}
	void SF32(long r) {
		CPU.SF = (r & 0x8000_0000) != 0;
	}
	void OF32(long r) {
		CPU.OF = r > 0xFFFF_FFFF || r < 0;
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
	return (n >> 24) | (n & 0xFF_0000) >> 8 |
		(n & 0xFF00) << 8 | (n << 24);
}

//
// Interrupt helpers
//

extern (C)
void __int_enter() { // REAL-MODE
	//const inum = code << 2;
	/*IF (inum + 3 > IDT limit)
		#GP
	IF stack not large enough for a 6-byte return information
		#SS*/
	CPU.push16(CPU.FLAG);
	CPU.IF = CPU.TF = 0;
	CPU.push16(CPU.CS);
	CPU.push16(CPU.IP);
	//CS ← IDT[inum].selector;
	//IP ← IDT[inum].offset;
}

extern (C)
void __int_exit() { // REAL-MODE
	CPU.IP = CPU.pop16;
	CPU.CS = CPU.pop16;
	CPU.IF = CPU.TF = 1;
	CPU.FLAG = CPU.pop16;
}

/**
 * Get memory address out of a segment value and a register value.
 * Params:
 *   s = Segment register value
 *   o = Generic register value
 * Returns: SEG:ADDR Location
 */
pragma(inline, true)
uint address(int s, int o) {
	return (s << 4) | o;
}

/**
 * (8086) Get next instruction location
 * Returns: CS:IP effective address
 */
pragma(inline, true)
uint get_ip() {
	return address(CPU.CS, CPU.IP);
}