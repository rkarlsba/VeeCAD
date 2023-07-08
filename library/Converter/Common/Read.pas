unit Read;

interface

uses Rotations;

type TFloatPoint = record
    x : single;
    y : single;
end;

type TPin = record
    Name : string;
    Number : string;
    // location of
    Position : TFloatPoint;
    Rotation : TRotation;
    Part : integer;
    Length : single;
end;

type TPolygon = class
  protected
    FPoints : array of TFloatPoint;
    FPointCount : integer;
    function GetPoint(Index : integer) : TFloatPoint;
  public
    Position : TFloatPoint;
    property Points[Index : integer] : TFloatPoint read GetPoint;
    Property PointCount : integer read FPointCount;
    procedure Clear;
    procedure AddPoint( Point : TFloatPoint );
end;

type TCircle = record
    Centre : TFloatPoint;
    Radius : single;
end;

type TRectangle = record
    TopLeft : TFloatPoint;
    BottomRight : TFloatPoint;
end;

type TArc = record
   Centre : TFloatPoint;
   Radius : single;
   StartAngleDegrees : single;
   EndAngleDegrees : single;
end;


type TSymbolLibraryReader = class

  protected

    FName : string;
    FReference : string;
    FDescription : string;
    FPartsPerPackage : integer;
    FPackage : string;

    function GetEOF : boolean; virtual; abstract;
    function GetPin( Index : integer ) : TPin; virtual; abstract;
    function GetPolygon( Index : integer ) : TPolygon; virtual; abstract;
    function GetCircle( Index : integer ) : TCircle; virtual; abstract;
    function GetRectangle( Index : integer ) : TRectangle; virtual; abstract;
    function GetArc( Index : integer ) : TArc; virtual; abstract;

    function GetPinCount : integer; virtual; abstract;
    function GetPolygonCount : integer; virtual; abstract;
    function GetCircleCount : integer; virtual; abstract;
    function GetRectangleCount : integer; virtual; abstract;
    function GetArcCount : integer; virtual; abstract;

  public
    procedure Next; virtual; abstract;
    property EOF : boolean read GetEOF;

    property Pins[ Index : integer ] : TPin read GetPin;
    property PinCount : integer read GetPinCount;

    property Polygons[ Index : integer ] : TPolygon read GetPolygon;
    property PolygonCount : integer read GetPolygonCount;

    property Circles[ Index : integer ] : TCircle read GetCircle;
    property CircleCount : integer read GetCircleCount;

    property Rectangles[ Index : integer ] : TRectangle read GetRectangle;
    property RectangleCount : integer read GetRectangleCount;

    property Arcs[ Index : integer ] : TArc read GetArc;
    property ArcCount : integer read GetArcCount;

    {
    property Text
    property TextCount
}

    property Name : string read FName;
    property Reference : string read FReference;
    property Description : string read FDescription;
    property PartsPerPackage : integer read FPartsPerPackage;
    property Package : string read FPackage;


    constructor Create( const FileName : string ); virtual; abstract;
    destructor Destroy; override; abstract;
end;


implementation

// **************************************************
//                  TPOLYGON CLASS
// **************************************************

function TPolygon.GetPoint(Index : integer) : TFloatPoint;
begin
    result := FPoints[Index];
end;

procedure TPolygon.Clear;
begin
    FPointCount := 0;
end;

procedure TPolygon.AddPoint( Point : TFloatPoint );
begin
    if FPointCount >= Length(FPoints) then begin
        SetLength( FPoints, FPointCount + 20 );
    end;
    FPoints[FPointCount] := Point;
    Inc( FPointCount );
end;

end.
