#!/usr/bin/perl

package xml_parse;

use strict;
use XML::Simple;

sub xml_parse($) {
    my ($string) = @_;
    my $xs = XML::Simple->new(ForceArray => ['partition']);
    my $result = $xs->XMLin($string); 
    use Data::Dumper;
    warn Dumper($result);
    return $result;    
}

sub get_predicates($) {
    my ($data) = @_;
    my $result = [];
    for my $p (keys %{$data->{halstead}->{predicate}}) {

	my $ps = $data->{local_complexity}->{predicate}->{$p}->{partition};
	my $partitions = [];
	for (sort keys %$ps) {
	    push @$partitions, { %{$ps->{$_}}, id => $_ };
	}

	push @$result, { 
	    name => $p, 
	    halstead => $data->{halstead}->{predicate}->{$p},
	    local => local_total($partitions),
	};
    }
    use Data::Dumper;
    warn Dumper($result);
    return $result;
}

sub local_total($) {
    my ($partitions) = @_;
    my $sum = 0;
    my $n = @$partitions;

    for (@$partitions) {
	my $compl = $_->{new_entities} + $_->{subproblems} + $_->{relation_compl} + $_->{new_variables};
	$sum += $compl;
    };

    return {
	partitions => $partitions, 
	sum => $sum, 
	average => $n == 0 ? undef : $sum / $n,
	n_partitions => $n,
    };
}


return 1;
