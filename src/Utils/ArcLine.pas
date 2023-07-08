unit ArcLine;
interface

uses Types;

{
Class to Convert Arc into Polyline
==================================
}

type TExtendedPoint = record
    X : extended;
    Y : extended;
end;

type TArcLines = class
protected
    FPoints : array of TExtendedPoint;
    Capacity : integer;
    FCount : integer;
    FSegments : integer;
    function GetPoint(index : integer) : TExtendedPoint;
    function GetPointInteger(index : integer) : TPoint;
    procedure AddPoint( X, Y : Extended );
public
    // number of line segments
    property Segments : integer read FSegments write FSegments;
    // number of points
    property Count : integer read FCount;
    // read points in polyline sequence
    property Points[index : integer] : TExtendedPoint read GetPoint;
    property PointsInteger[index : integer] : TPoint read GetPointInteger;
    // convert an Arc to Points
    procedure SetArc(  X1, Y1, X2, Y2, X3, Y3, X4, Y4 : extended );
end;

implementation

uses Math;


procedure TArcLines.AddPoint( X, Y : Extended );
begin
  if FCount <= Length(FPoints) then begin
    SetLength(FPoints, FCount + 20);
  end;
  Inc(FCount);
  FPoints[FCount -1].X := X;
  FPoints[FCount -1].Y := Y;
end;

function TArcLines.GetPoint(index : integer) : TExtendedPoint;
begin
  result := FPoints[index];
end;

function TArcLines.GetPointInteger(index : integer) : TPoint;
begin
  result.X := Round(FPoints[index].X);
  result.Y := Round(FPoints[index].Y);
end;


// ******************************************
//      Convert Arc to Line Segments.
// ******************************************
{
 Call with:
 X1..Y4 same as Canvas.Arc() parameters. Segments=no of line segments in 360 degrees.

Equation of ellipse symetrical about x, y axis:
X(t) = Xc + a.cos(t)
Y(t) = Yc – b.sin(t)
where: a = half width of ellipse, b= half height of ellipse and t varies from
start angle to finish angle. (Xc,Yc) is centre of ellipse.

Notes about code:

 function ArcTan2(const Y, X: Extended): Extended; calculates ArcTan(Y/X), and
 returns an angle in the correct quadrant.
  IN: |Y| < 2^64, |X| < 2^64, X <> 0   OUT: [-PI..PI] radians

 procedure SinCos(const Theta: Extended; var Sin, Cos: Extended) register;
  SinCos is 2x faster than calling Sin and Cos separately for the same angle
procedure SinCos(const Theta: Extended; var Sin, Cos: Extended) register;
}

procedure TArcLines.SetArc(  X1, Y1, X2, Y2, X3, Y3, X4, Y4 : extended );
var
    // half width, half height, a,b are
    a, b : single;

    CentreX, CentreY : extended;
    StartAngle, EndAngle : extended;
    IncrementAngle : extended;
    IncludedAngle : extended;
    SegmentsUsed : integer;

    // current plot point to draw line to
    X, Y : extended;

    // current angle
    Angle : single;

    i : integer;
begin
    // clear old points before creating new points
    FCount := 0;

    // work out centre
    CentreX := ( X2 + X1 ) * 0.5;
    CentreY := ( Y2 + Y1 ) * 0.5;

    // work out a=half width, b=half height
    a := ( X2 - X1 ) * 0.5;
    b := ( Y2 - Y1 ) * 0.5;

    // work out start, end angles. Y values are negated because Y moves down page
    StartAngle := ArcTan2( CentreY - Y3, X3 - CentreX );
    EndAngle := ArcTan2( CentreY - Y4, X4 - CentreX );

    // work out increment angle
    IncrementAngle := (2 * Pi) / Segments;

    // work out angle swept by all segments. Going clockwise means we always
    // have positive included angle
    IncludedAngle := EndAngle - StartAngle;
    if IncludedAngle <= 0.0 then begin
        IncludedAngle := IncludedAngle + 2 * Pi;
    end;

    // work out how many segments
    SegmentsUsed := Round( IncludedAngle / IncrementAngle );
    if SegmentsUsed < 4 then begin
        SegmentsUsed := 4
    end;

    // work out revised increment angle that exactly fits segments in angle
    // IncrementAngle is always positive because that is direction of drawing
    IncrementAngle := IncludedAngle / SegmentsUsed;

    // go to start point
    Angle := StartAngle;
    SinCos( Angle, Y, X );
    AddPoint( Round( CentreX + a*X), Round( CentreY - b*Y ) );

    // plot line segments
    for i := 0 to SegmentsUsed -1 do begin
        Angle := Angle + IncrementAngle;
        SinCos( Angle, Y, X );
        AddPoint( Round( CentreX + a*X), Round( CentreY - b*Y ) );
    end;
end;

end.