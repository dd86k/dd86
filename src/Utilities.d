/**
 * Utilities.d : Generic utilities
 */

module Utilities;

string MemString(void* mem, uint pos) pure
{
    import core.stdc.string : strlen;
    const size_t len = strlen(cast(char*)(mem + pos));
    return cast(string)mem[pos..pos+len];
}