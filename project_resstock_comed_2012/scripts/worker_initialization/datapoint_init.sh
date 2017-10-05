#!/usr/bin/env sh

# Switch to directory the script resides in
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

# Create and enter ../../weather dir
cd ..
cd ..
if ! [ -d "weather" ]; then
  mkdir "weather"
fi
cd "weather"

FILENAME="${1##*/}"

if ! [ -f $FILENAME ]; then

  NUMEPWS="0"
  CNT="0"
  
  # Download and extract weather files
  echo "Retrieving weather files."
  while [ $NUMEPWS -le "1" ]; do
  
    curl --retry 10 -O "$1"
    
    if ! [ -f $FILENAME ]; then
      echo "ERROR: $FILENAME not successfully downloaded. Aborting..."
      exit 1
    fi
    
    unzip -o $FILENAME

    NUMEPWS=$(ls -l *.epw | wc -l)
    
    CNT=$((CNT+1))
    
    if [ $CNT -eq "10" ]; then
      echo "ERROR: Maximum number of retries ($CNT) exceeded. Aborting..."
      exit 1
    fi
  
  done
  
  cd ..

  # Run sampling script; if script has been uploaded, use that instead.
  OUTCSV="buildstock.csv"
  if ! [ -f "lib/housing_characteristics/$OUTCSV" ]; then
  
    echo "Generating buildstock.csv sampling results."
    
    NUMDATAPOINTS=`awk -F\"maximum\": 'NF>=2 {print $2}' analysis.json | sed 's/,//g' | head -n1 | xargs` # Yes, this is gross.
    echo "NUMDATAPOINTS is $NUMDATAPOINTS"

    ruby lib/resources/run_sampling.rb -p NA -n $NUMDATAPOINTS -o $OUTCSV

    cp "lib/resources/$OUTCSV" "lib/housing_characteristics/$OUTCSV"
    
  else
  
    echo "Using uploaded buildstock.csv."
  
  fi
  
else

  NUMEPWS=$(ls -l *.epw | wc -l)
  
fi

echo "$NUMEPWS EPWs available."
