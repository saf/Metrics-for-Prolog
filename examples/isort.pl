% isort(List, Sorted)

isort([H | T], L) :-
	isort(T, L1),
	insert(L1, H, L).
isort([], []).


% insert(List, Element, ListWithElement)

insert([H | T], Elem, [Elem, H | T]) :-
	Elem =< H.
insert([H | T], Elem, [H | L]) :-
	Elem > H,
	insert(T, Elem, L).
insert([], Elem, [Elem]).

	