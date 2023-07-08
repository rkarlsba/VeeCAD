unit RouteLeaded;

interface

uses Classes,
    Project, Connective, Outlines;

type TroPlacement = record
    X : integer;
    StartY : integer;
    EndY : integer;
    FromStripAbove : boolean;
    Valid : boolean;
end;

type TroMoveBreakPlacement = record

    X : integer;
    StartY : integer;
    EndY : integer;
    FromStripAbove : boolean;
    Valid : boolean;

    // first break Y
    BreakLeftY : integer;
    // first break original X
    BreakLeftFromX : integer;
    // first break new X
    BreakLeftToX : integer;

    // second break Y
    BreakRightY : integer;
    // second break original X
    BreakRightFromX : integer;
    // second break new X
    BreakRightToX : integer;

    RightStrip : TcnStrip;
    LeftStrip : TcnStrip;
end;


type TLeadedRouter = class
  protected
    FProject : TveProject;
    FConnectivity : TConnectivity;

    ItemPlaced : boolean;
    OffBoardLeadedItems : TList;

    function InternalPlaceItem( Item : TveBoardItem ) : boolean;
    function PlaceBetweenStrips( Item : TveBoardItem; FromStrip, ToStrip : TcnStrip ): TroPlacement;
    function InternalPlaceItemWithBreakShift( Item : TveBoardItem ) : boolean;
    function PlaceBetweenStripsWithBreakShift(
        Item : TveBoardItem; FromStrip, ToStrip : TcnStrip ): TroMoveBreakPlacement;
  public
    property Project : TveProject read FProject write FProject;

    procedure PlaceSelectedLeadedItem;
    procedure PlaceSelectedLeadedItems;
    procedure PlaceAllLeadedItems;
    constructor Create;
    destructor Destroy; override;
end;


implementation

uses SizeableOutlines, OtherOutlines, Netlist, Math, Rotations, Types;

constructor TLeadedRouter.Create;
begin
    OffBoardLeadedItems := TList.Create;
end;

destructor TLeadedRouter.Destroy;
begin
    OffBoardLeadedItems.Free;
    inherited;
end;


// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//                  PUBLIC FUNCTIONS
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

// *******************************************
//             Public Functions
// *******************************************
{
    Find the leaded item which is selected in FProject.  Adjust its position
    and length so its ends connect to strips of the correct nets.
    This single item place is just for testing.  It does not remove all items
    from board before letting DRC allocate strips.  Modify it to
    "Place Selected Item" for real value.
}
procedure TLeadedRouter.PlaceSelectedLeadedItem;
var
    i : integer;
    SelectedCount : integer;
    item : TveBoardItem;
    SelectedItem : TveBoardItem;
begin
    FConnectivity := TConnectivity( FProject.ConnectivityObject );

    // avoid "Unitialised Variable" warning
    Item := nil;

    // find a single item which is selected
    SelectedItem := nil;
    SelectedCount := 0;
    for i := FProject.BoardItemCount -1 downto 0 do begin
        Item := FProject.BoardItems[i];
        if Item.Selected then begin
            SelectedItem := Item;
            inc( SelectedCount );
        end;
    end;

    // wrong kind of outline or zero or multiple outlines are selected, do nothing
    if (SelectedCount <> 1) or not(SelectedItem.Outline is TveLeadedOutline) or (Item.Group <> 0) then begin
        exit;
    end;

    // take item off the board
    FProject.ReleaseBoardItem( SelectedItem );
    try
        // get DRC checker to identify strips - with leaded item absent
        FConnectivity.Check;
        FConnectivity.GenerateNetSets;

        // move this component and adjust its length so it is correctly connected
        // simple placement
        if not InternalPlaceItem( SelectedItem ) then begin
            // clever placement slides breaks to make connection possible
            InternalPlaceItemWithBreakShift( SelectedItem );
        end;

    finally
        FProject.AddBoardItem( SelectedItem );
    end;
end;

{
    Remove *selected* leaded items off the board, then place each one between
    strip pairs so its ends connect to strips of the correct nets.
}
procedure TLeadedRouter.PlaceSelectedLeadedItems;
var
    i : integer;
    item : TveBoardItem;
begin
    FConnectivity := TConnectivity( FProject.ConnectivityObject );

    // take all leaded items off the board
    OffBoardLeadedItems.Count := 0;
    for i := FProject.BoardItemCount -1 downto 0 do begin
        Item := FProject.BoardItems[i];
        if (Item.Outline is TveLeadedOutline) and Item.Selected and
                (Item.Group = 0) then begin
            OffBoardLeadedItems.Add( Item );
            FProject.ReleaseBoardItem( Item );
        end;
    end;

    try
        // get DRC checker to identify strips - with leaded items absent
        FConnectivity.Check;
        FConnectivity.GenerateNetSets;


        // for each offboard leaded item..
        for i := OffBoardLeadedItems.Count -1 downto 0 do begin

            Item := TveBoardItem( OffBoardLeadedItems[i] );

            // attempt to place the item : if placement succeeds, put item
            // back on the board, so its position is no longer available.
            if InternalPlaceItem( Item ) then begin
                OffBoardLeadedItems.Delete( i );
                FProject.AddBoardItem( Item );
            end;
        end;

        // try to place any remaining parts using break shifting
        // for each offboard leaded item..
        for i := OffBoardLeadedItems.Count -1 downto 0 do begin

            Item := TveBoardItem( OffBoardLeadedItems[i] );

            // attempt to place the item with break shift : if placement succeeds,
            // put item back on the board, so its position is no longer available.
            if InternalPlaceItemWithBreakShift( Item ) then begin
                OffBoardLeadedItems.Delete( i );
                FProject.AddBoardItem( Item );
            end;
        end;

    finally
        // replace any board items still off the board
        for i := OffBoardLeadedItems.Count -1 downto 0 do begin
            Item := TveBoardItem( OffBoardLeadedItems[i] );
            FProject.AddBoardItem( Item );
        end;
    end;

end;


{
    Remove all leaded items off the board, then place each one between strip
    pairs so its ends connect to strips of the correct nets.
}

procedure TLeadedRouter.PlaceAllLeadedItems;
var
    i : integer;
    item : TveBoardItem;
begin
    FConnectivity := TConnectivity( FProject.ConnectivityObject );

    // take all leaded items off the board
    OffBoardLeadedItems.Count := 0;
    for i := FProject.BoardItemCount -1 downto 0 do begin
        Item := FProject.BoardItems[i];
        if (Item.Outline is TveLeadedOutline) and (Item.Group = 0) then begin
            OffBoardLeadedItems.Add( Item );
            FProject.ReleaseBoardItem( Item );
        end;
    end;

    try
        // get DRC checker to identify strips - with leaded items absent
        FConnectivity.Check;
        FConnectivity.GenerateNetSets;


        // for each offboard leaded item..
        for i := OffBoardLeadedItems.Count -1 downto 0 do begin

            Item := TveBoardItem( OffBoardLeadedItems[i] );

            // attempt to place the item : if placement succeeds, put item
            // back on the board, so its position is no longer available.
            if InternalPlaceItem( Item ) then begin
                OffBoardLeadedItems.Delete( i );
                FProject.AddBoardItem( Item );
            end;
        end;

        // try to place any remaining parts using break shifting
        // for each offboard leaded item..
        for i := OffBoardLeadedItems.Count -1 downto 0 do begin

            Item := TveBoardItem( OffBoardLeadedItems[i] );

            // attempt to place the item with break shift : if placement succeeds,
            // put item back on the board, so its position is no longer available.
            if InternalPlaceItemWithBreakShift( Item ) then begin
                OffBoardLeadedItems.Delete( i );
                FProject.AddBoardItem( Item );
            end;
        end;

    finally
        // replace any board items still off the board
        for i := OffBoardLeadedItems.Count -1 downto 0 do begin
            Item := TveBoardItem( OffBoardLeadedItems[i] );
            FProject.AddBoardItem( Item );
        end;
    end;

end;



// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//                  SIMPLE ROUTING
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&


// *******************************************************
//              COMPARE TWO PLACEMENTS
// *******************************************************
{
    Two links are compared and an integer returned:
    1 = Placement 1 better
    -1 = Placement 2 better
    0 = Placement1, Placement2 equal "goodness"
}

function ComparePlacements( const Placement1, Placement2 : TroPlacement ) : integer;
var
    Length1, Length2 : integer;
begin
    if Placement1.Valid and (not Placement2.Valid) then begin
        result := 1;
    end
    else if (not Placement1.Valid) and (Placement2.Valid) then begin
        result := -1;
    end
    else if (not Placement1.Valid) and (not Placement2.Valid) then begin
        result := 0;
    end
    else begin

      Length1 := abs(Placement1.EndY - Placement1.StartY);
      Length2 := abs(Placement2.EndY - Placement2.StartY);

      if Length1 < Length2 then begin
          result := 1;
      end
      else if Length1 > Length2 then begin
          result := -1;
      end
      else begin
          result := 0;
      end;

    end;
end;


// ***************************************************
//              PLACE A LEADED ITEM
// ***************************************************
{
    Item.Outline MUST be TveLeadedOutline class.
    If item can be placed, returns True, otherwise it returns false.
}

function TLeadedRouter.InternalPlaceItem( Item : TveBoardItem ) : boolean;

    function GetNetSet( Net : TneNode ) : TcnNetSet;
    var
        i : integer;
    begin
        for i := 0 to FConnectivity.NetSetCount - 1 do begin
            result := FConnectivity.NetSets[ i ];
            if result.Net = Net then begin
                exit;
            end;
        end;
        // no stripset for our net
        result := nil;
    end;

var
    OriginalX, OriginalY : integer;
    OriginalEndDeltaX, OriginalEndDeltaY : integer;

    i, j : integer;
    FromNetSet, ToNetSet : TcnNetSet;
    FromStrip, ToStrip : TcnStrip;
    TestedPlacement, BestPlacement : TroPlacement;
begin
    // get stripsets for the two pins of our component
    // could also use outlines pin discovery functions, in case
    // pin numbering becomes alterable for example ...
    //    procedure ToFirstPin; virtual; abstract;
    //    function GetNextPin(
    //        Item : TveBoardItem; var X, Y, PinNo : integer ) : boolean; virtual; abstra

    // FROM NET is net of Pin1
    FromNetSet := GetNetSet( TneNode(Item.NodeAtPin[0]) );
    if FromNetSet = nil then begin
        result := False;
        exit;
    end;

    // TO NET is net of Pin2
    ToNetSet := GetNetSet( TneNode(Item.NodeAtPin[1]) );
    if ToNetSet = nil then begin
        result := False;
        exit;
    end;

    // before we move component about, save original disposition
    OriginalX := Item.X;
    OriginalY := Item.Y;
    OriginalEndDeltaX := Item.EndDeltaX;
    OriginalEndDeltaY := Item.EndDeltaY;

    // before undo
    Item.TakeSnapshot;

    // evaluate component placement between every possible strip pair, storing
    // the currently best result in BestPlacement
    BestPlacement.Valid := False;
    // ..for every strip in FromStripSet
    for i := FromNetSet.Count -1 downto 0 do begin

        FromStrip := FromNetSet.Strips[i];

        // for every strip in ToStripSet
        for j := ToNetSet.Count -1 downto 0 do begin

            ToStrip := ToNetSet.Strips[j];

            // evaluate component placed between the 2 strips
            // EvaluateBetweenStrips()
            TestedPlacement := PlaceBetweenStrips( Item, FromStrip, ToStrip );
            if ComparePlacements( TestedPlacement, BestPlacement ) > 0 then begin
                BestPlacement := TestedPlacement;
            end
        end;
    end;

    // if a valid placement exists, move the component to that position
    if BestPlacement.Valid then begin

        Item.Length := BestPlacement.EndY - BestPlacement.StartY;
        Item.X := BestPlacement.X;
        // which way to rotate item?
        if BestPlacement.FromStripAbove then begin
            Item.Y := BestPlacement.StartY;
            Item.Rotation := Rot0;
        end
        else begin
            Item.Y := BestPlacement.EndY;
            Item.Rotation := Rot180;
        end;

        //** WARNING - TEXT MAY BE OFF SCREEN - NEED TO FIX THIS
        // adjust text position so text not off screen

        // component moved - store in Undo
        Project.ItemSnapshotToUndo( Item );

        // placement successful
        result := True;
    end

    //else put component back to its old position;
    else begin
        Item.X := OriginalX;
        Item.Y := OriginalY;
        Item.EndDeltaX := OriginalEndDeltaX;
        Item.EndDeltaY := OriginalEndDeltaY;
        result := False;
    end;
end;



// *******************************************
//             PlaceBetweenStrips
// *******************************************
{
    Given two strips, find the best possible position "BestX" for the leaded
    component (Item) along the strips, and return a TroPlacement placement
    record which describes that placement

    This code fakes it - we do not find "BestX" - we find the
    first valid position scanning from the left.  To find best possible X we
    would have to keep a "BestPlacementX" record which stores the ratings of the
    best link tried to date.  This may not be worth the trouble - a "relax"
    process might be better - relaxing looks over the board and moves links
    and leaded parts sideways to get vertical alignment of links, thus freeing
    up long vertical runs which could take links.
}

function TLeadedRouter.PlaceBetweenStrips(
    Item : TveBoardItem; FromStrip, ToStrip : TcnStrip ) : TroPlacement;

var
    StartX, EndX : integer;     // X range in common with both strips
    LowY, HighY : integer;
    Temp : integer;
    FromStripAbove : boolean;

    Outline : TveLeadedOutline;
    ItemBounds : TRect;

    Item2 : TveBoardItem;
    Item2Bounds : TRect;

    i,j : integer;
    Dummy : TRect;
    Obstructed : boolean;

begin
    // find X coord range shared by both strips
    StartX := Max( FromStrip.Start.X, ToStrip.Start.X );
    EndX := Min( FromStrip.Finish.X, ToStrip.Finish.X );

    // if no overlap
    // .. NB, a one cell length strip has StartX = EndX
    if StartX > EndX then begin
        result.Valid := False;
        exit;
    end;

    // grab Y coords of two strips
    LowY := FromStrip.Start.Y;
    HighY := ToStrip.Start.Y;
    if LowY > HighY then begin
        Temp := LowY;
        LowY := HighY;
        HighY := Temp;
        // From strip is *below* To strip
        FromStripAbove := False
    end
    else begin
        // From strip is *above* To strip
        FromStripAbove := True;
    end;

    // quick reference local variable
    Outline := TveLeadedOutline(Item.Outline);

    // we refuse to place a leaded component with pins closer together than
    // body length
    if (HighY - LowY) < Outline.BodyLength then begin
        result.Valid := False;
        exit;
    end;

    // size item so it fits between our strips
    Item.Rotation := Rot0;
    Item.Length := HighY - LowY;

    // place the leaded component vertically between our strips, with pins
    // x-coord set to i . Now see if pin, lead and body area is free of overlap
    // with any other component.
    // between these end points
    for i := StartX to EndX do begin
        Obstructed := False;

        // calculate body rectangle in board coords
        Item.X := i;
        Item.Y := LowY;
        //Outline.GetScreenRect( Item, ItemLeft, ItemRight, ItemTop, ItemBottom );
        Outline.GetScreenRectR( Item, ItemBounds );

        // see if any component overlaps our rectangle
        for j := FProject.BoardItemCount -1 downto 0 do begin

            Item2 := FProject.BoardItems[j];

            // ignore breaks
            if (Item2.Outline is TveBreakOutline) then begin
                continue;
            end;

            // get screen rect occupied by Item2
//            Item2.Outline.GetScreenRect( Item2, ItemLeft2, ItemRight2, ItemTop2, ItemBottom2 );
            Item2.Outline.GetScreenRectR( Item2, Item2Bounds );

            // check if our leaded component overlaps this other component
            // IntersectRect() not particularly fast, could add a function
            // RectanglesOverlap() to Rectangles.pas
            if IntersectRect( Dummy, ItemBounds, Item2Bounds ) then begin
                Obstructed := True;
                break;
            end;
        end;

        if not Obstructed then begin
            result.Valid := True;
            result.X := i;
            result.StartY := LowY;
            result.EndY := HighY;
            result.FromStripAbove := FromStripAbove;
            exit;
        end;
    end;

    // never went round the loop OR never found a match
    result.Valid := False;
end;





// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//              BREAK-SHIFT ROUTING
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

// *****************************************
// *****************************************

function LeadedComponentFits( x, LowY, HighY : integer; Item : TveBoardItem ) : boolean;
begin
    result := False;
end;


// *******************************************
//    Place Between Strips With Break Shift
// *******************************************
{
    Given two strips, find the best possible position "BestX" for the leaded
    component (Item) along the strips, and return a TroPlacement placement
    record which describes that placement

    Same as PlaceBetweenStrips() except slides breaks sideways to improve
    overlap zone between strips.

    Has same limitation as PlaceBetweenStrips() - settles for first link that
    works.
}

function TLeadedRouter.PlaceBetweenStripsWithBreakShift(
    Item : TveBoardItem; FromStrip, ToStrip : TcnStrip ): TroMoveBreakPlacement;

    // see if anything is obstructing this strip
    function CellFree( x, y : integer ) : boolean;
    var
        index : integer;
        Item : TveBoardItem;
    begin
        index := 0;
        while True do begin

            FProject.GetNextItemAt( Item, Index, x, y );
            if Item = nil then begin
                result := true;
                exit;
            end;

            if not (Item.Outline is TveBreakOutline) then begin
                result := false;
                exit;
            end;
        end;
    end;


const
    MAX_OVERLAP = 3;
    MAX_EXTEND = 2;
var
    OverlapStartX: integer;
    OverlapEndX : integer;
    Overlap : integer;
//    LeftStrip : TdrStrip;
//    RightStrip : TdrStrip;
    LeftStrip : TcnStrip;
    RightStrip : TcnStrip;
    LeftStripXRightSave, RightStripXLeftSave : integer;
    LeftStripNewEnd: integer;
    RightStripNewEnd: integer;
    x: integer;
    ZoneLeft: integer;
    ZoneRight: integer;
    TestedPlacement : TroPlacement;

begin
    {   ********************GG                     small gap GG
                            GG*****************
    }

    {   ********************                     small overlap GG
                          GG
                          *****************

    Note that CheckerStrip.XRight is coord of last cell in the strip, not
    bounding coord.
    }

    // if strips are co-linear, we cannot link them!
    if FromStrip.Start.Y = ToStrip.Start.Y then begin
        result.Valid := False;
        exit;
    end;


    // see if the extend left and extend right will cause additional overlap
    // find X coord range shared by both strips
    OverlapStartX := Max( FromStrip.Start.X, ToStrip.Start.X );
    OverlapEndX := Min( FromStrip.Finish.X, ToStrip.Finish.X );
    Overlap := OverlapEndX - OverlapStartX + 1;

    // We are interested in a small small overlap or small gap (negative overlap)
    // We are just catching the cases a vertical row of breaks prevents a strips
    // being joined by vertical links.
    if Abs(Overlap) > MAX_OVERLAP then begin
        result.Valid := False;
        exit;
    end;

    // find which strip is left, which is right
    if FromStrip.Start.X < ToStrip.Start.X then begin
        LeftStrip := FromStrip;
        RightStrip := ToStrip;
    end
    else begin
        LeftStrip := ToStrip;
        RightStrip := FromStrip;
    end;

    //  extend left strip toward right
    LeftStripNewEnd := Min(
        LeftStrip.Finish.X + MAX_EXTEND, FProject.BoardWidth -1 );

    //. See if cells are free for the extension
    //. Next cell has a break, but may be overlaid with a component,
    //. include it in check for free cells
    //. At the end of extended strip we need to place a break
    for x := LeftStrip.Finish.X + 1 to LeftStripNewEnd do begin
        if not CellFree( x, LeftStrip.Start.Y ) then begin
            LeftStripNewEnd := x -1;
            break;
        end;
    end;

    //. if we are not at board edge, we need an extra clear cell for a break
    if LeftStripNewEnd < FProject.BoardWidth -1 then begin
        if not CellFree( LeftStripNewEnd +1, LeftStrip.Start.Y ) then begin
            dec(LeftStripNewEnd);
        end;
    end;
    //.. (now LeftStripNewEnd equals possible end of extended left strip)


    //  extend right strip toward left
    RightStripNewEnd := Max( RightStrip.Start.X - MAX_EXTEND, 0 );

    //. see if cells are free for the extension
    //. next cell has a break and so is available.
    //. at the end of extended strip we need to place a break

    for x := RightStrip.Start.X -1 downto RightStripNewEnd do begin
        if not CellFree( x, RightStrip.Start.Y ) then begin
            RightStripNewEnd := x +1;
            break;
        end;
    end;

    //. if we are not at board edge, we need an extra clear cell for a break
    if RightStripNewEnd > 0 then begin
        if not CellFree( RightStripNewEnd -1, RightStrip.Start.Y ) then begin
            inc(RightStripNewEnd);
        end;
    end;
    //.. (now RightStripNewEnd equals possible end of extended right strip)


    // calculate overlap zone of two extended areas
    ZoneLeft := Max( RightStripNewEnd, LeftStrip.Start.X );
    ZoneRight := Min( LeftStripNewEnd, RightStrip.Finish.X );

    // save original strip lengths
    LeftStripXRightSave := LeftStrip.Finish.X;
    RightStripXLeftSave := RightStrip.Start.X;

    // set strip lengths to new values
    LeftStrip.Finish.X := ZoneRight;
    RightStrip.Start.X := ZoneLeft;

    // place component and get rating
    // either call PlaceBetweenStrips, or do it in code right here
    TestedPlacement := PlaceBetweenStrips( Item, FromStrip, ToStrip );

    // restore strip lengths
//    LeftStrip.XRight := LeftStripXRightSave;
//    RightStrip.XLeft := RightStripXLeftSave;
    LeftStrip.Finish.X := LeftStripXRightSave;
    RightStrip.Start.X := RightStripXLeftSave;

    // Build result
    result.X := TestedPlacement.X;
    result.StartY := TestedPlacement.StartY;
    result.EndY := TestedPlacement.EndY;
    result.FromStripAbove := TestedPlacement.FromStripAbove;
    result.Valid := TestedPlacement.Valid;

    // first break Y
    result.BreakLeftY := LeftStrip.Start.Y;
    // first break original X
    result.BreakLeftFromX := LeftStrip.Finish.X + 1;
    // first break new X
    result.BreakLeftToX := Max( result.X + 1, result.BreakLeftFromX );

    // second break Y
    result.BreakRightY := RightStrip.Start.Y;
    // second break original X
    result.BreakRightFromX := RightStrip.Start.X - 1 ;
    // second break new X
    result.BreakRightToX := Min( result.X - 1, result.BreakRightFromX );

    result.RightStrip := RightStrip;
    result.LeftStrip := LeftStrip;
end;


// *******************************************************
//              COMPARE TWO PLACEMENTS
// *******************************************************
{
    Two links are compared and an integer returned:
    1 = Placement 1 better
    -1 = Placement 2 better
    0 = Placement1, Placement2 equal "goodness"
}

function ComparePlacementsBreakShifted( const Placement1, Placement2 : TroMoveBreakPlacement ) : integer;
var
    Length1, Length2 : integer;
begin
    if Placement1.Valid and (not Placement2.Valid) then begin
        result := 1;
    end
    else if (not Placement1.Valid) and (Placement2.Valid) then begin
        result := -1;
    end
    else if (not Placement1.Valid) and (not Placement2.Valid) then begin
        result := 0;
    end
    else begin

      Length1 := abs(Placement1.EndY - Placement1.StartY);
      Length2 := abs(Placement2.EndY - Placement2.StartY);

      if Length1 < Length2 then begin
          result := 1;
      end
      else if Length1 > Length2 then begin
          result := -1;
      end
      else begin
          result := 0;
      end;

    end;
end;


function TLeadedRouter.InternalPlaceItemWithBreakShift( Item : TveBoardItem ) : boolean;

    function GetNetSet( Net : TneNode ) : TcnNetSet;
    var
        i : integer;
    begin
        for i := 0 to FConnectivity.NetSetCount - 1 do begin
            result := FConnectivity.NetSets[ i ];
            if result.Net = Net then begin
                exit;
            end;
        end;
        // no stripset for our net
        result := nil;
    end;

    function GetBreakAt( x, y : integer ) : TveBoardItem;
    var
        Index : integer;
        Item : TveBoardItem;
    begin
        // no break found yet
        result := nil;

        // a component body or pin means an obstruction
        Index := 0;
        while true do begin

            // See if this cell contains part of a board item
            // ..GetNextItemAt() is slow - we may need to make a map of cells
            // ..occupied by component pins & bodies.
            FProject.GetNextItemAt( Item, Index, x, y );

            // no more items - finished checking
            if Item = nil then begin
                break;
            end;

            // anything other than a break is an obstruction - no path for link
            if (Item.Outline is TveBreakOutline) then begin
                result := Item;
                break;
            end;
        end;
    end;

var
    OriginalX, OriginalY : integer;
    OriginalEndDeltaX, OriginalEndDeltaY : integer;

    i, j : integer;
    FromNetSet, ToNetSet : TcnNetSet;
//    FromStrip, ToStrip : TdrStrip;
    FromStrip, ToStrip : TcnStrip;
    TestedPlacement, BestPlacement : TroMoveBreakPlacement;
    BreakItem : TveBoardItem;
//    Strip : TdrStrip;
    Strip : TcnStrip;

begin
    // get stripsets for the two pins of our component
    // could also use outlines pin discovery functions, in case
    // pin numbering becomes alterable for example ...
    //    procedure ToFirstPin; virtual; abstract;
    //    function GetNextPin(
    //        Item : TveBoardItem; var X, Y, PinNo : integer ) : boolean; virtual; abstra

    // FROM NET is net of Pin1
    FromNetSet := GetNetSet( TneNode(Item.NodeAtPin[0]) );
    if FromNetSet = nil then begin
        result := False;
        exit;
    end;

    // TO NET is net of Pin2
    ToNetSet := GetNetSet( TneNode(Item.NodeAtPin[1]) );
    if ToNetSet = nil then begin
        result := False;
        exit;
    end;

    // before we move component about, save original disposition
    OriginalX := Item.X;
    OriginalY := Item.Y;
    OriginalEndDeltaX := Item.EndDeltaX;
    OriginalEndDeltaY := Item.EndDeltaY;
    //

    // evaluate component placement between every possible strip pair, storing
    // the currently best result in BestPlacement
    BestPlacement.Valid := False;
    // ..for every strip in FromStripSet
    for i := FromNetSet.Count -1 downto 0 do begin

        FromStrip := FromNetSet.Strips[i];

        // for every strip in ToStripSet
        for j := ToNetSet.Count -1 downto 0 do begin

            ToStrip := ToNetSet.Strips[j];

            // evaluate component placed between the 2 strips
            // EvaluateBetweenStrips()
            TestedPlacement := PlaceBetweenStripsWithBreakShift( Item, FromStrip, ToStrip );
            if ComparePlacementsBreakShifted( TestedPlacement, BestPlacement ) > 0 then begin
                BestPlacement := TestedPlacement;
            end
        end;
    end;

    // if a valid placement exists, move the component to that position
    if BestPlacement.Valid then begin

        // before undo
        Item.TakeSnapshot;

        Item.Length := BestPlacement.EndY - BestPlacement.StartY;
        Item.X := BestPlacement.X;
        // which way to rotate item?
        if BestPlacement.FromStripAbove then begin
            Item.Y := BestPlacement.StartY;
            Item.Rotation := Rot0;
        end
        else begin
            Item.Y := BestPlacement.EndY;
            Item.Rotation := Rot180;
        end;

        // component moved - store in Undo
        Project.ItemSnapshotToUndo( Item );

        //** WARNING - TEXT MAY BE OFF SCREEN - NEED TO FIX THIS
        // adjust text position so text not off screen

        // move first break
        if BestPlacement.BreakLeftFromX <> BestPlacement.BreakLeftToX then begin
            BreakItem := GetBreakAt( BestPlacement.BreakLeftFromX, BestPlacement.BreakLeftY );
            if BreakItem <> nil then begin
                BreakItem.TakeSnapshot;
                BreakItem.X := BestPlacement.BreakLeftToX;
                Project.ItemSnapshotToUndo( BreakItem );
            end;
        end;
        // move second break
        if BestPlacement.BreakRightFromX <> BestPlacement.BreakRightToX then begin
            BreakItem := GetBreakAt( BestPlacement.BreakRightFromX, BestPlacement.BreakRightY );
            if BreakItem <> nil then begin
                BreakItem.TakeSnapshot;
                BreakItem.X := BestPlacement.BreakRightToX;
                Project.ItemSnapshotToUndo( BreakItem );
            end;
        end;

        // shorten strip "nudged" by right hand strip moving leftward
        Strip := FConnectivity.StripAt(
            BestPlacement.BreakRightFromX - 1, BestPlacement.BreakRightY );
        if Strip <> nil then begin
            // end cell is to left of link
            Strip.Finish.X := BestPlacement.X - 2;
        end;

        // shorten strip "nudged" by left hand strip moving rightward
        Strip := FConnectivity.StripAt(
            BestPlacement.BreakLeftFromX + 1, BestPlacement.BreakLeftY );
        if Strip <> nil then begin
            // end cell is to left of link
            Strip.Finish.X := BestPlacement.X + 2;
        end;

        // adjust the strips to terminate on the link cell
        BestPlacement.RightStrip.Start.X := BestPlacement.X;
        BestPlacement.LeftStrip.Finish.X := BestPlacement.X;

        // placement successful
        result := True;
    end

    //else put component back to its old position;
    else begin
        Item.X := OriginalX;
        Item.Y := OriginalY;
        Item.EndDeltaX := OriginalEndDeltaX;
        Item.EndDeltaY := OriginalEndDeltaY;
        result := False;
    end;
end;


end.

