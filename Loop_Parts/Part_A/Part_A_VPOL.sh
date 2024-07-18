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
#chmod -R 777 /fs/project/PAS0654/BiconeEvolutionOSC/BiconeEvolution/

# NOTE: the asymmetric bicone_GA.exe should be compiled from fourGeneGA_cutoff_testing.cpp
# (It tells you at the top of the cpp file how to compile)

cd $WorkingDir

if [ $CURVED -eq 0 ]; then
    if [ $NSECTIONS -eq 0 ]; then # if $NSECTIONS is 1, then it is symmetric (see Asym_XF_Loop.sh)
        #g++ -std=c++11 roulette_algorithm_cut_test.cpp -o bicone_GA.exe 
        g++ -std=c++11 GA/Algorithms/improved_GA.cpp -o GA/Executables/bicone_GA.exe
        if [ $gen -eq 0 ]; then
            ./GA/Executables/bicone_GA.exe start $NPOP $GeoFactor
        else
            ./GA/Executables/bicone_GA.exe cont $NPOP $GeoFactor 
        fi	
    else
        g++ -std=c++11 GA/Algorithms/Latest_Asym_GA.cpp -o GA/Executables/bicone_GA.exe
        if [ $gen -eq 0 ]; then
            ./GA/Executables/bicone_GA.exe start $NPOP $GeoFactor 3 36 2 #$NSECTIONS $GeoFactor #$RADIUS $LENGTH $ANGLE $SEPARATION
        else
            ./GA/Executables/bicone_GA.exe cont $NPOP $GeoFactor 3 36 2 #3 36 8 #$NSECTIONS $GeoFactor #$RADIUS $LENGTH $ANGLE $SEPARATION 
        fi
    fi
else
    if [ $NSECTIONS -eq 1 ]; then # if SYMMETRY is 1, then it is symmetric (see Asym_XF_Loop.sh)
        g++ -std=c++11 GA/Algorithms/parent_track_GA.cpp -o GA/Executables/bicone_GA.exe
        if [ $gen -eq 0 ]; then
            ./GA/Executables/bicone_GA.exe start $NPOP $GeoFactor
        else
            ./GA/Executables/bicone_GA.exe cont $NPOP $GeoFactor
        fi	
    else
        g++ -std=c++11 GA/Algorithms/curved_seeded_ga.cpp -o GA/Executables/bicone_GA.exe
        if [ $gen -eq 0 ]; then
            ./GA/Executables/bicone_GA.exe start $NPOP $REPRODUCTION $CROSSOVER $MUTATION $SIGMA $ROULETTE $TOURNAMENT $RANK $ELITE 
        else
            ./GA/Executables/bicone_GA.exe cont $NPOP $REPRODUCTION $CROSSOVER $MUTATION $SIGMA $ROULETTE $TOURNAMENT $RANK $ELITE
        fi
    fi
fi
echo "Flag: Successfully Ran GA!"

mkdir -m775 $RunDir/Generation_Data/Generation_${gen}
cp Run_Outputs/generationDNA.csv $RunDir/Generation_Data/Generation_${gen}/${gen}_generationDNA.csv
mv Run_Outputs/generationDNA.csv $RunDir/Generation_Data/generationDNA.csv
mv Run_Outputs/generators.csv $WorkingDir/Run_Outputs/${RunName}/Generation_Data/Generation_${gen}/${gen}_generators.csv
if [ $gen -gt 0 ]; then
        mv Run_Outputs/Parents.csv $WorkingDir/Run_Outputs/${RunName}/Generation_Data/Generation_${gen}/${gen}_parents.csv
fi
