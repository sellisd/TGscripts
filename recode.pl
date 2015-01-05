#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use Unicode::Normalize;
use Data::Dumper;
binmode(STDOUT, ":utf8");
#to replace multi2binary
#perform binary recoding of a multistate matrix

my $multistateFile = '../data/multistate.csv';
open IN, '<:encoding(UTF-8)',$multistateFile or die $!;
#read multistate line by line
my $lineCounter = 0;
my @languages;
while(my $line = <IN>){
    if($lineCounter > 0){
	chomp $line;
	my @ar = split "\t", $line;
	my $meaning = shift @ar;
	my %outerHash;  # hash of states in a row
	my %innerHash;  # hash of states in an entry
	my %indmed;
	foreach my $entries (@ar){
	    my @states = split ';', $entries;
	    foreach my $state (@states){
		if(substr($state,0,7) eq 'Warning'){
		    next;
		}
		if($state =~ /^;*$/){
		    next;
		}
		#do not make in hash ...
		next if $state eq '...';
		$innerHash{$state} = 1;
	    }
	    foreach my $unique (keys %innerHash){
		#IND & MED einai anexartitoi xaraktires
		if(substr($unique,-4,4) eq '.MED' or substr($unique,-4,4) eq '.IND'){
		    if(defined($indmed{$unique})){
			$indmed{$unique}++;
		    }else{
			$indmed{$unique} = 1;
		    }
		    $outerHash{$unique.$indmed{$unique}}=1;  #build hash of all states
		}else{
		    $outerHash{$unique}=1;  #build hash of all states
		}
	    }
	}
	#loop through keys of hash and print one line for each key
	foreach my $binstate (sort keys %outerHash){
	    my %indmed; #hash of ind or med counters
	    print $meaning.$binstate,"\t";
	    #loop through columns if $entry eq $binstate print 1 otherwise 0
	    foreach my $entries (@ar){
		my @states = split ';', $entries;
		#do not print more columns than necessary
		my $found = 0;
		foreach my $state (@states){
		    if(substr($state,0,7) eq 'Warning'){
			print "$state; "; # Il y a une couille dans le potage
		    }
		    if($state =~ /^;*$/){
			die "Kapoio lako exei i fava\n";
		    }	
		    if ($state eq $binstate){
			$found = 1;
			last;
		    }elsif($state eq '...'){
			$found = '?';
		    }elsif(substr($state,-4,4) eq '.MED'){
			$found = 1;
			last;
		    }elsif(substr($state,-4,4) eq '.MED'){
			$found = 1;
			last;
		    }else{
			$found = 0;
		    }
		}
		print $found,"\t";
	    }
	    print "\n";
	}

    }else{
	print $line; #print header
    }


    $lineCounter++;
}	

