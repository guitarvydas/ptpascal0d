% PT S/SL Symbolic Tracing Filter V1.00
% J.R. Cordy, Queen's University, 10 Jan 1990

% This program is designed to take the .def file generated from
% the PT S/SL Processor V1.12 or later, and use the information in
% it to filter the tracing output of a PT S/SL program, converting
% the trace to a formatted symbolic one.

% Usage:    (program generating trace) | ssltrace.x program.def


% Limits
const maxnamelength := 100
const maxprimitives := 14
const maxoperations := 300
const maxinputtokens := 300
const maxoutputtokens := 300
const maxiotokens := 300
const maxerrorcodes := 300
const maxtypes := 20
const maxtypevalues := 300
const maxrules := 300
const maxcalldepth := 100

type Definition :
    record
	name : string (maxnamelength)
	value : int
	parmtype, resulttype : int
    end record

% S/SL Primitives
const primitives : array 1 .. maxprimitives + 1 of Definition := init (
    init ("oCall", 0, 0, 0),
    init ("oReturn", 1, 0, 0),
    init ("oRuleEnd", 2, 0, 0),
    init ("oJumpBack", 3, 0, 0),
    init ("oJumpForward", 4, 0, 0),
    init ("oInput", 5, 0, 0),
    init ("oInputAny", 6, 0, 0),
    init ("oInputChoice", 7, 0, 0),
    init ("oEmit", 8, 0, 0),
    init ("oError", 9, 0, 0),
    init ("oChoice", 10, 0, 0),
    init ("oChoiceEnd", 11, 0, 0),
    init ("oSetParameter", 12, 0, 0),
    init ("oSetResult", 13, 0, 0),
    init ("", 0, 0, 0)
    )

% Get Operation Definitions from .def file
var line := ""

procedure flushuntil (marker : string)
    loop
	exit when index (line, marker) not= 0
	get : 1, line : *
    end loop
end flushuntil

function defname (line : string) : string
    pre index (line, "=") not= 0
    var n1 := 1
    loop
	exit when line (n1) not= " " and line (n1) not= "\t"
	n1 += 1
    end loop
    const n2 := index (line (n1 .. *), " ") + n1 - 2
    result line (n1 .. n2)
end defname

function defvalue (line : string) : int
    pre index (line, "=") not= 0
    const n1 := index (line, "=") + 2
    const n2 := index (line, ";") - 1
    result strint (line (n1 .. n2))
end defvalue

function defparmtype (line : string) : int
    pre index (line, "=") not= 0
    if index (line, "(") not= 0 then
	const n1 := index (line, "(") + 1
	const n2 := index (line, ")") - 1
	result strint (line (n1 .. n2))
    else
	result 0
    end if
end defparmtype

function defresulttype (line : string) : int
    pre index (line, "=") not= 0
    if index (line, ">>") not= 0 then
	const n1 := index (line, ">>") + 2
	var n2 := index (line, "}") - 2
	if n2 < 0 then
	    n2 := length (line)
	end if
	result strint (line (n1 .. n2))
    else
	result 0
    end if
end defresulttype

procedure getclassdefinitions
	(classname : string, var class : array 1 .. * of Definition)
    var nextdef := 0
    flushuntil (classname)
    loop
	get : 1, line : *
	exit when index (line, "=") = 0
	nextdef += 1
	class (nextdef).name := defname (line)
	class (nextdef).value := defvalue (line)
	class (nextdef).parmtype := defparmtype (line)
	class (nextdef).resulttype := defresulttype (line)
    end loop
    class (nextdef + 1).name := ""
end getclassdefinitions

var operations : array 1 .. maxoperations of Definition
var inputtokens : array 1 .. maxinputtokens of Definition
var outputtokens : array 1 .. maxoutputtokens of Definition
var iotokens : array 1 .. maxiotokens of Definition
var errorcodes : array 1 .. maxerrorcodes of Definition
var rules : array 1 .. maxrules of Definition

var ntypes := 0
var typevalues : array 1 .. maxtypes of 
    record 
	code : int
	values : array 1 .. maxtypevalues of Definition
    end record

function word (line : string, whichword : 1 .. 20) : string
    if index (line, " ") = 1 then
	result word (line (2 .. *), whichword)
    elsif whichword = 1 then
	if index (line, " ") = 0 then
	    result line
	else
	    result line (1 .. index (line, " ") - 1)
	end if
    else
	result word (line (index (line, " ") + 1 .. *), whichword - 1)
    end if
end word

procedure gettypedefinitions
    flushuntil ("Type Values")
    get : 1, line : *
    if index (line, "{") not= 0 then
	loop
	    flushuntil ("{ ")
	    exit when index (line, "S/SL Rule") not= 0
	    assert index (line, "Type ") not= 0
	    % { Type NN }
	    const typecode := strint (word (line, 3))
	    ntypes += 1
	    typevalues (ntypes).code := typecode
	    getclassdefinitions ("Type " + intstr (typecode, 1), 
		typevalues (ntypes).values)
	end loop
    end if
end gettypedefinitions

getclassdefinitions ("Operations", operations)
getclassdefinitions ("Input Tokens", inputtokens)
getclassdefinitions ("Output Tokens", outputtokens)
getclassdefinitions ("Input/Output Tokens", iotokens)
getclassdefinitions ("Error Codes", errorcodes)
gettypedefinitions 
getclassdefinitions ("S/SL Rule", rules)


% Now translate the trace stream
function lookupclassdefinition (class : array 1 .. * of Definition,
	value : int) : int
    var i := 1
    loop
	exit when class (i).name = "" or class (i).value = value
	i += 1
    end loop
    result i
end lookupclassdefinition

function lookuptype (typecode : int) : int
    for i : 1 .. ntypes
	if typevalues (i).code = typecode then
	    result i
	end if
    end for
    result 0
end lookuptype


% Keep track of what rule we're in
var callstack : array 1 .. maxcalldepth of int % (ruletable index)
var calldepth := 1
callstack (calldepth) := 1 % first rule is always the main one
put "@", rules (1).name

var nexttokenname := ""

loop
    exit when eof
    get line : *

    if index (line, "Input") = 1 then
	% "Input token accepted 28;  Line         0;  Next input token 21"
	% Nothing to output, since already did so for the input operation.
	% Just remember the lookahead.
	const nexttoken := strint (word (line, 10))
	var nexttokenentry := lookupclassdefinition (inputtokens, nexttoken)
	nexttokenname := inputtokens (nexttokenentry).name
	if nexttokenname = "" then
	    nexttokenentry := lookupclassdefinition (iotokens, nexttoken)
	    nexttokenname := iotokens (nexttokenentry).name
	end if

    elsif index (line, "Output") = 1 then
	% "Output token emitted 28"
	% Must be one emitted from a semantic operation, since
	% we take output lines with the emit operation.
	const value := strint (word (line, 4))
	put "" : calldepth, "% value emitted ", value

    elsif index (line, "Table") = 1 then
	% Table index 0;  Operation 0;  Argument 11
	const operation := strint (word (line, 5) (1 .. * - 1))
	const argument := strint (word (line, 7))
	const primitiveentry := lookupclassdefinition (primitives, operation)
	const primitivename := primitives (primitiveentry).name

	if primitivename not= "" then

	    if primitivename = "oCall" then
		% Rule call
		const ruleentry := lookupclassdefinition (rules, argument)
		const rulename := rules (ruleentry).name
		put "" : calldepth, "@", rulename
		calldepth += 1
		callstack (calldepth) := ruleentry

	    elsif primitivename = "oReturn" then
		% Rule return
		const rulename := rules (callstack (calldepth)).name
		put "" : calldepth, ">>"
		calldepth -= 1
		put "" : calldepth, ";", rulename

	    elsif primitivename = "oRuleEnd" then
		% Choice rule failure
		const rulename := rules (callstack (calldepth)).name
		calldepth -= 1
		put "" : calldepth, ";", rulename, 
		    " (FAILED TO RETURN A RESULT!)"

	    elsif primitivename = "oJumpBack" then
		% Repeat cycle
		put "" : calldepth, "}"

	    elsif primitivename = "oJumpForward" then
		% Choice or cycle exit
		put "" : calldepth, "] or >"

	    elsif primitivename = "oInput" then
		% Required input token
		var tokenentry := lookupclassdefinition (inputtokens,
		    argument)
		var tokenname := inputtokens (tokenentry).name
		if tokenname = "" then
		    tokenentry := lookupclassdefinition (iotokens, argument)
		    tokenname := iotokens (tokenentry).name
		end if
		put "" : calldepth, "?", tokenname, " (", nexttokenname, ")"

	    elsif primitivename = "oInputAny" then
		% Arbitrary input token
		put "" : calldepth, "? (", nexttokenname, ")"

	    elsif primitivename = "oInputChoice" then
		% Input choice
		put "" : calldepth, "[ (", nexttokenname, ")"
		get line : *
		% Choice tag NN ([not] matched)
		assert index (line, "Choice") = 1

		if index (line, "not") not= 0 then
		    put "" : calldepth, "| *:"
		else
		    put "" : calldepth, "| ", nexttokenname, ":"
		end if

	    elsif primitivename = "oEmit" then
		% Emit output token
		var tokenentry := lookupclassdefinition (outputtokens, argument)
		var tokenname := outputtokens (tokenentry).name
		if tokenname = "" then
		    tokenentry := lookupclassdefinition (iotokens, argument)
		    tokenname := iotokens (tokenentry).name
		end if
		put "" : calldepth, ".", tokenname ..
		get line : *
		% "Output token emitted 28"
		const emittedtoken := strint (word (line, 4))
		var emittedtokenentry := lookupclassdefinition (outputtokens, emittedtoken)
		var emittedtokenname := outputtokens (emittedtokenentry).name
		if emittedtokenname = "" then
		    emittedtokenentry := lookupclassdefinition (iotokens, emittedtoken)
		    emittedtokenname := iotokens (emittedtokenentry).name
		end if
		if tokenname not= emittedtokenname then
		    % If they differ, some kind of screener changed it!
		    put " (screened to ", emittedtokenname, ")"
		else
		    put ""
		end if

	    elsif primitivename = "oError" then
		% Emit error signal
		const errorentry := lookupclassdefinition (errorcodes, argument)
		const errorname := errorcodes (errorentry).name
		put "" : calldepth, "#", errorname

	    elsif primitivename = "oChoice" then
		% Semantic choice
		assert false	% Shouldn't happen; handled elsewhere
		put "" : calldepth, "["

	    elsif primitivename = "oEndChoice" then
		% Semantic choice failure
		put "" : calldepth, "] (CHOICE FAILED)"

	    elsif primitivename = "oSetParameter" then
		% Parameterized semantic operation
		get line : *
		const nextoperation := strint (word (line, 5) (1 .. * - 1))
		const operationentry :=
		    lookupclassdefinition (operations, nextoperation)
		const operationname := operations (operationentry).name
		const typeentry := 
		    lookuptype (operations (operationentry).parmtype)
		const argumententry := 
		    lookupclassdefinition (typevalues (typeentry).values, 
			argument)
		const argumentname := 
		    typevalues (typeentry).values (argumententry).name

		if operations (operationentry).resulttype not = 0 then
		    % Parameterized choice semantic operation
		    get line : *
		    assert index (line, "Operation 10") not= 0
		    get line : *
		    % Choice tag NN ([not] matched)
		    const choicetag := strint (word (line, 3))
		    const choicetypeentry := 
			lookuptype (operations (operationentry).resulttype)
		    const choicetagentry := 
			lookupclassdefinition (typevalues (typeentry).values, 
			    choicetag)
		    const choicetagname := 
			typevalues (typeentry).values (choicetagentry).name
		    put "" : calldepth, "[ ", operationname, "(",
			argumentname, ") (", choicetagname, ")"

		    if index (line, "not") not= 0 then
			put "" : calldepth, "| *:"
		    else
			put "" : calldepth, "| ", choicetagname, ":"
		    end if

		else
		    % Parameterized update semantic operation
		    put "" : calldepth, operationname, "(", argumentname, ")"
		end if

	    elsif primitivename = "oSetResult" then
		% Choice rule return
		get line : *
		assert index (line, "Operation 1") not= 0
		const typeentry := 
		    lookuptype (rules (callstack (calldepth)).resulttype)
		const argumententry := 
		    lookupclassdefinition (typevalues (typeentry).values, 
			argument)
		const argumentname := 
		    typevalues (typeentry).values (argumententry).name
		const rulename := rules (callstack (calldepth)).name
		put "" : calldepth, ">>", argumentname
		calldepth -= 1
		put "" : calldepth, ";", rulename
		get line : *
		assert index (line, "Operation 10") not= 0 % oChoice
		get line : *
		% Choice tag NN ([not] matched)
		const choicetag := strint (word (line, 3))
		assert choicetag = argument
		put "" : calldepth, "[@", rulename, " (", argumentname, ")"

		if index (line, "not") not= 0 then
		    put "" : calldepth, "| *:"
		else
		    put "" : calldepth, "| ", argumentname, ":"
		end if
	    end if

	else
	    % Non-parameterized semantic operation
	    const operationentry := 
		lookupclassdefinition (operations, operation)
	    const operationname := operations (operationentry).name

	    if operations (operationentry).resulttype not = 0 then
		% Choice semantic operation
		get line : *
		assert index (line, "Operation 10") not= 0
		get line : *
		% Choice tag NN ([not] matched)
		const choicetag := strint (word (line, 3))
		const choicetypeentry := 
		    lookuptype (operations (operationentry).resulttype)
		const choicetagentry := 
		    lookupclassdefinition (typevalues (choicetypeentry).values, 
			choicetag)
		const choicetagname := 
		    typevalues (choicetypeentry).values (choicetagentry).name
		put "" : calldepth, "[ ", operationname, " (",
		    choicetagname, ")"

		if index (line, "not") not= 0 then
		    put "" : calldepth, "| *:"
		else
		    put "" : calldepth, "| ", choicetagname, ":"
		end if

	    else
		% Update semantic operation
		put "" : calldepth, operationname
	    end if
	end if

    else
	% Pass-dependent comment line, or error message or ...
	% Not part of the trace output - simply print it.
	put "" : calldepth, line
    end if
end loop
