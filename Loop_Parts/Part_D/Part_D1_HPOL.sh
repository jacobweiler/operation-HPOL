#!/bin/bash
########  AraSim Execution (D)  ################################################################################################################## 
#
#
#       1. Moves each .dat file individually into a folder that AraSim can access while changing to a .txt file that AraSim can use. (can we just have the .py program make this output a .txt?)
#
#       2. For each individual ::
#           I. Run Arasim for that text file
#           III. Moves the AraSim output into the Antenna_Performance_Metric folder
#
#
################################################################################################################################################## 

#variables
WorkingDir=$1
RunName=$2
gen=$3
source $WorkingDir/Run_Outputs/$RunName/setup.sh
source /fs/ess/PAS1960/BiconeEvolutionOSC/new_root/new_root_setup.sh
source /cvmfs/ara.opensciencegrid.org/trunk/centos7/setup.sh

cd $WorkingDir

job_name=ara_hpol_paralleljob.sh
SpecificSeed=32000
output_name=$RunDir/AraSim_Outputs/AraSim_%a.output
error_name=$RunDir/AraSim_Errors/AraSim_%a.error
num_jobs=$((NPOP*Seeds))
nnt_per_ara=$((NNT / (Seeds * threads_per_ara_job)))

mkdir -m777 $RunDir/AraSim_Outputs/${gen}_AraSim_Outputs

sbatch 	--array=1-${num_jobs}%${maxJobs} --export=ALL,gen=$gen,WorkingDir=$WorkingDir,RunName=$RunName,Seeds=$Seeds,AraSimDir=$AraSimExec,nnt_per_ara=$nnt_per_ara \
		--job-name=${RunName} --output=$output_name --error=$error_name \
		Batch_Jobs/${job_name}
		
cd $AraSimExec
rm -f outputs/*.root

#This submits the job for the actual ARA bicone. Veff depends on Energy and we need this to run once per run to compare it to. 
if [ $gen -eq 10000 ]; then
	sbatch --export=ALL,WorkingDir=$WorkingDir,RunName=$RunName,AraSimDir=$AraSimExec Batch_Jobs/AraSimBiconeActual_Prototype.sh 
fi
