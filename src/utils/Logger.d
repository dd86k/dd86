module Logger;

import core.stdc.stdio;

pragma(msg, "Compiling logger"); // temporary

/// Log an informational message
/// Params: msg = Message
void log(immutable(char)* msg) {
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

debug void logexec(ushort seg, ushort ip, ubyte op) {
	printf("[ VM ] %04X:%04X  %02Xh\n", seg, ip, op);
}