module UtilitiesTests;

import Interpreter : MEMORY;
import std.stdio, vdos, Utilities;
import core.stdc.string : memcpy;

unittest
{
    writeln("\n----- Utilities");

    const uint pos = 10;
    char* s = cast(char*)"Hello\0";
    memcpy(cast(void*)MEMORY + pos, s, 6);

    write("MemString(uint) : ");
    assert(MemString(pos) == "Hello");
    writeln("OK");
}