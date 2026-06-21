unit uMRUtils;

{$mode objfpc}{$H+}

// 替代 fmultirename.pas 里用到的 DCOSUtils / DCStrUtils / uDCUtils / uFileProcs 中的函数。
// 只保留批量重命名实际调用的那几个，全部用标准库重新实现。

interface

uses
  SysUtils, Classes, Controls, StdCtrls, LazFileUtils;

const
  // 文件名大小写敏感（Windows 不敏感）
{$IFDEF MSWINDOWS}
  FileNameCaseSensitive = False;
{$ELSE}
  FileNameCaseSensitive = True;
{$ENDIF}

// 展开环境变量并规范路径（简化版，只处理常见情况）
function  mbExpandFileName(const sFileName: string): string;

// 强制创建目录（含中间目录）
procedure mbForceDirectory(const sDir: string);

// 生成临时文件名（用于解决重命名冲突）
function  GetTempName(const APath: string; const APrefix: string = ''): string;

// 删除文件（DC uFileProcs.mbDeleteFile 的简化替代）
function  mbDeleteFile(const AFileName: string): Boolean;

// 返回系统临时目录下的 MultiRename 临时目录（DC 临时目录管理器的简化替代）
function  GetTempFolderDeletableAtTheEnd: string;

// UTF-16/UnicodeString -> UTF-8（DCUnicodeUtils.CeUtf16ToUtf8 的简化替代）
function  CeUtf16ToUtf8(const S: UnicodeString): UTF8String;

// 调试输出（uDebug.DCDebug 的简化替代）
procedure DCDebug(const S: string); overload;
procedure DCDebug(const S: string; Args: array of const); overload;

// 用系统默认程序打开文件，替代 DC 的 ShowViewerByGlob 路径
function  OpenDocument(const AFileName: string): Boolean;

// --- uDCUtils / uFileProcs 替代 ---

// 把 '|' 分隔的字符串逐项加入 ComboBox
procedure ParseLineToList(const sLine: string; AList: TStrings);

// 从形如 "key=value" 的参数数组里读取 Bool 值
procedure GetParamBoolValue(const sParam: string; const sKey: string; var Value: Boolean);

// 把 sLine 插入 ComboBox 第一项（去重后移到最前）
procedure InsertFirstItem(const sLine: string; AComboBox: TCustomComboBox);

// 自然排序比较（1 < 2 < 10，不区分大小写）
// 返回值：<0 表示 A<B，0 表示相等，>0 表示 A>B
function NaturalCompareFileNames(const A, B: string): integer;

implementation

uses
  LCLIntf;

function mbExpandFileName(const sFileName: string): string;
begin
  // 先展开 %ENV% 变量，再规范化路径分隔符
  Result := ExpandFileName(ExpandUNCFileName(sFileName));
end;

procedure mbForceDirectory(const sDir: string);
begin
  ForceDirectories(sDir);
end;

function GetTempName(const APath: string; const APrefix: string): string;
var
  I: Integer;
  BasePath: string;
begin
  I := 0;
  if APath = '' then
    BasePath := IncludeTrailingPathDelimiter(GetTempDir(False))
  else
    BasePath := IncludeTrailingPathDelimiter(APath);
  ForceDirectories(BasePath);
  repeat
    Result := BasePath + '._tmp_' + APrefix + '_' + IntToStr(I);
    Inc(I);
  until not FileExists(Result);
end;

function mbDeleteFile(const AFileName: string): Boolean;
begin
  Result := SysUtils.DeleteFile(AFileName);
end;

function GetTempFolderDeletableAtTheEnd: string;
begin
  Result := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'multirename' + PathDelim;
  ForceDirectories(Result);
end;

function CeUtf16ToUtf8(const S: UnicodeString): UTF8String;
begin
  Result := UTF8Encode(S);
end;

procedure DCDebug(const S: string); overload;
begin
  // Standalone build: ignore Double Commander debug output.
end;

procedure DCDebug(const S: string; Args: array of const); overload;
begin
  // Standalone build: ignore Double Commander debug output.
end;

function OpenDocument(const AFileName: string): Boolean;
begin
  Result := LCLIntf.OpenDocument(AFileName);
end;

procedure ParseLineToList(const sLine: string; AList: TStrings);
var
  I, Start: Integer;
  S: string;
begin
  AList.Clear;
  if sLine = '' then Exit;
  Start := 1;
  for I := 1 to Length(sLine) do
  begin
    if sLine[I] = '|' then
    begin
      S := Copy(sLine, Start, I - Start);
      AList.Add(S);
      Start := I + 1;
    end;
  end;
  // 最后一段
  S := Copy(sLine, Start, MaxInt);
  if S <> '' then AList.Add(S);
end;

procedure GetParamBoolValue(const sParam: string; const sKey: string; var Value: Boolean);
var
  P: Integer;
  sVal: string;
begin
  P := Pos(LowerCase(sKey) + '=', LowerCase(sParam));
  if P = 0 then Exit;
  sVal := Copy(sParam, P + Length(sKey) + 1, MaxInt);
  if SameText(sVal, 'true') or (sVal = '1') then
    Value := True
  else if SameText(sVal, 'false') or (sVal = '0') then
    Value := False;
end;

procedure InsertFirstItem(const sLine: string; AComboBox: TCustomComboBox);
var
  I: Integer;
begin
  if sLine = '' then Exit;
  with AComboBox.Items do
  begin
    I := 0;
    while (I < Count) and (CompareStr(Strings[I], sLine) <> 0) do Inc(I);
    if I >= Count then
    begin
      Insert(0, sLine);
      AComboBox.ItemIndex := 0;
    end
    else if I > 0 then
    begin
      Move(I, 0);
      AComboBox.ItemIndex := 0;
    end;
  end;
end;

// 自然排序文件名比较，移植自 DC udcutils.StrChunkCmp
// 大小写不敏感，数字段按数值比较（前导零忽略），跨平台
function NaturalCompareFileNames(const A, B: string): integer;
type
  TCategory = (cNone, cNumber, cString);

  TChunk = record
    FullStr: string;
    Str:     string;
    Category: TCategory;
    PosStart: integer;
    PosEnd:   integer;
  end;

var
  Chunk1, Chunk2: TChunk;

  function Categorize(c: char): TCategory; inline;
  begin
    if c in ['0'..'9'] then Result := cNumber
    else Result := cString;
  end;

  procedure NextChunkInit(var Chunk: TChunk); inline;
  begin
    Chunk.PosStart := Chunk.PosEnd;
    if Chunk.PosStart > Length(Chunk.FullStr) then
      Chunk.Category := cNone
    else
      Chunk.Category := Categorize(Chunk.FullStr[Chunk.PosStart]);
  end;

  procedure FindChunk(var Chunk: TChunk); inline;
  begin
    Chunk.PosEnd := Chunk.PosStart;
    repeat
      Inc(Chunk.PosEnd);
    until (Chunk.PosEnd > Length(Chunk.FullStr)) or
          (Categorize(Chunk.FullStr[Chunk.PosEnd]) <> Chunk.Category);
  end;

  procedure PrepareChunk(var Chunk: TChunk); inline;
  begin
    Chunk.Str := Copy(Chunk.FullStr, Chunk.PosStart, Chunk.PosEnd - Chunk.PosStart);
  end;

  procedure PrepareNumberChunk(var Chunk: TChunk); inline;
  begin
    // 跳过前导零，使 "007" 和 "7" 视为相等
    while (Chunk.PosStart < Chunk.PosEnd) and
          (Chunk.FullStr[Chunk.PosStart] = '0') do
      Inc(Chunk.PosStart);
    PrepareChunk(Chunk);
  end;

begin
  Chunk1.FullStr := A;
  Chunk2.FullStr := B;
  Chunk1.PosEnd  := 1;
  Chunk2.PosEnd  := 1;

  NextChunkInit(Chunk1);
  NextChunkInit(Chunk2);
  FindChunk(Chunk1);
  FindChunk(Chunk2);

  // 若一方是数字段、另一方是字符串段，按字符串处理以保持自然位置
  if (Chunk1.Category = cNumber) xor (Chunk2.Category = cNumber) then
    Chunk1.Category := cString;

  while True do
  begin
    case Chunk1.Category of
      cString:
        begin
          PrepareChunk(Chunk1);
          PrepareChunk(Chunk2);
          Result := AnsiCompareText(Chunk1.Str, Chunk2.Str);
          if Result <> 0 then Exit;
        end;
      cNumber:
        begin
          PrepareNumberChunk(Chunk1);
          PrepareNumberChunk(Chunk2);
          // 先比长度（去前导零后位数多的更大），再按字典序
          Result := Length(Chunk1.Str) - Length(Chunk2.Str);
          if Result <> 0 then Exit;
          Result := CompareStr(Chunk1.Str, Chunk2.Str);
          if Result <> 0 then Exit;
        end;
      cNone:
        begin
          // 所有段相等，最终回退到大小写不敏感全串比较
          Result := AnsiCompareText(A, B);
          Exit;
        end;
    end;

    NextChunkInit(Chunk1);
    NextChunkInit(Chunk2);

    if (Chunk1.Category = cNone) and (Chunk2.Category = cNone) then
    begin
      Result := 0;
      Exit;
    end;

    if Chunk1.Category <> Chunk2.Category then
    begin
      if Chunk1.Category < Chunk2.Category then Result := -1
      else Result := 1;
      Exit;
    end;

    FindChunk(Chunk1);
    FindChunk(Chunk2);
  end;
end;

end.
