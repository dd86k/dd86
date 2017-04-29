/*
 * InterpreterUtils.d : 
 */

module InterpreterUtils;

import Interpreter;

/*
 * Registers
 */

/**
 * ModR/M byte handing.
 * Params:
 *   rm = ModR/M byte
 */
void SetRegAddressWord(const ubyte rm)
{
    //TODO: Figure out prefered segreg (when prefix override)
    final switch (rm & 0b11_000000)
    {
    case 0, 0b01_000000: // MOD 00
        final switch (rm & 0b111)
        {
        case 0:
            SetRegRMWord(rm, GetAddress(SI, BX));
        break; // R/M 000
        case 0b001_000: 
        break;
        }
    break; // MOD 00, 01
    case 0b10_000000: // MOD 10

    break; // MOD 10
    case 0b11_000000: // MOD 11, Register Mode
        final switch(rm &
    break; // MOD 11
    }
}

/**
 * ModR/M byte handing.
 * Params:
 *   rm = ModR/M byte
 */
void SetRegAddressByte(const ubyte rm)
{

}

/**
 * Get a byte register with the ModR/M byte and its address.
 * Used by SetRegAddressWord.
 * Params:
 *   rm = ModR/M byte
 *   addr = Calculated address
 */
private void SetRegRMWord(const ubyte rm, uint addr)
{
    final switch (rm & 0b111_000)
    {
        case 0:     AX = FetchWord(addr); break;
        case 0b001: CX = FetchWord(addr); break;
        case 0b010: DX = FetchWord(addr); break;
        case 0b011: BX = FetchWord(addr); break;
        case 0b100: SP = FetchWord(addr); break;
        case 0b101: BP = FetchWord(addr); break;
        case 0b110: SI = FetchWord(addr); break;
        case 0b111: DI = FetchWord(addr); break;
    }
}

/**
 * Get a byte register with the ModR/M byte and its address.
 * Used by SetRegAddressByte.
 * Params:
 *   rm = ModR/M byte
 *   addr = Calculated address
 */
private void SetRegRMByte(const ubyte rm, uint addr)
{
    final switch (rm & 0b111_000)
    {
        case 0:     AL = bank[addr]; break;
        case 0b001: CL = bank[addr]; break;
        case 0b010: DL = bank[addr]; break;
        case 0b011: BL = bank[addr]; break;
        case 0b100: AH = bank[addr]; break;
        case 0b101: CH = bank[addr]; break;
        case 0b110: DH = bank[addr]; break;
        case 0b111: BH = bank[addr]; break;
    }
}

/*
 * Memory sets
 */

/// Set an unsigned word in memory.
void SetWord(uint addr, ushort value) {
    version (X86_ANY)
        *(cast(ushort *)&bank[addr]) = value;
    else {
        bank[addr] = value & 0xFF;
        bank[addr + 1] = value >> 8 & 0xFF;
    }
}

/*
 * Insert
 */

/// Directly overwrite instructions at CS:IP.
void Insert(ubyte[] ops, size_t offset = 0)
{
    size_t i = GetIPAddress + offset;
    foreach(b; ops) bank[i++] = b;
}

/// Insert number at CS:IP.
void InsertImm(uint op, size_t addr = 1)
{
    ubyte* bankp = cast(ubyte*)&op;
    addr += GetIPAddress;
    bank[addr] = *bankp;
    if (op > 0xFF) {
        bank[++addr] = *++bankp;
        if (op > 0xFFFF) {
            bank[++addr] = *++bankp;
            if (op > 0xFFFFFF)
                bank[++addr] = *++bankp;
        }
    }
}
/// Insert a number in memory.
void Insert(int op, size_t addr)
{
    ubyte* bankp = cast(ubyte*)&op;
    bank[addr] = *bankp;
    if (op > 0xFF) {
        bank[++addr] = *++bankp;
        if (op > 0xFFFF) {
            bank[++addr] = *++bankp;
            if (op > 0xFFFFFF)
                bank[++addr] = *++bankp;
        }
    }
}
/// Insert a string in memory.
void Insert(string data, size_t addr = 0)
{
    if (addr == 0) addr = GetIPAddress;
    foreach(b; data) bank[addr++] = b;
}
/// Insert a wide string in memory.
void InsertW(wstring data, size_t addr = 0)
{
    if (addr == 0) addr = GetIPAddress;
    size_t l = data.length * 2;
    ubyte* bp = &bank[addr], dp = cast(ubyte*)&data[0];
    for (; l; --l) *bp++ = *dp++;
}

/*
 * Fetch
 */

ubyte FetchImmByte() {
    return bank[GetIPAddress + 1];
}
/// Fetch an immediate unsigned byte (ubyte) with offset.
ubyte FetchImmByte(int offset) {
    return bank[GetIPAddress + offset + 1];
}
/// Fetch an unsigned byte (ubyte).
ubyte FetchByte(uint addr) {
    return bank[addr];
}
/// Fetch an immediate byte (byte).
byte FetchImmSByte() {
    return cast(byte)bank[GetIPAddress + 1];
}

/// Fetch an immediate unsigned word (ushort).
ushort FetchWord() {
    version (X86_ANY)
        return *(cast(ushort*)&bank[GetIPAddress + 1]);
    else {
        const uint addr = GetIPAddress + 1;
        return cast(ushort)(bank[addr] | bank[addr + 1] << 8);
    }
}
/// Fetch an unsigned word (ushort).
ushort FetchWord(uint addr) {
    version (X86_ANY)
        return *(cast(ushort*)&bank[addr]);
    else
        return cast(ushort)(bank[addr] | bank[addr + 1] << 8);
}
/// Fetch an immediate unsigned word with optional offset.
ushort FetchImmWord(uint offset = 0) {
    version (X86_ANY)
        return *(cast(ushort*)&bank[GetIPAddress + offset + 1]);
    else {
        const uint l = GetIPAddress + offset + 1;
        return cast(ushort)(bank[l] | bank[l + 1] << 8);
    }
}
/// Fetch an immediate word (short).
short FetchSWord(uint addr) {
    version (X86_ANY)
        return *(cast(short*)&bank[addr]);
    else {
        if (addr == 0) addr = GetIPAddress + 1;
        return cast(short)(bank[addr] | bank[addr + 1] << 8);
    }
}
short FetchImmSWord(uint offset = 0) {
    version (X86_ANY)
        return *(cast(short*)&bank[GetIPAddress + offset + 1]);
    else {
        const uint addr = GetIPAddress + offset + 1;
        return cast(short)(bank[addr] | bank[addr + 1] << 8);
    }
}