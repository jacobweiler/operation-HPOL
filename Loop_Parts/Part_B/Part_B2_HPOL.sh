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

# Removing Old output xmacro
rm -f $RunXmacrosDir/output.xmacro

# Writing new xmacro
echo "var NPOP = $NPOP;" >> $RunXmacrosDir/output.xmacro
echo "var gen = \"$gen\";" >> $RunXmacrosDir/output.xmacro
echo "var WorkingDir = \"$WorkingDir\";" >> $RunXmacrosDir/output.xmacro
echo "var RunDir = \"$WorkingDir/RunData/$RunName\";" >> $RunXmacrosDir/output.xmacro
echo "for (var k = $(($gen*$NPOP + 1)); k <= $(($gen*$NPOP+$NPOP)); k++){" >> $RunXmacrosDir/output.xmacro

cat shortened_outputmacroskeleton.txt >> $RunXmacrosDir/output.xmacro

sed -i "s+fileDirectory+${WorkingDir}+" $RunXmacrosDir/output.xmacro

module load xfdtd/7.10.2.3
xfdtd $XFProj --execute-macro-script=$RunXmacrosDir/output.xmacro || true --splash=false
