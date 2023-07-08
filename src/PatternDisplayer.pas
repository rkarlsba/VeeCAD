unit PatternDisplayer;

interface

uses Editor, Project, Classes, ProjectInput;

type TvePatternDisplayer = class(TveEditor)
    protected
        Loader : TProjectInputLoader;
    public
        procedure LoadFromFile( const FileName : string );

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
end;

implementation

uses Forms, Types, Board;

constructor TvePatternDisplayer.Create(AOwner: TComponent);
begin
    inherited;
    Project := TveProject.Create;
    Project.BoardWidth := 12;
    Project.BoardHeight := 12;

    Loader := TProjectInputLoader.Create( Project );

    // 96 DPI gets 1 pixel wide line
    // 120 DPI gets 2 pixels wide line
    // 180 DPI gets 3 pixels wide line
    ComponentLineWidth := Screen.PixelsPerInch div 60;

    // bright orange strips on pale yellow board
    StripColor := $5EBBF0;
    BoardColor := $DFF3FF;

    // no mouse zoom
    OnMouseWheel := nil;
end;

destructor TvePatternDisplayer.Destroy;
begin
    Loader.Free;
    //.. TveEditor (ancestor) frees the Project member we created
    inherited;
end;

procedure TvePatternDisplayer.LoadFromFile( const FileName : string );
begin
    Loader.LoadFromFile( FileName );
end;

end.
