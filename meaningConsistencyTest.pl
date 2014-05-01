#!/usr/bin/perl
use warnings;
use strict;
use Encode;
use feature 'unicode_strings';
# version 1
#find meanings that do not have the same spelling across files
#INPUT :cognate.csv
#       comparative.csv
#OUTPUT: missingMeanings.txt
my $cognateFile = '../data/TG_cognates_online_MASTER.csv';
my $comparativeFile = '../data/TG_comparative_online_MASTER.csv';
my $output = '../data/missingMeanings.txt';
my %hash;
open CG, '<:encoding(UTF-8)',$cognateFile or die $!;
open CP, '<:encoding(UTF-8)',$comparativeFile or die $!;
open OUT, '>:encoding(UTF-8)', $output or die $!;

while (my $line = <CG>){
   my @ar = split "\t", $line;
   next unless($ar[1] ne uc($ar[1]));
   next if ($ar[1] =~ /^.*X$/);
   my $meaning = $ar[1]; # $ar[0] is COMPOUND
   $hash{$meaning} = 1;
}

while (my $line = <CP>){
   my @ar = split "\t", $line;
   shift @ar; #remove TAGS
   next if ($ar[0] =~ /^.*\@$/);
   if (defined($hash{$ar[0]})){
       delete $hash{$ar[0]};
       #correct!
   }else{
       $hash{$ar[0]} = 0; # in comparative but not in cognate
   }
}
my @missing1; # in comparative, but not in cognate
my @missing2; # in cognate, but not in comparative
my @missing1_space;
my @missing2_space;
foreach (keys %hash){
    if (checkWordLimits($_)){
	if ($hash{$_} == 1){
	    push @missing2, $_;
	}elsif($hash{$_} == 0){
	    push @missing1, $_;
	}
    }else{
	if ($hash{$_} == 1){
	    push @missing2_space, $_;
	}elsif($hash{$_} == 0){
	    push @missing1_space, $_;
	}
    }
}
close CG;
close CP;

print OUT "\n   Consistency Test Error report using $comparativeFile and $cognateFile\n\n";
print OUT 'meanings in comparative file, but not in cognate (',$#missing1+$#missing1_space+2,"):\n";
print OUT "-----------------------------------------------------\n";
print OUT "\n  with space characters in front or after word:\n";
print OUT join("\n",sort @missing1_space),"\n";
print OUT "\n  other:\n";
print OUT join("\n",sort @missing1),"\n";
print OUT "\nmeanings in cognate file, but not in comparative (",$#missing2+$#missing2_space+2,"):\n";
print OUT "----------------------------------------------------\n";
print OUT "\n  with space characters in front or after word:\n";
print OUT join("\n",sort @missing2_space),"\n";
print OUT "\n  other:\n";
print OUT join("\n",sort @missing2),"\n";
sub checkWordLimits{
#return true if limits are not space
    my $word = shift @_;
    if ($word =~ /^(.*)\s+$/ or $word =~ /^\s+(.*)$/){
	return 0;
    }else{
	return 1;
    }
}
