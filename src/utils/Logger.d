module Logger;

import core.stdc.stdio;

enum {
	L_SILENCE = 0, /// Complete silence
	L_CRIT, /// Non-recoverable errors, program stopped
	L_ERROR, /// Recovarable error, flow halted
	L_WARN, /// Flow may be halted in the near future
	L_INFO, /// Informal message, can be a little verbose!
	L_DEBUG /// Usually unused, and the debug 
}

/// Verbosity level
debug
public __gshared ubyte Verbose = L_INFO;
else
public __gshared ubyte Verbose = L_CRIT;

//TODO: template?
debug void _debug(immutable(char)* msg) {
	printf("[....] %s\n", msg);
}

debug void logexec(ushort seg, ushort ip, ubyte op) {
	printf("[ VM ] %04X:%04X  %02Xh\n", seg, ip, op);
}

/// Log an informational message
/// Params: msg = Message
void info(immutable(char)* msg) {
	if (Verbose < L_INFO) return;
	printf("[INFO] %s\n", msg);
}

/// Log a warning message
/// Params: msg = Message
void warn(immutable(char)* msg) {
	if (Verbose < L_WARN) return;
	printf("[WARN] %s\n", msg);
}

/// Log an error
/// Params: msg = Message
void error(immutable(char)* msg) {
	if (Verbose < L_ERROR) return;
	printf("[ERR!] %s\n", msg);
}

void crit(immutable(char)* msg, ubyte code = 0xff) {
	if (Verbose < L_CRIT) return;
	import core.stdc.stdlib : exit;
	import vdos : panic;
	panic(msg);
	exit(code);
}