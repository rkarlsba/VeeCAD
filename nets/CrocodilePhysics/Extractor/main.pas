unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    CIRFileNameTEdit: TEdit;
    Label1: TLabel;
    CIRFileNameTButton: TButton;
    WriteComponentNameFileTButton: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Memo1: TMemo;
    Label2: TLabel;
    ReadCIRFileTButton: TButton;
    procedure CIRFileNameTButtonClick(Sender: TObject);
    procedure WriteComponentNameFileTButtonClick(Sender: TObject);
    procedure ReadCIRFileTButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses ComponentNameExtract;

procedure TForm1.CIRFileNameTButtonClick(Sender: TObject);
begin
    OpenDialog1.InitialDir := ExtractFilePath( ParamStr(0) );
    OpenDialog1.Filter := 'Croc Physics files (*.cir)|*.CIR|All files (*.*)|*.*';
    if OpenDialog1.Execute then begin
        CIRFileNameTEdit.Text := OpenDialog1.FileName;
    end;
end;

procedure TForm1.ReadCIRFileTButtonClick(Sender: TObject);
var
    Input : TStringlist;
begin
    Input := TStringlist.Create;
    try
        Input.LoadFromFile( CIRFileNameTEdit.Text );
        ExtractCrocPhysicsComponentNames( Input, Memo1.Lines );
    finally
        Input.Free;
    end;
end;

procedure TForm1.WriteComponentNameFileTButtonClick(Sender: TObject);
begin
    SaveDialog1.InitialDir := ExtractFilePath( CIRFileNameTEdit.Text );
    SaveDialog1.Filter := 'Text Files (*.txt)|*.TXT|All Files (*.*)|*.*';
    if SaveDialog1.Execute then begin
        Memo1.Lines.SaveToFile( SaveDialog1.FileName );
    end;
end;

end.
