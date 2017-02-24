module dd_dos;

import Interpreter;

pragma(msg, "Compiling DD-DOS v", APP_VERSION, "...");
pragma(msg, "Reporting DOS v", DOS_MAJOR_VERSION, ".", DOS_MINOR_VERSION);

/// DD-DOS version.
enum APP_VERSION = "0.0.0";

enum {
    /// Minor reported DOS version
    DOS_MINOR_VERSION = 0,
    /// Major reported DOS version
    DOS_MAJOR_VERSION = 0
}

/// Verbose flags
static bool Verbose;

/// Current machine
static Intel8086 machine;
