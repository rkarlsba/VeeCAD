unit PalUtils;

interface

uses
 Windows, SysUtils, Classes, Graphics, RGBHSVUtils, RGBHSLUtils, RGBCIEUtils, RGBCMYKUtils,
 HTMLColors;

const
 clCustom = $2FFFFFFF;
 clTransparent = $3FFFFFFF;

//replaces passed strings with passed value
function ReplaceFlags(s: string; flags: array of string; value: integer): string;
//replaces the appropriate tags with values in a hint format string
function FormatHint(fmt: string; c: TColor): string;

implementation

function ReplaceFlags(s: string; flags: array of string; value: integer): string;
var
  i, p: integer;
  v: string;
begin
  Result := s;
  v := IntToStr(value);
  for i := 0 to Length(flags) - 1 do
  begin
    p := Pos(flags[i], Result);
    if p > 0 then
    begin
      Delete(Result, p, Length(flags[i]));
      Insert(v, Result, p);
    end;
  end;
end;

function AnsiReplaceText(const AText, AFromText, AToText: string): string;
begin
  Result := StringReplace(AText, AFromText, AToText, [rfReplaceAll, rfIgnoreCase]);
end;

function FormatHint(fmt: string; c: TColor): string;
var
 h: string;
begin
 h := AnsiReplaceText(fmt, '%hex', ColorToHex(c));
 h := AnsiReplaceText(h, '%cieL', IntToStr(Round(GetCIElValue(c))));
 h := AnsiReplaceText(h, '%cieA', IntToStr(Round(GetCIEaValue(c))));
 h := AnsiReplaceText(h, '%cieB', IntToStr(Round(GetCIEbValue(c))));
 h := AnsiReplaceText(h, '%cieX', IntToStr(Round(GetCIExValue(c))));
 h := AnsiReplaceText(h, '%cieY', IntToStr(Round(GetCIEyValue(c))));
 h := AnsiReplaceText(h, '%cieZ', IntToStr(Round(GetCIEzValue(c))));
 h := AnsiReplaceText(h, '%cieC', IntToStr(Round(GetCIEcValue(c))));
 h := AnsiReplaceText(h, '%cieH', IntToStr(Round(GetCIEhValue(c))));
 h := AnsiReplaceText(h, '%hslH', IntToStr(RGBHSLUtils.GetHValue(c)));
 h := AnsiReplaceText(h, '%hslS', IntToStr(RGBHSLUtils.GetSValue(c)));
 h := AnsiReplaceText(h, '%hslL', IntToStr(RGBHSLUtils.GetLValue(c)));
 h := AnsiReplaceText(h, '%hsvH', IntToStr(RGBHSVUtils.GetHValue(c)));
 h := AnsiReplaceText(h, '%hsvS', IntToStr(RGBHSVUtils.GetSValue(c)));
 h := AnsiReplaceText(h, '%hsvV', IntToStr(RGBHSVUtils.GetVValue(c)));
 h := AnsiReplaceText(h, '%r', IntToStr(GetRValue(c)));
 h := AnsiReplaceText(h, '%g', IntToStr(GetGValue(c)));
 h := AnsiReplaceText(h, '%b', IntToStr(GetBValue(c)));
 h := AnsiReplaceText(h, '%c', IntToStr(GetCValue(c)));
 h := AnsiReplaceText(h, '%m', IntToStr(GetMValue(c)));
 h := AnsiReplaceText(h, '%y', IntToStr(GetYValue(c)));
 h := AnsiReplaceText(h, '%k', IntToStr(GetKValue(c)));
 h := AnsiReplaceText(h, '%h', IntToStr(RGBHSLUtils.GetHValue(c)));
 h := AnsiReplaceText(h, '%s', IntToStr(RGBHSLUtils.GetSValue(c)));
 h := AnsiReplaceText(h, '%l', IntToStr(RGBHSLUtils.GetLValue(c)));
 h := AnsiReplaceText(h, '%v', IntToStr(RGBHSVUtils.GetVValue(c)));
 Result := h;
end;

end.
