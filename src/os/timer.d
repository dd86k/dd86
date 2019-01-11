/**
 * timer: Precise OS interval timer
 *
 * (Windows) TBD
 * (Posix) TBD
 */
module os.timer;

import core.stdc.time : clock, clock_t, CLOCKS_PER_SEC;

/// Clocks per milliseconds
/// Fine even on 32-bit systems where the value is usually 1_000_000, since
/// 1_000_000_000 is a valid value in 32-bit systems.
/// (Windows) This value is 1_000_000
/// (OSX) This value is 1_000_000_000
/// (FreeBSD) This value is 128_000
/// (NetBSD) This value is 100_000
/// (OpenBSD) This value is 100_000
/// (DragonflyBSD) This value is 128_000
/// (Other) This value is 1_000_000_000
enum CLOCKS_PER_MS = CLOCKS_PER_SEC * 1_000;

extern (C):

struct timer_t {
	/// Minimum amount of time to sleep the thread.
	/// Default: 5 ms
	int min_sleep;
	/// Required amount of time to go through
	int req_ms;
	clock_t c_init;
	clock_t c_target;
}

timer_t timer_create(int ms) {
	timer_t t = void;
	t.c_init = clock;
	t.c_target = t.c_init + (ms * CLOCKS_PER_MS);
	return t;
}

/**
 * Check if time has been exhausted from last check. 
 * This function checks cinit against 
 *
 *
 * Returns: Non-zero if time has been exhausted
 */
int timer_check(timer_t t) {
	clock_t c = clock;
	//TODO: check
	return 0; 
}