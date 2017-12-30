/*
 * Loader.d : Executable file loader.
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
	ushort e_crlc;         /* Number of relocation entries */
	ushort e_cparh;        /* Size of header in paragraphs */
	ushort e_minalloc;     /* Minimum extra paragraphs needed */
	ushort e_maxalloc;     /* Maximum extra paragraphs needed */
	ushort e_ss;           /* Initial (relative) SS value */
	ushort e_sp;           /* Initial SP value */
	ushort e_csum;         /* Checksum, ignored */
	ushort e_ip;           /* Initial IP value */
	ushort e_cs;           /* Initial (relative) CS value */
	ushort e_lfarlc;       /* File address (byte offset) of relocation table */
	ushort e_ovno;         /* Overlay number */
	//ushort[ERESWDS] e_res; /* Reserved words */
	//uint   e_lfanew;       /* File address of new exe header */
}
private enum ERESWDS = 16;

private struct mz_rlc { // For AL=03h
	ushort offset; /// Offset within segment
	ushort segment; // Segment of relocation
}

/// MZ file magic
private enum MZ_MAGIC = 0x5A4D;

private enum {
	PARAGRAPH = 16,
	PAGE = 512
}

/**
 * Load an executable file in memory.
 * Params:
 *   path = Path to executable
 *   args = Executable arguments
 */
void LoadExec(string path, string args = null) {
	if (exists(path)) {
		if (Verbose)
			log("File exists");

		FILE* f = fopen(cast(char*)(path ~ '\0'), "rb"); // A little sad, I know
		fseek(f, 0, SEEK_END);
		int fsize = ftell(f);

		if (Verbose)
			logd("File size: ", fsize);

		ushort sig;
		fseek(f, 0, SEEK_SET);
		fread(&sig, 2, 1, f);

		if (fsize == 0) {
			if (Verbose)
				log("File is zero length.", LogLevel.Error);
			AL = 2; // Non-official
			return;
		}

		switch (sig) {
		case MZ_MAGIC: // Party time!
			/* Reserved code for Windows 286/386 era
			if (mzh.e_lfanew) {
				char[2] sig;
				f.seek(e_lfanew);
				f.rawRead(sig);
				switch (sig) {
				//case "NE":
				default:
				}
			}*/

			if (Verbose)
				log("LOAD MZ");
			
			// ** Header is read for initial register values
			mz_hdr mzh;
			fread(&mzh, mzh.sizeof, 1, f);
			CS = 0; IP = 0x100; // Temporary
			//CS = mzh.e_cs;
			//IP = mzh.e_ip;
			SS = mzh.e_ss;
			SP = mzh.e_sp;

			// ** Copy code section from exe into memory
			if (mzh.e_minalloc && mzh.e_maxalloc) { // High memory
				if (Verbose)
					log("LOAD IN HIGH MEM");
			} else { // Low memory
				if (Verbose)
					log("LOAD IN LOW MEM");
			}
			const uint headersize = mzh.e_cparh * PARAGRAPH;
			uint codesize = (mzh.e_cp * PAGE) - headersize;
			if (mzh.e_cblp) // Adjust codesize for last bytes in page
				codesize -= 512 - mzh.e_cblp;
			/*if (headersize + codesize < 512)
				codesize = 512 - headersize;*/
			if (Verbose) {
				debug logd("STRUCT_SIZE: ", mzh.sizeof);
				debug logd("HEADER_SIZE: ", headersize);
				debug logd("IMAGE_SIZE : ", codesize);
				logd("CS:", CS);
				logd("IP:", IP);
				logd("SS:", SS);
				logd("SP:", SP);
			}
			//TODO: Move to malloc and add an Insert(ubyte*,size_t) function
			//ubyte* t = cast(ubyte*)malloc(codesize);
			ubyte[] t = new ubyte[codesize];
			fseek(f, headersize, SEEK_SET);
			fread(&t[0], codesize, 1, f);
			Insert(t); // Insert at CS:IP

			// ** Read relocation table and adjust far pointers in memory
			if (mzh.e_crlc) {
				uint ra = headersize + mzh.e_lfarlc; // relocation file address
				uint rn = mzh.e_crlc; // number of relocations
				uint rs = rn * 2; // relocation table size
				if (Verbose) {
					logd("Relocating at ", ra);
					logd("Relocations to do: ", rn);
				}
				fseek(f, headersize, SEEK_SET);
				// Relocation table
				mz_rlc[] rlct = new mz_rlc[mzh.e_crlc];
				fread(&rlct[0], rs, 1, f);
/*
	To get the position of the relocation within the file, you have to compute the
	physical adress from the segment:offset pair, which is done by multiplying the
	segment by 16 and adding the offset and then adding the offset of the binary
	start. Note that the raw binary code starts on a paragraph boundary within the
	executable file. All segments are relative to the start of the executable in
	memory, and this value must be added to every segment if relocation is done
	manually.
	http://www.fileformat.info/format/exe/corion-mz.htm
*/
				uint ca = GetIPAddress; // current address
				ubyte* cap = cast(ubyte*)MEMORY + ca;
				for (int i; i < rn; ++i) { //TODO: relocations
					uint s = (rlct[i].segment << 4) + rlct[i].offset;
					//*(cap + s) = idk
				}
			}
			else if (Verbose) log("No relocations");

			// ** Setup registers
			// AL      drive letter
			// AH      status
			// DS:ES   Points to PSP
			// SS:SP   Stack pointer (from EXE header)

			// Jump to CS:IP, relative to start of program

			/*Push(SS);
			ushort j = Pop();*/



			/*uint minsize = codesize + (e_minalloc << 4) + 256;
			uint maxsize = e_maxalloc ?
				codesize + (e_maxalloc << 4) + 256 :
				0xFFFF;*/

			//DS = ES = 0; // DS:ES (??????)

			// Make PSP
			//MakePSP(GetIPAddress, "test");
			break; // case MZ
		default:
			if (fsize > 0xFF00) { // Size - PSP
				if (Verbose)
					log("COM file too large", LogLevel.Error);
				AL = 3;
				return;
			}
			if (Verbose)
				log("LOAD COM");
			CS = 0; EIP = 0x100;
			fseek(f, 0, SEEK_SET);
			ubyte* _comp = cast(ubyte*)MEMORY + GetIPAddress;
			fread(_comp, fsize, 1, f);

			//MakePSP(_comp - 0x100, "TEST");
			break; // case COM
		}
	}
	else if (Verbose)
		printf("[VMLE] File %s does not exist, skipping\n",
			cast(char*)path);
}