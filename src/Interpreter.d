/*
 * Interpreter.d: Legacy machine code interpreter. An Intel i486/8086 hybrid.
 */

module Interpreter;

import dd_dos, std.stdio;
import InterpreterUtils, Logger;
import core.thread : Thread;
import core.time : hnsecs, nsecs;

/// Initial amount of memory.
enum MAX_MEM = 0x10_0000; // 1 MB

/// Sleep for n hecto-nanoseconds
pragma(inline, true) void HSLEEP(int n) {
    Thread.sleep(hnsecs(n));
}

/// Sleep for n nanoseconds
pragma(inline, true) void NSLEEP(int n) {
    Thread.sleep(nsecs(n));
}

/// Initiate machine (memory, etc.)
void Initiate()
{
    bank = new ubyte[MAX_MEM]; CS = 0xFFFF;

    AXp = cast(ushort*)&EAX;
    BXp = cast(ushort*)&EBX;
    CXp = cast(ushort*)&ECX;
    DXp = cast(ushort*)&EDX;

    SIp = cast(ushort*)&ESI;
    DIp = cast(ushort*)&EDI;
    BPp = cast(ushort*)&EBP;
    SPp = cast(ushort*)&ESP;

    ALp = cast(ubyte*)AXp;
    BLp = cast(ubyte*)BXp;
    CLp = cast(ubyte*)CXp;
    DLp = cast(ubyte*)DXp;
}

/// Start!
void Run()
{
    if (Verbose) log("Running...");

    while (Running)
    {
        Execute(bank[GetIPAddress]);
        if (Sleep) HSLEEP( 2 ); // Intel 8086 - 5 MHz
    }
}

/// Is sleeping vcpu between cycles?
bool Sleep = true;
/// Is currently running?
bool Running = true;
/// Is verbose?
bool Verbose;

/// Main memory brank;
ubyte[] bank;

/**
 * Get memory address out of a segment and a register value.
 * Params:
 *   segment = Segment register value
 *   offset  = Generic register value
 * Returns: SEG:ADDR Location
 */
uint GetAddress(int segment, int offset)
{
    return (segment << 4) + offset;
}
/**
 * Get next instruction location
 * Returns: CS:IP address
 */
uint GetIPAddress()
{
    return GetAddress(CS, IP);
}

/// RESET instruction function
void Reset()
{
    OF = DF = IF = TF = SF =
        ZF = AF = PF = CF = false;
    CS = 0xFFFF;
    IP = DS = SS = ES = 0;
    // Empty Queue Bus
}

/// Resets the entire vCPU, does not refer to the instruction.
void FullReset()
{
    Reset();
    EAX = EBX = ECX = EDX =
        EBP = ESP = EDI = ESI = 0;
}

/// Generic register
uint EAX, EBX, ECX, EDX;
ubyte* ALp, BLp, CLp, DLp;
ushort* AXp, BXp, CXp, DXp;

/*
 * Register properties, includes sanity check.
 * Getters and setters, respectively.
 */

/// Get AX
/// Returns: WORD
@property ushort AX() { return *AXp; }
/// Get AH
/// Returns: BYTE
@property ubyte  AH() { return *(ALp + 1); }
/// Get AL
/// Returns: BYTE
@property ubyte  AL() { return *ALp; }
/// Set AX
/// Params: v = WORD
@property void   AX(int v) { *AXp = v & 0xFFFF; }
/// Set AH
/// Params: v = BYTE
@property void   AH(int v) { *(ALp + 1) = v & 0xFF; }
/// Set AL
/// Params: v = BYTE
@property void   AL(int v) { *ALp = v & 0xFF; }

/// Get BX
/// Returns: WORD
@property ushort BX() { return *BXp; }
/// Get BH
/// Returns: BYTE
@property ubyte  BH() { return *(BLp + 1); }
/// Get BL
/// Returns: BYTE
@property ubyte  BL() { return *BLp; }
/// Set BX
/// Params: v = WORD
@property void   BX(int v) { *BXp = v & 0xFFFF; }
/// Set BH
/// Params: v = BYTE
@property void   BH(int v) { *(BLp + 1) = v & 0xFF; }
/// Set BL
/// Params: v = BYTE
@property void   BL(int v) { *BLp = v & 0xFF; }

/// Get CX
/// Returns: WORD
@property ushort CX() { return *CXp; }
/// Get CH
/// Returns: BYTE
@property ubyte  CH() { return *(CLp + 1); }
/// Get CL
/// Returns: BYTE
@property ubyte  CL() { return *CLp; }
/// Set CX
/// Params: v = WORD
@property void   CX(int v) { *CXp = v & 0xFFFF; }
/// Set CH
/// Params: v = BYTE
@property void   CH(int v) { *(CLp + 1) = v & 0xFF; }
/// Set CL
/// Params: v = BYTE
@property void   CL(int v) { *CLp = v & 0xFF; }

/// Get DX
/// Returns: WORD
@property ushort DX() { return *DXp; }
/// Get DH
/// Returns: BYTE
@property ubyte  DH() { return *(DLp + 1); }
/// Get CL
/// Returns: BYTE
@property ubyte  DL() { return *DLp; }
/// Set DX
/// Params: v = WORD
@property void   DX(int v) { *DXp = v & 0xFFFF; }
/// Set DH
/// Params: v = BYTE
@property void   DH(int v) { *(DLp + 1) = v & 0xFF; }
/// Set DL
/// Params: v = BYTE
@property void   DL(int v) { *DLp = v & 0xFF; }

/// Index register
uint ESI, EDI, EBP, ESP;
/// Index register pointer
ushort* SIp, DIp, BPp, SPp;

@property ushort SI() { return *SIp; }
@property ushort DI() { return *DIp; }
@property ushort BP() { return *BPp; }
@property ushort SP() { return *SPp; }
@property void SI(int v) { *SIp = v & 0xFFFF; }
@property void DI(int v) { *DIp = v & 0xFFFF; }
@property void BP(int v) { *BPp = v & 0xFFFF; }
@property void SP(int v) { *SPp = v & 0xFFFF; }

/// Segment register
ushort CS, SS, DS, ES,
// Post-i386
       FS, GS;

/// Program Counter
//uint EIP;
ushort IP;
//@property ushort IP() { return EIP & 0xFFFF; }
//@property void IP(int v) { EIP |= v & 0xFFFF; }

/*
 * FLAGS
 */

/// Flag mask
private enum {
    MASK_CF = 1,
    MASK_PF = 4,
    MASK_AF = 0x10,
    MASK_ZF = 0x40,
    MASK_SF = 0x80,
    MASK_TF = 0x100,
    MASK_IF = 0x200,
    MASK_DF = 0x400,
    MASK_OF = 0x800,
    // i386

}

bool OF, /// Bit 11, Overflow Flag
     DF, /// Bit 10, Direction Flag
     IF, /// Bit  9, Interrupt Enable Flag
     TF, /// Bit  8, Trap Flag
     SF, /// Bit  7, Sign Flag
     ZF, /// Bit  6, Zero Flag
     AF, /// Bit  4, Auxiliary Carry Flag (aka Adjust Flag)
     PF, /// Bit  2, Parity Flag
     CF; /// Bit  0, Carry Flag

/**
 * Push value into memory.
 * Params:
 *   value = WORD value to PUSH
 */
void Push(ushort value)
{
    SP = SP - 2;
    SetWord(GetAddress(SS, SP), value);
}
/**
 * Pop value from memory.
 * Returns: POP'd WORD value
 */
ushort Pop()
{
    const uint addr = GetAddress(SS, SP);
    SP = SP + 2;
    return FetchWord(addr);
}

/**
 * Get FLAG as WORD.
 * Returns: FLAG as byte
 */
@property ubyte FLAGB()
{
    ubyte b;
    if (SF) b |= MASK_SF;
    if (ZF) b |= MASK_ZF;
    if (AF) b |= MASK_AF;
    if (PF) b |= MASK_PF;
    if (CF) b |= MASK_CF;
    return b;
}

/// Set FLAG as BYTE.
@property void FLAGB(ubyte flag)
{
    SF = (flag & MASK_SF) != 0;
    ZF = (flag & MASK_ZF) != 0;
    AF = (flag & MASK_AF) != 0;
    PF = (flag & MASK_PF) != 0;
    CF = (flag & MASK_CF) != 0;
}

/**
 * Get FLAG as WORD.
 * Returns: FLAG (WORD)
 */
@property ushort FLAG()
{
    ushort b = FLAGB;
    if (OF) b |= MASK_OF;
    if (DF) b |= MASK_DF;
    if (IF) b |= MASK_IF;
    if (TF) b |= MASK_TF;
    return b;
}

/// Set FLAG as WORD.
@property void FLAG(ushort flag)
{
    OF = (flag & MASK_OF) != 0;
    DF = (flag & MASK_DF) != 0;
    IF = (flag & MASK_IF) != 0;
    TF = (flag & MASK_TF) != 0;
    FLAGB = flag & 0xFF;
}

// Rest of the source here is solely this function.
/**
 * Execute an operation code, acts like the ALU from an Intel 8086.
 * Params:
 *   op = Operation Code
 */
void Execute(ubyte op) // All instructions are 1-byte for the 8086.
{
    //TODO: Seg (uint)
    //      Seg will be used to get the default or segment overload prefix.
    // Usage:
    //      Default: Seg = DS (for ModR/M example)
    //      Prefix : Seg = CS (for CS: example)
    // Then the next instruction will use Seg (with GetAddress)
    // There are a few instructions (opcodes) affected by this:
    // (TODO: get those opcodes too)
    /*
     * Legend:
     * R/M - Mod Register/Memory byte
     * IMM - Immediate value
     * REG - Register
     * MEM - Memory location
     * SEGREG - Segment register
     * 
     * The number represents bitness.
     */
    switch (op) {
    case 0x00: { // ADD R/M8, REG8

        break;
    }
    case 0x01: { // ADD R/M16, REG16

        break;
    }
    case 0x02: { // ADD REG8, R/M8

        break;
    }
    case 0x03: { // ADD REG16, R/M16

        break;
    }
    case 0x04: // ADD AL, IMM8
        AL = AL + FetchImmByte;
        IP += 2;
        SF = CF = (AL & 0x80) != 0;
        PF = (AL & 1) != 0;
        AF = (AL & 0x10) != 0;
        ZF = AL == 0;
        //OF = 
        break;
    case 0x05: // ADD AX, IMM16
        AX = AX + FetchWord;
        IP += 2;
        break;
    case 0x06: // PUSH ES
        Push(ES);
        ++IP;
        break;
    case 0x07: // POP ES
        ES = Pop();
        ++IP;
        break;
    case 0x08: { // OR R/M8, REG8

        break;
    }
    case 0x09: { // OR R/M16, REG16

        break;
    }
    case 0x0A: { // OR REG8, R/M8
    
        break;
    }
    case 0x0B: { // OR REG16, R/M16

        break;
    }
    case 0x0C: // OR AL, IMM8
        AL = AL | FetchImmByte;
        IP += 2;
        break;
    case 0x0D: // OR AX, IMM16
        AX = AX | FetchWord;
        IP += 3;
        break;
    case 0x0E: // PUSH CS
        Push(CS);
        ++IP;
        break;
    case 0x10: { // ADC R/M8, REG8

        break;
    }
    case 0x11: { // ADC R/M16, REG16

        break;
    }
    case 0x12: { // ADC REG8, R/M8

        break;
    }
    case 0x13: { // ADC REG16, R/M16

        break;
    }
    case 0x14: { // ADC AL, IMM8
        int t = AL + FetchImmByte;
        if (CF) ++t;
        AL = t;
        IP += 2;
        break;
    }
    case 0x15: { // ADC AX, IMM16
        int t = AX + FetchWord;
        if (CF) ++t;
        AX = t;
        IP += 3;
    }
        break;
    case 0x16: // PUSH SS
        Push(SS);
        ++IP;
        break;
    case 0x17: // POP SS
        SS = Pop();
        ++IP;
        break;
    case 0x18: // SBB R/M8, REG8

        break;
    case 0x19: // SBB R/M16, REG16

        break;
    case 0x1A: // SBB REG8, R/M16

        break;
    case 0x1B: // SBB REG16, R/M16

        break;
    case 0x1C: { // SBB AL, IMM8
        int t = AL - FetchImmByte;
        if (CF) --t;
        AL = t;
        IP += 2;
    }
        break;
    case 0x1D: { // SBB AX, IMM16
        int t = AX - FetchImmByte;
        if (CF) --t;
        AX = t;
        IP += 3;
    }
        break;
    case 0x1E: // PUSH DS
        Push(DS);
        ++IP;
        break;
    case 0x1F: // POP DS
        DS = Pop();
        ++IP;
        break;
    case 0x20: // AND R/M8, REG8

        break;
    case 0x21: // AND R/M16, REG16

        break;
    case 0x22: // AND REG8, R/M8

        break;
    case 0x23: // AND REG16, R/M16

        break;
    case 0x24: // AND AL, IMM8
        AL = AL & FetchImmByte;
        IP += 2;
        break;
    case 0x25: // AND AX, IMM16
        AX = AX & FetchWord;
        IP += 3;
        break;
    case 0x26: // ES: (Segment override prefix)
        // e.g. mov	ax, [es:100h] ; Use ES as the segment

        break;
    case 0x27: { // DAA
        const ubyte oldAL = AL;
        const bool oldCF = CF;
        CF = false;

        if (((oldAL & 0xF) > 9) || AF)
        {
            AL = AL + 6;
            CF = oldCF || (AL & 0x80);
            AF = true;
        }
        else AF = false;

        if ((oldAL > 0x99) || oldCF)
        {
            AL = AL + 0x60;
            CF = true;
        }
        else CF = false;
        ++IP;
    }
        break;
    case 0x28: // SUB R/M8, REG8

        break;
    case 0x29: // SUB R/M16, REG16

        break;
    case 0x2A: // SUB REG8, R/M8
    
        break;
    case 0x2B: // SUB REG16, R/M16

        break;
    case 0x2C: // SUB AL, IMM8
        AL = AL - FetchImmByte;
        IP += 2;
        break;
    case 0x2D: // SUB AX, IMM16
        AX = AX - FetchWord;
        IP += 3;
        break;
    case 0x2E: // CS:
        //TODO: CS:
        ++IP;
        break;
    case 0x2F: { // DAS
        const ubyte oldAL = AL;
        const bool oldCF = CF;
        CF = false;

        if (((oldAL & 0xF) > 9) || AF)
        {
            AL = AL - 6;
            CF = oldCF || (AL & 0b10000000);
            AF = true;
        }
        else AF = false;

        if ((oldAL > 0x99) || oldCF)
        {
            AL = AL - 0x60;
            CF = true;
        }
        else CF = false;
        ++IP;
    }
        break;
    case 0x30: // XOR R/M8, REG8

        break;
    case 0x31: // XOR R/M16, REG16

        break;
    case 0x32: // XOR REG8, R/M8

        break;
    case 0x33: // XOR REG16, R/M16

        break;
    case 0x34: // XOR AL, IMM8
        AL = AL ^ FetchImmByte;
        IP += 2;
        break;
    case 0x35: // XOR AX, IMM16
        AX = AX ^ FetchWord;
        IP += 3;
        break;
    case 0x36: // SS:

        break;
    case 0x37: // AAA
        if (((AL & 0xF) > 9) || AF)
        {
            AX = AX + 0x106;
            AF = CF = true;
        }
        else AF = CF = false;
        AL = AL & 0xF;
        ++IP;
        break;
    case 0x38: // CMP R/M8, REG8

        break;
    case 0x39: // CMP R/M16, REG16

        break;
    case 0x3A: // CMP REG8, R/M8

        break;
    case 0x3B: // CMP REG16, R/M16

        break;
    case 0x3C: // CMP AL, IMM8
        const ubyte b = FetchImmByte;
        const int r = AL - b;
        CF = SF = (r & 0x80) != 0;
        OF = r < 0;
        ZF = r == 0;
        AF = (r & 0x10) != 0; //((AL & 0b1000) - (b & 0b1000)) < 0;
        //PF =
        IP += 2;
        break;
    case 0x3D: // CMP AX, IMM16
        const ushort w = FetchWord;
        const int r = AL - w;
        SF = (r & 0x8000) != 0;
        OF = r < 0;
        ZF = r == 0;
        //AF = 
        //PF =
        //CF =
        IP += 3;
        break;
    case 0x3E: // DS:

        break;
    case 0x3F: // AAS
        if (((AL & 0xF) > 9) || AF)
        {
            AX = AX - 6;
            AH = AH - 1;
            AF = CF = true;
        }
        else
        {
            AF = CF = false;
        }
        AL = AL & 0xF;
        ++IP;
        break;
    case 0x40: { // INC AX
        const int r = AX + 1;
        ZF = r == 0;
        SF = (r & 0x8000) != 0;
        AF = (r & 0x10) != 0;
        //PF =
        //OF =
        AX = r;
        ++IP;
    }
        break;
    case 0x41: // INC CX
        CX = CX + 1;
        ++IP;
        break;
    case 0x42: // INC DX
        DX = DX + 1;
        ++IP;
        break;
    case 0x43: // INC BX
        BX = BX + 1;
        ++IP;
        break;
    case 0x44: // INC SP
        SP = SP + 1;
        ++IP;
        break;
    case 0x45: // INC BP
        BP = BP + 1;
        ++IP;
        break;
    case 0x46: // INC SI
        SI = SI + 1;
        ++IP;
        break;
    case 0x47: // INC DI
        DI = DI + 1;
        ++IP;
        break;
    case 0x48: // DEC AX
        AX = AX - 1;
        ++IP;
        break;
    case 0x49: // DEC CX
        CX = CX - 1;
        ++IP;
        break;
    case 0x4A: // DEC DX
        DX = DX - 1;
        ++IP;
        break;
    case 0x4B: // DEC BX
        BX = BX - 1;
        ++IP;
        break;
    case 0x4C: // DEC SP
        SP = SP - 1;
        ++IP;
        break;
    case 0x4D: // DEC BP
        BP = BP - 1;
        ++IP;
        break;
    case 0x4E: // DEC SI
        SI = SI - 1;
        ++IP;
        break;
    case 0x4F: // DEC DI
        DI = DI - 1;
        ++IP;
        break;
    case 0x50: // PUSH AX
        Push(AX);
        ++IP;
        break;
    case 0x51: // PUSH CX
        Push(CX);
        ++IP;
        break;
    case 0x52: // PUSH DX
        Push(DX);
        ++IP;
        break;
    case 0x53: // PUSH BX
        Push(BX);
        ++IP;
        break;
    case 0x54: // PUSH SP
        Push(SP);
        ++IP;
        break;
    case 0x55: // PUSH BP
        Push(BP);
        ++IP;
        break;
    case 0x56: // PUSH SI
        Push(SI);
        ++IP;
        break;
    case 0x57: // PUSH DI
        Push(DI);
        ++IP;
        break;
    case 0x58: // POP AX
        AX = Pop();
        ++IP;
        break;
    case 0x59: // POP CX
        CX = Pop();
        ++IP;
        break;
    case 0x5A: // POP DX
        DX = Pop();
        ++IP;
        break;
    case 0x5B: // POP BX
        BX = Pop();
        ++IP;
        break;
    case 0x5C: // POP SP
        SP = Pop();
        ++IP;
        break;
    case 0x5D: // POP BP
        BP = Pop();
        ++IP;
        break;
    case 0x5E: // POP SI
        SI = Pop();
        ++IP;
        break;
    case 0x5F: // POP DI
        DI = Pop();
        ++IP;
        break;
    case 0x70: // JO            SHORT-LABEL
        IP += OF ? FetchImmSByte : 2;
        break;
    case 0x71: // JNO           SHORT-LABEL
        IP += OF == false ? FetchImmSByte : 2;
        break;
    case 0x72: // JB/JNAE/JC    SHORT-LABEL
        IP += CF ? FetchImmSByte : 2;
        break;
    case 0x73: // JNB/JAE/JNC   SHORT-LABEL
        IP += CF == false ? FetchImmSByte : 2;
        break;
    case 0x74: // JE/JZ         SHORT-LABEL
        IP += ZF ? FetchImmSByte : 2;
        break;
    case 0x75: // JNE/JNZ       SHORT-LABEL
        IP += ZF == false ? FetchImmSByte : 2;
        break;
    case 0x76: // JBE/JNA       SHORT-LABEL
        IP += (CF || ZF) ? FetchImmSByte : 2;
        break;
    case 0x77: // JNBE/JA       SHORT-LABEL
        IP += CF == false && ZF == false ? FetchImmSByte : 2;
        break;
    case 0x78: // JS            SHORT-LABEL
        IP += SF ? FetchImmSByte : 2;
        break;
    case 0x79: // JNS           SHORT-LABEL
        IP += SF == false ? FetchImmSByte : 2;
        break;
    case 0x7A: // JP/JPE        SHORT-LABEL
        IP += PF ? FetchImmSByte : 2;
        break;
    case 0x7B: // JNP/JPO       SHORT-LABEL
        IP += PF == false ? FetchImmSByte : 2;
        break;
    case 0x7C: // JL/JNGE       SHORT-LABEL
        IP += SF != OF ? FetchImmSByte : 2;
        break;
    case 0x7D: // JNL/JGE       SHORT-LABEL
        IP += SF == OF ? FetchImmSByte : 2;
        break;
    case 0x7E: // JLE/JNG       SHORT-LABEL
        IP += SF != OF || ZF ? FetchImmSByte : 2;
        break;
    case 0x7F: // JNLE/JG       SHORT-LABEL
        IP += SF == OF && ZF == false ? FetchImmSByte : 2;
        break;
    case 0x80: { // GRP1 R/M8, IMM8
        const ubyte rm = FetchImmByte; // Get ModR/M byte
        const ubyte im = FetchImmByte(2); // 8-bit Immediate
        final switch (rm & 0b11_000000) {
            case 0: // No displacement
                final switch (rm & 0b111_000) { // REG
                case 0: // 000 - ADD
                    final switch (rm & 0b111)
                    {
                    case 0:
                        AL = AL + im;
                        break;
                    case 0b001:
                        CL = CL + im;
                        break;
                    case 0b010:
                        DL = DL + im;
                        break;
                    case 0b011:
                        BL = BL + im;
                        break;
                    case 0b100:
                        AH = AH + im;
                        break;
                    case 0b101:
                        CH = CH + im;
                        break;
                    case 0b110:
                        DH = DH + im;
                        break;
                    case 0b111:
                        BH = BH + im;
                        break;
                    }
                    break;
                case 0b001_000: // 001 - OR

                    break;
                case 0b010_000: // 010 - ADC

                    break;
                case 0b011_000: // 011 - SBB

                    break;
                case 0b100_000: // 100 - AND

                    break;
                case 0b101_000: // 101 - SUB

                    break;
                case 0b110_000: // 110 - XOR

                    break;
                case 0b111_000: // 111 - CMP

                    break;
                }
                break; // case 0
            case 0b01_000000: // 8-bit displacement

                break; // case 01
        }
        IP += 3;
        break;
    }
    case 0x81: { // GRP1 R/M16, IMM16
        const ubyte rm = FetchImmByte;  // Get ModR/M byte
        const ushort im = FetchWord(GetIPAddress + 2); // 16-bit Immediate
        final switch (rm & 0b111_000) { // ModR/M's REG
        case 0: // 000 - ADD

            break;
        case 0b001_000: // 001 - OR

            break;
        case 0b010_000: // 010 - ADC

            break;
        case 0b011_000: // 011 - SBB

            break;
        case 0b100_000: // 100 - AND

            break;
        case 0b101_000: // 101 - SUB

            break;
        case 0b110_000: // 110 - XOR

            break;
        case 0b111_000: // 111 - CMP

            break;
        }
        IP += 4;
        break;
    }
    case 0x82: // GRP2 R/M8, IMM8
        const ubyte rm = FetchImmByte; // Get ModR/M byte
        const ubyte im = FetchByte(GetIPAddress + 2);
        switch (rm & 0b111_000) { // ModRM REG
        case 0b000_000: // 000 - ADD

            break;
        case 0b010_000: // 010 - ADC

            break;
        case 0b011_000: // 011 - SBB

            break;
        case 0b101_000: // 101 - SUB

            break;
        case 0b111_000: // 111 - CMP

            break;
        default:
        
            break;
        }
        IP += 3;
        break;
    case 0x83: // GRP2 R/M16, IMM16
        const ubyte rm = FetchImmByte; // Get ModR/M byte
        const ushort im = FetchWord(GetIPAddress + 2);
        switch (rm & 0b111_000) { // ModRM REG
        case 0b000_000: // 000 - ADD

            break;
        case 0b010_000: // 010 - ADC

            break;
        case 0b011_000: // 011 - SBB

            break;
        case 0b101_000: // 101 - SUB

            break;
        case 0b111_000: // 111 - CMP

            break;
        default:
            
            break;
        }
        IP += 4;
        break;
    case 0x84: // TEST R/M8, REG8

        break;
    case 0x85: // TEST R/M16, REG16

        break;
    case 0x86: // XCHG REG8, R/M8

        break;
    case 0x87: // XCHG REG16, R/M16

        break;
    case 0x88: { // MOV R/M8, REG8

        break;
    }
    case 0x89: { // MOV R/M16, REG16
        const uint addr = GetIPAddress + 2;
        const ubyte rm = FetchImmByte;
        final switch (rm & 0b111) // R/M
        {
        case 0: // BX + SI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AX
                final switch (rm & 0b11000000) // MOD
                {
                case 0: // 00
                    AX = FetchWord(BX + SI);
                    break;
                case 0b01000000: // 01
                    AX = FetchWord(BX + SI + FetchByte(addr));
                    break;
                case 0b10000000: // 10
                    AX = FetchWord(BX + SI + FetchWord(addr));
                    break;
                case 0b11000000: // 11
                    AX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00001000: // CX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CX = FetchWord(BX + SI);
                    break;
                case 0b01000000:
                    CX = FetchWord(BX + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    CX = FetchWord(BX + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    CX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00010000: // DX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DX = FetchWord(BX + SI);
                    break;
                case 0b01000000:
                    DX = FetchWord(BX + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DX = FetchWord(BX + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00011000: // BX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BX = FetchWord(BX + SI);
                    break;
                case 0b01000000:
                    BX = FetchWord(BX + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BX = FetchWord(BX + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00100000: // SP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SP = FetchWord(BX + SI);
                    break;
                case 0b01000000:
                    SP = FetchWord(BX + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SP = FetchWord(BX + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00101000: // BP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BP = FetchWord(BX + SI);
                    break;
                case 0b01000000:
                    BP = FetchWord(BX + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BP = FetchWord(BX + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00110000: // SI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SI = FetchWord(BX + SI);
                    break;
                case 0b01000000:
                    SI = FetchWord(BX + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SI = FetchWord(BX + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00111000: // DI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DI = FetchWord(BX + SI);
                    break;
                case 0b01000000:
                    DI = FetchWord(BX + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DI = FetchWord(BX + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            }
            break; // 000
        case 0b00001000: // BX + DI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AX = FetchWord(BX + DI);
                    break;
                case 0b01000000:
                    AX = FetchWord(BX + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    AX = FetchWord(BX + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    AX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00001000: // CX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CX = FetchWord(BX + DI);
                    break;
                case 0b01000000:
                    CX = FetchWord(BX + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    CX = FetchWord(BX + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    CX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00010000: // DX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DX = FetchWord(BX + DI);
                    break;
                case 0b01000000:
                    DX = FetchWord(BX + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DX = FetchWord(BX + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00011000: // BX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BX = FetchWord(BX + DI);
                    break;
                case 0b01000000:
                    BX = FetchWord(BX + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BX = FetchWord(BX + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00100000: // SP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SP = FetchWord(BX + DI);
                    break;
                case 0b01000000:
                    SP = FetchWord(BX + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SP = FetchWord(BX + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00101000: // BP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BP = FetchWord(BX + DI);
                    break;
                case 0b01000000:
                    BP = FetchWord(BX + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BP = FetchWord(BX + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00110000: // SI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SI = FetchWord(BX + DI);
                    break;
                case 0b01000000:
                    SI = FetchWord(BX + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SI = FetchWord(BX + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00111000: // DI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DI = FetchWord(BX + DI);
                    break;
                case 0b01000000:
                    DI = FetchWord(BX + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DI = FetchWord(BX + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            }
            break; // 001
        case 0b00000010: // BP + SI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AX = FetchWord(BP + SI);
                    break;
                case 0b01000000:
                    AX = FetchWord(BP + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    AX = FetchWord(BP + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    AX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00001000: // CX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CX = FetchWord(BP + SI);
                    break;
                case 0b01000000:
                    CX = FetchWord(BP + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    CX = FetchWord(BP + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    CX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00010000: // DX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DX = FetchWord(BP + SI);
                    break;
                case 0b01000000:
                    DX = FetchWord(BP + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DX = FetchWord(BP + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00011000: // BX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BX = FetchWord(BP + SI);
                    break;
                case 0b01000000:
                    BX = FetchWord(BP + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BX = FetchWord(BP + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00100000: // SP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SP = FetchWord(BP + SI);
                    break;
                case 0b01000000:
                    SP = FetchWord(BP + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SP = FetchWord(BP + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00101000: // BP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BP = FetchWord(BP + SI);
                    break;
                case 0b01000000:
                    BP = FetchWord(BP + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BP = FetchWord(BP + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00110000: // SI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SI = FetchWord(BP + SI);
                    break;
                case 0b01000000:
                    SI = FetchWord(BP + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SI = FetchWord(BP + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00111000: // DI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DI = FetchWord(BP + SI);
                    break;
                case 0b01000000:
                    DI = FetchWord(BP + SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DI = FetchWord(BP + SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            }
            break; // 010
        case 0b00000011: // BP + DI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AX = FetchWord(BP + DI);
                    break;
                case 0b01000000:
                    AX = FetchWord(BP + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    AX = FetchWord(BP + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    AX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00001000: // CX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CX = FetchWord(BP + DI);
                    break;
                case 0b01000000:
                    CX = FetchWord(BP + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    CX = FetchWord(BP + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    CX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00010000: // DX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DX = FetchWord(BP + DI);
                    break;
                case 0b01000000:
                    DX = FetchWord(BP + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DX = FetchWord(BP + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00011000: // BX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BX = FetchWord(BP + DI);
                    break;
                case 0b01000000:
                    BX = FetchWord(BP + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BX = FetchWord(BP + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00100000: // SP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SP = FetchWord(BP + DI);
                    break;
                case 0b01000000:
                    SP = FetchWord(BP + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SP = FetchWord(BP + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00101000: // BP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BP = FetchWord(BP + DI);
                    break;
                case 0b01000000:
                    BP = FetchWord(BP + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BP = FetchWord(BP + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00110000: // SI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SI = FetchWord(BP + DI);
                    break;
                case 0b01000000:
                    SI = FetchWord(BP + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SI = FetchWord(BP + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00111000: // DI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DI = FetchWord(BP + DI);
                    break;
                case 0b01000000:
                    DI = FetchWord(BP + DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DI = FetchWord(BP + DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            }
            break; // 011
        case 0b00000100: // SI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AX = FetchWord(SI);
                    break;
                case 0b01000000:
                    AX = FetchWord(SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    AX = FetchWord(SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    AX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00001000: // CX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CX = FetchWord(SI);
                    break;
                case 0b01000000:
                    CX = FetchWord(SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    CX = FetchWord(SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    CX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00010000: // DX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DX = FetchWord(SI);
                    break;
                case 0b01000000:
                    DX = FetchWord(SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DX = FetchWord(SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00011000: // BX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BX = FetchWord(SI);
                    break;
                case 0b01000000:
                    BX = FetchWord(SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BX = FetchWord(SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00100000: // SP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SP = FetchWord(SI);
                    break;
                case 0b01000000:
                    SP = FetchWord(SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SP = FetchWord(SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00101000: // BP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BP = FetchWord(SI);
                    break;
                case 0b01000000:
                    BP = FetchWord(SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BP = FetchWord(SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00110000: // SI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SI = FetchWord(SI);
                    break;
                case 0b01000000:
                    SI = FetchWord(SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SI = FetchWord(SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00111000: // DI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DI = FetchWord(SI);
                    break;
                case 0b01000000:
                    DI = FetchWord(SI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DI = FetchWord(SI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            }
            break; // 100
        case 0b00000101: // DI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AX = FetchWord(DI);
                    break;
                case 0b01000000:
                    AX = FetchWord(DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    AX = FetchWord(DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    AX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00001000: // CX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CX = FetchWord(DI);
                    break;
                case 0b01000000:
                    CX = FetchWord(DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    CX = FetchWord(DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    CX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00010000: // DX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DX = FetchWord(DI);
                    break;
                case 0b01000000:
                    DX = FetchWord(DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DX = FetchWord(DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00011000: // BX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BX = FetchWord(DI);
                    break;
                case 0b01000000:
                    BX = FetchWord(DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BX = FetchWord(DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00100000: // SP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SP = FetchWord(DI);
                    break;
                case 0b01000000:
                    SP = FetchWord(DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SP = FetchWord(DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00101000: // BP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BP = FetchWord(DI);
                    break;
                case 0b01000000:
                    BP = FetchWord(DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    BP = FetchWord(DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    BP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00110000: // SI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SI = FetchWord(DI);
                    break;
                case 0b01000000:
                    SI = FetchWord(DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    SI = FetchWord(DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    SI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00111000: // DI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DI = FetchWord(DI);
                    break;
                case 0b01000000:
                    DI = FetchWord(DI + FetchByte(addr));
                    break;
                case 0b10000000:
                    DI = FetchWord(DI + FetchWord(addr));
                    break;
                case 0b11000000:
                    DI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            }
            break; // 101
        case 0b00000110: // BP*
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AX = FetchWord(BP); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    AX = FetchWord(BP + FetchByte(addr));
                    break;
                case 0b10000000:
                    AX = FetchWord(BP + FetchWord(addr));
                    break;
                case 0b11000000:
                    AX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00001000: // CX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CX = FetchWord(BP); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    CX = FetchWord(BP + FetchByte(addr));
                    break;
                case 0b10000000:
                    CX = FetchWord(BP + FetchWord(addr));
                    break;
                case 0b11000000:
                    CX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00010000: // DX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DX = FetchWord(BP); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    DX = FetchWord(BP + FetchByte(addr));
                    break;
                case 0b10000000:
                    DX = FetchWord(BP + FetchWord(addr));
                    break;
                case 0b11000000:
                    DX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00011000: // BX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BX = FetchWord(BP); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    BX = FetchWord(BP + FetchByte(addr));
                    break;
                case 0b10000000:
                    BX = FetchWord(BP + FetchWord(addr));
                    break;
                case 0b11000000:
                    BX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00100000: // SP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SP = FetchWord(BP); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SP = FetchWord(BP + FetchByte(addr));
                    break;
                case 0b10000000:
                    SP = FetchWord(BP + FetchWord(addr));
                    break;
                case 0b11000000:
                    SP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00101000: // BP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BP = FetchWord(BP); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    BP = FetchWord(BP + FetchByte(addr));
                    break;
                case 0b10000000:
                    BP = FetchWord(BP + FetchWord(addr));
                    break;
                case 0b11000000:
                    BP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00110000: // SI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SI = FetchWord(BP); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SI = FetchWord(BP + FetchByte(addr));
                    break;
                case 0b10000000:
                    SI = FetchWord(BP + FetchWord(addr));
                    break;
                case 0b11000000:
                    SI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00111000: // DI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DI = FetchWord(BP); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    DI = FetchWord(BP + FetchByte(addr));
                    break;
                case 0b10000000:
                    DI = FetchWord(BP + FetchWord(addr));
                    break;
                case 0b11000000:
                    DI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            }
            break; // 110
        case 0b111: // BX
            final switch (rm & 0b00111000) // REG
            {
            case 0b00000000: // AX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AX = FetchWord(BX);
                    break;
                case 0b01000000:
                    AX = FetchWord(BX + FetchByte(addr));
                    break;
                case 0b10000000:
                    AX = FetchWord(BX + FetchWord(addr));
                    break;
                case 0b11000000:
                    AX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00001000: // CX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CX = FetchWord(BX);
                    break;
                case 0b01000000:
                    CX = FetchWord(BX + FetchByte(addr));
                    break;
                case 0b10000000:
                    CX = FetchWord(BX + FetchWord(addr));
                    break;
                case 0b11000000:
                    CX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00010000: // DX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DX = FetchWord(BX);
                    break;
                case 0b01000000:
                    DX = FetchWord(BX + FetchByte(addr));
                    break;
                case 0b10000000:
                    DX = FetchWord(BX + FetchWord(addr));
                    break;
                case 0b11000000:
                    DX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00011000: // BX
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BX = FetchWord(BX);
                    break;
                case 0b01000000:
                    BX = FetchWord(BX + FetchByte(addr));
                    break;
                case 0b10000000:
                    BX = FetchWord(BX + FetchWord(addr));
                    break;
                case 0b11000000:
                    BX = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00100000: // SP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SP = FetchWord(BX);
                    break;
                case 0b01000000:
                    SP = FetchWord(BX + FetchByte(addr));
                    break;
                case 0b10000000:
                    SP = FetchWord(BX + FetchWord(IP + 2));
                    break;
                case 0b11000000:
                    SP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00101000: // BP
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BP = FetchWord(BX); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    BP = FetchWord(BX + FetchByte(addr));
                    break;
                case 0b10000000:
                    BP = FetchWord(BX + FetchWord(IP + 2));
                    break;
                case 0b11000000:
                    BP = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00110000: // SI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    SI = FetchWord(BX);
                    break;
                case 0b01000000:
                    SI = FetchWord(BX + FetchByte(addr));
                    break;
                case 0b10000000:
                    SI = FetchWord(BX + FetchWord(IP + 2));
                    break;
                case 0b11000000:
                    SI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            case 0b00111000: // DI
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DI = FetchWord(BX); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    DI = FetchWord(BX + FetchByte(addr));
                    break;
                case 0b10000000:
                    DI = FetchWord(BX + FetchWord(IP + 2));
                    break;
                case 0b11000000:
                    DI = FetchWord(FetchByte(addr));
                    break;
                }
                break;
            }
            break; // 111
        }
        break;
    }
    case 0x8A: { // MOV REG8, R/M8
        const uint addr = GetIPAddress + 2;
        const ubyte rm = FetchImmByte;
        final switch (rm & 0b111) // R/M
        {
        case 0: // BX + SI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AL
                final switch (rm & 0b11000000) // MOD
                {
                case 0: // 00
                    AL = bank[BX + SI];
                    break;
                case 0b01000000: // 01
                    AL = bank[BX + SI + FetchByte(addr)];
                    break;
                case 0b10000000: // 10
                    AL = bank[BX + SI + FetchWord(addr)];
                    break;
                case 0b11000000: // 11
                    AL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00001000: // CL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CL = bank[BX + SI];
                    break;
                case 0b01000000:
                    CL = bank[BX + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CL = bank[BX + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00010000: // DL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DL = bank[BX + SI];
                    break;
                case 0b01000000:
                    DL = bank[BX + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DL = bank[BX + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00011000: // BL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BL = bank[BX + SI];
                    break;
                case 0b01000000:
                    BL = bank[BX + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BL = bank[BX + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00100000: // AH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AH = bank[BX + SI];
                    break;
                case 0b01000000:
                    AH = bank[BX + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AH = bank[BX + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00101000: // CH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CH = bank[BX + SI];
                    break;
                case 0b01000000:
                    CH = bank[BX + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CH = bank[BX + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00110000: // DH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DH = bank[BX + SI];
                    break;
                case 0b01000000:
                    DH = bank[BX + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DH = bank[BX + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00111000: // BH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BH = bank[BX + SI];
                    break;
                case 0b01000000:
                    BH = bank[BX + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BH = bank[BX + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BH = bank[FetchByte(addr)];
                    break;
                }
                break;
            }
            break; // 000
        case 0b00001000: // BX + DI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AL = bank[BX + DI];
                    break;
                case 0b01000000:
                    AL = bank[BX + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AL = bank[BX + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00001000: // CL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CL = bank[BX + DI];
                    break;
                case 0b01000000:
                    CL = bank[BX + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CL = bank[BX + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00010000: // DL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DL = bank[BX + DI];
                    break;
                case 0b01000000:
                    DL = bank[BX + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DL = bank[BX + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00011000: // BL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BL = bank[BX + DI];
                    break;
                case 0b01000000:
                    BL = bank[BX + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BL = bank[BX + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00100000: // AH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AH = bank[BX + DI];
                    break;
                case 0b01000000:
                    AH = bank[BX + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AH = bank[BX + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00101000: // CH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CH = bank[BX + DI];
                    break;
                case 0b01000000:
                    CH = bank[BX + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CH = bank[BX + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00110000: // DH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DH = bank[BX + DI];
                    break;
                case 0b01000000:
                    DH = bank[BX + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DH = bank[BX + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00111000: // BH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BH = bank[BX + DI];
                    break;
                case 0b01000000:
                    BH = bank[BX + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BH = bank[BX + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BH = bank[FetchByte(addr)];
                    break;
                }
                break;
            }
            break; // 001
        case 0b00000010: // BP + SI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AL = bank[BP + SI];
                    break;
                case 0b01000000:
                    AL = bank[BP + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AL = bank[BP + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00001000: // CL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CL = bank[BP + SI];
                    break;
                case 0b01000000:
                    CL = bank[BP + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CL = bank[BP + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00010000: // DL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DL = bank[BP + SI];
                    break;
                case 0b01000000:
                    DL = bank[BP + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DL = bank[BP + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00011000: // BL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BL = bank[BP + SI];
                    break;
                case 0b01000000:
                    BL = bank[BP + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BL = bank[BP + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00100000: // AH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AH = bank[BP + SI];
                    break;
                case 0b01000000:
                    AH = bank[BP + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AH = bank[BP + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00101000: // CH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CH = bank[BP + SI];
                    break;
                case 0b01000000:
                    CH = bank[BP + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CH = bank[BP + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00110000: // DH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DH = bank[BP + SI];
                    break;
                case 0b01000000:
                    DH = bank[BP + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DH = bank[BP + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00111000: // BH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BH = bank[BP + SI];
                    break;
                case 0b01000000:
                    BH = bank[BP + SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BH = bank[BP + SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BH = bank[FetchByte(addr)];
                    break;
                }
                break;
            }
            break; // 010
        case 0b00000011: // BP + DI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AL = bank[BP + DI];
                    break;
                case 0b01000000:
                    AL = bank[BP + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AL = bank[BP + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00001000: // CL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CL = bank[BP + DI];
                    break;
                case 0b01000000:
                    CL = bank[BP + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CL = bank[BP + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00010000: // DL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DL = bank[BP + DI];
                    break;
                case 0b01000000:
                    DL = bank[BP + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DL = bank[BP + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00011000: // BL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BL = bank[BP + DI];
                    break;
                case 0b01000000:
                    BL = bank[BP + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BL = bank[BP + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00100000: // AH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AH = bank[BP + DI];
                    break;
                case 0b01000000:
                    AH = bank[BP + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AH = bank[BP + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00101000: // CH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CH = bank[BP + DI];
                    break;
                case 0b01000000:
                    CH = bank[BP + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CH = bank[BP + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00110000: // DH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DH = bank[BP + DI];
                    break;
                case 0b01000000:
                    DH = bank[BP + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DH = bank[BP + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00111000: // BH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BH = bank[BP + DI];
                    break;
                case 0b01000000:
                    BH = bank[BP + DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BH = bank[BP + DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BH = bank[FetchByte(addr)];
                    break;
                }
                break;
            }
            break; // 011
        case 0b00000100: // SI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AL = bank[SI];
                    break;
                case 0b01000000:
                    AL = bank[SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AL = bank[SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00001000: // CL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CL = bank[SI];
                    break;
                case 0b01000000:
                    CL = bank[SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CL = bank[SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00010000: // DL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DL = bank[SI];
                    break;
                case 0b01000000:
                    DL = bank[SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DL = bank[SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00011000: // BL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BL = bank[SI];
                    break;
                case 0b01000000:
                    BL = bank[SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BL = bank[SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00100000: // AH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AH = bank[SI];
                    break;
                case 0b01000000:
                    AH = bank[SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AH = bank[SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00101000: // CH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CH = bank[SI];
                    break;
                case 0b01000000:
                    CH = bank[SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CH = bank[SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00110000: // DH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DH = bank[SI];
                    break;
                case 0b01000000:
                    DH = bank[SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DH = bank[SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00111000: // BH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BH = bank[SI];
                    break;
                case 0b01000000:
                    BH = bank[SI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BH = bank[SI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BH = bank[FetchByte(addr)];
                    break;
                }
                break;
            }
            break; // 100
        case 0b00000101: // DI
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AL = bank[DI];
                    break;
                case 0b01000000:
                    AL = bank[DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AL = bank[DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00001000: // CL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CL = bank[DI];
                    break;
                case 0b01000000:
                    CL = bank[DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CL = bank[DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00010000: // DL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DL = bank[DI];
                    break;
                case 0b01000000:
                    DL = bank[DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DL = bank[DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00011000: // BL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BL = bank[DI];
                    break;
                case 0b01000000:
                    BL = bank[DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BL = bank[DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00100000: // AH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AH = bank[DI];
                    break;
                case 0b01000000:
                    AH = bank[DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AH = bank[DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00101000: // CH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CH = bank[DI];
                    break;
                case 0b01000000:
                    CH = bank[DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CH = bank[DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00110000: // DH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DH = bank[DI];
                    break;
                case 0b01000000:
                    DH = bank[DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DH = bank[DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00111000: // BH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BH = bank[DI];
                    break;
                case 0b01000000:
                    BH = bank[DI + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BH = bank[DI + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BH = bank[FetchByte(addr)];
                    break;
                }
                break;
            }
            break; // 101
        case 0b00000110: // BP*
            final switch (rm & 0b00111000) // REG
            {
            case 0: // AL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AL = bank[BP]; // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    AL = bank[BP + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AL = bank[BP + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00001000: // CL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CL = bank[BP]; // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    CL = bank[BP + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CL = bank[BP + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00010000: // DL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DL = bank[BP]; // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    DL = bank[BP + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DL = bank[BP + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00011000: // BL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BL = bank[BP]; // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    BL = bank[BP + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BL = bank[BP + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00100000: // AH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AH = bank[BP]; // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    AH = bank[BP + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AH = bank[BP + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00101000: // CH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CH = bank[BP]; // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    CH = bank[BP + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CH = bank[BP + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00110000: // DH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DH = bank[BP]; // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    DH = bank[BP + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DH = bank[BP + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00111000: // BH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BH = bank[BP]; // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    BH = bank[BP + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BH = bank[BP + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BH = bank[FetchByte(addr)];
                    break;
                }
                break;
            }
            break; // 110
        case 0b111: // BX
            final switch (rm & 0b00111000) // REG
            {
            case 0b00000000: // AL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AL = bank[BX];
                    break;
                case 0b01000000:
                    AL = bank[BX + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AL = bank[BX + FetchWord(addr)];
                    break;
                case 0b11000000:
                    AL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00001000: // CL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CL = bank[BX];
                    break;
                case 0b01000000:
                    CL = bank[BX + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CL = bank[BX + FetchWord(addr)];
                    break;
                case 0b11000000:
                    CL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00010000: // DL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DL = bank[BX];
                    break;
                case 0b01000000:
                    DL = bank[BX + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DL = bank[BX + FetchWord(addr)];
                    break;
                case 0b11000000:
                    DL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00011000: // BL
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BL = bank[BX];
                    break;
                case 0b01000000:
                    BL = bank[BX + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BL = bank[BX + FetchWord(addr)];
                    break;
                case 0b11000000:
                    BL = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00100000: // AH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    AH = bank[BX];
                    break;
                case 0b01000000:
                    AH = bank[BX + FetchByte(addr)];
                    break;
                case 0b10000000:
                    AH = bank[BX + FetchWord(IP + 2)];
                    break;
                case 0b11000000:
                    AH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00101000: // CH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    CH = bank[BX]; // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    CH = bank[BX + FetchByte(addr)];
                    break;
                case 0b10000000:
                    CH = bank[BX + FetchWord(IP + 2)];
                    break;
                case 0b11000000:
                    CH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00110000: // DH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    DH = bank[BX];
                    break;
                case 0b01000000:
                    DH = bank[BX + FetchByte(addr)];
                    break;
                case 0b10000000:
                    DH = bank[BX + FetchWord(IP + 2)];
                    break;
                case 0b11000000:
                    DH = bank[FetchByte(addr)];
                    break;
                }
                break;
            case 0b00111000: // BH
                final switch (rm & 0b11000000) // MOD
                {
                case 0:
                    BH = bank[BX]; // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    BH = bank[BX + FetchByte(addr)];
                    break;
                case 0b10000000:
                    BH = bank[BX + FetchWord(IP + 2)];
                    break;
                case 0b11000000:
                    BH = bank[FetchByte(addr)];
                    break;
                }
                break;
            }
            break; // 111
        }
        break;
    }
    case 0x8B: { // MOV REG16, R/M16
        ubyte rm = FetchImmByte;
        ushort reg = FetchImmWord(1);
        /*final switch (rm & 0b11_000000)
        {
            case 
        }*/
        IP += 4;
    }
        break;
    case 0x8C: // MOV R/M16, SEGREG
        // MOD 0SR R/M

        break;
    case 0x8D: // LEA REG16, MEM16

        break;
    case 0x8E: // MOV SEGREG, R/M16
        // MOD 0SR R/M

        break;
    case 0x8F: { // POP R/M16
        const byte rm = FetchImmByte;
        const ushort add = FetchWord(IP + 2);
        if (rm & 0b00111000) // MOD 000 R/M only
        {
            // Raise illegal instruction
        }
        else
        {
            final switch (rm & 0b111)
            {
            case 0b000: // BX + SI
                final switch (rm & 0b11000000)
                {
                case 0:
                    SetWord(BX + SI, Pop());
                    break;
                case 0b01_000000:
                    SetWord(BX + SI + (add >> 8), Pop());
                    break;
                case 0b10_000000:
                    SetWord(BX + SI + add, Pop());
                    break;
                case 0b11_000000:
                    SetWord(AX, Pop());
                    break;
                }
                break;
            case 0b001: // BX + DI
                final switch (rm & 0b11000000)
                {
                case 0:
                    SetWord(BX + DI, Pop());
                    break;
                case 0b01_000000:
                    SetWord(BX + DI + (add >> 8), Pop());
                    break;
                case 0b10_000000:
                    SetWord(BX + DI + add, Pop());
                    break;
                case 0b11_000000:
                    SetWord(CX, Pop());
                    break;
                }
                break;
            case 0b010: // BP + SI
                final switch (rm & 0b11000000)
                {
                case 0:
                    SetWord(BP + SI, Pop());
                    break;
                case 0b01_000000:
                    SetWord(BP + SI + (add >> 8), Pop());
                    break;
                case 0b10_000000:
                    SetWord(BP + SI + add, Pop());
                    break;
                case 0b11_000000:
                    SetWord(DX, Pop());
                    break;
                }
                break;
            case 0b011: // BP + DI
                final switch (rm & 0b11000000)
                {
                case 0:
                    SetWord(BP + DI, Pop());
                    break;
                case 0b01_000000:
                    SetWord(BP + DI + (add >> 8), Pop());
                    break;
                case 0b10_000000:
                    SetWord(BP + DI + add, Pop());
                    break;
                case 0b11_000000:
                    SetWord(BX, Pop());
                    break;
                }
                break;
            case 0b100: // SI
                final switch (rm & 0b11000000)
                {
                case 0:
                    SetWord(SI, Pop());
                    break;
                case 0b01_000000:
                    SetWord(SI + (add >> 8), Pop());
                    break;
                case 0b10_000000:
                    SetWord(SI + add, Pop());
                    break;
                case 0b11_000000:
                    SetWord(SP, Pop());
                    break;
                }
                break;
            case 0b101: // DI
                final switch (rm & 0b11000000)
                {
                case 0:
                    SetWord(DI, Pop());
                    break;
                case 0b01_000000:
                    SetWord(DI + (add >> 8), Pop());
                    break;
                case 0b10_000000:
                    SetWord(DI + add, Pop());
                    break;
                case 0b11_000000:
                    SetWord(BP, Pop());
                    break;
                }
                break;
            case 0b110: // BP
                final switch (rm & 0b11000000)
                {
                case 0:
                    //SetWord(BP, Pop()); - DIRECT ACCESS
                    break;
                case 0b01_000000:
                    SetWord(BP + (add >> 8), Pop());
                    break;
                case 0b10_000000:
                    SetWord(BP + add, Pop());
                    break;
                case 0b11_000000:
                    SetWord(SI, Pop());
                    break;
                }
                break;
            case 0b111: // BX
                final switch (rm & 0b11000000)
                {
                case 0:
                    SetWord(BX, Pop());
                    break;
                case 0b01_000000:
                    SetWord(BX + (add >> 8), Pop());
                    break;
                case 0b10_000000:
                    SetWord(BX + add, Pop());
                    break;
                case 0b11_000000:
                    SetWord(DI, Pop());
                    break;
                }
                break;
            }
        }
        IP += 4;
    }
        break;
    case 0x90: // NOP (aka XCHG AX, AX)
        ++IP;
        break;
    case 0x91: { // XCHG AX, CX
        const ushort ax = AX;
        AX = CX;
        CX = ax;
    }
        break;
    case 0x92: { // XCHG AX, DX
        const ushort ax = AX;
        AX = DX;
        DX = ax;
    }
        break;
    case 0x93: { // XCHG AX, BX
        const ushort ax = AX;
        AX = BX;
        BX = ax;
    }
        break;
    case 0x94: { // XCHG AX, SP
        const ushort ax = AX;
        AX = SP;
        SP = ax;
    }
        break;
    case 0x95: { // XCHG AX, BP
        const ushort ax = AX;
        AX = BP;
        BP = ax;
    }
        break;
    case 0x96: { // XCHG AX, SI
        const ushort ax = AX;
        AX = SI;
        SI = ax;
    }
        break;
    case 0x97: { // XCHG AX, DI
        const ushort ax = AX;
        AX = DI;
        DI = ax;
    }
        break;
    case 0x98: // CBW
        AH = AL & 0x80 ? 0xFF : 0;
        ++IP;
        break;
    case 0x99: // CWD
        DX = AX & 0x8000 ? 0xFFFF : 0;
        ++IP;
        break;
    case 0x9A: // CALL FAR_PROC
        Push(CS);
        Push(IP);
        break;
    case 0x9B: // WAIT
    //TODO: WAIT ???
        ++IP;
        break;
    case 0x9C: // PUSHF
        Push(FLAG);
        ++IP;
        break;
    case 0x9D: // POPF
        FLAG = Pop();
        ++IP;
        break;
    case 0x9E: // SAHF (AH to Flags)
        FLAGB = AH;
        ++IP;
        break;
    case 0x9F: // LAHF (Flags to AH)
        AH = FLAGB;
        ++IP;
        break;
    case 0xA0: // MOV AL, MEM8

        break;
    case 0xA1: // MOV AX, MEM16

        break;
    case 0xA2: // MOV MEM8, AL

        break;
    case 0xA3: // MOV MEM16, AX

        break;
    case 0xA4: // MOVS DEST-STR8, SRC-STR8

        break;
    case 0xA5: // MOVS DEST-STR16, SRC-STR16

        break;
    case 0xA6: { // CMPS DEST-STR8, SRC-STR8
        const int temp = bank[GetAddress(DS, SI)] - bank[GetAddress(ES, DI)];
        //TODO: CMPS PF
        ZF = temp == 0;
        AF = (temp & 0x10) != 0;
        CF = SF = (temp & 0x80) != 0;
        OF = (temp < 0) || (temp > 0xFF);
        if (DF == 0) {
            DI = DI + 1; SI = SI + 1;
        } else {
            DI = DI - 1; SI = SI - 1;
        }
    }
        break;
    case 0xA7: { // CMPS DEST-STR16, SRC-STR16
        const int temp = FetchWord(GetAddress(DS, SI)) - FetchWord(GetAddress(ES, DI));
        //TODO: CMPS PF
        ZF = temp == 0;
        AF = (temp & 0x10) != 0;
        CF = SF = (temp & 0x80) != 0;
        OF = (temp < 0) || (temp > 0xFFFF);
        if (DF == 0) {
            DI = DI + 2; SI = SI + 2;
        } else {
            DI = DI - 2; SI = SI - 2;
        }
    }
        break;
    case 0xA8: { // TEST AL, IMM8
        const int r = AL & FetchImmByte;
        //TODO: TEST ZF SF PF

        CF = OF = 0;
        IP += 2;
    }
        break;
    case 0xA9: { // TEST AX, IMM16
        const int r = AX & FetchImmWord;
        //TODO: TEST ZF SF PF

        CF = OF = 0;
        IP += 3;
    }
        break;
    case 0xAA: // STOS DEST-STR8
        bank[GetAddress(ES, DI)] = AL;
        if (DF == 0) DI = DI + 1;
        else         DI = DI - 1;
        ++IP;
        break;
    case 0xAB: // STOS DEST-STR16
        Insert(AX, GetAddress(ES, DI));
        if (DF == 0) DI = DI + 2;
        else         DI = DI - 2;
        ++IP;
        break;
    case 0xAC: // LODS SRC-STR8
        AL = bank[GetAddress(DS, SI)];
        if (DF == 0) SI = SI + 1;
        else         SI = SI - 1;
        ++IP;
        break;
    case 0xAD: // LODS SRC-STR16
        AX = FetchWord(GetAddress(DS, SI));
        if (DF == 0) SI = SI + 2;
        else         SI = SI - 2;
        ++IP;
        break;
    case 0xAE: { // SCAS DEST-STR8
        const int r = AL - bank[GetAddress(ES, DI)];
        //TODO: SCAS OF, PF
        ZF = r == 0;
        AF = (r & 0x10) != 0;
        CF = SF = (r & 0x80) != 0;
        if (DF == 0) DI = DI + 1;
        else         DI = DI - 1;
        ++IP;
    }
        break;
    case 0xAF: { // SCAS DEST-STR16
        const int r = AX - FetchWord(GetAddress(ES, DI));
        //TODO: SCAS OF, PF
        ZF = r == 0;
        AF = (r & 0x10) != 0;
        CF = SF = (r & 0x80) != 0;
        if (DF == 0) DI = DI + 2;
        else         DI = DI - 2;
        ++IP;
    }
        break;
    case 0xB0: // MOV AL, IMM8
        AL = FetchImmByte;
        IP += 2;
        break;
    case 0xB1: // MOV CL, IMM8
        CL = FetchImmByte;
        IP += 2;
        break;
    case 0xB2: // MOV DL, IMM8
        DL = FetchImmByte;
        IP += 2;
        break;
    case 0xB3: // MOV BL, IMM8
        BL = FetchImmByte;
        IP += 2;
        break;
    case 0xB4: // MOV AH, IMM8
        AH = FetchImmByte;
        IP += 2;
        break;
    case 0xB5: // MOV CH, IMM8
        CH = FetchImmByte;
        IP += 2;
        break;
    case 0xB6: // MOV DH, IMM8  
        DH = FetchImmByte;
        IP += 2;
        break;
    case 0xB7: // MOV BH, IMM8
        BH = FetchImmByte;
        IP += 2;
        break;
    case 0xB8: // MOV AX, IMM16
        AX = FetchWord();
        IP += 3;
        break;
    case 0xB9: // MOV CX, IMM16
        CX = FetchWord();
        IP += 3;
        break;
    case 0xBA: // MOV DX, IMM16
        DX = FetchWord();
        IP += 3;
        break;
    case 0xBB: // MOV BX, IMM16
        BX = FetchWord();
        IP += 3;
        break;
    case 0xBC: // MOV SP, IMM16
        SP = FetchWord();
        IP += 3;
        break;
    case 0xBD: // MOV BP, IMM16
        BP = FetchWord();
        IP += 3;
        break;
    case 0xBE: // MOV SI, IMM16
        SI = FetchWord();
        IP += 3;
        break;
    case 0xBF: // MOV DI, IMM16
        DI = FetchWord();
        IP += 3;
        break;
    case 0xC2: // RET IMM16 (NEAR)
        IP = Pop();
        SP = cast(ushort)(SP + FetchWord());
        //IP += 3; ?
        break;
    case 0xC3: // RET (NEAR)
        IP = Pop();
        break;
    case 0xC4: // LES REG16, MEM16
// Load into REG and ES
        
        break;
    case 0xC5: // LDS REG16, MEM16
// Load into REG and DS

        break;
    case 0xC6: // MOV MEM8, IMM8
        // MOD 000 R/M only
        break;
    case 0xC7: // MOV MEM16, IMM16
        // MOD 000 R/M only
        break;
    case 0xCA: // RET IMM16 (FAR)
        IP = Pop();
        CS = Pop();
        SP = SP + FetchWord;
        // IP += 3; ?
        break;
    case 0xCB: // RET (FAR)
        IP = Pop();
        CS = Pop();
        //++IP; ?
        break;
    case 0xCC: // INT 3
        Raise(3);
        ++IP;
        break;
    case 0xCD: // INT IMM8
        Raise(FetchImmByte);
        IP += 2;
        break;
    case 0xCE: // INTO
        if (CF) Raise(4);
        ++IP;
        break;
    case 0xCF: // IRET
        IP = Pop();
        CS = Pop();
        FLAG = Pop();
        ++IP;
        break;
    case 0xD0: // GRP2 R/M8, 1
        /*byte rm; // Get ModR/M byte
        switch (rm & 0b00111000) {
        case 0b00000000: // 000 - ROL

        break;
        case 0b00001000: // 001 - ROR

        break;
        case 0b00010000: // 010 - RCL

        break;
        case 0b00011000: // 011 - RCR

        break;
        case 0b00100000: // 100 - SAL/SHL

        break;
        case 0b00101000: // 101 - SHR

        break;
        case 0b00111000: // 111 - SAR

        break;
        default:
            
            break;
        }*/
        break;
    case 0xD1: // GRP2 R/M16, 1
        /*byte rm; // Get ModR/M byte
        switch (rm & 0b00111000) {
        case 0b00000000: // 000 - ROL

        break;
        case 0b00001000: // 001 - ROR

        break;
        case 0b00010000: // 010 - RCL

        break;
        case 0b00011000: // 011 - RCR

        break;
        case 0b00100000: // 100 - SAL/SHL

        break;
        case 0b00101000: // 101 - SHR

        break;
        case 0b00111000: // 111 - SAR

        break;
        default:

        break;
        }*/
        break;
    case 0xD2: // GRP2 R/M8, CL
        /*byte rm; // Get ModR/M byte
        switch (rm & 0b00111000) {
        case 0b00000000: // 000 - ROL

        break;
        case 0b00001000: // 001 - ROR

        break;
        case 0b00010000: // 010 - RCL

        break;
        case 0b00011000: // 011 - RCR

        break;
        case 0b00100000: // 100 - SAL/SHL

        break;
        case 0b00101000: // 101 - SHR

        break;
        case 0b00111000: // 111 - SAR

        break;
        default:

        break;
        }*/
        break;
    case 0xD3: // GRP2 R/M16, CL
        /*byte rm; // Get ModR/M byte
        switch (rm & 0b00111000) {
        case 0b00000000: // 000 - ROL

        break;
        case 0b00001000: // 001 - ROR

        break;
        case 0b00010000: // 010 - RCL

        break;
        case 0b00011000: // 011 - RCR

        break;
        case 0b00100000: // 100 - SAL/SHL

        break;
        case 0b00101000: // 101 - SHR

        break;
        case 0b00111000: // 111 - SAR

        break;
        default:

        break;
        }*/
        break;
    case 0xD4: { // AAM
        AH = cast(ubyte)(AL / 0xA);
        AL = cast(ubyte)(AL % 0xA);
        ++IP;
    }
        break;
    case 0xD5: { // AAD
        AL = (AL + (AH * 0xA)) & 0xFF;
        AH = 0;
        ++IP;
    }
        break;
    case 0xD7: // XLAT SOURCE-TABLE
        AL = bank[GetAddress(DS, BX) + AL];
        break;
    /*case 0xD8: // ESC OPCODE, SOURCE
    case 0xD9: // 1101 1XXX - MOD YYY R/M
    case 0xDA: // Used to escape to another co-processor.
    case 0xDB: 
    case 0xDC: 
    case 0xDD:
    case 0xDE:
    case 0xDF:

        break;*/
    case 0xE0: // LOOPNE/LOOPNZ SHORT-LABEL
        CX = CX - 1;
        if (CX && ZF == 0) // CX <> 0 AND ZF = 0
            IP += FetchImmSByte;
        else
            IP += 2;
        break;
    case 0xE1: // LOOPE/LOOPZ   SHORT-LABEL
        CX = CX - 1;
        if (CX && ZF) // CX <> 0 AND ZF = 1
            IP += FetchImmSByte;
        else
            IP += 2;
        break;
    case 0xE2: // LOOP  SHORT-LABEL
        CX = CX - 1;
        if (CX) // CX <> 0
            IP += FetchImmSByte;
        else
            IP += 2;
        break;
    case 0xE3: // JCXZ  SHORT-LABEL
        if (CX == 0)
            IP += FetchImmSByte;
        else
            IP += 2;
        break;
    case 0xE4: // IN AL, IMM8

        break;
    case 0xE5: // IN AX, IMM8

        break;
    case 0xE6: // OUT AL, IMM8

        break;
    case 0xE7: // OUT AX, IMM8

        break;
    case 0xE8: // CALL NEAR-PROC
        Push(IP);
        IP += FetchImmSWord; // Direct within segment
        break;
    case 0xE9: // JMP    NEAR-LABEL
        IP += FetchImmSWord; // ±32 KB
        break;
    case 0xEA: { // JMP  FAR-LABEL
        // Any segment, any fragment, 5 byte instruction.
        // EAh (LO-IP) (HI-IP) (LO-CS) (HI-CS)
        const int ip = GetIPAddress + 1;
        IP = FetchWord(ip);
        CS = FetchWord(ip + 2);
    }
        break;
    case 0xEB: // JMP  SHORT-LABEL
        IP += FetchImmSByte; // ±128 B
        break;
    case 0xEC: // IN AL, DX

        break;
    case 0xED: // IN AX, DX

        break;
    case 0xEE: // OUT AL, DX

        break;
    case 0xEF: // OUT AX, DX

        break;
    case 0xF0: // LOCK (prefix)
// http://qcd.phys.cmu.edu/QCDcluster/intel/vtune/reference/vc160.htm

        break;
    case 0xF2: // REPNE/REPNZ
CHECK_CX:
        if (CX)
        {
            // (chain)
            //TODO: Finish REPNE/REPNZ properly
            Execute(0xA6);
            CX = CX - 1;
            if (ZF == 0)
                goto CHECK_CX;
        }
        else ++IP;
        break;
    case 0xF3: // REP/REPE/REPNZ

        break;
    case 0xF4: // HLT
    //TODO: HLT
        ++IP;
        break;
    case 0xF5: // CMC
        CF = !CF;
        ++IP;
        break;
    case 0xF6: // GRP3a R/M8, IMM8
        /*byte rm; // Get ModR/M byte
        switch (rm & 0b00111000) {
        case 0b00000000: // 000 - TEST

        break;
        case 0b00010000: // 010 - NOT

        break;
        case 0b00011000: // 011 - NEG

        break;
        case 0b00100000: // 100 - MUL

        break;
        case 0b00101000: // 101 - IMUL

        break;
        case 0b00110000: // 110 - DIV

        break;
        case 0b00111000: // 111 - IDIV

        break;
        default:

        break;
        }*/
        break;
    case 0xF7: // GRP3b R/M16, IMM16
        /*byte rm; // Get ModR/M byte
        switch (rm & 0b00111000) {
        case 0b00000000: // 000 - TEST

        break;
        case 0b00010000: // 010 - NOT

        break;
        case 0b00011000: // 011 - NEG

        break;
        case 0b00100000: // 100 - MUL

        break;
        case 0b00101000: // 101 - IMUL

        break;
        case 0b00110000: // 110 - DIV

        break;
        case 0b00111000: // 111 - IDIV

        break;
        default:

        break;
        }*/
        break;
    case 0xF8: // CLC
        CF = false;
        ++IP;
        break;
    case 0xF9: // STC
        CF = true;
        ++IP;
        break;
    case 0xFA: // CLI
        IF = false;
        ++IP;
        break;
    case 0xFB: // STI
        IF = true;
        ++IP;
        break;
    case 0xFC: // CLD
        DF = false;
        ++IP;
        break;
    case 0xFD: // STD
        DF = true;
        ++IP;
        break;
    case 0xFE: // GRP4 R/M8
        /*byte rm; // Get ModR/M byte
        switch (rm & 0b00111000) {
        case 0b00000000: // 000 - INC

            break;
        case 0b00001000: // 001 - DEC

            break;
        default:

            break;
        }*/
        break;
    case 0xFF: // GRP5 R/M16
        /*byte rm; // Get ModR/M byte
        switch (rm & 0b00111000) {
        case 0b00000000: // 000 - INC

        break;
        case 0b00001000: // 001 - DEC

        break;
        case 0b00010000: // 010 - CALL R/M16 (intra)

        break;
        case 0b00011000: // 011 - CALL MEM16 (inter)

        break;
        case 0b00100000: // 100 - JMP R/M16 (intra)

        break;
        case 0b00101000: // 101 - JMP MEM16 (inter)

        break;
        case 0b00110000: // 110 - PUSH MEM16

        break;
        default:

        break;
        }*/
        break;
    default: // Illegal instruction
        if (Verbose)
            loghb("Illegal instruction : ", op, LogLevel.Error);
        //TODO: Raise vector on illegal op
        
        ++IP;
        break;
    }
}