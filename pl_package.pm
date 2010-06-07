#!/usr/bin/perl

package pl_package;

use strict;
use XML::Simple;

sub get_data($) {
    my ($filename) = @_;
    my $command = fetch_xml_command($filename);
    my $xml = `$command`;
    my $xs = XML::Simple->new(ForceArray => ['partition'], GroupTags => { links => 'consult' });
    my $result = $xs->XMLin($xml); 
    add_code_metrics($filename, $result);
    return $result;    
}

sub fetch_xml_command($) {
    my ($file) = @_;
    # TODO
    return "swipl -t halt -f none -g \"[parse], read_file('$file').\"";
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

sub get_links($) {
    my ($data) = @_;
    my $links = [];
    my $lnk = $data->{links};
    if ($lnk =~ /^ARRAY/) {
	for (@$lnk) {
	    push @$links, $_->{ref};
	};
    };
    return $links;
}

sub add_code_metrics($$) {
    my ($file, $data) = @_;

    my $loc = 0;
    my $comments = 0;
    my $effective_loc = 0;

    open FILE, "<$file";
    while(<FILE>) {
	$loc++;
	$effective_loc++ if m/[^%]*\w/;
	$comments++ if m/%/;
    };
    close FILE;

    $data->{loc} = $loc;
    $data->{effective_loc} = $effective_loc;
    $data->{comments} = $comments;
}

return 1;
