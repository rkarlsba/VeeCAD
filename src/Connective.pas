unit Connective;

interface

uses Outlines, OtherOutlines, Project, Netlist, ManagedItem, Types,
    Classes, DebugFrm, Board;

const
    // number of pins from links, wires, components that can exist on
    // the same cell and still be tracked by TConnective. If a layout
    // has more pins on a cell, the program ignores some pins
    PINS_PER_CELL = 6;

    // number of strip ends that can intersect on a cell. Since strips are
    // vertical or horizontal, can never be more than four.
    STRIPS_PER_CELL = 4;

    // number of DIVS per cell. A finer unit of measurement
    DIVS_PERCELL = 1000;

type
    // *********************************************************************
    // Cell data record describes pins & breaks using a cell
    // *********************************************************************
    TcnPin = record
        Item : TveBoardItem;  // item with pin on this cell, not including a break
        PinIndex : integer;   // use with Item.NodeAtPin[Index]
        //                    //   Item.Outline.Pins[PinIndex].Name
    end;
    pcnPin = ^TcnPin;

    TveBreak = ( brUnshifted, brShiftRight, brShiftDown );
    TveBreaks = set of TveBreak;

    TcnStrip = class;

    TcnCellData = record
        Break : TveBreaks;      // breaks on this cell, or 1/2 cell to right
        // number of pins on this cell
        PinCount : integer;
        // component pin data (PinCount number of filled array entries)
        Pins : array[0..PINS_PER_CELL-1] of TcnPin;
        // an error occurs on this cell
        Error : boolean;
        Scanned : boolean;
        // Strips
        StripEndCount : integer;
        StripEnds : array[0..STRIPS_PER_CELL-1] of TcnStrip;
    end;

    PcnCellData = ^TcnCellData;

    // *********************************************************************
    //        Strip Describes a Length of Perforated Strip
    // *********************************************************************
    // Strips only intersect at the the ends: a new strip starts at any
    // intersection of strips.
    TcnDirection = ( drHorizontal, drVertical );
    TcnStripSet = class;

    TcnStrip = class( TManagedItem )
      public
        Start : TPoint;   // left or top
        Finish : TPoint;  // right or bottom
        Direction : TcnDirection;
        StripSet : TcnStripSet;
        Scanned : boolean;
        IslandNo : integer;
        FirstPin : TPoint;
    end;

    // *********************************************************************
    //   A StripSet is A Group of Strips and SegmentGroups in the Same Net
    // *********************************************************************

    // StripSet has 1)no net yet, h2)an error prevents allocation, 3)has a net
    TcnStripNetStatus = ( nsAvailable, nsMustNotAllocate, nsAllocated );

    TcnStripSet = class( TManagedItem )
      private
        FStrips : TList;
        FSegmentGroups : TList;
        FNet : TneNode;
        function GetCount : integer;
        function GetStrip(index : integer) : TcnStrip;
        function GetSegmentGroupCount : integer;
        function GetSegmentGroup( index : integer ) : TbrSegmentGroup;
      public
        Broken : boolean;
        Status : TcnStripNetStatus;
        property Net : TneNode read FNet write FNet;
        property Count : integer read GetCount;
        property Strips[index : integer] : TcnStrip read GetStrip; default;
        property SegmentGroupCount : integer read GetSegmentGroupCount;
        property SegmentGroups[index : integer] : TbrSegmentGroup
            read GetSegmentGroup;
        procedure AddSegmentGroup( Group : TbrSegmentGroup );
        procedure AddStrip( Strip : TcnStrip );
        procedure Clear;

        procedure SortByScanOrder;

        constructor Create; override;
        destructor Destroy; override;
    end;

    // *********************************************************************
    //        A SegmentSet is A Group of Board Segments
    // *********************************************************************

    TcnSegmentSet = class( TManagedItem )
      public
        Net : TneNode;
        Status : TcnStripNetStatus;
        SegmentGroup : TbrSegmentGroup;
    end;

// ***************************************************************
//          A Wire link Joins Two Strips
// ***************************************************************

type TcnLink = class( TManagedItem )
  protected
    FStartStrip : TcnStrip;
    FEndStrip : TcnStrip;
    FStartX : integer;
    FStartY : integer;
    FEndX : integer;
    FEndY : integer;
  public
    property StartStrip : TcnStrip read FStartStrip write FStartStrip;
    property EndStrip : TcnStrip read FEndStrip write FEndStrip;
    property StartX : integer read FStartX write FStartX;
    property StartY : integer read FStartY write FStartY;
    property EndX : integer read FEndX write FEndX;
    property EndY : integer read FEndY write FEndY;
end;


// ***************************************************************
//       A TcnWire Is A Point Which Is Connected by Free-Form
//        wires to other TdrWires in same net.
// ***************************************************************

type TcnWire = class( TManagedItem )
  protected
    FStrip : TcnStrip;
    FX : integer;
    FY : integer;
  public
    property Strip : TcnStrip read FStrip write FStrip;
    property X : integer read FX write FX;
    property Y : integer read FY write FY;
end;


// ***************************************************************
//    A WireSet is a Collection of TcnWires in the same Net.
// ***************************************************************

type TcnWireSet = class( TManagedItem )

protected
    FWires : TManagedList;
    FNet : TneNode;
    function GetWireCount : integer;
    function GetWire( index : integer ) : TcnWire;
public
    property Net : TneNode read FNet write FNet;

    property WireCount : integer read GetWireCount;
    property Wires[ index : integer ] : TcnWire read GetWire;

    function CreateWire : TcnWire;

    constructor Create; override;
    destructor Destroy; override;
end;


// ***************************************************************
//    A TcnIslandBridge Records A Missing Connection That
//      Is Required Between 2 Strips To Complete the Layout
//      in Accordance with the Netlist. LineStart, LineEnd
//      Are Shortest Line Between the Strips.
// ***************************************************************

type TcnIslandBridge = class( TManagedItem )

protected
    FStartStrip : TcnStrip;
    FEndStrip : TcnStrip;
    FLineStart, FLineFinish : TPoint;
public
    property StartStrip : TcnStrip read FStartStrip write FStartStrip;
    property EndStrip : TcnStrip read FEndStrip write FEndStrip;
    property Line1 : TPoint read FLineStart write FLineStart;
    property Line2 : TPoint read FLineFinish write FLineFinish;
end;

// ***************************************************************
//    A TcnNetSet Records All The Strips That Are In
//      The Same Net.
// ***************************************************************

type TcnNetSet = class( TManagedItem )

protected
    FNet : TneNode;
    FStrips : TList;
    function GetCount : integer;
    function GetStrip( index : integer ) : TcnStrip;
public
    property Net : TneNode read FNet;
    property Count : integer read GetCount;
    property Strips[ index : integer ] : TcnStrip read GetStrip;
    procedure Clear;
    procedure AddStrip( Strip : TcnStrip );

    constructor Create; override;
    destructor Destroy; override;
end;


// ***************************************************************
//    A TcnError Records The XDiv, YDiv Coords of An Error
//    Used to draw error markers. Cell Errors stored in Cells[]
//    not with TcnError
// ***************************************************************

type TcnError = class( TManagedItem )
public
    XDiv, YDiv : integer;
end;


type TConnectivity = class

  protected
    // references to other classes for access
    FProject : TveProject;
    Netlist : TneNetlist;

    // owned by this class
    FStrips : TManagedList;
    FStripSets : TManagedList;
    FLinks : TManagedList;
    FWireSets : TManagedList;
    FIslandBridges : TManagedList;
    FNetSets : TManagedList;
    AllWires : TList;
    FSegmentSets : TManagedList;
    FErrors : TManagedList;

    FOnDebugStart : TveDebugNotify;
    FOnDebugLineOut : TveDebugLineOut;
    FOnDebugEnd : TveDebugNotify;

   // last width height value used
    OldWidth, OldHeight : integer;

    procedure DebugStripSets;
    procedure DebugBoard;
    procedure DebugSegmentSets;
    procedure DebugLinks;
    procedure DebugLine( const s : string );

    function AddToStripSet( SumStripSet, AddendStripSet : TcnStripSet ) : boolean;
    procedure CombineStripSets;

    procedure BuildPins;
    procedure CheckBreaksOnPins;
    procedure BuildStrips;
    procedure RescanBrokenStripSets;
    procedure BuildSegmentSets;
    procedure ConnectSmdPinsToSegments;
    procedure CombineStripsetsBySegments;
    procedure BuildLinks;
    procedure NetsToStripSets;
    procedure BuildWireSets;
    procedure PropagateNets;
    procedure FindFirstPins;
    procedure DetectIslands;

    // property handlers
    function GetStrip( index : integer ) : TcnStrip;
    function GetStripCount : integer;

    function GetStripSetCount : integer;
    function GetStripSet( index : integer ) : TcnStripSet;

    function GetLinkCount : integer;
    function GetLink( index : integer ) : TcnLink;

    function GetIslandBridgeCount : integer;
    function GetIslandBridge( index : integer ) : TcnIslandBridge;

    function GetNetSetCount : integer;
    function GetNetSet( index : integer ) : TcnNetSet;

    function GetSegmentSetCount : integer;
    function GetSegmentSet( index : integer ) : TcnSegmentSet;

    function GetErrorCount : integer;
    function GetError( index : integer ) : TcnError;

  public

    //Cells : array[0..500, 0..100] of TcnCellData;
    Cells : array of array of TcnCellData;

    property Project : TveProject read FProject write FProject;

    property Strips[index : integer] : TcnStrip read GetStrip;
    property StripCount : integer read GetStripCount;

    property StripSetCount : integer read GetStripSetCount;
    property StripSets[index : integer] : TcnStripSet read GetStripSet;

    property LinkCount : integer read GetLinkCount;
    property Links[i : integer] : TcnLink read GetLink;

    property IslandBridgeCount : integer read GetIslandBridgeCount;
    property IslandBridges[i : integer] : TcnIslandBridge read GetIslandBridge;

    // NetSets only available if GenerateNetSets is called by code outside this
    // class. A convenience for use by Router, not called by TConnectivity.Check.
    // Whereas TcnStripSet holds strips and segmentGroups, TcnNetSet holds only
    // strips.
    property NetSetCount : integer read GetNetSetCount;
    property NetSets[index : integer] : TcnNetSet read GetNetSet;
    procedure GenerateNetSets;

    property OnDebugStart : TveDebugNotify read FOnDebugStart write FOnDebugStart;
    property OnDebugLineOut : TveDebugLineOut read FOnDebugLineOut write FOnDebugLineOut;
    property OnDebugEnd : TveDebugNotify read FOnDebugEnd write FOnDebugEnd;

    property SegmentSetCount : integer read GetSegmentSetCount;
    property SegmentSets[index : integer] : TcnSegmentSet read GetSegmentSet;

    property ErrorCount : integer read GetErrorCount;
    property Errors[index : integer] : TcnError read GetError;

    procedure Clear;
    procedure Check;

    function GetCellErrorCount : integer;

    function NodeByLink( Item : TveBoardItem ) : TneNode;
    function NodeByWire( Item : TveBoardItem ) : TneNode;
    function StripAt( x, y : integer ) : TcnStrip;
    function StripSetByNode( Node : TneNode ) :  TcnStripSet;

    constructor Create;
    destructor Destroy; override;
end;



implementation

uses SysUtils, SizeableOutlines, SmdOutlines, CopperTrace;

type TcnExcept = class( Exception );

// *****************************************************************
//        TcnStripSet : Contains Strips in Same Net
// *****************************************************************

function TcnStripSet.GetCount : integer;
begin
    result := FStrips.Count;
end;

function TcnStripSet.GetStrip(index : integer) : TcnStrip;
begin
    result := TcnStrip( FStrips[index] );
end;

procedure TcnStripSet.AddStrip( Strip : TcnStrip );
begin
    FStrips.Add( Strip );
end;

function TcnStripSet.GetSegmentGroupCount : integer;
begin
    result := FSegmentGroups.Count;
end;

function TcnStripSet.GetSegmentGroup( index : integer ) : TbrSegmentGroup;
begin
    result := TbrSegmentGroup( FSegmentGroups[index] );
end;

procedure TcnStripSet.AddSegmentGroup( Group : TbrSegmentGroup );
begin
    FSegmentGroups.Add( Group );
end;

procedure TcnStripSet.Clear;
begin
    FStrips.Count := 0;
    FSegmentGroups.Count := 0;
    Status := nsAvailable;
    Net := nil;
    Broken := False;
end;

constructor TcnStripSet.Create;
begin
    inherited;
    FStrips := TList.Create;
    FSegmentGroups := TList.Create;
end;

destructor TcnStripSet.Destroy;
begin
    FStrips.Free;
    FSegmentGroups.Free;
    inherited;
end;

{
**********************************************


    TcnStripSet = class( TManagedItem )
      private
        FStrips : TList;
        FNet : TneNode;
        FCount : integer;
        function GetStrip(index : integer) : TcnStrip;
      public
        Broken : boolean;
        ScanStrip : TcnStrip;
        Status : TcnStripNetStatus;
        property Count : integer read FCount;
        property Strips[index : integer] : TcnStrip read GetStrip; default;
        property Net : TneNode read FNet write FNet;

        procedure AddStrip( Strip : TcnStrip );
        procedure Clear;

        procedure SortByScanOrder;

        constructor Create;
        destructor Destroy; override;
    end;

***********************************************
}

function CompareStripsByScanOrder( P1, P2 : pointer ) : integer;
var
    Start1, Start2 : TPoint;
//    X1, Y1, X2, Y2 : integer;
begin
    Start1 := TcnStrip(P1).Start;
    Start2 := TcnStrip(P2).Start;

    // try to minimise X ( ie want nearest left )
    if Start1.X < Start2.X then begin
        result := 1;
    end
    else if Start1.X > Start2.X then begin
        result := -1;
    end
    // at this stage, Start1.X = Start2.X so now try for nearest the top
    else if Start1.Y < Start2.Y then begin
        result := 1;
    end
    else if Start1.Y > Start2.Y then begin
        result := -1;
    end
    // at this stage, Start1 = Start2. For 2 strips to have the same start
    // point, one must be horizontal and other vertical. Give the horizontal
    // strip priority.
     else if TcnStrip(P1).Direction = drHorizontal then begin
          if TcnStrip(P2).Direction = drVertical then begin
              result := 1;
          end
          else begin
              result := 0;
          end;
     end
     else begin
          if TcnStrip(P2).Direction = drHorizontal then begin
              result := -1
          end
          else begin
              result := 0;
          end;
     end;
end;


procedure TcnStripSet.SortByScanOrder;
begin
    FStrips.Sort( CompareStripsByScanOrder );
end;


// **************************************
//              TdrWireSet
// **************************************

function TcnWireSet.GetWireCount : integer;
begin
    result := FWires.Count;
end;

function TcnWireSet.GetWire( index : integer ) : TcnWire;
begin
    result := TcnWire( FWires[ index ] );
end;

function TcnWireSet.CreateWire : TcnWire;
begin
    result := TcnWire(FWires.AddNew( TcnWire ));
end;

constructor TcnWireSet.Create;
begin
    FWires := TManagedList.Create;
end;

destructor TcnWireSet.Destroy;
begin
    FWires.Free;
end;

// **************************************
//              TcnNetSet
// **************************************

//  A TcnNetSet holds a list of Strips that belong in the same net

constructor TcnNetSet.Create;
begin
    inherited;
    FStrips := TList.Create;
end;

destructor TcnNetSet.Destroy;
begin
    // FStrips holds references to Strips - it does not need to destroy
    // the strip objects.
    FStrips.Free;
    inherited;
end;

function TcnNetSet.GetCount : integer;
begin
    result := FStrips.Count;
end;

function TcnNetSet.GetStrip( index : integer ) : TcnStrip;
begin
    result := TcnStrip( FStrips[ index ] );
end;

// ** Remove all Strip References from List **
procedure TcnNetSet.Clear;
begin
    // setting Count leaves FStrips memory allocated
    FStrips.Count := 0;
end;

// ** Add a Strip Reference to the List **
procedure TcnNetSet.AddStrip( Strip : TcnStrip );
begin
    FStrips.Add( Strip );
end;

// **************************************
//    A TcnNetSets Stores An Array of TcnNetSet
//    Objects That Describe a Project.
// **************************************

function TConnectivity.GetNetSetCount : integer;
begin
    result := FNetSets.Count;
end;

function TConnectivity.GetNetSet( index : integer ) : TcnNetSet;
begin
    result := TcnNetSet( FNetSets[ index ] );
end;

// ** Generate NetSets array property - each NetSet in the array contains
// a list of Strips that are in the same net. Strips with no net are not
// included NetSets **

procedure TConnectivity.GenerateNetSets;
var
    i : integer;
    j : integer;
    StripSet : TcnStripSet;
    CurrentNetSet : TcnNetSet;
    CurrentNet : TneNode;
begin
    // remove old NetSets
    FNetSets.Clear;

    // provent "unititialised variable" warning
    CurrentNetSet := nil;

    // initialise so first net comparison causes new Net trigger
    CurrentNet := nil;

    // StripSets are sorted so that StripSets with no net (nil net) are
    // at lowest indexes, so start at top and quit at first nil net StripSet.
    for i := StripSetCount - 1 downto 0 do begin

        StripSet := StripSets[ i ];

        // if reached bottom of list where all nil net stripsets reside- finished
        if StripSet.Net = nil then begin
            exit;
        end;

        // if new net, start a new NetSet (new net trigger)
        if StripSet.Net <> CurrentNet then begin
            CurrentNet := StripSet.Net;
            // our ManagedList ancestor can do AddNew
            CurrentNetSet := TcnNetSet( FNetSets.AddNew( TcnNetSet ) );
            CurrentNetSet.Clear;
            CurrentNetSet.FNet := CurrentNet;
        end;

        // add stripset contents to NetSet
        for j := 0 to StripSet.Count -1 do begin
            CurrentnetSet.AddStrip( StripSet.Strips[ j ] );
        end;
    end;
end;

// ************************************************
//                SegmentSets
// ************************************************

function TConnectivity.GetSegmentSetCount : integer;
begin
    result := FSegmentSets.Count;
end;

function TConnectivity.GetSegmentSet( index : integer ) : TcnSegmentSet;
begin
    result := TcnSegmentSet( FSegmentSets[index] );
end;


// ************************************************
//                TcnErrors
// ************************************************

function TConnectivity.GetErrorCount : integer;
begin
    result := FErrors.Count;
end;

function TConnectivity.GetError( index : integer ) : TcnError;
begin
    result := TcnError( FErrors[index] );
end;

{ TConnectivity }

// ************************************************
//           CONSTRUCTOR, DESTRUCTOR
// ************************************************

constructor TConnectivity.Create;
begin
    FStrips := TManagedList.Create;
    FStripSets := TManagedList.Create;
    FLinks := TManagedList.Create;
    FWireSets := TManagedList.Create;
    FIslandBridges := TManagedList.Create;
    FNetSets := TManagedList.Create;
    AllWires := TList.Create;
    FSegmentSets := TManagedList.Create;
    FErrors := TManagedList.Create;
end;

destructor TConnectivity.Destroy;
begin
    FStrips.Free;
    FStripSets.Free;
    FLinks.Free;
    FWireSets.Free;
    FIslandBridges.Free;
    FNetSets.Free;
    AllWires.Free;
    FSegmentSets.Free;
    FErrors.Free;
end;

// *****************************************************************
//                  PROPERTY HANDLERS
// *****************************************************************


function TConnectivity.GetStripCount : integer;
begin
    result := FStrips.Count;
end;

function TConnectivity.GetStrip( index : integer ) : TcnStrip;
begin
    result := TcnStrip( FStrips[index] );
end;

function TConnectivity.GetStripSetCount : integer;
begin
    result := FStripSets.Count;
end;

function TConnectivity.GetStripSet( index : integer ) : TcnStripSet;
begin
    result := TcnStripSet( FStripSets[index] );
end;

function TConnectivity.GetLinkCount : integer;
begin
    result := FLinks.Count;
end;

function TConnectivity.GetLink( index : integer ) : TcnLink;
begin
    result := TcnLink( FLinks[index] );
end;

function TConnectivity.GetIslandBridgeCount : integer;
begin
    result := FIslandBridges.Count;
end;

function TConnectivity.GetIslandBridge( index : integer ) : TcnIslandBridge;
begin
    result := TcnIslandBridge( FIslandBridges[index] );
end;

function TConnectivity.GetCellErrorCount : integer;
var
    x, y : integer;
begin
    result := 0;
    for x := 0 to FProject.BoardWidth -1 do begin
        for y := 0 to FProject.BoardHeight -1 do begin
            if Cells[x,y].Error then begin
                Inc( result );
            end;
        end;
    end;
end;

// *****************************************************************
//                  COMBINE TWO STRIPSETS
// *****************************************************************

// Combine Addend into Sum Stripsets
// Returns True if the function has combined the two stripsets
// Returns False if function did not combine the stripsets because they
// were the identical object.
function TConnectivity.AddToStripSet( SumStripSet, AddendStripSet : TcnStripSet ) : boolean;
var
    i : integer;
    Strip : TcnStrip;
begin
    // if same object, don't combine it
    if SumStripSet = AddendStripSet then begin
        result := False;
        exit;
    end;

    // transfer strip references from 2 to 1
    for i := 0 to AddendStripSet.Count - 1 do begin
        Strip := AddendStripSet[i];
        SumStripSet.AddStrip( AddendStripSet[i] );
        Strip.StripSet := SumStripSet;
    end;

    // transfer segment group references from 2 to 1
    for i := 0 to AddendStripSet.SegmentGroupCount - 1 do begin
        SumStripSet.AddSegmentGroup( AddendStripSet.SegmentGroups[i] );
    end;

    // delete StripSet2
    FStripSets.Delete( FStripSets.IndexOf(AddendStripSet) );

    result := True;
end;


// *****************************************************************
//        FILL BOARD ARRAY WITH PIN & BREAK DATA
// *****************************************************************

procedure TConnectivity.BuildPins;
var
    i : integer;
    Item : TveBoardItem;
    Outline : TveOutline;

    // pin information
    X, Y  : integer;
    PinIndex : integer;

    pCellData : PcnCellData;
    CellPinCount : integer;

    BoardWidth, BoardHeight : integer;
begin
    // record board extents
    BoardWidth := FProject.BoardWidth;
    BoardHeight := FProject.BoardHeight;

    // examine every board item, identifying Breaks, Pins
    for i := 0 to FProject.BoardItemCount -1 do begin
        Item := FProject.BoardItems[i];
        Outline := Item.Outline;

        // SMD Pins are off-cell and are handled in ConnectSmdPinsToSegments()
        if Outline is TveSmdOutline then begin
            continue;
        end;

        // a break does not have pins, but affects nets, so store it
        // Cells[][].Break can store set of ( brUnshifted, brShiftRight, brShiftDown )
        if Outline is TveBreakOutline then begin
            case Item.Shift of
                shNone : begin
                    Include( Cells[Item.X,Item.Y].Break, brUnShifted );
                end;
                shRight : begin
                    Include( Cells[Item.X,Item.Y].Break, brShiftRight );
                end;
                shDown : begin
                    Include( Cells[Item.X,Item.Y].Break, brShiftDown );
                end;
            end;
            continue;
        end;

        // other parts have pins, so store the pin indexes
        Outline.ToFirstPin;
        while Outline.GetNextPin( Item, X, Y, PinIndex ) do begin

            // refuse to store invalid pin numbers - these map to outside
            // array boundaries!
            if (X < 0) or (Y < 0) or (X >= BoardWidth) or (Y >= BoardHeight) then begin
                continue;
            end;

            // store item & pin No information in correct cell.
            pCellData := @(Cells[x,y]);
            CellPinCount := pCellData^.PinCount;

            if CellPinCount < PINS_PER_CELL then begin
                pCellData^.Pins[CellPinCount].Item := Item;
                pCellData^.Pins[CellPinCount].PinIndex := PinIndex;
                Inc( pCellData^.PinCount );
            end;
        end;
    end;
end;

// *****************************************************************
//    MARK CELLS WITH both PIN and UNSHIFTED BREAK AS ERROR
// *****************************************************************

procedure TConnectivity.CheckBreaksOnPins;
var
    x, y : integer;
//    pCellData : PcnCellData;
begin
    // look for pins with unshifted break on same cell, & mark as error
    for x := 0 to FProject.BoardWidth -1 do begin
        for y := 0 to FProject.BoardHeight - 1 do begin
            if (brUnShifted in Cells[x,y].Break)and (Cells[x,y].PinCount > 0) then begin
                Cells[x,y].Error := True;
            end;
        end;
    end;
end;

// *****************************************************************
//          BUILD LIST OF STRAIGHT COPPER STRIPS
// *****************************************************************
// Read TbrBoard StripGroups and create corresponding StripSets in
// FStripsSets[]. If a strip is cut into segments by breaks, create a
// new strip for each segment. Put all segments into the same StripSet
// - later code will rescand broken stripsets.  Record is stripset is broken.


procedure TConnectivity.BuildStrips;
const
    BoardDirToConnDir : array[TbrDirection] of TcnDirection =
        ( drHorizontal, drVertical );

var
    StripSet : TcnStripSet;

  // Copy a TbrBoard strip into our Strips array, and add it to our StripSet.
  // If our strip is interrupted by breaks, we will add multiple smaller
  // strips, a shorter strip or no strip at all. A break means that the parts
  // of the stripset could belong to different nets. We don't assign the net
  // here, but we do record that the stripset is "broken" and needs to be
  // rescanned later into separate stripsets. For now, all the pieces go into
  // one stripset.
  procedure AddStripHorizontal( BoardStrip : TbrStrip );
  var
      Strip : TcnStrip;
      HaveStrip : boolean;
      FirstStrip : boolean;
      x, y : integer;
      StripFinish : integer;
  begin

    HaveStrip := False;
    FirstStrip := True;
    x := BoardStrip.Start.x;
    y := BoardStrip.Start.y;
    StripFinish := BoardStrip.Finish.x;
    //.. prevent "uninitialised variable" warning
    Strip := nil;

    while x <= StripFinish do begin

        // break right on the cell hole
        if brUnshifted in Cells[x,y].Break then begin
            if HaveStrip then begin
               Strip.Finish := Point( x -1, y );
               StripSet.Broken := True;
               HaveStrip := False;
            end;
        end

        // break between this cell hole and next cell hole to right
        else if brShiftRight in Cells[x,y].Break then begin
            // if already have a strip, finish it
            if HaveStrip then begin
               Strip.Finish := Point( x, y );
               StripSet.Broken := True;
               HaveStrip := False;
            end
            // if leftmost hole on strip has a break shifted right, make a
            // 1 cell strip
            else begin
                Strip := TcnStrip( FStrips.AddNew( TcnStrip ) );
                Strip.Start := Point( x, y );
                Strip.Direction := drHorizontal;

                //.. strip belongs to a StripSet.
                Strip.StripSet := StripSet;
                StripSet.AddStrip( Strip );

                Strip.Finish := Point( x, y );
                StripSet.Broken := True;

               HaveStrip := False;
            end
        end

        // no break on horizontal strip, so must be good copper.
        // if we don't have a strip, start one
        else if not HaveStrip then begin
            Strip := TcnStrip( FStrips.AddNew( TcnStrip ) );
            Strip.Start := Point( x, y );
            Strip.Direction := drHorizontal;

            //.. strip belongs to a StripSet.
            Strip.StripSet := StripSet;
            StripSet.AddStrip( Strip );

            // if this is second or later section of strip (after a break)
            if not FirstStrip then begin
                StripSet.Broken := True;
            end
            else begin
                FirstStrip := False;
            end;

            HaveStrip := True;
        end;

        // to next hole to the right
        Inc( x );
    end;

    // if BoardStrip end reached without break, then end strip here
    if HaveStrip then begin
        Strip.Finish := Point( StripFinish, y );
    end;
  end;

  procedure AddStripVertical( BoardStrip : TbrStrip );
  var
      Strip : TcnStrip;
      HaveStrip : boolean;
      FirstStrip : boolean;
      x, y : integer;
      StripFinish : integer;
  begin

    HaveStrip := False;
    FirstStrip := True;
    x := BoardStrip.Start.x;
    y := BoardStrip.Start.y;
    StripFinish := BoardStrip.Finish.y;
    //.. prevent "uninitialised variable" warning
    Strip := nil;

    while y <= StripFinish do begin

        // break right on the cell hole
        if brUnshifted in Cells[x,y].Break then begin
            if HaveStrip then begin
               Strip.Finish := Point( x, y -1 );
               StripSet.Broken := True;
               HaveStrip := False;
            end;
        end

        // break between this cell hole and next cell hole below
        else if brShiftDown in Cells[x,y].Break then begin
            // if already have a strip, finish it
            if HaveStrip then begin
               Strip.Finish := Point( x, y );
               StripSet.Broken := True;
               HaveStrip := False;
            end
            // if top hole on strip has a break shifted down, make a 1 cell strip
            else begin
                Strip := TcnStrip( FStrips.AddNew( TcnStrip ) );
                Strip.Start := Point( x, y );
                Strip.Direction := drVertical;

                //.. strip belongs to a StripSet.
                Strip.StripSet := StripSet;
                StripSet.AddStrip( Strip );

                Strip.Finish := Point( x, y );
                StripSet.Broken := True;

               HaveStrip := False;
            end
        end

        // no break on vertical strip, so must be good copper.
        // if we don't have a strip, start one
        else if not HaveStrip then begin
            Strip := TcnStrip( FStrips.AddNew( TcnStrip ) );
            Strip.Start := Point( x, y );
            Strip.Direction := drVertical;

            //.. strip belongs to a StripSet.
            Strip.StripSet := StripSet;
            StripSet.AddStrip( Strip );

            // if this is second or later section of strip (after a break)
            if not FirstStrip then begin
                StripSet.Broken := True;
            end
            else begin
                FirstStrip := False;
            end;

            HaveStrip := True;
        end;

        // to next hole below
        Inc( y );
    end;

    // if BoardStrip end reached without break, then end strip here
    if HaveStrip then begin
        Strip.Finish := Point( x, StripFinish );
    end;
  end;

var
    i, j : integer;
    StripGroup : TbrStripGroup;
    BoardStrip : TbrStrip;
begin
    // copy over stripsets from TbrBoard object. Each stripset maps to a
    // group of strips having the same island number
    for i := 0 to FProject.Board.StripGroupCount - 1 do begin
        StripGroup := FProject.Board.StripGroups[i];

        StripSet := TcnStripSet( FStripSets.AddNew( TcnStripSet ) );
        StripSet.Clear;

        for j := 0 to StripGroup.Count - 1 do begin

            // access board strip
            BoardStrip := StripGroup.Strips[j];

            if BoardStrip.Direction = diHorizontal then begin
                AddStripHorizontal( BoardStrip );
            end
            else begin
                AddStripVertical( BoardStrip );
            end;

        end;
    end;
 end;


// *****************************************************************
//                  RESCAN BROKEN STRIPSET
// *****************************************************************

{ Broken stripsets are those where at least one strip crosses a break.
  When breaks lie on strips:
    * stripset can disappear due to breaks on entire stripa length.
    * stripset can lose strips due to breaks disconnecting strips. New stripsets
      are created to contain these strips.
    * stripset can remain intact if a circular path powers both sides of a break.
}
{
 If 4 tracks meet at a cell OR two tracks cross, Connective.pas sees these as 4
 segments. If you place 4 breaks immediately next to the cross cell, Connective
 produces FOUR segments that start and end on the cell hole – sort of “donuts”.
 In TConnectivity.RescanBrokenStripSets() (line 1218) we only record one end of
 these tiny strips, because STRIPS_PER_CELL = 4; only allows for 4 strip ends, \
 not 8. The tiny strips all belong to the same StripSet and net. Potentially \
 the multiple “donuts” affect Routing, but I have not checked for that, and the
 code survived with up to 2 donuts before fix in Dec 2022 to
 allow 4.
}
procedure TConnectivity.RescanBrokenStripSets;

    // plot one end of a strip on the cells array
    procedure PlotEnd( x, y : integer; Strip : TcnStrip );
    var
        pCell : PcnCellData;
    begin
        pCell := @Cells[x, y];
{$IFDEF DEBUG}
        if pCell^.StripEndCount > STRIPS_PER_CELL then begin
            raise TcnExcept.CreateFmt( 'Internal error: Too many strips at %d,%d', [x, y]);
        end;
{$ENDIF}
        pCell^.StripEnds[pCell^.StripEndCount] := Strip;
        Inc( pCell^.StripEndCount );
    end;

    // Given the coords of one end of a strip, trace any connected strips,
    // adding them to the StripSet, and setting the Scanned member to true.
    procedure FollowStrip( StripSet : TcnStripSet; Point : TPoint );
    var
        i : integer;
        PCell : PcnCellData;
        AStrip : TcnStrip;
    begin
        // look at Cells to find all connected strips
        PCell := @(Cells[Point.X, Point.Y]);

        // for each connected strip,
        for i := 0 to PCell^.StripEndCount - 1 do begin
            AStrip := PCell^.StripEnds[i];
            if AStrip.Scanned then begin
                continue;
            end;

            // add strip to stripset
            StripSet.AddStrip( AStrip );
            AStrip.Stripset := StripSet;

            // prevent recursive scanning of same strip due to a circular track
            // path. Also prevents re-scanning as we move down the Strips[]
            // list and encounter a strip that was connected to an earlier strip.
            AStrip.Scanned := True;

            // follow other end of the strip (this end is already being scanned)
            if(AStrip.Start.X = Point.X) and (AStrip.Start.Y = Point.Y) then begin
                FollowStrip( StripSet, AStrip.Finish );
            end
            else begin
                FollowStrip( StripSet, AStrip.Start );
            end;
        end;
    end;

var
  i: Integer;
  StripSet : TcnStripSet;
  j: Integer;
  Limit : integer;
  NewStripSet : TcnStripSet;
  Strip : TcnStrip;
begin

    // remove empty stripsets
    for i := FStripSets.Count - 1 downto 0 do begin
        StripSet := TcnStripSet( FStripSets[i] );

        if StripSet.Count <= 0 then begin
            FStripSets.Delete( i );
        end;
    end;

    // for each stripset
    Limit := FStripSets.Count -1;
    for i := Limit downto 0 do begin
        StripSet := TcnStripSet( FStripSets[i] );

        // only process stripsets that are "broken" by track break symbols
        if not StripSet.Broken then begin
            continue;
        end;

{       // No need - cleared in TConnectivity.Clear().
        // clear strip endpoint cells
        for j := 0 to Stripset.Count - 1 do begin
            Strip := Stripset[j];
        end;
}
        // plot strip endpoints on cells
        for j := 0 to Stripset.Count - 1 do begin
            Strip := Stripset[j];
            PlotEnd( Strip.Start.X, Strip.Start.Y, Strip );
            // if both ends on same cell, don't record same strip twice
            if (Strip.Start.X <> Strip.Finish.X) or
                (Strip.Start.Y <> Strip.Finish.Y) then begin
                PlotEnd( Strip.Finish.X, Strip.Finish.Y, Strip );
            end;
            // and prepare for tracing
            Strip.Scanned := False;
        end;

        // trace further strips : create new stripset for each connnected set
        for j := 0 to StripSet.Count - 1 do begin

            Strip := StripSet[j];

            // ignore previously scanned strips - they belong to this stripset
            if not Strip.Scanned then begin
                NewStripSet := TcnStripSet( FStripSets.AddNew( TcnStripSet ) );
                NewStripSet.Clear;

                NewStripSet.AddStrip( Strip );
                Strip.Scanned := True;
                Strip.Stripset := NewStripSet;

                FollowStrip( NewStripSet, Strip.Start );
                FollowStrip( NewStripSet, Strip.Finish );
            end;
          end;

        // we no longer need the original stripset!
        FStripSets.Delete( i );
    end;
end;

// *****************************************************************
//           COMBINE STRIPSETS THAT ARE JOINED BY SEGMENTS
// *****************************************************************
{ This is where segments (segment groups) join to stripsets, and where
 segment groups connect different stripsets together. After this function, we
 all electrically continuous copper, both segments and strips is recroded in
 the StripSets.
}

procedure TConnectivity.CombineStripsetsBySegments;

    // mark Segment as error - with a dot at it's mid point
    procedure MarkSegmentError( Segment : TbrSegment );
    var
        Error : TcnError;
    begin
        Error := TcnError(FErrors.AddNew(TcnError) );
        Error.XDiv := (Segment.X1_1000 + Segment.X2_1000) div 2;
        Error.YDiv := (Segment.Y1_1000 + Segment.Y2_1000) div 2;
     end;

    // Join A Segment to a StripSet
    // RETURNS True=Join Made, False=No Join because nets not compatible
    function JoinSegmentToStripSet( StripSet : TcnStripSet;
        SegmentSet : TcnSegmentSet; Segment : TbrSegment ) : boolean;
    begin
      // * detect error situations *
      // ssMustNotAllocate can only propagate to a free strip/segment
      if ((StripSet.Status = nsMustNotAllocate) and (SegmentSet.Status <> nsAvailable)) OR

      // ssMustNotAllocate can only propagate to a free strip/segment
      ((SegmentSet.Status = nsMustNotAllocate) and (StripSet.Status <> nsAvailable)) OR

      // if nets assigned, they must be identical
      ((StripSet.Status = nsAllocated) and (SegmentSet.Status = nsAllocated) and
          (StripSet.Net <> SegmentSet.Net)) then begin

          MarkSegmentError( Segment );
          // join not made
          result := False;
          exit;
      end;

      // * perform join *
      // we use Segment if it has data (we know Segment already compatible with
      // StripSet, because of error checks in lines above).
      // if SegmentSet has a net to offer
      if SegmentSet.Status <> nsAvailable then begin
          StripSet.Net := SegmentSet.Net;
          StripSet.Status := SegmentSet.Status;
      end
      // else StripSet net dominates
      else begin
          SegmentSet.Net := StripSet.Net;
          SegmentSet.Status := StripSet.Status;
      end;

      // SEGMENTGROUP ADDED ONLY ONCE, BECAUSE JoinSegmentToStripSet() is
      // only called once per segment
      StripSet.AddSegmentGroup( SegmentSet.SegmentGroup );

      // join made
      result := True;
    end;


    // Combine stripset into master. Segment and Master are already in same
    // net before this function is called.
    procedure JoinStripSets( Master, Joiner : TcnStripSet; Segment : TbrSegment );
    begin
      // don't join a stripset to itself
      if Master = Joiner then begin
          exit;
      end;

      // * detect error situations *
      // ssMustNotAllocate can only propagate to a free strip/segment
      if ((Master.Status = nsMustNotAllocate) and (Joiner.Status <> nsAvailable)) OR

      // ssMustNotAllocate can only propagate to a free strip/segment
      ((Joiner.Status = nsMustNotAllocate) and (Master.Status <> nsAvailable)) OR

      // if nets assigned, they must be identical
      ((Master.Status = nsAllocated) and (Joiner.Status = nsAllocated) and
          (Master.Net <> Joiner.Net)) then begin

          MarkSegmentError( Segment );
          exit;
      end;

      // WHAT IF STRIPSET IS ??ALREADY ADDED TO THIS STRIPSET ?
      // IS THAT POSSIGLE >>

      { ****************************
        WARNING! above error check wrongly detects cases where a StripGroup
        with ssMustNotAllocate connects to a strip in multiple places. We have
        the same error in NetsToStripSets and PropagateNets where we join
        StripSets.
       ****************************}

      // * perform join *
      // we use Joiner if it has data (we know Joiner already compatible with
      // Master, because of error checks in lines above).
      // If Joiner has a net
      if Joiner.Status <> nsAvailable then begin
          Master.Net := Joiner.Net;
          Master.Status := Joiner.Status;
      end
      // else Master has a net
      else begin
          Joiner.Net := Master.Net;
          Joiner.Status := Master.Status;
      end;

      // merge our stripset into the Master
      AddToStripSet( Master, Joiner );
    end;


    procedure CombineStripSets( SegSet : TcnSegmentSet );
    var
        SegGroup : TbrSegmentGroup;
        MasterStripSet : TcnStripSet;
        Segment : TbrSegment;
        Strip : TcnStrip;
        TrackConnect : TPoint;
        SegmentIndex : integer;
        SegmentEndIndex : integer;
        CellX, CellY : integer;
    begin
        SegGroup := SegSet.SegmentGroup;

        // we hope to find a master stripset
        MasterStripSet := nil;

        // When we combine stripsets, we remove a stripset from StripSets[]
        // and thus must start from top of array StripSets[]

        for SegmentIndex := 0 to SegGroup.Count -1 do begin

            Segment := SegGroup.Segments[SegmentIndex];

            // for each end of the segment
            for SegmentEndIndex := 0 to 1 do begin

                TrackConnect := Segment.TrackIntersection[SegmentEndIndex];
                CellX := TrackConnect.X;
                CellY := TrackConnect.Y;

                // no connection if X coord is -1 (by convention) or break on cell
                if (CellX = -1) or (brUnshifted in Cells[CellX,CellY].Break) then begin
                    continue;
                end;

                // at this point we have a connection!
                Strip := StripAt( TrackConnect.X, TrackConnect.Y );
                if Strip = nil then begin
                    // should never get here
                    //asm nop end;
                    continue;
                end;

                // if we don't have a master stripset already, make this stripset
                // the master
                if MasterStripSet = nil then begin
                    if JoinSegmentToStripSet( Strip.StripSet, SegSet, Segment) then begin
                        MasterStripSet := Strip.StripSet;
                    end;
                end
                // we have a master stripset, so add this strip to it
                else begin
                    JoinStripSets( MasterStripSet, Strip.StripSet, Segment );
                end;
           end;
        end;

        // if no join was made, give the segment set its own stripset, which
        // has no strips, only segments
        if MasterStripSet = nil then begin

            // make a new stripset - the "Master", to which other stripsets can
            // be added
            MasterStripSet := TcnStripSet( FStripSets.AddNew( TcnStripSet ) );
            MasterStripSet.Clear;

            // add our SegmentGroup to this StripSet - it has no strips as yet,
            // and if it contacts no strips, then it will stay that way
            MasterStripSet.AddSegmentGroup( SegGroup );
            MasterStripSet.Net := SegSet.Net;
            MasterStripSet.Status := SegSet.Status;
        end;
    end;

var
    i : integer;
    SegmentSet : TcnSegmentSet;
begin
    // for each segment set
    for i := 0 to SegmentSetCount -1 do begin

        // get the segment group
        SegmentSet := SegmentSets[i];
        CombineStripSets( SegmentSet );
    end;
end;


procedure TConnectivity.BuildLinks;

    // return True if point (X,Y) lies on strip
    function OnStrip( Strip : TcnStrip; X, Y : integer ) : boolean;
    begin
        // horizontal strip
        if Strip.Direction = drHorizontal then begin
            result :=
                (Y = Strip.Start.Y) and (X >= Strip.Start.X) and (X <= Strip.Finish.X);
        end

        // vertical strip
        else begin
            result :=
                (X = Strip.Start.X) and (Y >= Strip.Start.Y) and (Y <= Strip.Finish.Y)
        end;
    end;

var
    BoardItem : TveBoardItem;

    procedure SetupLink;

    var X1,Y1 : integer;
        X2,Y2 : integer;
        StripIndex : integer;
        Strip : TcnStrip;
        StartStrip, EndStrip : TcnStrip;
        Link : TcnLink;
        Found : boolean;
    begin
        // ** find coords of link ends (X1,Y1) and (X2,Y2) **
        // X1,Y1
        X1 := BoardItem.X;
        Y1 := BoardItem.Y;

        // X2,Y2
        X2 := BoardItem.X + BoardItem.EndDeltaX;
        Y2 := BoardItem.Y + BoardItem.EndDeltaY;

        // search for a strips which contain ends of the link. Note: StartStrip
        // and EndStrip are arbitrary - we don't care which is start, end.
        StartStrip := nil;
        EndStrip := nil;
        Found := False;
        for StripIndex := 0 to FStrips.Count -1 do begin
            Strip := TcnStrip( FStrips[ StripIndex ] );

            if StartStrip = nil then begin
                if OnStrip( Strip, X1, Y1 ) then begin
                    StartStrip := Strip;
                end;
            end;
            if EndStrip = nil then begin
                if OnStrip( Strip, X2, Y2 ) then begin
                    EndStrip := Strip;
                end;
            end;

            if (StartStrip <> nil) and (EndStrip <> nil) then begin
                Found := True;
                break;
            end;
        end;

        if Found then begin
            Link := TcnLink(FLinks.AddNew( TcnLink ));
            Link.StartStrip := StartStrip;
            Link.EndStrip := EndStrip;
            Link.StartX := X1;
            Link.StartY := Y1;
            Link.EndX := X2;
            Link.EndY := Y2;
        end
        else begin
        // if either end of link has no strip, then either there is a bug in
        // BuildStrips() procedure, or one end of link is off the board or lies
        // on a non-strip location, including on a break cell. So do not create
        // the link at all - we want every link to have a StartX and StartY which
        // we can reference.
{$IFDEF DEBUG}
        // warning is useful when testing code - not a real error
//            raise TcnExcept.Create( 'Debug check : Link end not in Strip' );
{$ENDIF}
        end;
     end;

var
    i : integer;

begin
    // for each link,
    for i := 0 to FProject.BoardItemCount -1 do begin
        BoardItem := FProject.BoardItems[ i ];
        if BoardItem.Outline is TveLinkOutline then begin

            // build a TdrLink object to represent the link on board
            SetupLink;
        end;
    end;
end;


// Allocate a Net to Each StripSet, By Using Pin Data
// Method: For each stripset:
//    Scan along strips, assigning net of first pin encountered as stripset net.
//    Continue scanning, marking as error any pins that are in different nets.

procedure TConnectivity.NetsToStripSets;

    // scan along one strip - when a pin is encountered, and stripset does not
    // yet have a net, give the net of the pin to the entire stripset.
    // If a later pin is encountered that belongs to a different net, then
    // mark the cell as having an error.

    // Note: Strip belongs to StripSet.Strips : they are in the same net

    procedure IdentifyNets( StripSet : TcnStripSet; Strip : TcnStrip );

        // look at all pins that connect to this cell
        procedure ScanCell( pCell : PcnCellData );
        var
            i : integer;
            pPin : PcnPin;
            Outline : TveOutline;
            PinNet : TneNode;
        begin

            // cell already scanned because its end meets another strip
            if pCell^.Scanned then begin
                exit;
            end;

            // No pins on this cell, or an error already recorded.
            // Do nothing.
            if (pCell^.PinCount <= 0) or (pCell^.Error) then begin
                exit;
            end;

            // check all pins
            for i := 0 to pCell^.PinCount -1 do begin

                // mark as scanned
                pCell^.Scanned := True;

                // get pin number, outline, pin net
                pPin := @( pCell^.Pins[i] );
                Outline := pPin^.Item.Outline;
                PinNet := TneNode(pPin^.Item.NodeAtPin[ pPin^.PinIndex ]);

                // if we have a wire or link
                if ((Outline is TveLinkOutline) or (Outline is TveWireOutline)) then begin
                    continue;
                end
                else begin

                    // if stripset already reserved by a "no-net" pin
                    if StripSet.Status = nsMustNotAllocate then begin
                        pCell^.Error := True;
                    end

                    // if Stripset is is free, assign the pin net to it
                    else if StripSet.Status = nsAvailable then begin
                        StripSet.Net := PinNet;
                        // if "no net", reserve stripset
                        if PinNet = nil then begin
                            StripSet.Status := nsMustNotAllocate;
                        end
                        else begin
                            StripSet.Status := nsAllocated;
                        end;
                     end

                    // pin and StripSet have nets, check the nets are same
                    else begin
                        if StripSet.Net <> PinNet then begin
                            pCell^.Error := True;
                    end;
                end;
            end;
       end;
    end;

    var
        x, y : integer;
        pCell : PcnCellData;

    begin
        // horizontal strips
        if Strip.Direction = drHorizontal then begin

            // scan from start to finish
            y := Strip.Start.Y;
            for x := Strip.Start.X to Strip.Finish.X do begin
                pCell := @Cells[x,y];
                ScanCell( pCell );
            end;
        end

        // vertical strips
        else begin

            // scan from start to finish
            x := Strip.Start.X;
            for y := Strip.Start.Y to Strip.Finish.Y do begin
                pCell := @Cells[x,y];
                ScanCell( pCell );
            end;
        end;
    end;

var
  i: Integer;
  StripSet : TcnStripSet;
  j: Integer;
  Strip : TcnStrip;
begin

    // determine a net for each stripset. If no net determined, TcnStripset.Net
    // property is set to nil.
    for i := 0 to FStripSets.Count - 1 do begin

        StripSet := TcnStripSet( FStripSets[i] );

        // get strips in order required by scan.
        StripSet.SortByScanOrder;

        // trace every strip in the stripset (the first component pin
        // encountered will determine the net assigned to the entire stripset.
        // Trace from the strip start, because this is the left of a horizontal
        // strip, or the top of a vertical strip.
//        StripSet.Net := nil;

        for j := 0 to StripSet.Count - 1 do begin
            Strip := StripSet.Strips[j];
              IdentifyNets( StripSet, Strip );
        end;
    end;
end;



// ** Function Compares Wires By Value (wires with same value connect) **
function WireListCompareValues( P1, P2 : pointer ) : integer;
begin
    result := CompareText( TveBoardItem(P1).Value, TveBoardItem(P2).Value );
end;

procedure TConnectivity.BuildWireSets;

    // find strip at location (x,y)
    function StripAt( x, y : integer ) : TcnStrip;
    var
        StripIndex : integer;
        Strip : TcnStrip;

    begin
        // assume no strip found (break on cell or end off strip area)
        result := nil;

        // check for a break on the cell - no strip
        if brUnshifted in Cells[x,y].Break then begin
            exit;
        end;

        // search strips
        for StripIndex := 0 to FStrips.Count -1 do begin
            Strip := TcnStrip( FStrips[ StripIndex ] );

            // horizontal strip
            if Strip.Direction = drHorizontal then begin
                if (y = Strip.Start.Y) and (x >= Strip.Start.X) and (x <= Strip.Finish.X)
                    then begin
                    result := Strip;
                    break;
                end;
             end
            // vertical strip
            else begin
                if (x = Strip.Start.X) and (y >= Strip.Start.Y) and (y <= Strip.Finish.Y)
                    then begin
                    result := Strip;
                    break;
                end;
            end;
        end;
    end;

var
    i : integer;
    BoardItem : TveBoardItem;
    LastWireValue : string;
    WireValue : string;
    WireSet : TcnWireSet;
    Wire : TcnWire;
    WireStrip : TcnStrip;
begin
    // ..don't use .Clear - avoid memory reallocation
    AllWires.Count := 0;

    // get all wires into TList
    for i := 0 to FProject.BoardItemCount -1 do begin
        BoardItem := FProject.BoardItems[ i ];
        if BoardItem.Outline is TveWireOutline then begin
            AllWires.Add( BoardItem );
        end;
    end;

    // sort the TList so all wires in Value order
    AllWires.Sort( WireListCompareValues );

    // put wires with same Value into a separate WireSet since these are
    // all in the same Net.
    LastWireValue := '';
    WireSet := nil;
    for i := 0 to AllWires.Count -1 do begin

        BoardItem := TveBoardItem(AllWires[i]);
        WireStrip := StripAt( BoardItem.X, BoardItem.Y );

        // If no strip under our wire, (due to a break on same cell).
        // Omit this wire from the WireSet since with a nil WireStrip
        // net trace code crashes.  Anyway no strip is meaningless.
        // Mark cell as error so user will move wire or break.
        if WireStrip = nil then begin
            Cells[BoardItem.X, BoardItem.Y].Error := True;
            continue;
        end;

        WireValue := BoardItem.Value;

        // if wires have different value fields, belong to new net, so
        // make new WireSet.  If don't have a previous wire (first time in loop)
        // then need a new WireSet.
        if (WireSet = nil) or (WireValue <> LastWireValue) then begin

            WireSet := TcnWireSet(FWireSets.AddNew( TcnWireSet));
            WireSet.FNet := nil;
            // remove any old "wires" because we may be reusing an object
            WireSet.FWires.Clear;
            // started a block in sort order, containing this Value
            LastWireValue := WireValue;
        end;

        // add this wire to WireSet
        Wire := WireSet.CreateWire;
        Wire.X := BoardItem.X;
        Wire.Y := BoardItem.Y;
        Wire.Strip := WireStrip;
    end;

end;


procedure TConnectivity.PropagateNets;

    // handle nets at both ends of a link
    // Return True = a strip has had a net change made on this pass.
    // Keep calling for all links until returns False because no futher nets
    // resolved.

    function PropagateLinkNet( Link : TcnLink ) : boolean;
    var
        StartStripSet, EndStripSet : TcnStripSet;

    begin
        // assume nothing will change
        result := False;

        // if one end of link has no strip, get out - pointers are nil!
        if (Link.StartStrip = nil) or (Link.EndStrip = nil) then begin
            exit;
        end;

        // get local references to stripsets
        StartStripSet := Link.StartStrip.StripSet;
        EndStripSet := Link.EndStrip.StripSet;

        // if both ends of link are in same stripset, don't make a fuss, just
        // let it pass through - stripsets were already combined, or link
        // lies along a strip or between overlapping strips etc.
        if (StartStripSet = EndStripSet) then begin
            exit;
        end;

        // most common case first for speed
        // if strips have same nets allocated, can skip further checks
        if  (StartStripSet.Status = nsAllocated) and
            (EndStripSet.Status = nsAllocated) then begin

            // if stripsets have same net but are not combined, combine them
            if StartStripSet.Net = EndStripSet.Net then begin
                 AddToStripSet( StartStripSet , EndStripSet );
                result := True;
                exit;
            end

            // if nets are different, mark both ends as network error
            else begin
                // mark start of link as error
                Cells[Link.StartX, Link.StartY].Error := True;
                exit;
            end;
        end;

        // if neither strip has a net allocated, leave it till a later pass
        // when nets have propagated through links and wires
        if  (StartStripSet.Status = nsAvailable) and
            (EndStripSet.Status = nsAvailable) then begin
            exit;
        end;

        // if a strip belongs to a pin with no net allocated then error -
        // can't wire a floating pin
        if  (StartStripSet.Status = nsMustNotAllocate) then begin
            // mark start of link as error
            Cells[Link.StartX, Link.StartY].Error := True;
            exit;
        end;
        if  (EndStripSet.Status = nsMustNotAllocate) then begin
            // mark end of link as error
            Cells[Link.EndX, Link.EndY].Error := True;
            exit;
        end;

        // if only one strip has a net, combine no-net stripset with netted
        // stripset
        if (EndStripSet.Status = nsAvailable) then begin
            AddToStripSet( StartStripSet , EndStripSet );
            result := True;
            exit;
        end;
        if (StartStripSet.Status = nsAvailable) then begin
            AddToStripSet( EndStripSet, StartStripSet );
            // signal that net propagated through link !
            result := True;
            exit;
        end;
    end;


    function PropagateWireNet( WireSet : TcnWireSet ) : boolean;
    var
        i : integer;
        Wire : TcnWire;
        AllWiresHaveNets : boolean;
        NetsSame : boolean;
        LastNet : TneNode;
        NetKnown : boolean;
        StripSet : TcnStripSet;
        MasterStripSet : TcnStripSet;
    begin
        // default is no new nets propagated
        result := False;

        // test to see if all Wires in WireSet have a net allocated
        AllWiresHaveNets := True;
        NetsSame := True;
        LastNet := nil;
        for i := 0 to WireSet.WireCount -1 do begin
            Wire := WireSet.Wires[i];

            AllWiresHaveNets :=
                AllWiresHaveNets and (Wire.Strip.StripSet.Status = nsAllocated);

            if (AllWiresHaveNets) and (LastNet <> nil) then begin
                NetsSame := NetsSame and (Wire.Strip.StripSet.Net = LastNet);
            end;
            LastNet := Wire.Strip.StripSet.Net;
        end;

        // if all wires have same nets, combine stripsets
        if AllWiresHaveNets and NetsSame then begin

            MasterStripSet := WireSet.Wires[0].Strip.StripSet;
            for i := 1 to WireSet.WireCount - 1 do begin
                Wire := WireSet.Wires[i];
                if Wire.Strip.StripSet <> MasterStripSet then begin
                    AddToStripSet( MasterStripSet, Wire.Strip.StripSet );
                end;
            end;
            // although stripsets were combined, no nets were propagated,
            // so leave result as False.
            exit;
        end;

        // if all wires have nets, but nets different, mark all wires as error
        if AllWiresHaveNets then begin

            for i := 0 to WireSet.WireCount -1 do begin
                Wire := WireSet.Wires[i];
                Cells[Wire.X, Wire.Y].Error := True;
            end;
            exit;
        end;

        // mark as error any wires which are in strips with ssDoNotAllocate
        // - these strips belong to a single pin which has no net defined and
        // which should have no other connections to the strip.
        for i := 0 to WireSet.WireCount -1 do begin
            Wire := WireSet.Wires[i];
            if Wire.Strip.StripSet.Status = nsMustNotAllocate then begin
                Cells[Wire.X, Wire.Y].Error := True;
            end;
        end;

        // search for first valid net belonging to any wire
        // ...MasterStripSet variable initialised to prevent compiler warning
        MasterStripSet := nil;
        NetKnown := False;
        for i := 0 to WireSet.WireCount -1 do begin
            Wire := WireSet.Wires[i];
            if Wire.Strip.StripSet.Status = nsAllocated then begin

                // choose a StripSet that will have other stripsets combined
                // with it.
                MasterStripSet := Wire.Strip.StripSet;

                NetKnown := True;
                break;
            end;
        end;

        // if no wire has a net allocated, leave it till a later pass
        // when nets have propagated through links and wires
        if not NetKnown then begin
            exit;
        end;

        // combine all stripsets which connect via wires (thru this wireset)
        for i := 0 to WireSet.WireCount -1 do begin
            StripSet := WireSet.Wires[i].Strip.StripSet;
            if StripSet <> MasterStripset then begin
                AddToStripSet( MasterStripSet, StripSet );
                // signal that at least one net propagated through wires !
                result := True;
            end;
        end;
    end;

var
    Changed : boolean;
    i : integer;
begin
    repeat
        Changed := False;

        for i := 0 to FLinks.Count -1 do begin
            Changed := Changed or PropagateLinkNet( TcnLink(FLinks[i]) );
        end;

        for i := 0 to FWireSets.Count -1 do begin
            Changed := Changed or PropagateWireNet( TcnWireSet(FWireSets[i]) );
        end;
    until not Changed;
end;

{
function CompareStripSetsByNet( P1, P2 : pointer ) : integer;
var
    S1, S2 : TcnStripSet;
    Status1, Status2 : TcnStripNetStatus;
    PA, PB : PByte;

begin
    S1 := TcnStripSet(P1);
    S2 := TcnStripSet(P2);

    Status1 := S1.Status;
    Status2 := S2.Status;

    // unallocated nets and "no net" strips come last
    if (Status1 <> nsAllocated) and (Status2 <> nsAllocated) then begin
        result := 0;
    end
    else if (Status1 <> nsAllocated) then begin
        result := 1;
    end
    else if (Status2 <> nsAllocated) then begin
        result := -1;
    end
    // otherwise, compare nets as pointers - thus same nets will be adjacent
    // in sorted list
    else begin
        PA := pByte(TcnStripSet(P1).Net);
        PB := pByte(TcnStripSet(P2).Net);

        if (PA > PB) then begin
            result := 1;
        end
        else if PA < PB then begin
            result := -1;
        end
        else begin
            result := 0;
        end;
    end;
end;
}


function CompareStripSetsByNet( P1, P2 : pointer ) : integer;
var
    PA, PB : pChar;
begin
    PA := pChar(TcnStripSet(P1).Net);
    PB := pChar(TcnStripSet(P2).Net);

    if (PA > PB) then begin
        result := 1;
    end
    else if PA < PB then begin
        result := -1;
    end
    else begin
        result := 0;
    end;
end;

procedure TConnectivity.CombineStripSets;
var
    i : integer;
    MasterStripSet : TcnStripSet;
    StripSet : TcnStripSet;
    j : integer;
    Strip : TcnStrip;
begin

    // sort StripSets[], so same net stripsets are adjacent in array, with
    // nil net stripsets at lowest indexes
    FStripSets.Sort( CompareStripSetsByNet );

    // initialise for loop
    MasterStripSet := nil;

    // for every stripset in sorted list. We work from the top of the array
    // downwards, so we can delete array members without altering indexes of
    // lower items in array.
    for i := FStripSets.Count -1 downto 0 do begin

        StripSet := TcnStripSet( FStripSets[i] );

        // if reached an unassigned Strip, then no more strips with net in
        // sorted list, so all StripSets mergers have been completed
        if StripSet.Net = nil then begin
            break;
        end;

        // if StripSets have different nets, then MasterStripSet is finished,
        // and we need to move to the next Master
        if ((MasterStripSet = nil) or (StripSet.Net <> MasterStripSet.Net)) then begin
            MasterStripSet := StripSet;
            continue;
        end;

        // combine stripsets
        for j := 0 to StripSet.Count - 1 do begin
            Strip := StripSet.Strips[j];
            Strip.StripSet := MasterStripSet;
            MasterStripSet.AddStrip( Strip );
        end;
        FStripSets.Delete( i );
    end;
end;

procedure TConnectivity.FindFirstPins;
var
    Strip : TcnStrip;

    procedure ScanHorizontal;
    var
        x, y : integer;
    begin
        // default is start of strip - even if no pin there
        Strip.FirstPin := Strip.Start;

        y := Strip.Start.Y;
        for x := Strip.Start.x to Strip.Finish.x do begin
            if Cells[x,y].PinCount > 0 then begin
                Strip.FirstPin := Point( x,y );
                break;
            end;
        end;
    end;
    procedure ScanVertical;
    var
        x, y : integer;
    begin
        // default is start of strip - even if no pin there
        Strip.FirstPin := Strip.Start;

        x := Strip.Start.X;
        for y := Strip.Start.y to Strip.Finish.y do begin
            if Cells[x,y].PinCount > 0 then begin
                Strip.FirstPin := Point( x,y );
                break;
            end;
        end;
    end;

var
    i: Integer;
begin
    for i := 0 to FStrips.Count - 1 do begin
        Strip := Strips[i];

        if Strip.Direction = drHorizontal then begin
            ScanHorizontal;
        end
        else begin
            ScanVertical;
        end;
    end;
end;


procedure TConnectivity.DetectIslands;

    type TBridge = record
        LineStart : TPoint;
        LineFinish : TPoint;
        LengthDiv : Int64;
    end;

    // Find Shortest Line ("Connection") Between Strips from two StripSets
    procedure BridgeStripToStrip( StripSet1, StripSet2 : TcnStripSet; var Connection : TBridge);
    var
        i : integer;
        Strip1 : TcnStrip;
        j : integer;
        Strip2 : TcnStrip;
        DX, DY : Int64;
        LengthDiv : Int64;
    begin
        // start with a length that any connection will better
        Connection.LengthDiv := High( Connection.LengthDiv );

        // for every strip in StripSet1
        for i := 0 to StripSet1.Count - 1 do begin
            Strip1 := StripSet1[i];

            // find the distance to the start of each strip in StripSet2
            for j := 0 to StripSet2.Count -1 do begin
                Strip2 := StripSet2[j];

                // line between FirstPin points on strips
                // NOTE: we only connect to FirstPin points on strips
                DX := (Strip1.FirstPin.X - Strip2.FirstPin.X) * 1000;
                DY := (Strip1.FirstPin.Y - Strip2.FirstPin.Y) * 1000;
                // length is actually length squared
                LengthDiv := (DX * DX)+(DY * DY);

                // is this a shorter line - if so, keep it
                if LengthDiv < Connection.LengthDiv then begin
                    Connection.LengthDiv := LengthDiv;
                    Connection.LineStart := Point(
                        Strip1.FirstPin.X * DIVS_PER_CELL, Strip1.FirstPin.Y * DIVS_PER_CELL );
                    Connection.LineFinish := Point(
                        Strip2.FirstPin.X * DIVS_PER_CELL, Strip2.FirstPin.Y * DIVS_PER_CELL );
                end;
            end;
        end;
    end;

    // Find Shortest Line ("Connection") Between a Segment and a Strip belonging
    // to two StripSets
    procedure BridgeSegmentToStrip( StripSet1, StripSet2 : TcnStripSet; var Connection : TBridge);
    var
        i : integer;
        SegmentGroup : TbrSegmentGroup;
        j : integer;
        Segment : TbrSegment;

        k : integer;

        Strip : TcnStrip;

        CentreX, CentreY : integer;
        DX, DY : Int64;
        Distance : Int64;
    begin
        // start with a length that any connection will better
        Connection.LengthDiv := High( Connection.LengthDiv );

        // for every segment group in StripSet1
        for i := 0 to StripSet1.SegmentGroupCount - 1 do begin
            SegmentGroup := StripSet1.SegmentGroups[i];

            // for every segment in the segment group
            for j := 0 to SegmentGroup.Count - 1 do begin
                Segment := SegmentGroup.Segments[j];

                // for every strip in StripSet2
                for k := 0 to StripSet2.Count - 1 do begin
                Strip := StripSet2[k];

                    // work out the distance squared between segment centres
                    // don't divide by 2 here - do later to DX, DY
                    CentreX := (Segment.X1_1000 + Segment.X2_1000) div 2;
                    CentreY := (Segment.Y1_1000 + Segment.Y2_1000) div 2;

                    // we only connect to FirstPin on strip - can add code to
                    // check distance to start, or end, etc.
                    DX := CentreX - (Strip.FirstPin.X * 1000);
                    DY := CentreY - (Strip.FirstPin.Y * 1000);
                    Distance := DX*DX + DY*DY;
                    if Distance < Connection.LengthDiv then begin
                        Connection.LengthDiv := Distance;
                        Connection.LineStart := Point(CentreX, CentreY);
                        Connection.LineFinish :=
                            Point((Strip.FirstPin.X * 1000), (Strip.FirstPin.Y * 1000));
                    end;
                end;
            end;
        end;
    end;

    // Find Shortest Line ("Connection") Between Segments belonging
    // to two StripSets
    procedure BridgeSegmentToSegment( StripSet1, StripSet2 : TcnStripSet; var Connection : TBridge);
    var
        i : integer;
        SegmentGroup1 : TbrSegmentGroup;
        j : integer;
        Segment1 : TbrSegment;
        k : integer;
        SegmentGroup2 : TbrSegmentGroup;
        m : integer;
        Segment2 : TbrSegment;

        Centre1X, Centre1Y : integer;
        Centre2X, Centre2Y : integer;
        DX, DY : Int64;
        Distance : Int64;
    begin
        // start with a length that any connection will better
        Connection.LengthDiv := High( Connection.LengthDiv );

        // for every segment group in StripSet1
        for i := 0 to StripSet1.SegmentGroupCount - 1 do begin
            SegmentGroup1 := StripSet1.SegmentGroups[i];

            // for every segment in the segment group
            for j := 0 to SegmentGroup1.Count - 1 do begin
                Segment1 := SegmentGroup1.Segments[j];

                // for every segment group in StripSet2
                for k := 0 to StripSet2.SegmentGroupCount - 1 do begin
                    SegmentGroup2 := StripSet2.SegmentGroups[k];

                    for m := 0 to SegmentGroup2.Count - 1 do begin
                        Segment2 := SegmentGroup2.Segments[m];

                        // work out the distance squared between segment centres
                        // don't divide by 2 here - do later to DX, DY
                        Centre1X := Segment1.X1_1000 + Segment1.X2_1000;
                        Centre1Y := Segment1.Y1_1000 + Segment1.Y2_1000;
                        Centre2X := Segment2.X1_1000 + Segment2.X2_1000;
                        Centre2Y := Segment2.Y1_1000 + Segment2.Y2_1000;

                        DX := (Centre1X - Centre2X) div 2;
                        DY := (Centre1Y - Centre2Y) div 2;

                        Distance := DX*DX + DY*DY;

                        // if that distance is shorter, keep it
                        if Distance < Connection.LengthDiv then begin
                            Connection.LengthDiv := Distance;
                            Connection.LineStart := Point(Centre1X div 2, Centre1Y div 2);
                            Connection.LineFinish := Point(Centre2X div 2 , Centre2Y div 2);
                        end;
                    end;
                end;
            end;
        end;
    end;

    // find shortest bridge (line) between two stripsets
    procedure MakeIslandBridge( StripSet1, StripSet2 : TcnStripSet; var Connection : TBridge);
    begin
      // if StripSet1 has strip
      if StripSet1.Count > 0 then begin
          // if StripSet2 has strip
          if StripSet2.Count > 0 then begin
              // most common case - two strips
              BridgeStripToStrip( StripSet1, StripSet2, Connection );
          end
          // StripSet2 segment to StripSet1 strip
          else begin
              BridgeSegmentToStrip( StripSet2, StripSet1, Connection );
          end;
      end
      // if StripSet1 segment to StripSet2 strip
      else if StripSet2.Count > 0 then begin
              BridgeSegmentToStrip( StripSet1, StripSet2, Connection );
      end
      // StripSet1 segment to StripSet2 segment
      else begin
              BridgeSegmentToSegment( StripSet1, StripSet2, Connection );
      end;
    end;

    // find shortest bridges between the StripSets in FStripSets array,
    // given the indexes of the start and end of the block of stripsets
    procedure MakeIslandBridges( LowIndex, HighIndex : integer );
    var
        i : integer;
        StripSet : TcnStripSet;
        j : integer;
        CurrentConnection : TBridge;
        BestConnection : TBridge;
        IslandBridge : TcnIslandBridge;
    begin

        // EndIndex-1 means we leave last stripset - it will be connected to
        // by the
        for i := LowIndex to HighIndex -1 do begin

            // get a stripset
            StripSet := StripSets[i];

            // start with worst possible length
            BestConnection.LengthDiv := High( BestConnection.LengthDiv );

            // test connection length to every other stripset
            for j := i +1 to HighIndex do begin
                MakeIslandBridge( StripSet, StripSets[j], CurrentConnection );
                // remember shortest island bridge
                if BestConnection.LengthDiv > CurrentConnection.LengthDiv then begin
                    BestConnection := CurrentConnection;
                end;
            end;

            // record shortest island bridge
            IslandBridge := TcnIslandBridge( FIslandBridges.AddNew( TcnIslandBridge ));
//            IslandBridge.StartStrip := BestConnection.StartStrip;
//            IslandBridge.EndStrip := BestConnection.EndStrip;
            IslandBridge.Line1 := BestConnection.LineStart;
            IslandBridge.Line2 := BestConnection.LineFinish;
        end;
    end;

var
    i : integer;
    StripSet : TcnStripSet;

    CurrentNet : TneNode;
    HighIndex : integer;
    LowIndex : integer;
    InBlock : boolean;

begin
    // sort StripSets[], so same net stripsets are adjacent in array, with
    // nil net stripsets at lowest indexes
    FStripSets.Sort( CompareStripSetsByNet );

    // initialise for loop
    CurrentNet := nil;

    // in block
    InBlock := False;

    // prevent "variable might not be initialised" warning
    HighIndex := 0;

    // for every stripset in sorted list. We work from the top of the array
    // downwards, so we can delete array members without altering indexes of
    // lower items in array.
    i := FStripSets.Count -1;
    while i >= 0 do begin
        StripSet := TcnStripSet( FStripSets[i] );

        // currently in a block
        if InBlock then begin

            // net has changed, means block has ended
            if StripSet.Net <> CurrentNet then begin

                // previous block ending
                LowIndex := i +1;

                // if more than 1 element in block
                if LowIndex < HighIndex then begin
                    MakeIslandBridges( LowIndex, HighIndex );
                end;

                // start new block
                if StripSet.Net = nil then begin
                    //InBlock := False;
                    exit;
                end;

                HighIndex := i;
                CurrentNet := StripSet.Net;
            end;

            // net has not changed.. keep scanning
        end

        // not in a block (just starting, or no blocks at all
        else begin
            // never started a block, and no net (first item has no net)
            // nothing to do
            if StripSet.Net = nil then begin
                exit;
            end;

            // start a block
            InBlock := True;
            HighIndex := i;
            CurrentNet := StripSet.Net;
        end;
        // finish any possible

        // loop
        Dec( i );
    end;

    // finished a block when loop ended, have i=-1
    if (i = -1) and (HighIndex > 0) and InBlock then begin
        MakeIslandBridges( 0, HighIndex );
    end;

{
        // combine stripsets
        for j := 0 to StripSet.Count - 1 do begin
            Strip := StripSet.Strips[j];
            Strip.StripSet := MasterStripSet;
            MasterStripSet.AddStrip( Strip );
        end;
        FStripSets.Delete( i );
}
end;

procedure TConnectivity.Clear;
var
    x, y : integer;
begin
    if (OldWidth < FProject.BoardWidth) or (OldHeight < FProject.BoardHeight) then begin
        SetLength( Cells, FProject.BoardWidth + 50, FProject.BoardHeight + 50);
        OldWidth := FProject.BoardWidth;
        OldHeight := FProject.BoardHeight;
    end;

    // fill Cells array with zeros
    for x := 0 to FProject.BoardWidth -1 do begin
        for y := 0 to FProject.BoardHeight - 1 do begin
            FillChar( Cells[x, y], sizeof(TcnCellData), 0 );
        end;
    end;

    FStrips.Clear;
    FStripSets.Clear;
    FLinks.Clear;
    FWireSets.Clear;
    FIslandBridges.Clear;
//    FNetSets : TManagedList; // cleared elsewhere
//    AllWires : TList;        // cleared elsewhere
    FSegmentSets.Clear;
    FErrors.Clear;
end;

procedure TConnectivity.Check;
begin
    // we can only do design rule check if we have Project and Netlist
    if not Assigned( FProject ) then begin
        exit;
    end;
    Netlist := FProject.Netlist;

    // set size of PinCells and BadCells arrays
    // we can speed this up by only calling SetLength when BoardWidth,
    // BoardHeight increase.
    // SetLength( Cells, FProject.BoardWidth, FProject.BoardHeight );

    Clear;

{$IFDEF DEBUGFORM}
    if Assigned( FOnDebugStart ) then begin
        FOnDebugStart;
    end;
{$ENDIF}

//    DebugBoard;

    // read all pin data into Cells[][]
    BuildPins;

    // mark as error where a break coincides with pin
    CheckBreaksOnPins;

    // copy over striprsets from Board StripGroups. Mark strips that include
    // a break as Broken.
    BuildStrips;


    // *********<<<<<<<
//    DebugStripSets;
    // *********<<<<<<<

    // rescan Broken stripsets into new stripsets
    RescanBrokenStripSets;

    // build a SegmentSet for each TbrBoard.SegmentGroup
    BuildSegmentSets;

    // *********<<<<<<<
//      DebugSegmentSets;
//    DebugStripSets;
    // *********<<<<<<<

    // record Pin to Segment connections
    ConnectSmdPinsToSegments;

    // *********<<<<<<<
//    DebugStripSets;
    // *********<<<<<<<

    // connect strips together using segments
    CombineStripsetsBySegments;

    // build an array of link objects, and record on each the start and end
    // strips (or stripsets)
    BuildLinks;

    // *********<<<<<<<
//      DebugStripSets;
    // *********<<<<<<<


    // Scan along strips, assigning net of first pin encountered as stripset net
    // assign a net to each stripset, by scanning in correct order, and using
    // net of first pin encountered. Continue scanning each stripset, marking
    // as error, cells with pins belonging to other nets.
    NetsToStripSets;

    // group connected wires to form wiresets
    BuildWireSets;

    // propagate nets through links and wires and on to stripsets
    PropagateNets;

    // find first pin from left or top of strip, for later use as connectivity
    // line end point
    FindFirstPins;

    // Detect Islands
    DetectIslands;

    // *********<<<<<<<
//    DebugStripSets;
//    DebugLinks;
    // *********<<<<<<<

    // CombineStripSets
//    CombineStripSets;

{$IFDEF DEBUGFORM}
    if Assigned( FOnDebugEnd ) then begin
        FOnDebugEnd;
    end;
{$ENDIF}
end;


// Given a board item which displays a link, find the netlist node of that
// link.  Available for editor to use.

function TConnectivity.NodeByLink( Item : TveBoardItem ) : TneNode;
var
  X1 : integer;
  Y1 : integer;
  X2 : integer;
  Y2 : integer;
  i : integer;
  Link: TcnLink;
  Found : boolean;
begin
    // default is fail condition
    result := nil;

    // must really be a link
    if not (Item.Outline is TveLinkOutline) then begin
        exit;
    end;

    // get start, end coords of our link
    X1 := Item.X;
    Y1 := Item.Y;
    X2 := Item.X + Item.EndDeltaX;
    Y2 := Item.Y + Item.EndDeltaY;

    // find a link record with same coords
    Found := False;
    Link := nil;
    for i := 0 to FLinks.Count - 1 do begin
        Link := TcnLink( FLinks[i] );
        if (
            ((Link.StartX = X1) and (Link.StartY = Y1) and
            (Link.EndX = X2) and (Link.EndY = Y2))
            or
            ((Link.StartX = X2) and (Link.StartY = Y2) and
            (Link.EndX = X1) and (Link.EndY = Y1))
            ) then begin

            Found := True;
            break;
        end;
    end;

    if not Found then begin
        exit;
    end;

    // determine net : both ends of link must have non-error connection to
    // same stripset
    if  (
        Cells[X1,Y1].Error or Cells[X2,Y2].Error or
        (Link.StartStrip = nil) or (Link.EndStrip = nil) or
        (Link.StartStrip.StripSet = nil) or (Link.EndStrip.StripSet = nil) {or
        (Link.StartStrip.StripSet <> Link.EndStrip.StripSet)}
        )
        then begin
        exit;
    end;
    // take net of stripset that both strips belong to
    result := Link.StartStrip.StripSet.Net;
end;


// Given a board item which displays a wire, find the netlist node of that
// wire.  Available for editor to use.

function TConnectivity.NodeByWire( Item : TveBoardItem ) : TneNode;
var
    X, Y : integer;
    i : integer;
    WireSet : TcnWireSet;
    j : integer;
    Wire: TcnWire;
begin
    // default is fail condition
    result := nil;

    // must really be a link
    if not (Item.Outline is TveWireOutline) then begin
        exit;
    end;

    // find coords of our wire
    X := Item.X;
    Y := Item.Y;

    // if our wire is sitting on an error location, we cannot be sure
    // of its net
    if Cells[X,Y].Error then begin
        exit;
    end;

    // search all wiresets for our wire
    for i := 0 to FWireSets.Count - 1 do begin
        WireSet := TcnWireSet( FWireSets[i] );

        for j := 0 to WireSet.WireCount - 1 do begin
            Wire := WireSet.Wires[j];
            if (Wire.X = X) and (Wire.Y = Y) then begin
                result := Wire.Strip.StripSet.Net;
                exit;
            end;
        end;
    end;

    // our wire not found !  returns nil result
end;

// given a netlist node, return a reference to the StripSet belonging to that node

function TConnectivity.StripSetByNode( Node : TneNode ) :  TcnStripSet;
var
  i : integer;
  StripSet : TcnStripSet;
begin
    for i := 0 to StripSetCount -1 do begin
        StripSet := StripSets[i];
        if StripSet.Net = Node then begin
            result := StripSet;
            exit;
        end;
    end;
    result := nil;
end;

// ************************************************
//        StripAt() - find strip at location (x,y)
// ************************************************
function TConnectivity.StripAt( x, y : integer ) : TcnStrip;
var
    StripIndex : integer;
    Strip : TcnStrip;

begin
    // assume no strip found (break on cell or end off strip area)
    result := nil;

    // x,y must be within border
    if (x < 0) or (x >= OldWidth) or (y < 0) or (y>= OldHeight) then begin
        exit;
    end;

    // check for a break on the cell - no strip
    if brUnshifted in Cells[x,y].Break then begin
        exit;
    end;

    // search strips
    for StripIndex := 0 to FStrips.Count -1 do begin
        Strip := TcnStrip( FStrips[ StripIndex ] );

        // horizontal strip
        if Strip.Direction = drHorizontal then begin
            if (y = Strip.Start.Y) and (x >= Strip.Start.X) and (x <= Strip.Finish.X)
                then begin
                result := Strip;
                break;
            end;
         end
        // vertical strip
        else begin
            if (x = Strip.Start.X) and (y >= Strip.Start.Y) and (y <= Strip.Finish.Y)
                then begin
                result := Strip;
                break;
            end;
        end;
    end;
 end;

// ***********************************************
//      EMIT DEBUG INFO FOR ALL STRIPSETS
// ***********************************************

procedure TConnectivity.DebugLine( const s : string );
begin
    if Assigned( FOnDebugLineOut ) then begin
        FOnDebugLineOut( s );
    end;
end;

// ***********************************************
//      EMIT DEBUG INFO FOR ALL STRIPSETS
// ***********************************************

// Show all stripsets, for each showing each stripset and the strips it contains

procedure TConnectivity.DebugStripSets;

    procedure Line( const s : string );
    begin
        FOnDebugLineOut( s );
    end;

const
    StripNetStatus2String : array[TcnStripNetStatus] of string =
    ( 'nsAvailable', 'nsMustNotAllocate', 'nsAllocated' );

    Direction2String : array[TcnDirection] of string =
    ( 'drHorizontal', 'drVertical' );

var
    i, j, k : integer;
    StripSet : TcnStripSet;
    Strip : TcnStrip;
    SegmentGroup : TbrSegmentGroup;
    Segment : TbrSegment;
begin
    if not Assigned( FOnDebugLineOut ) then begin
        exit;
    end;

    Line( '****** DEBUG STRIPSETS ******' );


    for i := FStripSets.Count -1 downto 0 do begin

        // get stripset
        StripSet := TcnStripSet( FStripSets[i] );
        Line( Format( 'StripSet %d, address: %p', [i,pointer(StripSet)] ));

        // display stripset properties
        if StripSet.Net = nil then begin
            Line( Format( '  net   : %s', ['nil'] ));
        end
        else begin
            Line( Format( '  net   : %s', [StripSet.Net.Name] ));
        end;
        Line( Format( '  broken: %d', [Ord(StripSet.Broken)] ));
//        Line( Format( '  broken: %d, status %s',
//            [Ord(StripSet.Broken), StripNetStatus2String[StripSet.Status]] ));
        Line( Format( '  status: %s', [StripNetStatus2String[StripSet.Status]] ));

        // display strips
        Line( Format( '  strips...', [] ));

        for j := 0 to StripSet.Count - 1 do begin
            Strip := StripSet.Strips[j];

            // display strip properties
            Line( Format( '    (%2d,%2d), (%2d,%2d)',
                [Strip.Start.X, Strip.Start.Y, Strip.Finish.X, Strip.Finish.Y] ));
            Line( Format( '    direction: %s', [Direction2String[Strip.Direction]] ));
            Line( Format( '    scanned  : %d', [Ord(Strip.Scanned)] ));
//            Line( Format( '    stripset : %p', [@Strip.StripSet] ));
        end;

        // display segments
        Line( Format( '  segment groups...', [] ));
        for j := 0 to StripSet.SegmentGroupCount - 1 do begin

            SegmentGroup := StripSet.SegmentGroups[j];
            for k := 0 to SegmentGroup.Count - 1 do begin
                Segment := SegmentGroup.Segments[k];

                Line( Format('    segment...', [] ));
                Line( Format('      (%d,%d),(%d,%d)',
                [Segment.X1_1000,Segment.Y1_1000,Segment.X2_1000,Segment.Y2_1000] ));
                Line( Format('      width %d', [Segment.Width_1000]) );

                Line( Format('      TrackIntersections: (%d,%d),(%d,%d)',
                [Segment.TrackIntersection[0].X,Segment.TrackIntersection[0].Y,
                 Segment.TrackIntersection[1].X,Segment.TrackIntersection[1].Y ]));
            end;
        end;
    end;
end;

// ***********************************************
//      EMIT DEBUG INFO FOR ALL BOARD SEGMENTS
// ***********************************************
procedure TConnectivity.DebugSegmentSets;

    procedure Line( const s : string );
    begin
        FOnDebugLineOut( s );
    end;

const
    StripNetStatus2String : array[TcnStripNetStatus] of string =
    ( 'nsAvailable', 'nsMustNotAllocate', 'nsAllocated' );

var
    i, j : integer;
    SegmentSet : TcnSegmentSet;
    SegmentGroup : TbrSegmentGroup;
    Segment : TbrSegment;
begin
    if not Assigned( FOnDebugLineOut ) then begin
        exit;
    end;

    Line( '***** Segment Sets ******' );

    for i := 0 to SegmentSetCount - 1 do begin
        SegmentSet := SegmentSets[i];

        Line( 'SegmentSet ...' );

        // net
        if SegmentSet.Net = nil then begin
            Line( Format( '  net : %s', ['nil'] ));
        end
        else begin
            Line( Format( '  net : %s', [SegmentSet.Net.Name] ));
        end;

        // status
        Line( Format( '  Status : %s', [StripNetStatus2String[SegmentSet.Status] ] ));

        // SegmentGroup
        Line( Format( '  segment groups...', [] ));
        SegmentGroup := SegmentSet.SegmentGroup;

        for j := 0 to SegmentGroup.Count - 1 do begin

            Segment := SegmentGroup.Segments[j];

            Line( Format('    segment...', [] ));
            Line( Format('      (%d,%d),(%d,%d)',
            [Segment.X1_1000,Segment.Y1_1000,Segment.X2_1000,Segment.Y2_1000] ));
            Line( Format('      width %d', [Segment.Width_1000]) );

            Line( Format('      TrackIntersections: (%d,%d),(%d,%d)',
            [Segment.TrackIntersection[0].X,Segment.TrackIntersection[0].Y,
             Segment.TrackIntersection[1].X,Segment.TrackIntersection[1].Y ]));
        end;
    end;
end;


// ***********************************************
//      EMIT DEBUG INFO FOR ALL BOARD SEGMENTS
// ***********************************************

// Show all stripsets, for each showing each stripset and the strips it contains

procedure TConnectivity.DebugBoard;

    procedure Line( const s : string );
    begin
        FOnDebugLineOut( s );
    end;

var
    Board : TbrBoard;
    i, j : integer;
    SegmentGroup : TbrSegmentGroup;
    Segment : TbrSegment;
begin
    if not Assigned( FOnDebugLineOut ) then begin
        exit;
    end;

    Board := FProject.Board;

{
    // show segment groups as text
    for i := 0 to Board.SegmentGroupCount -1 do begin
        SegmentGroup := Board.SegmentGroups[i];

        Line( Format('segment Group ...', [] ));

        for j := 0 to SegmentGroup.Count - 1 do begin

            Segment := SegmentGroup.Segments[j];

            Line( Format('  segment...', [] ));
            Line( Format('    (%d,%d),(%d,%d)',
            [Segment.X1_1000,Segment.Y1_1000,Segment.X2_1000,Segment.Y2_1000] ));
            Line( Format('    width %d', [Segment.Width_1000]) );

            Line( Format('    TrackIntersections: (%d,%d),(%d,%d)',
            [Segment.TrackIntersection[0].X,Segment.TrackIntersection[0].Y,
             Segment.TrackIntersection[1].X,Segment.TrackIntersection[1].Y ]));
        end;
    end;
}
    // show segment groups as CSV
    for i := 0 to Board.SegmentGroupCount -1 do begin
        SegmentGroup := Board.SegmentGroups[i];

         for j := 0 to SegmentGroup.Count - 1 do begin

            Segment := SegmentGroup.Segments[j];

            Line( Format( '%d,%p,%d,%d,%d,%d,%d,%d,%d,%d,%d',
            [
            i, pointer(Segment),
            Segment.X1_1000,Segment.Y1_1000,Segment.X2_1000,Segment.Y2_1000,
            Segment.Width_1000,
            Segment.TrackIntersection[0].X,Segment.TrackIntersection[0].Y,
            Segment.TrackIntersection[1].X,Segment.TrackIntersection[1].Y
            ] ));
        end;
    end;
end;

// ***********************************************
//      EMIT DEBUG INFO FOR ALL LINKS
// ***********************************************

// Show all links, for each showing start, end, stripset, net
procedure TConnectivity.DebugLinks;
var
  i : integer;
  Link : TcnLink;
  NetName : string;
begin
    for i := 0 to LinkCount -1 do begin
        Link := Links[i];

        if Link.StartStrip.StripSet.Net = nil then begin
          NetName := 'nil';
        end
        else begin
          NetName := Link.StartStrip.StripSet.Net.Name;
        end;

        DebugLine( Format( '{%5d,%5d), (%5d,%5d), %p, %s',
        [
        Link.FStartX, Link.StartY, Link.EndX, Link.EndY,
        pointer(Link.StartStrip.StripSet), NetName
        ] ));
    end;
end;


// ***************************************************
//              GENERATE SEGMENT SETS
// ***************************************************

// Each SegmentSet exactly represents a single TbrBoard.SegmentGroup
procedure TConnectivity.BuildSegmentSets;
var
    Board : TbrBoard;
    i : integer;
    SegmentSet : TcnSegmentSet;
begin
    Board := FProject.Board;
    for i := 0 to Board.SegmentGroupCount - 1 do begin
        // Make a SegmentSet that represents the SegmentGroup
        SegmentSet := TcnSegmentSet( FSegmentSets.AddNew( TcnSegmentSet ) );
        SegmentSet.Net := nil;
        SegmentSet.Status := nsAvailable;
        SegmentSet.SegmentGroup := Board.SegmentGroups[i];
    end;
end;

{
    Assign nets to segment groups by looking for intersection between every SMD
    pin and every segment. If a segment group joins two SMD pins that are in
    not in the same net, draw an error circle one on of the SMD pins.

    // This function leaves:
    - some SMD pins marked as errors
    - some segmentSets assigned a net or status of ssMustNotAllocate
}

procedure TConnectivity.ConnectSmdPinsToSegments;

    procedure AddError( PinRect : TRect );
    var
        Error : TcnError;
    begin
        Error := TcnError(FErrors.AddNew(TcnError) );
        Error.XDiv := (PinRect.Left + PinRect.Right) div 2;
        Error.YDiv := (PinRect.Top + PinRect.Bottom) div 2;
    end;

var
    i : integer;
    Item : TveBoardItem;
    SmdOutline : TveSmdOutline;
    PinRect : TRect;
    PinIndex : integer;
    j : integer;
    SegmentSet : TcnSegmentSet;
    k : Integer;
    Segment : TbrSegment;
begin
    // stop unitialised variable warning
    PinIndex := 0;

    // for every SMD component
    for i := 0 to FProject.BoardItemCount -1 do begin

        Item := FProject.BoardItems[i];
        if Item.Outline is TveSmdOutline then begin

            SmdOutline := TveSmdOutline(Item.Outline);

            // for each pin of the Item
            SmdOutline.ToFirstPin;
            while SMDOutline.GetNextPinDiv( Item, PinRect, PinIndex ) do begin

                // for each segment set
                for j := 0 to SegmentSetCount - 1 do begin

                    SegmentSet := SegmentSets[j];


                    // for each segment in the segment set
                    for k := 0 to SegmentSet.SegmentGroup.Count - 1 do begin

                        // if segment connects to our pin
                        Segment := SegmentSet.SegmentGroup.Segments[k];

                        if SegmentToRect( Segment, PinRect ) then begin

                            // if our SegmentSet has no net so far, assign
                            // it the net of the pin
                            if SegmentSet.Status = nsAvailable then begin
                                SegmentSet.Net := TneNode(Item.NodeAtPin[PinIndex]);
                                if SegmentSet.Net = nil then begin
                                    SegmentSet.Status := nsMustNotAllocate;
                                end
                                else begin
                                    SegmentSet.Status := nsAllocated;
                                end;
                            end

                            // if our segmentSet already has a different net
                            // or is not available, record an error at the pin
                            else if ((SegmentSet.Status = nsAllocated) and
                                (SegmentSet.Net <> Item.NodeAtPin[PinIndex])) or
                                (SegmentSet.Status = nsMustNotAllocate)
                                then begin
                                // mark pin as error
                                // add error at PinRect();
                                AddError( PinRect );
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
end;


end.

