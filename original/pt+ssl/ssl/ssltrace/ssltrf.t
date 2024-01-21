% Symbolic trace filter for use with ssltrace.
% Filters out all but the part of a trace executed inside
% a specified S/SL rule.
% J.R. Cordy, Queen's University, 10 Jan 1990

include "%system"

% Name fo the rule we're looking for
const rulename := fetcharg (1)

% Flag and level to indicate when we're in it
var traceon := false
var tracelevel := 0

loop
    exit when eof
    var s : string
    get s : *

    if index (s, "@") not= 0 then
	if index (s, rulename) not= 0 then
	    % We just called the rule of interest
	    traceon := true
	    tracelevel := index (s, "@") + 1
	end if
    end if

    if traceon then
	% We're executing inside the interesting rule - show it
	put s

	if index (s, ">>") = tracelevel then
	    % We just returned from the rule of interest
	    traceon := false
	end if
    end if
end loop
