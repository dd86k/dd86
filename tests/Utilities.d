module UtilitiesTests;

import Interpreter, std.stdio, dd_dos, Utilities;

unittest
{
    writeln("---------- Utilities");

    const uint pos = 10;
    ubyte[] c = new ubyte[50];
    const char[] s = "Hello it's me";
    ubyte* p = &c[pos];
    for (int i; i < s.length; ++i, ++p) *p = s[i];

    write("MemString(ubyte*, uint) : ");
    assert(MemString(cast(void*)c, pos) == "Hello it's me");
    writeln("OK");
}