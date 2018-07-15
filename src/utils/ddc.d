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

extern (C) {
	void putchar(int);
	char* fgets(char*, int, shared(FILE*));
	int fputs(immutable(char)*, shared(FILE*));
}

version (CRuntime_Microsoft) {
	enum _NFILE = 20;

	struct _iobuf { align(1):
		char*	_ptr;
		int	_cnt;
		char*	_base;
		int	_flag;
		int	_file;
		int	_charbuf;
		int	_bufsiz;
		int	__tmpnum;
	}

	alias _iobuf FILE;

	enum {
		_IOFBF   = 0,
		_IOLBF   = 0x40,
		_IONBF   = 4,
		_IOREAD  = 1,     // non-standard
		_IOWRT   = 2,     // non-standard
		_IOMYBUF = 8,     // non-standard
		_IOEOF   = 0x10,  // non-standard
		_IOERR   = 0x20,  // non-standard
		_IOSTRG  = 0x40,  // non-standard
		_IORW    = 0x80,  // non-standard
		_IOAPP   = 0x200, // non-standard
		_IOAPPEND = 0x200, // non-standard
	}

	extern shared void function() _fcloseallp;

	private extern extern(C) shared FILE[_NFILE] _iob;

	shared stdin  = &_iob[0];
	shared stdout = &_iob[1];
	shared stderr = &_iob[2];
	shared stdaux = &_iob[3];
	shared stdprn = &_iob[4];
} else {
	public import core.stdc.stdio :
		stdin, stdout, stderr, fgets, fputs, FILE;
}

/*
 * sys/stat.h
 */
version (Posix) {
	extern (C) int getchar();

	//TODO: !! alises/enums/structs for stat_t
	/*struct stat_t { align(1):
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
	extern (C) int stat(char*, stat_t*);
	extern (C) int lstat(immutable(char*) filename, stat* buf);
	extern (C) int fstat(int filedesc, stat* buf);*/
}