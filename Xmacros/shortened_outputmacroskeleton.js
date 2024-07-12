var start = gen * NPOP + 1;
var end = start + NPOP - 1;

for (var k = start; k <= end; k++){
    // if var simNum doesn't exist, create it
    var simNum = k;
    var simlength = k.toString().length;
    
    var totchars = 6;
    var init = "";
    for (var i = 0; i < totchars - simlength; i++){
        init = init + "0";
    }
    var simNum = init + simNum;
    Output.println("simNum is");
    Output.println(simNum);
    var query = new ResultQuery();
    ///////////////////////Get Theta and Phi Gain///////////////
    query.projectId = App.getActiveProject().getProjectDirectory();

    Output.println( App.getActiveProject().getProjectDirectory() );

    query.runId = "Run0001";
    query.simulationId = simNum;
    query.sensorType = ResultQuery.FarZoneSensor;
    query.sensorId = "Far Zone Sensor";
    query.timeDependence = ResultQuery.SteadyState;
    query.resultType = ResultQuery.RealizedGain; // Toggle ideal + realized gain here
    query.fieldScatter = ResultQuery.TotalField;
    query.resultComponent = ResultQuery.Theta;
    query.dataTransform = ResultQuery.NoTransform;
    query.complexPart = ResultQuery.NotComplex;
    query.surfaceInterpolationResolution = ResultQuery.NoInterpolation;
    query.setDimensionRange( "Frequency", 0, -1 );
    query.setDimensionRange( "Theta", 0, -1 );
    query.setDimensionRange( "Phi", 0, -1 );

    var thdata = new ResultDataSet( "" );
    thdata.setQuery( query );
    if( !thdata.isValid() ){
        Output.println( "1getCurrentDataSet() : " +
        thdata.getReasonWhyInvalid() );
    }

    query.resultComponent = ResultQuery.Phi;
    var phdata = new ResultDataSet("");
    phdata.setQuery(query);

    if( !phdata.isValid() ){
        Output.println( "2getCurrentDataSet() : " +
        phdata.getReasonWhyInvalid() );
    }
    /////////////////Get Theta and Phi Phase///////////////////////////////////

    query.resultType = ResultQuery.E;
    query.fieldScatter = ResultQuery.TotalField;
    query.resultComponent = ResultQuery.Theta;
    query.dataTransform = ResultQuery.NoTransform;
    query.complexPart = ResultQuery.Phase;
    query.surfaceInterpolationResolution = ResultQuery.NoInterpolation;
    query.setDimensionRange( "Frequency", 0, -1 );
    query.setDimensionRange( "Theta", 0, -1 );
    query.setDimensionRange( "Phi", 0, -1 );


    var thphase = new ResultDataSet("");
    thphase.setQuery(query);

    if( !thphase.isValid() ){
        Output.println( "3getCurrentDataSet() : " +
        thphase.getReasonWhyInvalid() );
    }

    query.resultComponent = ResultQuery.Phi;
    query.ComplexPart = ResultQuery.Phase;
    var phphase = new ResultDataSet("");
    phphase.setQuery(query);

    if( !phphase.isValid() ){
        Output.println( "4getCurrentDataSet() : " +
        phphase.getReasonWhyInvalid() );
    }

    /////////////////Get Input Power///////////////////////////
    query.sensorType = ResultQuery.System;
    query.sensorId = "System";
    query.timeDependence = ResultQuery.SteadyState;
    query.resultType = ResultQuery.NetInputPower;
    query.fieldScatter = ResultQuery.NoFieldScatter;
    query.resultComponent = ResultQuery.Scalar;
    query.dataTransform = ResultQuery.NoTransform;
    query.complexPart = ResultQuery.NotComplex;
    query.surfaceInterpolationResolution = ResultQuery.NoInterpolation;
    query.clearDimensions();
    query.setDimensionRange("Frequency",0,-1);

    var inputpower = new ResultDataSet("");
    inputpower.setQuery(query);
    if( !inputpower.isValid() ){
        Output.println( "5getCurrentDataSet() : " +
        inputpower.getReasonWhyInvalid() );
    }
    for (var i = 1; i <= 60; i++){
        var ind_num = k - (gen * NPOP);
        var file = RunDir + "/uan_files/" + gen + "_uan_files/" + ind_num + "/";
        file = file + gen + "_" + ind_num + "_";
        file = file + (i) + ".uan";
        Output.println(file);
        Output.println("thdata: " + thdata );
        Output.println("thphase: " + thphase);
        Output.println("phdata: " + phdata);
        Output.println("phphase: " + phphase);
        Output.println("inputpower: " + inputpower);
        Output.println("i: " + i);
        FarZoneUtils.exportToUANFile(thdata,thphase,phdata,phphase,inputpower,file, i-1);
    }
}
App.quit();