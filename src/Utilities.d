/**
 * Utilities.d : Generic utilities
 */

module Utilities;

string MemString(ubyte* mem, uint pos) pure
{
    import core.stdc.string : strlen;
    size_t len = strlen(cast(char*)&mem[pos]);
    return cast(string)mem[pos..pos+len];
}