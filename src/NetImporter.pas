unit NetImporter;

interface

uses Project, NetReader, Adjuster, SysUtils, Classes, Outlines, ExceptSafe;

type ETveNetImporter = class( Exception );
type ESafeNetImporter = class( ESafe );

type TveNetImporter = class
protected

    FProject : TveProject;
    FNetReader : TveNetReader;
    ItemAdjuster : TBoardItemAdjuster;
    FLibraries : TList;

    function LibraryOutlineByName( const Name : string ) : TveOutline;
    procedure LoadComponents;
    procedure LoadNets;

    // property providers
    function GetLibraryCount : integer;
    function GetLibrary(index : integer) : TveProject;

public

    property LibraryCount : integer read GetLibraryCount;
    property Libraries[ index : integer ] : TveProject read GetLibrary;
    procedure AddLibrary( LibProject : TveProject );

    property Project : TveProject read FProject write FProject;
    property NetReader : TveNetReader read FNetReader write FNetReader;

    constructor Create;
    destructor Destroy;  override;

    procedure Execute;
end;

implementation

uses Netlist, SizeableOutlines;

const FReplaceOutlines = True;

constructor TveNetImporter.Create;
begin
    ItemAdjuster := TBoardItemAdjuster.Create;
    FLibraries := TList.Create;
end;


destructor TveNetImporter.Destroy;
var
    i : integer;
begin
    ItemAdjuster.Free;
    for i := FLibraries.Count -1 downto 0 do begin
        TveProject(FLibraries[i]).Free;
    end;
    FLibraries.Free;
end;

// *****************************************
//      Manage a Group of Libraries
// *****************************************


function TveNetImporter.GetLibraryCount : integer;
begin
    result := FLibraries.Count;
end;

function TveNetImporter.GetLibrary( index : integer ) : TveProject;
begin
    result := TveProject( FLibraries[index] );
end;

procedure TveNetImporter.AddLibrary( LibProject : TveProject );
begin
    FLibraries.Add( LibProject );
end;


// *************************************************
//    FIND FIRST LIBRARY OUTLINE MATCHING NAME
// *************************************************

function TveNetImporter.LibraryOutlineByName( const Name : string ) : TveOutline;
var
    LibIndex : integer;    
begin
    result := nil;
    for LibIndex := 0 to LibraryCount -1 do begin
        result := Libraries[LibIndex].OutlineByName( Name );
        if result <> nil then begin
            exit;
        end;
    end;
end;


// *************************************************
//    DEFINE COMPONENT OBJECTS AS LISTED IN NETLIST
// *************************************************

procedure TveNetImporter.LoadComponents;

var
    Designator : string;
    Value : string;
    Outline : string;


    procedure LoadComponent;
    var
        Component : TneComponent;
        BoardItem : TveBoardItem;
        DefaultOutline : TveOutline;
        NewComponent : boolean;
        ProjectOutline : TveOutline;
        LibraryOutline : TveOutline;
        CloneOutline : TveOutline;
    begin
        // must have designator (eg 'C1', 'Q2') - other fields can be blank
        // OR could give a dummy designator or no designator ??
        // OR raise an exception.
        Designator := Trim( Designator );
        if (Designator = '') then begin

            if FNetReader.LineBased then begin
                raise ESafeNetImporter.CreateFmt(
                '%s netlist error : component on line %d has blank Designator',
                [FNetReader.NetlistDescriptor, FNetReader.CurrentLine]
                );
            end

            else begin
                raise ESafeNetImporter.CreateFmt(
                '%s netlist error : component with blank Designator',
                [FNetReader.NetlistDescriptor]
                );
            end;
        end;

        // try to find existing item with same designator
        BoardItem := FProject.ItemByDesignator( Designator );
        NewComponent := BoardItem = nil;

        // if component doesn't already exist, make it
        if NewComponent then begin

            // put component into board
            BoardItem := TveBoardItem.Create;
            FProject.AddBoardItem( BoardItem );
            BoardItem.Designator := Designator;
        end;

        // use latest Value (eg "100R") from schematic
        BoardItem.Value := Value;

        // put component into netlist
        Component := FProject.Netlist.CreateComponent;
        Component.Name := Designator;


        // ** give item an outline - must have one **

        // look for outline on board
        ProjectOutline := FProject.OutlineByName( Outline );

        // If Outline in project or project contains NoImport flagged outline or
        // project already contains updated outline then use project outline.
        // This is most common case, so we optimise by doing it first.
        if (ProjectOutline <> nil) and
            (Projectoutline.ReservedUpdated or ProjectOutline.NoImport) then begin

            BoardItem.Outline := ProjectOutline;
            if NewComponent then begin
                ProjectOutline.LocateTextDefault( BoardItem );
            end;
            exit;
        end;


        // the tricky cases follow

        // look for outline in libraries
        LibraryOutline := LibraryOutlineByName( Outline );

        // no library outline available
        if LibraryOutline = nil then begin

            // project outline available, but nothing in library: use project
            if ProjectOutline <> nil then begin
                BoardItem.Outline := ProjectOutline;
                if NewComponent then begin
                    ProjectOutline.LocateTextDefault( BoardItem );
                end;
                // save searching libraries again during this import
                ProjectOutline.ReservedUpdated := True;
                exit;
            end

            // no outline in project or libraries, make a clean one
            else begin
                // make an outline type
                DefaultOutline := FProject.AddDefaultOutline;
                DefaultOutline.Name := Outline;
                BoardItem.Outline := DefaultOutline;
                if NewComponent then begin
                    DefaultOutline.LocateTextDefault( BoardItem );
                end;
                // save searching libraries again during this import
                DefaultOutline.ReservedUpdated := True;
                exit;
            end;
        end;

        // at this stage, we definitely have a library outline and we have to
        // use it.

        // make a duplicate of the library outline: we cannot add a reference
        // to the existing one, because we will destroy the library
        CloneOutline := LibraryOutline.Clone;

        if CloneOutline = nil then begin
            // fatal error, close VeeCAD
            raise ETveNetImporter.Create(
            'Net Importer internal error : Cloned outline = nil'
            );
        end;

        // no existing outline of this name, so just add new one
        if ProjectOutline = nil then begin
            FProject.AddOutline( CloneOutline );
            BoardItem.Outline := CloneOutline;
            if NewComponent then begin
                CloneOutline.LocateTextDefault( BoardItem );
            end;
            // save searching libraries again during this import
            CloneOutline.ReservedUpdated := True;
            exit;
        end;

        // we must replace the existing project outline with the clone outline
        BoardItem.Outline := CloneOutline;
        if NewComponent then begin
            CloneOutline.LocateTextDefault( BoardItem );
        end;
        FProject.ReplaceOutline( ProjectOutline, CloneOutline );
        //... save searching libraries again during this import
        CloneOutline.ReservedUpdated := True;
    end;

var
    i : integer;

begin
    // mark all outlines as not updated
    for i := 0 to FProject.OutlineCount -1 do begin
        FProject.Outlines[i].ReservedUpdated := False;
    end;

    // load components
    NetReader.ToFirstComponent;
    while NetReader.GetNextComponent( Designator, Value, Outline ) do begin
        LoadComponent;
    end;
end;


procedure TveNetImporter.LoadNets;
var
    Netlist : TneNetlist;

    NetName : string;
    Designator : string;
    PinName : string;

    procedure LoadConnection;
    var
        Net : TneNode;
        Component : TneComponent;
    begin

        // check valid net name
        NetName := Trim( NetName );
        if NetName = '' then begin
            if FNetReader.LineBased then begin
                raise ESafeNetImporter.CreateFmt(
                '%s netlist error : net with blank name on line %d',
                [FNetReader.NetlistDescriptor, FNetReader.CurrentLine]
                );
            end
            else begin
                raise ESafeNetImporter.CreateFmt(
                '%s netlist error : net with blank name',
                [FNetReader.NetlistDescriptor]
                );
            end;
        end;

        // see if net exists already
        Net := Netlist.NodeByName( NetName );

        // existing net not found, so create one
        if Net = nil then begin
            // put new node in netlist
            Net := Netlist.CreateNode;
            Net.Name := NetName;
        end;


       // find the component in the component list
        Component := Netlist.ComponentByName( Designator );
        if Component = nil then begin
            if FNetReader.LineBased then begin
                raise ESafeNetImporter.CreateFmt(
                '%s netlist error : Net %s on line %d requires component %s but component not defined',
                [FNetReader.NetlistDescriptor, NetName, FNetReader.CurrentLine, Designator]
                );
            end
            else begin
                raise ESafeNetImporter.CreateFmt(
                '%s netlist error : Net %s requires component %s but component not defined',
                [FNetReader.NetlistDescriptor, NetName, Designator]
                );
            end;
        end;

        // add pin connecting the component to the node
        Netlist.CreatePin( Net, Component, PinName );
    end;
begin

    Netlist := FProject.Netlist;

    // load components
    NetReader.ToFirstConnection;
    while NetReader.GetNextConnection( NetName, Designator, PinName ) do begin

        // test pin name
        if (PinName = '') then begin
            if FNetReader.LineBased then begin
                raise ESafeNetImporter.CreateFmt(
                '%s netlist error on line %d: Component %s has blank pin name',
                [FNetReader.NetlistDescriptor, FNetReader.CurrentLine, Designator]
                );
            end;
        end;

        LoadConnection;
    end;
end;


// *** IMPORT NETLIST TO PROJECT USING NETREADER ***

// NetReader must have had ReadFile() called.
// Project will have existing nets cleared, even if import process fails.
(*
procedure TveNetImporter.Execute;
begin

    // must be correct file format for TveNetReader descendant in use
    if not NetReader.CheckCompatibility then begin
        raise ESafeNetImporter.CreateFmt(
            'Netlist not %s type', [NetReader.NetlistDescriptor]
        );
    end;

    // make a note of netlist format used for this import
    Project.NetlistImportFormat := NetReader.NetlistDescriptor;

    // clear existing netlist
    FProject.ClearFastNets;
    FProject.ClearNetlist;

    // mark components for adjust

    // Do Mark before reassigning outlines to components, then do Adjust after.
    // Reason - some components need altering when an outline type swapped or
    // assigned after Creation - especially for Sizeable outlines.
    ItemAdjuster.MarkComponents( FProject );

    // load components section of file
    LoadComponents;

    // adjust components with new/changed outlines
    ItemAdjuster.AdjustComponents;

    // load nets section of file
    LoadNets;

    // housekeeping gets Project ready for use
    FProject.TransferFastNets;
end;
*)

procedure TveNetImporter.Execute;
var
    TempNetlist : TneNetlist;
begin

    // must be correct file format for TveNetReader descendant in use
    if not NetReader.CheckCompatibility then begin
        raise ESafeNetImporter.CreateFmt(
            'Netlist not %s type', [NetReader.NetlistDescriptor]
        );
    end;

    // make a note of netlist format used for this import
    Project.NetlistImportFormat := NetReader.NetlistDescriptor;

    // create a temporary netlist
    TempNetlist := TneNetlist.Create;
    try
        // copy the current netlist into the temporary netlist - we will use
        // the temporary netlist for netlist matching later on
        TempNetlist.Clone( Project.NetList );

        // clear existing netlist
        FProject.ClearFastNets;
        FProject.ClearNetlist;

        // mark components for adjust

        // Do Mark before reassigning outlines to components, then do Adjust after.
        // Reason - some components need altering when an outline type swapped or
        // assigned after Creation - especially for Sizeable outlines.
        ItemAdjuster.MarkComponents( FProject );

        // load components section of file
        LoadComponents;

        // adjust components with new/changed outlines
        ItemAdjuster.AdjustComponents;

        // load nets section of file
        LoadNets;

        // housekeeping gets Project ready for use
        FProject.TransferFastNets;

        // ** now we must find the ColoredNets[] in our new netlist that
        // ** correspond with the ColoredNets[] in our old netlist
        FProject.NetList.GetEquivalentColoredNets( TempNetlist );

    finally
        TempNetlist.Free;
    end;
end;

{$IFDEF 0}
LibraryOutline := FLibrary.OutlineByName( Outline );
ProjectOutline := FProject.OutlineByName( Outline );


Need list of updated outlines, or a tag field for outlines.


1. Import components when a component requires and outline :

If Outline in project and (projectoutline.updated or projectoutline.noreplace)
    then use project outline.

If Outline in project and not (projectoutline.updated or projectoutline.noreplace)
then clone library outline, replace project outline with cloned version and
rewrite outline member in every component which references the old outline. Delete
old outline.

If Outline not in project, then clone library outline, add outline to project.


{$ENDIF}


end.


