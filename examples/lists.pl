% Pierwszy element listy
% pierwszy(E, Lista)
pierwszy(E, [E | _Tl]).

% ostatni(E, Lista)
ostatni(E, [E]).
ostatni(E, [_Hd | L]) :- ostatni(E, L).

% element(E, Lista)
element(E, [E | _Tl]).
element(E, [_Hd | L]) :- element(E, L).

% scal(L1, L2, Wynik)
scal([Hd | Tl], L2, [Hd | Merged]) :- scal(Tl, L2, Merged).
scal([], L2, L2).

% k-ty element
% kth(Element, K, Lista)
kth(E, 1, [E | _Tl]).
kth(E, N, [_Hd | Tl]) :- M is N-1, kth(E, M, Tl).

% srodek listy
% srodek(Element, Lista)
srodek(E, L) :- 
	dlugosc(L, N),
	M is (N + 1) // 2,
	kth(E, M, L).

% niespojna podlista
% podciag(Podciag, Lista).
podciag([], _).
podciag([Ph | Pt], [Ph | Lt]) :- podciag(Pt, Lt).
podciag([Ph | Pt], [Lh | Lt]) :- Ph \= Lh, podciag([Ph | Pt], Lt).

podciag2([], []).
podciag2([Ph | Pt], [Ph | Lt]) :- podciag2(Pt, Lt).
podciag2(P, [_ | Lt]) :- podciag2(P, Lt).

% wypisz liste. 
wypisz([]) :- write('Lista pusta'), nl, !.
wypisz([A]) :- write(A), nl, !.
wypisz([H | T]) :- write(H), write(' '), wypisz(T).


% Insertion sort
% isort(List, Sorted).

isort([], []).
isort([H | T], L) :-
	isort(T, ST),
	insert(ST, H, L).

insert([], Elem, [Elem]).
insert([H | T], Elem, [Elem, H | T]) :- 
	Elem < H, !       .
insert([H | T], Elem, [H | L]) :-
	Elem >= H, 
	insert(T, Elem, L).

% dlugosc listy
% dlugosc(Lista, Dlugosc).

dlugosc([], 0).
dlugosc([_H | T], N) :-
	dlugosc(T, NT),
	N is NT + 1.
	

suma([], 0).
suma([H | T], S) :-
	suma(T, ST),
	S is ST + H.

% Sumo - suma z listy ogonowo
% sumo(Lista, Suma).
sumo(L, S) :-
	sumo(L, 0, S).

% sumo(Lista, Akumulator, Suma)
sumo([], Acc, Acc).
sumo([H | T], Acc, S) :-
	NewAcc is H + Acc,
	sumo(T, NewAcc, S).

% reverse - odwroc liste
% reverse(Lista, Odwrocona)
reverse(L, R) :-
	reverse(L, [], R).

% reverse(Lista, Akumulator, Odwrocona)
reverse([], Acc, Acc).
reverse([H | T], Acc, R) :-
	reverse(T, [H | Acc], R).

% dlugosc ogonowo
% dlugosc(Lista, Dlugosc).
dlugog(L, N) :-
	dlugog(L, 0, N).
% dlugosc(Lista, Akumulator, N)
dlugog([], Acc, Acc).
dlugog([_H | T], Acc, N) :-
	N1 is Acc + 1,
	dlugog(T, N1, N).

% Palindrom - czy lista L jest palindromem?

palindrom(L) :-
	palindrom(L, []).

% Palindrom(Lista, OdwroconaGlowa)
palindrom(L, L).
palindrom([_H | T], T).
palindrom([H | T], Acc) :-
	palindrom(T, [H | Acc]).


% Czy slowo L jest postaci a^nb^n ? 
slowo(L) :-
	slowo(L, []).

slowo([b | T], [b | T]). % niepuste
slowo([a | T], Acc) :-
	slowo(T, [b | Acc]).

% rslowo(L, R) - rozpoznaj L = a^nb^nR, daj reszte R.

rslowo(L, R) :-
	rslowo(L, [], R).

rslowo([b | L], B, R) :-
	append(B, R, [b | L]).
rslowo([a | L], Acc, R) :-
	rslowo(L, [b | Acc], R).

rslowo2(L, R) :- append(X, R, L), slowo(X).

% flagaPolska(L, F) - L jest lista nad {'b', 'c'}, F lista posortowana.

flagaPolska(L, F) :-
	flagaPolska(L, [], F).

flagaPolska([], C, C).
flagaPolska([b | L], C, [b | F]) :-
	flagaPolska(L, C, F).
flagaPolska([c | L], C, F) :-
	flagaPolska(L, [c | C], F).

% Uogolnienie. Sortujemy liste z elementami dwoch rodzajow, 
% mniejszy jest ten na poczatku listy.
% sort2(Lista, Posortowana).

sort2(L, F) :-
	sort2(L, _, _, [], F).

sort2([], _, _, A, A).
sort2([Lo | T], Lo, Hi, A, [Lo | F]) :-
	!, 
	sort2(T, Lo, Hi, A, F).
sort2([Hi | T], Lo, Hi, A, F) :-
	Hi \= Lo,                  % Bez tego dla zapytan ustalonych wykonywala sie ta regula.
	sort2(T, Lo, Hi, [Hi | A], F).

% Quicksort
% quicksort(List, Sorted)
quicksort([], []).
quicksort([H | T], S) :-
	split(T, H, Lower, Higher), 
	quicksort(Lower, Slower),
	quicksort(Higher, Shigher),
	append(Slower, [H | Shigher], S).

% split(L, Elem, Lo, Hi, Diff)
% podzial listy L na elementy nie wieksze (Lo) i wieksze (Hi) od El
% Diff jest roznica dlugosci list: len(Lo) - len(Hi).

split([], _, [], [], 0).
split([H | T], El, [H | Lo], Hi, Diff) :-
	H =< El, 
	split(T, El, Lo, Hi, ND),
	Diff is ND + 1.
split([H | T], El, Lo, [H | Hi], Diff) :-
	H > El,
	split(T, El, Lo, Hi, ND),
	Diff is ND - 1.

% bez append, z aku
quicksort2([H | T], S) :-
	quicksort2([H | T], [], S).

quicksort2([], A, A).
quicksort2([H | T], A, S) :-
	split(T, H, Lower, Higher, Diff), 
	(Diff >= 0 ->
	    quicksort2(Higher, A, Shigher),
	    quicksort2(Lower, [H | Shigher], S)
	;
	    quicksort2(Lower, [H | Shigher], S),
	    quicksort2(Higher, A, Shigher)
	).

% Warto wolac najpierw rekurencyjnie quicksort2 dla krotszej listy
% - mniejszy maksymalny poziom rekursji (maks. log n)


% List.flatten z "nieograniczona glebokoscia"
% flatten(ListaList, SplaszczonaLista)

rflatten([], []).
rflatten([[HH | HT] | T], F) :-
	!, 
	rflatten(T, TF),
	rflatten([HH | HT], HF),
	append(HF, TF, F).
rflatten([H | T], [H | F]) :-
	rflatten(T, F).

% rflatten z akumulatorem
arflatten(L, R) :- arflatten(L, [], RR), reverse(RR, R).

arflatten([], A, A).
arflatten([[HH | HT] | T], A, F) :-
	!, 
	arflatten([HH | HT], A, AHF),
	arflatten(T, AHF, F).
arflatten([H | T], A, F) :-
	arflatten(T, [H | A], F).

% rflatten z akumulatorem bez reverse

nrarflatten(L, F) :- nrarflatten(L, [], F).

nrarflatten([], A, A) :- !.
nrarflatten([H | T], A, F) :-
	!, 
	nrarflatten(H, FT, F),
	nrarflatten(T, A, FT).
nrarflatten(El, A, [El | A]) :-
	atomic(El).                % potrzebne dla zapytan ustalonych

% Wyslij slowo2

frslowo([a | L], R) :- frslowo(L, [a | R]).
frslowo(R, R). % dla n >= 0 - co dla n >= 1?




% Komputerowka MM'2007
% Podlisty(Lista, Podlisty)

podziel_secure(L, P) :-
	podziel_secure(L, [], P).

podziel_secure([], [], []).
podziel_secure([H | T], [], [[H] | P]) :-
	podziel_secure(T, [], P).
podziel_secure([H | T], A, P) :-
	append(A, [H], NA), 
	podziel_secure(T, NA, P).
podziel_secure([H | T], [H | A], [L | P]) :-
	append([H | A], [H], L),
	podziel_secure(T, [], P).

podziel([], []).
podziel(L, P) :-
	podziel(L, _, [], P).

podziel([], _, [], []).
podziel([H | T], _, [], [[H] | P]) :-
	podziel(T, _, [], P).


% AZ'2005: Edytor
% edytor(Lista, Wynik)

edytor(L, W) :-
	edytor(L, [], [], W).

edytor([], [], W, W).
edytor([], [H | T], After, W) :-
	edytor([], T, [H | After], W).

edytor([znak(C) | T], Before, After, W) :-
	edytor(T, [C | Before], After, W).
edytor([backspace | T], [_ | Before], After, W) :-
	edytor(T, Before, After, W).
edytor([left | T], [H | Before], After, W) :-
	edytor(T, Before, [H | After], W).
edytor([right | T], Before, [H | After], W) :-
	edytor(T, [H | Before], After, W).


flatten(L, F) :- flatten(L, [], F).

flatten([], A, A).
flatten([H | T], A, R) :-
	append(H, NA, R),
	flatten(T, A, NA).

unimember(L, El) :-
	unimember(L, no, El).

unimember([], yes, _).
unimember([H | T], no, H) :-
	!, 
	unimember(T, yes, H).
unimember([H | T], no, El) :-
	El \= H,
	unimember(T, no, El).
unimember([H | T], yes, El) :-
	El \= H,
	unimember(T, yes, El).
	