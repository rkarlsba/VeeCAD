unit Editor;

interface

uses ExtCtrls, Classes, Controls, SysUtils,
    Outlines, SizeableOutlines, OtherOutlines, Netlist, Menus, InputBoxFrm,
    Windows, Messages, Graphics,
    Project, Painter, Rotations, BoardPainterConnective, BoardPainter;

type
    TPerfEditMode = ( emSelect, emBreak, emLink, emWire, emText );
    TPerfMouseMoveTask = (
        mvNone, mvDrawSelectionRectangle, mvMoveItem, mvMoveSelectedItems,
        mvSizeLink, mvStretchSizeable, mvMoveSizeablePin, mvMoveDesignator,
        mvMoveItemFine );
    EPerfProject = class( Exception );
    TMouseCellMove = procedure( CellX, CellY : integer ) of object;
    TMouseClickItem = procedure(
        Item : TveBoardItem; PinName : string; Node : TneNode ) of object;
    TPerfModeChange = procedure( Sender : TObject; Mode : TPerfEditMode )
        of object;
    TDrawMode = ( dmNormal, dmSelected, dmXOR );
    TvePenMode = ( drcXOR, drcCopy );
    TveOverlayType = ( ovlNone, ovlConnectionErrors, ovlNetTrace );
    TveArrowMove = ( amNone, amUp, amDown, amLeft, amRight );

type TveEditor = class( TCustomControl )

protected

    // The editor always works on a TveProject
    FProject : TveProject;

    // drawing scale in pixels per cell
    FPixelsPerCell : integer;
    FComponentLineWidth : integer;
    WheelTotal : integer;

    // editing variables
    FEditMode : TPerfEditMode;
    MouseCellX, MouseCellY : integer;

    // painting variables
    //.. draw board items (components, links, wires, text) on this plane
    ItemPlane : TBitmap;
    Painter : TvePainter;

    //.. build screen image on OutputPlane then blit to screen
    OutputPlane : TBitmap;
    DrawMode : TDrawMode;

    //.. pre-drawn board with its strips stored in this bitmap
    BoardPlane : TBitmap;
    BoardPainterNetColor : TcnBoardPainter;
    BoardPainter : TbrBoardPainter;

    // display colors
    FStripColor : TColor;
    FBoardColor : TColor;

    // overlays to display
    FConnectionErrorsVisible : boolean;
    FNetTraceVisible : boolean;
    FFreeStripsVisible : boolean;

    // interface objects
    ItemPopupMenu : TPopupMenu;
    PopupPoint : TPoint;
    ClickedItem : TveBoardItem;
    InputBoxForm : TInputBoxForm;

    // mouse move action
    MouseMoveTask : TPerfMouseMoveTask;

    // arrow key action
    ArrowMove : TveArrowMove;

    // selection rectangle as defined by user, cell units
    FSelectedRect : TRect;
    // FSelectedRect holds valid info
    FSelectionValid : boolean;
    // selection rectangle dragged on screen by user in client (pixel) units
    SelectionClientRect : TRect;

    // link drawing & sizing variables
    DrawLink : TveBoardItem;
    ClickCellX : integer;
    ClickCellY : integer;

    // item dragging variables
    MoveItem : TveBoardItem;
    MoveOriginalClientX : integer;
    MoveOriginalClientY : integer;
    MoveLastCellX : integer;
    MoveLastCellY : integer;
    MoveOriginalXDiv : integer;
    MoveOriginalYDiv : integer;
    MovePinIndex : integer;

    ClickCellOffsetX : integer;
    ClickCellOffsetY : integer;
    ClickOriginalCellX : integer;
    ClickOriginalCellY : integer;

    // rectangle around all items which are being moved - just encloses items
    // and is calculated just before starting to drag items
    MoveItemsBoundaryCellRect : TRect;

    // rectangle which requires repaint around moved items
    MoveItemRepaintCellRect : TRect;

    LastDeltaCellX : integer;
    LastDeltaCellY : integer;

    // sizeable item stretching variables
    ClickNearestReference : boolean;
    ClickItemOffset : integer;
    OriginalSizeableLength : integer;

    // designator moving variables
    MoveDesignatorItem : TveBoardItem;

    // events offered by this object
    FOnMouseCellMove : TMouseCellMove;
    FOnMouseClickItem : TMouseClickItem;

    FOnChange : TNotifyEvent;
    FOnChangeMode : TPerfModeChange;

    // values used to get appearance right
    FBorder : integer;
    FGap : integer;

    // Design rule check
    FDRCVisible : boolean;
    FDRCAutoRefresh : boolean;

    // hot key data
    FSelectModeKey : WORD;
    FBreakModeKey : WORD;
    FLinkModeKey : WORD;
    FWireModeKey : WORD;
    FTextModeKey : WORD;
    FRedrawKey : WORD;

    // hot keys functions
    function GetSelectModeShortCut : TShortCut;
    procedure SetSelectModeShortCut( value : TShortCut );
    function GetBreakModeShortCut : TShortCut;
    procedure SetBreakModeShortCut( value : TShortCut );
    function GetLinkModeShortCut : TShortCut;
    procedure SetLinkModeShortCut( value : TShortCut );
    function GetWireModeShortCut : TShortCut;
    procedure SetWireModeShortCut( value : TShortCut );
    function GetTextModeShortCut : TShortCut;
    procedure SetTextModeShortCut( value : TShortCut );
    function GetRedrawShortCut : TShortCut;
    procedure SetRedrawShortCut( value : TShortCut );


    procedure SetProject( Proj : TveProject );
    procedure SetEditMode( Mode : TPerfEditMode );
    procedure GetCellAt( ClientX, ClientY : integer; var CellX, CellY : integer );
    function GetCellQuadrantAt( ClientX, ClientY : integer ) : TQuadrant;

    procedure SetPixelsPerCell( value : integer );
    procedure SetComponentLineWidth( Width : integer );
    function GetTextDisplay : TTextDisplay;
    procedure SetTextDisplay( Value : TTextDisplay );
    function GetLeadStyle : TLeadStyle;
    procedure SetLeadStyle( Value : TLeadStyle );

    procedure UpdatePaintInfo;

    // override functions from ancestor object
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

    // message handlers
    procedure WMGetDlgCode(var message: TMessage); message WM_GETDLGCODE;

    // painting functions
    procedure SetCanvasXOR;
    procedure SetCanvasXORRectangle;
    procedure PaintDesignatorRectangle( Item : TveBoardItem );
    procedure PaintConnectivityErrors;
    procedure PaintNetTrace;
    procedure PaintNetTraceSimple;
    procedure PaintNetTraceFull;
    procedure PaintPinTrace;
    procedure PaintFreeStrips;
    procedure PaintFreeStripsNoNet;
    procedure PaintNetColors;
    procedure PaintLinkColors;
    procedure PaintSelected;
    procedure PaintItem( Item : TveBoardItem );
    procedure PaintItemAndGroup( Item : TveBoardItem );
    procedure PaintRect( const R : TRect );
    procedure SetCanvasUnselected;
    procedure SetCanvasSelected;

    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;

    // internal service functions
    procedure ShowRightClickMenu( X, Y : integer );

    function GetDirty : boolean;
    procedure SetDirty( Value : boolean );
    procedure MakeDirty;
    procedure ProjectChangeHandler( Sender : TObject );
    procedure CreateBoardItemMenu;
    procedure ArrowMoveSelected( Direction : TveArrowMove );


    // internal event channelling
    procedure MouseClickItem( Item : TveBoardItem );
    procedure MouseClickItemXY( Item : TveBoardItem; X, Y : integer );
    procedure MouseWheelEvent(Sender: TObject; Shift: TShiftState;
        WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);

    // internal popup menu event handlers
    procedure OnDesignatorMenu(Sender: TObject);
    procedure OnValueMenu(Sender : TObject);
    procedure OnDesignatorVisibleMenu( Sender : TObject );
    procedure OnLargeTextMenu( Sender : TObject );
    procedure OnPropertiesMenu( Sender: TObject );

    // internal calcs
    procedure GetSelectedItemsBoundary;
    procedure GetSelectedItemsPaintBoundary;

    // properties
    function GetBodyColor : TColor;
    procedure SetBodyColor( Value : TColor );
    function GetPinColor : TColor;
    procedure SetPinColor( Value : TColor );
    function GetStripColor : TColor;
    procedure SetStripColor( Value : TColor );
    function GetBoardColor : TColor;
    procedure SetBoardColor( Value : TColor );
    function GetSelectionColor : TColor;
    procedure SetSelectionColor( Value : TColor );

public
    // color nets in these colors
//    const ColoredNodeCount = 6;
    var NodeColors : array[0..TneNetlist.ColoredNodeCount-1] of TColor;

    // the editor always works on a project
    property Project : TveProject read FProject write SetProject;

    // editing mode variables
    property EditMode : TPerfEditMode read FEditMode write SetEditMode;

    property Dirty : boolean read GetDirty write SetDirty;

    property PixelsPerCell : integer read FPixelsPerCell write SetPixelsPerCell;
    property Border : integer read FBorder;
    property Gap : integer read FGap;
    property ComponentLineWidth : integer
            read FComponentLineWidth write SetComponentLineWidth;
    property TextDisplay : TTextDisplay read GetTextDisplay write SetTextDisplay;
    property LeadStyle : TLeadStyle read GetLeadStyle write SetLeadStyle;


    // expose editor canvas for use in graphics copy ????
    property Canvas;

    // events
    property OnMouseCellMove : TMouseCellMove
        read FOnMouseCellMove write FOnMouseCellMove;

    property OnMouseClickItem : TMouseClickItem
        read FOnMouseClickItem write FOnMouseClickItem;

    property OnChange : TNotifyEvent read FOnChange write FOnChange;

    property OnChangeMode : TPerfModeChange
        read FOnChangeMode write FOnChangeMode;

    // mouse selection rectangle, cell units
    property SelectedRect : TRect read FSelectedRect;
    property SelectionValid : boolean read FSelectionValid;

    // editing procedures should be hooked to keys
    procedure RotateDuringMove;

    procedure DeleteSelectedItems;
    procedure RotateSelected;
    procedure RotateSingleSelected;
    procedure RotateMultipleSelected;
    procedure SelectItem( Item : TveBoardItem );

    procedure Undo;
    procedure Redo;
    procedure ClearUndo;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // painting
    procedure Paint; override;
    procedure EndDrawSequence;

    property ConnectionErrorsVisible : boolean
        read FConnectionErrorsVisible write FConnectionErrorsVisible;
    property NetTraceVisible : boolean
        read FNetTraceVisible write FNetTraceVisible;
    property FreeStripsVisible : boolean
        read FFreeStripsVisible write FFreeStripsVisible;

    // display colors
    property BodyColor : TColor read GetBodyColor write SetBodyColor;
    property PinColor : TColor read GetPinColor write SetPinColor;
    property StripColor : TColor read GetStripColor write SetStripColor;
    property BoardColor : TColor read GetBoardColor write SetBoardColor;
    property SelectionColor : TColor read GetSelectionColor write SetSelectionColor;

    // hot keys
    property SelectModeShortCut : TShortCut
        read GetSelectModeShortCut write SetSelectModeShortCut;
    property LinkModeShortCut : TShortCut
        read GetLinkModeShortCut write SetLinkModeShortCut;
    property BreakModeShortCut : TShortCut
        read GetBreakModeShortCut write SetBreakModeShortCut;
    property WireModeShortCut : TShortCut
        read GetWireModeShortCut write SetWireModeShortCut;
    property TextModeShortCut : TShortCut
        read GetTextModeShortCut write SetTextModeShortCut;
//    property ZoomInShortCut
//    property ZoomOutShortCut
    property RedrawShortCut : TShortCut
        read GetRedrawShortCut write SetRedrawShortCut;

    procedure PasteComponents;
    procedure PasteComponentsWithDuplicateIdentifiers;

    procedure CopyComponents;

    procedure GroupSelected;
    procedure UnGroupSelected;

end;


implementation

uses Dialogs, Connective, Tracer, CelledOutlines, Cursors,
    SortCompare, BlockRotate, Math, Rectangles, BoardSize, ClipbrdComponents,
    Board, SmdOutlines, BoardItemSettings
{$IFNDEF VER200}, System.Types {$ENDIF} ;

const
    STD_BORDER = 0;
    STD_GAP = 1;
    TRANSPARENT_COLOR = clWhite - 50;

const Rotation2Str : array[TRotation] of string = ( '0', '90', '180', '270' );
const NodeColorsInit : array[0..5] of TColor =
    ( clGray, clAqua, clYellow, clSkyBlue, clNavy, clOlive );


constructor TveEditor.Create(AOwner: TComponent);
var
    i : integer;
begin
    inherited Create( AOwner );
//    Tabstop := False;
    // This forces drawing to a bitmap then blitting to screen: we definitely
    // do not want this, since we take great care to paint only changed regions
//     DoubleBuffered := True;

    // a safe value to get us going
    FPixelsPerCell := 14;
    FComponentLineWidth := 1;

    FBorder := STD_BORDER;
    FGap := STD_GAP;

    FStripColor := $E0E0E0; //clLtGray;
    FBoardColor := $DFFFF8; //clWhite;

    for i := 0 to High( NodeColorsInit ) do begin
        NodeColors[i] := NodeColorsInit[i];
    end;

    CreateBoardItemMenu;
    InputBoxForm := TInputBoxForm.Create(self);

    OutputPlane := TBitmap.Create;
    Painter := TvePainter.Create;
    BoardPlane := TBitmap.Create;
    BoardPainterNetColor := TcnBoardPainter.Create;
    BoardPainter := TbrBoardPainter.Create;
    ItemPlane := TBitmap.Create;
    UpdatePaintInfo;

    OnMouseWheel := MouseWheelEvent;
end;

// Right Click Menu Indexes
const
    RM_Value       = 0;
    RM_Designator  = 1;
    RM_TextVisible = 2;
    RM_LargeText   = 3;
    RM_Properties  = 4;

procedure TveEditor.CreateBoardItemMenu;
    procedure AddMenuItem( const Caption : string; Handler : TNotifyEvent );
    var
        NewItem : TMenuItem;
    begin
        NewItem := TMenuItem.Create(Self);
        NewItem.Caption := Caption;
        NewItem.OnClick := Handler;
        ItemPopupMenu.Items.Add( NewItem );
    end;
begin
    ItemPopupMenu := TPopupMenu.Create(self);
    AddMenuItem( 'Value', OnValueMenu );
    AddMenuItem( 'Designator', OnDesignatorMenu );
    AddMenuItem( 'Text Visible', OnDesignatorVisibleMenu );
    AddMenuItem( 'Large Text', OnLargeTextMenu );
    AddMenuItem( 'Properties', OnPropertiesMenu );

//    AddMenuItem( 'Outline', nil );
end;

destructor TveEditor.Destroy;
begin
    // at the moment, the editor owns its Project.  Other projects are
    // created in other places in the program, but are not "given" to the
    // Editor.  At some future stage, might make Editor accept projects
    // so that 1) could have multiple projects open 2) Outlines and Components
    // settings forms can edit a copy of the project so that if Cancel button
    // clicked can discard that copy and if OK clicked replaced Editor.Project.
    FProject.Free;
    Painter.Free;
    BoardPainterNetColor.Free;
    BoardPainter.Free;
    OutputPlane.Free;
    BoardPlane.Free;
    ItemPlane.Free;
    inherited;
end;


// Handle a Windows Message to request arrow key messages sent to this
// TWinControl as well as ordinary key messages
procedure TveEditor.WMGetDlgCode(var message: TMessage);
begin
    message.Result := DLGC_WANTARROWS;
end;


procedure TveEditor.SetPixelsPerCell( value : integer );
const
    MaxPixelsPerCell = 40;
    MinPixelsPerCell = 4;
begin
    if value < MinPixelsPerCell then begin
        value := MinPixelsPerCell;
    end
    else if value > MaxPixelsPerCell then begin
        value := MaxPixelsPerCell;
    end;

    // force pixels per cell to move in jumps of 2, thus overcoming
    // difficulties in drawing routines
//    FPixelsPerCell := value {and $FFFFFFFE};
    FPixelsPerCell := value;

    BoardPainterNetColor.PixelsPerCell := value;

    UpdatePaintInfo;
end;

// Mouse Wheel Scrolls By Changing PixelsPerCell 
procedure TveEditor.MouseWheelEvent(Sender: TObject; Shift: TShiftState;
    WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
    Delta : integer;
begin
    Inc( WheelTotal, WheelDelta );
    Delta := WheelTotal div WHEEL_DELTA;
    Dec( WheelTotal, Delta * WHEEL_DELTA );
    PixelsPerCell := PixelsPerCell + Delta;
    Handled := True;
    Paint;
end;



procedure TveEditor.SetComponentLineWidth( Width : integer );
begin
    FComponentLineWidth := Width;
    UpdatePaintInfo;
end;

function TveEditor.GetTextDisplay : TTextDisplay;
begin
    result := Painter.TextDisplay;
end;

procedure TveEditor.SetTextDisplay( Value : TTextDisplay );
begin
    Painter.TextDisplay := Value;
end;

function TveEditor.GetLeadStyle : TLeadStyle;
begin
    result := Painter.LeadStyle;
end;

procedure TveEditor.SetLeadStyle( Value : TLeadStyle );
begin
    Painter.LeadStyle := Value;
end;

procedure TveEditor.SetProject( Proj : TveProject );
begin
    FProject := Proj;
    FProject.OnChange := ProjectChangeHandler;

    // trigger update of dirty status
    FProject.Dirty := FProject.Dirty;
end;


procedure TveEditor.UpdatePaintInfo;
begin
    Painter.Border := FBorder;
    Painter.Gap := FGap;
    Painter.PixelsPerCell := FPixelsPerCell;
    Painter.Options := [];
    Painter.LineWidth := FComponentLineWidth;

    Painter.SmallTextWidth := PixelsPerCell2CharWidth( PixelsPerCell, tsSmall );
    Painter.SmallTextHeight :=  PixelsPerCell2CharHeight( PixelsPerCell, tsSmall );

    Painter.LargeTextWidth := PixelsPerCell2CharWidth( PixelsPerCell, tsLarge );
    Painter.LargeTextHeight := PixelsPerCell2CharHeight( PixelsPerCell, tsLarge );


end;


// *** CHANGE EDIT MODE ***
procedure TveEditor.SetEditMode( Mode : TPerfEditMode );
const
    ModeToShape : array[TPerfEditMode]  of TcCursorShape =
        ( csSelect, csBreak, csLink, csWire, csText );
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
end;


function TveEditor.GetDirty : boolean;
begin
    result := FProject.Dirty;
end;


procedure TveEditor.SetDirty( Value : boolean );
begin
    FProject.Dirty := Value;
end;

function TveEditor.GetBodyColor : TColor;
begin
    result := Painter.BodyColor;
end;

procedure TveEditor.SetBodyColor( Value : TColor );
begin
    Painter.BodyColor := Value;
end;

function TveEditor.GetPinColor : TColor;
begin
    result := Painter.PinColor;
end;

procedure TveEditor.SetPinColor( Value : TColor );
begin
    Painter.PinColor := Value;
end;

function TveEditor.GetStripColor : TColor;
begin
    result := BoardPainter.StripColor;
end;

procedure TveEditor.SetStripColor( Value : TColor );
begin
    BoardPainter.StripColor := Value;
end;

function TveEditor.GetBoardColor : TColor;
begin
    result := BoardPainter.BoardColor;
end;

procedure TveEditor.SetBoardColor( Value : TColor );
begin
    BoardPainter.BoardColor := Value;
end;

function TveEditor.GetSelectionColor : TColor;
begin
    result := Painter.SelectionColor;
end;

procedure TveEditor.SetSelectionColor( Value : TColor );
begin
    Painter.SelectionColor := Value;
end;

// ** HOT KEYS **

function TveEditor.GetSelectModeShortCut : TShortCut;
begin
    result := ShortCut( FSelectModeKey, [] );
end;

procedure TveEditor.SetSelectModeShortCut( value : TShortCut );
var
  Shift: TShiftState;
begin
    ShortCutToKey( value, FSelectModeKey, Shift );
end;

function TveEditor.GetBreakModeShortCut : TShortCut;
begin
    result := ShortCut( FBreakModeKey, [] );
end;

procedure TveEditor.SetBreakModeShortCut( value : TShortCut );
var
  Shift: TShiftState;
begin
    ShortCutToKey( value, FBreakModeKey, Shift );
end;

function TveEditor.GetLinkModeShortCut : TShortCut;
begin
    result := ShortCut( FLinkModeKey, [] );
end;
procedure TveEditor.SetLinkModeShortCut( value : TShortCut );
var
  Shift: TShiftState;
begin
    ShortCutToKey( value, FLinkModeKey, Shift );
end;

function TveEditor.GetWireModeShortCut : TShortCut;
begin    
    result := ShortCut( FWireModeKey, [] );
end;

procedure TveEditor.SetWireModeShortCut( value : TShortCut );
var
  Shift: TShiftState;
begin    
    ShortCutToKey( value, FWireModeKey, Shift );
end;

function TveEditor.GetTextModeShortCut : TShortCut;
begin
    result := ShortCut( FTextModeKey, [] );
end;

procedure TveEditor.SetTextModeShortCut( value : TShortCut );
var
  Shift: TShiftState;
begin
    ShortCutToKey( value, FTextModeKey, Shift );
end;

function TveEditor.GetRedrawShortCut : TShortCut;
begin    
    result := ShortCut( FRedrawKey, [] );
end;
procedure TveEditor.SetRedrawShortCut( value : TShortCut );
var
  Shift: TShiftState;
begin    
    ShortCutToKey( value, FRedrawKey, Shift );
end;


// ** CALL WHEN EDITING CHANGES ANYTHING IN PROJECT **
procedure TveEditor.MakeDirty;
begin
    FProject.Dirty := True;
end;

// ** EVENT HANDLER CALLED BY PROJECT BELONGING TO THIS EDITOR **
procedure TveEditor.ProjectChangeHandler( Sender : TObject );
begin
    if assigned( FOnChange ) then begin
        FOnChange( Self );
    end;
end;


// ** OnMouseClickItem EVENT FIRED VIA THIS FUNCTION **
// Call this when an item is manipulated during editing, but no specific
// pin number is involved.  Item can be nil.

procedure TveEditor.MouseClickItem( Item : TveBoardItem );
begin
    if Assigned( FOnMouseClickItem ) then begin
        // show item details, and current clicknet, but no pin number
        FOnMouseClickItem( Item, '', FProject.TraceNet );
    end;
end;

// ** OnMouseClickItem EVENT FIRED VIA THIS FUNCTION **
// Item can be nil

procedure TveEditor.MouseClickItemXY( Item : TveBoardItem; X, Y : integer );
var
    Node : TneNode;
    PinIndex : integer;
    PinName : string;
    Tracer : TveTracer;
begin

    // if we clicked on an item
     if Item <> nil then begin
        PinIndex := Item.Outline.PinIndexAt( Item, X, Y );

        // if we clicked on a pin of the item
        if PinIndex >= 0 then begin

            // if item is a Link
            if (Item.Outline is TveLinkOutline) then begin
                Tracer := TveTracer( FProject.ConnectivityObject );
                Node := Tracer.NodeByLink(Item );
                FProject.TraceNet := Node;
            end

            else if (Item.Outline is TveWireOutline) then begin
                Tracer := TveTracer( FProject.ConnectivityObject );
                Node := Tracer.NodeByWire(Item );
                FProject.TraceNet := Node;
            end

            // else for all other items
            // if we have a valid pin number
            else begin
                Node := TneNode( Item.NodeAtPin[PinIndex] );
                FProject.TraceNet := Node;
            end;
        end

        // if we do not have a valid pin number
        else begin
            Node := nil;
            // leave clicknet unchanged
        end;
    end

    // else we clicked outside an item
    else begin
        PinIndex := -1;
//        PinNo := -1;
        Node := nil;
        // leave clicknet unchanged
    end;

    if Assigned( FOnMouseClickItem ) then begin

//        if PinNo > 0 then begin
//            PinName := IntToStr(PinNo);
//        end;
        if PinIndex >= 0  then begin
            PinName :=  Item.Outline.Pins[PinIndex].Name;
        end;

        // show clicknet : applies even if last click was not on a pin
        if FNetTraceVisible then begin
            FOnMouseClickItem( Item, PinName, FProject.TraceNet );
        end

        // show net only if last click was on a pin last
        else begin
            FOnMouseClickItem( Item, PinName, Node );
        end;
    end;
end;


// ** Find Rectangle Which Encloses All Selected Items **
procedure TveEditor.GetSelectedItemsBoundary;
begin
    FProject.GetSelectedItemsBoundary( MoveItemsBoundaryCellRect );
end;

// ** Find Paint Rectangle Which Encloses All Selected Items **
procedure TveEditor.GetSelectedItemsPaintBoundary;
begin
    FProject.GetSelectedItemsPaintBoundary( MoveItemRepaintCellRect );
end;

// *** Find Cell Coords Given Client (Pixel) Coords ***
procedure TveEditor.GetCellAt( ClientX, ClientY : integer; var CellX, CellY : integer );
begin
    // turn screen cooords into Cell Coords
    CellX := ( ClientX - FBorder ) div PixelsPerCell;
    CellY := ( ClientY - FBorder ) div PixelsPerCell;
end;

// *** Find Cell Quadrant Given Client (Pixel) Coords ***
function TveEditor.GetCellQuadrantAt( ClientX, ClientY : integer ) : TQuadrant;
const                           // left           // bottom
    CellOffset2Quadrant : array[boolean] of array[boolean] of TQuadrant =
        ( (qaBottomLeft, qaTopLeft), (qaBottomRight, qaTopRight) );
begin
    result := CellOffset2Quadrant
    [   ((2 * (ClientX mod FPixelsPerCell)) > FPixelsPerCell ),
        ((2 * (ClientY mod FPixelsPerCell)) <= FPixelsPerCell )
    ];
end;

procedure TveEditor.MouseDown(Button: TMouseButton; Shift: TShiftState;
    X, Y: Integer);
var
    i : integer;
    Item : TveBoardItem;
    deleted : boolean;

    C : TveBoardItem;
    B : TveBoardItem;
    CellX, CellY : integer;
    CellQuadrant : TQuadrant;
    SelectedCount : integer;

    RotX, RotY : integer;

    BreakRect : TRect;
    Break2Rect : TRect;
    TextRect : TRect;
begin
    // focus lets this Window receive keyboard messages

    // old selection rectangle dead
    FSelectionValid := False;

    // terminate any arrow movements sequence
    ArrowMove := amNone;

    // if Right-Click, then Popup Menu
    if (ssRight in Shift) then begin
        ShowRightClickMenu( X, Y );
        exit;
    end;

    GetCellAt( X, Y, ClickCellX, ClickCellY );

    // if break mode , togggle break BoardItem
    if EditMode = emBreak then begin

        // convert client to cell cords
        GetCellAt( X, Y, CellX, CellY );

        // This is a hack: a substitute for locating each break exactly.
        // if we are near half way between 2 cells, make sure we target
        // the cell to the left, because this will pick up shifted cells
        // which are based on the cell to the left. Don't worry about Y direction
        // because we place unshifted or right shifted breaks only - we don't
        // *place* vertically shifted breaks.
        if (4 * (X mod FPixelsPerCell)) < FPixelsPerCell then begin
            Dec( CellX );
            // do not place a break off the board
            if CellX < 0 then begin
                CellX := 0;
            end;
        end;

        // look for all breaks already at the location, and delete them
        Item := nil;
        deleted := False;
        for i := FProject.BoardItemCount -1 downto 0 do begin
            Item := FProject.BoardItems[i];
            if (Item.Outline is TveBreakOutline) and
                    Item.Outline.OccupiesCell( Item, CellX, CellY ) then begin
                deleted := True;
                break;
            end;
        end;

        if deleted then begin
            // record deleted item for Undo
            FProject.DeleteItemAsUndo( Item );
            // get bounding rectangle containing break and repaint inside it
            Item.Outline.GetPaintRect( Item, BreakRect );
            PaintRect( BreakRect );
            EndDrawSequence;
        end

        // if no breaks were deleted, then space was clear - add a break
        else begin
            // add new break to BoardItems list
            B := TveBoardItem.Create;
            B.Outline := FProject.BreakOutline;
            B.X := CellX;
            B.Y := CellY;
            // offset 1/2 cell to right if Alt key held down
            if (ssAlt in Shift) or (ssShift in Shift) then begin
                B.Shift := shRight;
            end;

            // record added item for Undo
            FProject.AddItemAsUndo( B );
            // redraw rectangle containing break
            B.Outline.GetPaintRect( B, BreakRect );
            PaintRect( BreakRect );
            EndDrawSequence;
        end;
        MakeDirty;
        MouseMoveTask := mvNone;
    end

    // if Wire mode, toggle Wire BoardItem
    else if EditMode = emWire then begin
        // convert client to cell cords
        GetCellAt( X, Y, CellX, CellY );

        // look for all wires already at the location, and delete them
        Item := nil;
        deleted := False;
        for i := FProject.BoardItemCount -1 downto 0 do begin
            Item := FProject.BoardItems[i];
            if (Item.Outline is TveWireOutline) and
                    Item.Outline.OccupiesCell( Item, CellX, CellY ) then begin
                deleted := True;
                break;
            end;
        end;

        if deleted then begin
            // record deleted item for Undo
            FProject.DeleteItemAsUndo( Item );

            PaintRect( Rect(CellX, CellY, CellX+1, CellY+1) );
        end

        // if no wires were deleted, then space was clear - add a wire
        else begin
            // add new wire to BoardItems list
            B := TveBoardItem.Create;
            B.Outline := FProject.WireOutline;
            B.Value := '??';
            B.X := CellX;
            B.Y := CellY;

            // record added item for Undo
            FProject.AddItemAsUndo( B );

            // redraw rectangle containing break
            B.Outline.GetPaintRect( B, BreakRect );
            PaintRect( BreakRect );
            EndDrawSequence;
        end;
        MakeDirty;
        MouseMoveTask := mvNone;
    end

    // if link mode
    else if EditMode = emLink then begin

        // create link object
        DrawLink := TveBoardItem.Create;
        DrawLink.Outline := FProject.LinkOutline;
        GetCellAt( X, Y, CellX, CellY );
        DrawLink.X := CellX;
        DrawLink.Y := CellY;
        DrawLink.Length := 0;

        // record added item for Undo
        FProject.AddItemAsUndo( DrawLink );

        // record BoardItem, Original Click Pixel Coords,
        // Offset (ie position relative to reference cell) of click point
        ClickCellX := CellX;
        ClickCellY := CellY;
        MoveOriginalClientX := X;
        MoveOriginalClientY := Y;
        ClickCellOffsetX := ((X - FBorder) div PixelsPerCell) - DrawLink.X ;
        ClickCellOffsetY := ((Y - FBorder) div PixelsPerCell) - DrawLink.Y;

        // prepare for XOR image to follow mouse
        SetCanvasXOR;
        PaintItem( DrawLink );

        MakeDirty;
        // start "sizing link" state machine
        MouseMoveTask := mvSizeLink;
    end

    // if Text mode
    else if EditMode = emText then begin
        // convert client to cell cords
        GetCellAt( X, Y, CellX, CellY );

        // add new text item to BoardItems list
        B := TveBoardItem.Create;
        B.Outline := FProject.TextOutline;
        B.Value := '??';
        B.X := CellX;
        B.Y := CellY;

        // record added item for Undo
        FProject.AddItemAsUndo( B );

//            SetCanvasUnselected;
//            PaintItem( B );

        // redraw rectangle containing break
        B.Outline.GetPaintRect( B, TextRect );
        PaintRect( TextRect );
        EndDrawSequence;

//        end;
        MakeDirty;
        MouseMoveTask := mvNone;
    end

    // if select mode
    else begin

        // convert client to cell cords
        GetCellAt( X, Y, CellX, CellY );

        // if designators are showing and not Alt/Ctrl and not multiple items
        // selected as in group moves, then look for designator
        if (Painter.TextDisplay <> tdNone) and not
            ( (ssAlt in Shift) or (ssCtrl in Shift) ) and not FProject.MultipleSelected then begin
             // see if we have clicked on a designator belonging to a BoardItem
            C := FProject.GetItemWithDesignatorAt( CellX, CellY );
        end
        else begin
            C := nil;
        end;

        if C <> nil then begin

            // event gives info on clicked board item
            // We don't call MouseClickItemXY( C, CellX, CellY ); because
            // it will find any pin lying under the text and we don't want
            // to appear to click on text *and* pin at the same time.
            MouseClickItem( C );

            // unselect all by repainting selected in normal color
            SetCanvasUnselected;
            PaintSelected;

            // select just this BoardItem
            FProject.DeSelectAllItems;
            C.Selected := True;
            SetCanvasSelected;
            PaintItem( C );

            // save reference to BoardItem
            MoveDesignatorItem := C;

            // ...record Original Designator settings for undo
            C.TakeSnapshot;

            // record
            MoveOriginalClientX := X;
            MoveOriginalClientY := Y;
            ClickOriginalCellX := CellX;
            ClickOriginalCellY := CellY;
            LastDeltaCellX := 0;
            LastDeltaCellY := 0;

            // record the repaint rectangle of the item - this includes the
            // area taken by the Designator and the Body
            C.Outline.GetPaintRect( C, MoveItemRepaintCellRect );

            // setup for XOR drawing of Designator during move
            SetCanvasXORRectangle;

            // draw Designator text rectangle to show user we are clicked
            PaintDesignatorRectangle( MoveDesignatorItem );

            // start "moving designator" state machine
            MouseMoveTask := mvMoveDesignator;

            exit;
        end;

        // locate BoardItem
        // .. fine tune location info by finding which clicked quadrant of cell
        CellQuadrant := GetCellQuadrantAt( X, Y );
        // .. and use special function which discerns shifted items (breaks)
        C := FProject.GetBoardItemAtXYQuad( CellX, CellY, CellQuadrant );

        // display info on clicked board item - name, net, pin no etc
        MouseClickItemXY( C, CellX, CellY );

        // if clicked outside all BoardItems,
        if (C = nil) then begin

            // then prepare to draw selection rectangle

            // if Ctrl not down, empty selection
            if not (ssCtrl in Shift) then begin
                SetCanvasUnselected;
                PaintSelected;
                FProject.DeSelectAllItems;
            end;

            // prepare to draw selection rectangle when mouse moves
            SetCanvasXORRectangle;

            // record where we started
            MoveOriginalClientX := X;
            MoveOriginalClientY := Y;

            SelectionClientRect.Left := X;
            SelectionClientRect.Top := Y;
            SelectionClientRect.Right := X;
            SelectionClientRect.Bottom := Y;

            MouseMoveTask := mvDrawSelectionRectangle;
        end

        // ** ctrl-click toggles selection of this BoardItem **
        else if (ssCtrl in Shift) then begin
//            C.Selected := not C.Selected;
            FProject.ToggleComponentAndGroupSelection( C );

            // paint this BoardItem to show new selection status
            if C.Selected then begin
                SetCanvasSelected;
            end
            else begin
                SetCanvasUnselected;
            end;
//            PaintItem( C );
            PaintItemAndGroup( C );
            MouseMoveTask := mvNone;
        end

        // ** shift-click ** (also ALT-click supported)
        else if (ssAlt in Shift) or (ssShift in Shift) then begin

            // shift-click means stretch lead of this BoardItem
            // (non group items only.)
            if C.Outline is TveSizeableOutline and (C.Group = 0) then begin

                // unselect all by repainting selected in normal color
                SetCanvasUnselected;
                PaintSelected;

                // select just this BoardItem
                FProject.DeSelectAllItems;
                C.Selected := True;

                // redraw item in red
                SetCanvasSelected;
                PaintItem( C );

                // prepare for XOR image to follow mouse
                SetCanvasXOR;

                // record BoardItem, Original Click Pixel Coords,
                // Offset (ie position relative to reference cell) of click point
                MoveItem := C;
                MoveOriginalClientX := X;
                ClickCellOffsetX := ((X - FBorder) div PixelsPerCell) - C.X;
                MoveOriginalClientY := Y;
                ClickCellOffsetY := ((Y - FBorder) div PixelsPerCell) - C.Y;

                // record item properties for undo storage
                C.TakeSnapshot;

                // rotate click coords in opposite direction to item rotation
                // to reference click point to unrotated BoardItem at rot0.
                // Now RotY is the only coord that matters - it tells us how far
                // the click is down the BoardItem
                GetCellAt( X, Y, CellX, CellY );
                RotX := CellX;
                RotY := CellY;
                RotateReverse( RotX, RotY, MoveItem.X, MoveItem.Y, MoveItem.Rotation );

                // record point along the BoardItem where the click occurred
                ClickItemOffset := RotY - C.Y;
                // record original item length
                OriginalSizeableLength := C.Length;
                // record if clicked on reference side of item midpoint
                ClickNearestReference := (ClickItemOffset * 2) <= MoveItem.Length;

                // Record screen rectangle which encloses this component
                C.Outline.GetPaintRect( C, MoveItemsBoundaryCellRect );

                // if we have clicked on a pin, then we enter the "drag pin" mdoe
                MovePinIndex := C.Outline.PinIndexAt( C, CellX, CellY );
                //.. if no pin clicked, do orthogonal resize
                if MovePinIndex = -1  then begin
                    MouseMoveTask := mvStretchSizeable;
                end
                // else if pin clicked index=0 (reference) or index=1 (other pin),
                // do move pin - to any cell on the board. This can make the
                // component "diagonal"
                else begin
                    ClickOriginalCellX := CellX;
                    ClickOriginalCellY := CellY;
                    MouseMoveTask := mvMoveSizeablePin;
               end;
            end

            // shift-click means step thru shift values of this Break 1/2 cell to right
            else if C.Outline is TveBreakOutline and (C.Group = 0) then begin

                // get original paint rectangle
                C.Outline.GetPaintRect( C, BreakRect );

                // record original shift, for Undo
                C.TakeSnapshot;

                // perform shift operation
                case C.Shift of
                    shNone : C.Shift := shRight;
                    shRight : C.Shift := shDown;
                    shDown : C.Shift := shNone;
                end;

                // get new original paint rectangle
                C.Outline.GetPaintRect( C, Break2Rect );

                // combine original and new paint rectangles
                if BreakRect.Right < Break2Rect.Right then begin
                    BreakRect.Right := Break2Rect.Right;
                end;
                if BreakRect.Bottom < Break2Rect.Bottom then begin
                    BreakRect.Bottom := Break2Rect.Bottom;
                end;

                // repaint rectangle containing both original and altered Break
                PaintRect( BreakRect );

                // record shift for Undo
                FProject.ItemSnapshotAsUndo( C );
            end

            // shift click on SMD outline means start fine resolution single
            // component drag
            else if (C.Outline is TveSmdOutline) and (C.Group = 0) then begin
                // unselect all by repainting selected in normal color
                SetCanvasUnselected;
                PaintSelected;

                // select just this BoardItem
                FProject.DeSelectAllItems;
                C.Selected := True;

                // record item being moved
                MoveItem := C;

                // record position and rotation of this item
                C.TakeSnapshot;

                // Paint this BoardItem in selected color
                SetCanvasSelected;
                PaintItem( C );

                // ...record Original Click Pixel Coords,
                MoveOriginalClientX := X;
                MoveOriginalClientY := Y;
                ClickOriginalCellX := CellX;
                ClickOriginalCellY := CellY;
                LastDeltaCellX := 0;
                LastDeltaCellY := 0;
                MoveOriginalXDiv := C.XDiv;
                MoveOriginalYDiv := C.YDiv;

                // find rectangle containing all selected components
                // This rectangle will be used to prevent block move outside
                // board area.
                GetSelectedItemsBoundary;

                // Will have to repaint area containing moved component, so
                // record that area
                GetSelectedItemsPaintBoundary;

                // setup for XOR drawing of BoardItems during move
                SetCanvasXOR;

                // start "in motion" state machine
                MouseMoveTask := mvMoveItemFine;
            end;
        end

        // ** simple click on an item **

        // If no items selected at all or clicked on item is not selected or
        // clicked on item is only selected item, and is not part of a Group
        // then means move single item.

        else begin

            SelectedCount := FProject.GetSelectedCount;
            if  (SelectedCount = 0) or ( not C.Selected ) or
                ((SelectedCount = 1) and (C.Selected)) then begin

{
                // if item is unselected and a group, ensure it is selected
                if (C.Group <> 0) and not C.Selected then begin
                    FProject.ToggleComponentAndGroupSelection( C );
                    SetCanvasSelected;
                    PaintItemAndGroup( C );
                end;

                // start "in motion" state machine
                MouseMoveTask := mvMoveSelectedItems;

}

                // unselect all by repainting selected in normal color
                SetCanvasUnselected;
                PaintSelected;

                // select just this BoardItem and its group
                FProject.DeSelectAllItems;
//                C.Selected := True;
                FProject.ToggleComponentAndGroupSelection( C );

                // record item being moved
                MoveItem := C;

                // record position and rotation of this item
                C.TakeSnapshot;

                // Paint this BoardItem in selected color
                SetCanvasSelected;
//                PaintItem( C );
                PaintItemAndGroup( C );

                // ...record Original Click Pixel Coords,
                MoveOriginalClientX := X;
                MoveOriginalClientY := Y;
                ClickOriginalCellX := CellX;
                ClickOriginalCellY := CellY;
                LastDeltaCellX := 0;
                LastDeltaCellY := 0;

                // find rectangle containing all selected components
                // This rectangle will be used to prevent block move outside
                // board area.
                GetSelectedItemsBoundary;

                // Will have to repaint area containing moved component, so
                // record that area
                GetSelectedItemsPaintBoundary;

                // setup for XOR drawing of BoardItems during move
                SetCanvasXOR;

                // start "in motion" state machine
                if C.Group = 0 then begin
                    MouseMoveTask := mvMoveItem;
                end
                else begin
                    // record component properties for possible Undo entry
                    FProject.SnapshotSelected;
                    MouseMoveTask := mvMoveSelectedItems;
                end;
            end

            // clicked on an already selected item, so move all selected items
            // clicked on an already selected item, with multiple items selected
            // OR clicked on an item that is a member of a Group,
            // so move all selected items

            else begin
                // find repaint rectangle - including an part group members
                GetSelectedItemsPaintBoundary;

                // don't move part groups - remove them from selection
                FProject.RemovePartGroupsSelection;

                // if something left to move after eliminating part groups
                if FProject.GetSelectedCount > 0 then begin

                    // ...record Original Click Pixel Coords,
                    MoveOriginalClientX := X;
                    MoveOriginalClientY := Y;
                    ClickOriginalCellX := CellX;
                    ClickOriginalCellY := CellY;
                    LastDeltaCellX := 0;
                    LastDeltaCellY := 0;

                    // record component properties for possible Undo entry
                    FProject.SnapshotSelected;

                    // find rectangle containing all selected components
                    // This rectangle will be used to prevent block move outside
                    // board area.
                    GetSelectedItemsBoundary;

                    // setup for XOR drawing of BoardItems during move
                    SetCanvasXOR;

                    // start "in motion" state machine
                    MouseMoveTask := mvMoveSelectedItems;
                end;
            end;
        end;
    end;
end;

procedure TveEditor.MouseMove(Shift: TShiftState; X, Y: Integer);
const
    DROP_DISTANCE = 49;

var
    // distance mouse moved from mouse down point when BoardItem grabbed
    DeltaClientX, DeltaClientY : integer;
    DropDistance : integer;
    NewItemX, NewItemY : integer;

    ActiveMouseCellX, ActiveMouseCellY : integer;
    LinkX, LinkY, LinkLength : integer;
    LinkRotation : TRotation;

    // rotated click cords
    RotX, RotY : integer;

    // rubber band selection rectangle
    NewMouseCellX, NewMouseCellY : integer;
    NewBandCellX, NewBandCellY : integer;
    X1, Y1, X2, Y2 : integer;
    HalfCell : integer;

    // move selection
    DeltaCellX : integer;
    DeltaCellY : integer;
    MoveX : integer;
    MoveY : integer;
    i : integer;
    Item : TveBoardItem;
    DesignatorX, DesignatorY : integer;
    DX1, DY1, DX2, DY2 : integer;

    // stretch sizeable item
    OriginalItemX, OriginalItemY : integer;
    NewLength : integer;
    // move sizeable pin
    CurrentPinX, CurrentPinY : integer;
    NewPinX, NewPinY : integer;
    OriginalItemXY, NewItemXY : TPoint;
    OriginalItemEndDeltaXY, NewItemEndDeltaXY : TPoint;
    NewItemRect : TRect;

begin
    // calculate current Cell Coords
    NewMouseCellX := (( X - FBorder ) div PixelsPerCell);
    NewMouseCellY := (( Y - FBorder ) div PixelsPerCell);

    // update coords if changed
    if ((NewMouseCellX <> MouseCellX) or (NewMouseCellY <> MouseCellY)) then begin
        MouseCellX := NewMouseCellX;
        MouseCellY := NewMouseCellY;
        if Assigned( OnMouseCellMove ) then begin
            OnMouseCellMove( NewMouseCellX, NewMouseCellY );
        end;
    end;

    // only respond to move while left mouse button down
    if not (ssLeft in Shift) then begin
        MouseMoveTask := mvNone;
        exit;
    end;


    // if we are sizing a link
    if MouseMoveTask = mvSizeLink then begin

        // work out how far we have moved on screen, in terms of pixels
        DeltaClientX := abs( MoveOriginalClientX - X );
        DeltaClientY := abs( MoveOriginalClientY - Y );

        // if movement is within 1/4 of a cell from pixel coords of a cell, then
        // we may want to redraw the link shape

        // ... step 1 : is displacement within 1/4 of a cell from pixel coords of
        //... a cell
        DropDistance := (PixelsPerCell * DROP_DISTANCE) div 100;
        if  ((DeltaClientX mod PixelsPerCell) > DropDistance) and
            ((DeltaClientY mod PixelsPerCell) > DropDistance) then begin
            exit;
        end;

        // ... step 2 : work out link x,y and length given displacement of
        // mouse from original click position

        // step 2 if strip up-down
        if DeltaClientX <= DeltaClientY then begin

            ActiveMouseCellY := (( Y - FBorder ) div PixelsPerCell) - ClickCellOffsetY;
            LinkX := ClickCellX;
            LinkRotation := rot0;

            if ActiveMouseCellY >= ClickCellY then begin
                LinkY := ClickCellY;
                LinkLength := ActiveMouseCellY - ClickCellY;
            end
            else begin
                LinkY := ActiveMouseCellY;
                LinkLength := ClickCellY - ActiveMouseCellY;
            end;
        end

        // step 2 else strip left-right
        else begin

            ActiveMouseCellX := (( X - FBorder ) div PixelsPerCell) - ClickCellOffsetX;
            LinkY := ClickCellY;
            LinkRotation := rot90;

            if ActiveMouseCellX >= ClickCellX then begin
                LinkX := ClickCellX;
                LinkLength := ActiveMouseCellX - ClickCellX;
            end
            else begin
                LinkX := ActiveMouseCellX;
                LinkLength := ClickCellX - ActiveMouseCellX;
            end;
        end;


        // ... step 3 : if BoardItem is already drawn in the cell, then we have
        //      nothing to do
        if (DrawLink.Y = LinkY) and (DrawLink.Length = LinkLength) and
            (DrawLink.X = LinkX) and (DrawLink.Rotation = LinkRotation) then begin
            exit;
        end;

        // ... step 4 : erase BoardItem at old location
        PaintItem( DrawLink );

        // ... step 5 : draw BoardItem at new location
        DrawLink.X := LinkX;
        DrawLink.Y := LinkY;
        DrawLink.Rotation := LinkRotation;
        DrawLink.Length := LinkLength;
        PaintItem( DrawLink );
        MakeDirty;
    end

    // if we are stretching a sizeable item
    else if MouseMoveTask = mvStretchSizeable then begin

        // work out how far we have moved on screen, in terms of pixels
        DeltaClientX := abs( MoveOriginalClientX - X );
        DeltaClientY := abs( MoveOriginalClientY - Y );

        // have we moved a distance within 1/4 of a cell width ?
        // ...if not - exit
        DropDistance := (PixelsPerCell * DROP_DISTANCE) div 100;
        if ((DeltaClientX mod PixelsPerCell) > DropDistance) and
            ((DeltaClientY mod PixelsPerCell) > DropDistance)
            then begin
            exit;
        end;

        // calculate position of component origin at time of mousedown
         OriginalItemX :=
            ((MoveOriginalClientX - FBorder) div PixelsPerCell) - ClickCellOffsetX;
        OriginalItemY :=
            ((MoveOriginalClientY - FBorder) div PixelsPerCell) - ClickCellOffsetY;

        // rotate click coords in opposite direction to item rotation
        // to reference click point to unrotated BoardItem at rot0.  Now RotY
        // is the only coord that matters, because in unrotated component,
        // length is always in the Y direction.
        RotX := NewMouseCellX;
        RotY := NewMouseCellY;
        RotateReverse( RotX, RotY, OriginalItemX, OriginalItemY, MoveItem.Rotation );

        // work out new length and position of sizeable item

        //... if click was nearer component origin i.e. less than half way along
        if ClickNearestReference then begin

            // work out new length of sizeable item : position unchanged
            NewLength := OriginalSizeableLength -  RotY + OriginalItemY + ClickItemOffset;
            if (NewLength < 1) then begin
                NewLength := 1;
            end;

            // set component position in unrotated frame (length along Y direction)
            NewItemX := OriginalItemX;
            NewItemY := OriginalItemY - NewLength + OriginalSizeableLength;

            // rotate to match component rotation
            Rotate( NewItemX, NewItemY, OriginalItemX, OriginalItemY, MoveItem.Rotation );
        end

        //... else click was farther away from origin
        else begin
            // leave component origin end fixed - we stretch other end
            NewItemX := MoveItem.X;
            NewItemY := MoveItem.Y;

            // work out new length of sizeable item : position unchanged
            NewLength := OriginalSizeableLength +  RotY - MoveItem.Y - ClickItemOffset;
        end;

        // if length unchanged, nothing to do
        if NewLength = MoveItem.Length then begin
            exit;
        end;

        // erase old image
        PaintItem( MoveItem );

        // change length & position
        MoveItem.Length := NewLength;
        MoveItem.X := NewItemX;
        MoveItem.Y := NewItemY;

        // draw new image
        PaintItem( MoveItem );

        MakeDirty;
    end

    else if MouseMoveTask = mvMoveSizeablePin then begin

        // work out how far we have moved on screen, in terms of pixels
        DeltaClientX := X - MoveOriginalClientX;
        DeltaClientY := Y - MoveOriginalClientY;

        // if movement is within 1/4 of a cell from pixel coords of a cell, then
        // we want to draw the BoardItem outline in that cell

        // ... step 1 : is displacement within 1/4 of a cell from pixel coords of
        //... a cell
        DropDistance := (PixelsPerCell * DROP_DISTANCE) div 100;
        if ((abs(DeltaClientX) mod FPixelsPerCell) > DropDistance) and
            ((abs(DeltaClientY) mod FPixelsPerCell) > DropDistance) then begin
            exit;
        end;

        // ... step 2 : if BoardItem is already drawn in the cell, then we have
        //      nothing to do
        DeltaCellX := DeltaClientX div PixelsPerCell;
        DeltaCellY := DeltaClientY div PixelsPerCell;
        if (DeltaCellX = LastDeltaCellX) and (DeltaCellY = LastDeltaCellY)
            then begin
            exit;
        end;

        // calculate new pin position
        NewPinX := ClickOriginalCellX + DeltaCellX;
        NewPinY := ClickOriginalCellY + DeltaCellY;

        // if new pin position lies on top of other pin, don't do it
        // because sizeable outline code will have divide by zero error.
        // if moving reference pin over second pin
        if MovePinIndex = 0 then begin
            if (NewPinX = MoveItem.X + MoveItem.EndDeltaX) and
                (NewPinY = MoveItem.Y + MoveItem.EndDeltaY) then begin
                exit;
            end;
        end
        // else if moving second pin over first pin
        else begin
            if (NewPinX = MoveItem.X) and (NewPinY = MoveItem.Y) then begin
                exit;
            end;
        end;

        // record position of item pins
        OriginalItemXY := Point( MoveItem.X, MoveItem.Y );
        OriginalItemEndDeltaXY := Point( MoveItem.EndDeltaX, MoveItem.EndDeltaY );

        // calculate new position of pins into TPoint variables
        // NewItemXY and NewItemEndDeltaXY
          // move pin is reference pin
        if MovePinIndex = 0 then begin
            NewItemEndDeltaXY.X := MoveItem.EndDeltaX + (MoveItem.X - NewPinX);
            NewItemEndDeltaXY.Y := MoveItem.EndDeltaY + (MoveItem.Y - NewPinY);
            NewItemXY.X := NewPinX;
            NewItemXY.Y := NewPinY;
        end
        // move pin is "other" pin
        else begin
            NewItemEndDeltaXY.X :=
                MoveItem.EndDeltaX + NewPinX - (MoveItem.X + MoveItem.EndDeltaX);
            NewItemEndDeltaXY.Y :=
                MoveItem.EndDeltaY + NewPinY - (MoveItem.Y + MoveItem.EndDeltaY);
            NewItemXY.X := MoveItem.X;
            NewItemXY.Y := MoveItem.Y;
        end;

        // set component to new position
        MoveItem.EndDeltaX := NewItemEndDeltaXY.X;
        MoveItem.EndDeltaY := NewItemEndDeltaXY.Y;
        MoveItem.X := NewItemXY.X;
        MoveItem.Y := NewItemXY.Y;

        // get component screen rectangle
        MoveItem.Outline.GetScreenRectR( MoveItem, NewItemRect );

        // put component back
        MoveItem.EndDeltaX := OriginalItemEndDeltaXY.X;
        MoveItem.EndDeltaY := OriginalItemEndDeltaXY.Y;
        MoveItem.X := OriginalItemXY.X;
        MoveItem.Y := OriginalItemXY.Y;

        // if not inside our rectangle, get out
        if not ContainsRect(
                NewItemRect,
                Rect( 0, 0, FProject.BoardWidth, FProject.BoardHeight ) ) then begin
            exit;
        end;

        // now we are moving for sure, store move amount
        LastDeltaCellX := DeltaCellX;
        LastDeltaCellY := DeltaCellY;

        // erase old image
        PaintItem( MoveItem );

        // move pins
        MoveItem.EndDeltaX := NewItemEndDeltaXY.X;
        MoveItem.EndDeltaY := NewItemEndDeltaXY.Y;
        MoveItem.X := NewItemXY.X;
        MoveItem.Y := NewItemXY.Y;

        // draw new image
        PaintItem( MoveItem );

        MakeDirty;
    end

    else if MouseMoveTask = mvDrawSelectionRectangle then begin

        // work out how far we have moved on screen, in terms of pixels
        DeltaClientX := abs( MoveOriginalClientX - X );
        DeltaClientY := abs( MoveOriginalClientY - Y );

        // if movement is within 1/4 of a cell from pixel coords of a cell, then
        // we want to draw the BoardItem outline in that cell

        // ... step 1 : is displacement within 1/4 of a cell from pixel coords of
        //... a cell
        DropDistance := (PixelsPerCell * DROP_DISTANCE) div 100;
        if ((DeltaClientX mod PixelsPerCell) > DropDistance) and
            ((DeltaClientY mod PixelsPerCell) > DropDistance) then begin
            exit;
        end;

        // ... step 2 : if rubber band already drawn in the cell, then we have
        //      nothing to do
        NewBandCellX := (( X - FBorder ) div PixelsPerCell);
        NewBandCellY := (( Y - FBorder ) div PixelsPerCell);

        if (NewBandCellX = MoveLastCellX) and (NewBandCellY = MoveLastCellY)
            then begin
            exit;
        end;

        // When drawing rubber band rectangle, we draw *around* the outside
        // of the cells enclosed by the rectangle, ie on the pixels at the
        // edge of the cells.  This permits the user to see exactly what is
        // included inside the rubber band rectangle

        // ... step 3 : erase band at old location
        Canvas.MoveTo( SelectionClientRect.Left, SelectionClientRect.Top );
        Canvas.LineTo( SelectionClientRect.Right, SelectionClientRect.Top );
        Canvas.LineTo( SelectionClientRect.Right, SelectionClientRect.Bottom );
        Canvas.LineTo( SelectionClientRect.Left, SelectionClientRect.Bottom );
        Canvas.LineTo( SelectionClientRect.Left, SelectionClientRect.Top );
        // Step 4
        // work out orientation of the new rectangle we have to draw.  There are
        // 4 such orientations - we will use TRotation to describe orientation.
{
        |-----------|
        |           |    rot0   '*' shows cell bounded by initial click
        |           |               bounding rectangle corner
        |*__________|

        |-----------|
        |           |    rot90
        |           |
        |__________*|

        |-----------|
        |          *|    rot180
        |           |
        |___________|

        |-----------|
        |*          |    rot270
        |           |
        |___________|

        type TRotation = ( rot0, rot90, rot180, rot270 );
}
        // Define rectangle Coords X1,Y1 and X2,Y2 of rubber band rectangle.
        // Rubber band rectangle encloses a group of cells.
        HalfCell := PixelsPerCell div 2;

        // if mouse is to right of original Click point then rubber band
        // encloses cell whose centre point is to right of original click point
        if X > MoveOriginalClientX then begin
            X1 := ((MoveOriginalClientX - FBorder + HalfCell) div FPixelsPerCell)
                * FPixelsPerCell  + FBorder;
            X2 := ((X - FBorder + HalfCell) div FPixelsPerCell) * FPixelsPerCell + FBorder;
        end
        // else mouse is to left of original Click point and rubber band
        // encloses cell whose centre point is to left of original click point
        else begin
            X1 := ((MoveOriginalClientX - FBorder + HalfCell) div FPixelsPerCell)
                * FPixelsPerCell + FBorder;
            X2 := ((X - FBorder + HalfCell) div FPixelsPerCell) * FPixelsPerCell + FBorder;
        end;

        // if mouse is below original Click point then rubber band
        // encloses cell whose centre point is below original click point
        if Y > MoveOriginalClientY then begin
            Y1 := ((MoveOriginalClientY - FBorder + HalfCell) div FPixelsPerCell)
                * FPixelsPerCell + FBorder;
            Y2 := ((Y - FBorder + HalfCell) div FPixelsPerCell) * FPixelsPerCell + FBorder;
        end

        // else mouse is above original Click point and rubber band
        // encloses cell whose centre point is above original click point
        else begin
            Y1 := ((MoveOriginalClientY - FBorder + HalfCell) div FPixelsPerCell)
                * FPixelsPerCell + FBorder;
            Y2 := ((Y - FBorder + HalfCell) div FPixelsPerCell) * FPixelsPerCell + FBorder;
        end;

        // ... step 4b : draw rectangle at new location
        Canvas.MoveTo( X1, Y1 );
        Canvas.LineTo( X2, Y1 );
        Canvas.LineTo( X2, Y2 );
        Canvas.LineTo( X1, Y2 );
        Canvas.LineTo( X1, Y1 );

        SelectionClientRect.Left := X1;
        SelectionClientRect.Top := Y1;
        SelectionClientRect.Right := X2;
        SelectionClientRect.Bottom := Y2;
    end

    // if we are moving a selection or a single BoardItem
    else if MouseMoveTask in [mvMoveItem, mvMoveSelectedItems] then begin

        // work out how far we have moved on screen, in terms of pixels
        DeltaClientX := X - MoveOriginalClientX;
        DeltaClientY := Y - MoveOriginalClientY;

        // if movement is within DropDistance from pixel coords of a cell, then
        // we want to draw the BoardItem outline in that cell

        // ... step 1 : is displacement within DropDistance of a cell from pixel
        // ... coords of a cell
        DropDistance := (PixelsPerCell * DROP_DISTANCE) div 100;
        if ((abs(DeltaClientX) mod FPixelsPerCell) > DropDistance) and
            ((abs(DeltaClientY) mod FPixelsPerCell) > DropDistance) then begin
            exit;
        end;

        // ... step 2 : if BoardItem is already drawn in the cell, then we have
        //      nothing to do
        DeltaCellX := DeltaClientX div PixelsPerCell;
        DeltaCellY := DeltaClientY div PixelsPerCell;
        if (DeltaCellX = LastDeltaCellX) and (DeltaCellY = LastDeltaCellY)
            then begin
            exit;
        end;

        // ensure that no selected item is moved outside board boundaries
        if  (MoveItemsBoundaryCellRect.Left + DeltaCellX < 0) then begin
            DeltaCellX := - MoveItemsBoundaryCellRect.Left;
        end
        else if (MoveItemsBoundaryCellRect.Right + DeltaCellX > FProject.BoardWidth) then begin
            DeltaCellX := FProject.BoardWidth - MoveItemsBoundaryCellRect.Right;
        end;

        if (MoveItemsBoundaryCellRect.Top + DeltaCellY < 0) then begin
            DeltaCellY := - MoveItemsBoundaryCellRect.Top;
        end
        else if (MoveItemsBoundaryCellRect.Bottom + DeltaCellY > FProject.BoardHeight) then begin
            DeltaCellY := FProject.BoardHeight - MoveItemsBoundaryCellRect.Bottom;
        end;

        // ... step 3 : erase BoardItems at old location
        PaintSelected;

        // step 4a : move BoardItems to new location
        MoveX := DeltaCellX - LastDeltaCellX;
        MoveY := DeltaCellY - LastDeltaCellY;
        for i := 0 to FProject.BoardItemCount -1 do begin
            Item := FProject.BoardItems[i];
            if Item.Selected then begin
                Item.X := Item.X + MoveX;
                Item.Y := Item.Y + MoveY;
            end;
        end;

        // step 4b : draws BoardItem at new location
        PaintSelected;

        // record latest position info, ready for next movement
        LastDeltaCellX := DeltaCellX;
        LastDeltaCellY := DeltaCellY;

        // an edit happened
        MakeDirty;
    end

    // if we are moving a designator
    else if (MouseMoveTask = mvMoveDesignator) then begin

        // work out how far we have moved on screen, in terms of pixels
        DeltaClientX := X - MoveOriginalClientX;
        DeltaClientY := Y - MoveOriginalClientY;

        // if movement is within 1/4 of a cell from pixel coords of a cell, then
        // we want to draw the BoardItem outline in that cell

        // ... step 1 : is displacement within 1/4 of a cell from pixel coords of
        //... a cell
        DropDistance := (PixelsPerCell * DROP_DISTANCE) div 100;
        if ((abs(DeltaClientX) mod FPixelsPerCell) > DropDistance) and
            ((abs(DeltaClientY) mod FPixelsPerCell) > DropDistance) then begin
            exit;
        end;

        // ... step 2 : if designator is already drawn in the cell, then we have
        //      nothing to do
        DeltaCellX := DeltaClientX div PixelsPerCell;
        DeltaCellY := DeltaClientY div PixelsPerCell;
        if (DeltaCellX = LastDeltaCellX) and (DeltaCellY = LastDeltaCellY)
            then begin
            exit;
        end;

        // ... step 3 : erase Designator Rectangle at old location
        PaintDesignatorRectangle( MoveDesignatorItem );

        // step 4 : move Designator  to new location
        MoveX := DeltaCellX - LastDeltaCellX;
        MoveY := DeltaCellY - LastDeltaCellY;

        // add in movement
        MoveDesignatorItem.GetDesignatorCell( DesignatorX, DesignatorY );
        Inc( DesignatorX, MoveX );
        Inc( DesignatorY, MoveY );
        MoveDesignatorItem.SetDesignatorCell( DesignatorX, DesignatorY );

        // adjust new position to ensure designator inside board edges
        MoveDesignatorItem.SetDesignatorInsideRectangle(
            0, 0, FProject.BoardWidth, FProject.BoardHeight );

        // step 4b : draws BoardItem at new location
        PaintDesignatorRectangle( MoveDesignatorItem );

        // record latest position info, ready for next movement
        LastDeltaCellX := DeltaCellX;
        LastDeltaCellY := DeltaCellY;
    end

    // moving a single item in fine resolution
    else if MouseMoveTask = mvMoveItemFine then begin

        // ... step 3 : erase BoardItems at old location
        PaintSelected;

        // work out how far we have moved on screen, in terms of pixels
        DeltaClientX := X - MoveOriginalClientX;
        DeltaClientY := Y - MoveOriginalClientY;

        // convert screen pixels to Divs
        DX1 := ( DeltaClientX * DIVS_PER_CELL ) div FPixelsPerCell;
        DY1 := ( DeltaClientY * DIVS_PER_CELL ) div FPixelsPerCell;

        // work out new location in Divs
        MoveItem.XDiv := MoveOriginalXDiv + DX1;
        MoveItem.YDiv := MoveOriginalYDiv + DY1;

        // step 4b : draws BoardItem at new location
        PaintSelected;
    end;
end;

procedure TveEditor.MouseUp(Button: TMouseButton; Shift: TShiftState;
    X, Y: Integer);
    
    // Was total mouse movement so small we can consider it to be a simple click
    // without drag ?
    function ClickWithoutMovement : boolean;
    var
        ClientDistanceX, ClientDistanceY : integer;
        NegligibleDistance : integer;
    begin
        ClientDistanceX := Abs( MoveOriginalClientX - X );
        ClientDistanceY := Abs( MoveOriginalClientY - Y );
        NegligibleDistance := FPixelsPerCell div 4;
        result :=
            (ClientDistanceX < NegligibleDistance) and
            (ClientDistanceY < NegligibleDistance);
    end;    
    
var
    CellX1, CellY1, CellX2, CellY2 : integer;
    temp : integer;
    RedrawRect : TRect;
begin
    if MouseMoveTask = mvDrawSelectionRectangle then begin

        // if only a small mouse movement, call that a simple click outside
        // all BoardItems rather than a rectangle draw, and unselect all
        if ClickWithoutMovement then begin        
            SetCanvasUnselected;
            PaintSelected;
            FProject.DeSelectAllItems;
        end
        else begin

            // erase band at old location
            Canvas.MoveTo(
                SelectionClientRect.Left, SelectionClientRect.Top );
            Canvas.LineTo(
                SelectionClientRect.Right, SelectionClientRect.Top );
            Canvas.LineTo(
                SelectionClientRect.Right, SelectionClientRect.Bottom );
            Canvas.LineTo(
                SelectionClientRect.Left, SelectionClientRect.Bottom );
            Canvas.LineTo(
                SelectionClientRect.Left, SelectionClientRect.Top );


            // work out CellX1,CellY1 and CellX2,CellY2 for opposite corners
            // of selection rectangle
            CellX1 := (SelectionClientRect.Left - FBorder) div FPixelsPerCell;
            CellY1 := (SelectionClientRect.Top - FBorder) div FPixelsPerCell;
            CellX2 := (SelectionClientRect.Right - FBorder) div FPixelsPerCell;
            CellY2 := (SelectionClientRect.Bottom - FBorder) div FPixelsPerCell;

            // swap coords if necessary so that CellX1, CellY1 is top left
            // corner of selection rectangle and CellX2, CellY2 is bottom right
            // corner of selection rectangle.
            if (CellX1 > CellX2) then begin
                Temp := CellX1;
                CellX1 := CellX2;
                CellX2 := Temp;
            end;
            if (CellY1 > CellY2) then begin
                Temp := CellY1;
                CellY1 := CellY2;
                CellY2 := Temp;
            end;

            // store selection rectangle :
            // bottom, right coords are 1+ selected area,
            // top left coords are inside selected area
            FSelectedRect.Left := Max( CellX1, 0 );
            FSelectedRect.Top := Max( CellY1, 0 );
            FSelectedRect.Right := Min( CellX2, FProject.BoardWidth );
            FSelectedRect.Bottom := Min( CellY2, FProject.BoardHeight );
            FSelectionValid := True;

            // Adjust top, left X,Y so they include cells *outside* the
            // selection rectangle.
            // (Up to now these are top, right were actually cells *inside*
            // selection rectangle.)  This is required by calls to
            // Outline.InsideRectange below.  No idea why?                
            Dec( CellX1 );
            Dec( CellY1 );
{
            // debug : print cell coords on screen
            Canvas.Pen.Color := clBlack;
            Canvas.Pen.Style := psSolid;
            Canvas.TextOut( 0, 0, Format( '(%d,%d),(%d,%d)',
                [CellX1, CellY1, CellX2, CellY2] )
            );
}
            // find items completely inside selection rectangle and set
            // to selected. Also entire groups.
            FProject.AddComponentsAndGroupsInsideAreaToSelection( Rect(CellX1, CellY1, CellX2, CellY2) );

            // draw all selected items in highlight colour
            SetCanvasSelected;
            PaintSelected;
        end;
    end

    else if MouseMoveTask = mvMoveSelectedItems then begin

        // adjust designator positions to ensure designators inside board edges
        RescueOffBoardSelectedItemText( FProject );

        // record move for Undo tracking
        FProject.SelectedItemsSnapshotAsUndo;

        // Repaint background rectangle containing source components,
        // (Also repaints selected items without XOR)
        PaintRect( MoveItemRepaintCellRect );

        MakeDirty;
    end

    else if MouseMoveTask = mvMoveItem then begin

        // erase XOR image of item
        PaintSelected;

        // if component was rotated without moving, part of it may be offscreen,
        // so put it on screen.
        RescueOffBoardItem( MoveItem, FProject.BoardWidth, FProject.BoardHeight );

        // adjust designator position to ensure designator inside board edges
        MoveItem.SetDesignatorInsideRectangle( 0, 0, FProject.BoardWidth, FProject.BoardHeight );

        // record item movement / rotation for undo
        FProject.ItemSnapshotAsUndo( MoveItem );

        // Repaint background rectangle containing source components,
        // (Also repaints selected item (ie MoveItem)
        PaintRect( MoveItemRepaintCellRect );

        // update status bar display - if item moved
        // The updated display lacks pin information, so leave
        // mouse down info in place unless a drag occured.
        // Don't make project dirty if no movement, so that user can open a
        // file, click on an item and not be prompted to save on closing.
        if not ClickWithoutMovement then begin
            MouseClickItem( MoveItem );
            MakeDirty;
        end;

    end

    else if MouseMoveTask = mvMoveItemFine then begin

        // erase XOR image of item
        PaintSelected;

        // adjust designator position to ensure designator inside board edges
        MoveItem.SetDesignatorInsideRectangle( 0, 0, FProject.BoardWidth, FProject.BoardHeight );

        // record item movement / rotation for undo
        FProject.ItemSnapshotAsUndo( MoveItem );

        // Repaint background rectangle containing source components,
        // (Also repaints selected item (ie MoveItem)
        PaintRect( MoveItemRepaintCellRect );

        MakeDirty;
    end

    else if MouseMoveTask = mvSizeLink then begin

        // redraw rectangle containing break
        DrawLink.Outline.GetPaintRect( DrawLink, RedrawRect );
        PaintRect( RedrawRect );

        // update status bar display
        MouseClickItem( DrawLink );

        MakeDirty;
    end

    else if MouseMoveTask in [mvStretchSizeable, mvMoveSizeablePin] then begin

        // pin or body may be off board
        RescueOffBoardItem( MoveItem, FProject.BoardWidth, FProject.BoardHeight );

        // record item changes for undo
        FProject.ItemSnapshotAsUndo( MoveItem );

        // repaint rectangle containing both original and altered item
        MoveItem.Outline.GetPaintRect( MoveItem, RedrawRect );
        ExtendRectangle( RedrawRect, MoveItemsBoundaryCellRect );
        PaintRect( RedrawRect );

        // update status bar display
        MouseClickItem( MoveItem );

        // drawing is changed (probably)
        MakeDirty;
    end
    else if MouseMoveTask = mvMoveDesignator then begin

        // erase XOR image of item
        PaintDesignatorRectangle( MoveDesignatorItem );

        // record item changes for undo
        FProject.ItemSnapshotAsUndo( MoveDesignatorItem );

        // if component was rotated without moving, part of it may be offscreen,
        // so put it on screen. (not implemented)

        // Repaint background rectangle containing source component
        // This also rectangle must overlap the component with the moved
        // designator, so this component will get a redraw - including the
        // designator, even if that designator lies outside the repaint
        // rectangle
        PaintRect( MoveItemRepaintCellRect );

        // drawing is changed (probably)
        MakeDirty;
    end

    // No move task occured during move - task may have occured on mouse down,
    // but that would have been drawn at the time
    else if MouseMoveTask = mvNone then begin
        // no paint required
    end

    // all other mouse operations - actually, there should be none
    else begin
        Paint;
        // there should be no "other" mouse operations, so beep
        MessageBeep(0);
    end;

    // record that we have no job in progress
    MouseMoveTask := mvNone;

    // record that we are no longer sizing or drawing or moving BoardItems
    DrawLink := nil;
    MoveItem := nil;

    // now mouse is up, draw DRC
    EndDrawSequence;
end;

procedure TveEditor.KeyPress(var Key: Char);
begin
    if Key = ' ' then begin
        // lose keystroke
        Key := #0;

        // if no mouse operation in progress then do static rotate of selection
        if MouseMoveTask = mvNone then begin
            RotateSelected;
        end
        // otherwise, do "during move" rotation where block or item rotates
        // around the cursor point
        else begin
            RotateDuringMove;
        end;
    end
end;

procedure TveEditor.KeyDown(var Key: Word; Shift: TShiftState);
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
    else begin
        // terminate any arrow move sequences
        ArrowMove := amNone;

        if Key = VK_DELETE then begin
            DeleteSelectedItems;
        end
        else if KEY = FSelectModeKey then begin
            EditMode := emSelect;
        end
        else if KEY = FBreakModeKey then begin
            EditMode := emBreak;
        end
        else if KEY = FLinkModeKey then begin
            EditMode := emLink;
        end
        else if KEY = FWireModeKey then begin
            EditMode := emWire;
        end
        else if KEY = FTextModeKey then begin
             EditMode := emText;
        end
    end;
end;


// *** USER PRESSES KEY TO ROTATE BOARD ITEM DURING MOVE ***

procedure TveEditor.RotateDuringMove;
var
    ItemRect : TRect;
begin

    // if dragging a board item
    if (MouseMoveTask = mvMoveItem) then begin

        // must be rotatable
        if not MoveItem.Outline.Rotatable then begin
            exit;
        end;

        // erase BoardItem at old position and rotation - using XOR screen drawing
        // which is always used during move.
        PaintItem( MoveItem );

        // rotate item
        MoveItem.RotateAboutPoint(
            ClickOriginalCellX + LastDeltaCellX,
            ClickOriginalCellY + LastDeltaCellY
        );

        // find new rectangle occupied by item
        MoveItem.Outline.GetScreenRectR( MoveItem, ItemRect );

        // adjust original selection rectangle to match new component rotation
        MoveItemsBoundaryCellRect.Left := ItemRect.Left - LastDeltaCellX;
        MoveItemsBoundaryCellRect.Top := ItemRect.Top - LastDeltaCellY;
        MoveItemsBoundaryCellRect.Right := ItemRect.Right - LastDeltaCellX;
        MoveItemsBoundaryCellRect.Bottom := ItemRect.Bottom - LastDeltaCellY;

        // draw BoardItem at new position and rotation
        PaintItem( MoveItem );

        // update selected component info
        MouseClickItem( MoveItem );

        MakeDirty;
    end

    else if (MouseMoveTask = mvMoveDesignator) then begin

        // must be something to rotate
        if not ((MoveDesignatorItem.Outline.ShowsDesignator) and
            (MoveDesignatorItem.TextVisible)) then begin
            exit;
        end;

        // erase existing text rectangle by XOR drawing it
        PaintDesignatorRectangle( MoveDesignatorItem );

        // rotate designator by 90 degrees
        MoveDesignatorItem.TextRotation :=
            AddRotation( MoveDesignatorItem.TextRotation, Rot90 );

        // draw new text rectangle
        PaintDesignatorRectangle( MoveDesignatorItem );

        // drawing is changed (probably)
        MakeDirty;
    end

    // else rotate during block move
    else if (MouseMoveTask = mvMoveSelectedItems) then begin
        // paint XOR erases selected block in old rotation
        PaintSelected;
        // calculate new component positions and rotations
        BlockRotate.RotateSelected( FProject );
        // paint XOR draws selected block in new rotation
        PaintSelected;
    end;
end;

procedure TveEditor.RotateSelected;
var
    SelectedCount : integer;
begin
    if (MouseMoveTask <> mvNone) or (EditMode <> emSelect) then begin
        exit;
    end;

    SelectedCount := FProject.GetSelectedCount;

    // a single selected item gets rotated in 90 degree increments
    if SelectedCount = 1 then begin
        RotateSingleSelected;
    end

    // multiple selected items get rotated thru 180 degree increments
    else if SelectedCount > 1 then begin
        RotateMultipleSelected;
    end;
end;

// ** ROTATE SINGLE SELECTED ITEM "IN PLACE" THRU 90 DEGREES **

procedure TveEditor.RotateSingleSelected;
var
    i : integer;
    Item, SelectedItem : TveBoardItem;

    BeforeRect : TRect;
    AfterRect : TRect;
begin

    // ** this code rotates single item
    // find the selected item
    SelectedItem := nil;
    for i := 0 to FProject.BoardItemCount -1 do begin
        Item := FProject.BoardItems[i];
        if Item.Selected then begin
            SelectedItem := Item;
            break;
        end;
    end;
    // if no selected item found
    if SelectedItem = nil then begin
        exit;
    end;

    // record item rectangle before moving
    SelectedItem.Outline.GetPaintRect( SelectedItem, BeforeRect );

    // record item position, rotation before we rotate
    SelectedItem.TakeSnapshot;

    // do rotation
    SelectedItem.Outline.RotateAboutCenter( SelectedItem );

    // keep designator within board boundaries
    SelectedItem.SetDesignatorInsideRectangle( 0, 0, FProject.BoardWidth, FProject.BoardHeight );

    // record changes for Undo
    FProject.ItemSnapshotAsUndo( SelectedItem );

    // extend bound rectangle to include item bounding rectangle of new rotation
    SelectedItem.Outline.GetPaintRect( SelectedItem, AfterRect );
    ExtendRectangle( BeforeRect, AfterRect );

    // redraw rectangle which contains both pre-post rotation rectangles
    PaintRect( BeforeRect );
    EndDrawSequence;

    // update item readout to reflect changed rotation
    MouseClickItem( SelectedItem );

    MakeDirty;
end;

// ** ROTATE MULTIPLE SELECTED ITEMS "IN PLACE" THRU 180 DEGREES **

procedure TveEditor.RotateMultipleSelected;
var
    PaintRectBefore : TRect;
    PaintRectAfter : TRect;
begin
    // get area we must repaint later
    FProject.GetSelectedItemsPaintBoundary( PaintRectBefore );

    // capture component postions, rotations before changes
    FProject.SnapshotSelected;

    // perform rotation
    BlockRotate.RotateSelected( FProject );

    // pull all component text inside board edges
    RescueOffBoardSelectedItemText( FProject );

    // store changes for undo
    FProject.SelectedItemsSnapshotAsUndo;

    // get area we must repaint now
    FProject.GetSelectedItemsPaintBoundary( PaintRectAfter );

    // combine areas and paint
    ExtendRectangle( PaintRectAfter, PaintRectBefore );
    Self.PaintRect( PaintRectAfter );

    EndDrawSequence;

    MakeDirty;
end;


// ** USER PRESSES KEY TO DELETE SELECTED BOARDITEMS **

procedure TveEditor.DeleteSelectedItems;
begin
    if FProject.GetSelectedCount <= 0 then begin
        exit;
    end;

    // find repaint area enclosing items to be deleted
    GetSelectedItemsPaintBoundary;

    FProject.DeleteSelectedItemsAsUndo;

    // redraw area which contained deleted items
    PaintRect( MoveItemRepaintCellRect );

    // redraw DRC lines
    EndDrawSequence;

    MakeDirty;

    // update status bar
    MouseClickItem( nil );
end;

// ** USER PRESSES KEY TO SHIFT SELECTED BOARDITEMS **
procedure TveEditor.ArrowMoveSelected( Direction : TveArrowMove );
var
    // enclosing rectangle is 1 cell to right, bottom of occupied cells
    SelectedCount : integer;
    ItemsBoundary : TRect;
    i: Integer;
    deltaX, deltaY : integer;
    Item : TveBoardItem;
    OldPaintRectangle, NewPaintRectangle : TRect;
begin
    // must have something selected!
    SelectedCount := FProject.GetSelectedCount;
    if SelectedCount <= 0 then begin
        exit;
    end;

    // get rectangle enclosing selected items
    FProject.GetSelectedItemsBoundary( ItemsBoundary );

    // see if rectangle can be moved 1 cell in desired direction
    // This code assumes we do not move in both x and y directions!
    case Direction of
        amRight : begin
            if ItemsBoundary.Right >= FProject.BoardWidth then begin
                exit;
            end;
            deltaX := 1;
            deltaY := 0;
        end;
        amLeft : begin
            if ItemsBoundary.Left <= 0 then begin
                exit;
            end;
            deltaX := -1;
            deltaY := 0;
        end;
        amDown : begin
            if ItemsBoundary.Bottom >= FProject.BoardHeight then begin
                exit;
            end;
            deltaX := 0;
            deltaY := 1;
        end;
        amUp : begin
            if ItemsBoundary.Top <= 0 then begin
                exit;
            end;
            deltaX := 0;
            deltaY := -1;
        end
        else begin
            exit;
        end;
    end;

    // record pre-move paint rectangle
    FProject.GetSelectedItemsPaintBoundary( OldPaintRectangle );

    // record present position, text position of selected items
    FProject.SnapshotSelected;

    // move items, adjusting text position if necessary
    for i := 0 to FProject.BoardItemCount - 1 do begin
        // locate a selected item
        Item := FProject.BoardItems[i];
        if not Item.Selected then begin
            continue;
        end;

        // move item
        Item.X :=Item.X + DeltaX;
        Item.Y := Item.Y + DeltaY;
        Item.SetDesignatorInsideRectangle(
                0, 0, Project.BoardWidth, Project.BoardHeight );
    end;

    // ** alternative code put all consecutive arrow key moves into a single undo **
    // if this is first arrow move, not in a sequence
    if ArrowMove = amNone then begin

    // if this is first arrow move in this direction, not in a sequence
//    if Direction <> ArrowMove then begin
        // save movement, text movement for Undo
        FProject.SelectedItemsSnapshotAsUndo;
    end

    // continuing in a sequence of arrow key moves, so keep amending the
    // original undo record
    else begin
        // update latest Undo record
//        FProject.UpdateSnapshotSelectedAsUndoA;
          FProject.SelectedItemsSnapshotAsUndo;
    end;

    // record that we are now moving in this direction - so next time this
    // arrow key is pressed, we can detect it is a consecutive press,
    // and amend the original undo record rather than making a new Undo
    // operation for each key press.
    ArrowMove := Direction;

    // redraw area enclosing original & shifted board items
    FProject.GetSelectedItemsPaintBoundary( NewPaintRectangle );
    ExtendRectangle( NewPaintRectangle, OldPaintRectangle );
    PaintRect( NewPaintRectangle );

    // redraw DRC lines, put back buffer to screen
    EndDrawSequence;

    // record that project is altered
    MakeDirty;
end;


// ** SELECT A SINGLE ITEM **
// Offered by this object for use by external code which want to highlight
// a BoardItem

procedure TveEditor.SelectItem( Item : TveBoardItem );
begin
    FProject.DeSelectAllItems;
    Item.Selected := True;
    // update status bar
    MouseClickItem( Item );
    Paint;
end;


// *****************************************
//  SHOW & SUPPORT RIGHT-CLICK POPUP MENU
// *****************************************
{
// Right Click Menu Indexes
const
    RM_Value       = 0;
    RM_Designator  = 1;
    RM_TextVisible = 2;
    RM_LargeText   = 3;
    RM_Properties  = 4;
}
procedure TveEditor.ShowRightClickMenu( X, Y : integer );
var
    CellX, CellY : integer;
    C : TveBoardItem;
    IsTextOutline : boolean;    
begin
    // convert client to cell cords
    GetCellAt( X, Y, CellX, CellY );

    // locate BoardItem - first by Designator
    C := FProject.GetItemWithDesignatorAt( CellX, CellY );

    // if no designator found at click location, try for component body
    if C = nil then begin
        C := FProject.GetBoardItemAt( CellX, CellY );
    end;

    // event gives info on clicked board item : we get C = nil if no item
    MouseClickItemXY( C, CellX, CellY );

    // record which item clicked
    ClickedItem := C;

    // if no item clicked, right click reverts to select mode
    if C = nil then begin
        EditMode := emSelect;
        exit;
    end;

    // a component was clicked : popup menu will be shown.  User will probably
    // forget that in in Break, Link or Wire mode and mess up on next left click
    // so switch back to Select Mode.  Remove this next line if mode switch
    // turns out to be annoying.  Can't just switch mode : must raise an event
    // so that controls which show mode can be changed externally to this object.
//    FEditMode := emSelect;

    // setup menu to show/hide the Value menu item
    ItemPopupMenu.Items[RM_Designator].Visible := C.Outline.ShowsDesignator;

    // setup menu to show/hide the Designator menu item
    ItemPopupMenu.Items[RM_Value].Visible := C.Outline.ShowsValue;

    // setup menu to tick/untick the DesignatorVisible menu item
    ItemPopupMenu.Items[RM_TextVisible].Visible := C.Outline.ShowsDesignator;
    ItemPopupMenu.Items[RM_TextVisible].Checked := C.TextVisible and C.Outline.ShowsDesignator;

    // setup menu to show and tick the LargeText menu item
    IsTextOutline := ClickedItem.Outline is TveTextOutline;
    ItemPopupMenu.Items[RM_LargeText].Visible := IsTextOutline;
        ItemPopupMenu.Items[RM_LargeText].Checked :=
            TveTextOutline(ClickedItem.Outline).GetSize(ClickedItem) = tsLarge;

    // user defined components have "properties menu item"
    ItemPopupMenu.Items[RM_Properties].Visible := ClickedItem.Outline.UserDefined;

    // work out where component is on screen
    PopupPoint := ClientToScreen( Point(X, Y) );

    // show menu
    ItemPopupMenu.Popup( PopupPoint.X, PopupPoint.Y );
end;


procedure TveEditor.OnDesignatorMenu(Sender: TObject);

    // force user to enter non-blank input
    function GetNonBlank( APrompt, Default : string ) : string;
    begin
        Default := Trim(Default);
        if Default = '' then begin
            Default := '??';
        end;
        repeat
            result :=
            Trim(
                InputBoxForm.ExecutePos(
                PopupPoint.X, PopupPoint.Y,
                'VeeCAD', APrompt, Default
                )
            );
        until result <> '';
    end;

var
    OldDesignator : string;
    Prompt : string;
    ItemRect : TRect;
begin
    // record for undo
    OldDesignator := ClickedItem.Designator;
    ClickedItem.TakeSnapshot;

    // change this so diaog box is positioned
    if ClickedItem.Designator = '' then begin
        Prompt := 'Designator';
    end
    else begin
        Prompt :=
            Format('Change Designator of "%s" to:', [ClickedItem.Designator] );
    end;

    ClickedItem.Designator := GetNonBlank( Prompt, ClickedItem.Designator);

    // if item was text and got a longer string, it may extend off board
    RescueOffBoardItem( ClickedItem, FProject.BoardWidth, FProject.BoardHeight );

    // record change in Undo
    if ClickedItem.Designator <> OldDesignator then begin
      FProject.ItemSnapshotAsUndo( ClickedItem );
    end;

    // find area occupied by component
    ClickedItem.Outline.GetPaintRect( ClickedItem, ItemRect );

    // redraw item
    PaintRect( ItemRect );
    EndDrawSequence;

    // update status bar
    MouseClickItem( ClickedItem );

    // changing designator adds/removes pins : so reload netlist to pins
    FProject.TransferFastNets;

    MakeDirty;
end;

procedure TveEditor.OnValueMenu(Sender : TObject);
var
    OldValue : string;
    Prompt : string;
    ItemRect : TRect;
begin
    // store old value for undo
    OldValue := ClickedItem.Value;
    ClickedItem.TakeSnapshot;

    // change this so diaog box is positioned
    if ClickedItem.Value = '' then begin
        Prompt := 'Value';
    end
    else begin
        Prompt :=
            Format('Change Value of "%s" to:', [ClickedItem.Designator] );
    end;

    ClickedItem.Value :=
        Trim(
            InputBoxForm.ExecutePos(
            PopupPoint.X, PopupPoint.Y,
            'VeeCAD', Prompt,
            ClickedItem.Value
        )
    );

    // if item was text and got a longer string, it may extend off board
    RescueOffBoardItem( ClickedItem, FProject.BoardWidth, FProject.BoardHeight );

    // record change in Undo
    if ClickedItem.Value <> OldValue then begin
      FProject.ItemSnapshotAsUndo( ClickedItem );
    end;

    // find area occupied by component
    ClickedItem.Outline.GetPaintRect( ClickedItem, ItemRect );

    // redraw item
    PaintRect( ItemRect );
    EndDrawSequence;
    
    // update status bar
    MouseClickItem( ClickedItem );

    MakeDirty;
end;


procedure TveEditor.OnDesignatorVisibleMenu( Sender : TObject );
var
    ItemRect : TRect;
begin
    // find area originally occupied by component
    ClickedItem.Outline.GetPaintRect( ClickedItem, ItemRect );

    // for undo
    ClickedItem.TakeSnapshot;

    // toggle item's Visibility
    ClickedItem.TextVisible := not ClickedItem.TextVisible;

    // record change in Undo
    FProject.ItemSnapshotAsUndo( ClickedItem );

    // erase clicked item and redraw it
    PaintRect( ItemRect );
    EndDrawSequence;

    MakeDirty;
end;

procedure TveEditor.OnLargeTextMenu( Sender : TObject );
begin
    if ClickedItem.Outline is TveTextOutline then begin

        // store info before change for undo
        ClickedItem.TakeSnapshot;

        if TveTextOutline(ClickedItem.Outline).GetSize(ClickedItem)
            = tsSmall then begin
            TveTextOutline(ClickedItem.Outline).SetSize(ClickedItem, tsLarge);
            // larger text may extend off board, so fix that
            RescueOffBoardItem( ClickedItem, FProject.BoardWidth, FProject.BoardHeight );
        end
        else begin
            TveTextOutline(ClickedItem.Outline).SetSize(ClickedItem, tsSmall);
        end;

        // record change for undo
        FProject.ItemSnapshotAsUndo( ClickedItem );
    end;

    // show change
    Repaint;
    EndDrawSequence;

    MakeDirty;
end;

procedure TveEditor.OnPropertiesMenu(Sender: TObject);
var
    SettingsForm : TBoardItemSettingsForm;
    BeforeRect, AfterRect : TRect;
begin
    ClickedItem.Outline.GetPaintRect(ClickedItem, BeforeRect);

    SettingsForm := TBoardItemSettingsForm.Create(self);
    try
        SettingsForm.Project := FProject;
        SettingsForm.SelectItem := ClickedItem;
        SettingsForm.ShowModal;
    finally
        SettingsForm.Free;
    end;

//    Repaint;
    ClickedItem.Outline.GetPaintRect(ClickedItem, AfterRect);
    ExtendRectangle( AfterRect, BeforeRect );
    PaintRect( AfterRect );
    EndDrawSequence;

    MakeDirty
end;

// *****************************************
//       SETUP CANVAS PEN, TEXT, BRUSH
// *****************************************

procedure TveEditor.SetCanvasSelected;
begin
    DrawMode := dmSelected;
end;

procedure TveEditor.SetCanvasUnselected;
begin
    DrawMode := dmNormal;
end;

procedure TveEditor.SetCanvasXOR;
begin
    DrawMode := dmXOR;
end;


procedure TveEditor.SetCanvasXORRectangle;
begin
//    Canvas.Pen.Style := psDot;
    Canvas.Pen.Style := psSolid;

    Canvas.Pen.Mode := pmXOr;
    Canvas.Pen.Color := clYellow;
    Canvas.Pen.Width := FComponentLineWidth;
//    Canvas.Pen.Width := 2;
//    Canvas.Pen.Width := PixelsPerCell div 4;
    Canvas.Brush.Color := clWhite;
end;


// *****************************************
//              DRC
// *****************************************

// ** EndDrawSequence is used to blit all drawing changes to screen and
// add any DRC drawing on top **

(* Call EndDrawSequence when a series of edits have been drawn to the back
 buffer and it is time to
  1) show the back buffer to the user and..
  2) draw the latest DRC and NetTrace info on top
*)

{$IFDEF TIMING}
var
    performancefreq : Int64;
    performanceCount1 : Int64;
    performanceCount2 : Int64;
    performance : single;
{$ENDIF}

procedure TveEditor.EndDrawSequence;
var
    WidthPixels, HeightPixels : integer;
    CopyRect : TRect;
{
    i : integer;
    TraceNet : TneNode;
    Match : boolean;
}    
begin
{$IFDEF TIMING}
    QueryPerformanceFrequency( performancefreq );
    QueryPerformanceCounter( performanceCount1 );
{$ENDIF}

    // generate new DRC info
    FProject.ConnectivityCheck;

{$IFDEF TIMING}
    QueryPerformanceCounter( performanceCount2 );
    Performance := (performanceCount2 - performanceCount1) / performancefreq;
    asm nop end;

{$ENDIF}

    // (ScreenX1, ScreenY1) and ( ScreenX2, ScreenY2) define rectangle we need
    // to draw inside.  Units are pixels : ie canvas coords.  Even though part
    // of this rectangle may be outside the visible rectangle "Rect", we use
    // this rectangle because its top left coords start exactly at top left of
    // a cell - and we have to draw integral cells.
    WidthPixels := (Width * FPixelsPerCell) + FBorder;
    HeightPixels := (Height * FPixelsPerCell) + FBorder;

    // entire BoardPlane (tracks image) to output plane
    // must copy entire board so as to overwrite all colored net tracks
    CopyRect := Rect( 0, 0, WidthPixels, HeightPixels );
    OutputPlane.Canvas.CopyRect( CopyRect, BoardPlane.Canvas, CopyRect );

    // draw colored net tracks here
    if NetTraceVisible then begin
        PaintNetColors;
    end;

    // copy ItemPlane (components, links, text) to output plane - want
    // bitmap.transparent color
    OutputPlane.Canvas.Draw( 0, 0, ItemPlane );

    // paint overlays
    if ConnectionErrorsVisible then begin
        PaintConnectivityErrors;
    end;

    // draw colored links here
    if NetTraceVisible then begin
        PaintLinkColors;
    end;

    // draw colored net tracks here
    if NetTraceVisible then begin
          PaintNetTrace;
    end;
    
    if FFreeStripsVisible then begin
        if Project.NetList.NodeCount <= 0 then begin
            PaintFreeStripsNoNet;
        end
        else begin;
            PaintFreeStrips;
        end;
    end;

    // display it
    self.Canvas.CopyRect( CopyRect, OutputPlane.Canvas, CopyRect );
end;


// ** PaintDRC Draws Actual DRC Lines & Circles **

procedure TveEditor.PaintConnectivityErrors;

var
    Canvas : TCanvas;
    HoleDiam, HoleRadius : integer;
    Tracer : TveTracer;
    StripY, StripX : integer;
    ScreenY1, ScreenX1 : integer;
    i : integer;
    CellX1, CellX2 : integer;
    CellY1, CellY2 : integer;
    j : integer;
    Error : TcnError;
    Bridge : TcnIslandBridge;
    X1, Y1, X2, Y2 : integer;

begin
    Canvas := OutputPlane.Canvas;
    Tracer := TveTracer( FProject.ConnectivityObject );

    // DRC error circles
    Canvas.Pen.Style := psSolid;
//    Canvas.Pen.Width := 1;

    // draw directly
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Color := clRed;
    Canvas.Brush.Color := clRed;
//    HoleDiam := PixelsPerCell div 2;
//    HoleRadius := PixelsPerCell div 4;

    Canvas.Pen.Width := FComponentLineWidth;
//    Canvas.Brush.Color := clWhite;
    HoleDiam := (PixelsPerCell * 70) div 100;
    HoleRadius := (PixelsPerCell * 35) div 100;

    ScreenX1 := 0;
    ScreenY1 := 0;
    CellX1 := 0;
    CellY1 := 0;
    CellX2 := FProject.BoardWidth -1;
    CellY2 := FProject.BoardHeight -1;

    // wrong connections to a strip
    StripY := ScreenY1 + (PixelsPerCell div 2) - HoleRadius -1; // -1 why ??
    for i := CellY1 to CellY2 do begin
        StripX := ScreenX1 + (PixelsPerCell div 2) - HoleRadius -1; // -1 why    ??
        for j := CellX1 to CellX2 do begin

            if Tracer.Cells[j,i].Error then begin
                Canvas.Ellipse( StripX, StripY, StripX + HoleDiam +1, StripY + HoleDiam +1);
            end;
            Inc( StripX, PixelsPerCell );
        end;
        Inc( StripY, PixelsPerCell );
    end;

    // other errors
    HoleRadius := (PixelsPerCell * 25) div 100;
    for i := 0 to Tracer.ErrorCount - 1 do begin
        Error := Tracer.Errors[i];
        X1 := ((Error.XDiv + 500) * FPixelsPerCell) div 1000;
        Y1 := ((Error.YDiv + 500) * FPixelsPerCell) div 1000;
        Canvas.Ellipse(
            X1 - HoleRadius, Y1 - HoleRadius,
            X1 + HoleRadius, Y1 + HoleRadius );
    end;

    // DRC Bridges
    Canvas.Pen.Width := FComponentLineWidth;

    for i := 0 to Tracer.IslandBridgeCount -1
        do begin

        Bridge := Tracer.IslandBridges[i];

        X1 := ((Bridge.Line1.X + 500) * FPixelsPerCell) div 1000;
        Y1 := ((Bridge.Line1.Y + 500) * FPixelsPerCell) div 1000;
        X2 := ((Bridge.Line2.X + 500) * FPixelsPerCell) div 1000;
        Y2 := ((Bridge.Line2.Y + 500) * FPixelsPerCell) div 1000;
        Canvas.MoveTo( X1, Y1 );
        Canvas.LineTo( X2, Y2 );
    end;
end;

procedure TveEditor.PaintNetTrace;
var
    Tracer : TveTracer;
begin
    Tracer := TveTracer( FProject.ConnectivityObject );

   if Tracer.ScanType = stSimpleScan then begin
      PaintNetTraceSimple;
   end
   else begin
      PaintNetTraceFull;
   end;
end;

procedure TveEditor.PaintNetTraceSimple;
var
    Canvas : TCanvas;
    Tracer : TveTracer;
    i : integer;
    j : integer;
    X1, Y1, X2, Y2 : integer;

    StripSet : TcnStripSet;
    Strip : TcnStrip;
    Link : TcnLink;

    SegmentGroup : TbrSegmentGroup;
    k: Integer;
    Segment : TbrSegment;

begin
    Canvas := OutputPlane.Canvas;

    // DRC error circles
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;

    // draw directly
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Color := clFuchsia;
    Canvas.Brush.Color := clFuchsia;

    // *** NET PINS & STRIPS DISPLAY ***
    Canvas.Pen.Width := (FComponentLineWidth * 3) div 2;
    Canvas.Pen.Width := (FComponentLineWidth * 2);

    Tracer := TveTracer( FProject.ConnectivityObject );

    Strip := Tracer.StripAt(ClickCellX, ClickCellY);
    if Strip = nil then begin
        exit;
    end;
    StripSet := Tracer.StripAt(ClickCellX, ClickCellY).StripSet;
    if StripSet = nil then begin
        exit;
    end;

    // strips
    for j := 0 to StripSet.Count -1 do begin
        Strip := StripSet.Strips[j];
        X1 := Strip.Start.X * FPixelsPerCell + (FPixelsPerCell div 2);
        Y1 := Strip.Start.Y * FPixelsPerCell + (FPixelsPerCell div 2);
        X2 := Strip.Finish.X * FPixelsPerCell + (FPixelsPerCell div 2);
        Y2 := Strip.Finish.Y * FPixelsPerCell + (FPixelsPerCell div 2);
        Canvas.MoveTo( X1, Y1 );
        Canvas.LineTo( X2, Y2 );
    end;
    // for each segment group
    for j := 0 to StripSet.SegmentGroupCount - 1 do begin
        SegmentGroup := StripSet.SegmentGroups[j];
        // for each segment in the group
        for k := 0 to SegmentGroup.Count - 1 do begin
            Segment := SegmentGroup.Segments[k];
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

    // links which belong to our net
    for i := 0 to Tracer.LinkCount - 1 do begin
        Link := Tracer.Links[i];
        if Link.StartStrip.StripSet = StripSet then begin
            X1 := Link.StartX * PixelsPerCell + (FPixelsPerCell div 2);
            Y1 := Link.StartY * PixelsPerCell + (FPixelsPerCell div 2);
            X2 := Link.EndX * PixelsPerCell + (FPixelsPerCell div 2);
            Y2 := Link.EndY * PixelsPerCell + (FPixelsPerCell div 2);
            Canvas.MoveTo( X1, Y1 );
            Canvas.LineTo( X2, Y2 );
        end;
    end;

    Canvas.Pen.Width := FComponentLineWidth;
end;

procedure TveEditor.PaintNetTraceFull;
var
    Canvas : TCanvas;
    HoleDiam, HoleRadius : integer;

    Connectivity : TConnectivity;
    StripY, StripX : integer;
    ScreenY1, ScreenX1 : integer;
    i : integer;
    CellX1, CellX2 : integer;
    CellY1, CellY2 : integer;
    j : integer;
    X1, Y1, X2, Y2 : integer;

    StripSet : TcnStripSet;
    Strip : TcnStrip;
    Link : TcnLink;

    PinData : TcnCellData;
    TraceNet : TneNode;
    PinIndex : Integer;

    SegmentGroup : TbrSegmentGroup;
    k: Integer;
    Segment : TbrSegment;
//{$DEFINE SMDPINTRACE}
{$IFDEF SMDPINTRACE}
    Item : TveBoardItem;
    Outline : TveOutline;
    PinRect : TRect;
    ErrorXDiv, ErrorYDiv : integer;
    XS, YS : integer;
{$ENDIF}
begin
    Canvas := OutputPlane.Canvas;
    Connectivity := TConnectivity( FProject.ConnectivityObject );

    // DRC error circles
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;

    // draw directly
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Color := clFuchsia;
    Canvas.Brush.Color := clFuchsia;
{
    Canvas.Pen.Color := clAqua;
    Canvas.Brush.Color := clAqua;
}
    HoleDiam := PixelsPerCell div 3;
    HoleRadius := PixelsPerCell div 6;


   // *** NET PINS & STRIPS DISPLAY ***
    Canvas.Pen.Width := (FComponentLineWidth * 3) div 2;
    Canvas.Pen.Width := (FComponentLineWidth * 2);

    TraceNet := FProject.TraceNet;
    if TraceNet = nil then begin
        exit;
    end;

    // Strips and Segments which belong to our net
    for i := 0 to Connectivity.StripSetCount -1 do begin
        StripSet := Connectivity.StripSets[i];
        if StripSet.Net = TraceNet then begin

            // strips
            for j := 0 to StripSet.Count -1 do begin
                Strip := StripSet.Strips[j];
                X1 := Strip.Start.X * FPixelsPerCell + (FPixelsPerCell div 2);
                Y1 := Strip.Start.Y * FPixelsPerCell + (FPixelsPerCell div 2);
                X2 := Strip.Finish.X * FPixelsPerCell + (FPixelsPerCell div 2);
                Y2 := Strip.Finish.Y * FPixelsPerCell + (FPixelsPerCell div 2);
                Canvas.MoveTo( X1, Y1 );
                Canvas.LineTo( X2, Y2 );
            end;
            // for each segment group
            for j := 0 to StripSet.SegmentGroupCount - 1 do begin
                SegmentGroup := StripSet.SegmentGroups[j];
                // for each segment in the group
                for k := 0 to SegmentGroup.Count - 1 do begin
                    Segment := SegmentGroup.Segments[k];
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

    // links which belong to our net
    for i := 0 to Connectivity.LinkCount - 1 do begin
        Link := Connectivity.Links[i];
        if Link.StartStrip.StripSet.Net = TraceNet then begin
            X1 := Link.StartX * PixelsPerCell + (FPixelsPerCell div 2);
            Y1 := Link.StartY * PixelsPerCell + (FPixelsPerCell div 2);
            X2 := Link.EndX * PixelsPerCell + (FPixelsPerCell div 2);
            Y2 := Link.EndY * PixelsPerCell + (FPixelsPerCell div 2);
            Canvas.MoveTo( X1, Y1 );
            Canvas.LineTo( X2, Y2 );
        end;
    end;

    // pins which belong to our net
    ScreenX1 := 0;
    ScreenY1 := 0;
    CellX1 := 0;
    CellY1 := 0;
    CellX2 := FProject.BoardWidth -1;
    CellY2 := FProject.BoardHeight -1;

    StripY := ScreenY1 + (PixelsPerCell div 2) - HoleRadius -1; // -1 why ??
    for i := CellY1 to CellY2 do begin
        StripX := ScreenX1 + (PixelsPerCell div 2) - HoleRadius -1; // -1 why    ??
        for j := CellX1 to CellX2 do begin
            PinData := Connectivity.Cells[j,i];
            if (PinData.PinCount > 0) {and (not PinData.Error)} then begin
                for PinIndex := 0 to PinData.PinCount - 1 do begin
                      if PinData.Pins[PinIndex].Item.NodeAtPin[PinData.Pins[PinIndex].PinIndex] = TraceNet then begin
                          Canvas.Ellipse( StripX, StripY, StripX + HoleDiam +1, StripY + HoleDiam +1);
                          break;
                      end;
                end;
            end;
            Inc( StripX, PixelsPerCell );
        end;
        Inc( StripY, PixelsPerCell );
    end;

    // SMD pin which belong to our net
    // for every item
    //    if item has SMD outline
    //        ToFirstPin
    //        GetNextPinDiv to find pin location and index
    //        NodeAtPin to find node
    //        if node is TraceNet then draw a circle at pin location
    // - we'd have to iterate throught

{$IFDEF SMDPINTRACE}
    for i := 0 to FProject.BoardItemCount - 1 do begin
        Item := FProject.BoardItems[i];
        if Item.Outline is TveSmdOutline then begin
            Outline := Item.Outline;
            Outline.ToFirstPin;
            while TveSmdOutline(Outline).GetNextPinDiv( Item, PinRect, PinIndex ) do begin
                if Item.NodeAtPin[ PinIndex ] = TraceNet then begin
                    ErrorXDiv := (PinRect.Left + PinRect.Right) div 2;
                    ErrorYDiv := (PinRect.Top + PinRect.Bottom) div 2;
                    XS := ((ErrorXDiv + 500) * FPixelsPerCell) div 1000;
                    YS := ((ErrorYDiv + 500) * FPixelsPerCell) div 1000;
                    Canvas.Ellipse(
                        XS - HoleRadius, YS - HoleRadius,
                        XS + HoleRadius, YS + HoleRadius );
                end;
            end;
        end;
    end;
{$ENDIF}

    Canvas.Pen.Width := FComponentLineWidth;
end;


//{$DEFINE NEW}
{$IFDEF NEW}
procedure TveEditor.PaintNetTrace;
var
    Canvas : TCanvas;
    HoleDiam, HoleRadius : integer;

    Connectivity : TConnectivity;
    StripY, StripX : integer;
    ScreenY1, ScreenX1 : integer;
    i : integer;
    CellX1, CellX2 : integer;
    CellY1, CellY2 : integer;
    j : integer;
    X1, Y1, X2, Y2 : integer;

    StripSet : TcnStripSet;
    Strip : TcnStrip;
    Link : TcnLink;

    PinData : TcnCellData;
    TraceNet : TneNode;
    PinIndex : Integer;

    SegmentGroup : TbrSegmentGroup;
    k: Integer;
    Segment : TbrSegment;
//{$DEFINE SMDPINTRACE}
{$IFDEF SMDPINTRACE}
    Item : TveBoardItem;
    Outline : TveOutline;
    PinRect : TRect;
    ErrorXDiv, ErrorYDiv : integer;
    XS, YS : integer;
{$ENDIF}
begin
    Canvas := OutputPlane.Canvas;
    Connectivity := TConnectivity( FProject.ConnectivityObject );

    // DRC error circles
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;

    // draw directly
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Color := clFuchsia;
    Canvas.Brush.Color := clFuchsia;
{
    Canvas.Pen.Color := clAqua;
    Canvas.Brush.Color := clAqua;
}
    HoleDiam := PixelsPerCell div 3;
    HoleRadius := PixelsPerCell div 6;


   // *** NET PINS & STRIPS DISPLAY ***
//    Canvas.Pen.Width := (FComponentLineWidth * 3) div 2;
    Canvas.Pen.Width := (FComponentLineWidth * 2);

    TraceNet := FProject.TraceNet;

    if TraceNet <> nil then begin

        // Strips and Segments which belong to our net
        StripSet := Connectivity.StripSetByNode( TraceNet );

        if StripSet <> nil then begin

            // strips
            for j := 0 to StripSet.Count -1 do begin
                Strip := StripSet.Strips[j];
                X1 := Strip.Start.X * FPixelsPerCell + (FPixelsPerCell div 2);
                Y1 := Strip.Start.Y * FPixelsPerCell + (FPixelsPerCell div 2);
                X2 := Strip.Finish.X * FPixelsPerCell + (FPixelsPerCell div 2);
                Y2 := Strip.Finish.Y * FPixelsPerCell + (FPixelsPerCell div 2);
                Canvas.MoveTo( X1, Y1 );
                Canvas.LineTo( X2, Y2 );
            end;

            // for each segment group
            for j := 0 to StripSet.SegmentGroupCount - 1 do begin
                SegmentGroup := StripSet.SegmentGroups[j];
                // for each segment in the group
                for k := 0 to SegmentGroup.Count - 1 do begin
                    Segment := SegmentGroup.Segments[k];
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

        // links which belong to our net
        for i := 0 to Connectivity.LinkCount - 1 do begin
            Link := Connectivity.Links[i];
            if Link.StartStrip.StripSet = StripSet then
                X1 := Link.StartX * PixelsPerCell + (FPixelsPerCell div 2);
                Y1 := Link.StartY * PixelsPerCell + (FPixelsPerCell div 2);
                X2 := Link.EndX * PixelsPerCell + (FPixelsPerCell div 2);
                Y2 := Link.EndY * PixelsPerCell + (FPixelsPerCell div 2);
                Canvas.MoveTo( X1, Y1 );
                Canvas.LineTo( X2, Y2 );
            end;
        end;

        // pins which belong to our net
        ScreenX1 := 0;
        ScreenY1 := 0;
        CellX1 := 0;
        CellY1 := 0;
        CellX2 := FProject.BoardWidth -1;
        CellY2 := FProject.BoardHeight -1;

        StripY := ScreenY1 + (PixelsPerCell div 2) - HoleRadius -1; // -1 why ??
        for i := CellY1 to CellY2 do begin
            StripX := ScreenX1 + (PixelsPerCell div 2) - HoleRadius -1; // -1 why    ??
            for j := CellX1 to CellX2 do begin
                PinData := Connectivity.Cells[j,i];
                if (PinData.PinCount > 0) {and (not PinData.Error)} then begin
                    for PinIndex := 0 to PinData.PinCount - 1 do begin
                          if PinData.Pins[PinIndex].Item.NodeAtPin[PinData.Pins[PinIndex].PinIndex] = TraceNet then begin
                              Canvas.Ellipse( StripX, StripY, StripX + HoleDiam +1, StripY + HoleDiam +1);
                              break;
                          end;
                    end;
                end;
                Inc( StripX, PixelsPerCell );
            end;
            Inc( StripY, PixelsPerCell );
        end;

        // SMD pin which belong to our net
        // for every item
        //    if item has SMD outline
        //        ToFirstPin
        //        GetNextPinDiv to find pin location and index
        //        NodeAtPin to find node
        //        if node is TraceNet then draw a circle at pin location
        // - we'd have to iterate through

{$IFDEF SMDPINTRACE}
        for i := 0 to FProject.BoardItemCount - 1 do begin
            Item := FProject.BoardItems[i];
            if Item.Outline is TveSmdOutline then begin
                Outline := Item.Outline;
                Outline.ToFirstPin;
                while TveSmdOutline(Outline).GetNextPinDiv( Item, PinRect, PinIndex ) do begin
                    if Item.NodeAtPin[ PinIndex ] = TraceNet then begin
                        ErrorXDiv := (PinRect.Left + PinRect.Right) div 2;
                        ErrorYDiv := (PinRect.Top + PinRect.Bottom) div 2;
                        XS := ((ErrorXDiv + 500) * FPixelsPerCell) div 1000;
                        YS := ((ErrorYDiv + 500) * FPixelsPerCell) div 1000;
                        Canvas.Ellipse(
                            XS - HoleRadius, YS - HoleRadius,
                            XS + HoleRadius, YS + HoleRadius );
                    end;
                end;
            end;
        end;
{$ENDIF}
    end;

    Canvas.Pen.Width := FComponentLineWidth;
end;
{$ENDIF}

// ***** THIS PROCEDURE NOT CALLED - INCLUDED IN PaintNetTrace() *****

procedure TveEditor.PaintPinTrace;
var
    Canvas : TCanvas;
    HoleDiam, HoleRadius : integer;

    Connectivity : TConnectivity;

    StripY, StripX : integer;
    ScreenY1, ScreenX1 : integer;
    i : integer;
    CellX1, CellX2 : integer;
    CellY1, CellY2 : integer;
    j : integer;

    PinData : TcnCellData;
    PinIndex : integer;

    TraceNet : TneNode;

begin
    Canvas := OutputPlane.Canvas;
    Connectivity := TConnectivity( FProject.ConnectivityObject );

    // DRC error circles
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;

    // draw directly
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Color := clFuchsia;
    Canvas.Brush.Color := clFuchsia;

{
    Canvas.Pen.Color := clAqua;
    Canvas.Brush.Color := clAqua;
}

    HoleDiam := PixelsPerCell div 3;
    HoleRadius := PixelsPerCell div 6;


   // *** NET PINS & STRIPS DISPLAY ***
//    Canvas.Pen.Width := (FComponentLineWidth * 3) div 2;
    Canvas.Pen.Width := (FComponentLineWidth * 2);

    TraceNet := FProject.TraceNet;
    if TraceNet <> nil then begin

        // pins which belong to our net
        ScreenX1 := 0;
        ScreenY1 := 0;
        CellX1 := 0;
        CellY1 := 0;
        CellX2 := FProject.BoardWidth -1;
        CellY2 := FProject.BoardHeight -1;

        StripY := ScreenY1 + (PixelsPerCell div 2) - HoleRadius -1; // -1 why ??
        for i := CellY1 to CellY2 do begin
            StripX := ScreenX1 + (PixelsPerCell div 2) - HoleRadius -1; // -1 why    ??
            for j := CellX1 to CellX2 do begin
                PinData := Connectivity.Cells[j,i];
                if (PinData.PinCount > 0) {and (not PinData.Error)} then begin
                    for PinIndex := 0 to PinData.PinCount - 1 do begin
                          if PinData.Pins[PinIndex].Item.NodeAtPin[PinData.Pins[PinIndex].PinIndex] = TraceNet then begin
                              Canvas.Ellipse( StripX, StripY, StripX + HoleDiam +1, StripY + HoleDiam +1);
                              break;
                          end;
                    end;
                end;
                Inc( StripX, PixelsPerCell );
            end;
            Inc( StripY, PixelsPerCell );
        end;
    end;

    Canvas.Pen.Width := FComponentLineWidth;
end;


procedure TveEditor.PaintFreeStrips;
var
    Canvas : TCanvas;
    Connectivity : TConnectivity;
    i : integer;
    StripSet : TcnStripSet;
    Strip : TcnStrip;
    X1, Y1, X2, Y2 : integer;
  j: Integer;

begin
    Canvas := OutputPlane.Canvas;
    Connectivity := TConnectivity( FProject.ConnectivityObject );

    // DRC error circles
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;

    // draw directly
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Color := clBlue;

    // stripsets which belong to our net
    for i := 0 to Connectivity.StripSetCount - 1 do begin
        StripSet := Connectivity.StripSets[i];
        if StripSet.Status = nsAvailable then begin

            for j := 0 to StripSet.Count - 1 do begin
                Strip := StripSet.Strips[j];
                X1 := Strip.Start.X * FPixelsPerCell + (FPixelsPerCell div 2);
                Y1 := Strip.Start.Y * FPixelsPerCell + (FPixelsPerCell div 2);
                X2 := Strip.Finish.X * FPixelsPerCell + (FPixelsPerCell div 2);
                Y2 := Strip.Finish.Y * FPixelsPerCell + (FPixelsPerCell div 2);
                Canvas.MoveTo( X1, Y1 );
                Canvas.LineTo( X2, Y2 );
            end;
        end;
    end;
end;

procedure TveEditor.PaintFreeStripsNoNet;
var
    Canvas : TCanvas;
    Connectivity : TConnectivity;
    i : integer;
    Strip : TcnStrip;
    x, y : integer;
    Cell : TcnCellData;
    X1, Y1, X2, Y2 : integer;
begin
    Canvas := OutputPlane.Canvas;
    Connectivity := TConnectivity( FProject.ConnectivityObject );

    // DRC error circles
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;

    // draw directly
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Color := clBlue;

    for i := 0 to Connectivity.StripCount - 1 do begin
        Strip := Connectivity.Strips[i];

        // if a strip has no pins then FirstPin will be placed at the default
        // position at the start of the strip. It will have NO PINS in its Cell
        x := Strip.FirstPin.x;
        y := Strip.FirstPin.y;
        Cell := Connectivity.Cells[x,y];
        if Cell.PinCount = 0 then begin
                X1 := Strip.Start.X * FPixelsPerCell + (FPixelsPerCell div 2);
                Y1 := Strip.Start.Y * FPixelsPerCell + (FPixelsPerCell div 2);
                X2 := Strip.Finish.X * FPixelsPerCell + (FPixelsPerCell div 2);
                Y2 := Strip.Finish.Y * FPixelsPerCell + (FPixelsPerCell div 2);
                Canvas.MoveTo( X1, Y1 );
                Canvas.LineTo( X2, Y2 );
        end;
    end;
end;


procedure TveEditor.PaintNetColors;
var
    Canvas : TCanvas;
    Connectivity : TConnectivity;

    // Paint Strips and Segments that belong to our Node, in Color
    procedure PaintColor( Node : TneNode; Color : TColor );
    var
      j : integer;
      StripSet : TcnStripSet;
   begin

      // Strips and Segments which belong to our net
      for j := 0 to Connectivity.StripSetCount -1 do begin
          StripSet := Connectivity.StripSets[j];

          if StripSet.Net = Node then begin
              Canvas.Pen.Color := Color;
              BoardPainterNetColor.PaintStripSet( Canvas, StripSet );
          end;
      end;
  end;


var
    SavePenWidth : integer;
    i : integer;
    Node : TneNode;
begin

    Canvas := OutputPlane.Canvas;

    SavePenWidth := Canvas.Pen.Width;
    Canvas.Pen.Width := (FComponentLineWidth * 10) div 2;
    Canvas.Pen.Mode := pmCopy;

    Connectivity := TConnectivity( FProject.ConnectivityObject );
    for i := 0 to TneNetlist.ColoredNodeCount - 1 do begin

        Node := Project.Netlist.ColoredNodes[i];
        // don't paint if TraceNet is painting the strips
        if (Node = nil) or (Node = FProject.TraceNet) then begin
            continue;
        end;

        PaintColor( Node, NodeColors[i] );
    end;

    // restore resource
    Canvas.Pen.Width := SavePenWidth;
end;


procedure TveEditor.PaintLinkColors;
var
    Canvas : TCanvas;
    SavePenWidth : integer;
    Connectivity : TConnectivity;
    i : integer;
    Node : TneNode;
    j : integer;
    Link : TcnLink;
    X1, Y1, X2, Y2 : integer;
begin
    Canvas := OutputPlane.Canvas;

    SavePenWidth := Canvas.Pen.Width;

    Canvas.Pen.Width := FPixelsPerCell div 6;
    Canvas.Pen.Mode := pmCopy;

    Connectivity := TConnectivity( FProject.ConnectivityObject );
    for i := 0 to TneNetlist.ColoredNodeCount - 1 do begin

        Node := Project.Netlist.ColoredNodes[i];
        // don't paint if TraceNet is painting the strips
        if (Node = nil) or (Node = FProject.TraceNet) then begin
            continue;
        end;

        Canvas.Pen.Color := NodeColors[i];

        // links which belong to our net
        for j := 0 to Connectivity.LinkCount - 1 do begin
            Link := Connectivity.Links[j];
            if Link.StartStrip.StripSet.Net = Node then begin
                X1 := Link.StartX * PixelsPerCell + (FPixelsPerCell div 2);
                Y1 := Link.StartY * PixelsPerCell + (FPixelsPerCell div 2);
                X2 := Link.EndX * PixelsPerCell + (FPixelsPerCell div 2);
                Y2 := Link.EndY * PixelsPerCell + (FPixelsPerCell div 2);
                Canvas.MoveTo( X1, Y1 );
                Canvas.LineTo( X2, Y2 );
            end;
        end;
    end;

    // restore resource
    Canvas.Pen.Width := SavePenWidth;
end;


// *****************************************
//          PAINT BOARD & ITEMS
// *****************************************

procedure TveEditor.Paint;
var
    FullRect : TRect;
    ClipRect : TRect;
    PaintCellRect : TRect;
    H : HDC;
    Origin: TPoint;
 begin
    // set TPaintbox or TCustomControl dimensions : 2 extra pixels for border
    Width := (FProject.BoardWidth * FPixelsPerCell) +2;
    Height := (FProject.BoardHeight * FPixelsPerCell) +2;
    FullRect := Rect( 0, 0, Width, Height );

    // item buffer to same dimensions and make it transparent
    ItemPlane.Width := Width;
    ItemPlane.Height := Height;
    ItemPlane.Transparent := True;
    ItemPlane.TransparentColor := TRANSPARENT_COLOR;

    // output buffer to same dimensions
    OutputPlane.Width := Width;
    OutputPlane.Height := Height;

    // set board buffer to same dimensions
    BoardPlane.Width := Width;
    BoardPlane.Height := Height;

    // the board is painted from connectivity info, so have to we generate info
    // even though EndDrawSequence() will generate it again. That will not
    // spoil performance, because Paint() is not called during normal editing.
    FProject.ConnectivityCheck;

    // get Board Bitmap to resize, because Paint must reset everything, since it
    // it is called when zooming, loading new board, major changes.
    // Then paint a plain track pattern on Board Bitmap, without colored tracks.
    // This image will be blitted onto the output image as the first action when
    // drawing during editing, where speed is important.

//    PREVIOUSLY PAINTED FROM CONNECTIVITY - but that wrongly shows missing
//    copper around a break symbol.
//    BoardPainterNetColor.PixelsPerCell := FPixelsPerCell;
//    BoardPainterNetColor.Paint( BoardPlane.Canvas, TConnectivity(Project.ConnectivityObject) );

    // paint board without connectivity changes
    BoardPainter.PixelsPerCell := FPixelsPerCell;
    BoardPainter.Paint( BoardPlane.Canvas, FProject.Board );

    // only need to paint inside this rectangle
    ClipRect := Canvas.ClipRect;
    H := Canvas.Handle;
    GetDCOrgEx( H, Origin );

    // visible screen area in cell coords.  Part of this rectangle of cells
    // may be partly hidden, but all should be drawn
    PaintCellRect.Left := (ClipRect.Left - FBorder) div FPixelsPerCell;
    PaintCellRect.Top := (ClipRect.Top - FBorder) div FPixelsPerCell;
    // ... CellX2 needs to be 1 more otherwise not entire visible area drawn
    PaintCellRect.Right := 1+ (ClipRect.Right - FBorder) div FPixelsPerCell;
    PaintCellRect.Bottom := 1+ (ClipRect.Bottom - FBorder) div FPixelsPerCell;

    PaintRect( PaintCellRect );

    // no need to call inherited Paint - does nothing in TCustomContol
    //inherited Paint;

    EndDrawSequence;
end;


// *****************************************
//    PAINT BOARD & ITEMS INSIDE RECTANGLE
// *****************************************

procedure TveEditor.PaintRect( const R : TRect );
var
    Canvas : TCanvas;
    DrawRect : TRect;

    i : integer;
    Item : TveBoardItem;

    ScreenX1, ScreenY1, ScreenX2, ScreenY2 : integer;
    RX1, RY1, RX2, RY2 : integer;
begin
{
    Notes on DC := Canvas.Handle; : If the call to Paint is in response to a
    WM_Paint message, then Handle is got with a call to BeginPaint(). If Paint
    is called outside a WM_Paint message, then the handle is got with GetDC().
    Thus at all times, Canvas.Handle will return a valid handle.

    The DC := Canvas.Handle is directly that provided by Windows, and the VCL
    does not own its Pen, Brush or Font which are the default ones supplied by
    Windows with any DC. Providing no TCanvas drawing functions such as
    TCanvas.TextOut() or TCanvas.LineTo() are called, the VCL will not select
    any pens, brushes or fonts into this DC.
}
    Canvas := ItemPlane.Canvas;


    // (ScreenX1, ScreenY1) and ( ScreenX2, ScreenY2) define rectangle we need
    // to draw inside.  Units are pixels : ie canvas coords.  Even though part
    // of this rectangle may be outside the visible rectangle "Rect", we use
    // this rectangle because its top left coords start exactly at top left of
    // a cell - and we have to draw integral cells.
    ScreenX1 := (R.Left * FPixelsPerCell) + FBorder;
    ScreenY1 := (R.Top * FPixelsPerCell) + FBorder;
    ScreenX2 := (R.Right * FPixelsPerCell) + FBorder;
    ScreenY2 := (R.Bottom * FPixelsPerCell) + FBorder;

    // Copy required portion of board image (strips, holes) to buffer
    DrawRect := Rect( ScreenX1, ScreenY1, ScreenX2, ScreenY2 );

    // erase ItemPlane where components are redrawn
    ItemPlane.Canvas.Brush.Color := TRANSPARENT_COLOR;
    ItemPlane.Canvas.FillRect( DrawRect );

    // draw BoardItems

    //... calculate rectangle one cell larger than "draw" area, because
    //... strip redraw eat slightly more than we expect. (why?) Because
    //... white strips live on both sides of the border between two cells?
    RX1 := R.Left - 1;
    RY1 := R.Top - 1;
    RX2 := R.Right + 1;
    RY2 := R.Bottom + 1;

    //... draw unselected BoardItems
    Painter.Clear;
    UpdatePaintInfo;
    for i := 0 to FProject.BoardItemCount -1 do begin
        Item := FProject.BoardItems[i];
        if Item.Outline.PaintOverlapsRectangle( Item, Rect(RX1, RY1, RX2, RY2) )
        and not Item.Selected then begin
            Item.Outline.Paint( Item, Painter );
        end;
    end;
    Painter.PaintNormal( Canvas );

    //... draw selected BoardItems
    Painter.Clear;
    for i := 0 to FProject.BoardItemCount -1 do begin
        Item := FProject.BoardItems[i];
        if Item.Selected then begin
            Item.Outline.Paint( Item, Painter );
        end;
    end;
    Painter.PaintSelected( Canvas );
end;

procedure TveEditor.PaintSelected;
var
    i : integer;
    Item : TveBoardItem;
begin
    Painter.Clear;
    UpdatePaintInfo;
    Painter.Options := [];
    try
        if DrawMode = dmXOR then begin
            Painter.Options := [poXOR];
        end;

        for i := 0 to FProject.BoardItemCount -1 do begin
            Item := FProject.BoardItems[i];
            if Item.Selected then begin
                Item.Outline.Paint( Item, Painter );
            end;
        end;

        case DrawMode of
            dmNormal : begin
                Painter.PaintNormal( ItemPlane.Canvas );
                EndDrawSequence;
            end;
            dmSelected : begin
                Painter.PaintSelected( ItemPlane.Canvas );
                EndDrawSequence;
            end;
            dmXOR : begin
                Painter.PaintXOR( Canvas );
            end;
        end;

    finally
        Painter.Options := [];
    end;
end;

procedure TveEditor.PaintItem( Item : TveBoardItem );
begin
    Painter.Clear;
    UpdatePaintInfo;

// hack for now - need to sort out drag vs XOR
    if DrawMode = dmXOR then begin
        Painter.Options := [poXOR];
    end;

    Item.Outline.Paint( Item, Painter );

    case DrawMode of
        dmNormal : begin
            Painter.PaintNormal( ItemPlane.Canvas );
            EndDrawSequence;
        end;
        dmSelected : begin
            Painter.PaintSelected( ItemPlane.Canvas );
            EndDrawSequence;
        end;
        dmXOR : Painter.PaintXOR( Canvas );
    end;
end;

procedure TveEditor.PaintItemAndGroup( Item : TveBoardItem );
var
    PaintItem : TveBoardItem;
    GroupNo : integer;
    i : integer;
begin
    Painter.Clear;
    UpdatePaintInfo;

// hack for now - need to sort out drag vs XOR
    if DrawMode = dmXOR then begin
        Painter.Options := [poXOR];
    end;

    // load all items in group into Painter
    GroupNo := Item.Group;

    // ..single item with no group
    if GroupNo = 0 then begin
        Item.Outline.Paint( Item, Painter );
    end

    // ..else group - paint all items in group
    else begin
        for i := 0 to FProject.BoardItemCount - 1 do begin
            PaintItem := FProject.BoardItems[i];
            if PaintItem.Group = GroupNo then begin
                PaintItem.Outline.Paint( PaintItem, Painter );
            end;
        end;
    end;

    // Paint
    case DrawMode of
        dmNormal : begin
            Painter.PaintNormal( ItemPlane.Canvas );
            EndDrawSequence;
        end;
        dmSelected : begin
            Painter.PaintSelected( ItemPlane.Canvas );
            EndDrawSequence;
        end;
        dmXOR : Painter.PaintXOR( Canvas );
    end;
end;


procedure TveEditor.PaintDesignatorRectangle( Item : TveBoardItem );
var
    RotationX, RotationY : integer;
    Rotation : TRotation;

    procedure MoveTo( X, Y : integer );
    begin
        Rotate( X, Y, RotationX, RotationY, Rotation );
        Canvas.MoveTo( X, Y );
    end;

    procedure LineTo( X, Y : integer );
    begin
        Rotate( X, Y, RotationX, RotationY, Rotation );
        Canvas.LineTo( X, Y );
    end;

var
    TextX, TextY : integer;
    CellX, CellY : integer;
    HalfLineWidth : integer;

    LeftX : integer;
    RightX : integer;
    TopY : integer;
    BottomY : integer;
    Bottom2Y : integer;

begin
    // step 1 : calculate cell position of centre cell of text as TextX, TextY
    TextX := Item.X + Item.TextX;
    TextY := Item.Y + Item.TextY;

    // text position is rotated along with the rest of the component
    // around the item (0.0) reference point
    Rotate( TextX, TextY, Item.X, Item.Y, Item.Rotation );


    // step 2 : convert cell position on board to a pixel position
    CellX := TextX * FPixelsPerCell;
    CellY := TextY * FPixelsPerCell;

    // step 3 : calculate centre pixel of cell : shape will rotate about it
    RotationX := (CellX + FPixelsPerCell div 2);
    RotationY := (CellY + FPixelsPerCell div 2);

    // step 4 : Draw a text shape in the default rotation, but output
    // via code which performs rotation translation of points
{
    <-- 3 cells wide -->
    ********************
    *                  *
    *                  *  1 cell high
    *                  *
    ********************
    ********************
}
    HalfLineWidth := (FComponentLineWidth div 2);
    LeftX := CellX - FPixelsPerCell + HalfLineWidth;
    RightX := CellX + (FPixelsPerCell * 2) - HalfLineWidth;
    TopY := CellY + HalfLineWidth;
    BottomY := CellY + FPixelsPerCell -HalfLineWidth;
    Bottom2Y := BottomY - (FComponentLineWidth * 2);

    Rotation := Item.TextRotation;

    MoveTo( LeftX, TopY );
    LineTo( RightX, TopY );
    LineTo( RightX, Bottom2Y);
    LineTo( LeftX, Bottom2Y);
    LineTo( LeftX, TopY );
    MoveTo( LeftX, BottomY );
    LineTo( RightX, BottomY );
end;


{
// stop erase of background.  Makes a real difference to paint speed
// We do need to draw background, because otherwise we are only drawing
// the strips - not the background which shows between the strips.
// We can either let Windows erase the background, or do it ourself in the
// Paint etc functions.  If we paint only altered areas of board, we can
// possibly save time by painting the background only for the altered area.

procedure TPerfProject.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
    // 0 means "I will draw the background myself
    Message.Result := 0;
//    Message.Result := 1;
end;
}

// *****************************************
//              UNDO & REDO
// *****************************************

procedure TveEditor.Undo;
begin
    // no arrow key operation in progress
    ArrowMove := amNone;

    FProject.DeselectAllItems;
    FProject.Undo;
    Paint;

    // get rid of last-clicked item info displayed in status bar
    MouseClickItem( nil );
end;

procedure TveEditor.Redo;
begin
    // no arrow key operation in progress
    ArrowMove := amNone;

    FProject.DeselectAllItems;
    FProject.Redo;
    Paint;

    // get rid of last-clicked item info displayed in status bar
    MouseClickItem( nil );
end;

procedure TveEditor.ClearUndo;
begin
    // no arrow key operation in progress
    ArrowMove := amNone;
    FProject.ClearUndo;
end;

// ***********************************
//          COPY & PASTE
// ***********************************
procedure TveEditor.PasteComponents;
begin
    // no arrow key operation in progress
    ArrowMove := amNone;

    PasteComponentsFromClipboard( FProject );
    Paint;
end;

procedure TveEditor.PasteComponentsWithDuplicateIdentifiers;
begin
    // no arrow key operation in progress
    ArrowMove := amNone;

    PasteComponentsFromClipboardWithDuplicateIdentifiers( Project );
    Paint;
end;

procedure TveEditor.CopyComponents;
begin
    CopySelectedToClipboard( FProject );
end;


// ***********************************
//            GROUPING
// ***********************************

procedure TveEditor.GroupSelected;
begin
    FProject.GroupSelected;
end;

procedure TveEditor.UnGroupSelected;
begin
    FProject.UnGroupSelected;
end;


end.


