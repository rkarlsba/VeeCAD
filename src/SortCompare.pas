unit SortCompare;

interface

function CompareItemsForComponents( P1, P2 : pointer ) : integer;
function CompareDesignators( D1, D2 : string ) : integer;

implementation


uses SysUtils, Character, Windows, Outlines;

// split designator into two parts - eg TR402 is split into 'TR' and '402'
// the first part contains leading alpha characters, the second part
// starts from the first non-alpha character.
procedure Split( Designator : string; var Alpha, Numeric : string );
var
    i : integer;
    limit : integer;
    c : char;
begin
    limit := Length(Designator);
    i := 1;
    Alpha := '';
    Numeric := '';
    // parse leading Alpha section of Designator
    while i <= limit do begin
        c := Designator[i];
{$IFDEF VER200}
        if IsLetter(c) then  begin
{$ELSE}
        if c.Isletter then  begin
{$ENDIF}
            Alpha := Alpha + c;
        end
        else begin
            break;
        end;
        Inc( i );
    end;

    // remainder becomes Numeric section
    Numeric := Copy(Designator, i, limit -i +1 );
end;


function CompareDesignators( D1, D2 : string ) : integer;
var
    Alpha1, Numeric1 : string;
    Alpha2, Numeric2 : string;
    Number1, Number2 : integer;
begin
    // set length to avoid reallocations
    SetLength( Alpha1, 10 );
    SetLength( Numeric1, 10 );
    SetLength( Alpha2, 10 );
    SetLength( Numeric2, 10 );

    // split strings - eg TR402 is split into 'TR' and '402'
    Split( D1, Alpha1, Numeric1 );
    Split( D2, Alpha2, Numeric2 );

    // compare Alpha
    result := AnsiCompareStr( Alpha1, Alpha2 );
    if result <> 0 then begin
        exit;
    end;

    // Alphas are the same, so compare numeric
    Number1 := StrToIntDef( Numeric1, Low(Integer) );
    Number2 := StrToIntDef( Numeric2, Low(Integer) );

    // we don't have numbers, so just compare strings
    if (Number1 = low(Integer)) or (Number2 = Low(integer)) then begin
        result := AnsiCompareStr( D1, D2 );
        exit;
    end;

    // compare numbers
    if Number1 > Number2 then begin
        result := 1;
    end
    else if Number1 < Number2 then begin
        result := -1;
    end
    else begin
        result := 0;
    end;
end;

function CompareItemsForComponents( P1, P2 : pointer ) : integer;
var
    Item1, Item2 : TveBoardItem;
begin
    Item1 := TveBoardItem(P1);
    Item2 := TveBoardItem(P2);
    result := CompareDesignators( Item1.Designator, Item2.Designator );
end;


end.
