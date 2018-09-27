import vcpu, vdos, vdos_screen, ddcon;
import core.stdc.string : memset;

unittest {
	vcpu_init;
	vdos_init;

	ubyte* video = MEMORY + __VGA_ADDRESS;

	Clear;

	video[0] = 'H';
	video[2] = 'e';
	video[4] = 'l';
	video[6] = 'l';
	video[8] = 'o';
	video[10] = '!';

	screen_draw;
}