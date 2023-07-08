unit DebugFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TveDebugNotify = procedure of object;
  TveDebugLineOut = procedure( const s : string ) of object;

  TDebugForm = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    CopyTButton: TButton;
    procedure CopyTButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure DebugStart;
    procedure DebugLineOut( const s : string );
    procedure DebugEnd;
  end;

var
  DebugForm : TDebugForm;

implementation

{$R *.dfm}

procedure TDebugForm.DebugLineOut(const s: string);
begin
    Memo1.Lines.Add( s );
end;

procedure TDebugForm.DebugStart;
begin
    Memo1.Clear;
    Memo1.Lines.BeginUpdate;
end;

procedure TDebugForm.DebugEnd;
begin
    Memo1.Lines.EndUpdate;
end;

procedure TDebugForm.CopyTButtonClick(Sender: TObject);
begin
    Memo1.SelectAll;
    Memo1.CopyToClipboard;
end;


end.
