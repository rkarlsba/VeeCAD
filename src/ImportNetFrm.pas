unit ImportNetFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, CheckLst, Buttons,
  Project, NetImporter, ExtCtrls, ExceptSafe;

type EImportNetForm = class( Exception );
type ESafeImportNetForm = class( ESafe );

type
  TImportNetForm = class(TForm)
    Panel1: TPanel;
    ImportTButton: TButton;
    CloseTButton: TButton;
    Panel2: TPanel;
    Panel3: TPanel;
    LibListTCheckListBox: TCheckListBox;
    LibMoveDownTBitBtn: TBitBtn;
    LibMoveUpTBitBtn: TBitBtn;
    LibAddTButton: TButton;
    LibDeleteTButton: TButton;
    Panel4: TPanel;
    FormatTComboBox: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    FilenameTEdit: TEdit;
    SelectFileNameTButton: TButton;
    Label3: TLabel;
    procedure ImportTButtonAClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SelectFileNameTButtonAClick(Sender: TObject);
    procedure LibMoveUpTBitBtnAClick(Sender: TObject);
    procedure LibMoveDownTBitBtnAClick(Sender: TObject);
    procedure LibAddTButtonAClick(Sender: TObject);
    procedure LibDeleteTButtonAClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormatTComboBoxAChange(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    FProject : TveProject;
    FProjectFileName : string;

    // hi level
    procedure LoadSettings;
    procedure SaveSettings;
    procedure UpdateDefaultNetName;
    procedure LoadLibraries( NetImporter : TveNetImporter );

    // low level
    function LibSelectedItemIndex : integer;
  public
    { Public declarations }
    LastUsedFormat : string;

    property ProjectFileName : string read FProjectFileName write FProjectFileName;
    property Project : TveProject read FProject write FProject;
    procedure Execute;
  public
    { Public declarations }
  end;

var
  ImportNetForm: TImportNetForm;

implementation

{$R *.DFM}

uses
    Registry, Globals,
    NetReader, ProjectInput,
    NetReaderProtelTango, NetReaderEasyPC, NetReaderWirelist, NetReaderOrcadPCB2
    {NetReaderKiCad}, NetReaderUltiCap, NetReaderCrododilePhysics,
    NetReaderSeetrax, NetReaderZenit, Placement, DebugFrm;

//type TKicadNetReader = class( TveNetReader )

// **********************************************
//        DATA FOR SUPPORTED NETLIST FORMATS
// **********************************************

type TNetFormat =
(
nfProtel,
nfTango,
//nfKicad,
nfOrcadPCB2,
nfEasyPCGeneric,
nfWirelist,
nfUltiCapDOS,
nfUltiCapWin,
nfCrocodilePhysics,
nfSeetrax,
nfZenit1p0
);

const FileExtensions : array[TNetFormat] of string =
(
'net',
'net',
//'net',
'net',
'net',
'net',
'net',
'nt0',
'cir',
'net',
'net'
);

const IniFileNetNames : array[TNetFormat] of string =
(
'Protel',
'Tango',
//'Kicad',
'OrcadPCB2',
'EasyPCGeneric',
'Wirelist',
'UltiCap_DOS',
'UltiCap_Win',
'Crocodile Physics',
'Seetrax',
'Zenit1.0'
);

const ProjectFileNetFormats : array[TNetFormat] of string =
(
'Protel',
'Tango',
//'Kicad',
'OrcadPCB2',
'EasyPCGeneric',
'Wirelist',
'UltiCap_DOS',
'UltiCap_Win',
'CrocodilePhysics',
'Seetrax',
'Zenit1.0'
);

const UserDisplayNetFormats : array[TNetFormat] of string =
(
'Protel',
'Tango',
//'Kicad',
'Orcad PCB2',
'Easy-PC Generic',
'Wirelist',
'UltiCap DOS with matching CMP file',
'UltiCap Windows with matching CMP file',
'Crocodile Physics',
'Seetrax Legacy: NET with matching CMP file',
'Zenit Capture'
);


const Filters : array[TNetFormat] of string =
(
'Protel Netlist Files (*.net)|*.NET|All Files (*.*)|*.*',
'Tango Netlist Files (*.net)|*.NET|All Files (*.*)|*.*',
//'Kicad Netlist Files (*.net)|*.NET|All Files (*.*)|*.*',
'Orcad PCB2 Netlist Files (*.net)|*.NET|All Files (*.*)|*.*',
'Easy-PC Generic Net Files (*.net)|*.NET|All Files (*.*)|*.*',
'Wirelist Files (*.net)|*.NET|All Files (*.*)|*.*',
'UltiCap DOS Net Files (*.net)|*.NET|All Files (*.*)|*.*',
'UltiCap Win Net Files (*.nt0)|*.NT0|All Files (*.*)|*.*',
'Crocodile Physics Net Files (*.cir)|*.CIR|All Files (*.*)|*.*',
'Seetrax Net Fiiles (*.net)|*.NET|All Files (*.*)|*.*',
'Zenit Capture Net Fiiles (*.net)|*.NET|All Files (*.*)|*.*'
);


procedure TImportNetForm.Execute;
begin
    ShowModal;
end;

// **********************************************
//          SETUP FORM BEFORE USE
// **********************************************

procedure TImportNetForm.FormShow(Sender: TObject);
var
    FoundFormat : boolean;
    ProjectFormat : string;

    Format : string;
    i : TNetFormat;
begin
    // Load from Registry etc
    LoadSettings;

    // load combobox with list of net formats
    FormatTComboBox.Items.Clear;
    for i := Low( TNetFormat ) to High( TNetFormat ) do begin
        FormatTComboBox.Items.Add( UserDisplayNetFormats[i] );
    end;


    FoundFormat := False;

    // find last loaded Net Format from Project File
    ProjectFormat := FProject.NetlistImportFormat;
    for i := low( TNetFormat ) to high( TNetFormat ) do begin
        if ProjectFormat = ProjectFileNetFormats[i] then begin
            FormatTComboBox.ItemIndex := Ord( i );
            FoundFormat := True;
        end;
    end;

    // if no net Format in project file, use last loaded Net Format from Registry
    if not FoundFormat then begin

        Format := LastUsedFormat;

        FormatTComboBox.ItemIndex := 0;
        for i := low( TNetFormat ) to high( TNetFormat ) do begin
            if Format = IniFileNetNames[i] then begin
                FormatTComboBox.ItemIndex := Ord( i );
                FoundFormat := True;
            end;
        end;
    end;

    // otherwise, default to Protel net format
    if not FoundFormat then begin
        FormatTComboBox.ItemIndex := Ord(nfProtel);
    end;

    UpdateDefaultNetname;
end;

procedure TImportNetForm.UpdateDefaultNetName;
begin
    // Generate filename from Project filename plus extension for
    // netlist file format displayed in Format combobox.
    FileNameTEdit.Text :=
        Copy(
            FProjectFileName, 1,
            Length(FProjectFileName) - Length( ExtractFileExt(FProjectFileName) )
        )
        + '.'
        + FileExtensions[TNetFormat(FormatTComboBox.ItemIndex)];
end;

// **********************************************
//         USER SELECTS NETLIST FORMAT
// **********************************************

{
Do we want default netlist to be regenerated every time we change netlist format ?
} 

procedure TImportNetForm.FormatTComboBoxAChange(Sender: TObject);
begin
    UpdateDefaultNetName;
end;


// **********************************************
//         USER SELECTS NETLIST FILENAME
// **********************************************

procedure TImportNetForm.SelectFileNameTButtonAClick(Sender: TObject);
var
    NetFormat : TNetFormat;
    FileName : string;
    OpenDialog : TOpenDialog;
begin
    NetFormat := TNetFormat( FormatTComboBox.ItemIndex );

    FileName := FileNameTEdit.Text;

    OpenDialog := TOpenDialog.Create(nil);
    try
        OpenDialog.FileName := ExtractFileName( FileName );
        OpenDialog.InitialDir := ExtractFilePath( FileName );

        OpenDialog.DefaultExt := FileExtensions[ NetFormat ];
        OpenDialog.Filter := Filters[ NetFormat ];
        OpenDialog.Options := [ofEnableSizing, ofFileMustExist, ofHideReadOnly];

        if not OpenDialog.Execute then begin
            exit;
        end;
        FileName := OpenDialog.FileName;
    finally
        OpenDialog.Free;
    end;

    FileNameTEdit.Text := FileName;
end;


// **********************************************
//          PROCEED WITH IMPORT
// **********************************************

procedure TImportNetForm.ImportTButtonAClick(Sender: TObject);
var
    Filename : string;
    NetFormat : TNetFormat;
    NetReader : TveNetReader;
    NetImporter : TveNetImporter;
    OriginalItemCount : integer;
begin



    Filename := FileNameTEdit.Text;

    // file must exist
    if not FileExists( FileName ) then begin
        ShowMessage( Format( 'File not found: %s', [FileName] ) );
        exit;
    end;

    // At this point, we don't want any complications.
    // Actually, Undo should be OK, because import only creates
    // new Items and Outlines, never deletes old.  However, it
    // complicates things for user if undo continues.
    FProject.ClearUndo;

    // record # of items on the board before we create new components
    OriginalItemCount := FProject.BoardItemCount;

    // get net format selected by user
    NetFormat := TNetFormat(FormatTComboBox.ItemIndex);

    // load file into appropriate netreader
    case NetFormat of
        nfProtel : NetReader := TProtelNetReader.Create;
        nfTango : NetReader := TTangoNetReader.Create;
//        nfKicad : NetReader := TKicadNetReader.Create;
        nfOrcadPCB2 : NetReader := TOrcadPCB2NetReader.Create;
        nfEasyPCGeneric : NetReader := TEasyPCNetReader.Create;
        nfWirelist : NetReader := TWirelistNetReader.Create;
        nfUltiCapDOS : NetReader := TUlticapDOSNetReader.Create;
        nfUltiCapWin : NetReader := TUlticapWinNetReader.Create;
        nfCrocodilePhysics : NetReader := TCrododilePhysicsNetReader.Create;
        nfSeetrax : NetReader := TSeetraxNetReader.Create;
        nfZenit1p0 : NetReader := TZenitNetReader.Create;
        else begin
            exit;
        end;
    end;
    try
        NetReader.ReadFile( FileName );

        // attach to netImporter
        NetImporter := TveNetImporter.Create;
        try
            NetImporter.Project := FProject;
            LoadLibraries( NetImporter );
            NetImporter.NetReader := NetReader;
            NetImporter.Execute;
        finally
            NetImporter.Free;
        end;

    finally
        NetReader.Free;
    end;

    // place components
    if OriginalItemCount = 0 then begin
        PlaceComponents( FProject );
        FProject.ClearUndo;
    end;

    // close this form
    ModalResult := mrOK;
end;



// **********************************************
//         LOAD AND STORE LATEST SETTINGS
// **********************************************

// fill library list from INI file
// check off libraries in project file which match library list
// if not all libraries can be matched, record this fact.

// up to this many libraries
const LibCount = 15;

procedure TImportNetForm.SaveSettings;
const
    Bool2Str : array[boolean] of string = ('0', '1');
var
    IniFile : TRegIniFile;

    ListedLibCount : integer;
    i : integer;
    Checked : boolean;
    LibFile : string;
begin

    IniFile := GetRegIniFile;
    try
        // ** save last used net format **
        IniFile.WriteString( 'Import', 'NetFormat', IniFileNetNames[TNetFormat(FormatTComboBox.ItemIndex)] );

        // ** save libraries **
        ListedLibCount := LibListTCheckListBox.Items.Count;
        for i := 0 to LibCount -1 do begin

            // in the library listbox
            if i < ListedLibCount then begin

                Checked := LibListTCheckListBox.Checked[i];
                LibFile := LibListTCheckListBox.Items[i];
                IniFile.WriteString( 'Import', 'Lib' + IntToStr(i),
                    Bool2Str[Checked]+ ',' + Libfile );
            end
            // not in the library listbox
            else begin
                IniFile.WriteString( 'Import', 'Lib' + IntToStr(i), '' );
            end;
        end;
    finally
        IniFile.Free;
    end;
end;

{$HINTS OFF}

procedure TImportNetForm.LoadSettings;
var
    IniFile : TRegIniFile;

    i : integer;
    LibText : string;
    Checked : boolean;
    LibFile : string;
begin
    IniFile := GetRegIniFile;
    try
        // ** load last used net format **
        LastUsedFormat := IniFile.ReadString( 'Import', 'NetFormat', '' );
        // ** load libraries **
        Checked := False;       // stop compiler warning "uninitialised varible"
        LibListTCheckListBox.Items.Clear;

        for i := 0 to LibCount -1 do begin

            // read registry key like "Lib0" or "Lib1" etc
            // value will be a string like "0,C:\CAD\Libs\VCadStdLib.per"
            LibText := IniFile.ReadString( 'Import', 'Lib' + IntToStr(i), '' );

            // ignore short strings or string when 2nd char is not a comma
            if (length(LibText) < 2) or (LibText[2] <> ',') then begin
                continue;
            end;

            // first character is 0 or 1 and represents "checked"
            if LibText[1] = '0' then begin
                Checked := False;
            end
            else if LibText[1] = '1' then begin
                Checked := True;
            end
            else begin
                // rubbish, so skip this reg entry
                continue;
            end;

            // remainder of string after comma is library path
            LibFile := Copy( LibText, 3, 255 );

            // add to library checkbox
            LibListTCheckListBox.Items.Add( LibFile );
            LibListTCheckListBox.Checked[LibListTCheckListBox.Items.Count -1] :=
                Checked;
        end;
    finally
        IniFile.Free;
    end;
end;

{$HINTS ON}


// **********************************************
//         USER MANIPULATES LIBRARY LIST
// **********************************************

(*
issues :

NETLIST FORMAT
==============

options :
- last used read from registry.
- stored in .PER file : then must be copied to TPerfProject
- project filename and net format pairs are stored in registry.

Importer must validate file format before loading components and nets.  Each
TNetReader descendant must have a CheckType function which decides if file
looks like correct type.


IMPORT FILENAME
===============

Always the project filename plus extension appropriate for the netlist format.

*)
// ** find selected item in Library List **
function TImportNetForm.LibSelectedItemIndex : integer;
var
    i : integer;
begin
    for i := 0 to LibListTCheckListBox.Items.Count -1 do begin
        if LibListTCheckListBox.Selected[i] then begin
            result := i;
            exit;
        end;
    end;

    // nothing selected
    result := -1;
end;


// ** move selected library up in list **
procedure TImportNetForm.LibMoveUpTBitBtnAClick(Sender: TObject);
var
    SelectedIndex : integer;

begin
    // find current item
    SelectedIndex := LibSelectedItemIndex;
    if SelectedIndex < 0 then begin
        exit;
    end;

    // we can't move up if we are already at the top
    if SelectedIndex <= 0 then begin
        exit;
    end;

    // move item up one
    // exchange provokes a bug in the TChecklistbox causes crash at program
    // shutdown or a memory leak
//    LibListTCheckListBox.Items.Exchange( SelectedIndex, SelectedIndex -1 );

    // so insert in new position, transfer the item checked value then delete
    LibListTCheckListBox.Items.Insert(
        SelectedIndex -1,  LibListTCheckListBox.Items[SelectedIndex]);
    LibListTCheckListBox.Checked[SelectedIndex -1] :=
        LibListTCheckListBox.Checked[SelectedIndex + 1];
    LibListTCheckListBox.Items.Delete( SelectedIndex + 1);

    // set highlight to the new position
//    LibListTCheckListBox.Selected[SelectedIndex -1] := True;
    LibListTCheckListBox.ItemIndex := SelectedIndex -1;
end;

// ** move selected library down in list **
procedure TImportNetForm.LibMoveDownTBitBtnAClick(Sender: TObject);
var
    SelectedIndex : integer;
begin
    // find current item
    SelectedIndex := LibSelectedItemIndex;

    // nothing selected ?
    if SelectedIndex < 0 then begin
        exit;
    end;

    // we can't move down if we are already at the bottom
    if SelectedIndex >= LibListTCheckListBox.Items.Count -1 then begin
        exit;
    end;

    // move item below up one  (same as moving the desired item down one)

    // .. insert in new position, transfer the item checked value then delete
    LibListTCheckListBox.Items.Insert(
        SelectedIndex,  LibListTCheckListBox.Items[SelectedIndex +1]);
    LibListTCheckListBox.Checked[SelectedIndex] :=
        LibListTCheckListBox.Checked[SelectedIndex + 2];
    LibListTCheckListBox.Items.Delete( SelectedIndex + 2);

    // set highlight to the new position
    LibListTCheckListBox.ItemIndex := SelectedIndex +1;
end;

// ** add a library to the list **
procedure TImportNetForm.LibAddTButtonAClick(Sender: TObject);
var
    SelectedLibIndex : integer;
    ExistingLibFileName : string;

    OpenDialog : TOpenDialog;
    FileName : string;
  i: Integer;
begin
    // ** Get a Sensible Initial Path for Library File **

    // use path of library selected in listbox
    SelectedLibIndex := LibSelectedItemIndex;
    if SelectedLibIndex >= 0 then begin
        ExistingLibFileName := LibListTCheckListBox.Items[ SelectedLibIndex ];
    end
    // no selected item, so try for first
    else if LibListTCheckListBox.Items.Count > 0 then begin
        ExistingLibFileName := LibListTCheckListBox.Items[0];
    end
    // nothing at all in list, so leave it blank (add something smarter here later)
    else begin
    end;

    // ** Show Open Dialog and Get User to Select File **

    OpenDialog := TOpenDialog.Create(nil);
    try
        OpenDialog.Title := 'Select Library File';
        OpenDialog.InitialDir := ExtractFilePath( ExistingLibFileName );
        OpenDialog.DefaultExt := 'per';
        OpenDialog.Filter :=
            'VeeCAD files (*.per}|*.per|All files (*.*)|*.*';
        OpenDialog.Options :=
            [ofEnableSizing, ofFileMustExist, ofHideReadOnly, ofAllowMultiSelect];

        if not OpenDialog.Execute then begin
            exit;
        end;

        // add files to list
        for i := 0 to OpenDialog.Files.Count - 1 do begin
            FileName := OpenDialog.Files[i];
            // add to list if filename not already in list
            if LibListTCheckListBox.Items.IndexOf( FileName ) = -1 then begin
                LibListTCheckListBox.Items.Add( OpenDialog.Files[i] );
            end;
        end;

    finally
        OpenDialog.Free;
    end;
end;


// ** delete a library from the list **
procedure TImportNetForm.LibDeleteTButtonAClick(Sender: TObject);
var
    SelectedLibIndex : integer;
    ItemCount : integer;
begin
    // use path of library selected in listbox
    SelectedLibIndex := LibSelectedItemIndex;
    if SelectedLibIndex >= 0 then begin
        LibListTCheckListBox.Items.Delete( SelectedLibIndex );

        // number of lines in listbox
        ItemCount := LibListTCheckListBox.Items.Count;

        // if we have some lines left to move selection to
        if ItemCount > 0 then begin


            // try to set selection to same item index (ie list moves up and highlight
            // stays in same line position
            if (SelectedLibIndex < ItemCount) then begin
                LibListTCheckListBox.ItemIndex := SelectedLibIndex;
            end

            // not enough items to keep index same, so move it one up
            else begin
                LibListTCheckListBox.ItemIndex := SelectedLibIndex -1;
            end;

        end;
    end;
end;


// **********************************************
//         LOAD LIBRARIES FROM FILE
// **********************************************

// Create all libraries and load into NetImporter.
// An exception can be raised by this function if a library will not load
// in this case some libraries can have been added to the NetImporter.  When
// the NetImporter is destroyed it will destroy those libraries.

procedure TImportNetForm.LoadLibraries( NetImporter : TveNetImporter );
var
    i : integer;
    LibFileName : string;

    Loader : TProjectInputLoader;
    Lib : TveProject;
begin
    // test that all checked libraries exist
    for i := 0 to LibListTCheckListBox.Items.Count -1 do begin

        // ignore unchecked entries in libraries listbox
        if not LibListTCheckListBox.Checked[i] then begin
            continue;
        end;

        // make sure library file exists
        LibFileName := LibListTCheckListBox.Items[i];

        if not FileExists( LibFileName ) then begin
            raise ESafeImportNetForm.CreateFmt(
                'Cannot find Library file: %s', [LibFileName]
            );
        end;
    end;


    // load libraries
    for i := 0 to LibListTCheckListBox.Items.Count -1 do begin

        // ignore unchecked entries in libraries listbox
        if not LibListTCheckListBox.Checked[i] then begin
            continue;
        end;

        // make the project and give it to the NetImporter
        Lib := TveProject.Create;
        NetImporter.AddLibrary( Lib );

        // make the loader and read the file with it
        Loader := TProjectInputLoader.Create( Lib );
        try
            LibFileName := LibListTCheckListBox.Items[i];
            Loader.LoadFromFile( LibFileName );
        except
            // add some info to exceptions that do not require VeeCAD to close
            on E : ESafe do begin
                Loader.Free;
                raise ESafeImportNetForm.Create( 'Error loading library. ' + E.Message );
            end;
            // let all other exceptions go through and close VeeCAD
        end;
        Loader.Free;
    end;
end;

procedure TImportNetForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
    // always save settings, even if no import took place
    SaveSettings;
end;


procedure TImportNetForm.FormResize(Sender: TObject);
var
    ButtonWidth : integer;
    Centre : integer;
begin
    // centre import and close buttons
    ButtonWidth := CloseTButton.Width;
    Centre := Panel1.Width div 2;

    ImportTButton.Left := Centre - ((ButtonWidth * 3) div 2);
    CloseTButton.Left := Centre + (ButtonWidth div 2);
end;

{
FIRST RELEASE
=============

For a start, we only store library settings in the registry.  Laster we might
want to also store last used librariy filename+path in the project, but that
will need extra work when we run the project on another machine.
}

end.




