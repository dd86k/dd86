/*
 * Loader.d : File loader.
 */

module Loader;

import std.stdio, std.path, std.file, dd_dos, Interpreter;

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
	uint   e_lfanew;       /* File address of new exe header */
}
private enum ERESWDS = 16;

private struct mz_rlc { // For AL=03h
    ushort segment, relocation; // reloc factor
}

/// MZ file magic
private enum MZ_MAGIC = 0x5A4D;

/// Load a file in virtual memory.
void LoadFile(string path, string args = null, bool verbose = false)
{
    //TODO: args
    if (exists(path))
    {
        import core.stdc.string : memcpy;
        import std.uni : toUpper;
        File f = File(path);

        const ulong fsize = f.size;

        if (verbose)
            writeln("[VMLI] File exists");

        if (fsize == 0)
        {
            if (verbose)
                writeln("[VMLE] File is zero length.");
            return;
        }

        if (fsize <= 0xFFF_FFFFL)
        {
            switch (toUpper(extension(f.name)))
            {
                case ".COM": {
                    if (fsize > 0xFF00) // Size - PSP
                    {
                        if (verbose)
                            writeln("[VMLE] COM file too large.");
                        AL = LastErrorCode = 3;
                        return;
                    }
                    if (verbose) write("[VMLI] Loading COM... ");
                    uint s = cast(uint)fsize;
                    ubyte[] buf = new ubyte[s];
                    f.rawRead(buf);
                    CS = 0; IP = 0x100;
                    ubyte* bankp = &bank[0] + IP;
                    memcpy(bankp, &buf[0], buf.length);

                    //MakePSP(GetIPAddress - 0x100, "TEST");
                    if (verbose) writeln("loaded");
                }
                    break;

                case ".EXE": { // Real party starts here
                    if (verbose) write("[VMLI] Loading EXE... ");
                    mz_hdr mzh;
                    {
                        ubyte[mz_hdr.sizeof] buf;
                        f.rawRead(buf);
                        memcpy(&mzh, &buf, mz_hdr.sizeof);
                    }

                    with (mzh) {
                        /*if (e_lfanew)
                        {
                            char[2] sig;
                            f.seek(e_lfanew);
                            f.rawRead(sig);
                            switch (sig)
                            {
                            //case "NE":
                            default:
                            }
                        }*/

                        if (verbose)
                            writeln("[VMLI] Loading MZ");

                        /*
                         * MZ File loader, temporary
                         */
                        
                         if (e_minalloc && e_maxalloc) // High memory
                         {
                            writeln("[VMLI] HIGH MEM");
                         }
                         else // Low memory
                         {
                            writeln("[VMLI] LOW MEM");
                         }
                         
                         const uint headersize = e_cparh * 16;
                         uint imagesize = (e_cp * 512) - headersize;
                         if (e_cblp) imagesize -= 512 - e_cblp;
                         /*if (headersize + imagesize < 512)
                            imagesize = 512 - headersize;*/
                         writeln("[VMLI] HDR_SIZE: ", headersize);
                         writeln("[VMLI] IMG_SIZE: ", imagesize);

                        if (e_crlc)
                        {
                            if (verbose)
                                writeln("[VMLI] Relocating...");
                            f.seek(e_lfarlc);
                            // Relocation table
                            mz_rlc[] rlct = new mz_rlc[e_crlc];
                            f.rawRead(rlct);

                            const int m = e_crlc * 2;
                            for (int i = 0; i < m; i += 2)
                            { //TODO: relocations

                            }
                        }
                        else if (verbose)
                            writeln("[VMLI] No relocations");

                        /*uint minsize = imagesize + (e_minalloc << 4) + 256;
                        uint maxsize = e_maxalloc ?
                            imagesize + (e_maxalloc << 4) + 256 :
                            0xFFFF;*/

                        ubyte[] t = new ubyte[imagesize];
                        f.seek(headersize);
                        f.rawRead(t);
                        Insert(t);

                        DS = ES = 0; // DS:ES (??????)
                        
                        CS = e_cs;
                        IP = e_ip;
                        //CS = 0;
                        //IP = 0x100;
                        SS = e_ss;
                        SP = e_sp;
                        //uint l = GetIPAddress;

                        // Make PSP
                        MakePSP(GetIPAddress, "test");
                    }
                }
                    break;

                default: break; // null is included here.
            }
        }
        else if (verbose) writeln("[VMLE] File is too big.");
    }
    else if (verbose)
        writefln("[VMLE] File %s does not exist, skipping.", path);
}