/*
 * Interpreter.hpp
 */

#pragma once

#include <string>
#include "Utils.hpp"

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
    ushort FetchWord(uint addr);
    void SetWord(uint addr, ushort value);

    byte GetFlag();
    void SetFlag(byte);
    ushort GetFlagWord();
    void SetFlagWord(ushort);

    /*
     * AL/AH
     */
    byte GetAL();
    void SetAL(byte);
    byte GetAH();
    void SetAH(byte);

    /*
     * CL/CH
     */
    byte GetCL();
    void SetCL(byte);
    byte GetCH();
    void SetCH(byte);

    /*
     * DL/DH
     */
    byte GetDL();
    void SetDL(byte);
    byte GetDH();
    void SetDH(byte);

    /*
     * CL/CH
     */
    byte GetBL();
    void SetBL(byte);
    byte GetBH();
    void SetBH(byte);

	byte *memoryBank;

    ushort
        // Generic registers
        AX, BX, CX, DX,
        // Index registers
        SI, DI, BP, SP,
        // Segment registers
        CS, DS, ES, SS,
        // Program Counter
        IP;
    bool // FLAG
        OF, // 11, Overflow Flag
        DF, // 10, Direction Flag
        IF, //  9, Interrupt Enable Flag
        TF, //  8, Trap Flag
        SF, //  7, Sign Flag
        ZF, //  6, Zero Flag
        AF, //  4, Auxiliary Carry Flag (aka Adjust Flag)
        PF, //  2, Parity Flag
        CF; //  0, Carry Flag
};