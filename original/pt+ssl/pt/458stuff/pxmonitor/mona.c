/* PX VAX Runtime Monitor (Part A)  Ver. 1.02,
   after PT PDP-11 Runtime Monitor  Ver. 1.01

   Author:  J.A. Rosselet, University of Toronto
	    VAX conversion by J.R. Cordy, Queen's University at Kingston

   Date 30 Jun 1980
	 (Updated 12 Feb 1981)
	 (VAX conversion 30 Aug 1985)
	 (PX extension 27 Nov 1985)
*/

#include <stdio.h>

#define SYSERR	 (-1)

#define BLANK ' '
#define ERROR -1
#define BYTE 1
#define WORD 4
#define SHIFTLEFT8 256
#define MAXFILES 15
#define READ 1
#define WRITE 2
#define	EOS '\0'

/* error codes */
#define PROGARG 0
#define PROGOPEN 1
#define PROGERR 2
#define ARGCOUNT 3
#define PROGSIZE 4
#define RESET 5
#define REWRITE 6
#define FILEEOF 7
#define NORESET 8
#define NOREWRITE 9
#define NONINT 10

/* global variables */
char **argument;
int   errcond, argcount;
struct fileDescs {
		   int mode;
		   FILE *fileFile;
		 }; 
struct fileDescs fileDescs[MAXFILES] = {
	READ,	stdin,
	WRITE,	stdout,
	};

main (argc, argv)
    register int  argc;
    register char *argv[];
    {
	/* make arguments global */
	argcount = argc += 1;	/* -1 for progname, +2 for stdin/out */
	argv -= 2;
	argument = argv;	/* so names correspond to fileDescs */
	errcond = 0;
	DispatchUser ();
    }

char * NameFile (fileOffset)
    int  fileOffset;
    {
	if (fileOffset == 1)
	    return ("input");
	else if (fileOffset == 2)
	    return ("output");
	else if (argcount >= fileOffset)
	    return (argument[fileOffset]);
	else
	    return ("<no file>");
    }

Error (errcode, fileOffset)
    int  errcode;
    int  fileOffset;

    {
	static char *errMessages[] =	{
		"no program name argument\n",
		"can't open program file %s\n",
		"error in program file %s\n",
		"wrong number of arguments\n",
		"program too large\n",
		"can't reset file %s\n",
		"can't rewrite file %s\n",
		"read past EOF on file %s\n",
		"read before reset of file %s\n",
		"write before rewrite of file %s\n",
		"integer read failed on file %s\n"
		};
	fprintf (stderr, errMessages[errcode], NameFile (fileOffset));
	errcond = ERROR;
	PTHalt ();
    }

PTSubscrErr (lineNum, arrayIndex, lowerBound, upperBound)
    int  lineNum, arrayIndex, upperBound, lowerBound;
    {
	fprintf (stderr, "line %d: subscript [%d] out of bounds [%d .. %d]\n",
		lineNum, arrayIndex, lowerBound, upperBound);
	errcond = ERROR;
	PTHalt ();
    }

PTCaseAbort (lineNum)
    int  lineNum;
    {
	fprintf (stderr, "line %d: case selector does not match a label\n",
		lineNum);
	errcond = ERROR;
	PTHalt ();
    }

FILE * OpenTest (fileOffset, mode)
    register int fileOffset, mode;	/* mode is one of READ, WRITE */

    {
	register struct fileDescs *fD;
	fD = &fileDescs[fileOffset-1];
	if (fD->mode != mode)
	    Error ( mode==READ ? NORESET : NOREWRITE, fileOffset);
	return (fD->fileFile);
    }

PTHalt ()
    {
	exit (errcond);
    }

PTWriteString (fileOffset, fieldWidth, stringDescriptor)
    register char  *stringDescriptor;
    int   fieldWidth, fileOffset;

    {
	struct cheat { int oops[1]; };

	PutStr (OpenTest (fileOffset, WRITE),  
		((struct cheat *) stringDescriptor) -> oops[-1],
		stringDescriptor, fieldWidth);
   }

PutStr (f, length, str, width)
	register FILE *f;
	int length, width;
	register char *str;
    {
	register int n;

	if ( (n=width-length) > 0) do putc (' ', f); while (--n);
	if ( (n=length) > 0) do fputc (*str++, f); while (--n);
    }

PTReset (fileOffset)
    int fileOffset;
    {
	Open (fileOffset, READ);
    }

PTRewrite (fileOffset)
    int  fileOffset;
    {
	Open (fileOffset, WRITE);
    }

Open (fileOffset, mode)
    int  fileOffset;
    register int mode;
    {
	register struct fileDescs *fD;

	if (fileOffset > argcount)
		Error (mode==READ?RESET:REWRITE, fileOffset);
	fD = &fileDescs[fileOffset-1];
	if (fD->fileFile != NULL)
		fclose (fD->fileFile);
	fD->fileFile = fopen (argument[fileOffset], mode==READ?"r":"w");
	if (fD->fileFile == NULL)
		Error (mode==READ?RESET:REWRITE, fileOffset);
	fD->mode = mode;
    }

PTWrite (fileOffset, valueLength, value)
    int  fileOffset, valueLength;
	register int value;
    {
	register FILE *f;

	f = OpenTest (fileOffset, WRITE);
	if (valueLength == WORD)
	    putw (value, f);
	else
	    putc (value, f);
    }

PTWriteln (fileOffset)
    int  fileOffset;
    {
	PTWriteChar (fileOffset, 1, '\n');
    }

PTRead (fileOffset, valueLength, valueRef)
    register int  fileOffset, valueLength;
    register char *valueRef;
    {
	register FILE *f;
	struct cheat { int intg; };

	f = OpenTest (fileOffset, READ);
	if (valueLength == WORD)
	    ((struct cheat *) valueRef) -> intg = getw (f);
	else
	    *valueRef = getc (f);
	if (feof (f))
	    Error (FILEEOF, fileOffset);
    }

PTReadln (fileOffset)
    int  fileOffset;
    {
	register  FILE *f;
	register  int letter;

	f = OpenTest (fileOffset, READ);
	do
	    {
		if ( (letter = getc (f)) == EOF)
		    Error (FILEEOF, fileOffset);
	    }
	while (letter != '\n');
    }

PTWriteInteger (fileOffset, fieldWidth, value)
    int  fileOffset, fieldWidth, value;
    {
	PutInt (OpenTest (fileOffset, WRITE), value, fieldWidth);
    }

PutInt (f, value, width)
	FILE *f;
	int value, width;
    {
	static char intBuf[6];
	register char *cp;
	register int myvalue;

	cp = &intBuf[6];
	/*
	 * We manipulate a negative number so that -32768
	 * doesn't need special help.  This depends on
	 * (n % m) <= 0 for n<0, m>0.
	 */
	if ( (myvalue=value) > 0)	myvalue = -myvalue;
	do	{
		*--cp = '0' - myvalue%10;
		myvalue /= 10;
		}
	while (myvalue != 0);
	if (value < 0)	*--cp = '-';
	PutStr (f, &intBuf[6]-cp, cp, width);
    }

PTWriteChar (fileOffset, fieldWidth, charVal)
    int  fileOffset, fieldWidth;
    char charVal;
    {
	/* Make a pretend stringDescriptor */
	static struct	{
		int cLen;
		char cBuf[1];
		} iC =
	    { 1, "" };
	iC.cBuf[0] = charVal;
	PTWriteString (fileOffset, fieldWidth, &iC.cBuf[0]);
    }

PTReadInteger (fileOffset, intRef)
    int  fileOffset, *intRef;
    {
	int  sign;
	register int letter;
	register int value;
	register FILE *f;

	f = OpenTest (fileOffset, READ);
	value = 0;
	sign = 0;
	/* skip noise */
	do
	    {
		letter = getc (f);
		if (letter == EOF)
		    Error (FILEEOF, fileOffset);
	    }
	while (letter == BLANK || letter == '\n');

	/* handle sign */
	switch (letter) {
		case '-':	sign--;
				/* Fall through */
		case '+':	letter = getc (f);
				break;
		}

	/* scan ( >= 1 ) integer digits */
	if (letter < '0' || letter > '9')
		 Error (NONINT, fileOffset);
	do
		{
		value *= 10;
		letter -= '0';
		value -= letter;
		letter = getc (f);
		}
	while (letter >= '0' && letter <= '9');

	/* return non-integer character to input */
	if (letter != EOF)
	    ungetc (letter, f);

	if (sign == 0)
	    value = -value;
	*intRef = value;
    }

PTReadChar (fileOffset, charRef)
    int  fileOffset;
    char *charRef;
    {
	register int  letter;
	register struct fileDescs  *fD;

	fD = &fileDescs[fileOffset-1];
	if (fD->mode == READ)
	    {
		letter = getc (fD->fileFile);
		if (letter == '\n')
		    *charRef = BLANK;
		else if (letter == EOF)
		    Error (FILEEOF, fileOffset);
		else
		    *charRef = letter;
	    }
	else
	    Error (NORESET, fileOffset);
    }

PTEoln (fileOffset)
    int  fileOffset;
    {
	register  int letter;
	register  struct fileDescs  *fD;

	fD = &fileDescs[fileOffset-1];
	if (fD->mode == READ)
	    {
		if ( (letter=getc (fD->fileFile)) == EOF)
		    Error (FILEEOF, fileOffset);
		ungetc (letter, fD->fileFile);
		return (letter == '\n');
	    }
	else
	    Error (NORESET, fileOffset);
    }

PTEof (fileOffset)
    int  fileOffset;
    {
	register int  letter;
	register struct fileDescs *fD;

	fD = &fileDescs[fileOffset-1];
	if (fD->mode == READ)
	    {
		if ( (letter=getc (fD->fileFile)) == EOF)
		    return (1);
		ungetc (letter, fD->fileFile);
		return (0);
	    }
	else if (fD->mode == WRITE)
	    return (1);
	else
	    Error (NORESET, argument[fileOffset]);
    }

/* PX String Routines - note that these do not give error messages
   if things go wrong.  Instead, they attempt to create SOME reasonable 
   result. */

PXConcatenate (s1, s2)
    char  s1[], s2[];
    {
	/* s1 := s1 + s2 */
	register char *p1,*p1last,*p2; 
	p1 = s1;
	p1last = &(s1[255]);	/* last byte in s1 */
	/* find end of s1 */
	while ((p1 < p1last) && (*p1++));
	p1--;
	/* concatenate on s2 */
	for (p2 = s2; (p1 < p1last) && (*p1++ = *p2++); );
	p1--;
	*p1 = EOS;  		/* in case result truncated */
    }

PXSubstring (s, len, start)
    char s[];
    int start, len;
    {
	/* s := s ! start : len */
	register char *p1,*p2;
	register char *p1last;	/* Last character in s to copy. */

	if ((start <= 0) || (len <= 0) || (start+len > 255)) {
	    s[0] = EOS;
	    return;
	}

	p2 = s;
	p1last = &s[start+len-2];
	for (p1= &s[start-1]; p1!=p1last+1;)
	    *p2++ = *p1++;
	*p2 = EOS;
    }

PXReadString (fileOffset, s)
    int  fileOffset;
    char s[];
    {
	register int  i,letter;
	register struct fileDescs  *fD;

	fD = &fileDescs[fileOffset-1];
	if (fD->mode == READ)
	    {
		for (i=0; i<255; i++)  {
		    letter = getc (fD->fileFile);
		    if (letter == '\n')
			break;
		    else if (letter == EOF)
			Error (FILEEOF, fileOffset);
		    else
			s[i] = letter;
		}
		s[i] = EOS;
	    }
	else
	    Error (NORESET, fileOffset);
    }

PXWriteString (s, fileOffset, fieldWidth)
    char  s[];
    int   fieldWidth, fileOffset;
    {
	register int i;
	for (i=0; (i < 255) && (s[i]); i++);
	PutStr (OpenTest (fileOffset, WRITE), i, s, fieldWidth);
   }

/* fast, small version of standard fprintf */
fprintf (f, fmt, a)
	register FILE *f;
	register char *fmt;
	int a;
    {
	register char **ap;

	ap = (char **) &a;

	while (*fmt) {
		if (*fmt == '%') {
			switch (*++fmt) {
				case '%':
					break;

				case 'd':
					PutInt (f, *ap++, 0);
					fmt++;
					continue;

				case 's':
					while (* (*ap)) fputc (* (*ap)++, f);
					*ap++;
					fmt++;
					continue;

				default:
					putc ('%', f);
					break;
				}
		}
		fputc (*fmt++, f);
	}
    }
