module bench_;

import vcpu, std.stdio, vdos, os.term, vdos.video;
import std.datetime.stopwatch : StopWatch;
import core.time, std.conv;

private enum RUNS = 60;

unittest {
	con_init;
	vcpu_init;
	vdos_init;

	Clear;

	StopWatch sw;
	Duration r_once, r_multiple;

	VIDEO[0].ascii = 'H';
	VIDEO[1].ascii = 'e';
	VIDEO[2].ascii = 'l';
	VIDEO[3].ascii = 'l';
	VIDEO[4].ascii = 'o';
	VIDEO[5].ascii = '!';
	VIDEO[77].ascii = 'H';
	VIDEO[78].ascii = 'e';
	VIDEO[79].ascii = 'l';
	VIDEO[80].ascii = 'l';
	VIDEO[81].ascii = 'o';
	VIDEO[82].ascii = '!';

	VIDEO[160].ascii = 0xda;
	VIDEO[160].attribute = 0x2E;
	VIDEO[161].ascii = 0xc4;
	VIDEO[161].attribute = 0x2E;
	VIDEO[162].ascii = 0xc4;
	VIDEO[162].attribute = 0x2E;
	VIDEO[163].ascii = 0xbf;
	VIDEO[163].attribute = 0x1A;
	VIDEO[241].ascii = 219;
	VIDEO[241].attribute = 0x1A;
	VIDEO[242].ascii = 151;
	VIDEO[242].attribute = 0x1A;

	screen_draw; // "in case" warm up

	sw.start;
	screen_draw;
	sw.stop;

	r_once = sw.peek;

	sw.reset; // won't pause
	for (size_t i; i < RUNS; ++i) screen_draw;
	sw.stop;

	r_multiple = sw.peek;

	SetPos(0, 26);
	writefln("one draw: %s", r_once);
	writefln("%d draws: %s", RUNS, r_multiple);
}