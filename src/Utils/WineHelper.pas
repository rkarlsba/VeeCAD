unit WineHelper;

interface

uses Graphics;

// return True if running under Wine
function WineHosted : boolean;

//  OPEN A URL UNDER WINDOWS OR UNIX-WINE
function OpenUrl(const url: string) : cardinal;


// Workaround Wine GDI Printing Arcs Problem
// Draw Circle to Canvas Using Line Segments.
// X1..Y4 same as Canvas.Arc() parameters.
// Segments=no of line segments in 360 degrees.

procedure PaintArc( Canvas : TCanvas; Segments, X1, Y1, X2, Y2, X3, Y3, X4, Y4 : integer );

implementation

uses Windows, Math, Shellapi;


// *******************************************
//     DETECT IF RUNNING UNDER UNIX-WINE
// *******************************************

function GetWineAvail: boolean;
var H: cardinal;
begin
    Result := False;
    H := LoadLibrary('ntdll.dll');
    if H > HINSTANCE_ERROR then begin
        Result := Assigned(GetProcAddress(H, 'wine_get_version'));
          FreeLibrary(H);
    end;
end;


// ***********************************************
//      returns True if Running under Wine
// ***********************************************

{ $DEFINE FAKE_WINE}

type THost = ( hsUnknown, hsWindows, hsWine );
var
    Hosting : THost;

function WineHosted : boolean;
begin
{$IFDEF FAKE_WINE}
    result := True;
    exit;
{$ELSE}
    // if first time called, test Wine Status and record
    if Hosting = hsUnknown then begin
        if GetWineAvail then begin
            Hosting := hsWine
        end
        else begin
            Hosting := hsWindows;
        end;
    end;

    // return Wine status.
    result := Hosting = hsWine;
{$ENDIF}
end;



// Draw Circle to Canvas Using Line Segments.
// X1..Y4 same as Canvas.Arc() parameters. Segments=no of line segments in 360 degrees.
{
Equation of ellipse symetrical about x, y axis:
X(t) = Xc + a.cos(t)
Y(t) = Yc – b.sin(t)

where a = half width of ellipse, b= half height of ellipse and t varies from
start angle to finish angle.

Notes about code:
 ArcTan2 calculates ArcTan(Y/X), and returns an angle in the correct quadrant.
  IN: |Y| < 2^64, |X| < 2^64, X <> 0   OUT: [-PI..PI] radians
function ArcTan2(const Y, X: Extended): Extended;

 SinCos is 2x faster than calling Sin and Cos separately for the same angle
procedure SinCos(const Theta: Extended; var Sin, Cos: Extended) register;
}

procedure PaintArc( Canvas : TCanvas; Segments, X1, Y1, X2, Y2, X3, Y3, X4, Y4 : integer );
var
    // half width, half height, a,b are
    a, b : single;

    CentreX, CentreY : single;
    StartAngle, EndAngle : single;
    IncrementAngle : single;
    IncludedAngle : single;
    SegmentsUsed : integer;

    // current plot point to draw line to
    X, Y : extended;

    // current angle
    Angle : single;

    i : integer;
begin
    // work out centre
    CentreX := ( X2 + X1 ) * 0.5;
    CentreY := ( Y2 + Y1 ) * 0.5;

    // work out a=half width, b=half height
    a := ( X2 - X1 ) * 0.5;
    b := ( Y2 - Y1 ) * 0.5;

    // work out start, end angles. Y values are negated because Y moves down page
    StartAngle := ArcTan2( CentreY - Y3, X3 - CentreX );
    EndAngle := ArcTan2( CentreY - Y4, X4 - CentreX );

    // work out increment angle
    IncrementAngle := (2 * Pi) / Segments;

    // work out angle swept by all segments. Going clockwise means we always
    // have positive included angle
    IncludedAngle := EndAngle - StartAngle;
    if IncludedAngle <= 0.0 then begin
        IncludedAngle := IncludedAngle + 2 * Pi;
    end;

    // work out how many segments
    SegmentsUsed := Round( IncludedAngle / IncrementAngle );
    if SegmentsUsed < 4 then begin
        SegmentsUsed := 4
    end;

    // work out revised increment angle that exactly fits segments in angle
    // IncrementAngle is always positive because that is direction of drawing
    IncrementAngle := IncludedAngle / SegmentsUsed;

    // go to start point. Y values are negated because Y moves down page
    Angle := StartAngle;
    SinCos( Angle, Y, X );
    Canvas.MoveTo( Round( CentreX + a*X), Round( CentreY - b*Y ) );

    // plot line segments. Y values are negated because Y moves down page
    for i := 0 to SegmentsUsed -1 do begin
        Angle := Angle + IncrementAngle;
        SinCos( Angle, Y, X );
        Canvas.LineTo( Round( CentreX + a*X), Round( CentreY - b*Y ) );
    end;
end;


// *******************************************
//     OPEN A URL UNDER WINDOWS OR UNIX-WINE
// *******************************************


// *******************************************
//     OPEN A URL UNDER WINDOWS OR UNIX-WINE
// *******************************************

procedure OpenUrlWindows(const url: string);
begin
    ShellExecute(0, 'open', PChar(url), nil, nil, SW_SHOWNORMAL);
end;


procedure OpenUrlWine(const url: string );
var
  S: string;
begin
    S := 'winebrowser ' + url;
    ShellExecute(0, 'open', PChar(S), nil, nil, SW_SHOWNORMAL);
end;


// PROBABLY THE CORRECT WAY TO USE SHELLEXECUTE IN WINE - URL AS SEPARATE PARAMETER
procedure OpenUrlWineParam( url : string);
begin
    ShellExecute(0, 'open', 'winebrowser', PChar(url), nil, SW_SHOWNORMAL);
end;

{
Note:
Wine 1.2 does not work with OpenUrlWindows. No info on OpenUrlWine or OpenUrlWineParam
Wine 1.3 works OpenUrlWindows and OpenUrlWine. No info on OpenUrlWineParam
Wine 1.4 supposedly fixed failure of OpenUrlWindows
Wine 1.6.2 works with OpenUrlWindows and OpenUrlWine and OpenUrlWineParam
Wine 2.0, 2.4, 2.5 work with OpenUrlWindows & OpenUrlWineParam *not* OpenUrlWine

looks as though OpenUrlWineParam is the best bet.
Don't want OpenUrlWindows on old versions of Wine, because it might try to use
a Windows browser.
}

function OpenUrl( const url : string ) : cardinal;
begin
    // recent wine and all windows versions show the system browser
    // too bad if running a really old version of Wine
    result := ShellExecute(0, 'open', PChar(url), nil, nil, SW_SHOWNORMAL);
end;







end.
