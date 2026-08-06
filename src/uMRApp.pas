unit uMRApp;

{$mode objfpc}{$H+}

// Standalone application helpers.

interface

uses
  SysUtils;

const
  MRApplicationName = 'multirename';

function MRGetApplicationName: string;
function MRGetConfigDir: string;
procedure MRInstallApplicationNameHook;

implementation

function MRGetApplicationName: string;
begin
  Result := MRApplicationName;
end;

procedure MRInstallApplicationNameHook;
begin
  OnGetApplicationName := @MRGetApplicationName;
end;

// 配置目录为可执行文件所在目录（便于绿色/便携部署）。
function MRGetConfigDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

end.
