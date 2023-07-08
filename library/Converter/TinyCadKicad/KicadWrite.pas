unit KicadWrite;

interface

uses Read, Classes, Types;

type TKicadWriter = class
  protected
     FReader : TSymbolLibraryReader;
     Stream : TStream;
     SymbolRect : TRect;
     SymbolCentre : TPoint;
     SymbolHeight : integer;
     SymbolWidth : integer;
     procedure LineOut( const Line : string );
     procedure EmitSymbol;
     procedure CalculateSymbolLocation;
  public
    property Reader : TSymbolLibraryReader read FReader write FReader;
    procedure WriteToFile( const FileName : string );
    procedure WriteToStream( S : TStream );

    constructor Create;
    destructor Destroy; override;
 end;


implementation

uses SysUtils, Rotations, Rectangles, Math, StrUtils;

type EKicadWriter = class( Exception );

const
    // normal snap is 50, fine snap is 25 : however, setting reverts when
    // program is reloaded!
    SNAP_MILS = 25;

// convert millimetres to mils
function ToMils( Millimetres : single ) : integer;
begin
    // true conversion of millimetres to mils
//    result := round( Millimetres * ( 1000.0 / 25.4 ) );

    // if we convert one millimetre to 50 mils, we get an on-grid
    // spacing of pins in Kicad. Parts are slightly larger, but all is OK.
    result := round( Millimetres * ( 1000.0 / 20 ) );
end;

// convert millimetres to mils, then snap to Kicad 25 mils grid
function ToMilsSnap( Millimetres : single ) : integer;
begin
    result := ToMils( Millimetres );

    // now snap to nearest
    if (result mod SNAP_MILS) > (SNAP_MILS div 2) then begin
        result := ((result div SNAP_MILS) * SNAP_MILS) + SNAP_MILS;
    end
    else begin
        result := ((result div SNAP_MILS) * SNAP_MILS);
    end;
end;

function ToMilsPoint( MillimetresPoint : TFloatPoint ) : TPoint;
begin
    result.X := ToMils( MillimetresPoint.x );
    result.Y := ToMils( MillimetresPoint.y );
end;

function Snap( Value : integer ) : integer;
begin
    if (Value mod SNAP_MILS) > (SNAP_MILS div 2) then begin
        result := ((Value div SNAP_MILS) * SNAP_MILS) + SNAP_MILS;
    end
    else begin
        result := (Value div SNAP_MILS) * SNAP_MILS;
    end;
end;

procedure SnapPoint( var Point : TPoint );
begin
    Point.X := Snap( Point.X );
    Point.Y := Snap( Point.Y );
end;

function SnapTo( Value, Step : integer ) : integer;
begin
    if (Value mod Step) > (Step div 2) then begin
        result := ((Value div Step) * Step) + Step;
    end
    else begin
        result := (Value div Step) * Step;
    end;
end;


// Limit angle to +/- 180 degrees
function LimitAngle( angle : single ) : single;
begin
    if angle > 180 then begin
//        angle := -(360 - angle);
        result := angle - 360;
    end
    else begin
        result := angle;
    end;
end;


procedure TKicadWriter.LineOut( const Line : string );
const
    CRLF : array[0..1] of ansichar = ( #13, #10 );
var
   oString: UTF8String;
begin
   oString := UTF8String(Line);
   Stream.WriteBuffer(oString[1], length(oString) * sizeof(ansichar) );
   Stream.WriteBuffer(CRLF, 2 * sizeof(ansichar) );
end;

constructor TKicadWriter.Create;
begin


end;

destructor TKicadWriter.Destroy;
begin
    inherited;
end;


procedure TKicadWriter.WriteToFile( const FileName : string );
var
    FileStream : TFileStream;
begin
    FileStream := TFileStream.Create( FileName, fmCreate  );
    try
        WriteToStream( FileStream )
    finally
        FileStream.Free;
    end;
end;

procedure TKicadWriter.WriteToStream(S: TStream);
var
    Line : string;
begin
    if not Assigned( FReader ) then begin
        raise EKicadWriter.Create( 'Reader not assigned' );
    end;


    Stream := S;

    // emit first line of any library file :
    // e.g. 'EESchema-LIBRARY Version 2.3  Date: 23/5/2007-07:37:51'
    Line := 'EESchema-LIBRARY Version 2.3  Date: ';
    Line := Line + FormatDateTime( 'dd/mm/yyyy-hh:mm:ss', Now );
    LineOut( Line );

    // emit components
    while not FReader.EOF do begin
        EmitSymbol;
        FReader.Next;
    end;

    // emit final lines
    // #
    // #End Library
    LineOut( '#' );
    LineOut( '#End Library' );
end;

procedure TKicadWriter.EmitSymbol;
const
    Rotation2Direction : array[TRotation] of string = ( 'R', 'U', 'L', 'D' );
    //  0=on pin, >0 =distance inside body
    PIN_TEXT_INSIDE_DISTANCE = 20;
    // draw line width
    LINE_WIDTH = 8;
    // designator, value text
    TEXT_SIZE = 50;
var
    NameNoSpaces : string;
    i : integer;
    Pin : TPin;
    PinName : string;
    Polygon : TPolygon;
    Line : string;
    j : integer;
    Point : TFloatPoint;
    Rectangle : TRectangle;
    Circle : TCircle;
    Arc : TArc;
    StartAngleRadians : single;
    EndAngleRadians : single;
begin
    // calculate where symbol lies so we can pull it onto point (0,0) to
    // make Kicad happy
    CalculateSymbolLocation;

    // convert name to a safe format, because Kicad cannot handle spaces
    NameNoSpaces :=
        Uppercase( StringReplace( FReader.Name, ' ', '_', [rfReplaceAll] ));


    // emit preamble : actually just comment lines to help human readability
    LineOut( '#' );
    LineOut( Format( '# %s', [Uppercase(FReader.Name)]) );
    LineOut( '#' );

    // 'DEF' line starts symbol definition
    // e.g. DEF BI_LED D 0 0 Y Y 1 F N
{
    DEF name reference unused text_offset draw_pinnumber draw_pinname unit_count units_locked option_flag
      name = component name in library (74LS02 ...)
      reference = Reference ( U, R, IC .., which become U3, U8, R1, R45, IC4...)
      unused = 0 (reserved)
      text_offset = offset for pin name text: 0=on pin, 1=inside component
      draw_pinnumber = Y (display pin number) or N (do not display pin number).
      draw_pinname = Y (display pin name) or N (do not display pin name).
      unit_count = Number of part ( or section) in a component package.
      units_locked = = L (units are not identical and cannot be swapped) or F (units are identical and therefore can be swapped) (Used only if unit_count > 1)
      option_flag = N (normal) or P (component type "power")
}
    LineOut( Format(
      'DEF %s %s %d %d %s %s %d %s %s',
      [ NameNoSpaces,
        FReader.Reference,
        0,    // unused, always 0
        PIN_TEXT_INSIDE_DISTANCE,    // pin name text offset  0=on pin, else distance inside component
        'Y',                         // pin number visible
        'Y',                         // pin name visible
        FReader.PartsPerPackage,
        'L',                         // multi-part sections cannot be swapped
        'N'
      ]
      ));

      // F0, F1 & F2 lines define Reference, Name & Package displays respectively
      // e.g F0 "D" 300 100 50 H V C C
      //     F1 "BI_LED" 350 -100 50 H V C C
      //     F2 "DIP8" 0 0 50 H V C C

      {
    F0 reference posx posy text_size text_orient visibile htext_justify vtext_justify
    F1 name posx posy text_size text_orient visibility htext_justify vtext_justify
    F2 package, x, y, text_size, text_orient visible, htext_justify vtext_justify

      reference = Reference ( U, R, IC .., which become U3, U8, R1, R45, IC4...)
      name = component name in library (74LS02 ...)
      posx, posy = position of the text label
      text_size = Size of the displayed text
      text_orient = Displayed text orientation (V=Vertical, H=Horizontal(default))
      visible = Is label displayed (I=Invisible, V=Visible(default))
      htext_justify = Horizontal text justify (L=Left, R=Right, C=Centre(default))
      vtext_justify = Vertical text justify (T=Top, B=Bottom, C=Centre(default))
}
    LineOut( Format(
      'F0 "%s" %d %d %d %s %s %s %s',
      [ FReader.Reference,
        -Snap((SymbolWidth div 2)),  // text x coord : to right of part
        Snap((SymbolHeight div 2) + 200),  // text y coord : above part
        TEXT_SIZE,    // text size
        'H',          // text orientation V or H
        'V',          // V=visible, I=Invisible
        'L',          // Horizontal text justify L(eft),C(entre),R(ight)
        'C'           // Vertical text justify
      ]
      ));

    LineOut( Format(
      'F1 "%s" %d %d %d %s %s %s %s',
      [ NameNoSpaces,
        -Snap((SymbolWidth div 2)),  // text x coord : to right of part
        Snap((SymbolHeight div 2) + 100),  // text y coord : above part
        TEXT_SIZE,  // text size
        'H',        // text orientation V or H
        'V',        // V=visible, I=Invisible
        'L',        // Horizontal text justify L(eft),C(entre),R(ight)
        'C'         // Vertical text justify
      ]
      ));

    LineOut( Format(
      'F2 "%s" %d %d %d %s %s %s %s',
      [ FReader.Package,
        0,    // text x coord : don't care if not visible
        0,    // text y coord : don't care if not visible
        TEXT_SIZE,   // text size : don't care if not visible
        'H',  // text orientation V or H
        'I',  // V=visible, I=Invisible
        'C',  // Horizontal text justify L(eft),C(entre),R(ight)
        'C'   // Vertical text justify
      ]
      ));

    // $FPLIST defines a number of packages- we provide only one
    LineOut( '$FPLIST' );
    LineOut( ' ' + FReader.Package );
    LineOut( '$ENDFPLIST' );

    // 'DRAW' begins description of graphical appearance
    LineOut( 'DRAW' );


    // output pins
    // e.g. X P7 7 350 50 300 L 60 60 1 1 P I
{
  X name num posx posy length direction name_text_size num_text_size unit convert electrical_type pin_type
      name = name displayed on the pin
      num = pin no. displayed on the pin
      posx = Position X same units as the length
      posy = Position Y same units as the length
      length = length of pin
      direction = R/L/U/D R for Right L for left etc.
      name_text_size = Text size for the pin name
      num_text_size = Text size for the pin number
      unit = 0 if common to the parts; if not, number of part (1. .n).
      convert :
      convert = 0 so common to the representations, if not 1 or 2.
      electrical_type = Elec. Type of pin (I=Input, O=Output, B=Bidi, T=tristate,P=Passive, U=Unspecified, W=Power In, w=Power Out, C=Open Collector, E=Open Emitter)
      pin_type= Type of pin (N=No Draw, I=Invert (hollow circle), C=Clock, L=Low In (IEEE), V=Low Out (IEEE)). Seems to be optional.
}
    for i := 0 to FReader.PinCount - 1 do begin

        Pin := FReader.Pins[i];

        // pin name can't be empty, or contain spaces
        PinName := ReplaceStr( Pin.Name, ' ', '_' );
        // '~' means hide pin name
        if PinName = '' then begin
            PinName := '~'
        end;

        LineOut( Format(
            'X %s %s %d %d %d %s %d %d %d %d %s',
            [ PinName,                          // name
              Pin.Number,                       // number
              ToMilsSnap(Pin.Position.x) - SymbolCentre.x,       // x pos
              -(ToMilsSnap(Pin.Position.y) - SymbolCentre.y),    // y pos : inverted coords!!
              ToMils(Pin.Length),               // length
              Rotation2Direction[Pin.Rotation], // direction
              TEXT_SIZE,                        // name text size
              TEXT_SIZE,                        // number text size
              Pin.Part + 1,                     // Unit :package part show multi part packages
              0,                                // convert :
              'U'                               // electrical type
//              'I'                             // pin type unspecified (omit)
            ]
         ));
    end;

    // Output Polygons
    // e.g. P 2 0 1 16  100 100  100 -100 N
    // e.g LM324 : P 4 0 1 6  -200 200  200 0  -200 -200  -200 200 f
    {
    P point_count unit convert thickness (posx posy)* fill

    point_count : number of coord pairs
    unit = 0 if common to the parts; if not, number of part (1. .n).
    convert : convert = 0 if common to the 2 representations, if not 1 or 2.
    thickness : line thickness (mils) 0 to 16 observed.
    posx posy : a number of coord x,y values
    fill : F=filled with foreground color, f=filled with background color, N=no_fill
}
    for i := 0 to FReader.PolygonCount - 1 do begin
        // build first part of polygon text line
        Polygon := FReader.Polygons[i];
        Line := Format(
            'P %d %d %d %d ',
            [ Polygon.PointCount,   // number of points
              0,                    // 0 : common to all parts
              0,                    // always 0 : only one format (no deMorgan)
              LINE_WIDTH            // thickness often 0 or 8,12,16
             ]
         );
         // add coord pairs to polygon text line
         for j := 0 to Polygon.PointCount - 1 do begin
            Point := Polygon.Points[j];
            Line := Line + Format( '%d %d ',
                [ ToMils( Polygon.Position.x + Point.x ) - SymbolCentre.x,
                  -(ToMils( Polygon.Position.y + Point.y ) - SymbolCentre.Y) // inverted y!!
                ] );
         end;

         // add fill - always set to none
         Line := Line + 'N';

         LineOut( Line );
    end;

    // output rectangles
    // e.g. S -100 -1250 150 1250 0 1 0 N
{

    S startx starty endx endy unit convert thickness fill
    startx, starty = Starting corner of the rectangle
    endx, endy = End corner of the rectangle
    unit = 0 if common to the parts; if not, number of part (1. .n).
    convert : convert = 0 if common to the 2 representations, if not 1 or 2.
    thickness : line thickness (mils) 0 to 16 observed.
    fill : F=filled with foreground color, f=filled with background color, N=no_fill
}
    for i := 0 to FReader.RectangleCount - 1 do begin
        // build first part of rectangle text line
        Rectangle := FReader.Rectangles[i];
        LineOut ( Format(
            'S %d %d %d %d %d %d %d %s',
            [ ToMils( Rectangle.TopLeft.x ) - SymbolCentre.X,
              -(ToMils( Rectangle.TopLeft.y ) - SymbolCentre.Y),
              ToMils( Rectangle.BottomRight.x ) - SymbolCentre.X,
              -(ToMils( Rectangle.BottomRight.y ) - SymbolCentre.Y),
              0,                // unit : 0=common to all parts
              0,                // convert : 0=applies to both symbol forms
              LINE_WIDTH,       // thickness
              'N'               // no fill
            ] ));
    end;

    // output circles
{
C posx posy radius unit convert ltrait cc
• posx, posy are location of centre
• unit = 0 if common to the parts; if not, number of part (1. .n).
• convert = 0 so common to the representations, if not 1 or 2.
• ltrait = thickness.
• cc = N F or F ( F = filled Rectangle,; f = . filled Rectangle, transparent background)
  Example:
  C 0 0 70 0 1 0 F
  C 0 0 20 0 1 0 N
}
    for i := 0 to FReader.CircleCount - 1 do begin
        Circle := FReader.Circles[i];
        LineOut ( Format(
            'C %d %d %d %d %d %d %s',
            [ ToMils( Circle.Centre.x ) - SymbolCentre.X, // centre X
              -(ToMils( Circle.Centre.y ) - SymbolCentre.Y),// centre Y
              ToMils( Circle.Radius ),                      // radius
              0,                                            // unit: 0=all units
              0,                                            // convert: 0=both forms
              LINE_WIDTH,                                   // line thickness
              'N'                                           // N=no fill
             ]
        ));
    end;

    // output arcs
    // e.g. A 0 -150 50 -889 889 0 1 0 N 1 -199 1 -100
{
 With posx posy radius start_angle end_angle part convert ltrait start_pointX start_pointY end_pointX end_pointY cc
• start = angle of the starting point (in 0,1 degrees).
• end = angle of the end point (in 0,1 degrees).
• unit = 0 so common to the parts; if not, number of part (1. .n).
• convert = 0 if common to the representations, if not 1 or 2.
• ltrait = thickness.
• fill : N, F fill, no fill
• start_pointX start_pointY = coord of the starting point (role similar to start)
• end_pointX end_pointY = coord of the point of arrival (role similar to end)
• cc = ?N F or F ( F = filled Rectangle,; f = . filled Rectangle, transparent background)
}
    for i := 0 to FReader.ArcCount - 1 do begin
        Arc := FReader.Arcs[i];
        StartAngleRadians := DegToRad( Arc.StartAngleDegrees );
        EndAngleRadians := DegToRad( Arc.EndAngleDegrees );

        LineOut ( Format(
            'A %d %d %d %d %d %d %d %d %s %d %d %d %d',
            [ ToMils( Arc.Centre.x ) - SymbolCentre.X,    // centre X
              -(ToMils( Arc.Centre.y ) - SymbolCentre.Y), // centre Y
              ToMils( Arc.Radius ),                       // radius
              round(LimitAngle(Arc.StartAngleDegrees) * 10),  // start angle 0.1 degrees
              round(LimitAngle(Arc.EndAngleDegrees) * 10),    // end angle 0.1 degrees
              0,                                         // unit: 0=all units
              0,                                         // convert: 0=both forms
              LINE_WIDTH,                                // line thickness
              'N',                                       // No fill
              ToMils(Arc.Radius * cos(StartAngleRadians) + Arc.Centre.x) - SymbolCentre.X,  // startX
              -(ToMils(-Arc.Radius * sin(StartAngleRadians) + Arc.Centre.y) - SymbolCentre.Y),  // startY
              ToMils(Arc.Radius * cos(EndAngleRadians) + Arc.Centre.x) - SymbolCentre.X,    // endX
              -(ToMils(-Arc.Radius * sin(EndAngleRadians) + Arc.Centre.y) - SymbolCentre.Y)     // endY
                                                              // cc : can omit
        ] )
        );
    end;

    // 'ENDDRAW' finishes drawing section
    LineOut( 'ENDDRAW' );


    // 'ENDDEF' finishes symbol definition
    LineOut( 'ENDDEF' );
end;

function RotatePoint( Point, Pivot : TPoint; Rotation : TRotation ) : TPoint;
begin
    case Rotation of
        rot180 : { 180 degree } begin
            result.X := (2 * Pivot.X) - Point.X;
            result.Y := (2 * Pivot.Y) - Point.Y;
        end;
        rot0 : { zero rotation }
            ;
        rot90 : { 90 degree } begin
            Result.X := Pivot.X + (Point.Y - Pivot.Y);
            Result.Y := Pivot.Y - (Point.X - Pivot.X);
        end;
        rot270 :  { -90 degree } begin
            Result.X := Pivot.X - (Point.Y - Pivot.Y);
            Result.Y := Pivot.Y + (Point.X - Pivot.X);
        end;
    end;
end;

procedure RotateRect( var Rect : TRect; Point : TPoint; Rotation : TRotation );
begin
    // rotate all nodes around point
    Rotate( Rect.Top, Rect.Left, Point.X, Point.Y, Rotation );
    Rotate( Rect.Bottom, Rect.Right, Point.X, Point.Y, Rotation );
end;

procedure ExtendRectangleByPoint( var Rect : TRect; Point : TPoint );
begin
    if Rect.Left > Point.x then begin
        Rect.Left := Point.X;
    end;
    if Rect.Right < Point.x then begin
        Rect.Right := Point.X
    end;
    if Rect.Top > Point.y then begin
        Rect.Top := Point.Y
    end;
    if Rect.Bottom < Point.y then begin
        Rect.Bottom := Point.y
    end;
end;

function AddPoints( Point1, Point2 : TPoint ) : TPoint;
begin
    result.X := Point1.X + Point2.X;
    result.Y := Point1.Y + Point2.Y;
end;

// ***********************************************
//              CALCULATE SYMBOL SIZE
// ***********************************************
{
  Calculates the class variables:
      SymbolTop
      SymbolBottom
      SymbolCentre

  These variables permitsother code to center the symbol and
  place name and designator text.
}

procedure TKicadWriter.CalculateSymbolLocation;
var
    i : integer;
    Rect : TRect;
    Point : TPoint;
    Pivot : TPoint;
    Polygon : TPolygon;
    j : integer;
    CentreX, CentreY, radius : integer;
begin
      // make the bounding rectangle "empty"
     SymbolRect.Left := High( integer );
     SymbolRect.Top := High( integer );
     SymbolRect.Right := Low( integer );
     SymbolRect.Bottom := Low( integer );

    // include pins into symbol area
    for i := 0 to FReader.PinCount - 1 do begin
        // pivot point
        Pivot := ToMilsPoint(Reader.Pins[i].Position);
        ExtendRectangleByPoint( SymbolRect, Pivot );

        // other end of pin not important, since pins face *inwared*
{
        Point := Pivot;
        Point.X := Point.X + ToMils(Reader.Pins[i].Length);
        RotatePoint( Point, Pivot,
        Point.X := Point.X + ToMils(Reader.Pins[i].Length);
        RotatePoint( Point, Point.X, Point.Y, Reader.Pins[i].Rotation );
        ExtendRectangleByPoint( SymbolRect, Point );
}
    end;

    // include polygon points into symbol area
    for i := 0 to Reader.PolygonCount - 1 do begin
        Polygon := Reader.Polygons[i];
        for j := 0 to Polygon.PointCount - 1 do begin
            Point := AddPoints( ToMilsPoint(Polygon.Position), ToMilsPoint(Polygon.Points[j]) );
            ExtendRectangleByPoint( SymbolRect, Point );
        end;
    end;

    // CIRCLES
    for i := 0 to Reader.CircleCount - 1 do begin

        CentreX := ToMils(Reader.Circles[i].Centre.x);
        CentreY := ToMils(Reader.Circles[i].Centre.y);
        Radius := ToMils(Reader.Circles[i].Radius);

        Rect.Top := CentreY - Radius;
        Rect.Left := CentreX - Radius;
        Rect.Bottom := CentreY + Radius;
        Rect.Right := CentreX + Radius;

        ExtendRectangle( SymbolRect, Rect );
    end;

    // RECTANGLES
    for i := 0 to Reader.RectangleCount - 1 do begin

        Rect.TopLeft := ToMilsPoint(Reader.Rectangles[i].TopLeft);
        Rect.BottomRight := ToMilsPoint(Reader.Rectangles[i].BottomRight);

        ExtendRectangle( SymbolRect, Rect );
    end;

    // now we have a rectangle enclosing our component

    // work out centre of rectangle
    SymbolCentre.X := ( SymbolRect.Left + SymbolRect.Right ) div 2;
    SymbolCentre.Y := ( SymbolRect.Top + SymbolRect.Bottom ) div 2;
    SnapPoint( SymbolCentre );

    // see if the first pin is on grid when offset by symbol centre: if not,
    // move it on grid.

    if Reader.PinCount > 0 then begin

        // calculate the position of this pin when offset by SymbolCentre
        Point.x := ToMilsSnap(Reader.Pins[0].Position.x) - SymbolCentre.x;
        Point.y := ToMilsSnap(Reader.Pins[0].Position.y) - SymbolCentre.y;

        // nudge symbol centre if pin lies on a 25 mils grid - get it onto 50 mils grid
        if Abs(Point.x mod 50) > 12 then begin
            Inc( SymbolCentre.x, 25 );
        end;

        if Abs(Point.y mod 50) > 12 then begin
            Inc( SymbolCentre.y, 25 );
        end;
    end;

    SymbolHeight := SymbolRect.Bottom - SymbolRect.Top;
    SymbolWidth := SymbolRect.Right - SymbolRect.Left;
end;


end.


