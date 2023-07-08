unit ProjectOutput;

interface

uses Project, Classes;

type TProjectOutputSaver = class

private
    FProject : TveProject;

    procedure SaveVersion( S : TStream );
    procedure SaveConfig( S : TStream );
    procedure SaveBoard( S : TStream );
    procedure SaveCelledOutlines( S : TStream );
    procedure SaveLeadedOutlines( S : TStream );
    procedure SaveRadialOutlines( S : TStream );
    procedure SaveCustomOutlines( S : TStream );
    procedure SaveSMDOutlines( S : TStream );
    procedure SaveComponents( S : TStream );
    procedure SaveLinks( S : TStream );
    procedure SaveBreaks( S : TStream );
    procedure SaveWires( S : TStream );
    procedure SaveTexts( S : TStream );
    procedure SaveNetlist( S : TStream );
    procedure SaveNetColors( S : TStream );
    procedure SaveNotes( S : TStream );

public
    constructor Create( Project : TveProject );
    destructor Destroy; override;

    procedure SaveToStream( Stream : TStream );
    procedure SaveToFile( FileName : string );
end;

implementation

uses SysUtils, ParseCsv, Outlines, CelledOutlines, OtherOutlines,
    SizeableOutlines, RadialOutlines, CustomOutlines, SmdOutlines, Netlist,
    Rotations, JsonParse, Board, Types;


const
    RotationToStr : array[TRotation] of string = ('0', '1', '2', '3');
    BooleanToStr : array[boolean] of string = ( '0', '1' );

    BoolToStr : array[Boolean] of string = ( 'false', 'true' );
    RotToStr : array[TRotation] of string = ( '0', '90', '180', '270' );

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


constructor TProjectOutputSaver.Create( Project : TveProject );
begin
    FProject := Project;
end;

destructor TProjectOutputSaver.Destroy;
begin
    inherited;
end;


// OUTPUT TEXT LINE TO FILE AS UTF-8

procedure LineOut( Line : string; Stream : TStream );
const
    CRLF : array[0..1] of ansichar = ( #13, #10 );
var
   oString: UTF8String;
begin
   oString := UTF8String(Line);
   Stream.WriteBuffer(oString[1], length(oString) * sizeof(ansichar) );
   Stream.WriteBuffer(CRLF, 2 * sizeof(ansichar) );
end;

procedure TextOut( const Text : string; Stream : TStream );
var
   oString: UTF8String;
begin
   oString := UTF8String(Text);
   Stream.WriteBuffer(oString[1], length(oString) * sizeof(ansichar) );
end;


procedure TProjectOutputSaver.SaveToStream( Stream : TStream );
begin
    SaveVersion( Stream );

    // start JSON text with an object
    LineOut( '{', Stream );

//    SaveVersion( Stream );

    SaveConfig( Stream );
    SaveBoard( Stream );
    SaveCelledOutlines( Stream );
    SaveLeadedOutlines( Stream );
    SaveRadialOutlines( Stream );
    SaveCustomOutlines( Stream );
    SaveSMDOutlines( Stream );
    SaveComponents( Stream );
    SaveLinks( Stream );
    SaveBreaks( Stream );
    SaveWires( Stream );
    SaveTexts( Stream );
    SaveNetlist( Stream );
    SaveNetColors( Stream );
    SaveNotes( Stream );

    // end JSON text - close object
    LineOut( '}', Stream );

end;


procedure TProjectOutputSaver.SaveToFile( FileName : string );
var ProjectFile : TFileStream;
begin
    ProjectFile := TFileStream.Create( FileName, fmCreate );
    try
        SaveToStream( ProjectFile );
    finally
        ProjectFile.Free;
    end;
end;

{   // EMIT VERSION HEADER IN OLD CSV FORMAT
[Version]
Product,2
File,9
}
procedure TProjectOutputSaver.SaveVersion( S : TStream );
begin
    LineOut( '[Version]', S );
    LineOut( 'Product,2', S );
//    LineOut( 'File,1', S );      // commercial product, initial release
//    LineOut( 'File,2', S );      // commercial product, radial outlines
//    LineOut( 'File,3', S );      // commercial product, shifted breaks
//    LineOut( 'File,4', S );      // custom outlines
//    LineOut( 'File,5', S );     // sizeable radial outlines using length param
//    LineOut( 'File,6', S );     // text component
//    LineOut( 'File,7', S );     // large/small characters for text component
//    LineOut( 'File,8', S );     // pin names replace pin numbers
//    LineOut( 'File,9', S );     // UTF8 format project file
//    LineOut( 'File,10', S );    // JSON File Format
//    LineOut( 'File,11', S ); // Definable strip patterns
//    LineOut( 'File,12', S ); // Diagonal placement of sizeable outlines
//    LineOut( 'File,13', S ); // Component Grouping
//    LineOut( 'File,14', S ); // Down shifted track breaks
//    LineOut( 'File,15', S ); // Saving TveTextOutline Size attribute
//    LineOut( 'File,16', S ); // HoleArrays removed.
//    LineOut( 'File,17', S );   // Save names of nets to be colored.
//    LineOut( 'File,18', S );   // Save names of 6 nets (was 4) to be colored.
    LineOut( 'File,19', S );   // Save Notes Lines.

end;


procedure TProjectOutputSaver.SaveConfig( S : TStream );
begin
{
    LineOut( '[Config]', S );
    LineOut( 'NetImportFormat,' + FProject.NetlistImportFormat, S );
}
    LineOut( '"Config" : {', S );
    LineOut( Format( '  "NetImportFormat" : "%s"',[JEsc(FProject.NetlistImportFormat)]) , S );
    LineOut( '},', S );
end;

procedure TProjectOutputSaver.SaveBoard( S : TStream );
const
    Pattern2Str : array[TbrPattern] of string =
        ( 'Strip', 'Donut', 'Tripad', 'Defined' );
var
    Board : TbrBoard;
    i : integer;
    Strip : TbrRawStrip;
    Seg : TbrSegment;
begin
    Board := FProject.Board;

    LineOut( '"Board" : {', S );
    LineOut( Format( '  "Width" : %d,',[Board.Width]) , S );
    LineOut( Format( '  "Height" : %d,',[Board.Height]) , S );

    // pattern has comma for defined boards, because Strips section follows
    if Board.Pattern = ptDefined then begin
        LineOut( Format( '  "Pattern" : "%s",',[Pattern2Str[Board.Pattern]]) , S );
    end
    // other patterns have no comma, because end of Board section
    else begin
        LineOut( Format( '  "Pattern" : "%s"',[Pattern2Str[Board.Pattern]]) , S );
    end;

    // defined boards have strips & holes
    if FProject.Board.Pattern = ptDefined then begin

        // ** strips **
        LineOut( '  "Strips" : [', S );
        if Board.RawStripCount > 0 then begin
            for i := 0 to Board.RawStripCount - 2 do begin
                Strip := Board.RawStrips[i];
                // emit array member, with comma at end
                LineOut( Format(
                    '      { "X1" : %d,  "Y1" : %d, "X2" : %d, "Y2" : %d },',
                    [ Strip.Start.X, Strip.Start.Y, Strip.Finish.X, Strip.Finish.Y ]
                ), S );
            end;

            // last line without comma
            Strip := Board.RawStrips[Board.RawStripCount -1];
            LineOut( Format(
                '      { "X1" : %d,  "Y1" : %d, "X2" : %d, "Y2" : %d }',
                [ Strip.Start.X, Strip.Start.Y, Strip.Finish.X, Strip.Finish.Y ]
            ), S);
        end;
        // Close strips array
        LineOut( '  ],', S );

        // ** segments **
        LineOut( '  "Segments" : [', S );
        if Board.SegmentCount > 0 then begin
            for i := 0 to Board.SegmentCount - 2 do begin
                Seg := Board.Segments[i];
                // emit array member, with comma at end
                LineOut( Format(
                '      { "X1_1000" : %d,  "Y1_1000" : %d, "X2_1000" : %d, "Y2_1000" : %d, "Width_1000" : %d },',
                    [ Seg.X1_1000, Seg.Y1_1000, Seg.X2_1000, Seg.Y2_1000, Seg.Width_1000 ]
//                    [ Seg.X1_1000-500, Seg.Y1_1000-500, Seg.X2_1000-500, Seg.Y2_1000-500, Seg.Width_1000 ]
                ), S );
            end;

            // last line without comma
            Seg := Board.Segments[Board.SegmentCount -1];
            LineOut( Format(
                '      { "X1_1000" : %d,  "Y1_1000" : %d, "X2_1000" : %d, "Y2_1000" : %d, "Width_1000" : %d }',
                    [ Seg.X1_1000, Seg.Y1_1000, Seg.X2_1000, Seg.Y2_1000, Seg.Width_1000 ]
//                    [ Seg.X1_1000-500, Seg.Y1_1000-500, Seg.X2_1000-500, Seg.Y2_1000-500, Seg.Width_1000 ]
            ), S);
        end;
        // Close segments array
        LineOut( '  ]', S );
    end;

    // close Board Object
    LineOut( '},', S );
end;


procedure TProjectOutputSaver.SaveCelledOutlines( S : TStream );
(*
Celled Outline contains definition of rows, starting at the reference point at
top left and working down.  Each row is defined on a separate line, beginning
with "row".  Each element in a row contains a pin number, an "X" (for used by
outline) or a "E" (for empty)
LM555
WIRES  // ** optional **
ROW,1,X, X, 8
ROW,2, X, X, 7
ROW,3, X, X, 6
ROW,4 X X 5
*)
    procedure SaveCelledOutline( Outline : TveCellOutline );
    var
        Y : integer;
        X : integer;
        Line : string;
        LastX, LastY : integer;
    begin

        // open JSON array element : eg.
        //   [ { "Name" : "TO202", "Locked" : false,
        LineOut( Format( '  { "Name" : "%s", "Locked" : %s,',
            [JEsc(Outline.Name), BoolToStr[Outline.NoImport]] ), S );

        LineOut( '    "Rows" : [', S );

        LastX := Outline.Width -1;
        LastY := Outline.Height -1;

        // output rows of cell data eg. [Empty, Body, {Pin : Name}]
        for Y := 0 to LastY do begin
            Line := '    [';

            // output one row
            for X := 0 to LastX do begin
                case Outline.CellTypes[X,Y] of
                    ctFree : Line := Line + '"Free"';
                    ctBody : Line := Line + '"Body"';
                    ctPin : Line := Line + '{"Pin" : "' + JEsc(Outline.CellPinNames[X,Y]) + '"}';
                end;
                // comma between array elements, but not after last element
                if X <> LastX then begin
                    Line := Line + ',';
                end;
            end;
            // close array for this row
            Line := Line + ']';

            // if not last row, add a comma
            if Y <> LastY then begin
                Line := Line + ',';
            end;

            LineOut( Line, S );
        end;

        // close array of rows
        LineOut( '    ]', S );
    end;

var i : integer;
    Found : boolean;
    Outline : TveOutline;
begin
//    LineOut( '[Outlines]', S );

    // next object is an array of outlines
    LineOut( '"CelledOutlines" : [', S );

    Found := False;
    for i := 0 to FProject.OutlineCount -1 do begin
        Outline := FProject.Outlines[i];
        if Outline is TveCellOutline then begin

            // finish previous outline with a comma
            if Found then begin
                LineOut( '  },', S );
            end;
            Found := True;
            SaveCelledOutline( TveCellOutline(Outline) );
        end;
    end;

    // if we emitted at least one outline, finish last record with no comma
    if Found then begin
        LineOut( '  }', S );
     end;

    // end of array of celled outlines
    LineOut( '],', S );
end;

procedure TProjectOutputSaver.SaveLeadedOutlines( S : TStream );

(*
Leaded Outline contains body length, body width
RES100, 5, 3
Outline name, body length, body width
Parts like resistors, diodes with 2 variable length wires
*)
    procedure SaveLeadedOutline( Outline : TveLeadedOutline );
    begin
        // open JSON array element : eg.
        //   [ { "Name" : "AXIAL2_7", "Locked" : false,
        LineOut( Format( '  { "Name" : "%s", "Locked" : %s,',
            [JEsc(Outline.Name), BoolToStr[Outline.NoImport] ] ), S );

        //   "BodyLength" : 3, "BodyWidth" : 1,
        LineOut( Format( '    "BodyLength" : %d, "BodyWidth" : %d,',
            [Outline.BodyLength, Outline.BodyWidth] ) ,S );

        //   "Pin0Name" : "1", "Pin1Name" : "2", "ShowReference" : True
        LineOut( Format( '    "Pin0Name" : "%s", "Pin1Name" : "%s", "ShowReference" : %s',
            [JEsc(Outline.Pins[0].Name), jEsc(Outline.Pins[1].Name), BoolToStr[Outline.ShowReference]] ) , S );
    end;

var
    Outline : TveOutline;
    i : integer;
    Found : boolean;
begin
    LineOut( '"LeadedOutlines" : [', S );

    Found := False;
    for i := 0 to FProject.OutlineCount -1 do begin
        Outline := FProject.Outlines[i];
        if Outline is TveLeadedOutline then begin

            // finish previous outline with a comma
            if Found then begin
                LineOut( '  },', S );
            end;
            Found := True;
            SaveLeadedOutline( TveLeadedOutline(Outline) );
        end;
    end;

    // if we emitted at least one outline, finish last record with no comma
    if Found then begin
        LineOut( '  }', S );
     end;

    // end of array of leaded outlines
    LineOut( '],', S );
end;


procedure TProjectOutputSaver.SaveRadialOutlines( S : TStream );
(*
// [RadialOutlines]
// TestRadial,1,3,0     ( name, lead spacing, diameter, NoImport )
*)
    procedure SaveRadialOutline( Outline : TveRadialOutline );
    begin

        // open JSON array element : eg.
        //   [ { "Name" : "RADIAL2_7", "Locked" : false,
        LineOut( Format( '  { "Name" : "%s", "Locked" : %s,',
            [JEsc(Outline.Name), BoolToStr[Outline.NoImport] ] ), S );

        //   "BodyLength" : 3, "BodyWidth" : 1,
        LineOut( Format( '    "LeadSpacing" : %d, "Diameter" : %d,',
            [Outline.LeadSpacing, Outline.Diameter] ) ,S );

        //   "Pin0Name" : "1", "Pin1Name" : "2", "ShowReference" : True
        LineOut( Format( '    "Pin0Name" : "%s", "Pin1Name" : "%s"',
            [Jesc(Outline.Pins[0].Name), JEsc(Outline.Pins[1].Name)] ) , S );
    end;

var
    Outline : TveOutline;
    i : integer;
    Found : boolean;
begin
    LineOut( '"RadialOutlines" : [', S );

    Found := False;
    for i := 0 to FProject.OutlineCount -1 do begin
        Outline := FProject.Outlines[i];
        if Outline is TveRadialOutline then begin
            // finish previous outline with a comma
            if Found then begin
                LineOut( '  },', S );
            end;
            Found := True;
            SaveRadialOutline( TveRadialOutline(Outline) );
        end;
    end;

    // if we emitted at least one outline, finish last record with no comma
    if Found then begin
        LineOut( '  }', S );
     end;

    // end of array of Radial outlines
    LineOut( '],', S );
end;


procedure TProjectOutputSaver.SaveCustomOutlines( S : TStream );

    procedure SaveCustomOutline( Outline : TveCustomOutline );
    var
        i : integer;
        Shape : TcoShape;
        NewShape : TcoShape;
    begin

        // open JSON array element : eg.
        //   [ { "Name" : "TO92", "Locked" : false,
        LineOut( Format( '  { "Name" : "%s", "Locked" : %s,',
            [JEsc(Outline.Name), BoolToStr[Outline.NoImport] ] ), S );

        // output pins
        LineOut( '    "Pins" : [', S );

        Shape := nil;
        for i := 0 to Outline.ShapeCount -1 do begin
            NewShape := Outline.Shapes[i];

            if NewShape is TcoPin then begin

                // if have a shape in the pipeline, emit it - with a comma
                if Shape <> nil then begin
                   LineOut( Format( '    { "Name" : "%s", "X5" : %d, "Y5" : %d },',
                    [JEsc(TcoPin(Shape).Name), TcoPin(Shape).SubX, TcoPin(Shape).SubY] ) ,S );
                end;

                Shape := NewShape;
            end;
        end;

        if Shape <> nil then begin
            LineOut( Format( '    { "Name" : "%s", "X5" : %d, "Y5" : %d }',
            [jEsc(TcoPin(Shape).Name), TcoPin(Shape).SubX, TcoPin(Shape).SubY] ) ,S );
        end;

        // end object list of pins
        LineOut( '    ],', S );

        // output lines
        LineOut( '    "Lines" : [', S );

        Shape := nil;
        for i := 0 to Outline.ShapeCount -1 do begin

            NewShape := Outline.Shapes[i];
            if NewShape is TcoLine then begin

                // if have a shape in the pipeline, emit it - with a comma
                if Shape <> nil then begin

                    LineOut( Format( '    { "X5" : %d, "Y5" : %d, "DX5" : %d, "DY5" : %d},',
                    [
                    TcoLine(Shape).SubX, TcoLine(Shape).SubY,
                    TcoLine(Shape).EndDeltaSubX, TcoLine(Shape).EndDeltaSubY
                    ] ), S );
                end;

                Shape := NewShape;
            end;
        end;

        // emit last shape in pipeline
        if Shape <> nil then begin

            LineOut( Format( '    { "X5" : %d, "Y5" : %d, "DX5" : %d, "DY5" : %d}',
            [
            TcoLine(Shape).SubX, TcoLine(Shape).SubY,
            TcoLine(Shape).EndDeltaSubX, TcoLine(Shape).EndDeltaSubY
            ] ), S );
        end;

        // end array of lines
        LineOut( '    ]', S );
    end;
var
    Outline : TveOutline;
    i : integer;
    Found : boolean;
begin
    LineOut( '"CustomOutlines" : [', S );

    Found := False;
    for i := 0 to FProject.OutlineCount -1 do begin
        Outline := FProject.Outlines[i];
        if Outline is TveCustomOutline then begin
            // finish previous outline with a comma
            if Found then begin
                LineOut( '  },', S );
            end;
            Found := True;
            SaveCustomOutline( TveCustomOutline(Outline) );
        end;
    end;

    // if we emitted at least one outline, finish last record with no comma
    if Found then begin
        LineOut( '  }', S );
     end;

    // end of array of Radial outlines
    LineOut( '],', S );
end;


procedure TProjectOutputSaver.SaveSMDOutlines( S : TStream );

    procedure SaveSMDOutline( Outline : TveSMDOutline );
    var
        i : integer;
        Shape : TsmShape;
        NewShape : TsmShape;
    begin

        // open JSON array element : eg.
        //   [ { "Name" : "TO92", "Locked" : false,
        LineOut( Format( '  { "Name" : "%s", "Locked" : %s,',
            [JEsc(Outline.Name), BoolToStr[Outline.NoImport] ] ), S );

        // output pins
        LineOut( '    "Pins" : [', S );

        Shape := nil;
        for i := 0 to Outline.ShapeCount -1 do begin
            NewShape := Outline.Shapes[i];

            if NewShape is TsmPin then begin

                // if have a shape in the pipeline, emit it - with a comma
                if Shape <> nil then begin
                   LineOut( Format( '    { "Name" : "%s", "X1000" : %d, "Y1000" : %d, "Width1000" : %d, "Height1000" : %d },',
                    [JEsc(TsmPin(Shape).Name), TsmPin(Shape).XDiv, TsmPin(Shape).YDiv,
                    TsmPin(Shape).WidthDiv, TsmPin(Shape).HeightDiv
                    ]) ,S );
                end;

                Shape := NewShape;
            end;
        end;

        if Shape <> nil then begin
            LineOut( Format( '    { "Name" : "%s", "X1000" : %d, "Y1000" : %d, "Width1000" : %d, "Height1000" : %d }',
            [
            JEsc(TsmPin(Shape).Name), TsmPin(Shape).XDiv, TsmPin(Shape).YDiv,
            TsmPin(Shape).WidthDiv, TsmPin(Shape).HeightDiv
            ]) ,S );
        end;

        // end object list of pins
        LineOut( '    ],', S );

        // output lines
        LineOut( '    "Lines" : [', S );

        Shape := nil;
        for i := 0 to Outline.ShapeCount -1 do begin

            NewShape := Outline.Shapes[i];
            if NewShape is TsmLine then begin

                // if have a shape in the pipeline, emit it - with a comma
                if Shape <> nil then begin

                    LineOut( Format( '    { "X1000" : %d, "Y1000" : %d, "DX1000" : %d, "DY1000" : %d},',
                    [
                    TsmLine(Shape).XDiv, TsmLine(Shape).YDiv,
                    TsmLine(Shape).EndDeltaXDiv, TsmLine(Shape).EndDeltaYDiv
                    ] ), S );
                end;

                Shape := NewShape;
            end;
        end;

        // emit last shape in pipeline
        if Shape <> nil then begin

            LineOut( Format( '    { "X1000" : %d, "Y1000" : %d, "DX1000" : %d, "DY1000" : %d}',
            [
            TsmLine(Shape).XDiv, TsmLine(Shape).YDiv,
            TsmLine(Shape).EndDeltaXDiv, TsmLine(Shape).EndDeltaYDiv
            ] ), S );
        end;

        // end array of lines
        LineOut( '    ]', S );
    end;
var
    Outline : TveOutline;
    i : integer;
    Found : boolean;
begin
    LineOut( '"SmdOutlines" : [', S );

    Found := False;
    for i := 0 to FProject.OutlineCount -1 do begin
        Outline := FProject.Outlines[i];
        if Outline is TveSmdOutline then begin
            // finish previous outline with a comma
            if Found then begin
                LineOut( '  },', S );
            end;
            Found := True;
            SaveSmdOutline( TveSmdOutline(Outline) );
        end;
    end;

    // if we emitted at least one outline, finish last record with no comma
    if Found then begin
        LineOut( '  }', S );
     end;

    // end of array of Radial outlines
    LineOut( '],', S );
end;



procedure TProjectOutputSaver.SaveComponents( S : TStream );

// R1,220K,RESISTOR_100mW,5,12,0,2,1
// Designator,Value,Outline,X,Y,Rotation,WireLeadTopLength,WireLeadBottomLength
// where Orientation goes anti-clockwise in 90 degree steps where 0 is reference rotation
// ie 0=>0 degrees, 1=>90 degrees, 2=>180 degrees, 3=>degrees
// WireLeadTopLength,WireLeadBottomLength parameters are optional and can
// contain blanks between the commas..

    procedure SaveComponent( Component : TveBoardItem );
    begin
        LineOut( Format( '  { "Designator" : "%s", "Value" : "%s", "Outline" : "%s",',
        [ jEsc(Component.Designator), JEsc(Component.Value), JEsc(Component.Outline.Name) ]), S );

        LineOut( Format( '  "X1000" : %d, "Y1000" : %d, "EndDeltaX" : %d, "EndDeltaY" : %d,',
        [ Component.XDiv, Component.YDiv, Component.EndDeltaX, Component.EndDeltaY ] ), S);

        LineOut( Format( '  "Text" : { "X" : %d, "Y" : %d, "Angle" : %s, "Visible" : %s },',
        [ Component.TextX, Component.TextY,
            RotToStr[Component.TextRotation], BoolToStr[Component.TextVisible]] ), S);

        LineOut( Format( '  "Group" : %d', [Component.Group] ), S );
    end;

var
    i : integer;
    Item : TveBoardItem;
    Found : boolean;
begin
    LineOut( '"Components" : [', S );

    Found := False;
    for i := 0 to FProject.BoardItemCount -1 do begin
        Item := FProject.BoardItems[i];
        if (Item.Outline is TveCellOutline) or
            (Item.Outline is TveLeadedOutline) or
            (Item.Outline is TveRadialOutline) or
            (Item.Outline is TveDummyOutline) or
            (Item.Outline is TveCustomOutline) or
            (Item.Outline is TveSmdOutline)
            then begin

            // finish previous component with a comma
            if Found then begin
                LineOut( '  },', S );
            end;
            Found := True;

            SaveComponent( Item );
        end;
    end;

    // finish last component with no comma
    if Found then begin
        LineOut( '  }', S );
    end;

    // end of array of Components
    LineOut( '],', S );
end;


procedure TProjectOutputSaver.SaveLinks( S : TStream );
var
    i : integer;
    Item : TveBoardItem;
    NewItem : TveBoardItem;
begin
    LineOut( '"Links" : [', S );

    Item := nil;
    for i := 0 to FProject.BoardItemCount -1 do begin
        NewItem := FProject.BoardItems[i];
        if NewItem.Outline is TveLinkOutline then begin

            // if an item in storage then emit it with a comma
            if Item <> nil then begin

                LineOut( Format( '  { "X" : %d, "Y" : %d, "EndDeltaX" : %d, "EndDeltaY" : %d, "Group" : %d },',
                [ Item.X, Item.Y, Item.EndDeltaX, Item.EndDeltaY, Item.Group ] ), S);
            end;

            // store item for next time
            Item := NewItem;
        end;
    end;

    // emit last link with no comma
    if Item <> nil then begin
        LineOut( Format( '  { "X" : %d, "Y" : %d, "EndDeltaX" : %d, "EndDeltaY" : %d, "Group" : %d }',
        [ Item.X, Item.Y, Item.EndDeltaX, Item.EndDeltaY, Item.Group ] ), S);
    end;

    // end of array of Links
    LineOut( '],', S );
end;


procedure TProjectOutputSaver.SaveBreaks( S : TStream );

const ShiftToStr : array[TveShift] of string = ( 'none', 'right', 'down' );

var
    i : integer;
    Item : TveBoardItem;
    NewItem : TveBoardItem;
begin
    LineOut( '"Breaks" : [', S );

    Item := nil;
    for i := 0 to FProject.BoardItemCount -1 do begin
        NewItem := FProject.BoardItems[i];
        if NewItem.Outline is TveBreakOutline then begin

            // if an item in storage then emit it with a comma
            if Item <> nil then begin
                LineOut( Format( '  { "X" : %d, "Y" : %d, "Shift" : "%s", "Group" : %d },',
                [ Item.X, Item.Y, ShiftToStr[Item.Shift], Item.Group ] ), S);
            end;

            // store item for next time
            Item := NewItem;
        end;
    end;

    // emit last break with no comma
    if Item <> nil then begin
        LineOut( Format( '  { "X" : %d, "Y" : %d, "Shift" : "%s", "Group" : %d }',
        [ Item.X, Item.Y, ShiftToStr[Item.Shift], Item.Group ] ), S);
    end;

    // end of array of Breaks
    LineOut( '],', S );
end;

procedure TProjectOutputSaver.SaveWires( S : TStream );
var
    i : integer;
    Item : TveBoardItem;
    NewItem : TveBoardItem;
begin
    LineOut( '"Wires" : [', S );

    Item := nil;
    for i := 0 to FProject.BoardItemCount -1 do begin
        NewItem := FProject.BoardItems[i];
        if NewItem.Outline is TveWireOutline then begin

            // if an item in storage then emit it with a comma
            if Item <> nil then begin
                LineOut( Format( '    { "Value" : "%s", "X" : %d, "Y" : %d, "Group" : %d },',
                [ Item.Value, Item.X, Item.Y, Item.Group ] ), S );
            end;

            // store item for next time
            Item := NewItem;
        end;
    end;

    // emit last Wire with no comma
    if Item <> nil then begin
        LineOut( Format( '    { "Value" : "%s", "X" : %d, "Y" : %d, "Group" : %d }',
        [ Item.Value, Item.X, Item.Y, Item.Group ] ), S );
    end;

    // end of array of Wires
    LineOut( '],', S );
end;

procedure TProjectOutputSaver.SaveTexts( S : TStream );

const TextSize2Str : array[TTextSize] of string = ( 'Small', 'Large' );
var
    i : integer;
    Item : TveBoardItem;
    NewItem : TveBoardItem;
begin
    LineOut( '"Text" : [', S );

    Item := nil;
    for i := 0 to FProject.BoardItemCount -1 do begin
        NewItem := FProject.BoardItems[i];
        if NewItem.Outline is TveTextOutline then begin

            // if an item in storage then emit it with a comma
            if Item <> nil then begin
                LineOut( Format( '    { "Value" : "%s", "X" : %d, "Y" : %d, "Angle" : %s, "Size" : "%s", "Group" : %d },',
                [ JEsc(Item.Value), Item.X, Item.Y, RotToStr[Item.Rotation],
                TextSize2Str[TveTextOutline(Item.Outline).GetSize(Item)], Item.Group ] ), S );
            end;
            // store item for next time
            Item := NewItem;
        end;
    end;

    // emit last Test with no comma
    if Item <> nil then begin
        LineOut( Format( '    { "Value" : "%s", "X" : %d, "Y" : %d, "Angle" : %s, "Size" : "%s", "Group" : %d }',
        [ JEsc(Item.Value), Item.X, Item.Y, RotToStr[Item.Rotation],
        TextSize2Str[TveTextOutline(Item.Outline).GetSize(Item)], Item.Group ] ), S );
    end;

    // end of array of Wires
    LineOut( '],', S );
end;

procedure TProjectOutputSaver.SaveNetlist( S : TStream );
var
    Netlist : TneNetlist;

    i : integer;
    Node : TneNode;

    Line : string;
    j : integer;
    Pin : TnePin;
    LastComponent : TneComponent;
    Last : integer;
begin
    Netlist := FProject.Netlist;

    // get nodes in alphabetical order.
    // Within each node, sort by components, then by component pins
    Netlist.SortNodes;

    LineOut( '"Nets" : [', S );

    // for each node
    Last := Netlist.NodeCount -1;
    for i := 0 to Netlist.NodeCount -1 do begin
        Node := Netlist.Nodes[i];

        // Emit start of Node object and open an array
        // '    VCC " [
        LineOut( Format( '    { "Node" : "%s", "Components" : [', [JEsc(Node.Name)] ), S );

        // add pins connecting to the node
        LastComponent := nil;
        for j := 0 to Node.PinCount -1 do begin

            // get next node pin
            Pin := Node.Pins[j];

            // if new component encountered
            // Node pins are in Component, PinNo order, so we encounter
            // blocks of each component.  (Netlist.SortNodes gives
            // us this order).
            if Pin.Component <> LastComponent then begin

                // remember current component
                LastComponent := Pin.Component;

                // output last pin, and end the component pins line and close
                // object (including a comma)
                if Line <> '' then begin
                    LineOut( Line + '] },', S );
                    Line := '';
                end;

                // start line for current component
                Line := Format( '    { "Name" : "%s", "Pins" : [', [JEsc(LastComponent.Name)] );

                // add pin member of array of pins
                Line := Line  + '"' + Pin.Name + '"';

            end
            else begin
                // add pin member of array of pins
                Line := Line  + ', "' + Pin.Name + '"';
            end;
        end;

        // output component line still in the pipeline - without comma
        if Line <> '' then begin
            LineOut( Line + '] }', S );
            Line := '';
        end;

        // close Component Pin array
        if i = Last then begin
            // don't add a comma - this is last Node
            LineOut( '    ] }', S );
        end
        else begin
            LineOut( '    ] },', S );
        end;
    end;

    // close Nets object.
    LineOut( '],', S );
end;

(*
"NetColors" : [
    { "Node" : "GND" },
    { "Node" : "VCC" },
    { "Node" : "N000001" },
    { "Node" : "N000008" }
]
*)
procedure TProjectOutputSaver.SaveNetColors( S : TStream );
var
    Netlist : TneNetlist;
    i : integer;
    Node : TneNode;
    NodeName : string;
begin
    Netlist := FProject.Netlist;
    // beginning of JSON array
    LineOut( '"NetColors" : [', S );

    // output nodes in array order
    for i := 0 to TneNetlist.ColoredNodeCount - 1 do begin

        Node := Netlist.ColoredNodes[i];
        if Node = nil then begin
            NodeName := '';
        end
        else begin
            NodeName := Node.Name;
        end;

        TextOut( Format( '    { "Node" : "%s" }', [NodeName] ), S );

        // finish line with comma, except for last element in array
        if i < TneNetlist.ColoredNodeCount -1 then begin
            LineOut( ',', S );
        end
        else begin
            LineOut( '', S );
        end;
    end;

    // close JSON array of NetColors
    LineOut( '],', S );
end;

(*
"Notes" : {
  "Lines" : "Hello World"
}
*)
procedure TProjectOutputSaver.SaveNotes( S : TStream );
begin
  LineOut( '"Notes" : {', S );
  LineOut( Format( '  "Lines" : "%s"', [JEsc(FProject.NotesLines)] ), S );
  // close JSON object
  LineOut( '}', S );
end;




end.


