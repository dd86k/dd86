/*
 * poshub.cpp : In-house console library.
 */


#include "stdio.h"
#include "poshub.hpp"
#include <iostream>

#if _WIN32
#include <windows.h>
#elif __GNUC__
#include <termios.h>
#endif

poshub::poshub() {
	hOut = nullptr;
	hIn = nullptr;
}

void poshub::Init() {
#if _WIN32
    hOut = GetStdHandle(STD_OUTPUT_HANDLE);
    hIn = GetStdHandle(STD_INPUT_HANDLE);
#endif
}

/*
 * Window dimensions.
 */

unsigned short poshub::GetWindowWidth() {
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

void poshub::SetWindowWidth(unsigned short w) {
    // Note: A COORD uses SHORT (short) and Linux uses unsigned shorts.
#if _WIN32
    SetConsoleScreenBufferSize(
        hOut,
        { (SHORT)w, (SHORT)GetWindowWidth() }
    );
#elif __GNUC__
    winsize ws = { w, GetWindowWidth() };
    ioctl(0, TIOCSWINSZ, &ws);
#endif
}

unsigned short poshub::GetWindowHeight() {
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

void poshub::SetWindowHeight(unsigned short h) {
#if _WIN32
    SetConsoleScreenBufferSize(
        hOut,
        { (SHORT)GetWindowWidth(), (SHORT)h }
    );
#elif __GNUC__
    winsize ws = { GetWindowWidth(), h, 0, 0 };
    ioctl(0, TIOCSWINSZ, &ws);
#endif
}

/*
 * ASCII Titles
 */

std::string poshub::GetTitle() {
#if _WIN32
    std::string str(MAX_PATH, 0);
    GetConsoleTitleA(&str[0], MAX_PATH);
    return str;
#elif __GNUC__
#error: GetTitle needs implementation.
#endif
}

void poshub::SetTitle(std::string str) {
#if _WIN32
    SetConsoleTitleA(&str[0]);
#elif __GNUC__
#error: SetTitle needs implementation.
#endif
}

/*
 * Wide Titles
 */

std::wstring poshub::GetTitleWide() {
#if _WIN32
    std::wstring str(MAX_PATH, 0);
    GetConsoleTitleW(&str[0], MAX_PATH);
    return str;
#elif __GNUC__
#error: GetTitle needs implementation.
#endif
}

void poshub::SetTitleWide(std::wstring str) {
#if _WIN32
    SetConsoleTitleW(&str[0]);
#elif __GNUC__
#error: SetTitle needs implementation.
#endif
}

/*
 * STDIN
 */

unsigned char poshub::ReadChar()
{
    INPUT_RECORD in;
    ReadConsoleInputA(hOut, &in, 1, NULL);

    if (in.Event.KeyEvent.bKeyDown)
    {
        return in.Event.KeyEvent.uChar.AsciiChar;
    }
    return NULL;
}