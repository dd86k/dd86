import vcpu, vcpu_utils, vcpu_8086, std.stdio, vdos;
import test_utils;

unittest
{
	import core.stdc.string : memset;
	section("Interpreter (vcpu.d) -- 8086");

	vcpu_init;
	vCPU.CS = 0;
	vCPU.EIP = get_ip;

	sub("Interpreter Utilities (vcpu_utils.d)");

	test("__iu8");
	__iu8(0xFF, vCPU.EIP);
	assert(MEMORY[vCPU.EIP]     == 0xFF);
	__iu8(0x12, vCPU.EIP + 2);
	assert(MEMORY[vCPU.EIP + 2] == 0x12);
	OK;

	test("__iu16");
	__iu16(0x100, vCPU.EIP);
	assert(MEMORY[vCPU.EIP]     == 0);
	assert(MEMORY[vCPU.EIP + 1] == 1);
	__iu16(0xABCD, vCPU.EIP);
	assert(MEMORY[vCPU.EIP]     == 0xCD);
	assert(MEMORY[vCPU.EIP + 1] == 0xAB);
	__iu16(0x5678, 4);
	assert(MEMORY[4] == 0x78);
	assert(MEMORY[5] == 0x56);
	OK;

	test("__iu32");
	__iu32(0xAABBCCFF, vCPU.EIP);
	assert(MEMORY[vCPU.EIP    ] == 0xFF);
	assert(MEMORY[vCPU.EIP + 1] == 0xCC);
	assert(MEMORY[vCPU.EIP + 2] == 0xBB);
	assert(MEMORY[vCPU.EIP + 3] == 0xAA);
	OK;

	test("__fu8");
	__iu8(0xAC, vCPU.EIP + 1);
	assert(__fu8(vCPU.EIP + 1) == 0xAC);
	OK;

	test("__fu8_i");
	assert(__fu8_i == 0xAC);
	OK;

	test("__fi8");
	assert(__fi8(vCPU.EIP + 1) == cast(byte)0xAC);
	OK;

	test("__fi8_i");
	assert(__fi8_i == cast(byte)0xAC);
	OK;

	test("__fu16");
	__iu16(0xAAFF, vCPU.EIP + 1);
	assert(__fu16(vCPU.EIP + 1) == 0xAAFF);
	OK;

	test("__fi16");
	assert(__fi16(vCPU.EIP + 1) == cast(short)0xAAFF);
	OK;

	test("__fu16_i");
	assert(__fu16_i == 0xAAFF);
	OK;

	test("__fi16_i");
	assert(__fi16_i == cast(short)0xAAFF);
	OK;

	test("__fu32");
	__iu32(0xDCBA_FF00, vCPU.EIP + 1);
	assert(__fu32(vCPU.EIP + 1) == 0xDCBA_FF00);
	OK;

	/*test("__fu32_i");
	assert(__fu32_i == 0xDCBA_FF00);
	OK;*/

	test("__istr");
	__istr("AB$");
	assert(MEMORY[vCPU.EIP .. vCPU.EIP + 3] == "AB$");
	__istr("QWERTY", vCPU.EIP + 10);
	assert(MEMORY[vCPU.EIP + 10 .. vCPU.EIP + 16] == "QWERTY");
	OK;

	test("__iwstr");
	__iwstr("Heck"w);
	assert(MEMORY[vCPU.EIP     .. vCPU.EIP + 1] == "H"w);
	assert(MEMORY[vCPU.EIP + 2 .. vCPU.EIP + 3] == "e"w);
	assert(MEMORY[vCPU.EIP + 4 .. vCPU.EIP + 5] == "c"w);
	assert(MEMORY[vCPU.EIP + 6 .. vCPU.EIP + 7] == "k"w);
	OK;

	test("__iarr");
	ubyte[2] ar = [ 0xAA, 0xBB ];
	__iarr(cast(ubyte*)ar, 2, vCPU.EIP);
	assert(MEMORY[vCPU.EIP .. vCPU.EIP + 2] == [ 0xAA, 0xBB ]);
	OK;

	sub("Registers");

	vCPU.EAX = 0x0807;
	vCPU.EBX = 0x0605;
	vCPU.ECX = 0x0403;
	vCPU.EDX = 0x0201;

	test("AL/AH");
	assert(vCPU.AL == 7);
	assert(vCPU.AH == 8);
	OK;

	test("BL/BH");
	assert(vCPU.BL == 5);
	assert(vCPU.BH == 6);
	OK;

	test("CL/CH");
	assert(vCPU.CL == 3);
	assert(vCPU.CH == 4);
	OK;

	test("DL/DH");
	assert(vCPU.DL == 1);
	assert(vCPU.DH == 2);
	OK;

	test("AX");
	assert(vCPU.AX == 0x0807);
	OK;

	test("BX");
	assert(vCPU.BX == 0x0605);
	OK;

	test("CX");
	assert(vCPU.CX == 0x0403);
	OK;

	test("DX");
	assert(vCPU.DX == 0x0201);
	OK;

	vCPU.EIP = 0x0F50;
	test("IP");
	assert(vCPU.IP == 0x0F50);
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
	__iu16(0x1020, vCPU.EIP + 2); // low:20h
	vCPU.SI = 0x50; vCPU.DI = 0x50;
	vCPU.BX = 0x30; vCPU.BP = 0x30;
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
	vCPU.AX = 0x2040; vCPU.CX = 0x2141;
	vCPU.DX = 0x2242; vCPU.BX = 0x2343;
	vCPU.SP = 0x2030; vCPU.BP = 0x2131;
	vCPU.SI = 0x2232; vCPU.DI = 0x2333;
	assert(get_ea(0b11_000_000) == 0x40); // vCPU.AL
	assert(get_ea(0b11_000_001) == 0x41); // vCPU.CL
	assert(get_ea(0b11_000_010) == 0x42); // vCPU.DL
	assert(get_ea(0b11_000_011) == 0x43); // vCPU.BL
	assert(get_ea(0b11_000_100) == 0x20); // vCPU.AH
	assert(get_ea(0b11_000_101) == 0x21); // vCPU.CH
	assert(get_ea(0b11_000_110) == 0x22); // vCPU.DH
	assert(get_ea(0b11_000_111) == 0x23); // vCPU.BH
	OK;
	test("ModR/M (MOD=11+W)");
	assert(get_ea(0b11_000_000, 1) == 0x2040); // vCPU.AX
	assert(get_ea(0b11_000_001, 1) == 0x2141); // vCPU.CX
	assert(get_ea(0b11_000_010, 1) == 0x2242); // vCPU.DX
	assert(get_ea(0b11_000_011, 1) == 0x2343); // vCPU.BX
	assert(get_ea(0b11_000_100, 1) == 0x2030); // vCPU.SP
	assert(get_ea(0b11_000_101, 1) == 0x2131); // vCPU.BP
	assert(get_ea(0b11_000_110, 1) == 0x2232); // vCPU.SI
	assert(get_ea(0b11_000_111, 1) == 0x2333); // vCPU.DI
	OK;

	sub("Flag instructions");

	test("CLC"); exec16(0xF8); assert(CF == 0); OK;
	test("STC"); exec16(0xF9); assert(CF); OK;
	test("CMC"); exec16(0xF5); assert(CF == 0); OK;
	test("CLI"); exec16(0xFA); assert(IF == 0); OK;
	test("STI"); exec16(0xFB); assert(IF); OK;
	test("CLD"); exec16(0xFC); assert(DF == 0); OK;
	test("STD"); exec16(0xFD); assert(DF); OK;

	sub("General instructions");

	// -- MOV

	vCPU.CS = 0; vCPU.IP = 0x100;

	test("MOV MEM8, vCPU.AL");
	vCPU.AL = 143;
	__iu16(0x4000, vCPU.EIP + 1);
	exec16(0xA2);
	assert(__fu8(0x4000) == 143);
	OK;
	test("MOV MEM16, vCPU.AX");
	vCPU.AX = 1430;
	__iu16(0x4000, vCPU.EIP + 1);
	exec16(0xA3);
	assert(__fu16(0x4000) == 1430);
	OK;

	test("MOV vCPU.AL, MEM8");
	__iu8(167, 0x8000);
	__iu16(0x8000, vCPU.EIP + 1);
	exec16(0xA0);
	assert(vCPU.AL == 167);
	OK;
	test("MOV vCPU.AX, MEM16");
	__iu16(1670, 0x8000);
	__iu16(0x8000, vCPU.EIP + 1);
	exec16(0xA1);
	assert(vCPU.AX == 1670);
	OK;

	test("MOV REG8, IMM8");
	__iu8(0x1, vCPU.EIP + 1);
	exec16(0xB0); // MOV vCPU.AL, 1
	assert(vCPU.AL == 1);
	__iu8(0x2, vCPU.EIP + 1);
	exec16(0xB1); // MOV vCPU.CL, 2
	assert(vCPU.CL == 2);
	__iu8(0x3, vCPU.EIP + 1);
	exec16(0xB2); // MOV vCPU.DL, 3
	assert(vCPU.DL == 3);
	__iu8(0x4, vCPU.EIP + 1);
	exec16(0xB3); // MOV vCPU.BL, 4
	assert(vCPU.BL == 4);
	__iu8(0x5, vCPU.EIP + 1);
	exec16(0xB4); // MOV vCPU.AH, 5
	assert(vCPU.AH == 5);
	__iu8(0x6, vCPU.EIP + 1);
	exec16(0xB5); // MOV vCPU.CH, 6
	assert(vCPU.CH == 6);
	__iu8(0x7, vCPU.EIP + 1);
	exec16(0xB6); // MOV vCPU.DH, 7
	assert(vCPU.DH == 7);
	__iu8(0x8, vCPU.EIP + 1);
	exec16(0xB7); // MOV vCPU.BH, 8
	assert(vCPU.BH == 8);
	OK;

	test("MOV REG16, IMM16");
	__iu16(0x1112, vCPU.EIP + 1);
	exec16(0xB8); // MOV vCPU.AX, 1112h
	assert(vCPU.AX == 0x1112);
	__iu16(0x1113, vCPU.EIP + 1);
	exec16(0xB9); // MOV vCPU.CX, 1113h
	assert(vCPU.CX == 0x1113);
	__iu16(0x1114, vCPU.EIP + 1);
	exec16(0xBA); // MOV vCPU.DX, 1114h
	assert(vCPU.DX == 0x1114);
	__iu16(0x1115, vCPU.EIP + 1);
	exec16(0xBB); // MOV vCPU.BX, 1115h
	assert(vCPU.BX == 0x1115);
	__iu16(0x1116, vCPU.EIP + 1);
	exec16(0xBC); // MOV vCPU.SP, 1116h
	assert(vCPU.SP == 0x1116);
	__iu16(0x1117, vCPU.EIP + 1);
	exec16(0xBD); // MOV vCPU.BP, 1117h
	assert(vCPU.BP == 0x1117);
	__iu16(0x1118, vCPU.EIP + 1);
	exec16(0xBE); // MOV vCPU.SI, 1118h
	assert(vCPU.SI == 0x1118);
	__iu16(0x1119, vCPU.EIP + 1);
	exec16(0xBF); // MOV vCPU.DI, 1119h
	assert(vCPU.DI == 0x1119);
	OK;

	// MOV REG8, R/M8

	test("MOV R/M8, REG8");
	vCPU.AL = 34;
	__iu8(0b11_000_000, vCPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(vCPU.AL) == 34);
	vCPU.CL = 77;
	__iu8(0b11_001_000, vCPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(vCPU.AL) == 77);
	vCPU.DL = 123;
	__iu8(0b11_010_000, vCPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(vCPU.AL) == 123);
	vCPU.BL = 231;
	__iu8(0b11_011_000, vCPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(vCPU.AL) == 231);
	vCPU.AH = 88;
	__iu8(0b11_100_000, vCPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(vCPU.AL) == 88);
	vCPU.CH = 32;
	__iu8(0b11_101_000, vCPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(vCPU.AL) == 32);
	vCPU.DH = 32;
	__iu8(0b11_110_000, vCPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(vCPU.AL) == 32);
	vCPU.BH = 42;
	__iu8(0b11_111_000, vCPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(vCPU.AL) == 42);
	OK;

	test("MOV REG8, R/M8");
	vCPU.AL = 56;
	__iu8(vCPU.AL, vCPU.AL);
	__iu8(0b11_000_000, vCPU.EIP + 1);
	exec16(0x8A);
	assert(vCPU.AL == 56);
	vCPU.CL = 152;
	__iu8(vCPU.CL, vCPU.AL);
	__iu8(0b11_001_000, vCPU.EIP + 1);
	exec16(0x8A);
	assert(vCPU.CL == 152);
	vCPU.DL = 159;
	__iu8(vCPU.DL, vCPU.AL);
	__iu8(0b11_010_000, vCPU.EIP + 1);
	exec16(0x8A);
	assert(vCPU.DL == 159);
	vCPU.BL = 129;
	__iu8(vCPU.BL, vCPU.AL);
	__iu8(0b11_011_000, vCPU.EIP + 1);
	exec16(0x8A);
	assert(vCPU.BL == 129);
	vCPU.AH = 176;
	__iu8(vCPU.AH, vCPU.AL);
	__iu8(0b11_100_000, vCPU.EIP + 1);
	exec16(0x8A);
	assert(vCPU.AH == 176);
	vCPU.CH = 166;
	__iu8(vCPU.CH, vCPU.AL);
	__iu8(0b11_101_000, vCPU.EIP + 1);
	exec16(0x8A);
	assert(vCPU.CH == 166);
	vCPU.DH = 198;
	__iu8(vCPU.DH, vCPU.AL);
	__iu8(0b11_110_000, vCPU.EIP + 1);
	exec16(0x8A);
	assert(vCPU.DH == 198);
	vCPU.BH = 111;
	__iu8(vCPU.BH, vCPU.AL);
	__iu8(0b11_111_000, vCPU.EIP + 1);
	exec16(0x8A);
	assert(vCPU.BH == 111);
	OK;

	// MOV R/M16, REG16

	test("MOV R/M16, REG16");
	vCPU.AX = 344;
	__iu8(0b11_000_000, vCPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(vCPU.AX) == 344);
	vCPU.CX = 777;
	__iu8(0b11_001_000, vCPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(vCPU.AX) == 777);
	vCPU.DX = 1234;
	__iu8(0b11_010_000, vCPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(vCPU.AX) == 1234);
	vCPU.BX = 2311;
	__iu8(0b11_011_000, vCPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(vCPU.AX) == 2311);
	vCPU.SP = 8888;
	__iu8(0b11_100_000, vCPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(vCPU.AX) == 8888);
	vCPU.BP = 3200;
	__iu8(0b11_101_000, vCPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(vCPU.AX) == 3200);
	vCPU.SI = 3244;
	__iu8(0b11_110_000, vCPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(vCPU.AX) == 3244);
	vCPU.DI = 4212;
	__iu8(0b11_111_000, vCPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(vCPU.AX) == 4212);
	OK;

	test("MOV REG16, R/M16");
	vCPU.AX = 5600;
	__iu16(vCPU.AX, vCPU.AX);
	__iu8(0b11_000_000, vCPU.EIP + 1);
	exec16(0x8B);
	assert(vCPU.AX == 5600);
	vCPU.CX = 1520;
	__iu16(vCPU.CX, vCPU.AX);
	__iu8(0b11_001_000, vCPU.EIP + 1);
	exec16(0x8B);
	assert(vCPU.CX == 1520);
	vCPU.DX = 1590;
	__iu16(vCPU.DX, vCPU.AX);
	__iu8(0b11_010_000, vCPU.EIP + 1);
	exec16(0x8B);
	assert(vCPU.DX == 1590);
	vCPU.BX = 1290;
	__iu16(vCPU.BX, vCPU.AX);
	__iu8(0b11_011_000, vCPU.EIP + 1);
	exec16(0x8B);
	assert(vCPU.BX == 1290);
	vCPU.SP = 1760;
	__iu16(vCPU.SP, vCPU.AX);
	__iu8(0b11_100_000, vCPU.EIP + 1);
	exec16(0x8B);
	assert(vCPU.SP == 1760);
	vCPU.BP = 1660;
	__iu16(vCPU.BP, vCPU.AX);
	__iu8(0b11_101_000, vCPU.EIP + 1);
	exec16(0x8B);
	assert(vCPU.BP == 1660);
	vCPU.SI = 1984;
	__iu16(vCPU.SI, vCPU.AX);
	__iu8(0b11_110_000, vCPU.EIP + 1);
	exec16(0x8B);
	assert(vCPU.SI == 1984);
	vCPU.DI = 1110;
	__iu16(vCPU.DI, vCPU.AX);
	__iu8(0b11_111_000, vCPU.EIP + 1);
	exec16(0x8B);
	assert(vCPU.DI == 1110);
	OK;

	test("MOV R/M16, SEGREG");
	vCPU.CS = 123; vCPU.DS = 124; vCPU.ES = 125; vCPU.SS = 126;
	vCPU.AX = 0x4440; // address
	__iu8(0b11_101_000, vCPU.EIP + 1);
	exec16(0x8C);
	assert(__fu16(vCPU.AX) == vCPU.CS);
	__iu8(0b11_111_000, vCPU.EIP + 1);
	exec16(0x8C);
	assert(__fu16(vCPU.AX) == vCPU.DS);
	__iu8(0b11_100_000, vCPU.EIP + 1);
	exec16(0x8C);
	assert(__fu16(vCPU.AX) == vCPU.ES);
	__iu8(0b11_110_000, vCPU.EIP + 1);
	exec16(0x8C);
	assert(__fu16(vCPU.AX) == vCPU.SS);
	OK;

	test("MOV SEGREG, R/M16");
	__iu8(0b11_101_000, vCPU.EIP + 1);
	__iu16(8922, vCPU.AX);
	exec16(0x8E);
	assert(vCPU.CS == 8922);
	__iu8(0b11_111_000, vCPU.EIP + 1);
	__iu16(4932, vCPU.AX);
	exec16(0x8E);
	assert(vCPU.DS == 4932);
	__iu8(0b11_100_000, vCPU.EIP + 1);
	__iu16(7632, vCPU.AX);
	exec16(0x8E);
	assert(vCPU.ES == 7632);
	__iu8(0b11_110_000, vCPU.EIP + 1);
	__iu16(9999, vCPU.AX);
	exec16(0x8E);
	assert(vCPU.SS == 9999);
	OK;

	// -- ADD

	test("ADD vCPU.AL, IMM8");
	__iu8(4, vCPU.EIP + 1);
	vCPU.AL = 12;
	exec16(0x04);
	assert(vCPU.AL == 16);
	OK;

	test("ADD vCPU.AX, IMM16");
	__iu16(4, vCPU.EIP + 1);
	vCPU.AX = 1200;
	exec16(0x05);
	assert(vCPU.AX == 1204);
	OK;

	test("ADD REG8, R/M8");
	vCPU.CL = 0x20; // address
	vCPU.AL = 12;
	__iu8(0b11_000_001, vCPU.EIP + 1);
	__iu8(13, vCPU.CL);
	exec16(0x02);
	assert(vCPU.AL == 25);
	vCPU.CL = 13;
	vCPU.AL = 0x20; // address
	__iu8(0b11_001_000, vCPU.EIP + 1);
	__iu8(16, vCPU.AL);
	exec16(0x02);
	assert(vCPU.CL == 29);
	vCPU.CL = 0x20; // address
	vCPU.DL = 12;
	__iu8(0b11_010_001, vCPU.EIP + 1);
	__iu8(23, vCPU.CL);
	exec16(0x02);
	assert(vCPU.DL == 35);
	vCPU.CL = 0x20; // address
	vCPU.BL = 12;
	__iu8(0b11_011_001, vCPU.EIP + 1);
	__iu8(4, vCPU.CL);
	exec16(0x02);
	assert(vCPU.BL == 16);
	vCPU.CL = 0x20; // address
	vCPU.AH = 12;
	__iu8(0b11_100_001, vCPU.EIP + 1);
	__iu8(4, vCPU.CL);
	exec16(0x02);
	assert(vCPU.AH == 16);
	vCPU.CX = 0x04_20; // address:20h
	__iu8(0b11_101_001, vCPU.EIP + 1);
	__iu8(52, vCPU.CL);
	exec16(0x02);
	assert(vCPU.CH == 56);
	vCPU.CL = 0x20; // address
	vCPU.DH = 12;
	__iu8(0b11_110_001, vCPU.EIP + 1);
	__iu8(22, vCPU.CL);
	exec16(0x02);
	assert(vCPU.DH == 34);
	vCPU.CL = 0x20; // address
	vCPU.BH = 56;
	__iu8(0b11_111_001, vCPU.EIP + 1);
	__iu8(4, vCPU.CL);
	exec16(0x02);
	assert(vCPU.BH == 60);
	OK;

	test("ADD R/M8, REG8");
	vCPU.CL = 0x20; // address
	vCPU.AL = 12;
	__iu8(0b11_000_001, vCPU.EIP + 1);
	__iu8(13, vCPU.CL);
	exec16(0x00);
	assert(__fu8(vCPU.CL) == 25);
	vCPU.CL = 13;
	vCPU.AL = 0x20; // address
	__iu8(0b11_001_000, vCPU.EIP + 1);
	__iu8(16, vCPU.AL);
	exec16(0x00);
	assert(__fu8(vCPU.AL) == 29);
	vCPU.CL = 0x20; // address
	vCPU.DL = 12;
	__iu8(0b11_010_001, vCPU.EIP + 1);
	__iu8(23, vCPU.CL);
	exec16(0x00);
	assert(__fu8(vCPU.CL) == 35);
	vCPU.CL = 0x20; // address
	vCPU.BL = 12;
	__iu8(0b11_011_001, vCPU.EIP + 1);
	__iu8(4, vCPU.CL);
	exec16(0x00);
	assert(__fu8(vCPU.CL) == 16);
	vCPU.CL = 0x20; // address
	vCPU.AH = 12;
	__iu8(0b11_100_001, vCPU.EIP + 1);
	__iu8(4, vCPU.CL);
	exec16(0x00);
	assert(__fu8(vCPU.CL) == 16);
	vCPU.CX = 0x04_20; // address:20h
	__iu8(0b11_101_001, vCPU.EIP + 1);
	__iu8(52, vCPU.CL);
	exec16(0x00);
	assert(__fu8(vCPU.CL) == 56);
	vCPU.CL = 0x20; // address
	vCPU.DH = 12;
	__iu8(0b11_110_001, vCPU.EIP + 1);
	__iu8(22, vCPU.CL);
	exec16(0x00);
	assert(__fu8(vCPU.CL) == 34);
	vCPU.CL = 0x20; // address
	vCPU.BH = 56;
	__iu8(0b11_111_001, vCPU.EIP + 1);
	__iu8(4, vCPU.CL);
	exec16(0x00);
	assert(__fu8(vCPU.CL) == 60);
	OK;

	// MOV R/M16, REG16

	test("ADD REG16, R/M16"); TODO;
	test("ADD R/M16, REG16");
	vCPU.CX = 0x200; // address
	vCPU.AX = 22;
	__iu8(0b11_000_001, vCPU.EIP + 1);
	__iu16(23, vCPU.CX);
	exec16(0x01);
	assert(__fu16(vCPU.CX) == 45);
	vCPU.CX = 23;
	vCPU.AX = 0x200; // address
	__iu8(0b11_001_000, vCPU.EIP + 1);
	__iu16(23, vCPU.AX);
	exec16(0x01);
	assert(__fu16(vCPU.AX) == 46);
	vCPU.CX = 0x200; // address
	vCPU.DX = 24;
	__iu8(0b11_010_001, vCPU.EIP + 1);
	__iu16(23, vCPU.CX);
	exec16(0x01);
	assert(__fu16(vCPU.CX) == 47);
	vCPU.CX = 0x200; // address
	vCPU.BX = 25;
	__iu8(0b11_011_001, vCPU.EIP + 1);
	__iu16(23, vCPU.CX);
	exec16(0x01);
	assert(__fu16(vCPU.CX) == 48);
	vCPU.CX = 0x200; // address
	vCPU.SP = 26;
	__iu8(0b11_100_001, vCPU.EIP + 1);
	__iu16(23, vCPU.CX);
	exec16(0x01);
	assert(__fu16(vCPU.CX) == 49);
	vCPU.CX = 0x200; // address
	vCPU.BP = 27;
	__iu8(0b11_101_001, vCPU.EIP + 1);
	__iu16(23, vCPU.CX);
	exec16(0x01);
	assert(__fu16(vCPU.CX) == 50);
	vCPU.CX = 0x200; // address
	vCPU.SI = 28;
	__iu8(0b11_110_001, vCPU.EIP + 1);
	__iu16(23, vCPU.CX);
	exec16(0x01);
	assert(__fu16(vCPU.CX) == 51);
	vCPU.CX = 0x200; // address
	vCPU.DI = 29;
	__iu8(0b11_111_001, vCPU.EIP + 1);
	__iu16(23, vCPU.CX);
	exec16(0x01);
	assert(__fu16(vCPU.CX) == 52);
	OK;

	// -- OR

	test("OR vCPU.AL, IMM8");
	__iu8(0xF0, vCPU.EIP + 1);
	vCPU.AL = 0xF;
	exec16(0xC); // OR vCPU.AL, 3
	assert(vCPU.AL == 0xFF);
	OK;

	test("OR vCPU.AX, IMM16");
	__iu16(0xFF00, vCPU.EIP + 1);
	exec16(0xD); // OR vCPU.AX, F0h
	assert(vCPU.AX == 0xFFFF);
	OK;

	// MOV REG8, R/M8

	test("OR REG8, R/M8"); TODO;
	test("OR R/M8, REG8"); TODO;

	// MOV R/M16, REG16

	test("OR REG16, R/M16"); TODO;
	test("OR R/M16, REG16"); TODO;

	// XOR

	test("XOR vCPU.AL, IMM8");
	__iu8(5, vCPU.EIP + 1);
	vCPU.AL = 0xF;
	exec16(0x34); // XOR vCPU.AL, 5
	assert(vCPU.AL == 0xA);
	OK;

	test("XOR vCPU.AX, IMM16");
	__iu16(0xFF00, vCPU.EIP + 1);
	vCPU.AX = 0xAAFF;
	exec16(0x35); // XOR vCPU.AX, FF00h
	assert(vCPU.AX == 0x55FF);
	OK;

	// INC

	test("INC REG16");
	fullreset; vCPU.CS = 0;
	exec16(0x40);
	assert(vCPU.AX == 1);
	exec16(0x41);
	assert(vCPU.CX == 1);
	exec16(0x42);
	assert(vCPU.DX == 1);
	exec16(0x43);
	assert(vCPU.BX == 1);
	exec16(0x44);
	assert(vCPU.SP == 1);
	exec16(0x45);
	assert(vCPU.BP == 1);
	exec16(0x46);
	assert(vCPU.SI == 1);
	exec16(0x47);
	assert(vCPU.DI == 1);
	OK;
	
	// DEC

	test("DEC REG16");
	exec16(0x48);
	assert(vCPU.AX == 0);
	exec16(0x49);
	assert(vCPU.CX == 0);
	exec16(0x4A);
	assert(vCPU.DX == 0);
	exec16(0x4B);
	assert(vCPU.BX == 0);
	exec16(0x4C);
	assert(vCPU.SP == 0);
	exec16(0x4D);
	assert(vCPU.BP == 0);
	exec16(0x4E);
	assert(vCPU.SI == 0);
	exec16(0x4F);
	assert(vCPU.DI == 0);
	OK;

	// PUSH

	test("PUSH REG16");

	vCPU.SS = 0x100;
	vCPU.SP = 0x60;

	vCPU.AX = 0xDAD;
	exec16(0x50);
	assert(vCPU.AX == __fu16(get_ad(vCPU.SS, vCPU.SP)));
	push(vCPU.AX);
	assert(vCPU.AX == __fu16(get_ad(vCPU.SS, vCPU.SP)));

	vCPU.CX = 0x4488;
	exec16(0x51);
	assert(vCPU.CX == __fu16(get_ad(vCPU.SS, vCPU.SP)));

	vCPU.DX = 0x4321;
	exec16(0x52);
	assert(vCPU.DX == __fu16(get_ad(vCPU.SS, vCPU.SP)));

	vCPU.BX = 0x1234;
	exec16(0x53);
	assert(vCPU.BX == __fu16(get_ad(vCPU.SS, vCPU.SP)));

	exec16(0x54);
	assert(vCPU.SP == __fu16(get_ad(vCPU.SS, vCPU.SP)) - 2);

	vCPU.BP = 0xFBAC;
	exec16(0x55);
	assert(vCPU.BP == __fu16(get_ad(vCPU.SS, vCPU.SP)));

	vCPU.SI = 0xF00F;
	exec16(0x56);
	assert(vCPU.SI == __fu16(get_ad(vCPU.SS, vCPU.SP)));

	vCPU.DI = 0xB0B;
	exec16(0x57);
	assert(vCPU.DI == __fu16(get_ad(vCPU.SS, vCPU.SP)));

	OK;

	// POP

	test("POP REG16");

	vCPU.SS = 0x100;
	vCPU.SP = 0x20;

	push(0xFFAA);
	exec16(0x58);
	assert(vCPU.AX == 0xFFAA);
	vCPU.SP -= 2;
	exec16(0x59);
	assert(vCPU.CX == 0xFFAA);
	vCPU.SP -= 2;
	exec16(0x5A);
	assert(vCPU.DX == 0xFFAA);
	vCPU.SP -= 2;
	exec16(0x5B);
	assert(vCPU.BX == 0xFFAA);
	vCPU.SP -= 2;
	exec16(0x5C);
	assert(vCPU.SP == 0xFFAA);
	vCPU.SP = 0x1E;
	exec16(0x5D);
	assert(vCPU.BP == 0xFFAA);
	vCPU.SP -= 2;
	exec16(0x5E);
	assert(vCPU.SI == 0xFFAA);
	vCPU.SP -= 2;
	exec16(0x5F);
	assert(vCPU.DI == 0xFFAA);

	OK;

	// XCHG

	test("XCHG");

	// Nevertheless, let's test the Program Counter
	{
		const uint oldip = vCPU.IP;
		exec16(0x90);
		assert(oldip + 1 == vCPU.IP);
	}

	vCPU.AX = 0xFAB;
	vCPU.CX = 0xAABB;
	exec16(0x91);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.CX == 0xFAB);

	vCPU.AX = 0xFAB;
	vCPU.DX = 0xAABB;
	exec16(0x92);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.DX == 0xFAB);

	vCPU.AX = 0xFAB;
	vCPU.BX = 0xAABB;
	exec16(0x93);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.BX == 0xFAB);

	vCPU.AX = 0xFAB;
	vCPU.SP = 0xAABB;
	exec16(0x94);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.SP == 0xFAB);

	vCPU.AX = 0xFAB;
	vCPU.BP = 0xAABB;
	exec16(0x95);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.BP == 0xFAB);

	vCPU.AX = 0xFAB;
	vCPU.SI = 0xAABB;
	exec16(0x96);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.SI == 0xFAB);

	vCPU.AX = 0xFAB;
	vCPU.DI = 0xAABB;
	exec16(0x97);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.DI == 0xFAB);

	OK;

	// CBW

	test("CBW");
	vCPU.AL = 0;
	exec16(0x98);
	assert(vCPU.AH == 0);
	vCPU.AL = 0xFF;
	exec16(0x98);
	assert(vCPU.AH == 0xFF);
	OK;

	// CWD

	test("CWD");
	vCPU.AX = 0;
	exec16(0x99);
	assert(vCPU.DX == 0);
	vCPU.AX = 0xFFFF;
	exec16(0x99);
	assert(vCPU.DX == 0xFFFF);
	OK;

	// TEST

	test("TEST vCPU.AL, IMM8");
	vCPU.AL = 0b1100;
	__iu8(0b1100, vCPU.EIP + 1);
	exec16(0xA8);
	assert(PF);
	assert(ZF == 0);
	assert(SF == 0);
	assert(CF == 0);
	assert(OF == 0);
	vCPU.AL = 0xF0;
	__iu8(0x0F, vCPU.EIP + 1);
	exec16(0xA8);
	assert(PF);
	assert(ZF);
	assert(SF == 0);
	assert(CF == 0);
	assert(OF == 0);
	OK;

	test("TEST vCPU.AX, IMM16");
	vCPU.AX = 0xAA00;
	__iu16(0xAA00, vCPU.EIP + 1);
	exec16(0xA9);
	assert(PF);
	assert(ZF == 0);
	assert(SF);
	assert(CF == 0);
	assert(OF == 0);
	OK;

	test("TEST R/M8, REG8");
	vCPU.AL = 0x60; // address
	vCPU.CL = 40;
	__iu8(0b11_001_000, vCPU.EIP+1);
	__iu8(20, vCPU.AL);
	exec16(0x85);
	assert(ZF);
	OK;
	test("TEST R/M16, REG16");
	vCPU.AX = 0x600; // address
	vCPU.CX = 400;
	__iu8(0b11_001_000, vCPU.EIP+1);
	__iu16(200, vCPU.AL);
	exec16(0x86);
	assert(ZF);
	OK;

	test("LEA REG16, MEM16"); TODO;

	sub("Group1 8");

	test("ADD");
	vCPU.AL = 0x40;
	__iu8(10, vCPU.AL);
	__iu8(0b11_000_000, vCPU.EIP+1);
	__iu8(20, vCPU.EIP+2);
	exec16(0x80);
	assert(__fu8(vCPU.AL) == 30);
	OK;
	test("OR");
	vCPU.AL = 0x40;
	__iu8(0b1100_0011, vCPU.AL);
	__iu8(0b11_001_000, vCPU.EIP+1);
	__iu8(0b0011_0000, vCPU.EIP+2);
	exec16(0x80);
	assert(__fu8(vCPU.AL) == 0b1111_0011);
	OK;
	test("ADC"); TODO;
	test("SBB"); TODO;
	test("AND");
	vCPU.AL = 0x40;
	__iu8(0b0011_0011, vCPU.AL);
	__iu8(0b11_100_000, vCPU.EIP+1);
	__iu8(0b0011_0000, vCPU.EIP+2);
	exec16(0x80);
	assert(__fu8(vCPU.AL) == 0b0011_0000);
	OK;
	test("SUB/CMP");
	vCPU.AL = 0x40;
	__iu8(45, vCPU.AL);
	__iu8(0b11_101_000, vCPU.EIP+1);
	__iu8(20, vCPU.EIP+2);
	exec16(0x80);
	assert(__fu8(vCPU.AL) == 25);
	OK;
	test("XOR");
	vCPU.AL = 0x40;
	__iu8(40, vCPU.AL);
	__iu8(0b11_110_000, vCPU.EIP+1);
	__iu8(20, vCPU.EIP+2);
	exec16(0x80);
	assert(__fu8(vCPU.AL) == 60);
	OK;

	sub("Group1 16");

	test("ADD");
	vCPU.AX = 0x400;
	__iu16(40, vCPU.AX);
	__iu8(0b11_000_000, vCPU.EIP+1);
	__iu16(222, vCPU.EIP+2);
	exec16(0x81);
	assert(__fu16(vCPU.AX) == 262);
	OK;
	test("OR");
	vCPU.AX = 0x400;
	__iu16(40, vCPU.AX);
	__iu8(0b11_001_000, vCPU.EIP+1);
	__iu16(222, vCPU.EIP+2);
	exec16(0x81);
	assert(__fu16(vCPU.AX) == 254);
	OK;
	test("ADC"); TODO;
	test("SBB"); TODO;
	test("AND");
	vCPU.AX = 0x400;
	__iu16(40, vCPU.AX);
	__iu8(0b11_100_000, vCPU.EIP+1);
	__iu16(222, vCPU.EIP+2);
	exec16(0x81);
	assert(__fu16(vCPU.AX) == 8);
	OK;
	test("SUB/CMP");
	vCPU.AX = 0x400;
	__iu16(222, vCPU.AX);
	__iu8(0b11_101_000, vCPU.EIP+1);
	__iu16(40, vCPU.EIP+2);
	exec16(0x81);
	assert(__fu16(vCPU.AX) == 182);
	OK;
	test("XOR");
	vCPU.AX = 0x400;
	__iu16(222, vCPU.AX);
	__iu8(0b11_110_000, vCPU.EIP+1);
	__iu16(40, vCPU.EIP+2);
	exec16(0x81);
	assert(__fu16(vCPU.AX) == 246);
	OK;

	sub("Group2 8");

	test("ADD");
	vCPU.AL = 0x40;
	__iu8(40, vCPU.AL);
	__iu8(0b11_000_000, vCPU.EIP+1);
	__iu8(20, vCPU.EIP+2);
	exec16(0x82);
	assert(__fu8(vCPU.AL) == 60);
	OK;
	test("ADC"); TODO;
	test("SBB"); TODO;
	test("SUB/CMP");
	vCPU.AL = 0x40;
	__iu8(40, vCPU.AL);
	__iu8(0b11_101_000, vCPU.EIP+1);
	__iu8(20, vCPU.EIP+2);
	exec16(0x82);
	assert(__fu8(vCPU.AL) == 20);
	OK;

	sub("Group2 16");

	test("ADD");
	vCPU.AX = 0x400;
	__iu16(40, vCPU.AX);
	__iu8(0b11_000_000, vCPU.EIP+1);
	__iu16(20, vCPU.EIP+2);
	exec16(0x83);
	assert(__fu16(vCPU.AX) == 60);
	OK;
	test("ADC"); TODO;
	test("SBB"); TODO;
	test("SUB/CMP");
	vCPU.AX = 0x400;
	__iu16(40, vCPU.AX);
	__iu8(0b11_101_000, vCPU.EIP + 1);
	__iu16(25, vCPU.EIP + 2);
	exec16(0x83);
	assert(__fu16(vCPU.AX) == 15);
	OK;

	sub("Group3 8");
	test("TEST");
	vCPU.AL = 130;
	__iu8(0xAF, vCPU.AL);
	__iu8(0b11_000_000, vCPU.EIP + 1);
	__iu8(0xF, vCPU.EIP + 2);
	exec16(0xF6);
	assert(ZF == 0 && OF == 0);
	OK;
	test("NOT");
	__iu8(0b11_010_000, vCPU.EIP + 1);
	__iu8(0xF, vCPU.AL);
	exec16(0xF6);
	assert(__fu8(vCPU.AL) == 0xF0);
	OK;
	test("NEG");
	__iu8(0b11_011_000, vCPU.EIP + 1);
	__iu8(0xF, vCPU.AL);
	exec16(0xF6);
	assert(__fu8(vCPU.AL) == 0xF1);
	assert(ZF == 0);
	assert(OF == 0);
	OK;
	test("MUL");
	__iu8(0b11_100_000, vCPU.EIP + 1);
	__iu8(2, vCPU.EIP + 2);
	__iu8(4, vCPU.AL);
	exec16(0xF6);
	assert(__fu8(vCPU.AL) == 8);
	assert(ZF == 0);
	OK;
	test("IMUL");
	__iu8(0b11_101_000, vCPU.EIP + 1);
	__iu8(-2, vCPU.EIP + 2);
	__iu8(4, vCPU.AL);
	exec16(0xF6);
	assert(__fu8(vCPU.AL) == 0xF8); // -8 as BYTE
	assert(ZF == 0);
	OK;
	test("DIV");
	vCPU.AX = 12;
	__iu8(0b11_110_000, vCPU.EIP + 1);
	__iu8(8, vCPU.AL);
	exec16(0xF6);
	assert(vCPU.AL == 1);
	assert(vCPU.AH == 4);
	OK;
	test("IDIV");
	vCPU.AX = 0xFFF4; // -12
	__iu8(0b11_111_000, vCPU.EIP + 1);
	__iu8(8, vCPU.AL);
	exec16(0xF6);
	assert(vCPU.AL == 0xFF);
	assert(vCPU.AH == 0xFC);
	OK;

	sub("Group3 16"); TODO;

	sub("Array intructions");

	test("XLAT SOURCE-TABLE");
	vCPU.AL = 10;
	vCPU.DS = 0x400;
	vCPU.BX = 0x20;
	__iu8(36, get_ad(vCPU.DS, vCPU.BX) + vCPU.AL);
	exec16(0xD7);
	assert(vCPU.AL == 36);
	OK;

	// -- STRING INSTRUCTIONS --
	
	sub("String instructions");

	// STOS

	test("STOS");
	vCPU.ES = 0x20; vCPU.DI = 0x20;        
	vCPU.AL = 'Q';
	exec16(0xAA);
	assert(MEMORY[get_ad(vCPU.ES, vCPU.DI - 1)] == 'Q');
	OK;

	test("STOSW");
	vCPU.ES = 0x200; vCPU.DI = 0x200;        
	vCPU.AX = 0xACDC;
	exec16(0xAB);
	assert(__fu16(get_ad(vCPU.ES, vCPU.DI - 2)) == 0xACDC);
	OK;

	// LODS

	test("LODS"); // of dosh
	vCPU.AL = 0;
	vCPU.DS = 0xA0; vCPU.SI = 0x200;
	MEMORY[get_ad(vCPU.DS, vCPU.SI)] = 'H';
	exec16(0xAC);
	assert(vCPU.AL == 'H');
	MEMORY[get_ad(vCPU.DS, vCPU.SI)] = 'e';
	exec16(0xAC);
	assert(vCPU.AL == 'e');
	OK;

	test("LODSW");
	vCPU.AX = 0;
	vCPU.DS = 0x40; vCPU.SI = 0x80;
	__iu16(0x48AA, get_ad(vCPU.DS, vCPU.SI));
	exec16(0xAD);
	assert(vCPU.AX == 0x48AA);
	__iu16(0x65BB, get_ad(vCPU.DS, vCPU.SI));
	exec16(0xAD);
	assert(vCPU.AX == 0x65BB);
	OK;

	// SCAS

	test("SCAS");
	vCPU.ES = vCPU.CS = 0x400; vCPU.DI = 0x20; vCPU.IP = 0x20;
	vCPU.EIP = get_ip;
	__istr("Hello!");
	vCPU.AL = 'H';
	exec16(0xAE);
	assert(ZF);
	vCPU.AL = '1';
	exec16(0xAE);
	assert(!ZF);
	OK;

	test("SCASW");
	vCPU.CS = 0x800; vCPU.ES = 0x800; vCPU.EIP = 0x30; vCPU.DI = 0x30;
	__iu16(0xFE22, get_ad(vCPU.ES, vCPU.DI));
	vCPU.AX = 0xFE22;
	exec16(0xAF);
	assert(ZF);
	exec16(0xAF);
	assert(!ZF);
	OK;

	DF = 0;

	// CMPS

	test("CMPS");
	vCPU.CS = vCPU.ES = 0xF00; vCPU.DI = vCPU.EIP = 0x100;
	__istr("HELL", get_ip);
	vCPU.CS = vCPU.DS = 0xF00; vCPU.SI = vCPU.EIP = 0x110;
	__istr("HeLL", get_ip);
	exec16(0xA6);
	assert(ZF);
	exec16(0xA6);
	assert(!ZF);
	exec16(0xA6);
	assert(ZF);
	exec16(0xA6);
	assert(ZF);
	OK;

	test("CMPSW");
	vCPU.CS = vCPU.ES = 0xF00; vCPU.DI = vCPU.EIP = 0x100;
	__iwstr("HELL"w, get_ip);
	vCPU.CS = vCPU.DS = 0xF00; vCPU.SI = vCPU.EIP = 0x110;
	__iwstr("HeLL"w, get_ip);
	exec16(0xA7);
	assert(ZF);
	exec16(0xA7);
	assert(!ZF);
	exec16(0xA7);
	assert(ZF);
	exec16(0xA7);
	assert(ZF);
	OK;
}