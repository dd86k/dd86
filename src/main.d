/*
 * main.d: CLI entry point
 */

import core.stdc.stdio;
import core.stdc.stdlib : exit;
import core.stdc.string : strcmp;
import dd_dos : APP_VERSION, BANNER, EnterShell;
import Interpreter : Initiate, Verbose, Sleep, Run;
import Loader : ExecLoad;
import Logger;
import ddcon : InitConsole;
import OSUtilities : pexist;

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
	exit(0);
}

extern (C)
void help() {
	puts(
`A DOS virtual machine.
Usage:
  dd-dos [OPTIONS] [EXEC [EXECARGS]]

OPTIONS
  -P, --perf       Do not sleep between cycles (fast!)
  -N, --nobanner   Removes starting message and banner
  -V, --verbose    Set verbose mode
  -v, --version    Print version screen and exit
  -h, --help       This help information.`
	);
	exit(0);
}

extern (C)
void sarg(char* a) {
	while (*++a) {
		switch (*a) {
		case 'P': --Sleep; break;
		case 'N': --banner; break;
		case 'V': ++Verbose; break;
		case '-': --args; break;
		case 'h': help; break;
		case 'v': _version; break;
		default:
			printf("Invalid parameter: -%c\n", *a);
			exit(1);
		}
	}
}

extern (C)
void larg(char* a) {
	if (strcmp(a, "help") == 0)
		help;
	if (strcmp(a, "version") == 0)
		_version;

	printf("Unknown parameter: --%s\n", a);
	exit(1);
}

private __gshared byte args = 1;
private __gshared byte banner = 1;

extern (C)
private int main(int argc, char** argv) {
	__gshared char* prog; // Possible program to start

	while (--argc >= 1) {
		++argv;
		if (args) {
			if ((*argv)[1] == '-') { // long arguments
				larg(*argv + 2); continue;
			} else if ((*argv)[0] == '-') { // short arguments
				sarg(*argv); continue;
			}
		}

		if (cast(int)prog == 0) prog = *argv;
	}

	if (banner)
		puts("DD-DOS is starting...");

	if (Verbose) {
		debug
			log("Debug mode: ON");
		else
			log("Verbose mode: ON");
		if (!Sleep)
			log("Maximum performance: ON");
	}

	InitConsole;
	Initiate;

	if (banner)
		puts(BANNER); // Defined in dd_dos.d
	
	if (cast(int)prog) {
		if (pexist(prog)) {
			if (ExecLoad(prog)) {
				puts("E: Could not load executable");
				return 1;
			}
			Run;
		} else {
			puts("E: File not found or loaded");
			return 1;
		}
	} else EnterShell;

	return 0;
}