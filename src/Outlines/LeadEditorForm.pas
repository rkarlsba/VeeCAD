unit LeadEditorForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, SizeableOutlines;

const WM_CHANGE = WM_USER + $400;

type
  TveLeadOutlineEditor = class(TForm)
    BodyLengthTEdit: TEdit;
    BodyWidthTEdit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    BodyHeightTUpdown: TUpDown;
    BodyWidthTUpdown: TUpDown;
    Pin0NameTEdit: TEdit;
    Pin1NameTEdit: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    ReferenceTCheckBox: TCheckBox;
    procedure BodyLengthTEditChange(Sender: TObject);
  private
    { Private declarations }
    FOutline : TveLeadedOutline;
    FOnChanged : TNotifyEvent;
    procedure SetOutline( value : TveLeadedOutline ) ;
    procedure WMCHANGE(var Message: TMessage); message WM_CHANGE;
  public
    { Public declarations }
    property Outline : TveLeadedOutline read FOutline write SetOutline;
    property OnChanged : TNotifyEvent read FOnChanged write FOnChanged;
  end;

var
  veLeadOutlineEditor : TveLeadOutlineEditor;

implementation

{$R *.DFM}


procedure TveLeadOutlineEditor.WMCHANGE(var Message: TMessage);
var
    PinName : string;
begin
    if FOutline <> nil then begin
        FOutline.BodyLength := StrToInt( BodyLengthTEdit.Text );
        FOutline.BodyWidth := StrToInt( BodyWidthTEdit.Text );

        PinName := Trim( Pin0NameTEdit.Text );
        if PinName = '' then begin
            PinName := '1';
        end;
        FOutline.Pins[0].Name := PinName;

        PinName := Trim( Pin1NameTEdit.Text );
        if PinName = '' then begin
            PinName := '2';
        end;
        FOutline.Pins[1].Name := PinName;

        FOutline.ShowReference := ReferenceTCheckBox.Checked;

        if Assigned( FOnChanged ) then begin
            FOnChanged(self);
        end;
    end;
end;


procedure TveLeadOutlineEditor.SetOutline( value : TveLeadedOutline ) ;
begin
    // display outline settings in TEdits
    if value <> nil then begin
        //.. prevent on change firing when TEdits changed and altering an Outline
        FOutline := nil;

        BodyLengthTEdit.Text := IntToStr( value.BodyLength );
        BodyWidthTEdit.Text := IntToStr( value.BodyWidth );
        Pin0NameTEdit.Text := value.Pins[0].Name;
        Pin1NameTEdit.Text := value.Pins[1].Name;
        ReferenceTCheckBox.Checked := value.ShowReference;
    end;

    // store new outline we are working with
    FOutline := value;
end;


procedure TveLeadOutlineEditor.BodyLengthTEditChange(Sender: TObject);
begin
    if (FOutline <> nil) and Assigned(FOnChanged) then begin
        PostMessage( handle, WM_CHANGE, 0, 0 );
    end;
end;

end.
