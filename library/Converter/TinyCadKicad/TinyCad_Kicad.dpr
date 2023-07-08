program TinyCad_Kicad;

uses
  Forms,
  main in 'main.pas' {Form1},
  KicadWrite in 'KicadWrite.pas',
  Rotations in 'Rotations.pas',
  Windows,
  Rectangles in 'Rectangles.pas',
  NativeXml in '..\Common\NativeXml.pas',
  Read in '..\Common\Read.pas',
  SQLite3 in '..\Common\SQLite3.pas',
  SQLiteWrap in '..\Common\SQLiteWrap.pas',
  TinyCadRead in '..\Common\TinyCadRead.pas';

{$R *.res}

begin
  // visual mode
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
