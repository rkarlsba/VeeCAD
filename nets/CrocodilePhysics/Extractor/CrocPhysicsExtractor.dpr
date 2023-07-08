program CrocPhysicsExtractor;

uses
  Forms,
  main in 'main.pas' {Form1},
  ComponentNameExtract in 'ComponentNameExtract.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
