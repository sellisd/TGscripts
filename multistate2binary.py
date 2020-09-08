#!/usr/bin/env python
import pandas as pd
import numpy as np
from sklearn.preprocessing import MultiLabelBinarizer
import re
import typer


def import_file(filename):
    """Import matrix, assumes tab-delimited file

      Args:
          filename (string): path and file name.

      Returns:
          dataframe: multistate dataframe
    """
    multistate = pd.read_table(filename,
                               sep="\t",
                               dtype=str,
                               index_col=0)
    return multistate

pd.set_option("display.max_rows", None, "display.max_columns", None)

def check_format(df):
    """Validate input format

    Args:
        multistate (dataframe): multistate dataframe
    """
    if empty_entries(df):
        print("Error: file has empty entries")
        return(False)
    if invalid_characters_in_entries(df):
        print("Error: invalid characters in entries (valid are only , ?0-9)")
        return(False)
    return True


def empty_entries(df):
    """Check if there are empty entries

    Args:
        df (dataframe): multistate dataframe

    Returns:
        Bool: True for valid format
    """
    if df.isnull().any().any():
        return True
    return False


def invalid_characters_in_entries(df):
    r = re.compile(r'^[0-9\s,?]+$')
    if df.applymap(lambda x: bool(r.match(x))).all().all():
        return False
    return True


def to_binary(multistate):
    """Transform multistate to binary

    Args:
        multistate (dataframe): Multistate

    Returns:
        binary (dataframe): Binary dataframe
    """
    coding = []
    for column in multistate:
        vector = multistate[column].str.split('\s*[,;]\s*')
        mlb = MultiLabelBinarizer()
        try:
            encodedArray = mlb.fit_transform(vector)
        except:
            print(vector)
            continue
        header = [column + i for i in mlb.classes_]
        encoded = pd.DataFrame(encodedArray, columns=header)
        missing_data_category = column + '?'
        if missing_data_category in encoded:  # if missing data
            encoded.loc[encoded[missing_data_category] == 1] = '?'  # state of missing data
            encoded = encoded.drop(labels=missing_data_category, axis=1)
        coding.append(encoded)
    coding = pd.concat(coding, axis=1)
    coding.index = multistate.index
    coding.columns = [re.sub('[\s\(\)]+','_',i) for i in coding.columns]
    return coding


def save_matrix(filename, df):
    """Save output to file

    Args:
        filename (string): Path and filename for output
    """
    df.to_csv(filename, sep="\t")


def main(input: str, output: str):
    multistate = import_file(input)
    if check_format(multistate):
        binary = to_binary(multistate)
        save_matrix(output, binary)
    else:
        print("Aborting transformation due to invalid input")


if __name__ == "__main__":
    typer.run(main)

# # strip white spaces from headers
# multistate = multistate.rename(columns=lambda x: x.strip())



# sanity check
# coding_manually = pd.read_table("../data/Bantu/BantuCognates 20181109 - coding.tsv",
#   sep = "\t",
#   index_col = 1)
# header_manual = ['heart'+str(i) for i in range(1, 10)]
# header_coding = ['heart'+'_'+str(i) for i in range(1, 10)]
# a = coding_manually[header_manual]
# b = coding[header_coding]
# b.columns = a.columns
# assert a.equals(b) == True
