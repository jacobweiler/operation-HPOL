
########    Execute our initial genetic algorithm (A)    #############################################################################
#
#
#   This part of the loop  ::
#
#      1. Runs genetic algorithm
#
#
#      2. Moves GA outputs and renames the .csv file so it isn't overwritten 
#
#
#
#
#######################################################################################################################################
#variables
WorkingDir=$1
RunName=$2
gen=$3
source $WorkingDir/Run_Outputs/$RunName/setup.sh

cd $WorkingDir

if [ $gen -eq 0 ]
then
    ./Loop_Parts/Part_A/MakeSettings.sh $WorkingDir $RunName
fi

python Shared-Code/PyGA/Run_GA.py $RunName $WorkingDir $gen

# check the exit status
if [ $? -eq 0 ]
then
    echo "GA ran successfully"
else
    echo "GA failed"
    exit 1
fi
