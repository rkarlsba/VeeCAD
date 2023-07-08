unit GdiHandles;

interface

uses Windows;

// *************** TFontHandle ***************
{
The TFontHandle is useful when the Delphi TPen won't do the job, especially
for rotated text. This class gives you a hFont which has settable Font Name,
Height, Width, Bold, Angle, Pitch. After properties have been changed, hFont
calls CreateFontIndirect() to provide a new handle.
}

type TvePitch = ( piFixed, piVariable );

type TFontHandle = class

  protected
    FHandle : hFont;
    FName : string;
    FHeight : integer;
    FWidth : integer; 
    FBold : boolean;
    FAngle : integer;
    FPitch : TvePitch;

    procedure CreateHandle;
    procedure FreeHandle;
    function GetHandle : hFont;
    procedure SetName( Value : string );
    procedure SetHeight( Value : integer );
    procedure SetWidth( Value : integer ); 
    procedure SetBold( Value : boolean );
    procedure SetAngle( Value : integer );
    procedure SetPitch( Value : TvePitch );

  public
    property Handle : hFont read GetHandle;

    // Name must be of a TrueType font for rotation to work
    property Name : string read FName write SetName;

    property Height : integer read FHeight write SetHeight;
    property Width : integer read FWidth write SetWidth;
    property Bold : boolean read FBold write SetBold;
    property Angle : integer read FAngle write SetAngle;
    property Pitch : TvePitch read FPitch write SetPitch;

    constructor Create;
    destructor Destroy; override;
end;


implementation

uses SysUtils;

// *************************************
//            TFontHandle
// *************************************

procedure TFontHandle.CreateHandle;
var
    LogFont : TLogFont;
begin
    FreeHandle;

    with LogFont do begin

        { when Height > 0  this value in device units is matched against the
        *cell height* of the available fonts.

        when Height < 0, absolute of height in device units is matched against
        the *character height* of available fonts.  This is what we want !
        }
        lfHeight := - FHeight;
        lfWidth :=  FWidth;
        lfEscapement := FAngle;
        lfOrientation := Angle;
        if FBold then begin
            lfWeight := FW_BOLD
        end
        else begin
            lfWeight := FW_NORMAL
        end;
        lfItalic := 0;
        lfUnderline := 0;
        lfStrikeout := 0;
        lfCharSet := ANSI_CHARSET;
        lfOutPrecision := OUT_TT_ONLY_PRECIS;  //	OUT_DEFAULT_PRECIS;
        lfClipPrecision := CLIP_DEFAULT_PRECIS;
        lfQuality := DEFAULT_QUALITY;
        case FPitch of
          piFixed : lfPitchAndFamily := FIXED_PITCH;
          piVariable : lfPitchAndFamily := VARIABLE_PITCH;
        end;
        StrPLCopy(lfFaceName, FName, LF_FACESIZE);
    end;

    FHandle := CreateFontIndirect(LogFont);
end;

procedure TFontHandle.FreeHandle;
begin
    if FHandle <> 0 then begin
        DeleteObject( FHandle );
        FHandle := 0;
    end;
end;

function TFontHandle.GetHandle : hFont;
begin
    if FHandle = 0 then begin
        CreateHandle;
    end;
    result := FHandle;
end;

procedure TFontHandle.SetName( Value : string );
begin
    if FName <> Value then begin
        FName := Value;
        FreeHandle;
    end;
end;

procedure TFontHandle.SetHeight( Value : integer );
begin
    if FHeight <> Value then begin
        FHeight := Value;
        FreeHandle;
    end;
end;

procedure TFontHandle.SetWidth( Value : integer );
begin
    if FWidth <> Value then begin
        FWidth := Value;
        FreeHandle;
    end;
end;


procedure TFontHandle.SetBold( Value : boolean );
begin
    if FBold <> Value then begin
        FBold := Value;
        FreeHandle;
    end;
end;

procedure TFontHandle.SetAngle( Value : integer );
begin
    if FAngle <> Value then begin
        FAngle := Value;
        FreeHandle;
    end;
end;

procedure TFontHandle.SetPitch( Value : TvePitch );
begin
    if FPitch <> Value then begin
        FPitch := Value;
        FreeHandle;
    end;
end;


constructor TFontHandle.Create;
begin
end;

destructor TFontHandle.Destroy;
begin
    FreeHandle;
    inherited;
end;




end.
