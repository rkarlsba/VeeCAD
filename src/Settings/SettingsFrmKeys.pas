unit SettingsFrmKeys;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Editor;

type
  TSetKeysForm = class(TForm)
    GroupBox1: TGroupBox;
    Image1: TImage;
    SelectTComboBox: TComboBox;
    GroupBox2: TGroupBox;
    Image2: TImage;
    BreakTComboBox: TComboBox;
    GroupBox3: TGroupBox;
    Image3: TImage;
    LinkTComboBox: TComboBox;
    GroupBox4: TGroupBox;
    Image4: TImage;
    WireTComboBox: TComboBox;
    GroupBox5: TGroupBox;
    Image5: TImage;
    RedrawTComboBox: TComboBox;
    TextModeTGroupBox: TGroupBox;
    Image6: TImage;
    TextTComboBox: TComboBox;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    Activated : boolean;
  public
    { Public declarations }
    Editor : TveEditor;
    procedure SaveChanges;
    procedure ReadSettings;
  end;

var
  SetKeysForm: TSetKeysForm;

implementation

{$R *.dfm}

uses Menus, Registry, Globals;

{   USEFUL FUNCTIONS IN MENUS.PAS
function ShortCut(Key: Word; Shift: TShiftState): TShortCut;
procedure ShortCutToKey(ShortCut: TShortCut; var Key: Word; var Shift: TShiftState);
function ShortCutToText(ShortCut: TShortCut): string;
function TextToShortCut(Text: string): TShortCut;
function ShortCutFromMessage(Message: TWMKey): TShortCut;
}


// Array of keycodes - these match those provided by any keydown handler
// KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
// This list does not have Shift, Ctrl, Alt etc modifiers, because I think
// that would make the hot keys less convenient.  However, modifiers can be
// added easily, because the TShortCut data type can include modifiers.

const Keys : array[0..47] of WORD =
(
    VK_ESCAPE,
    {VK_F1,}
    VK_F2, VK_F3, VK_F4, VK_F5, VK_F6,
    VK_F7, VK_F8, VK_F9, VK_F10, VK_F11,
    VK_F12,

    WORD('0'), WORD('1'), WORD('2'), WORD('3'), WORD('4'),
    WORD('5'), WORD('6'), WORD('7'), WORD('8'), WORD('9'),

    WORD('A'), WORD('B'), WORD('C'), WORD('D'), WORD('E'),
    WORD('F'), WORD('G'), WORD('H'), WORD('I'), WORD('J'),
    WORD('K'), WORD('L'), WORD('M'), WORD('N'), WORD('O'),
    WORD('P'), WORD('Q'), WORD('R'), WORD('S'), WORD('T'),
    WORD('U'), WORD('V'), WORD('W'), WORD('X'), WORD('Y'),
    WORD('Z')
);

procedure LoadComboBox( Box : TComboBox; aShortCut : TShortCut );
var
    i : integer;
begin
    // fill ComboBox with all shortcuts available
    Box.Clear;
    for i := Low(Keys) to High(Keys) do begin
        Box.Items.Add( ShortCutToText( ShortCut( Keys[i], [] )) );
    end;

    // set ComboBox to show our shortcut
    Box.ItemIndex := Box.Items.IndexOf( ShortCutToText( aShortCut ) );
end;

function ReadComboBox( Box : TComboBox ) : TShortCut;
var
    Index : integer;
begin
    Index := Box.ItemIndex;

    // if nothing selected, then set no shortcut
    if Index < 0 then begin
        result := TShortCut( 0 );
        exit;
    end;

    // convert selected item text to a  TShortCut
    // TextToShortCut() returns 0 if text is not a valid shortcut
    result := TextToShortCut( Box.Items[ Box.ItemIndex ] );
end;



procedure TSetKeysForm.ReadSettings;
begin
    // load comboboxes with initial choices
    LoadComboBox( SelectTComboBox, Editor.SelectModeShortCut );
    LoadComboBox( BreakTComboBox, Editor.BreakModeShortCut );
    LoadComboBox( LinkTComboBox, Editor.LinkModeShortCut );
    LoadComboBox( WireTComboBox, Editor.WireModeShortCut );
    LoadComboBox( TextTComboBox, Editor.TextModeShortCut );
    LoadComboBox( RedrawTComboBox, Editor.RedrawShortCut );
end;

procedure TSetKeysForm.FormShow(Sender: TObject);
begin
    Activated := True;
    ReadSettings;
end;


procedure TSetKeysForm.SaveChanges;
var
    RegIniFile : TRegIniFile;
begin
    if not Activated {also test if changed}then begin
        exit;
    end;

    // put new settings into Editor
    Editor.SelectModeShortCut := ReadComboBox( SelectTComboBox );
    Editor.BreakModeShortCut := ReadComboBox( BreakTComboBox );
    Editor.LinkModeShortCut := ReadComboBox( LinkTComboBox );
    Editor.WireModeShortCut := ReadComboBox( WireTComboBox );
    Editor.TextModeShortCut := ReadComboBox( TextTComboBox );
    Editor.RedrawShortCut := ReadComboBox( RedrawTComboBox );

    // save new settings in Registry
    RegIniFile := GetRegIniFile;
    try
        RegIniFile.WriteInteger( 'Keys', 'Select', Editor.SelectModeShortCut );
        RegIniFile.WriteInteger( 'Keys', 'Break',  Editor.BreakModeShortCut );
        RegIniFile.WriteInteger( 'Keys', 'Link',   Editor.LinkModeShortCut );
        RegIniFile.WriteInteger( 'Keys', 'Wire',   Editor.WireModeShortCut );
        RegIniFile.WriteInteger( 'Keys', 'Text',   Editor.TextModeShortCut );
        RegIniFile.WriteInteger( 'Keys', 'Redraw', Editor.RedrawShortCut );
    finally
        RegIniFile.Free;
    end;
end;



end.


