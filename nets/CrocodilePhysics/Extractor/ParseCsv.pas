unit ParseCsv;

interface


function ParseCsvValue( const CSVString : string; var Value : string;
    var Index : integer ) : boolean;

implementation


// function parses comma-separated values
// Call first time with index = 0 => returns Value = text before 1st comma and
// moves index to next posisiton.
// Returns True means Value holds new data
// Returns False means Value undefined - no more values to parse

function ParseCsvValue( const CSVString : string; var Value : string;
    var Index : integer ) : boolean;
var
    Len : integer;
    i : integer;
begin
    Len := Length( CSVString );

    // if CSVString consumed
    if (Index > Len) or (Len = 0) then begin
        result := False;
        exit;
    end;

    // set i to index of next ',' or one past end of CSVString
    i := index + 1;
    while i <= Len do begin
        if CSVString[i] = ',' then begin
            break;
        end;
        inc( i );
    end;

    Value := Copy( CSVString, Index +1, i - index -1 );
    Index := i;
    result := True;
end;


end.
 