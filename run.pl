#!/usr/bin/perl

use strict;
use xml_parse;

my @files = @ARGV;

for (@files) {
    my $xml = `swipl -t halt -f none -g "[parse], read_file('$_')."`;
    my $data = xml_parse::xml_parse($xml);
    xml_parse::get_predicates($data);
}
