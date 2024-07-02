/**************************************** Set Global Variables **************************************************/
var units = " cm";
var plate_num = 4; // 4 for now until we implement a generic implementation
var thick = 0.02; // Thickness of the HPOL plates
var path = workingdir + "/Run_Outputs/" + RunName + "/Generation_Data/" + gen + "_generationDNA.csv"

// feed coords
var zpos_ground = 1.98;
var zpos_feed = 2.02;

// create the frequency array
var freq = [];
for (var i = 0; i < freqCoefficients; i++) {
    freq.push(freq_start + i * freq_step);
}