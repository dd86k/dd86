/*
 * dd-dos.cpp : Defines the entry point for the console application.
 */

#include "dd-dos.hpp"
#include "Interpreter.hpp"

#include <iostream>
#include <string>
#include <vector>

void DisplayVersion()
{
	std::cout << "DD-DOS - " << version << std::endl;;
	std::cout << "Project page: <https://github.com/dd86k/dd-dos>" << std::endl;
}

void DisplayHelp(const char *program_name)
{
	std::cout << "Usage: " << std::endl;
	std::cout << "  " << program_name << " [<Options>] [<Program>]" << std::endl;
	std::cout << std::endl;
	std::cout << "  -h | --help       Display help and quit." << std::endl;
	std::cout << "  -v | --version    Display version and quit." << std::endl;
}

int main(int argc, char **argv)
{
	std::vector<std::string> args(argv, argv + argc);

	for (const std::string &arg : args) {
		if (arg == "-v" || arg == "--version") {
			DisplayVersion();
            return 0;
		} else if (arg == "-h" || arg == "--help") {
			DisplayHelp(argv[0]);
            return 0;
        }
    }

    Con = poshub();
    Con.Init();

	Intel8086 machine;
    machine.Init(NULL);

    return 0;
}
