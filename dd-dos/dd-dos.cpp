// dd-dos.cpp : Defines the entry point for the console application.
//

#include "dd-dos.hpp"
#include "stdio.h"
#include "poshub.cpp"

static poshub Con;

int main()
{
    Con = poshub();
    Con.Init();

    return 0;
}
