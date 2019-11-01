/**
 * Processor utilities: Flag handling, bswap
 */
module vcpu.utils;

import vcpu.core, vcpu.mm;
import logger;

extern (C):

//
// CPU Flag handling utilities
//

pragma(inline, true):

/**
 * Handle result for GROUP1 (UNSIGNED BYTE)
 * Affected: OF, SF, ZF, AF, CF, PF
 * Params: r = Operation result
 */
void cpuf8_1(int r) {
	ZF16(r);
	AF8(r);
	SF8(r);
	PF8(r);
	OF8(r);
	CF8(r);
}

/**
 * Handle result for GROUP2 (UNSIGNED BYTE)
 * Affected: OF, SF, ZF, AF, PF
 * Undefined: CF undefined
 * Params: r = Operation result
 */
void cpuf8_2(int r) {
	ZF16(r);
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
void cpuf8_3(int r) {
	ZF16(r);
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
void cpuf8_4(int r) {
	OF8(r);
	CF8(r);
}

/**
 * Handle result for BYTE
 * Affected: SF, ZF, PF
 * Undefined: OF, CF, AF
 * Params: r = Input number
 */
void cpuf8_5(int r) {
	ZF16(r);
	SF8(r);
	PF8(r);
}

/**
 * Handle result for GROUP1 (UNSIGNED WORD)
 * Affected: OF, SF, ZF, AF, CF, PF
 * Params: r = Operation result
 */
void cpuf16_1(int r) {
	ZF16(r);
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
void cpuf16_2(int r) {
	ZF16(r);
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
void cpuf16_3(int r) {
	ZF16(r);
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
void cpuf16_5(int r) {
	ZF16(r);
	SF16(r);
	PF16(r);
}

/**
 * Handle result for DWORD.
 * Affected: ZF, AF, SF, PF, OF, CF
 * Params: r = DWORD result
 */
void cpuf32_1(long r) {
	ZF32(r);
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
void cpuf32_2(long r) {
	ZF32(r);
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
void cpuf32_3(long r) {
	CPU.OF = CPU.CF = 0;
	ZF32(r);
	SF32(r);
	PF32(r);
}

/**
 * Handle result for MUL (DWORD)
 * Affected: OF, CF
 * Undefined: SF, ZF, AF, PF
 * Params: r = Input number
 */
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
void cpuf32_5(long r) {
	ZF32(r);
	SF32(r);
	PF32(r);
}

//
// Conditional flag handlers
//

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
void ZF16(int r) {
	CPU.ZF = r == 0;
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
void ZF32(long r) {
	CPU.ZF = r == 0;
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

/**
 * Byte swap a 2-byte number.
 * Params: n = 2-byte number to swap.
 * Returns: Byte swapped number.
 */
ushort bswap16(ushort n) {
	return cast(ushort)(n >> 8 | n << 8);
}

/**
 * Byte swap a 4-byte number.
 * Params: n = 4-byte number to swap.
 * Returns: Byte swapped number.
 */
uint bswap32(uint n) {
	return (n >> 24) | (n & 0xFF_0000) >> 8 |
		(n & 0xFF00) << 8 | (n << 24);
}

pragma(inline, true):

/**
 * Get memory address out of a segment value and a register value.
 * Params:
 *   s = Segment register value
 *   o = Generic register value
 * Returns: SEG:ADDR Location
 */
uint address(int s, int o) {
	return (s << 4) | o;
}

/**
 * (8086) Get next instruction location
 * Returns: CS:IP effective address
 */
uint get_ip() {
	return address(CPU.CS, CPU.IP);
}