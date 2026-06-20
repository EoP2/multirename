unit uGlobs;
// [独立版存根] 替代 DC 的 uGlobs

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, IniPropStorage,
  uKeyboard,       // KeyModifiersShortcutNoText
  uHotkeyManager,  // THotKeyManager
  uMRApp;          // MRGetConfigDir

// ---- 热键文件版本号 (uHotkeyManager 用) ----
const
  hkVersion = 72;

// ---- 全局热键管理器 (uFormCommands 用) ----
var
  HotMan: THotKeyManager;

// ---- 键盘输入模式 (uHotkeyManager 用) ----
type
  TKeyTypingModifier = (ktmNone, ktmAlt, ktmCtrlAlt);
  TKeyTypingAction   = (ktaNone, ktaCommandLine, ktaQuickSearch, ktaQuickFilter);

const
  TKeyTypingModifierToShift: array[TKeyTypingModifier] of TShiftState =
    ([], [ssAlt], [ssCtrl, ssAlt]);

var
  gKeyTyping: array[TKeyTypingModifier] of TKeyTypingAction;

function GetKeyTypingAction(ShiftStateEx: TShiftState): TKeyTypingAction;

// ---- fSelectPathRange 用 ----
var
  gMulRenPathRangeSeparator: string = ' - ';

// ---- 子对话框窗口状态持久化（SessionProperties 后端）----
// 所有窗体共用 multirename.ini，section 名为各自的 ClassName，
// 与主配置的 [MultiRename] / [Session] / [Presets] / [Preset_N] 不冲突。
function InitPropStorage(Owner: TComponent): TIniPropStorage;

implementation

function GetKeyTypingAction(ShiftStateEx: TShiftState): TKeyTypingAction;
var
  Modifier: TKeyTypingModifier;
begin
  for Modifier in TKeyTypingModifier do
    if ShiftStateEx * KeyModifiersShortcutNoText = TKeyTypingModifierToShift[Modifier] then
      Exit(gKeyTyping[Modifier]);
  Result := ktaNone;
end;

function InitPropStorage(Owner: TComponent): TIniPropStorage;
begin
  Result := TIniPropStorage.Create(Owner);
  Result.IniFileName := MRGetConfigDir + 'multirename.ini';
  if Owner <> nil then
    Result.IniSection := Owner.ClassName
  else
    Result.IniSection := 'Default';
end;

initialization
  HotMan := THotKeyManager.Create;
  gKeyTyping[ktmNone]    := ktaQuickSearch;
  gKeyTyping[ktmAlt]     := ktaNone;
  gKeyTyping[ktmCtrlAlt] := ktaQuickFilter;

finalization
  FreeAndNil(HotMan);

end.
