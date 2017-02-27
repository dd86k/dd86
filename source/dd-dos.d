module dd_dos;

import Interpreter, std.stdio, Loader;

pragma(msg, "Compiling DD-DOS v", APP_VERSION, "...");
pragma(msg, "Reporting DOS v", DOS_MAJOR_VERSION, ".", DOS_MINOR_VERSION);

/// DD-DOS version.
enum {
    APP_VERSION = "0.0.0",
    APP_NAME = "dd-dos"
}

enum {
    /// Minor reported DOS version
    DOS_MINOR_VERSION = 0,
    /// Major reported DOS version
    DOS_MAJOR_VERSION = 0
}

/// Verbose flags
static bool Verbose;

/// 
static ubyte LastErrorCode;

/// Current machine
static Intel8086 machine;

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
        case "help":
            writeln("CLS            Clear screen.");
            writeln("MEM            Show memory information.");
            writeln("VER            Show DOS version.");
            break;
        case "ver":
            writeln("DD-DOS Version ", APP_VERSION);
            writefln("MS-DOS Version %d.%d", DOS_MAJOR_VERSION, DOS_MINOR_VERSION);
            break;
        case "mem":
            writeln("Not implemented.");
            break;
        case "cls":
            machine.Con.Clear();
            break;
        case "??":
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
                writefln("(%Xh)", FLAG);
            }
            break;
        case "exit": return;
        default:
            writefln("%s: Invalid command.", s[0]);
            break;
        }
    }
}

void GeneratePSP()
{

}