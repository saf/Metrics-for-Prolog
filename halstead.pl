% Halstead metrics module.

:- module(halstead, [halstead_analyse/1]).

halstead_analyse(Terms) :-
	term_vocab(Terms, V, []).

term_vocab([], V, V).
term_vocab([H | T], V, V).
	
	

