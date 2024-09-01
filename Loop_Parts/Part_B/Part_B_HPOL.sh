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

mkdir -m777 $RunDir/Antenna_Images/${gen}
mkdir -m777 $RunDir/uan_files/${gen}_uan_files 2> /dev/null

cd $WorkingDir

# Delete Simulation directories if they exist
for i in $(seq 1 $NPOP); do
	individual_number=$(($gen*$NPOP + $i))
	indiv_dir_parent=$XFProj/Simulations/$(printf "%06d" $individual_number)

	if [ -d $indiv_dir_parent ]; then
		rm -rf $indiv_dir_parent
	fi
done

# store the next simulation number in the hidden file
if [[ $gen -ne 0 ]]; then
	echo $(($gen*$NPOP + 1)) > $XFProj/Simulations/.nextSimulationNumber
fi

chmod -R 777 $XmacrosDir 2> /dev/null

#get rid of the simulation_PEC.xmacro that already exists
rm -f $RunXacrosDir/simulation_PEC.xmacro
touch $RunXmacrosDir/simulation_PEC.xmacro

# Create the simulation_PEC.xmacro
echo "var NPOP = $NPOP;" > $RunXmacrosDir/simulation_PEC.xmacro
echo "var indiv = $indiv;" >> $RunXmacrosDir/simulation_PEC.xmacro
echo "var gen = $gen;" >> $RunXmacrosDir/simulation_PEC.xmacro
echo "var workingdir = \"$WorkingDir\";" >> $RunXmacrosDir/simulation_PEC.xmacro
echo "var RunName = \"$RunName\";" >> $RunXmacrosDir/simulation_PEC.xmacro
echo "var freq_start = $FreqStart;" >> $RunXmacrosDir/simulation_PEC.xmacro
echo "var freq_step = $FreqStep;" >> $RunXmacrosDir/simulation_PEC.xmacro
echo "var freqCoefficients = $FREQS;" >> $RunXmacrosDir/simulation_PEC.xmacro

if [ $gen -eq 0 ]; then
	echo "App.saveCurrentProjectAs(\"$WorkingDir/Run_Outputs/$RunName/$RunName\");" >> $RunXmacrosDir/simulation_PEC.xmacro
fi

cat $XmacrosDir/headerHPOL.js >> $RunXmacrosDir/simulation_PEC.xmacro
cat $XmacrosDir/functioncallsHPOL.js >> $RunXmacrosDir/simulation_PEC.xmacro
cat $XmacrosDir/build_hpol.js >> $RunXmacrosDir/simulation_PEC.xmacro
cat $XmacrosDir/CreateFerrite.js >> $RunXmacrosDir/simulation_PEC.xmacro
cat $XmacrosDir/CreatePEC.js >> $RunXmacrosDir/simulation_PEC.xmacro
cat $XmacrosDir/CreateAntennaSource.js >> $RunXmacrosDir/simulation_PEC.xmacro
cat $XmacrosDir/CreateGrid.js >> $RunXmacrosDir/simulation_PEC.xmacro
cat $XmacrosDir/CreateSensors.js >> $RunXmacrosDir/simulation_PEC.xmacro
cat $XmacrosDir/CreateAntennaSimulationData.js >> $RunXmacrosDir/simulation_PEC.xmacro
cat $XmacrosDir/QueueSimulation.js >> $RunXmacrosDir/simulation_PEC.xmacro
cat $XmacrosDir/MakeImage.js >> $RunXmacrosDir/simulation_PEC.xmacro

# Run XF simulation PEC
xfdtd $XFProj --execute-macro-script=$RunXmacrosDir/simulation_PEC.xmacro || true

chmod -R 775 $XmacrosDir 2> /dev/null

# Submit the Batch XF Job to solve the simulations
if [ $NPOP -lt $num_keys ]
then
	batch_size=$NPOP
else
	batch_size=$num_keys
fi

# make sure there are no stray jobs from previous runs
scancel -n ${RunName}

# Numbers through testing
if [ $SingleBatch -eq 1 ]; then
	XFCOUNT=$batch_size
	job_time="15:00:00"
else
	XFCOUNT=$NPOP
	job_time="04:00:00"
fi

echo "Submitting XF jobs with batch size $batch_size"
sbatch  --array=1-${XFCOUNT}%${batch_size} \
        --export=ALL,WorkingDir=$WorkingDir,RunName=$RunName,indiv=$individual_number,gen=${gen},batch_size=$batch_size \
        --job-name=${RunName} --time=${job_time} $WorkingDir/Batch_Jobs/GPU_XF_Job.sh 