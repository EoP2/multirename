unit uMRConfig;

{$mode objfpc}{$H+}

// 替代 DC 的 uGlobs，只保留批量重命名需要的配置项。
// 全部数据（全局设置、列宽、预设）统一用标准 TIniFile 写入单一文件，
// 不依赖 DCXmlConfig，也不再生成 session.ini / presets.xml。
//
// Find/Replace 字段可能含换行、等号等 INI 特殊字符，写入时做 Base64 编码，
// 读取时对应解码，键名加 _B64 后缀以便区分（未编码的旧数据仍可兼容读取）。

interface

uses
  SysUtils, Classes, IniFiles, base64;

type
  TMulRenLaunchBehavior     = (mrlbLastMaskUnderLastOne, mrlbLastPreset, mrlbFreshNew);
  TMulRenExitModifiedPreset = (mrempIgnoreSaveLast, mrempPromptUser, mrempSaveAutomatically);
  TMulRenSaveRenamingLog    = (mrsrlPerPreset, mrsrlAppendSameLog);
  // 添加文件时的排序方式
  TMulRenAddSortOrder       = (mrsoNameAsc, mrsoNameDesc, mrsoTimeAsc, mrsoTimeDesc, mrsoNone);

  // 单个预设的纯数据载体（不含界面逻辑，供 TMRConfig 持有）
  TPresetData = class
    PresetName    : string;
    FileName      : string;
    Extension     : string;
    FileNameStyle : integer;
    ExtensionStyle: integer;
    Find          : string;
    Replace       : string;
    RepExt        : boolean;
    RegExp        : boolean;
    UseSubs       : boolean;
    CaseSens      : boolean;
    OnlyFirst     : boolean;
    Counter       : string;
    Interval      : string;
    Width         : integer;
    Log           : boolean;
    LogAppend     : boolean;
    LogFile       : string;
    constructor Create;
  end;

  TMRConfig = class
  private
    FIniPath: string;
    function  B64Enc(const S: string): string;
    function  B64Dec(const S: string): string;
    procedure WriteStr64(Ini: TIniFile; const Section, Key, Value: string);
    function  ReadStr64(Ini: TIniFile; const Section, Key, Default: string): string;
  public
    // ── 全局设置 ──────────────────────────────────────────────
    InvalidCharReplacement  : string;
    LaunchBehavior          : TMulRenLaunchBehavior;
    ExitModifiedPreset      : TMulRenExitModifiedPreset;
    SaveRenamingLog         : TMulRenSaveRenamingLog;
    LogFilename             : string;
    DailyIndividualDirLog   : Boolean;
    FilenameWithFullPathInLog: Boolean;
    PathRangeSeparator      : string;
    AddSortOrder            : TMulRenAddSortOrder;
    // ── 历史记录 ──────────────────────────────────────────────
    NameMaskHistory         : TStringList;
    ExtMaskHistory          : TStringList;
    // ── 列宽（原 session.ini）─────────────────────────────────
    ColWidth0               : integer;
    ColWidth1               : integer;
    ColWidth2               : integer;
    // ── 窗口几何 ──────────────────────────────────────────────
    WinLeft                 : integer;  // 0 = 未保存，使用默认值
    WinTop                  : integer;
    WinWidth                : integer;
    WinHeight               : integer;
    WinMaximized            : boolean;
    PnlOptionsLeftWidth     : integer;  // 左侧选项面板宽度
    GbNameWidth             : integer;  // "文件名"分组宽度（文件名/扩展名分隔条位置）
    // ── 预设（原 presets.xml）────────────────────────────────
    LastPreset              : string;
    Presets                 : TList;   // list of TPresetData, owned by this object
    // ── 启动参数（运行时中转，不持久化）──────────────────────
    StartupPaths            : TStringList;
    StartupPreset           : string;

    constructor Create(const AIniPath: string);
    destructor  Destroy; override;
    procedure   Load;
    procedure   Save;
    // 预设辅助
    function  FindPreset(const AName: string): integer;
    procedure ClearPresets;
  end;

var
  MRConfig: TMRConfig;

implementation

{ TPresetData }

constructor TPresetData.Create;
begin
  inherited Create;
  FileName      := '[N]';
  Extension     := '[E]';
  FileNameStyle := 0;
  ExtensionStyle:= 0;
  Find          := '';
  Replace       := '';
  RepExt        := True;
  RegExp        := False;
  UseSubs       := False;
  CaseSens      := False;
  OnlyFirst     := False;
  Counter       := '1';
  Interval      := '1';
  Width         := 0;
  Log           := False;
  LogAppend     := False;
  LogFile       := '';
end;

{ TMRConfig – private helpers }

// 将任意字符串 Base64 编码为纯 ASCII（无换行）
function TMRConfig.B64Enc(const S: string): string;
begin
  Result := EncodeStringBase64(S);
end;

// Base64 解码
function TMRConfig.B64Dec(const S: string): string;
begin
  Result := DecodeStringBase64(S);
end;

// 写字符串时使用 Base64，键名加 _B64 后缀
procedure TMRConfig.WriteStr64(Ini: TIniFile; const Section, Key, Value: string);
begin
  Ini.WriteString(Section, Key + '_B64', B64Enc(Value));
  // 同时删除旧的明文键（如果有），避免读取时被旧值覆盖
  Ini.DeleteKey(Section, Key);
end;

// 读取：优先读 _B64 键并解码；若不存在则读裸键（兼容旧数据）
function TMRConfig.ReadStr64(Ini: TIniFile; const Section, Key, Default: string): string;
var
  Encoded: string;
begin
  if Ini.ValueExists(Section, Key + '_B64') then
  begin
    Encoded := Ini.ReadString(Section, Key + '_B64', '');
    Result  := B64Dec(Encoded);
  end
  else
    Result := Ini.ReadString(Section, Key, Default);
end;

{ TMRConfig }

constructor TMRConfig.Create(const AIniPath: string);
begin
  FIniPath := AIniPath;
  // 全局设置默认值
  InvalidCharReplacement    := '.';
  LaunchBehavior            := mrlbFreshNew;
  ExitModifiedPreset        := mrempIgnoreSaveLast;
  SaveRenamingLog           := mrsrlPerPreset;
  LogFilename               := ExtractFilePath(AIniPath) + 'multirename.log';
  DailyIndividualDirLog     := True;
  FilenameWithFullPathInLog := False;
  PathRangeSeparator        := ' - ';
  AddSortOrder              := mrsoNameAsc;
  // 列宽默认值（0 = 使用控件自身默认）
  ColWidth0 := 0;
  ColWidth1 := 0;
  ColWidth2 := 0;
  // 窗口几何（0 表示未保存，由 LFM 默认值或系统决定）
  WinLeft             := 0;
  WinTop              := 0;
  WinWidth            := 0;
  WinHeight           := 0;
  WinMaximized        := False;
  PnlOptionsLeftWidth := 0;
  GbNameWidth         := 0;
  // 预设
  LastPreset := '';
  Presets    := TList.Create;
  // 历史
  NameMaskHistory := TStringList.Create;
  ExtMaskHistory  := TStringList.Create;
  // 运行时
  StartupPaths  := TStringList.Create;
  StartupPreset := '';
end;

destructor TMRConfig.Destroy;
begin
  ClearPresets;
  Presets.Free;
  NameMaskHistory.Free;
  ExtMaskHistory.Free;
  StartupPaths.Free;
  inherited;
end;

function TMRConfig.FindPreset(const AName: string): integer;
var
  I: integer;
begin
  Result := -1;
  for I := 0 to Presets.Count - 1 do
    if TPresetData(Presets[I]).PresetName = AName then
    begin
      Result := I;
      Exit;
    end;
end;

procedure TMRConfig.ClearPresets;
var
  I: integer;
begin
  for I := 0 to Presets.Count - 1 do
    TPresetData(Presets[I]).Free;
  Presets.Clear;
end;

procedure TMRConfig.Load;
var
  Ini  : TIniFile;
  I, N : Integer;
  Sec  : string;
  PD   : TPresetData;
begin
  if not FileExists(FIniPath) then Exit;
  Ini := TIniFile.Create(FIniPath);
  try
    // ── 全局设置 ──────────────────────────────────────────────
    InvalidCharReplacement    := Ini.ReadString ('MultiRename', 'InvalidCharReplacement',    InvalidCharReplacement);
    LaunchBehavior            := TMulRenLaunchBehavior(
                                   Ini.ReadInteger('MultiRename', 'LaunchBehavior',           Ord(LaunchBehavior)));
    ExitModifiedPreset        := TMulRenExitModifiedPreset(
                                   Ini.ReadInteger('MultiRename', 'ExitModifiedPreset',       Ord(ExitModifiedPreset)));
    SaveRenamingLog           := TMulRenSaveRenamingLog(
                                   Ini.ReadInteger('MultiRename', 'SaveRenamingLog',          Ord(SaveRenamingLog)));
    LogFilename               := Ini.ReadString ('MultiRename', 'LogFilename',               LogFilename);
    DailyIndividualDirLog     := Ini.ReadBool   ('MultiRename', 'DailyIndividualDirLog',     DailyIndividualDirLog);
    FilenameWithFullPathInLog := Ini.ReadBool   ('MultiRename', 'FilenameWithFullPathInLog', FilenameWithFullPathInLog);
    PathRangeSeparator        := Ini.ReadString ('MultiRename', 'PathRangeSeparator',        PathRangeSeparator);
    AddSortOrder              := TMulRenAddSortOrder(
                                   Ini.ReadInteger('MultiRename', 'AddSortOrder',             Ord(AddSortOrder)));

    // ── 列宽（原 session.ini）────────────────────────────────
    ColWidth0 := Ini.ReadInteger('Session', 'ColWidth0', 0);
    ColWidth1 := Ini.ReadInteger('Session', 'ColWidth1', 0);
    ColWidth2 := Ini.ReadInteger('Session', 'ColWidth2', 0);
    // ── 窗口几何 ─────────────────────────────────────────────
    WinLeft             := Ini.ReadInteger('Session', 'WinLeft',             0);
    WinTop              := Ini.ReadInteger('Session', 'WinTop',              0);
    WinWidth            := Ini.ReadInteger('Session', 'WinWidth',            0);
    WinHeight           := Ini.ReadInteger('Session', 'WinHeight',           0);
    WinMaximized        := Ini.ReadBool   ('Session', 'WinMaximized',        False);
    PnlOptionsLeftWidth := Ini.ReadInteger('Session', 'PnlOptionsLeftWidth', 0);
    GbNameWidth         := Ini.ReadInteger('Session', 'GbNameWidth',         0);

    // ── 历史记录 ──────────────────────────────────────────────
    NameMaskHistory.Clear;
    N := Ini.ReadInteger('NameMaskHistory', 'Count', 0);
    for I := 0 to N - 1 do
      NameMaskHistory.Add(Ini.ReadString('NameMaskHistory', 'Item' + IntToStr(I), ''));

    ExtMaskHistory.Clear;
    N := Ini.ReadInteger('ExtMaskHistory', 'Count', 0);
    for I := 0 to N - 1 do
      ExtMaskHistory.Add(Ini.ReadString('ExtMaskHistory', 'Item' + IntToStr(I), ''));

    // ── 预设（原 presets.xml）────────────────────────────────
    ClearPresets;
    LastPreset := Ini.ReadString('Presets', 'LastPreset', '');
    N := Ini.ReadInteger('Presets', 'Count', 0);
    for I := 0 to N - 1 do
    begin
      Sec := 'Preset_' + IntToStr(I);
      PD  := TPresetData.Create;
      PD.PresetName    := ReadStr64(Ini, Sec, 'Name',          '');
      PD.FileName      := ReadStr64(Ini, Sec, 'Filename',      '[N]');
      PD.Extension     := ReadStr64(Ini, Sec, 'Extension',     '[E]');
      PD.FileNameStyle := Ini.ReadInteger(Sec, 'FilenameStyle',  0);
      PD.ExtensionStyle:= Ini.ReadInteger(Sec, 'ExtensionStyle', 0);
      PD.Find          := ReadStr64(Ini, Sec, 'Find',          '');
      PD.Replace       := ReadStr64(Ini, Sec, 'Replace',       '');
      PD.RepExt        := Ini.ReadBool   (Sec, 'RepExt',         True);
      PD.RegExp        := Ini.ReadBool   (Sec, 'RegExp',         False);
      PD.UseSubs       := Ini.ReadBool   (Sec, 'UseSubs',        False);
      PD.CaseSens      := Ini.ReadBool   (Sec, 'CaseSensitive',  False);
      PD.OnlyFirst     := Ini.ReadBool   (Sec, 'OnlyFirst',      False);
      PD.Counter       := Ini.ReadString (Sec, 'Counter',        '1');
      PD.Interval      := Ini.ReadString (Sec, 'Interval',       '1');
      PD.Width         := Ini.ReadInteger(Sec, 'Width',          0);
      PD.Log           := Ini.ReadBool   (Sec, 'LogEnabled',     False);
      PD.LogAppend     := Ini.ReadBool   (Sec, 'LogAppend',      False);
      PD.LogFile       := ReadStr64(Ini, Sec, 'LogFile',       '');
      if PD.PresetName <> '' then
        Presets.Add(PD)
      else
        PD.Free;   // 跳过名称为空的损坏条目
    end;
  finally
    Ini.Free;
  end;
end;

procedure TMRConfig.Save;
var
  Ini : TIniFile;
  I   : Integer;
  Sec : string;
  PD  : TPresetData;
begin
  Ini := TIniFile.Create(FIniPath);
  try
    // ── 全局设置 ──────────────────────────────────────────────
    Ini.WriteString ('MultiRename', 'InvalidCharReplacement',    InvalidCharReplacement);
    Ini.WriteInteger('MultiRename', 'LaunchBehavior',            Ord(LaunchBehavior));
    Ini.WriteInteger('MultiRename', 'ExitModifiedPreset',        Ord(ExitModifiedPreset));
    Ini.WriteInteger('MultiRename', 'SaveRenamingLog',           Ord(SaveRenamingLog));
    Ini.WriteString ('MultiRename', 'LogFilename',               LogFilename);
    Ini.WriteBool   ('MultiRename', 'DailyIndividualDirLog',     DailyIndividualDirLog);
    Ini.WriteBool   ('MultiRename', 'FilenameWithFullPathInLog', FilenameWithFullPathInLog);
    Ini.WriteString ('MultiRename', 'PathRangeSeparator',        PathRangeSeparator);
    Ini.WriteInteger('MultiRename', 'AddSortOrder',              Ord(AddSortOrder));

    // ── 列宽（原 session.ini）────────────────────────────────
    Ini.WriteInteger('Session', 'ColWidth0', ColWidth0);
    Ini.WriteInteger('Session', 'ColWidth1', ColWidth1);
    Ini.WriteInteger('Session', 'ColWidth2', ColWidth2);
    // ── 窗口几何 ─────────────────────────────────────────────
    Ini.WriteInteger('Session', 'WinLeft',             WinLeft);
    Ini.WriteInteger('Session', 'WinTop',              WinTop);
    Ini.WriteInteger('Session', 'WinWidth',            WinWidth);
    Ini.WriteInteger('Session', 'WinHeight',           WinHeight);
    Ini.WriteBool   ('Session', 'WinMaximized',        WinMaximized);
    Ini.WriteInteger('Session', 'PnlOptionsLeftWidth', PnlOptionsLeftWidth);
    Ini.WriteInteger('Session', 'GbNameWidth',         GbNameWidth);

    // ── 历史记录 ──────────────────────────────────────────────
    Ini.WriteInteger('NameMaskHistory', 'Count', NameMaskHistory.Count);
    for I := 0 to NameMaskHistory.Count - 1 do
      Ini.WriteString('NameMaskHistory', 'Item' + IntToStr(I), NameMaskHistory[I]);

    Ini.WriteInteger('ExtMaskHistory', 'Count', ExtMaskHistory.Count);
    for I := 0 to ExtMaskHistory.Count - 1 do
      Ini.WriteString('ExtMaskHistory', 'Item' + IntToStr(I), ExtMaskHistory[I]);

    // ── 预设（原 presets.xml）────────────────────────────────
    // 先清除所有旧的 Preset_N section，防止预设数减少时残留旧 section
    I := 0;
    while Ini.SectionExists('Preset_' + IntToStr(I)) do
    begin
      Ini.EraseSection('Preset_' + IntToStr(I));
      Inc(I);
    end;

    Ini.WriteString ('Presets', 'LastPreset', LastPreset);
    Ini.WriteInteger('Presets', 'Count', Presets.Count);
    for I := 0 to Presets.Count - 1 do
    begin
      Sec := 'Preset_' + IntToStr(I);
      PD  := TPresetData(Presets[I]);
      WriteStr64(Ini, Sec, 'Name',          PD.PresetName);
      WriteStr64(Ini, Sec, 'Filename',      PD.FileName);
      WriteStr64(Ini, Sec, 'Extension',     PD.Extension);
      Ini.WriteInteger(Sec, 'FilenameStyle',  PD.FileNameStyle);
      Ini.WriteInteger(Sec, 'ExtensionStyle', PD.ExtensionStyle);
      WriteStr64(Ini, Sec, 'Find',          PD.Find);
      WriteStr64(Ini, Sec, 'Replace',       PD.Replace);
      Ini.WriteBool   (Sec, 'RepExt',         PD.RepExt);
      Ini.WriteBool   (Sec, 'RegExp',         PD.RegExp);
      Ini.WriteBool   (Sec, 'UseSubs',        PD.UseSubs);
      Ini.WriteBool   (Sec, 'CaseSensitive',  PD.CaseSens);
      Ini.WriteBool   (Sec, 'OnlyFirst',      PD.OnlyFirst);
      Ini.WriteString (Sec, 'Counter',        PD.Counter);
      Ini.WriteString (Sec, 'Interval',       PD.Interval);
      Ini.WriteInteger(Sec, 'Width',          PD.Width);
      Ini.WriteBool   (Sec, 'LogEnabled',     PD.Log);
      Ini.WriteBool   (Sec, 'LogAppend',      PD.LogAppend);
      WriteStr64(Ini, Sec, 'LogFile',       PD.LogFile);
    end;
  finally
    Ini.Free;
  end;
end;

end.
