unit RGBCMYKUtils;

interface

uses
 Windows, Graphics, Math;

procedure ColorToCMYK(clr: TColor; var C, M, Y, K: integer);
function GetCValue(c: TColor): integer;
function GetMValue(c: TColor): integer;
function GetYValue(c: TColor): integer;
function GetKValue(c: TColor): integer;

implementation


procedure ColorToCMYK(clr: TColor; var C, M, Y, K: integer);
begin
 C := 255 - GetRValue(clr);
 M := 255 - GetGValue(clr);
 Y := 255 - GetBValue(clr);
 K := MinIntValue([C, M, Y]);
 C := C - K;
 M := M - K;
 Y := Y - K;
end;

function GetCValue(c: TColor): integer;
var
 d: integer;
begin
 ColorToCMYK(c, Result, d, d, d);
end;

function GetMValue(c: TColor): integer;
var
 d: integer;
begin
 ColorToCMYK(c, d, Result, d, d);
end;

function GetYValue(c: TColor): integer;
var
 d: integer;
begin
 ColorToCMYK(c, d, d, Result, d);
end;

function GetKValue(c: TColor): integer;
var
 d: integer;
begin
 ColorToCMYK(c, d, d, d, Result);
end;

end.
