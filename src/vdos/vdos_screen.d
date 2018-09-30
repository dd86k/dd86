/*
 * vdos_screen: Virtual video adapter.
 *
 * Used to translate CP437 characters and character attributes to stdout.
 */

module vdos_screen;

import core.stdc.stdlib : malloc;
import vcpu : MEMORY;
import vdos : SYSTEM;

enum __EGA_ADDRESS = 0xA_0000;
enum __MDA_ADDRESS = 0xB_0000;
enum __VGA_ADDRESS = 0xB_8000;

//TODO: Consider videochar**
videochar* VIDEO = void;	/// video buffer
private uint screensize = void;

// When possible, use this VGA reference
// http://www.brackeen.com/vga/basics.html

// Unicode reference: https://unicode-table.com

version (Windows) {
	import core.sys.windows.wincon :
		WriteConsoleOutputA, COORD, SMALL_RECT, CHAR_INFO;
	import ddcon : hOut;

	private __gshared CHAR_INFO* ibuf = void;	/// Intermediate buffer
	private __gshared COORD ibufsize = void;
	private __gshared SMALL_RECT ibufout = void;
	private __gshared COORD bufcoord;	// inits to 0,0
}
version (Posix) {
	// Should cover Linux, FreeBSD, NetBSD, OpenBSD, DragonflyBSD, Haiku,
	// OpenIndiana/Solaris, macOS
	// Haiku has write(1) in fcntl.h
	import core.sys.posix.unistd;
	// This table suits most use cases.
	// It could of been a three-byte table, which yes could of saved us 256
	// bytes of memory, but due to alignment (fetch performance) reasons, it's
	// better to have this 4 bytes wide.
	//TODO: See if the table should be filled with actual characters
	//      since D characters are UTF-8. Which might avoid us to make a MSB
	//      version of this table. However, this is safer.
	//TODO: These kind of tables could very potentially be seperate binary files
	__gshared
	immutable uint[256] vctable = [ /// cp437-utf8-le default character translation table
		0x000020, 0xBA98E2, 0xBB98E2, 0xA599E2, 0xA699E2, 0xA399E2, 0xA099E2, 0x9897E2,
		0x8B97E2, 0x9997E2, 0x8299E2, 0x8099E2, 0xAA99E2, 0xAB99E2, 0xBC98E2, 0xBA96E2,
		// 16 (offset)
		0x8497E2, 0x9586E2, 0xBC80E2, 0x00B6C2, 0x00A7C2, 0xAC96E2, 0xA886E2, 0x9186E2,
		0xE28691, 0x9386E2, 0x9286E2, 0x9086E2, 0x9F88E2, 0x9486E2, 0xB296E2, 0xBC96E2,
		// 32
		0x000020, 0x000021, 0x000022, 0x000023, 0x000024, 0x000025, 0x000026, 0x000027,
		0x000028, 0x000029, 0x00002a, 0x00002b, 0x00002c, 0x00002d, 0x00002e, 0x00002f,
		// 48
		0x000030, 0x000031, 0x000032, 0x000033, 0x000034, 0x000035, 0x000036, 0x000037,
		0x000038, 0x000039, 0x00003a, 0x00003b, 0x00003c, 0x00003d, 0x00003e, 0x00003f,
		// 64
		0x000040, 0x000041, 0x000042, 0x000043, 0x000044, 0x000045, 0x000046, 0x000047,
		0x000048, 0x000049, 0x00004a, 0x00004b, 0x00004c, 0x00004d, 0x00004e, 0x00004f,
		// 80
		0x000050, 0x000051, 0x000052, 0x000053, 0x000054, 0x000055, 0x000056, 0x000057,
		0x000058, 0x000059, 0x00005a, 0x00005b, 0x00005c, 0x00005d, 0x00005e, 0x00005f,
		// 96
		0x000060, 0x000061, 0x000062, 0x000063, 0x000064, 0x000065, 0x000066, 0x000067,
		0x000068, 0x000069, 0x00006a, 0x00006b, 0x00006c, 0x00006d, 0x00006e, 0x00006f,
		// 112
		0x000070, 0x000071, 0x000072, 0x000073, 0x000074, 0x000075, 0x000076, 0x000077,
		0x000078, 0x000079, 0x00007a, 0x00007b, 0x00007c, 0x00007d, 0x00007e, 0x828CE2,
		// 128
		0x0087C3, 0x00BCC3, 0x00A9C3, 0x00A2C3, 0x00A4C3, 0x00A0C3, 0x00A5C3, 0x00A7C3,
		0x00AAC3, 0x00ABC3, 0x00A8C3, 0x00AFC3, 0x00AEC3, 0x00ACC3, 0x0084C3, 0x0085C3,
		// 144
		0x0089C3, 0x00A6C3, 0x0086C3, 0x00B4C3, 0x00B6C3, 0x00B2C3, 0x00BBC3, 0x00B9C3,
		0x00BFC3, 0x0096C3, 0x009CC3, 0x00A2C2, 0x00A3C2, 0x00A5C2, 0xA782E2, 0x0092C6,
		// 160
		0x00A1C3, 0x00ADC3, 0x00B3C3, 0x00BAC3, 0x00B1C3, 0x0091C3, 0x00AAC2, 0x00BAC2,
		0x00BFC2, 0x908CE2, 0x00ACC2, 0x00BDC2, 0x00BCC2, 0x00A1C2, 0x00ABC2, 0x00BBC2,
		// 176
		0x9196E2, 0x9296E2, 0x9396E2, 0x8294E2, 0xA195E2, 0xA295E2, 0x9695E2, 0x9596E2,
		0x9595E2, 0xA395E2, 0x9195E2, 0x9795E2, 0x9D95E2, 0x9C95E2, 0x9B95E2, 0x9094E2,
		// 192
		0x9494E2, 0xB494E2, 0xAC94E2, 0x9C94E2, 0x8094E2, 0xBC94E2, 0x9E95E2, 0x9F95E2,
		0x9A95E2, 0x9495E2, 0xA995E2, 0xA695E2, 0xA095E2, 0x9095E2, 0xAC95E2, 0xA795E2,
		// 208
		0xA895E2, 0xA495E2, 0xA595E2, 0x9995E2, 0x9885E2, 0x9295E2, 0x9395E2, 0xAB95E2,
		0xAA95E2, 0x9894E2, 0x8C94E2, 0x8896E2, 0x8496E2, 0x8C96E2, 0x9096E2, 0x8096E2,
		// 224
		0x00B1CE, 0x009FC3, 0x0093CE, 0x0080CF, 0x00A3CF, 0x0083CF, 0x00B5C2, 0x0084CF,
		0x00A6CE, 0x0098CE, 0x00A9CE, 0x00B4CE, 0x9E88E2, 0x0086CF, 0x00B5CE, 0xA988E2,
		// 240
		0xA189E2, 0x00B1C2, 0xA589E2, 0xA489E2, 0xA08CE2, 0xA18CE2, 0x00B7C3, 0x8889E2,
		0x00B0C2, 0x9988E2, 0x00B7C2, 0x9A88E2, 0xBF81E2, 0x00B2C2, 0xA096E2, 0x000020
	];
	__gshared
	immutable ushort[16] vatable = [ /// xterm-256 attribute translation table
		// ascii-encoded characters, terminal can accept a leading zero
		// see https://i.stack.imgur.com/KTSQa.png for reference
		// black, blue, green, cyan, red, magenta, brown, lightgray
		0x3030, 0x3430, 0x3230, 0x3630, 0x3130, 0x3530, 0x3330, 0x3730,
		// dark gray, ^blue, ^green, ^cyan, ^red, ^magenta, yellow, white
		0x3830, 0x3231, 0x3031, 0x3431, 0x3930, 0x3331, 0x3131, 0x3531
	];
}

struct videochar {
	union {
		ushort WORD;
		struct {
			// should be CP437
			ubyte ascii;	/// ascii character
			// 7 6 5 4 3 2 1 0
			// |-|-|-|-|-|-|-| attribute structure
			// | | | | +-+-+-+- foreground (4 bits)
			// | +-+-+--------- background (3 bits)
			// +--------------- blink or special (1 bit)
			ubyte attribute;	/// character attributes
		}
	}
}
static assert(videochar.sizeof == 2);

/**
 * Initiates screen, including intermediate buffer.
 */
extern (C)
void screen_init() {
	import core.stdc.string : memset;
	screensize = 80 * 25; // temporary -- mode 3
	VIDEO = cast(videochar*)(MEMORY + __VGA_ADDRESS);

	screen_clear;

	version (Windows) {
		ibuf = cast(CHAR_INFO*)malloc(CHAR_INFO.sizeof * screensize);
		ibufsize.X = 80;
		ibufsize.Y = 25;
		ibufout.Top = ibufout.Left = 0;
		ibufout.Bottom = 24;
		ibufout.Right = 79;
	}
}

/**
 * Draw a frame from the video adapter memory region.
 * (Windows) Uses WriteConsoleOutputA
 * (Linux) WIP
 */
extern (C)
void screen_draw() {
	version (Windows) {
		uint sc = SYSTEM.screen_col * SYSTEM.screen_row; /// screen size
		for (size_t i; i < sc; ++i) {
			ibuf[i].AsciiChar = cast(char)VIDEO[i].ascii;
			ibuf[i].Attributes = VIDEO[i].attribute;
		}
		WriteConsoleOutputA(hOut, ibuf, ibufsize, bufcoord, &ibufout);
	}
	version (Posix) {
		uint x = SYSTEM.screen_col;
		//uint y = SYSTEM.screen_row;

		uint sc = x * SYSTEM.screen_row; /// screen size

		char NL = '\n';
		ubyte[] s = [ // "\033[38;5;00m\033[48;5;00m" -- Guarantees byte-alignment
			0x1b,0x5b,0x33,0x38,0x3b,0x35,0x3b,0x00,0x00,0x6d, // fg
			0x1b,0x5b,0x34,0x38,0x3b,0x35,0x3b,0x00,0x00,0x6d, // bg
		];
		uint c = void; /// character to print
		ushort* s_fg = cast(ushort*)(cast(ubyte*)s + 7);
		ushort* s_bg = cast(ushort*)(cast(ubyte*)s + 17);

		write(STDOUT_FILENO, cast(char*)"\033[0;0H", 6); // put cursor at 0,0
		for (size_t i, _x; i < sc; ++i, ++_x) {
			*s_fg = vatable[vbuffer[i].attribute & 0xF];
			*s_bg = vatable[(vbuffer[i].attribute >> 4) & 7];
			c = vctable[vbuffer[i].ascii];
			write(STDOUT_FILENO, cast(void*)s, 20);
			if (c < 128)
				write(STDOUT_FILENO, cast(void*)&c, 1); // s + 1
			else if (c > 0xFFFF)
				write(STDOUT_FILENO, cast(void*)&c, 3); // s + 3
			else
				write(STDOUT_FILENO, cast(void*)&c, 2); // s + 2
			if (_x == x) {
				// TODO: Check if newline fucks when terminal's witdh is screen_col (80)
				write(STDOUT_FILENO, &NL, 1);
				_x = 0;
			}
		}
	}
}

/// Clear virtual video RAM
extern (C)
void screen_clear() {
	int t = screensize / 2;
	uint* v = cast(uint*)VIDEO;
	for (size_t i; i < t; ++i) v[i] = 0x0720_0720;
}

/// Print DD-DOS logo
extern (C)
void screen_logo() {
	/*
	 * ┌─────────────────────────────────────────────────────┐
	 * │ ┌──────┐ ┌──────┐        ┌──────┐ ┌──────┐ ┌──────┐ │
	 * │ │ ┌──┐ └┐│ ┌──┐ └┐ ┌───┐ │ ┌──┐ └┐│ ┌──┐ │┌┘ ────┬┘ │
	 * │ │ │  │  ││ │  │  │ └───┘ │ │  │  ││ │  │ │└────┐ │  │
	 * │ │ └──┘ ┌┘│ └──┘ ┌┘       │ └──┘ ┌┘│ └──┘ │┌────┘ │  │
	 * │ └──────┘ └──────┘        └──────┘ └──────┘└──────┘  │
	 * └─────────────────────────────────────────────────────┘
	 */
	//TODO: print screen logo "normally" (using vdos stdio functions)
}

/// Output a string, raw in video memory
/// This function affects the system cursor position
/// Equivelent to fputs(s, stdout)
extern (C)
void __v_put(immutable(char)* s, uint size = 0) {
	if (size == 0) {

	}
	int vs = SYSTEM.screen_row * SYSTEM.screen_col; /// video size
	videochar* v = VIDEO + vs;
	//while (--size)

	//TODO: __v_put
}

/// Output a string with a newline, raw in video memory
/// This function affects the system cursor position
/// Equivelent to puts(s)
extern (C)
void __v_putn(immutable(char)* s, uint size = 0) {
	//TODO: __v_putn
}

/// Output a character, raw in video memory
/// This function affects the system cursor position
/// Equivelent to puts(s)
extern (C)
void __v_putc(char c) {
	import vdos_structs;
	__cpos* cpos = &SYSTEM.cursor[SYSTEM.screen_page];
	uint vpos = (cpos.row * SYSTEM.screen_row) + cpos.col;
	VIDEO[vpos].ascii = c;
	++cpos.col;

	if (cpos.col <= SYSTEM.screen_col) return;

	++cpos.row;
	cpos.col = 0;

	if (cpos.row <= SYSTEM.screen_row) return;
	
	--cpos.row;
	__v_scroll;
}

extern (C)
void __v_scroll() {
	import core.stdc.string : memcpy;
	ubyte* d = MEMORY + __VGA_ADDRESS;
	ubyte* s = d + SYSTEM.screen_col;
	memcpy(s, d, SYSTEM.screen_col * SYSTEM.screen_row);
}