/**
 * Virtual I/O handling, mostly I/O port and IN/OUT instructions. Usually
 * handled by the BIOS. All functions have the vio_ prefix, and take care of
 * handling the CPU registers. Each port manages their own operations (IO_IN or
 * IO_OUT set) and may change CPU register values. I/O port may depend on
 * configured equipment, and only a subset of hardware and ports are emulated.
 */
module vdos.io;

import vcpu.core : CPU;

extern (C):

enum : ubyte {
	IO_IN,	/// Receive (RX)
	IO_OUT,	/// Transmit (TX)
	
	IO_BYTE,	/// Byte data
	IO_WORD,	/// Word data
	IO_DWORD,	/// Dword data
}

/**
 * Performs an I/O operation (e.g. IN or OUT instruction) to an emulated piece
 * of hardware. 
 * Params:
 *   op = I/O operation
 *   port = I/O port
 *   width = Data width (1, 2, or 4 bytes wide)
 *   data = Tranmission data
 */
void io(ubyte op, ushort port, ubyte width, int *data) {
	switch (port) {
	//
	// Monochrome Display Adapter (MDA)
	//
	case 0x3B0: break;
	case 0x3B1: break;
	case 0x3B2: break;
	case 0x3B3: break;
	case 0x3B4: break;
	case 0x3B5: break;
	case 0x3B6: break;
	case 0x3B7: break;
	case 0x3B8: break;
	case 0x3BA: break;
	//
	// Color Graphic Adapater (CGA)
	//
	case 0x3D8: break;
	case 0x3D9: break;
	case 0x3DA: break;
	//
	// Light Pen (under CGA)
	//
	case 0x3DB: break;
	case 0x3DC: break;
	default:
	}
}