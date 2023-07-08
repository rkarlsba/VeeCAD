unit TestCopperTrace;

interface


procedure TestLinesIntersect;
procedure TestSegmentToRect;


implementation

uses Types, SysUtils, CopperTrace, Board;

procedure Error( comment : string );
begin
    raise Exception.Create( 'Error ' + comment );
end;

procedure TestLinesIntersect;
begin
    // Vertical and Horizontal lines
    if not LinesCross( Point(5, 5), Point(10,5), Point(7,0), Point(7,15) ) then begin
        Error( 'LinesIntersect: Lines cross not detected' );
    end;
    if LinesCross( Point(5, 5), Point(10,5), Point(7,0), Point(7,4) ) then begin
       Error( 'LinesIntersect: Wrongly detected lines cross' );
    end;

    // Criss-cross lines
    if not LinesCross( Point(5, 5), Point(10,15), Point(5,15), Point(15,4) ) then begin
        Error( 'LinesIntersect: Lines cross not detected' );
    end;
    if LinesCross( Point(5, 50), Point(10,15), Point(5,15), Point(15,4) ) then begin
       Error( 'LinesIntersect: Wrongly detected lines cross' );
    end;
end;

procedure TestSegmentToRect;
var
    Segment : TbrSegment;
    Rect : TRect;
begin
    Segment := TbrSegment.Create;
    try


        // rect intersects with segment, but not at segment end point
        // segment horizontal
        Segment.X1_1000 := 1000;
        Segment.Y1_1000 := 1000;
        Segment.X2_1000 := 2000;
        Segment.Y2_1000 := 1000;
        Segment.Width_1000 := 100;

        Rect.Left := 1500;
        Rect.Top := 990;
        Rect.Right := 1510;
        Rect.Bottom := 1100;
{
        if not SegmentToRect( Segment, Rect ) then begin
           Error( 'SegmentToRect: Intersect not detected' );
        end;
}
        // rect intersects with segment, but not at segment end point
        // segment vertical, no intersection
        Segment.X1_1000 := 1000;
        Segment.Y1_1000 := 1000;
        Segment.X2_1000 := 1000;
        Segment.Y2_1000 := 2000;
        Segment.Width_1000 := 100;

        Rect.Left := 1500;
        Rect.Top := 990;
        Rect.Right := 1510;
        Rect.Bottom := 1100;
{
        if SegmentToRect( Segment, Rect ) then begin
           Error( 'SegmentToRect: Intersect wrongly detected' );
        end;
}
         // rect intersects with segment, with segment at 45 degrees angle
         // and rectangle near center.
        Segment.X1_1000 := 1000;
        Segment.Y1_1000 := 1000;
        Segment.X2_1000 := 10000;
        Segment.Y2_1000 := 10000;
        Segment.Width_1000 := 1000;

        Rect.Left := 5500;
        Rect.Top := 5500;
        Rect.Right := 5800;
        Rect.Bottom := 5800;

        if not SegmentToRect( Segment, Rect ) then begin
           Error( 'SegmentToRect: Intersect not detected' );
        end;

        // segment end just touches top of rectangle - tests end circle intersect
        Segment.X1_1000 := 7000;
        Segment.Y1_1000 := 1000;
        Segment.X2_1000 := 7000;
        Segment.Y2_1000 := 6000;
        Segment.Width_1000 := 100;

        Rect.Left := 6800;
        Rect.Top := 6049;
        Rect.Right := 7200;
        Rect.Bottom := 7300;

        if not SegmentToRect( Segment, Rect ) then begin
           Error( 'SegmentToRect: Intersect not detected' );
        end;

        // same as previous, but Segment Ends swapped
        Segment.X1_1000 := 7000;
        Segment.Y1_1000 := 6000;
        Segment.X2_1000 := 7000;
        Segment.Y2_1000 := 1000;
        Segment.Width_1000 := 100;

        if not SegmentToRect( Segment, Rect ) then begin
           Error( 'SegmentToRect: Intersect not detected' );
        end;

    finally
        Segment.Free;
    end;
end;

end.
