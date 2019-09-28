/**
 * Error facility
 */
module err;

__gshared:
extern (C):

/*
 * DOS error codes
 * Prefix: EDOS_
 * Source:
 *   DOSSYM.ASM (MS-DOS 2.0 source)
 *   FreeDOS
 */
enum : ubyte {
	/// Successful
	EDOS_SUCCESS	= 0,
	/// Invalid function (ms-dos service)
	EDOS_INVALID_FUNCTION	= 1,
	EDOS_FILE_NOT_FOUND	= 2,
	EDOS_PATH_NOT_FOUND	= 3,
	EDOS_TOO_MANY_OPENED_FILES	= 4,
	EDOS_ACCESS_DENIED	= 5,
	EDOS_INVALID_HANDLE	= 6,
	EDOS_ARENA_TRASHED	= 7,
	EDOS_NOT_ENOUGH_MEMORY	= 8,
	EDOS_INVALID_BLOCK	= 9,
	EDOS_BAD_ENVIRONMENT	= 10,
	EDOS_BAD_FORMAT	= 11,
	EDOS_INVALID_ACCESS	= 12,
	EDOS_INVALID_DATA	= 13,
//	;**** unused	= 14,
	EDOS_INVALID_DRIVE	= 15,
	EDOS_CURRENT_DIRECTORY	= 16,
	EDOS_NOT_SAME_DEVICE	= 17,
	EDOS_NO_MORE_FILES	= 18,	/// also DE_WRTPRTCT
	//EDOS_INVALID_BLOCK	= 20,
	EDOS_INVALID_BUFFER	= 24,	/// Invalid buffer size
	EDOS_SEEK	= 25,	/// Seek error (file)
	EDOS_DISK_FULL	= 28,	/// Handle disk full, likely used internally
	EDOS_DEADLOCK	= 36,
	EDOS_LOCK	= 39,
	EDOS_FILE_EXISTS	= 80,
	EDOS_INVALID_PARAMETER	= 87,	/// Invalid parameter

	E_MM_OK	= 0,
	E_MM_OVRFLW	= 1,
}

/+
#define EFLG_READ       0x00    /// Read error
#define EFLG_WRITE      0x01    /// Write error
#define EFLG_RSVRD      0x00    /// Error in rserved area
#define EFLG_FAT        0x02    /// Error in FAT area
#define EFLG_DIR        0x04    /// Error in dir area
#define EFLG_DATA       0x06    /// Error in data area
#define EFLG_ABORT      0x08    /// Handler can abort
#define EFLG_RETRY      0x10    /// Handler can retry
#define EFLG_IGNORE     0x20    /// Handler can ignore
#define EFLG_CHAR       0x80    /// Error in char or FAT image

/* error results returned after asking user                     */
/* MS-DOS compatible -- returned by CriticalError               */
#define CONTINUE        0
#define RETRY           1
#define ABORT           2
#define FAIL            3
+/

/*
 * DD/86 Critical Error Codes
 * Prefix: PANIC_
 * Source: DD/86 Technical Reference Manual
 */
enum : ushort {
	PANIC_FILE_NOT_LOADED	= 0x03,
	PANIC_UNKNOWN	= 0xFF,
	PANIC_MEMORY_ACCESS	= 0x100,
	PANIC_MANUAL	= 0xDEAD,
}

/// Used by: vcpu.*, and os.* functions
uint errno;

/**
 *
 * Returns: 
 */
const(char) *err_str() {
	switch (errno) {
		//
		// DOS
		//
		case EDOS_SUCCESS:
			return "success";
		//
		// MM
		//
		//
		// Other
		//
		default:
			return "(no description)";
	}
}

void err_perror(const(char)* func) {
	import core.stdc.stdio : printf;
	printf("%s: %s", func, err_str);
}