#!/usr/bin/env sh

# Switch to directory the script resides in
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

cd ..
cd ..

# TODO: install dependencies
sudo apt-get update
sudo apt-get install -y python-pandas python-pyproj

ANALYSISID=$(basename "$PWD")
SERVERURL="http://ec2-18-212-144-200.compute-1.amazonaws.com" # TODO

RESULTSCSV="results.csv"
wget -O $RESULTSCSV "$SERVERURL/analyses/$ANALYSISID/download_data.csv?export=true"
python lib/resources/results_savings_csv.py -r $RESULTSCSV