#!/bin/bash
#This is for the VPOL + HPOL Loop in AraSim, your choice of HPOL or VPOL
#Evolutionary loop for antennas.
#Last update: June 06, 2024 by Jacob Weiler
#OSU GENETIS Team

###########################################################################################################################################
#### THIS COPY SUBMITS XF SIMS AS A JOB AND REQUESTS A GPU FOR THE JOB ####
# This loop contains 8 different parts. 
# Each part is its own function and is contained in its own bash script(Part_A to Part_F, with there being 2 part_D scripts and 2 part_B scripts). 
# When the loop is finished running through, it will restart for a set number of generations. 
# The code is optimised for a dynamic choice of NPOP UP TO fitnessFunction.exe. From there on, it has not been checked.
################################################################################################################################################

################# Load Modules #################################################################################################################
module load python/3.6-conda5.2

############### Initialize Run Variables #######################################################################################################
RunName=$1   	## Unique id of the run
setupfile="${2:-setup.sh}"
WorkingDir=$(pwd)
RunDir=$WorkingDir/Run_Outputs/$RunName

mkdir -m777 $WorkingDir/Run_Outputs 2> /dev/null
mkdir -m777 $WorkingDir/saveStates 2> /dev/null

echo "Setup file is ${setupfile}"

XmacrosDir=$WorkingDir/Xmacros 
XFProj=$WorkingDir/Run_Outputs/${RunName}/${RunName}.xf
AraSimExec="/fs/ess/PAS1960/BiconeEvolutionOSC/AraSim" 

source $WorkingDir/Environments/araenv.sh
source $WorkingDir/Environments/new_root_setup.sh
source /cvmfs/ara.opensciencegrid.org/trunk/centos7/setup.sh

######## SAVE STATE #################################################################################################################################
saveStateFile="${RunName}.savestate.txt"

echo "${saveStateFile}"
if ! [ -f "saveStates/${saveStateFile}" ]; then
    echo "saveState does not exist. Making one and starting new run"
	
	echo "0" > saveStates/${saveStateFile}
	echo "0" >> saveStates/${saveStateFile}
	echo "1" >> saveStates/${saveStateFile}
	chmod -R 777 saveStates/${saveStateFile}

	mkdir -m777 $WorkingDir/RunData/$RunName

	cp $WorkingDir/$setupfile $WorkingDir/RunData/$RunName/setup.sh
	cp $WorkingDir/RunData/$RunName/setup.sh $WorkingDir/RunData/$RunName/settings.py
	XFProj=$WorkingDir/RunData/${RunName}/${RunName}.xf
	XmacrosDir=$WorkingDir/XF
	echo "XFProj=${XFProj}" >> $WorkingDir/RunData/$RunName/setup.sh
	echo "XmacrosDir=${XmacrosDir}" >> $WorkingDir/RunData/$RunName/setup.sh
else
	source $RunDir/setup.sh
fi
##################### THE LOOP ###########################################################################################################
## Read in the saveState file ##
InitialGen=$(sed '1q;d' saveStates/${saveStateFile})
state=$(sed '2q;d' saveStates/${saveStateFile})
indiv=$(sed '3q;d' saveStates/${saveStateFile})
echo "${InitialGen}"
echo "${state}"
echo "${indiv}"

for gen in `seq $InitialGen $TotalGens`; do
	if [[ $gen -eq 0 && $state -eq 0 ]]; then # New Run
        if [ $manual_override -eq 0 ]; then
	    	read -p "Starting generation ${gen} at location ${state}. Press any key to continue... " -n1 -s
		fi
		# Make the run name directory
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName/AraSimFlags
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName/AraSimConfirmed
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName/GPUFlags
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName/XFGPUOutputs
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName/uan_files
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName/Gain_Plots
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName/Antenna_Images
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName/AraOut
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName/Generation_Data
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName/Evolution_Plots
		mkdir -m777 $WorkingDir/Run_Outputs/$RunName/Root_Files
		head -n 53 Loop_Scripts/Asym_XF_Loop.sh | tail -n 33 > $WorkingDir/Run_Outputs/$RunName/run_details.txt
		# Create the run's date and save it in the run's directory
		python Data_Generators/dateMaker.py
		mv "runDate.txt" "$WorkingDir/Run_Outputs/$RunName/" -f
		state=1
	fi

	## Part A ##
    if [ $state -eq 1 ]; then
        if [ $antenna == "VPOL" ]; then
            if [ $CURVED -eq 0 ]; then # Straight
                ./Loop_Parts/Part_A/Part_A_With_Switches.sh $gen $NPOP $NSECTIONS $WorkingDir $RunName $GeoFactor $RADIUS $LENGTH $ANGLE $SEPARATION 
            else # Curved
                ./Loop_Parts/Part_A/Part_A_Curved.sh $gen $NPOP $NSECTIONS $WorkingDir $RunName $GeoFactor $RADIUS $LENGTH $A $B $SEPARATION $NSECTIONS $REPRODUCTION $CROSSOVER $MUTATION $SIGMA $ROULETTE $TOURNAMENT $RANK $ELITE
            fi
        elif [ $antenna == "HPOL" ]; then
            ./Loop_Parts/Part_A/Part_A_HPOL.sh $gen $NPOP $NSECTIONS $WorkingDir $RunName $GeoFactor $RADIUS $LENGTH $ANGLE $SEPARATION 
        else # Where both will go
            echo "ERROR: Antenna type not recognized"
            exit 1
        fi
        state=2

        ./SaveState_Prototype.sh $gen $state $RunName $indiv
    fi

	## Part B1 ##
	if [ $state -eq 2 ]; then
        if [ $antenna == "VPOL"]; then
            if [ $CURVED -eq 0 ]; then
                if [ $NSECTIONS -eq 1 ]; then
                    if [ $database_flag -eq 0 ]; then
                        ./Loop_Parts/Part_B/Part_B_GPU_job1.sh $indiv $gen $NPOP $WorkingDir $RunName $XmacrosDir $XFProj $GeoFactor $num_keys

                    else
                        ./Loop_Parts/Part_B/Part_B_GPU_job1_database.sh $indiv $gen $NPOP $WorkingDir $RunName $XmacrosDir $XFProj $GeoFactor $num_keys

                    fi

                else
                    if [ $database_flag -eq 0 ]; then
                        ./Loop_Parts/Part_B/Part_B_job1_sep.sh $indiv $gen $NPOP $WorkingDir $RunName $XmacrosDir $XFProj $GeoFactor $num_keys 

                    else
                        ./Loop_Parts/Part_B/Part_B_GPU_job1_asym_database.sh $indiv $gen $NPOP $WorkingDir $RunName $XmacrosDir $XFProj $GeoFactor $num_keys

                    fi
                fi
            else
                ./Loop_Parts/Part_B/Part_B_Curved_1.sh $indiv $gen $NPOP $WorkingDir $RunName $XmacrosDir $XFProj $GeoFactor $num_keys
            fi
        elif [ $antenna == "HPOL" ]; then
            ./Loop_Parts/Part_B/Part_B_HPOL.sh
        else # Both 
            echo "ERROR: Antenna type not recognized"
            exit 1
        fi
		state=3

		./SaveState_Prototype.sh $gen $state $RunName $indiv
	fi
		
	## Part B2 ##
	if [ $state -eq 3 ]; then
        if [ $antenna == "VPOL" ]; then
            if [ $database_flag -eq 0 ]; then
            ./Loop_Parts/Part_B/Part_B_GPU_job2_asym_array.sh $indiv $gen $NPOP $WorkingDir $RunName $XmacrosDir $XFProj $GeoFactor $num_keys $NSECTIONS
            else
            ./Loop_Parts/Part_B/Part_B_GPU_job2_asym_database.sh $indiv $gen $NPOP $WorkingDir $RunName $XmacrosDir $XFProj $GeoFactor $num_keys $NSECTIONS
            fi
        elif [ $antenna == "HPOL" ]; then
            ./Loop_Parts/Part_B/Part_B_HPOL2.sh # do we need this??
        else
            echo "ERROR: Antenna type not recognized"
            exit 1
        fi
		state=4

		./SaveState_Prototype.sh $gen $state $RunName $indiv
	fi

	## Part C ##
	if [ $state -eq 4 ]; then
        indiv=1
        ./Loop_Parts/Part_C/Part_C.sh $NPOP $WorkingDir $RunName $gen $indiv
		state=5

		./SaveState_Prototype.sh $gen $state $RunName $indiv
	fi

	## Part D1 ##
	if [ $state -eq 5 ]; then
        if [ $antenna == "VPOL" ]; then
		    ./Loop_Parts/Part_D/Part_D1_Array.sh $gen $NPOP $WorkingDir $AraSimExec $exp $NNT $RunName $Seeds $DEBUG_MODE
        elif [ $antenna == "HPOL" ]; then
            ./Loop_Parts/Part_D/Part_D1_HPOL.sh
        else
            echo "ERROR: Antenna type not recognized"
            exit 1
        fi
		state=6

		./SaveState_Prototype.sh $gen $state $RunName $indiv
	fi

	## Part D2 ##
	if [ $state -eq 6 ]; then
        if [ $antenna == "VPOL" ]; then
            ./Loop_Parts/Part_D/Part_D2_Array.sh $gen $NPOP $WorkingDir $RunName $Seeds $AraSimExec
        elif [ $antenna == "HPOL" ]; then
            ./Loop_Parts/Part_D/Part_D2_HPOL.sh
        else
            echo "ERROR: Antenna type not recognized"
            exit 1
        fi
		state=7

		./SaveState_Prototype.sh $gen $state $RunName $indiv
	fi

	## Part E ##
	if [ $state -eq 7 ]; then
        if [ $antenna == "VPOL" ]; then
            if [ $CURVED -eq 0 ]; then # Straight Sides
                ./Loop_Parts/Part_E/Part_E_Asym.sh $gen $NPOP $WorkingDir $RunName $ScaleFactor $indiv $Seeds $GeoFactor $AraSimExec $XFProj $NSECTIONS $SEPARATION
            else # Curved Sides
                ./Loop_Parts/Part_E/Part_E_Curved.sh $gen $NPOP $WorkingDir $RunName $ScaleFactor $indiv $Seeds $GeoFactor $AraSimExec $XFProj $NSECTIONS $SEPARATION $CURVED
            fi
        elif [ $antenna == "HPOL" ]; then
            ./Loop_Parts/Part_E/Part_E_HPOL.sh
        else
            echo "ERROR: Antenna type not recognized"
            exit 1
        fi
		state=8

		./SaveState_Prototype.sh $gen $state $RunName $indiv 

	fi

	## Part F ##
	if [ $state -eq 8 ]; then
        if [ $antenna == "VPOL" ]; then
            if [ $CURVED -eq 0 ]; then
                ./Loop_Parts/Part_F/Part_F_asym.sh $NPOP $WorkingDir $RunName $gen $Seeds $NSECTIONS
            else
                ./Loop_Parts/Part_F/Part_F_Curved.sh $NPOP $WorkingDir $RunName $gen $Seeds $NSECTIONS
            fi
        elif [ $antenna == "HPOL" ]; then
            ./Loop_Parts/Part_F/Part_F.sh
        else
            echo "ERROR: Antenna type not recognized"
            exit 1
        fi
		state=1

		./SaveState_Prototype.sh $gen $state $RunName $indiv
	fi
done

cp generationDNA.csv "$WorkingDir"/Run_Outputs/$RunName/FinalGenerationParameters.csv
mv runData.csv Antenna_Performance_Metric

#########################################################################################################################
###Moving the Veff AraSim output for the actual ARA bicone into the $RunName directory so this data isn't lost in     ###
###the next time we start a run. Note that we don't move it earlier since (1) our plotting software and fitness score ###
###calculator expect it where it is created in "$WorkingDir"/Antenna_Performance_Metric, and (2) we are only creating ###
###it once on gen 0 so it's not written over in the looping process.                                                  ###
########################################################################################################################
cd "$WorkingDir"
mv AraOut_ActualBicone.txt "$WorkingDir"/Run_Outputs/$RunName/AraOut_ActualBicone.txt


