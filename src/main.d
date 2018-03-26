/*
 * main.d: CLI entry point
 */

import core.stdc.stdio;
import core.stdc.stdlib : exit;
import std.getopt;
import dd_dos : APP_VERSION, BANNER, EnterShell;
import Interpreter : Initiate, Verbose, Sleep, Run;
import Loader : ExecLoad;
import Logger;
import ddcon : InitConsole;
import std.file : exists;

debug {} else {
	extern (C) __gshared bool
		rt_envvars_enabled, /// Disable runtime environment variables
		rt_cmdline_enabled; /// Disable runtime command-line (--DRT-gcopt)
}

extern (C)
private void _version() {
	printf(
`dd-dos v` ~ APP_VERSION ~ `  (` ~ __TIMESTAMP__ ~ `)
Copyright (c) 2017-2018 dd86k, using MIT license
Project page: <https://github.com/dd86k/dd-dos>
Compiler: ` ~ __VENDOR__ ~ " v%d\n", __VERSION__
	);
	exit(0); // getopt hack ;-)
}

version (D_BetterC)
private int main(int argc, char** argv) {
	// Reversed for future use ;-)
} else
private int main(string[] args) {
	__gshared string init_file, init_args;
	__gshared bool smsg; // Startup message

	//TODO: Find a better getopt alternative, or make our own.
	//      Unfortunately, getopt can ONLY does off-to-on switches.
	GetoptResult r;
	try {
		r = getopt(args,
			config.caseSensitive,
			"p|program", "Run a program directly", &init_file,
			config.caseSensitive,
			"a|args", "Add arguments to -p", &init_args,
			config.bundling, config.caseSensitive,
			"P|perf", "Do not sleep between cycles (!)", &Sleep,
			config.bundling, config.caseSensitive,
			"N|nobanner", "Removes starting message and banner", &smsg,
			config.bundling, config.caseSensitive,
			"V|verbose", "Set verbose mode", &Verbose,
			config.caseSensitive,
			"v|version", "Print version screen and exit", &_version);
	} catch (GetOptException ex) {
		fprintf(stderr, "E: %s\n", cast(char*)ex.msg);
		return 1;
	}

	if (r.helpWanted) {
		puts(
`A DOS virtual machine.
Usage:
  dd-dos [OPTIONS]

OPTIONS
  -p, --program    Run a program directly
  -a, --args       Add arguments to -p
  -P, --perf       Do not sleep between cycles (fast!)
  -N, --nobanner   Removes starting message and banner
  -V, --verbose    Set verbose mode
  -v, --version    Print version screen and exit
  -h, --help       This help information.`
		);
		return 0;
	}

	Sleep = !Sleep;
	debug Verbose = !Verbose;

	if (Verbose) {
		debug log("Debug mode: ON");
		else log("Verbose mode: ON");
		if (!Sleep)
			log("Maximum performance: ON");
	}

	if (!smsg)
		puts("DD-DOS is starting...");

	InitConsole; // Initiates console screen (ddcon)
	Initiate; // Initiates vcpu

	if (!smsg)
		puts(BANNER); // Defined in dd_dos.d

	if (init_file) {
		if (exists(init_file)) {
			if (ExecLoad(init_file, init_args))
				Run;
		} else {
			puts("E: File not found or could not be loaded");
		}
	} else {
		EnterShell;
	}

	return 0;
}