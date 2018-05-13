module Logger;

import core.stdc.stdio;

//TODO: template?
debug void _debug(immutable(char)* msg) {
	printf("[....] %s\n", msg);
}

/// Log an informational message
/// Params: msg = Message
void info(immutable(char)* msg) {
	printf("[INFO] %s\n", msg);
}

/// Log a warning message
/// Params: msg = Message
void warn(immutable(char)* msg) {
	printf("[WARN] %s\n", msg);
}

/// Log an error
/// Params: msg = Message
void error(immutable(char)* msg) {
	printf("[ERR!] %s\n", msg);
}

void crit(immutable(char)* msg, ubyte code = 0xff) {
	import core.stdc.stdlib : exit;
	import vdos : panic;
	panic(msg);
	exit(code);
}

debug void logexec(ushort seg, ushort ip, ubyte op) {
	printf("[ VM ] %04X:%04X  %02Xh\n", seg, ip, op);
}