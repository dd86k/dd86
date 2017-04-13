module UtilitiesTests;

import Interpreter, std.stdio, dd_dos, Utilities;

unittest
{
    writeln("---------- Utilities");

    const uint pos = 10;
    char[] c = new char[50];
    const char[] s = "Hello it's me\0";
    char* p = &c[pos];
    for (int i; i < s.length; ++i, ++p) *p = s[i];

    write("MemString(ubyte*, uint) : ");
    assert(MemString(&c[0], pos) == "Hello it's me");
    writeln("OK");
}