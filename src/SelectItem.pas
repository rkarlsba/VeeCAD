unit SelectItem;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,
  Editor, Project;

type
  TSelectItemForm = class(TForm)
    ItemTComboBox: TComboBox;
    Button1: TButton;
    Button2: TButton;
    MessageTLabel: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ItemTComboBoxChange(Sender: TObject);
    procedure ItemTComboBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
    Editor : TveEditor;
  end;

var
    SelectItemForm: TSelectItemForm;

implementation

{$R *.DFM}

uses Outlines, CelledOutlines, SizeableOutlines;


// On Form Show, fill ComboBox with list of BoardItems

procedure TSelectItemForm.FormShow(Sender: TObject);
var
    i : integer;
    Item : TveBoardItem;
    Project : TveProject;
begin
    ItemTComboBox.Items.Clear;
    ItemTComboBox.Text := '';
    MessageTLabel.Caption := '';

    if (Editor = nil) or (Editor.Project = nil) then begin
        exit;
    end;

    Project := Editor.Project;
    for i := 0 to Editor.Project.BoardItemCount -1 do begin
        Item := Project.BoardItems[i];
        if Item.Outline.UserDefined then begin
            ItemTComboBox.Items.AddObject( Item.Designator, Item );
        end;
    end;
end;

// User Clicks OK - Use ComboBox State to Find Item Selected and Get Project
// to Select this Item.  If no such item, show message and keep Form Open.

procedure TSelectItemForm.FormClose(Sender: TObject;
  var Action: TCloseAction);

var
    Item : TveBoardItem;
    Index : integer;
begin
    if (ModalResult <> mrOK) or (Editor = nil) or (Editor.Project = nil) then begin
        exit;
    end;

    // if item selected from list
    if ItemTComboBox.ItemIndex <> -1 then begin
        Index := ItemTComboBox.ItemIndex;
    end

    // item not selected from list - try to match any user entered text with
    // a list item.
    else begin
        Index := ItemTComboBox.Items.IndexOf( ItemTComboBox.Text );

         // if text not matched in list, then show message & keep form open
        if Index = -1 then begin
            MessageTLabel.Caption := 'Item not found';
            Action := caNone;
            exit;
        end;
    end;

    // tell project to highlight this item
    Item := TveBoardItem(ItemTComboBox.Items.Objects[Index]);
    Editor.SelectItem( Item );
end;

// Hide Error Message When User Changes Input into ComboBox

procedure TSelectItemForm.ItemTComboBoxChange(Sender: TObject);
begin
    MessageTLabel.Caption := '';
end;


// Turn Enter key press into OK button
procedure TSelectItemForm.ItemTComboBoxKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
    if Key = VK_RETURN then begin
        ModalResult := mrOK;
    end;
end;

end.
