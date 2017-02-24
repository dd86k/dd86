module dd_dos;

import Interpreter;

/// Verbose flags
static bool Verbose;

/// Current machine
static Intel8086 machine;

enum {
    /// Minor reported DOS version
    DOS_MINOR_VERSION = 0,
    /// Major reported DOS version
    DOS_MAJOR_VERSION = 0
}