#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use feature 'unicode_strings';
use Getopt::Long;
use Unicode::Normalize;
binmode(STDOUT, ":utf8");
#read output from convert (-check nf format)
#and produce a multistate coding table with words and roots
#if option $dbg is set to true then in the output file the words
#are also included e.g  <word>ROOT1 instead of ROOT in each entry

my $Version = 0.01;
my $usage = <<HERE;
multistate version $Version
Parses cognate and comparative files and produces a multistate coding table
with words and roots
    USAGE multistate.pl [OPTIONS=XX]
where OPTIONS can be one or more of the following:
 -words                 include also words in the output
 -comparative FILENAME  path and filename of comparative .csv file
 -cognate     FILENAME  path and filename of cognate .csv file
 -output      FILENAME  path and filename of output file
 -help or -?            this help screen
HERE

my $cognateFile = '../data/TG_cognates.13.09.19.csv';
my $comparativeFile = '../data/TG_comparative.13.09.19.csv';
my $outputFile = '../data/multistate.13.09.19.csv';
my $includeWords = 0;
my $help;
unless(GetOptions( 
	   'words'         => \$includeWords,
	   'comparative=s' => \$comparativeFile,
	   'cognate=s'     => \$cognateFile,
	   'output=s'      => \$outputFile,
	   'help|?'        => \$help
       )){die $usage;}
if($help){
   die $usage;
}

open my $cpfh, '<:encoding(UTF-8)',$comparativeFile or die $!;
open my $cgfh, '<:encoding(UTF-8)',$cognateFile or die $!;
open OUT, '>:encoding(UTF-8)',$outputFile or die $!;

my $hashref;
my $langref;
($hashref,$langref)=parseCognates($cgfh);

# foreach my $k (keys %{$hashref}){
#     my @ar = @{$hashref->{$k}};
#     foreach my $l (@ar){
# 	if ($l eq 'EAT1'){
# 	    print "$k @ar\n";
# 	}
#     }
# }

my $lineCounter = 0;
while(my $line = readline($cpfh)){
    chomp $line;
   if($lineCounter == 0){ #languages (header)
       my @ar = split "\t", $line;
       shift @ar; #remove TAG header
       print OUT join("\t",@ar),"\n";    
    }else{
	my @ar = split '\t', $line;
	my $meaning;
	my $tag;
	if (defined($ar[1])){
	    if ($ar[1] =~ /^.*@/){ #skip lines with @ (lax rows)
		next;
	    }
	    $tag = shift @ar;
	    $meaning = shift @ar;
	}else{
	    next;
	}
	my $counter = 0;
	print OUT $meaning,"\t";
	foreach my $entry (@ar){
	    if (substr($entry,0,3) eq '...'){
		print OUT '...';
	    }else{
		my $wordsref = parseWords($entry);
		my $err = $wordsref->{'err'};
		my @words = @{$wordsref->{'words'}};
		if ($err == 1){
		    print "Odd number of delimiters ",$meaning,": $words[0]\n";
		    next;
		}
		foreach my $w (@words){
		    $w = NFD($w); #decompose & reorder canonically
		    my $language = ${$langref}[$counter];
		    if (!defined($hashref->{$language.'.'.$w})){
			print "inconsistency at: $language $w\n";
			# use Data::Dumper;
			# print Dumper $hashref;
			# die;
		    }else{
			if($includeWords == 1){
			    print OUT $w,';',join(';',@{$hashref->{$language.'.'.$w}});
			}elsif($includeWords == 0){
			    print OUT join(';',@{$hashref->{$language.'.'.$w}});
			}else{
			    die;
			}
		    }
		    print OUT ';';
		}
	    }
	    print OUT "\t";
	    $counter++;
	}
    }
    $lineCounter++;
    print OUT "\n";
}
close $cgfh;
close $cpfh;

sub parseCognates{
    my $cgfh = shift @_;
    my $lineCounter = 0;
    my @languages;
    my %hash;
    while(my $line = readline($cgfh)){
	next if $line =~ /^[\s\f\t]*$/; #skip empty lines
	chomp $line;
	my @ar = split "\t", $line;
	my $compound = shift @ar; #remove compound column for the rest of analysis
	if($lineCounter == 0){ #languages (header)
	    push @languages, @ar;
	    shift @languages; #remove English
	}else{
            #filter Xs
	    if(!defined($ar[0])){
		die $line;
	       }
	    next if $ar[0] =~ /^.*X$/;
            #do not filter Compound words
#	    next if $compound eq 'COMPOUND';
	    my $counter = 0;
	    my $root = shift @ar;
	    if($root ne uc($root)){
                #first column;
		next
	    }
	    foreach my $entry (@ar){
		my $wordsref = parseWords($entry);
		my $err = $wordsref->{'err'};
		my @words = @{$wordsref->{'words'}};
		if ($err == 1){
		    print "Odd number of delimiters ", $root,": $words[0]\n";
		    next;
		}else{
		    foreach my $w (@words){
			$w = NFD($w); #decompose & reorder canonically
			if(!defined($languages[$counter])){
			    die;
			}
			if(defined($hash{$languages[$counter].".".$w})){
			    push @{$hash{$languages[$counter].".".$w}},$root;
			}else{
			    $hash{$languages[$counter].'.'.$w}=[$root];
			}
		    }
		}
		$counter++;
	    }
	}
	$lineCounter++;
    }
    return (\%hash,\@languages);
}

sub parseWords{
    my $string = shift @_;
    my $inWord = 0;
    my $wordCount = 0;
    my @words;
    my $openDelim;
    for(my $i = 0; $i < length($string); $i++){
	my $char = substr($string,$i,1);
	next if $char eq '$';
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
    my $errors = -1;
    if ($inWord == 1){
#	print "Odd number of delimiters!, I don't know how to parse words, At: $string\n    "; 
	$errors = 1;
	$words[0]=$string;
    }
    my $returnValue = {'words' => \@words,
		       'err'   => $errors};
    return $returnValue;
}
