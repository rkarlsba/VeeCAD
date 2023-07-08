unit BoardSettings;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,
  Project;

type
  TBoardSettingsForm = class(TForm)
    OKTButton: TButton;
    CancelTButton: TButton;
    Label1: TLabel;
    WidthTEdit: TEdit;
    MinWidthTLabel: TLabel;
    MinHeightTLabel: TLabel;
    HeightTEdit: TEdit;
    Label6: TLabel;
    WarningTLabel: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FProject : TveProject;
    RequiredLeft, RequiredRight, RequiredTop, RequiredBottom : integer;

  public
    { Public declarations }
    property Project : TveProject read FProject write FProject;
  end;

var
  BoardSettingsForm: TBoardSettingsForm;

implementation

{$R *.DFM}

uses ProjectCheck, BoardSize, Math, Board;

procedure TBoardSettingsForm.FormShow(Sender: TObject);
var
    TrackMinWidth, TrackMinHeight : integer;
    Board : TbrBoard;
begin
    // hide warning label
    WarningTLabel.Caption := '';

    //
    Board := FProject.Board;

    // display current width and height
    WidthTEdit.Text := IntToStr( Board.Width );
    HeightTEdit.Text := IntToStr( Board.Height );

    // find minimum board size required to hold tracks
    RequiredStripArea( Project, TrackMinWidth, TrackMinHeight );

    // find rectangle holding all components
    CalcRequiredBoardRectangle(
        Project, RequiredLeft, RequiredRight, RequiredTop, RequiredBottom );

    // combine track and component required dimensions
    RequiredRight := Max( RequiredRight, TrackMinWidth );
    RequiredBottom := Max( RequiredBottom, TrackMinHeight );

    // display minimum board size required to hold components and tracks
    MinWidthTLabel.Caption := Format( '(Min %d)', [RequiredRight] );
    MinHeightTLabel.Caption := Format( '(Min %d)', [RequiredBottom] );
end;

procedure TBoardSettingsForm.FormClose(Sender: TObject;
  var Action: TCloseAction);

var
    Width, Height : integer;
    Board : TbrBoard;
begin

    // if escaping form
    if ModalResult <> mrOK then begin
        exit;
    end;

    // remove any previous warning
    WarningTLabel.Caption := '';

    //
    Board := FProject.Board;

    // read user entered board dimensions
    try
        Width := StrToInt( WidthTEdit.Text );
        Height := StrToInt( HeightTEdit.Text );
    except
        WarningTLabel.Caption := 'Only numerals allowed!';
        Action := caNone;
        exit;
    end;

    // check if board wide enough to fit components
    if Width < RequiredRight then begin
        WarningTLabel.Caption :=
            Format('X must be at least %d', [RequiredRight]);
        Action := caNone;
        exit;
    end;

    // check if board high enough to fit components
    if Height < RequiredBottom then begin
        WarningTLabel.Caption :=
            Format('Y must be at least %d', [RequiredBottom]);
        Action := caNone;
        exit;
    end;

    // implement user entered values - FProject may reduce these values
    // if too big.
    Board.Width := StrToInt( WidthTEdit.Text );
    Board.Height := StrToInt( HeightTEdit.Text );

    // built-in patterns always fill the board area, so recalculate strips
    if Board.Pattern <> ptDefined then begin
        FProject.Board.Clear;
        FProject.Board.Prepare;
    end;

    // Move any off board components back onto board so fully inside
    // board boundaries - these components will be left of or above
    // 0,0 board origin or possibly beyond max allowable height or width
    // of board.
    RescueOffBoardItems( FProject );

    // undo is no longer possible, because it may move a component off board
    FProject.ClearUndo;
end;

end.
