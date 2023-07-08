unit NetReaderSeetrax;

interface

uses NetReader, Classes;

// Low level access to UltiCap Netlist files.

type TSeetraxNetReader = class( TveNetReader )

protected
    ComponentFileName : string;
    ComponentLines : TStringList;
    ComponentLineIndex : integer;
    ComponentLineLimit : integer;

    CurrentNet : string;
    HaveNet : boolean;
    NetLineIndex : integer;
    function GetNetlistDescriptor : string; override;
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


implementation

uses SysUtils;


// replace any commas in a string with underscores
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

// function parses space-separated values where AT LEAST 2 SPACES are required.
// Call first time with index = 0 => returns Value = text before 1st comma and
// moves index to next posisiton.
// Returns True means Value holds new data
// Returns False means Value undefined - no more values to parse

function Parse2SpaceDelimited( const Source : string; var Value : string;
    var Index : integer ) : boolean;
var
    Len : integer;
    i : integer;
    start: Integer;
 begin
    Len := Length( Source );

    // if CSVString consumed
    if (Index > Len) or (Len = 0) then begin
        result := False;
        exit;
    end;

    // skip space characters
    i := Index;
    while (i <= Len) and (Source[i] = ' ') do begin
        inc( i );
    end;

    // remember location of first non-space character
    start := i;

    // scan non-space characters
    while (i <= Len) do begin
        if Source[i] = ' ' then begin
            // last space on line is taken as delimiter
            if i = Len then begin
                break;
            end;
            // two consecutive spaces is taken as delimeter
            if Source[i+1] = ' ' then begin
                break;
            end;
        end;
        inc( i );
    end;

    // nothing found
    if i <= start then begin
        result := False;
        exit;
    end;

    // return parsed character block
    Index := i;
    Value := Copy( Source, start, i - start );
    result := True;
    exit;
end;

// function parses space-separated values.
// Call first time with index = 0 => returns Value = text before 1st comma and
// moves index to next posisiton.
// Returns True means Value holds new data
// Returns False means Value undefined - no more values to parse

function ParseSpaceDelimited( const Source : string; var Value : string;
    var Index : integer ) : boolean;
var
    Len : integer;
    i : integer;
    start: Integer;
 begin
    Len := Length( Source );

    // if CSVString consumed
    if (Index > Len) or (Len = 0) then begin
        result := False;
        exit;
    end;

    // skip space characters
    i := Index;
    while (i <= Len) and (Source[i] = ' ') do begin
        inc( i );
    end;

    // remember location of first non-space character
    start := i;

    // scan non-space characters
    while (i <= Len) and (Source[i] <> ' ') do begin
        inc( i );
    end;

    // nothing found
    if i <= start then begin
        result := False;
        exit;
    end;

    // return parsed character block
    Index := i;
    Value := Copy( Source, start, i - start );
    result := True;
    exit;
end;
// starting from position LineIndex, scan across Line until next designator.pin
// pair is consumed. Copy scanned designator.pin into Value.  Return True if
// a pair was scanned, otherwise return False.
// To use, set LineIndex := 0 then call ParseNetLine(). If returns True, you
// have next designator.pin pair in Value.  Otherwise, end of this line

{ eg
. IC1.14  RL1.2
}
function ParseNetLine(
  const Line : string; var Value : string; var LineIndex : integer ) : boolean;
var
    Len : integer;
    start : integer;
    FoundFirst, FoundLast : boolean;
begin
    FoundFirst  := False;
    FoundLast := False;

    Len := Length( Line );

    // move to next character
    Inc( LineIndex );

    // skip leading spaces
    while (LineIndex < Len) and (Line[LineIndex] = ' ') do begin
        Inc( LineIndex );
    end;

    // remember where characters start
    Start := LineIndex;

    // gobble characters until next '.' encountered
    while (LineIndex < Len) and (Line[LineIndex] <> '.') do begin
        FoundFirst := True;
        Inc( LineIndex );
    end;

    // gobble characters until we hit a space
    while (LineIndex < Len) and (Line[LineIndex] <> ' ') do begin
        FoundLast := True;
        Inc( LineIndex );
    end;

    // copy data to output
    Value := Copy( Line, Start, LineIndex - Start );

    // leave LineIndex pointing to last char (space) read
    result := FoundFirst and FoundLast;
end;


constructor TSeetraxNetReader.Create;
begin
    inherited;
    ComponentLines := TStringList.Create;
end;

destructor TSeetraxNetReader.Destroy;
begin
    ComponentLines.Free;
    inherited;
end;

procedure TSeetraxNetReader.ReadFile( const FileName : string );
begin
    // load netlist
    Lines.LoadFromFile( FileName );
    LineLimit := Lines.Count;

    // now load accompanying component file
    ComponentFileName := ChangeFileExt( FileName, '.cmp' );
    ComponentLines.LoadFromFile( ComponentFileName );
    ComponentLineLimit := ComponentLines.Count;
end;


function TSeetraxNetReader.GetNetlistDescriptor : string;
begin
    result := 'Seetrax';
end;


function TSeetraxNetReader.CheckCompatibility : boolean;
begin
    result := True;
end;

procedure TSeetraxNetReader.ToFirstComponent;
var
    i : integer;
    LineCount : integer;
begin
    i := 0;
    LineCount := ComponentLines.Count;
    while i < LineCount do begin
        if Pos( '.PARTS', ComponentLines[i] ) = 1 then begin
            ComponentLineIndex := i + 1;
            exit;
        end;
        inc( i );
    end;
    // must have .PARTS line
    raise ETveNetReader.Create( 'Missing ".PARTS" statement in components file' );
end;

{
.PARTS
CON1  SL3.5-2          SL3.5-2  FN617-520    73,660   30,480    90.00
IC1   ULN2803,ULN2803  DIL18                 53,340   62,230    270.00
RL1   RELHRA,SPCO      HRA                   69,850   60,960    0.00
.ENDPARTS
}

function TSeetraxNetReader.GetNextComponent( var Designator, Value, Outline : string ) : boolean;
var
    ComponentLine : string;
    Index : integer;
begin

    // search for next component
    while ComponentLineIndex < ComponentLineLimit do begin

        ComponentLine := ComponentLines[ComponentLineIndex];

        // no more parts
        if Pos( ComponentLine, '.ENDPARTS' ) = 1 then begin
            break;
        end;

        // handle lines which begin with a dot
        if ComponentLine[1] = '.' then begin
            raise ETveNetReader.CreateFmt(
            'Unknown %s directive in component file, line %d',
            [ComponentLine, ComponentLineIndex + 1] );
        end;

        Index := 0;
        Parse2SpaceDelimited( ComponentLine, Designator, Index );
        Parse2SpaceDelimited( ComponentLine, Value, Index );
        Parse2SpaceDelimited( ComponentLine, Outline, Index );

        // setup for nex component
        Inc( ComponentLineIndex );
        result := True;
        exit;
    end;

    // no component loaded - at end of file
    result := False;
end;

//    ** Parse a string like 'SH1.26' into designator and pin name (number) **

procedure ParsePinToNetText( const Text : string; LineIndex : integer;
        var Designator, PinName : string );
var
    DotPos : integer;
begin
    // find position of dot
    DotPos := Pos( '.', Text );
    if DotPos = 0 then begin
        raise ETveNetReader.CreateFmt(
        'Missing "." in pin to in Pin to Net assignment on line %d',
        [LineIndex + 1] );
    end;

    // before dot is designator
    Designator := Trim(DeComma(Copy( Text, 1, DotPos -1 )));

    // after dot is pin name (number)
    PinName := Trim(DeComma(Copy( Text, DotPos +1, 255 )));

    // blank pin name not allowed
    if PinName = '' then begin
        raise ETveNetReader.CreateFmt(
        'Blank pin name in Pin to Net assignment on line %d',
        [LineIndex + 1] );
    end;
end;

procedure TSeetraxNetReader.ToFirstConnection;

var
    i : integer;
    LineCount : integer;
begin
    HaveNet := False;

    i := 0;
    LineCount := Lines.Count;
    while i < LineCount do begin
        if Pos( '.NETS', Lines[i] ) = 1 then begin
            LineIndex := i;
            FCurrentLine := LineIndex + 1;
            // load parsing line
            Line := Lines[i];
            // put index beyond end of this line to force read of next line
            NetLineIndex := Length(Line) +1;
            exit;
        end;
        inc( i );
    end;
    // must have .NETS line
    raise ETveNetReader.Create( 'Missing ".NETS" statement in net file' );
end;

{
.POWERNAMES
.ENDNAMES

.NETS
. IC1.14  RL1.2
. SH1.25  IC1.9
. CON1.2  RL1.3
. CON1.1  RL1.6
. SH1.3   IC1.5
. SH1.26  IC1.10  RL1.5
.ENDNETS
}

function TSeetraxNetReader.GetNextConnection(
    var NetName, Designator, PinName : string ) : boolean;
var
    Value : string;
 begin
    while LineIndex < LineLimit do begin

        // read next Pin assignment from this line
        if ParseNetLine( Line, Value, NetLineIndex ) then begin
            // should have a value like "R1.2" which identifies a component and pin No
            ParsePinToNetText( Value, NetLineIndex, Designator, PinName );
            NetName := CurrentNet;
            result := True;
            exit;
        end;

        // nothing readable on this line, go to next line
        inc( LineIndex );
        Line := Lines[LineIndex];
        FCurrentLine := LineIndex + 1;
        NetLineIndex := 0;

        // finished with nets
        if Pos( '.ENDNETS', Line ) = 1 then begin
            result := False;
            exit;
        end;

        // see if new line continues an existing net
        if Length(Line) < 2 then begin
            ETveNetReader.CreateFmt(
            'Too short definition in net file on %d', [LineIndex +1] );
        end;

        // net lines starting with '.' have no explicit net name, so use line No
        if Line[1] = '.' then begin
            CurrentNet := Format( 'N%4.4d', [LineIndex +1]);
            NetLineIndex := 2;
        end

        // nets with '&' continue existing net name from previous line, so
        // leave along
        else if Line[1] = '&' then begin
            NetLineIndex := 2;
        end

        // else first field defines the net name
        else begin
            Parse2SpaceDelimited( Line, CurrentNet, NetLineIndex );
        end;
    end;

    // fell through loop - end of netlist file but no .ENDNETS encountered
    raise ETveNetReader.Create( 'Missing ".ENDNETS" statement in net file' );
end;


end.
