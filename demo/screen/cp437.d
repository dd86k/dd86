import vcpu, vdos, vdos_screen, ddcon;
import core.stdc.string : memset;

unittest {
	vcon_init;
	vcpu_init;
	vdos_init;

	videochar* video = cast(videochar*)(MEMORY + __VGA_ADDRESS);

	Clear;

	for (size_t i; i < 80 * 25; ++i)
		video[i].attribute = 0x1F;

	video[0].ascii = 'H';
	video[1].ascii = 'e';
	video[2].ascii = 'l';
	video[3].ascii = 'l';
	video[4].ascii = 'o';
	video[5].ascii = '!';
	video[77].ascii = 'H';
	video[78].ascii = 'e';
	video[79].ascii = 'l';
	video[80].ascii = 'l';
	video[81].ascii = 'o';
	video[82].ascii = '!';

	screen_draw;

	SetPos(0,25); // puts test result messages at the send
}