import vcpu, vcpu_utils, vcpu16, std.stdio, vdos;
import test_utils;

unittest {
	vcpu_init;
	CPU.CS = 0;
	CPU.EIP = get_ip;

	section("Interpreter Utilities (vcpu_utils.d)");

	test("__iu8");
	__iu8(0xFF, CPU.EIP);
	assert(MEMORY[CPU.EIP]     == 0xFF);
	__iu8(0x12, CPU.EIP + 2);
	assert(MEMORY[CPU.EIP + 2] == 0x12);
	OK;

	test("__iu16");
	__iu16(0x100, CPU.EIP);
	assert(MEMORY[CPU.EIP]     == 0);
	assert(MEMORY[CPU.EIP + 1] == 1);
	__iu16(0xABCD, CPU.EIP);
	assert(MEMORY[CPU.EIP]     == 0xCD);
	assert(MEMORY[CPU.EIP + 1] == 0xAB);
	__iu16(0x5678, 4);
	assert(MEMORY[4] == 0x78);
	assert(MEMORY[5] == 0x56);
	OK;

	test("__iu32");
	__iu32(0xAABBCCFF, CPU.EIP);
	assert(MEMORY[CPU.EIP    ] == 0xFF);
	assert(MEMORY[CPU.EIP + 1] == 0xCC);
	assert(MEMORY[CPU.EIP + 2] == 0xBB);
	assert(MEMORY[CPU.EIP + 3] == 0xAA);
	OK;

	__iu8(0xAC, CPU.EIP + 1);

	test("__fu8");
	assert(__fu8(CPU.EIP + 1) == 0xAC);
	OK;

	test("__fu8_i");
	assert(__fu8_i == 0xAC);
	OK;

	test("__fi8");
	assert(__fi8(CPU.EIP + 1) == cast(byte)0xAC);
	OK;

	test("__fi8_i");
	assert(__fi8_i == cast(byte)0xAC);
	OK;

	__iu16(0xAAFF, CPU.EIP + 1);

	test("__fu16");
	assert(__fu16(CPU.EIP + 1) == 0xAAFF);
	OK;

	test("__fi16");
	assert(__fi16(CPU.EIP + 1) == cast(short)0xAAFF);
	OK;

	test("__fu16_i");
	assert(__fu16_i == 0xAAFF);
	OK;

	test("__fi16_i");
	assert(__fi16_i == cast(short)0xAAFF);
	OK;

	test("__fu32");
	__iu32(0xDCBA_FF00, CPU.EIP + 1);
	assert(__fu32(CPU.EIP + 1) == 0xDCBA_FF00);
	OK;

	/*test("__fu32_i");
	assert(__fu32_i == 0xDCBA_FF00);
	OK;*/

	test("__istr");
	__istr("AB$");
	assert(MEMORY[CPU.EIP .. CPU.EIP + 3] == "AB$");
	__istr("QWERTY", CPU.EIP + 10);
	assert(MEMORY[CPU.EIP + 10 .. CPU.EIP + 16] == "QWERTY");
	OK;

	test("__iwstr");
	__iwstr("Hi!!"w);
	assert(MEMORY[CPU.EIP     .. CPU.EIP + 1] == "H"w);
	assert(MEMORY[CPU.EIP + 2 .. CPU.EIP + 3] == "i"w);
	assert(MEMORY[CPU.EIP + 4 .. CPU.EIP + 5] == "!"w);
	assert(MEMORY[CPU.EIP + 6 .. CPU.EIP + 7] == "!"w);
	OK;

	test("__iarr");
	ubyte[2] ar = [ 0xAA, 0xBB ];
	__iarr(cast(ubyte*)ar, 2, CPU.EIP);
	assert(MEMORY[CPU.EIP .. CPU.EIP + 2] == [ 0xAA, 0xBB ]);
	OK;

	section("Registers");

	test("AL/AH");
	CPU.EAX = 0x40_0807;
	assert(CPU.AL == 7);
	assert(CPU.AH == 8);
	OK;

	test("BL/BH");
	CPU.EBX = 0x41_0605;
	assert(CPU.BL == 5);
	assert(CPU.BH == 6);
	OK;

	test("CL/CH");
	CPU.ECX = 0x42_0403;
	assert(CPU.CL == 3);
	assert(CPU.CH == 4);
	OK;

	test("DL/DH");
	CPU.EDX = 0x43_0201;
	assert(CPU.DL == 1);
	assert(CPU.DH == 2);
	OK;

	test("AX");
	assert(CPU.AX == 0x0807);
	OK;

	test("BX");
	assert(CPU.BX == 0x0605);
	OK;

	test("CX");
	assert(CPU.CX == 0x0403);
	OK;

	test("DX");
	assert(CPU.DX == 0x0201);
	OK;

	test("SI");
	CPU.ESI = 0x44_9001;
	assert(CPU.SI == 0x9001);
	OK;

	test("DI");
	CPU.EDI = 0x44_9002;
	assert(CPU.DI == 0x9002);
	OK;

	test("BP");
	CPU.EBP = 0x44_9003;
	assert(CPU.BP == 0x9003);
	OK;

	test("SP");
	CPU.ESP = 0x44_9004;
	assert(CPU.SP == 0x9004);
	OK;

	test("IP");
	CPU.EIP = 0x40_0F50;
	assert(CPU.IP == 0x0F50);
	CPU.EIP = 0x100;
	OK;

	test("FLAG");
	FLAG = 0xFFFF;
	assert(CPU.SF); assert(CPU.ZF); assert(CPU.AF);
	assert(CPU.PF); assert(CPU.CF); assert(CPU.OF);
	assert(CPU.DF); assert(CPU.IF); assert(CPU.TF);
	assert(FLAGB == 0xD5);
	assert(FLAG == 0xFD5);
	FLAG = 0;
	assert(CPU.SF == 0); assert(CPU.ZF == 0); assert(CPU.AF == 0);
	assert(CPU.PF == 0); assert(CPU.CF == 0); assert(CPU.OF == 0);
	assert(CPU.DF == 0); assert(CPU.IF == 0); assert(CPU.TF == 0);
	assert(FLAGB == 0); assert(FLAG == 0);
	OK;

	section("ModR/M");

	__iu16(0x1020, CPU.EIP + 2); // low:20h
	CPU.SI = 0x50; CPU.DI = 0x50;
	CPU.BX = 0x30; CPU.BP = 0x30;
	test("16-bit ModR/M (MOD=00)");
	assert(get_rm16(0b000) == 0x80);
	assert(get_rm16(0b001) == 0x80);
	assert(get_rm16(0b010) == 0x80);
	assert(get_rm16(0b011) == 0x80);
	assert(get_rm16(0b100) == 0x50);
	assert(get_rm16(0b101) == 0x50);
	assert(get_rm16(0b110) == 0x1020);
	assert(get_rm16(0b111) == 0x30);
	OK;
	test("16-bit ModR/M (MOD=01)");
	assert(get_rm16(0b01_000_000) == 0xA0);
	assert(get_rm16(0b01_000_001) == 0xA0);
	assert(get_rm16(0b01_000_010) == 0xA0);
	assert(get_rm16(0b01_000_011) == 0xA0);
	assert(get_rm16(0b01_000_100) == 0x70);
	assert(get_rm16(0b01_000_101) == 0x70);
	assert(get_rm16(0b01_000_110) == 0x50);
	assert(get_rm16(0b01_000_111) == 0x50);
	OK;
	test("16-bit ModR/M (MOD=10)");
	assert(get_rm16(0b10_000_000) == 0x10A0);
	assert(get_rm16(0b10_000_001) == 0x10A0);
	assert(get_rm16(0b10_000_010) == 0x10A0);
	assert(get_rm16(0b10_000_011) == 0x10A0);
	assert(get_rm16(0b10_000_100) == 0x1070);
	assert(get_rm16(0b10_000_101) == 0x1070);
	assert(get_rm16(0b10_000_110) == 0x1050);
	assert(get_rm16(0b10_000_111) == 0x1050);
	OK;
	test("16-bit ModR/M (MOD=11)");
	CPU.AX = 0x2040; CPU.CX = 0x2141;
	CPU.DX = 0x2242; CPU.BX = 0x2343;
	CPU.SP = 0x2030; CPU.BP = 0x2131;
	CPU.SI = 0x2232; CPU.DI = 0x2333;
	assert(get_rm16(0b11_000_000) == 0x40); // AL
	assert(get_rm16(0b11_000_001) == 0x41); // CL
	assert(get_rm16(0b11_000_010) == 0x42); // DL
	assert(get_rm16(0b11_000_011) == 0x43); // BL
	assert(get_rm16(0b11_000_100) == 0x20); // AH
	assert(get_rm16(0b11_000_101) == 0x21); // CH
	assert(get_rm16(0b11_000_110) == 0x22); // DH
	assert(get_rm16(0b11_000_111) == 0x23); // BH
	OK;
	test("16-bit ModR/M (MOD=11+W)");
	assert(get_rm16(0b11_000_000, 1) == 0x2040); // AX
	assert(get_rm16(0b11_000_001, 1) == 0x2141); // CX
	assert(get_rm16(0b11_000_010, 1) == 0x2242); // DX
	assert(get_rm16(0b11_000_011, 1) == 0x2343); // BX
	assert(get_rm16(0b11_000_100, 1) == 0x2030); // SP
	assert(get_rm16(0b11_000_101, 1) == 0x2131); // BP
	assert(get_rm16(0b11_000_110, 1) == 0x2232); // SI
	assert(get_rm16(0b11_000_111, 1) == 0x2333); // DI
	OK;

	test("32-bit ModR/M (MOD=00)"); TODO;
	test("32-bit ModR/M (MOD=01)"); TODO;
	test("32-bit ModR/M (MOD=10)"); TODO;
	test("32-bit ModR/M (MOD=11)"); TODO;
	test("32-bit ModR/M (MOD=11+W)"); TODO;

	section("16-bit Instructions (8086)");

	// ADD

	test("00h  ADD R/M8, REG8");
	CPU.CL = 0x20; // address
	CPU.AL = 12;
	__iu8(0b11_000_001, CPU.EIP + 1);
	__iu8(13, CPU.CL);
	exec16(0x00);
	assert(__fu8(CPU.CL) == 25);
	CPU.CL = 13;
	CPU.AL = 0x20; // address
	__iu8(0b11_001_000, CPU.EIP + 1);
	__iu8(16, CPU.AL);
	exec16(0x00);
	assert(__fu8(CPU.AL) == 29);
	CPU.CL = 0x20; // address
	CPU.DL = 12;
	__iu8(0b11_010_001, CPU.EIP + 1);
	__iu8(23, CPU.CL);
	exec16(0x00);
	assert(__fu8(CPU.CL) == 35);
	CPU.CL = 0x20; // address
	CPU.BL = 12;
	__iu8(0b11_011_001, CPU.EIP + 1);
	__iu8(4, CPU.CL);
	exec16(0x00);
	assert(__fu8(CPU.CL) == 16);
	CPU.CL = 0x20; // address
	CPU.AH = 12;
	__iu8(0b11_100_001, CPU.EIP + 1);
	__iu8(4, CPU.CL);
	exec16(0x00);
	assert(__fu8(CPU.CL) == 16);
	CPU.CX = 0x04_20; // address:20h
	__iu8(0b11_101_001, CPU.EIP + 1);
	__iu8(52, CPU.CL);
	exec16(0x00);
	assert(__fu8(CPU.CL) == 56);
	CPU.CL = 0x20; // address
	CPU.DH = 12;
	__iu8(0b11_110_001, CPU.EIP + 1);
	__iu8(22, CPU.CL);
	exec16(0x00);
	assert(__fu8(CPU.CL) == 34);
	CPU.CL = 0x20; // address
	CPU.BH = 56;
	__iu8(0b11_111_001, CPU.EIP + 1);
	__iu8(4, CPU.CL);
	exec16(0x00);
	assert(__fu8(CPU.CL) == 60);
	OK;

	test("01h  ADD R/M16, REG16");
	CPU.CX = 0x200; // address
	CPU.AX = 22;
	__iu8(0b11_000_001, CPU.EIP + 1);
	__iu16(23, CPU.CX);
	exec16(0x01);
	assert(__fu16(CPU.CX) == 45);
	CPU.CX = 23;
	CPU.AX = 0x200; // address
	__iu8(0b11_001_000, CPU.EIP + 1);
	__iu16(23, CPU.AX);
	exec16(0x01);
	assert(__fu16(CPU.AX) == 46);
	CPU.CX = 0x200; // address
	CPU.DX = 24;
	__iu8(0b11_010_001, CPU.EIP + 1);
	__iu16(23, CPU.CX);
	exec16(0x01);
	assert(__fu16(CPU.CX) == 47);
	CPU.CX = 0x200; // address
	CPU.BX = 25;
	__iu8(0b11_011_001, CPU.EIP + 1);
	__iu16(23, CPU.CX);
	exec16(0x01);
	assert(__fu16(CPU.CX) == 48);
	CPU.CX = 0x200; // address
	CPU.SP = 26;
	__iu8(0b11_100_001, CPU.EIP + 1);
	__iu16(23, CPU.CX);
	exec16(0x01);
	assert(__fu16(CPU.CX) == 49);
	CPU.CX = 0x200; // address
	CPU.BP = 27;
	__iu8(0b11_101_001, CPU.EIP + 1);
	__iu16(23, CPU.CX);
	exec16(0x01);
	assert(__fu16(CPU.CX) == 50);
	CPU.CX = 0x200; // address
	CPU.SI = 28;
	__iu8(0b11_110_001, CPU.EIP + 1);
	__iu16(23, CPU.CX);
	exec16(0x01);
	assert(__fu16(CPU.CX) == 51);
	CPU.CX = 0x200; // address
	CPU.DI = 29;
	__iu8(0b11_111_001, CPU.EIP + 1);
	__iu16(23, CPU.CX);
	exec16(0x01);
	assert(__fu16(CPU.CX) == 52);
	OK;
	
	test("02h  ADD REG8, R/M8");
	CPU.CL = 0x20; // address
	CPU.AL = 12;
	__iu8(0b11_000_001, CPU.EIP + 1);
	__iu8(13, CPU.CL);
	exec16(0x02);
	assert(CPU.AL == 25);
	CPU.CL = 13;
	CPU.AL = 0x20; // address
	__iu8(0b11_001_000, CPU.EIP + 1);
	__iu8(16, CPU.AL);
	exec16(0x02);
	assert(CPU.CL == 29);
	CPU.CL = 0x20; // address
	CPU.DL = 12;
	__iu8(0b11_010_001, CPU.EIP + 1);
	__iu8(23, CPU.CL);
	exec16(0x02);
	assert(CPU.DL == 35);
	CPU.CL = 0x20; // address
	CPU.BL = 12;
	__iu8(0b11_011_001, CPU.EIP + 1);
	__iu8(4, CPU.CL);
	exec16(0x02);
	assert(CPU.BL == 16);
	CPU.CL = 0x20; // address
	CPU.AH = 12;
	__iu8(0b11_100_001, CPU.EIP + 1);
	__iu8(4, CPU.CL);
	exec16(0x02);
	assert(CPU.AH == 16);
	CPU.CX = 0x04_20; // address:20h
	__iu8(0b11_101_001, CPU.EIP + 1);
	__iu8(52, CPU.CL);
	exec16(0x02);
	assert(CPU.CH == 56);
	CPU.CL = 0x20; // address
	CPU.DH = 12;
	__iu8(0b11_110_001, CPU.EIP + 1);
	__iu8(22, CPU.CL);
	exec16(0x02);
	assert(CPU.DH == 34);
	CPU.CL = 0x20; // address
	CPU.BH = 56;
	__iu8(0b11_111_001, CPU.EIP + 1);
	__iu8(4, CPU.CL);
	exec16(0x02);
	assert(CPU.BH == 60);
	OK;

	test("03h  ADD REG16, R/M16");
	CPU.CX = 400; // address
	CPU.AX = 40;
	__iu16(280, CPU.CX);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x03);
	assert(CPU.AX == 320);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	test("04h  ADD AL, IMM8");
	__iu8(4, CPU.EIP + 1);
	CPU.AL = 12;
	exec16(0x04);
	assert(CPU.AL == 16);
	OK;

	test("05h  ADD AX, IMM16");
	__iu16(4, CPU.EIP + 1);
	CPU.AX = 1200;
	exec16(0x05);
	assert(CPU.AX == 1204);
	OK;

	// PUSH ES

	test("06h  PUSH ES");
	CPU.ES = 189;
	exec16(0x06);
	assert(__fu16(get_ad(CPU.SS, CPU.SP)) == 189);
	OK;

	// POP ES

	test("07h  POP ES");
	CPU.ES = 83;
	exec16(0x07);
	assert(CPU.ES == 189); // sanity check
	OK;

	// OR R/M8, REG8

	test("08h  OR R/M8, REG8");
	CPU.CL = 160; // address
	CPU.AL = 0b0101;
	__iu8(0b1010, CPU.CL);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x08);
	assert(__fu8(CPU.CL) == 0xF);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// OR R/M16, REG16

	test("09h  OR R/M16, REG16");
	CPU.CX = 0x4000; // address
	CPU.AX = 0xFF;
	__iu16(0xFF00, CPU.CX);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x09);
	assert(__fu16(CPU.CX) == 0xFFFF);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// OR REG8, R/M8

	test("0Ah  OR REG8, R/M8");
	CPU.CL = 0x40; // address
	CPU.AL = 0xF;
	__iu8(0xF0, CPU.CL);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x0A);
	assert(CPU.AL == 0xFF);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// OR REG16, R/M16

	test("0Bh  OR REG16, R/M16");
	CPU.CX = 0x4000; // address
	CPU.AX = 0xFF;
	__iu16(0xFF00, CPU.CX);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x0B);
	assert(CPU.AX == 0xFFFF);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// OR AL, IMM8

	test("0Ch  OR AL, IMM8");
	__iu8(0xF0, CPU.EIP + 1);
	CPU.AL = 0xF;
	exec16(0x0C); // OR CPU.AL, 3
	assert(CPU.AL == 0xFF);
	OK;

	// OR AX, IMM16

	test("0Dh  OR AX, IMM16");
	__iu16(0xFF00, CPU.EIP + 1);
	exec16(0x0D); // OR CPU.AX, F0h
	assert(CPU.AX == 0xFFFF);
	OK;

	// PUSH CS

	test("0Eh  PUSH CS");
	CPU.CS = 318;
	exec16(0x0E);
	assert(__fu16(get_ad(CPU.SS, CPU.SP)) == 318);
	OK;

	// ADC R/M8, REG8

	test("10h  ADC R/M8, REG8"); TODO;

	// ADC R/M16, REG16

	test("11h  ADC R/M16, REG16"); TODO;

	// ADC REG8, R/M8

	test("12h  ADC REG8, R/M8"); TODO;

	// ADC REG16, R/M16

	test("13h  ADC REG16, R/M16"); TODO;

	// ADC AL, IMM8

	test("14h  ADC AL, IMM8"); TODO;

	// ADC AX, IMM16

	test("15h  ADC AX, IMM16"); TODO;

	// PUSH SS

	test("16h  PUSH SS");
	CPU.SS = 202;
	exec16(0x16);
	assert(__fu16(get_ad(CPU.SS, CPU.SP)) == 202);
	OK;

	// POP SS

	test("17h  POP SS");
	exec16(0x17);
	assert(CPU.SS == 202);
	OK;

	// SBB R/M8, REG8

	test("18h  SBB R/M8, REG8"); TODO;

	// SBB R/M16, REG16

	test("19h  SBB R/M16, REG16"); TODO;

	// SBB REG8, R/M16

	test("1Ah  SBB REG8, R/M16"); TODO;

	// SBB REG16, R/M16

	test("1Bh  SBB REG16, R/M16"); TODO;

	// SBB AL, IMM8

	test("1Ch  SBB AL, IMM8"); TODO;

	// SBB AX, IMM16

	test("1Dh  SBB AX, IMM16"); TODO;

	// PUSH DS

	test("1Eh  PUSH DS");
	CPU.DS = 444;
	exec16(0x1E);
	assert(__fu16(get_ad(CPU.SS, CPU.SP)) == 444);
	OK;

	// POP DS

	test("1Fh  POP DS");
	CPU.DS = 128;
	exec16(0x1F);
	assert(CPU.DS == 444);
	OK;

	// AND R/M8, REG8

	test("20h  AND R/M8, REG8");
	CPU.CL = 160; // address
	CPU.AL = 0xF;
	__iu8(0b11, CPU.CL);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x20);
	assert(__fu8(CPU.CL) == 0b11);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// AND R/M16, REG16

	test("21h  AND R/M16, REG16");
	CPU.CX = 0x4000; // address
	CPU.AX = 0xFF;
	__iu16(0xFFFF, CPU.CX);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x21);
	assert(__fu16(CPU.CX) == 0xFF);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// AND REG8, R/M8

	test("22h  AND REG8, R/M8");
	CPU.CL = 0x40; // address
	CPU.AL = 0xFF;
	__iu8(0xF, CPU.CL);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x22);
	assert(CPU.AL == 0xF);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// AND REG16, R/M16

	test("23h  AND REG16, R/M16");
	CPU.CX = 0x4000; // address
	CPU.AX = 0xFFFF;
	__iu16(0xFF, CPU.CX);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x23);
	assert(CPU.AX == 0xFF);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// AND AL, IMM8

	test("24h  AND AL, IMM8");
	CPU.AL = 0xFF;
	__iu8(0xF, CPU.EIP + 1);
	exec16(0x24);
	assert(CPU.AL == 0xF);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// AND AX, IMM16

	test("25h  AND AX, IMM16");
	CPU.AX = 0xFFFF;
	__iu16(0xFF, CPU.EIP + 1);
	exec16(0x25);
	assert(CPU.AX == 0xFF);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// ES:

	test("26h  ES:");
	exec16(0x26);
	assert(Seg == SEG_ES);
	OK;

	// DAA
	// Examples taken from the Intel's reference manual.

	test("27h  DAA");
	CPU.AF = 0;
	CPU.CF = 0;
	CPU.AL = 0xAE;
	exec16(0x27);
	assert(CPU.AL == 0x14);
	assert(CPU.AF);
	assert(CPU.PF);
	assert(CPU.CF);
	assert(CPU.SF == 0);
	assert(CPU.ZF == 0);
	CPU.AF = 0;
	CPU.CF = 0;
	CPU.AL = 0x2E;
	exec16(0x27);
	assert(CPU.AL == 0x34);
	assert(CPU.AF);
	//assert(CPU.PF == 0);
	//assert(CPU.CF);
	assert(CPU.SF == 0);
	assert(CPU.ZF == 0);
	OK;

	// SUB R/M8, REG8

	test("28h  SUB R/M8, REG8");
	CPU.CL = 160; // address
	CPU.AL = 40;
	__iu8(70, CPU.CL);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x28);
	assert(__fu8(CPU.CL) == 30);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// SUB R/M16, REG16

	test("29h  SUB R/M16, REG16");
	CPU.CX = 0x5000; // address
	CPU.AX = 1000;
	__iu16(24000, CPU.CX);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x29);
	assert(__fu16(CPU.CX) == 23000);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// SUB REG8, R/M8

	test("2Ah  SUB REG8, R/M8");
	CPU.CL = 0x40; // address
	CPU.AL = 200;
	__iu8(50, CPU.CL);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x2A);
	assert(CPU.AL == 150);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// SUB REG16, R/M16

	test("2Bh  SUB REG16, R/M16");
	CPU.CX = 0x4000; // address
	CPU.AX = 65000;
	__iu16(64000, CPU.CX);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x2B);
	assert(CPU.AX == 1000);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	// SUB AL, IMM8

	test("2Ch  SUB AL, IMM8");
	__iu8(21, CPU.EIP + 1);
	CPU.AL = 21;
	exec16(0x2C);
	assert(CPU.AL == 0);
	assert(CPU.ZF);
	OK;

	// SUB AX, IMM16

	test("2Dh  SUB AX, IMM16");
	CPU.AX = 2500;
	__iu16(2500, CPU.EIP + 1);
	exec16(0x2D);
	assert(CPU.AX == 0);
	assert(CPU.ZF);
	OK;

	// CS:

	test("2Eh  CS:");
	exec16(0x2E);
	assert(Seg == SEG_CS);
	OK;

	// DAS

	test("2Fh  DAS"); TODO;

	// XOR

	test("30h  XOR R/M8, REG8");
	CPU.CL = 200; // address
	CPU.AL = 25;
	__iu8(50, CPU.CL);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x30);
	assert(__fu8(CPU.CL) == 43);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	test("31h  XOR R/M16, REG16");
	CPU.CX = 0x5000; // address
	CPU.AX = 2500;
	__iu16(5000, CPU.CX);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x31);
	assert(__fu16(CPU.CX) == 6732);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	test("32h  XOR REG8, R/M8");
	CPU.CL = 0x40; // address
	CPU.AL = 100;
	__iu8(50, CPU.CL);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x32);
	assert(CPU.AL == 86);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	test("33h  XOR REG16, R/M16");
	CPU.CX = 0x4000; // address
	CPU.AX = 8086;
	__iu16(3770, CPU.CX);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x33);
	assert(CPU.AX == 4396);
	assert(CPU.OF == 0);
	assert(CPU.ZF == 0);
	OK;

	test("34h  XOR AL, IMM8");
	__iu8(5, CPU.EIP + 1);
	CPU.AL = 0xF;
	exec16(0x34); // XOR CPU.AL, 5
	assert(CPU.AL == 0xA);
	OK;

	test("35h  XOR AX, IMM16");
	__iu16(0xFF00, CPU.EIP + 1);
	CPU.AX = 0xAAFF;
	exec16(0x35); // XOR CPU.AX, FF00h
	assert(CPU.AX == 0x55FF);
	OK;

	// INC

	fullreset; CPU.CS = 0;
	test("40h  INC AX");
	exec16(0x40); assert(CPU.AX == 1);
	OK;
	test("41h  INC CX");
	exec16(0x41); assert(CPU.CX == 1);
	OK;
	test("42h  INC DX");
	exec16(0x42); assert(CPU.DX == 1);
	OK;
	test("43h  INC BX");
	exec16(0x43); assert(CPU.BX == 1);
	OK;
	test("44h  INC SP");
	exec16(0x44); assert(CPU.SP == 1);
	OK;
	test("45h  INC BP");
	exec16(0x45); assert(CPU.BP == 1);
	OK;
	test("46h  INC SI");
	exec16(0x46); assert(CPU.SI == 1);
	OK;
	test("47h  INC SI");
	exec16(0x47); assert(CPU.DI == 1);
	OK;
	
	// DEC

	test("48h  DEC AX");
	exec16(0x48);
	assert(CPU.AX == 0);
	OK;
	test("49h  DEC CX");
	exec16(0x49);
	assert(CPU.CX == 0);
	OK;
	test("4Ah  DEC DX");
	exec16(0x4A);
	assert(CPU.DX == 0);
	OK;
	test("4Bh  DEC BX");
	exec16(0x4B);
	assert(CPU.BX == 0);
	OK;
	test("4Ch  DEC SP");
	exec16(0x4C);
	assert(CPU.SP == 0);
	OK;
	test("4Dh  DEC BP");
	exec16(0x4D);
	assert(CPU.BP == 0);
	OK;
	test("4Eh  DEC SI");
	exec16(0x4E);
	assert(CPU.SI == 0);
	OK;
	test("4Fh  DEC DI");
	exec16(0x4F);
	assert(CPU.DI == 0);
	OK;

	// PUSH

	CPU.SS = 0x100; CPU.SP = 0x60;

	test("50h  PUSH AX");
	CPU.AX = 0xDAD;
	exec16(0x50);
	assert(CPU.AX == __fu16(get_ad(CPU.SS, CPU.SP)));
	OK;

	test("51h  PUSH CX");
	CPU.CX = 0x4488;
	exec16(0x51);
	assert(CPU.CX == __fu16(get_ad(CPU.SS, CPU.SP)));
	OK;

	test("52h  PUSH DX");
	CPU.DX = 0x4321;
	exec16(0x52);
	assert(CPU.DX == __fu16(get_ad(CPU.SS, CPU.SP)));
	OK;

	test("53h  PUSH BX");
	CPU.BX = 0x1234;
	exec16(0x53);
	assert(CPU.BX == __fu16(get_ad(CPU.SS, CPU.SP)));
	OK;

	test("54h  PUSH SP");
	exec16(0x54);
	assert(CPU.SP == __fu16(get_ad(CPU.SS, CPU.SP)) - 2);
	OK;

	test("55h  PUSH BP");
	CPU.BP = 0xFBAC;
	exec16(0x55);
	assert(CPU.BP == __fu16(get_ad(CPU.SS, CPU.SP)));
	OK;

	test("56h  PUSH SI");
	CPU.SI = 0xF00F;
	exec16(0x56);
	assert(CPU.SI == __fu16(get_ad(CPU.SS, CPU.SP)));
	OK;

	test("57h  PUSH DI");
	CPU.DI = 0xB0B;
	exec16(0x57);
	assert(CPU.DI == __fu16(get_ad(CPU.SS, CPU.SP)));
	OK;

	// POP

	CPU.SS = 0x100; CPU.SP = 0x20;

	test("58h  POP AX");
	push16(0xFFAA);
	exec16(0x58);
	assert(CPU.AX == 0xFFAA);
	OK;
	
	CPU.SP -= 2;
	test("59h  POP CX");
	exec16(0x59);
	assert(CPU.CX == 0xFFAA);
	OK;

	CPU.SP -= 2;
	test("5Ah  POP DX");
	exec16(0x5A);
	assert(CPU.DX == 0xFFAA);
	OK;

	CPU.SP -= 2;
	test("5Bh  POP BX");
	exec16(0x5B);
	assert(CPU.BX == 0xFFAA);
	OK;

	CPU.SP -= 2;
	test("5Ch  POP SP");
	exec16(0x5C);
	assert(CPU.SP == 0xFFAA);
	OK;

	CPU.SP = 0x1E;
	test("5Dh  POP BX");
	exec16(0x5D);
	assert(CPU.BP == 0xFFAA);
	OK;

	CPU.SP -= 2;
	test("5Eh  POP SI");
	exec16(0x5E);
	assert(CPU.SI == 0xFFAA);
	OK;

	CPU.SP -= 2;
	test("5Fh  POP DI");
	exec16(0x5F);
	assert(CPU.DI == 0xFFAA);
	OK;

	// Conditional Jumps

	test("70h  JO");
	CPU.IP = 0x100;
	CPU.OF = 0;
	exec16(0x70);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.OF = 1;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x70);
	assert(CPU.IP == 0xEE);
	OK;

	test("71h  JNO");
	CPU.IP = 0x100;
	CPU.OF = 0;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x71);
	assert(CPU.IP == 0xEE);
	CPU.IP = 0x100;
	CPU.OF = 1;
	exec16(0x71);
	assert(CPU.IP == 0x102);
	OK;

	test("72h  JB/JNAE/JC");
	CPU.IP = 0x100;
	CPU.CF = 0;
	exec16(0x72);
	assert(CPU.IP == 0x102);
	__iu8(-20, CPU.EIP + 1);
	CPU.IP = 0x100;
	CPU.CF = 1;
	exec16(0x72);
	assert(CPU.IP == 0xEE);
	OK;

	test("73h  JNB/JAE/JNC");
	CPU.IP = 0x100;
	CPU.CF = 1;
	exec16(0x73);
	assert(CPU.IP == 0x102);
	__iu8(-20, CPU.EIP + 1);
	CPU.IP = 0x100;
	CPU.CF = 0;
	exec16(0x73);
	assert(CPU.IP == 0xEE);
	OK;

	test("74h  JE/JZ");
	CPU.IP = 0x100;
	CPU.ZF = 0;
	exec16(0x74);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.ZF = 1;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x74);
	assert(CPU.IP == 0xEE);
	OK;

	test("75h  JNE/JNZ");
	CPU.IP = 0x100;
	CPU.ZF = 1;
	exec16(0x75);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.ZF = 0;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x75);
	assert(CPU.IP == 0xEE);
	OK;

	test("76h  JBE/JNA");
	CPU.IP = 0x100;
	CPU.CF = 0;
	CPU.ZF = 0;
	exec16(0x76);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.ZF = 0;
	CPU.CF = 1;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x76);
	assert(CPU.IP == 0xEE);
	OK;

	test("77h  JNBE/JA");
	CPU.IP = 0x100;
	CPU.CF = 0;
	CPU.ZF = 1;
	exec16(0x77);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.ZF = 0;
	CPU.CF = 0;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x77);
	assert(CPU.IP == 0xEE);
	OK;

	test("78h  JS");
	CPU.IP = 0x100;
	CPU.SF = 0;
	exec16(0x78);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.SF = 1;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x78);
	assert(CPU.IP == 0xEE);
	OK;

	test("79h  JNS");
	CPU.IP = 0x100;
	CPU.SF = 1;
	exec16(0x79);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.SF = 0;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x79);
	assert(CPU.IP == 0xEE);
	OK;

	test("7Ah  JP/JPE");
	CPU.IP = 0x100;
	CPU.PF = 0;
	exec16(0x7A);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.PF = 1;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x7A);
	assert(CPU.IP == 0xEE);
	OK;

	test("7Bh  JNP/JPO");
	CPU.IP = 0x100;
	CPU.PF = 1;
	exec16(0x7B);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.PF = 0;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x7B);
	assert(CPU.IP == 0xEE);
	OK;

	test("7Ch  JL/JNGE");
	CPU.IP = 0x100;
	CPU.SF = 1;
	CPU.OF = 1;
	exec16(0x7C);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.SF = 0;
	CPU.OF = 1;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x7C);
	assert(CPU.IP == 0xEE);
	OK;

	test("7Dh  JNL/JGE");
	CPU.IP = 0x100;
	CPU.SF = 0;
	CPU.OF = 1;
	exec16(0x7D);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.SF = 1;
	CPU.OF = 1;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x7D);
	assert(CPU.IP == 0xEE);
	OK;

	test("7Eh  JLE/JNG");
	CPU.IP = 0x100;
	CPU.SF = 1;
	CPU.OF = 1;
	CPU.ZF = 0;
	exec16(0x7E);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.SF = 0;
	CPU.OF = 0;
	CPU.ZF = 1;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x7E);
	assert(CPU.IP == 0xEE);
	OK;

	test("7Fh  JNLE/JG");
	CPU.IP = 0x100;
	CPU.SF = 0;
	CPU.OF = 1;
	CPU.ZF = 0;
	exec16(0x7F);
	assert(CPU.IP == 0x102);
	CPU.IP = 0x100;
	CPU.SF = 0;
	CPU.OF = 0;
	CPU.ZF = 0;
	__iu8(-20, CPU.EIP + 1);
	exec16(0x7F);
	assert(CPU.IP == 0xEE);
	OK;

	// Group 1

	test("80h  GRP1 ADD");
	CPU.AL = 0x40;
	__iu8(10, CPU.AL);
	__iu8(0b11_000_000, CPU.EIP+1);
	__iu8(20, CPU.EIP+2);
	exec16(0x80);
	assert(__fu8(CPU.AL) == 30);
	OK;
	test("80h  GRP1 OR");
	CPU.AL = 0x40;
	__iu8(0b1100_0011, CPU.AL);
	__iu8(0b11_001_000, CPU.EIP+1);
	__iu8(0b0011_0000, CPU.EIP+2);
	exec16(0x80);
	assert(__fu8(CPU.AL) == 0b1111_0011);
	OK;
	test("80h  GRP1 ADC"); TODO;
	test("80h  GRP1 SBB"); TODO;
	test("80h  GRP1 AND");
	CPU.AL = 0x40;
	__iu8(0b0011_0011, CPU.AL);
	__iu8(0b11_100_000, CPU.EIP+1);
	__iu8(0b0011_0000, CPU.EIP+2);
	exec16(0x80);
	assert(__fu8(CPU.AL) == 0b0011_0000);
	OK;
	test("80h  GRP1 SUB/CMP");
	CPU.AL = 0x40;
	__iu8(45, CPU.AL);
	__iu8(0b11_101_000, CPU.EIP+1);
	__iu8(20, CPU.EIP+2);
	exec16(0x80);
	assert(__fu8(CPU.AL) == 25);
	OK;
	test("80h  GRP1 XOR");
	CPU.AL = 0x40;
	__iu8(40, CPU.AL);
	__iu8(0b11_110_000, CPU.EIP+1);
	__iu8(20, CPU.EIP+2);
	exec16(0x80);
	assert(__fu8(CPU.AL) == 60);
	OK;

	test("81h  GRP1 ADD");
	CPU.AX = 0x400;
	__iu16(40, CPU.AX);
	__iu8(0b11_000_000, CPU.EIP+1);
	__iu16(222, CPU.EIP+2);
	exec16(0x81);
	assert(__fu16(CPU.AX) == 262);
	OK;
	test("81h  GRP1 OR");
	CPU.AX = 0x400;
	__iu16(40, CPU.AX);
	__iu8(0b11_001_000, CPU.EIP+1);
	__iu16(222, CPU.EIP+2);
	exec16(0x81);
	assert(__fu16(CPU.AX) == 254);
	OK;
	test("81h  GRP1 ADC"); TODO;
	test("81h  GRP1 SBB"); TODO;
	test("81h  GRP1 AND");
	CPU.AX = 0x400;
	__iu16(40, CPU.AX);
	__iu8(0b11_100_000, CPU.EIP+1);
	__iu16(222, CPU.EIP+2);
	exec16(0x81);
	assert(__fu16(CPU.AX) == 8);
	OK;
	test("81h  GRP1 SUB/CMP");
	CPU.AX = 0x400;
	__iu16(222, CPU.AX);
	__iu8(0b11_101_000, CPU.EIP+1);
	__iu16(40, CPU.EIP+2);
	exec16(0x81);
	assert(__fu16(CPU.AX) == 182);
	OK;
	test("81h  GRP1 XOR");
	CPU.AX = 0x400;
	__iu16(222, CPU.AX);
	__iu8(0b11_110_000, CPU.EIP+1);
	__iu16(40, CPU.EIP+2);
	exec16(0x81);
	assert(__fu16(CPU.AX) == 246);
	OK;

	// Group 2

	test("82h  GRP2 ADD");
	CPU.AL = 0x40;
	__iu8(40, CPU.AL);
	__iu8(0b11_000_000, CPU.EIP+1);
	__iu8(20, CPU.EIP+2);
	exec16(0x82);
	assert(__fu8(CPU.AL) == 60);
	OK;
	test("82h  GRP2 ADC"); TODO;
	test("82h  GRP2 SBB"); TODO;
	test("82h  GRP2 SUB/CMP");
	CPU.AL = 0x40;
	__iu8(40, CPU.AL);
	__iu8(0b11_101_000, CPU.EIP+1);
	__iu8(20, CPU.EIP+2);
	exec16(0x82);
	assert(__fu8(CPU.AL) == 20);
	OK;

	test("83h  GRP2 ADD");
	CPU.AX = 0x400;
	__iu16(40, CPU.AX);
	__iu8(0b11_000_000, CPU.EIP+1);
	__iu16(20, CPU.EIP+2);
	exec16(0x83);
	assert(__fu16(CPU.AX) == 60);
	OK;
	test("83h  GRP2 ADC"); TODO;
	test("83h  GRP2 SBB"); TODO;
	test("83h  GRP2 SUB/CMP");
	CPU.AX = 0x400;
	__iu16(40, CPU.AX);
	__iu8(0b11_101_000, CPU.EIP + 1);
	__iu16(25, CPU.EIP + 2);
	exec16(0x83);
	assert(__fu16(CPU.AX) == 15);
	OK;

	// TEST

	test("84h  TEST R/M8, REG8");
	CPU.CL = 240;
	__iu8(0xF, CPU.CL);
	CPU.AL = 0xFF;
	assert(CPU.ZF == 0);
	assert(CPU.SF == 0);
	assert(CPU.PF);
	OK;

	test("85h  TEST R/M16, REG16");
	CPU.CX = 24000;
	__iu16(0xFF, CPU.CL);
	CPU.AX = 0xFFFF;
	assert(CPU.ZF == 0);
	assert(CPU.SF == 0);
	assert(CPU.PF);
	OK;

	// XCHG

	test("86h  XCHG REG8, R/M8");
	CPU.CL = 230;
	CPU.AL = 25;
	__iu8(50, CPU.CL);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x86);
	assert(__fu8(CPU.CL) == 25);
	assert(CPU.AL == 50);
	OK;

	test("87h  XCHG REG16, R/M16");
	CPU.CX = 2300;
	CPU.AX = 1337;
	__iu16(666, CPU.CX);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x87);
	assert(__fu16(CPU.CX) == 1337);
	assert(CPU.AX == 666);
	OK;

	// MOV REG8, R/M8

	test("88h  MOV R/M8, REG8");
	CPU.AL = 34;
	__iu8(0b11_000_000, CPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(CPU.AL) == 34);
	CPU.CL = 77;
	__iu8(0b11_001_000, CPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(CPU.AL) == 77);
	CPU.DL = 123;
	__iu8(0b11_010_000, CPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(CPU.AL) == 123);
	CPU.BL = 231;
	__iu8(0b11_011_000, CPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(CPU.AL) == 231);
	CPU.AH = 88;
	__iu8(0b11_100_000, CPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(CPU.AL) == 88);
	CPU.CH = 32;
	__iu8(0b11_101_000, CPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(CPU.AL) == 32);
	CPU.DH = 32;
	__iu8(0b11_110_000, CPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(CPU.AL) == 32);
	CPU.BH = 42;
	__iu8(0b11_111_000, CPU.EIP + 1);
	exec16(0x88);
	assert(__fu8(CPU.AL) == 42);
	OK;

	// MOV R/M16, REG16

	test("89h  MOV R/M16, REG16");
	CPU.AX = 344;
	__iu8(0b11_000_000, CPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(CPU.AX) == 344);
	CPU.CX = 777;
	__iu8(0b11_001_000, CPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(CPU.AX) == 777);
	CPU.DX = 1234;
	__iu8(0b11_010_000, CPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(CPU.AX) == 1234);
	CPU.BX = 2311;
	__iu8(0b11_011_000, CPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(CPU.AX) == 2311);
	CPU.SP = 8888;
	__iu8(0b11_100_000, CPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(CPU.AX) == 8888);
	CPU.BP = 3200;
	__iu8(0b11_101_000, CPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(CPU.AX) == 3200);
	CPU.SI = 3244;
	__iu8(0b11_110_000, CPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(CPU.AX) == 3244);
	CPU.DI = 4212;
	__iu8(0b11_111_000, CPU.EIP + 1);
	exec16(0x89);
	assert(__fu16(CPU.AX) == 4212);
	OK;

	// MOV R/M16, REG16

	test("8Ah  MOV REG8, R/M8");
	CPU.AL = 56;
	__iu8(CPU.AL, CPU.AL);
	__iu8(0b11_000_000, CPU.EIP + 1);
	exec16(0x8A);
	assert(CPU.AL == 56);
	CPU.CL = 152;
	__iu8(CPU.CL, CPU.AL);
	__iu8(0b11_001_000, CPU.EIP + 1);
	exec16(0x8A);
	assert(CPU.CL == 152);
	CPU.DL = 159;
	__iu8(CPU.DL, CPU.AL);
	__iu8(0b11_010_000, CPU.EIP + 1);
	exec16(0x8A);
	assert(CPU.DL == 159);
	CPU.BL = 129;
	__iu8(CPU.BL, CPU.AL);
	__iu8(0b11_011_000, CPU.EIP + 1);
	exec16(0x8A);
	assert(CPU.BL == 129);
	CPU.AH = 176;
	__iu8(CPU.AH, CPU.AL);
	__iu8(0b11_100_000, CPU.EIP + 1);
	exec16(0x8A);
	assert(CPU.AH == 176);
	CPU.CH = 166;
	__iu8(CPU.CH, CPU.AL);
	__iu8(0b11_101_000, CPU.EIP + 1);
	exec16(0x8A);
	assert(CPU.CH == 166);
	CPU.DH = 198;
	__iu8(CPU.DH, CPU.AL);
	__iu8(0b11_110_000, CPU.EIP + 1);
	exec16(0x8A);
	assert(CPU.DH == 198);
	CPU.BH = 111;
	__iu8(CPU.BH, CPU.AL);
	__iu8(0b11_111_000, CPU.EIP + 1);
	exec16(0x8A);
	assert(CPU.BH == 111);
	OK;

	// MOV REG16, R/M16

	test("8Bh  MOV REG16, R/M16");
	CPU.AX = 5600;
	__iu16(CPU.AX, CPU.AX);
	__iu8(0b11_000_000, CPU.EIP + 1);
	exec16(0x8B);
	assert(CPU.AX == 5600);
	CPU.CX = 1520;
	__iu16(CPU.CX, CPU.AX);
	__iu8(0b11_001_000, CPU.EIP + 1);
	exec16(0x8B);
	assert(CPU.CX == 1520);
	CPU.DX = 1590;
	__iu16(CPU.DX, CPU.AX);
	__iu8(0b11_010_000, CPU.EIP + 1);
	exec16(0x8B);
	assert(CPU.DX == 1590);
	CPU.BX = 1290;
	__iu16(CPU.BX, CPU.AX);
	__iu8(0b11_011_000, CPU.EIP + 1);
	exec16(0x8B);
	assert(CPU.BX == 1290);
	CPU.SP = 1760;
	__iu16(CPU.SP, CPU.AX);
	__iu8(0b11_100_000, CPU.EIP + 1);
	exec16(0x8B);
	assert(CPU.SP == 1760);
	CPU.BP = 1660;
	__iu16(CPU.BP, CPU.AX);
	__iu8(0b11_101_000, CPU.EIP + 1);
	exec16(0x8B);
	assert(CPU.BP == 1660);
	CPU.SI = 1984;
	__iu16(CPU.SI, CPU.AX);
	__iu8(0b11_110_000, CPU.EIP + 1);
	exec16(0x8B);
	assert(CPU.SI == 1984);
	CPU.DI = 1110;
	__iu16(CPU.DI, CPU.AX);
	__iu8(0b11_111_000, CPU.EIP + 1);
	exec16(0x8B);
	assert(CPU.DI == 1110);
	OK;

	// MOV R/M16, SEGREG

	test("8Ch  MOV R/M16, SEGREG");
	CPU.CS = 123; CPU.DS = 124; CPU.ES = 125; CPU.SS = 126;
	CPU.AX = 0x4440; // address
	__iu8(0b11_101_000, CPU.EIP + 1);
	exec16(0x8C);
	assert(__fu16(CPU.AX) == CPU.CS);
	__iu8(0b11_111_000, CPU.EIP + 1);
	exec16(0x8C);
	assert(__fu16(CPU.AX) == CPU.DS);
	__iu8(0b11_100_000, CPU.EIP + 1);
	exec16(0x8C);
	assert(__fu16(CPU.AX) == CPU.ES);
	__iu8(0b11_110_000, CPU.EIP + 1);
	exec16(0x8C);
	assert(__fu16(CPU.AX) == CPU.SS);
	OK;

	// LEA REG16, MEM16

	test("8Dh  LEA REG16, MEM16");
	CPU.SI = 0xAAAA;
	__iu8(0b11_000_110, CPU.EIP + 1);
	exec16(0x8D);
	assert(CPU.AX == CPU.SI);
	OK;

	// MOV SEGREG, R/M16

	test("8Eh  MOV SEGREG, R/M16");
	__iu8(0b11_101_000, CPU.EIP + 1);
	__iu16(8922, CPU.AX);
	exec16(0x8E);
	assert(CPU.CS == 8922);
	__iu8(0b11_111_000, CPU.EIP + 1);
	__iu16(4932, CPU.AX);
	exec16(0x8E);
	assert(CPU.DS == 4932);
	__iu8(0b11_100_000, CPU.EIP + 1);
	__iu16(7632, CPU.AX);
	exec16(0x8E);
	assert(CPU.ES == 7632);
	__iu8(0b11_110_000, CPU.EIP + 1);
	__iu16(9999, CPU.AX);
	exec16(0x8E);
	assert(CPU.SS == 9999);
	OK;

	// POP R/M16

	test("8Fh  POP R/M16");
	CPU.CX = 0x4000;
	push16(1234);
	__iu8(0b11_000_001, CPU.EIP + 1);
	exec16(0x8F);
	assert(__fu16(CPU.CX) == 1234);
	OK;

	// XCHG

	test("90h  NOP");
	{ // Nevertheless, let's test the Program Counter
		CPU.AX = cast(ushort)(CPU.IP + 1); // expected IP
		exec16(0x90);
		assert(CPU.AX == CPU.IP);
	}
	OK;

	test("91h  XCHG AX, CX");
	CPU.AX = 0xFAB;
	CPU.CX = 0xAABB;
	exec16(0x91);
	assert(CPU.AX == 0xAABB);
	assert(CPU.CX == 0xFAB);
	OK;

	test("92h  XCHG AX, DX");
	CPU.AX = 0xFAB;
	CPU.DX = 0xAABB;
	exec16(0x92);
	assert(CPU.AX == 0xAABB);
	assert(CPU.DX == 0xFAB);
	OK;

	test("93h  XCHG AX, BX");
	CPU.AX = 0xFAB;
	CPU.BX = 0xAABB;
	exec16(0x93);
	assert(CPU.AX == 0xAABB);
	assert(CPU.BX == 0xFAB);
	OK;

	test("94h  XCHG AX, SP");
	CPU.AX = 0xFAB;
	CPU.SP = 0xAABB;
	exec16(0x94);
	assert(CPU.AX == 0xAABB);
	assert(CPU.SP == 0xFAB);
	OK;

	test("95h  XCHG AX, BP");
	CPU.AX = 0xFAB;
	CPU.BP = 0xAABB;
	exec16(0x95);
	assert(CPU.AX == 0xAABB);
	assert(CPU.BP == 0xFAB);
	OK;

	test("96h  XCHG AX, SI");
	CPU.AX = 0xFAB;
	CPU.SI = 0xAABB;
	exec16(0x96);
	assert(CPU.AX == 0xAABB);
	assert(CPU.SI == 0xFAB);
	OK;

	test("97h  XCHG AX, DI");
	CPU.AX = 0xFAB;
	CPU.DI = 0xAABB;
	exec16(0x97);
	assert(CPU.AX == 0xAABB);
	assert(CPU.DI == 0xFAB);
	OK;

	// CBW

	test("98h  CBW");
	CPU.AL = 0;
	exec16(0x98);
	assert(CPU.AH == 0);
	CPU.AL = 0xFF;
	exec16(0x98);
	assert(CPU.AH == 0xFF);
	OK;

	// CWD

	test("99h  CWD");
	CPU.AX = 0;
	exec16(0x99);
	assert(CPU.DX == 0);
	CPU.AX = 0xFFFF;
	exec16(0x99);
	assert(CPU.DX == 0xFFFF);
	OK;

	// WAIT

	test("9Bh  WAIT"); TODO;

	// PUSHF

	test("9Ch  PUSHF");
	exec16(0x9C);
	assert(__fu16(get_ad(CPU.SS, CPU.SP)) == FLAG);
	OK;

	// POPF

	test("9Dh  POPF");
	exec16(0x9D);
	assert(pop16 == FLAG);
	OK;

	// SAHF

	test("9Eh  SAHF"); TODO;

	// LAHF

	test("9Fh  LAHF"); TODO;

	// MOV AL, MEM8

	test("A0h  MOV AL, MEM8");
	__iu8(167, 0x8000);
	__iu16(0x8000, CPU.EIP + 1);
	exec16(0xA0);
	assert(CPU.AL == 167);
	OK;

	// MOV AX, MEM16

	test("A1h  MOV AX, MEM16");
	__iu16(1670, 0x8000);
	__iu16(0x8000, CPU.EIP + 1);
	exec16(0xA1);
	assert(CPU.AX == 1670);
	OK;

	// MOV MEM8, AL

	test("A2h  MOV MEM8, AL");
	CPU.AL = 143;
	__iu16(0x4000, CPU.EIP + 1);
	exec16(0xA2);
	assert(__fu8(0x4000) == 143);
	OK;

	// MOV MEM16, AX

	test("A3h  MOV MEM16, AX");
	CPU.AX = 1430;
	__iu16(0x4000, CPU.EIP + 1);
	exec16(0xA3);
	assert(__fu16(0x4000) == 1430);
	OK;

	// CMPS

	CPU.DF = 0;

	test("A6h  CMPS");
	CPU.CS = CPU.ES = 0xF00; CPU.DI = CPU.EIP = 0x100;
	__istr("HELL", get_ip);
	CPU.CS = CPU.DS = 0xF00; CPU.SI = CPU.EIP = 0x110;
	__istr("HeLL", get_ip);
	exec16(0xA6);
	assert(CPU.ZF);
	exec16(0xA6);
	assert(!CPU.ZF);
	exec16(0xA6);
	assert(CPU.ZF);
	exec16(0xA6);
	assert(CPU.ZF);
	OK;

	test("A7h  CMPSW");
	CPU.CS = CPU.ES = 0xF00; CPU.DI = CPU.EIP = 0x100;
	__iwstr("HELL"w, get_ip);
	CPU.CS = CPU.DS = 0xF00; CPU.SI = CPU.EIP = 0x110;
	__iwstr("HeLL"w, get_ip);
	exec16(0xA7);
	assert(CPU.ZF);
	exec16(0xA7);
	assert(!CPU.ZF);
	exec16(0xA7);
	assert(CPU.ZF);
	exec16(0xA7);
	assert(CPU.ZF);
	OK;

	// TEST AL, IMM8

	test("A8h  TEST AL, IMM8");
	CPU.AL = 0b1100;
	__iu8(0b1100, CPU.EIP + 1);
	exec16(0xA8);
	assert(CPU.PF);
	assert(CPU.ZF == 0);
	assert(CPU.SF == 0);
	assert(CPU.CF == 0);
	assert(CPU.OF == 0);
	CPU.AL = 0xF0;
	__iu8(0x0F, CPU.EIP + 1);
	exec16(0xA8);
	assert(CPU.PF);
	assert(CPU.ZF);
	assert(CPU.SF == 0);
	assert(CPU.CF == 0);
	assert(CPU.OF == 0);
	OK;

	// TEST AX, IMM16

	test("A9h  TEST AX, IMM16");
	CPU.AX = 0xAA00;
	__iu16(0xAA00, CPU.EIP + 1);
	exec16(0xA9);
	assert(CPU.PF);
	assert(CPU.ZF == 0);
	assert(CPU.SF);
	assert(CPU.CF == 0);
	assert(CPU.OF == 0);
	OK;

	// STOS

	test("AAh  STOS");
	CPU.ES = 0x20; CPU.DI = 0x20;        
	CPU.AL = 'Q';
	exec16(0xAA);
	assert(MEMORY[get_ad(CPU.ES, CPU.DI - 1)] == 'Q');
	OK;

	test("ABh  STOSW");
	CPU.ES = 0x200; CPU.DI = 0x200;        
	CPU.AX = 0xACDC;
	exec16(0xAB);
	assert(__fu16(get_ad(CPU.ES, CPU.DI - 2)) == 0xACDC);
	OK;

	// LODS

	test("ACh  LODS"); // of dosh
	CPU.AL = 0;
	CPU.DS = 0xA0; CPU.SI = 0x200;
	MEMORY[get_ad(CPU.DS, CPU.SI)] = 'H';
	exec16(0xAC);
	assert(CPU.AL == 'H');
	MEMORY[get_ad(CPU.DS, CPU.SI)] = 'e';
	exec16(0xAC);
	assert(CPU.AL == 'e');
	OK;

	test("ADh  LODSW");
	CPU.AX = 0;
	CPU.DS = 0x40; CPU.SI = 0x80;
	__iu16(0x48AA, get_ad(CPU.DS, CPU.SI));
	exec16(0xAD);
	assert(CPU.AX == 0x48AA);
	__iu16(0x65BB, get_ad(CPU.DS, CPU.SI));
	exec16(0xAD);
	assert(CPU.AX == 0x65BB);
	OK;

	// SCAS

	test("AEh  SCAS");
	CPU.ES = CPU.CS = 0x400; CPU.DI = 0x20; CPU.IP = 0x20;
	CPU.EIP = get_ip;
	__istr("Hello!");
	CPU.AL = 'H';
	exec16(0xAE);
	assert(CPU.ZF);
	CPU.AL = '1';
	exec16(0xAE);
	assert(!CPU.ZF);
	OK;

	test("AFh  SCASW");
	CPU.CS = 0x800; CPU.ES = 0x800; CPU.EIP = 0x30; CPU.DI = 0x30;
	__iu16(0xFE22, get_ad(CPU.ES, CPU.DI));
	CPU.AX = 0xFE22;
	exec16(0xAF);
	assert(CPU.ZF);
	exec16(0xAF);
	assert(!CPU.ZF);
	OK;

	// MOV REG8, IMM8

	test("B0h  MOV AL, IMM8");
	__iu8(0x1, CPU.EIP + 1);
	exec16(0xB0); // MOV AL, 1
	assert(CPU.AL == 1);
	OK;

	test("B1h  MOV CL, IMM8");
	__iu8(0x2, CPU.EIP + 1);
	exec16(0xB1); // MOV CL, 2
	assert(CPU.CL == 2);
	OK;

	test("B2h  MOV DL, IMM8");
	__iu8(0x3, CPU.EIP + 1);
	exec16(0xB2); // MOV DL, 3
	assert(CPU.DL == 3);
	OK;

	test("B3h  MOV BL, IMM8");
	__iu8(0x4, CPU.EIP + 1);
	exec16(0xB3); // MOV BL, 4
	assert(CPU.BL == 4);
	OK;

	test("B4h  MOV AH, IMM8");
	__iu8(0x5, CPU.EIP + 1);
	exec16(0xB4); // MOV AH, 5
	assert(CPU.AH == 5);
	OK;

	test("B5h  MOV CH, IMM8");
	__iu8(0x6, CPU.EIP + 1);
	exec16(0xB5); // MOV CH, 6
	assert(CPU.CH == 6);
	OK;

	test("B6h  MOV DH, IMM8");
	__iu8(0x7, CPU.EIP + 1);
	exec16(0xB6); // MOV DH, 7
	assert(CPU.DH == 7);
	OK;

	test("B7h  MOV BH, IMM8");
	__iu8(0x8, CPU.EIP + 1);
	exec16(0xB7); // MOV BH, 8
	assert(CPU.BH == 8);
	OK;

	// MOV REG16, IMM16

	test("B8h  MOV AX, IMM16");
	__iu16(0x1112, CPU.EIP + 1);
	exec16(0xB8); // MOV AX, 1112h
	assert(CPU.AX == 0x1112);
	OK;

	test("B9h  MOV CX, IMM16");
	__iu16(0x1113, CPU.EIP + 1);
	exec16(0xB9); // MOV CX, 1113h
	assert(CPU.CX == 0x1113);
	OK;

	test("BAh  MOV DX, IMM16");
	__iu16(0x1114, CPU.EIP + 1);
	exec16(0xBA); // MOV DX, 1114h
	assert(CPU.DX == 0x1114);
	OK;

	test("BBh  MOV BX, IMM16");
	__iu16(0x1115, CPU.EIP + 1);
	exec16(0xBB); // MOV BX, 1115h
	assert(CPU.BX == 0x1115);
	OK;

	test("BCh  MOV SP, IMM16");
	__iu16(0x1116, CPU.EIP + 1);
	exec16(0xBC); // MOV SP, 1116h
	assert(CPU.SP == 0x1116);
	OK;

	test("BDh  MOV BP, IMM16");
	__iu16(0x1117, CPU.EIP + 1);
	exec16(0xBD); // MOV BP, 1117h
	assert(CPU.BP == 0x1117);
	OK;

	test("BEh  MOV SI, IMM16");
	__iu16(0x1118, CPU.EIP + 1);
	exec16(0xBE); // MOV SI, 1118h
	assert(CPU.SI == 0x1118);
	OK;

	test("BFh  MOV DI, IMM16");
	__iu16(0x1119, CPU.EIP + 1);
	exec16(0xBF); // MOV DI, 1119h
	assert(CPU.DI == 0x1119);
	OK;

	// RET

	test("C2h  RET IMM16 (NEAR)"); TODO;

	test("C3h  RET (NEAR)"); TODO;

	// LES

	test("C4h  LES REG16, MEM16"); TODO;

	// LDS

	test("C5h  LDS REG16, MEM16"); TODO;

	// MOV

	test("C6h  MOV MEM8, IMM8"); TODO;

	test("C7h  MOV MEM16, IMM16"); TODO;

	// RET

	test("CAh  RET IMM16 (FAR)"); TODO;

	test("CBh  RET (FAR)"); TODO;

	// INT

	test("CCh  INT 3"); TODO;

	test("CDh  INT IMM8"); TODO;

	test("CEh  INTO"); TODO;

	// IRET

	test("CFh  IRET"); TODO;

	// Group 2, R/M8, 1

	test("D0h  GRP2 ROL R/M8, 1"); TODO;
	test("D0h  GRP2 ROR R/M8, 1"); TODO;
	test("D0h  GRP2 RCL R/M8, 1"); TODO;
	test("D0h  GRP2 RCR R/M8, 1"); TODO;
	test("D0h  GRP2 SAL/SHL R/M8, 1"); TODO;
	test("D0h  GRP2 SHR R/M8, 1"); TODO;
	test("D0h  GRP2 SAR R/M8, 1"); TODO;

	// Group 2, R/M16, 1

	test("D1h  GRP2 ROL R/M16, 1"); TODO;
	test("D1h  GRP2 ROR R/M16, 1"); TODO;
	test("D1h  GRP2 RCL R/M16, 1"); TODO;
	test("D1h  GRP2 RCR R/M16, 1"); TODO;
	test("D1h  GRP2 SAL/SHL R/M16, 1"); TODO;
	test("D1h  GRP2 SHR R/M16, 1"); TODO;
	test("D1h  GRP2 SAR R/M16, 1"); TODO;

	// Group 2, R/M8, CL

	test("D2h  GRP2 ROL R/M8, CL"); TODO;
	test("D2h  GRP2 ROR R/M8, CL"); TODO;
	test("D2h  GRP2 RCL R/M8, CL"); TODO;
	test("D2h  GRP2 RCR R/M8, CL"); TODO;
	test("D2h  GRP2 SAL/SHL R/M8, CL"); TODO;
	test("D2h  GRP2 SHR R/M8, CL"); TODO;
	test("D2h  GRP2 SAR R/M8, CL"); TODO;

	// Group 2, R/M16, CL

	test("D3h  GRP2 ROL R/M16, CL"); TODO;
	test("D3h  GRP2 ROR R/M16, CL"); TODO;
	test("D3h  GRP2 RCL R/M16, CL"); TODO;
	test("D3h  GRP2 RCR R/M16, CL"); TODO;
	test("D3h  GRP2 SAL/SHL R/M16, CL"); TODO;
	test("D3h  GRP2 SHR R/M16, CL"); TODO;
	test("D3h  GRP2 SAR R/M16, CL"); TODO;

	// AAM

	test("D4h  AAM"); TODO;

	// AAD

	test("D5h  AAD"); TODO;

	// XLAT SOURCE-TABLE

	test("D7h  XLAT SOURCE-TABLE");
	CPU.AL = 10;
	CPU.DS = 0x400;
	CPU.BX = 0x20;
	__iu8(36, get_ad(CPU.DS, CPU.BX) + CPU.AL);
	exec16(0xD7);
	assert(CPU.AL == 36);
	OK;

	// LOOP

	test("E0h  LOOPNE/LOOPNZ"); TODO;

	test("E1h  LOOPE/LOOPZ"); TODO;

	test("E2h  LOOP"); TODO;

	// JCXZ

	test("E3h  JCXZ"); TODO;

	// CALL

	test("E8h  CALL IMM16 (NEAR)"); TODO;

	// JMP

	test("E9h  JMP (NEAR)"); TODO;

	test("EAh  JMP (FAR)"); TODO;

	test("EBh  JMP (SHORT)"); TODO;

	// LOCK

	test("F0h  LOCK"); TODO;

	// REPNE/REPNZ

	test("F2h  REPNE/REPNZ"); TODO;

	// REP/REPE/REPNZ

	test("F3h  REP/REPE/REPNZ"); TODO;

	// HLT

	test("F4h  HLT"); TODO;

	// CMC

	CPU.CF = 0;
	test("F5h  CMC"); exec16(0xF5); assert(CPU.CF); OK;

	// Group 3, 8-bit

	test("F6h  GRP3 TEST");
	CPU.AL = 130;
	__iu8(0xAF, CPU.AL);
	__iu8(0b11_000_000, CPU.EIP + 1);
	__iu8(0xF, CPU.EIP + 2);
	exec16(0xF6);
	assert(CPU.ZF == 0 && CPU.OF == 0);
	OK;
	test("F6h  GRP3 NOT");
	__iu8(0b11_010_000, CPU.EIP + 1);
	__iu8(0xF, CPU.AL);
	exec16(0xF6);
	assert(__fu8(CPU.AL) == 0xF0);
	OK;
	test("F6h  GRP3 NEG");
	__iu8(0b11_011_000, CPU.EIP + 1);
	__iu8(0xF, CPU.AL);
	exec16(0xF6);
	assert(__fu8(CPU.AL) == 0xF1);
	assert(CPU.ZF == 0);
	assert(CPU.OF == 0);
	OK;
	test("F6h  GRP3 MUL");
	__iu8(0b11_100_000, CPU.EIP + 1);
	__iu8(2, CPU.EIP + 2);
	__iu8(4, CPU.AL);
	exec16(0xF6);
	assert(__fu8(CPU.AL) == 8);
	assert(CPU.ZF == 0);
	OK;
	test("F6h  GRP3 IMUL");
	__iu8(0b11_101_000, CPU.EIP + 1);
	__iu8(-2, CPU.EIP + 2);
	__iu8(4, CPU.AL);
	exec16(0xF6);
	assert(__fu8(CPU.AL) == 0xF8); // -8 as BYTE
	assert(CPU.ZF == 0);
	OK;
	test("F6h  GRP3 DIV");
	CPU.AX = 12;
	__iu8(0b11_110_000, CPU.EIP + 1);
	__iu8(8, CPU.AL);
	exec16(0xF6);
	assert(CPU.AL == 1);
	assert(CPU.AH == 4);
	OK;
	test("F6h  GRP3 IDIV");
	CPU.AX = 0xFFF4; // -12
	__iu8(0b11_111_000, CPU.EIP + 1);
	__iu8(8, CPU.AL);
	exec16(0xF6);
	assert(CPU.AL == 0xFF);
	assert(CPU.AH == 0xFC);
	OK;

	// Group 3, 16-bit

	test("F7h  GRP3 TEST"); TODO;
	test("F7h  GRP3 NOT"); TODO;
	test("F7h  GRP3 NEG"); TODO;
	test("F7h  GRP3 MUL"); TODO;
	test("F7h  GRP3 IMUL"); TODO;
	test("F7h  GRP3 DIV"); TODO;
	test("F7h  GRP3 IDIV"); TODO;

	// Flags

	test("F8h  CLC"); exec16(0xF8); assert(CPU.CF == 0); OK;
	test("F9h  STC"); exec16(0xF9); assert(CPU.CF); OK;
	test("FAh  CLI"); exec16(0xFA); assert(CPU.IF == 0); OK;
	test("FBh  STI"); exec16(0xFB); assert(CPU.IF); OK;
	test("FCh  CLD"); exec16(0xFC); assert(CPU.DF == 0); OK;
	test("FDh  STD"); exec16(0xFD); assert(CPU.DF); OK;

	// Group 4, 8-bit

	test("FEh  GRP4 INC"); TODO;
	test("FEh  GRP4 DEC"); TODO;

	// Group 5, 16-bit

	test("FFh  GRP4 INC"); TODO;
	test("FFh  GRP4 DEC"); TODO;
	test("FFh  GRP4 CALL R/M16 (NEAR)"); TODO;
	test("FFh  GRP4 CALL MEM16 (FAR)"); TODO;
	test("FFh  GRP4 JMP R/M16 (NEAR)"); TODO;
	test("FFh  GRP4 JMP MEM16 (FAR)"); TODO;
	test("FFh  GRP4 PUSH MEM16"); TODO;

	section("32-bit Instructions (i486)");

	test("Protected-mode"); TODO;
}