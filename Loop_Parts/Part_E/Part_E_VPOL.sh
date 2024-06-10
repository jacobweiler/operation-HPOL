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

if [ $ParallelAra -eq 1 ]; then
	# maybe change 40 to a variable that's passed in
	ara_processes=$((Seeds*40))
else
	ara_processes=$Seeds
fi

echo "ara_processes: " $ara_processes

module load python/3.7-2019.10

# Moving Results to Generation_Data Folder in run directory
cd $WorkingDir
cp ARA_Bicone_Data/AraOut_Actual_Bicone_Fixed_Polarity_2.9M_NNU.txt Run_Outputs/$RunName/Generation_Data/Generation_${gen}/AraOut_ActualBicone.txt

cd Antenna_Performance_Metric/

echo 'Starting fitness function calculating portion...'
mkdir -m775 $WorkingDir/Run_Outputs/$RunName/Root_Files/Root_Files_${gen}
mv *.root $WorkingDir/Run_Outputs/$RunName/Root_Files/Root_Files_${gen}/

for i in `seq $indiv $NPOP`; do
    InputFiles="${InputFiles}AraOut_${gen}_${i}.txt "
done

if [ $NSECTIONS -eq 1 ]; then
	# Compiling and Run
	g++ -std=c++11 fitnessFunction_ARA.cpp -o fitnessFunction.exe
	./fitnessFunction.exe $NPOP $ara_processes $ScaleFactor $WorkingDir/Generation_Data/generationDNA.csv $GeoFactor $InputFiles 
else
	if [ $SEPARATION -eq 1 ]; then
        # Compile and Run
		g++ -std=c++11 fitnessFunction_ARA_Sep.cpp -o fitnessFunction_Sep.exe
		./fitnessFunction_Sep.exe $NPOP $ara_processes $ScaleFactor $WorkingDir/Generation_Data/generationDNA.csv $GeoFactor $InputFiles 
	else
        # Compile and Run
		g++ -std=c++11 fitnessFunction_ARA_Asym.cpp -o fitnessFunction_asym.exe
		./fitnessFunction_asym.exe $NPOP $ara_processes $ScaleFactor $WorkingDir/Generation_Data/generationDNA.csv $GeoFactor $InputFiles 
	fi
fi

cp fitnessScores.csv $WorkingDir/Run_Outputs/$RunName/Generation_Data/Generation_${gen}/${gen}_fitnessScores.csv
mv fitnessScores.csv $WorkingDir/Generation_Data/

cp vEffectives.csv $WorkingDir/Run_Outputs/$RunName/Generation_Data/Generation_${gen}/${gen}_vEffectives.csv
mv vEffectives.csv $WorkingDir/Generation_Data/

cp errorBars.csv $WorkingDir/Run_Outputs/$RunName/Generation_Data/Generation_${gen}/${gen}_errorBars.csv
mv errorBars.csv $WorkingDir/Generation_Data/

#Plotting software for Veff(for each individual) vs Generation
python Veff_Plotting.py $WorkingDir/Run_Outputs/$RunName $WorkingDir/Run_Outputs/$RunName $gen $NPOP $Seeds 

cd $WorkingDir

if [ $gen -eq 0 ]; then
	rm -f Generation_Data/runData.csv
fi

if [ $indiv -eq $NPOP ]; then
	cp Generation_Data/runData.csv $WorkingDir/Run_Outputs/$RunName/runData_$gen.csv
fi

python Data_Generators/gensData_asym.py $gen $NSECTIONS $NPOP Generation_Data
cd Antenna_Performance_Metric
next_gen=$((gen+1))

if [ $CURVED -eq 0 ]; then
# I can potentially simplify this further by making the if statement in LRTPlot instead
: <<'END'
if [ $NSECTIONS -eq 1 ]
then
	python LRTPlot.py $WorkingDir/Generation_Data $WorkingDir/Run_Outputs/$RunName $next_gen $NPOP $GeoFactor
else
	## Let's consider whether or not we're evolving the separation distance
	if [ $SEPARATION -eq 0 ]
	then
		python LRTPlot2.0.py $WorkingDir/Generation_Data $WorkingDir/Run_Outputs/$RunName $next_gen $NPOP $GeoFactor $NSECTIONS	
	else
		python LRTSPlot.py $WorkingDir/Generation_Data $WorkingDir/Run_Outputs/$RunName $next_gen $NPOP $GeoFactor $NSECTIONS
	fi
fi
END
else
    #This is where we'll make the rainbow plot
    python Antenna_Performance_Metric/DataConverter_quad.py
    /cvmfs/ara.opensciencegrid.org/trunk/centos7/misc_build/bin/python3.9 Antenna_Performance_Metric/Rainbow_Plotter.py
    ## Jacob call Dennis' script here!
    
    ## Needs the path to the root files as an argument
    mv Generation_Data/Rainbow_Plot.png Run_Outputs/$RunName/Evolution_Plots/Rainbow_Plot.png

    # Since we know we're using the curved on, just call the curved LRAB plot script
    python Antenna_Performance_Metric/LRABPlot.py $WorkingDir/Generation_Data $WorkingDir/Run_Outputs/$RunName $next_gen $NPOP $GeoFactor $NSECTIONS
fi

cd $AraSimExec
for i in `seq 1 $NPOP`; do
	mv a_${i}.txt $XFProj/XF_model_${gen}_${i}.txt
done

echo 'Congrats on getting a fitness score!'

cd $WorkingDir/Run_Outputs/$RunName
mkdir -m777 AraOut/AraOut_$gen

cd $WorkingDir/Antenna_Performance_Metric
for i in `seq 1 $NPOP`; do
    for j in `seq 1 $ara_processes`; do
        cp AraOut_${gen}_${i}_${j}.txt $WorkingDir/Run_Outputs/$RunName/AraOut/AraOut_${gen}/AraOut_${gen}_${i}_${j}.txt
	done
done 

cd $WorkingDir

# I still need to add these changes into the asymmetric algorithm
if [ $gen -gt 0 ]; then
	mv Generation_Data/parents.csv Run_Outputs/$RunName/${gen}_parents.csv
	mv Generation_Data/genes.csv Run_Outputs/$RunName/${gen}_genes.csv
	mv Generation_Data/mutations.csv Run_Outputs/$RunName/${gen}_mutations.csv
fi

mv Generation_Data/generators.csv Run_Outputs/$RunName/${gen}_generators.csv
