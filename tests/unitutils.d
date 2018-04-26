import std.stdio;

enum SPACES = 16;

void test(string s) {
	writef("%-*s: ", SPACES, s);
}
void section(string s) {
	writeln("\n---------- ", s);
}
void sub(string s) {
	writeln("\n--- ", s);
}
void OK() {
	writeln("OK");
}