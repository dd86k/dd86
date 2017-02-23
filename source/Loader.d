/*
 * Loader.d : File loader.
 */

module Loader;

import main, std.stdio, std.path, std.file;

/// MS-DOS EXE header
private struct mz_hdr {
	ushort e_magic;        /* Magic number, "MZ" */
	ushort e_cblp;         /* Bytes on last page of file */
	ushort e_cp;           /* Pages in file */
	ushort e_crlc;         /* Relocations */
	ushort e_cparh;        /* Size of header in paragraphs */
	ushort e_minalloc;     /* Minimum extra paragraphs needed */
	ushort e_maxalloc;     /* Maximum extra paragraphs needed */
	ushort e_ss;           /* Initial (relative) SS value */
	ushort e_sp;           /* Initial SP value */
	ushort e_csum;         /* Checksum */
	ushort e_ip;           /* Initial IP value */
	ushort e_cs;           /* Initial (relative) CS value */
	ushort e_lfarlc;       /* File address of relocation table */
	ushort e_ovno;         /* Overlay number */
	ushort[ERESWDS] e_res; /* Reserved words */
	uint   e_lfanew;       /* File address of new exe header (usually at 0x3c) */
}

//private struct mz_bdy { }

private enum ERESWDS = 16;

enum {
    ///
    LOADER_VER = "0.0.0"
}

enum {
    /// MZ file magic
    MZ_MAGIC = 0x5A4D,
}

/// Load a file in virtual memory.
void LoadFile(string path)
{
    if (exists(path))
    {
        import core.stdc.string, std.uni;
        File f = File(path);

        const ulong fsize = f.size;

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

                case ".EXE": { // Real party starts here
                    if (e_lfanew)
                    {
                        char[2] sig;
                        f.seek(0x3c);
                        f.rawRead(sig);
                        switch (sig)
                        {
                            //case "NE", "LE", "LX", "PE":
                            default:
                        }
                    }
                    else LoadMZ(path);
                }
                    break;

                default: break; // null is included here.
            }
        else if (Verbose) writeln("Error : File too big.");
    }
    else if (Verbose)
        writefln("File %s does not exist, skipping.", path);
}

void LoadMZ(string path)
{
    mz_hdr mzh;
    {
        ubyte[mz_hdr.sizeof] buf;
        f.rawRead(buf);
        memcpy(&mzh, &buf, mz_hdr.sizeof);
    }
}