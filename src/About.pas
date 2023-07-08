unit About;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TAboutForm = class(TForm)
    VersionTLabel: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    OKTButton: TButton;
    LinkTEdit: TEdit;
    Label3: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }

  public
    { Public declarations }
  end;

var
  AboutForm: TAboutForm;

implementation

{$R *.DFM}

uses Version;

procedure TAboutForm.FormCreate(Sender: TObject);
var
    // version info
    Major, Minor, Release, Build : integer;
    PreRelease, Debug : boolean;
    Description : string;
begin
    GetFileVersion( ParamStr(0),
        Major, Minor, Release, Build,
        PreRelease, Debug,
        Description );
    VersionTLabel.Caption := Description;
end;

procedure TAboutForm.FormShow(Sender: TObject);
var
    TextSize : TSize;
    TextWidth : integer;
begin
    // Edit control allows user to wipe with mouse and copy to clipboard.
    // However, TEdit controls do not center text, so we do so in code here.

    //... find out size of text in edit control.  TEdit has ParentFont = True,
    // so we find size on Form Canvas.
    TextSize := Canvas.TextExtent( LinkTEdit.Text );
    TextWidth := TextSize.cx;
    LinkTEdit.Left := ( Width - TextWidth ) div 2;
end;


end.
