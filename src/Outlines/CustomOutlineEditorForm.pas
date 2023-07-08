unit CustomOutlineEditorForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, ToolWin, CustomOutlineEditor, CustomOutlines, ImgList, ExtCtrls;

type
  TveCustomOutlineEditorForm = class(TForm)
    ToolBar1: TToolBar;
    SelectTToolButton: TToolButton;
    LineTToolButton: TToolButton;
    StatusBar1: TStatusBar;
    ImageList1: TImageList;
    PinTToolButton: TToolButton;
    ToolButton1: TToolButton;
    UndoTToolButton: TToolButton;
    RedoTToolButton: TToolButton;
    ToolButton4: TToolButton;
    ZoomInTToolButton: TToolButton;
    ZoomOutTToolButton: TToolButton;
    ToolButton7: TToolButton;
    LighterTToolButton: TToolButton;
    ToolButton2: TToolButton;
    ScrollBox1: TScrollBox;
    DarkerTToolButton: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SelectTToolButtonClick(Sender: TObject);
    procedure LineTToolButtonClick(Sender: TObject);
    procedure PinTToolButtonClick(Sender: TObject);
    procedure ZoomInTToolButtonClick(Sender: TObject);
    procedure ZoomOutTToolButtonClick(Sender: TObject);
    procedure LighterTToolButtonClick(Sender: TObject);
    procedure DarkerTToolButtonClick(Sender: TObject);
  private
    // Properties
    CellGrey : byte;
    Editor : TveCustomOutlineEditor;
    procedure SetOutline( value : TveCustomOutline );
    function GetOutline : TveCustomOutline;

    procedure LoadSettings;
    procedure SaveSettings;

    procedure UpdateEditorCellGrey;

    procedure OnMouseSubCellMove( SubCellX, SubCellY, CellX, CellY : integer );
    procedure OnMouseClickShape( Sender : TObject; Item : TcoShape );
    procedure OnChangeMode( Sender : TObject; Mode : TCmoEditMode );
  public
    { Public declarations }
    property Outline : TveCustomOutline read GetOutline write SetOutline;

  end;

var
  veCustomOutlineEditorForm: TveCustomOutlineEditorForm;

implementation

{$R *.DFM}

uses Globals, Registry;

// ********************************************
//          FORM PROPEERTY PROVIDERS
// ********************************************

procedure TveCustomOutlineEditorForm.SetOutline( value : TveCustomOutline );
begin
    Caption := 'Custom Outline Editor: ' + value.Name;
    Editor.Outline := value;
    Outline.UnselectAllShapes;
end;

function TveCustomOutlineEditorForm.GetOutline : TveCustomOutline;
begin
    result := Editor.Outline;
end;

procedure TveCustomOutlineEditorForm.UpdateEditorCellGrey;
begin
    Editor.StripColor := (CellGrey shl 16) + (CellGrey shl 8 ) + CellGrey;
end;


procedure TveCustomOutlineEditorForm.LoadSettings;
var
    RegIniFile : TRegIniFile;
begin
    RegIniFile := GetRegIniFile;
    try
        CellGrey := $FF and
            RegIniFile.ReadInteger( 'CustomEditor', 'CellGrey', $80 );
        UpdateEditorCellGrey;
        Editor.PixelsPerCell := RegIniFile.ReadInteger( 'CustomEditor', 'PixelsPerCell', Editor.PixelsPerCell );
    finally
        RegIniFile.Free;
    end;
end;

procedure TveCustomOutlineEditorForm.SaveSettings;
var
    RegIniFile : TRegIniFile;
begin
    RegIniFile := GetRegIniFile;
    try
        RegIniFile.WriteString( 'CustomEditor', 'CellGrey', Format('$%2.2X', [CellGrey]) );
        RegIniFile.WriteInteger( 'CustomEditor', 'PixelsPerCell', Editor.PixelsPerCell );
    finally
        RegIniFile.Free;
    end;
end;

procedure TveCustomOutlineEditorForm.FormCreate(Sender: TObject);
begin
    Editor := TveCustomOutlineEditor.Create(self);
    Editor.Parent := ScrollBox1;
    Editor.Paint;
    Editor.Top := ToolBar1.Height;
    Editor.OnMouseSubCellMove := OnMouseSubCellMove;
    Editor.OnMouseClickShape := OnMouseClickShape;
    Editor.OnChangeMode := OnChangeMode;

    GetFormMinder.AdjustForm( self );
    LoadSettings;
end;

procedure TveCustomOutlineEditorForm.FormDestroy(Sender: TObject);
begin
    GetFormMinder.RecordForm( self );
    SaveSettings;
end;

procedure TveCustomOutlineEditorForm.FormShow(Sender: TObject);
begin
    // without .SetFocus, Editor.KeyDown never called.
    Editor.SetFocus;
end;

// ********************************************
//          EDITOR EVENT HANDLERS
// ********************************************

procedure TveCustomOutlineEditorForm.OnMouseSubCellMove(
    SubCellX, SubCellY, CellX, CellY : integer );
begin
    StatusBar1.Panels[0].Text := Format( 'SubCell=%d,%d', [SubCellX, SubCellY] );
    StatusBar1.Panels[1].Text := Format( 'Cell=%d,%d', [CellX, CellY] );
end;

procedure TveCustomOutlineEditorForm.OnMouseClickShape( Sender : TObject; Item : TcoShape );
var
    ItemText : string;
begin
    if Item = nil then begin
        ItemText := '';
    end
    else if Item is TcoLine then begin
        ItemText := 'Line';
    end
    else if Item is TcoPin then begin
        ItemText := 'Pin ' + TcoPin(Item).Name;
    end;
    StatusBar1.Panels[2].Text := ItemText;
end;

procedure TveCustomOutlineEditorForm.OnChangeMode( Sender : TObject; Mode : TCmoEditMode );
begin
    case Mode of
      emSelect : SelectTToolbutton.Down := True;
      emLine : LineTToolbutton.Down := True;
      emPin : PinTToolbutton.Down := True;
    end;
end;

// ********************************************
//          TOOLBAR BUTTON EVENT HANDLERS
// ********************************************

procedure TveCustomOutlineEditorForm.SelectTToolButtonClick(Sender: TObject);
begin
    Editor.EditMode := emSelect;
end;

procedure TveCustomOutlineEditorForm.LineTToolButtonClick(Sender: TObject);
begin
    Editor.EditMode := emLine;
end;

procedure TveCustomOutlineEditorForm.PinTToolButtonClick(Sender: TObject);
begin
    Editor.EditMode := emPin;
end;

procedure TveCustomOutlineEditorForm.ZoomInTToolButtonClick(Sender: TObject);
begin
    Editor.PixelsPerCell := Editor.PixelsPerCell + 1;
    Editor.Refresh;
end;

procedure TveCustomOutlineEditorForm.ZoomOutTToolButtonClick(Sender: TObject);
begin
    Editor.PixelsPerCell := Editor.PixelsPerCell - 1;
    Editor.Refresh;
end;

procedure TveCustomOutlineEditorForm.LighterTToolButtonClick(
  Sender: TObject);
begin
    if CellGrey < 255 then begin
        Inc( CellGrey, 4 );
    end;
    UpdateEditorCellGrey;
    Editor.Paint;
end;

procedure TveCustomOutlineEditorForm.DarkerTToolButtonClick(Sender: TObject);
begin
    if CellGrey > 0 then begin
        Dec( CellGrey, 6 );
    end;
    UpdateEditorCellGrey;
    Editor.Paint;
end;

end.
