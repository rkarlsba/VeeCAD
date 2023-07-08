unit NetReader;

interface

uses Classes, SysUtils, ExceptSafe;

// All netlist files are read through a TNetReader descendant.  There is a
// descendant for every netlist file format : Protel, Wirelist, PADS etc.

// Single piece of high level code can be passed any TNetReader descendant
// and perform the tricky net assignment stuff regardless of file format.

// The payoff is that the low level TNetReaders need not be touched once
// they are debugged.  The high level stuff is tweaked as desired and tested
// using any single format !

type ETveNetReader = class( Exception );
     ESafeTveNetReader = class( ESafe );

type TveNetReader = class

protected

    FileName : string;
    Lines : TStringList;
    Line : string;
    LineIndex : integer;
    LineLimit : integer;
    FLineBased : boolean;
    FCurrentLine : integer;

    function GetNetlistDescriptor : string; virtual; abstract;
    function GetCurrentLine : integer; virtual;

public
    property NetlistDescriptor : string read GetNetlistDescriptor;
    property LineBased : boolean read FLineBased;
    property CurrentLine : integer read GetCurrentLine;

    procedure ReadFile( const FileName : string ); virtual;
    function CheckCompatibility : boolean; virtual; abstract;

    procedure ToFirstComponent; virtual; abstract;
    function GetNextComponent( var Designator, Value, Outline : string ) : boolean;
        virtual; abstract;
    procedure ToFirstConnection; virtual; abstract;
    function GetNextConnection( var NetName, Designator, PinName : string )
        : boolean; virtual; abstract;

    constructor Create; virtual;
    destructor Destroy; override;
end;


implementation

procedure TveNetReader.ReadFile( const FileName : string );
begin
    // assume netlist is Ansi, same as system default (TEndocding.Default)
    try
        Lines.LoadFromFile( FileName, TEncoding.Default );
    except
        On E : Exception do begin
            raise ESafeTveNetReader.Create( E.Message );
        end;
    end;

    // we may need ReadFileAnsi and ReadFileUtf8, but for now all is Ansi
    //    Lines.LoadFromFile( FileName, TEncoding.UTF8 );

    LineLimit := Lines.Count;
end;

function TveNetReader.GetCurrentLine : integer;
begin
    result := FCurrentLine;
end;

constructor TveNetReader.Create;
begin
    Lines := TStringList.Create;
    FLineBased := True;
end;

destructor TveNetReader.Destroy;
begin
    Lines.Free;
    inherited;
end;


end.
