#include <stdio.h>

/*
 *	Computer Systems Research Group
 *	University of Toronto
 *
 *	File:   ptc.c  V1.03
 *	Author: Alan Rosselet
 *	        VAX and SUN conversions by J.R. Cordy, Queen's University
 *
 *	Date:   28 Nov 1980 (Revised 7 Sept 1987)
 *
 *	Copyright (C) 1980, the University of Toronto
 */

/* This is the "ptc" command which executes the PT compiler. */

char *usage = 
    "ptc [-help] [-O] [-S] [-c] [-L lib] [-T] [-oN] [-tN] [-nDD] progname.pt";

/* The PT Compiler Library (changeable via the -L option) */
char *library =		"/usr/lib/pt";

/* The PT Compiler Passes (in the library) */
char stdIds[80], scanSst[80], parser[80], parseSst[80], semantic[80],
     semanSst[80], coder[80], coderSst[80], monitorA[80], monitorB[80];
#define STDIDS 		"/stdIdentifiers"
#define SCANSST		"/scan.sst"
#define PARSER 		"/parser.out"
#define PARSESST 	"/parser.sst"
#define SEMANTIC 	"/semantic.out"
#define SEMANSST 	"/semantic.sst"
#define CODER 		"/coder.out"
#define CODERSST 	"/coder.sst"
#define MONITORA 	"/mona.o"
#define MONITORB 	"/monb.o"

/* Assembler and Linker */
char *assembler =	"/bin/as";
char *load =		"/bin/ld";
char *crt0 =		"/lib/crt0.o";
char *move =		"/bin/mv";

/* Option Flags */
#define true	1
#define false	0
int cOption =  false;
int Soption =  false;
int Toption =  false;
int oOption =  99;	/* number of compiler passes to run */

/* Arguments to the Processor */
int arg =  0;
char pnamechars[100];
char *progname =  pnamechars;
char progsuf;
char *sourceFile =  0;
int nPtcArgs =  0;
char *ptcArgs[15];

char loadFile[32];
char asmFile[32];
char objFile[32];
char *linkFiles[10];
int nLinkFiles = 0;

char *optionFile =	"/tmp/ptcXXXXX";
char *tempdir =		"/tmp";
char *tempname =	"/ptcXXXXX";
char parseStream[80], semTempFile[80], tCodeFile[80];
#define PARSESTREAM	".parseout"
#define SEMTEMPFILE	".semtemp"
#define TCODEFILE	".tcode"

int optfd;
int tmpfd;

/* Error Severity Levels */
#define fatal	1
#define continue  0

/* Code used by the UNIX open call */
#define READ  0

/* Routine declarations */
extern char * mktemp();
extern char * strip();
extern char suffix();



main (argc, argv)
    char *argv[];
    int argc;

    { int i;
      char c;

    arg = 0;

    if (argc == 1)  useerror ();

    /* Process Options */

    optionFile = mktemp (optionFile);
    if ((optfd=creat(optionFile, 0644)) == -1)  
	error ("ptc: Unable to create ", optionFile, fatal);

    while (++arg < argc)  {

	if (*argv[arg] == '-')  {
	    option (argv);

	} else {
	    if (!sourceFile)  {
		sourceFile = argv[arg];
		copystr (sourceFile, progname);
		progsuf = suffix (progname);
		progname = strip (progname);
	    } else 
		linkFiles[nLinkFiles++] = argv[arg];
	}
    };

    close (optfd);

    if (!sourceFile)  useerror ();


    /* Run the Compiler */

    concatn (loadFile, progname, ".out", 0);
    concatn (asmFile, progname, ".s", 0);
    concatn (objFile, progname, ".o", 0);

    tempname = mktemp (tempname);
    concatn (parseStream, tempdir, tempname, PARSESTREAM, 0);
    concatn (semTempFile, tempdir, tempname, SEMTEMPFILE, 0);
    concatn (tCodeFile, tempdir, tempname, TCODEFILE, 0);

    concatn (stdIds, library, STDIDS, 0);
    concatn (scanSst, library, SCANSST, 0);
    concatn (parseSst, library, PARSESST, 0);
    concatn (parser, library, PARSER, 0);
    concatn (semanSst, library, SEMANSST, 0);
    concatn (semantic, library, SEMANTIC, 0);
    concatn (coderSst, library, CODERSST, 0);
    concatn (coder, library, CODER, 0);
    concatn (monitorA, library, MONITORA, 0);
    concatn (monitorB, library, MONITORB, 0);

    if (progsuf == 'p') {

	/* Compile PT Program to Assembly Code */

	ptcArgs[0] = "parser";
	ptcArgs[1] = stdIds;
	ptcArgs[2] = scanSst;
	ptcArgs[3] = parseSst;
	ptcArgs[4] = sourceFile;
	ptcArgs[5] = parseStream;
	ptcArgs[6] = optionFile;
	ptcArgs[7] = 0;

	if (callsys (parser, ptcArgs, 0, 0))  goto finished;

	/* If the parser aborted translation (indicated by an empty token
	   stream) then exit.					    */
	tmpfd = open(parseStream, READ);
	if (!read(tmpfd, &c, 1)) goto finished;

	/* decrement twice, since scanner/parser is actually one pass */
	if (--oOption <= 0) goto finished;
	if (--oOption <= 0) goto finished;

	ptcArgs[0] = "semantic";
	ptcArgs[1] = semanSst;
	ptcArgs[2] = parseStream;
	ptcArgs[3] = semTempFile;
	ptcArgs[4] = tCodeFile;
	ptcArgs[5] = optionFile;
	ptcArgs[6] = 0;

	if (callsys (semantic, ptcArgs, 0, 0)) goto finished;

	/* If the semantic pass had a fatal error (first word > 0) then abort */
	tmpfd = open(tCodeFile, READ);
	read(tmpfd, &i, 4);
	if (i) goto finished;

	if (--oOption <= 0) goto finished;

	ptcArgs[0] = "coder";
	ptcArgs[1] = coderSst;
	ptcArgs[2] = tCodeFile;
	ptcArgs[3] = asmFile;
	ptcArgs[4] = optionFile;
	ptcArgs[5] = 0;

	if (callsys (coder, ptcArgs, 0, 0)) goto finished;

	progsuf = 's';
    };

    if (Soption) goto finished;

    if (progsuf == 's') {

	/* Assemble the PT program */
	ptcArgs[0] = "as";
	ptcArgs[1] = "-o";;
	ptcArgs[2] = objFile;
	ptcArgs[3] = asmFile;
	ptcArgs[4] = 0;
	    
	if (callsys (assembler, ptcArgs, 0, 0)) goto finished;

	progsuf = 'o';

	if (!Toption) unlink (asmFile);
    };

    if (cOption) goto finished;

    if (progsuf != 'o')  useerror();

    /* Create a load module */
    ptcArgs[0] = "ld";
    ptcArgs[1] = "-n";
    ptcArgs[2] = crt0;
    ptcArgs[3] = monitorA;
    ptcArgs[4] = monitorB;
    ptcArgs[5] = objFile;

    nPtcArgs = 6;
    i = 1;
    while (i <= nLinkFiles)
	ptcArgs[nPtcArgs++] = linkFiles[i++];

    ptcArgs[nPtcArgs++] = "-lc";
    ptcArgs[nPtcArgs] = 0;

    if (callsys(load, ptcArgs, 0, 0)) goto finished;

    if (!Toption) unlink (objFile);

    /* Move a.out to progname.out */
    ptcArgs[0] = "mv";
    ptcArgs[1] = "a.out";
    ptcArgs[2] = loadFile;
    ptcArgs[3] = 0;

    callsys(move, ptcArgs, 0, 0);



finished:
    unlink (optionFile);
    if (!Toption) {
	unlink (parseStream);
	unlink (semTempFile);
	unlink (tCodeFile);
    }
}



option (argv)
    char *argv[];

    { int j,value;
    char c;

    j = 0;

    while (argv[arg][++j])  {

	c = argv[arg][j];

	if (c == '-')  {
	    value = false;
	    j++;
	    c = argv[arg][j];
	} else {
	    value = true;
	};

	switch (c)  {
	    case 'h':
		help ();
		unlink (optionFile);
		exit (0);
    
	    case 'c':
		cOption = value;
		break;

	    case 'S':
		Soption = value;
		break;

	    case 'T':
		tempdir = ".";
		Toption = value;
		break;

	    case 'L':
		library = argv[++arg];
		return;

	    case 'o':
		c = argv[arg][++j];
		oOption = (c - '0');
		break;

	    case 'm': case 'k': case 'O':
		if (value)  write(optfd, &c, 1);
		break;

	    case 'l':
		linkFiles[nLinkFiles++] = argv[arg];
		break;

	    case 't':
		write(optfd, &c, 1);
		c = argv[arg][++j];
		write(optfd, &c, 1);
		break;

	    case 'n':
		c = argv[arg][++j];
		write(optfd, &c, 1);
		c = argv[arg][++j];
		write(optfd, &c, 1);
		break;

	    default:
		useerror ();
	}
    }
}



callsys (prog, args)
    char prog[], *args[];

    { int t, status;

    if ((t=fork())==0) {
	execv (prog, args);
	error ("ptc: Unable to execute ", prog, fatal);

    } else {
	if (t == -1) 
	    error ("ptc: Unable to fork ", prog, fatal);
    };

    while (t!=wait(&status));

    if ((t=(status&0377)) != 0 && t!=14) {
	if (t!=2)	/* interrupt */
	    error ("ptc: Fatal processor error in ", prog, fatal);
    };

    return ((status>>8) & 0377);
}



error (msg, data, severity)
    char *msg, *data;
    int severity;

    { char outstr[200];

    concatn (outstr, msg, data, "\n", 0);
    write (2, outstr, length(outstr));

    if (severity == fatal)  {
	unlink (optionFile); 
	exit (10);
    };
}



useerror ()

    {
    error ("Usage:  ", usage, fatal);
}



char * strip (as)
    char *as;

    { register char *s;
    s = as;
    while (*s)
	if (*s++ == '/')
	    as = s;

    while (--s > as)
	if (*s == '.')  {
	    *s = '\0';
	    return (as);
	};

    useerror ();
}



char suffix (as)
    char *as;

    { register char *s;
    s = as;
    while (*s)
	s++;
    while (--s > as)
	if (*s == '.')  {
	    s++;
	    return (*s);
	};
    return ('\0');
}



help ()
    { char c;
    printf ("'ptc' invokes the PT compiler to compile a PT source program.\n");
    printf ("The command syntax is:\n\n");
    printf ("	%s\n\n", usage);
    printf ("The input source program is assumed to be in progname.pt .\n");
    printf ("The UNIX load module for the program will be placed in progname.out .\n");
    printf ("The -S and -c options specify UNIX assembly code or object code\n");
    printf ("respectively are to be placed in progname.s or progname.o instead.\n");
    printf ("The -O flag specifies that no line numbering and checking\n");
    printf ("code should be generated for the program.\n");
    printf ("This has the effect of reducing the size of the code generated\n");
    printf ("and speeding up execution, while sacrificing runtime checking.\n");
    printf ("Error messages are sent to the standard output.\n");
    printf ("Disasters (such as not finding the compiler) are logged\n");
    printf ("on the diagnostic output.\n\n");
    printf ("Option details? ");
    c = getchar();
    if (c == 'y')  {
	printf ("\nThe following options are recognized.\n\n");
	printf ("  -S	  compile to assembly code only, do not assemble or link\n");
	printf ("  -c	  compile to object code only, do not link\n");
	printf ("  -O	  optimize generated code by sacrificing runtime line\n");
	printf ("		numbering and checking\n");
	printf ("  -nDD	  use only the first DD (08 <= DD <= 50) characters to\n");
	printf ("		distinguish between different identifiers (default 50)\n");
	printf ("  -L DIR  run the version of the compiler passes in directory DIR\n");
	printf ("		instead of the production compiler in /usr/lib/pt\n");
	printf ("  -T	  put all compiler temporary files in the present working directory\n");
	printf ("		and do not remove them when done\n");
	printf ("  -oN	  execute only to end of compiler pass N\n");
	printf ("		(1 or 2 = scan/parse, 3 = semantic, 4 = coder)\n");
	printf ("  -tN	  trace execution of compiler pass N\n");
	printf ("		(1 = scan, 2 = parse, 3 = semantic, 4 = coder)\n");
    }
}



concatn (dest, rest)
    char *dest;

    { register char *from,*to;
    register *argp;

    to = dest;
    argp = &rest;
    while (from = (char *) *argp++) {
        while (*to++ = *from++)
            ;
        to--;
    }
}



char * mktemp (as)
    char *as;

    { register char *s;
    register pid, i;
    int sign;
    int sbuf[20];

    pid = getpid ();
    sign = 0;
    while (pid<0) {
        pid -= 10000;
        sign++;
    }

    s = as;
    while (*s++);
    s--;

    i = 0;
    while (*--s == 'X') {
        *s = (pid%10) + '0';
        pid /= 10;
        if (++i == 5)
            *s += sign;
    }

    s += i;
    while (stat(as, sbuf) != -1) {
        if (i==0 || sign>=20)
            return ("/");
        *s = 'a' + sign++;
    }

    return (as);
}


copystr (from, to)
    char *from, *to;

    { register char *t, *f;
    t = to;
    f = from;
    while (*t++ = *f++);
}



length (s)
    char *s;

    { register char *p;
    p = s;
    while (*p++);
    return (p - s - 1);
}
