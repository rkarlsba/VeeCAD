unit CustomOutlineBasicEditor;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, CustomOutlines, CustomOutlineEditorForm;

// const WM_CHANGE = WM_USER + $400;

type
  TveCustomOutlineBasicEditor = class(TForm)
    EditTButton: TButton;
    procedure EditTButtonClick(Sender: TObject);
  private
    EditorForm : TveCustomOutlineEditorForm;
    FOutline : TveCustomOutline;
    FOnChanged : TNotifyEvent;
    procedure SetOutline( value : TveCustomOutline ) ;
//    procedure WMCHANGE(var Message: TMessage); message WM_CHANGE;
  public
    { Public declarations }
    property Outline : TveCustomOutline read FOutline write SetOutline;
    property OnChanged : TNotifyEvent read FOnChanged write FOnChanged;
  end;

var
  veCustomOutlineBasicEditor: TveCustomOutlineBasicEditor;

implementation

{$R *.DFM}

procedure TveCustomOutlineBasicEditor.SetOutline( value : TveCustomOutline ) ;
begin
    FOutline := Value;
end;


procedure TveCustomOutlineBasicEditor.EditTButtonClick(Sender: TObject);
begin
    // create a custom outline editor form and run it
    EditorForm := TveCustomOutlineEditorForm.Create(nil);
    try
        EditorForm.Outline := FOutline;

        // ?? or should we just "show" - probably doesn't affect the editor
        // form, so either is OK as desirec
        EditorForm.ShowModal;

        //  hack!! need to get changed from EditorForm.ShowModal return value (ModalResult)
        // - add OK - Cancel buttons to EditorForm
        OnChanged( self );
    finally
        EditorForm.Free;
    end;
end;

end.
