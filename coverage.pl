#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use feature 'unicode_strings';
use Unicode::Normalize;
binmode(STDOUT, ":utf8");
#read comparative file
#for each column (language) find the percentage of cells that are three dots excluding lax rows (ending in @)
my $comparativeFile = '../data/TG_comparative_lexical_online_MASTER.csv';
open my $cpfh, '<:encoding(UTF-8)',$comparativeFile or die $!;
my $header = readline($cpfh);
chomp $header;
my @languages = split "\t", $header;
shift @languages; #remove TAGs
shift @languages; #remove English
my @counter = ( (0) x ($#languages + 1) );
my $total = 0;
while (my $line = readline($cpfh)){
    next if $line =~ /^[\s\t\f\n\r]*$/; #skip emtpy lines
    chomp $line;
    my @ar = split "\t", $line;
    shift @ar; #remove TAGs
    my $root = shift @ar; #remove root
#    die $root,' ',length($root),' ',substr($root,(length($root)-1),1);
    if (substr($root,(length($root)-1),1) ne '@'){ #skip lax rows
	$total++;
	for (my $i = 0 ; $i <= $#ar; $i++){
	    if ($ar[$i] eq '...'){
		$counter[$i]++;
	    }	
	}
    }
}
close $cpfh;

print "languages\tcounts\t\%\ttotal\n";
for (my $i = 0; $i<=$#languages; $i++){
  print $languages[$i],"\t",$counter[$i],"\t",sprintf("%.2f",100*$counter[$i]/$total),"\t",$total,"\n";
}
