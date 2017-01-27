/*
 * Utils.cpp : Utilities.
 */

#include "Utils.hpp"

byte GetLower(ushort n) {
    return n & 0xFF;
}
byte GetUpper(ushort n) {
    return n >> 8 & 0xFF;
}
void SetLower(ushort & n, byte v){
    n |= v;
}
void SetUpper(ushort & n, byte v){
    n |= v << 8;
}