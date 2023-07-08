unit BoardTracks;

interface

uses Windows,
    ManagedItem, Board;


// ************************************************************
//      SIMPLE ENCAPSULATION OF STRIPS & SEGMENTS ON A BOARD
// ************************************************************

type TbeFastStrip = class( TManagedItem )
  public
    Start : TPoint;     // first cell in straignt strip
    Finish : TPoint;    // last cell in straight strip
    Selected : boolean;
end;

type TbeFastSegment = class( TManagedItem )
  public
    Start_1000 : TPoint;
    Finish_1000 : TPoint;
    Width_1000: integer;
    Selected : boolean;
end;

type TbeTracks = class

  protected
    // property handlers
    FStrips : TManagedList;
    FSegments : TManagedList;
    FHeight : integer;
    FWidth : integer;

    // property handlers
    function GetStripCount : integer;
    function GetSegmentCount : integer;

    function GetStrip(i: integer): TbeFastStrip;
    function GetSegment(i: integer): TbeFastSegment;

    procedure Clear;

  public
    // board dimensions in cells
    property Height : integer read FHeight write FHeight;
    property Width : integer read FWidth write FWidth;

    property StripCount : integer read GetStripCount;
    property Strips[ i : integer ] : TbeFastStrip read GetStrip;
    property SegmentCount : integer read GetSegmentCount;
    property Segments[ i : integer ] : TbeFastSegment read GetSegment;

    function AddNewStrip : TbeFastStrip;
    function AddNewSegment : TbeFastSegment;

    procedure DeleteStrip( Strip : TbeFastStrip );
    procedure DeleteSegment( Segment : TbeFastSegment );

    procedure LoadFromBoard( Board : TbrBoard );
    procedure SaveToBoard( Board : TbrBoard );

    constructor Create;
    destructor Destroy; override;
end;



implementation

uses SysUtils;

{ TbeFastBoard }

type EBoardFast = class( Exception );


// ***************************************
//          CREATE, DESTROY
// ***************************************

constructor TbeTracks.Create;
begin
    FStrips := TManagedList.Create;
    FSegments := TManagedList.Create;
end;

destructor TbeTracks.Destroy;
begin
    FStrips.Free;
    FSegments.Free;
    inherited;
end;

// ***************************************
//                STRIPS
// ***************************************

function TbeTracks.GetStripCount: integer;
begin
    result := FStrips.Count;
end;

function TbeTracks.GetStrip(i: integer): TbeFastStrip;
begin
    result := TbeFastStrip( FStrips[i] );
end;

function TbeTracks.AddNewStrip: TbeFastStrip;
begin
    result := TbeFastStrip( FStrips.AddNew( TbeFastStrip ));
end;

procedure TbeTracks.DeleteStrip(Strip: TbeFastStrip);
var
    index : integer;
begin
    Index := FStrips.IndexOf( Strip );
    if index < 0 then begin
        raise EBoardFast.Create( 'Deleting invalid strip reference' );
    end;
    FStrips.Delete( Index );
end;

// ***************************************
//                SEGMENTS
// ***************************************

function TbeTracks.GetSegmentCount: integer;
begin
    result := FSegments.Count;
end;

function TbeTracks.GetSegment(i: integer): TbeFastSegment;
begin
    result := TbeFastSegment( FSegments[i] );
end;

function TbeTracks.AddNewSegment: TbeFastSegment;
begin
    result := TbeFastSegment( FSegments.AddNew( TbeFastSegment ));
end;

procedure TbeTracks.DeleteSegment(Segment: TbeFastSegment);
var
    index : integer;
begin
    Index := FSegments.IndexOf( Segment );
    if index < 0 then begin
        raise EBoardFast.Create( 'Deleting invalid segment reference' );
    end;
    FSegments.Delete( Index );
end;

// ******************************************
//          CLEAR STRIPS & SEGMENTS
// ******************************************

procedure TbeTracks.Clear;
begin
    FStrips.Clear;
    FSegments.Clear;
end;


// ******************************************
//     LOAD & SAVE TO TBRBOARD OBJECT
// ******************************************

procedure TbeTracks.LoadFromBoard(Board: TbrBoard);
var
    i : integer;
    Strip : TbrStrip;
    Segment : TbrSegment;
    FastStrip : TbeFastStrip;
    FastSegment : TbeFastSegment;
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
    FastStrip : TbeFastStrip;
    FastSegment : TbeFastSegment;
begin
    // at this point we might want to addd code to break segments that cross
    // strips, so that only segment ends contact strips

    Board.Clear;

    // board rectangle
    Board.Height := FHeight;
    Board.Width := FWidth;

    // strips are loaded into the TbrBoard as RawStrips.
    for i := 0 to StripCount -1 do begin
        FastStrip := Strips[i];
        RawStrip := Board.CreateNewRawStrip;
        RawStrip.Start := FastStrip.Start;
        RawStrip.Finish := FastStrip.Finish;
    end;

    for i := 0 to Board.SegmentCount -1 do begin
        FastSegment := Segments[i];
        Board.AddSegment(
            FastSegment.Start_1000.X, FastSegment.Start_1000.Y,
            FastSegment.Finish_1000.X, FastSegment.Finish_1000.Y,
            FastSegment.Width_1000
        );
    end;
end;


end.
