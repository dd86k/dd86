/*
 * Loader.d: Executable file loader. Should somewhat be like EXEC.
 */

module Loader;

import core.stdc.stdio;
import core.stdc.stdlib : malloc, free;
import vdos, Interpreter, InterpreterUtils, Logger;
import Codes;

private enum ERESWDS = 16; /// RESERVED WORDS

/// MS-DOS EXE header structure
private struct mz_hdr { align(1):
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

/// MS_DOS EXE Relocation structure
private struct mz_rlc { align(1): // For AL=03h
	ushort off; /// Offset
	ushort seg; /// Segment of relocation
}

/// MZ file magic
private enum MZ_MAGIC = 0x5A4D;

private enum {
	PARAGRAPH = 16, /// Size of a paragraph (16B)
	PAGE = 512, /// Size of a page (512B)
	SEG_SIZE = 64 * 1024, /// i8086 maximum code size (64K)
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

	if (fsize == 0) {
		fclose(f);
		if (Verbose)
			log("File is zero length");
		AL = E_BAD_FORMAT; //TODO: Verify return value if 0 size is checked
		return E_BAD_FORMAT;
	}

	__gshared ushort sig; /// signature
	fseek(f, 0, SEEK_SET);
	fread(&sig, 2, 1, f);

	int cip = get_ip;
	ubyte* memloc = cast(ubyte*)MEMORY + cip;

	switch (sig) {
	case MZ_MAGIC: // Party time!
		if (Verbose) log("LOADING MZ");

		// ** Header is read for initial register values
		__gshared mz_hdr mzh;
		fread(&mzh, mzh.sizeof, 1, f);
		//CS = 0; IP = 0; // Temporary
		//CS = CS + mzh.e_cs; // Relative
		//IP = mzh.e_ip;

		// ** Copy code section from exe into memory
		//TODO: LOW/HIGH MEMORY
		if (mzh.e_minalloc && mzh.e_maxalloc) { // Low memory
			if (Verbose)
				log("LOAD LOW MEM");
		} else { // High memory
			if (Verbose)
				log("LOAD HIGH MEM");
		}

		// Shouldn't it be there _multiple_ code segments in some cases?
		const uint hsize = mzh.e_cparh * PARAGRAPH; /// Header size
		const uint cstart = hsize + (mz_rlc.sizeof * mzh.e_crlc); /// code section start
		uint csize = mzh.e_cp * PAGE; /// image code size

		if (mzh.e_cblp) // Adjust csize for last bytes in page (DJGPP)
			csize -= PAGE - mzh.e_cblp;

		if (csize >= SEG_SIZE) { // Section too large?
			if (Verbose)
				error("Executable code size too big (>64K)");
			return -1; //TODO: check error code (for AL)
		}

		debug {
			printf("[dbug] STRUCT SIZE: %d\n", mzh.sizeof);
			printf("[dbug] HEADER SIZE: %d\n", hsize);
			printf("[dbug] CODE SIZE : %d\n", csize);
			printf("[dbug] CS: %d\n", CS);
			printf("[dbug] IP: %d\n", IP);
			printf("[dbug] SS: %d\n", SS);
			printf("[dbug] SP: %d\n", SP);
		}
		fseek(f, cstart, SEEK_SET); // Seek to start of first code segment
		fread(memloc, csize, 1, f); // read code segment into MEMORY

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
				const ushort data = __fu16(get_ea + (r[i].seg << 4) + r[i].off);
				if (Verbose)
					printf("%2d  %04X:%04X -> %04X\n", i, r[i].seg, r[i].off, data);
				CS += cast(ushort)(CS + r[i].seg); // temporarily cheat
				IP = cast(ushort)(IP + r[i].off); // ditto
				//SetWord((r[i].seg << 4) + r[i].off, r[i].refseg);
			}
			free(r);
		} else {
			if (Verbose)
				log("No relocations");
		}+/

		// ** Setup registers
		// AL      drive letter
		// AH      status
		// DS:ES   Points to PSP
		// SS:SP   Stack pointer (from EXE header)

		AL = 2;
		AH = 0;
		SS = cast(ushort)(SS + mzh.e_ss); // Relative
		SP = SP + mzh.e_sp;
		SS = mzh.e_ss;

		// ** Make PSP
		//MakePSP(get_ip, "test");

		// ** Jump to CS:IP+0x0100, relative to start of program
		EIP += 0x100; // cheapest CALL for the moment
		break; // case MZ
	default:
		if (fsize > 0xFF00) { // Size - PSP
			fclose(f);
			if (Verbose) error("COM file too large");
			AL = E_BAD_FORMAT; //TODO: Verify code
			return E_BAD_FORMAT;
		}
		if (Verbose) log("LOADING COM");

		fseek(f, 0, SEEK_SET);
		fread(memloc, fsize, 1, f);

		//MakePSP(_comp - 0x100, "TEST");
		AL = 0;
		break; // default (COM)
	}

	fclose(f);
	return 0;
}