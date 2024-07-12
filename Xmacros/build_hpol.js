// build HPOL antenna (units not working on this script, default units in cm)
function build_hpol(num_plates, radius, plate_thickness, arclength, antenna_height) 
{
    // Scaling the variables because you can't input the units in this method of building (for some reason)
	
    if (units == " cm"){
        scale = (1/100);
    }
    else if (units == " mm"){
        scale = (1/1000);
    }
    else if (units == " m"){
        scale = 1;
    } 
    // Scaling and other variables for the antenna
    var radius = radius * scale;
    var plate_thickness = plate_thickness * scale;
    var antenna_height = antenna_height * scale;
    var half_height = antenna_height/2;
    var feed_distance = feed_dist * scale; 
	// Start by creating a new pattern
	var ePattern = new EllipticalPattern();
	ePattern.setCenter(new CoordinateSystemPosition(0,0,0));
	ePattern.setNormal(new CoordinateSystemDirection(0,0,1));
	ePattern.setInstances(num_plates);      //number of instances must be less than twice arclength
	ePattern.setRotated(true);

	var x_rotator = (Math.cos(Math.PI/arclength));
	var y_rotator = (Math.sin(Math.PI/arclength));
    var x_rotation = Math.acos(x_rotator)
    var rotation = (Math.PI/2 - (x_rotation))/2 + x_rotation ; //This is an angle. It is half of the angle between PI/2 and the edge of the Cover Plates (given by x_rotation). The +0.02 is just to compensate for the thickness of the wires.

    // To see what this looks like, comment out the first semicircle sketch down below and uncomment the other one
	//(Deviding by arclength makes the arc legnth PI/arclength)
    //Building the cover plates:
	var outer = new LawEdge("("+radius+" + "+plate_thickness+")*cos(u/"+arclength+")","("+radius+" + "+plate_thickness+")*sin(u/"+arclength+")","0",0,Math.PI);  //Outer curve
    var inner = new LawEdge("("+radius+")*cos(u/"+arclength+")","("+radius+")*sin(u/"+arclength+")","0",0,Math.PI);   //Inner curve
    var line1 = new LawEdge("("+radius+")+("+plate_thickness+")*u/("+Math.PI+")","0","0",0,Math.PI);   //Right line
	var line2 = new LawEdge(""+x_rotator+"*("+radius+"+("+plate_thickness+")*u/("+Math.PI+"))",""+y_rotator+"*("+radius+"+("+plate_thickness+")*u/("+Math.PI+"))","0",0,Math.PI);//Left line
	
	//Building the lower set of wires:
    var wire1 = new LawEdge("(("+radius+")+("+plate_thickness+"))*u/("+Math.PI+")","0","("+half_height+ " - " +feed_distance+")",0,Math.PI); //line in x from (0,PI) with y=0 & z=0
    var wire2 = new LawEdge("("+radius+" +"+plate_thickness+")*u/("+Math.PI+")",""+plate_thickness+"","("+half_height+ " - " +feed_distance+")",0,Math.PI); //line in x from (0,PI) with y=0.2 & z=0
    var wire3 = new LawEdge("0","("+plate_thickness+")*u/("+Math.PI+")","("+half_height+ " - " +feed_distance+")",0,Math.PI);
    var wire4 = new LawEdge("(("+radius+")+("+plate_thickness+"))","("+plate_thickness+")*u/("+Math.PI+")","("+half_height+ " - " +feed_distance+")",0,Math.PI);

    //Building the top set of wires:
    var twire1 = new LawEdge("(("+radius+")+("+plate_thickness+"))*u/("+Math.PI+")","0","("+half_height+ " + " +feed_distance+")",0,Math.PI); //line in x from (0,PI) with y=0 & z=2.02
    var twire2 = new LawEdge("("+radius+" +"+plate_thickness+")*u/("+Math.PI+")",""+plate_thickness+"","("+half_height+ " + " +feed_distance+")",0,Math.PI); //line in x from (0,PI) with y=0.2 & z=2.02
    var twire3 = new LawEdge("0","("+plate_thickness+")*u/("+Math.PI+")","("+half_height+ " + " +feed_distance+")",0,Math.PI);
    var twire4 = new LawEdge("("+radius+" + "+plate_thickness+")","("+plate_thickness+")*u/("+Math.PI+")","("+half_height+ " + " +feed_distance+")",0,Math.PI);

    var arcx_connect = Math.cos(rotation);   //Used to scale the arclegnth of the connecting wires.
    var arcy_connect = Math.sin(rotation);   //Used to scale the arclegnth of the connecting wires.

    //Building the lower set of wires to connect to the cover plates:
    //We are using LawEdge to draw the edges of a 2D shape that will later be extruded into 3D.
    var connect1 = new LawEdge("("+radius+" + "+plate_thickness+")*cos(u)","("+radius+" + "+plate_thickness+")*sin(u)","("+half_height+ " - " +feed_distance+")",rotation,Math.PI/2)
    var connect2 = new LawEdge("("+radius+")*cos(u)","("+radius+")*sin(u)","("+half_height+ " - " +feed_distance+")",rotation,Math.PI/2);
    var connect4 = new LawEdge("0","("+radius+")+("+plate_thickness+")*u/("+Math.PI+")","("+half_height+ " - " +feed_distance+")",0,Math.PI);
    var connect3 = new LawEdge(""+arcx_connect+"*("+radius+"+("+plate_thickness+")*u/("+Math.PI+"))",""+arcy_connect+"*("+radius+"+("+plate_thickness+")*u/("+Math.PI+"))","("+half_height+ " - " +feed_distance+")",0,Math.PI);

    //Building the top set of wires to connect to the cover plates:
    var tconnect1 = new LawEdge("("+radius+" + "+plate_thickness+")*cos(u)","("+radius+" + "+plate_thickness+")*sin(u)","("+half_height+ " + " +feed_distance+")",x_rotation,rotation);
    var tconnect2 = new LawEdge("("+radius+")*cos(u)","("+radius+")*sin(u)","("+half_height+ " + " +feed_distance+")",x_rotation,rotation);
    var tconnect4 = new LawEdge(""+x_rotator+"*("+radius+"+("+plate_thickness+")*u/("+Math.PI+"))",""+y_rotator+"*("+radius+"+("+plate_thickness+")*u/("+Math.PI+"))","("+half_height+ " + " +feed_distance+")",0,Math.PI);
    var tconnect3 = new LawEdge("("+arcx_connect+")*("+radius+"+("+plate_thickness+")*u/("+Math.PI+"))","("+arcy_connect+")*("+radius+"+("+plate_thickness+")*u/("+Math.PI+"))","("+half_height+ " + " +feed_distance+")",0,Math.PI);

    //This is where we set the LawEdge lines into a shape (Sketch)
    var semicircle1 = new Sketch();
	var wire = new Sketch();
    var topwire = new Sketch();
    var connect = new Sketch();   
    var tconnect = new Sketch(); 
	
    // Add the edges to the sketches
	semicircle1.addEdges( [line1,line2, outer,inner] );
	wire.addEdges([wire1,wire2,wire3,wire4]);
	topwire.addEdges([twire1,twire2,twire3,twire4]);
    connect.addEdges([connect1,connect2,connect3,connect4]);
    tconnect.addEdges([tconnect1,tconnect2,tconnect3,tconnect4]);
	
    //Making a cover for the Sketches to give then a solid surface.
	var covsemi = new Cover(semicircle1);
    var covwire = new Cover(wire);
    var covtopwire = new Cover(topwire);
    var covconnect = new Cover(connect);
    var covtconnect = new Cover(tconnect);
	
    //Now we Extrude the Sketch (which still has a cover) in the form of (Sketch , distance to extrude , Direction). Here we are setting the CoordinateSystemDirection to (0,0,1) for the z direction. 
    var extrudesemi = new Extrude(semicircle1,antenna_height,CoordinateSystemDirection(0,0,1)); //sketch, sketch thickness to extrude, coordinates
    var extrudewire = new Extrude(wire,plate_thickness,CoordinateSystemDirection(0,0,1));
    var extrudetopwire = new Extrude(topwire,plate_thickness,CoordinateSystemDirection(0,0,1));
    var extrudeconnect = new Extrude(connect,plate_thickness,CoordinateSystemDirection(0,0,1));
    var extrudetconnect = new Extrude(tconnect,plate_thickness,CoordinateSystemDirection(0,0,1));

    //Here we are creating a Recipe to assemble multiple functions to our shapes. Cover, Extrude, and ePattern.
    var rsemi = new Recipe();
	rsemi.append( covsemi );
    rsemi.append(extrudesemi);
    rsemi.append(ePattern);

    var rwire = new Recipe();
	rwire.append( covwire );
    rwire.append(extrudewire);
    rwire.append(ePattern);
	
    var rtopwire = new Recipe();
	rtopwire.append( covtopwire );
    rtopwire.append(extrudetopwire);
    rtopwire.append(ePattern);

    var rconnect = new Recipe();
    rconnect.append( covconnect );
    rconnect.append(extrudeconnect);
    rconnect.append(ePattern);

    var rtconnect = new Recipe();
    rtconnect.append( covtconnect );
    rtconnect.append(extrudetconnect);
    rtconnect.append(ePattern);

    // Adding recipe to model
	var msemi = new Model();
	msemi.setRecipe( rsemi );

    var mwire = new Model();
	mwire.setRecipe( rwire );
	
    var mtopwire = new Model();
	mtopwire.setRecipe( rtopwire );

    var mconnect = new Model();
    mconnect.setRecipe( rconnect );

    var mtconnect = new Model();
    mtconnect.setRecipe( rtconnect );

    // Adding parts to the XF project + giving names
	var surfacesemi = App.getActiveProject().getGeometryAssembly().append(msemi);
	surfacesemi.name = "Plates"
	
    var surfacewire = App.getActiveProject().getGeometryAssembly().append(mwire);
	surfacewire.name = "Bottom Wire"
	
    var surfacetopwire = App.getActiveProject().getGeometryAssembly().append(mtopwire);
	surfacetopwire.name = "Top Wire"

    var surfaceconnect = App.getActiveProject().getGeometryAssembly().append(mconnect);
	surfaceconnect.name = "Bottom Connecting Wire"

    var surfacetconnect = App.getActiveProject().getGeometryAssembly().append(mtconnect);
	surfacetconnect.name = "Top Connecting Wire"

    //This section is where we define coordinates of the wires
    var coordst = surfacetopwire.getCoordinateSystem();
    var coords = surfacewire.getCoordinateSystem();
    coordst.rotate("0 rad", "0 rad", rotation);
    coords.rotate("0 rad", "0 rad", rotation);

    // Set the material
	var pecMaterial = App.getActiveProject().getMaterialList().getMaterial( "PEC" );
		
	App.getActiveProject().setMaterial( surfacesemi, pecMaterial );
    App.getActiveProject().setMaterial( surfacewire, pecMaterial );
    App.getActiveProject().setMaterial( surfacetopwire, pecMaterial );
    App.getActiveProject().setMaterial( surfaceconnect, pecMaterial );
    App.getActiveProject().setMaterial( surfacetconnect, pecMaterial );
}