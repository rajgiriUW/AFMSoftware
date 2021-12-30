#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function setupPulse()

	Make/O/N=(500) VPulse = 0
	
	VPulse[0,100] = 1
	td_xsetoutwave(1, "Event.1", "Output.A", VPulse, 1)
	print "Pulse"

end


function Line_Trigger()

	print td_wv("Output.A", 2)
	print td_wv("Output.A", 0)
	print "Pulse Done?"

end

Function UserOutAndTrigger()

        String ErrorStr = ""
        
        wave FastWave = root:Packages:MFP3D:Main:FastWave
        Duplicate/FREE FastWave TraceWave
        Variable fastLen = numpnts(FastWave)
        Redimension/N=(fastLen + fastLen, -1) TraceWave
        Variable traceLen = numpnts(TraceWave)/4
        //Variable traceLen=numpnts(TraceWave)/2
        TraceWave = 0    // off everywhere
        // comment/edit the following 2 statements as needed
        TraceWave[,traceLen - 1] = (p >= traceLen*0.1 && p <= traceLen*0.9)  ? 0 : 0    //0V during linear trace and 0V in turnaround
        TraceWave[traceLen,2*traceLen - 1] = (p >= traceLen*1.1 && p <= traceLen*1.9)  ? 0 : 0        // 0V during linear part of retrace and 0V in turnaround
        TraceWave[2*traceLen, 3*traceLen - 1] = (p >= traceLen*2.1 && p <= traceLen*2.9)  ? 0 : 0    // Nap Pass 0V during linear trace and 0V in turnaround
        TraceWave[3*traceLen,] = (p >= traceLen*3.1 && p <= traceLen*3.9)  ? 1.8:0       //Nap pass 1.8V during linear part of retrace and 0V in turnaround        
        
        //TraceWave[,traceLen - 1] = (p >= traceLen*0.1 && p <= traceLen*0.9)  ? 3.3 : 0    //0V during linear trace and 0V in turnaround
        //TraceWave[traceLen,] = (p >= traceLen*1.1 && p <= traceLen*1.9)  ? 3.3 : 0        // 3.3V during linear part of retrace and 0V in turnaround
        errorStr += IR_xSetOutWave(0,cScanOutWaveEvent+","+cScanKeepGoingEvent,"Output.A",TraceWave,td_RS("OutWave0StatusCallback"),GV("Decimation"))    //set up the fast wave
        
        ARReportError(ErrorStr)

End

function KPFM_lim()

        string errorStr = ""

        errorStr += ir_WriteValue("PIDSLoop.3.OutputMin",GV("NapTipVoltage")) //Pins the tip voltage feedback at a single
        errorStr += ir_WriteValue("PIDSLoop.3.OutputMax",GV("NapTipVoltage")) // value 

end 