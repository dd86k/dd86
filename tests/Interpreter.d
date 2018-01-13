module InterpreterTests;

import Interpreter, InterpreterUtils, std.stdio, dd_dos;

unittest
{
	import core.stdc.string : memset;
	writeln("----- Interpreter (8086/i486)");

	Initiate;
	CS = 0;

	writeln("-- [ Help functions ]");

	write("InsertByte : ");
	uint ip = GetIPAddress;
	InsertByte(0xFF, ip);
	assert(MEMORY[ip]     == 0xFF);
	assert(MEMORY[ip + 1] == 0);
	InsertByte(0x12, ip + 2);
	assert(MEMORY[ip + 2] == 0x12);
	writeln("OK");

	write("InsertWord : ");
	InsertWord(0x100, ip);
	assert(MEMORY[ip]     == 0);
	assert(MEMORY[ip + 1] == 1);
	InsertWord(0xABCD, ip);
	assert(MEMORY[ip]     == 0xCD);
	assert(MEMORY[ip + 1] == 0xAB);
	InsertWord(0x5678, 4);
	assert(MEMORY[4] == 0x78);
	assert(MEMORY[5] == 0x56);
	writeln("OK");
	
	write("InsertDWord : ");
	InsertDWord(0xAABBCCFF, ip + 1);
	assert(MEMORY[ip + 1] == 0xFF);
	assert(MEMORY[ip + 2] == 0xCC);
	assert(MEMORY[ip + 3] == 0xBB);
	assert(MEMORY[ip + 4] == 0xAA);
	writeln("OK");

	write("InsertString: ");
	InsertString("AB$");
	assert(MEMORY[ip .. ip + 3] == "AB$");
	InsertString("QWERTY", ip + 10);
	assert(MEMORY[ip + 10 .. ip + 16] == "QWERTY");
	writeln("OK");

	write("InsertW: ");
	InsertW("Heck"w);
	assert(MEMORY[ip     .. ip + 1] == "H"w);
	assert(MEMORY[ip + 2 .. ip + 3] == "e"w);
	assert(MEMORY[ip + 4 .. ip + 5] == "c"w);
	assert(MEMORY[ip + 6 .. ip + 7] == "k"w);
	writeln("OK");

	write("InsertArray: ");
	ubyte[2] ar = [ 0xAA, 0xBB ];
	InsertArray(cast(ubyte*)ar, 2, GetIPAddress);
	assert(MEMORY[ip .. ip + 2] == [ 0xAA, 0xBB ]);
	writeln("OK");

	write("Fetch : ");
	InsertWord(0xAAFF, ip + 1);
	assert(FetchImmWord == 0xAAFF);
	assert(FetchWord(ip + 1) == 0xAAFF);
	assert(FetchImmSWord == cast(short)0xAAFF);
	assert(FetchSWord(ip + 1) == cast(short)0xAAFF);
	writeln("OK");

	writeln("\n----- [ Registers ]");

	AX = 0x0201;
	BX = 0x0201;
	CX = 0x0201;
	DX = 0x0201;
	EIP = 0x0050;
	write("AL/AH : ");
	assert(AL == 1);
	assert(AH == 2);
	writeln("OK");
	write("BL/BH : ");
	assert(BL == 1);
	assert(BH == 2);
	writeln("OK");
	write("CL/CH : ");
	assert(CL == 1);
	assert(CH == 2);
	writeln("OK");
	write("DL/DH : ");
	assert(DL == 1);
	assert(DH == 2);
	writeln("OK");
	write("AX : ");
	assert(AX == 0x0201);
	writeln("OK");
	write("BX : ");
	assert(BX == 0x0201);
	writeln("OK");
	write("CX : ");
	assert(CX == 0x0201);
	writeln("OK");
	write("DX : ");
	assert(DX == 0x0201);
	writeln("OK");
	write("IP : ");
	assert(IP == 0x0050);
	writeln("OK");

	write("FLAG: ");
	FLAG = 0xFFFF;
	assert(SF); assert(ZF); assert(AF); assert(PF); assert(CF);
	assert(OF); assert(DF); assert(IF); assert(TF);
	assert(FLAGB == 0xD5);
	assert(FLAG == 0xFD5);
	FLAG = 0;
	assert(!SF); assert(!ZF); assert(!AF); assert(!PF); assert(!CF);
	assert(!OF); assert(!DF); assert(!IF); assert(!TF);
	assert(FLAGB == 0);
	assert(FLAG == 0);
	writeln("OK");

	writeln("\n-- [ General instructions ]");

	// MOV

	CS = 0; IP = 0x100;
	_CURRENT_IP = GetIPAddress;

	write("MOV (Registers) : ");

	InsertByte(0x1, _CURRENT_IP + 1);
	Execute(0xB0); // MOV AL, 1
	assert(AL == 1);

	InsertByte(0x2, _CURRENT_IP + 1);
	Execute(0xB1); // MOV CL, 2
	assert(CL == 2);

	InsertByte(0x3, _CURRENT_IP + 1);
	Execute(0xB2); // MOV DL, 3
	assert(DL == 3);

	InsertByte(0x4, _CURRENT_IP + 1);
	Execute(0xB3); // MOV BL, 4
	assert(BL == 4);

	InsertByte(0x5, _CURRENT_IP + 1);
	Execute(0xB4); // MOV AH, 5
	assert(AH == 5);

	InsertByte(0x6, _CURRENT_IP + 1);
	Execute(0xB5); // MOV CH, 6
	assert(CH == 6);

	InsertByte(0x7, _CURRENT_IP + 1);
	Execute(0xB6); // MOV DH, 7
	assert(DH == 7);

	InsertByte(0x8, _CURRENT_IP + 1);
	Execute(0xB7); // MOV BH, 8
	assert(BH == 8);

	InsertWord(0x1112, _CURRENT_IP + 1); // [ 0x12, 0x11 ]
	Execute(0xB8); // MOV AX, 1112h
	assert(AX == 0x1112);

	InsertWord(0x1113, _CURRENT_IP + 1);
	Execute(0xB9); // MOV CX, 1113h
	assert(CX == 0x1113);

	InsertWord(0x1114, _CURRENT_IP + 1);
	Execute(0xBA); // MOV DX, 1114h
	assert(DX == 0x1114);

	InsertWord(0x1115, _CURRENT_IP + 1);
	Execute(0xBB); // MOV BX, 1115h
	assert(BX == 0x1115);

	InsertWord(0x1116, _CURRENT_IP + 1);
	Execute(0xBC); // MOV SP, 1116h
	assert(SP == 0x1116);

	InsertWord(0x1117, _CURRENT_IP + 1);
	Execute(0xBD); // MOV BP, 1117h
	assert(BP == 0x1117);

	InsertWord(0x1118, _CURRENT_IP + 1);
	Execute(0xBE); // MOV SI, 1118h
	assert(SI == 0x1118);

	InsertWord(0x1119, _CURRENT_IP + 1);
	Execute(0xBF); // MOV DI, 1119h
	assert(DI == 0x1119);

	writeln("OK");

	// MOV - ModR/M

	// MOV R/M16, REG16

	/*write("MOV R/M16, REG16 : ");
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
	writeln("OK");*/

	// MOV REG8, R/M8

	//write("MOV REG8, R/M8 : ");



	//writeln("OK");

	// OR

	write("OR (AL/AX) : ");

	InsertByte(0xF0, _CURRENT_IP + 1);
	AL = 0xF;
	Execute(0xC); // OR AL, 3
	assert(AL == 0xFF);

	InsertWord(0xFF00, _CURRENT_IP + 1);
	Execute(0xD); // OR AX, F0h
	assert(AX == 0xFFFF);

	writeln("OK");

	write("XOR (AL/AX) : ");

	InsertByte(5, _CURRENT_IP + 1);
	AL = 0xF;
	Execute(0x34); // XOR AL, 5
	assert(AL == 0xA);

	InsertWord(0xFF00, _CURRENT_IP + 1);
	AX = 0xAAFF;
	Execute(0x35); // XOR AX, FF00h
	assert(AX == 0x55FF);

	writeln("OK");

	// OR - ModR/M

	//write("OR (R/M) : ");



	//writeln("OK");

	// INC

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
	
	// DEC

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

	// PUSH

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

	// POP

	write("POP : ");

	SS = 0x100;
	SP = 0x20;

	Push(0xFFAA);
	Execute(0x58);
	assert(AX == 0xFFAA);
	SP = SP - 2;
	Execute(0x59);
	assert(CX == 0xFFAA);
	SP = SP - 2;
	Execute(0x5A);
	assert(DX == 0xFFAA);
	SP = SP - 2;
	Execute(0x5B);
	assert(BX == 0xFFAA);
	SP = SP - 2;
	Execute(0x5C);
	assert(SP == 0xFFAA);
	SP = 0x1E;
	Execute(0x5D);
	assert(BP == 0xFFAA);
	SP = SP - 2;
	Execute(0x5E);
	assert(SI == 0xFFAA);
	SP = SP - 2;
	Execute(0x5F);
	assert(DI == 0xFFAA);

	writeln("OK");

	// XCHG

	write("XCHG : ");

	// Nevertheless, let's test the Program Counter
	{
		const uint oldip = IP;
		Execute(0x90);
		assert(oldip + 1 == IP);
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

	/*write("GRP1 ADD : ");

	AX = 6;
	BX = 6;
	CX = 6;
	DX = 6;
	InsertImm(0x10, 3);
	InsertImm(0);
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
	writefln("AH::%X", AH);
	Execute(0x80);
	writefln("AH::%X", AH);
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

	writeln("OK");*/

	/*write("GRP1 OR : ");
	{

	}
	writeln("TODO");*/

	// OVERRIDES (CS:, etc.)

	// CS:

	/*write("CS Override : ");
	{

	}
	writeln("TODO");*/

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

	write("CWD : ");

	AX = 0;
	Execute(0x99);
	assert(DX == 0);
	AX = 0xFFFFF;
	Execute(0x99);
	assert(DX == 0xFFFF);

	writeln("OK");

	// -- STRING INSTRUCTIONS --
	
	writeln("\n-- [ String instructions ]");

	// STOS

	write("STOSB : ");

	ES = 0x20; DI = 0x20;        
	AL = 'Q';
	Execute(0xAA);
	assert(MEMORY[GetAddress(ES, DI - 1)] == 'Q');

	writeln("OK");

	write("STOSW : ");

	ES = 0x200; DI = 0x200;        
	AX = 0xACDC;
	Execute(0xAB);
	assert(FetchWord(GetAddress(ES, DI - 2)) == 0xACDC);

	writeln("OK");

	// LODS

	write("LODSB : ");

	AL = 0;
	DS = 0xA0; SI = 0x200;
	MEMORY[GetAddress(DS, SI)] = 'H';
	Execute(0xAC);
	assert(AL == 'H');
	MEMORY[GetAddress(DS, SI)] = 'e';
	Execute(0xAC);
	assert(AL == 'e');

	writeln("OK");

	write("LODSW : ");

	AX = 0;
	DS = 0x40; SI = 0x80;
	InsertWord(0x48AA, GetAddress(DS, SI));
	Execute(0xAD);
	assert(AX == 0x48AA);
	InsertWord(0x65BB, GetAddress(DS, SI));
	Execute(0xAD);
	assert(AX == 0x65BB);

	writeln("OK");

	// SCAS

	write("SCASB : ");

	ES = CS = 0x400; DI = 0x20; IP = 0x20;
	_CURRENT_IP = GetIPAddress;
	InsertString("Hello!");
	AL = 'H';
	Execute(0xAE);
	assert(ZF);
	AL = '1';
	Execute(0xAE);
	assert(!ZF);

	writeln("OK");

	write("SCASW : ");

	CS = 0x800; ES = 0x800; EIP = 0x30; DI = 0x30;
	InsertWord(0xFE22, GetAddress(ES, DI));
	AX = 0xFE22;
	Execute(0xAF);
	assert(ZF);
	Execute(0xAF);
	assert(!ZF);

	writeln("OK");

	// CMPS

	write("CMPSB : ");

	CS = ES = 0xF00; DI = EIP = 0x100;
	InsertString("HELL", GetIPAddress);
	CS = DS = 0xF00; SI = EIP = 0x110;
	InsertString("HeLL", GetIPAddress);
	Execute(0xA6);
	assert(ZF);
	Execute(0xA6);
	assert(!ZF);
	Execute(0xA6);
	assert(ZF);
	Execute(0xA6);
	assert(ZF);

	writeln("OK");

	write("CMPSW : ");

	CS = ES = 0xF00; DI = EIP = 0x100;
	InsertW("HELL"w, GetIPAddress);
	CS = DS = 0xF00; SI = EIP = 0x110;
	InsertW("HeLL"w, GetIPAddress);
	Execute(0xA7);
	assert(ZF);
	Execute(0xA7);
	assert(!ZF);
	Execute(0xA7);
	assert(ZF);
	Execute(0xA7);
	assert(ZF);

	writeln("OK");
}