unit GcodeFm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,

  Project;

type TgcReport = (rptTrackCuts, rptTopOutlines);

type
  TGcodeForm = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Panel1: TPanel;
    FileNameTEdit: TEdit;
    FileNameTButton: TButton;
    Label1: TLabel;
    SaveTButton: TButton;
    CopyTButton: TButton;
    procedure FormShow(Sender: TObject);
    procedure SaveTButtonClick(Sender: TObject);
    procedure FileNameTButtonClick(Sender: TObject);
    procedure CopyTButtonClick(Sender: TObject);
  private
    { Private declarations }
    FProjectFileName : string;
  public
    { Public declarations }
    ReportType : TgcReport;
    Project : TveProject;
    property ProjectFileName : string read FProjectFileName write FProjectFileName;
  end;
var
  GcodeForm: TGcodeForm;

implementation

{$R *.dfm}

uses Gcode, GcodeTop;

// ***********************************************
//    ON SHOW GENERATE G-CODE AND SHOW IN MEMO
// ***********************************************
procedure TGcodeForm.FormShow(Sender: TObject);
const FileAppends : array[TgcReport] of string = ('-Gcode.txt', '-GcodeTop.txt');

begin
    // generate default save filename
    FileNameTEdit.Text :=
        Copy(
            FProjectFileName, 1,
            Length(FProjectFileName) - Length( ExtractFileExt(FProjectFileName) )
        )
        + FileAppends[ReportType];

    // write G-Code into Memo
    case ReportType of
      rptTrackCuts: begin
          screen.Cursor := crHourglass;
          try
            MakeCutTracksGcode( Memo1.Lines, Project );
          finally
            screen.Cursor := crDefault;
          end;
          Caption := 'G-code Track Cuts';
      end;
      rptTopOutlines: begin
          screen.Cursor := crHourglass;
          try
            MakeTopGCode( Memo1.Lines, Project );
          finally
            screen.Cursor := crDefault;
          end;
          Caption := 'G-code Links & Components';
      end;
    end;
end;

// ***********************************************
//      USER CLICKS COPY TO CLIPBOARD BUTTON
// ***********************************************

procedure TGcodeForm.CopyTButtonClick(Sender: TObject);
begin
    Memo1.SelectAll;
    Memo1.CopyToClipboard;
end;

// ***********************************************
//        USER CLICKS SAVE FILE BUTTON
// ***********************************************

{ Gcode uses EIA format, which is identical to 7 bit ISO/ASCII, except that
some ISO/ASCII codes are not defined. :#$'*;<=>? @ " are not defined.
So, always use 7 bit ASCII encoding. }

procedure TGcodeForm.SaveTButtonClick(Sender: TObject);
begin
    Memo1.Lines.SaveToFile( FileNameTEdit.Text, TEncoding.ASCII);
    Close;
//    Memo1.Lines.SaveToFile( FileNameTEdit.Text, TEncoding.Default); // system ANSI
//    Memo1.Lines.SaveToFile( FileNameTEdit.Text, TEncoding.UTF8);
end;

// ***********************************************
//      USER CLICKS BROWSE FOR FILE BUTTON
// ***********************************************

procedure TGcodeForm.FileNameTButtonClick(Sender: TObject);
var
    SaveDialog : TSaveDialog;
begin
    SaveDialog := TSaveDialog.Create(self);
    try
        SaveDialog.Options := [];
        SaveDialog.InitialDir := ExtractFilePath( ParamStr(0) );
        SaveDialog.Filter := 'Text Files (*.txt)|*.TXT|All Files (*.*)|*.*';
        SaveDialog.FileName := FileNameTEdit.Text;
        if SaveDialog.Execute then begin
           FileNameTEdit.Text := SaveDialog.FileName;
        end;
    finally
        SaveDialog.Free;
    end;
end;

end.
