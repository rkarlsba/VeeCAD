unit NetReaderUltiCap;

interface

uses NetReader, Classes;

// Low level access to UltiCap Netlist files.

type TUlticapDOSNetReader = class( TveNetReader )

protected
    ComponentFileName : string;
    ComponentLines : TStringList;
    ComponentLineIndex : integer;
    ComponentLineLimit : integer;

    CurrentNet : string;
    HaveNet : boolean;
    NetCsvIndex : integer;
    function GetNetlistDescriptor : string; override;
{
    procedure ParseNetLine(
        LineIndex : integer; const Line : string;
        var Designator : string; var PinNo : Integer ); virtual;
}
public
    procedure ReadFile( const FileName : string ); override;
    function CheckCompatibility : boolean; override;

    procedure ToFirstComponent; override;
    function GetNextComponent( var Designator, Value, Outline : string ) : boolean;
        override;
    procedure ToFirstConnection; override;
    function GetNextConnection( var NetName, Designator, PinName : string )
        : boolean; override;

    constructor Create; override;
    destructor Destroy; override;
end;


type TUlticapWinNetReader = class( TUlticapDOSNetReader )

protected
    function GetNetlistDescriptor : string; override;
end;


implementation

uses SysUtils, ParseCsv;

constructor TUlticapDOSNetReader.Create;
begin
    inherited;
    ComponentLines := TStringList.Create;
end;

destructor TUlticapDOSNetReader.Destroy;
begin
    ComponentLines.Free;
    inherited;
end;

procedure TUlticapDOSNetReader.ReadFile( const FileName : string );
begin
    // load netlist
    Lines.LoadFromFile( FileName );
    LineLimit := Lines.Count;

    // now load accompanying component file
    ComponentFileName := ChangeFileExt( FileName, '.cmp' );
    ComponentLines.LoadFromFile( ComponentFileName );
    ComponentLineLimit := ComponentLines.Count;
end;


function TUlticapDOSNetReader.GetNetlistDescriptor : string;
begin
    result := 'UltiCap_DOS';
end;

{
procedure TUlticapNetReader.ParseNetLine(
    LineIndex : integer; const Line : string;
    var Designator : string; var PinNo : Integer );
begin
end;
}

function TUlticapDOSNetReader.CheckCompatibility : boolean;
begin
    result := True;
end;

procedure TUlticapDOSNetReader.ToFirstComponent;
begin
    ComponentLineIndex := 0;
    HaveNet := False;
end;

{
* VERSION 4 80
C1, 47NF, CK05, 1080, 4980, 270.00, 2, 1080, 4860, 1080, 5100;
D1, GREEN, LED5MM, 660, 4980, 270.00, 2, 660, 4860, 660, 4980;
}

function TUlticapDOSNetReader.GetNextComponent( var Designator, Value, Outline : string ) : boolean;
var
    ComponentLine : string;
    c : char;
    Index : integer;
begin

    // search for next component
    while ComponentLineIndex < ComponentLineLimit do begin

        ComponentLine := ComponentLines[ComponentLineIndex];

        if Length(ComponentLine) < 1 then begin
            Inc( ComponentLineIndex );
            continue;
        end;

        // skip comment lines or EOF character
        c := ComponentLine[1];
        if ( c = '*' ) or ( c = ' ' ) or ( c = #$1A ) then begin
            Inc( ComponentLineIndex );
            continue;
        end;

        // parse line into Designator, Value, Outline
        Index := 0;

        if not ParseCsvValue( ComponentLine, Designator, Index ) then begin
           raise ETveNetReader.CreateFmt(
            'Missing component Designator on CMP file line %d', [ComponentLineIndex + 1] );
        end;

        if not ParseCsvValue( ComponentLine, Value, Index ) then begin
           raise ETveNetReader.CreateFmt(
            'Missing component Value on CMP file line %d', [ComponentLineIndex + 1] );
        end;

        if not ParseCsvValue( ComponentLine, Outline, Index ) then begin
           raise ETveNetReader.CreateFmt(
            'Missing component Outline on CMP file line %d', [ComponentLineIndex + 1] );
        end;

        //
        Inc( ComponentLineIndex );
        result := True;
        exit;
    end;

    // no component loaded - at end of file
    result := False;
end;


function DeComma( const S : string ) : string;
var
    i : integer;
begin
    result := S;
    for i := 1 to Length(S) do begin
        if result[i] = ',' then begin
            result[i] := '_';
        end;
    end;
end;

(*
A Net line is of form "U1-14" ie pin 14 of U1 is assigned to current net.
A component name can also include a '-', e.g. "U1--14" means pin 14 of U1- ,
so have to scan from the right when looking for separator '-'.
*)

procedure ParsePinToNetText( const Text : string; LineIndex : integer;
        var Designator, PinName : string );
var
    found : boolean;
    i : integer;
    PinNoString : string;
begin
    // scan from right until '-' found
    found := False;
    i := Length( Text );
    while i > 0 do begin
        if Text[i] = '-' then begin     // Protel
//        if Line[i] = ',' then begin   // Tango
            found := True;
            break;
        end;
        dec( i );
    end;

    if not Found then begin
        raise ETveNetReader.CreateFmt(
        'Missing "-" in Pin to Net assignment on line %d',
        [LineIndex + 1]
        );
    end;

    Designator := Trim(DeComma(Copy( Text, 1, i-1 )));
    PinNoString := Trim(Copy( Text, i+1, 255 ));

    // blank pin name not allowed
    if PinNoString = '' then begin
        raise ETveNetReader.CreateFmt(
        'Blank pin name in Pin to Net assignment on line %d',
        [LineIndex + 1] );
    end;

    PinName := PinNoString;
end;

procedure TUlticapDOSNetReader.ToFirstConnection;
begin
    ComponentLineIndex := 0;
end;

{
* GND
T1-3,             IC1-2,            R6-2,             R7-1,
J1-5,             C1-1,

* +5V
J1-3,             R2-1,             IC1-7,            R4-1,
C1-2,
}

function TUlticapDOSNetReader.GetNextConnection(
    var NetName, Designator, PinName : string ) : boolean;

    procedure ToNextNet;
    begin
        while LineIndex < LineLimit do begin

            // find opening '*' of net definition group of lines
            Line := Trim(Lines[LineIndex]);

            if (Length(Line) > 1) and (Line[1] = '*') then begin

                CurrentNet := Trim( Copy( Line, 2, 20 ));
                if CurrentNet = '' then begin
                    raise ETveNetReader.CreateFmt(
                    'Invalid Net definition on line %d',  [LineIndex + 1]
                    );
                end;

                // successfully entered new net
                Inc( LineIndex );
                HaveNet := True;
                exit;
            end;
            inc( LineIndex );
        end;

        // fell through loop and did not find net : leave HaveNet = False;
//      HaveNet := False;
    end;

var
    Value : string;


begin
    while LineIndex < LineLimit do begin

        // must be inside a net definition
        if not HaveNet then begin
            ToNextNet;

            // no net definition found
            if not HaveNet then begin
                result := False;
                exit;
            end;

            NetCsvIndex := 0;
            Line := Lines[LineIndex];
        end;

        // look for next


        // read lines until a blank line is found
        while true do begin

            // read next Pin assignment from this line
            if ParseCsvValue( Line, Value, NetCsvIndex ) then begin
                Value := Trim(Value);
                if Value <> '' then begin
                    // should have a value like "R1-2" which identifies a component and pin No
                    ParsePinToNetText( Value, LineIndex, Designator, PinName );
                    NetName := CurrentNet;
                    result := True;
                    exit;
                end
            end;

            // no pin assignment found, so we need a new line
            // any more lines left?
            if LineIndex >= LineLimit then begin
                HaveNet := False;
                result := False;
                exit;
            end;

            // get next line
            Inc( LineIndex );
            Line := Lines[LineIndex];
            NetCsvIndex := 0;

            // a blank line means end of net
            if Line = '' then begin
                HaveNet := False;
                break;
            end;
        end;
    end;

    // fell through loop - end of netlist file
    result := False;
end;


function TUlticapWinNetReader.GetNetlistDescriptor : string;
begin
    result := 'UltiCap_Win';
end;

end.
