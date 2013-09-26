#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use feature 'unicode_strings';

my $file = $ARGV[0];
my $output;
die unless -f $file;
if (defined($ARGV[1])){
    $output = $ARGV[1];
}else{
    $output = 'transposed.csv';
}
open IN, '<:encoding(UTF-8)',$file or die $!;
open OUT, '>:encoding(UTF-8)',$output or die $!;
my @t;
my $row = 0;
while(my $line = <IN>){
    chomp $line;
    my @ar = split "\t", $line;
    my $column = 0;
    foreach my $entry (@ar){
	$t[$row][$column] = $entry;
	$column++;
    }
    $row++;
}
my $rows = $#t;
my $columns = $#{$t[0]};
for(my $i = 0; $i<=$columns; $i++){
    for(my $j = 0; $j<=$rows; $j++){
	my $entry=$t[$j][$i];
	if(defined($entry)){
	    print OUT $entry;
	}
	print OUT "\t";
    }
    print OUT "\n";
}
#print $rows,".\n";
#print $columns,".\n";

close IN;
close OUT;
