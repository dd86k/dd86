/**
 * loader: Executable file loader. Should somewhat be like EXEC.
 */
module vdos.loader;

import core.stdc.stdio :
	FILE, fopen, fseek, ftell, fclose, fread, SEEK_END, SEEK_SET;
import core.stdc.stdlib : malloc, free;
import vcpu.core;
import vcpu.mm : mmfu16, mmiu16;
import vdos.os : MinorVersion, MajorVersion;
import vdos.structs : mz_hdr, MZ_HDR_SIZE, mz_rlc, PSP;
import vdos.codes;
import logger;
import ddc : NULL_CHAR;
import vdos.video : v_printf, v_putn;

/// MZ file magic
private enum MZ_MAGIC = 0x5A4D;
private enum ZM_MAGIC = 0x4D5A;

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

	fseek(f, 0, SEEK_END); // for ftell
	int fsize = cast(int)ftell(f); // >2G binary in MSDOS is not possible anyway
	fseek(f, 0, SEEK_SET);

	mz_hdr mzh = void; /// MZ header structure variable

	CPU.CS = 0x2000; // TEMPORARY LOADING SEGMENT
	CPU.DS = 0x2000;
	CPU.ES = 0x2000;
	CPU.SS = 0x2000;

	if (fsize == 0) {
		fclose(f);
		log_error("Executable file is zero length");
		CPU.AL = EDOS_BAD_FORMAT; //TODO: Verify return value if 0 size is checked
		return EDOS_BAD_FORMAT;
	}
	if (fsize <= MZ_HDR_SIZE) goto FILE_COM;

	fread(&mzh.e_magic, 2, 1, f);

	switch (mzh.e_magic) {
	case MZ_MAGIC, ZM_MAGIC: // Party time!
		log_info("LOAD MZ");

		// ** Header is read for initial register values
		fread(&mzh, mzh.sizeof, 1, f); // read rest
		CPU.IP = mzh.e_ip;
		//CPU.EIP = get_ip;

		// ** Copy code section from exe into memory
		/*if (mzh.e_minalloc && mzh.e_maxalloc) { // Low memory
			log_info("LOAD LOW MEM");
		} else { // High memory
			log_info("LOAD HIGH MEM");
		}*/

		// Shouldn't it be there _multiple_ code segments in some cases?
		const uint hsize = mzh.e_cparh * PARAGRAPH; /// Header size
		const uint codebase = hsize;// + (mz_rlc.sizeof * mzh.e_crlc); /// code section start
		uint csize = (mzh.e_cp & 0x7FF) * PAGE; /// image code size and limit address to 1M

		if (mzh.e_cblp) // Adjust code size for last bytes in page (DJGPP)
			csize -= PAGE - mzh.e_cblp;

		debug {
			v_printf("RELOC TABLE: %d -- %d B\n", mzh.e_lfarlc,  mz_rlc.sizeof * mzh.e_crlc);
			v_printf("STURCT STRUCT SIZE: %d\n", mzh.sizeof);
			v_printf("EXE HEADER SIZE: %d\n", hsize);
			v_printf("CODE: %d -- %d B\n", codebase, csize);
			v_printf("CPU.CS: %4Xh -- e_cs: %4Xh\n", CPU.CS, mzh.e_cs);
			v_printf("CPU.IP: %4Xh -- e_ip: %4Xh\n", CPU.IP, mzh.e_ip);
			v_printf("CPU.SS: %4Xh -- e_ss: %4Xh\n", CPU.SS, mzh.e_ss);
			v_printf("CPU.SP: %4Xh -- e_sp: %4Xh\n", CPU.SP, mzh.e_sp);
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
			if (LOGLEVEL)
				v_printf("[INFO] Relocation(s): %d\n", mzh.e_crlc);
			fseek(f, mzh.e_lfarlc, SEEK_SET); // 1.
			const int rs = mzh.e_crlc * mz_rlc.sizeof; /// Relocation table size
			//TODO: Use MEMORY instead of a malloc
			mz_rlc* r = cast(mz_rlc*)malloc(rs); /// Relocation table pointer
			fread(r, rs, 1, f); // Read whole relocation table

			// temporary value
			ushort rel = 0x2000; // usually the loading segment
			int i;
			debug v_putn(" #    seg: off -> loadseg");
			do {
				const int addr = get_ad(r.segment, r.offset); // 2.
				const ushort loadseg = mmfu16(addr); /// 3. Load segment
				debug v_printf("%2d   %04X:%04X -> cs:%04X+CPU.CS:%04X = %04X\n",
					i, r.segment, r.offset, mzh.e_cs, CPU.CS, loadseg
				);
				mmiu16(mzh.e_cs + loadseg, addr); // 4. & 5.
				++r; ++i;
			} while (--mzh.e_crlc);
			free(r);
		} else {
			//if (LOGLEVEL)
			//	log_info("No relocations");
		}

		// ** Setup registers
		// AL      drive letter
		// AH      status
		// DS:ES   Points to PSP
		// SS:SP   Stack pointer (from EXE header)

		CPU.AL = 2; // C: for now
		CPU.AH = 0;
		CPU.DS = CPU.CS; CPU.ES = CPU.IP;
		CPU.SS = cast(ushort)(CPU.SS + mzh.e_ss); // Relative
		CPU.SP = mzh.e_sp;

		// ** Make PSP
		//MakePSP(CPU.EIP - 0x100, ...);

		// ** Jump to CS:IP+0100h, relative to start of program
		//CPU.EIP += 0x100; // Unecessary since we loaded code segment directly at CS:IP
		break; // case MZ
	default:
		if (fsize > 0xFF00) { // Size - PSP
			fclose(f);
			log_error("COM file too large (exceeds FF00h)");
			CPU.AL = EDOS_BAD_FORMAT; //TODO: Verify code
			return EDOS_BAD_FORMAT;
		}
FILE_COM:
		log_info("LOAD COM");

		CPU.IP = 0x100;

		fseek(f, 0, SEEK_SET);
		fread(MEMORY + get_ip, fsize, 1, f);

		MakePSP;
		CPU.AL = 0;
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