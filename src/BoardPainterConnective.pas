unit BoardPainterConnective;

interface

uses Graphics, Types,
    Board, Connective;

type TcnBoardPainter = class

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
//    procedure Paint( Canvas : TCanvas; Board : TbrBoard );
    procedure Paint( Canvas : TCanvas; Connectivity : TConnectivity );
    procedure PaintStripSet( Canvas : TCanvas; StripSet : TcnStripSet );

    constructor Create;
end;

implementation


constructor TcnBoardPainter.Create;
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

// *************************************************
//            PAINT ?? CANVAS
// *************************************************
{

}
procedure TcnBoardPainter.Paint( Canvas : TCanvas; Connectivity : TConnectivity );
var
    PixelsWidth : integer;
    PixelsHeight : integer;

    StripWidth : integer;
//    InterStripWidth : integer;
    TopStripY : integer;
    LeftStripX : integer;

    // data we get via Connectivity properties
    StripSet : TcnStripSet;
    SegmentGroup : TbrSegmentGroup;
    Strip : TcnStrip;
    Segment : TbrSegment;
    Board : TbrBoard;

    // working data
    i, j, k : integer;
    x,y : integer;
    StripX, StripY : integer;

    HoleDiam, HoleRadius : integer;
begin
    // * defined patterns get drawn using Board.StripSets *

    // calculate TPaintbox or TCustomControl dimensions : 2 extra pixels for border
    Board := Connectivity.Project.Board;
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
        Canvas.Pen.Color := FStripColor;

        for i := 0 to Connectivity.StripSetCount -1 do begin

            StripSet := Connectivity.StripSets[i];

            for j := 0 to StripSet.Count - 1 do begin
                Strip := StripSet.Strips[j];

                Canvas.MoveTo(
                    (Strip.Start.X * FPixelsPerCell) + LeftStripX,
                    (Strip.Start.Y * FPixelsPerCell) + TopStripY );
                Canvas.LineTo(
                    (Strip.Finish.X * FPixelsPerCell) + LeftStripX,
                    (Strip.Finish.Y * FPixelsPerCell) + TopStripY );
            end;
        end;

        // Draw segments (non-strip) copper segments
        // 500 offset is half a cell - moves segments onto the centre of cell
        // coords used by strips
        for i := 0 to Connectivity.StripSetCount -1 do begin

            StripSet := Connectivity.StripSets[i];

            for j := 0 to StripSet.SegmentGroupCount - 1 do begin
                SegmentGroup := StripSet.SegmentGroups[j];

                for k := 0 to SegmentGroup.Count - 1 do begin

                    Segment := SegmentGroup.Segments[k];

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

        // draw holes in all strips
        for i := 0 to Connectivity.StripSetCount -1 do begin

            StripSet := Connectivity.StripSets[i];

            for j := 0 to StripSet.Count - 1 do begin
                Strip := StripSet.Strips[j];

                // coords of top or left hole
                StripX := (Strip.Start.X * FPixelsPerCell) + LeftStripX - HoleRadius;
                StripY := (Strip.Start.Y * FPixelsPerCell) + TopStripY - HoleRadius;
                // horizontal
                if Strip.Direction = drHorizontal then begin
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
end;


// *************************************************
//            PAINT STRIPSET ON CANVAS
// *************************************************

// Input: TCanvas to draw on, TcnStripSet to draw strips from
// To draw a particular color, set Canvas.Pen.Color before calling

procedure TcnBoardPainter.PaintStripSet( Canvas : TCanvas; StripSet : TcnStripSet );
var
    j : integer;
    Strip : TcnStrip;
    StripWidth : integer;

//    StripWidth : integer;
//    InterStripWidth : integer;
    TopStripY : integer;
    LeftStripX : integer;

    StripX, StripY : integer;

    HoleRadius, HoleDiam : integer;
    x, y : integer;

    // segments
    k : integer;
    SegmentGroup : TbrSegmentGroup;
    Segment : TbrSegment;


begin
    // calculate common parameters
    StripWidth := (FPixelsPerCell * FStripWidth1000) div 1000;
    TopStripY := FPixelsPerCell div 2;
    LeftStripX := TopStripY;

    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := StripWidth;
    Canvas.Pen.Mode := pmCopy;

    // paint strip
    for j := 0 to StripSet.Count - 1 do begin
        Strip := StripSet.Strips[j];

        Canvas.MoveTo(
            (Strip.Start.X * FPixelsPerCell) + LeftStripX,
            (Strip.Start.Y * FPixelsPerCell) + TopStripY );
        Canvas.LineTo(
            (Strip.Finish.X * FPixelsPerCell) + LeftStripX,
            (Strip.Finish.Y * FPixelsPerCell) + TopStripY );
    end;

    // paint segments
    for j := 0 to StripSet.SegmentGroupCount - 1 do begin

        SegmentGroup := StripSet.SegmentGroups[j];

        for k := 0 to SegmentGroup.Count - 1 do begin

            Segment := SegmentGroup.Segments[k];

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



    // paint holes
//        Canvas.Pen.Style := psDot;
        Canvas.Pen.Width := 1;
//        Canvas.Pen.Mode := pmCopy;
        Canvas.Pen.Color := FHoleOutlineColor;
        Canvas.Brush.Color := FHoleColor;
        HoleDiam := ( FPixelsPerCell * FHoleDiameter1000 ) div 1000;
        HoleRadius := ( FPixelsPerCell * FHoleDiameter1000 ) div 2000;

    for j := 0 to StripSet.Count - 1 do begin
        Strip := StripSet.Strips[j];

        // coords of top or left hole
        StripX := (Strip.Start.X * FPixelsPerCell) + LeftStripX - HoleRadius;
        StripY := (Strip.Start.Y * FPixelsPerCell) + TopStripY - HoleRadius;
        // horizontal
        if Strip.Direction = drHorizontal then begin
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

end.
