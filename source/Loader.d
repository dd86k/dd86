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
        import core.stdc.string, std.string;
        File f = File(path);

        if (Verbose)
            writeln("File exists");

        if (f.size <= 0xFFFF_FFFFL)
            switch (capitalize(extension(f.name)))
            {
                case ".COM": {
                    if (Verbose) write("Loading COM... ");
                    uint s = cast(uint)f.size;
                    ubyte[] buf = f.rawRead(new ubyte[s]);
                    with (machine) {
                        CS = 0; IP = 0x100;
                        ubyte* offset = &machine.memoryBank[0];
                        memcpy(offset, &buf, s);
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