/*
 * dd-dos.d: Operating system, shell, system and hardware interrupts handler
 */

module vdos;

import core.stdc.stdio;
import core.stdc.string;
import core.stdc.stdlib : malloc, free;
import Loader : ExecLoad;
import vcpu, ddcon, Logger, Codes, Utilities, OSUtilities;

debug {
pragma(msg, `
+-------------+
| DEBUG BUILD |
+-------------+
`);
enum BUILD_TYPE = "DEBUG";
} else {
enum BUILD_TYPE = "RELEASE";
}

pragma(msg, "Compiling DD-DOS ", APP_VERSION);
pragma(msg, "Reporting MS-DOS ", DOS_MAJOR_VERSION, ".", DOS_MINOR_VERSION);
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


enum APP_VERSION = "0.0.0-0"; /// Application version

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

enum DOS_MAJOR_VERSION = 2, /// Default reported major DOS version
	 DOS_MINOR_VERSION = 0; /// Default reported minor DOS version

__gshared ubyte MajorVersion = DOS_MAJOR_VERSION; /// Alterable reported major version
__gshared ubyte MinorVersion = DOS_MINOR_VERSION; /// Alterable reported minor version

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

/*
 * ANSI.txt@L160 :
 * Parameter     Parameter Function
 *    0            40 x 25 black and white
 *    1            40 x 25 color
 *    2            80 x 25 black and white
 *    3            80 x 25 color
 *    4            320 x 200 color
 *    5            320 x 200 black and white
 *    6            640 x 200 black and white
 *    7            wrap at end of line
 */

// Temporary -betterC fix, confirmed on DMD 2.079.0+ (Windows+linux)
// putchar is extern (D) for some stupid reason
extern (C) void putchar(int);

enum _BUFS = 127; // maximum in MS-DOS 5.0

/**
 * CLI argument splitter, supports quoting.
 * This function uses a malloc call.
 * Params:
 *   t = user input
 *   argc = argument count pointer
 * Returns: argument vector string array
 * Notes: Original function by Nuke928. Modified by dd86k.
 */
extern (C)
char** sargs(const char* t, int* argc) {
	int j, a;
	// Might move the allocation outside
	char** argv = cast(char**)malloc(_BUFS * size_t.sizeof); // sizeof(char *)
	
	size_t sl = strlen(t);

	for (int i = 0; i <= sl; ++i) {
		if (t[i] == 0 || t[i] == ' ' || t[i] == '\n') {
			argv[a] = cast(char*)malloc(i - j + 1);
			strncpy(argv[a], t + j, i - j);
			argv[a][i - j] = 0;
			while (t[i + 1] == ' ') ++i;
			j = i + 1;
			++a;
		} else if (t[i] == '\"') {
			j = ++i;
			while (t[i] != '\"' && t[i] != 0) ++i;
			if (t[i] == 0) continue;
			argv[a] = cast(char*)malloc(i - j + 1);
			strncpy(argv[a], t + j, i - j);
			argv[a][i - j] = 0;
			while(t[i + 1] == ' ') ++i;
			j = ++i;
			++a;
		}
	}
	*argc = --a;

	return argv;
}

/// Enter virtual shell
extern (C)
void EnterShell() {
	__gshared char[255] cwb; /// internal current working directory buffer
	__gshared char[_BUFS] inb; /// internal input buffer
	__gshared char** argv; /// argument vector
	__gshared int argc; /// argument count
	//TODO: Print $PROMPT
START:
	if (gcwd(cast(char*)cwb))
		printf("\n%s%% ", cast(char*)cwb);
	else // just-in-case
		fputs("\n% ", stdout);

	fgets(cast(char*)inb, _BUFS, stdin);
	if (inb[0] == '\n') goto START;

	argc = 0;
	argv = sargs(cast(char*)inb, &argc);

	//TODO: TREE, DIR
	//TODO: lowercase

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
			puts(cast(char*)cwb);
		}
		goto END;
	}
	if (strcmp(*argv, "cls") == 0) {
		Clear;
		goto END;
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
		goto END;
	}

	// E

	if (strcmp(*argv, "exit") == 0) {
		free(argv);
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
		goto END;
	}

	// M

	if (strcmp(*argv, "mem") == 0) {
		if (strcmp(argv[1], "/stats") == 0) {
			const bool ext = MEMORYSIZE > 0xA_0000; // extended?
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
				"Extended (DD-DOS)    %6dK   %6dK   %6dK\n" ~
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
		goto END;
	}

	// T

	if (strcmp(*argv, "time") == 0) {
		AH = 0x2C;
		Raise(0x21);
		printf("It is currently %02d:%02d:%02d.%02d\n", CH, CL, DH, DL);
		goto END;
	}

	// V

	if (strcmp(*argv, "ver") == 0) {
		printf("\nDD-DOS Version %s\nMS-DOS Version %d.%d\n\n",
			cast(char*)APP_VERSION, MajorVersion, MinorVersion);
		goto END;
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
		goto END;
	}
	if (strcmp(*argv, "?load") == 0) {
		if (argc > 1) {
			if (pexist(argv[1]))
				ExecLoad(argv[1]);
			else
				puts("File not found");
		} else puts("Executable required");
		goto END;
	}
	if (strcmp(*argv, "?run") == 0) {
		run;
		goto END;
	}
	if (strcmp(*argv, "?v") == 0) {
		Verbose = !Verbose;
		printf("Verbose mode: %s\n", Verbose ? "ON" : cast(char*)"OFF");
		goto END;
	}
	if (strcmp(*argv, "?p") == 0) {
		CpuSleep = !CpuSleep;
		printf("CpuSleep mode: %s\n", CpuSleep ? "ON" : cast(char*)"OFF");
		goto END;
	}
	if (strcmp(*argv, "?r") == 0) {
		print_regs;
		goto END;
	}
	if (strcmp(*argv, "?s") == 0) {
		print_stack;
		goto END;
	}
	if (strcmp(*argv, "?panic") == 0) {
		panic(PANIC_MSG_MANUAL);
		goto END;
	}
	if (strcmp(*argv, "?diag") == 0) {
		printf(
			"Current MS-DOS version: %d.%d\n" ~
			"Compiled MS-DOS version: %d.%d\n" ~
			"vDOS version: " ~ APP_VERSION ~ "\n" ~
			"Compiler: " ~ __VENDOR__ ~ " v%d\n" ~
			"C Runtime: " ~ C_RUNTIME ~ "\n" ~
			"Build type: " ~ BUILD_TYPE ~ "\n",
			MajorVersion, MinorVersion,
			DOS_MAJOR_VERSION, DOS_MINOR_VERSION,
			__VERSION__
		);
		goto END;
	}

	puts("Bad command or file name");
END:
	free(argv);
	goto START;
}

extern (C)
void print_regs() {
	printf(
`EIP=%08X  (%04X:%04X)
EAX=%08X  EBX=%08X  ECX=%08X  EDX=%08X
SP=%04X  BP=%04X  SI=%04X  DI=%04X  CS=%04X  DS=%04X  ES=%04X  SS=%04X
`,
		EIP, CS, IP,
		EAX, EBX, ECX, EDX,
		SP, BP, SI, DI, CS, DS, ES, SS
	);
	printf("FLAG=");
	if (OF) printf(" OF");
	if (DF) printf(" DF");
	if (IF) printf(" IF");
	if (TF) printf(" TF");
	if (SF) printf(" SF");
	if (ZF) printf(" ZF");
	if (AF) printf(" AF");
	if (PF) printf(" PF");
	if (CF) printf(" CF");
	printf(" (%Xh)\n", FLAG);
}

extern (C)
void print_stack() {
	puts("print_stack::Not implemented.");
}

extern (C)
void panic(immutable(char)* r) {
	enum RANGE = 20;

	printf("\n[ !! ] PANIC: %s\n\n", r);
	print_regs;
	print_stack;
	printf("CODE:");
	__gshared int i = RANGE;
	ubyte* p = cast(ubyte*)MEMORY + get_ip - 4;
	while (--i) {
		if (i == (RANGE - 5))
			printf(" <%02X>", *p);
		else
			printf(" %02X", *p);
		++p;
	}
}

/*
 * Interrupt handler (Hardware, BIOS, DOS, MS-DOS)
 */

/// Raise interrupt.
/// Params: code = Interrupt byte
extern (C)
void Raise(ubyte code) {
	debug printf("[dbug] INTERRUPT: 0x%02X\n", code);

	// REAL-MODE
	//const inum = code << 2;
	/*
	IF (inum + 3 > IDT limit)
		#GP
	IF stack not large enough for a 6-byte return information
		#SS
	*/
	push(FLAG);
	IF = TF = 0;
	push(CS);
	push(IP);
	//CS ← IDT[inum].selector;
	//IP ← IDT[inum].offset;

	// http://www.ctyme.com/intr/int.htm
	// http://www.shsu.edu/csc_tjm/spring2001/cs272/interrupt.html
	// http://spike.scu.edu.au/~barry/interrupts.html
	switch (code) {
	case 0x10: // VIDEO
		switch (AH) {
		/*
		 * VIDEO - Set cursor position.
		 * Input:
		 *   BH (Page number)
		 *   DH (Row, 0 is top)
		 *   DL (Column, 0 is top)
		 */
		case 0x02:
			SetPos(DH, DL);
			break;
		/*
		 * VIDEO - Get cursor position and size.
		 * Input:
		 *   BH (Page number)
		 * Return:
		 *   CH (Start scan line)
		 *   CL (End scan line)
		 *   DH (Row)
		 *   DL (Column)
		 */
		case 0x03:
			AX = 0;
			//DH = cast(ubyte)CursorTop;
			//DL = cast(ubyte)CursorLeft;
			break;
		/*
		 * VIDEO - Read light pen position
		 * Return:
		 *   AH (Trigger flag)
		 *   DH (Row)
		 *   DL (Column)
		 *   CH (Pixel row, modes 04h-06h)
		 *   CX (Pixel row, modes >200 rows)
		 *   BX (Pixel column)
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
		AX = MEMORYSIZE / 1024;
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
		 * Input: None
		 * Returns:
		 *   CX:DX 	Number of clock ticks since midnight
		 *   AL		Midnight flag
		 */
		case 0:

			break;
		/*
		 * Set system time by number of clock ticks since midnight
		 * Input:
		 *   CX:DX 	Number of clock ticks since midnight
		 * Returns: None
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
		 * 00h - Terminate program.
		 * Input:
		 *   CS (PSP Segment)
		 *
		 * Notes: Microsoft recommends using INT 21/AH=4Ch for DOS 2+. This
		 * function sets the program's return code (ERRORLEVEL) to 00h. Execution
		 * continues at the address stored in INT 22 after DOS performs whatever
		 * cleanup it needs to do (restoring the INT 22,INT 23,INT 24 vectors
		 * from the PSP assumed to be located at offset 0000h in the segment
		 * indicated by the stack copy of CS, etc.). If the PSP is its own parent,
		 * the process's memory is not freed; if INT 22 additionally points into the
		 * terminating program, the process is effectively NOT terminated. Not
		 * supported by MS Windows 3.0 DOSX.EXE DOS extender.
		 */
		case 0:

			break;
		/*
		 * 01h - Read character from stdin with echo.
		 * Input: None
		 * Return: AL (Character)
		 * 
		 * Notes:
		 * - ^C and ^Break are checked.
		 * - ^P toggles the DOS-internal echo-to-printer flag.
		 * - ^Z is not interpreted.
		 */
		case 1:
			//AL = cast(ubyte)ReadKey.keyCode;
			break;
		/*
		 * 02h - Write character to stdout.
		 * Input: DL (Character)
		 * Return: AL (Last character)
		 * 
		 * Notes:
		 * - ^C and ^Break are checked. (If true, INT 23)
		 * - If DL=09h on entry, in which case AL=20h is expended as blanks.
		 * - If stdout is redirected to a file, no error-checks are performed.
		 */
		case 2:
			AL = DL;
			putchar(AL);
			break;
		/*
		 * 05h - Write character to printer.
		 * Input: DL (Character)
		 * Return: None
		 *
		 * Notes:
		 * - ^C and ^Break are checked. (Keyboard)
		 * - Usually STDPRN, may be redirected under DOS 2.0+.
		 * - If the printer is busy, this function will wait.
		 */
		case 5:

			break;
		/*
		 * 06h - Direct console input/output.
		 * Input:
		 *   Output: DL (Character, DL != FFh)
		 *   Input: DL (Character, DL == FFh)
		 * Return:
		 *   Ouput: AL (Character)
		 *   Input:
		 *     ZF set if no characters are available and AL == 00h
		 *     ZF clear if a character is available and AL != 00h
		 *
		 * Notes:
		 * - ^C and ^Break are checked. (Keyboard)
		 *
		 * Input notes:
		 * - If the returned character is 00h, the user pressed a key with an
		 *     extended keycode, which will be returned by the next call of
		 *     this function
		 */
		case 6:

			break;
		/*
		 * 07h - Read character directly from stdin without echo.
		 * Input: None
		 * Return: AL (Character)
		 *
		 * Notes:
		 * - ^C/^Break are not checked.
		 */
		case 7:
			//AL = cast(ubyte)ReadKey.keyCode;
			break;
		/*
		 * 08h - Read character from stdin without echo.
		 * Input: None
		 * Return: AL (Character)
		 *
		 * Notes:
		 * - ^C/^Break are checked.
		 */
		case 8:

			break;
		/*
		 * 09h - Write string to stdout.
		 * Input: DS:DX ('$' terminated)
		 * Return: AL = 24h
		 *
		 * Notes:
		 * - ^C and ^Break are not checked.
		 */
		case 9:
			char* p = cast(char*)MEMORY + get_ad(DS, DX);
			while (*p != '$')
				putchar(*p++);

			AL = 0x24;
			break;
		/*
		 * 0Ah - Buffered input.
		 * Input: DS:DX (Pointer to BUFFER)
		 * Return: Buffer filled with used input.
		 *
		 * Notes:
		 * - ^C and ^Break are checked.
		 * - Reads from stdin.
		 *
		 * BUFFER:
		 * | Offset | Size | Description
		 * +--------+------+-----------------
		 * | 0      | 1    | Maximum characters buffer can hold
		 * | 1      | 1    | Chars actually read (except CR) (or from last input)
		 * | 2      | N    | Characters, including the final CR.
		 */
		case 0xA:

			break;
		/*
		 * 0Bh - Get stdin status.
		 * Input: None.
		 * Return:
		 *   AL = 00h if no characters are available.
		 *   AL = FFh if a character are available.
		 *
		 * Notes:
		 * - ^C and ^Break are checked.
		 */
		case 0xB:

			break;
		/*
		 * 0Ch - Flush stdin buffer and read character.
		 * Input:
		 *   AL (STDIN input function to execute after flushing)
		 *   Other registers as appropriate for the input function.
		 * Return: As appropriate for the input function.
		 *
		 * Notes:
		 * - If AL is not 1h, 6h, 7h, 8h, or Ah, the buffer is flushed and
		 *     no input are attempted.
		 */
		case 0xC:

			break;
		/*
		 * 0Dh - Disk reset.
		 * Input: None.
		 * Return: None.
		 *
		 * Notes:
		 * - Write all buffers to disk without updating directory information.
		 */
		case 0xD:

			break;
		/*
		 * 0Eh - Select default drive.
		 * Input: DL (incrementing from 0 for A:)
		 * Return: AL (number of potentially valid drive letters)
		 *
		 * Notes:
		 * - The return value is the highest drive present.
		 */
		case 0xE:

			break;
		/*
		 * 19h - Get default drive.
		 * Input: None.
		 * Return: AL (incrementing from 0 for A:)
		 */
		case 0x19:
			AL = 2; // Temporary.
			break;
		/*
		 * 25h - Set interrupt vector.
		 * Input:
		 *   AL (Interrupt number)
		 *   DS:DX (New interrupt handler)
		 * Return: None.
		 *
		 * Notes:
		 * - Preferred over manually changing the interrupt vector table.
		 */
		case 0x25:

			break;
		/*
		 * 26h - Create PSP
		 * Input: DX (Segment to create PSP)
		 * Return: AL destroyed
		 *
		 * Notes:
		 * - New PSP is updated with memory size information; INTs 22h, 23h,
		 *     24h taken from interrupt vector table; the parent PSP field
		 *     is set to 0. (DOS 2+) DOS assumes that the caller's CS is the`
		 *     segment of the PSP to copy.
		 */
		case 0x26:

			break;
		/*
		 * 2Ah - Get system date.
		 * Input: None.
		 * Return:
		 *   CX (Year, 1980-2099)
		 *   DH (Month)
		 *   DL (Day)
		 *   AL (Day of the week, Sunday = 0)
		 */
		case 0x2A:
			version (Windows) {
				import core.sys.windows.winbase : SYSTEMTIME, GetLocalTime;
				SYSTEMTIME s;
				GetLocalTime(&s);

				CX = s.wYear;
				DH = cast(ubyte)s.wMonth;
				DL = cast(ubyte)s.wDay;
				AL = cast(ubyte)s.wDayOfWeek;
			} else version (Posix) {
				import core.sys.posix.time : time_t, time, localtime, tm;
				time_t r;
				time(&r);
				const tm* s = localtime(&r);

				CX = 1900 + s.tm_year;
				DH = cast(ubyte)(s.tm_mon + 1);
				DL = cast(ubyte)s.tm_mday;
				AL = cast(ubyte)s.tm_wday;
			} else {
				static assert(0, "Implement INT 21h AH=2Ah");
			}
			break;
		/*
		 * 2Bh - Set system date.
		 * Input:
		 *   CX (Year, 1980-2099)
		 *   DH (Month)
		 *   DL (Day)
		 * Return: AL (00h if successful, FFh (invalid) if failed)
		 */
		case 0x2B:
			AL = 0xFF;
			break;
		/*
		 * 2Ch - Get system time.
		 * Input: None.
		 * Return:
		 *   CH (Hour)
		 *   CL (Minute)
		 *   DH (Second)
		 *   DL (1/100 seconds)
		 */
		case 0x2C:
			version (Windows) {
				import core.sys.windows.windows : SYSTEMTIME, GetLocalTime;
				SYSTEMTIME s;
				GetLocalTime(&s);

				CH = cast(ubyte)s.wHour;
				CL = cast(ubyte)s.wMinute;
				DH = cast(ubyte)s.wSecond;
				DL = cast(ubyte)s.wMilliseconds;
			} else version (Posix) {
				import core.sys.posix.time : tm, localtime;
				import core.sys.posix.sys.time : timeval, gettimeofday;
				//TODO: Consider moving gettimeofday(2) to clock_gettime(2)
				//      https://linux.die.net/man/2/gettimeofday
				//      gettimeofday is deprecated since POSIX.2008
				__gshared tm* s;
				__gshared timeval tv;
				gettimeofday(&tv, null);
				s = localtime(&tv.tv_sec);

				CH = cast(ubyte)s.tm_hour;
				CL = cast(ubyte)s.tm_min;
				DH = cast(ubyte)s.tm_sec;
				AL = cast(ubyte)tv.tv_usec;
			} else {
				static assert(0, "Implement INT 21h AH=2Ch");
			}
			break;
		/*
		 * 2Dh - Set system time.
		 * Input:
		 *   CH (Hour)
		 *   CL (Minute)
		 *   DH (Second)
		 *   DL (1/100 seconds)
		 * Return: AL (00h if successful, FFh if failed (invalid))
		 */
		case 0x2D:
			AL = 0xFF;
			break;
		/*
		 * 2Eh - Set verify flag.
		 * Input: AL (00 = off, 01 = on)
		 * Return: None.
		 *
		 * Notes:
		 * - Default state at boot is off.
		 * - When on, all disk writes are verified provided the device driver
		 *   supports read-after-write verification.
		 */
		case 0x2E:

			break;
		/*
		 * 30h - Get DOS version.
		 * Input: AL (00h = OEM Number in AL, 01h = Version flag in AL)
		 * Return:
		 *   AL (Major version, DOS 1.x = 00h)
		 *   AH (Minor version)
		 *   BL:CX (24-bit user serial* if DOS<5 or AL=0)
		 *   BH (MS-DOS OEM number if DOS 5+ and AL=1)
		 *   BH (Version flag bit 3: DOS is in ROM, other: reserved (0))
		 *
		 * *Most versions do not use this.
		 */
		case 0x30:
			BH = AL == 0 ? OEM_ID.IBM : 1;
			AL = MajorVersion;
			AH = MinorVersion;
			break;
		/*
		 * 35h - Get interrupt vector.
		 * Input: AL (Interrupt number)
		 * Return: ES:BX (Current interrupt number)
		 */
		case 0x35:

			break;
		/*
		 * 36h - Get free disk space.
		 * Input: DL (Drive number, e.g. A = 0, B = 1, etc.)
		 * Return:
		 *   AX (FFFFh = invalid drive)
		 * or
		 *   AX (Sectors per cluster)
		 *   BX (Number of free clusters)
		 *   CX (bytes per sector)
		 *   DX (Total clusters on drive)
		 *
		 * Notes:
		 * - Free space on drive in bytes is AX * BX * CX.
		 * - Total space on drive in bytes is AX * CX * DX.
		 * - "lost clusters" are considered to be in use.
		 * - No proper results on CD-ROMs; use AX=4402h instead.
		 */
		case 0x36:

			break;
		/*
		 * Get country specific information
		 * Input:
		 *   AL (0)
		 *   DS:DX (Buffer location, see BUFFER)
		 * Return:
		 *   CF set on error, otherwise cleared
		 *   AX (Error code, 02h)
		 *   AL (0 for current country, 1h-feh specific, ffh for >ffh)
		 *   BX (16-bit country code)
		 *     http://www.ctyme.com/intr/rb-2773.htm#Table1400
		 *   Buffer at DS:DX filled
		 *
		 * BUFFER:
		 * Offset  Size    Description
		 * 00h     WORD    date format (see #01398)
		 * 02h  5  BYTEs   ASCIZ currency symbol string
		 * 07h  2  BYTEs   ASCIZ thousands separator
		 * 09h  2  BYTEs   ASCIZ decimal separator
		 * 0Bh  2  BYTEs   ASCIZ date separator
		 * 0Dh  2  BYTEs   ASCIZ time separator
		 * 0Fh     BYTE    currency format
		 *   bit 2 = set if currency symbol replaces decimal point
		 *   bit 1 = number of spaces between value and currency symbol
		 *   bit 0 = 0 if currency symbol precedes value
		 *           1 if currency symbol follows value
		 * 10h     BYTE    number of digits after decimal in currency
		 * 11h     BYTE    time format
		 *   bit 0 = 0 if 12-hour clock
		 *       1 if 24-hour clock
		 * 12h     DWORD   address of case map routine
		 *   (FAR CALL, AL = character to map to upper case [>= 80h])
		 * 16h  2  BYTEs   ASCIZ data-list separator
		 * 18h 10  BYTEs   reserved
		 */
		case 0x38:

			break;
		/*
		 * 39h - Create subdirectory.
		 * Input: DS:DX (ASCIZ path)
		 * Return:
		 *  CF clear if sucessful (AX set to 0)
		 *  CF set on error (AX = error code (3 or 5))
		 *
		 * Notes:
		 * - All directories in the given path except the last must exist.
		 * - Fails if the parent directory is the root and is full.
		 * - DOS 2.x-3.3 allow the creation of a directory sufficiently deep
		 *     that it is not possible to make that directory the current
		 *     directory because the path would exceed 64 characters.
		 */
		case 0x39:

			break;
		/*
		 * 3Ah - Remove subdirectory.
		 * Input: DS:DX (ASCIZ path)
		 * Return: 
		 *   CF clear if successful (AX set to 0)
		 *   CF set on error (AX = error code (03h,05h,06h,10h))
		 *
		 * Notes:
		 * - Subdirectory must be empty.
		 */
		case 0x3A:

			break;
		/*
		 * 3Bh - Set current directory.
		 * Input: DS:DX (ASCIZ path (maximum 64 Bytes))
		 * Return:
		 *  CF clear if sucessful (AX set to 0)
		 *  CF set on error (AX = error code (3))
		 *
		 * Notes:
		 * - If new directory name includes a drive letter, the default drive
		 *     is not changed, only the current directory on that drive.
		 */
		case 0x3B:

			break;
		/*
		 * 3Ch - Create or truncate file.
		 * Input:
		 *   CX (File attributes, see ATTRIB)
		 *   DS:DX (ASCIZ path)
		 * Return:
		 *  CF clear if sucessful (AX = File handle)
		 *  CF set if error (AX = error code (3, 4, 5)
		 *
		 * Notes:
		 * - If the file already exists, it is truncated to zero-length.
		 *
		 * ATTRIB:
		 * | Bit         | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
		 * | Description | S | - | A | D | V | S | H | R |
		 * 7 - S = Shareable
		 *     A = Archive
		 *     D = Directory
		 *     V = Volume label
		 *     S = System
		 *     H = Hidden
		 * 0 - R = Read-only
		 */
		case 0x3C:

			break;
		/*
		 * 3Dh - Open file.
		 * Input:
		 *   AL (Access and sharing modes)
		 *   DS:DX (ASCIZ path)
		 * Return:
		 *   CF clear if successful (AX = File handle)
		 *   CF set on error (AX = error code (01h,02h,03h,04h,05h,0Ch,56h))
		 *
		 * Notes:
		 * - File pointer is set to start of file.
		 * - File handles which are inherited from a parent also inherit
		 *     sharing and access restrictions.
		 * - Files may be opened even if given the hidden or system attributes.
		 */
		case 0x3D:

			break;
		/*
		 * 3Eh - Close file.
		 * Input: BX (File handle)
		 * Return:
		 *   CF clear if successful (AX = File handle)
		 *   CF set on error (AX = error code (06h))
		 *
		 * Notes:
		 * - If the file was written to, any pending disk writes are performed,
		 *     the time and date stamps are set to the current time, and the
		 *     directory entry is updated.
		 */
		case 0x3E:

			break;
		/*
		 * 3Fh - Read from file or device.
		 * Input:
		 *   BX (File handle)
		 *   CX (Number of bytes to read)
		 *   DS:DX (Points to buffer)
		 * Return:
		 *   CF clear if successful (AX = bytes read)
		 *   CF set on error (AX = error code (05h,06h))
		 *
		 * Notes:
		 * - Data is read beginning at current file position, and the file
		 *     position is updated after a successful read.
		 * - The returned AX may be smaller than the request in CX if a
		 *     partial read occurred.
		 * - If reading from CON, read stops at first CR.
		 */
		case 0x3F:

			break;
		/*
		 * 40h - Write to file or device.
		 * Input:
		 *   BX (File handle)
		 *   CX (Number of bytes to write)
		 *   DS:DX (Points to buffer)
		 * Return:
		 *   CF clear if successful (AX = bytes read)
		 *   CF set on error (AX = error code (05h,06h))
		 *
		 * Notes:
		 * - If CX is zero, no data is written, and the file is truncated or
		 *     extended to the current position.
		 * - Data is written beginning at the current file position, and the
		 *     file position is updated after a successful write.
		 * - The usual cause for AX < CX on return is a full disk.
		 */
		case 0x40:

			break;
		/*
		 * 41h - Delete file.
		 * Input:
		 *   DS:DX (ASCIZ path)
		 *   CL (Attribute mask)
		 * Return:
		 *   CF clear if successful (AX = 0, AL seems to be drive number)
		 *   CF set on error (AX = error code (2, 3, 5))
		 *
		 * Notes:
		 * - (DOS 3.1+) wildcards are allowed if invoked via AX=5D00h, in
		 *     which case the filespec must be canonical (as returned by
		 *     AH=60h), and only files matching the attribute mask in CL are
		 *     deleted.
		 * - DOS does not erase the file's data; it merely becomes inaccessible
		 *     because the FAT chain for the file is cleared.
		 * - Deleting a file which is currently open may lead to filesystem
		 *     corruption.
		 */
		case 0x41:

			break;
		/*
		 * 42h - Set current file position.
		 * Input:
		 *   AL (0 = SEEK_SET, 1 = SEEK_CUR, 2 = SEEK_END)
		 *   BX (File handle)
		 *   CX:DX (File origin offset)
		 * Return:
		 *   CF clear if successful (DX:AX = New position (from start))
		 *   CF set on error (AX = error code (1, 6))
		 *
		 * Notes:
		 * - For origins 01h and 02h, the pointer may be positioned before the
		 *     start of the file; no error is returned in that case, but
		 *     subsequent attempts at I/O will produce errors.
		 * - If the new position is beyond the current end of file, the file
		 *     will be extended by the next write (see AH=40h).
		 */
		case 0x42:

			break;
		/*
		 * 43h - Get or set file attributes.
		 * Input:
		 *   AL (00 for getting, 01 for setting)
		 *   CX (New attributes if setting, see ATTRIB in 3Ch)
		 *   DS:DX (ASCIZ path)
		 * Return:
		 *   CF cleared if successful (CX=File attributes on getting, AX=0 on setting)
		 *   CF set on error (AX = error code (01h,02h,03h,05h))
		 *
		 * Bugs:
		 * - Windows for Workgroups returns error code 05h (access denied)
		 *     instead of error code 02h (file not found) when attempting to
		 *     get the attributes of a nonexistent file.
		 *
		 * Notes:
		 * - Setting will not change volume label or directory attribute bits,
		 *     but will change the other attribute bits of a directory.
		 * - MS-DOS 4.01 reportedly closes the file if it is currently open.
		 */
		case 0x43:

			break;
		/*
		 * 47h - Get current working directory.
		 * Input:
		 *   DL (Drive number, 0 = Default, 1 = A:, etc.)
		 *   DS:DI (Pointer to 64-byte buffer for ASCIZ path)
		 * Return:
		 *   CF cleared if successful
		 *   CF set on error code (AX = error code (Fh))
		 *
		 * Notes:
		 * - The returned path does not include a drive or the initial
		 *     backslash
		 * - Many Microsoft products for Windows rely on AX being 0100h on
		 *     success.
		 */
		case 0x47:

			break;
		/*
		 * 4Ah - Resize memory block
		 * Input:
		 *   BX (New size in paragraphs)
		 *   ES (Segment of block to resize)
		 * Return: 
		 *   CF set on error, otherwise cleared
		 *   AX error code (07h,08h,09h)
		 *   BX (Maximum paragraphs available for specified memory block)
		 *
		 * Notes:
		 * - Notes: Under DOS 2.1 to 6.0, if there is insufficient memory to
		 *     expand the block as much as requested, the block will be made
		 *     as large as possible. DOS 2.1-6.0 coalesces any free blocks
		 *     immediately following the block to be resized.
		 */
		case 0x4A:

			break;
		/*
		 * 4Bh - Load/execute program
		 * Input:
		 *   AL (see LOADTYPE)
		 *   DS:DX (ASCIZ path)
		 *   ES:BX (parameter block)
		 *   CX (Mode, only for AL=04h)
		 * Return:
		 *   CF set on error, or cleared
		 *   AX (error code (See codes.d))
		 *   BX and DX destroyed
		 */
		case 0x4B: {
			switch (AL) {
			case 0: // Load and execute the program.
				char[] p = MemString(get_ad(DS, DX));
				if (pexist(cast(char*)p)) {
					ExecLoad(cast(char*)p);
					CF = 0;
					return;
				}
				AX = E_FILE_NOT_FOUND;
				CF = 1;
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
		 * 4Ch - Terminate with return code.
		 * Input: AL (Return code)
		 * Return: None. (Never returns)
		 *
		 * Notes:
		 * - Unless the process is its own parent, all open files are closed
		 *     and all memory belonging to the process is freed.
		 */
		case 0x4C:
			--RLEVEL;
			break;
		/*
		 * 4Dh - Get return code. (ERRORLEVEL)
		 * Input: None
		 * Return:
		 *   AH (Termination type*)
		 *   AL (Code)
		 *
		 * *00 = Normal, 01 = Control-C Abort, 02h = Critical Error Abort,
		 *   03h Terminate and stay resident.
		 *
		 * Notes:
		 * - The word in which DOS stores the return code is cleared after
		 *     being read by this function, so the return code can only be
		 *     retrieved once.
		 * - COMMAND.COM stores the return code of the last external command
		 *     it executed as ERRORLEVEL.
		 */
		case 0x4D:
			
			break;
		/*
		 * 54h - Get verify flag.
		 * Input: None.
		 * Return:
		 *   AL (0 = off, 1 = on)
		 */
		case 0x54:

			break;
		/*
		 * 56h - Rename file or directory.
		 * Input:
		 *   DS:DX (ASCIZ path)
		 *   ES:DI (ASCIZ new name)
		 *   CL (Attribute mask, server call only)
		 * Return:
		 *   CF cleared if successful
		 *   CF set on error (AX = error code (02h,03h,05h,11h))
		 *
		 * Notes:
		 * - Allows move between directories on same logical volume.
		 * - This function does not set the archive attribute.
		 * - Open files should not be renamed.
		 * - (DOS 3.0+) allows renaming of directories.
		 */
		case 0x56:

			break;
		/*
		 * 57h - Get or set file's last-written time and date.
		 * Input:
		 *   AL (0 = get, 1 = set)
		 *   BX (File handle)
		 *   CX (New time (set), see TIME)
		 *   DX (New date (set), see DATE)
		 * Return (get):
		 *   CF clear if successful (CX = file's time, DX = file's date)
		 *   CF set on error (AX = error code (01h,06h))
		 * Return (set):
		 *   CF cleared if successful
		 *   CF set on error (AX = error code (01h,06h))
		 *
		 * TIME:
		 * | Bits        | 15-11 | 10-5    | 4-0     |
		 * | Description | hours | minutes | seconds |
		 * DATE:
		 * | Bits        | 15-9         | 8-5   | 4-0 |
		 * | Description | year (1980-) | month | day |
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

	IP = pop;
	CS = pop;
	IF = TF = 1;
	FLAG = pop;
}