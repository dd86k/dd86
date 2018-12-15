/*
 * dd-dos.d: virtual OS, shell, and interrupt handler (layer part)
 */

module vdos;

import ddc;
import core.stdc.string : strcmp, strlen, memcpy;
import core.stdc.stdlib : malloc, free, system;
import vcpu, vcpu_utils;
import vdos_codes, vdos_int;
import vdos_loader : vdos_load;
import vdos_structs : system_struct, dos_struct, __cpos;
import vdos_screen;
import utils, os_utils;
import ddcon, Logger;
import compile_config :
	__MM_SYS_DOS, C_RUNTIME, APP_VERSION, BUILD_TYPE, INIT_MEM;

enum BANNER = 
	`_______ _______        _______  ______  _______`~"\n"~
	`|  __  \|  __  \  ___  |  __  \/  __  \/ _____/`~"\n"~
	`| |  \ || |  \ | |___| | |  \ || /  \ |\____ \`~ "\n"~
	`| |__/ || |__/ |       | |__/ || \__/ |_____\ \`~"\n"~
	`|______/|______/       |______/\______/\______/`~"\n"
	; /// ASCII banner screen, fancy!

/// OEM IDs
enum OEM_ID { // Used for INT 21h AH=30 so far.
	IBM, Compaq, MSPackagedProduct, ATnT, ZDS
}

enum
	DOS_MAJOR_VERSION = 5, /// Default major DOS version
	DOS_MINOR_VERSION = 0; /// Default minor DOS version

enum float BIOS_TICK = 1 / 18.2f;

// Internal input buffer length.
private enum _BUFS = 127;

extern (C):

__gshared ubyte
	MajorVersion = DOS_MAJOR_VERSION, /// Alterable major version
	MinorVersion = DOS_MINOR_VERSION; /// Alterable minor version

// Live structures in MEMORY

__gshared dos_struct *DOS = void;
__gshared system_struct *SYSTEM = void;

extern (C)
void vdos_init() {
	// Setting a memory pointer as ubyte* (as vdos_settings*) is not
	// supported in CTFE, so done in run-time instead
	SYSTEM = cast(system_struct*)MEMORY;
	SYSTEM.memsize = INIT_MEM >> 10; // DIV 1024
	SYSTEM.video_mode = 3;
	SYSTEM.screen_row = 25;
	SYSTEM.screen_col = 80;

	DOS = cast(dos_struct*)(MEMORY + __MM_SYS_DOS);

	screen_init;
}

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
		__v_printf("\n%s%% ", inbuf);
	else // just-in-case
		__v_put("\n% ");

	__v_ucpos; // update cursor pos
	screen_draw;

	vdos_readline(inbuf, _BUFS);
	if (*inbuf == '\n') goto SHL_S; // Nothing to process

	switch (vdos_command(cast(immutable)inbuf)) {
	case -1, -2:
		__v_putn("Bad command or file name");
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
int vdos_command(immutable(char) *command) {
	char **argv = // argument vector, sizeof(char *)
		cast(char**)(MEMORY + 0x1200 + _BUFS + 1);
	const int argc = sargs(command, argv); /// argument count
	lowercase(*argv);
	//TODO: lowercase extensions
	//enum uint D_EXE = 0x6578652E; /// ".exe", LSB
	//enum uint D_COM = 0x6D6F632E; /// ".com", LSB

	//TODO: TREE, DIR (waiting on OS directory crawler)
	//TODO: search for executable in current directory (here)
	//TODO: search for executable in (virtual, user set) PATH

	//int argl = cast(int)strlen(*argv);

	/+if (os_pexist(*argv)) {
		if (os_pisdir(*argv)) return -2;
		switch (cast(uint)*argv[argl-4]) {
		case D_COM, D_EXE:
			__v_putn("HIT");
			//vdos_load(*argv);
			//vcpu_run;
			break;
		default: return -1;
		}
	} else { // try .exe, .com
		//char [256]appname = void;
		//memcpy(cast(char*)appname, *argv, argl); // dont copy null

	}+/

	// ** INTERNAL COMMANDS **

	// C

	if (strcmp(*argv, "cd") == 0 || strcmp(*argv, "chdir") == 0) {
		if (argc > 1) {
			if (strcmp(argv[1], "/?") == 0) {
				__v_putn(
					"Display or set current working directory\n"~
					"  CD or CHDIR [FOLDER]\n\n"~
					"By default, CD will display the current working directory"
				);
			} else {
				if (os_pisdir(*(argv + 1))) {
					os_scwd(*(argv + 1));
				} else {
					__v_putn("Directory not found or entry is not a directory");
				}
			}
		} else {
			if (os_gcwd(cast(char*)command))
				__v_putn(command);
			else
				__v_putn("Error getting current directory");
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
		__v_put("It is currently ");
		switch (CPU.AL) {
		case 0, 7: __v_put("Sunday"); break;
		case 1: __v_put("Monday"); break;
		case 2: __v_put("Tuesday"); break;
		case 3: __v_put("Wednesday"); break;
		case 4: __v_put("Thursday"); break;
		case 5: __v_put("Friday"); break;
		case 6: __v_put("Saturday"); break;
		default:
		}
		__v_printf(" %d-%02d-%02d\n", CPU.CX, CPU.DH, CPU.DL);
		return 0;
	}

	// E

	if (strcmp(*argv, "echo") == 0) {
		if (argc == 1) {
			__v_putn("ECHO is on");
		} else {
			for (int i = 1; i < argc; ++i) {
				__v_put(cast(immutable)argv[i]);
				__v_put(" ");
			}
			__v_putn;
		}
		return 0;
	}
	if (strcmp(*argv, "exit") == 0) return -3;

	// H

	if (strcmp(*argv, "help") == 0) {
		__v_putn(
			"Internal commands available\n\n"~
			"CD .......... Change working directory\n"~
			"CLS ......... Clear screen\n"~
			"DATE ........ Get current date\n"~
			"DIR ......... Show directory content\n"~
			"EXIT ........ Exit DD-DOS or script\n"~
			"TREE ........ Show directory structure\n"~
			"TIME ........ Get current time\n"~
			"MEM ......... Show memory information\n"~
			"VER ......... Show DD-DOS and MS-DOS version"
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
			__v_printf(
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
			__v_putn("Not implemented");
		} else if (strcmp(argv[1], "/free") == 0) {
			__v_putn("Not implemented");
		} else if (strcmp(argv[1], "/?") == 0) {
MEM_HELP:
			__v_putn(
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
		__v_putn("Not implemented. Only /stats is implemented");
		return 0;
	}

	// T

	if (strcmp(*argv, "time") == 0) {
		CPU.AH = 0x2C;
		INT(0x21);
		__v_printf("It is currently %02d:%02d:%02d.%02d\n",
			CPU.CH, CPU.CL, CPU.DH, CPU.DL);
		return 0;
	}

	// V

	if (strcmp(*argv, "ver") == 0) {
		__v_printf(
			"DD-DOS v"~APP_VERSION~
			", reporting MS-DOS v%d.%d (compiled: %d.%d)\n",
			MajorVersion, MinorVersion,
			DOS_MAJOR_VERSION, DOS_MINOR_VERSION
		);
		return 0;
	}

	// ? -- debugging

	if (strcmp(*argv, "??") == 0) {
		__v_putn(
`?diag       Print diagnostic information screen
?load FILE  Load an executable FILE into memory
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
				__v_putn("File not found");
		} else __v_putn("Executable required");
		return 0;
	}
	if (strcmp(*argv, "?run") == 0) {
		vcpu_run;
		return 0;
	}
	if (strcmp(*argv, "?v") == 0) {
		__v_printf("LOGLEVEL set to ");
		if (argc >= 2) {
			switch (argv[1][0]) {
			case '0', 's':
				LOGLEVEL = LOG_DEBUG;
				__v_putn("DEBUG");
				break;
			case '1', 'c':
				LOGLEVEL = LOG_CRIT;
				__v_putn("CRTICAL");
				break;
			case '2', 'e':
				LOGLEVEL = LOG_ERROR;
				__v_putn("ERRORS");
				break;
			case '3', 'w':
				LOGLEVEL = LOG_WARN;
				__v_putn("WARNINGS");
				break;
			case '4', 'i':
				LOGLEVEL = LOG_INFO;
				__v_putn("INFORMAL");
				break;
			case '5', 'd':
				LOGLEVEL = LOG_DEBUG;
				__v_putn("DEBUG");
				break;
			default:
				__v_putn("Invalid log level");
			} // switch
		} else if (LOGLEVEL) {
			LOGLEVEL = LOG_SILENCE;
			__v_putn("SILENCE");
		} else {
			debug {
				LOGLEVEL = LOG_DEBUG;
				__v_putn("DEBUG");
			} else {
				LOGLEVEL = LOG_INFO;
				__v_putn("INFO");
			}
		}
		return 0;
	}
	if (strcmp(*argv, "?p") == 0) {
		opt_sleep = !opt_sleep;
		__v_printf("CPU SLEEP mode: %s\n", opt_sleep ? "ON" : cast(char*)"OFF");
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
	if (strcmp(*argv, "?diag") == 0) {
		__v_printf(
			"DD-DOS version: "~APP_VERSION~"\n"~
			"MS-DOS version: %d.%d (%d.%d)\n"~
			"Compiler: "~__VENDOR__~" v%d\n"~
			"C Runtime: "~C_RUNTIME~"\n"~
			"Build type: "~BUILD_TYPE~"\n",
			MajorVersion, MinorVersion,
			DOS_MAJOR_VERSION, DOS_MINOR_VERSION,
			__VERSION__
		);
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
	__cpos *c = &SYSTEM.cursor[SYSTEM.screen_page];
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
		__v_putn;
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
	__v_ucpos; // update to host
	screen_draw;
	goto READ_S;
}

extern (C)
void print_regs() {
	__v_printf(
		"EIP=%08X  IP=%04X  (get_ip=%08X)\n"~
		"EAX=%08X  EBX=%08X  ECX=%08X  EDX=%08X\n"~
		"CS=%04X  DS=%04X  ES=%04X  SS=%04X  SP=%04X  BP=%04X  SI=%04X  DI=%04X\n",
		CPU.EIP, CPU.IP, get_ip,
		CPU.EAX, CPU.EBX, CPU.ECX, CPU.EDX,
		CPU.CS, CPU.DS, CPU.ES, CPU.SS, CPU.SP, CPU.BP, CPU.SI, CPU.DI,
	);
	__v_put("FLAG=");
	if (CPU.OF) __v_putn("OF ");
	if (CPU.DF) __v_putn("DF ");
	if (CPU.IF) __v_putn("IF ");
	if (CPU.TF) __v_putn("TF ");
	if (CPU.SF) __v_putn("SF ");
	if (CPU.ZF) __v_putn("ZF ");
	if (CPU.AF) __v_putn("AF ");
	if (CPU.PF) __v_putn("PF ");
	if (CPU.CF) __v_putn("CF ");
	__v_printf("(%4Xh)\n", FLAG);
}

extern (C)
void print_stack() {
	__v_putn("print_stack::Not implemented");
}

extern (C)
void panic(ushort code,
	immutable(char) *modname = cast(immutable(char)*)__MODULE__,
	int line = __LINE__) {
	import core.stdc.stdlib : exit;
	//TODO: Setup SEH that points here

	enum RANGE = 26, TARGET = (RANGE / 2) - 1;
	__v_printf(
		"\n\n\n\n"~
		"A fatal exception occured, which DD-DOS couldn't recover.\n\n"~
		"STOP: %4Xh (%s@L%d)\nEXEC:\n",
		//TODO: if SEH is setup, remove modname and line
		// Otherwise it'll be even more debugging
		code, modname, line
	);
	int i = RANGE;
	ubyte *p = MEMORY + CPU.EIP - TARGET;
	while (--i) {
		if (i == TARGET)
			__v_printf(" > %02X<", *p);
		else
			__v_printf(" %02X", *p);
		++p;
	}
	__v_put("\n--\n");
	print_regs;
	/*printf("--\n"); Temporary commented until print_stack is implemented
	print_stack;*/

	screen_draw;
	exit(code); //TODO: Consider another strategy
}