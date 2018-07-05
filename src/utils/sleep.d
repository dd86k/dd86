/*
 * sleep.d : Sleep functions
 */

module sleep;

version (Posix) {
	private import core.sys.posix.time : nanosleep, timespec;
	private import core.stdc.errno;
	private __gshared timespec _t;
}
version (Windows) {
	private import core.sys.windows.winbase : Sleep;
}

enum SLEEP_TIME = 1; // ms

extern (C)
void SLEEP_SET() {
	version (Posix) {
		_t.tv_nsec = SLEEP_TIME * 1_000_000UL;
	}
}

extern (C)
void SLEEP() {
	version (Posix) {
		// EFAULT and EINVAL usually not applied to _our_ case
		while (nanosleep(&_t, cast(timespec*)0)) {}
	}
	version (Windows) {
		Sleep(SLEEP_TIME);
	}
}