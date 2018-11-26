/*
 * main.d: CLI entry point
 */

import core.stdc.stdio : printf, puts;
import core.stdc.string : strcmp, memcpy;
import ddc : fputs, stderr;
import vcpu;
import vdos : BANNER, vdos_shell, vdos_init;
import vdos_codes;
import vdos_loader : vdos_load;
import vdos_screen;
import Logger;
import ddcon : con_init, Clear;
import os_utils : os_pexist;
import sleep : sleep_init;
import compile_config : APP_VERSION, PLATFORM;

extern (C)
private void _version() {
	printf(
		BANNER ~
		"\ndd-dos-"~PLATFORM~" v"~APP_VERSION~" ("~__TIMESTAMP__~")\n"~
		"Copyright (c) 2017-2018 dd86k\n"~
		"Project page: <https://git.dd86k.space/dd86k/dd-dos>\n"~
		"License: <https://opensource.org/licenses/MIT>\n"~
		"Compiler: "~__VENDOR__~" v%d\n\n"~
		// Credit roles start at 40 characters
		`Credits
dd86k ................................. Original author

`,
		__VERSION__
	);
}

extern (C)
private void help() {
	puts(
`IBM PC Virtual Machine and DOS Emulation Layer
USAGE
	dd-dos [-vPN] [FILE [FILEARGS]]
	dd-dos {-V|--version|-h|--help}

OPTIONS
	-P	Do not sleep between cycles
	-N	Remove starting messages and banner
	-v	Increase verbosity level
	-V, --version  Print version screen, then exit
	-h, --help     Print help screen, then exit
`
	);
}

extern (C)
private int main(int argc, char** argv) {
	ubyte args = 1;
	ubyte arg_banner = 1;
	char* prog; /// FILE, COM or EXE to start
//	char* args; /// FILEARGS, MUST not be over 127 characters
//	size_t arg_i; /// Argument length incrementor

	// Pre-boot / CLI

	while (--argc >= 1) {
		++argv;
		if (args) {
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
					case 'v': ++Verbose; break;
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
		}

		if (cast(int)prog == 0)
			prog = *argv;
		//TODO: Else, append program arguments (strcmp)
		//      Don't forget to null it after while loop, keep arg_i updated
	}

	if (cast(int)prog) {
		if (os_pexist(prog) == 0) {
			fputs("E: File not found\n", stderr);
			return EDOS_FILE_NOT_FOUND;
		}
	}

	switch (Verbose) {
	case LOG_SILENCE, LOG_CRIT, LOG_ERROR: break;
	case LOG_WARN: info("I: Log level: LOG_WARN"); break;
	case LOG_INFO: info("I: Log level: LOG_INFO"); break;
	case LOG_DEBUG: info("I: Log level: LOG_DEBUG"); break;
	default:
		printf("E: Unknown log level: %d\n", Verbose);
		return EDOS_INVALID_FUNCTION;
	}

	if (opt_sleep == 0)
		info("I: MAX_PERF");

	// Where the real fun starts

	//sleep_init;	// sleep timers
	vcpu_init;	// vcpu

	if (cast(int)prog) {
		if (vdos_load(prog)) {
			fputs("E: Could not load executable image\n", stderr);
			return PANIC_FILE_NOT_LOADED;
		}
	}

	con_init;	// ddcon
	vdos_init;	// vdos, screen

	if (arg_banner)
		__v_putn("DD-DOS is starting...");

	// Should be loading settings here

	screen_logo;

	if (cast(int)prog) {
		vCPU.CS = 0; vCPU.IP = 0x100; // Temporary
		vcpu_run;
	} else vdos_shell;

	return 0;
}