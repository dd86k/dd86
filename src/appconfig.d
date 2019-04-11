/**
 * DD/86 compilation configuration settings and messages. This includes compile
 * configuration options for vcpu, memory manager, vdos, and os layer module.
 *
 * Pragmas of type msg are only allowed here.
 */
module appconfig;

import os.sleep : SLEEP_TIME;
import vdos.os : DOS_MAJOR_VERSION, DOS_MINOR_VERSION;
import vdos.structs;

//
// * CPU
//

// in MHz
private enum i8086_FREQ = 5; // to 10
private enum i486_FREQ = 16; // to 100

//pragma(msg, "[CONFIG]\tIntel 8086 = ", i8086_FREQ, " MHz");
//pragma(msg, "[CONFIG]\tIntel i486 = ", i486_FREQ, " MHz");
//pragma(msg, "[CONFIG]\tvcpu sleeps every ", TSC_SLEEP, " instructions");

/// Byte alignment for CPU flags. This includes EFLAG, CR0, and CR3 flags and
/// will affect Test Registers and Debug Registers in the future.
enum FLAG_ALIGNMENT = 2;

//
// * Memory settings
//

/// Default initial amount of memory for the virtual machine
// 0x4_0000    256K MS-DOS minimum
// 0xA_0000    640K
// 0x10_0000  1024K Recommended
// 0x20_0000  2048K
// 0x40_0000  4096K
enum INIT_MEM = 0x10_0000;

enum __MM_COM_ROM = 0x400;	/// ROM Communication Area, 400h
enum __MM_COM_DOS = 0x500;	/// DOS Communication Area, 500h
enum __MM_SYS_DEV = 0x700;	/// System Device Drivers location, 700h
enum __MM_SYS_DOS = 0x1160;	/// MS-DOS data location, 1160h

//
// * DOS settings
//

enum __SHL_BUFSIZE = 127;	/// Input buffer size
enum __MM_SHL_DATA = 0x5E40;	/// Virtual shell data location

//
// Compilation messages
//

debug {
	pragma(msg, "[DEBUG]\tON");
	enum BUILD_TYPE = "debug";	/// For printing purposes
} else {
	pragma(msg, "[DEBUG]\tOFF");
	enum BUILD_TYPE = "release";	/// For printing purposes
}

pragma(msg, "[DOS]\tDD/86 version: ", APP_VERSION);
pragma(msg, "[DOS]\tMS-DOS version: ", DOS_MAJOR_VERSION, ".", DOS_MINOR_VERSION);

version (BigEndian) pragma(msg,
`WARNING: DD/86 has not been tested on big-endian platforms!
You might want to run 'dub test' beforehand to check if everything is OK.
`);

version (CRuntime_Bionic) {
	pragma(msg, "[RUNTIME]\tBionic");
	enum C_RUNTIME = "Bionic";
} else version (CRuntime_DigitalMars) {
	pragma(msg, "[RUNTIME]\tDigitalMars");
	enum C_RUNTIME = "DigitalMars";
} else version (CRuntime_Glibc) {
	pragma(msg, "[RUNTIME]\tGlibc");
	enum C_RUNTIME = "Glibc";
} else version (CRuntime_Microsoft) {
	pragma(msg, "[RUNTIME]\tMicrosoft");
	enum C_RUNTIME = "Microsoft";
} else version(CRuntime_Musl) {
	pragma(msg, "[RUNTIME]\tmusl");
	enum C_RUNTIME = "musl";
} else version (CRuntime_UClibc) {
	pragma(msg, "[RUNTIME]\tuClibc");
	enum C_RUNTIME = "uClibc";
} else {
	pragma(msg, "[RUNTIME]\tUNKNOWN");
	enum C_RUNTIME = "UNKNOWN";
}

version (X86) {
	enum PLATFORM = "x86";
} else version (X86_64) {
	enum PLATFORM = "amd64";
} else version (ARM) {
	version (LittleEndian) enum PLATFORM = "aarch32le";
	version (BigEndian) enum PLATFORM = "aarch32be";
} else version (AArch64) {
	version (LittleEndian) enum PLATFORM = "aarch64le";
	version (BigEndian) enum PLATFORM = "aarch64be";
} else {
	static assert(0, "This platform is not supported");
}

enum APP_VERSION = "0.0.0"; /// DD/86 version