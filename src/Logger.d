module Logger;

import std.stdio;

bool Logging;

enum LogLevel {
    Information = 1, Warning, Error, Critical
}

/// Log a simple message
void log(string msg, int level = 1, string src = __FILE__)
{
    //import std.string : format;
    writefln("[VM%c%c] %s", src[4], getLevel(level), msg);

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
    import std.string : format;
    log(format("%s%02X", msg, op), level, src);
}

private char getLevel(int level)
{
    switch (level)
    {
        case 1: return 'I';
        case 2: return 'W';
        case 3: return 'E';
        case 4: return '!';
        default:return '?';
    }
}