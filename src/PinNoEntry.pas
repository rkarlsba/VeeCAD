unit PinNoEntry;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TPinNoEntryForm = class(TForm)
    NumberTEdit: TEdit;
    Label1: TLabel;
    Button1: TButton;
    Button2: TButton;
    WarningTLabel: TLabel;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FPinName : string;
    procedure SetPinName( value : string );
  public
    { Public declarations }
    property PinName : string read FPinName write SetPinName;
  end;

var
  PinNoEntryForm: TPinNoEntryForm;

implementation

{$R *.DFM}


procedure TPinNoEntryForm.FormShow(Sender: TObject);
begin
    WarningTLabel.Caption := '';
    NumberTEdit.SetFocus;
    NumberTEdit.SelectAll;
end;

procedure TPinNoEntryForm.SetPinName( value : string );
begin
    FPinName := Trim(value);
    NumberTEdit.Text := FPinName;
end;

procedure TPinNoEntryForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    if ModalResult <> mrOK then begin
        exit;
    end;

    FPinName := Trim( NumberTEdit.Text );

    if FPinName = '' then begin
        WarningTLabel.Caption := 'Pin Name is blank!';
        NumberTEdit.Text := FPinName;
        CanClose := False;
    end;
end;


end.
