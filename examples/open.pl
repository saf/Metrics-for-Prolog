:- op(500, xfx, '--').

% poziomy(Drzewo, Lista)
%   Drzewo jest binarne i zawiera listy różnicowe.
%   Lista jest unifikowana z listą list stanowiacych
%   konkatenacje list z poszczegolnych jego poziomow.
poziomy(nil, []).
poziomy(tree(Left, List -- [], Right), [List | L]) :-
	poziomy([Left, Right, end | R] -- R, X--X, L).

% poziomy(Kolejka, ObecnyPoziom, Poziomy)
poziomy(Q, R, _) :-
	write(Q), nl, write(R), nl, nl, fail.
poziomy([end | T] -- _, X -- X, []) :-
	var(T),
	!.
poziomy([end | T] -- _, P -- [], [P | []]) :-
	var(T),
	!.
poziomy([end | T] -- [end | R], P -- [], [P | L]) :-
	nonvar(T), 
	poziomy(T -- R, X -- X, L).
poziomy([nil | T] -- R, P -- TP, L) :-
	poziomy(T -- R, P -- TP, L).
poziomy([tree(Left, Head -- Tail, Right) | R] -- [Left, Right | RT], P -- Head, L) :-
	poziomy(R -- RT, P -- Tail, L).


	