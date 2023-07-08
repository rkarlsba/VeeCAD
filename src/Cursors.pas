unit Cursors;

interface

uses Controls;


// cursors available
type TcCursorShape =
  ( csSelect, csLink, csWire, csBreak, csLine, csPin, csText, csHandOpen );

// cursor sizes available
type TCursorSize = ( szSmall, szLarge );

type TCursorMinder = class
    FRegistryKey : string;
    function GetCursorSize : TCursorSize;
    procedure SetCursorSize( Size : TCursorSize );
public
    property Size : TCursorSize read GetCursorSize write SetCursorSize;
    property HKEY_CURRENT_USER_KEY : string read FRegistryKey write FRegistryKey;
    function GetCursor( Shape : TcCursorShape ) : TCursor;
    procedure LoadSettings;
    procedure SaveSettings;
end;

// ** There is a single "Static" Cursor Minder for Whole Program
var CursorMinder : TCursorMinder;



implementation

{$R CURSORS.RES}

uses Windows, Forms, Registry;

// ** DATA IS "STATIC" TO ALL TCURSORS **
var
    CurrentSize : TCursorSize = szSmall;
    AvailableCursors : array[TCursorSize, TcCursorShape] of TCursor =
        ((-1, 21, 22, 23, 24, 29, 31, 33), (-1, 25, 26, 27, 28, 30, 32, 34));


function TCursorMinder.GetCursorSize : TCursorSize;
begin
    result := CurrentSize;
end;

// set size of cursors to be returned by GetCursor()
procedure TCursorMinder.SetCursorSize( Size : TCursorSize );
begin
    CurrentSize := Size;
end;

function TCursorMinder.GetCursor( Shape : TcCursorShape ) : TCursor;
begin
    result := AvailableCursors[CurrentSize][Shape];
end;

procedure TCursorMinder.SaveSettings;
const
    SizeText : array[TCursorSize] of string = ('small', 'large');
var
    RegIniFile : TRegIniFile;
begin
    RegIniFile := TRegIniFile.Create( HKEY_CURRENT_USER_KEY );
    try
        RegIniFile.WriteString( 'Cursor', 'Size', SizeText[CurrentSize]);
    finally
        RegIniFile.Free;
    end;
end;

procedure TCursorMinder.LoadSettings;
var
    RegIniFile : TRegIniFile;
begin
    RegIniFile := TRegIniFile.Create( HKEY_CURRENT_USER_KEY );
    try
        if RegIniFile.ReadString( 'Cursor', 'Size', 'small' ) = 'small' then begin
            CurrentSize := szSmall;
        end
        else begin
            CurrentSize := szLarge;
        end;
    finally
        RegIniFile.Free;
    end;
end;


// ************************************
//   READ CURSOR IMAGES FROM RESOURCE
// ************************************

{ How Cursors are stored in Delphi -

  The Screen.Cursors[] property has setter, getter functions which store
  cursors in a linked list.  Screen.Cursors[index] := hCur can be called with
  any index, since any existing cursor with that index is destroyed before the
  new cursor is stored, and the index can be any integer as large as you like,
  because the linked list is searched to find a record with a matching index
  field.
}

procedure ReadCursor( const Name : string; index : integer );
var
    hCur : HCURSOR;
begin
    hCur := LoadImage( HInstance, pChar(Name), IMAGE_CURSOR, 0, 0, 0 );
    Screen.Cursors[index] := hCur;
end;

initialization
begin
    ReadCursor( 'CUR_LINK_SM', 21 );
    ReadCursor( 'CUR_LINK_LG', 25 );

    ReadCursor( 'CUR_WIRE_SM', 22 );
    ReadCursor( 'CUR_WIRE_LG', 26 );

    ReadCursor( 'CUR_BREAK_SM', 23 );
    ReadCursor( 'CUR_BREAK_LG', 27 );

    ReadCursor( 'CUR_LINE_SM', 24 );
    ReadCursor( 'CUR_LINE_LG', 28 );

    ReadCursor( 'CUR_PIN_SM', 29 );
    ReadCursor( 'CUR_PIN_LG', 30 );

    ReadCursor( 'CUR_TEXT_SM', 31 );
    ReadCursor( 'CUR_TEXT_LG', 32 );

    ReadCursor( 'HAND_OPEN_SM', 33 );
    ReadCursor( 'HAND_OPEN_LG', 34 );

    CursorMinder := TCursorMinder.Create;
end

finalization
    CursorMinder.Free;
end.
