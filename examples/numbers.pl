

% N is M + 1, obsluguje wszystkie zapytania.
succ(M, N) :-
	nonvar(M), var(N),
	N is M + 1.
succ(M, N) :-
	nonvar(N), var(M),
	M is N - 1.
succ(M, N) :-
	nonvar(N), nonvar(M), 
	M is N - 1.


% fib(K, N) <==> N jest K-ta liczba Fibonacciego
% F_0 = 0, F_1 = 1,
% F_(n+2) = F_n + F_(n+1).
% Wszystkie zapytania.

fib(0, 0).
fib(1, 1).
fib(K, N) :-
	if(nonvar(K), K > 1, true),
	fib(K, N, 1, 1, 2).

% K-ta liczba Fibonacciego jest N, I przebiega 2..K, N1 = F_I, N2 = F_(I-1).
fib(K, N, _, N, K).
fib(K, N, N2, N1, I) :-
	if(nonvar(K), I =< K, true), 
	if(nonvar(N), N1 =< N, true),
	N0 is N2 + N1, 
	I1 is I + 1,
	fib(K, N, N1, N0, I1).
