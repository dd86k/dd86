/*
 * InterpreterUtils.d : Interpreter utilities.
 */

module InterpreterUtils;

import Interpreter;
import Logger;
import core.stdc.string : memcpy;

/**
 * Get (calculated) effective address, mostly usefull for R/M bits.
 * Takes account of the preferred segment register.
 * Params: rm = R/M BYTE
 * Returns: Effective Address
 */
uint GetEA(ubyte rm) {
	final switch (rm & 0b1100_0000) { // MOD
	case 0: // MOD 00, Memory Mode, no displacement
		switch (Seg) {
		/*case SEG_CS:
		case SEG_DS:
		case SEG_ES:
		case SEG_SS:*/
		default:
			final switch (rm & 0b111) { // R/M
			case 0:
				debug log("EA:0:0", Log.Debug);
				return SI + BX;
			case 0b001:
				debug log("EA:0:1", Log.Debug);
				return DI + BX;
			case 0b010:
				debug log("EA:0:2", Log.Debug);
				return SI + BP;
			case 0b011:
				debug log("EA:0:3", Log.Debug);
				return DI + BP;
			case 0b100:
				debug log("EA:0:4", Log.Debug);
				return SI;
			case 0b101:
				debug log("EA:0:5", Log.Debug);
				return DI;
			case 0b110:
				debug log("EA:0:6", Log.Debug);
				return FetchImmWord(1); // DIRECT ADDRESS
			case 0b111:
				debug log("EA:0:7", Log.Debug);
				return BX;
			}
		} // MOD 00
	case 0b0100_0000: // MOD 01, Memory Mode, 8-bit displacement follows
		log("EA:1:_", Log.Debug);
		EIP += 1;
		break; // MOD 01
	case 0b1000_0000: // MOD 10, Memory Mode, 16-bit displacement follows
		log("EA:2:_", Log.Debug);
		EIP += 2;
		break; // MOD 10
	case 0b1100_0000: // MOD 11, Register Mode
		log("EA:3:_", Log.Debug);
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

	return -1; // Temporary
}

extern (C) private
deprecated ushort getRMRegWord(const ubyte rm) {
	final switch (rm & 0b111) {
	case 0: return AX;
	case 1: return CX;
	case 2: return DX;
	case 3: return BX;
	case 4: return SP;
	case 5: return BP;
	case 6: return SI;
	case 7: return DI;
	}
}

extern (C) private
deprecated void setRMRegWord(const ubyte rm, const ushort v) {
	final switch (rm & 0b111) {
	case 0: AX = v; break;
	case 1: CX = v; break;
	case 2: DX = v; break;
	case 3: BX = v; break;
	case 4: SP = v; break;
	case 5: BP = v; break;
	case 6: SI = v; break;
	case 7: DI = v; break;
	}
}

/*
 * Memory sets
 */

/**
 * Set an unsigned word in memory.
 * Params:
 *   addr = Physical address.
 *   value = WORD v alue.
 */
extern (C)
void SetWord(uint addr, int value) {
	*(cast(ushort*)&MEMORY[addr]) = cast(ushort)value;
}
extern (C)
void SetDWord(uint addr, uint value) {
	*(cast(uint*)&MEMORY[addr]) = value;
}

/*
 * Insert
 */

/// Directly overwrite instructions at CS:IP.
void Insert(ubyte[] ops, size_t offset = 0) {
	size_t i = GetIPAddress + offset;
	foreach(b; ops) MEMORY[i++] = b;
}
/// Directly overwrite instructions at CS:IP.
void Insert(void* ops, size_t size, size_t offset = 0) {
	memcpy(cast(void*)MEMORY + GetIPAddress + offset, ops, size);
}

/// Insert number at CS:IP.
extern (C)
void InsertImm(uint op, size_t addr = 1)
{
	//TODO: Maybe re-write this part
	ubyte* bankp = cast(ubyte*)&op;
	addr += GetIPAddress;
	MEMORY[addr] = *bankp;
	if (op > 0xFF) {
		MEMORY[++addr] = *++bankp;
		if (op > 0xFFFF) {
			MEMORY[++addr] = *++bankp;
			if (op > 0xFFFFFF)
				MEMORY[++addr] = *++bankp;
		}
	}
}

/// Insert a number in memory.
extern (C)
void Insert(int op, size_t addr)
{
	ubyte* bankp = cast(ubyte*)&op;
	MEMORY[addr] = *bankp;
	if (op > 0xFF) {
		MEMORY[++addr] = *++bankp;
		if (op > 0xFFFF) {
			MEMORY[++addr] = *++bankp;
			if (op > 0xFFFFFF)
				MEMORY[++addr] = *++bankp;
		}
	}
}
/// Insert a string in memory.
void Insert(string data, size_t addr = 0)
{
	if (addr == 0) addr = GetIPAddress;
	foreach(b; data) MEMORY[addr++] = b;
}
/// Insert a wide string in memory.
void InsertW(wstring data, size_t addr = 0)
{
	if (addr == 0)
		addr = GetIPAddress;
	size_t l = data.length * 2;
	ubyte* bp = cast(ubyte*)MEMORY + addr;
	ubyte* dp = cast(ubyte*)data;
	for (; l; --l) *bp++ = *dp++;
}

/*
 * Fetch
 */

ubyte FetchImmByte() {
	return MEMORY[GetIPAddress + 1];
}
/// Fetch an immediate unsigned byte (ubyte) with offset.
ubyte FetchImmByte(int offset) {
	return MEMORY[GetIPAddress + offset + 1];
}
/// Fetch an unsigned byte (ubyte).
extern (C)
ubyte FetchByte(uint addr) {
	return MEMORY[addr];
}
/// Fetch an immediate byte (byte).
extern (C)
byte FetchImmSByte() {
	return cast(byte)MEMORY[GetIPAddress + 1];
}

/// Fetch an immediate unsigned word (ushort).
ushort FetchWord() {
	version (X86_ANY)
		return *(cast(ushort*)&MEMORY[GetIPAddress + 1]);
	else {
		const uint addr = GetIPAddress + 1;
		return cast(ushort)(MEMORY[addr] | MEMORY[addr + 1] << 8);
	}
}
/// Fetch an unsigned word (ushort).
ushort FetchWord(uint addr) {
	version (X86_ANY)
		return *(cast(ushort*)&MEMORY[addr]);
	else
		return cast(ushort)(MEMORY[addr] | MEMORY[addr + 1] << 8);
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