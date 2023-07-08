unit SettingsFrmColors;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, ColorPreviewer, Editor, Menus, Styles,
  ComCtrls,
  HSVColorPicker, VColorPicker;

type TPickerItem =
  ( piBody, piPin, piStrip, piBoard, piSelection,
    piNet1, piNet2, piNet3, piNet4, piNet5, piNet6 );

type
  TSetColorsForm = class(TForm)
    PreviewTPanel: TPanel;
    ClipboardTPopupMenu: TPopupMenu;
    CopyColorValuestoClipboard1: TMenuItem;
    PasteColorValuesfromClipboard1: TMenuItem;
    Label3: TLabel;
    Label4: TLabel;
    LeadStyleTComboBox: TComboBox;
    LineWidthTUpDown: TUpDown;
    LineWidthTEdit: TEdit;
    ColorPickersTGroupBox: TGroupBox;
    Label5: TLabel;
    BodyTRadioButton: TRadioButton;
    PinsTRadioButton: TRadioButton;
    StripsTRadioButton: TRadioButton;
    BoardTRadioButton: TRadioButton;
    SelectedColorTRadioButton: TRadioButton;
    SelectedColorResetTButton: TButton;
    Net1TRadioButton: TRadioButton;
    Net2TRadioButton: TRadioButton;
    Net3TRadioButton: TRadioButton;
    Net4TRadioButton: TRadioButton;
    Net5TRadioButton: TRadioButton;
    Net6TRadioButton: TRadioButton;
    SpecialTButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SpecialTButtonClick(Sender: TObject);
    procedure CopyColorValuestoClipboard1Click(Sender: TObject);
    procedure PasteColorValuesfromClipboard1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LineWidthTUpDownChangingEx(Sender: TObject;
      var AllowChange: Boolean; NewValue: Smallint;
      Direction: TUpDownDirection);
    procedure LeadStyleTComboBoxChange(Sender: TObject);
    procedure BodyTRadioButtonClick(Sender: TObject);
    procedure SelectedColorResetTButtonClick(Sender: TObject);
  private
    { Private declarations }
    Picker : THSVColorPicker;
    VPicker : TVColorPicker;

    FColorPreviewer : TveColorPreviewer;
    Styles : TveStyles;
    Activated : boolean;
    procedure PreviewerToPickers;
    procedure PickersToPreviewer;

    procedure PickerChange(Sender: TObject);
    procedure VPickerChange(Sender: TObject);
    function PickerItem : TPickerItem;

    public
    { Public declarations }
    Editor : TveEditor;
    property ColorPreviewer : TveColorPreviewer read FColorPreviewer;
    procedure SaveChanges;
    procedure ReadSettings;
  end;

var
  SetColorsForm: TSetColorsForm;

implementation

uses ClipbrdUtils, Registry, Globals, Painter, RGBHSVUtils;

{$R *.DFM}

// *****************************************************
//        SHOW WHICH ITEM DISPLAYED IN PICKERS
// *****************************************************

function TSetColorsForm.PickerItem : TPickerItem;
begin
    if BodyTRadioButton.Checked then begin
        result := piBody;
    end
    else if PinsTRadioButton.Checked then begin
        result := piPin;
    end
    else if StripsTRadioButton.Checked then begin
        result := piStrip;
    end
    else if SelectedColorTRadioButton.Checked then begin
        result := piSelection;
    end
    else if Net1TRadioButton.Checked then begin
        result := piNet1;
    end
    else if Net2TRadioButton.Checked then begin
        result := piNet2;
    end
    else if Net3TRadioButton.Checked then begin
        result := piNet3;
    end
    else if Net4TRadioButton.Checked then begin
        result := piNet4;
    end
    else if Net5TRadioButton.Checked then begin
        result := piNet5;
    end
    else if Net6TRadioButton.Checked then begin
        result := piNet6;
    end
    else begin
        result := piBoard;
    end;
end;


// *********************************************
//         INITIALIZATION, FINALIZATION
// *********************************************
procedure TSetColorsForm.FormCreate(Sender: TObject);
var
    PickerHeight : integer;
    PickerWidth : integer;

    PickerLeft : integer;
    PickerTop : integer;
begin
    // color previewer is "mini veecad editor"
    FColorPreviewer := TveColorPreviewer.Create(self);
    FColorPreviewer.Parent := PreviewTPanel;
    FColorPreviewer.Top := 0;
    FColorPreviewer.Left := 0;
    FColorPreviewer.Height := PreviewTPanel.Height;
    FColorPreviewer.Width  := PreviewTPanel.Width;

    // calculate picker placement variables
    PickerHeight := (ColorPickersTGroupBox.Width * 5) div 8;
    PickerWidth := PickerHeight;

    PickerLeft := (ColorPickersTGroupBox.Width * 1) div 16;
    PickerTop := ColorPickersTGroupBox.Height -
        ColorPickersTGroupBox.Width div 16 - PickerHeight;

    // color picker show colors of selected board item
    // Picker is color circle setup to show only H,S, but not V(value).
    Picker := THSVColorPicker.Create(self);
    Picker.Parent := ColorPickersTGroupBox;
    Picker.Height := PickerHeight;
    Picker.Width := PickerWidth;
    Picker.Left := PickerLeft;
    Picker.Top := PickerTop;

    // picker changes are shown immediately
    Picker.OnChange := PickerChange;

    // VPicker is vertical strip which allows setting color values
    VPicker := TVColorPicker.Create(self);
    VPicker.Parent := ColorPickersTGroupBox;
    VPicker.Left := (ColorPickersTGroupBox.Width * 7)  div 9;
    VPicker.Top := PickerTop;
    VPicker.Height := PickerHeight;

    // picker changes are shown immediately
    Picker.OnChange := PickerChange;
    VPicker.OnChange := VPickerChange;

    // style files read with this object
    Styles := TveStyles.Create;
end;

procedure TSetColorsForm.FormDestroy(Sender: TObject);
begin
    Styles.Free;
end;

procedure TSetColorsForm.FormShow(Sender: TObject);
begin
    Activated := True;
    ReadSettings;
end;

// ***************************************************
//    READ EXISTING SETTINGS FROM EDITOR & REGISTRY
// ***************************************************

// ALL settings are stored in the ColorPreviewer object properties
// while this form operates, and are modified by the controls
// on this form.

procedure TSetColorsForm.ReadSettings;
begin
    // component line width
    LineWidthTUpDown.Position := Editor.ComponentLineWidth;
    FColorPreviewer.ComponentLineWidth :=  Editor.ComponentLineWidth;

    // Lead width (style)
    case Editor.LeadStyle of

        lsHollow : begin
            LeadStyleTComboBox.ItemIndex := 0;
        end
        // lsLine :
        else begin
            LeadStyleTComboBox.ItemIndex := 1;
        end;
    end;
    FColorPreviewer.LeadStyle := Editor.LeadStyle;

    // scale: we run ColorPreviwer at same scale as main editor
//    FColorPreviewer.PixelsPerCell := Editor.PixelsPerCell;
    FColorPreviewer.PixelsPerCell := Screen.PixelsPerInch div 6;


    // *** COLOR SETTINGS ***
    // shows colors from editor
    FColorPreviewer.BodyColor := Editor.BodyColor;
    FColorPreviewer.PinColor := Editor.PinColor;
    FColorPreviewer.StripColor := Editor.StripColor;
    FColorPreviewer.BoardColor := Editor.BoardColor;
    FColorPreviewer.SelectionColor := Editor.SelectionColor;

    FColorPreviewer.NodeColors[0] := Editor.NodeColors[0];
    FColorPreviewer.NodeColors[1] := Editor.NodeColors[1];
    FColorPreviewer.NodeColors[2] := Editor.NodeColors[2];
    FColorPreviewer.NodeColors[3] := Editor.NodeColors[3];
    FColorPreviewer.NodeColors[4] := Editor.NodeColors[4];
    FColorPreviewer.NodeColors[5] := Editor.NodeColors[5];

    // show color of selected item in the color pickers
    PreviewerToPickers;
end;

// ***************************************************
//        SAVE SETTINGS TO EDITOR & REGISTRY
// ***************************************************

// The latest settings, including user changes, are held in the
// properties of the ColorPreviwer object.  We copy then to
// the running editor and to the registry.

procedure TSetColorsForm.SaveChanges;
begin
    if not Activated then begin
        exit;
    end;

    Editor.BodyColor := ColorPreviewer.BodyColor;
    Editor.PinColor := ColorPreviewer.PinColor;
    Editor.StripColor := ColorPreviewer.StripColor;
    Editor.BoardColor := ColorPreviewer.BoardColor;
    Editor.SelectionColor := ColorPreviewer.SelectionColor;

    Editor.NodeColors[0] := FColorPreviewer.NodeColors[0];
    Editor.NodeColors[1] := FColorPreviewer.NodeColors[1];
    Editor.NodeColors[2] := FColorPreviewer.NodeColors[2];
    Editor.NodeColors[3] := FColorPreviewer.NodeColors[3];
    Editor.NodeColors[4] := FColorPreviewer.NodeColors[4];
    Editor.NodeColors[5] := FColorPreviewer.NodeColors[5];

    Editor.ComponentLineWidth := LineWidthTUpDown.Position;
    Editor.LeadStyle := ColorPreviewer.LeadStyle;
end;

// *********************************************************
//    EVENT HANDLER SLAVES VERT PICKER TO CIRCULAR PICKER
// *********************************************************

procedure TSetColorsForm.PickerChange(Sender: TObject);
begin
    // VPicker tracks hue, saturation of Picker
    VPicker.Hue := Picker.Hue;
    VPicker.Saturation := Picker.Saturation;
end;

// *********************************************************
//       USER CHANGES PICKER COLOR - UPDATES PREVIEWER
// *********************************************************

procedure TSetColorsForm.VPickerChange(Sender: TObject);
begin
    PickersToPreviewer;
end;

// *********************************************************
//    USER CHANGES PICKER ITEM - UPDATES PICKER
// *********************************************************

procedure TSetColorsForm.BodyTRadioButtonClick(Sender: TObject);
begin
    PreviewerToPickers;
    SelectedColorResetTButton.Enabled := SelectedColorTRadioButton.Checked;
end;

// *******************************************************
//        COORDINATE PREVIEWER AND COLOR PICKERS
// *******************************************************

procedure TSetColorsForm.PreviewerToPickers;
var
    Color : TColor;
    H,S,V : integer;
begin
    case PickerItem of
        piBody :  Color := FColorPreviewer.BodyColor;
        piPin  :  Color := FColorPreviewer.PinColor;
        piStrip : Color := FColorPreviewer.StripColor;
        piBoard : Color := FColorPreviewer.BoardColor;
        piSelection : Color := FColorPreviewer.SelectionColor;

        piNet1 : Color := FColorPreviewer.NodeColors[0];
        piNet2 : Color := FColorPreviewer.NodeColors[1];
        piNet3 : Color := FColorPreviewer.NodeColors[2];
        piNet4 : Color := FColorPreviewer.NodeColors[3];
        piNet5 : Color := FColorPreviewer.NodeColors[4];
        piNet6 : Color := FColorPreviewer.NodeColors[5];

        else Color := clBlack;
    end;

    // convert TColor to HSV
    H := GetHValue( Color );
    S := GetSValue( Color );
    V := GetVValue( Color );

    VPicker.OnChange := nil;
    Picker.OnChange := nil;

    // the circular picker gets only the saturation and hue - not the value
    Picker.Hue := H;
    Picker.Saturation := S;
    Picker.Value := 255;

    // the vertical picker gets the value
    VPicker.Hue := H;
    VPicker.Saturation := S;
    VPicker.Value := V;

    Picker.OnChange := PickerChange;
    VPicker.OnChange := VPickerChange;
end;

procedure TSetColorsForm.PickersToPreviewer;
begin
    case PickerItem of
        piPin  :  FColorPreviewer.PinColor := VPicker.SelectedColor;
        piStrip : FColorPreviewer.StripColor := VPicker.SelectedColor;

        piBody :  FColorPreviewer.BodyColor := VPicker.SelectedColor;
        piBoard : FColorPreviewer.BoardColor := VPicker.SelectedColor;

        piNet1 : FColorPreviewer.NodeColors[0] := VPicker.SelectedColor;
        piNet2 : FColorPreviewer.NodeColors[1] := VPicker.SelectedColor;
        piNet3 : FColorPreviewer.NodeColors[2] := VPicker.SelectedColor;
        piNet4 : FColorPreviewer.NodeColors[3] := VPicker.SelectedColor;
        piNet5 : FColorPreviewer.NodeColors[4] := VPicker.SelectedColor;
        piNet6 : FColorPreviewer.NodeColors[5] := VPicker.SelectedColor;

        piSelection : FColorPreviewer.SelectionColor := VPicker.SelectedColor;
    end;
    FColorPreviewer.Paint;
end;

// *********************************************************
//            "SPECIAL" POPUP MENU
// *********************************************************

// ***** SHOW POPUP MENU WHEN BUTTON CLICKED ****
procedure TSetColorsForm.SpecialTButtonClick(Sender: TObject);
var
    Point : TPoint;
begin
    Point.X := SpecialTButton.Left;
    Point.Y := SpecialTButton.Top;

    Point := self.ClientToScreen( Point );

    ClipboardTPopupMenu.Popup( Point.X, Point.Y );
end;

 // ***** MOVE RGB COLORS TO CLIPBOARD ****
procedure TSetColorsForm.CopyColorValuestoClipboard1Click(Sender: TObject);
var
    s : TStringList;
begin
    s := TStringList.Create;
    try
        s.Add( Format('Body=%6.6X', [FColorPreviewer.BodyColor]) );
        s.Add( Format('Pin=%6.6X', [FColorPreviewer.PinColor]) );
        s.Add( Format('Strip=%6.6X', [FColorPreviewer.StripColor]) );
        s.Add( Format('Board=%6.6X', [FColorPreviewer.BoardColor]) );
        s.Add( Format('Selection=%6.6X', [FColorPreviewer.SelectionColor]) );
        WriteClipboardText( s.Text );
    finally
        s.Free;
    end;
end;

// ***** MOVE RGB COLORS FROM CLIPBOARD ****
procedure TSetColorsForm.PasteColorValuesfromClipboard1Click(
  Sender: TObject);

    function Extract( S : TStrings; Name : string; OriginalColor : TColor ) : TColor;
    begin
        result := StrToIntDef( '$' + s.Values[Name], OriginalColor );
    end;

var
    s : TStringList;

begin
    s := TStringList.Create;
    try
        s.Text := ReadClipboardText;
        FColorPreviewer.BodyColor := Extract( S, 'Body', FColorPreviewer.BodyColor );
        FColorPreviewer.PinColor := Extract( S, 'Pin', FColorPreviewer.PinColor );
        FColorPreviewer.StripColor := Extract( S, 'Strip', FColorPreviewer.StripColor );
        FColorPreviewer.BoardColor := Extract( S, 'Board', FColorPreviewer.BoardColor );
        FColorPreviewer.SelectionColor := Extract( S, 'Selection', FColorPreviewer.SelectionColor );
        PreviewerToPickers;
    finally
        s.Free;
    end;
    ColorPreviewer.Paint;
    PreviewerToPickers;
end;


// ********************************************************
//        USER CLICKS RESET SELECTION COLOR BUTTON
// ********************************************************

procedure TSetColorsForm.SelectedColorResetTButtonClick(Sender: TObject);
begin
    FColorPreviewer.SelectionColor := clRed;
    PreviewerToPickers;
    FColorPreviewer.Paint;
end;

// ********************************************************
//          USER CHANGES APPEARANCE CONTROLS
// ********************************************************

procedure TSetColorsForm.LineWidthTUpDownChangingEx(Sender: TObject;
  var AllowChange: Boolean; NewValue: Smallint;
  Direction: TUpDownDirection);
begin
    // display new value
    FColorPreViewer.ComponentLineWidth := NewValue;
    FColorPreViewer.Paint;
end;

procedure TSetColorsForm.LeadStyleTComboBoxChange(Sender: TObject);
const
    IntToLeadStyle : array[0..1] of TLeadStyle = ( lsHollow, lsLine );
begin
    ColorPreviewer.LeadStyle := IntToLeadStyle[LeadStyleTComboBox.ItemIndex];
    ColorPreViewer.Paint;
end;

end.


