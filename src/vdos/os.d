/**
 * os: Virtual DOS
 */
module vdos.os;

import ddc;
import vcpu.core : MEMORY, CPU, get_ip, FLAG;
import vdos.codes, vdos.interrupts;
import vdos.structs : SYSTEM_t, DOS_t, CURSOR;
import vdos.video;
import logger;
import appconfig : __MM_SYS_DOS, INIT_MEM;

nothrow:


/// Project logo, fancy!
enum LOGO =
	`_______ _______     ___ ______   ______`~"\n"~
	`|  __  \|  __  \   /  //  __  \ / ____/`~"\n"~
	`| |  \ || |  \ |  /  / \ \__/ //  __ \`~"\n"~
	`| |__/ || |__/ | /  /  / /__\ \| \__\ \`~"\n"~
	`|______/|______//__/   \______/\______/`~"\n";

/// OEM IDs
enum OEM_ID { // Used for INT 21h AH=30 so far.
	IBM, Compaq, MSPackagedProduct, ATnT, ZDS
}

enum
	DOS_MAJOR_VERSION = 5, /// Default major DOS version
	DOS_MINOR_VERSION = 0; /// Default minor DOS version

enum float BIOS_TICK = 1 / 18.2f;

extern (C):

__gshared ubyte
	MajorVersion = DOS_MAJOR_VERSION, /// Alterable major version
	MinorVersion = DOS_MINOR_VERSION; /// Alterable minor version

// Live structures in MEMORY

__gshared DOS_t *DOS = void;
__gshared SYSTEM_t *SYSTEM = void;

extern (C)
void vdos_init() {
	// Setting a memory pointer as ubyte* (as vdos_settings*) is not
	// supported in CTFE, so it's done in run-time instead
	SYSTEM = cast(SYSTEM_t*)MEMORY;
	SYSTEM.memsize = INIT_MEM >> 10; // DIV 1024
	SYSTEM.video_mode = 3;
	SYSTEM.screen_row = 25;
	SYSTEM.screen_col = 80;

	DOS = cast(DOS_t*)(MEMORY + __MM_SYS_DOS);

	screen_init;
}

extern (C)
void print_regs() {
	v_printf(
		"EIP=%08X  IP=%04X  (%08X)\n"~
		"EAX=%08X  EBX=%08X  ECX=%08X  EDX=%08X\n"~
		"ESP=%08X  EBP=%08X  ESI=%08X  EDI=%08X\n"~
		"CS=%04X  DS=%04X  ES=%04X  FS=%04X  GS=%04X  SS=%04X\n",
		CPU.EIP, CPU.IP, get_ip,
		CPU.EAX, CPU.EBX, CPU.ECX, CPU.EDX,
		CPU.ESP, CPU.EBP, CPU.ESI, CPU.EDI,
		CPU.CS, CPU.DS, CPU.ES, CPU.FS, CPU.GS, CPU.SS
	);
	v_put("EFLAG=");
	if (CPU.OF) v_putln("OF ");
	if (CPU.DF) v_putln("DF ");
	if (CPU.IF) v_putln("IF ");
	if (CPU.TF) v_putln("TF ");
	if (CPU.SF) v_putln("SF ");
	if (CPU.ZF) v_putln("ZF ");
	if (CPU.AF) v_putln("AF ");
	if (CPU.PF) v_putln("PF ");
	if (CPU.CF) v_putln("CF ");
	//TODO: Print rest of flags
	v_printf("(%Xh)\n", FLAG);
}

extern (C)
void print_stack() {
	v_putln("print_stack::Not implemented");
}

extern (C)
void panic(ushort code,
	const(char) *name = cast(const(char)*)__MODULE__,
	int line = __LINE__) {
	import core.stdc.stdlib : exit;

	enum RANGE = 26, TARGET = (RANGE / 2) - 1;
	v_printf(
		"\n\n\n\n"~
		"A fatal exception occured, which DD/86 couldn't recover.\n\n"~
		"STOP: %4Xh (%s L%d)\nEXEC:\n",
		code, name, line
	);
	int i = RANGE;
	ubyte *p = MEMORY + CPU.EIP - TARGET;
	while (--i) {
		if (i == TARGET)
			v_printf(" >%02X<", *p);
		else
			v_printf(" %02X", *p);
		++p;
	}
	v_put("\n--\n");
	print_regs;
	/*printf("--\n"); Temporary commented until print_stack is implemented
	print_stack;*/

	screen_draw;
	//gracefulexit(code)
}

//TODO: Function to handle SEH