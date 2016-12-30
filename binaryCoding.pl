#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use feature 'unicode_strings';
use Getopt::Long;

#Usage:
# input tab separated file
#make binary ecnoding of comparative file
my $help;
my $threedots = '?';
my $file;
my $output;
my $usage = <<HERE;
USAGE binaryCoding.pl [OPTIONS = XX] inputFileName outputFileName
where OPTIONS can be one or more of the following:
  -input  FILENAME path and file name of input (cognate .csv file)
  -output FILENAME path and file name of output file
  -threedots       What symbol is used in the input either ? (default) or ...
  -help or -?      this help screen
HERE
unless(GetOptions(
	   'input=s'     => \$file,
	   'output=s'    => \$output,
	   'threedots=s' => \$threedots,
	   'help|?'      => \$help
       )){die $usage;}
if($help){
    die $usage;
}

die $usage unless -f $file;

my $outSep = "\t";
my $inSep = "\t";
#my $file = 'Sampe_TG_coding.csv';
open IN, '<:encoding(UTF-8)',$file or die $!;
open OUT, '>:encoding(UTF-8)',$output or die $!;
#get title
my $header = <IN>;
chomp $header;
my @header = split $inSep, $header;
print OUT ''.$outSep; # empty for compatibility with Mesquite
my $counter = 0;
my $previous;
my $current;
foreach my $number (@header){
    if($number eq uc($number)){
	$current = 'Capital';
    }else{
	$current = 'small';
    }
    if ($counter>0){
        # ignore first title
	if($previous eq 'small' and $current eq 'small'){
	    print "Error !!!!: $number $counter\n";
	}
	#print header
	if($current eq 'Capital'){
	    print OUT $number,$outSep;
	}
    }else{
	$current = 'Capital';
    }
    $previous = $current;
    $counter++;
}
print OUT "\n";
while (my $line = <IN>){
    chomp $line;
    my @ar = split $inSep, $line;
    my $counter = 0;
    my $dots = -1;
    print OUT $ar[0],$outSep;#print language
    foreach my $title (@header){
	if($counter > 0){ # do not process the first column (with Language names)
	    my $word;
	    if(defined($ar[$counter])){
		$word = $ar[$counter];
	    }else{
		$word = '';
	    }
	    if ($title ne uc($title)){ #lowercase
		$dots = $word;
	    }elsif($title eq uc($title)){
		if(substr($dots,0,3) ne $threedots){
		    if($word ne ''){
			print OUT 1,$outSep;
		    }elsif($word eq ''){
			print OUT 0,$outSep;
		    }else{
			die "1. ups!\n"
		    }
		}elsif(substr($dots,0,3) eq $threedots){
		    if($word){
			print OUT 1,$outSep;
		    }elsif($word eq ''){
			print OUT '?'.$outSep;
		    }else{
			die "2. ups!\n";
		    }
		}
		else{
		    die "4. ups!\n";
		}
	    }
	}
	$counter++;
    }
    print OUT "\n";
}
# if empty
#     if word 1
#     if empty 0
# if threedots
#     if word 1
#     if empty ?
# http://www.thegeekstuff.com/2011/12/perl-and-excel/
#http://perldoc.perl.org/perlunitut.html
