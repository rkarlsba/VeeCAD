unit TrackEditor;

interface

uses Controls, Classes, Windows, Graphics, Messages,
    Board, Intersect, Tracks, TrackItems, TrackPainter, SegmentProperties;


type
    TteEditMode = ( bmSelect, bmStrip, bmSegment, bmDonut );
    TteEditorModeChange = procedure( Sender : TObject; Mode : TteEditMode )
        of object;

    TbeTrackMouseMoveTask = (
        mtNone,
        mtDrawSelectionRectangle,
        mtDrawStrip, mtDrawSegment,
        mtDragEndStrip, mtDragEndSegment,
        mtMoveSelected
    );


    TbeDrawMode = ( dmNormal, dmSelected, dmXOR );
    TveArrowMove = ( amNone, amUp, amDown, amLeft, amRight );

    TteMouseMove = procedure( X_DIV, Y_DIV : integer ) of object;

// *************************************************
// *************************************************

type TteTrackEditor = class( TCustomControl )

  protected

    Tracks : TbeTracks;
    Painter : TteTrackEditPainter;

    // editing variables
    FEditMode : TteEditMode;
    MouseMoveTask : TbeTrackMouseMoveTask;
    MouseMoveItem : TteTrack;
    DrawMode : TbeDrawMode;

    // LeftX, TopY are board coords in screen pixels at top, left of the canvas
    LeftX : integer;
    TopY : integer;
    BoardHeightScreenPixels : integer;
    BoardWidthScreenPixels : integer;
    // extra pixels to scroll so actual board edge is clearly displayed
    ScrollBorder : integer;

    // simple properties
    //.. draw selection rectangle, etc with this line width
    FDrawLineWidth : integer;

    // property handlers
//    procedure SetEditMode( AEditMode : TbeEditMode );

    // ** Mouse Down/Move/Up State Machine Vars **
    // Where mouse went down as float and DIVs
    MouseDownCellCoords : TFloatPoint;
    MouseDownCellCoords_D : TPoint;
    // where mouse went down in screen pixels
    ClickOriginalClient : TPoint;
    // X,Y distance from where the mouse went down
    LastDeltaXCells_D, LastDeltaYCells_D : integer;
    // Selection rectangle in Divs
    ClickSelectedItemsRect_D : TRect;
    // selection rectangle in screen units
    SelectionClientRect : TRect;
    // when dragging items or selections, move in these steps
    DragGrid_1000 : integer;

    // Reference to Strip or Segment that we are in process of drawing
    DrawStrip : TteStrip;
    DrawSegment : TteSegment;

    // ** Events **
    FOnChangeMode : TteEditorModeChange;
    FOnMouseMove : TteMouseMove;

    FStripColor : TColor;
    FSelectionColor : TColor;
    FBoardColor : TColor;

    // form for entering segment changes
    SegmentPropertiesForm : TSegmentPropertiesForm;

    // ** Scrolling **
    procedure Recalculate;
    procedure SetVertScroll;
    procedure SetHorzScroll;
    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;
    procedure WMHScroll(var Msg: TWMHScroll); message WM_HSCROLL;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Resize; override;
    // EraseBackgroud - doesn't seem to make any visible difference whether we
    // let Windows erase the background or prevent it.
    procedure EraseBackground(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;

    // mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    function ClickxyToCells( ClickX, ClickY : integer) : TFloatPoint;
    function ClickxyToCells_D( ClickX, ClickY : integer) : TPoint;
    function SnapToGrid( value : integer ) : integer;
    procedure SnapCircleToGrid( var Centre : TPoint; Radius : integer );
    procedure PullCellInsideBoard( var Cell : TPoint );
    function DragAtGrid( value : integer ) : integer;
    function StripFollowMouse(
        Strip : TteStrip; MouseX_D, MouseY_D : integer ) : boolean;
    function SegmentFollowMouse(
        Segment : TteSegment; MouseX_D, MouseY_D : integer ) : boolean;


    // keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure ArrowMoveSelected( Direction : TveArrowMove );
    procedure DeleteSelectedItems;
    procedure SelectAll;

    // message handlers
    procedure WMGetDlgCode(var message: TMessage); message WM_GETDLGCODE;

    // Canvas, Pen, Brush
    procedure SetCanvasUnselected;
    procedure SetCanvasSelected;
    procedure SetCanvasXORTrack;
    procedure SetCanvasXORRectangle;
    procedure CanvasSettingsToPainter;

    // Painting
    procedure PaintSelected;
    procedure PaintTrack( Track : TteTrack );
    procedure PaintRect( RectDivs : TRect );

    //
    procedure MakeDirty;
    function GetDirty : boolean;
    procedure SetDirty( Value : boolean );

    // property
    function GetPixelsPerCell : integer;
    procedure SetPixelsPerCell( Value : integer );

    procedure SetEditMode( Mode : TteEditMode );

  public
    // segment drawing settings
    SegmentWidth_D : integer;
    SnapGrid_D : integer;
    ConstrainedSegments : boolean;


    // events
    property OnMouseMove : TteMouseMove read FOnMouseMove write FOnMouseMove;
{
    property OnMouseClickItem : TMouseClickItem
        read FOnMouseClickItem write FOnMouseClickItem;
}

    property OnChangeMode : TteEditorModeChange read FOnChangeMode write FOnChangeMode;
    property EditMode : TteEditMode read FEditMode write SetEditMode;

    property Dirty : boolean read GetDirty write SetDirty;

    // display colors
    property StripColor : TColor read FStripColor write FStripColor;
    property BoardColor : TColor read FBoardColor write FBoardColor;
    property SelectionColor : TColor read FSelectionColor write FSelectionColor;

    // editing mode variables
//    property EditMode : TbeEditMode read FEditMode write SetEditMode;
    property PixelsPerCell : integer read GetPixelsPerCell write SetPixelsPerCell;
    property DrawLineWidth : integer read FDrawLineWidth write FDrawLineWidth;

    procedure LoadFromBoard( Board : TbrBoard );
    procedure SaveToBoard( Board : TbrBoard );


    procedure Paint; override;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
end;

implementation

uses Forms, SysUtils, Math, Rectangles, ClipbrdTracks;

const
    DIVS_PER_CELL = 1000;
    DIVS_PER_HALF_CELL = 500;


{ Found this:
http://stackoverflow.com/questions/6363954/best-way-to-do-non-flickering-segmented-graphics-updates-in-delphi
}
// ***********************************************
//        INITIALISATION & FINALISATION
// ***********************************************
constructor TteTrackEditor.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
    // csOpaque means the control completely fills its client rectangle.
//    ControlStyle := ControlStyle + [csOpaque];

    Tracks := TbeTracks.Create;
    Painter := TteTrackEditPainter.Create;
    SegmentPropertiesForm := TSegmentPropertiesForm.Create( self );
//    SegmentPropertiesForm.Parent := self;

    //..scroll border is a little bit of "extra scroll" that lets user see
    // a small blank area around the board edge. 4 pixels at 96 ppi resolution.
    ScrollBorder := Screen.PixelsPerInch div 10;

    // initialise color scheme here
    FStripColor := clBlack;
    FSelectionColor := clRed;
    FBoardColor := clWhite;

    SegmentWidth_D := 250;
    SnapGrid_D := 500;
end;

destructor TteTrackEditor.Destroy;
begin
    Painter.Free;
    Tracks.Free;
    inherited;
end;

procedure TteTrackEditor.CreateParams(var Params: TCreateParams);
begin
    inherited CreateParams(Params);
    Params.Style := Params.Style or WS_VSCROLL or WS_HSCROLL {or WS_BORDER};
end;

// Handle a Windows Message to request arrow key messages sent to this
// TWinControl as well as ordinary key messages
procedure TteTrackEditor.WMGetDlgCode(var message: TMessage);
begin
{
Remy Lebeau : I call the base class handler first, so that it can assign default
settings, to which you are then simply adding DLGC_WANTARROWS.
TCustomControl::Dispatch(&AMsg);
AMsg.Result |= DLGC_WANTARROWS;
}
    message.Result := DLGC_WANTARROWS;
end;

procedure TteTrackEditor.LoadFromBoard( Board : TbrBoard );
begin
    Tracks.LoadFromBoard( Board );
    Recalculate; // << thia should be somewhere else
end;

procedure TteTrackEditor.SaveToBoard( Board : TbrBoard );
begin
    Tracks.SaveToBoard( Board );
end;

// *******************************************
//            PROPERTY HANDLERS
// *******************************************

// ****** GET / SET DISPLAY SCALE ******

function TteTrackEditor.GetPixelsPerCell : integer;
begin
    result := Painter.PixelsPerCell;
end;

const
    MAX_PIXELS_PER_CELL = 40;
    MIN_PIXELS_PER_CELL = 4;

procedure TteTrackEditor.SetPixelsPerCell( Value : integer );
begin
    if Value > MAX_PIXELS_PER_CELL then begin
        Value := MAX_PIXELS_PER_CELL;
    end
    else if Value < MIN_PIXELS_PER_CELL then begin
        Value := MIN_PIXELS_PER_CELL;
    end;
    //FPixelsPerCell := Value;
    Painter.PixelsPerCell := Value;

    Recalculate;
end;

procedure TteTrackEditor.SetEditMode( Mode : TteEditMode );
//const
//    ModeToShape : array[TbeEditMode]  of TcCursorShape =
//        ( bmSelect, bmStrip, bmSegment );
begin
    FEditMode := Mode;
    if Mode = bmSelect then begin
        Cursor := crDefault;
    end;
{
    else begin
        Cursor := CursorMinder.GetCursor( ModeToShape[Mode] );
    end;
}
    // raise event
    if assigned( FOnChangeMode ) then begin
        FOnChangeMode( self, Mode );
    end;
end;
{
const
    ModeToShape : array[TCmoEditMode]  of TcCursorShape =
        ( csSelect, csLine, csPin );
begin
    FEditMode := Mode;
    if Mode = emSelect then begin
        Cursor := crDefault;
    end
    else begin
        Cursor := CursorMinder.GetCursor( ModeToShape[Mode] );
    end;

    // raise event
    if assigned( FOnChangeMode ) then begin
        FOnChangeMode( self, Mode );
    end;
}

// **************************************************
//                  SCROLLING
// **************************************************

// *** POSITION HORIZONTAL SCROLLBAR ***

procedure TteTrackEditor.SetHorzScroll;
var
    ScrollInfo : TScrollInfo;
    LeftScroll, RightScroll : integer;
begin
    // At full left scroll, screen left shows -0.5 minus a little bit extra
    LeftScroll := -(PixelsPerCell div 2) - ScrollBorder;

    // At full right scroll, screen right shows board right plus a little
    RightScroll := BoardWidthScreenPixels + Scrollborder - ClientWidth;

    if LeftX < LeftScroll then begin
        LeftX := LeftScroll;
    end
    else if LeftX > RightScroll then begin
        LeftX := RightScroll;
    end;

    // if whole board will fit on screen, scroll to left
    if BoardWidthScreenPixels + Scrollborder + Scrollborder <= ClientWidth then begin
        LeftX := LeftScroll;
    end;

    ScrollInfo.cbSize := sizeof(TScrollInfo);
    ScrollInfo.fMask := SIF_POS or SIF_RANGE or SIF_PAGE;
    ScrollInfo.nMin := LeftScroll;
    ScrollInfo.nMax := BoardWidthScreenPixels + ScrollBorder;
    ScrollInfo.nPage := ClientWidth;
    ScrollInfo.nPos := LeftX;
    ScrollInfo.nTrackPos := 0;

    SetScrollInfo( handle, SB_HORZ, ScrollInfo, TRUE );
end;

// *** POSITION VERTICAL SCROLLBAR ***

procedure TteTrackEditor.SetVertScroll;
var
    ScrollInfo : TScrollInfo;
    UpScroll, DownScroll : integer;
begin
    // At full up scroll, screen top shows -0.5 minus a little bit extra
    UpScroll := -(PixelsPerCell div 2) - ScrollBorder;

    // At full right scroll, screen right shows board right plus a little
    DownScroll := BoardHeightScreenPixels + Scrollborder - ClientHeight;

    if TopY < UpScroll then begin
        TopY := UpScroll;
    end
    else if TopY > DownScroll then begin
        TopY := DownScroll;
    end;

    // if whole board will fit on screen, scroll up
    if BoardHeightScreenPixels + Scrollborder + Scrollborder <= ClientHeight then begin
        TopY := UpScroll;
    end;

    ScrollInfo.cbSize := sizeof(TScrollInfo);
    ScrollInfo.fMask := SIF_POS or SIF_RANGE or SIF_PAGE;
    ScrollInfo.nMin := UpScroll;
    ScrollInfo.nMax := BoardHeightScreenPixels + ScrollBorder;
    ScrollInfo.nPage := ClientHeight;
    ScrollInfo.nPos := TopY;
    ScrollInfo.nTrackPos := 0;

    SetScrollInfo( handle, SB_VERT, ScrollInfo, TRUE );
end;



procedure TteTrackEditor.WMVScroll(var Msg: TWMVScroll);
begin
    case Msg.ScrollCode of

        // SB_THUMBPOSITION updates when mouse released after moving scrollbar
        SB_THUMBPOSITION {, SB_THUMBTRACK} : begin
            TopY := Msg.Pos;
        end;
        // SB_THUMBTRACK gives continuous tracking
        SB_THUMBTRACK : begin
            ScrollWindowEx( handle, 0, TopY - Msg.Pos, nil, nil, 0, nil, SW_INVALIDATE);
//            ScrollWindowEx( handle, 0, TopY - Msg.Pos, nil, nil, 0, nil, 0 );
            TopY := Msg.Pos;
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

    SetVertScroll;
    InvalidateRect( handle, ClientRect, False );
//    PostMessage(hwnd, WM_MYMESSAGE, 0, 0);
end;

procedure TteTrackEditor.WMHScroll(var Msg: TWMHScroll);
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

    SetHorzScroll;
    InvalidateRect( handle, ClientRect, False );
end;

// Window resized

procedure TteTrackEditor.Resize;
begin
    Recalculate;
end;


procedure TteTrackEditor.Recalculate;
begin
    BoardHeightScreenPixels := Tracks.Height * PixelsPerCell;
    BoardWidthScreenPixels := Tracks.Width * PixelsPerCell;

    SetVertScroll;
    SetHorzScroll;
end;


// Tell Windows not to erase backgroud - we will do it.
// GDI calls this Preview first displays, and when resizing the window
// Can't see any visible difference whether we do this or not.
procedure TteTrackEditor.EraseBackground(var Msg: TWMEraseBkgnd);
begin
    // tell Windows we have handled background drawing
    Msg.Result := 1;
end;

// **********************************************
//               DIRTY (ALTERED)
// **********************************************

procedure TteTrackEditor.MakeDirty;
begin
    Tracks.Dirty := True;
end;

function TteTrackEditor.GetDirty : boolean;
begin
    result := Tracks.Dirty;
end;

procedure TteTrackEditor.SetDirty( Value : boolean );
begin
    Tracks.Dirty := Value;
end;


// **********************************************
//                  KEYBOARD
// **********************************************

procedure TteTrackEditor.KeyDown(var Key: Word; Shift: TShiftState);
begin
    if Key = VK_LEFT then begin
        ArrowMoveSelected( amLeft );
        Key := 0;
    end
    else if KEY = VK_UP then begin
        ArrowMoveSelected( amUp );
        Key := 0;
    end
    else if KEY = VK_RIGHT then begin
        ArrowMoveSelected( amRight );
        Key := 0;
    end
    else if KEY = VK_DOWN then begin
        ArrowMoveSelected( amDown );
        Key := 0;
    end
    else if Key = VK_DELETE then begin
         DeleteSelectedItems;
    end
    else if Key = VK_ESCAPE then begin
        EditMode := bmSelect;
    end;
end;

procedure TteTrackEditor.KeyPress(var Key: Char);
const
    // WM_CHAR messages come through to TWinControl.KeyPress
    // Windows encodes Ctrl Key in combination with a letter key
    // as a WM_CHAR key containing standard ASCII control characters
    // which range from 0x01 (Ctrl-A), Ox02 (Ctrl-B), through 0x1A (Ctrl-Z)
    CTRL_A = char(1);   // Select All
    CTRL_C = char(3);   // Copy
    CTRL_V = char($16); // Paste
    CTRL_X = char($18); // Cut
    CTRL_Z = char($1A); // Undo
    CTRL_Y = char($19); // Redo
begin
    case Key of
        CTRL_A : SelectAll;
        CTRL_C : CopySelectedTracksToClipboard( Tracks );
        CTRL_V : begin
            SetCanvasUnselected;
            PaintSelected;
            PasteTracksFromClipboard( Tracks );
            SetCanvasSelected;
            PaintSelected;
        end;
        CTRL_Z : begin
            Tracks.Undo;
            Paint;
        end;
        CTRL_Y : begin
            Tracks.Redo;
            Paint;
        end;
    end;
end;

// Select All Tracks
procedure TteTrackEditor.SelectAll;
begin
    Tracks.SelectAll;
    SetCanvasSelected;
    PaintSelected;
end;


// ** Move Selected Items in Requested Direction **

// NOTE: based on TveEditor.ArrowMoveSelected() in Editor.pas - refer
// to that functn. for Undo & Screen refresh code.

procedure TteTrackEditor.ArrowMoveSelected( Direction : TveArrowMove );
var
    SelectedCount : integer;
    BoardRect : TRect;
    ItemsBoundarySource_D : TRect;
    Delta_D : integer;
    deltaX, deltaY : integer;
begin
    // must have something selected!
    SelectedCount := Tracks.GetSelectedCount;
    if SelectedCount <= 0 then begin
        exit;
    end;

    // get rectangle of board area
    BoardRect := Tracks.BoardRect_D;

    // get rectangle enclosing selected items
    ItemsBoundarySource_D := Tracks.GetSelectedItemsBoundary_D;

    // work out how far to move the selected items
    //.. If any strips in selection, only move by whole cells
    if Tracks.GetSelectedTypeCount( TteStrip ) > 0 then begin
        Delta_D := DIVS_PER_CELL;
    end
    // else move by snap
    else begin
        Delta_D := SnapGrid_D;
    end;

    // see if rectangle can be moved 1 in desired direction
    // This code assumes we do not move in both x and y directions!
    case Direction of
        amRight : begin
            if ItemsBoundarySource_D.BottomRight.x + Delta_D > BoardRect.Right then begin
                exit;
            end;
            deltaX := Delta_D;
            deltaY := 0;
        end;
        amLeft : begin
            if (ItemsBoundarySource_D.TopLeft.x - Delta_D) < BoardRect.Left then begin
                exit;
            end;
            deltaX := -Delta_D;
            deltaY := 0;
        end;
        amDown : begin
            if ItemsBoundarySource_D.BottomRight.y + Delta_D > BoardRect.Bottom then begin
                exit;
            end;
            deltaX := 0;
            deltaY := Delta_D;
        end;
        amUp : begin
            if ItemsBoundarySource_D.TopLeft.y - Delta_D < BoardRect.Top then begin
                exit;
            end;
            deltaX := 0;
            deltaY := -Delta_D;
        end
        else begin
            exit;
        end;
    end;

    // move items
    Tracks.SnapshotSelectedItems;
    Tracks.MoveSelectedItems_D( deltaX, deltaY );
    Tracks.StoreSnaphotSelectedAsUndo;

    // redraw source area to clean up
    PaintRect( ItemsBoundarySource_D );

    // redraw items in new position - most of these items were probably redrawn
    // in code line above, since they continue to overlap the source area
    SetCanvasSelected;
    PaintSelected;
    MakeDirty;
end;

procedure TteTrackEditor.DeleteSelectedItems;
begin
    Tracks.DeleteSelectedItemsWithUndo;
    // now show the changes
    Paint;
    MakeDirty;
end;

// **********************************************
//                SNAP GRID & DRAG GRID
// **********************************************

// Pull A Coordinate or Displacement in DIVS to snap grid
function TteTrackEditor.SnapToGrid( value : integer ) : integer;
begin
    result := SnapGrid_D * Round( value / SnapGrid_D );
end;

// Pull a circle to snap grid inside the board boundaries
procedure TteTrackEditor.SnapCircleToGrid( var Centre : TPoint; Radius : integer );
var
    BoardRect : TRect;
    LeftLimit_D, RightLimit_D : integer;
    TopLimit_D, BottomLimit_D : integer;
begin
    // get rectangle of board area
    BoardRect := Tracks.BoardRect_D;

    // *** HANDLE X COORD
    LeftLimit_D := BoardRect.Left + Radius;
    RightLimit_D := BoardRect.Right - Radius;

    // pull X coord onto board
    if Centre.X > RightLimit_D then begin
        Centre.X := RightLimit_D;
    end
    else if Centre.X < LeftLimit_D then begin
        Centre.x := LeftLimit_D;
    end;

    // snap X coord
    Centre.X := SnapGrid_D * Round( Centre.X / SnapGrid_D );

    // if X coord snapped outside the board, pull it back
    if Centre.X > RightLimit_D then begin
        dec( Centre.X, SnapGrid_D );
    end
    else if Centre.X < LeftLimit_D then begin
        inc( Centre.X, SnapGrid_D );
    end;


    // *** HANDLE Y COORD
    TopLimit_D := BoardRect.Top + Radius;
    BottomLimit_D := BoardRect.Bottom - Radius;

    // pull Y coord onto board
    if Centre.Y > BottomLimit_D then begin
        Centre.Y := BottomLimit_D;
    end
    else if Centre.Y < TopLimit_D then begin
        Centre.Y := TopLimit_D;
    end;

    // snap Y coord
    Centre.Y := SnapGrid_D * Round( Centre.Y / SnapGrid_D );

    // if Y coord snapped outside the board, pull it back
    if Centre.Y > BottomLimit_D then begin
        dec( Centre.Y, SnapGrid_D );
    end
    else if Centre.Y < LeftLimit_D then begin
        inc( Centre.Y, SnapGrid_D );
    end;
end;


// Pull A Coordinate in DIVS to drag grid
function TteTrackEditor.DragAtGrid( value : integer ) : integer;
begin
    result := DragGrid_1000 * Round( value / DragGrid_1000 );
end;

// Pull Cell Coords Inside Board Edges
procedure TteTrackEditor.PullCellInsideBoard( var Cell : TPoint );
begin
    Cell.X := Max( Cell.X, 0 );
    Cell.X := Min( Cell.X, Tracks.Width -1 );
    Cell.Y := Max( Cell.Y, 0 );
    Cell.Y := Min( Cell.Y, Tracks.Height -1 );
end;

// **********************************************
//              STRIP & SEGMENT PLACING
// **********************************************

// Make the strip finish follow the mouse - return TRUE if strip finish moved
function TteTrackEditor.StripFollowMouse(
    Strip : TteStrip; MouseX_D, MouseY_D : integer ) : boolean;
var
    DeltaX_D, DeltaY_D : integer;
    TempPoint : TPoint;
begin
    // how far mouse is from Strip.Start
    DeltaX_D := MouseX_D - (Strip.Start.X * DIVS_PER_CELL);
    DeltaY_D := MouseY_D - (Strip.Start.Y * DIVS_PER_CELL);

    // work out if we have a horizontal strip or vertical and calculate
    // new strip Finish coords (leave Start Coords unchanged)
    // We add DIVS_PER_HALF_CELL to get rounding of the integer division result

    // if horizontal
    if abs( DeltaX_D ) > abs( DeltaY_D ) then begin
        TempPoint.X := Strip.Start.X + Round( DeltaX_D / DIVS_PER_CELL );
        TempPoint.Y := Strip.Start.Y;

        // keep strip within board boundaries
        if TempPoint.X < 0 then begin
            TempPoint.X := 1;
        end
        else if TempPoint.X >= Tracks.Width then begin
            TempPoint.X := Tracks.Width -1;
        end;
    end
    // else vertical
    else begin
        TempPoint.X := Strip.Start.X;
        TempPoint.Y := Strip.Start.Y + Round( DeltaY_D / DIVS_PER_CELL );

        // keep strip within board boundaries
        if TempPoint.Y < 0 then begin
            TempPoint.Y := 1;
        end
        else if TempPoint.Y >= Tracks.Height then begin
            TempPoint.Y := Tracks.Height -1;
        end;
    end;

    // work out return value - TRUE = changed
    result := (TempPoint.X <> Strip.Finish.X) or (TempPoint.Y <> Strip.Finish.Y);

    // move changes into the strip
    Strip.Finish := TempPoint;
end;


// Make the segment follow the mouse - return TRUE if segment finish moved
function TteTrackEditor.SegmentFollowMouse(
    Segment : TteSegment; MouseX_D, MouseY_D : integer ) : boolean;
var
    DeltaX_D, DeltaY_D : integer;
    TempPoint : TPoint;
    MagDx, MagDy : integer;
    TrackDelta_DIV : integer;
const
    // 100 * tan(22.5 degrees)
    tan22p5x100 = 41;
begin
    // how far mouse is from Segment.Start
    DeltaX_D := MouseX_D - Segment.Start_1000.X;
    DeltaY_D := MouseY_D - Segment.Start_1000.Y;

    // zero length
    if (DeltaX_D = 0) and (DeltaY_D = 0) then begin
        TempPoint.X := Segment.Start_1000.X;
        TempPoint.Y := Segment.Start_1000.Y;
    end

    // UNCONSTRAINED SEGMENTS CODE - SEGEMENTS AT ANY ANGLE
    else if not ConstrainedSegments then begin
        TempPoint.X := Segment.Start_1000.X + DeltaX_D;
        TempPoint.Y := Segment.Start_1000.Y + DeltaY_D;
        SnapCircleToGrid( TempPoint, Segment.Width_1000 div 2 );
    end

    // CONSTRAINED SEGMENTS CODE - SEGEMENTS AT 45 DEGREE INCREMENTS
    else begin
        // calculate some useful values
        MagDx := abs( DeltaX_D );
        MagDy := abs( DeltaY_D );

        // if vertical (mouse at less than 22.5 degrees from the vertical
        if (MagDy > 0) and (((MagDx * 100) div MagDy) < tan22p5x100) then begin
            // do vertical
            TempPoint.x := Segment.Start_1000.X;
            TempPoint.y := Segment.Start_1000.Y + DeltaY_D;
            SnapCircleToGrid( TempPoint, Segment.Width_1000 div 2 );
        end

        // if horizontal (mouse at less than 22.5 degrees the horizontal
        else if (MagDx > 0) and (((MagDy * 100) div MagDx) < tan22p5x100) then begin
            // do horizontal
            TempPoint.x := Segment.Start_1000.X + DeltaX_D;
            TempPoint.y := Segment.Start_1000.Y;
            SnapCircleToGrid( TempPoint, Segment.Width_1000 div 2 );
        end

        // at this point in code, our line is not vertical or horizontal, so it
        // must be either 45 / 225 degrees or 135 / 315 degrees.
        // Note: Tests in the lines above ensure that neither dX or dY is zero
        // at this point in the code. So no divide by zero errors!

        // if 45 / 225 degrees
        else if (DeltaY_D / DeltaX_D) > 0 then begin
            // do 45 / 225 degrees, where deltaX = deltaY : both positive or negative

            // calculate deltaX_div as average of the two - in grid multiple
            TrackDelta_DIV := SnapToGrid((DeltaX_D + DeltaY_D) DIV 2);
            TempPoint.x := Segment.Start_1000.X + TrackDelta_DIV;
            TempPoint.y := Segment.Start_1000.Y + TrackDelta_DIV;

            // snap to a grid point far enough inside the board so that
            // segment radius is entirely inside the board
            SnapCircleToGrid( TempPoint, Segment.Width_1000 div 2 );

            // in case Snap moved X or Y, make deltaX=deltaY again
            if abs(TempPoint.X - Segment.Start_1000.X) <
                abs(TempPoint.Y - Segment.Start_1000.Y) then begin
                 TempPoint.Y := Segment.Start_1000.Y +
                    (TempPoint.X - Segment.Start_1000.X);
            end
            else if abs(TempPoint.X - Segment.Start_1000.X) >
                abs(TempPoint.Y - Segment.Start_1000.Y) then begin
                 TempPoint.X := Segment.Start_1000.X +
                    (TempPoint.Y - Segment.Start_1000.Y);
            end;
        end

        // else 135 / 315 degrees
        else begin
            // do 135 / 315 degrees, where deltaX = -(deltaY) : opposite sign
            //.. this could be positive or negative
            TrackDelta_DIV := SnapToGrid((DeltaX_D - DeltaY_D) DIV 2);
            TempPoint.x := Segment.Start_1000.X + TrackDelta_DIV;
            TempPoint.y := Segment.Start_1000.Y - TrackDelta_DIV;

            SnapCircleToGrid( TempPoint, Segment.Width_1000 div 2 );

            // in case Snap moved X or Y, make deltaX=-deltaY again
            if abs(TempPoint.X - Segment.Start_1000.X) <
                abs(TempPoint.Y - Segment.Start_1000.Y) then begin
                 TempPoint.Y := Segment.Start_1000.Y -
                    (TempPoint.X - Segment.Start_1000.X);
            end
            else if abs(TempPoint.X - Segment.Start_1000.X) >
                abs(TempPoint.Y - Segment.Start_1000.Y) then begin
                 TempPoint.X := Segment.Start_1000.X -
                    (TempPoint.Y - Segment.Start_1000.Y);
            end;
        end;
    end;

    // work out return value - TRUE = changed
    result := (TempPoint.X <> Segment.Finish_1000.X) or
              (TempPoint.Y <> Segment.Finish_1000.Y);

    // move changes into the strip
    Segment.Finish_1000 := TempPoint;
end;


// **********************************************
//                  MOUSE
// **********************************************

procedure TteTrackEditor.MouseDown(Button: TMouseButton; Shift: TShiftState;
    X, Y: Integer);
var
    ClickedItem : TteTrack;

procedure SetDragGrid;
begin
    // work out whether fine movement is possible - or only coarse
    if (ClickedItem is TteStrip) or (Tracks.GetSelectedTypeCount( TteStrip ) > 0) then begin
        DragGrid_1000 := DIVS_PER_CELL;
    end
    else begin
        DragGrid_1000 := SnapGrid_D;
    end;
end;

var
    TempPoint : TPoint;

begin
    // focus makes this control receive keyboard input
    if CanFocus then begin
        SetFocus;
    end;

    // Find where on the board we clicked
    MouseDownCellCoords := ClickxyToCells( X, Y );
    MouseDownCellCoords_D := ClickxyToCells_D( X, Y );

    // Find the track clicked on
    ClickedItem := Tracks.ClickedItem( MouseDownCellCoords );

    // *********************************
    // *** Right click returns to bmSelect ****
    // *********************************

    // if right click
    if Button = mbRight then begin

        EditMode := bmSelect;

        // if a segment is under the mouse, show right click menu
        if ClickedItem is TteSegment then begin

           // remove existing selection
            DrawMode := dmNormal;
            PaintSelected;
            Tracks.ClearSelectedItems;

            // Select new item
            DrawMode := dmSelected;
            PaintTrack( ClickedItem );
            ClickedItem.Selected := True;

            // record original segment rectangle
            ClickSelectedItemsRect_D := ClickedItem.GetPaintRect_D;

            // show segment properties form and let user change start, end, width
            SegmentPropertiesForm.Segment := TteSegment( ClickedItem );
            SegmentPropertiesForm.BoardRect_D := Tracks.BoardRect_D;
            SegmentPropertiesForm.ShowModal;

            // repaint area containing both original and edited segment
            ExtendRectangle( ClickSelectedItemsRect_D, ClickedItem.GetPaintRect_D );
            PaintRect( ClickSelectedItemsRect_D );

            MakeDirty;
        end;

        // finished
        MouseMoveTask := mtNone;
        exit;
    end;


    // *********************************
    // *** edit mode = bmStrip     ****
    // *********************************
    if EditMode = bmStrip then begin

        // create new strip
        DrawStrip := Tracks.AddNewStrip;
        DrawStrip.Selected := False;

        // set strip to single cell - in whole cell coords
        TempPoint.X := Round( MouseDownCellCoords.x );
        TempPoint.Y := Round( MouseDownCellCoords.y );
        PullCellInsideBoard( TempPoint );
        DrawStrip.Start := TempPoint;
        DrawStrip.Finish := TempPoint;

        // prepare for XOR image to follow mouse
        SetCanvasXORTrack;
        PaintTrack( DrawStrip );

        MouseMoveTask := mtDrawStrip;

        // no other repaint
        exit;
    end

    // *********************************
    // *** edit mode = bmSegment   ****
    // *********************************
    else if EditMode = bmSegment then begin

        // create new segment
        DrawSegment := Tracks.AddNewSegment;
        DrawSegment.Selected := False;
        DrawSegment.Width_1000 := SegmentWidth_D;

        // set segment to zero length at mouse position
        TempPoint.X := MouseDownCellCoords_D.X;
        TempPoint.Y := MouseDownCellCoords_D.Y;
        SnapCircleToGrid( TempPoint, SegmentWidth_D div 2 );
        DrawSegment.Start_1000 := TempPoint;
        DrawSegment.Finish_1000 := TempPoint;

        // prepare for XOR image to follow mouse
        SetCanvasXORTrack;
        PaintTrack( DrawSegment );

        MouseMoveTask := mtDrawSegment;

        // no other repaint
        exit;
    end

    // *********************************
    // *** edit mode = bmDonut   ****
    // *********************************
    else if EditMode = bmDonut then begin

        // MouseMoveTask := mtDrawSegment;  ?? DrawDonut?

    end
    else begin

        // *********************************
        // *** edit mode = bmSelect ****
        // *********************************

        // *** if SHIFT key is down - means size a track or drag one end of a track ***
        if ssShift in Shift then begin

            // Clear all selected items - SHIFT-DRAG will act only on one track
            DrawMode := dmNormal;
            PaintSelected;
            Tracks.ClearSelectedItems;

            // Find the track under the mouse and make it selected.
            if ClickedItem <> nil then begin

                // item should show as selected after end is dragged
                ClickedItem.Selected := True;

                // record the item paint rectangle before movement in cell units
                ClickSelectedItemsRect_D := ClickedItem.GetPaintRect_D;

                // if we have a strip, drag the end of it
                if ClickedItem is TteStrip then begin

                    // we will be altering this strip during time mouse stays down
                    DrawStrip := TteStrip( ClickedItem );

                    // get ClickedItem.Finish to be the end nearest nearest mouse
                    DrawStrip.MakeFinishNearestPoint( MouseDownCellCoords );

                    // move strip end to be near mouse, depending on free/45 degree
                    // angle mode
                    StripFollowMouse( DrawStrip,
                        MouseDownCellCoords_D.X, MouseDownCellCoords_D.Y );

                    // prepare for XOR image to follow mouse
                    SetCanvasXORTrack;
                    PaintTrack( DrawStrip );

                    MouseMoveTask := mtDragEndStrip;

                    // record for undo
                    DrawStrip.TakeSnapshot;

                    // no other repaint
                    exit;
                end
                else if ClickedItem is TteSegment then begin

                    // we will be altering this segment during time mouse stays down
                    DrawSegment := TteSegment( ClickedItem );

                    // get ClickedItem.Finish to be the end nearest nearest mouse
                    DrawSegment.MakeFinishNearestPoint( MouseDownCellCoords );

                    // move strip end to be near mouse, depending on free/45 degree
                    // angle mode
                    SegmentFollowMouse( DrawSegment,
                        MouseDownCellCoords_D.X, MouseDownCellCoords_D.Y );

                    // prepare for XOR image to follow mouse
                    SetCanvasXORTrack;
                    PaintTrack( DrawSegment );

                    MouseMoveTask := mtDragEndSegment;

                    // record for undo
                    DrawSegment.TakeSnapshot;

                    // no other repaint
                    exit;
                end
            end;
        end

        // if nothing clicked on
        else if ClickedItem = nil then begin

            // if Ctrl not down, empty selection
            if not (ssCtrl in Shift) then begin
                SetCanvasUnselected;
                PaintSelected;
                Tracks.ClearSelectedItems;
            end;

            // prepare to draw selection rectangle when mouse moves
            SetCanvasXORRectangle;

            // record where we started  ??
            ClickOriginalClient.X := X;
            ClickOriginalClient.Y := Y;

            // initialise selection rectangle in screen units
            SelectionClientRect.Left := X;
            SelectionClientRect.Top := Y;
            SelectionClientRect.Right := X;
            SelectionClientRect.Bottom := Y;

            MouseMoveTask := mtDrawSelectionRectangle;
            // don't do paint
            exit;
        end

         // at this point we have an item under the mouse ClickedItem

        // *** if CTRL key is down ***
        else if ssCTRL in Shift then begin

            // Invert the selection of the item under the mouse
            if ClickedItem <> nil then begin

                if ClickedItem.Selected then begin
                    ClickedItem.Selected := False;
                    DrawMode := dmNormal;
                end
                else begin
                    ClickedItem.Selected := True;
                    DrawMode := dmSelected;
                end;

                // redraw the clicked item
                PaintTrack( ClickedItem );
            end;

            // Enter “None” mode – no dragging to follow.
            MouseMoveTask := mtNone;

            // no other repaints
            exit;
        end

        // else we are clicking on a track or tracks, in anticipation that
        // they will be dragged by the mouse
        else begin
            // work out how much the drag grid will be (movement increment)
            SetDragGrid;

            // If one of the items under the mouse is already selected, then
            // enter the DragTracks mode. Don't add anything to the selection
            if Tracks.SelectedTracksUnderMouse( MouseDownCellCoords ) then begin

                // Set up for drag
                MouseMoveTask := mtMoveSelected;
                SetCanvasXORTrack;

                // record the border of the selected items
                ClickSelectedItemsRect_D := Tracks.GetSelectedItemsBoundary_D;
            end

            // else item under the mouse is not selected, so select that one item
            // and prepare for it to be dragged
            // select the item under the mouse for dragging
            else begin
                // remove existing selection
                DrawMode := dmNormal;
                PaintSelected;
                Tracks.ClearSelectedItems;
                // Select new item
                DrawMode := dmSelected;
                PaintTrack( ClickedItem );
                ClickedItem.Selected := True;

                // set up for drag
                MouseMoveTask := mtMoveSelected;
                SetCanvasXORTrack;

                // record the border of the selected item
                ClickSelectedItemsRect_D := Tracks.GetSelectedItemsBoundary_D;
            end;
            // record for undo
            Tracks.SnapshotSelectedItems;

            // distance we have moved from mouse down
            LastDeltaXCells_D := 0;
            LastDeltaYCells_D := 0;
        end;
    end;
end;



procedure TteTrackEditor.MouseMove(Shift: TShiftState; X, Y: Integer);
var
    MouseMoveCellCoords_D : TPoint;
    DeltaXCells_D, DeltaYCells_D : integer;
    BoardRect_D : TRect;
    LatestMoveX, LatestMoveY : integer;

const
    // 100 * tan(22.5 degrees)
    tan22p5x100 = 41;

begin
    // Find where on the board is the mouse in DIVS
    MouseMoveCellCoords_D := ClickxyToCells_D( X, Y );

    // mouse move event
    if assigned( FOnMouseMove ) then begin
        FOnMouseMove(
            SnapToGrid( MouseMoveCellCoords_D.X ),
            SnapToGrid( MouseMoveCellCoords_D.Y ) );
    end;

    // Nothing was started by a mouse down? then exit
    if MouseMoveTask = mtNone then begin
        exit;
    end;

    // find total distance mouse has moved since it went down in DIVS
    DeltaXCells_D := MouseMoveCellCoords_D.x - MouseDownCellCoords_D.x;
    DeltaYCells_D := MouseMoveCellCoords_D.y - MouseDownCellCoords_D.y;

    // get boundaries of the board
    BoardRect_D := Tracks.BoardRect_D;

    if MouseMoveTask = mtDrawSelectionRectangle then begin

        // XOR draw over previous selection rectangle
        Canvas.MoveTo( SelectionClientRect.Left, SelectionClientRect.Top );
        Canvas.LineTo( SelectionClientRect.Right, SelectionClientRect.Top );
        Canvas.LineTo( SelectionClientRect.Right, SelectionClientRect.Bottom );
        Canvas.LineTo( SelectionClientRect.Left, SelectionClientRect.Bottom );
        Canvas.LineTo( SelectionClientRect.Left, SelectionClientRect.Top );

        // adjust rectangle to new mouse position
        SelectionClientRect.Right := X;
        SelectionClientRect.Bottom := Y;

        // XOR draw latest selection rectangle
        Canvas.MoveTo( SelectionClientRect.Left, SelectionClientRect.Top );
        Canvas.LineTo( SelectionClientRect.Right, SelectionClientRect.Top );
        Canvas.LineTo( SelectionClientRect.Right, SelectionClientRect.Bottom );
        Canvas.LineTo( SelectionClientRect.Left, SelectionClientRect.Bottom );
        Canvas.LineTo( SelectionClientRect.Left, SelectionClientRect.Top );
    end

    else if MouseMoveTask = mtDrawStrip then begin

        // XOR paint strip at old location to remove it
        PaintTrack( DrawStrip );

        // move strip end to be near mouse, depending on free/45 degree
        // angle mode
        StripFollowMouse( DrawStrip, MouseMoveCellCoords_D.x, MouseMoveCellCoords_D.y );

        // draw strip at new location
        PaintTrack( DrawStrip );

        // no other repaint
        exit;
    end

    else if MouseMoveTask = mtDrawSegment then begin

        // XOR paint strip at old location to remove it
        PaintTrack( DrawSegment );

        // move strip end to be near mouse, depending on free/45 degree
        // angle mode
        SegmentFollowMouse( DrawSegment, MouseMoveCellCoords_D.x, MouseMoveCellCoords_D.y );

        // draw strip at new location
        PaintTrack( DrawSegment );

        // no other repaint
        exit;
    end

    else if MouseMoveTask = mtDragEndStrip then begin

        // XOR paint strip at old location to remove it
        PaintTrack( DrawStrip );

        // move strip end to be near mouse, depending on free/45 degree
        // angle mode
        StripFollowMouse( DrawStrip, MouseMoveCellCoords_D.x, MouseMoveCellCoords_D.y );

        // draw strip at new location
        PaintTrack( DrawStrip );

        // no other repaint
        exit;
    end

    else if MouseMoveTask = mtDragEndSegment then begin

        // XOR paint strip at old location to remove it
        PaintTrack( DrawSegment );

        // move strip end to be near mouse, depending on free/45 degree
        // angle mode
        SegmentFollowMouse( DrawSegment, MouseMoveCellCoords_D.x, MouseMoveCellCoords_D.y );

        // draw strip at new location
        PaintTrack( DrawSegment );

        // no other repaint
        exit;
    end

    else if MouseMoveTask = mtMoveSelected then begin

        // limit movement to left
        if ClickSelectedItemsRect_D.TopLeft.x + DeltaXCells_D < BoardRect_D.TopLeft.x then begin
            DeltaXCells_D := BoardRect_D.TopLeft.x - ClickSelectedItemsRect_D.TopLeft.x;
            DeltaXCells_D := DragAtGrid( DeltaXCells_D );
            if ClickSelectedItemsRect_D.TopLeft.x + DeltaXCells_D < BoardRect_D.TopLeft.x then begin
                Inc( DeltaXCells_D, DragGrid_1000 );
            end;
        end;
        // limit movement to right
        if ClickSelectedItemsRect_D.BottomRight.x + DeltaXCells_D > BoardRect_D.BottomRight.x then begin
            DeltaXCells_D := BoardRect_D.BottomRight.x - ClickSelectedItemsRect_D.BottomRight.x;
            DeltaXCells_D := DragAtGrid( DeltaXCells_D );
            if ClickSelectedItemsRect_D.BottomRight.x + DeltaXCells_D > BoardRect_D.BottomRight.x then begin
                Dec( DeltaXCells_D, DragGrid_1000 );
            end;
        end;

        // limit movement to top
        if ClickSelectedItemsRect_D.TopLeft.y + DeltaYCells_D < BoardRect_D.TopLeft.y then begin
            DeltaYCells_D := BoardRect_D.TopLeft.y - ClickSelectedItemsRect_D.TopLeft.y;
            DeltaYCells_D := DragAtGrid( DeltaYCells_D );
            if ClickSelectedItemsRect_D.TopLeft.y + DeltaYCells_D < BoardRect_D.TopLeft.y then begin
                Inc( DeltaYCells_D, DragGrid_1000 );
            end;
        end;

        // limit movement to bottom
        if ClickSelectedItemsRect_D.BottomRight.y + DeltaYCells_D > BoardRect_D.BottomRight.y then begin
            DeltaYCells_D := BoardRect_D.BottomRight.y - ClickSelectedItemsRect_D.BottomRight.y;
            DeltaYCells_D := DragAtGrid( DeltaYCells_D );
            if ClickSelectedItemsRect_D.BottomRight.y + DeltaYCells_D > BoardRect_D.BottomRight.y then begin
                Dec( DeltaYCells_D, DragGrid_1000 );
            end;
        end;

        // snap to grid
        DeltaXCells_D := DragAtGrid( DeltaXCells_D );
        DeltaYCells_D := DragAtGrid( DeltaYCells_D );

        // work out the displacement needed to move the selected components
        // to their new position
        LatestMoveX := DeltaXCells_D - LastDeltaXCells_D;
        LatestMoveY := DeltaYCells_D - LastDeltaYCells_D;

        // if no displacement, do nothing
        if (LatestMoveX = 0) and (LatestMoveY = 0) then begin
            exit;
        end;

        // erase BoardItems at old location
        PaintSelected;

        // move the selected components to the new position
        Tracks.MoveSelectedItems_D( LatestMoveX, LatestMoveY );

        // record distance we have moved from original mouse down
        LastDeltaXCells_D := DeltaXCells_D;
        LastDeltaYCells_D := DeltaYCells_D;

        //show movement
        PaintSelected;
    end;
end;

procedure TteTrackEditor.MouseUp(Button: TMouseButton; Shift: TShiftState;
    X, Y: Integer);
var
    SelectionRect : TAlignedFloatRect;
    ItemPaintRect_D : TRect;

begin
    if MouseMoveTask = mtDrawSelectionRectangle then begin

        // erase rectangle at old old location by XOR drawing
        Canvas.MoveTo( SelectionClientRect.Left, SelectionClientRect.Top );
        Canvas.LineTo( SelectionClientRect.Right, SelectionClientRect.Top );
        Canvas.LineTo( SelectionClientRect.Right, SelectionClientRect.Bottom );
        Canvas.LineTo( SelectionClientRect.Left, SelectionClientRect.Bottom );
        Canvas.LineTo( SelectionClientRect.Left, SelectionClientRect.Top );

        // get rectangle in standard format
        NormalizeRect( SelectionClientRect );

        // convert rectangle to TAlignedFloatRect
        SelectionRect.TopLeft :=
            ClickxyToCells( SelectionClientRect.Left, SelectionClientRect.Top );
        SelectionRect.BottomRight :=
            ClickxyToCells( SelectionClientRect.Right, SelectionClientRect.Bottom );

        // select items inside selection rectangle
        Tracks.SelectInsideRect( SelectionRect );

        // paint selected
        SetCanvasSelected;
        PaintSelected;

        MouseMoveTask := mtNone;
        exit;
    end

    else if MouseMoveTask = mtDrawStrip then begin
        // save for Undo
        Tracks.RegisterNewTrackForUndo(DrawStrip);

        // Redraw Strip
        SetCanvasUnselected;
        PaintTrack( DrawStrip );
        MouseMoveTask := mtNone;
        MakeDirty;
        exit;
    end

    else if MouseMoveTask = mtDrawSegment then begin
        // save for Undo
        Tracks.RegisterNewTrackForUndo(DrawSegment);

        // Redraw Segment
        SetCanvasUnselected;
        PaintTrack( DrawSegment );
        MouseMoveTask := mtNone;
        MakeDirty;
        exit;
    end

    else if MouseMoveTask = mtDragEndStrip then begin

        // make an undo record
        Tracks.StoreSnaphotSelectedAsUndo;

        // repaint the rectangle that contains the strip
        // in both its before-edit and after-edit forms

        // current paint rect of item
        ItemPaintRect_D := DrawStrip.GetPaintRect_D;


        // combine before and after movement rects
        ExtendRectangle( ItemPaintRect_D, ClickSelectedItemsRect_D );

        // stop XOR drawing
        SetCanvasUnselected;
        PaintRect( ItemPaintRect_D );

        MouseMoveTask := mtNone;
        MakeDirty;
        exit;
    end

    else if MouseMoveTask = mtDragEndSegment then begin

        // make an undo record
        Tracks.StoreSnaphotSelectedAsUndo;

        // repaint the rectangle that contains the strip
        // in both its before-edit and after-edit forms

        // current paint rect of item
        ItemPaintRect_D := DrawSegment.GetPaintRect_D;
        // combine before and after movement rects
        ExtendRectangle( ItemPaintRect_D, ClickSelectedItemsRect_D );

        // stop XOR drawing
        SetCanvasUnselected;
        PaintRect( ItemPaintRect_D );

        MouseMoveTask := mtNone;
        MakeDirty;
        exit;
    end

    else if MouseMoveTask = mtMoveSelected then begin
        // erase XOR drawing
        //PaintSelected;

        // make an undo record
        Tracks.StoreSnaphotSelectedAsUndo;

        // paint destination
        SetCanvasSelected;
        PaintSelected;

        // repaint the source rectangle so item is "not there"
        SetCanvasUnselected; //- PaintRect does this automatically
        PaintRect( ClickSelectedItemsRect_D );

        MouseMoveTask := mtNone;
        MakeDirty;
        exit;
    end;
end;


//  ****  MouseClickXY to Cell Coords XY  ****
function TteTrackEditor.ClickxyToCells( ClickX, ClickY : integer ) : TFloatPoint;
begin
    result.x := ((ClickX + LeftX) / PixelsPerCell);
    result.y := ((ClickY + TopY) / PixelsPerCell);
end;

function TteTrackEditor.ClickxyToCells_D( ClickX, ClickY : integer) : TPoint;
var
    FPoint : TFloatPoint;
begin
    FPoint := ClickxyToCells( ClickX, ClickY );
    result.x := round( FPoint.x * DIVS_PER_CELL );
    result.Y := round( FPoint.y * DIVS_PER_CELL );

//    result.x := ((ClickX + LeftX) * DIVS_PER_CELL) div PixelsPerCell;
//    result.y := ((ClickY + TopY) * DIVS_PER_CELL) div PixelsPerCell;
end;

// *****************************************
//       SETUP CANVAS PEN, TEXT, BRUSH
// *****************************************

procedure TteTrackEditor.SetCanvasUnselected;
begin
    DrawMode := dmNormal;
    Canvas.Pen.Mode := pmCopy;
end;

procedure TteTrackEditor.SetCanvasSelected;
begin
    DrawMode := DmSelected;
end;

procedure TteTrackEditor.SetCanvasXORTrack;
begin
    DrawMode := dmXOR;
end;

procedure TteTrackEditor.SetCanvasXORRectangle;
begin
//    Canvas.Pen.Style := psDot;
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Mode := pmXOr;
    Canvas.Pen.Color := clYellow;
    Canvas.Pen.Width := FDrawLineWidth;
//    Canvas.Pen.Width := PixelsPerCell div 4;
    Canvas.Brush.Color := clWhite;
end;

procedure TteTrackEditor.CanvasSettingsToPainter;
begin
    case DrawMode of

      dmNormal: begin
          Painter.StripColor := FStripColor;
          Painter.XOR_Mode := False;
      end;
      dmSelected: begin
          Painter.StripColor := FSelectionColor;
          Painter.XOR_Mode := False;
      end;
      dmXOR: begin
          Painter.StripColor := FSelectionColor;
          Painter.XOR_Mode := True;
      end;

    end;
end;



// ***********************************************
//                 PAINTING
// ***********************************************
// Painting
procedure TteTrackEditor.PaintSelected;
var
    i : integer;
    Track : TteTrack;
begin
    CanvasSettingsToPainter;

    // ** Paint Selected Items
    Painter.Clear;
    for i := 0 to Tracks.Count - 1 do begin
        Track := Tracks[i];
        if Track.Selected then begin
{
            if Track.InsideRect then begin
            end;
}
            Track.Paint( Painter );
        end;
    end;
    Painter.Paint( Canvas );
end;

procedure TteTrackEditor.PaintTrack( Track : TteTrack );
begin
    CanvasSettingsToPainter;
    Painter.Clear;
    Track.Paint( Painter );
    Painter.Paint( Canvas );
end;


// *********************************************
//          PAINT MESSAGE HANDLER
// *********************************************

// Called in response to WM_PAINT, and also explicitly.
// Fills out the clipping rectangle supplied by WM_PAINT

procedure TteTrackEditor.Paint;
var
    BoardRectPx : TRect;
    RightRectPx : TRect;
    BelowRectPx : TRect;
    ClipRect : TRect;
    RefreshBoardRectDivs : TRect;
    RefreshBoardRectPx : TRect;
begin
    ClipRect := Canvas.ClipRect;

    // calculate where Board Rectangle lies on window in screen pixels
    BoardRectPx.Left := 0;
    BoardRectPx.Top := 0;
    BoardRectPx.Right := BoardWidthScreenPixels - LeftX;
    BoardRectPx.Bottom := BoardHeightScreenPixels - TopY;

    // *** Repaint window area to right and below board - if inside cliprect
    {   ---------------------
        |  BOARD |  RIGHT   |
        |--------|----------|
        |  BELOW            |
        --------------------
    }

    // area to right of board
    RightRectPx.Left := BoardRectPx.Right;
    RightRectPx.Right := Width;
    RightRectPx.Top := 0;
    RightRectPx.Bottom := BoardRectPx.Bottom;

    // if requires a repaint, repaint the whole area to the right
    if RectanglesOverlap( ClipRect, RightRectPx ) then begin
        Canvas.Pen.Color := clBtnFace;
        Canvas.Brush.Color := clBtnFace;
        Canvas.Rectangle(
            RightRectPx.Left, RightRectPx.Top,
            RightRectPx.Right, RightRectPx.Bottom);
    end;

    // area below board
    BelowRectPx.Left := 0;
    BelowRectPx.Right := Width;
    BelowRectPx.Top := BoardRectPx.Bottom;
    BelowRectPx.Bottom := Height;

    // if requires a repaint, repaint the whole area below
    if RectanglesOverlap( ClipRect, BelowRectPx ) then begin
        Canvas.Pen.Color := clBtnFace;
        Canvas.Brush.Color := clBtnFace;
        Canvas.Rectangle(
            BelowRectPx.Left, BelowRectPx.Top,
            BelowRectPx.Right, BelowRectPx.Bottom);
    end;

    // Calculate the Board Area in screen pixels that Needs a Repaint
    if not IntersectRect( RefreshBoardRectPx, BoardRectPx, ClipRect ) then begin
        // ClipRect area does not include the board & tracks
        asm nop end;
        exit;
    end;

//    RefreshBoardRectPx := ClipRect;// BoardRectPx;

    // offset Screen Redraw Rectangle to remove any scrolling and give us
    // a rectangle relative to the board
    RefreshBoardRectPx.Left := RefreshBoardRectPx.Left + LeftX;
    RefreshBoardRectPx.Right := RefreshBoardRectPx.Right + LeftX;
    RefreshBoardRectPx.Top := RefreshBoardRectPx.Top + TopY;
    RefreshBoardRectPx.Bottom := RefreshBoardRectPx.Bottom + TopY;

    // convert repaint Board area into Board Cell Units
    RefreshBoardRectDivs.Left :=
        (RefreshBoardRectPx.Left * DIVS_PER_CELL) DIV PixelsPerCell;
    RefreshBoardRectDivs.Right :=
        (RefreshBoardRectPx.Right * DIVS_PER_CELL) DIV PixelsPerCell;
    RefreshBoardRectDivs.Top :=
        (RefreshBoardRectPx.Top * DIVS_PER_CELL) DIV PixelsPerCell;
    RefreshBoardRectDivs.Bottom :=
        (RefreshBoardRectPx.Bottom * DIVS_PER_CELL) DIV PixelsPerCell;

    // Paint Board Area
    PaintRect( RefreshBoardRectDivs );
end;

// *********************************************
//          PAINT BOARD RECTANGLE
// *********************************************

// Called with board rectangle to paint as parameter, defined in DIVS.
// Redraws the background rectangle, then finds all tracks overlapping that
// rectangle and draws them.

procedure TteTrackEditor.PaintRect( RectDivs : TRect );
var
    i : integer;
    Track : TteTrack;
    SelectedCount : integer;
    ScreenRectPx : TRect;
begin
{
    // ** increase the draw area box by one cell on each side, so that
    // integer division truncation does not leave us a pixel undersize
    ScreenRectPx.Left := ScreenRectPx.Left - DIVS_PER_CELL;
    ScreenRectPx.Right := ScreenRectPx.Right + DIVS_PER_CELL;
    ScreenRectPx.Top := ScreenRectPx.Top - DIVS_PER_CELL;
    ScreenRectPx.Bottom := ScreenRectPx.Bottom + DIVS_PER_CELL;
}
    // convert repaint Board area into Board Cell Units
    ScreenRectPx.Left := (RectDivs.Left * PixelsPerCell div DIVS_PER_CELL);
    ScreenRectPx.Right := (RectDivs.Right * PixelsPerCell div DIVS_PER_CELL);
    ScreenRectPx.Top := (RectDivs.Top * PixelsPerCell div DIVS_PER_CELL);
    ScreenRectPx.Bottom := (RectDivs.Bottom * PixelsPerCell div DIVS_PER_CELL);

    // calculate screen rectangle to erase.
    // Note: we paint +1 pixel larger, to account for rounding errors.
    // In particular THUMBTRACK painting leaves debris without this.
    ScreenRectPx.Left := ScreenRectPx.Left - LeftX - 1;
    ScreenRectPx.Right := ScreenRectPx.Right - LeftX + 1;
    ScreenRectPx.Top := ScreenRectPx.Top - TopY - 1;
    ScreenRectPx.Bottom := ScreenRectPx.Bottom - TopY + 1;

    // ** paint the board repaint area
    Canvas.Pen.Color := FBoardColor;
    Canvas.Brush.Color := FBoardColor;
    Canvas.Rectangle( ScreenRectPx );

    // ** Painter will take over drawing on the canvas
    CanvasSettingsToPainter;

    // ** get unselected items to register primitives (lines, circles etc)
    Painter.Clear;
    for i := 0 to Tracks.Count - 1 do begin
        Track := Tracks[i];
        if not Track.Selected then begin
            if Track.OverlapsPaintRect_D( RectDivs ) then begin
                Track.Paint( Painter );
            end;
        end;
    end;

    // ** paint unselected
    Painter.LeftX := LeftX;
    Painter.TopY := TopY;
    Painter.StripColor := FStripColor;
    Painter.Paint( Canvas );

    // ** get selected items to register primitives (lines, circles etc)
    Painter.Clear;
    for i := 0 to Tracks.Count - 1 do begin
        Track := Tracks[i];
        if Track.Selected then begin
            if Track.OverlapsPaintRect_D( RectDivs ) then begin
                Track.Paint( Painter );
            end;
        end;
    end;

    // ** paint selected
    // we ignore DrawMode because Paint and PaintRect always draw without XOR
    Painter.StripColor := FSelectionColor;
    Painter.Paint( Canvas );

    //display some stuff for debug
    exit;
    SelectedCount := Tracks.GetSelectedCount;
    Canvas.TextOut( 20, 20, Format( '%d', [SelectedCount] ));
    Canvas.TextOut( 20, 30, Format( '%f,%f', [MouseDownCellCoords.x, MouseDownCellCoords.y] ));
end;




end.
