module test;

import Interpreter;

unittest
{
    Intel8086 machine = new Intel8086();

    with (machine)
    {
        // Registers
        Insert(0xDD, 1);
        Execute(0xA0);
        assert(AL == 0xDD);
    }
}