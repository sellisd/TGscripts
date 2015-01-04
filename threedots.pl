#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use feature 'unicode_strings';
#three dots:
#parse cognates file : meaning.language=>entry
#read comparative file line by line
# if entry empty print error
# if entry eq ... 
#    if substr(meaning.language{entry},0,3) eq '...'
#        meaning.language=found
#    else print error
#foreach meaning.language
#   if $_ ne found
#         print error

my $cognateFile = '../data/TG_cognates_online_MASTER.csv';
my $comparativeFile ='../data/TG_comparative_lexical_online_MASTER.csv';
my $errorsList = '../data/threedotCheck.txt';
my %hash;
my %missing;
open CG, '<:encoding(UTF-8)',$cognateFile or die $!;
open CP, '<:encoding(UTF-8)',$comparativeFile or die $!;
open OUT, '>:encoding(UTF-8)',$errorsList or die $!;

my $lineCounter = 0;
my @languages;
while (my $line = <CG>){
    my @ar = split "\t", $line;
    shift @ar; #remove COMPOUND
    if ($lineCounter == 0){
	@languages = @ar;
	shift @languages; #remove English
    }else{
	my $meaning = shift @ar; # remove first column
	if ($meaning ne uc($meaning)){ #not root
	    next if ($meaning =~ /^.*X$/);
	    for(my $i = 0; $i <= $#ar; $i++){
		$hash{$languages[$i].'.'.$meaning} = $ar[$i];
	    }
	}
    }
    $lineCounter++;
}
close CG;
%missing=%hash;
$lineCounter = 0;
while(my $line = <CP>){
    chomp $line;
    if ($line =~ /^[\s\f\t]*$/){ #skip empty lines
	$lineCounter++;
	next;
    }
    if ($lineCounter > 0){
	my @ar = split "\t", $line;
	shift @ar; #ignore tags
	if ($ar[0] =~ /^[\s\f\t]*$/){ #skip empty lines even if not fully empty!
	    print OUT "line ",$lineCounter+1," not empty\n";
	}elsif($ar[0] =~ /^.*@/){
	    #skip lines with @ (lax rows)
	}else{
	    my $meaning = shift @ar;
	    if ($#ar != $#languages){
		print OUT "Warning: Entries are less than languages at $meaning. First or last entry is empty?\n";
	    }

	    my $counter = 0;
	    foreach my $entry (@ar){
		if ($entry=~ /^[\s\f\t]*$/){
		    print OUT "Empty entry at: $meaning - $languages[$counter]\n";
		}elsif($entry eq '...'){
		    if (!defined( $hash{$languages[$counter].'.'.$meaning} )){
			print OUT "Not consistent names of meanings, run meaningConsistencyTest.pl: $meaning $languages[$counter]\n";
		    }else{
			if(substr($hash{$languages[$counter].'.'.$meaning},0,3) ne '...'){
#			    print $meaning, ' ', $languages[$counter],"\n";#
#			    die $hash{$languages[$counter].'.'.$meaning};
			    print OUT "Missing ... at: $meaning - $languages[$counter]\n";
			}else{
                            # mark for deletion
			    delete($missing{$languages[$counter].'.'.$meaning});
			}
		    }
		}
		$counter++;
	    }
	}
    }
    $lineCounter++;
}
close CP;

print OUT "Three dots (...) in cognates but not in comparative:\n";
foreach my $k (sort keys %missing){
    $k =~ /(.*?)\.(.*)/;
    my $language = $1;
    my $word = $2;
    if ($missing{$k} eq '...'){
	print  OUT "$language\t$word\n"
   }
}
