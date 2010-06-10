% Halstead metrics module.

:- module(halstead, [halstead_analyse/1]).

% halstead_analyse(+Terms)
%   Perform analysis of Terms and print out the results.
halstead_analyse(Terms) :-
	terms_vocabs(Terms, [], Vocabs),
	%summary_vocab(Vocabs, Summary),
	%vocab_metrics(Summary, Metrics),   % Global metrics commented out.
	xml_print_header, 
	%xml_print_metrics(Metrics),
	xml_print_predicate_metrics(Vocabs),
	xml_print_footer.
	
% empty_vocab
%   Defines what an empty vocabulary is.
empty_vocab(([], [])).

% terms_vocabs(+Terms, -Vocabs)
%   Vocabs is a list of the form [ voc(Predicate, Vocabulary) | ... ].
terms_vocabs([], Vocabs, Vocabs).
terms_vocabs([H | T], Vocabs, NewVocabs) :-
	term_vocab(H, Pred, Vocab), 
	merge_vocabs(Vocabs, Pred, Vocab, Merged), 
	terms_vocabs(T, Merged, NewVocabs).

% term_vocab(+Term, -PredName, -Vocab)
term_vocab(T, '[commands]', V) :-
	functor(T, :-, 1), 
	!, 
	empty_vocab(E), 
	subterm_vocab(T, E, W),
	add_operator(W, '.', V).
term_vocab(T, S/Arity, V) :-
	functor(T, :-, 2), 
	!, 
	T =.. [:-, L | _], 
	functor(L, S, Arity), 
	empty_vocab(E), 
	subterm_vocab(T, E, W), 
	add_operator(W, '.', V).
term_vocab(T, S/Arity, V) :-
	\+ functor(T, :-, _), 
	functor(T, S, Arity), 
	empty_vocab(E), 
	subterm_vocab(T, E, W), 
	add_operator(W, '.', V).

% subterms_vocab(+Terms, +OldVocab, -NewVocab)
%   Terms is a list of subterms to analyse.
subterms_vocab([], V, V).
subterms_vocab([H | T], V, W) :-
	subterm_vocab(H, V, N),
	subterms_vocab(T, N, W).

% subterm_vocab(+Term, +OldVocab, -NewVocab)
subterm_vocab(T, V, W) :-
	nonvar(T),
	T == [H | L], 
	!,                             % Red cut in fact, but we want
	add_operator(V, '[|]', V1),    % special handling here.
	subterms_vocab([H, L], V1, W).
subterm_vocab(T, V, W) :-
	nonvar(T), 
	T =.. [S | Args],
	atom(S), 
	current_op(_, _, S),
	!,
	add_operator(V, S, V1),
	subterms_vocab(Args, V1, W).
subterm_vocab(T, V, W) :-
	nonvar(T),
	!, 
	T =.. [S | Args],
	\+ (atom(S), current_op(_, _, S)), 
	add_operand(V, S, V1),
	add_operator(V1, '()', V2), 
	subterms_vocab(Args, V2, W).
subterm_vocab(T, V, W) :-
	var(T),
	!,
	add_operand(V, T, W).

% Vocabulary management

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

% summary_vocab(+Vocabs, +SummaryVocab)
%   Merge all Vocabs.
summary_vocab(Vocab, Summary) :-
	summary_vocab(Vocab, ([], []), Summary).
% summary_vocab(+Vocabs, +SummarySoFar, -Summary)
summary_vocab([], S, S).
summary_vocab([voc(_, (Oprs, Opnds)) | T], (TOprs, TOpnds), Summary) :-
	merge_vocab(Oprs, TOprs, SOprs), 
	merge_vocab(Opnds, TOpnds, SOpnds), 
	summary_vocab(T, (SOprs, SOpnds), Summary).

% merge_vocabs(+OldVocabs, +Predicate, +Vocab, -NewVocabs)
%   Merge voc(Predicate, Vocab) into OldVocabs.
merge_vocabs([], P, V, [voc(P, V)]).
merge_vocabs([voc(P, (Oprs, Opnds)) | T], P, (POprs, POpnds), [voc(P, (NOprs, NOpns)) | T]) :-
	!, 
	merge_vocab(Oprs, POprs, NOprs), 
	merge_vocab(Opnds, POpnds, NOpns).
merge_vocabs([voc(C, CV) | T], P, V, [voc(C, CV) | NT]) :-
	C \= P, 
	merge_vocabs(T, P, V, NT).

% merge_vocab(+V1, +V2, -Merged)
merge_vocab([], V2, V2).
merge_vocab([H | T], V2, Merged) :-
	merge_entry(V2, H, M), 
	merge_vocab(T, M, Merged).

% merge_entry(+Vocabulary, +Entry, -NewVocabulary)
merge_entry([], Entry, [Entry]).
merge_entry([(Key, Value) | T], (EKey, EVal), [(Key, NVal) | T]) :-
	Key == EKey, 
	!, 
	NVal is Value + EVal.
merge_entry([(Key, Val) | T], (EKey, EVal), [(Key, Val) | NT]) :-
	Key \== EKey, 
	merge_entry(T, (EKey, EVal), NT).


% vocab_metrics(+Vocab, -Metrics)
vocab_metrics(V, [length(Length), vocabulary(Vocabulary), 
   volume(Volume), difficulty(Difficulty), effort(Effort), time(Time)]) :-
	all_operands(V, AllOperands),
	all_operators(V, AllOperators),
	unique_operands(V, UniqueOperands),
	unique_operators(V, UniqueOperators),
	Vocabulary is UniqueOperators + UniqueOperands, 
	Length is AllOperators + AllOperands,
	Volume is Length * log(Vocabulary) / log(2),
	Difficulty is (UniqueOperators * AllOperands) / (UniqueOperands * 2),
	Effort is Volume * Difficulty,
	Time is Effort / 10.

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

% XML printing

xml_print_header :-
	print('  <halstead>'),
	nl.

xml_print_footer :-
	print('  </halstead>'),
	nl.

% print_predicate_metrics(+Vocabs) 
%   Print metrics gathered from Vocabs.
xml_print_predicate_metrics([]).
xml_print_predicate_metrics([voc(Pred, V) | T]) :-
	vocab_metrics(V, M), 
	format('    <predicate name="~w">~n', [Pred]),
	xml_print_metrics(M),
	format('    </predicate>~n'),
	xml_print_predicate_metrics(T).

xml_print_metrics([]).
xml_print_metrics([H | T]) :-
	H =.. [Name, Value],
	format('      <~w>~w</~w>~n', [Name, Value, Name]),
	xml_print_metrics(T).
	
