#!/usr/bin/perl

use strict;

use lib './process';
use util;
use html_vis;

unless (-d "output") {
    mkdir "output", 0777 or die "Failed to create output directory: $!";
} else {
    `rm -r output/*`;
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

print "\nAnalysis complete. HTML output created in ./output/\n";

exit 0;


