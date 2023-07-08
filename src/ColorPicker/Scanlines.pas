unit Scanlines;

interface

uses
 Windows, Graphics;

 type
 TRGBTripleArray = array [0..65535] of TRGBTriple;
 pRGBTripleArray = ^TRGBTripleArray;
 TRGBQuadArray = array [0..65535] of TRGBQuad;
 pRGBQuadArray = ^TRGBQuadArray;

function RGBtoRGBQuad(R, G, B: byte): TRGBQuad; overload;
function RGBToRGBQuad(c: TColor): TRGBQuad; overload;

implementation


function RGBtoRGBQuad(R, G, B: byte): TRGBQuad; overload;
begin
 with Result do
  begin
   rgbRed := R;
   rgbGreen := G;
   rgbBlue := B;
   rgbReserved := 0;
  end
end;

function RGBToRGBQuad(c: TColor): TRGBQuad; overload;
begin
 with Result do
  begin
   rgbRed := GetRValue(c);
   rgbGreen := GetGValue(c);
   rgbBlue := GetBValue(c);
   rgbReserved := 0
  end;
end;


end.
 