unit GcodeTop;

interface

uses Classes, SysUtils, Types, Contnrs, Project, Painter, Outlines;

// **************************************************
//          CLASS FOR DRAWING SETTINGS
// **************************************************

{ This class presents a set of properties for settings which affect how
a G-Code file is created. The settings are read from a text format
configuration file. By editing the config. file the user can alter G-Code
to suit their own milling machine and technique.
}

type TgctConfiguration = class
protected
    FHeader : TStringList;
    FStartLine : TStringList;
    FLineTo : TStringList;
    FEndLine : TStringList;
    FFooter : TStringList;
    FCellSpacing_mm : Currency;
    FCutLength_mm : Currency;
    FBoardZeroX_mm : Currency;
    FBoardZeroY_mm : Currency;
    FRotate90 : boolean;

    FShowLinks : boolean;
    FShowCustom : boolean;
    FShowCelled : boolean;
    FShowLeaded : boolean;
    FShowRadial : boolean;

    FormatSettings : TFormatSettings;

    function GetHeader : TStrings;
    function GetStartLine : TStrings;
    function GetLineTo : TStrings;
    function GetEndLine : TStrings;
    function GetFooter : TStrings;

    procedure ProcessConfigLine(const Line : string);
public
    // canned G-Code segments
    property Header : TStrings read GetHeader;
    property StartLine : TStrings read GetStartLine;
    property LineTo : TStrings read GetLineTo;
    property EndLine : TStrings read GetEndLine;
    property Footer : TStrings read GetFooter;

    // configuration items
    property CellSpacing_mm : Currency read FCellSpacing_mm;
    property BoardZeroX_mm : Currency read FBoardZeroX_mm;
    property BoardZeroY_mm : Currency read FBoardZeroY_mm;
    property Rotate90 : boolean read FRotate90;

    property ShowLinks : boolean read FShowLinks;
    property ShowCustom : boolean read FShowCustom;
    property ShowCelled : boolean read FShowCelled;
    property ShowLeaded : boolean read FShowLeaded;
    property ShowRadial : boolean read FShowRadial;

    procedure LoadFromFile( const Filename : string );
    constructor Create;
    destructor Destroy; override;
end;

// *******************************************************
//     CLASSES HOLD SHAPES - LINES, POLYLINES, CIRCLES
// *******************************************************
type TgctShape = class
protected
  function GetCentre : TPoint; virtual; abstract;
  function GetTop : TPoint; virtual; abstract;
public
  property Centre : TPoint read GetCentre;
  property Top : TPoint read GetTop;
end;

TgctPolyLine = class( TgctShape )
protected
  FPoints : array of TPoint;
  FCount : integer;
  function GetPoint( index : integer ) : TPoint;
  function GetCentre : TPoint; override;
  function GetTop : TPoint; override;
public
  property Count : integer read FCount;
  property Points[index : integer] : TPoint read GetPoint; default;
  procedure AddPoint( APoint : TPoint );
  constructor Create;
  destructor Destroy; override;
end;

TgctArc = class( TgctShape )
  FX1, FY1, FX2, FY2, FX3, FY3, FX4, FY4 : integer;
  function GetCentre : TPoint; override;
  function GetTop : TPoint; override;
public
  procedure SetArc( X1, Y1, X2, Y2, X3, Y3, X4, Y4 : integer );
  constructor Create;
  destructor Destroy; override;
end;

type TgctDrawPins = (dpHidePins, dpShowPins);

type TgctShapes = class
protected
    FPainter : TvePainter;
    FShapes : TObjectList;
    function GetCount : integer;
    function GetShape( i : integer ) : TgctShape;
public
    property Count : integer read GetCount;
    property Shapes[i : integer] : TgctShape read GetShape; default;
    procedure Load( AProject : TveProject; PixelsPerCell : integer;
        OutlineClass : TClass; ShowPins : TgctDrawPins );
    procedure SortByXThenY;
    constructor Create;
    destructor Destroy; override;
end;


// **************************************************
//     PROCEDURE GENERATES G-CODE INTO TSTRINGS
// **************************************************

// Write G-Code describing track cuts to a TStrings
procedure MakeTopGCode( Strings : TStrings; Project : TveProject );

implementation

uses ExceptSafe, Math, OtherOutlines, SizeableOutlines, CustomOutlines, 
  CelledOutlines, RadialOutlines, ArcLine;

// ********************************************************
//              CLASS FOR GCODE TOP SETTINGS
// ********************************************************

type ESafeGCodeTopConfig = class( ESafe );

procedure ParseNameValue( var Name, Value : string; const Input : string );
var
    EqualPos : integer;
begin
    EqualPos := Pos( '=', Input );
    if EqualPos = 0 then begin
        raise ESafeGCodeTopConfig.CreateFmt( 'No "=" on config file line: %s.', [Input] );
    end;
    Name := UpperCase(Copy( Input, 1, EqualPos -1 ));
    Value := UpperCase(Copy( Input, EqualPos +1, 255 ));
end;


constructor TgctConfiguration.Create;
begin
    FHeader := TStringList.Create;
    FStartLine := TStringList.Create;
    FLineTo := TStringList.Create;
    FEndLine := TStringList.Create;
    FFooter := TStringList.Create;

    // StrToCurr needs a TFormatSettings with '.' decimal separator
    // get USA number formats    2.87  123,000,000
{$IFDEF VER200}
    GetLocaleFormatSettings(1036, FormatSettings);
{$ELSE}
    FormatSettings := TFormatSettings.Create(1036);
{$ENDIF}
    // plug in the decimal separator just in case
    FormatSettings.DecimalSeparator := '.';
end;

destructor TgctConfiguration.Destroy;
begin
    FHeader.Free;
    FStartLine.Free;
    FLineTo.Free;
    FEndLine.Free;
    FFooter.Free;
    inherited;
end;

function TgctConfiguration.GetHeader : TStrings;
begin
    result := FHeader;
end;

function TgctConfiguration.GetStartLine : TStrings;
begin
    result := FStartLine;
end;

function TgctConfiguration.GetLineTo : TStrings;
begin
    result := FLineTo;
end;

function TgctConfiguration.GetEndLine : TStrings;
begin
    result := FEndLine;
end;

function TgctConfiguration.GetFooter : TStrings;
begin
    result := FFooter;
end;

// handle a configuration line of form 'Name=Value'
procedure TgctConfiguration.ProcessConfigLine(const Line : string);

    // convert string to currency with safe exception
    function ConvertNumber( const S : string ) : Currency;
    begin
        try
            Result := StrToCurr( S, FormatSettings );
        except
            On EConvertError do begin
                raise ESafeGCodeTopConfig.CreateFmt(
                    'Invalid decimal number in config file: %s', [S] );
            end;
        end;
    end;

var
    Name, Value : string;
begin
    // line is trimmed already
    ParseNameValue( Name, Value, Line );

    if Name = 'HOLEGRID' then begin
        FCellSpacing_mm := ConvertNumber( Value )
    end
    else if Name = 'TOOLZEROX' then begin
         FBoardZeroX_mm := ConvertNumber( Value )
    end
    else if Name = 'TOOLZEROY' then begin
         FBoardZeroY_mm := ConvertNumber( Value )
    end
    else if Name = 'SHOWLINKS' then begin
         FShowLinks := Uppercase(Trim(Value)) = 'TRUE'
    end
    else if Name = 'SHOWCUSTOM' then begin
         FShowCustom := Uppercase(Trim(Value)) = 'TRUE'
    end
    else if Name = 'SHOWCELLED' then begin
         FShowCelled := Uppercase(Trim(Value)) = 'TRUE'
    end
    else if Name = 'SHOWLEADED' then begin
         FShowLeaded := Uppercase(Trim(Value)) = 'TRUE'
    end
    else if Name = 'SHOWRADIAL' then begin
         FShowRadial := Uppercase(Trim(Value)) = 'TRUE'
    end
    else if Name = 'ROTATE90' then begin
         FRotate90 := Uppercase(Trim(Value)) = 'TRUE'
    end
    else begin
        raise ESafeGCodeTopConfig.CreateFmt(
            'Unknown Name in config file line: %s.', [Line] );
    end;
end;

procedure TgctConfiguration.LoadFromFile( const Filename : string );
var
    Lines : TStringList;
    LineIndex : integer;
    Limit : integer;
    Line : string;

    // read the lines from a [Section] of a config file
    procedure ReadSection( Destination : TStrings );
    begin
        // skip [Header]
        Inc( LineIndex );

        // process lines
        while LineIndex < Limit do begin
            Line := Trim(Lines[LineIndex]);
            if Pos( '[', Line ) = 1 then begin
                break;
            end;
            // non-blank, non-comment lines
            if (Line <> '') then begin
                Destination.Add( Line );
            end;
            Inc( LineIndex );
        end;
    end;

begin
    if not FileExists( Filename ) then begin
        raise ESafeGCodeTopConfig.CreateFmt( 'Missing file: %s.', [Filename] );
    end;

    lines := TStringList.Create;
    try
        { Gcode uses EIA format, which is identical to 7 bit ISO/ASCII, except that
        some ISO/ASCII codes are not defined. :#$'*;<=>? @ " are not defined.
        So, always use 7 bit ASCII encoding. }
        lines.LoadFromFile( Filename, TEncoding.ASCII );

        // sections are in square brackets
        LineIndex := 0;
        Limit := Lines.Count;
        while LineIndex < Limit do begin

             Line := Trim(Lines[LineIndex]);

            // comment line
            if Pos( ';', Line ) = 1  then begin

            end

            else if Pos(Line, '[Header]') = 1 then begin
                ReadSection( FHeader );
            end
            else if Pos(Line, '[StartLine]') = 1 then begin
                ReadSection( FStartLine );
            end
            else if Pos(Line, '[LineTo]') = 1 then begin
                ReadSection( FLineTo );
            end
            else if Pos(Line, '[EndLine]') = 1 then begin
                ReadSection( FEndLine );
            end
            else if Pos(Line, '[Footer]') = 1 then begin
                ReadSection( FFooter );
            end
            else if Pos(Line, '[Config]') = 1 then begin

                  // skip [Header]
                  Inc( LineIndex );

                  while LineIndex < Limit do begin
                      Line := Trim(Lines[LineIndex]);
                      if Pos( '[', Line ) = 1 then begin
                          break;
                      end;
                      if Pos( ';', Line ) <> 1  then begin
                          ProcessConfigLine( Line );
                      end;
                      Inc( LineIndex );
                  end;
            end
            else begin
                Inc( LineIndex )
            end;
        end;
    finally
        lines.Free;
    end;
end;

// *******************************************************
//     CLASSES HOLD SHAPES - POLYLINES, CIRCLES
// *******************************************************

function TgctPolyLine.GetPoint( index : integer ) : TPoint;
begin
  result := FPoints[index];
end;


function TgctPolyLine.GetCentre : TPoint;
var
  LeftX, TopY, RightX, BottomY : integer;
  APoint : TPoint;
  i : integer;
begin
  // sent limits to full scale
  //.. NB Y increases going down - ordinary DC coords
  LeftX := High(LeftX);
  TopY := High(TopY);
  RightX := Low(RightX);
  BottomY := Low(BottomY);

  // pull limits to extents of shape
  for i := 0 to FCount -1 do begin
    APoint := FPoints[i];
    LeftX := Min(LeftX, APoint.X);
    TopY := Min(TopY, APoint.Y);
    RightX := Max(RightX, APoint.X);
    BottomY := Max(BottomY, APoint.Y)
  end;

  // calculate centre
  result.X := (RightX + LeftX) div 2;
  result.Y := (TopY + BottomY) div 2;
end;

function TgctPolyLine.GetTop : TPoint;
begin
  result.X := 0;
  result.Y := 0;
end;

procedure TgctPolyLine.AddPoint( APoint : TPoint );
begin
  if FCount <= Length(FPoints) then begin
    SetLength(FPoints, FCount + 10);
  end;
  Inc(FCount);
  FPoints[FCount -1] := APoint;
end;

constructor TgctPolyLine.Create;
begin

end;

destructor TgctPolyLine.Destroy;
begin
  inherited;
end;

// ***********************

function TgctArc.GetCentre : TPoint;
begin
  result.X := (FX1 + FX2) div 2;
  result.Y := (FY1 + FY2) div 2;
end;

function TgctArc.GetTop : TPoint;
begin
  result.X := (FX1 + FX2) div 2;
  result.Y := Min(FY1, FY2);
end;

procedure TgctArc.SetArc( X1, Y1, X2, Y2, X3, Y3, X4, Y4 : integer );
begin
  FX1 := X1;
  FY1 := Y1;
  FX2 := X2;
  FY2 := Y2;
  FX3 := X3;
  FY3 := Y3;
  FX4 := X4;
  FY4 := Y3;
end;

constructor TgctArc.Create;
begin

end;

destructor TgctArc.Destroy;
begin
  inherited;
end;

// *******************************************************
//           SHAPES CLASS HOLDS SHAPES TO DRAW
// *******************************************************

function TgctShapes.GetCount : integer;
begin
  result := FShapes.Count;
end;

function TgctShapes.GetShape( i : integer ) : TgctShape;
begin
  result := TgctShape(FShapes[i])
end;

procedure TgctShapes.Load( AProject : TveProject; PixelsPerCell : integer;
        OutlineClass : TClass; ShowPins : TgctDrawPins );
var
  Item : TveBoardItem;
  Count : integer;
  Points : PPointList;
  i : integer;
  PolyLine : TgctPolyLine;
  Circle : TCircleRec;
  Arc : TgctArc;
begin
  FPainter.Clear;

  // set drawing resolution
  FPainter.PixelsPerCell := PixelsPerCell;

  // get items to draw links and/or components into FPainter as lines, arcs
  for i := 0 to AProject.BoardItemCount -1 do begin

    Item := AProject.BoardItems[i];
    if Item.Outline is OutlineClass then begin
      // get outline to add to FPainter.BodyLines, PinLines, BodyCircles
      Item.Outline.Paint( Item, FPainter );
    end;
  end;

  // get body (component) lines out of FPainter into FShapes TObjectList
  FPainter.BodyLines.Rewind;
  //.. for each polyline
  while FPainter.BodyLines.GetNext(Count, Points) do begin

      PolyLine := TgctPolyLine.Create;
      FShapes.Add( PolyLine );
      //.. transfer the points
      for i := 0 to Count - 1 do begin
        PolyLine.AddPoint( Points^[i] );
      end;
  end;

  // get pin lines out of FPainter into FShapes TObjectList
  if ShowPins = dpShowPins then begin
  
      FPainter.PinLines.Rewind;
      //.. for each polyline
      while FPainter.PinLines.GetNext(Count, Points) do begin

          PolyLine := TgctPolyLine.Create;
          FShapes.Add( PolyLine );
          //.. transfer the points
          for i := 0 to Count - 1 do begin
            PolyLine.AddPoint( Points^[i] );
          end;
      end;
  end;

  // get body (component) circles, arcs out of FPainter into FShapes TObjectList
  for i := 0 to FPainter.BodyCircles.Count -1 do begin

      Circle := FPainter.BodyCircles[i];
      Arc := TgctArc.Create;
      FShapes.Add( Arc );
      //.. transfer the data for the arc
      Arc.FX1 := Circle.X1;
      Arc.FY1 := Circle.Y1;
      Arc.FX2 := Circle.X2;
      Arc.FY2 := Circle.Y2;
      Arc.FX3 := Circle.X3;
      Arc.FY3 := Circle.Y3;
      Arc.FX4 := Circle.X4;
      Arc.FY4 := Circle.Y4;
  end;
end;

constructor TgctShapes.Create;
begin
  FShapes := TObjectList.Create;
  FPainter := TvePainter.Create;
  FPainter.TextDisplay := tdNone;   // no text
  FPainter.Border := 0;             // not really used
  FPainter.Gap := 1;                // arcane tweak for outlines drawing
  FPainter.LeadStyle := lsLine;     // not lsHollow
end;

destructor TgctShapes.Destroy;
begin
  FPainter.Free;
  FShapes.Free;
  inherited;
end;

// compare two TgcShapes for sorting in order of X, then Y
function CompareShapesXThenY( P1, P2 : pointer ) : integer;
var
  Centre1, Centre2 : TPoint;
begin
  Centre1 := TgctShape( P1 ).Centre;
  Centre2 := TgctShape( P2 ).Centre;

    if Centre1.X > Centre2.X then begin
        result := 1;
    end
    else if Centre1.X < Centre2.X  then begin
        result := -1
    end
    // Xmmthou are equal at this point
    else if Centre1.Y > Centre2.Y then begin
        result := 1;
    end
    else if Centre1.Y < Centre2.Y then begin
        result := -1;
    end
    else begin
        result := 0;
    end;
end;

procedure TgctShapes.SortByXThenY;
begin
  FShapes.Sort( CompareShapesXThenY );
end;

// *******************************************************
//        CLASS GENERATES BOARD TOP LAYER GCODE
// *******************************************************

const PIXELSPERCELL = 100;  // outlines will paint at this resolution
type MMPoint = record
  X : currency;
  Y : currency;
end;

procedure MakeTopGCode( Strings : TStrings; Project : TveProject );
var
    Config : TgctConfiguration;
    CurrencyFormat : TFormatSettings;
    ArcLine : TArcLines;

    // take location in Pixels and convert to mm relative to
    // bottom left hole on board viewed from top and converted to mm
    // Also adjust when board is rotated

    function Translate( Pixels : TPoint ) : MMPoint;
    var
      Xmm, Ymm : extended;
      Xpix, Ypix : integer;

    begin
      // adjust from components drawing relative to (0,0) pixels to
      // plotter reference hole at (0.5, 0.5) pixels
      XPix := Pixels.X - (PIXELSPERCELL div 2);
      YPix := Pixels.Y - (PIXELSPERCELL div 2);

      // adjust for reversed Y coord in computer, versus plotter: Y = -Y
      Ypix := - YPix;

      // convert from pixels to millimetres
      Xmm := XPix * Config.CellSpacing_mm / PIXELSPERCELL;
      Ymm := YPix * Config.CellSpacing_mm / PIXELSPERCELL;

      // Adjust for where user placed tool zero relative to top left hole
      Xmm := Xmm - Config.BoardZeroX_mm;
      Ymm := Ymm - Config.BoardZeroX_mm;

     // adjust for rotation by 90 degrees
      if Config.Rotate90 then begin
          result.X := - Ymm;
          result.Y := Xmm;
      end
      // or rotation by zero degrees
      else begin
          result.X := Xmm;
          result.Y := Ymm;
      end;
    end;

    // get pen in position at first point in line or polyline
    procedure StartLine( Point : TPoint );
    var
      i : integer;
      Line : string;
      Pointmm : MMPoint;
      Xmm, Ymm : string;
    begin
        Pointmm := Translate(Point);
        Xmm:= CurrToStr( Pointmm.X, CurrencyFormat );
        Ymm:= CurrToStr( Pointmm.Y, CurrencyFormat );
        for i := 0 to Config.StartLine.Count -1 do begin
          Line := Config.StartLine[i];
          Line := StringReplace( Line, '%X', Xmm, [rfReplaceAll, rfIgnoreCase] );
          Line := StringReplace( Line, '%Y', Ymm, [rfReplaceAll, rfIgnoreCase] );
          Strings.Add( Line );
        end;
    end;

    procedure LineTo( Point : TPoint );
    var
      i : integer;
      Line : string;
      Pointmm : MMPoint;
      Xmm, Ymm : string;
    begin
        PointMM := Translate(Point);
        Xmm:= CurrToStr( Pointmm.X, CurrencyFormat );
        Ymm:= CurrToStr( Pointmm.Y, CurrencyFormat );
        for i := 0 to Config.LineTo.Count -1 do begin
          Line := Config.LineTo[i];
          Line := StringReplace( Line, '%X', Xmm, [rfReplaceAll, rfIgnoreCase] );
          Line := StringReplace( Line, '%Y', Ymm, [rfReplaceAll, rfIgnoreCase] );
          Strings.Add( Line );
        end;
    end;

    procedure EndLine;
    var
      i : integer;
    begin
        for i := 0 to Config.EndLine.Count -1 do begin
            Strings.Add( Config.EndLine[i] );
        end;
    end;

    procedure EmitPolyLine( PolyLine : TgctPolyLine );
    var
      SegIndex : integer;
    begin
        // get pen in position at first point in polyline
        StartLine( PolyLine[0] );

        // draw segments
        for SegIndex := 1 to PolyLine.Count - 1 do begin
          LineTo( PolyLine[SegIndex] );
        end;

        // final line back to start point
        //.. no need to close the figure if only a single line
        if PolyLine.Count > 2 then begin
          LineTo( PolyLine[0] );
        end;

        // get pen up
        EndLine;
    end;

    procedure EmitArc( Arc : TgctArc );
    var
      j : integer;
    begin
      ArcLine.SetArc(
        Arc.FX1, Arc.FY1,
        Arc.FX2, Arc.FY2,
        Arc.FX3, Arc.FY3,
        Arc.FX4, Arc.FY4
      );

      // get pen in position at first point in polyline
      StartLine( ArcLine.PointsInteger[0] );

      // line to next point
      for j := 1 to ArcLine.Count -1 do begin
        LineTo( ArcLine.PointsInteger[j] );
      end;

      // get pen up
      EndLine;
    end;
var
    Shapes : TgctShapes;
    FileName : string;
    i : integer;
    Shape : TgctShape;
begin
    // clear out lines
    Strings.Clear;

    // how currency will be printed
    CurrencyFormat.NegCurrFormat := 2;
    CurrencyFormat.ThousandSeparator := ',';
    CurrencyFormat.DecimalSeparator := '.';
    CurrencyFormat.CurrencyDecimals := 4;
    CurrencyFormat.CurrencyString := '';

    // path to config file
    FileName := ExtractFilePath( ParamStr(0)) + 'G-CodeTopConfig.txt';

    Shapes := nil;
    ArcLine := nil;
    Config := TgctConfiguration.Create;

    try
      Config.LoadFromFile(FileName);
      Shapes := TgctShapes.Create;
      ArcLine := TArcLines.Create;
      ArcLine.Segments := 24;

      // draw components into TgctShapes                        
      if Config.ShowLinks then begin
          Shapes.Load( Project, PIXELSPERCELL, TveLinkOutline, dpShowPins );
      end;
      if Config.ShowCustom then begin
          Shapes.Load( Project, PIXELSPERCELL, TveCustomOutline, dpHidePins );
      end;
      if Config.ShowCelled then begin
          Shapes.Load( Project, PIXELSPERCELL, TveCellOutline, dpHidePins );
      end;
      if Config.ShowLeaded then begin
          Shapes.Load( Project, PIXELSPERCELL, TveLeadedOutline, dpShowPins );
      end;
      if Config.ShowRadial then begin
          Shapes.Load( Project, PIXELSPERCELL, TveRadialOutline, dpShowPins );
      end;

      // so plotter does not jump all over the board, but progresses to
      // adjacent lines and shapes
      Shapes.SortByXThenY;

      // output Gcode header
      Strings.AddStrings( Config.Header );
{
      for i := 0 to Config.Header.Count - 1 do begin
          Strings.Add( Config.Header[i]);
      end;
}
      // output G-Code for shapes
      // ...sort cuts by X then Y
      for i := 0 to Shapes.Count - 1 do begin
          Shape := Shapes[i];
          if Shape is TgctPolyLine then begin
            EmitPolyLine( TgctPolyLine(Shape) );
          end
          else if Shape is TgctArc then begin
            EmitArc( TgctArc(Shape)) ;
          end
          // we shouldn't get here!
          else begin
            raise Exception.Create( 'Internal error unknown shape' );
          end;
      end;

      // output footer
      Strings.AddStrings( Config.Footer );
{
      for i := 0 to Config.Footer.Count - 1 do begin
          Strings.Add( Config.Footer[i]);
      end;
}
    finally
      Config.Free;
      Shapes.Free;
      ArcLine.Free;
    end;
end;






end.
