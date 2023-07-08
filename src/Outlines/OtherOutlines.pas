unit OtherOutlines;

interface

uses Outlines, Painter, Types;

// ***************************************
//     TveBreakOutline breaks a track
// ***************************************

type TveBreakOutline = class(TveOutline)

    constructor Create; override;

    procedure Paint( Item : TveBoardItem; Info : TvePainter ); override;
    function OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
        : boolean; override;
{
    function InsideRectangle( Item : TveBoardItem;
        CellX1, CellY1, CellX2, CellY2 : integer ) : boolean; override;
}
    procedure GetScreenRectR( Item : TveBoardItem; var R : TRect ); override;
end;


// ***************************************
//     TveWireOutline shows wiring point
// ***************************************

type TveWireOutline = class(TveOutline)

  protected
    NextPinIndex : integer;

  public

    constructor Create; override;

    procedure Paint( Item : TveBoardItem; Info : TvePainter ); override;

    function OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
        : boolean; override;
{
    function InsideRectangle( Item : TveBoardItem;
        CellX1, CellY1, CellX2, CellY2 : integer ) : boolean; override;
}        
    procedure RotateAboutCenter( Item : TveBoardItem ); override;
    function PinIndexAt( Item : TveBoardItem; CellX, CellY : integer )
        : integer; override;
    procedure GetScreenRectR( Item : TveBoardItem; var R : TRect ); override;
    procedure GetPaintRect( Item : TveBoardItem; var R : TRect ); override;

    // pin discovery
    procedure ToFirstPin; override;
    function GetNextPin(
        Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean; override;

end;


// ***************************************
//     TveText Displays a Line of Text
// ***************************************

type TveTextOutline = class(TveOutline)

  protected

  public

    constructor Create; override;

    procedure Paint( Item : TveBoardItem; Info : TvePainter ); override;

    function OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
        : boolean; override;
    procedure RotateAboutCenter( Item : TveBoardItem ); override;
    procedure GetScreenRectR( Item : TveBoardItem; var R : TRect ); override;        

    // special functions for Text
    function GetSize( Item : TveBoardItem ) : TTextSize;
    procedure SetSize( Item : TveBoardItem; Size : TTextSize );
end;


implementation

uses Rotations, SysUtils, Rectangles
{$IFNDEF VER200}, System.Contnrs, System.Classes {$ENDIF} ;

// ***************************************
//     TveBreakOutline breaks a track
// ***************************************

constructor TveBreakOutline.Create;
begin
    inherited;
    FName := 'Break';
end;

procedure TveBreakOutline.Paint( Item : TveBoardItem; Info : TvePainter );
var
    BodyLines : TPolyLines;
    PixelsPerCell : integer;
    HalfLineWidth : integer;

    // Item position on screen in pixels, top, left of cell[0,0]
    ComponentX, ComponentY : integer;

    // Top, Left, Bottom, Right coords
    Offset : integer;
    AX1, AY1, AX2, AY2 : integer;
    BX1, BY1, BX2, BY2 : integer;
begin
    BodyLines := Info.BodyLines;
    PixelsPerCell := Info.PixelsPerCell;

    //locate TCanvas pixels containing top left of Item
    ComponentX := (Item.X * PixelsPerCell) + Info.Border;
    ComponentY := (Item.Y * PixelsPerCell) + Info.Border;

    case Item.Shift of
        shRight : begin
            Inc( ComponentX, PixelsPerCell div 2 );
        end;
        shDown : begin
            Inc( ComponentY, PixelsPerCell div 2 );
        end;
    end;
(*
    // Will draw 2 offset X characters 'X' using two crossed lines
   bx1,by1    ax2,by1
ax1,ay1 **     **  bx2,ay1
          **  **
            **
          **  **
ax1,by2  **    ** bx2,by2
       bx1,ay2  ax2,ay2
*)
    // Will draw 2 offset X characters 'X' using two crossed lines
    Offset := PixelsPerCell div 8;
    HalfLineWidth := (Info.LineWidth div 2);
    AX1 := ComponentX + HalfLineWidth;
    AY1 := ComponentY + offset + HalfLineWidth;;
    AX2 := ComponentX + PixelsPerCell - Offset - HalfLineWidth;;
    AY2 := ComponentY + PixelsPerCell - HalfLineWidth;;

    BX1 := ComponentX + offset + HalfLineWidth;
    BY1 := ComponentY + HalfLineWidth;
    BX2 := ComponentX + PixelsPerCell - HalfLineWidth;
    BY2 := ComponentY + PixelsPerCell - Offset - HalfLineWidth;

    // ... draw line pair 1
    BodyLines.AddLine( AX1, AY1, AX2, AY2 );
    BodyLines.AddLine( BX1, BY1, BX2, BY2 );

    // ... draw line pair 2
    BodyLines.AddLine( AX1, BY2, AX2, BY1 );
    BodyLines.AddLine( BX1, AY2, BX2, AY1 );
end;


function TveBreakOutline.OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
    : boolean;
begin
    case Item.Shift of
        shNone : begin
            result := (CellX = Item.X) and (CellY = Item.Y);
        end;
        shRight : begin
            result := ((CellX = Item.X) or (CellX = Item.X + 1)) and (CellY = Item.Y);
        end;
        else begin // shDown :
            result := ((CellX = Item.X) and (CellY = Item.Y + 1)) or (CellY = Item.Y);
        end;
    end;
end;

{
function TveBreakOutline.InsideRectangle( Item : TveBoardItem;
    CellX1, CellY1, CellX2, CellY2 : integer ) : boolean;
begin
    // see if our location is inside rectangle
    result :=
        (CellX1 < Item.X) and (CellX2 > Item.X) and
        (CellY1 < Item.Y) and (CellY2 > Item.Y);
end;
}

procedure TveBreakOutline.GetScreenRectR( Item : TveBoardItem; var R : TRect );
begin
    // basic rectangle for unshifted break
    R.Left := Item.X;
    R.Right := Item.X + 1;
    R.Top := Item.Y;
    R.Bottom := Item.Y + 1;

    // extend include adjacent rectangle if break is shifted right or down
    case Item.Shift of
        shRight : begin
            Inc( R.Right );
        end;
        shDown : begin
            Inc( R.Bottom );
        end;
    end;
end;


// ***************************************
//     TveWireOutline shows wiring point
// ***************************************

constructor TveWireOutline.Create;
var
    Pin : TvePin;
begin
    inherited;
    FName := 'Wire';

    // pin 1 is only pin
    Pin := TvePin.Create;
    Pin.Name := '1';
    FPins.Add( Pin );
    FShowsValue := True;
end;


procedure TveWireOutline.Paint( Item : TveBoardItem; Info : TvePainter );
var
    BodyLines : TPolyLines;
    PixelsPerCell : integer;

    HalfLineWidth : integer;
    ComponentX, ComponentY : integer;
    X1, X2 : integer;
    Y1, Y2 : integer;
//    TextSize : TSize;
begin
    BodyLines := Info.BodyLines;
    PixelsPerCell := Info.PixelsPerCell;

    //locate TCanvas pixels containing top left of Item
    ComponentX := (Item.X * PixelsPerCell) + Info.Border;
    ComponentY := (Item.Y * PixelsPerCell) + Info.Border;

    // draw text first, because Windows leaves background colored area above
    // and below text - later, lines are drawn over this background
    if not (poXOR in Info.Options) then begin

        // draw Item.Value inside square : this identifies wire group on screen
        //... font Name is already setup - we just have to set height
        //    Canvas.Font.Name := 'Small Fonts';
        Info.BodyText.Add(
            Item.Value,
            ComponentX + (PixelsPerCell div 2),
            ComponentY + (PixelsPerCell div 2)
        );
    end;

(*
    // Will draw two lines
  x1,y1***********x2,y1



  x1,y2***********x2,y2
*)
    HalfLineWidth := (Info.LineWidth div 2);
    X1 := ComponentX + Info.Gap + HalfLineWidth;
    X2 := ComponentX + PixelsPerCell - Info.Gap - HalfLineWidth;
    Y1 := ComponentY + Info.Gap + HalfLineWidth;
    Y2 := ComponentY + PixelsPerCell - Info.Gap - HalfLineWidth;

    BodyLines.AddLine( X1, Y1, X2, Y1 );
    BodyLines.AddLine( X1, Y2, X2, Y2 );
end;


function TveWireOutline.OccupiesCell(
    Item : TveBoardItem; CellX, CellY : integer ) : boolean;
begin
    result := (CellX = Item.X) and (CellY = Item.Y);
end;

{
function TveWireOutline.InsideRectangle( Item : TveBoardItem;
        CellX1, CellY1, CellX2, CellY2 : integer ) : boolean;
begin
    // see if our location is inside rectangle
    result :=
        (CellX1 < Item.X) and (CellX2 > Item.X) and
        (CellY1 < Item.Y) and (CellY2 > Item.Y);
end;
}
{
function TveWireOutline.InsideRectangleR(
    Item : TveBoardItem; CellRect : TRect ) : boolean;
begin
    // see if our location is inside rectangle
    result :=
        (CellRect.Left < Item.X) and (CellRect.Right > Item.X) and
        (CellRect.Top < Item.Y) and (CellRect.Bottom > Item.Y);
end;
}
procedure TveWireOutline.RotateAboutCenter( Item : TveBoardItem );
begin
end;

function TveWireOutline.PinIndexAt( Item : TveBoardItem; CellX, CellY : integer )
    : integer;
begin
    if (CellX = Item.X) and (CellY = Item.Y) then begin
        result := 0;
    end
    else begin
        result := -1;
    end;
end;    


procedure TveWireOutline.GetScreenRectR( Item : TveBoardItem; var R : TRect );
begin
{
    R.Left := Item.X -1;
    R.Right := Item.X + 2;
    R.Top := Item.Y;
    R.Bottom := Item.Y + 1;
}
    R.Left := Item.X;
    R.Right := Item.X + 1;
    R.Top := Item.Y;
    R.Bottom := Item.Y + 1;

end;

procedure TveWireOutline.GetPaintRect( Item : TveBoardItem; var R : TRect );
begin
    // paint extends to square to right and left of Wire, because text can
    // be longer than expected
    R.Left := Item.X -1;
    R.Right := Item.X + 2;
    R.Top := Item.Y;
    R.Bottom := Item.Y + 1;
end;


// pin discovery
procedure TveWireOutline.ToFirstPin;
begin
    NextPinIndex := 0;
end;

function TveWireOutline.GetNextPin(
    Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean;
begin
    if NextPinIndex < 1 then begin
        PinIndex := 0;
        Inc( NextPinIndex );
        X := Item.X;
        Y := Item.Y;
        result := True;
    end
    else begin
        result := False;
    end;
end;
       


// ***************************************
//     TveText Displays a Line of Text
// ***************************************

// text also has properties such as alignment=left/center/right and
// size=large/small .  Where can we store this info in the TveBoardItem ?
// in Length parameter ??  The editor does alter Length for sizeable outlines
// but probably leaves it alone for non-sizable.

// Length value used as :
// b0..b7 size. 0=same as component text, approx 0.5 cell), 1=one cell height
// b8..b15 are alignment, 0=center, 1=left, 2=right


constructor TveTextOutline.Create;
begin
    inherited;
    Rotatable := True;
    FName := 'Text';
    FShowsValue := True;
end;

function GetAdjustedText( Item : TveBoardItem ) : string;
begin
    result := Trim( Item.Value );
    if result = '' then begin
        result := '??';
    end;
end;


procedure TveTextOutline.Paint( Item : TveBoardItem; Info : TvePainter );
var
    TextSize : TTextSize;
    CenterX, CenterY : integer;
    halfwidth, halfheight : integer;
    boxtop, boxleft, boxbottom, boxright : integer;
    Text : string;

begin
    TextSize := GetSize( Item );

    // text to display
    Text := GetAdjustedText( Item );

    if Info.Options = [poXOR] then begin
    //if Item.Selected then begin

        // calculate text width in pixels
        // we add 1 in case we have an odd number and division would lose remainder
        halfwidth :=
            (PixelsPerCell2CharWidth( Info.PixelsPerCell, TextSize ) * Length( Text ))
            div 2;
        halfheight := ( Info.PixelsPerCell * 6 ) div 16;

        // calculate center of text in pixels
        CenterX := (Item.X * Info.PixelsPerCell) + (Info.PixelsPerCell div 2);
        CenterY := (Item.Y * Info.PixelsPerCell) + (Info.PixelsPerCell div 2);

        // rectangle which holds text.  This is not a bounding rectangle
        boxleft := CenterX - halfwidth;
        boxright := CenterX + halfwidth;
        boxtop := CenterY - halfheight;
        boxbottom := CenterY + halfheight;

        Rotate( boxLeft, boxTop, CenterX, CenterY, Item.Rotation );
        Rotate( boxRight, boxBottom, CenterX, CenterY, Item.Rotation );

        Info.BodyLines.AddRectangle(boxLeft, BoxTop, BoxRight, BoxBottom );
    end;

    if TextSize = tsSmall then begin
        Info.SmallText.Add( Text,
            ( Item.X * Info.PixelsPerCell ) + ( Info.PixelsPerCell div 2 ),
            ( Item.Y * Info.PixelsPerCell ) + ( Info.PixelsPerCell div 2 ),
            Item.Rotation );
    end
    else begin
        Info.LargeText.Add( Text,
            ( Item.X * Info.PixelsPerCell ) + ( Info.PixelsPerCell div 2 ),
            ( Item.Y * Info.PixelsPerCell ) + ( Info.PixelsPerCell div 2 ),
            Item.Rotation );
    end;
end;

function TveTextOutline.OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
    : boolean;
var
    TextSize : TTextSize;
    CompX, CompY : integer;
    width : integer;
    Text : string;
begin
    TextSize := GetSize( Item );

    // text to display
    Text := GetAdjustedText( Item );

    // convert screen cell coords to outline cell coords
    CompX := CellX - Item.X;
    CompY := CellY - Item.Y;

    // rotate cell coords to follow outline rotation
    RotateReverse( CompX, CompY, 0, 0, Item.Rotation );

    // see if our location hits a cell used by our outline
    width := StrlenCells( Text, TextSize );
    //..work with X (width) coord doubled to avoid having to halve the width
    //.. StrlenCells() value with a lossy div
    CompX := 2 * CompX;

    // see if point lies within boundaries
    result :=
        ((-width) <= CompX) and
        ((width) >= CompX) and
        (CompY = 0);
end;

procedure TveTextOutline.RotateAboutCenter( Item : TveBoardItem );
begin
    Item.Rotation := TRotation( (Ord(Item.Rotation) + 1) mod 4 );
end;

procedure TveTextOutline.GetScreenRectR( Item : TveBoardItem; var R : TRect ); 
var
    TextSize : TTextSize;
    halfwidth : integer;
    Text : string;
begin
    TextSize := GetSize( Item );

    // text to display
    Text := GetAdjustedText( Item );     //

    // calculate text width
    // we add 1 in case we have an odd number and division would lose remainder
    halfwidth := (StrlenCells( Text, TextSize ) + 1) div 2;

    // rectangle which holds text.  This is not a bounding rectangle
    R.Left := Item.X - halfwidth;
    R.Right := Item.X + halfwidth;
    R.Top := Item.Y;
    R.Bottom := Item.Y;

    Rotate( R.Left, R.Top, Item.X, Item.Y, Item.Rotation );
    Rotate( R.Right, R.Bottom, Item.X, Item.Y, Item.Rotation );

    // arrange rotated coords to give left,top and right,bottom of rectangle.
    NormalizeRect( R );

    // turn inro bounding rectangle
    inc( R.Right );
    inc( R.Bottom );
end;

function TveTextOutline.GetSize( Item : TveBoardItem ) : TTextSize;
begin
    if Item.Length = 1 then begin
        result := tsSmall
    end
    else begin
        result := tsLarge;
    end;
end;

procedure TveTextOutline.SetSize( Item : TveBoardItem; Size : TTextSize );
const
    // type TTextSize = ( tsSmall, tsLarge );
    SizeToLength : array[TTextSize] of integer = ( 1, 2);
begin
    Item.Length := SizeToLength[Size];
end;



end.
