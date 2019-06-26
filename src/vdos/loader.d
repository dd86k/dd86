/**
 * Executable file loader. Should somewhat be like EXEC.
 */
module vdos.loader;

import core.stdc.stdio :
	FILE, fopen, fseek, ftell, fclose, fread, SEEK_END, SEEK_SET;
import core.stdc.stdlib : malloc, free;
import vcpu.core, vcpu.utils;
import vcpu.mm : mmfu16, mmiu16;
import vdos.os : MinorVersion, MajorVersion;
import vdos.structs : mz_hdr_t, mz_reloc_t, dos_psp_t;
import vdos.ecodes;
import logger;
import ddc : NULL_CHAR;
import vdos.video : v_printf, v_putln;

extern (C):

/// MZ file magic
private enum MZ_MAGIC = 0x5A4D;
private enum ZM_MAGIC = 0x4D5A;

private enum {
	PARAGRAPH = 16, /// Size of a paragraph (16B)
	PAGE = 512, /// Size of a page (512B)
	SEG_SIZE = 64 * 1024, /// max linear address size (64K)
}

/**
 * Load an executable file in memory. This function manages its own file
 * handling for the executable. AL is destroyed.
 * Params: path = Path to executable
 * Returns: 0 if successfully loaded
 * Notes: Refer to EXEC2BIN.ASM from MS-DOS 2.0 for details, at EXELOAD.
 */
int vdos_load(const(char) *path) {
	FILE *f = fopen(path, "rb"); /// file handle

	fseek(f, 0, SEEK_END); // for ftell
	int fsize = cast(int)ftell(f); // >2G binary in MSDOS is impossible anyway
	fseek(f, 0, SEEK_SET);

	CPU.CS = 0x200; // TEMPORARY LOADING SEGMENT
	CPU.DS = 0x200;
	CPU.ES = 0x200;
	CPU.SS = 0x200;

	mz_hdr_t mzh = void; /// MZ header structure variable

	if (fsize == 0) {
		fclose(f);
		log_error("Executable file is zero length");
		CPU.AL = EDOS_BAD_FORMAT; //TODO: Verify return value if 0 size is checked
		return EDOS_BAD_FORMAT;
	}
	if (fsize <= mz_hdr_t.sizeof) goto FILE_COM;

	fread(&mzh, 2, 1, f); // e_magic is at 0 anyway

	switch (mzh.e_magic) {
	case MZ_MAGIC, ZM_MAGIC: // Party time!
		log_info("LOAD MZ");

		// ** Header is read for initial register values
		fread(&mzh, mzh.sizeof - 2, 1, f); // read rest minus signature
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
		const uint cbase = hsize + (mz_reloc_t.sizeof * mzh.e_crlc); /// code section start
		uint csize = (mzh.e_cp & 0x7FF) * PAGE; /// image code size and limit address to 1M

		if (mzh.e_cblp) // Adjust code size for last bytes in page (DJGPP)
			csize -= PAGE - mzh.e_cblp;

		debug {
			v_printf("RELOC TABLE: %u -- %u B\n", mzh.e_lfarlc, mz_reloc_t.sizeof * mzh.e_crlc);
			v_printf("STURCT STRUCT SIZE: %u\n", mzh.sizeof);
			v_printf("EXE HEADER SIZE: %u\n", hsize);
			v_printf("CODE: %u -- %u B\n", cbase, csize);
			v_printf("CPU.CS: %4Xh -- e_cs: %4Xh\n", CPU.CS, mzh.e_cs);
			v_printf("CPU.IP: %4Xh -- e_ip: %4Xh\n", CPU.IP, mzh.e_ip);
			v_printf("CPU.SS: %4Xh -- e_ss: %4Xh\n", CPU.SS, mzh.e_ss);
			v_printf("CPU.SP: %4Xh -- e_sp: %4Xh\n", CPU.SP, mzh.e_sp);
		}

		fseek(f, cbase, SEEK_SET); // Seek to start of first code segment
		fread(MEMORY + get_ip, csize, 1, f); // read code segment to MEMORY[CS:IP/EIP]

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
				v_printf("[INFO] Relocation(s): %u\n", mzh.e_crlc);

			const int rs = mzh.e_crlc * mz_reloc_t.sizeof; // table size
			mz_reloc_t *rp = cast(mz_reloc_t*)(MEMORY + 0x1300); // table pointer

			fseek(f, mzh.e_lfarlc, SEEK_SET); // 1.
			fread(rp, rs, 1, f); // Read whole relocation table

			debug v_putln(" #    seg: off -> loadseg");
			int i;
			do {
				const int addr = address(rp.segment, rp.offset); // 2.
				const ushort loadseg = mmfu16(addr); /// 3. Load segment
				debug v_printf("%2d   %04X:%04X -> cs:%04X+CPU.CS:%04X = %04X\n",
					i, rp.segment, rp.offset, mzh.e_cs, CPU.CS, loadseg
				);
				mmiu16(mzh.e_cs + loadseg, addr); // 4. & 5.
				++rp; ++i;
			} while (--mzh.e_crlc >= 0);
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
		fread(MEMORY + get_ip, fsize - 2, 1, f);

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
int MakePSP(const(char) *path = NULL_CHAR) { //TODO: Consider passing a structure
	dos_psp_t *psp = cast(dos_psp_t*)(MEMORY + get_ip - 0x100);

	psp.minorversion = MinorVersion;
	psp.majorversion = MajorVersion;

	return 0;
}