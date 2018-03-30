/*
 * OSUtilities.d : Basic OS utilities
 *
 * Includes OS utilities, such as changing/getting the current working
 * directory, setting/getting file attributes, directory walkers, etc.
 */

module OSUtilities;

version (Windows) {
	private import core.sys.windows.windows;
} else {

}

/**
 * Sets the process' current working directory.
 * Params: p = Path
 * Returns: 0 on success
 */
extern (C)
int setcwd(immutable(char)* p) {
	version (Windows) {
		return SetCurrentDirectoryA(p) != 0;
	} else { // POSIX

	}
}

/**
 *
 *
 *
 *
 *
 */
extern (C)
char[] getcwd(int* s) {
	version (Windows) {
		__gshared char[255] p;
		*s = GetCurrentDirectoryA(255, cast(char*)p);
		return p;
	} else { // POSIX

	}
}

/**
 * Verifies if the file or directory exists from path
 * Params: p = Path
 * Returns: 0 on found
 */
extern (C)
int fexist(immutable(char)* p) {
	version (Windows) {
		return GetFileAttributesA(p) != 0xFFFF_FFFF;
	} else {

	}
}