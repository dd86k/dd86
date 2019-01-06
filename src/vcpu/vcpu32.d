module vcpu32; // 80486+

import vcpu16;

/**
 * Execute an instruction in 32-bit PROTECTED mode
 * Params: op = opcode
 */
extern (C)
void exec32(ubyte op) {
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