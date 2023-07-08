unit ClipbrdGraphic;

interface

uses Editor, Graphics, Project, Windows;

type TveRuler = ( ruNone, ruNumber, ruLetterNumber ); 

// *******************************************************
//    ARTMAKER PUTS BITMAPPED BOARD IMAGE TO CLIPBOARD
// *******************************************************

type TveClipboarder = class

  protected
    FEditor : TveEditor;
    FRulers : TveRuler;
    FPixelsPerCell : integer;

    TopRulerHeight : integer;
    LeftRulerWidth : integer;
    RulerTextHeight : integer;

    Project : TveProject;

    procedure PaintToCanvas(
        Canvas : TCanvas; Project : TveProject; Area : TRect );

  public
//    property BorderWidth : integer;
//    property BorderColor : TColor;
    property Rulers : TveRuler read FRulers write FRulers;
    property PixelsPerCell : integer read FPixelsPerCell write FPixelsPerCell;
    property Editor : TveEditor read FEditor write FEditor;

    procedure CopyToClipboard;
//    constructor Create;
end;



implementation

uses Clipbrd, Outlines, Classes, Painter, BoardPainter, SysUtils;


const
    FBorder = 0;
    FGap = 1;

{
constructor TveArtMaker.Create;
begin
end;
}

function IntToLetter( i : integer ) : string;
begin
    // show single character A..Z
    if i < 26 then begin
        result := char( Ord('A') + (i mod 26) );
    end
    // show AA..ZZ
    else begin
        result := char( Ord('A') + (i div 26) -1 ) + char( Ord('A') + (i mod 26) );
    end;
end;



procedure TveClipboarder.PaintToCanvas(
    Canvas : TCanvas; Project : TveProject; Area : TRect );
var
    i : integer;
    Item : TveBoardItem;

    CellX1, CellY1, CellX2, CellY2 : integer;
    ScreenX1, ScreenY1, ScreenX2, ScreenY2 : integer;

    BoardPainter : TbrBoardPainter;
    Painter : TvePainter;

    LeftTopRulerValue, RightTopRulerValue : integer;

    Text : string;
    TextX, TextY : integer;

    TextSize : TSize;
begin
    // move origin so correct part of graphic is included in rect
    if Editor.SelectionValid then begin

        SetWindowOrgEx(
            Canvas.Handle,
            ( FPixelsPerCell * Editor.SelectedRect.Left ) - LeftRulerWidth,
            ( FPixelsPerCell * Editor.SelectedRect.Top ) - TopRulerHeight,
            nil
        );
    end
    else begin
        SetWindowOrgEx(
            Canvas.Handle,
            - LeftRulerWidth,
            - TopRulerHeight,
            nil
        );
    end;

    // visible screen area in cell coords.  Part of this rectangle of cells
    // may be partly hidden, but all should be drawn
    CellX1 := (Area.Left ) div FPixelsPerCell;
    CellY1 := (Area.Top ) div FPixelsPerCell;
    // ... CellX2 needs to be 1 more otherwise not entire visible area drawn
    CellX2 := 1+ (Area.Right) div FPixelsPerCell;
    CellY2 := (Area.Bottom) div FPixelsPerCell;

    // (ScreenX1, ScreenY1) and ( ScreenX2, ScreenY2) define rectangle we need
    // to draw inside.  Units are pixels : ie canvas coords.  Even though part
    // of this rectangle may be outside the visible rectangle "Rect", we use
    // this rectangle because its top left coords start exactly at top left of
    // a cell - and we have to draw integral cells.
    ScreenX1 := CellX1 * FPixelsPerCell;
    ScreenY1 := CellY1 * FPixelsPerCell;
    ScreenX2 := CellX2 * FPixelsPerCell;
    ScreenY2 := CellY2 * FPixelsPerCell;

    // BoardPainter object draws board, holes and strips
    BoardPainter := TbrBoardPainter.Create;
    try
        BoardPainter.PixelsPerCell := FPixelsPerCell;
        BoardPainter.BoardColor := Editor.BoardColor;
        BoardPainter.StripColor := Editor.StripColor;
        BoardPainter.Paint( Canvas, Project.Board );
    finally
        BoardPainter.Free;
    end;


    // draw BoardItems
    Painter := TvePainter.Create;
    try
        Painter.Border := FBorder;
        Painter.Gap := FGap;
        Painter.PixelsPerCell := FPixelsPerCell;
        Painter.TextDisplay := Editor.TextDisplay;

        Painter.LeadStyle := Editor.LeadStyle;
        Painter.LineWidth := Editor.ComponentLineWidth;
        Painter.BodyColor := Editor.BodyColor;
        Painter.PinColor := Editor.PinColor;

        Painter.SmallTextWidth := PixelsPerCell2CharWidth( FPixelsPerCell, tsSmall );
        Painter.SmallTextHeight :=  PixelsPerCell2CharHeight( FPixelsPerCell, tsSmall );

        Painter.LargeTextWidth := PixelsPerCell2CharWidth( FPixelsPerCell, tsLarge );
        Painter.LargeTextHeight := PixelsPerCell2CharHeight( FPixelsPerCell, tsLarge );


        //... draw BoardItems into TvePainter
        for i := 0 to Project.BoardItemCount -1 do begin
            Item := TveBoardItem(Project.BoardItems[i]);
            Item.Outline.Paint( Item, Painter );
        end;

        Painter.PaintNormal( Canvas );

    finally
            Painter.Free;
    end;

    
    if FRulers <> ruNone then begin

        // move coords back to 0,0 at top, left
        SetWindowOrgEx( Canvas.Handle, 0, 0 , nil );

        // erase ruler areas where component outlines were drawn
        Canvas.Brush.Color := Editor.BoardColor;
        //.. lefthand ruler
        Canvas.FillRect( Classes.Rect(
            0, 0, LeftRulerWidth,  TopRulerHeight + ScreenY2 - ScreenY1
        ));
        //.. top ruler
        Canvas.FillRect( Classes.Rect(
            LeftRulerWidth, 0, LeftRulerWidth + ScreenX2 - ScreenX1,  TopRulerHeight
        ));


        if Editor.SelectionValid then begin
            LeftTopRulerValue := Editor.SelectedRect.Top;
            RightTopRulerValue := Editor.SelectedRect.Left;
        end
        else begin
            LeftTopRulerValue := 0;
            RightTopRulerValue := 0;
        end;


        // write in ruler text
        Canvas.Font.Color := clBlack;
        Canvas.Font.Name := 'CourierNew';
        Canvas.Font.Height := (13 * FPixelsPerCell) div 16;

        // Painter.PaintNormal had side effect of leaving text alignment set
        // to TA_CENTER - ie. horizontally centered, but written below the y
        // ccord, ie. not centered in both x and y.  All following code works
        // with this alignment.

        //.. lefthand ruler always shows numbers
        TextX := (3 * LeftRulerWidth) div 4;
//        TextY := FTopRulerWidth + (FPixelsPerCell div 2) - (Canvas.Font.Height div 2);
//      same as above with less rounding error :
        TextY := TopRulerHeight + ((FPixelsPerCell - Canvas.Font.Height ) div 2);

        for i := LeftTopRulerValue to LeftTopRulerValue + CellY2 - CellY1 do begin
            Text := IntToStr(i mod 100);
            GetTextExtentPoint32( Canvas.Handle, pChar(Text), length(Text), TextSize );
            Canvas.TextOut( TextX - (TextSize.cx div 2), TextY, Text );
//            Canvas.TextOut( TextX - (Canvas.TextWidth(Text) div 2), TextY, IntToStr(i mod 100) );
            Inc( TextY, FPixelsPerCell );
        end;


        // if top ruler shows numbers
        if FRulers = ruNumber then begin

            //.. Top ruler
            TextX := LeftRulerWidth + (FPixelsPerCell div 2);
            TextY := FPixelsPerCell div 4;
            for i := RightTopRulerValue to RightTopRulerValue + CellX2 - CellX1 do begin
                Text := IntToStr(i mod 100);
                Canvas.TextOut( TextX, TextY, Text );
                Inc( TextX, FPixelsPerCell );
            end;
        end
        // else top ruler shows letters
        else if FRulers = ruLetterNumber then begin

            //.. Top ruler
            TextX := LeftRulerWidth + (FPixelsPerCell div 2);
            TextY := FPixelsPerCell div 4;
            for i := RightTopRulerValue to RightTopRulerValue + CellX2 - CellX1 do begin
                Text := IntToLetter(i);
                Canvas.TextOut( TextX, TextY, Text );
                Inc( TextX, FPixelsPerCell );
            end;
        end;

    end;

end;


procedure TveClipboarder.CopyToClipBoard;
var
    Bitmap : Graphics.TBitmap;
    Canvas : TCanvas;

begin

    Project := FEditor.Project;
    Bitmap := Graphics.TBitmap.Create;
    try

        Canvas := Bitmap.Canvas;

        // calculate size of rulers
        if FRulers <> ruNone then begin
            RulerTextHeight := (PixelsPerCell * 9) div 12;
            TopRulerHeight := PixelsPerCell;
            LeftRulerWidth := (PixelsPerCell * 15) div 12;
        end
        else begin
            RulerTextHeight := 0;
            TopRulerHeight := 0;
            LeftRulerWidth := 0;
        end;


        // if a valid mouse selection
        if Editor.SelectionValid then begin
            Bitmap.Width :=
                (FPixelsPerCell * (Editor.SelectedRect.Right - Editor.SelectedRect.Left)) +
                LeftRulerWidth;
            Bitmap.Height :=
                (FPixelsPerCell * (Editor.SelectedRect.Bottom - Editor.SelectedRect.Top)) +
                TopRulerHeight;
        end
        // else copy the whole graphic
        else begin
            Bitmap.Width := (FPixelsPerCell * Project.BoardWidth) +
                LeftRulerWidth;
            Bitmap.Height := (FPixelsPerCell * Project.BoardHeight) +
                TopRulerHeight;
        end;


        PaintToCanvas( Canvas, Project,
            Rect( 0, 0, FPixelsPerCell * Project.BoardWidth, FPixelsPerCell * Project.BoardHeight )
        );

        // send Bitmap to clipboard
        ClipBoard.Assign( Bitmap );
    finally
        Bitmap.Free;
    end
end;

end.