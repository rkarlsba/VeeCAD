unit Adjuster;

interface

uses Classes, Project;

type TBoardItemAdjuster = class

  protected
      FProject : TveProject;

  public

    // Do Mark before reassigning outlines to components, then do Adjust after.
    // Reason - some components need altering when an outline type swapped or
    // assigned after Creation - especially for Sizeable outlines.
    procedure MarkComponents( Project : TveProject );
    procedure AdjustComponents;

{
    constructor Create;
    destructor Destroy; override;
}    
end;


implementation

uses Outlines, SizeableOutlines, RadialOutlines;

// values for ReservedAdjust integer member of TveBoardItem

const

    // ** VALUES FOR TveBoardItem.ReservedAdjust1 member **

    // set to this to mark item as not having a leaded outline
    // A new Board Item also has value initialised to zero by constructor
    NON_LEADED_OR_NEW = 0;

    // set to this to mark item as having a leaded outline
    LEADED = 1;



procedure TBoardItemAdjuster.MarkComponents( Project : TveProject );
//const BoolToLeadedNo : array[boolean] of integer := ( NON_LEADED, LEADED );
var
    i : integer;
    Item : TveBoardItem;
begin
    FProject := Project;
    // record all items which have sizable outlines
    for i := 0 to Project.BoardItemCount -1 do begin
        Item := Project.BoardItems[i];

        // store value for components which have for leaded or radial outlines.
        // this value means "I already have a leaded or radial outline"
        if (Item.Outline is TveLeadedOutline) or
                (Item.Outline is TveRadialOutline) then begin
            Item.ReservedAdjust1 := LEADED;
        end

        // store value for non-leaded
        else begin
            Item.ReservedAdjust1 := NON_LEADED_OR_NEW;
        end;
    end;
end;


procedure TBoardItemAdjuster.AdjustComponents;
var
    i : integer;
    Item : TveBoardItem;
begin
    for i := 0 to FProject.BoardItemCount -1 do begin
        Item := FProject.BoardItems[i];

        // if item has leaded or radial outline AND (did not have one before or
        // is new), then its has just received a leaded outline and the
        // component length needs adjusting
        if (Item.ReservedAdjust1 = NON_LEADED_OR_NEW) then begin
            Item.Outline.SetDefaultLength( Item );
        end;
    end;
end;


end.
