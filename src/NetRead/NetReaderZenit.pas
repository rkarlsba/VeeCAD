unit NetReaderZenit;

interface

uses NetReader;

// Low level access to Protel Netlist files.

type TZenitNetReader = class( TveNetReader )

protected
    CurrentNet : string;
    HaveNet : boolean;
    HaveLine : boolean;
    LinePos : integer;
    function GetNetlistDescriptor : string; override;

public
    function CheckCompatibility : boolean; override;

    procedure ToFirstComponent; override;
    function GetNextComponent( var Designator, Value, Outline : string ) : boolean;
        override;
    procedure ToFirstConnection; override;
    function GetNextConnection( var NetName, Designator, PinName : string )
        : boolean; override;
end;


implementation

uses SysUtils, ParseCSV, ExceptSafe;

type ESafeZenitReader = class( ESafe );

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

function TZenitNetReader.GetNetlistDescriptor : string;
begin
    result := 'ZenitPCB';
end;

function TZenitNetReader.CheckCompatibility : boolean;
begin
    result := True;
end;


procedure TZenitNetReader.ToFirstComponent;
begin
    LineIndex := 0;
    while LineIndex < LineLimit do begin

        // find opening *Parts* of component section of lines, then move
        // to next line
        Line := Lines[LineIndex];
        Inc( LineIndex );
        if Line = '*Parts*' then begin
            exit;
        end;
    end;

    // *Parts* section not found
    raise ESafeZenitReader.Create( '*Parts* heading not found.' );
 end;

function TZenitNetReader.GetNextComponent( var Designator, Value, Outline : string ) : boolean;

    procedure LoadComponent;
    var
        Index : integer;
    begin
        // read line of form
        // Designator;Package;Value;??;???;Datasheet filename.
        // R1;RES-CR 1/4W S[10.16MM 400MIL];220K;;0.000;C:\PROGRAM FILES\ZENITSUITE\DATASHEET\RESISTOR.PDF
        Index := 0;
        ParseCsvValue( Line, Designator, Index, ';' );
        ParseCsvValue( Line, Outline, Index, ';' );
        ParseCsvValue( Line, Value, Index, ';' );

        Designator := Trim( Designator );
        Outline := Trim( Outline );
        Value := Trim( Value );

        // must have designator (eg 'C1', 'Q2') - other fields can be blank
        // OR could give a dummy designator or no designator ??
        // OR raise an exception.
        if (Designator = '') then begin
            raise ESafeZenitReader.CreateFmt(
            'Component on line %d has blank Designator', [LineIndex + 1] );
        end;
    end;

begin
    // search for next component
    while LineIndex   < LineLimit do begin

        Line := Trim(Lines[LineIndex]);

        // parts section ends when *Nets* heading encountered
        if Line = '*Nets*' then begin
            result := False;
            exit;
        end
        else if Line <> '' then begin
            LoadComponent;
            FCurrentLine := LineIndex + 1;
            Inc( LineIndex );
            result := True;
            exit;
        end;

        Inc( LineIndex );
    end;

    // no component loaded - at end of file
   raise ESafeZenitReader.Create( 'End of file before *Nets* statement encountered' );
end;

procedure TZenitNetReader.ToFirstConnection;
begin
    LineIndex := 0;
    while LineIndex < LineLimit do begin

        // find opening *Parts* of component section of lines, then move to
        // next line
        Line := Lines[LineIndex];
        Inc( LineIndex );
        if Line = '*Nets*' then begin
            HaveNet := False;
            exit;
        end;
    end;

    // *Parts* section not found
    raise ESafeZenitReader.Create( '*Nets* heading not found.' );
end;

function TZenitNetReader.GetNextConnection( var NetName, Designator, PinName : string )
    : boolean;

    procedure ToNextNet;
    var
        ColonPos : integer;
        SemiColonPos : integer;
    begin
        while LineIndex < LineLimit do begin

            // find opening 'Signal:' of net definition group of lines
            Line := Trim(Lines[LineIndex]);

            if Line = '*end*' then begin
                exit;
            end
            else if Pos( 'Signal:', Line ) = 1 then begin

                ColonPos := Pos( ':', Line );
                SemiColonPos := Pos( ';', Line );
                if SemiColonPos = 0 then begin
                end;

                CurrentNet := Trim( Copy( Line, ColonPos + 1, SemiColonPos - ColonPos -1 ));

                // successfully entered new net
                HaveNet := True;
                HaveLine := False;
                exit;
            end;
            inc( LineIndex );
        end;

        // fell through loop and did not find net : leave HaveNet = False;
//      HaveNet := False;
    end;

    procedure ToNextLine;
    begin
        inc( LineIndex );
        LinePos := 1;
        HaveLine := LineIndex < LineLimit;
    end;


    // read next pin from current line of form "C2.2 CN1.1 R1.2 IC2.3 IC1.4"
    function ParseNextPin : boolean;
    var
        FirstCharPos : integer;
        PeriodPos : integer;
    begin
        // scan past white space to first char
        // ..prevent "uninitialised variable" compiler warning
        FirstCharPos := 0;
        while LinePos <= Length(Line) do begin
            if Line[LinePos] <> '' then begin
                FirstCharPos := LinePos;
                break;
            end;
            inc( LinePos );
        end;

        // possibly no more pin assignment on this line
        if LinePos > Length(Line) then begin
            result := False;
            exit;
        end;

        // scan until '.' character
        // ..prevent "uninitialised variable" compiler warning
        PeriodPos := 0;
        while LinePos <= Length(Line) do begin
            if Line[LinePos] = '.' then begin
                PeriodPos := LinePos;
                break;
            end;
            inc( LinePos );
        end;

        // scan until next white space (probably digits)
        while LinePos <= Length(Line) do begin
            if Line[LinePos] = ' ' then begin
                break;
            end;
            inc( LinePos );
        end;

        if FirstCharPos = PeriodPos then begin
            raise ESafeZenitReader.CreateFmt(
                'Blank designator on net line %d', [LineIndex +1] );
        end;

        NetName := CurrentNet;
        Designator := Copy( Line, FirstCharPos, PeriodPos - FirstCharPos );
        PinName := Copy( Line, PeriodPos +1, LinePos - PeriodPos -1 );

        Inc( LinePos );
        result := True;
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

        // must have a line to digest
        if not HaveLine then begin

            ToNextLine;

            if not HaveLine then begin
                HaveNet := False;
                continue;
            end;
        end;

        // read line
        Line := Trim(Lines[ LineIndex ]);

        // find end of net definition
        if Pos( 'Signal:', Line ) = 1 then begin
            HaveNet := False;
            continue;
        end

        else if Line = '*end*' then begin
            result := False;
            exit;
        end

        // Parse next designator, pin no from line, of form 'R1.2'
        else if ParseNextPin then begin
            FCurrentLine := LineIndex + 1;
            result := True;
            exit;
        end
        // couldn't parse - end of line
        else begin
            HaveLine := False;
        end;

    end;

    // fell through loop - end of netlist file
    result := False;
end;



end.





