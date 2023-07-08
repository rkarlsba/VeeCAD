unit SettingsFrmCursors;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Cursors;

type
  TSetCursorsForm = class(TForm)
    GroupBox1: TGroupBox;
    SmallTRadioButton: TRadioButton;
    LargeTRadioButton: TRadioButton;
    Image1: TImage;
    Image2: TImage;
    procedure FormCreate(Sender: TObject);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GroupBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    OriginalSize : TCursorSize;
    Activated : boolean;
  public
    { Public declarations }
    procedure SaveChanges;
  end;

var
  SetCursorsForm: TSetCursorsForm;

implementation                          

{$R *.DFM}

procedure TSetCursorsForm.SaveChanges;
begin
    if not Activated then begin
        exit;
    end;

    if SmallTRadioButton.Checked then begin
        CursorMinder.Size := szSmall;
    end
    else begin
        CursorMinder.Size := szLarge;
    end;

    if CursorMinder.Size <> OriginalSize then begin
        CursorMinder.SaveSettings;
    end;
end;

procedure TSetCursorsForm.FormCreate(Sender: TObject);
begin
    OriginalSize := CursorMinder.Size;
    if OriginalSize = szSmall then begin
        SmallTRadioButton.Checked := True;
    end
    else begin
        LargeTRadioButton.Checked := True;
    end;

    Activated := True;
end;

procedure TSetCursorsForm.Image2MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    SmallTRadioButton.Checked := True;
end;

procedure TSetCursorsForm.Image1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    LargeTRadioButton.Checked := True;
end;


procedure TSetCursorsForm.GroupBox1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    if Y < (( SmallTRadioButton.Top + LargeTRadioButton.Top ) div 2) then begin
        SmallTRadioButton.Checked := True;
    end
    else begin
        LargeTRadioButton.Checked := True;
    end;
end;

end.
