unit Tracks;

interface

uses Windows, Contnrs,
    Board, TrackItems, Intersect, UndoEngine;

// ************************************************************
//      CONTAINER HOLDS ALL STRIPS & SEGMENTS ON A BOARD
// ************************************************************

type

TbeTracks = class

  protected
    // property handlers
    FItems : TObjectList;
    FHeight : integer;
    FWidth : integer;

    // contained
    UndoEng : TunUndo;

    // property handlers
    function GetCount : integer;
    function GetItem(i: integer): TteTrack;
    procedure Clear;
    function GetBoardRect : TAlignedFloatRect;
    function GetBoardRect_D : TRect;
    function GetBoardRect_Cells : TRect;

  public
    Marked : boolean;
    Dirty : boolean;

    // board dimensions in cells
    property Height : integer read FHeight write FHeight;
    property Width : integer read FWidth write FWidth;
    property BoardRect : TAlignedFloatRect read GetBoardRect;
    property BoardRect_D : TRect read GetBoardRect_D;
    property BoardRect_Cells : TRect read GetBoardRect_Cells;

    property Count : integer read GetCount;
    property Items[ Index : integer ] : TteTrack read GetItem; default;

    function AddNewStrip : TteStrip;
    function AddNewSegment : TteSegment;

    procedure DeleteItem( Item : TteTrack );
    procedure DeleteSelectedItems;

    function GetSelectedCount : integer;
    procedure SelectAll;
    procedure ClearSelectedItems;

    procedure GetSelectedItemsBoundary( var SRect : TAlignedFloatRect );
    function GetSelectedItemsBoundary_D : TRect;
    function SelectInsideRect( SRect : TAlignedFloatRect ) : integer;

    procedure MoveSelectedItemsCells( deltaX, deltaY : integer );
    procedure MoveSelectedItems_D( deltaX, deltaY : integer );

    function SelectedTracksUnderMouse( ClickPoint : TFloatPoint ) : boolean;
    function ItemsUnderMouseCount( ClickPoint : TFloatPoint ) : integer;
    function ClickedItem( ClickPoint : TFloatPoint ) : TteTrack;
    function GetSelectedTypeCount( C : TClass ) : integer;

    procedure ClearMarkedItems;

    // UNDO-REDO
    procedure SnapshotSelectedItems;
    procedure StoreSnaphotSelectedAsUndo;
    procedure RegisterNewTrackForUndo(Track : TteTrack);
    function AddNewStripWithUndo : TteStrip;
    function AddNewSegmentWithUndo : TteSegment;
    procedure DeleteItemWithUndo( Item : TteTrack );
    procedure DeleteSelectedItemsWithUndo;
    procedure Undo;
    procedure Redo;

    procedure LoadFromBoard( Board : TbrBoard );
    procedure SaveToBoard( Board : TbrBoard );
    procedure DeleteBadSegments;

    constructor Create;
    destructor Destroy; override;
end;

TbeOperation = (opAdd, opRemove);

TbeTracksMemento = class( TunMemento )
protected
    Tracks : TbeTracks;
    Track : TteTrack;
    Operation : TbeOperation;
public
    Procedure Undo; override;
    Procedure Redo; override;
    Procedure DiscardUndo; override;
    Procedure DiscardRedo; override;
end;

implementation

uses SysUtils, Math, Rectangles
{$IFNDEF VER200}, System.Classes, System.Types {$ENDIF} ;

const
    DIVS_PER_CELL = 1000;
    DIVS_PER_CELL_HALF = 500;


{ TbeTracks }

type EBoardFast = class( Exception );


// ***************************************
//          CREATE, DESTROY
// ***************************************

constructor TbeTracks.Create;
// set undo depth here
const UNDO_LEVELS = 50;
begin
    FItems := TObjectList.Create;
    UndoEng := TunUndo.Create(UNDO_LEVELS);
end;

destructor TbeTracks.Destroy;
begin
    UndoEng.Free;
    FItems.Free;
    inherited;
end;

// ***************************************
//     TRACKS (STRIPS & SEGMENTS ETC)
// ***************************************

function TbeTracks.GetCount: integer;
begin
    result := FItems.Count;
end;

function TbeTracks.GetItem(i: integer): TteTrack;
begin
    result := TteTrack( FItems[i] );
end;

function TbeTracks.AddNewStrip: TteStrip;
begin
    result := TteStrip.Create;
    FItems.Add( result );
end;

function TbeTracks.AddNewSegment: TteSegment;
begin
    result := TteSegment.Create;
    FItems.Add( result );
end;


procedure TbeTracks.DeleteItem( Item : TteTrack );
var
    index : integer;
begin
    Index := FItems.IndexOf( Item );
    if index < 0 then begin
        raise EBoardFast.Create( 'Deleting invalid tracks item reference' );
    end;
    FItems.Delete( Index );

    // or replace all of above with
    // FItems.Remove( Item );
end;

// ******************************************
//          INFORMATION ROUTINES
// ******************************************

function TbeTracks.GetBoardRect : TAlignedFloatRect;
begin
    result.TopLeft.x := -0.5;
    result.TopLeft.y := -0.5;
    result.BottomRight.x := Width - 0.5;
    result.BottomRight.y := Height -0.5;
end;

function TbeTracks.GetBoardRect_D : TRect;
begin
    result.TopLeft.x := - DIVS_PER_CELL_HALF;
    result.TopLeft.y := - DIVS_PER_CELL_HALF;
    result.BottomRight.x := ( Width * DIVS_PER_CELL ) - DIVS_PER_CELL_HALF;
    result.BottomRight.y := ( Height * DIVS_PER_CELL ) - DIVS_PER_CELL_HALF;
end;

function TbeTracks.GetBoardRect_Cells : TRect;
begin
    result.TopLeft.x := 0;
    result.TopLeft.y := 0;
    result.BottomRight.x := Width - 1;
    result.BottomRight.y := Height - 1;
end;

// ******************************************
//            ITEM MANAGEMENT
// ******************************************

procedure TbeTracks.ClearMarkedItems;
var
    i : integer;
begin
    for i := 0 to FItems.Count - 1 do begin
        Items[i].Marked := False;
    end;
end;


procedure TbeTracks.ClearSelectedItems;
var
    i : integer;
begin
    for i := 0 to FItems.Count - 1 do begin
        Items[i].Selected := False;
    end;
end;

procedure TbeTracks.SelectAll;
var
    i : integer;
begin
    for i := 0 to FItems.Count -1 do begin
        Items[i].Selected := True;
    end;
end;

function TbeTracks.GetSelectedCount : integer;
var
    i : integer;
begin
    result := 0;
    for i := 0 to FItems.Count - 1 do begin
        if Items[i].Selected then begin
            inc( result );
        end;
    end;
end;

function TbeTracks.ItemsUnderMouseCount( ClickPoint : TFloatPoint ) : integer;
var
    i : integer;
begin
    result := 0;
    for i := 0 to Count - 1 do begin
        if Items[i].ClickedOn( ClickPoint ) then begin
            Inc( result );
        end;
    end;
end;

procedure TbeTracks.GetSelectedItemsBoundary( var SRect : TAlignedFloatRect );
var
    i : integer;
    Item : TteTrack;
    ItemRect : TAlignedFloatRect;
    Bounds : TAlignedFloatRect;
begin
    // set rectangle borders to "no rectangle"
    Bounds.TopLeft.x := MaxSingle;
    Bounds.TopLeft.y := MaxSingle;
    Bounds.BottomRight.x := MinSingle;
    Bounds.BottomRight.y := MinSingle;

    // expand rectangle to contain all seleccted components
    for i := 0 to Count - 1 do begin
        Item := Items[i];
        if Item.Selected then begin
            ItemRect := Item.GetPaintRect;
            CombineAlignedFloatRectangles( Bounds, ItemRect );
        end;
    end;

    SRect := Bounds;
end;

function TbeTracks.GetSelectedItemsBoundary_D : TRect;
var
    i : integer;
    Item : TteTrack;
    ItemRect_D : TRect;
begin
    // set rectangle borders to "no rectangle"
    result.TopLeft.x := High( result.TopLeft.x );
    result.TopLeft.y := High( result.TopLeft.y );
    result.BottomRight.x := Low( result.BottomRight.x );
    result.BottomRight.y := Low( result.BottomRight.y );

    // expand rectangle to contain all seleccted components
    for i := 0 to Count - 1 do begin
        Item := Items[i];
        if Item.Selected then begin
            ItemRect_D := Item.GetPaintRect_D;
            ExtendRectangle( result, ItemRect_D );
        end;
    end;
end;


// Count Number of Items that are Selected AND of given type

function TbeTracks.GetSelectedTypeCount( C : TClass ) : integer;
var
    i : integer;
    Item : TteTrack;
begin
    // count items that are selected and of desired class
    result := 0;
    for i := 0 to Count - 1 do begin
        Item := Items[i];
        if Item.Selected and (Item is C) then begin
            Inc( result );
        end;
    end;
end;

function TbeTracks.SelectInsideRect( SRect : TAlignedFloatRect ) : integer;
var
    i : integer;
    Item : TteTrack;
//  ItemRect_D : TRect;
    ItemRect : TAlignedFloatRect;
begin
    // initialise count of selected items to zero
    result := 0;

    for i := 0 to Count - 1 do begin
        Item := Items[i];
//      ItemRect_D := Item.GetPaintRect_D;
        ItemRect := Item.GetPaintRect;
        if EnclosesRectAligned( ItemRect, SRect ) then begin
            Inc( result );
            Item.Selected := True;
        end;
    end;
end;


// **************************************************
//              MOVE SELECTED ITEMS
// **************************************************

// move selected items
procedure TbeTracks.MoveSelectedItemsCells( deltaX, deltaY : integer );
var
    i : integer;
    Item : TteTrack;
begin
    for i := 0 to Count - 1 do begin
        Item := Items[i];
        if Item.Selected then begin
            Item.MoveCells( deltaX, deltaY );
        end;
    end;
end;

procedure TbeTracks.MoveSelectedItems_D( deltaX, deltaY : integer );
var
    i : integer;
    Item : TteTrack;
begin
    for i := 0 to Count - 1 do begin
        Item := Items[i];
        if Item.Selected then begin
            Item.MoveCells_D( deltaX, deltaY );
        end;
    end;
end;

// **************************************************
//          DELETE SELECTED ITEMS
// **************************************************

procedure TbeTracks.DeleteSelectedItems;
var
    i : integer;
    Item : TteTrack;
begin
    for i := Count - 1 downto 0 do begin
        Item := Items[i];
        if Item.Selected then begin
            DeleteItem( Item );
        end;
    end;
end;


// **************************************************
//        REPORT ITEMS UNDER MOUSE CLICK
// **************************************************

function TbeTracks.SelectedTracksUnderMouse( ClickPoint : TFloatPoint ) : boolean;
var
    i : integer;
    Item : TteTrack;
begin
    for i := 0 to Count - 1 do begin
        Item := Items[i];
        // looking for any selected item which is under the mouse
        if Item.Selected and Item.ClickedOn( ClickPoint ) then begin
            result := True;
            exit;
        end;
    end;
    // nothing found, fail
    result := False;
end;

function TbeTracks.ClickedItem( ClickPoint : TFloatPoint ) : TteTrack;
var
    i : integer;
    Item : TteTrack;
begin
    result := nil;

    for i := 0 to Count - 1 do begin

        Item := Items[i];

        if Item.ClickedOn( ClickPoint ) then begin

            Item.ClickedOn( ClickPoint );

            if result = nil then begin
                result := Item;
                continue;
            end;

            // go for the smallest area thing you can find under the mouse
            // - sometimes there will be multiple items.
            if Item.Area < result.Area then begin
                result := Item;
            end;
        end;
    end;
    // we exit with result=nil (nothing under mouse) or result=smallest item
    // under the mouse
end;


// ******************************************
//          UNDO-REDO-SNAPSHOT
// ******************************************

procedure TbeTracks.SnapshotSelectedItems;
var
  i : integer;
  Item : TteTrack;
begin
    for i := 0 to FItems.Count - 1 do begin
        Item := Items[i];
        if Item.Selected then begin
            Item.TakeSnapshot;
        end;
    end;
end;

procedure TbeTracks.StoreSnaphotSelectedAsUndo;
var
  i : integer;
  Item : TteTrack;
  Memento : TteMemento;
begin
    // begin Undo Transaction
    UndoEng.BeginTransaction;

    // add changed items to undo
    for i := 0 to FItems.Count - 1 do begin
        Item := Items[i];
        if (Item.Selected and Item.ChangedSinceSnapshot) then begin
            Memento := Item.CreateMementoFromSnapshot;
            UndoEng.AddMemento(Memento);
        end;
    end;

    // end Undo Transaction
    UndoEng.EndTransaction;
end;

procedure TbeTracks.RegisterNewTrackForUndo(Track : TteTrack);
var
    Memento : TbeTracksMemento;
begin
    Memento := TbeTracksMemento.Create;
    Memento.Tracks := Self;
    Memento.Track := Track;
    Memento.Operation := opAdd;
    UndoEng.BeginTransaction;
    UndoEng.AddMemento(Memento);
    UndoEng.EndTransaction;
end;


function TbeTracks.AddNewStripWithUndo : TteStrip;
var
    Memento : TbeTracksMemento;
begin
    result := AddNewStrip;
    Memento := TbeTracksMemento.Create;
    Memento.Tracks := Self;
    Memento.Track := result;
    Memento.Operation := opAdd;
    UndoEng.BeginTransaction;
    UndoEng.AddMemento(Memento);
    UndoEng.EndTransaction;
end;

function TbeTracks.AddNewSegmentWithUndo : TteSegment;
var
    Memento : TbeTracksMemento;
begin
    result := AddNewSegment;
    Memento := TbeTracksMemento.Create;
    Memento.Tracks := Self;
    Memento.Track := result;
    Memento.Operation := opAdd;
    UndoEng.BeginTransaction;
    UndoEng.AddMemento(Memento);
    UndoEng.EndTransaction;
end;

procedure TbeTracks.DeleteItemWithUndo( Item : TteTrack );
var
    Memento : TbeTracksMemento;
begin
    // the undo engine will own the item via this Memento
    Memento := TbeTracksMemento.Create;
    Memento.Tracks := Self;
    Memento.Track := Item;
    Memento.Operation := opRemove;
    UndoEng.BeginTransaction;
    UndoEng.AddMemento(Memento);
    UndoEng.EndTransaction;

    // release item from Self, the container object
    FItems.Extract( Item );
end;

procedure TbeTracks.DeleteSelectedItemsWithUndo;
var
  i : integer;
  Item : TteTrack;
  Memento : TbeTracksMemento;
begin
    // begin Undo Transaction
    UndoEng.BeginTransaction;

    // add changed items to undo
    for i := FItems.Count - 1 downto 0 do begin
        Item := Items[i];
        if Item.Selected then begin
            Memento := TbeTracksMemento.Create;
            Memento.Tracks := Self;
            Memento.Track := Item;
            Memento.Operation := opRemove;
            UndoEng.AddMemento(Memento);
            Fitems.Extract( Item );
        end;
    end;

    // end Undo Transaction
    UndoEng.EndTransaction;
end;

procedure TbeTracks.Undo;
begin
    ClearSelectedItems;
    UndoEng.Undo;
end;

procedure TbeTracks.Redo;
begin
    ClearSelectedItems;
    UndoEng.Redo;
end;



// ******************************************
//          CLEAR STRIPS & SEGMENTS
// ******************************************

procedure TbeTracks.Clear;
begin
    FItems.Clear;
end;


// ******************************************
//     LOAD & SAVE TO TBRBOARD OBJECT
// ******************************************

procedure TbeTracks.LoadFromBoard(Board: TbrBoard);
var
    i : integer;
    Strip : TbrStrip;
    Segment : TbrSegment;
    FastStrip : TteStrip;
    FastSegment : TteSegment;
begin
    Clear;

    // board rectangle
    FHeight := Board.Height;
    FWidth := Board.Width;

    // we copy the Strips, not the RawStrips, because:
    // 1. Strips includes built-in patterns, so built in patterns get converted
    // into defined patterns
    // 2. Strips are "cleaned up", overlapping sections combined

    for i := 0 to Board.StripCount -1 do begin
        Strip := Board.Strips[i];
        FastStrip := AddNewStrip;
        FastStrip.Start := Strip.Start;
        FastStrip.Finish := Strip.Finish;
    end;

    // we copy the Segments. These are "warts and all" and we can't do anything
    // about that. This FastBoard class or some other class must break segments
    // into smaller segments at the point where a segment crosses a strip,
    // because it is required that only segment end points may contact a strip.
    for i := 0 to Board.SegmentCount -1 do begin
        Segment := Board.Segments[i];
        FastSegment := AddNewSegment;
        FastSegment.Start_1000.X := Segment.X1_1000;
        FastSegment.Start_1000.Y := Segment.Y1_1000;
        FastSegment.Finish_1000.X := Segment.X2_1000;
        FastSegment.Finish_1000.Y := Segment.Y2_1000;
        FastSegment.Width_1000 := Segment.Width_1000;
    end;
end;

procedure TbeTracks.SaveToBoard(Board: TbrBoard);
var
    i : integer;
    RawStrip : TbrRawStrip;
    Track : TteTrack;
    Strip : TteStrip;
    Segment : TteSegment;
begin
    // at this point we might want to addd code to break segments that cross
    // strips, so that only segment ends contact strips

    Board.Clear;
    // the track editor only outputs Defined patterns, no matter what the
    // pattern type that was loaded
    Board.Pattern := ptDefined;

    // board rectangle
    Board.Height := FHeight;
    Board.Width := FWidth;

    for i := 0 to Count - 1 do begin
        Track := Items[i];

        if Track is TteStrip then begin
            Strip := TteStrip(Track);
            RawStrip := Board.CreateNewRawStrip;
            RawStrip.Start := Strip.Start;
            RawStrip.Finish := Strip.Finish;
        end

        // segments
        else begin
            Segment := TteSegment(Track);
            Board.AddSegment(
                Segment.Start_1000.X, Segment.Start_1000.Y,
                Segment.Finish_1000.X, Segment.Finish_1000.Y,
                Segment.Width_1000
            );
        end;
    end;

    // patterns must be prepared after loading
    Board.Prepare;
end;


// **********************************************
//                  DELETE BAD SEGMENTS
// **********************************************

procedure TbeTracks.DeleteBadSegments;
begin

(*
var
    i,j : integer;

    Track : TbeTrack;
    Segment : TteSegment;
    Strip : TteStrip;

    IntersectionCount : integer;

begin
    // unmark everything
    for i := 0 to List.Count - 1 do begin
        Items[i].Marked := False;
    end;

    // for every segment
    for i := 0 to Count - 1 do begin

        // identify a segment
        Track := Items[i];
        if not (Track is TteSegment) then begin
            continue;
        end;
        Segment := TteSegment( Track );

        IntersectionCount := 0;

        // for every strip
        for j := 0 to Count -1  do begin

            // identify a strip
            Track := Items[i];
            if not( Track is TteStrip ) then begin
                continue;
            end;
            Strip := TteStrip( Track );

            // now see if this track and strip intersect

            // if they don't intersect, continue
            // continue;

            // is segment too wide?
            if Segment.Width_1000 > 500 then begin
                Segment.Marked := True;
                continue;
            end;

            // do we have too many intersectins?
             Inc( IntersectionCount );
             if IntersectionCount > 2 then begin
                Segment.Marked := True;
                continue;
             end;

            // is intersection point not at a cell center?



        end;
    end;

    // delete all the marked Segments
    for i := Count - 1 downto 0 do begin

        Track := Items[i];
        if Track.Marked then begin
            DeleteItem( Track );
        end;
    end;

*)






{
    for every segment

        for every strip

            if segment and strip intersect
                ++intersection_count for this segment

                if intersection_count  > 2 then
                    delete segment

                if SegmentWidth > 0.5 then
                    delete segment


                if intersection point is not at a cell center, then error
      [ie. Line to point distance from segment to circle centre distance > 0.5]
                    delete segment

             endif

        endfor
    endfor



  Note: We don't care if a segment does not actually end when it meets a
  strip - we just care that it passes through a cell circle, and that it
  intersects with only two strips.

  Define "passes through a cell circle" as
    1. Segment width <= track width [ie. 0.5 cells]
    2. Line to point distance from segment to circle centre distance <= 0.5


    function DeleteBadSegments : string;
}

end;

// *****************************************************
//                TbeTracksMemento
// *****************************************************

Procedure TbeTracksMemento.Undo;
begin
    case Operation of
      // reverse an add operation by taking item out of container
      opAdd: begin
          Tracks.FItems.Extract(Track);
      end;

      // reverse a remove operation by returning item to container
      opRemove: begin
          Track.Selected := True;
          Tracks.FItems.Add(Track);
      end;
    end;
end;

Procedure TbeTracksMemento.Redo;
begin
    case Operation of
      // redo an add operation that was previously UNDONE by returning
      // item to container
      opAdd: begin
          Track.Selected := True;
          Tracks.FItems.Add(Track);
      end;

      // redo a remove operation by that was previously UNDONE by removing
      // the item once again
      opRemove: begin
          Tracks.FItems.Extract(Track);
      end;
    end;
end;

Procedure TbeTracksMemento.DiscardUndo;
begin
    case Operation of
      // throw away the Undo record for an Add Item by leaving the item
      // in the Tracks container
      opAdd: begin
      end;

      // throw away the Undo record for a Remove Item
      // by deleting the item that is owned by this Memento
      opRemove: begin
          Track.Free;
      end;
    end;
    // always dispose of this unwanted Memento
    Free;
end;

Procedure TbeTracksMemento.DiscardRedo;
begin
    case Operation of
      // throw away the Redo record for an Add Item operation that was
      // previously UNDONE - delete the item owned by this Memento
      opAdd: begin
          Track.Free;
      end;

      // throw away the Redo record for a Remove Item operation that was
      // previously UNDONE - leave the item with its owning Tracks container
      opRemove: begin
      end;
    end;
    // always dispose of this unwanted Memento
    Free;
end;


end.
