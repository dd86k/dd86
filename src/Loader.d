/*
 * Loader.d : File loader.
 */

module Loader;

import core.stdc.stdio;
import std.path, std.file;
import dd_dos, Interpreter, InterpreterUtils, Logger;

/// MS-DOS EXE header
private struct mz_hdr { align(1):
	//ushort e_magic;        /* Magic number, "MZ" */
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

/**
 * Load a file in memory.
 * Params:
 *   path = Path to executable
 *   args = Executable arguments
 */
void LoadFile(string path, string args = null) {
    if (exists(path)) {
        if (Verbose)
            log("File exists");
        FILE* f = fopen(cast(char*)(path ~ '\0'), "rb");
        fseek(f, 0, SEEK_END);
        int fsize = ftell(f);
        if (Verbose)
            logd("File size: ", fsize);

        char[2] sig;
        fread(&sig, 2, 1, f);

        if (fsize == 0)
        {
            if (Verbose)
                log("File is zero length.", LogLevel.Error);
            return;
        }

        switch (sig) {
        case "MZ": // Party time!
            if (Verbose)
                log("MZ detected");
            mz_hdr mzh;
            fread(&mzh, mzh.sizeof, 1, f);

            /*if (mzh.e_magic != MZ_MAGIC) {
                if (Verbose) log("EXEC failed magic test");
                AL = 3;
                return;
            }*/

            /*if (mzh.e_lfanew)
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

            if (mzh.e_minalloc && mzh.e_maxalloc) // High memory
            {
                if (Verbose) log("HIGH MEM");
            }
            else // Low memory
            {
                if (Verbose) log("LOW MEM");
            }

            const uint headersize = mzh.e_cparh * 16;
            uint imagesize = (mzh.e_cp * 512) - headersize;
            if (mzh.e_cblp)
                imagesize -= 512 - mzh.e_cblp;
            /*if (headersize + imagesize < 512)
            imagesize = 512 - headersize;*/

            logd("HDR_SIZE: ", headersize);
            logd("IMG_SIZE: ", imagesize);

            if (mzh.e_crlc) {
                if (Verbose)
                    log("Relocating...");
                fseek(f, mzh.e_lfarlc, SEEK_SET);
                // Relocation table
                mz_rlc[] rlct = new mz_rlc[mzh.e_crlc];
                fread(&rlct, mzh.e_crlc, 1, f);

                const int m = mzh.e_crlc * 2;
                for (int i = 0; i < m; i += 2)
                { //TODO: relocations

                }
            }
            else if (Verbose) log("No relocations");

            /*uint minsize = imagesize + (e_minalloc << 4) + 256;
            uint maxsize = e_maxalloc ?
                imagesize + (e_maxalloc << 4) + 256 :
                0xFFFF;*/

            DS = ES = 0; // DS:ES (??????)
            
            CS = mzh.e_cs;
            IP = mzh.e_ip;
            //CS = 0;
            //IP = 0x100;
            SS = mzh.e_ss;
            SP = mzh.e_sp;
            //uint l = GetIPAddress;

            ubyte[] t = new ubyte[imagesize];
            fseek(f, headersize, SEEK_SET);
            fread(&t, t.length, 1, f);
            Insert(t);

            // Make PSP
            //MakePSP(GetIPAddress, "test");
            break; // "MZ"
        default:
            if (fsize > 0xFF00) { // Size - PSP
                if (Verbose)
					log("COM file too large", LogLevel.Error);
                AL = 3;
                return;
            }
            if (Verbose)
                log("Loading COM... ");
            CS = 0; EIP = 0x100;
            fseek(f, 0, SEEK_SET);
            fread(cast(ubyte*)bank + EIP, fsize, 1, f);

            //MakePSP(GetIPAddress - 0x100, "TEST");
            break;
        }
    }
    else if (Verbose)
        printf("[VMLE] File %s does not exist, skipping\n",
            cast(char*)path);
}