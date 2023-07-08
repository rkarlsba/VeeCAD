unit ClipbrdUtils;

interface

uses Classes;

function ReadClipboardText : string;
procedure WriteClipboardText( const s :  string );
procedure ReadClipboardToMemoryStream(
    ClipboardFormat : Word; Stream : TMemoryStream );
procedure WriteMemoryStreamToClipboard(
    ClipboardFormat : Word; Stream : TMemoryStream );

implementation

uses Clipbrd, Windows, SysUtils, ExceptSafe;

type EClipbrdUtils = class( Exception );
     ESafeClipbrdUtils = class( ESafe );


function ReadClipboardText : string;
var
    ClipHandle : THandle;
    TextPtr : pChar;
begin
    ClipBoard.Open;
    try
        ClipHandle := Clipboard.GetAsHandle( CF_TEXT );
        TextPtr := GlobalLock(ClipHandle);
        try
            result := string( TextPtr );
        finally
            GlobalUnlock(ClipHandle);
        end;
    finally
        Clipboard.Close;
    end;
end;


procedure WriteClipboardText( const s :  string );
var
    hMem : THandle;
    TextPtr : pChar;
begin
    hMem := GlobalAlloc( GMEM_MOVEABLE or GMEM_DDESHARE, Length(s)+1 );
    if hMem = 0 then begin
        raise Exception.Create('Can''''t allocate memory');
    end;
    TextPtr := GlobalLock( hMem );
    if TextPtr = Nil then begin
        GlobalFree( hMem );
        raise Exception.Create('Can''''t lock memory');
    end;
    try
        Move( (@(s[1]))^, TextPtr^, Length(s) + sizeof(Char) );
    finally
        GlobalUnlock( hMem );
    end;
    ClipBoard.SetAsHandle( CF_TEXT, hMem );
end;


// ** Read Clipboard Data To Memory Stream **
// If data format not available on clipboard, then returns with Stream.Size=0

procedure ReadClipboardToMemoryStream(
    ClipboardFormat : Word; Stream : TMemoryStream );

var
    hMem : THandle;
    pMem : pointer;
begin

    // open the clipboard
//    if not OpenClipboard( Application.Handle ) then begin
    if not OpenClipboard( 0 ) then begin
        raise ESafeClipbrdUtils.Create( 'Can''''t open Clipboard' );
    end;
    try
        // get a handle to the clipboard data
        hMem := GetClipboardData( ClipboardFormat );

        // nothing on the clipboard in our format..
        if hMem = 0 then begin
            Stream.Size := 0;
            exit;
        end;

        // get a pointer to the clipboard data
        pMem := GlobalLock( hMem );
        if pMem = nil then begin
            raise EClipbrdUtils.Create( 'GlobalLock fail' );
        end;
        try
            // copy the null terminated clipboard data into our memory stream
            Stream.Position := 0;
            Stream.Size := sizeof(char) * StrLen( pChar(pMem) );
            Stream.WriteBuffer( pMem^, Stream.Size );
        finally
            GlobalUnlock( hMem );
        end;

    finally
        CloseClipboard;
    end;
    Stream.Position := 0;
end;
    
// ** Write Memory Stream to Clipboard **
// Uses Clipboard format specified
procedure WriteMemoryStreamToClipboard( ClipboardFormat : Word; Stream : TMemoryStream );
var
    hMem : THandle;
    pMem : Pointer;
begin
    // get a handle to a global block of memory
    hMem := GlobalAlloc( GMEM_DDESHARE or GMEM_MOVEABLE, Stream.Size );
    if hMem = 0 then begin
        exit;
    end;
    try
        // get a pointer to global memory & copy data to global memory
        pMem := GlobalLock( hMem );
        if pMem = nil then begin
            raise EClipbrdUtils.Create( 'Memory lock fail' );
        end;
        try
            // copy data to global memory
            Move( Stream.Memory^, pMem^, Stream.Size );
        finally
            GlobalUnlock( hMem );
        end;

        // give global memory to clipboard
//        if not OpenClipboard( Application.Handle ) then begin
        if not OpenClipboard( 0 ) then begin
            raise ESafeClipbrdUtils.Create( 'Open Clipboard fail' );
        end;
        try
            EmptyClipboard;
            if SetClipboardData( ClipboardFormat, hMem ) = 0 then begin
                raise EClipbrdUtils.Create( 'SetClipboardData fail' );
            end;
        finally
            CloseClipboard;
        end;

    except
        GlobalFree( hMem );
        raise;
    end;
end;

end.
