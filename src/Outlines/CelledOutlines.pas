unit CelledOutlines;

interface

uses Outlines, Painter, Classes, Types;

type
    TCellType = ( ctFree, ctBody, ctPin );
    TLocation = record
        X: integer;
        Y: integer;
end;

const TveCellOutline_MaxHeight = 40;
const TveCellOutline_MaxWidth = 20;


// ***************************************
//              TveCellOutline
// ***************************************

// These Outlines assign each cell to body, free or pin.

type TveCellOutline = class( TveOutline )

    FMaxWidth : integer;
    FMaxHeight : integer;

    FWidth : integer;
    FHeight : integer;
    FCells : array[0..TveCellOutline_MaxWidth -1,0..TveCellOutline_MaxHeight -1]
        of byte;

    // find next pin vars
    NextPinX : integer;
    NextPinY : integer;
    NextPinIndex : integer;

    PinListValid : boolean;

    function GetWidth : integer;
    function GetHeight : integer;

    function GetCellType( x, y : integer ) : TCellType;
    procedure SetCellType( x, y : integer; value : TCellType );

    function GetCellPinName( x, y : integer ) : string;
    procedure SetCellPinName( x, y : integer; value : string );
    function PinForCell( x, y : integer ) : TvePin;    

    property Width : integer read GetWidth;
    property Height : integer read GetHeight;

    function GetPin( index : integer ) : TvePin; override;

  public

    property MaxWidth : integer read FMaxWidth;
    property MaxHeight : integer read FMaxHeight;

    property CellTypes[x, y : integer] : TCellType
        read GetCellType write SetCellType;

    property CellPinNames[x, y : integer] : string
        read GetCellPinName write SetCellPinName;

    constructor Create; override;
    function Clone : TveOutline; override;
    function Identical( Outline : TveOutline ) : boolean; override;

    procedure Paint( Item : TveBoardItem; Info : TvePainter ); override;
    function OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
        : boolean; override;
       
    procedure RotateAboutCenter( Item : TveBoardItem ); override;
    function PinIndexAt( Item : TveBoardItem; CellX, CellY : integer )
        : integer; override;
    procedure GetScreenRectR( Item : TveBoardItem; var R : TRect ); override;

    // pin exists
    procedure ToFirstPin; override;
    function GetNextPin(
        Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean; override;

    procedure WriteToStream( S : TStream ); override;
    procedure ReadFromStream( S : TStream ); override;           
end;

implementation

uses SysUtils, Rotations, ParseCSV, Rectangles
{$IFNDEF VER200}, System.Contnrs {$ENDIF} ;

// values we store in FCells[]
// TCellType = ( ctFree, ctBody, ctPin );
//    0 to 253 : the index into Pins[] for that
//    254 : body
//    255 : empty
const
    FREE_CELL = 255;
    BODY_CELL = 254;
    MAX_PIN_INDEX = 253;

type ECell = class( Exception );

constructor TveCellOutline.Create;
begin
    inherited;
    FMaxWidth := TveCellOutline_MaxWidth;
    FMaxHeight := TveCellOutline_MaxHeight;
    FRotatable := True;
    FUserDefined := True;
    FShowsDesignator := True;
    FShowsValue := True;
    // mark all cells as empty
    FillChar( FCells, sizeof(FCells), FREE_CELL );
end;


function TveCellOutline.Clone : TveOutline;
var
  i: Integer;
  Pin : TvePin;
begin
    result := TveCellOutline.Create;
    TveCellOutline(result).Name := Name;

    // duplicate the cells array
    Move( FCells, TveCellOutline(result).FCells, sizeof(FCells) );

    // duplicate the pins array
    for i := 0 to PinCount - 1 do begin
        Pin := TvePin.Create;
        TveCellOutline(result).FPins.Add( Pin );
        Pin.Name := Pins[i].Name;
    end;
    TveCellOutline(result).FWidth := Width;
    TveCellOutline(result).FHeight := Height;
end;

function TveCellOutline.Identical( Outline : TveOutline ) : boolean;
var
    sx, sy : integer;
  i: Integer;
begin
    // assume outlines not equal
    result := False;

    if  not (
        (Outline is TveCellOutline) and
        (TveCellOutline(Outline).Width = Width) and
        (TveCellOutline(Outline).Height = Height) and
        (TveCellOutline(Outline).PinCount = PinCount)
        ) then begin
        exit;
    end;

    // compare the pins arrays
    for i := 0 to PinCount - 1 do begin
        if TveCellOutline(Outline).Pins[i].Name <> Pins[i].Name then begin
            exit;
        end;
    end;

    // compare the cells arrays
    for sx := 0 to TveCellOutline_MaxWidth - 1 do begin
        for sy := 0 to TveCellOutline_MaxHeight - 1 do begin
            if CellTypes[sx,sy] <> TveCellOutline(Outline).CellTypes[sx,sy]
                then begin
                exit;
            end;
        end;
    end;

    // passed all tests
    result := True;
end;

function TveCellOutline.GetWidth : integer;
var
    sx, sy : integer;
    maxX : integer;
begin
    if FWidth < 0 then begin
        // search every row for highest x index of non-free cell
        maxX := 0;
        for sy := 0 to TveCellOutline_MaxHeight - 1 do begin
            for sx := 0 to TveCellOutline_MaxWidth - 1 do begin
                if (CellTypes[sx,sy] <> ctFree) and (maxX < sx) then begin
                    maxX := sx;
                end;
            end;
        end;
        // width is 1 higher than 0-based highest occupied cell index
        FWidth := maxX + 1;
    end;
    result := FWidth;
end;

function TveCellOutline.GetHeight : integer;
var
    sx, sy : integer;
    maxY : integer;
begin
    if FHeight < 0 then begin
        // search every column for highest x index of non-free cell
        maxY := 0;
        for sx := 0 to TveCellOutline_MaxWidth - 1 do begin
            for sy := 0 to TveCellOutline_MaxHeight - 1 do begin
                if (CellTypes[sx,sy] <> ctFree) and (maxY < sy) then begin
                    maxY := sy;
                end;
            end;
        end;
        // height is 1 higher than 0-based highest occupied cell index
        FHeight := maxY + 1;
    end;
    result := FHeight;
end;

function TveCellOutline.GetCellType( x, y : integer ) : TCellType;

begin
    // don't raise exception if coords are out of bounds, because this
    // function can be called to explore locations far outside component
    if(x >= TveCellOutline_MaxWidth) or (y >= TveCellOutline_MaxHeight) or
    (y < 0) or (x < 0) then begin
        result := ctFree;
    end
    else begin
        case FCells[x,y] of
            BODY_CELL : result := ctBody;
            FREE_CELL : result := ctFree;
            else begin
                result := ctPin;
            end
        end;
    end;
end;


procedure TveCellOutline.SetCellType( x, y : integer; value : TCellType );

    // decrement pins which have an index above *index*
    // This proc called when an element is removed from FPins[] and all the
    // elements above "slide down by 1", ie. decrement indexes
    procedure AdjustPinIndexesAbove( index : integer );
    var
        x, y : integer;
        value : byte;
    begin
        for x := 0 to TveCellOutline_MaxWidth - 1 do begin
            for y := 0 to TveCellOutline_MaxHeight - 1 do begin
                value := FCells[x,y];
                if (value < MAX_PIN_INDEX) and (value > index) then begin
                    dec( FCells[x,y] );
                end
            end
        end
    end;

var
    Cell : byte;
    Pin : TvePin;
begin
    // get existing cell
    Cell := FCells[ x, y ];

    // if existing cell is body or free : no Pins[] entry to worry about
    if Cell > MAX_PIN_INDEX then begin

        // we are placing a pin
        if value = ctPin then begin
            Pin := TvePin.Create;
            FPins.Add( Pin );
            // store index of our pin
            FCells[x, y] :=  FPins.Count -1;
        end
        // we are placing a body
        else if value = ctBody then begin
            FCells[x, y] := BODY_CELL;
        end
        // else we are placing a free
        else begin
            FCells[x, y] :=  FREE_CELL;
        end;
    end
          
    // existing cell holds a pin
    else begin

        // we are placing a pin
        if value = ctPin then begin
            // already have a pin - nothing to do
        end

        else begin
            // remove pin
            Pin := PinForCell( x, y );
            if Pin = nil then begin
                raise ECell.Create( 'Cell reference has no Pins[] entry' );
            end;

            FPins.Remove(Pin);
            AdjustPinIndexesAbove( Cell );

            // we are placing a body
            if value = ctBody then begin
                FCells[x, y] := BODY_CELL;
            end
            // else we are placing a free
            else begin
                FCells[x, y] := FREE_CELL;
            end;
        end;
    end;

    // signal that width, height needs recalc
    FWidth := -1;
    FHeight := -1;    
end;


// given x, y find TvePin in Pins[] which belongs to that cell
function TveCellOutline.PinForCell( x, y : integer ) : TvePin;
var
    Cell : byte;
begin
    if (x >= TveCellOutline_MaxWidth) or (y >= TveCellOutline_MaxHeight) then begin
        raise ERangeError.Create( 'Cell x,y out of range' );
    end;

    Cell := FCells[x,y];

    // a body or empty cell doesn't link to an item in Pins[]
    if Cell > MAX_PIN_INDEX  then begin
        result := nil;
        exit;
    end;

    if Cell >= FPins.Count then begin
        raise ERangeError.Create( 'Cell to FPins[] mismatch' );
    end;

    result := TvePin( FPins[Cell] );
end;

function TveCellOutline.GetCellPinName( x, y : integer ) : string;
var
    Pin : TvePin;
begin
    Pin := PinForCell( x, y );
    if Pin = nil then begin
        raise ECell.Create( 'No cell pin at location' );
    end;

    result := Pin.Name;
end;

procedure TveCellOutline.SetCellPinName( x, y : integer; value : string );
var
    Pin : TvePin;
begin
    Pin := PinForCell( x, y );
    if Pin = nil then begin
        raise ECell.Create( 'No cell pin at location' );
    end;

    Pin.Name := value;
end;


procedure TveCellOutline.Paint( Item : TveBoardItem; Info : TvePainter );
const
    PivotX = 0;
    PivotY = 0;
var
    BodyLines : TPolyLines;
    PinLines : TPolyLines;
    PixelsPerCell : integer;
    Gap : integer;
    HalfLineWidth : integer;

    X, Y : integer;

    // Outline holds shape
    // Variables tell what surrounds current cell
    // Outline position on screen in pixels, top, left of cell[0,0]
    ComponentX, ComponentY : integer;
    // line segment coords held in these vars
    LineY1 : integer;

    // outline is rotated
    Rotation : TRotation;
    // Rotation is about this point
    RotationX, RotationY : integer;

    // radius of reference cell
    Radius : integer;

    // Pins
    PinNo : integer;
    // 3 corners of a pin
    PinX, PinY : integer;
    PinX0, PinY0 : integer;
    PinX1 {, PinY1} : integer;
    PinX2, PinY2 : integer;

    // Lines
    XUpperStart : integer;
    XLowerStart : integer;
    UpperStartConcave : boolean;
    LowerStartConcave : boolean;

    YLeftStart : integer;
    YRightStart : integer;
    LeftStartConcave : boolean;
    RightStartConcave : boolean;


    // designator
    DesignatorX, DesignatorY : integer;

    procedure Line( X1, Y1, X2, Y2 : integer );
    begin
        Rotate( X1, Y1, RotationX, RotationY, Rotation );
        Rotate( X2, Y2, RotationX, RotationY, Rotation );
        BodyLines.AddLine( X1, Y1, X2, Y2 );
    end;

    procedure Triangle( X1, Y1, X2, Y2, X3, Y3 : integer );
    begin
        Rotate( X1, Y1, RotationX, RotationY, Rotation );
        Rotate( X2, Y2, RotationX, RotationY, Rotation );
        Rotate( X3, Y3, RotationX, RotationY, Rotation );
        PinLines.AddPoint( X1, Y1 );
        PinLines.AddPoint( X2, Y2 );
        PinLines.AddPoint( X3, Y3 );
        PinLines.AddPoint( X1, Y1 );
        PinLines.EndShape;
    end;

    procedure UpperLine( XStart, X, Y : integer; StartConcave, EndConcave : boolean );
    var
        LineX, LineX1, LineY : integer;
    begin
        if StartConcave then begin
            LineX := ComponentX + (PixelsPerCell * XStart);
        end
        else begin
            LineX := ComponentX + (PixelsPerCell * XStart) + Gap + HalfLineWidth;
        end;
        if EndConcave then begin
            LineX1 := ComponentX + (PixelsPerCell * (X+1)) - Gap +1;
        end
        else begin
            LineX1 := ComponentX + (PixelsPerCell * (X+1)) - Gap - HalfLineWidth;
        end;
        LineY := ComponentY + (PixelsPerCell * Y) + Gap + HalfLineWidth;
        Line( LineX, LineY, LineX1, LineY );
    end;

    procedure LowerLine( XStart, X, Y : integer; StartConcave, EndConcave : boolean );
    var
        LineX, LineX1, LineY : integer;
    begin
        if StartConcave then begin
            LineX := ComponentX + (PixelsPerCell * XStart);
        end
        else begin
            LineX := ComponentX + (PixelsPerCell * XStart) + Gap + HalfLineWidth;
        end;
        if EndConcave then begin
            LineX1 := ComponentX + (PixelsPerCell * (X+1)) - Gap +1;
        end
        else begin
            LineX1 := ComponentX + (PixelsPerCell * (X+1)) - Gap - HalfLineWidth;
        end;
        LineY := ComponentY + (PixelsPerCell * (Y + 1)) - Info.Gap - HalfLineWidth;
        Line( LineX, LineY, LineX1, LineY );
    end;

    procedure LeftLine( X, YStart, Y : integer; StartConcave, EndConcave : boolean );
    var
        LineX, LineY, LineY1 : integer;
    begin
        if StartConcave then begin
            LineY := ComponentY + (PixelsPerCell * YStart);
        end
        else begin
            LineY := ComponentY + (PixelsPerCell * YStart) + Gap + HalfLineWidth;
        end;
        if EndConcave then begin
            LineY1 := ComponentY + (PixelsPerCell * (Y+1)) - Gap +1;
        end
        else begin
            LineY1 := ComponentY + (PixelsPerCell * (Y+1)) - Gap - HalfLineWidth;
        end;
        LineX := ComponentX + (PixelsPerCell * X) + Info.Gap + HalfLineWidth;
        Line( LineX, LineY, LineX, LineY1 );
    end;

    procedure RightLine( X, YStart, Y : integer; StartConcave, EndConcave : boolean );
    var
        LineX, LineY : integer;
    begin
        if StartConcave then begin
            LineY := ComponentY + (PixelsPerCell * YStart);
        end
        else begin
            LineY := ComponentY + (PixelsPerCell * YStart) + Gap + HalfLineWidth;
        end;
        if EndConcave then begin
            LineY1 := ComponentY + (PixelsPerCell * (Y+1)) - Gap +1;
        end
        else begin
            LineY1 := ComponentY + (PixelsPerCell * (Y+1)) - Gap - HalfLineWidth;
        end;
        LineX := ComponentX + (PixelsPerCell * (X+1)) - Gap - HalfLineWidth;
        Line( LineX, LineY, LineX, LineY1 );
    end;


    function CellType( x, y : integer ) : TCellType;
    begin
        if (x < 0) or (y < 0) or (x >= Width) or (y >= Height) then begin
            result := ctFree;
        end
        else begin
            case FCells[x,y] of
                BODY_CELL : result := ctBody;
                FREE_CELL : result := ctFree;
                else begin
                    result := ctPin;
                end
            end;
        end;
    end;

begin
    BodyLines := Info.BodyLines;
    PinLines := Info.PinLines;

    PixelsPerCell := Info.PixelsPerCell;
    Gap := Info.Gap;
    Rotation := Item.Rotation;
    HalfLineWidth := (Info.LineWidth div 2);

    //locate TCanvas pixels containing top left of outline (+1 pixel for border
    ComponentX := (Item.X * PixelsPerCell) + Info.Border;
    ComponentY := (Item.Y * PixelsPerCell) + Info.Border;

    // find centre of reference pin : ie perfboard hole at top left
    RotationX := ComponentX + (PixelsPerCell div 2);
    RotationY := ComponentY + (PixelsPerCell div 2);

    { We calculate everything in non-rotated position, then rotate around a
    graphics pixel.  
    }

    // draw reference pin as circle (Rectangle)
    Radius := PixelsPerCell div 4;
    BodyLines.AddRectangle( RotationX - Radius , RotationY - Radius,
        RotationX + Radius , RotationY + Radius );

    // find outline cell boundaries, drawing boundary lines
    for Y := 0 to Height -1 do begin
        for X := 0 to Width -1 do begin

            // draw pin as triangle
            // ******
            //  *  *
            //   *
            PinNo := FCells[x,y];
            if (PinNo <= MAX_PIN_INDEX ) then begin
                PinX := ComponentX + (X * PixelsPerCell);
                PinY := ComponentY + (Y * PixelsPerCell);
                PinX0 := PinX + (PixelsPerCell div 3);
                PinY0 := PinY + (PixelsPerCell div 3);
                PinX1 := PinX0 + (PixelsPerCell div 3);
                PinX2 := PinX + (PixelsPerCell div 2);
                PinY2 := PinY0 + (PixelsPerCell div 3);
                Triangle( PinX0, PinY0, PinX1, PinY0, PinX2, PinY2 );
            end;
         end;
    end;

    // stop compiler warnings - these assignments have no benefit
    XUpperStart := 0;
    XLowerStart := 0;
    UpperStartConcave := False;
    LowerStartConcave := False;
    YLeftStart := 0;
    YRightStart := 0;
    LeftStartConcave := False;
    RightStartConcave := False;

    // Find horizontal lines
    // ...for each row
    for Y := 0 to Height -1 do begin

        // for each cell across the row, left to right
        for X := 0 to Width -1 do begin

            // ignore empty cells - only occupied cells can have a border line
            if CellType(X,Y) = ctFree then begin
                continue;
            end;

            // horizontal top line
            if CellType(X,Y-1) = ctFree then begin

                // start of line, convex
                //    _
                //   |   = convex  (outer corner)
                if CellType(X-1,Y) = ctFree then begin
                    XUpperStart := X;
                    UpperStartConcave := False;
                end

                // start of line, concave
                //   |_  = concave (inner corner)
                else if CellType(X-1,Y-1) <> ctFree then begin
                    XUpperStart := X;
                    UpperStartConcave := True;
                end;

                // end of line, convex
                //    _
                //     |  = convex  (outer corner)
                if CellType(X+1,Y) = ctFree then begin
                    UpperLine( XUpperStart, X, Y, UpperStartConcave, False );
                end

                // end of line, concave
                //  _|  = concave (inner corner)
                else if CellType(X+1,Y-1) <> ctFree then begin
                    UpperLine( XUpperStart, X, Y, UpperStartConcave, True );
                end;
            end;

            // horizontal bottom line
            if CellType(X,Y+1) = ctFree then begin

                // start of line, convex
                //   |_  = convex  (outer corner)
                if CellType(X-1,Y) = ctFree then begin
                    XLowerStart := X;
                    LowerStartConcave := False;
                end

                // start of line, concave
                //   _
                //  |   concave (inner corner)
                else if CellType(X-1,Y+1) <> ctFree then begin
                    XLowerStart := X;
                    LowerStartConcave := True;
                end;

                // end of line, convex
                //    _|  = convex  (outer corner)
                if CellType(X+1,Y) = ctFree then begin
                    LowerLine( XLowerStart, X, Y, LowerStartConcave, False );
                end

                // end of line, concave
                //  _|  = concave (inner corner)
                else if CellType(X+1,Y+1) <> ctFree then begin
                    LowerLine( XLowerStart, X, Y, LowerStartConcave, True );
                end;
            end;
        end;
    end;

    // Find vertical lines
    // ...for each column
    for X := 0 to Width -1 do begin

        // for each cell downn the columns, top to bottom
        for Y := 0 to Height -1 do begin

            // ignore empty cells - only occupied cells can have a border line
            if CellType(X,Y) = ctFree then begin
                continue;
            end;

            // vertical left line
            if CellType(X-1,Y) = ctFree then begin

                // start of line, convex
                //    _
                //   |   = convex  (outer corner)
                if CellType(X,Y-1) = ctFree then begin
                    YLeftStart := Y;
                    LeftStartConcave := False;
                end

                // start of line, concave
                //   _|  = concave (inner corner)
                else if CellType(X-1,Y-1) <> ctFree then begin
                    YLeftStart := Y;
                    LeftStartConcave := True;
                end;

                // end of line, convex
                //    _|   = convex  (outer corner)
                if CellType(X,Y+1) = ctFree then begin

                    // record line
                    LeftLine( X, YLeftStart, Y, LeftStartConcave, False );
                end

                // end of line, concave
                //  _
                //   |  = concave (inner corner)
                else if CellType(X-1,Y+1) <> ctFree then begin
                    // record line
                    LeftLine( X, YLeftStart, Y, LeftStartConcave, True );
                end;
            end;

            // vertical right line
            if CellType(X+1,Y) = ctFree then begin

                // start of line, convex
                //    _
                //     |   = convex  (outer corner)
                if CellType(X,Y-1) = ctFree then begin
                    YRightStart := Y;
                    RightStartConcave := False;
                end

                // start of line, concave
                //     _
                //    |  = concave (inner corner)
                else if CellType(X+1,Y-1) <> ctFree then begin
                    YRightStart := Y;
                    RightStartConcave := True;
                end;

                // end of line, convex
                //  _|   = convex  (outer corner)
                if CellType(X,Y+1) = ctFree then begin
                    RightLine( X, YRightStart, Y, RightStartConcave, False );
                end

                // end of line, concave
                //   |_  = concave (inner corner)
                else if CellType(X+1,Y+1) <> ctFree then begin
                    RightLine( X, YRightStart, Y, RightStartConcave, True );
                end;
            end;
        end;

    end;


    // print designator
    if not Item.TextVisible then begin
        exit;
    end;

    DesignatorX :=
        (Item.TextX * PixelsPerCell) + ComponentX + (PixelsPerCell div 2);
    DesignatorY :=
        (Item.TextY * PixelsPerCell) + ComponentY  + (PixelsPerCell div 2);;

    // text position is rotated along with the rest of the component
    // around the item (0.0) reference point
    Rotate( DesignatorX, DesignatorY,
            RotationX, RotationY,
            Rotation   );

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


// *** See if Outline Occupies Cell At Coords ***
// returns True : this outline occupies the cell, else False
function TveCellOutline.OccupiesCell(  Item : TveBoardItem; CellX, CellY : integer )
    : boolean;
var
    CompX, CompY : integer;
begin
    // convert screen cell coords to outline cell coords
    CompX := CellX - Item.X;
    CompY := CellY - Item.Y;

    // rotate cell coords to follow outline rotation
    RotateReverse( CompX, CompY, 0, 0, Item.Rotation );

    // see if our location hits a cell used by our outline
    result := CellTypes[CompX,CompY] <> ctFree;
end;

{
function TveCellOutline.InsideRectangle( Item : TveBoardItem;
    CellX1, CellY1, CellX2, CellY2 : integer ) : boolean;

var
    RectX1, RectY1 : integer;
    RectX2, RectY2 : integer;
    Temp : integer;

begin
    // convert screen cell coords to outline cell coords
    RectX1 := CellX1 - Item.X;
    RectY1 := CellY1 - Item.Y;
    RectX2 := CellX2 - Item.X;
    RectY2 := CellY2 - Item.Y;

    // rotate cell coords to follow outline rotation
    RotateReverse( RectX1, RectY1, 0, 0, Item.Rotation );
    RotateReverse( RectX2, RectY2, 0, 0, Item.Rotation );

    // swap coords to get top,left bottom,right of rectangle
    if (RectX1 > RectX2) then begin
        Temp := RectX1;
        RectX1 := RectX2;
        RectX2 := Temp;
    end;
    if (RectY1 > RectY2) then begin
        Temp := RectY1;
        RectY1 := RectY2;
        RectY2 := Temp;
    end;

    // see if our location is inside rectangle
    result :=
        (RectX1 < 0) and (RectX2 >= Width) and
        (RectY1 < 0) and (RectY2 >= Height);
end;
}

procedure TveCellOutline.RotateAboutCenter( Item : TveBoardItem );
var
    Angle : TRotation;
//    OriginX, OriginY : integer;
begin
    // Calculate new location point for outline.
    // Adjust position of outline origin so that top left of Item
    // width x height rectangle is always at same square.
    case Item.Rotation of

        rot0 : begin
            Item.Y := Item.Y + Width - 1;
        end;
        rot90 : begin
            Item.X := Item.X + Width - 1;
            Item.Y := Item.Y - Width  + Height;
        end;
        rot180 : begin
            Item.Y := Item.Y - Height + 1;
            Item.X := Item.X - Width + Height;
        end;
        rot270 : begin
            Item.X := Item.X - Height + 1;
        end
    end;

    // calculate new rotation for Item
    Angle := Item.Rotation;
    Item.Rotation := TRotation( (Ord(Angle) + 1) mod 4 );
end;

function TveCellOutline.PinIndexAt( Item : TveBoardItem; CellX, CellY : integer )
    : integer;
var
    CompX, CompY : integer;
    CellValue : byte;
begin
    // convert screen cell coords to outline cell coords
    CompX := CellX - Item.X;
    CompY := CellY - Item.Y;

    // rotate cell coords to follow outline rotation
    RotateReverse( CompX, CompY, 0, 0, Item.Rotation );

    if(CompX >= TveCellOutline_MaxWidth) or (CompY >= TveCellOutline_MaxHeight) or
    (CompX < 0) or (CompY < 0) then begin
        result := -1;
        exit;
    end;

    CellValue := FCells[CompX, CompY];

    // if our location does not hit a pin..
    if CellValue > MAX_PIN_INDEX then begin
        result := -1;
    end
    // hit a pin
    else begin
        result := CellValue;
    end;
end;


procedure TveCellOutline.GetScreenRectR( Item : TveBoardItem; var R : TRect );
begin
    // create rectangle which includes all cells in this outline
    // this is not a bounding rectangle - hence we subtract 1 from width, height
    R.Left := Item.X;
    R.Right := Item.X + Width - 1;
    R.Top := Item.Y;
    R.Bottom := Item.Y + Height - 1;

    Rotate( R.Right, R.Bottom, Item.X, Item.Y, Item.Rotation );

    // arrange rotated coords to give left,top and right,bottom of rectangle.
    NormalizeRect( R );

    // turn into bounding rectangle
    Inc( R.Right );
    Inc( R.Bottom );
end;

procedure TveCellOutline.ToFirstPin;
begin
    // start search from 0,0
    NextPinX := 0;
    NextPinY := 0;
end;

function TveCellOutline.GetNextPin(
    Item : TveBoardItem; var X, Y, PinIndex : integer ) : boolean;
var
    SearchX, SearchY : integer;
    SearchCell : byte;
    FoundX, FoundY : integer;
begin
    // continue to search every cell in matrix !
    for SearchX := NextPinX to Width -1 do begin

        for SearchY := NextPinY to Height -1 do begin

            // if found matching pin
            SearchCell := FCells[SearchX, SearchY];
            if (SearchCell < MAX_PIN_INDEX) then begin

                // leave record of where to continue searching
                NextPinX := SearchX;
                NextPinY := SearchY + 1;

                FoundX := SearchX;
                FoundY := SearchY;

                // rotate X,Y for Item
                Rotate( FoundX, FoundY, 0, 0, Item.Rotation );

                // add offset for item position
                Inc( FoundX, Item.X );
                Inc( FoundY, Item.Y );

                // return results
                X := FoundX;
                Y := FoundY;
                PinIndex := SearchCell;

                result := True;
                exit;
            end;
        end;

        // inner loop always scans from 0 again
        NextPinY := 0;
    end;

    // not found
    result := False;
end;


function TveCellOutline.GetPin( index : integer ) : TvePin;
begin
    if not PinListValid  then begin
//        BuildPinList;
    end;
    result := TvePin( FPins[index] );
end;

// ** Outline writes its properties to a stream - override this virtual function
// ** in descendants **
procedure TveCellOutline.WriteToStream( S : TStream );

    procedure LineOut( const text : string );
    begin
        LineToStream( S, text );
    end;

var
    Y : integer;
    X : integer;
    Line : string;
    CellLetter : string;
begin
    LineOut( Format( 'Outline=%s', [ClassName] ) );
    LineOut( Format('Name=%s', [Name]) );

    // susequent rows are cell data eg. "ROW,3, X, X, 6"
    CellLetter := 'X';
    for Y := 0 to Height -1 do begin
        Line := 'Row=';
        for X := 0 to Width -1 do begin
            case CellTypes[X,Y] of
                ctFree : CellLetter := 'X';
                ctBody : CellLetter := 'E';
                ctPin : CellLetter := 'P' + CellPinNames[X,Y];
            end;
            if X = 0 then begin
                Line := Line + CellLetter;
            end
            else begin
                Line := Line + ',' + CellLetter;
            end;
        end;
        LineOut( Line );
    end;

    LineOut( 'end' );
end;

procedure TveCellOutline.ReadFromStream( S : TStream );
var
    AName, AValue : string;
    ScanIndex : integer;
    PinText : string;
    X : integer;
    Y : integer;
begin
{
Name=DIP6
Row=1XX6
Row=2EE5
Row=3EE4
end
}   // start at top row of pins
    Y := 0;

    while NameValueFromStream( S, AName, AValue ) do begin

        if AName = 'Name' then begin
            FName := AValue;
        end

        else if AName = 'Row' then begin
            ScanIndex := 0;
            X := 0;
            while ParseCSVValue( AValue, PinText, ScanIndex ) do begin
                if PinText = 'X' then begin
                    CellTypes[X,Y] := ctFree;
                end
                else if PinText = 'E' then begin
                    CellTypes[X,Y] := ctBody;
                end
                else begin
                    CellTypes[X,Y] := ctPin;
                    // ignore initial 'P' and use rest as pin name
                    CellPinNames[X,Y] := Copy(PinText, 2, 99 );
                end;
                Inc( X );
            end;
            // to next row
            Inc( Y );
        end

        else if AName = 'end' then begin
            exit;
        end;
    end;
end;



end.


