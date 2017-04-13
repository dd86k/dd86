module UtilitiesTests;

import Interpreter, std.stdio, dd_dos, Utilities;

unittest
{
    writeln("---------- Utilities");

    machine = new Intel8086();

    with (machine) {
        CS = IP = 0;
        Insert("Hello it's me\0");
        write("MemString(ubyte*) : ");
        assert(MemString(&memoryBank[0]) == "Hello it's me");
        writeln("OK");
        write("MemString(ubyte*, uint) : ");
        assert(MemString(&memoryBank[0], 0) == "Hello it's me");
        writeln("OK");
    }
}