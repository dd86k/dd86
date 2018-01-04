/*
 * codes.d: Error codes. Mostly extracted from DOSSYM.ASM
 */

module codes;

enum : ubyte {
	no_error_occurred               = 0,
	error_invalid_function          = 1,
	error_file_not_found            = 2,
	error_path_not_found            = 3,
	error_too_many_open_files       = 4,
	error_access_denied             = 5,
	error_invalid_handle            = 6,
	error_arena_trashed             = 7,
	error_not_enough_memory         = 8,
	error_invalid_block             = 9,
	error_bad_environment           = 10,
	error_bad_format                = 11,
	error_invalid_access            = 12,
	error_invalid_data              = 13,
//	;**** unused                    = 14,
	error_invalid_drive             = 15,
	error_current_directory         = 16,
	error_not_same_device           = 17,
	error_no_more_files             = 18,

	exec_invalid_function           = error_invalid_function,
	exec_bad_environment            = error_bad_environment,
	exec_bad_format                 = error_bad_format,
	exec_not_enough_memory          = error_not_enough_memory,
	exec_file_not_found             = error_file_not_found,
}