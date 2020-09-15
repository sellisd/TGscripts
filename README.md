# Utilities for linguistics

## Multistate to binary coding

The script `multistate2binary.py` will transform a multistate matrix to a binary.

The input format is expected as a tab delimited file with the following format:

|         | cognate1 | cognate2 |cognate3|
|---------|----------|----------|--------|
|language1|  1       | 1        |   1    |
|language2|  1       | 1,2      |   2    |
|language3|  2       |  ?       |   2    |

Assuming the above table is in file `wordlist.tsv` to perform the transformation:


```bash
./multistate2binary.py --transpose ./wordlist.tsv coded.tsv
```

the `--transpose` option is not necessary if languages are in columns and cognates are in the rows of the table.
