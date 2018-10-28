/*
 * dd-dos.d: virtual OS, shell, and interrupt handler (layer part)
 */

module vdos;

import ddc;
import core.stdc.string : strcmp;
import core.stdc.stdlib : malloc, free, system;
import vcpu, vcpu_utils;
import vdos_codes, vdos_int;
import vdos_loader : vdos_load;
import vdos_structs : system_struct, dos_struct;
import vdos_screen;
import utils, os_utils;
import ddcon, Logger;
import compile_config :
	__MM_SYS_DOS, C_RUNTIME, APP_VERSION, BUILD_TYPE, INIT_MEM;

enum BANNER = `
_______ _______        _______  ______  _______
|  __  \|  __  \  ___  |  __  \/  __  \/ _____/
| |  \ || |  \ | |___| | |  \ || /  \ |\____ \
| |__/ || |__/ |       | |__/ || \__/ |_____\ \
|______/|______/       |______/\______/\______/
`; /// Banner screen, fancy!

/// OEM IDs
enum OEM_ID { // Used for INT 21h AH=30 so far.
	IBM, Compaq, MSPackagedProduct, ATnT, ZDS
}

enum
	DOS_MAJOR_VERSION = 5, /// Default major DOS version
	DOS_MINOR_VERSION = 0; /// Default minor DOS version

// Internal input buffer length.
private enum _BUFS = 127;

enum float BIOS_TICK = 1 / 18.2f;

__gshared ubyte
	MajorVersion = DOS_MAJOR_VERSION, /// Alterable major version
	MinorVersion = DOS_MINOR_VERSION; /// Alterable minor version

// Live structures in MEMORY

__gshared dos_struct* DOS;
__gshared system_struct* SYSTEM;

extern (C)
void vdos_init() {
	// ubyte* -> vdos_settings* is not supported in CTFE, done in run-time instead
	SYSTEM = cast(system_struct*)MEMORY;
	SYSTEM.memsize = INIT_MEM >> 10; // DIV 1024
	SYSTEM.video_mode = 3;
	SYSTEM.screen_row = 25;
	SYSTEM.screen_col = 80;

	DOS = cast(dos_struct*)(MEMORY + __MM_SYS_DOS);

	screen_init;
}

/**
 * Enter virtual shell (vDOS), assuming all modules have been initiated
 */
extern (C)
void vdos_shell() {
	char* inb = // internal input buffer, also used for CWD buffering
		cast(char*)(MEMORY + 0x900);
	char** argv = // argument vector, sizeof(char *)
		cast(char**)(MEMORY + 0x900 + _BUFS);

SHL_S:
	//TODO: Print $PROMPT
	if (os_gcwd(inb))
		__v_printf("\n%s%% ", inb);
	else // just-in-case
		__v_put("\n% "); screen_draw;

	fgets(inb, _BUFS, stdin);
	if (*inb == '\n') goto SHL_S; // Nothing to process

	const int argc = sargs(inb, argv); /// argument count

	lowercase(*argv);

	//TODO: TREE, DIR (waiting on OS directory crawler)

	// C

	if (strcmp(*argv, "cd") == 0 || strcmp(*argv, "chdir") == 0) {
		if (argc > 1) {
			if (strcmp(argv[1], "/?") == 0) {
				__v_putn(
`Display or set current working directory
  CD [FOLDER]
  CHDIR [FOLDER]

By default, CD will display the current working directory`
				);
			} else {
				if (os_pisdir(*(argv + 1))) {
					os_scwd(*(argv + 1));
				} else {
					__v_putn("Directory not found or entry is not a directory");
				}
			}
		} else {
			if (os_gcwd(cast(char*)inb))
				puts(cast(char*)inb);
			else puts("E: Error getting CWD");
		}
		goto SHL_S;
	}
	if (strcmp(*argv, "cls") == 0) {
		SYSTEM.cursor[SYSTEM.screen_page].row = 0;
		SYSTEM.cursor[SYSTEM.screen_page].col = 0;
		screen_clear;
		//Clear;
		goto SHL_S;
	}

	// D

	if (strcmp(*argv, "date") == 0) {
		vCPU.AH = 0x2A;
		INT(0x21);
		__v_put("It is currently ");
		switch (vCPU.AL) {
		case 0, 7: __v_put("Sun"); break;
		case 1: __v_put("Mon"); break;
		case 2: __v_put("Tue"); break;
		case 3: __v_put("Wed"); break;
		case 4: __v_put("Thu"); break;
		case 5: __v_put("Fri"); break;
		case 6: __v_put("Sat"); break;
		default:
		}
		__v_printf(" %d-%02d-%02d\n", vCPU.CX, vCPU.DH, vCPU.DL);
		goto SHL_S;
	}

	// E

	if (strcmp(*argv, "exit") == 0) {
		//free(inb);
		//free(argv);
		return;
	}

	// H

	if (strcmp(*argv, "help") == 0) {
		__v_putn(
`Internal commands available

CD .......... Change working directory
CLS ......... Clear screen
DATE ........ Get current date
DIR ......... Show directory content
EXIT ........ Exit DD-DOS or script
TREE ........ Show directory structure
TIME ........ Get current time
MEM ......... Show memory information
VER ......... Show DD-DOS and MS-DOS version`
		);
		goto SHL_S;
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
				"Memory Type             Zero +    Data =   Total\n" ~
				"-------------------  -------   -------   -------\n" ~
				"Conventional         %6dK   %6dK   %6dK\n" ~
				"Extended             %6dK   %6dK   %6dK\n" ~
				"-------------------  -------   -------   -------\n" ~
				"Total                %6dK   %6dK   %6dK\n",
				(ct - nzc) / 1024, nzc / 1024, ct / 1024,
				(tt - nzt) / 1024, nzt / 1024, tt / 1024,
				(msize - nzt) / 1024, (nzt + nzc) / 1024, msize / 1024);
		} else if (strcmp(argv[1], "/debug") == 0) {
			__v_putn("Not implemented");
		} else if (strcmp(argv[1], "/free") == 0) {
			__v_putn("Not implemented");
		} else if (strcmp(argv[1], "/?") == 0) {
MEM_HELP:
			__v_putn(
`Display memory statistics
MEM [OPTIONS]

OPTIONS
/DEBUG    Not implemented
/FREE     Not implemented
/STATS    Scan memory and show statistics

By default, MEM will show memory usage`
			);
			goto SHL_S;
		}
		__v_putn("Not implemented. Only /stats is implemented");
		goto SHL_S;
	}

	// T

	if (strcmp(*argv, "time") == 0) {
		vCPU.AH = 0x2C;
		INT(0x21);
		__v_printf("It is currently %02d:%02d:%02d.%02d\n",
			vCPU.CH, vCPU.CL, vCPU.DH, vCPU.DL);
		goto SHL_S;
	}

	// V

	if (strcmp(*argv, "ver") == 0) {
		__v_printf(
			"\nDD-DOS Version " ~
			APP_VERSION ~
			"\nMS-DOS Version %d.%d (compiled: %d.%d)\n",
			MajorVersion, MinorVersion,
			DOS_MAJOR_VERSION, DOS_MINOR_VERSION
		);
		goto SHL_S;
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
		goto SHL_S;
	}
	if (strcmp(*argv, "?load") == 0) {
		if (argc > 1) {
			if (os_pexist(argv[1])) {
				vCPU.CS = 0; vCPU.IP = 0x100; // Temporary
				vdos_load(argv[1]);
			} else
				__v_putn("File not found");
		} else __v_putn("Executable required");
		goto SHL_S;
	}
	if (strcmp(*argv, "?run") == 0) {
		vcpu_run;
		goto SHL_S;
	}
	if (strcmp(*argv, "?v") == 0) {
		__v_printf("Verbose set to ");
		if (argc >= 2) {
			switch (argv[1][0]) {
			case '0', 's':
				Verbose = LOG_DEBUG;
				__v_putn("DEBUG");
				break;
			case '1', 'c':
				Verbose = LOG_CRIT;
				__v_putn("CRTICAL");
				break;
			case '2', 'e':
				Verbose = LOG_ERROR;
				__v_putn("ERRORS");
				break;
			case '3', 'w':
				Verbose = LOG_WARN;
				__v_putn("WARNINGS");
				break;
			case '4', 'i':
				Verbose = LOG_INFO;
				__v_putn("INFORMAL");
				break;
			case '5', 'd':
				Verbose = LOG_DEBUG;
				__v_putn("DEBUG");
				break;
			default:
				__v_putn("Invalid log level");
			} // switch
		} else if (Verbose) {
			Verbose = LOG_SILENCE;
			__v_putn("SILENCE");
		} else {
			debug {
				Verbose = LOG_DEBUG;
				__v_putn("DEBUG");
			} else {
				Verbose = LOG_INFO;
				__v_putn("INFO");
			}
		}
		goto SHL_S;
	}
	if (strcmp(*argv, "?p") == 0) {
		opt_sleep = !opt_sleep;
		__v_printf("CPU SLEEP mode: %s\n", opt_sleep ? "ON" : cast(char*)"OFF");
		goto SHL_S;
	}
	if (strcmp(*argv, "?r") == 0) {
		print_regs;
		goto SHL_S;
	}
	if (strcmp(*argv, "?s") == 0) {
		print_stack;
		goto SHL_S;
	}
	if (strcmp(*argv, "?panic") == 0) {
		panic(PANIC_MANUAL);
		goto SHL_S;
	}
	if (strcmp(*argv, "?diag") == 0) {
		__v_printf(
			"MS-DOS version: %d.%d (%d.%d)\n" ~
			"DD-DOS version: " ~ APP_VERSION ~ "\n" ~
			"Compiler: " ~ __VENDOR__ ~ " v%d\n" ~
			"C Runtime: " ~ C_RUNTIME ~ " Runtime\n" ~
			"Build type: " ~ BUILD_TYPE ~ "\n",
			MajorVersion, MinorVersion,
			DOS_MAJOR_VERSION, DOS_MINOR_VERSION,
			__VERSION__
		);
		goto SHL_S;
	}

	//TODO: See if command is not an executable (COM/EXE (MZ)/BAT)
	//      to evaluate before passing to system, like check_exe
	//system(inb);
	__v_put("Bad command or file name");

//SHL_E:
	goto SHL_S;
}

extern (C)
void print_regs() {
	__v_printf(
`EIP=%08X  IP=%04X  (get_ip=%08X)
EAX=%08X  EBX=%08X  ECX=%08X  EDX=%08X
CS=%04X  DS=%04X  ES=%04X  SS=%04X  SP=%04X  BP=%04X  SI=%04X  DI=%04X
`,
		vCPU.EIP, vCPU.IP, get_ip,
		vCPU.EAX, vCPU.EBX, vCPU.ECX, vCPU.EDX,
		vCPU.CS, vCPU.DS, vCPU.ES, vCPU.SS, vCPU.SP, vCPU.BP, vCPU.SI, vCPU.DI,
	);
	__v_printf("FLAG=");
	if (vCPU.OF) __v_putn("OF ");
	if (vCPU.DF) __v_putn("DF ");
	if (vCPU.IF) __v_putn("IF ");
	if (vCPU.TF) __v_putn("TF ");
	if (vCPU.SF) __v_putn("SF ");
	if (vCPU.ZF) __v_putn("ZF ");
	if (vCPU.AF) __v_putn("AF ");
	if (vCPU.PF) __v_putn("PF ");
	if (vCPU.CF) __v_putn("CF ");
	__v_printf("(%4Xh)\n", FLAG);
}

extern (C)
void print_stack() {
	__v_putn("print_stack::Not implemented");
}

extern (C)
void panic(ushort code,
	immutable(char)* modname = cast(immutable(char)*)__MODULE__,
	int line = __LINE__) {
	import core.stdc.stdlib : exit;
	//TODO: Setup SEH that points here

	enum RANGE = 26, TARGET = RANGE / 2;
	__v_printf(
		"\n\n\n\n" ~
		"A fatal exception occured, which DD-DOS couldn't recover.\n\n" ~
		"STOP: %4Xh (%s@L%d)\nEXEC:\n",
		code, modname, line
	);
	int i = RANGE;
	ubyte* p = MEMORY + vCPU.EIP - TARGET;
	while (--i) {
		if (i == (TARGET - 1))
			__v_printf(" > %02X<", *p);
		else
			__v_printf(" %02X", *p);
		++p;
	}
	__v_put("\n--\n");
	print_regs;
	/*printf("--\n"); Temporary commented until print_stack is implemented
	print_stack;*/

	exit(code); //TODO: Consider another strategy
}