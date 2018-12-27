/*
 * main.d: CLI entry point
 */

import core.stdc.string : strcmp;
import ddc : puts, printf, fputs, stderr, stdout;
import vcpu;
import vdos : BANNER, vdos_shell, vdos_init;
import vdos_codes;
import vdos_loader : vdos_load;
import vdos_screen;
import Logger;
import ddcon : con_init, Clear;
import os_utils : os_pexist;
import sleep : sleep_init;
import compile_config : APP_VERSION, PLATFORM, BUILD_TYPE;

extern (C):

enum DESC = "IBM PC Virtual Machine and DOS Emulation Layer";

private void _version() {
	printf(
		BANNER~
		DESC~"\n"~
		"Copyright (c) 2017-2018 dd86k\n\n"~
		"dd-dos-"~PLATFORM~" v"~APP_VERSION~"-"~BUILD_TYPE~" ("~__TIMESTAMP__~")\n"~
		"Homepage: <https://git.dd86k.space/dd86k/dd-dos>\n"~
		"License: MIT <https://opensource.org/licenses/MIT>\n"~
		"Compiler: "~__VENDOR__~" v%d\n",
		__VERSION__
	);
}

private void help() {
	puts(
		DESC~"\n"~
		"USAGE\n"~
		"	dd-dos [-vPN] [FILE [FILEARGS]]\n"~
		"	dd-dos {-V|--version|-h|--help}\n\n"~
		"OPTIONS\n"~
		"	-P	Do not sleep between cycles\n"~
		"	-N	Remove starting messages and banner\n"~
		"	-v	Increase verbosity level\n"~
		"	-V, --version  Print version screen, then exit\n"~
		"	-h, --help     Print help screen, then exit",
	);
}

private int main(int argc, char **argv) {
	ubyte args = 1;
	ubyte arg_banner = 1;
	char *prog; /// FILE, COM or EXE to start
//	char *args; /// FILEARGS, MUST not be over 127 characters
//	size_t arg_i; /// Argument length incrementor

	// Pre-boot / CLI

	while (--argc >= 1) {
		++argv;

		if (args == 0) goto NO_ARGS;

		if (*(*argv + 1) == '-') { // long arguments
			char* a = *(argv) + 2;
			if (strcmp(a, "help") == 0) {
				help;
				return 0;
			}
			if (strcmp(a, "version") == 0) {
				_version;
				return 0;
			}

			printf("Unknown parameter: --%s\n", a);
			return EDOS_INVALID_FUNCTION;
		} else if (**argv == '-') { // short arguments
			char* a = *argv;
			while (*++a) {
				switch (*a) {
				case 'P': --opt_sleep; break;
				case 'N': --arg_banner; break;
				case 'v': ++LOGLEVEL; break;
				case '-': --args; break;
				case 'h': help; return 0;
				case 'V': _version; return 0;
				default:
					printf("Unknown parameter: -%c\n", *a);
					return EDOS_INVALID_FUNCTION;
				}
			}
			continue;
		}
NO_ARGS:

		if (cast(int)prog == 0)
			prog = *argv;
		//TODO: Else, append program arguments (strcmp)
		//      Don't forget to null it after while loop and keep arg_i updated
	}

	if (cast(int)prog) {
		if (os_pexist(prog) == 0) {
			//fputs("E: File not found\n", stderr);
			puts("E: File not found");
			return EDOS_FILE_NOT_FOUND;
		}
	}

	// Welcome. Welcome to DD-DOS

	//sleep_init;	// sleep timers
	vcpu_init;	// vcpu

	if (cast(int)prog) {
		if (vdos_load(prog)) {
			//fputs("E: Could not load executable image\n", stderr);
			puts("E: Could not load executable image");
			return PANIC_FILE_NOT_LOADED;
		}
	}

	if (LOGLEVEL > LOG_DEBUG) {
		printf("E: Unknown log level: %d\n", LOGLEVEL);
		return EDOS_INVALID_FUNCTION;
	}

	con_init;	// ddcon
	vdos_init;	// vdos, screen

	switch (LOGLEVEL) {
	case LOG_CRIT: log_info("I: LOG_CRIT"); break;
	case LOG_ERROR: log_info("I: LOG_ERROR"); break;
	case LOG_WARN: log_info("I: LOG_WARN"); break;
	case LOG_INFO: log_info("I: LOG_INFO"); break;
	case LOG_DEBUG: log_info("I: LOG_DEBUG"); break;
	default:
	}

	if (opt_sleep == 0)
		v_putn("I: MAX_PERF");

	v_putn("DD-DOS is starting...");

	// Should be loading settings here

	if (arg_banner)
		screen_logo;

	screen_draw;

	if (cast(int)prog) {
		vdos_load(prog);
		vcpu_run;
	} else vdos_shell;

	return 0;
}