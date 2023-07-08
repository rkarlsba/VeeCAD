unit Placement;

interface

uses Project, Classes;

type TvePlacement = class

  protected
    FProject : TveProject;
    Items : TList;
    procedure FillItemList;
  public

    property Project : TveProject read FProject write FProject;
    procedure PlaceUp;
    procedure PlaceDown;

    constructor Create;
    destructor Destroy; override;
end;

procedure PlaceComponents( Project : TveProject );


implementation

uses Outlines, SysUtils, SortCompare, BoardSize, Types;

// *******************************************
//          TvePlacement Class
// *******************************************

{ This class arranges components on the board.
}

constructor TvePlacement.Create;
begin
    Items := TList.Create;
end;

destructor TvePlacement.Destroy;
begin
    Items.Free;
    inherited;
end;


function CompareItemsForPlacement( P1, P2 : pointer ) : integer;
var
    Item1, Item2 : TveBoardItem;
    Outline1, Outline2 : TveOutline;
    Item1Rect : TRect;
    Item2Rect : TRect;
    Height1, Height2 : integer;
    Width1, Width2 : integer;
begin
    Item1 := TveBoardItem(P1);
    Item2 := TveBoardItem(P2);

    Outline1 := Item1.Outline;
    Outline2 := Item2.Outline;

    // bounding rectangle which contains item : click inside this to select
    Outline1.GetScreenRectR( Item1, Item1Rect );
    Outline2.GetScreenRectR( Item2, Item2Rect );

    // compare by height
    Height1 := Item1Rect.Bottom - Item1Rect.Top;
    Height2 := Item2Rect.Bottom - Item2Rect.Top;

    if Height1 > Height2 then begin
        result := 1;
    end
    else if Height1 < Height2 then begin
        result := -1
    end

    else begin

        // compare by width
        Width1 := Item1Rect.Right - Item1Rect.Left;
        Width2 := Item2Rect.Right - Item2Rect.Left;

        if Width1 > Width2 then begin
            result := 1
        end
        else if Width1 < Width2 then begin
            result := -1
        end

        // compare by outline name
        else begin
            result := CompareText( Item1.Outline.Name, Item2.Outline.Name );

            if result = 0 then begin

                // compare by designator
                result := CompareDesignators( Item1.Designator, Item2.Designator );
            end
        end;
    end;
end;

type TPlacementDirection = ( pmDown, pmUp );
const Direction : TPlacementDirection = pmDown;

procedure TvePlacement.FillItemList;
var
    i : integer;
    Item : TveBoardItem;
begin
    Items.Clear;


    // get references to board items in project which have "high level"
    // outlines - ie "components" which are defined in netlist, as distinct
    // from breaks, links, wires.
    for i := 0 to FProject.BoardItemCount -1 do begin
        Item := FProject.BoardItems[i];
        if Item.Outline.UserDefined then begin
            Items.Add( Item );
        end;
    end;

    // now sort item references by height, width, then outline then designator
    Items.Sort( CompareItemsForPlacement );
end;


procedure TvePlacement.PlaceUp;
var
    i : integer;
    Item : TveBoardItem;

    RowBottom : integer;
    RowHeight : integer;
    x : integer;
    BoardWidth : integer;

    Outline : TveOutline;
    ItemRect : TRect;
    ItemHeight : integer;
    ItemWidth : integer;
    RowItemCount : integer;
begin
    // fill list with BoardItem references, sorted in layout order.
    FillItemList;

    // record change in Undo ** not needed since only called on import
    Project.BeginUndo;

    // now place smallest item in bottom left, and work across
    RowBottom := FProject.BoardHeight -1;
    RowHeight := 0;
    RowItemCount := 0;
    BoardWidth := FProject.BoardWidth;
    x := BoardWidth;  // right to left

    for i := 0 to Items.Count -1 do begin
        Item := TveBoardItem( Items[i] );
        Outline := Item.Outline;

        // bounding rectangle which contains item : click inside this to select
        Outline.GetScreenRectR( Item, ItemRect );
        ItemWidth := ItemRect.Right - ItemRect.Left;
        ItemHeight := ItemRect.Bottom - ItemRect.Top;

        // if will go past end of row, move to next row - provided we have at
        // least one item in the row
        if (RowItemCount > 0) and (x < ItemWidth) then begin
            RowItemCount := 0;
            x := BoardWidth;    // left to right
            Dec( RowBottom, RowHeight );
        end;

        // record item position, text position
        Item.TakeSnapshot;

        // move item
        Item.X := x - ( ItemRect.Left - Item.X ) - ItemWidth;  // right to left
        Item.Y := RowBottom - ItemHeight - ( ItemRect.Top - Item.Y );

        // adjust position & text position so item & text is on the board
        RescueOffBoardItem( Item, BoardWidth, Project.BoardHeight );

        // record item and XY, TextXY displacements
        Project.ItemSnapshotToUndo( Item );

        // move to next location across row
        x := x - ItemWidth;     // left to right
        Inc( RowItemCount );

        // record largest component height yet encountered
        // (largest because that is sort order)
        RowHeight := ItemHeight;
    end;

    Project.EndUndo;
    Project.Dirty := True;
end;

procedure TvePlacement.PlaceDown;
var
    i : integer;
    Item : TveBoardItem;

    RowTop : integer;
    RowHeight : integer;
    x : integer;
    BoardWidth : integer;

    Outline : TveOutline;
    ItemRect : TRect;
    ItemHeight : integer;
    ItemWidth : integer;
    RowItemCount : integer;
begin
    // fill list with BoardItem references, sorted in layout order.
    FillItemList;

    // now place smallest item in top left, and work across
    RowTop := 0;
    RowHeight := 0;
    x := 0;
    RowItemCount := 0;
    BoardWidth := FProject.BoardWidth;

    for i := 0 to Items.Count -1 do begin
        Item := TveBoardItem( Items[i] );
        Outline := Item.Outline;

        // bounding rectangle which contains item : click inside this to select
        Outline.GetScreenRectR( Item, ItemRect );
        ItemWidth := ItemRect.Right - ItemRect.Left;
        ItemHeight := ItemRect.Bottom - ItemRect.Top;

        // if will go past end of row, move to next row - provided we have at
        // least one item in the row
        if (RowItemCount > 0) and (ItemWIdth > BoardWidth - x) then begin
            RowItemCount := 0;
            x := 0;
            Inc( RowTop, RowHeight );
        end;

        // place item
        Item.X := x - ( ItemRect.Left - Item.X );
        Item.Y := RowTop - ( ItemRect.Top - Item.Y );

        // move to next location across row
        x := x + ItemWidth;
        Inc( RowItemCount );

        // record largest component height yet encountered
        // (largest because that is sort order)
        RowHeight := ItemHeight;
    end;
end;


procedure PlaceComponents( Project : TveProject );
var
    Placement : TvePlacement;
begin
    Placement := TvePlacement.Create;
    try
        Placement.Project := Project;
        Placement.PlaceUp;
    finally
        Placement.Free;
    end;
end;

end.


