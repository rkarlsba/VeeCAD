unit Import;

interface

uses Project;

procedure ImportNetlist( Project : TveProject; const ProjectFileName : string );

implementation

uses ImportNetFrm;


procedure ImportNetlist( Project : TveProject; const ProjectFileName : string );
var
    ImportNetForm : TImportNetForm;
begin
    ImportNetForm := TImportNetForm.Create(nil);
    try
        ImportNetForm.ProjectFileName := ProjectFileName;
        ImportNetForm.Project := Project;
        ImportNetForm.Execute;
    finally
        ImportNetForm.Free;
    end;
end;

end.
