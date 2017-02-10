/*
 * main.d : Defines the entry point for the console application.
 */

module main;

import std.stdio;
import std.path;
import std.file;

import Interpreter;
import poshublib;

// DD-DOS version.
enum APP_VERSION = "0.0.0";
// Reported DOS version.
enum DOS_VERSION = 0x00_00; // 00.00
// CLI Error codes
enum {
    E_INVCLI = 1,
}

pragma(msg, "Compiling DD-DOS Version ", APP_VERSION);
pragma(msg, "Reporting DOS major version: ", DOS_VERSION >> 8);
pragma(msg, "Reporting DOS minor version: ", DOS_VERSION & 0xFF);

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
    string init_file;
	for (size_t i = 0; i < argl; ++i) {
        switch (args[i])
        {
            case "-v", "--version":
                DisplayVersion();
                break;
            case "-h", "--help", "/?":
                DisplayHelp(args[0]);
                break;

            case "-p", "/p":
                if (++i < argl) {
                    init_file = args[i];
                } else {
                    writeln("-p : Missing argument.");
                    return E_INVCLI;
                }
                break;

            default:
        }
    }

    Con = poshub();
    Con.Init();

    machine = new Intel8086();
    if (init_file != null) {
        Load(init_file);
    } else {
        import std.array;
        while (true) {
            write('$');
            // Read line from stdln and remove endl, then split arguments.
            string[] s = split(readln()[0..$-1], ' ');

            if (s.length > 0)
                switch (s[0])
                {
                    case "load":
                        if (s.length > 1)
                            Load(s[1]);
                        break;
                    case "run":
                        machine.Init();
                        break;
                    case "?r":
                        with (machine) {
                            writef(
                                "AX=%04X BX=%04X CX=%04X DX=%04X " ~
                                "SP=%04X BP=%04X SI=%04X DI=%04X\n" ~
                                "CS=%04X DS=%04X ES=%04X SS=%04X " ~
                                "IP=%04X\n\n",
                                AX, BX, CX, DX, SP, BP, SI, DI,
                                CS, DS, ES, SS, IP
                            );
                            write("FLAG: ");
                            if (OF) write("OF ");
                            if (DF) write("DF ");
                            if (IF) write("IF ");
                            if (TF) write("TF ");
                            if (SF) write("SF ");
                            if (ZF) write("ZF ");
                            if (AF) write("AF ");
                            if (PF) write("PF ");
                            if (CF) write("CF ");
                            writeln();
                        }
                        break;
                    default:
                        writefln("%s: Invalid command.", s[0]);
                        break;
                }
        }
    }
    machine.Init();

    return 0;
}

/// Load a file in virtual memory.
void Load(string filename)
{
    import std.string;
    import core.stdc.string;

    if (exists(filename))
    {
        File f = File(filename);

        if (f.size <= 0xFFFF_FFFFL)
            switch (capitalize(extension(f.name)))
            {
                case ".COM": {
                    write("Loading COM... ");
                    uint s = cast(uint)f.size;
                    ubyte[] buf = f.rawRead(new ubyte[s]);
                    // Temporary, but will be the first thing to run.
                    ubyte[]* offset = &machine.memoryBank + 0xFFFF0;
                    memcpy(offset, &buf, s);
                    writeln("loaded");
                }
                    break;
                default: // null is included here.
            }
        else writeln("File too big.");
    }
    else
    {
        writefln("File %s does not exist, skipping.", filename);
    }
}