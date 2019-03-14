/**
 * This module is responsable of giving at least millisecond (Windows) sleeping
 * procedures alongside a stopwatch to measure 
 */
module os.sleep;

//TODO: See if usleep(3) from Linux can be used when possible

version (Posix) {
	private import core.sys.posix.time : nanosleep, timespec;
	private import core.stdc.errno;
}
version (Windows) {
	private import core.sys.windows.windows;
}

enum SLEEP_TIME = 1; // ms

extern (C):

struct swatch_t { extern (C):
	long t_start, t_end, freq;
	bool running;

	void initw() {
		version (Windows) {
			LARGE_INTEGER l = void;
			QueryPerformanceFrequency(&l);
			freq = l.QuadPart;
		}
		version (Posix) {
			
		}
		running = 0;
	}

	void start() {
		version (Windows) {
			LARGE_INTEGER l = void;
			QueryPerformanceCounter(&l);
			t_start = l.QuadPart;
		}
		version (Posix) {
			
		}
		running = 1;
	}

	void stop() {
		version (Windows) {
			LARGE_INTEGER l = void;
			QueryPerformanceCounter(&l);
			t_end = l.QuadPart;
		}
		version (Posix) {
			
		}
		running = 0;
	}

	float time_ms(swatch_t *s) {
		//TODO: Verify Posix stuff works here as well
		return ((t_end - t_start) * 1000.0f) / s.freq;
	}
	
	void sleep_ms(int t) {
		version (Windows) {
			Sleep(t);
		}
		version (Posix) {
			timespec s = void;
			s.tv_sec = 0;
			s.tv_nsec = t * 1_000_000;
			while (nanosleep(&s, &s) > 0) {}
		}
	}
}
