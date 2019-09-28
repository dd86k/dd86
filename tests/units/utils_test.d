import test_utils;
import vcpu.core, vcpu.mm, vcpu.utils;
import vdos.os;
import core.stdc.string : strncmp;

unittest {
	section("Utilities");

	CPU.cpuinit;
	vdos_init;

	test("mmfstr");
	mmistr("Hello", 20);
	assert(mmfstr(0xFFFF_FFFF) == null);
	int l;
	const(char) *p = mmfstr(20, &l);
	assert(strncmp(p, "Hello", l) == 0);
	OK;

	test("bswap16");
	assert(bswap16(0xAAFF) == 0xFFAA);
	OK;

	test("bswap32");
	assert(bswap32(0xAABB_FFEE) == 0xEEFF_BBAA);
	OK;
}