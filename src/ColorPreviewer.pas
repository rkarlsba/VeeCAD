unit ColorPreviewer;

interface

uses Editor, Project, Outlines, Classes, CelledOutlines, SizeableOutlines;

type TveColorPreviewer = class(TveEditor)
  protected

    CelledItem : TveBoardItem;
    LeadedItem : TveBoardItem;
    BreakItem : TveBoardItem;
    LinkItem : TveBoardItem;
    WireItem : TveBoardItem;

    FOutline : TveOutline;

  public
    property Outline : TveOutline read FOutline write FOutline;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
end;

implementation

uses Board, Netlist, Painter;

constructor TveColorPreviewer.Create(AOwner: TComponent);
var
    CelledOutline : TveCellOutline;
    LeadedOutline : TveLeadedOutline;

    // colored nodes variables
    Netlist : TneNetlist;
    Node0, Node1, Node2, Node3, Node4, Node5 : TneNode;
    Component0, Component1 : TneComponent;
    Break : TveBoardItem;
const
    CellWidth = 12;
    CellHeight = 12;

    procedure CreateWireItem( x, y : integer; const Value : string );
    var
        WireItem : TveBoardItem;
    begin
        { Wire Item - uses a stock WireOutline }
        WireItem := TveBoardItem.Create;
        WireItem.Outline := Project.WireOutline;
        Project.AddBoardItem( WireItem );
        WireItem.X := x;
        WireItem.Y := y;
        WireItem.Value := Value;
    end;

begin
    inherited;
    Project := TveProject.Create;
    Project.BoardWidth := CellWidth;
    Project.BoardHeight := CellHeight;
    Project.Board.Pattern := ptStrip;
    // must call Board.Prepare after setting up Board
    Project.Board.Prepare;

    // create BoardItems and add them to the Project : this makes a little
    // circuit for display.
    // Project.AddOutline and Project.AddBoardItem pass ownership Outline or
    // Item to the Project, which destroys them during its destructor.

    {  Celled Item - a DIP-8 package }
    CelledItem := TveBoardItem.Create;
    CelledOutline := TveCellOutline.Create;
    Project.AddOutline( CelledOutline );
    CelledItem.Outline := CelledOutline;
    Project.AddBoardItem( CelledItem );
    CelledItem.Designator := 'U1';
    CelledItem.TextX := 1;

    CelledItem.X := 1;
    CelledItem.Y := 1;

    CelledOutline.CellTypes[0,0] := ctPin;
    CelledOutline.CellTypes[0,1] := ctPin;
    CelledOutline.CellTypes[0,2] := ctPin;
    CelledOutline.CellTypes[0,3] := ctPin;
    CelledOutline.CellTypes[3,0] := ctPin;
    CelledOutline.CellTypes[3,1] := ctPin;
    CelledOutline.CellTypes[3,2] := ctPin;
    CelledOutline.CellTypes[3,3] := ctPin;

    CelledOutline.CellPinNames[0,0] := '1';
    CelledOutline.CellPinNames[0,1] := '2';
    CelledOutline.CellPinNames[0,2] := '3';
    CelledOutline.CellPinNames[0,3] := '4';
    CelledOutline.CellPinNames[3,0] := '8';
    CelledOutline.CellPinNames[3,1] := '7';
    CelledOutline.CellPinNames[3,2] := '6';
    CelledOutline.CellPinNames[3,3] := '5';

    CelledOutline.CellTypes[1,1] := ctBody;
    CelledOutline.CellTypes[1,2] := ctBody;
    CelledOutline.CellTypes[1,3] := ctBody;
    CelledOutline.CellTypes[2,1] := ctBody;
    CelledOutline.CellTypes[2,2] := ctBody;
    CelledOutline.CellTypes[2,3] := ctBody;

    { Leaded Item - a resistor or similar package }
    LeadedItem := TveBoardItem.Create;
    LeadedOutline := TveLeadedOutline.Create;
    Project.AddOutline( LeadedOutline );
    LeadedItem.Outline := LeadedOutline;
    Project.AddBoardItem( LeadedItem );
    LeadedItem.Designator := 'R1';
    LeadedItem.X := 2;
    LeadedItem.Y := 5;
    LeadedOutline.BodyLength := 3;
    LeadedOutline.BodyWidth := 2;
    LeadedItem.Length := 5;
    LeadedItem.TextY := 3;

    { Break Item - uses a stock BreakOutline }
    BreakItem := TveBoardItem.Create;
    BreakItem.Outline := Project.BreakOutline;
    Project.AddBoardItem( BreakItem );
    BreakItem.X := 5;
    BreakItem.Y := 5;

    { Link Item - uses a stock LinkOutline }
    LinkItem := TveBoardItem.Create;
    LinkItem.Outline := Project.LinkOutline;
    Project.AddBoardItem( LinkItem );
    LinkItem.X := 7;
    LinkItem.Y := 5;
    LinkItem.Length := 3;

    // Mark colored nets using Wire Items
    CreateWireItem( 0, 2, 'N1' );
    CreateWireItem( 0, 4, 'N2' );
    CreateWireItem( 5, 4, 'N3' );
    CreateWireItem( 5, 2, 'N4' );
    CreateWireItem( 3, 5, 'N5' );
    CreateWireItem( 3, 10, 'N6' );

    // show colors better with wider line
    Painter.LineWidth := 2;

    // add a couple of breaks
    Break := TveBoardItem.Create;
    Break.Outline := Project.BreakOutline;
    Break.X := 3;
    Break.Y := 2;
    Project.AddBoardItem( Break );

    Break := TveBoardItem.Create;
    Break.Outline := Project.BreakOutline;
    Break.X := 3;
    Break.Y := 4;
    Project.AddBoardItem( Break );

    // show component text
    TextDisplay := tdDesignator;

    // add a netlist
    Netlist := Project.NetList;

    // set which nodes to color
    // 1. Create 4 nodes
    Node0 := Netlist.CreateNode;
    Node1 := Netlist.CreateNode;
    Node2 := Netlist.CreateNode;
    Node3 := Netlist.CreateNode;
    Node4 := Netlist.CreateNode;
    Node5 := Netlist.CreateNode;

    Node0.Name := 'Node0';
    Node1.Name := 'Node1';
    Node2.Name := 'Node2';
    Node3.Name := 'Node3';
    Node4.Name := 'Node4';
    Node5.Name := 'Node5';

    // 2. Create components
    Component0 := Netlist.CreateComponent;
    Component1 := Netlist.CreateComponent;

    Component0.Name := 'U1';
    Component1.Name := 'R1';

    // 3. Put component pins in nodes
    Netlist.CreatePin( Node0, Component0, '2' );
    Netlist.CreatePin( Node1, Component0, '4' );
    Netlist.CreatePin( Node2, Component0, '5' );
    Netlist.CreatePin( Node3, Component0, '7' );

    Netlist.CreatePin( Node4, Component1, '1' );
    Netlist.CreatePin( Node5, Component1, '2' );

    // make net colors available
    Netlist.ColoredNodes[0] := Node0;
    Netlist.ColoredNodes[1] := Node1;
    Netlist.ColoredNodes[2] := Node2;
    Netlist.ColoredNodes[3] := Node3;
    Netlist.ColoredNodes[4] := Node4;
    Netlist.ColoredNodes[5] := Node5;

    // set nets ready for connectivity to find net tracks
    Project.TransferFastNets;

    // turn on display of net colors
    NetTraceVisible := True;

    // no wheel zoom
    OnMouseWheel := nil;
end;

destructor TveColorPreviewer.Destroy;
begin
    //.. TveEditor (ancestor) frees the Project member we created
    inherited;
end;

{
procedure TveColorPreviewer.Paint;
var
    ItemLeft, ItemRight, ItemTop, ItemBottom : integer;
begin
    inherited Paint;
end;
}

end.


