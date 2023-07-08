unit NetReaderKiCad;

interface

uses NetReader;

// Low level access to KiCad or EESchem or PcbNew Netlist files.

type TKicadNetReader = class( TveNetReader )

protected
    CurrentDesignator : string;
    HaveComponent : boolean;
    function GetNetlistDescriptor : string; override;

    function FindComponentStart : boolean;
    procedure FindComponentEnd;

    function ToNextPinToNetRecord : boolean;
    procedure ParsePinToNetRecord( var Netname : string; var Pin : integer );
public
    function CheckCompatibility : boolean; override;

    procedure ToFirstComponent; override;
    function GetNextComponent( var Designator, Value, Outline : string ) : boolean;
        override;
    procedure ToFirstConnection; override;
    function GetNextConnection( var NetName, Designator : string; var Pin : integer )
        : boolean; override;

//    constructor Create; virtual;
//    destructor Destroy; override;
end;

implementation

uses SysUtils;



procedure ParseComponentFirstLine(
    LineIndex : integer;
    const Line : string; var Designator, Value, Outline : string );
var
    found : boolean;
    i : integer;
    Limit : integer;
    OutlineRaw : string;

    // parse next token from line - space is separator
    function GetNextText : string;
    begin
        // skip leading spaces
        while (i <= Limit) and (Line[i] = ' ') do begin
            Inc( i );
        end;

        // if come to end of line, then error
        if i > Limit then begin
            raise ETveNetReader.CreateFmt(
                'Not enough fields in Component opening on line %d', [LineIndex + 1]
            );
        end;

        // copy characters until next space or line end
        while (i <= Limit) and (Line[i] <> ' ') do begin
            result := result + Line[i];
            inc( i );
        end;
    end;


begin
    // setup line info
    i := 1;
    Limit := length( Line );

    // skip leading '('
    found := False;
    while i <= Limit do begin
        if Line[i] = '(' then begin
            inc( i );
            found := True;
            break;
        end;
        inc( i );
    end;

    if not Found then begin
        raise ETveNetReader.CreateFmt(
        'Missing "(" in Component start on line %d', [LineIndex + 1]
        );
    end;

    // skip next 2 items
    GetNextText;
    GetNextText;

    // get designator
    Designator := GetNextText;

    // get value
    Value := GetNextText;

    // get outline
    OutlineRaw := GetNextText;
    //.. must start with '{Lib='
    if not (Copy( OutlineRaw, 1, 5 ) = '{Lib=') then begin
        raise ETveNetReader.CreateFmt(
        'Missing "{Lib=" on line %d', [LineIndex + 1]
        );
    end;
    //.. must end with '}'
    if OutlineRaw[Length(OutlineRaw)] <> '}' then begin
        raise ETveNetReader.CreateFmt(
        '"{Lib=" requires closing "}" on line %d', [LineIndex + 1]
        );
    end;
    //.. extract outline name
    Outline := Copy( OutlineRaw, 6, Length(OutlineRaw) - 6 );
end;

function TKicadNetReader.GetNetlistDescriptor : string;
begin
    result := 'Kicad';
end;

function TKicadNetReader.CheckCompatibility : boolean;
begin
    result := True;
end;


procedure TKicadNetReader.ToFirstComponent;
begin
    // skip any leading blank or comment lines, with '#' as first character
    LineIndex := 0;
    while LineIndex < LineLimit do begin
        Line := Lines[LineIndex];
        if (Line = '') or (Line[1] = '#') then begin
            Inc( LineIndex );
            continue;
        end;
        break;
    end;

    // skip '(' which opens the components section
    if Trim( Line[1] ) = '(' then begin
        Inc( LineIndex );
    end
    else begin
        raise ETveNetReader.Create( 'Opening "(" character not found' );
    end;

    if LineIndex >= LineLimit then begin
        raise ETveNetReader.Create( 'Not enough lines in file' );
    end;
end;


// Move LineIndex to line which contains the next component record opening '('
// Returns True if component found, False if not found.

function TKicadNetReader.FindComponentStart : boolean;
var
    Input : string;
begin
    result := False;

    // search for next component
    while LineIndex < LineLimit do begin

        Line := Lines[LineIndex];
        Input := Trim( Line );

        // end of component section is a closing ')'
        if Input = ')' then begin
            result := False;
            break;
        end;

        // component located
        if (Input <> '') and (Input[1] = '(') then begin
            result := True;
            exit;
        end;

        Inc( LineIndex );
    end;
end;


// Move LineIndex to line which contains the component record closing ')'
// Assumes LineIndex is at or beyond the start of a component record.

procedure TKicadNetReader.FindComponentEnd;
var
    Input : string;
begin
    // go to end of this component
    while LineIndex < LineLimit do begin

        Line := Lines[LineIndex];
        Input := Trim( Line );

        // skip blank line
        if Input = '' then begin
            Inc( LineIndex );
            continue
        end;

        // skip pin definition lines
        //..these must have at least 7 chars, e.g. "( 1 N )"
        if (Length( Input ) >= 7) and (Input[1] = '(') and
                (Input[Length(Input)] = ')') then begin
            Inc( LineIndex );
            continue;
        end;

        // must be and end of component line
        if Input = ')' then begin
            Inc( LineIndex );
            break;
        end;

        // if we are still executing, we have an error
        raise ETveNetReader.Create( Format(
            'End of component character ")" expected on line %d', [LineIndex] )
        );
    end;
end;


function TKicadNetReader.GetNextComponent( var Designator, Value, Outline : string ) : boolean;
begin
    // find next component record
    result := FindComponentStart;

    if not result then begin
        exit;
    end;

    // LoadComponent info from start of the record
    ParseComponentFirstLine( LineIndex, Line, Designator, Value, Outline );
    Inc( LineIndex );

    // go to end of this component record
    FindComponentEnd;
end;


procedure TKicadNetReader.ToFirstConnection;
begin
    ToFirstComponent;
    HaveComponent := False;
end;

// Call this inside a component record, to move to the next Pin To Net line
// of form "  (    1 +5V )"
function TKicadNetReader.ToNextPinToNetRecord : boolean;
var
    Input : string;
begin
    // find next non-blank line
    while LineIndex < LineLimit do begin
        Line := Lines[LineIndex];
        Input := Trim( Line );
        if Input <> '' then begin
            break;
        end;
        Inc( LineIndex );
    end;

    // pin to net assignment line
    if Input[1] = '(' then begin
        result := True;
        exit;
    end;
    // end of component line
    if Input[1] = ')' then begin
        result := False;
        exit;
    end;
    // invalid line
    raise ETveNetReader.Create( Format(
        '"(" or ")" expected at start line %d', [LineIndex] )
    );
end;

// Extract Pin and Net from a PinToNet record which is in variable Line
// Line will be of form "  (    1 +5V )"

procedure TKicadNetReader.ParsePinToNetRecord( var Netname : string; var Pin : integer );
var
    i : integer;
    Limit : integer;
    Found : boolean;
    PinStr : string;
begin
    // initialise
    i := 1;
    Limit := Length(Line);

    // skip leading spaces until '('
    while i <= Limit do begin
        if Line[i] = ' ' then begin
            Inc( i );
            continue;
        end;
        if Line[i] = '(' then begin
            Inc( i );
            break;
        end;
        // to get here is error
        raise ETveNetReader.Create( Format(
            '"(" expected at start line %d', [LineIndex] )
        );
    end;

    // skip spaces
    while (i <= Limit) and (Line[i] = ' ') do begin
        inc( i );
    end;

    // next field is number of pin
    while (i <= Limit) and (Line[i] <> ' ') do begin
        PinStr := PinStr + Line[i];
        inc( i );
    end;
    try
        Pin := StrToInt( PinStr );
    except
        raise ETveNetReader.Create( Format(
            'Invalid pin number on line %d', [LineIndex] )
        );
    end;

    // skip spaces
    while (i <= Limit) and (Line[i] = ' ') do begin
        inc( i );
    end;

    // next field is net name
    NetName := '';
    while (i <= Limit) and (Line[i] <> ' ') do begin
        NetName := NetName + Line[i];
        inc( i );
    end;
end;


function TKicadNetReader.GetNextConnection( var NetName, Designator : string; var Pin : integer )
    : boolean;

var
    Value : string;
    Outline : string;

begin
    result := False;
    exit;


    // do until we find a pin to net assignment or run out of components
    while LineIndex < LineLimit do begin

        // must be inside a component
        if not HaveComponent then begin
            result := FindComponentStart;
            // no more components
            if not result then begin
                exit;
            end;

            // setup for this new component
            HaveComponent := True;
            ParseComponentFirstLine( LineIndex, Line, CurrentDesignator, Value, Outline );
            Inc( LineIndex );
        end;


        // go to next Pin To Net record inside component record
        if ToNextPinToNetRecord then begin;
            ParsePinToNetRecord( Netname, Pin );
            Inc( LineIndex );
            // if pin has genuine net name
            if NetName <> '?' then begin
                Designator := CurrentDesignator;
                result := True;
                exit;
            end;
        end
        else begin
            // try again for next component
            HaveComponent := False;
            Inc( LineIndex );
        end;
    end;

    // we should not get here
    raise ETveNetReader.Create( '")" expected before end of data' );
end;


end.



Component definitions contain the pin to net assignments


 ( IGNORE, OUTLINE, DESIGNATOR, VALUE, OUTLINE
  ( PIN_NO NET )
  ( PIN_NO NET )
 )


 ( 33A51A4E $noname R4 10K {Lib=R}
  (    1 N-000112 )
  (    2 +5V )
 )


Note : ORCAD PCB2 format is very similar :

 ( 00000157 SO-8 U26 TLC393
  ( 1 NetR132_1 )
  ( 2 NetR128_1 )
  ( 3 NetR130_1 )
  ( 4 GND_2 )
  ( 5 NetR128_1 )
  ( 6 NetU26_6 )
  ( 7 NetU26_7 )
  ( 8 VBAT_1 )
 )

