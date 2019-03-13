/**
 * Virtual I/O handling, mostly I/O port and IN/OUT instructions.
 *
 * All functions have the vio_ prefix, take care of handling the CPU
 * registers.
 */
module vdos.io;

import vcpu.core : CPU;

extern (C):


void vio_send(ushort port) {
	
}

void vio_recv(ushort port) {
	
}