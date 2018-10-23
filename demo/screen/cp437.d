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
	SYSTEM.cursor[0].row = 3;

	__v_putn("Now testing __v_putn");

	__v_putn("1");
	__v_putn("2");
	__v_putn("3");
	__v_putn("4");
	__v_putn("5");
	__v_putn("6");
	__v_putn("7");
	__v_putn("8");
	__v_putn("10");
	__v_putn("11");
	__v_putn("12");
	__v_putn("13");
	__v_putn("14");
	__v_putn("15");
	__v_putn("16");
	__v_putn("17");
	__v_putn("18");
	__v_putn("19");

	__v_putn("Hello again!");

	screen_logo; // print logo

	__v_putn("END");

	screen_draw; // draw on screen

	SetPos(0, 26); // puts test result messages at the send
}