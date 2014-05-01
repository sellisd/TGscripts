#!/usr/bin/perl
use strict;
use warnings;
use Encode;
use feature 'unicode_strings';
use Unicode::Normalize;
binmode(STDOUT, ":utf8");
#read cognates file, find which roots have GEN and print a list
my $cognatesFile = '../data/TG_cognates.13.10.16.15.54.noIND.csv';
my $multistateFile = '../data/multistate.13.10.16.15.54.noIND.csv';
open CG, '<:encoding(UTF-8)',$cognatesFile or die $!;
open MS, '<:encoding(UTF-8)',$multistateFile or die $!;
my %gens;
while(my $line = <CG>){
    my @ar = split "\t", $line;
    if($ar[0] ne ''){ #if there is a tag
	my @tags = split ',', $ar[0];
	foreach my $tag (@tags){
	    $tag=~s/\s*(.*)\s*/$1/; #remove space
	    if ($tag eq 'GEN'){
		$gens{$ar[1]} = 1;
	    }
	}
    }
}
close CG;
foreach (sort keys %gens){
    print $_,"\n";
}
close MS;
