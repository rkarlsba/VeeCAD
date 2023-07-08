unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    TestCopperTraceTButton: TButton;
    procedure TestCopperTraceTButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses TestCopperTrace;

procedure TForm1.TestCopperTraceTButtonClick(Sender: TObject);
begin
    TestLinesIntersect;
    TestSegmentToRect;
end;

end.
