unit GraphicCopy;

interface

uses Editor;

procedure CopyGraphicToClipboard( Editor : TveEditor );


implementation

uses Registry, Globals, ClipbrdGraphic;

procedure CopyGraphicToClipboard( Editor : TveEditor );
var
    RegIniFile : TRegIniFile;
    ArtMaker : TveClipboarder;
    PixelsPerCell : integer;
    RulerString : string;
    Ruler : TveRuler;
begin
    // get Registry Info
    RegIniFile := GetRegIniFile;
    try
        PixelsPerCell :=
            RegIniFile.ReadInteger( 'GraphicCopy', 'PixelsPerCell', 24 );

        RulerString := RegIniFile.ReadString( 'GraphicCopy', 'Rulers', '' );
    finally
        RegIniFile.Free;
    end;

    if RulerString = 'Number' then begin
        Ruler := ruNumber
    end
    else if RulerString = 'LetterNumber' then begin
        Ruler := ruLetterNumber
    end
    else begin
        Ruler := ruNone;
    end;


    // use ArtMaker to make graphic
    ArtMaker := TveClipboarder.Create;
    try
        ArtMaker.Editor := Editor;
        ArtMaker.Rulers := Ruler;
        ArtMaker.PixelsPerCell := PixelsPerCell;
        ArtMaker.CopyToClipBoard;
    finally
        ArtMaker.Free;
    end;
end;


end.


