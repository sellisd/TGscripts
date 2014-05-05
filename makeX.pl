#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use Encode;
use feature 'unicode_strings';
use Unicode::Normalize;
binmode(STDOUT, ":utf8");
#compares cognate and comparative files and compares @ and X
#output: a comma separated file with one error in each row
#there are three types of errors:
#  add X    : there is an X missing
#  remove X : there is an extra X
#  no words : in the cognate files this row is empty for all languages
#check  each row of cognates file to validate Xs
#parse comparative file 
#$language{$word}=[0,1,0] # 1 if @ otherwise 0
#foreach line of cognate
# foreach entry
#   foreach word
#     if defined $language{$word}
#     else noX
my %hash;
my $VocabularyFile = '../data/TG_comparative_online_MASTER.csv';
my $CognateFile='../data/TG_cognates_online_MASTER.csv';
my $outputFile = '../data/addX.csv';
open my $cpfh, '<:encoding(UTF-8)',$VocabularyFile or die $!;
open my $cgfh, '<:encoding(UTF-8)',$CognateFile or die $!;
open OUT, '>:encoding(UTF-8)',$outputFile or die $!;
my $line = readline($cpfh);
chomp $line;
my @languages = split "\t",$line;
shift @languages;
while ($line = readline($cpfh)){
    my @ar = split "\t", $line;
    shift @ar; #remove TAGs
    my $meaning = shift @ar;
    my $counter = 0;
    foreach my $entry (@ar){
	foreach my $word (parsewords($entry)){
	    $word = NFD($word); # decompose & reorder canonically
	    my $value = -1;
	    if ($meaning =~ /^(.*)\@(\s*)$/){
		$value = 1;
	    }else{
		$value = 0;
	    }
	    if (defined($hash{$languages[$counter].'.'.$word})){
		push @{$hash{$languages[$counter].'.'.$word}}, $value;
	    }else{
		$hash{$languages[$counter].'.'.$word} = [$value];
	    }
	}
	$counter++;
    }
}

readline($cgfh); #get rid of header
my $lineCounter = 1;
while (my $line = readline($cgfh)){
    chomp $line;
    $lineCounter++;
    next if $line =~ /^[\s\f\n\r]*$/;
    my @ar = split "\t", $line;
    shift @ar; #remove compound
    my $x = -1;
    my $root = shift @ar;
    next if uc($root) ne $root;
    if ($#ar == -1){
	print OUT "no words for $root\n";next;
    }
    if($root eq ""){
	print OUT "Line $lineCounter not empty\n";
	next;
    }
    if($root =~ /^.*(X)$/){
	$x = 1;
    }else{
	$x = 0;
    }
    my $counter = 0;
    my $papioflag = 1;
    foreach my $entry (@ar){
	foreach my $word (parsewords($entry)){
	    $word = NFD($word);
	    if(defined($hash{$languages[$counter].'.'.$word})){
		foreach my $flag(@{$hash{$languages[$counter].'.'.$word}}){
		    if ($flag == 0){
			$papioflag = 0;
		    }elsif($flag == 1){
                        #ola prepei na einai 1
		    }else{
			die;
		    }

		}
	    }
	}
	$counter++;
    }
    if($x == 0){
	if($papioflag == 0){
	    #ok
	}elsif($papioflag == 1){
	    #add X
	    print OUT "add X, $root\n";
	}else{
	    print OUT "Non-matching names at $root\n";
	}
    }elsif($x == 1){
	if($papioflag == 0){
	    print OUT "remove X, $root\n";
	    #remove X
	}elsif($papioflag == 1){
	    #ok
	}else{
	    print OUT "Non-matching names at $root\n";
	}
    }
}

close $cpfh;
close $cgfh;
close OUT;


sub parsewords{
    my $string = shift @_;
    my $inWord = 0;
    my $wordCount = 0;
    my @words;
    my $openDelim;
    for(my $i = 0; $i < length($string); $i++){
	my $char = substr($string,$i,1);
	if ($inWord == 0){ #outside word
	    if($char eq '<' or $char eq '[' or $char eq '/'){
		#in word
		$inWord = 1;
		$words[$wordCount].=$char; #delimiters are part of the word
		$openDelim=$char;
	    }
	}else{ #inside word
	    if($char eq '>' or $char eq ']' or $char eq '/'){
		$inWord = 0;
		$words[$wordCount].=$char;
		$wordCount++;
	    }else{
		$words[$wordCount].=$char;
	    }

	}
    }
    return @words;
}
