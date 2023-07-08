unit SettingsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Editor, SettingsFrmCursors, 
  SettingsFrmColors, SettingsFrmGraphic, SettingsFrmKeys;

{
type
    TAppearance = class
        public


    end;
}

type
  TSettingsForm = class(TForm)
    Panel1: TPanel;
    OkTButton: TButton;
    CancelTButton: TButton;
    PageControl: TPageControl;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
  private
    { Private declarations }
    SetCursorsForm : TSetCursorsForm;
    SetColorsForm : TSetColorsForm;
    SetGraphicCopyForm : TSetGraphicCopyForm;
    SetKeysForm : TSetKeysForm;

  public
    { Public declarations }
    Editor : TveEditor;
  end;

var
  SettingsForm: TSettingsForm;

implementation

{$R *.DFM}

{
Groups of settings :

1.  Line width :  changes with zoom, so abolute unit of % or 1/1000 of
celll.
   or offer 5 settings.
2.  Cursor size : large and small.
3.  Toolbar buttons : large and small.
}

procedure TSettingsForm.FormCreate(Sender: TObject);

    function AddTab( FormClass : TFormClass ) : TForm;
    var
        TabSheet : TTabSheet;
    begin
        // create a new tabbed page
        TabSheet := TTabSheet.Create(Self);
        TabSheet.PageControl := PageControl;

        // create a form & host it in tabbed page
        result  := FormClass.Create( Self );
        result.Parent := TabSheet;
        result.Align := alClient;
        result.BorderStyle := bsNone;
        result.Show;
        TabSheet.Caption := result.Caption;
        TabSheet.HelpContext  := result.HelpContext;
    end;

begin
    SetCursorsForm := TSetCursorsForm( AddTab( TSetCursorsForm ) );
    SetColorsForm := TSetColorsForm( AddTab(TSetColorsForm) );
    SetGraphicCopyForm := TSetGraphicCopyForm( AddTab(TSetGraphicCopyForm) );
    SetKeysForm := TSetKeysForm( AddTab(TSetKeysForm) );

end;

procedure TSettingsForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
    if ModalResult <> mrOK then begin
        exit;
    end;

    // save results
    SetCursorsForm.SaveChanges;
    SetColorsForm.SaveChanges;
    SetGraphicCopyForm.SaveChanges;
    SetKeysForm.SaveChanges;
end;


{
procedure TSettingsForm.FormResize(Sender: TObject);
var
    ButtonWidth : integer;
    Centre : integer;
begin

    // centre close and refresh buttons
    ButtonWidth := CancelTButton.Width;
    Centre := Panel1.Width div 2;

    OkTButton.Left := Centre + (ButtonWidth div 2);
    CancelTButton.Left := Centre - ((3 * ButtonWidth) div 2);
end;
}

procedure TSettingsForm.FormShow(Sender: TObject);
begin
//    SetGraphicCopyForm.Editor := Editor;
    SetColorsForm.Editor := Editor;
    SetKeysForm.Editor := Editor;

    // show color tab
    PageControl.ActivePageIndex := 1;

    // make Host form have HelpContext of active page, so F1 Help works
    HelpContext := PageControl.ActivePage.HelpContext;
end;

procedure TSettingsForm.PageControlChange(Sender: TObject);
begin
    // make Host form have HelpContext of active page, so F1 Help works
    HelpContext := PageControl.ActivePage.HelpContext;

    // Here is a place to transfer settings from
    // SettingsFrmColors.pas to SettingsFrmGraphic
    if PageControl.ActivePage.TabIndex = 2 then begin
        SetGraphicCopyForm.UpdateColorPreviewer( SetColorsForm.ColorPreviewer );
    end;
end;

end.
