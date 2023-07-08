unit SegmentProperties;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,
  TrackItems;

type
  TSegmentPropertiesForm = class(TForm)
    Label1: TLabel;
    StartXTEdit: TEdit;
    Label2: TLabel;
    StartYTEdit: TEdit;
    Label3: TLabel;
    FinishXTEdit: TEdit;
    Label4: TLabel;
    FinishYTEdit: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    Button1: TButton;
    Button2: TButton;
    WarningTLabel: TLabel;
    WidthTEdit: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Segment : TteSegment;
    BoardRect_D : TRect;
  end;

var
  SegmentPropertiesForm: TSegmentPropertiesForm;

implementation

{$R *.dfm}

procedure TSegmentPropertiesForm.FormShow(Sender: TObject);
begin
    // display current start & finish coords of segment
    StartXTEdit.Text := IntToStr( Segment.Start_1000.X );
    StartYTEdit.Text := IntToStr( Segment.Start_1000.Y );
    FinishXTEdit.Text := IntToStr( Segment.Finish_1000.X );
    FinishYTEdit.Text := IntToStr( Segment.Finish_1000.Y );
    WidthTEdit.Text := IntToStr( Segment.Width_1000 );
    // nothing to warn of yet
    WarningTLabel.Caption := '';
end;


procedure TSegmentPropertiesForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
    Start_D : TPoint;
    Finish_D : TPoint;
    Width_D : integer;
begin
    // if escaping form
    if ModalResult <> mrOK then begin
        exit;
    end;

    // read values from controls into temporary variables
    try
        Start_D.X := StrToInt( StartXTEdit.Text );
        Start_D.Y := StrToInt( StartYTEdit.Text );
        Finish_D.X := StrToInt( FinishXTEdit.Text );
        Finish_D.Y := StrToInt( FinishYTEdit.Text );
        Width_D := StrToInt( WidthTEdit.Text );
    except
        WarningTLabel.Caption := 'Only numerals allowed!';
        Action := caNone;
        exit;
    end;

    // values all acceptable, so store them
    Segment.Start_1000.X := Start_D.X;
    Segment.Start_1000.Y := Start_D.Y;
    Segment.Finish_1000.X := Finish_D.X;
    Segment.Finish_1000.Y := Finish_D.Y;
    Segment.Width_1000 := Width_D;

    // keep segment on screen
    Segment.PullInsideRect_D( BoardRect_D );
end;


end.
