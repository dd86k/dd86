module bench_;

import vcpu, std.stdio, vdos, ddcon, vdos_screen;
import std.datetime.stopwatch : StopWatch;
import core.time, std.conv;

private enum RUNS = 60;

unittest {
	StopWatch sw;
	Duration r_once, r_multiple;

	vcon_init;
	vcpu_init;
	vdos_init;
	Clear;

	VIDEO[0].ascii = 'a';
	VIDEO[0].attribute = 0x2E;
	VIDEO[1].ascii = 'e';
	VIDEO[1].attribute = 0x2E;
	VIDEO[80].ascii = 'F';
	VIDEO[80].attribute = 0x1A;
	VIDEO[81].ascii = 'e';
	VIDEO[81].attribute = 0x1A;

	sw.start;
	screen_draw;
	sw.stop;

	r_once = sw.peek;

	sw.reset; // won't pause
	for (uint i; i < RUNS; ++i) screen_draw;
	sw.stop;

	r_multiple = sw.peek;

	SetPos(0, 25);
	writefln("one draw: %s", r_once);
	writefln("%d draws: %s", RUNS, r_multiple);
}