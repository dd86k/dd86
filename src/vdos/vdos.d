/*
 * dd-dos.d: virtual OS, shell, and interrupt handler (layer part)
 */

module vdos;

import core.stdc.stdio : printf, puts, fputs, fgets, stdin, stdout;
import core.stdc.string : strcmp, strncpy, strlen;
import core.stdc.stdlib : malloc, free, system;
import vdos_loader : ExecLoad;
import vcpu;
import ddcon, Logger, vdos_codes, utils, utils_os, ddc;

debug {
pragma(msg, `
+-------------+
| DEBUG BUILD |
+-------------+
`);
	enum BUILD_TYPE = "DEBUG";	/// For printing purposes
} else {
	enum BUILD_TYPE = "RELEASE";	/// For printing purposes
}

pragma(msg, "Compiling DD-DOS ", APP_VERSION);
pragma(msg, "Default MS-DOS version: ", DOS_MAJOR_VERSION, ".", DOS_MINOR_VERSION);

version (BigEndian)
	pragma(msg,
`WARNING: DD-DOS has not been tested on big-endian platforms!
You might want to run 'dub test' beforehand.
`);

version (CRuntime_Bionic) {
	pragma(msg, "Using Bionic C Runtime");
	enum C_RUNTIME = "Bionic";
} else version (CRuntime_DigitalMars) {
	pragma(msg, "Using DigitalMars C Runtime");
	enum C_RUNTIME = "DigitalMars";
} else version (CRuntime_Glibc) {
	pragma(msg, "Using Glibc C Runtime");
	enum C_RUNTIME = "Glibc";
} else version (CRuntime_Microsoft) {
	pragma(msg, "Using Microsoft C Runtime");
	enum C_RUNTIME = "Microsoft";
} else version(CRuntime_Musl) {
	pragma(msg, "Using musl C Runtime");
	enum C_RUNTIME = "musl";
} else version (CRuntime_UClibc) {
	pragma(msg, "Using uClibc C Runtime");
	enum C_RUNTIME = "uClibc";
} else {
	pragma(msg, "Runtime: Unknown (Be careful!)");
	enum C_RUNTIME = "UNKNOWN";
}

enum APP_VERSION = "0.0.0-0"; /// DD-DOS version

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

/// File/Folder attribute. See INT 21h AH=3Ch
// Trivia: Did you know Windows still use these values today?
enum
	READONLY = 1,
	HIDDEN = 2,
	SYSTEM = 4,
	VOLLABEL = 8,
	DIRECTORY = 16,
	ARCHIVE = 32,
	SHAREABLE = 128;

// While maximum in MS-DOS 5.0 seems to be 120, 255 feels like a little more
// breathable
enum _BUFS = 255;

/**
 * Enter virtual shell (vDOS)
 * This function allocates memory on the heap and frees when exiting.
 */
extern (C)
void EnterShell() {
	__gshared char* inb; /// internal input buffer, also used for CWD buffering
	__gshared char** argv; /// argument vector
	__gshared int argc; /// argument count
	inb = cast(char*)malloc(_BUFS);
	argv = cast(char**)malloc(_BUFS * size_t.sizeof); // sizeof(char *)
START:
	//TODO: Print $PROMPT
	if (gcwd(cast(char*)inb))
		printf("\n%s%% ", cast(char*)inb);
	else // just-in-case
		fputs("\n% ", stdout);

	fgets(cast(char*)inb, _BUFS, stdin);
	if (*inb == '\n') goto START; // Empty?

	argc = sargs(cast(char*)inb, argv);

	//TODO: TREE, DIR
	lowercase(*argv);

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
				if (pisdir(argv[1])) {
					scwd(argv[1]);
				} else {
					puts("Directory not found or entry is not a directory");
				}
			}
		} else {
			if (gcwd(cast(char*)inb))
				puts(cast(char*)inb);
			else puts("E: Error getting CWD");
		}
		goto START;
	}
	if (strcmp(*argv, "cls") == 0) {
		Clear;
		goto START;
	}

	// D

	if (strcmp(*argv, "date") == 0) {
		AH = 0x2A;
		Raise(0x21);
		printf("It is currently ");
		switch (AL) {
		case 0, 7: printf("Sun"); break;
		case 1: printf("Mon"); break;
		case 2: printf("Tue"); break;
		case 3: printf("Wed"); break;
		case 4: printf("Thu"); break;
		case 5: printf("Fri"); break;
		case 6: printf("Sat"); break;
		default:
		}
		printf(" %d-%02d-%02d\n", CX, DH, DL);
		goto START;
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
`CD        Change working directory
CLS       Clear screen
DATE      Get current date
DIR       Show directory content
EXIT      Exit DD-DOS or script
TREE      Show directory structure
TIME      Get current time
MEM       Show memory information
VER       Show DD-DOS and MS-DOS version`
		);
		goto START;
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
				if (i < 0xA_0000) {
					if (MEMORY[i]) ++nzc;
				} else if (MEMORY[i]) ++nzt;
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
			puts("Not implemented");
		}
		goto START;
	}

	// T

	if (strcmp(*argv, "time") == 0) {
		AH = 0x2C;
		Raise(0x21);
		printf("It is currently %02d:%02d:%02d.%02d\n", CH, CL, DH, DL);
		goto START;
	}

	// V

	if (strcmp(*argv, "ver") == 0) {
		printf(
			"\nDD-DOS Version " ~ APP_VERSION ~ "\nMS-DOS Version %d.%d (default: %d.%d)\n",
			MajorVersion, MinorVersion,
			DOS_MAJOR_VERSION, DOS_MINOR_VERSION
		);
		goto START;
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
		goto START;
	}
	if (strcmp(*argv, "?load") == 0) {
		if (argc > 1) {
			if (pexist(argv[1])) {
				CS = 0; IP = 0x100; // Temporary
				ExecLoad(argv[1]);
			} else
				puts("File not found");
		} else puts("Executable required");
		goto START;
	}
	if (strcmp(*argv, "?run") == 0) {
		vcpu_run;
		goto START;
	}
	if (strcmp(*argv, "?v") == 0) {
		printf("Verbose set to ");
		if (Verbose) {
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
		goto START;
	}
	if (strcmp(*argv, "?p") == 0) {
		opt_sleep = !opt_sleep;
		printf("CpuSleep mode: %s\n", opt_sleep ? "ON" : cast(char*)"OFF");
		goto START;
	}
	if (strcmp(*argv, "?r") == 0) {
		print_regs;
		goto START;
	}
	if (strcmp(*argv, "?s") == 0) {
		print_stack;
		goto START;
	}
	if (strcmp(*argv, "?panic") == 0) {
		panic(PANIC_MANUAL);
		goto START;
	}
	if (strcmp(*argv, "?diag") == 0) {
		printf(
			"Current MS-DOS version: %d.%d\n" ~
			"Compiled MS-DOS version: %d.%d\n" ~
			"DD-DOS version: " ~ APP_VERSION ~ "\n" ~
			"Compiler: " ~ __VENDOR__ ~ " v%d\n" ~
			"C Runtime: " ~ C_RUNTIME ~ " Runtime\n" ~
			"Build type: " ~ BUILD_TYPE ~ "\n",
			MajorVersion, MinorVersion,
			DOS_MAJOR_VERSION, DOS_MINOR_VERSION,
			__VERSION__
		);
		goto START;
	}

	system(inb);
	//puts("Bad command or file name");

END:	goto START;
}

extern (C)
void print_regs() {
	printf(
`EIP=%08X  IP=%04X  (get_ip=%08X)
EAX=%08X  EBX=%08X  ECX=%08X  EDX=%08X
CS=%04X  DS=%04X  ES=%04X  SS=%04X  SP=%04X  BP=%04X  SI=%04X  DI=%04X
`,
		EIP, IP, get_ip,
		EAX, EBX, ECX, EDX,
		CS, DS, ES, SS, SP, BP, SI, DI,
	);
	printf("FLAG=");
	if (OF) printf("OF ");
	if (DF) printf("DF ");
	if (IF) printf("IF ");
	if (TF) printf("TF ");
	if (SF) printf("SF ");
	if (ZF) printf("ZF ");
	if (AF) printf("AF ");
	if (PF) printf("PF ");
	if (CF) printf("CF ");
	printf("(%Xh)\n", FLAG);
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
	ubyte* p = MEMORY_P + EIP - TARGET;
	while (--i) {
		if (i == TARGET)
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

/*
 * Interrupt handler (Hardware, BIOS, DOS, vDOS)
 */

/// Raise interrupt.
/// Params: code = Interrupt byte
extern (C)
void Raise(ubyte code) {
	debug printf("[dbug] INTERRUPT: %02Xh\n", code);

	// REAL-MODE
	//const inum = code << 2;
	/*IF (inum + 3 > IDT limit)
		#GP
	IF stack not large enough for a 6-byte return information
		#SS*/
	/*push(FLAG);
	IF = TF = 0;
	push(CS);
	push(IP);*/
	//CS ← IDT[inum].selector;
	//IP ← IDT[inum].offset;

	switch (code) {
	case 0x10: // VIDEO
		switch (AH) {
		/*
		 * VIDEO - Set cursor position
		 */
		case 0x02:
			SetPos(DH, DL);
			break;
		/*
		 * VIDEO - Get cursor position and size
		 */
		case 0x03:
			AX = 0;
			//DH = cast(ubyte)CursorTop;
			//DL = cast(ubyte)CursorLeft;
			break;
		/*
		 * VIDEO - Read light pen position
		 */
		case 0x04:

			break;
		default:
		
			break;
		}
		break;
	case 0x11: { // BIOS - Get equipement list
		// Number of 16K banks of RAM on motherboard (PC only).
		int ax = 0b10000; // VGA //TODO: CHECK ON VIDEO MODE!
		/*if (FloppyDiskInstalled) {
			ax |= 1;
			// Bit 6-7 = Number of floppy drives
			ax |= 0b10
		}*/
		//if (PenInstalled) ax |= 0b100;
		AX = ax;
		break;
	}
	case 0x12: // BIOS - Get memory size
		AX = cast(int)(MEMORYSIZE) / 1024;
		break;
	case 0x13: // DISK operations

		break;
	case 0x14: // SERIAL

		break;
	case 0x16: // Keyboard
		switch (AH) {
		case 0, 1: { // Get/Check keystroke
			/*const KeyInfo k = ReadKey;
			AH = cast(ubyte)k.scanCode;
			AL = cast(ubyte)k.keyCode;
			if (AH) ZF = 0; // Keystroke available*/
		}
			break;
		case 2: // SHIFT
			// Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
			// Des | I | C | N | S | A | C | L | R
			// Insert, Capslock, Numlock, Scrolllock, Alt, Ctrl, Left, Right
			// AL = (flag)
			break;
		default:
			
			break;
		}
		break;
	case 0x17: // PRINTER

		break;
	case 0x1A: // TIME
		switch (AH) {
		/*
		 * Get system time by number of clock ticks since midnight
		 */
		case 0:

			break;
		/*
		 * Set system time by number of clock ticks since midnight
		 */
		case 1:
		
			break;

		default: break;
		}
		break;
	case 0x1B: // CTRL-BREAK handler

		break;
	case 0x21: // MS-DOS Services
		switch (AH) {
		/*
		 * 00h - Terminate program
		 */
		case 0:

			break;
		/*
		 * 01h - Read character from stdin with echo
		 */
		case 1:
			//AL = cast(ubyte)ReadKey.keyCode;
			break;
		/*
		 * 02h - Write character to stdout
		 */
		case 2:
			AL = DL;
			putchar(AL);
			break;
		/*
		 * 05h - Write character to printer
		 */
		case 5:

			break;
		/*
		 * 06h - Direct console input/output
		 */
		case 6:

			break;
		/*
		 * 07h - Read character directly from stdin without echo
		 */
		case 7:
			//AL = cast(ubyte)ReadKey.keyCode;
			break;
		/*
		 * 08h - Read character from stdin without echo
		 */
		case 8:

			break;
		/*
		 * 09h - Write string to stdout
		 */
		case 9: {
			uint limit = 255;
			char* p = cast(char*)MEMORY + get_ad(DS, DX);
			while (*p != '$' && --limit > 0)
				putchar(*p++);

			AL = 0x24;
			break;
		}
		/*
		 * 0Ah - Buffered input
		 */
		case 0xA:

			break;
		/*
		 * 0Bh - Get stdin status
		 */
		case 0xB:

			break;
		/*
		 * 0Ch - Flush stdin buffer and read character
		 */
		case 0xC:

			break;
		/*
		 * 0Dh - Disk reset
		 */
		case 0xD:

			break;
		/*
		 * 0Eh - Select default drive
		 */
		case 0xE:

			break;
		/*
		 * 19h - Get default drive
		 */
		case 0x19:
			AL = 2; // Temporary.
			break;
		/*
		 * 25h - Set interrupt vector
		 */
		case 0x25:

			break;
		/*
		 * 26h - Create PSP
		 */
		case 0x26:

			break;
		/*
		 * 2Ah - Get system date
		 */
		case 0x2A: {
			OSDate d;
			os_date(&d); // utils_os
			CX = d.year;
			DH = d.month;
			DL = d.day;
			AL = d.weekday;
			break;
		}
		/*
		 * 2Bh - Set system date
		 */
		case 0x2B:
			AL = 0xFF;
			break;
		/*
		 * 2Ch - Get system time
		 */
		case 0x2C: {
			OSTime t;
			os_time(&t); // utils_os
			CH = t.hour;
			CL = t.minute;
			DH = t.second;
			DL = t.millisecond;
			break;
		}
		/*
		 * 2Dh - Set system time
		 */
		case 0x2D:
			AL = 0xFF;
			break;
		/*
		 * 2Eh - Set verify flag
		 */
		case 0x2E:

			break;
		/*
		 * 30h - Get DOS version
		 */
		case 0x30:
			BH = AL == 0 ? OEM_ID.IBM : 0;
			AL = MajorVersion;
			AH = MinorVersion;
			break;
		/*
		 * 35h - Get interrupt vector.
		 */
		case 0x35:

			break;
		/*
		 * 36h - Get free disk space.
		 */
		case 0x36:

			break;
		/*
		 * Get country specific information
		 */
		case 0x38:

			break;
		/*
		 * 39h - Create subdirectory
		 */
		case 0x39:

			break;
		/*
		 * 3Ah - Remove subdirectory
		 */
		case 0x3A:

			break;
		/*
		 * 3Bh - Set current directory
		 */
		case 0x3B:

			break;
		/*
		 * 3Ch - Create or truncate file
		 */
		case 0x3C:

			break;
		/*
		 * 3Dh - Open file
		 */
		case 0x3D:

			break;
		/*
		 * 3Eh - Close file
		 */
		case 0x3E:

			break;
		/*
		 * 3Fh - Read from file or device
		 */
		case 0x3F:

			break;
		/*
		 * 40h - Write to file or device
		 */
		case 0x40:

			break;
		/*
		 * 41h - Delete file
		 */
		case 0x41:

			break;
		/*
		 * 42h - Set current file position
		 */
		case 0x42:

			break;
		/*
		 * 43h - Get or set file attributes
		 */
		case 0x43:

			break;
		/*
		 * 47h - Get current working directory
		 */
		case 0x47:

			break;
		/*
		 * 4Ah - Resize memory block
		 */
		case 0x4A:

			break;
		/*
		 * 4Bh - Load/execute program
		 */
		case 0x4B: {
			switch (AL) {
			case 0: // Load and execute the program.
				char[] p = MemString(get_ad(DS, DX));
				if (pexist(cast(char*)p)) {
					ExecLoad(cast(char*)p);
					CF = 0;
				} else {
					AX = E_FILE_NOT_FOUND;
					CF = 1;
				}
				break;
			case 1: // Load, create the program header but do not begin execution.

				CF = 1;
				break;
			case 3: // Load overlay. No header created.

				CF = 1;
				break;
			default:
				AX = E_INVALID_FUNCTION;
				CF = 1;
				break;
			}
		}
			break;
		/*
		 * 4Ch - Terminate with return code
		 */
		case 0x4C:
			--RLEVEL;
			//TODO: ERRORLEVEL = AL;
			break;
		/*
		 * 4Dh - Get return code. (ERRORLEVEL)
		 */
		case 0x4D:
			
			break;
		/*
		 * 54h - Get verify flag
		 */
		case 0x54:

			break;
		/*
		 * 56h - Rename file or directory
		 */
		case 0x56:

			break;
		/*
		 * 57h - Get or set file's last-written time and date
		 */
		case 0x57:

			break;
		default: break;
		}
		break; // End MS-DOS Services
	case 0x27: // TERMINATE AND STAY RESIDANT

		break;
	case 0x29: // FAST CONSOLE OUTPUT
		putchar(AL);
		break;
	default: break;
	}

	/*IP = pop;
	CS = pop;
	IF = TF = 1;
	FLAG = pop;*/
}