import vcpu, vcpu_utils, std.stdio, vdos;
import unitutils;

unittest
{
	import core.stdc.string : memset;
	section("Interpreter (vcpu.d) -- 8086");

	vcpu_init;
	CS = 0;
	EIP = get_ip;

	sub("Interpreter Utilities (vcpu_utils.d)");

	test("__iu8");
	__iu8(0xFF, EIP);
	assert(MEMORY[EIP]     == 0xFF);
	__iu8(0x12, EIP + 2);
	assert(MEMORY[EIP + 2] == 0x12);
	OK;

	test("__iu16");
	__iu16(0x100, EIP);
	assert(MEMORY[EIP]     == 0);
	assert(MEMORY[EIP + 1] == 1);
	__iu16(0xABCD, EIP);
	assert(MEMORY[EIP]     == 0xCD);
	assert(MEMORY[EIP + 1] == 0xAB);
	__iu16(0x5678, 4);
	assert(MEMORY[4] == 0x78);
	assert(MEMORY[5] == 0x56);
	OK;

	test("__iu32");
	__iu32(0xAABBCCFF, EIP);
	assert(MEMORY[EIP    ] == 0xFF);
	assert(MEMORY[EIP + 1] == 0xCC);
	assert(MEMORY[EIP + 2] == 0xBB);
	assert(MEMORY[EIP + 3] == 0xAA);
	OK;

	test("__fu8");
	__iu8(0xAC, EIP + 1);
	assert(__fu8(EIP + 1) == 0xAC);
	OK;

	test("__fu8_i");
	assert(__fu8_i == 0xAC);
	OK;

	/*test("__fi8");
	assert(__fi8(EIP + 1) == cast(byte)0xAC);
	OK;*/

	test("__fi8_i");
	assert(__fi8_i == cast(byte)0xAC);
	OK;

	test("__fu16");
	__iu16(0xAAFF, EIP + 1);
	assert(__fu16(EIP + 1) == 0xAAFF);
	OK;

	test("__fi16");
	assert(__fi16(EIP + 1) == cast(short)0xAAFF);
	OK;

	test("__fu16_i");
	assert(__fu16_i == 0xAAFF);
	OK;

	test("__fi16_i");
	assert(__fi16_i == cast(short)0xAAFF);
	OK;

	test("__fu32");
	__iu32(0xDCBA_FF00, EIP + 1);
	assert(__fu32(EIP + 1) == 0xDCBA_FF00);
	OK;

	/*test("__fu32_i");
	assert(__fu32_i == 0xDCBA_FF00);
	OK;*/

	test("__istr");
	__istr("AB$");
	assert(MEMORY[EIP .. EIP + 3] == "AB$");
	__istr("QWERTY", EIP + 10);
	assert(MEMORY[EIP + 10 .. EIP + 16] == "QWERTY");
	OK;

	test("__iwstr");
	__iwstr("Heck"w);
	assert(MEMORY[EIP     .. EIP + 1] == "H"w);
	assert(MEMORY[EIP + 2 .. EIP + 3] == "e"w);
	assert(MEMORY[EIP + 4 .. EIP + 5] == "c"w);
	assert(MEMORY[EIP + 6 .. EIP + 7] == "k"w);
	OK;

	test("__iarr");
	ubyte[2] ar = [ 0xAA, 0xBB ];
	__iarr(cast(ubyte*)ar, 2, EIP);
	assert(MEMORY[EIP .. EIP + 2] == [ 0xAA, 0xBB ]);
	OK;

	sub("Registers");

	EAX =
	EBX =
	ECX =
	EDX = 0x0201;

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

	sub("ModR/M");
	__iu16(0x1020, EIP + 2); // low:20h
	SI = 0x50; DI = 0x50;
	BX = 0x30; BP = 0x30;
	test("ModR/M (MOD=00)");
	assert(get_ea(0b000) == 0x80);
	assert(get_ea(0b001) == 0x80);
	assert(get_ea(0b010) == 0x80);
	assert(get_ea(0b011) == 0x80);
	assert(get_ea(0b100) == 0x50);
	assert(get_ea(0b101) == 0x50);
	assert(get_ea(0b110) == 0x1020);
	assert(get_ea(0b111) == 0x30);
	OK;
	test("ModR/M (MOD=01)");
	assert(get_ea(0b01_000_000) == 0xA0);
	assert(get_ea(0b01_000_001) == 0xA0);
	assert(get_ea(0b01_000_010) == 0xA0);
	assert(get_ea(0b01_000_011) == 0xA0);
	assert(get_ea(0b01_000_100) == 0x70);
	assert(get_ea(0b01_000_101) == 0x70);
	assert(get_ea(0b01_000_110) == 0x50);
	assert(get_ea(0b01_000_111) == 0x50);
	OK;
	test("ModR/M (MOD=10)");
	assert(get_ea(0b10_000_000) == 0x10A0);
	assert(get_ea(0b10_000_001) == 0x10A0);
	assert(get_ea(0b10_000_010) == 0x10A0);
	assert(get_ea(0b10_000_011) == 0x10A0);
	assert(get_ea(0b10_000_100) == 0x1070);
	assert(get_ea(0b10_000_101) == 0x1070);
	assert(get_ea(0b10_000_110) == 0x1050);
	assert(get_ea(0b10_000_111) == 0x1050);
	OK;
	test("ModR/M (MOD=11)");
	AX = 0x2040; CX = 0x2141;
	DX = 0x2242; BX = 0x2343;
	SP = 0x2030; BP = 0x2131;
	SI = 0x2232; DI = 0x2333;
	assert(get_ea(0b11_000_000) == 0x40); // AL
	assert(get_ea(0b11_000_001) == 0x41); // CL
	assert(get_ea(0b11_000_010) == 0x42); // DL
	assert(get_ea(0b11_000_011) == 0x43); // BL
	assert(get_ea(0b11_000_100) == 0x20); // AH
	assert(get_ea(0b11_000_101) == 0x21); // CH
	assert(get_ea(0b11_000_110) == 0x22); // DH
	assert(get_ea(0b11_000_111) == 0x23); // BH
	OK;
	test("ModR/M (MOD=11+W)");
	assert(get_ea(0b11_000_000, 1) == 0x2040); // AX
	assert(get_ea(0b11_000_001, 1) == 0x2141); // CX
	assert(get_ea(0b11_000_010, 1) == 0x2242); // DX
	assert(get_ea(0b11_000_011, 1) == 0x2343); // BX
	assert(get_ea(0b11_000_100, 1) == 0x2030); // SP
	assert(get_ea(0b11_000_101, 1) == 0x2131); // BP
	assert(get_ea(0b11_000_110, 1) == 0x2232); // SI
	assert(get_ea(0b11_000_111, 1) == 0x2333); // DI
	OK;

	sub("Flag instructions");

	test("CLC"); exec(0xF8); assert(CF == 0); OK;
	test("STC"); exec(0xF9); assert(CF); OK;
	test("CMC"); exec(0xF5); assert(CF == 0); OK;
	test("CLI"); exec(0xFA); assert(IF == 0); OK;
	test("STI"); exec(0xFB); assert(IF); OK;
	test("CLD"); exec(0xFC); assert(DF == 0); OK;
	test("STD"); exec(0xFD); assert(DF); OK;

	sub("General instructions");

	// -- MOV

	CS = 0; IP = 0x100;

	test("MOV MEM8, AL");
	AL = 143;
	__iu16(0x4000, EIP + 1);
	exec(0xA2);
	assert(__fu8(0x4000) == 143);
	OK;
	test("MOV MEM16, AX");
	AX = 1430;
	__iu16(0x4000, EIP + 1);
	exec(0xA3);
	assert(__fu16(0x4000) == 1430);
	OK;

	test("MOV AL, MEM8");
	__iu8(167, 0x8000);
	__iu16(0x8000, EIP + 1);
	exec(0xA0);
	assert(AL == 167);
	OK;
	test("MOV AX, MEM16");
	__iu16(1670, 0x8000);
	__iu16(0x8000, EIP + 1);
	exec(0xA1);
	assert(AX == 1670);
	OK;

	test("MOV REG8, IMM8");
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
	OK;

	test("MOV REG16, IMM16");
	__iu16(0x1112, EIP + 1);
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

	// MOV REG8, R/M8

	test("MOV R/M8, REG8");
	AL = 34;
	__iu8(0b11_000_000, EIP + 1);
	exec(0x88);
	assert(__fu8(AL) == 34);
	CL = 77;
	__iu8(0b11_001_000, EIP + 1);
	exec(0x88);
	assert(__fu8(AL) == 77);
	DL = 123;
	__iu8(0b11_010_000, EIP + 1);
	exec(0x88);
	assert(__fu8(AL) == 123);
	BL = 231;
	__iu8(0b11_011_000, EIP + 1);
	exec(0x88);
	assert(__fu8(AL) == 231);
	AH = 88;
	__iu8(0b11_100_000, EIP + 1);
	exec(0x88);
	assert(__fu8(AL) == 88);
	CH = 32;
	__iu8(0b11_101_000, EIP + 1);
	exec(0x88);
	assert(__fu8(AL) == 32);
	DH = 32;
	__iu8(0b11_110_000, EIP + 1);
	exec(0x88);
	assert(__fu8(AL) == 32);
	BH = 42;
	__iu8(0b11_111_000, EIP + 1);
	exec(0x88);
	assert(__fu8(AL) == 42);
	OK;

	test("MOV REG8, R/M8");
	AL = 56;
	__iu8(AL, AL);
	__iu8(0b11_000_000, EIP + 1);
	exec(0x8A);
	assert(AL == 56);
	CL = 152;
	__iu8(CL, AL);
	__iu8(0b11_001_000, EIP + 1);
	exec(0x8A);
	assert(CL == 152);
	DL = 159;
	__iu8(DL, AL);
	__iu8(0b11_010_000, EIP + 1);
	exec(0x8A);
	assert(DL == 159);
	BL = 129;
	__iu8(BL, AL);
	__iu8(0b11_011_000, EIP + 1);
	exec(0x8A);
	assert(BL == 129);
	AH = 176;
	__iu8(AH, AL);
	__iu8(0b11_100_000, EIP + 1);
	exec(0x8A);
	assert(AH == 176);
	CH = 166;
	__iu8(CH, AL);
	__iu8(0b11_101_000, EIP + 1);
	exec(0x8A);
	assert(CH == 166);
	DH = 198;
	__iu8(DH, AL);
	__iu8(0b11_110_000, EIP + 1);
	exec(0x8A);
	assert(DH == 198);
	BH = 111;
	__iu8(BH, AL);
	__iu8(0b11_111_000, EIP + 1);
	exec(0x8A);
	assert(BH == 111);
	OK;

	// MOV R/M16, REG16

	test("MOV R/M16, REG16");
	AX = 344;
	__iu8(0b11_000_000, EIP + 1);
	exec(0x89);
	assert(__fu16(AX) == 344);
	CX = 777;
	__iu8(0b11_001_000, EIP + 1);
	exec(0x89);
	assert(__fu16(AX) == 777);
	DX = 1234;
	__iu8(0b11_010_000, EIP + 1);
	exec(0x89);
	assert(__fu16(AX) == 1234);
	BX = 2311;
	__iu8(0b11_011_000, EIP + 1);
	exec(0x89);
	assert(__fu16(AX) == 2311);
	SP = 8888;
	__iu8(0b11_100_000, EIP + 1);
	exec(0x89);
	assert(__fu16(AX) == 8888);
	BP = 3200;
	__iu8(0b11_101_000, EIP + 1);
	exec(0x89);
	assert(__fu16(AX) == 3200);
	SI = 3244;
	__iu8(0b11_110_000, EIP + 1);
	exec(0x89);
	assert(__fu16(AX) == 3244);
	DI = 4212;
	__iu8(0b11_111_000, EIP + 1);
	exec(0x89);
	assert(__fu16(AX) == 4212);
	OK;

	test("MOV REG16, R/M16");
	AX = 5600;
	__iu16(AX, AX);
	__iu8(0b11_000_000, EIP + 1);
	exec(0x8B);
	assert(AX == 5600);
	CX = 1520;
	__iu16(CX, AX);
	__iu8(0b11_001_000, EIP + 1);
	exec(0x8B);
	assert(CX == 1520);
	DX = 1590;
	__iu16(DX, AX);
	__iu8(0b11_010_000, EIP + 1);
	exec(0x8B);
	assert(DX == 1590);
	BX = 1290;
	__iu16(BX, AX);
	__iu8(0b11_011_000, EIP + 1);
	exec(0x8B);
	assert(BX == 1290);
	SP = 1760;
	__iu16(SP, AX);
	__iu8(0b11_100_000, EIP + 1);
	exec(0x8B);
	assert(SP == 1760);
	BP = 1660;
	__iu16(BP, AX);
	__iu8(0b11_101_000, EIP + 1);
	exec(0x8B);
	assert(BP == 1660);
	SI = 1984;
	__iu16(SI, AX);
	__iu8(0b11_110_000, EIP + 1);
	exec(0x8B);
	assert(SI == 1984);
	DI = 1110;
	__iu16(DI, AX);
	__iu8(0b11_111_000, EIP + 1);
	exec(0x8B);
	assert(DI == 1110);
	OK;

	test("MOV R/M16, SEGREG");
	CS = 123; DS = 124; ES = 125; SS = 126;
	AX = 0x4440; // address
	__iu8(0b11_101_000, EIP + 1);
	exec(0x8C);
	assert(__fu16(AX) == CS);
	__iu8(0b11_111_000, EIP + 1);
	exec(0x8C);
	assert(__fu16(AX) == DS);
	__iu8(0b11_100_000, EIP + 1);
	exec(0x8C);
	assert(__fu16(AX) == ES);
	__iu8(0b11_110_000, EIP + 1);
	exec(0x8C);
	assert(__fu16(AX) == SS);
	OK;

	test("MOV SEGREG, R/M16");
	__iu8(0b11_101_000, EIP + 1);
	__iu16(8922, AX);
	exec(0x8E);
	assert(CS == 8922);
	__iu8(0b11_111_000, EIP + 1);
	__iu16(4932, AX);
	exec(0x8E);
	assert(DS == 4932);
	__iu8(0b11_100_000, EIP + 1);
	__iu16(7632, AX);
	exec(0x8E);
	assert(ES == 7632);
	__iu8(0b11_110_000, EIP + 1);
	__iu16(9999, AX);
	exec(0x8E);
	assert(SS == 9999);
	OK;

	// -- ADD

	test("ADD AL, IMM8");
	__iu8(4, EIP + 1);
	AL = 12;
	exec(0x04);
	assert(AL == 16);
	OK;

	test("ADD AX, IMM16");
	__iu16(4, EIP + 1);
	AX = 1200;
	exec(0x05);
	assert(AX == 1204);
	OK;

	test("ADD REG8, R/M8"); TODO;
	test("ADD R/M8, REG8");
	CL = 0x20; // address
	AL = 12;
	__iu8(0b11_000_001, EIP + 1);
	__iu8(13, CL);
	exec(0x00);
	assert(__fu8(CL) == 25);
	CL = 13;
	AL = 0x20; // address
	__iu8(0b11_001_000, EIP + 1);
	__iu8(16, AL);
	exec(0x00);
	assert(__fu8(AL) == 29);
	CL = 0x20; // address
	DL = 12;
	__iu8(0b11_010_001, EIP + 1);
	__iu8(23, CL);
	exec(0x00);
	assert(__fu8(CL) == 35);
	CL = 0x20; // address
	BL = 12;
	__iu8(0b11_011_001, EIP + 1);
	__iu8(4, CL);
	exec(0x00);
	assert(__fu8(CL) == 16);
	CL = 0x20; // address
	AH = 12;
	__iu8(0b11_100_001, EIP + 1);
	__iu8(4, CL);
	exec(0x00);
	assert(__fu8(CL) == 16);
	CX = 0x04_20; // address:20h
	__iu8(0b11_101_001, EIP + 1);
	__iu8(52, CL);
	exec(0x00);
	assert(__fu8(CL) == 56);
	CL = 0x20; // address
	DH = 12;
	__iu8(0b11_110_001, EIP + 1);
	__iu8(22, CL);
	exec(0x00);
	assert(__fu8(CL) == 34);
	CL = 0x20; // address
	BH = 56;
	__iu8(0b11_111_001, EIP + 1);
	__iu8(4, CL);
	exec(0x00);
	assert(__fu8(CL) == 60);
	OK;

	// MOV R/M16, REG16

	test("ADD REG16, R/M16"); TODO;
	test("ADD R/M16, REG16");
	CX = 0x200; // address
	AX = 22;
	__iu8(0b11_000_001, EIP + 1);
	__iu16(23, CX);
	exec(0x01);
	assert(__fu16(CX) == 45);
	CX = 23;
	AX = 0x200; // address
	__iu8(0b11_001_000, EIP + 1);
	__iu16(23, AX);
	exec(0x01);
	assert(__fu16(AX) == 46);
	CX = 0x200; // address
	DX = 24;
	__iu8(0b11_010_001, EIP + 1);
	__iu16(23, CX);
	exec(0x01);
	assert(__fu16(CX) == 47);
	CX = 0x200; // address
	BX = 25;
	__iu8(0b11_011_001, EIP + 1);
	__iu16(23, CX);
	exec(0x01);
	assert(__fu16(CX) == 48);
	CX = 0x200; // address
	SP = 26;
	__iu8(0b11_100_001, EIP + 1);
	__iu16(23, CX);
	exec(0x01);
	assert(__fu16(CX) == 49);
	CX = 0x200; // address
	BP = 27;
	__iu8(0b11_101_001, EIP + 1);
	__iu16(23, CX);
	exec(0x01);
	assert(__fu16(CX) == 50);
	CX = 0x200; // address
	SI = 28;
	__iu8(0b11_110_001, EIP + 1);
	__iu16(23, CX);
	exec(0x01);
	assert(__fu16(CX) == 51);
	CX = 0x200; // address
	DI = 29;
	__iu8(0b11_111_001, EIP + 1);
	__iu16(23, CX);
	exec(0x01);
	assert(__fu16(CX) == 52);
	OK;

	// -- OR

	test("OR AL, IMM8");
	__iu8(0xF0, EIP + 1);
	AL = 0xF;
	exec(0xC); // OR AL, 3
	assert(AL == 0xFF);
	OK;

	test("OR AX, IMM16");
	__iu16(0xFF00, EIP + 1);
	exec(0xD); // OR AX, F0h
	assert(AX == 0xFFFF);
	OK;

	// MOV REG8, R/M8

	test("OR REG8, R/M8"); TODO;
	test("OR R/M8, REG8"); TODO;

	// MOV R/M16, REG16

	test("OR REG16, R/M16"); TODO;
	test("OR R/M16, REG16"); TODO;

	// XOR

	test("XOR AL, IMM8");
	__iu8(5, EIP + 1);
	AL = 0xF;
	exec(0x34); // XOR AL, 5
	assert(AL == 0xA);
	OK;

	test("XOR AX, IMM16");
	__iu16(0xFF00, EIP + 1);
	AX = 0xAAFF;
	exec(0x35); // XOR AX, FF00h
	assert(AX == 0x55FF);
	OK;

	// INC

	test("INC REG16");
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

	test("DEC REG16");
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

	test("PUSH REG16");

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

	test("POP REG16");

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

	// TEST

	test("TEST AL, IMM8");
	AL = 0b1100;
	__iu8(0b1100, EIP + 1);
	exec(0xA8);
	assert(PF);
	assert(ZF == 0);
	assert(SF == 0);
	assert(CF == 0);
	assert(OF == 0);
	AL = 0xF0;
	__iu8(0x0F, EIP + 1);
	exec(0xA8);
	assert(PF);
	assert(ZF);
	assert(SF == 0);
	assert(CF == 0);
	assert(OF == 0);
	OK;

	test("TEST AX, IMM16");
	AX = 0xAA00;
	__iu16(0xAA00, EIP + 1);
	exec(0xA9);
	assert(PF);
	assert(ZF == 0);
	assert(SF);
	assert(CF == 0);
	assert(OF == 0);
	OK;

	test("TEST R/M8, REG8");
	AL = 0x60; // address
	CL = 40;
	__iu8(0b11_001_000, EIP+1);
	__iu8(20, AL);
	exec(0x85);
	assert(ZF);
	OK;
	test("TEST R/M16, REG16");
	AX = 0x600; // address
	CX = 400;
	__iu8(0b11_001_000, EIP+1);
	__iu16(200, AL);
	exec(0x86);
	assert(ZF);
	OK;

	test("LEA REG16, MEM16"); TODO;

	sub("Group1 8");

	test("ADD");
	AL = 0x40;
	__iu8(10, AL);
	__iu8(0b11_000_000, EIP+1);
	__iu8(20, EIP+2);
	exec(0x80);
	assert(__fu8(AL) == 30);
	OK;
	test("OR");
	AL = 0x40;
	__iu8(0b1100_0011, AL);
	__iu8(0b11_001_000, EIP+1);
	__iu8(0b0011_0000, EIP+2);
	exec(0x80);
	assert(__fu8(AL) == 0b1111_0011);
	OK;
	test("ADC"); TODO;
	test("SBB"); TODO;
	test("AND");
	AL = 0x40;
	__iu8(0b0011_0011, AL);
	__iu8(0b11_100_000, EIP+1);
	__iu8(0b0011_0000, EIP+2);
	exec(0x80);
	assert(__fu8(AL) == 0b0011_0000);
	OK;
	test("SUB/CMP");
	AL = 0x41;
	__iu8(40, AL);
	__iu8(0b11_101_000, EIP+1);
	__iu8(20, EIP+2);
	exec(0x80);
	assert(__fu8(AL) == 20);
	OK;
	test("XOR");
	AL = 0x40;
	__iu8(40, AL);
	__iu8(0b11_110_000, EIP+1);
	__iu8(20, EIP+2);
	exec(0x80);
	assert(__fu8(AL) == 60);
	OK;

	sub("Group1 16");

	test("ADD");
	AX = 0x400;
	__iu16(40, AX);
	__iu8(0b11_000_000, EIP+1);
	__iu16(222, EIP+2);
	exec(0x81);
	assert(__fu16(AX) == 262);
	OK;
	test("OR");
	AX = 0x400;
	__iu16(40, AX);
	__iu8(0b11_001_000, EIP+1);
	__iu16(222, EIP+2);
	exec(0x81);
	assert(__fu16(AX) == 254);
	OK;
	test("ADC"); TODO;
	test("SBB"); TODO;
	test("AND");
	AX = 0x400;
	__iu16(40, AX);
	__iu8(0b11_100_000, EIP+1);
	__iu16(222, EIP+2);
	exec(0x81);
	assert(__fu16(AX) == 8);
	OK;
	test("SUB/CMP");
	AX = 0x400;
	__iu16(222, AX);
	__iu8(0b11_101_000, EIP+1);
	__iu16(40, EIP+2);
	exec(0x81);
	assert(__fu16(AX) == 182);
	OK;
	test("XOR");
	AX = 0x400;
	__iu16(222, AX);
	__iu8(0b11_110_000, EIP+1);
	__iu16(40, EIP+2);
	exec(0x81);
	assert(__fu16(AX) == 246);
	OK;

	sub("Group2 8");

	test("ADD");
	AL = 0x40;
	__iu8(40, AL);
	__iu8(0b11_000_000, EIP+1);
	__iu8(20, EIP+2);
	exec(0x82);
	assert(__fu8(AL) == 60);
	OK;
	test("ADC"); TODO;
	test("SBB"); TODO;
	test("SUB/CMP");
	AL = 0x40;
	__iu8(40, AL);
	__iu8(0b11_101_000, EIP+1);
	__iu8(20, EIP+2);
	exec(0x82);
	assert(__fu8(AL) == 20);
	OK;

	sub("Group2 16");

	test("ADD");
	AX = 0x400;
	__iu16(400, AX);
	__iu8(0b11_000_000, EIP+1);
	__iu16(200, EIP+2);
	exec(0x83);
	assert(__fu16(AX) == 600);
	OK;
	test("ADC"); TODO;
	test("SBB"); TODO;
	test("SUB/CMP");
	AX = 0x400;
	__iu16(400, AX);
	__iu8(0b11_101_000, EIP + 1);
	__iu16(200, EIP + 2);
	exec(0x83);
	assert(__fu16(AX) == 200);
	OK;

	sub("Group3 8");
	test("TEST");
	AL = 130;
	__iu8(0xAF, AL);
	__iu8(0b11_000_000, EIP + 1);
	__iu8(0xF, EIP + 2);
	exec(0xF6);
	assert(ZF == 0 && OF == 0);
	OK;
	test("NOT");
	__iu8(0b11_010_000, EIP + 1);
	__iu8(0xF, AL);
	exec(0xF6);
	assert(__fu8(AL) == 0xF0);
	OK;
	test("NEG");
	__iu8(0b11_011_000, EIP + 1);
	__iu8(0xF, AL);
	exec(0xF6);
	assert(__fu8(AL) == 0xF1);
	assert(ZF == 0);
	assert(OF == 0);
	OK;
	test("MUL");
	__iu8(0b11_100_000, EIP + 1);
	__iu8(2, EIP + 2);
	__iu8(4, AL);
	exec(0xF6);
	assert(__fu8(AL) == 8);
	assert(ZF == 0);
	OK;
	test("IMUL");
	__iu8(0b11_101_000, EIP + 1);
	__iu8(-2, EIP + 2);
	__iu8(4, AL);
	exec(0xF6);
	assert(__fu8(AL) == 0xF8); // -8 as BYTE
	assert(ZF == 0);
	OK;
	test("DIV");
	AX = 12;
	__iu8(0b11_110_000, EIP + 1);
	__iu8(8, AL);
	exec(0xF6);
	assert(AL == 1);
	assert(AH == 4);
	OK;
	test("IDIV");
	AX = 0xFFF4; // -12
	__iu8(0b11_111_000, EIP + 1);
	__iu8(8, AL);
	exec(0xF6);
	assert(AL == 0xFF);
	assert(AH == 0xFC);
	OK;

	sub("Group3 16"); TODO;

	sub("Array intructions");

	test("XLAT SOURCE-TABLE");
	AL = 10;
	DS = 0x400;
	BX = 0x20;
	__iu8(36, get_ad(DS, BX) + AL);
	exec(0xD7);
	assert(AL == 36);
	OK;

	// -- STRING INSTRUCTIONS --
	
	sub("String instructions");

	// STOS

	test("STOS");
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

	test("LODS"); // of dosh
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

	test("SCAS");
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