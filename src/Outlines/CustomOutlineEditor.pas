unit CustomOutlineEditor;

interface

uses Controls, Classes, Outlines, CustomOutlines, Graphics, Painter, PinNoEntry;

type
    TMouseSubCellMove = procedure( SubCellX, SubCellY, CellX, CellY : integer ) of object;

    TCmoEditMode = ( emSelect, emLine, emPin );
    TCmofMouseMoveTask = ( mvNone, mvMoveShape, mvMoveSelectedShapes,
        mvMoveLineEnd, mvDrawLine, mvDrawSelectionRectangle );
    TDrawMode = ( dmNormal, dmSelected, dmXOR );
    TCmoEditorModeChange = procedure( Sender : TObject; Mode : TCmoEditMode )
        of object;
    TMouseClickShape = procedure( Sender : TObject; Item : TcoShape ) of object;

type TveCustomOutlineEditor = class( TCustomControl )

protected

    // The editor always works on a TveCustomOutline which belongs to
    FOutline : TveCustomOutline;
    FComponent : TveBoardItem;

    // drawing scale in pixels per cell
    FPixelsPerCell : integer;
    FComponentLineWidth : integer;

    // editing variables
    FEditMode : TCmoEditMode;

    MouseCellX, MouseCellY : integer;
    MouseSubCellX, MouseSubCellY : integer;

    // painting variables
    BackBuffer : TBitmap;
    Painter : TvePainter;
    DrawMode : TDrawMode;

    // display colors
    FStripColor : TColor;
    FBoardColor : TColor;
{
    // overlays to display

    // interface objects
    PinNoEntryForm : TPinNoEntryForm;
    ItemPopupMenu : TPopupMenu;
    PopupPoint : TPoint;
}
    // ClickedShape : TcoShape;
{
    InputBoxForm : TInputBoxForm;
}
    // mouse move action
    MouseMoveTask : TCmofMouseMoveTask;
{
    // selection rectangle as defined by user, celll units
    FSelectedLeft : integer;
    FSelectedTop : integer;
    FSelectedRight : integer;
    FSelectedBottom : integer;
    FSelectionValid : boolean;

    // line drawingvariables
    DrawLine : TcoLine;

    ClickCellX : integer;
    ClickCellY : integer;
}
    // item dragging variables
    MoveShape : TcoShape;
    MoveLineStart : boolean;
    WholeCellMove : boolean;
{
    MoveOriginalClientX : integer;
    MoveOriginalClientY : integer;

    MoveLastCellX : integer;
    MoveLastCellY : integer;

    ClickCellOffsetX : integer;
    ClickCellOffsetY : integer;
}
    ClickOriginalSubX : integer;
    ClickOriginalSubY : integer;
{
    // store x,y, rotation, length for single item undo
    UndoOriginalRotation : TRotation;
    UndoOriginalX : integer;
    UndoOriginalY : integer;
    UndoOriginalLength : integer;
}
    // rectangle around all items which are being moved - just encloses items
    // and is calculated just before starting to drag items
    MoveItemsBoundarySubCellX1,
    MoveItemsBoundarySubCellX2,
    MoveItemsBoundarySubCellY1,
    MoveItemsBoundarySubCellY2 : integer;
{
    MoveItemRepaintCellX1,
    MoveItemRepaintCellX2,
    MoveItemRepaintCellY1,
    MoveItemRepaintCellY2 : integer;

    MoveLastRectangleDrawClientX1 : integer;
    MoveLastRectangleDrawClientY1 : integer;
    MoveLastRectangleDrawClientX2 : integer;
    MoveLastRectangleDrawClientY2 : integer;
}

    LastDeltaSubX : integer;
    LastDeltaSubY : integer;
{
    // sizeable item stretching variables
    ClickNearestReference : boolean;
    ClickItemOffset : integer;
    OriginalSizeableLength : integer;

    // designator moving variables
    MoveDesignatorItem : TveBoardItem;


    // events offered by this object
}
    FOnMouseSubCellMove : TMouseSubCellMove;
    FOnMouseClickShape : TMouseClickShape;
{
    FOnChange : TNotifyEvent;
}
    FOnChangeMode : TCmoEditorModeChange;

    // values used to get appearance right
    FBorder : integer;
{
    FGap : integer;

    // Design rule check
    FDRCVisible : boolean;
    FDRCAutoRefresh : boolean;

    procedure SetProject( Proj : TveProject );
}
    procedure SetEditMode( Mode : TCmoEditMode );
{
    procedure GetCellAt( ClientX, ClientY : integer; var CellX, CellY : integer );
    function GetCellQuadrantAt( ClientX, ClientY : integer ) : TQuadrant;
}
    procedure SetPixelsPerCell( value : integer );
{
    procedure SetComponentLineWidth( Width : integer );
    function GetTextDisplay : TTextDisplay;
    procedure SetTextDisplay( Value : TTextDisplay );
    function GetLeadStyle : TLeadStyle;
    procedure SetLeadStyle( Value : TLeadStyle );
}
    procedure UpdatePaintInfo;

    // override functions from ancestor object
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;

    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

    // painting functions
    procedure SetCanvasXOR;
{
    procedure SetCanvasXORRectangle;
}
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;

    // internal service functions
    procedure ShowRightClickMenu( X, Y : integer );
{
    function GetDirty : boolean;
    procedure SetDirty( Value : boolean );
    procedure MakeDirty;
    procedure ProjectChangeHandler( Sender : TObject );

    procedure CreateBoardItemMenu;

    // internal event channelling
    procedure MouseClickShape( Item : TveBoardItem );
    procedure MouseClickItemXY( Item : TveBoardItem; X, Y : integer );

    // internal popup menu event handlers
    procedure OnDesignatorMenu(Sender: TObject);
    procedure OnValueMenu(Sender : TObject);
    procedure OnDesignatorVisibleMenu( Sender : TObject );

}
    // internal calcs
    procedure GetSelectedItemsBoundary;
{
    procedure GetSelectedItemsPaintBoundary;
}

    // properties
    procedure SetOutline( Outline : TveCustomOutline  );

    function GetBodyColor : TColor;
    procedure SetBodyColor( Value : TColor );
    function GetPinColor : TColor;
    procedure SetPinColor( Value : TColor );

    // internal editing
    procedure DeleteSelectedShapes;
public
    // the editor always works on a project
    property Outline : TveCustomOutline read FOutline write SetOutline; //SetOutline;

    // editing mode variables      
    property EditMode : TCmoEditMode read FEditMode write SetEditMode;

//    property Dirty : boolean read GetDirty write SetDirty;

    property PixelsPerCell : integer read FPixelsPerCell write SetPixelsPerCell;
    property ComponentLineWidth : integer
            read FComponentLineWidth write FComponentLineWidth; //SetComponentLineWidth;

    // events
    property OnMouseSubCellMove : TMouseSubCellMove
        read FOnMouseSubCellMove write FOnMouseSubCellMove;

    property OnMouseClickShape : TMouseClickShape
        read FOnMouseClickShape write FOnMouseClickShape;
{
    property OnChange : TNotifyEvent read FOnChange write FOnChange;
}
    property OnChangeMode : TCmoEditorModeChange
        read FOnChangeMode write FOnChangeMode;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // painting
    procedure Paint; override;
    procedure PaintShape( Shape : TcoShape );
    procedure SetCanvasUnselected;
    procedure SetCanvasSelected;
    procedure EndDrawSequence;
    procedure PaintSelected;

    // display colors
    property BodyColor : TColor read GetBodyColor write SetBodyColor;
    property PinColor : TColor read GetPinColor write SetPinColor;
    property StripColor : TColor read FStripColor write FStripColor;
    property BoardColor : TColor read FBoardColor write FBoardColor;
end;


implementation

uses Cursors, Windows, Forms, SysUtils, ExceptSafe
{$IFNDEF VER200}, System.Types {$ENDIF} ;

type ESafeCustomOutlineEditor = class( ESafe );

const
    STD_BORDER = 0;
    STD_GAP = 1;

    MAX_OUTLINE_WIDTH = 50;
    MAX_OUTLINE_HEIGHT = 50;


constructor TveCustomOutlineEditor.Create(AOwner: TComponent);
begin
    inherited Create( AOwner );

    // a safe value to get us going
    FPixelsPerCell := 23;
    FComponentLineWidth := 1;
    FBorder := STD_BORDER;

    FStripColor := $E0E0E0; //clLtGray;
    FBoardColor := $DFFFF8; //clWhite;

//    CreateBoardItemMenu;
//    InputBoxForm := TInputBoxForm.Create(self);
    PinNoEntryForm := TPinNoEntryForm.Create(self);

    BackBuffer := Graphics.TBitmap.Create;
    FComponent := TveBoardItem.Create;

    // 96 DPI gets 2 pixel wide line
    // 120 DPI gets 2 pixels wide line
    // 180 DPI gets 3 pixels wide line
    ComponentLineWidth := Screen.PixelsPerInch div 48;

    Painter := TvePainter.Create;
    Painter.BodyColor := clBlack;
    Painter.PinColor := clBlue;
    UpdatePaintInfo;
end;

destructor TveCustomOutlineEditor.Destroy;
begin
    PinNoEntryForm.Free;
    FComponent.Free;
    Painter.Free;
    BackBuffer.Free;
    inherited;
end;


//**********************************************
//          PROPERTY SETTER-GETTERS    
//**********************************************

procedure TveCustomOutlineEditor.SetOutline( Outline : TveCustomOutline  );
begin
    FOutline := Outline;
    FComponent.Outline := Outline;
    Outline.EnableUndo;
end;

procedure TveCustomOutlineEditor.UpdatePaintInfo;
begin
    Painter.Border := STD_BORDER;
    Painter.Gap := STD_GAP;
    Painter.PixelsPerCell := FPixelsPerCell;
    Painter.Options := [];
    Painter.LineWidth := FComponentLineWidth;
end;

function TveCustomOutlineEditor.GetBodyColor : TColor;
begin
    result := Painter.BodyColor;
end;

procedure TveCustomOutlineEditor.SetBodyColor( Value : TColor );
begin
    Painter.BodyColor := Value;
end;

function TveCustomOutlineEditor.GetPinColor : TColor;
begin
    result := Painter.PinColor;
end;

procedure TveCustomOutlineEditor.SetPinColor( Value : TColor );
begin
    Painter.PinColor := Value;
end;

procedure TveCustomOutlineEditor.SetEditMode( Mode : TCmoEditMode );
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
end;

procedure TveCustomOutlineEditor.SetPixelsPerCell( value : integer );
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

    FPixelsPerCell := value;
    UpdatePaintInfo;
end;

// ****************************************************
//              INTERNAL FUNCTIONS
// ****************************************************

procedure TveCustomOutlineEditor.DeleteSelectedShapes;
begin
    FOutline.DeleteSelectedShapesWithUndo;
    // redraw to show items now deleted
    Paint;
end;


procedure TveCustomOutlineEditor.GetSelectedItemsBoundary;
var
    i : integer;
    Shape : TcoShape;
    ShapeLeft, ShapeRight, ShapeTop, ShapeBottom : integer;
    BoundLeft, BoundRight, BoundTop, BoundBottom : integer;
begin
    BoundLeft := High(BoundLeft);
    BoundRight := Low(BoundRight);
    BoundTop := High(BoundTop);
    BoundBottom := Low(BoundBottom);

    for i := 0 to FOutline.ShapeCount -1 do begin
        Shape := FOutline.Shapes[i];
        if not Shape.Selected then begin
            continue;
        end;

        Shape.GetSubRectangle( ShapeLeft, ShapeTop, ShapeRight, ShapeBottom );

        if BoundLeft > ShapeLeft     then BoundLeft := ShapeLeft;
        if BoundRight < ShapeRight   then BoundRight := ShapeRight;
        if BoundTop > ShapeTop       then BoundTop := ShapeTop;
        if BoundBottom < ShapeBottom then BoundBottom := ShapeBottom;
    end;

    // rectangle around all selected items
    MoveItemsBoundarySubCellX1 := BoundLeft;
    MoveItemsBoundarySubCellX2 := BoundRight;
    MoveItemsBoundarySubCellY1 := BoundTop;
    MoveItemsBoundarySubCellY2 := BoundBottom;
end;


// ****************************************************
//              KEYBOARD MESSAGES
// ****************************************************

procedure TveCustomOutlineEditor.KeyPress(var Key: Char);
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

        CTRL_A : begin
            FOutline.SelectAllShapes;
            Paint;
        end;
{
        CTRL_C : CopySelectedTracksToClipboard( Tracks );
        CTRL_V : begin
            SetCanvasUnselected;
            PaintSelected;
            PasteTracksFromClipboard( Tracks );
            SetCanvasSelected;
            PaintSelected;
        end;
}
        CTRL_Z : begin
            FOutline.Undo;
            Paint;
        end;
        CTRL_Y : begin
            FOutline.Redo;
            Paint;
        end;
    end;
end;

//  warning : this function not called unless TveCustomOutlineEditor.SetFocus
// has been called by form containing this control.
procedure TveCustomOutlineEditor.KeyDown(var Key: Word; Shift: TShiftState);
begin
    if Key = VK_DELETE then begin
        DeleteSelectedShapes;
    end
    else
    if Key = VK_ESCAPE then begin
        EditMode := emSelect;
    end
    else if Key = VK_F2 then begin
        EditMode := emLine;
    end;
end;


// ****************************************************
//              MOUSE MESSAGES
// ****************************************************

procedure TveCustomOutlineEditor.MouseMove(Shift: TShiftState; X, Y: Integer);
var
    NewMouseCellX, NewMouseCellY : integer;
    NewMouseSubCellX, NewMouseSubCellY : integer;

    // move selection
    DeltaSubX : integer;
    DeltaSubY : integer;
    MoveX : integer;
    MoveY : integer;

    DropDistance : integer;

    i : integer;
    Shape : TcoShape;

begin
    // calculate current SubCell Coords
    NewMouseSubCellX := ((( X - FBorder ) * TcoSubCellsPerCell) div FPixelsPerCell);
    NewMouseSubCellY := ((( Y - FBorder ) * TcoSubCellsPerCell) div FPixelsPerCell);

    // Cell Coords
    NewMouseCellX := NewMouseSubCellX div TcoSubCellsPerCell;
    NewMouseCellY := NewMouseSubCellY div TcoSubCellsPerCell;


    // update coords if changed
    if ((NewMouseSubCellX <> MouseSubCellX) or (NewMouseSubCellY <> MouseSubCellY)) then begin
        MouseSubCellX := NewMouseSubCellX;
        MouseSubCellY := NewMouseSubCellY;
        if Assigned( FOnMouseSubCellMove ) then begin
            FOnMouseSubCellMove( NewMouseSubCellX, NewMouseSubCellY, NewMouseCellX, NewMouseCellY );
        end;
    end

    // if we have not moved to a new subcell from last time, nothing to do, even
    // though mouse pointer may have moved a pixel or two
    else begin
//        MessageBeep(0);
        exit;
    end;

    // if we are moving a selection or a single BoardItem
    {else} if MouseMoveTask in [mvMoveShape, mvMoveSelectedShapes] then begin

        // calculate how far we have moved in SubCells since move began
        DeltaSubX := MouseSubCellX - ClickOriginalSubX;
        DeltaSubY := MouseSubCellY - ClickOriginalSubY;

{
       // ... step 1 : is displacement within 1/4 of a cell from pixel coords of
        //... a cell
        DropDistance := PixelsPerCell div 4;
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
}

        // ensure that no selected item is moved outside board boundaries
        if  (MoveItemsBoundarySubCellX1 + DeltaSubX < 0) then begin
            DeltaSubX := - MoveItemsBoundarySubCellX1;
        end
        else if (MoveItemsBoundarySubCellX2 + DeltaSubX > (MAX_OUTLINE_WIDTH * TcoSubCellsPerCell)) then begin
            DeltaSubX := (MAX_OUTLINE_WIDTH * TcoSubCellsPerCell) - MoveItemsBoundarySubCellX2;
        end;

        if (MoveItemsBoundarySubCellY1 + DeltaSubY < 0) then begin
            DeltaSubY := - MoveItemsBoundarySubCellY1;
        end
        else if (MoveItemsBoundarySubCellY2 + DeltaSubY > (MAX_OUTLINE_HEIGHT * TcoSubCellsPerCell)) then begin
            DeltaSubY := (MAX_OUTLINE_HEIGHT * TcoSubCellsPerCell) - MoveItemsBoundarySubCellY2;
        end;


        // if we are moving in cell increments, "cog" movement
        if WholeCellMove then begin
           // ... step 1 : is displacement within 1/3 of a cell from pixel coords of
            //... a cell
            DropDistance := TcoSubCellsPerCell div 3;
            if ((abs(DeltaSubX) mod TcoSubCellsPerCell) > DropDistance) and
                ((abs(DeltaSubY) mod TcoSubCellsPerCell) > DropDistance) then begin
                asm nop end;
                exit;
            end;

            // since we are moving in cell increments, move to nearest cell
            DeltaSubX := ((DeltaSubX div TcoSubCellsPerCell) * TcoSubCellsPerCell);
            DeltaSubY := ((DeltaSubY div TcoSubCellsPerCell) * TcoSubCellsPerCell);
        end;


        // erase BoardItems at old location with second XOR paint
        PaintSelected;

        // step 4a : move BoardItems to new location
        MoveX := DeltaSubX - LastDeltaSubX;
        MoveY := DeltaSubY - LastDeltaSubY;
        for i := 0 to FOutline.ShapeCount -1 do begin
            Shape := FOutline.Shapes[i];
            if Shape.Selected then begin
                Shape.SubX := Shape.SubX + MoveX;
                Shape.SubY := Shape.SubY + MoveY;
            end;
        end;

        // step 4b : draws BoardItem at new location
        PaintSelected;

        // record latest position info, ready for next movement
        LastDeltaSubX := DeltaSubX;
        LastDeltaSubY := DeltaSubY;

        // an edit happened
        {MakeDirty;}
    end

    else if MouseMoveTask in [mvMoveLineEnd, mvDrawLine] then begin

        // calculate how far we have moved in SubCells since move began
        DeltaSubX := MouseSubCellX - ClickOriginalSubX;
        DeltaSubY := MouseSubCellY - ClickOriginalSubY;

        // erase Line at old location with second XOR paint
        PaintShape( MoveShape );

        // Line end new location
        MoveX := DeltaSubX - LastDeltaSubX;
        MoveY := DeltaSubY - LastDeltaSubY;
        if MoveLineStart then begin
            MoveShape.SubX := MoveShape.SubX + MoveX;
            MoveShape.SubY := MoveShape.SubY + MoveY;
            TcoLine(MoveShape).EndDeltaSubX := TcoLine(MoveShape).EndDeltaSubX - MoveX;
            TcoLine(MoveShape).EndDeltaSubY := TcoLine(MoveShape).EndDeltaSubY - MoveY;
        end
        else begin
            TcoLine(MoveShape).EndDeltaSubX := TcoLine(MoveShape).EndDeltaSubX + MoveX;
            TcoLine(MoveShape).EndDeltaSubY := TcoLine(MoveShape).EndDeltaSubY + MoveY;
        end;

        // draw BoardItem at new location
        PaintShape( MoveShape );

        // record latest position info, ready for next movement
        LastDeltaSubX := DeltaSubX;
        LastDeltaSubY := DeltaSubY;

        // an edit happened
        {MakeDirty;}
    end;
end;

procedure TveCustomOutlineEditor.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);

    // look for a pin close to the click point
    // Shape.DistanceToPoint( Item, SubCellX, SubCellY );
    function NearestPin( SubX, SubY : integer ) : TcoPin;
    var
        Shape : TcoShape;
        i : integer;
    begin
        for i := FOutline.ShapeCount -1 downto 0 do begin
            Shape := FOutline.Shapes[i];
            if (Shape is TcoPin) and
               (Shape.DistanceToPoint( FComponent, SubX, SubY ) <= TcoSubCellsPerCell div 4)
                then begin
                result := TcoPin( Shape );
                exit;
            end;
        end;
        // no pin found in range
        result := nil;
    end;

var
    S : TcoShape;
    SelectedCount : integer;

    Shape : TcoShape;
    deleted : boolean;
    i : integer;
    Pin : TcoPin;
    PinSubX, PinSubY : integer;
    Line : TcoLine;

    ClickSubX, ClickSubY : single;

begin
    // if mouse just gone down, we can't be doing a mouse move task!
    MouseMoveTask := mvNone;


    // if Right-Click, then Popup Menu
    if (ssRight in Shift) then begin
        ShowRightClickMenu( X, Y );
    end

    // if Draw Line mode
    else if EditMode = emLine then begin

        // add a new Line starting at the click cell
        Line := FOutline.CreateLine;
        Line.SubX := MouseSubCellX;
        Line.SubY := MouseSubCellY;

        // give the line a small initial length
        Line.EndDeltaSubY := 1;
        Line.EndDeltaSubX := 0;

        // will move line *end* not line *start*
        MoveLineStart := False;

        // select just this BoardItem
        FOutline.UnselectAllShapes;
        Line.Selected := True;

        // record item being moved
        MoveShape := Line;

        // Paint this BoardItem in selected color
        SetCanvasSelected;
        PaintShape( Line );

        // record positions before movement starts
        ClickOriginalSubX := MouseSubCellX;
        ClickOriginalSubY := MouseSubCellY;
        LastDeltaSubX := 0;
        LastDeltaSubY := 0;

        // prepare for XOR image to follow mouse
        SetCanvasXOR;
        PaintShape( Line );

        //MakeDirty;

        // use same code as for moving a line end
        MouseMoveTask := mvDrawLine;
    end

    // if Pin mode, toggle pin
    else if EditMode = emPin then begin

        // bump mouse coords to nearest pin exact coords
        PinSubX :=
            ((MouseSubCellX div TcoSubCellsPerCell) * TcoSubCellsPerCell) + (TcoSubCellsPerCell div 2);
        PinSubY :=
            ((MouseSubCellY div TcoSubCellsPerCell) * TcoSubCellsPerCell) + (TcoSubCellsPerCell div 2);

        // look for a pin within 1/4 cell distance of the click point
        // and delete it

        Shape := nil;
        deleted := False;
        for i := FOutline.ShapeCount -1 downto 0 do begin
            Shape := FOutline.Shapes[i];
            if (Shape is TcoPin) and
                    (Shape.DistanceToPoint( FComponent, PinSubX, PinSubY ) <= TcoSubCellsPerCell div 4)
                    then begin
                deleted := True;
                break;
            end;
        end;

        if deleted then begin
            // delete item to Undo
            FOutline.UnselectAllShapes;
            Shape.Selected := True;
            FOutline.DeleteSelectedShapesWithUndo;

            // repaint board to reveal deleted pin
            Paint;
        end

        // if no pins were deleted, then space was clear - add a pin
        else begin

            // too many pins?
            if FOutline.PinCount > TveMaxPinIndex then begin
                raise ESafeCustomOutlineEditor.Create( 'Too many pins' );
            end;

            // add a new pin at click location
            // Pin := TcoPin.Create;
            Pin := FOutline.CreatePin;
            Pin.Name := '1';
            Pin.SubX := PinSubX;
            Pin.SubY := PinSubY;

            // record added item for Undo
            FOutline.RegisterNewShapeForUndo(Pin);

            // repaint board to reveal deleted pin
            FOutline.UnselectAllShapes;
            Pin.Selected := True;
            Paint;
        end
    end

    else if FEditMode = emSelect then begin

        // locate shape nearest click point.
        //.. subtract 0.5 cell so that mouse centre of cell is same as cell coord.
        ClickSubX := (((X - FBorder) * TcoSubCellsPerCell) / FPixelsPerCell) -0.5;
        ClickSubY := (((Y - FBorder) * TcoSubCellsPerCell) / FPixelsPerCell) -0.5;

{$IFDEF DEBUG}
        Canvas.TextOut( 100, 100, Format( '%f,%f', [ClickSubX, ClickSubY] ));
{$ENDIF}

        S := FOutline.GetSpecifiedShapeAtSubCellXY( FComponent, ClickSubX, ClickSubY, TcoShape );
//        S := FOutline.GetSpecifiedShapeAtSubCellXY( FComponent, MouseSubCellX, MouseSubCellY, TcoShape );
        // event gives info on clicked Shape
        if Assigned( FOnMouseClickShape ) then begin
            FOnMouseClickShape( self, S );
        end;

            // if clicked outside all Shapes,
            if (s = nil) then begin

                // then prepare to draw selection rectangle
                if not (ssCtrl in Shift) then begin
    {
                    // prepare to draw selection rectangle when mouse moves
                    SetCanvasXORRectangle;

                    // record where we started
                    MoveOriginalClientX := X;
                    MoveOriginalClientY := Y;

                    MoveLastRectangleDrawClientX1 := X;
                    MoveLastRectangleDrawClientY1 := Y;
                    MoveLastRectangleDrawClientX2 := X;
                    MoveLastRectangleDrawClientY2 := Y;
    }
                    // record where we started
                    ClickOriginalSubX := MouseSubCellX;
                    ClickOriginalSubY := MouseSubCellY;

                    MouseMoveTask := mvDrawSelectionRectangle;
                end
            end

            // *** alt-click : drag line end
            else if (ssAlt in Shift) or (ssShift in Shift) then begin

                // find nearest line
                Line := TcoLine(
                    FOutline.GetSpecifiedShapeAtSubCellXY( FComponent, MouseSubCellX, MouseSubCellY, TcoLine )
                );
                
                // no line found, do nothing
                if Line = nil then begin
                    exit;
                end;

                // find if we clicked Start or End of line and store this info
                // for use during MouseMove
                MoveLineStart := Line.StartIsNearestPoint(
                    FComponent, MouseSubCellX, MouseSubCellY );

                // unselect all by repainting selected in normal color
                SetCanvasUnselected;
                PaintSelected;

                // select just this BoardItem
                FOutline.UnselectAllShapes;
                Line.Selected := True;

                // record item being moved
                MoveShape := Line;

                // Paint this BoardItem in selected color
                SetCanvasSelected;
                PaintShape( Line );

                // record positions before movement starts
                ClickOriginalSubX := MouseSubCellX;
                ClickOriginalSubY := MouseSubCellY;
                LastDeltaSubX := 0;
                LastDeltaSubY := 0;

                 // snapshot for Undo
                 FOutline.SnapshotSelectedShapes;

                // setup for XOR drawing of BoardItems during move
                SetCanvasXOR;

                MouseMoveTask := mvMoveLineEnd;
            end

            // *** ctrl-click : toggle selection
            else if (ssCtrl in Shift) then begin
                S.Selected := not S.Selected;

                // paint this BoardItem to show new selection status
                if S.Selected then begin
                    SetCanvasSelected;
                end
                else begin
                    SetCanvasUnselected;
                end;
                PaintShape( S );
                MouseMoveTask := mvNone;
            end

            // ** simple click on an item **
            else begin

                // If no items selected at all or clicked on item is not selected or
                // clicked on item is only selected item, then
                // means move single item.
                SelectedCount := FOutline.SelectedCount;
                if (SelectedCount = 0) or ( not S.Selected ) or
                    ((SelectedCount = 1) and (S.Selected))
                    then begin

                    // unselect all by repainting selected in normal color
                    SetCanvasUnselected;
                    PaintSelected;

                    // select just this BoardItem
                    FOutline.UnselectAllShapes;
                    S.Selected := True;

                    // record item being moved
                    MoveShape := S;

                    // if item is pin, move it in whole cell increments
                    WholeCellMove := MoveShape is TcoPin;

                    // Paint this BoardItem in selected color
                    SetCanvasSelected;
                    PaintShape( S );

                    // record positions before movement starts
                    ClickOriginalSubX := MouseSubCellX;
                    ClickOriginalSubY := MouseSubCellY;
                    LastDeltaSubX := 0;
                    LastDeltaSubY := 0;

                    // find rectangle containing all selected components
                    // This rectangle will be used to prevent block move outside
                    // board area.
                    GetSelectedItemsBoundary;

                    // snapshot for Undo
                    FOutline.SnapshotSelectedShapes;

                    // setup for XOR drawing of BoardItems during move
                    SetCanvasXOR;

                    // start "in motion" state machine
                    MouseMoveTask := mvMoveShape;
                end

                // clicked on an already selected item, so move all selected items
                else begin

                    ClickOriginalSubX := MouseSubCellX;
                    ClickOriginalSubY := MouseSubCellY;
                    LastDeltaSubX := 0;
                    LastDeltaSubY := 0;

                    // if item to move includes a pin, move it in whole cell increments
                    WholeCellMove := FOutline.SelectionIncludesPin;

                    // find rectangle containing all selected components
                    // This rectangle will be used to prevent block move outside
                    // board area.
                    GetSelectedItemsBoundary;
    {
                    // find repaint rectangle
                    GetSelectedItemsPaintBoundary;
    }
                    // snapshot for Undo
                    FOutline.SnapshotSelectedShapes;

                    // setup for XOR drawing of BoardItems during move
                    SetCanvasXOR;

                    // start "in motion" state machine
                    MouseMoveTask := mvMoveSelectedShapes;
                end;
            end;
    end;
end;


procedure TveCustomOutlineEditor.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
//    NewMouseCellX, NewMouseCellY : integer;
    NewMouseSubCellX, NewMouseSubCellY : integer;
begin
    // calculate present coordinates in SubCell units
    NewMouseSubCellX := ((X - FBorder) * TcoSubCellsPerCell) div FPixelsPerCell;
    NewMouseSubCellY := ((Y - FBorder) * TcoSubCellsPerCell) div FPixelsPerCell;

    // update coords if changed
    if (NewMouseSubCellX <> MouseSubCellX) or (NewMouseSubCellY <> MouseSubCellY) then begin

        // calculate cell coords too
        MouseCellX := (X - FBorder) div FPixelsPerCell;
//        NewMouseCellX := (Y - FBorder) div FPixelsPerCell;

        if Assigned( OnMouseSubCellMove ) then begin
            OnMouseSubCellMove( MouseSubCellX, MouseSubCellX, MouseCellX, MouseCellY );
        end;
    end;

    case MouseMoveTask of
        mvNone : ;

        mvMoveShape, mvMoveSelectedShapes : begin
            FOutline.StoreSnapshotSelectedAsUndo;
            Paint;
        end;

        mvDrawSelectionRectangle : begin
            // if only a small mouse movement, call that a simple click outside
            // all Shapes rather than a rectangle draw, and unselect all
            if (ClickOriginalSubX = MouseSubCellX) and
                (ClickOriginalSubY = MouseSubCellY) then begin
                FOutline.UnSelectAllShapes;
                Paint
            end;
        end;

        mvDrawLine : begin
            FOutline.RegisterNewShapeForUndo(MoveShape);
            Paint;
        end;

        mvMoveLineEnd : begin
            FOutline.StoreSnapshotSelectedAsUndo;
            Paint;
        end;
    end;

    // we are no longer doing a mouse move task
    MouseMoveTask := mvNone;
end;

// *********************************************
//          PAINTING FUNCTIONS
// *********************************************

procedure TveCustomOutlineEditor.SetCanvasSelected;
begin
    DrawMode := dmSelected;
end;

procedure TveCustomOutlineEditor.SetCanvasUnselected;
begin
    DrawMode := dmNormal;
end;

procedure TveCustomOutlineEditor.SetCanvasXOR;
begin
    DrawMode := dmXOR;
end;

procedure TveCustomOutlineEditor.EndDrawSequence;
begin
    // display it
    self.Canvas.Draw( 0,0, BackBuffer );
end;


procedure TveCustomOutlineEditor.PaintShape( Shape : TcoShape );
begin
    Painter.Clear;
    UpdatePaintInfo;
    Shape.Paint( FComponent, Painter );

    case DrawMode of
        dmNormal : begin
            Painter.PaintNormal( BackBuffer.Canvas );
            EndDrawSequence;
        end;
        dmSelected : begin
            Painter.PaintSelected( BackBuffer.Canvas );
            EndDrawSequence;
        end;
        dmXOR : Painter.PaintXOR( Canvas );
    end;
end;

procedure TveCustomOutlineEditor.PaintSelected;
var
    i : integer;
    Shape : TcoShape;
begin
    Painter.Clear;
    UpdatePaintInfo;
    Painter.Options := [];
    try
        for i := 0 to FOutline.ShapeCount -1 do begin
            Shape := FOutline.Shapes[i];
            if Shape.Selected then begin
                Shape.Paint( FComponent, Painter );
            end;
        end;

        case DrawMode of
            dmNormal : begin
                Painter.PaintNormal( BackBuffer.Canvas );
                EndDrawSequence;
            end;
            dmSelected : begin
                Painter.PaintSelected( BackBuffer.Canvas );
                EndDrawSequence;
            end;
            dmXOR : Painter.PaintXOR( Canvas );
        end;

    finally
        Painter.Options := [];
    end;
end;


procedure TveCustomOutlineEditor.Paint;
var
    // area of board to operate on (fixed at moment)
    CellX1, CellY1, CellX2, CellY2 : integer;
    Canvas : TCanvas;

    ScreenX1 : integer;
    ScreenY1 : integer;
    ScreenX2 : integer;
//    ScreenY2 : integer;

//    StripWidth : integer;
//    InterStripWidth : integer;
    TopStripDownY : integer;

    StripX, StripY : integer;
    i,j : integer;

//    HoleDiam, HoleRadius : integer;

    Shape : TcoShape;
begin
    // area of board to operate on (fixed at moment)
    CellX1 := 0;
    CellY1 := 0;
    CellX2 := MAX_OUTLINE_WIDTH;
    CellY2 := MAX_OUTLINE_HEIGHT;

    // set TCustomControl dimensions : 2 extra pixels for border
    Width := (MAX_OUTLINE_WIDTH * FPixelsPerCell);
    Height := (MAX_OUTLINE_HEIGHT * FPixelsPerCell);

    // set back buffer to same dimensions
    BackBuffer.Width := Width;
    BackBuffer.Height := Height;

    // all drawing on this canvas
    Canvas := BackBuffer.Canvas;

    // (ScreenX1, ScreenY1) and ( ScreenX2, ScreenY2) define rectangle we need
    // to draw inside.  Units are pixels : ie canvas coords.  Even though part
    // of this rectangle may be outside the visible rectangle "Rect", we use
    // this rectangle because its top left coords start exactly at top left of
    // a cell - and we have to draw integral cells.
    ScreenX1 := (CellX1 * FPixelsPerCell);
    ScreenY1 := (CellY1 * FPixelsPerCell);
    ScreenX2 := (CellX2 * FPixelsPerCell);
//    ScreenY2 := CellY2 * FPixelsPerCell;

    // calculate common parameters
//    StripWidth := FPixelsPerCell div 2;
//    InterStripWidth :=  FPixelsPerCell - StripWidth;

{
    // **** DRAW CLASSIC STRIP PATTERN ****

    TopStripDownY := ScreenY1 + (InterStripWidth div 2);

    // draw lines between strips - part which is inside visible rectangle
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := FBoardColor;
    StripY := TopStripDownY - InterStripWidth;
    for i := CellY1 to CellY2 do begin
        Canvas.FillRect( Rect(ScreenX1, StripY, ScreenX2, StripY + InterStripWidth) );
        Inc( StripY, PixelsPerCell );
    end;

    // draw strips  - part which is inside visible rectangle
    Canvas.Brush.Color := FStripColor;
    StripY := TopStripDownY;
    for i := CellY1 to CellY2 -1 do begin
        Canvas.FillRect( Rect(ScreenX1, StripY, ScreenX2, StripY + StripWidth) );
        Inc( StripY, PixelsPerCell );
    end;

    // draw holes
    // draw holes/grid
    Canvas.Pen.Style := psDot;
    Canvas.Pen.Width := 1;
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Color := clWhite;
    Canvas.Brush.Color := clWhite;
    HoleDiam := PixelsPerCell div 6;
    HoleRadius := PixelsPerCell div 12;

    StripY := TopStripDownY + (StripWidth div 2) - HoleRadius;
    for i := CellY1 to CellY2 do begin
        StripX := ScreenX1 + (PixelsPerCell div 2) - HoleRadius;
        for j := CellX1 to CellX2 do begin
            Canvas.Ellipse( StripX, StripY, StripX + HoleDiam +1, StripY + HoleDiam +1);
            Inc( StripX, PixelsPerCell );
        end;
        Inc( StripY, PixelsPerCell );
    end;
}

    // **** DRAW CHEQUERBOARD PATTERN ****

    TopStripDownY := ScreenY1;

    // draw background color over entire editor area
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := FBoardColor;
    Canvas.FillRect( Rect(ScreenX1, ScreenY1, ScreenX2, ScreenX2) );

    // draw boxes over background
    Canvas.Brush.Color := FStripColor;

    StripY := TopStripDownY;
    i := CellY1;
    while i <= CellY2 do begin
//    for i := CellY1 to CellY2 do begin

        StripX := ScreenX1 + (FPixelsPerCell * (i mod 2));;
        j := CellX1;
        while j <= CellX2 do begin
//        for j := CellX1 to CellX2  step 2 do begin
            Canvas.FillRect( Rect(
                StripX, StripY, StripX + FPixelsPerCell +1, StripY + FPixelsPerCell +1) );
            Inc( StripX, FPixelsPerCell * 2 );
            inc( j, 2 );
        end;

        Inc( StripY, FPixelsPerCell );
        inc( i, 1 );
    end;

    if FOutline = nil then begin
        exit;
    end;

    // draw shapes
    UpdatePaintInfo;

    // ...draw unselected shapes
    Painter.Clear;
    for i := 0 to FOutline.ShapeCount -1 do begin
        Shape := FOutline.Shapes[i];
        if not Shape.Selected then begin
            Shape.Paint( FComponent, Painter );
        end;
    end;
    Painter.PaintNormal( Canvas );

    // ...draw selected shapes
    Painter.Clear;
    for i := 0 to FOutline.ShapeCount -1 do begin
        Shape := FOutline.Shapes[i];
        if Shape.Selected then begin
            Shape.Paint( FComponent, Painter );
        end;
    end;
    Painter.PaintSelected( Canvas );

    //... after painting shapes
    EndDrawSequence;

    // display it
    self.Canvas.Draw( 0,0, BackBuffer );
end;

// *****************************************
//  SHOW & SUPPORT RIGHT-CLICK POPUP MENU
// *****************************************

procedure TveCustomOutlineEditor.ShowRightClickMenu( X, Y : integer );
var
    Shape : TcoShape;
    PopupPoint : TPoint;
begin
    Shape := FOutline.GetShapeAtSubCellXY(
        FComponent, MouseSubCellX, MouseSubCellY );

    // event gives info on clicked board item : we get C = nil if no item
//    MouseClickShapeXY( C, CellX, CellY );

    // record which shape clicked
//    ClickedShape := Shape;

    // if no shape clicked, right click reverts to select mode
    if Shape = nil then begin
        EditMode := emSelect;
        exit;
    end;

    // a shape was clicked : popup menu or dialog will be shown.  User will probably
    // forget that in in Line, Pin mode and mess up on next left click
    // so switch back to Select Mode.  Remove this next line if mode switch
    // turns out to be annoying.  Can't just switch mode : must raise an event
    // so that controls which show mode can be changed externally to this object.
//    FEditMode := emSelect;

    // work out where component is on screen
    PopupPoint := ClientToScreen( Point(X, Y) );

    // show menu
    //ItemPopupMenu.Popup( PopupPoint.X, PopupPoint.Y );
    if Shape is TcoPin then begin

        // existing selected items get painted non-highlighted
        SetCanvasUnselected;
        PaintSelected;

        // show this item as selected
        FOutline.UnselectAllShapes;
        Shape.Selected := True;
        SetCanvasSelected;
        PaintShape( Shape );

        // transfer changes to screen
        EndDrawSequence;

        // pop up entry form near cursor
        PinNoEntryForm.Top := PopupPoint.Y + GetSystemMetrics(SM_CYCAPTION);
        if PinNoEntryForm.Top + PinNoEntryForm.Height > Screen.Height then begin
            PinNoEntryForm.Top := Screen.Height - PinNoEntryForm.Height - GetSystemMetrics(SM_CYCAPTION);
        end;

        PinNoEntryForm.Left := PopupPoint.X + GetSystemMetrics(SM_CXFIXEDFRAME);
        if PinNoEntryForm.Left + PinNoEntryForm.Width > Screen.Width then begin
            PinNoEntryForm.Left := Screen.Width - PinNoEntryForm.Width;
        end;

        // show pin No. entry form
        PinNoEntryForm.PinName := TcoPin(Shape).Name;
        if PinNoEntryForm.ShowModal = mrOK then begin
            TcoPin(Shape).Name := PinNoEntryForm.PinName;
            // altered pin name must appear in pin list
            FOutline.BuildPinList;
        end;
    end;
end;


end.


