unit Breaks;

interface

uses Connective, Project, Classes;

type TveBreakTool = class
  protected
    Strips : TList;
    FProject : TveProject;
    FConnectivity : TConnectivity;
    OffBoardLeadedItems : TList;
  public
    property Project : TveProject read FProject write FProject;
    procedure SelectRedundant;
    procedure PlaceBreaks;
    procedure PlaceBreaksWithoutLeaded;

    constructor Create;
    destructor Destroy; override;
end;


implementation

uses SysUtils, Outlines, OtherOutlines, SizeableOutlines, Board;


type EBreakTool = class( Exception );


// *******************************************
//              CREATE, DESTROY
// *******************************************

constructor TveBreakTool.Create;
begin
    inherited;
    Strips := TList.Create;
    OffBoardLeadedItems := TList.Create;
end;

destructor TveBreakTool.Destroy;
begin
    Strips.Free;
    OffBoardLeadedItems.Free;
    inherited;
end;


// *******************************************
//          SELECT REDUNDANT BREAKS
// *******************************************
{
    Find Unneeded Breaks in the Project and set "Selected" property to True.
    Unselect all other components.
}

procedure TveBreakTool.SelectRedundant;

var
    RemovedBreaks : TList;
    CurrentErrorCount : integer;

    // if a break is redundant, remove it from the board and place in
    // RemovedBreaks list
    procedure AnalyseBreak( Break : TveBoardItem );
    var
        WithoutBreakErrors : integer;
    begin
        // find number of errors without the break on board
        FProject.ReleaseBoardItem( Break );
        FConnectivity.Check;
        WithoutBreakErrors := FConnectivity.GetCellErrorCount;

        // if more errors without break, replace break on board and leave
        // CurrentErrorCount unchanged to reflect unchanged board.
        if WithoutBreakErrors > CurrentErrorCount then begin
            FProject.AddBoardItem( Break );
        end

        // else break makes no difference to errors, mark it as selected,
        // leave it off board, store it in list. CurrentErrorCount must now
        // reflect board with break removed - ie. set to WithoutBreakErrors
        else begin
            Break.Selected := True;
            // allocate big 100 pointer sized chunks of memory rather than
            // the default 10 size allocations
            if RemovedBreaks.Capacity <= RemovedBreaks.Count then begin
                RemovedBreaks.Capacity := RemovedBreaks.Capacity + 100;
            end;
            RemovedBreaks.Add( Break );
            CurrentErrorCount := WithoutBreakErrors;
        end;
    end;

var
    i : integer;
    Item : TveBoardItem;
    j: Integer;
begin
    FConnectivity := TConnectivity( FProject.ConnectivityObject );

    // unnecessary breaks will be shown as Selected. so unselect all
    FProject.DeSelectAllItems;

    // TList will hold references to breaks that are temporarily removed
    // from the board
    RemovedBreaks := TList.Create;
    try
        // prime error CurrentErrorCount - ie. error count as board stands
        // with whatever breaks have been removed during analysis
        FConnectivity.Check;
        CurrentErrorCount := FConnectivity.GetCellErrorCount;

        // for every item in project
        for i := FProject.BoardItemCount - 1 downto 0 do begin

            // get a break and analyse it
            Item := FProject.BoardItems[ i ];
            if Item.Outline is TveBreakOutline then begin
                AnalyseBreak( Item );
            end;
        end;

        // put removed breaks back on board
        for j := 0 to RemovedBreaks.Count -1 do begin
            Item := TveBoardItem( RemovedBreaks[ j ]);
            FProject.AddBoardItem( Item );
        end;

    finally
        RemovedBreaks.Free;
    end;
end;

// *******************************************
//          PLACE BREAKS ON BOARD
// *******************************************
{
    Place breaks to remove wrong connections to pins as indicated by
    Connectivity Checker.

    Before calling PlaceBreaks, Project.BeginUndo must have been called.
    PlaceBreaks will add some extra Mementos to the active undo operation,
    so that a single Undo can include PlaceBreaks changes as well as other
    changes.
}

procedure TveBreakTool.PlaceBreaks;

    // return True if cell pins belong only to wires or links
    function WiresOrLinksOnlyOnCell( pCell : pcnCellData ) : boolean;
    var
        i : integer;
        Item : TveBoardItem;
    begin
        for i := 0 to pCell^.PinCount - 1 do begin
            Item := pCell^.Pins[i].Item;

            // if item other than Link or Wire, return false
            if not ((Item.Outline is TveLinkOutline) or (Item.Outline is TveWireOutline)) then begin
                result := False;
                exit;
            end;
        end;
        // only links or wires encountered in pins[]
        result := True;
    end;

var
    IterationCount : integer;
    i : integer;
    Strip : TcnStrip;
    SectionStartX : integer;
    BreaksCount : integer;
    X, Y : integer;
    NewBreakX : integer;
    pCell : pcnCellData;
    NewBreak : TveBoardItem;
begin
    FConnectivity := TConnectivity( FProject.ConnectivityObject );

    IterationCount := 0;
    while True do begin

        BreaksCount := 0;

        // for each strip
        for i := 0 to FConnectivity.StripCount -1 do begin

            // evaluate connection errors ready for this iteration
            FConnectivity.Check;

            Strip := FConnectivity.Strips[i];
            Y := Strip.Start.Y;

            // move from left end +1 cell along strip to first connection error
            // don't check left end cell, because it can't have an error
            // .. SectionX is start of a scan from strip start or last
            //.. break we have inserted in the strip.
            SectionStartX := Strip.Start.X -1;
            for X := Strip.Start.X +1 to Strip.Finish.X do begin

                // error found
                if FConnectivity.Cells[X, Y].Error then begin

                    // if error cell holds a link or wire, ignore it.  We simply
                    // cannot divine where a link should go, because they
                    // are chameleon and can take on any net depending on the
                    // pattern of breaks.  (Actually, the net of some links/wires
                    // is pretty likely - eg, runs between 2 pins of same
                    // net.)
                    pCell := @FConnectivity.Cells[X, Y];
                    if WiresOrLinksOnlyOnCell( pCell ) then begin

                        // unbroken section of track now restarts, so any
                        // cut takes place midway between this link/wire
                        // and the error circle to the right.
                        SectionStartX := X;

                        // we keep looking for errors further along this strip
                        continue;
                    end;

                    // we place break half way between error and start of
                    // this section
                    NewBreakX := (X + SectionStartX) div 2;

                    // get at cell immediately to left of error cell
                    pCell := @FConnectivity.Cells[NewbreakX, Y];

                    // if cell to left holds a break ??? can't be
{
                    if (pCell^.Break and [brUnshifted, brShiftRight]) <> []then begin
                    if PinData.Break then begin
                        raise EBreakTool.Create(
                            'Internal error : Break left next to error cell' );
                    end;
}
                    // place a break on cell
                    NewBreak := TveBoardItem.Create;
                    NewBreak.Outline := FProject.BreakOutline;
                    NewBreak.X := NewBreakX;
                    NewBreak.Y := Y;
                    NewBreak.Selected := True;

                    // put each new break into undo items
                    Project.AddItemToUndo( NewBreak );

                    // if cell to left of error is occupied, shift break half
                    // cell to right
                    if pCell.PinCount > 0 then begin
                        NewBreak.Shift := shRight;
                    end;
                    Inc( BreaksCount );

                    // don't scan further to right along this strip - other
                    // error cells may disappear due to our break, and we
                    // can evaluate this - leave to another iteration
                    break;
                end

                // not a bad cell - but does it contain a pin ?
                else begin
                    pCell := @FConnectivity.Cells[X, Y];
                    if pCell^.PinCount > 0 then begin
                        // unbroken section of track now restarts
                        SectionStartX := X;
                    end;
                end;
            end;
        end;

        // if no breaks were put down on any strips, we are finished
        // plus safety IterationCount catches endless loops
        Inc( IterationCount );
        if (BreaksCount = 0) or (IterationCount = 20) then begin
            Break;
        end;
   end;
end;

// *******************************************
//   PLACE BREAKS WITH LEADED PARTS REMOVED 
// *******************************************
{
    Before calling PlaceBreaksWithoutLeaded, Project.BeginUndo must have been
    called. PlaceBreaksWithoutLeaded will add some extra Mementos to the active
    undo operation, so that a single Undo can include PlaceBreaksWithoutLeaded
    changes as well as other changes.
}

procedure TveBreakTool.PlaceBreaksWithoutLeaded;
var
    i : integer;
    item : TveBoardItem;
begin
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
        // with leaded items absent, call standard breaks function.
        PlaceBreaks;

    finally
        // replace leaded items on board
        for i := OffBoardLeadedItems.Count -1 downto 0 do begin
            Item := TveBoardItem( OffBoardLeadedItems[i] );
            FProject.AddBoardItem( Item );
        end;
    end;
end;


end.


