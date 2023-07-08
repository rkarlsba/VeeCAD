unit NewItem;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TNewItemForm = class(TForm)
    DesignatorTEdit: TEdit;
    Label1: TLabel;
    ValueTEdit: TEdit;
    Label2: TLabel;
    OKTButton: TButton;
    CancelTButton: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FDesignator : string;
    FValue : string;
  public
    { Public declarations }
    property Designator : string read FDesignator;
    property Value : string read FValue;
  end;

var
  NewItemForm: TNewItemForm;

implementation

{$R *.DFM}

procedure TNewItemForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
    if ModalResult <> mrOK then begin
        exit;
    end;

    FDesignator := Trim( Uppercase( DesignatorTEdit.Text ));
    FValue := Trim( Uppercase( ValueTEdit.Text ));
end;

end.
