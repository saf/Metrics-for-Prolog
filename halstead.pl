% Halstead metrics module.

:- module(halstead, [halstead_analyse/1]).

% halstead_analyse(+Terms)
%   Perform analysis of Terms and print out the results.
halstead_analyse(Terms) :-
	empty_vocab(E),
	terms_vocab(Terms, E, V),
	all_operands(V, AllOperands),
	all_operators(V, AllOperators),
	unique_operands(V, UniqueOperands),
	unique_operators(V, UniqueOperators),
	Vocabulary is UniqueOperators + UniqueOperands, 
	Length is AllOperators + AllOperands,
	Volume is Length * log(Vocabulary) / log(2),
	Difficulty is (UniqueOperators * AllOperands) / (UniqueOperands * 2),
	Effort is Volume * Difficulty,
	Time is Effort / 18,
	print((Vocabulary, Length, Volume, Difficulty, Effort, Time)), nl.
	

% empty_vocab
%   Defines what is an empty vocabulary.
empty_vocab(([], [])).

% terms_vocab(+Terms, +OldVocab, -NewVocab)
terms_vocab([], V, V).
terms_vocab([H | T], V, W) :-
	term_vocab(H, V, N),
	terms_vocab(T, N, W).

% term_vocab(+Term, +OldVocab, -NewVocab)
term_vocab(T, V, W) :-
	subterm_vocab(T, V, X),
	add_operator(X, '.', W).

% subterms_vocab(+Terms, +OldVocab, -NewVocab)
%   Terms is a list of subterms to analyse.
subterms_vocab([], V, V).
subterms_vocab([H | T], V, W) :-
	subterm_vocab(H, V, N),
	subterms_vocab(T, N, W).

% subterm_vocab(+Term, +OldVocab, -NewVocab)
subterm_vocab(T, V, W) :-
	nonvar(T), 
	T =.. [S | Args],
	current_op(_, _, S),
	!,
	add_operator(V, S, V1),
	subterms_vocab(Args, V1, W).
subterm_vocab(T, V, W) :-
	nonvar(T), 
	T =.. [S | Args],
	\+ current_op(_, _, S),
	add_operand(V, S, V1),
	add_operator(V1, '()', V2), 
	subterms_vocab(Args, V2, W).
subterm_vocab(T, V, W) :-
	var(T),
	!,
	add_operand(V, T, W).

% add_operator(+OldVocab, +Operator, -NewVocab)
add_operator((Operators, Operands), Op, (NewOperators, Operands)) :-
	add_occurrence(Operators, Op, NewOperators).

% add_operand(+OldVocab, +Operand, -NewVocab)
add_operand((Operators, Operands), Op, (Operators, NewOperands)) :-
	add_occurrence(Operands, Op, NewOperands).

% add_occurrence(+List, +Elem, -NewList)
add_occurrence([], El, [(El, 1)]).
add_occurrence([(HEl, HNo) | T], El, [(HEl, NHNo) | T]) :-
	HEl == El,
	!,
	NHNo is HNo + 1.
add_occurrence([(HEl, HNo) | T], El, [(HEl, HNo) | NT]) :-
	HEl \== El,
	add_occurrence(T, El, NT).


% all_operands(+V, -AO)
%   Unify AO with the number of all operands in the vocabulary V
all_operands((_, Operands), AO) :-
	snd_sum(Operands, AO).

% all_operators(+V, -AO)
%   Unify AO with the number of all operators in the vocabulary V
all_operators((Operators, _), AO) :-
	snd_sum(Operators, AO).

% unique_operators(+V, -UO)
unique_operators((Operators, _), UO) :-
	length(Operators, UO).

% unique_operands(+V, -UO)
unique_operands((_, Operands), UO) :-
	length(Operands, UO).

% snd_sum(+List, -Sum)
%   List is a list of pairs (A, B), where B is a number. Compute the
%   Sum of all B's on the list.
snd_sum([], 0).
snd_sum([(_, B) | T], S) :-
	snd_sum(T, TS),
	S is B + TS.

