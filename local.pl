% Markusz & Kaposi's local complexity measure for Prolog.

:- module(local, [local_analyse/1]).

% local_analyse(+Terms)
%   Perform local complexity analysis of Terms
local_analyse(Terms) :-
	predicate_complexity(Terms, AnnotatedPredicates),
	xml_print_header, 
	xml_print_result(AnnotatedPredicates),
	xml_print_footer.

% predicate_complexity(+Terms, -Predicates)
predicate_complexity(Terms, AnnotatedPredicates) :-
	partitions_complexity(Terms, AnnotatedTerms), 
	merge_predicates(AnnotatedTerms, AnnotatedPredicates).

% partitions_complexity(+Terms, -AnnotatedTerms) 
%   AnnotatedTerms is unified with the list of all partitions
%   (described by their predicate name and arity) and their
%   complexity.
partitions_complexity([], []).
partitions_complexity([H | T], AT) :-
	\+ predicate_name(H, _), 
	!, 
	partitions_complexity(T, AT).
partitions_complexity([H | T], [part(Pred, C) | AT]) :-
	predicate_name(H, Pred),
	partition_complexity(H, C), 
	partitions_complexity(T, AT).

% predicate_name(+Term, -Name)
%   Succeeds whenever Term is a partition. Name is the
%   name and arity of the defined relation.
predicate_name(:-(C, _), N/A) :-
	functor(C, N, A).

% merge_predicates(+Partitions, -Predicates)
%   Complexity values of Partitions are merged for 
%   repeating symbol/arity values.
merge_predicates(Partitions, Predicates) :-
	merge_predicates(Partitions, [], Predicates).

merge_predicates([], Ps, Ps).
merge_predicates([H | T], Ps, NPs) :-
	merge_predicate(Ps, H, N), 
	%print((Ps, H, N)), nl, nl, 
	merge_predicates(T, N, NPs).

% merge_predicate(+Predicates, +Partition, -NewPredicates)
%   Merge a single partition information into Predicates
merge_predicate([], part(P, C), [pred(P, [C])]).
merge_predicate([pred(P, L) | T], part(P, C), [pred(P, [C | L]) | T]) :- 
	!.
merge_predicate([pred(R, CR) | T], part(P, C), [pred(R, CR) | NT]) :-
	R \= P, 
	merge_predicate(T, part(P, C), NT).

%
% PARTITION COMPLEXITY
%

% partition_complexity(+Term, -Complexity)
%   The local complexity value of the given partition.
partition_complexity(T, C) :-
	new_entities(T, P1),
	subproblems(T, P2),
	relations_complexity(T, P3),
	new_variables(T, P4),
	C = P1 + P2 + P3 + P4.

% new_entities(+Term, -C)
%    Unify C with the number of new data entities introduced in 
%    the positive side of the partition.
%    In other words, C is the number of non-trivial variables in
%    the left side of the partition.
new_entities(:-(L, _), C) :-
        L =.. [_ | Args],
	count_nontrivial_variables(Args, 0, C).

% count_nontrivial_variables(+Terms, +Accumulator, -Variables)
%   Count all variables inside Terms, excluding Terms themselves
%   if they are variables.
count_nontrivial_variables([], A, A).
count_nontrivial_variables([H | T], A, C) :-
	var(H),
	!,
	count_nontrivial_variables(T, A, C).
count_nontrivial_variables([H | T], A, C) :-
	nonvar(H),
	count_variables([H], 0, V),
	NA is A + V,
	count_nontrivial_variables(T, NA, C).

% count_variables(+Terms, +Accumulator, -Variables)
%   Count all variables in Terms.
count_variables([], A, A) :- !.
count_variables([H | T], A, V) :-
	var(H),
	!,
	NA is A + 1,
	count_variables(T, NA, V).
count_variables([H | T], A, V) :-
	nonvar(H), 
	functor(H, S, _),
	atom(S),
	!,
	H =.. [S | Args],
	count_variables(Args, 0, NV),
	NA is A + NV,
	count_variables(T, NA, V).
count_variables([H | T], A, V) :-
	nonvar(H),
	(\+functor(H, S, _) ; functor(H, S, _), \+ atom(S)), 
	count_variables(T, A, V).

% subproblems(+Term, -C)
%    Unify C with the number of negative atoms in the partition.
subproblems(:-(_, R), C) :-
        count_subproblems(R, 0, C).

% count_subproblems(+Term, +Accumulator, -Subproblems)
count_subproblems(T, A, S) :-
	(functor(T, ',', 2);
	 functor(T, ';', 2);
	 functor(T, '->', 2);
	 functor(T, '*->', 2)), 
	!,                       % Red cut for simplicity.
	T =.. [_, X, Y], 
	count_subproblems(X, A, NA),
	count_subproblems(Y, NA, S).
count_subproblems(_, A, C) :-
	C is A + 1.

% relations_complexity(+T, -C)
%    Unify C with the complication coefficient of the partition.
%    Each recursive call adds 2 here. Each disjunction operator (;), 
%    or implication operator (->, *->) adds 1.
relations_complexity(:-(L, R), C) :-
	functor(L, P, A),
	!, 
	relations_complexity([R], P/A, 0, C).
relations_complexity(_, 0).         % Red cut for simplicity.

% relations_complexity(+Terms, +Predicate, +Accumulator, -Complexity)
relations_complexity([], _, C, C).
relations_complexity([H | T], P/A, Acc, C) :-
	var(H),
	!,
	relations_complexity(T, P/A, Acc, C).
relations_complexity([H | T], P/A, Acc, C) :-
	nonvar(H), 
	functor(H, P, A), 
	!, 
	NAcc is Acc + 2,
	relations_complexity(T, P/A, NAcc, C).
relations_complexity([H | T], P/A, Acc, C) :-
	nonvar(H),
	(functor(H, '->', 2); functor(H, ';', 2); functor(H, '*->', 2)),
	H =.. [_ | Args], 
	NAcc is Acc + 1,
	relations_complexity(Args, P/A, NAcc, NNAcc),
	relations_complexity(T, P/A, NNAcc, C).
relations_complexity([H | T], P/A, Acc, C) :-
	nonvar(H),
	functor(H, S, Ar),
	(P, A) \= (S, Ar),
	S/Ar \= '->'/2,
	S/Ar \= ';'/2,
	S/Ar \= '*->'/2, 
	H =.. [S | Args], 
	relations_complexity(Args, P/A, Acc, NAcc),
	relations_complexity(T, P/A, NAcc, C).

% new_variables(+Term, -C) 
%   Unify C with the number of all new variables in the negative 
%   side of the partition.
new_variables(:-(L, R), C) :-
	all_variables(L, [], LV), 
	all_variables(R, [], RV), 
	list_diff(RV, LV, D), 
	length(D, C).

% all_variables(+T, +Acc, -L) 
%   L contains the union of Acc and the set of variables in T.
all_variables(T, Acc, Acc) :-
	ground(T), 
	!.
all_variables(T, Acc, [T | Acc]) :-
	var(T), 
	\+ eqmember(Acc, T),
	!.
all_variables(T, Acc, Acc) :-
	var(T), 
	eqmember(Acc, T), 
	!.
all_variables(T, Acc, L) :-
	nonvar(T), 
	\+ ground(T), 
	T =.. [_ | Args], 
	list_variables(Args, Acc, L).
	
list_variables([], Acc, Acc).
list_variables([H | T], Acc, L) :-
	all_variables(H, Acc, N), 
	list_variables(T, N, L).
	
% list_diff(+L1, +L2, -L)
%    L contains all the elements of L1 that are not in L2.
list_diff([], _, []).
list_diff([H | T], L, NT) :-
	eqmember(L, H), 
	!, 
	list_diff(T, L, NT).
list_diff([H | T], L, [H | NT]) :-
	\+ eqmember(L, H), 
	list_diff(T, L, NT).

% eqmember(+List, +El)
%    There is an element in List equal (==) to El.
eqmember([H | _], El) :-
	H == El, 
	!.
eqmember([H | T], El) :-
	H \== El, 
	eqmember(T, El).


% XML printing

xml_print_header :-
	print('  <local_complexity>'), nl.

xml_print_footer :-
	print('  </local_complexity>'), nl.

% print_result(+Terms)
%   Print XML for the result of the analysis.

xml_print_result([]).
xml_print_result([H | T]) :-
	xml_print_predicate(H), 
	xml_print_result(T).

xml_print_predicate(pred(P, Partitions)) :-
	format('    <predicate name="~w">~n', [P]),
	xml_print_partitions(Partitions, 0),
	format('    </predicate>~n').

xml_print_partitions([], _).
xml_print_partitions([P1+P2+P3+P4 | T], Id) :-
	format('       <partition id="~w">~n', [Id]),
	format('          <new_entities>~w</new_entities>~n', [P1]),
	format('          <subproblems>~w</subproblems>~n', [P2]),
	format('          <relations_complexity>~w</relations_complexity>~n', [P3]),
	format('          <new_variables>~w</new_variables>~n', [P4]),
	format('       </partition>~n'),
	NewId is Id + 1, 
	xml_print_partitions(T, NewId).
