module vdosTests;

import vcpu, vcpuutils, std.stdio, vdos, std.file : exists;
import unitutils;

unittest
{
    section("DD-DOS (MS-DOS, IBM PC)");

    /*
     * Hardware (and/or BIOS)
     */

    // MEMORY SIZE

    test("INT 12h");
    Raise(0x12);
    assert(MEMORYSIZE / 1024 == AX);
    writeln("OK  (", AX, " KB)");

    /*
     * Software (Other)
     */

    // FAST CONSOLE OUTPUT (DOS)

    test("INT 29h");
    AL = 'O';
    Raise(0x29);
    AL = 'K';
    Raise(0x29);
    AL = '\n';
    Raise(0x29);

    /*
     * MS-DOS Services
     */

    // FAST CONSOLE OUTPUT (MS-DOS)

    test("INT 21h->02_00h");
    AH = 2;
    DL = 'O';
    Raise(0x21);
    DL = 'K';
    Raise(0x21);
    DL = '\n';
    Raise(0x21);

    // PRINT STRING

    test("INT 21h->09_00h");
    DS = CS = 0x400;
    DX = 0x20; IP = 0x20;
    EIP = get_ip;
    __istr("OK\n$");
    AH = 9;
    Raise(0x21);
    assert(AL == 0x24);

    // GET DATE

    test("INT 21h->2A_00h");
    AH = 0x2A;
    Raise(0x21);
    switch (AL) {
    case 0, 7: write("Sunday"); break;
    case 1: write("Monday"); break;
    case 2: write("Tuesday"); break;
    case 3: write("Wednesday"); break;
    case 4: write("Thursday"); break;
    case 5: write("Friday"); break;
    case 6: write("Saturday"); break;
    default: assert(0);
    }
    writefln(" %d-%02d-%02d", CX, DH, DL);

    // GET TIME

    test("INT 21h->2C_00h");
    AH = 0x2C;
    Raise(0x21);
    writefln("%02d:%02d:%02d.%d", CH, CL, DH, DL);

    // GET VERSION

    test("INT 21h->30_00h");
    AL = 0;
    AH = 0x30;
    Raise(0x21);
    assert(AH == DOS_MINOR_VERSION);
    assert(AL == DOS_MAJOR_VERSION);
    assert(BH == OEM_ID.IBM);
    OK;

    // CREATE SUBDIRECTORY

    /*test("INT 21h->39_00h");
    DS = CS; DX = IP;
    __istr("TESTDIR\0");
    AH = 0x39;
    Raise(0x21);
    assert(exists("TESTDIR"));
    OK;

    // REMOVE SUBDIRECTORY

    test("INT 21h->3A_00h");
    AH = 0x3A;
    Raise(0x21);
    assert(!exists("TESTDIR"));
    OK;

    // CREATE/TRUNC FILE

    test("INT 21h->3C_00h");
    __istr("TESTFILE\0");
    CL = 0; // No attributes
    AH = 0x3C;
    Raise(0x21);
    assert(exists("TESTFILE"));
    //CL = 32; // Archive
    //Raise(0x21); // On TESTFILE again
    OK;

    // OPEN FILE

    // READ FILE

    // WRITE TO FILE/DEVICE

    // RENAME FILE

    // DELETE FILE

    test("INT 21h->41_00h");
    CL = 0;
    AH = 0x41;
    Raise(0x21);
    assert(!exists("TESTFILE"));
    OK;*/

    // GET FREE DISK SPACE

    /*test("INT 21h->36_00h");
    DL = 2; // C:
    AH = 0x36;
    Raise(0x21);
    OK;*/

    writeln; // usually run last so unittest results have their own line
}