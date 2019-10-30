/**
 * structs: Structures defined within DOS
 */
module vdos.structs;

// Enumerations

private enum ERESWDS = 16; /// RESERVED WORDS (MZ EXE)

/// File/Folder attribute. See INT 21h AH=3Ch
// Trivia: Did you know Windows still use these values today?
enum
	FS_ATTR_READONLY = 1,
	FS_ATTR_HIDDEN = 2,
	FS_ATTR_SYSTEM = 4,
	FS_ATTR_VOLLABEL = 8,
	FS_ATTR_DIRECTORY = 16,
	FS_ATTR_ARCHIVE = 32,
	FS_ATTR_SHAREABLE = 128;

//
// DOS Structures
//

/// EXEC PSP structure
struct dos_psp_t { align(1):
	ushort cpm_exit;	/// CP/M Exit (INT 20h) pointer
	ushort first_seg;	/// First segment location pointer
	ubyte reserved1;	// likely to pad with cpm_comp
	ubyte [5]cpm_comp;	/// Far call to CP/M combability mode within DOS (instructions)
	uint prev_term;	/// Previous programs terminate address (INT 22h)
	uint prev_break;	/// Previous programs break address (INT 23h)
	uint prev_crit;	/// Previous programs critical address (INT 24h)
	ushort parent_psp;	/// Parent’s PSP segment (usually COMMAND.COM internal)
	ubyte [20]jft;	/// Job File Table (used for file redirection, internal)
	ushort env_seg;	/// Environment segment
	uint int21h;	/// Entry to call INT 21h (SS:SP) (internal)
	ushort jft_size;	/// JFT size (internal)
	uint jft_pointer;	/// Pointer to the JFT (internal)
	uint prev_psp;	/// Pointer to the previous PSP (used in SHARE in DOS 3.3 and later)
	uint reserved2;
	union {
		ushort dosversion;	/// DOS version
		struct {
			ubyte majorversion, minorversion;
		}
	}
	ubyte [14]reserved3;
	ubyte [3]dos_far;	/// DOS far call (instructions)
	ushort reserved4;
	ubyte [7]reserved5;	// Could be used to extend FCB1, usually struct padding
	ubyte [16]fcb1;	/// Unopened Standard FCB 1 (see File Control Block)
	ubyte [20]fcb2;	/// Unopened Standard FCB 2 (overwritten if FCB 1 is opened)
	ubyte cmd_length;	/// Number of bytes on the command-line
	ubyte [127]cmd;	/// Command-line, terminates with CR character (Dh)
}
static assert(dos_psp_t.sizeof == 256);

/// MS-DOS EXE header structure
struct mz_hdr_t { align(1):
	ushort e_magic;	/// Magic number, "MZ"
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
	ushort[ERESWDS] e_res;	/// Reserved words
	uint   e_lfanew;	/// File address of new exe header
}

/// MS_DOS EXE Relocation structure
struct mz_reloc_t { align(1): // For AL=03h
	ushort offset;	/// Offset
	ushort segment;	/// Segment of relocation
}

/// DOS device structure
struct dos_dev_t { align(1):
	ushort dev_clock;	/// CLOCK$ device driver, far call
	ushort dev_console;	/// CON device driver, far call
	ushort dev_printer;	/// LPT device driver, far call
	ushort dev_aux;	/// auxiliery device driver, far call
	ushort dev_block;	/// Disk device driver, far call
	char [15]HOSTNAME;	/// Network NetBIOS HOSTNAME
	ubyte errorlevel;	/// Last system error level
}

/// Cursor position structure
struct CURSOR { align(1):
	ubyte col;	/// Left 0-based horizontal cursor position
	ubyte row;	/// Upper 0-based vertical cursor position
}

/// IVT entry
struct __ivt { align(1):
	union {
		uint value;
		alias value this;
		struct {
			ushort offset, segment;
		}
	}
}
static assert(__ivt.sizeof == 4, "IVT.sizeof != 4");

/// BIOS data area
// 300h would usually contain bootstrap code on an actual IBM PC
// Includes:
// - 000h -- Interrupt Vector Table
// - 400h -- ROM Communication Area
// - 500h -- DOS Communication Area
struct SYSTEM_t { align(1):
	union {
		__ivt [256]IVT;
		struct {
			private ubyte [0x104]_padding0;
			ushort hdd_offset;	/// HDD address Parameter
			ushort hdd_segment;	/// HDD address Parameter
		}
	}
	// 400h
	ushort COM1, COM2, COM3, COM4, LPT1, LPT2, LPT3, LPT4;
	ushort equip_flag;	/// See INT 11h
	ubyte pcjr_ir_kb_er_count;	/// (PCjr) Infrared keyboard link error count
	ushort memsize;	/// Memory size (in KB)
	private ubyte _res0;
	ubyte ps2_bios_flag;	/// (PS/2) BIOS control flags
	ushort kb_flags;	// 417h
	ubyte keypad_storage;
	ushort kb_buf_head_offset;	/// from 400h
	ushort kb_buf_tail_offset;	/// from 400h
	ubyte [32]kb_buffer;
	ubyte drive_recal_status;	// 43Eh
	ubyte diskette_motor_status;	// 43Fh
	ubyte diskette_shutoff_counter;	// 440h
	ubyte diskette_last_op_status;	// 441h, see INT 13h AH=01h
	ubyte [7]nec765_status;
	ubyte video_mode;	/// Current video mode
	ushort screen_col;
	ushort video_rbuf_size;	/// Size of current video regenerate buffer in bytes
	ushort video_rbuf_off;	/// Offset of current video page in video regenerate buffer
	CURSOR [8]cursor;	/// Cursor positions per page
	ubyte video_scan_line_bottom;
	ubyte video_scan_line_top;
	ubyte screen_page;	/// current active page
	ushort crt_base_port;	/// 6845 base port, 3B4h=mono, 3D4h=color
	ubyte crt_mode;	/// 6845 CRT mode control register value (port 3x8h)
	ubyte video_cga_palette;	/// CGA current color palette mask setting (port 3D9h)
	ubyte [5]cassette_control;
	uint clock_counter;
	ubyte clock_rollover;
	ubyte bios_break;
	ushort reset;
	ubyte disk_last_op;
	ubyte disk_number;	// that are attached
	ubyte disk_control;
	ubyte disk_adapter_port_offset;
	ubyte [4]lpt_timeouts;
	ubyte [4]com_timeouts;
	// 480h
	ushort kb_buf_off_start;
	ushort kb_buf_off_end;
	ubyte screen_row;	// -1
	ushort video_char_matrix_off;
	ubyte video_options;
	ubyte video_features;
	ubyte video_data_area;
	ubyte video_dcc_index;
	ubyte diskette_data_rate;
	ubyte disk_status;
	ubyte disk_error;
	ubyte disk_int_control;
	ubyte disk_floppy_card;
	ubyte [4]drive_status;	// 0 through 3
	ubyte drive0_seek;
	ubyte drive1_seek;
	ubyte kb_mode;
	ubyte kb_led;
	uint user_wait_complete;	// flag
	uint user_wait_timeout;	// microseconds
	ubyte rtc_flag;
	ubyte lana_dma;
	ubyte lana0_status;
	ubyte lana1_status;
	uint disk_int;
	uint video_table_addr;	/// BIOS Video Save/Override Pointer Table address
	private ubyte [8]_res1;
	ubyte kb_nmi_control;
	uint kb_break;
	ubyte port60_queue;
	ubyte kb_last_scancode;
	ubyte nmi_buf_head;	// pointer
	ubyte nmi_buf_tail;	// pointer
	ubyte [16]nmi_scancode_buf;
	ushort clock_counter_conv;
	ubyte [16]app_comm_area;	/// Intra-Applications Communications Area
	ubyte [33]unknown;
	// 500h
	ubyte print_scr_status;
	ubyte [3]basic;
	ubyte diskette_dos_mode;
	ubyte [10]post;
	ubyte basic_shell;
	ushort basic_ds;
	uint basic_int1c;
	uint basic_int23;
	uint basic_int24;
	ushort dos_storage;
	ubyte [14]diskette_init_table;	/// DOS
	ushort mode;	// Referring to the MODE command
}
static assert(SYSTEM_t.COM1.offsetof == 0x400);
static assert(SYSTEM_t.kb_buf_off_start.offsetof == 0x480);
static assert(SYSTEM_t.print_scr_status.offsetof == 0x500);