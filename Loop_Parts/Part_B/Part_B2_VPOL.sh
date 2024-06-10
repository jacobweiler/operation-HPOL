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

if [ $database_flag -eq 1 ]; then 
    Database=$WorkingDir/Database/database.txt
    NewDataFile=$WorkingDir/Database/newData.txt
    RepeatDataFile=$WorkingDir/Database/repeatData.txt
    GenDNA=$WorkingDir/Run_Outputs/$RunName/${gen}_generationDNA.csv
fi

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
cd $XmacrosDir
rm -f output.xmacro

# Writing new xmacro
echo "var NPOP = $NPOP;" >> output.xmacro
echo "for (var k = $(($gen*$NPOP + 1)); k <= $(($gen*$NPOP+$NPOP)); k++){" >> output.xmacro

if [ $NSECTIONS -eq 1 ]; then
	cat shortened_outputmacroskeleton.txt >> output.xmacro
else
	cat shortened_outputmacroskeleton_Asym.txt >> output.xmacro
fi

sed -i "s+fileDirectory+${WorkingDir}+" output.xmacro

module load xfdtd/7.9.2.2
xfdtd $XFProj --execute-macro-script=$XmacrosDir/output.xmacro || true --splash=false

cd $WorkingDir/Antenna_Performance_Metric
for i in `seq $(($gen*$NPOP + $indiv)) $(($gen*$NPOP+$NPOP))`; do
	pop_ind_num=$(($i - $gen*$NPOP))
	for freq in `seq 1 60`; do
		mv ${i}_${freq}.uan "$WorkingDir"/Run_Outputs/$RunName/uan_files/${gen}_${pop_ind_num}_${freq}.uan
	done
done

if [ $database_flag -eq 1 ]; then 
    #This is adding files to the database
    cd $WorkingDir/Database
    # we're going to need to fix the database for asymmetry (it's not built for it yet)
    if [ $NSECTIONS -eq 1 ]; then
        ./dataAdd.exe $NPOP $GenDNA $Database $NewDataFile 3
    else
        ./dataAdd.exe $NPOP $GenDNA $Database $NewDataFile
    fi

    FILE=$NewDataFile

    while read f1 f2; do
        cd $WorkingDir/Database
        mkdir -m777 $f2
        cd $WorkingDir/Run_Outputs/$RunName
        for i in `seq 1 60`; do
            cp ${gen}_${f1}_$i.uan $WorkingDir/Database/$f2/$i.uan
        done
    done < $FILE
fi 