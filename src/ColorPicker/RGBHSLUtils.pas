unit RGBHSLUtils;

interface

uses
 Windows, Graphics, Math, Scanlines;

var //set these variables to your needs, e.g. 360, 255, 255
 MaxHue: integer = 239;
 MaxSat: integer = 240;
 MaxLum: integer = 240;

procedure RGBtoHSLRange (RGB: TColor; var H1, S1, L1 : integer);
function GetHValue(AColor: TColor): integer;
function GetSValue(AColor: TColor): integer;
function GetLValue(AColor: TColor): integer;

implementation



procedure RGBtoHSLRange(RGB: TColor; var H1, S1, L1 : integer);
var
  R, G, B, D, Cmax, Cmin, h, s, l: double;
begin
// H := h1;
//  S := s1;
// L := l1;
 R := GetRValue (RGB) / 255;
 G := GetGValue (RGB) / 255;
 B := GetBValue (RGB) / 255;
 Cmax := Max (R, Max (G, B));
 Cmin := Min (R, Min (G, B));
 L := (Cmax + Cmin) / 2;
 if Cmax = Cmin then
  begin
   H := 0;
   S := 0;
  end
 else
  begin
   D := Cmax - Cmin;
   //calc L
   if L < 0.5 then
    S := D / (Cmax + Cmin)
   else
    S := D / (2 - Cmax - Cmin);
   //calc H
   if R = Cmax then
    H := (G - B) / D
   else
    if G = Cmax then
     H  := 2 + (B - R) /D
    else
     H := 4 + (R - G) / D;
   H := H / 6;
   if H < 0 then
    H := H + 1;
  end;
 H1 := round (H * MaxHue);
 S1 := round (S * MaxSat);
 L1 := round (L * MaxLum);
end;

function GetHValue(AColor: TColor): integer;
var
 d, h: integer;
begin
 RGBToHSLRange(AColor, h, d, d);
 Result := h;
end;

function GetSValue(AColor: TColor): integer;
var
 d, s: integer;
begin
 RGBToHSLRange(AColor, d, s, d);
 Result := s;
end;

function GetLValue(AColor: TColor): integer;
var
 d, l: integer;
begin
 RGBToHSLRange(AColor, d, d, l);
 Result := l;
end;

end.
