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

cd $WorkingDir/Run_Outputs/$RunName/GPUFlags/
flag_files=$(ls | wc -l)

while [[ $flag_files -lt $NPOP ]]
do
	sleep 1m
	echo $flag_files
	flag_files=$(ls | wc -l)
done

rm -f $WorkingDir/Run_Outputs/$RunName/GPUFlags/*

echo $flag_files
echo "Done!"

cd $WorkingDir

# Removing Old output xmacro
rm -f $RunXmacrosDir/output.xmacro

# Writing new xmacro
echo "Writing output.xmacro!" 

echo "var popsize = $NPOP;" >> $RunXmacrosDir/output.xmacro
echo "var gen = \"$gen\";" >> $RunXmacrosDir/output.xmacro
echo "var WorkingDir = \"$WorkingDir\";" >> $RunXmacrosDir/output.xmacro
echo "var RunDir = \"$RunDir\";" >> $RunXmacrosDir/output.xmacro

cat $XmacrosDir/shortened_outputmacroskeleton.js >> $RunXmacrosDir/output.xmacro

xfdtd $XFProj --execute-macro-script=$RunXmacrosDir/output.xmacro || true --splash=false
