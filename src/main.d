/**
 * main: Main entry point, CLI arguments, initiate sub-systems
 */
module main;

import core.stdc.string : strcmp;
import ddc : puts, printf, fputs, stderr, stdout;
import vcpu.core;
import vdos.os : LOGO, SYSTEM, vdos_init;
import vdos.shell : shell_start;
import err;
import vdos.loader : vdos_load;
import vdos.video;
import logger;
import os.term : con_init, con_clear, con_pos, WindowSize, con_wsize;
import os.io : os_pexist;
import config : APP_VERSION, PLATFORM, BUILD_TYPE, C_RUNTIME;

private:
extern (C):

/// Copyright string, used in version and license screens
enum COPYRIGHT = "Copyright (c) 2017-2020 dd86k\n\n";

/// Print version screen to stdout
void _version() {
	import d = std.compiler;
	printf(
	"dd86-"~PLATFORM~" v"~APP_VERSION~"-"~BUILD_TYPE~" ("~__TIMESTAMP__~")\n"~
	"Homepage: <https://github.com/dd86k/dd86>\n"~
	"License: MIT <https://opensource.org/licenses/MIT>\n"~
	"Compiler: "~__VENDOR__~" v%u.%03u, crt: "~C_RUNTIME~"\n",
	d.version_major, d.version_minor
	);
}

/// Print help screen to stdout
void help() {
	puts(
	"IBM PC Virtual Machine and DOS Emulation Layer\n"~
	"USAGE\n"~
	"	dd86 [-vPN] [FILE [FILEARGS]]\n"~
	"	dd86 {--version|-h|--help|--license}\n\n"~
	"OPTIONS\n"~
	"	-P	Do not sleep between cycles\n"~
	"	-N	Remove starting messages and banner\n"~
	"	-v	Increase verbosity level\n"~
	"	--version    Print version screen, then exit\n"~
	"	-h, --help   Print help screen, then exit\n"~
	"	--license    Print license screen, then exit"
	);
}

/// Print license screen to stdout
void license() {
	puts(
	COPYRIGHT~
	"Permission is hereby granted, free of charge, to any person obtaining a copy of\n"~
	"this software and associated documentation files (the \"Software\"), to deal in\n"~
	"the Software without restriction, including without limitation the rights to\n"~
	"use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies\n"~
	"of the Software, and to permit persons to whom the Software is furnished to do\n"~
	"so, subject to the following conditions:\n\n"~
	"The above copyright notice and this permission notice shall be included in all\n"~
	"copies or substantial portions of the Software.\n\n"~
	"THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n"~
	"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n"~
	"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n"~
	"AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n"~
	"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n"~
	"OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n"~
	"SOFTWARE."
	);
}

int main(int argc, char **argv) {
	bool args = true;
	ubyte opt_smsg = 1; /// CLI startup messages
	char *prog; /// FILE: COM or EXE to start
//	char *args; /// FILEARGS: for FILE

	//
	// Pre-boot / CLI
	//

	for (size_t argi = 1; argi < argc; ++argi) {
		if (args == false) goto L_DEFAULT_ARG;

		if (argv[argi][1] == '-') { // long arguments
			char* a = argv[argi] + 2;
			if (strcmp(a, "help") == 0) {
				help;
				return 0;
			}
			if (strcmp(a, "version") == 0) {
				_version;
				return 0;
			}
			if (strcmp(a, "license") == 0) {
				license;
				return 0;
			}

			printf("Unknown parameter: --%s\n", a);
			return EDOS_INVALID_FUNCTION;
		} else if (argv[argi][0] == '-') { // short arguments
			char* a = argv[argi];
			while (*++a) {
				switch (*a) {
				case 'P': CPU.sleep = !CPU.sleep; break;
				case 'N': opt_smsg = !opt_smsg; break;
				case 'v': ++LOGLEVEL; break;
				case '-': args = !args; break;
				case 'h': help; return 0;
				default:
					printf("Unknown parameter: -%c\n", *a);
					return EDOS_INVALID_FUNCTION;
				}
			}
			continue;
		}

L_DEFAULT_ARG:
		if (prog == null)
			prog = argv[argi];
		//TODO: Else, append program arguments (strcmp)
		//      Don't forget to null it after while loop and keep arg_i updated
	}

	if (cast(size_t)prog) {
		if (os_pexist(prog) == 0) {
			puts("E: File not found");
			return EDOS_FILE_NOT_FOUND;
		}
	}

	if (LOGLEVEL > LogLevel.Debug) {
		printf("E: Unknown log level: %u\n", LOGLEVEL);
		return EDOS_INVALID_FUNCTION;
	}

	//
	// Welcome to DD/86
	//

	con_init;	// os.term

	WindowSize s = void;
	con_wsize(&s);
	if (s.Width < 80 || s.Height < 25) {
		printf("Terminal must be at least 80x25 characters, got %ux%u\n",
			s.Width, s.Height);
		return 1;
	}

	//TODO: Read settings here

	vcpu_init;	// vcpu
	vdos_init;	// vdos + screen
	video_init;

	if (opt_smsg) {
		video_printf(
			"Starting DD/86...\n\n"~
			"Ver "~APP_VERSION~" ("~__TIMESTAMP__~")\n"~
			"Intel 8086, %uK OK\n\n",
			SYSTEM.memsize
		);

		const(char) *logl;

		switch (LOGLEVEL) {
		case LogLevel.Info:  logl = "LogLevel=Info"; break;
		case LogLevel.Debug: logl = "LogLevel=Debug"; break;
		default:
		}

		if (logl) log_info(logl);

		if (CPU.sleep == 0)
			log_info("MAX_PERF");
	}

	video_update;

	if (cast(size_t)prog) {
		vdos_load(prog);
		vcpu_run;
		video_update; //temp: ensures last frame is drawn
	} else shell_start;

	con_pos(0, 25);

	return 0;
}