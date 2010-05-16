% Read a file or stdin and analyse all read terms.


read_file(Filename) :-
	see(Filename), 
	read_terms.

% read_terms
%   Read all terms from the currently seen stream
%   and analyse each of them.
read_terms :-
	read(end_of_file),
	!, 
	seen.               % End of input.
read_terms :-
	read(Term),
	analyse(Term),
	read_terms.

% analyse(Term)
% Perform analysis of the term T using various metric engines.
analyse([]) :- !.
analyse([H | T]) :-
	analyse(H),
	analyse(T).
analyse(T) :-
	
	
