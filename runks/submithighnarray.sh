#!/bin/bash
#SBATCH job-name=HighN_array
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --array=1-15%5

Rscript --vanilla /research-home/runks/HighN_Example.r