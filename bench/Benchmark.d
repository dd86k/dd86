module Benchmarks;

import Interpreter, std.stdio, dd_dos, Utilities;
import std.datetime : StopWatch;
import core.time : Duration;
import std.conv : to;

unittest
{
    writeln("---------- Benchmarks");

    const uint pos = 10;
    char[] c = new char[50];
    const char[] s = "Hello it's me\0";
    char* p = &c[pos];
    for (int i; i < s.length; ++i, ++p) *p = s[i];

    StopWatch sw;

    write("MemString(ubyte*, uint) 1'000'000x : ");
    sw.start();
    for (int i; i < 2_000_000; ++i) MemString(&c[0], pos);
    sw.stop();
    writeln(to!Duration(sw.peek));
}