unit Materials;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls,
  Project, Menus;

type
  TMaterialsForm = class(TForm)
    Panel1: TPanel;
    PageControl: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    ComponentsTMemo: TMemo;
    WiresTMemo: TMemo;
    CloseTButton: TButton;
    RefreshTButton: TButton;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    LinksTMemo: TMemo;
    BOMTMemo: TMemo;
    CopyTButton: TButton;
    TabSheet5: TTabSheet;
    StatisticsTMemo: TMemo;
    TabSheet6: TTabSheet;
    BreaksTMemo: TMemo;
    PrintTButton: TButton;
    procedure FormResize(Sender: TObject);
    procedure CloseTButtonClick(Sender: TObject);
    procedure RefreshTButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CopyTButtonClick(Sender: TObject);
    procedure PrintTButtonClick(Sender: TObject);
  private
    { Private declarations }
    Created : boolean;
    function ActiveMemo : TMemo;

  public
    { Public declarations }
    Project : TveProject;
    procedure UpdateInfo;
  end;

var
  MaterialsForm: TMaterialsForm;

implementation

{$R *.DFM}

uses Outlines, CelledOutlines, SizeableOutlines, OtherOutlines, SortCompare,
    Connective, PrintReport, Globals, Netlist, Contnrs;

procedure TMaterialsForm.FormCreate(Sender: TObject);
begin
    // show last page in tabbed page control
    PageControl.ActivePageIndex := 3;
end;

procedure TMaterialsForm.FormShow(Sender: TObject);
var
    MainForm : TForm;
begin

    if not Created then begin
        // Position page so it is slightly to right and down of center position
        // This means this form is not obscured by netlist form which does live
        // exactly at centre of main form.
        MainForm := Application.MainForm;

        Left := MainForm.Left + (MainForm.Width div 2) - (Width div 2) +
            (2 * GetSystemMetrics(SM_CXHTHUMB) );
        Top := MainForm.Top + (MainForm.Height div 2) - (Height div 2) +
            (2 * GetSystemMetrics( SM_CYVTHUMB) );
        Created := True;

        PageControl.ActivePage := TabSheet1;
    end;
end;


// ************************************************
//       REPOSITION BUTTONS AFTER FORM RESIZE
// ************************************************

procedure TMaterialsForm.FormResize(Sender: TObject);
var
    Spacing : integer;
begin
    Spacing := CloseTButton.Width div 6;

    // Position Close Button at left
    CloseTButton.Left := Spacing * 2;

    // Position Print Button at right, with Copy, Refresh buttons nearby
    PrintTButton.Left := Panel1.Width - PrintTButton.Width - (Spacing * 2);
    CopyTButton.Left := PrintTButton.Left - CopyTButton.Width - Spacing;
    RefreshTButton.Left := CopyTButton.Left - RefreshTButton.Width - Spacing;
end;


procedure TMaterialsForm.CloseTButtonClick(Sender: TObject);
begin
    Hide;
end;

procedure TMaterialsForm.RefreshTButtonClick(Sender: TObject);
begin
    UpdateInfo;
end;

procedure DisplayComponents( Project : TveProject; Memo : TMemo );
var
    S : TStringList;
    i : integer;
    Item : TveBoardItem;
    Outline : TveOutline;
    Components : TList;

const
    HeadingFormat =    '%8s%20s%18s (%3s,%3s)-(%3s,%3s) %5s';
    DataFormat =       '%8s%20s%18s (%3d,%3d)';
    DataLeadedFormat = '%8s%20s%18s (%3d,%3d)-(%3d,%3d) %5s';
begin
    S := TStringList.Create;
    try
        Components := TList.Create;
        try
            // fill list with components
            for i := 0 to Project.BoardItemCount -1 do begin
                Item := Project.BoardItems[i];
                Outline := Item.Outline;
                if Outline.UserDefined then begin
                    Components.Add( Item );
                end;
            end;

            // sort list so same part type are grouped
            Components.Sort( CompareItemsForComponents );

            // print column headings
            S.Add( Format(HeadingFormat,
              ['Item', 'Value', 'Outline', 'X', 'Y', 'X2', 'X2', 'Length']) );
            S.Add( '' );

           for i := 0 to Components.Count -1 do begin
                Item := TveBoardItem(Components[i]);
                Outline := Item.Outline;
                if Outline.UserDefined then begin
                    if Outline is TveSizeableOutline then begin
                        S.Add(
                          Format( DataLeadedFormat,
                          [Item.Designator, Item.Value, Outline.Name,
                          Item.X, Item.Y,
                          Item.X+Item.EndDeltaX, Item.Y+Item.EndDeltaY,
                          Item.DisplayLength]
                          )
                        );
                    end
                    else begin
                        S.Add(
                          Format( DataFormat,
                          [Item.Designator, Item.Value, Outline.Name,
                          Item.X, Item.Y]
                          )
                        );
                    end;
                end;
            end;
            Memo.Lines := S;
        finally
            Components.Free;
        end
    finally
        S.Free;
    end;
end;


function CompareItemsByValue( P1, P2 : pointer ) : integer;
begin
    result := AnsiCompareStr( TveBoardItem(P1).Value, TveBoardItem(P2).Value );
    if result = 0 then begin
        if TveBoardItem(P1).X > TveBoardItem(P2).X then begin
            result := 1;
        end
        else if TveBoardItem(P1).X < TveBoardItem(P2).X then begin
            result := -1;
        end
        else if TveBoardItem(P1).Y > TveBoardItem(P2).Y then begin
            result := 1;
        end
        else if TveBoardItem(P1).Y < TveBoardItem(P2).Y then begin
            result := -1;
        end
    end;
end;

procedure DisplayWires( Project : TveProject; Memo : TMemo );
var
    Connectivity : TConnectivity;
    S : TStringList;
    Wires : TList;
    i : integer;
    Item : TveBoardItem;
    Node : TneNode;
    Outline : TveOutline;
    LastItem : TveBoardItem;

const
    HeadingFormat = '%17s %10s, (%3s,%3s)';
    DataFormat =    '%17s %10s, (%3d,%3d)';
begin
    // get hold of connectivity object that provides net information
    Connectivity := TConnectivity( Project.ConnectivityObject );

    S := TStringList.Create;
    try
        Wires := TList.Create;
        try
            // print column headings
            S.Add( Format( HeadingFormat, ['Net', 'Value', 'X', 'Y'] ) );
            S.Add('');

            // build list of wires
            for i := 0 to Project.BoardItemCount -1 do begin
                Item := Project.BoardItems[i];
                Outline := Item.Outline;
                if (Outline is TveWireOutline) then begin
                    Wires.Add( Item );
                end;
            end;

            // sort wires so connected wires are adjacent in list
            Wires.Sort( CompareItemsByValue );

            // print out list of wires
            LastItem := nil;
            for i := 0 to Wires.Count -1 do begin
                Item := TveBoardItem( Wires[i] );

                // blank line before each interconnected group of wires
                if (LastItem <> nil) and (Item.Value <> LastItem.Value) then begin
                    S.Add( '' );
                end;
                LastItem := Item;
                Node := Connectivity.NodeByWire( Item );
                if Node = nil then begin
                    S.Add(
                        Format( DataFormat, [ '', Item.Value, Item.X, Item.Y] )
                    );
                end
                else begin
                    S.Add(
                        Format( DataFormat, [ Node.Name, Item.Value, Item.X, Item.Y] )
                    );
                end;
            end;

        finally
            Wires.Free;
        end;

        // display wires in memo
        Memo.Lines := S;

    finally
        S.Free;
    end;
end;

// Compare Items So Sort Produces Leftmost items first.
// If two items have same X position, then put topmost item first

function CompareItemsByPosition( P1, P2 : pointer ) : integer;
var
    Item1, Item2 : TveBoardItem;
begin
    Item1 := TveBoardItem(P1);
    Item2 := TveBoardItem(P2);
    if (Item1.X < Item2.X) then begin
        result := -1;
    end
    else if Item1.X > Item2.X then begin
        result := 1;
    end
    else begin
        if Item1.Y < Item2.Y then begin
            result := -1;
        end
        else if Item1.Y > Item2.Y then begin
            result := 1;
        end
        else begin
            result := 0;
        end;
    end;
end;

type TLinkData = class
  public
    Link : TveBoardItem;
    Net : TneNode;
end;

function CompareLinkDataByNetName( P1, P2 : pointer ) : integer;
var
    Net1, Net2 : TneNode;
begin
    // compare first by net name
    Net1 := TLinkData( P1 ).Net;
    Net2 := TLinkData( P2 ).Net;

    // if no net names involved, compare by position
    if (Net1 = nil) and (Net2 = nil) then begin
        result := CompareItemsByPosition( TLinkData(P1).Link, TlinkData(P2).Link );
        exit;
    end;

    // if one link has no net, put it last
    if Net1 = nil then begin
        result := 1;
        exit;
    end;
    if Net2 = nil then begin
        result := -1;
        exit;
    end;

    // both links have a net
    result := AnsiCompareStr( Net1.Name, Net2.Name );
end;



procedure DisplayLinks( Project : TveProject; Memo : TMemo );
var
    Connectivity : TConnectivity;
    S : TStringList;
    Links : TObjectList;
    LinkData : TLinkData;
    i : integer;
    Item : TveBoardItem;
    Outline : TveOutline;
    NetName : string;

const
    HeadingFormat = '%15s (%3s,%3s)-(%3s,%3s) %5s';
    DataFormat =    '%15s (%3d,%3d)-(%3d,%3d) %5s';
begin
    // get hold of connectivity object that provides net information
    Connectivity := TConnectivity( Project.ConnectivityObject );

    S := TStringList.Create;
    try
        Links := TObjectList.Create;
        try
            // print column headings
            S.Add( Format(HeadingFormat,
              [ 'Net', 'X', 'Y', 'X2', 'Y2', 'Length' ]) );
            S.Add('');

            // build list of links
            for i := 0 to Project.BoardItemCount -1 do begin
                Item := Project.BoardItems[i];
                Outline := Item.Outline;
                if (Outline is TveLinkOutline) then begin

                    LinkData := TLinkData.Create;
                    LinkData.Link := Item;
                    LinkData.Net := Connectivity.NodeByLink( Item );
                    Links.Add( LinkData );
                end;
            end;

            // sort wires so connected wires are adjacent in list
            Links.Sort( CompareLinkDataByNetName );

            // print out list of wires
            for i := 0 to Links.Count -1 do begin
                LinkData := TLinkData( Links[i] );
                Item := LinkData.Link;

                if LinkData.Net <> nil then begin
                    NetName := LinkData.Net.Name;
                end
                else begin
                    NetName := '';
                end;


                S.Add(
                    Format( DataFormat,
                    [ NetName,
                      Item.X, Item.Y,
                      Item.X+Item.EndDeltaX, Item.Y+Item.EndDeltaY,
                      Item.DisplayLength
                    ] )
                );
            end;

        finally
            Links.Free;
        end;

        // display wires in memo
        Memo.Lines := S;

    finally
        S.Free;
    end;
end;



// Compare Items So Sort Produces grouping of items with same
// alphabetical prefix of designator (C11 C3 etc), same outline
// and same value.

function CompareItemsForBOM( P1, P2 : pointer ) : integer;
var
    Item1, Item2 : TveBoardItem;
begin
    Item1 := TveBoardItem(P1);
    Item2 := TveBoardItem(P2);

    // Same Outline - no two outlines will ever have the same name,
    // so we can compare by name without having to worry about
    // outline object references being to same object.
    result := AnsiCompareStr( Item1.Outline.Name, Item2.Outline.Name );

    // same outline - so compare Value ( 100K vs 22K etc )
    if result = 0 then begin
        result := AnsiCompareStr( Item1.Value, Item2.Value );
    end;

    // same outline & value - so compare designator - "Item" column
    if result = 0 then begin
//        result := AnsiCompareStr( Item1.Designator, Item2.Designator );
        result := CompareDesignators( Item1.Designator, Item2.Designator );
    end;
end;

procedure DisplayBOM( Project : TveProject; Memo : TMemo );
var
    S : TStringList;
    i : integer;
    Item : TveBoardItem;
    Outline : TveOutline;
    Components : TList;
    LastComponent : TveBoardItem;
const
    HeadingFormat = '%8s%20s%18s (%3s,%3s)';
    DataFormat = '%8s%20s%18s (%3d,%3d)';

begin
    S := TStringList.Create;
    try
        Components := TList.Create;
        try

            // print column headings
            S.Add(
                Format( HeadingFormat,
                ['Item', 'Value', 'Outline', 'X', 'Y']
                )
            );
            S.Add( '' );

            // fill list with components
            for i := 0 to Project.BoardItemCount -1 do begin
                Item := Project.BoardItems[i];
                Outline := Item.Outline;
                if Outline.UserDefined then begin
                    Components.Add( Item );
                end;
            end;

            // sort list so same part type are grouped
            Components.Sort( CompareItemsForBOM );

            // print out list of components in groups
            LastComponent := nil;
            for i := 0 to Components.Count -1 do begin
                Item := TveBoardItem( Components[i] );

                // blank line before each interconnected group of wires
                if (LastComponent <> nil) and (
                    (Item.Value <> LastComponent.Value) or
                    (Item.Outline <> LastComponent.Outline)     ) then begin
                    S.Add( '' );
                end;
                LastComponent := Item;
                S.Add(
                    Format( DataFormat,
                    [Item.Designator, Item.Value, Item.Outline.Name, Item.X, Item.Y] )
                );
            end;

        finally
            Components.Free;
        end;
        Memo.Lines := S;
    finally
        S.Free;
    end;
end;


procedure DisplayStatistics( Project : TveProject; Memo : TMemo );
var
    S : TStringList;
    i : integer;
    Outline : TveOutline;
    ComponentCount : integer;
    LinkCount : integer;
    WireCount : integer;
    BreakCount : integer;

    Connectivity : TConnectivity;
    x, y : integer;
    SolderPointCount : integer;
begin
    S := TStringList.Create;
    try
        // info on board items available from Components list.
        ComponentCount := 0;
        LinkCount := 0;
        WireCount := 0;
        BreakCount := 0;

        for i := 0 to Project.BoardItemCount - 1 do begin
            Outline := Project.BoardItems[i].Outline;
            if Outline.UserDefined then begin
                inc( ComponentCount );
            end
            else if( Outline is TveLinkOutline ) then begin
                inc( LinkCount );
            end
            else if( Outline is TveWireOutline ) then begin
                inc( WireCount );
            end
            else if( Outline is TveBreakOutline ) then begin
                inc( BreakCount );
            end;
        end;

        S.Add( Format('Components : %d', [ComponentCount]) );
        S.Add( '' );
        S.Add( Format('Links : %d', [LinkCount]) );
        S.Add( '' );
        S.Add( Format('Wires : %d', [WireCount]) );
        S.Add( '' );
        S.Add( Format('Breaks : %d', [BreakCount]) );
        S.Add( '' );

        // solder point info available from Design Rule Checker
        SolderPointCount := 0;
        Connectivity := TConnectivity( Project.ConnectivityObject );
        for x := 0 to Project.BoardWidth - 1 do begin
            for y := 0 to Project.BoardHeight -1 do begin

                if Connectivity.Cells[x, y].PinCount > 0 then begin
                    inc( SolderPointCount );
                end;
            end;
        end;
        S.Add( Format('Solder Points : %d', [SolderPointCount]) );


        // display information
        Memo.Lines := S;
    finally
        S.Free;
    end;
end;
(*
function CompareItemsByBreakPosition( P1, P2 : pointer ) : integer;
var
    Item1, Item2 : TveBoardItem;
begin
    Item1 := TveBoardItem(P1);
    Item2 := TveBoardItem(P2);

    // sort by Y ( across board )
    if Item1.X < Item2.X then begin
        result := -1;
    end
    else if Item1.X > Item2.X then begin
        result := 1;
    end
    else if Item1.Y < Item2.Y then begin
        result := -1;
    end
    else if Item2.Y > Item2.Y then begin
        result := 1;
    end
    else begin
        result := 0;
    end;
end;
*)
procedure DisplayBreaks( Project : TveProject; Memo : TMemo );
var
    S : TStringList;
    i : integer;
    Item : TveBoardItem;
    List : TList;
begin
    List := nil;
    S := TStringList.Create;
    try
        // fill list with references to items with break outlines
        List := TList.Create;
        for i := 0 to Project.BoardItemCount - 1 do begin
            Item := Project.BoardItems[i];
            if Item.Outline is TveBreakOutline then begin
                 List.Add( Item );
            end;
        end;

        // sort list by break position
        // List.Sort( CompareItemsByBreakPosition );
        List.Sort( CompareItemsByPosition );

        // put outline (break) locations into report
        S.Add( '     X,   Y' );
        S.Add( '' );
        for i := 0 to List.Count - 1 do begin
            Item := TveBoardItem( List[i] );
            case Item.Shift of

                shNone: begin
                    S.Add( Format('%4d  ,%4d', [Item.X, Item.Y]) );
                end;
                shRight: begin
                    S.Add( Format('%4d.5,%4d', [Item.X, Item.Y]) );
                end;
                shDown: begin
                    S.Add( Format('%4d  ,%4d.5', [Item.X, Item.Y]) );
                end;
            end;
        end;

        // display information
        Memo.Lines := S;
    finally
        S.Free;
        List.Free;
    end;
end;

// ************************************************
//              REFRESH ALL TABS
// ************************************************

procedure TMaterialsForm.UpdateInfo;
begin
    Screen.Cursor := crHourGlass;
    try
        DisplayComponents( Project, ComponentsTMemo );
        DisplayWires( Project, WiresTMemo );
        DisplayLinks( Project, LinksTMemo );
        DisplayBOM( Project, BOMTMemo );
        DisplayStatistics( Project, StatisticsTMemo );
        DisplayBreaks( Project, BreaksTMemo );
    finally
        Screen.Cursor := crDefault;
    end;
end;

// ************************************************
//          FIND CURRENTLY SHOWING MEMO
// ************************************************

function TMaterialsForm.ActiveMemo : TMemo;
var
    ActivePage : TTabSheet;
begin
    ActivePage := PageControl.ActivePage;

    if ActivePage = TabSheet1 then begin
        result := ComponentsTMemo;
    end
    else if ActivePage = TabSheet2 then begin
        result := WiresTMemo;
    end
    else if ActivePage = TabSheet3 then begin
        result := LinksTMemo;
    end
    else if ActivePage = TabSheet4 then begin
        result := BOMTMemo;
    end
    else if ActivePage = TabSheet5 then begin
        result := StatisticsTMemo;
    end
    else if ActivePage = TabSheet6 then begin
        result := BreaksTMemo;
    end
    // we never get here, but stops "Undefined result" compiler warning
    else begin
        result := nil;
    end;
end;

// ************************************************
//      COPY TO CLIPBOARD CURRENTLY SHOWING MEMO
// ************************************************

procedure TMaterialsForm.CopyTButtonClick(Sender: TObject);
begin
    ActiveMemo.SelectAll;
    ActiveMemo.CopyToClipboard;
end;

// ************************************************
//        PRINT THE CURRENTLY SHOWING MEMO
// ************************************************

procedure TMaterialsForm.PrintTButtonClick(Sender: TObject);
var
    ReportPrinter : TPrintReportForm;
begin
    // This form has position = poOwnerFormCenter, do must have AOwner
    // param set to this form, not to nil
    ReportPrinter := TPrintReportForm.Create(self);
    try
        ReportPrinter.HKEY_CURRENT_USER_key := Globals.HKEY_CURRENT_USER_KEY;
        ReportPrinter.ReportStrings := ActiveMemo.Lines;
        ReportPrinter.PrinterTitle := 'VeeCAD Report';
        ReportPrinter.Caption := 'Print: ' + PageControl.ActivePage.Caption;

        // title for each page, including page number at %d format
        ReportPrinter.PageTitle :=
            'Materials : ' + PageControl.ActivePage.Caption + '.  Page %d';
        ReportPrinter.Execute;
    finally
        ReportPrinter.Free;
    end;
end;

end.


