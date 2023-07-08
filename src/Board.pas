unit Board;

interface

uses Graphics, Types {TPoint}, ManagedItem, Contnrs, Classes;

// ******************************************************************************
//  TbrBoard class describes board dimensions, tracks and interconnectons
// ******************************************************************************
{
    strip : horizontal or vertical copper between start and finish cell coords.
    segment : copper between any two 1/1000th cell coo-ords, any angle,
        any width. Used on SMD or special boards.

    HOW TO USE TbrBoard Class

    // perform 1-3 in any order
    1. Set Pattern.
    2. Set Height
    3. Set Width
    // then perform 5
    5. If Pattern is ptDefined do 5a,5b,5c
    5a.  Call Clear() to remove old tracks, segments and holes
    5b. Call CreateNewRawStrip for each new strip
    5c. Call AddSegment
    // then always perform 6,
    6. Call Prepare() to make board ready. Subsequent calls of Prepare() have no
        effect unless at least one of Pattern/Height/Width/Clear
        have been altered. Prepare() sets the variable Prepared, while
        Pattern/Height/Width/Clear clear it.
}

const
    TbrBoardMAXWIDTH = 300;
    TbrBoardMINWIDTH = 5;
    TbrBoardMAXHEIGHT = 75;
    TbrBoardMINHEIGHT = 5;
    TbrBoardDEFAULTWIDTH = 25;
    TbrBoardDEFAULTHEIGHT = 34;

  // access a single strip or *electrically interconnected by copper* group of strips
// All strips in a StripGroup are
type TbrRawStrip = class
  public
    Start : TPoint;     // first cell in straignt strip
    Finish : TPoint;    // last cell in straight strip
end;

// Describe a straight line segment start, end, width, in 1/1000 of a cell.
// These segments are not assessed for connectivity, just drawn so the board
// will "look right" to the user.
type
  TbrSegmentGroup = class;

TbrSegment = class( TManagedItem )
  public
    X1_1000 : integer;
    Y1_1000 : integer;
    X2_1000 : integer;
    Y2_1000 : integer;
    Width_1000: integer;
    Group : TbrSegmentGroup;
    TrackIntersection : array[0..1] of TPoint;
end;

// Segment groups contain segments that are electrically connected.
// A segment group does not continue where it crosses. Contains a list of
// *references* to TbrSegments - does not destroy any TbrSegments

TbrSegmentGroup = class( TManagedItem )
  private
    FSegments : TList;
    function GetSegment( i : integer ) : TbrSegment;
    function GetCount : integer;
  public
    property Segments[i : integer] : TbrSegment read GetSegment;
    property Count : integer read GetCount;
    procedure Clear;
    procedure AddSegment( Segment : TbrSegment );
    constructor Create; override;
    destructor Destroy; override;
end;

// ******************************
//          Strips
// ******************************

// Strips are Straight Copper with no intersectionsExcept at ends
type TbrDirection = ( diHorizontal, diVertical );


type TbrStrip = class( TManagedItem )
public
    Start : TPoint;     // first cell in straignt strip
    Finish : TPoint;    // last cell in straight strip
    Scanned : boolean;
    Direction : TbrDirection;
end;

// ******************************
//          StripGroups
// ******************************

// StripGroups are electrically connected strips

type TbrStripGroup = class( TManagedItem )
  private
    FStrips : TList;
    function GetStrip( i : integer ) : TbrStrip;
    function GetCount : integer;
  public
    property Strips[i : integer] : TbrStrip read GetStrip;
    property Count : integer read GetCount;
    procedure Clear;
    procedure AddStrip( Strip : TbrStrip );
    constructor Create; override;
    destructor Destroy; override;
end;

// cell contains references of up to 4 RawStrips that can intersect at that point
const STRIPS_PER_CELL = 4;
type TbrRawCell = record
    Count : integer;                  // number of RawStrips
    RawStrips : array[0..STRIPS_PER_CELL -1] of TbrRawStrip; // references to strips
end;
PbrRawCell = ^TbrRawCell;

// cell contains references of up to 4 Strips that can intersect at that point
type TbrCell = record
    Count : integer;                  // number of strips
    Strips : array[0..STRIPS_PER_CELL -1] of TbrStrip; // references to strips
end;


type TbrPattern = ( ptStrip, ptDonut, ptTripad, ptDefined );

type TbrBoard = class

  protected
    // StripGroups
    FRawStrips : TObjectList;
    FRawStripCount : integer;

    FStrips : TManagedList;
    FStripGroups : TManagedList;

    // segments
    FSegments : TManagedList;

    // segment groups
    FSegmentGroups : TManagedList;

    // strip pattern
    FPattern : TbrPattern;

    // object state - have we yet generated Strips from RawStrips
    Prepared : boolean;

    // board dimensions
    FHeight : integer;
    FWidth : integer;

    // drawing settings
    FPixelsPerCell : integer;
    FBoardColor : TColor;
    FStripColor : TColor;
    FStripWidth1000 : integer;
    FStripsVisible : boolean;
    FHolesVisible : boolean;

    // event handler
    FOnChangePattern : TNotifyEvent;

    procedure ClearSegmentGroups;
    function AddSegmentGroup : TbrSegmentGroup;

    procedure MakeBuiltInPattern;
    procedure DeleteRawStrip( index : integer );
    procedure ClearRawStrips;
    procedure ClearSegments;
    procedure ClearStrips;

    // properties
    function GetRawStrip(i : integer) : TbrRawStrip;

    function GetSegmentCount : integer;
    function GetSegment(i : integer ) : TbrSegment;

    function GetStripCount : integer;
    function GetStrip(i : integer) : TbrStrip;

    function GetStripGroupCount : integer;
    function GetStripGroup( i : integer ) : TbrStripGroup;

    function GetSegmentGroupCount : integer;
    function GetSegmentGroup( i : integer ) : TbrSegmentGroup;

    procedure SetPattern( APattern : TbrPattern );
    procedure SetHeight( AHeight : integer );
    procedure SetWidth( AWidth : integer );

    function MeasureDefinedPatternRect : TRect;

    procedure ConvertDiagonalRawStripsToSegments;
    procedure NormaliseRawStripCoordinates;
    procedure CleanRawStrips;

    procedure GenerateStrips;
    procedure GenerateStripGroups;

    procedure ConnectSegmentsToStrips;
    procedure GenerateSegmentGroups;


  public
    Cells : array of array of TbrCell;

    // raw strips are those defined in the project file
    property RawStripCount : integer read FRawStripCount;
    property RawStrips[i : integer] : TbrRawStrip read GetRawStrip;
    function CreateNewRawStrip : TbrRawStrip;

    // segments are conductors defined in the project file
    property SegmentCount : integer read GetSegmentCount;
    property Segments[i : integer] : TbrSegment read GetSegment;
    procedure AddSegment( X1_1000, Y1_1000, X2_1000, Y2_1000, Width_1000 : integer );

    // track pattern type
    property Pattern : TbrPattern read FPattern write SetPattern;

    property OnChangePattern : TNotifyEvent read FOnChangePattern write FOnChangePattern;

    // strips are straight conductors, pierced with holes. A strip can only
    // intersect with another strip at its start or end points. The strip is the
    // the primitive from which the track pattern is made up.

    // By contrast, the RawStrip is the type of strip defined in the project
    // file, which can intersect other strips at any point along the length.

    // Strips are calculated from RawStrips and present a "pre-digested" view
    // of a track pattern made of simple segments with a start and end point.
    //    property Strips[i : integer] : read GetTrack;

    property StripCount : integer read GetStripCount;
    property Strips[i : integer] : TbrStrip read GetStrip;

    property StripGroupCount : integer read GetStripGroupCount;
    property StripGroups[i : integer] : TbrStripGroup read GetStripGroup;

    // Segment groups are electrically connected segments
    property SegmentGroupCount : integer read GetSegmentGroupCount;
    property SegmentGroups[i : integer] : TbrSegmentGroup read GetSegmentGroup;

    // dimensions
    property Height : integer read FHeight write FHeight;
    property Width : integer read FWidth write FWidth;

    procedure LoadFromBoard( Source : TbrBoard );

    procedure Clear;
    procedure Prepare;

    constructor Create;
    destructor Destroy; override;
end;



implementation

uses SysUtils, Math, CopperTrace, ExceptSafe
{$IFDEF TIMING}
,Windows
{$ENDIF}
;

type ETbrBoard = class( Exception );
     ESafeTbrBoard = class( ESafe );

{ *************** TbrBoard *************** }

// ******************************
//          StripGroups
// ******************************

// StripGroups are electrically connected strips
// StripGroup holds only references to strips, does not own or destroy them

procedure TbrStripGroup.Clear;
begin
    FStrips.Count := 0;
end;

procedure TbrStripGroup.AddStrip( Strip : TbrStrip );
begin
    FStrips.Add( Strip );
end;

function TbrStripGroup.GetStrip( i : integer ) : TbrStrip;
begin
    if (i < 0) or (i>=Count) then begin
        raise ERangeError.Create( 'StripGroup index out of range' );
    end;
    result := TbrStrip( FStrips[i] );
end;

function TbrStripGroup.GetCount : integer;
begin
    result := FStrips.Count;
end;

constructor TbrStripGroup.Create;
begin
    inherited;
    FStrips := TList.Create;
end;

destructor TbrStripGroup.Destroy;
begin
    FStrips.Free;
    inherited;
end;

// ******************************
//          SegmentGroup
// ******************************

// A Segment group contains segments that are electrically connected.
// A segment group does not continue where it crosses over a track - it
// breaks into two, or an error condition exists.

procedure TbrSegmentGroup.Clear;
begin
    FSegments.Count := 0;
end;

procedure TbrSegmentGroup.AddSegment( Segment : TbrSegment );
begin
    FSegments.Add( Segment );
end;

function TbrSegmentGroup.GetSegment( i : integer ) : TbrSegment;
begin
    if (i < 0) or (i>=Count) then begin
        raise ERangeError.Create( 'SegmentGroup index out of range' );
    end;
    result := TbrSegment( FSegments[i] );
end;

function TbrSegmentGroup.GetCount : integer;
begin
    result := FSegments.Count;
end;

constructor TbrSegmentGroup.Create;
begin
    inherited;
    FSegments := TList.Create;
end;

destructor TbrSegmentGroup.Destroy;
begin
    FSegments.Free;
    inherited;
end;


{ *************** TbrBoard *************** }

// ******************************************
//           CREATE, DESTROY
// ******************************************
constructor TbrBoard.Create;
begin
    FRawStrips := TObjectList.Create;
    FSegments := TManagedList.Create;
    FSegmentGroups := TManagedList.Create;
    FStrips := TManagedList.Create;
    FStripGroups := TManagedList.Create;

    FStripColor := $E0E0E0; //clLtGray;
    FBoardColor := $DFFFF8; //clWhite;
    Pattern := ptStrip;
end;

destructor TbrBoard.Destroy;
begin
    FRawStrips.Free;
    FSegments.Free;
    FSegmentGroups.Free;
    FStrips.Free;
    FStripGroups.Free;
    inherited;
end;

// ******************************************
//          PROPERTY FUNCTIONS
// ******************************************

procedure TbrBoard.SetPattern( APattern : TbrPattern );
begin
    FPattern := APattern;
    Prepared := False;

    if Assigned( FOnChangePattern ) then begin
        FOnChangePattern( self );
    end;
end;

procedure TbrBoard.SetHeight( AHeight : integer );
begin
    if AHeight > TbrBoardMAXHEIGHT then begin
        AHeight := TbrBoardMAXHEIGHT;
    end
    else if AHeight < TbrBoardMINHEIGHT then begin
        AHeight := TbrBoardMINHEIGHT
    end;
    FHeight := AHeight;
    Prepared := False;
end;

procedure TbrBoard.SetWidth( AWidth : integer );
begin
    if AWidth > TbrBoardMAXWIDTH then begin
        AWidth := TbrBoardMAXWIDTH;
    end
    else if AWidth < TbrBoardMINWIDTH then begin
        AWidth := TbrBoardMINWIDTH;
    end;
    FWidth := AWidth;
    Prepared := False;
end;


function TbrBoard.GetRawStrip(i: integer): TbrRawStrip;
begin
    result := TbrRawStrip( FRawStrips[i] );
end;

// ******************************************
//               RAW STRIPS
// ******************************************

procedure TbrBoard.ClearRawStrips;
begin
    FRawStripCount := 0;
    FRawStrips.Count := 0;
end;

function TbrBoard.CreateNewRawStrip: TbrRawStrip;
begin
    // if non in reserve, then make new strip
    if FRawStripCount >= FRawStrips.Count then begin
        result := TbrRawStrip.Create;
        FRawStrips.Add( result );
    end
    // else use cached strips
    else begin
        result := TbrRawStrip( FRawStrips[FRawStripCount] );
    end;
    Inc( FRawStripCount );
end;

procedure TbrBoard.DeleteRawStrip( index : integer );
begin
    FRawStrips.Move( index, FRawStripCount -1 );
    Dec( FRawStripCount );
end;

// ******************************************
//                  SEGMENTS
// ******************************************

procedure TbrBoard.ClearSegments;
begin
    FSegments.Clear;
end;

function TbrBoard.GetSegmentCount : integer;
begin
    result := FSegments.Count;
end;


function TbrBoard.GetSegment(i : integer ) : TbrSegment;
begin
    result := TbrSegment( FSegments[i] );
end;

// Segments are drawn straigh lines of defined width,l in track color
// They are drawn for appearance only, and have no effect on connectivity

procedure TbrBoard.AddSegment(X1_1000, Y1_1000, X2_1000, Y2_1000,
  Width_1000: integer);
var
    Segment : TbrSegment;
begin
    Segment := TbrSegment(FSegments.AddNew(TbrSegment));
    Segment.X1_1000 := X1_1000;
    Segment.Y1_1000 := Y1_1000;
    Segment.X2_1000 := X2_1000;
    Segment.Y2_1000 := Y2_1000;
    Segment.Width_1000 := Width_1000;
end;

// ******************************************
//              SEGMENT GROUPS
// ******************************************

function TbrBoard.GetSegmentGroupCount : integer;
begin
    result := FSegmentGroups.Count;
end;

function TbrBoard.GetSegmentGroup( i : integer ) : TbrSegmentGroup;
begin
    result := TbrSegmentGroup(FSegmentGroups[i]);
end;

procedure TbrBoard.ClearSegmentGroups;
begin
    FSegmentGroups.Clear;
end;

function TbrBoard.AddSegmentGroup : TbrSegmentGroup;
begin
      result := TbrSegmentGroup( FSegmentGroups.AddNew( TbrSegmentGroup ));
      result.Clear;
end;


// ******************************************
//                  STRIPS
// ******************************************

function TbrBoard.GetStripCount : integer;
begin
    result := FStrips.Count;
end;

function TbrBoard.GetStrip(i : integer) : TbrStrip;
begin
    result := TbrStrip(FStrips[i]);
end;

// ******************************************
//    GENERATE BUILT-IN STRIPBOARD PATTERN
// ******************************************

procedure TbrBoard.MakeBuiltInPattern;
var
    y : integer;
    x: Integer;
    Strip : TbrRawStrip;
begin
    // ptStrip stripboard pattern is handled here.
    if Pattern = ptStrip then begin

        // Strip pattern is generated from inside this class
        // create standard horizontal Stripboard pattern
        for y := 0 to FHeight - 1 do begin
            // each stripgroup holds a single strip
            Strip := CreateNewRawStrip;
            Strip.Start.X := 0;
            Strip.Start.Y := y;
            Strip.Finish.X := FWidth -1;
            Strip.Finish.Y := y;
        end;
    end

    // ptDonut pattern is handled here.
    else if Pattern = ptDonut then begin

        // put a donut on every cell
        for y := 0 to FHeight -1 do begin
            for x := 0 to FWidth - 1 do begin
                // each stripgroup holds a single strip
                Strip := CreateNewRawStrip;
                Strip.Start.X := x;
                Strip.Start.Y := y;
                Strip.Finish.X := x;
                Strip.Finish.Y := y;
            end;
        end;
    end

    // tripad pattern is handled here
    else if Pattern = ptTripad then begin

{
        // draw tripad strips -  only integral 3 wide strips
        for y := 0 to FHeight -1 do begin
            for x := 0 to (FWidth div 3) - 1 do begin
                // each stripgroup holds a single strip
                Strip := CreateNewRawStrip;
                Strip.Start.X := x * 3;
                Strip.Start.Y := y;
                Strip.Finish.X := (x * 3) + 2;
                Strip.Finish.Y := y;
            end;
        end;
}
        // draw tripad strips - 1, 2 or 3 wide strip at extreme right
        // for every line
        for y := 0 to FHeight - 1 do begin

            // draw 3 wide strips
            x := 0;
            while x < FWidth do begin

                Strip := CreateNewRawStrip;
                Strip.Start.X := x;
                Strip.Start.Y := y;
                Strip.Finish.X := Min( x + 2, FWidth -1 );
                Strip.Finish.Y := y;

                // to next tri-wide strip
                Inc( x, 3 );
            end;
        end;
    end;
end;

// ***************************************************
//      FIND RECTANGLE ENCLOSING DEFINED PATTERN
// ***************************************************

function TbrBoard.MeasureDefinedPatternRect : TRect;
var
    MinTop, MaxBottom, MinLeft, MaxRight : integer;
    i : integer;
    RawStrip : TbrRawStrip;
    Segment : TbrSegment;
begin

    // if we have no strips and no segments, the track search algorithm
    // will return nonsense, so weed that out first and return a fake
    // 1 cell rectangle
    if (RawStripCount = 0) and (SegmentCount = 0) then begin
        result := Rect( 0, 0, 1, 1 );
        exit;
    end;

    MinTop := High( MinTop );
    MaxBottom := Low( MaxBottom );
    MinLeft := High( MinLeft );
    MaxRight := Low( MaxRight );

    // find extreme cell x and y values of any strip
    for i := 0 to RawStripCount - 1 do begin
        RawStrip := RawStrips[i];
        MinTop := Min( RawStrip.Start.Y, MinTop );
        MinTop := Min( RawStrip.Finish.Y, MinTop );
        MaxBottom := Max( RawStrip.Start.Y, MaxBottom );
        MaxBottom := Max( RawStrip.Finish.Y, MaxBottom );
        MinLeft := Min( RawStrip.Start.X, MinLeft );
        MinLeft := Min( RawStrip.Finish.X, MinLeft );
        MaxRight := Max( RawStrip.Start.X, MaxRight );
        MaxRight := Max( RawStrip.Finish.X, MaxRight );
    end;

    // find extreme cellx and y values of any segment
    for i := 0 to SegmentCount - 1 do begin
        Segment := Segments[i];
        MinTop := Min( (Segment.Y1_1000 - Segment.Width_1000) div 1000, MinTop );
        MinTop := Min( (Segment.Y2_1000 - Segment.Width_1000) div 1000, MinTop );
        MaxBottom := Max( (Segment.Y1_1000 + Segment.Width_1000) div 1000, MaxBottom );
        MaxBottom := Max( (Segment.Y2_1000 + Segment.Width_1000) div 1000, MaxBottom );
        MinLeft := Min( (Segment.X1_1000 - Segment.Width_1000) div 1000, MinLeft );
        MinLeft := Min( (Segment.X2_1000 - Segment.Width_1000) div 1000, MinLeft );
        MaxRight := Max( (Segment.X1_1000 + Segment.Width_1000) div 1000, MaxRight );
        MaxRight := Max( (Segment.X2_1000 + Segment.Width_1000) div 1000, MaxRight );
    end;
    // return bounding rectangle
    result :=Rect( MinLeft, MinTop, MaxRight +1, MaxBottom +1 );
end;


// ***************************************************
//          CONVERT DIAGONAL STRIPS TO SEGMENTS
// ***************************************************

procedure TbrBoard.ConvertDiagonalRawStripsToSegments;
var
    i : integer;
    RawStrip : TbrRawStrip;
begin
    for i := RawStripCount - 1 downto 0 do begin

        RawStrip := TbrRawStrip( FRawStrips[i] );

        // if strip is diagonal, convert it to a segment
        if (RawStrip.Start.X <> RawStrip.Finish.X) and
          (RawStrip.Start.Y <> RawStrip.FInish.Y) then begin

            AddSegment(
                RawStrip.Start.X * 1000, RawStrip.Start.Y * 1000,
                RawStrip.Finish.X * 1000, RawStrip.Finish.Y * 1000,
                350 );

            DeleteRawStrip( i );
        end;
    end;
end;


// ***************************************************
//           NORMALISE RAW STRIP COORD PAIRS
// ***************************************************

 // get Strip.Start as (left, top), Strip.Finish as (right, bottom).
 // That is standard representation throughout VeeCAD

procedure TbrBoard.NormaliseRawStripCoordinates;
var
    i : integer;
    Strip : TbrRawStrip;
    left, top, right, bottom : integer;
begin
    // get start as (left, top), finish as (right, bottom). That is standard
    // representation throughout VeeCAD
    for i := 0 to RawStripCount -1 do begin
        Strip := RawStrips[i];

        // find left, top, right, bottom extremes of coord pairs
        left := min( Strip.Start.X, Strip.Finish.X );
        top := min( Strip.Start.Y, Strip.Finish.Y );
        right := max( Strip.Start.X, Strip.Finish.X );
        bottom := max( Strip.Start.Y, Strip.Finish.Y );

        // put normalised coords back in strip
        Strip.Start.X := left;
        Strip.Start.Y := top;
        Strip.Finish.X := right;
        Strip.Finish.Y := bottom;
    end;
end;


// ***************************************************
//           REMOVE DUPLICATE TRACK SECTIONS
// ***************************************************

procedure TbrBoard.CleanRawStrips;

    // find length of a strip in cell units
    function StripLength( Strip : TbrRawStrip ) : integer;
    begin
        // all strips are vertical or horizontal - non are angled, so just
        // add X and Y lengths, since one must be zero
        result :=
            abs( Strip.Start.X - Strip.Finish.X ) +
            abs( Strip.Start.Y - Strip.FiniSh.Y );
       end;

    // if strips are co-linear and overlap, then combine strips to form a single
    // and return True. Integrates StripB into StripA.
    function CombineStrips( StripA, StripB : TbrRawStrip ) : boolean;
    var
        LeftA, RightA : integer;
        LeftB, RightB : integer;
        TopA, BottomA : integer;
        TopB, BottomB : integer;

    begin
        result := False;

        // if both strips horizontal and co-linear
        if (StripA.Start.Y = StripA.Finish.Y) and
            (StripA.Start.Y = StripB.Start.Y) and
            (StripA.Start.Y = StripB.Finish.Y) then begin

            // get left, right X values of StripA, StripB
            LeftA := StripA.Start.X;
            RightA := StripA.Finish.X;

            LeftB := StripB.Start.X;
            RightB := StripB.Finish.X;

            // if strips overlap
            if ((LeftA <= RightB) and (RightA >= LeftB)) or
                ((LeftB <= RightA) and (RightB >= LeftA)) then begin
                result := True;
                StripA.Start.X := Min(LeftA, LeftB);
                StripA.Finish.X := Max(RightA, RightB);
            end;
        end

        // if both strips vertical and co-linear
        else if (StripA.Start.X = StripA.Finish.X) and
                (StripA.Start.X = StripB.Start.X) and
                (StripA.Start.X = StripB.Finish.X) then begin

            // get top, bottom X values of StripA, StripB
            TopA := StripA.Start.Y;
            BottomA := StripA.Finish.Y;

            TopB := StripB.Start.Y;
            BottomB := StripB.Finish.Y;

            // if strips overlap
            if ((TopA <= TopB) and (BottomA >= TopB)) or
               ((TopB <= TopA) and (BottomB >= TopA)) then begin
                result := True;
                StripA.Start.Y := Min(TopA, TopB);
                StripA.Finish.Y := Max(BottomA, BottomB);
            end;
        end;
    end;

var
    i : integer;
    Strip : TbrRawStrip;
    j : integer;
    Strip1 : TbrRawStrip;
    JoinMade : boolean;
label
    loop;
begin
    JoinMade := True;
    while JoinMade do begin

        JoinMade := False;

        // for every strip (except last strip)
        for i := 0 to RawStripCount -2 do begin
            Strip := RawStrips[i];

            // for every strip further down the list
            for j := i+1 to RawStripCount - 1 do begin

                    Strip1 := RawStrips[j];

                // if strips are co-linear and overlap, combine the strips and
                // delete the shorter of the two. Strips are combined into Strip
                if CombineStrips( Strip, Strip1 ) then begin

                    // delete Strip1 - no longer needed
                    DeleteRawStrip( j );

                    // now start joining procedure again
                    JoinMade := True;
                    goto loop;
                end;
            end;
        end;
loop:
    end;
end;


// ***************************************************
//           GENERATE DATA FOR STRIPS PROPERTY
// ***************************************************
{
    Strips property presents straight tracks, pierced with holes, that
    only overlap (intersect) other tracks at the ends.

    Cells property presents.

}
procedure TbrBoard.GenerateStrips;

var
    // address this as Cells[x,y] where 0 <= x < width and 0 <= y < height
    // This is a dynamic array directly exposed. Copy it by defining a dynamic
    // array with
    // CellsCopy = Board.Cells;             // accesses same data as Board.Cells
    // SetLength(CellsCopy, width,height);  // SetLength forces a copy to be made
    RawCells : array of array of TbrRawCell;

    procedure RecordStripAt( x, y : integer; strip : TbrRawStrip );
    begin
        // does this strips lie (at least partly) outside board area ?
        if (x < 0) or (x >= FWidth) or (y < 0) or (y >= FHeight) then begin
            raise ESafeTbrBoard.CreateFmt(
                'Strip (%d,%d)-(%d,%d) contains point (%d,%d) outside board area',
                [strip.Start.X, strip.Start.Y, strip.Finish.X, strip.Finish.Y, x, y] );
        end;

        // do we have room for another strip ?
        if RawCells[x, y].Count >= STRIPS_PER_CELL then begin
            raise ETbrBoard.CreateFmt(
                'Internal Error: Adding strip (%d,%d)-(%d,%d), causes more than ' +
                '%d strips to cross at (%d,%d)',
                [strip.Start.X, strip.Start.Y, strip.Finish.X, strip.Finish.Y,
                STRIPS_PER_CELL, x, y] );
        end;

        // record this strip in next available space
        RawCells[x, y].RawStrips[RawCells[x, y].Count] := strip;

        // count shows additional strip
        Inc( RawCells[x, y].Count );
    end;

var
    i : integer;
    RawStrip : TbrRawStrip;
    Strip : TbrStrip;
    x, y: Integer;
    CellStripCount : integer;

    StartY, FinishY : integer;
    StartX, FinishX : integer;

    ScanX, ScanY : integer;
    RawFinish : TPoint;

begin
    // draw all RawStrips on an array of cells
    SetLength( RawCells, FWidth, FHeight );

    // no strips to start with
    for x := 0 to FWidth -1 do begin
        for y := 0 to FHeight -1 do begin
            RawCells[x,y].Count := 0;
        end;
    end;

    // mark all cells crossed by a RawStrip
    for i := RawStripCount -1 downto 0 do begin

        RawStrip := TbrRawStrip( FRawStrips[i] );

        // strip is either horizontal or vertical
        // ..if horizontal
        if RawStrip.Start.Y = RawStrip.Finish.Y then begin
            StartX := Min( RawStrip.Start.X, RawStrip.Finish.X );
            FinishX := Max( RawStrip.Start.X, RawStrip.Finish.X );
            Y := RawStrip.Start.Y;
            for X := StartX to FinishX do begin
                 RecordStripAt( X, Y , RawStrip );
             end;
        end

        // ..else vertical
        else if RawStrip.Start.X = RawStrip.Finish.X then begin
             StartY := Min( RawStrip.Start.Y, RawStrip.Finish.Y );
             FinishY := Max( RawStrip.Start.Y, RawStrip.Finish.Y );
             X := RawStrip.Start.X;
             for Y := StartY to FinishY do begin
                 RecordStripAt( X, Y , RawStrip );
             end;
        end

        // ..else strip is diagonal - should be detected earlier!
        else begin
            raise ETbrBoard.Create(
                'Internal error: GenerateStrips() received diagonal strip' );
        end;
    end;

    // Add strips as TbrStrip objects to the FStrips[] managed item list.
    // strips are created by cutting up RawStrips - we cut whenever another
    // strip crosses our strip. We use RawCells[][] to detect multiple strips
    // but we will discard RawCells on exit from this function.
    for i := 0 to RawStripCount - 1 do begin

        RawStrip := TbrRawStrip( FRawStrips[i] );

        // strip is either horizontal or vertical . .

        // if horizontal
        if RawStrip.Start.Y = RawStrip.Finish.Y then begin

            // work out start, finish coords of raw strip, working left to right
            ScanX := Min( RawStrip.Start.X, RawStrip.Finish.X );
            ScanY := RawStrip.Start.Y;

            RawFinish.X := Max( RawStrip.Start.X, RawStrip.Finish.X );
            RawFinish.Y := ScanY;

            // create TbrStrip objects up to end of RawStrip
            repeat
                // Create a strip.
                Strip := TbrStrip(FStrips.AddNew( TbrStrip ));
                Strip.Start := Point( ScanX, ScanY );
                Strip.Finish := RawFinish;
                Strip.Direction := diHorizontal;

                // Scan along raw strip until it is terminated by another
                // strip intersecting, or reaches its natural end.
                // Start scanning on adjacent cell to right of start cell
                Inc( ScanX );
                while( ScanX < RawFinish.X ) do begin

                    // did we intersect with another strip?
                    CellStripCount := RawCells[ScanX, ScanY].Count;
                    if CellStripCount > 1 then begin
                        // intersected another strip - truncate our strip so
                        // its last cell is the intersection cell
                        Strip.Finish.X := ScanX;
                        break;
                    end

                    // how can there be no strips when we are tracing along a RawStrip!
                    // Internal inconsistency error!
                    else if CellStripCount < 1 then begin
                        raise ETbrBoard.CreateFmt(
                            'Internal Errror: Cell record should show at least one strip at (%d,%d)',
                            [ ScanX, ScanY ]
                        );
                    end;

                    Inc( ScanX );
                end;
           until ( ScanX >= RawFinish.X );

        end

        // else vertical

        else if RawStrip.Start.X = RawStrip.Finish.X then begin

            // work out start, finish coords of raw strip, working top to bottom
            ScanY := Min( RawStrip.Start.Y, RawStrip.Finish.Y );
            ScanX := RawStrip.Start.X;
            RawFinish.Y := Max( RawStrip.Start.Y, RawStrip.Finish.Y );
            RawFinish.X := ScanX;

            // create new strips up to end of RawStrip
            repeat
                Strip := TbrStrip(FStrips.AddNew( TbrStrip ));
                Strip.Start := Point( ScanX, ScanY );
                Strip.Finish := RawFinish;
                Strip.Direction := diVertical;

                // Create a strip.
                // Scan along raw strip until it is terminated by another
                // strip intersecting, or reaches its natural end.
                // Start scanning on adjacent cell to right of start cell
                Inc( ScanY );
                while( ScanY < RawFinish.Y ) do begin

                    // did we intersect with another strip?
                    CellStripCount := RawCells[ScanX, ScanY].Count;
                    if CellStripCount > 1 then begin
                        // intersected another strip - truncate our strip so
                        // its last cell is the intersection cell
                        Strip.Finish.Y := ScanY;
                        break;
                    end

                    // how can there be no strips when we are tracing along a RawStrip!
                    // Internal inconsistency error!
                    else if CellStripCount < 1 then begin
                        raise ETbrBoard.CreateFmt(
                            'Internal Error: Cell record should show at least one strip at (%d,%d)',
                            [ ScanX, ScanY ]
                        );
                    end;

                    Inc( ScanY );
                end;
            until ( ScanY >= RawFinish.Y );

        end

        // else strip is diagonal - not allowed
        else begin
            raise ETbrBoard.Create(
                'Internal error: GenerateStrips() received diagonal strip' );
        end;
     end;
end;

//*********************************************
//              STRIP GROUPS
//*********************************************

// Group electrically connected Strips into StripGroups.

function TbrBoard.GetStripGroupCount : integer;
begin
    result := FStripGroups.Count;
end;

function TbrBoard.GetStripGroup( i : integer ) : TbrStripGroup;
begin
    result := TbrStripGroup( FStripGroups[i] );
end;

procedure TbrBoard.ClearStrips;
begin
    FStripGroups.Clear;
    FStrips.Clear;
end;


// This function operates on the data that is contained in the Strips and Cells
// data members

procedure TbrBoard.GenerateStripGroups;

type PTbrCell = ^TbrCell;

    // Given the coords of one end of a strip, trace any connected strips,
    // adding them to the StripGroup, and setting the Scanned member to true.
    procedure FollowStrip( StripGroup : TbrStripGroup; Strip : TbrStrip; Point : TPoint );
    var
        i : integer;
        PCell : PTbrCell;
        AStrip : TbrStrip;
    begin
        // look at Cells to find all connected strips
        PCell := @(Cells[Point.X, Point.Y]);

        // for each connected strip,
        for i := 0 to PCell^.Count - 1 do begin
            AStrip := PCell^.Strips[i];
            if AStrip.Scanned then begin
                continue;
            end;
            // process this strip..
            StripGroup.AddStrip( AStrip );
            // prevent recursive scanning of same strip due to a circular track
            // path. Also prevents re-scanning as we move down the Strips[]
            // list and encounter a strip that was connected to an earlier strip.
            AStrip.Scanned := True;
            // scan the other end
            if(AStrip.Start.X = Point.X) and (AStrip.Start.Y = Point.Y) then begin
                FollowStrip( StripGroup, AStrip, AStrip.Finish );
            end
            else begin
                FollowStrip( StripGroup, AStrip, AStrip.Start );
            end;
        end;
    end;

type TbrCell = record
    Count : integer;                  // number of strips
    Strips : array[0..STRIPS_PER_CELL -1] of TbrRawStrip; // references to strips
end;

var
    x, y : integer;
    i : integer;
    Strip : TbrStrip;
    StripGroup : TbrStripGroup;
    PCell : PTbrCell;
begin
    // sero cells first - cells is a public member of this class
    SetLength( Cells, Width, Height );
    for x := 0 to Width - 1 do begin
        for y := 0 to Height - 1 do begin
            Cells[x,y].Count := 0;
        end;
    end;

    // draw all Strips on an array of cells
    for i := 0 to StripCount - 1 do begin
        Strip := Strips[i];

        // record strip start
        if (Strip.Start.X >= Width) or (Strip.Start.Y >= Height) or
            (Strip.Finish.X >= Width) or (Strip.Finish.Y >= Height) then begin
            raise ETbrBoard.Create( 'Strip coords off board' );
        end;

        PCell := @Cells[Strip.Start.X,Strip.Start.Y];
        PCell^.Strips[PCell^.Count] := Strip;
        Inc( PCell^.Count );

        // record strip end
        PCell := @Cells[Strip.Finish.X,Strip.Finish.Y];
        PCell^.Strips[PCell^.Count] := Strip;
        Inc( PCell^.Count );
    end;

    // set all strips to not scanned
    for i := 0 to StripCount - 1 do begin
        Strips[i].Scanned := False;
    end;

    // put strips in StripGroups
    for i := 0 to StripCount - 1 do begin
        Strip := Strips[i];

        // if strip has not been included in a StripGroup - then start a
        // new StripGroup
        if not Strip.Scanned then begin
            // new stripgroup
            StripGroup := TbrStripGroup(FStripGroups.AddNew( TbrStripGroup ));
            // stripgroups get reused, so clear to remove earlier strip refs
            StripGroup.Clear;
            // first member of stripgroup
            StripGroup.AddStrip( Strip );
            // don't include this strip in the scan = prevents infinite
            // recursion on circular track
            Strip.Scanned := True;
            // follow both ends of our strip and add connected strips to
            // our stripgroup
            FollowStrip( StripGroup, Strip, Strip.Start );
            FollowStrip( StripGroup, Strip, Strip.Finish );
        end;
    end;
end;


// Record Cell Coords and Strip Refs of locations Where Segments
// Connect to Strips.

procedure TbrBoard.ConnectSegmentsToStrips;

// ************************
//      TbrSegment
// ************************

function SegmentFull( Segment : TbrSegment ) : boolean;
begin
    result := (Segment.TrackIntersection[1].X <> -1) and
        (Segment.TrackIntersection[0].X <> -1);
end;


    procedure RecordTrackIntersection( Segment : TbrSegment; x, y : integer );
    begin
        if Segment.TrackIntersection[0].X = -1 then begin
            Segment.TrackIntersection[0].X := x;
            Segment.TrackIntersection[0].Y := y;
        end
        else if Segment.TrackIntersection[1].X = -1 then begin
            Segment.TrackIntersection[1].X := x;
            Segment.TrackIntersection[1].Y := y;
        end
        else begin
            raise ETbrBoard.CreateFmt(
            'Segment (%d,%d), (%d,%d) contacts more than 2 strips',
            [Segment.X1_1000, Segment.Y1_1000, Segment.X2_1000, Segment.Y2_1000] );
        end;
    end;
var
    i : integer;
    Segment : TbrSegment;
    j : integer;
    Strip : TbrStrip;
    x, y : Integer;
    Connected : boolean;

label SegmentRemoved;

begin
    // blank out all segment-track intersection coords
    for i := 0 to SegmentCount - 1 do begin
        Segments[i].TrackIntersection[0].X := -1;
        Segments[i].TrackIntersection[1].X := -1;
    end;

    // for every segment
    for i  := SegmentCount -1 downto 0 do begin

        Segment := Segments[i];

        // for every strip
        for j := StripCount -1 downto 0 do begin

            Strip := Strips[j];

            if SegmentStripConnects( Segment, Strip ) then begin

                // will record when when connection is located
                Connected := False;

                // find point of intersection
                if Strip.Direction = diHorizontal then begin
                    y := Strip.Start.Y;
                    for x := Strip.Start.X  to Strip.Finish.X do begin
                        if SegmentToCell( Segment, Point(x,y) ) then begin
                            Connected := True;

                            // segment contacts too many strips?
                            if SegmentFull( Segment ) then begin
                                FSegments.Delete( i );
                                goto SegmentRemoved;
                            end
                            else begin
                                RecordTrackIntersection( Segment, x, y );
                            end;
                            // assume only one contact with this strip! and look
                            // no further
                            break;
                        end;
                    end;
                end
                // else strip vertical
                else begin
                    x := Strip.Start.X;
                    for y := Strip.Start.Y  to Strip.Finish.Y do begin
                        if SegmentToCell( Segment, Point(x,y) ) then begin
                            Connected := True;
                            // segment contacts too many strips?
                            if SegmentFull( Segment ) then begin
                                FSegments.Delete( i );
                                goto SegmentRemoved;
                            end
                            else begin
                                RecordTrackIntersection( Segment, x, y );
                            end;
                            // assume only one contact with this strip! and look
                            // no further
                            break;
                        end;
                    end;
                end;

                // if we did not contact at a cell circle, so must have contacted
                // part way between cell circles, and is thus invalid
                if not Connected then begin
                    FSegments.Delete( i );
                    goto SegmentRemoved;
                end;

            end;
        end;
        // break out of loops here
SegmentRemoved:

    end;
end;


// Group electrically connected segments into SegmentGroups and add to
// SegmentGroups[] array.

procedure TbrBoard.GenerateSegmentGroups;

    procedure CombineGroups( TotalGroup, Group : TbrSegmentGroup );
    var
        i : integer;
        Segment : TbrSegment;
    begin
        // look for bug here - group that is not in Groups[]
        if FSegmentGroups.IndexOf(Group) < 0 then begin
            asm nop end;
        end;

        // transfer Segments from Group to TotalGroup
        for i := 0 to Group.Count - 1 do begin
            Segment := Group.Segments[i];
            TotalGroup.AddSegment( Segment );
            Segment.Group := TotalGroup;
        end;

        // eliminate donor group
        FSegmentGroups.Delete( FSegmentGroups.IndexOf(Group) );
    end;

    // see if two segments meet at the same strip cell
    function SegmentsJoinAtStrip( Segment1, Segment2 : TbrSegment ) : boolean;
    var
        i, j: Integer;
        JoinX, JoinY : integer;
    begin
        for i := 0 to 1 do begin

            // ...(we reserve X = -1 to mean "no join"). Also, if
            // TrackIntersection[0].X = -1 then TrackIntersection[0].Y = -1 is
            // guaranteed, because we rocord joins starting from index [0] )

            // if segment1 makes a track join
            if Segment1.TrackIntersection[i].X >= 0 then begin

                JoinX := Segment1.TrackIntersection[i].X;
                JoinY := Segment1.TrackIntersection[i].Y;

                for j := 0 to 1 do begin

                    // if segment2 makes same track join
                    if (Segment2.TrackIntersection[j].X = JoinX) and
                    (Segment2.TrackIntersection[j].Y = JoinY) then begin
                        result := True;
                        exit;
                    end
                end;
             end
             // "optimisation"
             // if index[0] does not record a track join, then index[1] will
             // not record a track join
             else begin
                break;
             end;
        end;
        result := False;
    end;

var
    i : integer;
    Segment : TbrSegment;
    Group : TbrSegmentGroup;
    j: Integer;
    NewSegment : TbrSegment;
begin
    // remove any segment references from groups
    for i := 0 to SegmentCount - 1 do begin
        Segments[i].Group := nil;
    end;

    // for each segment
    for i := 0 to SegmentCount - 1 do begin

        Segment := Segments[i];

        // if segment does not have a group, give it one
        if Segment.Group = nil then begin
            Group := AddSegmentGroup;
            Group.AddSegment(Segment);
            Segment.Group := Group;
        end;

        // Go down the list and try to connect our segment to other segments.
        // We only try to join to segments later in the list, because segments
        // earlier in the list have already tried to join to all later segments
        for j := i+1 to SegmentCount - 1 do begin

            NewSegment := Segments[j];

            // try to connect this segment to other segment
            if SegmentsConnect( Segment, NewSegment ) then begin

                // if the two segments meet at the same cell on a strip -
                // don't join. A break could be placed on the strip and
                // our SegmentSet would no longer be valid. The SegmentSets
                // will be joined in Connective.pas
                if SegmentsJoinAtStrip( Segment, NewSegment ) then begin
//                    asm nop end;
                    continue;
                end;

                // if new segment has no group, include it
                if NewSegment.Group = nil then begin
                    Segment.Group.AddSegment(NewSegment);
                    NewSegment.Group := Segment.Group;
                end
                // else both segments have groups (not same group)- combine groups
                else if Segment.Group <> NewSegment.Group then begin
                    CombineGroups( Segment.Group, NewSegment.Group );
                end;
            end;
        end;
    end;

//    j := SegmentGroupCount;
end;

// ********************************************************
// ********************************************************
//              MAIN PUBLIC FUNCTIONS
// ********************************************************
// ********************************************************
// Clear, Prepare(), LoadFromBoard()

// ******************************************
//        CLEAR DEFINED STRIPS
// ******************************************

procedure TbrBoard.Clear;
begin
    ClearRawStrips;
    ClearSegments;
    ClearStrips;
    ClearSegmentGroups;
    // have not yet prepared by:
    // 1. making Strips and Stripsets form RawStrips
    // 2. making SegmentGroups from Segments
    Prepared := False;
end;


// ******************************************
//        PREPARE TBRBOARD STRIPS
// ******************************************

// After loading a defined pattern or switching to a built-in pattern,
// setting boards size or trackrect coords, call Prepare() to generate
// Strips[] and StripSets[] so board object is ready for use.

{$IFDEF TIMING}
var
    performancefreq : Int64;
    performanceCount1 : Int64;
    performanceCount2 : Int64;
    performance : single;
{$ENDIF}

// rationalise data ready for use
// Call After Creating Raw Strips, Segments
procedure TbrBoard.Prepare;
begin
{$IFDEF TIMING}
    QueryPerformanceFrequency( performancefreq );
    QueryPerformanceCounter( performanceCount1 );
{$ENDIF}

    // don't prepare twice, otherwise all strips duplicated!
    if not Prepared then begin

        // if zero size board, get out
        if (width <= 0) or (height <= 0) then begin
            raise ESafeTbrBoard.Create( 'Zero size board' );
        end;

        ClearStrips;

        // Defined (built-in) patterns are generated here
        // All other patterns are have Raw Strips and Segments that were defined
        // by the user.
        if Pattern <> ptDefined then begin
            // clear raw strips
            ClearRawStrips;
            ClearSegments;
            // make our own strips
            MakeBuiltInPattern;
        end;

        ConvertDiagonalRawStripsToSegments;
        NormaliseRawStripCoordinates;
        CleanRawStrips;
        GenerateStrips;
        GenerateStripGroups;
        ConnectSegmentsToStrips;
        GenerateSegmentGroups;
        Prepared := True;

{$IFDEF TIMING}
    QueryPerformanceCounter( performanceCount2 );
    Performance := (performanceCount2 - performanceCount1) / performancefreq;
    asm nop end;
{$ENDIF}

    end;
end;


// ******************************************
//     COPY FROM ANOTHER TBRBOARD OBJECT
// ******************************************

procedure TbrBoard.LoadFromBoard( Source : TbrBoard );
var
    i : integer;
    SourceStrip : TbrRawStrip;
    Strip : TbrRawStrip;
    SourceSegment : TbrSegment;
begin
    Clear;

    Pattern := Source.Pattern;

    // Standard patterns are generated in code inside this class - no need to
    // transfer strips, segments, holes. Leave board size unchanged.
    // However, Defined patterns have a fixed copper size
    if Pattern = ptDefined then begin

        // copy strips
        for i := 0 to Source.RawStripCount - 1 do begin
            SourceStrip := Source.RawStrips[i];
            Strip := CreateNewRawStrip;
            Strip.Start := SourceStrip.Start;
            Strip.Finish := SourceStrip.Finish;
        end;

        // copy segments
        for i := 0 to Source.SegmentCount - 1 do begin
            SourceSegment := Source.Segments[i];
            AddSegment(
                SourceSegment.X1_1000, SourceSegment.Y1_1000,
                SourceSegment.X2_1000, SourceSegment.Y2_1000,
                SourceSegment.Width_1000
            );
        end;

        //if necessary, expand board to fit entire pattern
        if FWidth < Source.Width then begin
            FWidth := Source.Width;
        end;
        if FHeight < Source.Height then begin
            FHeight := Source.Height;
        end;
    end;

    // rationalise data ready for use
    Prepare;
end;


end.
