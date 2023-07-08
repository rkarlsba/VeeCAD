unit TinyCadRead;

interface

uses Read, SqliteWrap, Rotations, NativeXML, Types, Contnrs;


type TTinyCadReader = class( TSymbolLibraryReader )
  protected
    FileName : string;

    // database access
    database : TSqliteDatabase;
    table : TSqliteTable;
    NameIndex : integer;
    ReferenceIndex : integer;
    DescriptionIndex : integer;
    PartsPerPackageIndex : integer;
    PackageIndex : integer;
    DrawingIndex : integer;

    // properties
{
    FName : string;
    FReference : string;
    FDescription : string;
    FPartsPerPackage : integer;
    FPackage : string;
}
    FPins : array of TPin;
    FPinCount : integer;

    FPolygons : TObjectList;
    FPolygonCount : integer;

    FCircles : array of TCircle;
    FCircleCount : integer;

    FRectangles : array of TRectangle;
    FRectangleCount : integer;

    FArcs : array of TArc;
    FArcCount : integer;

    // internal processing
    FDrawing : string;

    // properties
    function GetEOF : boolean; override;
    function GetPin( Index : integer ) : TPin; override;
    function GetPolygon( Index : integer ) : TPolygon; override;
    function GetCircle( Index : integer ) : TCircle; override;
    function GetRectangle( Index : integer ) : TRectangle; override;
    function GetArc( Index : integer ) : TArc; override;

    function GetPinCount : integer; override;
    function GetPolygonCount : integer; override;
    function GetCircleCount : integer; override;
    function GetRectangleCount : integer; override;
    function GetArcCount : integer; override;

    // internal processing
    procedure ReadTableRow;
    procedure DecodeDrawing;
    procedure ParseDrawingItems( Node : TXmlNode );
    procedure ParseFont( Node : TXmlNode );
    procedure ParseStyle( Node : TXmlNode );
    procedure ParseFill( Node : TXmlNode );
    procedure ParsePin( Node : TXmlNode );
    procedure ParsePolygon( Node : TXmlNode );
    procedure ParseEllipse( Node : TXmlNode );
    procedure ParseRectangle( Node : TXmlNode );
    procedure ParseText( Node : TXmlNode );
    procedure ParseWire( Node : TXmlNode );
    procedure PolygonToArc( Polygon : TPolygon; ArcType : integer );


  public
    procedure Next; override;
//    property EOF : boolean read GetEOF;

    {
    Property Arcs
    property ArcCount

    property Text
    property TextCount
}

    constructor Create( const FileName : string ); override;
    destructor Destroy; override;
end;



implementation

uses SysUtils, Math;

type EReader = class( Exception );


// **************************************************
//                  UTILITY
// **************************************************

// Convert CSV pair to Point type '28.00000,20.00000'
function StrToFloatPoint( const s : string ) : TFloatPoint;
var
    CommaPos : integer;
begin
    CommaPos := Pos( ',', s );
    result.X := StrToFloat( Copy( s, 1, CommaPos -1 ) );
    result.Y := StrToFloat( Copy( s, CommaPos + 1, 255 ) );
end;

// convert Pin direction attribute to TRotation
function DirectionToRotation( direction : integer ) : TRotation;
const
    Dir2Rot : array[0..3] of TRotation = ( Rot90, Rot270, Rot180, Rot0 );
begin
    result := Dir2Rot[direction];
end;

// **************************************************
//            TTinyCadReader PROPERTIES
// **************************************************

function TTinyCadReader.GetPin( Index : integer ) : TPin;
begin
    result := FPins[Index];
end;

function TTinyCadReader.GetPolygon( Index : integer ) : TPolygon;
begin
    result := TPolygon( FPolygons[Index] );
end;

function TTinyCadReader.GetCircle( Index: Integer ) : TCircle;
begin
    result := FCircles[Index];
end;

function TTinyCadReader.GetRectangle( Index : integer ) : TRectangle;
begin
    result := FRectangles[Index];
end;

function TTinyCadReader.GetArc( Index : integer ) : TArc;
begin
    result := FArcs[Index];
end;

function TTinyCadReader.GetPinCount : integer;
begin
    result := FPinCount;
end;

function TTinyCadReader.GetPolygonCount : integer;
begin
    result := FPolygonCount;
end;

function TTinyCadReader.GetCircleCount : integer;
begin
    result := FCircleCount;
end;

function TTinyCadReader.GetRectangleCount : integer;
begin
    result := FRectangleCount;
end;

function TTinyCadReader.GetArcCount : integer;
begin
    result := FArcCount;
end;

// **************************************************
//            TTinyCadReader CREATE, DESTROY
// **************************************************

constructor TTinyCadReader.Create( const FileName : string );
begin
    self.FileName := FileName;

    // create data objects
    FPolygons := TObjectList.Create;


    // open file as Sqlite3 database
    database := TSqliteDatabase.Create( FileName );
    table := database.GetTable(

      'SELECT Name, Reference, Description, ppp, Symbol.Data, AttValue ' +
      'FROM Name, Symbol, Attribute ' +
      'WHERE Name.SymbolID = Symbol.SymbolID ' +
      'AND Name.NameID = Attribute.NameID ' +
      'AND Attribute.AttName = "Package" ' +
      'ORDER BY Name.Name'
    );
{
# |Name            |Reference|Description     |ppp|AttValue        |Data
--+----------------+---------+----------------+---+----------------+----------------
1 |2 Part Symbol   |U?       |New symbol      |2  |package name for|<?xml version="1
2 |Arc 1st Quadrant|U?       |New symbol      |1  |package name for|<?xml version="1
3 |Arc 2nd Quadrant|U?       |New symbol      |1  |package name for|<?xml version="1
4 |Arc 3rd Quadrant|U?       |New symbol      |1  |package name for|<?xml version="1
5 |Arc 4th Quadrant|U?       |Drawn from botto|1  |package name for|<?xml version="1
}
    // get field indexes
    NameIndex := Table.FieldIndex['Name'];
    ReferenceIndex := Table.FieldIndex['Reference'];
    DescriptionIndex := Table.FieldIndex['Description'];
    PartsPerPackageIndex := Table.FieldIndex['ppp'];
    PackageIndex := Table.FieldIndex['AttValue'];
    DrawingIndex := Table.FieldIndex['Data'];

    // read in first symbol data
    if not Table.EOF then begin
        ReadTableRow;
    end;
end;

destructor TTinyCadReader.Destroy;
begin
    table.free;
    database.free;
    FPolygons.Free;
    inherited;
end;


// **************************************************
//         TTinyCadReader STEP THRU SYMBOLS
// **************************************************

procedure TTinyCadReader.Next;
begin
    Table.Next;
    if not Table.EOF then begin
        ReadTableRow;
    end;
end;

function TTinyCadReader.GetEOF : boolean;
begin
    result := Table.EOF;
end;

procedure TTinyCadReader.ReadTableRow;
var
    TempReference : string;
begin
    try
        FName := Table.FieldAsString( NameIndex );
        // reference standard form omits TinyCAD question mark
        TempReference := Table.FieldAsString( ReferenceIndex );
        FReference := SysUtils.StringReplace( TempReference, '?', '',  [rfReplaceAll] );
        FDescription := Table.FieldAsString( DescriptionIndex );
        FPartsPerPackage := Table.FieldAsInteger( PartsPerPackageIndex );
        FPackage := Table.FieldAsString( PackageIndex );

    //    FDrawing := Table.FieldAsString( DrawingIndex );
        FDrawing := string(Table.FieldAsBlobText( DrawingIndex ));
        DecodeDrawing;
    except
        On E:Exception do begin
            raise Exception.CreateFmt(
            'Error in file %s. %s', [FileName, E.Message] );
        end;
    end;
end;


// **************************************************
//          TTinyCadReader READ XML DRAWING
// **************************************************

procedure TTinyCadReader.DecodeDrawing;
var
    XML : TNativeXML;
    Node : TXMLNode;
begin
    // empty
    FPinCount := 0;
    FPolygonCount := 0;
    FCircleCount := 0;
    FRectangleCount := 0;
    FArcCount := 0;

    // work through the XML
    XML := TNativeXML.Create;
    try
        XML.ReadFromString( UTF8String(FDrawing) );

        // root node
        Node := XML.Root;
        if Node.Name = 'TinyCAD' then begin
            ParseDrawingItems( Node );
        end
        else begin
            raise EReader.Create( 'root node <TinyCAD> not found' );
        end;
    finally
        XML.Free;
    end;
end;

procedure TTinyCadReader.ParseDrawingItems( Node : TXmlNode );
var
    i : integer;
    Name : string;
    iChildNode : TXMLNode;
begin
    for i := 0 to Node.NodeCount -1 do begin

        iChildNode := Node.Nodes[i];

        Name := string( iChildNode.Name );

        if Name = 'FONT' then begin
            ParseFont( iChildNode );
        end
        else if Name = 'STYLE' then begin
            ParseStyle( iChildNode );
        end
        else if Name = 'FILL' then begin
            ParseFill( iChildNode );
        end
        else if Name = 'PIN' then begin
            ParsePin( iChildNode );
        end
        else if Name = 'POLYGON' then begin
            ParsePolygon( iChildNode );
        end
        else if Name = 'ELLIPSE' then begin
            ParseEllipse( iChildNode );
        end
        else if Name = 'RECTANGLE' then begin
            ParseRectangle( iChildNode );
        end
        else if Name = 'TEXT' then begin
            ParseText( iChildNode );
        end
        else if Name = 'WIRE' then begin
            ParseWire( iChildNode );
        end
        else begin
            raise EReader.CreateFmt( 'Unknown node name: "%s" in file %s', [Name, FileName] );
        end;
    end;
end;

{
	<FONT id='1'>
		<HEIGHT>-10</HEIGHT>
		<WIDTH>0</WIDTH>
		<WEIGHT>400</WEIGHT>
		<ITALIC>0</ITALIC>
		<UNDERLINE>0</UNDERLINE>
		<STRIKEOUT>0</STRIKEOUT>
		<CHARSET>0</CHARSET>
		<FACENAME>Arial</FACENAME>
</FONT>
}
procedure TTinyCadReader.ParseFont( Node : TXmlNode );
begin

end;

{
<STYLE id='2'>
		<STYLE>0</STYLE>
		<COLOR>000000</COLOR>
		<THICKNESS>1</THICKNESS>
</STYLE>
}
procedure TTinyCadReader.ParseStyle( Node : TXmlNode );
begin

end;

{
<FILL id='0'>
		<INDEX>-1</INDEX>
		<COLOR>000000</COLOR>
	</FILL>
}
procedure TTinyCadReader.ParseFill( Node : TXmlNode );
begin

end;

{
<PIN pos='28.00000,20.00000' which='0' elec='4' direction='1' part='0' number='4'
  show='2' length='20' number_pos='0' centre_name='0'>Collector</PIN>
}
procedure TTinyCadReader.ParsePin( Node : TXmlNode );
var
    Pin : TPin;
    Position : string;
    Direction : integer;
    Show : integer;
begin
    Pin.Number := string( Node.ReadAttributeString( 'number' ) );

    Position := string( Node.ReadAttributeString( 'pos' ) );
    Pin.Position := StrToFloatPoint( Position );

    Direction := Node.ReadAttributeInteger( 'direction' );
    Pin.Rotation := DirectionToRotation( Direction );

    Pin.Part := Node.ReadAttributeInteger( 'part' );

    // pin length units are millimetres x 5
    Pin.Length := Node.ReadAttributeFloat( 'length' ) * ( 0.2 );

    // pin name : blank if hidden
    Show := Node.ReadAttributeInteger( 'show' );
    if Show <> 3 then begin
        Pin.Name := '';
    end
    else begin
        Pin.Name := Node.ValueAsUnicodeString;
    end;

    if FPinCount >= Length(FPins) then begin
        SetLength( FPins, FPinCount + 50 );
    end;
    FPins[FPinCount] := Pin;
    Inc( FPinCount );
end;

{
<POLYGON pos='24.00000,22.00000' style='2' fill='0'>
		<POINT pos='0.00000,0.00000' arc='0'/>
		<POINT pos='9.00000,4.00000' arc='0'/>
		<POINT pos='0.00000,8.00000' arc='0'/>
</POLYGON>

Polygons with a point containing attribute "arc='2' are actually "bent" lines
and we will map these as arcs.
}
procedure TTinyCadReader.ParsePolygon( Node : TXmlNode );
var
    Polygon : TPolygon;
    Position : string;

    i : integer;
    iChildNode : TXMLNode;
    Name : string;
    Point : TFloatPoint;

    ArcType : integer;
begin
    // need access to a new TPolygon
    // need to create a new TPolygon
    if FPolygonCount >= FPolygons.Count then begin
        Polygon := TPolygon.Create;
        FPolygons.Add( Polygon );
    end
    // reuse old TPolygon
    else begin
        Polygon := TPolygon( FPolygons[FPolygonCount] );
    end;

    // another polygon
    Inc( FPolygonCount );

    // read position
    Position := string( Node.ReadAttributeString( 'pos' ) );
    Polygon.Position := StrToFloatPoint( Position );

    // "polygon" can actually be an arc in TinyCAD. In fact, a polygon can
    // contain arc segments, but in this converter, we discard the polygon
    // if an arc segment is met as the first and only segment and draw only the
    // arc. If the polygon contains multiple segments we raise an exception.
    ArcType := 0;

    // read points
    Polygon.Clear;
    for i := 0 to Node.NodeCount -1 do begin

        iChildNode := Node.Nodes[i];
        Name := string( iChildNode.Name );

        if Name = 'POINT' then begin

          Position := string( iChildNode.ReadAttributeString( 'pos' ) );
          Point := StrToFloatPoint( Position );
          Polygon.AddPoint( Point );

          ArcType := iChildNode.ReadAttributeInteger( 'arc' );
        end

        // only expect <POINT ..> tags inside <POLYGON ..>
        else begin
            raise EReader.CreateFmt( 'Unknown polygon child node name: "%s"', [Name] );
        end;
    end;

    // if "polygon" turns out to be an arc!
    if ArcType <> 0 then begin

        // steal back the polygon ( it is still available, but not visible )
        // and will be allocated to the next polygon required
        dec( FPolygonCount );

        // make an arc
        PolygonToArc( Polygon, ArcType );
    end;
end;

// Draw an arc between the two points contained in Polygon. If ArcType=1 then
// bow right as you move from the first to the second point. If ArcTyp3=2
// then bow left.

procedure TTinyCadReader.PolygonToArc( Polygon : TPolygon; ArcType : integer );
var
    Arc : TArc;
    Radius : single;
    Centre : TFloatPoint;
begin
    // arcs only have 2 points
    if Polygon.PointCount <> 2 then begin
        raise EReader.CreateFmt(
          'Polygon "arc" has %d points: required 2 points. Symbol %s',
          [Polygon.PointCount, FName] );
    end;

    // ArcType must be 1 or 2
    if (ArcType <> 1) and (ArcType <> 2) then begin
        raise EReader.CreateFmt(
          'Polygon "arc" type of %d is unknown. Symbol %s', [ArcType, FName] );
    end;

    // our arcs are only quadrants : fitting in a rectangular bounding box
    // of side length = radius
    Radius := Abs(Polygon.Points[0].x - Polygon.Points[1].x);

    // arc must be circular
    if Radius <> Abs(Polygon.Points[0].y - Polygon.Points[1].y) then begin
        raise EReader.CreateFmt(
          'Arc not circular in symbol %s', [FName] );
    end;

    Arc.Radius := Radius;

{   We have 8 arcs possible.                             *=good, other
P1=(0,y), P2=(x,0)
      type 1 centre=(0,y), angles start=270, end=0       *
      type 2 centre=(x,0)  angles start=90, end=180      *

P1=(x,y), P2=(0,0)
      type 1 centre=(x,y), angles start=180, end=270     *
      type 2 centre=(0,0)  angles start=0, end=90        *

P1=(0,0), P2=(x,y)
      type 1 centre=(0,0), angles start=0, end=90        *
      type 2 centre=(x,y)  angles start=180, end=270     *

P1=(x,0), P2=(0,y)
      type 1 centre=(x,0), angles start=90, end=180      *
      type 2 centre=(0,y)  angles start=270, end=0       *
}
    //Arc.Centre := Polygon.Position;

    // radius is smaller of two sides of rectangle
    Arc.Radius :=
        Min(
        Abs(Polygon.Points[0].x - Polygon.Points[1].x),
        Abs(Polygon.Points[0].y - Polygon.Points[1].y)
        );

    // find how to draw this arc: 8 types possible
    if Polygon.Points[0].x = 0.0 then begin
        if Polygon.Points[0].y = 0.0 then begin
          // P1=(0,0), P2=(x,y)
          // type 1 centre=(0,0), angles start=0, end=90
            if ArcType = 1 then begin
                Centre.X := 0;
                Centre.Y := Radius;
                Arc.StartAngleDegrees := 0;
                Arc.EndAngleDegrees := 90.0;
            end
          //type 2 centre=(x,y)  angles start=180, end=270
            else begin
                Centre.X := Radius;
                Centre.Y := 0; // Radius; RKKL
                Arc.StartAngleDegrees := 180.0;
                Arc.EndAngleDegrees := 270.0;
            end;
        end
        else begin
          // P1=(0,y), P2=(x,0)
          // type 1 centre=(0,y), angles start=270, end=0
            if ArcType = 1 then begin
                Centre.X := 0;
                Centre.Y := 0;
                Arc.StartAngleDegrees := 270.0;
                Arc.EndAngleDegrees := 0;
            end
          // type 2 centre=(x,0)  angles start=90, end=180
            else begin
                Centre.X := Radius;
                Centre.Y := Radius;
                Arc.StartAngleDegrees := 90.0;
                Arc.EndAngleDegrees := 180.0;
            end;
        end;
    end
    else begin
        if Polygon.Points[0].y = 0.0 then begin
            // P1=(x,0), P2=(0,y)
            // type 1 centre=(x,0), angles start=90, end=180
            if ArcType = 1 then begin
                Centre.X := Radius;
                Centre.Y := 0;
                Arc.StartAngleDegrees := 90.0;
                Arc.EndAngleDegrees := 180.0;
            end
            // type 2 centre=(0,y)  angles start=270, end=0
            else begin
                Centre.X := 0;
                Centre.Y := 0;
                Arc.StartAngleDegrees := 270.0;
                Arc.EndAngleDegrees := 0;
            end;
        end
        else begin
          // P1=(x,y), P2=(0,0)
            // type 1 centre=(x,y), angles start=180, end=270
            if ArcType = 1 then begin
                Centre.X := Radius;
                Centre.Y := Radius;
                Arc.StartAngleDegrees := 180.0;
                Arc.EndAngleDegrees := 270.0;
            end
            // type 2 centre=(0,0)  angles start=0, end=90
            else begin
                Centre.X := 0;
                Centre.Y := Radius;
                Arc.StartAngleDegrees := 0;
                Arc.EndAngleDegrees := 90.0;
            end;
        end;
    end;

    // add the poition to the centre coords to get absolute values
    Arc.Centre.X := Polygon.Position.x + Centre.x;
    Arc.Centre.Y := Polygon.Position.y + Centre.y;

    if FArcCount >= Length(FArcs) then begin
        SetLength( FArcs, FArcCount + 50 );
    end;
    FArcs[FArcCount] := Arc;
    Inc( FArcCount );
end;


{
<ELLIPSE a='18.00000,11.00000' b='31.00000,24.00000' style='2' fill='0'/>
// We turn ellipses into circles. Too bad if ellipse width <> height - we
// use just width. In a schematic these are rare or useless.
}
procedure TTinyCadReader.ParseEllipse( Node : TXmlNode );
var
    TopLeft_s : string;
    BottomRight_s : string;

    TopLeft : TFloatPoint;
    BottomRight : TFloatPoint;

    Circle : TCircle;
begin
    TopLeft_s := string( Node.ReadAttributeString( 'a' ) );
    TopLeft := StrToFloatPoint( TopLeft_s );

    BottomRight_s := string( Node.ReadAttributeString( 'b' ));
    BottomRight := StrToFloatPoint( BottomRight_s );

    Circle.Radius := Abs(TopLeft.x - BottomRight.x) * 0.5;
    Circle.Centre.x := (TopLeft.x + BottomRight.x) * 0.5;
    Circle.Centre.y := (TopLeft.y + BottomRight.y) * 0.5;

    // add our circle to FCircles[]
    if FCircleCount >= Length(FCircles) then begin
        SetLength( FCircles, FCircleCount + 20 );
    end;
    FCircles[FCircleCount] := Circle;
    Inc( FCircleCount );
end;

{
<RECTANGLE a='26.00000,24.00000' b='41.00000,51.00000' style='2' fill='0'/>
(26,24) are coords of top, left.  (41,51) are coords of bottom, right. No relative coords used.
}
procedure TTinyCadReader.ParseRectangle( Node : TXmlNode );
var
    TopLeft_s : string;
    BottomRight_s : string;

    TopLeft : TFloatPoint;
    BottomRight : TFloatPoint;

    Rectangle : TRectangle;
begin
    TopLeft_s := string( Node.ReadAttributeString( 'a' ) );
    TopLeft := StrToFloatPoint( TopLeft_s );

    BottomRight_s := string( Node.ReadAttributeString( 'b' ) );
    BottomRight := StrToFloatPoint( BottomRight_s );

    Rectangle.TopLeft := TopLeft;
    Rectangle.BottomRight := BottomRight;

    // add our rectangle to FRectanges[]
    if FRectangleCount >= Length(FRectangles) then begin
        SetLength( FRectangles, FRectangleCount + 20 );
    end;
    FRectangles[FRectangleCount] := Rectangle;
    Inc( FRectangleCount );
end;

{
<TEXT pos='45.00000,25.00000' direction='3' font='0' color='000000'>Hello World</TEXT>
(45,25) is top, left of text bounding rectangle. Direction=3 is normal horizontal text.
}
procedure TTinyCadReader.ParseText( Node : TXmlNode );
begin

end;

procedure TTinyCadReader.ParseWire( Node : TXmlNode );
begin
end;

end.
