#!/bin/bash
########  Plotting (F)  ############################################################################################################################ 
#
#
#      1. Plots in 3D and 2D of current and all previous generation's scores. Saves the 2D plots. Extracts data from $RunName folder in all of the i_generationDNA.csv files. Plots to same directory.
#
#
#################################################################################################################################################### 
# variables
WorkingDir=$1
RunName=$2
gen=$3
source $WorkingDir/Run_Outputs/$RunName/setup.sh

# Current Plotting Software

cd $WorkingDir

module load python/3.7-2019.10

#cp AraOut_ActualBicone_10_18.txt Run_Outputs/$RunName/AraOut_ActualBicone.txt
#cp ARA_Bicone_Data/AraOut_Actual_Bicone_Fixed_Polarity_2.9M_NNU.txt Run_Outputs/$RunName/AraOut_ActualBicone.txt

cd Antenna_Performance_Metric

#Plotting software for Veff(for each individual) vs Generation
python Plotting/Veff_Plotting.py "$WorkingDir"/Run_Outputs/$RunName "$WorkingDir"/Run_Outputs/$RunName $gen $NPOP $Seeds

# Format is source directory (where is generationDNA.csv), destination directory (where to put plots), npop
python FScorePlot.py $WorkingDir/Run_Outputs/$RunName $WorkingDir/Run_Outputs/$RunName $NPOP $gen

python3 color_plots.py $WorkingDir/Run_Outputs/$RunName/ $WorkingDir/Run_Outputs/$RunName $NPOP $gen $Seeds

mkdir -m 775 $WorkingDir/Run_Outputs/$RunName/Gain_Plots/${gen}_Gain_Plots
./image_maker.sh $WorkingDir/Run_Outputs/$RunName/Generation_Data/Generation_${gen} $WorkingDir/../Xmacros $WorkingDir/Run_Outputs/$RunName/Antenna_Images $gen $WorkingDir $RunName $NPOP

echo 'Congrats on getting some nice plots!'

## I'm going to get rid of all of the slurm files being created
cd "$WorkingDir"
rm -f slurm-*
