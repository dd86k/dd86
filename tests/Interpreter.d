module InterpreterTests;

import Interpreter, std.stdio, dd_dos;

//extern (C) __gshared string[] rt_options = [ "gcopt=profile:1" ];

unittest
{
    writeln("---------- Interpreter");

    machine = new Intel8086();

    with (machine)
    {
        Sleep = false; // Maximum performance
        Verbose = true;
        CS = 0;

        writeln("[ Help functions ]");
        {
            write("Insert : ");

            uint ip = GetIPAddress;
            Insert(0xFF);
            assert(memoryBank[ip]      == 0xFF);
            Insert(0x12, 2);
            assert(memoryBank[ip + 2]  == 0x12);
            Insert(0xABCD);
            assert(memoryBank[ip]      == 0xCD);
            assert(memoryBank[ip + 1]  == 0xAB);
            Insert(0x5678, 4);
            assert(memoryBank[ip + 4]  == 0x78);
            assert(memoryBank[ip + 5]  == 0x56);
            Insert("AB$");
            assert(memoryBank[ip..ip+3]     == "AB$");
            Insert("QWERTY", 10);
            assert(memoryBank[ip+10..ip+16] == "QWERTY");
            ubyte[] ar = [ 0xAA, 0xBB ];
            Insert(ar, 2);
            assert(memoryBank[ip+2..ip+4] == [ 0xAA, 0xBB ]);

            writeln("OK");

            write("Fetch : ");

            writeln("TODO");
        }
        writeln("[ Instructions ]");

        /**
         * MOV
         */

        write("MOV : ");

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

        writeln("OK");

        /**
         * MOV - ModR/M
         */

        // MOV R/M16, REG16

        write("MOV R/M16, REG16 : ");
        {
            ubyte mod = 0; // AX
            Insert(0x134A, 10);
            BX = 5;
            SI = 5;
            AX = 0;
            Execute(0x89);
           // assert(AX == 0x134A);

            mod = 1;
        }
        writeln("OK");

        // MOV REG8, R/M8

        //write("MOV REG8, R/M8 : ");



        //writeln("OK");

        /**
         * OR
         */

        write("OR : ");

        Insert(0xF0, 1);
        AL = 0xF;
        Execute(0xC); // OR AL, 3
        assert(AL == 0xFF);

        Insert(0xFF00, 1);
        Execute(0xD); // OR AX, F0h
        assert(AX == 0xFFFF);

        writeln("OK");

        /**
         * OR - ModR/M
         */

        //write("OR+ModR/M : ");



        //writeln("OK");

        /**
         * INC
         */

        write("INC : ");

        FullReset(); CS = 0;
        Execute(0x40);
        assert(AX == 1);
        Execute(0x41);
        assert(CX == 1);
        Execute(0x42);
        assert(DX == 1);
        Execute(0x43);
        assert(BX == 1);
        Execute(0x44);
        assert(SP == 1);
        Execute(0x45);
        assert(BP == 1);
        Execute(0x46);
        assert(SI == 1);
        Execute(0x47);
        assert(DI == 1);

        writeln("OK");
        
        /**
         * DEC
         */

        write("DEC : ");

        Execute(0x48);
        assert(AX == 0);
        Execute(0x49);
        assert(CX == 0);
        Execute(0x4A);
        assert(DX == 0);
        Execute(0x4B);
        assert(BX == 0);
        Execute(0x4C);
        assert(SP == 0);
        Execute(0x4D);
        assert(BP == 0);
        Execute(0x4E);
        assert(SI == 0);
        Execute(0x4F);
        assert(DI == 0);

        writeln("OK");

        /**
         * PUSH
         */

        write("PUSH : ");

        SS = 0x100;
        SP = 0x60;

        AX = 0xDAD;
        Execute(0x50);
        assert(AX == FetchWord(GetAddress(SS, SP)));
        Push(AX);
        assert(AX == FetchWord(GetAddress(SS, SP)));

        CX = 0x4488;
        Execute(0x51);
        assert(CX == FetchWord(GetAddress(SS, SP)));

        DX = 0x4321;
        Execute(0x52);
        assert(DX == FetchWord(GetAddress(SS, SP)));

        BX = 0x1234;
        Execute(0x53);
        assert(BX == FetchWord(GetAddress(SS, SP)));

        Execute(0x54);
        assert(SP == FetchWord(GetAddress(SS, SP)) - 2);

        BP = 0xFBAC;
        Execute(0x55);
        assert(BP == FetchWord(GetAddress(SS, SP)));

        SI = 0xF00F;
        Execute(0x56);
        assert(SI == FetchWord(GetAddress(SS, SP)));

        DI = 0xB0B;
        Execute(0x57);
        assert(DI == FetchWord(GetAddress(SS, SP)));

        writeln("OK");

        /**
         * POP
         */

        write("POP : ");

        SS = 0x100;
        SP = 0x20;

        Push(0xFFAA);
        Execute(0x58);
        assert(AX == 0xFFAA);
        SP -= 2;
        Execute(0x59);
        assert(CX == 0xFFAA);
        SP -= 2;
        Execute(0x5A);
        assert(DX == 0xFFAA);
        SP -= 2;
        Execute(0x5B);
        assert(BX == 0xFFAA);
        SP -= 2;
        Execute(0x5C);
        assert(SP == 0xFFAA);
        SP = 0x1E;
        Execute(0x5D);
        assert(BP == 0xFFAA);
        SP -= 2;
        Execute(0x5E);
        assert(SI == 0xFFAA);
        SP -= 2;
        Execute(0x5F);
        assert(DI == 0xFFAA);

        writeln("OK");

        /**
         * XCHG
         */

        write("XCHG : ");

        /*
         * 90h is NOP which is basically a XCHG AX,AX internally
         * Nevertheless, let's test it (for the Program Counter's sake)
         */
        {
            uint ip = IP;
            Execute(0x90);
            assert(ip + 1 == IP);
        }

        AX = 0xFAB;
        CX = 0xAABB;
        Execute(0x91);
        assert(AX == 0xAABB);
        assert(CX == 0xFAB);

        AX = 0xFAB;
        DX = 0xAABB;
        Execute(0x92);
        assert(AX == 0xAABB);
        assert(DX == 0xFAB);

        AX = 0xFAB;
        BX = 0xAABB;
        Execute(0x93);
        assert(AX == 0xAABB);
        assert(BX == 0xFAB);

        AX = 0xFAB;
        SP = 0xAABB;
        Execute(0x94);
        assert(AX == 0xAABB);
        assert(SP == 0xFAB);

        AX = 0xFAB;
        BP = 0xAABB;
        Execute(0x95);
        assert(AX == 0xAABB);
        assert(BP == 0xFAB);

        AX = 0xFAB;
        SI = 0xAABB;
        Execute(0x96);
        assert(AX == 0xAABB);
        assert(SI == 0xFAB);

        AX = 0xFAB;
        DI = 0xAABB;
        Execute(0x97);
        assert(AX == 0xAABB);
        assert(DI == 0xFAB);

        writeln("OK");

        // GRP1

        write("GRP1 ADD : ");

        AL = CL = DL = BL = 
             AH = CH = DH = BH = 6;
        Insert(0x10, 2);
        InsertImm(0, 1);
        Execute(0x80);
        assert(AL == 0x16);
        IP -= 3;
        InsertImm(0b001);
        Execute(0x80);
        assert(CL == 0x16);
        IP -= 3;
        InsertImm(0b010);
        Execute(0x80);
        assert(DL == 0x16);
        IP -= 3;
        InsertImm(0b011);
        Execute(0x80);
        assert(BL == 0x16);
        IP -= 3;
        InsertImm(0b100);
        Execute(0x80);
        assert(AH == 0x16);
        IP -= 3;
        InsertImm(0b101);
        Execute(0x80);
        assert(CH == 0x16);
        IP -= 3;
        InsertImm(0b110);
        Execute(0x80);
        assert(DH == 0x16);
        IP -= 3;
        InsertImm(0b111);
        Execute(0x80);
        assert(BH == 0x16);

        writeln("OK");

        /*write("GRP1 OR : ");
        {

        }
        writeln("TODO");*/

        /**
         * OVERRIDES (CS, etc.)
         */

         // CS:

        /*write("CS Override : ");
        {

        }
        writeln("TODO");*/

        /**
         * MISC.
         */

        // CBW

        write("CBW : ");

        AL = 0;
        Execute(0x98);
        assert(AH == 0);
        AL = 0xFF;
        Execute(0x98);
        assert(AH == 0xFF);

        writeln("OK");

        // CWD

        write("CBW : ");

        AX = 0;
        Execute(0x99);
        assert(DX == 0);
        AX = 0xFFFFF;
        Execute(0x99);
        assert(DX == 0xFFFF);

        writeln("OK");
    }
}