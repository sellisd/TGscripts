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
my $errors = 0;
while(my $line = <IN>){     #read file line by line
    chomp $line;
    my @ar = split "\t", $line;    
    if($lineCounter == 0){
	@languages = @ar;
	print join("\t", @languages);
	print "\n";
    }elsif($lineCounter > 0){
	my $meaning = shift @ar;
	my %outerHash;  # hash of states in a row
	my @b; #copy of @a with unique entries and numbered and renamed .IND and .MED
	for (my $c = 0; $c <= $#ar; $c++){ # loop through cells
	    my %innerHash;  # hash of states in an entry
	    my @states = split ';', $ar[$c];
	    foreach my $state (@states){               #skip errors or warnings
		if(substr($state,0,7) eq 'Warning'){
		    $b[$c] = $ar[$c];
		    my $errors = 1;
		    next;
		}
		if($state =~ /^;*$/){
		    $b[$c] = $ar[$c];
		    my $errors;
		    next;
		}
		#do not make in hash ...
		if ($state eq '...'){
#		    print '...';
		    $b[$c] = $ar[$c];
		    next;
		}
		$innerHash{$state} = 1;
	    }
	    my @innerb;
	    foreach my $unique (keys %innerHash){
		my $part = substr($unique,-4,4);
		if($part eq '.MED' or $part eq '.IND'){ #if IND or MED
		    if(defined($outerHash{$unique})){
			$outerHash{$unique}++;
		    }else{
			$outerHash{$unique} = 1;
		    }
		    push @innerb, $unique.$outerHash{$unique};
#		    print $unique.$outerHash{$unique};

		}else{
		    $outerHash{$unique} = 1;
#		    print $unique,";";
		    push @innerb, $unique;
		}
	    }
#	    print "\t";
	    my $cellString = join ';', @innerb;
	    push @b, $cellString;
	}
#		print join("\t",@b);
#	print"\n";
#	next;
	# loop through keys of hash and print one line for each key
	foreach my $binstate (sort keys %outerHash){
	    #each IND & MED are unique
	    for (my $c = 1; $c <= $outerHash{$binstate}; $c++){
		my $binstateC;
		if ($outerHash{$binstate}>1){
		    $binstateC = $binstate.$c;
		    # $binstate;
		}else{
		    $binstateC = $binstate;
		}
		print $meaning.'.'.$binstateC,"\t";
		#loop through columns if $entry eq $binstate print 1 otherwise 0
		print $#b,"\n";
		foreach my $entries (@b){
		    my @states = split ';', $entries;
		    my $found = 0;
		    foreach my $state (@states){
			#		    print $state," $binstate\n";die;
			if(substr($state,0,7) eq 'Warning'){
			    print "$state";
			}
			if($state =~ /^;*$/){
			    die "Kapoio lako exei i fava\n";
			}
			#if MED IND
			if($state eq $binstateC){
			    $found = 1;
			}elsif($state eq '...'){
			    $found =  '?';
			}else{
			}
		    }
		    print "$found\t";
		}
		print "\n";
	    }
	}
    }
    $lineCounter++;
}
if ($errors != 0){
    die "Il y a une couille dans le potage";
}
	 #   next;	    
	   # foreach my $unique (keys %innerHash){
		#IND & MED einai anexartitoi xaraktires
#		if(substr($unique,-4,4) eq '.MED' or substr($unique,-4,4) eq '.IND'){
#		    if(defined($indmed{$unique})){
#			$indmed{$unique}++;
#		#	push @innerb, $unique.$indmed{$unique};
#		    }else{
#			$indmed{$unique} = 1;
#		#	push @innerb, $unique.'1';
#		    }
#		    $outerHash{$unique.$indmed{$unique}}=1;  #build hash of all states
#		}else{
#		    $outerHash{$unique}=1;  #build hash of all states
#		    push @innerb, $unique;
#		}
#		my $indmedString = join ';', keys %indmed;
#		push @b, $indmedString;
#	    }
#	}
#	print "@b";die;
	#loop through keys of hash and print one line for each key
#	foreach my $binstate (sort keys %outerHash){
#	    print $meaning.$binstate,"\t";
#	    #loop through columns if $entry eq $binstate print 1 otherwise 0
#	    foreach my $entries (@ar){
#		my @states = split ';', $entries;
#		#do not print more columns than necessary
#		my $found = 0;
#		foreach my $state (@states){
#		    if(substr($state,0,7) eq 'Warning'){
#			print "$state; "; # Il y a une couille dans le potage
#		    }
#		    if($state =~ /^;*$/){
#			die "Kapoio lako exei i fava\n";
#		    }	
#		    if ($state eq $binstate){
#			$found = 1;
#			last;
#		    }elsif($state eq '...'){
#			$found = '?';
#		    }elsif(substr($state,-4,4) eq '.MED'){
##			my $word = substr($state,0,length($state)-4);
##			$found = $indmed{$word};
#			#			$indmed{$word}--;
#			$found = 1;
#			last;
#		    }elsif(substr($state,-4,4) eq '.IND'){
#			$found = 1;
#3			last;
##		    }else{
#			$found = 0;
#		    }
#		}
#		print $found,"\t";
#	    }
#	    print "\n";
#	}
#
 #   }else{
#	print $line; #print header
 #   }
#

 #   $lineCounter++;
#}	

