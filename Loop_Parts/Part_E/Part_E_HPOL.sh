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
# put the actual bicone results in the run name directory
cp ARA_Bicone_Data/AraOut_Actual_Bicone_Fixed_Polarity_2.9M_NNU.txt Run_Outputs/$RunName/AraOut_ActualBicone.txt

cd Antenna_Performance_Metric/

echo 'Starting fitness function calculating portion...'
mkdir -m775 $WorkingDir/Run_Outputs/$RunName/Root_Files/Root_Files_${gen}
mv *.root $WorkingDir/Run_Outputs/$RunName/Root_Files/Root_Files_${gen}/

for i in `seq $indiv $NPOP`;do
	InputFiles="${InputFiles}AraOut_${gen}_${i}.txt " 
done

cp $WorkingDir/Run_Outputs/$RunName/Generation_Data/${gen}_generationDNA.csv $WorkingDir/Generation_Data/generationDNA.csv

./fitnessFunction.exe $NPOP $Seeds $ScaleFactor $WorkingDir/Generation_Data/generationDNA.csv $GeoFactor $InputFiles #Here's where we add the flags for the generation
cp fitnessScores.csv "$WorkingDir"/Run_Outputs/$RunName/${gen}_fitnessScores.csv
mv fitnessScores.csv $WorkingDir/Generation_Data/

cp vEffectives.csv "$WorkingDir"/Run_Outputs/$RunName/${gen}_vEffectives.csv
mv vEffectives.csv $WorkingDir/Generation_Data/

cp errorBars.csv "$WorkingDir"/Run_Outputs/$RunName/${gen}_errorBars.csv
mv errorBars.csv $WorkingDir/Generation_Data/

cd $WorkingDir

if [ $gen -eq 0 ]; then
	rm -f Generation_Data/runData.csv
fi

if [ $indiv -eq $NPOP ]; then
	cp Generation_Data/runData.csv $WorkingDir/Run_Outputs/$RunName/runData_$gen.csv
fi

python Data_Generators/gensData.py $gen Generation_Data 

cd $WorkingDir/Antenna_Performance_Metric

python3 avg_freq.py $XFProj $XFProj 10 $NPOP

cd $XFProj
mv gain_vs_freq.png gain_vs_freq_gen_$gen.png

echo 'Congrats on getting a fitness score!'

cd $WorkingDir/Run_Outputs/$RunName

mkdir -m777 AraOut_$gen
cd $WorkingDir
for i in `seq 1 $NPOP`; do
    for j in `seq 1 $Seeds`; do
		mv $RunDir/AraSim_Outputs/AraOut_${gen}_${i}_${j}.txt $WorkingDir/Run_Outputs/$RunName/AraOut_${gen}/AraOut_${gen}_${i}_${j}.txt
	done
done 

mv Generation_Data/parents.csv Run_Outputs/$RunName/${gen}_parents.csv
mv Generation_Data/genes.csv Run_Outputs/$RunName/${gen}_genes.csv
mv Generation_Data/mutations.csv Run_Outputs/$RunName/${gen}_mutations.csv
mv Generation_Data/generators.csv Run_Outputs/$RunName/${gen}_generators.csv
