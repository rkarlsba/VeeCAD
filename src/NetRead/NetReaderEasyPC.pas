unit NetReaderEasyPC;


interface

uses NetReader;

// Low level access to Protel Netlist files.

type TEasyPCNetReader = class( TveNetReader )

protected
    CurrentNet : string;
    HaveNet : boolean;
    function GetNetlistDescriptor : string; override;

public
    function CheckCompatibility : boolean; override;

    procedure ToFirstComponent; override;
    function GetNextComponent( var Designator, Value, Outline : string ) : boolean;
        override;
    procedure ToFirstConnection; override;
    function GetNextConnection( var NetName, Designator, PinName : string )
        : boolean; override;

//    constructor Create; virtual;
//    destructor Destroy; override;
end;

implementation

uses SysUtils, ExceptSafe;

type ESafeEasyPCReader = class( ESafe );

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
A Net line is of form "U1.8" ie pin 8 of U1 is assigned to current net.
A component name can also include a '.', e.g. "U.1.14" means pin 14 of U.1,
so have to scan from the right when looking for separator '.'.
*)

procedure ParseNetLine(
    LineIndex : integer;
    const Line : string; var Designator, PinName : string );
var
    found : boolean;
    i : integer;
begin
    // scan from right until '.' found
    found := False;
    i := Length( Line );
    while i > 0 do begin
        if Line[i] = '.' then begin
            found := True;
            break;
        end;
        dec( i );
    end;

    if not Found then begin
        raise  ESafeEasyPCReader.CreateFmt(
        'Missing "." in Pin to Net assignment on line %d',
        [LineIndex + 1]
        );
    end;

    Designator := DeComma(Copy( Line, 1, i-1 ));
    PinName := Trim(Copy( Line, i+1, 255 ));
    if PinName = '' then begin

        raise ESafeEasyPCReader.CreateFmt(
        'Blank pin name in Pin to Net assignment on line %d',
        [LineIndex + 1]
        );
    end;
end;

// function parses quote " enclosed values
// Call with index at starting point : returns Value = text within ".." pair
// moves index to next char beyond second " character.
// Returns True means Value holds new data
// Returns False means Value undefined - no more values to parse

function ParseQuotedValue( const InputString : string; var Value : string;
    var Index : integer ) : boolean;
var
    Len : integer;
    i : integer;
    start : integer;
begin
    Len := Length( InputString );

    // if CSVString consumed
    if (Index > Len) or (Len = 0) then begin
        result := False;
        exit;
    end;

    // move i just past next "
    i := index;
    while i < Len do begin
        if InputString[i] = '"' then begin
            inc( i );
            break;
        end;
        inc( i );
    end;

    // move to next (terminating) "
    start := i;
    while i < Len do begin
        if InputString[i] = '"' then begin
            break;
        end;
        inc( i );
    end;

    Value := Copy( InputString, start, i - start );
    Index := i + 1;
    result := True;
end;




function TEasyPCNetReader.GetNetlistDescriptor : string;
begin
    result := 'Easy-PC Generic';
end;

function TEasyPCNetReader.CheckCompatibility : boolean;
begin
    result := True;
end;


procedure TEasyPCNetReader.ToFirstComponent;
begin
    LineIndex := 0;
end;

function TEasyPCNetReader.GetNextComponent( var Designator, Value, Outline : string ) : boolean;

    procedure LoadComponent;
    var
        i : integer;
        Limit : integer;
    begin
        // current line has 3 sections like this:
        // U11 "74LS244" "SOL20"

        Limit := Length(Line);

        // First section is Designator
        i := 1;
        while i <= Limit do begin
            if Line[i] = ' ' then begin
                break;
            end;
            inc( i );
        end;

        if i < 2 then begin
            raise ESafeEasyPCReader.CreateFmt(
            'Designator too short on line %d', [LineIndex] )
        end;
        Designator := Copy( Line, 1, i-1 );

        // Next section is Value in "quotes"
        if not ParseQuotedValue( Line, Value, i ) then begin
            raise ESafeEasyPCReader.CreateFmt(
            'Missing Value field on line %d', [LineIndex +1] )
        end;

        // Next section is Outline in "quotes"
        if not ParseQuotedValue( Line, Outline, i ) then begin
            raise ESafeEasyPCReader.CreateFmt(
            'Missing Outline field on line %d', [LineIndex +1] )
        end;
    end;
            

begin
    // search for next component
    while LineIndex < LineLimit do begin

        Line := Trim( Lines[LineIndex] );

        // skip blank lines
        if Line = '' then begin
            Inc( LineIndex );
            continue;
        end;

        // if reached net section, then finished : "Net " signals a net section line
        if Pos( 'Net ', Line ) = 1 then begin
            result := False;
            exit;
        end;

        // line defines a component
        LoadComponent;
        Inc( LineIndex );
        result := True;
        exit;
    end;

    // no component loaded - at end of file
    result := False;
end;

procedure TEasyPCNetReader.ToFirstConnection;
begin
    LineIndex := 0;
    HaveNet := False;
end;

function TEasyPCNetReader.GetNextConnection( var NetName, Designator, PinName : string )
    : boolean;

    procedure ToNextNet;
    var
        i : integer;
    begin
        while LineIndex < LineLimit do begin

            // find opening 'Net ' of net definition group of lines
            Line := Lines[LineIndex];
            if Pos( 'Net ', Line ) = 1 then begin

                 // Next section is Value in "quotes"
                i := 5;
                if not ParseQuotedValue( Line, CurrentNet, i ) then begin
                    raise ESafeEasyPCReader.CreateFmt(
                    'Missing net name on line %d', [LineIndex] )
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
        end;

        // read line
        Line := Trim( Lines[ LineIndex ] );

        // find end of net definition
        if Line = '' then begin
            HaveNet := False;
            Inc( LineIndex );
            continue;
        end;

        // find pin to net assignment , eg line is "U1-3"
        // separate net line into Designator & PinNo

        ParseNetLine( LineIndex, Line, Designator, PinName );
        NetName := CurrentNet;
        Inc( LineIndex );
        FCurrentLine := LineIndex;
        result := True;
        exit;
    end;

    // fell through loop - end of netlist file
    result := False;
end;


end.


