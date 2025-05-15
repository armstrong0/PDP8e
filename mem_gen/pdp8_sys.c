/* pdp8_sys.c: PDP-8 simulator interface

   Copyright (c) 1993-2011, Robert M Supnik

   Permission is hereby granted, free of charge, to any person obtaining a
   copy of this software and associated documentation files (the "Software"),
   to deal in the Software without restriction, including without limitation
   the rights to use, copy, modify, merge, publish, distribute, sublicense,
   and/or sell copies of the Software, and to permit persons to whom the
   Software is furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
   ROBERT M SUPNIK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
   IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

   Except as contained in this notice, the name of Robert M Supnik shall not be
   used in advertising or otherwise to promote the sale, use or other dealings
   in this Software without prior written authorization from Robert M Supnik.

   22 Aug-13    DBA     Imported from SIMH, removed everything but the loaders
                        changed the includes
   24-Mar-09    RMS     Added link to FPP
   24-Jun-08    RMS     Fixed bug in new rim loader (Don North)
   24-May-08    RMS     Fixed signed/unsigned declaration inconsistency
   03-Sep-07    RMS     Added FPP8 support
                        Rewrote rim and binary loaders
   15-Dec-06    RMS     Added TA8E support, IOT disambiguation
   30-Oct-06    RMS     Added infinite loop stop
   18-Oct-06    RMS     Re-ordered device list
   17-Oct-03    RMS     Added TSC8-75, TD8E support, DECtape off reel message
   25-Apr-03    RMS     Revised for extended file support
   30-Dec-01    RMS     Revised for new TTX
   26-Nov-01    RMS     Added RL8A support
   17-Sep-01    RMS     Removed multiconsole support
   16-Sep-01    RMS     Added TSS/8 packed char support, added KL8A support
   27-May-01    RMS     Added multiconsole support
   18-Mar-01    RMS     Added DF32 support
   14-Mar-01    RMS     Added extension detection of RIM binary tapes
   15-Feb-01    RMS     Added DECtape support
   30-Oct-00    RMS     Added support for examine to file
   27-Oct-98    RMS     V2.4 load interface
   10-Apr-98    RMS     Added RIM loader support
   17-Feb-97    RMS     Fixed bug in handling of bin loader fields
*/

#include <stdio.h>
#include <inttypes.h>
#include <ctype.h>
extern uint16_t core[];

#define OK 0
#define FMT (OK+1)
#define CSUM (OK+2)             /* loader checksum */
#define NXM (OK+3)
#define IERR (OK+4)             /* internal error */
#define ARG (OK+5)              /* argument error */

#define MEMSIZE 32768

/* RIM loader format consists of alternating pairs of addresses and 12-bit
   words.  It can only operate in field 0 and is not checksummed.
*/
int
sim_load_rim (FILE *fi)
{
    int32_t origin, hi, lo, wd;
    origin = 0200;

    do
    {                           /* skip leader */
        if ((hi = getc (fi)) == EOF)
            return FMT;
    }
    while ((hi == 0) || (hi >= 0200));

    do
    {                           /* data block */
        if ((lo = getc (fi)) == EOF)
            return FMT;
        wd = (hi << 6) | lo;
        if (wd > 07777)
            origin = wd & 07777;

        else
            core[origin++ & 07777] = wd;
        if ((hi = getc (fi)) == EOF)
            return FMT;
    }
    while (hi < 0200);          /* until trailer */
    return OK;
}


/* BIN loader format consists of a string of 12-bit words (made up from
   7-bit characters) between leader and trailer (200).  The last word on
   tape is the checksum.  A word with the "link" bit set is a new origin;
   a character > 0200 indicates a change of field.
*/
int32_t
sim_bin_getc (FILE *fi, uint32_t *newf)
{
    int32_t c, rubout;
    rubout = 0;                 /* clear toggle */
    while ((c = getc (fi)) != EOF)
    {                           /* read char */
        if (rubout)             /* toggle set? */
            rubout = 0;         /* clr, skip */

        else if (c == 0377)     /* rubout? */
            rubout = 1;         /* set, skip */

        else if (c > 0200)      /* channel 8 set? */

        {
            *newf = (c & 070) << 9;     /* change field */
            fprintf (stderr, "Newfield %o\n", *newf);
        }

        else
            return c;           /* otherwise ok */
    }
    return EOF;
}

int
sim_load_bin (FILE *fi)
{
    int32_t hi, lo, wd, csum, t;
    uint32_t field, newf, origin;

    do
    {                           /* skip leader */
        if ((hi = sim_bin_getc (fi, &newf)) == EOF)
            return FMT;
    }
    while ((hi == 0) || (hi >= 0200));
    csum = origin = field = newf = 0;   /* init */
    for (;;)
    {                           /* data blocks */
        if ((lo = sim_bin_getc (fi, &newf)) == EOF)     /* low char */
            return FMT;
        wd = (hi << 6) | lo;    /* form word */
        t = hi;                 /* save for csum */
        if ((hi = sim_bin_getc (fi, &newf)) == EOF)     /* next char */
            return FMT;
        if (hi == 0200)
        {                       /* end of tape? */
            if ((csum - wd) & 07777)    /* valid csum? */
                return CSUM;
            return OK;
        }
        csum = csum + t + lo;   /* add to csum */
        if (wd > 07777)         /* chan 7 set? */
            origin = wd & 07777;        /* new origin */

        else
        {                       /* no, data */
            if ((field | origin) >= MEMSIZE)
                return NXM;
            core[field | origin] = wd;
            origin = (origin + 1) & 07777;
        }
        field = newf;           /* update field */
    }
    return IERR;
}


/* Binary loader
   Two loader formats are supported: RIM loader (-r) and BIN (-b) loader. */
#if 0
int
sim_load (FILE *fileref, char *cptr, char *fnam, int flag)
{
    if ((*cptr != 0) || (flag != 0))
        return ARG;
    if ((sim_switches & SWMASK ('R')) ||        /* RIM format? */
        (match_ext (fnam, "RIM") && !(sim_switches & SWMASK ('B'))))
        return sim_load_rim (fileref);

    else
        return sim_load_bin (fileref);  /* no, BIN */
}


#endif /*  */
