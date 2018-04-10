#!/bin/bash

module use /nopt/nrel/apps/modules/candidate/modulefiles
module load conda/5.0

conda env create -f environment.yml

source activate ruby

gem install bundler

bundle install

