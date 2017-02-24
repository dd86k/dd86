module test;

import Interpreter;

unittest
{
    Intel8086 machine = new Intel8086();

    with (machine)
    {
        CS = 0;

        // MOV
        Insert(0xAB, 1);
        Execute(0xA0); // MOV AL, ABh
        assert(AL == 0xAB);

        Insert(0xABCD, 1); // [ 0xCD, 0xAB ]
        Execute(0xA1); // MOV AX, ABCDh
        assert(AX == 0xABCD);

        assert(false);
    }
}