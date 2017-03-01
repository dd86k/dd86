/*
 * Loader.d : File loader.
 */

module Loader;

import main, std.stdio, std.path, std.file, dd_dos;

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

enum {
    ///
    LOADER_VER = "0.0.0"
}

enum {
    /// MZ file magic
    MZ_MAGIC = 0x5A4D,
}

/// Load a file in virtual memory.
void LoadFile(string path, string args = null)
{
    if (exists(path))
    {
        import core.stdc.string, std.uni;
        File f = File(path);

        const ulong fsize = f.size;

        if (Verbose)
            writeln("[VMLI] File exists");

        if (fsize == 0)
        {
            if (Verbose)
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
                        if (Verbose)
                            writeln("[VMLE] COM file too large.");
                        return;
                    }
                    if (Verbose) write("[VMLI] Loading COM... ");
                    uint s = cast(uint)fsize;
                    ubyte[] buf = new ubyte[s];
                    f.rawRead(buf);
                    with (machine) {
                        CS = 0; IP = 0x100;
                        ubyte* o = &memoryBank[0] + IP;
                        foreach (b; buf) *o++ = b;

                        MakePSP(GetIPAddress - 0x100, "TEST");
                    }
                    if (Verbose) writeln("loaded");
                }
                    break;

                case ".EXE": { // Real party starts here
                    mz_hdr mzh;
                    {
                        ubyte[mz_hdr.sizeof] buf;
                        f.rawRead(buf);
                        memcpy(&mzh, &buf, mz_hdr.sizeof);
                    }

                    with (mzh) {
                        if (e_lfanew)
                        {
                            char[2] sig;
                            f.seek(e_lfanew);
                            f.rawRead(sig);
                            /*switch (sig)
                            {
                            //case "NE":
                            default:
                                if (Verbose)
                                    writeln("Unsupported format : ", sig);
                                return;
                            }*/
                        }

                        if (Verbose)
                            writeln("[VMLI] Loading MZ");

                        /*
                         * MZ File loader, temporary
                         */
                        
                         /*if (e_minalloc && e_maxalloc) // High memory
                         {

                         }
                         else // Low memory
                         {

                         }*/
                         
                         uint headersize = e_cparh * 16;
                         uint imagesize = (e_cp * 512) - headersize;
                         //if (e_cblp) imagesize -= 512 - e_cblp;
                         if (headersize + imagesize < 512)
                            imagesize = 512 - headersize;

                         with (machine) {
                            if (e_crlc)
                            {
                                f.seek(e_lfarlc);
                                // Relocation table
                                mz_rlc[] rlct = new mz_rlc[e_crlc];
                                f.rawRead(rlct);

                                const int m = e_crlc * 2;
                                for (int i = 0; i < m; i += 2)
                                {

                                }
                            }
                            else
                                writeln("[VMLI] No relocations");

                            /*uint minsize = imagesize + (e_minalloc << 4) + 256;
                            uint maxsize = e_maxalloc ?
                                imagesize + (e_maxalloc << 4) + 256 :
                                0xFFFF;*/

                            DS = ES = 0; // DS:ES
                            
                            //CS = e_cs;
                            //IP = e_ip;
                            CS = 0;
                            IP = 0x100;
                            SS = e_ss;
                            SP = e_sp;
                            //uint l = GetIPAddress;

                            ubyte[] t = new ubyte[imagesize];
                            f.seek(headersize + 16);
                            f.rawRead(t);
                            Insert(t);

                            // Make PSP
                            MakePSP(machine.GetIPAddress, "test");
                         }
                    }
                }
                    break;

                default: break; // null is included here.
            }
        }
        else if (Verbose) writeln("[VMLE] File is too big.");
    }
    else if (Verbose)
        writefln("[VMLE] File %s does not exist, skipping.", path);
}