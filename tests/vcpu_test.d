import vcpu, vcpu_utils, vcpu16, std.stdio, vdos;
import test_utils;

unittest {
	vcpu_init;
	vCPU.CS = 0;
	vCPU.EIP = get_ip;

	section("Interpreter Utilities (vcpu_utils.d)");

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

	__iu8(0xAC, vCPU.EIP + 1);

	test("__fu8");
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

	__iu16(0xAAFF, vCPU.EIP + 1);

	test("__fu16");
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
	__iwstr("Hi!!"w);
	assert(MEMORY[vCPU.EIP     .. vCPU.EIP + 1] == "H"w);
	assert(MEMORY[vCPU.EIP + 2 .. vCPU.EIP + 3] == "i"w);
	assert(MEMORY[vCPU.EIP + 4 .. vCPU.EIP + 5] == "!"w);
	assert(MEMORY[vCPU.EIP + 6 .. vCPU.EIP + 7] == "!"w);
	OK;

	test("__iarr");
	ubyte[2] ar = [ 0xAA, 0xBB ];
	__iarr(cast(ubyte*)ar, 2, vCPU.EIP);
	assert(MEMORY[vCPU.EIP .. vCPU.EIP + 2] == [ 0xAA, 0xBB ]);
	OK;

	section("Registers");

	test("AL/AH");
	vCPU.EAX = 0x0807;
	assert(vCPU.AL == 7);
	assert(vCPU.AH == 8);
	OK;

	test("BL/BH");
	vCPU.EBX = 0x0605;
	assert(vCPU.BL == 5);
	assert(vCPU.BH == 6);
	OK;

	test("CL/CH");
	vCPU.ECX = 0x0403;
	assert(vCPU.CL == 3);
	assert(vCPU.CH == 4);
	OK;

	test("DL/DH");
	vCPU.EDX = 0x0201;
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

	test("IP");
	vCPU.EIP = 0x0F50;
	assert(vCPU.IP == 0x0F50);
	OK;

	test("FLAG");
	FLAG = 0xFFFF;
	assert(vCPU.SF); assert(vCPU.ZF); assert(vCPU.AF);
	assert(vCPU.PF); assert(vCPU.CF); assert(vCPU.OF);
	assert(vCPU.DF); assert(vCPU.IF); assert(vCPU.TF);
	assert(FLAGB == 0xD5);
	assert(FLAG == 0xFD5);
	FLAG = 0;
	assert(vCPU.SF == 0); assert(vCPU.ZF == 0); assert(vCPU.AF == 0);
	assert(vCPU.PF == 0); assert(vCPU.CF == 0); assert(vCPU.OF == 0);
	assert(vCPU.DF == 0); assert(vCPU.IF == 0); assert(vCPU.TF == 0);
	assert(FLAGB == 0);
	assert(FLAG == 0);
	OK;

	section("ModR/M");

	__iu16(0x1020, vCPU.EIP + 2); // low:20h
	vCPU.SI = 0x50; vCPU.DI = 0x50;
	vCPU.BX = 0x30; vCPU.BP = 0x30;
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
	vCPU.AX = 0x2040; vCPU.CX = 0x2141;
	vCPU.DX = 0x2242; vCPU.BX = 0x2343;
	vCPU.SP = 0x2030; vCPU.BP = 0x2131;
	vCPU.SI = 0x2232; vCPU.DI = 0x2333;
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

	test("01h  ADD R/M16, REG16");
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
	
	test("02h  ADD REG8, R/M8");
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

	test("03h  ADD REG16, R/M16"); TODO;

	test("04h  ADD AL, IMM8");
	__iu8(4, vCPU.EIP + 1);
	vCPU.AL = 12;
	exec16(0x04);
	assert(vCPU.AL == 16);
	OK;

	test("05h  ADD AX, IMM16");
	__iu16(4, vCPU.EIP + 1);
	vCPU.AX = 1200;
	exec16(0x05);
	assert(vCPU.AX == 1204);
	OK;

	// PUSH ES

	test("06h  PUSH ES");
	vCPU.ES = 189;
	exec16(0x06);
	assert(__fu16(get_ad(vCPU.SS, vCPU.SP)) == 189);
	OK;

	// POP ES

	test("07h  POP ES");
	vCPU.ES = 83;
	exec16(0x07);
	assert(vCPU.ES == 189); // sanity check
	OK;

	// OR R/M8, REG8

	test("08h  OR R/M8, REG8"); TODO;

	// OR R/M16, REG16

	test("09h  OR R/M16, REG16"); TODO;

	// OR REG8, R/M8

	test("0Ah  OR REG8, R/M8"); TODO;

	// OR REG16, R/M16

	test("0Bh  OR REG16, R/M16"); TODO;

	// OR AL, IMM8

	test("0Ch  OR AL, IMM8");
	__iu8(0xF0, vCPU.EIP + 1);
	vCPU.AL = 0xF;
	exec16(0x0C); // OR vCPU.AL, 3
	assert(vCPU.AL == 0xFF);
	OK;

	// OR AX, IMM16

	test("0Dh  OR AX, IMM16");
	__iu16(0xFF00, vCPU.EIP + 1);
	exec16(0x0D); // OR vCPU.AX, F0h
	assert(vCPU.AX == 0xFFFF);
	OK;

	// PUSH CS

	test("0Eh  PUSH CS");
	vCPU.CS = 318;
	exec16(0x0E);
	assert(__fu16(get_ad(vCPU.SS, vCPU.SP)) == 318);
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
	vCPU.SS = 202;
	exec16(0x16);
	assert(__fu16(get_ad(vCPU.SS, vCPU.SP)) == 202);
	OK;

	// POP SS

	test("17h  POP SS");
	exec16(0x17);
	assert(vCPU.SS == 202);
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
	vCPU.DS = 444;
	exec16(0x1E);
	assert(__fu16(get_ad(vCPU.SS, vCPU.SP)) == 444);
	OK;

	// POP DS

	test("1Fh  POP DS");
	vCPU.DS = 128;
	exec16(0x1F);
	assert(vCPU.DS == 444);
	OK;

	// AND R/M8, REG8

	test("20h  AND R/M8, REG8"); TODO;

	// AND R/M16, REG16

	test("21h  AND R/M16, REG16"); TODO;

	// AND REG8, R/M8

	test("22h  AND REG8, R/M8"); TODO;

	// AND REG16, R/M16

	test("23h  AND REG16, R/M16"); TODO;

	// AND AL, IMM8

	test("24h  AND AL, IMM8"); TODO;

	// AND AX, IMM16

	test("25h  AND AX, IMM16"); TODO;

	// ES:

	test("26h  ES:");
	exec16(0x26);
	assert(Seg == SEG_ES);
	OK;

	// DAA

	test("27h  DAA"); TODO;

	// SUB R/M8, REG8

	test("28h  SUB R/M8, REG8"); TODO;

	// SUB R/M16, REG16

	test("29h  SUB R/M16, REG16"); TODO;

	// SUB REG8, R/M8

	test("2Ah  SUB REG8, R/M8"); TODO;

	// SUB REG16, R/M16

	test("2Bh  SUB REG16, R/M16"); TODO;

	// SUB AL, IMM8

	test("2Ch  SUB AL, IMM8"); TODO;

	// SUB AX, IMM16

	test("2Dh  SUB AX, IMM16"); TODO;

	// CS:

	test("2Eh  CS:");
	exec16(0x2E);
	assert(Seg == SEG_CS);
	OK;

	// DAS

	test("2Fh  DAS"); TODO;

	// XOR

	test("30h  XOR R/M8, REG8"); TODO;

	test("31h  XOR R/M16, REG16"); TODO;

	test("32h  XOR REG8, R/M8"); TODO;

	test("33h  XOR REG16, R/M16"); TODO;

	test("34h  XOR AL, IMM8");
	__iu8(5, vCPU.EIP + 1);
	vCPU.AL = 0xF;
	exec16(0x34); // XOR vCPU.AL, 5
	assert(vCPU.AL == 0xA);
	OK;

	test("35h  XOR AX, IMM16");
	__iu16(0xFF00, vCPU.EIP + 1);
	vCPU.AX = 0xAAFF;
	exec16(0x35); // XOR vCPU.AX, FF00h
	assert(vCPU.AX == 0x55FF);
	OK;

	// INC

	fullreset; vCPU.CS = 0;
	test("40h  INC AX");
	exec16(0x40); assert(vCPU.AX == 1);
	OK;
	test("41h  INC CX");
	exec16(0x41); assert(vCPU.CX == 1);
	OK;
	test("42h  INC DX");
	exec16(0x42); assert(vCPU.DX == 1);
	OK;
	test("43h  INC BX");
	exec16(0x43); assert(vCPU.BX == 1);
	OK;
	test("44h  INC SP");
	exec16(0x44); assert(vCPU.SP == 1);
	OK;
	test("45h  INC BP");
	exec16(0x45); assert(vCPU.BP == 1);
	OK;
	test("46h  INC SI");
	exec16(0x46); assert(vCPU.SI == 1);
	OK;
	test("47h  INC SI");
	exec16(0x47); assert(vCPU.DI == 1);
	OK;
	
	// DEC

	test("48h  DEC AX");
	exec16(0x48);
	assert(vCPU.AX == 0);
	OK;
	test("49h  DEC CX");
	exec16(0x49);
	assert(vCPU.CX == 0);
	OK;
	test("4Ah  DEC DX");
	exec16(0x4A);
	assert(vCPU.DX == 0);
	OK;
	test("4Bh  DEC BX");
	exec16(0x4B);
	assert(vCPU.BX == 0);
	OK;
	test("4Ch  DEC SP");
	exec16(0x4C);
	assert(vCPU.SP == 0);
	OK;
	test("4Dh  DEC BP");
	exec16(0x4D);
	assert(vCPU.BP == 0);
	OK;
	test("4Eh  DEC SI");
	exec16(0x4E);
	assert(vCPU.SI == 0);
	OK;
	test("4Fh  DEC DI");
	exec16(0x4F);
	assert(vCPU.DI == 0);
	OK;

	// PUSH

	vCPU.SS = 0x100; vCPU.SP = 0x60;

	test("50h  PUSH AX");
	vCPU.AX = 0xDAD;
	exec16(0x50);
	assert(vCPU.AX == __fu16(get_ad(vCPU.SS, vCPU.SP)));
	OK;

	test("51h  PUSH CX");
	vCPU.CX = 0x4488;
	exec16(0x51);
	assert(vCPU.CX == __fu16(get_ad(vCPU.SS, vCPU.SP)));
	OK;

	test("52h  PUSH DX");
	vCPU.DX = 0x4321;
	exec16(0x52);
	assert(vCPU.DX == __fu16(get_ad(vCPU.SS, vCPU.SP)));
	OK;

	test("53h  PUSH BX");
	vCPU.BX = 0x1234;
	exec16(0x53);
	assert(vCPU.BX == __fu16(get_ad(vCPU.SS, vCPU.SP)));
	OK;

	test("54h  PUSH SP");
	exec16(0x54);
	assert(vCPU.SP == __fu16(get_ad(vCPU.SS, vCPU.SP)) - 2);
	OK;

	test("55h  PUSH BP");
	vCPU.BP = 0xFBAC;
	exec16(0x55);
	assert(vCPU.BP == __fu16(get_ad(vCPU.SS, vCPU.SP)));
	OK;

	test("56h  PUSH SI");
	vCPU.SI = 0xF00F;
	exec16(0x56);
	assert(vCPU.SI == __fu16(get_ad(vCPU.SS, vCPU.SP)));
	OK;

	test("57h  PUSH DI");
	vCPU.DI = 0xB0B;
	exec16(0x57);
	assert(vCPU.DI == __fu16(get_ad(vCPU.SS, vCPU.SP)));
	OK;

	// POP

	vCPU.SS = 0x100; vCPU.SP = 0x20;

	test("58h  POP AX");
	push16(0xFFAA);
	exec16(0x58);
	assert(vCPU.AX == 0xFFAA);
	OK;
	
	vCPU.SP -= 2;
	test("59h  POP CX");
	exec16(0x59);
	assert(vCPU.CX == 0xFFAA);
	OK;

	vCPU.SP -= 2;
	test("5Ah  POP DX");
	exec16(0x5A);
	assert(vCPU.DX == 0xFFAA);
	OK;

	vCPU.SP -= 2;
	test("5Bh  POP BX");
	exec16(0x5B);
	assert(vCPU.BX == 0xFFAA);
	OK;

	vCPU.SP -= 2;
	test("5Ch  POP SP");
	exec16(0x5C);
	assert(vCPU.SP == 0xFFAA);
	OK;

	vCPU.SP = 0x1E;
	test("5Dh  POP BX");
	exec16(0x5D);
	assert(vCPU.BP == 0xFFAA);
	OK;

	vCPU.SP -= 2;
	test("5Eh  POP SI");
	exec16(0x5E);
	assert(vCPU.SI == 0xFFAA);
	OK;

	vCPU.SP -= 2;
	test("5Fh  POP DI");
	exec16(0x5F);
	assert(vCPU.DI == 0xFFAA);
	OK;

	// Jumps

	test("70h  JO"); TODO;
	test("71h  JNO"); TODO;
	test("72h  JB/JNAE/JC"); TODO;
	test("73h  JNB/JAE/JNC"); TODO;
	test("74h  JE/JZ"); TODO;
	test("75h  JNE/JNZ"); TODO;
	test("76h  JBE/JNA"); TODO;
	test("77h  JNBE/JA"); TODO;
	test("78h  JS"); TODO;
	test("79h  JNS"); TODO;
	test("7Ah  JP/JPE"); TODO;
	test("7Bh  JNP/JPO"); TODO;
	test("7Ch  JL/JNGE"); TODO;
	test("7Dh  JNL/JGE"); TODO;
	test("7Eh  JLE/JNG"); TODO;
	test("7Fh  JNLE/JG"); TODO;

	// Group 1

	test("80h  GRP1 ADD");
	vCPU.AL = 0x40;
	__iu8(10, vCPU.AL);
	__iu8(0b11_000_000, vCPU.EIP+1);
	__iu8(20, vCPU.EIP+2);
	exec16(0x80);
	assert(__fu8(vCPU.AL) == 30);
	OK;
	test("80h  GRP1 OR");
	vCPU.AL = 0x40;
	__iu8(0b1100_0011, vCPU.AL);
	__iu8(0b11_001_000, vCPU.EIP+1);
	__iu8(0b0011_0000, vCPU.EIP+2);
	exec16(0x80);
	assert(__fu8(vCPU.AL) == 0b1111_0011);
	OK;
	test("80h  GRP1 ADC"); TODO;
	test("80h  GRP1 SBB"); TODO;
	test("80h  GRP1 AND");
	vCPU.AL = 0x40;
	__iu8(0b0011_0011, vCPU.AL);
	__iu8(0b11_100_000, vCPU.EIP+1);
	__iu8(0b0011_0000, vCPU.EIP+2);
	exec16(0x80);
	assert(__fu8(vCPU.AL) == 0b0011_0000);
	OK;
	test("80h  GRP1 SUB/CMP");
	vCPU.AL = 0x40;
	__iu8(45, vCPU.AL);
	__iu8(0b11_101_000, vCPU.EIP+1);
	__iu8(20, vCPU.EIP+2);
	exec16(0x80);
	assert(__fu8(vCPU.AL) == 25);
	OK;
	test("80h  GRP1 XOR");
	vCPU.AL = 0x40;
	__iu8(40, vCPU.AL);
	__iu8(0b11_110_000, vCPU.EIP+1);
	__iu8(20, vCPU.EIP+2);
	exec16(0x80);
	assert(__fu8(vCPU.AL) == 60);
	OK;

	test("81h  GRP1 ADD");
	vCPU.AX = 0x400;
	__iu16(40, vCPU.AX);
	__iu8(0b11_000_000, vCPU.EIP+1);
	__iu16(222, vCPU.EIP+2);
	exec16(0x81);
	assert(__fu16(vCPU.AX) == 262);
	OK;
	test("81h  GRP1 OR");
	vCPU.AX = 0x400;
	__iu16(40, vCPU.AX);
	__iu8(0b11_001_000, vCPU.EIP+1);
	__iu16(222, vCPU.EIP+2);
	exec16(0x81);
	assert(__fu16(vCPU.AX) == 254);
	OK;
	test("81h  GRP1 ADC"); TODO;
	test("81h  GRP1 SBB"); TODO;
	test("81h  GRP1 AND");
	vCPU.AX = 0x400;
	__iu16(40, vCPU.AX);
	__iu8(0b11_100_000, vCPU.EIP+1);
	__iu16(222, vCPU.EIP+2);
	exec16(0x81);
	assert(__fu16(vCPU.AX) == 8);
	OK;
	test("81h  GRP1 SUB/CMP");
	vCPU.AX = 0x400;
	__iu16(222, vCPU.AX);
	__iu8(0b11_101_000, vCPU.EIP+1);
	__iu16(40, vCPU.EIP+2);
	exec16(0x81);
	assert(__fu16(vCPU.AX) == 182);
	OK;
	test("81h  GRP1 XOR");
	vCPU.AX = 0x400;
	__iu16(222, vCPU.AX);
	__iu8(0b11_110_000, vCPU.EIP+1);
	__iu16(40, vCPU.EIP+2);
	exec16(0x81);
	assert(__fu16(vCPU.AX) == 246);
	OK;

	// Group 2

	test("82h  GRP2 ADD");
	vCPU.AL = 0x40;
	__iu8(40, vCPU.AL);
	__iu8(0b11_000_000, vCPU.EIP+1);
	__iu8(20, vCPU.EIP+2);
	exec16(0x82);
	assert(__fu8(vCPU.AL) == 60);
	OK;
	test("82h  GRP2 ADC"); TODO;
	test("82h  GRP2 SBB"); TODO;
	test("82h  GRP2 SUB/CMP");
	vCPU.AL = 0x40;
	__iu8(40, vCPU.AL);
	__iu8(0b11_101_000, vCPU.EIP+1);
	__iu8(20, vCPU.EIP+2);
	exec16(0x82);
	assert(__fu8(vCPU.AL) == 20);
	OK;

	test("83h  GRP2 ADD");
	vCPU.AX = 0x400;
	__iu16(40, vCPU.AX);
	__iu8(0b11_000_000, vCPU.EIP+1);
	__iu16(20, vCPU.EIP+2);
	exec16(0x83);
	assert(__fu16(vCPU.AX) == 60);
	OK;
	test("83h  GRP2 ADC"); TODO;
	test("83h  GRP2 SBB"); TODO;
	test("83h  GRP2 SUB/CMP");
	vCPU.AX = 0x400;
	__iu16(40, vCPU.AX);
	__iu8(0b11_101_000, vCPU.EIP + 1);
	__iu16(25, vCPU.EIP + 2);
	exec16(0x83);
	assert(__fu16(vCPU.AX) == 15);
	OK;

	// TEST

	test("84h  TEST R/M8, REG8"); TODO;

	test("85h  TEST R/M16, REG16"); TODO;

	// XCHG

	test("86h  XCHG REG8, R/M8"); TODO;

	test("87h  XCHG REG16, R/M16"); TODO;

	// MOV REG8, R/M8

	test("88h  MOV R/M8, REG8");
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

	// MOV R/M16, REG16

	test("89h  MOV R/M16, REG16");
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

	// MOV R/M16, REG16

	test("8Ah  MOV REG8, R/M8");
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

	// MOV REG16, R/M16

	test("8Bh  MOV REG16, R/M16");
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

	// MOV R/M16, SEGREG

	test("8Ch  MOV R/M16, SEGREG");
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

	// LEA REG16, MEM16

	test("8Dh  LEA REG16, MEM16"); TODO;

	// MOV SEGREG, R/M16

	test("8Eh  MOV SEGREG, R/M16");
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

	// POP R/M16

	test("8Fh  POP R/M16"); TODO;

	// XCHG

	test("90h  NOP");
	{ // Nevertheless, let's test the Program Counter
		const int oldip = vCPU.IP + 1;
		exec16(0x90);
		assert(oldip == vCPU.IP);
	}
	OK;

	test("91h  XCHG AX, CX");
	vCPU.AX = 0xFAB;
	vCPU.CX = 0xAABB;
	exec16(0x91);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.CX == 0xFAB);
	OK;

	test("92h  XCHG AX, DX");
	vCPU.AX = 0xFAB;
	vCPU.DX = 0xAABB;
	exec16(0x92);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.DX == 0xFAB);
	OK;

	test("93h  XCHG AX, BX");
	vCPU.AX = 0xFAB;
	vCPU.BX = 0xAABB;
	exec16(0x93);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.BX == 0xFAB);
	OK;

	test("94h  XCHG AX, SP");
	vCPU.AX = 0xFAB;
	vCPU.SP = 0xAABB;
	exec16(0x94);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.SP == 0xFAB);
	OK;

	test("95h  XCHG AX, BP");
	vCPU.AX = 0xFAB;
	vCPU.BP = 0xAABB;
	exec16(0x95);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.BP == 0xFAB);
	OK;

	test("96h  XCHG AX, SI");
	vCPU.AX = 0xFAB;
	vCPU.SI = 0xAABB;
	exec16(0x96);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.SI == 0xFAB);
	OK;

	test("97h  XCHG AX, DI");
	vCPU.AX = 0xFAB;
	vCPU.DI = 0xAABB;
	exec16(0x97);
	assert(vCPU.AX == 0xAABB);
	assert(vCPU.DI == 0xFAB);
	OK;

	// CBW

	test("98h  CBW");
	vCPU.AL = 0;
	exec16(0x98);
	assert(vCPU.AH == 0);
	vCPU.AL = 0xFF;
	exec16(0x98);
	assert(vCPU.AH == 0xFF);
	OK;

	// CWD

	test("99h  CWD");
	vCPU.AX = 0;
	exec16(0x99);
	assert(vCPU.DX == 0);
	vCPU.AX = 0xFFFF;
	exec16(0x99);
	assert(vCPU.DX == 0xFFFF);
	OK;

	// WAIT

	test("9Bh  WAIT"); TODO;

	// PUSHF

	test("9Ch  PUSHF"); TODO;

	// POPF

	test("9Dh  POPF"); TODO;

	// SAHF

	test("9Eh  SAHF"); TODO;

	// LAHF

	test("9Fh  LAHF"); TODO;

	// MOV AL, MEM8

	test("A0h  MOV AL, MEM8");
	__iu8(167, 0x8000);
	__iu16(0x8000, vCPU.EIP + 1);
	exec16(0xA0);
	assert(vCPU.AL == 167);
	OK;

	// MOV AX, MEM16

	test("A1h  MOV AX, MEM16");
	__iu16(1670, 0x8000);
	__iu16(0x8000, vCPU.EIP + 1);
	exec16(0xA1);
	assert(vCPU.AX == 1670);
	OK;

	// MOV MEM8, AL

	test("A2h  MOV MEM8, AL");
	vCPU.AL = 143;
	__iu16(0x4000, vCPU.EIP + 1);
	exec16(0xA2);
	assert(__fu8(0x4000) == 143);
	OK;

	// MOV MEM16, AX

	test("A3h  MOV MEM16, AX");
	vCPU.AX = 1430;
	__iu16(0x4000, vCPU.EIP + 1);
	exec16(0xA3);
	assert(__fu16(0x4000) == 1430);
	OK;

	// CMPS

	vCPU.DF = 0;

	test("A6h  CMPS");
	vCPU.CS = vCPU.ES = 0xF00; vCPU.DI = vCPU.EIP = 0x100;
	__istr("HELL", get_ip);
	vCPU.CS = vCPU.DS = 0xF00; vCPU.SI = vCPU.EIP = 0x110;
	__istr("HeLL", get_ip);
	exec16(0xA6);
	assert(vCPU.ZF);
	exec16(0xA6);
	assert(!vCPU.ZF);
	exec16(0xA6);
	assert(vCPU.ZF);
	exec16(0xA6);
	assert(vCPU.ZF);
	OK;

	test("A7h  CMPSW");
	vCPU.CS = vCPU.ES = 0xF00; vCPU.DI = vCPU.EIP = 0x100;
	__iwstr("HELL"w, get_ip);
	vCPU.CS = vCPU.DS = 0xF00; vCPU.SI = vCPU.EIP = 0x110;
	__iwstr("HeLL"w, get_ip);
	exec16(0xA7);
	assert(vCPU.ZF);
	exec16(0xA7);
	assert(!vCPU.ZF);
	exec16(0xA7);
	assert(vCPU.ZF);
	exec16(0xA7);
	assert(vCPU.ZF);
	OK;

	// TEST AL, IMM8

	test("A8h  TEST AL, IMM8");
	vCPU.AL = 0b1100;
	__iu8(0b1100, vCPU.EIP + 1);
	exec16(0xA8);
	assert(vCPU.PF);
	assert(vCPU.ZF == 0);
	assert(vCPU.SF == 0);
	assert(vCPU.CF == 0);
	assert(vCPU.OF == 0);
	vCPU.AL = 0xF0;
	__iu8(0x0F, vCPU.EIP + 1);
	exec16(0xA8);
	assert(vCPU.PF);
	assert(vCPU.ZF);
	assert(vCPU.SF == 0);
	assert(vCPU.CF == 0);
	assert(vCPU.OF == 0);
	OK;

	// TEST AX, IMM16

	test("A9h  TEST AX, IMM16");
	vCPU.AX = 0xAA00;
	__iu16(0xAA00, vCPU.EIP + 1);
	exec16(0xA9);
	assert(vCPU.PF);
	assert(vCPU.ZF == 0);
	assert(vCPU.SF);
	assert(vCPU.CF == 0);
	assert(vCPU.OF == 0);
	OK;

	// STOS

	test("AAh  STOS");
	vCPU.ES = 0x20; vCPU.DI = 0x20;        
	vCPU.AL = 'Q';
	exec16(0xAA);
	assert(MEMORY[get_ad(vCPU.ES, vCPU.DI - 1)] == 'Q');
	OK;

	test("ABh  STOSW");
	vCPU.ES = 0x200; vCPU.DI = 0x200;        
	vCPU.AX = 0xACDC;
	exec16(0xAB);
	assert(__fu16(get_ad(vCPU.ES, vCPU.DI - 2)) == 0xACDC);
	OK;

	// LODS

	test("ACh  LODS"); // of dosh
	vCPU.AL = 0;
	vCPU.DS = 0xA0; vCPU.SI = 0x200;
	MEMORY[get_ad(vCPU.DS, vCPU.SI)] = 'H';
	exec16(0xAC);
	assert(vCPU.AL == 'H');
	MEMORY[get_ad(vCPU.DS, vCPU.SI)] = 'e';
	exec16(0xAC);
	assert(vCPU.AL == 'e');
	OK;

	test("ADh  LODSW");
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

	test("AEh  SCAS");
	vCPU.ES = vCPU.CS = 0x400; vCPU.DI = 0x20; vCPU.IP = 0x20;
	vCPU.EIP = get_ip;
	__istr("Hello!");
	vCPU.AL = 'H';
	exec16(0xAE);
	assert(vCPU.ZF);
	vCPU.AL = '1';
	exec16(0xAE);
	assert(!vCPU.ZF);
	OK;

	test("AFh  SCASW");
	vCPU.CS = 0x800; vCPU.ES = 0x800; vCPU.EIP = 0x30; vCPU.DI = 0x30;
	__iu16(0xFE22, get_ad(vCPU.ES, vCPU.DI));
	vCPU.AX = 0xFE22;
	exec16(0xAF);
	assert(vCPU.ZF);
	exec16(0xAF);
	assert(!vCPU.ZF);
	OK;

	// MOV REG8, IMM8

	test("B0h  MOV AL, IMM8");
	__iu8(0x1, vCPU.EIP + 1);
	exec16(0xB0); // MOV AL, 1
	assert(vCPU.AL == 1);
	OK;

	test("B1h  MOV CL, IMM8");
	__iu8(0x2, vCPU.EIP + 1);
	exec16(0xB1); // MOV CL, 2
	assert(vCPU.CL == 2);
	OK;

	test("B2h  MOV DL, IMM8");
	__iu8(0x3, vCPU.EIP + 1);
	exec16(0xB2); // MOV DL, 3
	assert(vCPU.DL == 3);
	OK;

	test("B3h  MOV BL, IMM8");
	__iu8(0x4, vCPU.EIP + 1);
	exec16(0xB3); // MOV BL, 4
	assert(vCPU.BL == 4);
	OK;

	test("B4h  MOV AH, IMM8");
	__iu8(0x5, vCPU.EIP + 1);
	exec16(0xB4); // MOV AH, 5
	assert(vCPU.AH == 5);
	OK;

	test("B5h  MOV CH, IMM8");
	__iu8(0x6, vCPU.EIP + 1);
	exec16(0xB5); // MOV CH, 6
	assert(vCPU.CH == 6);
	OK;

	test("B6h  MOV DH, IMM8");
	__iu8(0x7, vCPU.EIP + 1);
	exec16(0xB6); // MOV DH, 7
	assert(vCPU.DH == 7);
	OK;

	test("B7h  MOV BH, IMM8");
	__iu8(0x8, vCPU.EIP + 1);
	exec16(0xB7); // MOV BH, 8
	assert(vCPU.BH == 8);
	OK;

	// MOV REG16, IMM16

	test("B8h  MOV AX, IMM16");
	__iu16(0x1112, vCPU.EIP + 1);
	exec16(0xB8); // MOV AX, 1112h
	assert(vCPU.AX == 0x1112);
	OK;

	test("B9h  MOV CX, IMM16");
	__iu16(0x1113, vCPU.EIP + 1);
	exec16(0xB9); // MOV CX, 1113h
	assert(vCPU.CX == 0x1113);
	OK;

	test("BAh  MOV DX, IMM16");
	__iu16(0x1114, vCPU.EIP + 1);
	exec16(0xBA); // MOV DX, 1114h
	assert(vCPU.DX == 0x1114);
	OK;

	test("BBh  MOV BX, IMM16");
	__iu16(0x1115, vCPU.EIP + 1);
	exec16(0xBB); // MOV BX, 1115h
	assert(vCPU.BX == 0x1115);
	OK;

	test("BCh  MOV SP, IMM16");
	__iu16(0x1116, vCPU.EIP + 1);
	exec16(0xBC); // MOV SP, 1116h
	assert(vCPU.SP == 0x1116);
	OK;

	test("BDh  MOV BP, IMM16");
	__iu16(0x1117, vCPU.EIP + 1);
	exec16(0xBD); // MOV BP, 1117h
	assert(vCPU.BP == 0x1117);
	OK;

	test("BEh  MOV SI, IMM16");
	__iu16(0x1118, vCPU.EIP + 1);
	exec16(0xBE); // MOV SI, 1118h
	assert(vCPU.SI == 0x1118);
	OK;

	test("BFh  MOV DI, IMM16");
	__iu16(0x1119, vCPU.EIP + 1);
	exec16(0xBF); // MOV DI, 1119h
	assert(vCPU.DI == 0x1119);
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
	vCPU.AL = 10;
	vCPU.DS = 0x400;
	vCPU.BX = 0x20;
	__iu8(36, get_ad(vCPU.DS, vCPU.BX) + vCPU.AL);
	exec16(0xD7);
	assert(vCPU.AL == 36);
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

	vCPU.CF = 0;
	test("F5h  CMC"); exec16(0xF5); assert(vCPU.CF); OK;

	// Group 3, 8-bit

	test("F6h  GRP3 TEST");
	vCPU.AL = 130;
	__iu8(0xAF, vCPU.AL);
	__iu8(0b11_000_000, vCPU.EIP + 1);
	__iu8(0xF, vCPU.EIP + 2);
	exec16(0xF6);
	assert(vCPU.ZF == 0 && vCPU.OF == 0);
	OK;
	test("F6h  GRP3 NOT");
	__iu8(0b11_010_000, vCPU.EIP + 1);
	__iu8(0xF, vCPU.AL);
	exec16(0xF6);
	assert(__fu8(vCPU.AL) == 0xF0);
	OK;
	test("F6h  GRP3 NEG");
	__iu8(0b11_011_000, vCPU.EIP + 1);
	__iu8(0xF, vCPU.AL);
	exec16(0xF6);
	assert(__fu8(vCPU.AL) == 0xF1);
	assert(vCPU.ZF == 0);
	assert(vCPU.OF == 0);
	OK;
	test("F6h  GRP3 MUL");
	__iu8(0b11_100_000, vCPU.EIP + 1);
	__iu8(2, vCPU.EIP + 2);
	__iu8(4, vCPU.AL);
	exec16(0xF6);
	assert(__fu8(vCPU.AL) == 8);
	assert(vCPU.ZF == 0);
	OK;
	test("F6h  GRP3 IMUL");
	__iu8(0b11_101_000, vCPU.EIP + 1);
	__iu8(-2, vCPU.EIP + 2);
	__iu8(4, vCPU.AL);
	exec16(0xF6);
	assert(__fu8(vCPU.AL) == 0xF8); // -8 as BYTE
	assert(vCPU.ZF == 0);
	OK;
	test("F6h  GRP3 DIV");
	vCPU.AX = 12;
	__iu8(0b11_110_000, vCPU.EIP + 1);
	__iu8(8, vCPU.AL);
	exec16(0xF6);
	assert(vCPU.AL == 1);
	assert(vCPU.AH == 4);
	OK;
	test("F6h  GRP3 IDIV");
	vCPU.AX = 0xFFF4; // -12
	__iu8(0b11_111_000, vCPU.EIP + 1);
	__iu8(8, vCPU.AL);
	exec16(0xF6);
	assert(vCPU.AL == 0xFF);
	assert(vCPU.AH == 0xFC);
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

	test("F8h  CLC"); exec16(0xF8); assert(vCPU.CF == 0); OK;
	test("F9h  STC"); exec16(0xF9); assert(vCPU.CF); OK;
	test("FAh  CLI"); exec16(0xFA); assert(vCPU.IF == 0); OK;
	test("FBh  STI"); exec16(0xFB); assert(vCPU.IF); OK;
	test("FCh  CLD"); exec16(0xFC); assert(vCPU.DF == 0); OK;
	test("FDh  STD"); exec16(0xFD); assert(vCPU.DF); OK;

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