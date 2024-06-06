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

#variables
WorkingDir=$1
RunName=$2
gen=$3
source $WorkingDir/RunData/$RunName/setup.sh

echo "XFProj: $XFProj"
echo "WorkingDir: $WorkingDir"
echo "XMacrosDir: $XmacrosDir"


cd $WorkingDir
# Get the number of jobs running and number of jobs finished
# truncate the RunName to 8 characters
tempName=${RunName:0:8}
count_running=$(squeue -u $(whoami) | grep $tempName | wc -l)
count_finished=$(ls $WorkingDir/RunData/$RunName/GPU_Flags | wc -l) 2> /dev/null

function printProgressBar () {
	#This function will create a progress bar based
	#on an inputted name and target file count

	cd $WorkingDir/RunData/$RunName/${1}_Flags
	flags=$(find . -type f | wc -l)
	percent=$(bc <<< "scale=2; $flags/$2")
	percent=$(bc <<< "scale=2; $percent*100")

	num_bars=$(bc <<< "scale=0; $percent/4")
	num_spaces=$(bc <<< "scale=0; 25-$num_bars")
	GREEN='\033[0;32m'
	NC='\033[0m'

	echo -ne "$1"
	if [ ${#1} -lt 10 ]
	then
		for ((i=0; i<10-${#1}; i++))
		do
			echo -ne " "
		done
	fi
	echo -ne "[${GREEN}"
	for ((i=0; i<$num_bars; i++))
	do
		echo -ne "#"
	done
	echo -ne "${NC}"
	for ((i=0; i<$num_spaces; i++))
	do
		echo -ne "#"
	done
	echo -ne "] - flags: $flags, $percent %"
	echo -ne "\n"
}

#Call the XF GPU jobs

if [ $SingleBatch -eq 1 ]
then
    XFCount=$XFkeys
else
    XFCount=$NPOP
fi

# If there are still jobs running, but not all the flags are there, then we need to wait for the jobs to finish
# Else, we can start the next batch of jobs
if [ $count_running -eq 0 ] && [ $count_finished -lt $NPOP ]
then
    echo ""
    echo "Preparing XF GPU jobs"
    echo ""
    starttime=$(date +%s)
    cd $XmacrosDir
    if [ $SingleBatch -eq 1 ]
    then
        mv $WorkingDir/RunData/$RunName/PendingFlags/* $WorkingDir/RunData/$RunName/TMPFlags 2> /dev/null
    else
        mv $WorkingDir/RunData/$RunName/GPU_Flags/* $WorkingDir/RunData/$RunName/TMPFlags 2> /dev/null
    fi
    mkdir -m775 $WorkingDir/RunData/$RunName/uan_files/${gen}_uan_files 2> /dev/null
    mkdir -m775 $WorkingDir/RunData/$RunName/detector_images/$gen

    python freqmaker.py $FreqStart $FreqStop $FreqStep $WorkingDir/RunData/$RunName/XMacros
    python DictToJson.py $NPOP $WorkingDir $RunName $gen

    # Run the simulation xmacro
    rm -f $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro
    touch $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro
    if [ $gen -ne 0 ]
    then
        echo $(($gen*$NPOP + 1)) > $XFProj/Simulations/.nextSimulationNumber
    fi

    echo "var popsize = $NPOP;" > $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro
    echo "var gen = \"$gen\";" >> $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro
    echo "var WorkingDir = \"$WorkingDir\";" >> $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro
    echo "var RunDir = \"$WorkingDir/RunData/$RunName\";" >> $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro
    echo "var gaoutpath = RunDir + \"/GA_Outputs/\" + gen + \"_GAOutput.json\";" >> $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro
    echo "var units = \" $XFunits\";" >> $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro ## might need to add space in beginning XF statement if error
    echo "var isHollow = $isHollow;" >> $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro
    echo "var HollowThickness = $HollowThickness;" >> $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro
    echo "var endcapremoval = $endcapremoval;" >> $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro

    # if gen equals 0
    if [ $gen -eq 0 ]
    then
        echo "App.saveCurrentProjectAs(\"$WorkingDir/RunData/$RunName/$RunName\");" >> $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro
    fi

    cat $XmacrosDir/skeleton.js >> $WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro

    xfdtd $XFProj --execute-macro-script=$WorkingDir/RunData/$RunName/XMacros/simulation_PEC.xmacro || true

    endtime=$(date +%s)
    echo "Generation $gen XF Geometries Time: $(($endtime - $starttime))" >> $WorkingDir/RunData/$RunName/TimeData.txt
    # Submit the XF GPU jobs
    cd $WorkingDir
    echo "Submitting XF GPU jobs"
    echo "XFCount: $XFCount"
    echo "XFkeys: $XFkeys"
    echo "Generation: $gen"
    sbatch --array=1-${XFCount}%${XFkeys} --mem-per-gpu=178gb --export=ALL,WorkingDir=$WorkingDir,RunName=$RunName,XmacrosDir=$XmacrosDir,XFProj=$XFProj,NPOP=$NPOP,gen=${gen},SingleBatch=$SingleBatch,batch_size=$XFkeys --job-name=${RunName} $XmacrosDir/GPU_XF_Job.sh
    #separate the jobid by the _
    starttime=$(date +%s)
    echo $(squeue -u $(whoami) | grep $tempName | awk '{print $1}' | cut -d_ -f1) > $WorkingDir/RunData/$RunName/JobID.txt
fi

echo ""
echo ""
# Wait for all the jobs to finish (wait for there to be NPOP files in the GPU_Flags dir)\
flag_count=$(ls $WorkingDir/RunData/$RunName/GPU_Flags | wc -l)
while [ $flag_count -lt $NPOP ]
do
    cd $WorkingDir/XF
    sleep 10
    tput cuu 1
    flag_count=$(ls $WorkingDir/RunData/$RunName/GPU_Flags | wc -l)
    count_running=$(squeue -u $(whoami) | grep $tempName | wc -l)
    printProgressBar "GPU" $NPOP
    if [ $count_running -eq 0 ]
    then
        # resubmit the jobs (should only resubmit single batch jobs)
        echo "Resubmitting XF GPU jobs"
        mv $WorkingDir/RunData/$RunName/PendingFlags/* $WorkingDir/RunData/$RunName/TMPFlags 2> /dev/null
        sbatch --array=1-${XFCount}%${XFkeys} --mem-per-gpu=178gb --export=ALL,WorkingDir=$WorkingDir,RunName=$RunName,XmacrosDir=$XmacrosDir,XFProj=$XFProj,NPOP=$NPOP,gen=${gen},SingleBatch=$SingleBatch,batch_size=$XFkeys --job-name=${RunName} $XmacrosDir/GPU_XF_Job.sh
        echo $(squeue -u $(whoami) | grep $tempName | awk '{print $1}' | cut -d_ -f1) > $WorkingDir/RunData/$RunName/JobID.txt
    fi
done

cd $WorkingDir/XF

echo "XF GPU jobs finished"
endtime=$(date +%s)
#echo "Generation $gen XF GPU Job Time: $(($endtime - $starttime))" >> $WorkingDir/RunData/$RunName/TimeData.txt

# find jobid
jobid=$(cat $WorkingDir/RunData/$RunName/JobID.txt)
scancel $jobid

rm -f $WorkingDir/RunData/$RunName/XMacros/output.xmacro

echo "Creating output.xmacro"

echo "var popsize = $NPOP;" > $WorkingDir/RunData/$RunName/XMacros/output.xmacro
echo "var gen = \"$gen\";" >> $WorkingDir/RunData/$RunName/XMacros/output.xmacro
echo "var WorkingDir = \"$WorkingDir\";" >> $WorkingDir/RunData/$RunName/XMacros/output.xmacro
echo "var RunDir = \"$WorkingDir/RunData/$RunName\";" >> $WorkingDir/RunData/$RunName/XMacros/output.xmacro

cat $XmacrosDir/output_skeleton.js >> $WorkingDir/RunData/$RunName/XMacros/output.xmacro

xfdtd $XFProj --execute-macro-script=$WorkingDir/RunData/$RunName/XMacros/output.xmacro || true --splash=false

# Deleting simulation files for each generation (Saves a TON of space and we don't need these files necessarily since we can recreate them even if it's annoying) 
# Comment these two lines out if you want to keep the simulation files for each generation (it takes up a lot of space, just be wary)
cd $WorkingDir/RunData/$RunName/$RunName.xf/Simulations
rm -r *
