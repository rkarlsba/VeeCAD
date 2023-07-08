unit PrintSetup;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, ComCtrls,

  PrintPainter, Painter, Printers, Project, PrintPreviewBoard, ColorScheme,
  Winspool;

type TveAppearance = record

    LeadStyle : TLeadStyle;

    HoleDiameterCellThousandths : integer;
    ShowHoles : boolean;

    StripLineWidthCellThousandths : integer;
    ShowStripLines : boolean;

    ComponentLineWidthCellThousandths : integer;
    ShowComponents : boolean;

    ShowBreaks : boolean;
    ShowLinks : boolean;
    ShowWires : boolean;

    ScalePercent : integer;
    Orientation : TPrinterOrientation;
    MarginLeftMM : integer;
    MarginRightMM : integer;
    MarginTopMM : integer;

    ShowColor : boolean;
end;

type PveAppearance = ^TveAppearance;


type
  TPrintSetupForm = class(TForm)
    PageControl1: TPageControl;
    PagesTTabSheet: TTabSheet;
    AppearanceTTabSheet: TTabSheet;
    Panel2: TPanel;
    GroupBox8: TGroupBox;
    AppearanceHolesTCheckBox: TCheckBox;
    AppearanceStripsTCheckBox: TCheckBox;
    TextTGroupBox: TGroupBox;
    AppearanceNoTextTRadioButton: TRadioButton;
    AppearanceValuesTRadioButton: TRadioButton;
    AppearanceDesignatorsTRadioButton: TRadioButton;
    GroupBox10: TGroupBox;
    AppearanceWideLeadTRadioButton: TRadioButton;
    AppearanceNarrowLeadTRadioButton: TRadioButton;
    GroupBox11: TGroupBox;
    Label2: TLabel;
    AppearanceHoleDiameterTEdit: TEdit;
    GroupBox12: TGroupBox;
    Label8: TLabel;
    AppearanceComponentLineWidthTEdit: TEdit;
    GroupBox13: TGroupBox;
    Label12: TLabel;
    Label13: TLabel;
    AppearanceStripLineWidthTEdit: TEdit;
    Panel1: TPanel;
    CloseTButton: TButton;
    PrintTButton: TButton;
    PrinterSetupDialog1: TPrinterSetupDialog;
    Panel3: TPanel;
    GroupBox7: TGroupBox;
    Label10: TLabel;
    PagesScaleTEdit: TEdit;
    GroupBox16: TGroupBox;
    PagesPortraitTRadioButton: TRadioButton;
    PagesLandscapeTRadioButton: TRadioButton;
    AppearanceComponentLineWidthTButton: TButton;
    AppearanceHoleDiameterTButton: TButton;
    AppearanceStripLineWidthTButton: TButton;
    PagesScaleTButton: TButton;
    GroupBox1: TGroupBox;
    PagesFrontTRadioButton: TRadioButton;
    PagesRearTRadioButton: TRadioButton;
    Label1: TLabel;
    GroupBox2: TGroupBox;
    PagesPrinterNameTLabel: TLabel;
    PagesPrinterSetupTButton: TButton;
    Label4: TLabel;
    PaperSizeTLabel: TLabel;
    AppearanceBreaksTCheckBox: TCheckBox;
    AppearanceComponentsTCheckBox: TCheckBox;
    AppearanceLinksTCheckBox: TCheckBox;
    AppearanceWiresTCheckBox: TCheckBox;
    GroupBox3: TGroupBox;
    PagesCopiesTEdit: TEdit;
    PagesCopiesTUpDown: TUpDown;
    Label3: TLabel;
    Margins: TGroupBox;
    PagesMarginLeftTEdit: TEdit;
    PagesMarginRightTEdit: TEdit;
    PagesMarginTopTEdit: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    PagesMarginsTButton: TButton;
    PagesColorTGroupBox: TGroupBox;
    PagesColorTRadioButton: TRadioButton;
    PagesBlackWhiteTRadioButton: TRadioButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure PagesPrinterSetupTButton1Click(Sender: TObject);
    procedure PagesScaleTButtonClick(Sender: TObject);
    procedure PagesScaleTEditKeyPress(Sender: TObject; var Key: Char);
    procedure PagesPortraitTRadioButtonClick(Sender: TObject);
    procedure PagesLandscapeTRadioButtonClick(Sender: TObject);
    procedure PagesFrontTRadioButtonClick(Sender: TObject);
    procedure PagesRearTRadioButtonClick(Sender: TObject);
    procedure AppearanceHolesTCheckBoxClick(Sender: TObject);
    procedure AppearanceStripsTCheckBoxClick(Sender: TObject);
    procedure AppearanceNoTextTRadioButtonClick(Sender: TObject);
    procedure AppearanceDesignatorsTRadioButtonClick(Sender: TObject);
    procedure AppearanceValuesTRadioButtonClick(Sender: TObject);
    procedure AppearanceWideLeadTRadioButtonClick(Sender: TObject);
    procedure AppearanceNarrowLeadTRadioButtonClick(Sender: TObject);
    procedure AppearanceHoleDiameterTButtonClick(Sender: TObject);
    procedure AppearanceHoleDiameterTEditKeyPress(Sender: TObject;
      var Key: Char);
    procedure AppearanceComponentLineWidthTEditKeyPress(Sender: TObject;
      var Key: Char);
    procedure AppearanceComponentLineWidthTButtonClick(Sender: TObject);
    procedure AppearanceStripLineWidthTButtonClick(Sender: TObject);
    procedure AppearanceStripLineWidthTEditKeyPress(Sender: TObject;
      var Key: Char);
    procedure PrintTButtonClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure PagesTTabSheetShow(Sender: TObject);
    procedure AppearanceTTabSheetShow(Sender: TObject);
    procedure AppearanceBreaksTCheckBoxClick(Sender: TObject);
    procedure AppearanceComponentsTCheckBoxClick(Sender: TObject);
    procedure AppearanceLinksTCheckBoxClick(Sender: TObject);
    procedure AppearanceWiresTCheckBoxClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PagesMarginsTButtonClick(Sender: TObject);
    procedure PagesMarginLeftTEditKeyPress(Sender: TObject; var Key: Char);
    procedure PagesBlackWhiteTRadioButtonClick(Sender: TObject);
    procedure PagesColorTRadioButtonClick(Sender: TObject);
  private
    { Private declarations }

    // internal data
    PagesTPreview : TvePrintPreview;
    AppearanceTPreview : TvePrintPreview;

    // system properties
    FProject : TveProject;
    FPrinterTitle : string;

    Front : TveAppearance;
    Rear : TveAppearance;
    View : PveAppearance;

    FMirrored : boolean;
    FComponentTextDisplay : TPrinterComponentText;

    // internal functions
    procedure DrawPrinterDisplay;

    procedure SetupPagesDisplay;
    procedure DrawPagesDisplay;
    procedure CreatePagesDisplay;
    procedure FreePagesDisplay;

    procedure SetupAppearanceDisplay;
    procedure DrawAppearanceDisplay;
    procedure CreateAppearanceDisplay;
    procedure FreeAppearanceDisplay;

    procedure LoadSettings;
    procedure ValidateSettings;
    procedure SaveSettings;

    procedure LoadPagesControls;
    procedure LoadAppearanceControls;

    // internal validation Pages tab
    procedure ReadScale;
    procedure ReadMargins;

    // internal validation Appearance tab
    procedure ReadComponentLineWidth;
    procedure ReadHoleDiameter;
    procedure ReadStripLineWidth;

public
    // user settings
    Colors : TveColorScheme;

    property PrinterTitle : string read FPrinterTitle write FPrinterTitle;
    property Project : TveProject read FProject write FProject;
    procedure Execute;
end;


var
  PrintSetupForm: TPrintSetupForm;

implementation

{$R *.DFM}

uses Globals, Registry, PaperSize, PrintBoard
{$IFNDEF VER200}, System.UITypes {$ENDIF};


// ***********************************************************
//          MAX, MIN & DEFAULT SETTINGS
// ***********************************************************

const

// user properties
DEFAULT_HOLE_DIAM = 200;
MAX_HOLE_DIAM = 300;
MIN_HOLE_DIAM = 10;

DEFAULT_STRIP_WIDTH = 200;
MAX_STRIP_WIDTH = 500;
MIN_STRIP_WIDTH = 20;

DEFAULT_COMPONENT_LINE_WIDTH = 160;
MAX_COMPONENT_LINE_WIDTH = 250;
MIN_COMPONENT_LINE_WIDTH = 10;

DEFAULT_COMPONENT_TEXT = ctDesignators;
DEFAULT_MIRRORED = False;
DEFAULT_ORIENTATION = poLandscape;
DEFAULT_SHOW_COLOR = False;

DEFAULT_MARGIN_LEFT_MM = 8;
DEFAULT_MARGIN_RIGHT_MM = 8;
DEFAULT_MARGIN_TOP_MM = 10;
DEFAULT_MARGIN_BOTTOM_MM = 10;

DEFAULT_LEAD_STYLE = lsLine;

DEFAULT_SCALE_PERCENT = 100;
MAX_SCALE_PERCENT = 250;
MIN_SCALE_PERCENT = 10;

DEFAULT_SHOW_HOLES = True;
DEFAULT_SHOW_STRIPS = True;

DEFAULT_SHOW_BREAKS = True;
DEFAULT_SHOW_COMPONENTS = True;
DEFAULT_SHOW_LINKS = True;
DEFAULT_SHOW_WIRES = True;

// *************************************************
//         EXECUTE FUNCTION RUNS THE DIALOG
// *************************************************
procedure TPrintSetupForm.Execute;
begin
    // abort if no printer available - avoid code problems
    if Printer.Printers.Count <= 0 then begin
        MessageDlg( 'No Printers installed in Windows!', mtError, [mbOK], 0 );
        exit;
    end;

    // show this form
    ShowModal;
end;

// ***********************************************************
//          PRINTER SECTION OF PAGES TAB
// ***********************************************************

procedure TPrintSetupForm.DrawPrinterDisplay;
begin
    PagesPrinterNameTLabel.Caption := Printer.Printers[Printer.PrinterIndex];
    PaperSizeTLabel.Caption := GetPaperSize;
end;


// ***********************************************************
//                     PAGES TAB
// ***********************************************************

// This tab handles landscape/portrait and scale settings, and shows a graphic of
// the layout, with page boundaries drawn as an overlay.

procedure TPrintSetupForm.CreatePagesDisplay;
begin
    PagesTPreview := TvePrintPreview.Create(self);
    PagesTPreview.Parent := PagesTTabsheet;
    PagesTPreview.Left := 0;
    PagesTPreview.Top := 0;
    PagesTPreview.Align := alClient;
end;

procedure TPrintSetupForm.FreePagesDisplay;
begin
    PagesTPreview.Free;
end;


procedure TPrintSetupForm.SetupPagesDisplay;
begin
    // transfer properties to Appearance Preview
    PagesTPreview.HoleDiameterCellThousandths := View^.HoleDiameterCellThousandths;
    PagesTPreview.ShowHoles := View^.ShowHoles;

    PagesTPreview.StripLineWidthCellThousandths := View^.StripLineWidthCellThousandths;
    PagesTPreview.ShowStripLines := View^.ShowStripLines;

    PagesTPreview.ComponentLineWidthCellThousandths := View^.ComponentLineWidthCellThousandths;

    PagesTPreview.ShowBreaks := View^.ShowBreaks;
    PagesTPreview.ShowComponents := View^.ShowComponents;
    PagesTPreview.ShowLinks := View^.ShowLinks;
    PagesTPreview.ShowWires := View^.ShowWires;

    PagesTPreview.LeadStyle := View^.LeadStyle;

    PagesTPreview.Mirrored := FMirrored;
    PagesTPreview.ScalePercent := View^.ScalePercent;
    PagesTPreview.Orientation := View^.Orientation;
    PagesTPreview.Colors.ShowColor := View^.ShowColor;

    PagesTPreview.MarginLeftMM := View^.MarginLeftMM;
    PagesTPreview.MarginTopMM := View^.MarginTopMM;
    PagesTPreview.MarginRightMM := View^.MarginRightMM;

    PagesTPreview.Colors := Colors;
    PagesTPreview.Colors.ShowColor := View^.ShowColor;

    PagesTPreview.ComponentTextDisplay := FComponentTextDisplay;

    PagesTPreview.Project := FProject;
    PagesTPreview.DisplayPixelsPerInch := Screen.PixelsPerInch div 4;

    PagesTPreview.ScrollToOrigin;
    PagesTPreview.Recalculate;
end;

procedure TPrintSetupForm.DrawPagesDisplay;
begin
    SetupPagesDisplay;
    PagesTPreview.Repaint;
end;


procedure TPrintSetupForm.PagesPrinterSetupTButton1Click(Sender: TObject);
begin
    Printer.Orientation := View^.Orientation;
    if PrinterSetupDialog1.Execute then begin
        View^.Orientation := Printer.Orientation;
        LoadPagesControls;
        DrawPrinterDisplay;
        DrawPagesDisplay;
    end;
end;


// *** PAGES SCALE EDIT & BUTTON ***
procedure TPrintSetupForm.PagesScaleTEditKeyPress(Sender: TObject;
  var Key: Char);
begin
    if Key = #13 then begin
        ReadScale;
        Key := #0;
    end;
end;
procedure TPrintSetupForm.PagesScaleTButtonClick(Sender: TObject);
begin
    ReadScale;
end;
procedure TPrintSetupForm.ReadScale;
var
    Scale : integer;
begin
    Scale := StrToIntDef( PagesScaleTEdit.Text, DEFAULT_SCALE_PERCENT );
    if Scale < MIN_SCALE_PERCENT then begin
        Scale := MIN_SCALE_PERCENT;
    end
    else if Scale > MAX_SCALE_PERCENT then begin
        Scale := MAX_SCALE_PERCENT;
    end;
    PagesScaleTEdit.Text := IntToStr( Scale );
    View^.ScalePercent := Scale;
    DrawPagesDisplay;
end;


// *** ORIENTATION RADIO BUTTONS ***
procedure TPrintSetupForm.PagesPortraitTRadioButtonClick(Sender: TObject);
begin
    View^.Orientation := poPortrait;
    DrawPagesDisplay;
end;

procedure TPrintSetupForm.PagesLandscapeTRadioButtonClick(Sender: TObject);
begin
    View^.Orientation := poLandscape;
    DrawPagesDisplay;
end;

// *** FRONT / REAR RADIO BUTTONS ***

procedure TPrintSetupForm.PagesFrontTRadioButtonClick(Sender: TObject);
begin
    FMirrored := False;
    View := @Front;
    DrawPagesDisplay;
    LoadPagesControls;
    LoadAppearanceControls;
end;

procedure TPrintSetupForm.PagesRearTRadioButtonClick(Sender: TObject);
begin
    FMirrored := True;
    View := @Rear;
    DrawPagesDisplay;
    LoadPagesControls;
    LoadAppearanceControls;
end;

// *** BLACK & WHITE - COLOR/GRAYSCALE RADIO BUTTONS ***

procedure TPrintSetupForm.PagesBlackWhiteTRadioButtonClick(Sender: TObject);
begin
    View^.ShowColor := False;
    DrawPagesDisplay;
end;

procedure TPrintSetupForm.PagesColorTRadioButtonClick(Sender: TObject);
begin
    View^.ShowColor := True;
    DrawPagesDisplay;
end;


// *** MARGINS EDITS AND BUTTON ***

procedure TPrintSetupForm.ReadMargins;
    // helper function forces margin to be a number between 0 and 100 mm
    function Adjust( Edit : TEdit ) : integer;
    begin
        result := StrToIntDef( Edit.Text, 0 );
        if result < 0 then begin
            result := 0;
        end;
        if result > 100 then begin
            result := 100;
        end;
        Edit.Text := IntToStr( result );
    end;
begin
    View^.MarginLeftMM := Adjust( PagesMarginLeftTEdit );
    View^.MarginRightMM := Adjust( PagesMarginRightTEdit );
    View^.MarginTopMM := Adjust( PagesMarginTopTEdit );
end;

procedure TPrintSetupForm.PagesMarginsTButtonClick(Sender: TObject);
begin
    ReadMargins;
    DrawPagesDisplay;
end;

procedure TPrintSetupForm.PagesMarginLeftTEditKeyPress(Sender: TObject;
  var Key: Char);
begin
    if Key = #13 then begin
        Key := #0;
        ReadMargins;
        DrawPagesDisplay;
    end;
end;


// *** SETTINGS TO CONTROLS ***
procedure TPrintSetupForm.LoadPagesControls;
var
    SaveOnClick1 : TNotifyEvent;
    SaveOnClick2 : TNotifyEvent;
begin
    // scale
    PagesScaleTEdit.Text := IntToStr( View^.ScalePercent );

    // Orientation
    SaveOnClick1 := PagesPortraitTRadioButton.OnClick;
    SaveOnClick2 := PagesLandscapeTRadioButton.OnClick;
    try
        PagesPortraitTRadioButton.OnClick := nil;
        PagesLandscapeTRadioButton.OnClick := nil;

        if View^.Orientation = poPortrait then begin
            PagesPortraitTRadioButton.Checked := True;
        end
        else begin
            PagesLandscapeTRadioButton.Checked := True;
        end;
    finally
        PagesPortraitTRadioButton.OnClick := SaveOnClick1;
        PagesLandscapeTRadioButton.OnClick := SaveOnClick2;
    end;

    // Mirrored
    SaveOnClick1 := PagesRearTRadioButton.OnClick;
    SaveOnClick2 := PagesFrontTRadioButton.OnClick;
    try
        PagesRearTRadioButton.OnClick := nil;
        PagesFrontTRadioButton.OnClick := nil;

        if FMirrored then begin
            PagesRearTRadioButton.Checked := True;
        end
        else begin
            PagesFrontTRadioButton.Checked := True;
        end;
    finally
        PagesRearTRadioButton.OnClick := SaveOnClick1;
        PagesFrontTRadioButton.OnClick := SaveOnClick2;
    end;

    // Margins
    PagesMarginLeftTEdit.Text := IntToStr( View^.MarginLeftMM );
    PagesMarginRightTEdit.Text := IntToStr( View^.MarginRightMM );
    PagesMarginTopTEdit.Text := IntToStr( View^.MarginTopMM );

    // color or black and white
    SaveOnClick1 := PagesBlackWhiteTRadioButton.OnClick;
    SaveOnClick2 := PagesColorTRadioButton.OnClick;
    try
        PagesBlackWhiteTRadioButton.OnClick := nil;
        PagesColorTRadioButton.OnClick := nil;

        if View^.ShowColor then begin
            PagesColorTRadioButton.Checked := True;
        end
        else begin
            PagesBlackWhiteTRadioButton.Checked := True;
        end;
    finally
        PagesBlackWhiteTRadioButton.OnClick := SaveOnClick1;
        PagesColorTRadioButton.OnClick := SaveOnClick2;
    end;
end;


// ***********************************************************
//                     APPEARANCE TAB
// ***********************************************************

// This tab handles detail appearance of page drawing

procedure TPrintSetupForm.CreateAppearanceDisplay;
begin
    AppearanceTPreview := TvePrintPreview.Create(self);
    AppearanceTPreview.Parent := AppearanceTTabsheet;
    AppearanceTPreview.Left := 0;
    AppearanceTPreview.Top := 0;
    AppearanceTPreview.Align := alClient;
end;

procedure TPrintSetupForm.FreeAppearanceDisplay;
begin
end;

procedure TPrintSetupForm.SetupAppearanceDisplay;
begin
    // transfer properties to Appearance Preview
    AppearanceTPreview.HoleDiameterCellThousandths := View^.HoleDiameterCellThousandths;
    AppearanceTPreview.ShowHoles := View^.ShowHoles;

    AppearanceTPreview.StripLineWidthCellThousandths := View^.StripLineWidthCellThousandths;
    AppearanceTPreview.ShowStripLines := View^.ShowStripLines;

    AppearanceTPreview.ComponentLineWidthCellThousandths := View^.ComponentLineWidthCellThousandths;

    AppearanceTPreview.ShowBreaks := View^.ShowBreaks;
    AppearanceTPreview.ShowComponents := View^.ShowComponents;
    AppearanceTPreview.ShowLinks := View^.ShowLinks;
    AppearanceTPreview.ShowWires := View^.ShowWires;

    AppearanceTPreview.LeadStyle := View^.LeadStyle;
    AppearanceTPreview.ComponentTextDisplay := FComponentTextDisplay;

    AppearanceTPreview.Mirrored := FMirrored;
    AppearanceTPreview.ScalePercent := View^.ScalePercent;
    AppearanceTPreview.Orientation := View^.Orientation;

    AppearanceTPreview.MarginLeftMM := View^.MarginLeftMM;
    AppearanceTPreview.MarginTopMM := View^.MarginTopMM;
    AppearanceTPreview.MarginRightMM := View^.MarginRightMM;

    AppearanceTPreview.Project := FProject;

    AppearanceTPreview.Colors := Colors;
    AppearanceTPreview.Colors.ShowColor := View^.ShowColor;

    // we want to keep display detail at constant size so user can inspect same
    // level of detail at all scales.  TvePrintPreview does not do this
    // automatically - instead it keeps paper size at constant scale and changes
    // size of displayed image.  We get constant feature size by adjusting
    // DisplayPixelsPerInch property, thus changing paper size.
    // DisplayPixelsPerInch looks good at Screen.PixelsPerInch * 2 at 120 percent.
    // ie DisplayPixelsPerInch = Screen.PixelsPerInch * 2 / (  FScalePercent / 120 )
    //  = ( Screen.PixelsPerInch * 2 * 120 ) div FScalePercent
    AppearanceTPreview.DisplayPixelsPerInch :=
        ( Screen.PixelsPerInch * 2 * 120 ) div View^.ScalePercent;

    AppearanceTPreview.Recalculate;
end;


procedure TPrintSetupForm.DrawAppearanceDisplay;
begin
    SetupAppearanceDisplay;
    AppearanceTPreview.Repaint;
end;

// *** SHOW HOLES STRIPS / BREAKS / COMPONENTS / LINKS CHECKBOXES ***
procedure TPrintSetupForm.AppearanceHolesTCheckBoxClick(Sender: TObject);
begin
    View^.ShowHoles := AppearanceHolesTCheckBox.Checked;
    DrawAppearanceDisplay;
end;

// *** SHOW STRIPS CHECKBOX **
procedure TPrintSetupForm.AppearanceStripsTCheckBoxClick(Sender: TObject);
begin
    View^.ShowStripLines := AppearanceStripsTCheckBox.Checked;
    DrawAppearanceDisplay;
end;

procedure TPrintSetupForm.AppearanceBreaksTCheckBoxClick(Sender: TObject);
begin
    View^.ShowBreaks := AppearanceBreaksTCheckBox.Checked;
    DrawAppearanceDisplay;
end;

procedure TPrintSetupForm.AppearanceComponentsTCheckBoxClick(
  Sender: TObject);
begin
    View^.ShowComponents := AppearanceComponentsTCheckBox.Checked;
    DrawAppearanceDisplay;
end;

procedure TPrintSetupForm.AppearanceLinksTCheckBoxClick(Sender: TObject);
begin
    View^.ShowLinks := AppearanceLinksTCheckBox.Checked;
    DrawAppearanceDisplay;
end;

procedure TPrintSetupForm.AppearanceWiresTCheckBoxClick(Sender: TObject);
begin
    View^.ShowWires := AppearanceWiresTCheckBox.Checked;
    DrawAppearanceDisplay;
end;

// *** COMPONENT TEXT RADIOBUTTONS **
procedure TPrintSetupForm.AppearanceNoTextTRadioButtonClick(Sender: TObject);
begin
    FComponentTextDisplay := ctNone;
    DrawAppearanceDisplay;
end;

procedure TPrintSetupForm.AppearanceDesignatorsTRadioButtonClick(Sender: TObject);
begin
    FComponentTextDisplay := ctDesignators;
    DrawAppearanceDisplay;
end;

procedure TPrintSetupForm.AppearanceValuesTRadioButtonClick(Sender: TObject);
begin
    FComponentTextDisplay := ctValues;
    DrawAppearanceDisplay;
end;

// *** LEAD WIDTHS RADIOBUTTONS ***
procedure TPrintSetupForm.AppearanceWideLeadTRadioButtonClick(Sender: TObject);
begin
    View^.LeadStyle := lsHollow;
    DrawAppearanceDisplay;
end;

procedure TPrintSetupForm.AppearanceNarrowLeadTRadioButtonClick(
  Sender: TObject);
begin
    View^.LeadStyle := lsLine;
    DrawAppearanceDisplay;
end;

// *** HOLE DIAMETER EDIT & BUTTON ***
procedure TPrintSetupForm.AppearanceHoleDiameterTEditKeyPress(
  Sender: TObject; var Key: Char);
begin
    if Key = #13 then begin
        ReadHoleDiameter;
        Key := #0;
    end;
end;

procedure TPrintSetupForm.AppearanceHoleDiameterTButtonClick(
  Sender: TObject);
begin
    ReadHoleDiameter;
end;

procedure TPrintSetupForm.ReadHoleDiameter;
var
    Width : integer;
begin
    Width := StrToIntDef( AppearanceHoleDiameterTEdit.Text, DEFAULT_HOLE_DIAM );
    if Width < MIN_HOLE_DIAM then begin
        Width := MIN_HOLE_DIAM;
    end
    else if Width > MAX_HOLE_DIAM then begin
        Width := MAX_HOLE_DIAM;
    end;
    AppearanceHoleDiameterTEdit.Text := IntToStr( Width );
    View^.HoleDiameterCellThousandths := Width;
    DrawAppearanceDisplay;
end;


// *** COMPONENT LINE WIDTH EDIT & BUTTON ***
procedure TPrintSetupForm.AppearanceComponentLineWidthTEditKeyPress(
  Sender: TObject; var Key: Char);
begin
    if Key = #13 then begin
        ReadComponentLineWidth;
        Key := #0;
    end;
end;

procedure TPrintSetupForm.AppearanceComponentLineWidthTButtonClick(
  Sender: TObject);
begin
    ReadComponentLineWidth;
end;

procedure TPrintSetupForm.ReadComponentLineWidth;
var
    Width : integer;
begin
    Width := StrToIntDef( AppearanceComponentLineWidthTEdit.Text, DEFAULT_COMPONENT_LINE_WIDTH );
    if Width < MIN_COMPONENT_LINE_WIDTH then begin
        Width := MIN_COMPONENT_LINE_WIDTH;
    end
    else if Width > MAX_COMPONENT_LINE_WIDTH then begin
        Width := MAX_COMPONENT_LINE_WIDTH;
    end;
    AppearanceComponentLineWidthTEdit.Text := IntToStr( Width );
    View^.ComponentLineWidthCellThousandths := Width;
    DrawAppearanceDisplay;
end;


// *** STRIP LINE WIDTH EDIT & BUTTON ***
procedure TPrintSetupForm.AppearanceStripLineWidthTEditKeyPress(
  Sender: TObject; var Key: Char);
begin
    if Key = #13 then begin
        ReadStripLineWidth;
        Key := #0;
    end;
end;

procedure TPrintSetupForm.AppearanceStripLineWidthTButtonClick(
  Sender: TObject);
begin
    ReadStripLineWidth;
end;

procedure TPrintSetupForm.ReadStripLineWidth;
var
    Width : integer;
begin
    Width := StrToIntDef( AppearanceStripLineWidthTEdit.Text, DEFAULT_STRIP_WIDTH );
    if Width < MIN_STRIP_WIDTH then begin
        Width := MIN_STRIP_WIDTH;
    end
    else if Width > MAX_STRIP_WIDTH then begin
        Width := MAX_STRIP_WIDTH;
    end;
    AppearanceStripLineWidthTEdit.Text := IntToStr( Width );
    View^.StripLineWidthCellThousandths := Width;
    DrawAppearanceDisplay;
end;


// *** SETTINGS TO CONTROLS ***
procedure TPrintSetupForm.LoadAppearanceControls;
    procedure SetCheckBox( Box : TCheckBox; Checked : boolean );
    var
        SaveOnClick : TNotifyEvent;
    begin
        SaveOnClick := Box.OnClick;
        try
            Box.OnClick := nil;
            Box.Checked := Checked;
        finally
            Box.OnClick := SaveOnClick;
        end;
    end;
    procedure SetRadioButtons( RButton0, RButton1 : TRadioButton; ButtonIndex : integer );
    var
        SaveOnClick0 : TNotifyEvent;
        SaveOnClick1 : TNotifyEvent;
    begin
        SaveOnClick0 := RButton0.OnClick;
        SaveOnClick1 := RButton1.OnClick;
        try
            RButton0.OnClick := nil;
            RButton1.OnClick := nil;

            if ButtonIndex = 0 then begin
                RButton0.Checked := True;
            end
            else begin
                RButton1.Checked := True;
            end;
        finally
            RButton0.OnClick := SaveOnClick0;
            RButton1.OnClick := SaveOnClick1;
        end;
    end;
var
    Save0, Save1, Save2 : TNotifyEvent;
begin
    // items to show
    SetCheckBox( AppearanceHolesTCheckBox, View^.ShowHoles );
    SetCheckBox( AppearanceStripsTCheckBox, View^.ShowStripLines );
    SetCheckBox( AppearanceBreaksTCheckBox, View^.ShowBreaks );
    SetCheckBox( AppearanceComponentsTCheckBox, View^.ShowComponents );
    SetCheckBox( AppearanceLinksTCheckBox, View^.ShowLinks );
    SetCheckBox( AppearanceWiresTCheckBox, View^.ShowWires );

    // component text
    if not FMirrored then begin

        Save0 := AppearanceDesignatorsTRadioButton.OnClick;
        Save1 := AppearanceValuesTRadioButton.OnClick;
        Save2 := AppearanceNoTextTRadioButton.OnClick;
        try
            AppearanceDesignatorsTRadioButton.OnClick := nil;
            AppearanceValuesTRadioButton.OnClick := nil;
            AppearanceNoTextTRadioButton.OnClick := nil;
            case FComponentTextDisplay of
                ctDesignators : AppearanceDesignatorsTRadioButton.Checked := True;
                ctValues : AppearanceValuesTRadioButton.Checked := True;
                ctNone : AppearanceNoTextTRadioButton.Checked := True;
            end;
        finally
            AppearanceDesignatorsTRadioButton.OnClick := Save0;
            AppearanceValuesTRadioButton.OnClick := Save1;
            AppearanceNoTextTRadioButton.OnClick := Save2;
        end;
    end;

    // hide text radio buttons when mirrored
    AppearanceDesignatorsTRadioButton.Visible := not FMirrored;
    AppearanceValuesTRadioButton.Visible := not FMirrored;
    AppearanceNoTextTRadioButton.Visible := not FMirrored;

    // lead width
    Save0 := AppearanceNarrowLeadTRadioButton.OnClick;
    Save1 := AppearanceWideLeadTRadioButton.OnClick;
    try
        AppearanceNarrowLeadTRadioButton.OnClick := nil;
        AppearanceWideLeadTRadioButton.OnClick := nil;
        case View^.LeadStyle of
            lsLine : AppearanceNarrowLeadTRadioButton.Checked := True;
            lsHollow : AppearanceWideLeadTRadioButton.Checked := True;
        end;
    finally
        AppearanceNarrowLeadTRadioButton.OnClick := Save0;
        AppearanceWideLeadTRadioButton.OnClick := Save1;
    end;

    // hole diameter
    AppearanceHoleDiameterTEdit.Text := IntToStr( View^.HoleDiameterCellThousandths );

    // component line width
    AppearanceComponentLineWidthTEdit.Text := IntToStr( View^.ComponentLineWidthCellThousandths );

    // strip line width
    AppearanceStripLineWidthTEdit.Text := IntToStr( View^.StripLineWidthCellThousandths );
end;


// ****************************************************
//              FORM CREATE & FREE & SHOW
// ****************************************************

procedure TPrintSetupForm.FormCreate(Sender: TObject);
begin
    // initialise pointer
    View := @Front;

    CreatePagesDisplay;
    CreateAppearanceDisplay;
end;

procedure TPrintSetupForm.FormDestroy(Sender: TObject);
begin
    FreePagesDisplay;
    FreeAppearanceDisplay;
end;


procedure TPrintSetupForm.FormShow(Sender: TObject);
begin
    // show page tab first
    PageControl1.ActivePageIndex := 0;
    ActiveControl := PrintTButton;      // i.e. SetFocus()
    LoadSettings;
    ValidateSettings;

    // display settings in controls
    DrawPrinterDisplay;

    // transfer settings to previews
    LoadPagesControls;
    LoadAppearanceControls;

    //
    DrawPagesDisplay;

    // now connect up tab handlers so change of tab redraws info displayed
    // on that tab
    PagesTTabSheet.OnShow := PagesTTabSheetShow;
    AppearanceTTabSheet.OnShow := AppearanceTTabSheetShow;
end;

procedure TPrintSetupForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    SaveSettings;
end;


// ****************************************************
//             LOAD & SAVE INIFILE SETTINGS
// ****************************************************


procedure TPrintSetupForm.LoadSettings;
var
    IniFile : TRegIniFile;

    procedure LoadView( View : PveAppearance; const Key : string );
    const PortraitToOrientation : array[boolean] of TPrinterOrientation =
        ( poLandscape, poPortrait );
    var
        LeadText : string;
    begin
        LeadText := IniFile.ReadString( Key, 'LeadStyle', '' );
        if LeadText = 'Narrow' then begin
            View^.LeadStyle := lsLine;
        end
        else if LeadText = 'Wide' then begin
            View^.LeadStyle := lsHollow;
        end
        else begin
            View^.LeadStyle := DEFAULT_LEAD_STYLE;
        end;

         View^.ShowHoles :=
            IniFile.ReadBool( Key, 'ShowHoles', DEFAULT_SHOW_HOLES );
        View^.ShowStripLines :=
            IniFile.ReadBool( Key, 'ShowStrips', DEFAULT_SHOW_STRIPS );

        View^.ShowComponents :=
            IniFile.ReadBool( Key, 'ShowComponents', DEFAULT_SHOW_COMPONENTS );
        View^.ShowBreaks :=
            IniFile.ReadBool( Key, 'ShowBreaks', DEFAULT_SHOW_BREAKS );
        View^.ShowLinks :=
            IniFile.ReadBool( Key, 'ShowLinks', DEFAULT_SHOW_LINKS );
        View^.ShowWires :=
            IniFile.ReadBool( Key, 'ShowWires',  DEFAULT_SHOW_WIRES );

        View^.HoleDiameterCellThousandths :=
            IniFile.ReadInteger( Key, 'HoleDiameter', DEFAULT_HOLE_DIAM );
        View^.ComponentLineWidthCellThousandths :=
            IniFile.ReadInteger( Key, 'ComponentLineWidth', DEFAULT_COMPONENT_LINE_WIDTH );
        View^.StripLineWidthCellThousandths :=
            IniFile.ReadInteger( Key, 'StripLineWidth', DEFAULT_STRIP_WIDTH );
        View^.ScalePercent :=
            IniFile.ReadInteger( Key, 'Scale', DEFAULT_SCALE_PERCENT );
//        FMirrored :=
//            IniFile.ReadBool( 'Print', 'Mirrored', DEFAULT_MIRRORED );
        View^.Orientation :=
            PortraitToOrientation[IniFile.ReadBool( 'Print', 'Portrait', DEFAULT_ORIENTATION = poPortrait )];
//        PrinterName :=
//            IniFile.ReadString( 'Print', 'PrinterName', '' );
        View^.MarginLeftMM :=
              IniFile.ReadInteger( Key, 'MarginLeftMM', DEFAULT_MARGIN_LEFT_MM );
        View^.MarginRightMM :=
              IniFile.ReadInteger( Key, 'MarginRightMM', DEFAULT_MARGIN_RIGHT_MM );
        View^.MarginTopMM :=
              IniFile.ReadInteger( Key, 'MarginTopMM', DEFAULT_MARGIN_TOP_MM );
        View^.ShowColor :=
            IniFile.ReadBool( Key, 'ShowColor',  DEFAULT_SHOW_COLOR );
    end;

var
    ComponentText : string;
    PrinterName : string;
    PrinterIndex : integer;

begin
    IniFile := GetRegIniFile;
    try
        ComponentText := IniFile.ReadString( 'Print', 'ComponentText', '' );
        if ComponentText = 'Designators' then begin
            FComponentTextDisplay := ctDesignators;
        end
        else if ComponentText = 'Values' then begin
            FComponentTextDisplay := ctValues;
        end
        else if ComponentText = 'None' then begin
            FComponentTextDisplay := ctNone;
        end
        else begin
            FComponentTextDisplay := DEFAULT_COMPONENT_TEXT;
        end;

        // many settings are stored twice - for front & rear views
        LoadView( @Front, 'Print' );
        LoadView( @Rear, 'PrintRear' );

        FMirrored :=
            IniFile.ReadBool( 'Print', 'Mirrored', DEFAULT_MIRRORED );

        // switch settings to either front, or rear
        if FMirrored then begin
            View := @Rear;
        end
        else begin
            View := @Front;
        end;

        PrinterName :=
            IniFile.ReadString( 'Print', 'PrinterName', '' );

    finally
        IniFile.Free;
    end;

    // switch to printer read from INI file : stored in FPrinterName
    PrinterIndex := Printer.Printers.IndexOf( PrinterName );

    // if printer found in list, switch to it, otherwise, switches to
    // default printer (Index = -1)
    Printer.PrinterIndex := PrinterIndex;
end;

procedure TPrintSetupForm.SaveSettings;
const
    PrinterComponentTextToStr : array[TPrinterCOmponentText] of string =
        ( 'None', 'Designators', 'Values' );
    LeadStyleToStr : array[TLeadStyle] of string = ('Wide', 'Narrow' );
var
    IniFile : TRegIniFile;

    procedure SaveView( View : PveAppearance; const Key : string );
    begin
        IniFile.WriteBool( Key, 'ShowHoles', View^.ShowHoles );
        IniFile.WriteBool( Key, 'ShowStrips', View^.ShowStripLines );
        IniFile.WriteBool( Key, 'ShowComponents', View^.ShowComponents );
        IniFile.WriteBool( Key, 'ShowBreaks', View^.ShowBreaks );
        IniFile.WriteBool( Key, 'ShowLinks', View^.ShowLinks );
        IniFile.WriteBool( Key, 'ShowWires', View^.ShowWires );
//        IniFile.WriteString( 'Print', 'ComponentText', PrinterComponentTextToStr[FComponentTextDisplay] );

        IniFile.WriteString( Key, 'LeadStyle', LeadStyleToStr[View^.LeadStyle] );
        IniFile.WriteInteger( Key, 'HoleDiameter', View^.HoleDiameterCellThousandths );
        IniFile.WriteInteger( Key, 'ComponentLineWidth', View^.ComponentLineWidthCellThousandths );
        IniFile.WriteInteger( Key, 'StripLineWidth', View^.StripLineWidthCellThousandths );
        IniFile.WriteInteger( Key, 'Scale', View^.ScalePercent );
//        IniFile.WriteBool( 'Print', 'Mirrored', FMirrored );
        IniFile.WriteBool( Key, 'Portrait', View^.Orientation = poPortrait );

//        IniFile.WriteString( 'Print', 'PrinterName', Printer.Printers[Printer.PrinterIndex] );

        IniFile.WriteInteger( Key, 'Scale', View^.ScalePercent );

        IniFile.WriteInteger( Key, 'MarginLeftMM', View^.MarginLeftMM );
        IniFile.WriteInteger( Key, 'MarginRightMM', View^.MarginRightMM );
        IniFile.WriteInteger( Key, 'MarginTopMM', View^.MarginTopMM );

        IniFile.WriteBool( Key, 'ShowColor', View^.ShowColor );
    end;

begin
    IniFile := GetRegIniFile;
    try
        IniFile.WriteString( 'Print', 'ComponentText', PrinterComponentTextToStr[FComponentTextDisplay] );
        SaveView( @Front, 'Print' );
        SaveView( @Rear, 'PrintRear' );

        IniFile.WriteBool( 'Print', 'Mirrored', FMirrored );
        IniFile.WriteString( 'Print', 'PrinterName', Printer.Printers[Printer.PrinterIndex] );
    finally
        IniFile.Free;
    end;
end;


procedure TPrintSetupForm.ValidateSettings;

    procedure ValidateView( View : PveAppearance );
    begin
        // hole diameter
        if View^.HoleDiameterCellThousandths < MIN_HOLE_DIAM then begin
            View^.HoleDiameterCellThousandths := MIN_HOLE_DIAM;
        end
        else if View^.HoleDiameterCellThousandths > MAX_HOLE_DIAM then begin
            View^.HoleDiameterCellThousandths := MAX_HOLE_DIAM;
        end;

        // component line width
        if  View^.ComponentLineWidthCellThousandths < MIN_COMPONENT_LINE_WIDTH then begin
            View^.ComponentLineWidthCellThousandths := MIN_COMPONENT_LINE_WIDTH;
        end
        else if View^.ComponentLineWidthCellThousandths > MAX_COMPONENT_LINE_WIDTH then begin
            View^.ComponentLineWidthCellThousandths := MAX_COMPONENT_LINE_WIDTH;
        end;

        // Strip Width
        if View^.StripLineWidthCellThousandths < MIN_STRIP_WIDTH then begin
            View^.StripLineWidthCellThousandths := MIN_STRIP_WIDTH;
        end
        else if View^.StripLineWidthCellThousandths > MAX_STRIP_WIDTH then begin
            View^.StripLineWidthCellThousandths := MAX_STRIP_WIDTH;
        end;

        // Scale
        if View^.ScalePercent < MIN_SCALE_PERCENT then begin
            View^.ScalePercent := MIN_SCALE_PERCENT;
        end
        else if View^.ScalePercent > MAX_SCALE_PERCENT then begin
            View^.ScalePercent := MAX_SCALE_PERCENT;
        end
    end;

begin
    ValidateView( @Front );
    ValidateView( @Rear );
end;



procedure TPrintSetupForm.PrintTButtonClick(Sender: TObject);
var
    PerfPrint : TvePrinter;
begin
    // orientation not forced to Printer until print time
    Printer.Orientation := View^.Orientation;
    Printer.Copies := PagesCopiesTUpDown.Position;
    Printer.Title := FPrinterTitle;

    // draw pages on printer
    PerfPrint := TvePrinter.Create;
    try
        PerfPrint.Project := Project;
        PerfPrint.ShowHoles := View^.ShowHoles;
        PerfPrint.ShowStripLines := View^.ShowStripLines;
        PerfPrint.ShowComponents := View^.ShowComponents;
        PerfPrint.ShowBreaks := View^.ShowBreaks;
        PerfPrint.ShowLinks := View^.ShowLinks;
        PerfPrint.ShowWires := View^.ShowWires;
        PerfPrint.ComponentTextDisplay := FComponentTextDisplay;
        PerfPrint.LeadStyle := View^.LeadStyle;
        PerfPrint.HoleDiameterCellThousandths := View^.HoleDiameterCellThousandths;
        PerfPrint.StripLineWidthCellThousandths := View^.StripLineWidthCellThousandths;
        PerfPrint.ComponentLineWidthCellThousandths := View^.ComponentLineWidthCellThousandths;
        PerfPrint.ScalePercent := View^.ScalePercent;
        PerfPrint.Mirrored := FMirrored;
        PerfPrint.MarginLeftMM := View^.MarginLeftMM;
        PerfPrint.MarginRightMM := View^.MarginRightMM;
        PerfPrint.MarginTopMM := View^.MarginTopMM;

        PerfPrint.Colors := Colors;
        PerfPrint.Colors.ShowColor := View^.ShowColor;

        PerfPrint.Print;
    finally
        PerfPrint.Free;
    end;

    ModalResult := mrOK;
end;

procedure TPrintSetupForm.FormResize(Sender: TObject);
begin
    // center
    PrintTButton.Left := (Panel1.Width - (3 * PrintTButton.Width)) div 2;
    CloseTButton.Left := (Panel1.Width + CloseTBUtton.Width) div 2;
end;


// User selects Pages Tab : Update its display
procedure TPrintSetupForm.PagesTTabSheetShow(Sender: TObject);
begin
    DrawPagesDisplay;
end;

// user selects Appearance Tab : Update its display
procedure TPrintSetupForm.AppearanceTTabSheetShow(Sender: TObject);
begin
    AppearanceTPreview.ScrollToOrigin;
    DrawAppearanceDisplay;
end;


end.


