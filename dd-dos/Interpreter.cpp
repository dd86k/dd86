/*
 * Interpreter.cpp: Legacy machine code interpreter. Mimics an Intel 8086.
 * 
 * Architecture: (Page 2-3)
 * 1. Fetch the next instruction from memory.
 * 2. Read an operand (if instruction demands).
 * 3. Execute.
 * 4. Write results (if instruction demands).
 */

/*
 * ModR/M Byte:
 * |
 * (To write)
 */

#include <iostream>
#include <cstdlib>
#include <cstring>

#include "Interpreter.hpp"
#include "dd-dos.hpp" // For Con

//NOTE: Opened files should go in JFT

Intel8086::Intel8086()
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

}

/// <summary>
/// Opens a file from the host and adjusts the virtual program's PSP.JFT.
/// </summary>
/*void Intel8086::Open(const std::string &filename)
{


}*/

//TODO: Need to find RESET again.
void Intel8086::Reset() {
    CS = 0xFFFF;
}

// Should return something for error checking.
// Should be for accessing executables outside of VM
/*void Start(wchar_t *filename) {

}*/

// void PushStack ?

/// <summary>
/// Execute the operation code. (ALU)
/// </summary>
/// <remark>
/// Queue-Bus (Q-BUS) is one byte large.
/// Page 4-27 (P169) of the Intel 8086 User Manual
/// contains decoding guide.
/// </remark>
void Intel8086::ExecuteInstruction(byte op)
{
    /*
     * Legend:
     * R/M: ModRegister/Memory Byte
     * IMM: Immediate value
     * IMMD: ?
     * REG: Register
     * MEM: Memory location
     * SEGREG: Segment register
     *
     * The number represents bitness.
     */
    //TODO: Will probably need to group instructions.
    switch (op) {
    case 0x00: // ADD R/M8, REG8

        break;
    case 0x01: // ADD R/M16, REG16

        break;
    case 0x02: // ADD REG8, R/M8

        break;
    case 0x03: // ADD REG16, R/M16

        break;
    case 0x04: // ADD AL, IMM8

        break;
    case 0x05: // ADD AX, IMM16

        break;
    case 0x06: // PUSH ES

        break;
    case 0x07: // POP ES

        break;
    case 0x08: // OR R/M8, REG8

        break;
    case 0x09: // OR R/M16, REG16

        break;
    case 0x0A: // OR REG8, R/M8

        break;
    case 0x0B: // OR REG16, R/M16

        break;
    case 0x0C: // OR AL, IMM8

        break;
    case 0x0D: // OR AX, IMM16

        break;
    case 0x0E: // PUSH CS

        break;
    case 0x10: // ADC R/M8, REG8

        break;
    case 0x11: // ADC R/M16, REG16

        break;
    case 0x12: // ADC REG8, R/M8

        break;
    case 0x13: // ADC REG16, R/M16

        break;
    case 0x14: // ADC AL, IMM8

        break;
    case 0x15: // ADC AX, IMM16

        break;
    case 0x16: // PUSH SS

        break;
    case 0x17: // POP SS

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

        break;
    case 0x1F: // POP DS

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

        break;
    case 0x27: // DAA

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
    case 0x2F: // DAS

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
    case 0x3F: // AAS

        break;
    case 0x40: // INC AX

        break;
    case 0x41: // INC CX

        break;
    case 0x42: // INC DX

        break;
    case 0x43: // INC BX

        break;
    case 0x44: // INC SP

        break;
    case 0x45: // INC BP

        break;
    case 0x46: // INC SI

        break;
    case 0x47: // INC DI

        break;
    case 0x48: // DEC AX

        break;
    case 0x49: // DEC CX

        break;
    case 0x4A: // DEC DX

        break;
    case 0x4B: // DEC BX

        break;
    case 0x4C: // DEC SP

        break;
    case 0x4D: // DEC BP

        break;
    case 0x4E: // DEC SI

        break;
    case 0x4F: // DEC DI

        break;
    case 0x50: // PUSH AX

        break;
    case 0x51: // PUSH CX

        break;
    case 0x52: // PUSH DX

        break;
    case 0x53: // PUSH BX

        break;
    case 0x54: // PUSH SP

        break;
    case 0x55: // PUSH BP

        break;
    case 0x56: // PUSH SI

        break;
    case 0x57: // PUSH DI

        break;
    case 0x58: // POP AX

        break;
    case 0x59: // POP CX

        break;
    case 0x5A: // POP DX

        break;
    case 0x5B: // POP BX

        break;
    case 0x5C: // POP SP

        break;
    case 0x5D: // POP BP

        break;
    case 0x5E: // POP SI

        break;
    case 0x5F: // POP DI

        break;
    case 0x70: // JO    SHORT-LABEL

        break;
    case 0x71: // JNO   SHORT-LABEL

        break;
    case 0x72: // JB/JNAE/JC    SHORT-LABEL

        break;
    case 0x73: // JNB/JAE/JNC   SHORT-LABEL

        break;
    case 0x74: // JE/JZ     SHORT-LABEL

        break;
    case 0x75: // JNE/JNZ   SHORT-LABEL

        break;
    case 0x76: // JBE/JNA   SHORT-LABEL

        break;
    case 0x77: // JNBE/JA   SHORT-LABEL

        break;
    case 0x78: // JS        SHORT-LABEL

        break;
    case 0x79: // JNS       SHORT-LABEL

        break;
    case 0x7A: // JP/JPE    SHORT-LABEL

        break;
    case 0x7B: // JNP/JPO   SHORT-LABEL

        break;
    case 0x7C: // JL/JNGE   SHORT-LABEL

        break;
    case 0x7D: // JNL/JGE   SHORT-LABEL

        break;
    case 0x7E: // JLE/JNG   SHORT-LABEL

        break;
    case 0x7F: // JNLE/JG   SHORT-LABEL

        break;
    case 0x80: // GRP1 R/M8, IMM8
        /*byte rm; // Get ModR/M byte
        switch (rm & 0b00111000) { // ModRM REG (I think)
        case 0x00: // 000 - ADD

            break;
        case 0x08: // 001 - OR

            break;
        case 0x10: // 010 - ADC

            break;
        case 0x18: // 011 - SBB

            break;
        case 0x20: // 100 - AND

            break;
        case 0x28: // 101 - SUB

            break;
        case 0x30: // 110 - XOR

            break;
        case 0x38: // 111 - CMP

            break;
        default: break;
        }*/
        break;
    case 0x81: // GRP1 R/M16, IMM16
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
    case 0x82: // GRP1 R/M8, IMMD8
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
    case 0x83: // GRP1 R/M16, IMMD8
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
    case 0x88: // MOV R/M8, REG8

        break;
    case 0x89: // MOV R/M16, REG16

        break;
    case 0x8A: // MOV REG8, R/M8

        break;
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
    case 0x8F: // POP R/M16
        // MOD 000 R/M only

        break;
    case 0x90: // NOP

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

        break;
    case 0x99: // CWD

        break;
    case 0x9A: // CALL FAR_PROC

        break;
    case 0x9B: // WAIT

        break;
    case 0x9C: // PUSHF

        break;
    case 0x9D: // POPF

        break;
    case 0x9E: // SAHF

        break;
    case 0x9F: // LAHF

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






    
    case 0xB8:
        AX = memoryBank[IP + 1];

        IP += 2; //TODO: Needs to investigate PC usage
        break;


    default: // Illegal instruction
        // Raise vector
        break;
    }
}

// Page 2-99 contains the interrupt message processor