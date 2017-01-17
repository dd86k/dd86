/*
 * Interpreter.hpp
 */

#pragma once

using byte = unsigned char;
using ushort = unsigned short;
using uint = unsigned int;

/*
* Intel 8086 Registers
*/
static ushort
    AX, BX, CX, DX,
    SI, DI, BP, SP,
    IP,
    CS, DS, ES, SS;

static byte *MemoryBank;

const uint MAX_MEMORY = 0x100000; // 1 MB

void Boot();