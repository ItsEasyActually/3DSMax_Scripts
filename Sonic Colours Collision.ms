fname = GetOpenFileName caption:"Open Sonic Colours Collision" types:"Collision File(*.orc)|*.orc"
f = fopen fname "rb"   --open file in read only format
clearlistener()
fsize = GetFileSize fname
	Vert_array = #()
	Face_array = #()
	UV_Array = #()
	
fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)
	
fseek f 68#seek_set
Pointer = ReadBELong f + 60

fseek f Pointer#seek_set

VertCount = ReadLong f
FaceCount = ReadLong f

For v = 1 to VertCount Do (
	vx = ReadFloat f
	vy = ReadFloat f
	vz = ReadFloat f
	append Vert_Array[vx,vy,vz]
)

For p = 1 to FaceCount Do (
	fa = ReadShort f+1
	fb = ReadShort f+1
	fc = ReadShort f+1
	append Face_Array[fa,fb,fc]
)
append UV_Array[0,0,0]

msh = mesh vertices:Vert_array faces:Face_array --build mesh
msh.numTVerts = UV_array.count
buildTVFaces msh    
fclose f