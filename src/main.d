/*
 * main.d : Main application.
 */

//TODO: "Dynamic memory", allocate only what's necessary.

module main;

import std.stdio;
import std.getopt;
import dd_dos, Interpreter, Loader, Poshub;

debug { } else
{
    extern (C) __gshared bool
        rt_envvars_enabled = false, rt_cmdline_enabled = false;
}

/// Display version.
void DisplayVersion()
{
    import core.stdc.stdlib : exit;
	writefln("%s - v%s (%s)", APP_NAME, APP_VERSION, __TIMESTAMP__);
    writeln("Copyright (c) 2017 dd86k, MIT license");
	writeln("Project page: <https://github.com/dd86k/dd-dos>");
    writefln("Compiled %s using %s v%s", __FILE__, __VENDOR__, __VERSION__);
    exit(0);
}

/// Display short help.
void DisplayHelp(string name = APP_NAME)
{
    writefln("  %s  [-p <Program> [-a <Arguments>]] [-M] [-V]", name);
    writefln("  %s  {-h|--help|/?|-v|--version}", name);
}

/// Main entry point.
int main(string[] args)
{
    string init_file, init_args;
    bool maxperf,
         verbose,
         smsg; // Startup message

    GetoptResult r;
	try {
		r = getopt(args,
            config.caseSensitive,
            "program|p", "Run a program at boot.", &init_file,
            config.caseSensitive,
            "args|a", "Starting program's arguments.", &init_args,
            config.bundling, config.caseSensitive,
            "perf|P", "Maximum performance(!)", &maxperf,
            config.bundling, config.caseSensitive,
            "nobootmsg|N", "No starting-up messages.", &smsg,
            config.bundling, config.caseSensitive,
			"verbose|V", "Verbose mode.", &verbose,
            config.caseSensitive,
            "version|v", "Print version screen.", &DisplayVersion);
	} catch (GetOptException ex) {
		stderr.writeln(ex.msg);
        return 1;
	}

    if (r.helpWanted)
    {
        DisplayHelp;
        writeln("\nSwitches");
        foreach (it; r.options)
        { // "custom" defaultGetoptPrinter
            writefln("%*s, %-*s%s%s",
                4,  it.optShort,
                12, it.optLong,
                it.required ? "Required: " : " ",
                it.help);
        }
        return 0;
	}

    debug verbose = true;

    if (!smsg) writeln("DD-DOS is starting...");
    if (verbose) writeln("[VMMI] Verbose mode.");
    if (verbose) writeln("[VMMI] Max perf: ", maxperf);
    InitConsole();
    machine = new Intel8086();
    machine.Sleep = !maxperf;
    machine.Verbose = verbose;

    if (init_file)
    {
        LoadFile(init_file, init_args ? init_args : null, verbose);
        machine.Initiate();
    }
    else
    {
        EnterVShell(verbose);
    }

    return LastErrorCode;
}