unit GerberImporter;

interface

uses Classes, ManagedItem, Board, SysUtils;

type TgrUnits = ( unInch, unMillimetre );
type TInterpolation = ( imLinear, imClockwise, imCounterClockwise );
type TZerosOmission = ( zmNone, zmLeading, zmTrailing );


type TgrTrack = class( TManagedItem )
  public
    // values in inches
    X1 : single;
    Y1 : single;
    X2 : single;
    Y2 : single;
    Width : single
end;

type TgrStrip = class( TManagedItem )
  public
    // values in inches
    X1 : single;
    Y1 : single;
    X2 : single;
    Y2 : single;
    // values in cells
    CellX1 : integer;
    CellY1 : integer;
    CellX2 : integer;
    CellY2 : integer;
    // marked for removal, etc
    Marked : boolean;
end;


type TgrSegment = class( TManagedItem )
  public
    // values in inches
    X1 : single;
    Y1 : single;
    X2 : single;
    Y2 : single;
    Width : single;
end;

type TgrAperture = record
    Assigned : boolean;
    Circle : boolean;
    Diameter : single;
end;

type TgrGerberImport = class

    // parsing state machine variables
    Units : TgrUnits;

    // number format : value to give least digit (inches or millimetres)
    IntegerDigits : integer;
    DecimalDigits : integer;
    ZerosOmission : TZerosOmission;

    ApertureNo : integer;
    Exposure : boolean;
    Interpolation : TInterpolation;
    X, Y : single;


    // scanning through Gerber text
    FText : string;
    FScanIndex : integer;
    Limit : integer;
    FinishedScan : boolean;

    FTracks : TManagedList;
    FStrips : TManagedList;
    FSegments : TManagedList;

    Width : integer;
    Height : integer;

    // circular apertures stored here (Gerber allows 0-999 as aperture Nos)
    // Eg. D3 aperture is Apertures[3] .
    Apertures : array[0..1000] of TgrAperture;

    function GetTrackCount : integer;
    function GetTrack(i : integer) : TgrTrack;
    function GetStripCount : integer;
    function GetStrip(i : integer) : TgrStrip;
    function GetSegmentCount : integer;
    function GetSegment(i : integer) : TgrSegment;

    procedure Clear;

    // Scanning functions
    procedure ScanParameters;
    procedure ScanDirectives;
    function ScanInteger : integer;
    function ScanIntegerText : string;
    function ScanDecimal : single;
    procedure ScanToBlockEnd;
    procedure CheckBlockEnd;
    procedure CheckLimit;

    function ConvertCoodinateToInches( value : string ) : single;
    procedure ScanFormatSpecification;

    // read data from Gerber text, convert coords to inches
    // and store all tracks in Tracks[]
    procedure ParseGerberText;
    function ErrorLineNo : integer;

    // extract veroboard strips from tracks
    procedure ExtractStripsAndSegments;

    // pull strips and segments onto veroboard grid
    procedure SnapToGrid;

    // remove duplicate tracks, hidden tracks, single hole tracks
    procedure CleanStrips;

    // find board dimensions
    procedure FindBoardSize;

    // copy to TbrBoard object
    procedure TransferToBoard( Board : TbrBoard );

    property Text : string read FText write FText;
    property ScanIndex : integer read FScanIndex write FScanIndex;


    // raw info in tracks, with inch units
    property TrackCount : integer  read GetTrackCount;
    property Tracks[i : integer] : TgrTrack read GetTrack;
    // veroboard strips
    property StripCount : integer read GetStripCount;
    property Strips[i : integer] : TgrStrip read GetStrip;
    // veroboard narrow "display only" strips
    property SegmentCount : integer read GetSegmentCount;
    property Segments[i : integer] : TgrSegment read GetSegment;

  public

    procedure ReadFileToBoard( const FileName : string; Board : TbrBoard );

    constructor Create;
    destructor Destroy; override;
end;


implementation

uses StrUtils, Character, Math, ExceptSafe;

type EGerber = class( ESafe );


constructor TgrGerberImport.Create;
begin
    FTracks := TManagedList.Create;
    FStrips := TManagedList.Create;
    FSegments := TManagedList.Create;
end;

destructor TgrGerberImport.Destroy;
begin
    FTracks.Free;
    FStrips.Free;
    FSegments.Free;
end;


procedure TgrGerberImport.Clear;
var
    i : integer;
begin
    for i := Low(Apertures) to High(Apertures) do begin
        Apertures[i].Assigned := False;
        Apertures[i].Circle := False;
//        Apertures[i].Diameter := 0.0
    end;

    FTracks.Clear;
    FStrips.Clear;
    FSegments.Clear;

    X := 0.0;
    Y := 0.0;
    Exposure := False;
    ApertureNo := 0;
    Interpolation := imLinear;

end;


// *************************************************
//                    PROPERTIES
// *************************************************

function TgrGerberImport.GetTrackCount : integer;
begin
    result := FTracks.Count;
end;

function TgrGerberImport.GetTrack(i : integer) : TgrTrack;
begin
    result := TgrTrack(FTracks[i]);

end;

function TgrGerberImport.GetStripCount : integer;
begin
    result := FStrips.Count;
end;

function TgrGerberImport.GetStrip(i : integer) : TgrStrip;
begin
    result := TgrStrip(FStrips[i]);
end;

function TgrGerberImport.GetSegmentCount : integer;
begin
    result := FSegments.Count;
end;

function TgrGerberImport.GetSegment(i : integer) : TgrSegment;
begin
    result := TgrSegment(FSegments[i]);
end;

// ********************************************
//      CONVERT SCAN INDEX TO LINE NUMBER
// ********************************************

// find which line number that current scan point
// Slow, but only used for error reporting.

function TgrGerberImport.ErrorLineNo : integer;
var
    i : integer;
    c : char;
    lastchar : char;
begin
    // work thru text, counting lines until ScanIndex is reached

    lastchar := #0;
    result := 1;
    for i := 1 to FScanIndex do begin
        c := FText[i];

        if c = #13 then begin
            inc( result );
        end
        else if (c = #10) and (lastchar <> #13) then begin
            inc( result );
        end;
        lastchar := c;
    end;

    // scan is one ahead of visible text lines, so if just hit end of line,
    // jump back
    if (lastchar = #10) or (lastchar = #13) then begin
        dec( result );
    end;
end;

// ********************************************
//         PARSE INTEGER FROM STREAM
// ********************************************

// Call with ScanIndex at expected first character of number
// If no digits found, then error
// Returns with ScanIndex at next char after number.

function TgrGerberImport.ScanInteger : integer;
var
    NumberStart : integer;
    NumberText : string;
    c : char;
begin
    NumberStart := FScanIndex;
    while FScanIndex <= Limit do begin
        c := FText[FScanIndex];
        if not (IsDigit(c) or (c='+') or (c='-') )then begin
            break;
        end;
        Inc( FScanIndex );
    end;

    if NumberStart = FScanIndex then begin
        raise EGerber.Create( 'Expected integer number' );
    end;

    NumberText := Copy( FText, NumberStart, FScanIndex - NumberStart );

    try
        result:= StrToInt( NumberText );
    except
        On EConvertError do begin
            raise EGerber.Create( 'Error reading integer value' );
        end
    end;
end;

// ********************************************
//        PARSE INTEGER FROM TEXT STREAM
// ********************************************

function TgrGerberImport.ScanIntegerText : string;
var
    NumberStart : integer;
    c : char;
begin
    NumberStart := FScanIndex;
    while FScanIndex <= Limit do begin
        c := FText[FScanIndex];
        if not (IsDigit(c) or (c='+') or (c='-') )then begin
            break;
        end;
        Inc( FScanIndex );
    end;

    if NumberStart = FScanIndex then begin
        raise EGerber.Create( 'Expected integer number' );
    end;

    result := Copy( FText, NumberStart, FScanIndex - NumberStart );
end;


// ********************************************
//         PARSE INTEGER FROM STREAM
// ********************************************

// Call with ScanIndex at expected first character of number
// If no digits with optional decimal point found, then error
// Returns with ScanIndex at next char after number.

function TgrGerberImport.ScanDecimal : single;
var
    NumberStart : integer;
    NumberText : string;
    c : char;
begin
    NumberStart := FScanIndex;
    while FScanIndex <= Limit do begin
        c := FText[FScanIndex];
        if not (IsDigit(c) or (c = '.') or (c='+') or (c='-')) then begin
            break;
        end;
        Inc( FScanIndex );
    end;

    if NumberStart = FScanIndex then begin
        raise EGerber.Create( 'Expected decimal number' );
    end;

    NumberText := Copy( FText, NumberStart, FScanIndex - NumberStart );

    try
        result:= StrToFloat( NumberText );
    except
        On EConvertError do begin
            raise EGerber.Create( 'Error reading decimal number.' );
        end
    end;
end;

// *****************************************************
//      Convert Raw Integer Coordinate To Inches
// *****************************************************
{
    Convert coordinate text to inches,
    // parsing state machine variables
    Units : TgrUnits;

    // number format : value to give least digit (inches or millimetres)
    IntegerDigits : integer;
    DecimalDigits : integer;
    ZerosOmission : TZerosOmission;
        type TZerosOmission = ( zmNone, zmLeading, zmTrailing );
}

function TgrGerberImport.ConvertCoodinateToInches( value : string ) : single;
var
    Minus : boolean;
    TargetLength : integer;
    i : integer;
begin
    // if the leading char is a '-', remove it
    Minus := False;
    if Copy( value, 1, 1 ) = '-' then begin
        Minus := True;
        Value := Copy( value, 2, 20 );    
    end
    else if Copy( value, 1, 1 ) = '+' then begin
        Value := Copy( value, 2, 20 );    
    end;
    
    // we must have a character string this many chars long
    TargetLength := IntegerDigits + DecimalDigits;

    // pad out leading or trailing zeros to get standard length number string
    if ZerosOmission = zmLeading then begin
        // add leading zeros
        for i := Length(value) to TargetLength - 1 do begin
            value := '0' + value;
        end;
    end

    else if ZerosOmission = zmTrailing then begin
        // add trailing zeros
        for i := Length(value) to TargetLength - 1 do begin
            value := value + '0';
        end;
    end;

    // check that we have correct length
    if Length(value) <> (IntegerDigits + DecimalDigits) then begin
        raise EGerber.CreateFmt(
        'Format specifier requires %d digits ', [TargetLength]);
    end;

    // put in decimal point
    value := Copy(value, 1, IntegerDigits) + '.' + Copy(value, IntegerDigits +1, 20 );

    // convert to floating point value
    result := StrToFloat( value );

    // put in minus if necessary
    if Minus then begin
        result := - result;
    end;

    // convert to inches if necessary
    if Units = unMillimetre then begin
        result := result / 25.4;
    end;
end;


// ***********************************************************
// move ScanIndex to first char past end of block '*' character
// ***********************************************************
procedure TgrGerberImport.ScanToBlockEnd;
begin
    while FScanIndex <= Limit do begin
        if FText[FScanIndex] = '*' then begin
            break;
        end;
        Inc( FScanIndex );
    end;
    CheckBlockEnd;
end;

// ***********************************************************
// Check that ScanIndex points to end of block character '*'
// ***********************************************************

procedure TgrGerberImport.CheckBlockEnd;
begin
    if FScanIndex >= Limit then begin
        raise EGerber.Create( 'Block end "*" expected before end of file.' );
    end;
    if FText[FScanIndex] <> '*'  then begin
        raise EGerber.Create( 'Block end "*" expected.' );
    end;
end;

// ********************************************
//    CHECK IF SCAN INDEX PAST END OF TEXT
// ********************************************

procedure TgrGerberImport.CheckLimit;
begin
    if FScanIndex > Limit then begin
        raise EGerber.Create( 'Input past end of file' );
    end;
end;

// ********************************************
//      PARSE GERBER FILE INTO OBJECT
// ********************************************

// read data from Gerber file presented as TStrings, convert coords to inches
    // and store all tracks in Tracks[]
procedure TgrGerberImport.ParseGerberText;
begin
    Clear;
    ScanIndex := 1;
    Limit := Length(FText);
    FinishedScan := False;

    // scan elements until end of file
    while (not FinishedScan) and (ScanIndex <= Limit) do begin

        case  FText[ScanIndex] of
            // Parameter section contains settings for drawing
            '%' : ScanParameters;
            ' ', #10, #13 : ;
            else begin
                // Directive section contains drawing commands
                ScanDirectives;
            end;
        end;

        Inc( FScanIndex );
    end;

    // if ran off end of file without M02 "End of Program" block, then error
    if ScanIndex > Limit then begin
        raise EGerber.Create( 'End of file without MO2 statement (1)' );
    end;
end;

// *************************************
//      Read Format Specification
// *************************************
{    Place results in these class vars:
    IntegerDigits : integer;
    DecimalDigits : integer;
    ZerosOmission : TZerosOmission;

RS274X includes a statement that embeds key information about the format,
zero suppression and data mode:
    * format (x,y)
    * zero suppression (leading, trailing or none)
    * coordinates (absolute or incremental)

  %FS L/T/D A/I Nn Gn Xa Yb Zc Dn Mn *%

where:
L  = omit leading zeros, T = omit trailing zeros,    ** record L/T/D **
D  = explicit decimal point (i.e. no zeros omitted)

A  = absolute coordinate mode, I  = incremental coordinate mode  ** require A **

Nn = number of digits following a Dxx code (ignore if encountered)
Gn = number of digits following a Gxx code (ignore if encountered)

Xa = format of X input data (5.5 is max) ** record **
Yb = format of Y input data (5.5 is max) ** record **

Zb = format of input data (Z is rarely if ever seen) (ignore if encountered)

Dn = number of digits following a Dxx code (ignore if encountered)
Mn = number of digits following a Mxx code (ignore if encountered)

%FSLAX24Y24*% = Leading Zeros Suppression, Absolute Coordinates format=2.4
%FSTIX44Y44*% = Trailing Zero Supression, Incremental Coordinates, format=4.4
}
procedure TgrGerberImport.ScanFormatSpecification;
var
    Integers : integer;
    Decimals : integer;

    // extract number of integer, decimals
    procedure ScanCoordFormat;
    var
        c : char;
    begin
        Inc( FScanIndex );
        CheckLimit;
        c := FText[FScanIndex];
        if not IsDigit(c) then begin
            raise EGerber.Create( 'Coord format error' );
        end;
        Integers := StrToInt( c );
        Inc( FScanIndex );
        CheckLimit;
        c := FText[FScanIndex];
        if not IsDigit(c) then begin
            raise EGerber.Create( 'Coord format error' );
        end;
        Decimals := StrToInt( c );
        Inc( FScanIndex );
        CheckLimit;
    end;
begin
    // step over opening 'FS'
    Inc( FScanIndex, 2 );
    CheckLimit;

    // L/T/D zeros format
    case FText[FScanIndex] of
        'L' : ZerosOmission := zmLeading;
        'T' : ZerosOmission := zmTrailing;
        'D' : ZerosOmission := zmNone;
        else begin
            raise EGerber.CreateFmt(
            'Unknown coordinate format "%s"', [FText[FScanIndex]]);
        end;
    end;

    Inc( FScanIndex );
    CheckLimit;

    // A/I absolute or incremental
    case FText[FScanIndex] of
        'A' : ;   // absolute mode required by this program
        'I' : raise EGerber.Create( 'Incremental coords not supported' );
        'D' : ZerosOmission := zmNone;
        else begin
            raise EGerber.CreateFmt(
            'Unknown Absolute/Incremental specification "%s"', [FText[FScanIndex]]);
        end;
    end;

    Inc( FScanIndex );
    CheckLimit;

    while true do begin

        case FText[FScanIndex] of

            // skip over these codes
            'N', 'G', 'Z', 'D', 'M' : begin
                ScanInteger;
            end;

            // extract number of integer, decimals
            'X' : begin
                ScanCoordFormat;
                IntegerDigits := Integers;
                DecimalDigits := Decimals;
            end;

            // extract number of integer, decimals - must match X format, which
            // we assume is already defined.
            'Y' : begin
                ScanCoordFormat;
                if (IntegerDigits <> Integers) or (DecimalDigits <> Decimals)
                    then begin
                    raise EGerber.Create( 'Different X, Y formats not supported' );
                end;
            end;

            '*' : begin
                break;
            end;

            else begin
                raise EGerber.CreateFmt(
                'Unknown format specification code "%s"', [FText[FScanIndex]]);
            end;
        end;
    end;
end;


// ********************************************************************
//   Scan from beginning of a Parameter Section start character
// ********************************************************************

procedure TgrGerberImport.ScanParameters;

    procedure ScanApertureDefinition;
    var
        ApertureNo : integer;
        Diameter : single;
    begin
        // enter with ScanIndex at opening 'A' of 'ADD'
        // move past 'AD' and 'D' character of Dxx
        Inc( FScanIndex, 3 );

        // number is digit characters after '%ADD'
        ApertureNo := ScanInteger;

        // if 'C,' follows, we have a circle aperture.
        // 'R,'  rectangle
        // 'O,'  obround (oval)
        // 'P,'  regular polygon

        if Copy( FText, FScanIndex, 2 ) = 'C,' then begin

            // Circles defined like '%ADD12C,.06*%' or '%ADD10C,0.0660*%'

            // move past 'C,'
            Inc( FScanIndex, 2 );

            // read decimal diameter
            diameter := ScanDecimal;

            // store value
            Apertures[ApertureNo].Assigned := True;
            Apertures[ApertureNo].Diameter := Diameter;
            Apertures[ApertureNo].Circle := True;
        end;

        // finish block, whether we read a circle or not
        ScanToBlockEnd;
    end;

var
    Param : string;
begin
    // move to first char in block
    Inc( FScanIndex );
    CheckLimit;


    Param := Copy( FText, ScanIndex, 2);

    // aperture definition
    if Param = 'AD' then begin
        ScanApertureDefinition;
        // leaves pointing to block end '*'
    end
    else if Param = 'FS' then begin
        ScanFormatSpecification;
        // leaves pointing to block end '*'
    end;

    // exit with ScanIndex pointing to terminating '%'
    // This also scans over entirety of unimplemented defintions, including
    // multi line ones.
    while ScanIndex <= Limit do begin
        if FText[FScanIndex] = '%' then begin
            break;
        end;
        Inc( FScanIndex );
    end;

end;


// ********************************************************************
//            Scan Statement Block
// ********************************************************************

// Scan until next '*' character, which ends the block.
// Contains any G,X,Y,D,M etc
// Basically, contains x,y values and/or codes describings how to apply coords.
// Called with ScanIndex pointing to first char in block

procedure TgrGerberImport.ScanDirectives;
var
    NewX, NewY : single;

    // G codes set the machine state, to define effect of subsequent drawing commands
    procedure ScanG;
    var
        Code : integer;
    begin
        Code := ScanInteger;
        case Code of

          // linear interpolation (default)
          01 : Interpolation := imLinear;
          // clockwise circular interpolation
          02 : Interpolation := imClockwise;
          // counter clockwise circular interpolation
          03 : Interpolation := imCounterClockwise;
          // comment, ignore
          04 : ScanToBlockEnd;
          // historically precedes an aperture D code, can be ignored.
          54 : ;

          70 : Units := unInch;
          71 : Units := unMillimetre;

          // 360 circle interpolation off
          // Cancel multi quadrant mode
          74 : ;
          // 360 circle interpolation on
          // Enable multi quadrant mode
          75 : ;

          else begin
              raise EGerber.CreateFmt( 'G%d code not supported', [Code]);
          end;
        end;
    end;

    // set X coord
    procedure ScanX;
    begin
        NewX := ConvertCoodinateToInches( ScanIntegerText );
    end;

    // set Y coord
    procedure ScanY;
    begin
        NewY := ConvertCoodinateToInches( ScanIntegerText );
    end;

    // Draw and Flash Commands
    procedure ScanD;
    var
        ExposureNum : integer;
        Track : TgrTrack;
    begin
        ExposureNum := ScanInteger;
        case ExposureNum of
            // draw a line using current aperture, leave exposure on, move to NewX,NewY
            // ie. Draw with Tool Down
            1 : begin
                // record only circle aperture used on lines (not arcs)
                if Apertures[ApertureNo].Assigned and
                  Apertures[ApertureNo].Circle and
                  (Interpolation = imLinear) then begin
                    // draw line
                    Track := TgrTrack(FTracks.AddNew(TgrTrack));
                    Track.X1 := X;
                    Track.Y1 := Y;
                    Track.X2 := NewX;
                    Track.Y2 := NewY;
                    Track.Width := Apertures[ApertureNo].Diameter;
                end;
                Exposure := True;
            end;
            // Exposure off, move to NewX,NewY
            // ie. Move with Tool Up
            2 : begin
                Exposure := False;
            end;
            // Flash the current aperture, move to NewX,NewY
            // ie. Flash Pad
            3 : begin

                if Apertures[ApertureNo].Assigned and
                  Apertures[ApertureNo].Circle then begin
                    // draw circle
                    Track := TgrTrack(FTracks.AddNew(TgrTrack));
                    Track.X1 := NewX;
                    Track.Y1 := NewY;
                    Track.X2 := NewX;
                    Track.Y2 := NewY;
                    Track.Width := Apertures[ApertureNo].Diameter;
                end;
                  Exposure := False;
            end;
            // select aperture
            10..999 : begin
                ApertureNo := ExposureNum;
            end
            else begin
                raise EGerber.Create( 'Unknown "D" code' );
            end;
        end;
    end;

    procedure ScanM;
    var Code : integer;
    begin
        Code := ScanInteger;
        case Code of
            // M02 is program stop. M00, M01 are obsolete, but we support anyway
            0, 1, 2 : FinishedScan := True;
        end;
    end;

    // these are block sequence numbers, rarely used, not involved in drawing
    procedure ScanN;
    begin
        ScanInteger;
    end;


var
    c : char;
begin
    // make existing X,Y the default new locations - one or other (or both?) may
    // not be changed.
    NewX := X;
    NewY := Y;

    // read the block
    while FScanIndex <= Limit do begin
        // read and consume next char
        c := FText[FScanIndex];
        Inc( FScanIndex );

        // act on char
        case c of
            'G' : ScanG;
            'X' : ScanX;
            'Y' : ScanY;
            'D' : ScanD;
            'M' : ScanM;
            'N' : ScanN;
            #10, #13 : begin
                continue;
            end
            else begin
                raise EGerber.CreateFmt( 'unknown  directive "%s".', [c] );
            end;
        end;

        // if we have executed all commands in this block, return
        if FText[FScanIndex] = '*' then begin
            break;
        end;
    end;

    // latest coords now become "last position"
    X := NewX;
    Y := NewY;
end;


const
    // values in inches:
    // strips widths
    MIN_STRIP_WIDTH = 0.039;
    MAX_STRIP_WIDTH = 0.075;
    // vertical or horiz strip must have x or y coords match to this tolerance
    // at both ends of strip.
    GRID_TOLERANCE = 0.002;

procedure TgrGerberImport.ExtractStripsAndSegments;
var
    i : integer;
    Track : TgrTrack;
    Strip : TgrStrip;
    Segment : TgrSegment;
begin
    // Work through tracks, extracting strips and segments
    for i := 0 to TrackCount -1 do begin
        Track := Tracks[i];

        // strips are must have a width that permits 0.1 inch spacing
        // and is vertical or hoizontal
        if (Track.Width >= MIN_STRIP_WIDTH) and
            (Track.Width <= MAX_STRIP_WIDTH) and
            (
                (Abs(Track.X1 - Track.X2) <= GRID_TOLERANCE) or
                (Abs(Track.Y1 - Track.Y2) <= GRID_TOLERANCE)
            )
            then begin
                Strip := TgrStrip(FStrips.AddNew(TgrStrip));
                Strip.X1 := Track.X1;
                Strip.Y1 := Track.Y1;
                Strip.X2 := Track.X2;
                Strip.Y2 := Track.Y2;
        end

        // else we have a "segment" just a piece of copper track that
        // is not a strip
        else begin
            Segment := TgrSegment(FSegments.AddNew(TgrSegment));
            Segment.X1 := Track.X1;
            Segment.Y1 := Track.Y1;
            Segment.X2 := Track.X2;
            Segment.Y2 := Track.Y2;
            Segment.Width := Track.Width;
        end;
    end;
end;

// pull strips and segments onto veroboard grid
procedure TgrGerberImport.SnapToGrid;

    // check that two coords are separated by a multiple of 0.1 inch
    function OnGrid( value1, value2 : single ) : boolean;
    var
        SeparationTenths : single;
    begin
        // find separation in tenths of an inch
        SeparationTenths := abs((value1 - value2) * 10.0);
        // see if separation is close to an exact 1/10 of an inch
        result := Frac(SeparationTenths) <= (GRID_TOLERANCE * 2 * 10);
    end;

    // convert inches to cells
    function InchToCells( Inches : single ) : single;
    begin
        result := Round(Inches * 10);
    end;

    // convert inches to 1000s of a cell
    function InchToCell1000s( Inches : single ) : integer;
    begin
        result := Round(Inches * 10 * 1000);
    end;


var
    i, j, k : integer;
    // references to strips : strip 0 is reference strip
    Strip0, Strip1, Strip2 : TgrStrip;
    ReferenceFound : boolean;
    deltaX, deltaY : single;
    Strip : TgrStrip;
    Segment : TgrSegment;
    LeftX, TopY : single;

label
    loopout;
begin
    // if we have no strips..
    if StripCount = 0 then begin
        exit;
    end;

    // we have to find a reference strip that is a multiple of 0.1 inches
    // away from two other strips
    // Index of reference strip : set to invalid value to start
    ReferenceFound := False;
    //.. prevent unitialised variable warning
    Strip0 := nil;

    // for all strips except last two
    for i := 0 to StripCount - 3 do begin

        // get a strip
        Strip0 := Strips[i];

        // look for 2 other strips that are a multiple of 0.1" away
        for j := i+1 to StripCount - 2 do begin

            Strip1 := Strips[j];

            for k := j+1 to StripCount - 1 do begin

                Strip2 := Strips[k];

                if  onGrid(Strip0.X1, Strip1.X1) and
                    onGrid(Strip0.X1, Strip2.X1) and

                    onGrid(Strip0.Y1, Strip1.Y1) and
                    onGrid(Strip0.Y1, Strip2.Y1)
                then begin
                    ReferenceFound := True;
                    goto loopout;
                end;
            end;
        end;
    end;

loopout:
    // if can't find 3 strips that are Reference
    if not ReferenceFound then begin
        raise EGerber.Create( 'Strips not on 0.1 inch grid' );
    end;

    // use reference strip (Strip0) to pull all other strips on
    // 0.1 inch grid : making the reference strip X1,Y1 the 0,0 point
    // In addition, negate all Y values to convert to the -Y axis used by VeeCAD.
    // then round to 0.1 inch (strips) to get "snap" to grid.
    // Note that segments may not be on grid
    deltaX := Strip0.X1;
    deltaY := Strip0.Y1;
    for i := 0 to StripCount - 1 do begin
        Strip := Strips[i];
        Strip.X1 := Strip.X1 - deltaX;
        Strip.Y1 := -(Strip.Y1 - deltaY);
        Strip.X2 := Strip.X2 - deltaX;
        Strip.Y2 := -(Strip.Y2 - deltaY);
    end;

    for i := 0 to SegmentCount - 1 do begin
        Segment := Segments[i];
        Segment.X1 :=   Segment.X1 - deltaX;
        Segment.Y1 := -(Segment.Y1 - deltaY);
        Segment.X2 :=   Segment.X2 - deltaX;
        Segment.Y2 := -(Segment.Y2 - deltaY);
    end;

    // find top, leftmost strip or segment, ie with lowestX,Y
    //.. start out with impossibly high X,Y, then reduce
    LeftX := 1000000;
    TopY := 1000000;
    for i := 0 to StripCount - 1 do begin
        Strip := Strips[i];
        LeftX := Min( LeftX, Strip.X1 );
        LeftX := Min( LeftX, Strip.X2 );
        TopY := Min( TopY, Strip.Y1 );
        TopY := Min( TopY, Strip.Y2 );
    end;

    for i := 0 to SegmentCount - 1 do begin
        Segment := Segments[i];
        LeftX := Min( LeftX, Segment.X1 );
        LeftX := Min( LeftX, Segment.X2 );
        TopY := Min( TopY, Segment.Y1 );
        TopY := Min( TopY, Segment.Y2 );
    end;


    LeftX := Round(LeftX * 10) / 10.0;
    TopY := Round(TopY * 10) / 10.0;

    // move strips and segments to final position
    for i := 0 to StripCount - 1 do begin
        Strip := Strips[i];
        Strip.X1 := Strip.X1 - LeftX;
        Strip.Y1 := Strip.Y1 - TopY;
        Strip.X2 := Strip.X2 - LeftX;
        Strip.Y2 := Strip.Y2 - TopY;
    end;

    for i := 0 to SegmentCount - 1 do begin
        Segment := Segments[i];
        Segment.X1 := Segment.X1 - LeftX;
        Segment.Y1 := Segment.Y1 - TopY;
        Segment.X2 := Segment.X2 - LeftX;
        Segment.Y2 := Segment.Y2 - TopY;
    end;
end;


// remove duplicate tracks, hidden tracks, single hole tracks
procedure TgrGerberImport.CleanStrips;

    // find length of a strip in cell units
    function StripLength( Strip : TgrStrip ) : integer;
    begin
        // all strips are vertical or horizontal - non are angled, so just
        // add X and Y lengths, since one must be zero
        result := 
            abs( Strip.CellX1 - Strip.CellX2 ) +
            abs( Strip.CellY1 - Strip.CellY2 );
       end;

    // if strips are co-linear and overlap, then combine strips to form a single
    // and return True. Integrates StripB into StripA.
    function CombineStrips( StripA, StripB : TgrStrip ) : boolean;
    var
        LeftA, RightA : integer;
        LeftB, RightB : integer;
        temp : integer;
        TopA, BottomA : integer;
        TopB, BottomB : integer;

    begin
        result := False;

        // if both strips horizontal and co-linear
        if (StripA.CellY1 = StripA.CellY2) and
            (StripA.CellY1 = StripB.CellY1) and
            (StripA.CellY1 = StripB.CellY2) then begin

            // get left, right X values of StripA, StripB
            LeftA := StripA.CellX1;
            RightA := StripA.CellX2;
            if LeftA > RightA then begin
                temp := LeftA;
                LeftA := RightA;
                RightA := temp;
            end;
            LeftB := StripB.CellX1;
            RightB := StripB.CellX2;
            if LeftB > RightB then begin
                temp := LeftB;
                LeftB := RightB;
                RightB := temp;
            end;

            // if strips overlap
            if ((LeftA <= RightB) and (RightA >= LeftB)) or
                ((LeftB <= RightA) and (RightB >= LeftA)) then begin
                result := True;
                StripA.CellX1 := Min(LeftA, LeftB);
                StripA.CellX2 := Max(RightA, RightB);
            end;
        end

        // if both strips vertical and co-linear
        else if (StripA.CellX1 = StripA.CellX2) and
                (StripA.CellX1 = StripB.CellX1) and
                (StripA.CellX1 = StripB.CellX2) then begin

            // get top, bottom X values of StripA, StripB
            TopA := StripA.CellY1;
            BottomA := StripA.CellY2;
            if BottomA < TopA then begin
                temp := BottomA;
                BottomA := TopA;
                TopA := temp;
            end;
            TopB := StripB.CellY1;
            BottomB := StripB.CellY2;
            if BottomB < TopB then begin
                temp := BottomB;
                BottomB := TopB;
                TopB := temp;
            end;

            // if strips overlap
            if ((TopA <= TopB) and (BottomA >= TopB)) or
               ((TopB <= TopA) and (BottomB >= TopA)) then begin
                result := True;
                StripA.CellY1 := Min(TopA, TopB);
                StripA.CellY2 := Max(BottomA, BottomB);
            end;
        end;

    end;

var
    i : integer;
    Strip : TgrStrip;
    j : integer;
    Strip1 : TgrStrip;
    JoinMade : boolean;
label
    loop;
begin
    // create strips (units are cells)
    for i := 0 to StripCount - 1 do begin
        Strip := Strips[i];
        Strip.CellX1 := Round( Strip.X1 * 10);
        Strip.CellY1 := Round( Strip.Y1 * 10);
        Strip.CellX2 := Round( Strip.X2 * 10);
        Strip.CellY2 := Round( Strip.Y2 * 10);
    end;

{
    // remove single hole tracks
    for i := 0 to StripCount -1 do begin
        if StripLength( Strip ) = 0 then begin
            FStrips.Delete( i );
            continue;
        end;
    end;
}
    JoinMade := True;
    while JoinMade do begin

        JoinMade := False;

        // for every strip (except last strip)
        for i := 0 to StripCount -2 do begin
            Strip := Strips[i];

            // for every strip further down the list
            for j := i+1 to StripCount - 1 do begin
                Strip1 := Strips[j];

                // if strips are co-linear and overlap, combine the strips and
                // delete the shorter of the two. Strips are combined into Strip
                if CombineStrips( Strip, Strip1 ) then begin

                    // delete Strip1 - no longer needed
                    FStrips.Delete(j);

                    // now start joining procedure again
                    JoinMade := True;
                    goto loop;
                end;
            end;
        end;
loop:

    end;
end;


// *************************************************
//         CALCULATE BOARD WIDTH, HEIGHT
// *************************************************

procedure TgrGerberImport.FindBoardSize;
var
    i: Integer;
    Strip : TgrStrip;
    Segment : TgrSegment;
    StripCellX, StripCellY : integer;
    X, Y : single;
    SegmentCellX, SegmentCellY : integer;


begin
    // find highest x and y coords in strip cells
    StripCellX := 0;
    StripCellY := 0;
    for i := 0 to StripCount - 1 do begin
        Strip := Strips[i];
        StripCellX := Max( StripCellX, Strip.CellX1 );
        StripCellX := Max( StripCellX, Strip.CellX2 );
        StripCellY := Max( StripCellY, Strip.CellY1 );
        StripCellY := Max( StripCellY, Strip.CellY2 );
    end;

    // add 1 cell to convert highest cell index to width
    StripCellX := StripCellX + 1;
    StripCellY := StripCellY + 1;

    // find highest x and y coords in strips
    X := 0.0;
    Y := 0.0;

    for i := 0 to SegmentCount - 1 do begin
        Segment := Segments[i];
        X := Max( X, Segment.X1 + (Segment.Width * 0.5) );
        X := Max( X, Segment.X2 + (Segment.Width * 0.5) );
        Y := Max( Y, Segment.Y1 + (Segment.Width * 0.5) );
        Y := Max( Y, Segment.Y2 + (Segment.Width * 0.5) );
    end;

    // add offset to centre of cell
    X := X + 0.05;
    Y := Y + 0.05;

    // convert inch coords to cells
    SegmentCellX := Ceil( X * 10.0 );
    SegmentCellY := Ceil( Y * 10.0 );

    // convert x, y to cells
    Width := Max( StripCellX, SegmentCellX );
    Height := Max( StripCellY, SegmentCellY );
end;



// copy to TbrBoard object
procedure TgrGerberImport.TransferToBoard( Board : TbrBoard );
var
    i : integer;
    Strip : TgrStrip;
    BoardStrip : TbrRawStrip;
    Segment : TgrSegment;
//    BoardSegment :
begin
    Board.Pattern := ptDefined;

    // measure board width, height


    //Board.Width := ??
    //Board.Height :=

    // transfer tracks to board
    for i := 0 to StripCount - 1 do begin
        Strip := Strips[i];
        BoardStrip := Board.CreateNewRawStrip;
        BoardStrip.Start.X := Strip.CellX1;
        BoardStrip.Start.Y := Strip.CellY1;
        BoardStrip.Finish.X := Strip.CellX2;
        BoardStrip.Finish.Y := Strip.CellY2;
    end;

    // create segments (units are cells/1000)
    // Move segments half a cell across and down - so point sit in middle of
    // the cell. This is due to the difference between Cell coords (cell centre)
    // and sub-cell cords.
    for i := 0 to SegmentCount - 1 do begin
        Segment := Segments[i];
        Board.AddSegment(

            Round(Segment.X1 * 10000.0),
            Round(Segment.Y1 * 10000.0),
            Round(Segment.X2 * 10000.0),
            Round(Segment.Y2 * 10000.0),
            Round(Segment.Width * 10000.0)

{
            Round((Segment.X1 + 0.05) * 10000.0),
            Round((Segment.Y1 + 0.05) * 10000.0),
            Round((Segment.X2 + 0.05) * 10000.0),
            Round((Segment.Y2 + 0.05) * 10000.0),
            Round(Segment.Width * 10000.0)
}
        );
    end;

    Board.Width := Max( Width, 10);
    Board.Height := Max( Height, 10);
end;


// *************************************************
//       IMPORT GERBER FILE & CONVERT TO BOARD
// *************************************************

procedure TgrGerberImport.ReadFileToBoard( const FileName : string; Board : TbrBoard );
var
    S : TStringStream;
begin
    // read Gerber file using a TStringStream object
    S := TStringStream.Create;
    try
        S.LoadFromFile( FileName );
        FText := S.DataString;
    finally
        S.Free;
    end;

    // parse text into tracks, reporting any error lines
    try
        ParseGerberText;
    except
        on E : Exception do begin
            raise Exception.CreateFmt(
                'Error on line %d: %s', [ErrorLineNo, E.Message] );
        end;
    end;

    // convert tracks to strips and segments
    ExtractStripsAndSegments;
    SnapToGrid;
    CleanStrips;

    // load data into a board
    FindBoardSize;
    TransferToBoard( Board );
end;


end.

