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
	ushort e_cblp;         /// Bytes on last page of file (extra bytes)
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
 * Params:
 *   path = Path to executable
 *   args = Executable arguments
 * Returns: State is successfully loaded
 */
bool ExecLoad(string path, string args = null) {
	FILE* f = fopen(cast(char*)(path~'\0'), "rb"); // A little sad, I know
	fseek(f, 0, SEEK_END);
	size_t fsize = ftell(f); // who the hell would have a >2G exec to run in DOS

	if (Verbose)
		logd("File size: ", fsize);

	ushort sig;
	fseek(f, 0, SEEK_SET);
	fread(&sig, 2, 1, f);

	if (fsize == 0) {
		if (Verbose)
			log("File is zero length.");
		AL = 2; // Non-official
		return false;
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
		//CS = CS + mzh.e_cs; // Relative
		//IP = mzh.e_ip;
		//SS = SS + mzh.e_ss; // Relative
		//SP = mzh.e_sp;

		// ** Copy code section from exe into memory
		if (mzh.e_minalloc && mzh.e_maxalloc) { // High memory
			if (Verbose)
				log("LOAD HIGH MEM");
		} else { // Low memory
			if (Verbose)
				log("LOAD LOW MEM");
		}
		const uint _h = mzh.e_cparh * PARAGRAPH; // Header size
		const uint _l = _h + (mz_rlc.sizeof * mzh.e_crlc); // image code offset
		uint _s = (mzh.e_cp * PAGE) - _h; // image code size
		if (mzh.e_cblp) // Adjust _s for last bytes in page
			_s -= PAGE - mzh.e_cblp;
		if (_h + _s < PAGE) // This snippet was found in DOSBox
			_s = PAGE - _h;
		debug {
			logd("STRUCT_SIZE: ", mzh.sizeof);
			logd("HEADER_SIZE: ", _h);
			logd("IMAGE_SIZE : ", _s);
			logd("CS: ", CS);
			logd("IP: ", IP);
			logd("SS: ", SS);
			logd("SP: ", SP);
		}
		fseek(f, _l, SEEK_SET);
		ubyte* t = cast(ubyte*)malloc(_s);
		fread(t, _s, 1, f);
		Insert(t, _s); // Insert at CS:IP
		free(t);

		// ** Read relocation table and adjust far pointers in memory
		if (mzh.e_crlc) {
			if (Verbose)
				logd("Relocation: ", mzh.e_crlc);
			fseek(f, mzh.e_lfarlc, SEEK_SET);
			const int rs = mzh.e_crlc * mz_rlc.sizeof; // Relocation table size
			mz_rlc* r = cast(mz_rlc*)malloc(rs); // Relocation table
			fread(cast(void*)r, rs, 1, f); // Read it full
			if (Verbose)
				puts(" #   seg: off -> data");
			const uint ip = GetIPAddress;
			for (int i; i < mzh.e_crlc; ++i) {
				const ushort data = FetchWord(ip + (r[i].seg << 4) + r[i].off);
				if (Verbose)
					printf("%2d  %04X:%04X -> %04X\n", i, r[i].seg, r[i].off, data);
				//SetWord((r[i].seg << 4) + r[i].off, r[i].refseg);
			}
			free(r);
		} else if (Verbose)
			log("No relocations");

		// ** Setup registers
		// AL      drive letter
		// AH      status
		// DS:ES   Points to PSP
		// SS:SP   Stack pointer (from EXE header)

		AL = 3;
		AH = 0;

		// Jump to CS:IP+0x0100, relative to start of program

		// Make PSP
		//MakePSP(GetIPAddress, "test");
		return true; // case MZ
	default:
		if (fsize > 0xFF00) { // Size - PSP
			if (Verbose)
				log("COM file too large", Log.Error);
			AL = exec_bad_format;
			return false;
		}
		if (Verbose)
			log("LOAD COM");
		CS = 0; EIP = 0x100; // Temporary
		fseek(f, 0, SEEK_SET);
		ubyte* _comp = cast(ubyte*)MEMORY + GetIPAddress;
		fread(_comp, fsize, 1, f);

		//MakePSP(_comp - 0x100, "TEST");
		AL = 0;
		return true; // case COM
	}
}