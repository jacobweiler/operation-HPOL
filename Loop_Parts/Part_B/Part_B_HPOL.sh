########  XF (B)  ######################################################################################################### 
#
#
#      1. Takes the .py dictionaries with the genes for each individual and creates meshes for each one in XF
#
#      2. Create the models for each antenna in XF
#
#      3. Run the simulations for each antenna in XF
#
#################################################################################################################################################### 
# variables
WorkingDir=$1
RunName=$2
gen=$3
indiv=$4
source $WorkingDir/Run_Outputs/$RunName/setup.sh

mkdir -m777 $RunDir/Plots/${gen}

# Delete Simulation directories if they exist
for i in $(seq 1 $XFCOUNT); do
	individual_number=$(($gen*$XFCOUNT + $i))
	indiv_dir_parent=$XFProj/Simulations/$(printf "%06d" $individual_number)

	if [ -d $indiv_dir_parent ]; then
		rm -rf $indiv_dir_parent
	fi
done

# store the next simulation number in the hidden file
if [[ $gen -ne 0 ]]; then
	echo $(($gen*$XFCOUNT + 1)) > $XFProj/Simulations/.nextSimulationNumber
fi

chmod -R 777 $XmacrosDir 2> /dev/null

cd $XmacrosDir

#get rid of the simulation_PEC.xmacro that already exists
rm -f $RunXMacrosDir/simulation_PEC.xmacro


# Create the simulation_PEC.xmacro
echo "var NPOP = $NPOP;" > $RunXMacrosDir/simulation_PEC.xmacro
echo "var indiv = $indiv;" >> $RunXMacrosDir/simulation_PEC.xmacro
echo "var gen = $gen;" >> $RunXMacrosDir/simulation_PEC.xmacro
echo "var workingdir = \"$WorkingDir\";" >> $RunXMacrosDir/simulation_PEC.xmacro
echo "var RunName = \"$RunName\";" >> $RunXMacrosDir/simulation_PEC.xmacro
echo "var freq_start = $FreqStart;" >> $RunXMacrosDir/simulation_PEC.xmacro
echo "var freq_step = $FreqStep;" >> $RunXMacrosDir/simulation_PEC.xmacro
echo "var freqCoefficients = $FREQS;" >> $RunXMacrosDir/simulation_PEC.xmacro

cat headerHPOL.js >> $RunXMacrosDir/simulation_PEC.xmacro
cat functioncallsHPOL.js >> $RunXMacrosDir/simulation_PEC.xmacro
cat build_hpol.js >> $RunXMacrosDir/simulation_PEC.xmacro
cat CreatePEC.js >> $RunXMacrosDir/simulation_PEC.xmacro
cat CreateAntennaSource.js >> $RunXMacrosDir/simulation_PEC.xmacro
cat CreateGrid.js >> $RunXMacrosDir/simulation_PEC.xmacro
cat CreateSensors.js >> $RunXMacrosDir/simulation_PEC.xmacro
cat CreateAntennaSimulationData.js >> $RunXMacrosDir/simulation_PEC.xmacro
cat QueueSimulation.js >> $RunXMacrosDir/simulation_PEC.xmacro
cat MakeImage.js >> $RunXMacrosDir/simulation_PEC.xmacro

# Remove the extra simulations
if [[ $gen -ne 0 && $i -eq 1 ]]
then
	cd $XFProj
	rm -rf Simulations
fi

# Run XF simulation PEC
echo
echo
echo 'Opening XF user interface...'
echo '*** Please remember to save the project with the same name as RunName! ***'
echo
echo '1. Import and run simulation_PEC.xmacro'
echo '2. Import and run output.xmacro'
echo '3. Close XF'

module load xfdtd/7.10.2.3

xfdtd $XFProj --execute-macro-script=$RunXMacrosDir/simulation_PEC.xmacro || true

chmod -R 775 $WorkingDir/../Xmacros 2> /dev/null

# Submit the Batch XF Job to solve the simulations
cd $WorkingDir

if [ $NPOP -lt $num_keys ]
then
	batch_size=$NPOP
else
	batch_size=$num_keys
fi

# make sure there are no stray jobs from previous runs
scancel -n ${RunName}

job_file=$WorkingDir/Batch_Jobs/GPU_XF_Job.sh

# Numbers through testing
if [ $SingleBatch -eq 1 ]
then
	XFCOUNT=$batch_size
	job_time="15:00:00"
else
	job_time="04:00:00"
fi

echo "Submitting XF jobs with batch size $batch_size"
sbatch --array=1-${XFCOUNT}%${batch_size} \
	   --export=ALL,WorkingDir=$WorkingDir,RunName=$RunName,indiv=$individual_number,gen=${gen},batch_size=$batch_size \
	   --job-name=${RunName} --time=${job_time} $job_file 