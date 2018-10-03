import vcpu, vdos, vdos_screen, ddcon;
import core.stdc.string : memset;

unittest {
	vcon_init;
	vcpu_init;
	vdos_init;

	videochar* v = cast(videochar*)(MEMORY + __VGA_ADDRESS);

	Clear;

	for (size_t i; i < 80 * 25; ++i)
		v[i].attribute = 0x1F;

	v[0].ascii = 'H';
	v[1].ascii = 'e';
	v[2].ascii = 'l';
	v[3].ascii = 'l';
	v[4].ascii = 'o';
	v[5].ascii = '!';
	v[77].ascii = 'H';
	v[78].ascii = 'e';
	v[79].ascii = 'l';
	v[80].ascii = 'l';
	v[81].ascii = 'o';
	v[82].ascii = '!';

	SYSTEM.cursor[0].col = 0;
	SYSTEM.cursor[0].row = 2;
	__v_putn("\xDA"); //TODO: Print dd-dos logo

	screen_draw;

	SetPos(0,25); // puts test result messages at the send
}