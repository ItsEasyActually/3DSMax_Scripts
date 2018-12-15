fsource = GetOpenFileName \
caption:"Sonic 2006 Collision Importer" \
types: "Binary Files (*.bin)|*.bin|"
clearlistener()

If fsource != undefined Do (
	fn readBEshort fstream = (bit.swapBytes (readshort fstream #unsigned) 1 2)
	fn readBElong fstream = (bit.swapBytes (bit.swapBytes (readlong fstream #unsigned) 1 4) 2 3)
	fn readBEfloat fstream = (bit.intAsFloat (bit.swapBytes (bit.swapBytes (readlong fstream #unsigned) 1 4) 2 3))
	
	f = fopen fsource "rb"
	disableSceneRedraw() -- Disables Scene from Refreshing
	
	Vert_Array=#()
	Face_Array=#()
	
	fseek f 0x30#seek_set
	
	VertCount = ReadBELong f
	
	For v = 1 to VertCount Do (
		vx = ReadBEFloat f
		vy = ReadBEFloat f
		vz = ReadBEFloat f
		append Vert_Array[vx,vy,vz]
	)
	FaceCount = ReadBELong f
	For m = 1 to FaceCount Do (
		fa = ReadBEShort f +1
		fb = ReadBEShort f +1
		fc = ReadBEShort f +1
		fseek f 6#seek_cur
		append Face_Array[fa,fb,fc]
	)
	msh = mesh vertices:Vert_array faces:Face_array
	
	fclose f
)

enableSceneRedraw()	-- Redraws the scene, this is to speed up Import times.
actionMan.executeAction 0 "311"  -- Tools: Zoom Extents All Selected