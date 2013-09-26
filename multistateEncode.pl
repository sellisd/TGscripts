#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use List::Util qw/max/;
use List::MoreUtils qw/uniq/;
use feature 'unicode_strings';
use Unicode::Normalize;
use Getopt::Long;
binmode(STDOUT, ":utf8");
my $Version = 0.01;

my $usage = <<HERE;
multistateEncode version $Version
Reads output from multistate.pl and replaces roots with numbers and
three dots (...) with question marks (?). For numbering it uses
mesquite Numbering (0-9, A-H,K-N,P-Z,a-h,k-n,p-z)
    USAGE multistateEncode.pl [OPTIONS=XX]
where OPTIONS can be one or more of the following:
 -input       FILENAME  path and filename of input file
 -output      FILENAME  path and filename of output file
 -help or -?            this help screen
HERE

my $multistateFile = 'multistate.csv';
my $outputFile = '4paup.csv';
my $help;
unless(GetOptions( 
	   'input=s'   => \$multistateFile,
	   'output=s'  => \$outputFile,
	   'help|?'    => \$help
       )){die $usage;}
if($help){
   die $usage;
}

open my $ms, '<:encoding(UTF-8)',$multistateFile or die $!;
open OUT, '>:encoding(UTF-8)', $outputFile or die $!;

my $lineCounter = 0;
my @mesqNumbering = qw/0 1 2 3 4 5 6 7 8 9 
                       A B C D E F G H
                       K L M N 
                       P Q R S T U V W X Y Z
                       a b c d e f g h
                       k l m n
                       p q r s t u v w x y z/;
while(my $line = readline($ms)){
    $lineCounter++;
    next if $line =~ /^[\s\f\t]*$/; #skip empty lines
    chomp $line;
    if($lineCounter == 1){ #languages (header)
	my @ar = split "\t", $line;
#	shift @ar; #remove TAGS from header
	print OUT join"\t",@ar;
	print OUT "\n";
	next;
    }

    my %unique;
    my $index = 0;
    my @ar = split "\t", $line; 
#    my $tags = shift @ar;
    my $meaning = shift @ar;
    print OUT $meaning,"\t";
    foreach my $entry (@ar){
	if($entry eq '...'){
	    print OUT "?\t";
	    next;
	}
	if($entry eq '' or $entry =~ /^;+$/){
	    print OUT "-\t"; #empty entries
	    next;
	}
	my @numbers;
	my @words = split ';', $entry;
	foreach my $w (@words){
	    if(defined($unique{$w})){
	    }else{
		$unique{$w} = $mesqNumbering[$index];
	     	$index++;
	    }
	    push @numbers, $unique{$w};
	}
	print OUT join('&',uniq(@numbers));
	print OUT "\t";
    }
#    print OUT max(@findMaxAr);
    print OUT "\n";
}
close $ms;
close OUT;
