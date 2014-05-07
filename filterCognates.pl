#!/usr/bin/perl
use strict;
use warnings;
use Encode;
use feature 'unicode_strings';
use Unicode::Normalize;
binmode(STDOUT, ":utf8");
my $input = '../data/TG_cognates_online_MASTER.csv';
my @filterTags = qw/IND MED/;
my $output = $input;
my $suffix = join '.',@filterTags;
$output =~s/\.csv/.no.$suffix.csv/;
#filter cognates file based on various criteria, e.g.removing all rows that have IND tag
#                                                   or keeping only the GEN (COMPOUND OR COMPLEX) tags

open IN, '<:encoding(UTF-8)',$input or die $!;
open OUT, '>:encoding(UTF-8)',$output or die $!;
while (my $line = <IN>){
    next if $line =~ /^[\s\t\f\n\r]*$/; #skip emtpy lines
    my @ar = split "\t", $line;
    my @tags = split /,\s*/, $ar[0]; #split first entry to tags
    my %tags;
    next if($ar[1] =~ /.*X$/);#filter Xs
    foreach my $tag (@tags){
	$tags{$tag}=1;
    }
    my $excluded = 0; #FALSE
    foreach my $tag2filter(@filterTags){
	if(defined($tags{$tag2filter})){
	    $excluded = 1;
	}
    }
    if($excluded == 1){
     #print nothing
    }else{
	print OUT $line;
    }
    # if(defined($tags{"COMPOUND"}) or defined($tags{"COMPLEX"})){
    # 	if(defined("GEN")){
    # 	    print OUT $line;
    # 	}
    # }else{
    # 	print OUT $line;
    # }
#    next if($ar[0] =~ /IND/); #filter by Tag remove IND
#    print OUT $line;
}
close IN;
close OUT;
