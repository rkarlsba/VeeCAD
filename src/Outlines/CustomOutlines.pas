unit CustomOutlines;

interface

uses Outlines, Painter, Contnrs, Classes, Types, UndoEngine;

// Board Cells are divided into MiniCells - shapes are located by MiniCell
// coords, while pins are located by ordinary Cell coords.

// Number of MiniCells per Cell
const TcoSubCellsPerCell = 5;

type TveCustomOutline = class;

// *** BASE CLASS FOR ALL SHAPE MEMENTOS ***
TcoMemento = class( TunMemento )
end;

TcoShape = class
  protected
    FSubX : integer;
    FSubY : integer;
    FSelected : boolean;
    procedure SetSubX( value : integer ); virtual;
    procedure SetSubY( value : integer ); virtual;
  public
    property SubX : integer read FSubX write SetSubX;
    property SubY : integer read FSubY write SetSubY;
    property Selected : boolean read FSelected write FSelected;
    // bounding rectangle which contains item
    procedure GetRectangle( var Left, Top, Right, Bottom : integer ); virtual; abstract;
    procedure GetSubRectangle( var Left, Top, Right, Bottom : integer ); virtual; abstract;
    procedure Paint( Item : TveBoardItem; Info : TvePainter ); virtual; abstract;
    function DistanceToPoint( Item : TveBoardItem; PointX, PointY : single ) : single; virtual; abstract;
    function Clone : TcoShape; virtual; abstract;
    function Identical( Shape : TcoShape ) : boolean; virtual; abstract;
    // undo-redo
    function ChangedSinceSnapshot : boolean; virtual; abstract;
    procedure TakeSnapshot; virtual; abstract;
    function CreateMementoFromSnapshot : TcoMemento; virtual; abstract;
end;

TcoLine = class( TcoShape )
    FEndDeltaSubX : integer;
    FEndDeltaSubY : integer;

    SnapshotSubX : integer;
    SnapshotSubY : integer;
    SnapshotEndDeltaSubX : integer;
    SnapshotEndDeltaSubY : integer;

    procedure SetEndDeltaSubX( value : integer );
    procedure SetEndDeltaSubY( value : integer );
  public
    property EndDeltaSubX : integer read FEndDeltaSubX write SetEndDeltaSubX;
    property EndDeltaSubY : integer read FEndDeltaSubY write SetEndDeltaSubY;
    procedure GetRectangle( var Left, Top, Right, Bottom : integer ); override;
    procedure GetSubRectangle( var Left, Top, Right, Bottom : integer ); override;
    procedure Paint( Item : TveBoardItem; Info : TvePainter ); override;
    function DistanceToPoint( Item : TveBoardItem; PointX, PointY : single ) : single; override;
    function StartIsNearestPoint( Item : TveBoardItem; PointX, PointY : integer ) : boolean;
    function Clone : TcoShape; override;
    function Identical( Shape : TcoShape ) : boolean; override;
    // undo-redo
    function ChangedSinceSnapshot : boolean; override;
    procedure TakeSnapshot; override;
    function CreateMementoFromSnapshot : TcoMemento; override;
end;

TcoLineMemento = class (TcoMemento)
  protected
    Line : TcoLine;
    DeltaSubX : integer;
    DeltaSubY : integer;
    EndDeltaSubX : integer;
    EndDeltaSubY : integer;
public
    Procedure Undo; override;
    Procedure Redo; override;
    Procedure DiscardUndo; override;
    Procedure DiscardRedo; override;
end;

TcoPin = class( TcoShape )
  protected
    SnapshotSubX : integer;
    SnapshotSubY : integer;

    procedure SetSubX( value : integer ); override;
    procedure SetSubY( value : integer ); override;
  public
    Name : string;
    procedure GetRectangle( var Left, Top, Right, Bottom : integer ); override;
    procedure GetSubRectangle( var Left, Top, Right, Bottom : integer ); override;
    procedure Paint( Item : TveBoardItem; Info : TvePainter ); override;
    function DistanceToPoint( Item : TveBoardItem; PointX, PointY : single ) : single; override;
    function Clone : TcoShape; override;
    function Identical( Shape : TcoShape ) : boolean; override;
    // undo-redo
    function ChangedSinceSnapshot : boolean; override;
    procedure TakeSnapshot; override;
    function CreateMementoFromSnapshot : TcoMemento; override;
end;

TcoPinMemento = class( TcoMemento )
protected
    Pin : TcoPin;
    DeltaSubX : integer;
    DeltaSubY : integer;
public
    Procedure Undo; override;
    Procedure Redo; override;
    Procedure DiscardUndo; override;
    Procedure DiscardRedo; override;
end;

TveCustomOutline = class( TveOutline )

  protected
    UndoEng : TunUndo;
    NextShapeIndex : integer;
    NextPinIndex : integer;
    FShapes : TObjectList;
    function GetShape( index : integer ) : TcoShape;
    function GetShapeCount : integer;
    function GetPin( index : integer ) : TvePin; override;
  public

    property Shapes[index : integer] : TcoShape read GetShape;
    property ShapeCount : integer read GetShapeCount;
    function CreateLine : TcoLine;
    function CreatePin : TcoPin;
    procedure AddShape( Shape : TcoShape );
    procedure DeleteShape( Shape : TcoShape );
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

    procedure WriteToStream( S : TStream ); override;
    procedure ReadFromStream( S : TStream ); override;

    function GetSpecifiedShapeAtSubCellXY(
        Item : TveBoardItem; SubCellX, SubCellY : single; ShapeClass : TClass ) : TcoShape;
    function GetShapeAtSubCellXY(
        Item : TveBoardItem; SubCellX, SubCellY : single ) : TcoShape;
    procedure UnselectAllShapes;
    procedure SelectAllShapes;
    function GetSelectedCount : integer;
    property SelectedCount : integer read GetSelectedCount;
    function SelectionIncludesPin : boolean;

    // UNDO-REDO
    procedure EnableUndo;
    procedure SnapshotSelectedShapes;
    procedure StoreSnapshotSelectedAsUndo;
    procedure RegisterNewShapeForUndo( Shape : TcoShape );
    procedure DeleteSelectedShapesWithUndo;
    procedure Undo;
    procedure Redo;
end;


TcoOperation = (opAdd, opRemove);

TcoCustomOutlineMemento = class( TcoMemento )
protected
    Outline : TveCustomOutline;
    Shape : TcoShape;
    Operation : TcoOperation;
public
    Procedure Undo; override;
    Procedure Redo; override;
    Procedure DiscardUndo; override;
    Procedure DiscardRedo; override;
end;



implementation

uses Rotations, SysUtils, Windows, ParseCSV, Rectangles, Intersect;

// **************************************************
//                  TcoShape
// **************************************************

procedure TcoShape.SetSubX( value : integer );
begin
    FSubX := value;
end;

procedure TcoShape.SetSubY( value : integer );
begin
    FSubY := value;
end;

// **************************************************
//                  TcoLine
// **************************************************

procedure TcoLine.SetEndDeltaSubX( value : integer );
begin
    // do not allow zero length
    if (value = 0) and (FEndDeltaSubY = 0) then begin
        FEndDeltaSubY := 1;
    end;
    FEndDeltaSubX := value;
end;

procedure TcoLine.SetEndDeltaSubY( value : integer );
begin
    // do not allow zero length
    if (value = 0) and (FEndDeltaSubX = 0) then begin
        FEndDeltaSubX := 1;
    end;
    FEndDeltaSubY := value;
end;

procedure TcoLine.GetRectangle( var Left, Top, Right, Bottom : integer );
begin
    if EndDeltaSubX > 0 then begin
        Left := SubX div TcoSubCellsPerCell;
        Right := ((SubX + EndDeltaSubX) div TcoSubCellsPerCell) + 1;
    end
    else begin
        Left :=  (SubX + EndDeltaSubX) div TcoSubCellsPerCell;
        Right := (SubX div TcoSubCellsPerCell) + 1;
    end;

    if EndDeltaSubY > 0 then begin
        Top := SubY div TcoSubCellsPerCell;
        Bottom := ((SubY + EndDeltaSubY) div TcoSubCellsPerCell) + 1;
    end
    else begin
        Top :=  (SubY + EndDeltaSubY) div TcoSubCellsPerCell;
        Bottom := (SubY div TcoSubCellsPerCell) + 1;
    end;
end;


// get rectangle in sub cell units, not relative to any component, but
// unrotated with origin at 0,0
procedure TcoLine.GetSubRectangle( var Left, Top, Right, Bottom : integer );
begin
    if EndDeltaSubX > 0 then begin
        Left := SubX;
        Right := SubX + EndDeltaSubX + 1;
    end
    else begin
        Left := SubX + EndDeltaSubX;
        Right := SubX + 1;
    end;

    if EndDeltaSubY > 0 then begin
        Top := SubY;
        Bottom := SubY + EndDeltaSubY + 1;
    end
    else begin
        Top := SubY + EndDeltaSubY;
        Bottom := SubY + 1;
    end;
end;


procedure TcoLine.Paint( Item : TveBoardItem; Info : TvePainter );
var
    BodyLines : TPolyLines;

    // Line pixel coords between start x1, y1 and end x2, y2
    X1, Y1, X2, Y2 : integer;

    PixelsPerCell : integer;

    Rotation : TRotation;
    RotationX, RotationY : integer;

    // pixel coords of reference point of this component
    ComponentX, ComponentY : integer;

    procedure Line( X1, Y1, X2, Y2 : integer );
    begin
        Rotate( X1, Y1, RotationX, RotationY, Rotation );
        Rotate( X2, Y2, RotationX, RotationY, Rotation );
        BodyLines.AddLine( X1, Y1, X2, Y2 );
    end;

begin
    BodyLines := Info.BodyLines;

    PixelsPerCell := Info.PixelsPerCell;
    Rotation := Item.Rotation;

    //locate TCanvas pixels containing top left of outline (+1 pixel for border
    ComponentX := (Item.X * PixelsPerCell) + Info.Border;
    ComponentY := (Item.Y * PixelsPerCell) + Info.Border;

    // find centre of reference pin : ie perfboard hole at top left
    RotationX := ComponentX + (PixelsPerCell div 2);
    RotationY := ComponentY + (PixelsPerCell div 2);

    // calculate line coords in pixels
    {
    X1 := ComponentX + ((SubX * PixelsPerCell) div TcoSubCellsPerCell);
    Y1 := ComponentY + ((SubY * PixelsPerCell) div TcoSubCellsPerCell);
    X2 := ComponentX + (((SubX + EndDeltaSubX) * PixelsPerCell) div TcoSubCellsPerCell);
    Y2 := ComponentY + (((SubY + EndDeltaSubY) * PixelsPerCell) div TcoSubCellsPerCell);
    }

    // as above calcs, but add 1/2 a sub cell to line coords, so line runs down
    // center of its cell
    X1 := ComponentX + (((SubX * PixelsPerCell * 2) + PixelsPerCell) div (TcoSubCellsPerCell *2));
    Y1 := ComponentY + (((SubY * PixelsPerCell * 2) + PixelsPerCell) div (TcoSubCellsPerCell *2));
    X2 := ComponentX + ((((SubX + EndDeltaSubX) * PixelsPerCell * 2) + PixelsPerCell) div (TcoSubCellsPerCell *2));
    Y2 := ComponentY + ((((SubY + EndDeltaSubY) * PixelsPerCell * 2) + PixelsPerCell) div (TcoSubCellsPerCell *2));

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

{
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
}

function TcoLine.DistanceToPoint( Item : TveBoardItem; PointX, PointY : single ) : single;
var
    PX, PY : single;
    EndA, EndB, PointC : TFloatPoint;
begin
    // make point coords relative to component reference point, sub cell units
    PX := PointX - (Item.X * TcoSubCellsPerCell);
    PY := PointY - (Item.Y * TcoSubCellsPerCell);

    // reverse rotate point about component reference point
    RotateReverse( PX, PY, 0, 0, Item.Rotation );

    // calculate distance between line and point
    EndA.x := SubX;
    EndA.y := SubY;
    EndB.x := SubX + EndDeltaSubX;
    EndB.y := SubY + EndDeltaSubY;
    PointC.x := PX;
    PointC.y := PY;

    result := LinePointDist( EndA, EndB, PointC );
end;

function TcoLine.StartIsNearestPoint( Item : TveBoardItem; PointX, PointY : integer ) : boolean;
var
    XDist, YDist : integer;

    // work in distance^2 to save square roots
    StartDistance2 : integer;
    EndDistance2 : integer;
begin
    // distance to start
    XDist := PointX - FSubX;
    YDist := PointY - FSubY;
    StartDistance2 := (XDist * XDist) + (YDist * YDist);

    // distance to end
    XDist := PointX - (FSubX + EndDeltaSubX);
    YDist := PointY - (FSubY + EndDeltaSubY);
    EndDistance2 := (XDist * XDist) + (YDist * YDist);

    // which distance is shorter?
    result := StartDistance2 < EndDistance2;
end;


function TcoLine.Clone : TcoShape;
begin
    result := TcoLine.Create;
    result.SubX := FSubX;
    result.SubY := FSubY;
    TcoLine( result ).EndDeltaSubX := FEndDeltaSubX;
    TcoLine( result ).EndDeltaSubY := FEndDeltaSubY;
end;

function TcoLine.Identical( Shape : TcoShape ) : boolean;
begin
    result :=
        (Shape is TcoLine) and
        (TcoLine(Shape).SubX = FSubX) and
        (TcoLine(Shape).SubY = FSubY) and
        (TcoLine(Shape).EndDeltaSubX = FEndDeltaSubX) and
        (TcoLine(Shape).EndDeltaSubY = FEndDeltaSubY);
end;

// undo-redo
function TcoLine.ChangedSinceSnapshot : boolean;
begin
  result :=
    (SnapshotSubX <> FSubX) or
    (SnapshotSubY <> FSubY) or
    (SnapshotEndDeltaSubX <> FEndDeltaSubX) or
    (SnapshotEndDeltaSubY <> FEndDeltaSubY);
end;

procedure TcoLine.TakeSnapshot;
begin
    SnapshotSubX := FSubX;
    SnapshotSubY := FSubY;
    SnapshotEndDeltaSubX := FEndDeltaSubX;
    SnapshotEndDeltaSubY := FEndDeltaSubY;
end;

function TcoLine.CreateMementoFromSnapshot : TcoMemento;
begin
    result := TcoLineMemento.Create;
    TcoLineMemento(result).Line := self;
    TcoLineMemento(result).DeltaSubX := FSubX - SnapshotSubX;
    TcoLineMemento(result).DeltaSubY := FSubY - SnapshotSubY;
    TcoLineMemento(result).EndDeltaSubX := FEndDeltaSubX - SnapshotEndDeltaSubX;
    TcoLineMemento(result).EndDeltaSubY := FEndDeltaSubY - SnapshotEndDeltaSubY;
end;


// **************************************************
//                  TcoLineMemento
// **************************************************

procedure TcoLineMemento.Undo;
begin
    Line.FSubX := Line.FSubX - DeltaSubX;
    Line.FSubY := Line.FSubY - DeltaSubY;
    Line.FEndDeltaSubX := Line.FEndDeltaSubX - EndDeltaSubX;
    Line.FEndDeltaSubY := Line.FEndDeltaSubY - EndDeltaSubY;
end;

procedure TcoLineMemento.Redo;
begin
    Line.FSubX := Line.FSubX + DeltaSubX;
    Line.FSubY := Line.FSubY + DeltaSubY;
    Line.FEndDeltaSubX := Line.FEndDeltaSubX + EndDeltaSubX;
    Line.FEndDeltaSubY := Line.FEndDeltaSubY + EndDeltaSubY;
end;

procedure TcoLineMemento.DiscardUndo;
begin
    // this memento is no longer needed. Since it only describes a property
    // change, it has no responsibilities to any object. We delete it.
    Free;
end;

procedure TcoLineMemento.DiscardRedo;
begin
    // this memento is no longer needed. Since it only describes a property
    // change, it has no responsibilities to any object. We delete it.
    Free;
end;

// **************************************************
//                  TcoPin
// **************************************************

procedure TcoPin.SetSubX( value : integer );
begin
    // place the pin at mid-cell
    FSubX := ((value div TcoSubCellsPerCell) * TcoSubCellsPerCell) + (TcoSubCellsPerCell div 2);
end;

procedure TcoPin.SetSubY( value : integer );
begin
    // place the pin at mid-cell
    FSubY := ((value div TcoSubCellsPerCell) * TcoSubCellsPerCell) + (TcoSubCellsPerCell div 2);
end;

procedure TcoPin.GetRectangle( var Left, Top, Right, Bottom : integer );
begin
    Left := SubX div TcoSubCellsPerCell;
    Right := Left + 1;
    Top := SubY div TcoSubCellsPerCell;
    Bottom := Top + 1;
end;


// get rectangle in sub cell units, not relative to any component, but
// unrotated with origin at 0,0
procedure TcoPin.GetSubRectangle( var Left, Top, Right, Bottom : integer );
begin
    // pin occupies one cell - convert that to bunding rectangle in SubCell units 
    Left := (FSubX div TcoSubCellsPerCell) * TcoSubCellsPerCell;
    Right := Left + TcoSubCellsPerCell;
    Top := (FSubY div TcoSubCellsPerCell) * TcoSubCellsPerCell;
    Bottom := Top + TcoSubCellsPerCell;
end;


procedure TcoPin.Paint( Item : TveBoardItem; Info : TvePainter );
var
    PinLines : TPolyLines;

    PixelsPerCell : integer;

    Rotation : TRotation;
    RotationX, RotationY : integer;

    // pixel coords of reference point of this component
    ComponentX, ComponentY : integer;      

    procedure Triangle( X1, Y1, X2, Y2, X3, Y3 : integer );
    begin
        Rotate( X1, Y1, RotationX, RotationY, Rotation );
        Rotate( X2, Y2, RotationX, RotationY, Rotation );
        Rotate( X3, Y3, RotationX, RotationY, Rotation );
        PinLines.AddPoint( X1, Y1 );
        PinLines.AddPoint( X2, Y2 );
        PinLines.AddPoint( X3, Y3 );
        PinLines.AddPoint( X1, Y1 );
        PinLines.EndShape;
    end;

var
    // 3 corners of a pin
    PinX, PinY : integer;
    PinX0, PinY0 : integer;
    PinX1 {, PinY1} : integer;
    PinX2, PinY2 : integer;

begin
    PinLines := Info.PinLines;

    PixelsPerCell := Info.PixelsPerCell;
    Rotation := Item.Rotation;

    //locate TCanvas pixels containing reference point of outline (+1 pixel for border
    ComponentX := (Item.X * PixelsPerCell) + Info.Border;
    ComponentY := (Item.Y * PixelsPerCell) + Info.Border;

    // find centre of reference pin : ie perfboard hole at top left
    RotationX := ComponentX + (PixelsPerCell div 2);
    RotationY := ComponentY + (PixelsPerCell div 2);

    // draw pin as triangle
    // ******
    //  *  *
    //   *
    // calculate pin position precisely - using PixelsPerCell
    PinX := ComponentX + ((SubX div TcoSubCellsPerCell) * PixelsPerCell);
    PinY := ComponentY + ((SubY div TcoSubCellsPerCell) * PixelsPerCell);

    PinX0 := PinX + (PixelsPerCell div 3);
    PinY0 := PinY + (PixelsPerCell div 3);
    PinX1 := PinX0 + (PixelsPerCell div 3);
    PinX2 := PinX + (PixelsPerCell div 2);
    PinY2 := PinY0 + (PixelsPerCell div 3);
    Triangle( PinX0, PinY0, PinX1, PinY0, PinX2, PinY2 );

end;

function TcoPin.DistanceToPoint( Item : TveBoardItem; PointX, PointY : single ) : single;
var
    PinSX, PinSY : integer;
    SideX, SideY : single;
begin
     // (we work in SubCell units in this function)
     PinSX := SubX;
     PinSY := SubY;

     // rotate pin position around the item reference point
     Rotate( PinSX, PinSY, 0, 0, Item.Rotation );

     // add in component position
     PinSX := PinSX + (Item.X  * TcoSubCellsPerCell);
     PinSY := PinSY + (Item.Y  * TcoSubCellsPerCell);

    // find distance to pin centre in SubCell units
    SideX := PointX - PinSX;
    SideY := PointY - PinSY;
    result := sqrt((SideX * SideX) + (SideY * SideY));
    
    // treating pin as a circle, subtract its radius to give distance from point
    // to circle
    result := result - (TcoSubCellsPerCell div 3);
end;


function TcoPin.Clone : TcoShape;
begin
    result := TcoPin.Create;
    result.SubX := FSubX;
    result.SubY := FSubY;
    TcoPin(result).Name := Name;
end;

function TcoPin.Identical( Shape : TcoShape ) : boolean;
begin
    result :=
        (Shape is TcoPin) and
        (TcoPin(Shape).SubX = FSubX) and
        (TcoPin(Shape).SubY = FSubY) and
        (TcoPin(Shape).Name = Name);
end;

// undo-redo
function TcoPin.ChangedSinceSnapshot : boolean;
begin
    result := (SnapshotSubX <> FSubX) or (SnapshotSubY <> FSubY);
end;
procedure TcoPin.TakeSnapshot;
begin
    SnapshotSubX := FSubX;
    SnapshotSubY := FSubY;
end;
function TcoPin.CreateMementoFromSnapshot : TcoMemento;
begin
    result := TcoPinMemento.Create;
    TcoPinMemento(result).Pin := self;
    // record deltas
    TcoPinMemento(result).DeltaSubX := FSubX - SnapshotSubX;
    TcoPinMemento(result).DeltaSubY := FSubY - SnapshotSubY;
end;

// **************************************************
//               TcoPinMemento
// **************************************************

procedure TcoPinMemento.Undo;
begin
    Pin.FSubX := Pin.FSubX - DeltaSubX;
    Pin.FSubY := Pin.FSubY - DeltaSubY;
end;

procedure TcoPinMemento.Redo;
begin
    Pin.FSubX := Pin.FSubX + DeltaSubX;
    Pin.FSubY := Pin.FSubY + DeltaSubY;
end;

procedure TcoPinMemento.DiscardUndo;
begin
    // this memento is no longer needed. Since it only describes a property
    // change, it has no responsibilities to any object. We delete it.
    Free;
end;

procedure TcoPinMemento.DiscardRedo;
begin
    // this memento is no longer needed. Since it only describes a property
    // change, it has no responsibilities to any object. We delete it.
    Free;
end;

// **************************************************
//               TveCustomOutline
// **************************************************

constructor TveCustomOutline.Create;
begin
    inherited;
    FShapes := TObjectList.Create;
    FRotatable := True;
    FUserDefined := True;
    FShowsDesignator := True;
    FShowsValue := True;    
end;

destructor TveCustomOutline.Destroy;
begin
    FShapes.Free;
    UndoEng.Free;
    inherited;
end;

function TveCustomOutline.GetShape( index : integer ) : TcoShape;
begin
    result := TcoShape( FShapes[index] );
end;

function TveCustomOutline.GetShapeCount : integer;
begin
    result := FShapes.Count;
end;

function TveCustomOutline.CreateLine : TcoLine;
begin
    result := TcoLine.Create;
    FShapes.Add( result );
    BuildPinList;
end;

function TveCustomOutline.CreatePin : TcoPin;
begin
    result := TcoPin.Create;
    FShapes.Add( result );
    BuildPinList;
end;

procedure TveCustomOutline.AddShape( Shape : TcoShape );
begin
    FShapes.Add( Shape );
    BuildPinList;
end;

procedure TveCustomOutline.DeleteShape( Shape : TcoShape );
begin
    if FShapes.Remove( Shape ) = -1 then begin
        raise EOutlineStream.Create( 'Deleting non-existant shape' );
    end;
    BuildPinList;
end;

function TveCustomOutline.Clone : TveOutline;
var
    i : integer;
begin
    result := TveCustomOutline.Create;

    // duplicate data
    TveCustomOutline(result).Name := Name;

    // duplicate shapes
    for i := 0 to FShapes.Count -1 do begin
        TveCustomOutline(result).AddShape( TcoShape(FShapes[i]).Clone );
    end;

    TveCustomOutline(result).BuildPinList;
end;

function TveCustomOutline.Identical( Outline : TveOutline ) : boolean;
var
    i : integer;
begin
    // assume different
    result := False;

    if not (
        (Outline is TveCustomOutline) and
        (TveCustomOutline(Outline).PinCount = PinCount) and
        (TveCustomOutline(Outline).ShapeCount = ShapeCount)
        ) then begin
          exit
    end;

    // compare the pins arrays
    for i := 0 to PinCount - 1 do begin
        if TveCustomOutline(Outline).Pins[i].Name <> Pins[i].Name then begin
            exit;
        end;
    end;

    // compare shapes
    for i := 0 to ShapeCount - 1 do begin
        if not Shapes[i].Identical( TveCustomOutline(Outline).Shapes[i] ) then begin
            exit;
        end;
    end;

    // passed all tests
    result := True;
end;

procedure TveCustomOutline.Paint( Item : TveBoardItem; Info : TvePainter );

var
    PixelsPerCell : integer;
    Rotation : TRotation;
    RotationX, RotationY : integer;

var
    i : integer;
    Shape : TcoShape;

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
        Shape := TcoShape(FShapes[i]);
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

function TveCustomOutline.OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
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

procedure TveCustomOutline.RotateAboutCenter( Item : TveBoardItem );
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

function TveCustomOutline.PinIndexAt( Item : TveBoardItem; CellX, CellY : integer )
    : integer;
var
    CompX, CompY : integer;
    i : integer;
    Shape : TcoShape;
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
        Shape := TcoShape( FShapes[i] );
        if (Shape is TcoPin) then begin

            if  ((Shape.SubX div TcoSubCellsPerCell) = CompX) and
                ((Shape.SubY div TcoSubCellsPerCell) = CompY)
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

procedure TveCustomOutline.GetScreenRectR( Item : TveBoardItem; var R : TRect );
var
    Left, Top, Right, Bottom : integer;
    i : integer;
    Shape : TcoShape;
    ShapeLeft, ShapeTop, ShapeRight, ShapeBottom : integer;
begin

    // create rectangle which includes all cells in this outline
    // this is not a bounding rectangle, ie. Right, Bottom cells rows include
    // drawn things like lines, circles, pins - whereas a bounding rectangle has
    // Right, Bottom as incremented by 1 so as to *enclose*

    // create bounding rectangle which includes all cells in this outline
    // start with a rectangle extents which must trigger changes if any shape exists
    Left := High(Left);
    Top := High(Top);
    Right := Low(Right);
    Bottom := Low(Bottom);

    // for each TcoShape, extend the rectangle to fit the shape
    for i := 0 to FShapes.Count -1 do begin
        Shape := TcoShape( FShapes[i] );
        Shape.GetRectangle( ShapeLeft, ShapeTop, ShapeRight, ShapeBottom );
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

    // we have a bounding rectangle - turn it into contents rectangle
    Dec( Right, 1 );
    Dec( Bottom, 1 );

    // rotate the item around its reference point
    Rotate( Left, Top, 0, 0, Item.Rotation );
    Rotate( Right, Bottom, 0, 0, Item.Rotation );

    // we now have offsets from the item reference point, so we add in the
    // reference point screen coords to get item rect in screen coords.
    Inc( Left, Item.X );
    Inc( Right, Item.X );
    Inc( Top, Item.Y );
    Inc( Bottom, Item.Y );

    // tranfer rectangle to result vars
    R.Left := Left;
    R.Right := Right;
    R.Top := Top;
    R.Bottom := Bottom;

    // arrange rotated coords to give left,top and right,bottom of rectangle.
    NormalizeRect( R );

    // turn into bounding rectangle
    Inc( R.Right );
    Inc( R.Bottom );
end;


function TveCustomOutline.PinIndexByName( const Name : string ) : integer;
begin
    result := inherited PinIndexByName( Name );
end;

procedure TveCustomOutline.ToFirstPin;
begin
    NextShapeIndex := 0;
    NextPinIndex := 0;
end;

function TveCustomOutline.GetNextPin(
    Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean;
var
    i : integer;
    Shape :  TcoShape;
    Found : boolean;
begin
    // prevent uninitialised variable warning
    Shape := nil;

    // search for next pin
    Found := False;
    for i := NextShapeIndex to FShapes.Count -1 do begin
        Shape := TcoShape( FShapes[i] );
        if Shape is TcoPin then begin

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
    X := TcoPin(Shape).SubX div TcoSubCellsPerCell;
    Y := TcoPin(Shape).SubY div TcoSubCellsPerCell;

    // rotate X,Y for Item
    Rotate( X, Y, 0, 0, Item.Rotation );

    // add offset for item position
    Inc( X, Item.X );
    Inc( Y, Item.Y );

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

procedure TveCustomOutline.BuildPinList;
var
    // manage Shapes[]
    i : Integer;
    coPin : TcoPin;

    // manage Pins[]
    PinIndex : integer;
    Pin : TvePin;
begin
    PinIndex := 0;

    // for every TcoShape in Shapes[]
    for i := 0 to FShapes.Count - 1 do begin

        // if this TcoShape is a TcoPin
        if Shapes[i] is TcoPin then begin

            coPin := TcoPin( Shapes[i] );

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


function TveCustomOutline.GetPin( index : integer ) : TvePin;
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

procedure TveCustomOutline.WriteToStream( S : TStream );

    procedure LineOut( const text : string );
    begin
        LineToStream( S, text );
    end;

var
    i : integer;
    Shape : TcoShape;
begin
    LineOut( Format( 'Outline=%s', [ClassName] ) );
    LineOut( Format('Name=%s', [Name]) );

    // susequent lines are shape data eg. "Line=3,2,4,8"

    // output shapes - one shape per line:
    for i := 0 to FShapes.Count -1 do begin
        Shape := TcoShape(FShapes[i]);

        if Shape is TcoLine then begin
            LineOut( Format( 'Line=%d,%d,%d,%d',
                [TcoLine(Shape).SubX, TcoLine(Shape).SubY,
                TcoLine(Shape).EndDeltaSubX, TcoLine(Shape).EndDeltaSubY]
            ));
        end
        else if Shape is TcoPin then begin
            LineOut( Format( 'Pin=%d,%d,%s',
                [TcoPin(Shape).SubX, TcoPin(Shape).SubY, TcoPin(Shape).Name]
            ));
        end;
    end;

    LineOut( 'end' );
end;

procedure TveCustomOutline.ReadFromStream( S : TStream );
var
    AName, AValue : string;
    Shape : TcoShape;
    ScanIndex : integer;
    Field : string;
begin
    while NameValueFromStream( S, AName, AValue ) do begin

        if AName = 'Name' then begin
            FName := AValue;
        end
        else if AName = 'Line' then begin

            Shape := TcoLine.Create;
            FShapes.Add( Shape );

            // x, y, EndDeltaX, EndDeltaY
            ScanIndex := 0;

            ParseCSVValue( AValue, Field, ScanIndex );
            Shape.FSubX := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            Shape.FSubY := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            TcoLine(Shape).FEndDeltaSubX := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            TcoLine(Shape).FEndDeltaSubY := StrToIntDef( Field, 1 );
        end
        else if AName = 'Pin' then begin

            Shape := TcoPin.Create;
            FShapes.Add( Shape );

            // x, y, number
            ScanIndex := 0;

            ParseCSVValue( AValue, Field, ScanIndex );
            Shape.FSubX := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            Shape.FSubY := StrToIntDef( Field, 1 );

            ParseCSVValue( AValue, Field, ScanIndex );
            TcoPin(Shape).Name := Field;
        end
        else if AName = 'end' then begin
            Break;
        end;
    end;

    BuildPinList;
end;

// ************** Functions used by Custom Outline Editor *****************

function TveCustomOutline.GetShapeAtSubCellXY(
        Item : TveBoardItem; SubCellX, SubCellY : single ) : TcoShape;
var
    i : integer;
    Shape, NearestShape : TcoShape;
    Distance, ShortestDistance : single;
begin
    NearestShape := nil;
    ShortestDistance := 100000000;
    for i := 0 to FShapes.Count -1 do begin
        Shape := TcoShape( FShapes[i] );
        Distance := Shape.DistanceToPoint( Item, SubCellX, SubCellY );
        if Distance < ShortestDistance then begin
            ShortestDistance := Distance;
            NearestShape := Shape;
        end;
    end;
    // reject Nearest Shape if it is too far away
    if (NearestShape <> nil) and (ShortestDistance > 8) then begin
        result := nil;
    end
    else begin
        result := NearestShape;
    end;
end;

function TveCustomOutline.GetSpecifiedShapeAtSubCellXY(
        Item : TveBoardItem; SubCellX, SubCellY : single; ShapeClass : TClass ) : TcoShape;
var
    i : integer;
    Shape, NearestShape : TcoShape;
    Distance, ShortestDistance : single;
begin
    NearestShape := nil;
    ShortestDistance := 100000000;
    for i := 0 to FShapes.Count -1 do begin
        Shape := TcoShape( FShapes[i] );
        // ignore everything except lines
        if Shape is ShapeClass then begin
            Distance := Shape.DistanceToPoint( Item, SubCellX, SubCellY );
            if Distance < ShortestDistance then begin
                ShortestDistance := Distance;
                NearestShape := Shape;
            end;
        end;
    end;
    // reject Nearest Shape if it is too far away
    if (NearestShape <> nil) and (ShortestDistance > 8) then begin
        result := nil;
    end
    else begin
        result := NearestShape;
    end;
end;

procedure TveCustomOutline.UnselectAllShapes;
var
    i : integer;
begin
    for i := 0 to FShapes.Count -1 do begin
        TcoShape( FShapes[i] ).Selected := False;
    end;
end;

procedure TveCustomOutline.SelectAllShapes;
var
    i : integer;
begin
    for i := 0 to FShapes.Count -1 do begin
        TcoShape( FShapes[i] ).Selected := True;
    end;
end;

function TveCustomOutline.GetSelectedCount : integer;
var
    i : integer;
begin
    result := 0;
    for i := 0 to FShapes.Count -1 do begin
        if TcoShape( FShapes[i] ).Selected then begin
            inc(result);
        end;
    end;
end;


function TveCustomOutline.SelectionIncludesPin : boolean;
var
    i : integer;
begin
    for i := 0 to FShapes.Count -1 do begin
        if FShapes[i] is TcoPin then begin
            result := True;
            exit;
        end;
    end;
    result := False;
end;


// **************************************************
//     UNDO-REDO FOR EDITING CUSTOM OUTLINE
// **************************************************
procedure TveCustomOutline.EnableUndo;
const
  UNDO_CAPACITY = 50;
begin
  // Once we edit a custom outline, the undo data stays with it until we delete
  // the outline or close the project
  if not Assigned( UndoEng ) then begin
      UndoEng := TunUndo.Create( UNDO_CAPACITY );
  end;
end;

procedure TveCustomOutline.SnapshotSelectedShapes;
var
  i : integer;
  Shape : TcoShape;
begin
    for i := 0 to FShapes.Count - 1 do begin
        Shape := TcoShape(FShapes[i]);
        if Shape.Selected then begin
            Shape.TakeSnapshot;
        end;
    end;
end;

procedure TveCustomOutline.StoreSnapshotSelectedAsUndo;
var
  i : integer;
  Shape : TcoShape;
  Memento : TcoMemento;
begin
    // begin Undo Transaction
    UndoEng.BeginTransaction;

    // add changed items to undo
    for i := 0 to FShapes.Count - 1 do begin
        Shape := TcoShape(FShapes[i]);
        if (Shape.Selected and Shape.ChangedSinceSnapshot) then begin
            Memento := Shape.CreateMementoFromSnapshot;
            UndoEng.AddMemento(Memento);
        end;
    end;

    // end Undo Transaction
    UndoEng.EndTransaction;
end;

procedure TveCustomOutline.RegisterNewShapeForUndo( Shape : TcoShape );
var
    Memento : TcoCustomOutlineMemento;
begin
    Memento := TcoCustomOutlineMemento.Create;
    Memento.Outline := Self;
    Memento.Shape := Shape;
    Memento.Operation := opAdd;
    UndoEng.BeginTransaction;
    UndoEng.AddMemento(Memento);
    UndoEng.EndTransaction;
end;

procedure TveCustomOutline.DeleteSelectedShapesWithUndo;
var
  i : integer;
  Shape : TcoShape;
  Memento : TcoCustomOutlineMemento;
begin
    // begin Undo Transaction
    UndoEng.BeginTransaction;

    // add changed items to undo
    for i := FShapes.Count - 1 downto 0 do begin
        Shape := TcoShape(FShapes[i]);
        if Shape.Selected then begin
            Memento := TcoCustomOutlineMemento.Create;
            Memento.Outline := Self;
            Memento.Shape := Shape;
            Memento.Operation := opRemove;
            UndoEng.AddMemento(Memento);
            FShapes.Extract( Shape );
        end;
    end;

    // end Undo Transaction
    UndoEng.EndTransaction;
end;

procedure TveCustomOutline.Undo;
begin
    UnselectAllShapes;
    UndoEng.Undo;
end;


procedure TveCustomOutline.Redo;
begin
    UnselectAllShapes;
    UndoEng.Redo;
end;



// ********************************************
//        TcoCustomOutlineMemento
// ********************************************

//TcoOperation = (opAdd, opRemove);
{
    Outline : TveCustomOutline;
    Shape : TcoShape;
    Operation : TcoOperation;
}

procedure TcoCustomOutlineMemento.Undo;
begin
    case Operation of
      // reverse an add operation by taking item out of container
      opAdd: begin
          Outline.FShapes.Extract(Shape);
      end;

      // reverse a remove operation by returning item to container
      opRemove: begin
          Shape.Selected := True;
          Outline.FShapes.Add(Shape);
      end;
    end;
end;

procedure TcoCustomOutlineMemento.Redo;
begin
    case Operation of
      // redo an add operation that was previously UNDONE by returning
      // item to container
      opAdd: begin
          Shape.Selected := True;
          Outline.FShapes.Add(Shape);
      end;

      // redo a remove operation by that was previously UNDONE by removing
      // the item once again
      opRemove: begin
          Outline.FShapes.Extract(Shape);
      end;
    end;
end;


procedure TcoCustomOutlineMemento.DiscardUndo;
begin
    case Operation of
      // throw away the Undo record for an Add Item by leaving the item
      // in the container
      opAdd: begin
      end;

      // throw away the Undo record for a Remove Item
      // by deleting the item that is owned by this Memento
      opRemove: begin
          Shape.Free;
      end;
    end;
    // always dispose of this unwanted Memento
    Free;
end;

procedure TcoCustomOutlineMemento.DiscardRedo;
begin
    case Operation of
      // throw away the Redo record for an Add Item operation that was
      // previously UNDONE - delete the item owned by this Memento
      opAdd: begin
          Shape.Free;
      end;

      // throw away the Redo record for a Remove Item operation that was
      // previously UNDONE - leave the item with its owning container
      opRemove: begin
      end;
    end;
    // always dispose of this unwanted Memento
    Free;
end;


(*
http://www.topcoder.com/tc?module=Static&d1=tutorials&d2=geometry1

For example, the dot product of (x1, y1) and (x2, y2) is x1*x2 + y1*y2. Note that
this is not a vector, but is simply a single number (called a scalar).

The cross product of two 2-D vectors is x1*y2 - y1*x2 Technically, the cross
product is actually a vector, and has the magnitude given above, and is directed
in the +z direction. Since we're only working with 2-D geometry for now, we'll
ignore this fact, and use it like a scalar.

    //Compute the dot product AB ? BC
    int dot(int[] A, int[] B, int[] C){
        AB = new int[2];
        BC = new int[2];
        AB[0] = B[0]-A[0];
        AB[1] = B[1]-A[1];
        BC[0] = C[0]-B[0];
        BC[1] = C[1]-B[1];
        int dot = AB[0] * BC[0] + AB[1] * BC[1];
        return dot;
    }
    //Compute the cross product AB x AC
    int cross(int[] A, int[] B, int[] C){               TveCustomOutlinep
        AB = new int[2];
        AC = new int[2];
        AB[0] = B[0]-A[0];
        AB[1] = B[1]-A[1];
        AC[0] = C[0]-A[0];
        AC[1] = C[1]-A[1];
        int cross = AB[0] * AC[1] - AB[1] * AC[0];
        return cross;
    }
    //Compute the distance from A to B
    double distance(int[] A, int[] B){
        int d1 = A[0] - B[0];
        int d2 = A[1] - B[1];
        return sqrt(d1*d1+d2*d2);
    }
    //Compute the distance from AB to C
    //if isSegment is true, AB is a segment, not a line.
    double linePointDist(int[] A, int[] B, int[] C, boolean isSegment){
        double dist = cross(A,B,C) / distance(A,B);
        if(isSegment){
            int dot1 = dot(A,B,C);
            if(dot1 > 0)return distance(B,C);
            int dot2 = dot(B,A,C);
            if(dot2 > 0)return distance(A,C);
        }
        return abs(dist);
    }

**************************

Line is defined by 2 points

Find the area of the triangle.  This formula is one which you probably haven't
seen before; it isn't usually used in high school mathematics.
Given the three coordinates of a triangle (x1, y1), (x2, y2), (x3, y3)
the area is given by A = |(1/2)(x1y2 + x2y3 + x3y1 - x2y1 - x3y2 - x1y3)|

Find base of triangle - ie sistance between the 2 points on the line
base = sqrt( (X1-X2)^2 + (Y1-Y2)^2)

Find height of the triangle:
area = 0.5 base x height, so height = area / ( 0.5 base )

Height is distance to line!


procedure SetDragPoint;
procedure MoveDragPoint( DeltaSubCellX, DeltaSubCellY );

*)

end.

