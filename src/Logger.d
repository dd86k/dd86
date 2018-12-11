module Logger;

import core.stdc.stdio : printf;

import vdos_screen, vdos_codes;

enum {
	LOG_SILENCE	= 0,	/// Complete silence
	LOG_CRIT	= 1,	/// Non-recoverable errors, program stopped
	LOG_ERROR	= 2,	/// Recovarable error, flow halted
	LOG_WARN	= 3,	/// Flow may be halted in the near future
	LOG_INFO	= 4,	/// Informal message, can be a little verbose!
	LOG_DEBUG	= 5	/// Usually only used in debug builds
}

/// Verbosity level
debug
public __gshared ubyte LOGLEVEL = LOG_DEBUG;
else
public __gshared ubyte LOGLEVEL = LOG_SILENCE;

//TODO: Figure out template to avoid re-typing debug everytime
debug void _debug(immutable(char) *msg) {
	__v_printf("[DBUG] %s\n", msg);
}
debug void logexec(ushort seg, ushort ip, ubyte op) {
	__v_printf("[ VM ] %04X:%04X  %02Xh\n", seg, ip, op);
}

/// Log an informational message
/// Params: msg = Message
void info(immutable(char) *msg) {
	if (LOGLEVEL < LOG_INFO) return;
	__v_printf("[INFO] %s\n", msg);
}

/// Log a warning message
/// Params: msg = Message
void warn(immutable(char) *msg) {
	if (LOGLEVEL < LOG_WARN) return;
	__v_printf("[WARN] %s\n", msg);
}

/// Log an error
/// Params: msg = Message
void error(immutable(char) *msg) {
	if (LOGLEVEL < LOG_ERROR) return;
	__v_printf("[ERR ] %s\n", msg);
}

void crit(immutable(char) *msg, ushort code = PANIC_UNKNOWN) {
	import core.stdc.stdlib : exit;
	import vdos : panic;
	//if (LOGLEVEL >= LOG_CRIT)
	__v_printf("[!!!!] %s\n", msg);
	panic(code);
	exit(code);
}