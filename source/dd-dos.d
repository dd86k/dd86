/*
 * dd-dos.cpp : Defines the entry point for the console application.
 */

module dd_dos;

import std.stdio;
import std.path;
import std.file;
import Interpreter;
import Poshub;

// DD-DOS version.
enum APP_VERSION = "0.0.0";
// Reported DOS version.
enum DOS_VERSION = 0x0000; // 00.00

enum OEM_ID { // Used for INT 21h AH=30 so far.
    IBM, Compaq, MSPackagedProduct, ATnT, ZDS
};

static Intel8086 machine;
static poshub Con;

private void DisplayVersion()
{
	writeln("DD-DOS - ", APP_VERSION);
	writeln("Project page: <https://github.com/dd86k/dd-dos>");
}

private void DisplayHelp(string program_name)
{
	writeln("Usage: ");
	writefln("  %s [<Options>] [<Program>]\n", program_name);
	writeln("  -h | --help       Display help and quit.");
	writeln("  -v | --version    Display version and quit.");
}

private int main(string[] args)
{
    size_t argl = args.length;
	for (size_t i = 0; i < argl; ++i) {
        switch (args[i])
        {
            case "-v", "--version":
                DisplayVersion();
                break;
            case "-h", "--help", "/?":
                DisplayHelp(args[0]);
                break;
            default:
        }
    }

    Con = poshub();
    Con.Init();

    machine = new Intel8086();
    machine.Init();

    return 0;
}

/// <summary>
/// Load an executable in virtual memory.
/// </summary>
void Load(string filename)
{
    
}