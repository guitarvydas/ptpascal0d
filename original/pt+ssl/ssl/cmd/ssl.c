#

/*
 *	Computer Systems Research Group
 *	University of Toronto
 *
 *	File:	ssl.c  V2.00
 *	Author:	James R. Cordy
 *	Date:	13 August 1980  (Rev 1 Sept 1987)
 *
 *	Copyright (C) 1980, the University of Toronto
 */

/* This is the "ssl" command which executes the S/SL processor. */

char *usage =	"ssl [-help] [-L dir] [-l] [-b] [-c] [-t] progname.ssl";

/* The S/SL Processor Library */
char *library = "/usr/lib/ssl";

/* The S/SL Processor  */
char sslPass[80], sslSsl[80];
#define SSLPASS 	"/ssl.out"
#define SSLSSL	 	"/ssl.sst"

/* Option Flags */
#define true	1
#define false	0

/* Arguments to the Processor */
int arg = 0;
char pnamechars[100];
char *progname =  pnamechars;
char *sourceFile =  0;
int nSslArgs =  0;
char *sslArgs[10];

char defFile[15];
char sstFile[15];
char listFile[15];

char *optionFile =  "/tmp/sslaXXXXX";
int optfd;

/* Error Severity Levels */
#define fatal	1
#define continue  0

/* Routines */
char * mktemp();
char * strip();


main (argc, argv)
    char *argv[];
    int argc;

    { int i;

    arg = 0;

    if (argc == 1)  useerror ();

    /* Process Options */

    optionFile = mktemp (optionFile);
    if ((optfd=creat(optionFile, 0644)) == -1)  
	error ("ssl: Unable to create ", optionFile, fatal);

    while (++arg < argc)  {

	if (*argv[arg] == '-')  {
	    option (argv);

	} else {
	    if (sourceFile)  useerror ();
	    sourceFile = argv[arg];
	    copystr (sourceFile, progname);
	    progname = strip (progname);
	}
    };

    close (optfd);

    if (!sourceFile)  useerror ();


    /* Run the Processor */
    concatn (sslPass, library, SSLPASS, 0);
    concatn (sslSsl, library, SSLSSL, 0);

    concatn (defFile, progname, ".def", 0);
    concatn (sstFile, progname, ".sst", 0);
    concatn (listFile, progname, ".lst", 0);

    sslArgs[0] = "ssl";
    sslArgs[1] = sslSsl;
    sslArgs[2] = sourceFile;
    sslArgs[3] = defFile;
    sslArgs[4] = sstFile;
    sslArgs[5] = listFile;
    sslArgs[6] = optionFile;
    sslArgs[7] = 0;

    callsys (sslPass, sslArgs, 0, 0);
    unlink (optionFile);
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
    
	    case 'L':
		library = argv[++arg];
		return;

	    case 'l': case 'c': case 'b': case 't':
		if (value)  write(optfd, &c, 1);
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
	error ("ssl: Unable to execute ", prog, fatal);

    } else {
	if (t == -1)  {
	    error ("ssl: Unable to fork ", prog, continue);
	    return (10);
	}
    };

    while (t!=wait(&status));

    if ((t=(status&0377)) != 0 && t!=14) {
	if (t!=2)	/* interrupt */
	    error ("ssl: Fatal processor error in ", prog, continue);
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



help ()

    {
    printf ("'ssl' invokes the S/SL processor to process an S/SL source program.\n");
    printf ("The command syntax is:\n\n");
    printf ("	%s\n\n", usage);
    printf ("The input source program is assumed to be in progname.ssl .\n");
    printf ("The output Pascal definitions will be put in progname.def,\n");
    printf ("and the output integer table file in progname.sst .\n");
    printf ("If -l is specified, a source listing with table coordinates\n");
    printf ("will be put in progname.lst .\n");
    printf ("Error messages are sent to the standard output.\n");
    printf ("Disasters (such as not finding the processor) are logged\n");
    printf ("on the diagnostic output.\n\n");
    printf ("More details? ");
    if (getchar() != 'y') return;
    printf ("\nThe following are recognized options:\n\n");
    printf ("	-h :	Help! (You are reading it)\n");
    printf ("	-L DIR :  Run the S/SL processor in directory DIR instead of\n");
    printf ("		the standard S/SL processor in /usr/lib/ssl\n");
    printf ("	-l :	Produce a source listing with table coordinates in\n");
    printf ("		the left margin in progname.lst\n");
    printf ("	-b :	Produce byte (0..255) tables rather than word\n");
    printf ("	-c :	Produce char (0..127) tables rather than word\n");
    printf ("	-t :	Trace S/SL processor table execution\n\n");
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

