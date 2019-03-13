/**
 * logger: Logger suite, which may enable file logging as well
 */
module logger;

import vdos.ecodes : PANIC_UNKNOWN;
import vdos.video : v_printf;

extern (C):


enum LogLevel : ubyte {
	Silence = 0,	/// Complete silence
	Fatal   = 1,	/// Non-recoverable errors, program stopped
	Error   = 2,	/// Recovarable error, flow halted
	Warning = 3,	/// Flow may be halted in the near future
	Info    = 4,	/// Informal message, can be a little verbose!
	Debug   = 5	/// Usually only used in debug builds
}

/// Verbosity level
debug
public __gshared ubyte LOGLEVEL = LogLevel.Debug;
else
public __gshared ubyte LOGLEVEL = LogLevel.Silence;

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
	if (LOGLEVEL < LogLevel.Info) return;
	v_printf("[INFO] %s\n", msg);
}

/// Log a warning message
/// Params: msg = Message
void log_warm(const(char) *msg) {
	if (LOGLEVEL < LogLevel.Warning) return;
	v_printf("[WARN] %s\n", msg);
}

/// Log an error
/// Params: msg = Message
void log_error(const(char) *msg) {
	if (LOGLEVEL < LogLevel.Error) return;
	v_printf("[ERR ] %s\n", msg);
}

void log_crit(const(char) *msg, ushort code = PANIC_UNKNOWN) {
	import core.stdc.stdlib : exit;
	import vdos.os : panic;
	//if (LOGLEVEL >= LogLevel.Critical)
	v_printf("[!!!!] %s\n", msg);
	panic(code);
	exit(code);
}