unit Gcode;

interface

uses Project, Classes, Contnrs, Tracks, Outlines, Board, SysUtils;


// **************************************************
//          CLASS FOR TRACK CUT SETTINGS
// **************************************************

{ This class presents a set of properties for settings which affect how
a G-Code file is created. The settings are read from a text format
configuration file. By editing the config. file the user can alter G-Code
to suit their own milling machine and technique.
}

type TgcConfiguration = class
protected
    FHeader : TStringList;
    FStartCut : TStringList;
    FCutTo : TStringList;
    FEndCut : TStringList;
    FFooter : TStringList;
    FCellSpacing_mm : Currency;
    FCutLength_mm : Currency;
    FJoinCuts : boolean;
    FBoardZeroX_mm : Currency;
    FBoardZeroY_mm : Currency;
    FRotate90 : boolean;
    FormatSettings : TFormatSettings;
    function GetHeader : TStrings;
    function GetStartCut : TStrings;
    function GetCutTo : TStrings;
    function GetEndCut : TStrings;
    function GetFooter : TStrings;
    procedure ProcessConfigLine(const Line : string);
public
    // canned G-Code segments
    property Header : TStrings read GetHeader;
    property StartCut : TStrings read GetStartCut;
    property CutTo : TStrings read GetCutTo;
    property EndCut : TStrings read GetEndCut;
    property Footer : TStrings read GetFooter;

    // configuration items
    property CellSpacing_mm : Currency read FCellSpacing_mm;
    property CutLength_mm : Currency read FCutLength_mm;
    property JoinCuts : boolean read FJoinCuts;
    property BoardZeroX_mm : Currency read FBoardZeroX_mm;
    property BoardZeroY_mm : Currency read FBoardZeroY_mm;
    property Rotate90 : boolean read FRotate90;


    procedure LoadFromFile( const Filename : string );
    constructor Create;
    destructor Destroy; override;
end;

// **************************************************
//      GENERATE LIST OF TRACK CUTS FROM PROJECT
// **************************************************

{ Class provides a list of cuts contained in a TveProject. The cuts
can be sorted and in-line cuts can be combined into a single cut
}

// we use a Cross "X" cut where strips meet at right angles,
// otherwise a simple vertical or horizontal cut will suffice
type TgcCutType = ( tcVertical, tcHorizontal, tcCross );

type TgcCut = class
    X : Currency;
    Y : Currency;
    // cuts grow in direction of less x, or less y in 1 cell increments
    Length : integer;
    CutType : TgcCutType;
end;

type TgcTrackCuts = class
protected
    Project : TveProject;
    Board : TbrBoard;
    FCuts : TObjectList;
    function GetCount : integer;
    function GetCut( i : integer ) : TgcCut;
    procedure AddBreak( Item : TveBoardItem );
public
    property Count : integer read GetCount;
    property Cuts[i : integer] : TgcCut read GetCut; default;
    procedure LoadFromProject( AProject : TveProject );
    procedure SortByXThenY;
    procedure JoinCuts;
    constructor Create;
    destructor Destroy; override;
end;

// **************************************************
//     PROCEDURE GENERATES G-CODE INTO TSTRINGS
// **************************************************

// Write G-Code describing track cuts to a TStrings
procedure MakeCutTracksGcode( Strings : TStrings; Project : TveProject );


implementation

uses Windows, OtherOutlines, Intersect, ExceptSafe;

// **************************************************
//        CLASS SUPPLIES TRACK CUT SETTINGS
// **************************************************

type ESafeGCodeConfig = class( ESafe );

procedure ParseNameValue( var Name, Value : string; const Input : string );
var
    EqualPos : integer;
begin
    EqualPos := Pos( '=', Input );
    if EqualPos = 0 then begin
        raise ESafeGCodeConfig.CreateFmt( 'No "=" on config file line: %s.', [Input] );
    end;
    Name := UpperCase(Copy( Input, 1, EqualPos -1 ));
    Value := UpperCase(Copy( Input, EqualPos +1, 255 ));
end;


constructor TgcConfiguration.Create;
begin
    FHeader := TStringList.Create;
    FStartCut := TStringList.Create;
    FCutTo := TStringList.Create;
    FEndCut := TStringList.Create;
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

destructor TgcConfiguration.Destroy;
begin
    FHeader.Free;
    FStartCut.Free;
    FCutTo.Free;
    FEndCut.Free;
    FFooter.Free;
    inherited;
end;

function TgcConfiguration.GetHeader : TStrings;
begin
    result := FHeader;
end;

function TgcConfiguration.GetStartCut : TStrings;
begin
    result := FStartCut;
end;

function TgcConfiguration.GetCutTo : TStrings;
begin
    result := FCutTo;
end;

function TgcConfiguration.GetEndCut : TStrings;
begin
    result := FEndCut;
end;

function TgcConfiguration.GetFooter : TStrings;
begin
    result := FFooter;
end;


// handle a configuration line of form 'Name=Value'
procedure TgcConfiguration.ProcessConfigLine(const Line : string);

    // convert string to currency with safe exception
    function ConvertNumber( const S : string ) : Currency;
    begin
        try
            Result := StrToCurr( S, FormatSettings );
        except
            On EConvertError do begin
                raise ESafeGCodeConfig.CreateFmt(
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
    else if Name = 'CUTDISTANCE' then begin
         FCutLength_mm := ConvertNumber( Value )
    end
    else if Name = 'JOINCUTS' then begin
         FJoinCuts := Uppercase(Trim(Value)) = 'TRUE'
    end
    else if Name = 'TOOLZEROX' then begin
         FBoardZeroX_mm := ConvertNumber( Value )
    end
    else if Name = 'TOOLZEROY' then begin
         FBoardZeroY_mm := ConvertNumber( Value )
    end
    else if Name = 'ROTATE90' then begin
         FRotate90 := Uppercase(Trim(Value)) = 'TRUE'
    end
    else begin
        raise ESafeGCodeConfig.CreateFmt(
            'Unknown Name in config file line: %s.', [Line] );
    end;
end;


procedure TgcConfiguration.LoadFromFile( const Filename : string );
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
        raise ESafeGCodeConfig.CreateFmt( 'Missing file: %s.', [Filename] );
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
            else if Pos(Line, '[StartCut]') = 1 then begin
                ReadSection( FStartCut );
            end
            else if Pos(Line, '[CutTo]') = 1 then begin
                ReadSection( FCutTo );
            end
            else if Pos(Line, '[EndCut]') = 1 then begin
                ReadSection( FEndCut );
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

// *******************************************
//      Comparison Functions for Sorting
// *******************************************

// compare two TgcCuts in order of X, then Y

function CompareCutsXThenY( P1, P2 : pointer ) : integer;
begin
    if TgcCut(P1).X > TgcCut(P2).X then begin
        result := 1;
    end
    else if TgcCut(P1).X < TgcCut(P2).X  then begin
        result := -1
    end
    // Xmmthou are equal at this point
    else if TgcCut(P1).Y > TgcCut(P2).Y then begin
        result := 1;
    end
    else if TgcCut(P1).Y < TgcCut(P2).Y then begin
        result := -1;
    end
    else begin
        result := 0;
    end;
end;

// compare two TgcCuts in order of Y, then X

function CompareCutsYThenX( P1, P2 : pointer ) : integer;
begin
    if TgcCut(P1).Y > TgcCut(P2).Y then begin
        result := 1;
    end
    else if TgcCut(P1).Y < TgcCut(P2).Y then begin
        result := -1;
    end
    // Ymmthou are equal at this point
    else if TgcCut(P1).X > TgcCut(P2).X then begin
        result := 1;
    end
    else if TgcCut(P1).X < TgcCut(P2).X  then begin
        result := -1
    end
    else begin
        result := 0;
    end;
end;


// **************************************************
//      TgcTrackCuts CLASS PROVIDES A LIST OF CUTS
// **************************************************

function TgcTrackCuts.GetCount : integer;
begin
    result := FCuts.Count;
end;

function TgcTrackCuts.GetCut( i : integer ) : TgcCut;
begin
    result := TgcCut( FCuts[i] );
end;

procedure TgcTrackCuts.LoadFromProject( AProject : TveProject );
var
    i : integer;
    item : TveBoardItem;
begin
    // local references
    AProject := AProject;
    Board := AProject.Board;

    // We search the TbrBoard object which has the property Strips[], which is
    // an array of TbrStrip objects. TbrStrip has a direction property. A break
    // is on a strip if we have:
    // * horizonal strip with break y = strip y
    // * vertical strip with break x = strip x

    // create list of track cuts in Cuts[]
    // ...for every item on board
    for i := 0 to AProject.BoardItemCount - 1 do begin
        Item := AProject.BoardItems[i];
        // if item is a break
        if Item.Outline is TveBreakOutline then begin
            // process our break
            AddBreak( Item );
        end;
    end;
end;


procedure TgcTrackCuts.AddBreak( Item : TveBoardItem );
var
    Cut : TgcCut;
    CutType : TgcCutType;
    HorizStrip, VertStrip : boolean;
    i : integer;
    Strip : TbrStrip;
    Start, Finish, BreakCentre : TFloatPoint;

begin
    // see if horizontal, vertical or horiz+vert strips are under our cut
    BreakCentre.x := Item.X;
    BreakCentre.y := Item.Y;

    // break can be shifted to right or down
    if Item.Shift = shRight then begin
        BreakCentre.x := BreakCentre.x + 0.5;
    end
    else if Item.Shift = shDown then begin
        BreakCentre.y := BreakCentre.y + 0.5;
    end;


    // see if vert and/or horiz strips are cut by the break
    HorizStrip := False;
    VertStrip := False;
    for i := 0 to Board.StripCount - 1 do begin
        Strip := Board.Strips[i];

        Start.x := Strip.Start.X;
        Start.y := Strip.Start.Y;
        Finish.x := Strip.Finish.X;
        Finish.y := Strip.Finish.Y;

        // if centre of break is on centre line our strip, then break cuts strip
        //..(0.1 handles float uncertainty)
        if LinePointDist(Start, Finish, BreakCentre) < 0.1 then begin
            // record horizontal or vertical aspect of strips under our break
            HorizStrip := HorizStrip or (Strip.Direction = diHorizontal);
            VertStrip := VertStrip or (Strip.Direction = diVertical);
        end;
    end;

    // at this point we know what kinds of strips lie under our break


    // ..cut must divide the strip completely
    if HorizStrip and VertStrip then begin
        CutType := tcCross;
    end
    else if HorizStrip then begin
        CutType := tcVertical;
    end
    else if VertStrip then begin
        CutType := tcHorizontal;
    end
    // else no tracks under this break - we ignore this break symbol
    else begin
        exit;
    end;

    // create our cut and set its properties
    Cut := TgcCut.Create;
    FCuts.Add( Cut );
    Cut.CutType := CutType;

    // record centre of cut
    Cut.X := BreakCentre.x;
    Cut.y := BreakCentre.y;

    // all cuts are of length 1 at this stage.
    // We may join cuts later for to produce longer cuts
    Cut.Length := 1;
end;

procedure TgcTrackCuts.SortByXThenY;
begin
    // sort cuts by x then by y
    FCuts.Sort( CompareCutsXThenY);
end;


procedure TgcTrackCuts.JoinCuts;
var
    i : integer;
    Cut1 : TgcCut;
    Cut2 : TgcCut;

begin
    // sort cuts by x then by y
    // x and y in ascending order as we go from index 0 higher
    FCuts.Sort( CompareCutsXThenY);

    // find vertically aligned cuts that are next to each other, and combine them
    // Since we go downward in the loop, the x and y values decrease
    for i:= FCuts.Count - 1 downto 1 do begin

        // get cuts
        Cut1 := TgcCut(FCuts[i]);     // higher X and Y
        Cut2 := TgcCut(FCuts[i-1]);   // than this cut

        // if vertically aligned and one above the other
        if  (Cut1.CutType = tcVertical) and (Cut2.CutType = tcVertical) and
            (Cut1.X = Cut2.X) and ((Cut1.Y - Cut1.Length) = Cut2.Y) then begin
            // combine the cuts
            Cut2.X := Cut1.X;
            Cut2.Y := Cut1.Y;
            Cut2.Length := Cut1.Length + Cut2.Length;
            FCuts.Delete( i );
        end
    end;

    // sort cuts by y then by x
    // x and y in ascending order as we go from index 0 higher
    FCuts.Sort( CompareCutsYThenX);

    // find horizontally aligned cuts that are adjacent, and combine them
    // Since we go downward in the loop, the x an y values decrease
    for i := FCuts.Count -1 downto 1 do begin

        // get cuts
        Cut1 := TgcCut(FCuts[i]);     // higher X and Y
        Cut2 := TgcCut(FCuts[i-1]);   // than this cut

        // if horizontally aligned and one beside the other
        if  (Cut1.CutType = tcHorizontal) and (Cut2.CutType = tcHorizontal) and
            (Cut1.Y = Cut2.Y) and ((Cut1.X - Cut1.Length) = Cut2.X) then begin
            // combine the cuts
            Cut2.X := Cut1.X;
            Cut2.Y := Cut1.Y;
            Cut2.Length := Cut1.Length + Cut2.Length;
            FCuts.Delete( i );
        end
    end;
end;

constructor TgcTrackCuts.Create;
begin
    FCuts := TObjectList.Create;
    // stop tiny reallocs
    FCuts.Capacity := 500;
end;

destructor TgcTrackCuts.Destroy;
begin
    FCuts.Free;
    inherited;
end;

// *******************************************
//  FUNCTION CREATES G-CODE FOR TRACK BREAKS
// *******************************************

procedure MakeCutTracksGcode( Strings : TStrings; Project : TveProject );
var
    Config : TgcConfiguration;
    Cuts : TgcTrackCuts;
    CurrencyFormat : TFormatSettings;

    // offset of zero point and rotation added here in this function
    procedure DoEmitCut( StartX, StartY, EndX, EndY : Currency );
    var
        i : integer;
        Line : string;
        StartRotX, StartRotY, EndRotX, EndRotY : currency;
        StartXS, StartYS, EndXS, EndYS : string;
    begin
        // adjust for where user placed tool zero relative to bottom left hole
        // when copper side is up.
        StartX := StartX - Config.BoardZeroX_mm;
        StartY := StartY - Config.BoardZeroY_mm;
        EndX := EndX - Config.BoardZeroX_mm;
        EndY := EndY - Config.BoardZeroY_mm;

        // adjust for rotation by 90 degrees
        if Config.Rotate90 then begin
            StartRotX := -StartY;
            StartRotY := StartX;
            EndRotX := -EndY;
            EndRotY := EndX;
        end
        // or rotation by zero degrees
        else begin
            StartRotX := StartX;
            StartRotY := StartY;
            EndRotX := EndX;
            EndRotY := EndY;
        end;

        // convert numeric values to strings
        StartXS := CurrToStr( StartRotX, CurrencyFormat );
        StartYS := CurrToStr( StartRotY, CurrencyFormat );
        EndXS := CurrToStr( EndRotX, CurrencyFormat );
        EndYS := CurrToStr( EndRotY, CurrencyFormat );

        // start of cut - StartX, StartY
        for i := 0 to Config.StartCut.Count -1 do begin
            Line := Config.StartCut[i];
            Line := StringReplace( Line, '%X', StartXS, [rfReplaceAll, rfIgnoreCase] );
            Line := StringReplace( Line, '%Y', StartYS, [rfReplaceAll, rfIgnoreCase] );
            Strings.Add( Line );
        end;

        // cut to - EndX, EndY
        for i := 0 to Config.CutTo.Count -1 do begin
            Line := Config.CutTo[i];
            Line := StringReplace( Line, '%X', EndXS, [rfReplaceAll, rfIgnoreCase] );
            Line := StringReplace( Line, '%Y', EndYS, [rfReplaceAll, rfIgnoreCase] );
            Strings.Add( Line );
        end;

        // end of cut
        for i := 0 to Config.EndCut.Count -1 do begin
            Line := Config.EndCut[i];
            Strings.Add( Line );
        end;
    end;


    procedure EmitVerticalCut( Cut : TgcCut );
    var
        StartX, StartY : Currency;
        EndX, EndY : Currency;
    begin
        // calculate start and end coords of cut
        StartX := Cut.X * Config.CellSpacing_mm;
        // cut from (x,y) down (decreasing y)
        StartY := (Cut.Y * Config.CellSpacing_mm) + (0.5 * Config.CutLength_mm);
        EndX := StartX;
        EndY := StartY - ((Cut.Length -1) * Config.CellSpacing_mm) - Config.CutLength_mm;
        DoEmitCut( StartX, StartY, EndX, EndY );
    end;

    procedure EmitHorizontalCut( Cut : TgcCut );
    var
        StartX, StartY : Currency;
        EndX, EndY : Currency;
    begin
        // calculate start and end coords of cut
        StartX := (Cut.X * Config.CellSpacing_mm) + (0.5 * Config.CutLength_mm);
        StartY := Cut.Y * Config.CellSpacing_mm;
        EndX := StartX - ((Cut.Length -1) * Config.CellSpacing_mm) - Config.CutLength_mm;
        EndY := StartY;
        DoEmitCut( StartX, StartY, EndX, EndY );
    end;

    procedure EmitCrossCut( Cut : TgcCut );
    var
        StartX, StartY : Currency;
        EndX, EndY : Currency;
    begin
        // first cut line is from top-left to bottom-right
        StartX := Cut.X * Config.CellSpacing_mm - (0.5 * Config.CutLength_mm);
        StartY := Cut.Y * Config.CellSpacing_mm + (0.5 * Config.CutLength_mm);
        EndX := StartX + Config.CutLength_mm;
        EndY := StartY - Config.CutLength_mm;
        DoEmitCut( StartX, StartY, EndX, EndY );

        // second cut is from bottom-left to top-right
        StartX := Cut.X * Config.CellSpacing_mm - (0.5 * Config.CutLength_mm);
        StartY := Cut.Y * Config.CellSpacing_mm - (0.5 * Config.CutLength_mm);
        EndX := StartX + Config.CutLength_mm;
        EndY := StartY + Config.CutLength_mm;
        DoEmitCut( StartX, StartY, EndX, EndY );
    end;

var
    FileName : string;
    Cut : TgcCut;
    i : integer;
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
    FileName := ExtractFilePath( ParamStr(0)) + 'G-CodeConfig.txt';

    Cuts := nil;
    Config := TgcConfiguration.Create;
    try
        Config.LoadFromFile( FileName );
        Cuts := TgcTrackCuts.Create;
        Cuts.LoadFromProject( Project );

        // if necessary, join cuts that are in line
        if Config.JoinCuts then begin
            Cuts.JoinCuts;
        end;

        // we cut by doing all cuts in a column, then moving right to next column
        Cuts.SortByXThenY;

        // output header
        for i := 0 to Config.Header.Count - 1 do begin
            Strings.Add( Config.Header[i]);
        end;

        // output G-Code for cuts
        for I := 0 to Cuts.Count - 1 do begin
            Cut := Cuts[i];
            case Cut.CutType of

            tcVertical: EmitVerticalCut( Cut );
            tcHorizontal: EmitHorizontalCut( Cut );
            tcCross: EmitCrossCut( Cut );
            end;
        end;

        // output footer
        for i := 0 to Config.Footer.Count - 1 do begin
            Strings.Add( Config.Footer[i]);
        end;

    finally
        Config.Free;
        Cuts.Free;
    end;


end;

end.
