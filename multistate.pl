#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use feature 'unicode_strings';
use Getopt::Long;
use Unicode::Normalize;
use Data::Dumper;
binmode(STDOUT, ":utf8");
#read output from convert (-check nf format)
#and produce a multistate coding table with words and roots
#if option -words is set then in the output file the words
#are also included e.g  <word>ROOT1 instead of ROOT in each entry

my $Version = 0.1.1;
my $usage = <<HERE;
multistate version $Version
    Parses cognate and comparative files and produces a multistate coding table
    with words and roots
    USAGE multistate.pl [OPTIONS=XX]
    where OPTIONS can be one or more of the following:
    -comparative FILENAME  path and filename of comparative .csv file
    -cognate     FILENAME  path and filename of cognate .csv file
    -output      FILENAME  path and filename of output file
    -help or -?            this help screen
HERE

my $cognateFile = '../data/TG_cognates_online_MASTER.csv';
my $comparativeFile = '../data/TG_comparative_lexical_online_MASTER.csv';
my $outputFile = '../data/multistate.csv';
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

my $lineCounter = 0;
while(my $line = readline($cpfh)){
    chomp $line;
    if($lineCounter == 0){ #languages (header)
	my @ar = split "\t", $line;
	shift @ar; #remove TAG header
	print OUT join("\t",@ar),"\n"; #includes English
	#        print join("\n",@ar),"\n"; #includes English
    }else{
	my @ar = split '\t', $line;
	if (defined($ar[1])){
	    if ($ar[1] =~ /^.*@/){ #skip lines with @ (lax rows)
		next;
	    }
	}else{
	    next;
	}
	my $tag = shift @ar;
	my $meaning = shift @ar; 
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
			print "inconsistency at: $language $meaning, $w\n";
		    }else{
			#loop through to find which are compounds and which match with meaning
			my @matches;
			my @matchesNotCompound;
			my %roots;
			my $counterComp = 0;
			foreach my $cognGroup (@{$hashref->{$language.'.'.$w}}){
			    my $root = ${$cognGroup}[0];
			    my $header = ${$cognGroup}[1];
			    my $tagsRef = ${$cognGroup}[2];
			    if($header eq $meaning){
				push @matches, $counterComp;
				if(defined($tagsRef->{'COMPOUND'}) or defined($tagsRef->{'COMPLEX'})){
				}else{
				    push @matchesNotCompound, $counterComp;
				}
			    }
			    $roots{$root} = 1;
			    $counterComp++;
			}
			#pool is the datastructure entry for one language.word (dereferenced value of hash)
			my @pool = @{$hashref->{$language.'.'.$w}}; #copy for shorthand reference
			
			if($#matches==0){                                                         # IF match == 1
			    print OUT $pool[$matches[0]][0];                                 #   PRINT
			    my $tagref = $pool[$matches[0]][2];			         
			    if (defined($tagref->{'IND'})){                                       #   IF IND
				print OUT '.IND';                                                 #     PRINT IND
			    }								         
			    if(defined($tagref->{'MED'})){                                        #   IF MED
				print OUT '.MED';                                                 #     PRINT MED
			    }								         
			}elsif(! @matches){                                 	                  # ELSE IF match == 0
			    my @rootsA = keys %roots;					         
			    if($#rootsA == 0){			                                  # IF only one root or only identical roots
				print OUT $rootsA[0];                                             #   PRINT
				my $tagref = $pool[0][2];				         
				if (defined($tagref->{'IND'})){                                   #   IF IND
				    print OUT '.IND';                                             #     PRINT IND
				}							         
				if(defined($tagref->{'MED'})){                                    #   IF MED
				    print OUT '.MED';                                             #     PRINT MED
				}							         
			    }else{                                                                # ELSE
				print OUT 'Warning: No cognate set matches meaning (';            #   WARNING
				foreach my $warnings (@pool){			         
				    print OUT $warnings->[0],' ';				         
				}							         
				print OUT ')';						         
			    }								         
			}elsif($#matches > 0){                                                    # ELSE IF match> 1
			    if(!@matchesNotCompound){                                             #   IF all matches are compound
				print OUT 'Warning: All matches are compound (';                  #     WARNING
				foreach my $warnings (@pool){
				    print OUT $warnings->[0],' ';
				}
				print OUT ')';
			    }elsif($#matchesNotCompound == 0){                                    #   ELSE IF one match is not compound
				print OUT $pool[$matchesNotCompound[0]][0];                       #     PRINT
			    }elsif($#matchesNotCompound > 0){                                     #   ELSE IF more than one matches are not compound
				print OUT 'Warning: More than one cognate set matches meaning ('; #     WARNING
				foreach my $warnings (@pool){
				    print OUT $warnings->[0],' ';
				}
				print OUT ')';
			    }
			}
			print OUT ';';
		    }
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
    my $rootHeader;
    while(my $line = readline($cgfh)){
	next if $line =~ /^[\s\f\t]*$/; #skip empty lines
	chomp $line;
	my @ar = split "\t", $line;
	my $compound = shift @ar; #remove compound column for the rest of analysis
	my @tags = split /,\s*/, $compound; #split first entry to tags
	my %tags = ();
	foreach my $tag (@tags){
	    $tags{$tag}=1;
	}
	if($lineCounter == 0){ #languages (header)
	    push @languages, @ar;
	    shift @languages; # remove English
	}else{
	    if(!defined($ar[0])){
		die $line;
	    }
	    # Do not filter Xs
	    # next if $ar[0] =~ /^.*X$/;
	    my $counter = 0;
	    my $root = shift @ar;
	    if($root ne uc($root)){
		#first column;
		$rootHeader = $root;
		next;
	    }
	    foreach my $entry (@ar){
		my $wordsref = parseWords($entry);
		my $err = $wordsref->{'err'};
		my @words = @{$wordsref->{'words'}};
		if ($err == 1){
		    print "Odd number of delimiters ", $root,": $words[0]\n";
		    $counter++;
		    next;
		}else{
		    foreach my $w (@words){
			$w = NFD($w); #decompose & reorder canonically
			if(!defined($languages[$counter])){
			    die;
			}
			my $value = [$root, $rootHeader, \%tags];
			if(defined($hash{$languages[$counter].".".$w})){
			    push @{$hash{$languages[$counter].".".$w}},$value;
			}else{
			    $hash{$languages[$counter].'.'.$w}=[$value];
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

