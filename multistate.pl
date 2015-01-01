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

my $Version = 0.02;
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
#print Dumper $hashref;die;
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
	    my @foundCompound;
	    my @matches;
	    my %roots;
	    my $counterComp = 0;
	    foreach my $cognGroup (@{$hashref->{$language.'.'.$w}}){
	      my $root = ${$cognGroup}[0];
	      my $header = ${$cognGroup}[1];
	      my $tagsRef = ${$cognGroup}[2];
	      if(defined($tagsRef->{'COMPOUND'}) or defined($tagsRef->{'COMPLEX'})){
		push @foundCompound, $counterComp;
	      }
	      if($header eq $meaning){
		push @matches, $counterComp;
	      }
	      $roots{$root} = 1;
	      $counterComp++;
	    }
	    my $rootNo = keys %roots;
	    if(! @foundCompound){                                                        # IF no compounds
	      if($rootNo == 0){                                                           #   IF all roots are the same
		print OUT $hashref->{$language.'.'.$w}[0][0];                             #     PRINT the first or only one
	      }else{                                                                      #   ELSE
		print OUT "Warning - Multiple roots: ";                                   #     WARNING
		print OUT Dumper($hashref->{$language.'.'.$w});	                          
	      }							                          
	    }elsif($#foundCompound>1){                                                    # ELSE IF more than one compounds
	      print OUT "Warning - More than 2 compounds: ";                              #   WARNING
	      print OUT Dumper($hashref->{$language.'.'.$w});	                          
   #	      print OUT "Il y a une couille dans le potage\n";	                          
	    }elsif($#foundCompound == 0){                                                 # ELSE IF one compounds
	      my $cognateSetNo = $#{$hashref->{$language.'.'.$w}};
	      if($cognateSetNo == 0){                                                     #   IF it belongs to only one cognate set
	     	print OUT ${$hashref->{$language.'.'.$w}}[0][0];                          #     PRINT
	      }elsif($cognateSetNo >0){                                                   #   ELSE IF it belongs to multiple cognate sets
		if(${$hashref->{$language.'.'.$w}}[$foundCompound[0]][1] eq $meaning){    #     IF headerOfCompound == meaning
		  if($#matches==0){                                                       #       IF only one match
		    print OUT ${$hashref->{$language.'.'.$w}}[$foundCompound[0]][0];      #         PRINT COMPOUND 
		    #	    print OUT IND MED
		  }elsif($#matches==1){                                                   #       ELSE IF two matches
		    #print other (not COMPLEX)                                                                #         PRINT other
		  }elsif($#matches>1){                                                    #       ELSE IF more than two matches
		    print OUT "Warning - More than two headers match meaning: ";          #         WARNING
		    print OUT Dumper($hashref->{$language.'.'.$w});
		  }
		}else{                                                                    #    ELSE
		  print OUT "Warning - header of Compound does not match meaning: ";      #      WARNING
		  print OUT Dumper($hashref->{$language.'.'.$w});
		}
	      }
	    }
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

sub printCell{
  # formats a string for printing from data structure
  # &printCell(ds,word,printWord) if printWord = TRUE also prints word
  my $dsRef = shift @_;
  my $word = shift @_;
  my $printWord = shift @_;
  my $ind = 0;
  my $med = 0;
  my $returnValue;
  #print Dumper $dsRef;
  for( my $i=0; $i<= $#{$dsRef};$i++){
    if(defined(${$dsRef}[$i][2]->{'IND'})){
      $ind = 1;
    }
    if(defined(${$dsRef}[$i][2]->{'MED'})){
      $med = 1;
    }
    if($printWord == 1){
      $returnValue .= $word.';'.${$dsRef}[$i][0].($ind?'.IND':'').($med?'.MED':'').';';
    }else{
      $returnValue .= ${$dsRef}[$i][0].($ind?'.IND':'').($med?'.MED':'').';';
    }
  }
  return $returnValue;
}

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
#	    shift @languages; # Do not remove English
	}else{
            #filter Xs
	    if(!defined($ar[0])){
		die $line;
	       }
	    next if $ar[0] =~ /^.*X$/;
	    my $counter = 0;
	    my $root = shift @ar;
	    if($root ne uc($root)){
              #first column;
	      $rootHeader = $root;
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

