/*
 * InterpreterUtils.d : Interpreter utilities.
 */

module InterpreterUtils;

import Interpreter;

/*
 * Registers
 */
extern (C)
void HandleRMByte(const ubyte rm)
{

}

/**
 * ModR/M byte handing.
 * Params:
 *   rm = ModR/M byte
 *   direction = If Direction bit is set (acts like an int)
 */
extern (C)
void HandleRMWord(const ubyte rm, const int direction)
{
    //TODO: Figure out prefered segreg (when prefix override)
    final switch (rm & 0b11_000000)
    {
    case 0: // MOD 00, Memory Mode, no displacement
        final switch (rm & 0b111_000)
        {
        case 0:
            SetRegRMWord(rm, GetAddress(SI, BX));
            break;
        case 0b001_000:

            break;
        }
        break; // MOD 00
    case 0b01_000000: // MOD 01, Memory Mode, 8-bit displacement

        EIP += 1;
        break; // MOD 01
    case 0b10_000000: // MOD 10, Memory Mode, 16-bit displacement

        EIP += 2;
        break; // MOD 10
    case 0b11_000000: // MOD 11, Register Mode
        if (direction)
            final switch (rm & 0b111_000)
            {
            case 0: AX = getRMRegWord(rm); break;
            case 0b001_000: CX = getRMRegWord(rm); break;
            case 0b010_000: DX = getRMRegWord(rm); break;
            case 0b011_000: BX = getRMRegWord(rm); break;
            case 0b100_000: SP = getRMRegWord(rm); break;
            case 0b101_000: BP = getRMRegWord(rm); break;
            case 0b110_000: SI = getRMRegWord(rm); break;
            case 0b111_000: DI = getRMRegWord(rm); break;
            }
        else // NO DIRECTION
            final switch (rm & 0b111_000)
            {
            case 0: setRMRegWord(rm, AX); break;
            case 0b001_000: setRMRegWord(rm, CX); break;
            case 0b010_000: setRMRegWord(rm, DX); break;
            case 0b011_000: setRMRegWord(rm, BX); break;
            case 0b100_000: setRMRegWord(rm, SP); break;
            case 0b101_000: setRMRegWord(rm, BP); break;
            case 0b110_000: setRMRegWord(rm, SI); break;
            case 0b111_000: setRMRegWord(rm, DI); break;
            }
        break; // MOD 11
    }
}

extern (C)
private ushort getRMRegWord(const ubyte rm)
{
    final switch (rm & 0b111)
    {
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

extern (C)
private void setRMRegWord(const ubyte rm, const ushort v)
{
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

/**
 * Get a byte register with the ModR/M byte and its address.
 * Used by SetRegAddressWord.
 * Params:
 *   rm = ModR/M byte
 *   addr = Calculated address
 */
extern (C)
private void SetRegRMWord(const ubyte rm, const uint addr)
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
extern (C)
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

/**
 * Set an unsigned word in memory.
 * Params:
 *   addr = Physical address.
 *   value = WORD v alue.
 */
extern (C)
void SetWord(uint addr, ushort value) {
    *(cast(ushort *)&bank[addr]) = value;
}
extern (C)
void SetDWord(uint addr, uint value) {
    *(cast(uint *)&bank[addr]) = value;
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
extern (C)
void InsertImm(uint op, size_t addr = 1)
{
    //TODO: Maybe re-write this part
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
extern (C)
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
deprecated void InsertW(wstring data, size_t addr = 0)
{
    if (addr == 0)
        addr = GetIPAddress;
    size_t l = data.length * 2;
    ubyte* bp = cast(ubyte*)bank + addr;
    ubyte* dp = cast(ubyte*)data;
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
extern (C)
ubyte FetchByte(uint addr) {
    return bank[addr];
}
/// Fetch an immediate byte (byte).
extern (C)
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
extern (C)
ushort FetchImmWord(uint offset = 0) {
    version (X86_ANY)
        return *(cast(ushort*)&bank[GetIPAddress + offset + 1]);
    else {
        const uint l = GetIPAddress + offset + 1;
        return cast(ushort)(bank[l] | bank[l + 1] << 8);
    }
}
/// Fetch an immediate word (short).
extern (C)
short FetchSWord(uint addr) {
    version (X86_ANY)
        return *(cast(short*)&bank[addr]);
    else {
        if (addr == 0) addr = GetIPAddress + 1;
        return cast(short)(bank[addr] | bank[addr + 1] << 8);
    }
}
extern (C)
short FetchImmSWord(uint offset = 0) {
    version (X86_ANY)
        return *(cast(short*)&bank[GetIPAddress + offset + 1]);
    else {
        const uint addr = GetIPAddress + offset + 1;
        return cast(short)(bank[addr] | bank[addr + 1] << 8);
    }
}