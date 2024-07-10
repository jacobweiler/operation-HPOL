#!/bin/bash

## We want to submit the XFsolver as a job array to GPUs
## We'll submit up to 4 at a time (based on number of XF keys)
## Here's the submission command:
## sbatch --array=1-$NPOP%$batch_size --export=ALL,(variables) GPU_XF_job.sh
#SBATCH -A PAS1960
#SBATCH -t 6:00:00
#SBATCH -N 1
#SBATCH -n 40
#SBATCH -G 2
#SBATCH --output=Run_Outputs/%x/XF_Outputs/XF_%a.output
#SBATCH --error=Run_Outputs/%x/XF_Errors/XF_%a.error
##SBATCH --mem-per-gpu=178gb

module load xfdtd/7.10.2.3
module load cuda

source $WorkingDir/Run_Outputs/$RunName/setup.sh

## We need to get the individual number
## This will be based on the number in the array
individual_number=$((${gen}*${NPOP}+${SLURM_ARRAY_TASK_ID}))

## Based on the individual number, we need the right parent directory
## This involves checking the individual number being submitted
## This is complicated--the individual number should be the number in the job array
## To do this, we'll have to call the array number (see above)
if [ $individual_number -lt 10 ]
then
	indiv_dir_parent=$XFProj/Simulations/00000$individual_number/
elif [[ $individual_number -ge 10 && $individual_number -lt 100 ]]
then
	indiv_dir_parent=$XFProj/Simulations/0000$individual_number/
elif [[ $individual_number -ge 100 && $individual_number -lt 1000 ]]
then
	indiv_dir_parent=$XFProj/Simulations/000$individual_number/
elif [ $individual_number -ge 1000 ]
then
	indiv_dir_parent=$XFProj/Simulations/00$individual_number/
fi

## Now we need to get into the Run0001 directory inside the parent directory
indiv_dir=$indiv_dir_parent/Run0001

cd $indiv_dir
xfsolver --use-xstream=true --xstream-use-number=2 --num-threads=2 -v

cd $WorkingDir/Run_Outputs/$RunName/GPUFlags

echo "The GPU job is done!" >> Part_B_GPU_Flag_${individual_number}.txt 
