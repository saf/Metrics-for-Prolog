% Sławomir Rudnicki

% wn(L) - dla ustalonej listy L, której elementami są pewne stałe, 
%   odniesie sukces wtw L reprezentuje poprawne wyrazenie nawiasowe, 
%   tj. kazdej stalej mozna przyporzadkowac 1-1 odpowiedni nawias.

wn(L) :-
	wn(L, [], []).

% wn(L, N, P, O) :
%  L - lista do przetworzenia, 
%  P - lista par symboli postaci nawias otw. - nawias zam.
%  O - "stos" otwartych nawiasow (symboli uznanych za nawiasy otwierajace)

%wn([], _, _, []).
%wn([H | T], S, P, [G | Otw]) :- % H domyka nawias z G na podstawie istniejacego przyporzadkowania.
%	member((G, H), P), 
%	wn(T, S, P, Otw).
%wn([H | T], S, P, [G | Otw]) :- % nowy symbol H domyka G, tworzac nowe przyporzadkowanie.
%	\+(member((_, H), P)), 
%	\+(member((G, _), P)), 
%	\+(member(H, S)),
%	H \= G, 
%	wn(T, [H | S], [(G, H) | P], Otw).
%wn([H | T], S, P, Otw) :-       % H jest nowym symbolem i otwiera nowy nawias.
%	\+(member(H, S)), 
%	wn(T, [H | S], P, [H | Otw]).
%wn([H | T], S, P, Otw) :-       % H juz wystapil, a teraz otwiera nowy nawias.
%	member(H, S), 
%	\+(member((_, H), P)), 
%	wn(T, S, P, [H | Otw]).

% "If it ain't broke, don't fix it..."
	
wn([], _, []).
wn([H | T], P, [G | Otw]) :- % H domyka nawias z G na podstawie istniejacego przyporzadkowania.
	member((G, H), P), 
	wn(T, P, Otw).
wn([H | T], P, [G | Otw]) :- % nowy symbol H domyka G, tworzac nowe przyporzadkowanie.
	\+(member(H, [G | Otw])), 
	\+(member((_, H), P)), 
	wn(T, [(G, H) | P], Otw).
wn([H | T], P, Otw) :-       % H otwiera nowy nawias.
	\+(member((_, H), P)), 
	wn(T, P, [H | Otw]).