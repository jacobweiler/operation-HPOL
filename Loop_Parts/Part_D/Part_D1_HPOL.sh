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


SpecificSeed=32000

cd $WorkingDir

# I'm going to make a directory to hold the AraSim output and error files for each gen

if [ ${gen} -eq 0 ]
then
	mkdir -m775 Run_Outputs/${RunName}/AraSim_Outputs
	mkdir -m775 Run_Outputs/${RunName}/AraSim_Errors
fi

cd Antenna_Performance_Metric
for i in `seq 1 $NPOP`
do
	mv evol_antenna_model_${i}.dat $AraSimExec/a_${i}.txt
done

#read -p "Press any key to continue... " -n1 -s
echo "Resuming..."
echo

cd "$AraSimExec"

job_name=ara_hpol_paralleljob.sh


# If we're doing a real run, we only need to change the setup .txt file once
# Although we need to be carefuly, since maybe eventually we'll want to run multiple times at once?
if [ $DEBUG_MODE -eq 0 ]; then

	sed -e "s/num_nnu/$NNT/" -e "s/n_exp/$exp/" -e "s/current_seed/$SpecificSeed/" ${AraSimExec}/setup_dummy_hpol.txt > $TMPDIR/setup.txt

	cd $WorkingDir
	numJobs=$((NPOP*Seeds))
	maxJobs=252 # for now, maybe make this a variable in the main loop script
	sbatch --array=1-${numJobs}%${maxJobs} --export=ALL,gen=$gen,WorkingDir=$WorkingDir,RunName=$RunName,Seeds=$Seeds,AraSimDir=$AraSimExec --job-name=${RunName} Batch_Jobs/${job_name}
	cd $AraSimExec
	rm -f outputs/*.root

# If we're testing with the seed, use DEBUG_MODE=1
# Then, we'll change the setup file for each job
# If we're using the DEBUG mode, we'll do it the original way
# This should be ok, since we'll be using few jobs in such instances
else
	for i in `seq 1 $NPOP`
	do
		for j in `seq 1 $Seeds`
		do
		# I think we want to use the below commented out version
		# but I'm commenting it out for testing purposes
		SpecificSeed=$(expr $j + 32000)
		#SpecificSeed=32000

	
		#We will want to call a job here to do what this AraSim call is doing so it can run in parallel
		cd $WorkingDir
		output_name=/fs/ess/PAS1960/BiconeEvolutionOSC/BiconeEvolution/current_antenna_evo_build/XF_Loop/Evolutionary_Loop/Run_Outputs/$RunName/AraSim_Outputs/${gen}_${i}_${j}.output
		error_name=/fs/ess/PAS1960/BiconeEvolutionOSC/BiconeEvolution/current_antenna_evo_build/XF_Loop/Evolutionary_Loop/Run_Outputs/$RunName/AraSim_Errors/${gen}_${i}_${j}.error
		sbatch --export=ALL,gen=$gen,num=$i,WorkingDir=$WorkingDir,RunName=$RunName,Seeds=$j,AraSimDir=$AraSimExec --job-name=AraSimCall_AraSeed_${gen}_${i}_${j}.run --output=$output_name --error=$error_name Batch_Jobs/AraSimCall_AraSeed.sh

		# We are going to implement a notificaiton system
		# This will require being able to know the job IDs
		# We'll print this to a file and then read read it in D2
		
		cd $AraSimExec
		rm -f outputs/*.root
		done
	done

fi

#This submits the job for the actual ARA bicone. Veff depends on Energy and we need this to run once per run to compare it to. 
if [ $gen -eq 10000 ]
then
	#sed -e "s/num_nnu/100000" /fs/ess/PAS1960/BiconeEvolutionOSC/AraSim/setup_dummy_araseed.txt > /fs/ess/PAS1960/BiconeEvolutionOSC/AraSim/setup.txt
	sbatch --export=ALL,WorkingDir=$WorkingDir,RunName=$RunName,AraSimDir=$AraSimExec Batch_Jobs/AraSimBiconeActual_Prototype.sh 

fi
#Any place we see the directory AraSimFlags we need to change that so that AraSimFlags is a directory under the runname directory
#cd $WorkingDir/AraSimFlags/

#chmod -R 777 /fs/ess/PAS1960/BiconeEvolutionOSC/BiconeEvolution/

## Let's move the uan files to a directory

cd $WorkingDir/Run_Outputs/${RunName}/uan_files
mkdir -m775 ${gen}_uan_files
for i in `seq 1 $NPOP`
do
	mkdir -m775 ${gen}_uan_files/${i}
	mv ${gen}_${i}_*.uan ${gen}_uan_files/${i}/
done
