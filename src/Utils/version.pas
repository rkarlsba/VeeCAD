unit version;

interface

function GetFileVersion( const FileName : string;
    var Major, Minor, Release, Build : integer;
    var PreRelease, Debug : boolean;
    var Description : string ) : boolean;


implementation

uses Windows, SysUtils, ExceptSafe;

type ESafeVersion = class( ESafe );

// get Major, Minor, Release, Build for an EXE or DLL file.
// returns true=success.
// returns false=failure-probably info not found in the file.

function GetFileVersion( const FileName : string;
    var Major, Minor, Release, Build : integer;
    var PreRelease, Debug : boolean;
    var Description : string ) : boolean;

var
    Zero : DWORD;       // set to 0 by GetFileVersionInfoSize
    VersionInfoSize : DWORD;
    PVersionData : pointer;
    PFixedFileInfo : PVSFixedFileInfo;
    FixedFileInfoLength : UINT;
    FileFlags : WORD;

begin
    // ask Windows how big a data buffer to allocate to hold this EXE or
    // DLL version info
    VersionInfoSize :=
        GetFileVersionInfoSize( pChar(FileName), Zero );

    // if no version info in the EXE or DLL
    if VersionInfoSize = 0 then begin
        result := False;
        exit;
    end;

    // allocate memory needed to hold version info
    PVersionData := AllocMem( VersionInfoSize );
    try

        // load version resource out of EXE or DLL into our buffer
        if GetFileVersionInfo( pChar(FileName), 0, VersionInfoSize,
            PVersionData ) = FALSE then begin
            Raise ESafeVersion.Create( 'Can''''t get version info' );
        end;

        // get the fixed file info portion of the resource in buffer
        if VerQueryValue(
            PVersionData, '\', pointer(PFixedFileInfo), FixedFileInfoLength )
            = FALSE then begin
            // no fixed file info in this version resource !
            result := False;
            exit;
        end;

        // extract the info from the the fixed file data structure
        Major := PFixedFileInfo^.dwFileVersionMS shr 16;
        Minor := PFixedFileInfo^.dwFileVersionMS and $FFFF;
        Release := PFixedFileInfo^.dwFileVersionLS shr 16;
        Build := PFixedFileInfo^.dwFileVersionLS and $FFFF;

        FileFlags :=  PFixedFileInfo^.dwFileFlags;
        PreRelease := (VS_FF_PRERELEASE and FileFlags) <> 0;
        Debug := (VS_FF_DEBUG and FileFlags) <> 0;

        Description := Format(
            'Ver %d.%d Release %d Build %d',
            [Major, Minor, Release, Build] );

        if PreRelease then begin
            Description := Description + ' Beta';
        end;
        if Debug then begin
            Description := Description + ' Debug';
        end;
    finally
        FreeMem( PVersionData );
    end;
    result := True;
end;
end.


