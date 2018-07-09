/*
 * vcpu_utils.d : vcpu utilities.
 */

module vcpu_utils;

import core.stdc.stdio : printf, puts;
import core.stdc.string : memcpy, strcpy;
import core.stdc.wchar_ : wchar_t, wcscpy;
import vcpu;
import Logger;
import vdos_codes : PANIC_MEMORY_ACCESS;

/**
 * Get effective address from a R/M byte.
 * Takes account of the preferred segment register.
 * MOD and RM fields are used, and Seg is reset (SEG_NONE) (TODO latter).
 * Params:
 *   rm = R/M BYTE
 *   wide = wide bit set in opcode
 * Returns: Effective Address
 */
extern (C)
uint get_ea(ubyte rm, ubyte wide = 0) {
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
			case RM_RM_000: debug _debug("EA:0:0");
				return SI + BX;
			case RM_RM_001: debug _debug("EA:0:1");
				return DI + BX;
			case RM_RM_010: debug _debug("EA:0:2");
				return SI + BP;
			case RM_RM_011: debug _debug("EA:0:3");
				return DI + BP;
			case RM_RM_100: debug _debug("EA:0:4");
				return SI;
			case RM_RM_101: debug _debug("EA:0:5");
				return DI;
			case RM_RM_110: debug _debug("EA:0:6");
				return __fu16_i(1); // DIRECT ADDRESS, immediate follows
			case RM_RM_111: debug _debug("EA:0:7");
				return BX;
			default:
			}
		}
		break; // MOD 00
	case RM_MOD_01: { // MOD 01, Memory Mode, 8-bit displacement follows
		debug _debug("EA:1:_");
		switch (rm & RM_RM) {
		case RM_RM_000: debug _debug("EA:1:0");
			return SI + BX + __fi8_i(1);
		case RM_RM_001: debug _debug("EA:1:1");
			return DI + BX + __fi8_i(1);
		case RM_RM_010: debug _debug("EA:1:2");
			return SI + BP + __fi8_i(1);
		case RM_RM_011: debug _debug("EA:1:3");
			return DI + BP + __fi8_i(1);
		case RM_RM_100: debug _debug("EA:1:4");
			return SI + __fi8_i(1);
		case RM_RM_101: debug _debug("EA:1:5");
			return DI + __fi8_i(1);
		case RM_RM_110: debug _debug("EA:1:6");
			return BP + __fi8_i(1);
		case RM_RM_111: debug _debug("EA:1:7");
			return BX + __fi8_i(1);
		default:
		}
		EIP += 1;
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
			case 0:
				debug _debug("EA:2:0");
				return SI + BX + __fi16_i(1);
			case RM_RM_001:
				debug _debug("EA:2:1");
				return DI + BX + __fi16_i(1);
			case RM_RM_010:
				debug _debug("EA:2:2");
				return SI + BP + __fi16_i(1);
			case RM_RM_011:
				debug _debug("EA:2:3");
				return DI + BP + __fi16_i(1);
			case RM_RM_100:
				debug _debug("EA:2:4");
				return SI + __fi16_i(1);
			case RM_RM_101:
				debug _debug("EA:2:5");
				return DI + __fi16_i(1);
			case RM_RM_110:
				debug _debug("EA:2:6");
				return BP + __fi16_i(1);
			case RM_RM_111:
				debug _debug("EA:2:7");
				return BX + __fi16_i(1);
			default:
			}
		}
		EIP += 2;
		break; // MOD 10
	case RM_MOD_11: // MOD 11, Register Mode
		if (wide)
			switch (rm & RM_RM) {
			case RM_RM_000: return AX;
			case RM_RM_001: return CX;
			case RM_RM_010: return DX;
			case RM_RM_011: return BX;
			case RM_RM_100: return SP;
			case RM_RM_101: return BP;
			case RM_RM_110: return SI;
			case RM_RM_111: return DI;
			default:
			}
		else
			switch (rm & RM_RM) {
			case RM_RM_000: return AL;
			case RM_RM_001: return CL;
			case RM_RM_010: return DL;
			case RM_RM_011: return BL;
			case RM_RM_100: return AH;
			case RM_RM_101: return CH;
			case RM_RM_110: return DH;
			case RM_RM_111: return BH;
			default:
			}
		break; // MOD 11
	default:
	}

	return 0;
}

//TODO: get_ea32

/*****************************************************************************
 * Flag utils
 *****************************************************************************/

/**
 * Handle result for GROUP1 (UNSIGNED BYTE)
 * OF, SF, ZF, AF, CF, and PF affected
 * Params: r = Operation result
 */
extern (C)
void __hflag8_1(int r) {
	CF = (r & 0x100) != 0;
	SF = (r & 0x80) != 0;
	AF = (r & 0x10) != 0;
	ZF = r == 0;
	OF = r > 0xFF || r < 0;
	PF = ~(cast(ubyte)r ^ cast(ubyte)r) != 0;
}

/**
 * Handle result for GROUP1 (UNSIGNED WORD)
 * OF, SF, ZF, AF, CF, and PF affected
 * Params: r = Operation result
 */
extern (C)
void __hflag16_1(int r) {
	CF = (r & 0x1_0000) != 0;
	SF = (r & 0x8000) != 0;
	AF = (r & 0x100) != 0;
	ZF = r == 0;
	OF = r > 0xFFFF || r < 0;
	PF = ~(cast(ushort)r ^ cast(ushort)r) != 0;
}

/**
 * Handle result for GROUP2 (UNSIGNED BYTE)
 * OF, SF, ZF, AF, and PF affected
 * CF undefined
 * Params: r = Operation result
 */
extern (C)
void __hflag8_2(int r) {
	SF = (r & 0x80) != 0;
	AF = (r & 0x10) != 0;
	ZF = r == 0;
	OF = r > 0xFF || r < 0;
	PF = ~(cast(ubyte)r ^ cast(ubyte)r) != 0;
}

/**
 * Handle result for GROUP2 (UNSIGNED WORD)
 * OF, SF, ZF, AF, and PF affected
 * CF undefined
 * Params: r = Operation result
 */
extern (C)
void __hflag16_2(int r) {
	SF = (r & 0x8000) != 0;
	AF = (r & 0x100) != 0;
	ZF = r == 0;
	OF = r > 0xFFFF || r < 0;
	PF = ~(cast(ushort)r ^ cast(ushort)r) != 0;
}

/**
 * Handle result for TEST (BYTE)
 * SF, ZF, and PF affected
 * OF, CF cleared
 * AF undefined
 */
extern (C)
void __hflag8_3(int r) {
	ZF = r == 0;
	SF = (r & 0x80) != 0;
	PF = ~(cast(ubyte)r ^ cast(ubyte)r) != 0; // XNOR(TEMP[0:7]);
	OF = CF = 0;
}

/**
 * Handle result for TEST (WORD)
 * SF, ZF, and PF affected
 * OF, CF cleared
 * AF undefined
 */
extern (C)
void __hflag16_3(int r) {
	ZF = r == 0;
	SF = (r & 0x8000) != 0;
	PF = ~(cast(ubyte)r ^ cast(ubyte)r) != 0; // XNOR(TEMP[0:7]);
	OF = CF = 0;
}

/**
 * Handle result for MUL (BYTE)
 * OF, CF affected
 * SF, ZF, AF, PF undefined
 */
extern (C)
void __hflag8_4(int r) {
	OF = r > 0xFF || r < 0;
	CF = cast(ubyte)(r & 0x100);
}

/**
 * Handle result for MUL (WORD)
 * OF, CF affected
 * SF, ZF, AF, PF undefined
 */
extern (C)
void __hflag16_4(int r) {
	OF = r > 0xFFFF || r < 0;
	CF = cast(ubyte)(r & 0x1_0000);
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
 *   op = WORD value (will be casted)
 *   addr = Memory address
 */
extern (C)
void __iu16(int data, int addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __iu16", PANIC_MEMORY_ACCESS);
	*cast(ushort*)(cast(void*)MEMORY + addr) = cast(ushort)data;
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
	*cast(uint*)(cast(void*)MEMORY + addr) = op;
}

/**
 * Insert data in MEMORY
 * Params:
 *   ops = Data
 *   size = Data size
 *   addr = Memory location
 */
extern (C)
void __iarr(void* ops, size_t size, size_t addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __iarr", PANIC_MEMORY_ACCESS);
	memcpy(cast(void*)MEMORY + addr, ops, size);
}

/**
 * Insert an ASCIZ string in MEMORY
 * Params:
 *   data = String value
 *   addr = Memory address, default: CS:IP
 */
extern (C)
void __istr(immutable(char)* data, size_t addr = EIP) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __istr", PANIC_MEMORY_ACCESS);
	strcpy(cast(char*)MEMORY + addr, data);
}

/**
 * Insert a null-terminated wide string in MEMORY
 * Params:
 *   data = Wide wtring data
 *   addr = Memory Address (EIP by default)
 */
extern (C)
void __iwstr(immutable(wchar)[] data, size_t addr = EIP) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __iwstr", PANIC_MEMORY_ACCESS);
	wcscpy(cast(wchar_t*)(MEMORY_P + addr), cast(wchar_t*)data);
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
	return *cast(ushort*)(MEMORY_P + addr);
}

/**
 * Fetch a signed WORD from memory
 * Params: addr = Memory address
 * Returns: signed WORD
 */
extern (C)
short __fi16(uint addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __fi16", PANIC_MEMORY_ACCESS);
	return *cast(short*)(MEMORY_P + addr);
}

/**
 * Fetch a DWORD from MEMORY
 * Params: addr = Memory address
 * Returns: DWORD
 */
extern (C)
uint __fu32(uint addr) {
	if (C_OVERFLOW(addr)) crit("ACCESS VIOLATION IN __fu32", PANIC_MEMORY_ACCESS);
	return *cast(uint*)(MEMORY_P + addr);
}

/*****************************************************************************
 * Fetch immediates
 *****************************************************************************/

/**
 * Fetch an immediate BYTE at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: BYTE
 */
extern (C)
ubyte __fu8_i(int n = 0) {
	if (C_OVERFLOW(n)) crit("ACCESS VIOLATION IN__fu8_i", PANIC_MEMORY_ACCESS);
	return MEMORY[EIP + 1 + n];
}

/**
 * Fetch a signed byte (byte).
 * Returns: Signed BYTE
 */
extern (C)
pragma(inline, true)
byte __fi8_i(int n = 0) {
	if (C_OVERFLOW(n)) crit("ACCESS VIOLATION IN __fi8_i", PANIC_MEMORY_ACCESS);
	return cast(byte)MEMORY[EIP + 1 + n];
}

/**
 * Fetch an immediate WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: WORD
 */
extern (C)
ushort __fu16_i(uint n = 0) {
	if (C_OVERFLOW(n)) crit("ACCESS VIOLATION IN __fu16_i", PANIC_MEMORY_ACCESS);
	return *cast(ushort*)(MEMORY_P + EIP + 1 + n);
}

/**
 * Fetch an immediate signed WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: signed WORD
 */
extern (C)
short __fi16_i(uint n = 0) {
	if (C_OVERFLOW(n)) crit("ACCESS VIOLATION IN __fi16_i", PANIC_MEMORY_ACCESS);
	return *cast(short*)(MEMORY_P + EIP + 1 + n);
}

/*****************************************************************************
 * Util helpers
 *****************************************************************************/

pragma(inline, true)
extern (C)
bool C_OVERFLOW(size_t addr) {
	return addr < 0 || addr > MEMORYSIZE;
}