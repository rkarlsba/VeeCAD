unit BoardPattern;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, PatternDisplayer, Board, Project;

type
  TBoardPatternForm = class(TForm)
    FileNamesTListBox: TListBox;
    Panel1: TPanel;
    CancelTButton: TButton;
    OKTButton: TButton;
    ScrollBox1: TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FileNamesTListBoxClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    PatternDisplayer : TvePatternDisplayer;
    PatternFolder : string;
    Board : TbrBoard;
  public
    { Public declarations }
    Project : TveProject;
  end;

var
  BoardPatternForm: TBoardPatternForm;

implementation

{$R *.dfm}

uses BoardSize;

procedure TBoardPatternForm.FormCreate(Sender: TObject);
begin
    PatternDisplayer := TvePatternDisplayer.Create( Self );
    PatternDisplayer.Parent := ScrollBox1;
    PatternDisplayer.Left := 0;
    PatternDisplayer.Top := 0;
    PatternDisplayer.Project.BoardWidth := 50;
    PatternDisplayer.Project.BoardHeight := 50;
    PatternDisplayer.PixelsPerCell := (ScrollBox1.Height) div 38;
end;


procedure TBoardPatternForm.FormShow(Sender: TObject);
var
    PatternFileSpec : string;
    SearchRec : TSearchRec;
    FileName : string;
begin
    Board := Project.Board;

    // folder used by multiple functions on this form
    PatternFolder := ExtractFilePath(ParamStr(0)) + 'Patterns\';
    //PatternFolder := 'C:\Pattern\';

    // first strip type in list is standard stripboard
    FileNamesTListBox.AddItem( 'Stripboard', nil );
    FileNamesTListBox.AddItem( 'Donut', nil );
    FileNamesTListBox.AddItem( 'Tripad', nil );


    // fill list with file names
    PatternFileSpec := PatternFolder + '*.per';

    if SysUtils.FindFirst( PatternFileSpec, 0, SearchRec ) = 0 then begin
        repeat
            FileName := ChangeFileExt(( SearchRec.Name ), '' );
            FileNamesTListBox.AddItem( FileName, nil );
        until FindNext( SearchRec ) <> 0;
        FindClose( SearchRec );
    end;
end;

procedure TBoardPatternForm.FileNamesTListBoxClick(Sender: TObject);

    procedure SetupInBuiltPattern( Pattern : TbrPattern );
    begin
        PatternDisplayer.Project.Clear;
        PatternDisplayer.Project.Board.Width := ScrollBox1.Width div PatternDisplayer.PixelsPerCell;
        PatternDisplayer.Project.Board.Height := ScrollBox1.Height div PatternDisplayer.PixelsPerCell;
        PatternDisplayer.Project.Board.Pattern := Pattern;
        PatternDisplayer.Project.Board.Prepare;
    end;

var
    SelectionIndex : integer;
    FileName : string;
begin
    SelectionIndex := FileNamesTListBox.ItemIndex;

    // invalid selection
    if (SelectionIndex < 0) or (SelectionIndex > FileNamesTListBox.Count) then begin
        exit;
    end;

    // first value is standard stripboard
    if SelectionIndex = 0 then begin
        SetupInBuiltPattern( ptStrip );
    end
    else if SelectionIndex = 1 then begin
        SetupInBuiltPattern( ptDonut );
    end
    else if SelectionIndex = 2 then begin
        SetupInBuiltPattern( ptTripad );
    end
    // following values are names of files
    else begin
        FileName := PatternFolder + FileNamesTListBox.Items[SelectionIndex] + '.per';
        PatternDisplayer.LoadFromFile( FileName );
    end;

    // draw new pattern
    ScrollBox1.HorzScrollBar.Position := 0;
    ScrollBox1.VertScrollBar.Position := 0;
    PatternDisplayer.Paint;
end;

procedure TBoardPatternForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
    if ModalResult <> mrOK then begin
        exit;
    end;

    // if OK button clicked, then use new board
    Board.LoadFromBoard( PatternDisplayer.Project.Board );
    RescueOffBoardItems( Project );
end;


procedure TBoardPatternForm.FormResize(Sender: TObject);
var
    ButtonWidth : integer;
    Centre : integer;
begin
    // centre import and close buttons
    ButtonWidth := CancelTButton.Width;
    Centre := Panel1.Width div 2;

    OKTButton.Left := Centre - ((ButtonWidth * 3) div 2);
    CancelTButton.Left := Centre + (ButtonWidth div 2);
end;


end.
