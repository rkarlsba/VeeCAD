unit Netlist;

interface

uses SysUtils, Classes;

type

EneError = class(Exception);


TneNode = class;
TneComponent = class;

TnePin = class
private
    FName : string;
    FNode : TneNode;
    FComponent : TneComponent;
public
    property Name : string read FName write FName;
    property Component : TneComponent read FComponent write FComponent;
    property Node : TneNode read FNode write FNode;
end;

TneNode = class
private
    FName : string;
    FPins : TList;
    function GetPinCount : integer;
    function GetPin( index : integer ) : TnePin;
public
    property Name : string read FName write FName;
    property PinCount : integer read GetPinCount;
    property Pins[index : integer] : TnePin read GetPin;
    procedure Sort;
    constructor Create;
    destructor Destroy; override;
end;

TneComponent = class
private
    FName : string;
    FPins : TList;
    function GetPinCount : integer;
    function GetPin( index : integer ) : TnePin;
public
    property Name : string read FName write FName;
    property PinCount : integer read GetPinCount;
    property Pins[index : integer] : TnePin read GetPin;
    procedure SortNodes;
    procedure SortPinNos;
    constructor Create;
    destructor Destroy; override;
end;


type
TneNetList = class
private
    FNodes : TList;
    FComponents : TList ;

    // property handlers
    function GetNodeCount : integer;
    function GetNode( index : integer ) : TneNode;
    function GetComponentCount : integer;
    function GetComponent( index : integer ) : TneComponent;

    // internal functions
    function EquivalentNode( SourceNode : TneNode ) : TneNode;

public
    const ColoredNodeCount = 6;
    var ColoredNodes : array[0..ColoredNodeCount-1] of TneNode;

    property NodeCount : integer read GetNodeCount;
    property Nodes[index : integer] : TneNode read GetNode;

    property ComponentCount : integer read GetComponentCount;
    property Components[index : integer] : TneComponent read GetComponent;

//    property PinCount : integer read GetPinCount;
//    property Pins[index : integer] : TnePin read GetPin;

    function CreateNode : TneNode;
    function CreateComponent : TneComponent;
    function CreatePin(
        Node : TneNode; Component : TneComponent; const PinName : string ) : TnePin;

    procedure DeleteNode( value : TneNode );
    procedure DeleteComponent( value : TneComponent );
    procedure DeletePin( value : TnePin );


    function ComponentByName( const Name : string ) : TneComponent;
    function NodeByName( const Name : string ) : TneNode;

    procedure Clear;
    procedure SortNodes;
    procedure SortComponentsByNode;
    procedure SortComponentsByPinNo;
    function Validate( report : TStrings ) : boolean;

    procedure GetEquivalentColoredNets( SourceNetlist : TneNetlist );
    procedure Clone( Source : TneNetlist );

    constructor Create;
    destructor Destroy; override;
end;


implementation

uses SortCompare, Windows;

(*
    A Netlist contains

    1. Array of Components[] - each component representing a part on schematic.

    2. Array of Nodes[] - each node being a circuit "Net".

    3. Array of Pins[] - each pin connecting a component and a node.


    We add a component with CreateComponent
    We add a node with CreateNode
    We add a pin with CreatePin : the pin connects a node to a component
        and both the node and the component must exist when CreatePin called

    To remove a component, node or pin, call its destructor via .Free .

NO**  TneComponent.Free causes any pins connecting the component to be destroyed.

YES** TneNode.Free causes any pins connecting the node to be destroyed.

NO** TnePin.Free causes the pins to be removed the from Component and Node

    Pins[] arrays.

    Locate a Component or Node by name with ComponentByName and NodeByName.

*)

// *****************************************
//              TnePin CLASS
// *****************************************


// *****************************************
//              TneNode CLASS
// *****************************************

function TneNode.GetPinCount : integer;
begin
    result := FPins.Count;
end;

function TneNode.GetPin( index : integer ) : TnePin;
begin
    result := TnePin( FPins[index] );
end;

function NodeComparePinNames( const Name1, Name2 : string ) : integer;
begin
    result := AnsiCompareText( Name1, Name2 );
end;

function NodePinCompare( P1, P2 : pointer ) : integer;
begin
    // compare two pins

    //.. firstly on component name
      result := CompareDesignators(
        TnePin(P1).Component.Name, TnePin(P2).Component.Name );

    //.. if names match, compare by pin number
    if result = 0 then begin
//        result := AnsiCompareText( TnePin(P1).Name, TnePin(P2).Name );
          result := NodeComparePinNames( TnePin(P1).Name, TnePin(P2).Name );
    end;
end;


// sort the pins attached to this node, firstly by the component name belonging
// to the pin, then by pin number.
procedure TneNode.Sort;
begin
    FPins.Sort( NodePinCompare );
end;

constructor TneNode.Create;
begin
    FPins := TList.Create;
end;

destructor TneNode.Destroy;
begin
    FPins.Free;
    inherited;
end;

// *****************************************
//              TneComponent CLASS
// *****************************************

function TneComponent.GetPinCount : integer;
begin
    result := FPins.Count;
end;

function TneComponent.GetPin( index : integer ) : TnePin;
begin
    result := TnePin( FPins[index] );
end;

function ComponentNodeCompare( P1, P2 : pointer ) : integer;
begin
    // compare two pins

    //.. firstly on node name
    result := CompareDesignators(
        TnePin(P1).Node.Name, TnePin(P2).Node.Name );

    // if names match, compare by pin name
    if result = 0 then begin
        result := AnsiCompareText( TnePin(P1).Name, TnePin(P2).Name );
    end;
end;

function ComponentPinNoCompare( P1, P2 : pointer ) : integer;
begin
    // compare by pin name
    result := AnsiCompareText( TnePin(P1).Name, TnePin(P2).Name );
end;

procedure TneComponent.SortNodes;
begin
    FPins.Sort( ComponentNodeCompare );
end;

procedure TneComponent.SortPinNos;
begin
    FPins.Sort( ComponentPinNoCompare );
end;

constructor TneComponent.Create;
begin
    FPins := TList.Create;
end;

destructor TneComponent.Destroy;
var
    i : integer;
begin
    for i := FPins.Count -1 downto 0 do begin
        TnePin( FPins[i] ).Free;
    end;
    FPins.Free;
    inherited;
end;


// *****************************************
//              TneNetlist CLASS
// *****************************************

function TneNetList.GetNodeCount : integer;
begin
    result := FNodes.Count;
end;

function TneNetList.GetNode( index : integer ) : TneNode;
begin
    result := TneNode(FNodes[index]);
end;

function TneNetList.GetComponentCount : integer;
begin
    result := FComponents.Count;
end;

function TneNetList.GetComponent( index : integer ) : TneComponent;
begin
    result := TneComponent(FComponents[index]);
end;

function TneNetList.CreateNode : TneNode;
begin
    result := TneNode.Create;
    FNodes.Add( result) ;
end;

function TneNetList.CreateComponent : TneComponent;
begin
    result := TneComponent.Create;
    FComponents.Add( result );
end;

function TneNetList.CreatePin(
    Node : TneNode; Component : TneComponent; const PinName : string ) : TnePin;
begin
    // check that node and component exist
    if (FNodes.IndexOf( Node ) < 0) then begin
        raise EneError.Create( 'Unknown node' );
    end;
    if (FComponents.IndexOf( Component ) < 0) then begin
        raise EneError.Create( 'Unknown component' );
    end;

    result := TnePin.Create;
    result.Node := Node;
    result.Component := Component;
    result.FName := PinName;
    Node.FPins.Add( result );
    Component.FPins.Add( result );
end;


procedure TneNetList.DeleteNode( value : TneNode );
begin
end;

procedure TneNetList.DeleteComponent( value : TneComponent );
begin
end;

procedure TneNetList.DeletePin( value : TnePin );
begin
end;



function TneNetList.ComponentByName( const Name : string ) : TneComponent;
var
    i : integer;
    Component : TneComponent;
begin
    for i := 0 to FComponents.Count -1 do begin
        Component := TneComponent(FComponents[i]);
        if CompareText( Component.Name, Name) = 0 then begin
            result := Component;
            exit;
        end;
    end;
    result := nil;
end;

function TneNetList.NodeByname( const Name : string ) : TneNode;
var
    i : integer;
    Node : TneNode;
begin
    for i := 0 to FNodes.Count -1 do begin
        Node := TneNode(FNodes[i]);
        if Node.Name = Name then begin
            result := Node;
            exit;
        end;
    end;
    result := nil;
end;


// ** COMPARISON FUNCTIONS FOR SORT OF NODES, COMPONENTS **

function NodeCompare( P1, P2 : pointer ) : integer;
begin
    result := AnsiCompareText( (TneNode(P1)).Name, (TneNode(P2)).Name );
end;


function ComponentCompare( P1, P2 : pointer ) : integer;
begin
//    result := AnsiCompareText( (TneComponent(P1)).Name, (TneComponent(P2)).Name );
    result := CompareDesignators( (TneComponent(P1)).Name, (TneComponent(P2)).Name );
end;


// Sort nodes so node names are in text order
// Each Node must sort pins by Component name, then by pin number
procedure TneNetList.SortNodes;
var
    i : integer;
begin
    // Sort Nodes by Name
    FNodes.Sort( NodeCompare );

    // Each Node must sort pins by Component name, then by pin number
    for i := 0 to NodeCount -1 do begin
        Nodes[i].Sort;
    end;
end;

// Sort components so they are in component name order.
// Within each component, sort its pins by node name, pin number.
procedure TneNetList.SortComponentsByNode;
var
    i : integer;
begin
    FComponents.Sort( ComponentCompare );

    // Each component must sort pins by Node name, pin number
    for i := 0 to ComponentCount -1 do begin
        Components[i].SortNodes;
    end;
end;

procedure TneNetList.SortComponentsByPinNo;
var
    i : integer;
begin
    FComponents.Sort( ComponentCompare );

    // Each component must sort pins by pin number
    for i := 0 to ComponentCount -1 do begin
        Components[i].SortPinNos;
    end;
end;

procedure TneNetList.Clear;
var
    i : integer;
begin
    for i := 0 to ColoredNodeCount -1 do begin
        ColoredNodes[i] := nil;
    end;
    for i := FComponents.Count -1 downto 0 do begin
        TneComponent( FComponents[i] ).Free;
    end;
    FComponents.Clear;

    for i := FNodes.Count -1 downto 0 do begin
        TneNode( FNodes[i] ).Free;
    end;
    FNodes.Clear;
end;


// ******************************
//      TEST NETLIST VALIDITY
// ******************************
(*
    Call with report = reference to TStrings object which will receive lines
    of the report.  Set report = nil if no report required.

    Returns
        True = Netlist valid, no lines added to report.
        False = Netlist not valid, if report not nil, lines added to report.
*)

function TneNetList.Validate( report : TStrings ) : boolean;

    procedure LineOut( s : string );
    begin
        if Assigned( report ) then begin
            report.Add( s );
        end;
        result := False;
    end;

var
    i : integer;

    Node : TneNode;
    LastNodeName : string;

    Component : TneComponent;
    LastComponentName : string;

    j : integer;
    Pin : TnePin;
    LastPin : TnePin;
begin
    // assume will pass tests : any failure detected will change
    result := True;

    // * Check that no two nodes have same name *

    // get nodes in .name order
    SortNodes;

    for i := 0 to NodeCount -1 do begin
        Node := Nodes[i];

        // node must have a name
        if Node.Name = '' then begin
            LineOut( 'Unnamed node' );
            continue;
        end;

        // node name must not be same as node before
        if LastNodeName = Node.Name then begin
            LineOut( 'Duplicate net Name : "' + LastNodeName + '"' );
        end;

        // keep old nodename ready for next node check
        LastNodeName := Node.Name;
    end;


    // * Warn of Nodes with only one pin *

    for i := 0 to NodeCount -1 do begin
        Node := Nodes[i];
        if Node.PinCount =1 then begin
            LineOut( 'Node has only one pin : "' + Node.Name + '"' );
        end
        else if Node.PinCount = 0 then begin
            LineOut( 'Node has no pins : "' + Node.Name + '"' );
        end;
    end;

    // * Check that no two components have same name *

    // get components in .Name order (also by PinNo order within components :
    // this order is used by test following this one)
    SortComponentsByPinNo;

    for i := 0 to ComponentCount -1 do begin

        Component := Components[i];

        // component must have a name
        if Component.Name = '' then begin
            LineOut( 'Unnamed component' );
            continue;
        end;

        // component name must not be same as component before
        if LastComponentName = Component.Name then begin
            LineOut( 'Duplicate component Name : "' + LastComponentName + '"' );
        end;

        // keep old component name ready for next component check
        LastComponentName := Component.Name;
    end;

    // * Check that component pin does not appear in more than one node *

    for i := 0 to ComponentCount -1 do begin

        Component := Components[i];

        // invald pin number will never match a actual pin no
        LastPin := nil;

        for j := 0 to Component.PinCount -1 do begin

            Pin := Component.Pins[j];

            // Pin

            if Pin.Name = '' then begin
                LineOut( Format(
                    'Component %s has empty pin name',
                    [Component.Name]
                    )
                );
                continue;
            end;

            // If a pin name in array equals last pin name in array
            // of pins for this component, then we have 2 pins with same name
            // which is an error in the netlist.
            if (LastPin <> nil) and (LastPin.Name = Pin.Name) then begin
                LineOut( Format(
                    'Component %s has duplicate Pin "%s" in nets %s and %s',
                    [Component.Name, LastPin.Name, LastPin.Node.Name, Pin.Node.Name]
                    )
                );
            end;


            LastPin := Pin;
        end;
    end;
end;

constructor TneNetList.Create;
begin
    FNodes := TList.Create;
    FComponents := TList.Create;
end;

destructor TneNetList.Destroy;
var
    i : integer;
begin
    if assigned( FComponents ) then begin
        for i := FComponents.Count -1 downto 0 do begin
            TneComponent( FComponents[i] ).Free;
        end;
        FComponents.Free;
    end;

    if assigned( FNodes ) then begin
        for i := FNodes.Count -1 downto 0 do begin
            TneNode( FNodes[i] ).Free;
        end;
        FNodes.Free;
    end;
    inherited;
end;



// ** MAKE THIS NETLIST A COPY OF THE SOURCE NETLIST **

procedure TneNetList.Clone( Source : TneNetlist );
var
    // record equivalent source nodes
    SourceNodes : array[0..ColoredNodeCount -1] of TneNode;
    i : integer;
    SourceComponent, LocalComponent : TneComponent;
    SourceNode, LocalNode : TneNode;
    j : integer;
    SourcePin {, LocalPin} : TnePin;
    SourcePinNode, LocalPinNode : TneNode;

    SourceNodeColoredNode : TneNode;
    SourceNodeName : string;
begin
    // Clear everything - nodes, components, pins
    Clear;

    // create new Nodes to match SourceNetlist
    for i := 0 to Source.NodeCount - 1 do begin
        SourceNode := Source.Nodes[i];
        LocalNode := CreateNode;
        LocalNode.FName := SourceNode.Name;

        // if source node is tagged as colored, then set the local copy to colored
        for j := 0 to ColoredNodeCount - 1 do begin
            if SourceNodes[j] = SourceNode then begin
                // store this node in array of nodes that are colored
                ColoredNodes[j] := SourceNode;
            end;
        end;

    end;

    // create new Components to match SourceNetlist
    for i := 0 to Source.ComponentCount - 1 do begin
        SourceComponent := Source.Components[i];
        LocalComponent := CreateComponent;
        LocalComponent.FName := SourceComponent.FName;

        // put component pins
        for j := 0 to SourceComponent.PinCount - 1 do begin
            SourcePin := SourceComponent.Pins[j];

            SourcePinNode := SourcePin.FNode;
            LocalPinNode := NodeByName( SourcePinNode.Name );
            if LocalPinNode = nil then begin
                raise EneError.Create( 'Missing node in net duplication' );
            end;
            // LocalPin := CreatePin( LocalPinNode, LocalComponent, SourcePin.Name );
            CreatePin( LocalPinNode, LocalComponent, SourcePin.Name );
        end;
    end;

    // copy the colored node list
    for i := 0 to ColoredNodeCount - 1 do begin
        SourceNodeColoredNode := Source.ColoredNodes[i];
        if SourceNodeColoredNode = nil then begin
            ColoredNodes[i] := nil;
        end
        else begin
            SourceNodeName := SourceNodeColoredNode.Name;
            ColoredNodes[i] := NodeByName( SourceNodeName );
        end;
    end;
end;




// ** EVALUATE EQUIVALENCE OF TWO NODES **
// return the number of matching component pins. 0=no matches, etc

function RateNodeMatch( Node1, Node2 : TneNode ) : integer;
var
    Component1, Component2 : TneComponent;
    Node1PinIndex, Node2PinIndex : integer;
    Node1PinCount, Node2PinCount : integer;
    DesignatorCompare : integer;
    PinCompare : integer;
begin
    // will count number of component pin matches between the two nodes
    result := 0;

    // each node sorted by 1.Component Name, then by 2. Pin Name (number)
    Node1.Sort;
    Node2.Sort;

    Node1PinIndex := 0;
    Node2PinIndex := 0;
    Node1PinCount := Node1.PinCount;
    Node2PinCount := Node2.PinCount;

    // step through pins of Node 1
    while (Node1PinIndex < Node1PinCount) and (Node2PinIndex < Node2PinCount) do begin

        Component1 := Node1.Pins[Node1PinIndex].Component;
        Component2 := Node2.Pins[Node2PinIndex].Component;

        // *** move components in sync
        DesignatorCompare := CompareDesignators( Component1.Name, Component2.Name );

        // if Node1 is on an earlier component than Node2, then move Node1 ahead
        if DesignatorCompare < 0 then begin
            Inc( Node1PinIndex );
        end
        // if Node2 is on an earlier component than Node1, then move Node2 ahead
        else if DesignatorCompare > 0 then begin
            Inc( Node2PinIndex );
        end

        // we are on the same component, so count the number of pins that match
        else begin

            PinCompare := NodeComparePinNames(
                Node1.Pins[Node1PinIndex].Name, Node2.Pins[Node2PinIndex].Name );

            // if Node 1 is on earlier pin name than Node2, then move Node 1 ahead
            if PinCompare < 0 then begin
                Inc( Node1PinIndex );
            end

            // if Node 2 is on earlier pin name than Node1, then move Node 2 ahead
            else if PinCompare > 0 then begin
                Inc( Node2PinIndex );
            end

            // if names match, count that and move to next pins in both lists
            else begin
                inc( result );
                inc( Node1PinIndex );
                inc( Node2PinIndex );
            end
        end;
    end;
end;


// ** FIND EQUIVALENT NODE **
// Look through local nodes to find the one that best matches SourceNode
// Return reference to the  local node.

function TneNetList.EquivalentNode( SourceNode : TneNode ) : TneNode;
var
    i : integer;
    Node : TneNode;
    NodeRating : integer;
    BestNode : TneNode;
    BestNodeRating : integer;
begin
    // can't match empty node
    if SourceNode = nil then begin
        result := nil;
        exit;
    end;

    // stop uninitialised variable compiler warning
    BestNode := nil;

    // look for node with maximum number of pin matches with Source Node
    //.. impossibly low rating
    BestNodeRating := Low(BestNodeRating);

    // for each local node
    for i := 0 to NodeCount -1 do begin

        Node := Nodes[i];

        // see how well that node matches the SourceNode
        NodeRating := RateNodeMatch( SourceNode, Node );
        if (NodeRating > 0) and (NodeRating > BestNodeRating) then begin
            BestNode := Node;
            BestNodeRating := NodeRating;
        end;
    end;

    // return result
    if BestNodeRating > 0 then begin
        result := BestNode;
    end
    else begin
        result := nil;
    end;
end;

// ** Identify Colored Nets by Finding Nets Equivalent to Colored nets in a
// ** source netlist.

procedure TneNetList.GetEquivalentColoredNets( SourceNetlist : TneNetlist );
var
    i : integer;
    SourceNode : TneNode;
begin
    // find equivalent nodes in Source to match This.ColoredNodes[] array members
    // This is necessary because schematic editors can change node names
    // from one export of a netlist to the next.
    for i := 0 to ColoredNodeCount - 1 do begin
        SourceNode := SourceNetlist.ColoredNodes[i];
        ColoredNodes[i] := EquivalentNode( SourceNode );
    end;
end;


end.
