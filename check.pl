#!/usr/bin/perl

use warnings;
use strict;
use Encode;
use Getopt::Long;
use feature 'unicode_strings';
use Unicode::Normalize;
binmode(STDOUT, ":utf8");
# default input parameters
my $Version = 2.3;
my $check = 'nf';
my $help;
my $comparativeFile;
my $cognateFile;
my $outputPath = '/home/dsellis/Dropbox/TGnobos/data/';
my $outputfile = $outputPath.'output.csv';
my $errorfile = $outputPath.'errors.csv';

my $usage = <<HERE;
check.pl Version $Version

Validates cognate and comparative files. The program has two modes,
NOT FOUND and MULTIPLE Validation.  In NOT FOUND mode it validates
that all words in the comparative file are present in the cognate
file. The output file (notFound.csv) is a table similar to the
comparative file, but with the word NOT FOUND included next to words
that are missing. The opposite problem, Words that are present in the
cognates file but missing form the comparative file are printed in the
error file (errors.csv).

In MULTIPLE mode it reads the cognate file skipping COMPOUND 

Usage ./check.pl [OPTIONS=XX]

where OPTIONS can be one or more of the following
  -comparative FILENAME   path and filename of comparative .csv file
  -cognate     FILENAME   path and filename of cognate .csv file
  -check       XX         type of validation to do:
                          XX: nf   Default: NOT FOUND, find words 
                              in the comparative missing from the 
                              cognate file
                          XX: m    MULTIPLE: find words that multiple
                              times in the cognates file, excluding
                              compound roots
HERE

#command line options
unless (GetOptions(
                   'comparative=s' => \$comparativeFile,
                   'cognate=s'     => \$cognateFile,
                   'check=s'       => \$check,
                   'help|?'        => \$help,
                  )){
    die $usage;
}
if ($help){
  print $usage;
  exit(0);
}
unless (defined($comparativeFile) and defined($cognateFile)){
print "Missing input without default\n";
die $usage;
}

unless (-f $comparativeFile) {die "$comparativeFile not found"};
unless (-f $cognateFile) {die "$cognateFile not found"};

if($check eq 'nf'){
    $outputfile =~ s/output/notFound/;
    print "Performing 'Not Found' validation\n";
}elsif($check eq 'm'){
    print "Performing 'Multiple' validation\n";
    $outputfile =~ s/output/multiple/;
}else{
    die $usage;
}

# Remember to read and write with correct encoding
open CP, '<:encoding(UTF-8)',$comparativeFile or die $!;
open CG, '<:encoding(UTF-8)',$cognateFile or die $!;
open OUT, '>:encoding(UTF-8)',$outputfile or die $!;

my %hash;
my %missing; #same as %hash but remove the ones found in the comparative list
my %unknown;
my $lineCounter = 0;
my @languages;
my $root;
#parse cognate file
while(my $line = <CG>){
    chomp $line;
    next if $line =~ /^[\s\f\t]*$/; #skip empty lines
    my @ar = split '\t', $line;
    my $compound = shift @ar;
    if ($lineCounter == 0){
        @languages = @ar;
    }else{
        my $counter = 0;
	if($check eq 'nf'){
	}elsif($check eq 'm'){
#	    next if $ar[0] =~ /^.*X$/;
#	    next if $compound; #skip lines with compound words
	    if($compound eq 'COMPOUND'){
		next;
	    }
	}else{
	    die "wrong argument $usage";
	}
	foreach my $entry (@ar){
         if($ar[0] ne uc($ar[0])){
 	    $root = $ar[0]; #first column
	  }else{
	      if($counter>0){ #do not build in hash the roots
		  foreach my $word (parseWords($entry)){
		      $word = NFD($word);  # decompose & reorder canonically
		      if(defined($hash{$languages[$counter].".".$word})){
			  push @{$hash{$languages[$counter].".".$word}},$ar[0];
		      }else{
			  $hash{$languages[$counter].'.'.$word}=[$ar[0]];
		      }
		  }
		  if(substr($entry,0,3) eq '...'){
		  }
	      }
	      $counter++;
	  }
	}
  }
  $lineCounter++;
}

$lineCounter = 0;
%missing = %hash;
# parse vocabulary file line by line
while(my $line = <CP>){
    chomp $line;
    my @ar = split "\t", $line;
    shift @ar; #remove TAGS
    if($lineCounter == 0){ #languages (header)
    	print OUT join("\t",@ar);
	print OUT "\n";
    }else{
	my $counter = 0;
	if (defined($ar[0])){
	    if ($ar[0] =~ /^.*@/){ #skip lines with @ (lax rows)
		next;
	    }
	}
	foreach my $entry (@ar){
	    if($counter == 0){
		print OUT $entry,"\t";
	    }else{
		if ($entry eq '...'){
		    print OUT '...';
		}else{
		    foreach my $w (parseWords($entry)){
			$w = NFD($w); # decompose & reorder canonically
			if($check eq 'nf'){
			    if (defined($hash{$languages[$counter].'.'.$w})){
				print OUT $w,':',"@{$hash{$languages[$counter].'.'.$w}},";
                                #remove entry fom missing
				delete $missing{$languages[$counter].'.'.$w};
			    }else{
				print OUT $w,"NOT FOUND";
			    }
			}
			elsif($check eq 'm'){
			    if (defined($hash{$languages[$counter].'.'.$w})){
#			    print OUT $w,':',"@{$hash{$languages[$counter].'.'.$w}} MULTIPLE,";
				print OUT $w,':';
				my @rootA = @{$hash{$languages[$counter].'.'.$w}};
				if ($#rootA>0){
				    print OUT "@{$hash{$languages[$counter].'.'.$w}} MULTIPLE,";
				}else{
				    print OUT "@{$hash{$languages[$counter].'.'.$w}},";
				}
			    }
			}else{
			    
			}
		    }
		}
		print OUT "\t";
	    }
	    $counter++;
	}
    }
    print OUT "\n";
    $lineCounter++;
}
if ($check eq 'nf'){
    open ERR, '>:encoding(UTF-8)',$errorfile or die $!;
    print ERR "language\tword in Cognate table but not in Comparative file\troot(s)\n";
    foreach my $errors (sort keys %missing){
      $errors =~ /(.*?)\.(.*)/;
      my $roots = join("\t", @{$missing{$errors}});
      print ERR "$1\t$2\t$roots\n";
    }
}

close CP;
close CG;
close OUT;
close ERR;
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
    return @words;
}
#read Cognate table
#for language build hash : 
#  language.meaning=>{word=>root}
#  language.meaning=>{'...'=>root} if there is no word use ... as special case to print ?

#read Vocabulary table
#for each line
# for each language
# parse words one by one
# /<[^<>\[\]\/\/]>/
#  for each word
#    read cognate table hash{language_meaning}
#     language.meaning=>{word=>root}



