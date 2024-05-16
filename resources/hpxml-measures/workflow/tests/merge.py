import os
import sys
import pandas as pd


# Combines two CSV files (that have potentially different column names).

if __name__ == "__main__":

    if len(sys.argv) != 4:
        sys.exit("Usage: merge.py file1.csv file2.csv merged.csv")

    csv1_path = os.path.abspath(sys.argv[1])
    csv2_path = os.path.abspath(sys.argv[2])
    merged_path = os.path.abspath(sys.argv[3])

    df1 = pd.read_csv(csv1_path)
    df2 = pd.read_csv(csv2_path)

    df3 = pd.concat([df1, df2], ignore_index=True)

    df3.to_csv(merged_path, index=False)
