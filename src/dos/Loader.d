/*
 * Loader.d: Executable file loader. Should somewhat be like EXEC.
 */

module Loader;

import core.stdc.stdio;
import core.stdc.stdlib : malloc, free;
import vdos, Interpreter, InterpreterUtils, Logger;
import Codes;

private enum ERESWDS = 16; /// RESERVED WORDS

/// MS-DOS EXE header (Introduced in MS-DOS 2.0)
private struct mz_hdr { align(1): // Necessary fields included
//	ushort e_magic;        /// Magic number, "MZ"
	ushort e_cblp;         /// Bytes on last page of file (extra bytes), 9 bits
	ushort e_cp;           /// Pages in file
	ushort e_crlc;         /// Number of relocation entries
	ushort e_cparh;        /// Size of header in paragraphs (usually 32 (512B))
	ushort e_minalloc;     /// Minimum extra paragraphs needed
	ushort e_maxalloc;     /// Maximum extra paragraphs needed
	ushort e_ss;           /// Initial (relative) SS value
	ushort e_sp;           /// Initial SP value
	ushort e_csum;         /// Checksum, ignored
	ushort e_ip;           /// Initial IP value
	ushort e_cs;           /// Initial (relative) CS value
	ushort e_lfarlc;       /// File address (byte offset) of relocation table
	ushort e_ovno;         /// Overlay number
	ushort[ERESWDS] e_res; /// Reserved words
	uint   e_lfanew;       /// File address of new exe header
}

private struct mz_rlc { align(1): // For AL=03h
	ushort off; /// Offset
	ushort seg; /// Segment of relocation
}

/// MZ file magic
private enum MZ_MAGIC = 0x5A4D;

private enum {
	PARAGRAPH = 16, /// Size of a paragraph (16B)
	PAGE = 512, /// Size of a page (512B)
	SEG_SIZE = 64 * 1024, /// i8086 maximum code size
}

/**
 * Load an executable file in memory.
 * AL values are set according to error (destroyed)
 * Params:
 *   path = Path to executable
 *   args = Executable arguments
 * Returns: 0 if successfully loaded
 * Notes: Refer to EXEC2BIN.ASM from MS-DOS 2.0 for details, at EXELOAD.
 */
int ExecLoad(char* path) {
	FILE* f = fopen(path, "rb");
	fseek(f, 0, SEEK_END);
	int fsize = cast(int)ftell(f); // who the hell would have a >2G exec to run in DOS

	debug printf("[dbug] File size: %d\n", fsize);

	__gshared ushort sig;
	fseek(f, 0, SEEK_SET);
	fread(&sig, 2, 1, f);

	if (fsize == 0) {
		fclose(f);
		if (Verbose)
			log("File is zero length");
		AL = 2; // Non-official
		return 1;
	}

	int cip = get_ip; // calculated CS:IP

	switch (sig) {
	case MZ_MAGIC: // Party time!
		if (Verbose)
			log("LOAD MZ");

		// ** Header is read for initial register values
		mz_hdr mzh;
		fread(&mzh, mzh.sizeof, 1, f);
		CS = 0; IP = 0; // Temporary
		//CS = CS + mzh.e_cs; // Relative
		//IP = mzh.e_ip;

		// ** Copy code section from exe into memory
		if (mzh.e_minalloc && mzh.e_maxalloc) { // Low memory
			if (Verbose)
				log("LOAD LOW MEM");
		} else { // High memory
			if (Verbose)
				log("LOAD HIGH MEM");
		}
		const uint _h = mzh.e_cparh * PARAGRAPH; /// Header size
		const uint _l = _h + (mz_rlc.sizeof * mzh.e_crlc); // image code offset
		uint csize = (mzh.e_cp * PAGE) - _h; // image code size
		if (mzh.e_cblp) // Adjust csize for last bytes in page
			csize -= PAGE - mzh.e_cblp;
		if (csize >= SEG_SIZE) {
			if (Verbose)
				error("Executable code size too big (>64K)");
			return -1; // TOOBIG
		}
		//TODO: Binary fix on IP=0

		debug {
			printf("[dbug] _H::%d\n", _h);
			printf("[dbug] _L::%d\n", _l);
			printf("[dbug] STRUCT_SIZE: %d\n", mzh.sizeof);
			printf("[dbug] HEADER_SIZE: %d\n", _h);
			printf("[dbug] IMAGE_SIZE : %d\n", csize);
			printf("[dbug] CS: %d\n", CS);
			printf("[dbug] IP: %d\n", IP);
			printf("[dbug] SS: %d\n", SS);
			printf("[dbug] SP: %d\n", SP);
		}
		fseek(f, _h, SEEK_SET); // Seek to end of header
		fread(cast(ubyte*)MEMORY + cip, csize, 1, f); // read code into MEMORY

		// ** Read relocation table and adjust far pointers in memory
		/+if (mzh.e_crlc) {
		//TODO: Adjust pointers in memory
			if (Verbose)
				printf("[INFO] Relocation: %d\n", mzh.e_crlc);
			fseek(f, mzh.e_lfarlc, SEEK_SET);
			const int rs = mzh.e_crlc * mz_rlc.sizeof; /// Relocation table size
			mz_rlc* r = cast(mz_rlc*)malloc(rs); /// Relocation table
			fread(r, rs, 1, f); // Read whole table
			if (Verbose)
				puts(" #   seg: off -> data");
			for (int i; i < mzh.e_crlc; ++i) {
				const ushort data = __fu16(cip + (r[i].seg << 4) + r[i].off);
				if (Verbose)
					printf("%2d  %04X:%04X -> %04X\n", i, r[i].seg, r[i].off, data);
				CS += cast(ushort)(CS + r[i].seg); // temporarily cheat
				IP = cast(ushort)(IP + r[i].off); // ditto
				//SetWord((r[i].seg << 4) + r[i].off, r[i].refseg);
			}
			free(r);
		} else {
			EIP += 0x100; // temporary
			if (Verbose)
				log("No relocations");
		}+/

		// ** Setup registers
		// AL      drive letter
		// AH      status
		// DS:ES   Points to PSP
		// SS:SP   Stack pointer (from EXE header)

		AL = 3;
		AH = 0;
		SS = cast(ushort)(SS + mzh.e_ss); // Relative
		SP = mzh.e_sp;

		// ** Make PSP
		//MakePSP(get_ip, "test");

		// ** Jump to CS:IP+0x0100, relative to start of program
		EIP += 0x100;
		break; // case MZ
	default:
		if (fsize > 0xFF00) { // Size - PSP
			fclose(f);
			if (Verbose)
				error("COM file too large");
			AL = E_BAD_FORMAT;
			return 1;
		}
		if (Verbose)
			log("LOAD COM");

		fseek(f, 0, SEEK_SET);
		ubyte* c = cast(ubyte*)MEMORY + cip;
		fread(c, fsize, 1, f);

		//MakePSP(_comp - 0x100, "TEST");
		AL = 0;
		break; // default (COM)
	}

	fclose(f);
	return 0;
}