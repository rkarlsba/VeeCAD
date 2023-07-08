unit ColorNetLinkFm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls,
  Editor, Netlist;

type
  TColorNetLinkForm = class(TForm)
    NetTComboBox0: TComboBox;
    Label1: TLabel;
    Shape0: TShape;
    NetTComboBox1: TComboBox;
    Label2: TLabel;
    Shape1: TShape;
    NetTComboBox2: TComboBox;
    Label3: TLabel;
    Shape2: TShape;
    NetTComboBox3: TComboBox;
    Label4: TLabel;
    Shape3: TShape;
    Panel1: TPanel;
    OKTButton: TButton;
    CancelTButton: TButton;
    ColorsTButton: TButton;
    Label5: TLabel;
    Shape4: TShape;
    NetTComboBox4: TComboBox;
    Label6: TLabel;
    Shape5: TShape;
    NetTComboBox5: TComboBox;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ColorsTButtonClick(Sender: TObject);
  private
    { Private declarations }
    Netlist : TneNetlist;
    procedure LoadNetComboBoxes;
    procedure SaveNetComboBoxes;
    procedure ShowColorSwatches;
  public
    { Public declarations }
    Editor : TveEditor;
    // add location of object holding net colors. Either Project or Editor.
  end;

var
  ColorNetLinkForm: TColorNetLinkForm;

implementation

{$R *.dfm}

uses SettingsFrm;

// *********************************************
//         INITIALISATION & FINALISATION
// *********************************************

procedure TColorNetLinkForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
    //
    SaveNetComboBoxes;
end;

procedure TColorNetLinkForm.FormShow(Sender: TObject);
begin
    // access objects
    Netlist := Editor.Project.Netlist;

    // load color swatches
    ShowColorSwatches;

    // load nets into comboBoxes
    LoadNetComboBoxes;
end;


// **************************************************
//           LOAD & SAVE NET COMBOBOXES
// **************************************************

procedure SetComboBox( ComboBox : TComboBox; Node : TneNode );
var
    i : integer;
begin
    // find index of Node (will find nil as 0th element)
    for i := 0 to ComboBox.Items.Count - 1 do begin
        if ComboBox.Items.Objects[i] = Node then begin
            ComboBox.ItemIndex := i;
            exit;
        end;
    end;

    // node not found in Objects[] - we should not get here, but handle case
    // anyway - set to NO-NODE at index 0
    ComboBox.ItemIndex := 0;
end;

procedure TColorNetLinkForm.LoadNetComboBoxes;
const NO_NODE = '--No Net--';

    procedure FillComboBox( Box : TComboBox );
    var
        i : integer;
        Node : TneNode;
    begin
        Box.Items.Clear;

        // first combobox item is "--No Net--"
        Box.Items.AddObject( NO_NODE, nil );

        // put net names into comboboxes
        for i := 0 to Netlist.NodeCount - 1 do begin
            Node := Netlist.Nodes[i];
            Box.Items.AddObject( Node.Name, Node );
        end;
    end;

begin
    // fill comboboxes with net selections
    FillComboBox( NetTComboBox0 );
    FillComboBox( NetTComboBox1 );
    FillComboBox( NetTComboBox2 );
    FillComboBox( NetTComboBox3 );
    FillComboBox( NetTComboBox4 );
    FillComboBox( NetTComboBox5 );

    // set ComboBoxes to select correct net name
    SetComboBox( NetTComboBox0, Netlist.ColoredNodes[0] );
    SetComboBox( NetTComboBox1, Netlist.ColoredNodes[1] );
    SetComboBox( NetTComboBox2, Netlist.ColoredNodes[2] );
    SetComboBox( NetTComboBox3, Netlist.ColoredNodes[3] );
    SetComboBox( NetTComboBox4, Netlist.ColoredNodes[4] );
    SetComboBox( NetTComboBox5, Netlist.ColoredNodes[5] );
end;

procedure TColorNetLinkForm.SaveNetComboBoxes;
begin
    // store colored node references
    Netlist.ColoredNodes[0] :=
        TneNode(NetTComboBox0.Items.Objects[NetTComboBox0.ItemIndex]);

    Netlist.ColoredNodes[1] :=
        TneNode(NetTComboBox1.Items.Objects[NetTComboBox1.ItemIndex]);

    Netlist.ColoredNodes[2] :=
        TneNode(NetTComboBox2.Items.Objects[NetTComboBox2.ItemIndex]);

    Netlist.ColoredNodes[3] :=
        TneNode(NetTComboBox3.Items.Objects[NetTComboBox3.ItemIndex]);

    Netlist.ColoredNodes[4] :=
        TneNode(NetTComboBox2.Items.Objects[NetTComboBox4.ItemIndex]);

    Netlist.ColoredNodes[5] :=
        TneNode(NetTComboBox3.Items.Objects[NetTComboBox5.ItemIndex]);
end;

// *******************************************
//          UPDATE COLOR "SWATCHES"
// *******************************************

procedure TColorNetLinkForm.ShowColorSwatches;
begin
    // set color squares beside comboBoxes
    Shape0.Brush.Color := Editor.NodeColors[0];
    Shape1.Brush.Color := Editor.NodeColors[1];
    Shape2.Brush.Color := Editor.NodeColors[2];
    Shape3.Brush.Color := Editor.NodeColors[3];
    Shape4.Brush.Color := Editor.NodeColors[4];
    Shape5.Brush.Color := Editor.NodeColors[5];
end;

// *******************************************
//            SHOW COLORS DIALOG -
// *******************************************
// This is a convenience - just shows the standard Tools -> Settings dialog

procedure TColorNetLinkForm.ColorsTButtonClick(Sender: TObject);
var
    SettingsForm : TSettingsForm;
begin
    SettingsForm := TSettingsForm.Create(self);
    try
        SettingsForm.Editor := Editor;
        SettingsForm.ShowModal;
    finally
        SettingsForm.Free;
    end;

    // update colors
    ShowColorSwatches;
end;

end.
