module vcpu32; // 80286

import vcpu16;

/**
 * Execute an instruction in PROTECTED mode
 * Params: op = opcode
 */
extern (C)
void exec32(ubyte op) {
	switch (op) {
/* TODO:
	APRL
	BOUND
	IMUL R16, R16, IMM
	IMUL R16, M16, IMM
	INS
	LAR R16, R16
	LAR R16, M16
	LEAVE
	LGDT
	LIDT
	LLDT
	LMSW
	LSL R16, R16
	LSL R16, M16
	LTR
	OUTS
	POPA
	PUSH IMM
	PUSHA
	RCL REG, IMM
	RCL MEM, IMM
	RCR REG, IMM
	RCR MEM, IMM
	ROL REG, IMM
	ROL MEM, IMM
	SAL/SHL/SAR/SHR REG, IMM
	SAL/SHL/SAR/SHR MEM, IMM
	SGDT
	SIDT
	SLDT
	STR
	VERR
	VERW
*/
	case 0:
	default:
		exec16(op); // temporary?
	}
}