unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Menus, ComCtrls,
  Editor, Project, FileMenuHandler, Outlines, Grids, Calendar, ToolWin, Mask,
  ImgList, Netlist, CustomizeDlg;

type

  TMainForm = class(TForm)
    MainMenu1: TMainMenu;
    ToolBar1: TToolBar;
    SelectTToolButton: TToolButton;
    BreakTToolButton: TToolButton;
    LinkTToolButton: TToolButton;
    ImageList1: TImageList;
    StatusBar2: TStatusBar;
    RotateTToolbutton: TToolButton;
    ToolButton3: TToolButton;
    ZoomInTToolButton: TToolButton;
    ZoomOutTToolButton5: TToolButton;
    Project1: TMenuItem;
    Items1: TMenuItem;
    Outlines1: TMenuItem;
    Board1: TMenuItem;
    ShowNetErrorsTToolButton: TToolButton;
    TraceNetTToolbutton: TToolButton;
    Edit1: TMenuItem;
    Find1: TMenuItem;
    WireTToolButton: TToolButton;
    Help1: TMenuItem;
    About1: TMenuItem;
    Import1: TMenuItem;
    ScrollBox1: TScrollBox;
    Materials1: TMenuItem;
    Preferences1: TMenuItem;
    NetlistImport: TMenuItem;
    NetlistView: TMenuItem;
    Undo1: TMenuItem;
    Redo1: TMenuItem;
    Contents1: TMenuItem;
    VeeCADWebsite1: TMenuItem;
    ArrangeComponents1: TMenuItem;
    Route1: TMenuItem;
    PlaceSelectedNetLinks: TMenuItem;
    PlaceBreaks: TMenuItem;
    PlaceSelectedLeadedItem: TMenuItem;
    PlaceLinks: TMenuItem;
    Select1: TMenuItem;
    All1: TMenuItem;
    InSelection1: TMenuItem;
    All2: TMenuItem;
    InSelection2: TMenuItem;
    Redundant2: TMenuItem;
    N1: TMenuItem;
    PlaceLeadedComponents: TMenuItem;
    FullAutoroute1: TMenuItem;
    N3: TMenuItem;
    Tools1: TMenuItem;
    TextTToolButton: TToolButton;
    ToolButton1: TToolButton;
    MakeLibraryLayout1: TMenuItem;
    All3: TMenuItem;
    N2: TMenuItem;
    InvertSelection1: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    ComponentsNotRequired1: TMenuItem;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    CopyGraphic2: TMenuItem;
    ToolButton4: TToolButton;
    DesignatorsTToolButton: TToolButton;
    ValuesTToolButton: TToolButton;
    NoTextTToolButton: TToolButton;
    ToolButton2: TToolButton;
    FreeStripsTToolButton: TToolButton;
    Strips1: TMenuItem;
    GroupSelection1: TMenuItem;
    UnGroupSelection1: TMenuItem;
    N6: TMenuItem;
    Delete1: TMenuItem;
    PastewithDuplicates1: TMenuItem;
    N5SelectedLeadedItems1: TMenuItem;
    TrackEditor1: TMenuItem;
    NetlistColors: TMenuItem;
    Gcode1: TMenuItem;
    Notes1: TMenuItem;
    TrackCuts: TMenuItem;
    Links_Components: TMenuItem;
    CheckforUpdates1: TMenuItem;
    MakeFromlayout1: TMenuItem;
    ExportNet1: TMenuItem;
    Clear1: TMenuItem;
    CustomizeDlg1: TCustomizeDlg;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SelectTToolButtonClick(Sender: TObject);
    procedure BreakTToolButtonClick(Sender: TObject);
    procedure LinkTToolButtonClick(Sender: TObject);
    procedure RotateTToolbuttonClick(Sender: TObject);
    procedure ZoomOutTToolButton5Click(Sender: TObject);
    procedure ZoomInTToolButtonClick(Sender: TObject);
    procedure Print1Click(Sender: TObject);
    procedure Board1Click(Sender: TObject);
    procedure Outlines1Click(Sender: TObject);
    procedure Find1Click(Sender: TObject);
    procedure NetlistViewClick(Sender: TObject);
    procedure Items1Click(Sender: TObject);
    procedure ShowNetErrorsTToolButtonClick(Sender: TObject);
    procedure TraceNetTToolbuttonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure WireTToolButtonClick(Sender: TObject);
    procedure CopyGraphic1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure Materials1Click(Sender: TObject);
    procedure Preferences1Click(Sender: TObject);
    procedure NetlistImportClick(Sender: TObject);
    procedure Undo1Click(Sender: TObject);
    procedure Redo1Click(Sender: TObject);
    procedure Contents1Click(Sender: TObject);
    procedure NoTextTToolButtonClick(Sender: TObject);
    procedure ValuesTToolButtonClick(Sender: TObject);
    procedure DesignatorsTToolButtonClick(Sender: TObject);
    procedure VeeCADWebsite1Click(Sender: TObject);
    procedure ArrangeComponents1Click(Sender: TObject);
    procedure PlaceSelectedNetLinksClick(Sender: TObject);
    procedure PlaceBreaksClick(Sender: TObject);
    procedure PlaceLinksClick(Sender: TObject);
    procedure All1Click(Sender: TObject);
    procedure InSelection1Click(Sender: TObject);
    procedure Redundant1Click(Sender: TObject);
    procedure All2Click(Sender: TObject);
    procedure Redundant2Click(Sender: TObject);
    procedure InSelection2Click(Sender: TObject);
    procedure PlaceSelectedLeadedItemClick(Sender: TObject);
    procedure PlaceLeadedComponentsClick(Sender: TObject);
    procedure FullAutoroute1Click(Sender: TObject);
    procedure MakeLibraryLayout1Click(Sender: TObject);
    procedure TextTToolButtonClick(Sender: TObject);
    procedure CheckforUpdates1Click(Sender: TObject);
    procedure All3Click(Sender: TObject);
    procedure InvertSelection1Click(Sender: TObject);
    procedure ComponentsNotRequired1Click(Sender: TObject);
    procedure Copy1Click(Sender: TObject);
    procedure Paste1Click(Sender: TObject);
    procedure FreeStripsTToolButtonClick(Sender: TObject);
    procedure Strips1Click(Sender: TObject);
    procedure GroupSelection1Click(Sender: TObject);
    procedure UnGroupSelection1Click(Sender: TObject);
    procedure Delete1Click(Sender: TObject);
    procedure PastewithDuplicates1Click(Sender: TObject);
    procedure N5SelectedLeadedItems1Click(Sender: TObject);
    procedure TrackEditor1Click(Sender: TObject);
    procedure NetlistColorsClick(Sender: TObject);
    procedure Notes1Click(Sender: TObject);
    procedure Links_ComponentsClick(Sender: TObject);
    procedure TrackCutsClick(Sender: TObject);
    procedure MakeFromlayout1Click(Sender: TObject);
    procedure Clear1Click(Sender: TObject);
    procedure ExportNet1Click(Sender: TObject);
  private
    { Private declarations }
    Project : TveProject;
    Editor : TveEditor;
    FileMenuHandler : TFileMenuHandler;

    procedure FileHandlerFileRead(
        Sender : TObject; const FileName : string; var Done : boolean );
    procedure FileHandlerFileWrite(
        Sender : TObject; const FileName : string; var Done : boolean );
    procedure FileHandlerFileNew(
        Sender : TObject; const FileName : string; var Done : boolean );
    procedure FileHandlerClose(
        Sender : TObject; const FileName : string; var Done : boolean );
    procedure FileHandlerOnChangeFileName( Sender : TObject );
    procedure FileHandlerExit( Sender : TObject );

    procedure OnMouseCellMove( CellX, CellY : integer );
    procedure OnMouseClickItem( Item : TveBoardItem; PinName : string; Node : TneNode );
    procedure OnChangeDirty( Sender : TObject );
    procedure OnChangeMode( Sender : TObject; Mode : TPerfEditMode );
    procedure OnChangePattern( Sender : TObject );

    procedure EnsureProjectFile;

    procedure ApplicationException( Sender: TObject; E: Exception );

  public
    { Public declarations }
    property FileMenuHandlerPublic : TFileMenuHandler read FileMenuHandler;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

uses ProjectInput, ProjectOutput,
    BoardSettings, OutlineSettings, BoardItemSettings, SelectItem,
    NetlistSettings1, Import, Globals, Registry, GraphicCopy, About,
    Materials, SettingsFrm, Rotations, Painter, FullPathName, WebUpdate,
    PrintSetup, Placement, Selector, Breaks, Route, LibraryTools,
    SizeableOutlines, BoardPattern,
    DebugFrm, Connective, Board, ExceptSafe, JsonParse, TrackEditFm,
    ColorNetLinkFm, GcodeFm, NotesFm, NetlistUser;

// ****************************************
//  ***  Project File Must Always Exist ***
// ****************************************

// must have some kind of document acknowleged by FilemMnuHandler, because
// Project object cannot be disabled, and edits must be saved to some
// file

procedure TMainForm.EnsureProjectFile;
begin

//    if not FileMenuHandler.ActiveDocument then begin
//        FileMenuHandler.NewFile;
//    end;

end;

// ****************************************
//  ***    Constructor & Destructor     ***
// ****************************************

procedure TMainForm.FormCreate(Sender: TObject);
var
    MenuItem : TMenuItem;
begin
    // Get Global Exception Catcher Working - all exceptions routed there
    Application.OnException := ApplicationException;

    // default caption, before any file loaded
    Caption := 'VeeCAD';

    InitialiseGlobals;

    FileMenuHandler := TFileMenuHandler.Create;
        FileMenuHandler.MaxRecentFiles := 12;
    FileMenuHandler.Menu := MainMenu1;

    FileMenuHandler.HKEY_CURRENT_USER_key := Globals.HKEY_CURRENT_USER_KEY;
    FileMenuHandler.FileExtension := 'per';
    FileMenuHandler.FileFilter :=
        'VeeCAD files (*.per}|*.per|All files (*.*)|*.*';
    // (we can't stop Editor from being visible and enabled for editing)
    FileMenuHandler.DocAlwaysOpen := True;

    FileMenuHandler.OnFileRead := FileHandlerFileRead;
    FileMenuHandler.OnFileWrite := FileHandlerFileWrite;
    FileMenuHandler.OnFileNew := FileHandlerFileNew;
    FileMenuHandler.OnFileClose := FileHandlerClose;
    FileMenuHandler.OnChangeFileName := FileHandlerOnChangeFileName;
    FileMenuHandler.OnExit := FileHandlerExit;

    // create editor
    Editor := TveEditor.Create( self );
    Project := TveProject.Create;
    Editor.Project := Project;
    Editor.Parent := ScrollBox1;
//    Editor.Parent := self;
    Editor.Enabled := True;

    Editor.Visible := True;

    Editor.Left := 0;
    Editor.Top := 0;

    Editor.TabStop := False;

    Editor.OnMouseCellMove := OnMouseCellMove;
    Editor.OnMouseClickItem := OnMouseClickItem;

    Editor.OnChange := OnChangeDirty;
    Editor.OnChangeMode := OnChangeMode;

    // wire up editor to menu handler so dirty status passed from editor
    Editor.Dirty := False;

    // insert additional menus into File Menu created by FileMenuHandler
    MenuItem := FileMenuHandler.InsertMenuItem( 4, '&Print...', Print1Click );
    MenuItem.ShortCut := ShortCut(Word('P'), [ssCtrl]);

    // **WARNING* drilling straight thru to Board. If we switch Editor to
    // another Project, (Eg. multi-board editor, tabs or MDI ) code will break.
    Editor.Project.Board.OnChangePattern := OnChangePattern;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
    CommandFile : string;
    CommandFileLong : string;
begin
    // Prevents bug - run VeeCAD and let it auto open last project.  Pull horiz
    // scrollbar to right and click - on board - scrollbox then descrolls which
    // means you drag a component just by clicking it.
    // Also, without .SetFocus, Editor.KeyDown never called.
    Editor.SetFocus;

    // setup netlist form
    NetlistForm1.Netlist := Project.Netlist;
    NetlistForm1.Project := Project;

    // setup materials form
    MaterialsForm.Project := Project;

    // setup notes form
    NotesForm.Project := Project;

    // load settings from Registry
    ReadSettings( Editor );

    // make toolbar match loaded settings in Editor
    ShowNetErrorsTToolButton.Down := Editor.ConnectionErrorsVisible;
    TraceNetTToolbutton.Down := Editor.NetTraceVisible;
    DesignatorsTToolButton.Down := True;

    // set form position & size
    //.. start with default form size, because we need to show startup
    // document which looks good at 800 x 550, 13 pixels per cell, on 96 dpi
    // screen. Scale for present dpi
    // No need for code here - form properties are set to 800x600 at design
    // time and form will scale at run time according to DPI.
    //    Width := (PixelsPerInch * 800) div 96;
    //    Height := (PixelsPerInch * 550) div 96;

    // further adjust form position and size, including registry saved data
    GetFormMinder.AdjustForm( self );

    // try to load file from command line
    // filename must be in long filename, full form with no relative paths
    // in order to be compatible with the conventions used within this program.
    CommandFile := ParamStr(1);
    CommandFileLong := GetFullLongPathName( CommandFile );
    if CommandFileLong <> '' then begin
        try
            FileMenuHandler.LoadFile( CommandFileLong );
        except
        end;
    end;

    // try to load last file
    if not FileMenuHandler.ActiveDocument then begin
        FileMenuHandler.LoadMostRecentFile;
    end;

    // must have some kind of document acknowleged by FilemMnuHandler
    EnsureProjectFile;

    // always start in normal designators mode
    DesignatorsTToolButtonClick(nil);


{$IFDEF DEBUGFORM}
    // create debug form
    if not Assigned( DebugForm ) then begin
        DebugForm := TDebugForm.Create( Self );
    end;
    // position debug form beside main form
    DebugForm.Left := MainForm.Left + MainForm.Width;
    DebugForm.Top := MainForm.Top;

    DebugForm.Show;
{$ENDIF}

{$IFDEF DEBUG_CONNECTIVE}
    // hook up connectivity object to debug
    TConnectivity(Project.ConnectivityObject).OnDebugStart := DebugForm.DebugStart;
    TConnectivity(Project.ConnectivityObject).OnDebugLineOut := DebugForm.DebugLineOut;
    TConnectivity(Project.ConnectivityObject).OnDebugEnd := DebugForm.DebugEnd;
{$ENDIF}

    // if command line file or most recent file was not loaded, then without
    // Editor.Paint here, we never see a board on the screen.
    Editor.Paint;
end;


procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    CanClose := FileMenuHandler.ExitFile;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    SaveSettings( Editor );
    GetFormMinder.RecordForm( self );
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
    FileMenuHandler.Free;
    Editor.Free;
end;

procedure TMainForm.ApplicationException(Sender: TObject; E: Exception);
var
    s : string;
begin
    if (E is ESafe) or (E is EFileMenu) or (E is EJParse )
    then begin
        Application.ShowException(E);
    end
    else begin
        s := 'Internal Error: VeeCAD must close. ' + E.Message
            + ' Error Name: ' + E.ClassName;
        MessageBox( 0, pChar(s), 'VeeCAD', MB_OK );
        Application.Terminate;
    end;
end;


// ****************************************
//  *** Implement Menu Handler Requests ***
// ****************************************

procedure TMainForm.FileHandlerFileRead(
        Sender : TObject; const FileName : string; var Done : boolean );

var
    Loader : TProjectInputLoader;
begin
    //.. normally, all goes well, and we open the file
    Done := True;
    Loader := TProjectInputLoader.Create( Project );
    Editor.OnChange := nil;
    try
        Loader.LoadFromFile( FileName );
    except
        // error occured reading the file
        on E : Exception do begin
            // any file loading error is taken seriously.  We stop the exception
            // here and display the message.
            ShowMessage( Format( 'Cannot open file : %s.  (Detail: %s)',
                [FileName, E.Message]) );

            // wipe out any partly loaded project, leaving blank document
            // which is not associated with any filename
            Project.Clear;
            Done := False;
        end;
    end;
    Editor.OnChange := OnChangeDirty;
    Loader.Free;

    // report netlist error
    if not Project.Netlist.Validate( nil ) then begin
        ShowMessage( 'Netlist contains errors' );
    end;

    // repaint screen
//    NetlistForm1.UpdateInfo;
//    MaterialsForm.UpdateInfo;
    NotesForm.UpdateInfo;
    Editor.Dirty := False;
    Editor.Paint;
end;

procedure TMainForm.FileHandlerFileWrite(
    Sender : TObject; const FileName : string; var Done : boolean );
var
    Saver : TProjectOutputSaver;
begin
    Saver := TProjectOutputSaver.Create( Project );
    try
        Saver.SaveToFile( FileName );
    finally
        Saver.Free;
    end;
    Editor.Dirty := False;
    Done := True;
end;

procedure TMainForm.FileHandlerFileNew(
    Sender : TObject; const FileName : string; var Done : boolean );
begin
    Project.Clear;
    Editor.Dirty := False;
    NetlistForm1.UpdateInfo;
    MaterialsForm.UpdateInfo;
    NotesForm.UpdateInfo;
    Done := True;
end;

procedure TMainForm.FileHandlerClose(
        Sender : TObject; const FileName : string; var Done : boolean );
begin
    Project.Clear;
    // same as Editor.Refresh but gets tool button down and Designators mode set
    DesignatorsTToolButtonClick(nil);
    // Editor.Refresh;
    Done := True;
end;

procedure TMainForm.FileHandlerOnChangeFileName( Sender : TObject );
var
    FileName : string;
begin
    FileName := ExtractFileName( (Sender as TFileMenuHandler).FileName );
    Caption := ChangeFileExt( ExtractFileName(FileName), '' ) + ' - VeeCAD';
end;

procedure TMainForm.FileHandlerExit( Sender : TObject );
begin
    Close;
end;


// ****************************************
// ***      File Menu Events            ***
// ****************************************

procedure TMainForm.Print1Click(Sender: TObject);
var
    SetupForm : TPrintSetupForm;
    Title : string;
begin
    SetupForm := TPrintSetupForm.Create(self);
    try
        SetupForm.Project := Project;
        Title := ExtractFileName( FileMenuHandler.FileName );
        if Title = '' then begin
            Title := 'VeeCAD';
        end;
        SetupForm.PrinterTitle := Title;
        
        SetupForm.Colors.Board := Editor.BoardColor;
        SetupForm.Colors.Strips := Editor.StripColor;
        SetupForm.Colors.Body := Editor.BodyColor;
        SetupForm.Colors.Pin := Editor.PinColor;        
        
//        SetupForm.ShowModal;
        SetupForm.Execute;
    finally
        SetupForm.Free;
    end;
end;

// ****************************************
//  ***  Other Project Object Events    ***
// ****************************************

procedure TMainForm.OnMouseCellMove( CellX, CellY : integer );
begin
    StatusBar2.Panels[0].Text := Format( '%d,%d', [CellX, CellY] );
end;

procedure TMainForm.OnMouseClickItem( Item : TveBoardItem; PinName : string; Node : TneNode );
    
const Rotation2Str : array[TRotation] of string = ( '0', '90', '180', '270' );
var
    PinText : string;
    NodeText : string;
begin
    // show component properties in status bar panel
    if Item <> nil then begin
        StatusBar2.Panels[3].Text :=
            Format( 'Desig=%s, Value=%s Outline=%s, X=%d, Y=%d, Rot=%s',
            [Item.Designator, Item.Value, Item.Outline.Name, Item.X, Item.Y,
            Rotation2Str[Item.Rotation]]
            );
        // show length of leaded items
        if Item.Outline is TveSizeableOutline then begin
//            StatusBar2.Panels[4].Text := Format( 'Length=%d', [Item.Length] );
            StatusBar2.Panels[4].Text := 'Length=' + Item.DisplayLength;
        end
        else begin
            StatusBar2.Panels[4].Text := '';
        end;
    end
    else begin
        StatusBar2.Panels[3].Text := '';
        StatusBar2.Panels[4].Text := '';
    end;

    // show "Pin=2" in status bar panel
    if PinName <> '' then begin
        PinText := 'Pin=' + PinName;
    end;
    StatusBar2.Panels[1].Text := PinText;

    // show "Net=GND" in status bar panel
    if Node <> nil then begin
        NodeText := 'Net=' + Node.Name;
    end;
    StatusBar2.Panels[2].Text := NodeText;
end;

// ** ADJUST MENUS WHEN EDITOR GOES DIRTY **

procedure TMainForm.OnChangeDirty( Sender : TObject );
begin
    if TveEditor(Sender).Project.Dirty then begin
        FileMenuHandler.NotifyDirty;
    end;
end;

// ** ROUTER MENUS FOR STANDARD STRIPBOARD ONLY **
procedure TMainForm.OnChangePattern( Sender : TObject );
begin
    // **WARNING* drilling straight thru to Board. If we switch Editor to
    // another Project, (Eg. multi-board editor, tabs or MDI ) code will break.
    Route1.Enabled := (Project.Board.Pattern = ptStrip);
end;

// ****************************************
//  ***     TOOLBUTTON MODE CLICKS      ***
// ****************************************

procedure TMainForm.SelectTToolButtonClick(Sender: TObject);
begin
    Editor.EditMode := emSelect;
end;

procedure TMainForm.BreakTToolButtonClick(Sender: TObject);
begin
    Editor.EditMode := emBreak;
end;

procedure TMainForm.LinkTToolButtonClick(Sender: TObject);
begin
    Editor.EditMode := emLink;
end;

procedure TMainForm.WireTToolButtonClick(Sender: TObject);
begin
    Editor.EditMode := emWire;
end;

procedure TMainForm.TextTToolButtonClick(Sender: TObject);
begin
    Editor.EditMode := emText;
end;


procedure TMainForm.OnChangeMode( Sender : TObject; Mode : TPerfEditMode );
begin
    case Mode of
      emSelect : SelectTToolbutton.Down := True;
      emBreak : BreakTToolbutton.Down := True;
      emLink : LinkTToolbutton.Down := True;
      emWire : WireTToolbutton.Down := True;
      emText : TextTToolbutton.Down := True;
    end;
end;


// ****************************************
//  ***     TOOLBUTTON EDIT CLICKS      ***
// ****************************************

procedure TMainForm.RotateTToolbuttonClick(Sender: TObject);
begin
    Editor.RotateSelected;
end;

// ****************************************
//  ***     TOOLBUTTON VIEW CLICKS      ***
// ****************************************

procedure TMainForm.ZoomInTToolButtonClick(Sender: TObject);
begin
    Editor.PixelsPerCell := Editor.PixelsPerCell + 1;
    Editor.Refresh;
end;

procedure TMainForm.ZoomOutTToolButton5Click(Sender: TObject);
begin
    Editor.PixelsPerCell := Editor.PixelsPerCell - 1;
    Editor.Refresh;
end;


// ****************************************
// ***   TOOLBUTTON SHOW NETS CLICKS    ***
// ****************************************

{ When using XP Themes, toolbuttons do not go down when clicked, but do go
down when .Down property is set to True in code.  So we set Down in code, but
do not read the Down property. We read the editor properties to see if button
is supposed to be down or up this click.  This code works in Win9x and WinXP }

procedure TMainForm.ShowNetErrorsTToolButtonClick(Sender: TObject);
var
    Down : boolean;
begin
    Down := not Editor.ConnectionErrorsVisible;
    Editor.ConnectionErrorsVisible := Down;
    Editor.EndDrawSequence;
end;

procedure TMainForm.TraceNetTToolbuttonClick(Sender: TObject);
var
    Down : boolean;
begin
    Down := not Editor.NetTraceVisible;
    Editor.NetTraceVisible := Down;
    Editor.EndDrawSequence;
end;

procedure TMainForm.FreeStripsTToolButtonClick(Sender: TObject);
var
    Down : boolean;
begin
    Down := not Editor.FreeStripsVisible;
    Editor.FreeStripsVisible := Down;
    Editor.EndDrawSequence;
end;



// ****************************************
// *** TOOLBUTTON COMPONENT TEXT CLICKS ***
// ****************************************

procedure TMainForm.NoTextTToolButtonClick(Sender: TObject);
begin
    Editor.TextDisplay := tdNone;
    Editor.Refresh;
end;

procedure TMainForm.ValuesTToolButtonClick(Sender: TObject);
begin
    Editor.TextDisplay := tdValue;
    Editor.Refresh;
end;

procedure TMainForm.DesignatorsTToolButtonClick(Sender: TObject);
begin
    Editor.TextDisplay := tdDesignator;
    Editor.Refresh;
end;

// ****************************************
//  ***     PROJECT MENU ITEMS          ***
// ****************************************

procedure TMainForm.Board1Click(Sender: TObject);
var
    BoardSettingsForm : TBoardSettingsForm;
begin
    BoardSettingsForm := TBoardSettingsForm.Create(self);
    try
        BoardSettingsForm.Project := Project;
        BoardSettingsForm.ShowModal;
    finally
        BoardSettingsForm.Free;
        Editor.Project := Project;
        Editor.Refresh;
    end;
    Editor.Dirty := True;
end;


procedure TMainForm.Strips1Click(Sender: TObject);
var
    BoardPatternForm : TBoardPatternForm;
begin
    BoardPatternForm := TBoardPatternForm.Create(self);
    try
        BoardPatternForm.Project := Project;
        BoardPatternForm.ShowModal;
    finally
        BoardPatternForm.Free;
    end;
    Editor.Dirty := True;
    Editor.Paint;
end;


procedure TMainForm.Outlines1Click(Sender: TObject);
var
    OutlineSettingsForm  : TOutlineSettingsForm;
begin
    OutlineSettingsForm  := TOutlineSettingsForm.Create(self);
    try
        OutlineSettingsForm.Project := Project;
        OutlineSettingsForm.ShowModal;
    finally
        OutlineSettingsForm.Free;
        Editor.Project := Project;
        Editor.Refresh;
    end;
end;

procedure TMainForm.Items1Click(Sender: TObject);
var
    BoardItemSettingsForm : TBoardItemSettingsForm;
begin
    BoardItemSettingsForm := TBoardItemSettingsForm.Create(self);
    try
        BoardItemSettingsForm.Project := Project;
        BoardItemSettingsForm.ShowModal;
    finally
        BoardItemSettingsForm.Free;
        Editor.Project := Project;
        Editor.Refresh;
    end;
end;

procedure TMainForm.Materials1Click(Sender: TObject);
begin
    MaterialsForm.Show;
    MaterialsForm.UpdateInfo;
end;

procedure TMainForm.Notes1Click(Sender: TObject);
begin
//    NotesForm.Parent := nil;
    NotesForm.Show;
end;

// ****************************************
//  ***        EDIT MENU ITEMS          ***
// ****************************************

procedure TMainForm.Undo1Click(Sender: TObject);
begin
    Editor.Undo;
end;

procedure TMainForm.Redo1Click(Sender: TObject);
begin
    Editor.Redo
end;

procedure TMainForm.Copy1Click(Sender: TObject);
begin
    Editor.CopyComponents;
end;

procedure TMainForm.Paste1Click(Sender: TObject);
begin
    Editor.PasteComponents;
end;

procedure TMainForm.PastewithDuplicates1Click(Sender: TObject);
begin
    Editor.PasteComponentsWithDuplicateIdentifiers;
end;

procedure TMainForm.Delete1Click(Sender: TObject);
begin
    Editor.DeleteSelectedItems;
end;

procedure TMainForm.CopyGraphic1Click(Sender: TObject);
begin
    Screen.Cursor := crHourGlass;
    try
        CopyGraphicToClipboard( Editor );
    finally
        Screen.Cursor := crDefault;
    end;
end;

procedure TMainForm.Find1Click(Sender: TObject);
var
    SelectItemForm: TSelectItemForm;
begin
    SelectItemForm := TSelectItemForm.Create(self);
    try
        SelectItemForm.Editor := Editor;
        SelectItemForm.ShowModal;
    finally
        SelectItemForm.Free;
    end;
end;

procedure TMainForm.ArrangeComponents1Click(Sender: TObject);
begin
    PlaceComponents( Project );
    Editor.Refresh;
end;

procedure TMainForm.Preferences1Click(Sender: TObject);
var
    SettingsForm : TSettingsForm;
begin
    SettingsForm := TSettingsForm.Create(self);
    try
        SettingsForm.Editor := Editor;
        SettingsForm.ShowModal;
    finally
        SettingsForm.Free;
    end;
    // reflect any display changes
    Editor.Refresh;
end;


// ****************************************
//  ***        NETLIST MENU ITEMS          ***
// ****************************************

procedure TMainForm.NetlistViewClick(Sender: TObject);
begin
    NetlistForm1.Show;
    NetlistForm1.UpdateInfo;
end;

procedure TMainForm.NetlistImportClick(Sender: TObject);
begin
    ImportNetlist( Project, FileMenuHandler.FileName );
    Editor.Project := Project;
    Editor.Refresh;
end;

procedure TMainForm.Clear1Click(Sender: TObject);
begin
  NetListClear( Project );
end;


procedure TMainForm.ExportNet1Click(Sender: TObject);
begin
    NetlistExport( Project, FileMenuHandler.FileName );
end;


procedure TMainForm.NetlistColorsClick(Sender: TObject);
var
    ColorNetLinkForm :  TColorNetLinkForm;
begin
    ColorNetLinkForm := TColorNetLinkForm.Create(self);
    try
        ColorNetLinkForm.Editor := Editor;
        ColorNetLinkForm.ShowModal;
    finally
        ColorNetLinkForm.Free;
    end;
    Editor.Dirty := True;
    Editor.Refresh;
end;

procedure TMainForm.MakeFromlayout1Click(Sender: TObject);
begin
    NetlistGenerate( Project );
end;

// ****************************************
//  ***        HELP MENU ITEMS          ***
// ****************************************

procedure TMainForm.Contents1Click(Sender: TObject);
begin
    Application.HelpShowTableOfContents;
end;

procedure TMainForm.About1Click(Sender: TObject);
var
    About : TAboutForm;
begin
    About := TAboutForm.Create(self);
    try
        About.ShowModal;
    finally
        About.Free;
    end;
end;

procedure TMainForm.CheckforUpdates1Click(Sender: TObject);
begin
    GetVeeCADUpdate;
end;

procedure TMainForm.VeeCADWebsite1Click(Sender: TObject);
begin
    ToVeeCADWebsite;
end;

// ****************************************
// ***           Router MENU            ***
// ****************************************

procedure TMainForm.PlaceBreaksClick(Sender: TObject);
begin
    AddBreaks( Editor.Project );
    Editor.Refresh;
end;


procedure TMainForm.PlaceLinksClick(Sender: TObject);
begin
    Screen.Cursor := crHourGlass;
    try
        LinkAll( Editor.Project );
        Editor.Refresh;
    finally
        Screen.Cursor := crDefault;
    end;
end;

procedure TMainForm.PlaceLeadedComponentsClick(Sender: TObject);
begin
    PlaceLeadedItems( Editor.Project );
    Editor.Refresh;
end;

procedure TMainForm.PlaceSelectedNetLinksClick(Sender: TObject);
begin
    LinkSelectedNet( Editor.Project );
    Editor.Refresh;
end;

procedure TMainForm.N5SelectedLeadedItems1Click(Sender: TObject);
begin
    PlaceSelectedLeadedItems( Editor.Project );
    Editor.Refresh;
end;


procedure TMainForm.PlaceSelectedLeadedItemClick(Sender: TObject);
begin
//    RouteLeaded.PlaceLeadedItemSelected( Editor.Project );
    Editor.Refresh;
end;


procedure TMainForm.FullAutoroute1Click(Sender: TObject);
begin
    Screen.Cursor := crHourGlass;
    try
        FullAutoRoute( Editor.Project );
        Editor.Refresh;
    finally
        Screen.Cursor := crDefault;
    end;
end;

// ****************************************
//          *** SELECT MENU ***
// ****************************************

procedure TMainForm.All3Click(Sender: TObject);
begin
    SelectAll( Editor.Project );
    Editor.Refresh;
end;

procedure TMainForm.InvertSelection1Click(Sender: TObject);
begin
    InvertSelection( Editor.Project );
    Editor.Refresh;
end;

// ****************************************
//          *** SELECT Links MENU ***
// ****************************************


procedure TMainForm.All1Click(Sender: TObject);
begin
    SelectLinks( Editor.Project );
    Editor.Refresh;
end;

procedure TMainForm.InSelection1Click(Sender: TObject);
begin
    SelectLinksInSelection( Editor.Project );
    Editor.Refresh;
end;

procedure TMainForm.Redundant1Click(Sender: TObject);
begin
    SelectShortedLinks( Editor.Project );
    Editor.Refresh;
end;

// ****************************************
//          *** SELECT Breaks MENU ***
// ****************************************

procedure TMainForm.All2Click(Sender: TObject);
begin
    SelectBreaks( Editor.Project );
    Editor.Refresh;
end;

procedure TMainForm.InSelection2Click(Sender: TObject);
begin
    SelectbreaksInSelection( Editor.Project );
    Editor.Refresh;
end;

procedure TMainForm.Redundant2Click(Sender: TObject);
begin
    SelectUnusedBreaks( Editor.Project );
    Editor.Refresh;
end;

// ****************************************
//          *** SELECT Groups MENU ***
// ****************************************

procedure TMainForm.GroupSelection1Click(Sender: TObject);
begin
    Editor.GroupSelected;
end;

procedure TMainForm.UnGroupSelection1Click(Sender: TObject);
begin
    Editor.UnGroupSelected;
end;

// ****************************************
// ***  Select Unused Components MENU   ***
// ****************************************

procedure TMainForm.ComponentsNotRequired1Click(Sender: TObject);
begin
    SelectUnusedComponents( Editor.Project );
    Editor.Refresh;
end;

// ****************************************
//          ***   Tools MENU   ***
// ****************************************

procedure TMainForm.MakeLibraryLayout1Click(Sender: TObject);
begin
    MakeLibraryLayout( Editor.Project );
    Editor.Refresh;
end;

procedure TMainForm.TrackEditor1Click(Sender: TObject);
var
    TrackEditForm : TTrackEditForm;
begin
    TrackEditForm := TTrackEditForm.Create( Self );
    try
        TrackEditForm.Board := Project.Board;
        TrackEditForm.ShowModal;
        if TrackEditForm.Dirty then begin
            Editor.Dirty := True;
        end;
    finally
        TrackEditForm.Free;
    end;
    Editor.Refresh;
end;

procedure TMainForm.TrackCutsClick(Sender: TObject);
var
    GcodeForm : TGcodeForm;
begin
    // show G-Code to user
    GcodeForm := TGcodeForm.Create( self );
    try
        GcodeForm.ReportType := rptTrackCuts;
        GCodeForm.Project := Project;
        GCodeForm.ProjectFileName := FileMenuHandler.FileName;
        GcodeForm.ShowModal;
    finally
        GcodeForm.Free;
    end;
end;


procedure TMainForm.Links_ComponentsClick(Sender: TObject);
var
    GcodeForm : TGcodeForm;
begin
    // show G-Code to user
    GcodeForm := TGcodeForm.Create( self );
    try
        GcodeForm.ReportType := rptTopOutlines;
        GCodeForm.Project := Project;
        GCodeForm.ProjectFileName := FileMenuHandler.FileName;
        GcodeForm.ShowModal;
    finally
        GcodeForm.Free;
    end;
end;

// ****************************************
//  ***   Temp Development / Debug Code ***
// ****************************************

end.



