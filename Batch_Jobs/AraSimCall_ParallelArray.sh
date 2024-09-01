#!/bin/bash
## This job is designed to be submitted by an array batch submission
## Here's the command:
## sbatch --array=1-NPOP*SEEDS%max --export=ALL,(variables) AraSimCall_Array.sh
#SBATCH -A PAS1960
#SBATCH -t 4:00:00
#SBATCH -N 1
#SBATCH -n 40

#variables
source $WorkingDir/Run_Outputs/$RunName/setup.sh

cd $AraSimDir

source /fs/ess/PAS1960/BiconeEvolutionOSC/new_root/new_root_setup.sh

threads=40
num=$(($((${SLURM_ARRAY_TASK_ID}-1))/${Seeds}+1))
seed=$(($((${SLURM_ARRAY_TASK_ID}-1))%${Seeds}+1))
# init = seed - 1
init=$((${seed}-1))

echo a_${num}_${seed}.txt

chmod -R 777 $AraSimDir/outputs/

# We need to create a setup file for each individual in the population 
gain_file="${RunDir}/txt_files/a_${num}.txt "

echo "gain file is $gain_file"

sed -e "s|num_nnu|$NNT|" -e "s|n_exp|$exp|" -e "s|current_seed|$SpecificSeed|" -e "s|vpol_gain|$gain_file|" ${AraSimDir}/SETUP/setup_dummy_vpol.txt > $TMPDIR/setup.txt

# starts running $threads processes of AraSim
echo "Starting AraSim processes"
for (( i=0; i<${threads}; i++ )); do
    # we need $threads unique id's for each seed
    dataoutloc="$TMPDIR/AraOut_${gen}_${indiv}_${indiv_thread}.txt"
    indiv_thread=$((${init}*${threads}+${i}))
    echo "individual thread is $indiv_thread"
    ./AraSim $TMPDIR/setup.txt ${indiv_thread} $TMPDIR > $TMPDIR/AraOut_${gen}_${num}_${indiv_thread}.txt > $dataoutloc &
done

wait

cd $TMPDIR

echo "Done running AraSim processes"

echo "Let's see what's in TMPDIR:"
ls -alrt

echo "Moving AraSim outputs to final destination"
for (( i=0; i<${threads}; i++ )); do
    indiv_thread=$((${init}*${threads}+${i}))
    echo "individual thread is $indiv_thread"
    #mv AraOut.setup.txt.run${indiv_thread}.root $WorkingDir/Antenna_Performance_Metric/AraOut_${gen}_${num}_${indiv_thread}.root
    rm AraOut.setup.txt.run${indiv_thread}.root
    mv $dataoutloc $WorkingDir/Run_Outputs/$RunName/AraSim_Outputs/${gen}_AraSim_Outputs/AraOut_${gen}_${indiv}_${indiv_thread}.txt
done

wait

echo $gen > $TMPDIR/${num}_${seed}.txt
echo $num >> $TMPDIR/${num}_${seed}.txt
echo $seed >> $TMPDIR/${num}_${seed}.txt
cd $TMPDIR

echo "Let's see what's in TMPDIR:"
ls -alrt

mv ${num}_${seed}.txt $WorkingDir/Run_Outputs/$RunName/AraSimFlags
