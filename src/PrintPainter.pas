unit PrintPainter;

interface

uses Project, Graphics, Painter, BoardPainter, ColorScheme;

type TPrinterComponentText = ( ctNone, ctDesignators, ctValues );


(*******************************************************

   SIMPLE CLASS PAINTS ON A CANVAS IN PRINTER STLYE

   Canvas can be Printer.Canvas or WinControl.Canvas

  ******************************************************)

type TvePrintPainter = class

protected
    FProject : TveProject;

    BoardPainter : TbrBoardPainter;

    // user settings
    FHoleDiameterCellThousandths : integer;
    FShowHoles : boolean;

    FStripLineWidthCellThousandths : integer;
    FShowStripLines : boolean;

    FComponentLineWidthCellThousandths : integer;
    FShowBreaks : boolean;
    FShowComponents : boolean;
    FShowLinks : boolean;
    FShowWires : boolean;

    FLeadStyle : TLeadStyle;
    FComponentTextDisplay : TPrinterComponentText;
    FMirrored : boolean;

public

    // user settings
    Colors : TveColorScheme;

    // component line width in units of 1/1000 of a cell

    property HoleDiameterCellThousandths : integer
        read FHoleDiameterCellThousandths write FHoleDiameterCellThousandths;
    property ShowHoles : boolean read FShowHoles write FShowHoles;

    property StripLineWidthCellThousandths : integer
        read FStripLineWidthCellThousandths write FStripLineWidthCellThousandths;
    property ShowStripLines : boolean read FShowStripLines write FShowStripLines;

    property ComponentLineWidthCellThousandths : integer
            read FComponentLineWidthCellThousandths
            write FComponentLineWidthCellThousandths;

    property ShowComponents : boolean read FShowComponents write FShowComponents;
    property ShowBreaks : boolean read FShowBreaks write FShowBreaks;
    property ShowLinks : boolean read FShowLinks write FShowLinks;
    property ShowWires : boolean read FShowWires write FShowWires;

    property LeadStyle : TLeadStyle read FLeadStyle write FLeadStyle;
    property ComponentTextDisplay : TPrinterComponentText
        read FComponentTextDisplay write FComponentTextDisplay;
    property Mirrored : boolean read FMirrored write FMirrored;


    property Project : TveProject read FProject write FProject;

    procedure Paint( Canvas : TCanvas );

    constructor Create;
    destructor Destroy; override;

end;


implementation

uses Printers, Windows, Outlines, OtherOutlines, SizeableOutlines, Rotations,
    WineHelper;

constructor TvePrintPainter.Create;
begin
    inherited;
    BoardPainter := TbrBoardPainter.Create;
end;

destructor TvePrintPainter.Destroy;
begin
    BoardPainter.Free;
    inherited;
end;


procedure TvePrintPainter.Paint( Canvas : TCanvas );
var
    i : integer;
    Item : TveBoardItem;
    Outline : TveOutline;
    Painter : TvePainter;
    Dc : hDC;
    OldFont : hFont;

    // low level settings
    ComponentLineWidthPixels : integer;


const ComponentTextFDisplay2PainterText :
    array[TPrinterComponentText] of TTextDisplay = ( tdNone, tdDesignator, tdValue );

const
    Gap = 1;
    Border = 0;
    PixelsPerCell = 96;    // drawing calcs to this pixel pitch
    CellsPerInch = 10;      // standard perf board hole spacing


begin

    ComponentLineWidthPixels :=
        (FComponentLineWidthCellThousandths * PixelsPerCell) div 1000;

    BoardPainter.PixelsPerCell := PixelsPerCell;

    if Colors.ShowColor then begin
        BoardPainter.BoardColor := Colors.Board;
        BoardPainter.StripColor := Colors.Strips;
    end
    else begin
        BoardPainter.BoardColor := clWhite;
        BoardPainter.StripColor := clSilver; //$808080;
    end;

    BoardPainter.StripWidth1000 := FStripLineWidthCellThousandths;
    BoardPainter.StripsVisible := FShowStripLines;
    BoardPainter.HolesVisible := FShowHoles;
    BoardPainter.HoleColor := clWhite;
    // wide strips have white holes
    if FStripLineWidthCellThousandths > HoleDiameterCellThousandths then begin
        BoardPainter.HoleOutlineColor := clWhite;
    end
    // narrow strips have thin black outline holes
    else begin
        BoardPainter.HoleOutlineColor := clBlack;
    end;

    BoardPainter.HoleDiameter1000 := HoleDiameterCellThousandths;
    BoardPainter.Paint( Canvas, FProject.Board );

    Painter := TvePainter.Create;
    try
        // load up paint data structure used by BoardItems when painting
        Painter.Border := Border;
        Painter.Gap := Gap;
        Painter.PixelsPerCell := PixelsPerCell;
        Painter.Options := [];
        Painter.TextDisplay := ComponentTextFDisplay2PainterText[FComponentTextDisplay];
        Painter.LeadStyle := FLeadStyle;

        //... draw BoardItems into Painter which stores all lines, text
        for i := 0 to FProject.BoardItemCount -1 do begin
            Item := FProject.BoardItems[i];
            Outline := Item.Outline;
            if Outline is TveBreakOutline then begin
                if not FShowBreaks then begin
                    continue;
                end;
            end
            else if Outline is TveLinkOutline then begin
                if not FShowLinks then begin
                    continue;
                end;
            end
            else if Outline is TveWireOutline then begin
                if not FShowWires then begin
                    continue;
                end;
            end
            else begin
                if not FShowComponents then begin
                    continue;
                end;
            end;

            Item.Outline.Paint( Item, Painter );
        end;


        DC := Canvas.Handle;
        // .. all text is horizontally centered
        SetTextAlign( DC, TA_CENTER );

        if (not FMirrored) then begin

            Painter.SmallTextWidth := PixelsPerCell2CharWidth( PixelsPerCell, tsSmall );
            Painter.SmallTextHeight :=  PixelsPerCell2CharHeight( PixelsPerCell, tsSmall );

            Painter.LargeTextWidth := PixelsPerCell2CharWidth( PixelsPerCell, tsLarge );
            Painter.LargeTextHeight := PixelsPerCell2CharHeight( PixelsPerCell, tsLarge );

            // draw component designators out of Painter - these leave a dead space
            // around them so draw before the outlines.  This uses the Canvas DC
            // and does not change the font originally selected into that DC.
            OldFont := SelectObject( DC, Painter.SmallFont0.Handle );

            // in B&W mode, print text over a patch of white,
            // while in Color mode, print straight over color underneath
            if Colors.ShowColor then begin
                SetBkMode(Canvas.handle, TRANSPARENT);
            end;

            try
                // small text, includes component and user text
                Painter.SmallText.PaintDC( DC, Rot0 );

                SelectObject( DC, Painter.SmallFont90.Handle );
                Painter.SmallText.PaintDC( Canvas.Handle, Rot90 );

                SelectObject( DC, Painter.SmallFont180.Handle );
                Painter.SmallText.PaintDC( Canvas.Handle, Rot180 );

                SelectObject( DC, Painter.SmallFont270.Handle );
                Painter.SmallText.PaintDC( Canvas.Handle, Rot270 );

                // large text, (user text)
                SelectObject( DC, Painter.LargeFont0.Handle );
                Painter.LargeText.PaintDC( Canvas.Handle, Rot0 );

                SelectObject( DC, Painter.LargeFont90.Handle );
                Painter.LargeText.PaintDC( Canvas.Handle, Rot90 );

                SelectObject( DC, Painter.LargeFont180.Handle );
                Painter.LargeText.PaintDC( Canvas.Handle, Rot180 );

                SelectObject( DC, Painter.LargeFont270.Handle );
                Painter.LargeText.PaintDC( Canvas.Handle, Rot270 );

            finally
                SelectObject( DC, OldFont );
                SetBkMode(Canvas.handle, OPAQUE);
            end;
        end;

        // draw components using TCanvas functions
        Canvas.Pen.Style := psSolid;
        Canvas.Pen.Width := ComponentLineWidthPixels;
        Canvas.Pen.Mode := pmCopy;

        Canvas.Font.Name := 'Arial';
        Canvas.Font.Height := (PixelsPerCell * 3) div 4;

        // ..draw body lines out of Painter
        if Colors.ShowColor then begin
            Canvas.Pen.Color := Colors.Body;
        end
        else begin
            Canvas.Pen.Color := clBlack;
        end;
        Painter.BodyLines.Paint( Canvas );
        if WineHosted then begin
            Painter.BodyCircles.Segments := 8;
        end;
        Painter.BodyCircles.Paint( Canvas );

        // draw pins using line segments
        if Colors.ShowColor then begin
            Canvas.Pen.Color := Colors.Pin;
        end
        else begin
            Canvas.Pen.Color := clBlack;
        end;
        Painter.PinLines.Paint( Canvas );

        // .. all text is horizontally centered
        Canvas.Font.Color := clBlack;

        //.. white background, or transparent
        //  SetBkMode(Canvas.handle, TRANSPARENT);
        // OR
        //  SetBkColor(  HDC hdc, COLORREF crColor );

        if FMirrored then begin
            Painter.BodyText.PaintMirroredDC( Canvas );
        end
        else begin
            Painter.BodyText.Paint( Canvas );
        end;

    finally
        Painter.Free;
    end;

    // draw rectangle around board
    // linewidth of 1 provides indistinct rectangle.  Thicker linewidth may
    // be better.  Don't use .Rectangle function, since wastes time filling
    // rectangle - better to use 4 lines or .Polyline.  For now, border not
    // drawn.
(*
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Color := clBlack;
    Bottom := Height * FPixelsPerCell + Border;
    Right := Width * FPixelsPerCell + Border;
    MoveTo( 0,0 );
    LineTo( Right, Width );
    LineTo( Bottom, Width );
    LineTo( Bottom, 0 );
    LineTo( 0, 0 );
*)
end;


end.





