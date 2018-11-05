#!/usr/bin/env sh

# Switch to directory the script resides in
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

cd ..
cd ..

REFUPGS=""
for REFUPG in "$@"
do
REFUPGS="$REFUPGS -u '$REFUPG'"
done

sudo apt-get update
sudo apt-get install -y python-pandas python-pyproj

ANALYSISID=$(basename "$PWD")
RESULTSCSV="results.csv"

wget -O $RESULTSCSV "http://web/analyses/$ANALYSISID/download_data.csv?export=true"
ARGS="-r $RESULTSCSV $REFUPGS -e egrid_subregions -e location -e net_present_value -e reportable_domain -e simple_payback -e source_energy -e total_utility_bill"

CALL="python lib/resources/results_savings_csv.py $ARGS"
echo "Calling: $CALL"
eval $CALL