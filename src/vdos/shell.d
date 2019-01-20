/**
 * shell: Virtual shell
 */
module vdos.shell;

import ddc;
import core.stdc.string : strcmp, strlen, memcpy, strncpy;
import vcpu.core : MEMORY, vcpu_run, CPU, MEMORYSIZE, opt_sleep;
import vdos.loader : vdos_load;
import vdos.video;
import vdos.os;
import vdos.interrupts : INT;
import vdos.codes : PANIC_MANUAL;
import os.io;
import logger;
import appconfig : C_RUNTIME, APP_VERSION, BUILD_TYPE;

// Internal input buffer length.
private enum _BUFS = 127;

/**
 * Enter virtual shell (vDOS), assuming all modules have been initiated.
 * Uses memory location 1200h for input buffer
 */
extern (C)
void vdos_shell() {
	char *inbuf = // internal input buffer
		cast(char*)(MEMORY + 0x1200);
SHL_S:
	//TODO: Print $PROMPT
	if (os_gcwd(inbuf))
		v_printf("\n%s%% ", inbuf);
	else // just-in-case
		v_put("\n% ");

	v_updatecur; // update cursor pos
	screen_draw;

	vdos_readline(inbuf, _BUFS);
	if (*inbuf == '\n') goto SHL_S; // Nothing to process

	switch (vdos_command(cast(immutable)inbuf)) {
	case -1, -2:
		v_putln("Bad command or file name");
		goto SHL_S;
	case -3:
		//TODO: Proper application exit
		return;
	default: goto SHL_S;
	}
}

/**
 * Execute a command with its arguments, useful for scripting.
 * Uses memory location 1200h + _BUFS + 1 for argument list. (argv)
 * Params: command == Command string with arguments
 * Returns: Error code (ERRORLEVEL), see Note
 * Note:
 *   vdos_command include non-DOS error codes:
 *   Returns -1 on command not found
 *   Returns -2 on error (e.g. trying to call a directory)
 *   Returns -3 if EXIT has been requested
 */
extern (C)
int vdos_command(const(char) *command) {
	char **argv = // argument vector, sizeof(char *)
		cast(char**)(MEMORY + 0x1200 + _BUFS + 1);
	const int argc = sargs(command, argv); /// argument count
	lowercase(*argv);

	enum uint EXE_L = 0x6578652E; /// ".exe", LSB
	enum uint COM_L = 0x6D6F632E; /// ".com", LSB
	//enum uint EXE_U = 0x4558452E; /// ".EXE", LSB
	//enum uint COM_U = 0x4D4F432E; /// ".COM", LSB

	//TODO: TREE, DIR (waiting on OS directory crawler)
	//TODO: search for executable in (virtual, user set) PATH

	int argl = cast(int)strlen(*argv);

	//TODO: Do case-insensitive globbing instead (Posix)
	if (os_pexist(*argv)) {
		if (os_pisdir(*argv)) return -2;
		uint ext = *cast(uint*)&argv[0][argl-4];
		// While it is possible to compare strings (even with slices),
		// this works the fastests. This will be changed when needed.
		switch (ext) {
		case COM_L, EXE_L: // already lowercased
			vdos_load(*argv);
			vcpu_run;
			return 0;
		default: return -1;
		}
	} else {
		//TODO: Clean this up, move +ext checking to function
		char [512]appname = void;
		memcpy(cast(char*)appname, *argv, argl); // dont copy null
		uint* appext = cast(uint*)(cast(char*)appname + argl);
		*appext = COM_L;
		*(appext + 1) = 0;
		if (os_pexist(cast(char*)appname)) {
			vdos_load(cast(char*)appname);
			vcpu_run;
			return 0;
		}
		*appext = EXE_L;
		if (os_pexist(cast(char*)appname)) {
			vdos_load(cast(char*)appname);
			vcpu_run;
			return 0;
		}
	}

	// ** INTERNAL COMMANDS **

	// C

	if (strcmp(*argv, "cd") == 0 || strcmp(*argv, "chdir") == 0) {
		if (argc > 1) {
			if (strcmp(argv[1], "/?") == 0) {
				v_putln(
					"Display or set current working directory\n"~
					"  CD or CHDIR [FOLDER]\n\n"~
					"By default, CD will display the current working directory"
				);
			} else {
				if (os_pisdir(*(argv + 1))) {
					os_scwd(*(argv + 1));
				} else {
					v_putln("Directory not found or entry is not a directory");
				}
			}
		} else {
			if (os_gcwd(cast(char*)command))
				v_putln(command);
			else
				v_putln("Error getting current directory");
			return 2;
		}
		return 0;
	}
	if (strcmp(*argv, "cls") == 0) {
		screen_clear;
		SYSTEM.cursor[SYSTEM.screen_page].row = 0;
		SYSTEM.cursor[SYSTEM.screen_page].col = 0;
		return 0;
	}

	// D

	if (strcmp(*argv, "date") == 0) {
		CPU.AH = 0x2A;
		INT(0x21);
		v_put("It is currently ");
		switch (CPU.AL) {
		case 0, 7: v_put("Sunday"); break;
		case 1: v_put("Monday"); break;
		case 2: v_put("Tuesday"); break;
		case 3: v_put("Wednesday"); break;
		case 4: v_put("Thursday"); break;
		case 5: v_put("Friday"); break;
		case 6: v_put("Saturday"); break;
		default:
		}
		v_printf(" %d-%02d-%02d\n", CPU.CX, CPU.DH, CPU.DL);
		return 0;
	}

	// E

	if (strcmp(*argv, "echo") == 0) {
		if (argc == 1) {
			v_putln("ECHO is on");
		} else {
			for (int i = 1; i < argc; ++i) {
				v_put(cast(immutable)argv[i]);
				v_put(" ");
			}
			v_putln;
		}
		return 0;
	}
	if (strcmp(*argv, "exit") == 0) return -3;

	// H

	if (strcmp(*argv, "help") == 0) {
		v_putln(
			"Internal commands available\n\n"~
			"CD .......... Change working directory\n"~
			"CLS ......... Clear screen\n"~
			"DATE ........ Get current date\n"~
			"DIR ......... Show directory content\n"~
			"EXIT ........ Exit interactive session or script\n"~
			"TREE ........ Show directory structure\n"~
			"TIME ........ Get current time\n"~
			"MEM ......... Show memory information\n"~
			"VER ......... Show emulator and MS-DOS versions"
		);
		return 0;
	}

	// M

	if (strcmp(*argv, "mem") == 0) {
		if (argc <= 1) goto MEM_HELP;

		if (strcmp(argv[1], "/stats") == 0) {
			const uint msize = MEMORYSIZE;
			const ubyte ext = msize > 0xA_0000; // extended?
			const size_t ct = ext ? 0xA_0000 : msize; /// convential memsize
			const size_t tt = msize - ct; /// total memsize excluding convential

			int nzt; /// Non-zero (total/excluded from conventional in some cases)
			int nzc; /// Convential (<640K) non-zero
			for (size_t i; i < msize; ++i) {
				if (MEMORY[i]) {
					if (i < 0xA_0000)
						++nzc;
					else
						++nzt;
				}
			}
			v_printf(
				"Memory Type             Zero +   NZero =   Total\n" ~
				"-------------------  -------   -------   -------\n" ~
				"Conventional         %6dK   %6dK   %6dK\n" ~
				"Extended             %6dK   %6dK   %6dK\n" ~
				"-------------------  -------   -------   -------\n" ~
				"Total                %6dK   %6dK   %6dK\n",
				(ct - nzc) / 1024, nzc / 1024, ct / 1024,
				(tt - nzt) / 1024, nzt / 1024, tt / 1024,
				(msize - nzt) / 1024, (nzt + nzc) / 1024, msize / 1024
			);
			return 0;
		} else if (strcmp(argv[1], "/debug") == 0) {
			v_putln("Not implemented");
		} else if (strcmp(argv[1], "/free") == 0) {
			v_putln("Not implemented");
		} else if (strcmp(argv[1], "/?") == 0) {
MEM_HELP:
			v_putln(
				"Display memory statistics\n"~
				"MEM [OPTIONS]\n\n"~
				"OPTIONS\n"~
				"/DEBUG    Not implemented\n"~
				"/FREE     Not implemented\n"~
				"/STATS    Scan memory and show statistics\n\n"~
				"By default, MEM will show memory usage"
			);
			return 0;
		}
		v_putln("Not implemented. Only /stats is implemented");
		return 0;
	}

	// T

	if (strcmp(*argv, "time") == 0) {
		CPU.AH = 0x2C;
		INT(0x21);
		v_printf("It is currently %02d:%02d:%02d.%02d\n",
			CPU.CH, CPU.CL, CPU.DH, CPU.DL);
		return 0;
	}

	// V

	if (strcmp(*argv, "ver") == 0) {
		v_printf(
			"DD/86 v"~APP_VERSION~
			", reporting MS-DOS v%d.%d (compiled: %d.%d)\n",
			MajorVersion, MinorVersion,
			DOS_MAJOR_VERSION, DOS_MINOR_VERSION
		);
		return 0;
	}

	// ? -- debugging

	if (strcmp(*argv, "??") == 0) {
		v_putln(
`?load FILE  Load an executable FILE into memory
?p          Toggle performance mode
?panic      Manually panic
?r          Print interpreter registers info
?run        Start the interpreter at current CS:IP values
?s          Print stack (Not implemented)
?v          Toggle verbose mode`
		);
		return 0;
	}
	if (strcmp(*argv, "?load") == 0) {
		if (argc > 1) {
			if (os_pexist(argv[1])) {
				CPU.CS = 0; CPU.IP = 0x100; // Temporary
				vdos_load(argv[1]);
			} else
				v_putln("File not found");
		} else v_putln("Executable required");
		return 0;
	}
	if (strcmp(*argv, "?run") == 0) {
		vcpu_run;
		return 0;
	}
	if (strcmp(*argv, "?v") == 0) {
		v_printf("LOGLEVEL set to ");
		if (argc >= 2) {
			switch (argv[1][0]) {
			case '0', 's':
				LOGLEVEL = LOG_DEBUG;
				v_putln("DEBUG");
				break;
			case '1', 'c':
				LOGLEVEL = LOG_CRIT;
				v_putln("CRTICAL");
				break;
			case '2', 'e':
				LOGLEVEL = LOG_ERROR;
				v_putln("ERRORS");
				break;
			case '3', 'w':
				LOGLEVEL = LOG_WARN;
				v_putln("WARNINGS");
				break;
			case '4', 'i':
				LOGLEVEL = LOG_INFO;
				v_putln("INFORMAL");
				break;
			case '5', 'd':
				LOGLEVEL = LOG_DEBUG;
				v_putln("DEBUG");
				break;
			default:
				v_putln("Invalid log level");
			} // switch
		} else if (LOGLEVEL) {
			LOGLEVEL = LOG_SILENCE;
			v_putln("SILENCE");
		} else {
			debug {
				LOGLEVEL = LOG_DEBUG;
				v_putln("DEBUG");
			} else {
				LOGLEVEL = LOG_INFO;
				v_putln("INFO");
			}
		}
		return 0;
	}
	if (strcmp(*argv, "?p") == 0) {
		opt_sleep = !opt_sleep;
		v_printf("CPU SLEEP mode: %s\n", opt_sleep ? "ON" : cast(char*)"OFF");
		return 0;
	}
	if (strcmp(*argv, "?r") == 0) {
		print_regs;
		return 0;
	}
	if (strcmp(*argv, "?s") == 0) {
		print_stack;
		return 0;
	}
	if (strcmp(*argv, "?panic") == 0) {
		panic(PANIC_MANUAL);
		return 0;
	}

	return -1;
}

/**
 * Read a line within DOS
 * Params:
 *   buf = Buffer
 *   len = Buffer size (maximum length)
 * Returns: String length
 */
extern (C)
int vdos_readline(char *buf, int len) {
	import vdos.structs : CURSOR;
	import os.term : Key, KeyInfo, ReadKey;

	CURSOR *c = &SYSTEM.cursor[SYSTEM.screen_page];
	const ushort x = c.col; // initial cursor col value to update cursor position
	const ushort y = c.row; // ditto
	videochar *v = &VIDEO[(y * SYSTEM.screen_col) + x];	/// video index
	uint s;	/// string size
	uint i;	/// selection index
READ_S:
	const KeyInfo k = ReadKey;
	switch (k.keyCode) {
	case Key.Backspace:
		if (s) {
			if (i == 0) break;

			--i;
			char *p = buf + i;
			videochar *vc = v + i;

			if (i == s) {
				*p = 0;
				vc.ascii = 0;
			} else {
				uint l = s - i + 1;
				while (--l > 0) {
					*p = *(p + 1);
					vc.ascii = (vc + 1).ascii;
					++p; ++vc;
				}
			}
			--s;
		}
		break;
	case Key.LeftArrow:
		if (i > 0) --i;
		break;
	case Key.RightArrow:
		if (i < s) ++i;
		break;
	case Key.Delete: //TODO: delete key

		break;
	case Key.Enter:
		buf[s] = '\n';
		buf[s + 1] = 0;
		v_putln;
		return s + 2;
	case Key.Home:
		i = 0;
		break;
	case Key.End:
		i = s;
		break;
	default:
		// no space in buffer, abort
		if (s + 1 >= len) break;
		// anything that doesn't fit a character, abort
		//TODO: Character converter
		if (k.keyChar < 32 || k.keyChar > 126) break;

		// 012345   s=6, i=6, i == s
		//       ^
		// 012345   s=6, i=5, i < s
		//      ^
		if (i < s) { // cursor is not at the end, see examples above
			//TODO: FIXME
			char *p = buf + s; // start at the end
			uint l = s - i;
			while (--l >= 0) { // and "pull" characters to the end
				*p = *(p - 1);
				--p;
			}
		}
		//TODO: translate character in case of special codes
		// depending on current charset (cp437 or others)
		v[i].ascii = buf[i] = k.keyChar;
		++i; ++s;
		break;
	}
	// Update cursor position
	int xi = x + i;
	int yi = y;
	if (xi >= SYSTEM.screen_col) {
		xi -= SYSTEM.screen_col;
		yi += (xi / SYSTEM.screen_col) + 1;
	}
	c.col = cast(ubyte)xi;
	c.row = cast(ubyte)yi;
	v_updatecur; // update to host
	screen_draw;
	goto READ_S;
}


/**
 * CLI argument splitter, supports argument quoting.
 * This function inserts null-terminators.
 * Uses memory base 1400h for arguments and increments per argument lengths.
 * Params:
 *   t = User input
 *   argv = argument vector buffer
 * Returns: argument count
 * Notes: Original function by Nuke928. Modified by dd86k.
 */
extern (C)
int sargs(const char *t, char **argv) {
	int j, a;
	char* mloc = cast(char*)MEMORY + 0x1400;

	const size_t sl = strlen(t);

	for (int i = 0; i <= sl; ++i) {
		if (t[i] == 0 || t[i] == ' ' || t[i] == '\n') {
			argv[a] = mloc;
			mloc += i - j + 1;
			strncpy(argv[a], t + j, i - j);
			argv[a][i - j] = 0;
			while (t[i + 1] == ' ') ++i;
			j = i + 1;
			++a;
		} else if (t[i] == '\"') {
			j = ++i;
			while (t[i] != '\"' && t[i] != 0) ++i;
			if (t[i] == 0) continue;
			argv[a] = mloc;
			mloc += i - j + 1;
			strncpy(argv[a], t + j, i - j);
			argv[a][i - j] = 0;
			while(t[i + 1] == ' ') ++i;
			j = ++i;
			++a;
		}
	}

	return --a;
}

/**
 * Lowercase an ASCIZ string. Must be null-terminated.
 * Params: c = String pointer
 */
extern (C)
void lowercase(char *c) {
	while (*c) {
		if (*c >= 'A' && *c <= 'Z')
			*c = cast(char)(*c + 32);
		++c;
	}
}