/*
 * codes.d: Error codes used for vDOS, DD-DOS, and the CLI.
 */

module vdos_codes;

/*
 * DOS error codes
 * Prefix: E_
 * Source: DOSSYM.ASM (MS-DOS 2.0 source)
 * Source: FreeDOS
 */
enum : ubyte {
	E_NONE		= 0,
	E_INVALID_FUNCTION		= 1,
	E_FILE_NOT_FOUND		= 2,
	E_PATH_NOT_FOUND		= 3,
	E_TOO_MANY_OPENED_FILES		= 4,
	E_ACCESS_DENIED		= 5,
	E_INVALID_HANDLE		= 6,
	E_ARENA_TRASHED		= 7,
	E_NOT_ENOUGH_MEMORY		= 8,
	E_INVALID_BLOCK		= 9,
	E_BAD_ENVIRONMENT		= 10,
	E_BAD_FORMAT		= 11,
	E_INVALID_ACCESS		= 12,
	E_INVALID_DATA		= 13,
//    ;**** unused          = 14,
	E_INVALID_DRIVE		= 15,
	E_CURRENT_DIRECTORY		= 16,
	E_NOT_SAME_DEVICE		= 17,
	E_NO_MORE_FILES		= 18,	// also DE_WRTPRTCT
	//E_INVALID_BLOCK		= 20,
	E_INVALID_BUFFER		= 24,	/// Invalid buffer size
	E_SEEK		= 25,	/// Seek error (file)
	E_DISK_FULL		= 28, /// Handle disk full, likely used internally
	E_DEADLOCK		= 36,
	E_LOCK		= 39,
	E_FILE_EXISTS	= 80,
	E_INVALID_PARAMETER		= 87,	/// Invalid parameter
}

/+
/* Critical error flags                                         */
#define EFLG_READ       0x00    /* Read error                   */
#define EFLG_WRITE      0x01    /* Write error                  */
#define EFLG_RSVRD      0x00    /* Error in rserved area        */
#define EFLG_FAT        0x02    /* Error in FAT area            */
#define EFLG_DIR        0x04    /* Error in dir area            */
#define EFLG_DATA       0x06    /* Error in data area           */
#define EFLG_ABORT      0x08    /* Handler can abort            */
#define EFLG_RETRY      0x10    /* Handler can retry            */
#define EFLG_IGNORE     0x20    /* Handler can ignore           */
#define EFLG_CHAR       0x80    /* Error in char or FAT image   */

/* error results returned after asking user                     */
/* MS-DOS compatible -- returned by CriticalError               */
#define CONTINUE        0
#define RETRY           1
#define ABORT           2
#define FAIL            3
+/

/*
 * DD-DOS Critical Error Codes
 * Prefix: PANIC_
 * Source: DD-DOS Technical Reference Manual
 */
enum : ushort {
	PANIC_FILE_NOT_LOADED	= 0x03,
	PANIC_UNKNOWN	= 0xFF,
	PANIC_MEMORY_ACCESS	= 0x100,
	PANIC_MANUAL	= 0xDEAD,
}