#!/usr/bin/perl
use warnings;
use strict;

my $file = '';
my $lineCounter = 0;
open IN, $file or die $!;
my @languages;
my $row = 0;
my $column;
while(my $line = <IN>){
	chomp $line,
	my @ar = split "\t", $line;
	shirt @ar; # discard Column with No
	if($lineCounter == 0){
      # header;	
      @languages = @ar;
	}else{
		#make table with rows languages and columns meanings
		push @meanings, $ar[0].$ar[1];
		for(my $col = 0; $col <= $#ar; $col++){
			$table[$row][$col] = $word;			
		}
		#Wari manyA -     manyB -
		#Jaru manyA word  manyB ?
		$row++;
# manyA Wari 0 Jaru 1
# many B Wari 0 Jaru?
		my $hash{$ar[0].$ar[1]}
	}
	$lineCounter++;
}
close IN;

#loop through table vertically 
for(my $i = $)