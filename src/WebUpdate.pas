unit WebUpdate;

interface


procedure GetVeeCADUpdate;
function GetEnvironmentString( const Name : string ) : string;
procedure ToVeeCADWebsite;

implementation

uses Windows, SysUtils, Version, WineHelper;


// *****************************************
//     OPEN BROWSER AT VEECAD WEBSITE
// *****************************************

const URL = 'http://veecad.com/index.html';

procedure ToVeeCADWebsite;
begin
    OpenUrl( URL );
end;


// *****************************************
//     CONVERT DELPHI TIME TO UNIX EPOCH
// *****************************************

// The 64 bit result does not rollover in 2038 like the
// 32 bit one from old Unixes !

function DateTimeToUnix(const AValue: TDateTime): Int64;
begin
  Result := Round((AValue - 25569) * (24*60*60));
end;

function GetEnvironmentString( const Name : string ) : string;
var
    Env_String : array[0..255] of char;
begin
    Env_String := '';
    if GetEnvironmentVariable( pChar(Name), Env_String, 255 ) <> 0 then begin
        result := Trim( Env_String )
    end
    else begin
        result := '';
    end;
end;


procedure GetVeeCADUpdate;
const
//    URL = 'http://localhost/update.php';
    URL = 'http://veecad.com/updatefree.php';
var
    Major, Minor, Release, Build : integer;
    PreRelease, Debug : boolean;
    Description : string;

    Task : string;
    Request : string;
begin
    // ***** VERSION OF THIS PROGRAM *****

    // Current Version
    GetFileVersion(
        ParamStr(0),
        Major, Minor, Release, Build,
        PreRelease, Debug,
        Description
    );

    // Task to Do
    Task := 'CheckVer';

    // ***** PUT ALL BITS TOGETHER TO MAKE AN HTTP GET STRING ********
    // http://localhost/echo.php?text2=T2&text2A=T2A

    Request := Format( '?Major=%d&Minor=%d&Release=%d&Build=%d&Action=%s',
        [ Major, Minor, Release, Build, Task ] );

    // ***** SEND BROWSER AS REQUEST ********
    Request := URL + Request;
    OpenUrl( Request );
end;

end.

