unit RGBCIEUtils;

interface

uses
 SysUtils, Windows, Graphics, Math;

const

 // Observer= 2°, Illuminant= D50
 ref_X =  96.422;
 ref_Z = 82.521;


type
 xyz = record
  x: real;
  y: real;
  z: real;
 end;


function RGBToXYZ(c: TColor): xyz;
procedure RGBToLab(clr: TColor; var l, a, b: real);
procedure XYZToLab(space: xyz; var l, a, b: real);
 procedure LabToLCH(l, a, b: real; var lum, c, h: real);
procedure RGBToLCH(clr: TColor; var l, c, h: real);
function GetCIEXValue(c: TColor): real;
function GetCIEYValue(c: TColor): real;
function GetCIEZValue(c: TColor): real;
function GetCIELValue(c: TColor): real;
function GetCIEAValue(c: TColor): real;
function GetCIEBValue(c: TColor): real;
function GetCIECValue(c: TColor): real;
function GetCIEHValue(c: TColor): real;

implementation


function RGBToXYZ(c: TColor): xyz;
var
 r, g, b: real;
begin
 r := GetRValue(c)/255;
 g := GetGValue(c)/255;
 b := GetBValue(c)/255;
 if r > 0.04045 then
  r := Power((r + 0.055)/1.055, 2.4)
 else
  r := r/12.92;
 if g > 0.04045 then
  g := Power((g + 0.055)/1.055, 2.4)
 else
  g := g/12.92;
 if b > 0.04045 then
  b := Power((b + 0.055)/1.055, 2.4)
 else
  b := b/12.92;
 r := r * 100;
 g := g * 100;
 b := b * 100;
 // Observer= 2°, Illuminant= D65
 Result.x := r * 0.4124 + g * 0.3576 + b * 0.1805;
 Result.y := r * 0.2126 + g * 0.7152 + b * 0.0722;
 Result.z := r * 0.0193 + g * 0.1192 + b * 0.9505;
end;

procedure XYZToLab(space: xyz; var l, a, b: real);
var
x, y, z: real;
begin
 x := space.x/ref_X;
 y := space.y/100;
 z := space.z/ref_Z;
 if x > 0.008856 then
  x := Power(x, 1/3)
 else
  x := (7.787*x) + 0.138;
 if y > 0.008856 then
  y := Power(y, 1/3)
 else
  y := (7.787*y) + 0.138;
 if z > 0.008856 then
  z := Power(z, 1/3)
 else
  z := (7.787*z) + 0.138;
 l := (116*y) - 16;
 a := 500 * (x - y);
 b := 200 * (y - z);
 if l > 100 then l := 100;
 if l < 0 then l := 0;
 if a < -128 then a := -128;
 if a > 127 then a := 127;
 if b < -128 then b := -128;
 if b > 127 then b := 127;
end;

procedure RGBToLab(clr: TColor; var l, a, b: real);
var
 s: xyz;
begin
 s := RGBToXYZ(clr);
 XYZToLab(s, l, a, b);
end;

procedure LabToLCH(l, a, b: real; var lum, c, h: real);
begin
 h := ArcTan2(b, a);
 if h > 0 then
  h := (h/PI) * 180
 else
  h := 360 - (ABS(h)/PI) * 180;
 lum := l;
 c := SQRT(a*a + b*b);
end;

procedure RGBToLCH(clr: TColor; var l, c, h: real);
var
 a, b: real;
begin
 RGBToLab(clr, l, a, b);
 LabToLCH(l, a, b, l, c, h);
end;

function GetCIEXValue(c: TColor): real;
var
 d: xyz;
begin
 d := RGBToXYZ(c);
 Result := d.x;
end;

function GetCIEYValue(c: TColor): real;
var
 d: xyz;
begin
 d := RGBToXYZ(c);
 Result := d.y;
end;

function GetCIEZValue(c: TColor): real;
var
 d: xyz;
begin
 d := RGBToXYZ(c);
 Result := d.z;
end;

function GetCIELValue(c: TColor): real;
var
 d: real;
begin
 XYZToLab(RGBToXYZ(c), Result, d, d);
end;

function GetCIEAValue(c: TColor): real;
var
 d: real;
begin
 XYZToLab(RGBToXYZ(c), d, Result, d);
end;

function GetCIEBValue(c: TColor): real;
var
 d: real;
begin
 XYZToLab(RGBToXYZ(c), d, d, Result);
end;

function GetCIECValue(c: TColor): real;
var
 d: real;
begin
 RGBToLCH(c, d, Result, d);
end;

function GetCIEHValue(c: TColor): real;
var
 d: real;
begin
 RGBToLCH(c, d, d, Result);
end;

end.

