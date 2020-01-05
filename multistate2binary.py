#!/usr/bin/env python
from __future__ import print_function, division
import pandas as pd
import numpy as np
from sklearn.preprocessing import MultiLabelBinarizer
import re
# # Transform Multistate to binary format with new
# tables (Bantu project)
multistate = pd.read_table("../data/Bantu/WCB binary coding NEW SET 20190103 - _basic_ vocabulary concepts.tsv",
  sep = "\t",
  index_col = 1)
#check for empty entries
assert multistate.isnull().any().any() == False

coding = []
for column in multistate:
  if column[-1] == '#':
    vector = multistate[column].str.split('\s*[,;]\s*')
    mlb = MultiLabelBinarizer()
    try:
        encodedArray = mlb.fit_transform(vector)
    except:
        print(vector)
        continue
    header = [column[:-1] + i for i in mlb.classes_]
    encoded = pd.DataFrame(encodedArray, columns = header)
    missing_data_category = column[:-1] + '?'
    if missing_data_category in encoded: #if missing data
      encoded.loc[encoded[missing_data_category]==1]='?' # state of missing data
      encoded = encoded.drop(labels=missing_data_category, axis = 1)
    coding.append(encoded)
coding = pd.concat(coding,axis=1)
coding.index = multistate.index
# no need to transpose
#coding_transposed = coding.transpose()
coding.columns = [re.sub('[\s\(\)]+','_',i) for i in coding.columns]
coding.to_csv("../data/Bantu/coding.csv", sep="\t")


# sannity check
# coding_manually = pd.read_table("../data/Bantu/BantuCognates 20181109 - coding.tsv",
#   sep = "\t",
#   index_col = 1)
# header_manual = ['heart'+str(i) for i in range(1, 10)]
# header_coding = ['heart'+'_'+str(i) for i in range(1, 10)]
# a = coding_manually[header_manual]
# b = coding[header_coding]
# b.columns = a.columns
# assert a.equals(b) == True
