#!/usr/bin/env sh

# Switch to directory the script resides in
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

# Delete selective large files from data_point dir
echo "Cleaning up data_point directory."
DPDIR="data_point_$SCRIPT_DATA_POINT_ID"
cd ..
cd ..

echo "Original files:"
ls -l $DPDIR
ls -l $DPDIR/run
du -h $DPDIR

rm -f $DPDIR/in.osm
rm -f $DPDIR/in.idf

rm -f $DPDIR/run/in.osm
rm -f $DPDIR/run/in.idf
rm -f $DPDIR/run/*.err
rm -f $DPDIR/run/*.json
rm -f $DPDIR/run/*.osw
rm -f $DPDIR/run/*.htm
rm -f $DPDIR/run/*.job
rm -f $DPDIR/run/run.log
rm -f $DPDIR/run/stdout*
rm -r $DPDIR/run/eplusout*

echo "Final files:"
ls -l $DPDIR
ls -l $DPDIR/run
du -h $DPDIR