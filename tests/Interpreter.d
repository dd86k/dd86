module InterpreterTests;

import Interpreter, InterpreterUtils, std.stdio, vdos;
import unitutils;

unittest
{
	import core.stdc.string : memset;
	section("Interpreter (8086/i486)");

	init;
	CS = 0;
	uint ip = get_ip;

	sub("InterpreterUtils");

	test("__iu8");
	__iu8(0xFF, ip);
	assert(MEMORY[ip]     == 0xFF);
	__iu8(0x12, ip + 2);
	assert(MEMORY[ip + 2] == 0x12);
	OK;

	test("__iu16");
	__iu16(0x100, ip);
	assert(MEMORY[ip]     == 0);
	assert(MEMORY[ip + 1] == 1);
	__iu16(0xABCD, ip);
	assert(MEMORY[ip]     == 0xCD);
	assert(MEMORY[ip + 1] == 0xAB);
	__iu16(0x5678, 4);
	assert(MEMORY[4] == 0x78);
	assert(MEMORY[5] == 0x56);
	OK;
	
	test("__iu32");
	__iu32(0xAABBCCFF, ip);
	assert(MEMORY[ip    ] == 0xFF);
	assert(MEMORY[ip + 1] == 0xCC);
	assert(MEMORY[ip + 2] == 0xBB);
	assert(MEMORY[ip + 3] == 0xAA);
	OK;

	test("__fu8");
	__iu8(0xAC, ip + 1);
	assert(__fu8(ip + 1) == 0xAC);
	OK;

	test("__fu8_i");
	assert(__fu8_i == 0xAC);
	OK;

	/*test("__fi8");
	assert(__fi8(ip + 1) == cast(byte)0xAC);
	OK;*/

	test("__fi8_i");
	assert(__fi8_i == cast(byte)0xAC);
	OK;

	test("__fu16");
	__iu16(0xAAFF, ip + 1);
	assert(__fu16(ip + 1) == 0xAAFF);
	OK;

	test("__fi16");
	assert(__fi16(ip + 1) == cast(short)0xAAFF);
	OK;

	test("__fu16_i");
	assert(__fu16_i == 0xAAFF);
	OK;

	test("__fi16_i");
	assert(__fi16_i == cast(short)0xAAFF);
	OK;

	test("__fu32");
	__iu32(0xDCBA_FF00, ip + 1);
	assert(__fu32(ip + 1) == 0xDCBA_FF00);
	OK;

	/*test("__fu32_i");
	assert(__fu32_i == 0xDCBA_FF00);
	OK;*/

	test("__istr");
	__istr("AB$");
	assert(MEMORY[ip .. ip + 3] == "AB$");
	__istr("QWERTY", ip + 10);
	assert(MEMORY[ip + 10 .. ip + 16] == "QWERTY");
	OK;

	test("__iwstr");
	__iwstr("Heck"w);
	assert(MEMORY[ip     .. ip + 1] == "H"w);
	assert(MEMORY[ip + 2 .. ip + 3] == "e"w);
	assert(MEMORY[ip + 4 .. ip + 5] == "c"w);
	assert(MEMORY[ip + 6 .. ip + 7] == "k"w);
	OK;

	test("__iarr");
	ubyte[2] ar = [ 0xAA, 0xBB ];
	__iarr(cast(ubyte*)ar, 2, ip);
	assert(MEMORY[ip .. ip + 2] == [ 0xAA, 0xBB ]);
	OK;

	sub("Registers");
	
	EAX = 0xFF_0201;
	EBX = 0xFF_0201;
	ECX = 0xFF_0201;
	EDX = 0xFF_0201;

	test("AL/AH");
	assert(AL == 1);
	assert(AH == 2);
	OK;

	test("BL/BH");
	assert(BL == 1);
	assert(BH == 2);
	OK;

	test("CL/CH");
	assert(CL == 1);
	assert(CH == 2);
	OK;

	test("DL/DH");
	assert(DL == 1);
	assert(DH == 2);
	OK;

	test("AX");
	assert(AX == 0x0201);
	OK;

	test("BX");
	assert(BX == 0x0201);
	OK;

	test("CX");
	assert(CX == 0x0201);
	OK;

	test("DX");
	assert(DX == 0x0201);
	OK;

	EIP = 0x0F50;
	test("IP");
	assert(IP == 0x0F50);
	OK;

	test("FLAG");
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
	OK;

	sub("General instructions");

	// MOV

	CS = 0; IP = 0x100;
	EIP = get_ip;

	test("MOV (REG)");

	__iu8(0x1, EIP + 1);
	exec(0xB0); // MOV AL, 1
	assert(AL == 1);

	__iu8(0x2, EIP + 1);
	exec(0xB1); // MOV CL, 2
	assert(CL == 2);

	__iu8(0x3, EIP + 1);
	exec(0xB2); // MOV DL, 3
	assert(DL == 3);

	__iu8(0x4, EIP + 1);
	exec(0xB3); // MOV BL, 4
	assert(BL == 4);

	__iu8(0x5, EIP + 1);
	exec(0xB4); // MOV AH, 5
	assert(AH == 5);

	__iu8(0x6, EIP + 1);
	exec(0xB5); // MOV CH, 6
	assert(CH == 6);

	__iu8(0x7, EIP + 1);
	exec(0xB6); // MOV DH, 7
	assert(DH == 7);

	__iu8(0x8, EIP + 1);
	exec(0xB7); // MOV BH, 8
	assert(BH == 8);

	__iu16(0x1112, EIP + 1); // [ 0x12, 0x11 ]
	exec(0xB8); // MOV AX, 1112h
	assert(AX == 0x1112);

	__iu16(0x1113, EIP + 1);
	exec(0xB9); // MOV CX, 1113h
	assert(CX == 0x1113);

	__iu16(0x1114, EIP + 1);
	exec(0xBA); // MOV DX, 1114h
	assert(DX == 0x1114);

	__iu16(0x1115, EIP + 1);
	exec(0xBB); // MOV BX, 1115h
	assert(BX == 0x1115);

	__iu16(0x1116, EIP + 1);
	exec(0xBC); // MOV SP, 1116h
	assert(SP == 0x1116);

	__iu16(0x1117, EIP + 1);
	exec(0xBD); // MOV BP, 1117h
	assert(BP == 0x1117);

	__iu16(0x1118, EIP + 1);
	exec(0xBE); // MOV SI, 1118h
	assert(SI == 0x1118);

	__iu16(0x1119, EIP + 1);
	exec(0xBF); // MOV DI, 1119h
	assert(DI == 0x1119);

	OK;

	// MOV - ModR/M

	// MOV R/M16, REG16

	/*test("MOV R/M16, REG16");
	{
		ubyte mod = 0; // AX
		Insert(0x134A, 10);
		BX = 5;
		SI = 5;
		AX = 0;
		exec(0x89);
		// assert(AX == 0x134A);

		mod = 1;
	}
	OK;*/

	// MOV REG8, R/M8

	//test("MOV REG8, R/M8");



	//OK;

	// OR

	test("OR (AL/AX)");

	__iu8(0xF0, EIP + 1);
	AL = 0xF;
	exec(0xC); // OR AL, 3
	assert(AL == 0xFF);

	__iu16(0xFF00, EIP + 1);
	exec(0xD); // OR AX, F0h
	assert(AX == 0xFFFF);

	OK;

	test("XOR (AL/AX)");

	__iu8(5, EIP + 1);
	AL = 0xF;
	exec(0x34); // XOR AL, 5
	assert(AL == 0xA);

	__iu16(0xFF00, EIP + 1);
	AX = 0xAAFF;
	exec(0x35); // XOR AX, FF00h
	assert(AX == 0x55FF);

	OK;

	// OR - ModR/M

	//test("OR (R/M)");



	//OK;

	// INC

	test("INC");

	fullreset; CS = 0;
	exec(0x40);
	assert(AX == 1);
	exec(0x41);
	assert(CX == 1);
	exec(0x42);
	assert(DX == 1);
	exec(0x43);
	assert(BX == 1);
	exec(0x44);
	assert(SP == 1);
	exec(0x45);
	assert(BP == 1);
	exec(0x46);
	assert(SI == 1);
	exec(0x47);
	assert(DI == 1);

	OK;
	
	// DEC

	test("DEC");

	exec(0x48);
	assert(AX == 0);
	exec(0x49);
	assert(CX == 0);
	exec(0x4A);
	assert(DX == 0);
	exec(0x4B);
	assert(BX == 0);
	exec(0x4C);
	assert(SP == 0);
	exec(0x4D);
	assert(BP == 0);
	exec(0x4E);
	assert(SI == 0);
	exec(0x4F);
	assert(DI == 0);

	OK;

	// PUSH

	test("PUSH");

	SS = 0x100;
	SP = 0x60;

	AX = 0xDAD;
	exec(0x50);
	assert(AX == __fu16(get_ad(SS, SP)));
	push(AX);
	assert(AX == __fu16(get_ad(SS, SP)));

	CX = 0x4488;
	exec(0x51);
	assert(CX == __fu16(get_ad(SS, SP)));

	DX = 0x4321;
	exec(0x52);
	assert(DX == __fu16(get_ad(SS, SP)));

	BX = 0x1234;
	exec(0x53);
	assert(BX == __fu16(get_ad(SS, SP)));

	exec(0x54);
	assert(SP == __fu16(get_ad(SS, SP)) - 2);

	BP = 0xFBAC;
	exec(0x55);
	assert(BP == __fu16(get_ad(SS, SP)));

	SI = 0xF00F;
	exec(0x56);
	assert(SI == __fu16(get_ad(SS, SP)));

	DI = 0xB0B;
	exec(0x57);
	assert(DI == __fu16(get_ad(SS, SP)));

	OK;

	// POP

	test("POP");

	SS = 0x100;
	SP = 0x20;

	push(0xFFAA);
	exec(0x58);
	assert(AX == 0xFFAA);
	SP = SP - 2;
	exec(0x59);
	assert(CX == 0xFFAA);
	SP = SP - 2;
	exec(0x5A);
	assert(DX == 0xFFAA);
	SP = SP - 2;
	exec(0x5B);
	assert(BX == 0xFFAA);
	SP = SP - 2;
	exec(0x5C);
	assert(SP == 0xFFAA);
	SP = 0x1E;
	exec(0x5D);
	assert(BP == 0xFFAA);
	SP = SP - 2;
	exec(0x5E);
	assert(SI == 0xFFAA);
	SP = SP - 2;
	exec(0x5F);
	assert(DI == 0xFFAA);

	OK;

	// XCHG

	test("XCHG");

	// Nevertheless, let's test the Program Counter
	{
		const uint oldip = IP;
		exec(0x90);
		assert(oldip + 1 == IP);
	}

	AX = 0xFAB;
	CX = 0xAABB;
	exec(0x91);
	assert(AX == 0xAABB);
	assert(CX == 0xFAB);

	AX = 0xFAB;
	DX = 0xAABB;
	exec(0x92);
	assert(AX == 0xAABB);
	assert(DX == 0xFAB);

	AX = 0xFAB;
	BX = 0xAABB;
	exec(0x93);
	assert(AX == 0xAABB);
	assert(BX == 0xFAB);

	AX = 0xFAB;
	SP = 0xAABB;
	exec(0x94);
	assert(AX == 0xAABB);
	assert(SP == 0xFAB);

	AX = 0xFAB;
	BP = 0xAABB;
	exec(0x95);
	assert(AX == 0xAABB);
	assert(BP == 0xFAB);

	AX = 0xFAB;
	SI = 0xAABB;
	exec(0x96);
	assert(AX == 0xAABB);
	assert(SI == 0xFAB);

	AX = 0xFAB;
	DI = 0xAABB;
	exec(0x97);
	assert(AX == 0xAABB);
	assert(DI == 0xFAB);

	OK;

	// GRP1

	/*test("GRP1 ADD");

	AX = 6;
	BX = 6;
	CX = 6;
	DX = 6;
	InsertImm(0x10, 3);
	InsertImm(0);
	exec(0x80);
	assert(AL == 0x16);
	IP -= 3;
	InsertImm(0b001);
	exec(0x80);
	assert(CL == 0x16);
	IP -= 3;
	InsertImm(0b010);
	exec(0x80);
	assert(DL == 0x16);
	IP -= 3;
	InsertImm(0b011);
	exec(0x80);
	assert(BL == 0x16);
	IP -= 3;
	InsertImm(0b100);
	writefln("AH::%X", AH);
	exec(0x80);
	writefln("AH::%X", AH);
	assert(AH == 0x16);
	IP -= 3;
	InsertImm(0b101);
	exec(0x80);
	assert(CH == 0x16);
	IP -= 3;
	InsertImm(0b110);
	exec(0x80);
	assert(DH == 0x16);
	IP -= 3;
	InsertImm(0b111);
	exec(0x80);
	assert(BH == 0x16);

	OK;*/

	/*test("GRP1 OR");
	{

	}
	writeln("TODO");*/

	// OVERRIDES (CS:, etc.)

	// CS:

	/*test("CS Override");
	{

	}
	writeln("TODO");*/

	// CBW

	test("CBW");

	AL = 0;
	exec(0x98);
	assert(AH == 0);
	AL = 0xFF;
	exec(0x98);
	assert(AH == 0xFF);

	OK;

	// CWD

	test("CWD");

	AX = 0;
	exec(0x99);
	assert(DX == 0);
	AX = 0xFFFFF;
	exec(0x99);
	assert(DX == 0xFFFF);

	OK;

	test("TEST AL,IMM8");

	AL = 0b1100;
	__iu8(0b1100, EIP + 1);
	exec(0xA8);
	assert(!CF);
	assert(PF);
	assert(!AF);
	assert(!ZF);
	assert(!SF);

	AL = 0xF0;
	__iu8(0x0F, EIP + 1);
	exec(0xA8);
	assert(!CF);
	assert(!PF);
	assert(!AF);
	assert(ZF);
	assert(!SF);

	OK;

	// -- STRING INSTRUCTIONS --
	
	sub("String instructions");

	// STOS

	test("STOSB");
	ES = 0x20; DI = 0x20;        
	AL = 'Q';
	exec(0xAA);
	assert(MEMORY[get_ad(ES, DI - 1)] == 'Q');
	OK;

	test("STOSW");
	ES = 0x200; DI = 0x200;        
	AX = 0xACDC;
	exec(0xAB);
	assert(__fu16(get_ad(ES, DI - 2)) == 0xACDC);
	OK;

	// LODS

	test("LODSB");
	AL = 0;
	DS = 0xA0; SI = 0x200;
	MEMORY[get_ad(DS, SI)] = 'H';
	exec(0xAC);
	assert(AL == 'H');
	MEMORY[get_ad(DS, SI)] = 'e';
	exec(0xAC);
	assert(AL == 'e');
	OK;

	test("LODSW");
	AX = 0;
	DS = 0x40; SI = 0x80;
	__iu16(0x48AA, get_ad(DS, SI));
	exec(0xAD);
	assert(AX == 0x48AA);
	__iu16(0x65BB, get_ad(DS, SI));
	exec(0xAD);
	assert(AX == 0x65BB);
	OK;

	// SCAS

	test("SCASB");
	ES = CS = 0x400; DI = 0x20; IP = 0x20;
	EIP = get_ip;
	__istr("Hello!");
	AL = 'H';
	exec(0xAE);
	assert(ZF);
	AL = '1';
	exec(0xAE);
	assert(!ZF);
	OK;

	test("SCASW");
	CS = 0x800; ES = 0x800; EIP = 0x30; DI = 0x30;
	__iu16(0xFE22, get_ad(ES, DI));
	AX = 0xFE22;
	exec(0xAF);
	assert(ZF);
	exec(0xAF);
	assert(!ZF);
	OK;

	DF = 0;

	// CMPS

	test("CMPS");
	CS = ES = 0xF00; DI = EIP = 0x100;
	__istr("HELL", get_ip);
	CS = DS = 0xF00; SI = EIP = 0x110;
	__istr("HeLL", get_ip);
	exec(0xA6);
	assert(ZF);
	exec(0xA6);
	assert(!ZF);
	exec(0xA6);
	assert(ZF);
	exec(0xA6);
	assert(ZF);
	OK;

	test("CMPSW");
	CS = ES = 0xF00; DI = EIP = 0x100;
	__iwstr("HELL"w, get_ip);
	CS = DS = 0xF00; SI = EIP = 0x110;
	__iwstr("HeLL"w, get_ip);
	exec(0xA7);
	assert(ZF);
	exec(0xA7);
	assert(!ZF);
	exec(0xA7);
	assert(ZF);
	exec(0xA7);
	assert(ZF);
	OK;
}