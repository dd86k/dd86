/**
 * interrupts: Interrupt handler (Hardware, BIOS, DOS, vDOS)
 *
 * This module lays in-between the virtual processor and the OS functions
 */
module vdos.interrupts;

import ddc;
import vcpu.core : CPU, MEMORY, get_ad, RLEVEL;
import vcpu.utils : __int_enter, __int_exit;
import vdos.os : SYSTEM, DOS, BIOS_TICK, MinorVersion, MajorVersion, OEM_ID;
import vdos.codes;
import vdos.loader : vdos_load;
import vdos.structs : CURSOR;
import vdos.video : v_printf, v_put_s, v_putc;
import os.io : OSTime, os_time, OSDate, os_date, os_pexist;
import vcpu.mm : MemString;

/// Raise interrupt.
/// Params: code = Interrupt byte
extern (C)
void INT(ubyte code) {
	debug v_printf("[dbug] INTERRUPT: %02Xh\n", code);

	__int_enter;

	switch (code) {
	case 0x10: // VIDEO
		switch (CPU.AH) {
		case 0: // Set video mode

			break;
		case 0x01: // Set text-mode cursor shape

			break;
		case 0x02: // Set cursor position
			SYSTEM.screen_page = CPU.BL > 8 ? 0 : CPU.BH;
			CURSOR* c = &SYSTEM.cursor[SYSTEM.screen_page];
			c.row = CPU.DH; //TODO: Check against system rows/columns current size
			c.col = CPU.DL;
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
		case 0:

			break;
		case 1:

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
			uint c = cast(uint)( //TODO: FIXME
				((cast(float)t.hour * 60 * 60) +
				(cast(float)t.minute * 60) +
				cast(float)t.second) * BIOS_TICK
			);
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
		--RLEVEL;
		break;
	case 0x21: // MS-DOS Services
		switch (CPU.AH) {
		case 0: // Terminal program
			--RLEVEL;
			break;
		case 1: // Read character from stdin with echo
			//CPU.AL = cast(ubyte)ReadKey.keyCode;
			break;
		case 2: // Write character to stdout
			CPU.AL = CPU.DL;
			v_putc(CPU.AL);
			break;
		case 5: // Write character to printer

			break;
		case 6: // Direct console input/output
			if (CPU.DL == 0xFF) { // input

			} else { // output
				CPU.AL = CPU.DL;
				v_putc(CPU.AL);
			}
			break;
		case 7: // Read character directly from stdin without echo
			//CPU.AL = cast(ubyte)ReadKey.keyCode;
			break;
		case 8: // Read character from stdin without echo

			break;
		case 9: { // Write string to stdout
			char *p = cast(char *)(MEMORY + get_ad(CPU.DS, CPU.DX));
			ushort l;
			while (p[l] != '$' && l < 255) ++l;
			v_put_s(p, l - 1);

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
				char[] p = MemString(get_ad(CPU.DS, CPU.DX));
				if (os_pexist(cast(char*)p)) {
					vdos_load(cast(char*)p);
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
			--RLEVEL;
			DOS.ERRORLEVEL = CPU.AL;
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
		v_putc(CPU.AL);
		break;
	default:
		//TODO: Handle incorrect interrupt vector
	}

	__int_exit;
}