# TG analysis

## Preprocess data
The first step is to reformat the data from google docs to tab delimited files in order to perform the analysis. To do so:

 - before downloading search all sheets for \\n !#()@#
 - Download as .ods `TG_cognates_online_Master` and `TG_comparative_online_Master`
 - merge sheets in cognates file
 - remove all extra columns and rows, leave only one header row with languages and two left columns, one with TAGS and one with English
 - save as -> Text .csv -> edit saving settings
 - field delimiter tab, text delimiter none, do not save cells as shown
 
## Validate data
A series of validation scripts check for discrepancies between the two tables or other common errors (typos etc)

 - `./check.pl -check nf -comparative ../data/TG_comparative_lexical_online_MASTER.csv  -cognate ../data/TG_cognates_online_MASTER.csv`
 - `./threedots.pl`
 - `./makeX.pl`

## Transform data
For the phylogenetic analysis we create character matrices.
`./multistate.pl -cognate ../data/TG_cognates_online_MASTER.csv -comparative ../data/TG_comparative_lexical_online_MASTER.csv -output ../data/multistate.csv > ../data/multistate.errors.txt`
which should not produce any errors
manually remove warnings
## GA coding (Grey & Attkinson: multistate + binary recoding)

IND and MED are completely ignored
`./recode.pl '../data/GA multistate output MASTER.csv' > ../data/recodedMatrix.csv` recode multistate to binary recoded matrix

Prepare for downstream analysis
 
 - transpose file
`./transpose.pl ../data/recodedMatrix.csv ../data/recodedMatrix.tr.csv`
 - edit with emacs to make sure English is removed from the header of the first column


## NZLKE Multistate coding (true miultistate coding)
1. `multistate.pl` (replaced `multi2binary.pl`)
reads the output file from `convert.pl` (with option `-check nf`) and produces a multistate coding table with words and roots (if option `-words` is set then in the output file the words are also included e.g  `<word>ROOT1` instead of `ROOT` in each entry)

2. `multistateEncode.pl -input ../data/multistate.csv -output ../data/multiMatrix.csv`
Reads output from `multistate.pl` and replaces roots with numbers and three dots (...) with question marks (?). For numbering it uses mesquite Numbering (0-9, A-H,K-N,P-Z,a-h,k-n,p-z)

## Binary coding

    ./filterTag.pl -exclude FUNCT -comparative ../data/TG_comparative_lexical_online_MASTER.csv -cognate ../data/TG_cognates_online_MASTER.csv -output ../data/cognates.noFUNCT.csv
    ./filterCognates.pl ../data/cognates.noFUNCT.csv
    ./transpose.pl ../data/cognates.noFUNCT.no.IND.MED.csv ../data/cognates.noFUNCT.no.IND.MED.tr.csv
    ./binaryCoding.pl ../data/cognates.noFUNCT.no.IND.MED.tr.csv ../data/cognates.noFUNCT.no.IND.MED.tr.bin.csv


if errors are produced, go back to the untransposed file and remove consecutive small
open with mesquite