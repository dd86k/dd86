/*
 * poshub.d : In-house console library.
 */

module poshublib;

enum {
    POSHUB_VER = "0.0.0"
}

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
     * ASCII Titles
     */

    string GetTitle() {
        version (Windows) {
            string str = new string(MAX_PATH);
            GetConsoleTitleA(cast(char*)&str[0], MAX_PATH);
            return str;
        } else {
            return null;
        }
    }

    void SetTitle(string str) {
        version (Windows) {
            SetConsoleTitleA(&str[0]);
        }
    }

    /*
    * Wide Titles
    */

    wstring GetTitleWide() {
        version (Windows) {
            wstring str = new wstring(MAX_PATH);
            GetConsoleTitleW(cast(wchar*)&str[0], MAX_PATH);
            return str;
        } else {
            return null;
        }
    }

    void SetTitleWide(wstring str) {
        version (Windows) {
            SetConsoleTitleW(&str[0]);
        }
    }

    /*
     * STDIN
     */

    char ReadChar()
    {
        version (Windows) {
            INPUT_RECORD ir;
            ReadConsoleInputA(hOut, &ir, 1, NULL);

            if (ir.Event.KeyEvent.bKeyDown)
            {
                return ir.Event.KeyEvent.uChar.AsciiChar;
            }

            return 0;
        } else version (Posix) {


            return 0;
        }
    }
}