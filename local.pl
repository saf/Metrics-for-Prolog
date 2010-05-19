% Markusz & Kaposi's local complexity measure for Prolog.

:- module(local, [local_analyse/1]).

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
predicate_name(C :- _, N/A) :-
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


% partition_complexity(+Term, -Complexity)
%   The local complexity value of the given partition.
partition_complexity(_, 2). %TODO

