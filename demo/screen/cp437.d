import vcpu, vdos, vdos_screen, ddcon;
import core.stdc.string : memset;

unittest {
	vcon_init;
	vcpu_init;
	vdos_init;

	Clear;

	for (size_t i; i < 80 * 25; ++i)
		VIDEO[i].attribute = 0x1F;

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
	VIDEO[162].ascii = 0xbf;
	VIDEO[162].attribute = 0x1A;
	VIDEO[241].ascii = 'e';
	VIDEO[241].attribute = 0x1A;

	SYSTEM.cursor[0].col = 0;
	SYSTEM.cursor[0].row = 2;
	__v_putn("\xDA"); //TODO: Print dd-dos logo

	screen_draw;

	SetPos(0,25); // puts test result messages at the send
}