unit Outlines;

interface

uses SysUtils, Classes, Painter, Rotations, Types, Contnrs, ExceptSafe,
UndoEngine;

const TveMaxPinIndex = 100;

// Number of Fine Dividions per Cell
const DIVS_PER_CELL = 1000;

type EOutline = class( Exception );
//type ESafeOutline = class( ESafe );
type EOutlineStream = class( EOutline );
type EComponentStream = class( EOutline );


// ***************************************
//   Information Used for Outline Text
// ***************************************

type TTextSize = ( tsSmall, tsLarge );
function PixelsPerCell2CharWidth( PixelsPerCell : integer; TextSize : TTextSize ) : integer;
function StrlenCells( s : string; TextSize : TTextSize ) : integer;
function PixelsPerCell2CharHeight( PixelsPerCell : integer; TextSize : TTextSize ) : integer;

// **************************************************
//      Items Can be Shifted 1/2 Cell Right or Down
// **************************************************

type TveShift = ( shNone, shRight, shDown );


// ******************************************************************
//      TveUndoSnapshot Records BoardItem Properties
// ******************************************************************

type TveSnapshot = record
    X : integer;
    Y : integer;
    EndDeltaX : integer;
    EndDeltaY : integer;
    Shift : TveShift;
    TextX : integer;
    TextY : integer;
    TextVisible : boolean;
    TextRotation : TRotation;
    Designator : string;
    Value : string;
    Group : integer;
end;

// ***************************************
//      TBoardItem is placed on board
// ***************************************
(* A TveBoardItem is created for every item which is visible on the board
*)

type
    TveOutline = class;
    TunBoardItemMemento = class;

    TveBoardItem = class
    protected
        FOutline : TveOutline;
        FDesignator : string;   // eg 'R24'
        FValue : string;        // eg '120R'
        FX : integer;
        FY : integer;
        FXDivOffset : integer;
        FYDivOffset : integer;
        FEndDeltaX : integer;
        FEndDeltaY : integer;
        FShift : TveShift;

        FDesignatorX : integer;
        FDesignatorY : integer;
        FDesignatorRotation : TRotation;
        FDesignatorVisible : boolean;

        FSelected : boolean;
        FGroup : integer;

        FNodes : array[0..TveMaxPinIndex] of TObject;

        FSnapshot : TveSnapshot;

        function GetXDiv : integer;
        procedure SetXDiv( Value : integer );
        function GetYDiv : integer;
        procedure SetYDiv( Value : integer );

        function GetRotation : TRotation;
        procedure SetRotation( value : TRotation );

        function GetLength : integer;
        procedure SetLength( value : integer );
        function GetLengthExact : single;
        function GetDisplayLength : string;

        function GetNodeAtPin( PinIndex : integer ) : TObject;
        procedure SetNodeAtPin( PinIndex : integer; Node : TObject );
    public
        // for use by Adjuster - see Adjuster.pas
        ReservedAdjust1 : integer;

        property Outline : TveOutline read FOutline write FOutline;
        property Designator : string read FDesignator write FDesignator;
        property Value : string read FValue write FValue;

        property NodeAtPin[PinIndex : integer] : TObject
            read GetNodeAtPin write SetNodeAtPin;
        procedure ClearNodes;

        // placement properties of position x,y and rotation, footprint
        property X : integer read FX write FX;
        property Y : integer read FY write FY;
        property XDiv : integer read GetXDiv write SetXDiv;
        property YDiv : integer read GetYDiv write SetYDiv;
        property EndDeltaX : integer read FEndDeltaX write FEndDeltaX;
        property EndDeltaY : integer read FEndDeltaY write FEndDeltaY;

        property Rotation : TRotation read GetRotation write SetRotation;
        property Shift : TveShift read FShift write FShift;
        property Length : integer read GetLength write SetLength;
        property LengthExact : single read GetLengthExact;
        property DisplayLength : string read GetDisplayLength;

        property TextX : integer read FDesignatorX write FDesignatorX;
        property TextY : integer read FDesignatorY write FDesignatorY;
        property TextRotation : TRotation read FDesignatorRotation write FDesignatorRotation;
        property TextVisible : boolean read FDesignatorVisible write FDesignatorVisible;
//        property TextWidth : integer read FTextWidth write FTextWidth;

        property Snapshot : TveSnapshot read FSnapshot;

        procedure TakeSnapshot;
        function ChangedSinceSnapshot : boolean;
        function CreateMementoFromSnapshot : TunBoardItemMemento;

        function DesignatorOccupiesCell( CellX, CellY : integer ) : boolean;
        procedure GetDesignatorCell( var CellX, CellY : integer );
        procedure GetDesignatorRectangle( var X1, Y1, X2, Y2 : integer );
        procedure SetDesignatorCell( X, Y : integer );
        procedure SetDesignatorInsideRectangle( X1, Y1, X2, Y2 : integer );

        // editing properties
        property Selected : boolean read FSelected write FSelected;
        property Group : integer read FGroup write FGroup;

        procedure RotateAboutPoint( X, Y : integer );

        // stream the board item
        procedure WriteToStream( S : TStream );
        procedure ReadFromStream( S : TStream );

        constructor Create;
end;


// ***************************************
//              TveOutline
// ***************************************

(*  A TveOutline is the definition of a component type.  For each
TveOutline which is created, there can be any number of TveBoardItems placed
on the board - each having the same value of the Outline property.

This ancestor class will have descendants which record shape in different
ways, but all can be accessed through parent methods and properties.
*)

TvePin = class
  public
    Name : string;
end;


TveOutline = class

    protected

    FName : string;     // eg 'Resistor 100mW leaded'
    FRotatable : boolean;
    FUserDefined : boolean;
    FShowsDesignator : boolean;
    FShowsValue : boolean;
    FNoImport : boolean;
    FPins : TObjectList;

    function GetPin( index : integer ) : TvePin; virtual;
    function GetPinCount : integer;

    public

    // reserved for use by NetImporter : see NetImporter.pas
    ReservedUpdated : boolean;
    // reserved for general use ( in particular LibraryTools.pas)
    Tag : integer;

    property Name : string read FName write FName;
    property Rotatable : boolean read FRotatable write FRotatable;
    // UserDefined : can be assigned to different components, ie is not
    // a built-in outline like Wire, Link, Break, Text.
    property UserDefined : boolean read FUserDefined;
    property ShowsDesignator : boolean read FShowsDesignator;
    property ShowsValue : boolean read FShowsValue;
    property NoImport : boolean read FNoImport write FNoImport;

    property Pins[index : integer] : TvePin read GetPin;
    property PinCount : integer read GetPinCount;

    constructor Create; virtual;
    destructor Destroy; override;

    function Clone : TveOutline; virtual;
    function Identical( Outline : TveOutline ) : boolean; virtual;

    procedure Paint( Item : TveBoardItem;  Info : TvePainter ); virtual;

    function OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
        : boolean; virtual;

    function InsideRectangleR(
        Item : TveBoardItem; CellRect : TRect ) : boolean; //virtual;

    function PaintOverlapsRectangle( Item : TveBoardItem; R : TRect ) : boolean;

    procedure RotateAboutCenter( Item : TveBoardItem ); virtual;

    procedure LocateTextDefault( Item : TveBoardItem ); virtual;

    function PinIndexAt( Item : TveBoardItem; CellX, CellY : integer )
        : integer; virtual;

    function PinIndexByName( const Name : string ) : integer; virtual;

    // bounding rectangle which contains item : click inside this to select
    procedure GetScreenRectR( Item : TveBoardItem; var R : TRect ); virtual; abstract;

    // PaintRect is area to repaint: basically same as GetScreenRect plus designator
    procedure GetPaintRect( Item : TveBoardItem; var R : TRect ); virtual;

    // pin discovery
    procedure ToFirstPin; virtual;
    function GetNextPin(
        Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean; virtual;

    procedure SetDefaultLength( Item : TveBoardItem ); virtual;

    procedure WriteToStream( S : TStream ); virtual;
    procedure ReadFromStream( S : TStream ); virtual;
end;


// ***************************************
//      TunBoardItemMemento records edit of a single BoardItem
// ***************************************

TunBoardItemMemento = class( TunMemento )
  protected
    Item : TveBoardItem;
    X : integer;
    Y : integer;
    EndDeltaX : integer;
    EndDeltaY : integer;
    Shift : byte;
    TextX : integer;
    TextY : integer;
    TextVisible : boolean;
    TextRotation : TRotation;
//    DesignatorChanged : boolean;
    OldDesignator : string;
    NewDesignator : string;
//    ValueChanged : boolean;
    OldValue : string;
    NewValue : string;
    Group : integer;

  public

  // perform undo
  Procedure Undo; override;

  // perform redo
  Procedure Redo; override;

  // throw away this Memento from the Undo stack and destroy etc. the Memento
  Procedure DiscardUndo; override;

  // throw away this Memento from the Redo stack and destroy etc. the Memento
  Procedure DiscardRedo; override;
end;

TbeOperation = (opAdd, opRemove);


// ***************************************
//     TDefaultOutline always available
// ***************************************

TveDummyOutline = class(TveOutline)

    constructor Create; override;
    procedure Paint( Item : TveBoardItem;  Info : TvePainter ); override;
    function OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
        : boolean; override;
{
    function InsideRectangle( Item : TveBoardItem;
        CellX1, CellY1, CellX2, CellY2 : integer ) : boolean; override;
}        
//    procedure GetScreenRect( Item : TveBoardItem;
//        var ItemLeft, ItemRight, ItemTop, ItemBottom : integer ); override;
    procedure GetScreenRectR( Item : TveBoardItem; var R : TRect ); override;        

    // pin discovery
    procedure ToFirstPin; override;
    function GetNextPin(
        Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean; override;
end;

// ***************************************
//   Utility Functions Used by Outlines
// ***************************************

function LineFromStream( S : TStream; var Line : string ) : boolean;
function NameValueFromStream( S : TStream; var Name, Value : string ) : boolean;
procedure LineToStream( S : TStream; const Line : string );

implementation

uses Rectangles, Math;

// ***************************************
//   Information Used for Outline Text
// ***************************************

const
    // CellsPerChar given by ratio of these two values
    // (i.e. width of a character in cells)
    CellsPerCharWidthMult = 5;
    CellsPerCharWidthDiv = 10;

    CellsPerCharWidthMultLarge = 7;
    CellsPerCharWidthDivLarge = 10;

    // height of a character in cells
    CellsPerCharHeightMult = 9;
    CellsPerCharHeightDiv = 12;

    CellsPerCharHeightMultLarge = 13;
    CellsPerCharHeightDivLarge = 12;

// calculate char width in pixels given pixels per cell.
function PixelsPerCell2CharWidth( PixelsPerCell : integer; TextSize : TTextSize ) : integer;
begin
    // = PixelsPerCell * CellsPerChar
    case TextSize of
        tsSmall : result :=
            ( PixelsPerCell * CellsPerCharWidthMult ) div CellsPerCharWidthDiv;
        else
        {tsLarge :} result :=
            ( PixelsPerCell * CellsPerCharWidthMultLarge ) div CellsPerCharWidthDivLarge;
    end;
end;

// calculate length of a string in cells
function StrlenCells( s : string; TextSize : TTextSize ) : integer;
begin
    case TextSize of
        tsSmall : result :=
            ( Length(s) * CellsPerCharWidthMult ) div CellsPerCharWidthDiv;
        else
        {tsLarge :} result :=
            ( Length(s) * CellsPerCharWidthMultLarge ) div CellsPerCharWidthDivLarge;
    end;
end;

function PixelsPerCell2CharHeight( PixelsPerCell : integer; TextSize : TTextSize ) : integer;
begin
    case TextSize of
        tsSmall : result :=
            ( PixelsPerCell * CellsPerCharHeightMult ) div CellsPerCharHeightDiv;
        else
        {tsLarge :} result :=
            ( PixelsPerCell * CellsPerCharHeightMultLarge ) div CellsPerCharHeightDivLarge;
    end;
end;

// ***************************************
//      TunBoardItemMemento records edit of a single BoardItem
// ***************************************

// perform undo
Procedure TunBoardItemMemento.Undo;
begin
  Item.X := Item.X - X;
  Item.Y := Item.Y - Y;
  Item.EndDeltaX := Item.EndDeltaX - EndDeltaX;
  Item.EndDeltaY := Item.EndDeltaY - EndDeltaY;
  Item.Shift := TveShift((byte(Item.Shift) xor Shift));
  Item.TextX := Item.TextX - TextX;
  Item.TextY := Item.TextY - TextY;
  Item.TextRotation :=
        SubtractRotation( Item.TextRotation, TextRotation );
  Item.TextVisible :=
        Item.TextVisible XOR TextVisible;
  Item.Designator := OldDesignator;
  Item.Value := OldValue;
  Item.Group := Item.Group - Group;

  Item.Selected := True;
end;

// perform redo
Procedure TunBoardItemMemento.Redo;
begin
  Item.X := Item.X + X;
  Item.Y := Item.Y + Y;
  Item.EndDeltaX := Item.EndDeltaX + EndDeltaX;
  Item.EndDeltaY := Item.EndDeltaY + EndDeltaY;
  Item.Shift := TveShift((byte(Item.Shift) xor Shift));
  Item.TextX := Item.TextX + TextX;
  Item.TextY := Item.TextY + TextY;
  Item.TextRotation :=
        AddRotation( Item.TextRotation, TextRotation );
  Item.TextVisible :=
        Item.TextVisible XOR TextVisible;
  Item.Designator := NewDesignator;
  Item.Value := NewValue;
  Item.Group := Item.Group + Group;

  Item.Selected := True;
end;

// throw away this Memento from the Undo stack and destroy etc. the Memento
Procedure TunBoardItemMemento.DiscardUndo;
begin
  Free;
end;

// throw away this Memento from the Redo stack and destroy etc. the Memento
Procedure TunBoardItemMemento.DiscardRedo;
begin
  Free;
end;

// ***************************************
//      TveBoardItem is placed on board
// ***************************************

function TVeBoardItem.GetXDiv : integer;
begin
    result := (FX * DIVS_PER_CELL) + FXDivOffset;
end;

procedure TVeBoardItem.SetXDiv( Value : integer );
begin
    FX := (Value + DIVS_PER_CELL div 2) div DIVS_PER_CELL;
    FXDivOffset := Value - (FX * DIVS_PER_CELL);
end;

function TVeBoardItem.GetYDiv : integer;
begin
    result := (FY * DIVS_PER_CELL) + FYDivOffset;
end;

procedure TVeBoardItem.SetYDiv( Value : integer );
begin
    FY := (Value + DIVS_PER_CELL div 2) div DIVS_PER_CELL;
    FYDivOffset := Value - (FY * DIVS_PER_CELL);
end;

// Get Rotation
// result is inaccurate if component is diagonally placed: that is OK,
// because only used by code that sets 90 degree rotations

function TVeBoardItem.GetRotation : TRotation;
begin
    // if component is horizontal or mostly horizontal
    if abs( FEndDeltaX ) >  abs( FEndDeltaY ) then begin
        if FEndDeltaX > 0 then begin
            result := rot90;
        end
        else begin
            result := rot270;
        end;
    end

    // else component is vertical or mostly vertical
    else begin
        if FEndDeltaY > 0 then begin
            result := rot0;
        end
        else begin
            result := rot180;
        end;
    end;
end;

// Set Rotation
// If component is diagonally placed, the length will be altered: that is OK,
// because only used by code that sets 90 degree rotatons

procedure TVeBoardItem.SetRotation( value : TRotation );
var
    LengthTemp : integer;
begin
    // length is greater of X, Y
    LengthTemp := Max( abs( FEndDeltaX ), abs( FEndDeltaY ) );
    case value of
      rot0: begin
          FEndDeltaX := 0;
          FEndDeltaY := LengthTemp;
      end;
      rot90: begin
          FEndDeltaX := LengthTemp;
          FEndDeltaY := 0;
          end;
      rot180: begin
          FEndDeltaX := 0;
          FEndDeltaY := -LengthTemp;
      end;
      rot270: begin
          FEndDeltaX := -LengthTemp;
          FEndDeltaY := 0;
      end;
    end;
end;

// Get Length
// result is inaccurate if component is diagonally placed: that is OK,
// because only used by code that sets 90 degree rotations

function TVeBoardItem.GetLength : integer;
begin
    // length is greater of X, Y
    result := Max( abs( FEndDeltaX ), abs( FEndDeltaY ) );
end;


// Set Rotation
// If component is diagonally placed, the length will be altered: that is OK,
// because only used by code that sets 90 degree rotatons
procedure TVeBoardItem.SetLength( value : integer );
begin
    if value < 1 then begin
        value := 1;
    end;

    // if component is horizontal or mostly horizontal
    if abs( FEndDeltaX ) >  abs( FEndDeltaY ) then begin
        if FEndDeltaX > 0 then begin
            FEndDeltaX := value;
            FEndDeltaY := 0;
        end
        else begin
            FEndDeltaX := -value;
            FEndDeltaY := 0;
        end;
    end

    // else component is vertical or mostly vertical
    else begin
        if FEndDeltaY > 0 then begin
            FEndDeltaX := 0;
            FEndDeltaY := value;
        end
        else begin
            FEndDeltaX := 0;
            FEndDeltaY := -value;
        end;
    end;
end;

function TVeBoardItem.GetLengthExact : single;
begin
    result := sqrt((EndDeltaX * EndDeltaX) + (EndDeltaY * EndDeltaY));
end;

function TveBoardItem.GetDisplayLength : string;
var
    LengthF : single;
begin
    LengthF := GetLengthExact;
    if abs(Round(LengthF) - LengthF) < 0.01 then begin
        result := Format( '%d', [Round(LengthF)] );
    end
    else begin
        result := Format( '%3.1f', [LengthF] );
    end;
end;

function TVeBoardItem.GetNodeAtPin( PinIndex : integer ) : TObject;
begin
    if (PinIndex > TveMaxPinIndex) or (PinIndex < 0) then begin
        raise ERangeError.Create( 'Pin Index out of range' );
    end;
    result := FNodes[PinIndex];
end;

procedure TVeBoardItem.SetNodeAtPin( PinIndex : integer; Node : TObject );
begin
    if (PinIndex > TveMaxPinIndex) or (PinIndex < 0) then begin
        raise ERangeError.Create( 'Pin Index out of range' );
    end;
    FNodes[PinIndex] := Node;
end;

procedure TVeBoardItem.ClearNodes;
var
    i : integer;
begin
    for i := 0 to TveMaxPinIndex do begin
        FNodes[i] := nil;
    end;
end;

procedure TveBoardItem.RotateAboutPoint( X, Y : integer );
var
    RefX, RefY : integer;
begin
    // if not orthogonal
    if (EndDeltaX <> 0) and (EndDeltaY <> 0) then begin

        // if mostly up and down
        if abs(EndDeltaX) > abs(EndDeltaY) then begin
            // make it vertical
            EndDeltaX := 0;
        end
        else begin
            // make it horizontal
            EndDeltaY := 0;
        end;
        // locate one end at rotation point
        FX := X;
        FY := Y;
        exit;
    end;

    // rotate reference point around X, Y
    RefX := self.X;
    RefY := self.Y;
    Rotate(  RefX, RefY, X, Y, rot90 );
    self.X := RefX;
    self.Y := RefY;

    // change rotation component is drawn
    Rotation := TRotation( (Ord(Rotation) + 1) mod 4 );
end;


function TveBoardItem.DesignatorOccupiesCell( CellX, CellY : integer ) : boolean;
const
    // cells each side of text center which respond to clicks
    SideCells = 0;
var
    TextX, TextY : integer;
begin
    TextX := FX + FDesignatorX;
    TextY := FY + FDesignatorY;

    // text position is rotated along with the rest of the component
    // around the item (0.0) reference point
    Rotate( TextX, TextY, FX, FY, Rotation );

    // one cell each side of center cell is accepted as click on area
    if FDesignatorRotation in [Rot0, Rot180] then begin
        Result :=
            (CellY = TextY) and
            (CellX >= (TextX - SideCells)) and
            (CellX <= (TextX + SideCells));
    end
    else begin
        Result :=
            (CellX = TextX) and
            (CellY >= (TextY - SideCells)) and
            (CellY <= (TextY + SideCells));
    end;
end;

procedure TveBoardItem.GetDesignatorCell( var CellX, CellY : integer );
begin
    CellX := FX + FDesignatorX;
    CellY := FY + FDesignatorY;

    // text position is rotated along with the rest of the component
    // around the item (0.0) reference point
    Rotate( CellX, CellY, FX, FY, Rotation );
end;

procedure TveBoardItem.GetDesignatorRectangle( var X1, Y1, X2, Y2 : integer );
var
    TextX, TextY : integer;
begin

    // calculate (TextX, TextY), Cell coords of text
    TextX := FX + FDesignatorX;
    TextY := FY + FDesignatorY;

    // text position is rotated along with the rest of the component
    // around the item (0.0) reference point
    Rotate( TextX, TextY, FX, FY, Rotation );

    // define a designator "box" at text position, depending on designator rotation
    if FDesignatorRotation in [Rot0, Rot180] then begin
        X1 := TextX - 1;
        X2 := TextX + 2;
        Y1 := TextY;
        Y2 := TextY + 1;
    end
    else begin
        X1 := TextX;
        X2 := TextX + 1;
        Y1 := TextY - 1 ;
        Y2 := TextY + 2;
    end;
end;

// ** Set Designator Centre Cell with Board Cell Coords **

procedure TveBoardItem.SetDesignatorCell( X, Y : integer );
begin
    // Screen text position is rotated back to default component angle
    // around the componentn reference point
    RotateReverse( X, Y, FX, FY, Rotation );

    // any remaining offset is provided by DesignatorX, DesignatorY
    FDesignatorX := X - FX;
    FDesignatorY := Y - FY;
end;

// ** Keep Designator Center Cell Within a Rectangle **

procedure TveBoardItem.SetDesignatorInsideRectangle( X1, Y1, X2, Y2 : integer );
var
    CellX, CellY : integer;

begin
    GetDesignatorCell( CellX, CellY );

    // adjust movement to keep designator on board
    if (CellX < X1) then begin
        CellX := X1;
    end
    else if (CellX >= X2) then begin
        CellX := X2 -1;
    end;

    if (CellY < Y1) then begin
        CellY := Y1;
    end
    else if (CellY >= Y2) then begin
        CellY := Y2 -1;
    end;

    SetDesignatorCell( CellX, CellY );
end;


constructor TveBoardItem.Create;
begin
    FDesignatorVisible := True;
    // give it a rotation of 0
    FEndDeltaY := 1;
end;

procedure TveBoardItem.TakeSnapshot;
begin
    FSnapshot.X := X;
    FSnapshot.Y := Y;
    FSnapshot.EndDeltaX := EndDeltaX;
    FSnapshot.EndDeltaY := EndDeltaY;
    FSnapshot.Shift := Shift;
    FSnapshot.TextX := TextX;
    FSnapshot.TextY := TextY;
    FSnapshot.TextVisible := TextVisible;
    FSnapshot.TextRotation := TextRotation;
    FSnapshot.Designator := Designator;
    FSnapshot.Value := Value;
    FSnapshot.Group := Group;
end;

function TveBoardItem.ChangedSinceSnapshot : boolean;
begin
    result :=
        (FSnapshot.X <> X) or
        (FSnapshot.Y <> Y) or
        (FSnapshot.EndDeltaX <> EndDeltaX) or
        (FSnapshot.EndDeltaY <> EndDeltaY) or
        (FSnapshot.Shift <> Shift) or
        (FSnapshot.TextX <> TextX) or
        (FSnapshot.TextY <> TextY) or
        (FSnapshot.TextVisible <> TextVisible) or
        (FSnapshot.TextRotation <> TextRotation) or
        (FSnapshot.Designator <> Designator) or
        (FSnapshot.Value <> Value) or
        (FSnapshot.Group <> Group);
end;


function TVeBoardItem.CreateMementoFromSnapshot : TunBoardItemMemento;
begin
  result := TunBoardItemMemento.Create;
  result.Item := self;
  result.X := X - Snapshot.X;
  result.Y := Y - Snapshot.Y;
  result.EndDeltaX := EndDeltaX - Snapshot.EndDeltaX;
  result.EndDeltaY := EndDeltaY - Snapshot.EndDeltaY;
  result.Shift := byte(Shift) xor byte(Snapshot.Shift);
  result.TextX := TextX - Snapshot.TextX;
  result.TextY := TextY - Snapshot.TextY;
  result.TextRotation := SubtractRotation( TextRotation, Snapshot.TextRotation );
  result.TextVisible := TextVisible XOR Snapshot.TextVisible;
  result.OldDesignator := Snapshot.Designator;
  result.NewDesignator := Designator;
  result.OldValue := Snapshot.Value;
  result.NewValue := Value;
  result.Group := Group - Snapshot.Group;
end;

// stream the board item
procedure TveBoardItem.WriteToStream( S : TStream );
const ShiftToStr : array[TveShift] of string = ( 'shNone', 'shRight', 'shDown' );
const BoolToStr : array[boolean] of string = ( '0', '1' );
const RotToStr : array[TRotation] of string = ( '0', '1', '2', '3' );
begin
    LineToStream( S, Format( 'Component=', [''] ) );

    //  write out properties

    LineToStream( S, Format( 'Outline=%s', [FOutline.Name] ) );
    LineToStream( S, Format( 'Designator=%s', [FDesignator] ) );
    LineToStream( S, Format( 'Value=%s', [FValue] ) );
    LineToStream( S, Format( 'X=%d', [FX] ) );
    LineToStream( S, Format( 'Y=%d', [FY] ) );
    LineToStream( S, Format( 'EndDeltaX=%d', [FEndDeltaX] ) );
    LineToStream( S, Format( 'EndDeltaY=%d', [FEndDeltaY] ) );
    LineToStream( S, Format( 'Shift=%s', [ShiftToStr[Shift]] ) );
    LineToStream( S, Format( 'DesignatorX=%d', [TextX] ) );
    LineToStream( S, Format( 'DesignatorY=%d', [TextY] ) );
    LineToStream( S, Format( 'DesignatorRotation=%s', [RotToStr[FDesignatorRotation]] ) );
    LineToStream( S, Format( 'DesignatorVisible=%s', [BoolToStr[TextVisible]] ) );

    LineToStream( S, 'end' );
end;

procedure TveBoardItem.ReadFromStream( S : TStream );

function StrToShift( const s : string ) : TveShift;
begin
    if s = 'shRight' then begin
        result := shRight;
    end
    else if s = 'shDown' then begin
        result := shDown;
    end
    // default to no shift
    else begin
        result := shNone;
    end;
end;

function StrToRotation( const s : string ) : TRotation;
var
    n : integer;
begin
    n := StrToInt( s );
    if n > 3 then begin
        n := 0;
    end;
    result := TRotation( n );
end;

var
    AName, AValue : string;
begin
{
Component=
Outline=Break
Designator=
Value=
X=34
y=32
EndDeltaX=5
EndDeltaY=2
Shifted=0
DesignatorX=0
DesignatorY=0
DesignatorRotation=0
DesignatorVisible=1
end
}

   while NameValueFromStream( S, AName, AValue ) do begin
      if AName = 'Component' then begin

      end
      else if AName = 'Outline' then begin

      end
      else if AName = 'Designator' then begin
          FDesignator := AValue;
      end
      else if AName = 'Value' then begin
          FValue := AValue;
      end
      else if AName = 'X' then begin
          FX := StrToInt( AValue );
      end
      else if AName = 'Y' then begin
          FY := StrToInt( AValue );
      end
      else if AName = 'EndDeltaX' then begin
          EndDeltaX := StrToInt( AValue );
      end
      else if AName = 'EndDeltaY' then begin
          EndDeltaY := StrToInt( AValue );
      end
      else if AName = 'Shift' then begin
          FShift := StrToShift( AValue );
      end
      else if AName = 'DesignatorX' then begin
          FDesignatorX := StrToInt( AValue );
      end
      else if AName = 'DesignatorY' then begin
          FDesignatorY := StrToInt( AValue );
      end
      else if AName = 'DesignatorRotation' then begin
          FDesignatorRotation := StrToRotation( AValue );
      end
      else if AName = 'DesignatorVisible' then begin
          FDesignatorVisible := AValue <> '0';;
      end
      else if AName = 'end' then begin
          exit;
      end
      else begin
          raise EComponentStream.CreateFmt( 'Unknown property name: "%s"', [AName] );
      end;
   end;
end;

// ***************************************
//          TveOutline
// ***************************************

constructor TveOutline.Create;
begin
    inherited;
    FPins := TObjectList.Create;
end;

destructor TveOutline.Destroy;
begin
    FPins.Free;
    inherited;
end;

//  ********  Functions Provide Array of Pins *******
// descendants will add pins to the array

function TveOutline.GetPin( index : integer ) : TvePin;
begin
    result := TvePin( FPins[index] );
end;

function TveOutline.GetPinCount : integer;
begin
    result := FPins.Count;
end;

// *********************************

function TveOutline.Clone : TveOutline;
begin
    // By default outlines cannot clone themselves.
    // Later, for proper duplication of a TProject, we may want to give all
    // outlines the ability to clone.
    result := nil;
end;

function TveOutline.Identical( Outline : TveOutline ) : boolean; 
begin
    // safe to say "different" by default - means that duplicate outlines get
    // created.  All outlines need to be able to detect identical outlines
    // Does not compare Name property, but all else
    result := False;
end;

procedure TveOutline.Paint( Item : TveBoardItem;  Info : TvePainter );
begin
end;

function TveOutline.OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
    : boolean;
begin
    result := False;
end;

// say if click area of this item lies completely inside a given rectangle
// This base class function can probably replace all separate implementations
// in descendant classes

function TveOutline.InsideRectangleR(
    Item : TveBoardItem; CellRect : TRect ) : boolean;
var
    ItemRect : TRect;
begin
    // screen rect is bounding rectangle
    GetScreenRectR( Item, ItemRect );

    // CellX1, CellX2 are not bounding rectangle, but one extra cell on
    // all sides.  This is wierd, but observed by all outlines.  We could
    // rationalise this.
    result :=
        (CellRect.Left < ItemRect.Left) and (CellRect.Top < ItemRect.Top) and
        (CellREct.Right >= ItemRect.Right) and (CellRect.Bottom >= ItemRect.Bottom);
end;

// say if this item overlaps a given screen rectangle, and requires a repaint
// when that rectangle is repainted.
function TveOutline.PaintOverlapsRectangle(
    Item : TveBoardItem; R : TRect ) : boolean;
var
    ItemRect : TRect;
begin
    GetPaintRect( Item, ItemRect );

    result :=
        (
        ((R.Left <= ItemRect.Left) and (R.Right > ItemRect.Left)) and

        (((R.Top <= ItemRect.Top) and (R.Bottom > ItemRect.Top)) or
                ((ItemRect.Top <= R.Top) and (ItemRect.Bottom > R.Top)))
        )
        or
        (
        ((ItemRect.Left <= R.Left) and (ItemRect.Right > R.Left)) and
        (((ItemRect.Top <=  R.Top) and (ItemRect.Bottom > R.Top)) or
                ((R.Top <= ItemRect.Top) and (R.Bottom > ItemRect.Top)))
        )
    ;
end;


procedure TveOutline.GetPaintRect( Item : TveBoardItem; var R : TRect );
const
    // cells each side of text center which are repainted
    SideCells = 4;

var
    TextX, TextY : integer;
    TextX1, TextY1, TextX2, TextY2 : integer;

begin
    // by default, PaintRect is same as GetScreenRect plus designator
    GetScreenRectR( Item,  R );

    // extend rectangle to include Designator
    if ShowsDesignator and Item.TextVisible then begin

        // calculate (TextX, TextY), Cell coords of text
        TextX := Item.X + Item.TextX;
        TextY := Item.Y + Item.TextY;

        // text position is rotated along with the rest of the component
        // around the item (0.0) reference point
        Rotate( TextX, TextY, Item.X, Item.Y, Item.Rotation );

        // define a designator "box" at text position, depending on designator rotation
        // 4 squares each side of center cell
        if Item.TextRotation in [Rot0, Rot180] then begin
            TextX1 := TextX - SideCells;
            TextX2 := TextX + SideCells +1;
            TextY1 := TextY;
            TextY2 := TextY + 1;
        end
        else begin
            TextX1 := TextX;
            TextX2 := TextX + 1;
            TextY1 := TextY - SideCells ;
            TextY2 := TextY + SideCells +1;
        end;
{
        // 1 square each side of center cell
        if Item.DesignatorRotation in [Rot0, Rot180] then begin
            TextX1 := TextX - 1;
            TextX2 := TextX + 2;
            TextY1 := TextY;
            TextY2 := TextY + 1;
        end
        else begin
            TextX1 := TextX;
            TextX2 := TextX + 1;
            TextY1 := TextY - 1 ;
            TextY2 := TextY + 2;
        end;
}
        // extend body rectangle by designator rectangle
        if TextX1 < R.Left then begin
            R.Left := TextX1;
        end;
        if TextX2 > R.Right then begin
            R.Right := TextX2;
        end;
        if TextY1 < R.Top then begin
            R.Top := TextY1;
        end;
        if TextY2 > R.Bottom then begin
            R.Bottom := TextY2;
        end;
    end;
end;

procedure TveOutline.RotateAboutCenter( Item : TveBoardItem );
begin
end;

// Move text to default location - in this case, to centre

procedure TveOutline.LocateTextDefault( Item : TveBoardItem );
var
  R : TRect;
begin
  GetScreenRectR( Item, R );
    Item.TextX := 0;
    Item.TextY := -1;
//  Item.TextX := ((R.Right - R.Left ) div 2) - Item.X;
//  Item.TextY := ((R.Bottom + R.Top ) div 2) - Item.Y;
  Item.TextRotation := rot0;
end;

function TveOutline.PinIndexAt( Item : TveBoardItem; CellX, CellY : integer )
    : integer;
begin
    result := -1;
end;

function TveOutline.PinIndexByName( const Name : string ) : integer;
var
  i: Integer;
begin
    for i := 0 to FPins.Count - 1 do begin
        if TvePin(FPins[i]).Name = Name then begin
            result := i;
            exit;
        end;
    end;

    // Name not found in list
    result := -1;
end;


// pin discovery : base class has no pins
procedure TveOutline.ToFirstPin;
begin

end;

function TveOutline.GetNextPin(
    Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean;
begin
    result := False;
end;


// ** Outline sets board item length to a safe and visually OK default value **
// ** Lets newly created components look OK **
procedure TveOutline.SetDefaultLength( Item : TveBoardItem );
begin

end;

// ** Outline writes its properties to a stream - override this virtual function
// ** in descendants **

// Every outline at least emits its ClassName - which covers simple outlines
// like text, links, breaks, wires
procedure TveOutline.WriteToStream( S : TStream );
begin
    LineToStream( S, Format( 'Outline=%s', [ClassName] ) );
    LineToStream( S, 'end' );
end;

// ** Outline reads its properties from a stream - override this virtual function
// ** in descendants **

// Simple outlines like text, links, breaks, wires, dummy use this default procedure
// because they have no properties to set.
procedure TveOutline.ReadFromStream( S : TStream );
var
    Line : string;
begin
    // These simple objects read no properties, just look for "end" to terminate
    // section
    if (not LineFromStream( S, Line )) or (Line <> 'end') then begin

    end;
end;


// ***************************************
//              TveDummyOutline
// ***************************************

constructor TveDummyOutline.Create;
begin
    inherited;
    FName := '*Dummy*';
    FUserDefined := True;
    FShowsDesignator := True;
    FShowsValue := True;
end;

procedure TveDummyOutline.Paint( Item : TveBoardItem; Info : TvePainter );
var
    BodyLines : TPolyLines;
    ComponentX, ComponentY : integer;
    X1, X2 : integer;
    Y1, Y2 : integer;
    Side : integer;
begin
    BodyLines := Info.BodyLines;

    // draw a rectangle, 2 cells per side
    //locate TCanvas pixels containing top left of Item
    ComponentX := (Item.X * Info.PixelsPerCell) + Info.Border;
    ComponentY := (Item.Y * Info.PixelsPerCell) + Info.Border;

    // calculate 4 points on corners of a rectangle
    Side := Info.PixelsPerCell * 2;
    X1 := ComponentX +1;
    X2 := ComponentX + Side -1;

    Y1 := ComponentY +1;
    Y2 := ComponentY + Side -1;

    // draw rectangle
    BodyLines.AddPoint( X1, Y1 );
    BodyLines.AddPoint( X2, Y1 );
    BodyLines.AddPoint( X2, Y2 );
    BodyLines.AddPoint( X1, Y2 );
    BodyLines.AddPoint( X1, Y1 );
    // slanting line across rectangle
    BodyLines.AddPoint( X2, Y2 );
    BodyLines.EndShape;
end;

function TveDummyOutline.OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
    : boolean;
begin
    result :=
        (CellX >= Item.X) and (CellX <= Item.X + 1) and
        (CellY >= Item.Y) and (CellY <= Item.Y + 1);
end;

{
function TveDummyOutline.InsideRectangle( Item : TveBoardItem;
    CellX1, CellY1, CellX2, CellY2 : integer ) : boolean;
begin
    result :=
        (CellX1 < Item.X) and (CellX2 > Item.X + 1) and
        (CellY1 < Item.Y) and (CellY2 > Item.Y + 1);
end;
}

procedure TveDummyOutline.GetScreenRectR( Item : TveBoardItem; var R : TRect );
begin
   // create rectangle which includes all cells in this outline
    // this is not a bounding rectangle - hence we subtract 1 from width, height
    R.Left := Item.X;
    R.Right := Item.X + 1;
    R.Top := Item.Y;
    R.Bottom := Item.Y + 1;

    Rotate( R.Right, R.Bottom, Item.X, Item.Y, Item.Rotation );

    // arrange rotated coords to give left,top and right,bottom of rectangle.
    NormalizeRect( R );

    // turn into bounding rectangle
    Inc( R.Right );
    Inc( R.Bottom );
end;


// pin discovery
procedure TveDummyOutline.ToFirstPin;
begin
end;

function TveDummyOutline.GetNextPin(
    Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean;
begin
    result := False;
end;


// ***************************************
//   Utility Functions Used by Outlines
// ***************************************

function LineFromStream( S : TStream; var Line : string ) : boolean;
var
    CH : char;
begin
    Line := '';
    result := False;
    while S.Read( CH, sizeof(char) ) = sizeof(char) do begin
        result := True;
        if CH = #13 then begin
            exit;
        end;
        if CH <> #10 then begin
            Line := Line + CH;
        end;
    end;
end;

function NameValueFromStream( S : TStream; var Name, Value : string ) : boolean;
var
    CH : char;
begin
    Name := '';
    Value := '';
    result := False;

    // Safe to parse 16 bit char-bychar, because surrogate units
    // always have the 2 high bits set to 1101 and neither surrogate char
    // can be mistaken for a single char unicode character.

    // parse first (Name) section of Name=Value pair
    while S.Read( CH, sizeof(char) ) = sizeof(char) do begin
        if CH = #13 then begin
            exit;
        end;
        // first '=' cencountered means end of Name section
        if CH = '=' then begin
            break;
        end;
        if CH <> #10 then begin
            // provided we have at least one character on the line
            result := True;
            Name := Name + CH;
        end;
    end;

    // parse second (Value) section of Name=Value pair
    while S.Read( CH, sizeof(CH) ) = sizeof(char) do begin
        if CH = #13 then begin
            exit;
        end;
        if CH <> #10 then begin
            Value := Value + CH;
        end;
    end;
end;


procedure LineToStream( S : TStream; const Line : string );
const CRLF : array[0..1] of char = #13#10;
begin
    S.WriteBuffer( PChar(Line)^, Length(Line) * sizeof(char) );
    S.WriteBuffer( CRLF, 2 * sizeof(char) );
end;

(*
function TStringStream.ReadString(Count: Longint): string;
var
  Len: Integer;
begin
  Len := Length(FDataString) - FPosition;
  if Len > Count then Len := Count;
  SetString(Result, PChar(@FDataString[FPosition + 1]), Len);
  Inc(FPosition, Len);
end;


function TaaReadTextFilter.ReadLine : string;
const
  CR = ^M;
  LF = ^J;
var
  Ch : char;
  BytesRead : longint;
begin
  {read characters until we get an LF}
  BytesRead := Read(Ch, sizeof(Ch));
  while (BytesRead <> 0) and (Ch <> LF) do begin
    {if it's not a CR character, append it to the current line}
    if (Ch <> CR) then
      FStrBuilder.Add(Ch);
    BytesRead := Read(Ch, sizeof(Ch));
  end;
  {return the string}
  Result := FStrBuilder.AsString;
end;
*)

end.

