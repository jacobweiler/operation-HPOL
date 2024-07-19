#!/bin/bash
########  Fitness Score Generation (E)  ######################################################################################################### 
#
#
#      1. Takes AraSim data and cocatenates each file name into one string that is then used to generate fitness scores 
#
#      2. Then gensData.py extracts useful information from generationDNA.csv and fitnessScores.csv, and writes to maxFitnessScores.csv and runData.csv
#
#      3. Copies each .uan file from the Antenna_Performance_Metric folder and moves to Run_Outputs/$RunName folder
#
#
#################################################################################################################################################### 

#variables
WorkingDir=$1
RunName=$2
gen=$3
source $WorkingDir/Run_Outputs/$RunName/setup.sh

module load python/3.7-2019.10

cd $WorkingDir

cd Antenna_Performance_Metric/

echo 'Starting fitness function calculating portion...'

ara_processes=$((threads * Seeds))

python ara_fitness.py $WorkingDir $RunName $gen $NPOP $ara_processes $ScaleFactor -geoscalefactor $GeoFactor

cd $WorkingDir

if [ $gen -eq 0 ]; then
	rm -f Generation_Data/runData.csv
fi

if [ $indiv -eq $NPOP ]; then
	cp Generation_Data/runData.csv $WorkingDir/Run_Outputs/$RunName/runData_$gen.csv
fi

echo 'Congrats on getting a fitness score!'

mkdir -m777 $RunDir/Generation_Data/Generation_${gen}
mv $RunDir/Generation_Data/${gen}_penalty.csv $RunDir/Generation_Data/Generation_${gen}/
mv $RunDir/Generation_Data/${gen}_generationDNA.csv $RunDir/Generation_Data/Generation_${gen}/
mv $RunDir/Generation_Data/${gen}_Veff.csv $RunDir/Generation_Data/Generation_${gen}/
mv $RunDir/Generation_Data/${gen}_Veff_Error.csv $RunDir/Generation_Data/Generation_${gen}/
mv $RunDir/Generation_Data/${gen}_Fitness_Error.csv $RunDir/Generation_Data/Generation_${gen}/
cp $RunDir/Generation_Data/${gen}_fitnessScores.csv $RunDir/Generation_Data/Generation_${gen}/
cp $RunDir/Generation_Data/${gen}_population.pkl $RunDir/Generation_Data/Generation_${gen}/
