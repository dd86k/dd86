module Logger;

import core.stdc.stdio;
import std.string : format;

bool Logging;

enum LogLevel {
    Information = 1, Warning, Error, Critical
}

//TODO: Change format from [VMxx] to [NNNx] where NNN is source

/// Log a simple message
void log(string msg, int level = 1, string src = __FILE__)
{
    //import std.string : format;
    version (Have_dd_dos) // DUB with src\
        printf("[VM%c%c] %s\n", src[4], getLevel(level), cast(char*)msg);
    else // Compiled manually
        printf("[VM%c%c] %s\n", src[0], getLevel(level), cast(char*)msg);

    //TODO: Logging in file
}

/// Log string
void logs(string msg, string v, int level = 1, string src = __FILE__)
{
    //import std.string : format;
    log(msg ~ v, level, src);
}

/// Log hex byte
void loghb(string msg, ubyte op, int level = 1, string src = __FILE__)
{
    log(format("%s%02X", msg, op), level, src);
}

/// Log decimal
void logd(string msg, long op, int level = 1, string src = __FILE__)
{
    log(format("%s%d", msg, op), level, src);
}

private char getLevel(int level)
{
    switch (level) {
    case 1: return 'I';
    case 2: return 'W';
    case 3: return 'E';
    case 4: return '!';
    default: return '?';
    }
}