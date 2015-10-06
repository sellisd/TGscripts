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

my $Version = 0.1.2;
my $usage = <<HERE;
multistate version $Version
    Parses cognate and comparative files and produces a multistate coding table
    with words and roots
    USAGE multistate.pl [OPTIONS=XX]
    where OPTIONS can be one or more of the following:
    -comparative FILENAME  path and filename of comparative .csv file
    -cognate     FILENAME  path and filename of cognate .csv file
    -choices     FILENAME  path and filename of table with manual choices
    -output      FILENAME  path and filename of output file
    -help or -?            this help screen
HERE

my $cognateFile = '../data/TG_cognates_online_MASTER.csv';
my $comparativeFile = '../data/TG_comparative_lexical_online_MASTER.csv';
my $outputFile = '../data/multistate.csv';
my $choiceFile = '../data/choices.csv';
my $includeWords = 0;
my $help;
unless(GetOptions( 
	   'words'         => \$includeWords,
	   'comparative=s' => \$comparativeFile,
	   'cognate=s'     => \$cognateFile,
	   'choices=s'     => \$choiceFile,
	   'output=s'      => \$outputFile,
	   'help|?'        => \$help
       )){die $usage;}
if($help){
    die $usage;
}
my %choicesH; # hash filled with manually made choices 
if(-f $choiceFile){
    open my $choiceFH, '<:encoding(UTF-8)', $choiceFile or die $!;
    readline($choiceFH); # skip header
    while(my $line = readline($choiceFH)){
	chomp $line;
	next if substr($line,0,1) eq '#';
	(my $language, my $meaning, my $warning, my $decision) = split "\t", $line;
	my $key = $language.$meaning.$warning;
	$choicesH{$key} = $decision;
	
    }
    close $choiceFH;
}

open my $cpfh, '<:encoding(UTF-8)',$comparativeFile or die $!;
open my $cgfh, '<:encoding(UTF-8)',$cognateFile or die $!;
open OUT, '>:encoding(UTF-8)',$outputFile or die $!;
open WARN, '>:encoding(UTF-8)', '../data/notResolvedWarnings.csv' or die $!;
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
		if (defined($err)){
		    print $err, ' at ', $meaning,"\n";
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
			my @compounds;
			foreach my $cognGroup (@{$hashref->{$language.'.'.$w}}){
			    my $root = ${$cognGroup}[0];
			    my $header = ${$cognGroup}[1];
			    my $indmed = ${$cognGroup}[2];
			    my $isComp = ${$cognGroup}[3];
############debug
			    use Data::Dumper;
			if ($meaning eq 'hungry' and $counter == 20){
			    print STDERR $language,"\n";
			    print STDERR $line,"\n";
			    print Dumper @{$hashref->{$language.'.'.$w}};
die;
			}
##############debug
			    if($isComp==1){
				push @compounds, $counterComp; #compound
			    }
			    if($header eq $meaning){
				push @matches, $counterComp;
				if($isComp==1){ #matching compound
				}else{
				    push @matchesNotCompound, $counterComp;
				}
			    }
			    $roots{$root} = 1;
			    $counterComp++;
			}
			#pool is the datastructure entry for one language.word (dereferenced value of hash)
			my @pool = @{$hashref->{$language.'.'.$w}}; #copy for shorthand reference
#			print $counter,' ',$language,' ', $meaning,"\n";
#			if ($counter == 12 and $meaning eq 'eye'){
#			    print $language,' ',$meaning;
#			    print Dumper @pool;
#			    print @compounds,' - ',@matches,' -',@matchesNotCompound;
#			    die;
#			}

			if($#matches==0){                                                         # IF match == 1
			    print OUT $pool[$matches[0]][0];                                      #   PRINT
			    my $indmed = $pool[$matches[0]][2];			         
			    if (defined($indmed)){                                                #   IF IND/MED
				print OUT '.'.$indmed;                                            #     PRINT IND/MED
			    }
			}elsif(! @matches){                                 	                  # ELSE IF match == 0
			    my @rootsA = keys %roots;					         
			    if($#rootsA == 0){			                                  # IF only one root or only identical roots
				print OUT $rootsA[0];                                             #   PRINT
				my $indmed = $pool[0][2];				         
				if (defined($indmed)){                                            #   IF IND/MED
				    print OUT '.'.$indmed;                                        #     PRINT IND/MED
				}
			    }else{                                                                # ELSE
				if($#compounds==0){                                               #   IF compounds==1
				    print OUT $pool[$compounds[0]][0];                            #     PRINT (with MED/IND)
				    my $indmed = $pool[$compounds[0]][2];				         
				    if (defined($indmed)){                                        #   IF IND/MED
					print OUT '.'.$indmed;                                    #     PRINT IND/MED
				    }
				}else{                                                            #   ELSE
				    #check if there is a precomputed solution
				    my $warnString = 'Warning: No cognate set matches meaning (';
				    foreach my $warnings (@pool){			         
					$warnString.= $warnings->[0].' ';
				    }
				    $warnString .=')';		    
				    my $key = $language.$meaning.$warnString;
				    if(defined($choicesH{$key})){
					print OUT $choicesH{$key};
				    }else{
					print OUT $warnString;
					print WARN $language,"\t",$meaning,"\t",$warnString,"\n"; 
				    }
				}			         
			    }								         
			}elsif($#matches > 0){                                                    # ELSE IF match> 1
			    if(!@matchesNotCompound){                                             #   IF all matches are compound
			    	my $warnString = 'Warning: All matches are compound (';
					foreach my $warnings (@pool){
				    $warnString .= $warnings->[0].' ';
				}
				$warnString .= ')';
				my $key = $language.$meaning.$warnString;
				if(defined($choicesH{$key})){
				    print OUT $choicesH{$key};
				}else{
				    print OUT $warnString;
				    print WARN $language,"\t",$meaning,"\t",$warnString,"\n";
				}
			    }elsif($#matchesNotCompound == 0){                                    #   ELSE IF one match is not compound
				print OUT $pool[$matchesNotCompound[0]][0];                       #     PRINT
			    }elsif($#matchesNotCompound > 0){                                     #   ELSE IF more than one matches are not compound
				my $warnString = 'Warning: More than one cognate set matches meaning ('; #     WARNING
				foreach my $warnings (@pool){
				    $warnString .= $warnings->[0].' ';
				}
				$warnString .= ')';
				my $key = $language.$meaning.$warnString;
				if(defined($choicesH{$key})){
				    print OUT $choicesH{$key};
				}else{
				    print OUT $warnString;
				    print WARN $language,"\t",$meaning,"\t",$warnString,"\n";		
				}
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
close WARN;

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
	my %tags;
	my $isComp = 0;
	my $indmed;
	foreach my $tag (@tags){
	    if ($tag eq 'COMPOUND' or $tag eq 'COMPLEX'){
		$isComp = 1;
	    }
	    if($tag eq 'IND'){
		$indmed = 'IND';
	    }elsif($tag eq 'MED'){
		$indmed = 'MED';
	    }
	}
	if($lineCounter == 0){ #languages (header)
	    push @languages, @ar;
	    shift @languages; # remove English
	}else{
	    if(!defined($ar[0])){
		die $line;
	    }
	    # Do not filter Xs
	    next if $ar[0] =~ /^.*X$/;
	    my $counter = 0;
	    my $root = shift @ar;
	    $root =~ s/^\s*(\S+)\s*$/$1/;
	    if($root ne uc($root)){
		#first column;
		$rootHeader = $root;
		next;
	    }
	    foreach my $entry (@ar){
		if ($entry =~ /^[\s\f\t]*$/){ # skip emty entries
		    $counter++;
		    next;
		}
		my $wordsref = parseWords($entry);
		my $err = $wordsref->{'err'};
		my @words = @{$wordsref->{'words'}};
		if (defined($err)){
		    print  $err, ' at ',$root,"\n";
		    $counter++;
		    next;
		}else{
		    foreach my $w (@words){
			$w = NFD($w); #decompose & reorder canonically
			if(!defined($languages[$counter])){
			    die;
			}
			my $value = [$root, $rootHeader, $indmed, $isComp ];
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
#    print Dumper %hash;die;
    return (\%hash,\@languages);
}

sub parseWords{
    my $string = shift @_;
    my $inWord = 0;
    my $wordCount = 0;
    my @words;
    my $openDelim;
    my $errors;
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
		if($char eq '>' and $openDelim eq '<'){
		}elsif($char eq ']' and $openDelim eq '['){
		}elsif($char eq '/' and $openDelim eq '/'){
		}else{
		    $errors = "Error parsing: $string";
		}
	    }else{
		$words[$wordCount].=$char;
	    }
	    
	}
    }
    if ($inWord == 1){
	$errors = "Error parsing: $string";
    }
    my %uniqH;
    foreach my $w (@words){
	$w = NFD($w); #decompose & reorder canonically
	$uniqH{$w} = 1;
    }
    @words = keys %uniqH;
    my $returnValue = {'words' => \@words,
		       'err'   => $errors};
    return $returnValue;
}
