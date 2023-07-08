unit Styles;

interface

uses Classes, Editor;

// ** Display settings storage and retrieval for VeeCAD **
// Class is not general purpose: it is built only to access the Styles.txt
// file stored in a predetermined folder.

type TveStyles = class

  protected
    Folder : string;
    FData : TStringList;
    FNames : TStringList;
    function GetNames : TStrings;
  public
    property Names : TStrings read GetNames;
    procedure StyleToEditor( Index : integer; Editor : TveEditor );

    constructor Create;
    destructor Destroy; override;
end;


implementation

uses SysUtils, Graphics;


constructor TveStyles.Create;
var
    i : integer;
    Line : string;
    FileName : string;
begin
    FNames := TStringList.Create;
    FData := TStringList.Create;

    // if style data file does not exist, quit now without error - we have
    // "no" styles
    FileName := ExtractFilePath( ParamStr(0) ) + 'Styles.txt';
    if not FileExists( FileName ) then begin
        exit;
    end;

    // read raw data in - acdepts unicode with BOM Byte Order Mark or ansii
    // local codepage.
    FData.LoadFromFile( FileName );

    // from raw data, separate out square bracketed Style names
    for i := 0 to FData.Count -1 do begin
        Line := Trim( FData[i] );
        if (Length(Line) > 1) and ( Line[1] = '[' ) and ( Line[Length(Line)] = ']' ) then begin
            FNames.Add( Copy( Line, 2, Length(Line) -2 ) );
        end;
    end;

    // sort names for consistent user listing
    FNames.Sort;
end;


destructor TveStyles.Destroy;
begin
    FNames.Free;
    FData.Free;
end;

function TveStyles.GetNames : TStrings;
begin
    result := FNames;
end;

procedure TveStyles.StyleToEditor( Index : integer; Editor : TveEditor );


    function GetColor( const s : string ) : TColor;
    begin
        // find '=' character
        result := StrToInt( '$' + Copy( s, 1 + Pos( '=', s ), 255 ) );
    end;

type
    TStyle =  (
        stBodyColor, stPinColor, stStripColor, stBoardColor, stSelectionColor );
    TStyles = set of TStyle;

var
    Name : string;
    NameIndex : integer;
    i : integer;
    Line : string;

    Styles : TStyles;
    BodyColor : TColor;
    PinColor : TColor;
    StripColor : TColor;
    BoardColor : TColor;
    SelectionColor : TColor;

begin
    // get style name
    Name := FNames[Index];

    // find name in data
    NameIndex := FData.IndexOf( '[' + Name + ']' );

    // if we can't find the name, some kind of internal inconsistency in this
    // code, but don't make a fuss
    if NameIndex < 0 then begin
        exit;
    end;

    // parse next lines from file

    // ...assign colors to elements to stop "uninitialized variable" warnings
    BodyColor := clBlack;
    PinColor := clBlack;
    StripColor := clBlack;
    BoardColor := clBlack;
    SelectionColor := clBlack;

    Styles := [];
    for i := NameIndex +1 to FData.Count -1 do begin

        Line := Trim( FData[i] );

        // if a section name in brackets '[..] then end of section
        if (Length(Line) > 1) and ( Line[1] = '[' ) and ( Line[Length(Line)] = ']' )
            then begin
            break;
        end;

        // look for stuff like this
        {
        [Grey]
        Body=003D7F
        Pin=1A9F00
        Strip=E0E0E0
        Board=DFFFFF
        Selection=0000FF
        }

        if Pos( 'Body=', Line ) = 1 then begin
            BodyColor := GetColor( Line );
            Include( Styles, stBodyColor );
        end
        else if Pos( 'Pin=', Line ) = 1 then begin
            PinColor := GetColor( Line );
            Include( Styles, stPinColor );
        end
        else if Pos( 'Strip=', Line ) = 1 then begin
            StripColor := GetColor( Line );
            Include( Styles, stStripColor );
        end
        else if Pos( 'Board=', Line ) = 1 then begin
            BoardColor := GetColor( Line );
            Include( Styles, stBoardColor );
        end
        else if Pos( 'Selection=', Line ) = 1 then begin
            SelectionColor := GetColor( Line );
            Include( Styles, stSelectionColor );
        end
    end;

    // transfer the colors only after file access and interpretation is finished
    // so that we can make decisions here
    if (Styles = [stBodyColor, stPinColor, stStripColor, stBoardColor]) then begin
        Editor.BodyColor := BodyColor;
        Editor.PinColor := PinColor;
        Editor.StripColor := StripColor;
        Editor.BoardColor := BoardColor;
    end;
    // if a newer file with Selection info
    if stSelectionColor in Styles then begin
        Editor.SelectionColor := SelectionColor;
    end
    else begin
        // use old default Red highlight
        Editor.SelectionColor := clRed;
    end;
end;



end.
