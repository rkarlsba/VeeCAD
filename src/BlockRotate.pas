unit BlockRotate;

interface

uses Project;

procedure RotateSelected( Project : TveProject );


implementation

uses
    Outlines, Rotations, Types;

procedure RotateSelected( Project : TveProject );
var
    Bounds : TRect;
    i : integer;
    Item : TveBoardItem;
begin

    // find enclosing rectange which contains all selected component
    //Project.GetSelectedItemsBoundary( Left, Top, Right, Bottom  );

    // Don't use GetSelectedItemsPaintBoundary() because the paint rectangle
    // for component text can extend way out the side, causing the rotated
    // block to jump sideways on screen rather than rotating in place.
    Project.GetSelectedItemsBoundary( Bounds );

    // convert bounding rectangle to "cells inside border"
    dec( Bounds.Right );
    dec( Bounds.Bottom );

    // rotate and reposition each selected item
    for i := 0 to Project.BoardItemCount - 1 do begin
        Item := Project.BoardItems[i];
        if Item.Selected then begin

            // adjust coords so new position relative to right becomes position
            // relative to left (ie move to Left + (Right - X)
            Item.X := Bounds.Left + Bounds.Right - Item.X;
            Item.Y := Bounds.Top + Bounds.Bottom - Item.Y;

            // rotate item through 180 degrees
            Item.EndDeltaX := -Item.EndDeltaX;
            Item.EndDeltaY := -Item.EndDeltaY;
        end;
    end;
end;

end.

