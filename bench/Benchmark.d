module Benchmarks;

import Interpreter, std.stdio, dd_dos, Utilities;
import std.datetime : StopWatch;
import core.time : Duration;
import std.conv : to;

unittest
{
    writeln("---------- Benchmarks");

    machine = new Intel8086();

    with (machine) {
        auto sw = StopWatch();
        CS = IP = 0;
        Insert("Hello it's me\0");

        write("MemString(ubyte*) : ");
        sw.start();
        writeln(to!Duration(sw.peek));
        sw.stop();

        sw.reset();

        sw.start();
        write("MemString(ubyte*, uint) : ");
        sw.stop();
        writeln(to!Duration(sw.peek));
    }
}