unit uMRRename;

{$mode objfpc}{$H+}

// 替代 DC 的 IFileSource / TFileSourceSetFilePropertyOperation / OperationsManager。
// 直接用 SysUtils.RenameFile 执行重命名，记录结果到日志列表。

interface

uses
  SysUtils, Classes, uMRFile;

type
  TRenameResultCode = (rrcSuccess, rrcError, rrcSkipped);

  TRenameResult = record
    OldPath: string;
    NewPath: string;
    Code:    TRenameResultCode;
    Msg:     string;  // 错误时填写
  end;

  TRenameResults = array of TRenameResult;

// 执行重命名：OldFiles[i] -> NewFiles[i].Name（路径不变）
// 返回每个文件的结果。
// 如果 ALog <> nil，写入 'OK  old -> new' 格式的行。
procedure ExecuteRename(
  OldFiles, NewFiles: TFiles;
  ALog: TStrings;
  const FilenameWithFullPath: Boolean;
  out Results: TRenameResults);

implementation

procedure ExecuteRename(
  OldFiles, NewFiles: TFiles;
  ALog: TStrings;
  const FilenameWithFullPath: Boolean;
  out Results: TRenameResults);
var
  I: Integer;
  OldPath, NewPath: string;
  LogName: string;
begin
  SetLength(Results, OldFiles.Count);

  for I := 0 to OldFiles.Count - 1 do
  begin
    OldPath := OldFiles[I].FullPath;
    NewPath := OldFiles[I].Path + NewFiles[I].Name;

    Results[I].OldPath := OldPath;
    Results[I].NewPath := NewPath;

    if OldPath = NewPath then
    begin
      Results[I].Code := rrcSkipped;
      Results[I].Msg  := '';
    end
    else if not FileExists(OldPath) and not DirectoryExists(OldPath) then
    begin
      Results[I].Code := rrcError;
      Results[I].Msg  := '源文件不存在';
    end
    else if RenameFile(OldPath, NewPath) then
    begin
      // 成功后把新名字写回 OldFiles，让窗口刷新时能显示
      OldFiles[I].Name := NewFiles[I].Name;
      Results[I].Code := rrcSuccess;
      Results[I].Msg  := '';
    end
    else
    begin
      Results[I].Code := rrcError;
      Results[I].Msg  := SysErrorMessage(GetLastOSError);
    end;

    // 写日志
    if Assigned(ALog) then
    begin
      if FilenameWithFullPath then
        LogName := OldPath
      else
        LogName := OldFiles[I].Name;  // 已更新或原名

      case Results[I].Code of
        rrcSuccess: ALog.Add('OK      ' + LogName + ' -> ' + NewFiles[I].Name);
        rrcError:   ALog.Add('FAILED  ' + LogName + ' -> ' + NewFiles[I].Name + ' (' + Results[I].Msg + ')');
        rrcSkipped: ALog.Add('SKIPPED ' + LogName);
      end;
    end;
  end;
end;

end.
