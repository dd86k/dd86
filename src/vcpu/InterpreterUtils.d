/*
 * InterpreterUtils.d : Interpreter utilities.
 */

module InterpreterUtils;

import Interpreter;
import Logger;
import core.stdc.stdio : printf, puts;
import core.stdc.string : memcpy, strcpy;
import core.stdc.wchar_ : wchar_t, wcscpy;

/**
 * Get effective address from a R/M byte.
 * Takes account of the preferred segment register.
 * Params: rm = R/M BYTE
 * Returns: Effective Address
 * Notes: Uses MOD and RM fields.
 */
extern (C)
uint get_ea(ubyte rm) {
	switch (rm & RM_MOD) { // MOD
	case RM_MOD_00: // MOD 00, Memory Mode, no displacement
		switch (Seg) {
		case SEG_CS:
			debug puts("MOD_00, get_ea::SEG_CS");
			break;
		case SEG_DS:
			debug puts("MOD_00, get_ea::SEG_DS");
			break;
		case SEG_ES:
			debug puts("MOD_00, get_ea::SEG_ES");
			break;
		case SEG_SS:
			debug puts("MOD_00, get_ea::SEG_SS");
			break;
		default:
			switch (rm & RM_RM) { // R/M
			case 0:
				debug puts("EA:0:0");
				return SI + BX;
			case 0b001:
				debug puts("EA:0:1");
				return DI + BX;
			case 0b010:
				debug puts("EA:0:2");
				return SI + BP;
			case 0b011:
				debug puts("EA:0:3");
				return DI + BP;
			case 0b100:
				debug puts("EA:0:4");
				return SI;
			case 0b101:
				debug puts("EA:0:5");
				return DI;
			case 0b110:
				debug puts("EA:0:6");
				return __fu16_i(1); // DIRECT ADDRESS
			case 0b111:
				debug puts("EA:0:7");
				return BX;
			default:
			}
		}
		break; // MOD 00
	case RM_MOD_01: // MOD 01, Memory Mode, 8-bit displacement follows
		debug puts("EA:1:_");
		EIP += 1;
		break; // MOD 01
	case RM_MOD_10: // MOD 10, Memory Mode, 16-bit displacement follows
		switch (Seg) {
		case SEG_CS:
			debug puts("MOD_10, get_ea::SEG_CS");
			break;
		case SEG_DS:
			debug puts("MOD_10, get_ea::SEG_DS");
			break;
		case SEG_ES:
			debug puts("MOD_10, get_ea::SEG_ES");
			break;
		case SEG_SS:
			debug puts("MOD_10, get_ea::SEG_SS");
			break;
		default:
			switch (rm & RM_RM) { // R/M
			case 0:
				debug puts("EA:2:0");
				return SI + BX + __fu16_i(1);
			case RM_RM_001:
				debug puts("EA:2:1");
				return DI + BX + __fu16_i(1);
			case RM_RM_010:
				debug puts("EA:2:2");
				return SI + BP + __fu16_i(1);
			case RM_RM_011:
				debug puts("EA:2:3");
				return DI + BP + __fu16_i(1);
			case RM_RM_100:
				debug puts("EA:2:4");
				return SI + __fu16_i(1);
			case RM_RM_101:
				debug puts("EA:2:5");
				return DI + __fu16_i(1);
			case RM_RM_110:
				debug puts("EA:2:6");
				return BP + __fu16_i(1);
			case RM_RM_111:
				debug puts("EA:2:7");
				return BX + __fu16_i(1);
			default:
			}
		}
		EIP += 2;
		break; // MOD 10
	case RM_MOD_11: // MOD 11, Register Mode
		debug printf("[dbug] EA:3:REG::%d", rm & RM_REG);
		debug printf("[dbug] EA:3:SEG::%d", Seg);
		switch (rm & RM_REG) {
		case RM_REG_000: 
			switch (Seg) {
			case SEG_CS: return get_ad(CS, AX);
			case SEG_DS: return get_ad(DS, AX);
			case SEG_ES: return get_ad(ES, AX);
			case SEG_SS: return get_ad(SS, AX);
			default: return AX;
			}
		case RM_REG_001:
			switch (Seg) {
			case SEG_CS: return get_ad(CS, CX);
			case SEG_DS: return get_ad(DS, CX);
			case SEG_ES: return get_ad(ES, CX);
			case SEG_SS: return get_ad(SS, CX);
			default: return CX;
			}
		case RM_REG_010:
			switch (Seg) {
			case SEG_CS: return get_ad(CS, DX);
			case SEG_DS: return get_ad(DS, DX);
			case SEG_ES: return get_ad(ES, DX);
			case SEG_SS: return get_ad(SS, DX);
			default: return DX;
			}
		case RM_REG_011:
			switch (Seg) {
			case SEG_CS: return get_ad(CS, BX);
			case SEG_DS: return get_ad(DS, BX);
			case SEG_ES: return get_ad(ES, BX);
			case SEG_SS: return get_ad(SS, BX);
			default: return BX;
			}
		case RM_REG_100:
			switch (Seg) {
			case SEG_CS: return get_ad(CS, SP);
			case SEG_DS: return get_ad(DS, SP);
			case SEG_ES: return get_ad(ES, SP);
			case SEG_SS: return get_ad(SS, SP);
			default: return SP;
			}
		case RM_REG_101:
			switch (Seg) {
			case SEG_CS: return get_ad(CS, BP);
			case SEG_DS: return get_ad(DS, BP);
			case SEG_ES: return get_ad(ES, BP);
			case SEG_SS: return get_ad(SS, BP);
			default: return BP;
			}
		case RM_REG_110:
			switch (Seg) {
			case SEG_CS: return get_ad(CS, SI);
			case SEG_DS: return get_ad(DS, SI);
			case SEG_ES: return get_ad(ES, SI);
			case SEG_SS: return get_ad(SS, SI);
			default: return SI;
			}
		case RM_REG_111:
			switch (Seg) {
			case SEG_CS: return get_ad(CS, DI);
			case SEG_DS: return get_ad(DS, DI);
			case SEG_ES: return get_ad(ES, DI);
			case SEG_SS: return get_ad(SS, DI);
			default: return DI;
			}
		default: return -1; // Temporary
		}
	default:
	}

	return -1; // Temporary until switch
}

/*****************************************************************************
 * Insert
 *****************************************************************************/

/**
 * Insert data in MEMORY
 * Params:
 *   ops = Data
 *   size = Data size
 *   offset = Memory location
 */
extern (C)
void __iarr(void* ops, size_t size, size_t offset) {
	memcpy(cast(void*)MEMORY + offset, ops, size);
}

/**
 * Insert a BYTE in MEMORY
 * Params:
 *   op = BYTE value
 *   addr = Memory address
 */
extern (C)
void __iu8(ubyte op, int addr) {
	MEMORY[addr] = op;
}

/**
 * Insert a WORD in MEMORY
 * Params:
 *   op = WORD value (will be casted)
 *   addr = Memory address
 */
extern (C)
void __iu16(int data, int addr) {
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
	*cast(uint*)(cast(void*)MEMORY + addr) = op;
}

/**
 * Insert an ASCIZ string in MEMORY
 * Params:
 *   data = String value
 *   addr = Memory address, default being CS:IP
 */
extern (C)
void __istr(immutable(char)* data, size_t addr = EIP) {
	strcpy(cast(char*)MEMORY + addr, data);
}

/**
 * Insert a wide string, null-terminated in MEMORY
 * Params:
 *   data = Wide wtring data
 *   addr = Memory Address (EIP by default)
 */
extern (C)
void __iwstr(immutable(wchar)[] data, size_t addr = EIP) {
	wcscpy(cast(wchar_t*)(cast(ubyte*)MEMORY + addr), cast(wchar_t*)data);
}

/*****************************************************************************
 * Fetch
 *****************************************************************************/

/**
 * Fetch an immediate BYTE at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: BYTE
 */
extern (C)
ubyte __fu8_i(int n = 0) {
	return MEMORY[EIP + 1 + n];
}

/**
 * Fetch an immediate WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: WORD
 */
extern (C)
ushort __fu16_i(uint n = 0) {
	return *cast(ushort*)(cast(ubyte*)MEMORY + EIP + 1 + n);
}

/**
 * Fetch an immediate signed WORD at EIP+1+n
 * Params: n = Optional offset (+1)
 * Returns: signed WORD
 */
extern (C)
short __fi16_i(uint n = 0) {
	return *cast(short*)(cast(ubyte*)MEMORY + EIP + 1 + n);
}

/**
 * Fetch an unsigned byte (ubyte).
 * Params: addr = Memory address
 * Returns: BYTE
 */
extern (C)
pragma(inline, true)
ubyte __fu8(uint addr) {
	return MEMORY[addr];
}

/**
 * Fetch a signed byte (byte).
 * Returns: Signed BYTE
 */
extern (C)
pragma(inline, true)
byte __fi8_i() {
	return cast(byte)MEMORY[EIP + 1];
}

/**
 * Fetch a WORD from MEMORY
 * Params: addr = Memory address
 * Returns: WORD
 */
extern (C)
ushort __fu16(uint addr) {
	return *cast(ushort*)(cast(ubyte*)MEMORY + addr);
}

/**
 * Fetch a DWORD from MEMORY
 * Params: addr = Memory address
 * Returns: DWORD
 */
extern (C)
uint __fu32(uint addr) {
	return *cast(uint*)(cast(ubyte*)MEMORY + addr);
}

/**
 * Fetch a signed WORD from memory
 * Params: addr = Memory address
 * Returns: signed WORD
 */
extern (C)
short __fi16(uint addr) {
	return *cast(short*)(cast(ubyte*)MEMORY + addr);
}