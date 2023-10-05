#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --qos=debug
#SBATCH --time=00:30:00
#SBATCH --constraint=cpu
#SBATCH --account=m2173

srun -n 128 python ./MPI_Test.py