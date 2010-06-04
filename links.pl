% For the analysed package, determine:
%   * the list of packages it consults,
%   * the list of predicates it defines.

:- module(links, [links_analyse/1]).

% links_analyse(+Terms)
%   Print XML information about the packages consulted by Terms
links_analyse(Terms) :-
	consults(Terms, Files),
	xml_print_header,
	xml_print_consults(Files),
	xml_print_footer.

% consults(+Terms, -Files)
%   Files is unified with the list of all filenames of files
%   consulted within Terms.
consults([], []).
consults([:-([CH | CT]) | T], Consults) :-
        !,                            % Red cut for simplicity
	append([CH | CT], TC, Consults),
	consults(T, TC).
consults([:-(consult(F)) | T], [F | TC]) :-
        !,
        consults(T, TC).
consults([_ | T], TC) :-
	consults(T, TC).

% XML Output

xml_print_header :-
	print('  <links>'),
	nl.

xml_print_footer :-
	print('  </links>'),
	nl.

xml_print_consults([]).
xml_print_consults([F | T]) :-
	format('    <consult ref="~w" />~n', [F]),
	xml_print_consults(T).

xml_print_calls([]).
xml_print_calls([P | T]) :-
	format('    <call predicate="~w" />~n', [P]),
	xml_print_calls(T).

xml_print_defines([]).
xml_print_defines([P | T]) :-
	format('    <def predicate="~w" />~n', [P]),
	xml_print_defines(T).