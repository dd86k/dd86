/*
 * Interpreter.cpp: Legacy machine code interpreter. Mimics an Intel 8086.
 * 
 * Architecture: Page 2-3 (P18)
 * 1. Fetch the next instruction from memory.
 * 2. Read an operand (if instruction demands).
 * 3. Execute.
 * 4. Write results (if instruction demands).
 */

#include <iostream>
#include <cstdlib>
#include <cstring>

#include "Interpreter.hpp"
#include "dd-dos.hpp" // For Con
#include "Utils.hpp"

//NOTE: Opened files should go in JFT

Intel8086::Intel8086()
	: AX(0), BX(0), CX(0), DX(0)
	, SI(0), DI(0), BP(0), SP(0)
	, CS(0xFFFF), DS(0), ES(0), SS(0)
	, IP(0)
	, OF(false), DF(false), IF(false)
	, TF(false), SF(false), ZF(false)
	, AF(false), PF(false), CF(false)
{
    memoryBank = new byte[MAX_MEMORY]();
}

Intel8086::~Intel8086()
{
	delete memoryBank;
}

/// <summary>
/// Load the machine and OS with optional starting app other than COMMAND.COM.
/// </summary>
void Intel8086::Init(const std::string &filename)
{


    while (true) {
        ExecuteInstruction(memoryBank[(CS << 4) | IP]);
    }
}

/// <summary>
/// Opens a file from the host and adjusts the virtual program's PSP.JFT.
/// </summary>
/*void Intel8086::Open(const std::string &filename)
{


}*/

void Intel8086::Reset() {
    OF = DF = IF = TF = SF =
        ZF = AF = PF = CF = false;
    CS = 0xFFFF;
    IP = DS = SS = ES = 0;
    // Empty Queue Bus
}

/*
 * AL/AH
 */
inline byte Intel8086::GetAL() {
    return GetLower(AX);
}
inline void Intel8086::SetAL(byte v) {
    SetLower(AX, v);
}
inline byte Intel8086::GetAH() {
    return GetUpper(AX);
}
inline void Intel8086::SetAH(byte v) {
    SetUpper(AX, v);
}

/*
 * CL/CH
 */
inline byte Intel8086::GetCL() {
    return GetLower(CX);
}
inline void Intel8086::SetCL(byte v){
    SetLower(CX, v);
}
inline byte Intel8086::GetCH() {
    return GetUpper(CX);
}
inline void Intel8086::SetCH(byte v){
    SetUpper(CX, v);
}


/*
 * DL/DH
 */
inline byte Intel8086::GetDL() {
    return GetLower(DX);
}
inline void Intel8086::SetDL(byte v){
    SetLower(DX, v);
}
inline byte Intel8086::GetDH() {
    return GetUpper(DX);
}
inline void Intel8086::SetDH(byte v){
    SetUpper(DX, v);
}

/*
 * BL/BH
 */
inline byte Intel8086::GetBL() {
    return GetLower(BX);
}
inline void Intel8086::SetBL(byte v){
    SetLower(BX, v);
}
inline byte Intel8086::GetBH() {
    return GetUpper(BX);
}
inline void Intel8086::SetBH(byte v){
    SetUpper(BX, v);
}

/// <summary>
/// Execute the operation code. (ALU)
/// </summary>
/// <remark>
/// Queue-Bus (Q-BUS) is one byte large.
/// Page 4-27 (P169) of the Intel 8086 User Manual
/// contains decoding guide.
///
/// Legend:
/// R/M : Mod{Register/Memory} byte
/// IMM : Immediate value
/// REG : Register
/// MEM : Memory location
/// SEGREG : Segment register
/// SHORT : +/- 128 Byte displacement (2 byte instruction)
/// NEAR  : +/- 32K Byte displacement (3 byte instruction)
/// FAR   : Any segment/offset (5 byte instruction)
/// 
/// The number represents bitness.
/// </remark>
void Intel8086::ExecuteInstruction(byte op)
{
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
    case 0x04: { // ADD AL, IMM8
        byte b = memoryBank[IP + 1];
        byte al = GetAL();
        byte alr = al + b;
        OF = al + b > 0xFF;
        SF = (alr & 0b10000000) != 0;
        ZF = alr == 0;
        //AF
        //CF
        //PF
        SetAL(alr);
        IP += 2;
        break;
    }
    case 0x05: { // ADD AX, IMM16

        break;
    }
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
    case 0x0C: { // OR AL, IMM8

        break;
    }
    case 0x0D: { // OR AX, IMM16

        break;
    }
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

        break;
    }
    case 0x15: { // ADC AX, IMM16

        break;
    }
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
    case 0x1C: // SBB R/M8, REG8

        break;
    case 0x1D: // SBB R/M16, REG16

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

        break;
    case 0x25: // AND AX, IMM16

        break;
    case 0x26: // ES: (Segment override prefix)
        // e.g. mov	ax, [es:100h] ; Use ES as the segment

        break;
    case 0x27: { // DAA
        byte oldAL = GetAL();
        bool oldCF = CF;
        CF = false;

        if (((oldAL & 0xF) > 9) || AF)
        {
            SetAL(GetAL() + 6);
            CF = oldCF || (GetAL() & 0b10000000);
            AF = true;
        }
        else AF = false;

        if ((oldAL > 0x99) || oldCF)
        {
            SetAL(GetAL() + 0x60);
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

        break;
    case 0x2D: // SUB AX, IMM16

        break;
    case 0x2E: // CS:

        break;
    case 0x2F: { // DAS
        byte oldAL = GetAL();
        bool oldCF = CF;
        CF = false;

        if (((oldAL & 0xF) > 9) || AF)
        {
            SetAL(GetAL() - 6);
            CF = oldCF || (GetAL() & 0b10000000);
            AF = true;
        }
        else AF = false;

        if ((oldAL > 0x99) || oldCF)
        {
            SetAL(GetAL() - 0x60);
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

        break;
    case 0x35: // XOR AX, IMM16

        break;
    case 0x36: // SS:

        break;
    case 0x37: // AAA
        if (((GetAL() & 0xF) > 9) || AF)
        {
            AX += 0x106;
            AF = CF = true;
        }
        else AF = CF = false;
        SetAL(GetAL() & 0xF);
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

        break;
    case 0x3D: // CMP AX, IMM16

        break;
    case 0x3E: // DS:

        break;
    case 0x3F: { // AAS
        if (((GetAL() & 0xF) > 9) || AF)
        {
            AX -= 6;
            SetAH(GetAH() - 1);
            AF = CF = true;
            SetAL(GetAL() & 0xF);
        }
        else
        {
            AF = CF = false;
            SetAL(GetAL() & 0xF);
        }
        ++IP;
    }
        break;
    case 0x40: // INC AX
        ++AX;
        ++IP;
        break;
    case 0x41: // INC CX
        ++CX;
        ++IP;
        break;
    case 0x42: // INC DX
        ++DX;
        ++IP;
        break;
    case 0x43: // INC BX
        ++BX;
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
        ++SP;
        ++IP;
        break;
    case 0x48: // DEC AX
        --AX;
        ++IP;
        break;
    case 0x49: // DEC CX
        --CX;
        ++IP;
        break;
    case 0x4A: // DEC DX
        --DX;
        ++IP;
        break;
    case 0x4B: // DEC BX
        --BX;
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
    case 0x70: // JO    SHORT-LABEL
        if (OF)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x71: // JNO   SHORT-LABEL
        if (OF == false)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x72: // JB/JNAE/JC    SHORT-LABEL
        if (CF)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x73: // JNB/JAE/JNC   SHORT-LABEL
        if (CF == false)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x74: // JE/JZ     SHORT-LABEL
        if (ZF)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x75: // JNE/JNZ   SHORT-LABEL
        if (ZF == false)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x76: // JBE/JNA   SHORT-LABEL
        if (CF || ZF)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x77: // JNBE/JA   SHORT-LABEL
        if (CF == false && ZF == false)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x78: // JS        SHORT-LABEL
        if (SF)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x79: // JNS       SHORT-LABEL
        if (SF == false)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x7A: // JP/JPE    SHORT-LABEL
        if (PF)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x7B: // JNP/JPO   SHORT-LABEL
        if (PF == false)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x7C: // JL/JNGE   SHORT-LABEL
        if (SF != OF)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x7D: // JNL/JGE   SHORT-LABEL
        if (SF == OF)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x7E: // JLE/JNG   SHORT-LABEL
        if (SF != OF || ZF)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x7F: // JNLE/JG   SHORT-LABEL
        if (SF == OF && ZF == false)
            IP += memoryBank[IP + 1];
        else IP += 2;
        break;
    case 0x80: { // GRP1 R/M8, IMM8
        byte rm = memoryBank[IP + 1]; // Get ModR/M byte
        byte ra = memoryBank[IP + 2]; // 8-bit Immediate
        switch (rm & 0b00111000) { // REG
        case 0b00000000: // 000 - ADD

            break;
        case 0b00001000: // 001 - OR

            break;
        case 0b00010000: // 010 - ADC

            break;
        case 0b00011000: // 011 - SBB

            break;
        case 0b00100000: // 100 - AND

            break;
        case 0b00101000: // 101 - SUB

            break;
        case 0b00110000: // 110 - XOR

            break;
        case 0b00111000: // 111 - CMP

            break;
        default: break;
        }
        IP += 3;
        break;
    }
    case 0x81: { // GRP1 R/M16, IMM16
        byte rm = memoryBank[IP + 1];  // Get ModR/M byte
        ushort ra = FetchWord(IP + 2); // 16-bit Immediate
        switch (rm & 0b00111000) { // ModR/M's REG
        case 0b00000000: // 000 - ADD

        break;
        case 0b00001000: // 001 - OR

        break;
        case 0b00010000: // 010 - ADC

        break;
        case 0b00011000: // 011 - SBB

        break;
        case 0b00100000: // 100 - AND

        break;
        case 0b00101000: // 101 - SUB

        break;
        case 0b00110000: // 110 - XOR

        break;
        case 0b00111000: // 111 - CMP

        break;
        default: break;
        }
        break;
    }
    case 0x82: // GRP1 R/M8, IMM8
        /*byte rm; // Get ModR/M byte
        switch (rm & 0b00111000) { // ModRM REG
        case 0b00000000: // 000 - ADD

        break;
        case 0b00001000: // 001 - OR

        break;
        case 0b00010000: // 010 - ADC

        break;
        case 0b00011000: // 011 - SBB

        break;
        case 0b00100000: // 100 - AND

        break;
        case 0b00101000: // 101 - SUB

        break;
        case 0b00110000: // 110 - XOR

        break;
        case 0b00111000: // 111 - CMP

        break;
        default: break;
        }*/
        break;
    case 0x83: // GRP1 R/M16, IMM8
        /*byte rm; // Get ModR/M byte
        switch (rm & 0b00111000) { // ModRM REG
        case 0b00000000: // 000 - ADD

        break;
        case 0b00001000: // 001 - OR

        break;
        case 0b00010000: // 010 - ADC

        break;
        case 0b00011000: // 011 - SBB

        break;
        case 0b00100000: // 100 - AND

        break;
        case 0b00101000: // 101 - SUB

        break;
        case 0b00110000: // 110 - XOR

        break;
        case 0b00111000: // 111 - CMP

        break;
        default: break;
        }*/
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
        byte rm = memoryBank[IP + 1];
        byte ra = memoryBank[IP + 2];
        //TODO: Group by MOD->REG->R/M instead (MOV REG8, R/M8)
        switch (rm & 0b00000111) // R/M
        {
        case 0b00000000: // BX + SI
            switch (rm & 0b00111000) // REG
            {
            case 0b00000000: // AL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000: // 00
                    SetAL(memoryBank[BX + SI]);
                    break;
                case 0b01000000: // 01
                    SetAL(memoryBank[BX + SI + ra]);
                    break;
                case 0b10000000: // 10
                    SetAL(memoryBank[BX + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000: // 11
                    SetAL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00001000: // CL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCL(memoryBank[BX + SI]);
                    break;
                case 0b01000000:
                    SetCL(memoryBank[BX + SI + ra]);
                    break;
                case 0b10000000:
                    SetCL(memoryBank[BX + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00010000: // DL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDL(memoryBank[BX + SI]);
                    break;
                case 0b01000000:
                    SetDL(memoryBank[BX + SI + ra]);
                    break;
                case 0b10000000:
                    SetDL(memoryBank[BX + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00011000: // BL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBL(memoryBank[BX + SI]);
                    break;
                case 0b01000000:
                    SetBL(memoryBank[BX + SI + ra]);
                    break;
                case 0b10000000:
                    SetBL(memoryBank[BX + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00100000: // AH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAH(memoryBank[BX + SI]);
                    break;
                case 0b01000000:
                    SetAH(memoryBank[BX + SI + ra]);
                    break;
                case 0b10000000:
                    SetAH(memoryBank[BX + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00101000: // CH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCH(memoryBank[BX + SI]);
                    break;
                case 0b01000000:
                    SetCH(memoryBank[BX + SI + ra]);
                    break;
                case 0b10000000:
                    SetCH(memoryBank[BX + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00110000: // DH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDH(memoryBank[BX + SI]);
                    break;
                case 0b01000000:
                    SetDH(memoryBank[BX + SI + ra]);
                    break;
                case 0b10000000:
                    SetDH(memoryBank[BX + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00111000: // BH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBH(memoryBank[BX + SI]);
                    break;
                case 0b01000000:
                    SetBH(memoryBank[BX + SI + ra]);
                    break;
                case 0b10000000:
                    SetBH(memoryBank[BX + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBH(ra);
                    break;
                default: break;
                }
                break;
            default: break;
            }
            break; // 000
        case 0b00001000: // BX + DI
            switch (rm & 0b00111000) // REG
            {
            case 0b00000000: // AL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAL(memoryBank[BX + DI]);
                    break;
                case 0b01000000:
                    SetAL(memoryBank[BX + DI + ra]);
                    break;
                case 0b10000000:
                    SetAL(memoryBank[BX + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00001000: // CL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCL(memoryBank[BX + DI]);
                    break;
                case 0b01000000:
                    SetCL(memoryBank[BX + DI + ra]);
                    break;
                case 0b10000000:
                    SetCL(memoryBank[BX + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00010000: // DL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDL(memoryBank[BX + DI]);
                    break;
                case 0b01000000:
                    SetDL(memoryBank[BX + DI + ra]);
                    break;
                case 0b10000000:
                    SetDL(memoryBank[BX + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00011000: // BL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBL(memoryBank[BX + DI]);
                    break;
                case 0b01000000:
                    SetBL(memoryBank[BX + DI + ra]);
                    break;
                case 0b10000000:
                    SetBL(memoryBank[BX + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00100000: // AH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAH(memoryBank[BX + DI]);
                    break;
                case 0b01000000:
                    SetAH(memoryBank[BX + DI + ra]);
                    break;
                case 0b10000000:
                    SetAH(memoryBank[BX + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00101000: // CH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCH(memoryBank[BX + DI]);
                    break;
                case 0b01000000:
                    SetCH(memoryBank[BX + DI + ra]);
                    break;
                case 0b10000000:
                    SetCH(memoryBank[BX + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00110000: // DH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDH(memoryBank[BX + DI]);
                    break;
                case 0b01000000:
                    SetDH(memoryBank[BX + DI + ra]);
                    break;
                case 0b10000000:
                    SetDH(memoryBank[BX + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00111000: // BH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBH(memoryBank[BX + DI]);
                    break;
                case 0b01000000:
                    SetBH(memoryBank[BX + DI + ra]);
                    break;
                case 0b10000000:
                    SetBH(memoryBank[BX + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBH(ra);
                    break;
                default: break;
                }
                break;
            default: break;
            }
            break; // 001
        case 0b00000010: // BP + SI
            switch (rm & 0b00111000) // REG
            {
            case 0b00000000: // AL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAL(memoryBank[BP + SI]);
                    break;
                case 0b01000000:
                    SetAL(memoryBank[BP + SI + ra]);
                    break;
                case 0b10000000:
                    SetAL(memoryBank[BP + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00001000: // CL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCL(memoryBank[BP + SI]);
                    break;
                case 0b01000000:
                    SetCL(memoryBank[BP + SI + ra]);
                    break;
                case 0b10000000:
                    SetCL(memoryBank[BP + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00010000: // DL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDL(memoryBank[BP + SI]);
                    break;
                case 0b01000000:
                    SetDL(memoryBank[BP + SI + ra]);
                    break;
                case 0b10000000:
                    SetDL(memoryBank[BP + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00011000: // BL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBL(memoryBank[BP + SI]);
                    break;
                case 0b01000000:
                    SetBL(memoryBank[BP + SI + ra]);
                    break;
                case 0b10000000:
                    SetBL(memoryBank[BP + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00100000: // AH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAH(memoryBank[BP + SI]);
                    break;
                case 0b01000000:
                    SetAH(memoryBank[BP + SI + ra]);
                    break;
                case 0b10000000:
                    SetAH(memoryBank[BP + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00101000: // CH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCH(memoryBank[BP + SI]);
                    break;
                case 0b01000000:
                    SetCH(memoryBank[BP + SI + ra]);
                    break;
                case 0b10000000:
                    SetCH(memoryBank[BP + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00110000: // DH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDH(memoryBank[BP + SI]);
                    break;
                case 0b01000000:
                    SetDH(memoryBank[BP + SI + ra]);
                    break;
                case 0b10000000:
                    SetDH(memoryBank[BP + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00111000: // BH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBH(memoryBank[BP + SI]);
                    break;
                case 0b01000000:
                    SetBH(memoryBank[BP + SI + ra]);
                    break;
                case 0b10000000:
                    SetBH(memoryBank[BP + SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBH(ra);
                    break;
                default: break;
                }
                break;
            default: break;
            }
            break; // 010
        case 0b00000011: // BP + DI
            switch (rm & 0b00111000) // REG
            {
            case 0b00000000: // AL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAL(memoryBank[BP + DI]);
                    break;
                case 0b01000000:
                    SetAL(memoryBank[BP + DI + ra]);
                    break;
                case 0b10000000:
                    SetAL(memoryBank[BP + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00001000: // CL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCL(memoryBank[BP + DI]);
                    break;
                case 0b01000000:
                    SetCL(memoryBank[BP + DI + ra]);
                    break;
                case 0b10000000:
                    SetCL(memoryBank[BP + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00010000: // DL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDL(memoryBank[BP + DI]);
                    break;
                case 0b01000000:
                    SetDL(memoryBank[BP + DI + ra]);
                    break;
                case 0b10000000:
                    SetDL(memoryBank[BP + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00011000: // BL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBL(memoryBank[BP + DI]);
                    break;
                case 0b01000000:
                    SetBL(memoryBank[BP + DI + ra]);
                    break;
                case 0b10000000:
                    SetBL(memoryBank[BP + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00100000: // AH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAH(memoryBank[BP + DI]);
                    break;
                case 0b01000000:
                    SetAH(memoryBank[BP + DI + ra]);
                    break;
                case 0b10000000:
                    SetAH(memoryBank[BP + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00101000: // CH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCH(memoryBank[BP + DI]);
                    break;
                case 0b01000000:
                    SetCH(memoryBank[BP + DI + ra]);
                    break;
                case 0b10000000:
                    SetCH(memoryBank[BP + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00110000: // DH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDH(memoryBank[BP + DI]);
                    break;
                case 0b01000000:
                    SetDH(memoryBank[BP + DI + ra]);
                    break;
                case 0b10000000:
                    SetDH(memoryBank[BP + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00111000: // BH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBH(memoryBank[BP + DI]);
                    break;
                case 0b01000000:
                    SetBH(memoryBank[BP + DI + ra]);
                    break;
                case 0b10000000:
                    SetBH(memoryBank[BP + DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBH(ra);
                    break;
                default: break;
                }
                break;
            default: break;
            }
            break; // 011
        case 0b00000100: // SI
            switch (rm & 0b00111000) // REG
            {
            case 0b00000000: // AL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAL(memoryBank[SI]);
                    break;
                case 0b01000000:
                    SetAL(memoryBank[SI + ra]);
                    break;
                case 0b10000000:
                    SetAL(memoryBank[SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00001000: // CL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCL(memoryBank[SI]);
                    break;
                case 0b01000000:
                    SetCL(memoryBank[SI + ra]);
                    break;
                case 0b10000000:
                    SetCL(memoryBank[SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00010000: // DL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDL(memoryBank[SI]);
                    break;
                case 0b01000000:
                    SetDL(memoryBank[SI + ra]);
                    break;
                case 0b10000000:
                    SetDL(memoryBank[SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00011000: // BL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBL(memoryBank[SI]);
                    break;
                case 0b01000000:
                    SetBL(memoryBank[SI + ra]);
                    break;
                case 0b10000000:
                    SetBL(memoryBank[SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00100000: // AH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAH(memoryBank[SI]);
                    break;
                case 0b01000000:
                    SetAH(memoryBank[SI + ra]);
                    break;
                case 0b10000000:
                    SetAH(memoryBank[SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00101000: // CH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCH(memoryBank[SI]);
                    break;
                case 0b01000000:
                    SetCH(memoryBank[SI + ra]);
                    break;
                case 0b10000000:
                    SetCH(memoryBank[SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00110000: // DH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDH(memoryBank[SI]);
                    break;
                case 0b01000000:
                    SetDH(memoryBank[SI + ra]);
                    break;
                case 0b10000000:
                    SetDH(memoryBank[SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00111000: // BH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBH(memoryBank[SI]);
                    break;
                case 0b01000000:
                    SetBH(memoryBank[SI + ra]);
                    break;
                case 0b10000000:
                    SetBH(memoryBank[SI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBH(ra);
                    break;
                default: break;
                }
                break;
            default: break;
            }
            break; // 100
        case 0b00000101: // DI
            switch (rm & 0b00111000) // REG
            {
            case 0b00000000: // AL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAL(memoryBank[DI]);
                    break;
                case 0b01000000:
                    SetAL(memoryBank[DI + ra]);
                    break;
                case 0b10000000:
                    SetAL(memoryBank[DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00001000: // CL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCL(memoryBank[DI]);
                    break;
                case 0b01000000:
                    SetCL(memoryBank[DI + ra]);
                    break;
                case 0b10000000:
                    SetCL(memoryBank[DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00010000: // DL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDL(memoryBank[DI]);
                    break;
                case 0b01000000:
                    SetDL(memoryBank[DI + ra]);
                    break;
                case 0b10000000:
                    SetDL(memoryBank[DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00011000: // BL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBL(memoryBank[DI]);
                    break;
                case 0b01000000:
                    SetBL(memoryBank[DI + ra]);
                    break;
                case 0b10000000:
                    SetBL(memoryBank[DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00100000: // AH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAH(memoryBank[DI]);
                    break;
                case 0b01000000:
                    SetAH(memoryBank[DI + ra]);
                    break;
                case 0b10000000:
                    SetAH(memoryBank[DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00101000: // CH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCH(memoryBank[DI]);
                    break;
                case 0b01000000:
                    SetCH(memoryBank[DI + ra]);
                    break;
                case 0b10000000:
                    SetCH(memoryBank[DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00110000: // DH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDH(memoryBank[DI]);
                    break;
                case 0b01000000:
                    SetDH(memoryBank[DI + ra]);
                    break;
                case 0b10000000:
                    SetDH(memoryBank[DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00111000: // BH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBH(memoryBank[DI]);
                    break;
                case 0b01000000:
                    SetBH(memoryBank[DI + ra]);
                    break;
                case 0b10000000:
                    SetBH(memoryBank[DI + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBH(ra);
                    break;
                default: break;
                }
                break;
            default: break;
            }
            break; // 101
        case 0b00000110: // BP*
            switch (rm & 0b00111000) // REG
            {
            case 0b00000000: // AL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAL(memoryBank[BP]); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SetAL(memoryBank[BP + ra]);
                    break;
                case 0b10000000:
                    SetAL(memoryBank[BP + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00001000: // CL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCL(memoryBank[BP]); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SetCL(memoryBank[BP + ra]);
                    break;
                case 0b10000000:
                    SetCL(memoryBank[BP + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00010000: // DL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDL(memoryBank[BP]); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SetDL(memoryBank[BP + ra]);
                    break;
                case 0b10000000:
                    SetDL(memoryBank[BP + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00011000: // BL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBL(memoryBank[BP]); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SetBL(memoryBank[BP + ra]);
                    break;
                case 0b10000000:
                    SetBL(memoryBank[BP + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00100000: // AH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAH(memoryBank[BP]); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SetAH(memoryBank[BP + ra]);
                    break;
                case 0b10000000:
                    SetAH(memoryBank[BP + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00101000: // CH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCH(memoryBank[BP]); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SetCH(memoryBank[BP + ra]);
                    break;
                case 0b10000000:
                    SetCH(memoryBank[BP + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00110000: // DH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDH(memoryBank[BP]); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SetDH(memoryBank[BP + ra]);
                    break;
                case 0b10000000:
                    SetDH(memoryBank[BP + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00111000: // BH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBH(memoryBank[BP]); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SetBH(memoryBank[BP + ra]);
                    break;
                case 0b10000000:
                    SetBH(memoryBank[BP + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBH(ra);
                    break;
                default: break;
                }
                break;
            default: break;
            }
            break; // 110
        case 0b111: // BX
            switch (rm & 0b00111000) // REG
            {
            case 0b00000000: // AL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAL(memoryBank[BX]);
                    break;
                case 0b01000000:
                    SetAL(memoryBank[BX + ra]);
                    break;
                case 0b10000000:
                    SetAL(memoryBank[BX + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00001000: // CL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCL(memoryBank[BX]);
                    break;
                case 0b01000000:
                    SetCL(memoryBank[BX + ra]);
                    break;
                case 0b10000000:
                    SetCL(memoryBank[BX + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00010000: // DL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDL(memoryBank[BX]);
                    break;
                case 0b01000000:
                    SetDL(memoryBank[BX + ra]);
                    break;
                case 0b10000000:
                    SetDL(memoryBank[BX + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00011000: // BL
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBL(memoryBank[BX]);
                    break;
                case 0b01000000:
                    SetBL(memoryBank[BX + ra]);
                    break;
                case 0b10000000:
                    SetBL(memoryBank[BX + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBL(ra);
                    break;
                default: break;
                }
                break;
            case 0b00100000: // AH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetAH(memoryBank[BX]);
                    break;
                case 0b01000000:
                    SetAH(memoryBank[BX + ra]);
                    break;
                case 0b10000000:
                    SetAH(memoryBank[BX + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetAH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00101000: // CH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetCH(memoryBank[BX]); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SetCH(memoryBank[BX + ra]);
                    break;
                case 0b10000000:
                    SetCH(memoryBank[BX + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetCH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00110000: // DH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetDH(memoryBank[BX]);
                    break;
                case 0b01000000:
                    SetDH(memoryBank[BX + ra]);
                    break;
                case 0b10000000:
                    SetDH(memoryBank[BX + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetDH(ra);
                    break;
                default: break;
                }
                break;
            case 0b00111000: // BH
                switch (rm & 0b11000000) // MOD
                {
                case 0b00000000:
                    SetBH(memoryBank[BX]); // DIRECT ADDRESS
                    break;
                case 0b01000000:
                    SetBH(memoryBank[BX + ra]);
                    break;
                case 0b10000000:
                    SetBH(memoryBank[BX + FetchWord(IP + 2)]);
                    break;
                case 0b11000000:
                    SetBH(ra);
                    break;
                default: break;
                }
                break;
            default: break;
            }
            break; // 111
        default: break;
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
        byte rm = memoryBank[IP + 1];
        ushort add = FetchWord(IP + 2);
        if (rm & 0b00111000) // MOD 000 R/M only
        {
            // Raise illegal instruction
        }
        else
        {
            //TODO: Check if POP R/M16 was done correctly.
            switch (rm & 0b00000111)
            {
            case 0b000: // BX + SI
                switch (rm & 0b11000000)
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
                switch (rm & 0b11000000)
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
                switch (rm & 0b11000000)
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
                switch (rm & 0b11000000)
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
                switch (rm & 0b11000000)
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
                switch (rm & 0b11000000)
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
                switch (rm & 0b11000000)
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
                switch (rm & 0b11000000)
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
            default: break;
            }
        }
        IP += 4;
    }
        break;
    case 0x90: // NOP
        ++IP;
        break;
    case 0x91: // XCHG AX, CX

        break;
    case 0x92: // XCHG AX, DX

        break;
    case 0x93: // XCHG AX, BX

        break;
    case 0x94: // XCHG AX, SP

        break;
    case 0x95: // XCHG AX, BP

        break;
    case 0x96: // XCHG AX, SI

        break;
    case 0x97: // XCHG AX, DI

        break;
    case 0x98: // CBW
        if (GetAL() & 0b10000000)
            SetAH(0xFF);
        else
            SetAH(0);
        ++IP;
        break;
    case 0x99: // CWD
        if (AX & 0x8000)
            DX = 0xFFFF;
        else
            DX = 0;
        ++IP;
        break;
    case 0x9A: // CALL FAR_PROC

        break;
    case 0x9B: // WAIT

        break;
    case 0x9C: // PUSHF
        Push(GetFlagWord());
        ++IP;
        break;
    case 0x9D: // POPF
        SetFlagWord(Pop());
        ++IP;
        break;
    case 0x9E: // SAHF (AH to Flags)
        SetFlag(GetUpper(AX));
        ++IP;
        break;
    case 0x9F: // LAHF (Flags to AH)
        SetUpper(AX, GetFlag());
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
        SetAL(memoryBank[IP + 1]);
        IP += 2;
        break;
    case 0xB1: // MOV CL, IMM8
        SetCL(memoryBank[IP + 1]);
        IP += 2;
        break;
    case 0xB2: // MOV DL, IMM8
        SetDL(memoryBank[IP + 1]);
        IP += 2;
        break;
    case 0xB3: // MOV BL, IMM8
        SetBL(memoryBank[IP + 1]);
        IP += 2;
        break;
    case 0xB4: // MOV AH, IMM8
        SetAH(memoryBank[IP + 1]);
        IP += 2;
        break;
    case 0xB5: // MOV CH, IMM8
        SetCH(memoryBank[IP + 1]);
        IP += 2;
        break;
    case 0xB6: // MOV DH, IMM8
        SetDH(memoryBank[IP + 1]);
        IP += 2;
        break;
    case 0xB7: // MOV BH, IMM8
        SetBH(memoryBank[IP + 1]);
        IP += 2;
        break;
    case 0xB8: // MOV AX, IMM16
        AX = FetchWord(IP + 1);
        IP += 3;
        break;
    case 0xB9: // MOV CX, IMM16

        break;
    case 0xBA: // MOV DX, IMM16

        break;
    case 0xBB: // MOV BX, IMM16

        break;
    case 0xBC: // MOV SP, IMM16

        break;
    case 0xBD: // MOV BP, IMM16

        break;
    case 0xBE: // MOV SI, IMM16

        break;
    case 0xBF: // MOV DI, IMM16

        break;
    case 0xC2: // RET IMM16 (intrasegment)

        break;
    case 0xC3: // RET (intrasegment)

        break;
    case 0xC4: // LES REG16, MEM16

        break;
    case 0xC5: // LDS REG16, MEM16

        break;
    case 0xC6: // MOV MEM8, IMM8
        // MOD 000 R/M only
        break;
    case 0xC7: // MOV MEM16, IMM16
        // MOD 000 R/M only
        break;
    case 0xCA: // RET IMM16 (intersegment)

        break;
    case 0xCB: // RET (intersegment)

        break;
    case 0xCC: // INT 3

        break;
    case 0xCD: // INT IMM8

        break;
    case 0xCE: // INTO
        
        break;
    case 0xCF: // IRET
        IP = Pop();
        CS = Pop();
        SetFlagWord(Pop());
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
        byte tempAL = GetAL();
        SetAH(tempAL / 0xA);
        SetAL(tempAL % 0xA);
        IP += 2;
    }
        break;
    case 0xD5: { // AAD
        byte tempAL = GetAL();
        byte tempAH = GetAH();
        SetAL((tempAL + (tempAH * 0xA)) & 0xFF);
        SetAH(0);
        IP += 2;
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

        break;
    case 0xE9: // JMP  NEAR-LABEL

        break;
    case 0xEA: // JMP  FAR-LABEL

        break;
    case 0xEB: // JMP  SHORT-LABEL

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
        // Raise vector
        break;
    }
}

// Page 2-99 contains the IF message processor



void Intel8086::Push(ushort value)
{
	SP -= 2;
	uint addr = GetPhysicalAddress(SS, SP);
	*((ushort *)&memoryBank[addr]) = value;
}

ushort Intel8086::Pop()
{
	uint addr = GetPhysicalAddress(SS, SP);
	SP += 2;
	return *((ushort *)&memoryBank[addr]);
}

uint inline Intel8086::GetPhysicalAddress(ushort segment, ushort offset)
{
	return (segment << 4) + offset;
}

/// <summary>
/// Raise hardware IF.
/// <summary>
void Intel8086::Raise(byte IF)
{
    switch (IF)
    {
    case 0x21: // MS-DOS Services
        switch (GetAH())
        {
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

            break;
        /*
         * 02h - Write character to stdout.
         * Input: DL (Character)
         * Return: AL (Last character)
         * 
         * Notes:
         * - ^C and ^Break are checked.
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

            break;
        /*
         * 0Ah - Buffered input.
         * Input: DS:DX (See Buffer)
         * Return: Buffer filled with used input.
         *
         * Notes:
         * - ^C and ^Break are checked.
         * - Reads from stdin.
         *
         * Buffer:
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
         * 2Ah - Get system date.
         * Input: None.
         * Return:
         *   CX (Year, 1980-2099)
         *   DH (Month)
         *   DL (Day)
         *   AL (Day of the week, Sunday = 0)
         */
        case 0x2A:

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
         *   BH (Version flag bit 3: DOS is in ROM other: reserved (0))
         *
         * *Most versions do not use this.
         */
        case 0x30:

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
         * 4Ch - Terminate with return code.
         * Input: AL (Return code)
         * Return: None. (Never returns)
         *
         * Notes:
         * - Unless the process is its own parent, all open files are closed
         *     and all memory belonging to the process is freed.
         */
        case 0x4C:

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
    default: break;
    }
}

ushort Intel8086::FetchWord(uint addr) {
    return *((ushort *)&memoryBank[addr]);
}

void Intel8086::SetWord(uint addr, ushort value) {
    *((ushort *)&memoryBank[addr]) = value;
}

byte Intel8086::GetFlag()
{
    return
        SF ? 0x80 : 0 |
        ZF ? 0x40 : 0 |
        AF ? 0x10 : 0 |
        PF ? 0x4  : 0 |
        CF ? 1    : 0;
}

void Intel8086::SetFlag(byte flag)
{
    SF = (flag & 0x80) != 0;
    ZF = (flag & 0x40) != 0;
    AF = (flag & 0x10) != 0;
    PF = (flag & 0x4 ) != 0;
    CF = (flag & 1   ) != 0;
}

ushort Intel8086::GetFlagWord()
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

void Intel8086::SetFlagWord(ushort flag)
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