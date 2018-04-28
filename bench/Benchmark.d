module Benchmarks;

import vcpu, std.stdio, vdos, Utilities;
import std.datetime.stopwatch : StopWatch;
import core.time : Duration;
import std.conv : to;
import core.stdc.string : memcpy;

unittest
{
    writeln("----- Benchmarks");

    const uint pos = 10;
    char[50] c;
    char* s = cast(char*)"Hello it's me\0";
    memcpy(cast(void*)&c + pos, s, s.sizeof);

    StopWatch sw;

    write("MemString(ubyte*, uint) 10'000'000x : ");
    sw.start();
    for (int i; i < 10_000_000; ++i) MemString(cast(void*)c, pos);
    sw.stop();
    writeln(to!Duration(sw.peek));

    //sw.reset;
}