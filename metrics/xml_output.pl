% Helper module for XML output of MFPL's Prolog interface.

print_xml_header(F) :-
	format('<package src="~w">~n', [F]).

print_xml_footer :-
	format('</package>~n').
