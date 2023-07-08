program IconUpdate;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  MainIconUpdate in 'MainIconUpdate.pas';

var
    TargetExeName : string;
    IconFileName : string;

begin
    Writeln( 'Icon Updater V 1.0 : replaces MAINICON in a Delphi .exe'#13 );

    // command line parameters count
    if ParamCount <> 2 then begin
        Writeln( 'usage: IconUpdater TargetExeFile IconFile'#13 );
        ExitCode := 1;
        exit;
    end;

    // exe to modify
    TargetExeName := ParamStr( 1 );
    if not FileExists( TargetExeName ) then begin
        Writeln( 'Target Exe File not found: ' + TargetExeName );
        ExitCode := 2;
        exit;
    end;

    // icon file
    IconFileName := ParamStr( 2 );
    if not FileExists( IconFileName ) then begin
        Writeln( 'Icon File not found: ' + IconFileName );
        ExitCode := 3;
        exit;
    end;

    //
    try
        UpdateDelphiExeIcons( TargetExeName, IconFileName );
    except
        On E: Exception do begin
            Writeln( 'Error : ' + E.Message );
            ExitCode := 4;
            exit;
        end;
    end;

    // success
    ExitCode := 0;

end.
