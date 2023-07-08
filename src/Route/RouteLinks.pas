unit
 RouteLinks;

interface

uses Project, Connective, Netlist, Classes, Contnrs, SysUtils,
    Types, ManagedItem;

type
    ERouterError = class(Exception);

// Copper Strip Belonging to a Net.
// A TroStrip does not own the TcnStrip in its FCheckerStrip member - it is just a
// reference.

type TroStrip = class( TManagedItem )
  protected
    FCheckerStrip : TcnStrip;
  public
    property CheckerStrip : TcnStrip read FCheckerStrip write FCheckerStrip;
end;

type TroLink = record
    X : integer;
    StartY : integer;
    EndY : integer;
    Valid : boolean;
end;

type TroMoveBreakLink = record
    // this record describes a valid link
    Valid : boolean;

    // link X, and Y
    X : integer;
    StartY : integer;
    EndY : integer;

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

    RightStrip : TroStrip;
    LeftStrip : TroStrip;
end;

 

// Island of Strips - all belonging to same net and joined by wires or links
// Island does not own the strip objects in its list - they are just references

type TroIsland = class

  protected
    FStrips : TList;
    FIslandNo : integer;
    function GetStrip( index : integer ) : TroStrip;
    function GetStripCount : integer;
  public
    property Strips[index : integer] : TroStrip read GetStrip;
    property StripCount : integer read GetStripCount;
    property IslandNo : integer read FIslandNo write FIslandNo;

    procedure AddStrip( Strip : TroStrip );
    procedure ClearStrips;

    constructor Create;
    destructor Destroy; override;
end;

// Record describes free strips - those we can use for linking
type TroFreeStrip = class
    XLeft : integer;
    XRight : integer;
    Y : integer;
end;

// Record describes how an island joins to a FreeStrip
type TroIslandToStrip = record
    Valid : boolean;
    LinkLength : integer;
    IslandStripY : integer;
    LinkX : integer;
end;

// Record describes how Islands[] array joins to a FreeStrip
type TXSlots = array[0..TveBoardMAXWIDTH-1] of boolean;

type StripToIslandStatus = record
    TotalLinkLength : integer;
    LinksMade : integer;
    FreeStrip : TroFreeStrip;
    // store link starting points (all links end on the FreeStrip)
    LinkStarts : array[0..10] of TPoint;
    // record which positions are already taken along joining strip
    XSlots : TXSlots;
end;


// Router creates and owns TroIsland and TroStrip objects.

type TveRouter = class

  protected
    FProject : TveProject;
    FConnectivity : TConnectivity;

    FIslands : TObjectList;
    FStrips : TObjectList;
    FIslandCount : integer;
    FStripCount : integer;
    OffBoardLeadedItems : TList;
    FFreeStrips : TObjectList;

    function GetIsland( index : integer ) : TroIsland;
    procedure RemoveIsland( Island : TroIsland );
    function GetStrip( index : integer ) : TroStrip;

    function LinkPathExists( x, y1, y2 : integer ) : boolean;

    procedure JoinIslands;
    function LinkStrips( FromStrip, ToStrip : TroStrip ) : TroLink;

    procedure JoinIslandsWithBreakShift;
    function LinkStripsWithShift( FromStrip, ToStrip : TroStrip ) : TroMoveBreakLink;

    procedure JoinIslandsWithFreeStrips;
    procedure JoinIslandToStrip(
        Island : TroIsland;
        FreeStrip : TroFreeStrip;
        var XSlots : TXSlots;
        var Status : TroIslandToStrip );
    procedure IslandStripToFreeStrip(
        Strip : TroStrip;
        FreeStrip : TroFreeStrip;
        var XSlots : TXSlots;
        var Status : TroIslandToStrip );

    function CreateStrip : TroStrip;
    function CreateIsland : TroIsland;

    procedure LocateFreeStrips;
    function GetFreeStrip( index : integer ) : TroFreeStrip;
    function GetFreeStripCount : integer;
    function CreateFreeStrip : TroFreeStrip;

    procedure Clear;

    procedure InternalRouteNet( Net : TneNode );
    //procedure RouteAllNets;

    property Islands[ index : integer ] : TroIsland read GetIsland;
    property Strips[ index : integer ] : TroStrip read GetStrip;
    property IslandCount : integer read FIslandCount;
    property StripCount : integer read FStripCount;
    property FreeStrips[ index : integer ] : TroFreeStrip read GetFreeStrip;
    property FreeStripCount : integer read GetFreeStripCount;
    procedure DeleteFreeStrip( FreeStrip : TroFreeStrip );

  public
    property Project : TveProject read FProject write FProject;

    procedure RouteNet( Net : TneNode );
    procedure RouteAllNetsWithoutLeaded;

    constructor Create;
    destructor Destroy; override;
end;

implementation

uses Outlines, OtherOutlines, SizeableOutlines, Math;

// *******************************************
//                  TroIsland
// *******************************************

function TroIsland.GetStrip( index : integer ) : TroStrip;
begin
    result := TroStrip(FStrips[index]);
end;

function TroIsland.GetStripCount : integer;
begin
    result := FStrips.Count;
end;

procedure TroIsland.AddStrip( Strip : TroStrip );
begin
    FStrips.Add( Strip );
end;

procedure TroIsland.ClearStrips;
begin
    FStrips.Count := 0;
end;

constructor TroIsland.Create;
begin
    FStrips := TList.Create;
end;

destructor TroIsland.Destroy;
begin
    FStrips.Free;
end;

// *******************************************
//          TveRouter Create, Destroy
// *******************************************

constructor TveRouter.Create;
begin
    FStrips := TObjectList.Create;
    FIslands := TObjectList.Create;
    OffBoardLeadedItems := TList.Create;
    FFreeStrips := TObjectList.Create;
end;

destructor TveRouter.Destroy;
begin
    FIslands.Free;  // destroyes islands
    FStrips.Free;   // destroys container plus contained strip objects
    OffBoardLeadedItems.Free;
    FFreeStrips.Free;  // destroys container plus contained FreeStrip objects
    inherited;
end;

procedure TveRouter.Clear;
begin
    FIslandCount := 0;
    FStripCount := 0;
end;

function TveRouter.GetIsland( index : integer ) : TroIsland;
begin
    if index >= FIslandCount then begin
        raise EListError.Create( 'Island index out of bounds' );
    end;
    result := TroIsland(FIslands[index]);
end;
function TveRouter.GetStrip( index : integer ) : TroStrip;
begin
    if index >= FStripCount then begin
        raise EListError.Create( 'Strip index out of bounds' );
    end;
    result := TroStrip(FStrips[index] )
end;

function TveRouter.CreateStrip : TroStrip;
begin
    // reuse strip from list
    if FStrips.Count > FStripCount then begin
        result := TroStrip(FStrips[FStripCount]);
    end
    // add a new strip to list
    else begin
        result := TroStrip.Create;
        FStrips.Add( result );
    end;
    Inc( FStripCount );
end;

function TveRouter.CreateIsland : TroIsland;
begin
    // reuse island from list
    if FIslands.Count > FIslandCount then begin
        result := TroIsland(FIslands[FIslandCount]);
        // make it look like new
        result.ClearStrips;
    end
    // add a new island to list
    else begin
        result := TroIsland.Create;
        FIslands.Add( result );
    end;
    Inc( FIslandCount );
end;

procedure TveRouter.RemoveIsland( Island : TroIsland );
var
    i : integer;
begin
    // find index of our Island.
    i := FIslands.IndexOf( Island );

    // if removing an island which is already removed
    if (i > FIslandCount) then begin
        raise ERouterError.Create( 'Island removed twice' );
    end;

    // move that object to end of list
    //.. exception here if line i is -1 for Island invalid
    FIslands.Move( i, FIslands.Count -1 );
                 
    // and hide it by decreasing count
    dec( FIslandCount );
end;


// *******************************************
//      SORT STRIPS COMPARISON FUNCTION
// *******************************************

function CompareStripsByStartY_X( P1, P2 : pointer ) : integer;
var
    XLeft1, XLeft2 : integer;
    Y1, Y2 : integer;
begin
    // first compare strips by XLeft (leftmost cell X coord)
//    XLeft1 := TdrStrip(P1).XLeft;
//    XLeft2 := TdrStrip(P2).XLeft;
    XLeft1 := TcnStrip(P1).Start.X;
    XLeft2 := TcnStrip(P2).Start.X;
    if XLeft1 > XLeft2 then begin
        result := 1;
    end
    else if XLeft1 < XLeft2 then begin
        result := -1;
    end

    // if XLefts are same, next compare strips by Y
    else begin
//        Y1 := TdrStrip(P1).Y;
//        Y2 := TdrStrip(P2).Y;
        Y1 := TcnStrip(P1).Start.Y;
        Y2 := TcnStrip(P2).Start.Y;
        if Y1 > Y2 then begin
            result := 1;
        end
        else if Y1 > Y2 then begin
            result := -1;
        end
        else begin
            // we should never get here - overlapping strips
            result := 0;
        end;
    end;
end;

// *******************************************************
//              COMPARE TWO LINKS
// *******************************************************
{
    Two links are compared and an integer returned:
    1 = Link1 better
    -1 = Link2 better
    0 = Link1, Link2 equal "goodness"
}
function CompareLinks( const Link1, Link2 : TroLink ) : integer;
var
    Length1, Length2 : integer;
begin
    if Link1.Valid and (not Link2.Valid) then begin
        result := 1;
    end
    else if (not Link1.Valid) and (Link2.Valid) then begin
        result := -1;
    end
    else if (not Link1.Valid) and (not Link2.Valid) then begin
        result := 0;
    end
    else begin

      Length1 := abs(Link1.EndY - Link1.StartY);
      Length2 := abs(Link2.EndY - Link2.StartY);

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

// *******************************************************
//              COMPARE TWO BREAK-SHIFTED LINKS
// *******************************************************
{
    Two links are compared and an integer returned:
    1 = Link1 better
    -1 = Link2 better
    0 = Link1, Link2 equal "goodness"
}
function CompareLinksWithShift( const Link1, Link2 : TroMoveBreakLink ) : integer;
var
    Length1, Length2 : integer;
begin
    if Link1.Valid and (not Link2.Valid) then begin
        result := 1;
    end
    else if (not Link1.Valid) and (Link2.Valid) then begin
        result := -1;
    end
    else if (not Link1.Valid) and (not Link2.Valid) then begin
        result := 0;
    end
    else begin

      Length1 := abs(Link1.EndY - Link1.StartY);
      Length2 := abs(Link2.EndY - Link2.StartY);

      if Length1 < Length2 then begin
          result := 1;
      end
      else if Length1 > Length2 then begin
          result := -1;
      end
      else begin
          result := 0;
          // calculate total amount of break shifting of both links


      end;

    end;
end;

// *******************************************
//            TEST PATH FOR LINK
// *******************************************
// see if there is a clear line for a link to run vertically
// between two points.  Returns True if path exists.

function TveRouter.LinkPathExists( x, y1, y2 : integer ) : boolean;
var
    y : integer;
    Index : integer;
    Item : TveBoardItem;
begin
    result := True;
    for y := y1 to y2 do begin

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
            if not (Item.Outline is TveBreakOutline) then begin
                result := False;
                break;
            end;
        end;
    end;
end;


// *******************************************
//         High Level Public Functions
// *******************************************
// Use these functions to run the class.

// ROUTE A SINGLE NET BY ADDING LINKS
// Start an Undo operation before calling this. RouteNet
// will add its changes to the latest undo operation.
procedure TveRouter.RouteNet( Net : TneNode );
begin
    FConnectivity := TConnectivity( FProject.ConnectivityObject );

    // find unused strip we can use as joining strip
    LocateFreeStrips;

    InternalRouteNet( Net );
end;

// ROUTE ALL NETS BY TAKING LEADED ITEMS OFF BOARD THEN ADDING LINKS
// Start an Undo operation before calling this. RouteAllNetsWithoutLeaded
// will add its changes to the latest undo operation.
procedure TveRouter.RouteAllNetsWithoutLeaded;

var
    i : integer;
    item : TveBoardItem;
    j : integer;
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
        // with leaded parts missing, we need to reevaluate DRC strips
        FConnectivity.Check;

        // find unused strip we can use as joining strips
        LocateFreeStrips;

        // with leaded items absent, call standard breaks function.
        // revaluate connection errors ready for next iteration
        for j := 0 to FProject.Netlist.NodeCount -1 do begin
            InternalRouteNet( FProject.Netlist.Nodes[j] );
        end;

    finally
        // replace leaded items on board
        for i := OffBoardLeadedItems.Count -1 downto 0 do begin
            Item := TveBoardItem( OffBoardLeadedItems[i] );
            FProject.AddBoardItem( Item );
        end;
    end;
end;

//************************************************
//           End of Public Functions
//************************************************


// *******************************************
//             TveRouter RouteNet
// *******************************************
{
    This function is called to Autoroute links between strips which
    require connection. This function does the core work of this class and as
    it runs the lower level class members are called.
    Given TveNode, connect all strips belonging to this node.
    This reduces to joining the strip islands which the TConnectivity
    has identified and which belong to our net.
}


procedure TveRouter.InternalRouteNet( Net : TneNode );
var
    i : integer;
    StripSet : TcnStripSet;
    j : integer;
    NewStrip : TroStrip;
    NewIsland : TroIsland;
begin
    if Net = nil then begin
        exit;
    end;

    // clear old Islands and Strips
    Clear;
    FStrips.Count :=0;

    // Connectivity stores a separate StripSet for each island, so
    // create an island for each stripset that belongs to our net
    for i := 0 to FConnectivity.StripSetCount - 1 do begin

        StripSet := FConnectivity.StripSets[ i ];
        if StripSet.Net = Net then begin

            // create a new TroIsland object.
            NewIsland := CreateIsland;

            // give island a unique "island number"
            NewIsland.IslandNo := i;

            // add all the StripSets strips to the island
            for j := 0 to StripSet.Count -1 do begin

                NewStrip := CreateStrip;
                // connect strip to TConnectivity TcnStrip object
                NewStrip.CheckerStrip := StripSet.Strips[j];
                // add reference to our strip to current Island
                NewIsland.AddStrip( NewStrip );
            end;
        end;
    end;

    // no islands to join - ie. No StripSets have this net. Caused by no
    // component pin in the net
    if IslandCount <= 0 then begin
        exit;
    end;

    // now pass the job to a link maker which links Islands together
    JoinIslands;

    // pass the job to second link maker which can move breaks to make
    // additional links
    JoinIslandsWithBreakShift;

    // pass the job to the third link maker which can add joining strips
    JoinIslandsWithFreeStrips;
end;

// *******************************************
//            TveRouter JoinIslands
// *******************************************
{
    Given a list of Islands, in the class member Islands[], merge the Islands by
    connecting links between strips belonging to different Islands.
    1. We start at the first island and try to link to every other island -
    then keep the shortest link.  We merge the two islands to make a bigger
    first island.
    2. Using the merged island, we go back to step 1.  Eventually we cannot
    make a link, and goto step 3.
    3. Move to next island down the list and goto step 1, attempting to link to
    islands later in the list - never earlier.
    Note: do not call if there are no islands to join, because Islands[0] in
    code will cause exception
}
procedure TveRouter.JoinIslands;
var
    FromIslandIndex : integer;
    FromIsland : TroIsland;
    ToIsland : TroIsland;
    i,j,k : integer;
    FromStrip, ToStrip : TroStrip;
    TestedLink, BestLink : TroLink;
    BestToIsland : TroIsland;
    m : integer;
    NewLink : TveBoardItem;
begin
    // prevent "uninitialised variable" compiler warnings
    BestToIsland := nil;

    // start a process of many linking attempts
    //.. start with first Island
    FromIslandIndex := 0;
    FromIsland := Islands[0];
    while True do begin

        // if reached bottom of Islands list, then can't join to any more
        // Islands later in the list, so finished
        if FromIslandIndex >= IslandCount - 1 then begin
            break;
        end;

        // evaluate all possible links from our Island to all other strips
        // outside our Island and belonging to Islands later than our Island in
        // the Islands[] list.
        BestLink.Valid := False;
        for i := FromIslandIndex + 1 to IslandCount -1 do begin

            ToIsland := Islands[i];

            // from each strip in our Island
            for j := 0 to FromIsland.StripCount -1 do begin
                FromStrip := FromIsland.Strips[j];

                // to each strip in that Island
                for k := 0 to ToIsland.StripCount -1 do begin
                    ToStrip := ToIsland.Strips[k];

                    //.. LinkStrips called for the same 2 strips every
                    //.. time we evaluate links from the same island to other
                    //.. islands.  We may want to optimise by caching the result
                    //.. of the initial call to LinkStrips and just look
                    //.. up the TroLink records which describes how the link
                    //.. rated.
                    TestedLink := LinkStrips( FromStrip, ToStrip );
                    if (CompareLinks( TestedLink, BestLink ) > 0) then begin
                        BestLink := TestedLink;
                        BestToIsland := ToIsland;
                    end;
                end;
            end;
        end;

        // if no link can be made from our Island to a strip from another
        // Island further down the list, then we are finished with our Island.
        // Move to the next Island down the list
        if not BestLink.Valid then begin
            Inc( FromIslandIndex);
            FromIsland := Islands[FromIslandIndex];
            continue;
        end;

        // 2 Islands are joined by the new link, so combine the later Island
        // into in Our Island (FromIsland)
        for m := 0 to BestToIsland.StripCount -1 do begin
            FromIsland.AddStrip( BestToIsland.Strips[m] );
            // BestToIsland.ClearStrips; .. not needed since strips are cleared
            // when strips reused.
        end;
        RemoveIsland( BestToIsland );

        // place the "best link"
        NewLink := TveBoardItem.Create;
        NewLink.Outline := FProject.LinkOutline;
        NewLink.Selected := True;

        //.. careful - this assumes StartY < StartX.
        NewLink.X := BestLink.X;
        NewLink.Y := BestLink.StartY;
        NewLink.Length := BestLink.EndY - BestLink.StartY;

        // record added item for Undo
        Project.AddItemToUndo( NewLink );

        // loop will continue and attempt to find the "next best link" from
        // our Island to another Island
    end;
end;


// *******************************************
//             LinkStrips
// *******************************************
{
    Given two strips, find the best possible link between the strips, and
    return a TroLink record which describes that link.

    This code fakes it - we do not find the best possible link - we find the
    first valid link scanning from the left.  To find best possible link we
    would have to keep a "BestLinkX" record which stores the ratings of the
    best link tried to date.  This may not be worth the trouble - a "relax"
    process might be better - relaxing looks over the board and moves links
    sideways to get vertical alignment of links, thus freeing up long vertical
    runs which could take links.
}
function TveRouter.LinkStrips( FromStrip, ToStrip : TroStrip ) : TroLink;
var
    StartX, EndX : integer;     // X range in common with both strips
    LowY, HighY : integer;
    Temp : integer;
    i : integer;
begin
    // find X coord range shared by both strips
    StartX := Max( FromStrip.CheckerStrip.Start.X, ToStrip.CheckerStrip.Start.X );
    EndX := Min( FromStrip.CheckerStrip.Finish.X, ToStrip.CheckerStrip.Finish.X );

    // if no overlap
    // .. NB, a one cell length strip has StartX = EndX
    if StartX > EndX then begin
        result.Valid := False;
        exit;
    end;

    // grab Y coords of two strips
    LowY := FromStrip.CheckerStrip.Start.Y;
    HighY := ToStrip.CheckerStrip.Start.Y;
    if LowY > HighY then begin
        Temp := LowY;
        LowY := HighY;
        HighY := Temp;
    end;

    // look for a pair of free cells vertically aligned with no obstruction
    // between these end points
    for i := StartX to EndX do begin
        if LinkPathExists( i, LowY, HighY ) then begin
            result.Valid := True;
            result.X := i;
            result.StartY := LowY;
            result.EndY := HighY;
            exit;
        end;
    end;

    // never went round the loop OR never found a match
    result.Valid := False;
end;

// *******************************************
//         JoinIslandsWithBreakShift
// *******************************************
{
    Given a list of Islands, merge the Islands by connecting links between
    strips belonging to different Islands.  Each link is chosen to be that which
    gives the shortest connection between an Island and a strip from another
    Island.

    Call this AFTER calling JoinIslands - this will add a few more links
    in cases where strips do not have an overlap

    Do not call if IslandCount <= 0 because Islands[0] will cause exception
}

procedure TveRouter.JoinIslandsWithBreakShift;

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
    FromIslandIndex : integer;
    FromIsland : TroIsland;
    ToIsland : TroIsland;
    i,j,k : integer;
    FromStrip, ToStrip : TroStrip;
    TestedLink, BestLink : TroMoveBreakLink;
    BestToIsland : TroIsland;
    m : integer;
    NewLink : TveBoardItem;
    BreakItem : TveBoardItem;
//    Strip : TdrStrip;
    Strip : TcnStrip;
begin
    // prevent "uninitialised variable" compiler warnings
    BestToIsland := nil;

    // start a process of many linking attempts
    //.. start with first Island
    FromIslandIndex := 0;
    FromIsland := Islands[0];
    while True do begin

        // if reached bottom of Islands list, then can't join to any more
        // Islands later in the list, so finished
        if FromIslandIndex >= IslandCount - 1 then begin
            break;
        end;

        // evaluate all possible links from our Island to all other strips
        // outside our Island and belonging to Islands later than our Island in
        // the Islands[] list.
        BestLink.Valid := False;
        for i := FromIslandIndex + 1 to IslandCount -1 do begin

            ToIsland := Islands[i];

            // from each strip in our Island
            for j := 0 to FromIsland.StripCount -1 do begin
                FromStrip := FromIsland.Strips[j];

                // to each strip in that Island
                for k := 0 to ToIsland.StripCount -1 do begin
                    ToStrip := ToIsland.Strips[k];

                    //.. LinkStrips called for the same 2 strips every
                    //.. time we evaluate links from the same island to other
                    //.. islands.  We may want to optimise by caching the result
                    //.. of the initial call to LinkStrips and just look
                    //.. up the TroLink records which describes how the link
                    //.. rated.
                    TestedLink := LinkStripsWithShift( FromStrip, ToStrip );
                    if (CompareLinksWithShift( TestedLink, BestLink ) > 0) then begin
                        BestLink := TestedLink;
                        BestToIsland := ToIsland;
                    end;
                end;
            end;
        end;

        // if no link can be made from our Island to a strip from another
        // Island further down the list, then we are finished with our Island.
        // Move to the next Island down the list
        if not BestLink.Valid then begin
            Inc( FromIslandIndex);
            FromIsland := Islands[FromIslandIndex];
            continue;
        end;

        // 2 Islands are joined by the new link, so combine the later Island
        // into in Our Island (FromIsland)
        for m := 0 to BestToIsland.StripCount -1 do begin
            FromIsland.AddStrip( BestToIsland.Strips[m] );
            // BestToIsland.ClearStrips; .. not needed since strips are cleared
            // when strips reused.
        end;
        RemoveIsland( BestToIsland );

        // place the "best link"
        NewLink := TveBoardItem.Create;
        NewLink.Outline := FProject.LinkOutline;
        NewLink.Selected := True;
        FProject.AddItemToUndo( NewLink );

        //.. careful - this assumes StartY < StartX.
        NewLink.X := BestLink.X;
        NewLink.Y := BestLink.StartY;
        NewLink.Length := BestLink.EndY - BestLink.StartY;
        // move first break
        if BestLink.BreakLeftFromX <> BestLink.BreakLeftToX then begin
            BreakItem := GetBreakAt( BestLink.BreakLeftFromX, BestLink.BreakLeftY );
            if BreakItem <> nil then begin
                BreakItem.TakeSnapshot;
                BreakItem.X := BestLink.BreakLeftToX;
                Project.ItemSnapshotToUndo( BreakItem );
            end;
        end;
        // move second break
        if BestLink.BreakRightFromX <> BestLink.BreakRightToX then begin
            BreakItem := GetBreakAt( BestLink.BreakRightFromX, BestLink.BreakRightY );
            if BreakItem <> nil then begin
                BreakItem.TakeSnapshot;
                BreakItem.X := BestLink.BreakRightToX;
                Project.ItemSnapshotToUndo( BreakItem );
            end;
        end;

        // shorten strip "nudged" by right hand strip moving leftward
        Strip := FConnectivity.StripAt(
            BestLink.BreakRightFromX - 1, BestLink.BreakRightY );
        if Strip <> nil then begin
            // end cell is to left of link
            Strip.Finish.X := BestLink.X - 2;
        end;

        // shorten strip "nudged" by left hand strip moving rightward
        Strip := FConnectivity.StripAt(
            BestLink.BreakLeftFromX + 1, BestLink.BreakLeftY );
        if Strip <> nil then begin
            // end cell is to left of link
            Strip.Start.X := BestLink.X + 2;
        end;

        // adjust the strips to terminate on the link cell
        BestLink.RightStrip.CheckerStrip.Start.X := BestLink.X;
        BestLink.LeftStrip.CheckerStrip.Finish.X := BestLink.X;

        // record added item for Undo
        FProject.AddItemToUndo( NewLink );

        // loop will continue and attempt to find the "next best link" from
        // our Island to another Island
    end;
end;

// *******************************************
//       LINK STRIPS USING BREAK-SHIFT
// *******************************************

// Call this after LinkStrips() - it can create links by shoving breaks aside.
// However, it might cause disarray if used on easy links - so we should run it
// after LinkStrips() has made the easy links.

function TveRouter.LinkStripsWithShift( FromStrip, ToStrip : TroStrip ) : TroMoveBreakLink;

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
    LeftStrip : TroStrip;
    RightStrip : TroStrip;
    LeftStripNewEnd: integer;
    RightStripNewEnd: integer;
    x: integer;
    ZoneLeft: integer;
    ZoneRight: integer;
    LowY: integer;
    HighY: integer;
    Temp: integer;
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
    if FromStrip.CheckerStrip.Start.Y = ToStrip.CheckerStrip.Start.Y then begin
        result.Valid := False;
        exit;
    end;

    // see if the extend left and extend right will cause additional overlap
    // find X coord range shared by both strips
    OverlapStartX := Max( FromStrip.CheckerStrip.Start.X, ToStrip.CheckerStrip.Start.X );
    OverlapEndX := Min( FromStrip.CheckerStrip.Finish.X, ToStrip.CheckerStrip.Finish.X );
    Overlap := OverlapEndX - OverlapStartX;

    // We are interested in a small small overlap or small gap (negative overlap)
    // We are just catching the cases a vertical row of breaks prevents a strips
    // being joined by vertical links.
    if Abs(Overlap) > MAX_OVERLAP then begin
        result.Valid := False;
        exit;
    end;

    // find which strip is left, which is right
    if FromStrip.CheckerStrip.Start.X < ToStrip.CheckerStrip.Start.X then begin
        LeftStrip := FromStrip;
        RightStrip := ToStrip;
    end
    else begin
        LeftStrip := ToStrip;
        RightStrip := FromStrip;
    end;

    //  extend left strip toward right
    LeftStripNewEnd := Min(
        LeftStrip.CheckerStrip.Finish.X + MAX_EXTEND, FProject.BoardWidth -1 );
    //. See if cells are free for the extension
    //. Next cell has a break, but may be overlaid with a component,
    //. include it in check for free cells
    //. At the end of extended strip we need to place a break
    for x := LeftStrip.CheckerStrip.Finish.X + 1 to LeftStripNewEnd do begin
        if not CellFree( x, LeftStrip.CheckerStrip.Start.Y ) then begin
            LeftStripNewEnd := x -1;
            break;
        end;
    end;
    //. if we are not at board edge, we need an extra clear cell for a break
    if LeftStripNewEnd < FProject.BoardWidth -1 then begin
        if not CellFree( LeftStripNewEnd +1, LeftStrip.CheckerStrip.Start.Y ) then begin
            dec(LeftStripNewEnd);
        end;
    end;
    //.. (now LeftStripNewEnd equals possible end of extended left strip)


    //  extend right strip toward left
    RightStripNewEnd := Max( RightStrip.CheckerStrip.Start.X - MAX_EXTEND, 0 );
    //. see if cells are free for the extension
    //. next cell has a break and so is available.
    //. at the end of extended strip we need to place a break
    for x := RightStrip.CheckerStrip.Start.X -1 downto RightStripNewEnd do begin
        if not CellFree( x, RightStrip.CheckerStrip.Start.Y ) then begin
            RightStripNewEnd := x +1;
            break;
        end;
    end;
    //. if we are not at board edge, we need an extra clear cell for a break
    if RightStripNewEnd > 0 then begin
        if not CellFree( RightStripNewEnd -1, RightStrip.CheckerStrip.Start.Y ) then begin
            inc(RightStripNewEnd);
        end;
    end;
    //.. (now RightStripNewEnd equals possible end of extended right strip)


    // calculate overlap zone of two extended areas
    ZoneLeft := Max( RightStripNewEnd, LeftStrip.CheckerStrip.Start.X );
    ZoneRight := Min( LeftStripNewEnd, RightStrip.CheckerStrip.Finish.X );

    // grab Y coords of two strips
    LowY := FromStrip.CheckerStrip.Start.Y;
    HighY := ToStrip.CheckerStrip.Start.Y;
    if LowY > HighY then begin
        Temp := LowY;
        LowY := HighY;
        HighY := Temp;
    end;


    // See if we can place any links between the strips, for x within zone
    // Look for a pair of free cells vertically aligned with no obstruction
    // between these end points
    for x := ZoneLeft to ZoneRight do begin
        if LinkPathExists( x, LowY, HighY ) then begin

            result.X := x;
            result.StartY := LowY;
            result.EndY := HighY;
            result.Valid := True;

            // left strip
            // first break Y
            result.BreakLeftY :=  LeftStrip.CheckerStrip.Start.Y;
            // first break original X
            result.BreakLeftFromX := LeftStrip.CheckerStrip.Finish.X +1;
            // first break new X
            result.BreakLeftToX := x + 1;

            // right strip
            // second break Y
            result.BreakRightY := RightStrip.CheckerStrip.Start.Y;
            // second break original X
            result.BreakRightFromX := RightStrip.CheckerStrip.Start.X -1;
            // second break new X
            result.BreakRightToX := x - 1;

            // strips
            result.RightStrip := RightStrip;
            result.LeftStrip :=  LeftStrip;

            exit;
        end;
    end;

    // never went round the loop OR never found a match
    result.Valid := False;
end;

// *******************************************
//           List of Available Strips
// *******************************************

function TveRouter.GetFreeStrip( index : integer ) : TroFreeStrip;
begin
    result := TroFreeStrip( FFreeStrips[index] );
end;

function TveRouter.GetFreeStripCount : integer;
begin
    result := FFreeStrips.Count;
end;

function TveRouter.CreateFreeStrip : TroFreeStrip;
begin
    result := TroFreeStrip.Create;
    FFreeStrips.Add( result );
end;

procedure TveRouter.DeleteFreeStrip( FreeStrip : TroFreeStrip );
begin
    FFreeStrips.Delete( FFreeStrips.IndexOf( FreeStrip ) );
end;

// *******************************************
//         Make List of Available Strips
// *******************************************
{   Make a list of TFreeStrip records.  Each record describes a strip which
    is either unused, or can be cut free with a single break.
}
procedure TveRouter.LocateFreeStrips;

    // Add a new free strip to the list.
    // StartX = x of leftmost cell of the strip available for links.
    // EndX = x of rightmost cell (not bounding cell) of the strip available
    //     for links.
    // BreakX = x value where we need to place a break to free our strip for use
    // BreakX = -1 means no break required
    // Y is Y coord of strip.
    procedure NewFreeStrip( StartX, EndX, Y : integer );
    var
        NewFreeStrip : TroFreeStrip;
    begin
        NewFreeStrip := CreateFreeStrip;
        NewFreeStrip.XLeft := StartX;
        NewFreeStrip.XRight := EndX;
        NewFreeStrip.Y := Y;
    end;

const
    MINIMUM_STRIP_LENGTH = 8;
var
    x, y : integer;
    pCell : PcnCellData;
    StripClear : boolean;
begin
    // clear Free Strip list
    FFreeStrips.Clear;

    // scan every board row (strip) from left
    for y := 0 to FProject.BoardHeight - 1 do begin

        // scan copper strip from board left
        StripClear := True;
        for x := 0 to FProject.BoardWidth - 1 do begin
            pCell := @FConnectivity.Cells[ x, y ];

            // if found a pin: strip not free
            if (pCell^.PinCount <> 0) then begin
                StripClear := False;
                break;
            end;

            // if found a break: end of strip
            // down break is ignored on horizontal strip, but unshifted and
            // right shifted breaks cut the strip
            if (pCell^.Break * [brUnshifted, brShiftRight]) <> [] then begin
                StripClear := False;
                if x >= MINIMUM_STRIP_LENGTH then begin
                    NewFreeStrip( 0, x-1, y );
                end
                // strip too short to bother
                else begin
                    break;
                end;
            end;
        end;

        // if we scanned across board width without meeting anything
        // therefore strip is empty
        if StripClear then begin
            NewFreeStrip( 0, FProject.BoardWidth - 1, y );
        end;
    end;

    // scan every board row (strip) from right
    for y := 0 to Fproject.BoardHeight - 1 do begin

        // scan copper strip from board right
        for x := FProject.BoardWidth - 1 downto 0 do begin
            pCell := @FConnectivity.Cells[ x, y ];

            // if found a pin: strip not free
            if (pCell^.PinCount <> 0) then begin
                break;
            end;

            // if found a break: end of strip
            if (pCell^.Break * [brUnshifted, brShiftRight]) <> [] then begin
                if (FProject.BoardWidth - x -1 ) >= MINIMUM_STRIP_LENGTH then begin
                    NewFreeStrip( x+1, FProject.BoardWidth, y );
                end
                // strip too short to bother
                else begin
                    break;
                end;
            end;
        end;
    end;
end;


// *********************************************
//    TEST JOIN AN ISLAND STRIP TO A FREE STRIP
// *********************************************
{
    Given a strips, find the best possible link between the strips, and
    return a TroLink record which describes that link.
}
procedure TveRouter.IslandStripToFreeStrip(
    Strip : TroStrip;
    FreeStrip : TroFreeStrip;
    var XSlots : TXSlots;
    var Status : TroIslandToStrip );
var
    StartX, EndX : integer;     // X range in common with both strips
    LowY, HighY : integer;
    Temp : integer;
    x : integer;
begin
    //***<<< WARNING: is StartX, EndX same for links requiring a break?
    // find X coord range shared by both strips
    StartX := Max( Strip.CheckerStrip.Start.X, FreeStrip.XLeft );
    EndX := Min( Strip.CheckerStrip.Finish.X, FreeStrip.XRight );

    // if no overlap
    // .. NB, a one cell length strip has StartX = EndX
    if StartX > EndX then begin
        Status.Valid := False;
        exit;
    end;

    // grab Y coords of two strips
    LowY := Strip.CheckerStrip.Start.Y;
    HighY := FreeStrip.Y;
    if LowY > HighY then begin
        Temp := LowY;
        LowY := HighY;
        HighY := Temp;
    end;

    // look for a pair of free cells vertically aligned with no obstruction
    // between these end points
    for x := StartX to EndX do begin

        // if another link to be placed at at x pos on joining strip
        if XSlots[x] then begin
            continue;
        end;

        if LinkPathExists( x, LowY, HighY ) then begin
            // informtion to evaluate the link
            Status.Valid := True;
            Status.LinkLength := HighY - LowY;
            // enough information to create the link
            Status.IslandStripY := Strip.CheckerStrip.Start.Y;
            Status.LinkX := x;
            // reserve the link location
            XSlots[x] := True;
            exit;
        end;
    end;

    // never went round the loop OR never found a match
    Status.Valid := False;
end;

// *******************************************
//    TEST JOIN AN ISLAND TO A FREE STRIP
// *******************************************

// Need to call this offering linksX[0..TveBoardMAXWIDTH-1] array showing
// showing x positions currently used by links (can't use same hole twice!).

procedure TveRouter.JoinIslandToStrip(
    Island : TroIsland;
    FreeStrip : TroFreeStrip;
    var XSlots : TXSlots;
    var Status : TroIslandToStrip );
var
    i : integer;
    Strip : TroStrip;
    CurrentJoin : TroIslandToStrip;
begin
    // start out with the worst possible join
    Status.Valid := False;
    Status.LinkLength := High(Status.LinkLength);

    // for every strip in the island ("IslandStrip")
    for i := 0 to Island.StripCount - 1 do begin
        Strip := Island.Strips[ i ];

        // test link the Strip to the IslandStrip
        IslandStripToFreeStrip( Strip, FreeStrip, XSlots, CurrentJoin );

        // if this join is better than the last
        if  CurrentJoin.Valid and
            (CurrentJoin.LinkLength < Status.LinkLength) then begin

            Status := CurrentJoin;
        end;
    end;
end;

// *******************************************
//       JOIN ISLANDS USING A FREE STRIP
// *******************************************
{
  To use, call LocateFreeStrips(), load class member Islands[] with Islands to
  be joined, then call this function.
  This function will allocate a free strip from FreeStrips[] and add links
  to make the join.  This function may not be able to join every island, but
  will join at least two.
}
procedure TveRouter.JoinIslandsWithFreeStrips;

{***********
1. Pick a Joining Strip
2. Join every island to the strip
3. Track the best join: total link length, number of links,
  (join strip length could also be used to evaluate?)
***********}

var
    FreeStripIndex : integer;
    IslandIndex: Integer;
    Island : TroIsland;

    LatestJoin : TroIslandToStrip;

    CurrentStatus : StripToIslandStatus;
    BestStatus : StripToIslandStatus;

    Link : TveBoardItem;
    i : integer;
    Y1, Y2 : integer;
begin
    // create a "dud" BestStatus to get started
    BestStatus.LinksMade := 0;

    // for every free strip (count down lets us delete FreeStrips[] members
    // as we go.)
    for FreeStripIndex := FreeStripCount - 1 downto 0 do begin

        // start a status record
        CurrentStatus.TotalLinkLength := 0;
        CurrentStatus.LinksMade := 0;
        CurrentStatus.FreeStrip := FreeStrips[FreeStripIndex];
        FillChar( CurrentStatus.XSlots, sizeof(CurrentStatus.XSlots), 0 );

        // attempt to link the free strip to every island
        for IslandIndex := 0 to IslandCount - 1 do begin

            // if our array can't hold any more links 
            if CurrentStatus.LinksMade > High(CurrentStatus.LinkStarts) then begin
                break;
            end;

            Island := Islands[IslandIndex];
            JoinIslandToStrip(
                Island,
                CurrentStatus.FreeStrip,
                CurrentStatus.XSlots,
                LatestJoin );

            // include latest join attempt into status
            if LatestJoin.Valid then begin
                // remember where to place the link
                CurrentStatus.LinkStarts[CurrentStatus.LinksMade] :=
                    Point( LatestJoin.LinkX, LatestJoin.IslandStripY);
                // remember some statistics used to rate this join
                inc( CurrentStatus.LinksMade );
                inc( CurrentStatus.TotalLinkLength, LatestJoin.LinkLength );
            end;
        end;

        // assess the results of the attempted joinings of current free
        // strip to our islands
        if( CurrentStatus.LinksMade > BestStatus.LinksMade ) or
          (
            (CurrentStatus.LinksMade = BestStatus.LinksMade) and
            (CurrentStatus.TotalLinkLength < BestStatus.TotalLinkLength)
          )
            then begin
            BestStatus := CurrentStatus;
        end;
    end;

    // now implement the best join we found - but at least two links must be
    // made or we have not joined any islands!
    if BestStatus.LinksMade >= 2 then begin

        // remove our FreeStrip from the list
        DeleteFreeStrip( BestStatus.FreeStrip );

        // place the links
        for i := 0 to BestStatus.LinksMade - 1 do begin
            Link := TveBoardItem.Create;
            Link.Outline := FProject.LinkOutline;
            Link.Selected := True;
            Link.X := BestStatus.LinkStarts[i].X;
            // link ref point at top
            Y1 := BestStatus.FreeStrip.Y;
            Y2 := BestStatus.LinkStarts[i].Y;
            Link.Y := Min( Y1, Y2 );
            Link.Length := Abs( Y1 - Y2 );

            // record added item for Undo
            Project.AddItemToUndo( Link );
        end;
    end;
end;


end.

