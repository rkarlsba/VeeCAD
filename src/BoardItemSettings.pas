unit BoardItemSettings;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Grids,

  Project,  Outlines, OutlineDisplayer, Adjuster;

type
  TBoardItemSettingsForm = class(TForm)
    Grid: TStringGrid;
    Panel1: TPanel;
    ScrollBox1: TScrollBox;
    NewTButton: TButton;
    EditDesignatorTButton: TButton;
    DeleteTButton: TButton;
    OutlineTLabel: TLabel;
    OKTButton: TButton;
    CancelTButton: TButton;
    EditValueTButton: TButton;
    ChangeOutlineTGroupBox: TGroupBox;
    PreviousOutlineTButton: TButton;
    CancelOutlineTButton: TButton;
    NextOutlineTButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GridSelectCell(Sender: TObject; Col, Row: Integer;
      var CanSelect: Boolean);
    procedure NewTButtonClick(Sender: TObject);
    procedure EditDesignatorTButtonClick(Sender: TObject);
    procedure EditValueTButtonClick(Sender: TObject);
    procedure DeleteTButtonClick(Sender: TObject);
    procedure PreviousOutlineTButtonClick(Sender: TObject);
    procedure NextOutlineTButtonClick(Sender: TObject);
    procedure CancelOutlineTButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FProject : TveProject;
    FSelectItem : TveBoardItem;
    OutlineDisplayer : TveOutlineDisplayer;
    RevertTarget : TveBoardItem;
    RevertOutline : TveOutline;
    LeadedAdjuster : TBoardItemAdjuster;

    function GetSelectedBoardItem : TveBoardItem;
    procedure FillGrid;
    procedure ShowGridRowInfo( Row : integer );
    procedure SelectGridItem( Item : TveBoardItem );
    procedure SelectGridRow( Row : integer );

  public
    { Public declarations }
    property Project : TveProject read FProject write FProject;

    // item to select after ShowModal call - can be nil
    property SelectItem: TveBoardItem read FSelectItem write FSelectItem;
  end;

var
  BoardItemSettingsForm: TBoardItemSettingsForm;

implementation

{$R *.DFM}

uses NewItem, CelledOutlines, SizeableOutlines, RadialOutlines, CustomOutlines,
    BoardSize, InputBoxFrm, MessageDialogFrm;


procedure TBoardItemSettingsForm.FormCreate(Sender: TObject);
begin
    LeadedAdjuster := TBoardItemAdjuster.Create;

    OutlineDisplayer := TveOutlineDisplayer.Create(self);
    OutlineDisplayer.Parent := ScrollBox1;
    OutlineDisplayer.Left := 0;
    OutlineDisplayer.Top := 0;
    OutlineDisplayer.Project.Board.Width := 50;
    OutlineDisplayer.Project.Board.Height := 50;
    OutlineDisplayer.Prepare;
    OutlineDisplayer.PixelsPerCell := (ScrollBox1.Height) div 15;
end;

procedure TBoardItemSettingsForm.FormShow(Sender: TObject);
var
    ScrollBoxWidth : integer;
begin
    // Leaded Items Tracking
    LeadedAdjuster.MarkComponents( FProject );

    // setup grid
    Grid.FixedCols := 0;
    Grid.FixedRows := 1;
    Grid.ColCount := 2;
    ScrollBoxWidth := GetSystemMetrics( SM_CXHTHUMB );
    Grid.ColWidths[0] := (Grid.ClientWidth - ScrollBoxWidth -3) div 2;
    Grid.ColWidths[1] := (Grid.ClientWidth - ScrollBoxWidth -3) div 2;
    Grid.Cells[0,0] := 'Designator';
    Grid.Cells[1,0] := 'Value';

    FillGrid;

    if FSelectItem = nil then begin
        // highlight first item
        SelectGridRow( 1 );
    end
    else begin
        SelectGridItem( FSelectItem );
    end;
end;


function TBoardItemSettingsForm.GetSelectedBoardItem : TveBoardItem;
begin
    if (Grid.Row < 1) or (Grid.RowCount < 1) then begin
        result := nil;
    end
    else begin
        result := TveBoardItem( Grid.Rows[Grid.Row].Objects[0] );
    end;
end;

// ************************************************
//              GRID - DISPLAY FUNCTIONS
// ************************************************
(*
Following are Basic Display Functions which are called by other
code when there is a change in info to display.  This form is driven
by the grid - when a grid row is selected by the user (or by code),
the other sections of the form must show info which corresponds to
the selected item.

lower level display functions :
-----------------------------

FillGrid                                - refill grid with all items

ShowGridRowInfo( Row : integer );       - get rest of form to match grid row

higher level display functions :
------------------------------

SelectGridRow( Row : integer );         - move grid selection to this row

SelectGridItem( Item : TveBoardItem );  - move grid selection to this item
                                        - technically, this should not be needed
                                        - at all
*)

// ** REFILL GRID WITH ITEMS TO DISPLAY **

procedure TBoardItemSettingsForm.FillGrid;
var
    i : integer;
    Outline : TveOutline;
    Item : TveBoardItem;
    DisplayableItemCount : integer;
    GridRow : integer;
begin
    // we will show items sorted by Designator
    Project.SortBoardItems;

    // count items of type we want to display
    DisplayableItemCount := 0;
    for i := 0 to Project.BoardItemCount -1 do begin
        Item := Project.BoardItems[i];
        Outline := Item.Outline;
        if Outline.UserDefined then begin
            Inc( DisplayableItemCount );
        end;
    end;

    // load grid with details of all Items in project
    // always the fixed row, plus one extra, VCL source shows that Grid
    // forces this many rows minimum.  Fighting this leads to display
    // anomalies.
    // if no items to display, add an empty dummy item, because VCL source
    // shows that Grid requires FixedRowCount + 1 rows minimum.
    if DisplayableItemCount = 0 then begin
        Grid.RowCount := 2;
        Grid.Cells[0,1] := '';
        Grid.Cells[1,1] := '';
        Grid.Rows[1].Objects[0] := nil;
    end

    else begin
        Grid.RowCount := DisplayableItemCount + 1;
        GridRow := 1;
        for i := 0 to Project.BoardItemCount -1 do begin
            Item := Project.BoardItems[i];
            Outline := Item.Outline;
            if Outline.UserDefined then begin
                Grid.Cells[0,GridRow] := Item.Designator;
                Grid.Cells[1,GridRow] := Item.Value;
                Grid.Rows[GridRow].Objects[0] := Item;
                Inc( GridRow );
            end;
        end;            
    end;
end;


// ** MAKE REST OF SCREEN MATCH A GRID ROW **

procedure TBoardItemSettingsForm.ShowGridRowInfo( Row : integer );
var
    Item : TveBoardItem;
    Outline : TveOutline;
begin
    if (Row > 0) and (Row < Grid.RowCount) then begin
        Item := TveBoardItem( Grid.Rows[Row].Objects[0] );
    end
    else begin
        Item := nil;
    end;

    if Item = nil then begin
        OutlineDisplayer.Outline := nil;
        OutlineTLabel.Caption := '**';
        //OutlineDisplayer.Refresh;
        OutlineDisplayer.Paint;
        RevertTarget := nil;
    end
    else begin
        Outline := Item.Outline;
        OutlineDisplayer.Outline := Outline;
        OutlineTLabel.Caption := Outline.Name;
        //OutlineDisplayer.Refresh;
        OutlineDisplayer.Paint;
        if RevertTarget <> Item then begin
            RevertTarget := Item;
            RevertOutline := Outline;
        end;
    end;
end;


// ** SETUP SELECTED CELL IN GRID  **

procedure TBoardItemSettingsForm.SelectGridRow( Row : integer );
var
    GRect : TGridRect;
begin
     // scroll grid so selected cell is visible
     //... scroll up if cell is above view window
     if Row < Grid.TopRow then begin
         Grid.TopRow := Row;
     end
     // ...scroll down if the cell is below view  window
     else if Row >= (Grid.TopRow + Grid.VisibleRowCount) then begin
         Grid.TopRow := Row + 1 - Grid.VisibleRowCount;
     end;

     // draw selection rectangle
     Grid.SetFocus;
     GRect.Left := 0;
     GRect.Top := Row;
     GRect.Right := 0;
     GRect.Bottom := Row;
     Grid.Selection := GRect;

     // display edits which match this row
     ShowGridRowInfo( Row );
end;


// ** FIND AN ITEM IN GRID AND HIGHLIGHT IT **

procedure TBoardItemSettingsForm.SelectGridItem( Item : TveBoardItem );
var
    Row : integer;
    SearchItem : TveBoardItem;
begin
    // find item in grid and draw it as selected
    for Row := 1 to Grid.RowCount -1 do begin
        SearchItem := TveBoardItem( Grid.Rows[Row].Objects[0] );
        if Item = SearchItem then begin
                SelectGridRow( Row );
            exit;
        end;
    end;
end;


// ***************************************************
//       EVENT HANDLER WHEN USER SELECTS GRID CELL
// ***************************************************

procedure TBoardItemSettingsForm.GridSelectCell(Sender: TObject; Col,
  Row: Integer; var CanSelect: Boolean);
begin
    ShowGridRowInfo( Row );
end;


// ****************************************************
//         NEW GRID ITEM & DELETE GRID ITEM
// ****************************************************

// ** USER CLICKS BUTTON TO CREATE NEW BOARD ITEM **

procedure TBoardItemSettingsForm.NewTButtonClick(Sender: TObject);
var
    UserInput : TNewItemForm;
    NewItem : TveBoardItem;
begin
    UserInput := TNewItemForm.Create(nil);
    try
        if UserInput.ShowModal = mrOK then begin
            NewItem := TveBoardItem.Create;
            NewItem.Designator := UserInput.Designator;
            NewItem.Outline := FProject.DummyOutline;
            NewItem.Value := UserInput.Value;
            FProject.AddBoardItem( NewItem );

            // now select cell with new item
            FillGrid;
            SelectGridItem( NewItem );
        end;
    finally
        UserInput.Free;
    end;
end;


// ** USER CLICKS BUTTON TO DELETE SELECTED BOARD ITEM **

procedure TBoardItemSettingsForm.DeleteTButtonClick(Sender: TObject);
var
    Item : TveBoardItem;
    OldRow : integer;
begin
    Item := GetSelectedBoardItem;
    if Item <> nil then begin

        // get user confirmation for delete of outline
{
        if MessageDlg(
            Format( 'Delete Board Item : %s ?', [Item.Designator] ),
            mtConfirmation, [mbOK, mbCancel], 0
            ) = mrOK then begin
}
        if not MessageDialogForm.ExecuteCentered(
            self, 'VeeCAD',
            Format( 'Delete Board Item : %s ?', [Item.Designator] )) then begin

            exit;
        end;

       // Delete outline from project
        Project.DeleteBoardItem( Item );

        // update grid
        OldRow := Grid.Row;
        FillGrid;

        // select item above the deleted item
        if OldRow > 1 then begin
            SelectGridRow( OldRow -1 );
        end
        else begin
            SelectGridRow( 1 );
        end;
    end;
end;


// ***************************************************
//       EDIT ITEM DESIGNATOR AND VALUE
// ***************************************************


// ** USER CLICKS BUTTON TO EDIT DESIGNATOR OF SELECTED BOARD ITEM **

procedure TBoardItemSettingsForm.EditDesignatorTButtonClick(
  Sender: TObject);

var
    Item : TveBoardItem;
    NewName : string;
    MatchingDesignatorItem : TveBoardItem;
begin
    Item := GetSelectedBoardItem;
    if Item <> nil then begin

        if not InputBoxForm.ExecuteCentered(
            self, 'VeeCAD', 'Edit Designator', Item.Designator, NewName
            ) then begin
            exit;
        end;

        // warn user if name matches existing outline and cancel the edit.
        // If NewName is blank '' then ItemByDesignator will match this blank
        // name with every link, since these all have blank names.  Solution
        // here is to allow blank names.  Better to replace InputBox with
        // a form specifically designed to prompt user for non-blank name AND
        // which detects clashes with existing names.

        // ItemByDesignator is a search function, and stops at first match.
        // If user enters unchanged name and match stops at Item, then the
        // search will not continue to find a later duplicate. The code
        // serves it basic task of preventing duplicate entries gaining access
        // via this form. If a duplicate gains access in some other way,
        // the netlist report will find it.
        MatchingDesignatorItem := FProject.ItemByDesignator( NewName );
        if  (MatchingDesignatorItem <> nil) and
            (MatchingDesignatorItem <> Item) and (NewName <> '')
            then begin
            ShowMessage( Format( 'Designator %s already used by Board Item', [NewName] ));
        end

        else begin
            Item.Designator := NewName;
            FillGrid;
            SelectGridItem( Item );
        end;
    end;
end;


// ** USER CLICKS BUTTON TO EDIT VALUE OF SELECTED BOARD ITEM **

procedure TBoardItemSettingsForm.EditValueTButtonClick(Sender: TObject);
var
    Item : TveBoardItem;
    NewName : string;
begin
    Item := GetSelectedBoardItem;
    if Item <> nil then begin

        if not InputBoxForm.ExecuteCentered(
            self, 'VeeCAD', 'Edit Value', Item.Value, NewName ) then begin
            exit;
        end;

//        NewName := InputBox( 'VeeCAD', 'Edit Value', Item.Value );
        Item.Value := NewName;
        FillGrid;
    end;
end;


// ****************************************************
//              USER CHANGES OUTLINE
// ****************************************************

procedure TBoardItemSettingsForm.PreviousOutlineTButtonClick(
  Sender: TObject);
var
    Index : integer;
    Item : TveBoardItem;
begin
    Item := GetSelectedBoardItem;

    // No outline means grid not selecting an item, so get out.
    // Also must have a valid Grid selected item.
    if (OutlineDisplayer.Outline = nil) or (Item = nil) then begin
        exit;
    end;

    Index := FProject.IndexOfOutline( OutlineDisplayer.Outline ) - 1;
    if (Index < 0) then begin
        OutlineDisplayer.Outline := FProject.DummyOutline;
    end
    else begin
        OutlineDisplayer.Outline := FProject.Outlines[Index];
    end;

    OutlineTLabel.Caption := OutlineDisplayer.Outline.Name;
//    OutlineDisplayer.Refresh;
    OutlineDisplayer.Paint;


    // set change into TProject
    Item.Outline := OutlineDisplayer.Outline;
    ShowGridRowInfo( Grid.Row );

end;

procedure TBoardItemSettingsForm.NextOutlineTButtonClick(Sender: TObject);
var
    Index : integer;
    Item : TveBoardItem;
begin
    Item := GetSelectedBoardItem;

    // No outline means grid not selecting an item, so get out.
    // Also must have a valid Grid selected item.
    if (OutlineDisplayer.Outline = nil) or (Item = nil) then begin
        exit;
    end;

    Index := FProject.IndexOfOutline( OutlineDisplayer.Outline ) + 1;
    if (Index >= FProject.OutlineCount) then begin
        exit;
    end;

    OutlineDisplayer.Outline := FProject.Outlines[Index];
    OutlineTLabel.Caption := OutlineDisplayer.Outline.Name;
    //OutlineDisplayer.Refresh;
    OutlineDisplayer.Paint;


    // set change into TProject
    Item.Outline := OutlineDisplayer.Outline;
    ShowGridRowInfo( Grid.Row );
end;

procedure TBoardItemSettingsForm.CancelOutlineTButtonClick(
  Sender: TObject);
var
    Item : TveBoardItem;
begin
    Item := GetSelectedBoardItem;
    if (Item = nil) or (RevertOutline = nil) then begin
        exit;
    end;

    // show existing outline
    OutlineDisplayer.Outline := RevertOutline;
    OutlineTLabel.Caption := OutlineDisplayer.Outline.Name;
    // OutlineDisplayer.Refresh;
    OutlineDisplayer.Paint;


    // set change into TProject
    Item.Outline := OutlineDisplayer.Outline;
    ShowGridRowInfo( Grid.Row );
end;

procedure TBoardItemSettingsForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
    // fix up length of components which have newly gained a leaded outline
    LeadedAdjuster.AdjustComponents;
    RescueOffBoardItems( FProject );

    FProject.ClearUndo;
    FProject.Dirty := True;
    FProject.TransferFastNets;
end;

procedure TBoardItemSettingsForm.FormDestroy(Sender: TObject);
begin
    LeadedAdjuster.Free;
end;


end.



