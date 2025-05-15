/****************************************************************
 *
 *  	RIM Client, Version 0.3
 * 	Pete Turnbull, December 2001
 *  	<pete@dunnington.u-net.com>
 *
 *  	This is a utility to transmit a file in RIM or BIN format
 *  	to a PDP-8.  The PDP-8 must be running the "slow-speed"
 *  	RIM (Read-In Mode) Loader before starting this program.
 *
 *  	Modelled after Kevin McQuiggin's sender, updated for IRIX,
 *  	and with some extra features:
 *
 *  	-- delay between characters is machine-independant
 *  	-- optionally strips headers (spurious ASCII preceeding a
 *  	   block of octal 200 leader code), as may be desirable
 *  	   for papertape files (often with .pt extension)
 *
 ****************************************************************/

/* The following #define allows us to use this code on older systems 
   such as IRIX 5.x as well as later POSIX ones such as IRIX 6.5.x
   but it must precede the #include <termios.h>                     */

#define    	_OLD_TERMIOS
#define     	VERSION_MAJ     	0
#define     	VERSION_MIN     	3

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


char *progname;


void
usage (void)
{
    fprintf (stderr, "Usage: %s file file\n", progname);
    fprintf (stderr, "    if no file is given then standard input is used\n");
    fprintf (stderr,
             "    if no second file is given then standard output is used\n");
}

extern int sim_load_rim (FILE *);

int16_t core[4096];
void
main (int argc, char **argv)
{

    int c;
    char byte;
    long counter;
    off_t filesize;
    char s_port[255];
    char rimname[255];
    FILE *rimfile;
    FILE *verilogfile;
    char messge[255];
    extern char *optarg;
    extern int optind, opterr, optopt;

    memset (&core, 0x00, sizeof (int16_t) * 4096);

    progname = argv[0];
    printf ("PDP-8 RIM Loader - Verilog memory intializer, Version %d.%d\n",
            VERSION_MAJ, VERSION_MIN);


    while ((c = getopt (argc, argv, "vxh?")) != EOF)
    {
        switch (c)
        {
        case '?':
        case 'h':
            usage ();
            exit (0);
        }
    }

    /* allow this to act as a filter in a pipe */
    if (optind >= argc)
    {                           /* no filename given */
        rimfile = stdin;
        strcpy (rimname, "stdin");
        verilogfile = stdout;
    }
    else if ((rimfile = fopen (argv[optind], "r")) == NULL)
    {
        perror (argv[optind]);
        exit (1);
    }
    else
        strcpy (rimname, argv[optind]);


    optind++;

    if (optind >= argc)
    {                           /* no filename given */
        verilogfile = stdout;
    }
    else if ((verilogfile = fopen (argv[optind], "w")) == NULL)
    {
        perror (argv[optind]);
        exit (1);
    }

    /* OK, so get on with it! */
    fprintf (stderr, "Processing...  ");
    counter = 0;

    sim_load_rim (rimfile);


    for (int k = 0; k < 4096; k = k + 1)
    {
        fprintf (verilogfile, "%03x", core[k]);
        if ((k % 8) != 7)
            fprintf (verilogfile, " ");
        else
        {
            fprintf (verilogfile, "\n");
        };


    }

    fclose (rimfile);
    fclose (verilogfile);
}
