/*
 * vdos_structs : Structures defined within DOS
 */

module vdos_structs;

// Tests

static assert(PSP.sizeof == 0x100);

// Enumerations

private enum ERESWDS = 16; /// RESERVED WORDS (MZ EXE)

/// File/Folder attribute. See INT 21h AH=3Ch
// Trivia: Did you know Windows still use these values today?
enum
	READONLY = 1,
	HIDDEN = 2,
	SYSTEM = 4,
	VOLLABEL = 8,
	DIRECTORY = 16,
	ARCHIVE = 32,
	SHAREABLE = 128;

/*
 * DOS Structures
 */

struct PSP { align(1):
	ushort cpm_exit;	/// CP/M Exit (INT 20h) pointer
	ushort first_seg;	/// First segment location pointer
	ubyte reserved1;
	ubyte[5] cpm_comp;	/// Far call to CP/M combability mode within DOS (instructions)
	uint prev_term;	/// Previous programs terminate address (INT 22h)
	uint prev_break;	/// Previous programs break address (INT 23h)
	uint prev_crit;	/// Previous programs critical address (INT 24h)
	ushort parent_psp;	/// Parent’s PSP segment (usually COMMAND.COM internal)
	ubyte[20] jft;	/// Job File Table (used for file redirection, internal)
	ushort env_seg;	/// Environment segment
	uint int21h;	/// Entry to call INT 21h (SS:SP) (internal)
	ushort jft_size;	/// JFT size (internal)
	uint jft_pointer;	/// Pointer to the JFT (internal)
	uint prev_psp;	/// Pointer to the previous PSP (SHARE in DOS 3.3 and later)
	uint reserved2;
	ushort version_;	/// DOS version
	//TODO: figure out union for version
	ubyte[14] reserved3;
	ubyte[3] dos_far;	/// DOS far call (instructions)
	ushort reserved4;
	ubyte[7] reserved5;	// Could be used to extend FCB1
	ubyte[16] fcb1;	/// Unopened Standard FCB 1 (see File Control Block)
	ubyte[20] fcb2;	/// Unopened Standard FCB 2 (overwritten if FCB 1 is opened)
	ubyte cmd_length;	/// Number of bytes on the command-line
	ubyte[127] cmd;	/// Command-line, terminates with CR character (Dh)
}

/// MS-DOS EXE header structure
struct mz_hdr { align(1):
//	ushort e_magic;	/// Magic number, "MZ"
	ushort e_cblp;	/// Bytes on last page of file (extra bytes), 9 bits
	ushort e_cp;	/// Pages in file
	ushort e_crlc;	/// Number of relocation entries
	ushort e_cparh;	/// Size of header in paragraphs (usually 32 (512B))
	ushort e_minalloc;	/// Minimum extra paragraphs needed
	ushort e_maxalloc;	/// Maximum extra paragraphs needed
	ushort e_ss;	/// Initial (relative) SS value
	ushort e_sp;	/// Initial SP value
	ushort e_csum;	/// Checksum, ignored
	ushort e_ip;	/// Initial IP value
	ushort e_cs;	/// Initial (relative) CS value
	ushort e_lfarlc;	/// File address (byte offset) of relocation table
	ushort e_ovno;	/// Overlay number
//	ushort[ERESWDS] e_res;	/// Reserved words
//	uint   e_lfanew;	/// File address of new exe header
}

/// MS_DOS EXE Relocation structure
struct mz_rlc { align(1): // For AL=03h
	ushort offset; /// Offset
	ushort segment; /// Segment of relocation
}

/*
 * Internal Structures
 */

struct vdos_settings { align(1):
	// DOS related
	char[15] HOSTNAME;
	// vDOS
	// x86 interpreter settings
}