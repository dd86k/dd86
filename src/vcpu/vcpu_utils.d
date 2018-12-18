/*
 * vcpu_utils.d : vcpu utilities.
 */

module vcpu_utils;

import core.stdc.string : memcpy, strcpy;
import core.stdc.wchar_ : wchar_t, wcscpy;
import vcpu;
import Logger;
import vdos_codes : PANIC_MEMORY_ACCESS;

/**
 * Get effective address from a R/M byte.
 * Takes account of the preferred segment register.
 * MOD and RM fields are used, and Seg is reset (SEG_NONE).
 * Params:
 *   rm = R/M BYTE
 *   wide = wide bit set in opcode
 * Returns: Effective Address
 */
extern (C)
uint get_rm16(ubyte rm, ubyte wide = 0) {
	//TODO: Reset Seg to SEG_NONE
	//TODO: Use general purpose variable to hold segreg value
	switch (rm & RM_MOD) { // MOD
	case RM_MOD_00: // MOD 00, Memory Mode, no displacement
		switch (Seg) {
		case SEG_CS:
			debug _debug("MOD_00, get_ea::SEG_CS");
			break;
		case SEG_DS:
			debug _debug("MOD_00, get_ea::SEG_DS");
			break;
		case SEG_ES:
			debug _debug("MOD_00, get_ea::SEG_ES");
			break;
		case SEG_SS:
			debug _debug("MOD_00, get_ea::SEG_SS");
			break;
		default:
			switch (rm & RM_RM) { // R/M
			case RM_RM_000: return CPU.SI + CPU.BX;
			case RM_RM_001: return CPU.DI + CPU.BX;
			case RM_RM_010: return CPU.SI + CPU.BP;
			case RM_RM_011: return CPU.DI + CPU.BP;
			case RM_RM_100: return CPU.SI;
			case RM_RM_101: return CPU.DI;
			case RM_RM_110: return __fu16_i(1);
			case RM_RM_111: return CPU.BX;
			default:
			}
		}
		break; // MOD 00
	case RM_MOD_01: { // MOD 01, Memory Mode, 8-bit displacement follows
		switch (rm & RM_RM) {
		case RM_RM_000: return CPU.SI + CPU.BX + __fi8_i(1);
		case RM_RM_001: return CPU.DI + CPU.BX + __fi8_i(1);
		case RM_RM_010: return CPU.SI + CPU.BP + __fi8_i(1);
		case RM_RM_011: return CPU.DI + CPU.BP + __fi8_i(1);
		case RM_RM_100: return CPU.SI + __fi8_i(1);
		case RM_RM_101: return CPU.DI + __fi8_i(1);
		case RM_RM_110: return CPU.BP + __fi8_i(1);
		case RM_RM_111: return CPU.BX + __fi8_i(1);
		default:
		}
		++CPU.EIP;
		break; // MOD 01
	}
	case RM_MOD_10: // MOD 10, Memory Mode, 16-bit displacement follows
		switch (Seg) {
		case SEG_CS:
			debug _debug("MOD_10, get_ea::SEG_CS");
			break;
		case SEG_DS:
			debug _debug("MOD_10, get_ea::SEG_DS");
			break;
		case SEG_ES:
			debug _debug("MOD_10, get_ea::SEG_ES");
			break;
		case SEG_SS:
			debug _debug("MOD_10, get_ea::SEG_SS");
			break;
		default:
			switch (rm & RM_RM) { // R/M
			case RM_RM_000: return CPU.SI + CPU.BX + __fi16_i(1);
			case RM_RM_001: return CPU.DI + CPU.BX + __fi16_i(1);
			case RM_RM_010: return CPU.SI + CPU.BP + __fi16_i(1);
			case RM_RM_011: return CPU.DI + CPU.BP + __fi16_i(1);
			case RM_RM_100: return CPU.SI + __fi16_i(1);
			case RM_RM_101: return CPU.DI + __fi16_i(1);
			case RM_RM_110: return CPU.BP + __fi16_i(1);
			case RM_RM_111: return CPU.BX + __fi16_i(1);
			default:
			}
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

//TODO: Write get_rm32

/*****************************************************************************
 * Flag utils
 *****************************************************************************/

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

// Conditional flag handlers

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

/*****************************************************************************
 * Insert
 *****************************************************************************/

/**
 * Insert a BYTE in MEMORY
 * Params:
 *   op = BYTE value
 *   addr = Memory address
 */
extern (C)
pragma(inline, true)
void __iu8(int op, int addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __iu8", PANIC_MEMORY_ACCESS);
	MEMORY[addr] = cast(ubyte)op;
}

/**
 * Insert a WORD in MEMORY
 * Params:
 *   data = WORD value (will be casted)
 *   addr = Memory address
 */
extern (C)
void __iu16(int data, int addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __iu16", PANIC_MEMORY_ACCESS);
	*cast(ushort*)(MEMORY + addr) = cast(ushort)data;
}

/**
 * Insert a DWORD in MEMORY
 * Params:
 *   op = DWORD value
 *   addr = Memory address
 */
extern (C)
void __iu32(uint op, int addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __iu32", PANIC_MEMORY_ACCESS);
	*cast(uint*)(MEMORY + addr) = op;
}

/**
 * Insert data in MEMORY
 * Params:
 *   ops = Data
 *   size = Data size
 *   addr = Memory location
 */
extern (C)
void __iarr(void *ops, size_t size, size_t addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __iarr", PANIC_MEMORY_ACCESS);
	memcpy(MEMORY + addr, ops, size);
}

/**
 * Insert an ASCIZ string in MEMORY
 * Params:
 *   data = String value
 *   addr = Memory address, default: CS:IP
 */
extern (C)
void __istr(immutable(char) *data, size_t addr = CPU.EIP) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __istr", PANIC_MEMORY_ACCESS);
	strcpy(cast(char*)(MEMORY + addr), data);
}

/**
 * Insert a null-terminated wide string in MEMORY
 * Params:
 *   data = Wide wtring data
 *   addr = Memory Address (EIP by default)
 */
extern (C)
void __iwstr(immutable(wchar)[] data, size_t addr = CPU.EIP) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __iwstr", PANIC_MEMORY_ACCESS);
	wcscpy(cast(wchar_t*)(MEMORY + addr), cast(wchar_t*)data);
}

/*****************************************************************************
 * Fetch
 *****************************************************************************/

/**
 * Fetch an unsigned byte (ubyte).
 * Params: addr = Memory address
 * Returns: BYTE
 */
extern (C)
ubyte __fu8(uint addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __fu8", PANIC_MEMORY_ACCESS);
	return MEMORY[addr];
}

/**
 * Fetch an unsigned byte (ubyte).
 * Params: addr = Memory address
 * Returns: BYTE
 */
extern (C)
byte __fi8(uint addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __fi8", PANIC_MEMORY_ACCESS);
	return cast(byte)MEMORY[addr];
}

/**
 * Fetch a WORD from MEMORY
 * Params: addr = Memory address
 * Returns: WORD
 */
extern (C)
ushort __fu16(uint addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __fu16", PANIC_MEMORY_ACCESS);
	return *cast(ushort*)(MEMORY + addr);
}

/**
 * Fetch a signed WORD from memory
 * Params: addr = Memory address
 * Returns: signed WORD
 */
extern (C)
short __fi16(uint addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __fi16", PANIC_MEMORY_ACCESS);
	return *cast(short*)(MEMORY + addr);
}

/**
 * Fetch a DWORD from MEMORY
 * Params: addr = Memory address
 * Returns: DWORD
 */
extern (C)
uint __fu32(uint addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __fu32", PANIC_MEMORY_ACCESS);
	return *cast(uint*)(MEMORY + addr);
}

/*****************************************************************************
 * Fetch immediates
 *****************************************************************************/

/**
 * Fetch an immediate BYTE at CPU.EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: BYTE
 */
extern (C)
ubyte __fu8_i(int n = 0) {
	if (C_OVERFLOW(n)) crit("ACCESS VIOLATION IN __fu8_i", PANIC_MEMORY_ACCESS);
	return MEMORY[CPU.EIP + 1 + n];
}

/**
 * Fetch a signed byte (byte).
 * Params: n = Optional offset from EIP+1
 * Returns: Signed BYTE
 */
extern (C)
byte __fi8_i(int n = 0) {
	if (C_OVERFLOW(n)) crit("ACCESS VIOLATION IN __fi8_i", PANIC_MEMORY_ACCESS);
	return cast(byte)MEMORY[CPU.EIP + 1 + n];
}

/**
 * Fetch an immediate WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: WORD
 */
extern (C)
ushort __fu16_i(uint n = 0) {
	if (C_OVERFLOW(n)) crit("ACCESS VIOLATION IN __fu16_i", PANIC_MEMORY_ACCESS);
	return *cast(ushort*)(MEMORY + CPU.EIP + 1 + n);
}

/**
 * Fetch an immediate signed WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: signed WORD
 */
extern (C)
short __fi16_i(uint n = 0) {
	if (C_OVERFLOW(n)) crit("ACCESS VIOLATION IN __fi16_i", PANIC_MEMORY_ACCESS);
	return *cast(short*)(MEMORY + CPU.EIP + 1 + n);
}

/*****************************************************************************
 * Util helpers
 *****************************************************************************/

/**
 * Check for overflow from MEMORY.
 * Params: addr = virtual memory address
 * Returns: True if overflowed
 */
pragma(inline, true)
extern (C) private
bool C_OVERFLOW(size_t addr) {
	return addr < 0 || addr > MEMORYSIZE;
}

/*****************************************************************************
 * Interrupt helpers
 *****************************************************************************/

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

void __int_exit() { // REAL-MODE
	CPU.IP = pop16;
	CPU.CS = pop16;
	CPU.IF = CPU.TF = 1;
	FLAG = pop16;
}