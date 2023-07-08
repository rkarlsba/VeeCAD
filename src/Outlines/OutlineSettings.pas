unit OutlineSettings;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Grids, Menus,
  Project, OutlineDisplayer,
  Outlines, Adjuster,
  CellOutlineEditor, LeadEditorForm, RadialOutlineEditor, CustomOutlineBasicEditor,
  ClipbrdOutlines;

type
  TOutlineSettingsForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    ScrollBox1: TScrollBox;
    OKTButton: TButton;
    RenameTButton: TButton;
    NewTButton: TButton;
    DeleteTButton: TButton;
    Groupbox1: TGroupBox;
    OutlineClassTLabel: TLabel;
    GroupBox2: TGroupBox;
    LeadedTRadioButton: TRadioButton;
    CelledTRadioButton: TRadioButton;
    NoImportTCheckBox: TCheckBox;
    RadialTRadioButton: TRadioButton;
    ListBox: TListBox;
    PopupMenu1: TPopupMenu;
    Copy1: TMenuItem;
    PasteReplaceDuplicates1: TMenuItem;
    Paste1: TMenuItem;
    PasteInto1: TMenuItem;
    Cut1: TMenuItem;
    CustomTRadioButton: TRadioButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RenameTButtonClick(Sender: TObject);
    procedure DeleteTButtonClick(Sender: TObject);
    procedure NewTButtonClick(Sender: TObject);
    procedure CelledTRadioButton1Click(Sender: TObject);
    procedure LeadedTRadioButton1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure NoImportTCheckBoxClick(Sender: TObject);
    procedure RadialTRadioButtonClick(Sender: TObject);
    procedure ListBoxClick(Sender: TObject);
    procedure ListBoxKeyPress(Sender: TObject; var Key: Char);
    procedure Copy1Click(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure Paste1Click(Sender: TObject);
    procedure PasteInto1Click(Sender: TObject);
    procedure PasteReplaceDuplicates1Click(Sender: TObject);
    procedure Cut1Click(Sender: TObject);
    procedure CustomTRadioButtonClick(Sender: TObject);
  private
    { Private declarations }
    OutlineDisplayer : TveOutlineDisplayer;
    FProject : TveProject;
    CellOutlineEditor : TCellOutlneEditor;
    LeadOutlineEditor : TveLeadOutlineEditor;
    RadialOutlineEditor : TveRadialOutlineEditor;
    CustomOutlineEditor : TveCustomOutlineBasicEditor;

    LeadedAdjuster : TBoardItemAdjuster;
    TopIndex : integer;

    Paster : TveOutlinesFromClipboard;

    procedure EditorChanged(Sender: TObject);
    function SelectedOutline : TveOutline;
    function SelectedIndex : integer;
    function IndexToOutline( Index : integer ) : TveOutline;
    function IndexOfOutline( Outline : TveOutline ) : integer;
    procedure ReloadList;
    procedure SelectIndex( index : integer );
    procedure SelectOutline( Outline : TveOutline );
    procedure DisplayOutlineSettings( Index : integer );
    procedure StoreTopIndex;
    procedure RecallTopIndex;
    function SelectedOutlinesInUse : boolean;
    procedure Copy;

  public
    { Public declarations }
    property Project : TveProject read FProject write FProject;

  end;

var
  OutlineSettingsForm: TOutlineSettingsForm;

implementation

{$R *.DFM}

uses CelledOutlines, SizeableOutlines, RadialOutlines, CustomOutlines,
  BoardSize, InputBoxFrm, MessageDialogFrm;

// ************************************************
//           INITIALISATION, FINALISATION
// ************************************************

procedure TOutlineSettingsForm.FormCreate(Sender: TObject);
var
    EditorTop : integer;
begin
    Paster := TveOutlinesFromClipboard.Create;
    LeadedAdjuster := TBoardItemAdjuster.Create;

    OutlineDisplayer := TveOutlineDisplayer.Create(self);
    OutlineDisplayer.Parent := ScrollBox1;
    OutlineDisplayer.Left := 0;
    OutlineDisplayer.Top := 0;
    OutlineDisplayer.Width := 50;
    OutlineDisplayer.Height := 50;
    OutlineDisplayer.Prepare;
    OutlineDisplayer.PixelsPerCell := ((ScrollBox1.Height) div 15);

    // CellOutline and LeadOutline editors placed below OutlineClassTLabel
    EditorTop := OutlineClassTLabel.Top + (OutlineClassTLabel.Height * 3) div 2;

    // cell OutlineEditor
    CellOutlineEditor := TCellOutlneEditor.Create(self);
    CellOutlineEditor.Parent := Panel2;

    CellOutlineEditor.Top := EditorTop;
    CellOutlineEditor.Left := ScrollBox1.Left;
    CellOutlineEditor.Height := Panel2.ClientHeight - 3 - CellOutlineEditor.Top;
    CellOutlineEditor.Width := ScrollBox1.Width;


    CellOutlineEditor.ColWidth := CellOutlineEditor.Width  div 10;
    CellOutlineEditor.RowHeight := CellOutlineEditor.Height div 15;
    CellOutlineEditor.Font := Font;
    CellOutlineEditor.Visible := False;

    // Leaded Outline Editor
    LeadOutlineEditor := TveLeadOutlineEditor.Create(self);
    LeadOutlineEditor.Parent := Panel2;

    LeadOutlineEditor.Top := EditorTop;
    LeadOutlineEditor.Left := ScrollBox1.Left;
    LeadOutlineEditor.Height := Panel2.ClientHeight - 3 - CellOutlineEditor.Top;
    LeadOutlineEditor.Width := ScrollBox1.Width;

    LeadOutlineEditor.Visible := False;

    // Radial Outline Editor
    RadialOutlineEditor :=TveRadialOutlineEditor.Create(self);
    RadialOutlineEditor.Parent := Panel2;

    RadialOutlineEditor.Top := EditorTop;
    RadialOutlineEditor.Left := ScrollBox1.Left;
    RadialOutlineEditor.Height := Panel2.ClientHeight - 3 - CellOutlineEditor.Top;
    RadialOutlineEditor.Width := ScrollBox1.Width;

    RadialOutlineEditor.Visible := False;

    // Custom Outline Editor
    CustomOutlineEditor := TveCustomOutlineBasicEditor.Create(self);
    CustomOutlineEditor.Parent := Panel2;

    CustomOutlineEditor.Top := EditorTop;
    CustomOutlineEditor.Left := ScrollBox1.Left;
    CustomOutlineEditor.Height := Panel2.ClientHeight - 3 - CellOutlineEditor.Top;
    CustomOutlineEditor.Width := ScrollBox1.Width;

    CustomOutlineEditor.Visible := False;
end;

procedure TOutlineSettingsForm.FormDestroy(Sender: TObject);
begin
    //.. stop OutlineDisplayer referencing any outline
    LeadedAdjuster.Free;
    Paster.Free;
end;


procedure TOutlineSettingsForm.FormShow(Sender: TObject);
begin
    // Leaded Items Tracking
    LeadedAdjuster.MarkComponents( FProject );

    ReloadList;

    // select top cell and display outline, if any available
    ListBox.SetFocus;
    SelectIndex( 0 );
end;


procedure TOutlineSettingsForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
    // fix up length of components which have newly gained a leaded outline
    LeadedAdjuster.AdjustComponents;
    RescueOffBoardItems( FProject );

    FProject.ClearUndo;
    FProject.Dirty := True;
    FProject.TransferFastNets;
end;


// ************************************************
//             OUTLINE LIST MANAGEMENT
// ************************************************

function TOutlineSettingsForm.SelectedIndex : integer;
begin
    if ListBox.SelCount = 1 then begin
        result := ListBox.ItemIndex;
        if (result < 0) or (result >= FProject.OutlineCount) then begin
            result := -1;
        end;
    end
    else begin
        result := -1;
    end;
end;

function TOutlineSettingsForm.SelectedOutline : TveOutline;
begin
    result := IndexToOutline( SelectedIndex );
end;

function TOutlineSettingsForm.IndexToOutline( Index : integer ) : TveOutline;
begin
    if (Index < 0) or (Index >= FProject.OutlineCount) then begin
        result := nil;
    end
    else begin;
        result := FProject.Outlines[Index];
    end;
end;

function TOutlineSettingsForm.IndexOfOutline( Outline : TveOutline ) : integer;
var
    i: integer;
begin
    for i := 0 to Project.OutlineCount -1 do begin
        if Outline = Project.Outlines[i] then begin
            result := i;
            exit;
        end;
    end;
    // no match found
    result := -1;
end;

procedure TOutlineSettingsForm.ReloadList;
var
    i : integer;
    Outline : TveOutline;
begin
    // load grid with details of all outlines in project
    Project.SortOutlines;

    ListBox.Items.Clear;
    for i := 0 to Project.OutlineCount -1 do begin
        Outline := Project.Outlines[i];
        ListBox.Items.Add( Outline.Name );
    end;
end;


procedure TOutlineSettingsForm.SelectIndex( index : integer );
var
    i : integer;
begin
    // set selections
    for i := 0 to ListBox.Items.Count -1 do begin
        ListBox.Selected[i] := i = Index;
    end;
    ListBox.ItemIndex := Index;

    // display settings for this outline
    DisplayOutlineSettings( Index );
end;

procedure TOutlineSettingsForm.SelectOutline( Outline : TveOutline );
begin
    SelectIndex( IndexOfOutline( Outline ) );
end;

procedure TOutlineSettingsForm.DisplayOutlineSettings( Index : integer );
var
    Outline : TveOutline;
    TempClick : TNotifyEvent;
begin
    Outline := IndexToOutline( Index );
    if Outline <> nil then begin
        OutlineDisplayer.Outline := Outline;
        OutlineClassTLabel.Caption := Outline.ClassName;
        NoImportTCheckBox.Checked := Outline.NoImport;

        if OutlineDisplayer.Outline is TveCellOutline then begin
            LeadOutlineEditor.Outline := nil;
            LeadOutlineEditor.Visible := False;
            LeadOutlineEditor.OnChanged := nil;

            RadialOutlineEditor.Outline := nil;
            RadialOutlineEditor.Visible := False;
            RadialOutlineEditor.OnChanged := nil;

            // editor must be visible before we change visible stuff !
            CellOutlineEditor.Visible := True;
            CellOutlineEditor.Outline := TveCellOutline(Outline);
            CellOutlineEditor.OnChanged := EditorChanged;
            CellOutlineEditor.Refresh;

            TempClick := CelledTRadioButton.OnClick;
            CelledTRadioButton.OnClick := nil;
            CelledTRadioButton.Checked := True;
            CelledTRadioButton.OnClick := TempClick;

            CustomOutlineEditor.Outline := nil;
            CustomOutlineEditor.Visible := False;
            CustomOutlineEditor.OnChanged := nil;
        end

        else if OutlineDisplayer.Outline is TveLeadedOutline then begin
            CellOutlineEditor.Outline := nil;
            CellOutlineEditor.Visible := False;
            CellOutlineEditor.OnChanged := nil;

            RadialOutlineEditor.Outline := nil;
            RadialOutlineEditor.Visible := False;
            RadialOutlineEditor.OnChanged := nil;

            // editor must be visible before we change visible stuff !
            // otherwise stuff in TEdits is lost !
            LeadOutlineEditor.Visible := True;
            LeadOutlineEditor.Outline := TveLeadedOutline(Outline);
            LeadOutlineEditor.OnChanged := EditorChanged;

            TempClick := LeadedTRadioButton.OnClick;
            LeadedTRadioButton.OnClick := nil;
            LeadedTRadioButton.Checked := True;
            LeadedTRadioButton.OnClick := TempClick;

            CustomOutlineEditor.Outline := nil;
            CustomOutlineEditor.Visible := False;
            CustomOutlineEditor.OnChanged := nil;
        end

        else if OutlineDisplayer.Outline is TveRadialOutline then begin

            CellOutlineEditor.Outline := nil;
            CellOutlineEditor.Visible := False;
            CellOutlineEditor.OnChanged := nil;

            LeadOutlineEditor.Outline := nil;
            LeadOutlineEditor.Visible := False;
            LeadOutlineEditor.OnChanged := nil;

            // editor must be visible before we change visible stuff !
            // otherwise stuff in TEdits is lost !
            RadialOutlineEditor.Visible := True;
            RadialOutlineEditor.Outline := TveRadialOutline(Outline);
            RadialOutlineEditor.OnChanged := EditorChanged;

            TempClick := RadialTRadioButton.OnClick;
            RadialTRadioButton.OnClick := nil;
            RadialTRadioButton.Checked := True;
            RadialTRadioButton.OnClick := TempClick;

            CustomOutlineEditor.Outline := nil;
            CustomOutlineEditor.Visible := False;
            CustomOutlineEditor.OnChanged := nil;
        end

        else if OutlineDisplayer.Outline is TveCustomOutline then begin

            LeadOutlineEditor.Outline := nil;
            LeadOutlineEditor.Visible := False;
            LeadOutlineEditor.OnChanged := nil;

            CellOutlineEditor.Outline := nil;
            CellOutlineEditor.Visible := False;
            CellOutlineEditor.OnChanged := nil;

            RadialOutlineEditor.Outline := nil;
            RadialOutlineEditor.Visible := False;
            RadialOutlineEditor.OnChanged := nil;

            CustomOutlineEditor.Visible := True;
            CustomOutlineEditor.Outline := TveCustomOutline(Outline);
            CustomOutlineEditor.OnChanged := EditorChanged;

            TempClick := CustomTRadioButton.OnClick;
            CustomTRadioButton.OnClick := nil;
            CustomTRadioButton.Checked := True;
            CustomTRadioButton.OnClick := TempClick;
        end

        else begin
            LeadOutlineEditor.Outline := nil;
            LeadOutlineEditor.Visible := False;
            LeadOutlineEditor.OnChanged := nil;

            CellOutlineEditor.Outline := nil;
            CellOutlineEditor.Visible := False;
            CellOutlineEditor.OnChanged := nil;

            RadialOutlineEditor.Outline := nil;
            RadialOutlineEditor.Visible := False;
            RadialOutlineEditor.OnChanged := nil;

            CustomOutlineEditor.Outline := nil;
            CustomOutlineEditor.Visible := False;
            CustomOutlineEditor.OnChanged := nil;
        end;

        // permit deletion only if Outline not referenced by a BoardItem
        DeleteTButton.Enabled :=
            not FProject.OutlineInUse( OutlineDisplayer.Outline );
    end
    else begin
        LeadOutlineEditor.Outline := nil;
        LeadOutlineEditor.Visible := False;
        LeadOutlineEditor.OnChanged := nil;

        CellOutlineEditor.Outline := nil;
        CellOutlineEditor.Visible := False;
        CellOutlineEditor.OnChanged := nil;

        RadialOutlineEditor.Outline := nil;
        RadialOutlineEditor.Visible := False;
        RadialOutlineEditor.OnChanged := nil;

        CustomOutlineEditor.Outline := nil;
        CustomOutlineEditor.Visible := False;
        CustomOutlineEditor.OnChanged := nil;

        OutlineDisplayer.Outline := nil;
        OutlineClassTLabel.Caption := 'xx';
    end;

    OutlineDisplayer.Paint;
end;

procedure TOutlineSettingsForm.StoreTopIndex;
begin
    TopIndex := ListBox.TopIndex;
end;

procedure TOutlineSettingsForm.RecallTopIndex;
begin
    ListBox.TopIndex := TopIndex;
end;


function TOutlineSettingsForm.SelectedOutlinesInUse : boolean;
var
    i : integer;
    Outline : TveOutline;
begin
    // return True if any of the selected outlines are in use by board items
    for i := 0 to ListBox.Items.Count -1 do begin
        if ListBox.Selected[i] then begin
            Outline := IndexToOutline( i );
            if FProject.OutlineInUse( Outline ) then begin
                result := True;
                exit;
            end;
        end;
    end;
    // no outlines in use
    result := False;
end;

// ***************************************************
//       EVENT HANDLER WHEN USER SELECTS GRID CELL
// ***************************************************

procedure TOutlineSettingsForm.ListBoxClick(Sender: TObject);
begin
    DisplayOutlineSettings( SelectedIndex );
end;

// ***************************************************
//   EVENT HANDLER UPDATES OUTLINE PICTURE DURING EDITS
// ***************************************************

// ** Repaint Picture of Outline if Cell Editor Has Changed Outline **
procedure TOutlineSettingsForm.EditorChanged(Sender: TObject);
var
    Outline : TveOutline;
begin
    // OutlineDisplayer.Refresh;
    OutlineDisplayer.Paint;

    // outline has been edited : lock out further import of this outline via
    // library - and show this in NoImport checkbox
    Outline := SelectedOutline;
    if Outline <> nil then begin
        Outline.NoImport := True;
        NoImportTCheckBox.Checked := True;
        exit;
    end;
end;

// ****************************************************
//         NEW GRID ITEM & DELETE GRID ITEM
// ****************************************************

// *** USER CLICKS TO CREATE A NEW OUTLINE ***

procedure TOutlineSettingsForm.NewTButtonClick(Sender: TObject);
var
    Outline : TveCellOutline;
begin
    // make a new celled outline - user can change to leaded if desired
    Outline := TveCellOutline.Create;
    Project.AddOutline( Outline );
    Outline.Name := 'NewOutline';
    ReloadList;
    SelectOutline( Outline );
    ListBox.SetFocus;
end;


procedure TOutlineSettingsForm.DeleteTButtonClick(Sender: TObject);
var
    SaveIndex : integer;
    TargetOutline : TveOutline;
begin
    SaveIndex := SelectedIndex;
    TargetOutline := IndexToOutline( SaveIndex );
    if TargetOutline <> nil then begin
        // get user confirmation for delete of outline
{
        if MessageDlgPos(
            Format( 'Delete Outline : %s ?', [TargetOutline.Name] ),
            mtConfirmation, [mbOK, mbCancel], 0,
            Left  + width div 2, top + height div 2,
            mbOK
            ) = mrOK then begin
 }
        if not MessageDialogForm.ExecuteCentered(
            self, 'VeeCAD',
            Format( 'Delete Outline : %s ?', [TargetOutline.Name] )) then begin

            exit;
        end;

       // Delete outline from project
        FProject.DeleteOutline( TargetOutline );

        // leave selected row same, TopIndex
        StoreTopIndex;
        ReloadList;
        RecallTopIndex;
        SelectIndex( SaveIndex );
        ListBox.SetFocus;
    end;
end;

// ***************************************************
//                  EDIT OUTLINE NAME
// ***************************************************

procedure TOutlineSettingsForm.RenameTButtonClick(Sender: TObject);
var
    NewName : string;
    MatchingNameOutline : TveOutline;
    TargetOutline : TveOutline;
begin
    TargetOutline := SelectedOutline;

    if TargetOutline <> nil then begin

        if not InputBoxForm.ExecuteCentered(
            self, 'VeeCAD', 'Rename Outline', TargetOutline.Name, NewName
            ) then begin
            exit;
        end;

        // warn user if name matches existing outline and cancel the edit
        MatchingNameOutline := FProject.OutlineByName( NewName );
        if (MatchingNameOutline <> nil) and (MatchingNameOutline <> TargetOutline)
            then begin
            ShowMessage( Format( 'Name %s already used by an Outline', [NewName] ));
        end

        else begin
            TargetOutline.Name := NewName;
            ReloadList;
            SelectOutline( TargetOutline );
        end;
    end;
end;


// ***************************************************
//                  ALTER OUTLINE TYPE
// ***************************************************

procedure TOutlineSettingsForm.CelledTRadioButton1Click(Sender: TObject);
var
    Index : integer;
    OldOutline : TveOutline;
    NewOutline : TveCellOutline;
begin
    Index := SelectedIndex;
    OldOutline := IndexToOutline( Index );
    if OldOutline = nil then begin
        exit;
    end;

    NewOutline := TveCellOutline.Create;
    NewOutline.Name := OldOutline.Name;
    Project.ReplaceOutline( OldOutline, NewOutline );
    DisplayOutlineSettings( Index );
    ListBox.SetFocus;
end;

// *** CONVERT CURRENT ITEM TO LEADED ITEM **

procedure TOutlineSettingsForm.LeadedTRadioButton1Click(Sender: TObject);
var
    Index : integer;
    OldOutline : TveOutline;
    NewOutline : TveLeadedOutline;
begin
    Index := SelectedIndex;
    OldOutline := IndexToOutline( Index );
    if OldOutline = nil then begin
        exit;
    end;

    NewOutline := TveLeadedOutline.Create;
    NewOutline.Name := OldOutline.Name;
    NewOutline.BodyLength := 3;
    NewOutline.BodyWidth := 1;
    Project.ReplaceOutline( OldOutline, NewOutline );
    DisplayOutlineSettings( Index );
    ListBox.SetFocus;
end;

// *** CONVERT CURRENT ITEM TO RADIAL ITEM **

procedure TOutlineSettingsForm.RadialTRadioButtonClick(Sender: TObject);
var
    Index : integer;
    OldOutline : TveOutline;
    NewOutline : TveRadialOutline;
begin
    Index := SelectedIndex;
    OldOutline := IndexToOutline( Index );
    if OldOutline = nil then begin
        exit;
    end;

    NewOutline := TveRadialOutline.Create;
    NewOutline.Name := OldOutline.Name;
    NewOutline.LeadSpacing := 2;
    NewOutline.Diameter := 3;
    Project.ReplaceOutline( OldOutline, NewOutline );
    DisplayOutlineSettings( Index );
    ListBox.SetFocus;
end;

procedure TOutlineSettingsForm.CustomTRadioButtonClick(Sender: TObject);

var
    Index : integer;
    OldOutline : TveOutline;
    NewOutline : TveCustomOutline;
    Line : TcoLine;

    procedure AddLine( x1, y1, x2, y2 : integer );
    begin
        Line := NewOutline.CreateLine;
        Line.SubX := x1;
        Line.SubY := y1;
        Line.EndDeltaSubX := x2 - x1;
        Line.EndDeltaSubY := y2 - y1;
    end;

begin
    Index := SelectedIndex;
    OldOutline := IndexToOutline( Index );
    if OldOutline = nil then begin
        exit;
    end;

    NewOutline := TveCustomOutline.Create;
    NewOutline.Name := OldOutline.Name;

    // give the new outline a sensible default shape - a rectangle
    AddLine( 0, 0, TcoSubCellsPerCell, 0 );
    AddLine( TcoSubCellsPerCell, 0, TcoSubCellsPerCell, TcoSubCellsPerCell );
    AddLine( TcoSubCellsPerCell, TcoSubCellsPerCell, 0, TcoSubCellsPerCell );
    AddLine( 0, TcoSubCellsPerCell, 0, 0 );

    Project.ReplaceOutline( OldOutline, NewOutline );
    DisplayOutlineSettings( Index );
    ListBox.SetFocus;
end;


// ***************************************************
// *** TOGGLE NO_IMPORT SETTING OF CURRENT OUTLINE **
// ***************************************************

procedure TOutlineSettingsForm.NoImportTCheckBoxClick(Sender: TObject);
var
    Outline : TveOutline;
begin
    Outline := SelectedOutline;
    if Outline = nil then begin
        exit;
    end;

    Outline.NoImport := NoImportTCheckBox.Checked;
end;


// ******************************************************
//            HANDLE LISTBOX KEYBOARD EVENTS
// ******************************************************

procedure TOutlineSettingsForm.ListBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
    // swallow all keys here, disabling TListBox jump to item facility
    Key := #0;
end;


// ******************************************************
//         LISTBOX RIGHT CLICK POPUP MENU EVENTS
// ******************************************************

procedure TOutlineSettingsForm.Copy;
var
    Copier : TveOutlinesToClipboard;
    i : integer;
    Outline : TveOutline;
begin
    Copier := TveOutlinesToClipboard.Create;
    try
        for i := 0 to ListBox.Items.Count -1 do begin
            if ListBox.Selected[i] then begin
                Outline := IndexToOutline( i );
                if Outline <> nil then begin
                    Copier.AddOutline( Outline );
                end;
            end;
        end;
        Copier.SenderHandle := Application.Handle;
        Copier.SendToClipboard;
    finally
        Copier.Free;
    end;
end;



procedure TOutlineSettingsForm.Cut1Click(Sender: TObject);
var
    SavedIndex : integer;
    i : integer;
    Outline : TveOutline;
begin
    // can only delete free outlines
    if SelectedOutlinesInUse then begin
        exit;
    end;

    // put outlines on clipboard
    Copy;

    SavedIndex := ListBox.ItemIndex;

    // delete selected outlines
    //.. must count *down* or list items indexes will get out of step with
    //.. project indexes.  This code relies on Project.DeleteOutline(n) keeping
    //.. unaltered outlines associated with indexes less than n.
    for i := ListBox.Items.Count -1 downto 0 do begin
        if ListBox.Selected[i] then begin
            Outline := IndexToOutline( i );
            if Outline <> nil then begin
                FProject.DeleteOutline( Outline );
            end;
        end;
    end;
    StoreTopIndex;
    ReloadList;
    RecallTopIndex;
    SelectIndex( SavedIndex );
end;


procedure TOutlineSettingsForm.Copy1Click(Sender: TObject);
begin
    Copy;
end;


procedure TOutlineSettingsForm.PopupMenu1Popup(Sender: TObject);
begin
    // Configure the Paste Menu Items
    Paster.ReadClipboard;

    // nothing to paste
    if (not Paster.OutlinesAvailable) or not (Paster.OutlineCount > 0) then begin
        Paste1.Enabled := False;
        PasteReplaceduplicates1.Enabled := False;
        PasteInto1.Enabled := False;
    end
    // paste options depending
    else begin

        // we can always do a simple paste where make a new name if a name already exists
        Paste1.Enabled := True;

        // paste into only if one item on clipboard and valid target item selected
        PasteInto1.Enabled := (Paster.OutlineCount = 1) and (SelectedOutline <> nil);

        // overwrite matching names only if pasting from a different VeeCAD instance
        PasteReplaceduplicates1.Enabled := (Paster.SenderHandle <> Application.Handle);
    end;

    // cut allowed if all selected items are not in use by outlines
    Cut1.Enabled := not SelectedOutlinesInUse;
end;

procedure TOutlineSettingsForm.Paste1Click(Sender: TObject);
begin
    Paster.Paste( FProject );
    StoreTopIndex;
    ReloadList;
    RecallTopIndex;
end;

procedure TOutlineSettingsForm.PasteReplaceDuplicates1Click( Sender: TObject);
begin
    // paste cliboard outlines into project - if name clashes occur, replace
    // the existing outline with the new one
    Paster.PasteOverwrite( FProject );
    StoreTopIndex;
    ReloadList;
    RecallTopIndex;
end;

procedure TOutlineSettingsForm.PasteInto1Click(Sender: TObject);
var
    AlteredOutline : TveOutline;
begin
    // replaced highlighted list outline with outline on the clipboard
    Paster.PasteInto( FProject, SelectedOutline, AlteredOutline );
    Paster.PasteOverwrite( FProject );
    StoreTopIndex;
    ReloadList;
    RecallTopIndex;

    // select item we pasted into
    SelectOutline( AlteredOutline );
end;

end.

    
