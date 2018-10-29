import vcpu, vdos, vdos_screen, ddcon;
import core.stdc.string : memset;

unittest {
	con_init;
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
	VIDEO[82].ascii = '~';

	//TODO: Finish colourful 'thing'
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

	SYSTEM.cursor[0].col = 0;
	SYSTEM.cursor[0].row = 5;

	__v_put("__v_put\n");
	__v_putn("__v_putn");
	__v_printf("__v_printf: %d\n", 32);

	screen_logo; // print logo

	__v_putn("END");

	screen_draw; // draw on screen

	SetPos(0, 26); // puts test result messages at the end
}