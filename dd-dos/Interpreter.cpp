/*
 * Interpreter.cpp: Legacy machine code interpreter. Mimics an Intel 8086.
 * 
 * Architecture: (Page 2-3)
 * 1. Fetch the next instruction from memory.
 * 2. Read an operand (if instruction demands).
 * 3. Execute.
 * 4. Write results (if instruction demands).
 */

#include <iostream>
#include <cstdlib>
#include <cstring>

#include "Interpreter.hpp"

//NOTE: Opened files should go in JFT

// Page 4-36 of the Intel 8086 User Manual contains opcode map.
enum Op : byte {
    MovToAX = 0xB8,
};

enum ModRM : byte {

};

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
void Intel8086::Load(const std::string &filename)
{
	// Intel 8086 code


    // DD-DOS Init code
    std::cout << "Starting DD-DOS..." << std::endl;

    /*if (&filename != NULL)
        Open(filename);*/

    // Loop while on

}

/// <summary>
/// Opens a file from the host and adjusts the virtual program's PSP.JFT.
/// </summary>
/*void Intel8086::Open(const std::string &filename)
{


}*/

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
        AX = memoryBank[IP + 1];

        IP += 2; //TODO: Needs to investigate PC usage
        break;


    default: // Illegal instruction
        // Raise vector
        break;
    }
}

// Page 2-99 contains the interrupt message processor