/*
 * vdos_loader.d: Executable file loader. Should somewhat be like EXEC.
 */

module vdos_loader;

import core.stdc.stdio;
import core.stdc.stdlib : malloc, free;
import vdos_codes, Logger;
import vcpu, vcpu_utils;
import vdos, vdos_structs;
import ddc : NULL_CHAR;

/// MZ file magic
private enum MZ_MAGIC = 0x5A4D;

private enum {
	PARAGRAPH = 16, /// Size of a paragraph (16B)
	PAGE = 512, /// Size of a page (512B)
	SEG_SIZE = 64 * 1024, /// max linear address size (64K)
}

/**
 * Load an executable file in memory.
 * AL is destroyed with error value
 * Params:
 *   path = Path to executable
 * Returns: 0 if successfully loaded
 * Notes: Refer to EXEC2BIN.ASM from MS-DOS 2.0 for details, at EXELOAD.
 */
extern (C)
int vdos_load(char *path) {
	FILE *f = fopen(path, "rb"); /// file handle
	fseek(f, 0, SEEK_END);
	// leave the cast in case of 64-bit compiles
	uint fsize = cast(uint)ftell(f); // who the hell would have a >2G exec to run in DOS

	debug printf("[....] File size: %d\n", fsize);

	if (fsize == 0) {
		fclose(f);
		warn("Executable file is zero length");
		vCPU.AL = EDOS_BAD_FORMAT; //TODO: Verify return value if 0 size is checked
		return EDOS_BAD_FORMAT;
	}

	ushort sig = void; /// Header signature
	fseek(f, 0, SEEK_SET);
	fread(&sig, 2, 1, f);

	switch (sig) {
	case MZ_MAGIC: // Party time!
		info("LOAD MZ");

		// ** Header is read for initial register values
		mz_hdr mzh = void; /// MZ header structure variable
		fread(&mzh, mzh.sizeof, 1, f);
		vCPU.CS = 0; vCPU.IP = 0x100; // Temporary!
		vCPU.CS = cast(ushort)(vCPU.CS + mzh.e_cs); // Relative
		vCPU.IP = mzh.e_ip;
		//vCPU.EIP = get_ip;

		// ** Copy code section from exe into memory
		/*if (mzh.e_minalloc && mzh.e_maxalloc) { // Low memory
			info("LOAD LOW MEM");
		} else { // High memory
			info("LOAD HIGH MEM");
		}*/

		// Shouldn't it be there _multiple_ code segments in some cases?
		const uint hsize = mzh.e_cparh * PARAGRAPH; /// Header size
		const uint codebase = hsize;// + (mz_rlc.sizeof * mzh.e_crlc); /// code section start
		uint csize = (mzh.e_cp & 0x7FF) * PAGE; /// image code size and limit address to 1M

		if (mzh.e_cblp) // Adjust code size for last bytes in page (DJGPP)
			csize -= PAGE - mzh.e_cblp;

		debug {
			printf("RELOC TABLE: %d -- %d B\n", mzh.e_lfarlc,  mz_rlc.sizeof * mzh.e_crlc);
			printf("STURCT STRUCT SIZE: %d\n", mzh.sizeof);
			printf("EXE HEADER SIZE: %d\n", hsize);
			printf("CODE: %d -- %d B\n", codebase, csize);
			printf("vCPU.CS: %4Xh -- e_cs: %4Xh\n", vCPU.CS, mzh.e_cs);
			printf("vCPU.IP: %4Xh -- e_ip: %4Xh\n", vCPU.IP, mzh.e_ip);
			printf("vCPU.SS: %4Xh -- e_ss: %4Xh\n", vCPU.SS, mzh.e_ss);
			printf("vCPU.SP: %4Xh -- e_sp: %4Xh\n", vCPU.SP, mzh.e_sp);
		}

		fseek(f, codebase, SEEK_SET); // Seek to start of first code segment
		fread(MEMORY + get_ip, csize, 1, f); // read code segment into MEMORY at CS:IP

		// ** Read relocation table and adjust far pointers in memory
		if (mzh.e_crlc) {
			/*
			 * 1. Read entry from table
			 * 2. Calculate address effective address
			 * 3. Fetch word from calculated address
			 * 4. Add the image's CS field to the word
			 * 5. Write the word (sum) back to address
			 */
			if (Verbose)
				printf("[INFO] Relocation(s): %d\n", mzh.e_crlc);
			fseek(f, mzh.e_lfarlc, SEEK_SET); // 1.
			const int rs = mzh.e_crlc * mz_rlc.sizeof; /// Relocation table size
			mz_rlc* r = cast(mz_rlc*)malloc(rs); /// Relocation table pointer
			fread(r, rs, 1, f); // Read whole relocation table

			int i;
			debug puts(" #    seg: off -> loadseg");
			do {
				const int addr = get_ad(r.segment, r.offset); // 2.
				const ushort loadseg = __fu16(addr); /// 3. Load segment
				debug printf("%2d   %04X:%04X -> cs:%04X+vCPU.CS:%04X = %04X\n",
					i, r.segment, r.offset, mzh.e_cs, vCPU.CS, loadseg
				);
				__iu16(mzh.e_cs + loadseg, addr); // 4. & 5.
				++r; ++i;
			} while (--mzh.e_crlc);
			free(r);
		} else {
			if (Verbose)
				info("No relocations");
		}

		// ** Setup registers
		// AL      drive letter
		// AH      status
		// DS:ES   Points to PSP
		// SS:SP   Stack pointer (from EXE header)

		vCPU.AL = 2; // C: for now
		vCPU.AH = 0;
		vCPU.DS = vCPU.CS; vCPU.ES = vCPU.IP;
		vCPU.SS = cast(ushort)(vCPU.SS + mzh.e_ss); // Relative
		vCPU.SP = mzh.e_sp;

		// ** Make PSP
		//MakePSP(vCPU.EIP - 0x100, ...);

		// ** Jump to CS:IP+0100h, relative to start of program
		//vCPU.EIP += 0x100; // Unecessary since we loaded code segment directly at CS:IP
		break; // case MZ
	default:
		if (fsize > 0xFF00) { // Size - PSP
			fclose(f);
			error("COM file too large (exceeds FF00h)");
			vCPU.AL = EDOS_BAD_FORMAT; //TODO: Verify code
			return EDOS_BAD_FORMAT;
		}
		info("LOAD COM");

		fseek(f, 0, SEEK_SET);
		fread(MEMORY + get_ip, fsize, 1, f);

		MakePSP;
		vCPU.AL = 0;
		break; // default (COM)
	}

	fclose(f);
	return 0;
}

/**
 * Create a PSP in MEMORY at CS:IP-100h with an optional filename
 *
 * Params: path = Path placed in PSP for command-line
 * Returns: 0 on success
 */
extern (C) private
int MakePSP(immutable(char) *path = NULL_CHAR) { //TODO: Consider default "NULL"
	PSP* psp = cast(PSP*)(MEMORY + get_ip - 0x100);

	psp.minorversion = MinorVersion;
	psp.majorversion = MajorVersion;

	return 0;
}