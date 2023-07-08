unit Project;

interface

uses Classes, SysUtils, Windows, Contnrs,
    Outlines, SizeableOutlines, OtherOutlines, Netlist, Board,
    ExceptSafe, UndoEngine;

const
    TveBoardDEFAULTWIDTH = 25;
    TveBoardDEFAULTHEIGHT = 34;
    TveBoardMAXWIDTH = TbrBoardMAXWIDTH;

type
    EPerfProject = class( Exception );
    ESafePerfProject = class( ESafe );
    TQuadrant = ( qaBottomLeft, qaBottomRight, qaTopRight, qaTopLeft );

type TveGroup = class
    Allocated : boolean;
    Tag : boolean;
end;

type TveProject = class

protected

    // board dimensions in units perf board cells
    //FBoardWidth : integer;
    //FBoardHeight : integer;
    FBoard : TbrBoard;

    // lists of items on board and item outlines
    FBoardItems : TList;
    FOutlines : TList;
    FDummyOutline : TveDummyOutline;
    FBreakOutline : TveBreakOutline;
    FLinkOutline : TveLinkOutline;
    FWireOutline : TveWireOutline;
    FTextOutline : TveTextOutline;

    FGroups : TObjectList;

    FNetList : TneNetList;
    FTraceNet : TneNode;
    FTraceXY : TPoint;
    FTracer : TObject;
    FUndoEng : TunUndo;

    FNotesLines : string;

    FDirty : boolean;
    FOnChange : TNotifyEvent;

    FNetlistImportFormat : string;

    // track pasting
    FPasteID : DWORD;
    FPasteOffsetX : integer;
    FPasteOffsetY : integer;

    procedure SetBoardWidth( value : integer );
    procedure SetBoardHeight( value : integer );

    function GetBoardWidth : integer;
    function GetBoardHeight : integer;

    function GetBoardItem( index : integer ) : TveBoardItem;
    function GetBoardItemCount : integer;

    function GetOutLine(index : integer) : TveOutline;
    function GetOutlineCount : integer;

    function GetSelectedItemCount : integer;

    procedure MakeDirty;
    procedure SetDirty( Value : boolean );

    // grouping
    procedure UntagGroups;
    procedure TagSelectedGroups;
    function AllocateGroup : integer;
    procedure DeAllocateGroup( GroupNo : integer );
    function PartGroupInSelection : boolean;


public

    property Dirty : boolean read FDirty write SetDirty;
    property OnChange : TNotifyEvent read FOnChange write FOnChange;

    // circuit board basic parameters
    property Board : TbrBoard read FBoard write FBoard;
    property BoardWidth : integer read GetBoardWidth write SetBoardWidth;
    property BoardHeight : integer read GetBoardHeight write SetBoardHeight;

    // access items on board
    property BoardItemCount : integer read GetBoardItemCount;
    property BoardItems[index : integer] : TveBoardItem
        read GetBoardItem;

    // access outlines used by items
    property OutlineCount : integer read GetOutlineCount;
    property Outlines[index : integer] : TveOutline
        read GetOutline;
    property DummyOutline : TveDummyOutline read FDummyOutline;
    property BreakOutline : TveBreakOutline read FBreakOutline;
    property LinkOutline : TveLinkOutline read FLinkOutline;
    property WireOutline : TveWireOutline read FWireOutline;
    property TextOutline : TveTextOutline read FTextOutline;

    // Netlist tells how components are wired together
    property NetList : TneNetList read FNetList;
    property TraceNet : TneNode read FTraceNet write FTraceNet;
    property ConnectivityObject : TObject read FTracer;

    // reminder of netlist mode for import
    property NetlistImportFormat : string
        read FNetlistImportFormat write FNetlistImportFormat;

    // Notes information
    property NotesLines : string read FNotesLines write FNotesLines;

    // store Component Paste information -
    property PasteID : DWORD read FPasteID write FPasteID;
    property PasteOffsetX : integer read FPasteOffsetX write FPasteOffsetX;
    property PasteOffsetY : integer read FPasteOffsetY write FPasteOffsetY;

    // clear / load fast lookup net info used for real time editing
    procedure ClearFastNets;
    procedure TransferFastNets;

    // access items (parts ie. components) on board
    function IndexOfBoardItem( item : TveBoardItem ) : integer;
    procedure AddBoardItem( Item : TveBoardItem );
    procedure DeleteBoardItem( Item : TveBoardItem );
    procedure ReleaseBoardItem( item : TveBoardItem );
    function GetBoardItemAt( CellX, CellY : integer ) : TveBoardItem;
    procedure GetNextItemAt(
        var Item : TveBoardItem; var Index : integer; CellX, CellY : integer );
    function GetBoardItemAtXYQuad( CellX, CellY : integer; Quadrant : TQuadrant ) : TveBoardItem;
    function ItemByDesignator( const Designator : string ) : TveBoardItem;
    procedure SortBoardItems;
    function GetSelectedCount : integer;
    function MultipleSelected : boolean;
    procedure DeSelectAllItems;
    function GetItemWithDesignatorAt( CellX, CellY : integer ) : TveBoardItem;
    procedure GetSelectedItemsBoundary( var Rect : TRect );
    procedure GetSelectedItemsPaintBoundary( var Rect : TRect );

    // Outlines are footprints available for use by items
    function IndexOfOutline( Outline : TveOutline ) : integer;
    function OutlineByName( Name : string ) : TveOutline;
    procedure AddOutline( Outline : TveOutline );
    function AddDefaultOutline : TveOutline;
    procedure DeleteOutline( Outline : TveOutline );
    function OutlineInUse( Outline : TveOutline ) : boolean;
    procedure ReplaceOutline( OldOutline, NewOutline : TveOutline );
    procedure SortOutlines;

    function MakeOutlineNameUnique( const Name : string ) : string;
    function MakeItemDesignatorUnique( const Designator : string ) : string;

    procedure Clear;
    procedure ClearNetlist;
    procedure Undo;
    procedure Redo;
    procedure ClearUndo;
    procedure SnapshotSelected;

    // MultiStage Undo Registrations
    procedure BeginUndo;
    procedure EndUndo;
    procedure ItemSnapshotToUndo( Item : TveBoardItem );
    procedure AddItemToUndo( Item : TveBoardItem );
    procedure DeleteItemToUndo( Item : TveBoardItem );

    // functions that create a single undo operation
    procedure ItemSnapshotAsUndo( Item : TveBoardItem );
    procedure SelectedItemsSnapshotAsUndo;
    procedure DeleteItemAsUndo( Item : TveBoardItem );
    procedure DeleteSelectedItemsAsUndo;
    procedure AddItemAsUndo( Item : TveBoardItem );

    procedure ClearDesignErrors;
    procedure ConnectivityCheck;

    // Groups and locking
//    procedure LockItem( Item : TveBoardItem );
//    procedure UnlockItem( Item : TveBoardItem );
    procedure RegisterGroups;
    procedure RemovePartGroupsSelection;
    procedure UnselectGroupMembers;
    procedure GroupSelected;
    procedure UnGroupSelected;
    procedure DeleteSelectedItems;

    procedure ToggleComponentAndGroupSelection( Item : TveBoardItem );
    procedure AddComponentsAndGroupsInsideAreaToSelection( Rect : Trect );

    constructor Create;
    destructor Destroy; override;
end;


TbeOperation = (opAdd, opRemove);

TunItemListMemento = class( TunMemento )
protected
    ItemList : TveProject;
    Item : TveBoardItem;
    Operation : TbeOperation;
public
    Procedure Undo; override;
    Procedure Redo; override;
    Procedure DiscardUndo; override;
    Procedure DiscardRedo; override;
end;


implementation

uses Dialogs, CelledOutlines, SortCompare, Rotations, Tracer;

const
    STD_BORDER = 0;
    STD_GAP = 1;

constructor TveProject.Create;
begin

    FBoardItems := TList.Create;
    FOutlines := TList.Create;
    FGroups := TObjectList.Create;

    FDummyOutline := TveDummyOutline.Create;
    FBreakOutline := TveBreakOutline.Create;
    FLinkOutline := TveLinkOutline.Create;
    FWireOutline := TveWireOutline.Create;
    FTextOutline := TveTextOutline.Create;

    FNetList := TneNetList.Create;

    FTracer := TveTracer.Create;
    TveTracer( FTracer ).Project := self;

    Board := TbrBoard.Create;
    BoardWidth := TveBoardDEFAULTWIDTH;
    BoardHeight := TveBoardDEFAULTHEIGHT;

    FUndoEng := TunUndo.Create(50);
end;

destructor TveProject.Destroy;
var
    i : integer;
begin
    FUndoEng.Free;

    if Assigned( FBoardItems ) then begin
        for i := FBoardItems.Count -1 downto 0 do begin
            TveBoardItem( FBoardItems[i] ).Free;
        end;
        FBoardItems.Free;
    end;

    if Assigned( FOutlines ) then begin
        for i := FOutlines.Count -1 downto 0 do begin
            TveOutline( FOutlines[i] ).Free;
        end;
        FOutlines.Free;
    end;

    FGroups.Free;

    Board.Free;
    FTextOutline.Free;
    FWireOutline.Free;
    FLinkOutline.Free;
    FBreakOutline.Free;
    FDummyOutline.Free;
    FNetList.Free;
    FTracer.Free;
    inherited;
end;


function TveProject.GetBoardWidth : integer;
begin
    result := FBoard.Width;
end;

function TveProject.GetBoardHeight : integer;
begin
    result := FBoard.Height;
end;

procedure TveProject.SetBoardWidth( value : integer );
begin
    FBoard.Width := value;
    MakeDirty;
end;

procedure TveProject.SetBoardHeight( value : integer );
begin
    FBoard.Height := value;
    MakeDirty;
end;

procedure TveProject.Clear;
var
    i : integer;
    Outline : TveOutline;
begin
    for i := FBoardItems.Count -1 downto 0 do begin
        TveBoardItem( FBoardItems[i] ).Free;
    end;
    FBoardItems.Clear;

    for i := FOutlines.Count -1 downto 0 do begin
        Outline := TveOutline( FOutlines[i] );
        Outline.Free;
    end;
    FOutlines.Clear;

    ClearNetList;
    ClearFastNets;

    TveTracer( FTracer ).Clear;

    FUndoEng.Clear;

    FNotesLines := '';

    FDirty := False;
// ** RKL    FSelectionValid := False;
end;

procedure TveProject.ClearNetlist;
begin
    FNetlist.Clear;
    FTraceNet := nil;
end;

function TveProject.GetBoardItem( index : integer ) : TveBoardItem;
begin
    result := TveBoardItem(FBoardItems[index]);
end;

function TveProject.GetOutLine(index : integer) : TveOutline;
begin
    result := TveOutline(FOutlines[index]);
end;

function TveProject.GetBoardItemCount : integer;
begin
    result := FBoardItems.Count;
end;

function TveProject.GetOutlineCount : integer;
begin
    result := FOutlines.Count;
end;

function TveProject.IndexOfBoardItem( Item : TveBoardItem ) : integer;
var
    i : integer;
begin
    for i := 0 to BoardItemCount -1 do begin
        if Item = FBoardItems[i] then begin
            result := i;
            exit;
        end;
    end;

    // item not found
    result := -1;
end;


procedure TveProject.AddBoardItem( Item : TveBoardItem );
begin
    FBoardItems.Add( Item );
end;

procedure TveProject.ReleaseBoardItem( Item : TveBoardItem );
var ItemIndex : integer;
begin
    ItemIndex := FBoardItems.IndexOf( Item );
    if (ItemIndex >= 0) then begin
        FBoardItems.Delete( ItemIndex );
    end;
end;

procedure TveProject.DeleteBoardItem( Item : TveBoardItem );
begin
    ReleaseBoardItem( Item );
    Item.Free;
    MakeDirty;
end;


// ** Find BoardItem at Cell Coords **
// returns nil if no BoardItem found
// if multiple items fall on a square, returns item with lowest index in
// FBoardItems array.
function TveProject.GetBoardItemAt( CellX, CellY : integer ) : TveBoardItem;
var
    i : integer;
    Item : TveBoardItem;

    Size : integer;

    SmallestItem : TveBoardItem;
    SmallestSize : integer;

    procedure GetSize;
    var R : TRect;
    begin
        Item.Outline.GetScreenRectR( Item,  R );
        // size = width + height
        Size := (R.Right - R.Left) + (R.Bottom - R.Top);
    end;    
  
begin
    SmallestItem := nil;
    SmallestSize := High( integer );

    // search list to find smallest item which lives in our cell
    for i := 0 to FBoardItems.Count -1 do begin

        Item := FBoardItems[i];
        if Item.Outline.OccupiesCell( Item, CellX, CellY ) then begin

            // get size of board item
            GetSize;

            // this is first item found on this cell or item is smaller than last ?
            if (SmallestItem = nil) or (Size < SmallestSize) then begin
                SmallestItem := Item;
                SmallestSize := Size;
            end;
        end;
    end;

    result := SmallestItem;
end;


function TveProject.GetBoardItemAtXYQuad
    ( CellX, CellY : integer; Quadrant : TQuadrant ) : TveBoardItem;
var
    i : integer;
    Item : TveBoardItem;

    Size : integer;

    SmallestItem : TveBoardItem;
    SmallestSize : integer;

   procedure GetSize;
    var R : TRect;
    begin
        Item.Outline.GetScreenRectR( Item,  R );
        // size = width * height
        Size := (R.Right - R.Left) * (R.Bottom - R.Top);
    end;

begin
    // first look for a break outline, using Quadrant info to pick shifted breaks
    // search list to find item which lives in our cell
    for i := 0 to FBoardItems.Count -1 do begin

        Item := FBoardItems[i];

        if Item.Outline is TveBreakOutline then begin

            case Item.Shift of

                shNone: begin
                    if (Item.X = CellX) and (Item.Y = CellY) then begin
                        result := Item;
                        exit;
                    end;
                end;

                shRight : begin
                    if (Item.Y = CellY) and
                       (
                       ((Item.X = CellX) and (Quadrant in [qaBottomRight, qaTopRight])) or
                       ((Item.X = CellX -1) and (Quadrant in [qaBottomLeft, qaTopLeft]))
                       )
                          then begin
                       result := Item;
                       exit;
                    end;
                end;

                shDown : begin
                    if (Item.X = CellX) and
                       (
                       ((Item.Y = CellY) and (Quadrant in [qaBottomLeft, qaBottomRight])) or
                       ((Item.Y = CellY -1) and (Quadrant in [qaTopLeft, qaTopRight]))
                       )
                          then begin
                       result := Item;
                       exit;
                    end;
                end;
            end;
        end;
    end;

    // no break, so simply use standard location algorithm

    SmallestItem := nil;
    SmallestSize := High( integer );

    // search list to find smallest item which lives in our cell
    for i := 0 to FBoardItems.Count -1 do begin

        Item := FBoardItems[i];
        if  (not (Item.Outline is TveBreakOutline)) and
            Item.Outline.OccupiesCell( Item, CellX, CellY ) then begin

            // get size of board item
            GetSize;

            // this is first item found on this cell or item is smaller than last ?

            { Could improve this so clicking on a pin dominates over size.
             to find if a pin is under the mouse, call
             function TveOutline.PinIndexAt( Item : TveBoardItem; CellX, CellY : integer ) : integer;
             if 0 or greater returned, have a pin.
             }

            if (SmallestItem = nil) or (Size < SmallestSize) then begin
                SmallestItem := Item;
                SmallestSize := Size;
            end;
        end;
    end;

    result := SmallestItem;
end;


// ** Find Board Item at or Following Index at Cell Coords CellX, CellY **
// To iterate thru items which occupy a square, set Index to 0 and call
// repeatedly until returns Item = nil

procedure TveProject.GetNextItemAt(
    var Item : TveBoardItem; var Index : integer; CellX, CellY : integer );
var
    i : integer;
    SearchItem : TveBoardItem;
begin
    // search list to find item which lives in our cell
    for i := Index to FBoardItems.Count -1 do begin
        SearchItem := FBoardItems[i];
        if SearchItem.Outline.OccupiesCell( SearchItem, CellX, CellY ) then begin
            Item := SearchItem;
            Index := i + 1;
            exit;
        end;
    end;

    // no item found
    Item := nil;
    Index := FBoardItems.Count;
end;

function TveProject.GetItemWithDesignatorAt( CellX, CellY : integer ) : TveBoardItem;
var
    i : integer;
    Item : TveBoardItem;
begin
    // search list to find item which lives in our cell
    for i := 0 to FBoardItems.Count -1 do begin

        Item := FBoardItems[i];
        if Item.Outline.ShowsDesignator and Item.TextVisible and
            Item.DesignatorOccupiesCell( CellX, CellY ) then begin
            result := Item;
            exit;
        end;
    end;

    // no item found
    result := nil;
end;


function TveProject.ItemByDesignator( const Designator : string ) : TveBoardItem;
var
    i : integer;
    SearchItem : TveBoardItem;
begin
    for i := 0 to FBoardItems.Count -1 do begin
        SearchItem := FBoardItems[i];
        if CompareText( SearchItem.Designator, Designator ) = 0 then begin
            result := SearchItem;
            exit;
        end;
    end;

    // no item found
    result := nil;
end;


function CompareItemsByDesignator( P1, P2 : pointer ) : integer;
begin
//    result := AnsiCompareStr( TveBoardItem(P1).Designator, TveBoardItem(P2).Designator );
    result := CompareDesignators( TveBoardItem(P1).Designator, TveBoardItem(P2).Designator );
end;


procedure TveProject.SortBoardItems;
begin
    FBoardItems.Sort( CompareItemsByDesignator );
end;


function TveProject.IndexOfOutline( Outline : TveOutline ) : integer;
var
    i : integer;
begin
    for i := 0 to FOutlines.Count -1 do begin
        if Outline = FOutlines[i] then begin
            result := i;
            exit;
        end;
    end;

    // item not found
    result := -1;
end;


function TveProject.OutlineByName( Name : string ) : TveOutline;
var
    Outline : TveOutline;
    i : integer;
begin
    for i := 0 to FOutlines.Count -1 do begin
        Outline := TveOutline( FOutlines[i] );
        if AnsiCompareText( Outline.Name, Name ) = 0 then begin
//        if Uppercase( Outline.Name ) = Uppercase( Name ) then begin
            result :=  Outline;
            exit;
        end;
    end;
    result := nil;
end;

procedure TveProject.AddOutline( Outline : TveOutline );
begin
    FOutlines.Add( Outline );
    MakeDirty;
end;

function TveProject.AddDefaultOutline : TveOutline;
var
    Outline : TveCellOutline;
begin
    Outline := TveCellOutline.Create;
    AddOutline( Outline );
    Outline.CellTypes[0,0] := ctBody;
    Outline.CellTypes[2,0] := ctBody;
    Outline.CellTypes[0,1] := ctBody;
    Outline.CellTypes[1,1] := ctBody;
    Outline.CellTypes[2,1] := ctBody;
    result := Outline;
end;

procedure TveProject.DeleteOutline( Outline : TveOutline );
var
    OutlineIndex : integer;
begin
    // find index of this outline - if not managed by thie Project, do nothing
    OutlineIndex := FOutlines.IndexOf( Outline );
    if OutlineIndex < 0 then begin
        raise EPerfProject.Create( 'Internal Error: Deleting outline not owned by Project' );
    end;

//    Don't need this - Dummy outline is not found via IndexOfOutline
//    in code immediately above
//    if OutlineInUse( Outline ) then begin
//        raise EPerfProject.Create( 'Deleting in-use outline' );
//    end;

    // remove item from array
    FOutlines.Delete( OutlineIndex );

    // delete outline
    Outline.Free;

    MakeDirty;
end;

function TveProject.OutlineInUse( Outline : TveOutline ) : boolean;
var
    i : integer;
begin
    // dummy outline belongs to this object and can't be deleted
    if Outline = FDummyOutline then begin
//        result := True;
//      exit;
    end;

    // try to find item in use by a board item
    for i := 0 to BoardItemCount -1 do begin
        if TveBoardItem(FBoardItems[i]).Outline = Outline then begin
            result := True;
            exit;
        end;
    end;

    // no item found using this outlline
    result := False;
end;

procedure TveProject.ReplaceOutline( OldOutline, NewOutline : TveOutline );
var
    ItemIndex : integer;
    i : integer;
    Item : TveBoardItem;
begin
    // replace outline in list
    ItemIndex := IndexOfOutline( OldOutline );
    if ItemIndex = -1 then begin
        raise EPerfProject.Create( 'Internal error: Replacing foreign outline' );
    end;
    FOutlines[ItemIndex] := NewOutline;

    // swap every reference to old outline to point to new outline
    for i := 0 to BoardItemCount -1 do begin
        Item := TveBoardItem(FBoardItems[i]);
        if Item.Outline = OldOutline then begin
            Item.Outline := NewOutline;
{
            // adjust lead length so items "look good"
            if (NewOutline is TveLeadedOutline) and
                (not (OldOutline is TveLeadedOutline)) then begin
                Item.Length := TveLeadedOutline(NewOutline).BodyLength + 2;
            end;
}
        end;
    end;

    // get rid of old outline
    OldOutline.Free;
end;

function CompareOutlinesByName( P1, P2 : pointer ) : integer;
begin
    result := CompareDesignators( TveOutline(P1).Name, TveOutline(P2).Name );
end;

procedure TveProject.SortOutlines;
begin
    FOutlines.Sort( CompareOutlinesByName );
end;

function TveProject.MakeOutlineNameUnique( const Name : string ) : string;
var
    NameCount : integer;
begin
    // if a matching name exists, add (1) or (2) etc to name
    result  := Name;
    NameCount := 0;
    while OutlineByName( result  ) <> nil do begin
        Inc( NameCount );
        result := Format( '%s(%d)', [Name, NameCount] );
    end;
end;

function TveProject.MakeItemDesignatorUnique( const Designator : string ) : string;
var
    DesignatorCount : integer;
begin
    // if a matching name exists, add (1) or (2) etc to name
    result  := Designator;
    DesignatorCount := 0;
    while ItemByDesignator( result  ) <> nil do begin
        Inc( DesignatorCount );
        result := Format( '%s(%d)', [Designator, DesignatorCount] );
    end;
end;


function TveProject.GetSelectedCount : integer;
var
    i : integer;
begin
    // Count how many items are in selection list
    result := 0;
    for i := 0 to FBoardItems.Count -1 do begin
        if TveBoardItem(FBoardItems[i]).Selected then begin
            Inc( result );
        end;
    end;
end;

// ** IS MORE THAN ONE ITEM SELECTED ? **
// faster then GetSelectedCount because quits when 2 counted
function TveProject.MultipleSelected : boolean;
var
    i : integer;
    one : boolean;
begin
    // Count how many items are in selection list
    one := False;
    result := false;
    for i := 0 to FBoardItems.Count -1 do begin
        if TveBoardItem(FBoardItems[i]).Selected then begin
            if one then begin
                result := True;
                exit;
            end;
            one := True;
        end;
    end;
end;

// ** INTERNAL PROC CALLED TO QUICKLY SET DIRTY **

procedure TveProject.MakeDirty;
begin
    FDirty := True;
    if assigned( FOnChange ) then begin
        OnChange( Self );
    end;
end;


// ** DIRTY PROPERTY CHANGED WITH THIS CODE **

procedure TveProject.SetDirty( Value : boolean );
begin
    FDirty := Value;
    if assigned( OnChange ) then begin
        OnChange( Self );
    end;
end;


// ** FAST LOOKUP NET INFO USED FOR REAL TIME EDITING **

// ** Clear all fast net info - so net info not available during board editing **
procedure TveProject.ClearFastNets;
var
    i : integer;
begin
    for i := 0 to FBoardItems.Count -1 do begin
        TveBoardItem( FBoardItems[i] ).ClearNodes;
    end;

    MakeDirty;
end;

// ** Transfer Info from NetList to FastNets contained in BoardItems **

// Fast Net info permits on-the-fly display of net info during board editing.
// During transfer, Netlist component.name is matched with BoardItem.Designator

// If a match is not found, the nets associated with the net component are
// not transferred to a board item.  This is not an error, since the Netlist must
// exist independently of the board, so that discrepancies between the two
// can be reported and fixed by the user 1) editing the netlist 2) editing
// the BoardItems.

procedure TveProject.TransferFastNets;
var
    i : integer;
    NetComponent : TneComponent;
    BoardItem : TveBoardItem;
    j : integer;
    NetPin : TnePin;
    PinIndex : integer;
begin
    // erase existing data
    ClearFastNets;

    for i := 0 to FNetlist.ComponentCount -1 do begin
        NetComponent := FNetlist.Components[i];
        BoardItem := ItemByDesignator( NetComponent.Name );

        // if board item not found with same name as netlist component
        // then skip this component
        if BoardItem = nil then begin
            continue;
        end;

        // number of pins is limited due to fixed size of array behind
        // BoardItem.NodeAtPin[PinIndex] . 
        if BoardItem.Outline.PinCount > TveMaxPinIndex +1 then begin
            raise ESafePerfProject.CreateFmt(
            'Outline "%s" has more than %d pins. You must remove pins!',
            [BoardItem.Outline.Name, TveMaxPinIndex + 1]);
        end;

        // load board item pins to netlist map
        for j := 0 to NetComponent.PinCount -1 do begin
            NetPin := NetComponent.Pins[j];
            PinIndex := BoardItem.Outline.PinIndexByName( NetPin.Name );
            if PinIndex >= 0 then begin
                BoardItem.NodeAtPin[PinIndex] := NetPin.Node;
            end;
        end;
    end;
end;


// ** Find Bounding Rectangle Which Encloses All Selected Items **
procedure TveProject.GetSelectedItemsBoundary( var Rect : TRect );
var
    i : integer;
    Item : TveBoardItem;
    ItemRect : TRect;
    Bounds : TRect;
begin
    Bounds.Left := High(Bounds.Left);
    Bounds.Right := Low(Bounds.Right);
    Bounds.Top := High(Bounds.Top);
    Bounds.Bottom := Low(Bounds.Bottom);
    for i := 0 to BoardItemCount -1 do begin
        Item := BoardItems[i];
        if not Item.Selected then begin
            continue;
        end;
        Item.Outline.GetScreenRectR( Item, ItemRect );

        if Bounds.Left > ItemRect.Left     then Bounds.Left := ItemRect.Left;
        if Bounds.Right < ItemRect.Right   then Bounds.Right := ItemRect.Right;
        if Bounds.Top > ItemRect.Top       then Bounds.Top := ItemRect.Top;
        if Bounds.Bottom < ItemRect.Bottom then Bounds.Bottom := ItemRect.Bottom;
    end;

    // rectangle around all selected items
    Rect.Left := Bounds.Left;
    Rect.Top := Bounds.Top;
    Rect.Right := Bounds.Right;
    Rect.Bottom := Bounds.Bottom;
end;


// ** Find Bounding Rectangle Which Encloses Paint Area of Selected Items  **
procedure TveProject.GetSelectedItemsPaintBoundary( var Rect : TRect );
var
    i : integer;
    Item : TveBoardItem;
    ItemRect : TRect;
    BoundLeft, BoundRight, BoundTop, BoundBottom : integer;
begin
    BoundLeft := High(BoundLeft);
    BoundRight := Low(BoundRight);
    BoundTop := High(BoundTop);
    BoundBottom := Low(BoundBottom);
    for i := 0 to BoardItemCount -1 do begin
        Item := BoardItems[i];
        if not Item.Selected then begin
            continue;
        end;
        Item.Outline.GetPaintRect( Item, ItemRect );

        if BoundLeft > ItemRect.Left     then BoundLeft := ItemRect.Left;
        if BoundRight < ItemRect.Right   then BoundRight := ItemRect.Right;
        if BoundTop > ItemRect.Top       then BoundTop := ItemRect.Top;
        if BoundBottom < ItemRect.Bottom then BoundBottom := ItemRect.Bottom;
    end;

    Rect.Left := BoundLeft;
    Rect.Right := BoundRight;
    Rect.Top := BoundTop;
    Rect.Bottom := BoundBottom;
end;


// ** Count Number of Selected Items **
function TveProject.GetSelectedItemCount : integer;
var
    i : integer;
    Item : TveBoardItem;
begin
    result := 0;
    for i := 0 to FBoardItems.Count -1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if Item.Selected then begin
            Inc( result );
        end;
    end;
end;


// ** UNSELECT ALL ITEMS **

procedure TveProject.DeSelectAllItems;
var
    i : integer;
begin
    for i := FBoardItems.Count -1 downto 0 do begin
        TveBoardItem(FBoardItems[i]).Selected := False;
    end;
end;

procedure TveProject.ConnectivityCheck;
begin
    TveTracer( FTracer ).Check;
end;


procedure TveProject.ClearDesignErrors;
begin
    TveTracer( FTracer ).Clear;
end;


// *****************************************
//              UNDO & REDO
// *****************************************

procedure TveProject.Undo;
begin
//    TveUndo(FUndo).Undo;
  FUndoEng.Undo;
end;

procedure TveProject.Redo;
begin
//    TveUndo(FUndo).Redo;
  FUndoEng.Redo;
end;

procedure TveProject.ClearUndo;
begin
//    TveUndo(FUndo).Clear;
  FUndoEng.Clear;
end;

// *******************************************************
//                  SNAPSHOT For Undo
// *******************************************************

// tell each BoardItem in selection to record its current properties
procedure TveProject.SnapshotSelected;
var
    i : integer;
    Item : TveBoardItem;
begin
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if Item.Selected then begin
            Item.TakeSnapshot;
        end;
    end;
end;

// ***********************************************************
//              MultiStage Undo Actions
// ***********************************************************
// to create a complete Ctrl-Z undo operation, call BeginUndo,
// then one or more of the "xxxToUndo" functions, and finally EndUndo.

procedure TveProject.BeginUndo;
begin
  FUndoEng.BeginTransaction;
end;

procedure TveProject.EndUndo;
begin
  FUndoEng.EndTransaction;
end;

// **************
// Add item changes to an undo operation
// **************
procedure TveProject.ItemSnapshotToUndo( Item : TveBoardItem );
var
    Memento : TunMemento;
begin
    if Item.ChangedSinceSnapshot then begin
        Memento := Item.CreateMementoFromSnapshot;
        FUndoEng.AddMemento( Memento );
    end;
end;

// **************
// Add board item to project and include in an undo operation
// **************
procedure TveProject.AddItemToUndo( Item : TveBoardItem );
var
  Memento : TunItemListMemento;
begin
  Memento := TunItemListMemento.Create;
  Memento.ItemList := self;
  Memento.Item := Item;
  Memento.Operation := opAdd;
  AddBoardItem( Item );
  FUndoEng.AddMemento( Memento );
end;

// **************
// Remove board item from project and include in an undo operation
// **************
procedure TveProject.DeleteItemToUndo( Item : TveBoardItem );
var
  Memento : TunItemListMemento;
begin
  Memento := TunItemListMemento.Create;
  Memento.ItemList := self;
  Memento.Item := Item;
  Memento.Operation := opRemove;
  FUndoEng.AddMemento( Memento );
  // release item from Self, the container object
  ReleaseBoardItem( Item );
end;

// ********************************************************
//            Single Stage Undo Actions
// ********************************************************
// to create a complete Ctrl-Z undo operation, simply call one of these
// "xxxToUndo" functions.

// **************
// Create an undo operation from changes to a single board item
// **************
procedure TveProject.ItemSnapshotAsUndo( Item : TveBoardItem );
begin
    BeginUndo;
    ItemSnapshotToUndo( Item );
    EndUndo;
end;

// **************
// Create an undo operation from changes to selected board itema
// **************
procedure TveProject.SelectedItemsSnapshotAsUndo;
var
    i : integer;
    Item : TveBoardItem;
begin
    BeginUndo;

    // record changes to selected items
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if Item.Selected then begin
              ItemSnapshotToUndo( Item );
        end;
    end;

    EndUndo;
end;

// **************
// Remove an item from the board and Create an undo operation
// **************
procedure TveProject.DeleteItemAsUndo( Item : TveBoardItem );
begin
    BeginUndo;
    DeleteItemToUndo( Item );
    EndUndo;
end;

// **************
// Remove selected items from the board and Create an undo operation
// **************
procedure TveProject.DeleteSelectedItemsAsUndo;
var
  i : integer;
  Item : TveBoardItem;
begin
    BeginUndo;

    // delete selected and add to Undo
    for i := FBoardItems.Count - 1 downto 0 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if Item.Selected then begin
            DeleteItemToUndo( Item );
        end;
    end;

    EndUndo;
end;

// **************
// Add an item to the board and Create an undo operation
// **************
procedure TveProject.AddItemAsUndo( Item : TveBoardItem );
begin
  BeginUndo;
  AddItemToUndo( Item );
  EndUndo;
end;


// ************************************
//        GROUPING AND LOCKING
// ************************************
{
procedure TveProject.LockItem( Item : TveBoardItem );
begin

end;

procedure TveProject.UnlockItem( Item : TveBoardItem );
begin

end;
}


// *****************
// Clear Tag member of all Groups. Internal use.
// *****************
procedure TveProject.UntagGroups;
var
    i : integer;
    Group : TveGroup;
begin
    // untag all groups
    for i := 0 to FGroups.Count - 1 do begin
        Group := TveGroup( FGroups[i] );
        Group.Tag := False;
    end;
end;

// *****************
// Tag Groups that Contain at Least One Selected Member
// *****************
procedure TveProject.TagSelectedGroups;
var
    i : integer;
    Item : TveBoardItem;
begin
    // get Groups[] data correct
    RegisterGroups;

    // clear tags
    UntagGroups;

    // tag all groups that contain at least one selected member
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if (Item.Selected) and (Item.Group <> 0) then begin
            TveGroup(FGroups[Item.Group -1]).Tag := True;
        end;
    end;
end;

// *****************
// If any Groups contain some selected and some unselected members, Unselect
// all members of those Groups.
// *****************
procedure TveProject.RemovePartGroupsSelection;
var
    i : integer;
    Item : TveBoardItem;
begin
    // get Groups[] data correct
    RegisterGroups;

    // clear tags
    UntagGroups;

    // tag groups that contain at least one unselected member
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if (not Item.Selected) and (Item.Group <> 0) then begin
            TveGroup(FGroups[Item.Group -1]).Tag := True;
        end;
    end;

    // unselect all items that belong to tagged groups
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if (Item.Group <> 0) and TveGroup(FGroups[Item.Group -1]).Tag then begin
            Item.Selected := False;
        end;
    end;
end;

// *****************
// Uselect all items that belong to Groups. Call this to prevent selection
// of only some members of a group - that is not allowed, since we either
// select the whole group, or none of it.
// *****************

procedure TveProject.UnselectGroupMembers;
var
    i : integer;
    Item : TveBoardItem;
begin
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if (Item.Selected) and (Item.Group <> 0) then begin
            Item.Selected := False;
        end;
    end;
end;

// *****************
// After setting group numbers in items, can create group data structures
// to manage them.
// *****************
procedure TveProject.RegisterGroups;
var
    i : integer;
    GroupNo : integer;
    Item : TveBoardItem;
    HighestGroupNo : integer;
    Group : TveGroup;
const
    // don't allow more groups than this
    MAX_GROUP = 50;

begin
    // find highest group number
    HighestGroupNo := 0;
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        GroupNo := Item.Group;
        // discard any groups with outrageously high group number
        if (GroupNo < 0) or (GroupNo > MAX_GROUP) then begin
            Item.Group := 0;
        end
        // keep track of highest group number encountered
        else if GroupNo > HighestGroupNo then begin
            HighestGroupNo := GroupNo;
        end;
    end;

    // create any additional groups needed
    for i := FGroups.Count to HighestGroupNo -1 do begin
        FGroups.Add( TveGroup.Create );
    end;

    // activate the groups that have members
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if Item.Group > 0 then begin
            Group := TveGroup(FGroups[Item.Group-1]);
            Group.Allocated := True;
        end;
    end;
end;

// *****************
// Provide the number of a fresh group. We can assign this number to the
// group propery of TveBoardItems that we are placing in a group
// *****************

function TveProject.AllocateGroup : integer;
var
    Group : TveGroup;
    i : integer;
begin
    // work out new group number to use
    result := 0;
    Group := nil;
    for i := 0 to FGroups.Count - 1 do begin
        Group := TveGroup( FGroups[i] );
        if not Group.Allocated then begin
            // group numbers are 1-based
            result := i + 1;
            break;
        end;
    end;

    // if no free group - make one
    if result = 0 then begin
        Group := TveGroup.Create;
        FGroups.Add( Group );
        result := FGroups.Count;
    end;

    // set new group to allocated
    Group.Allocated := True;
end;

// *****************
// DeAllocate Group with number GroupNo
// *****************

procedure TveProject.DeAllocateGroup( GroupNo : integer );
begin
    TveGroup(FGroups[GroupNo -1]).Allocated := False;
end;


// *****************
// Group selected items. If any of items is in a group, merge that group into
// the new group.
// *****************
procedure TveProject.GroupSelected;
var
    i : integer;
    Group : TveGroup;
    GroupNo : integer;
    Item : TveBoardItem;
    MaxGroup : integer;
    SelectedCount : integer;
begin
    // highest group number we can have
    MaxGroup := FGroups.Count;

    // untag all groups
    UntagGroups;

    // tag all groups that contain one or more selected items
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if Item.Selected and (Item.Group > 0) and (Item.Group <= MaxGroup) then begin
            Group := TveGroup(FGroups[Item.Group-1]);
            Group.Tag := True;
        end;
    end;

    // add all group members to the selection - and make a count total
    // number of items in the selection
    SelectedCount := 0;
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if (Item.Group > 0) and (Item.Group <= MaxGroup) then begin
            Group := TveGroup(FGroups[Item.Group-1]);
            if Group.Tag then begin
                Item.Selected := True;
            end;
        end;
        if Item.Selected then begin
            Inc( SelectedCount );
        end;

    end;

    // if only one item or fewer is selected, cancel the group
    if SelectedCount < 2 then begin
        exit;
    end;


    // scrap any existing groups- we will make a new one that contains all items
    for i := 0 to FGroups.Count - 1 do begin
        Group := TveGroup( FGroups[i] );
        if Group.Tag then begin
            Group.Allocated := False;
        end;
    end;

    // allocate a new group
    GroupNo := AllocateGroup;

    // start Undo Recording
    SnapshotSelected;

    // apply group number to selected items
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if Item.Selected then begin
            // make change to item
            Item.Group := GroupNo;
        end;
    end;

    SelectedItemsSnapshotAsUndo;
end;


// *****************
// UnGroup selected items. Break up any groups that the selected items may
// belong to.
// *****************

procedure TveProject.UnGroupSelected;
var
    i : integer;
    Group : TveGroup;
    Item : TveBoardItem;
    MaxGroup : integer;
begin
    // highest group number we can have
    MaxGroup := FGroups.Count;

    // start Undo Recording
    BeginUndo;

    // find groups associated with all selected items and mark as de-allocated
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if Item.Selected then begin
            if (Item.Group > 0) and (Item.Group <= MaxGroup) then begin
                Group := TveGroup(FGroups[Item.Group-1]);
                Group.Allocated := False;
            end;

            // .. perform item de-group, recording to Undo
            Item.TakeSnapshot;
            Item.Group := 0;
            ItemSnapshotToUndo( Item );
        end;
    end;

    // find any items that were not selected, but also no longer have a group
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if (Item.Group > 0) and (Item.Group <= MaxGroup) then begin
            Group := TveGroup(FGroups[Item.Group-1]);
            if not Group.Allocated then begin

                // also de-group the item, with Undo
                Item.TakeSnapshot;
                Item.Group := 0;
                ItemSnapshotToUndo( Item );
            end;
        end;
    end;

    // finished single Undo transaction
    EndUndo;
end;

// *****************
// Toggle item selection. If item is part of a group, match the group
// selection to match the item. Following a call to UnselectItems, has effect
// of selecting item and group.
// *****************
procedure TveProject.ToggleComponentAndGroupSelection( Item : TveBoardItem );
var
    MaxGroup : integer;
    i : integer;
    GroupNo : integer;
    NewSelected : boolean;
begin
    // highest group number we can have
    MaxGroup := FGroups.Count;

    // find group belonging to our Item
    if (Item.Group > 0) and (Item.Group <= MaxGroup) then begin
        GroupNo := Item.Group;
    end
    else begin
        GroupNo := 0;
    end;

    // if no group then just toggle the one item
    if GroupNo = 0 then begin
        Item.Selected := not Item.Selected;
        exit;
    end;

    // set whole group to opposite Selected value to our Item
    NewSelected := not Item.Selected;
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if Item.Group = GroupNo then begin
            Item.Selected := NewSelected;
        end;
    end;
end;

// *****************
// Set to Selected all components and groups that lie wholly within the
// rectangular area Rect.
// *****************
procedure TveProject.AddComponentsAndGroupsInsideAreaToSelection( Rect : Trect );

    function GroupInsideRect( GroupNo : integer ) : boolean;
    var
        i : integer;
        Item : TveBoardItem;
    begin
        for i := 0 to FBoardItems.Count - 1 do begin
            Item := TveBoardItem( FBoardItems[i] );

            if Item.Group = GroupNo then begin
                // if found a group item outside rectangle, therefore, group is
                // not inside rectangel
                if not Item.Outline.InsideRectangleR( Item, Rect ) then begin
                    result := False;
                    exit;
                end;
            end;
        end;
        // all items were inside rectangle
        result := True;
    end;

var
    i : integer;
    Group : TveGroup;
    GroupNo : integer;
    Item : TveBoardItem;
    MaxGroup : integer;
begin
    RegisterGroups;

    // clear all groups Tag member
    UntagGroups;

    // Tag the groups that lie completely inside Rect
    for i := 0 to FGroups.Count - 1 do begin
        Group := TveGroup( FGroups[i] );
        if Group.Allocated then begin
            GroupNo := i + 1;

            // See if group members inside Rect
            if GroupInsideRect( GroupNo ) then begin
                Group.Tag := True;
            end;
        end;
    end;

    // select board items that are inside rectangle, but not associated with
    // a group
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );

        // if item not a member of a group
        if Item.Group = 0 then begin
            // if found a group item outside rectangle, therefore, group is
            // not inside rectangel
            if Item.Outline.InsideRectangleR( Item, Rect ) then begin
                Item.Selected := True;
            end;
        end;
    end;

    // highest group number we can have
    MaxGroup := FGroups.Count;

    // select board items that belong to board groups that are tagged
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );

        GroupNo := Item.Group;

        if (GroupNo > 0) and (GroupNo <= MaxGroup) then begin
            if TveGroup( FGroups[GroupNo -1] ).Tag then begin
                  Item.Selected := True;
            end;
        end;
    end;
end;


// *****************
// Detect if Selected Items contains part of a Group
// *****************
function TveProject.PartGroupInSelection : boolean;
var
    i : integer;
    Item : TveBoardItem;
begin
    // get Groups[] data correct
    RegisterGroups;

    // clear tags
    UntagGroups;

    // tag all groups that contain at least one selected member
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if (Item.Selected) and (Item.Group <> 0) then begin
            TveGroup(FGroups[Item.Group -1]).Tag := True;
        end;
    end;

    // look for a member of a tagged group that is not selected : that means
    // we have a part group in a selection.
    // tag all groups that contain at least one selected member
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if ( not Item.Selected) and
          (Item.Group <> 0) and
          TveGroup(FGroups[Item.Group -1]).Tag then begin
              result := True;
              exit;
        end;
    end;

    // no incomplete selected groups
    result := False;
end;

procedure TveProject.DeleteSelectedItems;
var
    i : integer;
    Item : TveBoardItem;
begin
    // set Tag field on groups that contain at least one selected member
    TagSelectedGroups;

    // clear tag field on groups that contain one or more unselected members
    for i := 0 to FBoardItems.Count - 1 do begin
        Item := TveBoardItem( FBoardItems[i] );
        if (not Item.Selected) and (Item.Group <> 0) then begin
            TveGroup(FGroups[Item.Group -1]).Tag := False;
        end;
    end;

    // start Undo Recording
    BeginUndo;

    // delete items
    for i := BoardItemCount -1 downto 0 do begin
        Item := BoardItems[i];
        if Item.Selected and
           (
           ( Item.Group = 0 ) or ( TveGroup(FGroups[Item.Group -1]).Tag )
           )
            then begin
            // delete the item to Undo
            DeleteItemToUndo( Item );
        end;
    end;

    EndUndo;

    // some groups may be missing
    RegisterGroups;
end;

// *********************************************
//         ADD-REMOVE ITEM MEMENTOS
// *********************************************

Procedure TunItemListMemento.Undo;
begin
    case Operation of
      // reverse an add operation by taking item out of container
      opAdd: begin
          ItemList.ReleaseBoardItem( Item );
      end;

      // reverse a remove operation by returning item to container
      opRemove: begin
          Item.Selected := True;
          ItemList.AddBoardItem( Item );
      end;
    end;
end;

Procedure TunItemListMemento.Redo;
begin
    case Operation of
      // redo an add operation that was previously UNDONE by returning
      // item to container
      opAdd: begin
          Item.Selected := True;
          ItemList.AddBoardItem( Item );
      end;

      // redo a remove operation by that was previously UNDONE by removing
      // the item once again
      opRemove: begin
          ItemList.ReleaseBoardItem( Item );
      end;
    end;
end;

Procedure TunItemListMemento.DiscardUndo;
begin
    case Operation of
      // throw away the Undo record for an Add Item by leaving the item
      // in the ItemList container
      opAdd: begin
      end;

      // throw away the Undo record for a Remove Item
      // by deleting the item that is owned by this Memento
      opRemove: begin
          Item.Free;
      end;
    end;
    // always dispose of this unwanted Memento
    Free;
end;

Procedure TunItemListMemento.DiscardRedo;
begin
    case Operation of
      // throw away the Redo record for an Add Item operation that was
      // previously UNDONE - delete the item owned by this Memento
      opAdd: begin
          Item.Free;
      end;

      // throw away the Redo record for a Remove Item operation that was
      // previously UNDONE - leave the item with its owning ItemList container
      opRemove: begin
      end;
    end;
    // always dispose of this unwanted Memento
    Free;
end;



end.



