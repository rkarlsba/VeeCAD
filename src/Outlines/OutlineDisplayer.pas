unit OutlineDisplayer;

interface

uses Editor, Project, Outlines, Classes;

type TveOutlineDisplayer = class(TveEditor)
    protected
    DisplayItem : TveBoardItem;
    FOutline : TveOutline;
    procedure SetWidth( AWidth : integer );
    function GetWidth : integer;
    procedure SetHeight( AHeight : integer );
    function GetHeight : integer;
    public
    property Outline : TveOutline read FOutline write FOutline;
    property Width : integer read GetWidth write SetWidth;
    property Height : integer read GetHeight write SetHeight;
    procedure Prepare;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
end;

implementation

uses Forms, Types, Board, Dialogs;

constructor TveOutlineDisplayer.Create(AOwner: TComponent);
begin
    inherited;
    Project := TveProject.Create;
    Project.Board.Pattern := ptStrip;

    DisplayItem := TveBoardItem.Create;
    DisplayItem.X := 5;
    DisplayItem.Y := 0;
    DisplayItem.Length := 8;
    //.. must have an outline at all times - can't be nil
    DisplayItem.Outline := Project.DummyOutline;
    Project.AddBoardItem(DisplayItem);

    // 96 DPI gets 1 pixel wide line
    // 120 DPI gets 2 pixels wide line
    // 180 DPI gets 3 pixels wide line
    ComponentLineWidth := Screen.PixelsPerInch div 60;

    // no mouse zoom
    OnMouseWheel := nil;
end;

destructor TveOutlineDisplayer.Destroy;
begin
    //.. TveEditor (ancestor) frees the Project member we created
    //.. and Project will destroy DisplayItem;
    inherited;
end;

procedure TveOutlineDisplayer.SetWidth( AWidth : integer );
begin
    Project.Board.Width := AWidth;
end;

function TveOutlineDisplayer.GetWidth : integer;
begin
    result := Project.Board.Width;
end;

procedure TveOutlineDisplayer.SetHeight( AHeight : integer );
begin
    Project.Board.Height := AHeight;
end;

function TveOutlineDisplayer.GetHeight : integer;
begin
    result := Project.Board.Height;
end;

procedure TveOutlineDisplayer.Prepare;
begin
    Project.Board.Prepare;
end;

procedure TveOutlineDisplayer.Paint;
var
    ItemRect : TRect;
begin
    if Assigned(FOutline) then begin

        // our single board item will display the outline
        DisplayItem.Outline := FOutline;

        // let outline adjust our item length to tasteful and safe value
        FOutline.SetDefaultLength( DisplayItem );

        // adjust top & left so item sits at (1,1) next to top left of display
        FOutline.GetScreenRectR( DisplayItem, ItemRect );

        DisplayItem.X := DisplayItem.X - ItemRect.Left + 1;
        DisplayItem.Y := DisplayItem.Y - ItemRect.Top + 1; 

        // draw BoardItems
        inherited Paint;
    end;
end;

end.

