unit TrackPainter;

interface

uses Graphics, Types;


// *************** TLines ***************

type TLine = record
      X1 : integer;
      Y1 : integer;
      X2 : integer;
      Y2 : integer;
  end;

type PLine = ^TLine;

type TLines = class

  protected
    Lines : array of TLine;
    Count : integer;

  public
    procedure Clear;
    procedure AddLine( X1, Y1, X2, Y2 : integer );
    procedure Paint( Canvas : TCanvas; OffsetX, OffsetY : integer );
end;


// *************** TLinesWide ***************

type TLineWide = record
      X1 : integer;
      Y1 : integer;
      X2 : integer;
      Y2 : integer;
      Width : integer;
  end;

PLineWide = ^TLineWide;

type TLinesWide = class

  protected
    Lines : array of TLineWide;
    Count : integer;

  public
    procedure Clear;
    procedure AddLine( X1, Y1, X2, Y2, Width : integer );
    procedure Paint( Canvas : TCanvas; OffsetX, OffsetY : integer );

end;

// *************** THoles ***************

type THole = record
      X : integer;
      Y : integer;
  end;

PHole = ^THole;

type THoles = class

  protected
    Holes : array of THole;
    Count : integer;

  public
    procedure Clear;
    procedure AddHole( X1, Y1 : integer );
    procedure Paint( Canvas : TCanvas; OffsetX, OffsetY, Radius : integer );
end;



type TteTrackEditPainter = class

  protected

    // objects store primitives to be painted
    FTrackLines : TLines;
    FSegmentLines : TLinesWide;
    FBoardHoles : THoles;

    // drawing settings
    FPixelsPerCell : integer;
    FStripColor : TColor;
    FStripWidth1000 : integer;
    FStripsVisible : boolean;
    FHolesVisible : boolean;
    FHoleColor : TColor;
    FHoleOutlineColor : TColor;
    FHoleDiameter1000 : integer;

  public
    // draw stuff with board offset given by pixels
    LeftX : integer;
    TopY : integer;

    XOR_Mode : boolean;

    // track items add primitives here
    property TrackLines : TLines read FTrackLines;
    property SegmentLines : TLinesWide read FSegmentLines;
    property BoardHoles : THoles read FBoardHoles;

    // appearance
    property PixelsPerCell : integer read FPixelsPerCell write FPixelsPerCell;
    property StripColor : TColor read FStripColor write FStripColor;
    property StripWidth1000 : integer read FStripWidth1000 write FStripWidth1000;

    property StripsVisible : boolean read FStripsVisible write FStripsVisible;
    property HolesVisible : boolean read FHolesVisible write FHolesVisible;

    property HoleColor : TColor read FHoleColor write FHoleColor;
    property HoleOutlineColor : TColor read FHoleOutlineColor write FHoleOutlineColor;
    property HoleDiameter1000 : integer read FHoleDiameter1000 write FHoleDiameter1000;

    procedure Clear;

    // draw entire board on Bitmap - using current appearance properties
    // if necessary, resizing bitmap to suit
    procedure Paint( Canvas : TCanvas );

    constructor Create;
    destructor Destroy; override;
end;

implementation

// ****************************************
//     TLines - Standard Width Strips
// ****************************************

procedure TLines.Clear;
begin
    Count := 0;
end;

procedure TLines.AddLine( X1, Y1, X2, Y2 : integer );
var
    P : PLine;
begin
    // make room in dynamic array if needed
    if Count >= Length( Lines ) then begin
        SetLength( Lines, Count + 200 );
    end;

    // store Line details in next array element
    P := @(Lines[Count]);
    P^.X1 := X1;
    P^.Y1 := Y1;
    P^.X2 := X2;
    P^.Y2 := Y2;

    // count item addes
    Inc( Count );
end;

procedure TLines.Paint( Canvas : TCanvas; OffsetX, OffsetY : integer );
var
    i : integer;
    LineP : PLine;
begin
    for i := 0 to Count -1 do begin
      LineP := @Lines[i];
      Canvas.MoveTo( LineP^.X1 + OffsetX, LineP^.Y1 + OffsetY );
      Canvas.LineTo( LineP^.X2 + OffsetX, LineP^.Y2 + OffsetY );
    end;
end;

// *****************************************
//   TLinesWide - Definable Width Segments
// *****************************************

procedure TLinesWide.Clear;
begin
    Count := 0;
end;

procedure TLinesWide.AddLine( X1, Y1, X2, Y2, Width : integer );
var
    P : PLineWide;
begin
    // make room in dynamic array if needed
    if Count >= Length( Lines ) then begin
        SetLength( Lines, Count + 200 );
    end;

    // store Line details in next array element
    P := @(Lines[Count]);
    P^.X1 := X1;
    P^.Y1 := Y1;
    P^.X2 := X2;
    P^.Y2 := Y2;
    P^.Width := Width;

    // count item addes
    Inc( Count );
end;

procedure TLinesWide.Paint( Canvas : TCanvas; OffsetX, OffsetY : integer );
var
    i : integer;
    LineP : PLineWide;
begin
    for i := 0 to Count -1 do begin
        LineP := @Lines[i];
        Canvas.Pen.Width := LineP^.Width;
        Canvas.MoveTo( LineP^.X1 + OffsetX, LineP^.Y1 + OffsetY );
        Canvas.LineTo( LineP^.X2 + OffsetX, LineP^.Y2 + OffsetY );
    end;
end;

// ********************************************
//        THoles - Standard Radius Holes
// ********************************************

procedure THoles.Clear;
begin
    Count := 0;
end;

procedure THoles.AddHole( X1, Y1 : integer );
var
    P : PHole;
begin
    // make room in dynamic array if needed
    if Count >= Length( Holes ) then begin
        SetLength( Holes, Count + 200 );
    end;

    // store Line details in next array element
    P := @(Holes[Count]);
    P^.X := X1;
    P^.Y := Y1;

    // count item addes
    Inc( Count );
end;

procedure THoles.Paint( Canvas : TCanvas; OffsetX, OffsetY, Radius : integer );
var
    i : integer;
    HoleP : PHole;
begin
    for i := 0 to Count -1 do begin
        HoleP := @Holes[i];

        Canvas.Ellipse(
            HoleP^.X - Radius + OffsetX, HoleP^.Y - Radius + OffsetY,
            HoleP^.X + Radius + OffsetX, HoleP^.Y + Radius + OffsetY );
    end;
end;

// *****************************************
//            TRACK PAINTER
// *****************************************

constructor TteTrackEditPainter.Create;
begin
    // objects store primitives to be painted
    FTrackLines := TLines.Create;
    FSegmentLines := TLinesWide.Create;
    FBoardHoles := THoles.Create;

    FPixelsPerCell := 20;
    FStripColor := $E0E0E0;     // light grey
    FStripWidth1000 := 500;     // half width
    FStripsVisible := True;
    FHolesVisible := True;
    FHoleDiameter1000 := 167;   // 1/6th of a cell
    FHoleColor := clWhite;
    FHoleOutlineColor := clWhite;
end;

destructor TteTrackEditPainter.Destroy;
begin
    FTrackLines.Free;
    FSegmentLines.Free;
    FBoardHoles.Free;
    inherited;
end;

procedure TteTrackEditPainter.Clear;
begin
    FTrackLines.Clear;
    FSegmentLines.Clear;
    FBoardHoles.Clear;
end;


procedure TteTrackEditPainter.Paint( Canvas : TCanvas );
var
    StripWidthPixels : integer;
    HoleRadius : integer;
begin

    // draw strips as lines on top of board background
    Canvas.Pen.Style := psSolid;
    StripWidthPixels := (StripWidth1000 * FPixelsPerCell) div 1000;
    Canvas.Pen.Width := StripWidthPixels;
    if XOR_Mode then begin
        Canvas.Pen.Mode := pmXOR;
    end
    else begin
        Canvas.Pen.Mode := pmCopy;
    end;
    Canvas.Pen.Color := FStripColor;
    TrackLines.Paint( Canvas, -LeftX, -TopY );

    // draw segments as lines on top of board background
    SegmentLines.Paint( Canvas, -LeftX, -TopY );

//    if not XOR_Mode then begin
        // draw board holes
//        Canvas.Pen.Mode := pmCopy;
        Canvas.Pen.Color := HoleColor;
        Canvas.Pen.Width := 1;
        Canvas.Brush.Color := HoleOutlineColor;
        HoleRadius := ((HoleDiameter1000 * FPixelsPerCell) div 2000) +1;
        BoardHoles.Paint( Canvas, -LeftX, -TopY, HoleRadius );
//    end;
end;

(*
procedure TteTrackEditPainter.Paint( Canvas : TCanvas; Board : TbeTracks );
var
    PixelsWidth : integer;
    PixelsHeight : integer;

    StripWidth : integer;
//    InterStripWidth : integer;
    TopStripY : integer;
    LeftStripX : integer;

    i : integer;
    Item : TbeTrack;
    Strip : TteStrip;
    Segment : TteSegment;
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

        for i := 0 to Board.Count - 1 do begin
            Item := Board.Items[i];
            if Item is TteStrip then begin

                Strip := TteStrip(Item);
                Canvas.MoveTo(
                    (Strip.Start.X * FPixelsPerCell) + LeftStripX - LeftX,
                    (Strip.Start.Y * FPixelsPerCell) + TopStripY - TopY );
                Canvas.LineTo(
                    (Strip.Finish.X * FPixelsPerCell) + LeftStripX - LeftX,
                    (Strip.Finish.Y * FPixelsPerCell) + TopStripY -TopY );
            end;
        end;

        // Draw segments (non-strip) copper segments, for display only
        // 500 offset is half a cell - moves segments onto the centre of cell
        // coords used by strips
        for i := 0 to Board.Count - 1 do  begin

            Item := Board.Items[i];
            if Item is TteSegment then begin

                Segment := TteSegment(Item);
                    Canvas.Pen.Width := (PixelsPerCell * Segment.Width_1000) div 1000;
                    Canvas.MoveTo(

                        ((Segment.Start_1000.X + 500) * FPixelsPerCell) div 1000 - LeftX,
                        ((Segment.Start_1000.Y + 500) * FPixelsPerCell) div 1000 - TopY
                    );
                    Canvas.LineTo(
                        ((Segment.Finish_1000.X + 500) * FPixelsPerCell) div 1000 - LeftX,
                        ((Segment.Finish_1000.Y + 500) * FPixelsPerCell) div 1000 - TopY
                    );
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
        for i := 0 to Board.Count - 1 do begin
            Item := Board.Items[i];
            if Item is TteStrip then begin

            Strip := TteStrip(Item);

                // coords of top or left hole
                StripX := (Strip.Start.X * FPixelsPerCell) +
                    LeftStripX - HoleRadius -LeftX;
                StripY := (Strip.Start.Y * FPixelsPerCell) +
                    TopStripY - HoleRadius  -TopY ;
                // horizontal
                if Strip.IsHorizontal then begin
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
*)

end.
