import vcpu, vcpu_utils, std.stdio, vdos, std.file : exists;
import test_utils;

unittest
{
    section("DD-DOS (MS-DOS, IBM PC)");

    /*
     * Hardware (and/or BIOS)
     */

    // MEMORY SIZE

    test("INT 12h");
    Raise(0x12);
    assert(MEMORYSIZE / 1024 == vCPU.AX);
    writeln("OK  (", vCPU.AX, " KB)");

    /*
     * Software (Other)
     */

    // FAST CONSOLE OUTPUT (DOS)

    test("INT 29h");
    vCPU.AL = 'O';
    Raise(0x29);
    vCPU.AL = 'K';
    Raise(0x29);
    vCPU.AL = '\n';
    Raise(0x29);

    /*
     * MS-DOS Services
     */

    // FAST CONSOLE OUTPUT (MS-DOS)

    test("INT 21h  AX=0200h");
    vCPU.AH = 2;
    vCPU.DL = 'O';
    Raise(0x21);
    vCPU.DL = 'K';
    Raise(0x21);
    vCPU.DL = '\n';
    Raise(0x21);

    // PRINT STRING

    test("INT 21h  AX=0900h");
    vCPU.DS = vCPU.CS = 0x400;
    vCPU.DX = 0x20; vCPU.IP = 0x20;
    vCPU.EIP = get_ip;
    __istr("OK\n$");
    vCPU.AH = 9;
    Raise(0x21);
    assert(vCPU.AL == 0x24);

    // GET DATE

    test("INT 21h  AX=2A00h");
    vCPU.AH = 0x2A;
    Raise(0x21);
    switch (vCPU.AL) {
    case 0, 7: write("Sunday"); break;
    case 1: write("Monday"); break;
    case 2: write("Tuesday"); break;
    case 3: write("Wednesday"); break;
    case 4: write("Thursday"); break;
    case 5: write("Friday"); break;
    case 6: write("Saturday"); break;
    default: assert(0);
    }
    writefln(" %d-%02d-%02d", vCPU.CX, vCPU.DH, vCPU.DL);

    // GET TIME

    test("INT 21h  AX=2C00h");
    vCPU.AH = 0x2C;
    Raise(0x21);
    writefln("%02d:%02d:%02d.%d", vCPU.CH, vCPU.CL, vCPU.DH, vCPU.DL);

    // GET VERSION

    test("INT 21h  AX=3000h");
    vCPU.AL = 0;
    vCPU.AH = 0x30;
    Raise(0x21);
    assert(vCPU.AH == DOS_MINOR_VERSION);
    assert(vCPU.AL == DOS_MAJOR_VERSION);
    assert(vCPU.BH == OEM_ID.IBM);
    OK;

    // CREATE SUBDIRECTORY

    /*test("INT 21h->39_00h");
    vCPU.DS = vCPU.CS; vCPU.DX = vCPU.IP;
    __istr("TESTDIR\0");
    vCPU.AH = 0x39;
    Raise(0x21);
    assert(exists("TESTDIR"));
    OK;

    // REMOVE SUBDIRECTORY

    test("INT 21h->3A_00h");
    vCPU.AH = 0x3A;
    Raise(0x21);
    assert(!exists("TESTDIR"));
    OK;

    // CREATE/TRUNC FILE

    test("INT 21h->3C_00h");
    __istr("TESTFILE\0");
    vCPU.CL = 0; // No attributes
    vCPU.AH = 0x3C;
    Raise(0x21);
    assert(exists("TESTFILE"));
    //vCPU.CL = 32; // Archive
    //Raise(0x21); // On TESTFILE again
    OK;

    // OPEN FILE

    // READ FILE

    // WRITE TO FILE/DEVICE

    // RENAME FILE

    // DELETE FILE

    test("INT 21h->41_00h");
    vCPU.CL = 0;
    vCPU.AH = 0x41;
    Raise(0x21);
    assert(!exists("TESTFILE"));
    OK;*/

    // GET FREE DISK SPACE

    /*test("INT 21h->36_00h");
    vCPU.DL = 2; // C:
    vCPU.AH = 0x36;
    Raise(0x21);
    OK;*/

    writeln; // usually run last so unittest results have their own line
}