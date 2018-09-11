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
import vdos_structs : vdos_settings, dos_struct;
import utils, os_utils;
import ddcon, Logger;
import compile_config :
	__SETTINGS_LOC, __DOS_STRUCT_LOC, C_RUNTIME, APP_VERSION, BUILD_TYPE;

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

__gshared ubyte
	MajorVersion = DOS_MAJOR_VERSION, /// Alterable major version
	MinorVersion = DOS_MINOR_VERSION; /// Alterable minor version

// Internal input buffer length. While maximum in MS-DOS 5.0 seems to be 120,
// 255 feels like a little more breathable.
private enum _BUFS = 255;

/// DD-DOS settings holder. Values are stored in MEMORY.
__gshared vdos_settings* SETTINGS;
__gshared dos_struct* DOS;

extern (C)
void vdos_init() {
	// reinterpreting cast from ubyte* to vdos_settings* is not supported in CTFE
	// so it's done in run-time
	SETTINGS = cast(vdos_settings*)(MEMORY_P + __SETTINGS_LOC);
	DOS = cast(dos_struct*)(MEMORY_P + __SETTINGS_LOC);
}

/**
 * Enter virtual shell (vDOS)
 * This function allocates memory on the heap and frees it when exiting.
 */
extern (C)
void vdos_shell() {
	char* inb = // also used for CWD buffering
		cast(char*)malloc(_BUFS); /// internal input buffer
	char** argv = // sizeof(char *)
		cast(char**)malloc(_BUFS * size_t.sizeof); /// argument vector
SHELL_SHART:
	//TODO: Print $PROMPT
	if (os_gcwd(inb))
		printf("\n%s%% ", inb);
	else // just-in-case
		fputs("\n% ", stdout);

	fgets(inb, _BUFS, stdin);
	if (*inb == '\n') goto SHELL_SHART; // Nothing to process

	int argc = sargs(inb, argv); /// argument count

	//TODO: TREE, DIR
	lowercase(*argv);

	//TODO: Consider string-switch usage in betterC code (#24)

	// C

	if (strcmp(*argv, "cd") == 0 || strcmp(*argv, "chdir") == 0) {
		if (argc > 1) {
			if (strcmp(argv[1], "/?") == 0) {
				puts(
`Display or set current working directory
  CD [FOLDER]
  CHDIR [FOLDER]

By default, CD will display the current working directory`
				);
			} else {
				if (os_pisdir(argv[1])) {
					os_scwd(argv[1]);
				} else {
					puts("Directory not found or entry is not a directory");
				}
			}
		} else {
			if (os_gcwd(cast(char*)inb))
				puts(cast(char*)inb);
			else puts("E: Error getting CWD");
		}
		goto SHELL_SHART;
	}
	if (strcmp(*argv, "cls") == 0) {
		Clear;
		goto SHELL_SHART;
	}

	// D

	if (strcmp(*argv, "date") == 0) {
		vCPU.AH = 0x2A;
		INT(0x21);
		printf("It is currently ");
		switch (vCPU.AL) {
		case 0, 7: printf("Sun"); break;
		case 1: printf("Mon"); break;
		case 2: printf("Tue"); break;
		case 3: printf("Wed"); break;
		case 4: printf("Thu"); break;
		case 5: printf("Fri"); break;
		case 6: printf("Sat"); break;
		default:
		}
		printf(" %d-%02d-%02d\n", vCPU.CX, vCPU.DH, vCPU.DL);
		goto SHELL_SHART;
	}

	// E

	if (strcmp(*argv, "exit") == 0) {
		free(argv);
		free(inb);
		return;
	}

	// H

	if (strcmp(*argv, "help") == 0) {
		puts(
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
		goto SHELL_SHART;
	}

	// M

	if (strcmp(*argv, "mem") == 0) {
		if (strcmp(argv[1], "/stats") == 0) {
			const ubyte ext = MEMORYSIZE > 0xA_0000; // extended?
			const size_t ct = ext ? 0xA_0000 : MEMORYSIZE; /// convential memsize
			const size_t tt = MEMORYSIZE - ct; /// total memsize excluding convential

			int nzt; /// Non-zero (total/excluded from conventional in some cases)
			int nzc; /// Convential (<640K) non-zero
			for (int i; i < MEMORYSIZE; ++i) {
				if (MEMORY[i]) {
					if (i < 0xA_0000)
						++nzc;
					else
						++nzt;
				}
			}
			printf(
				"Memory Type             Zero +    Data =   Total\n" ~
				"-------------------  -------   -------   -------\n" ~
				"Conventional         %6dK   %6dK   %6dK\n" ~
				"Extended             %6dK   %6dK   %6dK\n" ~
				"-------------------  -------   -------   -------\n" ~
				"Total                %6dK   %6dK   %6dK\n",
				(ct - nzc) / 1024, nzc / 1024, ct / 1024,
				(tt - nzt) / 1024, nzt / 1024, tt / 1024,
				(MEMORYSIZE - nzt) / 1024, (nzt + nzc) / 1024, MEMORYSIZE / 1024);
		} else if (strcmp(argv[1], "/debug") == 0) {
			puts("Not implemented");
		} else if (strcmp(argv[1], "/free") == 0) {
			puts("Not implemented");
		} else if (strcmp(argv[1], "/?") == 0) {
			puts(
`Display memory statistics
  MEM [OPTIONS]

OPTIONS
/DEBUG    Not implemented
/FREE     Not implemented
/STATS    Scan memory and show statistics

By default, MEM will show memory usage`
			);
		} else {
			puts("Not implemented. Only /stats is implemented");
		}
		goto SHELL_SHART;
	}

	// T

	if (strcmp(*argv, "time") == 0) {
		vCPU.AH = 0x2C;
		INT(0x21);
		printf("It is currently %02d:%02d:%02d.%02d\n",
			vCPU.CH, vCPU.CL, vCPU.DH, vCPU.DL);
		goto SHELL_SHART;
	}

	// V

	if (strcmp(*argv, "ver") == 0) {
		printf(
			"\nDD-DOS Version " ~
			APP_VERSION ~
			"\nMS-DOS Version %d.%d (compiled: %d.%d)\n",
			MajorVersion, MinorVersion,
			DOS_MAJOR_VERSION, DOS_MINOR_VERSION
		);
		goto SHELL_SHART;
	}

	// ? -- debugging

	if (strcmp(*argv, "??") == 0) {
		puts(
`?diag       Print diagnostic information screen
?load FILE  Load an executable FILE into memory
?p          Toggle performance mode
?panic      Manually panic
?r          Print interpreter registers info
?run        Start the interpreter at current CS:IP values
?s          Print stack (Not implemented)
?v          Toggle verbose mode`
		);
		goto SHELL_SHART;
	}
	if (strcmp(*argv, "?load") == 0) {
		if (argc > 1) {
			if (os_pexist(argv[1])) {
				vCPU.CS = 0; vCPU.IP = 0x100; // Temporary
				vdos_load(argv[1]);
			} else
				puts("File not found");
		} else puts("Executable required");
		goto SHELL_SHART;
	}
	if (strcmp(*argv, "?run") == 0) {
		vcpu_run;
		goto SHELL_SHART;
	}
	if (strcmp(*argv, "?v") == 0) {
		printf("Verbose set to ");
		if (argc >= 2) {
			switch (argv[1][0]) {
			case '0', 's':
				Verbose = LOG_DEBUG;
				puts("DEBUG");
				break;
			case '1', 'c':
				Verbose = LOG_CRIT;
				puts("CRTICAL");
				break;
			case '2', 'e':
				Verbose = LOG_ERROR;
				puts("ERRORS");
				break;
			case '3', 'w':
				Verbose = LOG_WARN;
				puts("WARNINGS");
				break;
			case '4', 'i':
				Verbose = LOG_INFO;
				puts("INFORMAL");
				break;
			case '5', 'd':
				Verbose = LOG_DEBUG;
				puts("DEBUG");
				break;
			default:
				puts("Invalid log level");
			} // switch
		} else if (Verbose) {
			Verbose = LOG_SILENCE;
			puts("SILENCE");
		} else {
			debug {
				Verbose = LOG_DEBUG;
				puts("DEBUG");
			} else {
				Verbose = LOG_INFO;
				puts("INFO");
			}
		}
		goto SHELL_SHART;
	}
	if (strcmp(*argv, "?p") == 0) {
		opt_sleep = !opt_sleep;
		printf("CpuSleep mode: %s\n", opt_sleep ? "ON" : cast(char*)"OFF");
		goto SHELL_SHART;
	}
	if (strcmp(*argv, "?r") == 0) {
		print_regs;
		goto SHELL_SHART;
	}
	if (strcmp(*argv, "?s") == 0) {
		print_stack;
		goto SHELL_SHART;
	}
	if (strcmp(*argv, "?panic") == 0) {
		panic(PANIC_MANUAL);
		goto SHELL_SHART;
	}
	if (strcmp(*argv, "?diag") == 0) {
		printf(
			"MS-DOS version: %d.%d (%d.%d)\n" ~
			"DD-DOS version: " ~ APP_VERSION ~ "\n" ~
			"Compiler: " ~ __VENDOR__ ~ " v%d\n" ~
			"C Runtime: " ~ C_RUNTIME ~ " Runtime\n" ~
			"Build type: " ~ BUILD_TYPE ~ "\n",
			MajorVersion, MinorVersion,
			DOS_MAJOR_VERSION, DOS_MINOR_VERSION,
			__VERSION__
		);
		goto SHELL_SHART;
	}

	//TODO: See if command is not an executable (COM/EXE (MZ)/BAT)
	//      to evaluate before passing to system, like check_exe or something
	system(inb);
	//puts("Bad command or file name");

SHELL_END:
	goto SHELL_SHART;
}

extern (C)
void print_regs() {
	printf(
`EIP=%08X  IP=%04X  (get_ip=%08X)
EIP=%08X  EBX=%08X  ECX=%08X  EDX=%08X
CS=%04X  DS=%04X  ES=%04X  SS=%04X  SP=%04X  BP=%04X  SI=%04X  DI=%04X
`,
		vCPU.EIP, vCPU.IP, get_ip,
		vCPU.EIP, vCPU.EBX, vCPU.ECX, vCPU.EDX,
		vCPU.CS, vCPU.DS, vCPU.ES, vCPU.SS, vCPU.SP, vCPU.BP, vCPU.SI, vCPU.DI,
	);
	printf("FLAG=");
	//TODO: Use fputs
	if (vCPU.OF) printf("OF ");
	if (vCPU.DF) printf("DF ");
	if (vCPU.IF) printf("IF ");
	if (vCPU.TF) printf("TF ");
	if (vCPU.SF) printf("SF ");
	if (vCPU.ZF) printf("ZF ");
	if (vCPU.AF) printf("AF ");
	if (vCPU.PF) printf("PF ");
	if (vCPU.CF) printf("CF ");
	printf("(%4Xh)\n", FLAG);
}

extern (C)
void print_stack() {
	puts("print_stack::Not implemented");
}

extern (C)
void panic(ushort code,
	immutable(char)* modname = cast(immutable(char)*)__MODULE__,
	int line = __LINE__) {
	enum RANGE = 26, TARGET = RANGE / 2;
	printf(
		"\n\n\n\n" ~
		"A fatal exception occured, which DD-DOS couldn't recover.\n\n" ~
		"STOP: %4Xh (%s@L%d)\nEXEC:\n",
		code, modname, line
	);
	int i = RANGE;
	ubyte* p = MEMORY_P + vCPU.EIP - TARGET;
	while (--i) {
		if (i == (TARGET - 1))
			printf(" > %02X<", *p);
		else
			printf(" %02X", *p);
		++p;
	}
	printf("\n--\n");
	print_regs;
	/*printf("--\n"); Temporary commented until print_stack is implemented
	print_stack;*/
}