#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use Unicode::Normalize;
binmode(STDOUT, ":utf8");

my $one = '../data/binary.noIND.test.tr.csv';
my $two = '../data/temp';
open IN1, '<:encoding(UTF-8)',$one or die $!;
open IN2, '<:encoding(UTF-8)', $two or die $!;
while(my $line1 = <IN1>){
    my $line2 = readline(*IN2);
    if ($line1 ne $line2){
	my @ar1 = split "\t", $line1;
	my @ar2 = split "\t", $line2;
	die if $#ar1 != $#ar2;
	for(my $i = 0; $i <= $#ar1; $i++){
	    if ($ar1[$i] ne $ar2[$i]){
		print $ar1[$i],"\n";
		print $ar2[$i],"\n";
	    }
	}
    }
}

close IN1;
close IN2;
