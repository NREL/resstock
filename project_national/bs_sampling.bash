#!/bin/bash
#SBATCH --account=enduse
#SBATCH --time=1 # estimated time in minutes
#SBATCH --job-name=buildstock_sampling
#SBATCH --nodes=8
#SBATCH --output=fb.%j.out
#SBATCH --mail-user peter.berrill@yale.edu.gov
#SBATCH --mail-type BEGIN,END,FAIL
#module load conda
#source activate  /shared-projects/buildstock/envs/buildstock-0.19
srun buildstock_eagle national2020_eagle.yml