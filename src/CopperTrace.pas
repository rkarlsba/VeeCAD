unit CopperTrace;

interface

uses Board, Types;

function SegmentsConnect( Segment1, Segment2 : TbrSegment ) : boolean;
function SegmentStripConnects( Segment : TbrSegment; Strip : TbrStrip ) : boolean;
function SegmentToCell( Segment : TbrSegment; Cell : TPoint ) : boolean;
function SegmentToRect( Segment : TbrSegment; Rect : TRect ) : boolean;


implementation

uses Intersect;

// **************************************************
//          DISTANCE FROM POINT TO LINE
// **************************************************

//Compute the dot product AB . BC of the two vectors AB and BC
function dot( A, B, C : TPoint ) : integer;
var
    AB : TPoint;
    BC : TPoint;
begin
     AB.X := B.X - A.X;
     AB.Y := B.Y - A.Y;
     BC.X := C.X - B.X;
     BC.Y := C.Y - B.Y;
     result := (AB.X * BC.X) + (AB.Y * BC.Y);
end;

//Compute the cross product AB x AC
function cross( A, B, C : TPoint ) : integer;
var
    AB : TPoint;
    AC : TPoint;
begin
    AB.X := B.X - A.X;
    AB.Y := B.Y - A.Y;
    AC.X := C.X - A.X;
    AC.Y := C.Y - A.Y;
    result := (AB.X * AC.Y) - (AB.Y * AC.X);
end;

//Compute the distance from A to B
function distance( A, B : TPoint ) : single;
var
    d1 : extended;
    d2 : extended;
//    test : extended;
begin
    d1 := A.X - B.X;
    d2 := A.Y - B.Y;
//    test := ( (d1 * d1) + (d2 * d2) );
    result := sqrt( (d1 * d1) + (d2 * d2) );
end;

//Compute the distance from line segment AB to point C
// AB is a segment, not an infinitely long line, so if line is too short,
// distance is taken to the nearest line end.

function linePointDist( A, B, C : TPoint ) : single;
var
    dist : single;
    dot1 : integer;
    dot2 : integer;
    LineLength : single;
begin
    // C is nearest to end B
    dot1 := dot( A,B,C );
    if( dot1 > 0 ) then begin
        result := distance(B,C);
        exit;
    end;
    // C is nearest to end A
    dot2 := dot(B,A,C);
    if( dot2 > 0 ) then begin
        result := distance(A,C);
        exit;
    end;

    // C is nearest to some point along the line between A and C
    //  warning - we have potential for a divide by zero error if distance(A,B)
    // is zero - ie. a zero length segment (donunt). In this case, return just
    // the distance from A to C:

    // if line A,B is zero length, we get a divide by zero. So for a short line
    // A,B we take the distance A,C, since A & B are the same point anyway.
    LineLength := distance(A,B);
    if LineLength < 0.01 then begin
        result := distance(A,C);
    end
    else begin
        dist := cross( A,B,C) / LineLength;
        result := abs( dist );
    end;
end;

// *************************************************
//       TEST IF TWO TRACK SEGMENTS CONNECT
// *************************************************

{ We can regard track segments as a center line with a "halo" of half the
track width on each side - and with semi-circular "halos" around the center line
end points. This reduces the track connection test to determining if the
distance between the two lines is less than half the track width.

To detect distance between centre lines:
Check for intersection of the two lines
Check for distance from each line end to the other line (4 ends)
}

function SegmentsConnect( Segment1, Segment2 : TbrSegment ) : boolean;
var
    CentresSeparation : single;
begin
    // distance between centre lines when two tracks just touch
    CentresSeparation := (Segment1.Width_1000 + Segment2.Width_1000) * 0.5;

    // point to line distance from all 4 ends
    result :=
      // Segment1 to X1,Y1 on Segment2
      (
      linePointDist(
        Point( Segment1.X1_1000, Segment1.Y1_1000 ),
        Point( Segment1.X2_1000, Segment1.Y2_1000 ),
        Point( Segment2.X1_1000, Segment2.Y1_1000 ) )
        < CentresSeparation
      ) or
      // Segment1 to X2,Y2 on Segment2
      (
      linePointDist(
        Point( Segment1.X1_1000, Segment1.Y1_1000 ),
        Point( Segment1.X2_1000,           Segment1.Y2_1000 ),
        Point( Segment2.X2_1000, Segment2.Y2_1000 ) )
        < CentresSeparation
      ) or
      // Segment2 to X1,Y1 on Segment1
      (
      linePointDist(
        Point( Segment2.X1_1000, Segment2.Y1_1000 ),
        Point( Segment2.X2_1000, Segment2.Y2_1000 ),
        Point( Segment1.X1_1000, Segment1.Y1_1000 ) )
        < CentresSeparation
       ) or
      // Segment2 to X2,Y2 on Segment1
      (
      linePointDist(
        Point( Segment2.X1_1000, Segment2.Y1_1000 ),
        Point( Segment2.X2_1000, Segment2.Y2_1000 ),
        Point( Segment1.X2_1000, Segment1.Y2_1000 ) )
        < CentresSeparation
      ) or
      // lines actually cross
      (
      LinesCross(
        Point( Segment1.X1_1000, Segment1.Y1_1000 ),
        Point( Segment1.X2_1000, Segment1.Y2_1000 ),
        Point( Segment2.X1_1000, Segment2.Y1_1000 ),
        Point( Segment2.X2_1000, Segment2.Y2_1000 )
      )
  );
end;

// *************************************************
//       TEST IF A SEGMENT AND A TRACK CONNECT
// *************************************************

function SegmentStripConnects( Segment : TbrSegment; Strip : TbrStrip ) : boolean;
const
    // track width in 1/1000's of a cell nominally 1/2 a cell
    TrackWidth_1000 = 500;
var
    CentresSeparation : single;
    TrackX1_1000, TrackY1_1000 : integer;
    TrackX2_1000, TrackY2_1000 : integer;
begin
    // convert track cell coords to 1/1000's of a cell as used for segments
    TrackX1_1000 := Strip.Start.X * 1000;
    TrackY1_1000 := Strip.Start.Y * 1000;
    TrackX2_1000 := Strip.Finish.X * 1000;
    TrackY2_1000 := Strip.Finish.Y * 1000;

    // distance between centre lines when two tracks just touch
    CentresSeparation := (Segment.Width_1000 + TrackWidth_1000) * 0.5;

    // point to line distance from all 4 ends
    result :=
      // Segment1 to X1,Y1 on Segment2
      (
      linePointDist(
        Point( Segment.X1_1000, Segment.Y1_1000 ),
        Point( Segment.X2_1000, Segment.Y2_1000 ),
        Point( TrackX1_1000, TrackY1_1000 ) )
        < CentresSeparation
      ) or
      // Segment1 to X2,Y2 on Segment2
      (
      linePointDist(
        Point( Segment.X1_1000, Segment.Y1_1000 ),
        Point( Segment.X2_1000, Segment.Y2_1000 ),
        Point( TrackX2_1000, TrackY2_1000 ) )
        < CentresSeparation
      ) or
      // Segment2 to X1,Y1 on Segment1
      (
      linePointDist(
        Point( TrackX1_1000, TrackY1_1000 ),
        Point( TrackX2_1000, TrackY2_1000 ),
        Point( Segment.X1_1000, Segment.Y1_1000 ) )
        < CentresSeparation
       ) or
      // Segment2 to X2,Y2 on Segment1
      (
      linePointDist(
        Point( TrackX1_1000, TrackY1_1000 ),
        Point( TrackX2_1000, TrackY2_1000 ),
        Point( Segment.X2_1000, Segment.Y2_1000 ) )
        < CentresSeparation
      ) or
      // lines actually cross
      (
      LinesCross(
        Point( Segment.X1_1000, Segment.Y1_1000 ),
        Point( Segment.X2_1000, Segment.Y2_1000 ),
        Point( TrackX1_1000, TrackY1_1000 ),
        Point( TrackX2_1000, TrackY2_1000 )
      )
  );
end;

// *************************************************
//    TEST IF A SEGMENT AND A CELL CIRCLE CONNECT
// *************************************************

function SegmentToCell( Segment : TbrSegment; Cell : TPoint ) : boolean;
const
    // track width in 1/1000's of a cell nominally 1/2 a cell
    TrackWidth_1000 = 500;
begin
    result := linePointDist(

        Point( Segment.X1_1000, Segment.Y1_1000 ),
        Point( Segment.X2_1000, Segment.Y2_1000 ),
        Point( Cell.X * 1000, Cell.Y * 1000 )
        )
        < ((TrackWidth_1000 + Segment.Width_1000) * 0.5);
end;

// *************************************************
// TEST IF A SEGMENT AND AN AXIS-ALIGNED RECTANGLE CONNECT
// *************************************************
{ If the segment is wholly contained within the rectangle, the result does not
matter, because the segment connects to nothing. Therefore, we want the
segment to intersect the borders of the rectangle.




}

{
function SegmentToRect( Segment : TbrSegment; Rect : TRect ) : boolean;
var
    RectCorner0 : TPoint;
    RectCorner1 : TPoint;
    RectCorner2 : TPoint;
    RectCorner3 : TPoint;
    LineEnd0 : TPoint;
    LineEnd1 : TPoint;
begin
    // extract data into TPoint. Corners start at top left and go around Clockwise
    RectCorner0.X := Rect.Left;
    RectCorner0.Y := Rect.Top;

    RectCorner1.X := Rect.Right;
    RectCorner1.Y := Rect.Top;

    RectCorner2.X := Rect.Right;
    RectCorner2.Y := Rect.Bottom;

    RectCorner3.X := Rect.Left;
    RectCorner3.Y := Rect.Bottom;

    LineEnd0.X := Segment.X1_1000;
    LineEnd0.Y := Segment.Y1_1000;
    LineEnd1.X := Segment.X2_1000;
    LineEnd1.Y := Segment.Y2_1000;

    // determine if 2 line cross given their end-points
    result :=
        LinesCross( LineEnd0, LineEnd1, RectCorner0, RectCorner1 ) OR
        LinesCross( LineEnd0, LineEnd1, RectCorner1, RectCorner2 ) OR
        LinesCross( LineEnd0, LineEnd1, RectCorner2, RectCorner3 ) OR
        LinesCross( LineEnd0, LineEnd1, RectCorner3, RectCorner0 );
    if result then begin
        asm nop end;
    end;
end;
}
function SegmentToRect( Segment : TbrSegment; Rect : TRect ) : boolean;
var
    Length : single;
    DeltaX, DeltaY : single;
    HalfWidth : single;
    SegmentRect : TFloatRect;
    ShiftX, ShiftY : single;
    PinRectF : TFloatRect;
    Circle : TFloatCircle;
    TopLeft, BottomRight : TFloatPoint;
begin
    // * Check if Segment Body Rectangle overlaps Rect *

    // segment must have width or overlap checks have divide by zero error
    // when calculating projection axis.
    if Segment.Width_1000 < 1 then begin
        Segment.Width_1000 := 1;
    end;

    // half width of segment
    HalfWidth := Segment.Width_1000 * 0.5;

    // calculate run & rise of segment
    DeltaX := Segment.X2_1000 - Segment.X1_1000;
    DeltaY := Segment.Y2_1000 - Segment.Y1_1000;

    // calculate length of segment centre line - not including rounded ends
    Length := SQRT((DeltaX * DeltaX) + (DeltaY * DeltaY));

    // if length is very short, then effectively have no centre rectangle, just
    // a single circle. So only test when length is reasonable.
    if Length > 0.1 then begin

        // calculate shift of segment rectangle x,y corners
        ShiftX := (HalfWidth * DeltaY) / Length;
        ShiftY := (HalfWidth * DeltaX) / Length;

        // calculate 4 corners of segment rectangle
        SegmentRect.Point1.x := Segment.X1_1000 - ShiftX;
        SegmentRect.Point1.y := Segment.Y1_1000 - ShiftY;

        SegmentRect.Point2.x := Segment.X2_1000 - ShiftX;
        SegmentRect.Point2.y := Segment.Y2_1000 - ShiftY;

        SegmentRect.Point3.x := Segment.X2_1000 + ShiftX;
        SegmentRect.Point3.y := Segment.Y2_1000 + ShiftY;

        SegmentRect.Point4.x := Segment.X1_1000 + ShiftX;
        SegmentRect.Point4.y := Segment.Y1_1000 + ShiftY;

        // Rectangle must not be zero height or width
        if Rect.Left = Rect.Right then begin
            Rect.Right := Rect.Left +1;
        end;
        if Rect.Top = Rect.Bottom then begin
            Rect.Bottom := Rect.Top +1;
        end;

        // fill a TFloatRect with Rectangle coords
        PinRectF.Point1.x := Rect.Left;
        PinRectF.Point1.y := Rect.Top;

        PinRectF.Point2.x := Rect.Right;
        PinRectF.Point2.y := Rect.Top;

        PinRectF.Point3.x := Rect.Right;
        PinRectF.Point3.y := Rect.Bottom;

        PinRectF.Point4.x := Rect.Left;
        PinRectF.Point4.y := Rect.Bottom;

        // test if Segment rectangle overlaps rectangle
        if RectanglesIntersect( SegmentRect, PinRectF ) then begin
            result := True;
            exit;
        end;
    end;

     // * see if end circles intersect *
    TopLeft.x := Rect.Left;
    TopLeft.y := Rect.Top;
    BottomRight.x := Rect.Right;
    BottomRight.y := Rect.Bottom;
    Circle.Radius := HalfWidth;

    Circle.Centre.x := Segment.X1_1000;
    Circle.Centre.y := Segment.Y1_1000;
    if CircleAlignedRectangleIntersect( TopLeft, BottomRight, Circle ) then begin
        result := True;
        exit;
    end;

    Circle.Centre.x := Segment.X2_1000;
    Circle.Centre.y := Segment.Y2_1000;
    if CircleAlignedRectangleIntersect( TopLeft, BottomRight, Circle ) then begin
        result := True;
    end
    else begin
        result := False;
    end;
end;













{
    Method: Project Line and Square onto axis


}

    // check if end circles interesect with pin rectangles



    // turn body of strip into rectangle.



end.




