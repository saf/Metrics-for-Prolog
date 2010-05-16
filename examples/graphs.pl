% Grafy skierowane.

% DAG

% connect(A, B) - istnieje sciezka z A do B.
% path(A, B, P) - P jest sciezka (lista wierzcholkow [A, P_1, ..., P_k, B]) z A do B.


% Reprezentacja termowa - lista krawedzi.

% connect(G, A, B) - istnieje w G sciezka z A do B.
connect(G, A, B) :-
	member(e(A, B), G).
connect(G, A, B) :-
	member(e(A, X), G), 
	connect(G, X, B).

% path(G, A, B, P) - istnieje w G sciezka P z A do B.
path(G, A, B, [A, B]) :-
	member(e(A, B), G).
path(G, A, B, [A | P]) :-
	member(e(A, X), G), 
	path(G, X, B, P).

test(X) :-
	X = [e(a, b), e(b, c), e(b, d), e(c, d)].

% Powyzsze dziala dla DAG-ow, a teraz path z mozliwymi cyklami.

edge(a, a).
edge(a, b).
edge(b, a).
edge(b, c).
edge(b, d).
edge(c, d).
edge(d, c).

% path_c(Start, Koniec, Sciezka)

path_c(A, B, P) :-
	path_c(A, B, [A], P). % Jaka roznice robi [] vs [A]?

path_c(A, B, _, [A, B]) :-
	edge(A, B).
path_c(A, B, Vis, [A | P]) :-
	edge(A, X), 
	% X \= A, X \= B, 
	\+(member(X, Vis)), 
	path_c(X, B, [X | Vis], P).
	
% euler(P) - dany graf jest grafem Eulera, a sciezka P 
%            przechodzi przez wszystkie krawedzie.

euler(G, [St | P]) :-
	member((St, _), G), 
	euler_traverse(G, St, P).

% euler_traverse(Graf, Wierzcholek, Sciezka)
%   w Grafie istnieje Sciezka przechodzaca dokladnie raz
%   przez wszystkie jego krawędzie, która zaczyna się w
%   wierzchołku Wierzcholek
euler_traverse([], _, []).
euler_traverse(G, V, [X | P]) :-
	member((V, X), G),
	remove(G, (V, X), G1),
	euler_traverse(G1, X, P).

% remove(L, El, S) - S jest listą powstałą z usunięcia z L
%   pierwszego wystąpienia elementu L.

remove([], _, []).
remove([El | L], El, L) :- !.
remove([H | L], El, [H | S]) :-
	H \= El,
	remove(L, El, S).

% Grafy do testowania.

graph(1, [(a, b), (b, c), (c, d), (d, a), (a, c), (c, e), (e, d), (d, b)]).



% Reprezentacja klauzulowa grafow: 

% sasiedzi(Wierzcholek, ListaSasiadow).
sasiedzi(a, [b, c, d]).
sasiedzi(b, [d]).
sasiedzi(c, [d]).
sasiedzi(d, []).


% odlegle(W1, W2, L) - L jest uporzadkowana niemalejaco wszystkich odleglosci z W1 do W2.

odlegle(A, B, L) :-
	o_bfs([A], 0,  B, [], L).

o_bfs([], _, _, [], []).
o_bfs([], Dist, Target, [H|T], L) :-
	ND is Dist + 1, 
	o_bfs([H|T], ND, Target, [], L). 
o_bfs([Target | T], Dist, Target, NextLevel, [Dist | L]) :-
	!, 
	o_bfs(T, Dist, Target, NextLevel, L). % nie wrocimy, wiec nie musimy szukac dalej w te strone.
o_bfs([Node | T], Dist, Target, NextLevel, L) :-
	Node \= Target, 
	sasiedzi(Node, S), 
	append(NextLevel, S, NS), 
	o_bfs(T, Dist, Target, NS, L).


% Graf skierowany reprezentowany jako lista krawedzi [kr(a, b)]. Drzewa binarne z reprezentacja nil | tree(L, W, P).
% Zdefiniowac predykat: drzewo(+Graf, -Drzewo), ktory dla ustalonego termu Graf odnosi sukces wtw. gdy graf jest Drzewem.

drzewo(G, D) :-
	korzen(G, K), 
	buduj(G, K, D, []).

korzen(G, W) :-
	member(kr(W, _), G),
	\+(niekorzen(G, W)).
niekorzen(G, W) :- 
	member(kr(_, W), G).

% buduj(Graf, Korzen, D, ResztaKrawedzi)
buduj(G, K, tree(L, K, R), NG) :-
	(member(kr(K, LK), G) ->
	    remove(G, kr(K, LK), GBezL), 
	    buduj(GBezL, LK, L, LG)
	;
	    LG = G,
	    L = nil
	),
	(member(kr(K, RK), LG) ->
	    remove(LG, kr(K, RK), GBezR), 
	    buduj(GBezR, RK, R, NG)
	;
	    NG = LG, 
	    R = nil
	).