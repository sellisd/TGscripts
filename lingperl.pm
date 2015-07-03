# commonly used functions
sub parseWords{
    my $version = "1.0.0";
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
1;
