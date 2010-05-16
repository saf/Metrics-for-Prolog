% "Parser" module. Reads all terms from a given file and
% computes various metrics of the code.

:- [halstead].

% This module is only suitable for metrics that operate on syntactic
% features of the code and not whitespaces, comments etc.  In order to
% compute such metrics, parse the files with another module.

% read_file(+InputStream)
%   Reads all terms from InputStream and analyse each of them.
read_file(Stream) :-
	see(Stream),
	read_terms(Terms),
	analyse(Terms).

% read_terms(-Terms)
%   Unify Terms with the list of terms (in order of appearance)
%   in the currently seen stream.
read_terms([]) :-
	read(end_of_file),
	!, 
	seen.               % End of input.
read_terms([H | T]) :-
	read(H),
	read_terms(T).

% analyse(+Terms)
%   Analyse all Terms using various metrics.
analyse(T) :-
	halstead_analyse(T).


