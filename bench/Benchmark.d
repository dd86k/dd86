module Benchmarks;

import vcpu, vcpu_utils, std.stdio, vdos, utils;
import std.datetime.stopwatch : StopWatch;
import core.time, std.conv;
import core.stdc.string : memcpy;

import test_utils;

unittest
{
    section("Benchmark");

    sub("String utilities");

    __istr("Hello! This is a test! I love pie.", 10);

    StopWatch sw;

    test("MemString (10'000'000x)");
    sw.start();
    for (int i; i < 10_000_000; ++i) MemString(10);
    sw.stop();
    writefln("%s ms", to!Duration(sw.peek).total!"msecs");

    writeln;
    //sw.reset;
}