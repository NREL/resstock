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

LOCKFILE="LOCK"

if ! [ -f $LOCKFILE ]; then
  touch $LOCKFILE
  
  # Download weather zip
  `curl -O "$1"`
  
  FILENAME="${1##*/}"
  if ! [ -f $FILENAME ]; then
    # TODO: Retry download several times?
    echo ERROR: "$FILENAME not successfully downloaded. Aborting..."
    exit 1
  fi
  
  # Extract files
  unzip -o $FILENAME

  NUMDIREPWS=$(ls -l *.epw | wc -l)
  echo "$NUMDIREPWS EPWs available."
  
  # Let other scripts know that we are done
  rm $LOCKFILE
else
  
  i="0"
  while [ -f $LOCKFILE ]; do
    sleep 30 # seconds
    i=$[$i+1]
    if [ $i -eq "20" ]; then
      echo "Wait time exceeded. Aborting..."
      exit 1
    fi
  done
  
  NUMDIREPWS=$(ls -l *.epw | wc -l)
  echo "$NUMDIREPWS EPWs available."
fi
