unit RadialOutlines;

interface

uses Outlines, SizeableOutlines, Painter, Classes, Types;

const TveRadial_MaxDiam = 20;

// ***************************************
//              TveRadialOutline
// ***************************************


type TveRadialOutline = class( TveSizeableOutline )

    protected

    FLeadSpacing : integer;
    FDiameter : integer;
    FBodyWidth : integer;
  
    public

    property LeadSpacing : integer read FLeadSpacing write FLeadSpacing;
    property Diameter : integer read FDiameter write FDiameter;

    procedure Paint( Item : TveBoardItem;  Info : TvePainter ); override;

    function OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
        : boolean; override;
    procedure GetScreenRectR( Item : TveBoardItem; var R : TRect ); override;        

    constructor Create; override;
    function Clone : TveOutline; override;
    function Identical( Outline : TveOutline ) : boolean; override;
    procedure SetDefaultLength( Item : TveBoardItem ); override;   
    procedure WriteToStream( S : TStream ); override;
    procedure ReadFromStream( S : TStream ); override;
end;


implementation

uses Rotations, SysUtils, Rectangles, Intersect, Math;


// *********************************
//        TveRadialOutline
// *********************************

constructor TveRadialOutline.Create;
begin
    inherited;
    FLeadSpacing := 2;
    FDiameter := 4;
    FRotatable := True;
    FUserDefined := True;
    FShowsDesignator := True;
    FShowsValue := True;
end;

function TveRadialOutline.Clone : TveOutline;
begin
    result := TveRadialOutline.Create;
    TveRadialOutline(result).Name := Name;
    TveRadialOutline(result).FLeadSpacing := FLeadSpacing;
    TveRadialOutline(result).FDiameter := FDiameter;
    TveRadialOutline(result).Pins[0].Name := Pins[0].Name;
    TveRadialOutline(result).Pins[1].Name := Pins[1].Name;
end;

function TveRadialOutline.Identical( Outline : TveOutline ) : boolean;
begin
    result :=
    (Outline is TveRadialOutline) and
    (TveRadialOutline(Outline).FLeadSpacing = FLeadSpacing) and
    (TveRadialOutline(Outline).FDiameter = FDiameter) and
    (TveRadialOutline(Outline).Pins[0].Name = Pins[0].Name ) and
    (TveRadialOutline(Outline).Pins[1].Name = Pins[1].Name );
end;



// Calculate the perimeter of a leaded outline - by describing a circle and
// a rectangle
procedure CalculateRadialPerimeter(
    Pin2Delta : TPoint; Diameter : integer; LeadSpacing : integer;
    var Body : TFloatCircle; var Leads : TFloatRect
    );
var
    Hypotenuse : single;
    SinTheta : single;
    CosTheta : single;

    // rotate point about (0,0), by angle Theta
    procedure Rotate( var Point : TFloatPoint );
    var
        XTemp, YTemp : single;
    begin
        XTemp := Point.X;
        YTemp := Point.Y;
        // X negated to match negated Y coord system used by VeeCAD & Windows
        Point.X := -(XTemp*CosTheta - YTemp*SinTheta);
        Point.Y :=   XTemp*SinTheta + YTemp*CosTheta;
    end;

const
    HalfWidth = 0.125;
    HeightExtra = 0.25;

begin
    // theta is the angle of rotation. Zero rotation occurs when the part is
    // drawn with pin 2 directly below pin 1 : ie EndDeltaX = 0
    Hypotenuse :=  sqrt((Pin2Delta.X * Pin2Delta.X) + (Pin2Delta.Y * Pin2Delta.Y));
    SinTheta := Pin2Delta.X / Hypotenuse;
    CosTheta := Pin2Delta.Y / Hypotenuse;

    // Will calculate leads as thin rectangle, hole to hole length, 1/8 cell width
    // .. top left
    Leads.Point1.X := -HalfWidth;
    Leads.Point1.Y := -HeightExtra;
    // .. top right
    Leads.Point2.X := HalfWidth;
    Leads.Point2.Y := -HeightExtra;
    // bottom right
    Leads.Point3.X :=  HalfWidth;
    Leads.Point3.Y := Hypotenuse + HeightExtra;
    // .. bottom left
    Leads.Point4.X := -HalfWidth;
    Leads.Point4.Y := Hypotenuse + HeightExtra;

    // rotate rectangle points to final position
    Rotate( Leads.Point1 );
    Rotate( Leads.Point2 );
    Rotate( Leads.Point3 );
    Rotate( Leads.Point4 );

    // Body circle
    Body.Centre.x := 0;
    Body.Centre.y := Hypotenuse * 0.5;
    Body.Radius := Diameter * 0.5;

    Rotate( Body. Centre );
end;


// Calculate the three shapes that make up a radial outline.
// Pin 1 of the outline is at 0,0, Pin 2 is at 0,Pin2Delta
// All parameters are in cell units. To convert to screen coords, multiply
// returned coords by PixelsPerCell and add Item.X * PixelsPerCell etc
// If WideLead=True, TopLead, BottomLead each contain a single line between
// TopLead.Point1 and TopLead.Point2, BottomLead.Point1 and BottomLead.Point2.
// Bar1, Bar2 contain start, end of line that shows component pin 1 end.

procedure CalculateRadialOutline(
    Pin2Delta : TPoint; Diameter : integer; LeadSpacing : integer; WideLead : boolean;
    var Body : TFloatCircle;
    var TopLead, BottomLead : TFloatRect;
    var LeadCircle : TFloatCircle;
    var LeadSquare : TFloatRect;
    var RectLeads : boolean );

var
    Hypotenuse : single;
    SinTheta : single;
    CosTheta : single;

    // rotate point about (0,0), by angle Theta
    procedure Rotate( var Point : TFloatPoint );
    var
        XTemp, YTemp : single;
    begin
        XTemp := Point.X;
        YTemp := Point.Y;
        // X negated to match negated Y coord system used by VeeCAD & Windows
        Point.X := -(XTemp*CosTheta - YTemp*SinTheta);
        Point.Y :=   XTemp*SinTheta + YTemp*CosTheta;
    end;

const
    LeadHalfWidth = 0.125;
    LeadHeightExtra = 0.25;
    Undersize = 0.125;

    LeadSquareHalfWidth = 0.375;
    LeadCircleRadius = 0.5;

var
    Pin1Y, Pin2Y : single;
    Y1, Y2 : single;
begin
    // theta is the angle of rotation. Zero rotation occurs when the part is
    // drawn with pin 2 directly below pin 1 : ie EndDeltaX = 0
    Hypotenuse :=  sqrt((Pin2Delta.X * Pin2Delta.X) + (Pin2Delta.Y * Pin2Delta.Y));
    SinTheta := Pin2Delta.X / Hypotenuse;
    CosTheta := Pin2Delta.Y / Hypotenuse;

    // Body circle
    Body.Centre.x := 0;
    Body.Centre.y := Hypotenuse * 0.5;
    Body.Radius := (Diameter * 0.5) - Undersize;

    // Pin positions
    Pin1Y := Body.Centre.Y - (LeadSpacing * 0.5);
    Pin2Y := Body.Centre.Y + (LeadSpacing * 0.5);

    // draw square around where pin 1 lead emerges from guts
    LeadSquare.Point1.x := - LeadSquareHalfWidth;
    LeadSquare.Point1.y := Pin1Y - LeadSquareHalfWidth;
    LeadSquare.Point2.x :=  + LeadSquareHalfWidth;
    LeadSquare.Point2.y :=  LeadSquare.Point1.y;
    LeadSquare.Point3.x :=  + LeadSquareHalfWidth;
    LeadSquare.Point3.y :=  Pin1Y + LeadSquareHalfWidth;
    LeadSquare.Point4.x :=  - LeadSquareHalfWidth;
    LeadSquare.Point4.y :=  LeadSquare.Point3.y;

    // draw circle around whre pin 2 lead emerges from guts
    LeadCircle.Centre.x := 0;
    LeadCircle.Centre.y := Pin2Y;
    LeadCircle.Radius := LeadCircleRadius;

    // if leads are stretched
    if abs(Hypotenuse - LeadSpacing) > 0.01 then begin

        // calculate and draw leads hollow style
        if WideLead then begin

            // notify that leads should be drawn as rectangles
            RectLeads := True;

            // Will draw leads as thin rectangle, hole to hole length, 1/8 cell width
            // ...find coords of rectangle
            if Hypotenuse > LeadSpacing then begin
                // Y1 is near top board pin hole (top pin lead)
                Y1 := -LeadHeightExtra;
                // Y2 is near bottom board pin hole (bottom pin lead)
                Y2 := Hypotenuse + LeadHeightExtra;
            end
            else begin
                Y1 := +LeadHeightExtra;
                Y2 := Hypotenuse - LeadHeightExtra;
            end;

            // ... draw top leads rectangle
            TopLead.Point1.x := -LeadHalfWidth;
            TopLead.Point1.y := Y1;
            TopLead.Point2.x := LeadHalfWidth;
            TopLead.Point2.y := Y1;

            TopLead.Point3.x := LeadHalfWidth;
            TopLead.Point3.y := Pin1Y;
            TopLead.Point4.x := -LeadHalfWidth;
            TopLead.Point4.y := Pin1Y;

            // ... draw lower leads rectangle
            BottomLead.Point1.x := -LeadHalfWidth;
            BottomLead.Point1.y := Y2;
            BottomLead.Point2.x := LeadHalfWidth;
            BottomLead.Point2.y := Y2;

            BottomLead.Point3.x := LeadHalfWidth;
            BottomLead.Point3.y := Pin2Y;
            BottomLead.Point4.x := -LeadHalfWidth;
            BottomLead.Point4.y := Pin2Y;

            Rotate( TopLead.Point1 );
            Rotate( TopLead.Point2 );
            Rotate( TopLead.Point3 );
            Rotate( TopLead.Point4 );

            Rotate( BottomLead.Point1 );
            Rotate( BottomLead.Point2 );
            Rotate( BottomLead.Point3 );
            Rotate( BottomLead.Point4 );
        end

        // draw leads Line style
        else begin // lsLine

            // notify that leads should be drawn as rectangles
            RectLeads := False;

            TopLead.Point1.X := 0;
            TopLead.Point1.Y := 0;
            TopLead.Point2.X := 0;
            TopLead.Point2.Y := Pin1Y;

            BottomLead.Point1.x := 0;
            BottomLead.Point1.y := Pin2Y;
            BottomLead.Point2.x := 0;
            BottomLead.Point2.y := Hypotenuse;

            Rotate( TopLead.Point1 );
            Rotate( TopLead.Point2 );

            Rotate( BottomLead.Point1 );
            Rotate( BottomLead.Point2 );
        end;
    end

    // else leads are not stretched, so draw simple pins
    else begin
        // notify that leads should be drawn as rectangles
        RectLeads := True;

        // ... draw upper leads rectangle (pin 1)
        TopLead.Point1.x := -LeadHalfWidth;
        TopLead.Point1.y := Pin1Y - LeadHalfWidth;
        TopLead.Point2.x := LeadHalfWidth;
        TopLead.Point2.y := TopLead.Point1.y;

        TopLead.Point3.x := LeadHalfWidth;
        TopLead.Point3.y := Pin1Y + LeadHalfWidth;
        TopLead.Point4.x := -LeadHalfWidth;
        TopLead.Point4.y := TopLead.Point3.y;

        // ... draw lower leads rectangle (pin 2)
        BottomLead.Point1.x := -LeadHalfWidth;
        BottomLead.Point1.y := Pin2Y - LeadHalfWidth;
        BottomLead.Point2.x := LeadHalfWidth;
        BottomLead.Point2.y := BottomLead.Point1.y;

        BottomLead.Point3.x := LeadHalfWidth;
        BottomLead.Point3.y := Pin2Y + LeadHalfWidth;
        BottomLead.Point4.x := -LeadHalfWidth;
        BottomLead.Point4.y := BottomLead.Point3.y;

        Rotate( TopLead.Point1 );
        Rotate( TopLead.Point2 );
        Rotate( TopLead.Point3 );
        Rotate( TopLead.Point4 );

        Rotate( BottomLead.Point1 );
        Rotate( BottomLead.Point2 );
        Rotate( BottomLead.Point3 );
        Rotate( BottomLead.Point4 );
    end;

    // rotate the lead circles and rectangles
    Rotate( Body. Centre );

    Rotate( LeadSquare.Point1 );
    Rotate( LeadSquare.Point2 );
    Rotate( LeadSquare.Point3 );
    Rotate( LeadSquare.Point4 );

    Rotate( LeadCircle.Centre );
end;

procedure TveRadialOutline.Paint( Item : TveBoardItem; Info : TvePainter );
var
    PixelsPerCell : integer;
    ComponentX, ComponentY : integer;

    // move component to board position, in screen pixels
    procedure Convert( Point : TFloatPoint; var X, Y : integer );
    begin
        X := round(Point.X * PixelsPerCell ) + ComponentX;
        Y := round(Point.Y * PixelsPerCell) + ComponentY;
    end;
var
    Body : TFloatCircle;
    TopLead, BottomLead : TFloatRect;
    LeadCircle : TFloatCircle;
    LeadSquare : TFloatRect;
    RectLeads : boolean;

    X1, Y1 : integer;
    X2, Y2 : integer;
    X3, Y3 : integer;
    X4, Y4 : integer;
    Radius : integer;

    DesignatorX, DesignatorY : integer;
begin
    //locate TCanvas pixels containing top left of Item
    PixelsPerCell := Info.PixelsPerCell;
    ComponentX := Item.X * PixelsPerCell + (PixelsPerCell div 2);
    ComponentY := Item.Y * PixelsPerCell + (PixelsPerCell div 2);

    // calculate the rectangles and circles that make up a leaded outline
    CalculateRadialOutline(
        Point(Item.EndDeltaX, Item.EndDeltaY), Diameter, LeadSpacing,
        (Info.LeadStyle = lsHollow),
        Body,
        TopLead, BottomLead,
        LeadCircle,
        LeadSquare,
        RectLeads
    );

    // draw body circle
    Convert( Body.Centre, X1, Y1 );
    radius := Round( Body.Radius * PixelsPerCell);
    Info.BodyCircles.AddCircle( X1-radius, Y1-radius, X1+radius, Y1 +radius );

    // draw pin 1 lead square
    // ..calculate positions in screen pixels
    Convert( LeadSquare.Point1, X1, Y1 );
    Convert( LeadSquare.Point2, X2, Y2 );
    Convert( LeadSquare.Point3, X3, Y3 );
    Convert( LeadSquare.Point4, X4, Y4 );

    //..add lines for drawing
    Info.BodyLines.AddPoint(X1, Y1);
    Info.BodyLines.AddPoint(X2, Y2);
    Info.BodyLines.AddPoint(X3, Y3);
    Info.BodyLines.AddPoint(X4, Y4);
    Info.BodyLines.AddPoint(X1, Y1);
    Info.BodyLines.EndShape;

    // draw pin 2 lead circle
    Convert( LeadCircle.Centre, X1, Y1 );
    radius := round(LeadCircle.Radius * PixelsPerCell);
    Info.BodyCircles.AddCircle( X1-radius, Y1-radius, X1+radius, Y1+radius );

    // if leads/pins are drawn as thin "hollow" rectangles
    if RectLeads then begin

        Convert( TopLead.Point1, X1, Y1 );
        Convert( TopLead.Point2, X2, Y2 );
        Convert( TopLead.Point3, X3, Y3 );
        Convert( TopLead.Point4, X4, Y4 );

        Info.PinLines.AddLine( X1, Y1, X2, Y2 );
        Info.PinLines.AddLine( X2, Y2, X3, Y3 );
        Info.PinLines.AddLine( X3, Y3, X4, Y4 );
        Info.PinLines.AddLine( X4, Y4, X1, Y1 );

        Convert( BottomLead.Point1, X1, Y1 );
        Convert( BottomLead.Point2, X2, Y2 );
        Convert( BottomLead.Point3, X3, Y3 );
        Convert( BottomLead.Point4, X4, Y4 );

        Info.PinLines.AddLine( X1, Y1, X2, Y2 );
        Info.PinLines.AddLine( X2, Y2, X3, Y3 );
        Info.PinLines.AddLine( X3, Y3, X4, Y4 );
        Info.PinLines.AddLine( X4, Y4, X1, Y1 );
    end

    // else leads/pins are drawn as single lines
    else begin
        Convert( TopLead.Point1, X1, Y1 );
        Convert( TopLead.Point2, X2, Y2 );
        Info.PinLines.AddLine( X1, Y1, X2, Y2 );

        Convert( BottomLead.Point1, X1, Y1 );
        Convert( BottomLead.Point2, X2, Y2 );
        Info.PinLines.AddLine( X1, Y1, X2, Y2 );
    end;

    // print designator
    if not Item.TextVisible then begin
        exit;
    end;

    DesignatorX := (Item.TextX * PixelsPerCell) + ComponentX;
    DesignatorY := (Item.TextY * PixelsPerCell) + ComponentY;

    // text position is rotated along with the rest of the component
    // around the item (0.0) reference point
    Rotate( DesignatorX, DesignatorY,
            ComponentX, ComponentY,
            Item.Rotation   );

    // text orientation is never changed by item rotation
    case Info.TextDisplay of

        tdDesignator :
            Info.SmallText.Add(
                Item.Designator, DesignatorX, DesignatorY, Item.TextRotation );
        tdValue :
            Info.SmallText.Add(
                Item.Value, DesignatorX, DesignatorY, Item.TextRotation );
    end;
end;


function TveRadialOutline.OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
    : boolean;
var
    Leads : TFloatRect;
    Body : TFloatCircle;
    CellRect : TFloatRect;
begin
    // find rectangle and circle that describe the leads and body respectively
    // relative to Pin 1 at (0,0)
    CalculateRadialPerimeter(
        Point(Item.EndDeltaX, Item.EndDeltaY),
        Diameter, LeadSpacing, Body, Leads );

    // create a rectangle that describes the cell, relative to component origin
    CellRect.Point1.x := CellX - Item.X - 0.5;
    CellRect.Point1.y := CellY - Item.Y - 0.5;

    CellRect.Point2.x := CellX - Item.X + 0.5;
    CellRect.Point2.y := CellY - Item.Y - 0.5;

    CellRect.Point3.x := CellX - Item.X + 0.5;
    CellRect.Point3.y := CellY - Item.Y + 0.5;

    CellRect.Point4.x := CellX - Item.X - 0.5;
    CellRect.Point4.y := CellY - Item.Y + 0.5;


    // look for intersection between cell and body circle, and cell and
    // leads rectangle

    // look for intersection between these cell rectangles and outline drawing
    result :=
{
        CircleAlignedRectangleIntersect( CellRect.Point1, CellRect.Point3, Body ) or
        RectanglesIntersect( CellRect, Leads )
        ;
}
        CircleRectangleIntersect( CellRect, Body ) or
        RectanglesIntersect( CellRect, Leads )
        ;

end;


procedure TveRadialOutline.GetScreenRectR( Item : TveBoardItem; var R : TRect );
var
    Leads : TFloatRect;
    Body : TFloatCircle;
    Left, Right, Top, Bottom : single;
begin
    // find rectangle and circle that describe the leads and body respectively
    // relative to Pin 1 at (0,0)
    CalculateRadialPerimeter(
        Point(Item.EndDeltaX, Item.EndDeltaY),
        Diameter, LeadSpacing, Body, Leads );

    // find highest and lowest x and y values
    Left := Leads.Point1.x;
    Left := min( Left, Leads.Point2.x );
    Left := min( Left, Leads.Point3.x );
    Left := min( Left, Leads.Point4.x );
    Left := min( Left, Body.Centre.x - Body.Radius );

    Right := Leads.Point1.x;
    Right := max( Right, Leads.Point2.x );
    Right := max( Right, Leads.Point3.x );
    Right := max( Right, Leads.Point4.x );
    Right := max( Right, Body.Centre.x + Body.Radius );

    Top := Leads.Point1.y;
    Top := min( Top, Leads.Point2.y );
    Top := min( Top, Leads.Point3.y );
    Top := min( Top, Leads.Point4.y );
    Top := min( Top, Body.Centre.y - Body.Radius );

    Bottom := Leads.Point1.y;
    Bottom := max( Bottom, Leads.Point2.y );
    Bottom := max( Bottom, Leads.Point3.y );
    Bottom := max( Bottom, Leads.Point4.y );
    Bottom := Max( Bottom, Body.Centre.y + Body.Radius );

    // convert cells float to integer
    // .. add item offset
    // 0.5 to move to cell coords
    // +1 to make bounding rectangle
    R.Left := floor( Left + 0.5) + Item.X;
    R.Right := ceil( Right - 0.5) + Item.X +1;
    R.Top := floor( Top + 0.5) + Item.Y;
    R.Bottom := ceil( Bottom - 0.5) + Item.Y +1;
end;



procedure TveRadialOutline.SetDefaultLength( Item : TveBoardItem );
begin
    Item.Length := FLeadSpacing;
end;


// ** Outline writes its properties to a stream - override this virtual function
// ** in descendants **
procedure TveRadialOutline.WriteToStream( S : TStream );

    procedure LineOut( const text : string );
    begin
        LineToStream( S, text );
    end;

begin
    LineOut( Format( 'Outline=%s', [ClassName] ) );
    LineOut( Format('Name=%s', [Name]) );
    LineOut( Format('LeadSpacing=%d', [FLeadSpacing]) );
    LineOut( Format('Diameter=%d', [FDiameter]) );
    LineOut( Format('Pin0=%s', [Pins[0].Name]) );
    LineOut( Format('Pin1=%s', [Pins[1].Name]) );
    LineOut( 'end' );
end;

procedure TveRadialOutline.ReadFromStream( S : TStream );
var
    AName, AValue : string;
begin
{
Name=ELECTRO-MED
LeadSpacing=2
Diameter=5
end
}
    while NameValueFromStream( S, AName, AValue ) do begin
        if AName = 'Name' then begin
            FName := AValue;
        end
        else if AName = 'LeadSpacing' then begin
            FLeadSpacing := StrToIntDef( AValue, 1 );
        end
        else if AName = 'Diameter' then begin
            FDiameter := StrToIntDef( AValue, 2 );
        end
        else if AName = 'Pin0' then begin
            Pins[0].Name := AValue;
        end
        else if AName = 'Pin1' then begin
            Pins[1].Name := AValue;
        end
        else if AName = 'end' then begin
            exit;
        end;
    end;
end;



end.


