unit RadialOutlineEditor;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, RadialOutlines;

const WM_CHANGE = WM_USER + $400;

type
  TveRadialOutlineEditor = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    LeadSpacingTEdit: TEdit;
    DiameterTEdit: TEdit;
    BodyHeightTUpdown: TUpDown;
    BodyWidthTUpdown: TUpDown;
    Pin0NameTEdit: TEdit;
    Pin1NameTEdit: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    procedure DiameterTEditChange(Sender: TObject);
  private
    { Private declarations }
    FOutline : TveRadialOutline;
    FOnChanged : TNotifyEvent;
    procedure SetOutline( value : TveRadialOutline ) ;
    procedure WMCHANGE(var Message: TMessage); message WM_CHANGE;
  public
    { Public declarations }
    property Outline : TveRadialOutline read FOutline write SetOutline;
    property OnChanged : TNotifyEvent read FOnChanged write FOnChanged;
  end;

var
  veRadialOutlineEditor: TveRadialOutlineEditor;

implementation

{$R *.DFM}

procedure TveRadialOutlineEditor.WMCHANGE(var Message: TMessage);
var
    PinName : string;
begin
    if FOutline <> nil then begin
        FOutline.LeadSpacing := StrToInt( LeadSpacingTEdit.Text );
        FOutline.Diameter := StrToInt( DiameterTEdit.Text );
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
        
        if Assigned( FOnChanged ) then begin
            FOnChanged(self);
        end;
    end;
end;


procedure TveRadialOutlineEditor.SetOutline( value : TveRadialOutline ) ;
begin
    // display outline settings in TEdits
    if value <> nil then begin
        //.. prevent on change firing when TEdits changed and altering an Outline
        FOutline := nil;

        LeadSpacingTEdit.Text := IntToStr( value.LeadSpacing );
        DiameterTEdit.Text := IntToStr( value.Diameter );
        Pin0NameTEdit.Text := value.Pins[0].Name;
        Pin1NameTEdit.Text := value.Pins[1].Name;
    end;

    // store new outline we are working with
    FOutline := value;
end;

procedure TveRadialOutlineEditor.DiameterTEditChange(Sender: TObject);
begin
    if (FOutline <> nil) and Assigned(FOnChanged) then begin
        PostMessage( handle, WM_CHANGE, 0, 0 );
    end;
end;

end.