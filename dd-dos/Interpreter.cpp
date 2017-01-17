/*
 * Interpreter.cpp: Legacy machine code interpreter. Mimics an Intel 8086.
 */

#include <cstdlib>

#include "dd-dos.hpp"

// Page 4-36 of the Intel 8086 User Manual contains opcode map.
enum Op : byte {


    MovToAX = 0xB8,


};

const uint MAX_MEMORY = 0x100000; // 1 MB

static void Boot() {
    MemoryBank = (byte*)std::malloc(MAX_MEMORY);
}

// Should be returning something for error checking.
// Should be for accessing executables outside of VM
/*void Start(wchar_t *filename) {

}*/

/*
 * Intel 8086 Registers
 */
static ushort
    AX, BX, CX, DX,
    SI, DI, BP, SP,
    IP,
    CS, DS, ES, SS;

static byte *MemoryBank;

// void PushStack ?

void Execute(ushort op) {
    byte *por = (byte*)&op;

    switch ((Op)(por[0])) {
    
    
    case Op::MovToAX:

        break;


    default: // Illegal instruction
        
        break;
    }


}

// Page 2-99 contains the interrupt message processor