/*
 * Interpreter.hpp
 */

#pragma once

#include <string>

using byte = unsigned char;
using ushort = unsigned short;
using uint = unsigned int;

static const uint MAX_MEMORY = 0x100000; // 1 MB

class Intel8086
{
public:
	Intel8086();
	~Intel8086();

    void Load(const std::string &file);
    void Open(const std::string &file);
	void ExecuteInstruction(ushort op);

private:
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
        // Segment registers, points to a 64KB segment.
        CS, DS, ES, SS,
        // Program Counter (PC)
        IP;
};