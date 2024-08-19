
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
FILE *infile;
char *pathname;


int
main (int argc, char *argv[])
{
  FILE *stream;
  char *line = NULL;
  char *linep = line;
  char key;
  int addr, word_cnt;

  size_t len = 0;
  ssize_t nread;
  long ac, ts, temp1, temp2;

  if (argc != 2)
    {
      fprintf (stderr, "Usage: %s <file>\n", argv[0]);
      exit (EXIT_FAILURE);
    }

  stream = fopen (argv[1], "r");
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
	  switch (word_cnt)
	    {
	    case -1:
	      printf ("Start ac = %3lo\n", ac);
	      word_cnt++;
	      break;
	    case 0:
	      if ((addr % 8) == 0)
		printf ("\n%06o ", addr);
	      temp1 = ac & 0xff;
	      word_cnt++;
	      break;
	    case 1:
	      temp1 = temp1 | (ac & 0xf) << 8;
	      printf ("%06lo ", temp1);
	      temp2 = (ac & 0xf0) >> 4;
	      addr++;
	      word_cnt++;
	      break;
	    case 2:
	      temp2 = (temp2 | (ac << 4)) & 0xfff;
	      printf ("%06lo ", temp2);
	      addr++;
	      word_cnt = 0;
	      break;

	    default:
	      break;
	    }

	}

    }

}
