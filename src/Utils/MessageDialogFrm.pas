unit MessageDialogFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TMessageDialogForm = class(TForm)
    OKTButton: TButton;
    CancelTButton: TButton;
    PromptTLabel: TLabel;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }

    function ExecuteAt( X, Y : integer; const ACaption, APrompt : string ): boolean;

    function ExecuteCentered(
        AboveControl : TControl; const ACaption, APrompt : string ): boolean;

  end;

var
  MessageDialogForm: TMessageDialogForm;

implementation

{$R *.dfm}

function TMessageDialogForm.ExecuteAt(
    X, Y : integer; const ACaption, APrompt : string ): boolean;
begin

    // setup screen position
    if X < 0 then begin
        X := 0;
    end
    else if X > Screen.Width - Width then begin
        X := Screen.Width - Width;
    end;

    if Y < 0 then begin
        Y := 0;
    end
    else if Y > Screen.Height - Height then begin
        Y := Screen.Height - Height;
    end;

    Left := X;
    Top := Y;

    // setup text
    Caption := ACaption;
    PromptTLabel.Caption := APrompt;

    // user clicks OK or CANCEL
    result := ShowModal = mrOK;
end;


function TMessageDialogForm.ExecuteCentered(
    AboveControl : TControl; const ACaption, APrompt : string ): boolean;
begin
    result := ExecuteAt(
        AboveControl.Left + ((AboveControl.Width - Width) div 2),
        AboveControl.Top + ((AboveControl.Height - Height) div 2),
        ACaption, APrompt );
end;

procedure TMessageDialogForm.FormShow(Sender: TObject);
begin
    OKTButton.SetFocus;
end;

end.
