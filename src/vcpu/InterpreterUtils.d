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
uint GetEA(ubyte rm) {
	switch (rm & RM_MOD) { // MOD
	case RM_MOD_00: // MOD 00, Memory Mode, no displacement
		switch (Seg) {
		case SEG_CS:
			debug puts("MOD_00, GetEA::SEG_CS");
			break;
		case SEG_DS:
			debug puts("MOD_00, GetEA::SEG_DS");
			break;
		case SEG_ES:
			debug puts("MOD_00, GetEA::SEG_ES");
			break;
		case SEG_SS:
			debug puts("MOD_00, GetEA::SEG_SS");
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
				return FetchImmWord(1); // DIRECT ADDRESS
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
			debug puts("MOD_10, GetEA::SEG_CS");
			break;
		case SEG_DS:
			debug puts("MOD_10, GetEA::SEG_DS");
			break;
		case SEG_ES:
			debug puts("MOD_10, GetEA::SEG_ES");
			break;
		case SEG_SS:
			debug puts("MOD_10, GetEA::SEG_SS");
			break;
		default:
			switch (rm & RM_RM) { // R/M
			case 0:
				debug puts("EA:2:0");
				return SI + BX + FetchImmWord(1);
			case RM_RM_001:
				debug puts("EA:2:1");
				return DI + BX + FetchImmWord(1);
			case RM_RM_010:
				debug puts("EA:2:2");
				return SI + BP + FetchImmWord(1);
			case RM_RM_011:
				debug puts("EA:2:3");
				return DI + BP + FetchImmWord(1);
			case RM_RM_100:
				debug puts("EA:2:4");
				return SI + FetchImmWord(1);
			case RM_RM_101:
				debug puts("EA:2:5");
				return DI + FetchImmWord(1);
			case RM_RM_110:
				debug puts("EA:2:6");
				return BP + FetchImmWord(1);
			case RM_RM_111:
				debug puts("EA:2:7");
				return BX + FetchImmWord(1);
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
			case SEG_CS: return GetAddress(CS, AX);
			case SEG_DS: return GetAddress(DS, AX);
			case SEG_ES: return GetAddress(ES, AX);
			case SEG_SS: return GetAddress(SS, AX);
			default: return AX;
			}
		case RM_REG_001:
			switch (Seg) {
			case SEG_CS: return GetAddress(CS, CX);
			case SEG_DS: return GetAddress(DS, CX);
			case SEG_ES: return GetAddress(ES, CX);
			case SEG_SS: return GetAddress(SS, CX);
			default: return CX;
			}
		case RM_REG_010:
			switch (Seg) {
			case SEG_CS: return GetAddress(CS, DX);
			case SEG_DS: return GetAddress(DS, DX);
			case SEG_ES: return GetAddress(ES, DX);
			case SEG_SS: return GetAddress(SS, DX);
			default: return DX;
			}
		case RM_REG_011:
			switch (Seg) {
			case SEG_CS: return GetAddress(CS, BX);
			case SEG_DS: return GetAddress(DS, BX);
			case SEG_ES: return GetAddress(ES, BX);
			case SEG_SS: return GetAddress(SS, BX);
			default: return BX;
			}
		case RM_REG_100:
			switch (Seg) {
			case SEG_CS: return GetAddress(CS, SP);
			case SEG_DS: return GetAddress(DS, SP);
			case SEG_ES: return GetAddress(ES, SP);
			case SEG_SS: return GetAddress(SS, SP);
			default: return SP;
			}
		case RM_REG_101:
			switch (Seg) {
			case SEG_CS: return GetAddress(CS, BP);
			case SEG_DS: return GetAddress(DS, BP);
			case SEG_ES: return GetAddress(ES, BP);
			case SEG_SS: return GetAddress(SS, BP);
			default: return BP;
			}
		case RM_REG_110:
			switch (Seg) {
			case SEG_CS: return GetAddress(CS, SI);
			case SEG_DS: return GetAddress(DS, SI);
			case SEG_ES: return GetAddress(ES, SI);
			case SEG_SS: return GetAddress(SS, SI);
			default: return SI;
			}
		case RM_REG_111:
			switch (Seg) {
			case SEG_CS: return GetAddress(CS, DI);
			case SEG_DS: return GetAddress(DS, DI);
			case SEG_ES: return GetAddress(ES, DI);
			case SEG_SS: return GetAddress(SS, DI);
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
 * Insert data in memory (uses memcpy)
 * Params:
 *   ops = Data
 *   size = Data size
 *   offset = Memory location
 */
extern (C)
void InsertArray(void* ops, size_t size, size_t offset) {
	memcpy(cast(void*)MEMORY + offset, ops, size);
}

/**
 * Insert a BYTE in memory.
 * Params:
 *   op = BYTE value
 *   addr = Memory address
 */
extern (C)
void InsertByte(ubyte op, int addr) {
	MEMORY[addr] = op;
}
/**
 * Insert a WORD in memory.
 * Params:
 *   op = WORD value (will be casted)
 *   addr = Memory address
 */
extern (C)
void InsertWord(int data, int addr) { // int promotion ;-)
	*cast(ushort*)(cast(void*)MEMORY + addr) = cast(ushort)data;
}
/**
 * Insert a DWORD in memory.
 * Params:
 *   op = DWORD value
 *   addr = Memory address
 */
extern (C)
void InsertDWord(uint op, int addr) {
	*cast(uint*)(cast(void*)MEMORY + addr) = op;
}
/**
 * Insert an ASCIZ string in memory.
 * Params:
 *   data = String value
 *   addr = Memory address, default being CS:IP
 */
extern (C)
void InsertString(immutable(char)* data, size_t addr = EIP) {
	strcpy(cast(char*)MEMORY + addr, data);
}
/**
 * Insert a wide string, null-terminated, in memory.
 * Params:
 *   data = Wide wtring data
 *   addr = Memory Address (EIP by default)
 */
extern (C)
void InsertWString(immutable(wchar)[] data, size_t addr = EIP) {
	wcscpy(cast(wchar_t*)(cast(ubyte*)MEMORY + addr), cast(wchar_t*)data);
}

/*****************************************************************************
 * Fetch
 *****************************************************************************/

/**
 * Fetch an immediate BYTE at CS:IP+n+1
 * Params: off = Optional offset (+1)
 * Returns: BYTE
 */
extern (C)
ubyte FetchImmByte(int off = 0) {
	return MEMORY[EIP + 1 + off];
}
/**
 * Fetch an immediate WORD at CS:IP+n+1
 * Params: off = Optional offset (+1)
 * Returns: WORD
 */
extern (C)
ushort FetchImmWord(uint off = 0) {
	return *cast(ushort*)(cast(ubyte*)MEMORY + EIP + 1 + off);
}
/**
 * Fetch an immediate signed WORD at CS:IP+n+1
 * Params: off = Optional offset (+1)
 * Returns: signed WORD
 */
extern (C)
short FetchImmSWord(uint off = 0) {
	return *cast(short*)(cast(ubyte*)MEMORY + EIP + off + 1);
}

/**
 * Fetch an unsigned byte (ubyte).
 * Params: addr = Memory address
 * Returns: BYTE
 */
extern (C)
pragma(inline, true)
ubyte FetchByte(uint addr) {
	return MEMORY[addr];
}
/**
 * Fetch a signed byte (byte).
 * Returns: Signed BYTE
 */
extern (C)
pragma(inline, true)
byte FetchImmSByte() {
	return cast(byte)MEMORY[EIP + 1];
}

/**
 * Fetch a WORD from memory
 * Params: addr = Memory address
 * Returns: WORD
 */
extern (C)
pragma(inline, true)
ushort FetchWord(uint addr) {
	return *cast(ushort*)(cast(ubyte*)MEMORY + addr);
}
/**
 * Fetch a DWORD from memory
 * Params: addr = Memory address
 * Returns: DWORD
 */
extern (C)
pragma(inline, true)
uint FetchDWord(uint addr) {
	return *cast(uint*)(cast(ubyte*)MEMORY + addr);
}
/**
 * Fetch a signed WORD from memory
 * Params: addr = Memory address
 * Returns: signed WORD
 */
extern (C)
pragma(inline, true)
short FetchSWord(uint addr) {
	return *cast(short*)(cast(ubyte*)MEMORY + addr);
}