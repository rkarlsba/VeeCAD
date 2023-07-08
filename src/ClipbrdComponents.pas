unit ClipbrdComponents;

interface

uses Classes, Project, Outlines;

type TveComponentsToClipboard = class
  protected
    FStream : TMemoryStream;
    FProject : TveProject;
    FOutlines : TList;
  public
    procedure CopySelected( Project : TveProject );
    constructor Create;
    destructor Destroy; override;
end;

type TveComponentsFromClipboard = class
  protected
    FStream : TMemoryStream;
    FProject : TveProject;
    FOutlines : TList;
    FComponents : TList;
    PasteHandle : integer;
    PasteTime : integer;
    // offsets to add to pasted component positions
    function BuiltInOutlineFromStream( const ClassName : string ) : TveOutline;
    function DefinedOutlineFromStream( const ClassName : string ) : TveOutline;
    procedure PositionComponents;
  public
    procedure Paste( Project : TveProject; DuplicateIdentifiers : boolean = False );
    constructor Create;
    destructor Destroy; override;
end;


procedure CopySelectedToClipboard( Project : TveProject );
procedure PasteComponentsFromClipboard( Project : TveProject );
procedure PasteComponentsFromClipboardWithDuplicateIdentifiers( Project : TveProject );


implementation

uses SysUtils, ClipbrdUtils, Windows,
    OtherOutlines, SizeableOutlines, RadialOutlines, CelledOutlines,
    CustomOutlines, SmdOutlines, BoardSize, Forms, ExceptSafe;

var
    ClipboardFormat : Word;

type EClipboardComponents = class( Exception );
     ESafeClipboardComponents = class( ESafe );

// *********************************************
//        TveComponentsToClipboard
// *********************************************

constructor TveComponentsToClipboard.Create;
begin
    FStream := TMemoryStream.Create;
    FOutlines := TList.Create;
end;

destructor TveComponentsToClipboard.Destroy;
begin
    FStream.Free;
    FOutlines.Free;
    inherited;
end;

// ** COPY SELECTED COMPONENTS TO CLIPBOARD **

procedure TveComponentsToClipboard.CopySelected( Project : TveProject );
var
    i : integer;
    Component : TveBoardItem;
    OutlineIndex : integer;
begin
    // must have a project
    if Project = nil then begin
        exit;
    end;

    // initialise
    FProject := Project;
    FStream.Size := 0;

    // write header for clipboard
    LineToStream( FStream, 'VeeCADComponents' );

    // handle identifies the VeeCAD instance putting data to clipboard
    // 32 bit unsigned - interpret it as unsigned, so StrToInt will read it later
    LineToStream( FStream, Format('Handle=%10.10d', [integer(Application.Handle)]) );

    // Timestamp identifies which copy event placed this data. Allows Paste
    // do detect repeat pastes of same data and move that data.
    // 32 bit unsigned - interpret it as unsigned, so StrToInt will read it later
    LineToStream( FStream, Format('Time=%10.10d', [integer(GetTickCount)]) );

    // write outlines to clipboard data
    LineToStream( FStream, 'Outlines' );

    // find all outlines used in project
    FOutlines.Count := 0;
    for i := 0 to FProject.BoardItemCount - 1 do begin
        Component := FProject.BoardItems[i];
        if Component.Selected then begin
            // if outline not already in our list
            if FOutlines.IndexOf( Component.Outline ) <= 0 then begin

                // put it in our list
                FOutlines.Add( Component.Outline );
                // write it for clipboard
                Component.Outline.WriteToStream( FStream );
            end;
        end;
    end;

    // outlines are finished
    LineToStream( FStream, 'end' );

    // write components to stream
    LineToStream( FStream, 'Components' );
    for i := 0 to FProject.BoardItemCount - 1 do begin
        Component := FProject.BoardItems[i];
        if Component.Selected then begin
            // if outline not already in our list
            Component.WriteToStream( FStream );
        end;
    end;
    LineToStream( FStream, 'end' );

    // In same order as components are written, write indexs of outlines used by
    // components : 0 means first outline in outlines list, etc.
    LineToStream( FStream, 'components outlines' );
    for i := 0 to FProject.BoardItemCount - 1 do begin
        Component := FProject.BoardItems[i];
        if Component.Selected then begin

            // lookup outline in list
            OutlineIndex := FOutlines.IndexOf( Component.Outline );

            // outline not in list - !! - something broken
            if OutlineIndex < 0 then begin
                raise Exception.Create( 'Internal error listing outine indexes' );
            end;
            LineToStream( FStream, IntToStr( OutlineIndex ) );
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

// ** SIMPLE FUNCTION CALL PROVIDES SELECTED COMPONENTS COPY TO CLIPBOARD **

procedure CopySelectedToClipboard( Project : TveProject );
var
    Copier : TveComponentsToClipboard;
begin
    Copier := TveComponentsToClipboard.Create;
    try
        Copier.CopySelected( Project );
    finally
        Copier.Free;
    end;
end;


// *********************************************
//        TveComponentsFromClipboard
// *********************************************

constructor TveComponentsFromClipboard.Create;
begin
    FStream := TMemoryStream.Create;
    FOutlines := TList.Create;
    FComponents := TList.Create;
end;

destructor TveComponentsFromClipboard.Destroy;
begin
    FStream.Free;
    FOutlines.Free;
    FComponents.Free;
end;

// ** READ A BUILT-IN OUTLINE FROM STREAM **

function TveComponentsFromClipboard.BuiltInOutlineFromStream(
    const ClassName : string ) : TveOutline;
begin
    // if object is simple Outline, then supply a reference to the one which
    // is used by all components
    if ClassName = 'TveBreakOutline' then begin
        result := FProject.BreakOutline;
    end
    else if ClassName = 'TveLinkOutline' then begin
        result := FProject.LinkOutline;
    end
    else if ClassName = 'TveWireOutline' then begin
        result := FProject.WireOutline;
    end
    else if ClassName = 'TveTextOutline' then begin
        result := FProject.TextOutline;
    end
    else if ClassName = 'TveDummyOutline' then begin
        result := FProject.DummyOutline;
    end
    else begin
        result := nil;
        exit;
    end;

    // get results to read its properties from stream
    result.ReadFromStream( FStream );
end;

// ** READ A USER-DEFINE OUTLINE FROM STREAM

function TveComponentsFromClipboard.DefinedOutlineFromStream(
    const ClassName : string ) : TveOutline;
var
    ProjectOutline : TveOutline;
    i : integer;
    UseFromProject : boolean;
begin

    // create an object of the required class, and ask it to initialise
    // from the stream
    if ClassName = 'TveLeadedOutline' then begin
        result := TveLeadedOutline.Create;
    end
    else if ClassName = 'TveRadialOutline' then begin
        result := TveRadialOutline.Create;
    end
    else if ClassName = 'TveCellOutline' then begin
        result := TveCellOutline.Create;
    end
    else if ClassName = 'TveCustomOutline' then begin
        result := TveCustomOutline.Create;
    end
    else if ClassName = 'TveSmdOutline' then begin
        result := TveSmdOutline.Create;
    end
    else begin
        result := nil;
        exit;
    end;

    // get results to read its properties from stream
    result.ReadFromStream( FStream );

    // replace the streamed outline with an existing outline from the project
    // if available
    UseFromProject := False;
    for i := 0 to FProject.OutlineCount -1 do begin
        ProjectOutline := FProject.Outlines[i];

        //.. look for a project outline with same name and identical properties
        if  (result.Name = ProjectOutline.Name) and
             result.Identical(ProjectOutline) then begin
            UseFromProject := True;

            // delete our created outline
            result.Free;
            // and use the outline already in the project
            result := ProjectOutline;
            break;
        end;
    end;

    // our new outline must not clash with name of another outline already in
    // project
    if not UseFromProject then begin
        result.Name := FProject.MakeOutlineNameUnique( result.Name );
        FProject.AddOutline( result );
    end;
end;


// Move Components to New Positions.
// The components created have the same X,Y as the originals - and this must
// be changed else components will overly the original parts.  Or if originals
// are from a separate VeeCAD instance, position might be unsuitable or off-
// board.

procedure TveComponentsFromClipboard.PositionComponents;
var
    SameInstance : boolean;
    RepeatPaste : boolean;
    DeltaX, DeltaY : integer;
    PasteRect : TRect;
    ComponentIndex : integer;
    NewComponent : TveBoardItem;
begin
    // Is this paste from same or different instance of VeeCAD
    SameInstance := PasteHandle = integer(Application.Handle);

    // is this paste a repeate of an initial paste?
    RepeatPaste := PasteTime = integer(FProject.PasteID);

    // now update project
//    FProject.PasteHandle := PasteHandle;
    FProject.PasteID := PasteTime;

    // * Initial Paste of this block of components

    if (not RepeatPaste) then begin

        if SameInstance then begin
            // position pasted items 1 across, 1 down from original items position
            FProject.PasteOffsetX := 1;
            FProject.PasteOffsetY := 1;
            DeltaX := 1;
            DeltaY := 1;
        end

        // pasting from a different instance
        else begin
            // position at top left
            FProject.GetSelectedItemsBoundary( PasteRect );
            FProject.PasteOffsetX := - PasteRect.Left;
            FProject.PasteOffsetY := - PasteRect.Top;
            DeltaX := FProject.PasteOffsetX;
            DeltaY := FProject.PasteOffsetY;
        end;
    end

    // * Repeat Paste
    else begin

        // position pasted items 1 across, 1 down from last paste position
        FProject.PasteOffsetX := FProject.PasteOffsetX + 1;
        FProject.PasteOffsetY := FProject.PasteOffsetY + 1;
        DeltaX := FProject.PasteOffsetX;
        DeltaY := FProject.PasteOffsetY;
    end;

    FProject.GetSelectedItemsBoundary( PasteRect );

    // adjust rectangle components rectangle to new position
    inc( PasteRect.Left, DeltaX );
    inc( PasteRect.Right, DeltaX );
    inc( PasteRect.Top, DeltaY );
    inc( PasteRect.Bottom, DeltaY );


    // reposition block of pasted components if necessary to pull inside
    // board boundaries
    if PasteRect.Right > FProject.BoardWidth then begin
        DeltaX := DeltaX - (FProject.BoardWidth + 1 - PasteRect.Right);
    end;

    if PasteRect.Left < 0 then begin
        DeltaX := DeltaX - PasteRect.Left;
    end;

    if PasteRect.Bottom > FProject.BoardHeight then begin
        DeltaY := DeltaY - (FProject.BoardHeight + 1 - PasteRect.Bottom);
    end;

    if PasteRect.Top < 0 then begin
        DeltaY := DeltaY - PasteRect.Top;
    end;

    // write new component positions
    for ComponentIndex := 0 to FComponents.Count - 1 do begin
        NewComponent := FComponents[ComponentIndex];
        NewComponent.X := NewComponent.X + DeltaX;
        NewComponent.Y := NewComponent.Y + DeltaY;
    end;
end;

// Paste Components from Clipboard into Project.
// Parameter DuplicateIdentifiers = True to permit pasted components to have
// same identifiers as existing components. False means alter new identifiers
// to a new value if a duplcate would occur.
{$HINTS OFF} // value assigned to NewOutline never used

procedure TveComponentsFromClipboard.Paste( Project : TveProject; DuplicateIdentifiers : boolean = False );
var
    Line : string;
    Name, Value : string;
    NewOutline : TveOutline;
    OutlineIndex : integer;
    NewComponent : TveBoardItem;
    ComponentIndex : integer;
begin
    //
    FProject := Project;

    // get the block of data off the clipboard
    ReadClipboardToMemoryStream( ClipboardFormat, FStream );

    // if nothing on the clipboard with our format, OR has zero bytes(!), then
    // nothing to paste
    if FStream.Size = 0 then begin
        exit;
    end;

    // data must start with 'VeeCADComponents'
    if (not LineFromStream( FStream, Line )) or (Line <> 'VeeCADComponents') then begin
        exit;
    end;

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

    // next section is 'Outlines'
    if (not LineFromStream( FStream, Line )) or (Line <> 'Outlines') then begin
        exit;
    end;

    // we track references to outlines here, in same order as read from stream
    FOutlines.Count := 0;

    // locate or create an outline for each outline listed in stream
    //.. prevent compiler "unitialised variable" warning
    NewOutline := nil;

    while True do begin

        // parse next outline from stream - starts with name, value pair on
        // first line of definition.
        if (not NameValueFromStream( FStream, Name, Value )) then begin

            // we are in trouble - stream is broken?
            raise EClipboardComponents.Create( 'Truncated outlines stream' );
        end;

        // "Outline" as Name portion means we have another outline definition
        // in the stream
        if Name = 'Outline' then begin

            // see if we can create a Built-in Outline
            NewOutline := BuiltInOutlineFromStream( Value );

            // otherwise, see if we can create or locate a User-Defined Outline
            if NewOutline = nil then begin
                NewOutline := DefinedOutlineFromStream( Value );
            end;

            // can't get an outline - something wrong
            if NewOutline = nil then begin
                raise EClipboardComponents.CreateFmt( 'Unknown outline: %s', [Value] );
            end;
        end

        // end of Outlines section
        else if Name = 'end' then begin
            break;
        end

        // something wrong if not an outline OR end
        else begin
            raise EClipboardComponents.Create( 'Missing "Outline" or "End" in outlines stream' );
        end;

        // we have an outline - store a reference in our Outlines List
        FOutlines.Add( NewOutline );
    end;

    // next section is 'Components'
    if (not LineFromStream( FStream, Line )) or (Line <> 'Components') then begin
        raise EClipboardComponents.Create( 'Missing "Components" stream' );
    end;

    // now create components
    FComponents.Count := 0;
    while True do begin

        // parse next component from stream - starts with name, value pair on
        // first line of definition.
        if (not NameValueFromStream( FStream, Name, Value )) then begin

            // we are in trouble - stream is broken?
            raise EClipboardComponents.Create( 'Truncated components stream' );
        end;

        // "Component" as Name portion means we have another outline definition
        // in the stream
        if Name = 'Component' then begin

            // create new component
            NewComponent := TveBoardItem.Create;
            NewComponent.ReadFromStream( FStream );

            // store ref to component in list
            FComponents.Add( NewComponent );
        end

        // end of Components section
        else if Name = 'end' then begin
            break;
        end

        // something wrong if not an
        else begin
            raise EClipboardComponents.Create( 'Expected "Component" or "End" in component stream' );
        end;
    end;

    // next section is 'components outlines' - indexes into outlines list
    if (not LineFromStream( FStream, Line )) or (Line <> 'components outlines') then begin
        exit;
    end;

    // pasted items will be shown selected, so clear existing selected items
    FProject.DeSelectAllItems;

    // read list of indexes to outlines : in same order as our compoents list
    ComponentIndex := 0;
    try
        while True do begin

            // read next line from stream
            if (not LineFromStream( FStream, Line )) then begin
                raise EClipboardComponents.Create( 'Expected end of Indexes stream' );
            end;

            // if line says "end' then we are finished indexes section
            if Line = 'end' then begin
                break;
            end;

            // line contains the index of outline to use
            OutlineIndex := StrToInt( Line );

            // apply outline to component
            NewComponent := TveBoardItem(FComponents[ComponentIndex]);
            NewComponent.Outline := FOutlines[OutlineIndex];

            // if new component is high-level "user defined" type, which appears
            // in the netlist, then prevent new component having same name as an
            // existing component
            if (not DuplicateIdentifiers) and NewComponent.Outline.UserDefined then begin
                NewComponent.Designator :=
                FProject.MakeItemDesignatorUnique( NewComponent.Designator );
            end;

            // add component to board and show as selected
            FProject.AddBoardItem( NewComponent );
            NewComponent.Selected := True;

            // to next component
            Inc( ComponentIndex );
        end;

    except
        On EConvertError do begin
            raise EClipboardComponents.Create( 'Index to Outline not read from stream' );
        end;
    end;

    // make sure we found an index for every outline
    if ComponentIndex <> FComponents.Count then begin
        raise EClipboardComponents.Create( 'Indexes missing from stream' );
    end;

    // all done - our project has outlines and components

    // work out where to place block of pasted components by setting
    // variables DeltaX, DeltaYa
    PositionComponents;

    // if components or (text) still off board, pull them onto board
    RescueOffBoardItems( FProject );


    // added components all belong to a single Undo transaction.
    Project.BeginUndo;
    for ComponentIndex := 0 to FComponents.Count - 1 do begin
        NewComponent := TveBoardItem( FComponents[ComponentIndex] );
        Project.ReleaseBoardItem( NewComponent );
        Project.AddItemToUndo( NewComponent );
    end;
    Project.EndUndo;

    // make netlisting work with new components
    FProject.TransferFastNets;

    // project altered
    FProject.Dirty := True;
end;

// Paste Components and Alter Identifiers to Prevent Duplicates
procedure PasteComponentsFromClipboard( Project : TveProject );
var
    Paster : TveComponentsFromClipboard;
begin
    Paster := TveComponentsFromClipboard.Create;
    try
        Paster.Paste( Project );
    finally
        Paster.Free;
    end;
end;
{$HINTS ON}

// Paste Components and Allow Duplicate Identifiers
procedure PasteComponentsFromClipboardWithDuplicateIdentifiers( Project : TveProject );
var
    Paster : TveComponentsFromClipboard;
begin
    Paster := TveComponentsFromClipboard.Create;
    try
        Paster.Paste( Project, True );
    finally
        Paster.Free;
    end;
end;


initialization

{$IFDEF DEBUG}
    // put data onto clipboard in CF_TEXT so can paste into Notepad for debug.
    ClipboardFormat := CF_UNICODETEXT;
{$ELSE}
    ClipboardFormat := RegisterClipboardFormat( 'VeeCAD Component' );
{$ENDIF}

end.
