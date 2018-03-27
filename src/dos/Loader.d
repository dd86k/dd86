/*
 * Loader.d: Executable file loader. Should somewhat be like EXEC.
 */

module Loader;

import core.stdc.stdio;
import core.stdc.stdlib : malloc, free;
import dd_dos, Interpreter, InterpreterUtils, Logger;
import codes;

private enum ERESWDS = 16; /// RESERVED WORDS

/// MS-DOS EXE header
private struct mz_hdr { align(1): // Necessary fields included
//	ushort e_magic;        /// Magic number, "MZ"
	ushort e_cblp;         /// Bytes on last page of file (extra bytes), 9 bits
	ushort e_cp;           /// Pages in file
	ushort e_crlc;         /// Number of relocation entries
	ushort e_cparh;        /// Size of header in paragraphs
	ushort e_minalloc;     /// Minimum extra paragraphs needed
	ushort e_maxalloc;     /// Maximum extra paragraphs needed
	ushort e_ss;           /// Initial (relative) SS value
	ushort e_sp;           /// Initial SP value
	ushort e_csum;         /// Checksum, ignored
	ushort e_ip;           /// Initial IP value
	ushort e_cs;           /// Initial (relative) CS value
	ushort e_lfarlc;       /// File address (byte offset) of relocation table
	ushort e_ovno;         /// Overlay number
//	ushort[ERESWDS] e_res; /// Reserved words
//	uint   e_lfanew;       /// File address of new exe header
}

private struct mz_rlc { align(1): // For AL=03h
	ushort off; /// Offset
	ushort seg; /// Segment of relocation
}

/// MZ file magic
private enum MZ_MAGIC = 0x5A4D;

private enum {
	PARAGRAPH = 16, /// Size of a paragraph
	PAGE = 512, /// Size of a page
}

/**
 * Load an executable file in memory.
 * AL values are set according to error (destroyed)
 * Params:
 *   path = Path to executable
 *   args = Executable arguments
 * Returns: 0 if successfully loaded
 */
int ExecLoad(char* path) {
	FILE* f = fopen(path, "rb");
	fseek(f, 0, SEEK_END);
	int fsize = cast(int)ftell(f); // who the hell would have a >2G exec to run in DOS

	debug printf("[debug] File size: %d\n", fsize);

	__gshared ushort sig;
	fseek(f, 0, SEEK_SET);
	fread(&sig, 2, 1, f);

	if (fsize == 0) {
		fclose(f);
		if (Verbose)
			log("File is zero length.");
		AL = 2; // Non-official
		return 1;
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
		CS = 0; IP = 0; // Temporary
		//CS = CS + mzh.e_cs; // Relative
		//IP = mzh.e_ip;
		SS = cast(ushort)(SS + mzh.e_ss); // Relative
		SP = mzh.e_sp;

		// ** Copy code section from exe into memory
		if (mzh.e_minalloc && mzh.e_maxalloc) { // Low memory
			if (Verbose)
				log("LOAD LOW MEM");
		} else { // High memory
			if (Verbose)
				log("LOAD HIGH MEM");
		}
		const uint _h = mzh.e_cparh * PARAGRAPH; // Header size
		const uint _l = _h + (mz_rlc.sizeof * mzh.e_crlc); // image code offset
		uint _s = (mzh.e_cp * PAGE) - _h; // image code size
		if (mzh.e_cblp) // Adjust _s for last bytes in page
			_s -= PAGE - mzh.e_cblp;
		if (_h + _s < PAGE) // This snippet was found in DOSBox
			_s = PAGE - _h;
		debug {
			printf("[debug] _H::%d\n", _h);
			printf("[debug] _L::%d\n", _l);
			printf("[debug] STRUCT_SIZE: %d\n", mzh.sizeof);
			printf("[debug] HEADER_SIZE: %d\n", _h);
			printf("[debug] IMAGE_SIZE : %d\n", _s);
			printf("[debug] CS: %d\n", CS);
			printf("[debug] IP: %d\n", IP);
			printf("[debug] SS: %d\n", SS);
			printf("[debug] SP: %d\n", SP);
		}
		fseek(f, _l, SEEK_SET); // Seek to end of header
		fread(cast(ubyte*)MEMORY + GetIPAddress, _s, 1, f); // and read the code portion

		// ** Read relocation table and adjust far pointers in memory
		if (mzh.e_crlc) {
			if (Verbose) printf("[INFO] Relocation: %d\n", mzh.e_crlc);
			fseek(f, mzh.e_lfarlc, SEEK_SET);
			const int rs = mzh.e_crlc * mz_rlc.sizeof; /// Relocation table size
			mz_rlc* r = cast(mz_rlc*)malloc(rs); /// Relocation table
			fread(cast(void*)r, rs, 1, f); // Read whole table
			if (Verbose)
				puts(" #   seg: off -> data");
			const uint ip = GetIPAddress;
			for (int i; i < mzh.e_crlc; ++i) {
				const ushort data = FetchWord(ip + (r[i].seg << 4) + r[i].off);
				if (Verbose)
					printf("%2d  %04X:%04X -> %04X\n", i, r[i].seg, r[i].off, data);
				CS = cast(ushort)(CS + r[i].seg); // temporarily cheat
				IP = cast(ushort)(IP + r[i].off); // ditto
				//SetWord((r[i].seg << 4) + r[i].off, r[i].refseg);
			}
			free(r);
		} else {
			EIP += 0x100; // temporary
			if (Verbose)
				log("No relocations");
		}

		// ** Setup registers
		// AL      drive letter
		// AH      status
		// DS:ES   Points to PSP
		// SS:SP   Stack pointer (from EXE header)

		AL = 3;
		AH = 0;

		// ** Make PSP
		//MakePSP(GetIPAddress, "test");

		// ** Jump to CS:IP+0x0100, relative to start of program
		//EIP += 0x100;
		break; // case MZ
	default:
		if (fsize > 0xFF00) { // Size - PSP
			fclose(f);
			if (Verbose)
				log("COM file too large");
			AL = E_BAD_FORMAT;
			return 1;
		}
		if (Verbose)
			log("LOAD COM");
		CS = 0; EIP = 0x100; // Temporary
		fseek(f, 0, SEEK_SET);
		ubyte* _comp = cast(ubyte*)MEMORY + GetIPAddress;
		fread(_comp, fsize, 1, f);

		//MakePSP(_comp - 0x100, "TEST");
		AL = 0;
		break; // default (COM)
	}

	fclose(f);
	return 0;
}