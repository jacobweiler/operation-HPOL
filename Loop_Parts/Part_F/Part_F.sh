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

# Plotting Fitness vs generation plot (for every generation not 0)
if [ $gen -ne 0 ]; then
    python Antenna_Performance_Metric/Plotting/FScorePlot.py $RunDir $RunDir $NPOP $gen
fi 
# For every generation, getting the Top 3 Individuals (can be adjusted easily..)
# We want gain at multiple frequencies, frequency vs gain plot at different directions, PoR plots (theta_nu and theta_RF), VSWR and S11 Plots ETC 

if [ $gen -eq 0 ]; then 
    mkdir -m777 $RunDir/best_indivs/
    mkdir -m777 $RunDir/best_indivs/generational_bests
fi
# Get top 3 best individuals, creating a document for this generation that documents top3 for gen, then checks against current top 3 and replaces, if better

# If new individuals in top 3 (check which generation each best is from, if current then do plots), do wanted automatic plots. 
# do need to pass settings for hpol/vpol specific plots

    # Frequency Gain Plots

    # Frequency vs Gain Plots

    # VSWR and S11 Plots

    # PoR Plots




echo 'All Plots done, next generation commence!'

