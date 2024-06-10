#!/bin/bash
########    XF Simulation Software (B)     ########################################################################################## 
#
#
#     1. Prepares output.xmacro with generic parameters such as :: 
#             I. Antenna type
#             II. Population number
#             III. Grid size
#
#
#     2. Prepares simulation_PEC.xmacro with information such as:
#             I. Each generation antenna parameters
#
#
#     3. Runs XF and loads XF with both xmacros. 
#
#
###################################################################################################################################### 
# variables
WorkingDir=$1
RunName=$2
gen=$3
source $WorkingDir/Run_Outputs/$RunName/setup.sh

# Making directories for the XF output and errors
if [ ${gen} -eq 0 ]; then
	mkdir -m775 $WorkingDir/Run_Outputs/$RunName/XF_Outputs
	mkdir -m775 $WorkingDir/Run_Outputs/$RunName/XF_Errors
fi

for i in `seq 1 $NPOP`; do
	# first, declare the number of the individual we are checking
	individual_number=$(($gen*$NPOP + $i))
	# next, write the potential directories corresponding to that individual
	if [ $individual_number -lt 10 ]; then
		indiv_dir_parent=$XFProj/Simulations/00000$individual_number/
	elif [[ $individual_number -ge 10 && $individual_number -lt 100 ]]; then
		indiv_dir_parent=$XFProj/Simulations/0000$individual_number/
	elif [[ $individual_number -ge 100 && $individual_number -lt 1000 ]]; then
		indiv_dir_parent=$XFProj/Simulations/000$individual_number/
	elif [ $individual_number -ge 1000 ]; then
		indiv_dir_parent=$XFProj/Simulations/00$individual_number/
	fi

	# now delete the directory if it exists
	if [ -d $indiv_dir_parent ]; then
		rm -rf $indiv_dir_parent
	fi
done

if [[ $gen -ne 0 ]]; then
	echo $(($gen*$NPOP + 1)) > $XFProj/Simulations/.nextSimulationNumber 
fi

chmod -R 777 $XmacrosDir 

if [ $database_flag -eq 1 ]; then 
    Database=$WorkingDir/Database/database.txt
    NewDataFile=$WorkingDir/Database/newData.txt
    RepeatDataFile=$WorkingDir/Database/repeatData.txt
    GenDNA=$WorkingDir/Run_Outputs/$RunName/${gen}_generationDNA.csv
fi

cd $XmacrosDir
freqlist="8333 10000 11667 13333 15000 16667 18334 20000 21667 23334 25000 26667 28334 30000 31667 33334 35000 36667 38334 40001 41667 43334 45001 46667 48334 50001 51668 53334 55001 56668 58334 60001 61668 63334 65001 66668 68335 70001 71668 73335 75001 76668 78335 80001 81668 83335 85002 86668 88335 90002 91668 93335 95002 96668 98335 100000 101670 103340 105000 106670"

# Getting rid of the old simulation_PEC.xmacro
rm -f simulation_PEC.xmacro

echo "var NPOP = $NPOP;" > simulation_PEC.xmacro
echo "var indiv = $indiv;" >> simulation_PEC.xmacro
echo "//Factor of $GeoFactor frequency" >> simulation_PEC.xmacro
echo "var freq " | tr "\n" "=" >> simulation_PEC.xmacro

# Reading in Frequency list
for i in $freqlist; do
	if [ $i -eq 8333 ]; then
		echo " " | tr "\n" "[" >> simulation_PEC.xmacro	
    fi

	k=$(($GeoFactor*$i))

	if [ $i -ne 106670 ]; then
		echo "scale=2 ; $k/100 " | bc | tr "\n" "," >> simulation_PEC.xmacro 
		echo "" | tr "\n" " " >> simulation_PEC.xmacro 
	else 
		echo "scale=2 ; $k/100 " | bc | tr "\n" "]" >> simulation_PEC.xmacro 
		echo " " >> simulation_PEC.xmacro
	fi
done

if [[ $gen -eq 0 && $indiv -eq 1 ]]; then
    echo "if(indiv==1){" >> simulation_PEC.xmacro	
    echo "App.saveCurrentProjectAs(\"$WorkingDir/Run_Outputs/$RunName/$RunName\");" >> simulation_PEC.xmacro
    echo "}" >> simulation_PEC.xmacro
fi

if [ $CURVED -eq 0]; then
    if [ $NSECTIONS -eq 1 ]; then
        cat simulationPECmacroskeleton_GPU.txt >> simulation_PEC.xmacro 
        cat simulationPECmacroskeleton2_GPU.txt >> simulation_PEC.xmacro
    else
        cat simulationPECmacroskeleton_Sep.txt >> simulation_PEC.xmacro
        cat simulationPECmacroskeleton2_Sep.txt >> simulation_PEC.xmacro
    fi
else
    cat simulationPECmacroskeleton_curved.txt >> simulation_PEC.xmacro
    cat simulationPECmacroskeleton2_curved.txt >> simulation_PEC.xmacro
fi
#initial_gridsize=0.1
#new_gridsize=$(bc <<< "scale=6; $initial_gridsize/$GeoFactor")
# I'm going to test smaller grid sizes
#gen_grid_factor=$((($gen*5+1)))
#new_gridsize=$(bc <<< "scale=6; $initial_gridsize/$gen_grid_factor")
#sed -i "s/var gridSize = 0.1;/var gridSize = $new_gridsize;/" simulation_PEC.xmacro
#echo "New grid size is ${new_gridsize}"

sed -i "s+fileDirectory+${WorkingDir}/Generation_Data+" simulation_PEC.xmacro

if [[ $gen -ne 0 && $i -eq 1 ]]
then
	cd $XFProj
	rm -rf Simulations
fi

module load xfdtd/7.9.2.2 

xfdtd $XFProj --execute-macro-script=$XmacrosDir/simulation_PEC.xmacro || true  

cd $WorkingDir 

if [ $database_flag -eq 1]; then
    # we're going to implement the database
    # this means we want to be able to read a specific list of individuals to run
    # this data will be stored in a file created by the dataAdd.exe
    cd $WorkingDir/Database
    if [ $NSECTIONS -eq 1]; then 
        ./dataCheck.exe $NPOP $GenDNA $Database $NewDataFile $RepeatDataFile 3
    else
        ./dataCheck.exe $NPOP $GenDNA $Database $NewDataFile $RepeatDataFile
    fi 
    echo $NPOP
    echo $GenDNA
    echo $Database
    echo $NewDataFile
    echo $RepeatDataFile

    FILE=$RepeatDataFile


    while read f1 f2; do
        cd $WorkingDir/Database/$f2
        for i in `seq 1 60`; do
            cp $i.uan $WorkingDir/Run_Outputs/$RunName/${gen}_${f1}_${i}.uan
        done
    done < $FILE

    FILE=$NewDataFile # the file telling us which ones to run
    passArray=()

    while read f1; do
        passArray+=($f1)
    done < $FILE

    length=${#passArray[@]}

    if [ $length -lt $num_keys ]; then
        batch_size=$length
    else
        batch_size=$num_keys
    fi
else
    if [ $NPOP -lt $num_keys ]; then
        batch_size=$NPOP
    else
        batch_size=$num_keys
    fi
fi

## We'll make the run name the job name
## This way, we can use it in the SBATCH commands
sbatch --array=1-${NPOP}%${batch_size} --export=ALL,WorkingDir=$WorkingDir,RunName=$RunName,XmacrosDir=$XmacrosDir,XFProj=$XFProj,NPOP=$NPOP,indiv=$individual_number,indiv_dir=$indiv_dir,gen=${gen} --job-name=${RunName} Batch_Jobs/GPU_XF_Job.sh
