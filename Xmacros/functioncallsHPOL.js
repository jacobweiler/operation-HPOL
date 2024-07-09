/********************************************* Function Calls **************************************************/
var file = new File(path);
file.open(1);
var generationDNA = file.readAll();

// Lists to hold the genes
var num_plates =[]; // Number of plates
var radius = []; // Radius of the antenna
var arclength = []; // Arc length of the plates
var antenna_height = []; // Height of the antenna

var lines = generationDNA.split('\n');

// Loop over reading in the gene values
for(var i = 0;i < lines.length - 1;i++){
	if(i>=antennaLines){
		var params = lines[i].split(",");
		Output.println("Individual "+ i);
		Output.println("Number of Plates: "+params[0]);
		Output.println("Radius: "+params[1]);
		Output.println("Arclength: "+params[2]);
		Output.println("Antenna Height: "+params[3]);

		num_plates[i-antennaLines]=params[0];
		radius[i-antennaLines]=params[1];
		arclength[i-antennaLines]=params[2];
		antenna_height[i-antennaLines]=params[3];
        
	}
}

for(var i = indiv - 1; i < NPOP; i++)
{
    var plate_num = num_plates[i];
    var rad = radius[i];
    var arc = arclength[i];
    var height = antenna_height[i];

    Output.println('plate_num: ' + plate_num);
    Output.println('rad: ' + rad);
    Output.println('arc: ' + arc);
    Output.println('height: ' + height);

    App.getActiveProject().getGeometryAssembly().clear();
    CreatePEC();
    build_hpol(plate_num, rad, thick, arc, height);
    CreateAntennaSource(zpos_ground, zpos_feed); 
    CreateGrid();
    CreateSensors();
    CreateAntennaSimulationData();
    QueueSimulation();
    Output.println(ResultQuery().simulationId);
    MakeImage(i);
}

file.close();
App.quit();