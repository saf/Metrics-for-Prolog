%Reprezentacja drzewa binarnego
%
%Drzewo puste: nil,
%Drzewo binarne: tree(Lewe, Wierzcholek, Prawe).

% drzewo(D). Czy D jest drzewem binarnym?

drzewo(nil).
drzewo(tree(L, _, R)) :-
	drzewo(L), 
	drzewo(R).

% BST nad liczbami całkowitymi

% bstinsert(Drzewo, Element, NoweDrzewo)
bstinsert(nil, El, tree(nil, El, nil)).
bstinsert(tree(L, W, R), El, tree(NL, W, R)) :-
	El =< W, 
	!, 
	bstinsert(L, El, NL).
bstinsert(tree(L, W, R), El, tree(L, W, NR)) :-
	El > W,
	bstinsert(R, El, NR).
	
% createbst(Lista, Drzewo) - stworz drzewo z elementow listy.

createbst(L, D) :-
	createbst(L, nil, D).

createbst([], D, D).
createbst([H | T], A, D) :-
	bstinsert(A, H, NA),
	createbst(T, NA, D).

% wypiszbst(D) - wypisz zawartosc drzewo

wypiszbst(nil).
wypiszbst(tree(L, W, R)) :-
	wypiszbst(L),
	write(W), 
	nl, 
	wypiszbst(R).

% elements(D, L) - L jest lista elementow drzewa D.



% bstsort(L, S) - posortuj liste l z wykorzystaniem BST.


% liscie(D, L) - L jest lista lisci D uporzadkowana od lewej do prawej.





