#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use Unicode::Normalize;
binmode(STDOUT, ":utf8");

my $multistateFile = '../data/multistate.noIND.csv';
open IN, '<:encoding(UTF-8)',$multistateFile or die $!;
#open OUT, '>:encoding(UTF-8)', $outputFile or die $!;

#read a multistate file and change the encoding to binary
my $lineCounter = 0;
my @languages;
while(my $line = <IN>){
    if($lineCounter > 0){
	chomp $line;
	my @ar = split "\t", $line;
	my $meaning = shift @ar;
	my %hash;
#	my $c = 0;
	foreach my $entries (@ar){
	    my @states = split '&', $entries;
	    foreach my $state(@states){
                #do not make in hash ? and -
		next if $state eq '?';
		next if $state eq '-';
#		print $state,' ', $languages[$c],' ',$c,"\n";
		$hash{$state}=1;  #build hash of all states
	    }
#	    $c++;
	}
#	use Data::Dumper;
#	print Dumper %hash;
#	die;
        #loop through keys of hash and print one line for each key
	foreach my $binstate(sort keys %hash){
	    print $meaning.$binstate,"\t";
	    #loop through columns if $entry eq $binstate print 1 otherwise 0
	    foreach my $entries (@ar){
		my @states = split '&', $entries;
		#do not print more columns than necessary
		my $found = 0;
		foreach(@states){
		   if ($_ eq $binstate){
		       $found = 1;
		       last;
		    }elsif($_ eq '?'){
			$found = '?';
		    }elsif($_ eq '-'){
			$found = '-';
		    }else{
			$found = 0;
		    }
		}
		print $found,"\t";
	    }
	    print "\n";
	}
    }else{
	@languages = split "\t",$line;
	print $line;
    }
    $lineCounter++;
}
close IN;
