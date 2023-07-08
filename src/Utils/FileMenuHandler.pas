unit FileMenuHandler;

interface

uses Classes, Menus, SysUtils;

type
    TFileMenu = ( emSave, emSaveAs );
    TFileMenus = set of TFileMenu;
    TFileMenuStatusEvent = procedure( Sender : TObject; ActiveMenus : TFileMenus ) of object;
    TProcessFileEvent = procedure(
        Sender : TObject; const FileName : string; var Done : boolean ) of object;
    EFileMenu = class( Exception );

type TFileMenuHandler = class

    protected
        FMenu : TMainMenu;
        FFileMenu : TMenuItem;
        FNewMenu : TMenuItem;
        FOpenMenu : TMenuItem;
        FSaveMenu : TMenuItem;
        FSaveAsMenu : TMenuItem;
        FExitMenu : TMenuItem;
        FSeparator : TMenuItem;

        // vars track most recently used file list
        RecentFiles : TStringList;
        FMaxRecentFiles : integer;

        // vars exposed thru properties define how to manage file
        FHKEY_CURRENT_USER_key : string;
        FFileExtension : string;
        FFileFilter : string;
        FDocAlwaysOpen : boolean;

        // variables track file status
        FFileName : string;
        FActiveDocument : boolean;
        FDirty : boolean;

        // event handlers provided as properties
        FOnFileRead : TProcessFileEvent;
        FOnFileWrite : TProcessFileEvent;
        FOnFileNew :TProcessFileEvent;
        FOnFileClose : TProcessFileEvent;
        FOnChangeFileName : TNotifyEvent;
        FOnExit : TNotifyEvent;

        // property setters, getters
        procedure SetMenu( Menu : TMainMenu );
        procedure SetFileName( Value : string );
        procedure SetKey( const Value : string );
        function GetRecentFilesCount : integer;

        // internal
        function ReleaseFile : boolean;
        procedure UpdateMenus;
        procedure AddMenuItem( var Item : TMenuItem;
          const Caption : string; Handler : TNotifyEvent; GroupIndex : integer );

        procedure DisplayRecentFiles;
        procedure IncludeRecentFile( const FileName : string );
        procedure LimitRecentFileCount;

        // internal event handlers called by MenuItems when clicked
        procedure MenuNew(Sender: TObject);
        procedure MenuOpen(Sender: TObject);
        procedure MenuSave(Sender: TObject);
        procedure MenuSaveAs(Sender: TObject);
        procedure MenuCloseFile(Sender: TObject);
        procedure MenuExit(Sender : TObject);
        procedure MenuRecentFile(Sender : TObject);

    public
//        property IniFileName : string read FIniFileName write FIniFileName;
//        property IniSection : string read FIniSection write FIniSection;

        property HKEY_CURRENT_USER_key : string
            read FHKEY_CURRENT_USER_key write SetKey;

        property FileExtension : string read FFileExtension write FFileExtension;
        property FileFilter : string read FFileFilter write FFileFilter;

        property FileName : string read FFileName;
        property ActiveDocument : boolean read FActiveDocument;
        property MaxRecentFiles : integer read FMaxRecentFiles write FMaxRecentFiles;
        property RecentFilesCount : integer read GetRecentFilesCount;

        // important : set to True if closing a file causes a fresh, empty doc
        // to be left for use on screen.  If false, means no doc or disabled
        // empty doc is left on screen.
        property DocAlwaysOpen : boolean read FDocAlwaysOpen write FDocAlwaysOpen;

        property OnFileRead : TProcessFileEvent
            read FOnFileRead write FOnFileRead;
        property OnFileWrite : TProcessFileEvent
            read FOnFileWrite write FOnFileWrite;
        property OnFileNew : TProcessFileEvent
            read FOnFileNew write FOnFileNew;
        property OnFileClose : TProcessFileEvent
            read FOnFileClose write FOnFileClose;
        property OnChangeFileName : TNotifyEvent
            read FOnChangeFileName write FOnChangeFileName;
        property OnExit : TNotifyEvent
            read FOnExit write FOnExit;

        property Menu : TMainMenu read FMenu write SetMenu;
        function InsertMenuItem( Index : integer;
            const Caption : string; Handler : TNotifyEvent ) : TMenuItem;

        procedure NewFile;
        procedure LoadFile( const FileName : string );
        procedure LoadMostRecentFile;
        function ExitFile : boolean;
        procedure NotifyDirty;


        constructor Create;
        destructor Destroy; override;
end;

implementation

uses Dialogs, Controls, Registry, Windows, Forms
{$IFNDEF VER200}, System.UITypes {$ENDIF} ;

const
    // number of most recent files to display on menu and save in registry
    // ie initial value of MaxRecentFiles property after constructor
    DEFAULT_MAX_RECENT_FILES = 4;

function TFileMenuHandler.InsertMenuItem( Index : integer;
    const Caption : string; Handler : TNotifyEvent ) : TMenuItem;
begin
    result := TMenuItem.Create( FMenu.Owner );
    result.Caption := Caption;
    result.OnClick := Handler;
    FFileMenu.Insert( Index, result );
end;

procedure TFileMenuHandler.AddMenuItem( var Item : TMenuItem;
          const Caption : string; Handler : TNotifyEvent; GroupIndex : integer );
begin
    Item := TMenuItem.Create( FMenu.Owner );
    Item.Caption := Caption;
    Item.OnClick := Handler;
    FFileMenu.Add( Item );
end;


procedure TFileMenuHandler.SetMenu( Menu : TMainMenu );
begin
    FMenu := Menu;

    // add FileMenu at left of menu bar
    FFileMenu := TMenuItem.Create( Menu.Owner );
    FFileMenu.Caption := '&File';
    FFileMenu.GroupIndex := 0;
    Menu.Items.Insert( 0, FFileMenu );

    // build items into File Menu
    AddMenuItem( FNewMenu, '&New', MenuNew, 10 );
    FNewMenu.ShortCut := ShortCut(Word('N'), [ssCtrl]);
    AddMenuItem( FOpenMenu, '&Open...', MenuOpen, 20 );
    FOpenMenu.ShortCut := ShortCut(Word('O'), [ssCtrl]);
    AddMenuItem( FSaveMenu, '&Save', MenuSave, 30 );
    FSaveMenu.ShortCut := ShortCut(Word('S'), [ssCtrl]);
    AddMenuItem( FSaveAsMenu, 'Save &As...', MenuSaveAs, 40 );
    AddMenuItem( FExitMenu, 'E&xit', MenuExit, 50 );
    FExitMenu.ShortCut := ShortCut(VK_F4, [ssAlt]);
    AddMenuItem( FSeparator, '-', nil, 60 );
    FSeparator.Visible := False;

    // set menus to initial state
    UpdateMenus;
end;


// ** Set FileName - Used Internally Only **

procedure TFileMenuHandler.SetFileName( Value : string );
begin
    FFileName := Value;
    if Assigned( FOnChangeFileName ) then begin
        FOnChangeFileName( self );
    end;
end;


// *** Get Rid Of Responsibility for Current File ***
// returns

function TFileMenuHandler.ReleaseFile : boolean;

    function Clear : boolean;
    begin
        result := False;
        // exception can occur here - never caught in TFileMenuHandler - OK
        // becuase ReleaseFile always called before anything serious done.
        FOnFileClose( Self, FileName, result );
        if result then begin
                FActiveDocument := FDocAlwaysOpen;
                FDirty := False;
                SetFileName( '' );
                // ... adjust Save, SaveAs menus
                UpdateMenus;
        end;
    end;

begin
    // assume we can't clear file - must play it safe
    result := False;

    // if no changes, dump existing document, if any
    if not FDirty then begin
        result := Clear;
        exit;
    end;

    // if document exists and dirty, but has no filename, then tell user
    if FFileName = '' then begin

        case MessageDlg('Save new work ?', mtConfirmation,
            [mbYes,mbNo,mbCancel], 0 ) of

            // save work
            mrYes : begin
                MenuSaveAs(nil);
                if FDirty then begin
                    exit;
                end;
                result := Clear;
            end;

            // don't save work
            mrNo : begin
                 result := Clear;
            end;

            // cancel save
            mrCancel : begin
                result := False;
            end;
        end;
    end

    // we have document with filename

    else begin

        case MessageDlg('Save changes ?', mtConfirmation,
            [mbYes,mbNo,mbCancel], 0 ) of

            // save work
            mrYes : begin
                MenuSave(nil);
                if FDirty then begin
                    exit;
                end;
                result := Clear;
            end;

            // don't save work
            mrNo : begin
                 result := Clear;
            end;

            // cancel save
            mrCancel : begin
                result := False;
            end;
        end;
    end;
end;

procedure TFileMenuHandler.MenuNew(Sender: TObject);
var
   Done : boolean;
begin
    if not ReleaseFile then begin
        exit;
    end;
    if Assigned( FOnFileNew ) then begin
        FActiveDocument := False;
        Done := False;
        // this line may cause exception
        FOnFileNew( self, '', Done );
        FActiveDocument := Done;
        FDirty := False;
    end;
    UpdateMenus;
end;

procedure TFileMenuHandler.MenuOpen(Sender: TObject);
var OpenDialog : TOpenDialog;
    FileName : string;
    RegIniFile : TRegIniFile;
begin
    // must have a way to read a file
    if not assigned( FOnFileRead ) then begin
        exit;
    end;
    // honourably dispose of any existing file
    if not ReleaseFile then begin
        exit;
    end;

    // get last opened filename from registry
    if FHKEY_CURRENT_USER_key <> '' then begin
        RegIniFile := TRegIniFile.Create( FHKEY_CURRENT_USER_key );
        try
           FileName := RegIniFile.ReadString( 'File', 'Open', '' );
        finally
            RegIniFile.Free;
        end;
    end;

    // get user to enter name for file to open
    OpenDialog := TOpenDialog.Create(nil);
    try
        OpenDialog.DefaultExt := FFileExtension;
        OpenDialog.FileName := ExtractFileName( FileName );
        OpenDialog.Filter := FFileFilter;
        OpenDialog.InitialDir := ExtractFilePath( FileName );
        OpenDialog.Title := 'Open File';
        OpenDialog.Options := [ofFileMustExist, ofEnableSizing, ofHideReadOnly];

        // user cancels FileOpen dialog.  We exit with FActiveDocument as
        // set by ReleaseFile
        if not OpenDialog.Execute then begin
            exit;
        end;
        FileName := OpenDialog.FileName;
     finally
        OpenDialog.Free;
    end;

    LoadFile( FileName );
end;

procedure TFileMenuHandler.LoadFile( const FileName : string );
var
   Done : boolean;
   RegIniFile : TRegIniFile;
begin
    // must have a way to read a file
    if not assigned( FOnFileRead ) then begin
        exit;
    end;
    // honourably dispose of any existing file
    if not ReleaseFile then begin
        exit;
    end;

(*
    FOnFileRead can do :

    1.  Raise an exception : we let exception propagate directly,
        leaving a doc or no doc, depending on whether ReleaseFile leaves
        an empty doc or no doc

    2.  Return with Done = False
        we set FDirty = False, FileName = '', FActiveDocument as set
            by ReleaseFile.

    3.  Return with Done = True
        we set FDirty = False, FFileName = FileName, FActiveDocuement = True
*)

     Screen.Cursor := crHourglass;
     try
         FOnFileRead( self, FileName, Done );
     finally
         Screen.Cursor := crDefault;
     end;

    // if document not read from file, leave as set by ReleaseFile()
    if not Done then begin
        exit;
    end;

    // doc loaded from file
    FActiveDocument := True;
    SetFileName( FileName );
    IncludeRecentFile( FileName );

    // save filename in Registry
    if FHKEY_CURRENT_USER_key <> '' then begin
        RegIniFile := TRegIniFile.Create( FHKEY_CURRENT_USER_key );
        try
           RegIniFile.WriteString( 'File', 'Open', FileName );
        finally
            RegIniFile.Free;
        end;
    end;

    UpdateMenus;
end;

procedure TFileMenuHandler.MenuSave(Sender: TObject);
var Done : boolean;
begin
    if (not FActiveDocument) or (not Assigned(FOnFileWrite)) or (not FDirty)
        then begin
        exit;
    end;
    if FileName = '' then begin
        MenuSaveAs(Sender);
        exit;
    end;

    // simple case is readonly file
    if (FileGetAttr( FileName ) and faReadOnly) <> 0 then begin
        raise EFileMenu.CreateFmt( 'File : %s is readonly', [FileName] );
    end;

    // Save to file
    Done := False;

    // ... if exception raised, re-brand it to our "brand" of exception and
    // leave variables changed as if no save had occurred, which is OK.
    try
        FOnFileWrite( self, FileName, Done );
    except
        // raise
        On E:Exception do begin
          raise EFileMenu.Create( E.Message );
        end;
    end;

    FDirty := not Done;
    UpdateMenus;
    IncludeRecentFile( FileName );
end;

procedure TFileMenuHandler.MenuSaveAs(Sender: TObject);
var
    SaveDialog : TSaveDialog;
    FileName : string;
    Done : boolean;
    RegIniFile : TRegIniFile;
begin
    if (not FActiveDocument) or (not Assigned(FOnFileWrite))
        then begin
        exit;
    end;

    // Determine filename / path to offer in the file save dialog.
    // ..- (1) if have a current filename, use that.
    FileName := FFileName;

    // ..- (2) if have a last saved value in registry, use that
    // ..- (3) if no current filename, no last saved, then just offer blank
    //    and OpenDialog will function OK
    if (FileName = '') and (FHKEY_CURRENT_USER_key <> '') then begin
        RegIniFile := TRegIniFile.Create( FHKEY_CURRENT_USER_key );
        try
           FileName := RegIniFile.ReadString( 'File', 'SaveAs', '' );
        finally
            RegIniFile.Free;
        end;
    end;

    // show File Save dialog and get user to enter name for file to write
    SaveDialog := TSaveDialog.Create(nil);
    try
        SaveDialog.DefaultExt := FFileExtension;
        SaveDialog.FileName := ExtractFileName( FileName );
        SaveDialog.Filter := FFileFilter;
        SaveDialog.InitialDir := ExtractFilePath( FileName );
        SaveDialog.Title := 'Save File';
        SaveDialog.Options :=
            [ofNoReadOnlyReturn, ofOverwritePrompt, ofPathMustExist,
                ofHideReadOnly, ofEnableSizing];
        if not SaveDialog.Execute then begin
            exit;
        end;
        FileName := SaveDialog.FileName;
     finally
        SaveDialog.Free;
    end;

    // Save to file
    Done := False;
    // ...this line may cause exception, in which case, no variable will be
    // changed, which is OK.
    FOnFileWrite( self, FileName, Done );
    if Done then begin
        SetFileName( FileName );
        FDirty := False;
        IncludeRecentFile( FileName );

        // save filename in Registry
        if FHKEY_CURRENT_USER_key <> '' then begin
            RegIniFile := TRegIniFile.Create( FHKEY_CURRENT_USER_key );
            try
               RegIniFile.WriteString( 'File', 'SaveAs', FileName );
            finally
                RegIniFile.Free;
            end;
        end;
    end;
    UpdateMenus;
end;

procedure TFileMenuHandler.MenuCloseFile(Sender: TObject);
begin
    ReleaseFile;
end;

procedure TFileMenuHandler.MenuExit(Sender : TObject);
begin
    if Assigned( FOnExit ) then begin
        FOnExit( self );
    end;
end;


procedure TFileMenuHandler.NotifyDirty;
begin
    if not FDirty then begin
        FDirty := True;
        // if we didn't "File |New", but just started editing a blank document
        // then we must get an active document.
        if not FActiveDocument then begin
           FActiveDocument := True;
        end;
        UpdateMenus;
    end;
end;

constructor TFileMenuHandler.Create;
begin
     FMaxRecentFiles := DEFAULT_MAX_RECENT_FILES;
     RecentFiles := TStringList.Create;
end;

destructor TFileMenuHandler.Destroy;
var
    RegIniFile : TRegIniFile;
    i : integer;
begin
    // put recent files list into Registry
    RegIniFile := TRegIniFile.Create( FHKEY_CURRENT_USER_key );
    try
        for i := 0 to RecentFiles.Count -1 do begin
            RegIniFile.WriteString( 'File', 'Last' + IntToStr(i), RecentFiles[i] );
        end;

    finally
        RegIniFile.Free;
    end;

    RecentFiles.Free;
end;

procedure TFileMenuHandler.UpdateMenus;
begin
     FSaveMenu.Enabled := FActiveDocument and FDirty;
     FSaveAsMenu.Enabled := FActiveDocument;
end;


function TFileMenuHandler.ExitFile : boolean;
begin
    result := ReleaseFile;
end;

procedure TFileMenuHandler.SetKey( const Value : string );
var
   RegIniFile : TRegIniFile;
   i : integer;
   RecentFile : string;
begin
     FHKEY_CURRENT_USER_key := Value;

    if FHKEY_CURRENT_USER_key = '' then begin
        exit;
    end;

    RegIniFile := TRegIniFile.Create( FHKEY_CURRENT_USER_key );
    try
        for i := 0 to FMaxRecentFiles -1 do begin
            RecentFile :=
                RegIniFile.ReadString( 'File', 'Last' + IntToStr(i), '' );
            if RecentFile <> '' then begin
                RecentFiles.Add( RecentFile );
            end;
        end;
    finally
        RegIniFile.Free;
    end;

    // show recent files in menu
    LimitRecentFileCount;
    DisplayRecentFiles;
end;

procedure TFileMenuHandler.DisplayRecentFiles;
var
   i : integer;
   RecentFileItem : TMenuItem;
   FileName : string;
begin
    // add additional Most Recent File Menus
    for i := FFileMenu.Count - FSeparator.MenuIndex to RecentFiles.Count do begin
        AddMenuItem( RecentFileItem, '', MenuRecentFile, 100 );
    end;

    // setup File Menus to show most recent files
    for i := 0 to RecentFiles.Count -1 do begin
        RecentFileItem := FFileMenu.Items[FSeparator.MenuIndex + 1 + i];

        // could write a function which limits width of filenames displayed in
        // menu.  Delphi VCL has function MinimizeName(), but this requires
        // the canvas (with font selected) of the menu - not easily possible,
        // since Windows draws the menu. See "Programming Windows 95" and "Win
        // 32 Core API" for ways to draw directly in a menu - might be able to
        // find enough info to handle this.
        // function MinimizeName(const Filename: TFileName; Canvas: TCanvas; MaxLen: Integer): TFileName;

        // for now, if file + path too long, show filename only
        // and if filename only too long then truncate and add '...'
        FileName := RecentFiles[i];
        if Length( FileName ) > 70 then begin
            FileName := ExtractFileName( FileName );
        end;
        if Length( FileName ) > 70 then begin
            FileName := Copy( FileName, 1, 67 ) + '...';
        end;

        // show with underlined first character for i = 0 to 8  (shows 1 to 9)
        if i < 9 then begin
            RecentFileItem.Caption := Format( '&%d %s', [i+1, FileName ] );
        end
        // show without underlined first character for i > 8 (shows 10 and greater)
        else begin
            RecentFileItem.Caption := Format( '%d %s', [i+1, FileName ] );
        end;
        RecentFileItem.Visible := True;
    end;

    // remove excess Most Recent File Menus (make invisible)
    for i := FSeparator.MenuIndex + RecentFiles.Count + 1 to
        FFileMenu.Count -1 do begin
        FFileMenu.Items[i].Visible := False;
    end;

    // hide / show separator bar depending on whether there are files
    // displayed below it
    FSeparator.Visible := (RecentFiles.Count > 0);
end;

procedure TFileMenuHandler.MenuRecentFile(Sender : TObject);
var
    RecentFileItem : TMenuItem;
    RecentFileIndex : integer;
    RecentFileName : string;
begin
    RecentFileItem := Sender as TMenuItem;
    RecentFileIndex := RecentFileItem.MenuIndex - FSeparator.MenuIndex +  -1;
    if (RecentFileIndex >= 0) and (RecentFileIndex < RecentFiles.Count) then begin
       RecentFileName := RecentFiles[RecentFileIndex];
       LoadFile( RecentFileName );
    end;
end;

procedure TFileMenuHandler.IncludeRecentFile( const FileName : string );
var
    FileIndex : integer;
begin
     FileIndex := RecentFiles.IndexOf( FileName );

     //.. Note RecentFiles[] contains full path to file, so each file is
     //.. uniquely identified.

     // if filename is already in the list, move it to start
     if FileIndex >= 0 then begin
         RecentFiles.Move( FileIndex, 0 );
     end

     // filename not in list, so insert it at start
     else begin
          RecentFiles.Insert( 0, FileName );
          LimitRecentFileCount;
     end;

     // update display of files in menu
     DisplayRecentFiles;
end;

procedure TFileMenuHandler.LimitRecentFileCount;
var
    i : integer;
begin
    for i := RecentFiles.Count -1 downto FMaxRecentFiles do begin
        RecentFiles.Delete(i);
    end;
end;

function TFileMenuHandler.GetRecentFilesCount : integer;
begin
    result := RecentFiles.Count;
end;

procedure TFileMenuHandler.NewFile;
begin
    MenuNew( nil );
end;


procedure TFileMenuHandler.LoadMostRecentFile;
var
   FileName : string;
begin
     if RecentFiles.Count < 1 then begin
        exit;
     end;
     FileName := RecentFiles[0];
     if FileExists( FileName ) then begin
        LoadFile( FileName );
     end;
end;


(*
Want to save File|Open, File|SaveAs into registry.

File | Open : record File|Open filename and offer same directory and
file as last time.

File | Save : no choice needed, because file already has a name.

File | SaveAs : record last folder saved to with FileSaveAs and
offer this as directory - but do not offer a filename.


HKEY_CURRENT_USER\Software\RKL\VeeCAD\2'

If no value stored in Registry, (first time after install) then offer
"My Documents" as directory.  This may be automatic behaviour of Win 9X thru XP
but we need to check.  Otherwise use Shell functions to get CSIDL and convert
to filename.


Most Recently Used :

Run a TStringList of last 8? files.  Store in Registry as a set of
keys "File0' to "File7" which are rewritten every time program FileMenuHandler
destructor is called.

Add code which updates RecentFiles[] every time a file is saved. or opened.
Removes duplicate entry from RecentFiles[] then puts latest file at top.
Add property RecentFilesCount which allows setting of number of recent files.
Add code which save RecentFiles[] to Registry (in destructor ?)
*)

end.
