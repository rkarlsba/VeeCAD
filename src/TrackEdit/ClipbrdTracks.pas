unit ClipbrdTracks;

interface

uses Tracks, Classes;

type TveTracksToClipboard = class
  protected
    FStream : TMemoryStream;
    FTracks : TbeTracks;
  public
    procedure CopySelected( Tracks : TbeTracks );
    constructor Create;
    destructor Destroy; override;
end;

type TveTracksFromClipboard = class
  protected
    FStream : TMemoryStream;
    FTracks : TbeTracks;
    PasteHandle : integer;
    PasteTime : integer;
  public
    procedure Paste( Tracks : TbeTracks );
    constructor Create;
    destructor Destroy; override;
end;

procedure CopySelectedTracksToClipboard( Tracks : TbeTracks );
procedure PasteTracksFromClipboard( Tracks : TbeTracks );



implementation

uses SysUtils, Forms, Windows, ClipbrdUtils, TrackItems, TextUtils;

var
    ClipboardFormat : Word;

type EClipboardTracks = class( Exception );

procedure LineToStream( S : TStream; const Line : string );
const CRLF : array[0..1] of char = #13#10;
begin
    S.WriteBuffer( PChar(Line)^, Length(Line) * sizeof(char) );
    S.WriteBuffer( CRLF, 2 * sizeof(char) );
end;

// ********************************************************
//    TveTracksToClipboard - Read Tracks from Clipboard
// ********************************************************

constructor TveTracksToClipboard.Create;
begin
    FStream := TMemoryStream.Create;
end;

destructor TveTracksToClipboard.Destroy;
begin
    FStream.Free;
    inherited;
end;

procedure TveTracksToClipboard.CopySelected( Tracks : TbeTracks );
var
    i : integer;
    Track : TteTrack;
begin
    // initialise
    FStream.Size := 0;

    // write header for clipboard
    LineToStream( FStream, 'VeeCADTracks' );

    // handle identifies the VeeCAD instance putting data to clipboard
    // 32 bit unsigned - interpret it as unsigned, so StrToInt will read it later
    LineToStream( FStream, Format('Handle=%10.10d', [integer(Application.Handle)]) );

    // Timestamp identifies which copy event placed this data. Allows Paste
    // do detect repeat pastes of same data and move that data.
    // 32 bit unsigned - interpret it as unsigned, so StrToInt will read it later
    LineToStream( FStream, Format('Time=%10.10d', [integer(GetTickCount)]) );

    // write strips and segments to clipboard data

    // write strips first
    LineToStream( FStream, 'Strips' );

    for i := 0 to Tracks.Count - 1 do begin
        Track := Tracks.Items[i];
        if (Track is TteStrip) and Track.Selected then begin
            // write it for clipboard
            Track.WriteToStream( FStream );
        end;
    end;
    LineToStream( FStream, 'end' );

    // write strips first
    LineToStream( FStream, 'Segments' );

    // write strips first
    for i := 0 to Tracks.Count - 1 do begin
        Track := Tracks.Items[i];
        if (Track is TteSegment) and Track.Selected then begin
            // write it for clipboard
            Track.WriteToStream( FStream );
        end;
    end;
    LineToStream( FStream, 'end' );
//    LineToStream( FStream, 'end' );

    // require a valid registered clipboard format for this job
    if ClipboardFormat = 0 then begin
        exit;
    end;

    // put data to clipboard
    WriteMemoryStreamToClipboard( ClipboardFormat, FStream );
end;

// ** SIMPLE FUNCTION CALL PROVIDES SELECTED TRACKS COPY TO CLIPBOARD **
procedure CopySelectedTracksToClipboard( Tracks : TbeTracks );
var
    Copyer : TveTracksToClipboard;
begin
    Copyer := TveTracksToClipboard.Create;
    try
        Copyer.CopySelected( Tracks );
    finally
        Copyer.Free;
    end;
end;


// ********************************************************
//    TveTracksFromClipboard - Read Tracks from Clipboard
// ********************************************************

constructor TveTracksFromClipboard.Create;
begin
    FStream := TMemoryStream.Create;
end;

destructor TveTracksFromClipboard.Destroy;
begin
    FStream.Free;
    inherited;
end;

// ** SIMPLE FUNCTION CALL PROVIDES PASTE TRACKS FROM CLIPBOARD **
procedure TveTracksFromClipboard.Paste( Tracks : TbeTracks );
var
    Line : string;
    Name, Value : string;
    NewStrip : TteStrip;
    NewSegment : TteSegment;
begin
    //
//    FProject := Project;

    // get the block of data off the clipboard
    ReadClipboardToMemoryStream( ClipboardFormat, FStream );

    // if nothing on the clipboard with our format, OR has zero bytes(!), then
    // nothing to paste
    if FStream.Size = 0 then begin
        exit;
    end;

    // data must start with 'VeeCADComponents'
    if (not LineFromStream( FStream, Line )) or (Line <> 'VeeCADTracks') then begin
        exit;
    end;

    // unselect existing tracks, because newly pasted tracks will be selected
    Tracks.ClearSelectedItems;

    // next is Handle=1234
    // Read handle of VeeCAD instance which placed this data on clipboard.
    // We use this to detect if same or different instance put this data onto
    // clipboard
    if (not NameValueFromStream( FStream, Name, Value )) or (Name <> 'Handle') then begin
        exit;
    end;
    PasteHandle := StrToInt( Value );

    // next is Time=1234
    // read timestamp at moment this data placed on clipboard. We use this to
    // uniquely identify each clipboard copy "payload"
    if (not NameValueFromStream( FStream, Name, Value )) or (Name <> 'Time') then begin
        exit;
    end;
    PasteTime := StrToInt( Value );

    // next section is 'Strips'
    if (not LineFromStream( FStream, Line )) or (Line <> 'Strips') then begin
        exit;
    end;

    // create a strip for each outline listed in stream
    while True do begin

        // parse next stip from stream - starts with name, value pair on
        // first line of definition.
        if (not NameValueFromStream( FStream, Name, Value )) then begin

            // we are in trouble - stream is broken?
            raise EClipboardTracks.Create( 'Truncated strips stream' );
        end;

        // "Strip" as Name portion means we have another strip definition
        // in the stream
        if Name = 'Strip' then begin

            // create a Strip object as a one of our set of tracks
            NewStrip := Tracks.AddNewStrip;

            // get strip to read its properties from the stream
            NewStrip.ReadFromStream( FStream );

            // show all pasted Tracks as selected
            NewStrip.Selected := True;
        end

        // end of Strips section
        else if Name = 'end' then begin
            break;
        end

        // something wrong if not a segment OR end
        else begin
            raise EClipboardTracks.Create( 'Missing "Strip" or "End" in strips stream' );
        end;
    end;

    // next section is 'Segments'
    if (not LineFromStream( FStream, Line )) or (Line <> 'Segments') then begin
        exit;
    end;

    // create a strip for each outline listed in stream
    while True do begin

        // parse next stip from stream - starts with name, value pair on
        // first line of definition.
        if (not NameValueFromStream( FStream, Name, Value )) then begin

            // we are in trouble - stream is broken?
            raise EClipboardTracks.Create( 'Truncated segments stream' );
        end;

        // "Segment" as Name portion means we have another segment definition
        // in the stream
        if Name = 'Segment' then begin

            // create a Segment object as a one of our set of tracks
            NewSegment := Tracks.AddNewSegment;

            // get strip to read its properties from the stream
            NewSegment.ReadFromStream( FStream );

            // show all pasted Tracks as selected
            NewSegment.Selected := True;
        end

        // end of Strips section
        else if Name = 'end' then begin
            break;
        end

        // something wrong if not an outline OR end
        else begin
            raise EClipboardTracks.Create( 'Missing "Segment" or "End" in strips stream' );
        end;
    end;
end;


procedure PasteTracksFromClipboard( Tracks : TbeTracks );
var
    Paster : TveTracksFromClipboard;
begin
    Paster := TveTracksFromClipboard.Create;
    try
        Paster.Paste( Tracks );
    finally
        Paster.Free;
    end;
end;



initialization

{$IFDEF DEBUG}
    // put data onto clipboard in CF_TEXT so can paste into Notepad for debug.
    ClipboardFormat := CF_UNICODETEXT;
{$ELSE}
    ClipboardFormat := RegisterClipboardFormat( 'VeeCAD Track' );
{$ENDIF}

end.
