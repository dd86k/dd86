/**
 * Protected mode functions, structures, and utilities. Includes paging and
 * segmentation features.
 *
 * All functions in this module have the `p_` prefix.
 */
module vcpu.protection;

import vcpu.core : MEM;

__gshared:
extern (C):

/// Global Descriptor Table pointer to MEMORY
SegDesc_t *GDT;

//
// * Protection features
//

/**
 * Segment Descriptor Table
 * 
 * Contains a 16-bit segment selector and 32-bit base for setting up
 * protected mode alongside all the necessary flags for a segment.
 *
 * These fields may change depending on the type of descriptor it is. For
 * example, an GDT will have the following fields, but an IDT, depending
 * on its type, may use the base 15:0 field for either a segment selector
 * (interrupt game or trap gate) or the TSS segment selector for a Task Gate.
 *
 * ---
 * Bits   Description
 * 63:56  Base 32:24
 *    55  Granularity bit (G)
 *    54  Default operation size (D/B). Set: 32-bit operations; Unset: 16-bit
 *    53  LONG mode segment (IA-32e only, unsused) (L)
 *    52  Available for user software (AVL)
 * 51:48  Segment 19:16
 *    47  Segment present (P)
 * 46:45  Descriptor Privilege Level (DPL)
 *    44  Descriptor type (S). Set: Code/Data; Unset: System
 * 43:40  Type
 * 39:32  Base 23:16
 * 31:16  Base 15:0
 *  15:0  Segment limit 15:0
 * ---
 *
 * This structure is used for GDT, LDT, IDT, TSS, DSD, CSD, SSD descriptor
 * tables.
 */
struct SegDesc_t { align(1):
	union {
		uint low_dword;
		struct {
			ushort segment0_15, base0_15;
		}
	}
	union {
		uint high_dword;
		struct {
			ubyte base16_23, type, flags, base24_31;
		}
	}
}
static assert(SegDesc_t.sizeof == 8);

/**
 * Get a segment descriptor from MEMORY location to ease parsing and reading.
 * Params: loc = Memory location
 * Returns: Segment Descriptor structure pointer from MEMORY
 */
pragma(inline, true)
SegDesc_t *p_segdesc(uint loc) {
	return cast(SegDesc_t*)(MEM + loc);
}

//
// * Paging features
//

struct Page { align(1):
	uint size; /// 
	ubyte *data; /// 
}

//
// * Task features
//

/// 16-bit Task Segment
struct TaskSeg16_t { align(1):
	ushort prev_task, SP0, SS0, SP1, SS1, SP2, SS2,
		IP, FLAG, AX, CX, DX, BX, SP, BP, SI, DI, ES, CS, SS, DS, LDT;
}
static assert(TaskSeg16_t.sizeof == 44);

/// 32-bit Task Segment
struct TaskSeg32_t { align(1):
	ushort prev_task, res;
	uint ESP0;
	ushort SS0, res0;
	uint ESP1;
	ushort SS1, res1;
	uint ESP2;
	ushort SS2, res2;
	uint CR3, EIP, EFLAG, EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI;
	ushort ES, res3, CS, res4, SS, res5, DS, res6, FS, res7, GS, res8,
		LDT, res9, flags, iobase;
}
static assert(TaskSeg32_t.sizeof == 104);

pragma(inline, true):

/**
 * Get a 16-bit task segment from MEMORY location to ease parsing and reading.
 * Params: loc = Memory location
 * Returns: 16-bit Task Segment structure pointer from MEMORY
 */
TaskSeg16_t *p_taskseg16(uint loc) {
	return cast(TaskSeg16_t*)(MEM + loc);
}

/**
 * Get a 32-bit task segment from MEMORY location to ease parsing and reading.
 * Params: loc = Memory location
 * Returns: 32-bit Task Segment structure pointer from MEMORY
 */
TaskSeg32_t *p_taskseg32(uint loc) {
	return cast(TaskSeg32_t*)(MEM + loc);
}