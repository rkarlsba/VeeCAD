unit Intersect;

interface

uses Types;

// TFloatPoint : a point in floating point format
type TFloatPoint = record
  x : single;
  y : single;
end;

type TFloatRect = record
    Point1 : TFloatPoint;
    Point2 : TFloatPoint;
    Point3 : TFloatPoint;
    Point4 : TFloatPoint;
end;

type TFloatCircle = record
    Centre : TFloatPoint;
    Radius : single;
end;

type TAlignedFloatRect = record
    TopLeft : TFloatPoint;
    BottomRight : TFloatPoint;
end;

// combine areas of two aligned float rectangles - GDI coord system
procedure CombineAlignedFloatRectangles(
    var Total : TAlignedFloatRect; NewRect : TAlignedFloatRect );

// Test if two rectangles intersect (may not be aligned with axis)
function RectanglesIntersect( Rect1, Rect2 : TFloatRect ) : boolean;

// Test if a circle and aligned rectangle intersect.
// Rect points are Point1=TopLeft, Point2
function CircleAlignedRectangleIntersect(
    RectLeftTop, RectRightBottom : TFloatPoint; Circle : TFloatCircle ) : boolean;

// Test if a rectangle and circle intersect (rect may not be aligned with axis)
// Test if a rectangle and circle intersect (rect may not be aligned with axis)
function CircleRectangleIntersect(
    Rect1 : TFloatRect; Circle : TFloatCircle ) : boolean;

// Test if two circles intersect
function CirclesIntersect( Circle1, Circle2 : TFloatCircle ) : boolean;

//Compute the distance from line segment AB to point C
// AB is a segment, not an infinitely long line, so if line is too short,
// distance is taken to the nearest line end.
function LinePointDist( A, B, C : TFloatPoint ) : single;

// distance between two points
function DistanceBetweenPoints( Point1, Point2 : TFloatPoint ) : single;

// Test if Rect is inside Container
function EnclosesRectAligned( ARect, Container : TAlignedFloatRect ) : boolean;

// Test if Two Rectangles Overlap
function AlignedFloatRectsIntersect( Rect1, Rect2 : TAlignedFloatRect ): boolean;

// Normalise a TAlignedFloatRect, so (left,top) & (right, bottom) match GDI
// coord directions
procedure NormaliseAlignedFloatRect( var R : TAlignedFloatRect );

// determine if 2 line cross given their end-points
function LinesCross(LineAP1, LineAP2, LineBP1, LineBP2 : TPoint) : boolean;

implementation

uses Math;

// Calculate the dot product of two vectors
function dotProduct( vector1, vector2 : TFloatPoint ) : single;
begin
    result := (vector1.x * vector2.x) + (vector1.y * vector2.y);
end;

// Calculate the projection of a rectangle on an axis
// and returns it as a [min, max] interval

procedure ProjectPolygon(
    axis : TFloatPoint; Rect : TFloatRect; var min, max : single );
var
    Product : single;
begin
    Product := dotProduct( axis, Rect.Point1 );
    min := Product;
    max := Product;
    Product := dotProduct( axis, Rect.Point2 );
    min := Math.min( min, Product );
    max := Math.Max( max, Product );
    Product := dotProduct( axis, Rect.Point3 );
    min := Math.min( min, Product );
    max := Math.Max( max, Product );
    Product := dotProduct( axis, Rect.Point4 );
    min := Math.min( min, Product );
    max := Math.Max( max, Product );
end;

// Calculate the distance between [minA, maxA] and [minB, maxB]
// The distance will be negative if the intervals overlap

function IntervalDistance( minA, maxA, minB, maxB : single ) : single;
begin
    if minA < minB then begin
        result := minB - maxA;
    end
    else begin
        result := minA - maxB;
    end;
end;

// take two points, make a line out of them, and find the normal of the line.
// y-y and x-x moves one end of our line to the origin.
// letting x =-y and y=x gives us a 90 degree rotation.
// Thus our normal Axis is defined by two points.
// It is normalised to a length of 1.
function MakeAxis( PointA, PointB : TFloatPoint ) : TFloatPoint;
var
    Length : single;
begin
    result.x := -(PointA.y - PointB.y);
    result.y := -(PointA.x - PointB.x);
    Length := sqrt((result.x * result.x) + (result.y * result.y));
    // divide by zero error is possible, if points are identical.
    // In that case, make a tiny axis
//    if Length < 0.1 then begin
//        asm nop end;
//    end;
    result.x := result.x / Length;
    result.y := result.y / Length;
end;


// Test if two rectangles intersect.
function RectanglesIntersect( Rect1, Rect2 : TFloatRect ) : boolean;

    function VertexIsFree( Point1, Point2 : TFloatPoint ) : boolean;
    var
        // axis runs through (0.0) and is defined by a single point x,y
        axis : TFloatPoint;
        max1, min1 : single;
        max2, min2 : single;
    begin
        // if two points are same,
        // is

        // create a separation axis
        axis := MakeAxis( Point1, Point2 );
        // project polygons on it
        ProjectPolygon( axis, Rect1, min1, max1 );
        ProjectPolygon( axis, Rect2, min2, max2 );
        // look for overlap
        result := IntervalDistance( min1, max1, min2, max2 ) > 0;
    end;

begin
    // assume rectangles don't overlap - the usual case.
    result := False;

    // since we have rectangles, just test first two vertexes from each rectangle
    // for quadrilaterals or polygons in general, must test every vertex.
    // Apart from that, code is same

    if VertexIsFree( Rect1.Point1, Rect1.Point2 ) then begin
        exit;
    end;
    if VertexIsFree( Rect1.Point2, Rect1.Point3 ) then begin
        exit;
    end;
{   ** Not required for rectangles, ie. with parallel sides, because opposite
    sides have the same normals, and the polygon projections on those normals
    are identical. However, must test if sides are not parallel.
    if VertexIsFree( Rect1.Point3, Rect1.Point4 ) then begin
        exit;
    end;
    if VertexIsFree( Rect1.Point4, Rect1.Point1 ) then begin
        exit;
    end;
}
    if VertexIsFree( Rect2.Point1, Rect2.Point2 ) then begin
        exit;
    end;
    if VertexIsFree( Rect2.Point2, Rect2.Point3 ) then begin
        exit;
    end;
{   ** Not required for rectangles, ie. with parallel sides, because opposite
    sides have the same normals, and the polygon projections on those normals
    are identical. However, must test if sides are not parallel.
    if VertexIsFree( Rect2.Point3, Rect2.Point4 ) then begin
        exit;
    end;
    if VertexIsFree( Rect2.Point4, Rect2.Point1 ) then begin
        exit;
    end;
}
    // could not find an axis that allowed non-overlapping projections, so
    // rectangles are in contact.
    result := True;
end;


// Test if a circle and aligned rectangle intersect.
// Rect points are Point1=TopLeft, Point2

{     We make two rectangles :
    The "tall" rectangle has the original rectangle width, but is extended up
    and down by the circle radius.

    The "wide" rectangle has the original rectangle height, but is extended
    right and left by the circle radius.

         ************
         *          *
         *          *
     *********************
     |   *          *    |
     |   *          *    |
     *********************
         *          *
         *          *
         ************

    We test to see if the circle centre lies inside either rectangle - if so,
    we have an intersection.

    If we have no intersection with "tall" and "wide", then we still have to
    test the empty corners. We calculate the distance between the circle centre
    and the corners of the original rectangle. If less than radius, we have an
    intersection
}

function CircleAlignedRectangleIntersect(
    RectLeftTop, RectRightBottom : TFloatPoint; Circle : TFloatCircle ) : boolean;

    function DistanceSquared( Point1, Point2 : TFloatPoint ) : single; inline;
    begin
        result :=
            ((Point1.x - Point2.x)*(Point1.x - Point2.x)) +
            ((Point1.y - Point2.y)*(Point1.y - Point2.y));
    end;


var
    Left, Right, Top, Bottom : single;
    RadiusSquared : single;
    TestPoint : TFloatPoint;
begin
    // assume an intersection
    result := True;

    // extend rectangle by radius, to make the "tall" square
    Top := RectLeftTop.y - Circle.Radius;
    Bottom := RectRightBottom.y + Circle.Radius;
    // if centre inside tall square
    if
        (Circle.Centre.x > RectLeftTop.x) and
        (Circle.Centre.x < RectRightBottom.x) and
        (Circle.Centre.y > Top) and
        (Circle.Centre.y < Bottom) then begin
        exit;
    end;

    // extend rectangle by radius, to make the "wide" square
    Left := RectLeftTop.x - Circle.Radius;
    Right := RectRightBottom.x + Circle.Radius;
    // if centre inside tall square
    if
        (Circle.Centre.x > Left) and
        (Circle.Centre.x < Right) and
        (Circle.Centre.y > RectLeftTop.y) and
        (Circle.Centre.y < RectRightBottom.y) then begin
        exit;
    end;

    // still no intersection, so test the corners
    RadiusSquared := Circle.Radius * Circle.Radius;

    if (DistanceSquared( RectLeftTop, Circle.Centre ) < RadiusSquared) or
       (DistanceSquared( RectRightBottom, Circle.Centre ) < RadiusSquared) then begin
        exit;
    end;

    TestPoint.x := RectLeftTop.x;
    TestPoint.y := RectRightBottom.y;
    if (DistanceSquared( TestPoint, Circle.Centre ) < RadiusSquared) then begin
        exit;
    end;

    TestPoint.x := RectRightBottom.x;
    TestPoint.y := RectLeftTop.y;
    if (DistanceSquared( TestPoint, Circle.Centre ) < RadiusSquared) then begin
        exit;
    end;

    // no intersection found
    result := False;
end;


procedure ProjectCircle(
    axis : TFloatPoint; Circle : TFloatCircle; var min, max : single );
var
    Product : single;
begin
    // we can project circle centre like this:
    Product := dotProduct( axis, Circle.Centre );

    // now each side of circle will be + and - one radius on the projection
    min := Product - Circle.Radius;
    max := Product + Circle.Radius;
end;


// Test if a rectangle and circle intersect (rect may not be aligned with axis)
function CircleRectangleIntersect(
    Rect1 : TFloatRect; Circle : TFloatCircle ) : boolean;

    function VertexIsFree( Point1, Point2 : TFloatPoint ) : boolean;
    var
        // axis runs through (0.0) and is defined by a single point x,y
        axis : TFloatPoint;
        max1, min1 : single;
        max2, min2 : single;
    begin
        // create a separation axis
        axis := MakeAxis( Point1, Point2 );
        // project polygons on it
        ProjectPolygon( axis, Rect1, min1, max1 );
        ProjectCircle( axis, Circle, min2, max2 );
        // look for overlap
        result := IntervalDistance( min1, max1, min2, max2 ) > 0;
    end;

begin
    // assume rectangle and circle don't overlap - the usual case.
    result := False;

    // since we have rectangles, just test first two vertexes from each rectangle
    // for quadrilaterals or polygons in general, must test every vertex.
    // Apart from that, code is same

    if VertexIsFree( Rect1.Point1, Rect1.Point2 ) then begin
        exit;
    end;
    if VertexIsFree( Rect1.Point2, Rect1.Point3 ) then begin
        exit;
    end;
{   ** Not required for rectangles, ie. with parallel sides, because opposite
    sides have the same normals, and the polygon projections on those normals
    are identical. However, must test if sides are not parallel.
    if VertexIsFree( Rect1.Point3, Rect1.Point4 ) then begin
        exit;
    end;
    if VertexIsFree( Rect1.Point4, Rect1.Point1 ) then begin
        exit;
    end;
}
    // could not find an axis that allowed non-overlapping projections, so
    // rectangles are in contact.
    result := True;
end;


// Test if two circles intersect
function CirclesIntersect( Circle1, Circle2 : TFloatCircle ) : boolean;
var
    deltaX, deltaY : single;
    DistSquared : single;
    Radii : single;
    RadiiSquared : single;
begin
    // find distance squared between centres
    deltaX := Circle1.Centre.x - Circle2.Centre.x;
    deltaY := Circle1.Centre.y - Circle2.Centre.y;
    DistSquared := (deltaX * deltaX) + (deltaY * deltaY);

    // find square of sum of radii
    Radii := Circle1.Radius + Circle2.Radius;
    RadiiSquared := Radii * Radii;

    // are centres closer than sum of radii?
    result := DistSquared <= RadiiSquared;
end;

//*****************************************
//*****************************************

//Compute the dot product AB . BC of the two vectors AB and BC
function dot( A, B, C : TFloatPoint ) : single;
var
    AB : TFloatPoint;
    BC : TFloatPoint;
begin
     AB.X := B.X - A.X;
     AB.Y := B.Y - A.Y;
     BC.X := C.X - B.X;
     BC.Y := C.Y - B.Y;
     result := (AB.X * BC.X) + (AB.Y * BC.Y);
end;

//Compute the cross product AB x AC
function cross( A, B, C : TFloatPoint ) : single;
var
    AB : TFloatPoint;
    AC : TFloatPoint;
begin
    AB.X := B.X - A.X;
    AB.Y := B.Y - A.Y;
    AC.X := C.X - A.X;
    AC.Y := C.Y - A.Y;
    result := (AB.X * AC.Y) - (AB.Y * AC.X);
end;

//Compute the distance from A to B
function distance( A, B : TFloatPoint ) : single;
var
    d1 : single;
    d2 : single;
begin
    d1 := A.X - B.X;
    d2 := A.Y - B.Y;
    result := sqrt( (d1 * d1) + (d2 * d2) );
end;

//Compute the distance from line segment AB to point C
// AB is a segment, not an infinitely long line, so if line is too short,
// distance is taken to the nearest line end.

function LinePointDist( A, B, C : TFloatPoint ) : single;
var
    dist : single;
    dot1 : single;
    dot2 : single;
begin
    // if A and B are the same point, then distance is distance(A,C) or distance(B,C)
    if (A.X = B.X) and (A.Y = B.Y) then begin
        result := distance(B,C);
        exit;
    end;

    dot1 := dot( A,B,C );
    if( dot1 > 0 ) then begin
        result := distance(B,C);
        exit;
    end;

    dot2 := dot(B,A,C);
    if( dot2 > 0 ) then begin
        result := distance(A,C);
        exit;
    end;

    dist := cross( A,B,C) / distance(A,B);
    result := abs( dist );
end;

// ***************************************************************************
// Normalise a TAlignedFloatRect, so (left,top) & (right, bottom) match GDI
// coord directions
// ***************************************************************************
procedure NormaliseAlignedFloatRect( var R : TAlignedFloatRect );
var
    Temp : single;
begin
    if R.BottomRight.x < R.TopLeft.x then begin
        Temp := R.BottomRight.x;
        R.BottomRight.x := R.TopLeft.x;
        R.TopLeft.x := Temp;
    end;
    if R.BottomRight.y < R.TopLeft.y then begin
        Temp := R.BottomRight.y;
        R.BottomRight.y := R.TopLeft.y;
        R.TopLeft.y := Temp;
    end;
end;

// ***********************************************************
//  combine areas of two aligned float rectangles - GDI coord system
// ***********************************************************

procedure CombineAlignedFloatRectangles(
    var Total : TAlignedFloatRect; NewRect : TAlignedFloatRect );
begin
    if Total.TopLeft.x > NewRect.TopLeft.x then begin
        Total.TopLeft.x := NewRect.TopLeft.x;
    end;
    if Total.TopLeft.y > NewRect.TopLeft.y then begin
        Total.TopLeft.y := NewRect.TopLeft.y;
    end;
    if Total.BottomRight.x < NewRect.BottomRight.x then begin
        Total.BottomRight.x := NewRect.BottomRight.x;
    end;
    if Total.BottomRight.y < NewRect.BottomRight.y then begin
        Total.BottomRight.y := NewRect.BottomRight.y;
    end;
end;

// *********************************************
//        distance between two points
// *********************************************

function DistanceBetweenPoints( Point1, Point2 : TFloatPoint ) : single;
var
    dx, dy : single;
begin
    dx := Point1.x - Point2.x;
    dy := Point1.y - Point2.y;
    result := sqrt( (dx * dx) + (dy * dy) );
end;

// *********************************************
//  Test if Rect is Completely inside Other Rect
// *********************************************

function EnclosesRectAligned( ARect, Container : TAlignedFloatRect ) : boolean;
begin
    result :=
        (ARect.TopLeft.x >= Container.TopLeft.x) and
        (ARect.TopLeft.y >= Container.TopLeft.y) and

        (ARect.BottomRight.x <= Container.BottomRight.x ) and
        (ARect.BottomRight.y <= Container.BottomRight.y );
end;

// *********************************************
//      Test if Two Rectangles Overlap
// *********************************************

function AlignedFloatRectsIntersect( Rect1, Rect2 : TAlignedFloatRect ) : boolean;
begin
    result :=
        (
        ((Rect1.TopLeft.x <= Rect2.TopLeft.x) and (Rect1.BottomRight.x > Rect2.TopLeft.x)) and  // X
        (((Rect1.TopLeft.y <= Rect2.TopLeft.y) and (Rect1.BottomRight.y > Rect2.TopLeft.y)) or  // Y
                ((Rect2.TopLeft.y <= Rect1.TopLeft.y) and (Rect2.BottomRight.y > Rect1.TopLeft.y)))
        )
        or
        (
        ((Rect2.TopLeft.x <= Rect1.TopLeft.y) and (Rect2.BottomRight.y > Rect1.TopLeft.y)) and  // X
        (((Rect2.TopLeft.y <=  Rect1.TopLeft.y) and (Rect2.BottomRight.y > Rect1.TopLeft.y)) or   // Y
                ((Rect1.TopLeft.y <= Rect2.TopLeft.y) and (Rect1.BottomRight.y > Rect2.TopLeft.y)))
        )
    ;
end;

// **************************************************
//          TEST OF TWO LINES INTERSECT
// **************************************************

// determine if 2 line cross given their end-points
function LinesCross(LineAP1, LineAP2, LineBP1, LineBP2 : TPoint) : boolean;

    function Subtract(AVec1, AVec2 : TPoint) : TPoint; inline;
    begin
      Result.X := AVec1.X - AVec2.X;
      Result.Y := AVec1.Y - AVec2.Y;
    end;

var
  diffLA, diffLB : TPoint;
  CompareA, CompareB : integer;
begin
  diffLA := Subtract(LineAP2, LineAP1);
  diffLB := Subtract(LineBP2, LineBP1);

  CompareA := diffLA.X*LineAP1.Y - diffLA.Y*LineAP1.X;
  CompareB := diffLB.X*LineBP1.Y - diffLB.Y*LineBP1.X;

  result :=
     ( ((diffLA.X*LineBP1.Y - diffLA.Y*LineBP1.X) < CompareA) xor
       ((diffLA.X*LineBP2.Y - diffLA.Y*LineBP2.X) < CompareA) ) and
     ( ((diffLB.X*LineAP1.Y - diffLB.Y*LineAP1.X) < CompareB) xor
       ((diffLB.X*LineAP2.Y - diffLB.Y*LineAP2.X) < CompareB) );
end;

end.
