/*
 * dd-dos.d: Operating system, shell, system and hardware interrupts handler
 */

module dd_dos;

import core.stdc.stdio;
import std.stdio : readln, toFile;
import Interpreter, Loader, ddcon, Utilities, Logger;

pragma(msg, "Compiling DD-DOS ", APP_VERSION);
pragma(msg, "Reporting MS-DOS ", DOS_MAJOR_VERSION, ".", DOS_MINOR_VERSION);

enum APP_VERSION = "0.0.0"; /// Application version
enum APP_NAME = "dd-dos"; /// Application name

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

enum DOS_MAJOR_VERSION = 5, /// Default reported major DOS version
	 DOS_MINOR_VERSION = 0; /// Default reported minor DOS version

__gshared ubyte MajorVersion = DOS_MAJOR_VERSION; /// Alterable reported major version
__gshared ubyte MinorVersion = DOS_MINOR_VERSION; /// Alterable reported minor version

/// File/Folder attribute. See INT 21h AH=3Ch
// Did you know Windows still use these values?
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

/// Enter internal shell
extern (C)
void EnterVShell() {
	import std.array : split;
	import std.uni : toUpper;
	import std.file : getcwd, chdir, FileException;

_S:
	//write(getcwd ~ '$');
	//TODO: Print POMPT
	printf(">");

	// Read line from stdln and remove \n, then split arguments.
	string[] argv = split(readln()[0..$-1], ' ');
	const size_t argc = argv.length;

	if (argc > 0)
	switch (toUpper(argv[0])) {
	case "HELP": //TODO: /ALL should print info for "??"
		puts("CD        Change working directory");
		puts("CLS       Clear screen");
		puts("DATE      Get current date");
		puts("DIR       Show directory content");
		puts("EXIT      Exit DD-DOS or script");
		puts("TREE      Show directory structure");
		puts("TIME      Get current time");
		puts("MEM       Show memory information");
		puts("VER       Show DOS version");
		puts("\n??  Print debugger help screen");
		break;
	case "VER":
		if (argc > 1) {
			switch (toUpper(argv[1])) { //toUpper in-case of future sub commands
			case "/?":
				break;
			default:
			}
		} else {
			printf("\nDD-DOS Version %s\n", cast(char*)APP_VERSION);
			printf("MS-DOS Version %d.%d\n\n", MajorVersion, MinorVersion);
		}
		break;
	case "MEM":
		if (argc > 1) {
			switch (toUpper(argv[1])) {
			case "/STATS":
				puts("Fetching memory statistics...");

				const bool ext = MEMORYSIZE > 0xA_0000; // extended?
				const size_t ct = ext ? 0xA_0000 : MEMORYSIZE;
				const size_t tt = MEMORYSIZE - ct;

				int nzt; // Non-zero (total/excluded from conventional in some cases)
				int nzc; // Convential (<640K) non-zero
				for (int i; i < 0xA_0000; ++i) {
					if (i < 0xA_0000) {
						if (MEMORY[i]) ++nzc;
					} else if (MEMORY[i]) ++nzt;
				}
				puts("Memory type          Zero'd  +   NZero  =  Total");
				puts("-------------------  -------   -------   -------");
				printf("Conventional         %6dK   %6dK   %6dK\n",
					(ct - nzc) / 1024, nzc / 1024, ct / 1024);
				printf("Extended (DD-DOS)    %6dK   %6dK   %6dK\n",
					(tt - nzt) / 1024, nzt / 1024, tt / 1024);
				puts("-------------------  -------   -------   -------");
				printf("Total                %6dK   %6dK   %6dK\n",
					(MEMORYSIZE - nzt) / 1024, (nzt + nzc) / 1024, MEMORYSIZE / 1024);
				break;
			case "/DEBUG":
				puts("Not implemented");
				break;
			//case "/FREE":
			case "/?":
				puts("Display memory statistics");
				puts("  MEM [OPTIONS]\n");
				puts("OPTIONS");
				puts("/DEBUG    Not implemented");
				puts("/FREE     Not implemented");
				puts("/STATS    Scan memory and show statistics");
				break;
			default:

				break;
			}
		}
		break;
	case "CHDIR", "CD":
		if (argc > 1)
			try {
				if (argv[1] == "/?") {
					puts("Display or set current working directory.");
				} else chdir(argv[1]);
			} catch (FileException) {
				puts("Invalid directory");
			}
		else
			puts(cast(char*)(getcwd~'\0'));
		break;
	case "DIR": { //TODO: with folder arguemnt
		import std.file : exists, isDir, dirEntries, SpanMode;
		string dir;
		if (argc > 1) {
			switch (argv[1]) {
			case "/?":
				puts("List files and directories");
				break;
			default:
				if (exists(argv[1])) {
					if (isDir(argv[1]))
						dir = argv[1];
					else {
						puts("ERROR: Invalid path");
						AL = 2;
						goto _S;
					}
				} else {
					puts("ERROR: Invalid path");
					AL = 1;
					goto _S;
				}
				break;
			}
		}
		int c;
		foreach (string name; dirEntries(dir, SpanMode.shallow)) {
			++c;
			if (isDir(name))
				printf("%*s <DIR>\n", -32, cast(char*)(name~'\0'));
			else
				puts(cast(char*)(name~'\0'));
		}
		printf("        %d file(s)\n", c);
		break;
	}
	case "TIME":
		AH = 0x2C;
		Raise(0x21);
		printf("It is currently %02d:%02d:%02d,%02d\n", CH, CL, DH, DL);
		break;
	case "DATE":
		AH = 0x2A;
		Raise(0x21);
		printf("It is currently ");
		final switch (AL) {
		case 0, 7: printf("Sun"); break;
		case 1: printf("Mon"); break;
		case 2: printf("Tue"); break;
		case 3: printf("Wed"); break;
		case 4: printf("Thu"); break;
		case 5: printf("Fri"); break;
		case 6: printf("Sat"); break;
		}
		printf(" %d-%02d-%02d\n", CX, DH, DL);
		break;
	case "TREE": {
		import std.file : exists, isDir, dirEntries, SpanMode;
		string dir;
		if (argc > 1) {
			switch (argv[1]) {
			case "/?":
				puts("Displays a graphical representation of a folder recursively");
				puts("Usage:");
				puts("  TREE [OPTIONS]");
				return;
			default:
				if (exists(argv[1])) {
					if (isDir(argv[1]))
						dir = argv[1];
					else {
						puts("ERROR: Invalid path");
						AL = 2;
						goto _S;
					}
				} else {
					puts("ERROR: Invalid path");
					AL = 1;
					goto _S;
				}
				break;
			}
		}

		void printlevel(int l) {
			do {
				printf("+--");
			} while (--l);
		}

		int j = 1;
		puts(".");
		void tree(string d) { // C: goto+var
			foreach (string name; dirEntries(d, SpanMode.shallow)) {
				printlevel(j);
				puts(cast(char*)(name~'\0'));
				if (isDir(name)) {
					++j;
					tree(name);
				}
			}
			--j;
		}
		tree(dir); // cd
		break;
	}
	case "CLS": Clear; break;
	case "EXIT": return;

	// DEBUGGING COMMANDS

	case "?LOAD":
		if (argc > 1) // Is a file provided?
			LoadExec(argv[1]);
		break;
	case "?RUN": Run; break;
	case "?V":
		Verbose = !Verbose;
		printf("Verbose?: %s\n", Verbose ? "ON" : cast(char*)"OFF");
		break;
	case "?p":
		Sleep = !Sleep;
		printf("Sleep?: %s\n", Sleep ? "ON" : cast(char*)"OFF");
		break;
	/*case "?DUMP":
		//toFile(MEMORY, "MEMDUMP");
		//puts("Memory dumped to MEMDUMP");
		puts("TODO");
		break;*/
	case "?R":
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
		break;
	case "??":
		puts("?run        Start the interpreter");
		puts("?load FILE  Load an executable file");
		//puts("?dump    Dump memory content to MEMDUMP");
		puts("?r          Print vm register information");
		puts("?p          Toggle performance mode");
		puts("?v          Toggle verbose mode");
		break;
	default:
		puts("Bad command or file name");
		break;
	}
	goto _S;
}

/**
 * Make the Program Segment Prefix in memory
 * Params:
 *   l = Memory location
 *   appname = Application name
 *   args = Application arguments
 */
void MakePSP(uint l, string appname, string args = null) {
	MEMORY[l + 0x40] = MajorVersion;
	MEMORY[l + 0x41] = MinorVersion;
	size_t len = appname.length;
	if (args)
		len += args.length + 1;
	MEMORY[l + 0x80] = len > 0xFF ? 0xFF : cast(ubyte)len;
	ubyte* pbank = &MEMORY[l] + 0x81;
	size_t i;
	foreach (b; appname) pbank[i++] = b;
	if (args) {
		pbank[i++] = ' '; // Space
		foreach (b; args) pbank[i++] = b;
	}
	pbank[i] = '\0';
}

/*
 * Interrupt handler (Hardware, BIOS, DOS, MS-DOS)
 */

/// Raise interrupt.
/// Params: code = Interrupt byte
extern (C)
void Raise(ubyte code) { // Rest of this source is this function
	debug loghb("INTERRUPT: 0x", code, Log.Debug);

	// REAL-MODE
	//const inum = code << 2;
	/*
	IF (inum + 3 > IDT limit)
		#GP
	IF stack not large enough for a 6-byte return information
		#SS
	*/
	Push(FLAG);
	IF = TF = 0;
	Push(CS);
	Push(IP);
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
		//TODO: Figure out page (Buffer?)
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
		default: break;
		}
		break;
	case 0x11: { // BIOS - Get equipement list
		// Number of 16K banks of RAM on motherboard (PC only).
		int ax = 0b10000; // VGA
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
		AX = cast(int)(MEMORYSIZE / 1024);
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

		default: break;
		}
		break;
	case 0x17: // PRINTER

		break;
	case 0x1A: // TIME
		switch (AH) {
		case 0: // Get system time
		// CX:DX (Number of clock ticks since midnight)
		// AL (Midnight flag)

			break;
		case 1: // Set system time
		// CX:DX (Number of clock ticks since midnight)
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
			AL = cast(ubyte)ReadKey.keyCode;
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
			printf("%c", AL);
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
			AL = cast(ubyte)ReadKey.keyCode;
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
			uint pd = GetAddress(DS, DX);

			version (LittleEndian) {
				char* p = cast(char*)MEMORY + pd;
				while (*p != '$')
					printf("%c", *p++);
			} else {
				while (MEMORY[pd] != '$')
					printf("%c", MEMORY[pd++]);
			}

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
			version (Windows)
			{
				import core.sys.windows.winbase : SYSTEMTIME, GetLocalTime;
				SYSTEMTIME s;
				GetLocalTime(&s);

				CX = s.wYear;
				DH = cast(ubyte)s.wMonth;
				DL = cast(ubyte)s.wDay;
				AL = cast(ubyte)s.wDayOfWeek;
			}
			else version (Posix)
			{
				import core.sys.posix.time : time_t, time, localtime, tm;
				time_t r;
				time(&r);
				const tm* s = localtime(&r);

				CX = 1900 + s.tm_year;
				DH = cast(ubyte)(s.tm_mon + 1);
				DL = cast(ubyte)s.tm_mday;
				AL = cast(ubyte)s.tm_wday;
			}
			else
			{
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
				import core.sys.posix.time : tm, time_t, time, localtime;
				import core.time : timeval, gettimeofday;
				//TODO: Only use gettimeofday
				time_t r; tm* s;
				time(&r);
				s = localtime(&r);

				CH = cast(ubyte)s.tm_hour;
				CL = cast(ubyte)s.tm_min;
				DH = cast(ubyte)s.tm_sec;
				timeval tv;
				gettimeofday(&tv, null);
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

			break;
		/*
		 * 2Eh - Set verify flag.
		 * Input: AL (00 = off, 01 = on)
		 * Return: None.
		 *
		 * Notes:
		 * - Default state at boot is off.
		 * - When on, all disk writes are verified provided the device driver
		 *     supports read-after-write verification.
		 */
		case 0x2E:

			break;
		/*
		 * 30h - Get DOS version.
		 * Input: AL (00h = OEM Number in AL, 01h = Version flag in AL)
		 * Return:
		 *   AL (Major version, DOS 1.x = 00h)
		 *   AH (Minor version)
		 *   BL:CX (24bit user serial* if DOS<5 or AL=0)
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
		 * Input: DL (Drive number, A: = 0)
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
		 * http://www.ctyme.com/intr/rb-2773.htm#Table1399
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
		case 0x39: {
			import std.file : mkdir;
			string path = MemString(cast(void*)MEMORY, GetAddress(DS, DX));
			version (Windows)
			{
				import std.windows.syserror : WindowsException;
				try {
					mkdir(path);
					CF = 0;
				} catch (WindowsException) {
					CF = 1;
					AX = 3;
				}
			}
			else version (Posix)
			{
				import std.file : FileException;
				try {
					mkdir(path);
					CF = 0;
				} catch (FileException) {
					CF = 1;
					AX = 3;
				}
			}
		}
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
		case 0x3A: {
			import std.file : rmdir;
			string path = MemString(cast(void*)MEMORY, GetAddress(DS, DX));
			version (Windows)
			{
				import std.windows.syserror : WindowsException;
				try {
					rmdir(path);
					CF = 0;
				} catch (WindowsException) {
					CF = 1;
					AX = 3;
				}
			}
			else version (Posix)
			{
				import std.file : FileException;
				try {
					rmdir(path);
				} catch (FileException) {
					AX = 3;
				}
			}
		}
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
		case 0x3C: {
			import std.stdio : toFile;
			import std.file : setAttributes;
			enum EMPTY = cast(ubyte[])null;
			string path = MemString(cast(void*)MEMORY, GetAddress(DS, DX));
			uint at; // VOLLABEL and DIRECTORY are ignored here
			version (Windows) // 1:1 MS-DOS<->Windows
			{ // https://msdn.microsoft.com/en-us/library/gg258117(v=vs.85).aspx
				if (CL & READONLY) at |= READONLY;
				if (CL & HIDDEN)   at |= HIDDEN;
				if (CL & SYSTEM)   at |= SYSTEM;
				if (CL & ARCHIVE)  at |= ARCHIVE;
			}
			else version (Posix)
			{ // http://pubs.opengroup.org/onlinepubs/7908799/xsh/sysstat.h.html
				import core.sys.posix.sys.stat; // (st_mode)
				enum WRITE = S_IWUSR | S_IWGRP | S_IWOTH,
					 READ  = S_IRUSR | S_IRGRP | S_IROTH;
				at = (CL & READONLY) ? READ : READ | WRITE;
			}
			toFile(EMPTY, path);
			setAttributes(path, at);
		}
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
		case 0x41: {
			import std.file : remove, FileException;
			string path = MemString(cast(void*)MEMORY, GetAddress(DS, DX));
			try
			{
				remove(path);
				CF = 0;
				AX = 0;
				//AL =
			}
			catch (FileException)
			{
				CF = 1;
				AX = 2;
			}
			break;
		}
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
		/*case 0x4A:

			break;*/
		/*
		 * 4Bh - Load/execute program
		 * Input:
		 *   AL (see LOADTYPE)
		 *   DS:DX (ASCIZ path)
		 *   ES:BX (parameter block)
		 *   CX (Mode, only for AL=04h)
		 * Return:
		 *   CF set on error, or cleared
		 *   AX (error code (01h,02h,05h,08h,0Ah,0Bh))
		 *   BX and DX destroyed
		 */
		case 0x4B: {
		//TODO: (Load/Execute) INT 21h AH=4Bh
			//string path = MemString(cast(void*)MEMORY, GetAddress(DS, DX));
			//LoadFile(path);
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
		//TODO: Level count
			Running = false;
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
		printf("%c", AL);
		break;
	default: break;
	}

	IP = Pop();
	CS = Pop();
	IF = TF = 1;
	FLAG = Pop();
}