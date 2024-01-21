| PT SUN Monitor (Part B)  Ver 1.03, 
|  after PT VAX Monitor (Part B)  Ver 1.02, 
|  after PT PDP-11 Monitor  Ver 1.00

| Author:    Alan Rosselet, University of Toronto
|	     VAX conversion by J.R. Cordy, Queen's University at Kingston
|	     SUN conversion by J.R. Cordy, Queen's University at Kingston

| (VAX conversion 31 Aug 1985)
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

| global trap names used in PT program
	.globl	t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t14,t15,t16,t17
|	.globl	t12,t13	| subscripts done inline on SUN

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

	.align 2		| MUST be aligned on a 4-byte boundary!
userprog:
