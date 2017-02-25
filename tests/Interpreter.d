module test;

import Interpreter, std.stdio;

unittest
{
    Intel8086 machine = new Intel8086();

    with (machine)
    {
        CS = 0;

        // MOV
        
        Insert(1, 1);
        Execute(0xB0); // MOV AL, 1
        assert(AL == 1);

        Insert(2, 1);
        Execute(0xB1); // MOV CL, 2
        assert(CL == 2);

        Insert(3, 1);
        Execute(0xB2); // MOV DL, 3
        assert(DL == 3);

        Insert(4, 1);
        Execute(0xB3); // MOV BL, 4
        assert(BL == 4);

        Insert(5, 1);
        Execute(0xB4); // MOV AH, 5
        assert(AH == 5);

        Insert(6, 1);
        Execute(0xB5); // MOV CH, 6
        assert(CH == 6);

        Insert(7, 1);
        Execute(0xB6); // MOV DH, 7
        assert(DH == 7);

        Insert(8, 1);
        Execute(0xB7); // MOV BH, 8
        assert(BH == 8);

        Insert(0x1112, 1); // [ 0x12, 0x11 ]
        Execute(0xB8); // MOV AX, 1112h
        assert(AX == 0x1112);

        Insert(0x1113, 1);
        Execute(0xB9); // MOV CX, 1113h
        assert(CX == 0x1113);

        Insert(0x1114, 1);
        Execute(0xBA); // MOV DX, 1114h
        assert(DX == 0x1114);

        Insert(0x1115, 1);
        Execute(0xBB); // MOV BX, 1115h
        assert(BX == 0x1115);

        Insert(0x1116, 1);
        Execute(0xBC); // MOV SP, 1116h
        assert(SP == 0x1116);

        Insert(0x1117, 1);
        Execute(0xBD); // MOV BP, 1117h
        assert(BP == 0x1117);

        Insert(0x1118, 1);
        Execute(0xBE); // MOV SI, 1118h
        assert(SI == 0x1118);

        Insert(0x1119, 1);
        Execute(0xBF); // MOV DI, 1119h
        assert(DI == 0x1119);

        writefln("Resetting IP from %Xh to 0", IP);
        IP = 0;
    }
}