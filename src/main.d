/*
 * main.d: Main application.
 */

//TODO: "Dynamic memory", allocate only what's necessary.

module main;

import std.stdio, std.getopt;
import dd_dos : APP_VERSION, APP_NAME, EnterVShell;
import Interpreter : Initiate, Verbose, Sleep, Run;
import Loader : LoadFile;
import Logger;
import Poshub : InitConsole;

debug { } else
{
    extern (C) __gshared bool
        rt_envvars_enabled = false, rt_cmdline_enabled = false;
}

private void DisplayVersion()
{
    import core.stdc.stdlib : exit;
	writefln("%s - v%s  (%s)", APP_NAME, APP_VERSION, __TIMESTAMP__);
    writeln("Copyright (c) 2017 dd86k, using MIT license");
	writeln("Project page: <https://github.com/dd86k/dd-dos>");
    writefln("Compiled %s using %s v%s", __FILE__, __VENDOR__, __VERSION__);
    exit(0); // getopt hack
}

private void DisplayHelp(string name = APP_NAME)
{
    writefln("  %s  [-p <Program> [-a <Arguments>]] [-M] [-V]", name);
    writefln("  %s  {-h|--help|/?|-v|--version}", name);
}

/**
 * Main entry point.
 * Params: args = CLI Arguments
 * Returns: Errorcode
 */
int main(string[] args)
{
    string init_file, init_args;
    bool smsg; // Startup message

    GetoptResult r;
	try {
		r = getopt(args,
            config.caseSensitive,
            "program|p", "Run a program at boot.", &init_file,
            config.caseSensitive,
            "args|a", "Starting program's arguments.", &init_args,
            config.bundling, config.caseSensitive,
            "perf|P", "Maximum performance(!)", &Sleep,
            config.bundling, config.caseSensitive,
            "nobootmsg|N", "No starting-up messages.", &smsg,
            config.bundling, config.caseSensitive,
			"verbose|V", "Verbose mode.", &Verbose,
            config.caseSensitive,
            "version|v", "Print version screen.", &DisplayVersion);
	} catch (GetOptException ex) {
		stderr.writeln("Error: ", ex.msg);
        return 1;
	}

    debug Verbose = !Verbose;

    if (r.helpWanted)
    {
        DisplayHelp;
        writeln("\nSwitches (Default: Off)");
        foreach (it; r.options)
        { // "custom" and nicer defaultGetoptPrinter
            writefln("%*s, %-*s%s%s",
                4,  it.optShort,
                12, it.optLong,
                it.required ? "Required: " : " ",
                it.help);
        }
        return 0;
	}

    if (Verbose) log("Verbose mode is ON");
    if (Verbose) logs("Max performance is ", Sleep ? "OFF" : "ON");

    if (!smsg) writeln("DD-DOS is starting...");

    InitConsole();
    Initiate();

    if (init_file)
    {
        LoadFile(init_file, init_args);
        Run();
    }
    else
    {
        EnterVShell();
    }

    return 0;
}