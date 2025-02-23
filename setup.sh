####### GENERAL PARAMS ###############################################################################################
TotalGens=1			## number of generations (after initial) to run through
NPOP=2				## number of individuals per generation; please keep this value below 99
Seeds=10			## This is how many AraSim jobs will run for each individual## the number frequencies being iterated over in XF (Currectly only affects the output.xmacro loop)
FREQS=60				## the number frequencies being iterated over in XF (Currectly only affects the output.xmacro loop)
FreqStart=83.33     ## Start of Frequency Range
FreqStep=16.67      ## Step Size of Frequency
NNT=30000			## Number of Neutrinos Thrown in AraSim in total  
exp=18				## exponent of the energy for the neutrinos in AraSim
ScaleFactor=1.0			## ScaleFactor used when punishing fitness scores of antennae larger than the drilling holes
GeoFactor=1			## This is the number by which we are scaling DOWN our antennas. This is passed to many files
num_keys=4			## how many XF keys we are letting this run use
database_flag=0			## 0 if not using the database, 1 if using the database
DEBUG_MODE=0			## 1 for testing (ex: send specific seeds), 0 for real runs
SpecificSeed=32000      ## Specific Seed used for AraSim
########### ANTENNA PARAMS ##########################################################################################
antenna="VPOL"             ## This is the type of antenna we are evolving. Options are "VPOL" or "HPOL" 
############## VPOL PARAMS ##########################################################################################
RADIUS=0			## If 1, radius is asymmetric. If 0, radius is symmetric		
LENGTH=0			## If 1, length is asymmetric. If 0, length is symmetric
ANGLE=0				## If 1, angle is asymmetric. If 0, angle is symmetric
CURVED=1			## If 1, evolve curved sides. If 0, sides are straight
A=0				## If 1, A is asymmetric
B=0				## If 1, B is asymmetric
SEPARATION=0    		## If 1, separation evolves. If 0, separation is constant
NSECTIONS=0 			## If 1 Symmetric, if 0 Asymmetric
############## HPOL PARAMS #########################################################################################
# Not sure what HPOL needs atm
############ GA #####################################################################################################
REPRODUCTION=0.1			## Percent going through reproduction
CROSSOVER=0.4			## Percent going through Crossover
MUTATION=0.5			    ## Percent going through Mutation
SIGMA=0.05			    ## Standard deviation for the mutation operation 
ROULETTE=0.8			    ## Percent of individuals selected through roulette 
TOURNAMENT=0.2			## Percent of individuals selected through tournament
RANK=0				    ## Percent of individuals selected through rank 
ELITE=0				    ## Elite function on/off (1/0)
############## JOB SUBMISSION #######################################################################################
SingleBatch=0       ## 1 to submit a single batch for XF jobs (each job running for n antennas)
maxJobs=100         ## max number of jobs submitted per user on OSC
threads_per_ara_job=40 ## Number of cores used per AraSim Job