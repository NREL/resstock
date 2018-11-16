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
  time=$(date +%T)
  echo "$time Retrieving weather files."
  while [ $NUMEPWS -le "1" ]; do
  
    curl --retry 10 -O "$1"
    
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

ANALYSISID=$(basename "$PWD")
GEMFILEUPDATE="/var/oscli/$ANALYSISID.lock"
if [ -e $GEMFILEUPDATE ]
then
  echo "***The gem bundle has already been updated"
  exit
fi

# Gemfile for OpenStudio
GEMFILE='/var/oscli/Gemfile'
GEMFILEDIR='/var/oscli'

# Modify the reference Gemfile in place
cp /usr/local/openstudio-$OPENSTUDIO_VERSION/Ruby/Gemfile $GEMFILEDIR

NEWGEM="gem 'aws-sdk-s3', '~> 1'"
echo $NEWGEM >> $GEMFILE

# Pull the wfg from develop because otherwise `require 'openstudio-workflow'` fails
WFG="gem 'openstudio-workflow'"
NEWWFG="gem 'openstudio-workflow', github: 'NREL/openstudio-workflow-gem', branch: 'develop'"
sed -i -e "s|$WFG.*|$NEWWFG|g" $GEMFILE

# Show the modified Gemfile contents in the log
cd $GEMFILEDIR
dos2unix $GEMFILE
echo "***Here is the modified Gemfile:"
cat $GEMFILE

# Set & unset the required env vars
for evar in $(env | cut -d '=' -f 1 | grep ^BUNDLE); do unset $evar; done
for evar in $(env | cut -d '=' -f 1 | grep ^GEM); do unset $evar; done
for evar in $(env | cut -d '=' -f 1 | grep ^RUBY); do unset $evar; done
export HOME=/root
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export RUBYLIB=/usr/local/openstudio-$OPENSTUDIO_VERSION/Ruby:/usr/Ruby

# Update the specified gem in the bundle
echo "***Updating the specified gem:"
rm Gemfile.lock
bundle _1.14.4_ install --path gems

# Note that the bundle has been updated
echo >> $GEMFILEUPDATE