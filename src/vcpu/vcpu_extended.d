/*
 * Intel 80486 processor emulator
 */

module vcpu_80486;

import vcpu, vcpu_utils;
import vdos_int;
import Logger;

/**
 * Execute an instruction under EXTENDED mode.
 * Params: op = operation code
 */
extern (C)
void exec32(ubyte op) {

}