#!/usr/bin/perl
use warnings;
use strict;
use lib'./';
use lingperl;
use utf8;
use Encode;
use feature 'unicode_strings';
use Unicode::Normalize;
binmode(STDOUT,":utf8");
#read comparative file and keep only one word per entry
use Data::Dumper;
# remove Enghlish, spanish etc,
# remove Guajajara 
# save as .csv

my $comparativeFile = '../data/TG_comparative.noFUNCTEXCL.csv';
my $outputFile = '../data/comparativeSingleWord.csv';
open my $cpfh, '<:encoding(UTF-8)',$comparativeFile or die $!;
open OUT, '>:encoding(UTF-8)', $outputFile or die $!;
my $lineCounter = 0;
while(my $line = readline($cpfh)){
    if($lineCounter>0){ #skip first line
	next if $line =~ /^[\s\t\f\n\r]*$/; #skip emtpy lines
	chomp $line;
	my @ar = split "\t", $line;
	my $tag = shift @ar; # TAGs
	my $meaning = shift @ar; # meaning
	print OUT $tag,"\t",$meaning,"\t";
	foreach my $entry (@ar){
	    my $wordsref = parseWords($entry);
	    my $err = $wordsref->{'err'};
	    my @words = @{$wordsref->{'words'}};
	    if (defined($err)){
		print OUT $err, ' at ', $meaning,"\n";
		next;
	    }
	    if ($#words >= 0){
		my $randomWord = $words[rand @words];
		print OUT NFD($randomWord),"\t"; #decompose & reorder canonically
	    }else{
		print OUT $entry,"\t";
	    }
	}
    }else{
	print OUT $line;
    }
    print OUT "\n";
    $lineCounter++;
}
close $cpfh;
close OUT;
