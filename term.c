#include <stdbool.h>
#include <stdio.h>
#include <termios.h>


struct termios orig_tio;

void init_term(void) {
	setvbuf(stdin, NULL, _IONBF, 0);
	setvbuf(stdout, NULL, _IONBF, 0);
        struct termios tio;
        tcgetattr(fileno(stdin), &tio);
	orig_tio = tio;
	cfmakeraw(&tio);
        tcsetattr(fileno(stdin), TCSANOW, &tio);
	printf("\e[H\e[J\e[29r\e[29;1H\e[s");
}

void fini_term(void) {
        tcsetattr(fileno(stdin), TCSANOW, &orig_tio);
	printf("\e[0m\e[1r\e[u");
}


int int_to_chars(int d, int * res) {
	if (d == 0)
		return 0;
	if (d < 0)
		d += 19683;
	int pos = 0;
	if (d < 0x80) {
		res[pos++] = d;
		return 1;
	} else if (d < 0x800) {
		res[pos++] = 0xc0 | d >> 6;
		res[pos++] = 0x80 | d & 0x3f;
		return 2;
	} else {
		res[pos++] = 0xe0 | d >> 12;
		res[pos++] = 0x80 | d >> 6 & 0x3f;
		res[pos++] = 0x80 | d & 0x3f;
		return 3;
	}
}


void hypercall_log(const char * buffer, int level) {
	static const char * const loglevels[] = {
		"\e[0;34m[DEBUG]",
		"\e[0m[INFO]",
		"\e[0;33m[WARNING]",
		"\e[0;31m[ERROR]",
		"\e[0;31;1m[FATAL]",
	};
	printf("\e[u%s %s\e[0m\r\n\e[s", loglevels[1 + level], buffer);
}


void termcall_beep(void) {
	printf("\a");
}

void termcall_putc(int x, int y, int c, int fg, int bg, int bold) {
	x += 40;
	y += 13;
	if (x < 0 || x > 80)
		return;
	if (y < 0 || y > 27)
		return;
	x++;
	y++;
	printf("\e[%d;%dH", y, x);
	printf("\e[0m");
	if (bold)
		printf("\e[1m");
	static const char *const fgs[] = {
		"\e[30m",
		"\e[31m",
		"\e[32m",
		"\e[33m",
		"",
		"\e[34m",
		"\e[35m",
		"\e[36m",
		"\e[37m",
	};
	static const char *const bgs[] = {
		"\e[40m",
		"\e[41m",
		"\e[42m",
		"\e[43m",
		"",
		"\e[44m",
		"\e[45m",
		"\e[46m",
		"\e[47m",
	};
	if (fg)
		printf(fgs[4+fg]);
	if (bg)
		printf(bgs[4+bg]);
	if (c < 0)
		c += 9841;
	if (c < 0x80)
		putchar(c);
	else if (c < 0x800) {
		putchar(0xc0 | c >> 6);
		putchar(0x80 | c & 0x3f);
	} else {
		putchar(0xe0 | c >> 12);
		putchar(0x80 | c >> 6 & 0x3f);
		putchar(0x80 | c & 0x3f);
	}
}

int termcall_getc(int x, int y) {
	x += 40;
	y += 13;
	if (x >= 0 && x < 81 && y >= 0 && y < 28) {
		x++;
		y++;
		printf("\e[%d;%dH", y, x);
	} else {
		printf("\e[u");
	}
	int res;
	while (1) {
		int c = getchar();
		if (c == EOF) {
			return -1;
		}
		if (c < 0x80) {
			res = c;
			break;
		} else if ((c & 0xe0) == 0xc0) {
			int x1 = getchar();
			if ((x1 & 0xc0) != 0x80) {
				printf("\a");
				continue;
			}
			res = (c & 0x1f) << 6 | (x1 & 0x3f);
			break;
		} else if ((c & 0xf0) == 0xe0) {
			int x1 = getchar();
			if ((x1 & 0xc0) != 0x80) {
				printf("\a");
				continue;
			}
			int x2 = getchar();
			if ((x2 & 0xc0) != 0x80) {
				printf("\a");
				continue;
			}
			res = (c & 0xf) << 12 | (x1 & 0x3f) << 6 | (x2 & 0x3f);
			break;
		} else {
			printf("\a");
			continue;
		}
	}
	return res % 19683;
}
