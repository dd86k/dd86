/*
 * poshub.cpp : In-house console library.
 */


#include "stdio.h"
#include <iostream>

#if _WIN32
#include <windows.h>
#elif __GNUC__
#include <termios.h>
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

    /*
     * Window dimensions.
     */

    short GetWindowWidth() {
#if _WIN32
        CONSOLE_SCREEN_BUFFER_INFO i;
        GetConsoleScreenBufferInfo(hOut, &i);
        return i.srWindow.Right - i.srWindow.Left + 1;
#elif __GNUC__
        winsize ws;
        ioctl(0, TIOCGWINSZ, &ws);
        return ws.ws_col;
#endif
    }

    void SetWindowWidth(unsigned short w) {
        // Note: A COORD uses SHORT (short) and Linux uses unsigned shorts.
#if _WIN32
        SetConsoleScreenBufferSize(
            hOut,
            { (short)w, GetWindowWidth() }
        );
#elif __GNUC__
        winsize ws = { w, GetWindowWidth() };
        ioctl(0, TIOCSWINSZ, &ws);
#endif
    }

    short GetWindowHeight() {
#if _WIN32
        CONSOLE_SCREEN_BUFFER_INFO i;
        GetConsoleScreenBufferInfo(hOut, &i);
        return i.srWindow.Bottom - i.srWindow.Top + 1;
#elif __GNUC__
        winsize ws;
        ioctl(0, TIOCGWINSZ, &ws);
        return ws.ws_row;
#endif
    }
    
    void SetWindowHeight(unsigned short h) {
#if _WIN32
        SetConsoleScreenBufferSize(
            hOut,
            { GetWindowWidth(), (short)h }
        );
#elif __GNUC__
        winsize ws = { GetWindowWidth(), h, 0, 0 };
        ioctl(0, TIOCSWINSZ, &ws);
#endif
    }

    /*
     * ASCII Titles
     */

    std::string GetTitle() {
#if _WIN32
        std::string str(MAX_PATH, 0);
        GetConsoleTitleA(&str[0], MAX_PATH);
        return str;
#elif __GNUC__
#error: GetTitle needs implementation.
#endif
    }

    void SetTitle(std::string str) {
#if _WIN32
        SetConsoleTitleA(&str[0]);
#elif __GNUC__
#error: SetTitle needs implementation.
#endif
    }

    /*
     * Wide Titles
     */

    std::wstring GetTitleWide() {
#if _WIN32
        std::wstring str(MAX_PATH, 0);
        GetConsoleTitleW(&str[0], MAX_PATH);
        return str;
#elif __GNUC__
#error: GetTitle needs implementation.
#endif
    }

    void SetTitleWide(std::wstring str) {
#if _WIN32
        SetConsoleTitleW(&str[0]);
#elif __GNUC__
#error: SetTitle needs implementation.
#endif
    }
};