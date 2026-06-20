unit uGlobs;
// [独立版存根] 替代 DC 的 uGlobs
//
// [整合改动] 原本承担的“子对话框窗口状态持久化”职责（InitPropStorage +
// LFM 的 SessionProperties）以及 gMulRenPathRangeSeparator 全局变量，
// 已并入 uMRConfig.TMRConfig，统一通过 MRConfig 读写同一份 multirename.ini。
// 本单元现在只保留热键管理相关的全局状态，不再是配置持久化的另一个入口。

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls,
  uKeyboard,       // KeyModifiersShortcutNoText
  uHotkeyManager;  // THotKeyManager

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

initialization
  HotMan := THotKeyManager.Create;
  gKeyTyping[ktmNone]    := ktaQuickSearch;
  gKeyTyping[ktmAlt]     := ktaNone;
  gKeyTyping[ktmCtrlAlt] := ktaQuickFilter;

finalization
  FreeAndNil(HotMan);

end.
