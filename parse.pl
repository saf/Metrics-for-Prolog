% "Parser" module. Reads all terms from a given file and
% computes various metrics of the code.

:- [xml_output, links, local, halstead].

% This module is only suitable for metrics that operate on syntactic
% features of the code and not whitespaces, comments etc.  In order to
% compute such metrics, parse the files with another module.

% read_file(+InputStream)
%   Reads all terms from InputStream and analyse each of them.
read_file(Filename) :-
	consult(Filename), % TODO Replace this with calling op/3 as in the file.
	see(Filename),
	read_terms(Terms),
	analyse(Terms, Filename).

% read_terms(-Terms)
%   Unify Terms with the list of terms (in order of appearance)
%   in the currently seen stream.
read_terms(T) :-
	read(Term),
	(Term == end_of_file ->
	 T = [],
	 seen
	;
	 T = [Term | L],
	 read_terms(L)
	).

% analyse(+Terms, +PackageName)
%   Analyse all Terms using various metrics.
analyse(T, Pack) :-
	print_xml_header(Pack), 
	links_analyse(T), 
	halstead_analyse(T), 
	local_analyse(T),
	print_xml_footer.


