unit Rotations;

interface

type TRotation = ( rot0, rot90, rot180, rot270 );

// ***************************************
//     Utility Function Rotate Coords
// ***************************************

procedure Rotate( var X, Y : integer; CentreX, CentreY : integer;
    Rotation : TRotation );

procedure RotateReverse( var X, Y : integer; CentreX, CentreY : integer;
    Rotation : TRotation );

// ***************************************
//  Utility Functions Combine Rotations
// ***************************************

function AddRotation( R1, R2 : TRotation ) : TRotation;
function SubtractRotation( Minuend, Subtrahend : TRotation ) : TRotation;
function NegateRotation( R : TRotation ) : TRotation;

const RotationToStr : array[TRotation] of string = ( '0', '90', '180', '270' );

implementation

{ convert X, Y co-ords to value rotated around centre point }

procedure Rotate( var X, Y : integer; CentreX, CentreY : integer;
    Rotation : TRotation );
var XOut : integer;
begin
    case Rotation of
        rot180 : { 180 degree } begin
            X := (2 * CentreX) - X;
            Y := (2 * CentreY) - Y;
        end;
        rot0 : { zero rotation }
            ;
        rot90 : { 90 degree } begin
            XOut := CentreX + (Y - CentreY);
            Y := CentreY - (X - CentreX);
            X := XOut;
        end;
        rot270 :  { -90 degree } begin
            XOut := CentreX - (Y -CentreY);
            Y := CentreY + (X - CentreX);
            X := XOut;
        end;
    end;
end;

//{ rotate, but in opposite direction (clockwise) to Rotate()
//convert X, Y co-ords to value rotated around centre point }

procedure RotateReverse( var X, Y : integer; CentreX, CentreY : integer;
    Rotation : TRotation );
var XOut : integer;
begin
    case Rotation of
        rot180 : { 180 degree } begin
            X := (2 * CentreX) - X;
            Y := (2 * CentreY) - Y;
        end;
        rot0 : { zero rotation }
            ;
        rot270 : { -90 degree } begin
            XOut := CentreX + (Y - CentreY);
            Y := CentreY - (X - CentreX);
            X := XOut;
        end;
        rot90 :  { -90 degree } begin
            XOut := CentreX - (Y -CentreY);
            Y := CentreY + (X - CentreX);
            X := XOut;
        end;
    end;
end;

function AddRotation( R1, R2 : TRotation ) : TRotation;
const
    S : array[TRotation, TRotation] of TRotation =
    (
    ( Rot0, Rot90, Rot180, Rot270 ),  // S[0, 0], S[0, 90], S[0, 180], S[0, 270]
    ( Rot90, Rot180, Rot270, Rot0 ),  // S[90, 0], S[90, 90], S[90, 180], S[90, 270]
    ( Rot180, Rot270, Rot0, Rot90 ),  // S[180, 0], S[180, 90], S[180, 180], S[180, 270]
    ( Rot270, Rot0, Rot90, Rot180 )   // S[270, 0], S[270, 90], S[270, 180], S[270, 270]
    );
begin
    result := TRotation(  ( Ord(R1) + Ord(R2)) mod 4  );
//    result := S[R1, R2];
end;

//  Result = Minuend - Subtrahend
function SubtractRotation( Minuend, Subtrahend : TRotation ) : TRotation;
const

    S : array[TRotation, TRotation] of TRotation =
    (
    ( Rot0, Rot270, Rot180, Rot90 ),  // S[0, 0], S[0, 90], S[0, 180], S[0, 270]
    ( Rot90, Rot0, Rot270, Rot180 ),  // S[90, 0], S[90, 90], S[90, 180], S[90, 270]
    ( Rot180, Rot90, Rot0, Rot270 ),  // S[180, 0], S[180, 90], S[180, 180], S[180, 270]
    ( Rot270, Rot180, Rot90, Rot0 )   // S[270, 0], S[270, 90], S[270, 180], S[270, 270]
    );
begin
    result := S[Minuend, Subtrahend];
end;


function NegateRotation( R : TRotation ) : TRotation;
const
    Solution : array[TRotation] of TRotation = ( Rot0, Rot270, Rot180, Rot90 );
begin
    result := Solution[ R ];
end;



end.
