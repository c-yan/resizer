unit CommonUtils;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Winapi.ShlObj;

function IsDirectory(const Filename: string): Boolean;
function Chop(S: string): string;
function StrToIntDefWithRange(const S: string;
  Default, Min, Max: Integer): Integer;
function StrToFloatDef(const S: string; Default: Extended): Extended;
function AvoidCollisionName(const Filename: string): string;
function StringInSet(const S: string; const StringSet: array of string)
  : Boolean;
function FileExtInSet(const FileExt: string;
  const FileExtSet: array of string): Boolean;
function MyDocumentsDirectory: string;
function DesktopDirectory: string;
function ReadAllText(const Filename: string): string;
procedure WriteAllText(const Filename, Contents: string);
function GetFileSize(const Filename: string): Cardinal;
procedure SetTimeStamp(const Filename: string;
  const CreationTime, LastWriteTime: PFileTime);
procedure GetTimeStamp(const Filename: string;
  const CreationTime, LastWriteTime: PFileTime);
function FileTimeToDateTime(FileTime: TFileTime): TDateTime;

implementation

function IsDirectory(const Filename: string): Boolean;
begin
  Result := (FileGetAttr(Filename) and faDirectory) <> 0;
end;

function Chop(S: string): string;
begin
  Result := Copy(S, 1, Length(S) - 1);
end;

function StrToIntDefWithRange(const S: string;
  Default, Min, Max: Integer): Integer;
  function Clamp(Value, Min, Max: Integer): Integer; inline;
  begin
    if Value < Min then
      Result := Min
    else if Value > Max then
      Result := Max
    else
      Result := Value;
  end;

begin
  Result := Clamp(StrToIntDef(S, Default), Min, Max);
end;

function StrToFloatDef(const S: string; Default: Extended): Extended;
var
  Value: Extended;
begin
  if TextToFloat(PChar(S), Value, fvExtended) then
    Result := Value
  else
    Result := Default;
end;

function AvoidCollisionName(const Filename: string): string;
var
  I: Integer;
  Path, Name, Ext: string;
begin
  if not FileExists(Filename) then
  begin
    Result := Filename;
    Exit;
  end;
  I := 1;
  Path := ExtractFilePath(Filename);
  Name := ChangeFileExt(ExtractFileName(Filename), '');
  Ext := ExtractFileExt(Filename);
  while FileExists(Format('%s%s[%d]%s', [Path, Name, I, Ext])) do
    Inc(I);
  Result := Format('%s%s[%d]%s', [Path, Name, I, Ext]);
end;

function StringInSet(const S: string; const StringSet: array of string)
  : Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(StringSet) to High(StringSet) do
  begin
    if S = StringSet[I] then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function FileExtInSet(const FileExt: string;
  const FileExtSet: array of string): Boolean;
begin
  Result := StringInSet(LowerCase(FileExt), FileExtSet);
end;

function GetSpecialDirectory(FolderID: Integer): string;
var
  PIDL: PItemIDList;
begin
  SetLength(Result, MAX_PATH);
  SHGetSpecialFolderLocation(0, FolderID, PIDL);
  SHGetPathFromIDList(PIDL, PChar(Result));
  SetLength(Result, StrLen(PChar(Result)));
end;

function MyDocumentsDirectory: string;
begin
  Result := GetSpecialDirectory(CSIDL_PERSONAL);
end;

function DesktopDirectory: string;
begin
  Result := GetSpecialDirectory(CSIDL_DESKTOPDIRECTORY);
end;

function ReadAllText(const Filename: string): string;
begin
  with TStringList.Create do
    try
      LoadFromFile(Filename);
      Result := Text;
    finally
      Free;
    end;
end;

procedure WriteAllText(const Filename, Contents: string);
begin
  with TStringList.Create do
    try
      Text := Contents;
      SaveToFile(Filename);
    finally
      Free;
    end;
end;

function GetFileSize(const Filename: string): Cardinal;
var
  Handle: THandle;
begin
  Handle := CreateFile(PChar(Filename), GENERIC_READ, 0, nil,
    OPEN_EXISTING, 0, 0);
  Result := Winapi.Windows.GetFileSize(Handle, nil);
  CloseHandle(Handle);
end;

procedure SetTimeStamp(const Filename: string;
  const CreationTime, LastWriteTime: PFileTime);
var
  Handle: THandle;
begin
  Handle := CreateFile(PChar(Filename), GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, 0, 0);
  SetFileTime(Handle, CreationTime, nil, LastWriteTime);
  CloseHandle(Handle);
end;

procedure GetTimeStamp(const Filename: string;
  const CreationTime, LastWriteTime: PFileTime);
var
  Handle: THandle;
begin
  Handle := CreateFile(PChar(Filename), GENERIC_READ, 0, nil,
    OPEN_EXISTING, 0, 0);
  GetFileTime(Handle, CreationTime, nil, LastWriteTime);
  CloseHandle(Handle);
end;

function FileTimeToDateTime(FileTime: TFileTime): TDateTime;
var
  LocalTime: TFileTime;
  SystemTime: TSystemTime;
begin
  FileTimeToLocalFileTime(FileTime, LocalTime);
  FileTimeToSystemTime(LocalTime, SystemTime);
  Result := SystemTimeToDateTime(SystemTime);
end;

end.
