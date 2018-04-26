module UtilitiesTests;

import Utilities, InterpreterUtils;
import unitutils;

unittest
{
    section("Utilities");

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
    test("bswap64");
    assert(
        bswap64(0xAABBCCDD_11223344) ==
        0x44332211_DDCCBBAA
    );
    OK;
}