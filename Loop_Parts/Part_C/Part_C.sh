#!/bin/bash
########  XF output conversion code (C)  ###########################################################################################
#
#
#         1. Converts .uan file from XF into a readable .dat file that Arasim can take in.
#
#
####################################################################################################################################
#variables
WorkingDir=$1
RunName=$2
gen=$3
source $WorkingDir/Run_Outputs/$RunName/setup.sh

#chmod -R 777 /fs/ess/PAS1960/BiconeEvolutionOSC/BiconeEvolution/

cd "$WorkingDir"
cd Antenna_Performance_Metric
## move the .uan files to the run directory
## XFintoARA.py will read them and then in part D we will move them into dedicated directories
mv *.uan $WorkingDir/Run_Outputs/$RunName/uan_files/
## Run AraSim -- feeds the plots into AraSim 
## First we convert the plots from XF into AraSim readable files, then we move them to AraSim directory and execute AraSim

#chmod -R 777 $WorkingDir/Antenna_Performance_Metric
python XFintoARA.py $NPOP $WorkingDir $RunName $gen $indiv

#chmod -R 777 /fs/ess/PAS1960/BiconeEvolutionOSC/BiconeEvolution/
