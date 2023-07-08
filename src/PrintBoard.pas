unit PrintBoard;

interface

uses Project, Graphics, Painter, PrintPainter, ColorScheme;

type TvePrinter = class

    protected
    Canvas : TCanvas;
    FProject : TveProject;
    FHoleDiameterCellThousandths : integer;
    FScalePercent : integer;
    FMirrored : boolean;

    FMarginLeftMM : integer;
    FMarginRightMM : integer;
    FMarginTopMM : integer;

    FComponentLineWidthCellThousandths : integer;
    ComponentLineWidthPixels : integer;
    FStripLineWidthCellThousandths : integer;
    StripLineWidthPixels : integer;
    FShowHoles : boolean;
    FShowStripLines : boolean;
    FShowDesignators : boolean;

    FShowComponents : boolean;
    FShowBreaks : boolean;
    FShowLinks : boolean;
    FShowWires : boolean;

    FLeadStyle : TLeadStyle;
    FComponentTextDisplay : TPrinterComponentText;

    FCanvasXOffset : integer;
    PagesPainter : TvePrintPainter;

    procedure PaintLeftRuler;
    procedure PaintTopRuler;

    public

    Colors : TveColorScheme;

    property ScalePercent : integer read FScalePercent write FScalePercent;
    property Mirrored : boolean read FMirrored write FMirrored;
    // component line width in units of 1/1000 of a cell

    property MarginLeftMM : integer read FMarginLeftMM write FMarginLeftMM;
    property MarginRightMM : integer read FMarginRightMM write FMarginRightMM;
    property MarginTopMM : integer read FMarginTopMM write FMarginTopMM;

    property ShowHoles : boolean read FShowHoles write FShowHoles;
    property ShowStripLines : boolean read FShowStripLines write FShowStripLines;
    property ShowDesignators : boolean read FShowDesignators write FShowDesignators;
    property ComponentTextDisplay : TPrinterComponentText
        read FComponentTextDisplay write FComponentTextDisplay;

    property LeadStyle : TLeadStyle read FLeadStyle write FLeadStyle;

    property ComponentLineWidthCellThousandths : integer
            read FComponentLineWidthCellThousandths
            write FComponentLineWidthCellThousandths;
    property StripLineWidthCellThousandths : integer
        read FStripLineWidthCellThousandths write FStripLineWidthCellThousandths;
    property HoleDiameterCellThousandths : integer
        read FHoleDiameterCellThousandths write FHoleDiameterCellThousandths;

    property ShowComponents : boolean read FShowComponents write FShowComponents;
    property ShowBreaks : boolean read FShowBreaks write FShowBreaks;
    property ShowLinks : boolean read FShowLinks write FShowLinks;
    property ShowWires : boolean read FShowWires write FShowWires;

    property Project : TveProject read FProject write FProject;

    procedure Print;
    constructor Create;
    destructor Destroy; override;
end;


implementation

uses Printers, Windows, Outlines, Rotations, SysUtils;

const
    Gap = 1;
    Border = 0;
    PainterPixelsPerCell = 96;    // drawing calcs to this pixel pitch
    CellsPerInch = 10;      // standard perf board hole spacing
(*
    We use 24 PixelsPerCell for all printing, since calcs use PixelsPerCell
    divided by 2, 4, 6, 8, 12.

    Because printers do not always have same number of pixels per inch
    vertically and horizontally, we use mapping to set printer vert, horiz
    scales and to get round circles and scale.  We have to do this, because
    Paint() code performs rotations etc which assumes a square array

    We set mapping mode to MM_ISOTROPIC (round circles)
*)
    // ruler calculations
    RulerTextHeight = (PainterPixelsPerCell * 9) div 12;
    TopRulerHeight = PainterPixelsPerCell;
    LeftRulerWidth = (PainterPixelsPerCell * 15) div 12;

constructor TvePrinter.Create;
begin
    PagesPainter := TvePrintPainter.Create;

    FScalePercent := 100;
    FComponentLineWidthCellThousandths := 1000 div 12;
    FStripLineWidthCellThousandths := 1000 div 200;
    FShowHoles := True;
    FShowStripLines := True;
    FShowDesignators := True;
end;

destructor TvePrinter.Destroy;
begin
    PagesPainter.Free;
    inherited;
end;

procedure TvePrinter.PaintLeftRuler;
var
    TextX, TextY : integer;
    i : integer;
    TextSize : TSize;
    RulerText : string;
begin
//>>>> NEEDS WORK - WindowOrg is in wrong place

    // PagesPainter.Paint leaves text alignment set to TA_CENTER - ie.
    // horizontally centered, but written below the y without centering

    // write in ruler text
    Canvas.Font.Color := clBlack;
    Canvas.Font.Name := 'CourierNew';
    Canvas.Font.Height := (13 * PainterPixelsPerCell) div 16;

    //.. lefthand ruler
    TextX := (3 * LeftRulerWidth) div 4;
    if FMirrored then begin
        TextY := TopRulerHeight - (PainterPixelsPerCell div 8);
    end
    else begin
        // TextY := FTopRulerHeight + (FPixelsPerCell div 2) - (Canvas.Font.Height div 2);
        // same as above with less rounding error :
        TextY := TopRulerHeight + ((PainterPixelsPerCell - Canvas.Font.Height ) div 2);
    end;  
    for i := 0 to Project.BoardHeight -1 do begin
        RulerText := IntToStr(i mod 100);
        GetTextExtentPoint32( Canvas.Handle, pChar(RulerText), length(RulerText), TextSize );
        Canvas.TextOut( TextX - (TextSize.cx div 2), TextY, RulerText );
        Inc( TextY, PainterPixelsPerCell );
    end;
end;

procedure TvePrinter.PaintTopRuler;
var
    TextX, TextY : integer;
    i : integer;
    RulerText : string;
begin
    //.. Top ruler
    TextX := LeftRulerWidth + (PainterPixelsPerCell div 2);
    if FMirrored then begin
        TextY := - (PainterPixelsPerCell div 6);
    end
    else begin
        TextY := PainterPixelsPerCell div 8;
    end;
    for i := 0 to Project.BoardWidth -1 do begin
        RulerText := IntToStr(i mod 100);
        Canvas.TextOut( TextX, TextY, RulerText );
        Inc( TextX, PainterPixelsPerCell );
    end;
end;


// ** COUNT NUMBER OF PAGES REQUIRED TO PRINT BOARD **
(*
Board can span multiple pages running from left to right along the length
of the board.  Can only span one page from top to bottom of the board. If the
scale property is set too large, the top to bottom of board will exceed page
height and will not be seen.
*)

// ** OUTPUT DOCUMENT ONTO PRINTER **

(*
Uses Delphi global object Printer.  Details such as which printer to use,
Landscape/Portrait, must be set via Printer before calling this procedure.
*)


procedure TvePrinter.Print;
var
    hdc : THandle;
    PixelsPerInchX, PixelsPerInchY : integer;
//    BoolResult : BOOL;
//    IntResult : integer;
    PageWidthCanvasPixels : integer;
    VerticalOffset : integer;

    PrinterPixelsOrigin : TPoint;
    Margin, MinMargin : integer;
//    FullPageWidthPixels : integer;
    PageWidthPixels : integer;
    PageHeightPixels : integer;
    hRegion : HRGN;

begin
    PagesPainter.Colors := Colors;

    // Paint One Page
    Canvas := Printer.Canvas;
    Printer.BeginDoc;
    try
        HDC := Printer.Handle;
        PixelsPerInchX := GetDeviceCaps(Printer.Handle, LOGPIXELSX);
        PixelsPerInchY := GetDeviceCaps(Printer.Handle, LOGPIXELSY);

        // left margin
        //.. convert left margin to device pixels
        Margin := (FMarginLeftMM * PixelsPerInchX * 10) div 254;
        //.. minimum margin allowed by printer
        MinMargin := GetDeviceCaps(Printer.Handle, PHYSICALOFFSETX);
        if Margin < MinMargin then begin
            Margin := MinMargin;
        end;
        //.. convert margin to offset from left printable point
        PrinterPixelsOrigin.X := Margin - MinMargin;

        // top margin
        //.. convert right margin to device pixels
        Margin := (FMarginTopMM * PixelsPerInchY * 10) div 254;
        //.. minimum margin allowed by printer
        MinMargin := GetDeviceCaps(Printer.Handle, PHYSICALOFFSETY);
        if Margin < MinMargin then begin
            Margin := MinMargin;
        end;
        //.. convert margin to offset from left printable point
        PrinterPixelsOrigin.Y := Margin - MinMargin;

        // right margin
        //.. convert right margin to device pixels
        Margin := (FMarginRightMM * PixelsPerInchX * 10) div 254;
        MinMargin :=
            GetDeviceCaps(Printer.Handle, PHYSICALWIDTH) -
            GetDeviceCaps(Printer.Handle, HORZRES) -
            GetDeviceCaps(Printer.Handle, PHYSICALOFFSETX);
        if Margin < MinMargin then begin
            Margin := MinMargin;
        end;
        //.. convert margin to PageWidthPixels
        PageWidthPixels :=
            GetDeviceCaps(Printer.Handle, PHYSICALWIDTH) -
            PrinterPixelsOrigin.X -
            Margin;

        //.. we are not concerned about the bottom margin : if necessary we
        // print until we hit the bottom of the page, because there are no
        // more pages available below.
        PageHeightPixels :=
            GetDeviceCaps(Printer.Handle, PHYSICALHEIGHT) -
            PrinterPixelsOrigin.Y;

        // set the device origin to create top & bottom margin

        // set a clipping rectangle on the canvas to impose the
        // right margin and page bottom
        hRegion := CreateRectRgn(
            PrinterPixelsOrigin.X, PrinterPixelsOrigin.Y,
            PrinterPixelsOrigin.X + PageWidthPixels, PrinterPixelsOrigin.Y + PageHeightPixels
        );
        //.. SelectClipRgn is in device pixels
        SelectClipRgn( hDC, hRegion );
        DeleteObject( hRegion );


        // select a mapping mode which lets us choose any scale we like
        {IntResult :=} SetMapMode(hdc, MM_ANISOTROPIC);

(*  IMPORTANT SAMPLE CODE
        // for 1:1 scale, with 16 pixels per cell and cells 0.1 inch apart,
        // have 160 pixels per inch.  Set this in WindowExt and set printer
        // pixels per inch in ViewPortExt.  Now we can work at 16 pixels per
        // cell in all our code for both X & Y directions.  The printer can
        // have different #s of pixels per inch in X & Y directions.
        SetWindowExtEx(hdc, 160, 160, nil);
        SetViewPortExtEx(hdc, PixelsPerInchX, PixelsPerInchY, nil );
*)
        // setup printer so we work with the fixed value of FPixelsPerCell
        // internally in X & Y at 0.1 inch per cell
        {BoolResult :=} SetWindowExtEx(hdc,
            PainterPixelsPerCell * CellsPerInch,
            PainterPixelsPerCell * CellsPerInch,
            nil);

        // setup printer so we work with Printer Pixels externally in printer
        // device pixels. Also include the scale factor chosen for this print

        if FMirrored then begin
            {BoolResult :=} SetViewPortExtEx(hdc,
                (PixelsPerInchX * FScalePercent) div 100,
                (-PixelsPerInchY * FScalePercent) div 100,
                nil );
            // ViewPortOrg is in units of device pixels with board height offset
            // includes moved origin in PrinterPixelsOrigin required by left,
            // top margins
            {BoolResult :=} SetViewPortOrgEx(hdc,
//                0,
//                (Project.BoardHeight * PixelsPerInchY * FScalePercent) div (CellsPerInch * 100),
                  PrinterPixelsOrigin.X,
                  (Project.BoardHeight * PixelsPerInchY * FScalePercent) div (CellsPerInch * 100) +
                  PrinterPixelsOrigin.Y,
                nil );

            // horiz ruler is at bottom of page, so no offset required
            VerticalOffset := 0;
        end
        else begin
            {BoolResult :=} SetViewPortExtEx(hdc,
                (PixelsPerInchX * FScalePercent) div 100,
                (PixelsPerInchY * FScalePercent) div 100,
                nil );
            // view port org is in device pixels, includes moved origin
            // in PrinterPixelsOrigin required by left, top margins
            {BoolResult :=} SetViewPortOrgEx(hdc,
//                0,
//                0,
                  PrinterPixelsOrigin.X,
                  PrinterPixelsOrigin.Y,
                nil );

            // move board down to make room for ruler along top
            VerticalOffset := TopRulerHeight;
        end;


        // Setup component line width
        (* because we alter scaling at Device Context, we get full scaling
        via TCanvas of Line Widths as well as line & ellipse coords.  Thus
        line width is in same units as line & ellipse coords.  Thus we simply
        convert line width to canvas pixel units & get scaling for free *)
        ComponentLineWidthPixels :=
            (FComponentLineWidthCellThousandths * PainterPixelsPerCell) div 1000;

        StripLineWidthPixels :=
            (FStripLineWidthCellThousandths *  PainterPixelsPerCell) div 1000;

        PageWidthCanvasPixels :=
            ( PageWidthPixels * 100 * PainterPixelsPerCell * CellsPerInch )
                div ((PixelsPerInchX * FScalePercent) );
(*
        PageWidthCanvasPixels :=
            ( Printer.PageWidth * 100 * PainterPixelsPerCell * CellsPerInch )
                div ((PixelsPerInchX * FScalePercent) );
*)

        // copy user settings to PagesPainter
        PagesPainter.HoleDiameterCellThousandths := FHoleDiameterCellThousandths;
        PagesPainter.ShowHoles := FShowHoles;

        PagesPainter.StripLineWidthCellThousandths := FStripLineWidthCellThousandths;
        PagesPainter.ShowStripLines := FShowStripLines;

        PagesPainter.ComponentLineWidthCellThousandths := FComponentLineWidthCellThousandths;

        PagesPainter.LeadStyle := FLeadStyle;
        PagesPainter.ComponentTextDisplay := FComponentTextDisplay;
        PagesPainter.Mirrored := FMirrored;

        PagesPainter.ShowComponents := ShowComponents;
        PagesPainter.ShowBreaks := FShowBreaks;
        PagesPainter.ShowLinks := FShowLinks;
        PagesPainter.ShowWires := FShowWires;


        // other settings to PagesPainter
        PagesPainter.Project := FProject;

        //move origin so Painter produces board image with room for rulers,
        // in Painter units
        {BoolResult :=} SetWindowOrgEx( hdc, -LeftRulerWidth, - VerticalOffset, nil );

        // paint first page
        PagesPainter.Paint( Canvas );
    {BoolResult :=} SetWindowOrgEx( Canvas.Handle, 0, 0, nil );
        PaintLeftRuler;
        PaintTopRuler;

        // calculate print position of start of next page
        FCanvasXOffset := PageWidthCanvasPixels - LeftRulerWidth;

        // paint any subsequent pages across
        while FCanvasXOffset < (FProject.BoardWidth * PainterPixelsPerCell) do begin
            Printer.NewPage;


            // set a clipping rectangle on the canvas to impose the
            // right margin and page bottom
            hRegion := CreateRectRgn(
                PrinterPixelsOrigin.X, PrinterPixelsOrigin.Y,
                PrinterPixelsOrigin.X + PageWidthPixels, PrinterPixelsOrigin.Y + PageHeightPixels
            );
            //.. SelectClipRgn is in device pixels
            SelectClipRgn( hDC, hRegion );
            DeleteObject( hRegion );


            {BoolResult :=} SetWindowOrgEx( hdc, FCanvasXOffset, -VerticalOffset, nil );
            PagesPainter.Paint( Canvas );
            {BoolResult :=} SetWindowOrgEx( hdc, FCanvasXOffset + LeftRulerWidth, 0, nil );
            PaintTopRuler;
            Inc( FCanvasXOffset, PageWidthCanvasPixels );
        end;

    finally
        Printer.EndDoc;
    end;
end;

end.


