unit Rectangles;

interface

uses Types, Rotations;

procedure NormalizeRect( var R : TRect );
//procedure RotateRect( var R : TRect; Angle : TRot );
procedure ExtendRectangle( var Rectangle : TRect; const Additional : TRect );


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

end.

