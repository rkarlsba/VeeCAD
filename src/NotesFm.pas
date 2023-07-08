unit NotesFm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  Project;

type
  TNotesForm = class(TForm)
    Panel1: TPanel;
    PrintTButton: TButton;
    CopyTButton: TButton;
    CloseTButton: TButton;
    Memo1: TMemo;
    procedure FormResize(Sender: TObject);
    procedure CloseTButtonClick(Sender: TObject);
    procedure CopyTButtonClick(Sender: TObject);
    procedure PrintTButtonClick(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
  private
    { Private declarations }
    Changed : boolean;
  public
    { Public declarations }
    Project : TveProject;
    procedure UpdateInfo;
  end;

var
  NotesForm: TNotesForm;

implementation

{$R *.dfm}

uses PrintReport, Globals;

// ********************************************
//    HIDE FORM ON CLOSE BUTTON OR ESC KEY
// ********************************************

procedure TNotesForm.CloseTButtonClick(Sender: TObject);
begin
    Hide;
end;

{
procedure TNotesForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
     if Key = VK_ESCAPE then begin
          Hide;
     end;
end;
}
// ********************************************
//    ADJUST BUTTON POSITIONS ON FORM RESIZE
// ********************************************

procedure TNotesForm.FormResize(Sender: TObject);
var
    Spacing : integer;
begin
    Spacing := CloseTButton.Width div 6;

    // Position Close Button at left
    CloseTButton.Left := Spacing * 2;

    // Position Print Button at right, with Copy, Refresh buttons nearby
    PrintTButton.Left := Panel1.Width - PrintTButton.Width - (Spacing * 2);
    CopyTButton.Left := PrintTButton.Left - CopyTButton.Width - Spacing;
end;


// ********************************************
//            COPY TO CLIPBOARD
// ********************************************

procedure TNotesForm.CopyTButtonClick(Sender: TObject);
begin
    Memo1.SelectAll;
    Memo1.CopyToClipboard;
end;


 // ************************************************
//        PRINT THE CURRENTLY SHOWING MEMO
// ************************************************
procedure TNotesForm.PrintTButtonClick(Sender: TObject);
var
    ReportPrinter : TPrintReportForm;
begin
    // This form has position = poOwnerFormCenter, do must have AOwner
    // param set to this form, not to nil
    ReportPrinter := TPrintReportForm.Create(self);
    try
        ReportPrinter.HKEY_CURRENT_USER_key := Globals.HKEY_CURRENT_USER_KEY;
        ReportPrinter.ReportStrings := Memo1.Lines;
        ReportPrinter.PrinterTitle := 'VeeCAD Report';
        ReportPrinter.Caption := 'Print: ' + 'Notes';

        // title for each page, including page number at %d format
        ReportPrinter.PageTitle :=
            'Notes : .  Page %d';
        ReportPrinter.Execute;
    finally
        ReportPrinter.Free;
    end;
end;


// *******************************************
//       TRANSFER EDITS TO PROJECT
// *******************************************

procedure TNotesForm.Memo1Change(Sender: TObject);
begin
    Changed := True;
end;

procedure TNotesForm.FormDeactivate(Sender: TObject);
begin
    if assigned(Project) then begin
       if Changed then begin
           Project.NotesLines := Memo1.Text;
           Project.Dirty := True;
           Changed := False;
       end;
    end;
end;

procedure TNotesForm.UpdateInfo;
begin
    if assigned(Project) then begin
        Memo1.Text := Project.NotesLines;
        Changed := False;
    end;
end;


end.
