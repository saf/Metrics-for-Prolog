#!/usr/bin/perl

use strict;

use pl_package;
use html_vis;

my @files = @ARGV;

my $data = {};

for my $file (@files) {
    add_analysis($file, $data); 
}

use Data::Dumper;
#warn Dumper($data);

html_vis::visualise($data);

sub add_analysis($) {
    my ($file) = @_;

    unless (defined $data->{$file}) {  # Cycle-safe
	my $pkg = $file;

	my $dir = `dirname $file`;
	chomp $dir;
	if ($dir eq '.') {
	    $dir = '' ;
	} else {
	    $dir .= '/';
	};

	$pkg =~ s/\.pl$//;
	my $pkg_data = pl_package::get_data($file);
	$data->{$pkg} = $pkg_data;
	my $links = pl_package::get_links($pkg_data);

	for (@$links) {
	    s/$/.pl/ unless m/\.pl$/;
	    add_analysis($dir . $_);
	};
    }
}


