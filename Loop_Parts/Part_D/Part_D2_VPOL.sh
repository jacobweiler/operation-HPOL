#!/bin/bash
#This is a version of Part_D2 that uses multiple Seeds for an individual run of AraSim

#variables
WorkingDir=$1
RunName=$2
gen=$3
source $WorkingDir/Run_Outputs/$RunName/setup.sh

cd $RunDir/AraSimFlags/

nFiles=0
totPop=$( expr $NPOP \* $Seeds )

while [ "$nFiles" != "$totPop" ]; do
	echo "Waiting for AraSim jobs to finish..."
	sleep 20
	
	nFiles=$(ls -1 --file-type ../AraSimConfirmed | grep -v '/$' | wc -l) 
	
	for file in *; do
		if [ "$file" != "*" ] && [ "$file" != "" ]; then
			current_generation=$(head -n 1 $file) # what gen (should be this one)
			current_individual=$(head -n 2 $file | tail -n 1) # which individual?
			current_seed=$(head -n 3 $file | tail -n 1) # which seed of the individual

			current_file="AraSim_$(($((${current_individual}-1))*${Seeds}+${current_seed}))"	

			if 	grep "segmentation violation" ../AraSim_Errors/${current_file}.error || grep "DATA_LIKE_OUTPUT" ../AraSim_Errors/${current_file}.error || 
				grep "CANCELLED" ../AraSim_Errors/${current_file}.error || grep "please rerun" ../AraSim_Errors/${current_file}.error; then
				# Remove output so we don't get stuck in infinite loop
				rm -f ../AraSim_Errors/${current_file}.error
				rm -f ../AraSim_Outputs/${current_file}.output

				echo "segmentation violation/DATA_LIKE_OUTPUT/CANCELLED error!" 
				
				# Resubmit job
				cd $WorkingDir
				output_name=$RunDir/AraSim_Outputs/${current_file}.output
				error_name=$RunDir/AraSim_Errors/${current_file}.error
				sbatch --export=ALL,gen=$gen,num=${current_individual},WorkingDir=$WorkingDir,RunName=$RunName,Seeds=${current_seed},AraSimDir=$AraSimExec --job-name=AraSimCall_AraSeed_$gen_${current_individual}_${current_seed}.run --output=$output_name --error=$error_name Batch_Jobs/ara_hpol_paralleljob.sh

				cd Run_Outputs/$RunName/AraSimFlags/

				# since we need to rerun, we need to remove the flag
				rm -f ${current_individual}_${current_seed}.txt
			else
				if [ "$current_individual" != "" ] && [ "$current_seed" != "" ]; then
					echo "This individual succeeded" > ../AraSimConfirmed/${current_individual}_${current_seed}_confirmation.txt
				fi
			fi
		fi
	done
done

rm -f $WorkingDir/Run_Outputs/$RunName/AraSimFlags/*
rm -f $WorkingDir/Run_Outputs/$RunName/AraSimConfirmed/*

wait

cd "$WorkingDir"/Antenna_Performance_Metric


if [ $gen -eq 10000 ]; then
	cp $WorkingDir/Antenna_Performance_Metric/AraOut_ActualBicone.txt $WorkingDir/Run_Outputs/$RunName/AraOut_ActualBicone.txt
fi
