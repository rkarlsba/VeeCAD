unit Route;

interface

uses Project;
(*
    All user interface router calls go to this .pas file.  A staging point
    for the use of various combinations of the routing classes of
    Breaks.pas
    RouteLinks.pas
    RouteLeaded.pas
*)

procedure AddBreaks( Project : TveProject );
procedure LinkSelectedNet( Project : TveProject );
procedure LinkAll( Project : TveProject );
procedure PlaceLeadedItems( Project : TveProject );
procedure PlaceSelectedLeadedItems( Project : TveProject );

procedure FullAutoRoute( Project : TveProject );

implementation

uses
    Breaks, RouteLinks, RouteLeaded, Board;

// **********************************************
//        Functions from the Router Menu
// **********************************************

procedure AddBreaks( Project : TveProject );
var
    BreakTool : TveBreakTool;
begin
    if Project.Board.Pattern <> ptStrip then begin
        exit;
    end;

    BreakTool := TveBreakTool.Create;
    try
        Project.DeSelectAllItems;
        BreakTool.Project := Project;
        Project.BeginUndo;
        BreakTool.PlaceBreaksWithoutLeaded;
        Project.EndUndo;
    finally
        BreakTool.Free;
    end;
    Project.Dirty := True;
end;


procedure LinkSelectedNet( Project : TveProject );
var
    Linker : TveRouter;
begin
    if Project.Board.Pattern <> ptStrip then begin
        exit;
    end;

    Linker := TveRouter.Create;
    try
        // start undo - Linker will add items to undo list
        Project.DeSelectAllItems;
        Linker.Project := Project;
        Project.BeginUndo;
        Linker.RouteNet( Project.TraceNet );
        Project.EndUndo;
    finally
        Linker.Free;
    end;
    Project.Dirty := True;
end;


procedure LinkAll( Project : TveProject );
var
    Linker : TveRouter;
begin
    if Project.Board.Pattern <> ptStrip then begin
        exit;
    end;

    Project.DeSelectAllItems;
    Linker := TveRouter.Create;
    try
        Linker.Project := Project;
        Project.BeginUndo;
        Linker.RouteAllNetsWithoutLeaded;
        Project.EndUndo;
    finally
        Linker.Free;
    end;
    Project.Dirty := True;
end;

procedure PlaceLeadedItemSelected( Project : TveProject );
var
    Router : TLeadedRouter;
begin
    if Project.Board.Pattern <> ptStrip then begin
        exit;
    end;

    Router := TLeadedRouter.Create;
    try
        Project.BeginUndo;
        Router.PlaceSelectedLeadedItem;
        Project.EndUndo;
    finally
        Router.Free;
    end;
    Project.Dirty := True;
end;

procedure PlaceSelectedLeadedItems( Project : TveProject );
var
    Router : TLeadedRouter;
begin
    if Project.Board.Pattern <> ptStrip then begin
        exit;
    end;

    Router := TLeadedRouter.Create;
    try
        Router.Project := Project;
        Project.BeginUndo;
        Router.PlaceSelectedLeadedItems;
        Project.EndUndo;
    finally
        Router.Free;
    end;
    Project.Dirty := True;
end;


procedure PlaceLeadedItems( Project : TveProject );
var
    Router : TLeadedRouter;
begin
    if Project.Board.Pattern <> ptStrip then begin
        exit;
    end;

    Project.DeSelectAllItems;
    Router := TLeadedRouter.Create;
    try
        Router.Project := Project;
        Project.BeginUndo;
        Router.PlaceAllLeadedItems;
        Project.EndUndo;
    finally
        Router.Free;
    end;
    Project.Dirty := True;
end;

procedure FullAutoRoute( Project : TveProject );
var
    BreakTool : TveBreakTool;
    Linker : TveRouter;
    Router : TLeadedRouter;
begin
    if Project.Board.Pattern <> ptStrip then begin
        exit;
    end;

    Project.DeSelectAllItems;
    Project.BeginUndo;

    BreakTool := TveBreakTool.Create;
    try
        Project.DeSelectAllItems;
        BreakTool.Project := Project;
        BreakTool.PlaceBreaksWithoutLeaded;
    finally
        BreakTool.Free;
    end;

    Linker := TveRouter.Create;
    try
        Linker.Project := Project;
        Linker.RouteAllNetsWithoutLeaded;
    finally
        Linker.Free;
    end;

    Router := TLeadedRouter.Create;
    try
        Router.Project := Project;
        Router.PlaceAllLeadedItems;
    finally
        Router.Free;
    end;

    Project.EndUndo;
    Project.Dirty := True;
end;

{
Also
====

Also need a "consolidate/optimise/compact" process which moves links and
leaded components sideways to free up long vertical runs.  This can be called
while iterating thru Place Links.  Same for Place Leaded parts.

Place Breaks and Place Links need to shove breaks along strips to make
links/leaded placement possible.  A less powerful alternative is to make the
consolidate process move breaks to "midway" positions which leave an equal
number of free cells on each side of the break.
}


end.


