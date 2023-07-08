unit InputBoxFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TInputBoxForm = class(TForm)
    InputTEdit: TEdit;
    PromptTLabel: TLabel;
    OKTButton: TButton;
    CancelTButton: TButton;
    procedure FormShow(Sender: TObject);
    procedure InputTEditKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }

  public
    { Public declarations }

    function ExecutePos( X, Y : integer; const
        ACaption, APrompt, ADefault: string): string;

    function ExecuteAt( X, Y : integer; const
        ACaption, APrompt, ADefault: string; var Output : string ): boolean;

    function ExecuteCentered( AboveControl : TControl;
        const ACaption, APrompt, ADefault: string; var Output : string ): boolean;


  end;

var
  InputBoxForm: TInputBoxForm;

implementation

{$R *.DFM}

function TInputBoxForm.ExecutePos( X, Y : integer; const
        ACaption, APrompt, ADefault: string): string;
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
    InputTEdit.Text := ADefault;

    // user clicks OK or ENTER
    if ShowModal = mrOK then begin
        result := InputTEdit.Text;
    end

    // user cancels
    else begin
        result := ADefault;
    end;
end;


function TInputBoxForm.ExecuteAt( X, Y : integer; const
    ACaption, APrompt, ADefault: string; var Output : string ): boolean;
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
    InputTEdit.Text := ADefault;

    // user clicks OK or ENTER
    if ShowModal = mrOK then begin
        Output := InputTEdit.Text;
        result := True;
    end

    // user cancels
    else begin
        Output := ADefault;
        result := False;
    end;
end;


function TInputBoxForm.ExecuteCentered( AboveControl : TControl;
    const ACaption, APrompt, ADefault: string; var Output : string ): boolean;
begin
    result := ExecuteAt(
        AboveControl.Left + ((AboveControl.Width - Width) div 2),
        AboveControl.Top + ((AboveControl.Height - Height) div 2),
        ACaption, APrompt, ADefault, Output );
end;


procedure TInputBoxForm.FormShow(Sender: TObject);
begin
    // default button is OK
    InputTEdit.SelectAll;
    InputTEdit.SetFocus;
end;



procedure TInputBoxForm.InputTEditKeyPress(Sender: TObject; var Key: Char);
begin
    if key = #13 then begin
        ModalResult := mrOK;
    end;
end;

end.
