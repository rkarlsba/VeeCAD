unit LibraryTools;

interface

uses Project, SysUtils;

procedure MakeLibraryLayout( Project : TveProject );


implementation

uses Classes, Outlines, BoardSize, ExceptSafe;

type EPlaceOutlines = class( Exception );
type ESafePlaceOutlines = class( ESafe );

// ***********************************************
//    MAKE A COMPONENT FOR EVERY UNUSED OUTLINE
// ***********************************************

function CompareItemsByOutlineTag( P1, P2 : pointer ) : integer;
var
    Tag1, Tag2 : integer;
begin
    Tag1 := TveBoardItem(P1).Outline.Tag;
    Tag2 := TveBoardItem(P2).Outline.Tag;

    if Tag1 > Tag2 then begin
        result := 1;
    end
    else if Tag1 < Tag2 then begin
        result := -1;
    end
    else begin
        result :=0;
    end;
end;

function CompareOutlinesByName( P1, P2 : pointer ) : integer;
begin
    result := CompareText( TveOutline(P1).Name, TveOutline(P2).Name );
end;

function CompareItemsByOutlineName( P1, P2 : pointer ) : integer;
begin
    result := CompareText(
        TveBoardItem(P1).Outline.Name, TveBoardItem(P2).Outline.Name );
end;



procedure MakeLibraryLayout( Project : TveProject );

label
    loop;
var
    OutlineList : TList;
    OutlineIndex : integer;
    Outline : TveOutline;
    NextOutline : TveOutline;

    ComponentList : TList;
    ComponentIndex : integer;
    ComponentCount : integer;
    ComponentOutline : TveOutline;
    Component : TveBoardItem;
    NextComponent : TveBoardItem;

    i: integer;
    FreeOutline : boolean;
    NewComponent : TveBoardItem;
begin
    // We can undo the changes.
    Project.BeginUndo;

    ComponentList := nil;
    OutlineList := nil;
    try
        ComponentList := TList.Create;
        OutlineList := TList.Create;

        // fill OutlineList with references to all outlines
        OutlineList.Capacity := Project.OutlineCount;
        for i := 0 to Project.OutlineCount - 1 do begin
            Outline := Project.Outlines[i];
            OutlineList.Add( Outline );
        end;

        // sort outline list in Name order so identical names are adjacent
        OutlineList.Sort( CompareOutlinesByName );

        // work through outline list looking for adjacent outlines with same
        // name and raise exception if any two outlines have same name
        for i := 0 to OutlineList.Count - 2 do begin
            Outline := TveOutline( OutlineList[i] );
            NextOutline := TveOutline( OutlineList[i + 1] );
            if Outline.Name = NextOutline.Name then begin
                raise ESafePlaceOutlines.Create(
                'Outlines not placed - project has duplicate outline names' );
            end;
        end;

        // tag outlines in order - we can uniquely identify an outline by
        // its tag, rather than by comparing outline names
        for i := 0 to OutlineList.Count - 1 do begin
            TveOutline( OutlineList[i] ).Tag := i; 
        end;

        // fill ItemList with references to all components ("Items")
        ComponentCount := Project.BoardItemCount;
        ComponentList.Capacity := ComponentCount;
        for i := 0 to ComponentCount - 1 do begin
            Component := Project.BoardItems[i];
            // ignoring links etc, add component to list
            if Component.Outline.UserDefined then begin
                ComponentList.Add( Component )
            end;
        end;

        // and sort component list by Outline Tag No
        ComponentList.Sort( CompareItemsByOutlineTag );

        // if multiple components have same outline (Tag), delete all except the
        // first component
        for i := 0 to ComponentList.Count - 2 do begin
            Component := TveBoardItem( ComponentList[i] );
            NextComponent := TveBoardItem( ComponentList[i + 1] );
            if Component.Outline.Tag = NextComponent.Outline.Tag then begin

                // remove component from board and store it in an undo record
                Project.DeleteItemToUndo( NextComponent );
            end;
        end;

        // refill component list from Project
        ComponentCount := Project.BoardItemCount;
        ComponentList.Count := 0;
        for i := 0 to ComponentCount - 1 do begin
            Component := Project.BoardItems[i];
            // ignoring links etc, add component to list
            if Component.Outline.UserDefined then begin
                ComponentList.Add( Component )
            end;
        end;

        // and sort component list by Outline Tag
        ComponentList.Sort( CompareItemsByOutlineTag );

        // Work through Components list, forcing every component to have same
        // name as its outline
        for i := 0 to ComponentList.Count -1 do begin

            Component := TveBoardItem( ComponentList[i] );
            if Component.Designator <> Component.Outline.Name then begin
                // before Undo
                Component.TakeSnapshot;
                // rename designator
                Component.Designator := Component.Outline.Name;
                // record for Undo
                Project.ItemSnapshotToUndo( Component );
            end;
        end;


        // Work through Outline list, checking if Component list has an outline
        // to match
        ComponentIndex := 0;
        ComponentCount := ComponentList.Count;

        //.. for each outline
        for OutlineIndex := 0 to OutlineList.Count - 1 do begin

            FreeOutline := True;
            Outline := Outlinelist[OutlineIndex];

            // try to match outline with component outlines by working forward
            // in component list - no match means component is free
            while ComponentIndex < ComponentCount do begin

                ComponentOutline := TveBoardItem( ComponentList[ComponentIndex]).Outline;

                // not interested in built-in outlines like links, breaks
                if not ComponentOutline.UserDefined then begin
                    goto loop;
                end;

                // if component uses our outline, then to next outline!
                if ComponentOutline.Tag = Outline.Tag then begin
                    Inc( ComponentIndex );
                    FreeOutline := False;
                    break;
                end;

                // if component uses an outline with a higher tag No.
                // then our outline is Unused
                if ComponentOutline.Tag > Outline.Tag then begin
                    break;
                end;

loop:
                // to next component for a comparison
                Inc( ComponentIndex );
            end;

            // if our outline not used by a component, build a component to use it
            if FreeOutline then begin

                NewComponent := TveBoardItem.Create;
                NewComponent.Outline := Outline;
                NewComponent.Designator := Outline.Name;
                Outline.SetDefaultLength( NewComponent );
                Project.AddItemToUndo( NewComponent );
            end;
        end;

    finally
        ComponentList.Free;
        OutlineList.Free;
    end;

    // make sure all component are fully within board limits
    RescueOffBoardItems( Project );

    // If no changes made, the undo engine will delete the entire Undo operation
    Project.EndUndo;

    Project.Dirty := True;
end;


// Do we need TveOutline.SetBoardItemDefaults( Item : TveBoardItem );
// This would set length, etc to resonable values
// if BodyLength <= Item.Length then begin
//      BodyLength = Item.Length + 2
// end;



end.



