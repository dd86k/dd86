import test_utils;
import vcpu.core, vcpu.v16, vcpu.mm, vcpu.utils;

unittest {
	vcpu_init;
	CPU.CS = 0;
	CPU.EIP = get_ip;

	section("Interpreter Utilities (vcpu.utils.d)");

	test("mmiu8");
	mmiu8(0xFF, CPU.EIP);
	assert(MEMORY[CPU.EIP]     == 0xFF);
	mmiu8(0x12, CPU.EIP + 2);
	assert(MEMORY[CPU.EIP + 2] == 0x12);
	OK;

	test("mmiu16");
	mmiu16(0x100, CPU.EIP);
	assert(MEMORY[CPU.EIP]     == 0);
	assert(MEMORY[CPU.EIP + 1] == 1);
	mmiu16(0xABCD, CPU.EIP);
	assert(MEMORY[CPU.EIP]     == 0xCD);
	assert(MEMORY[CPU.EIP + 1] == 0xAB);
	mmiu16(0x5678, 4);
	assert(MEMORY[4] == 0x78);
	assert(MEMORY[5] == 0x56);
	OK;

	test("mmiu32");
	mmiu32(0xAABBCCFF, CPU.EIP);
	assert(MEMORY[CPU.EIP    ] == 0xFF);
	assert(MEMORY[CPU.EIP + 1] == 0xCC);
	assert(MEMORY[CPU.EIP + 2] == 0xBB);
	assert(MEMORY[CPU.EIP + 3] == 0xAA);
	OK;

	mmiu8(0xAC, CPU.EIP + 1);

	test("mmfu8");
	assert(mmfu8(CPU.EIP + 1) == 0xAC);
	OK;

	test("mmfu8_i");
	assert(mmfu8_i == 0xAC);
	OK;

	test("mmfi8");
	assert(mmfi8(CPU.EIP + 1) == cast(byte)0xAC);
	OK;

	test("mmfi8_i");
	assert(mmfi8_i == cast(byte)0xAC);
	OK;

	mmiu16(0xAAFF, CPU.EIP + 1);

	test("mmfu16");
	assert(mmfu16(CPU.EIP + 1) == 0xAAFF);
	OK;

	test("mmfi16");
	assert(mmfi16(CPU.EIP + 1) == cast(short)0xAAFF);
	OK;

	test("mmfu16_i");
	assert(mmfu16_i == 0xAAFF);
	OK;

	test("mmfi16_i");
	assert(mmfi16_i == cast(short)0xAAFF);
	OK;

	test("mmfu32");
	mmiu32(0xDCBA_FF00, CPU.EIP + 1);
	assert(mmfu32(CPU.EIP + 1) == 0xDCBA_FF00);
	OK;

	/*test("__fu32_i");
	assert(__fu32_i == 0xDCBA_FF00);
	OK;*/

	test("mmistr");
	mmistr("AB$");
	assert(MEMORY[CPU.EIP .. CPU.EIP + 3] == "AB$");
	mmistr("QWERTY", CPU.EIP + 10);
	assert(MEMORY[CPU.EIP + 10 .. CPU.EIP + 16] == "QWERTY");
	OK;

	test("mmiwstr");
	mmiwstr("Hi!!"w);
	assert(MEMORY[CPU.EIP     .. CPU.EIP + 1] == "H"w);
	assert(MEMORY[CPU.EIP + 2 .. CPU.EIP + 3] == "i"w);
	assert(MEMORY[CPU.EIP + 4 .. CPU.EIP + 5] == "!"w);
	assert(MEMORY[CPU.EIP + 6 .. CPU.EIP + 7] == "!"w);
	OK;

	test("mmiarr");
	ubyte[2] ar = [ 0xAA, 0xBB ];
	mmiarr(cast(ubyte*)ar, 2, CPU.EIP);
	assert(MEMORY[CPU.EIP .. CPU.EIP + 2] == [ 0xAA, 0xBB ]);
	OK;

	test("Registers");

	CPU.EAX = 0x40_0807;
	assert(CPU.AL == 7);
	assert(CPU.AH == 8);
	assert(CPU.AX == 0x0807);

	CPU.EBX = 0x41_0605;
	assert(CPU.BL == 5);
	assert(CPU.BH == 6);
	assert(CPU.BX == 0x0605);

	CPU.ECX = 0x42_0403;
	assert(CPU.CL == 3);
	assert(CPU.CH == 4);
	assert(CPU.CX == 0x0403);

	CPU.EDX = 0x43_0201;
	assert(CPU.DL == 1);
	assert(CPU.DH == 2);
	assert(CPU.DX == 0x0201);

	CPU.ESI = 0x44_9001;
	assert(CPU.SI == 0x9001);

	CPU.EDI = 0x44_9002;
	assert(CPU.DI == 0x9002);

	CPU.EBP = 0x44_9003;
	assert(CPU.BP == 0x9003);

	CPU.ESP = 0x44_9004;
	assert(CPU.SP == 0x9004);

	CPU.EIP = 0x40_0F50;
	assert(CPU.IP == 0x0F50);

	OK;
	CPU.EIP = 0x100;

	test("EFLAGS/FLAGS");
	FLAG = 0xFFFF;
	assert(CPU.SF); assert(CPU.ZF); assert(CPU.AF);
	assert(CPU.PF); assert(CPU.CF); assert(CPU.OF);
	assert(CPU.DF); assert(CPU.IF); assert(CPU.TF);
	assert(FLAGB == 0xD7);
	assert(FLAG == 0xFD7);
	FLAG = 0;
	assert(CPU.SF == 0); assert(CPU.ZF == 0); assert(CPU.AF == 0);
	assert(CPU.PF == 0); assert(CPU.CF == 0); assert(CPU.OF == 0);
	assert(CPU.DF == 0); assert(CPU.IF == 0); assert(CPU.TF == 0);
	assert(FLAGB == 2); assert(FLAG == 2);
	//TODO: EFLAGS
	OK;

	section("ModR/M");

	mmiu16(0x1020, CPU.EIP + 2); // low:20h
	CPU.SI = 0x50; CPU.DI = 0x50;
	CPU.BX = 0x30; CPU.BP = 0x30;
	test("16-bit ModR/M");
	// MOD=00
	assert(mmrm16(0b000) == 0x80);
	assert(mmrm16(0b001) == 0x80);
	assert(mmrm16(0b010) == 0x80);
	assert(mmrm16(0b011) == 0x80);
	assert(mmrm16(0b100) == 0x50);
	assert(mmrm16(0b101) == 0x50);
	assert(mmrm16(0b110) == 0x1020);
	assert(mmrm16(0b111) == 0x30);
	// MOD=01
	assert(mmrm16(0b01_000_000) == 0xA0);
	assert(mmrm16(0b01_000_001) == 0xA0);
	assert(mmrm16(0b01_000_010) == 0xA0);
	assert(mmrm16(0b01_000_011) == 0xA0);
	assert(mmrm16(0b01_000_100) == 0x70);
	assert(mmrm16(0b01_000_101) == 0x70);
	assert(mmrm16(0b01_000_110) == 0x50);
	assert(mmrm16(0b01_000_111) == 0x50);
	// MOD=10
	assert(mmrm16(0b10_000_000) == 0x10A0);
	assert(mmrm16(0b10_000_001) == 0x10A0);
	assert(mmrm16(0b10_000_010) == 0x10A0);
	assert(mmrm16(0b10_000_011) == 0x10A0);
	assert(mmrm16(0b10_000_100) == 0x1070);
	assert(mmrm16(0b10_000_101) == 0x1070);
	assert(mmrm16(0b10_000_110) == 0x1050);
	assert(mmrm16(0b10_000_111) == 0x1050);
	// MOD=11
	CPU.AX = 0x2040; CPU.CX = 0x2141;
	CPU.DX = 0x2242; CPU.BX = 0x2343;
	CPU.SP = 0x2030; CPU.BP = 0x2131;
	CPU.SI = 0x2232; CPU.DI = 0x2333;
	assert(mmrm16(0b11_000_000) == 0x40); // AL
	assert(mmrm16(0b11_000_001) == 0x41); // CL
	assert(mmrm16(0b11_000_010) == 0x42); // DL
	assert(mmrm16(0b11_000_011) == 0x43); // BL
	assert(mmrm16(0b11_000_100) == 0x20); // AH
	assert(mmrm16(0b11_000_101) == 0x21); // CH
	assert(mmrm16(0b11_000_110) == 0x22); // DH
	assert(mmrm16(0b11_000_111) == 0x23); // BH
	// MOD=11+W bit
	assert(mmrm16(0b11_000_000, 1) == 0x2040); // AX
	assert(mmrm16(0b11_000_001, 1) == 0x2141); // CX
	assert(mmrm16(0b11_000_010, 1) == 0x2242); // DX
	assert(mmrm16(0b11_000_011, 1) == 0x2343); // BX
	assert(mmrm16(0b11_000_100, 1) == 0x2030); // SP
	assert(mmrm16(0b11_000_101, 1) == 0x2131); // BP
	assert(mmrm16(0b11_000_110, 1) == 0x2232); // SI
	assert(mmrm16(0b11_000_111, 1) == 0x2333); // DI
	OK;

	test("16-bit ModR/M + SEG"); TODO;

	test("32-bit ModR/M"); TODO;
}