| XT SUN Monitor (Part B)  Ver 1.03, 
|  after PT SUN Monitor (Part B)  Ver 1.02, 
|  after PT VAX Monitor (Part B)  Ver 1.02, 
|  after PT PDP-11 Monitor  Ver 1.00

| Author:    Alan Rosselet, University of Toronto
|	     VAX conversion by J.R. Cordy, Queen's University at Kingston
|	     SUN conversion by J.R. Cordy, Queen's University at Kingston

| (VAX conversion 31 Aug 1985)
| (XT extension 27 Nov 1985)
| (SUN conversion 31 Aug 1987)
| (Revised 4 Dec 1987)


| globals referenced by C routines and defined here
	.globl  _DispatchUser

| globals defined in C and referenced here
	.globl	_PTHalt
	.globl	_PTReset
	.globl	_PTRewrite
	.globl	_PTWrite
	.globl  _PTWriteln
	.globl	_PTRead
	.globl  _PTReadln
	.globl	_PTWriteString
	.globl	_PTWriteInteger
	.globl	_PTWriteChar
	.globl	_PTReadInteger
	.globl	_PTReadChar
	.globl  _PTEoln
	.globl  _PTEof
	.globl  _PTSubscrErr
	.globl  _PTCaseAbort

| XT globals defined in C
	.globl	_XTConcatenate
	.globl	_XTSubstring
	.globl	_XTReadString
	.globl	_XTWriteString

| global trap names used in PT program
	.globl	t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t14,t15,t16,t17
|	.globl	t12,t13	| subscripts done inline on SUN

| global trap names used in XT program
	.globl	t101,t102,t103,t104,t105,t106,t107,t108

| register assignments 
|	d0		monitor scratch, C result value
|	a0,a5		monitor scratch
|	d1,d2,d3,d4	PT scratch  (monitor scratch also, except in Eof, Eoln
|	a1,a2,a3,a4	PT scratch   and string functions, which must preserve)
|	d7		PT line number
|	a6		C local base (DO NOT TOUCH!)

	.data; .align 2
return:	.long	0	| saved return address


	.text; .align 2

_DispatchUser:
	| start up the user
	jmp	userprog	| returns via trap PTHalt

t0:	| pthalt
	jbsr	_PTHalt

t1:	| ptreset
	movl	sp@+, return	| bring arg to top
	jbsr	_PTReset	| and call C routine to do it
	addql	#4,sp
	movl	return, sp@-
	rts

t2:	| ptrewrite
	movl	sp@+, return	| bring arg to top
	jbsr	_PTRewrite	| and call C routine to do it
	addql	#4,sp
	movl	return, sp@-
	rts

t3:	| ptread
	movl	sp@+, return	| bring args to top
	jbsr	_PTRead		| and call C routine to do it
	addl	#12,sp
	movl	return, sp@-
	rts

t4:	| ptreadln
	movl	sp@+, return	| bring arg to top
	jbsr	_PTReadln	| and call C routine to do it
	addql	#4,sp
	movl	return, sp@-
	rts

t5:	| ptwrite
	movl	sp@+, return	| bring args to top
	jbsr	_PTWrite	| and call C routine to do it
	addl	#12,sp
	movl	return, sp@-
	rts

t6:	| ptwriteln
	movl	sp@+, return	| bring arg to top
	jbsr	_PTWriteln	| and call C routine to do it
	addql	#4,sp
	movl	return, sp@-
	rts

t7:	| ptwrtstr
	movl	sp@+, return	| bring args to top
	jbsr	_PTWriteString	| and call C routine to do it
	addl	#12,sp
	movl	return, sp@-
	rts

t8:	| ptwrtint
	movl	sp@+, return	| bring args to top
	jbsr	_PTWriteInteger	| and call C routine to do it
	addl	#12,sp
	movl	return, sp@-
	rts

t9:	| ptwrtchr
	movl	sp@+, return	| bring args to top
	| correct for silly PT unaligned stack
	movl	sp@+, d1
	movl	sp@+, d2
	clrl	d3
	movb	sp@+, d3
	movl	d3, sp@-
	movl	d2, sp@-
	movl	d1, sp@-
	| end correction
	jbsr	_PTWriteChar	| call C routine to do it
	addl	#12,sp
	movl	return, sp@-
	rts

t10:	| ptrdint
	movl	sp@+, return	| bring args to top
	jbsr	_PTReadInteger	| and call C routine to do it
	addql	#8,sp
	movl	return, sp@-
	rts

t11:	| ptrdchr
	movl	sp@+, return	| bring args to top
	jbsr	_PTReadChar	| and call C routine to do it
	addql	#8,sp
	movl	return, sp@-
	rts

|t12:	| subscrByte		| (obsolete - subscripting now done inline)

|t13:	| subscrWord		| (obsolete - subscripting now done inline)

t17:	| subsError 		| (used by inline subscripting code)
	tstl	sp@+		| discard return address; we're aborting anyway
	movl	sp@+, a0	| array descriptor address
	movl	sp@+, d0	| normalized subscript 

subsLoErr:
	movl	a0@-, sp@-	| upper-lower bound
	movl	a0@-, sp@-	| lower bound
	movl	sp@, d1		|
	addl	d1, sp@(4)	| normalize upper bound
	addl	a0@, d0		| unnormalize subscript
	movl	d0, sp@-	| subscript
	movl	d7, sp@-	| line number
	jbsr	_PTSubscrErr 	| call C routine to print message and abort

t14:	| ptcaseAbort
	tstl	sp@+		| discard return address; we're aborting anyway
	movl	d7, sp@-	| line number
	jbsr	_PTCaseAbort 	| call C routine to print message and abort

t15: 	| ptEoln
	movl	sp@+, return	| move args to stack top
	jbsr	_PTEoln		| call C routine to check
	addql	#4,sp
	movb	d0, sp@-	| push result to stack
	movl	return, sp@-
	rts

t16:	| ptEof
	movl	sp@+, return	| move args to stack top
	jbsr	_PTEof		| call C routine to check
	addql	#4,sp
	movb	d0, sp@-	| push result to stack
	movl	return, sp@-
	rts

t101:	| xtFetchLiteralString (literalAddress : address) : string
	| 	pops address of literal from stack and pushes 
	| 	literal as string value in standard 256 byte form
	movl	sp@+, return	| return address
	movl	sp@+, a0	| address of literal
	subl	#256, sp	| space for result
	lea	sp@, a5		| address of result
1:	movb	a0@+, a5@+	| move literal characters, including trailing
	jne	1b		| null, into result string
	movl	return, sp@-
	rts

t102:	| xtFetchString (stringAddress : address) : string
	| 	pops address of string from stack and pushes 
	| 	string value
	movl	sp@+, return	| return address
	movl	sp@+, a0	| address of string
	subl	#256, sp	| space for result
	lea	sp@, a5		| address of result
1:	movb	a0@+, a5@+	| move string characters, including trailing
	jne	1b		| null, into result string
	movl	return, sp@-
	rts

t103:	| xtConcatenate (s1, s2 : string) : string
	| 	replaces two string values on stack with their concatenation
	movl	sp@+, return	| return address
	movl	sp, sp@-	| address of s2
	pea	sp@(260)	| address of s1
	jbsr	_XTConcatenate  | leaves result in s1
	addql	#8, sp		| pop address args
	addl	#256, sp	| discard s2
	movl	return, sp@-
	rts

t104:	| xtSubstring (s : string; i1,i2 : integer) : string
	| 	replaces string, lower bound and length on stack
	|	with string result
	movl	sp@+, return	| return address
	pea	sp@(8)		| address of s
	jbsr	_XTSubstring  	| leaves result in s
	addl	#12, sp		| pop args (address of s, i1 and i2)
	movl	return, sp@-
	rts

t105:	| xtLength (s : string) : integer
	| 	replaces two string values on stack with their concatenation
	movl	sp@+, return	| return address
	lea	sp@, a0		| address of s
	clrl	d0		| count chars in s
1:	tstb	a0@+		| test for null
	jeq	2f		| if null, end of string -> done
	addql	#1, d0		| if not, count another char
	jra	1b		| and go on
2:	addl	#256, sp	| done; pop s
	movl	d0, sp@-	| push result
	movl	return, sp@-
	rts

t106:	| xtStringEqual (s1, s2 : string) : boolean
	| 	replaces two string values on stack with boolean true if
	|	they are equal and boolean false otherwise
	movl	sp@+, return	| return address
	movl	sp, a0		| addr (s2)
	lea	sp@(256), a5	| addr (s1)
1:	cmpmb	a0@+, a5@+	| compare next two chars
	jne	2f		| if not equal, done (strings not equal)
	tstb	a0@(-1)		| else if chars compared not null,
	jne	1b		| not at end of strings so compare next chars
	movl	#1, d0		| else at end so done (strings equal)
	jra	3f		
2:	clrl	d0		| not equal, result false
3:	addl	#512, sp	| pop s1 and s2
	movb	d0, sp@-	| push result
	movl	return, sp@-
	rts

t107:	| xtReadString (stringAddress : address; fd : integer)
	movl	sp@+, return
	jbsr	_XTReadString
	addql	#8, sp		| pop args
	movl	return, sp@-
	rts

t108:	| xtWriteString (s : string; w : integer; fd : integer)
	movl	sp@+, return
	pea	sp@(8)		| addr(s)
	jbsr	_XTWriteString
	addl	#12, sp		| pop args (addr (s), fd, w)
	addl	#256, sp	| discard s
	movl	return, sp@-
	rts

	.align 2		| MUST be aligned on a 4-byte boundary!
userprog:
