||
||t101:	| xtFetchLiteralString (literalAddress : address) : string
||	| 	pops address of literal from stack and pushes 
||	| 	literal as string value in standard 256 byte form
||	movl	sp@+, a3	| return address
||	movl	sp@+, a1	| address of literal
||	subl	#256, sp	| space for result
||	lea	sp@, a2		| address of result
||1:	movb	a2@+, a1@+	| move literal characters, including trailing
||	jne	1b		| null, into result string
||	jmp	a3@
	.data
hithere:.asciz	"hi there"
.even
.lcomm	s1,256
.lcomm	s2,256
.lcomm	s3,256
.lcomm	s4,256
.lcomm	s5,256
infd=1
outfd=2
	.text
userprog:
	pea	hithere
	jbsr	t101		| result string on stack
	lea	sp@, a2		| address of result
	lea	s1, a1
1:	movb	a2@+, a1@+	| assign result to s1
	jne	1b		| 
	pea	1
	pea	outfd
	jbsr	t108
	pea	outfd
	jbsr	t6
||
||t102:	| xtFetchString (stringAddress : address) : string
||	| 	pops address of string from stack and pushes 
||	| 	string value
||	movl	sp@+, a3	| return address
||	movl	sp@+, r0	| address of string
||	subl	#256, sp	| space for result
||	lea	sp@, a2		| address of result
||1:	movb	a2@+, a1@+	| move string characters, including trailing
||	jne	1b		| null, into result string
||	jmp	a3@
	pea	s1
	jbsr	t102		| result string on stack
	pea	s1
	jbsr	t102		| result string on stack
	lea	sp@, a2		| address of result
	lea	s2, a1
1:	movb	a2@+, a1@+	| assign result to s2
	jne	1b		| 
||
||t103:	| xtConcatenate (s1, s2 : string) : string
||	| 	replaces two string values on stack with their concatenation
||	movl	sp@+, a3	| return address
||	movl	sp, sp@-	| address of s2
||	pea	sp@(260)	| address of s1
||	jbsr	_PXConcatenate  | leaves result in s1
||	addql	#8, sp		| pop address args
||	addl	#256, sp	| discard s2
||	jmp	a3@
	| (two copies of s1 already fetched to stack)
	jbsr	t103		| leaves result on stack
	lea	sp@, a2
	lea	s3, a1
1:	movb	a2@+, a1@+	| assign result to s3
	jne	1b		| 
	pea	s3
	jbsr	t102
	pea	1
	pea	outfd
	jbsr	t108
	pea	outfd
	jbsr	t6
||
||t104:	| xtSubstring (s : string; i1,i2 : integer) : string
||	| 	replaces string value with substring from i1, length i2
||	movl	sp@+, a3	| return address
||	pea	sp@(8)		| address of s
||	jbsr	_PXSubstring  	| leaves result in s
||	addl	#12, sp		| pop args (address of s, i1 and i2)
||	jmp	a3@
	| s3 is already on stack
	pea	9
	pea	2
	jbsr	t104
	lea	sp@, a2		| address of result
	lea	s4, a1
1:	movb	a2@+, a1@+	| assign result to s4
	jne	1b		| 
	pea	s4
	jbsr	t102
	pea	1
	pea	outfd
	jbsr	t108
	pea	outfd
	jbsr	t6
||
||t105:	| xtLength (s : string) : integer
||	| 	replaces two string values on stack with their concatenation
||	movl	sp@+, a3	| return address
||	lea	sp@, a2		| address of s
||	clrl	d0		| count chars in s
||1:	tstb	a2@+		| test for null
||	jeq	2f		| if null, end of string -> done
||	addql	#1, d0		| if not, count another char
||	jra	1b		| and go on
||2:	addl	#256, sp	| done; pop s
||	movl	d0, sp@-	| push result
||	jmp	a3@		
	| s4 already on stack
	jbsr	t105		| replace string with length
	movl	#1, sp@-
	pea	outfd
	jbsr	t8		| print integer result	
	pea	outfd
	jbsr	t6		
||
||t106:	| xtStringEqual (s1, s2 : string) : boolean
||	| 	replaces two string values on stack with boolean true if
||	|	they are equal and boolean false otherwise
||	movl	sp@+, a3	| return address
||	movl	sp, a2		| addr (s2)
||	lea	sp@(256), a1	| addr (s1)
||1:	cmpmb	a1@+, a2@+	| compare next two chars
||	jne	2f		| if not equal, done (strings not equal)
||	tstb	a2@(-1)		| else if chars compared not null,
||	jne	1b		| not at end of strings so compare next chars
||	movl	#1, d0		| else at end so done (strings equal)
||	jra	3f		
||2:	clrl	d0		| not equal, result false
||3:	addl	#512, sp	| pop s1 and s2
||	movb	d0, sp@-	| push result
||	jmp	a3@
	.data
fail:	.asciz	"fail"
pass:	.asciz	"pass"
	.text
	pea	s1	
	jbsr	t102		| push string value of s1
	pea	s2
	jbsr	t102		| push string value of s2
	jbsr	t106		| compare
	cmpb	#1,sp@+		| test result
	bne	1f		
	pea	pass
	bra	2f
1:	pea 	fail
2:	jbsr	t102
	pea	1
	pea	outfd
	jbsr	t108		| print pass/fail
	pea	outfd
	jbsr	t6
||
||t107:	| xtReadString (stringAddress : address; fd : integer)
||	movl	sp@+, a3
||	jbsr	_PXReadString
||	addql	#8, sp		| pop args
||	jmp	a3@
	pea	s5
	pea	infd
	jbsr	t107
	pea	s5
	jbsr	t102
	pea	1
	pea	outfd
	jbsr	t108
	pea	outfd
	jbsr	t6
||
||t108:	| xtWriteString (s : string; w : integer; fd : integer)
||	movl	sp@+, a3
||	pea	sp@(8)		| addr(s)
||	jbsr	_PXWriteString
||	addl	#12, sp		| pop args (addr (s), fd, w)
||	addl	#256, sp	| discard s
||	jmp	a3@
	pea	s5
	jbsr	t102
	pea	1
	pea	outfd
	jbsr	t108
	pea	outfd
	jbsr	t6
||
||	.align 2		| MUST be aligned on a 4-byte boundary!
||userprog:
	jbsr	t0
