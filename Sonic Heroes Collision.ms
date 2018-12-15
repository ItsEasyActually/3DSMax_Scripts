fname = GetOpenFileName caption:"MKDD Collision" types:"Collision File(*.cl)|*.cl"
f = fopen fname "rb"   --open file in read only format
clearlistener()

fn floatSwap2 f = (
	i = bit.floatAsInt f
	h = bit.intashex i
	while h.count < 8 do h = "0" + h
	
	s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
	bit.intAsFloat (bit.hexasint s)
)	

fn readBEshort fstream = (
	short = readshort fstream #unsigned
	short = bit.swapBytes short 1 2
	return short
)

 fn ReadBEHalfFloat Fstream = (
  local BH  = readByte Fstream #unsigned
  local BL  = readByte Fstream #unsigned
  local N = BH*256 + BL
  local S = floor((mod N 65536) / 32768)
  local Ef = floor((mod N 32768) / 1024)
  local M = mod N 1024
  if (Ef==0)AND(M==0) then return ( (-1.0)^S * 0.0 )
  if (Ef==0)AND(M!=0) then return ( (-1.0)^S * 2.0^-14 * (M / 2.0^10) )
  if (Ef>0)AND(Ef<31) then return ( (-1.0)^S * 2.0^(Ef-15) * (1 + M/2.0^10) )
  if (Ef==31)AND(M==0) then return ( (-1.0)^S * 1/0.0 )
  if (Ef==31)AND(M!=0) then return 0	--hack-- should be #inf   
 )--end fn ReadBEHalfFloat

fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)

fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
)

Vert_Array=#()
UV_Array=#()
Face_Array=#()

Fsize = ReadBELong f
FaceOffset = ReadBELong f
UnkOffset = ReadBELong f
VertOffset = ReadBELong f
fseek f 0x12#seek_cur
FaceTotal = ReadBEShort f /3
VertTotal = ReadBEShort f

fseek f VertOffset#seek_set
For v = 1 to VertTotal Do (
	vx = ReadBEFloat f
	vy = ReadBEFloat f
	vz = ReadBEFloat f
	append Vert_Array[vx,vy,vz]
)

fseek f FaceOffset#seek_set
For b = 1 to FaceTotal Do (
	fa = ReadBEShort f +1
	fseek f 0x1E#seek_cur
	fb = ReadBEShort f +1
	fseek f 0x1E#seek_cur
	fc = ReadBEShort f +1
	fseek f 0x1E#seek_cur
	append Face_Array[fa,fb,fc]
)

append UV_Array[0,0,0]

msh = mesh vertices:Vert_array faces:Face_array
msh.numTVerts = UV_array.count
buildTVFaces msh

fclose f