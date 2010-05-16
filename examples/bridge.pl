% Bridge double-dummy deal analysis tool.

:- op(500, xfx, ['--']).

% Minimax(AktualnyGracz, AktualnaLewa, Rece, Rozgrywajacy

minimax(_, [], [[] | _] -- _, _, 0).

minimax([], [Hand | T] -- X, opponent, Tricks) :-
	min_value(Hand, Tricks).
minimax([], [Hand | T] -- X, declarer, Tricks) :-
	max_value(Hand, Tricks).

minimax([Lead | T], [Hand | Other] -- X, opponent, Tricks) :-
	available(Hand, Lead, Available),
	min_value(Available, [Lead | T], Tricks).
minimax([Lead | T], [Hand | Other] -- X, declarer, Tricks) :-
	available(Hand, Lead, Available),
	max_value(Available, Tricks).

min_value(Choices, Best) :-
	min_value([Choices | L] -- L, Empty -- Empty, 0, Best).

min_value(L -- _, N, N) :-
	!, 
	var(L).
min_value([Card | T] -- L, Other -- M, N, NN) :-
	minimax(

	
lho(north, east).
lho(east, south).
lho(south, west).
lho(west, north).

opponent(north, east).
opponent(east, north).
opponent(south, east).
opponent(east, south).
opponent(north, west).
opponent(west, north).
opponent(south, west).
opponent(west, south).