unit NetlistSettings1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, ExtCtrls,
  Netlist, Project, Menus, StdCtrls;

type
  TNetlistForm1 = class(TForm)
    Panel1: TPanel;
    CloseTButton: TButton;
    PageControl: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    ValidationTMemo: TMemo;
    NodesTMemo: TMemo;
    ComponentPinsTMemo: TMemo;
    ProjectTTabSheet: TTabSheet;
    ProjectCheckTMemo: TMemo;
    RefreshTButton: TButton;
    CopyTButton: TButton;
    PrintTButton: TButton;
    procedure CloseTButtonClick(Sender: TObject);
    procedure RefreshTButtonClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CopyTButtonClick(Sender: TObject);
    procedure PrintTButtonClick(Sender: TObject);
  private
    { Private declarations }
    function ActiveMemo : TMemo;
  public
    { Public declarations }
    Netlist : TneNetlist;
    Project : TveProject;
    procedure UpdateInfo;
  end;

var
  NetlistForm1: TNetlistForm1;

implementation

{$R *.DFM}

uses ProjectCheck, PrintReport, Globals;

procedure TNetlistForm1.FormCreate(Sender: TObject);
begin
    PageControl.ActivePageIndex := 3;
end;

// ************************************************
//       REPOSITION BUTTONS AFTER FORM RESIZE
// ************************************************

procedure TNetlistForm1.FormResize(Sender: TObject);
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


procedure TNetlistForm1.CloseTButtonClick(Sender: TObject);
begin
    Hide;
end;

procedure TNetlistForm1.RefreshTButtonClick(Sender: TObject);
begin
    UpdateInfo;
end;

procedure DisplayNetlistByNodes( Netlist : TneNetlist; Memo : TMemo );
var
    S : TStringList;
    i : integer;
    Node : TneNode;
//    TreeNode : TTreeNode;

    j : integer;
    Pin : TnePin;
    LastComponent : TneComponent;
begin
//    TreeView.Items.Clear;

    S := TStringList.Create;
    try

        // Sort nodes so node names are in text order
        Netlist.SortNodes;

        // Within each component, sort its pins by node name, pin number.
        Netlist.SortComponentsByNode;

        // for each node
        for i := 0 to Netlist.NodeCount -1 do begin
            Node := Netlist.Nodes[i];

            // show node in TreeView
            S.Add( Node.Name );

            // add pins connecting to the node
            LastComponent := nil;
            for j := 0 to Node.PinCount -1 do begin

                // get next node pin
                Pin := Node.Pins[j];

                // if component on this node not previously encountered
                // add this component to the tree
                if Pin.Component <> LastComponent then begin
                    LastComponent := Pin.Component;
                    S.Add( '      ' + Pin.Component.Name );
                end;

                // add pin as child of its component
                S[S.Count -1] := S[S.Count -1] + ',' + Pin.Name;
            end;
        end;

        Memo.Lines := S;
    finally
        S.Free;
    end;
end;

{
procedure DisplayNetlistByComponents( Netlist : TneNetlist; TreeView : TTreeView );
var
    i : integer;
    Component : TneComponent;
    TreeNode : TTreeNode;

    j : integer;
    Pin : TnePin;
    LastNode : TneNode;
    NetNodeTreeNode : TTreeNode;

begin
    TreeView.Items.Clear;

    Netlist.SortNodes;
    Netlist.SortComponentsByNode;

    // for each component
    for i := 0 to Netlist.ComponentCount -1 do begin
        Component := Netlist.Components[i];

        // show component in TreeView
        TreeNode := TreeView.Items.Add( nil, Component.Name );

        // add pins connecting to the component
        LastNode := nil;
        NetNodeTreeNode := nil;
        for j := 0 to Component.PinCount -1 do begin

            // get next node pin
            Pin := Component.Pins[j];

            // if node on this component not previously encountered
            // add this node to the tree
            if Pin.Node <> LastNode then begin
                LastNode := Pin.Node;
                NetNodeTreeNode := TreeView.Items.AddChild( TreeNode, Pin.Node.Name );
            end;

            // add pin as child of its node
            TreeView.Items.AddChild( NetNodeTreeNode, IntToStr(Pin.Number) );
        end;
    end;
end;
}

procedure DisplayNetlistByComponentPinNos( Netlist : TneNetlist; Memo : TMemo );
var
    S : TStringList;
    i : integer;
    Component : TneComponent;

    j : integer;
    Pin : TnePin;
begin
    S := TStringList.Create;
    try
        Netlist.SortNodes;
        Netlist.SortComponentsByPinNo;

        // for each component
        for i := 0 to Netlist.ComponentCount -1 do begin
            Component := Netlist.Components[i];

            // show component in TreeView
            S.Add( Component.Name );

            // add pins connecting to the component
            for j := 0 to Component.PinCount -1 do begin
                Pin := Component.Pins[j];
                S.Add( Format( '   %10s - %s', [Pin.Name, Pin.Node.Name] ));
            end;
        end;
        Memo.Lines := S;
    finally
        S.Free;
    end;
end;


procedure DisplayNetlistValidation( Netlist : TneNetlist; Memo : TMemo );
var
    S : TStringList;
begin
    S := TStringList.Create;
    try

        if Netlist.Validate( S ) then begin
            S.Add( 'No errors in netlist' );
        end;

        Memo.Lines := S;
    finally
        S.Free;
    end;
end;


procedure DisplayProjectCheck( Project : TveProject; Memo : TMemo );
var
    S : TStringList;
    ProjectChecker : TProjectChecker;
begin
    S := TStringList.Create;
    try
        ProjectChecker := TProjectChecker.Create;
        try
            ProjectChecker.Project := Project;
            if ProjectChecker.CheckAll( S ) then begin
                S.Add( 'Board contains all components & pins required by Net' );
            end;
        finally
            ProjectChecker.Free;
        end;
        Memo.Lines := S;
    finally
        S.Free;
    end;
end;

// ************************************************
//              REFRESH ALL TABS
// ************************************************

procedure TNetlistForm1.UpdateInfo;
begin
    // if no netlist loaded, clear all report tabs
    if (Netlist.NodeCount <= 0) and (Netlist.ComponentCount <= 0) then begin
        NodesTMemo.Lines.Clear;
        ComponentPinsTMemo.Lines.Clear;
        ValidationTMemo.Lines.Clear;
        ProjectCheckTMemo.Lines.Clear;
        exit;
    end;

    // we do have a netlist, so report
    Screen.Cursor := crHourGlass;
    try
        DisplayNetlistByNodes( Netlist, NodesTMemo );
        DisplayNetlistByComponentPinNos( Netlist, ComponentPinsTMemo );
        DisplayNetlistValidation( Netlist, ValidationTMemo );
        DisplayProjectCheck( Project, ProjectCheckTMemo );
    finally
        Screen.Cursor := crDefault;
    end;
end;

// ************************************************
//          FIND CURRENTLY SHOWING MEMO
// ************************************************

function TNetlistForm1.ActiveMemo : TMemo;
var
    ActivePage : TTabSheet;
begin
    ActivePage := PageControl.ActivePage;

    if ActivePage = TabSheet1 then begin
        result := NodesTMemo;
    end
    else if ActivePage = TabSheet2 then begin
        result := ComponentPinsTMemo;
    end
    else if ActivePage = TabSheet3 then begin
        result := ValidationTMemo;
    end
    else if ActivePage = ProjectTTabSheet then begin
        result := ProjectCheckTMemo;
    end
    // we never get here, but this prevents "undefined result" compiler warning
    else begin
        result := nil;
    end;
end;

// ************************************************
//      COPY TO CLIPBOARD CURRENTLY SHOWING MEMO
// ************************************************

procedure TNetlistForm1.CopyTButtonClick(Sender: TObject);
begin
    ActiveMemo.SelectAll;
    ActiveMemo.CopyToClipboard;
end;

// ************************************************
//        PRINT THE CURRENTLY SHOWING MEMO
// ************************************************

procedure TNetlistForm1.PrintTButtonClick(Sender: TObject);
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
            'Netlist : ' + PageControl.ActivePage.Caption + '.  Page %d';
        ReportPrinter.Execute;
    finally
        ReportPrinter.Free;
    end;
end;



end.


