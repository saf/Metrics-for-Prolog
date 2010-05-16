field(1, 1, num(1)).
field(1, 2, _).
field(1, 3, num(2)).
field(1, 4, _).
field(1, 5, num(3)).
field(2, 1, _).
field(2, 2, _).
field(2, 3, _).
field(2, 4, _).
field(2, 5, _).
field(3, 1, num(1)).
field(3, 2, _).
field(3, 3, _).
field(3, 4, _).
field(3, 5, _).
field(4, 1, _).
field(4, 2, _).
field(4, 3, _).
field(4, 4, _).
field(4, 5, num(4)).
field(5, 1, num(1)).
field(5, 2, _).
field(5, 3, _).
field(5, 4, _).
field(5, 5, _).

valid(river).
valid(island).

valid_field(A, B) :-
	field(A, B, F),
	ground(F),
	!.
valid_field(A, B) :-
	field(A, B, F),
	var(F), 
	valid(F).

solve :-
	all_valid,
	islands_ok,
	no_pools,
	river_contingent,
	write_fields.

all_valid :-
	all_valid(1, 1).

all_valid(5, 5) :-
	!, 
	valid_field(5, 5).
all_valid(X, 5) :-
	X < 5,
	!, 
	valid_field(X, 5),
	NX = X + 1,
	all_valid(NX, 1).
all_valid(X, Y) :-
	X =< 5, Y < 5,
	valid_field(X, Y),
	NY = Y + 1,
	all_valid(X, NY).

islands_ok.
no_pools.
river_contingent.


write_fields :-
	write_fields(1, 1).

write_fields(5, 5) :-
	!, 
	field(5, 5, F),
	write(F),
	nl.
write_fields(X, 5) :-
	X < 5, 
	!,
	field(X, 5, F),
	write(F),
	nl,
	NX is X + 1,
	write_fields(NX, 1).
write_fields(X, Y) :-
	X =< 5, Y < 5,
	field(X, Y, F),
	write(F),
	NY is Y + 1,
	write_fields(X, NY).
	
	
	
