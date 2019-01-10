/**
 * sleep: Sleep functions
 */
module os.sleep;

version (Posix) {
	private import core.sys.posix.time : nanosleep, timespec;
	private import core.stdc.errno;
	private __gshared timespec _t = void;
}
version (Windows) {
	private import core.sys.windows.windows;
}

enum SLEEP_TIME = 1; // ms

extern (C)
void sleep_init() {
	/+
	version (Windows) {
		if (QueryPerformanceFrequency(&ticks_per_second)) {
			QueryPerformanceCounter(&hires_start_ticks);
		}
		// For WinRT, use timeGetTime();
	}
	version (Posix) {
		
	}
	+/
}

extern (C)
void SLEEP() {
	
}