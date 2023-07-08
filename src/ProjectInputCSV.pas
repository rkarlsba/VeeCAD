unit ProjectInputCSV;

 interface

uses Project, Classes, SysUtils, ExceptSafe;

type EProjectInput = class( Exception );
     ESafeProjectInput = class( ESafe );

type
   TProjectInputLoaderCSV = class

private
    FProject : TveProject;

    FProduct : integer;
    FFileCompatibility : integer;

    procedure LoadVersion( S : TStrings );
    procedure LoadConfig( S : TStrings );
    procedure LoadBoard( S : TStrings );
    procedure LoadOutlines( S : TStrings );
    procedure LoadLeadedOutlines( S : TStrings );
    procedure LoadRadialOutlines( S : TStrings );
    procedure LoadCustomOutlines( S : TStrings );
    procedure LoadComponents( S : TStrings );
    procedure LoadLinks( S : TStrings );
    procedure LoadBreaks( S : TStrings );
    procedure LoadWires( S : TStrings );
    procedure LoadText( S : TStrings );
    procedure LoadNetlist( S : TStrings );

    procedure LoadComponentsProduct1( S : TStrings );
    procedure LoadComponentsProduct2( S : TStrings );

public
    constructor Create( Project : TveProject );
    destructor Destroy; override;

    procedure LoadFromStreamUTF8( Stream : TStream );
    procedure LoadFromStreamAnsii( Stream : TStream );
    procedure LoadFromStream( Stream : TStream; Encoding : TEncoding );

//    procedure LoadFromFile( FileName : string );
end;

implementation

uses ParseCsv, Outlines, CelledOutlines, SizeableOutlines,
OtherOutlines, RadialOutlines, CustomOutlines, Netlist, Rotations, Board;

// define VeeCAD products which are accepted by this program
const PRODUCT_1 = 1;    // VCAD (V1)
const PRODUCT_2 = 2;    // VeeCAD (V2)

// array of VeeCAD 1 file versions which are accepted by this program
const Product1Versions : array[0..2] of integer = ( 1, 2, 1000 );

// array of VeeCAD 2 file versions which are accepted by this program
// at version 5  we introduced sizeable TveRadialOutlines
// at version 6 we introduced text component
// at version 7 we introduced large/small characters for text component
// at version 8 we introduced text pin names
// at version 9 we introduced unicode UTF-8 project file
const Product2Versions : array[0..8] of integer = ( 1, 2, 3, 4, 5, 6, 7, 8, 9 );


function StrToRotationDef( const s : string; Default : TRotation ) : TRotation;
var
    n : integer;
begin
    n := StrToIntDef( s, integer(Default) );
    if n > 3 then begin
        n := integer(Default);
    end;
    result := TRotation( n );
end;

function StrToBooleanDef( const s : string; Default : boolean ): boolean;
var
    n : integer;
begin
    n := StrToIntDef( s, integer(Default) );
    if n > 1 then begin
        n := integer(Default);
    end;
    result := boolean( n );
end;


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

constructor TProjectInputLoaderCSV.Create( Project : TveProject );
begin
    FProject := Project;
end;

destructor TProjectInputLoaderCSV.Destroy;
begin
    inherited;
end;

procedure TProjectInputLoaderCSV.LoadFromStreamUTF8( Stream : TStream );
begin
    LoadFromStream( Stream, TEncoding.UTF8 );
end;

procedure TProjectInputLoaderCSV.LoadFromStreamAnsii( Stream : TStream );
begin
    LoadFromStream( Stream, TEncoding.Default );
end;

procedure TProjectInputLoaderCSV.LoadFromStream( Stream : TStream; Encoding : TEncoding );
var
    Size: Integer;
    Header : ansistring;
    Lines : TStringList;
begin
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

        // rewind stream ready for full input
        Stream.Position := 0;

        Lines.LoadFromStream( Stream, Encoding );

        LoadConfig( Lines );
        LoadBoard( Lines );
        LoadOutlines( Lines );
        LoadLeadedOutlines( Lines );
        LoadRadialOutlines( Lines );
        LoadCustomOutlines( Lines );
        LoadComponents( Lines );
        LoadLinks( Lines );
        LoadBreaks( Lines );
        LoadWires( Lines );
        LoadText( Lines );
        LoadNetlist( Lines );
    finally
        Lines.Free;
    end;
end;

(*
procedure TProjectInputLoaderCSV.LoadFromFile( FileName : string );
var ProjectFile : TFileStream;
begin
    FProject.Clear;
    ProjectFile := TFileStream.Create( FileName, fmOpenRead	);
    try
        LoadFromStream( ProjectFile );
    finally
        ProjectFile.Free;
    end;
end;
*)

(*
    version 1 : original release

    version 2 : V 1.1.2.0
        code can now rotate links, so to prevent previous code
        versions from opening files with rotated links, move to ver 2.
        File format unchanged, because links already had rotation field.
*)

procedure TProjectInputLoaderCSV.LoadVersion( S : TStrings );
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


procedure TProjectInputLoaderCSV.LoadConfig( S : TStrings );
var
    LineIndex : integer;
    Line : string;
    Index : integer;
    Cell_0, Cell_1 : string;
begin
    // config section is entirely optional
    if not GotoSection( S, LineIndex, 'Config' ) then begin
        exit;
        // raise EProjectInput.Create( 'No config section found' );
    end

    else begin
        while GetNextLine( S, LineIndex, Line ) do begin

            Index := 0;
            ParseCsvValue( Line, Cell_0, Index );
            ParseCsvValue( Line, Cell_1, Index );

            // "NetImportFormat,Protel"
            if Cell_0 = 'NetImportFormat' then begin
                FProject.NetlistImportFormat := Cell_1;
            end
        end;
    end;
end;


procedure TProjectInputLoaderCSV.LoadBoard( S : TStrings );
var
    LineIndex : integer;
    Line : string;

    Cell_0 : string;
    Cell_1 : string;
    Index : integer;
begin
    // only strips in all versions handled by this code
    if not GotoSection( S, LineIndex, 'Board' ) then begin
        exit;
    end;

    while GetNextLine( S, LineIndex, Line ) do begin

        Index := 0;
        ParseCsvValue( Line, Cell_0, Index );
        ParseCsvValue( Line, Cell_1, Index );

        if Cell_0 = 'Width' then begin
            FProject.BoardWidth := StrToIntDef( Cell_1, 20 );
        end
        else if Cell_0 = 'Height' then begin
            FProject.BoardHeight := StrToIntDef( Cell_1, 20 );
        end;
    end;
end;


procedure TProjectInputLoaderCSV.LoadOutlines( S : TStrings );

var
    LineIndex : integer;
    Line : string;
    Cell : string;
    Index : integer;
    X, Y : integer;
(*
fixed dimension outline contains definition of rows, starting at the reference point at top left and working down.  Each row is defined on a separate line, biginning with "row".  Each element in a row contains a pin number, an "X" (for used by outline) or a "E" (for empty)
LM555
ROW,1,X, X, 8
ROW,2, X, X, 7
ROW,3, X, X, 6
ROW,4 X X 5
*)
    procedure AddOutline;
    var
        FieldIndex : integer;
        Name, NoImport : string;
        NoImportBool : boolean;
        Outline : TveCellOutline;
    begin
        // parse first line for component name, NoImport parameter
        FieldIndex := 0;

        ParseCsvValue( Line, Name, FieldIndex );
        Name := Trim(Name);

        // for VCAD 2  (ie VeeCAD):
        if ParseCsvValue( Line, NoImport, FieldIndex ) then begin;
            NoImportBool := Trim( NoImport ) <> '0';
        end
        else begin
            NoImportBool := False;
        end;

        // setup the outline
        Outline := TveCellOutline.Create;
        FProject.AddOutline( Outline );
        Outline.Name := Name;
        Outline.NoImport := NoImportBool;


        // next lines define shape or wires
        Y := 0;
        while GetNextLine( S, LineIndex, Line ) do begin

            // if line defines a row of pins or shape
            if Pos( 'ROW,', Line ) = 1 then begin

                Index := 0;

                // skip first field : 'ROW'
                ParseCsvValue( Line, Cell, Index );

                // parse columns 'X', 'E' or '1', '2', etc
                X := 0;
                while ParseCsvValue( Line, Cell, Index ) do begin
                    Cell := Trim( Cell );
                    if( Cell = 'X' ) then begin
                        Outline.CellTypes[X,Y] := ctFree;
                    end
                    else if Cell = 'E' then begin
                        Outline.CellTypes[X,Y] := ctBody;
                    end

                    // otherwise we have a pin
                    else begin
                        // pin for file versions 1 to 7
                        if FFileCompatibility <= 7 then begin
                            Outline.CellTypes[X,Y] := ctPin;
                            Outline.CellPinNames[X,Y] := Cell;
                        end

                        // pin for file versions 8 and on
                        else if (length(Cell) >= 1) and (Cell[1] = 'P') then begin
                            Outline.CellTypes[X,Y] := ctPin;
                            Outline.CellPinNames[X,Y] := Copy( Cell, 2, 99 );
                        end
                        else begin
                            raise ESafeProjectInput.CreateFmt(
                            'Invalid Cell first letter on line %d : %s',
                            [LineIndex +1, Line]
                            );
                        end;
                    end;
                    Inc( X );
                end;
            end

            // line belongs to next outline - put it back
            else begin
                Dec( LineIndex );
                exit;
            end;
            // move to row down
            Inc( Y );
        end;
    end;

begin
    if not GotoSection( S, LineIndex, 'Outlines' ) then begin
        exit;
    end;

    while GetNextLine( S, LineIndex, Line ) do begin
        AddOutline;
    end;
end;


// RES100, 5, 3
// Outline name, body length, body width
// Parts like resistors, diodes with 2 variable length wires
 procedure TProjectInputLoaderCSV.LoadLeadedOutlines( S : TStrings );
 var
    Line : string;
    LineIndex : integer;

    procedure AddLeadedOutline;
    var
        FieldIndex : integer;
        Name, BodyLength, BodyWidth, ShowReference, NoImport  : string;
        BodyLengthInt, BodyWidthInt : integer;
        Pin0Name, Pin1Name : string;
        NoImportBool : boolean;
        Leaded : TveLeadedOutline;
    begin
        FieldIndex := 0;

        ParseCsvValue( Line, Name, FieldIndex );
        Name := Trim(Name);

        ParseCsvValue( Line, BodyLength, FieldIndex );
        BodyLengthInt := StrToIntDef( BodyLength, 1 );

        ParseCsvValue( Line, BodyWidth, FieldIndex );
        BodyWidthInt := StrToIntDef( BodyWidth, 1 );

        // fields introduced in File Version 8
        if FFileCompatibility >= 8 then  begin
            // pin names
            ParseCsvValue( Line, Pin0Name, FieldIndex );
            ParseCsvValue( Line, Pin1Name, FieldIndex );

            // show reference pin
            ParseCsvValue( Line, ShowReference, FieldIndex );
        end;

        // NoImport field introduced in VCAD 2 (ie VeeCAD)
        if ParseCsvValue( Line, NoImport, FieldIndex ) then begin;
            NoImportBool := Trim( NoImport ) <> '0';
        end
        else begin
            NoImportBool := False;
        end;

        // create the leaded component
        Leaded := TveLeadedOutline.Create;
        FProject.AddOutline( Leaded );
        Leaded.Name := Name;
        Leaded.BodyLength := BodyLengthInt;
        Leaded.BodyWidth := BodyWidthInt;
        if FFileCompatibility >= 8 then  begin
            Leaded.Pins[0].Name := Pin0Name;
            Leaded.Pins[1].Name := Pin1Name;
            Leaded.ShowReference := Trim(ShowReference) <> '0';
        end
        // early versions always show Reference end.
        else begin
            Leaded.ShowReference := True;
        end;
        Leaded.NoImport := NoImportBool;
    end;

begin
    if not GotoSection( S, LineIndex, 'LeadedOutlines' ) then begin
        exit;
    end;

    while GetNextLine( S, LineIndex, Line ) do begin
        AddLeadedOutline;
    end;
end;


// [RadialOutlines]
// TestRadial,1,3,0     ( name, lead spacing, diameter, NoImport )
// load radial outline File Version 1 to 7
procedure TProjectInputLoaderCSV.LoadRadialOutlines( S : TStrings );
var
    Line : string;
    LineIndex : integer;

    procedure AddRadialOutline;
    var
        FieldIndex : integer;
        Name, LeadSpacing, Diameter, NoImport  : string;
        LeadSpacingInt, DiameterInt : integer;
        Pin0Name, Pin1Name : string;
        NoImportBool : boolean;
        Radial : TveRadialOutline;
    begin
        FieldIndex := 0;

        ParseCsvValue( Line, Name, FieldIndex );
        Name := Trim(Name);

        ParseCsvValue( Line, LeadSpacing, FieldIndex );
        LeadSpacingInt := StrToIntDef( LeadSpacing, 1 );

        ParseCsvValue( Line, Diameter, FieldIndex );
        DiameterInt := StrToIntDef( Diameter, 1 );

        // pin name fields introduced in File Version 8
        if FFileCompatibility >= 8 then  begin
            ParseCsvValue( Line, Pin0Name, FieldIndex );
            ParseCsvValue( Line, Pin1Name, FieldIndex );
        end;

        // NoImport field introduced in VCAD 2 (ie VeeCAD)
        if ParseCsvValue( Line, NoImport, FieldIndex ) then begin;
            NoImportBool := Trim( NoImport ) <> '0';
        end
        else begin
            NoImportBool := False;
        end;

        // create the leaded component
        Radial := TveRadialOutline.Create;
        FProject.AddOutline( Radial );
        Radial.Name := Name;
        Radial.Diameter := DiameterInt;
        Radial.LeadSpacing := LeadSpacingInt;
        if FFileCompatibility >= 8 then  begin
            Radial.Pins[0].Name := Pin0Name;
            Radial.Pins[1].Name := Pin1Name;
        end;
        Radial.NoImport := NoImportBool;
    end;

begin
    if not GotoSection( S, LineIndex, 'RadialOutlines' ) then begin
        exit;
    end;

    while GetNextLine( S, LineIndex, Line ) do begin
        AddRadialOutline;
    end;
end;



procedure TProjectInputLoaderCSV.LoadCustomOutlines( S : TStrings );
{
[CustomOutlines]
TO-220,0
Pin,1,7,2
Pin,2,7,12
Pin,3,7,22
Line,5,0,6,0
Line,11,0,0,24
Line,10,0,0,24
Line,5,24,6,0
Line,5,0,0,24
end
}
var
    Line : string;
    LineIndex : integer;

    procedure AddCustomOutline;
    var
        FieldIndex : integer;
        Name, NoImport  : string;
        Field : string;
        Custom : TveCustomOutline;
        CustomLine : TcoLine;
        CustomPin : TcoPin;
    begin
        // create custom outline and setup properties
        Custom := TveCustomOutline.Create;
        FProject.AddOutline( Custom );

        // firt line is "Name,NoImport"
        FieldIndex := 0;

        ParseCsvValue( Line, Name, FieldIndex );
        Custom.Name := Trim(Name);

        ParseCsvValue( Line, NoImport, FieldIndex );
        Custom.NoImport := Trim( NoImport ) <> '0';

        // successive lines define lines, circles, etc
        while GetNextLine( S, LineIndex, Line ) do begin

            // "Line,StartX, StartY, EndX, EndY"
            if Pos( 'Line,', Line ) = 1 then begin
                 // skip "line"
                FieldIndex := 0;
                ParseCsvValue( Line, Field, FieldIndex );

                // add line to outline
                CustomLine := Custom.CreateLine;

                // get X, Y, EndX, EndY
                ParseCsvValue( Line, Field, FieldIndex );
                CustomLine.SubX:= StrToInt( Field );
                ParseCsvValue( Line, Field, FieldIndex );
                CustomLine.SubY:= StrToInt( Field );
                ParseCsvValue( Line, Field, FieldIndex );
                CustomLine.EndDeltaSubX:= StrToInt( Field );
                ParseCsvValue( Line, Field, FieldIndex );
                CustomLine.EndDeltaSubY:= StrToInt( Field );
                asm nop end;
            end

            // "Pin, Name, X, Y
            else if Pos( 'Pin,', Line ) = 1 then begin

                // skip "Pin"
                FieldIndex := 0;
                ParseCsvValue( Line, Field, FieldIndex );

                // add pin to outline
                CustomPin := Custom.CreatePin;

                // pin number
                ParseCsvValue( Line, Field, FieldIndex );
                CustomPin.Name := Trim(Field);

                // position
                ParseCsvValue( Line, Field, FieldIndex );
                CustomPin.SubX := StrToInt( Field );
                ParseCsvValue( Line, Field, FieldIndex );
                CustomPin.SubY := StrToInt( Field );
            end
            else if Pos( 'end', Line ) = 1 then begin
                break;
            end
            else begin
                raise ESafeProjectInput.CreateFmt(
                'Invalid Custom Outline row line %d : %s', [LineIndex +1, Line]
                );
            end;
        end;
    end;

begin
    if not GotoSection( S, LineIndex, 'CustomOutlines' ) then begin
        exit;
    end;

    while GetNextLine( S, LineIndex, Line ) do begin
        AddCustomOutline;
    end;
end;


procedure TProjectInputLoaderCSV.LoadComponentsProduct1( S : TStrings );

var
    Line : string;
    LineIndex : integer;

    procedure AddItem;
    var
        Index : integer;
        FieldIndex : integer;
        Field : string;
        Fields : array[0..5] of string;
        Designator, Value, Outline  : string;
        X, Y, Length : integer;
        Rotation : integer;
        Item : TveBoardItem;
        DefaultOutline : TveOutline;
    begin
        // parse line into fields
        Index := 0;
        for FieldIndex := 0 to 5 do begin
            if ParseCsvValue( Line, Field, Index ) then begin
                Field := Trim( Field )
            end
            else begin
                Field := '';
            end;
            // only field with index 0 (Designator Field) or index 1
            // (Value Field) or index 2 (Outline Field) can be blank
            if (Field = '') and (FieldIndex > 2) then begin
                raise ESafeProjectInput.CreateFmt(
                'Blank or missing field in Component Line : "%s"', [Line] );
            end;
            Fields[FieldIndex] := Field;
        end;

        // parse field[6] which is length, use 0 if blank or missing
        if not ParseCsvValue( Line, Field, Index ) then begin
            Field := '';
        end;
        Length := StrToIntDef( Field, 0);


        //R1,220K,LEADED2,5,12,0
        // Designator,Value,Outline,X,Y,Rotation
        // where Orientation goes anti-clockwise in 90 degree steps where 0 is reference rotation
        // ie 0=>0 degrees, 1=>90 degrees, 2=>180 degrees, 3=>degrees
        // No two Items can have same designator.
        // Outline must correspond to name of an outline in [OutLines] section of file

        Designator := Fields[0];
        Value := Fields[1];
        Outline := Fields[2];
        X := StrToIntDef( Fields[3], 0 );
        Y := StrToIntDef( Fields[4], 0 );
        Rotation := StrToIntDef( Fields[5], 0 );
        if Rotation > Ord( High( TRotation ) ) then begin
            Rotation := 0;
        end;

        // create the board item

        //... if outline not found, then create one for that outline name
        Item := TveBoardItem.Create;
        Item.Outline := FProject.OutlineByName( Outline );
        if Item.Outline = nil then begin
            DefaultOutline := FProject.AddDefaultOutline;
            DefaultOutline.Name := Outline;
            Item.Outline := DefaultOutline;
        end;

        FProject.AddBoardItem( Item );
        Item.Designator := Designator;
        Item.Value := Value;
        Item.X := X;
        Item.Y := Y;
        Item.Rotation := TRotation(Rotation);
        Item.Length := Length;

        // these properties are not defined in V1 & V2 files
        Item.TextX := 0;
        Item.TextY := 0;
        Item.TextRotation := Rot0;
        Item.TextVisible := True;
    end;

begin

    if not GotoSection( S, LineIndex, 'Components' ) then begin
        exit;
    end;

    while GetNextLine( S, LineIndex, Line ) do begin
        AddItem;
    end;
end;

procedure TProjectInputLoaderCSV.LoadComponentsProduct2( S : TStrings );
var
    Line : string;
    LineIndex : integer;

    procedure AddItem;
    var
        Index : integer;
        FieldIndex : integer;
        Field : string;
        Fields : array[0..10] of string;
        Designator, Value, Outline  : string;
        X, Y, Length : integer;
        Rotation : TRotation;
        Item : TveBoardItem;
        DefaultOutline : TveOutline;

        DesignatorX : integer;
        DesignatorY : integer;
        DesignatorRotation : TRotation;
        DesignatorVisible : boolean;

    begin
        // parse line into fields
        Index := 0;
        for FieldIndex := Low(Fields) to High(Fields) do begin
            if ParseCsvValue( Line, Field, Index ) then begin
                Field := Trim( Field )
            end
            else begin
                Field := '';
            end;
            // only field with index 0 (Designator Field) or index 1
            // (Value Field) or index 2 (Outline Field) can be blank
            if (Field = '') and (FieldIndex > 2) then begin
                raise ESafeProjectInput.CreateFmt(
                'Blank or missing field in Component Line : "%s"', [Line] );
            end;
            Fields[FieldIndex] := Field;
        end;


        //R1,220K,LEADED2,5,12,0
        // Designator,Value,Outline,X,Y,Rotation
        // where Orientation goes anti-clockwise in 90 degree steps where 0 is reference rotation
        // ie 0=>0 degrees, 1=>90 degrees, 2=>180 degrees, 3=>degrees
        // No two Items can have same designator.
        // Outline must correspond to name of an outline in [OutLines] section of file

        Designator := Fields[0];
        Value := Fields[1];
        Outline := Fields[2];
        X := StrToIntDef( Fields[3], 0 );
        Y := StrToIntDef( Fields[4], 0 );
        Rotation := StrToRotationDef( Fields[5], Rot0 );
        Length := StrToIntDef( Fields[6], 0 );

        DesignatorX := StrToIntDef( Fields[7], 0 );
        DesignatorY := StrToIntDef( Fields[8], 0 );
        DesignatorRotation := StrToRotationDef( Fields[9], Rot0 );
        DesignatorVisible := StrToBooleanDef( Fields[10], True );


        // create the board item

        //... if outline not found, then create one for that outline name
        Item := TveBoardItem.Create;
        Item.Outline := FProject.OutlineByName( Outline );
        if Item.Outline = nil then begin
            DefaultOutline := FProject.AddDefaultOutline;
            DefaultOutline.Name := Outline;
            Item.Outline := DefaultOutline;
        end;

        FProject.AddBoardItem( Item );
        Item.Designator := Designator;
        Item.Value := Value;
        Item.X := X;
        Item.Y := Y;
        Item.Rotation := Rotation;

        // at file version V5 we made Radial Outlines to be sizeable, with
        // length parameter now important
        if (FFileCompatibility < 5) and (Item.Outline is TveRadialOutline) then begin
            // Make old zero length same as lead spacing so component appears
            // as for older versions
            Item.Length := TveRadialOutline(Item.Outline).LeadSpacing;
        end
        else begin
            Item.Length := Length;
        end;

        Item.TextX := DesignatorX;
        Item.TextY := DesignatorY;
        Item.TextRotation := DesignatorRotation;
        Item.TextVisible := DesignatorVisible;
    end;

begin

    if not GotoSection( S, LineIndex, 'Components' ) then begin
        exit;
    end;

    while GetNextLine( S, LineIndex, Line ) do begin
        AddItem;
    end;
end;


procedure TProjectInputLoaderCSV.LoadComponents( S : TStrings );
begin
    if  ((FProduct = PRODUCT_1) and (FFileCompatibility = 1000)) or
        (FProduct = PRODUCT_2) then begin

        LoadComponentsProduct2( s );
    end

    else if FProduct = PRODUCT_1 then begin
        LoadComponentsProduct1( s );
    end;
end;

(*
[Links]
1,5,9,7
DesignatorNumber, X, Y,Length
Links are always vertical - do not have an orientation.
X,Y are cell coords of top, left
*)

procedure TProjectInputLoaderCSV.LoadLinks( S : TStrings );

var
    Line : string;
    LineIndex : integer;
    Link : TveBoardItem;

    procedure AddLink;
    var
        FieldIndex : integer;
        Designator, X, Y, Rotation, Length  : string;
        XInt, YInt, LengthInt, RotationInt : integer;
    begin
        // each link is a single line
        FieldIndex := 0;

        ParseCsvValue( Line, Designator, FieldIndex );
        Designator := Trim(Designator);

        ParseCsvValue( Line, X, FieldIndex );
        XInt := StrToIntDef( X, 0 );

        ParseCsvValue( Line, Y, FieldIndex );
        YInt := StrToIntDef( Y, 0 );

        ParseCsvValue( Line, Rotation, FieldIndex );
        RotationInt := StrToIntDef( Rotation, 0 );
        if RotationInt > Ord( High( TRotation ) ) then begin
            RotationInt := 0;
        end;


        ParseCsvValue( Line, Length, FieldIndex );
        LengthInt := StrToIntDef( Length, 1 );

        // create the link
        Link := TveBoardItem.Create;
        Link.Outline := FProject.LinkOutline;
        FProject.AddBoardItem( Link );
        Link.Designator := Designator;
        Link.Value := '';
        Link.X := XInt;
        Link.Y := YInt;
        Link.Length := LengthInt;
        Link.Rotation := TRotation(RotationInt);
    end;

begin
    if not GotoSection( S, LineIndex, 'Links' ) then begin
        exit;
    end;

    while GetNextLine( S, LineIndex, Line ) do begin
        AddLink;
    end;
end;

procedure TProjectInputLoaderCSV.LoadBreaks( S : TStrings );

var
    Line : string;
    LineIndex : integer;
    Break : TveBoardItem;

    procedure AddBreak;
    var
        FieldIndex : integer;
        Designator, X, Y, Shift  : string;
        XInt, YInt : integer;
        ShiftBool : boolean;
    begin
        // each break is a single line
        FieldIndex := 0;

        ParseCsvValue( Line, Designator, FieldIndex );
        Designator := Trim(Designator);

        ParseCsvValue( Line, X, FieldIndex );
        XInt := StrToIntDef( X, 0 );

        ParseCsvValue( Line, Y, FieldIndex );
        YInt := StrToIntDef( Y, 0 );

        ParseCsvValue( Line, Shift, FieldIndex );
        ShiftBool := Trim(Shift) = '1';

        // create the break
        Break := TveBoardItem.Create;
        Break.Outline := FProject.BreakOutline;
        FProject.AddBoardItem( Break );
        Break.Designator := Designator;
        Break.X := XInt;
        Break.Y := YInt;
        if ShiftBool then begin
            Break.Shift := shRight;
        end;
    end;

begin
    if not GotoSection( S, LineIndex, 'Breaks' ) then begin
        exit;
    end;

    while GetNextLine( S, LineIndex, Line ) do begin
        AddBreak;
    end;
end;


procedure TProjectInputLoaderCSV.LoadWires( S : TStrings );
(*
[Wires]
W1,A,7,10
*)
var
    Line : string;
    LineIndex : integer;
    Wire : TveBoardItem;

    procedure AddWire;
    var
        FieldIndex : integer;
        Designator, NetName, X, Y  : string;
        XInt, YInt : integer;
    begin
        // each break is a single line
        FieldIndex := 0;

        ParseCsvValue( Line, Designator, FieldIndex );
        Designator := Trim(Designator);

        ParseCsvValue( Line, NetName, FieldIndex );
        NetName := Trim(NetName);

        ParseCsvValue( Line, X, FieldIndex );
        XInt := StrToIntDef( X, 0 );

        ParseCsvValue( Line, Y, FieldIndex );
        YInt := StrToIntDef( Y, 0 );

        // create the wire
        Wire := TveBoardItem.Create;
        Wire.Outline := FProject.WireOutline;
        FProject.AddBoardItem( Wire );
        Wire.Designator := Designator;
        Wire.Value := NetName;
        Wire.X := XInt;
        Wire.Y := YInt;
    end;

begin
    if not GotoSection( S, LineIndex, 'Wires' ) then begin
        exit;
    end;

    while GetNextLine( S, LineIndex, Line ) do begin
        AddWire;
    end;
end;


procedure TProjectInputLoaderCSV.LoadText( S : TStrings );
var
    Line : string;
    LineIndex : integer;
    Text : TveBoardItem;

    procedure AddText;
    var
        FieldIndex : integer;
        Designator, Value, X, Y  : string;
        XInt, YInt : integer;
        Rotation : string;
        RotationInt : integer;
        TextSize : string;
        TextSizeInt : integer;
    begin
        // each text is a single line
        FieldIndex := 0;

        ParseCsvValue( Line, Designator, FieldIndex );
        Designator := Trim(Designator);

        ParseCsvValue( Line, Value, FieldIndex );
        Value := Trim(Value);

        ParseCsvValue( Line, X, FieldIndex );
        XInt := StrToIntDef( X, 0 );

        ParseCsvValue( Line, Y, FieldIndex );
        YInt := StrToIntDef( Y, 0 );

        ParseCsvValue( Line, Rotation, FieldIndex );
        RotationInt := StrToIntDef( Rotation, 0 );
        if RotationInt > Ord( High( TRotation ) ) then begin
            RotationInt := 0;
        end;

        ParseCsvValue( Line, TextSize, FieldIndex );
        TextSizeInt := StrToIntDef( TextSize, 0 );

        // create the text
        Text := TveBoardItem.Create;
        Text.Outline := FProject.TextOutline;
        FProject.AddBoardItem( Text );
        Text.Value:= Value;
        Text.X := XInt;
        Text.Y := YInt;
        Text.Rotation := TRotation(RotationInt);
        if TextSizeInt = 0 then begin
            (FProject.TextOutline).SetSize(Text, tsSmall);
        end
        else begin
            FProject.TextOutline.SetSize(Text, tsLarge);
        end;
    end;
begin
    if not GotoSection( S, LineIndex, 'Text' ) then begin
        exit;
    end;

    while GetNextLine( S, LineIndex, Line ) do begin
        AddText;
    end;
end;


procedure TProjectInputLoaderCSV.LoadNetlist( S : TStrings );

(*
GND,R1, 5, 7, 22
GND, IC2, 6, 5, 11
VCC, ZD4, 2

NetName=, Designator, PinNo, PinNo, etc
*)

var
    LineIndex : integer;
    Line : string;
    Netlist : TneNetList;

    procedure AddNet;
    var
        FieldIndex : integer;
        NodeName  : string;
        Node : TneNode;
        ComponentName : string;
        Component : TneComponent;
        PinNoText : string;
//        PinNo : integer;
        PinsCreated : boolean;
    begin
        // variable tracks CSV scanning along line
        FieldIndex := 0;

        // leftmost parameter is net name
        ParseCsvValue( Line, NodeName, FieldIndex );
        NodeName := Trim(NodeName);

        // get reference to this net
        Node := Netlist.NodeByName( NodeName );
        if Node = nil then begin
            Node := Netlist.CreateNode;
            Node.Name := NodeName;
        end;

        // next field is component name
        // .. if no component belongs to this net, leave net name in Netlist
        if not ParseCsvValue( Line, ComponentName, FieldIndex ) then begin
            exit;
        end;
        ComponentName := Trim(ComponentName);

        // get reference to this component
        Component := Netlist.ComponentByName( ComponentName );
        if Component = nil then begin
            Component := Netlist.CreateComponent;
            Component.Name := ComponentName;
        end;

        // next fields are pin names which lie in this net
        PinsCreated := False;
        while ParseCsvValue( Line, PinNoText, FieldIndex ) do begin
            PinsCreated := True;
            Netlist.CreatePin( Node, Component, Trim(PinNoText) );
        end;

        // illegal to have component "in" a net with no pins connected !
        if not PinsCreated then begin
            raise ESafeProjectInput.CreateFmt(
            'Component name but no pins in Netlist line : %s', [Line]
            );
        end;
    end;

begin
    if not GotoSection( S, LineIndex, 'Nets' ) then begin
        exit;
    end;

    Netlist := FProject.NetList;

    while GetNextLine( S, LineIndex, Line ) do begin
        AddNet;
    end;

    FProject.TransferFastNets;
end;


end.


