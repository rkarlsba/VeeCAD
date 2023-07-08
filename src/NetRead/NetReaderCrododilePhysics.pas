unit NetReaderCrododilePhysics;

interface

uses NetReader, Classes;

// Low level access to Protel Netlist files.

type TCrododilePhysicsNetReader = class( TveNetReader )

protected
    ComponentNames : TStringlist;

{
    CurrentNet : string;
    HaveNet : boolean;
}
    function GetNetlistDescriptor : string; override;
    function ComponentNameToOutline( const ComponentName : string ) : string;
    {
    procedure ParseNetLine(
        LineIndex : integer; const Line : string;
        var Designator : string; var PinNo : Integer ); virtual;
}


public
    function CheckCompatibility : boolean; override;
    procedure ReadFile( const FileName : string ); override;
    procedure ToFirstComponent; override;
    function GetNextComponent( var Designator, Value, Outline : string ) : boolean;
        override;
    procedure ToFirstConnection; override;
    function GetNextConnection( var NetName, Designator, PinName : string )
        : boolean; override;

    constructor Create; override;
    destructor Destroy; override;
end;

implementation

uses SysUtils, ParseCsv, ExceptSafe;

type ESafeCrocodileReader = class( ESafe );

// Remove quotes from start, end of string.
// We assume that the quotes do exist.
function DeQuote( const s : string ) : string;
begin
    if length(s) >= 2 then begin
        result := copy( s, 2, length(s) - 2);
    end;
end;


// Find the Outline name to use, given the Croc Physics "Component Name" string
// Looks up ComponentNames[] TStrings which contains Name,Value pairs.
// We use this code because the TStrings.Values[] and IndexOfName() never found
// a name match.
function TCrododilePhysicsNetReader.ComponentNameToOutline(
    const ComponentName : string ) : string;
var
    i : integer;
    Name : string;
    Line : string;
begin
    Name := UpperCase( ComponentName ) + ',';
    for i := 0 to ComponentNames.Count - 1 do begin
        Line := UpperCase( ComponentNames[i] );
        if( Pos( Name, Line ) = 1) then begin
            result := Copy( Line, Length(Name) +1, 100 );
            exit;
        end;
    end;

    // no match found
    result := '';
end;


constructor TCrododilePhysicsNetReader.Create;
begin
    inherited;
    ComponentNames := TStringlist.Create;
end;

destructor TCrododilePhysicsNetReader.Destroy;
begin
    ComponentNames.Free;
    inherited;
end;

function TCrododilePhysicsNetReader.CheckCompatibility : boolean;
begin
    // look for header
    result := Trim(Lines[0]) = 'FORMAT,CROCODILENETLIST,1';
end;

function TCrododilePhysicsNetReader.GetNetlistDescriptor : string;
begin
    result := 'CrocodilePhysics';
end;

procedure TCrododilePhysicsNetReader.ReadFile( const FileName : string );
var
    ComponentNamesFileName : string;
begin
    // ComponentNames file 2 csv fields per line
    ComponentNamesFileName := ExtractFilePath(ParamStr(0)) + 'Library\CrocodileParts.txt';
    try
        ComponentNames.LoadFromFile( ComponentNamesFileName );
    except
        On EFOpenError do begin
            raise ESafeCrocodileReader.CreateFmt(
            'Cannot open Crocodile Physics parts definition file: %s',
            [ComponentNamesFileName] )
        end;
    end;

    // now do standard read into Lines[] TStringList
    inherited ReadFile( FileName );
end;


procedure TCrododilePhysicsNetReader.ToFirstComponent;
begin
    LineIndex := 0;
end;

function TCrododilePhysicsNetReader.GetNextComponent(
    var Designator, Value, Outline : string ) : boolean;

    // Parse Croc Physics component line of form:
    // COMPONENT,C1,"Electrolytic Capacitor","Passive components.cml","0.0001"
    procedure LoadComponent;
    var
        Index : integer;
        field : string;
        ComponentName : string;
    begin
        // skip first field, "COMPONENT"
        Index := 0;
        ParseCsvValue( Line, field, Index );

        // Parse Component Designator C1 etc (not in " quotes)
        ParseCsvValue( Line, Designator, Index );

        // parse what Croc Physics calls the "Component Name" ie. Type
        // "Capacitor (polyester)" etc
        ParseCsvValue( Line, ComponentName, Index );
        ComponentName := DeQuote(Trim( ComponentName ));
        if ComponentName = '' then begin
            raise ESafeCrocodileReader.CreateFmt(
            'Empty Component Name found in line %d',
            [LineIndex + 1] );
        end;

        // lookup "Component Name" in list and get appropriate footprint
        // TStrings.Values[] did not work for some reason
        //Outline := ComponentNames.Values[ ComponentName ];
        Outline := ComponentNameToOutline( ComponentName );

        // skip cml file "Passive components.cml" etc
        ParseCsvValue( Line, field, Index );

        // parse component value "0.0001" for 100uF electro, etc
        ParseCsvValue( Line, field, Index );
        Value := DeQuote( field );
        //.. if we have a blank value, show the ComponentName field - typically
        // this is the part number of an IC. Show in quotes because this can
        // be multiple words        
        if Value = '' then begin
            Value := '"' + ComponentName + '"';
        end;

   end;

begin
    // search for next component
    while LineIndex < LineLimit do begin

        Line := Lines[LineIndex];

        if Pos( 'COMPONENT,', Line ) =  1 then begin
            LoadComponent;
            Inc( LineIndex );
            FCurrentLine := LineIndex;
            result := True;
            exit;
        end;

        Inc( LineIndex );
    end;

    // no component loaded - at end of file
    result := False;
end;

procedure TCrododilePhysicsNetReader.ToFirstConnection;
begin
    LineIndex := 0;
end;

function TCrododilePhysicsNetReader.GetNextConnection(
    var NetName, Designator, PinName : string ) : boolean;

    // Parse Croc Physics component line of form:
    // PIN,C1,2,"N006"
    procedure LoadNet;
    var
        index : integer;
        field : string;
    begin
        // initialise CSV parser
        index := 0;

        // skip first field "PIN"
        ParseCsvValue( Line, field, Index );

        // parse designator
        ParseCsvValue( Line, Designator, Index );

        // parse pin No.
        ParseCsvValue( Line, field, Index );

        PinName := field;

        // parse net name
        ParseCsvValue( Line, field, Index );
        NetName := DeQuote( field );
    end;

begin
    // search for next net
    while LineIndex < LineLimit do begin

        Line := Lines[LineIndex];

        if Pos( 'PIN,', Line ) =  1 then begin
            LoadNet;
            Inc( LineIndex );
            FCurrentLine := LineIndex;
            result := True;
            exit;
        end;

        Inc( LineIndex );
    end;

    // no net loaded - at end of file
    result := False;
end;

end.
