/**
 * video: Virtual video adapter.
 *
 * Used to translate characters and character attributes to stdout.
 */
module vdos.video;

import core.stdc.stdlib : malloc;
import vcpu.core : MEMORY;
import vdos.os : SYSTEM;

extern (C):
nothrow:

private enum __EGA_ADDRESS = 0xA_0000;
private enum __MDA_ADDRESS = 0xB_0000;
private enum __VGA_ADDRESS = 0xB_8000;
enum __VIDEO_ADDRESS = __VGA_ADDRESS; /// Default video address
enum MAX_STR = 2048; /// maximum string length to print

__gshared videochar *VIDEO = void;	/// video buffer

// VGA reference: http://www.brackeen.com/vga/basics.html
// Unicode reference: https://unicode-table.com

version (Windows) {
	import core.sys.windows.wincon :
		WriteConsoleOutputW, WriteConsoleOutputA,
		COORD, SMALL_RECT, CHAR_INFO, SetConsoleOutputCP;
	import os.term : hOut;

	private __gshared CHAR_INFO *ibuf = void;	/// Intermediate buffer
	private __gshared COORD ibufsize = void;
	private __gshared SMALL_RECT ibufout = void;
	private __gshared COORD bufcoord;	// inits to 0,0
	// disabled until W variant is needed...
	/*__gshared ushort [256]vctable = [
		/// cp437-utf16-le default character translation table
		0x0020, 0x3A26, 0x3B26, 0x6526, 0x6626, 0x6326, 0x6026, 0x2220,
		0xD825, 0xCB25, 0xD925, 0x4226, 0x4026, 0x6A26, 0x6B26, 0x3C26,
		// 1_ -- 16 (offset)
		0xBA25, 0xC425, 0x9521, 0x3C20, 0xB600, 0xA700, 0xAC25, 0xA821,
		0x9121, 0x9321, 0x9221, 0x9021, 0x1F22, 0x9421, 0xB225, 0xBC25,
		// 2_ -- 32
		0x2000, 0x2100, 0x2200, 0x2300, 0x2400, 0x2500, 0x2600, 0x2700,
		0x2800, 0x2900, 0x2a00, 0x2b00, 0x2c00, 0x2d00, 0x2e00, 0x2f00,
		// 3_ -- 48
		0x3000, 0x3100, 0x3200, 0x3300, 0x3400, 0x3500, 0x3600, 0x3700,
		0x3800, 0x3900, 0x3a00, 0x3b00, 0x3c00, 0x3d00, 0x3e00, 0x3f00,
		// 4_ -- 64
		0x4000, 0x4100, 0x4200, 0x4300, 0x4400, 0x4500, 0x4600, 0x4700,
		0x4800, 0x4900, 0x4a00, 0x4b00, 0x4c00, 0x4d00, 0x4e00, 0x4f00,
		// 5_ -- 80
		0x5000, 0x5100, 0x5200, 0x5300, 0x5400, 0x5500, 0x5600, 0x5700,
		0x5800, 0x5900, 0x5a00, 0x5b00, 0x5c00, 0x5d00, 0x5e00, 0x5f00,
		// 6_ -- 96
		0x6000, 0x6100, 0x6200, 0x6300, 0x6400, 0x6500, 0x6600, 0x6700,
		0x6800, 0x6900, 0x6a00, 0x6b00, 0x6c00, 0x6d00, 0x6e00, 0x6f00,
		// 7_ -- 112
		0x7000, 0x7100, 0x7200, 0x7300, 0x7400, 0x7500, 0x7600, 0x7700,
		0x7800, 0x7900, 0x7a00, 0x7b00, 0x7c00, 0x7d00, 0x7e00, 0x0223,
		// 8_ -- 128
		0xC700, 0xFC00, 0xE900, 0xE200, 0xE400, 0xE000, 0xE500, 0xE700,
		0xEA00, 0xEB00, 0xE800, 0xEF00, 0xEE00, 0xEC00, 0xC400, 0xC500,
		// 9_ -- 144
		0xC900, 0xE600, 0xC600, 0xF400, 0xF600, 0xF200, 0xFB00, 0xF900,
		0xFF00, 0xD600, 0xDC00, 0xA200, 0xA300, 0xA500, 0xA720, 0x9201,
		// A_ -- 160
		0xE100, 0xED00, 0xF300, 0xFA00, 0xF100, 0xD100, 0xAA00, 0xBA00,
		0xBF00, 0x1023, 0xAC00, 0xBD00, 0xBC00, 0xA100, 0xAB00, 0xBB00,
		// B_ -- 176
		0x9125, 0x9225, 0x9325, 0x0225, 0x2425, 0x6125, 0x6225, 0x5625,
		0x5525, 0x6325, 0x5125, 0x5725, 0x5D25, 0x5C25, 0x5B25, 0x1025,
		// C_ -- 192
		0x1425, 0x3425, 0x2C25, 0x1C25, 0x0025, 0x3C25, 0x5E25, 0x5F25,
		0x5A25, 0x5425, 0x6925, 0x6625, 0x6025, 0x5025, 0x6C25, 0x6725,
		// D_ -- 208
		0x6825, 0x6425, 0x6525, 0x5925, 0x5825, 0x5225, 0x5325, 0x6B25,
		0x6A25, 0x1825, 0x0C25, 0x8825, 0x8425, 0x8C25, 0x9025, 0x8025,
		// E_ -- 224
		0xB103, 0xDF00, 0x9303, 0xC003, 0xA303, 0xC303, 0xB500, 0xC403,
		0xA603, 0x9803, 0xA903, 0xB403, 0xE122, 0xC603, 0xB503, 0x2922,
		// F_ -- 240
		0x6122, 0xB100, 0x6522, 0x6422, 0x2023, 0x2123, 0xF700, 0x4822,
		0xB000, 0x1922, 0xB700, 0x1A22, 0x7F20, 0xB200, 0xA025, 0x2000
	];*/
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
	// The table can also be put into a file and read at run-time.
	/// cp437-utf8-le default character translation table
	__gshared uint [256]vctable = [
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
	__gshared ushort [16]vatable = [ /// xterm-256 attribute translation table
		// ascii-encoded characters, terminal can accept a leading zero
		// see https://i.stack.imgur.com/KTSQa.png for reference
		// black, blue, green, cyan, red, magenta, brown, lightgray
		0x3030, 0x3430, 0x3230, 0x3630, 0x3130, 0x3530, 0x3330, 0x3730,
		// dark gray, ^blue, ^green, ^cyan, ^red, ^magenta, yellow, white
		0x3830, 0x3231, 0x3031, 0x3431, 0x3930, 0x3331, 0x3131, 0x3531
	];
	__gshared ubyte *fg_s = /// fg string -- "\033[38;5;00m"
		[ 0x1b, 0x5b, 0x33, 0x38, 0x3b, 0x35, 0x3b, 0x00, 0x00, 0x6d ];
	__gshared ubyte *bg_s = /// bg string -- "\033[48;5;00m"
		[ 0x1b, 0x5b, 0x34, 0x38, 0x3b, 0x35, 0x3b, 0x00, 0x00, 0x6d ];
	__gshared ushort *fg = void; /// Foreground color string pointer
	__gshared ushort *bg = void; /// Background color string pointer
	__gshared char *str = void;
}

/// Video adapter character (EGA, CGA, VGA)
struct videochar {
	union {
		ushort WORD;
		struct {
			ubyte ascii;	/// character, usually CP437
			// 7 6 5 4 3 2 1 0
			// |-|-|-|-|-|-|-|
			// | | | | +-+-+-+- foreground (4 bits)
			// | +-+-+--------- background (3 bits)
			// +--------------- blink/special (1 bit)
			ubyte attribute;	/// character attributes
		}
	}
}
static assert(videochar.sizeof == 2);

/**
 * Initiates screen, including intermediate buffer.
 * Usually called by vdos.
 */
void screen_init() {
	import core.stdc.string : memset;
	VIDEO = cast(videochar*)(MEMORY + __VIDEO_ADDRESS);

	screen_clear;

	version (Windows) {
		import core.sys.windows.windows : SetConsoleMode, SetConsoleOutputCP;

		// ~ENABLE_PROCESSED_OUTPUT & ~ENABLE_WRAP_AT_EOL_OUTPUT
		SetConsoleMode(hOut, 0);
		SetConsoleOutputCP(437); // default

		ibuf = cast(CHAR_INFO*)malloc(CHAR_INFO.sizeof * (80 * 25));
		ibufsize.X = 80;
		ibufsize.Y = 25;
		ibufout.Top = ibufout.Left = 0;
		ibufout.Bottom = 24;
		ibufout.Right = 79;
	}
	version (Posix) {
		fg = cast(ushort*)(fg_s + 7);
		bg = cast(ushort*)(bg_s + 7);
		// 24 extra bytes for:
		// 10 char fg
		// 10 char bg
		// 3 utf-8 char (worst-case)
		// 1 newline
		str = cast(char*)malloc(80 * 25 * 24);
	}
}

/**
 * Draw a frame from the video adapter memory region.
 * (Windows) Uses WriteConsoleOutputA
 * (Posix) Uses write(2) to STDOUT_FILENO
 */
void screen_draw() {
	version (Windows) {
		const uint sc = SYSTEM.screen_col * SYSTEM.screen_row; /// screen size
		for (size_t i; i < sc; ++i) {
			//ibuf[i].UnicodeChar = vctable[VIDEO[i].ascii];
			ibuf[i].AsciiChar = VIDEO[i].ascii;
			ibuf[i].Attributes = VIDEO[i].attribute;
		}
		WriteConsoleOutputA(hOut, ibuf, ibufsize, bufcoord, &ibufout);
		//WriteConsoleOutputW(hOut, ibuf, ibufsize, bufcoord, &ibufout);
	}
	version (Posix) {
		const uint w = SYSTEM.screen_col; /// width
		const uint h = SYSTEM.screen_row; /// height
		char *s = str;

		write(STDOUT_FILENO, cast(char*)"\033[0;0H", 6); // cursor at 0,0
		ubyte lfg = 0xFF; /// last foreground color
		ubyte lbg = 0xFF; /// last background color
		size_t bi; /// buffer index
		for (size_t i, x, sc = w * h; sc; ++i, --sc) {
			const ubyte a = VIDEO[i].attribute;
			ubyte cfg = a & 15;
			ubyte cbg = a >> 4;
			if (cfg != lfg) {
				*fg = vatable[cfg];
				*cast(ulong*)(s + bi) = *cast(ulong*)fg_s;
				*cast(ushort*)(s + bi + 8) = *cast(ushort*)(fg_s + 8);
				lfg = cfg;
				bi += 10;
			}
			if (cbg != lbg) {
				*bg = vatable[cbg];
				*cast(ulong*)(s + bi) = *cast(ulong*)bg_s;
				*cast(ushort*)(s + bi + 8) = *cast(ushort*)(bg_s + 8);
				lbg = cbg;
				bi += 10;
			}
			const uint c = vctable[VIDEO[i].ascii];
			if (c < 128) { // +1
				s[bi] = cast(ubyte)c;
				++bi;
			} else if (c > 0xFFFF) { // +3
				//*cast(ushort*)(s + bi) = cast(ushort)c;
				//*(s + bi + 2) = *cp;
				*cast(uint*)(s + bi) = c;
				bi += 3;
			} else { // +2
				*cast(ushort*)(s + bi) = cast(ushort)c;
				bi += 2;
			}
			++x;
			if (x == w) {
				*(s + bi) = '\n';
				if (sc <= 1) break;
				x = 0;
				++bi;
			}
		}
		write(STDOUT_FILENO, s, bi);
	}
}

/// Clear virtual video RAM, resets every cells to white/black with null
/// character
void screen_clear() {
	const int t = (SYSTEM.screen_row * SYSTEM.screen_col) / 2;
	uint *v = cast(uint*)VIDEO;
	for (size_t i; i < t; ++i) v[i] = 0x0700_0700;
}

/// Print the pretty logo
void screen_logo() {
	// ┌─────────────────────────────────────────────────────┐
	// │ ┌──────┐ ┌──────┐        ┌──────┐ ┌──────┐ ┌──────┐ │
	// │ │ ┌──┐ └┐│ ┌──┐ └┐ ┌───┐ │ ┌──┐ └┐│ ┌──┐ │┌┘ ────┬┘ │
	// │ │ │  │  ││ │  │  │ └───┘ │ │  │  ││ │  │ │└────┐ │  │
	// │ │ └──┘ ┌┘│ └──┘ ┌┘       │ └──┘ ┌┘│ └──┘ │┌────┘ │  │
	// │ └──────┘ └──────┘        └──────┘ └──────┘└──────┘  │
	// └─────────────────────────────────────────────────────┘
	enum l =
	// ┌─────────────────────────────────────────────────────┐
	"\xDA\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4"~
	"\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4"~
	"\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xBF\n"~
	// │ ┌──────┐ ┌──────┐        ┌──────┐ ┌──────┐ ┌──────┐ │
	"\xB3 \xDA\xC4\xC4\xC4\xC4\xC4\xC4\xBF \xDA\xC4\xC4\xC4\xC4\xC4\xC4\xBF"~
	"        \xDA\xC4\xC4\xC4\xC4\xC4\xC4\xBF \xDA\xC4\xC4\xC4\xC4\xC4\xC4\xBF"~
	" \xDA\xC4\xC4\xC4\xC4\xC4\xC4\xBF \xB3\n"~
	// │ │ ┌──┐ └┐│ ┌──┐ └┐ ┌───┐ │ ┌──┐ └┐│ ┌──┐ │┌┘ ────┬┘ │
	"\xB3 \xB3 \xDA\xC4\xC4\xBF \xC0\xBF\xB3 \xDA\xC4\xC4\xBF \xC0\xBF"~
	" \xDA\xC4\xC4\xC4\xBF \xB3 \xDA\xC4\xC4\xBF \xC0\xBF\xB3 \xDA\xC4\xC4\xBF "~
	"\xB3\xDA\xD9 \xC4\xC4\xC4\xC4\xC2\xD9 \xB3\n"~
	// │ │ │  │  ││ │  │  │ └───┘ │ │  │  ││ │  │ │└────┐ │  │
	"\xB3 \xB3 \xB3  \xB3  \xB3\xB3 \xB3  \xB3  \xB3 \xC0\xC4\xC4\xC4\xD9 \xB3"~
	" \xB3  \xB3  \xB3\xB3 \xB3  \xB3 \xB3\xC0\xC4\xC4\xC4\xC4\xBF \xB3  \xB3\n"~
	// │ │ └──┘ ┌┘│ └──┘ ┌┘       │ └──┘ ┌┘│ └──┘ │┌────┘ │  │
	"\xB3 \xB3 \xC0\xC4\xC4\xD9 \xDA\xD9\xB3 \xC0\xC4\xC4\xD9 \xDA\xD9       "~
	"\xB3 \xC0\xC4\xC4\xD9 \xDA\xD9\xB3 \xC0\xC4\xC4\xD9 \xB3"~
	"\xDA\xC4\xC4\xC4\xC4\xD9 \xB3  \xB3\n"~
	// │ └──────┘ └──────┘        └──────┘ └──────┘└──────┘  │
	"\xB3 \xC0\xC4\xC4\xC4\xC4\xC4\xC4\xD9 \xC0\xC4\xC4\xC4\xC4\xC4\xC4\xD9    "~
	"    \xC0\xC4\xC4\xC4\xC4\xC4\xC4\xD9 \xC0\xC4\xC4\xC4\xC4\xC4\xC4\xD9"~
	"\xC0\xC4\xC4\xC4\xC4\xC4\xC4\xD9  \xB3\n"~
	// └─────────────────────────────────────────────────────┘
	"\xC0\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4"~
	"\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4"~
	"\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xD9\n";
	v_put_s(l, l.length);
}

/**
 * Output a string, raw in video memory.
 * This function affects the virtual system cursor position.
 * Equivalent to fputs(s, stdout).
 * Params:
 *   s = String, null-terminated
 */
void v_put(const(char) *s) {
	for (size_t i; s[i] != 0 && i < MAX_STR; ++i)
		v_putc(s[i]);
}

/**
 * Output a string, raw in video memory.
 * This function affects the virtual system cursor position.
 * Equivalent to fputs(s, stdout).
 * Params:
 *   s = String
 *   size = String length
 */
void v_put_s(const(char) *s, uint size) {
	for (size_t i; i < size && s[i] != 0; ++i)
		v_putc(s[i]);
}

/**
 * Output a string with a newline, raw in video memory. If there is no strings,
 * this function outputs only a newline.
 * This function affects the virtual system cursor position.
 * Equivelent to puts(s)
 * Params:
 *   s = String (optional)
 */
void v_putln(const(char) *s = null) {
	if (s) v_put(s);
	v_putc('\n');
}

/**
 * Output a character in video memory.
 * This function affects the system cursor position.
 * Equivelent to putchar()
 * Params:
 *   c = Character
 */
void v_putc(char c) {
	import vdos.structs : CURSOR;

	CURSOR *cur = &SYSTEM.cursor[SYSTEM.screen_page];
	uint pos = void; // character position

	if (c < 32) goto CONTROL_CHAR; // ASCII

	// Normal character
	pos = (cur.row * SYSTEM.screen_col) + cur.col;
	++cur.col;
	if (cur.col >= SYSTEM.screen_col) {
		cur.col = 0;
		++cur.row;
	}
	if (cur.row >= SYSTEM.screen_row) {
		--cur.row;
		v_scroll;
	}
	VIDEO[pos].ascii = c;
	return;

CONTROL_CHAR:
	switch (c) {
	case 0: // '\0'
		++cur.col;
		if (cur.col >= SYSTEM.screen_col) {
			cur.col = 0;
			++cur.row;
		}
		if (cur.row >= SYSTEM.screen_row) {
			--cur.row;
			v_scroll;
		}
		return;
	case '\n':
		cur.col = 0;
		if (cur.row + 1 >= SYSTEM.screen_row)
			v_scroll;
		else
			++cur.row;
		return;
	case '\t':
		v_put_s("        ", 8);
		break;
	//case 27: // ESC codes
	default: // non-printable/usable
	}
}

void v_printf(const(char) *f, ...) {
	import ddc : vsnprintf, va_list, va_start, puts;

	va_list args = void;
	va_start(args, f);

	char [512]b = void;
	uint c = vsnprintf(cast(char*)b, 512, f, args);

	if (c > 0)
		v_put_s(cast(char *)b, c);
}

/// Scroll screen once, does not redraw screen
/// Note: This function goes one line overboard video memory
void v_scroll() {
	uint sc = SYSTEM.screen_row * SYSTEM.screen_col; /// screen size
	videochar *d = cast(videochar*)VIDEO; /// destination
	videochar *s = d + sc; /// source

	videochar tp;
	tp.attribute = VIDEO[sc - 1].attribute;
	for (size_t i; i < SYSTEM.screen_col; ++i)
		s[i].WORD = tp.WORD;

	s = cast(videochar*)(d + SYSTEM.screen_col);
	for (size_t di, si; --sc; ++di, ++si) {
		d[di].WORD = s[si].WORD;
	}
}

/// Update cursor positions on host machine using current screen page
void v_updatecur() {
	import vdos.structs : CURSOR;
	import os.term : SetPos;
	const CURSOR w = SYSTEM.cursor[SYSTEM.screen_page];
	SetPos(w.col, w.row);
}