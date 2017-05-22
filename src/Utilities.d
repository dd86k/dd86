/**
 * Utilities.d : Generic utilities
 */

module Utilities;

/**
 * Fetches a string from memory.
 * Params:
 *   mem = Memory pointer
 *   pos = Starting position
 * Returns: String
 */
string MemString(void* mem, uint pos) pure
{
    import core.stdc.string : strlen;
    const size_t len = strlen(cast(char*)(mem + pos));
    return cast(string)mem[pos..pos+len];
}

/**
 * Return a formatted string.
 * Params: size = Size in bytes.
 * Returns: Formatted string.
 */
string formatsize(long size) //BUG: %f is unpure?
{
    import std.format : format;

    enum : long {
        KB = 1024,
        MB = KB * 1024,
        GB = MB * 1024,
        TB = GB * 1024,
        KiB = 1000,
        MiB = KiB * 1000,
        GiB = MiB * 1000,
        TiB = GiB * 1000
    }

	const float s = size;

    if (size > TB)
        if (size > 100 * TB)
            return format("%d TB", size / TB);
        else if (size > 10 * TB)
            return format("%0.1f TB", s / TB);
        else
            return format("%0.2f TB", s / TB);
    else if (size > GB)
        if (size > 100 * GB)
            return format("%d GB", size / GB);
        else if (size > 10 * GB)
            return format("%0.1f GB", s / GB);
        else
            return format("%0.2f GB", s / GB);
    else if (size > MB)
        if (size > 100 * MB)
            return format("%d MB", size / MB);
        else if (size > 10 * MB)
            return format("%0.1f MB", s / MB);
        else
            return format("%0.2f MB", s / MB);
    else if (size > KB)
        if (size > 100 * KB)
            return format("%d KB", size / KB);
        else if (size > 10 * KB)
            return format("%0.1f KB", s / KB);
        else
            return format("%0.2f KB", s / KB);
    else
        return format("%d B", size);
}