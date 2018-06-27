#!/bin/bash

#PBS -j oe
#PBS -A res_stock
#PBS -l walltime=2:00:00
#PBS -l nodes=1
#PBS -q short
#PBS -l feature=24core


module use /nopt/nrel/apps/modules/candidate/modulefiles
module load conda/5.0

source activate ruby

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
cd ..
time ruby scripts/download_datapoints.rb -p $PROJECT_DIR -s $OS_SERVER_URL
