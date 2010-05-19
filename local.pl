% Markusz & Kaposi's local complexity measure for Prolog.



% local_analyse(+Terms)
%   Perform local complexity analysis of Terms
local_analyse(Terms) :-
	predicate_complexity(Terms, AnnotatedPredicates), 
	print(AnnotatedPredicates).

% predicate_complexity(+Terms, -Predicates)
predicate_complexity(Terms, AnnotatedPredicates) :-
	partitions_complexity(Terms, AnnotatedTerms), 
	print(AnnotatedTerms), nl, 
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
	C is P1 + P2 + P3 + P4.

% new_entities(+Term, -C)
%    Unify C with the number of new data entities introduced in 
%    the positive side of the partition.
new_entities(_, 0).

% subproblems(+Term, -C)
%    Unify C with the number of negative atoms in the partition.
subproblems(_, 0).

% relations_complexity(+T, -C)
%    Unify C with the complication coefficient of the partition.
%    Each recursive call adds 2 here.
relations_complexity(:-(L, R), C) :-
	functor(L, P, A),
	relations_complexity(R, P/A, 0, C).

relations_complexity(T, P/A, PC, C) :-
	functor(T, P, A), 
	!, 
	C is PC + 2.
relations_complexity(T, P/A, C, C) :-
	\+ functor(T, P, A), 
	T =.. [_, []], 
	!.
relations_complexity(T, P/A, PC, C) :-
	\+ functor(T, P, A), 
	T =.. [_, H | L], 
	relations_complexity(H, P/A, PC, NPC), % A bit of a hack here. Analyse all arguments
	relations_complexity(L, P/A, NPC, C).  % by passing a list of them to relations_complexity.

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