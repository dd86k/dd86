/*
 * main.d: CLI entry point
 */

import core.stdc.stdio;
import core.stdc.stdlib : exit;
import core.stdc.string : strcmp;
import vdos : APP_VERSION, BANNER, EnterShell;
import vcpu : init, cpu_sleep, run;
import Loader : ExecLoad;
import Logger;
import ddcon : InitConsole;
import utils_os : pexist;

extern (C)
private void _version() {
	printf(
		"Copyright (c) 2017-2018 dd86k, MIT license\n" ~
		"Project page: <https://github.com/dd86k/dd-dos>\n\n" ~
		"dd-dos " ~ APP_VERSION ~ "  (" ~ __TIMESTAMP__ ~ ")\n" ~
		"Compiler: " ~ __VENDOR__ ~ " v%d\n\n" ~
		`Credits
dd86k -- Original author and developer
`,
		__VERSION__
	);
	exit(0);
}

extern (C)
void help() {
	puts(
`A DOS virtual machine
USAGE
  dd-dos [-vPN] [FILE [FILEARGS]]
  dd-dos {-V|--version|-h|--help}

OPTIONS
  -P       Do not sleep between cycles
  -N       Remove starting messages and banner
  -v       Increase verbosity level
  -V, --version    Print version screen, then exit
  -h, --help       Print help screen, then exit`
	);
	exit(0);
}

extern (C)
private int main(int argc, char** argv) {
	__gshared byte args = 1;
	__gshared byte arg_banner = 1;
	__gshared char* prog; /// FILE, COM or EXE to start
//	__gshared char* args; /// FILEARGS, MUST not be over 127 characters
//	__gshared size_t arg_i; /// Argument length incrementor

	// CLI

	while (--argc >= 1) {
		++argv;
		if (args) {
			if (*(*argv + 1) == '-') { // long arguments
				char* a = *(argv) + 2;
				if (strcmp(a, "help") == 0)
					help;
				if (strcmp(a, "version") == 0)
					_version;

				printf("Unknown parameter: --%s\n", a);
				return 1;
			} else if (**argv == '-') { // short arguments
				char* a = *argv;
				while (*++a) {
					switch (*a) {
					case 'P': --cpu_sleep; break;
					case 'N': --arg_banner; break;
					case 'v': ++Verbose; break;
					case '-': --args; break;
					case 'h': help; break;
					case 'V': _version; break;
					default:
						printf("Invalid parameter: -%c\n", *a);
						exit(1);
					}
				}
				continue;
			}
		}

		if (cast(int)prog == 0)
			prog = *argv;
		//TODO: Else, append program arguments (strcmp)
		//      Don't forget to null it after while loop, keep arg_i updated
	}

	// Pre-boot

	switch (Verbose) {
	case L_SILENCE, L_CRIT, L_ERROR: break;
	case L_WARN: info("-- Log level: L_WARN"); break;
	case L_INFO: info("-- Log level: L_INFO"); break;
	case L_DEBUG: info("-- Log level: L_DEBUG"); break;
	default:
		printf("E: Unknown log level: %d\n", Verbose);
		return 1;
	}

	if (!cpu_sleep)
		info("-- SLEEP MODE OFF");

	if (arg_banner)
		puts("DD-DOS is starting...");

	// Initiating

	InitConsole; // ddcon
	init; // dd-dos

	// DD-DOS

	if (arg_banner)
		puts(BANNER); // Defined in vdos.d

	if (cast(int)prog) {
		if (pexist(prog)) {
			if (ExecLoad(prog)) {
				puts("E: Could not load executable");
				return 3;
			}
			run;
		} else {
			puts("E: File not found or loaded");
			return 2;
		}
	} else EnterShell;

	return 0;
}