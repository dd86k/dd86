/*
 * poshub.d : In-house console library.
 */

module poshub;

import std.stdio;
alias sys = core.stdc.stdlib.system;

version (Windows)
{
    import core.sys.windows.windows;
    /// Input and output handles
    HANDLE hIn, hOut;
}
else version (Posix)
{
    import core.sys.posix.sys.ioctl;
    //import core.sys.posix.termios;
}

/// Initiate poshub
void InitConsole()
{
    version (Windows)
    {
        hOut = GetStdHandle(STD_OUTPUT_HANDLE);
        hIn = GetStdHandle(STD_INPUT_HANDLE);
    }
}

/*
 * Buffer management.
 */

/// Clear screen
void Clear()
{
    // Lazy alert
    version (Windows)
        sys ("cls");
    else version (Posix)
        sys ("clear");
    else static assert(0, "Clear: Not implemented");
}

/*
 * Window dimensions.
 */
// Note: A COORD uses SHORT (short) and Linux uses unsigned shorts.

/// Window width
@property ushort WindowWidth()
{
    version (Windows)
    {
        CONSOLE_SCREEN_BUFFER_INFO i;
        GetConsoleScreenBufferInfo(hOut, &i);
        return cast(ushort)(i.srWindow.Right - i.srWindow.Left + 1);
    }
    else version (Posix)
    {
        winsize ws;
        ioctl(0, TIOCGWINSZ, &ws);
        return ws.ws_col;
    }
    else
    {
        static assert(0, "WindowWidth : Not implemented");
    }
}

/// Window width
@property void WindowWidth(int w)
{
    version (Windows)
    {
        COORD c = { cast(SHORT)w, cast(SHORT)WindowWidth };
        SetConsoleScreenBufferSize(hOut, c);
    }
    else version (Posix)
    {
        winsize ws = { cast(ushort)w, WindowWidth };
        ioctl(0, TIOCSWINSZ, &ws);
    }
    else
    {
        static assert(0, "WindowWidth : Not implemented");
    }
}

/// Window height
@property ushort WindowHeight()
{
    version (Windows)
    {
        CONSOLE_SCREEN_BUFFER_INFO i;
        GetConsoleScreenBufferInfo(hOut, &i);
        return cast(ushort)(i.srWindow.Bottom - i.srWindow.Top + 1);
    }
    else version (Posix)
    {
        winsize ws;
        ioctl(0, TIOCGWINSZ, &ws);
        return ws.ws_row;
    }
    else
    {
        static assert(0, "WindowHeight : Not implemented");
    }
}

/// Window height
@property void WindowHeight(int h)
{
    version (Windows)
    {
        COORD c = { cast(SHORT)WindowWidth, cast(SHORT)h };
        SetConsoleScreenBufferSize(hOut, c);
    }
    else version (Posix)
    {
        winsize ws = { WindowWidth, cast(ushort)h, 0, 0 };
        ioctl(0, TIOCSWINSZ, &ws);
    }
    else
    {
        static assert(0, "WindowHeight : Not implemented");
    }
}

/*
 * Cursor
 */

/// Set cursor position, 0-based.
void SetPos(short x, short y)
{
    version (Windows)
    {
        COORD c = { x, y };
        SetConsoleCursorPosition(hOut, c);
    }
    else version (Posix)
    { // Works!
        write("\033[", y + 1, ";", x + 1, "H");
    }
}

@property ushort CursorLeft()
{
    version (Windows)
    {


        return 0;
    }
    else version (Posix)
    {


        return 0;
    }
}

@property ushort CursorTop()
{
    version (Windows)
    {


        return 0;
    }
    else version (Posix)
    {


        return 0;
    }
}

/*
 * Titles
 */

/// Set session title
@property void Title(string value)
{
    version (Windows)
    {
        // Sanity check
        if (value[$-1] != '\0') value ~= '\0';
        SetConsoleTitleA(&value[0]);
    }
}

/// Set session title
@property void Title(wstring value)
{
    version (Windows)
    {
        // Sanity check
        if (value[$-1] != '\0') value ~= '\0';
        SetConsoleTitleW(&value[0]);
    }
}

/// Get session title
@property string Title()
{
    version (Windows)
    {
        char[255] buf;
        return buf[0..GetConsoleTitleA(&buf[0], MAX_PATH)].idup;
    }
    else 
    {
        return null;
    }
}

/*
 * Input
 */

/// Read a single character.
char ReadChar(bool echo = false)
{
    version (Windows)
    {
        INPUT_RECORD ir;
        ReadConsoleInputA(hOut, &ir, 1, NULL);

        //TODO: while loop

        if (ir.Event.KeyEvent.bKeyDown)
        {
            if (echo)
                write(ir.Event.KeyEvent.uChar.AsciiChar);
            return ir.Event.KeyEvent.uChar.AsciiChar;
        }

        return 0;
    }
    else version (Posix)
    {
        import std.uni : isControl;
        int t;
        while (isControl(t = getchar())) {}
        char c = cast(char)t;
        if (echo)
            write(c);
        return c;
        /+
int character;
struct termios orig_term_attr;
struct termios new_term_attr;

/* set the terminal to raw mode */
tcgetattr(fileno(stdin), &orig_term_attr);
memcpy(&new_term_attr, &orig_term_attr, sizeof(struct termios));
new_term_attr.c_lflag &= ~(ECHO|ICANON);
new_term_attr.c_cc[VTIME] = 0;
new_term_attr.c_cc[VMIN] = 0;
tcsetattr(fileno(stdin), TCSANOW, &new_term_attr);

/* read a character from the stdin stream without blocking */
/*   returns EOF (-1) if no character is available */
character = fgetc(stdin);

/* restore the original terminal attributes */
tcsetattr(fileno(stdin), TCSANOW, &orig_term_attr);

return character;
        +/
    }
}

/// Read a single character.
KeyInfo ReadKey(bool echo = false)
{
    version (Windows)
    {
        INPUT_RECORD ir;
        ReadConsoleInputA(hOut, &ir, 1, NULL);

        KeyInfo k;
        
        k.alt  = ir.KeyEvent.dwControlKeyState & RIGHT_ALT_PRESSED ||
                    ir.KeyEvent.dwControlKeyState & LEFT_ALT_PRESSED;
        k.ctrl = ir.KeyEvent.dwControlKeyState & RIGHT_CTRL_PRESSED ||
                    ir.KeyEvent.dwControlKeyState & LEFT_ALT_PRESSED;
        k.shift = (ir.KeyEvent.dwControlKeyState & SHIFT_PRESSED) != 0;
        k.keyChar = ir.KeyEvent.AsciiChar;
        k.keyCode = ir.KeyEvent.wVirtualKeyCode;
        k.scanCode = ir.KeyEvent.wVirtualScanCode;
        k.isKeyDown = ir.KeyEvent.bKeyDown != 0;

        if (k.isKeyDown && echo)
            write(k.keyChar);

        return k;
    }
    else version (Posix)
    {
        KeyInfo k;



        return k;
    }
}

/// Key information structure
// ala C#
struct KeyInfo
{
    ///
    char keyChar;
    ///
    ushort keyCode, scanCode;
    ///
    bool isKeyDown;
    ///
    bool ctrl, alt, shift;
}