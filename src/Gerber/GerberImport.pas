unit GerberImport;

interface

uses Board;

procedure GerberImportBoard( Board : TbrBoard );

implementation

uses Registry, Dialogs, Globals, SysUtils, Forms, Controls, GerberImporter;

procedure GerberImportBoard( Board : TbrBoard );

var
    RegIniFile : TRegIniFile;
    OpenDialog : TOpenDialog;
    FileName : string;
    Importer : TgrGerberImport;
begin
    RegIniFile := GetRegIniFile;
    try
        OpenDialog := TOpenDialog.Create( nil );
        try
            FileName := RegIniFile.ReadString( 'Tracks', 'GerberImportFile', '' );

            OpenDialog.FileName := ExtractFileName( FileName );
            OpenDialog.InitialDir := ExtractFilePath( FileName );
            OpenDialog.Filter := 'Gerber Files|*.*';
            OpenDialog.Options := [ofEnableSizing, ofFileMustExist, ofHideReadOnly];

            if not OpenDialog.Execute then begin
                exit;
            end;
            FileName := OpenDialog.FileName;
        finally
            OpenDialog.Free;
        end;

        RegIniFile.WriteString( 'Tracks', 'GerberImportFile', FileName );

    finally
        RegIniFile.Free;
    end;


    Importer := TgrGerberImport.Create;
    try
        Screen.Cursor := crHourGlass;
        try
            Importer.ReadFileToBoard( FileName, Board );
        finally
            Screen.Cursor := crDefault;
        end;
    finally
        Importer.Free;
    end;
end;

end.
