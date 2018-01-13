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
		debug _debug("EA:3:_");
		/*final switch (rm & 0b111_000) {
		case 0: 
			switch (Seg) {
			case SEG_CS: return GetAddress(CS, AX);
			case SEG_DS: return GetAddress(DS, AX);
			default: return AX;
			}
			break;
		case 0b00_1000:  break;
		case 0b01_0000:  break;
		case 0b01_1000:  break;
		case 0b10_0000:  break;
		case 0b10_1000:  break;
		case 0b11_0000:  break;
		case 0b11_1000:  break;
		}*/
		break; // MOD 11
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
 * Insert a string in memory.
 * Params:
 *   data = String value
 *   addr = Memory address, default being CS:IP
 */
void InsertString(string data, size_t addr = 0) {
	if (addr == 0) addr = GetIPAddress;
	foreach(b; data) MEMORY[addr++] = b;
}
//TODO: InsertString with char*
/// Insert a wide string in memory.
void InsertW(wstring data, size_t addr = 0) {
	if (addr == 0)
		addr = GetIPAddress;
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
	return MEMORY[GetIPAddress + off + 1];
}
/**
 * Fetch an unsigned byte (ubyte).
 * Params: addr = Memory address
 * Returns: BYTE
 */
extern (C)
ubyte FetchByte(uint addr) {
	return MEMORY[addr];
}
/// Fetch an immediate byte (byte).
extern (C)
byte FetchImmSByte() {
	return cast(byte)MEMORY[GetIPAddress + 1];
}

/// Fetch a WORD from memory
extern (C)
ushort FetchWord(uint addr) {
	version (X86_ANY)
		return *(cast(ushort*)&MEMORY[addr]);
	else
		return cast(ushort)(MEMORY[addr] | MEMORY[addr + 1] << 8);
}
/// Fetch a DWORD from memory
extern (C)
uint FetchDWord(uint addr) {
	version (X86_ANY)
		return *(cast(uint*)&MEMORY[addr]);
	else
		return cast(uint)(MEMORY[addr] | MEMORY[addr + 1] << 8);
}
/// Fetch an immediate unsigned word with optional offset.
extern (C)
ushort FetchImmWord(uint offset = 0) {
	version (X86_ANY)
		return *(cast(ushort*)&MEMORY[GetIPAddress + offset + 1]);
	else {
		const uint l = GetIPAddress + offset + 1;
		return cast(ushort)(MEMORY[l] | MEMORY[l + 1] << 8);
	}
}
/// Fetch an immediate word (short).
extern (C)
short FetchSWord(uint addr) {
	version (X86_ANY)
		return *(cast(short*)&MEMORY[addr]);
	else {
		if (addr == 0) addr = GetIPAddress + 1;
		return cast(short)(MEMORY[addr] | MEMORY[addr + 1] << 8);
	}
}
extern (C)
short FetchImmSWord(uint offset = 0) {
	version (X86_ANY)
		return *(cast(short*)&MEMORY[GetIPAddress + offset + 1]);
	else {
		const uint addr = GetIPAddress + offset + 1;
		return cast(short)(MEMORY[addr] | MEMORY[addr + 1] << 8);
	}
}