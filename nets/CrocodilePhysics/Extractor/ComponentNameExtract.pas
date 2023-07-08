unit ComponentNameExtract;

interface

uses Classes;

procedure ExtractCrocPhysicsComponentNames( Input, Output : TStrings );


implementation

uses ParseCsv;

//COMPONENT,IC8,"74HC00","Logic Gates (74HC).cml",""

procedure ExtractCrocPhysicsComponentNames( Input, Output : TStrings );

    procedure ExtractComponentName( const Line : string );
    var
        Index : integer;
        field : string;
    begin
        Index := 0;

        // skip COMPONENT field
        ParseCsvValue( Line, field, Index );

        // skip designator "IC8" field
        ParseCsvValue( Line, field, Index );

        // grab Component Name field
        ParseCsvValue( Line, field, Index );

        // output field with a comma at the end
        Output.Add( field + ',' );
    end;

var
    Line : string;
    InputIndex : integer;
begin
    // for every line in input list
    for InputIndex := 0 to Input.Count - 1 do begin

        Line := Input[InputIndex];

        // act on COMPONENT lines
        if Pos( 'COMPONENT,', Line ) = 1 then begin
            ExtractComponentName( Line );
        end;
    end;
end;


end.
