/*
 * main.d : Entry point, CLI, internal shell.
 */

//TODO: "Dynamic memory", allocate only what's necessary.

module main;

import std.stdio;

import Interpreter, Loader;
import poshublib : POSHUB_VER;

pragma(msg, "Compiling DD-DOS Version ", APP_VERSION);

/// DD-DOS version.
enum APP_VERSION = "0.0.0";
enum {
    /// Minor reported DOS version
    DOS_MINOR_VERSION = 0,
    /// Major reported DOS version
    DOS_MAJOR_VERSION = 0
}
// CLI Error codes
enum {
    /// Generic CLI syntax error
    E_CLI = 1,
}

/// Verbose flags
static bool Verbose;

/// Current machine
static Intel8086 machine;

private void DisplayVersion()
{
	writeln("DD-DOS - v", APP_VERSION);
    writeln("Interpreter - v", INTERPRETER_VER);
    writeln("Loader - v", LOADER_VER);
    writeln("Poshub - v", POSHUB_VER);
    writeln("Copyright (c) 2017 dd86k");
    writeln("License: MIT");
	writeln("Project page: <https://github.com/dd86k/dd-dos>");
}

private void DisplayHelp(string name)
{
    writefln("%s  [-p <Program> [-a <arguments]] [-M] [-V]", name);
    writefln("%s  {-h|--help|/?|-v|--version}", name);
}

private void DisplayFullHelp(string name)
{
	writeln("Usage: ");
	writefln("  %s [<Options>]", name);
    writeln("Options:");
    writeln("  -p <Program>     Load a program at start.");
    //writeln("  -a <Arguments>   Arguments to pass to <Program>.");
    writeln("  -M               Maximum performance (!)");
    writeln("  -V               Verbose.");
    writeln();
	writeln("  -h, --help       Display help and quit.");
	writeln("  -v, --version    Display version and quit.");
}

private int main(string[] args)
{
    const size_t argl = args.length;

    string init_file, init_args;
    bool sleep = true;

	for (size_t i = 0; i < argl; ++i)
    {
        switch (args[i])
        {
            case "-p", "/p":
                if (++i < argl) {
                    init_file = args[i];
                } else {
                    writeln("-p : Missing argument.");
                    return E_CLI;
                }
                break;
            
            case "-a", "/a":
                if (++i < argl) {
                    if (init_file) {
                        init_args = args[i];
                    } else {
                        writeln("-a : Missing <Program>.");
                        return E_CLI;
                    }
                } else {

                }
                break;

            case "-M":
                sleep = false;
                break;

            case "-V", "--verbose":
                writeln("Verbose mode turned on.");
                Verbose = true;
                break;

            case "-v", "--version", "/version", "/ver":
                DisplayVersion();
                return 0;
            case "-h", "--help", "/?":
                DisplayHelp(args[0]);
                return 0;
            default: break;
        }
    }

    writeln("DD-DOS is starting...");
    machine = new Intel8086();
    machine.Sleep = sleep;

    if (init_file)
    {
        LoadFile(init_file);
        machine.Initiate();
    }
    else
    {
        EnterVShell();
    }

    return 0;
}

/// Enter internal shell
void EnterVShell()
{
    import std.array : split;
    import std.uni : toLower;
    import std.file : getcwd;

    while (true) {
        //write(getcwd ~ '$');
        write('$');

        // Read line from stdln and remove \n, then split arguments.
        string[] s = split(readln()[0..$-1], ' ');

        if (s.length > 0)
        switch (toLower(s[0]))
        {
        case "help", "?", "??":
            writeln("?run     Run the VM");
            writeln("?load    Load a file");
            writeln("?r       Print register information");
            writeln("?v       Toggle verbose mode");
            break;
        /*case "time":
            writeln("Current time is   ");
            break;*/
        /*case "date":
            writeln("Current date is   ");
            break;*/
        case "ver":
            writeln("DD-DOS Version ", APP_VERSION);
            writefln("MS-DOS Version %d.%d", DOS_MAJOR_VERSION, DOS_MINOR_VERSION);
            break;
        //case "mem":break;
        case "cls":
            machine.Con.Clear();
            break;
        case "?t0":
            Test();
            break;
        case "?load":
            if (s.length > 1) {
                if (Verbose)
                    writeln("Loader initiated");
                LoadFile(s[1]);
            }
            break;
        case "?run":
            machine.Initiate();
            break;
        case "?v":
            Verbose = !Verbose;
            writeln("Verbose turned ", Verbose ? "on" : "off");
            break;
        case "?r":
            with (machine) {
                writef(
                    "AX=%04X BX=%04X CX=%04X DX=%04X " ~
                    "SP=%04X BP=%04X SI=%04X DI=%04X\n" ~
                    "CS=%04X DS=%04X ES=%04X SS=%04X " ~
                    "IP=%04X\n",
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
                writefln("(%Xh)", GetFlagWord);
            }
            break;
        case "exit": return;
        default:
            writefln("%s: Invalid command.", s[0]);
            break;
        }
    }
}