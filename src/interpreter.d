/*
 * Interpreter.d: Legacy machine code interpreter. Mimics an Intel 8086.
 */

module Interpreter;

import dd_dos, std.stdio, std.path, poshub;

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
        return cast(ubyte)(
            SF ? 0x80 : 0 |
            ZF ? 0x40 : 0 |
            AF ? 0x10 : 0 |
            PF ? 0x4  : 0 |
            CF ? 1    : 0);
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
            OF ? 0x800 : 0 |
            DF ? 0x400 : 0 |
            IF ? 0x200 : 0 |
            TF ? 0x100 : 0 |
            SF ? 0x80  : 0 |
            ZF ? 0x40  : 0 |
            AF ? 0x10  : 0 |
            PF ? 0x4   : 0 |
            CF ? 1     : 0;
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
        uint addr = GetIPAddress + offset;
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
        // Page 4-27 (P169) of the Intel 8086 User Manual
        // contains decoding guide.
        //
        // Legend:
        // R/M : ModRegister/Memory byte
        // IMM : Immediate value
        // REG : Register
        // MEM : Memory location
        // SEGREG : Segment register
        // 
        // The number represents bitness.
        // Instruction descriptions are available at Page 2-35 (P50).
        // Note: ModR/M explanation is location at Page 4-20 (P162).
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
            AF = (AL & 0b1_0000) != 0;
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
            AF = (r & 0b1_0000) != 0; //((AL & 0b1000) - (b & 0b1000)) < 0;
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
        case 0x40: // INC AX
            AX = AX + 1;
            ++IP;
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
        case 0x8B: // MOV REG16, R/M16

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

    // Page 2-99 contains the interrupt message processor
    /// Raise interrupt.
    void Raise(ubyte code)
    {
        if (Verbose)
            writeln("[VMRI] INTERRUPT ", code, " RAISED");

        Push(FLAG);
        IF = TF = 0;
        Push(CS);
        Push(IP);
        //CS ← IDT[Interrupt number * 4].selector;
        //IP ← IDT[Interrupt number * 4].offset;

        // http://www.ctyme.com/intr/int.htm
        // http://www.shsu.edu/csc_tjm/spring2001/cs272/interrupt.html
        // http://spike.scu.edu.au/~barry/interrupts.html
        switch (code)
        {
        case 0x10: // VIDEO
            switch (AH)
            {
                /*
                 * VIDEO - Set cursor position.
                 * Input:
                 *   BH (Page number)
                 *   DH (Row, 0 is top)
                 *   DL (Column, 0 is top)
                 */
                case 0x02:
                    SetPos(DH, DL);
                    break;
                /*
                 * VIDEO - Get cursor position and size.
                 * Input:
                 *   BH (Page number)
                 * Return:
                 *   CH (Start scan line)
                 *   CL (End scan line)
                 *   DH (Row)
                 *   DL (Column)
                 */
                case 0x03:
                    AX = 0;
                    DH = cast(ubyte)CursorTop;
                    DL = cast(ubyte)CursorLeft;
                    break;
                /*
                 * VIDEO - Read light pen position
                 * Return:
                 *   AH (Trigger flag)
                 *   DH (Row)
                 *   DL (Column)
                 *   CH (Pixel row, modes 04h-06h)
                 *   CX (Pixel row, modes >200 rows)
                 *   BX (Pixel column)
                 */
                case 0x04:

                    break;
                default: break;
            }
            break;
        case 0x11: // BIOS - Get equipement list
            // Number of 16K banks of RAM on motherboard (PC only).
            ushort ax = 0b10000; // VGA
            /+if (FloppyDiskInstalled) {
                ax |= 1;
                // Bit 6-7 = Number of floppy drives
            }+/
            //if (PenInstalled) ax |= 0b100;
            AX = ax;
            break;
        case 0x12: // BIOS - Get memory size
            uint kbsize = memoryBank.length / 1024;
            AX = cast(ushort)kbsize;
            break;
        case 0x13: // DISK operations

            break;
        case 0x14: // SERIAL

            break;
        case 0x16: // Keyboard
            switch (AH)
            {
                case 0, 1: { // Get/Check keystroke
                    KeyInfo k = ReadKey;
                    AH = cast(ubyte)k.scanCode;
                    AL = cast(ubyte)k.keyCode;
                    if (AH) ZF = 0; // Keystroke available
                }
                    break;

                case 2: // SHIFT
                    // Bit | 7 | 6 | 5 | 4 | 3 | 2  | 1 | 0
                    // Des | I | C | N | S | A | Ct | L | R
                    // Insert, Capslock, Numlock, Scrolllock, Alt, Ctrl,
                    //   Left, Right
                    // AL = (flag)
                    break;

                default: break;
            }
            break;
        case 0x17: // PRINTER

            break;
        case 0x1A: // TIME
            switch (AH)
            {
                case 0: // Get system time
                // CX:DX (Number of clock ticks since midnight)
                // AL (Midnight flag)

                    break;

                case 1: // Set system time
                // CX:DX (Number of clock ticks since midnight)
                    break;

                default: break;
            }
            break;
        case 0x1B: // CTRL-BREAK handler

            break;
        case 0x21: // MS-DOS Services
            switch (AH)
            {
            /*
            * 00h - Terminate program.
            * Input:
            *   CS (PSP Segment)
            *
            * Notes: Microsoft recommends using INT 21/AH=4Ch for DOS 2+. This
            * function sets the program's return code (ERRORLEVEL) to 00h. Execution
            * continues at the address stored in INT 22 after DOS performs whatever
            * cleanup it needs to do (restoring the INT 22,INT 23,INT 24 vectors
            * from the PSP assumed to be located at offset 0000h in the segment
            * indicated by the stack copy of CS, etc.). If the PSP is its own parent,
            * the process's memory is not freed; if INT 22 additionally points into the
            * terminating program, the process is effectively NOT terminated. Not
            * supported by MS Windows 3.0 DOSX.EXE DOS extender.
            */
            case 0:

                break;
            /*
            * 01h - Read character from stdin with echo.
            * Input: None
            * Return: AL (Character)
            * 
            * Notes:
            * - ^C and ^Break are checked.
            * - ^P toggles the DOS-internal echo-to-printer flag.
            * - ^Z is not interpreted.
            */
            case 1:
                AL = ReadChar;

                break;
            /*
            * 02h - Write character to stdout.
            * Input: DL (Character)
            * Return: AL (Last character)
            * 
            * Notes:
            * - ^C and ^Break are checked. (If true, INT 23)
            * - If DL=09h on entry, in which case AL=20h is expended as blanks.
            * - If stdout is redirected to a file, no error-checks are performed.
            */
            case 2:
            
                break;
            /*
            * 05h - Write character to printer.
            * Input: DL (Character)
            * Return: None
            *
            * Notes:
            * - ^C and ^Break are checked. (Keyboard)
            * - Usually STDPRN, may be redirected under DOS 2.0+.
            * - If the printer is busy, this function will wait.
            *
            * Dev notes:
            * - Virtually print to a PRN (text) file.
            */
            case 5:

                break;
            /*
            * 06h - Direct console input/output.
            * Input:
            *   Output: DL (Character, DL != FFh)
            *   Input: DL (Character, DL == FFh)
            * Return:
            *   Ouput: AL (Character)
            *   Input:
            *     ZF set if no characters are available and AL == 00h
            *     ZF clear if a character is available and AL != 00h
            *
            * Notes:
            * - ^C and ^Break are checked. (Keyboard)
            *
            * Input notes:
            * - If the returned character is 00h, the user pressed a key with an
            *     extended keycode, which will be returned by the next call of
            *     this function
            */
            case 6:

                break;
            /*
             * 07h - Read character directly from stdin without echo.
             * Input: None
             * Return: AL (Character)
             *
             * Notes:
             * - ^C/^Break are not checked.
             */
            case 7:
                AL = ReadChar();
                break;
            /*
            * 08h - Read character from stdin without echo.
            * Input: None
            * Return: AL (Character)
            *
            * Notes:
            * - ^C/^Break are checked.
            */
            case 8:

                break;
            /*
             * 09h - Write string to stdout.
             * Input: DS:DX ('$' terminated)
             * Return: AL = 24h
             *
             * Notes:
             * - ^C and ^Break are not checked.
             */
            case 9:
                uint pd = GetAddress(DS, DX);

                version (PLATFORM_X86) {
                    char* p = cast(char*)&memoryBank[0] + pd;
                    while (*p != '$')
                        write(*p++);
                } else {
                    while (memoryBank[pd] != '$')
                        write(cast(char)memoryBank[pd++]);
                }

                AL = 0x24;
                break;
            /*
            * 0Ah - Buffered input.
            * Input: DS:DX (Pointer to BUFFER)
            * Return: Buffer filled with used input.
            *
            * Notes:
            * - ^C and ^Break are checked.
            * - Reads from stdin.
            *
            * BUFFER:
            * | Offset | Size | Description
            * +--------+------+-----------------
            * | 0      | 1    | Maximum characters buffer can hold
            * | 1      | 1    | Chars actually read (except CR) (or from last input)
            * | 2      | N    | Characters, including the final CR.
            */
            case 0xA:

                break;
            /*
            * 0Bh - Get stdin status.
            * Input: None.
            * Return:
            *   AL = 00h if no characters are available.
            *   AL = FFh if a character are available.
            *
            * Notes:
            * - ^C and ^Break are checked.
            */
            case 0xB:

                break;
            /*
             * 0Ch - Flush stdin buffer and read character.
             * Input:
             *   AL (STDIN input function to execute after flushing)
             *   Other registers as appropriate for the input function.
             * Return: As appropriate for the input function.
             *
             * Notes:
             * - If AL is not 1h, 6h, 7h, 8h, or Ah, the buffer is flushed and
             *     no input are attempted.
             */
            case 0xC:

                break;
            /*
             * 0Dh - Disk reset.
             * Input: None.
             * Return: None.
             *
             * Notes:
             * - Write all buffers to disk without updating directory information.
             */
            case 0xD:

                break;
            /*
            * 0Eh - Select default drive.
            * Input: DL (incrementing from 0 for A:)
            * Return: AL (number of potentially valid drive letters)
            *
            * Notes:
            * - The return value is the highest drive present.
            */
            case 0xE:

                break;
            /*
            * 19h - Get default drive.
            * Input: None.
            * Return: AL (incrementing from 0 for A:)
            */
            case 0x19:
                AL = 2; // Temporary.
                break;
            /*
            * 25h - Set interrupt vector.
            * Input:
            *   AL (Interrupt number)
            *   DS:DX (New interrupt handler)
            * Return: None.
            *
            * Notes:
            * - Preferred over manually changing the interrupt vector table.
            */
            case 0x25:

                break;
            /*
             * 26h - Create PSP
             * Input: DX (Segment to create PSP)
             * Return: AL destroyed
             *
             * Notes:
             * - New PSP is updated with memory size information; INTs 22h, 23h,
             *     24h taken from interrupt vector table; the parent PSP field
             *     is set to 0. (DOS 2+) DOS assumes that the caller's CS is the`
             *     segment of the PSP to copy.
             */
            case 0x26:

                break;
            /*
             * 2Ah - Get system date.
             * Input: None.
             * Return:
             *   CX (Year, 1980-2099)
             *   DH (Month)
             *   DL (Day)
             *   AL (Day of the week, Sunday = 0)
             */
            case 0x2A:
                version (Windows)
                {
                    import core.sys.windows.windows;
                    SYSTEMTIME s;
                    GetLocalTime(&s);

                    CX = s.wYear;
                    DH = cast(ubyte)s.wMonth;
                    DL = cast(ubyte)s.wDay;
                    AL = cast(ubyte)s.wDayOfWeek;
                }
                else version (Posix)
                {
                    import core.sys.posix.time;
                    time_t r;
                    tm* s;
                    time(&r);
                    s = localtime(&r);

                    CX = s.tm_year;
                    DH = cast(ubyte)s.tm_mon;
                    DL = cast(ubyte)s.tm_mday;
                    AL = cast(ubyte)s.tm_wday;
                }
                else
                {
                    static assert(0, "Implement INT 21h AH=2Ah");
                }
                break;
            /*
            * 2Bh - Set system date.
            * Input:
            *   CX (Year, 1980-2099)
            *   DH (Month)
            *   DL (Day)
            * Return: AL (00h if successful, FFh if failed (invalid))
            */
            case 0x2B:

                break;
            /*
            * 2Ch - Get system time.
            * Input: None.
            * Return:
            *   CH (Hour)
            *   CL (Minute)
            *   DH (Second)
            *   DL (1/100 seconds)
            */
            case 0x2C:
                version (Windows)
                {
                    import core.sys.windows.windows;
                    SYSTEMTIME s;
                    GetLocalTime(&s);

                    CH = cast(ubyte)s.wHour;
                    CL = cast(ubyte)s.wMinute;
                    DH = cast(ubyte)s.wSecond;
                    DL = cast(ubyte)s.wMilliseconds;
                }
                else version (Posix)
                {
                    import core.sys.posix.time;
                    time_t r;
                    tm* s;
                    time(&r);
                    s = localtime(&r);

                    CH = cast(ubyte)s.tm_hour;
                    CL = cast(ubyte)s.tm_min;
                    DH = cast(ubyte)s.tm_wday;

                    version (linux)
                    {
                        //TODO: Check
                        import core.sys.linux.sys.time;
                        timeval tv;
                        gettimeofday(&tv, null);
                        AL = cast(ubyte)tv.tv_usec;
                    }
                }
                else
                {
                    static assert(0, "Implement INT 21h AH=2Ch");
                }
                break;
            /*
            * 2Dh - Set system time.
            * Input:
            *   CH (Hour)
            *   CL (Minute)
            *   DH (Second)
            *   DL (1/100 seconds)
            * Return: AL (00h if successful, FFh if failed (invalid))
            */
            case 0x2D:

                break;
            /*
            * 2Eh - Set verify flag.
            * Input: AL (00 = off, 01 = on)
            * Return: None.
            *
            * Notes:
            * - Default state at boot is off.
            * - When on, all disk writes are verified provided the device driver
            *     supports read-after-write verification.
            */
            case 0x2E:

                break;
            /*
             * 30h - Get DOS version.
             * Input: AL (00h = OEM Number in AL, 01h = Version flag in AL)
             * Return:
             *   AL (Major version, DOS 1.x = 00h)
             *   AH (Minor version)
             *   BL:CX (24bit user serial* if DOS<5 or AL=0)
             *   BH (MS-DOS OEM number if DOS 5+ and AL=1)
             *   BH (Version flag bit 3: DOS is in ROM, other: reserved (0))
             *
             * *Most versions do not use this.
             */
            case 0x30:
                BH = AL == 0 ? OEM_ID.IBM : 1;
                AL = DOS_MAJOR_VERSION;
                AH = DOS_MINOR_VERSION;
                break;
            /*
             * 35h - Get interrupt vector.
             * Input: AL (Interrupt number)
             * Return: ES:BX (Current interrupt number)
             */
            case 0x35:

                break;
            /*
            * 36h - Get free disk space.
            * Input: DL (Drive number, A: = 0)
            * Return:
            *   AX (FFFFh = invalid drive)
            * or
            *   AX (Sectors per cluster)
            *   BX (Number of free clusters)
            *   CX (bytes per sector)
            *   DX (Total clusters on drive)
            *
            * Notes:
            * - Free space on drive in bytes is AX * BX * CX.
            * - Total space on drive in bytes is AX * CX * DX.
            * - "lost clusters" are considered to be in use.
            * - No proper results on CD-ROMs; use AX=4402h instead.
            */
            case 0x36:

                break;
            /*
             * Get country specific information
             * Input:
             *   AL (0)
             *   DS:DX (Buffer location, see BUFFER)
             * Return:
             *   CF set on error, otherwise cleared
             *   AX (Error code, 02h)
             *   AL (0 for current country, 1h-feh specific, ffh for >ffh)
             *   BX (16-bit country code)
             *     http://www.ctyme.com/intr/rb-2773.htm#Table1400
             *   Buffer at DS:DX filled
             *
             * BUFFER:
             * http://www.ctyme.com/intr/rb-2773.htm#Table1399
             */
            case 0x38:

                break;
            /*
            * 39h - Create subdirectory.
            * Input: DS:DX (ASCIZ path)
            * Return:
            *  CF clear if sucessful (AX set to 0)
            *  CF set on error (AX = error code (3 or 5))
            *
            * Notes:
            * - All directories in the given path except the last must exist.
            * - Fails if the parent directory is the root and is full.
            * - DOS 2.x-3.3 allow the creation of a directory sufficiently deep
            *     that it is not possible to make that directory the current
            *     directory because the path would exceed 64 characters.
            */
            case 0x39:
                
                break;
            /*
            * 3Ah - Remove subdirectory.
            * Input: DS:DX (ASCIZ path)
            * Return: 
            *   CF clear if successful (AX set to 0)
            *   CF set on error (AX = error code (03h,05h,06h,10h))
            *
            * Notes:
            * - Subdirectory must be empty.
            */
            case 0x3A:

                break;
            /*
            * 3Bh - Set current directory.
            * Input: DS:DX (ASCIZ path (maximum 64 Bytes))
            * Return:
            *  CF clear if sucessful (AX set to 0)
            *  CF set on error (AX = error code (3))
            *
            * Notes:
            * - If new directory name includes a drive letter, the default drive
            *     is not changed, only the current directory on that drive.
            */
            case 0x3B:

                break;
            /*
            * 3Ch - Create or truncate file.
            * Input:
            *   CX (File attributes, see ATTRIB)
            *   DS:DX (ASCIZ path)
            * Return:
            *  CF clear if sucessful (AX = File handle)
            *  CF set if error (AX = error code (3, 4, 5)
            *
            * Notes:
            * - If the file already exists, it is truncated to zero-length.
            *
            * ATTRIB:
            * | Bit         | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
            * | Description | S | - | A | D | V | S | H | R |
            * 7 - S = Shareable
            *     A = Archive
            *     D = Directory
            *     V = Volume label
            *     S = System
            *     H = Hidden
            * 0 - R = Read-only
            */
            case 0x3C:

                break;
            /*
            * 3Dh - Open file.
            * Input:
            *   AL (Access and sharing modes)
            *   DS:DX (ASCIZ path)
            * Return:
            *   CF clear if successful (AX = File handle)
            *   CF set on error (AX = error code (01h,02h,03h,04h,05h,0Ch,56h))
            *
            * Notes:
            * - File pointer is set to start of file.
            * - File handles which are inherited from a parent also inherit
            *     sharing and access restrictions.
            * - Files may be opened even if given the hidden or system attributes.
            */
            case 0x3D:

                break;
            /*
            * 3Eh - Close file.
            * Input: BX (File handle)
            * Return:
            *   CF clear if successful (AX = File handle)
            *   CF set on error (AX = error code (06h))
            *
            * Notes:
            * - If the file was written to, any pending disk writes are performed,
            *     the time and date stamps are set to the current time, and the
            *     directory entry is updated.
            */
            case 0x3E:

                break;
            /*
            * 3Fh - Read from file or device.
            * Input:
            *   BX (File handle)
            *   CX (Number of bytes to read)
            *   DS:DX (Points to buffer)
            * Return:
            *   CF clear if successful (AX = bytes read)
            *   CF set on error (AX = error code (05h,06h))
            *
            * Notes:
            * - Data is read beginning at current file position, and the file
            *     position is updated after a successful read.
            * - The returned AX may be smaller than the request in CX if a
            *     partial read occurred.
            * - If reading from CON, read stops at first CR.
            */
            case 0x3F:

                break;
            /*
            * 40h - Write to file or device.
            * Input:
            *   BX (File handle)
            *   CX (Number of bytes to write)
            *   DS:DX (Points to buffer)
            * Return:
            *   CF clear if successful (AX = bytes read)
            *   CF set on error (AX = error code (05h,06h))
            *
            * Notes:
            * - If CX is zero, no data is written, and the file is truncated or
            *     extended to the current position.
            * - Data is written beginning at the current file position, and the
            *     file position is updated after a successful write.
            * - The usual cause for AX < CX on return is a full disk.
            */
            case 0x40:

                break;
            /*
            * 41h - Delete file.
            * Input:
            *   DS:DX (ASCIZ path)
            *   CL (Attribute mask)
            * Return:
            *   CF clear if successful (AX = 0, AL seems to be drive number)
            *   CF set on error (AX = error code (2, 3, 5))
            *
            * Notes:
            * - (DOS 3.1+) wildcards are allowed if invoked via AX=5D00h, in
            *     which case the filespec must be canonical (as returned by
            *     AH=60h), and only files matching the attribute mask in CL are
            *     deleted.
            * - DOS does not erase the file's data; it merely becomes inaccessible
            *     because the FAT chain for the file is cleared.
            * - Deleting a file which is currently open may lead to filesystem
            *     corruption.
            */
            case 0x41:

                break;
            /*
            * 42h - Set current file position.
            * Input:
            *   AL (0 = SEEK_SET, 1 = SEEK_CUR, 2 = SEEK_END)
            *   BX (File handle)
            *   CX:DX (File origin offset)
            * Return:
            *   CF clear if successful (DX:AX = New position (from start))
            *   CF set on error (AX = error code (1, 6))
            *
            * Notes:
            * - For origins 01h and 02h, the pointer may be positioned before the
            *     start of the file; no error is returned in that case, but
            *     subsequent attempts at I/O will produce errors.
            * - If the new position is beyond the current end of file, the file
            *     will be extended by the next write (see AH=40h).
            */
            case 0x42:

                break;
            /*
            * 43h - Get or set file attributes.
            * Input:
            *   AL (00 for getting, 01 for setting)
            *   CX (New attributes if setting, see ATTRIB in 3Ch)
            *   DS:DX (ASCIZ path)
            * Return:
            *   CF cleared if successful (CX=File attributes on getting, AX=0 on setting)
            *   CF set on error (AX = error code (01h,02h,03h,05h))
            *
            * Bugs:
            * - Windows for Workgroups returns error code 05h (access denied)
            *     instead of error code 02h (file not found) when attempting to
            *     get the attributes of a nonexistent file.
            *
            * Notes:
            * - Setting will not change volume label or directory attribute bits,
            *     but will change the other attribute bits of a directory.
            * - MS-DOS 4.01 reportedly closes the file if it is currently open.
            */
            case 0x43:

                break;
            /*
            * 47h - Get current working directory.
            * Input:
            *   DL (Drive number, 0 = Default, 1 = A:, etc.)
            *   DS:DI (Pointer to 64-byte buffer for ASCIZ path)
            * Return:
            *   CF cleared if successful
            *   CF set on error code (AX = error code (Fh))
            *
            * Notes:
            * - The returned path does not include a drive or the initial
            *     backslash
            * - Many Microsoft products for Windows rely on AX being 0100h on
            *     success.
            */
            case 0x47:

                break;
            /*
             * 4Ah - Resize memory block
             * Input:
             *   BX (New size in paragraphs)
             *   ES (Segment of block to resize)
             * Return: 
             *   CF set on error, otherwise cleared
             *   AX error code (07h,08h,09h)
             *   BX (Maximum paragraphs available for specified memory block)
             *
             * Notes:
             * - Notes: Under DOS 2.1 to 6.0, if there is insufficient memory to
             *     expand the block as much as requested, the block will be made
             *     as large as possible. DOS 2.1-6.0 coalesces any free blocks
             *     immediately following the block to be resized.
             */
            /*case 0x4A:

                break;*/
            /*
             * 4Bh - Load/execute program
             * Input:
             *   AL (see LOADTYPE)
             *   DS:DX (ASCIZ path)
             *   ES:BX (parameter block)
             *   CX (Mode, only for AL=04h)
             * Return:
             *   CF set on error, or cleared
             *   AX (error code (01h,02h,05h,08h,0Ah,0Bh))
             *   BX and DX destroyed
            /*
            * 4Ch - Terminate with return code.
            * Input: AL (Return code)
            * Return: None. (Never returns)
            *
            * Notes:
            * - Unless the process is its own parent, all open files are closed
            *     and all memory belonging to the process is freed.
            */
            case 0x4B:

                break;
            /*
             * 4Ch - Terminate with code
             * Input: AL (Return code)
             */
            case 0x4C:
                LastErrorCode = AL;
                Running = false;
                break;
            /*
            * 4Dh - Get return code. (ERRORLEVEL)
            * Input: None
            * Return:
            *   AH (Termination type*)
            *   AL (Code)
            *
            * *00 = Normal, 01 = Control-C Abort, 02h = Critical Error Abort,
            *   03h Terminate and stay resident.
            *
            * Notes:
            * - The word in which DOS stores the return code is cleared after
            *     being read by this function, so the return code can only be
            *     retrieved once.
            * - COMMAND.COM stores the return code of the last external command
            *     it executed as ERRORLEVEL.
            */
            case 0x4D:
                
                AL = LastErrorCode;
                break;
            /*
            * 54h - Get verify flag.
            * Input: None.
            * Return:
            *   AL (0 = off, 1 = on)
            */
            case 0x54:

                break;
            /*
            * 56h - Rename file.
            * Input:
            *   DS:DX (ASCIZ path)
            *   ES:DI (ASCIZ new name)
            *   CL (Attribute mask, server call only)
            * Return:
            *   CF cleared if successful
            *   CF set on error (AX = error code (02h,03h,05h,11h))
            *
            * Notes:
            * - Allows move between directories on same logical volume.
            * - This function does not set the archive attribute.
            * - Open files should not be renamed.
            * - (DOS 3.0+) allows renaming of directories.
            */
            case 0x56:

                break;
            /*
            * 57h - Get or set file's last-written time and date.
            * Input:
            *   AL (0 = get, 1 = set)
            *   BX (File handle)
            *   CX (New time (set), see TIME)
            *   DX (New date (set), see DATE)
            * Return (get):
            *   CF clear if successful (CX = file's time, DX = file's date)
            *   CF set on error (AX = error code (01h,06h))
            * Return (set):
            *   CF cleared if successful
            *   CF set on error (AX = error code (01h,06h))
            *
            * TIME:
            * | Bits        | 15-11 | 10-5    | 4-0     |
            * | Description | hours | minutes | seconds |
            * DATE:
            * | Bits        | 15-9         | 8-5   | 4-0 |
            * | Description | year (1980-) | month | day |
            */
            case 0x57:

                break;
            default: break;
            }
            break;
        case 0x27: // TERMINATE AND STAY RESIDANT

            break;
        case 0x29: // FAST CONSOLE OUTPUT
            write(cast(char)AL);
            break;
        default: break;
        }

        IP = Pop();
        CS = Pop();
        IF = TF = 1;
        FLAG = Pop();
    }
}

/// Sleep for n hecto-nanoseconds
pragma(inline, true) void HSLEEP(int n) {
    import core.thread : Thread;
    import core.time : hnsecs;
    Thread.sleep(hnsecs(n));
}

/// Sleep for n nanoseconds
pragma(inline, true) void NSLEEP(int n) {
    import core.thread : Thread;
    import core.time : nsecs;
    Thread.sleep(nsecs(n));
}