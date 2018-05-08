/*
 * main.d: CLI entry point
 */

import core.stdc.stdio;
import core.stdc.stdlib : exit;
import core.stdc.string : strcmp;
import vdos : APP_VERSION, BANNER, EnterShell;
import vcpu : init, Verbose, cpu_sleep, run;
import Loader : ExecLoad;
import Logger;
import ddcon : InitConsole;
import OSUtilities : pexist;

extern (C)
private void _version() {
	printf(
		"dd-dos v" ~ APP_VERSION ~ "  (" ~ __TIMESTAMP__ ~ ")" ~
		"Copyright (c) 2017-2018 dd86k, using MIT license" ~
		"Project page: <https://github.com/dd86k/dd-dos>" ~
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
  dd-dos [-VPN] [FILE [FILEARGS]]
  dd-dos {-v|--version|-h|--help}

OPTIONS
  -P       Do not sleep between cycles
  -N       Remove starting messages and banner
  -V       Toggle verbose mode for session
  -v, --version    Print version screen, then exit
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
			if ((*argv) + 1 == '-') { // long arguments
				char* a = (*argv) + 2;
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

	if (Verbose) {
		debug log("-- DEBUG BUILD");
		else  log("-- VERBOSE MODE ON");
		if (!CpuSleep)
			log("-- SLEEP MODE OFF");
	}

	if (arg_banner)
		puts("DD-DOS is starting...");

	// Initiating

	InitConsole; // ddcon
	init; // dd-dos

	if (arg_banner)
		puts(BANNER); // Defined in vdos.d

	// DD-DOS

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