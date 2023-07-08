unit NetlistGenerate;

interface

uses Project, Netlist, Tracer;

type TneNetlistGenerator = class

protected
  procedure LoadComponents;
  procedure LoadStripSets;
  procedure DeleteSinglePinNodes;
public
  Project : TveProject;
  Tracer : TveTracer;
  Netlist : TneNetlist;
  procedure Execute;
  constructor Create;
  destructor Destroy; override;
end;


implementation

uses Outlines, Connective, SysUtils;

{
To generate a netlist:

;


  - run TveTracer(TVeProjet.ConnectivityObject).CheckSimple because this ignores
  the netlist.

  - Now look at the TveTracer members defined in the TveConnectivity ancestor
  class.

    property StripSetCount : integer read GetStripSetCount;
    property StripSets[index : integer] : TcnStripSet read GetStripSet;

    A StripSet is A Group of Strips and SegmentGroups in the Same Net

    for i := 0 to Tracer.StripSetCount -1 do begin

        StripSet := Tracer.StripSets[i];
        // assign a net to this StripSet
        Node := Netlist.CreateNode;

        // strips
        for j := 0 to StripSet.Count -1 do begin
            Strip := StripSet.Strips[j];

            // look for component pins lying on that strip
            if Strip.Direction := drHorizontal then begin
                for x := Strip.Start.X to Strip.End.X do begin
                    Cell := Tracer.Cells[x, Strip.Start.Y]
                    RegisterCell( Cell );
                end;

            // drVertical
            else begin
                for y := Strip.Start.Y to Strip.End.Y do begin
                    Strip.Start.X,y
                    Cell := Tracer.Cells[x, Strip.Start.Y]
                    RegisterCell( Cell );
                end;
            end;
        end;

        TcnStripSet
        property SegmentGroupCount : integer read GetSegmentGroupCount;
        property SegmentGroups[index : integer] : TbrSegmentGroup

        brSegmentGroup
        property Segments[i : integer] : TbrSegment read GetSegment;
        property Count : integer read GetCount;

    end;

    procedure RegisterCell( Cell : TcnCellData );
    begin
        for i := 0 to Cell.PinCount -1 do begin
            Pin := Cell.Pins[i];
            Pin.Item.Outline.Pins[PinIndex].Name;
            // put this pin in the netlist
            Metlist.CreatePin()

        end;
    end;

        // component pin data (PinCount number of filled array entries)
        Pins : array[0..PINS_PER_CELL-1] of TcnPin;
     Cells : array of array of TcnCellData;


    TneNetList
    function CreateNode : TneNode;
    function CreateComponent : TneComponent;
    function CreatePin(
        Node : TneNode; Component : TneComponent; const PinName : string ) : TnePin;

     }

// ************************************************
//           LOAD NETLIST FROM PROJECT
// ************************************************


// ******* Add Every Component to Netlist *********

procedure TneNetlistGenerator.LoadComponents;
var
    i : integer;
    Item : TveBoardItem;
    Component : TneComponent;
begin
  for i := 0 to Project.BoardItemCount -1 do begin
      Item := Project.BoardItems[i];
      if Item.Outline.UserDefined then begin
          Component := Netlist.CreateComponent;
          Component.Name := Item.Designator;
      end;
  end
end;

{
from Connective.pas
TcnStripSet
property SegmentGroupCount : integer read GetSegmentGroupCount;
property SegmentGroups[index : integer] : TbrSegmentGroup

from Board.pas
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

Note Connective.pas - assigns SMD pin nets to segment groups. However, does
not record which pins are connected to which segments.



}

// ******* Add StripSet (Net & Pin) Info to Netlist *******

procedure TneNetlistGenerator.LoadStripSets;
var
    NodeIndex : integer;
    Node : TneNode;

  // if we don't have a node, create it
  procedure EnsureNode;
  begin
      if Node = nil then begin
          // assign a net to this StripSet
          Node := Netlist.CreateNode;
          Node.Name := Format( 'N%5.5d', [NodeIndex] );
      end;
  end;

  // put cell pins into the node, return number of pins so put
  // CheckOnly = True, don't put pin into Node, just count it for return value
  function RegisterCell( Cell : TcnCellData; CheckOnly : boolean ) : integer;
  var
      i : integer;
      Pin : TcnPin;
      Item : TveBoardItem;
      NetItem : TneComponent;
  begin
      result := 0;

      // join pins to node and component in Netlist object
      for i := 0 to Cell.PinCount -1 do begin
          Pin := Cell.Pins[i];
          Item := Pin.Item;
          NetItem := Netlist.ComponentByName( Item.Designator );

          if Item.Outline.UserDefined then begin
              Inc( result );
              if not CheckOnly then begin
                  Netlist.CreatePin( Node, NetItem, Item.Outline.Pins[Pin.PinIndex].Name );
              end;
          end;
      end;
  end;

  // store all pins on current node, and return number of pins so stored
  // CheckOnly = True, don't put pins into Node, just count for return value
  function RegisterStrip( Strip : TcnStrip; CheckOnly : boolean ) : integer;
  var
      x, y : integer;
      Cell : TcnCellData;
  begin
    result := 0;

    // look for component pins lying on that strip
    if Strip.Direction = drHorizontal then begin
        for x := Strip.Start.X to Strip.Finish.X do begin
            Cell := Tracer.Cells[x, Strip.Start.Y];
            Inc( result, RegisterCell( Cell, CheckOnly ) );
        end;
    end
    // drVertical
    else begin
        for y := Strip.Start.Y to Strip.Finish.Y do begin
            Cell := Tracer.Cells[Strip.Start.X, y];
            Inc( result, RegisterCell( Cell, CheckOnly ) );
        end;
    end;
  end;

  // store all pins on current node, and return number of pins so stored
  // CheckOnly = True, don't put pins into Node, just count for return value
  function RegisterStripSet( StripSet : TcnStripSet; CheckOnly : boolean ) : integer;
  var
    j : integer;
    Strip : TcnStrip;
  begin
      result := 0;

      // strips
      for j := 0 to StripSet.Count -1 do begin
          Strip := StripSet.Strips[j];
          Inc( result, RegisterStrip( Strip, CheckOnly ) );
      end;

      // segments - ADD CODE HERE
  end;

var
    StripSet : TcnStripSet;
begin

  // A StripSet is A Group of Strips and SegmentGroups in the Same Net
  for NodeIndex := 0 to Tracer.StripSetCount -1 do begin

      // we may not need to create a node, so reference to nil for a start
      Node := nil;

      StripSet := Tracer.StripSets[NodeIndex];

      if RegisterStripSet( StripSet, True ) > 1 then begin
          EnsureNode;
          RegisterStripSet( StripSet, False );
      end;
  end;
end;

// ************************************************
//     DELETE NODES WITH LESS THAN 2 PINS
// ************************************************

procedure TneNetlistGenerator.DeleteSinglePinNodes;
var
  i : integer;
  Node : TneNode;
begin
  for i := 0 to Netlist.NodeCount - 1 do begin
      Node := Netlist.Nodes[i];
      if Node.PinCount <= 1 then begin
          Netlist.DeleteNode( Node );
      end;
  end;
end;


// ************************************************
//     FILL NETLIST WITH COMPONENTS, PINS, NETS
// ************************************************
procedure TneNetlistGenerator.Execute;
begin
    TveTracer(Project.ConnectivityObject).CheckSimple;
    LoadComponents;
    LoadStripSets;
//        DeleteSinglePinNodes;
end;


// ************************************************
//             CREATE, DESTROY
// ************************************************

constructor TneNetlistGenerator.Create;
begin
    Netlist := TneNetlist.Create;
end;

destructor TneNetlistGenerator.Destroy;
begin
    Netlist.Free;
    inherited;
end;


end.



