/*
 * OSUtilities.d : Basic OS utilities
 *
 * Includes OS utilities, such as changing/getting the current working
 * directory, setting/getting file attributes, directory walkers, etc.
 */

module OSUtilities;

version (Windows) {
	private import core.sys.windows.windows;
}

/**
 * Set the process' current working directory.
 * Params: p = Path
 * Returns: 0 on success
 */
extern (C)
int setcwd(immutable(char)* p) {
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
 * Returns: 1 on success
 */
extern (C)
int getcwd(char* p) {
	version (Windows) {
		return GetCurrentDirectoryA(255, p);
	}
	version (Posix) {
		//TODO: Fix getcwd usage
		import core.sys.posix.unistd : getcwd;
		getcwd(p, 255);
		return 1;
	}
}

/**
 * Verifies if the file or directory exists from path
 * Params: p = Path
 * Returns: 0 on found
 */
extern (C)
int pexist(immutable(char)* p) {
	version (Windows) {
		return GetFileAttributesA(p) != 0xFFFF_FFFF;
	}
	version (Posix) {
		import core.sys.posix.sys.stat;
		debug import core.stdc.stdio;
		stat_t s;
		stat(p, &s);
		debug printf("mode: %X \n", s.st_mode);
		return s.st_mode != 0;
	}
}

/**
 * Verifies if the file or directory exists from path
 * Params: p = Path
 * Returns: 0 on found
 */
/*extern (C)
int fexist(FILE* f) {
	version (Windows) {
		
	}
	version (linux) {

	}
}*/