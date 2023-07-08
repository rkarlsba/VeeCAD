unit Painter;

interface

uses Windows, Graphics, Rotations, GdiHandles;

type TvePaintOption = ( poXOR );
type TvePaintOptions = set of TvePaintOption;
type TTextDisplay = ( tdNone, tdDesignator, tdValue );
type TLeadStyle = ( lsHollow, lsLine );

// *************** TPolyLines ***************

type
    TPointList = array[0..10] of TPoint;    // fake array length
    PPointList = ^TPointList;

    TCountList = array[0..10] of DWORD;     // fake array length
    PCountList = ^TCountList;

type TPolyLines = class

  protected
    PointList : PPointList;   // points to list of TPoints
    CountList : PCountList;   // stores # of points in each shape

    PointCapacity : integer;
    PointCount : integer;

    CountCapacity : integer;
    CountCount : integer;

    VertexCount : integer;

    // used by RewindPolyLines and GetNextPolyLine
    ReadPointIndex : integer;
    ReadCountIndex : integer;

  public
//    property Count : integer read
    procedure Clear;
    procedure AddPoint( X, Y : integer );
    procedure EndShape;
    procedure AddRectangle( X1, Y1, X2, Y2 : integer );
    procedure AddLine( X1, Y1, X2, Y2 : integer );
    procedure Rewind;
    function GetNext( var Count : integer; var Points : PPointList) : boolean;
    procedure Paint( Canvas : TCanvas );

    constructor Create;
    destructor Destroy; override;
end;

// *************** TPaintStrings ************

type
    TStringPosRec = record
        Text : string;
        X : integer;
        Y : integer;
        Rotation : TRotation;
    end;

type TPaintStrings = class

  protected
    StringData : array of TStringPosRec;
    Capacity : integer;
    Count : integer;

  public

    procedure Clear;
    procedure Add( S : string; X, Y : integer );
    procedure Paint( Canvas : TCanvas );
    procedure PaintMirroredDC( Canvas : TCanvas );
end;


// *************** TPaintRotatedStrings ************

type TPaintRotatedStrings = class( TPaintStrings )

  public
    procedure Add( s : string; X, Y : integer; Rot : TRotation );
    procedure PaintDC( DC : hDC; Rot : TRotation );
    procedure PaintDCMirroredDC( DC : hDC; Rot : TRotation );
end;


// *************** TPaintCircles ************

type
    TCircleRec = record
        X1, Y1, X2, Y2, X3, Y3, X4, Y4 : Integer;
    end;

    TCircleList = array[0..10] of TCircleRec;     // fake array length
    PCircleList = ^TCircleList;


type TPaintCircles = class

  protected
    CircleRecList : PCircleList;
    Capacity : integer;
    FCount : integer;
    FSegments : integer;
    function GetArc( index : integer ) : TCircleRec;
  public
    property Count : integer read FCount;
    property Arcs[index : integer] : TCircleRec read GetArc; default;
    property Segments : integer read FSegments write FSegments;
    procedure Clear;
    procedure AddCircle( X1, Y1, X2, Y2 : integer );
    procedure AddArc( X1, Y1, X2, Y2, X3, Y3, X4, Y4 : integer );
    procedure Paint( Canvas : TCanvas );
    constructor Create;
    destructor Destroy; override;
end;


// *************** TPainter ************

type TvePainter = class

  protected
    FBodyLines : TPolyLines;
    FBodyCircles : TPaintCircles;
    FPinLines : TPolyLines;
    FBodyText : TPaintStrings;
    FSmallText : TPaintRotatedStrings;
    FLargeText : TPaintRotatedStrings;

    // Font GDI objects for writing text
    Font0 : TFontHandle;
    Font90 : TFontHandle;
    Font180 : TFontHandle;
    Font270 : TFontHandle;

    // Font GDI objects for writing large text
    FLargeFont0 : TFontHandle;
    FLargeFont90 : TFontHandle;
    FLargeFont180 : TFontHandle;
    FLargeFont270 : TFontHandle;

    // user config
    FLineWidth : integer;
    FBodyColor : TColor;
    FPinColor : TColor;
    FSelectionColor : TColor;
    FLeadStyle : TLeadStyle;

    // text sizes
    FTextWidth : integer;
    FTextHeight : integer;
    FlargeTextWidth : integer;
    FLargeTextHeight : integer;

    // text font names
    FTextName : string;
    FLargeTextName : string;

    // text bold
    FTextBold : boolean;
    FLargeTextBold : boolean;


    procedure SetTextWidth( value : integer );
    procedure SetTextHeight( value : integer );
    procedure SetLargeTextWidth( value : integer );
    procedure SetLargeTextHeight( value : integer );
    procedure SetTextName( value : string );
    procedure SetLargeTextName( value : string );
    procedure SetTextBold( value : boolean );
    procedure SetLargeTextBold( value : boolean );

  public

    // tramp data available to object drawing code
    Border : integer;
    Gap : integer;
    PixelsPerCell : integer;
    Options : TvePaintOptions;
    TextDisplay : TTextDisplay;

    // storage of drawn items
    property BodyLines : TPolyLines read FBodyLines;
    property PinLines : TPolyLines read FPinLines;
    property BodyText : TPaintStrings read FBodyText;
    property SmallText : TPaintRotatedStrings read FSmallText;
    property LargeText : TPaintRotatedStrings read FLargeText;
    property BodyCircles : TPaintCircles read FBodyCircles write FBodyCircles;

    // DC font handles used for rotatable text (small)
    property SmallTextWidth : integer read FTextWidth write SetTextWidth;
    property SmallTextHeight : integer read FTextHeight write SetTextHeight;
    property SmallTextName : string read FTextName write SetTextName;
    property SmallTextBold : boolean read FTextBold write SetTextBold;

    property SmallFont0 : TFontHandle read Font0;
    property SmallFont90 : TFontHandle read Font90;
    property SmallFont180 : TFontHandle read Font180;
    property SmallFont270 : TFontHandle read Font270;

    // DC font handles used for rotatable text (large)
    property LargeTextWidth : integer read FLargeTextWidth write SetLargeTextWidth;
    property LargeTextHeight : integer read FLargeTextHeight write SetLargeTextHeight;
    property LargeTextName : string read FLargeTextName write SetLargeTextName;
    property LargeTextBold : boolean read FLargeTextBold write SetLargeTextBold;

    property LargeFont0 : TFontHandle read FLargeFont0;
    property LargeFont90 : TFontHandle read FLargeFont90;
    property LargeFont180 : TFontHandle read FLargeFont180;
    property LargeFont270 : TFontHandle read FLargeFont270;

    // user config properties
    property LineWidth : integer read FLineWidth write FLineWidth;
    property LeadStyle : TLeadStyle read FLeadStyle write FLeadStyle;
    property BodyColor : TColor read FBodyColor write FBodyColor;
    property PinColor : TColor read FPinColor write FPinColor;
//    property DesignatorColor : TColor read FDesignatorColor write FDesignatorColor;
    property SelectionColor : TColor read FSelectionColor write FSelectionColor;

    procedure Clear;
    procedure PaintSelected( Canvas : TCanvas );
    procedure PaintNormal( Canvas : TCanvas );
    procedure PaintXOR( Canvas : TCanvas );
//    procedure PaintMonochrome;

    constructor Create;
    destructor Destroy; override;

end;


implementation

uses SysUtils, WineHelper;


// *************************************
//          TPolyLines
// *************************************

{ This class accepts definitions of shapes defined as a series of points to be
connected by lines.  The points are added with AddPoint and once a shape is
defined, EndShape is called.  After this, the next shape is started with a
call to AddPoint.

Uses dynamic memory allocation, so won't hog RAM unless large number of points.
}

procedure TPolyLines.Clear;
begin
    PointCount := 0;
    CountCount := 0;
    VertexCount := 0;
end;

procedure TPolyLines.AddPoint( X, Y : integer );
var
    P : ^TPoint;
begin
    P := @PointList^[PointCount];
    P^.X := X;
    P^.Y := Y;
    Inc( PointCount );
    Inc( VertexCount );
end;

procedure TPolyLines.EndShape;  // .EndShape
begin
    // see if we need to expand - we want 1000 points available for the next
    // shape - plenty of space since a shape is typically 15 points
    if PointCount > (PointCapacity - 1000) then begin
        // extend the points by 8192 points
        Inc( PointCapacity, 8192 );
        ReAllocMem( PointList, PointCapacity * sizeof(TPoint) );
    end;

    // we must have room for the next count
    if CountCount >= CountCapacity then begin
        // extend the count by 3000 points
        Inc( CountCapacity, 3000 );
        ReAllocMem( CountList, CountCapacity * sizeof(DWORD) );
    end;

    // record number of vertexes in CountList
    CountList^[CountCount] := VertexCount;
    Inc( CountCount );
    VertexCount := 0;
end;

procedure TPolyLines.AddRectangle( X1, Y1, X2, Y2 : integer );
begin
    AddPoint( X1, Y1 );
    AddPoint( X1, Y2 );
    AddPoint( X2, Y2 );
    AddPoint( X2, Y1 );
    AddPoint( X1, Y1 );
    EndShape;
end;

procedure TPolyLines.AddLine( X1, Y1, X2, Y2 : integer );
begin
    AddPoint( X1, Y1 );
    AddPoint( X2, Y2 );
    EndShape;
end;

procedure TPolyLines.Paint( Canvas : TCanvas );
var
    DC : hDC;
    i : integer;
    PointIndex : integer;
begin
    // force canvas to have a DC
    DC := Canvas.handle;

    // select pen into DC of Canvas - already done when Canvas.DC executes ?
    //    Canvas.Pen.Handle;

    // get Windows to draw all line segments - very slow on some PCs
    // and Win9x has 1300 points limit on lines wider than 1 pixel, so don't do it.
    //    PolyPolyLine( DC, BodyLinePoints, BodyLineCounts, BodyLineCountIndex );

    // replacement for PolyPolyLine()
    PointIndex := 0;
    for i := 0 to CountCount -1 do begin
        PolyLine( DC,  PointList^[PointIndex], CountList^[i] );
        Inc( PointIndex, CountList^[i] );
    end;

// function PolyPolyline(DC: HDC; const PointStructs; const Points; p4: DWORD): BOOL; stdcall;
// function Polyline(DC: HDC; var Points; Count: Integer): BOOL; stdcall;
end;

//
procedure TPolyLines.Rewind;
begin
  ReadPointIndex := 0;    // index into array of points
  ReadCountIndex := 0;    // index into array of counts
end;


function TPolyLines.GetNext( var Count : integer; var Points : PPointList) : boolean;
begin
  // if nothing left to read out
  if ReadCountIndex >= CountCount then begin
    result := False;
    exit;
  end;

  // get count (ie. no. of points in this polyline
  Count := CountList^[ReadCountIndex];
  // get address of next set of points
  Points := PPointList(@(PointList^[ReadPointIndex]));

  // bump point index to next set of points
  Inc( ReadPointIndex, CountList^[ReadCountIndex] );

  // move to count for next set of points
  Inc( ReadCountIndex );

  Result := True;
end;

constructor TPolyLines.Create;
begin
    PointCapacity := 8192;
    PointList := AllocMem( PointCapacity * sizeof(TPoint) );

    CountCapacity := 3000;
    CountList := AllocMem( CountCapacity * sizeof(DWORD) );
end;

destructor TPolyLines.Destroy;
begin
    FreeMem( PointList );
    FreeMem( CountList );
    inherited;
end;

// *************************************
//          TPolyStrings
// *************************************

procedure TPaintStrings.Clear;
begin
    Count := 0;
end;

procedure TPaintStrings.Add( S : string; X, Y : integer );
var
    Data : ^TStringPosRec;
begin
    // make room if needed
    if Count >= Capacity then begin
        Inc( Capacity, 200 );
        SetLength( StringData, Capacity );
        FillChar( StringData[Count], 200, 0 );
    end;

    Data := @(StringData[Count]);
    Data^.X := X;
    Data^.Y := Y;
    Data^.Text := S;
    Inc( Count );
end;

// call this function with DC set to centered text with SetTextAlign( DC, TA_CENTER );

procedure TPaintStrings.Paint( Canvas : TCanvas );
var
    i : integer;
    Data : ^TStringPosRec;
    TextSize : TSize;
begin
    for i := 0 to Count -1 do begin
        Data := @StringData[i];
        TextSize := Canvas.TextExtent( Data^.Text );
        Canvas.TextOut(
            Data^.X,
            Data^.Y - (TextSize.cy div 2),
            Data^.Text
        );
    end;
end;

// call this function with DC set to centered text with SetTextAlign( DC, TA_CENTER );

procedure TPaintStrings.PaintMirroredDC( Canvas : TCanvas );
var
    i : integer;
    Data : ^TStringPosRec;
    TextSize : TSize;
begin
    for i := 0 to Count -1 do begin
        Data := @StringData[i];
        TextSize := Canvas.TextExtent( Data^.Text );
        Canvas.TextOut(
            Data^.X {- (TextSize.cx div 2)},
            Data^.Y + (TextSize.cy div 2),
            Data^.Text
        );
    end;
end;

// *************************************
//          TPolyRotatedStrings
// *************************************

procedure TPaintRotatedStrings.Add( S : string; X, Y : integer; Rot : TRotation );
var
    Data : ^TStringPosRec;
begin
    // make room if needed
    if Count >= Capacity then begin
        Inc( Capacity, 200 );
        SetLength( StringData, Capacity );
        FillChar( StringData[Count], 200, 0 );
    end;

    Data := @(StringData[Count]);
    Data^.X := X;
    Data^.Y := Y;
    Data^.Text := S;
    Data^.Rotation := Rot;
    Inc( Count );
end;

// call this function with DC set to centered text with SetTextAlign( DC, TA_CENTER );

procedure TPaintRotatedStrings.PaintDC( DC : hDC; Rot : TRotation );
var
    i : integer;
    Data : ^TStringPosRec;
    TextSize : TSize;
    OffsetX, OffsetY : integer;
begin
    for i := 0 to Count -1 do begin
        Data := @StringData[i];
        if Data^.Rotation = Rot then begin

            // note GetTextExtentPoint32 returns height & width as though
            // characters were not rotated. ie escapement = 0
            GetTextExtentPoint32( DC, pChar(Data^.Text), length(Data^.Text), TextSize );

            case Rot of

                Rot0 : begin
                    OffsetX := 0;
                    OffsetY := - (TextSize.cy div 2);
                end;
                Rot90 : begin
                    OffsetX := - (TextSize.cy div 2);
                    OffsetY := 0;
                end;
                Rot180 : begin
                    OffsetX := 0;
                    OffsetY := + (TextSize.cy div 2);
                end
                {Rot270 :} else begin
                    OffsetX := + (TextSize.cy div 2);
                    OffsetY := 0;
                end;
            end;
            TextOut(
                DC,
                Data^.X + OffsetX,
                Data^.Y + OffsetY,
                pChar(Data^.Text),
                length(Data^.Text)
            );
        end;
    end;
end;


procedure TPaintRotatedStrings.PaintDCMirroredDC( DC : hDC; Rot : TRotation );
begin
end;

// *************************************
//            TPaintCircles
// *************************************

procedure TPaintCircles.Clear;
begin
    FCount := 0;
end;

procedure TPaintCircles.AddCircle( X1, Y1, X2, Y2 : integer );
begin
    AddArc( X1, Y1, X2, Y2, X1, Y1, X1, Y1 );
end;

procedure TPaintCircles.AddArc( X1, Y1, X2, Y2, X3, Y3, X4, Y4 : integer );
var
    Data : ^TCircleRec;
begin
    // make room if needed
    if FCount >= Capacity then begin
        Inc( Capacity, 200 );
        ReAllocMem( CircleRecList, Capacity * sizeof(TCircleRec) );
    end;

    // add another record
    Data := @CircleRecList^[FCount];
    Data^.X1 := X1;
    Data^.Y1 := Y1;
    Data^.X2 := X2;
    Data^.Y2 := Y2;
    Data^.X3 := X3;
    Data^.Y3 := Y3;
    Data^.X4 := X4;
    Data^.Y4 := Y4;
    Inc( FCount );
end;


procedure TPaintCircles.Paint( Canvas : TCanvas );
var
    i : integer;
    Data : ^TCircleRec;
const Linux : boolean = False;
begin
    // draw arc using ellipse function
    if FSegments = 0 then begin
        for i := 0 to FCount -1 do begin
            Data := @CircleRecList^[i];
            Canvas.Arc(
                Data^.X1, Data^.Y1, Data^.X2, Data^.Y2,
                Data^.X3, Data^.Y3, Data^.X4, Data^.Y4
            );
        end;
    end
    // else draw arc as a series of line segments
    else begin
        for i := 0 to FCount -1 do begin
            Data := @CircleRecList^[i];
            PaintArc( Canvas, 10,
                Data^.X1, Data^.Y1, Data^.X2, Data^.Y2,
                Data^.X3, Data^.Y3, Data^.X4, Data^.Y4
            );
        end;
    end;
end;

function TPaintCircles.GetArc( index : integer ) : TCircleRec;
begin
  result := CircleRecList^[index];
end;

constructor TPaintCircles.Create;
begin
    Capacity := 200;
    CircleRecList := AllocMem( Capacity * sizeof( TCircleRec ) );
end;

destructor TPaintCircles.Destroy;
begin
    FreeMem( CircleRecList );
    inherited;
end;


// *************************************
//            TvePainter
// *************************************


procedure TvePainter.SetTextWidth( value : integer );
begin
    Font0.Width := value;
    Font90.Width := value;
    Font180.Width := value;
    Font270.Width := value;
    FTextWidth := value;
end;

procedure TvePainter.SetTextHeight( value : integer );
begin
    Font0.Height := value;
    Font90.Height := value;
    Font180.Height := value;
    Font270.Height := value;
    FTextHeight := value;
end;

procedure TvePainter.SetLargeTextWidth( value : integer );
begin
    LargeFont0.Width := value;
    LargeFont90.Width := value;
    LargeFont180.Width := value;
    LargeFont270.Width := value;
    FLargeTextWidth := value;
end;

procedure TvePainter.SetLargeTextHeight( value : integer );
begin
    LargeFont0.Height := value;
    LargeFont90.Height := value;
    LargeFont180.Height := value;
    LargeFont270.Height := value;
    FLargeTextHeight := value;
end;

procedure TvePainter.SetTextName( value : string );
begin
    Font0.Name := value;
    Font90.Name := value;
    Font180.Name := value;
    Font270.Name := value;
    FTextName := value;
end;

procedure TvePainter.SetLargeTextName( value : string );
begin
    LargeFont0.Name := value;
    LargeFont90.Name := value;
    LargeFont180.Name := value;
    LargeFont270.Name := value;
    FLargeTextName := value;
end;

procedure TvePainter.SetTextBold( value : boolean );
begin
    Font0.Bold := value;
    Font90.Bold := value;
    Font180.Bold := value;
    Font270.Bold := value;
    FTextBold := value;
end;

procedure TvePainter.SetLargeTextBold( value : boolean );
begin
    LargeFont0.Bold := value;
    LargeFont90.Bold := value;
    LargeFont180.Bold := value;
    LargeFont270.Bold := value;
    FLargeTextBold := value;
end;

procedure TvePainter.Clear;
begin
    FBodyLines.Clear;
    FBodyCircles.Clear;
    FPinLines.Clear;
    FBodyText.Clear;
    FSmallText.Clear;
    FLargeText.Clear;
end;

procedure TvePainter.PaintSelected( Canvas : TCanvas );
var
    DC : hDC;
    OldFont : hFont;
begin
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Width := FLineWidth;
    Canvas.Pen.Color := FSelectionColor;

    // ** Paint Outline Bodies **
    BodyLines.Paint( Canvas );
    FBodyCircles.Paint( Canvas );

    // ** Paint Outline Text **
    PinLines.Paint( Canvas );
{
    if PixelsPerCell < 8 then begin
        Canvas.Font.Name := 'Small Fonts';
    end
    else begin
        Canvas.Font.Name := 'Arial';
    end;
}
    Canvas.Font.Name := 'Arial';
    SetBkMode(Canvas.handle, TRANSPARENT);
    Canvas.Font.Height := (PixelsPerCell * 6) div 8;
    SetTextAlign( Canvas.Handle, TA_CENTER );
    BodyText.Paint( Canvas );

    // *** Paint Designators **
    DC := Canvas.Handle;
    SetTextColor( DC, FSelectionColor );  // reset by Canvas.TextOut() calls which follow

    OldFont := SelectObject( DC, Font0.Handle );
    try
        // paint small text
        SmallText.PaintDC( Canvas.Handle, Rot0 );
        SelectObject( DC, Font90.Handle );
        SmallText.PaintDC( Canvas.Handle, Rot90 );
        SelectObject( DC, Font180.Handle );
        SmallText.PaintDC( Canvas.Handle, Rot180 );
        SelectObject( DC, Font270.Handle );
        SmallText.PaintDC( Canvas.Handle, Rot270 );

        // paint large text
        SelectObject( DC, LargeFont0.Handle );
        LargeText.PaintDC( DC, Rot0 );
        SelectObject( DC, LargeFont90.Handle );
        LargeText.PaintDC( DC, Rot90 );
        SelectObject( DC, LargeFont180.Handle );
        LargeText.PaintDC( DC, Rot180 );
        SelectObject( DC, LargeFont270.Handle );
        LargeText.PaintDC( DC, Rot270 );

    finally
        SelectObject( DC, OldFont );
    end;
end;

procedure TvePainter.PaintNormal( Canvas : TCanvas );
var
    DC : hDC;
    OldFont : hFont;
begin
    // ** Paint Outline Bodies **
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Width := FLineWidth;

    Canvas.Pen.Color := FBodyColor;
    FBodyLines.Paint( Canvas );
    FBodyCircles.Paint( Canvas );

    // ** Paint Outline Pins **
    Canvas.Pen.Color := FPinColor;
    FPinLines.Paint( Canvas );

    // ** Paint Outline Body Text (wires have this)**
{
    if PixelsPerCell < 8 then begin
        Canvas.Font.Name := 'Small Fonts';
    end
    else begin
        Canvas.Font.Name := 'Arial';
    end;
}
    Canvas.Font.Name := 'Arial';
    SetBkMode(Canvas.handle, TRANSPARENT);
    Canvas.Font.Height := (PixelsPerCell * 6) div 8;
    SetTextAlign( Canvas.Handle, TA_CENTER );
    FBodyText.Paint( Canvas );

    // *** Paint Designators **
    DC := Canvas.Handle;

    // ..all text is centered horizontally
    SetTextAlign( DC, TA_CENTER );
    OldFont := SelectObject( DC, Font0.Handle );
    try
        SmallText.PaintDC( DC, Rot0 );
        SelectObject( DC, Font180.Handle );
        SmallText.PaintDC( DC, Rot180 );
        SelectObject( DC, Font90.Handle );
        SmallText.PaintDC( DC, Rot90 );
        SelectObject( DC, Font270.Handle );
        SmallText.PaintDC( DC, Rot270 );

        // paint large text
        SelectObject( DC, LargeFont0.Handle );
        LargeText.PaintDC( DC, Rot0 );
        SelectObject( DC, LargeFont90.Handle );
        LargeText.PaintDC( DC, Rot90 );
        SelectObject( DC, LargeFont180.Handle );
        LargeText.PaintDC( DC, Rot180 );
        SelectObject( DC, LargeFont270.Handle );
        LargeText.PaintDC( DC, Rot270 );

    finally
        SelectObject( DC, OldFont );
    end;
end;

procedure TvePainter.PaintXOR( Canvas : TCanvas );
begin
    Canvas.Pen.Width := FLineWidth;
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Mode := pmXOr;
    Canvas.Pen.Color := clYellow;

    FBodyLines.Paint( Canvas );
    FBodyCircles.Paint( Canvas );

    PinLines.Paint( Canvas );
    // Don't paint text, because it cannot XOR
end;


constructor TvePainter.Create;
begin
    FBodyLines := TPolyLines.Create;
    FBodyCircles := TPaintCircles.Create;
    FPinLines := TPolyLines.Create;
    FBodyText := TPaintStrings.Create;
    FSmallText := TPaintRotatedStrings.Create;
    FLargeText := TPaintRotatedStrings.Create;

    // small fonts at all rotations
    Font0 := TFontHandle.Create;
    Font0. Angle := 0;

    Font90 := TFontHandle.Create;
    Font90.Angle := 900;

    Font180 := TFontHandle.Create;
    Font180.Angle := 1800;

    Font270 := TFontHandle.Create;
    Font270.Angle := 2700;

    // large fonts at all rotations
    FLargeFont0 := TFontHandle.Create;
    FLargeFont0.Angle := 0;

    FLargeFont90 := TFontHandle.Create;
    FLargeFont90.Angle := 900;

    FLargeFont180 := TFontHandle.Create;
    FLargeFont180.Angle := 1800;

    FLargeFont270 := TFontHandle.Create;
    FLargeFont270.Angle := 2700;


    //SmallTextName := 'Arial';
    //LargeTextName := 'Arial';

    SmallTextBold := True;
    LargeTextBold := True;

    FLineWidth := 2;
    FBodyColor := $00217F;// clNavy;
    FPinColor := $007F28;// clOlive;
    FSelectionColor := clRed;
end;

destructor TvePainter.Destroy;
begin
    FBodyLines.Free;
    FBodyCircles.Free;
    FPinLines.Free;

    FBodyText.Free;
    FSmallText.Free;
    FLargeText.Free;

    Font0.Free;
    Font90.Free;
    Font180.Free;
    Font270.Free;

    FLargeFont0.Free;
    FLargeFont90.Free;
    FLargeFont180.Free;
    FLargeFont270.Free;

    inherited;
end;

end.
