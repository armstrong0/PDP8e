/****************************************************************
 *
 *  	RIM Client, Version 0.4
 * 	Pete Turnbull, December 2001
 *  	<pete@dunnington.u-net.com>
 *
 *  	This is a utility to transmit a file in RIM or BIN format
 *  	to a PDP-8.  The PDP-8 must be running the "slow-speed"
 *  	RIM (Read-In Mode) Loader or BIN Loader before starting
 *  	this program.
 *
 *  	Modelled after Kevin McQuiggin's sender, updated for IRIX,
 *  	and with some extra features:
 *
 *  	-- delay between characters is machine-independant
 *  	-- optionally strips headers (spurious ASCII preceeding a
 *  	   block of octal 200 leader code), as may be desirable
 *  	   for papertape files (often with .pt extension)
 *  	-- shows progress; either as percentage, as octal codes
 *  	   sent, or by rotating spinner
 *  	-- speed and port are user-settable from command line
 *  	   (default is 1200 baud on /dev/ttyd1)
 *  	-- can be used in a pipe (eg as "cat file | send")
 *  	-- uses environment variables SENDSPEED and SENDPORT to
 *  	   set initial values
 *
 ****************************************************************/

/* The following #define allows us to use this code on older systems 
   such as IRIX 5.x as well as later POSIX ones such as IRIX 6.5.x
   but it must precede the #include <termios.h>                     */

#define    	_OLD_TERMIOS
#define     	VERSION_MAJ     	0
#define     	VERSION_MIN     	4

#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/time.h>
#include <termios.h>
#include <unistd.h>
#include <sys/stat.h>


char    *progname;


void delay(int centisecs) {
#if defined _MIPS_ISA
    float     ticks; /* system clock ticks per second */
    
    ticks = sysconf(_SC_CLK_TCK)/100 * centisecs;
    sginap((int)ticks);
#else
    if (centisecs >= 100) sleep(centisecs/100);
    usleep((centisecs%100)*10000); 
#endif
}



void usage(void) {
    fprintf(stderr, 
    	    "Usage: %s [-v | -p] [-s speed] [-d delay] [-l line] file\n",
	    progname);
    fprintf(stderr, "    -v means verbose (show characters being sent)\n");
    fprintf(stderr, "    -p means show percentage sent\n");
    fprintf(stderr, "    -x means strip any extra header\n");
    fprintf(stderr, "    speed can be 50, 75, 110, 134.5, 150, 300, 600, 1200, 2400\n");
    fprintf(stderr, "    4800, 9600, 38400\n");
    fprintf(stderr, "    delay is centiseconds between characters\n");
    fprintf(stderr, "    if no file is given then standard input is used\n");
}



int setspeed(char *speedval) {

    if (strcmp(speedval, "50") == 0) return B50;
    else if (strcmp(speedval, "75") == 0) return B75;
    else if (strcmp(speedval, "110") == 0) return B110;
    else if (strncmp(speedval, "134", 3) == 0) return B134;
    else if (strcmp(speedval, "135") == 0) return B134;
    else if (strcmp(speedval, "150") == 0) return B150;
    else if (strcmp(speedval, "300") == 0) return B300;
    else if (strcmp(speedval, "600") == 0) return B600;
    else if (strcmp(speedval, "1200") == 0) return B1200;
    else if (strcmp(speedval, "2400") == 0) return B2400;
    else if (strcmp(speedval, "4800") == 0) return B4800;
    else if (strcmp(speedval, "9600") == 0) return B9600;
    else if (strcmp(speedval, "38400") == 0) return B38400;
    else {
    	fprintf(stderr, "%s: unrecognised speed\n", progname);
    	fprintf(stderr, "Must be one of 50, 75, 110, 134.5, 150, 300, 600, 1200, 2400.\n");
    	fprintf(stderr, "4800, 9600, 38400.\n");
	return 0;
    }
}

void main(int argc, char **argv) {

    int    	 c, port_fd, speed, sp, icdelay;
    int      	 verbose, percent, strip;
    char    	 byte;
    long    	 counter;
    off_t   	 filesize;
    char         s_port[255];
    char        *varptr;
    FILE    	*rimfile;
    char    	 messge[255];
    char    	 spinner[] = "-\\|/-";
    struct  termios settings;
    struct  stat    fileinfo;
    extern char *optarg;
    extern int   optind, opterr, optopt;
    
    progname = argv[0];
    printf("PDP-8 Loader, Version %d.%d\n", VERSION_MAJ, VERSION_MIN);

    /*** DEFAULT VALUES ***/
    sprintf(s_port, "/dev/ttyUSB0");
    icdelay = 4;
    speed   = B1200;
    verbose = percent = strip = 0;

    /* ENVIRONMENT VARIABLES */
    if ((varptr = getenv("SENDSPEED")) != NULL &&
    	(sp = setspeed(varptr)) != 0)
	    speed = sp;
    if ((varptr = getenv("SENDPORT")) != NULL) {
	strncpy(s_port, varptr, 253);
	s_port[254] = 0;
    }

    while ((c = getopt(argc, argv, "pvxs:d:l:h")) != EOF) {
	switch(c) {
 	case 'v':
	    verbose = 1;
	    percent = 0;
	    break;
 	case 'p':
	    verbose = 0;
	    percent = 1;
	    break;
 	case 'x':
	    strip = 1;
	    break;
 	case 's':
	    if ((sp = setspeed(optarg)) != 0) speed = sp;
	    break;
 	case 'd':
	    icdelay = atoi(optarg);
	    break;
	case 'l':
	    strncpy(s_port, optarg, 253);
	    s_port[254] = 0;
	    break;
	case '?':
	case 'h':
	    usage();
	    exit(0);
	}
    }
    
    /* allow this to act as a filter in a pipe */
    if (optind >= argc) {    /* no filename given */
/* 	usage();
 *   	exit(3);
 *  }
 *  if (strcmp(argv[optind], "-") == 0) {
 */    	percent = 0;
    	rimfile = stdin;
    }
    else if ((rimfile = fopen(argv[optind], "r")) == NULL) {
    	    perror(argv[optind]);
	    exit(1);
    }

    if (percent) {
	if (stat(argv[optind], &fileinfo) == 0)
	    filesize = fileinfo.st_size;
    	else percent = 0;
    }



    if((port_fd = open(s_port, O_WRONLY | O_NOCTTY | O_SYNC /* | O_NDELAY */)) < 0) {
    	sprintf(messge, "%s: Unable to open %s", argv[0], s_port);
	perror(messge);
	exit(1);
    }

    /* flush any old data in buffers */
    if (tcflush(port_fd, TCOFLUSH) != 0)
    	perror("Didn't flush old data");

    if(tcgetattr(port_fd, &settings) < 0) {
    	sprintf(messge, "%s: failed to read port settings", argv[0]);
	perror(messge);
	exit(1);
    }

    if (cfsetospeed(&settings, speed) != 0 ) {
    	sprintf(messge, "%s: failed to set output baud rate", argv[0]);
	perror(messge);
	exit(1);
    }
    if (cfsetispeed(&settings, speed) != 0) {
    	sprintf(messge, "%s: failed to set input baud rate", argv[0]);
	perror(messge);
	exit(1);
    }
    
    /* this line is to prevent echo feedback on loopback tests :-) */
    settings.c_lflag &= ~(ICANON | ECHO);

    settings.c_cflag &= ~CSIZE;	    	/* mask out char size */
    settings.c_cflag |=  CS8;	    	/* make 8-bit */
    settings.c_cflag &= ~PARENB;    	/* no parity */
    if (speed == B110 || speed == B75 || speed == B50)
    	settings.c_cflag |= CSTOPB;    	/* 2 stop bits */
    else
    	settings.c_cflag &= ~CSTOPB;    /* only 1 stop bit */

#ifdef CNEW_RTSCTS
    settings.c_cflag &= ~CNEW_RTSCTS;	/* make sure no hardware handshake */
#endif

    settings.c_oflag &= ~OPOST;     	/* raw output, no meddling */
    
    if(tcsetattr(port_fd, TCSANOW, &settings) != 0) {
    	sprintf(messge, "%s: failed to set 8N1 raw", argv[0]);
	perror(messge);
	exit(1);
    }

    /* OK, so get on with it! */
    fprintf(stderr, "Sending...  ");
    if (verbose) fprintf(stderr, "\n");
    if (percent) fprintf(stderr, "    ");
    counter = 0;

    if (strip) {
    	while ((c = getc(rimfile)) != EOF && c<128)
	    counter += 1;
    }

    while ((c = getc(rimfile)) != EOF) {
    	byte = (char)c;
	if (write(port_fd, &byte, 1) != 1) {
    	    sprintf(messge, "%s: could not write to serial port", argv[0]);
	    perror(messge);
	    exit(1);
	}
    	if (verbose) fprintf(stderr, "%03o ", (unsigned char)c);
    	counter += 1;
    	if (counter%8 == 0) {
	    if (percent)
	    	fprintf(stderr, "%c%c%c%c%c%i%% ", 8,8,8,8,8,(int) (100 * counter) / (int) filesize);
    	    else if (verbose) fprintf(stderr, "\n");
	    else fprintf(stderr, "%c%c", 8, spinner[counter%32/8]);
	}
    	tcdrain(port_fd); /* wait for char to get to the serial hardware */
	delay(icdelay);
    }

    if (verbose) fprintf(stderr, "\n");
    else if (percent) fprintf(stderr, "%c%c%c%c%c", 8,8,8,8,8);
    else fprintf(stderr, "%c ", 8);

    fprintf(stderr, "Done.  %li characters sent.  ", counter);
    close(port_fd);
    fprintf(stderr, "Closed %s\n", s_port);
}


