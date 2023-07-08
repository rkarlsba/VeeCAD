unit NetlistExport;

interface

uses Project;

procedure ExportNetlistProtel( const FileName : string; Project : TveProject );

implementation

uses Classes, SysUtils, Netlist, Outlines, ExceptSafe;

type ESafeNetExport = class( ESafe );


procedure ExportNetlistProtelStream( Stream : TStream; Project : TveProject );

    procedure LineOut( Line : string );
    const
        CRLF : array[0..1] of ansichar = ( #13, #10 );
    var
       oString: UTF8String;
    begin
       oString := UTF8String(Line);
       Stream.WriteBuffer(oString[1], length(oString) * sizeof(ansichar) );
       Stream.WriteBuffer(CRLF, 2 * sizeof(ansichar) );
    end;

var
  i, j : integer;
  Netlist : TneNetlist;
  Component : TneComponent;
  BoardItem : TveBoardItem;
  Value : string;
  Outline : string;
  Node : TneNode;
  Pin : TnePin;
begin
    // local var
    Netlist := Project.Netlist;

    // write components to stringlist
    for i := 0 to Netlist.ComponentCount - 1 do begin
        Component := Netlist.Components[i];
        BoardItem := Project.ItemByDesignator( Component.Name );
        // no matching component on board, make outline & value blank
        if BoardItem = nil then begin
            Outline := '';
            Value := '';
        end
        // else use outline and valuel from board
        else begin;
            Outline := BoardItem.Outline.Name;
            Value := BoardItem.Value;
        end;
{  Protel components format looks like this:
[
U100
TO-220_SINK
LM7812



]
}
        LineOut( '[' );
        LineOut( Component.Name );
        LineOut( Outline );
        LineOut( Value );
        LineOut( '' );
        LineOut( '' );
        LineOut( '' );
        LineOut( ']' );
    end;

    // write nodes (nets) to stringlist
    for i := 0 to Netlist.NodeCount - 1 do begin
        Node := Netlist.Nodes[i];

{ Protel nets format looks like this:
(
N000049
D400-2
D401-1
)
}
        LineOut( '(' );
        LineOut( Node.Name );

        for j := 0 to Node.PinCount - 1 do begin
            Pin := Node.Pins[j];
            LineOut( Pin.Component.Name + '-' + Pin.Name );
        end;

        LineOut( ')' );
  end;
end;


procedure ExportNetlistProtel( const FileName : string; Project : TveProject );
var Stream : TFileStream;
begin
    Stream := TFileStream.Create( FileName, fmCreate );
    try
        ExportNetlistProtelStream( Stream, Project );
    finally
        Stream.Free;
    end;
end;

end.
