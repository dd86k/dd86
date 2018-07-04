/*
 * ddc.d : C runtime bindings, subset of DD's C extern definitions (signatures)
 *
 * Why? Because some functions are externed as (D) in core.stdc, which does not
 * mangle well with the linker (D mangles for C externs, really?!). This source
 * is also the beginning of the departure of the standard D library (core.stdc).
 *
 * This also adds some enumerations and aliases to aid development.
 */

module ddc;

enum NULL_CHAR = cast(char*)0; /// Null character pointer

extern (C) void putchar(int);

/*
 * sys/stat.h
 */
version (Posix) {
	struct stat { align(1):
		mode_t st_mode;
		ino_t st_ino;
		dev_t st_dev;
		dev_t st_rdev;
		nlink_t st_nlink;
		uid_t st_uid;
		gid_t st_gid;
		off_t st_size;
		timespec st_atim;
		timespec st_mtim;
		timespec st_ctim;
		blksize_t st_blksize;
		blkcnt_t st_blocks;
	}
	extern extern (C) int stat(char*, stat_t*);
	extern extern (C) int lstat(immutable(char*) filename, stat* buf);
	extern extern (C) int fstat(int filedesc, stat* buf);
}