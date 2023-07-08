unit ProjectCheck;

interface

uses Project, Classes;

type TProjectChecker = class

  private
    FProject : TveProject;

  public
    property Project : TveProject read FProject write FProject;

    function CheckOutlinesNames( report : TStrings ) : boolean;
    function CheckOutlinesDuplicateNames( report : TStrings ) : boolean;
    function CheckOutlinesDuplicatePins( report : TStrings ) : boolean;
    function CheckNetComponentsExist( report : TStrings ) : boolean;
    function CheckNetPinsExist( report : TStrings ) : boolean;

    function CheckItemDesignators( report : TStrings ) : boolean;
    function CheckItemDuplicateDesignators( report : TStrings ) : boolean;
    function CheckItemsInsideBoardPerimeter( report : TStrings ) : boolean;
    function CheckItemsUnused( report : TStrings ) : boolean;

    function CheckAll( report : TStrings ) : boolean;
end;



implementation

uses Outlines, SizeableOutlines, CelledOutlines, RadialOutlines, SysUtils,
    Netlist, Windows;


procedure LineOut( report : TStrings; s : string );
begin
    if report <> nil then begin
        report.Add( s );
    end;
end;


// *****************************************
//      CHECK OUTLINES HAVE VALID NAMES
// *****************************************

function TProjectChecker.CheckOutlinesNames( report : TStrings ) : boolean;
var
    i : integer;
    Outline : TveOutline;
begin
    result := True;

    for i := 0 to FProject.OutlineCount -1 do begin

        Outline := FProject.Outlines[i];
        if Trim( Outline.Name ) = '' then begin
            LineOut( report,
                'Blank Name : Outline ??'
//              Format( 'Blank Name : Outline ??',
//                    []
//                )
            );
            result := False;
        end;
    end;
end;


// *****************************************
//      CHECK NO DUPLICATE OUTLINE NAMES
// *****************************************

function CompareOutlinesByName( P1, P2 : pointer ) : integer;
begin
    result := AnsiCompareStr( TveOutline(P1).Name, TveOutline(P2).Name );
end;


function TProjectChecker.CheckOutlinesDuplicateNames( report : TStrings ) : boolean;
var
    Outlines : TList;
    i : integer;
    Outline : TveOutline;
    LastOutline : TveOutline;
begin
    result := True;

    Outlines := TList.Create;
    try
        // make list of outlines
        for i := 0 to FProject.OutlineCount -1 do begin
            Outlines.Add( FProject.Outlines[i] );
        end;

        // sort list in name order so duplicates will be adjacent
        // uses AnsiCompareStr().
        Outlines.Sort(CompareOutlinesByName);

        // find duplicates
        LastOutline := nil;
        for i := 0 to Outlines.Count -1 do begin

            Outline := TveOutline( Outlines[i] );
            if LastOutline <> nil then begin
                // match if identical chars: differing case = different names
                if Outline.Name = LastOutline.Name then begin

                    LineOut( report,
                        Format( 'Duplicate Names : Outlines "%s"',
                            [Outline.Name]
                        )
                    );
                    result := False;
                end;
            end;
            // current item becomes last item ready for next check
            LastOutline := Outline;
        end;

    finally
        Outlines.Free;
    end;
end;

// *****************************************
// CHECK NO DUPLICATE OUTLINES PIN NUMBERS
// *****************************************

function PinComparePinNos( P1, P2 : pointer ) : integer;
begin
    if integer(P1) > integer(P2) then begin
        result := 1;
    end
    else if integer(P1) < integer(P2) then begin
        result := -1;
    end
    else begin
        result := 0;
    end;
end;


function TProjectChecker.CheckOutlinesDuplicatePins( report : TStrings ) : boolean;
var
    i : integer;
    Outline : TveOutline;

    Item : TveBoardItem;
    X, Y : integer;
    PinIndex : integer;
    PinName : string;
    Pins : TStringList;
    j : integer;
begin
    result := True;

    // create a TveBoardItem to enable us to call TveOutline.GetNextPin\();
    Pins := nil;
    Item := TveBoardItem.Create;
    try
        // sort pin numbers here
        Pins := TStringList.Create;

        // for each outline
        for i := 0 to FProject.OutlineCount -1 do begin

            Outline := FProject.Outlines[i];

            // make a list of the pins belonging to this outline
            Pins.Clear;
            Outline.ToFirstPin;
            while Outline.GetNextPin( Item, X, Y, PinIndex ) do begin
                PinName := Outline.Pins[PinIndex].Name;
                Pins.Add( PinName );
            end;

            // sort list
            Pins.Sort;

            // look for equal pin numbers
            for j := 0 to Pins.Count - 2 do begin
                if Pins[j] = Pins[j+1] then begin
                    result := False;
                    LineOut( report,
                        Format( 'Duplicate Pin "%s" in Outline "%s"',
                            [Pins[j], Outline.Name]
                        )
                    );
                end;
            end;
        end;
    finally
        Item.Free;
        Pins.Free;
    end;
end;

// *****************************************
//    CHECK NET COMPONENTS EXIST ON BOARD
// *****************************************

function TProjectChecker.CheckNetComponentsExist( report : TStrings ) : boolean;

var
    i : integer;
    Netlist : TneNetlist;
    Component : TneComponent;
    BoardItem : TveBoardItem;

begin
    result := True;

    Netlist := FProject.Netlist;

    // for for every netlist component
    for i := 0 to Netlist.ComponentCount -1 do begin

        Component := Netlist.Components[i];

        BoardItem := FProject.ItemByDesignator( Component.Name );

        // board item does not exist !
        if BoardItem = nil then begin
            LineOut( report,
                Format( 'No board item for net component : %s',
                    [Component.Name]
                )
            );
            result := False;
            continue;
        end;
    end;
end;

// *****************************************
//    CHECK NET PINS HAVE COMPONENT PINS
// *****************************************

function TProjectChecker.CheckNetPinsExist( report : TStrings ) : boolean;
var
    i : integer;
    Netlist : TneNetlist;
    Component : TneComponent;
    BoardItem : TveBoardItem;

    j : integer;
    NetPin : TnePin;
begin
    result := True;

    Netlist := FProject.Netlist;

    // for for every netlist component
    for i := 0 to Netlist.ComponentCount -1 do begin

        Component := Netlist.Components[i];

        BoardItem := FProject.ItemByDesignator( Component.Name );

        // board item does not exist !
        if BoardItem = nil then begin
            continue;
        end;

        // for every pin on component
        for  j := 0 to Component.PinCount -1 do begin
            NetPin := Component.Pins[j];

            // pin must exist on outline
            if BoardItem.Outline.PinIndexByName(NetPin.Name) = -1 then begin
                LineOut( report,
                    Format( 'Net pin %3s not on Component : %s',
                        [NetPin.Name, Component.Name]
                    )
                );
                result := False;
            end;
        end;
    end;
end;

// *****************************************
//      CHECK ITEMS HAVE VALID NAMES
// *****************************************

function TProjectChecker.CheckItemDesignators( report : TStrings ) : boolean;
var
    i : integer;
    Item : TveBoardItem;
begin
    result := True;

    for i := 0 to FProject.BoardItemCount -1 do begin
        Item := FProject.BoardItems[i];

        if (Item.Outline is TveLeadedOutline) or (Item.Outline is TveCellOutline) then begin

            if Trim( Item.Designator ) = '' then begin
                LineOut( report,
                    Format( 'Blank Designator : Item ?? at (%3d,%3d)',
                        [Item.X, Item.Y]
                    )
                );
                result := False;
            end;
        end;
    end;
end;

// *****************************************
//      CHECK NO DUPLICATE ITEM NAMES
// *****************************************

function CompareItemsByDesignator( P1, P2 : pointer ) : integer;
begin
    result := AnsiCompareStr( TveBoardItem(P1).Designator, TveBoardItem(P2).Designator );
end;

function TProjectChecker.CheckItemDuplicateDesignators( report : TStrings ) : boolean;
var
    I : integer;
    Items : TList;
    LastItem : TveBoardItem;
    Item : TveBoardItem;
begin

    result := True;

    Items := TList.Create;
    try

        // make list of items
        for i := 0 to FProject.BoardItemCount -1 do begin
            Item := TveBoardItem( FProject.BoardItems[i] );
            if (Item.Outline is TveLeadedOutline) or
                    (Item.Outline is TveCellOutline) then begin
                Items.Add( Item );
            end;
        end;

        // sort list in designator order so duplicates will be adjacent
        Items.Sort(CompareItemsByDesignator);

        // find duplicates
        LastItem := nil;
        for i := 0 to Items.Count -1 do begin

            Item := TveBoardItem( Items[i] );
            if LastItem <> nil then begin
                if Item.Designator = LastItem.Designator then begin

                    LineOut( report,
                        Format( 'Duplicate Designators : Item %s (%d,%d) Item %s (%d,%d)',
                            [LastItem.Designator, LastItem.X, LastItem.Y,
                            Item.Designator, Item.X, Item.Y]
                        )
                    );
                    result := False;
                end;
            end;
            // current item becomes last item ready for next check
            LastItem := Item;
        end;

    finally
        Items.Free;
    end;
end;

// *****************************************
//   CHECK ITEMS ALL INSIDE BOARD PERIMETER
// *****************************************

function TProjectChecker.CheckItemsInsideBoardPerimeter( report : TStrings ) : boolean;
var
    i : integer;
    Item : TveBoardItem;

    BoardWidth : integer;
    BoardHeight : integer;
begin
    result := True;

    BoardWidth := FProject.BoardWidth;
    BoardHeight := FProject.BoardHeight;

    for i := 0 to FProject.BoardItemCount -1 do begin

        Item := FProject.BoardItems[i];
        if (Item.X < 0) or (Item.X >= BoardWidth) or
            (Item.Y < 0) or (Item.Y >= BoardHeight) then begin
            LineOut( report,
                Format( 'Off board : Item %15s (%3d,%3d)',
                    [Item.Designator, Item.X, Item.Y]
                )
            );
            result := False;
        end;
    end;
end;

// *************************************************
//   CHECK ITEMS ON BOARD ARE ALL REQUIRED FOR NET
// *************************************************

function TProjectChecker.CheckItemsUnused( report : TStrings ) : boolean;
var
    i : integer;
    Netlist : TneNetlist;
    Component : TneComponent;
    BoardItem : TveBoardItem;
    Designator : string;
begin
    result := True;

    Netlist := FProject.Netlist;

    for i := 0 to FProject.BoardItemCount -1 do begin

        BoardItem := FProject.BoardItems[i];

        // respond only components, which are required by netlist -
        // others are added by user to interconnect or isolate tracks. 
        if not BoardItem.Outline.UserDefined then begin
            continue;
        end;

        Designator := BoardItem.Designator;
        Component := Netlist.ComponentByName( Designator );
        if Component = nil then begin
            LineOut( report,
                Format( 'Component surplus to netlist : %s',
                    [Designator]
                )
            );
            result := False;
        end;
    end;
end;


// ******************************
//      TEST PROJECT VALIDITY
// ******************************
(*
    Call with report = reference to TStrings object which will receive lines
    of the report.  Set report = nil if no report required.

    Returns
        True = Project valid, no lines added to report.
        False = Project not valid, if report not nil, lines added to report.
*)

function TProjectChecker.CheckAll( report : TStrings ) : boolean;
begin
    result := CheckOutlinesNames( report )                        ;
    result := CheckOutlinesDuplicateNames( report )     and result;
    result := CheckOutlinesDuplicatePins( report )      and result;
    result := CheckNetComponentsExist( report )         and result;
    result := CheckNetPinsExist( report )               and result;
    result := CheckItemDesignators( report )            and result;
    result := CheckItemDuplicateDesignators( report )   and result;
    result := CheckItemsInsideBoardPerimeter( report )  and result;
    result := CheckItemsUnused( report )                and result;
end;

end.


