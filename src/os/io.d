/**
 * io: Basic OS I/O utilities
 *
 * Includes OS utilities, such as changing/getting the current working
 * directory, setting/getting file attributes, directory walkers, etc.
 */
module os.io;

extern (C):
nothrow:
@nogc:

//TODO: File/directory walker

struct OSTime {
	ubyte hour, minute, second, millisecond;
}
struct OSDate {
	ushort year;
	ubyte month, day, weekday;
}

/**
 * Get OS current time
 * Params: ost = OSTime structure pointer
 * Returns: 0 on success, non-zero on error when applicable
 */
int os_time(ref OSTime ost) {
	version (Windows) {
		import core.sys.windows.windows : SYSTEMTIME, GetLocalTime;
		SYSTEMTIME s = void;
		GetLocalTime(&s);

		ost.hour = cast(ubyte)s.wHour;
		ost.minute = cast(ubyte)s.wMinute;
		ost.second = cast(ubyte)s.wSecond;
		ost.millisecond = cast(ubyte)s.wMilliseconds;
	} else version (Posix) {
		import core.sys.posix.time : tm, localtime;
		import core.sys.posix.sys.time : timeval, gettimeofday;
		//TODO: Consider moving from gettimeofday(2) to clock_gettime(2)
		//      https://linux.die.net/man/2/gettimeofday
		//      gettimeofday is deprecated since POSIX.2008
		tm *s;
		timeval tv = void;
		gettimeofday(&tv, null);
		s = localtime(&tv.tv_sec);

		ost.hour = cast(ubyte)s.tm_hour;
		ost.minute = cast(ubyte)s.tm_min;
		ost.second = cast(ubyte)s.tm_sec;
		ost.millisecond = cast(ubyte)tv.tv_usec;
	} else {
		static assert(0, "Implement os_time");
	}
	return 0;
}

/**
 * Get OS current date
 * Params: osd = OSDate structure pointer
 * Returns: 0 on success
 */
int os_date(ref OSDate osd) {
	version (Windows) {
		import core.sys.windows.winbase : SYSTEMTIME, GetLocalTime;
		SYSTEMTIME s = void;
		GetLocalTime(&s);

		osd.year = s.wYear;
		osd.month = cast(ubyte)s.wMonth;
		osd.day = cast(ubyte)s.wDay;
		osd.weekday = cast(ubyte)s.wDayOfWeek;
	} else version (Posix) {
		import core.sys.posix.time : time_t, time, localtime, tm;
		time_t r = void;
		time(&r);
		const tm *s = localtime(&r);

		osd.year = cast(ushort)(1900 + s.tm_year);
		osd.month = cast(ubyte)(s.tm_mon + 1);
		osd.day = cast(ubyte)s.tm_mday;
		osd.weekday = cast(ubyte)s.tm_wday;
	} else {
		static assert(0, "Implement os_date");
	}
	return 0;
}

/**
 * Set the process' current working directory.
 * Params: p = Path
 * Returns: 0 on success
 */
int os_scwd(char *p) {
	version (Windows) {
		import core.sys.windows.winbase : SetCurrentDirectoryA;
		return SetCurrentDirectoryA(p) != 0;
	}
	version (Posix) {
		import core.sys.posix.unistd : chdir;
		return chdir(p) == 0;
	}
}

/**
 * Get the process' current working directory. Limits to 255 characters.
 * Params: p = string buffer
 * Returns: non-zero on success
 */
int os_gcwd(char *p) {
	version (Windows) {
		import core.sys.windows.winbase : GetCurrentDirectoryA;
		return GetCurrentDirectoryA(255, p);
	}
	version (Posix) {
		import core.sys.posix.unistd : getcwd;
		p = getcwd(p, 255);
		return 1;
	}
}

/**
 * Verifies if the file or directory exists from path
 * Params: p = Path
 * Returns: Non-zero if exists
 */
int os_pexist(const(char) *p) {
	version (Windows) {
		import core.sys.windows.windows : GetFileAttributesA;
		return GetFileAttributesA(p) != 0xFFFF_FFFF;
	}
	version (Posix) {
		import core.sys.posix.sys.stat;
		stat_t s = void;
		return stat(p, &s) == 0;
	}
}

/**
 * Verifies if given path is a directory
 * Params: p = Path buffer
 * Returns: Non-zero if directory
 */
int os_pisdir(char *p) {
	version (Windows) {
		import core.sys.windows.windows :
			GetFileAttributesA, FILE_ATTRIBUTE_DIRECTORY;
		return GetFileAttributesA(p) == FILE_ATTRIBUTE_DIRECTORY;
	}
	version (Posix) {
		import core.sys.posix.sys.stat : stat_t, stat, S_IFDIR;
		stat_t s = void;
		stat(p, &s);
		return s.st_mode & S_IFDIR;
	}
}