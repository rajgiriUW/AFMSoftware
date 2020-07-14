#pragma rtGlobals=3		// Use modern global access method and strict wave access.




Function laserspots()

InitShutter()
print "Shutter Initialized"
//open shutter
SetShutterAngle("20")
		
	MoveXY(-3,3) 
	sleep/s 1566
	print "Dose 1 complete"
	
	MoveXY(3,3)
	sleep/s 2611
	print "Dose 2 complete"
	
	MoveXY(-3,-3)
	sleep/s 7834
	print "Dose 3 complete"
	
	MoveXY(3,-3) 
	sleep/s 26114
	print "Dose 4 complete"
	
	
//	MoveXY(0,0) 
//	sleep/s 2382
//	print "Dose 5 complete"
//	
//	MoveXY(10,0) 
//	sleep/s 3574
//	print "Dose 6 complete"
//	
//	MoveXY(-10,-10) 
//	sleep/s 5957
//	print "Dose 7 complete"
//	
//	MoveXY(0,-10) 
//	sleep/s 9532
//	print "Dose 8 complete"
//	
//	MoveXY(10,-10) 
//	sleep/s 14297
//	print "Dose 9 complete"
	
//close shutter	
SetShutterAngle("160")

print "Sutter closed, Degradation series complete"
End
	


