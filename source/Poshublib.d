/*
 * poshub.d : In-house console library.
 */

module poshublib;

import std.stdio;

enum {
    POSHUB_VER = "0.0.0"
}

pragma(msg, "Poshub version : ", POSHUB_VER);

struct poshub
{
    version (Windows)
    {
        import core.sys.windows.windows;
        HANDLE hIn, hOut;
    }

    void Init()
    {
        version (Windows)
        {
            hOut = GetStdHandle(STD_OUTPUT_HANDLE);
            hIn = GetStdHandle(STD_INPUT_HANDLE);
        }
    }

    /*
     * Window dimensions.
     */

    ushort GetWindowWidth() {
        version (Windows) {
            CONSOLE_SCREEN_BUFFER_INFO i;
            GetConsoleScreenBufferInfo(hOut, &i);
            return cast(ushort)(i.srWindow.Right - i.srWindow.Left + 1);
        } else version (Posix) {
            import core.sys.posix.sys.ioctl;
            winsize ws;
            ioctl(0, TIOCGWINSZ, &ws);
            return ws.ws_col;
        } else {
            static assert(0, "poshub::GetWindowWidth : Needs implementation.");
        }
    }

    void SetWindowWidth(ushort w) {
        // Note: A COORD uses SHORT (short) and Linux uses unsigned shorts.
        version (Windows) {
            COORD c = { cast(SHORT)w, cast(SHORT)GetWindowWidth() };
            SetConsoleScreenBufferSize(hOut, c);
        } else version (Posix) {
            import core.sys.posix.sys.ioctl;
            winsize ws = { w, GetWindowWidth() };
            ioctl(0, TIOCSWINSZ, &ws);
        } else {
            static assert(0, "poshub::SetWindowWidth : Needs implementation.");
        }
    }

    ushort GetWindowHeight() {
        version (Windows) {
            CONSOLE_SCREEN_BUFFER_INFO i;
            GetConsoleScreenBufferInfo(hOut, &i);
            return cast(ushort)(i.srWindow.Bottom - i.srWindow.Top + 1);
        } else version (Posix) {
            import core.sys.posix.sys.ioctl;
            winsize ws;
            ioctl(0, TIOCGWINSZ, &ws);
            return ws.ws_row;
        } else {
            static assert(0, "poshub::GetWindowHeight : Needs implementation.");
        }
    }

    void SetWindowHeight(ushort h) {
        version (Windows) {
            COORD c = { cast(SHORT)GetWindowWidth(), cast(SHORT)h };
            SetConsoleScreenBufferSize(hOut, c);
        } else version (Posix) {
            import core.sys.posix.sys.ioctl;
            winsize ws = { GetWindowWidth(), h, 0, 0 };
            ioctl(0, TIOCSWINSZ, &ws);
        } else {
            static assert(0, "poshub::SetWindowHeight : Needs implementation.");
        }
    }

    /*
     * Cursor
     */

    /// Set cursor position relating to the window position.
    void SetPos(short x, short y)
    {
        version (Windows)
        {
            COORD c = { x, y };
            SetConsoleCursorPosition(hOut, c);
        }
    }

    /*
     * Titles
     */

    @property void Title(string value)
    {
        version (Windows)
        {
            //TODO: Check if null terminating is necessary
            SetConsoleTitleA(&value[0]);
        }
    }

    @property void Title(wstring value)
    {
        version (Windows)
        {
            //TODO: Check if null terminating is necessary
            SetConsoleTitleW(&value[0]);
        }
    }

    @property string Title() {
        version (Windows) {
            string str = new string(MAX_PATH);
            GetConsoleTitleA(cast(char*)&str[0], MAX_PATH);
            return str;
        } else {
            return null;
        }
    }

    /*
     * STDIN
     */

    char ReadChar(bool echo = false)
    {
        version (Windows) {
            INPUT_RECORD ir;
            ReadConsoleInputA(hOut, &ir, 1, NULL);

            if (ir.Event.KeyEvent.bKeyDown)
            {
                if (echo)
                    write(ir.Event.KeyEvent.uChar.AsciiChar);
                return ir.Event.KeyEvent.uChar.AsciiChar;
            }

            return 0;
        } else version (Posix) {
            //TODO: Test
            import std.uni;
            int t;
            while (isControl(t = getchar())) {}
            c = cast(char)t;
            if (echo)
                write(c);
            return c;
        }
    }

    KeyInfo ReadKey(bool echo = false)
    {
        version (Windows) {
            import core.sys.windows.windows;
            INPUT_RECORD ir;
            ReadConsoleInputA(hOut, &ir, 1, NULL);

            KeyInfo k;
            
            k.alt  = ir.KeyEvent.dwControlKeyState & RIGHT_ALT_PRESSED ||
                     ir.KeyEvent.dwControlKeyState & LEFT_ALT_PRESSED;
            k.ctrl = ir.KeyEvent.dwControlKeyState & RIGHT_CTRL_PRESSED ||
                     ir.KeyEvent.dwControlKeyState & LEFT_ALT_PRESSED;
            k.shift = (ir.KeyEvent.dwControlKeyState & SHIFT_PRESSED) != 0;
            k.keyChar = ir.KeyEvent.AsciiChar;
            k.key = ir.KeyEvent.wVirtualKeyCode;
            k.isKeyDown = ir.KeyEvent.bKeyDown != 0;

            if (k.down && echo)
                write(k.keyChar);

            return k;
        } else version (Posix) {
            import core.sys.posix.termios;
            KeyInfo k;



            return k;
        }
    }
}

struct KeyInfo
{
    char keyChar;
    ushort key;
    bool isKeyDown;
    bool ctrl, alt, shift;
}