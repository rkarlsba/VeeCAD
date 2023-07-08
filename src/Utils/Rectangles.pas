unit Rectangles;

interface

uses Types, Rotations;

procedure NormalizeRect( var R : TRect );
procedure ExtendRectangle( var Rectangle : TRect; const Additional : TRect );
function ContainsRect( Rect, Container : TRect ) : boolean;
function RectanglesOverlap( R1, R2 : TRect ) : boolean;


implementation

// ** arrange coords in normalised form *
// ensures left<=right, top<=bottom
// This is not a bounding rectangle
procedure NormalizeRect( var R : TRect );
var
    Temp : integer;
begin
    if R.Right < R.Left then begin
        Temp := R.Right;
        R.Right := R.Left;
        R.Left := Temp;
    end;
    if R.Bottom < R.Top then begin
        Temp := R.Bottom;
        R.Bottom := R.Top;
        R.Top := Temp;
    end;
end;

// ** Extend Rectangle so it encloses Additional Rectangle **
procedure ExtendRectangle( var Rectangle : TRect; const Additional : TRect );
begin
    if Additional.Left < Rectangle.Left then begin
        Rectangle.Left := Additional.Left;
    end;
    if Additional.Right > Rectangle.Right then begin
        Rectangle.Right := Additional.Right;
    end;
    if Additional.Top < Rectangle.Top then begin
        Rectangle.Top := Additional.Top;
    end;
    if Additional.Bottom > Rectangle.Bottom then begin
        Rectangle.Bottom := Additional.Bottom;
    end;
end;

// ******* Return True if Rect is completely inside Container *********
function ContainsRect( Rect, Container : TRect ) : boolean;
begin
    result :=
        (Rect.Left >= Container.Left) and
        (Rect.Right <= Container.Right) and
        (Rect.Top >= Container.Top) and
        (Rect.Bottom <= Container.Bottom);
end;

function RectanglesOverlap( R1, R2 : TRect ) : boolean;
begin
    result :=
        (
        ((R1.Left <= R2.Left) and (R1.Right > R2.Left)) and

        (((R1.Top <= R2.Top) and (R1.Bottom > R2.Top)) or
                ((R2.Top <= R1.Top) and (R2.Bottom > R1.Top)))
        )
        or
        (
        ((R2.Left <= R1.Left) and (R2.Right > R1.Left)) and
        (((R2.Top <=  R1.Top) and (R2.Bottom > R1.Top)) or
                ((R1.Top <= R2.Top) and (R1.Bottom > R2.Top)))
        )
    ;
end;

end.
