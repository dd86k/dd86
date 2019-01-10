/*
 * main.d: CLI entry point
 */

import core.stdc.string : strcmp;
import ddc : puts, printf, fputs, stderr, stdout;
import vcpu.core : vcpu_init, vcpu_run, opt_sleep;
import vdos.os : BANNER, SYSTEM, vdos_init;
import vdos.shell : vdos_shell;
import vdos.codes;
import vdos.loader : vdos_load;
import vdos.screen;
import logger;
import os.term : con_init, Clear, SetPos;
import os.io : os_pexist;
import appconfig : APP_VERSION, PLATFORM, BUILD_TYPE, C_RUNTIME;

extern (C):

enum DESCRIPTION = "IBM PC Virtual Machine and DOS Emulation Layer";
enum COPYRIGHT = "Copyright (c) 2017-2019 dd86k";

private void _version() {
	printf(
		BANNER~
		DESCRIPTION~"\n"~
		COPYRIGHT~"\n\n"~
		"dd-dos-"~PLATFORM~" v"~APP_VERSION~"-"~BUILD_TYPE~" ("~__TIMESTAMP__~")\n"~
		"Homepage: <https://git.dd86k.space/dd86k/dd-dos>\n"~
		"License: MIT <https://opensource.org/licenses/MIT>\n"~
		"Compiler: "~__VENDOR__~" v%d\n"~
		"Runtime: "~C_RUNTIME~" v%d\n",
		__VERSION__
	);
}

private void help() {
	puts(
		DESCRIPTION~"\n"~
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
	ubyte arg_info = 1;
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
				case 'N': --arg_info; break;
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
			puts("E: File not found");
			return EDOS_FILE_NOT_FOUND;
		}
	}

	if (LOGLEVEL > LOG_DEBUG) {
		printf("E: Unknown log level: %d\n", LOGLEVEL);
		return EDOS_INVALID_FUNCTION;
	}
	
	//TODO: Read settings here

	//
	// Welcome to DD-DOS
	//

	//sleep_init;	// sleep timers
	vcpu_init;	// vcpu
	con_init;	// os.term
	vdos_init;	// vdos, screen

	if (arg_info) {
		v_printf(
			"Starting DD-DOS...\n\n"~
			"DD-DOS Ver "~APP_VERSION~" "~__DATE__~"\n"~
			"Processor: Intel 8086\n"~
			"Memory: %dK OK\n\n",
			SYSTEM.memsize);

		switch (LOGLEVEL) {
		case LOG_CRIT:  log_info("LOG_CRIT"); break;
		case LOG_ERROR: log_info("LOG_ERROR"); break;
		case LOG_WARN:  log_info("LOG_WARN"); break;
		case LOG_INFO:  log_info("LOG_INFO"); break;
		case LOG_DEBUG: log_info("LOG_DEBUG"); break;
		default:
		}

		if (opt_sleep == 0)
			v_putn("MAX_PERF");
	}

	screen_draw;

	if (cast(int)prog) {
		vdos_load(prog);
		vcpu_run;
		screen_draw; // ensures last frame is drawn
	} else vdos_shell;

	SetPos(0, 25);

	return 0;
}