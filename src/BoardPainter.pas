unit BoardPainter;

interface

uses Graphics, Types,
    Board;

// ****************************************************
//        BOARD PAINTER DRAWS TRACKS ON A BITMAP
// ****************************************************

type TbrBoardPainter = class

  protected

    // drawing settings
    FPixelsPerCell : integer;
    FBoardColor : TColor;
    FStripColor : TColor;
    FStripWidth1000 : integer;
    FStripsVisible : boolean;
    FHolesVisible : boolean;
    FHoleColor : TColor;
    FHoleOutlineColor : TColor;
    FHoleDiameter1000 : integer;
  public

    // appearance
    property PixelsPerCell : integer read FPixelsPerCell write FPixelsPerCell;
    property BoardColor : TColor read FBoardColor write FBoardColor;
    property StripColor : TColor read FStripColor write FStripColor;
    property StripWidth1000 : integer read FStripWidth1000 write FStripWidth1000;
    property StripsVisible : boolean read FStripsVisible write FStripsVisible;
    property HolesVisible : boolean read FHolesVisible write FHolesVisible;
    property HoleColor : TColor read FHoleColor write FHoleColor;
    property HoleOutlineColor : TColor read FHoleOutlineColor write FHoleOutlineColor;
    property HoleDiameter1000 : integer read FHoleDiameter1000 write FHoleDiameter1000;

    // draw entire board on Bitmap - using current appearance properties
    // if necessary, resizing bitmap to suit
    procedure Paint( Canvas : TCanvas; Board : TbrBoard );

    constructor Create;
end;

implementation


constructor TbrBoardPainter.Create;
begin
    FPixelsPerCell := 24;
    FBoardColor := clWhite;
    FStripColor := $E0E0E0;     // light grey
    FStripWidth1000 := 500;     // half width
    FStripsVisible := True;
    FHolesVisible := True;
    FHoleDiameter1000 := 167;   // 1/6th of a cell
    FHoleColor := clWhite;
    FHoleOutlineColor := clWhite;
end;


procedure TbrBoardPainter.Paint( Canvas : TCanvas; Board : TbrBoard );
var
    PixelsWidth : integer;
    PixelsHeight : integer;

    StripWidth : integer;
//    InterStripWidth : integer;
    TopStripY : integer;
    LeftStripX : integer;

    i : integer;
    Strip : TbrStrip;
    Segment : TbrSegment;
    x,y : integer;
    StripX, StripY : integer;

    HoleDiam, HoleRadius : integer;
begin
    // * defined patterns get drawn using Board.StripSets *

    // calculate TPaintbox or TCustomControl dimensions : 2 extra pixels for border
    PixelsWidth := (Board.Width * FPixelsPerCell) +2;
    PixelsHeight := (Board.Height * FPixelsPerCell) +2;

    // calculate common parameters
    StripWidth := (FPixelsPerCell * FStripWidth1000) div 1000;
    TopStripY := FPixelsPerCell div 2;
    LeftStripX := TopStripY;

    // draw board
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := FBoardColor;
    Canvas.FillRect( Rect(0, 0, PixelsWidth, PixelsHeight ) );

    // draw strips and segments
    if FStripsVisible then begin

        // draw strips as lines on top of board background
        Canvas.Pen.Style := psSolid;
        Canvas.Pen.Width := StripWidth;
        Canvas.Pen.Mode := pmCopy;

        // XOR reveals how tracks drawn : make this a menu item, just for
        // editor use - Editor.XORMode := True - property sets a XORMode in
        // Editor.Board. Or just do Editor.Board.XORMode := True etc. Use
        // menu item that has checkmark
//        Canvas.Pen.Mode := pmXOR;

        Canvas.Pen.Color := FStripColor;

        for i := 0 to Board.StripCount - 1 do begin
            Strip := Board.Strips[i];
            Canvas.MoveTo(
                (Strip.Start.X * FPixelsPerCell) + LeftStripX,
                (Strip.Start.Y * FPixelsPerCell) + TopStripY );
            Canvas.LineTo(
                (Strip.Finish.X * FPixelsPerCell) + LeftStripX,
                (Strip.Finish.Y * FPixelsPerCell) + TopStripY );
        end;

        // Draw segments (non-strip) copper segments, for display only
        // 500 offset is half a cell - moves segments onto the centre of cell
        // coords used by strips
        for i := 0 to Board.SegmentCount - 1 do  begin

            Segment := Board.Segments[i];
                Canvas.Pen.Width := (PixelsPerCell * Segment.Width_1000) div 1000;
                Canvas.MoveTo(
                    ((Segment.X1_1000 + 500) * FPixelsPerCell) div 1000,
                    ((Segment.Y1_1000 + 500) * FPixelsPerCell) div 1000
                );
                Canvas.LineTo(
                    ((Segment.X2_1000 + 500) * FPixelsPerCell) div 1000,
                    ((Segment.Y2_1000 + 500) * FPixelsPerCell) div 1000
                );
        end;
    end;

    // draw holes
    if FHolesVisible then begin
        // ellipse is outlined using Pen, and filled           fsBrush.
        Canvas.Pen.Style := psDot;
        Canvas.Pen.Width := 1;
        Canvas.Pen.Mode := pmCopy;
        Canvas.Pen.Color := FHoleOutlineColor;
        Canvas.Brush.Color := FHoleColor;
        HoleDiam := ( FPixelsPerCell * FHoleDiameter1000 ) div 1000;
        HoleRadius := ( FPixelsPerCell * FHoleDiameter1000 ) div 2000;

{       // draw holes using HoleArray - defined rectangles of holes
        for i := 0 to Board.HoleArrayCount - 1 do begin
            HoleArray := Board.HoleArrays[i];
            StripY := (HoleArray.Top * FPixelsPerCell) + TopStripY - HoleRadius;
            for y := HoleArray.Top to HoleArray.Bottom do begin
                StripX := (HoleArray.Left * FPixelsPerCell) + LeftStripX - HoleRadius;
                for x := HoleArray.Left to HoleArray.Right do begin
                    Canvas.Ellipse(
                    StripX, StripY,
                    StripX + HoleDiam +1, StripY + HoleDiam +1);
                    Inc( StripX, FPixelsPerCell );
                end;
                Inc( StripY, FPixelsPerCell );
            end;
        end;
}

        // draw holes in all strips
        for i := 0 to Board.StripCount - 1 do begin

            Strip := Board.Strips[i];
            // coords of top or left hole
            StripX := (Strip.Start.X * FPixelsPerCell) + LeftStripX - HoleRadius;
            StripY := (Strip.Start.Y * FPixelsPerCell) + TopStripY - HoleRadius;
            // horizontal
            if Strip.Direction = diHorizontal then begin
                for x := Strip.Start.X to Strip.Finish.X do begin
                    Canvas.Ellipse(
                    StripX, StripY,
                    StripX + HoleDiam +1, StripY + HoleDiam +1);
                    Inc( StripX, FPixelsPerCell );
                end;
            end
            // vertical
            else begin
                for y := Strip.Start.Y to Strip.Finish.Y do begin
                    Canvas.Ellipse(
                    StripX, StripY,
                    StripX + HoleDiam +1, StripY + HoleDiam +1);
                    Inc( StripY, FPixelsPerCell );
                end;
            end;
        end;

    end;
end;


end.
