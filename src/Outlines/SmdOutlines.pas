unit SmdOutlines;

interface

uses Outlines, Painter, Contnrs, Classes, Types;

// Board Cells are divided into Fine Divisions - shapes are located by MiniCell
// coords, while pins are located by ordinary Cell coords.


type TsmShape = class
  protected
    FXDiv : integer;
    FYDiv : integer;
    FSelected : boolean;
    procedure SetXDiv( value : integer ); virtual;
    procedure SetYDiv( value : integer ); virtual;
  public
    property XDiv : integer read FXDiv write SetXDiv;
    property YDiv : integer read FYDiv write SetYDiv;
    property Selected : boolean read FSelected write FSelected;
    // bounding rectangle which contains item
    procedure GetRectangle( var Left, Top, Right, Bottom : integer ); virtual; abstract;
    procedure GetDivRectangle( var Left, Top, Right, Bottom : integer ); virtual; abstract;
    procedure Paint( Item : TveBoardItem; Info : TvePainter ); virtual; abstract;
    function DistanceToPoint( Item : TveBoardItem; PointX, PointY : integer ) : integer; virtual; abstract;
    function Clone : TsmShape; virtual; abstract;
    function Identical( Shape : TsmShape ) : boolean; virtual; abstract;
end;

type TsmLine = class( TsmShape )
    FEndDeltaXDiv : integer;
    FEndDeltaYDiv : integer;
    procedure SetEndDeltaXDiv( value : integer );
    procedure SetEndDeltaYDiv( value : integer );
  public
    property EndDeltaXDiv : integer read FEndDeltaXDiv write SetEndDeltaXDiv;
    property EndDeltaYDiv : integer read FEndDeltaYDiv write SetEndDeltaYDiv;
    procedure GetRectangle( var Left, Top, Right, Bottom : integer ); override;
    procedure GetDivRectangle( var Left, Top, Right, Bottom : integer ); override;
    procedure Paint( Item : TveBoardItem; Info : TvePainter ); override;
    function DistanceToPoint( Item : TveBoardItem; PointX, PointY : integer ) : integer; override;
    function StartIsNearestPoint( Item : TveBoardItem; PointX, PointY : integer ) : boolean;
    function Clone : TsmShape; override;
    function Identical( Shape : TsmShape ) : boolean; override;
end;

type TsmPin = class( TsmShape )
  protected
    procedure SetXDiv( value : integer ); override;
    procedure SetYDiv( value : integer ); override;
  public
    Name : string;
    WidthDiv : integer;
    HeightDiv : integer;
    procedure GetRectangle( var Left, Top, Right, Bottom : integer ); override;
    procedure GetDivRectangle( var Left, Top, Right, Bottom : integer ); override;
    procedure Paint( Item : TveBoardItem; Info : TvePainter ); override;
    function DistanceToPoint( Item : TveBoardItem; PointX, PointY : integer ) : integer; override;
    function Clone : TsmShape; override;
    function Identical( Shape : TsmShape ) : boolean; override;
end;


type TveSmdOutline = class( TveOutline )

  protected
    NextShapeIndex : integer;
    NextPinIndex : integer;
    FShapes : TObjectList;
    function GetShape( index : integer ) : TsmShape;
    function GetShapeCount : integer;
    function GetPin( index : integer ) : TvePin; override;
  public

    property Shapes[index : integer] : TsmShape read GetShape;
    property ShapeCount : integer read GetShapeCount;
    function CreateLine : TsmLine;
    function CreatePin : TsmPin;
    procedure AddShape( Shape : TsmShape );
    procedure DeleteShape( Shape : TsmShape );
    procedure BuildPinList;

    constructor Create; override;
    destructor Destroy; override;

    function Clone : TveOutline; override;
    function Identical( Outline : TveOutline ) : boolean; override;

    procedure Paint( Item : TveBoardItem; Info : TvePainter ); override;

    function OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
        : boolean; override;

    procedure RotateAboutCenter( Item : TveBoardItem ); override;

    function PinIndexAt( Item : TveBoardItem; CellX, CellY : integer )
        : integer; override;

    procedure GetScreenRectR( Item : TveBoardItem; var R : TRect ); override;

    function PinIndexByName( const Name : string ) : integer; override;

    procedure ToFirstPin; override;
    function GetNextPin(
        Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean; override;
    function GetNextPinDiv(
        Item : TveBoardItem; var Rect : TRect; var PinIndex : integer ) : boolean;
    procedure WriteToStream( S : TStream ); override;
    procedure ReadFromStream( S : TStream ); override;

{
    // outline editor functions
    function GetSpecifiedShapeAtSubCellXY(
        Item : TveBoardItem; SubCellX, SubCellY : integer; ShapeClass : TClass ) : TsmShape;
    function GetShapeAtSubCellXY(
        Item : TveBoardItem; SubCellX, SubCellY : integer ) : TsmShape;
    procedure UnselectAllShapes;
    function GetSelectedCount : integer;
    property SelectedCount : integer read GetSelectedCount;
    function SelectionIncludesPin : boolean;
}
end;


implementation

uses Rotations, SysUtils, Windows, ParseCSV, Rectangles;

// **************************************************
//                  TcoShape
// **************************************************

procedure TsmShape.SetXDiv( value : integer );
begin
    FXDiv := value;
end;

procedure TsmShape.SetYDiv( value : integer );
begin
    FYDiv := value;
end;

// **************************************************
//                  TcoLine
// **************************************************

procedure TsmLine.SetEndDeltaXDiv( value : integer );
begin
    // do not allow zero length
    if (value = 0) and (FEndDeltaYDiv = 0) then begin
        FEndDeltaYDiv := 100;
    end;
    FEndDeltaXDiv := value;
end;

procedure TsmLine.SetEndDeltaYDiv( value : integer );
begin
    // do not allow zero length
    if (value = 0) and (FEndDeltaXDiv = 0) then begin
        FEndDeltaXDiv := 100;
    end;
    FEndDeltaYDiv := value;
end;


// Get Rectangle Enclosing Line, in Un-Rotated Position, in Cell Units,
// with origin at 0,0
procedure TsmLine.GetRectangle( var Left, Top, Right, Bottom : integer );
begin
    if EndDeltaXDiv > 0 then begin
        Left := (XDiv + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
        Right := (XDiv + EndDeltaXDiv + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
    end
    else begin
        Left := (XDiv + EndDeltaXDiv + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
        Right := (XDiv + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
    end;

    if EndDeltaYDiv > 0 then begin
        Top := (YDiv + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
        Bottom:= ((YDiv + EndDeltaYDiv) + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
    end
    else begin
        Top := ((YDiv + EndDeltaYDiv) + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
        Bottom := (YDiv + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
    end;
end;


// get rectangle in sub cell units, not relative to any component, but
// unrotated with origin at 0,0 . Not a bounding rectangle
procedure TsmLine.GetDivRectangle( var Left, Top, Right, Bottom : integer );
begin
    if EndDeltaXDiv > 0 then begin
        Left := XDiv;
        Right := XDiv + EndDeltaXDiv;
    end
    else begin
        Left := XDiv + EndDeltaXDiv;
        Right := XDiv;
    end;

    if EndDeltaYDiv > 0 then begin
        Top := YDiv;
        Bottom := YDiv + EndDeltaYDiv;
    end
    else begin
        Top := YDiv + EndDeltaYDiv;
        Bottom := YDiv;
    end;
end;


procedure TsmLine.Paint( Item : TveBoardItem; Info : TvePainter );
var
    BodyLines : TPolyLines;

    ComponentXDiv, ComponentYDiv : integer;

    // LDiv coords between start x1, y1 and end x2, y2
    X1, Y1, X2, Y2 : integer;

    PixelsPerCell : integer;

    Rotation : TRotation;
    RotationX, RotationY : integer;

    procedure Line( X1, Y1, X2, Y2 : integer );
    begin
        Rotate( X1, Y1, RotationX, RotationY, Rotation );
        Rotate( X2, Y2, RotationX, RotationY, Rotation );
        X1 := ((X1 + (DIVS_PER_CELL div 2)) * PixelsPerCell) div DIVS_PER_CELL;
        Y1 := ((Y1 + (DIVS_PER_CELL div 2)) * PixelsPerCell) div DIVS_PER_CELL;
        X2 := ((X2 + (DIVS_PER_CELL div 2)) * PixelsPerCell) div DIVS_PER_CELL;
        Y2 := ((Y2 + (DIVS_PER_CELL div 2)) * PixelsPerCell) div DIVS_PER_CELL;

        BodyLines.AddLine( X1, Y1, X2, Y2 );
    end;

begin
    BodyLines := Info.BodyLines;

    PixelsPerCell := Info.PixelsPerCell;
    Rotation := Item.Rotation;

    // Div coords of referece point of Component
    ComponentXDiv := Item.XDiv;
    ComponentYDiv := Item.YDiv;

    // rotation point of Component
    RotationX := ComponentXDiv;
    RotationY := ComponentYDiv;

    // calculate line coords in Div units
    X1 := ComponentXDiv + XDiv;
    Y1 := ComponentYDiv + YDiv;
    X2 := ComponentXDiv + XDiv + EndDeltaXDiv;
    Y2 := ComponentYDiv + YDiv + EndDeltaYDiv;

    Line( X1, Y1, X2, Y2 );
end;

//Compute the dot product AB . BC of the two vectors AB and BC
function dot( A, B, C : TPoint ) : integer;
var
    AB : TPoint;
    BC : TPoint;
begin
     AB.X := B.X - A.X;
     AB.Y := B.Y - A.Y;
     BC.X := C.X - B.X;
     BC.Y := C.Y - B.Y;
     result := (AB.X * BC.X) + (AB.Y * BC.Y);
end;

//Compute the cross product AB x AC
function cross( A, B, C : TPoint ) : integer;
var
    AB : TPoint;
    AC : TPoint;
begin
    AB.X := B.X - A.X;
    AB.Y := B.Y - A.Y;
    AC.X := C.X - A.X;
    AC.Y := C.Y - A.Y;
    result := (AB.X * AC.Y) - (AB.Y * AC.X);
end;

//Compute the distance from A to B
function distance( A, B : TPoint ) : single;
var
    d1 : integer;
    d2 : integer;
begin
    d1 := A.X - B.X;
    d2 := A.Y - B.Y;
    result := sqrt( (d1 * d1) + (d2 * d2) );
end;

//Compute the distance from line segment AB to point C
// AB is a segment, not an infinitely long line, so if line is too short,
// distance is taken to the nearest line end.

function linePointDist( A, B, C : TPoint ) : single;
var
    dist : single;
    dot1 : integer;
    dot2 : integer;
begin
    dot1 := dot( A,B,C );
    if( dot1 > 0 ) then begin
        result := distance(B,C);
        exit;
    end;

    dot2 := dot(B,A,C);
    if( dot2 > 0 ) then begin
        result := distance(A,C);
        exit;
    end;
    dist := cross( A,B,C) / distance(A,B);
    result := abs( dist );
end;

function TsmLine.DistanceToPoint( Item : TveBoardItem; PointX, PointY : integer ) : integer;
var
    PX, PY : integer;
begin
    // make point coords relative to component reference point, sub cell units
    PX := PointX - (Item.X * DIVS_PER_CELL);
    PY := PointY - (Item.Y * DIVS_PER_CELL);

    // reverse rotate point about component reference point
    RotateReverse( PX, PY, 0, 0, Item.Rotation );

    // calculate distance between line and point
    result := abs( round(
        linePointDist( Point(XDiv, YDiv), Point((XDiv + EndDeltaXDiv), (YDiv + EndDeltaYDiv)), Point(PX, PY) )
        ));
end;

function TsmLine.StartIsNearestPoint( Item : TveBoardItem; PointX, PointY : integer ) : boolean;
var
    XDist, YDist : integer;

    // work in distance^2 to save square roots
    StartDistance2 : integer;
    EndDistance2 : integer;
begin
    // distance to start
    XDist := PointX - FXDiv;
    YDist := PointY - FYDiv;
    StartDistance2 := (XDist * XDist) + (YDist * YDist);

    // distance to end
    XDist := PointX - (FXDiv + EndDeltaXDiv);
    YDist := PointY - (FYDiv + EndDeltaYDiv);
    EndDistance2 := (XDist * XDist) + (YDist * YDist);

    // which distance is shorter?
    result := StartDistance2 < EndDistance2;
end;


function TsmLine.Clone : TsmShape;
begin
    result := TsmLine.Create;
    result.XDiv := FXDiv;
    result.YDiv := FYDiv;
    TsmLine( result ).EndDeltaXDiv := FEndDeltaXDiv;
    TsmLine( result ).EndDeltaYDiv := FEndDeltaYDiv;
end;

function TsmLine.Identical( Shape : TsmShape ) : boolean;
begin
    result :=
        (Shape is TsmLine) and
        (TsmLine(Shape).XDiv = FXDiv) and
        (TsmLine(Shape).YDiv = FYDiv) and
        (TsmLine(Shape).EndDeltaXDiv = FEndDeltaXDiv) and
        (TsmLine(Shape).EndDeltaYDiv = FEndDeltaYDiv);
end;


// **************************************************
//                  TcoPin
// **************************************************

procedure TsmPin.SetXDiv( value : integer );
begin
    FXDiv := value;
end;

procedure TsmPin.SetYDiv( value : integer );
begin
    FYDiv := value;
end;

// Get Rectangle Enclosing Pin, in Un-Rotated Position, in Cell Units,
// with origin at 0,0
procedure TsmPin.GetRectangle( var Left, Top, Right, Bottom : integer );
var
    LeftDiv, RightDiv : integer;
    TopDiv, BottomDiv : integer;
begin
    // calculate pin extents
    LeftDiv := XDiv - (WidthDiv div 2);
    RightDiv := XDiv + (WidthDiv div 2);
    TopDiv := YDiv - (HeightDiv div 2);
    BottomDiv := YDiv + (HeightDiv div 2);

    // convert divs to cells
    Left := (LeftDiv + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
    Right := (RightDiv + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
    Top := (TopDiv + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
    Bottom := (BottomDiv + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;

    // convert to bounding rectangle
    Inc( Right );
    Inc( Bottom );
end;


// get rectangle in div cell units, not relative to any component, but
// unrotated with origin at 0,0 . Not a bounding rectangle.
procedure TsmPin.GetDivRectangle( var Left, Top, Right, Bottom : integer );
begin
    Left := FXDiv - (WidthDiv div 2);
    Right := FxDiv + (WidthDiv div 2);
    Top := FYDiv - (HeightDiv div 2);
    Bottom := FYDiv + (HeightDiv div 2);
end;


procedure TsmPin.Paint( Item : TveBoardItem; Info : TvePainter );
var
    PinLines : TPolyLines;

    PixelsPerCell : integer;

    Rotation : TRotation;
    RotationX, RotationY : integer;

    // Div coords of reference point of this component
    ComponentXDiv, ComponentYDiv : integer;

    procedure Rectangle( Rect : TRect );
    begin
        Rotate( Rect.Left, Rect.Top, RotationX, RotationY, Rotation );
        Rotate( Rect.Right, Rect.Bottom, RotationX, RotationY, Rotation );

        // convert Div coords to pixels
        Rect.Left := ((Rect.Left + (DIVS_PER_CELL div 2)) * PixelsPerCell) div DIVS_PER_CELL;
        Rect.Right := ((Rect.Right + (DIVS_PER_CELL div 2)) * PixelsPerCell) div DIVS_PER_CELL;
        Rect.Top := ((Rect.Top + (DIVS_PER_CELL div 2)) * PixelsPerCell) div DIVS_PER_CELL;
        Rect.Bottom := ((Rect.Bottom + (DIVS_PER_CELL div 2)) * PixelsPerCell) div DIVS_PER_CELL;

        // plot rectangle
        PinLines.AddPoint( Rect.Left, Rect.Top );
        PinLines.AddPoint( Rect.Right, Rect.Top );
        PinLines.AddPoint( Rect.Right, Rect.Bottom );
        PinLines.AddPoint( Rect.Left, Rect.Bottom );
        PinLines.AddPoint( Rect.Left, Rect.Top );
        PinLines.EndShape;
    end;

var
    PinXDiv, PinYDiv : integer;
    PinRect : TRect;

begin
    PinLines := Info.PinLines;

    PixelsPerCell := Info.PixelsPerCell;
    Rotation := Item.Rotation;


    //locate reference point of outline in Divs
    //*** this value will become high precision later on
//    ComponentXDiv := Item.X * TsmDivisionsPerCell; //+ (TsmDivisionsPerCell div 2);
//    ComponentYDiv := Item.Y * TsmDivisionsPerCell; //+ (TsmDivisionsPerCell div 2);

    ComponentXDiv := Item.XDiv;
    ComponentYDiv := Item.YDiv;

    // rotate about this point
    RotationX := ComponentXDiv;
    RotationY := ComponentYDiv;

    // calculate pin position in Divs
    PinXDiv := Item.XDiv + XDiv;
    PinYDiv := Item.YDiv + YDiv;

    // draw pin as rectangle
    PinRect.Left := PinXDiv - (WidthDiv div 2);
    PinRect.Right := PinXDiv + (WidthDiv div 2);
    PinRect.Top := PinYDiv - (HeightDiv div 2);
    PinRect.Bottom := PinYDiv + (HeightDiv div 2);
    Rectangle( PinRect );
end;

function TsmPin.DistanceToPoint( Item : TveBoardItem; PointX, PointY : integer ) : integer;
var
    PinSX, PinSY : integer;
    SideX, SideY : integer;
begin
     // (we work in SubCell units in this function)
     PinSX := XDiv;
     PinSY := YDiv;

     // rotate pin position around the item reference point
     Rotate( PinSX, PinSY, 0, 0, Item.Rotation );

     // add in component position
     PinSX := PinSX + (Item.X  * DIVS_PER_CELL);
     PinSY := PinSY + (Item.Y  * DIVS_PER_CELL);

    // find distance to pin centre in SubCell units
    SideX := PointX - PinSX;
    SideY := PointY - PinSY;
    result := round( sqrt((SideX * SideX) + (SideY * SideY)) );

    // treating pin as a circle, subtract its radius to give distance from point
    // to circle
    Dec( result, DIVS_PER_CELL div 3 );
end;


function TsmPin.Clone : TsmShape;
begin
    result := TsmPin.Create;
    result.XDiv := FXDiv;
    result.YDiv := FYDiv;
    TsmPin(result).WidthDiv := WidthDiv;
    TsmPin(result).HeightDiv := HeightDiv;
    TsmPin(result).Name := Name;
end;

function TsmPin.Identical( Shape : TsmShape ) : boolean;
begin
    result :=
        (Shape is TsmPin) and
        (TsmPin(Shape).XDiv = FXDiv) and
        (TsmPin(Shape).YDiv = FYDiv) and
        (TsmPin(Shape).WidthDiv = WidthDiv) and
        (TsmPin(Shape).HeightDiv = HeightDiv) and
        (TsmPin(Shape).Name = Name);
end;

// **************************************************
//               TveCustomOutline
// **************************************************

constructor TveSmdOutline.Create;
begin
    inherited;
    FShapes := TObjectList.Create;
    FRotatable := True;
    FUserDefined := True;
    FShowsDesignator := True;
    FShowsValue := True;    
end;

destructor TveSmdOutline.Destroy;
begin
    FShapes.Free;
    inherited;
end;

function TveSmdOutline.GetShape( index : integer ) : TsmShape;
begin
    result := TsmShape( FShapes[index] );
end;

function TveSmdOutline.GetShapeCount : integer;
begin
    result := FShapes.Count;
end;

function TveSmdOutline.CreateLine : TsmLine;
begin
    result := TsmLine.Create;
    FShapes.Add( result );
    BuildPinList;
end;

function TveSmdOutline.CreatePin : TsmPin;
begin
    result := TsmPin.Create;
    FShapes.Add( result );
    BuildPinList;
end;

procedure TveSmdOutline.AddShape( Shape : TsmShape );
begin
    FShapes.Add( Shape );
    BuildPinList;
end;

procedure TveSmdOutline.DeleteShape( Shape : TsmShape );
begin
    if FShapes.Remove( Shape ) = -1 then begin
        raise EOutlineStream.Create( 'Deleting non-existant shape' );
    end;
    BuildPinList;
end;

function TveSmdOutline.Clone : TveOutline;
var
    i : integer;
begin
    result := TveSmdOutline.Create;

    // duplicate data
    TveSmdOutline(result).Name := Name;

    // duplicate shapes
    for i := 0 to FShapes.Count -1 do begin
        TveSmdOutline(result).AddShape( TsmShape(FShapes[i]).Clone );
    end;

    TveSmdOutline(result).BuildPinList;
end;

function TveSmdOutline.Identical( Outline : TveOutline ) : boolean;
var
    i : integer;
begin
    // assume different
    result := False;

    if not (
        (Outline is TveSmdOutline) and
        (TveSmdOutline(Outline).PinCount = PinCount) and
        (TveSmdOutline(Outline).ShapeCount = ShapeCount)
        ) then begin
          exit
    end;

    // compare the pins arrays
    for i := 0 to PinCount - 1 do begin
        if TveSmdOutline(Outline).Pins[i].Name <> Pins[i].Name then begin
            exit;
        end;
    end;

    // compare shapes
    for i := 0 to ShapeCount - 1 do begin
        if not Shapes[i].Identical( TveSmdOutline(Outline).Shapes[i] ) then begin
            exit;
        end;
    end;

    // passed all tests
    result := True;
end;

procedure TveSmdOutline.Paint( Item : TveBoardItem; Info : TvePainter );

var
    PixelsPerCell : integer;
    Rotation : TRotation;
    RotationX, RotationY : integer;

var
    i : integer;
    Shape : TsmShape;

    // pixel coords of reference point of this component
    ComponentX, ComponentY : integer;

    // component text
    DesignatorX, DesignatorY : integer;

begin
    // setup local variables
    PixelsPerCell := Info.PixelsPerCell;
    Rotation := Item.Rotation;

    //locate TCanvas pixels containing top left of outline (+1 pixel for border
    ComponentX := (Item.X * PixelsPerCell) + Info.Border;
    ComponentY := (Item.Y * PixelsPerCell) + Info.Border;

    // find centre of reference pin : ie perfboard hole at top left
    RotationX := ComponentX + (PixelsPerCell div 2);
    RotationY := ComponentY + (PixelsPerCell div 2);

    // draw every shape in list
    for i := 0 to FShapes.Count -1 do begin
        Shape := TsmShape(FShapes[i]);
        Shape.Paint( Item, Info );
    end;

    // print designator
    if not Item.TextVisible then begin
        exit;
    end;

    DesignatorX :=
        (Item.TextX * PixelsPerCell) + ComponentX + (PixelsPerCell div 2);
    DesignatorY :=
        (Item.TextY * PixelsPerCell) + ComponentY  + (PixelsPerCell div 2);;

    // text position is rotated along with the rest of the component
    // around the item (0.0) reference point
    Rotate( DesignatorX, DesignatorY,
            RotationX, RotationY,
            Rotation   );

    // text orientation is never changed by item rotation
    case Info.TextDisplay of

        tdDesignator :
            Info.SmallText.Add(
                Item.Designator, DesignatorX, DesignatorY, Item.TextRotation );
        tdValue :
            Info.SmallText.Add(
                Item.Value, DesignatorX, DesignatorY, Item.TextRotation );
    end;

end;

function TveSmdOutline.OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
    : boolean;
var
    ItemRect : TRect;
begin
    // rough : see if cell is inside screen rectangle.
    // We should actually trace the outer outline of our component - quite a
    // complicated task
    GetScreenRectR( Item, ItemRect );
    result :=
        (CellX >= ItemRect.Left) and (CellX < ItemRect.Right) and
        (CellY >= ItemRect.Top) and (CellY < ItemRect.Bottom);
end;

{
function TveCustomOutline.InsideRectangle( Item : TveBoardItem;
    CellX1, CellY1, CellX2, CellY2 : integer ) : boolean;
var
    ItemRect : TRect;
begin
    // find rectangle occupied by our outline
    GetScreenRectR( Item, ItemRect );

    // see if our location is inside rectangle
    result :=
        (ItemRect.Left >= CellX1) and (ItemRect.Right <= CellX2) and
        (ItemRect.Top >= CellY1) and (ItemRect.Bottom <= CellY2);
end;
}

procedure TveSmdOutline.RotateAboutCenter( Item : TveBoardItem );
var
    ItemRect : TRect;
    Width, Height : integer;
    Angle : TRotation;
begin
    // find cells we occupy on screen
    GetScreenRectR( Item, ItemRect );

    // calc twice width and height
    Width := ItemRect.Right - ItemRect.Left;
    Height := ItemRect.Bottom - ItemRect.Top;

    // Calculate new location point for outline.
    // Adjust position of outline origin so that top left of Item
    // width x height rectangle is always at same square.
    case Item.Rotation of

        rot0 : begin
            Item.Y := Item.Y + Width - 1;
        end;
        rot90 : begin
            Item.X := Item.X + Height - 1;
            Item.Y := Item.Y + Width - Height;
        end;
        rot180 : begin
            Item.X := Item.X - Width + Height;
            Item.Y := Item.Y - Height + 1;
        end;
        rot270 : begin
            Item.X := Item.X - Width + 1;
        end
    end;

    // calculate new rotation for Item
    Angle := Item.Rotation;
    Item.Rotation := TRotation( (Ord(Angle) + 1) mod 4 );
end;

function TveSmdOutline.PinIndexAt( Item : TveBoardItem; CellX, CellY : integer )
    : integer;
begin
    // hide all pins
    result := -1;
end;
(*
var
    CompX, CompY : integer;
    i : integer;
    Shape : TsmShape;
begin
    // convert screen cell coords to outline cell coords
    CompX := CellX - Item.X;
    CompY := CellY - Item.Y;

    // rotate cell coords to follow outline rotation
    RotateReverse( CompX, CompY, 0, 0, Item.Rotation );

    // see if our location hits a cell used by our outline
    //.. Set result ready for first Pin Index. (Pins[] are in same index order
    //.. as pins in Shapes[], so we work thru shapes to find our pin, tracking
    //.. the index in result as we go.
    result := 0;
    for i := 0 to FShapes.Count -1 do begin
        Shape := TsmShape( FShapes[i] );
        if (Shape is TsmPin) then begin

            if  ((Shape.XDiv div DIVS_PER_CELL) = CompX) and
                ((Shape.YDiv div DIVS_PER_CELL) = CompY)
                then begin
                // result holds the correct pin index, so exit
                exit;
            end;
            // index of next pin in Pins[]
            inc( result );
        end;
    end;

    // return -1 if no pin found in Shapes[]
    result := -1;
end;
*)

procedure TveSmdOutline.GetScreenRectR( Item : TveBoardItem; var R : TRect );
var
    Left, Top, Right, Bottom : integer;
    i : integer;
    Shape : TsmShape;
    ShapeLeft, ShapeTop, ShapeRight, ShapeBottom : integer;
begin

    // create rectangle which includes all div extents in this outline
    // this is not a bounding rectangle, ie. Right, Bottom cells rows include
    // drawn things like lines, circles, pins - whereas a bounding rectangle has
    // Right, Bottom as incremented by 1 so as to *enclose*

    // create a  rectangle which includes all cells in this outline
    // start with a rectangle extents which must trigger changes if any shape exists
    Left := High(Left);
    Top := High(Top);
    Right := Low(Right);
    Bottom := Low(Bottom);

    for i := 0 to FShapes.Count -1 do begin
        Shape := TsmShape( FShapes[i] );
        Shape.GetDivRectangle( ShapeLeft, ShapeTop, ShapeRight, ShapeBottom );
        if ShapeLeft < Left then begin
            Left := ShapeLeft;
        end;
        if ShapeRight > Right then begin
            Right := ShapeRight;
        end;
        if ShapeTop < Top then begin
            Top := ShapeTop;
        end;
        if ShapeBottom > Bottom then begin
            Bottom := ShapeBottom;
        end;
    end;

    // if the outline is empty, invent a bounding rectangle of zero area
    if (Left = High(Left)) or (Top = High(Top)) or
        (Right = Low(Right)) or (Bottom = Low(Bottom)) then begin
        Left := 0;
        Right := 0;
        Top := 0;
        Bottom := 0;
    end;

    // rotate the item around its reference point
    Rotate( Left, Top, 0, 0, Item.Rotation );
    Rotate( Right, Bottom, 0, 0, Item.Rotation );

    // we now have offsets from the item reference point, so we add in the
    // reference point screen coords to get item rect in screen coords.
    Inc( Left, Item.XDiv );
    Inc( Right, Item.XDiv );
    Inc( Top, Item.YDiv );
    Inc( Bottom, Item.YDiv );

    // tranfer rectangle to result vars - converting to cells
    R.Left := (Left + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
    R.Right := (Right + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
    R.Top := (Top + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;
    R.Bottom := (Bottom + (DIVS_PER_CELL div 2)) div DIVS_PER_CELL;

    // arrange rotated coords to give left,top and right,bottom of rectangle.
    NormalizeRect( R );

    // turn into bounding rectangle
    Inc( R.Right );
    Inc( R.Bottom );
end;


function TveSmdOutline.PinIndexByName( const Name : string ) : integer;
begin
    result := inherited PinIndexByName( Name );
end;

procedure TveSmdOutline.ToFirstPin;
begin
    NextShapeIndex := 0;
    NextPinIndex := 0;
end;

function TveSmdOutline.GetNextPin(
    Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean;
var
    i : integer;
    Shape :  TsmShape;
    Found : boolean;
begin
    // prevent uninitialised variable warning
    Shape := nil;

    // search for next pin
    Found := False;
    for i := NextPinIndex to FShapes.Count -1 do begin
        Shape := TsmShape( FShapes[i] );
        if Shape is TsmPin then begin

            PinIndex := NextPinIndex;
            Found := True;

            // ready for continued search of shapes on next function call
            NextShapeIndex := i + 1;

            // remember new pin index for next time
            Inc( NextPinIndex );

            break;
        end;
    end;

    // no more pins
    if not Found then begin
        PinIndex := FShapes.Count;
        result := False;
        exit;
    end;

    // get info from pin
    X := TsmPin(Shape).XDiv div DIVS_PER_CELL;
    Y := TsmPin(Shape).YDiv div DIVS_PER_CELL;

    // rotate X,Y for Item
    Rotate( X, Y, 0, 0, Item.Rotation );

    // add offset for item position
    Inc( X, Item.X );
    Inc( Y, Item.Y );

    result := True;
end;

function TveSmdOutline.GetNextPinDiv(
    Item : TveBoardItem; var Rect : TRect; var PinIndex : integer ) : boolean;
var
    i : integer;
    Shape :  TsmShape;
    Found : boolean;
begin
    // prevent uninitialised variable warning
    Shape := nil;

    // search for next pin
    Found := False;
    for i := NextPinIndex to FShapes.Count -1 do begin
        Shape := TsmShape( FShapes[i] );
        if Shape is TsmPin then begin

            PinIndex := NextPinIndex;
            Found := True;

            // ready for continued search of shapes on next function call
            NextShapeIndex := i + 1;

            // remember new pin index for next time
            Inc( NextPinIndex );

            break;
        end;
    end;

    // no more pins
    if not Found then begin
        PinIndex := FShapes.Count;
        result := False;
        exit;
    end;

    // get pin rectangle in div cell units, not relative to any component, but
    // unrotated with origin at 0,0 . Not a bounding rectangle.
    TsmPin(Shape).GetDivRectangle( Rect.Left, Rect.Top, Rect.Right, Rect.Bottom );

    // rotate the rectangle around the component reference point
    RotateRect( Rect, Point(0, 0), Item.Rotation );
{
    // get pin rectangle in div cell units, not relative to any component, but
    // unrotated with origin at 0,0 . Not a bounding rectangle.
    TsmPin(Shape).GetDivRectangle( Left, Top, Right, Bottom );

    // rotate the rectangle around the component reference point
    Rotate( Left, Top, 0, 0, Item.Rotation );
    Rotate( Right, Bottom, 0, 0, Item.Rotation );

    // we will return a pin Rect
    Rect.Left := Left;
    Rect.Top := Top;
    Rect.Right := Right;
    Rect.Bottom := Bottom;

    // get top, left & bottom right in correct order
    NormalizeRect( Rect );
}
    // add offset for item position
    Inc( Rect.Left, Item.XDiv );
    Inc( Rect.Right, Item.XDiv );
    Inc( Rect.Top, Item.YDiv );
    Inc( Rect.Bottom, Item.YDiv );

    // found a pin
    result := True;
end;


// ********** Outline Creates an Array of TvePins  ***********
{
    Pins[] - the lists of TvePin objects is required to make the
    TveCustomOutline compatible with other TveOutline descendants.
    However, it is not required for the TveCustomOutline to operate
    internally.

    We inherite from TveOutline the FPins member, a TObjectList.  We
    fill the object list with our TvePin objects which match
    the pins held in the Shapes array.
}

procedure TveSmdOutline.BuildPinList;
var
    // manage Shapes[]
    i : Integer;
    coPin : TsmPin;

    // manage Pins[]
    PinIndex : integer;
    Pin : TvePin;
begin
    PinIndex := 0;

    // for every TcoShape in Shapes[]
    for i := 0 to FShapes.Count - 1 do begin

        // if this TcoShape is a TcoPin
        if Shapes[i] is TsmPin then begin

            coPin := TsmPin( Shapes[i] );

            // if we need a new TvePin in the list
            if PinIndex = PinCount then begin
                Pin := TvePin.Create;
                FPins.Add( Pin );
            end

            // else we can reuse an existing TvePin
            else begin
                Pin := Pins[PinIndex];
            end;

            // make the TvePin reflect the data in the TcoPin
            Pin.Name := coPin.Name;

            // housekeeping - remember index of next pin
            // to use in this loop
            inc( PinIndex );
        end;
    end;

    // remove any unused items in Pins[]
    for i := PinCount -1 downto PinIndex do begin
        FPins.Delete(i);
    end;
end;


function TveSmdOutline.GetPin( index : integer ) : TvePin;
begin
    result := TvePin( FPins[index] );
end;


// ********** Outline writes its properties to a stream ***********
{
TO-220,1
Pin,1,2,2
Pin,2,2,7
Pin,3,2,12
Line,0,0,7,0
Line,7,0,0,14
Line,7,14,-7,0
Line,0,14,0,-14
Line,5,0,0,14
end
}

procedure TveSmdOutline.WriteToStream( S : TStream );

    procedure LineOut( const text : string );
    begin
        LineToStream( S, text );
    end;

var
    i : integer;
    Shape : TsmShape;
begin
    LineOut( Format( 'Outline=%s', [ClassName] ) );
    LineOut( Format('Name=%s', [Name]) );

    // susequent lines are shape data eg. "Line=3,2,4,8"

    // output shapes - one shape per line:
    for i := 0 to FShapes.Count -1 do begin
        Shape := TsmShape(FShapes[i]);

        if Shape is TsmLine then begin
            LineOut( Format( 'Line=%d,%d,%d,%d',
                [TsmLine(Shape).XDiv, TsmLine(Shape).YDiv,
                TsmLine(Shape).EndDeltaXDiv, TsmLine(Shape).EndDeltaYDiv]
            ));
        end
        else if Shape is TsmPin then begin
            LineOut( Format( 'Pin=%d,%d,%d,%d,%s',
                [TsmPin(Shape).XDiv, TsmPin(Shape).YDiv,
                TsmPin(Shape).WidthDiv, TsmPin(Shape).HeightDiv,
                TsmPin(Shape).Name]
            ));
        end;
    end;

    LineOut( 'end' );
end;

procedure TveSmdOutline.ReadFromStream( S : TStream );
var
    AName, AValue : string;
    Shape : TsmShape;
    ScanIndex : integer;
    Field : string;
begin
    while NameValueFromStream( S, AName, AValue ) do begin

        if AName = 'Name' then begin
            FName := AValue;
        end
        else if AName = 'Line' then begin

            Shape := TsmLine.Create;
            FShapes.Add( Shape );

            // x, y, EndDeltaX, EndDeltaY
            ScanIndex := 0;

            ParseCSVValue( AValue, Field, ScanIndex );
            Shape.FXDiv := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            Shape.FYDiv := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            TsmLine(Shape).FEndDeltaXDiv := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            TsmLine(Shape).FEndDeltaYDiv := StrToIntDef( Field, 1 );
        end
        else if AName = 'Pin' then begin

            Shape := TsmPin.Create;
            FShapes.Add( Shape );

            // x, y, number
            ScanIndex := 0;

            ParseCSVValue( AValue, Field, ScanIndex );
            Shape.FXDiv := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            Shape.FYDiv := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            TsmPin(Shape).WidthDiv := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            TsmPin(Shape).HeightDiv := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            TsmPin(Shape).Name := Field;
        end
        else if AName = 'end' then begin
            Break;
        end;
    end;

    BuildPinList;
end;


end.
