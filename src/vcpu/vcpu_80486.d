/*
 * Intel 80486 processor emulator
 */

module vcpu_80486;

import vcpu, vcpu_utils;
import vdos : Raise;
import Logger;

/**
 * Execute an instruction under EXTENDED mode.
 * Params: op = operation code
 */
extern (C)
void exec32(ubyte op) {

}