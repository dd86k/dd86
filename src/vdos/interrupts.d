/**
 * interrupts: Interrupt handler (Hardware, BIOS, DOS, vDOS)
 *
 * This module lays in-between the virtual processor and the OS functions
 */
module vdos.interrupts;

import ddc;
import vcpu.core;
import vcpu.utils : address;
import vdos.os;
import vdos.loader;
import vdos.structs;
import vdos.video;
import vcpu.mm : mmfstr;
import os.io : OSTime, os_time, OSDate, os_date, os_pexist;
import err;

extern (C):

enum : ubyte {
	// CPU interrupt numbers
	INT_CPU_DE,	/// #DE: Divide Error Exception
	INT_CPU_DB,	/// #DB: Debug Exception
	INT_CPU_NMI,	/// Non-Maskable Interrupt
	INT_CPU_BP,	/// #BP: Breakpoint Exception
	INT_CPU_OF,	/// #OF: Overflow Exception
	INT_CPU_BR,	/// #BR: Bound Range Exception
	INT_CPU_UD,	/// #UD: Invalid Opcode
	INT_CPU_NM,	/// #NM: Device Not Available Exception
	INT_CPU_DF,	/// #DF: Double Fault Exception
	INT_CPU_CPSO,	/// Co-processor Segment Overrun
	INT_CPU_TS,	/// #TS: Invalid TSS Exception
	INT_CPU_NP,	/// #NP: Missing Segment
	INT_CPU_SS,	/// #SS: Stack Fault
	INT_CPU_GP,	/// #GP: General Protection Exception
	INT_CPU_PF,	/// #PF: Page Fault

	// IBM interrupt numbers
	INT_M_PRINT_SCRN = INT_CPU_BR,	/// IBM: Print Screen
	INT_M_IRQ0 = INT_CPU_DF,	/// IBM: IRQ0 System Timer
	INT_M_IRQ1 = INT_CPU_CPSO,	/// IBM: IRQ1 Keyboard Event
	INT_M_IRQ3 = INT_CPU_NP,	/// IBM: IRQ3 Serial Comms (COM0)
	INT_M_IRQ4 = INT_CPU_SS,	/// IBM: IRQ4 Serial Comms (COM1)
	INT_M_IRQ5 = INT_CPU_GP,	/// IBM: IRQ5 Disk Interface
	INT_M_IRQ6 = INT_CPU_PF,	/// IBM: IRQ6 Diskette Interface
	INT_M_IRQ7 = 0x0F,	/// IBM: IRQ6 Printer Interface

	// BIOS
	INT_BIOS_VIDEO = 0x10,
	INT_BIOS_EQUIP_CHECK,
	INT_BIOS_MEMSIZE,
	INT_BIOS_DISK,
	INT_BIOS_COM,
	INT_BIOS_KB,
	INT_BIOS_PRINTER,
	INT_BIOS_BOOTSTRAP = 0x19,
	INT_BIOS_SYSTIME,
	INT_BIOS_CTRL_ALT_DEL,
	INT_BIOS_TIMER_TICK,
	INT_BIOS_VIDEO_PARAMS,
	INT_BIOS_DISKETTE_PARAMS,
	INT_BIOS_VIDEO_CHARS,
	INT_BIOS_DISK_PARAMS = 0x41,

	// DOS
	INT_DOS_TERMINATE = 0x20,
	INT_DOS_SERVICE,	/// MS-DOS Service
	INT_DOS_TERMINATION_ADDRESS,
	INT_DOS_CTRL_C_BREAK,
	INT_DOS_CRIT_ERR,
	INT_DOS_ABS_DISK_READ,
	INT_DOS_ABS_DISK_WRITE,
	INT_DOS_TSR,	/// Terminate and Stay Resident
	INT_DOS_IDLE,	/// Idle interrupt
	INT_DOS_CON_OUT,	/// "Fast" console output
	INT_DOS_COMM = 0x2E,	/// Pass command to command interpreter
	INT_DOS_MULTIPLEX,	/// DOS Multiplex Interrupt
}

void __int_enter() { // REAL-MODE
	//const inum = code << 2;
	/*IF (inum + 3 > IDT limit)
		#GP
	IF stack not large enough for a 6-byte return information
		#SS*/
	CPU.push16(CPU.FLAGS);
	CPU.push16(CPU.CS);
	CPU.push16(CPU.IP);
	CPU.IF = CPU.TF = CPU.RF = 0;
	//CS ← IDT[inum].selector;
	//IP ← IDT[inum].offset;
}

void __int_exit() { // REAL-MODE
	CPU.IP = CPU.pop16;
	CPU.CS = CPU.pop16;
	CPU.FLAGS = CPU.pop16;
	CPU.IF = CPU.TF = CPU.RF = 1;
}

/// Raise and handle interrupt. This includes pre and post phases for interrupt
/// phases.
/// Params: code = Interrupt byte
void INT(ubyte code) {
	debug video_printf("[dbug] INTERRUPT: %02Xh\n", code);

	__int_enter;

	switch (code) { //TODO: Call usercode from IVT
	case 0x00: // #DE
	
		break;
	case 0x01: // #DB
	
		break;
	case 0x02: // NMI
	
		break;
	case 0x03: // #BP
	
		break;
	case 0x04: // #OF
	
		break;
	case 0x05: // #BR or Print Screen
	
		break;
	case 0x06: // #UD
	
		break;
	case 0x07: // #NM
	
		break;
	case 0x08: // #DF or IRQ0 System Timer
	
		break;
	case 0x09: // Coprocessor overrun or IRQ1 Keyboard Event
	
		break;
	case 0x0A: // #TS
	
		break;
	case 0x0B: // #NP or IRQ3 COM2
	
		break;
	case 0x0C: // #SS or IRQ4 COM1
	
		break;
	case 0x0D: // #GP or IRQ5 Disk driver
	
		break;
	case 0x0E: // #PF or IRQ6 Diskette driver
	
		break;
	case 0x0F: // IRQ7 Printer driver
	
		break;
	case 0x10: // VIDEO
		switch (CPU.AH) {
		case 0: // Set video mode

			break;
		case 0x01: // Set text-mode cursor shape

			break;
		case 0x02: // Set cursor position
			/*SYSTEM.screen_page = CPU.BL > 8 ? 0 : CPU.BH;
			CURSOR* c = &SYSTEM.cursor[SYSTEM.screen_page];
			c.row = CPU.DH; //TODO: Check against system rows/columns current size
			c.col = CPU.DL;*/
			video_curpos(CPU.DL, CPU.DH, CPU.BL > 8 ? 0 : CPU.BH);
			video_updatecur;
			break;
		case 0x03: // Get cursor position and size
			const CURSOR c = SYSTEM.cursor[SYSTEM.screen_page];
			CPU.AX = SYSTEM.screen_page; //TODO: Check if graphical mode
			CPU.DH = c.row;
			CPU.DL = c.col;
			break;
		case 0x04: // Read light pen position

			break;
		case 0x06: // Select display page

			break;
		default:
		}
		break;
	case 0x11: // BIOS - Get equipement list
		CPU.AX = SYSTEM.equip_flag;
		break;
	case 0x12: // BIOS - Get memory size (KB)
		CPU.AX = SYSTEM.memsize;
		break;
	case 0x13: // DISK operations

		break;
	case 0x14: // SERIAL

		break;
	case 0x16: // Keyboard
		switch (CPU.AH) {
		case 0: // Get keystroke

			break;
		case 1: // Check keystroke

			break;
		case 2: // SHIFT
			// Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
			// Des | I | C | N | S | A | C | L | R
			// Insert, Capslock, Numlock, Scrolllock, Alt, Ctrl, Left, Right
			// CPU.AL = (flag)
			break;
		default:
		}
		break;
	case 0x17: // PRINTER

		break;
	case 0x1A: // TIME
		switch (CPU.AH) {
		case 0: // Get system time by number of clock ticks since midnight
			OSTime t = void;
			os_time(t);
			float bt = cast(float)t.second;
			bt += cast(float)t.minute * 60f;
			bt += cast(float)t.hour * 3600f;
			bt /= BIOS_TICK;
			const uint c = cast(uint)bt;
			CPU.CS = c >> 16;
			CPU.DX = cast(ushort)c;
			break;
		case 1: // Set system time by number of clock ticks since midnight
			break;
		default:
		}
		break;
	case 0x1B: // CTRL-BREAK handler

		break;
	case 0x20: // Terminate program
		--CPU.level;
		break;
	case 0x21: // MS-DOS Services
		switch (CPU.AH) {
		case 0: // Terminal program
			--CPU.level;
			break;
		case 1: // Read character from stdin with echo
			//CPU.AL = cast(ubyte)ReadKey.keyCode;
			break;
		case 2: // Write character to stdout
			CPU.AL = CPU.DL;
			video_putc(CPU.AL);
			break;
		case 5: // Write character to printer

			break;
		case 6: // Direct console input/output
			if (CPU.DL == 0xFF) { // input

			} else { // output
				CPU.AL = CPU.DL;
				video_putc(CPU.AL);
			}
			break;
		case 7: // Read character directly from stdin without echo
			//CPU.AL = cast(ubyte)ReadKey.keyCode;
			break;
		case 8: // Read character from stdin without echo

			break;
		case 9: { // Write string to stdout
			//TODO: Use mmstr
			char *p = cast(char *)(MEM + address(CPU.DS, CPU.DX));
			ushort l;
			while (p[l] != '$' && l < 255) ++l;
			video_write(p, l);

			CPU.AL = 0x24;
			break;
		}
		case 0xA: // Buffered input

			break;
		case 0xB: // Get stdin status

			break;
		case 0xC: // Flush stdin buffer and read character

			break;
		case 0xD: // Disk reset

			break;
		case 0xE: // Select default drive

			break;
		case 0x19: // Get default drive
			CPU.AL = 2; // Temporary.
			break;
		case 0x25: // Set interrupt vector

			break;
		case 0x26: // Create PSP

			break;
		case 0x2A: { // Get system date
			OSDate d = void;
			os_date(d); // os.io
			CPU.CX = d.year;
			CPU.DH = d.month;
			CPU.DL = d.day;
			CPU.AL = d.weekday;
			break;
		}
		case 0x2B: // Set system date
			CPU.AL = 0xFF;
			break;
		case 0x2C: { // Get system time
			OSTime t = void;
			os_time(t); // os.io
			CPU.CH = t.hour;
			CPU.CL = t.minute;
			CPU.DH = t.second;
			CPU.DL = t.millisecond;
			break;
		}
		case 0x2D: // Set system time
			CPU.AL = 0xFF;
			break;
		case 0x2E: // Set verify flag
			CPU.AL = 1;
			break;
		case 0x30: // Get DOS version
			CPU.BH = CPU.AL == 0 ? OEM_ID.IBM : 0;
			CPU.AL = MajorVersion;
			CPU.AH = MinorVersion;
			break;
		case 0x35: // Get interrupt vector

			break;
		case 0x36: // Get free disk space

			break;
		case 0x38: // Get country specific information

			break;
		case 0x39: // Create subdirectory

			break;
		case 0x3A: // Remove subdirectory

			break;
		case 0x3B: // Set current directory

			break;
		case 0x3C: // Create or truncate file

			break;
		case 0x3D: // Open file

			break;
		case 0x3E: // Close file

			break;
		case 0x3F: // Read from file or device

			break;
		case 0x40: // Write to file or device

			break;
		case 0x41: // Delete file

			break;
		case 0x42: // Set current file position

			break;
		case 0x43: // Get or set file attributes

			break;
		case 0x47: // Get current working directory

			break;
		case 0x4A: // Resize memory block

			break;
		case 0x4B: { // Load/execute program
			switch (CPU.AL) {
			case 0: // Load and execute the program.
				const(char) *p = mmfstr(address(CPU.DS, CPU.DX));
				if (p == null) {
					//TODO: INT(#GP)
					CPU.AX = EDOS_FILE_NOT_FOUND;
					CPU.CF = 1;
					break;
				}
				if (p && os_pexist(p)) {
					vdos_load(p);
					CPU.CF = 0;
				} else {
					CPU.AX = EDOS_FILE_NOT_FOUND;
					CPU.CF = 1;
				}
				break;
			case 1: // Load, create the program header but do not begin execution.

				CPU.CF = 1;
				break;
			case 3: // Load overlay. No header created.

				CPU.CF = 1;
				break;
			default:
				CPU.AX = EDOS_INVALID_FUNCTION;
				CPU.CF = 1;
				break;
			}
			break;
		}
		case 0x4C: // Terminate with return code
			--CPU.level;
			DOS.errorlevel = CPU.AL;
			break;
		case 0x4D: // Get return code (ERROCPU.level)
			
			break;
		case 0x54: // Get verify flag

			break;
		case 0x56: // Rename file or directory

			break;
		case 0x57: // Get/set file's last-written time and date

			break;
		default:
		}
		break; // End MS-DOS Services
	case 0x27: // TERMINATE AND STAY RESIDANT

		break;
	case 0x29: // FAST CONSOLE OUTPUT
		video_putc(CPU.AL);
		break;
	default:
		//TODO: Handle incorrect interrupt vector
	}

	__int_exit;
}