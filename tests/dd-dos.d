module DD_DOSTests;

import Interpreter, std.stdio, dd_dos;

unittest
{
    writeln("---------- DD-DOS");

    machine = new Intel8086();

    with (machine) {
        Verbose = true;
        FullReset();

        /*
         * First half is the hardware and generic software interrupts while
         * the rest is the MS-DOS API (AH=21h)
         */

        // MEMORY SIZE
        
        write("INT 12h: ");
        Raise(0x12);
        assert(memoryBank.length / 1024 == AX);
        writeln("OK -- ", AX, " KB");

        // FAST CONSOLE OUTPUT
        
        write("INT 29h: ");
        AL = 'O';
        Raise(0x29);
        AL = 'K';
        Raise(0x29);
        AL = '\n';
        Raise(0x29);

        // HELLO WORLD
        
        write("INT 21h->09_00h: ");
        Insert("OK\n$");
        DS = CS; DX = IP;
        AH = 9;
        Raise(0x21);
        assert(AL == 0x24);

        // GET DATE

        write("INT 21h->2A_00h: ");
        AH = 0x2A;
        Raise(0x21);
        writefln("(D/M/Y) %d/%d/%d Weekday=%d", DL, DH, CX, AL);

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
    }
}