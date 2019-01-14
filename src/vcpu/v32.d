/**
 * v32: Protected-mode instructions
 */
module vcpu.v32; // 80486+

import vcpu.core;
import vcpu.v16 : exec16;

extern (C):

pragma(inline, true)
void exec32(ubyte op) {
	v32(op);
	//PROT_MAP[op]();
}

/**
 * Execute an instruction in 32-bit PROTECTED mode
 * Params: op = opcode
 */
void v32(ubyte op) {
	switch (op) {
	case 0x00: // ADD
		
		break;
	case 0x66: // OPCODE PREFIX
		++CPU.EIP;
		exec16(MEMORY[CPU.EIP]);
		break;
	default: //TODO: illegal op exec32

	}
}