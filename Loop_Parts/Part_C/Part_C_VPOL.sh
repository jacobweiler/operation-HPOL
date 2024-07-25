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
indiv=$4
source $WorkingDir/Run_Outputs/$RunName/setup.sh

cd $WorkingDir

python Antenna_Performance_Metric/XFintoARA_VPOL.py $NPOP $WorkingDir $RunName $gen $indiv
