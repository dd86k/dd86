/*
 * codes.d: Error codes used for vDOS, DD-DOS, and the CLI.
 */

module vdos_codes;

/*
 * DOS error codes
 * Prefix: E_
 * Source: DOSSYM.ASM (MS-DOS 2.0 source)
 */
enum : ubyte {
	E_NONE                  = 0,
	E_INVALID_FUNCTION      = 1,
	E_FILE_NOT_FOUND        = 2,
	E_PATH_NOT_FOUND        = 3,
	E_TOO_MANY_OPENED_FILES = 4,
	E_ACCESS_DENIED         = 5,
	E_INVALID_HANDLE        = 6,
	E_ARENA_TRASHED         = 7,
	E_NOT_ENOUGH_MEMORY     = 8,
	E_INVALID_BLOCK         = 9,
	E_BAD_ENVIRONMENT       = 10,
	E_BAD_FORMAT            = 11,
	E_INVALID_ACCESS        = 12,
	E_INVALID_DATA          = 13,
//    ;**** unused          = 14,
	E_INVALID_DRIVE         = 15,
	E_CURRENT_DIRECTORY     = 16,
	E_NOT_SAME_DEVICE       = 17,
	E_NO_MORE_FILES         = 18,
}

/*
 * DD-DOS Critical Error Codes
 * Prefix: PANIC_
 * Source: DD-DOS Technical Reference Manual 2018.1
 */
enum : ushort {
	PANIC_FILE_NOT_LOADED	= 0x03,
	PANIC_UNKNOWN	= 0xFF,
	PANIC_MANUAL	= 0xDEAD,
}