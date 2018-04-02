/*
 * OSUtilities.d : Basic OS utilities
 *
 * Includes OS utilities, such as changing/getting the current working
 * directory, setting/getting file attributes, directory walkers, etc.
 */

module OSUtilities;

//TODO: File/directory walker

version (Windows) {
	private import core.sys.windows.windows;
}

/**
 * Set the process' current working directory.
 * Params: p = Path
 * Returns: 0 on success
 */
extern (C)
int setcwd_dd(char* p) {
	version (Windows) {
		return SetCurrentDirectoryA(p) != 0;
	}
	version (Posix) {
		import core.sys.posix.unistd : chdir;
		return chdir(p) == 0;
	}
}

/**
 * Get the process' current working directory.
 * Params: po
 * Returns: non-zero on success
 */
extern (C)
int getcwd_dd(char* p) {
	//TODO: Fix getcwd (remake probs)
	version (Windows) {
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
 * Returns: 1 on found
 */
extern (C)
int pexist(char* p) {
	version (Windows) {
		return GetFileAttributesA(p) != 0xFFFF_FFFF;
	}
	version (Posix) {
		import core.sys.posix.sys.stat;
		debug import core.stdc.stdio;
		__gshared stat_t s;
		return stat(p, &s) == 0;
		//debug printf("mode: %X \n", s.st_mode);
		//return s.st_mode != 0;
	}
}

/**
 * Verifies if given path is a directory
 *
 * Returns: not-zero on success
 */
extern (C)
int pisdir(char* p) {
	version (Windows) {
		return GetFileAttributesA(p) == 0x10; // FILE_ATTRIBUTE_DIRECTORY
	}
	version (Posix) {
		import core.sys.posix.sys.stat;
		debug import core.stdc.stdio;
		__gshared stat_t s;
		stat(p, &s);
		return S_ISDIR(s.st_mode);
	}
}