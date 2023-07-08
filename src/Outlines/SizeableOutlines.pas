unit SizeableOutlines;

interface

uses Outlines, Painter, Classes, Types;

// *********************************
//        TveSizeableOutline
// *********************************

(* This class is ancestor of all classes which can be stretched by mouse
during editing.  Descendants all have 2 leads and can adjust their length
property in response to mouse edits. Class not instantiated *)

type TveSizeableOutline = class( TveOutline )

  protected
    NextPinIndex : integer;

  public

    function PinIndexAt( Item : TveBoardItem; CellX, CellY : integer )
        : integer; override;

    procedure RotateAboutCenter( Item : TveBoardItem ); override;

    // pin discovery
    procedure ToFirstPin; override;
    function GetNextPin(
        Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean; override;

    constructor Create; override;
end;


// *********************************
//        TveLeadedOutline
// *********************************

(* This class is resistor - diode type class which can be stretched by mouse
during editing.  Has 2 leads and can adjust their length property in response
to mouse edits.  *)

type TveLeadedOutline = class( TveSizeableOutline )
    protected

    FBodyWidth : integer;
    FBodyLength : integer;
    FShowReference : boolean; 

    procedure SetBodyLength( Item : TveBoardItem; value : integer );
    procedure SetBodyWidth( Item : TveBoardItem; value : integer );

    public

    property BodyLength : integer read FBodyLength write FBodyLength;
    property BodyWidth : integer read FBodyWidth write FBodyWidth;
    property ShowReference : boolean read FShowReference write FShowReference;

    procedure Paint( Item : TveBoardItem;  Info : TvePainter ); override;

    function OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
        : boolean; override;
{
    function InsideRectangle( Item : TveBoardItem;
        CellX1, CellY1, CellX2, CellY2 : integer ) : boolean; override;
}
    procedure GetScreenRectR( Item : TveBoardItem; var R : TRect ); override;        

    constructor Create; override;
    function Clone : TveOutline; override;
    function Identical( Outline : TveOutline ) : boolean; override;
    procedure SetDefaultLength( Item : TveBoardItem ); override;   
    procedure WriteToStream( S : TStream ); override;
    procedure ReadFromStream( S : TStream ); override;

end;

// *********************************
//          TveLinkOutline
// *********************************

type TveLinkOutline = class( TveSizeableOutline )

    constructor Create; override;

    procedure Paint( Item : TveBoardItem;  Info : TvePainter ); override;
    function OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
        : boolean; override;
{
    function InsideRectangle( Item : TveBoardItem;
        CellX1, CellY1, CellX2, CellY2 : integer ) : boolean; override;
}        
    procedure GetScreenRectR( Item : TveBoardItem; var R : TRect ); override;        
end;


implementation

uses Rotations, SysUtils, Rectangles, Intersect, Math
{$IFNDEF VER200}, System.Contnrs {$ENDIF} ;


// ***********************************
//     BASIC ROTATION FORUMLA
// ***********************************
{ Used to move line ends around point of rotation
  Mostly we rotate around (0,0), which simplifies the forumula
rotate point (px, py) around point (ox, oy) by angle theta
p'x = cos(theta) * (px-ox) - sin(theta) * (py-oy) + ox
p'y = sin(theta) * (px-ox) + cos(theta) * (py-oy) + oy
}

// *********************************
//        TveSizeableOutline
// *********************************

constructor TveSizeableOutline.Create;
var
    Pin : TvePin;
begin
    inherited;
    Pin := TvePin.Create;
    Pin.Name := '1';
    FPins.Add( Pin );

    Pin := TvePin.Create;
    Pin.Name := '2';
    FPins.Add( Pin );
end;

// ******** ROTATE ITEM BY 90 DEGREES ABOUT IT"S CENTRE **********

procedure TveSizeableOutline.RotateAboutCenter;
var
    Angle : TRotation;
    HalfLength : integer;
begin
    // goal is to:
    // 1. Rotate component so that it does not wander off the board
    // after multiple 90 degree rotations.
    // 2. If component is vertical or horizontal, TWO rotations has effect of
    // flipping item end for end with no shift.

    // Half length is a useful offset
    HalfLength := Item.Length div 2;

    case Item.Rotation of
        rot0 : begin
            Item.X := Item.X - HalfLength;
            Item.Y := Item.Y + HalfLength;
        end;
        rot90 : begin
            Item.X := Item.X + HalfLength;
            Item.Y := Item.Y + Item.Length - HalfLength;
        end;
        rot180 : begin
            Item.X := Item.X + Item.Length - HalfLength;
            Item.Y := Item.Y - Item.Length + HalfLength;
        end;
        rot270 : begin
            Item.X := Item.X - Item.Length + HalfLength;
            Item.Y := Item.Y - HalfLength;
        end
    end;

    // calculate new rotation for Item
    Angle := Item.Rotation;
    Item.Rotation := TRotation( (Ord(Angle) + 1) mod 4 );
end;


function TveSizeableOutline.PinIndexAt( Item : TveBoardItem; CellX, CellY : integer )
    : integer;
begin
    // pin 1 is at (0,0) and index 0
    if (Item.X = CellX) and (Item.Y = CellY) then begin
        result := 0
    end
    // pin 2 is at other location and index 1
    else if (Item.X + Item.EndDeltaX = CellX) and (Item.Y + Item.EndDeltaY = CellY) then begin
        result := 1;
    end
    // else no pin at location
    else begin
        result := -1;
    end;
end;

// pin discovery
procedure TveSizeableOutline.ToFirstPin;
begin
    NextPinIndex := 0;
end;

function TveSizeableOutline.GetNextPin(
    Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean;
begin
    if NextPinIndex < 2 then begin

        // calculate pin position at outline reference point (PinIndex = 0)
        if NextPinIndex = 0 then begin
            X := Item.X;
            Y := Item.Y;
        end
        // else pin position
        else begin
            X := Item.X + Item.EndDeltaX;
            Y := Item.Y + Item.EndDeltaY;
        end;

        // return results
        result := True;
        PinIndex := NextPinIndex;

        // to next pin
        Inc( NextPinIndex );
    end
    else begin
        result := False;
    end;
end;
       


// *********************************
//        TveLeadedOutline
// *********************************

constructor TveLeadedOutline.Create;
begin
    inherited;
    FRotatable := True;
    FUserDefined := True;
    FShowsDesignator := True;
    FShowsValue := True;    
end;

function TveLeadedOutline.Clone : TveOutline;
begin
    result := TveLeadedOutline.Create;
    TveLeadedOutline(result).Name := Name;
    TveLeadedOutline(result).BodyLength := FBodyLength;
    TveLeadedOutline(result).BodyWidth := FBodyWidth;
    TveLeadedOutline(result).Pins[0].Name := Pins[0].Name;
    TveLeadedOutline(result).Pins[1].Name := Pins[1].Name;
    TveLeadedOutline(result).FShowReference := FShowReference;
end;


function TveLeadedOutline.Identical( Outline : TveOutline ) : boolean;
begin
    result :=
    (Outline is TveLeadedOutline) and
    (TveLeadedOutline(Outline).BodyLength = FBodyLength) and
    (TveLeadedOutline(Outline).BodyWidth = FBodyWidth) and
    (TveLeadedOutline(Outline).Pins[0].Name = Pins[0].Name) and
    (TveLeadedOutline(Outline).Pins[1].Name = Pins[1].Name) and
    (TveLeadedOutline(Outline).FShowReference = FShowReference)
end;


procedure TveLeadedOutline.SetBodyLength( Item : TveBoardItem; value : integer );
begin
    if value < 1 then begin
        value := 1;
    end;
    FBodyLength := Value;
end;


procedure TveLeadedOutline.SetBodyWidth( Item : TveBoardItem; value : integer );
begin
    if value < 1 then begin
        value := 1;
    end;
    FBodyWidth := Value;
end;

// Calculate the perimeter of a leaded outline - by describing two
// rectangles,
procedure CalculateLeadedPerimeter(
    Pin2Delta : TPoint; BodyHeight, BodyWidth : integer;
    var Leads, Body : TFloatRect );
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

var
    BodyTop, BodyBottom : single;
    UseBodyHeight : single;
    HalfBodyWidth : single;

begin
    // theta is the angle of rotation. Zero rotation occurs when the part is
    // drawn with pin 2 directly below pin 1 : ie EndDeltaX = 0
    Hypotenuse :=  sqrt((Pin2Delta.X * Pin2Delta.X) + (Pin2Delta.Y * Pin2Delta.Y));
    SinTheta := Pin2Delta.X / Hypotenuse;
    CosTheta := Pin2Delta.Y / Hypotenuse;

    // body height of 0 is a special case : half height is drawn
    if BodyHeight = 0 then begin
        UseBodyHeight := 0.5;
    end
    else begin
        UseBodyHeight := BodyHeight;
    end;

    // body lies half way between top and bottom pins
    // 0.1 shrinks down slightly away from cell border
    BodyTop := (( Hypotenuse - UseBodyHeight ) * 0.5) + 0.1;;
    BodyBottom := BodyTop + UseBodyHeight - 0.1;

    // Will calculate lead as thin rectangle, hole to hole length, 1/8 cell width
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

    // calculate body rectangle which lies half way along leads
    // .. top left
    // ... less 0.1 of a cell to keep inside cell boundaries
    HalfBodyWidth := (BodyWidth * 0.5) - 0.1;

    Body.Point1.X := -HalfBodyWidth;
    Body.Point1.Y := BodyTop;
    // .. top right
    Body.Point2.X := HalfBodyWidth;
    Body.Point2.Y := BodyTop;
    // .. bottom right
    Body.Point3.X := HalfBodyWidth;
    Body.Point3.Y := BodyBottom;
    // .. bottom left
    Body.Point4.X := -HalfBodyWidth;
    Body.Point4.Y := BodyBottom;

    // rotate rectangle points to final position
    Rotate( Leads.Point1 );
    Rotate( Leads.Point2 );
    Rotate( Leads.Point3 );
    Rotate( Leads.Point4 );

    Rotate( Body.Point1 );
    Rotate( Body.Point2 );
    Rotate( Body.Point3 );
    Rotate( Body.Point4 );
end;


// Calculate the three shapes that make up a leaded outline.
// Pin 1 of the ooutline is at 0,0, Pin 2 is at Pin2Delta
// All parameters are in cell units. To convert to screen coords, multiply
// returned coords by PixelsPerCell and add Item.X * PixelsPerCell etc
// If WideLead=True, TopLead, BottomLead each contain a single line between
// TopLead.Point1 and TopLead.Point2, BottomLead.Point1 and BottomLead.Point2.
// Bar1, Bar2 contain start, end of line that shows component pin 1 end.

procedure CalculateLeadedShapes(
    Pin2Delta : TPoint; BodyHeight, BodyWidth : integer; WideLead : boolean;
    var TopLead, Body, BottomLead : TFloatRect; var Bar1, Bar2 : TFloatPoint );
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
    Undersize = 0.125;

var
    BodyTop, BodyBottom : single;
    UseBodyHeight : single;
    HalfBodyWidth : single;

begin
    // theta is the angle of rotation. Zero rotation occurs when the part is
    // drawn with pin 2 directly below pin 1 : ie EndDeltaX = 0
    Hypotenuse :=  sqrt((Pin2Delta.X * Pin2Delta.X) + (Pin2Delta.Y * Pin2Delta.Y));
    SinTheta := Pin2Delta.X / Hypotenuse;
    CosTheta := Pin2Delta.Y / Hypotenuse;

    // body height of 0 is a special case : half height is drawn
    if BodyHeight = 0 then begin
        UseBodyHeight := 0.5;
    end
    else begin
        // squeeze body 1/8 shorter each end, so bodies do not end exactly
        // over a pin. This means we see at least a very short pin.
        UseBodyHeight := BodyHeight - 0.25;
    end;

    // body lies half way between top and bottom pins
    BodyTop := ( Hypotenuse - UseBodyHeight ) * 0.5;
    BodyBottom := BodyTop + UseBodyHeight;

    // calculate wide leads as rectangles
    if WideLead then begin

        // Will draw top lead as thin rectangle, hole to hole length, 1/8 cell width
        // .. left & right
        TopLead.Point1.X := -HalfWidth;
        TopLead.Point2.X := HalfWidth;
        // top coord: goes above hole if leads extend past body
        if Hypotenuse >= BodyHeight then begin
            TopLead.Point1.Y := -HeightExtra;
            TopLead.Point2.Y := -HeightExtra;
        end
        // leads inside body, so leads go below hole
        else begin
            TopLead.Point1.Y := HeightExtra;
            TopLead.Point2.Y := HeightExtra;
        end;

        // .. lower right
        TopLead.Point3.X :=  HalfWidth;
        TopLead.Point3.Y := BodyTop;
        // .. lower left
        TopLead.Point4.X := -HalfWidth;
        TopLead.Point4.Y := BodyTop;

        // rotate rectangle points to final position
        Rotate( TopLead.Point1 );
        Rotate( TopLead.Point2 );
        Rotate( TopLead.Point3 );
        Rotate( TopLead.Point4 );

        // Will draw bottom lead as thin rectangle, hole to hole length, 1/8 cell width
        // ..find coords of rectangle, unrotated, relative to centre of pin 2 cell
        // .. top left
        BottomLead.Point1.X := -HalfWidth;
        BottomLead.Point1.Y := BodyBottom;
        // .. top right
        BottomLead.Point2.X := HalfWidth;
        BottomLead.Point2.Y := BodyBottom;

        // ..bottom coord: goes below hole if leads extend past body
        if Hypotenuse >= BodyHeight then begin
            BottomLead.Point3.Y := Hypotenuse + HeightExtra;
            BottomLead.Point4.Y := Hypotenuse + HeightExtra;
        end
        // leads inside body, so leads go below hole
        else begin
            BottomLead.Point3.Y := Hypotenuse - HeightExtra;
            BottomLead.Point4.Y := Hypotenuse - HeightExtra;
        end;
        //.. left and right
        BottomLead.Point3.X :=  HalfWidth;
        BottomLead.Point4.X := -HalfWidth;

        // rotate rectangle points to final position
        Rotate( BottomLead.Point1 );
        Rotate( BottomLead.Point2 );
        Rotate( BottomLead.Point3 );
        Rotate( BottomLead.Point4 );
    end

    // calculate narrow leads as lines
    else begin
        TopLead.Point1.X := 0;
        TopLead.Point1.Y := 0;
        // .. top right
        TopLead.Point2.X := 0;
        TopLead.Point2.Y := BodyTop;

        // rotate line to final position
        Rotate( TopLead.Point1 );
        Rotate( TopLead.Point2 );

        // .. top left
        BottomLead.Point1.X := 0;
        BottomLead.Point1.Y := BodyBottom;
        // .. top right
        BottomLead.Point2.X := 0;
        BottomLead.Point2.Y := Hypotenuse;

        // rotate line to final position
        Rotate( BottomLead.Point1 );
        Rotate( BottomLead.Point2 );
    end;

    // calculate body rectangle which lies half way along leads
    // .. top left
    // less 0.1 to keep inside line boundaries
    HalfBodyWidth := (BodyWidth * 0.5) - Undersize;

//    HalfBodyWidth := BodyWidth * 0.5;

    Body.Point1.X := -HalfBodyWidth;
    Body.Point1.Y := BodyTop;
    // .. top right
    Body.Point2.X := HalfBodyWidth;
    Body.Point2.Y := BodyTop;
    // .. bottom right
    Body.Point3.X := HalfBodyWidth;
    Body.Point3.Y := BodyBottom;
    // .. bottom left
    Body.Point4.X := -HalfBodyWidth;
    Body.Point4.Y := BodyBottom;

    Rotate( Body.Point1 );
    Rotate( Body.Point2 );
    Rotate( Body.Point3 );
    Rotate( Body.Point4 );

    // calculate bar line
    Bar1.X := -HalfBodyWidth;
    Bar1.Y := BodyTop + 0.25;
    Bar2.X := HalfBodyWidth;
    Bar2.Y := BodyTop + 0.25;

    Rotate( Bar1 );
    Rotate( Bar2 );
end;


procedure TveLeadedOutline.Paint( Item : TveBoardItem; Info : TvePainter );
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
    TopLead, Body, BottomLead : TFloatRect;
    Bar1, Bar2 : TFloatPoint;
    X1, Y1 : integer;
    X2, Y2 : integer;
    X3, Y3 : integer;
    X4, Y4 : integer;

    DesignatorX, DesignatorY : integer;
begin
    //locate TCanvas pixels containing top left of Item
    PixelsPerCell := Info.PixelsPerCell;
    ComponentX := Item.X * PixelsPerCell + (PixelsPerCell div 2);
    ComponentY := Item.Y * PixelsPerCell + (PixelsPerCell div 2);

    // calculate the 4 rectangles that make up a leaded outline
    CalculateLeadedShapes(
        Point(Item.EndDeltaX, Item.EndDeltaY), BodyLength, BodyWidth,
        Info.LeadStyle = lsHollow, TopLead, Body, BottomLead, Bar1, Bar2 );

    if Info.LeadStyle = lsHollow then begin

        // convert to pixels and offset
        Convert( TopLead.Point1, X1, Y1 );
        Convert( TopLead.Point2, X2, Y2 );
        Convert( TopLead.Point3, X3, Y3 );
        Convert( TopLead.Point4, X4, Y4 );

        // draw lines on screen
        Info.PinLines.AddPoint(X1, Y1);
        Info.PinLines.AddPoint(X2, Y2);
        Info.PinLines.AddPoint(X3, Y3);
        Info.PinLines.AddPoint(X4, Y4);
        Info.PinLines.AddPoint(X1, Y1);
        Info.PinLines.EndShape;

        Convert( BottomLead.Point1, X1, Y1 );
        Convert( BottomLead.Point2, X2, Y2 );
        Convert( BottomLead.Point3, X3, Y3 );
        Convert( BottomLead.Point4, X4, Y4 );

        Info.PinLines.AddPoint(X1, Y1);
        Info.PinLines.AddPoint(X2, Y2);
        Info.PinLines.AddPoint(X3, Y3);
        Info.PinLines.AddPoint(X4, Y4);
        Info.PinLines.AddPoint(X1, Y1);
        Info.PinLines.EndShape;
    end
    else begin
        Convert( TopLead.Point1, X1, Y1 );
        Convert( TopLead.Point2, X2, Y2 );
        Info.PinLines.AddLine( X1, Y1, X2, Y2 );

        Convert( BottomLead.Point1, X1, Y1 );
        Convert( BottomLead.Point2, X2, Y2 );
        Info.PinLines.AddLine( X1, Y1, X2, Y2 );
    end;

    // body as rectangle
    Convert( Body.Point1, X1, Y1 );
    Convert( Body.Point2, X2, Y2 );
    Convert( Body.Point3, X3, Y3 );
    Convert( Body.Point4, X4, Y4 );

    // draw lines on screen
    Info.BodyLines.AddPoint( X1, Y1 );
    Info.BodyLines.AddPoint( X2, Y2 );
    Info.BodyLines.AddPoint( X3, Y3 );
    Info.BodyLines.AddPoint( X4, Y4 );
    Info.BodyLines.AddPoint( X1, Y1 );
    Info.BodyLines.EndShape;

    // if polarity line required
    if ShowReference then begin
        Convert( Bar1, X1, Y1 );
        Convert( Bar2, X2, Y2 );
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


function TveLeadedOutline.OccupiesCell(  Item : TveBoardItem;
    CellX, CellY : integer ) : boolean;
var
    CellRect : TFloatRect;
    Leads : TFloatRect;
    Body : TFloatRect;
begin
    // Calculate the perimeter of a leaded outline - by describing two
    // rectangles,
    CalculateLeadedPerimeter(
        Point(Item.EndDeltaX, Item.EndDeltaY), FBodyLength, FBodyWidth,
        Leads, Body
    );

    // create a rectangle that describes the cell, relative to component origin
    CellRect.Point1.x := CellX - Item.X - 0.5;
    CellRect.Point1.y := CellY - Item.Y - 0.5;

    CellRect.Point2.x := CellX - Item.X + 0.5;
    CellRect.Point2.y := CellY - Item.Y - 0.5;

    CellRect.Point3.x := CellX - Item.X + 0.5;
    CellRect.Point3.y := CellY - Item.Y + 0.5;

    CellRect.Point4.x := CellX - Item.X - 0.5;
    CellRect.Point4.y := CellY - Item.Y + 0.5;

    // look for intersection between the cell rectangle and outline drawing
    result :=
        RectanglesIntersect( CellRect, Leads ) or
        RectanglesIntersect( CellRect, Body );
end;


procedure TveLeadedOutline.GetScreenRectR( Item : TveBoardItem; var R : TRect );
var
    Leads : TFloatRect;
    Body : TFloatRect;
    Left, Right, Top, Bottom : single;
begin

    // Calculate the perimeter of a leaded outline - by describing two
    // rectangles. Coords are returned in cell units, floating point.
    CalculateLeadedPerimeter(
        Point(Item.EndDeltaX, Item.EndDeltaY), FBodyLength, FBodyWidth,
        Leads, Body
    );

    // find highest and lowest x and y values
    Left := Leads.Point1.x;
    Left := min( Left, Leads.Point2.x );
    Left := min( Left, Leads.Point3.x );
    Left := min( Left, Leads.Point4.x );

    Left := min( Left, Body.Point1.x );
    Left := min( Left, Body.Point2.x );
    Left := min( Left, Body.Point3.x );
    Left := min( Left, Body.Point4.x );

    Right := Leads.Point1.x;
    Right := max( Right, Leads.Point2.x );
    Right := max( Right, Leads.Point3.x );
    Right := max( Right, Leads.Point4.x );

    Right := max( Right, Body.Point1.x );
    Right := max( Right, Body.Point2.x );
    Right := max( Right, Body.Point3.x );
    Right := max( Right, Body.Point4.x );

    Top := Leads.Point1.y;
    Top := min( Top, Leads.Point2.y );
    Top := min( Top, Leads.Point3.y );
    Top := min( Top, Leads.Point4.y );

    Top := min( Top, Body.Point1.y );
    Top := min( Top, Body.Point2.y );
    Top := min( Top, Body.Point3.y );
    Top := min( Top, Body.Point4.y );

    Bottom := Leads.Point1.y;
    Bottom := max( Bottom, Leads.Point2.y );
    Bottom := max( Bottom, Leads.Point3.y );
    Bottom := max( Bottom, Leads.Point4.y );

    Bottom := max( Bottom, Body.Point1.y );
    Bottom := max( Bottom, Body.Point2.y );
    Bottom := max( Bottom, Body.Point3.y );
    Bottom := max( Bottom, Body.Point4.y );

    // convert cells float to integer
    // .. add item offset
    // 0.5 to move to cell coords
    // +1 to make bounding rectangle
    R.Left := floor( Left + 0.5) + Item.X;
    R.Right := floor( Right + 0.5) + Item.X +1;
    R.Top := floor( Top + 0.5) + Item.Y;
    R.Bottom := floor( Bottom + 0.5) + Item.Y +1;
end;

procedure TveLeadedOutline.SetDefaultLength( Item : TveBoardItem );
begin
    Item.Length := FBodyLength + 2;
end;


// ** Outline writes its properties to a stream - override this virtual function
// ** in descendants **
procedure TveLeadedOutline.WriteToStream( S : TStream );

    procedure LineOut( const text : string );
    begin
        LineToStream( S, text );
    end;

    const BooleanToStr : array[boolean] of string = ('0', '1');    
begin
    LineOut( Format( 'Outline=%s', [ClassName] ) );
    LineOut( Format('Name=%s', [Name]) );
    LineOut( Format('BodyWidth=%d', [BodyWidth]) );
    LineOut( Format('BodyLength=%d', [BodyLength]) );
    LineOut( Format('Pin0=%s', [Pins[0].Name]) );
    LineOut( Format('Pin1=%s', [Pins[1].Name]) );
    LineOut( Format('Reference=%s', [BooleanToStr[FShowReference]]) );

    LineOut( 'end' );
end;

procedure TveLeadedOutline.ReadFromStream( S : TStream );
var
    AName, AValue : string;
begin
{
Name=AXIAL_14x29MM
BodyWidth=5
BodyLength=12
end
}
    while NameValueFromStream( S, AName, AValue ) do begin
        if AName = 'Name' then begin
            FName := AValue;
        end
        else if AName = 'BodyWidth' then begin
            FBodyWidth := StrToIntDef( AValue, 1 );
        end
        else if AName = 'BodyLength' then begin
            FBodyLength := StrToIntDef( AValue, 2 );
        end
        else if AName = 'Pin0' then begin
            Pins[0].Name := AValue;
        end
        else if AName = 'Pin1' then begin
            Pins[1].Name := AValue;
        end
        else if AName = 'Reference' then begin
            FShowReference := AValue <> '0';
        end
        else if AName = 'end' then begin
            exit;
        end;
    end;
end;


// *********************************
//          TveLinkOutline
// *********************************

constructor TveLinkOutline.Create;
begin
    inherited;
    FRotatable := True;
    FName := 'Link';
end;

// Calculate the 4 points of the rectangle that draws a link
// Pin 1 of the link is at 0,0, Pin 2 is at Pin2Delta
// All parameters are in cell units. To convert to screen coords, multiply
// returned coords by PixelsPerCell and add Item.X * PixelsPerCell etc

procedure CalculateLinkRect(
    Pin2Delta : TPoint; var Point1, Point2, Point3, Point4 : TFloatPoint );

var
    Hypotenuse : single;
    SinTheta : single;
    CosTheta : single;

    // rotate coord pair about (0,0), by angle Theta
    procedure RotateF( var X1, Y1 : single );
    var
        XTemp, YTemp : single;
    begin
        XTemp := X1;
        YTemp := Y1;
        // X negated to match negated Y coord system used by VeeCAD & Windows
        X1 := -(XTemp*CosTheta - YTemp*SinTheta);
        Y1 := XTemp*SinTheta + YTemp*CosTheta;
    end;

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

    // Will draw link as thin rectangle, hole to hole length, 1/8 cell width
    // ..find coords of rectangle, unrotated, relative to centre of pin 1 cell
    // .. top left
    Point1.X := -HalfWidth;
    Point1.Y := -HeightExtra;
    // .. top right
    Point2.X := HalfWidth;
    Point2.Y := -HeightExtra;
    // .. bottom right
    Point3.X :=  HalfWidth;
    Point3.Y := Hypotenuse + HeightExtra;
    // .. bottom left
    Point4.X := -HalfWidth;
    Point4.Y := Point3.Y;

    // rotate all 4 points to final position
    Rotate( Point1 );
    Rotate( Point2 );
    Rotate( Point3 );
    Rotate( Point4 );
end;


procedure TveLinkOutline.Paint( Item : TveBoardItem; Info : TvePainter );
var
    PixelsPerCell : integer;
    ComponentX, ComponentY : integer;

    // move component to board position, in screen pixels
    procedure Convert( Point : TFloatPoint; var X, Y : integer );
    begin
//        X := trunc(Point.X * PixelsPerCell ) + ComponentX;
//        Y := trunc(Point.Y * PixelsPerCell) + ComponentY;
        X := round(Point.X * PixelsPerCell ) + ComponentX;
        Y := round(Point.Y * PixelsPerCell) + ComponentY;
    end;

var
    Point1, Point2, Point3, Point4 : TFloatPoint;
    X1, Y1 : integer;
    X2, Y2 : integer;
    X3, Y3 : integer;
    X4, Y4 : integer;

begin
    //locate TCanvas pixels containing top left of Item
    PixelsPerCell := Info.PixelsPerCell;
    ComponentX := Item.X * PixelsPerCell + (PixelsPerCell div 2);
    ComponentY := Item.Y * PixelsPerCell + (PixelsPerCell div 2);

    if Info.LeadStyle = lsLine then begin
        Info.PinLines.AddLine( ComponentX, ComponentY,
        ComponentX + (Item.EndDeltaX * PixelsPerCell),
        ComponentY + (Item.EndDeltaY * PixelsPerCell)
         );
         exit;
    end;


    // get position of 4 points we draw between to display a link, in cell units,
    // relative to Pin 1 at (0,0)
    CalculateLinkRect( Point(Item.EndDeltaX, Item.EndDeltaY), Point1, Point2, Point3, Point4 );

    // convert to pixels and offset
    Convert( Point1, X1, Y1 );
    Convert( Point2, X2, Y2 );
    Convert( Point3, X3, Y3 );
    Convert( Point4, X4, Y4 );

    // draw skinny rectangle
    Info.PinLines.AddPoint(X1, Y1);
    Info.PinLines.AddPoint(X2, Y2);
    Info.PinLines.AddPoint(X3, Y3);
    Info.PinLines.AddPoint(X4, Y4);
    Info.PinLines.AddPoint(X1, Y1);
    Info.PinLines.EndShape;

end;


function TveLinkOutline.OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
    : boolean;
var
    LinkRect : TFloatRect;
    CellRect : TFloatRect;
begin
    // get position of 4 points we draw between to display a link, in cell units,
    // relative to Pin 1 at (0,0)
    CalculateLinkRect(
        Point(Item.EndDeltaX, Item.EndDeltaY),
        LinkRect.Point1, LinkRect.Point2, LinkRect.Point3, LinkRect.Point4
    );

    // create a rectangle that describes the cell, relative to component origin
    CellRect.Point1.x := CellX - Item.X - 0.5;
    CellRect.Point1.y := CellY - Item.Y - 0.5;

    CellRect.Point2.x := CellX - Item.X + 0.5;
    CellRect.Point2.y := CellY - Item.Y - 0.5;

    CellRect.Point3.x := CellX - Item.X + 0.5;
    CellRect.Point3.y := CellY - Item.Y + 0.5;

    CellRect.Point4.x := CellX - Item.X - 0.5;
    CellRect.Point4.y := CellY - Item.Y + 0.5;

    // look for intersection between these cell rectangles and outline drawing
    result := RectanglesIntersect( CellRect, LinkRect );
end;


procedure TveLinkOutline.GetScreenRectR( Item : TveBoardItem; var R : TRect );
begin
    // create rectangle which includes all cells in this outline
    // this is not a bounding rectangle
    R.Left := Item.X;
    R.Top := Item.Y;
    R.Right := R.Left + Item.EndDeltaX;
    R.Bottom := R.Top + Item.EndDeltaY;

    // arrange rotated coords to give left,top and right,bottom of rectangle.
    NormalizeRect( R );

    // turn into bounding rectangle
    Inc( R.Right );
    Inc( R.Bottom );
end;


end.







