/*
 * Loader.d : File loader.
 */

module Loader;

import main, std.stdio, std.path, std.file;

/// Load a file in virtual memory.
void LoadFile(string path)
{
    if (exists(path))
    {
        import core.stdc.string, std.uni;
        File f = File(path);

        ulong fsize = f.size;

        if (Verbose)
            writeln("File exists");

        if (fsize <= 0xFFFF_FFFFL)
            switch (toUpper(extension(f.name)))
            {
                case ".COM": {
                    if (Verbose) write("Loading COM... ");
                    uint s = cast(uint)fsize;
                    ubyte[] buf = new ubyte[s];
                    f.rawRead(buf);
                    with (machine) {
                        CS = 0; IP = 0x100;
                        ubyte* o = &memoryBank[0] + IP;
                        foreach (b; buf) *o++ = b;
                    }
                    if (Verbose) writeln("loaded");
                }
                    break;
                default: // null is included here.
            }
        else if (Verbose) writeln("Error : File too big.");
    }
    else if (Verbose)
        writefln("File %s does not exist, skipping.", path);
}