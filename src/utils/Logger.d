module Logger;

import core.stdc.stdio;
import std.string : format;

/// Log levels, see documentation for more details.
enum Log : ubyte {
	Debug,       /// Debugging information
	Information, /// Informational
	Warning,     /// Warnings
	Error,       /// Errors
	Critical     /// Critical messages (could not continue)
}

/// Log a simple message
void log(string msg, int level = Log.Information, ...) {
	import core.vararg;
	const size_t al = _arguments.length;
	immutable char* _p = cast(immutable char*)msg;

    for (size_t i; i < al; ++i) {
		final switch (level) {
		case Log.Debug:
			printf("[ ~~ ] %s", _p);
			break;
		case Log.Information:
			printf("[INFO] %s", _p);
			break;
		case Log.Warning:
			printf("[WARN] %s", _p);
			break;
		case Log.Error:
			printf("[ERR ] %s", _p);
			break;
		case Log.Critical:
			printf("[ !! ] %s", _p);
			break;
		}

        if (_arguments[i] == typeid(int)) {
            const int j = va_arg!(int)(_argptr);
            printf("%d", j);
        } else if (_arguments[i] == typeid(long)) {
            const long j = va_arg!(long)(_argptr);
            printf("%d", j);
        } else if (_arguments[i] == typeid(string)) {
            const char* j = va_arg!(char*)(_argptr);
            printf("%s", j);
        } else printf("?");
    }

	puts("");

	//TODO: Log in file when enabled
}

/// Log hex byte
void loghb(string msg, ubyte op, int level = Log.Information) {
	log(format("%s%02X\0", msg, op), level);
}

/// Log decimal
void logd(string msg, long op, int level = Log.Information) {
	log(format("%s%d\0", msg, op), level);
}

debug void logexec(string msg, ushort seg, ushort ip, ubyte op) {
	log(format("%s %4X:%4X    %02Xh\0", msg, seg, ip, op), Log.Debug);
}