unit BoardSize;

interface

uses Project, Outlines;

procedure CalcRequiredBoardRectangle( Project : TveProject;
    var Left, Right, Top, Bottom : integer );
procedure RequiredStripArea( Project : TveProject; var Width, Height : integer );

procedure RescueOffBoardItems( Project : TveProject );
procedure RescueOffBoardItem( Item : TveBoardItem; BoardWidth, BoardHeight : integer );
procedure RescueOffBoardSelectedItemText( Project : TveProject );

procedure MoveBoardItems( Project : TveProject; MoveX, MoveY : integer );

implementation

uses Rotations, Types, Board;

// calculate bounding rectangle which encloses whole board.  Right & Bottom
// values are 1 greater than coords of rightmost, bottommost cells.

procedure CalcRequiredBoardRectangle( Project : TveProject;
    var Left, Right, Top, Bottom : integer );
var
    i : integer;
    Item : TveBoardItem;
    ItemRect : TRect;
begin
    // if no components, make zero sized board at origin
    if Project.BoardItemCount = 0 then begin
        Left := 0;
        Right := 0;
        Top := 0;
        Bottom := 0;
        exit;
    end;

    // start with extreme zero size board dimensions
    Left := High(Left);
    Right := Low(Right);
    Top := High(Top);
    Bottom := Low(Bottom);

    // extend cell to accomodate all components
    for i := 0 to Project.BoardItemCount -1 do begin

        // bounding rectangle
        Item := Project.BoardItems[i];
        Item.Outline.GetScreenRectR( Item, ItemRect );

        if Left > ItemRect.Left then begin
            Left := ItemRect.Left;
        end;

        if Right < ItemRect.Right then begin
            Right := ItemRect.Right;
        end;

        if Top > ItemRect.Top then begin
            Top := ItemRect.Top;
        end;

        if Bottom < ItemRect.Bottom then begin
            Bottom := ItemRect.Bottom;
        end;
    end;
end;


// Move a BoardItems as required so that it is wholly contained within board
// boundaries.
procedure RescueOffBoardItem( Item : TveBoardItem; BoardWidth, BoardHeight : integer );
var
    ItemRect : TRect;
    // designator
    X, Y : integer;
    AdjustX : integer;
    AdjustY : integer;

begin
        Item.Outline.GetScreenRectR( Item, ItemRect );

        if ItemRect.Left < 0 then begin
            Item.X := Item.X - ItemRect.Left;
        end
        else if ItemRect.Right >= BoardWidth then begin
            Item.X := Item.X - ( ItemRect.Right - BoardWidth );
        end;

        if ItemRect.Top < 0 then begin
            Item.Y := Item.Y - ItemRect.Top;
        end
        else if ItemRect.Bottom >= BoardHeight then begin
            Item.Y := Item.Y - ( ItemRect.Bottom - BoardHeight );
        end;


        // ** keep designator within board edges **


        // find position of designator centre cell : we ignore designator rotation
        // and just keep centre cell inside board boundaries.
        Item.GetDesignatorCell( X, Y );

        AdjustX := 0;
        AdjustY := 0;

        if X < 0 then begin
            AdjustX := X
        end
        else if X >= BoardWidth then begin
            AdjustX := X - (BoardWidth -1);
        end;

        if Y < 0 then begin
            AdjustY := Y
        end
        else if Y >= BoardHeight then begin
            AdjustY := Y - (BoardHeight -1);
        end;

        if (AdjustX <> 0) or (AdjustY <> 0) then begin

            // rotate adjustment back to component reference position
            RotateReverse( AdjustX, AdjustY, 0, 0, Item.Rotation );

            // apply adjustment
            Item.TextX := Item.TextX - AdjustX;
            Item.TextY := Item.TextY - AdjustY;
        end;
end;

// Move any Project BoardItems as required so that all items are wholly
// contained within board boundaries.

procedure RescueOffBoardItems( Project : TveProject );
var
    BoardRight, BoardBottom : integer;
    i : integer;
    Item : TveBoardItem;
    ItemRect : TRect;

    // designator
    X, Y : integer;
    AdjustX : integer;
    AdjustY : integer;

begin
    // bounding rectangle is right, bottom is 1 cell more than rightmost,
    // bottommost allowable cells
    BoardRight := Project.BoardWidth;
    BoardBottom := Project.BoardHeight;

    for i := 0 to Project.BoardItemCount -1 do begin

        // ** keep item body + pins within board edges **
        Item := Project.BoardItems[i];
        Item.Outline.GetScreenRectR( Item, ItemRect );

        if ItemRect.Left < 0 then begin
            Item.X := Item.X - ItemRect.Left;
        end
        else if ItemRect.Right > BoardRight then begin
            Item.X := Item.X - ( ItemRect.Right - BoardRight );
        end;

        if ItemRect.Top < 0 then begin
            Item.Y := Item.Y - ItemRect.Top;
        end
        else if ItemRect.Bottom > BoardBottom then begin
            Item.Y := Item.Y - ( ItemRect.Bottom - BoardBottom );
        end;


        // ** keep designator within board edges **


        // find position of designator centre cell : we ignore designator rotation
        // and just keep centre cell inside board boundaries.
        Item.GetDesignatorCell( X, Y );

        AdjustX := 0;
        AdjustY := 0;

        if X < 0 then begin
            AdjustX := X
        end
        else if X >= BoardRight then begin
            AdjustX := X - (BoardRight -1);
        end;

        if Y < 0 then begin
            AdjustY := Y
        end
        else if Y >= BoardBottom then begin
            AdjustY := Y - (BoardBottom -1);
        end;

        if (AdjustX <> 0) or (AdjustY <> 0) then begin

            // rotate adjustment back to component reference position
            RotateReverse( AdjustX, AdjustY, 0, 0, Item.Rotation );

            // apply adjustment
            Item.TextX := Item.TextX - AdjustX;
            Item.TextY := Item.TextY - AdjustY;
        end;
    end;
end;

procedure RescueOffBoardSelectedItemText( Project : TveProject );
var
    i : integer;
    Item : TveBoardItem;
begin
    // adjust designator positions to ensure designators inside board edges
    for i := 0 to Project.BoardItemCount -1 do begin
        Item := Project.BoardItems[i];
        if Item.Selected then begin
            Item.SetDesignatorInsideRectangle(
                0, 0, Project.BoardWidth, Project.BoardHeight );
        end;
    end;
end;



// ***************************************************
//      RETURN MINIMUM AREA TO CONTAIN ALL STRIPS
// ***************************************************

procedure RequiredStripArea( Project : TveProject; var Width, Height : integer );
var
    Board : TbrBoard;
    i : integer;
    Strip : TbrStrip;
begin
    Board := Project.Board;

    // automatically generated patterns never have a minimum size, because
    // the pattern repeats
    if Board.Pattern <> ptDefined then begin
        Width := -1;
        Height := -1;
        exit;
    end;
    // calculate size of defined pattern board
    Width := 0;
    Height := 0;

    for i := 0 to Board.StripCount - 1 do begin
        Strip := Board.Strips[i];
        if Strip.Finish.X >= Width  then begin
            Width := Strip.Finish.X + 1;
        end;
        if Strip.Finish.Y >= Height  then begin
            Height := Strip.Finish.Y + 1;
        end;
    end;
end;


// *************************************
//       UTILITY - MOVE ALL ITEMS
// *************************************

procedure MoveBoardItems( Project : TveProject; MoveX, MoveY : integer );
var
    i : integer;
    Item : TveBoardItem;
begin
    // move components
    for i := 0 to Project.BoardItemCount -1 do begin
        Item := Project.BoardItems[i];
        Item.X := Item.X + MoveX;
        Item.Y := Item.Y + MoveY;
    end;
end;

end.
