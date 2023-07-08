unit NetReaderProtelTango;

interface

uses NetReader, ExceptSafe;

// Low level access to Protel Netlist files.

type ESafeProtelTangoReader = class( ESafe );

type TProtelNetReader = class( TveNetReader )
protected
    CurrentNet : string;
    HaveNet : boolean;
    function GetNetlistDescriptor : string; override;
    procedure ParseNetLine(
        LineIndex : integer; const Line : string;
        var Designator, PinName : string ); virtual;

public
    function CheckCompatibility : boolean; override;

    procedure ToFirstComponent; override;
    function GetNextComponent( var Designator, Value, Outline : string ) : boolean;
        override;
    procedure ToFirstConnection; override;
    function GetNextConnection( var NetName, Designator, PinName : string )
        : boolean; override;
end;


// Low level access to Tango Netlist files.

type TTangoNetReader = class( TProtelNetReader )

protected
    function GetNetlistDescriptor : string; override;
{
    procedure ParseNetLine(
        LineIndex : integer; const Line : string;
        var Designator : string; var PinNo : Integer ); override;
}       
end;



implementation

uses SysUtils;

// **********************************************
//              TProtelNetReader
// **********************************************

// safe to scan each code unit (16 bit char) because both bytes of a surrogate
// are guaranteed never to match any single unit char.

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

(*
A Net line is of form "U1-14" ie pin 14 of U1 is assigned to current net.
A component name can also include a '-', e.g. "U1--14" means pin 14 of U1- ,
so have to scan from the right when looking for separator '-'.

Code now accepts ',' as separator.  First '-' or ',' from right is taken to be
separator.
*)

procedure TProtelNetReader.ParseNetLine(
        LineIndex : integer; const Line : string; var Designator, PinName : string );
var
    found : boolean;
    i : integer;
    c : char;
    LineLength : integer;
begin
    // scan from right until '-' found
    found := False;
    i := Length( Line );
    while i > 0 do begin
        c := Line[i];
        if (c = '-') or (c = ',') then begin     // Protel '-', Tango ','
//        if Line[i] = '-' then begin   // Protel
//        if Line[i] = ',' then begin   // Tango
            found := True;
            break;
        end;
        dec( i );
    end;

    if not Found then begin
        raise ESafeProtelTangoReader.CreateFmt(
        'Missing "-" or "," in Pin to Net assignment on line %d', // Protel, Tango
//        'Missing "-" in Pin to Net assignment on line %d',      // Protel
//        'Missing "," in Pin to Net assignment on line %d',      // Tango
        [LineIndex + 1]
        );
    end;

    Designator := DeComma(Copy( Line, 1, i-1 ));

    //.. designator is Trimmed - to match Trim when reading when Designators in
    //.. component section
    Designator := Trim( Designator );
    PinName := Trim(Copy( Line, i+1, 255 ));

    // if PinName is blank, we might have encountered a line like
    // R1,- or R1-- , which is ambiguous, but which we define as a special case
    // of a pin name of '-'
    LineLength := Length(Line);
    if (PinName = '') and (LineLength > 2) then begin

        // c is 2nd last char
        c := Line[LineLength -1];

        // if last char is '-' and char before is '-' or ','
        if (Line[LineLength] = '-') and ((c = '-') or (c = ',')) then begin

            Designator := Trim( Copy( Line, 1, LineLength-2 ));
            PinName := '-';
        end;
    end;
end;

function TProtelNetReader.GetNetlistDescriptor : string;
begin
    result := 'Protel';
end;

function TProtelNetReader.CheckCompatibility : boolean;
begin
    result := True;
end;


procedure TProtelNetReader.ToFirstComponent;
begin
    LineIndex := 0;
end;

function TProtelNetReader.GetNextComponent( var Designator, Value, Outline : string ) : boolean;

    procedure LoadComponent;
    const MinimumComponentLines = 5;

    begin
        // to next line
        Inc( LineIndex );

        // need at least 6 data lines plus ']' to complete component
        if LineIndex >= LineLimit - MinimumComponentLines then begin
            raise ESafeProtelTangoReader.CreateFmt(
            'Component on lne %d has insufficient data lines',
            [LineIndex + 1]
            );
        end;

        // next 3 lines contain component info we want
        //.. designator is Trimmed - when reading connection section of netlist
        //.. must also Trim to avoid mismatches.
        Designator := DeComma(Trim( Lines[ LineIndex ] ));
        Inc( LineIndex );
        Outline := DeComma(Trim( Lines[ LineIndex ] ));
        Inc( LineIndex );
        Value := DeComma(Trim( Lines[ LineIndex ] ));

        // find the ']' which terminates the component
        while LineIndex < LineLimit do begin
            Line := Trim( Lines[LineIndex] );
            if Line = ']' then begin
                break;
            end
            else if Line = '[' then begin
                raise ESafeTveNetReader.CreateFmt(
                '"[" on line %d before end of component definition',
                [LineIndex + 1]
                );
            end
            else if Line = '(' then begin
                raise ESafeProtelTangoReader.CreateFmt(
                '"(" on line %d before end of component definition',
                [LineIndex + 1]
                );
            end;
            Inc( LineIndex )
        end;

        // must have designator (eg 'C1', 'Q2') - other fields can be blank
        // OR could give a dummy designator or no designator ??
        // OR raise an exception.
        if (Designator = '') then begin
            exit;
        end;
    end;

begin
    // search for next component
    while LineIndex < LineLimit do begin

        Line := Lines[LineIndex];

        if '[' = Line then begin
            FCurrentLine := LineIndex + 2;
            LoadComponent;
            Inc( LineIndex );
            result := True;
            exit;
        end;

        Inc( LineIndex );
    end;

    // no component loaded - at end of file
    result := False;
end;

procedure TProtelNetReader.ToFirstConnection;
begin
    LineIndex := 0;
    HaveNet := False;
end;

function TProtelNetReader.GetNextConnection( var NetName, Designator, PinName : string )
    : boolean;

    procedure ToNextNet;
    begin
        while LineIndex < LineLimit do begin

            // find opening '(' of net definition group of lines
            Line := Trim(Lines[LineIndex]);

            if (Length(Line) > 0) and (Line[1] = '(') then begin

                // Windraft has opening bracket and net name on same line..
                // (N0025
                // so net name is rest of this line
                if Length(Line) > 1 then begin
                    CurrentNet := Trim( Copy( Line, 2, 255 ));
                end

                // Normal Protel has bracket and net name on separate lines..
                // (
                //  N0025
                else begin

                  // read net name on next line
                  Inc(LineIndex);
                  if LineIndex >= LineLimit then begin
                      exit;
                  end;
                  CurrentNet := Trim(Lines[LineIndex]);
                end;

                // successfully entered new net
                Inc( LineIndex );
                HaveNet := True;
                exit;
            end;
            inc( LineIndex );
        end;

        // fell through loop and did not find net : leave HaveNet = False;
//      HaveNet := False;
    end;


begin
    while LineIndex < LineLimit do begin

        // must be inside a net definition
        if not HaveNet then begin
            ToNextNet;

            // no net definition found
            if not HaveNet then begin
                result := False;
                exit;
            end;
        end;

        // read line
        Line := Lines[ LineIndex ];

        // find end of net definition
        if Line = ')' then begin
            HaveNet := False;
            Inc( LineIndex );
            continue;
        end;

        // find pin to net assignment , eg line is "U1-3"
        // separate net line into Designator & PinNo
        ParseNetLine( LineIndex, Line, Designator, PinName );
        NetName := CurrentNet;
        Inc( LineIndex );
        FCurrentLine := LineIndex;
        result := True;
        exit;
    end;

    // fell through loop - end of netlist file
    result := False;
end;


// **********************************************
//              TTangoNetReader
// **********************************************
{
TANGO uses ',' separator in component pin descriptors
PROTEL uses '-' separator in component pin descriptors
Otherwise these two formats are handled by the same code

Tango
(
GND
U15,7
U15,13
)

Protel
(
GND
U15-7
U15-13
)
}

function TTangoNetReader.GetNetlistDescriptor : string;
begin
    result := 'Tango';
end;

(*
A Net line is of form "U1,14" ie pin 14 of U1 is assigned to current net.
A component name can also include a ',', e.g. "U1,,14" means pin 14 of "U1," 
so have to scan from the right when looking for separator ','.
*)
(*
procedure TTangoNetReader.ParseNetLine(
        LineIndex : integer; const Line : string;
        var Designator : string; var PinNo : Integer );
var
    found : boolean;
    i : integer;
    PinNoString : string;
begin
    // scan from right until '-' found
    found := False;
    i := Length( Line );
    while i > 0 do begin
//        if Line[i] = '-' then begin   // Protel
        if Line[i] = ',' then begin     // Tango
            found := True;
            break;
        end;
        dec( i );
    end;

    if not Found then begin
        raise ETveNetReader.CreateFmt(
//        'Missing "-" in Pin to Net assignment on line %d',    // Protel
        'Missing "," in Pin to Net assignment on line %d',      // Tango
        [LineIndex + 1]
        );
    end;

    Designator := DeComma(Copy( Line, 1, i-1 ));
    PinNoString := Trim(Copy( Line, i+1, 255 ));
    try
        PinNo := StrToInt( PinNoString );
    except
        raise ETveNetReader.CreateFmt(
        'Invalid pin number "%s" in Pin to Net assignment on line %d',
        [PinNoString, LineIndex + 1]
        );
    end;
end;
*)

end.





