####### GENERAL PARAMS ###############################################################################################
TotalGens=100			## number of generations (after initial) to run through
NPOP=50				## number of individuals per generation; please keep this value below 99
Seeds=10			## This is how many AraSim jobs will run for each individual## the number frequencies being iterated over in XF (Currectly only affects the output.xmacro loop)
FREQ=60				## the number frequencies being iterated over in XF (Currectly only affects the output.xmacro loop)
NNT=30000			## Number of Neutrinos Thrown in AraSim   
exp=18				## exponent of the energy for the neutrinos in AraSim
ScaleFactor=1.0			## ScaleFactor used when punishing fitness scores of antennae larger than the drilling holes
GeoFactor=1			## This is the number by which we are scaling DOWN our antennas. This is passed to many files
num_keys=4			## how many XF keys we are letting this run use
database_flag=0			## 0 if not using the database, 1 if using the database
DEBUG_MODE=0			## 1 for testing (ex: send specific seeds), 0 for real runs
########### ANTENNA PARAMS ##########################################################################################
antenna="VPOL"             ## This is the type of antenna we are evolving. Options are "VPOL" or "HPOL" 
############## VPOL PARAMS ##########################################################################################
RADIUS=0			## If 1, radius is asymmetric. If 0, radius is symmetric		
LENGTH=0			## If 1, length is asymmetric. If 0, length is symmetric
ANGLE=0				## If 1, angle is asymmetric. If 0, angle is symmetric
CURVED=0			## If 1, evolve curved sides. If 0, sides are straight
A=0				## If 1, A is asymmetric
B=0				## If 1, B is asymmetric
SEPARATION=0    		## If 1, separation evolves. If 0, separation is constant
NSECTIONS=1 			## The number of chromosomes
############## HPOL PARAMS #########################################################################################
num_plates=4             ## The number of plates in the HPOL antenna
# Not totally sure how twe should add this in based on how VPOL is implemented
############ GA #####################################################################################################
REPRODUCTION=3			## Number (not fraction!) of individuals formed through reproduction
CROSSOVER=36			## Number (not fraction!) of individuals formed through crossover
MUTATION=25			## Probability of mutation (divided by 100)
SIGMA=6				## Standard deviation for the mutation operation (divided by 100)
ROULETTE=8			## Percent of individuals selected through roulette (divided by 10)
TOURNAMENT=2			## Percent of individuals selected through tournament (divided by 10)
RANK=0				## Percent of individuals selected through rank (divided by 10)
ELITE=0				## Elite function on/off (1/0)