"""Calculate the AraSim Fitness of the individuals in the population"""
import argparse
import importlib
import sys
import numpy as np
import csv

from pathlib import Path


def parse_args():
    '''Parse command line arguments'''
    parser = argparse.ArgumentParser()
    parser.add_argument("workingdir", help="Working Directory", type=Path)
    parser.add_argument("run_name", help="Run Name", type=str)
    parser.add_argument("gen", help="Current generation", type=int)
    parser.add_argument("npop", help="Pop Size", type=int)
    parser.add_argument("ara_processes", help="The number of seeds", type=int)
    parser.add_argument("scalefactor",help="Exponential Constraint Factor",type=float)
    parser.add_argument("-job", help="What job is being used?", type=int, default=-1)
    parser.add_argument("-geoscalefactor",help="Antenan Scale Factor",
                        type=float,default=1)
    parser.add_argument("-bh_penalty", help="Borehole Penalty", 
                        type=int, default=0)
    parser.add_argument("-vpol_type", help="VPol Type", type=int, default=0)
    return parser.parse_args()


def file_tail(job, gen, process, indiv=0):
    '''Return the tail of the file name'''
    if job == -1:
        tail = (Path("AraSim_Outputs") 
                / f"{gen}_AraSim_Outputs" 
                / f"AraOut_{gen}_{indiv}_{process}.txt")
    else:
        tail = (Path("tempFiles") / f"job_{job}" 
                / f"AraOut_{job}_{process}.txt")
    return tail


def parse_ara_output(filename):
    '''Parse the AraSim output file for the Veff and error values'''
    veffstring = "Veff(ice) : "
    errorplusstring = "error plus : "
    # If veff string not found set to none
    veff, errorplus, errorminus = None, None, None
    with open(filename, "r") as file:
        for line in file:
            if veffstring in line:
                veff = float(line.split(" : ")[1].split(" ")[2])
            if errorplusstring in line:
                errorplus, errorminus = map(lambda x: float(x.split(" ")[0]), 
                                            line.split(" : ")[1:3])

    return veff, errorplus, errorminus


def main(g):
    radiusconstraint = 7.5  # The radius of the bore hole in cm
    bhrad = radiusconstraint / g.geoscalefactor
    job = g.job
    rundir = g.workingdir / "Run_Outputs" / g.run_name
    fitnesses = []
    fit_lowerrors = []
    fit_higherrors = []
    veffs = []
    lowerrors = []
    higherrors = []
    
    # Opening Generation DNA file and read in the radius then add .02 for the thickness of plates
    # Read the file and parse each line into its own list of entries
    data_list = []
    file_path = rundir / f"Generation_Data/Generation_{g.gen}/{g.gen}_generationDNA.csv"
    with open(file_path, 'r') as file:
        for line in file:
            # Strip newline characters and split the line by comma
            entries = line.strip().split(',')
            # Convert entries to float if possible
            entries = [float(entry) for entry in entries]
            data_list.append(entries)
        
    # Calculate the fitness and error values for each individual
    for i in range(1, g.npop + 1):
        sumveff = 0.0
        sumsquarelowerror = 0.0
        sumsquarehigherror = 0.0

        # Calculate the total Veff and error values for each seed
        seeds_successful = g.ara_processes
        for j in range(1, g.ara_processes + 1):
            filename = rundir / file_tail(job, g.gen, j, indiv=i)
            veff, errorplus, errorminus = parse_ara_output(filename)
            print(veff)
            if veff is None:
                seeds_successful -= 1
                continue

            sumveff += veff
            sumsquarelowerror += errorplus ** 2
            sumsquarehigherror += errorminus ** 2

        if seeds_successful == 0:
            print(f"Error: No successful seeds for individual {i}")
            indiv_veff = 0
            indiv_lowerror = 0
            indiv_higherror = 0
        else:
            indiv_veff = sumveff / seeds_successful
            indiv_lowerror = np.sqrt(sumsquarelowerror) / g.ara_processes
            indiv_higherror = np.sqrt(sumsquarehigherror) / g.ara_processes

        penalty = 1
        # Calculate the penalty for the individual
        if g.vpol_type == 0: # NSECTIONS = 1
            # Double check this
            current_indiv = data_list[i-1]
            current_radius = current_indiv[0]
            max_xy  = current_radius
        elif g.vpol_type == 1: # NSECTIONS = 0, SEPARATION = 1
            # Double check this
            current_indiv = data_list[i-1]
            current_radius = current_indiv[0]
            max_xy  = current_radius
        elif g.vpol_type == 2: # NSECTIONS = 0, SEPARATION = 0
            # Double check this
            current_indiv = data_list[i-1]  
            current_radius = current_indiv[0]
            max_xy  = current_radius
        else: # HPOL
            current_indiv = data_list[i-1]
            current_radius = current_indiv[1]
            max_xy = float(current_radius) + 0.02
        
        if max_xy >= bhrad and g.bh_penalty == 1:
            penalty = np.exp(-(g.scalefactor * (max_xy - bhrad) ** 2))

        if job != -1:
            csv_dir = rundir / "tempFiles" / f"job_{job}"
            penalty_file = csv_dir / f"{job}_penalty.csv"
        else:
            csv_dir = rundir / f"Generation_Data"
            penalty_file = csv_dir / f"{g.gen}_penalty.csv"
        
        with open(penalty_file, "a") as file:
            file.write(f"{i},0,{penalty}\n")
        
        print(f"Individual {i} has a penalty of {penalty}")
        
        # Append the fitness and error values to the lists
        fitnesses.append(indiv_veff * penalty)
        fit_lowerrors.append(indiv_lowerror * penalty)
        fit_higherrors.append(indiv_higherror * penalty)
        veffs.append(indiv_veff)
        lowerrors.append(indiv_lowerror)
        higherrors.append(indiv_higherror)

    output_dir = rundir / (f"Generation_Data" if job == -1 else f"tempFiles/job_{job}")

    error_array = np.column_stack((higherrors, lowerrors))
    fit_error_array = np.column_stack((fit_higherrors, fit_lowerrors))
    
    if job == -1:
        file_front = f"{g.gen}_"
    else:
        file_front = f"{job}_"
    
    # Save the fitness and error values to csv files
    np.savetxt(output_dir / f"{file_front}fitnessScores.csv", fitnesses, delimiter=",")
    np.savetxt(output_dir / f"{file_front}Fitness_Error.csv", fit_error_array, delimiter=",")
    np.savetxt(output_dir / f"{file_front}Veff.csv", veffs, delimiter=",")
    np.savetxt(output_dir / f"{file_front}Veff_Error.csv",  error_array, delimiter=",")


if __name__ == "__main__":
    args = parse_args()
    main(args)
