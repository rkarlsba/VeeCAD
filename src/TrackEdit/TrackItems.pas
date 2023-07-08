unit TrackItems;

interface

uses ManagedItem, Windows, Classes, Intersect, TrackPainter, UndoEngine;

type

TteTrack = class;

// *** BASE CLASS FOR ALL TRACK MEMENTOS ***
TteMemento = class( TunMemento )
end;


// *** BASE CLASS FOR ALL EDITABLE ITEMS ***
TteTrack = class
  protected

    // size when compared to other track items - smaller gets preference
    // for mouse clicks
    function GetArea : single; virtual; abstract;

  public
    Selected : boolean;
    Marked : boolean;

    property Area : single read GetArea;

    // lies under the mouse point in cell units
    function ClickedOn( Point : TFloatPoint ) : boolean; virtual; abstract;

    // is this point on the end circle of the track?
    function IsEndPoint( Point : TFloatPoint ) : boolean; virtual; abstract;

    // rectangle to repaint in cell units
    function GetPaintRect : TAlignedFloatRect; virtual; abstract;
    // in DIVS (1/1000th of a cell)
    function GetPaintRect_D : TRect; virtual; abstract;

    // is this track completely inside this rectangle in cell units
    function InsideRect( ARect : TAlignedFloatRect ) : boolean; virtual;
    // in DIVS (1/1000th of a cell)
    function InsideRect_D( ARect : TRect ) : boolean; virtual;

    // make track completely inside rectangle in DIVS
    procedure PullInsideRect_D( ARect : TRect ); virtual; abstract;

    // needs repainting if this rectangle redrawn
    function OverlapsPaintRect( ARect : TAlignedFloatRect ): boolean; virtual;
    // in DIVS (1/1000th of a cell)
    function OverlapsPaintRect_D( ARect : TRect ) : boolean; virtual;

    // move item around board
    procedure MoveCells( deltaX, deltaY : integer ); virtual; abstract;
    // in DIVS (1/1000th of a cell)
    procedure MoveCells_D( deltaX, deltaY : integer ); virtual; abstract;

    // swap start, finish if necessary to make finish nearest point
    procedure MakeFinishNearestPoint( Point : TFloatPoint ); virtual; abstract;

    procedure Paint( Painter : TteTrackEditPainter ); virtual; abstract;

    procedure WriteToStream( Stream : TStream ); virtual; abstract;
    procedure ReadFromStream( Stream : TStream ); virtual; abstract;

   function ChangedSinceSnapshot : boolean; virtual; abstract;
   procedure TakeSnapshot; virtual; abstract;
   function CreateMementoFromSnapshot : TteMemento; virtual; abstract;
end;


type TteStrip = class( TteTrack )

  protected
    Strip : TteStrip;    // reference to object described by this memento

    FStart : TPoint;     // first cell in straignt strip
    FFinish : TPoint;    // last cell in straight strip

    SnapshotStart : TPoint;
    SnapshotFinish : TPoint;

    // size when compared to other track items - smaller gets preference
    // for mouse clicks
    function GetArea : single; override;
    function GetWidth_D : integer;

  public
    property Start : TPoint read FStart write FStart;     // first cell in straignt strip
    property Finish : TPoint read FFinish write FFinish;  // last cell in straight strip
    property Width_D : integer read GetWidth_D;

    function IsHorizontal : boolean;

    // lies under the mouse point in cell units
    function ClickedOn( ClickPoint : TFloatPoint ) : boolean; override;

    // is this point on the end circle of the track?
    function IsEndPoint( Point : TFloatPoint ) : boolean; override;

    // rectangle to repaint in cell units
    function GetPaintRect : TAlignedFloatRect; override;
    function GetPaintRect_D : TRect; override;

    // make track completely inside rectangle
    procedure PullInsideRect_D( ARect : TRect ); override;

    // move item around board
    procedure MoveCells( deltaX, deltaY : integer ); override;
    procedure MoveCells_D( deltaX, deltaY : integer ); override;

    // swap start, finish if necessary to make finish nearest point
    procedure MakeFinishNearestPoint( Point : TFloatPoint ); override;

    procedure Paint( Painter : TteTrackEditPainter ); override;

    procedure WriteToStream( Stream : TStream ); override;
    procedure ReadFromStream( Stream : TStream ); override;

   function ChangedSinceSnapshot : boolean; override;
   procedure TakeSnapshot; override;
   function CreateMementoFromSnapshot : TteMemento;  override;
end;



TteStripMemento = class(TteMemento)
public
    Strip : TteStrip;
    Start_Delta : TPoint;
    Finish_Delta : TPoint;
    Procedure Undo; override;
    Procedure Redo; override;
    Procedure DiscardUndo; override;
    Procedure DiscardRedo; override;
end;

type TteSegment = class( TteTrack )

const
    MIN_WIDTH_D = 40;
    MAX_WIDTH_D = 5000;

  protected

    FWidth_1000 : integer;

    SnapshotStart_1000 : TPoint;
    SnapshotFinish_1000 : TPoint;
    SnapshotWidth_1000 : integer;

    procedure SetWidth_D( Value : integer );
    function GetMinWidth_D : integer;
    function GetMaxWidth_D : integer;

    // size when compared to other track items - smaller gets preference
    // for mouse clicks
    function GetArea : single; override;

  public
    Start_1000 : TPoint;
    Finish_1000 : TPoint;
    property Width_1000: integer read FWidth_1000 write SetWidth_D;
    property MinWidth_D : integer read GetMinWidth_D;
    property MaxWidth_D : integer read GetMaxWidth_D;

    // lies under the mouse point in cell units
    function ClickedOn( Point : TFloatPoint ) : boolean; override;

    // is this point on the end circle of the track?
    function IsEndPoint( Point : TFloatPoint ) : boolean; override;

    // rectangle to repaint in cell units
    function GetPaintRect : TAlignedFloatRect; override;
    function GetPaintRect_D : TRect; override;

    // make track completely inside rectangle
    procedure PullInsideRect_D( ARect : TRect ); override;

    // move item around board
    procedure MoveCells( deltaX, deltaY : integer ); override;
    procedure MoveCells_D( deltaX, deltaY : integer ); override;

    // swap start, finish if necessary to make finish nearest point
    procedure MakeFinishNearestPoint( Point : TFloatPoint ); override;

    procedure Paint( Painter : TteTrackEditPainter ); override;

    procedure WriteToStream( Stream : TStream ); override;
    procedure ReadFromStream( Stream : TStream ); override;

   function ChangedSinceSnapshot : boolean; override;
   procedure TakeSnapshot; override;
   function CreateMementoFromSnapshot : TteMemento; override;
end;

TteSegmentMemento = class(TteMemento)
public
    Segment : TteSegment;
    Start_1000_Delta : TPoint;
    Finish_1000_Delta : TPoint;
    Width_1000_Delta : integer;
    Procedure Undo; override;
    Procedure Redo; override;
    Procedure DiscardUndo; override;
    Procedure DiscardRedo; override;
end;



implementation

uses Math, SysUtils, Rectangles, TextUtils;

type TbeTrackError = class( Exception );


const DIVS_PER_CELL = 1000;

// *****************************************
//    TRACK (ANCESTOR of STRIP & SEGMENT)
// *****************************************

// *** BASE CLASS FOR ALL EDITABLE ITEMS ***

// is this track completely inside this rectangle in cell units
function TteTrack.InsideRect( ARect : TAlignedFloatRect ) : boolean;
var
    PaintRect : TAlignedFloatRect;
begin
    PaintRect := GetPaintRect;
    result := EnclosesRectAligned( PaintRect, ARect );
end;

function TteTrack.InsideRect_D( ARect : TRect ) : boolean;
var
    PaintRect : TRect;
begin
    PaintRect := GetPaintRect_D;
    result := ContainsRect( ARect, PaintRect );
end;

// needs repainting if this rectangle redrawn
function TteTrack.OverlapsPaintRect( ARect : TAlignedFloatRect ): boolean;
var
    PaintRect : TAlignedFloatRect;
begin
    PaintRect := GetPaintRect;
    result := AlignedFloatRectsIntersect( PaintRect, ARect );
end;

// needs repainting if this rectangle redrawn
function TteTrack.OverlapsPaintRect_D( ARect : TRect ): boolean;
var
    PaintRect : TRect;
begin
    PaintRect := GetPaintRect_D;
    result := RectanglesOverlap( PaintRect, ARect );
end;

// *****************************************
//                  STRIPS
// *****************************************

const
    STRIP_WIDTH_CELLS = 0.5;
    STRIP_HALF_WIDTH = STRIP_WIDTH_CELLS / 2;
    STRIP_WIDTH_D = DIVS_PER_CELL DIV 2;
    STRIP_HALF_WIDTH_D = STRIP_WIDTH_D DIV 2;

// width of a strip
function TteStrip.GetWidth_D : integer;
begin
    result := STRIP_WIDTH_D;
end;

// Test if Strip is Horizontal
function TteStrip.IsHorizontal : boolean;
begin
    result := Start.Y = Finish.Y;
end;

// is strip clicked on ?
function TteStrip.ClickedOn( ClickPoint : TFloatPoint ) : boolean;
var
    StartF, FinishF : TFloatPoint;
    Distance : single;
begin
    StartF.x := Start.X;
    StartF.y := Start.Y;
    FinishF.x := Finish.X;
    FinishF.y := Finish.Y;

    // test if we are 0.5 segment width from centre line of the strip
    Distance := LinePointDist( StartF, FinishF, ClickPoint );
    result := Distance <= STRIP_HALF_WIDTH;
end;


// is this point on the end circle of the track?
function TteStrip.IsEndPoint( Point : TFloatPoint ) : boolean;
var
    TrackEnd : TFloatPoint;
begin
    // are we on the circle at the Start end of track?
    TrackEnd.x := Start.X;
    TrackEnd.y := Start.Y;
    if DistanceBetweenPoints( Point, TrackEnd ) <= STRIP_HALF_WIDTH then begin
        result := True;
        exit;
    end;

    // are we on the circle at the Finish end of track?
    TrackEnd.x := Finish.X;
    TrackEnd.y := Finish.Y;
    if DistanceBetweenPoints( Point, TrackEnd ) <= STRIP_HALF_WIDTH then begin
        result := True;
        exit;
    end;
    result := False;
end;

// rectangle to repaint in cell units - as normalised aligned float rect
function TteStrip.GetPaintRect : TAlignedFloatRect;
begin
    result.TopLeft.x := Start.X;
    result.TopLeft.y := Start.Y;
    result.BottomRight.x := Finish.X;
    result.BottomRight.y := Finish.Y;

    NormaliseAlignedFloatRect( result );

    result.TopLeft.x := result.TopLeft.x - STRIP_HALF_WIDTH;
    result.TopLeft.y := result.TopLeft.y - STRIP_HALF_WIDTH;
    result.BottomRight.x := result.BottomRight.x + STRIP_HALF_WIDTH;
    result.BottomRight.y := result.BottomRight.y + STRIP_HALF_WIDTH;
end;

function TteStrip.GetPaintRect_D : TRect;
begin
    result.Bottom := Finish.Y * DIVS_PER_CELL;
    result.Left := Start.X * DIVS_PER_CELL;
    result.Right := Finish.X * DIVS_PER_CELL;
    result.Top := Start.Y * DIVS_PER_CELL;

    NormalizeRect( Result );

    result.TopLeft.x := result.TopLeft.x - STRIP_HALF_WIDTH_D;
    result.TopLeft.y := result.TopLeft.y - STRIP_HALF_WIDTH_D;
    result.BottomRight.x := result.BottomRight.x + STRIP_HALF_WIDTH_D;
    result.BottomRight.y := result.BottomRight.y + STRIP_HALF_WIDTH_D;
end;

// make Strip completely inside rectangle
procedure TteStrip.PullInsideRect_D( ARect : TRect );

    function DivsToCellsRoundUp( Value : integer ) : integer;
    begin
        result := Value div DIVS_PER_CELL;
        if Value MOD DIVS_PER_CELL > 0 then begin
            Inc( result );
        end;
    end;

    function DivsToCellsRoundDown( Value : integer ) : integer;
    begin
        result := Value div DIVS_PER_CELL;
        if Value MOD DIVS_PER_CELL < 0 then begin
            Dec( Result );
        end;
    end;

var
    EndRadius : integer;
    CellRect : TRect;
begin
    // shrink rectangle by radius
    EndRadius := STRIP_WIDTH_D div 2;
    ARect.Left := ARect.Left + EndRadius;
    ARect.Right := ARect.Right - EndRadius;
    ARect.Top := ARect.Top + EndRadius;
    ARect.Bottom := ARect.Bottom - EndRadius;

    // convert rectangle to cells
    CellRect.Left := DivsToCellsRoundUp( ARect.Left );
    CellRect.Right := DivsToCellsRoundDown( ARect.Right );
    CellRect.Top := DivsToCellsRoundUp( ARect.Top );
    CellRect.Bottom := DivsToCellsRoundDown( ARect.Bottom );

    // adjust centre points of start and end to fall inside rectangle
    FStart.X := Max( FStart.X, CellRect.Left );
    FStart.X := Min( FStart.X, CellRect.Right );

    FStart.Y := Max( FStart.Y, CellRect.Top );
    FStart.Y := Min( FStart.Y, CellRect.Bottom );

    FFinish.X := Max( FFinish.X, CellRect.Left );
    FFinish.X := Min( FFinish.X, CellRect.Right );

    FFinish.Y := Max( FFinish.Y, CellRect.Top );
    FFinish.Y := Min( FFinish.Y, CellRect.Bottom );
end;

// size when compared to other track items - smaller gets preference
// for mouse clicks. Area in square cell units.
function TteStrip.GetArea : single;
var
    dx, dy : single;
begin
    dx := Start.x - Finish.x;
    dy := Start.y - Finish.y;
    result := sqrt((dx * dx) + (dy * dy)) * STRIP_WIDTH_CELLS;
end;

// move item around board
procedure TteStrip.MoveCells( deltaX, deltaY : integer );
begin
    Inc( FStart.X, deltaX );
    Inc( FStart.Y, deltaY );
    Inc( FFinish.X, deltaX );
    Inc( FFinish.Y, deltaY );
end;

procedure TteStrip.MoveCells_D( deltaX, deltaY : integer );
var
    dx : integer;
    dy : integer;
begin
    // can only move in whole cells
    if ((deltaX mod DIVS_PER_CELL) <> 0) or
        ((deltaY mod DIVS_PER_CELL) <> 0)then begin
        raise TbeTrackError.Create( 'Internal Error - Fractional movement of strip.' );
    end;

    dx := deltaX div DIVS_PER_CELL;
    dy := deltaY div DIVS_PER_CELL;

    Inc( FStart.X, dX );
    Inc( FStart.Y, dY );
    Inc( FFinish.X, dX );
    Inc( FFinish.Y, dY );
end;

// swap start, finish if necessary to make finish nearest point
// swap start, finish if necessary to make finish nearest point
procedure TteStrip.MakeFinishNearestPoint( Point : TFloatPoint );
var
    StartF : TFloatPoint;
    PointToStartDist : single;
    FinishF : TFloatPoint;
    PointToFinishDist : single;
    Temp : TPoint;
begin
    // distance to start
    StartF.X := Start.X;
    StartF.Y := Start.Y;
    PointToStartDist := DistanceBetweenPoints( StartF, Point );

    // distance to finish
    FinishF.X := Finish.X;
    FinishF.Y := Finish.Y;
    PointToFinishDist := DistanceBetweenPoints( FinishF, Point );

    // make finish nearest the point
    if PointToStartDist < PointToFinishDist then begin
        Temp := Start;
        Start := Finish;
        Finish := Temp;
    end;
end;

procedure TteStrip.Paint( Painter : TteTrackEditPainter );
var
    PixelsPerCell : integer;
    x, y : integer;
begin
    PixelsPerCell := Painter.PixelsPerCell;

    // Strips **
    Painter.TrackLines.AddLine(
        Start.X * PixelsPerCell, Start.Y * PixelsPerCell,
        Finish.X * PixelsPerCell, Finish.Y * PixelsPerCell );

    // Holes **

    // horizontal
    if IsHorizontal then begin
        y := Start.Y;
        if Start.X < Finish.X then begin
            for x := Start.X to Finish.X do begin
                Painter.BoardHoles.AddHole( x * PixelsPerCell, y * PixelsPerCell );
            end;
        end
        else begin
            for x := Start.X downto Finish.X do begin
                Painter.BoardHoles.AddHole( x * PixelsPerCell, y * PixelsPerCell );
            end;
        end;

    end
    // vertical
    else begin
        x := Start.X;
        if Start.Y < Finish.Y then begin
            for y := Start.Y to Finish.Y do begin
                Painter.BoardHoles.AddHole( x * PixelsPerCell, y * PixelsPerCell );
            end;
        end
        else begin
            for y := Start.Y downto Finish.Y do begin
                Painter.BoardHoles.AddHole( x * PixelsPerCell, y * PixelsPerCell );
            end;
        end;
    end;
end;

// write out strip properties as lines of text followed by 'end'
procedure TteStrip.WriteToStream( Stream : TStream );

    procedure LineOut( const text : string );
    begin
        LineToStream( Stream, text );
    end;
begin
    LineOut('Strip' );
    LineOut( Format('StartX=%d', [Start.X] ) );
    LineOut( Format('StartY=%d', [Start.Y] ) );
    LineOut( Format('FinishX=%d', [Finish.X] ) );
    LineOut( Format('FinishY=%d', [Finish.Y] ) );
    LineOut( 'end' )
end;

procedure TteStrip.ReadFromStream( Stream : TStream );
var
    AName, AValue : string;
begin
{
Strip
StartX=6
StartY=2
FinishX=7
FinishY=2
end
}
    while NameValueFromStream( Stream, AName, AValue ) do begin
        if AName = 'StartX' then begin
            FStart.X := StrToIntDef( AValue, 0 );
        end
        else if AName = 'StartY' then begin
            FStart.Y := StrToIntDef( AValue, 0 );
        end
        else if AName = 'FinishX' then begin
            FFinish.X := StrToIntDef( AValue, 0 );
        end
        else if AName = 'FinishY' then begin
            FFinish.Y := StrToIntDef( AValue, 0 );
        end
        else if AName = 'end' then begin
            exit;
        end;
    end;
end;

function TteStrip.ChangedSinceSnapshot : boolean;
begin
    result :=
        (SnapshotStart.X <> FStart.X) or
        (SnapshotStart.Y <> FStart.Y) or
        (SnapshotFinish.X <> FFinish.X) or
        (SnapshotFinish.Y <> FFinish.Y);
end;
procedure TteStrip.TakeSnapshot;
begin
    SnapshotStart := FStart;
    SnapshotFinish := FFinish;
end;
function TteStrip.CreateMementoFromSnapshot : TteMemento;
begin
    result := TteStripMemento.Create;
    TteStripMemento(result).Strip := self;
    // record deltas
    TteStripMemento(result).Start_Delta.X := FStart.X - SnapshotStart.X;
    TteStripMemento(result).Start_Delta.Y := FStart.Y - SnapshotStart.Y;
    TteStripMemento(result).Finish_Delta.X := FFinish.X - SnapshotFinish.X;
    TteStripMemento(result).Finish_Delta.Y := FFinish.Y - SnapshotFinish.Y;
end;

// *****************************************
//            TteStripMemento
// *****************************************
{
TtStripMemento = class(TteMemento)
    Start : TPoint;
    Finish : TPoint;
}
Procedure TteStripMemento.Undo;
begin
    Strip.FStart.X := Strip.FStart.X - Start_Delta.X;
    Strip.FStart.Y := Strip.FStart.Y - Start_Delta.Y;
    Strip.FFinish.X := Strip.FFinish.X - Finish_Delta.X;
    Strip.FFinish.Y := Strip.FFinish.Y - Finish_Delta.Y;
    Strip.Selected := True;
end;

Procedure TteStripMemento.Redo;
begin
    Strip.FStart.X := Strip.FStart.X + Start_Delta.X;
    Strip.FStart.Y := Strip.FStart.Y + Start_Delta.Y;
    Strip.FFinish.X := Strip.FFinish.X + Finish_Delta.X;
    Strip.FFinish.Y := Strip.FFinish.Y + Finish_Delta.Y;
    Strip.Selected := True;
end;

Procedure TteStripMemento.DiscardUndo;
begin
    // this memento is no longer needed. Since it only describes a property
    // change, it has no responsibilities to any object. We delete it.
    Free;
end;
Procedure TteStripMemento.DiscardRedo;
begin
    // this memento is no longer needed. Since it only describes a property
    // change, it has no responsibilities to any object. We delete it.
    Free;
end;

// *****************************************
//                  SEGMENTS
// *****************************************

procedure TteSegment.SetWidth_D( Value : integer );
begin
    FWidth_1000 := Min( Value, MAX_WIDTH_D );
    FWidth_1000 := Max( FWidth_1000, MIN_WIDTH_D );
end;

function TteSegment.GetMinWidth_D : integer;
begin
    result := MIN_WIDTH_D;
end;

function TteSegment.GetMaxWidth_D : integer;
begin
    result := MAX_WIDTH_D;
end;

// overlaps a circle in cell units
function TteSegment.ClickedOn( Point : TFloatPoint ) : boolean;
var
    StartF, FinishF : TFloatPoint;
    Distance : single;
begin
    // convert DIVS to cell units
    StartF.x := Start_1000.X * (1 / DIVS_PER_CELL);
    StartF.y := Start_1000.Y * (1 / DIVS_PER_CELL);
    FinishF.x := Finish_1000.X * (1 / DIVS_PER_CELL);
    FinishF.y := Finish_1000.Y * (1 / DIVS_PER_CELL);

    // test if we are 0.5 segment width from centre line of the strip
    Distance := LinePointDist( StartF, FinishF, Point );

    result := Distance <= Width_1000 * (0.5 / DIVS_PER_CELL);
end;

// is this point on the end circle of the track?
function TteSegment.IsEndPoint( Point : TFloatPoint ) : boolean;
var
    TrackEnd : TFloatPoint;
begin
    // are we on the circle at the Start end of track?
    TrackEnd.x := Start_1000.X;
    TrackEnd.y := Start_1000.Y;
    if DistanceBetweenPoints( Point, TrackEnd ) <= (Width_1000 * 0.5) then begin
        result := True;
        exit;
    end;

    // are we on the circle at the Finish end of track?
    TrackEnd.x := Finish_1000.X;
    TrackEnd.y := Finish_1000.Y;
    if DistanceBetweenPoints( Point, TrackEnd ) <= (Width_1000 * 0.5) then begin
        result := True;
        exit;
    end;
    result := False;
end;

// rectangle to repaint in cell units - as normalised aligned float rect
function TteSegment.GetPaintRect : TAlignedFloatRect;
var
    HalfWidth : single;
begin
    result.TopLeft.x := Start_1000.X * (1 / DIVS_PER_CELL);
    result.TopLeft.y := Start_1000.Y * (1 / DIVS_PER_CELL);
    result.BottomRight.x := Finish_1000.X * (1 / DIVS_PER_CELL);
    result.BottomRight.y := Finish_1000.Y * (1 / DIVS_PER_CELL);

    NormaliseAlignedFloatRect( result );

    HalfWidth := Width_1000 * (0.5 / DIVS_PER_CELL);

    result.TopLeft.x := result.TopLeft.x - HalfWidth;
    result.TopLeft.y := result.TopLeft.y - HalfWidth;
    result.BottomRight.x := result.BottomRight.x + HalfWidth;
    result.BottomRight.y := result.BottomRight.y + HalfWidth;
end;

function TteSegment.GetPaintRect_D : TRect;
var
    HalfWidth : integer;
begin
    result.TopLeft.x := Start_1000.X;
    result.TopLeft.y := Start_1000.Y;
    result.BottomRight.x := Finish_1000.X;
    result.BottomRight.y := Finish_1000.Y;

    NormalizeRect( result );

    HalfWidth := Width_1000 DIV 2;

    result.TopLeft.x := result.TopLeft.x - HalfWidth;
    result.TopLeft.y := result.TopLeft.y - HalfWidth;
    result.BottomRight.x := result.BottomRight.x + HalfWidth;
    result.BottomRight.y := result.BottomRight.y + HalfWidth;
end;

// make track completely inside rectangle
procedure TteSegment.PullInsideRect_D( ARect : TRect );
var
    EndRadius : integer;
begin
    // shrink rectangle by radius
    EndRadius := Width_1000 div 2;
    ARect.Left := ARect.Left + EndRadius;
    ARect.Right := ARect.Right - EndRadius;
    ARect.Top := ARect.Top + EndRadius;
    ARect.Bottom := ARect.Bottom - EndRadius;

    // adjust centre points of start and end to fall inside rectangle
    Start_1000.X := Max( Start_1000.X, ARect.Left );
    Start_1000.X := Min( Start_1000.X, ARect.Right );

    Start_1000.Y := Max( Start_1000.Y, ARect.Top );
    Start_1000.Y := Min( Start_1000.Y, ARect.Bottom );

    Finish_1000.X := Max( Finish_1000.X, ARect.Left );
    Finish_1000.X := Min( Finish_1000.X, ARect.Right );

    Finish_1000.Y := Max( Finish_1000.Y, ARect.Top );
    Finish_1000.Y := Min( Finish_1000.Y, ARect.Bottom );
end;

// size when compared to other track items - smaller gets preference
// for mouse clicks. Area in square cell units.
function TteSegment.GetArea : single;
var
    dx, dy : single;
begin
    dx := Start_1000.x - Finish_1000.x;
    dy := Start_1000.Y - Finish_1000.Y;
    result := sqrt((dx * dx) + (dy * dy)) * width_1000 * 1E-9;
end;

// move item around board
procedure TteSegment.MoveCells( deltaX, deltaY : integer );
begin
    Inc( Start_1000.X, deltaX * 1000);
    Inc( Start_1000.Y, deltaY * 1000);
    Inc( Finish_1000.X, deltaX * 1000);
    Inc( Finish_1000.Y, deltaY * 1000);
end;

procedure TteSegment.MoveCells_D( deltaX, deltaY : integer );
begin
    Inc( Start_1000.X, deltaX );
    Inc( Start_1000.Y, deltaY );
    Inc( Finish_1000.X, deltaX );
    Inc( Finish_1000.Y, deltaY );
end;

// swap start, finish if necessary to make finish nearest point
procedure TteSegment.MakeFinishNearestPoint( Point : TFloatPoint );
var
    StartF : TFloatPoint;
    PointToStartDist : single;
    FinishF : TFloatPoint;
    PointToFinishDist : single;
    Temp : TPoint;
begin
    // distance to start
    StartF.X := Start_1000.X * ( 1 / DIVS_PER_CELL );
    StartF.Y := Start_1000.Y * ( 1 / DIVS_PER_CELL );
    PointToStartDist := DistanceBetweenPoints( StartF, Point );

    // distance to finish
    FinishF.X := Finish_1000.X * ( 1 / DIVS_PER_CELL );
    FinishF.Y := Finish_1000.Y * ( 1 / DIVS_PER_CELL );
    PointToFinishDist := DistanceBetweenPoints( FinishF, Point );

    // make finish nearest the point
    if PointToStartDist < PointToFinishDist then begin
        Temp := Start_1000;
        Start_1000 := Finish_1000;
        Finish_1000 := Temp;
    end;
end;

procedure TteSegment.Paint( Painter : TteTrackEditPainter );
var
    PixelsPerCell : integer;
begin
    PixelsPerCell := Painter.PixelsPerCell;

    // segments DIVS_PER_CELL
    Painter.SegmentLines.AddLine(
        Start_1000.X * PixelsPerCell div DIVS_PER_CELL,
        Start_1000.Y * PixelsPerCell div DIVS_PER_CELL,
        Finish_1000.X * PixelsPerCell div DIVS_PER_CELL,
        Finish_1000.Y * PixelsPerCell div DIVS_PER_CELL,
        Width_1000 * PixelsPerCell div DIVS_PER_CELL
    );
end;

// write out segment properties as lines of text followed by 'end'
procedure TteSegment.WriteToStream( Stream : TStream );

    procedure LineOut( const text : string );
    begin
        LineToStream( Stream, text );
    end;
begin
    LineOut('Segment' );
    LineOut( Format('Start_1000X=%d', [Start_1000.X] ) );
    LineOut( Format('Start_1000Y=%d', [Start_1000.Y] ) );
    LineOut( Format('Finish_1000X=%d', [Finish_1000.X] ) );
    LineOut( Format('Finish_1000Y=%d', [Finish_1000.Y] ) );
    LineOut( Format('Width_1000=%d', [Width_1000] ) );
    LineOut( 'end' )
end;

procedure TteSegment.ReadFromStream( Stream : TStream );
var
    AName, AValue : string;
begin
{
Segment
Start_1000X=5750
Start_1000Y=1500
Finish_1000X=7250
Finish_1000Y=1500
Width_1000=125
end
}
    while NameValueFromStream( Stream, AName, AValue ) do begin
        if AName = 'Start_1000X' then begin
            Start_1000.X := StrToIntDef( AValue, 0 );
        end
        else if AName = 'Start_1000Y' then begin
            Start_1000.Y := StrToIntDef( AValue, 0 );
        end
        else if AName = 'Finish_1000X' then begin
            Finish_1000.X := StrToIntDef( AValue, 0 );
        end
        else if AName = 'Finish_1000Y' then begin
            Finish_1000.Y := StrToIntDef( AValue, 0 );
        end
        else if AName = 'Width_1000' then begin
            Width_1000 := StrToIntDef( AValue, 200 );
        end
        else if AName = 'end' then begin
            exit;
        end;
    end;
end;

function TteSegment.ChangedSinceSnapshot : boolean;
begin
    result :=
    (SnapshotStart_1000.X <> Start_1000.X) or
    (SnapshotStart_1000.Y <> Start_1000.Y) or
    (SnapshotFinish_1000.X <> Finish_1000.X) or
    (SnapshotFinish_1000.Y <> Finish_1000.Y) or
    (SnapshotWidth_1000 <> FWidth_1000);
end;

procedure TteSegment.TakeSnapshot;
begin
    SnapshotStart_1000 := Start_1000;
    SnapshotFinish_1000 := Finish_1000;
    SnapshotWidth_1000 := FWidth_1000;
end;

function TteSegment.CreateMementoFromSnapshot : TteMemento;
begin
    result := TteSegmentMemento.Create;
    TteSegmentMemento(result).Segment := self;

    // deltas
    TteSegmentMemento(result).Start_1000_Delta.X :=
        Start_1000.X - SnapshotStart_1000.X;
    TteSegmentMemento(result).Start_1000_Delta.Y :=
        Start_1000.Y - SnapshotStart_1000.Y;

    TteSegmentMemento(result).Finish_1000_Delta.X :=
        Finish_1000.X - SnapshotFinish_1000.X;
    TteSegmentMemento(result).Finish_1000_Delta.Y :=
        Finish_1000.Y - SnapshotFinish_1000.Y;

    TteSegmentMemento(result).Width_1000_Delta :=
        FWidth_1000 - SnapshotWidth_1000;
end;

// *****************************************
//            TteSegmentMemento
// *****************************************

Procedure TteSegmentMemento.Undo;
begin
    Segment.Start_1000.X := Segment.Start_1000.X - Start_1000_Delta.X;
    Segment.Start_1000.Y := Segment.Start_1000.Y - Start_1000_Delta.Y;
    Segment.Finish_1000.X := Segment.Finish_1000.X - Finish_1000_Delta.X;
    Segment.Finish_1000.Y := Segment.Finish_1000.Y - Finish_1000_Delta.Y;
    Segment.Width_1000 := Segment.Width_1000 - Width_1000_Delta;
end;
Procedure TteSegmentMemento.Redo;
begin
    Segment.Start_1000.X := Segment.Start_1000.X + Start_1000_Delta.X;
    Segment.Start_1000.Y := Segment.Start_1000.Y + Start_1000_Delta.Y;
    Segment.Finish_1000.X := Segment.Finish_1000.X + Finish_1000_Delta.X;
    Segment.Finish_1000.Y := Segment.Finish_1000.Y + Finish_1000_Delta.Y;
    Segment.Width_1000 := Segment.Width_1000 + Width_1000_Delta;
end;
Procedure TteSegmentMemento.DiscardUndo;
begin
//    raise TbeTrackError.Create( 'DiscardUndo sent to Segment' );
    Free;
end;
Procedure TteSegmentMemento.DiscardRedo;
begin
//    raise TbeTrackError.Create( 'DiscardRedo sent to Segment' );
    Free;
end;


end.


