unit Selector;

interface

uses Project;

// Set various items in a TveProject to Selected, and unselect all other items.

procedure SelectAll( Project : TveProject );
procedure InvertSelection( Project : TveProject );

procedure SelectLinks( Project : TveProject );
procedure SelectLinksInSelection( Project : TveProject );
procedure SelectBreaks( Project : TveProject );
procedure SelectbreaksInSelection( Project : TveProject );
procedure SelectShortedLinks( Project : TveProject );
procedure SelectUnusedBreaks( Project : TveProject );
procedure SelectUnusedComponents( Project : TveProject );


implementation

uses Outlines, SizeableOutlines, OtherOutlines, Breaks, Netlist;

// *********************************************
//              SELECT ALL ITEMS
// *********************************************

procedure SelectAll( Project : TveProject );
var
    i : integer;
begin
    for i := 0 to Project.BoardItemCount -1 do begin
        Project.BoardItems[i].Selected :=  True;
    end;
end;

// *********************************************
//              INVERT SELECTION
// *********************************************
procedure InvertSelection( Project : TveProject );
var
    i : integer;
    Item : TveBoardItem;
begin
    for i := 0 to Project.BoardItemCount -1 do begin
        Item := Project.BoardItems[i];
        Item.Selected := not Item.Selected;
    end;
end;


// *********************************************
//     SELECT ITEMS WITH SPECIFIED OUTLINE
// *********************************************
{
    All items are unselected, then any items with an outline of OutlineClass
    are selected.
}
procedure SelectItems( Project : TveProject; OutlineClass : TClass );
var
    i : integer;
    Item : TveBoardItem;
begin
    Project.DeSelectAllItems;
    for i := 0 to Project.BoardItemCount -1 do begin
        Item := Project.BoardItems[i];
        if Item.Outline is OutlineClass then begin
            Item.Selected := True;
        end;
    end;
end;

// *************************************************************
//  SELECT ITEMS WITH SPECIFIED OUTLINE FROM WITHIN SELECTION
// *************************************************************
{
    Any items with Selected = True, are unselected unless they have
    an outline of OutlineClass.
}

procedure SelectItemsInSelection( Project : TveProject; OutlineClass : TClass );
var
    i : integer;
    Item : TveBoardItem;
begin
    for i := 0 to Project.BoardItemCount -1 do begin
        Item := Project.BoardItems[i];
        if Item.Selected and not (Item.Outline is OutlineClass) then begin
            Item.Selected := False;
        end;
    end;
end;

// ****************************************
//      SET SELECTED = TRUE FOR LINKS
// ****************************************

procedure SelectLinks( Project : TveProject );
begin
    SelectItems( Project, TveLinkOutline );
end;

// ****************************************
//   LEAVE ONLY SELECTED LINKS SELECTED
// ****************************************

procedure SelectLinksInSelection( Project : TveProject );
begin
    SelectItemsInSelection( Project, TveLinkOutline );
end;

// ****************************************
//      SET SELECTED = TRUE FOR BREAKS
// ****************************************

procedure SelectBreaks( Project : TveProject );
begin
    SelectItems( Project, TveBreakOutline );
end;

// ****************************************
//   LEAVE ONLY SELECTED BREAKS SELECTED
// ****************************************

procedure SelectbreaksInSelection( Project : TveProject );
begin
    SelectItemsInSelection( Project, TveBreakOutline );
end;

// ****************************************
//   LEAVE ONLY SELECTED BREAKS SELECTED
// ****************************************

procedure SelectShortedLinks( Project : TveProject );
begin

end;

// ****************************************
//          SELECT UNUSED BREAKS
// ****************************************

procedure SelectUnusedBreaks( Project : TveProject );

var BreakTool : TveBreakTool;
begin
    BreakTool := TveBreakTool.Create;
    try
        BreakTool.Project := Project;
        BreakTool.SelectRedundant;
    finally
        BreakTool.Free;
    end;
end;

// ****************************************
//          SELECT UNUSED BREAKS
// ****************************************
procedure SelectUnusedComponents( Project : TveProject );
var
    i : integer;
    Netlist : TneNetlist;
    Component : TneComponent;
    BoardItem : TveBoardItem;
    Designator : string;
begin
    Netlist := Project.Netlist;

    Project.DeSelectAllItems;

    for i := 0 to Project.BoardItemCount -1 do begin

        BoardItem := Project.BoardItems[i];

        // detect only components, which are required by netlist -
        // others are added by user to interconnect or isolate tracks.
        if not BoardItem.Outline.UserDefined then begin
            continue;
        end;

        Designator := BoardItem.Designator;
        Component := Netlist.ComponentByName( Designator );
        if Component = nil then begin
            BoardItem.Selected := True;
        end;
    end;
end;


end.

