unit MainIconUpdate;

// Pinched from Jordan Russell's Inno Setup 4.2.2.2 CompResUpdate.pas
(*
Inno Setup License
==================

Except where otherwise noted, all of the documentation and software included
in the Inno Setup package is copyrighted by Jordan Russell.

Copyright (C) 1997-2004 Jordan Russell. All rights reserved.

This software is provided "as-is," without any express or implied warranty.
In no event shall the author be held liable for any damages arising from the
use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter and redistribute it,
provided that the following conditions are met:

1. All redistributions of source code files must retain all copyright
   notices that are currently in place, and this list of conditions without
   modification.

2. All redistributions in binary form must retain all occurrences of the
   above copyright notice and web site addresses that are currently in
   place (for example, in the About boxes).

3. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software to
   distribute a product, an acknowledgment in the product documentation
   would be appreciated but is not required.

4. Modified versions in source or binary form must be plainly marked as
   such, and must not be misrepresented as being the original software.


Jordan Russell
jr-2004 AT jrsoftware.org
http://www.jrsoftware.org/
*)

interface

uses
  Windows, SysUtils;


procedure UpdateDelphiExeIcons(const FileName, IcoFileName: String);

implementation

uses  Classes;

procedure Error(const Msg: String);
begin
  raise Exception.Create('Resource update error: ' + Msg);
end;

procedure ErrorWithLastError(const Msg: String);
begin
  Error(Msg + '(' + IntToStr(GetLastError) + ')');
end;


function EnumLangsFunc(hModule: Cardinal; lpType, lpName: PAnsiChar; wLanguage: Word; lParam: Integer): BOOL; stdcall;
begin
  PWord(lParam)^ := wLanguage;
  Result := False;
end;

function GetResourceLanguage(hModule: Cardinal; lpType, lpName: PAnsiChar; var wLanguage: Word): Boolean;
begin
  wLanguage := 0;
  EnumResourceLanguages(hModule, lpType, lpName, @EnumLangsFunc, Integer(@wLanguage));
  Result := True;
end;


procedure UpdateDelphiExeIcons(const FileName, IcoFileName: String);
type
  PIcoItemHeader = ^TIcoItemHeader;
  TIcoItemHeader = packed record
    Width: Byte;
    Height: Byte;
    Colors: Byte;
    Reserved: Byte;
    Planes: Word;
    BitCount: Word;
    ImageSize: DWORD;
  end;
  PIcoItem = ^TIcoItem;
  TIcoItem = packed record
    Header: TIcoItemHeader;
    Offset: DWORD;
  end;
  PIcoHeader = ^TIcoHeader;
  TIcoHeader = packed record
    Reserved: Word;
    Typ: Word;
    ItemCount: Word;
    Items: array [0..MaxInt shr 4 - 1] of TIcoItem;
  end;
  PGroupIconDirItem = ^TGroupIconDirItem;
  TGroupIconDirItem = packed record
    Header: TIcoItemHeader;
    Id: Word;
  end;
  PGroupIconDir = ^TGroupIconDir;
  TGroupIconDir = packed record
    Reserved: Word;
    Typ: Word;
    ItemCount: Word;
    Items: array [0..MaxInt shr 4 - 1] of TGroupIconDirItem;
  end;

  function IsValidIcon(P: Pointer; Size: Cardinal): Boolean;
  var
    ItemCount: Cardinal;
  begin
    Result := False;
    if Size < SizeOf(Word) * 3 then
      Exit;
    if (PChar(P)[0] = 'M') and (PChar(P)[1] = 'Z') then
      Exit;
    ItemCount := PIcoHeader(P).ItemCount;
    if Size < (SizeOf(Word) * 3) + (ItemCount * SizeOf(TIcoItem)) then
      Exit;
    P := @PIcoHeader(P).Items;
    while ItemCount > 0 do begin
      if (PIcoItem(P).Offset + PIcoItem(P).Header.ImageSize < PIcoItem(P).Offset) or
         (PIcoItem(P).Offset + PIcoItem(P).Header.ImageSize > Size) then
        Exit;
      Inc(PIcoItem(P));
      Dec(ItemCount);
    end;
    Result := True;
  end;

var
  H: THandle;
  M: HMODULE;
  R: HRSRC;
  Res: HGLOBAL;
  GroupIconDir, NewGroupIconDir: PGroupIconDir;
  I: Integer;
  wLanguage: Word;
  F : TFileStream;
  Ico: PIcoHeader;
  N: Cardinal;
  NewGroupIconDirSize: LongInt;
begin
  if Win32Platform <> VER_PLATFORM_WIN32_NT then begin
    // complain if can't be done
    //    Error('Only supported on Windows NT and above');

    // quietly return if can't be done
    exit;
  end;

  Ico := nil;

  try
    { Load the icons }
    F := TFileStream.Create( IcoFileName, fmOpenRead or fmShareDenyWrite );
    try
        N := F.Size;
        GetMem(Ico, N);
        F.ReadBuffer( Ico^, N );
    finally
        F.Free;
    end;

    { Ensure the icon is valid }
    if not IsValidIcon(Ico, N) then
      Error('Icon file is invalid');

    { Update the resources }
    H := BeginUpdateResource(PChar(FileName), False);
    if H = 0 then
      ErrorWithLastError('BeginUpdateResource failed (1)');
    try
      M := LoadLibraryEx(PChar(FileName), 0, LOAD_LIBRARY_AS_DATAFILE);
      if M = 0 then
        ErrorWithLastError('LoadLibraryEx failed (1)');
      try
      	{ Load the 'MAINICON' group icon resource }
        R := FindResource(M, 'MAINICON', RT_GROUP_ICON);
        if R = 0 then
          ErrorWithLastError('FindResource failed (1)');
        Res := LoadResource(M, R);
        if Res = 0 then
          ErrorWithLastError('LoadResource failed (1)');
        GroupIconDir := LockResource(Res);
        if GroupIconDir = nil then
          ErrorWithLastError('LockResource failed (1)');

        { Delete 'MAINICON' }
        if not GetResourceLanguage(M, RT_GROUP_ICON, 'MAINICON', wLanguage) then
          Error('GetResourceLanguage failed (1)');
        if not UpdateResource(H, RT_GROUP_ICON, 'MAINICON', wLanguage, nil, 0) then
          ErrorWithLastError('UpdateResource failed (1)');

        { Delete the RT_ICON icon resources that belonged to 'MAINICON' }
        for I := 0 to GroupIconDir.ItemCount-1 do begin
          if not GetResourceLanguage(M, RT_ICON, MakeIntResource(GroupIconDir.Items[I].Id), wLanguage) then
            Error('GetResourceLanguage failed (2)');
          if not UpdateResource(H, RT_ICON, MakeIntResource(GroupIconDir.Items[I].Id), wLanguage, nil, 0) then
            ErrorWithLastError('UpdateResource failed (2)');
        end;

        { Build the new group icon resource }
        NewGroupIconDirSize := 3*SizeOf(Word)+Ico.ItemCount*SizeOf(TGroupIconDirItem);
        GetMem(NewGroupIconDir, NewGroupIconDirSize);
        try
          { Build the new group icon resource }
          NewGroupIconDir.Reserved := GroupIconDir.Reserved;
          NewGroupIconDir.Typ := GroupIconDir.Typ;
          NewGroupIconDir.ItemCount := Ico.ItemCount;
          for I := 0 to NewGroupIconDir.ItemCount-1 do begin
            NewGroupIconDir.Items[I].Header := Ico.Items[I].Header;
            NewGroupIconDir.Items[I].Id := I+1; //assumes that there aren't any icons left
          end;

          { Update 'MAINICON' }
          for I := 0 to NewGroupIconDir.ItemCount-1 do
            if not UpdateResource(H, RT_ICON, MakeIntResource(NewGroupIconDir.Items[I].Id), 1033, Pointer(DWORD(Ico) + Ico.Items[I].Offset), Ico.Items[I].Header.ImageSize) then
              ErrorWithLastError('UpdateResource failed (3)');

          { Update the icons }
          if not UpdateResource(H, RT_GROUP_ICON, 'MAINICON', 1033, NewGroupIconDir, NewGroupIconDirSize) then
            ErrorWithLastError('UpdateResource failed (4)');
        finally
          FreeMem(NewGroupIconDir);
        end;
      finally
        FreeLibrary(M);
      end;
    except
      EndUpdateResource(H, True);  { discard changes }
      raise;
    end;
    if not EndUpdateResource(H, False) then
      ErrorWithLastError('EndUpdateResource failed');
  finally
    FreeMem(Ico);
  end;
end;

end.

