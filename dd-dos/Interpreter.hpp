/*
 * Interpreter.hpp
 */

#pragma once

#include <string>

using byte = unsigned char;
using ushort = unsigned short;
using uint = unsigned int;

static const uint MAX_MEMORY = 0x100000; // 1 MB

/*
* Intel 8086 Registers
*/
struct Intel8086Registers
{
	ushort
		AX, BX, CX, DX,
		SI, DI, BP, SP,
		IP,
		CS, DS, ES, SS;

	Intel8086Registers()
		: AX(0), BX(0), CX(0), DX(0),
		SI(0), DI(0), BP(0), SP(0), IP(0),
		CS(0), DS(0), ES(0), SS(0) {}
};

class Intel8086
{
public:
	Intel8086();
	~Intel8086();

	void Load(const std::string &file);
	void ExecuteInstruction(ushort op);

private:
	byte *memoryBank;
	Intel8086Registers registers;
};