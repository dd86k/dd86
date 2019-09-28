/**
 * Virtual DOS
 */
module vdos.os;

import ddc;
import vcpu.core, vcpu.utils, err, vdos.interrupts;
import vdos.structs : SYSTEM_t, dos_dev_t, CURSOR;
import vdos.video;
import logger;
import appconfig : __MM_SYS_DOS, INIT_MEM;

__gshared:
extern (C):

/// Project logo, fancy!
enum LOGO =
	`_______ _______     ___ ______   ______`~"\n"~
	`|  __  \|  __  \   /  //  __  \ / ____/`~"\n"~
	`| |  \ || |  \ |  /  / \ \__/ //  __ \ `~"\n"~
	`| |__/ || |__/ | /  /  / /__\ \| \__\ \`~"\n"~
	`|______/|______//__/   \______/\______/`~"\n";

/// OEM IDs
enum OEM_ID { // Used for INT 21h AH=30 so far.
	IBM, Compaq, MSPackagedProduct, ATnT, ZDS
}

enum
	DOS_MAJOR_VERSION = 5, /// Default major DOS version
	DOS_MINOR_VERSION = 0; /// Default minor DOS version

/// BIOS tick/second ratio (18.2 times/sec)
enum float BIOS_TICK = 1 / 18.2f;

ubyte
	MajorVersion = DOS_MAJOR_VERSION, /// Alterable major version
	MinorVersion = DOS_MINOR_VERSION; /// Alterable minor version

// Live structures mapped to virtual memory (MEMORY)

dos_dev_t *DOS = void;	/// DOS devices
SYSTEM_t *SYSTEM = void;	/// System (IBM PC) and DOS variables

void vdos_init() {
	// Setting a memory pointer as ubyte* (as vdos_settings*) is not
	// supported in CTFE, so it's done in run-time instead
	SYSTEM = cast(SYSTEM_t*)MEMORY;
	SYSTEM.memsize = INIT_MEM >> 10; // DIV 1024
	SYSTEM.video_mode = 3;
	SYSTEM.screen_row = 25;
	SYSTEM.screen_col = 80;

	DOS = cast(dos_dev_t*)(MEMORY + __MM_SYS_DOS);

	video_init;
}

/**
 * Print CPU registers
 */
void vdos_print_regs() {
	video_printf(
		"EIP=%08X  IP=%04X  (%08X)\n"~
		"EAX=%08X  EBX=%08X  ECX=%08X  EDX=%08X\n"~
		"ESP=%08X  EBP=%08X  ESI=%08X  EDI=%08X\n"~
		"CS=%04X  DS=%04X  ES=%04X  FS=%04X  GS=%04X  SS=%04X\n",
		CPU.EIP, CPU.IP, get_ip,
		CPU.EAX, CPU.EBX, CPU.ECX, CPU.EDX,
		CPU.ESP, CPU.EBP, CPU.ESI, CPU.EDI,
		CPU.CS, CPU.DS, CPU.ES, CPU.FS, CPU.GS, CPU.SS
	);
	video_put("EFLAG=");
	if (CPU.OF) video_put("OF ");
	if (CPU.DF) video_put("DF ");
	if (CPU.IF) video_put("IF ");
	if (CPU.TF) video_put("TF ");
	if (CPU.SF) video_put("SF ");
	if (CPU.ZF) video_put("ZF ");
	if (CPU.AF) video_put("AF ");
	if (CPU.PF) video_put("PF ");
	if (CPU.CF) video_put("CF ");
	//TODO: Print rest of flags
	video_printf("(%Xh)\n", CPU.FLAGS);
}

/**
 *
 */
void vdos_print_stack() {
	video_puts("print_stack::Not implemented");
}

/**
 * Stops emulation, screen updates, and prints the fatal error code with
 * some extra error codes. This should only be used in the more
 * extreme situations.
 * Params: code = Error code
 */
void vdos_panic(ushort code,
	const(char) *name = cast(const(char)*)__MODULE__,
	int line = __LINE__) {
	import core.stdc.stdlib : exit;

	enum RANGE = 26, TARGET = (RANGE / 2) - 1;
	video_printf(
		"\n\n\n\n"~
		"+-------+\n"~
		"| FATAL |\n"~
		"+-------+\n"~
		"A fatal exception occured.\n\n"~
		"STOP: %4Xh (%s:L%u)\nEXEC:\n",
		code, name, line
	);
	int i = RANGE;
	ubyte *p = MEMORY + CPU.EIP - TARGET;
	while (--i)
		video_printf(i == TARGET ? " >%02X<" : " %02X", *p++);
	video_put("\n--\n");
	vdos_print_regs;
	/*printf("--\n"); Temporary commented until print_stack is implemented
	print_stack;*/

	video_update;
	//gracefulexit(code)
}