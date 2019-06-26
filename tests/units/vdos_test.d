import test_utils;
import std.stdio;
import vcpu.core : CPU;
import vdos.os, vdos.interrupts;

unittest {
	section("DOS (MS-DOS, IBM PC)");

	/*
	 * Hardware (and/or BIOS)
	 */

	// MEMORY SIZE

	test("INT 12h");
	INT(0x12);
	assert(SYSTEM.memsize == CPU.AX);
	writeln("OK  (", CPU.AX, " KB)");

	test("INT 1Ah  AH=00h");
	CPU.AH = 0;
	INT(0x1A);
	writefln("assuming OK (CS=%04X DX=%04X -- %u)", CPU.CS, CPU.DX, (CPU.CS << 16) | CPU.DX);

	/*
	 * MS-DOS Services
	 */

	// GET DATE

	test("INT 21h  AX=2A00h");
	CPU.AH = 0x2A;
	INT(0x21);
	switch (CPU.AL) {
	case 0, 7: write("Sunday"); break;
	case 1: write("Monday"); break;
	case 2: write("Tuesday"); break;
	case 3: write("Wednesday"); break;
	case 4: write("Thursday"); break;
	case 5: write("Friday"); break;
	case 6: write("Saturday"); break;
	default: assert(0);
	}
	writefln(" %u-%02d-%02d", CPU.CX, CPU.DH, CPU.DL);

	// GET TIME

	test("INT 21h  AX=2C00h");
	CPU.AH = 0x2C;
	INT(0x21);
	writefln("%02u:%02u:%02u.%u", CPU.CH, CPU.CL, CPU.DH, CPU.DL);

	// GET VERSION

	test("INT 21h  AX=3000h");
	CPU.AL = 0;
	CPU.AH = 0x30;
	INT(0x21);
	assert(CPU.AH == DOS_MINOR_VERSION);
	assert(CPU.AL == DOS_MAJOR_VERSION);
	assert(CPU.BH == OEM_ID.IBM);
	OK;

	// CREATE SUBDIRECTORY

	/*test("INT 21h->39_00h");
	CPU.DS = CPU.CS; CPU.DX = CPU.IP;
	mmistr("TESTDIR\0");
	CPU.AH = 0x39;
	INT(0x21);
	assert(exists("TESTDIR"));
	OK;

	// REMOVE SUBDIRECTORY

	test("INT 21h->3A_00h");
	CPU.AH = 0x3A;
	INT(0x21);
	assert(!exists("TESTDIR"));
	OK;

	// CREATE/TRUNC FILE

	test("INT 21h->3C_00h");
	mmistr("TESTFILE\0");
	CPU.CL = 0; // No attributes
	CPU.AH = 0x3C;
	INT(0x21);
	assert(exists("TESTFILE"));
	//CPU.CL = 32; // Archive
	//INT(0x21); // On TESTFILE again
	OK;

	// OPEN FILE

	// READ FILE

	// WRITE TO FILE/DEVICE

	// RENAME FILE

	// DELETE FILE

	test("INT 21h->41_00h");
	CPU.CL = 0;
	CPU.AH = 0x41;
	INT(0x21);
	assert(!exists("TESTFILE"));
	OK;*/

	// GET FREE DISK SPACE

	/*test("INT 21h->36_00h");
	CPU.DL = 2; // C:
	CPU.AH = 0x36;
	INT(0x21);
	OK;*/
}