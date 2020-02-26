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

FILENAME="weather.zip"

if ! [ -f $FILENAME ]; then

  NUMEPWS="0"
  CNT="0"

  # Download and extract weather files
  time=$(date +%T)
  echo "$time Retrieving weather files."
  while [ $NUMEPWS -le "1" ]; do

    curl --retry 10 -L -o $FILENAME "$1"

    if ! [ -f $FILENAME ]; then
      time=$(date +%T)
      echo "$time ERROR: $FILENAME not successfully downloaded. Aborting..."
      exit 1
    fi

    unzip -o $FILENAME

    NUMEPWS=$(ls -l *.epw | wc -l)

    CNT=$((CNT+1))

    if [ $CNT -eq "10" ]; then
      time=$(date +%T)
      echo "$time ERROR: Maximum number of retries ($CNT) exceeded. Aborting..."
      exit 1
    fi

  done

  cd ..

  # Run sampling script; if script has been uploaded, use that instead.
  OUTCSV="buildstock.csv"
  if ! [ -f "lib/housing_characteristics/$OUTCSV" ]; then

    time=$(date +%T)
    echo "$time Generating buildstock.csv sampling results."

    NUMDATAPOINTS=`awk -F\"maximum\": 'NF>=2 {print $2}' analysis.json | sed 's/,//g' | head -n1 | xargs` # Yes, this is gross.
    time=$(date +%T)
    echo "$time NUMDATAPOINTS is $NUMDATAPOINTS"

    ruby lib/resources/run_sampling.rb -p NA -n $NUMDATAPOINTS -o $OUTCSV

    cp "lib/resources/$OUTCSV" "lib/housing_characteristics/$OUTCSV"

  else

    time=$(date +%T)
    echo "$time Using uploaded buildstock.csv."

  fi

else

  NUMEPWS=$(ls -l *.epw | wc -l)

fi

time=$(date +%T)
echo "$time $NUMEPWS EPWs available."
