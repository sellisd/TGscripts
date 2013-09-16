#!/usr/bin/perl
use strict;
use warnings;
use Encode;
use feature 'unicode_strings';
use Unicode::Normalize;
use Getopt::Long;
binmode(STDOUT, ":utf8");

# filter a cognates file leaving out Xs and
# words that do not belong to a group defined with tags
# in the corresponding comparative file

my $Version = 0.1;
my $usage = <<HERE;
filterTag version $Version
    USAGE ./filterTag.pl [OPTIONS=XX]
where OPTIONS can be one or more of the following:

 -include     TAGLIST   list of TAGS to include separated by commas
 -exclude     TAGLIST   list of TAGS to exclude separated by commas. Exclude has
                         priority over include, i.e if a line has both included 
                         and excluded tags it will be excluded
 -comparative FILENAME  path and filename of comparative .csv file
 -cognate     FILENAME  path and filename of cognate .csv file
 -output      FILENAME  path and filename of output file
 -help or -?            this help screen
HERE


my $cognateFile = 'TG_cognates.13.09.14.17.15.csv'; #transposed
my $comparativeFile = 'TG_comparative.13.09.14.17.15.csv';
#my $cognateFile = 'TG_cognates.13.09.03.18.44.csv'; #transposed
#my $comparativeFile = 'TG_comparative.13.09.03.18.44.csv';
my $outputFile = 'filtered.csv';
my @include;
my @exclude;
my $help;
unless(GetOptions( 
        'include=s'     => \@include,
        'exclude=s'     => \@exclude,
        'comparative=s' => \$comparativeFile,
        'cognate=s'     => \$cognateFile,
        'output=s'      => \$outputFile,
        'help|?'        => \$help
       )){die $usage;}
if($help){
   die $usage;
}

@include = split(',',join(',',@include));
@exclude = split(',',join(',',@exclude));
my %conflicting;
foreach (@include){
  $conflicting{$_}=1;
}
foreach (@exclude){
  if(defined($conflicting{$_})){
    print "$_ cannot be included AND excluded\n";
    die;
  }
}
print "filtering...\n";
print "Comparative File: $comparativeFile\n";
print "Cognate File: $cognateFile\n";
print "Output File:  $outputFile\n";
print "Included TAGS: @include\n";
print "Excluded TAGS: @exclude\n";

open CG, '<:encoding(UTF-8)',$cognateFile or die $!;
open CP, '<:encoding(UTF-8)',$comparativeFile or die $!;
open OUT, '>:encoding(UTF-8)',$outputFile or die $!;

my %hash;
while (my $line = <CP>){
    chomp $line;
    next if $line =~ /^[\t\s\f\n]+$/; #skip empty lines
my @ar = split "\t", $line;
next if $ar[1] =~ /^.*\@$/;#ignore lax rows
next if $ar[0] =~ /^[\t\s\f\n]*$/;#only keep tags
if(defined($hash{$ar[1]})){
    die "meaning appeared twice! $ar[1]";
}else{
    $hash{$ar[1]}=$ar[0];
}
}
# use Data::Dumper;
# print Dumper %hash;
# die;
#clean cognate files from Xs and empty lines
my $lineCounter = 0;
my $meaning = '' ;
while (my $line = <CG>){
    $lineCounter++;
next if $line =~ /^[\t\s\f\n]+$/; #skip empty lines
my @ar = split "\t", $line;
shift @ar; #remove column with COMPLEX etc
$line = join ("\t",@ar);
#$line.="\n";
if ($lineCounter == 1){
    print OUT $line;
    next;
}

next if $ar[0] =~ /^.*X$/; #skip Xs
if($ar[0] ne uc($ar[0])){ # small case
    $meaning = $ar[0];
}
my $skip;
if(@include){
    if(@exclude){
	$skip = 1; #if both exclude everything by default
    }else{
	$skip = 1; #if only include is given exclude everythign by default
    }
}else{
    if(@exclude){
	$skip = 0; #if only exclude is given include everything by default
    }else{
	$skip = 0; #if none include all by default
    }
}
my $tagString = '';
if(defined($hash{$meaning})){
    $tagString = $hash{$meaning};
}
my @tags = split /,\s*/,$tagString;
#foreach tag check if it is included or excluded
foreach my $i (@include){
    foreach my $t(@tags){
	if ($i eq $t){
	    $skip = 0;
	}
    }
}
foreach my $e (@exclude){
    foreach my $t(@tags){
	if($e eq $t){
	    $skip = 1;
	}
    }
}
if ($skip == 0){
    print OUT $line;
}elsif ($skip == 1){
    next;
}
}

close CP;
close CG;
close OUT;
