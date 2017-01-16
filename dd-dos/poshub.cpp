
#include "stdio.h"

#if _WIN32
#include <windows.h>
#endif

struct poshub {
#if _WIN32
    HANDLE hIn, hOut;
#endif

    void Init() {
#if _WIN32
        hOut = GetStdHandle(STD_OUTPUT_HANDLE);
        hIn = GetStdHandle(STD_INPUT_HANDLE);
#endif
    }
};