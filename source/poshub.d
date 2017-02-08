/*
 * poshub.d : In-house console library.
 */

module poshublib;

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
        } else {
            winsize ws;
            ioctl(0, TIOCGWINSZ, &ws);
            return ws.ws_col;
        }
    }

    void SetWindowWidth(ushort w) {
        // Note: A COORD uses SHORT (short) and Linux uses unsigned shorts.
        version (Windows) {
            COORD c = { cast(SHORT)w, cast(SHORT)GetWindowWidth() };
            SetConsoleScreenBufferSize(hOut, c);
        } else {
            winsize ws = { w, GetWindowWidth() };
            ioctl(0, TIOCSWINSZ, &ws);
        }
    }

    ushort GetWindowHeight() {
        version (Windows) {
            CONSOLE_SCREEN_BUFFER_INFO i;
            GetConsoleScreenBufferInfo(hOut, &i);
            return cast(ushort)(i.srWindow.Bottom - i.srWindow.Top + 1);
        } else {
            winsize ws;
            ioctl(0, TIOCGWINSZ, &ws);
            return ws.ws_row;
        }
    }

    void SetWindowHeight(ushort h) {
        version (Windows) {
            COORD c = { cast(SHORT)GetWindowWidth(), cast(SHORT)h };
            SetConsoleScreenBufferSize(hOut, c);
        } else {
            winsize ws = { GetWindowWidth(), h, 0, 0 };
            ioctl(0, TIOCSWINSZ, &ws);
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
            static assert(0, "GetTitle needs implementation.");
        }
    }

    void SetTitle(string str) {
        version (Windows) {
            SetConsoleTitleA(&str[0]);
        } else {
            static assert(0, "SetTitle needs implementation.");
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
            static assert(0, "GetTitleWide needs implementation.");
        }
    }

    void SetTitleWide(wstring str) {
        version (Windows) {
            SetConsoleTitleW(&str[0]);
        } else {
            static assert(0, "SetTitle needs implementation.");
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
        } else {

        }
    }
}