unit ClipbrdOutlines;

interface

uses Classes, Outlines, Project, SysUtils, Windows;

type
    EOutlineClipboard = class( Exception );


// *******************************************************
//          SEND OUTLINES TO CLIPBOARD
// *******************************************************

type TveOutlinesToClipboard = class
  protected
    FSenderHandle : THandle;
    FStream : TMemoryStream;
    OutlineCount : integer;
    procedure WriteHeaderToStream;
  public
    property SenderHandle : THandle read FSenderHandle write FSenderHandle;
    procedure AddOutline( Outline : TveOutline );
    procedure SendToClipboard;

    constructor Create;
    destructor Destroy; override;
end;

// *******************************************************
//          GET OUTLINES FROM CLIPBOARD
// *******************************************************

type TveOutlinesFromClipboard = class
  protected
    FStream : TMemoryStream;
    FOutlinesAvailable : boolean;
    FOutlineCount : integer;
    FSenderHandle : THandle;
  public
    property OutlinesAvailable : boolean read FOutlinesAvailable;
    property OutlineCount : integer read FOutlineCount;
    property SenderHandle : THandle read FSenderHandle;

    // update properties from clipboard
    procedure ReadClipboard;
    procedure Paste( Project : TveProject );
    procedure PasteOverwrite( Project : TveProject );
    procedure PasteInto( Project : TveProject; Target : TveOutline; var NewOutline :  TveOutline );

    constructor Create;
    destructor Destroy; override;
end;


// *******************************************************
// read next section from stream and create an outline from it
// *******************************************************

function CreateDefinedOutlineFromStream( Stream : TStream ) : TveOutline;


implementation

uses Forms,
    SizeableOutlines, RadialOutlines, CelledOutlines, CustomOutlines, SmdOutlines,
    ClipbrdUtils;


// read next section from stream and create an outline from it
// If next section is not an outline, then leave stream position as it was
// before entering this function.  Can raise an exception, for example if stream
// does not contain expected text defining an outline.
function CreateDefinedOutlineFromStream( Stream : TStream ) : TveOutline;
var
    Name, Value : string;
    OriginalPosition : integer;
begin
    // assume the worst
    OriginalPosition := Stream.Position;
    result := nil;

    // parse next outline from stream - start with name, value pair on first line
    if not NameValueFromStream( Stream, Name, Value ) then begin
        Stream.Position := OriginalPosition;
        exit;
    end;

    // look for "Outline" as Name portion
    if Name <> 'Outline' then begin
        Stream.Position := OriginalPosition;
        exit;
    end;

    // create an object of the required class, and ask it to initialise
    // from the stream
    if Value = 'TveLeadedOutline' then begin
        result := TveLeadedOutline.Create;
    end
    else if Value = 'TveRadialOutline' then begin
        result := TveRadialOutline.Create;
    end
    else if Value = 'TveCellOutline' then begin
        result := TveCellOutline.Create;
    end
    else if Value = 'TveCustomOutline' then begin
        result := TveCustomOutline.Create;
    end
    else if Value = 'TveSmdOutline' then begin
        result := TveSmdOutline.Create;
    end;
    try
        result.ReadFromStream( Stream );
    except
        result.Free;
        raise;
    end;

end;

var
    ClipboardFormat : Word;

// **************************************************
//          TveOutlineToClipboard
// **************************************************

// ** Send Outline To Stream **

procedure TveOutlinesToClipboard.AddOutline( Outline : TveOutline );
begin
    Outline.WriteToStream( FStream );
    Inc( OutlineCount );
end;

procedure TveOutlinesToClipboard.SendToClipboard;

const
    Nulls : array[0..1] of char = #0#0;
begin
    // rewrite headers with latest information
    FStream.Position := 0;
    WriteHeaderToStream;

    // null terminate
    FStream.Seek( 0, soFromEnd	);
    FStream.WriteBuffer( Nulls, sizeof(char) * 2 );

    // require a valid registered clipboard format for this job
    if ClipboardFormat = 0 then begin
        exit;
    end;

    WriteMemoryStreamToClipboard( ClipboardFormat, FStream );
end;

procedure TveOutlinesToClipboard.WriteHeaderToStream;
begin
    // put initial info into clipboard stream...
    //.. handle
    LineToStream( FStream, Format('Handle=%10.10u', [FSenderHandle]) );

    //.. outline count
    LineToStream( FStream, Format('OutlineCount=%10.10u', [OutlineCount]) );
end;


constructor TveOutlinesToClipboard.Create;
begin
    FStream := TMemoryStream.Create;
    WriteHeaderToStream;
end;

destructor TveOutlinesToClipboard.Destroy;
begin
    FStream.Free;
    inherited;
end;


// **************************************************
//            TveOutlinesFromClipboard
// **************************************************

constructor TveOutlinesFromClipboard.Create;
begin
    FStream := TMemoryStream.Create;
end;

destructor TveOutlinesFromClipboard.Destroy;
begin
    FStream.Free;
    inherited;
end;


// ***** READ CLIPBOARD AND PARSE FIRST HEADERS ******

procedure TveOutlinesFromClipboard.ReadClipboard;
var
    Name, Value : string;
begin
    // set properties to default "nothing on clipboard" values
    FOutlinesAvailable := False;
    FOutlineCount := 0;  
    FSenderHandle := 0;

    // get the block of data off the clipboard
    ReadClipboardToMemoryStream( ClipboardFormat, FStream );

    // if nothing on the clipboard with our format, OR has zero bytes(!), then
    // nothing to paste
    if FStream.Size = 0 then begin
        exit;
    end;

    // read headers to find number of outlines, handle
    if (not NameValueFromStream( FStream, Name, Value )) or
        (Name <> 'Handle') then begin

        // chances are we have CF_TEXT format, so act as though nothing on clipboard
        exit;
        // raise EOutlineClipboard.Create( 'Sender Handle not found' );
    end;
    FSenderHandle := StrToIntDef( Value, 0 );
        // for 64 bit version, may need
        // function StrToInt64Def(const S: string; Default: Int64): Int64;

    if (not NameValueFromStream( FStream, Name, Value )) or
        (Name <> 'OutlineCount') then begin
        raise EOutlineClipboard.Create( 'Outline Count not found' );
    end;
    FOutlineCount := StrToIntDef( Value, 0 );

    FOutlinesAvailable := FOutlineCount > 0;
end;


// **** PASTE OUTLINES INTO PROJECT, USING MODIFIED NAMES IF NAMES EXIST ****

procedure TveOutlinesFromClipboard.Paste( Project : TveProject );
var
    NewOutline : TveOutline;
    TempOutlineName : string;
    NameCount : integer;
begin
    // if outline was created, add it to the project
    while True do begin

        NewOutline := CreateDefinedOutlineFromStream( FStream );

        // if no more outlines (or stream is rubbish)
        if NewOutline = nil then begin
            exit;
        end;

        // if a matching name exists, add (1) or (2) etc to name
        TempOutlineName := NewOutline.Name;
        NameCount := 0;
        while Project.OutlineByName( TempOutlineName ) <> nil do begin
            Inc( NameCount );
            TempOutlineName := Format( '%s (%d)', [NewOutline.Name, NameCount] );
        end;
        NewOutline.Name := TempOutlineName;

        // a new outline now available !
        Project.AddOutline( NewOutline );
    end;
end;

// **** PASTE OUTLINES INTO PROJECT, OVERWRITING OUTLINES OF SAME NAME ****

procedure TveOutlinesFromClipboard.PasteOverwrite( Project : TveProject );
var
    Name, Value : string;
    NewOutline : TveOutline;
    OldDuplicateOutline : TveOutline;
begin
    // parse stream into outline sections, & create an outline for each
    while NameValueFromStream( FStream, Name, Value ) do begin

        // look for "Outline" at start of line
        if Name = 'Outline' then begin

            NewOutline := nil;

            // create an object of the required class, and ask it to initialise
            // from the stream
            if Value = 'TveLeadedOutline' then begin
                NewOutline := TveLeadedOutline.Create;
                NewOutline.ReadFromStream( FStream );
            end
            else if Value = 'TveRadialOutline' then begin
                NewOutline := TveRadialOutline.Create;
                NewOutline.ReadFromStream( FStream );
            end
            else if Value = 'TveCellOutline' then begin
                NewOutline := TveCellOutline.Create;
                NewOutline.ReadFromStream( FStream );
            end
            else if Value = 'TveCustomOutline' then begin
                NewOutline := TveCustomOutline.Create;
                NewOutline.ReadFromStream( FStream );
            end;

            // if outline was created, add it to the project
            if NewOutline <> nil then begin

                // if project already contains an outline with this name, replace it
                OldDuplicateOutline := Project.OutlineByName( NewOutline.Name );
                if OldDuplicateOutline <> nil then begin
                    Project.ReplaceOutline( OldDuplicateOutline, NewOutline );
                end

                // else just add a new outline to the project
                else begin
                    Project.AddOutline( NewOutline );
                end;

            end;
        end;
    end;
end;


// **** PASTE ONE OUTLINE INTO ANOTHER TARGET OUTLINE, KEEPING NAME OF TARGET ****
procedure TveOutlinesFromClipboard.PasteInto(
    Project : TveProject; Target : TveOutline; var NewOutline : TveOutline );
var
    Temp : integer;
    Name, Value : string;
begin
    // var parameter must indicate the new outline which replaces the target
    NewOutline := nil;

    // check that Target belongs to Project
    Temp := Project.IndexOfOutline(Target);
    if Temp = -1 then begin
        exit;
    end;
{   This code doesn't work.
    if (Project.IndexOfOutline(Target) = -1) then begin
        exit;
    end;
}
    // parse stream into outline sections, & create an outline for each
    while NameValueFromStream( FStream, Name, Value ) do begin

        // look for "Outline" at start of line
        if Name = 'Outline' then begin

            // create an object of the required class, and ask it to initialise
            // from the stream
            if Value = 'TveLeadedOutline' then begin
                NewOutline := TveLeadedOutline.Create;
                NewOutline.ReadFromStream( FStream );
            end
            else if Value = 'TveRadialOutline' then begin
                NewOutline := TveRadialOutline.Create;
                NewOutline.ReadFromStream( FStream );
            end
            else if Value = 'TveCellOutline' then begin
                NewOutline := TveCellOutline.Create;
                NewOutline.ReadFromStream( FStream );
            end
            else if Value = 'TveCustomOutline' then begin
                NewOutline := TveCustomOutline.Create;
                NewOutline.ReadFromStream( FStream );
            end;


            // if outline was created, add it to the project
            if NewOutline <> nil then begin

                // give the new outline the same name as the target
                NewOutline.Name := Target.Name;
                Project.ReplaceOutline( Target, NewOutline );
            end;

            // job done - finish up

            exit;
        end;
    end;
end;



initialization

{$IFDEF DEBUG}
    // put data onto clipboard in CF_TEXT so can paste into Notepad for debug.
    ClipboardFormat := CF_UNICODETEXT;
{$ELSE}
    ClipboardFormat := RegisterClipboardFormat( 'VeeCAD Outline' );
{$ENDIF}
end.


