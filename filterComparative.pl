#!/usr/bin/perl
use strict;
use warnings;
use Encode;
use feature 'unicode_strings';
use Unicode::Normalize;
use Getopt::Long;
binmode(STDOUT, ":utf8");

# filter comparative file for cognates with TAG

my $Version = 0.1;

my $usage = <<HERE;
filterCognates version $Version
    USAGE ./filterCognates.pl [OPTIONS=XX]
where OPTIONS can be one or more of the following:

 -exclude     TAGLIST   list of TAGS to exclude separated by commas.
 -comparative FILENAME  path and filename of comparative .csv file
 -output      FILENAME  path and filename of output file
 -help or -?            this help screen
HERE

my $comparativeFile;
my $outputFile = 'filteredCognates.csv';
my @exclude;
my $help;
unless(GetOptions( 
        'exclude=s'     => \@exclude,
        'comparative=s' => \$comparativeFile,
        'output=s'      => \$outputFile,
        'help|?'        => \$help
       )){die $usage;}
if($help){
   die $usage;
}
die $usage unless(-f $comparativeFile);

print "filtering...\n";
print "Comparative File: $comparativeFile\n";
print "Output File:  $outputFile\n";
print "Excluded TAGS: @exclude\n";

my %exclude;
# make hash from tags to exclude for easier search
foreach my $e (@exclude){
	$exclude{$e} = 1;
}

open CP, '<:encoding(UTF-8)',$comparativeFile or die $!;
open OUT, '>:encoding(UTF-8)',$outputFile or die $!;

my $lineCounter = 0;
while(my $line = <CP>){
	my $skip = 0; # by default do not skip anything
	if($lineCounter==0){

	}else{
		chomp $line;
		my $tagString = (split "\t", $line)[0];
		my @tags = split /,\s*/,$tagString;
		foreach my $tag(@tags){
			if(defined($exclude{$tag})){
				$skip = 1;
				last;
			}
		}
	}
	if($skip){
		# do not print
	}else{
		print OUT $line,"\n";
	}
	$lineCounter++;
}

close CP;
close OUT;

