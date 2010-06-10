#!/usr/bin/perl

use strict;

use util;
use html_vis;

unless (-d "output") {
    mkdir "output", 0777 or die "Failed to create output directory: $!";
}

`cp -rt output layout/*`;

my @files = @ARGV;

my $data = {};

util::init_files(\@files);

for my $file (@files) {
    util::add_analysis($file, $data); 
}

util::postprocess_data($data);
html_vis::visualise($data);

exit 0;


