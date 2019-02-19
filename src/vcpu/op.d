/**
 * Main module for core CPU operations, including ADD, IMUL, etc. These
 * functions are meant to be favored over manual implementation in instructions.
 * These functions update flags as necessary 
 */
module vcpu.op;

import vcpu.core : CPU;
import vcpu.utils;

pragma(inline, true):
extern (C):
nothrow:
@nogc:

////////////////////////////////////////
//
// ADD
//
////////////////////////////////////////

int addi32(int a, int b) {
	long r = a + b;
	cpuf32_1(r);
	return cast(int)r;
}