/*
 * dd-dos.hpp: Main header file with aliases.
 */

#pragma once
#include "poshub.hpp"

// DD-DOS version.
static const char *APP_VERSION = "0.0.0";
// Reported DOS version.
static const unsigned short DOS_VERSION = 0x0000; // 00.00

enum OEM_ID { // Used for INT 21h AH=30 so far.
    IBM, Compaq, MSPackagedProduct, ATnT, ZDS
};

static poshub Con;