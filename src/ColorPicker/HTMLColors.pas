unit HTMLColors;

interface

{$I mxs.inc}

uses
 SysUtils, Windows, Graphics;

function ColorToHex(Color: TColor): string;
function GetWebSafe(C: TColor): TColor;

implementation

//------------------------------------------------------------------------------

//converts a TColor value to a hex value
function ColorToHex(Color: TColor): string;
begin
 if Color <> $0 then
  Result := IntToHex(GetRValue(Color), 2) + IntToHex(GetGValue(Color), 2) + IntToHex(GetBValue(Color), 2)
 else
  Result := '000000';
end;

//------------------------------------------------------------------------------


//returns the closest web safe color to the one given
function GetWebSafe(C: TColor): TColor;
begin
  result := C;
 //Result := RGB(WS[GetRValue(C)], WS[GetGValue(C)], WS[GetBValue(C)]);
end;

//------------------------------------------------------------------------------


end.
