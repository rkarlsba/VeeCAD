unit SettingsFrmGraphic;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Spin, ComCtrls,
  ColorPreviewer, ExtCtrls;

type
  TSetGraphicCopyForm = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    ScaleTUpDown: TUpDown;
    ScaleTEdit: TEdit;
    PreviewTPanel: TPanel;
    Label2: TLabel;
    RulersTComboBox: TComboBox;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ScaleTUpDownChangingEx(Sender: TObject; var AllowChange: Boolean;
      NewValue: Smallint; Direction: TUpDownDirection);
  private
    { Private declarations }
    Activated : boolean;
    ColorPreviewer : TveColorPreviewer;
  public
    { Public declarations }
    procedure SaveChanges;
    procedure UpdateColorPreviewer( Previewer : TveColorPreviewer );
  end;

var
  SetGraphicCopyForm: TSetGraphicCopyForm;

implementation

{$R *.DFM}

uses Registry, Globals, ClipbrdGraphic;

procedure TSetGraphicCopyForm.FormCreate(Sender: TObject);
begin
    ColorPreviewer := TveColorPreviewer.Create(self);
//    ColorPreviewer.Align := alClient;
    ColorPreviewer.Parent := PreviewTPanel;
    ColorPreviewer.Top := 0;
    ColorPreviewer.Left := 0;
    ColorPreviewer.Height := PreviewTPanel.Height;
    ColorPreviewer.Width  := PreviewTPanel.Width;
end;


const
    RulerToString : array[TveRuler] of string =
        ( 'None', 'Number',  'LetterNumber' );  


procedure TSetGraphicCopyForm.SaveChanges;
var
    RegIniFile : TRegIniFile;
    GraphicScale : integer;
begin
    if not Activated then begin
        exit;
    end;

    // get last used display size
    RegIniFile := GetRegIniFile;
    try
        GraphicScale := StrToIntDef( ScaleTEdit.Text, 0 );
        if GraphicScale >  ScaleTUpdown.Max then begin
                GraphicScale := ScaleTUpdown.Max;
        end
        else if GraphicScale <  ScaleTUpdown.Min then begin
                GraphicScale := ScaleTUpdown.Min;
        end;

        RegIniFile.WriteInteger(
            'GraphicCopy', 'PixelsPerCell', GraphicScale );

        RegIniFile.WriteString(
            'GraphicCopy', 'Rulers', RulerToString[TveRuler(RulersTComboBox.ItemIndex)] );
    finally
        RegIniFile.Free;
    end;
end;

procedure TSetGraphicCopyForm.FormShow(Sender: TObject);
var
    RegIniFile : TRegIniFile;
    Scale : integer;
    RulerString : string;
    Ruler : TveRuler;
begin
    Activated := True;

    // get last used display size
    RegIniFile := GetRegIniFile;
    try
        Scale :=
            RegIniFile.ReadInteger( 'GraphicCopy', 'PixelsPerCell', 24 );

        RulerString := RegIniFile.ReadString( 'GraphicCopy', 'Rulers', '' );
    finally
        RegIniFile.Free;
    end;

    if RulerString = 'Number' then begin
        Ruler := ruNumber
    end

    else if RulerString = 'LetterNumber' then begin
        Ruler := ruLetterNumber
    end

    else begin
        Ruler := ruNone;
    end;

    // display changes
    RulersTComboBox.ItemIndex := Ord( Ruler );
    ScaleTUpDown.Position := Scale;
    ColorPreViewer.PixelsPerCell := Scale;
    ColorPreViewer.Paint;
end;

procedure TSetGraphicCopyForm.ScaleTUpDownChangingEx(Sender: TObject;
  var AllowChange: Boolean; NewValue: Smallint; Direction: TUpDownDirection);
begin
    // this event fires even when 1 below minimum, so catch it here
    if NewValue < ScaleTUpDown.Min then begin
        AllowChange := False;
        Exit;
    end;

    ColorPreViewer.PixelsPerCell := NewValue;
    ColorPreViewer.Paint;
end;

procedure TSetGraphicCopyForm.UpdateColorPreviewer( Previewer : TveColorPreviewer );
begin
    ColorPreviewer.BodyColor := Previewer.BodyColor;
    ColorPreviewer.PinColor := Previewer.PinColor;
    ColorPreviewer.StripColor := Previewer.StripColor;
    ColorPreviewer.BoardColor := Previewer.BoardColor;
    ColorPreViewer.ComponentLineWidth := Previewer.ComponentLineWidth;
    ColorPreviewer.LeadStyle := Previewer.LeadStyle; 
end;

end.
