-- USE: Drag this script into 3DS Max and it should run. If not, open the .ms file in the MaxScript Editor and Evaluate it (Ctrl+E)

fsource = GetOpenFileName \
caption:"Sonic Mania MDL Importer" \
types: "Binary Files (*.bin)|*.bin|"
clearlistener()

If fsource != undefined Do (
	f = fopen fsource "rb"
	disableSceneRedraw() -- Disables Scene from Refreshing
	
	struct ManiaMaterial (
		M_Blue,
		M_Green,
		M_Red,
		M_Alpha
	)

	struct ManiaVertex (
		vx,
		vy,
		vz
	)

	MaterialArray=#()

	MDLMagic = ReadString f	--First bit of the file is an ASCII: "MDL"

	HasVColours = ReadByte f	-- Variable for checking if Vertex Colours exist.
	PolyType = ReadByte f	-- Dictates what type of polys are used. 0x03 = Triangles, 0x04 = Quads

	VertexCount = ReadShort f#unsigned
	FrameCount = ReadShort f#unsigned	-- Animations are baked vertex animations per frame.

	If HasVColours == 5 Do (
		For ms = 1 to VertexCount Do (
			Materials=(ManiaMaterial \
				M_Blue: (ReadByte f#unsigned) \
				M_Green: (ReadByte f#unsigned) \
				M_Red: (ReadByte f#unsigned) \
				M_Alpha: (ReadByte f#unsigned) \
			)
			append MaterialArray[Materials.M_Red, Materials.M_Green, Materials.M_Blue]
		)
	) 
	If HasVColours == 1 Do (
		For ms = 1 to VertexCount Do (
			Materials=(ManiaMaterial \
				M_Blue: (255) \
				M_Green: (255) \
				M_Red: (255) \
				M_Alpha: (255) \
			)
			append MaterialArray[Materials.M_Red, Materials.M_Green, Materials.M_Blue]
		)
	)	-- Defaults Vertex Colours to white in case Vertex Colour Array does not exist

	Face_Array=#()
	-- Reading Triangle Poly Type --
	If PolyType == 3 Do (
		FaceCount = (((ReadShort f#unsigned)*2) / 6)
		For fc = 1 to FaceCount Do (
			f1 = ReadShort f#unsigned + 1
			f2 = ReadShort f#unsigned + 1
			f3 = ReadShort f#unsigned + 1
			append Face_Array[f1,f2,f3]
		)
	)
	-- Reading Quad Poly Type (Editable Mesh can not be a quad, thus conversion to triangles is needed)
	If PolyType == 4 Do (
		FaceCount = (((ReadShort f#unsigned)*2) / 8)
		For fc = 1 to FaceCount Do (
			f1 = ReadShort f#unsigned + 1
			f2 = ReadShort f#unsigned + 1
			f3 = ReadShort f#unsigned + 1
			f4 = ReadShort f#unsigned + 1
			append Face_Array[f1,f2,f3]
			append Face_Array[f1,f3,f4]
		)
	)
	
	FrameVerts=#()	-- Needed to keep the vertices in an array outside of the Vertex Reading loop.
	FrameNorms=#()	-- Same deal but this isn't as needed.
	
	-- This loop is to get every Vertex Array per frame and contain them into arrays.
	For md = 1 to FrameCount Do (
		Vert_Array=#()
		Norm_Array=#()
		For v = 1 to VertexCount Do (
			Vertices=(ManiaVertex \
				vx: (ReadFloat f) \
				vy: (ReadFloat f) \
				vz: (ReadFloat f) \
			)
			Normals=(ManiaVertex \
				vx: (ReadFloat f) \
				vy: (ReadFloat f) \
				vz: (ReadFloat f) \
			)
			append Vert_Array[Vertices.vx, Vertices.vy, Vertices.vz]
			append Norm_Array[Normals.vx, Normals.vy, Normals.vz]
		)
		append FrameVerts(Vert_Array)
		append FrameNorms(Norm_Array)
	)

	msh = mesh vertices:FrameVerts[1] faces:Face_Array	-- Creates the model
	for j = 1 to FrameVerts[1].count do setNormal msh j FrameNorms[1][j]	-- Sets normals (Is actually broken or something)
	
	-- This is all Vertex Colour Related --
	setNumCPVVerts msh msh.numTVerts	-- Sets the Number of Vertex Colour Vertices
	setCVertMode msh true		-- Sets the Coloured Vertex Mode to True
	setShadeCVerts msh true	-- Sets the Shading for Coloured Vertices to True
	defaultVCFaces msh
	for j = 1 to MaterialArray.count do setvertcolor msh j MaterialArray[j]	-- Assigns Vertex Colours to Vertices

	If FrameCount >1 Do (
		animationRange = interval 0 (FrameCount - 1)	-- Sets the animation range on the Timeline
		animateVertex msh #all	-- Allows the vertices of the model to be animated
	
		For fc = 1 to (FrameCount) Do (
			with animate on at time (fc-1) (meshOp.setVert msh msh.Verts FrameVerts[fc])	-- Sets modified vertices per frame.
		)
		with animate on at time (FrameCount) (meshOp.setVert msh msh.Verts FrameVerts[FrameCount])	--Sets final vertices for final frame (Regularly it is missed for unknown reasons)
		update msh
	)
	


	fclose f
)
enableSceneRedraw()	-- Redraws the scene, this is to speed up Import times.
actionMan.executeAction 0 "311"  -- Tools: Zoom Extents All Selected
