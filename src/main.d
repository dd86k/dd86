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
import vdos_screen : screen_draw, screen_clear, __VGA_ADDRESS;
import Logger;
import ddcon : vcon_init, Clear;
import os_utils : os_pexist;
import sleep : sleep_init;
import compile_config : APP_VERSION;

extern (C)
private void _version() {
	printf(
		"%s\n" ~
		"Copyright (c) 2017-2018 dd86k, MIT license\n" ~
		"Project page: <https://github.com/dd86k/dd-dos>\n" ~
		"License: <https://opensource.org/licenses/MIT>\n\n" ~
		"dd-dos " ~ APP_VERSION ~ "  (" ~ __TIMESTAMP__ ~ ")\n" ~
		"Compiled using the " ~ __VENDOR__ ~ " compiler v%d\n\n" ~
		// Credit roles start at 40 characters
		`Credits
dd86k ................................. Original author

`,
		BANNER, __VERSION__
	);
}

extern (C)
private void help() {
	puts(
`A 8088/DOS virtual machine and emulation layer
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

	switch (Verbose) {
	case LOG_SILENCE, LOG_CRIT, LOG_ERROR: break;
	case LOG_WARN: info("-- Log level: LOG_WARN"); break;
	case LOG_INFO: info("-- Log level: LOG_INFO"); break;
	case LOG_DEBUG: info("-- Log level: LOG_DEBUG"); break;
	default:
		printf("E: Unknown log level: %d\n", Verbose);
		return EDOS_INVALID_FUNCTION;
	}

	if (arg_banner)
		puts("DD-DOS is starting...");

	if (opt_sleep == 0)
		info("NOTICE: MAX_PERF");

	// Initiation

	vcon_init;	// ddcon
	//sleep_init;	// sleep
	vcpu_init;	// vcpu
	vdos_init;	// vdos, screen

	/*Clear;

	// Place banner in memory here

	screen_draw;*/

	if (arg_banner)
		puts(BANNER); // Defined in vdos.d

	if (cast(int)prog) {
		if (os_pexist(prog)) {
			vCPU.CS = 0; vCPU.IP = 0x100; // Temporary
			if (vdos_load(prog)) {
				fputs("E: Could not load executable image\n", stderr);
				return PANIC_FILE_NOT_LOADED;
			}
			vcpu_run;
		} else {
			fputs("E: File not found\n", stderr);
			return EDOS_FILE_NOT_FOUND;
		}
	} else vdos_shell;

	return 0;
}