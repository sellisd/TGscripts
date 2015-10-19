#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use Unicode::Normalize;
use Data::Dumper;
binmode(STDOUT, ":utf8");
#to replace multi2binary
#perform binary recoding of a multistate matrix

my $multistateFile = $ARGV[0];;
open IN, '<:encoding(UTF-8)',$multistateFile or die $!;

#read multistate line by line
my $lineCounter = 0;
my @languages;
while(my $line = <IN>){     #read file line by line
    chomp $line;
    my @ar = split "\t", $line;    
    if($lineCounter == 0){
	@languages = @ar;
	$languages[0] = ""; # replace english with emtpy value
	print join("\t", @languages);
	print "\n";
    }elsif($lineCounter > 0){
	my $meaning = shift @ar;
	my %hash;  # build hash of states in a row
	foreach my $cell (@ar){
	    my @states = split ';', $cell;
	    foreach my $state (@states){
		if ($state eq '...'){
		    next;
		}
		$hash{$state} = 1;
	    }
	}
	foreach my $binstate (sort keys %hash){
	    if(substr($binstate,-4,4) eq '.IND' or substr($binstate,-4,4) eq '.MED'){
		next;
	    }
	    print $meaning.'.'.$binstate,"\t";
	    foreach my $cell (@ar){
		my @states = split ';', $cell;
		my $found = 0;
		foreach my $state (@states){
		    if ($state eq $binstate){
			$found = 1;
		    }elsif($state eq '...'){
			$found = '?';
		    }
		}
		print "$found\t";
	    }
	    print "\n";
	}
    }
    $lineCounter++;
}
