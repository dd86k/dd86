/*
 * main.d: Main application.
 */

//TODO: "Dynamic memory", allocate only what's necessary.
//TODO: -c "command" -- Executes a command on launch (ScriptHost.d)

module main;

import core.stdc.stdio;
import std.getopt;
import dd_dos : APP_VERSION, APP_NAME, EnterVShell;
import Interpreter : Initiate, Verbose, Sleep, Run;
import Loader : LoadFile;
import Logger;
import ddcon : InitConsole;

debug { } else
{
    extern (C) __gshared bool
        rt_envvars_enabled,
		rt_cmdline_enabled;
}

extern(C)
private void DisplayVersion()
{
    import core.stdc.stdlib : exit;
	printf("%s v%s  (%s)\n",
        cast(char*)APP_NAME, cast(char*)APP_VERSION, cast(char*)__TIMESTAMP__);
    puts("Copyright (c) 2017 dd86k, using MIT license");
	puts("Project page: <https://github.com/dd86k/dd-dos>");
    printf("Compiled %s using %s v%d\n",
        cast(char*)__FILE__, cast(char*)__VENDOR__, __VERSION__);
    exit(0); // getopt hack
}

private void DisplayHelp(string name = APP_NAME)
{
    puts("A mini DOS virtual machine.");
    puts("Usage:");
    puts("  dd-dos  [OPTIONS]");
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
            "p|program", "Run a program at boot.", &init_file,
            config.caseSensitive,
            "a|args", "Starting program's arguments.", &init_args,
            config.bundling, config.caseSensitive,
            "P|perf", "Maximum performance(!)", &Sleep,
            config.bundling, config.caseSensitive,
            "N|nobootmsg", "No starting-up messages.", &smsg,
            config.bundling, config.caseSensitive,
			"V|verbose", "Verbose mode.", &Verbose,
            config.caseSensitive,
            "v|version", "Print version screen.", &DisplayVersion);
	} catch (GetOptException ex) {
		//stderr.writeln("Error: ", ex.msg);
        printf("ERROR: %s\n", cast(char*)ex.msg);
        return 1;
	}

    debug Verbose = !Verbose;

    if (r.helpWanted)
    {
        DisplayHelp;
        puts("\nSwitches (Default: Off)");
        foreach (it; r.options)
        { // "custom" and nicer defaultGetoptPrinter
            printf("%*s, %-*s%s%s\n",
                4,  cast(char*)it.optShort,
                12, cast(char*)it.optLong,
                it.required ? "Required: " : cast(char*)" ",
                cast(char*)it.help);
        }
        return 0;
	}

    if (Verbose)
        log("Verbose mode is ON");
    if (Verbose)
        logs("Max performance is ", Sleep ? "OFF" : "ON");

    if (!smsg)
		puts("DD-DOS is starting...");

    InitConsole;
    Initiate; // dd-dos

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