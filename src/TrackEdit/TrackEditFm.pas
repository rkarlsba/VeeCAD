unit TrackEditFm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,
  Project, Board, TrackEditor, ComCtrls, ToolWin, StdCtrls, ImgList, ExtCtrls,
  ActnList, Buttons;

type
  TTrackEditForm = class(TForm)
    ImageList1: TImageList;
    Panel1: TPanel;
    SelectTSpeedButton: TSpeedButton;
    StripTSpeedButton: TSpeedButton;
    SegmentTSpeedButton: TSpeedButton;
    Shape1: TShape;
    ZoomInTSpeedButton: TSpeedButton;
    ZoomOutTSpeedButton: TSpeedButton;
    Shape2: TShape;
    Image1: TImage;
    Shape3: TShape;
    Image2: TImage;
    Shape4: TShape;
    SnapTComboBox: TComboBox;
    SegmentWidthTComboBox: TComboBox;
    TrackAngleTSpeedButton: TSpeedButton;
    StatusBar1: TStatusBar;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ZoomInTSpeedButtonClick(Sender: TObject);
    procedure ZoomOutTSpeedButtonClick(Sender: TObject);
    procedure SnapTComboBoxChange(Sender: TObject);
    procedure SegmentWidthTComboBoxChange(Sender: TObject);
    procedure StripTSpeedButtonClick(Sender: TObject);
    procedure SegmentTSpeedButtonClick(Sender: TObject);
    procedure DonutTSpeedButtonClick(Sender: TObject);
    procedure SelectTSpeedButtonClick(Sender: TObject);
    procedure TrackAngleTSpeedButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    TrackEditor : TteTrackEditor;
//    procedure OnMouseSubCellMove( SubCellX, SubCellY, CellX, CellY : integer );
//    procedure OnMouseClickShape( Sender : TObject; Item : TcoShape );
    procedure OnChangeMode( Sender : TObject; Mode : TteEditMode );
    procedure OnEditorMouseMove ( X_DIV, Y_DIV : integer );
    procedure ReadSegmentWidth;
    procedure ReadSnapGrid;
    procedure ReadTrackAngle;

    procedure LoadSettings;
    procedure SaveSettings;
    procedure EditorToControls;

  public
    { Public declarations }
      Board : TbrBoard;
      Dirty : boolean;
  end;

var
  TrackEditForm: TTrackEditForm;

implementation

{$R *.dfm}

uses globals, Registry
{$IFNDEF VER200}, System.UITypes, System.ImageList {$ENDIF} ;

// ************************************************
//           MANAGE COMBOBOX VALUES
// ************************************************

const
    IndexToSegmentWidth : array[0..3] of integer = (1000, 500, 250, 125 );
    IndexToSnapGrid : array[0..4] of integer = (1000, 500, 250, 125, 1);

function SegmentWidthToIndex( SegWidth_D : integer ) : integer;
var
    i : integer;
begin
    for i := 0 to High(IndexToSegmentWidth) do begin
        if SegWidth_D = IndexToSegmentWidth[i] then begin
            result := i;
            exit;
        end;
    end;
    // no match
    result := -1;
end;

function SnapGridToIndex( SnapGrid_D : integer ) : integer;
var
    i : integer;
begin
    for i := 0 to High(IndexToSnapGrid) do begin
        if SnapGrid_D = IndexToSnapGrid[i] then begin
            result := i;
            exit;
        end;
    end;
    // no match
    result := -1;
end;


// ************************************************
//           LOAD & SAVE SETTINGS
// ************************************************

procedure TTrackEditForm.LoadSettings;
var
    RegIniFile : TRegIniFile;
begin
    RegIniFile := GetRegIniFile;
    try
        TrackEditor.SnapGrid_D :=
            RegIniFile.ReadInteger( 'TrackEditor', 'SnapGrid', 500 );
        TrackEditor.SegmentWidth_D :=
            RegIniFile.ReadInteger( 'TrackEditor', 'SegmentWidth', 250 );
        TrackEditor.ConstrainedSegments :=
            RegIniFile.ReadBool( 'TrackEditor', 'Polar', True );
        TrackEditor.PixelsPerCell :=
            RegIniFile.ReadInteger( 'TrackEditor', 'PixelsPerCell', 20 )
    finally
        RegIniFile.Free;
    end;
end;


procedure TTrackEditForm.SaveSettings;
var
    RegIniFile : TRegIniFile;
begin
    RegIniFile := GetRegIniFile;
    try
        RegIniFile.WriteInteger(
            'TrackEditor', 'SnapGrid', TrackEditor.SnapGrid_D );
        RegIniFile.WriteInteger(
            'TrackEditor', 'SegmentWidth', TrackEditor.SegmentWidth_D );
        RegIniFile.WriteBool(
            'TrackEditor', 'Polar', TrackEditor.ConstrainedSegments );
        RegIniFile.WriteInteger(
            'TrackEditor', 'PixelsPerCell', TrackEditor.PixelsPerCell );
    finally
        RegIniFile.Free;
    end;
end;

// ************************************************
//           INITIALISATION & FINALISATION
// ************************************************

procedure TTrackEditForm.FormCreate(Sender: TObject);
begin
    TrackEditor := TteTrackEditor.Create( self );
    TrackEditor.Parent := Self;
    TrackEditor.Align := alClient;
    TrackEditor.OnChangeMode := OnChangeMode;
    TrackEditor.OnMouseMove := OnEditorMouseMove;
    TrackEditor.DrawLineWidth := (PixelsPerInch * 2) div 96;
end;

procedure TTrackEditForm.FormShow(Sender: TObject);
begin
    // further adjust form position and size, including registry saved data
    GetFormMinder.AdjustForm( self );

    // read saved settings to Editor
    LoadSettings;

    // sync toolbar controls with editor properties
    EditorToControls;

    TrackEditor.SetFocus;
    TrackEditor.LoadFromBoard( Board );
end;

procedure TTrackEditForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    SaveSettings;
    GetFormMinder.RecordForm( self );
end;

procedure TTrackEditForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    // if nothing changed, just close the form
    if not TrackEditor.Dirty then begin
        CanClose := True;
        exit;
    end;

    // see if user wants to save?
    case MessageDlg('Keep altered tracks ?', mtCustom,
        [mbYes,mbNo,mbCancel], 0 ) of

        // Close Track editor and don't save work
        mrNo : begin
            Dirty := False;
            CanClose := True;
        end;
        // Close Track editor and don't save work
        mrYes : begin
            Screen.Cursor := crHourGlass;
            try
                TrackEditor.SaveToBoard( Board );
            finally
                Screen.Cursor := crDefault;
            end;
            Dirty := True;
            CanClose := True;
        end;
        // cancel and return to Track Editor
        mrCancel : begin
            CanClose := False;
        end;
    end;
end;

procedure TTrackEditForm.FormDestroy(Sender: TObject);
begin
    TrackEditor.Free;
end;


// ************************************************
//              CONTROLS TO EDITOR
// ************************************************

procedure TTrackEditForm.ReadSegmentWidth;
begin
    TrackEditor.SegmentWidth_D := IndexToSegmentWidth[ SegmentWidthTComboBox.ItemIndex ];
end;

procedure TTrackEditForm.ReadSnapGrid;
begin
    TrackEditor.SnapGrid_D := IndexToSnapGrid[ SnapTComboBox.ItemIndex ];
end;

procedure TTrackEditForm.ReadTrackAngle;
begin
    TrackEditor.ConstrainedSegments := TrackAngleTSpeedButton.Down;
end;

// ************************************************
//              EDITOR TO CONTROLS
// ************************************************

// Copy editor settings to controls

procedure TTrackEditForm.EditorToControls;
var
    StoreChange : TNotifyEvent;
begin
    // Polar drawing
    StoreChange := TrackAngleTSpeedbutton.OnClick;
    TrackAngleTSpeedbutton.OnClick := nil;
    TrackAngleTSpeedbutton.Down := TrackEditor.ConstrainedSegments;
    TrackAngleTSpeedbutton.OnClick := StoreChange;

    // snap grid
    StoreChange := SnapTComboBox.OnChange;
    SnapTComboBox.OnChange := nil;
    SnapTComboBox.ItemIndex := SnapGridToIndex( TrackEditor.SnapGrid_D );
    SnapTComboBox.OnChange := StoreChange;

    // segment width
    StoreChange := SegmentWidthTComboBox.OnChange;
    SegmentWidthTComboBox.OnChange := nil;
    SegmentWidthTComboBox.ItemIndex := SegmentWidthToIndex( TrackEditor.SegmentWidth_D );
    SegmentWidthTComboBox.OnChange := StoreChange;
end;


// ************************************************
//            EDITOR EVENT HANDLERS
// ************************************************

procedure TTrackEditForm.OnChangeMode( Sender : TObject; Mode : TteEditMode );
begin
    case Mode of
      bmSelect : SelectTSpeedButton.Down := True;
      bmStrip : StripTSpeedButton.Down := True;
      bmSegment : SegmentTSpeedButton.Down := True;
    end;
end;

procedure TTrackEditForm.OnEditorMouseMove ( X_DIV, Y_DIV : integer );
begin
    StatusBar1.Panels[0].Text := Format( '%d.%d,%d.%d',
        [X_DIV div 1000, X_DIV mod 1000, Y_DIV div 1000, Y_DIV mod 1000] );


    // show mouse coords in status bar
//    StatusBar1.Panels[0].Text := Format( '%d,%d', [X_DIV, Y_DIV] );
end;


// ************************************************
//          TOOLBAR COMBOBOX HANDLERS
// ************************************************

procedure TTrackEditForm.SegmentWidthTComboBoxChange(Sender: TObject);
begin
    ReadSegmentWidth;
    TrackEditor.SetFocus;
end;

procedure TTrackEditForm.SnapTComboBoxChange(Sender: TObject);
begin
    ReadSnapGrid;
    TrackEditor.SetFocus;
end;

procedure TTrackEditForm.TrackAngleTSpeedButtonClick(Sender: TObject);
begin
    ReadTrackAngle;
    TrackEditor.SetFocus;
end;

// ************************************************
//          TOOLBAR MODE BUTTON HANDLERS
// ************************************************

procedure TTrackEditForm.SelectTSpeedButtonClick(Sender: TObject);
begin
    TrackEditor.EditMode := bmSelect;
    TrackEditor.SetFocus;
end;

procedure TTrackEditForm.StripTSpeedButtonClick(Sender: TObject);
begin
    TrackEditor.EditMode := bmStrip;
    TrackEditor.SetFocus;
end;

procedure TTrackEditForm.SegmentTSpeedButtonClick(Sender: TObject);
begin
    TrackEditor.EditMode := bmSegment;
    TrackEditor.SetFocus;
end;

procedure TTrackEditForm.DonutTSpeedButtonClick(Sender: TObject);
begin
    TrackEditor.EditMode := bmDonut;
    TrackEditor.SetFocus;
end;

// ************************************************
//          TOOLBAR ZOOM BUTTON HANDLERS
// ************************************************

procedure TTrackEditForm.ZoomInTSpeedButtonClick(Sender: TObject);
begin
    TrackEditor.PixelsPerCell := TrackEditor.PixelsPerCell + 1;
    TrackEditor.Paint;
    TrackEditor.SetFocus;
end;

procedure TTrackEditForm.ZoomOutTSpeedButtonClick(Sender: TObject);
begin
    TrackEditor.PixelsPerCell := TrackEditor.PixelsPerCell - 1;
    TrackEditor.Paint;
    TrackEditor.SetFocus;
end;


end.




