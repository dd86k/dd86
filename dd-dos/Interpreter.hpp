/*
 * Interpreter.hpp
 */

#pragma once

#include <string>

// Ala C#
using byte = unsigned char;
using ushort = unsigned short;
using uint = unsigned int;

static const uint MAX_MEMORY = 0x100000; // 1 MB

class Intel8086
{
public:
	Intel8086();
	~Intel8086();

    void Init(const std::string &file);
    //void Open(const std::string &file);
    void Reset();
	void ExecuteInstruction(byte);

	void Push(ushort value);
	ushort Pop();

	uint GetPhysicalAddress(ushort segment, ushort offset);

private:
    void Raise(byte);
    ushort FetchWord(uint location);
    ushort GetFlag();

    byte GetAL();
    void SetAL(byte);

	byte *memoryBank;
    ushort
        // Generic registers
        AX, BX, CX, DX,
        // Index registers :
        // - SI: Source Index
        // - DI: Destination Index
        // - BP: Base Pointer
        // - SP: Stack Pointer
        SI, DI, BP, SP,
        // Segment registers, points to a segment (Max 64KB).
        CS, DS, ES, SS,
        // Program Counter (PC)
        IP;
	bool // From bit 15 to 0:
		Overflow,  // 11 - OF
		Direction, // 10 - DF
		Interrupt, //  9 - IF
		Trap,      //  8 - TF
		Sign,      //  7 - SF
		Zero,      //  6 - ZF
		Auxiliary, //  4 - AF
		Parity,    //  2 - PF
		Carry;     //  0 - CF
};