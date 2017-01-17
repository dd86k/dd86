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
	void ExecuteInstruction(ushort op);

private:
	byte *memoryBank;
    ushort
        AX, BX, CX, DX,
        SI, DI, BP, SP,
        IP,
        CS, DS, ES, SS;
};