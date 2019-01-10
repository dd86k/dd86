import test_utils;
import vcpu.core, vcpu.mm, vcpu.utils;
import vdos.os;

unittest {
	section("Utilities");

	vcpu_init;
	vdos_init;

	test("MemString");
	__istr("Hello", 10);
	assert(MemString(10) == "Hello");
	OK;

	test("bswap16");
	assert(bswap16(0xAAFF) == 0xFFAA);
	OK;

	test("bswap32");
	assert(bswap32(0xAABB_FFEE) == 0xEEFF_BBAA);
	OK;
}