/*
 * vcpu_config.d : vcpu configuration
 */

module vcpu_config;

import sleep : SLEEP_TIME;

/*
 * vCPU timing/sleeping
 */

// in MHz
private enum i8086_FREQ = 5; // to 10
private enum i486_FREQ = 16; // to 100

/// Number of instructions to execute before sleeping for SLEEP_TIME
enum uint TSC_SLEEP = cast(uint)(
	(SLEEP_TIME * 1_000_000) / ((cast(float)1 / i8086_FREQ) * 1000)
);
pragma(msg, "CONFIG: Intel 8086 = ", i8086_FREQ, " MHz");
//pragma(msg, "CONFIG: Intel i486 = ", i486_FREQ, " MHz");
pragma(msg, "CONFIG: vcpu sleeps every ", TSC_SLEEP, " instructions");

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