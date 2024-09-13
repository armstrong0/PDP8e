
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
FILE *infile;
char *pathname;

void
usage (void)
{
  fprintf (stderr, "Usage:  [-1 | -2 | -3 ] file\n");
  fprintf (stderr, " converts hex files saved by the $writememh function\n");
  fprintf (stderr, "of iverilog into octal values \n");
  fprintf (stderr, "    -3 converts 3 hex values into 2 octal values\n");
  fprintf (stderr, "       this is useful to decode dumprk05 data.\n");
  fprintf (stderr, "       output format is the same as od -o\n");
  fprintf (stderr, "    -1 outputs a single values per line, address data\n");

  fprintf (stderr, "    -2 a hex values and outputs an octal value\n");
  fprintf (stderr, "        output is the same as od -o\n");
}



int
main (int argc, char *argv[])
{
  FILE *stream;
  char *line = NULL;
  char *linep = line;
  char key;
  int addr, word_cnt,state = 0;
  int c;
  int format = 3;

  size_t len = 0;
  ssize_t nread;
  long ac, ts, temp1, temp2;

  if (argc != 3)
    {
      usage ();
      exit (EXIT_FAILURE);
    }
  c = getopt (argc, argv, "123h");
  switch (c)
    {
    case '1':
      format = 1;
      break;
    case '2':
      format = 2;
      break;
    case '3':
      format = 3;
      break;
    case 'h':
      usage ();
      break;
    default:
      usage;
    }
  stream = fopen (argv[2], "r");
  if (stream == NULL)
    {
      perror ("fopen");
      exit (EXIT_FAILURE);
    }
  addr = 0;
  word_cnt = -1;
  while ((nread = getline (&line, &len, stream)) != -1)
    {

      linep = line + 1;
      if (line[0] != '/')
	{
	  ac = strtol (line, NULL, 16);
	  switch (format)
	    {
	    case 1:
	      printf ("%07o %04lo\n", addr++, ac);
	      break;
	    case 2:
	      if ((addr % 8) == 0)
		{
		  printf ("%07o", addr * 2);
		}
	      printf (" %06lo", ac);
	      addr++;
	      if ((addr % 8) == 0)
		printf ("\n");
	      break;

	    case 3:
	      switch (state)
		{
		case 0:
		  if (ac != 0xff) 
          {
          fprintf(stderr,"start of sector incorrect\n");
          exit (-1);
          }
		  state = 1;
		  break;
		case 1:
		  if ((addr % 8) == 0)
          {
		    printf ("%07o", 2 * addr);
          }
		  temp1 = ac & 0xff;
		  state = 2;
		  break;
		case 2:
		  temp1 = temp1 | (ac & 0xf) << 8;
		  printf (" %06lo", temp1);
		  temp2 = (ac & 0xf0) >> 4;
		  addr++;
		  state = 3;
		  break;
		case 3:
		  temp2 = (temp2 | (ac << 4)) & 0xfff;
		  printf (" %06lo", temp2);
		  addr++;
          if ((addr %256) == 0)
          {printf("\n");
          state = 0;
          }
		  else if ((addr % 8) == 0)
          {
		    printf ("\n");
            state = 1;
          }
          else state = 1;
		  
		  break;

		default:
		  break;
		}
	      break;
	    }

	}
    }

  printf ("\n");
}
