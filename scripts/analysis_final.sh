#!/usr/bin/env sh

# Switch to directory the script resides in
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

cd ..
cd ..

sudo apt-get update
sudo apt-get install -y python-pandas python-pyproj

ANALYSISID=$(basename "$PWD")
SERVERURL="http://ec2-18-212-144-200.compute-1.amazonaws.com" # TODO: get server url

RESULTSCSV="results.csv"
wget -O $RESULTSCSV "$SERVERURL/analyses/$ANALYSISID/download_data.csv?export=true"
python lib/resources/results_savings_csv.py -r $RESULTSCSV -e location -e reportable_domain -e egrid_subregions -e source_energy -e total_utility_bill -e simple_payback -e net_present_value

# TODO: how to get results_savings.csv out of web-background? create api endpoint or something?