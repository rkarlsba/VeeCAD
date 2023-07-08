unit NetReaderWirelist;

interface

uses NetReader;

// Low level access to Wirelist Netlist files.

type TWirelistNetReader = class( TveNetReader )

protected
    CurrentNet : string;
    HaveNet : boolean;
    function GetNetlistDescriptor : string; override;

public
    function CheckCompatibility : boolean; override;

    procedure ToFirstComponent; override;
    function GetNextComponent( var Designator, Value, Outline : string ) : boolean;
        override;
    procedure ToFirstConnection; override;
    function GetNextConnection( var NetName, Designator, PinName : string )
        : boolean; override;

//    constructor Create; virtual;
//    destructor Destroy; override;
end;

implementation

uses SysUtils;

function DeComma( const S : string ) : string;
var
    i : integer;
begin
    result := S;
    for i := 1 to Length(S) do begin
        if result[i] = ',' then begin
            result[i] := '_';
        end;
    end;
end;


function TWirelistNetReader.GetNetlistDescriptor : string;
begin
    result := 'Wirelist';
end;

function TWirelistNetReader.CheckCompatibility : boolean;
begin
    result := True;
end;


procedure TWirelistNetReader.ToFirstComponent;
var
    i : integer;
begin
    // go to line after "<<< Component List >>>"
    for i := 0 to LineLimit -1 do begin
        if Trim(Lines[i]) = '<<< Component List >>>' then begin
            FCurrentLine := i;
            LineIndex := i + 1;
            exit;
        end;
    end;
    // components section not found in file
    raise ESafeTveNetReader.CreateFmt(
        'Can''''t find text "<<< Component List >>>" in netlist file',
        [LineIndex + 1]
        );
end;

procedure ParseComponentLine( const Line : string;
    var Value, Designator, PartType : string );
begin
    Value := DeComma(Trim( Copy( Line, 1, 30 )));
    Designator := DeComma(Trim( Copy( Line, 31, 10 )));
    PartType := DeComma(Trim( Copy( Line, 41, 30 )));
end;


function TWirelistNetReader.GetNextComponent( var Designator, Value, Outline : string ) : boolean;

    procedure LoadComponent;
    begin
        // split line into 3 fields
        ParseComponentLine( Line, Value, Designator, Outline );
    end;

var
    LineTrim : string;

begin
    // search for next component
    while LineIndex < LineLimit do begin

        Line := Lines[LineIndex];
        LineTrim := Trim( Line );
        if (LineTrim = '') or (Copy(LineTrim, 1, 3) = '<<<') then begin
            break;
        end;

        FCurrentLine := LineIndex;
        LoadComponent;
        Inc( LineIndex );
        result := True;
        exit;
    end;

    // no component loaded - at end of file or end of components section
    result := False;
end;

procedure TWirelistNetReader.ToFirstConnection;
var
    i : integer;
begin
    // we don't have net       
     HaveNet := False;

    // go to 3rd line after "<<< Wire List >>>", thus skipping column headings
    for i := 0 to LineLimit -1 do begin
        if Trim(Lines[i]) = '<<< Wire List >>>' then begin
            FCurrentLine := i;
            LineIndex := i + 3;
            exit;
        end;
    end;

    // nets section not found in file
    raise ESafeTveNetReader.CreateFmt(
        'Can''''t find text "<<< Wire List >>>" in netlist file',
        [LineIndex + 1]
        );
end;


(*
Net lines consist of three types :

1. Net Name Line

[00001] NC_00

2. Pin No. Line
        U1              1       1               Passive        Value

3. Blank Line before next Net Line

for example,
[00028] MY_NET
        U1              28      28              Passive        Value
        C1              1       A               Passive        C

[00002] GND
        U1              2       2               Passive        Value
*)

(*
ParseNetLine

returns either
1. Node Name Field (eg MY_NET) with other fields blank if a Net Name Line.
2. PinNo, Designataor fields if a Pin No. Line.
if called on a blank line, get all fields empty.
*)

procedure ParseNetLine( const Line : string; var NetName, Designator, PinNo  : string );
begin
    // if a Node Name Field
    if Line[1] = '[' then begin
        NetName := DeComma(Trim( Copy( Line, 9, 255 )));
        PinNo := '';
        Designator := '';
    end

    // else must be a Pin No. field
    else begin
        NetName := '';
        Designator := DeComma(Trim( Copy( Line, 9, 16 )));
        PinNo := Trim( Copy( Line, 21, 8 ));
    end;
end;


function TWirelistNetReader.GetNextConnection(
    var NetName, Designator, PinName : string ) : boolean;

label loop;
var
    LineTrim : string;
    PinTemp : string;
    NetNameTemp : string;
    DesignatorTemp : string;
begin
    // search for next component
    while LineIndex < LineLimit do begin

        Line := Lines[ LineIndex ];

        // Skip empty lines
        LineTrim := Trim( Line );
        if LineTrim = '' then begin
            goto loop;
        end;

        // if components section or other section follows, end of nets section
        if Copy(LineTrim, 1, 3) = '<<<' then begin
            result := False;
            exit;
        end;

        // split line into 3 fields
        ParseNetLine( Line, NetNameTemp, DesignatorTemp, PinTemp );

        // Net line
        if NetNameTemp <> '' then begin
            // put new node in netlist - then contine looking for pin assignments
            CurrentNet := NetNameTemp;
            HaveNet := True;
            goto loop;
        end;

        // Pin Name line
        // can't define a pin without a net to belong to !
        if not HaveNet then begin
            raise ESafeTveNetReader.CreateFmt(
            'Pin Name without preceeding Node name in Line %d',
            [LineIndex -1] );
        end;

        // package up return data
        NetName := CurrentNet;
        Designator := DesignatorTemp;
        PinName := PinTemp;

        // return net connection
        FCurrentLine := LineIndex;
        Inc( LineIndex );
        result := True;
        exit;

loop:
        Inc( LineIndex );        
    end;

    // no component loaded - at end of file or end of nets section
    result := False;
end;

end.







