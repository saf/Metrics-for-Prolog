% Helper module for XML output of MFPL's Prolog interface.

print_xml_header :-
	print('<mfpl version="1.0">'),
	nl.

print_xml_footer :-
	print('</mfpl>'),
	nl.