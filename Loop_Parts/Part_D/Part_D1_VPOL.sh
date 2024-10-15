#!/bin/bash
########  AraSim Execution (D)  ################################################################################################################## 

# Variables
WorkingDir=$1
RunName=$2
gen=$3
source $WorkingDir/Run_Outputs/$RunName/setup.sh

SpecificSeed=32000

cd "$AraSimExec"

# Sourcing necessary setup scripts
source /fs/ess/PAS1960/BiconeEvolutionOSC/new_root/new_root_setup.sh
source /cvmfs/ara.opensciencegrid.org/trunk/centos7/setup.sh

job_name=AraSimCall_ParallelArray.sh

if [ $DEBUG_MODE -eq 0 ]; then
	cd $WorkingDir
	output_name=$RunDir/AraSim_Outputs/AraSim_%a.output
	error_name=$RunDir/AraSim_Errors/AraSim_%a.error
	num_jobs=$((NPOP * Seeds))
	# Calculate nnt_per_ara
	nnt_per_ara=$((NNT / (Seeds * threads_per_ara_job)))

	# Output the result of the calculation
	echo "NNT per ARA: $nnt_per_ara"

	sbatch --array=1-${num_jobs}%${maxJobs} \
       --export=ALL,gen=$gen,WorkingDir=$WorkingDir,RunName=$RunName,Seeds=$Seeds,AraSimDir=$AraSimExec,nnt_per_ara=$nnt_per_ara \
       --job-name=${RunName} \
       --output=$output_name --error=$error_name \
       Batch_Jobs/${job_name}

	cd $AraSimExec
	rm -f outputs/*.root

else
	for i in `seq 1 $NPOP`; do
		for j in `seq 1 $Seeds`; do
			SpecificSeed=$(expr $j + 32000)
			cd $WorkingDir
			output_name=$RunDir/AraSim_Outputs/${gen}_${i}_${j}.output
			error_name=$RunDir/AraSim_Errors/${gen}_${i}_${j}.error
			sbatch --export=ALL,gen=$gen,num=$i,WorkingDir=$WorkingDir,RunName=$RunName,Seeds=$j,AraSimDir=$AraSimExec \
			       --job-name=AraSimCall_AraSeed_${gen}_${i}_${j}.run --output=$output_name --error=$error_name \
			       Batch_Jobs/AraSimCall_AraSeed.sh

			cd $AraSimExec
			rm -f outputs/*.root
		done
	done
fi

# Submitting ARA bicone job if gen equals 10000
if [ $gen -eq 10000 ]; then
	sbatch --export=ALL,WorkingDir=$WorkingDir,RunName=$RunName,AraSimDir=$AraSimExec Batch_Jobs/AraSimBiconeActual_Prototype.sh 
fi
