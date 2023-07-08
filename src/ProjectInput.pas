unit ProjectInput;

interface

uses Project, Rotations, Classes, SysUtils, JsonParse;

type
   TProjectInputLoader = class

private
    FProject : TveProject;

    FProduct : integer;
    FFileCompatibility : integer;

    JSON : TJsonParser;

    function AngleToRotation( Angle : integer ) : TRotation;

    procedure LoadVersion( S : TStrings );
    procedure ParseProject;
    procedure ParseConfig;
    procedure ParseBoard;
    procedure ParseStrips;
    procedure ParseSegments;
    procedure ParseHoles;
    procedure ParseCelledOutlines;
    procedure ParseCelledOutline;
    procedure ParseLeadedOutlines;
    procedure ParseRadialOutlines;
    procedure ParseCustomOutlines;
    procedure ParseSmdOutlines;
    procedure ParseComponents;
    procedure ParseLinks;
    procedure ParseBreaks;
    procedure ParseWires;
    procedure ParseTexts;
    procedure ParseNets;
    procedure ParseNetColors;
    procedure ParseNotes;

    procedure ParseStateError;
    procedure KeyError;


public
    constructor Create( Project : TveProject );
    destructor Destroy; override;

    procedure LoadFromStream( Stream : TStream );
    procedure LoadFromFile( FileName : string );
end;

implementation

uses ParseCsv, Outlines, CelledOutlines, SizeableOutlines,
OtherOutlines, RadialOutlines, CustomOutlines, SmdOutlines, Netlist,
ProjectInputCSV, Board, Types, ExceptSafe;

type ESafeProjectInput = class( ESafe );

// Utility function
function TProjectInputLoader.AngleToRotation( Angle : integer ) : TRotation;
begin
    case Angle of
        0 : result := Rot0;
        90 : result := Rot90;
        180 : result := Rot180;
        270 : result := Rot270;
        else begin
            raise ESafeProjectInput.CreateFmt(
            'Non standard angle "%d" on line %d', [ Angle, JSON.Scanline] );
        end;
    end;
end;

(* Product versions
    version 1 : original release

    version 2 : V 1.1.2.0
        code can now rotate links, so to prevent previous code
        versions from opening files with rotated links, move to ver 2.
        File format unchanged, because links already had rotation field.
*)

// define VeeCAD products which are accepted by this program
const PRODUCT_1 = 1;    // VCAD (V1)
const PRODUCT_2 = 2;    // VeeCAD (V2)

// array of VeeCAD 1 file versions which are accepted by this program
const Product1Versions : array[0..2] of integer = ( 1, 2, 1000 );

// array of VeeCAD 2 file versions which are accepted by this program
// V5 sizeable TveRadialOutlines
// V6 text component
// V7 large/small characters for text component
// V8 text pin names
// V9 unicode UTF-8 project file
// V10 JSON UTF8 file format.
// V11 definable strip patterns
// V12 diagonal placement of sizeable outlines
// V13 Grouping of board outlines
// V14 track breaks shifted Down
// V15 text component size saved (supposed to be saved, but forgot to write code)
// V16 saving & reading Board.TrackRect. "HoleArrays" removed from board.
// V17 read names of nets to be colored.
// V18 increase to 6 (was 4) number net names to be colored.
// V19 save & read Notes Lines.


const Product2Versions : array[0..18] of integer =
    ( 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 );

function GotoSection(
    Source : TStrings; var LineIndex : integer; const Section : string ) : boolean;
begin
    LineIndex := Source.IndexOf( '[' + Section + ']' );
    result := LineIndex <> -1;
end;

function GetNextLine( Source : TStrings; var LineIndex : integer; var Line : string ) : boolean;
var
    i : integer;
    TestLine : string;
begin
    for i := LineIndex +1 to Source.Count -1 do begin
        TestLine := Source[i];

        // if line is blank, skip it
        if TestLine = '' then begin
            continue;
        end;

        // if next section : ie [Name], then end of section, return false
        if TestLine[1] = '[' then begin
            result := False;
            exit;
        end;

        // if non-blank line, found next information line
        result := True;
        LineIndex := i;
        Line := TestLine;
        exit;
    end;
    // no line found
    result := False;
end;

constructor TProjectInputLoader.Create( Project : TveProject );
begin
    FProject := Project;
end;

destructor TProjectInputLoader.Destroy;
begin
    inherited;
end;


procedure TProjectInputLoader.ParseStateError;
begin
    raise ESafeProjectInput.CreateFmt( 'Unknown parse state "%s" on line %d',
          [ JSON.ParseStateString, JSON.Scanline ] );
end;

procedure TProjectInputLoader.KeyError;
begin
    raise ESafeProjectInput.CreateFmt( 'Unknown key "%s" with data type "%s" on line %d',
          [ JSON.Key, JSON.ParseStateString, JSON.Scanline ] );
end;


procedure TProjectInputLoader.LoadFromStream( Stream : TStream );
var
    Size: Integer;
    Header : ansistring;
    Lines : TStringList;
    LoaderCSV : TProjectInputLoaderCSV;

    SS : TStringStream;
    Offset : integer;
begin
    // clear components
    FProject.Clear;

    Lines := TStringList.Create;
    try
        // read first part of stream into buffer
        SetLength( Header, 30 );
        Size := Stream.Read( Header[1], 30 );

        // we need 30 chars at least
        if Size < 30 then begin
            raise ESafeProjectInput.Create( 'Header too short.'  );
        end;

        // read just header as ansi
        Lines.Text := String( Header );

        // extract the version info: it reads the same for Ansi or Utf8 files
        LoadVersion( Lines );
    finally
        Lines.Free;
    end;

    // rewind stream ready for full input
    Stream.Position := 0;

    // old CSV versions are handled by legacy input class
    if FFileCompatibility < 10 then begin
        LoaderCSV := TProjectInputLoaderCSV.Create( FProject );
        try
            // simple board with strips
            FProject.Board.Clear;
            FProject.Board.Pattern := ptStrip;

            // version 9 used UTF8 encoding
            if FFileCompatibility = 9 then begin
                LoaderCSV.LoadFromStream( Stream, TEncoding.UTF8 );
            end
            // earlier versions used ANSII encoding
            else begin
                LoaderCSV.LoadFromStream( Stream, TEncoding.Default );
            end;
            FProject.Board.Prepare;
        finally
            LoaderCSV.Free;
        end;
        exit;
    end;

    // versions 10 and greater are handled by JSON with UTF8 encoding
    JSON := TJsonParser.Create;
    try
        SS := TStringStream.Create( '', TEncoding.UTF8 );
        try
            SS.CopyFrom( Stream, Stream.size );
            Offset := Pos( '{', SS.DataString );
            if (Offset < 25) or (Offset > 40) then begin
                raise ESafeProjectInput.Create( 'Can''''t find "{" in text stream.' );
            end;

            JSON.Text := SS.DataString;
            JSON.Reset;
            // tell JSON parser to start AFTER csv header
            JSON.ScanIndex := Offset;
            ParseProject;
            // build project group records
            FProject.RegisterGroups;
        finally
            SS.Free;
        end;
    finally
        JSON.Free;
    end;
end;


procedure TProjectInputLoader.LoadFromFile( FileName : string );
var ProjectFile : TFileStream;
begin
    FProject.Clear;
    ProjectFile := TFileStream.Create( FileName, fmOpenRead	);
    try
        LoadFromStream( ProjectFile );
    except
        on E : Exception do begin
            ProjectFile.Free;
            // add filename to message
            raise ESafeProjectInput.Create( E.Message + '. File: ' + FileName );
        end;
    end;
    ProjectFile.Free;
end;


procedure TProjectInputLoader.LoadVersion( S : TStrings );
var
    LineIndex : integer;
    Line : string;
    Index : integer;
    Cell_0, Cell_1 : string;
    Product : string;
    FileCompatibility : string;

    i : integer;
    VersionCompatible : boolean;
begin
//    LineOut( '[Version]', S );
//    LineOut( 'Product,VeeCAD', S );
//    LineOut( 'File,1', S );

    // earliest files have no version info
    if not GotoSection( S, LineIndex, 'Version' ) then begin
        raise ESafeProjectInput.Create( 'No file version information found' );

    // this code permits read of early files with no version info
//        FFileCompatibility := 1;
//        FProduct := 1;
    end

    else begin
        while GetNextLine( S, LineIndex, Line ) do begin

            Index := 0;
            ParseCsvValue( Line, Cell_0, Index );
            ParseCsvValue( Line, Cell_1, Index );

            // "Product,1"
            if Cell_0 = 'Product' then begin
                Product := Cell_1;
                FProduct := StrToIntDef( Cell_1, -1 );
            end

            // "File,1"
            else if Cell_0 = 'File' then begin
                FileCompatibility := Cell_1;
                FFileCompatibility := StrToIntDef( Cell_1, -1 );
            end;
        end;
    end;

    // for Product 1 (free version)
    if FProduct = PRODUCT_1 then begin

        VersionCompatible := False;
        for i := low(Product1Versions) to high(Product1Versions) do begin
            if Product1Versions[i] = FFileCompatibility then begin
                VersionCompatible := True;
                break;
            end;
        end;
    end


    // for Product 2 (commercial version)
    else if FProduct = PRODUCT_2 then begin

        VersionCompatible := False;
        for i := low(Product2Versions) to high(Product2Versions) do begin
            if Product2Versions[i] = FFileCompatibility then begin
                VersionCompatible := True;
                break;
            end;
        end;

    end

    // we don't know this product: Exception right here
    else begin
        raise ESafeProjectInput.CreateFmt(
        'File Product number "%s" belongs to a different or later VeeCAD product'
        , [Product]);
    end;

    // Product was OK, so report if Version not Compatible
    if not VersionCompatible then begin
        raise ESafeProjectInput.CreateFmt(
        'File version "%s" requires a later release of VeeCAD',
        [FileCompatibility]
        );
    end;
end;

procedure TProjectInputLoader.ParseProject;
begin
    // opening outermost object
    if (not JSON.Scan) or (JSON.ParseState <> psObject) then begin
       raise ESafeProjectInput.Create( 'Missing "{" at start of project' );
    end;

    // scan  Objects that make our file
    while JSON.Scan do begin
        case JSON.ParseState of

            psObject : begin

                if JSON.Key = 'Config' then begin
                    ParseConfig;
                end
                else if JSON.Key = 'Board' then begin
                    ParseBoard;
                end
                else if JSON.Key = 'Notes' then begin
                    ParseNotes;
                end
                else begin
                    raise ESafeProjectInput.CreateFmt(
                        'Unexpected Object key "%s" on line %d', [JSON.Key, JSON.Scanline] );
                end;
            end;

            psArray : begin
                if JSON.Key = 'CelledOutlines' then begin
                    ParseCelledOutlines;
                end
                else if JSON.Key = 'LeadedOutlines' then begin
                    ParseLeadedOutlines;
                end
                else if JSON.Key = 'RadialOutlines' then begin
                    ParseRadialOutlines;
                end
                else if JSON.Key = 'CustomOutlines' then begin
                    ParseCustomOutlines;
                end
                else if JSON.Key = 'SmdOutlines' then begin
                    ParseSmdOutlines;
                end
                else if JSON.Key = 'Components' then begin
                    ParseComponents;
                end
                else if JSON.Key = 'Links' then begin
                    ParseLinks;
                end
                else if JSON.Key = 'Breaks' then begin
                    ParseBreaks;
                end
                else if JSON.Key = 'Wires' then begin
                    ParseWires;
                end
                else if JSON.Key = 'Text' then begin
                    ParseTexts;
                end
                else if JSON.Key = 'Nets' then begin
                    ParseNets;
                end
                else if JSON.Key = 'NetColors' then begin
                    ParseNetColors;
                end
                else begin
                    raise ESafeProjectInput.CreateFmt(
                        'Unexpected array token "%s" on line %d', [JSON.Token, JSON.Scanline] );
                end;
            end;

            // end of JSON outer object
            psEndObject : begin
            end;
        end;
    end;

    if JSON.ParseState <> psEnd then begin
        raise ESafeProjectInput.Create(
            'Project text corrupted or truncated at end.' );
    end;
end;


procedure TProjectInputLoader.ParseConfig;
begin
    while JSON.Scan do begin
        case JSON.ParseState of

            psValueString : begin
                if JSON.Key = 'NetImportFormat' then begin
                    FProject.NetlistImportFormat := JSON.ValueString;
                end
                else begin
                    KeyError;
                end;
            end;
            psEndObject : begin
                exit;
            end
            else begin
                ParseStateError;
            end;
        end;
    end;
end;

(*
"Board" : {
  "Width" : 23,
  "Height" : 28,
  "Strips" : [
      { "X1" : 2,  "Y1" : 2, "X2" : 2, "Y2" : 9 },
      { "X1" : 2,  "Y1" : 3, "X2" : 16, "Y2" : 3 },
      { "X1" : 0,  "Y1" : 2, "X2" : 22, "Y2" : 2 },
      { "X1" : 0,  "Y1" : 3, "X2" : 22, "Y2" : 3 },
      { "X1" : 0,  "Y1" : 4, "X2" : 22, "Y2" : 4 },
      { "X1" : 0,  "Y1" : 5, "X2" : 22, "Y2" : 5 }
  ]
},
*)
procedure TProjectInputLoader.ParseBoard;

    function StrToPattern( const s : string ) : TbrPattern;
    begin
        if s = 'Strip' then begin
            result := ptStrip;
        end
        else if s = 'Donut' then begin
            result := ptDonut;
        end
        else if s = 'Tripad' then begin
            result := ptTripad;
        end
        else if s = 'Defined' then begin
             result := ptDefined;
        end else begin
            raise ESafeProjectInput.CreateFmt(
                'unknown pattern "%s" on line %d', [s, JSON.Scanline] );
        end;
    end;
var
    Defined : boolean;
begin
    FProject.Board.Clear;

    // default pattern is standard stripboard
    // versions 11 onward can override this by defining stripsets
    // ..no strips or segmentsdefined yet
    Defined := False;

    // initial pattern does not matter, but ptDefined is faster than ptStrip
    // when Height, Width are called.
    FProject.Board.Pattern := ptDefined;

    while JSON.Scan do begin
        case JSON.ParseState of

            psValueInteger : begin
                if JSON.Key = 'Width' then begin
                    FProject.Board.Width := JSON.ValueInteger;
                end
                else if JSON.Key = 'Height' then begin
                    FProject.Board.Height := JSON.ValueInteger;
                end
                else begin
                    KeyError;
                end;
            end;
            psValueString : begin
                if JSON.Key = 'Pattern' then begin
                    FProject.Board.Pattern := StrToPattern(JSON.ValueString);
                    Defined := True;
                end
                else begin
                    KeyError;
                end;
            end;
            psArray : begin
                if JSON.Key = 'Strips' then begin
                    // in versions pre V14, defined patterns are implicit if
                    // Strips[] exists
                    FProject.Board.Pattern := ptDefined;
                    Defined := True;
                    ParseStrips;
                end
                else if JSON.Key = 'Segments' then begin
                    Defined := True;
                    ParseSegments;
                end
                else if JSON.Key = 'HoleArrays' then begin
                    Defined := True;
                    ParseHoles;
                end;
            end;
            psEndObject : begin
                break;
            end
            else begin
                ParseStateError;
            end;
        end;
    end;

    // if no pattern read from file, default to Strip pattern, because
    // this handles early versions pre-defined patterns.
    if not Defined then begin
        FProject.Board.Pattern := ptStrip;
    end;

    // patterns must be prepared after loading
    FProject.Board.Prepare;
end;

procedure TProjectInputLoader.ParseStrips;
var
    Strip : TbrRawStrip;


    procedure ParseStrip;
    begin
        // start strip
        Strip := FProject.Board.CreateNewRawStrip;

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueInteger : begin
                    if JSON.Key = 'X1' then begin
                        Strip.Start.X := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y1' then begin
                        Strip.Start.Y := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'X2' then begin
                        Strip.Finish.X := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y2' then begin
                        Strip.Finish.Y := JSON.ValueInteger;
                    end;
                end;
                // A StripSet is an array - look for end
                psEndObject : begin
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin
    while JSON.Scan do begin
        case JSON.ParseState of

            psObject : begin
                ParseStrip;
            end;
            // Strips is an array - look for end
            psEndArray : begin
                exit;
            end
            else begin
                ParseStateError;
            end;
        end;
    end;
end;

procedure TProjectInputLoader.ParseSegments;

    procedure ParseSegment;
    var
        X1_1000, Y1_1000, X2_1000, Y2_1000, Width_1000 : integer;
    begin
        X1_1000 := 0;
        Y1_1000 := 0;
        X2_1000 := 1000;
        Y2_1000 := 1000;
        Width_1000 := 1000;

        // start strip
        while JSON.Scan do begin
            case JSON.ParseState of
                psValueInteger : begin
                    if JSON.Key = 'X1_1000' then begin
                        X1_1000 := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y1_1000' then begin
                        Y1_1000 := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'X2_1000' then begin
                        X2_1000 := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y2_1000' then begin
                        Y2_1000 := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Width_1000' then begin
                        Width_1000 := JSON.ValueInteger;
                    end;
                end;
                // A StripSet is an object - look for end
                psEndObject : begin
                    FProject.Board.AddSegment
                        (X1_1000, Y1_1000, X2_1000, Y2_1000, Width_1000);
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin
    while JSON.Scan do begin
        case JSON.ParseState of

            psObject : begin
                ParseSegment;
            end;
            // Strips is an array - look for end
            psEndArray : begin
                exit;
            end
            else begin
                ParseStateError;
            end;
        end;
    end;
end;


// ** HOLE ARRAYS are discontinued from V16 and later, so we parse the
// data, but do nothing with it.
procedure TProjectInputLoader.ParseHoles;

    procedure ParseHoleArray;
{
    var
        Left, Top, Right, Bottom : integer;
}
    begin
{
        // in case a value is missing, initialise to zero
        Left := 0;
        Top := 0;
        Right := 0;
        Bottom := 0;
}
        // start hole block
        while JSON.Scan do begin
            case JSON.ParseState of
                psValueInteger : begin
{
                    if JSON.Key = 'Left' then begin
                        Left := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Top' then begin
                        Top := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Right' then begin
                        Right := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Bottom' then begin
                        Bottom := JSON.ValueInteger;
                    end
}
                end;
                // HoleArray is a object - look for end
                psEndObject : begin
                    // do nothing with hole data
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;
begin
    while JSON.Scan do begin
        case JSON.ParseState of

            psObject : begin
                ParseHoleArray;
            end;
            // HoleArrays is an array - look for end
            psEndArray : begin
                exit;
            end
            else begin
                ParseStateError;
            end;
        end;
    end;

end;


procedure TProjectInputLoader.ParseCelledOutlines;
begin
    while JSON.Scan do begin
        case JSON.ParseState of

            // celled outlines is an array of objects - each object in one outline
            psObject : begin
                ParseCelledOutline;
            end;

            // celled outlines is an array - look for end
            psEndArray : begin
                exit;
            end
            else begin
                ParseStateError;
            end;
        end;
    end;
end;

procedure TProjectInputLoader.ParseCelledOutline;
var
    Outline : TveCellOutline;
    CellX, CellY : integer;

    procedure ParsePin;
    begin
        while JSON.Scan do begin
          case JSON.ParseState of
              psValueString : begin
                  if JSON.Key = 'Pin' then begin
                        Outline.CellTypes[CellX,CellY] := ctPin;
                        Outline.CellPinNames[CellX,CellY] := JSON.ValueString;
                  end
                  else begin
                      KeyError;
                  end;
              end;
              psEndObject : exit;
              else begin
                  ParseStateError;
              end;
          end;
        end;
    end;


    // row looks like this
    // [ "Free",{"Pin" : "2"},"Body" ]
    procedure ParseRow;
    begin
        // add row here ::

        // start filling from left
        CellX := 0;

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    if JSON.ValueString = 'Body' then begin
                        Outline.CellTypes[CellX,CellY] := ctBody;
                        Inc( CellX );
                    end
                    else if JSON.ValueString = 'Free' then begin
                        Outline.CellTypes[CellX,CellY] := ctFree;
                        Inc( CellX );
                    end
                    else begin
                        KeyError;
                    end;
                end;

                psObject : begin
                    ParsePin;
                    Inc( CellX );
                end;

                psEndArray : exit;

                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParseRows;
    begin
        // start filling cells from top
        CellY := 0;

        while JSON.Scan do begin
            case JSON.ParseState of
                psArray : begin
                    ParseRow;
                    // move to next row
                    Inc( CellY );
                end;
                psEndArray : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin

    // setup the outline
    Outline := TveCellOutline.Create;
    FProject.AddOutline( Outline );

    while JSON.Scan do begin
        case JSON.ParseState of

            // a celled outline is an object
            psValueString : begin
                if JSON.Key = 'Name' then begin
                    Outline.Name := JSON.ValueString;
                end
                else begin
                    KeyError;
                end;
            end;

            psValueBoolean : begin
                if JSON.Key = 'Locked' then begin
                    Outline.NoImport := JSON.ValueBoolean;
                end
                else begin
                    KeyError;
                end;
            end;

            // array of pins
            psArray : begin
                if JSON.Key = 'Rows' then begin
                    ParseRows;
                end
                else begin
                    KeyError;
                end;
            end;

            // celled outlines is an array - look for end
            psEndObject : begin
                exit;
            end
            else begin
                ParseStateError;
            end;
        end;
    end;
end;
(*
  { "Name" : "C_3", "Locked" : false,
    "BodyLength" : 1, "BodyWidth" : 1,
    "Pin0Name" : "1", "Pin1Name" : "2", "ShowReference" : true
  },
*)

procedure TProjectInputLoader.ParseLeadedOutlines;

    procedure ParseLeadedOutline;
    var
        Leaded : TveLeadedOutline;
    begin
        // create the leaded component
        Leaded := TveLeadedOutline.Create;
        FProject.AddOutline( Leaded );

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    if JSON.Key = 'Name' then begin
                        Leaded.Name := JSON.ValueString;
                    end
                    else if JSON.Key = 'Pin0Name' then begin
                        Leaded.Pins[0].Name := JSON.ValueString;
                    end
                    else if JSON.Key = 'Pin1Name' then begin
                        Leaded.Pins[1].Name := JSON.ValueString;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueInteger : begin
                    if JSON.Key = 'BodyLength' then begin
                        Leaded.BodyLength := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'BodyWidth' then begin
                        Leaded.BodyWidth := JSON.ValueInteger;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueBoolean : begin
                    if JSON.Key = 'Locked' then begin
                        Leaded.NoImport := JSON.ValueBoolean;
                    end
                    else if JSON.Key = 'ShowReference' then begin
                        Leaded.ShowReference := JSON.ValueBoolean;
                    end
                    else begin
                        keyError;
                    end;
                end;

                psEndObject : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin
    while JSON.Scan do begin
        case JSON.ParseState of
            psObject : ParseLeadedOutline;
            psEndArray : exit;
            else begin
                ParseStateError;
            end;
        end;
    end;
end;


procedure TProjectInputLoader.ParseRadialOutlines;
    procedure ParseRadialOutline;
    var
        Radial : TveRadialOutline;
    begin
        // create the leaded component
        Radial := TveRadialOutline.Create;
        FProject.AddOutline( Radial );

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    if JSON.Key = 'Name' then begin
                        Radial.Name := JSON.ValueString;
                    end
                    else if JSON.Key = 'Pin0Name' then begin
                        Radial.Pins[0].Name := JSON.ValueString;
                    end
                    else if JSON.Key = 'Pin1Name' then begin
                        Radial.Pins[1].Name := JSON.ValueString;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueInteger : begin
                    if JSON.Key = 'LeadSpacing' then begin
                        Radial.LeadSpacing := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Diameter' then begin
                        Radial.Diameter := JSON.ValueInteger;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueBoolean : begin
                    if JSON.Key = 'Locked' then begin
                        Radial.NoImport := JSON.ValueBoolean;
                    end
                    else begin
                        KeyError;
                    end;
                end;

                psEndObject : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin
    while JSON.Scan do begin
        case JSON.ParseState of
            psObject : ParseRadialOutline;
            psEndArray : exit;
            else begin
                ParseStateError;
            end;
        end;
    end;
end;

procedure TProjectInputLoader.ParseCustomOutlines;
var
    Custom : TveCustomOutline;

    procedure ParsePin;
    var
        Pin : TcoPin;
    begin
        Pin := Custom.CreatePin;
        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    if JSON.Key = 'Name' then begin
                        Pin.Name := JSON.ValueString;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueInteger : begin
                    if JSON.Key = 'X5' then begin
                        Pin.SubX := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y5' then begin
                        Pin.SubY := JSON.ValueInteger;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParsePins;
    begin
        while JSON.Scan do begin
            case JSON.ParseState of
                psObject : ParsePin;
                psEndArray : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParseLine;
    var
        Line : TcoLine;
    begin
        Line := Custom.CreateLine;

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueInteger : begin
                    if JSON.Key = 'X5' then begin
                        Line.SubX := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y5' then begin
                        Line.SubY := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'DX5' then begin
                        Line.EndDeltaSubX := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'DY5' then begin
                        Line.EndDeltaSubY := JSON.ValueInteger;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParseLines;
    begin
        while JSON.Scan do begin
            case JSON.ParseState of
                psObject : ParseLine;
                psEndArray : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParseCustomOutline;
    begin
        // create the leaded component
        Custom := TveCustomOutline.Create;
        FProject.AddOutline( Custom );

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    if JSON.Key = 'Name' then begin
                        Custom.Name := JSON.ValueString;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueBoolean : begin
                    if JSON.Key = 'Locked' then begin
                        Custom.NoImport := JSON.ValueBoolean;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psArray : begin
                    if JSON.Key = 'Pins' then begin
                        ParsePins;
                    end
                    else if JSON.Key = 'Lines' then begin
                        ParseLines;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin
    while JSON.Scan do begin
        case JSON.ParseState of
            psObject : ParseCustomOutline;
            psEndArray : exit;
            else begin
                ParseStateError;
            end;
        end;
    end;
end;


procedure TProjectInputLoader.ParseSmdOutlines;
var
    Smd : TveSmdOutline;

    procedure ParsePin;
    var
        Pin : TsmPin;
    begin
        Pin := Smd.CreatePin;
        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    if JSON.Key = 'Name' then begin
                        Pin.Name := JSON.ValueString;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueInteger : begin
                    if JSON.Key = 'X1000' then begin
                        Pin.XDiv := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y1000' then begin
                        Pin.YDiv := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Width1000' then begin
                        Pin.WidthDiv := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Height1000' then begin
                        Pin.HeightDiv := JSON.ValueInteger;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParsePins;
    begin
        while JSON.Scan do begin
            case JSON.ParseState of
                psObject : ParsePin;
                psEndArray : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParseLine;
    var
        Line : TsmLine;
    begin
        Line := Smd.CreateLine;

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueInteger : begin
                    if JSON.Key = 'X1000' then begin
                        Line.XDiv := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y1000' then begin
                        Line.YDiv := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'DX1000' then begin
                        Line.EndDeltaXDiv := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'DY1000' then begin
                        Line.EndDeltaYDiv := JSON.ValueInteger;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParseLines;
    begin
        while JSON.Scan do begin
            case JSON.ParseState of
                psObject : ParseLine;
                psEndArray : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParseSmdOutline;
    begin
        // create the leaded component
        Smd := TveSmdOutline.Create;
        FProject.AddOutline( Smd );

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    if JSON.Key = 'Name' then begin
                        Smd.Name := JSON.ValueString;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueBoolean : begin
                    if JSON.Key = 'Locked' then begin
                        Smd.NoImport := JSON.ValueBoolean;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psArray : begin
                    if JSON.Key = 'Pins' then begin
                        ParsePins;
                    end
                    else if JSON.Key = 'Lines' then begin
                        ParseLines;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin
    while JSON.Scan do begin
        case JSON.ParseState of
            psObject : ParseSmdOutline;
            psEndArray : exit;
            else begin
                ParseStateError;
            end;
        end;
    end;
end;


(*
"Components" : [
  { "Designator" : "C101", "Value" : "2200uF 16V", "Outline" : "ELECTRO_B",
  "XY" : [116,9], "Angle" : 180, "Length" : 3,
  "Text" : { "XY" : [0,1], Angle : 0, Visible : true }
  },
*)

procedure TProjectInputLoader.ParseComponents;
var
    Component : TveBoardItem;

    procedure ParseText;
    begin
        while JSON.Scan do begin
            case JSON.ParseState of
                psValueInteger : begin
                    if JSON.Key = 'X' then begin
                        Component.TextX := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y' then begin
                        Component.TextY := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Angle' then begin
                        Component.TextRotation := AngleToRotation( JSON.ValueInteger );
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueBoolean : begin
                    if JSON.Key = 'Visible' then begin
                        Component.TextVisible := JSON.ValueBoolean;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject : begin
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParseComponent;
    var
        Outline : string;
    begin
        Component := TveBoardItem.Create;
        // dummy outline for now - in case of exception
        Component.Outline := FProject.DummyOutline;
        FProject.AddBoardItem( Component );

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    if JSON.Key = 'Designator' then begin
                        Component.Designator := JSON.ValueString;
                    end
                    else if JSON.Key = 'Value' then begin
                        Component.Value := JSON.ValueString;
                    end
                    else if JSON.Key = 'Outline' then begin
                        Outline := JSON.ValueString;
                        Component.Outline := FProject.OutlineByName( Outline );
                        if Component.Outline = nil then begin
                            Component.Outline := FProject.AddDefaultOutline;
                            Component.Outline.Name := Outline;
                        end;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueInteger : begin
                    if JSON.Key = 'X1000' then begin
                        Component.XDiv := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y1000' then begin
                        Component.YDiv := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'X' then begin
                        Component.X := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y' then begin
                        Component.Y := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'EndDeltaX' then begin
                        Component.EndDeltaX := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'EndDeltaY' then begin
                        Component.EndDeltaY := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Angle' then begin
                        Component.Rotation := AngleToRotation( JSON.ValueInteger );
                    end
                    else if JSON.Key = 'Length' then begin
                        Component.Length := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Group' then begin
                        Component.Group := JSON.ValueInteger;
                    end
                    else begin
                        KeyError;
                    end;
                end;

                psObject : begin
                    if JSON.Key = 'Text' then begin
                        ParseText;
                    end
                    else begin
                        KeyError;
                    end;
                end;

                psEndObject : exit;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin
    while JSON.Scan do begin
        case JSON.ParseState of
            psObject : ParseComponent;
            psEndArray : exit;
            else begin
                ParseStateError;
            end;
        end;
    end;
end;


procedure TProjectInputLoader.ParseLinks;

    procedure ParseLink;
    var
        Link : TveBoardItem;
    begin
        Link := TveBoardItem.Create;
        Link.Outline := FProject.LinkOutline;
        FProject.AddBoardItem( Link );

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueInteger: begin
                    if JSON.Key = 'X' then begin
                        Link.X := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y' then begin
                        Link.Y := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'EndDeltaX' then begin
                        Link.EndDeltaX := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'EndDeltaY' then begin
                        Link.EndDeltaY := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Angle' then begin
                        Link.Rotation := AngleToRotation( JSON.ValueInteger );
                    end
                    else if JSON.Key = 'Length' then begin
                        Link.Length := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Group' then begin
                        Link.Group := JSON.ValueInteger;
                    end
                    else begin
                        KeyError;
                    end
                end;
                psEndObject: begin
                    exit;
                end;
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;
begin
    while JSON.Scan do begin
        case JSON.ParseState of
            psObject : ParseLink;
            psEndArray : exit;
            else begin
                ParseStateError;
            end;
        end;
    end;
end;

procedure TProjectInputLoader.ParseBreaks;

    function StrToShift( const s : string ) : TveShift;
    begin
        if s = 'right' then begin
            result := shRight;
        end
        else if s = 'down' then begin
            result := shDown;
        end
        // default to no shift
        else begin
            result := shNone;
        end;
    end;

    const Bool2Shift : array[boolean] of TveShift = ( shNone, shRight );

    procedure ParseBreak;
    var
        Break : TveBoardItem;
    begin
        Break := TveBoardItem.Create;
        Break.Outline := FProject.BreakOutline;
        FProject.AddBoardItem( Break );

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueInteger: begin
                    if JSON.Key = 'X' then begin
                        Break.X := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y' then begin
                        Break.Y := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Group' then begin
                        Break.Group := JSON.ValueInteger;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueString: begin
                    if JSON.Key = 'Shift' then begin
                        Break.Shift := StrToShift( JSON.ValueString );
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueBoolean: begin
                    // old shifted could only shift right: "true" or "false"
                    if JSON.Key = 'Shifted' then begin
                        Break.Shift := Bool2Shift[ JSON.ValueBoolean ];
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject: begin
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;

    end;

begin
    while JSON.Scan do begin
        case JSON.ParseState of
            psObject : ParseBreak;
            psEndArray : exit;
            else begin
                ParseStateError;
            end;
        end;
    end;
end;

procedure TProjectInputLoader.ParseWires;
    procedure ParseWire;
    var
        Wire : TveBoardItem;
    begin
        Wire := TveBoardItem.Create;
        Wire.Outline := FProject.WireOutline;
        FProject.AddBoardItem( Wire );

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueInteger: begin
                    if JSON.Key = 'X' then begin
                        Wire.X := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y' then begin
                        Wire.Y := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Group' then begin
                        Wire.Group := JSON.ValueInteger;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueString : begin
                    if JSON.Key = 'Value' then begin
                        Wire.Value := JSON.ValueString;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject: begin
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin
    while JSON.Scan do begin
        case JSON.ParseState of
            psObject : ParseWire;
            psEndArray : exit;
            else begin
                ParseStateError;
            end;
        end;
    end;
end;

procedure TProjectInputLoader.ParseTexts;

    // convert string 'Small', 'Large' to TTextSize
    function StrToSize( s : string ) : TTextSize;
    begin
        if s = 'Large' then begin
            result := tsLarge;
        end
        // default to small
        else begin
            result := tsSmall;
        end;
    end;

    procedure ParseText;
    var
        Text : TveBoardItem;
    begin
        Text := TveBoardItem.Create;
        Text.Outline := FProject.TextOutline;
        FProject.AddBoardItem( Text );

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueInteger: begin
                    if JSON.Key = 'X' then begin
                        Text.X := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Y' then begin
                        Text.Y := JSON.ValueInteger;
                    end
                    else if JSON.Key = 'Angle' then begin
                        Text.Rotation := AngleToRotation( JSON.ValueInteger );
                    end
                    else if JSON.Key = 'Group' then begin
                        Text.Group := JSON.ValueInteger;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psValueString : begin
                    if JSON.Key = 'Value' then begin
                        Text.Value := JSON.ValueString;
                    end
                    else if JSON.Key = 'Size' then begin
                        TveTextOutline(Text.Outline).SetSize( Text, StrToSize( JSON.ValueString ) );
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject: begin
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin
    while JSON.Scan do begin
        case JSON.ParseState of
            psObject : ParseText;
            psEndArray : exit;
            else begin
                ParseStateError;
            end;
        end;
    end;
end;

procedure TProjectInputLoader.ParseNets;
var
    Netlist : TneNetlist;
    Node : TneNode;
    Component : TneComponent;

    procedure ParsePins;
    var
        PinCreated : boolean;
    begin
        PinCreated := False;

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    Netlist.CreatePin( Node, Component, JSON.ValueString );
                    PinCreated := True;
                end;
                psEndArray: begin
                    if not PinCreated then begin
                        raise ESafeProjectInput.CreateFmt(
                        'No pins defined for component on line %d',
                        [ JSON.Scanline ] );
                    end;
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParseComponent;
    var
        ComponentName : string;
    begin
        Component := nil;
        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    if JSON.Key = 'Name' then begin
                        if Component <> nil then begin
                            raise ESafeProjectInput.CreateFmt(
                            'Repeated "Name" key on line %d,',
                            [JSON.Key, JSON.Value, JSON.ScanLine] );
                        end;
                        ComponentName := JSON.ValueString;
                        // get reference to this component
                        Component := Netlist.ComponentByName( ComponentName );
                        if Component = nil then begin
                            Component := Netlist.CreateComponent;
                            Component.Name := ComponentName;
                        end;
                   end
                    else begin
                        KeyError;
                    end;
                end;
                psArray : begin
                    if JSON.Key = 'Pins' then begin

                        if Component = nil then begin
                            raise ESafeProjectInput.CreateFmt(
                            'No "Name" key defined for Pins[] on line %d,',
                            [JSON.Key, JSON.Value, JSON.ScanLine] );
                        end;
                        ParsePins;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject : begin
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

    procedure ParseComponents;
    begin
        while JSON.Scan do begin
            case JSON.ParseState of
                psObject : begin
                    ParseComponent;
                end;
                psEndArray : begin
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;


    procedure ParseNet;
    begin
        Node := Netlist.CreateNode;

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    if JSON.Key = 'Node' then begin
                          Node.Name := JSON.ValueString;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psArray : begin
                    if JSON.Key = 'Components' then begin
                        ParseComponents;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject: begin
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin
    Netlist := FProject.NetList;

    while JSON.Scan do begin
        case JSON.ParseState of
            psObject : ParseNet;
            psEndArray : begin
                FProject.TransferFastNets;
                exit;
            end
            else begin
                ParseStateError;
            end;
        end;
    end;
end;

(*
"NetColors" : [
    { "Net" : "GND" },
    { "Net" : "VCC" },
    { "Net" : "N000001" },
    { "Net" : "N000008" }
]
*)
procedure TProjectInputLoader.ParseNetColors;
var
    Netlist : TneNetlist;
    NodeIndex : integer;

    procedure ParseNetColor;
    var
        NodeName : string;
    begin
        Inc( NodeIndex );

        while JSON.Scan do begin
            case JSON.ParseState of
                psValueString : begin
                    if JSON.Key = 'Node' then begin

                        // ignore nodes surplus to our capacity to store
                        if NodeIndex >= TneNetlist.ColoredNodeCount then begin
                            continue;
                        end;
                        // read Node Name for this ColorIndex
                        NodeName := JSON.ValueString;

                        // save node reference for this node name
                        if NodeName = '' then begin
                            Netlist.ColoredNodes[NodeIndex] := nil;
                        end
                        else begin
                            Netlist.ColoredNodes[NodeIndex] := Netlist.NodeByName( NodeName );
                        end;
                    end
                    else begin
                        KeyError;
                    end;
                end;
                psEndObject: begin
                    exit;
                end
                else begin
                    ParseStateError;
                end;
            end;
        end;
    end;

begin
    Netlist := FProject.NetList;
    NodeIndex := -1;

    while JSON.Scan do begin
        case JSON.ParseState of
            psObject : ParseNetColor;
            psEndArray : exit;
            else begin
                ParseStateError;
            end;
        end;
    end;

end;

(*
"Notes" : {
  "Lines" : "Hello World"
}
*)
procedure TProjectInputLoader.ParseNotes;
begin
    while JSON.Scan do begin
        case JSON.ParseState of
            psValueString : begin
                if JSON.Key = 'Lines' then begin
                    FProject.NotesLines := JSON.ValueString;
                end
            end;
            psEndObject : begin
                break;
            end
            else begin
                ParseStateError;
            end;
        end;
    end;
end;


end.


