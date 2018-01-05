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
	extern (C) __gshared bool // Defaults to false (.init)!
		rt_envvars_enabled, /// Disable runtime environment variables
		rt_cmdline_enabled; /// Disable runtime command-line (--DRT-gcopt)
}

extern (C)
private void DisplayVersion() {
	printf(
`dd-dos v%s  (%s)
Copyright (c) 2017 dd86k, using MIT license
Project page: <https://github.com/dd86k/dd-dos>
Compiler: %s v%d
`,
	 cast(char*)APP_VERSION, cast(char*)__TIMESTAMP__,
	 cast(char*)__VENDOR__, __VERSION__
	);
	exit(0); // getopt hack ;-)
}

extern (C)
private void DisplayHelp() {
	puts(
`A DOS virtual machine.");
Usage:");
  dd-dos [OPTIONS]`
	);
}

private
int main(string[] args) {
	string init_file, init_args;
	bool smsg; // Startup message

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
			"v|version", "Print version screen and exit", &DisplayVersion);
	} catch (GetOptException ex) {
		//stderr.writeln("Error: ", ex.msg);
		printf("ERROR: %s\n", cast(char*)ex.msg);
		return 1;
	}

	if (r.helpWanted) {
		DisplayHelp;
		puts("\nOPTIONS");
		foreach (it; r.options) {
			// "custom" and nicer defaultGetoptPrinter
			printf("%*s, %*s %s\n",
				4,  cast(char*)it.optShort,
				-12, cast(char*)it.optLong,
				cast(char*)it.help);
		}
		return 0;
	}

	// The "blame getopt for only doing off->on switches" section
	//TODO: Find a better getopt alternative, or make our own
	Sleep = !Sleep;
	debug Verbose = !Verbose;

	if (Verbose) {
		debug log("Debug mode is ON");
		else log("Verbose mode is ON");
		if (!Sleep)
			log("Maximum performance is ACTIVE");
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
			puts("ERROR: File not found");
		}
	} else {
		EnterShell;
	}

	return 0;
}