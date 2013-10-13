#!/usr/bin/perl
use strict;
use warnings;
use Encode;
use feature 'unicode_strings';
use Unicode::Normalize;
binmode(STDOUT, ":utf8");
my $input = '../data/TG_cognates.13.10.12.20.22.csv';
my $output = $input;
$output =~s/\.csv/.noIND.csv/;
#filter cognates file removing all rows that have IND tag
open IN, '<:encoding(UTF-8)',$input or die $!;
open OUT, '>:encoding(UTF-8)',$output or die $!;
while (my $line = <IN>){
    my @ar = split "\t", $line;
    unless ($ar[0] =~ /IND/){
	print OUT $line;
    }

}
close IN;
close OUT;
