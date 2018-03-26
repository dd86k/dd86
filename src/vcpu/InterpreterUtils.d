/*
 * InterpreterUtils.d : Interpreter utilities.
 */

module InterpreterUtils;

import Interpreter;
import Logger;
import core.stdc.string : memcpy;

/**
 * Get effective address from R/M byte, mostly usefull for R/M bits.
 * Takes account of the preferred segment register.
 * Params: rm = R/M BYTE
 * Returns: Effective Address
 */
extern (C)
uint GetEA(ubyte rm) {
	final switch (rm & RM_MOD) { // MOD
	case RM_MOD_00: // MOD 00, Memory Mode, no displacement
		switch (Seg) {
		case SEG_CS:
			debug _debug("MOD_00, GetEA::SEG_CS");
			break;
		case SEG_DS:
			debug _debug("MOD_00, GetEA::SEG_DS");
			break;
		case SEG_ES:
			debug _debug("MOD_00, GetEA::SEG_ES");
			break;
		case SEG_SS:
			debug _debug("MOD_00, GetEA::SEG_SS");
			break;
		default:
			final switch (rm & RM_RM) { // R/M
			case 0:
				debug _debug("EA:0:0");
				return SI + BX;
			case 0b001:
				debug _debug("EA:0:1");
				return DI + BX;
			case 0b010:
				debug _debug("EA:0:2");
				return SI + BP;
			case 0b011:
				debug _debug("EA:0:3");
				return DI + BP;
			case 0b100:
				debug _debug("EA:0:4");
				return SI;
			case 0b101:
				debug _debug("EA:0:5");
				return DI;
			case 0b110:
				debug _debug("EA:0:6");
				return FetchImmWord(1); // DIRECT ADDRESS
			case 0b111:
				debug _debug("EA:0:7");
				return BX;
			}
		}
		break; // MOD 00
	case RM_MOD_01: // MOD 01, Memory Mode, 8-bit displacement follows
		debug _debug("EA:1:_");
		EIP += 1;
		break; // MOD 01
	case RM_MOD_10: // MOD 10, Memory Mode, 16-bit displacement follows
		debug _debug("EA:2:_");
		EIP += 2;
		break; // MOD 10
	case RM_MOD_11: // MOD 11, Register Mode
		debug loghb("EA:3:REG::", rm & RM_REG);
		debug loghb("EA:3:SEG::", Seg);
		final switch (rm & RM_REG) {
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
		}
	}

	return -1; // Temporary until final switch
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
void InsertWord(int op, int addr) { // int promotion ;-)
	*cast(ushort*)(cast(void*)MEMORY + addr) = cast(ushort)op;
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
void InsertString(string data, size_t addr = EIP) {
	memcpy(cast(void*)MEMORY + addr, cast(void*)data, data.length);
}
//TODO: InsertString with char*
/// Insert a wide string in memory.
void InsertW(wstring data, size_t addr = EIP) {
	size_t l = data.length * 2;
	ubyte* bp = cast(ubyte*)MEMORY + addr;
	ubyte* dp = cast(ubyte*)data;
	for (; l; --l) *bp++ = *dp++;
}
//TODO: InsertWString(wstring data, size_t addr = 0) (tip: ushort casting)

/*****************************************************************************
 * Fetch
 *****************************************************************************/

/**
 * Fetch an immediate BYTE at CS:IP+n+1
 * Params: off = Optional offset
 * Returns: BYTE
 */
extern (C)
ubyte FetchImmByte(int off = 0) {
	return MEMORY[EIP + 1 + off];
}
/**
 * Fetch an immediate WORD at CS:IP+n+1
 * Params: off = Optional offset
 * Returns: WORD
 */
extern (C)
ushort FetchImmWord(uint off = 0) {
	return *(cast(ushort*)&MEMORY[EIP + 1 + off]);
}
/**
 * Fetch an immediate signed WORD at CS:IP+n+1
 * Params: off = Optional offset
 * Returns: signed WORD
 */
extern (C)
short FetchImmSWord(uint off = 0) {
	return *(cast(short*)&MEMORY[EIP + off + 1]);
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
 * Returns: signed BYTE
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
ushort FetchWord(uint addr) {
	return *(cast(ushort*)&MEMORY[addr]);
}
/**
 * Fetch a DWORD from memory
 * Params: addr = Memory address
 * Returns: DWORD
 */
extern (C)
uint FetchDWord(uint addr) {
	return *(cast(uint*)&MEMORY[addr]);
}
/**
 * Fetch a signed WORD from memory
 * Params: addr = Memory address
 * Returns: signed WORD
 */
extern (C)
short FetchSWord(uint addr) {
	return *(cast(short*)&MEMORY[addr]);
}