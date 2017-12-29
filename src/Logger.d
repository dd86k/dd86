module Logger;

import core.stdc.stdio;
import std.string : format;

enum LogLevel {
    Information = 1, Warning, Error, Critical
}

/// Log a simple message
void log(string msg, int level = 1, string src = __FILE__)
{
    debug printf("%s::", cast(char*)src);
    final switch (level) {
    case LogLevel.Information:
        printf("[INFO] %s\n", cast(char*)msg);
        break;
    case LogLevel.Warning:
        printf("[WARN] %s\n", cast(char*)msg);
        break;
    case LogLevel.Error:
        printf("[ERR ] %s\n", cast(char*)msg);
        break;
    case LogLevel.Critical:
        printf("[!!!!] %s\n", cast(char*)msg);
        break;
    }

    //TODO: Logging in file (maybe)
}

/// Log string
void logs(string msg, string v, int level = 1, string src = __FILE__)
{
    // As much as I would of liked avoiding using the GC..
    log(msg ~ v, level, src);
}

/// Log hex byte
void loghb(string msg, ubyte op, int level = 1, string src = __FILE__)
{
    log(format("%s%02X\0", msg, op), level, src);
}

/// Log decimal
void logd(string msg, long op, int level = 1, string src = __FILE__)
{
    log(format("%s%d\0", msg, op), level, src);
}