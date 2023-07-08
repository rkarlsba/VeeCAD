unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;
type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Memo1: TMemo;
    CloseTButton: TButton;
    ConvertBatchTButton: TButton;
    SingleFileTGroupBox: TGroupBox;
    DisplayLibraryTButton: TButton;
    Button1: TButton;
    procedure CloseTButtonClick(Sender: TObject);
    procedure DisplayLibraryTButtonAClick(Sender: TObject);
    procedure DisplayKicadTButtonClick(Sender: TObject);
    procedure ConvertBatchTButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    Break : boolean;
    SourceFileList : TStringList;
    procedure BuildFileList;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses Read, TinyCadRead, KicadWrite, Rotations;

// **************************************************
//          INITIALISATION, FINALISATION
// **************************************************

procedure TForm1.FormCreate(Sender: TObject);
begin
    SourceFileList := TStringList.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
    SourceFileList.Free;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
    BuildFileList;
end;

procedure TForm1.CloseTButtonClick(Sender: TObject);
begin
    Close;
end;

// *********************************************
//       BUILD LIST OF FILES TO CONVERT
// *********************************************
{ Fill Class variable FileList with all files to
  convert. Reads first command line parameter to
  find name of file or files to convert.
}

procedure TForm1.BuildFileList;
var
    Status : integer;
    SearchRec : TSearchRec;
    Path : string;
    FileName : string;
begin
    // the command line param is either
    // : a file name c:\myfolder\mylib.TCLib
    // : a file spec c:\myfolder\*.TCLib
    // both forms of command line produce a list of zero or more files
    // in SourceFileList[]

    // path leading to files
    Path := ExtractFilePath( ParamStr(1) );

    // individual files to convert
    status := FindFirst( ParamStr(1), 0, SearchRec);
    try
        while Status = 0 do begin//        FirstFileName := SearchRec.Name;
            FileName := Path + SearchRec.Name;
            Memo1.Lines.Add( FileName );
            SourceFileList.Add( FileName );
            Status := FindNext(SearchRec);
        end;
    finally
        FindClose(SearchRec);
    end;

    if SourceFileList.Count = 0 then begin
        Memo1.Lines.Add( 'No files found at ' + ParamStr(1) );
    end;
end;

// ************************************************
//          DISPLAY LIBRARY CONTENTS IN MEMO
// ************************************************

procedure TForm1.DisplayLibraryTButtonAClick(Sender: TObject);

    procedure Say( const s : string );
    begin
       Memo1.Lines.Add( s );
    end;

var
    Reader : TTinyCadReader;
    i : integer;
    Polygon : TPolygon;
    j : integer;
begin
    Break := False;
    Memo1.Lines.Clear;

    if SourceFileList.Count = 0 then begin
        exit;
    end;

    Memo1.Visible := False;
    try
      Reader := TTinyCadReader.Create( SourceFileList[0] );
    try
        while not Reader.EOF do begin

            say( 'Symbol *****' );
            say( Format( 'Name=%s', [Reader.Name] ));
            say( Format( 'Reference=%s', [Reader.Reference] ));
            say( Format( 'Description=%s', [Reader.Description] ));
            say( Format( 'PartsPerPackage=%d', [Reader.PartsPerPackage] ));
            say( Format( 'Package=%s', [Reader.Package] ));

            // PINS
            say( Format( 'PinCount=%d', [Reader.PinCount] ));
            for i := 0 to Reader.PinCount - 1 do begin
                say( Format( '  Number=%s, Name=%s, Part=%d, Pos=(%3.2f,%3.2f), Angle=%s, Length=%3.2f',
                  [ Reader.Pins[i].Number,
                    Reader.Pins[i].Name,
                    Reader.Pins[i].Part,
                    Reader.Pins[i].Position.x, Reader.Pins[i].Position.y,
                    RotationToStr[Reader.Pins[i].Rotation],
                    Reader.Pins[i].Length
                  ]
                 ));
            end;

            // POLYGONS
            for i := 0 to Reader.PolygonCount - 1 do begin
                Polygon := Reader.Polygons[i];
                say( Format( 'Polygon (%3.2f,%3.2f)', [Polygon.Position.x, Polygon.Position.y] ));
                for j := 0 to Polygon.PointCount - 1 do begin
                    say( Format( '  (%3.2f,%3.2f)', [Polygon.Points[j].x, Polygon.Points[j].y] ));
                end;
            end;

            // ARCS
            for i := 0 to Reader.ArcCount - 1 do begin
                say( Format( 'Arc Centre=(%3.2f,%3.2f), Radius=%3.2f, StartAngle=%3.2f, EndAngle=%3.2f',
                  [ Reader.Arcs[i].Centre.x,
                    Reader.Arcs[i].Centre.y,
                    Reader.Arcs[i].Radius,
                    Reader.Arcs[i].StartAngleDegrees,
                    Reader.Arcs[i].EndAngleDegrees
                  ]
                 ));
            end;



            // CIRCLES
            for i := 0 to Reader.CircleCount - 1 do begin
                say( Format( 'Circle Centre=(%3.2f,%3.2f), Radius=%3.2f',
                  [ Reader.Circles[i].Centre.x,
                    Reader.Circles[i].Centre.y,
                    Reader.Circles[i].Radius
                  ]
                 ));
            end;

            // RECTANGLES
            for i := 0 to Reader.RectangleCount - 1 do begin
                say( Format( 'Rectangle (%3.2f,%3.2f), (%3.2f,%3.2f)',
                  [ Reader.Rectangles[i].TopLeft.x,
                    Reader.Rectangles[i].TopLeft.y,
                    Reader.Rectangles[i].BottomRight.x,
                    Reader.Rectangles[i].BottomRight.y
                  ]
                 ));
            end;

            say( '' );

            Reader.Next;
        end;
    finally
        Reader.Free;
    end;

    finally
        Memo1.Visible := True;
    end;
end;


procedure ConvertFile( const SourceFile, DestFile : string );
var
    Reader : TTinyCadReader;
    Writer : TKicadWriter;
begin
    Reader := TTinyCadReader.Create( SourceFile );
    try
        Writer := TKicadWriter.Create;
        Writer.Reader := Reader;
        try
            Writer.WriteToFile( DestFile );
        finally
            Writer.Free;
        end;
    finally
        Reader.Free;
    end;
end;


procedure TForm1.ConvertBatchTButtonClick(Sender: TObject);
var
    DestinationFolder : string;
    i : integer;
    DestFileName : string;
begin
    DestinationFolder := ParamStr(2);
    if not DirectoryExists( DestinationFolder ) then begin
        raise Exception.CreateFmt( 'No such destination folder: %s', [DestinationFolder] );
    end;

    for i := 0 to SourceFileList.Count -1 do begin
        // generate destination file name same as original with 'lib' extension
        DestfileName := DestinationFolder + '\' + ExtractFileName( SourceFileList[i] );
        DestFileName := ChangeFileExt( DestFileName, '.lib' );

        // do conversion
        ConvertFile( SourceFileList[i], DestFileName );
    end;
end;

procedure TForm1.DisplayKicadTButtonClick(Sender: TObject);
var
    Reader : TTinyCadReader;
    Writer : TKicadWriter;
    Stream : TStringStream;
begin
    Memo1.Clear;

    Reader := TTinyCadReader.Create( SourceFileList[0] );
    try
        Writer := TKicadWriter.Create;
        Writer.Reader := Reader;
        try
            Stream := TStringStream.Create;
            try
                Writer.WriteToStream( Stream );
                Memo1.Lines.Text := Stream.DataString;
            finally
                Stream.Free;
            end;
          finally
            Writer.Free;
        end;
    finally
        Reader.Free;
    end;
end;

end.
