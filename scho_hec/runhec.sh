#!/bin/bash
#SBATCH --nodes=1
#SBATCH --partition=sesync
#SBATCH --job-name=hec

/research-home/scho/hec-hms-421/hec-hms.sh -s ${SCRIPT}

## call this with:
## sbatch --export=SCRIPT=path/to/script runhec.sh
