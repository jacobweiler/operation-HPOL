# Ara GENETIS Loop

This is the GENETIS Ara Loop that uses a genetic algorithm to evolve both VPOL and HPOL antennas for Ara. 

Multiple Versions of Loop: 
- VPOL Evolution
- HPOL Evolution
- VPOL + HPOL Evolution

# Current way of installing (Subject to change once pulled into main repo)
1. Go to desired location where you want to install the Ara Loop
2. Once in desired location we can type `git clone https://github.com/jacobweiler/operation-HPOL.git whateveryouwanttonamedirectory`
3. You may have to login to github if not already setup, but it should download the latest version on the main branch on github. After this, `cd whateveryouwanttonamedirectory/`
4. Now we need the Shared-Code as well, so after you have cd'ed, type `git clone https://github.com/osu-particle-astrophysics/Shared-Code.git`
5. We need to go to the branch with the current HPOL and VPOL implementations so go into the Shared-Code directory with `cd Shared-Code/` and then type `git checkout -b add_hpol origin/add_hpol`
   
Now you should be all set to run the loop. 

# How to run Ara Loop
1. Install Ara Loop (see previous instructions)
2. Go into and edit `setup.sh` to meet your wanted run parameters, save them.
3. In main directory type `./Loop_Scripts/Ara_Loop.sh RunName` and press enter. `RunName` is whatever your desired name of your current run, running this command with a previously used run name will result in your starting that run off from where it left off.
4. Press any key to start the loop. You should be going through creating the initial population.
5. XFdtd will open to create individuals, when first running a new run a popup will appear. **Press No**.
6. Now the loop will be running!

Note: The setup.sh file for each run after starting is copied and used from the `Run_Outputs/RunName` directory, so if you need to change parameters mid-run change the setup file in `Run_Outputs/RunName/setup.sh` where RunName is the name you gave the run. 
