/*
 * Interrupt handler (Hardware, BIOS, DOS, vDOS)
 */
 
module vdos_int;

import ddc;
import vcpu : vCPU, MEMORY, MEMORYSIZE, get_ad, RLEVEL;
import vcpu_utils : __int_enter, __int_exit;
import vdos : DOS, MinorVersion, MajorVersion, OEM_ID;
import vdos_codes;
import vdos_loader : vdos_load;
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
		/*
		 * VIDEO - Set cursor position
		 */
		case 0x02:
			SetPos(vCPU.DH, vCPU.DL);
			break;
		/*
		 * VIDEO - Get cursor position and size
		 */
		case 0x03:
			vCPU.AX = 0;
			//vCPU.DH = cast(ubyte)CursorTop;
			//vCPU.DL = cast(ubyte)CursorLeft;
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
		int r = 0b10000; // VGA //TODO: CHECK ON VIDEO MODE!
		/*if (FloppyDiskInstalled) {
			ax |= 1;
			// Bit 6-7 = Number of floppy drives
			ax |= 0b10
		}*/
		//if (PenInstalled) ax |= 0b100;
		vCPU.AX = cast(ushort)r;
		break;
	}
	case 0x12: // BIOS - Get memory size
		vCPU.AX = cast(ushort)(MEMORYSIZE / 1024);
		break;
	case 0x13: // DISK operations

		break;
	case 0x14: // SERIAL

		break;
	case 0x16: // Keyboard
		switch (vCPU.AH) {
		case 0, 1: { // Get/Check keystroke
			/*const KeyInfo k = ReadKey;
			vCPU.AH = cast(ubyte)k.scanCode;
			vCPU.AL = cast(ubyte)k.keyCode;
			if (vCPU.AH) vCPU.ZF = 0; // Keystroke available*/
		}
			break;
		case 2: // SHIFT
			// Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
			// Des | I | C | N | S | A | C | L | R
			// Insert, Capslock, Numlock, Scrolllock, Alt, Ctrl, Left, Right
			// vCPU.AL = (flag)
			break;
		default:
			
			break;
		}
		break;
	case 0x17: // PRINTER

		break;
	case 0x1A: // TIME
		switch (vCPU.AH) {
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
		switch (vCPU.AH) {
		/*
		 * 00h - Terminate program
		 */
		case 0:

			break;
		/*
		 * 01h - Read character from stdin with echo
		 */
		case 1:
			//vCPU.AL = cast(ubyte)ReadKey.keyCode;
			break;
		/*
		 * 02h - Write character to stdout
		 */
		case 2:
			vCPU.AL = vCPU.DL;
			putchar(vCPU.AL);
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
			//vCPU.AL = cast(ubyte)ReadKey.keyCode;
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
			char* p = cast(char*)MEMORY + get_ad(vCPU.DS, vCPU.DX);
			while (*p != '$' && --limit > 0)
				putchar(*p++);

			vCPU.AL = 0x24;
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
			vCPU.AL = 2; // Temporary.
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
			OSDate d = void;
			os_date(&d); // os_utils
			vCPU.CX = d.year;
			vCPU.DH = d.month;
			vCPU.DL = d.day;
			vCPU.AL = d.weekday;
			break;
		}
		/*
		 * 2Bh - Set system date
		 */
		case 0x2B:
			vCPU.AL = 0xFF;
			break;
		/*
		 * 2Ch - Get system time
		 */
		case 0x2C: {
			OSTime t = void;
			os_time(&t); // os_utils
			vCPU.CH = t.hour;
			vCPU.CL = t.minute;
			vCPU.DH = t.second;
			vCPU.DL = t.millisecond;
			break;
		}
		/*
		 * 2Dh - Set system time
		 */
		case 0x2D:
			vCPU.AL = 0xFF;
			break;
		/*
		 * 2Eh - Set verify flag
		 */
		case 0x2E:
			vCPU.AL = 1;
			break;
		/*
		 * 30h - Get DOS version
		 */
		case 0x30:
			vCPU.BH = vCPU.AL == 0 ? OEM_ID.IBM : 0;
			vCPU.AL = MajorVersion;
			vCPU.AH = MinorVersion;
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
			switch (vCPU.AL) {
			case 0: // Load and execute the program.
				char[] p = MemString(get_ad(vCPU.DS, vCPU.DX));
				if (os_pexist(cast(char*)p)) {
					vdos_load(cast(char*)p);
					vCPU.CF = 0;
				} else {
					vCPU.AX = E_FILE_NOT_FOUND;
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
				vCPU.AX = E_INVALID_FUNCTION;
				vCPU.CF = 1;
				break;
			}
			break;
		}
		/*
		 * 4Ch - Terminate with return code
		 */
		case 0x4C:
			--RLEVEL;
			DOS.ERRORLEVEL = vCPU.AL;
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
		putchar(vCPU.AL);
		break;
	default: break;
	}

	__int_exit;
}