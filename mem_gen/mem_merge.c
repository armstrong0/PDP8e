/*  This program takes two 4096 element hex files and merges them.  It will 
 *  report collisions (both input files have a non-zero element at the same
 *  location.)  It takes three command line arguements, two inout hex files and
 *  the name of the output file.
 */

/* The following #define allows us to use this code on older systems 
   such as IRIX 5.x as well as later POSIX ones such as IRIX 6.5.x
   but it must precede the #include <termios.h>                     */

#define    	_OLD_TERMIOS
#define     	VERSION_MAJ     	1
#define     	VERSION_MIN             0

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
#define VERSION_MAJ 1
#define VERSION_MIN 0


void
usage (void)
{
    fprintf (stderr, "Usage: %s infile1, infile2, outfile\n", progname);
    printf ("PDP-8 hex file merger, used to take two non-conflicting hex\n");
    printf
        ("files, and produce an composite hex file to be used for memory\n");
    printf ("initialization\n", "%d.%d\n\n", VERSION_MAJ, VERSION_MIN);

}

//int16_t in1[4096];
//int16_t in2[4096];

int
main (int argc, char **argv)
{

    int c;
    char byte;
    long counter;
    off_t filesize;
    char s_port[255];
    FILE *in1_file;
    FILE *in2_file;
    FILE *out_file;
    char messge[255];
    extern char *optarg;
    extern int optind, opterr, optopt;
    unsigned int out[4096];
    unsigned int tmp;
    memset (&out, 0x00, sizeof (u_int16_t) * 4096);

    progname = argv[0];

    if ((in1_file = fopen (argv[optind], "r")) == NULL)
    {
        perror (argv[optind]);
        exit (1);
    }
    optind++;

    if ((in2_file = fopen (argv[optind], "r")) == NULL)
    {
        perror (argv[optind]);
        exit (1);
    }

    optind++;

    if ((out_file = fopen (argv[optind], "w")) == NULL)
    {
        perror (argv[optind]);
        exit (1);
    }
    // read input file into out
    for (int k = 0; k < 4096; k = k + 1)
    {
        fscanf (in1_file, "%x", &out[k]);
    };
    for (int k = 0; k < 4096; k = k + 1)
    {
        fscanf (in2_file, "%x", &tmp);
	if (out[k] == 0 )
	   out[k] = tmp;
	else if (tmp != 0)
	{
	   fprintf(stderr,"Collision at address: %d \n",k);
	   exit(-1);
	}
		
    };


    for (int k = 0; k < 4096; k = k + 1)
    {
        fprintf (out_file, "%03x", out[k]);
        if ((k % 8) != 7)
            fprintf (out_file, " ");
        else
        {
            fprintf (out_file, "\n");
        };
    };
};
