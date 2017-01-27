/*
 * Utils.hpp
 */

#pragma once

// Ala C#
using byte = unsigned char;
using ushort = unsigned short;
using uint = unsigned int;

byte GetLower(ushort);
byte GetUpper(ushort);
void SetLower(ushort&, byte);
void SetUpper(ushort&, byte);