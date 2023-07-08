unit PrintPreviewBoard;


interface

uses Grids, Windows, Messages, Classes, Controls, Printers, Forms,
    Project, PrintPainter, Painter, ColorScheme;

// This class can draw the board at desired scale, with red lines
// drawn over the board to show where pages will cut the board

type TvePrintPreview = class(TCustomControl)

  protected

    // internal variables
    PagesPainter : TvePrintPainter;
    ImageWidthScreenPixels : integer;
    ImageHeightScreenPixels : integer;
    LeftX : integer;
    TopY : integer;
    ScrollBorder : integer;   // scroll extra pixels around image

    // system properties
    FProject : TveProject;
    FOnChanged : TNotifyEvent;
    FDisplayPixelsPerInch : integer;

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
    FScalePercent : integer;
    FOrientation : TPrinterOrientation;

    FMarginLeftMM : integer;
    FMarginRightMM : integer;
    FMarginTopMM : integer;

    // system properties

    // mouse drag tracking
    LastMouseX, LastMouseY : integer;
    MovingMouse : boolean;

    // recalculated properties
    RecalculateDone : boolean;

    PixelsPerInchX, PixelsPerInchY : integer;

    PageWidthCanvasPixels : integer;
    PageHeightCanvasPixels : integer;
    PagesTotalWidthCanvasPixels : integer;
    CanvasXOffset : integer;

    PrinterPixelsPerInchX : integer;
    PrinterPageWidthPixels : integer;
    PrinterPixelsPerInchY : integer;
    PrinterPageHeightPixels : integer;

    // printer page dimensions
    PageWidthScreenPixels : integer;
    PageHeightScreenPixels : integer;

    // board dimensions
    BoardHeightScreenPixels : integer;
    BoardWidthScreenPixels : integer;

    PageCount : integer;


    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;
    procedure WMHScroll(var Msg: TWMHScroll); message WM_HSCROLL;
    procedure CreateParams(var Params: TCreateParams); override;
//    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

    procedure Paint; override;

    procedure SetHorzScroll;
    procedure SetVertScroll;
    procedure LimitLeftX;
    procedure LimitTopY;
    procedure Changed;
    procedure Resize; override;

    // internal tasks
//    procedure DrawRulers;

  public
    Colors : TveColorScheme;

    property Align;
    property Color;
    property Ctl3D;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property OnEnter;
    property OnExit;
    property OnChanged : TNotifyEvent read FOnChanged write FOnChanged;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // System Properties
    property Project : TveProject read FProject write FProject;
    property DisplayPixelsPerInch : integer read FDisplayPixelsPerInch write FDisplayPixelsPerInch;


    // User properties
    // ..units of 1/1000 of a cell
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
    property ScalePercent : integer read FScalePercent write FScalePercent;
    property Orientation : TPrinterOrientation read FOrientation write FOrientation;

    property MarginLeftMM : integer read FMarginLeftMM write FMarginLeftMM;
    property MarginRightMM : integer read FMarginRightMM write FMarginRightMM;
    property MarginTopMM : integer read FMarginTopMM write FMarginTopMM;

    procedure Recalculate;
    procedure ScrollToOrigin;

end;



implementation

uses SysUtils, Graphics, Outlines, PrintPageSizer, Cursors;


// *********************************
//      TvedPrintPreview
// *********************************

const
    PainterPixelsPerCell = 96;
    CellsPerInch = 10;      // standard perf board hole spacing

    // ruler calculations
    RulerTextHeight = (PainterPixelsPerCell * 9) div 12;
    TopRulerHeight = PainterPixelsPerCell;
    LeftRulerWidth = (PainterPixelsPerCell * 15) div 12;


constructor TvePrintPreview.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
    ControlStyle := ControlStyle + [csOpaque];
    PagesPainter := TvePrintPainter.Create;

    // initialise variables
    FScalePercent := 100;
    //..scroll border is a little bit of "extra scroll" that lets user see
    // a small blank area around the board edge. 4 pixels at 96 ppi resolution.
    ScrollBorder := Screen.PixelsPerInch div 20;
    ScrollToOrigin;
    Cursor := CursorMinder.GetCursor( csHandOpen );
end;

destructor TvePrintPreview.Destroy;
begin
    PagesPainter.Free;
    inherited;
end;


procedure TvePrintPreview.CreateParams(var Params: TCreateParams);
begin
    inherited CreateParams(Params);
    Params.Style := Params.Style or WS_VSCROLL or WS_HSCROLL {or WS_BORDER};
end;


procedure TvePrintPreview.Changed;
begin
    if Assigned( FOnChanged ) then begin
        FOnChanged( self );
    end;
end;

// *** Identify Keys We Want To Handle in this Control ***

// Handling CM_WANTSPECIALKEY lets us tell Delphi VCL which keys to send thru
// to KeyDown() .  Following keys can be requested
// VK_TAB, VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_RETURN, VK_EXECUTE, VK_ESCAPE
// and VK_CANCEL
(*
procedure TvePrintPreview.CMWantSpecialKey (var Message: TCMWantSpecialKey);
    begin
        // We want to handle the arrow keys ourselves
        case Message.CharCode of
            VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN : Message.Result := 1;
        end;
end;
*)

procedure TvePrintPreview.ScrollToOrigin;
begin
    TopY := - ScrollBorder;
    LeftX := - ScrollBorder;
end;

// When creating a custom control, always override Paint to draw the image
// of the control.
procedure TvePrintPreview.Paint;
var
    Rect : TRect;
    HDC : THandle;

    // retain for debugging!
    // IntResult : integer;
    //BoolResult : bool;

    PageTop : integer;
    PageBottom : integer;

    TextX, TextY : integer;
    i : integer;
    TextSize : TSize;
    RulerText : string;

const FBorder = 0;

begin
   // only need to paint inside this rectangle
    Rect := Canvas.ClipRect;

    // Erase Drawing Area
    Canvas.Pen.Color := clWhite;
    Canvas.Brush.Color := clWhite;
    // just invalidated area
    Canvas.Rectangle(
      Rect.Left, Rect.Top, Rect.Right - Rect.Left, Rect.Bottom - Rect.Top);
//      Rect.Left-1, Rect.Top-1, Rect.Right - Rect.Left+1, Rect.Bottom - Rect.Top+1);
    // entire area
    //    Canvas.Rectangle( 0, 0, Width, Height );


    if FProject = nil then begin
        exit;
    end;

    // we  work with DC, to alter Mapping Mode, ViewPort
    HDC := Canvas.Handle;

    // now setup viewport so that drawing at 24 pixels per cell will give the
    // correct scale, and show mirrored as required.

    // select a mapping mode which lets us choose any scale we like
    {IntResult := }SetMapMode(hdc, MM_ANISOTROPIC);

(*  IMPORTANT SAMPLE CODE
    // for 1:1 scale, with 16 pixels per cell and cells 0.1 inch apart,
    // have 160 pixels per inch.  Set this in WindowExt and set printer
    // pixels per inch in ViewPortExt.  Now we can work at 16 pixels per
    // cell in all our code for both X & Y directions.  The printer can
    // have different #s of pixels per inch in X & Y directions.
    SetWindowExtEx(hdc, 160, 160, nil);
    SetViewPortExtEx(hdc, PixelsPerInchX, PixelsPerInchY, nil );
*)
    // setup printer so we work with Painter internally in X & Y and
    // get correct size of output at 0.1 inch per cell and scaled as per
    // FScalePerce9nt.
    {BoolResult := }SetWindowExtEx(hdc,
        PainterPixelsPerCell * CellsPerInch,
        PainterPixelsPerCell * CellsPerInch,
        nil);

    if FMirrored then begin
        {BoolResult := }SetViewPortExtEx(hdc,
            (PixelsPerInchX * FScalePercent) div 100,
            (-PixelsPerInchY * FScalePercent) div 100,
            nil );
        // ViewPortOrg is in units of device pixels
         {BoolResult := }SetViewPortOrgEx(hdc, -LeftX, -TopY + BoardHeightScreenPixels, nil );
        //move origin so Painter produces board image with room for rulers,
        // in Painter units
        {BoolResult := }SetWindowOrgEx( hdc, -LeftRulerWidth, 0, nil );
    end
    else begin
        {BoolResult := }SetViewPortExtEx(hdc,
            (PixelsPerInchX * FScalePercent) div 100,
            (PixelsPerInchY * FScalePercent) div 100,
            nil );
        {BoolResult := }SetViewPortOrgEx(hdc, -LeftX, -TopY, nil );
        //move origin so Painter produces board image with room for rulers,
        // in Painter units
        {BoolResult := }SetWindowOrgEx( hdc, -LeftRulerWidth, -TopRulerHeight, nil );
    end;

    // copy user settings to PagesPainter
    PagesPainter.HoleDiameterCellThousandths := FHoleDiameterCellThousandths;
    PagesPainter.ShowHoles := FShowHoles;

    PagesPainter.StripLineWidthCellThousandths := FStripLineWidthCellThousandths;
    PagesPainter.ShowStripLines := FShowStripLines;

    PagesPainter.ComponentLineWidthCellThousandths := FComponentLineWidthCellThousandths;

    PagesPainter.ShowBreaks := FShowBreaks;
    PagesPainter.ShowComponents := FShowComponents;
    PagesPainter.ShowLinks := FShowLinks;
    PagesPainter.ShowWires := FShowWires;

    PagesPainter.LeadStyle := FLeadStyle;
    PagesPainter.ComponentTextDisplay := FComponentTextDisplay;
    PagesPainter.Mirrored := FMirrored;

    // other settings to PagesPainter
    PagesPainter.Project := FProject;

    PagesPainter.Colors := Colors;

    // pass doctored DC (TCanvas) to Print Painter function, to get board
    // layout "Printed"
    PagesPainter.Paint( Canvas );

    // remove coord shift so that board overlay lines can be drawn as usual
    {BoolResult := }SetWindowOrgEx( hdc, 0, 0, nil );

    // draw rulers

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
        Canvas.TextOut( TextX, TextY, RulerText);
        Inc( TextX, PainterPixelsPerCell );
    end;

(*
    When mirrored, DC or Canvas Y coords have been transformed to this:


         -----------------  <----- Y = + BoardHeight in CanvasPixels = PageTop
        |                 |
        |      BOARD      |
        |                 |       Y Positive
         -----------------  <---- Y = 0
                                  Y Negative


                            <----- Y = PageTop - PageHeightCanvasPixels

*)
    // ** draw page edges on top of image **
    if FMirrored then begin
        // drawn with y axis negative, offsetted by height of board
        PageTop := Project.BoardHeight * PainterPixelsPerCell;
        PageBottom := PageTop - PageHeightCanvasPixels;
    end
    else begin
        PageTop := 0;
        PageBottom := PageHeightCanvasPixels -1;
    end;

    // ..paint vertical lines at left edge of every page
    Canvas.Pen.Color := clRed;
    CanvasXOffset := 0;
    while CanvasXOffset < PagesTotalWidthCanvasPixels do begin
        Canvas.MoveTo( CanvasXOffset, PageTop );
        Canvas.LineTo( CanvasXOffset, PageBottom );
        Inc( CanvasXOffset, PageWidthCanvasPixels );
    end;

    // ..paint vertical line at right edge of last page
    Canvas.MoveTo( PagesTotalWidthCanvasPixels, PageTop );
    Canvas.LineTo( PagesTotalWidthCanvasPixels, PageBottom );

    // ..paint horizontal line along top of pages
    Canvas.MoveTo( 0, PageTop );
    Canvas.LineTo( PagesTotalWidthCanvasPixels, PageTop );

    // ..paint horizontal line along bottom of pages
    Canvas.MoveTo( 0, PageBottom );
    Canvas.LineTo( PagesTotalWidthCanvasPixels, PageBottom );


    // restore canvas settings
//    IntResult := SetMapMode(hdc, MM_TEXT);
end;


procedure TvePrintPreview.SetHorzScroll;
var ScrollInfo : TScrollInfo;
begin
    if ImageWidthScreenPixels <= ClientWidth then begin
        TopY := 0;
    end;

    ScrollInfo.cbSize := sizeof(TScrollInfo);
    ScrollInfo.fMask := SIF_POS or SIF_RANGE or SIF_PAGE;
    ScrollInfo.nMin := - ScrollBorder;
    ScrollInfo.nMax := ImageWidthScreenPixels + ScrollBorder + ScrollBorder;
    ScrollInfo.nPage := Width;
    ScrollInfo.nPos := LeftX;
    ScrollInfo.nTrackPos := 0;

    SetScrollInfo( handle, SB_HORZ, ScrollInfo, TRUE );
end;

procedure TvePrintPreview.SetVertScroll;
var ScrollInfo : TScrollInfo;
begin
    if ImageHeightScreenPixels <= ClientHeight then begin
        TopY := 0;
    end;

    ScrollInfo.cbSize := sizeof(TScrollInfo);
    ScrollInfo.fMask := SIF_POS or SIF_RANGE or SIF_PAGE;
    ScrollInfo.nMin := - ScrollBorder;
    ScrollInfo.nMax := ImageHeightScreenPixels + ScrollBorder + ScrollBorder;
    ScrollInfo.nPage := Height;
    ScrollInfo.nPos := TopY;
    ScrollInfo.nTrackPos := 0;

    SetScrollInfo( handle, SB_VERT, ScrollInfo, TRUE );
end;

procedure TvePrintPreview.LimitTopY;
begin
    if TopY < - Scrollborder then begin
        TopY := - Scrollborder;
    end
    else if TopY > ImageHeightScreenPixels + ScrollBorder + ScrollBorder - ClientHeight then begin
        TopY := ImageHeightScreenPixels + ScrollBorder + ScrollBorder - ClientHeight;
    end;
end;

procedure TvePrintPreview.LimitLeftX;
begin
    if LeftX < - ScrollBorder then begin
        LeftX := - ScrollBorder;
    end
    else if LeftX > ImageWidthScreenPixels + ScrollBorder + Scrollborder - ClientWidth then begin
        LeftX := ImageWidthScreenPixels + ScrollBorder + ScrollBorder - ClientWidth;
    end;
end;


procedure TvePrintPreview.WMVScroll(var Msg: TWMVScroll);
begin
    case Msg.ScrollCode of

        // SB_THUMBPOSITION updates when mouse released after moving scrollbar
        SB_THUMBPOSITION {, SB_THUMBTRACK} : begin
            TopY := Msg.Pos;
        end;
        // SB_THUMBTRACK gives continuous tracking
        SB_THUMBTRACK : begin
            ScrollWindowEx( handle, 0, TopY - Msg.Pos, nil, nil, 0, nil, SW_INVALIDATE);
            TopY := Msg.Pos;
            LimitTopY;
            SetVertScroll;
            exit;
        end;
        SB_LINEDOWN : begin
            Inc( TopY, 20 );
        end;
        SB_LINEUP : begin
            Dec( TopY, 20 );
        end;
        SB_PAGEDOWN : begin
            Inc( TopY, ClientHeight -1 );
        end;
        SB_PAGEUP : begin
            Dec( TopY, ClientHeight -1 );
        end
        else begin
            exit;
        end;
    end;

    LimitTopY;
    SetVertScroll;
    InvalidateRect( handle, ClientRect, False );
end;

procedure TvePrintPreview.WMHScroll(var Msg: TWMHScroll);
begin
    case Msg.ScrollCode of

        // SB_THUMBPOSITION updates when mouse released after moving scrollbar
        SB_THUMBPOSITION : begin
            LeftX := Msg.Pos;
        end;
        // SB_THUMBTRACK gives continuous tracking
        SB_THUMBTRACK : begin
            ScrollWindowEx( handle, LeftX - Msg.Pos, 0, nil, nil, 0, nil, SW_INVALIDATE);
            LeftX := Msg.Pos;
            LimitLeftX;
            SetHorzScroll;
            exit;
        end;
        SB_LINERIGHT : begin
            Inc( LeftX, 20 );
        end;
        SB_LINELEFT : begin
            Dec( LeftX, 20 );
        end;
        SB_PAGERIGHT : begin
            Inc( LeftX, ClientWidth -1 );
        end;
        SB_PAGELEFT : begin
            Dec( LeftX, ClientWidth -1 );
        end
        else begin
            exit;
        end;
    end;

    LimitLeftX;
    SetHorzScroll;
    InvalidateRect( handle, ClientRect, False );
end;



procedure TvePrintPreview.Recalculate;
var
    PageOnDevicePixels : TRect;
begin
    if FProject = nil then begin
        exit;
    end;

    // We want to draw pages "shrunken". PixelsPerInchX,Y are values we use to
    // draw on screen - in place of Printer PixelsPerInchX,Y .  Alter these
    // at will to scale the whole thing - page boundaries included
    PixelsPerInchX := FDisplayPixelsPerInch;
    PixelsPerInchY := FDisplayPixelsPerInch;

    Printer.Orientation := Orientation;

    // margin calculations: find print rectangle in device coords, including
    // effect of margins.
    PageOnDevicePixels := CalculatePrintRectangle(
        MarginLeftMM, MarginTopMM, MarginRightMM );

    // turn print rectangle into page width, page height
    PrinterPageWidthPixels := PageOnDevicePixels.Right - PageOnDevicePixels.Left;
    PrinterPageHeightPixels := PageOnDevicePixels.Bottom - PageOnDevicePixels.Top;

    PrinterPixelsPerInchX := GetDeviceCaps(Printer.Handle, LOGPIXELSX);
    PrinterPixelsPerInchY := GetDeviceCaps(Printer.Handle, LOGPIXELSY);

    // page size in terms of DC pixels (24 pixels per cell)
    PageWidthCanvasPixels :=
        ( PrinterPageWidthPixels * 100 * PainterPixelsPerCell * CellsPerInch )
            div (PrinterPixelsPerInchX * FScalePercent);
    PageHeightCanvasPixels :=
        ( PrinterPageHeightPixels * 100 * PainterPixelsPerCell * CellsPerInch )
            div (PrinterPixelsPerInchY * FScalePercent);
    PageCount := 1 +
        (((Project.BoardWidth * PainterPixelsPerCell) + LeftRulerWidth)
        div PageWidthCanvasPixels );
    PagesTotalWidthCanvasPixels := PageWidthCanvasPixels * PageCount;


    // Sizes in terms of screen coords
    PageWidthScreenPixels := PrinterPageWidthPixels * (PixelsPerInchX) div PrinterPixelsPerInchX;
    PageHeightScreenPixels := PrinterPageHeightPixels * (PixelsPerInchY) div PrinterPixelsPerInchY;
    //.. Height(inches) = Height(cells) / (CellsPerInch)
    //.. Height(screen pixels) = Height(inches) x ScreenPixelsPerInch
    //.. with scaling: Height(screen pixels) = Height(screen pixels) * ScalePercent / 100;
    //.. Note: does not include Ruler
    BoardHeightScreenPixels :=
        ( Project.BoardHeight * PixelsPerInchY * FScalePercent )
            div ( CellsPerInch * 100 );

    // size of total image, including off-screen portions
    // this is only used for scrollbar calculations.  We add a "bit more"
    // width so user can scroll right off the image border
    ImageWidthScreenPixels := (PageCount * PageWidthScreenPixels) + (PixelsPerInchX div 10);
    if BoardHeightScreenPixels > PageHeightScreenPixels then begin
        ImageHeightScreenPixels := BoardHeightScreenPixels;
    end
    else begin
        ImageHeightScreenPixels := PageHeightScreenPixels;
    end;
    Inc( ImageHeightScreenPixels, (PixelsPerInchX div 10) );

    SetVertScroll;
    SetHorzScroll;
end;

procedure TvePrintPreview.Resize;
begin
//    Recalculate;
end;


procedure TvePrintPreview.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
//    Cursor := CursorMinder.GetCursor( csHandOpen );
    MovingMouse := True;
    LastMouseX := X;
    LastMouseY := Y;
end;

procedure TvePrintPreview.MouseMove(Shift: TShiftState; X, Y: Integer);
var
    DeltaX, DeltaY : integer;
    OldLeftX, OldTopY : integer;
begin
    if not MovingMouse then begin
        exit;
    end;

    DeltaX := X - LastMouseX;
    DeltaY := Y - LastMouseY;
    LastMouseX := X;
    LastMouseY := Y;

    OldLeftX := LeftX;
    LeftX := LeftX - DeltaX;
    LimitLeftX;
    SetHorzScroll;

    OldTopY := TopY;
    TopY := TopY - DeltaY;
    LimitTopY;
    SetVertScroll;

    ScrollWindowEx( handle, OldLeftX-LeftX, OldTopY-TopY, nil, nil, 0, nil, SW_INVALIDATE);
end;

procedure TvePrintPreview.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
//    Screen.Cursor := crDefault;
    MovingMouse := False;
    InvalidateRect( handle, ClientRect, False );


end;




end.



