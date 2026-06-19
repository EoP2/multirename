unit uShowForm;
// [独立版存根] 替代 DC 的 uShowForm

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

procedure ShowViewerByGlob(const sFileName: string);
procedure ShowEditorByGlob(const sFileName: string);

implementation

uses
{$IFDEF MSWINDOWS}
  Windows, ShellApi;
{$ELSE}
  Process;
{$ENDIF}

procedure OpenFileWithSystem(const sFileName: string);
begin
{$IFDEF MSWINDOWS}
  ShellExecute(0, 'open', PChar(sFileName), nil, nil, SW_SHOWNORMAL);
{$ELSE}
  // Linux/macOS: xdg-open / open
  with TProcess.Create(nil) do
  try
    {$IFDEF DARWIN}
    Executable := 'open';
    {$ELSE}
    Executable := 'xdg-open';
    {$ENDIF}
    Parameters.Add(sFileName);
    Options := [poNoConsole];
    Execute;
  finally
    Free;
  end;
{$ENDIF}
end;

procedure ShowViewerByGlob(const sFileName: string);
begin
  if FileExists(sFileName) then
    OpenFileWithSystem(sFileName);
end;

procedure ShowEditorByGlob(const sFileName: string);
begin
  if FileExists(sFileName) then
    OpenFileWithSystem(sFileName);
end;

end.
