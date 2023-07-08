program TestVeeCAD;

uses
  Forms,
  main in 'main.pas' {Form1},
  TestCopperTrace in 'TestCopperTrace.pas',
  CopperTrace in '..\Utils\CopperTrace.pas',
  Board in '..\Board.pas',
  ManagedItem in '..\Utils\ManagedItem.pas',
  Intersect in '..\Utils\Intersect.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
