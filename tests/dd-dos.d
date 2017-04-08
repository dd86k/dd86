module DD_DOSTests;

import Interpreter, std.stdio, dd_dos;

unittest
{
    writeln("** DD-DOS **");

    machine = new Intel8086();

    with (machine) {
        Verbose = true;
        FullReset();
        /***************
         * Hello World *
         ***************/
        
        write("INT 21h->0900h: ");

        // Hello World. Offset: 0, Address: CS:0100
        CS = 0; IP = 0x100;
        Insert("OK\n$", 0xE);
        Execute(0x0E); // push CS
        Execute(0x1F); // pop DS
        Insert(0x10E, 1);
        Execute(0xBA); // mov DX, 10Eh ;[msg]
        Insert(0x9, 1);
        Execute(0xB4); // mov AH, 9    ;print()
        Insert(0x21, 1);
        Execute(0xCD); // int 21h
        assert(AL == 0x24);
        Insert(0x4C01, 1);
        Execute(0xB8); // mov AX 4C01h ;return 1
        Insert(0x21, 1);
        Execute(0xCD); // int 21h
    }
}