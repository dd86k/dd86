/*
 * Interpreter.d: Legacy machine code interpreter. Mimics an Intel 8086.
 */

module Interpreter;

import main, dd_dos, std.stdio, std.path, Poshub;
import core.thread : Thread;
import core.time : hnsecs, nsecs;

version (X86)
    version = PLATFORM_X86;
else version (X86_64)
    version = PLATFORM_X86;

/// Initial amount of memory.
enum MAX_MEM = 0x10_0000; // 1 MB

/// OEM IDs
enum OEM_ID { // Used for INT 21h AH=30 so far.
    IBM, Compaq, MSPackagedProduct, ATnT, ZDS
}

//NOTE: Opened files should go in JFT

/// Mimics an Intel8086 system
class Intel8086
{
    ///
    this(uint memsize = MAX_MEM)
    {
        memoryBank = new ubyte[memsize];
        CS = 0xFFFF;
    }

    ///
    bool Sleep;
    ///
    bool Running = true;

    ///
    ubyte[] memoryBank;

    /// Generic register
    ubyte AH, AL, BH, BL, CH, CL, DH, DL;
    /// Index register
    ushort SI, DI, BP, SP;
    /// Segment register
    ushort CS, DS, ES, SS;
    /// Program Counter
    ushort IP;

    /// FLAG
    bool OF, // 11, Overflow Flag
         DF, // 10, Direction Flag
         IF, //  9, Interrupt Enable Flag
         TF, //  8, Trap Flag
         SF, //  7, Sign Flag
         ZF, //  6, Zero Flag
         AF, //  4, Auxiliary Carry Flag (aka Adjust Flag)
         PF, //  2, Parity Flag
         CF; //  0, Carry Flag

    /// Initiate the machine and run.
    void Initiate()
    {
        if (Verbose)
            writeln("[VMRI] Running...");
        
        while (Running)
        {
            if (Sleep)
                HSLEEP( 2 ); // Intel 8086 - 5 MHz
            Execute(memoryBank[GetIPAddress]);
        }
    }

    ///
    void Reset()
    {
        OF = DF = IF = TF = SF =
             ZF = AF = PF = CF = false;
        CS = 0xFFFF;
        IP = DS = SS = ES = 0;
        // Empty Queue Bus
    }

    void FullReset()
    {
        Reset();
        AL = AH = BL = BH = CL = CH = DL = DH =
             BP = SP = DI = SI = 0;
    }

    @property ushort AX() {
        return (AH << 8) | AL;
    }
    @property void AX(ushort v) {
        AH = (v >> 8) & 0xFF;
        AL = v & 0xFF;
    }
    @property void AX(int v) {
        AH = (v >> 8) & 0xFF;
        AL = v & 0xFF;
    }

    @property ushort BX() {
        return (BH << 8) | BL;
    }
    @property void BX(ushort v) {
        BH = (v >> 8) & 0xFF;
        BL = v & 0xFF;
    }
    @property void BX(int v) {
        BH = (v >> 8) & 0xFF;
        BL = v & 0xFF;
    }

    @property ushort CX() {
        return (CH << 8) | CL;
    }
    @property void CX(ushort v) {
        CH = (v >> 8) & 0xFF;
        CL = v & 0xFF;
    }
    @property void CX(int v) {
        CH = (v >> 8) & 0xFF;
        CL = v & 0xFF;
    }

    @property ushort DX() {
        return (DH << 8) | DL;
    }
    @property void DX(ushort v) {
        DH = (v >> 8) & 0xFF;
        DL = v & 0xFF;
    }
    @property void DX(int v) {
        DH = (v >> 8) & 0xFF;
        DL = v & 0xFF;
    }

    void Push(ushort value)
    {
        SP -= 2;
        const uint addr = GetAddress(SS, SP);
        SetWord(addr, value);
    }

    ushort Pop()
    {
        const uint addr = GetAddress(SS, SP);
        SP += 2;
        return FetchWord(addr);
    }

    /// Get physical address out of two segment/register values.
    uint GetAddress(ushort segment, ushort offset)
    {
        return (segment << 4) + offset;
    }
    /// Get next instruction location
    uint GetIPAddress()
    {
        return GetAddress(CS, IP);
    }

    /// Fetch an immediate unsigned byte (ubyte).
    ubyte FetchByte() {
        return memoryBank[GetIPAddress + 1];
    }
    /// Fetch an unsigned byte (ubyte).
    ubyte FetchByte(uint addr) {
        return memoryBank[addr];
    }
    /// Fetch an immediate byte (byte).
    byte FetchSByte() {
        return cast(byte)memoryBank[GetIPAddress + 1];
    }

    /// Fetch an immediate unsigned word (ushort).
    ushort FetchWord() {
        version (PLATFORM_X86)
            return *(cast(ushort*)&memoryBank[GetIPAddress + 1]);
        else {
            const uint addr = GetIPAddress + 1;
            return cast(ushort)(memoryBank[addr] | memoryBank[addr + 1] << 8);
        }
    }
    /// Fetch an unsigned word (ushort).
    ushort FetchWord(uint addr) {
        version (PLATFORM_X86)
            return *(cast(ushort*)&memoryBank[addr]);
        else
            return cast(ushort)(memoryBank[addr] | memoryBank[addr + 1] << 8);
    }
    /// Fetch an immediate unsigned word with optional offset.
    ushort FetchImmWord(uint offset) {
        version (PLATFORM_X86)
            return *(cast(ushort*)&memoryBank[GetIPAddress + offset]);
        else {
            uint l = GetIPAddress + offset;
            return cast(ushort)(memoryBank[l] | memoryBank[l + 1] << 8);
        }
    }
    /// Fetch an immediate word (short).
    short FetchSWord() {
        version (PLATFORM_X86)
            return *(cast(short*)&memoryBank[GetIPAddress + 1]);
        else {
            const uint addr = GetIPAddress + 1;
            return cast(short)(memoryBank[addr] | memoryBank[addr + 1] << 8);
        }
    }

    /// Set an unsigned word in memory.
    void SetWord(uint addr, ushort value) {
        version (PLATFORM_X86)
            *(cast(ushort *)&memoryBank[addr]) = value;
        else {
            memoryBank[addr] = value & 0xFF;
            memoryBank[addr + 1] = value >> 8 & 0xFF;
        }
    }

    @property ubyte FLAGB()
    {
        return 
            SF ? 0x80 : 0 | ZF ? 0x40 : 0 |
            AF ? 0x10 : 0 | PF ? 0x4  : 0 |
            CF ? 1    : 0;
    }

    @property void FLAGB(ubyte flag)
    {
        SF = (flag & 0x80) != 0;
        ZF = (flag & 0x40) != 0;
        AF = (flag & 0x10) != 0;
        PF = (flag & 0x4 ) != 0;
        CF = (flag & 1   ) != 0;
    }

    @property ushort FLAG()
    {
        return
            OF ? 0x800 : 0 | DF ? 0x400 : 0 | IF ? 0x200 : 0 |
            TF ? 0x100 : 0 | SF ? 0x80  : 0 | ZF ? 0x40  : 0 |
            AF ? 0x10  : 0 | PF ? 0x4   : 0 | CF ? 1     : 0;
    }

    @property void FLAG(ushort flag)
    {
        OF = (flag & 0x800) != 0;
        DF = (flag & 0x400) != 0;
        IF = (flag & 0x200) != 0;
        TF = (flag & 0x100) != 0;
        SF = (flag & 0x80 ) != 0;
        ZF = (flag & 0x40 ) != 0;
        AF = (flag & 0x10 ) != 0;
        PF = (flag & 0x4  ) != 0;
        CF = (flag & 1    ) != 0;
    }

    /// Directly overwrite instructions at CS:IP.
    void Insert(ubyte[] ops, size_t offset = 0)
    {
        size_t i = GetIPAddress + offset;
        foreach(b; ops) memoryBank[i++] = b;
    }

    void Insert(ubyte op, size_t offset = 0)
    {
        memoryBank[GetIPAddress + offset] = op;
    }
    void Insert(ushort op, size_t offset = 0)
    {
        size_t addr = GetIPAddress + offset;
        memoryBank[addr] = op & 0xFF;
        if (op > 0xFF)
            memoryBank[++addr] = (op >> 8) & 0xFF;
    }

    /// Directly overwrite data at CS:IP.
    void Insert(string data, size_t offset = 0)
    {
        size_t i = GetIPAddress + offset;
        foreach(b; data) memoryBank[i++] = b;
    }

    /// Execute the operation code. (ALU)
    void Execute(ubyte op) // All instructions are 1-byte initially.
    {
        // Legend:
        // R/M - ModRegister/Memory byte
        // IMM - Immediate value
        // REG - Register
        // MEM - Memory location
        // SEGREG - Segment register
        // 
        // The number represents bitness.
        //TODO: Group instructions. -dd
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
            AL += FetchByte;
            IP += 2;
            SF = CF = (AL & 0x80) != 0;
            PF = (AL & 1) != 0;
            AF = (AL & 0x10) != 0;
            ZF = AL == 0;
            //OF = 
            break;
        case 0x05: // ADD AX, IMM16
            AX = AX + FetchWord;
            IP += 3;
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
            AL |= FetchByte;
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
        case 0x14: // ADC AL, IMM8
            AL += FetchByte;
            if (CF) ++AL;
            IP += 2;
            break;
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
            AL -= FetchByte - 1;
            if (CF) --AL;
            IP += 2;
        }
            break;
        case 0x1D: { // SBB AX, IMM16
            int t = AX - FetchByte;
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
            AL &= FetchByte;
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
            const byte oldAL = AL;
            const bool oldCF = CF;
            CF = false;

            if (((oldAL & 0xF) > 9) || AF)
            {
                AL += 6;
                CF = oldCF || (AL & 0x80);
                AF = true;
            }
            else AF = false;

            if ((oldAL > 0x99) || oldCF)
            {
                AL += 0x60;
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
            AL -= FetchByte;
            IP += 2;
            break;
        case 0x2D: // SUB AX, IMM16
            AX = AX - FetchWord;
            IP += 3;
            break;
        case 0x2E: // CS:

            break;
        case 0x2F: { // DAS
            const ubyte oldAL = AL;
            const bool oldCF = CF;
            CF = false;

            if (((oldAL & 0xF) > 9) || AF)
            {
                AL -= 6;
                CF = oldCF || (AL & 0b10000000);
                AF = true;
            }
            else AF = false;

            if ((oldAL > 0x99) || oldCF)
            {
                AL -= 0x60;
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
            AL ^= FetchByte;
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
            AL &= 0xF;
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
            const ubyte b = FetchByte;
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
                --AH;
                AF = CF = true;
            }
            else
            {
                AF = CF = false;
            }
            AL &= 0xF;
            ++IP;
            break;
        case 0x40: { // INC AX
            int r = AX + 1;
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
            ++SP;
            ++IP;
            break;
        case 0x45: // INC BP
            ++BP;
            ++IP;
            break;
        case 0x46: // INC SI
            ++SI;
            ++IP;
            break;
        case 0x47: // INC DI
            ++DI;
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
            --SP;
            ++IP;
            break;
        case 0x4D: // DEC BP
            --BP;
            ++IP;
            break;
        case 0x4E: // DEC SI
            --SI;
            ++IP;
            break;
        case 0x4F: // DEC DI
            --DI;
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
            IP += OF ? FetchSByte : 2;
            break;
        case 0x71: // JNO           SHORT-LABEL
            IP += OF == false ? FetchSByte : 2;
            break;
        case 0x72: // JB/JNAE/JC    SHORT-LABEL
            IP += CF ? FetchSByte : 2;
            break;
        case 0x73: // JNB/JAE/JNC   SHORT-LABEL
            IP += CF == false ? FetchSByte : 2;
            break;
        case 0x74: // JE/JZ         SHORT-LABEL
            IP += ZF ? FetchSByte : 2;
            break;
        case 0x75: // JNE/JNZ       SHORT-LABEL
            IP += ZF == false ? FetchSByte : 2;
            break;
        case 0x76: // JBE/JNA       SHORT-LABEL
            IP += (CF || ZF) ? FetchSByte : 2;
            break;
        case 0x77: // JNBE/JA       SHORT-LABEL
            IP += CF == false && ZF == false ? FetchSByte : 2;
            break;
        case 0x78: // JS            SHORT-LABEL
            IP += SF ? FetchSByte : 2;
            break;
        case 0x79: // JNS           SHORT-LABEL
            IP += SF == false ? FetchSByte : 2;
            break;
        case 0x7A: // JP/JPE        SHORT-LABEL
            IP += PF ? FetchSByte : 2;
            break;
        case 0x7B: // JNP/JPO       SHORT-LABEL
            IP += PF == false ? FetchSByte : 2;
            break;
        case 0x7C: // JL/JNGE       SHORT-LABEL
            IP += SF != OF ? FetchSByte : 2;
            break;
        case 0x7D: // JNL/JGE       SHORT-LABEL
            IP += SF == OF ? FetchSByte : 2;
            break;
        case 0x7E: // JLE/JNG       SHORT-LABEL
            IP += SF != OF || ZF ? FetchSByte : 2;
            break;
        case 0x7F: // JNLE/JG       SHORT-LABEL
            IP += SF == OF && ZF == false ? FetchSByte : 2;
            break;
        case 0x80: { // GRP1 R/M8, IMM8
            const ubyte rm = FetchByte; // Get ModR/M byte
            const ubyte im = FetchByte(GetIPAddress + 2); // 8-bit Immediate
            final switch (rm & 0b111_000) { // REG
            case 0b000_000: // 000 - ADD

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
            IP += 3;
            break;
        }
        case 0x81: { // GRP1 R/M16, IMM16
            const ubyte rm = FetchByte;  // Get ModR/M byte
            const ushort im = FetchWord(GetIPAddress + 2); // 16-bit Immediate
            final switch (rm & 0b111_000) { // ModR/M's REG
            case 0b000_000: // 000 - ADD

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
            const ubyte rm = FetchByte; // Get ModR/M byte
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
            const ubyte rm = FetchByte; // Get ModR/M byte
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
        case 0x89: // MOV R/M16, REG16

            break;
        case 0x8A: { // MOV REG8, R/M8
            const uint addr = GetIPAddress + 2;
            const ubyte rm = FetchByte;
            final switch (rm & 0b111) // R/M
            {
            case 0: // BX + SI
                final switch (rm & 0b00111000) // REG
                {
                case 0: // AL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0: // 00
                        AL = memoryBank[BX + SI];
                        break;
                    case 0b01000000: // 01
                        AL = memoryBank[BX + SI + FetchByte(addr)];
                        break;
                    case 0b10000000: // 10
                        AL = memoryBank[BX + SI + FetchWord(addr)];
                        break;
                    case 0b11000000: // 11
                        AL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00001000: // CL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CL = memoryBank[BX + SI];
                        break;
                    case 0b01000000:
                        CL = memoryBank[BX + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CL = memoryBank[BX + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00010000: // DL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DL = memoryBank[BX + SI];
                        break;
                    case 0b01000000:
                        DL = memoryBank[BX + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DL = memoryBank[BX + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00011000: // BL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BL = memoryBank[BX + SI];
                        break;
                    case 0b01000000:
                        BL = memoryBank[BX + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BL = memoryBank[BX + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00100000: // AH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        AH = memoryBank[BX + SI];
                        break;
                    case 0b01000000:
                        AH = memoryBank[BX + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AH = memoryBank[BX + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00101000: // CH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CH = memoryBank[BX + SI];
                        break;
                    case 0b01000000:
                        CH = memoryBank[BX + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CH = memoryBank[BX + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00110000: // DH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DH = memoryBank[BX + SI];
                        break;
                    case 0b01000000:
                        DH = memoryBank[BX + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DH = memoryBank[BX + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00111000: // BH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BH = memoryBank[BX + SI];
                        break;
                    case 0b01000000:
                        BH = memoryBank[BX + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BH = memoryBank[BX + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BH = memoryBank[FetchByte(addr)];
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
                        AL = memoryBank[BX + DI];
                        break;
                    case 0b01000000:
                        AL = memoryBank[BX + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AL = memoryBank[BX + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00001000: // CL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CL = memoryBank[BX + DI];
                        break;
                    case 0b01000000:
                        CL = memoryBank[BX + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CL = memoryBank[BX + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00010000: // DL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DL = memoryBank[BX + DI];
                        break;
                    case 0b01000000:
                        DL = memoryBank[BX + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DL = memoryBank[BX + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00011000: // BL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BL = memoryBank[BX + DI];
                        break;
                    case 0b01000000:
                        BL = memoryBank[BX + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BL = memoryBank[BX + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00100000: // AH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        AH = memoryBank[BX + DI];
                        break;
                    case 0b01000000:
                        AH = memoryBank[BX + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AH = memoryBank[BX + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00101000: // CH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CH = memoryBank[BX + DI];
                        break;
                    case 0b01000000:
                        CH = memoryBank[BX + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CH = memoryBank[BX + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00110000: // DH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DH = memoryBank[BX + DI];
                        break;
                    case 0b01000000:
                        DH = memoryBank[BX + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DH = memoryBank[BX + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00111000: // BH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BH = memoryBank[BX + DI];
                        break;
                    case 0b01000000:
                        BH = memoryBank[BX + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BH = memoryBank[BX + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BH = memoryBank[FetchByte(addr)];
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
                        AL = memoryBank[BP + SI];
                        break;
                    case 0b01000000:
                        AL = memoryBank[BP + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AL = memoryBank[BP + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00001000: // CL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CL = memoryBank[BP + SI];
                        break;
                    case 0b01000000:
                        CL = memoryBank[BP + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CL = memoryBank[BP + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00010000: // DL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DL = memoryBank[BP + SI];
                        break;
                    case 0b01000000:
                        DL = memoryBank[BP + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DL = memoryBank[BP + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00011000: // BL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BL = memoryBank[BP + SI];
                        break;
                    case 0b01000000:
                        BL = memoryBank[BP + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BL = memoryBank[BP + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00100000: // AH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        AH = memoryBank[BP + SI];
                        break;
                    case 0b01000000:
                        AH = memoryBank[BP + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AH = memoryBank[BP + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00101000: // CH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CH = memoryBank[BP + SI];
                        break;
                    case 0b01000000:
                        CH = memoryBank[BP + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CH = memoryBank[BP + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00110000: // DH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DH = memoryBank[BP + SI];
                        break;
                    case 0b01000000:
                        DH = memoryBank[BP + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DH = memoryBank[BP + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00111000: // BH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BH = memoryBank[BP + SI];
                        break;
                    case 0b01000000:
                        BH = memoryBank[BP + SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BH = memoryBank[BP + SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BH = memoryBank[FetchByte(addr)];
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
                        AL = memoryBank[BP + DI];
                        break;
                    case 0b01000000:
                        AL = memoryBank[BP + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AL = memoryBank[BP + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00001000: // CL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CL = memoryBank[BP + DI];
                        break;
                    case 0b01000000:
                        CL = memoryBank[BP + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CL = memoryBank[BP + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00010000: // DL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DL = memoryBank[BP + DI];
                        break;
                    case 0b01000000:
                        DL = memoryBank[BP + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DL = memoryBank[BP + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00011000: // BL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BL = memoryBank[BP + DI];
                        break;
                    case 0b01000000:
                        BL = memoryBank[BP + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BL = memoryBank[BP + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00100000: // AH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        AH = memoryBank[BP + DI];
                        break;
                    case 0b01000000:
                        AH = memoryBank[BP + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AH = memoryBank[BP + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00101000: // CH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CH = memoryBank[BP + DI];
                        break;
                    case 0b01000000:
                        CH = memoryBank[BP + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CH = memoryBank[BP + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00110000: // DH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DH = memoryBank[BP + DI];
                        break;
                    case 0b01000000:
                        DH = memoryBank[BP + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DH = memoryBank[BP + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00111000: // BH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BH = memoryBank[BP + DI];
                        break;
                    case 0b01000000:
                        BH = memoryBank[BP + DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BH = memoryBank[BP + DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BH = memoryBank[FetchByte(addr)];
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
                        AL = memoryBank[SI];
                        break;
                    case 0b01000000:
                        AL = memoryBank[SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AL = memoryBank[SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00001000: // CL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CL = memoryBank[SI];
                        break;
                    case 0b01000000:
                        CL = memoryBank[SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CL = memoryBank[SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00010000: // DL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DL = memoryBank[SI];
                        break;
                    case 0b01000000:
                        DL = memoryBank[SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DL = memoryBank[SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00011000: // BL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BL = memoryBank[SI];
                        break;
                    case 0b01000000:
                        BL = memoryBank[SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BL = memoryBank[SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00100000: // AH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        AH = memoryBank[SI];
                        break;
                    case 0b01000000:
                        AH = memoryBank[SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AH = memoryBank[SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00101000: // CH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CH = memoryBank[SI];
                        break;
                    case 0b01000000:
                        CH = memoryBank[SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CH = memoryBank[SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00110000: // DH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DH = memoryBank[SI];
                        break;
                    case 0b01000000:
                        DH = memoryBank[SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DH = memoryBank[SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00111000: // BH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BH = memoryBank[SI];
                        break;
                    case 0b01000000:
                        BH = memoryBank[SI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BH = memoryBank[SI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BH = memoryBank[FetchByte(addr)];
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
                        AL = memoryBank[DI];
                        break;
                    case 0b01000000:
                        AL = memoryBank[DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AL = memoryBank[DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00001000: // CL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CL = memoryBank[DI];
                        break;
                    case 0b01000000:
                        CL = memoryBank[DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CL = memoryBank[DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00010000: // DL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DL = memoryBank[DI];
                        break;
                    case 0b01000000:
                        DL = memoryBank[DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DL = memoryBank[DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00011000: // BL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BL = memoryBank[DI];
                        break;
                    case 0b01000000:
                        BL = memoryBank[DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BL = memoryBank[DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00100000: // AH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        AH = memoryBank[DI];
                        break;
                    case 0b01000000:
                        AH = memoryBank[DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AH = memoryBank[DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00101000: // CH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CH = memoryBank[DI];
                        break;
                    case 0b01000000:
                        CH = memoryBank[DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CH = memoryBank[DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00110000: // DH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DH = memoryBank[DI];
                        break;
                    case 0b01000000:
                        DH = memoryBank[DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DH = memoryBank[DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00111000: // BH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BH = memoryBank[DI];
                        break;
                    case 0b01000000:
                        BH = memoryBank[DI + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BH = memoryBank[DI + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BH = memoryBank[FetchByte(addr)];
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
                        AL = memoryBank[BP]; // DIRECT ADDRESS
                        break;
                    case 0b01000000:
                        AL = memoryBank[BP + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AL = memoryBank[BP + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00001000: // CL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CL = memoryBank[BP]; // DIRECT ADDRESS
                        break;
                    case 0b01000000:
                        CL = memoryBank[BP + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CL = memoryBank[BP + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00010000: // DL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DL = memoryBank[BP]; // DIRECT ADDRESS
                        break;
                    case 0b01000000:
                        DL = memoryBank[BP + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DL = memoryBank[BP + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00011000: // BL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BL = memoryBank[BP]; // DIRECT ADDRESS
                        break;
                    case 0b01000000:
                        BL = memoryBank[BP + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BL = memoryBank[BP + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00100000: // AH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        AH = memoryBank[BP]; // DIRECT ADDRESS
                        break;
                    case 0b01000000:
                        AH = memoryBank[BP + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AH = memoryBank[BP + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00101000: // CH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CH = memoryBank[BP]; // DIRECT ADDRESS
                        break;
                    case 0b01000000:
                        CH = memoryBank[BP + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CH = memoryBank[BP + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00110000: // DH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DH = memoryBank[BP]; // DIRECT ADDRESS
                        break;
                    case 0b01000000:
                        DH = memoryBank[BP + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DH = memoryBank[BP + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00111000: // BH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BH = memoryBank[BP]; // DIRECT ADDRESS
                        break;
                    case 0b01000000:
                        BH = memoryBank[BP + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BH = memoryBank[BP + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BH = memoryBank[FetchByte(addr)];
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
                        AL = memoryBank[BX];
                        break;
                    case 0b01000000:
                        AL = memoryBank[BX + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AL = memoryBank[BX + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        AL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00001000: // CL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CL = memoryBank[BX];
                        break;
                    case 0b01000000:
                        CL = memoryBank[BX + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CL = memoryBank[BX + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        CL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00010000: // DL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DL = memoryBank[BX];
                        break;
                    case 0b01000000:
                        DL = memoryBank[BX + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DL = memoryBank[BX + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        DL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00011000: // BL
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BL = memoryBank[BX];
                        break;
                    case 0b01000000:
                        BL = memoryBank[BX + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BL = memoryBank[BX + FetchWord(addr)];
                        break;
                    case 0b11000000:
                        BL = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00100000: // AH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        AH = memoryBank[BX];
                        break;
                    case 0b01000000:
                        AH = memoryBank[BX + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        AH = memoryBank[BX + FetchWord(IP + 2)];
                        break;
                    case 0b11000000:
                        AH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00101000: // CH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        CH = memoryBank[BX]; // DIRECT ADDRESS
                        break;
                    case 0b01000000:
                        CH = memoryBank[BX + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        CH = memoryBank[BX + FetchWord(IP + 2)];
                        break;
                    case 0b11000000:
                        CH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00110000: // DH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        DH = memoryBank[BX];
                        break;
                    case 0b01000000:
                        DH = memoryBank[BX + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        DH = memoryBank[BX + FetchWord(IP + 2)];
                        break;
                    case 0b11000000:
                        DH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                case 0b00111000: // BH
                    final switch (rm & 0b11000000) // MOD
                    {
                    case 0:
                        BH = memoryBank[BX]; // DIRECT ADDRESS
                        break;
                    case 0b01000000:
                        BH = memoryBank[BX + FetchByte(addr)];
                        break;
                    case 0b10000000:
                        BH = memoryBank[BX + FetchWord(IP + 2)];
                        break;
                    case 0b11000000:
                        BH = memoryBank[FetchByte(addr)];
                        break;
                    }
                    break;
                }
                break; // 111
            }
            break;
        }
        case 0x8B: { // MOV REG16, R/M16
            ubyte rm = FetchByte;
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
            const byte rm = FetchByte;
            const ushort add = FetchWord(IP + 2);
            if (rm & 0b00111000) // MOD 000 R/M only
            {
                // Raise illegal instruction
            }
            else
            {
                //TODO: Check if POP R/M16 was done correctly.
                final switch (rm & 0b00000111)
                {
                case 0b000: // BX + SI
                    final switch (rm & 0b11000000)
                    {
                    case 0:
                        SetWord(BX + SI, Pop());
                        break;
                    case 0b01000000:
                        SetWord(BX + SI + (add >> 8), Pop());
                        break;
                    case 0b10000000:
                        SetWord(BX + SI + add, Pop());
                        break;
                    case 0b11000000:
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
                    case 0b01000000:
                        SetWord(BX + DI + (add >> 8), Pop());
                        break;
                    case 0b10000000:
                        SetWord(BX + DI + add, Pop());
                        break;
                    case 0b11000000:
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
                    case 0b01000000:
                        SetWord(BP + SI + (add >> 8), Pop());
                        break;
                    case 0b10000000:
                        SetWord(BP + SI + add, Pop());
                        break;
                    case 0b11000000:
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
                    case 0b01000000:
                        SetWord(BP + DI + (add >> 8), Pop());
                        break;
                    case 0b10000000:
                        SetWord(BP + DI + add, Pop());
                        break;
                    case 0b11000000:
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
                    case 0b01000000:
                        SetWord(SI + (add >> 8), Pop());
                        break;
                    case 0b10000000:
                        SetWord(SI + add, Pop());
                        break;
                    case 0b11000000:
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
                    case 0b01000000:
                        SetWord(DI + (add >> 8), Pop());
                        break;
                    case 0b10000000:
                        SetWord(DI + add, Pop());
                        break;
                    case 0b11000000:
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
                    case 0b01000000:
                        SetWord(BP + (add >> 8), Pop());
                        break;
                    case 0b10000000:
                        SetWord(BP + add, Pop());
                        break;
                    case 0b11000000:
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
                    case 0b01000000:
                        SetWord(BX + (add >> 8), Pop());
                        break;
                    case 0b10000000:
                        SetWord(BX + add, Pop());
                        break;
                    case 0b11000000:
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
            ushort ax = AX;
            AX = CX;
            CX = ax;
        }
            break;
        case 0x92: { // XCHG AX, DX
            ushort ax = AX;
            AX = DX;
            DX = ax;
        }
            break;
        case 0x93: { // XCHG AX, BX
            ushort ax = AX;
            AX = BX;
            BX = ax;
        }
            break;
        case 0x94: { // XCHG AX, SP
            ushort ax = AX;
            AX = SP;
            SP = ax;
        }
            break;
        case 0x95: { // XCHG AX, BP
            ushort ax = AX;
            AX = BP;
            BP = ax;
        }
            break;
        case 0x96: { // XCHG AX, SI
            ushort ax = AX;
            AX = SI;
            SI = ax;
        }
            break;
        case 0x97: { // XCHG AX, DI
            ushort ax = AX;
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
        /*case 0x9B: // WAIT

            break;*/
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
        case 0xA6: // CMPS DEST-STR8, SRC-STR8

            break;
        case 0xA7: // CMPS DEST-STR16, SRC-STR16

            break;
        case 0xA8: // TEST AL, IMM8

            break;
        case 0xA9: // TEST AX, IMM16

            break;
        case 0xAA: // STOS DEST-STR8

            break;
        case 0xAB: // STOS DEST-STR16

            break;
        case 0xAC: // LODS SRC-STR8

            break;
        case 0xAD: // LODS SRC-STR16

            break;
        case 0xAE: // SCAS DEST-STR8

            break;
        case 0xAF: // SCAS DEST-STR16

            break;
        case 0xB0: // MOV AL, IMM8
            AL = FetchByte;
            IP += 2;
            break;
        case 0xB1: // MOV CL, IMM8
            CL = FetchByte;
            IP += 2;
            break;
        case 0xB2: // MOV DL, IMM8
            DL = FetchByte;
            IP += 2;
            break;
        case 0xB3: // MOV BL, IMM8
            BL = FetchByte;
            IP += 2;
            break;
        case 0xB4: // MOV AH, IMM8
            AH = FetchByte;
            IP += 2;
            break;
        case 0xB5: // MOV CH, IMM8
            CH = FetchByte;
            IP += 2;
            break;
        case 0xB6: // MOV DH, IMM8
            DH = FetchByte;
            IP += 2;
            break;
        case 0xB7: // MOV BH, IMM8
            BH = FetchByte;
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
            //++IP; ?
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
            SP += FetchWord;
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
            Raise(FetchByte);
            IP += 2;
            break;
        case 0xCE: // INTO
            if (CF)
                Raise(4);
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

            break;
        /*case 0xD8: // ESC OPCODE, SOURCE
        case 0xD9: // 1101 1XXX - MOD YYY R/M
        case 0xDA: // Used to ESCape to another co-processor.
        case 0xDB: 
        case 0xDC: 
        case 0xDD:
        case 0xDE:
        case 0xDF:

            break;*/

        case 0xE0: // LOOPNE/LOOPNZ SHORT-LABEL

            break;
        case 0xE1: // LOOPE/LOOPZ   SHORT-LABEL

            break;
        case 0xE2: // LOOP  SHORT-LABEL

            break;
        case 0xE3: // JCXZ  SHORT-LABEL

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
            IP += FetchSWord(); // Direct within segment
            break;
        case 0xE9: // JMP    NEAR-LABEL
            IP += FetchSWord(); // ±32 KB
            break;
        case 0xEA: { // JMP  FAR-LABEL
            // Any segment, any fragment, 5 byte instruction.
            // EAh (LO-IP) (HI-IP) (LO-CS) (HI-CS)
            ushort ip = cast(ushort)(GetIPAddress + 1);
            IP = FetchWord(ip);
            CS = FetchWord(ip + 2);
        }
            break;
        case 0xEB: // JMP  SHORT-LABEL
            IP += FetchSByte; // ±128 B
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

            break;
        case 0xF3: // REP/REPE/REPNZ

            break;
        case 0xF4: // HLT

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
                writefln("[VMRE] Illegal instruction! (%Xh)", op);
            // Raise vector
            break;
        }
    }
}

/// Sleep for n hecto-nanoseconds
pragma(inline, true) void HSLEEP(int n) {
    Thread.sleep(hnsecs(n));
}

/// Sleep for n nanoseconds
pragma(inline, true) void NSLEEP(int n) {
    Thread.sleep(nsecs(n));
}