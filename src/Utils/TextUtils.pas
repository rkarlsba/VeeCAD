unit textutils;

interface

uses Classes;

procedure LineToStream( S : TStream; const Line : string );
function LineFromStream( S : TStream; var Line : string ) : boolean;
function NameValueFromStream( S : TStream; var Name, Value : string ) : boolean;

implementation

procedure LineToStream( S : TStream; const Line : string );
const CRLF : array[0..1] of char = #13#10;
begin
    S.WriteBuffer( PChar(Line)^, Length(Line) * sizeof(char) );
    S.WriteBuffer( CRLF, 2 * sizeof(char) );
end;


function LineFromStream( S : TStream; var Line : string ) : boolean;
var
    CH : char;
begin
    Line := '';
    result := False;
    while S.Read( CH, sizeof(char) ) = sizeof(char) do begin
        result := True;
        if CH = #13 then begin
            exit;
        end;
        if CH <> #10 then begin
            Line := Line + CH;
        end;
    end;
end;

function NameValueFromStream( S : TStream; var Name, Value : string ) : boolean;
var
    CH : char;
begin
    Name := '';
    Value := '';
    result := False;

    // Safe to parse 16 bit char-bychar, because surrogate units
    // always have the 2 high bits set to 1101 and neither surrogate char
    // can be mistaken for a single char unicode character.

    // parse first (Name) section of Name=Value pair
    while S.Read( CH, sizeof(char) ) = sizeof(char) do begin
        if CH = #13 then begin
            exit;
        end;
        // first '=' cencountered means end of Name section
        if CH = '=' then begin
            break;
        end;
        if CH <> #10 then begin
            // provided we have at least one character on the line
            result := True;
            Name := Name + CH;
        end;
    end;

    // parse second (Value) section of Name=Value pair
    while S.Read( CH, sizeof(CH) ) = sizeof(char) do begin
        if CH = #13 then begin
            exit;
        end;
        if CH <> #10 then begin
            Value := Value + CH;
        end;
    end;
end;


end.
