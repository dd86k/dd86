/*
 * DD-DOS compilation configuration settings
 */

module compile_config;

import sleep : SLEEP_TIME;
import vdos : DOS_MAJOR_VERSION, DOS_MINOR_VERSION;
import vdos_structs : vdos_settings;

debug {
	pragma(msg, "-- DEBUG: ON");
	enum BUILD_TYPE = "DEBUG";	/// For printing purposes
} else {
	pragma(msg, "-- DEBUG: OFF");
	enum BUILD_TYPE = "RELEASE";	/// For printing purposes
}

pragma(msg, "-- DD-DOS version: ", APP_VERSION);
pragma(msg, "-- MS-DOS version: ", DOS_MAJOR_VERSION, ".", DOS_MINOR_VERSION);

version (BigEndian) pragma(msg,
`WARNING: DD-DOS has not been tested on big-endian platforms!
You might want to run 'dub test' beforehand to check if everything is OK.
`);

version (CRuntime_Bionic) {
	pragma(msg, "-- RUNTIME: Bionic");
	enum C_RUNTIME = "Bionic";
} else version (CRuntime_DigitalMars) {
	pragma(msg, "-- RUNTIME: DigitalMars");
	enum C_RUNTIME = "DigitalMars";
} else version (CRuntime_Glibc) {
	pragma(msg, "-- RUNTIME: Glibc");
	enum C_RUNTIME = "Glibc";
} else version (CRuntime_Microsoft) {
	pragma(msg, "-- RUNTIME: Microsoft");
	enum C_RUNTIME = "Microsoft";
} else version(CRuntime_Musl) {
	pragma(msg, "-- RUNTIME: musl");
	enum C_RUNTIME = "musl";
} else version (CRuntime_UClibc) {
	pragma(msg, "-- RUNTIME: uClibc");
	enum C_RUNTIME = "uClibc";
} else {
	pragma(msg, "-- RUNTIME: UNKNOWN");
	enum C_RUNTIME = "UNKNOWN";
}

enum APP_VERSION = "0.0.0-0"; /// DD-DOS version

/*
 * vCPU
 */

// in MHz
private enum i8086_FREQ = 5; // to 10
private enum i486_FREQ = 16; // to 100

/// Number of instructions to execute before sleeping for SLEEP_TIME
// part of issue #20
enum uint TSC_SLEEP = cast(uint)(
	(SLEEP_TIME * 1_000_000) / ((cast(float)1 / i8086_FREQ) * 1000)
);
pragma(msg, "-- CONFIG: Intel 8086 = ", i8086_FREQ, " MHz");
//pragma(msg, "-- CONFIG: Intel i486 = ", i486_FREQ, " MHz");
pragma(msg, "-- CONFIG: vcpu sleeps every ", TSC_SLEEP, " instructions");

/*
 * Memory
 */

/// Initial and maximum amount of memory if not specified in settings.
enum INIT_MEM = 0x4_0000;
// 0x4_0000    256K -- MS-DOS minimum
// 0xA_0000    640K
// 0x10_0000  1024K -- Recommended
// 0x20_0000  2048K
// 0x40_0000  4096K

/*
 * vDOS
 */

private enum __SETTINGS_LOC = 0x2000; /// Settings location in MEMORY
private enum __DOS_STRUCT_LOC = 0x1160; /// MS-DOS system data location in MEMORY
static assert(
	__SETTINGS_LOC + vdos_settings.sizeof < INIT_MEM,
	"Settings location and size go beyond INIT_MEM size"
);