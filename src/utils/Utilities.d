/**
 * Utilities.d: Generic utilities
 */

module Utilities;

import Interpreter : MEMORY;

/**
 * Fetches a string from memory.
 * Params:
 *   pos = Starting position
 * Returns: String
 */
string MemString(uint pos) {
    import core.stdc.string : strlen;
    const size_t len = strlen(cast(char*)MEMORY + pos);
    return cast(string)MEMORY[pos..pos+len];
}