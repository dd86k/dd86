/*
 * Interpreter.cpp: Legacy machine code interpreter. Mimics an Intel 8086.
 */

#include <cstdlib>
#include <cstring>

#include "Interpreter.hpp"

//NOTE: Opened files should go in JFT

// Page 4-36 of the Intel 8086 User Manual contains opcode map.
enum Op : byte {
    MovToAX = 0xB8,
};

Intel8086::Intel8086()
{
	memoryBank = (byte *)std::calloc(1, MAX_MEMORY);
}

Intel8086::~Intel8086()
{
	delete memoryBank;
}

void Intel8086::Load(const std::string &file)
{
	// Intel 8086 code


    // DD-DOS Init code
}

// Should return something for error checking.
// Should be for accessing executables outside of VM
/*void Start(wchar_t *filename) {

}*/

// void PushStack ?

void Intel8086::ExecuteInstruction(ushort op)
{
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