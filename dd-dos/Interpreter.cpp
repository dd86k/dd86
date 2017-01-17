/*
 * Interpreter.cpp: Legacy machine code interpreter. Mimics an Intel 8086.
 */

#include <cstdlib>

#include "Interpreter.hpp"

//NOTE: Opened files should go in JFT

// Page 4-36 of the Intel 8086 User Manual contains opcode map.
enum Op : byte {


    MovToAX = 0xB8,


};

static void Boot() {
    MemoryBank = (byte*)std::malloc(MAX_MEMORY);

    // Intel 8086 code


    // DD-DOS Init code

}

// Should return something for error checking.
// Should be for accessing executables outside of VM
/*void Start(wchar_t *filename) {

}*/

// void PushStack ?

void Execute(ushort op) {
    byte *por = (byte*)&op;

    switch ((Op)(por[0])) {
    
    
    case Op::MovToAX:

        break;


    default: // Illegal instruction
        // Raise vector
        break;
    }


}

// Page 2-99 contains the interrupt message processor