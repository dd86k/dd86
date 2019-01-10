/*
 * vcpu.utils : Processor utilities
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
void __hflag8_1(int r) {
	setZF(r);
	setAF_8(r);
	setSF_8(r);
	setPF_8(r);
	setOF_8(r);
	setCF_8(r);
}

/**
 * Handle result for GROUP1 (UNSIGNED WORD)
 * Affected: OF, SF, ZF, AF, CF, PF
 * Params: r = Operation result
 */
extern (C)
void __hflag16_1(int r) {
	setZF(r);
	setAF_16(r);
	setSF_16(r);
	setPF_16(r);
	setOF_16(r);
	setCF_16(r);
}

/**
 * Handle result for GROUP2 (UNSIGNED BYTE)
 * Affected: OF, SF, ZF, AF, PF
 * Undefined: CF undefined
 * Params: r = Operation result
 */
extern (C)
void __hflag8_2(int r) {
	setZF(r);
	setAF_8(r);
	setSF_8(r);
	setPF_8(r);
	setOF_8(r);
}

/**
 * Handle result for GROUP2 (UNSIGNED WORD)
 * Affected: OF, SF, ZF, AF, PF
 * Undefined: CF
 * Params: r = Operation result
 */
extern (C)
void __hflag16_2(int r) {
	setZF(r);
	setAF_16(r);
	setSF_16(r);
	setPF_16(r);
	setOF_16(r);
}

/**
 * Handle result for TEST (BYTE)
 * Affected: SF, ZF, PF
 * Cleared: OF, CF
 * Undefined: AF
 * Params: r = Input number
 */
extern (C)
void __hflag8_3(int r) {
	setZF(r);
	setSF_8(r);
	setPF_8(r);
	CPU.OF = CPU.CF = 0;
}

/**
 * Handle result for TEST (WORD)
 * Affected: SF, ZF, PF
 * Cleared: OF, CF
 * Undefined: AF
 * Params: r = Input number
 */
extern (C)
void __hflag16_3(int r) {
	setZF(r);
	setSF_16(r);
	setPF_16(r);
	CPU.OF = CPU.CF = 0;
}

/**
 * Handle result for MUL (BYTE)
 * Affected: OF, CF
 * Undefined: SF, ZF, AF, PF
 * Params: r = Input number
 */
extern (C)
void __hflag8_4(int r) {
	setOF_8(r);
	setCF_8(r);
}

/**
 * Handle result for MUL (WORD)
 * Affected: OF, CF
 * Undefined: SF, ZF, AF, PF
 * Params: r = Input number
 */
extern (C)
void __hflag16_4(int r) {
	setOF_16(r);
	setCF_16(r);
}

/**
 * Handle result for BYTE
 * Affected: SF, ZF, PF
 * Undefined: OF, CF, AF
 * Params: r = Input number
 */
extern (C)
void __hflag8_5(int r) {
	setZF(r);
	setSF_8(r);
	setPF_8(r);
}

/**
 * Handle result for WORD
 * Affected: SF, ZF, PF
 * Undefined: OF, CF, AF
 * Params: r = Input number
 */
extern (C)
void __hflag16_5(int r) {
	setZF(r);
	setSF_16(r);
	setPF_16(r);
}

//
// Conditional flag handlers
//

extern (C)
pragma(inline, true) {
	void setCF_8(int r) {
		CPU.CF = (r & 0x100) != 0;
	}
	void setCF_16(int r) {
		CPU.CF = (r & 0x10000) != 0;
	}
	void setPF_8(int r) {
		CPU.PF = ~(cast(ubyte)r ^ cast(ubyte)r) != 0; // XNOR(TEMP[0:7]);
	}
	void setPF_16(int r) {
		CPU.PF = ~(cast(ushort)r ^ cast(ushort)r) != 0;
	}
	void setAF_8(int r) {
		CPU.AF = (r & 0x10) != 0;
	}
	void setAF_16(int r) {
		CPU.AF = (r & 0x100) != 0;
	}
	void setZF(int r) {
		CPU.ZF = r == 0;
	}
	void setSF_8(int r) {
		CPU.SF = (r & 0x80) != 0;
	}
	void setSF_16(int r) {
		CPU.SF = (r & 0x8000) != 0;
	}
	void setOF_8(int r) {
		CPU.OF = r > 0xFF || r < 0;
	}
	void setOF_16(int r) {
		CPU.OF = r > 0xFFFF || r < 0;
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
	push16(FLAG);
	CPU.IF = CPU.TF = 0;
	push16(CPU.CS);
	push16(CPU.IP);
	//CS ← IDT[inum].selector;
	//IP ← IDT[inum].offset;
}

extern (C)
void __int_exit() { // REAL-MODE
	CPU.IP = pop16;
	CPU.CS = pop16;
	CPU.IF = CPU.TF = 1;
	FLAG = pop16;
}