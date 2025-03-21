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
module load python/3.7-2019.10
module load xfdtd/7.10.2.3

#source $WorkingDir/Environments/araenv.sh
#source $WorkingDir/Environments/new_root_setup.sh
#source /cvmfs/ara.opensciencegrid.org/trunk/centos7/setup.sh

############### Initialize Run Variables #######################################################################################################
RunName=$1   	## Unique id of the run

setupfile="${2:-setup.sh}"
manual_override="${3:-0}"
WorkingDir=$(pwd)
RunDir=$WorkingDir/Run_Outputs/$RunName

mkdir -m777 $WorkingDir/Run_Outputs 2> /dev/null
mkdir -m777 $WorkingDir/saveStates 2> /dev/null

echo "Setup file is ${setupfile}"

######## SAVE STATE + SETUP #################################################################################################################################
saveStateFile="${RunName}.savestate.txt"

echo "${saveStateFile}"
if ! [ -f "saveStates/${saveStateFile}" ]; then
    echo "saveState does not exist. Making one and starting new run"
	
	echo "0" > saveStates/${saveStateFile}
	echo "0" >> saveStates/${saveStateFile}
	echo "1" >> saveStates/${saveStateFile}
	chmod -R 777 saveStates/${saveStateFile}

	mkdir -m777 $RunDir

	cp $WorkingDir/$setupfile $RunDir/setup.sh

	XFProj=$RunDir/${RunName}.xf
	XmacrosDir=$WorkingDir/Xmacros
	RunXmacrosDir=$RunDir/Xmacros 
    AraSimExec="/users/PAS1977/jacobweiler/GENETIS/UpdateAraSim" 

	echo "" >> $RunDir/setup.sh
	echo "XFProj=${XFProj}" >> $RunDir/setup.sh
	echo "XmacrosDir=${XmacrosDir}" >> $RunDir/setup.sh
    echo "AraSimExec=${AraSimExec}" >> $RunDir/setup.sh
	echo "RunXmacrosDir=${RunXmacrosDir}" >> $RunDir/setup.sh
	echo "RunDir=${RunDir}" >> $RunDir/setup.sh
fi

source $RunDir/setup.sh

##################### THE LOOP ###########################################################################################################
## Read in the saveState file ##
InitialGen=$(sed '1q;d' saveStates/${saveStateFile})
state=$(sed '2q;d' saveStates/${saveStateFile})
indiv=$(sed '3q;d' saveStates/${saveStateFile})
echo "${InitialGen}"
echo "${state}"
echo "${indiv}"
echo ""

for gen in `seq $InitialGen $TotalGens`; do
	if [[ $gen -eq 0 && $state -eq 0 ]]; then
        if [ $manual_override -eq 0 ]; then
            read -p "Starting generation ${gen} at location ${state}. Press any key to continue... " -n1 -s
			echo ""
		fi
		# Make the run name directories
		mkdir -m777 $RunDir/AraSimFlags
		mkdir -m777 $RunDir/AraSimConfirmed
		mkdir -m777 $RunDir/GPUFlags
		mkdir -m777 $RunDir/XF_Outputs
		mkdir -m777 $RunDir/XF_Errors
		mkdir -m777 $RunDir/uan_files
		mkdir -m777 $RunDir/Plots
		mkdir -m777 $RunDir/Antenna_Images
		mkdir -m777 $RunDir/AraSim_Outputs
		mkdir -m777 $RunDir/AraSim_Errors
		mkdir -m777 $RunDir/Generation_Data
		mkdir -m777 $RunDir/Root_Files
		mkdir -m777 $RunDir/txt_files
		mkdir -m777 $RunDir/Xmacros
		# Create the run's date and save it in the run's directory
		python Data_Generators/dateMaker.py
		mv "runDate.txt" "$RunDir/" -f
		state=1
	fi

	## Part A ##
    if [ $state -eq 1 ]; then
        ./Loop_Parts/Part_A/Part_A.sh $WorkingDir $RunName $gen

        state=2

        ./Loop_Scripts/SaveState_Prototype.sh $gen $state $RunName $indiv
    fi

	## Part B1 ##
	if [ $state -eq 2 ]; then
        if [ $antenna == "VPOL" ]; then
            ./Loop_Parts/Part_B/Part_B_VPOL.sh $WorkingDir $RunName $gen $indiv
        elif [ $antenna == "HPOL" ]; then
            ./Loop_Parts/Part_B/Part_B_HPOL.sh $WorkingDir $RunName $gen $indiv
        else
            echo "ERROR: Antenna type not recognized"
            exit 1
        fi
		state=3

		./Loop_Scripts/SaveState_Prototype.sh $gen $state $RunName $indiv
	fi
		
	## Part B2 ##
	if [ $state -eq 3 ]; then
        ./Loop_Parts/Part_B/Part_B2.sh $WorkingDir $RunName $gen

		state=4

		./Loop_Scripts/SaveState_Prototype.sh $gen $state $RunName $indiv
	fi

	## Part C ##
	if [ $state -eq 4 ]; then
        indiv=1
		if [ $antenna == "VPOL" ]; then
			./Loop_Parts/Part_C/Part_C_VPOL.sh $WorkingDir $RunName $gen $indiv
		elif [ $antenna == "HPOL" ]; then
			./Loop_Parts/Part_C/Part_C_HPOL.sh $WorkingDir $RunName $gen $indiv
		else
			echo "ERROR: Antenna type not recognized"
			exit 1
		fi
		state=5

		./Loop_Scripts/SaveState_Prototype.sh $gen $state $RunName $indiv
	fi

	## Part D1 ##
	if [ $state -eq 5 ]; then
        if [ $antenna == "VPOL" ]; then
            ./Loop_Parts/Part_D/Part_D1_VPOL.sh $WorkingDir $RunName $gen
        elif [ $antenna == "HPOL" ]; then
            ./Loop_Parts/Part_D/Part_D1_HPOL.sh $WorkingDir $RunName $gen
        else
            echo "ERROR: Antenna type not recognized"
            exit 1
        fi
		state=6

		./Loop_Scripts/SaveState_Prototype.sh $gen $state $RunName $indiv
	fi

	## Part D2 ##
	if [ $state -eq 6 ]; then
        if [ $antenna == "VPOL" ]; then
            ./Loop_Parts/Part_D/Part_D2_VPOL.sh $WorkingDir $RunName $gen
        elif [ $antenna == "HPOL" ]; then
            ./Loop_Parts/Part_D/Part_D2_HPOL.sh $WorkingDir $RunName $gen
        else
            echo "ERROR: Antenna type not recognized"
            exit 1
        fi
		state=7

		./Loop_Scripts/SaveState_Prototype.sh $gen $state $RunName $indiv
	fi

	## Part E ##
	if [ $state -eq 7 ]; then
		./Loop_Parts/Part_E/Part_E.sh $WorkingDir $RunName $gen
		
		state=8

		./Loop_Scripts/SaveState_Prototype.sh $gen $state $RunName $indiv 

	fi

	## Part F ##
	if [ $state -eq 8 ]; then
        ./Loop_Parts/Part_F/Part_F.sh $WorkingDir $RunName $gen

		state=1

		./Loop_Scripts/SaveState_Prototype.sh $gen $state $RunName $indiv
	fi
done

cp generationDNA.csv "$WorkingDir"/Run_Outputs/$RunName/FinalGenerationParameters.csv
#mv runData.csv Antenna_Performance_Metric

#########################################################################################################################
###Moving the Veff AraSim output for the actual ARA bicone into the $RunName directory so this data isn't lost in     ###
###the next time we start a run. Note that we don't move it earlier since (1) our plotting software and fitness score ###
###calculator expect it where it is created in "$WorkingDir"/Antenna_Performance_Metric, and (2) we are only creating ###
###it once on gen 0 so it's not written over in the looping process.                                                  ###
########################################################################################################################
cd "$WorkingDir"
mv AraOut_ActualBicone.txt "$WorkingDir"/Run_Outputs/$RunName/AraOut_ActualBicone.txt
