#!/usr/bin/perl

use strict;
use pl_package;

my @files = @ARGV;

my $data = {};

for my $file (@files) {
    add_analysis($file, $data); 
}

use Data::Dumper;
warn Dumper($data);

sub add_analysis($) {
    my ($file) = @_;

    unless (defined $data->{$file}) {
	my $pkg = $file;
	$pkg =~ s/\.pl$//;
	my $pkg_data = pl_package::get_data($file);
	$data->{$pkg} = $pkg_data;
	my $links = pl_package::get_links($pkg_data);
	for (@$links) {
	    s/$/.pl/ unless m/\.pl$/;
	    add_analysis($_);
	};
    }
}


