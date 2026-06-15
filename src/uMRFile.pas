unit uMRFile;

{$mode objfpc}{$H+}

// 精简版 TFile / TFiles，替代 DC 的 uFile.pas。
// 只保留 fmultirename.pas 实际使用的属性和方法，
// 去掉 IFileSource、TFileProperty 等 DC 专有依赖。

interface

uses
  SysUtils, Classes, DateUtils;

type
  { TFile }
  TFile = class
  private
    FPath:      string;   // 总带尾部路径分隔符
    FNameNoExt: string;
    FExtension: string;   // 不含点号
    FModificationTime: TDateTime;
    FSize: Int64;
    function  GetName: string;
    function  GetFullPath: string;
    procedure SetName(const AValue: string);
    procedure SetFullPath(const AValue: string);
    procedure SetPath(const AValue: string);
  public
    // 静态辅助
    class procedure SplitIntoNameAndExtension(const AFileName: string;
                      out ANameNoExt, AExt: string);

    constructor Create(const APath: string);
    function Clone: TFile;

    property Path:             string    read FPath             write SetPath;
    property Name:             string    read GetName           write SetName;
    property NameNoExt:        string    read FNameNoExt;
    property Extension:        string    read FExtension;
    property FullPath:         string    read GetFullPath        write SetFullPath;
    property ModificationTime: TDateTime read FModificationTime  write FModificationTime;
    property Size:             Int64     read FSize              write FSize;
  end;

  { TFiles }
  TFiles = class
  private
    FList: TList;
    FPath: string;
    function  GetCount: Integer;
    function  GetItem(Index: Integer): TFile;
    procedure SetItem(Index: Integer; AFile: TFile);
    procedure SetPath(const AValue: string);
  public
    constructor Create(const APath: string);
    destructor  Destroy; override;

    procedure Add(AFile: TFile);
    procedure Delete(Index: Integer);
    procedure Clear;
    function  Clone: TFiles;

    property Count:           Integer  read GetCount;
    property Items[I: Integer]: TFile  read GetItem write SetItem; default;
    property Path:            string   read FPath write SetPath;
  end;

// 从磁盘填充 TFiles（独立版入口）
procedure LoadFilesFromList(AFiles: TFiles; const APaths: array of string);

implementation

uses
  LazFileUtils;

{ TFile }

class procedure TFile.SplitIntoNameAndExtension(const AFileName: string;
  out ANameNoExt, AExt: string);
var
  P: Integer;
begin
  P := Length(AFileName);
  while (P > 0) and (AFileName[P] <> '.') do Dec(P);
  if (P > 1) then
  begin
    ANameNoExt := Copy(AFileName, 1, P - 1);
    AExt       := Copy(AFileName, P + 1, MaxInt); // без точки
  end
  else
  begin
    ANameNoExt := AFileName;
    AExt       := '';
  end;
end;

constructor TFile.Create(const APath: string);
begin
  if APath = '' then
    FPath := ''
  else
    FPath := IncludeTrailingPathDelimiter(APath);
  FNameNoExt := '';
  FExtension := '';
  FModificationTime := 0;
  FSize := 0;
end;

function TFile.GetName: string;
begin
  if FExtension = '' then
    Result := FNameNoExt
  else
    Result := FNameNoExt + '.' + FExtension;
end;

function TFile.GetFullPath: string;
begin
  Result := FPath + Name;
end;

procedure TFile.SetName(const AValue: string);
begin
  SplitIntoNameAndExtension(AValue, FNameNoExt, FExtension);
end;

procedure TFile.SetFullPath(const AValue: string);
begin
  FPath := IncludeTrailingPathDelimiter(ExtractFilePath(AValue));
  Name  := ExtractFileName(AValue);
end;

procedure TFile.SetPath(const AValue: string);
begin
  if AValue = '' then
    FPath := ''
  else
    FPath := IncludeTrailingPathDelimiter(AValue);
end;

function TFile.Clone: TFile;
begin
  Result := TFile.Create(FPath);
  Result.FNameNoExt        := FNameNoExt;
  Result.FExtension        := FExtension;
  Result.FModificationTime := FModificationTime;
  Result.FSize             := FSize;
end;

{ TFiles }

constructor TFiles.Create(const APath: string);
begin
  FList := TList.Create;
  Path  := APath;
end;

destructor TFiles.Destroy;
begin
  Clear;
  FList.Free;
  inherited;
end;

function TFiles.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TFiles.GetItem(Index: Integer): TFile;
begin
  Result := TFile(FList[Index]);
end;

procedure TFiles.SetItem(Index: Integer; AFile: TFile);
begin
  FList[Index] := AFile;
end;

procedure TFiles.SetPath(const AValue: string);
begin
  if AValue = '' then
    FPath := ''
  else
    FPath := IncludeTrailingPathDelimiter(AValue);
end;

procedure TFiles.Add(AFile: TFile);
begin
  FList.Add(AFile);
end;

procedure TFiles.Delete(Index: Integer);
begin
  TFile(FList[Index]).Free;
  FList.Delete(Index);
end;

procedure TFiles.Clear;
var
  I: Integer;
begin
  for I := FList.Count - 1 downto 0 do
    TFile(FList[I]).Free;
  FList.Clear;
end;

function TFiles.Clone: TFiles;
var
  I: Integer;
begin
  Result := TFiles.Create(FPath);
  for I := 0 to Count - 1 do
    Result.Add(Items[I].Clone);
end;

{ LoadFilesFromList }

procedure LoadFilesFromList(AFiles: TFiles; const APaths: array of string);
var
  F: TFile;
  SR: TSearchRec;
  I: Integer;
  APath, AName: string;
begin
  AFiles.Clear;
  for I := 0 to High(APaths) do
  begin
    APath := APaths[I];
    AName := ExtractFileName(APath);
    F := TFile.Create(ExtractFilePath(APath));
    F.Name := AName;
    if FindFirst(APath, faAnyFile, SR) = 0 then
    begin
      F.ModificationTime := FileDateToDateTime(SR.Time);
      F.Size             := SR.Size;
      FindClose(SR);
    end;
    AFiles.Add(F);
  end;
end;

end.
