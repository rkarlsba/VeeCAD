unit FullPathName;

interface

function GetFullLongPathName(sPath: string): string;

implementation

uses Windows, SysUtils;
{
Q.
I want to change the short filename D:\PROBA\NEWSAM~1\SAMPLE.BLD
into the long one D:\Proba\New samples\sample.bld.

When I use GetFullPathName the result is the same filename
D:\PROBA\NEWSAM~1\SAMPLE.BLD.

A.
GetFullPathName is working "as designed." Many people assume
GetFullPathName=GetLongPathName, but that's not the case. In order to get the
long path, you have to iterate over each element of the path.
Here's a function that does the work for you:

ROGER : This function looks dodgy to me.
}
{
function GetExpandedPathName(const PathName: string): string;
var
    Drive: String;
    Path: String;
    SearchRec: TSearchRec;
begin
    Drive := ExtractFileDrive(PathName);
    Path := Copy(PathName, Length(Drive) + 1, Length(PathName));
    if (Path = '') or (Path = '\') then begin
        Result := PathName;

        if Result[Length(Result)] = '\' then begin
            Delete(Result, Length(Result), 1);
        end;
    end
    else begin
        Path := GetLongPathName(ExtractFileDir(PathName));
        if FindFirst(PathName, faAnyFile, SearchRec) = 0 then begin
            Result := Path + '\' + SearchRec.FindData.cFileName;
            FindClose(SearchRec);
        end
        else begin
            Result := Path + '\' + ExtractFileName(PathName);
        end
    end;
end;

              sysutils.ExpandFileName() is a wrapper for GetFullPathName
}
{ from Win SDK documentation:
GetFullPathName does no conversion of the specified file name, lpFileName.
If the specified file name exists, you can use GetLongPathName and
GetShortPathName to convert to long and short path names, respectively.

I take this to mean that GetFullPathName followed by a check using FileExists,
followed by a call to GetLongPathName will get a unique form for a file.
}


// *****************************************************************************
// ** TURN 8.3 AND-OR RELATIVE FILENAME, PATH INTO LONG NAME, FULL PATH FORM **
// *****************************************************************************

{ Call with sPath = valid directory or filename, short or long, with or without
path.  Returns the full lfn version of sPath, or '' iff sPath invalid. }

function GetFullLongPathName(sPath: string): string;
var
    n: integer;
    h: HWND;
    fd: Twin32findData;
begin
    result := '';
    sPath := expandFilename(sPath);
    n := length(sPath);
    if (n = 0) then EXIT;
    if (n > 3) and (sPath[n] = '\') then setLength(sPath, n - 1);

    //loop from end, filling result with lfn translations.
    while (length(sPath) > 10) do begin
        h := findFirstFile(pChar(sPath), fd);
        if (h = invalid_handle_value) then begin
            result := '';
            EXIT;
        end;
        windows.findClose(h);
        result := '\' + string(fd.cFileName) + result;
        sPath := extractFilePath(sPath);
        setLength(sPath, length(sPath) - 1);
    end;
    result := sPath + result;
end;


// from Peter Below

// GetFullpathname only converts the last element of the name. Try this:

{+------------------------------------------------------------
 | Function GetFullLongFilename
 |
 | Parameters:
 |  shortname: filename or path to convert. This can be a
 |             fully qualified filename or a path relative
 |             to the current directory. It can contain long
 |             and/or short forms for the names.
 | Returns:
 |  fully qualified filename using the long names for all elements
 |  of the path.
 | Description:
 |  Recursively uses FindFirst to find the long names for
 |  the path elements.
 | Error Conditions:
 |  Will raise an exception if any part of the path was not found.
 |
 |Created: 15.01.98 14:09:26 by P. Below
 +------------------------------------------------------------}
(*
function GetFullLongFilename( shortname: string ) : string;

    function GetL( shortname: string ) : string;
    var
        srec: TSearchRec;
    begin
        { Lopp off the last element of the passed name. If we received
        only a root name, e.g. c:\, ExtractFileDir returns the
        path unchanged. }
        Result := ExtractFileDir( shortname );
        if (Result <> shortname) then begin
            { We still have an unconverted path element. So convert
            the last one in the current shortname and combine the
            resulting long name with what we get by calling ourselves
            recursively with the rest of the path. }
            if FindFirst( shortname, faAnyfile, srec ) = 0 then begin
                try
                    Result := GetL( Result )+'\'+srec.Name;
                finally
                    FindClose( srec );
                end
            end
            else begin
                result := '';
                // raise Exception.CreateFmt('Path %s does not exist!', [shortname]);
            end
        end
        else begin
            { Only the root remains. Remove the backslash since the
            caller will add it back anyway. }
            Delete(Result, length(result),1);
        end;
    end;

begin
    { Create fully qualified path and pass it to the converter. }
    Result := GetL( ExpandFilename( shortname ));
end;
*)

end.
