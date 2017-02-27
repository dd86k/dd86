/*
 * main.d : Entry point, CLI, internal shell.
 */

//TODO: "Dynamic memory", allocate only what's necessary.

module main;

import std.stdio;

import dd_dos, Interpreter, Loader;

// CLI Error codes
enum {
    /// Generic CLI syntax error
    E_CLI = 1,
}

debug
{ // --DRT-
    extern(C) __gshared string[] rt_options = [ "gcopt=profile:1" ];
}
else
{
    extern (C) __gshared bool rt_cmdline_enabled = false;
    extern (C) __gshared bool rt_envvars_enabled = false;
}

private void DisplayVersion()
{
	writeln(APP_NAME, " - v", APP_VERSION);
    writeln("Copyright (c) 2017 dd86k, using MIT license");
	writeln("Project page: <https://github.com/dd86k/dd-dos>");
    writeln("Compiled ", __FILE__, " (", __TIMESTAMP__, ") using ",
        __VENDOR__," v", __VERSION__);
}

private void DisplayHelp(string name = APP_NAME)
{
    writeln(name, "  [-p <Program> [-a <Arguments>]] [-M] [-V]");
    writeln(name, "  {-h|--help|/?|-v|--version}");
}

private void DisplayFullHelp(string name = APP_NAME)
{
	writeln("Usage:");
	writeln("  ", name, " [<Options>]");
    writeln("Options:");
    writeln("  -p <Program>     Load a program at start.");
    writeln("  -a <Arguments>   Arguments to pass to <Program>.");
    writeln("  -M               Maximum performance (!)");
    writeln("  -V               Verbose mode.");
    writeln();
	writeln("  -h, --help       Display help and quit.");
	writeln("  -v, --version    Display version and quit.");
}

/// Main entry point.
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
                    writeln("-a : Missing argument.");
                    return E_CLI;
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
            case "-h", "/?":
                DisplayHelp(args[0]);
                return 0;
            case "--help":
                DisplayFullHelp(args[0]);
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

    return LastErrorCode;
}