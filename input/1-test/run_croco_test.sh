#!/bin/bash
# Submission script for NIC5
#SBATCH --job-name=CROCO-AGRIF-Canary
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=00:05:00 # hh:mm:ss

#SBATCH --ntasks=128
#SBATCH --mem-per-cpu=500 # megabytes
#SBATCH --partition=batch
#
#SBATCH --mail-user=ctroupin@uliege.be
#SBATCH --mail-type=ALL

module --force purge
module load releases/2023b
module load intel-compilers
module load iimpi

export I_MPI_PMI=pmi2
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi2.so

compiler="ifx"
TARGETDIR=~/.local/${compiler}
mkdir -pv ${TARGETDIR}
export PATH=${TARGETDIR}/bin/:$PATH
export LD_LIBRARY_PATH=${TARGETDIR}/lib:${LD_LIBRARY_PATH}

cd /home/ulg/gher/ctroupin/CROCO_Canary/croco-v2.1.2/OCEAN/
SECONDS=0
srun --mpi=pmi2 croco_32_4 croco_test.in
duration=$SECONDS
echo $SECONDS
echo "$((duration / 60)) minutes and $((duration % 60)) seconds elapsed."
