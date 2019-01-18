/**
 * logger: Logger suite, which may enable file logging as well
 */
module logger;

import vdos.video, vdos.codes;

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
debug void _debug(const(char) *msg) {
	v_printf("[DBUG] %s\n", msg);
}
debug void logexec(ushort seg, ushort ip, ubyte op) {
	v_printf("[ VM ] %04X:%04X  %02Xh\n", seg, ip, op);
}

/// Log an informational message
/// Params: msg = Message
void log_info(const(char) *msg) {
	if (LOGLEVEL < LOG_INFO) return;
	v_printf("[INFO] %s\n", msg);
}

/// Log a warning message
/// Params: msg = Message
void log_warm(const(char) *msg) {
	if (LOGLEVEL < LOG_WARN) return;
	v_printf("[WARN] %s\n", msg);
}

/// Log an error
/// Params: msg = Message
void log_error(const(char) *msg) {
	if (LOGLEVEL < LOG_ERROR) return;
	v_printf("[ERR ] %s\n", msg);
}

void log_crit(const(char) *msg, ushort code = PANIC_UNKNOWN) {
	import core.stdc.stdlib : exit;
	import vdos.os : panic;
	//if (LOGLEVEL >= LOG_CRIT)
	v_printf("[!!!!] %s\n", msg);
	panic(code);
	exit(code);
}