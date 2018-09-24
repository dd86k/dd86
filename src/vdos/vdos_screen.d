module vdos_screen;

import core.stdc.stdlib : malloc;
import vcpu : MEMORY;
import vdos : SYSTEM;
import ddcon : Clear;

enum __EGA_ADDRESS = 0xA_0000;
enum __MDA_ADDRESS = 0xB_0000;
enum __VGA_ADDRESS = 0xB_8000;

extern (C):
__gshared:

private videochar* vbuffer = void;	/// video buffer

version (Windows) {
	import core.sys.windows.wincon :
		WriteConsoleOutputA, COORD, SMALL_RECT, CHAR_INFO;
	import ddcon : hOut;

	//extern extern (Windows)
	//uint WriteConsoleOutputA(void*, CHAR_INFO*, COORD, COORD, SMALL_RECT*);

	private CHAR_INFO* ibuf = void;	/// Intermediate buffer
	private COORD ibufsize = void;
	private SMALL_RECT ibufout = void;
	private uint screensize = void;
	private COORD bufcoord;	// inits to 0,0
}

struct videochar {
	union {
		ushort WORD;
		struct {
			ubyte ascii;	/// ascii character (should be CP437)
			// 7 6 5 4 3 2 1 0
			// |-|-|-|-|-|-|-| attribute structure
			// | | | | +-+-+-+- foreground (4 bits)
			// | +-+-+--------- background (3 bits)
			// +--------------- blink (1 bit)
			ubyte attribute;	/// attributes
		}
	}
}
static assert(videochar.sizeof == 2);

void screen_init() {
	import core.stdc.string : memset;
	screensize = 80 * 25; // mode 3
	vbuffer = cast(videochar*)(MEMORY + __VGA_ADDRESS);

	for (size_t i; i < screensize; ++i) {
		vbuffer[i].WORD = 0x0720; // gray-on-black + space (temp), should be 0700h
	}

	version (Windows) {
		ibuf = cast(CHAR_INFO*)malloc(CHAR_INFO.sizeof * screensize);
		//memset(ibuf, 37, screensize * CHAR_INFO.sizeof);
		ibufsize.X = 80;
		ibufsize.Y = 25;
		ibufout.Top = ibufout.Left = 0;
		ibufout.Bottom = 24;
		ibufout.Right = 79;
	}
}

void screen_draw() {
	version (Windows) {
		import core.stdc.stdio;
		for (size_t i; i < screensize; ++i) {
			ibuf[i].AsciiChar = cast(char)vbuffer[i].ascii;
			ibuf[i].Attributes = vbuffer[i].attribute;
		}
		WriteConsoleOutputA(hOut, ibuf, ibufsize, bufcoord, &ibufout);
	}
	version (linux)
		static assert(0, "Virtual Video Adapter missing for linux");
	version (FreeBSD)
		static assert(0, "Virtual Video Adapter missing for FreeBSD");
	version (OpenBSD)
		static assert(0, "Virtual Video Adapter missing for OpenBSD");
	version (NetBSD)
		static assert(0, "Virtual Video Adapter missing for NetBSD");
	version (DragonFlyBSD)
		static assert(0, "Virtual Video Adapter missing for DragonflyBSD");
	version (Solaris)
		static assert(0, "Virtual Video Adapter missing for Solaris");
	version (Haiku)
		static assert(0, "Virtual Video Adapter missing for Haiku");
	version (OSX)
		static assert(0, "Virtual Video Adapter missing for OSX");
}

void screen_clear() { //TODO: Check what CLS exactly does
	for (size_t i; i < screensize; ++i) {
		vbuffer[i].ascii = ' ';
	}
}