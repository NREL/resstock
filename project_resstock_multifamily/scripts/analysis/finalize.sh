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
ARGS="-r $RESULTSCSV$REFUPGS -e all"

CALL="python lib/scripts/results_savings_csv.py $ARGS"
echo "Calling: $CALL"
eval $CALL

cd ../../assets/analyses/$ANALYSISID/original
cp /mnt/openstudio/server/analyses/$ANALYSISID/results_savings.csv .
SEED=$(echo *.zip)
ZIP="zip $SEED results_savings.csv"
echo "Zipping: $ZIP"
eval $ZIP