/*
 * Interrupt handler (Hardware, BIOS, DOS, vDOS)
 */
 
module vdos_int;

import ddc;
import vcpu : vCPU, MEMORY, get_ad, RLEVEL;
import vcpu_utils : __int_enter, __int_exit;
import vdos : SYSTEM, DOS, BIOS_TICK, MinorVersion, MajorVersion, OEM_ID;
import vdos_codes;
import vdos_loader : vdos_load;
import vdos_structs : __cpos;
import ddcon;
import os_utils;
import utils : MemString;

/// Raise interrupt.
/// Params: code = Interrupt byte
extern (C)
void INT(ubyte code) {
	debug printf("[dbug] INTERRUPT: %02Xh\n", code);

	__int_enter;

	switch (code) {
	case 0x10: // VIDEO
		switch (vCPU.AH) {
		case 0: // Set video mode

			break;
		case 0x01: // Set text-mode cursor shape

			break;
		case 0x02: // Set cursor position
			SYSTEM.screen_page = vCPU.BL > 8 ? 0 : vCPU.BH;
			__cpos* pos = &SYSTEM.cursor[SYSTEM.screen_page];
			pos.row = vCPU.DH; //TODO: Check against system rows/columns current size
			pos.col = vCPU.DL;
			SetPos(pos.row, pos.col);
			break;
		case 0x03: // Get cursor position and size
			vCPU.AX = SYSTEM.screen_page; //TODO: Check if graphical mode
			//vCPU.DH = cast(ubyte)CursorTop;
			//vCPU.DL = cast(ubyte)CursorLeft;
			break;
		case 0x04: // Read light pen position

			break;
		case 0x06: // Select display page

			break;
		default:
		}
		break;
	case 0x11: // BIOS - Get equipement list
		vCPU.AX = SYSTEM.equip_flag;
		break;
	case 0x12: // BIOS - Get memory size (KB)
		vCPU.AX = SYSTEM.memsize;
		break;
	case 0x13: // DISK operations

		break;
	case 0x14: // SERIAL

		break;
	case 0x16: // Keyboard
		switch (vCPU.AH) {
		case 0:

			break;
		case 1:

			break;
		case 2: // SHIFT
			// Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
			// Des | I | C | N | S | A | C | L | R
			// Insert, Capslock, Numlock, Scrolllock, Alt, Ctrl, Left, Right
			// vCPU.AL = (flag)
			break;
		default:
		}
		break;
	case 0x17: // PRINTER

		break;
	case 0x1A: // TIME
		switch (vCPU.AH) {
		case 0: // Get system time by number of clock ticks since midnight
			OSTime t = void;
			os_time(&t);
			uint c = cast(uint)( //TODO: FIXME
				((cast(float)t.hour * 60 * 60) +
				(cast(float)t.minute * 60) +
				cast(float)t.second) * BIOS_TICK
			);
			vCPU.CS = c >> 16;
			vCPU.DX = cast(ushort)c;
			break;
		case 1: // Set system time by number of clock ticks since midnight
			break;
		default:
		}
		break;
	case 0x1B: // CTRL-BREAK handler

		break;
	case 0x20: // Terminate program
		--RLEVEL;
		break;
	case 0x21: // MS-DOS Services
		switch (vCPU.AH) {
		case 0: // Terminal program
			--RLEVEL;
			break;
		case 1: // Read character from stdin with echo
			//vCPU.AL = cast(ubyte)ReadKey.keyCode;
			break;
		case 2: // Write character to stdout
			vCPU.AL = vCPU.DL;
			putchar(vCPU.AL);
			break;
		case 5: // Write character to printer

			break;
		case 6: // Direct console input/output
			if (vCPU.DL == 0xFF) { // input

			} else { // output
				vCPU.AL = vCPU.DL;
				putchar(vCPU.AL);
			}
			break;
		case 7: // Read character directly from stdin without echo
			//vCPU.AL = cast(ubyte)ReadKey.keyCode;
			break;
		case 8: // Read character from stdin without echo

			break;
		case 9: { // Write string to stdout
			ubyte limit = 255;
			char* p = cast(char*)(MEMORY + get_ad(vCPU.DS, vCPU.DX));
			while (*p != '$' && --limit > 0)
				putchar(*p++);

			vCPU.AL = 0x24;
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
			vCPU.AL = 2; // Temporary.
			break;
		case 0x25: // Set interrupt vector

			break;
		case 0x26: // Create PSP

			break;
		case 0x2A: { // Get system date
			OSDate d = void;
			os_date(&d); // os_utils
			vCPU.CX = d.year;
			vCPU.DH = d.month;
			vCPU.DL = d.day;
			vCPU.AL = d.weekday;
			break;
		}
		case 0x2B: // Set system date
			vCPU.AL = 0xFF;
			break;
		case 0x2C: { // Get system time
			OSTime t = void;
			os_time(&t); // os_utils
			vCPU.CH = t.hour;
			vCPU.CL = t.minute;
			vCPU.DH = t.second;
			vCPU.DL = t.millisecond;
			break;
		}
		case 0x2D: // Set system time
			vCPU.AL = 0xFF;
			break;
		case 0x2E: // Set verify flag
			vCPU.AL = 1;
			break;
		case 0x30: // Get DOS version
			vCPU.BH = vCPU.AL == 0 ? OEM_ID.IBM : 0;
			vCPU.AL = MajorVersion;
			vCPU.AH = MinorVersion;
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
			switch (vCPU.AL) {
			case 0: // Load and execute the program.
				char[] p = MemString(get_ad(vCPU.DS, vCPU.DX));
				if (os_pexist(cast(char*)p)) {
					vdos_load(cast(char*)p);
					vCPU.CF = 0;
				} else {
					vCPU.AX = EDOS_FILE_NOT_FOUND;
					vCPU.CF = 1;
				}
				break;
			case 1: // Load, create the program header but do not begin execution.

				vCPU.CF = 1;
				break;
			case 3: // Load overlay. No header created.

				vCPU.CF = 1;
				break;
			default:
				vCPU.AX = EDOS_INVALID_FUNCTION;
				vCPU.CF = 1;
				break;
			}
			break;
		}
		case 0x4C: // Terminate with return code
			--RLEVEL;
			DOS.ERRORLEVEL = vCPU.AL;
			break;
		case 0x4D: // Get return code (ERRORLEVEL)
			
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
		putchar(vCPU.AL);
		break;
	default:
	}

	__int_exit;
}