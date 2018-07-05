/*
 * sleep.d : Sleep functions
 */

module sleep;

version (Posix) {
	private import core.sys.posix.time : nanosleep, timespec;
	private import core.stdc.errno;
	private __gshared timespec _t;
}

extern (C)
void SLEEP_SET(int nanoseconds) {
	version (Posix) {
		_t.tv_nsec = nanoseconds;
	}
}

extern (C)
void SLEEP() {
	version (Posix) {
		// EFAULT and EINVAL usually not applied to _our_ case
		while (nanosleep(&_t, &_t)) {}
	}
	version (Windows) {
		/*
		 * TODO: Figure out a highly accurate sleep assembly usable in ring 3
		 *
		 * PAUSE is _only_ good for spin-locks, not thread-sleeping
		 */
		asm { // testing stuff
		}
	}
}