unit NetlistUser;

interface

uses Project;


procedure NetlistClear( Project : TveProject );
procedure NetlistExport( Project : TveProject; const ProjectFileName : string );
procedure NetlistGenerate( Project : TveProject );

implementation

uses NetlistGenerate, NetlistExport, Tracer, Dialogs, Controls, SysUtils
{$IFNDEF VER200}, System.UITypes {$ENDIF} ;


procedure NetlistClear( Project : TveProject );
begin
    if MessageDlg('Delete netlist from layout?', mtConfirmation,
        [mbOk,mbCancel], 0 ) = mrCancel then begin
          exit;
    end;

    Project.NetList.Clear;
    Project.TransferFastNets;
end;

procedure NetlistExport( Project : TveProject; const ProjectFileName : string );
var
    SaveDialog : TSaveDialog;
begin
    SaveDialog := TSaveDialog.Create(nil);
    try
        SaveDialog.DefaultExt := 'net';
        SaveDialog.Filter := 'Protel Netlist Files (*.net)|*.NET|All Files (*.*)|*.*';
//        SaveDialog.FileName :=      // path and file name
        SaveDialog.InitialDir :=  ExtractFilePath( ProjectFileName );
        SaveDialog.Options := [ofPathMustExist, ofOverwritePrompt];

        if SaveDialog.Execute then begin
            ExportNetlistProtel( SaveDialog.FileName, Project );
        end;
    finally
        SaveDialog.Free;
    end;
end;


// ***************************************************
//      FUNCTION HANDLES ENTIRE NET GENERATION FROM PROJECT
// ***************************************************

// Call this function to have a netlist created from a layout

procedure NetlistGenerate( Project : TveProject );
var
    NetGen : TneNetlistGenerator;
begin
    NetGen := TneNetlistGenerator.Create;
    try
        NetGen.Project := Project;
        NetGen.Tracer := TveTracer( Project.ConnectivityObject );
        NetGen.Execute;
        Project.NetList.Clone( NetGen.Netlist );
        Project.TransferFastNets;
    finally
        NetGen.Free;
    end;
end;

end.
