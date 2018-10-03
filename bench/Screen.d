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

	VIDEO[1].ascii = 'e';
	VIDEO[1].attribute = 0x2E;

	sw.start;
	screen_draw;
	sw.stop;

	r_once = sw.peek;

	sw.reset; // won't pause
	for (uint i; i < RUNS; ++i) screen_draw;
	sw.stop;

	r_multiple = sw.peek;

	SetPos(0, 25);
	writefln("Once: %s", r_once);
	writefln("%d times: %s", RUNS, r_multiple);
}