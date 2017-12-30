module dd_dosTests;

import Interpreter, InterpreterUtils, std.stdio, dd_dos, std.file : exists;

unittest
{
    writeln("---------- DD-DOS (MS-DOS, IBM PC)");

    /*
     * Hardware (and/or BIOS)
     */

    // MEMORY SIZE

    write("INT 12h: ");
    Raise(0x12);
    assert(MEMORYSIZE / 1024 == AX);
    writeln("OK  (", AX, " KB)");

    /*
     * Software (Other)
     */

    // FAST CONSOLE OUTPUT (DOS)

    write("INT 29h: ");
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

    write("INT 21h->02_00h: ");
    AH = 2;
    DL = 'O';
    Raise(0x21);
    DL = 'K';
    Raise(0x21);
    DL = '\n';
    Raise(0x21);

    // "HELLO WORLD"

    write("INT 21h->09_00h: ");
    DS = CS = 0x400;
    DX = EIP = 0x20;
    Insert("OK\n$");
    AH = 9;
    Raise(0x21);
    assert(AL == 0x24);

    // GET DATE

    write("INT 21h->2A_00h: ");
    AH = 0x2A;
    Raise(0x21);
    write("(D/M/Y) ");
    final switch (AL) {
    case 0, 7: write("Sunday"); break;
    case 1: write("Monday"); break;
    case 2: write("Tuesday"); break;
    case 3: write("Wednesday"); break;
    case 4: write("Thursday"); break;
    case 5: write("Friday"); break;
    case 6: write("Saturday"); break;
    }
    writefln(" %d/%d/%d", DL, DH, CX);

    // GET TIME

    write("INT 21h->2C_00h: ");
    AH = 0x2C;
    Raise(0x21);
    writefln("(H:M:S) %d:%d:%d.%d", CH, CL, DH, DL);

    // GET VERSION

    write("INT 21h->30_00h: ");
    AL = 0;
    AH = 0x30;
    Raise(0x21);
    assert(AH == DOS_MINOR_VERSION);
    assert(AL == DOS_MAJOR_VERSION);
    assert(BH == OEM_ID.IBM);
    writeln("OK");

    // CREATE SUBDIRECTORY

    write("INT 21h->39_00h: ");
    DS = CS; DX = IP;
    Insert("TESTDIR\0");
    AH = 0x39;
    Raise(0x21);
    assert(exists("TESTDIR"));
    writeln("OK");

    // REMOVE SUBDIRECTORY

    write("INT 21h->3A_00h: ");
    AH = 0x3A;
    Raise(0x21);
    assert(!exists("TESTDIR"));
    writeln("OK");

    // CREATE/TRUNC FILE

    write("INT 21h->3C_00h: ");
    Insert("TESTFILE\0");
    CL = 0; // No attributes
    AH = 0x3C;
    Raise(0x21);
    assert(exists("TESTFILE"));
    //CL = 32; // Archive
    //Raise(0x21); // On TESTFILE again
    writeln("OK");

    // OPEN FILE

    // READ FILE

    // WRITE TO FILE/DEVICE

    // RENAME FILE

    // DELETE FILE

    write("INT 21h->41_00h: ");
    CL = 0;
    AH = 0x41;
    Raise(0x21);
    assert(!exists("TESTFILE"));
    writeln("OK");

    // GET FREE DISK SPACE

    /*write("INT 21h->36_00h: ");
    DL = 2; // C:
    AH = 0x36;
    Raise(0x21);
    writeln("OK");*/
}