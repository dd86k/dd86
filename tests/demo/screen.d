import os.term;
import vcpu.core;
import vdos.os;
import vdos.video;

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
	VIDEO[82].ascii = '!';

	// top
	VIDEO[160].ascii = 0xda;
	VIDEO[160].attribute = 0x2E;
	VIDEO[161].ascii = 0xc4;
	VIDEO[161].attribute = 0x2E;
	VIDEO[162].ascii = 0xc4;
	VIDEO[162].attribute = 0x2E;
	VIDEO[163].ascii = 0xbf;
	VIDEO[163].attribute = 0x2E;
	// middle
	VIDEO[240].ascii = 179;
	VIDEO[240].attribute = 0x2E;
	VIDEO[241].ascii = '<';
	VIDEO[241].attribute = 0x4E;
	VIDEO[242].ascii = '>';
	VIDEO[242].attribute = 0x4E;
	VIDEO[243].ascii = 179;
	VIDEO[243].attribute = 0x2E;
	// bottom
	VIDEO[320].ascii = 192;
	VIDEO[320].attribute = 0x2E;
	VIDEO[321].ascii = 0xc4;
	VIDEO[321].attribute = 0x2E;
	VIDEO[322].ascii = 0xc4;
	VIDEO[322].attribute = 0x2E;
	VIDEO[323].ascii = 217;
	VIDEO[323].attribute = 0x2E;

	VIDEO[(80 * 25) - 1].ascii = '+';
	VIDEO[(80 * 24)].ascii = '+';

	SYSTEM.cursor[0].col = 0;
	SYSTEM.cursor[0].row = 5;

	v_put("AC");
	v_putn("ID");
	v_printf("TES%c\n", 'T');

	screen_logo; // print logo

	v_putn("** END **");

	screen_draw; // draw on screen

	SetPos(0, 26); // puts test result messages at the end
}