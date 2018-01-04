/**
 * Utilities.d: Generic utilities
 */

module Utilities;

/**
 * Fetches a string from memory.
 * Params:
 *   mem = Memory pointer
 *   pos = Starting position
 * Returns: String
 */
string MemString(void* mem, uint pos) pure {
    import core.stdc.string : strlen;
    const size_t len = strlen(cast(char*)(mem + pos));
    return cast(string)mem[pos..pos+len];
}