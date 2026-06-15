{
   Double Commander
   -------------------------------------------------------------------------
   Multi-Rename Tool dialog window

   Copyright (C) 2007-2025 Alexander Koblov (alexx2000@mail.ru)

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>.


   Original comment:
   ----------------------------
   Seksi Commander
   ----------------------------
   Licence  : GNU GPL v 2.0
   Author   : Pavel Letko (letcuv@centrum.cz)

   Advanced multi rename tool

   contributors:

   Copyright (C) 2007-2018 Alexander Koblov (alexx2000@mail.ru)
}

unit fMultiRename;

{$mode objfpc}{$H+}

interface

uses
  //Lazarus, Free-Pascal, etc.
  LazUtf8, SysUtils, Classes, Graphics, Forms, StdCtrls, Menus, Controls,
  LCLType, StringHashList, Grids, ExtCtrls, Buttons, ActnList, EditBtn,
  KASButton, KASToolPanel,

  //独立版替代单元
  uRegExprW,            // 正则表达式（原样带走）
  uFormCommands,        // cm_xxx 热键系统（原样带走）
  uHotkeyManager,       // 同上
  uGlobs,               // HotMan 全局热键管理器（独立版存根）
  DCStringHashListUtf8, // TStringHashListUtf8（原样带走）
  uMRFile,              // 替代 uFile + uFileSource（TFile/TFiles）
  uMRConfig,            // 替代 uGlobs 中的 gMulXxx 全局变量
  uMRApp,               // 独立版应用名/配置目录
  uMRStrings,           // 替代 uLng（rs 字符串常量）
  uMRUtils,             // 替代 DCOSUtils/DCStrUtils/uDCUtils/uFileProcs
  uMRRename;            // 替代 IFileSource + OperationsManager

const
  HotkeysCategoryMultiRename = 'MultiRename'; // <--Not displayed to user, stored in .scf (Shortcut Configuration File)

type
  { TMultiRenamePreset }
  TMultiRenamePreset = class(TObject)
  private
    FPresetName: string;
    FFileName: string;
    FExtension: string;
    FFileNameStyle: integer;
    FExtensionStyle: integer;
    FFind: string;
    FReplace: string;
    FRepExt: Boolean;
    FRegExp: boolean;
    FUseSubs: boolean;
    FCaseSens: Boolean;
    FOnlyFirst: Boolean;
    FCounter: string;
    FInterval: string;
    FWidth: integer;
    FLog: boolean;
    FLogFile: string;
    FLogAppend: boolean;
  public
    property PresetName: string read FPresetName write FPresetName;
    property FileName: string read FFileName write FFileName;
    property Extension: string read FExtension write FExtension;
    property FileNameStyle: integer read FFileNameStyle write FFileNameStyle;
    property ExtensionStyle: integer read FExtensionStyle write FExtensionStyle;
    property Find: string read FFind write FFind;
    property Replace: string read FReplace write FReplace;
    property RepExt: boolean read FRepExt write FRepExt;
    property RegExp: boolean read FRegExp write FRegExp;
    property UseSubs: boolean read FUseSubs write FUseSubs;
    property CaseSens: Boolean read FCaseSens write FCaseSens;
    property OnlyFirst: Boolean read FOnlyFirst write FOnlyFirst;
    property Counter: string read FCounter write FCounter;
    property Interval: string read FInterval write FInterval;
    property Width: integer read FWidth write FWidth;
    property Log: boolean read FLog write FLog;
    property LogFile: string read FLogFile write FLogFile;
    property LogAppend: boolean read FLogAppend write FLogAppend;
    constructor Create;
    destructor Destroy; override;
  end;

  { TMultiRenamePresetList }
  TMultiRenamePresetList = class(TList)
  private
    function GetMultiRenamePreset(Index: integer): TMultiRenamePreset;
  public
    property MultiRenamePreset[Index: integer]: TMultiRenamePreset read GetMultiRenamePreset;
    procedure Delete(Index: integer);
    procedure Clear; override;
    function Find(sPresetName: string): integer;
  end;

  { tTargetForMask }
  //Used to indicate of a mask is used for the "Filename" or the "Extension".
  tTargetForMask = (tfmFilename, tfmExtension);

  { tRenameMaskToUse }
  //Used as a parameter type to indicate the kind of field the mask is related to.
  // [独立版] 去掉 rmtuPlugins
  tRenameMaskToUse = (rmtuFilename, rmtuExtension, rmtuCounter, rmtuDate, rmtuTime);

  { tSourceOfInformation }
  // [独立版] 去掉 soiPlugins
  tSourceOfInformation = (soiFilename, soiExtension, soiCounter, soiGUID, soiVariable, soiDate, soiTime, soiFullName, soiPath);

  { tMenuActionStyle }
  //Used to help to group common or similar action done for each mask.
  tMenuActionStyle = (masStraight, masXYCharacters, masAskVariable, masDirectorySelector);

  { TfrmMultiRename }
  // [独立版] TAloneForm -> TForm（去掉 DC 的平台窗口基类）
  TfrmMultiRename = class(TForm, IFormCommands)
    cbCaseSens: TCheckBox;
    cbRegExp: TCheckBox;
    cbUseSubs: TCheckBox;
    cbOnlyFirst: TCheckBox;
    cbRepExt: TCheckBox;
    pnlFindReplace: TPanel;
    pnlButtons: TPanel;
    StringGrid: TStringGrid;
    pnlOptions: TPanel;
    pnlOptionsLeft: TPanel;
    gbMaska: TGroupBox;
    lbName: TLabel;
    cbName: TComboBox;
    btnAnyNameMask: TKASButton;
    cbNameMaskStyle: TComboBox;
    lbExt: TLabel;
    cbExt: TComboBox;
    btnAnyExtMask: TKASButton;
    cmbExtensionStyle: TComboBox;
    gbPresets: TGroupBox;
    cbPresets: TComboBox;
    btnPresets: TKASButton;
    // 排序选项（gbPresets 下方）
    gbAddSort: TGroupBox;
    cmbAddSort: TComboBox;
    spltMainSplitter: TSplitter;
    pnlOptionsRight: TKASToolPanel;
    gbFindReplace: TGroupBox;
    lbFind: TLabel;
    edFind: TEdit;
    lbReplace: TLabel;
    edReplace: TEdit;
    gbCounter: TGroupBox;
    lbStNb: TLabel;
    edPoc: TEdit;
    lbInterval: TLabel;
    edInterval: TEdit;
    lbWidth: TLabel;
    cmbxWidth: TComboBox;
    btnRestore: TBitBtn;
    btnRename: TBitBtn;
    btnConfig: TBitBtn;
    btnEditor: TBitBtn;
    btnClose: TBitBtn;
    cbLog: TCheckBox;
    cbLogAppend: TCheckBox;
    fneRenameLogFileFilename: TFileNameEdit;
    btnViewRenameLogFile: TSpeedButton;
    pmPresets: TPopupMenu;
    pmFloatingMainMaskMenu: TPopupMenu;
    pmDynamicMasks: TPopupMenu;
    pmEditDirect: TPopupMenu;
    mnuLoadFromFile: TMenuItem;
    mnuEditNames: TMenuItem;
    mnuEditNewNames: TMenuItem;
    actList: TActionList;
    actResetAll: TAction;
    actInvokeEditor: TAction;
    actLoadNamesFromFile: TAction;
    actLoadNamesFromClipboard: TAction;
    actEditNames: TAction;
    actEditNewNames: TAction;
    actConfig: TAction;
    actAddFiles: TAction;
    actRename: TAction;
    actClose: TAction;
    actShowPresetsMenu: TAction;
    actDropDownPresetList: TAction;
    actLoadLastPreset: TAction;
    actLoadPreset: TAction;
    actSavePreset: TAction;
    actSavePresetAs: TAction;
    actRenamePreset: TAction;
    actDeletePreset: TAction;
    actSortPresets: TAction;
    actAnyNameMask: TAction;
    actClearNameMask: TAction;
    actAnyExtMask: TAction;
    actClearExtMask: TAction;
    actViewRenameLogFile: TAction;
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormCloseQuery({%H-}Sender: TObject; var CanClose: boolean);
    procedure FormClose({%H-}Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure StringGridKeyDown({%H-}Sender: TObject; var Key: word; Shift: TShiftState);
    procedure StringGridMouseDown({%H-}Sender: TObject; Button: TMouseButton; {%H-}Shift: TShiftState; X, Y: integer);
    procedure StringGridMouseUp({%H-}Sender: TObject; Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: integer);
    procedure StringGridSelection({%H-}Sender: TObject; {%H-}aCol, aRow: integer);
    procedure StringGridTopLeftChanged({%H-}Sender: TObject);
    procedure cbNameStyleChange({%H-}Sender: TObject);
    procedure cbPresetsChange({%H-}Sender: TObject);
    procedure cbPresetsCloseUp({%H-}Sender: TObject);
    procedure edFindChange({%H-}Sender: TObject);
    procedure edReplaceChange({%H-}Sender: TObject);
    procedure cbRegExpChange({%H-}Sender: TObject);
    procedure edPocChange({%H-}Sender: TObject);
    procedure edIntervalChange({%H-}Sender: TObject);
    procedure cbLogClick({%H-}Sender: TObject);
    procedure cmbAddSortChange({%H-}Sender: TObject);
    procedure actExecute(Sender: TObject);
  private
    FCommands: TFormCommands;
    FActuallyRenamingFile: boolean;
    FSourceRow: integer;
    FMoveRow: boolean;
    // [独立版] 去掉 FFileSource: IFileSource 和 FPluginDispatcher
    FFiles: TFiles;
    FNewNames: TStringHashListUtf8;
    FOldNames: TStringHashListUtf8;
    FNames: TStringList;
    FslVariableNames, FslVariableValues, FslVariableSuggestionName, FslVariableSuggestionValue: TStringList;
    FRegExp: TRegExprW;
    FFindText: TStringList;
    FReplaceText: TStringList;
    FMultiRenamePresetList: TMultiRenamePresetList;
    FParamPresetToLoadOnStart: string;
    FLastPreset: string;
    FbRememberLog, FbRememberAppend: boolean;
    FsRememberRenameLogFilename: string;
    FLog: TStringList;  // 替代 TStringList（方法完全兼容）
    property Commands: TFormCommands read FCommands implements IFormCommands;
    procedure RestoreProperties(Sender: TObject);
    procedure SetConfigurationState(bConfigurationSaved: boolean);
    function GetPresetNameForCommand(const Params: array of string): string;
    function isOkToLosePresetModification: boolean;
    procedure SavePreset(PresetName: string);
    procedure SavePresetsToConfig;
    procedure AddFilesToList(const APaths: array of string);
    procedure SortFileList;
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure SavePresets;
    procedure LoadPresetsFromConfig;
    procedure DeletePreset(PresetName: string);
    procedure FillPresetsList(const WantedSelectedPresetName: string = '');
    procedure RefreshActivePresetCommands;
    procedure InitializeMaskHelper;
    procedure PopulateFilenameMenu(AMenuSomething: TPopupMenu);
    procedure PopulateExtensionMenu(AMenuSomething: TPopupMenu);
    procedure BuildMaskMenu(AMenuSomething: TMenuItem; iTarget: tTargetForMask; iMenuTypeMask: tRenameMaskToUse);
    procedure BuildPresetsMenu(AMenuSomething: TPopupMenu);
    function GetMaskCategoryName(aRenameMaskToUse: tRenameMaskToUse): string;
    function GetImageIndexCategoryName(aRenameMaskToUse: tRenameMaskToUse): integer;
    function AppendSubMenuToThisMenu(ATargetMenu: TMenuItem; sCaption: string; iImageIndex: integer): TMenuItem;
    function AppendActionMenuToThisMenu(ATargetMenu: TMenuItem; paramAction: TAction): TMenuItem;
    procedure MenuItemXCharactersMaskClick(Sender: TObject);
    procedure MenuItemVariableMaskClick(Sender: TObject);
    procedure MenuItemStraightMaskClick(Sender: TObject);
    procedure MenuItemDirectorySelectorMaskClick(Sender: TObject);
    procedure PopupDynamicMenuAtThisControl(APopUpMenu: TPopupMenu; AControl: TControl);
    procedure miPluginClick(Sender: TObject);  // 保留声明，实现改为空
    procedure InsertMask(const Mask: string; edChoose: TComboBox);
    procedure InsertMask(const Mask: string; TargetForMask: tTargetForMask);
    function sReplace(sMask: string; ItemNr: integer): string;
    function sReplaceXX(const sFormatStr, sOrig: string): string;
    function sReplaceVariable(const sFormatStr: string): string;
    function sReplaceBadChars(const sPath: string): string;
    function IsLetter(AChar: AnsiChar): boolean;
    function ApplyStyle(InputString: string; Style: integer): string;
    function FirstCharToUppercaseUTF8(InputString: string): string;
    function FirstCharOfFirstWordToUppercaseUTF8(InputString: string): string;
    function FirstCharOfEveryWordToUppercaseUTF8(InputString: string): string;
    procedure LoadNamesFromList(const AFileList: TStrings);
    procedure LoadNamesFromFile(const AFileName: string);
    function FreshText(ItemIndex: integer): string;
    function sHandleFormatString(const sFormatStr: string; ItemNr: integer): string;
    procedure SetOutputGlobalRenameLogFilename;
    // [独立版] 辅助函数
    function mbExpandFileName(const s: string): string;
  public
    { Public declarations }
    constructor Create(TheOwner: TComponent); override;
    // [独立版] aFileSource/aFiles 参数替换为文件路径数组
    constructor Create(TheOwner: TComponent; const AFilePaths: TStringList; const paramPreset: string); reintroduce;
    destructor Destroy; override;
  published
    procedure cm_ResetAll(const Params: array of string);
    procedure cm_InvokeEditor(const {%H-}Params: array of string);
    procedure cm_LoadNamesFromFile(const {%H-}Params: array of string);
    procedure cm_LoadNamesFromClipboard(const {%H-}Params: array of string);
    procedure cm_EditNames(const {%H-}Params: array of string);
    procedure cm_EditNewNames(const {%H-}Params: array of string);
    procedure cm_Config(const {%H-}Params: array of string);
    procedure cm_AddFiles(const {%H-}Params: array of string);
    procedure cm_Rename(const {%H-}Params: array of string);
    procedure cm_Close(const {%H-}Params: array of string);
    procedure cm_ShowPresetsMenu(const {%H-}Params: array of string);
    procedure cm_DropDownPresetList(const {%H-}Params: array of string);
    procedure cm_LoadPreset(const Params: array of string);
    procedure cm_LoadLastPreset(const {%H-}Params: array of string);
    procedure cm_SavePreset(const Params: array of string);
    procedure cm_SavePresetAs(const Params: array of string);
    procedure cm_RenamePreset(const Params: array of string);
    procedure cm_DeletePreset(const Params: array of string);
    procedure cm_SortPresets(const Params: array of string);
    procedure cm_AnyNameMask(const {%H-}Params: array of string);
    procedure cm_ClearNameMask(const {%H-}Params: array of string);
    procedure cm_AnyExtMask(const {%H-}Params: array of string);
    procedure cm_ClearExtMask(const {%H-}Params: array of string);
    procedure cm_ViewRenameLogFile(const {%H-}Params: array of string);
  end;

{initialization function}
// [独立版] 接收文件路径列表替代 IFileSource + TFiles
function ShowMultiRenameForm(const AFilePaths: TStringList; const PresetToLoad: string = ''): boolean;

implementation

{$R *.lfm}

uses
  //Lazarus, Free-Pascal, etc.
  Dialogs, Math, Clipbrd,
  LazFileUtils,    // ForceDirectories, path helpers
  LCLIntf,         // OpenDocument
  DateUtils,       // FileDateToDateTime

  //独立版
  fSelectTextRange, fSelectPathRange,
  fMultiRenameWait, fSortAnything;

type
  tMaskHelper = record
    sMenuItem: string;
    sKeyword: string;
    MenuActionStyle: tMenuActionStyle;
    iMenuType: tRenameMaskToUse;
    iSourceOfInformation: tSourceOfInformation;
  end;

const
  sPresetsSection = 'MultiRenamePresets';
  sLASTPRESET = '{BC322BF1-2185-47F6-9F99-D27ED1E23E53}';
  sFRESHMASKS = '{40422152-9D05-469E-9B81-791AF8C369D8}';
  iTARGETMASK = $00000001;

  sREFRESHCOMMANDS = 'refreshcommands';
  sDEFAULTLOGFILENAME = 'default.log';

  CONFIG_NOTSAVED = False;
  CONFIG_SAVED = True;

  NBMAXHELPERS = 28;

var
  //Sequence of operation to add a new mask:
  // 1. Add its entry below in the "MaskHelpers" array.
  // 2. Go immediately set its translatable string for the user in the function "InitializeMaskHelper" and the text in unit "uLng".
  // 3. When editing "InitializeMaskHelper", make sure to update the TWO columns of indexes.
  // 4. In the procedure "BuildMaskMenu", there is good chance you need to associated to the "AMenuItem.OnClick" the correct function based on "MaskHelpers[iSeekIndex].MenuActionStyle".
  // 5. If it's a NEW procedure, you'll need to write it. You may check "MenuItemXCharactersMaskClick" for inspiration.
  // 6. There is good chance you need to edit "sHandleFormatString" to add your new mask and action to do with it.

  MaskHelpers: array[0..pred(NBMAXHELPERS)] of tMaskHelper =
    (
    (sMenuItem: ''; sKeyword: '[N]'; MenuActionStyle: masStraight; iMenuType: rmtuFilename; iSourceOfInformation: soiFilename),
    (sMenuItem: ''; sKeyword: '[Nx:y]'; MenuActionStyle: masXYCharacters; iMenuType: rmtuFilename; iSourceOfInformation: soiFilename),
    (sMenuItem: ''; sKeyword: '[A]'; MenuActionStyle: masStraight; iMenuType: rmtuFilename; iSourceOfInformation: soiFullName),
    (sMenuItem: ''; sKeyword: '[Ax:y]'; MenuActionStyle: masXYCharacters; iMenuType: rmtuFilename; iSourceOfInformation: soiFullName),
    (sMenuItem: ''; sKeyword: '[P]'; MenuActionStyle: masDirectorySelector; iMenuType: rmtuFilename; iSourceOfInformation: soiPath),
    (sMenuItem: ''; sKeyword: '[E]'; MenuActionStyle: masStraight; iMenuType: rmtuExtension; iSourceOfInformation: soiExtension),
    (sMenuItem: ''; sKeyword: '[Ex:y]'; MenuActionStyle: masXYCharacters; iMenuType: rmtuExtension; iSourceOfInformation: soiExtension),
    (sMenuItem: ''; sKeyword: '[C]'; MenuActionStyle: masStraight; iMenuType: rmtuCounter; iSourceOfInformation: soiCounter),
    (sMenuItem: ''; sKeyword: '[G]'; MenuActionStyle: masStraight; iMenuType: rmtuCounter; iSourceOfInformation: soiGUID),
    (sMenuItem: ''; sKeyword: '[V:x]'; MenuActionStyle: masAskVariable; iMenuType: rmtuCounter; iSourceOfInformation: soiVariable),
    (sMenuItem: ''; sKeyword: '[Y]'; MenuActionStyle: masStraight; iMenuType: rmtuDate; iSourceOfInformation: soiDate),
    (sMenuItem: ''; sKeyword: '[YYYY]'; MenuActionStyle: masStraight; iMenuType: rmtuDate; iSourceOfInformation: soiDate),
    (sMenuItem: ''; sKeyword: '[M]'; MenuActionStyle: masStraight; iMenuType: rmtuDate; iSourceOfInformation: soiDate),
    (sMenuItem: ''; sKeyword: '[MM]'; MenuActionStyle: masStraight; iMenuType: rmtuDate; iSourceOfInformation: soiDate),
    (sMenuItem: ''; sKeyword: '[MMM]'; MenuActionStyle: masStraight; iMenuType: rmtuDate; iSourceOfInformation: soiDate),
    (sMenuItem: ''; sKeyword: '[MMMM]'; MenuActionStyle: masStraight; iMenuType: rmtuDate; iSourceOfInformation: soiDate),
    (sMenuItem: ''; sKeyword: '[D]'; MenuActionStyle: masStraight; iMenuType: rmtuDate; iSourceOfInformation: soiDate),
    (sMenuItem: ''; sKeyword: '[DD]'; MenuActionStyle: masStraight; iMenuType: rmtuDate; iSourceOfInformation: soiDate),
    (sMenuItem: ''; sKeyword: '[DDD]'; MenuActionStyle: masStraight; iMenuType: rmtuDate; iSourceOfInformation: soiDate),
    (sMenuItem: ''; sKeyword: '[DDDD]'; MenuActionStyle: masStraight; iMenuType: rmtuDate; iSourceOfInformation: soiDate),
    (sMenuItem: ''; sKeyword: '[YYYY][MM][DD]'; MenuActionStyle: masStraight; iMenuType: rmtuDate; iSourceOfInformation: soiDate),
    (sMenuItem: ''; sKeyword: '[h]'; MenuActionStyle: masStraight; iMenuType: rmtuTime; iSourceOfInformation: soiTime),
    (sMenuItem: ''; sKeyword: '[hh]'; MenuActionStyle: masStraight; iMenuType: rmtuTime; iSourceOfInformation: soiTime),
    (sMenuItem: ''; sKeyword: '[n]'; MenuActionStyle: masStraight; iMenuType: rmtuTime; iSourceOfInformation: soiTime),
    (sMenuItem: ''; sKeyword: '[nn]'; MenuActionStyle: masStraight; iMenuType: rmtuTime; iSourceOfInformation: soiTime),
    (sMenuItem: ''; sKeyword: '[s]'; MenuActionStyle: masStraight; iMenuType: rmtuTime; iSourceOfInformation: soiTime),
    (sMenuItem: ''; sKeyword: '[ss]'; MenuActionStyle: masStraight; iMenuType: rmtuTime; iSourceOfInformation: soiTime),
    (sMenuItem: ''; sKeyword: '[hh][nn][ss]'; MenuActionStyle: masStraight; iMenuType: rmtuTime; iSourceOfInformation: soiTime)
    );

{ TMultiRenamePreset.Create }
constructor TMultiRenamePreset.Create;
begin
  FPresetName := '';
  FFileName := '[N]';
  FExtension := '[E]';
  FFileNameStyle := 0;
  FExtensionStyle := 0;
  FFind := '';
  FReplace := '';
  FRepExt := True;
  FRegExp := False;
  FUseSubs := False;
  FCaseSens := False;
  FOnlyFirst := False;
  FCounter := '1';
  FInterval := '1';
  FWidth := 0;
  FLog := False;
  FLogFile := '';
  FLogAppend := False;
end;

{ TMultiRenamePreset.Destory }
// Not so necessary, but useful with a breakpoint to validate object is really free from memory when deleting an element from the list of clearing that list.
destructor TMultiRenamePreset.Destroy;
begin
  inherited Destroy;
end;

{ TMultiRenamePresetList.GetMultiRenamePreset }
function TMultiRenamePresetList.GetMultiRenamePreset(Index: integer): TMultiRenamePreset;
begin
  Result := TMultiRenamePreset(Items[Index]);
end;

{ TMultiRenamePresetList.Delete }
procedure TMultiRenamePresetList.Delete(Index: integer);
begin
  TMultiRenamePreset(Items[Index]).Free;
  inherited Delete(Index);
end;

{ TMultiRenamePresetList.Clear }
procedure TMultiRenamePresetList.Clear;
var
  Index: integer;
begin
  for Index := pred(Count) downto 0 do
    TMultiRenamePreset(Items[Index]).Free;
  inherited Clear;
end;

{ TMultiRenamePresetList.Find }
function TMultiRenamePresetList.Find(sPresetName: string): integer;
var
  iSeeker: integer = 0;
begin
  Result := -1;
  while (Result = -1) and (iSeeker < Count) do
    if SameText(sPresetName, MultiRenamePreset[iSeeker].PresetName) then
      Result := iSeeker
    else
      Inc(iSeeker);
end;

{ TfrmMultiRename.Create }
//Not used for actual renaming file.
//Present there just for the "TfrmOptionsHotkeys.FillCommandList" function who need to create the form in memory to extract internal commands from it.
constructor TfrmMultiRename.Create(TheOwner: TComponent);
begin
  // Application.CreateForm 调用此路径；启动路径和预设由 lpr 提前写入 MRConfig
  Create(TheOwner, MRConfig.StartupPaths, MRConfig.StartupPreset);
end;

{ TfrmMultiRename.Create }
constructor TfrmMultiRename.Create(TheOwner: TComponent; const AFilePaths: TStringList; const paramPreset: string);
var
  I: Integer;
  F: TFile;
  SR: TSearchRec;
begin
  FActuallyRenamingFile := False;
  FRegExp := TRegExprW.Create;
  FNames := TStringList.Create;
  FFindText := TStringList.Create;
  FFindText.StrictDelimiter := True;
  FFindText.Delimiter := '|';
  FReplaceText := TStringList.Create;
  FReplaceText.StrictDelimiter := True;
  FReplaceText.Delimiter := '|';
  FMultiRenamePresetList := TMultiRenamePresetList.Create;
  FNewNames := TStringHashListUtf8.Create(FileNameCaseSensitive);
  FOldNames := TStringHashListUtf8.Create(FileNameCaseSensitive);
  FslVariableNames := TStringList.Create;
  FslVariableValues := TStringList.Create;
  FslVariableSuggestionName := TStringList.Create;
  FslVariableSuggestionValue := TStringList.Create;
  // [独立版] 从路径列表构建 FFiles
  if Assigned(AFilePaths) and (AFilePaths.Count > 0) then
    FFiles := TFiles.Create(ExtractFilePath(AFilePaths[0]))
  else
    FFiles := TFiles.Create('');
  if Assigned(AFilePaths) then
    for I := 0 to AFilePaths.Count - 1 do
    begin
      F := TFile.Create(ExtractFilePath(AFilePaths[I]));
      F.Name := ExtractFileName(AFilePaths[I]);
      if FindFirst(AFilePaths[I], faAnyFile, SR) = 0 then
      begin
        F.ModificationTime := FileDateToDateTime(SR.Time);
        F.Size := SR.Size;
        FindClose(SR);
      end;
      FFiles.Add(F);
    end;
  FSourceRow := -1;
  FMoveRow := False;
  FParamPresetToLoadOnStart := paramPreset;
  inherited Create(TheOwner);
  FCommands := TFormCommands.Create(Self, actList);
end;

{ TfrmMultiRename.Destroy }
destructor TfrmMultiRename.Destroy;
begin
  inherited Destroy;
  FMultiRenamePresetList.Clear;
  FreeAndNil(FMultiRenamePresetList);
  FreeAndNil(FNewNames);
  FreeAndNil(FOldNames);
  FreeAndNil(FslVariableNames);
  FreeAndNil(FslVariableValues);
  FreeAndNil(FslVariableSuggestionName);
  FreeAndNil(FslVariableSuggestionValue);
  FreeAndNil(FFiles);
  FreeAndNil(FNames);
  FreeAndNil(FRegExp);
  FreeAndNil(FFindText);
  FreeAndNil(FReplaceText);
end;

{ TfrmMultiRename.FormCreate }
procedure TfrmMultiRename.FormCreate({%H-}Sender: TObject);
var
  HMMultiRename: THMForm;
begin
  // Localize File name style ComboBox
  ParseLineToList(rsMulRenFileNameStyleList, cbNameMaskStyle.Items);
  ParseLineToList(rsMulRenFileNameStyleList, cmbExtensionStyle.Items);
  InitializeMaskHelper;

  // Set row count
  StringGrid.RowCount := FFiles.Count + 1;
  StringGrid.FocusRectVisible := False;

  HMMultiRename := HotMan.Register(Self, HotkeysCategoryMultiRename);
  HMMultiRename.RegisterActionList(actList);

  cbExt.Items.Assign(MRConfig.ExtMaskHistory);
  cbName.Items.Assign(MRConfig.NameMaskHistory);

  // Set default values for controls.
  cm_ResetAll([sREFRESHCOMMANDS + '=0']);

  // 从 MRConfig 加载预设（已在启动时由 MRConfig.Load 读入）
  LoadPresetsFromConfig;

  if (FParamPresetToLoadOnStart <> '') and (FMultiRenamePresetList.Find(FParamPresetToLoadOnStart) <> -1) then
    FillPresetsList(FParamPresetToLoadOnStart)
  else
    case MRConfig.LaunchBehavior of
      mrlbLastMaskUnderLastOne: FillPresetsList(sLASTPRESET);
      mrlbLastPreset:          FillPresetsList(FLastPreset);
      mrlbFreshNew:            FillPresetsList(sFRESHMASKS);
    end;

  btnAnyNameMask.Action := actAnyNameMask;
  btnAnyNameMask.Caption := '...';
  btnAnyNameMask.Width := fneRenameLogFileFilename.ButtonWidth;
  btnAnyExtMask.Action := actAnyExtMask;
  btnAnyExtMask.Caption := '...';
  btnAnyExtMask.Width := fneRenameLogFileFilename.ButtonWidth;
  btnViewRenameLogFile.Action := actViewRenameLogFile;
  btnViewRenameLogFile.Caption := '查看日志';
  btnViewRenameLogFile.Width := 60;
  btnViewRenameLogFile.Hint := actViewRenameLogFile.Caption;
  btnPresets.Action := actShowPresetsMenu;
  btnPresets.Caption := '...';
  btnPresets.Hint := actShowPresetsMenu.Caption;
  btnPresets.Constraints.MinWidth := fneRenameLogFileFilename.ButtonWidth;
  BuildPresetsMenu(pmPresets);
  // [独立版] 去掉 gSpecialDirList.PopulateMenuWithSpecialDir（无此功能）

  // 从 MRConfig 恢复列宽
  with StringGrid.Columns do
  begin
    if MRConfig.ColWidth0 > 0 then Items[0].Width := MRConfig.ColWidth0;
    if MRConfig.ColWidth1 > 0 then Items[1].Width := MRConfig.ColWidth1;
    if MRConfig.ColWidth2 > 0 then Items[2].Width := MRConfig.ColWidth2;
  end;

  // 从 MRConfig 恢复窗口几何
  // 先恢复尺寸/位置，再恢复最大化，避免最大化状态被尺寸覆盖
  if MRConfig.WinWidth  > 0 then Width  := MRConfig.WinWidth;
  if MRConfig.WinHeight > 0 then Height := MRConfig.WinHeight;
  if MRConfig.WinLeft   > 0 then Left   := MRConfig.WinLeft;
  if MRConfig.WinTop    > 0 then Top    := MRConfig.WinTop;
  if MRConfig.WinMaximized then WindowState := wsMaximized;
  if MRConfig.PnlOptionsLeftWidth > 0 then pnlOptionsLeft.Width := MRConfig.PnlOptionsLeftWidth;

  // 排序下拉列表
  cmbAddSort.Items.Add('名称升序');
  cmbAddSort.Items.Add('名称降序');
  cmbAddSort.Items.Add('时间升序');
  cmbAddSort.Items.Add('时间降序');
  cmbAddSort.Items.Add('不排序');
  cmbAddSort.ItemIndex := Ord(MRConfig.AddSortOrder);

  // btnConfig 改为添加文件按钮
  btnConfig.Action  := actAddFiles;
  btnConfig.Caption := actAddFiles.Caption;

  // OS 级文件拖拽
  Self.AllowDropFiles := True;
  Self.OnDropFiles    := @FormDropFiles;
end;

{ TfrmMultiRename.FormCloseQuery }
procedure TfrmMultiRename.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if not isOkToLosePresetModification then
    CanClose := False;
end;

{ TfrmMultiRename.FormClose }
procedure TfrmMultiRename.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SavePreset(sLASTPRESET);

  // [独立版] 保存列宽、历史到 MRConfig 再写盘
  with StringGrid.Columns do
  begin
    MRConfig.ColWidth0 := Items[0].Width;
    MRConfig.ColWidth1 := Items[1].Width;
    MRConfig.ColWidth2 := Items[2].Width;
  end;
  MRConfig.ExtMaskHistory.Assign(cbExt.Items);
  MRConfig.NameMaskHistory.Assign(cbName.Items);

  // 保存窗口几何
  // 最大化时不覆盖 Normal 尺寸，下次恢复后仍能还原为合理大小
  MRConfig.WinMaximized        := (WindowState = wsMaximized);
  MRConfig.PnlOptionsLeftWidth := pnlOptionsLeft.Width;
  if WindowState = wsNormal then
  begin
    MRConfig.WinLeft   := Left;
    MRConfig.WinTop    := Top;
    MRConfig.WinWidth  := Width;
    MRConfig.WinHeight := Height;
  end;

  MRConfig.Save;

  CloseAction := caFree;
end;

procedure TfrmMultiRename.FormShow(Sender: TObject);
var
  APoint: TPoint;
begin
{$IF DEFINED(LCLQT5)}
  gbPresets.Constraints.MaxHeight:= cbPresets.Height + (gbPresets.Height - gbPresets.ClientHeight) + 
                                    gbPresets.ChildSizing.TopBottomSpacing * 2;
{$ENDIF}
  APoint:= TPoint.Create(cbUseSubs.Left, 0);
  fneRenameLogFileFilename.BorderSpacing.Left:= gbFindReplace.ClientToParent(APoint, pnlOptionsRight).X;
end;

{ TfrmMultiRename.StringGridKeyDown }
procedure TfrmMultiRename.StringGridKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
var
  tmpFile: TFile;
  DestRow: integer;
begin
  DestRow := StringGrid.Row;

  if (Shift = []) then
  begin
    if Key = VK_DELETE then
    begin
      FFiles.Delete(DestRow - 1);
      StringGrid.RowCount:= StringGrid.RowCount - 1;

      if FFiles.Count = 0 then
      begin
        OnCloseQuery:= nil;
        Close;
      end
      else begin
        StringGridTopLeftChanged(StringGrid);
      end;
    end;
  end;

  if (Shift = [ssShift]) then
  begin
    case Key of
      VK_UP:
      begin
        DestRow := StringGrid.Row - 1;
      end;
      VK_DOWN:
      begin
        DestRow := StringGrid.Row + 1;
      end;
    end;

    if (DestRow <> StringGrid.Row) and (0 < DestRow) and (DestRow < StringGrid.RowCount) then
    begin
      tmpFile := FFiles.Items[DestRow - 1];
      FFiles.Items[DestRow - 1] := FFiles.Items[StringGrid.Row - 1];
      FFiles.Items[StringGrid.Row - 1] := tmpFile;

      StringGridTopLeftChanged(StringGrid);
    end;
  end;
end;

{ TfrmMultiRename.StringGridMouseDown }
procedure TfrmMultiRename.StringGridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
var
  SourceCol: integer = 0;
begin
  if (Button = mbLeft) then
  begin
    StringGrid.MouseToCell(X, Y, SourceCol, FSourceRow);
    if (FSourceRow > 0) then
    begin
      FMoveRow := True;
    end;
  end;
end;

{ TfrmMultiRename.StringGridMouseUp }
procedure TfrmMultiRename.StringGridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  if Button = mbLeft then
  begin
    FMoveRow := False;
  end;
end;

{ TfrmMultiRename.StringGridSelection }
procedure TfrmMultiRename.StringGridSelection(Sender: TObject; aCol, aRow: integer);
var
  tmpFile: TFile;
begin
  if FMoveRow and (aRow <> FSourceRow) then
  begin
    tmpFile := FFiles.Items[aRow - 1];
    FFiles.Items[aRow - 1] := FFiles.Items[FSourceRow - 1];
    FFiles.Items[FSourceRow - 1] := tmpFile;

    FSourceRow := aRow;
    StringGridTopLeftChanged(StringGrid);
  end;
end;

{ TfrmMultiRename.StringGridTopLeftChanged }
procedure TfrmMultiRename.StringGridTopLeftChanged(Sender: TObject);
var
  I, iRowCount: integer;
begin
  iRowCount := StringGrid.TopRow + StringGrid.VisibleRowCount;
  if iRowCount > FFiles.Count then
    iRowCount := FFiles.Count;
  for I := StringGrid.TopRow to iRowCount do
  begin
    StringGrid.Cells[0, I] := FFiles[I - 1].Name;
    StringGrid.Cells[1, I] := FreshText(I - 1);
    StringGrid.Cells[2, I] := FFiles[I - 1].Path;
  end;
end;

{ TfrmMultiRename.cbNameStyleChange }
procedure TfrmMultiRename.cbNameStyleChange(Sender: TObject);
begin
  StringGridTopLeftChanged(StringGrid);
  if ActiveControl <> cbPresets then
    SetConfigurationState(CONFIG_NOTSAVED);
end;

{ TfrmMultiRename.cbPresetsChange }
procedure TfrmMultiRename.cbPresetsChange(Sender: TObject);
begin
  if cbPresets.ItemIndex <> 0 then
    cm_LoadPreset(['name=' + cbPresets.Items.Strings[cbPresets.ItemIndex]])
  else
    cm_LoadPreset(['name=' + sLASTPRESET]);
  RefreshActivePresetCommands;
end;

{ TfrmMultiRename.cbPresetsCloseUp }
procedure TfrmMultiRename.cbPresetsCloseUp(Sender: TObject);
begin
  if cbName.Enabled and gbMaska.Enabled then ActiveControl := cbName;
  cbName.SelStart := UTF8Length(cbName.Text);
end;

{ TfrmMultiRename.edFindChange }
procedure TfrmMultiRename.edFindChange(Sender: TObject);
begin
  if cbRegExp.Checked then
    FRegExp.Expression := UTF8Decode(edFind.Text)
  else
  begin
    FFindText.DelimitedText := edFind.Text;
  end;
  SetConfigurationState(CONFIG_NOTSAVED);
  StringGridTopLeftChanged(StringGrid);
end;

{ TfrmMultiRename.edReplaceChange }
procedure TfrmMultiRename.edReplaceChange(Sender: TObject);
begin
  if not cbRegExp.Checked then
  begin
    FReplaceText.DelimitedText := edReplace.Text;
  end;
  SetConfigurationState(CONFIG_NOTSAVED);
  StringGridTopLeftChanged(StringGrid);
end;

{ TfrmMultiRename.cbRegExpChange }
procedure TfrmMultiRename.cbRegExpChange(Sender: TObject);
begin
  if cbRegExp.Checked then
    cbUseSubs.Checked := boolean(cbUseSubs.Tag)
  else
  begin
    cbUseSubs.Tag := integer(cbUseSubs.Checked);
    cbUseSubs.Checked := False;
  end;
  cbUseSubs.Enabled := cbRegExp.Checked;
  edFindChange(edFind);
  edReplaceChange(edReplace);
end;

{ TfrmMultiRename.edPocChange }
procedure TfrmMultiRename.edPocChange(Sender: TObject);
var
  c: integer;
begin
  c := StrToIntDef(edPoc.Text, maxint);
  if c = MaxInt then
    with edPoc do //editbox only for numbers
    begin
      Text := '1';
      SelectAll;
    end;
  SetConfigurationState(CONFIG_NOTSAVED);
  StringGridTopLeftChanged(StringGrid);
end;

{ TfrmMultiRename.edIntervalChange }
procedure TfrmMultiRename.edIntervalChange(Sender: TObject);
var
  c: integer;
begin
  c := StrToIntDef(edInterval.Text, maxint);
  if c = MaxInt then
    with edInterval do //editbox only for numbers
    begin
      Text := '1';
      SelectAll;
    end;
  SetConfigurationState(CONFIG_NOTSAVED);
  StringGridTopLeftChanged(StringGrid);
end;

{ TfrmMultiRename.cbLogClick }
procedure TfrmMultiRename.cbLogClick(Sender: TObject);
begin
  fneRenameLogFileFilename.Enabled := cbLog.Checked;
  actViewRenameLogFile.Enabled := cbLog.Checked;
  cbLogAppend.Enabled := cbLog.Checked;
  SetConfigurationState(CONFIG_NOTSAVED);
end;

{ TfrmMultiRename.actExecute }
procedure TfrmMultiRename.actExecute(Sender: TObject);
var
  cmd: string;
begin
  cmd := (Sender as TAction).Name;
  cmd := 'cm_' + Copy(cmd, 4, Length(cmd) - 3);
  Commands.ExecuteCommand(cmd, []);
end;

{ TfrmMultiRename.RestoreProperties }
// 列宽恢复已统一在 FormCreate 末尾直接从 MRConfig 读取，此回调保留空实现。
procedure TfrmMultiRename.RestoreProperties(Sender: TObject);
begin
end;

{ TfrmMultiRename.SetConfigurationState }
procedure TfrmMultiRename.SetConfigurationState(bConfigurationSaved: boolean);
begin
  if not cbPresets.DroppedDown then
  begin
    if bConfigurationSaved or (cbPresets.ItemIndex > 0) then
    begin
      if cbPresets.Enabled <> bConfigurationSaved then
      begin
        cbPresets.Enabled := bConfigurationSaved;
      end;
    end;
  end;
end;

{ TfrmMultiRename.GetPresetNameForCommand }
// Wanted preset may be given via "name=presetname" or via "index=indexno".
function TfrmMultiRename.GetPresetNameForCommand(const Params: array of string): string;
var
  Param, sValue: string;
  iIndex: integer;
begin
  Result := '';

  for Param in Params do
  begin
    if GetParamValue(Param, 'name', sValue) then
      Result := sValue
    else
    if GetParamValue(Param, 'index', sValue) then
    begin
      iIndex := StrToIntDef(sValue, -1);
      if (iIndex >= 0) and (iIndex < cbPresets.items.Count) then
        if iIndex = 0 then
          Result := sLASTPRESET
        else
          Result := cbPresets.Items.Strings[iIndex];
    end;
  end;
end;

{ TfrmMultiRename.LoadPresetsFromConfig }
// 从 MRConfig.Presets（已在启动时由 MRConfig.Load 填充）初始化 FMultiRenamePresetList。
procedure TfrmMultiRename.LoadPresetsFromConfig;
var
  I         : integer;
  PD        : TPresetData;
  MRP       : TMultiRenamePreset;
  PresetIndex: integer;
begin
  FMultiRenamePresetList.Clear;
  FLastPreset := MRConfig.LastPreset;

  for I := 0 to MRConfig.Presets.Count - 1 do
  begin
    PD := TPresetData(MRConfig.Presets[I]);
    if FMultiRenamePresetList.Find(PD.PresetName) = -1 then
    begin
      MRP := TMultiRenamePreset.Create;
      MRP.PresetName    := PD.PresetName;
      MRP.FileName      := PD.FileName;
      MRP.Extension     := PD.Extension;
      MRP.FileNameStyle := PD.FileNameStyle;
      MRP.ExtensionStyle:= PD.ExtensionStyle;
      MRP.Find          := PD.Find;
      MRP.Replace       := PD.Replace;
      MRP.RepExt        := PD.RepExt;
      MRP.RegExp        := PD.RegExp;
      MRP.UseSubs       := PD.UseSubs;
      MRP.CaseSens      := PD.CaseSens;
      MRP.OnlyFirst     := PD.OnlyFirst;
      MRP.Counter       := PD.Counter;
      MRP.Interval      := PD.Interval;
      MRP.Width         := PD.Width;
      MRP.Log           := PD.Log;
      MRP.LogAppend     := PD.LogAppend;
      MRP.LogFile       := PD.LogFile;
      FMultiRenamePresetList.Add(MRP);
    end;
  end;

  // 确保 sLASTPRESET 在位置 0
  PresetIndex := FMultiRenamePresetList.Find(sLASTPRESET);
  if PresetIndex <> 0 then
  begin
    if PresetIndex <> -1 then
      FMultiRenamePresetList.Move(PresetIndex, 0)
    else
    begin
      MRP := TMultiRenamePreset.Create;
      MRP.PresetName := sLASTPRESET;
      FMultiRenamePresetList.Insert(0, MRP);
    end;
  end;
end;

{ TfrmMultiRename.isOkToLosePresetModification }
function TfrmMultiRename.isOkToLosePresetModification: boolean;
var
  MsgRes: Integer;
begin
  Result := False;

  if (cbPresets.ItemIndex <= 0) or (cbPresets.Enabled) or (not Visible) then
    Result := True
  else
  begin
    case MRConfig.ExitModifiedPreset of
      mrempIgnoreSaveLast:
        Result := True;

      mrempSaveAutomatically:
      begin
        if cbPresets.ItemIndex > 0 then
          cm_SavePreset(['name=' + cbPresets.Items.Strings[cbPresets.ItemIndex]]);
        Result := True;
      end;

      mrempPromptUser:
      begin
        MsgRes := MessageDlg(Format(rsMulRenSaveModifiedPreset,
          [cbPresets.Items.Strings[cbPresets.ItemIndex]]),
          mtConfirmation, [mbYes, mbNo, mbCancel], 0);
        case MsgRes of
          mrYes:
          begin
            cm_SavePreset([]);
            Result := True;
          end;
          mrNo:     Result := True;
          mrCancel: ;
        end;
      end;
    end;
  end;
end;

{ TfrmMultiRename.SavePreset }
procedure TfrmMultiRename.SavePreset(PresetName: string);
var
  PresetIndex: integer;
  AMultiRenamePresetObject: TMultiRenamePreset;
begin
  if PresetName <> '' then
  begin
    PresetIndex := FMultiRenamePresetList.Find(PresetName);
    if PresetIndex = -1 then
    begin
      AMultiRenamePresetObject := TMultiRenamePreset.Create;
      AMultiRenamePresetObject.PresetName := PresetName;
      PresetIndex := FMultiRenamePresetList.Add(AMultiRenamePresetObject);
    end;

    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].FileName := cbName.Text;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Extension := cbExt.Text;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].FileNameStyle := cbNameMaskStyle.ItemIndex;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].ExtensionStyle := cmbExtensionStyle.ItemIndex;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Find := edFind.Text;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Replace := edReplace.Text;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].RepExt := cbRepExt.Checked;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].RegExp := cbRegExp.Checked;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].UseSubs := cbUseSubs.Checked;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].CaseSens := cbCaseSens.Checked;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].OnlyFirst := cbOnlyFirst.Checked;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Counter := edPoc.Text;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Interval := edInterval.Text;
    FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Width := cmbxWidth.ItemIndex;

    case MRConfig.SaveRenamingLog of
      mrsrlPerPreset:
      begin
        FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Log := cbLog.Checked;
        FMultiRenamePresetList.MultiRenamePreset[PresetIndex].LogFile := fneRenameLogFileFilename.FileName;
        FMultiRenamePresetList.MultiRenamePreset[PresetIndex].LogAppend := cbLogAppend.Checked;
      end;

      mrsrlAppendSameLog:
      begin
        FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Log := FbRememberLog;
        FMultiRenamePresetList.MultiRenamePreset[PresetIndex].LogAppend := FbRememberAppend;
        FMultiRenamePresetList.MultiRenamePreset[PresetIndex].LogFile := FsRememberRenameLogFilename;
      end;
    end;

    SavePresets;
  end;
end;

{ TfrmMultiRename.SavePresetsToConfig }
// 将 FMultiRenamePresetList 同步回 MRConfig.Presets，然后持久化。
procedure TfrmMultiRename.SavePresetsToConfig;
var
  I  : integer;
  MRP: TMultiRenamePreset;
  PD : TPresetData;
begin
  MRConfig.ClearPresets;

  if cbPresets.ItemIndex = 0 then
    MRConfig.LastPreset := sLASTPRESET
  else
    MRConfig.LastPreset := cbPresets.Items.Strings[cbPresets.ItemIndex];

  for I := 0 to pred(FMultiRenamePresetList.Count) do
  begin
    MRP := FMultiRenamePresetList.MultiRenamePreset[I];
    PD  := TPresetData.Create;
    PD.PresetName    := MRP.PresetName;
    PD.FileName      := MRP.FileName;
    PD.Extension     := MRP.Extension;
    PD.FileNameStyle := MRP.FileNameStyle;
    PD.ExtensionStyle:= MRP.ExtensionStyle;
    PD.Find          := MRP.Find;
    PD.Replace       := MRP.Replace;
    PD.RepExt        := MRP.RepExt;
    PD.RegExp        := MRP.RegExp;
    PD.UseSubs       := MRP.UseSubs;
    PD.CaseSens      := MRP.CaseSens;
    PD.OnlyFirst     := MRP.OnlyFirst;
    PD.Counter       := MRP.Counter;
    PD.Interval      := MRP.Interval;
    PD.Width         := MRP.Width;
    PD.Log           := MRP.Log;
    PD.LogAppend     := MRP.LogAppend;
    PD.LogFile       := MRP.LogFile;
    MRConfig.Presets.Add(PD);
  end;
end;

{ TfrmMultiRename.mbExpandFileName }
// [独立版] 简单展开路径，替代 DCOSUtils.mbExpandFileName
function TfrmMultiRename.mbExpandFileName(const s: string): string;
begin
  Result := ExpandFileName(s);
end;

{ TfrmMultiRename.SavePresets }
procedure TfrmMultiRename.SavePresets;
begin
  SavePresetsToConfig;
  MRConfig.Save;
end;

{ TfrmMultiRename.DeletePreset }
procedure TfrmMultiRename.DeletePreset(PresetName: string);
var
  PresetIndex: integer;
begin
  if PresetName <> '' then
  begin
    PresetIndex := FMultiRenamePresetList.Find(PresetName);
    if PresetIndex <> -1 then
    begin
      FMultiRenamePresetList.Delete(PresetIndex);
      SavePresets;
    end;
  end;
end;

{ TfrmMultiRename.FillPresetsList }
//We fill the preset drop list with the element in memory.
//If it's specified when called, will attempt to load the specified preset in parameter.
//If it's not specified, will attempt to re-select the one that was initially selected.
//If nothing is still selected, we'll select the [Last One].
procedure TfrmMultiRename.FillPresetsList(const WantedSelectedPresetName: string = '');
var
  i: integer;
  sRememberSelection, PresetName: string;

begin
  sRememberSelection := '';

  if WantedSelectedPresetName <> '' then
    sRememberSelection := WantedSelectedPresetName;

  if sRememberSelection = '' then
    if cbPresets.ItemIndex <> -1 then
      if cbPresets.ItemIndex < cbPresets.Items.Count then
        sRememberSelection := cbPresets.Items.Strings[cbPresets.ItemIndex];

  cbPresets.Clear;
  cbPresets.Items.Add(rsMulRenLastPreset);

  for i := 0 to pred(FMultiRenamePresetList.Count) do
  begin
    PresetName := FMultiRenamePresetList.MultiRenamePreset[i].PresetName;
    if (PresetName <> sLASTPRESET) then
      if cbPresets.Items.IndexOf(PresetName) = -1 then
        cbPresets.Items.Add(PresetName);
  end;

  if (WantedSelectedPresetName = sLASTPRESET) or (WantedSelectedPresetName = sFRESHMASKS) then
    cbPresets.ItemIndex := 0
  else
  if sRememberSelection <> '' then
    if cbPresets.Items.IndexOf(sRememberSelection) <> -1 then
      cbPresets.ItemIndex := cbPresets.Items.IndexOf(sRememberSelection);

  if cbPresets.ItemIndex = -1 then
    if cbPresets.Items.Count > 0 then
      cbPresets.ItemIndex := 0;

  if WantedSelectedPresetName <> sFRESHMASKS then
  begin
    cbPresetsChange(cbPresets);
    RefreshActivePresetCommands;
  end;
end;

{ TfrmMultiRename.RefreshActivePresetCommands }
procedure TfrmMultiRename.RefreshActivePresetCommands;
begin
  //"Load last preset" is always available since it's the [Last One].
  actSavePreset.Enabled := (cbPresets.ItemIndex > 0);
  //"Save as is always available so we may save the [Last One]
  actRenamePreset.Enabled := (cbPresets.ItemIndex > 0);
  actDeletePreset.Enabled := (cbPresets.ItemIndex > 0);
end;

{ TfrmMultiRename.InitializeMaskHelper }
procedure TfrmMultiRename.InitializeMaskHelper;
begin
  if MaskHelpers[00].sMenuItem = '' then //"MaskHelpers" are no tin the object but generic, so we just need to initialize once.
  begin
    MaskHelpers[00].sMenuItem := rsMulRenMaskName + ' ' + MaskHelpers[00].sKeyword;
    MaskHelpers[01].sMenuItem := rsMulRenMaskCharAtPosXtoY + ' ' + MaskHelpers[01].sKeyword;
    MaskHelpers[02].sMenuItem := rsMulRenMaskFullName + ' ' + MaskHelpers[02].sKeyword;
    MaskHelpers[03].sMenuItem := rsMulRenMaskFullNameCharAtPosXtoY + ' ' + MaskHelpers[03].sKeyword;
    MaskHelpers[04].sMenuItem := rsMulRenMaskParent + ' ' + MaskHelpers[04].sKeyword;
    MaskHelpers[05].sMenuItem := rsMulRenMaskExtension + ' ' + MaskHelpers[05].sKeyword;
    MaskHelpers[06].sMenuItem := rsMulRenMaskCharAtPosXtoY + ' ' + MaskHelpers[06].sKeyword;
    MaskHelpers[07].sMenuItem := rsMulRenMaskCounter + ' ' + MaskHelpers[07].sKeyword;
    MaskHelpers[08].sMenuItem := rsMulRenMaskGUID + ' ' + MaskHelpers[08].sKeyword;
    MaskHelpers[09].sMenuItem := rsMulRenMaskVarOnTheFly + ' ' + MaskHelpers[09].sKeyword;
    MaskHelpers[10].sMenuItem := rsMulRenMaskYear2Digits + ' ' + MaskHelpers[10].sKeyword;
    MaskHelpers[11].sMenuItem := rsMulRenMaskYear4Digits + ' ' + MaskHelpers[11].sKeyword;
    MaskHelpers[12].sMenuItem := rsMulRenMaskMonth + ' ' + MaskHelpers[12].sKeyword;
    MaskHelpers[13].sMenuItem := rsMulRenMaskMonth2Digits + ' ' + MaskHelpers[13].sKeyword;
    MaskHelpers[14].sMenuItem := rsMulRenMaskMonthAbrev + ' ' + MaskHelpers[14].sKeyword;
    MaskHelpers[15].sMenuItem := rsMulRenMaskMonthComplete + ' ' + MaskHelpers[15].sKeyword;
    MaskHelpers[16].sMenuItem := rsMulRenMaskDay + ' ' + MaskHelpers[16].sKeyword;
    MaskHelpers[17].sMenuItem := rsMulRenMaskDay2Digits + ' ' + MaskHelpers[17].sKeyword;
    MaskHelpers[18].sMenuItem := rsMulRenMaskDOWAbrev + ' ' + MaskHelpers[18].sKeyword;
    MaskHelpers[19].sMenuItem := rsMulRenMaskDOWComplete + ' ' + MaskHelpers[19].sKeyword;
    MaskHelpers[20].sMenuItem := rsMulRenMaskCompleteDate + ' ' + MaskHelpers[20].sKeyword;
    MaskHelpers[21].sMenuItem := rsMulRenMaskHour + ' ' + MaskHelpers[21].sKeyword;
    MaskHelpers[22].sMenuItem := rsMulRenMaskHour2Digits + ' ' + MaskHelpers[22].sKeyword;
    MaskHelpers[23].sMenuItem := rsMulRenMaskMin + ' ' + MaskHelpers[23].sKeyword;
    MaskHelpers[24].sMenuItem := rsMulRenMaskMin2Digits + ' ' + MaskHelpers[24].sKeyword;
    MaskHelpers[25].sMenuItem := rsMulRenMaskSec + ' ' + MaskHelpers[25].sKeyword;
    MaskHelpers[26].sMenuItem := rsMulRenMaskSec2Digits + ' ' + MaskHelpers[26].sKeyword;
    MaskHelpers[27].sMenuItem := rsMulRenMaskCompleteTime + ' ' + MaskHelpers[27].sKeyword;
  end;
end;

{ TfrmMultiRename.PopulateFilenameMenu }
procedure TfrmMultiRename.PopulateFilenameMenu(AMenuSomething: TPopupMenu);
var
  miSubMenu: TMenuItem;
begin
  miSubMenu := AppendSubMenuToThisMenu(AMenuSomething.Items, GetMaskCategoryName(rmtuFilename), GetImageIndexCategoryName(rmtuFilename));
  BuildMaskMenu(miSubMenu, tfmFilename, rmtuFilename);
  miSubMenu := AppendSubMenuToThisMenu(AMenuSomething.Items, GetMaskCategoryName(rmtuExtension), GetImageIndexCategoryName(rmtuExtension));
  BuildMaskMenu(miSubMenu, tfmFilename, rmtuExtension);
  miSubMenu := AppendSubMenuToThisMenu(AMenuSomething.Items, GetMaskCategoryName(rmtuCounter), GetImageIndexCategoryName(rmtuCounter));
  BuildMaskMenu(miSubMenu, tfmFilename, rmtuCounter);
  miSubMenu := AppendSubMenuToThisMenu(AMenuSomething.Items, GetMaskCategoryName(rmtuDate), GetImageIndexCategoryName(rmtuDate));
  BuildMaskMenu(miSubMenu, tfmFilename, rmtuDate);
  miSubMenu := AppendSubMenuToThisMenu(AMenuSomething.Items, GetMaskCategoryName(rmtuTime), GetImageIndexCategoryName(rmtuTime));
  BuildMaskMenu(miSubMenu, tfmFilename, rmtuTime);
  // [独立版] 去掉插件子菜单
  AppendSubMenuToThisMenu(AMenuSomething.Items, '-', -1);
  AppendActionMenuToThisMenu(AMenuSomething.Items, actClearNameMask);
end;

{ TfrmMultiRename.PopulateExtensionMenu }
procedure TfrmMultiRename.PopulateExtensionMenu(AMenuSomething: TPopupMenu);
var
  miSubMenu: TMenuItem;
begin
  miSubMenu := AppendSubMenuToThisMenu(AMenuSomething.Items, GetMaskCategoryName(rmtuFilename), GetImageIndexCategoryName(rmtuFilename));
  BuildMaskMenu(miSubMenu, tfmExtension, rmtuFilename);
  miSubMenu := AppendSubMenuToThisMenu(AMenuSomething.Items, GetMaskCategoryName(rmtuExtension), GetImageIndexCategoryName(rmtuExtension));
  BuildMaskMenu(miSubMenu, tfmExtension, rmtuExtension);
  miSubMenu := AppendSubMenuToThisMenu(AMenuSomething.Items, GetMaskCategoryName(rmtuCounter), GetImageIndexCategoryName(rmtuCounter));
  BuildMaskMenu(miSubMenu, tfmExtension, rmtuCounter);
  miSubMenu := AppendSubMenuToThisMenu(AMenuSomething.Items, GetMaskCategoryName(rmtuDate), GetImageIndexCategoryName(rmtuDate));
  BuildMaskMenu(miSubMenu, tfmExtension, rmtuDate);
  miSubMenu := AppendSubMenuToThisMenu(AMenuSomething.Items, GetMaskCategoryName(rmtuTime), GetImageIndexCategoryName(rmtuTime));
  BuildMaskMenu(miSubMenu, tfmExtension, rmtuTime);
  // [独立版] 去掉插件子菜单
  AppendSubMenuToThisMenu(AMenuSomething.Items, '-', -1);
  AppendActionMenuToThisMenu(AMenuSomething.Items, actClearExtMask);
end;

{ TfrmMultiRename.BuildMaskMenu }
procedure TfrmMultiRename.BuildMaskMenu(AMenuSomething: TMenuItem; iTarget: tTargetForMask; iMenuTypeMask: tRenameMaskToUse);
var
  iSeekIndex: integer;
  AMenuItem: TMenuItem;
begin
  AMenuSomething.Clear;

  for iSeekIndex := 0 to pred(NBMAXHELPERS) do
  begin
    if MaskHelpers[iSeekIndex].iMenuType = iMenuTypeMask then
    begin
      AMenuItem := TMenuItem.Create(AMenuSomething);
      AMenuItem.Caption := MaskHelpers[iSeekIndex].sMenuItem;
      AMenuItem.Tag := (iSeekIndex shl 16) or Ord(iTarget);
      AMenuItem.Hint := MaskHelpers[iSeekIndex].sKeyword;
      AMenuItem.ImageIndex := GetImageIndexCategoryName(MaskHelpers[iSeekIndex].iMenuType);

      case MaskHelpers[iSeekIndex].MenuActionStyle of
        masStraight: AMenuItem.OnClick := @MenuItemStraightMaskClick;
        masXYCharacters: AMenuItem.OnClick := @MenuItemXCharactersMaskClick;
        masAskVariable: AMenuItem.OnClick := @MenuItemVariableMaskClick;
        masDirectorySelector: AMenuItem.OnClick := @MenuItemDirectorySelectorMaskClick;
      end;

      AMenuSomething.Add(AMenuItem);
    end;
  end;

  // [独立版] 去掉插件（rmtuPlugins）分支
end;

{ TfrmMultiRename.BuildPresetsMenu }
procedure TfrmMultiRename.BuildPresetsMenu(AMenuSomething: TPopupMenu);
begin
  AppendActionMenuToThisMenu(AMenuSomething.Items, actDropDownPresetList);
  AppendActionMenuToThisMenu(AMenuSomething.Items, actLoadLastPreset);
  AppendSubMenuToThisMenu(AMenuSomething.Items, '-', -1);
  AppendActionMenuToThisMenu(AMenuSomething.Items, actSavePreset);
  AppendActionMenuToThisMenu(AMenuSomething.Items, actSavePresetAs);
  AppendActionMenuToThisMenu(AMenuSomething.Items, actRenamePreset);
  AppendActionMenuToThisMenu(AMenuSomething.Items, actDeletePreset);
  AppendActionMenuToThisMenu(AMenuSomething.Items, actSortPresets);
end;

{ TfrmMultiRename.GetMaskCategoryName }
function TfrmMultiRename.GetMaskCategoryName(aRenameMaskToUse: tRenameMaskToUse): string;
begin
  Result := '';
  case aRenameMaskToUse of
    rmtuFilename: Result := rsMulRenFilename;
    rmtuExtension: Result := rsMulRenExtension;
    rmtuCounter: Result := rsMulRenCounter;
    rmtuDate: Result := rsMulRenDate;
    rmtuTime: Result := rsMulRenTime;
  end;
end;

{ TfrmMultiRename.GetImageIndexCategoryName }
function TfrmMultiRename.GetImageIndexCategoryName(aRenameMaskToUse: tRenameMaskToUse): integer;
begin
  Result := -1;
  case aRenameMaskToUse of
    rmtuFilename: Result := 20;
    rmtuExtension: Result := 21;
    rmtuCounter: Result := 22;
    rmtuDate: Result := 23;
    rmtuTime: Result := 24;
  end;
end;

{ TfrmMultiRename.AppendSubMenuToThisMenu }
function TfrmMultiRename.AppendSubMenuToThisMenu(ATargetMenu: TMenuItem; sCaption: string; iImageIndex: integer): TMenuItem;
begin
  Result := TMenuItem.Create(ATargetMenu);
  Result.ImageIndex := iImageIndex;
  if sCaption <> '' then
    Result.Caption := sCaption;
  ATargetMenu.Add(Result);
end;

{ TfrmMultiRename.AppendActionMenuToThisMenu }
function TfrmMultiRename.AppendActionMenuToThisMenu(ATargetMenu: TMenuItem; paramAction: TAction): TMenuItem;
begin
  Result := TMenuItem.Create(ATargetMenu);
  Result.Action := paramAction;
  ATargetMenu.Add(Result);
end;

{ TfrmMultiRename.MenuItemXCharactersMaskClick }
procedure TfrmMultiRename.MenuItemXCharactersMaskClick(Sender: TObject);
var
  sSourceToSelectFromText, sPrefix: string;
  sResultingMaskValue: string = '';
  iMaskHelperIndex: integer;
begin
  iMaskHelperIndex := TMenuItem(Sender).Tag shr 16;

  if iMaskHelperIndex < length(MaskHelpers) then
  begin
    sSourceToSelectFromText := '';
    case MaskHelpers[iMaskHelperIndex].iSourceOfInformation of
      soiFilename:
      begin
        sSourceToSelectFromText := FFiles[pred(StringGrid.Row)].NameNoExt;
        sPrefix := 'N';
      end;

      soiExtension:
      begin
        sSourceToSelectFromText := FFiles[pred(StringGrid.Row)].Extension;
        sPrefix := 'E';
      end;

      soiFullName:
      begin
        sSourceToSelectFromText := FFiles[pred(StringGrid.Row)].FullPath;
        sPrefix := 'A';
      end;
    end;

    if ShowSelectTextRangeDlg(Self, Caption, sSourceToSelectFromText, sPrefix, sResultingMaskValue) then
      InsertMask(sResultingMaskValue, tTargetForMask(TMenuItem(Sender).Tag and iTARGETMASK));
  end;
end;

{ TfrmMultiRename.MenuItemDirectorySelectorMaskClick }
procedure TfrmMultiRename.MenuItemDirectorySelectorMaskClick(Sender: TObject);
var
  sSourceToSelectFromText, sPrefix: string;
  sResultingMaskValue: string = '';
  iMaskHelperIndex: integer;
begin
  iMaskHelperIndex := TMenuItem(Sender).Tag shr 16;

  if iMaskHelperIndex < length(MaskHelpers) then
  begin
    sSourceToSelectFromText := '';
    case MaskHelpers[iMaskHelperIndex].iSourceOfInformation of
      soiPath:
      begin
        sSourceToSelectFromText := FFiles[pred(StringGrid.Row)].Path;
        sPrefix := 'P';
      end;
    end;

    if ShowSelectPathRangeDlg(Self, Caption, sSourceToSelectFromText, sPrefix, sResultingMaskValue) then
      InsertMask(sResultingMaskValue, tTargetForMask(TMenuItem(Sender).Tag and iTARGETMASK));
  end;
end;

{ TfrmMultiRename.MenuItemVariableMaskClick }
procedure TfrmMultiRename.MenuItemVariableMaskClick(Sender: TObject);
var
  sVariableName: string;
begin
  sVariableName := rsSimpleWordVariable;
  if InputQuery(rsMulRenDefineVariableName, rsMulRenEnterNameForVar, sVariableName) then
  begin
    if sVariableName = '' then
      sVariableName := rsSimpleWordVariable;
    InsertMask('[V:' + sVariableName + ']', tTargetForMask(TMenuItem(Sender).Tag and iTARGETMASK));
  end;
end;

{ TfrmMultiRename.MenuItemStraightMaskClick }
procedure TfrmMultiRename.MenuItemStraightMaskClick(Sender: TObject);
var
  sMaks: string;
begin
  sMaks := TMenuItem(Sender).Hint;
  case tTargetForMask(TMenuItem(Sender).Tag and iTARGETMASK) of
    tfmFilename:
    begin
      InsertMask(sMaks, cbName);
      cbName.SetFocus;
    end;
    tfmExtension:
    begin
      InsertMask(sMaks, cbExt);
      cbExt.SetFocus;
    end;
  end;
end;

{ TfrmMultiRename.PopupDynamicMenuAtThisControl }
procedure TfrmMultiRename.PopupDynamicMenuAtThisControl(APopUpMenu: TPopupMenu; AControl: TControl);
var
  PopupPoint: TPoint;
begin
  PopupPoint := AControl.Parent.ClientToScreen(Point(AControl.Left + AControl.Width - 5, AControl.Top + AControl.Height - 5));
  APopUpMenu.PopUp(PopupPoint.X, PopupPoint.Y);
end;

{ TfrmMultiRename.miPluginClick }
procedure TfrmMultiRename.miPluginClick(Sender: TObject);
begin
  // [独立版] 插件功能已去除
end;

{ TfrmMultiRename.InsertMask }
procedure TfrmMultiRename.InsertMask(const Mask: string; edChoose: TComboBox);
var
  sTmp, sInitialString: string;
  I: integer;
begin
  sInitialString := edChoose.Text;
  if edChoose.SelLength > 0 then
    edChoose.SelText := Mask // Replace selected text
  else
  begin
    sTmp := edChoose.Text;
    I := edChoose.SelStart + 1;  // Insert on current position
    UTF8Insert(Mask, sTmp, I);
    Inc(I, UTF8Length(Mask));
    edChoose.Text := sTmp;
    edChoose.SelStart := I - 1;
  end;
  if sInitialString <> edChoose.Text then
    cbNameStyleChange(edChoose);
end;

{ TfrmMultiRename.InsertMask }
procedure TfrmMultiRename.InsertMask(const Mask: string; TargetForMask: tTargetForMask);
begin
  case TargetForMask of
    tfmFilename:
    begin
      InsertMask(Mask, cbName);
      cbName.SetFocus;
    end;

    tfmExtension:
    begin
      InsertMask(Mask, cbExt);
      cbExt.SetFocus;
    end;
  end;
end;

{TfrmMultiRename.sReplace }
function TfrmMultiRename.sReplace(sMask: string; ItemNr: integer): string;
var
  iStart, iEnd: integer;
begin
  Result := '';
  while Length(sMask) > 0 do
  begin
    iStart := Pos('[', sMask);
    if iStart > 0 then
    begin
      iEnd := Pos(']', sMask, iStart + 1);
      if iEnd > 0 then
      begin
        Result := Result + Copy(sMask, 1, iStart - 1) +
          sHandleFormatString(Copy(sMask, iStart + 1, iEnd - iStart - 1), ItemNr);
        Delete(sMask, 1, iEnd);
      end
      else
        Break;
    end
    else
      Break;
  end;
  Result := Result + sMask;
end;

{ TfrmMultiRename.sReplaceXX }
function TfrmMultiRename.sReplaceXX(const sFormatStr, sOrig: string): string;
var
  iFrom, iTo, iDelim: integer;
begin
  if Length(sFormatStr) = 1 then
    Result := sOrig
  else
  begin
    iDelim := Pos(':', sFormatStr);
    if iDelim = 0 then
    begin
      iDelim := Pos(',', sFormatStr);
      // Not found
      if iDelim = 0 then
      begin
        iFrom := StrToIntDef(Copy(sFormatStr, 2, MaxInt), 1);
        if iFrom < 0 then
          iFrom := sOrig.Length + iFrom + 1;
        iTo := iFrom;
      end
      // Range e.g. N1,3 (from 1, 3 symbols)
      else
      begin
        iFrom := StrToIntDef(Copy(sFormatStr, 2, iDelim - 2), 1);
        iDelim := Abs(StrToIntDef(Copy(sFormatStr, iDelim + 1, MaxSmallint), MaxSmallint));
        if iFrom >= 0 then
          iTo := iDelim + iFrom - 1
        else
        begin
          iTo := sOrig.Length + iFrom + 1;
          iFrom := Max(iTo - iDelim + 1, 1);
        end;
      end;
    end
    // Range e.g. N1:2 (from 1 to 2)
    else
    begin
      iFrom := StrToIntDef(Copy(sFormatStr, 2, iDelim - 2), 1);
      if iFrom < 0 then
        iFrom := sOrig.Length + iFrom + 1;
      iTo := StrToIntDef(Copy(sFormatStr, iDelim + 1, MaxSmallint), MaxSmallint);
      if iTo < 0 then
        iTo := sOrig.Length + iTo + 1;
      ;
      if iTo < iFrom then
      begin
        iDelim := iTo;
        iTo := iFrom;
        iFrom := iDelim;
      end;
    end;
    Result := UTF8Copy(sOrig, iFrom, iTo - iFrom + 1);
  end;
end;

{ TfrmMultiRename.sReplaceVariable }
function TfrmMultiRename.sReplaceVariable(const sFormatStr: string): string;
var
  iDelim, iVariableIndex, iVariableSuggestionIndex: integer;
  sVariableName: string = '';
  sVariableValue: string = '';
begin
  Result := '';

  iDelim := Pos(':', sFormatStr);
  if iDelim <> 0 then
    sVariableName := copy(sFormatStr, succ(iDelim), length(sFormatStr) - iDelim)
  else
    sVariableName := rsSimpleWordVariable;

  iVariableIndex := FslVariableNames.IndexOf(sVariableName);
  if iVariableIndex = -1 then
  begin
    iVariableSuggestionIndex := FslVariableSuggestionName.IndexOf(sVariableName);
    if iVariableSuggestionIndex <> -1 then
      sVariableValue := FslVariableSuggestionValue.Strings[iVariableSuggestionIndex]
    else
      sVariableValue := sVariableName;

    if InputQuery(rsMulRenDefineVariableValue, Format(rsMulRenEnterValueForVar, [sVariableName]), sVariableValue) then
    begin
      FslVariableNames.Add(sVariableName);
      iVariableIndex := FslVariableValues.Add(sVariableValue);
      if iVariableSuggestionIndex = -1 then
      begin
        FslVariableSuggestionName.Add(sVariableName);
        FslVariableSuggestionValue.Add(sVariableValue);
      end;
    end
    else
    begin
      FActuallyRenamingFile := False;
      exit;
    end;
  end;
  Result := FslVariableValues.Strings[iVariableIndex];
end;

{ TfrmMultiRename.sReplaceBadChars }//Replace bad path chars in string
function TfrmMultiRename.sReplaceBadChars(const sPath: string): string;
const
{$IFDEF MSWINDOWS}
  ForbiddenChars: set of char = ['<', '>', ':', '"', '/', '\', '|', '?', '*'];
{$ELSE}
  ForbiddenChars: set of char = ['/'];
{$ENDIF}
var
  Index: integer;
begin
  Result := '';
  for Index := 1 to Length(sPath) do
    if not (sPath[Index] in ForbiddenChars) then
      Result += sPath[Index]
    else
      Result += MRConfig.InvalidCharReplacement;
end;

{ TfrmMultiRename.IsLetter }
function TfrmMultiRename.IsLetter(AChar: AnsiChar): boolean;
begin
  Result :=  // Ascii letters
    ((AChar < #128) and
    (((AChar >= 'a') and (AChar <= 'z')) or
    ((AChar >= 'A') and (AChar <= 'Z')))) or
    // maybe Ansi or UTF8
    (AChar >= #128);
end;

{ TfrmMultiRename.ApplyStyle }
// Applies style (uppercase, lowercase, etc.) to a string.
function TfrmMultiRename.ApplyStyle(InputString: string; Style: integer): string;
begin
  case Style of
    1: Result := UTF8UpperCase(InputString);
    2: Result := UTF8LowerCase(InputString);
    3: Result := FirstCharOfFirstWordToUppercaseUTF8(InputString);
    4: Result := FirstCharOfEveryWordToUppercaseUTF8(InputString);
    else
      Result := InputString;
  end;
end;

{ TfrmMultiRename.FirstCharToUppercaseUTF8 }
// Changes first char to uppercase and the rest to lowercase
function TfrmMultiRename.FirstCharToUppercaseUTF8(InputString: string): string;
var
  FirstChar: string;
begin
  if UTF8Length(InputString) > 0 then
  begin
    Result := UTF8LowerCase(InputString);
    FirstChar := UTF8Copy(Result, 1, 1);
    UTF8Delete(Result, 1, 1);
    Result := UTF8UpperCase(FirstChar) + Result;
  end
  else
    Result := '';
end;

{ TfrmMultiRename.FirstCharOfFirstWordToUppercaseUTF8 }
// Changes first char of first word to uppercase and the rest to lowercase
function TfrmMultiRename.FirstCharOfFirstWordToUppercaseUTF8(InputString: string): string;
var
  SeparatorPos: integer;
begin
  InputString := UTF8LowerCase(InputString);
  Result := '';

  // Search for first letter.
  for SeparatorPos := 1 to Length(InputString) do
    if IsLetter(InputString[SeparatorPos]) then
      break;

  Result := Copy(InputString, 1, SeparatorPos - 1) + FirstCharToUppercaseUTF8(Copy(InputString, SeparatorPos, Length(InputString) - SeparatorPos + 1));
end;

{ TfrmMultiRename.FirstCharOfEveryWordToUppercaseUTF8 }
// Changes first char of every word to uppercase and the rest to lowercase
function TfrmMultiRename.FirstCharOfEveryWordToUppercaseUTF8(InputString: string): string;
var
  SeparatorPos: integer;
begin
  InputString := UTF8LowerCase(InputString);
  Result := '';

  while InputString <> '' do
  begin
    // Search for first non-letter (word separator).
    for SeparatorPos := 1 to Length(InputString) do
      if not IsLetter(InputString[SeparatorPos]) then
        break;

    Result := Result + FirstCharToUppercaseUTF8(Copy(InputString, 1, SeparatorPos));

    Delete(InputString, 1, SeparatorPos);
  end;
end;

procedure TfrmMultiRename.LoadNamesFromList(const AFileList: TStrings);
begin
  if AFileList.Count <> FFiles.Count then
  begin
    MessageDlg(Format(rsMulRenWrongLinesNumber, [AFileList.Count, FFiles.Count]), mtError, [mbOK], 0);
  end
  else
  begin
    FNames.Assign(AFileList);

    gbMaska.Enabled := False;
    gbPresets.Enabled := False;
    gbCounter.Enabled := False;

    StringGridTopLeftChanged(StringGrid);
  end;
end;

{ TfrmMultiRename.LoadNamesFromFile }
procedure TfrmMultiRename.LoadNamesFromFile(const AFileName: string);
var
  AFileList: TStringList;
begin
  AFileList := TStringList.Create;
  try
    AFileList.LoadFromFile(AFileName);
    LoadNamesFromList(AFileList);
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
  AFileList.Free;
end;

{ TfrmMultiRename.FreshText }
function TfrmMultiRename.FreshText(ItemIndex: integer): string;
var
  I: integer;
  bError: boolean;
  wsText: UnicodeString;
  wsReplace: UnicodeString;
  Flags: TReplaceFlags = [];
  sTmpName, sTmpExt: string;
begin
  bError := False;

  if FNames.Count > 0 then
    Result := FNames[ItemIndex]
  else
  begin
    // Use mask
    sTmpName := sReplace(cbName.Text, ItemIndex);
    sTmpExt := sReplace(cbExt.Text, ItemIndex);

    // Join
    Result := sTmpName;
    if sTmpExt <> '' then
      Result := Result + '.' + sTmpExt;
  end;

  // Find and replace
  if (edFind.Text <> '') then
  begin
    if cbRepExt.Checked then
      sTmpName := Result
    else begin
      sTmpExt := ExtractFileExt(Result);
      sTmpName := Copy(Result, 1, Length(Result) - Length(sTmpExt));
    end;
    if cbRegExp.Checked then
    try
      wsText:= UTF8Decode(sTmpName);
      wsReplace:= UTF8Decode(edReplace.Text);
      FRegExp.ModifierI := not cbCaseSens.Checked;

      if not cbOnlyFirst.Checked then
      begin
        sTmpName := CeUtf16ToUtf8(FRegExp.Replace(wsText, wsReplace, cbUseSubs.Checked));
      end
      else if FRegExp.Exec(wsText) then
      begin
        Delete(wsText, FRegExp.MatchPos[0], FRegExp.MatchLen[0]);
        if cbUseSubs.Checked then
          Insert(FRegExp.Substitute(wsReplace), wsText, FRegExp.MatchPos[0])
        else begin
          Insert(wsReplace, wsText, FRegExp.MatchPos[0]);
        end;
        sTmpName:= CeUtf16ToUtf8(wsText);
      end;
    except
      Result := rsMsgErrRegExpSyntax;
      bError := True;
    end
    else begin
      if not cbOnlyFirst.Checked then
        Flags:= [rfReplaceAll];
      if not cbCaseSens.Checked then
        Flags+= [rfIgnoreCase];
      // Many at once, split find and replace by |
      if (FReplaceText.Count = 0) then
        FReplaceText.Add('');
      for I := 0 to FFindText.Count - 1 do
        sTmpName := UTF8StringReplace(sTmpName, FFindText[I], FReplaceText[Min(I, FReplaceText.Count - 1)], Flags);
    end;
    if not bError then
    begin
      if cbRepExt.Checked then
        Result := sTmpName
      else begin
        Result := sTmpName + sTmpExt;
      end;
    end;
  end;

  if not bError then
  begin
    // File name style
    sTmpExt := ExtractFileExt(Result);
    sTmpName := Copy(Result, 1, Length(Result) - Length(sTmpExt));

    sTmpName := ApplyStyle(sTmpName, cbNameMaskStyle.ItemIndex);
    sTmpExt := ApplyStyle(sTmpExt, cmbExtensionStyle.ItemIndex);

    Result := sTmpName + sTmpExt;
  end;

  actRename.Enabled := not bError;

  if bError then
  begin
    edFind.Color := clRed;
    edFind.Font.Color := clWhite;
  end
  else
  begin
    edFind.Color := clDefault;
    edFind.Font.Color := clDefault;
  end;
end;

{ TfrmMultiRename.sHandleFormatString }
function TfrmMultiRename.sHandleFormatString(const sFormatStr: string; ItemNr: integer): string;
var
  aFile: TFile;
  Index: int64;
  Counter: int64;
  Dirs: TStringArray;
  G: TGUID;
begin
  Result := '';
  if Length(sFormatStr) > 0 then
  begin
    aFile := FFiles[ItemNr];
    case sFormatStr[1] of
      '[', ']':
      begin
        Result := sFormatStr;
      end;

      'N':
      begin
        Result := sReplaceXX(sFormatStr, aFile.NameNoExt);
      end;

      'E':
      begin
        Result := sReplaceXX(sFormatStr, aFile.Extension);
      end;

      'A':
      begin
        Result := sReplaceBadChars(sReplaceXX(sFormatStr, aFile.FullPath));
      end;

      'G':
      begin
        // [独立版] 用标准 CreateGUID 替代 DCGetNewGUID
        CreateGUID(G);
        Result := GuidToString(G);
      end;

      'V':
      begin
        if FActuallyRenamingFile then
          Result := sReplaceVariable(sFormatStr)
        else
          Result := '[' + sFormatStr + ']';
      end;

      'C':
      begin
        // Check for start value after C, e.g. C12
        if not TryStrToInt64(Copy(sFormatStr, 2, MaxInt), Index) then
          Index := StrToInt64Def(edPoc.Text, 1);
        Counter := Index + StrToInt64Def(edInterval.Text, 1) * ItemNr;
        Result := Format('%.' + cmbxWidth.Items[cmbxWidth.ItemIndex] + 'd', [Counter]);
      end;

      'P':  // sub path index
      begin
        Index := StrToIntDef(Copy(sFormatStr, 2, MaxInt), 0);
        Dirs := (aFile.Path + ' ').Split([PathDelim]);
        Dirs[High(Dirs)] := EmptyStr;
        if Index < 0 then
          Result := Dirs[Max(0, High(Dirs) + Index)]
        else
          Result := Dirs[Min(Index, High(Dirs))];
      end;

      '=':
      begin
        // [独立版] 不支持 [=Plugin()] 语法，返回空字符串
        Result := '';
      end;

      else
      begin
        // Assume it is date/time formatting string ([h][n][s][Y][M][D]).
        // [独立版] TFile.ModificationTime 直接可用，不需要 SupportedProperties 检查
        with FFiles.Items[ItemNr] do
          if ModificationTime <> 0 then
            try
              Result := FormatDateTime(sFormatStr, ModificationTime);
            except
              Result := sFormatStr;
            end;
      end;
    end;
  end;
end;


{ TfrmMultiRename.SetOutputGlobalRenameLogFilename }
procedure TfrmMultiRename.SetOutputGlobalRenameLogFilename;
begin
  if MRConfig.DailyIndividualDirLog then
    fneRenameLogFileFilename.FileName := mbExpandFileName(ExtractFilePath(MRConfig.LogFilename) + IncludeTrailingPathDelimiter(FormatDateTime('yyyy-mm-dd', Date)) + ExtractFilename(MRConfig.LogFilename))
  else
    fneRenameLogFileFilename.FileName := MRConfig.LogFilename;
end;

{ TfrmMultiRename.cm_ResetAll }
procedure TfrmMultiRename.cm_ResetAll(const Params: array of string);
var
  Param: string;
  bNeedRefreshActivePresetCommands: boolean = True;
begin
  for Param in Params do
    GetParamBoolValue(Param, sREFRESHCOMMANDS, bNeedRefreshActivePresetCommands);

  cbName.Text := '[N]';
  cbName.SelStart := UTF8Length(cbName.Text);
  cbExt.Text := '[E]';
  cbExt.SelStart := UTF8Length(cbExt.Text);
  edFind.Text := '';
  edReplace.Text := '';
  cbRepExt.Checked := True;
  cbRegExp.Checked := False;
  cbUseSubs.Checked := False;
  cbCaseSens.Checked := False;
  cbOnlyFirst.Checked := False;
  cbNameMaskStyle.ItemIndex := 0;
  cmbExtensionStyle.ItemIndex := 0;
  edPoc.Text := '1';
  edInterval.Text := '1';
  cmbxWidth.ItemIndex := 0;

  case MRConfig.SaveRenamingLog of
    mrsrlPerPreset:
    begin
      cbLog.Checked := False;
      cbLog.Enabled := True;
      cbLogAppend.Checked := False;
      fneRenameLogFileFilename.Enabled := cbLog.Checked;
      actViewRenameLogFile.Enabled := cbLog.Checked;
      cbLogAppend.Enabled := cbLog.Checked;
      if (FFiles.Count > 0) then
        fneRenameLogFileFilename.FileName := FFiles[0].Path + sDEFAULTLOGFILENAME
      else
        fneRenameLogFileFilename.FileName := sDEFAULTLOGFILENAME;
    end;

    mrsrlAppendSameLog:
    begin
      cbLog.Checked := True;
      cbLog.Enabled := False;
      cbLogAppend.Checked := True;
      cbLogAppend.Enabled := False;
      fneRenameLogFileFilename.Enabled := False;
      SetOutputGlobalRenameLogFilename;
      actViewRenameLogFile.Enabled := cbLog.Checked;
    end;
  end;

  cbPresets.Text := '';
  FNames.Clear;
  gbMaska.Enabled := True;
  gbPresets.Enabled := True;
  cbPresets.ItemIndex := 0;
  gbCounter.Enabled := True;

  // 排序选项重置为默认（名称升序），同步到配置并重排当前列表
  cmbAddSort.ItemIndex := Ord(mrsoNameAsc);
  MRConfig.AddSortOrder := mrsoNameAsc;
  SortFileList;

  StringGridTopLeftChanged(StringGrid);
  if bNeedRefreshActivePresetCommands then
    RefreshActivePresetCommands;
end;

{ TfrmMultiRename.cm_InvokeEditor }
procedure TfrmMultiRename.cm_InvokeEditor(const {%H-}Params: array of string);
var
  pt: TPoint;
begin
  // [独立版] 内联 DCPlaceCursorNearControlIfNecessary 的逻辑
  pt := btnEditor.ClientToScreen(Point(btnEditor.Width div 2, btnEditor.Height div 2));
  if (Abs(Mouse.CursorPos.X - pt.X) > (btnEditor.Width div 2)) or
     (Abs(Mouse.CursorPos.Y - pt.Y) > (btnEditor.Height div 2)) then
    Mouse.CursorPos := Point(pt.X + (btnEditor.Width div 2) - 10, pt.Y);
  pmEditDirect.PopUp;
end;

{ TfrmMultiRename.cm_LoadNamesFromFile }
procedure TfrmMultiRename.cm_LoadNamesFromFile(const {%H-}Params: array of string);
var
  OpenDialog: TOpenDialog;
begin
  // [独立版] 用本地 TOpenDialog 替代 Double Commander 的 dmComData.OpenDialog
  OpenDialog := TOpenDialog.Create(Self);
  try
    OpenDialog.FileName := EmptyStr;
    OpenDialog.Filter := EmptyStr;
    if OpenDialog.Execute then
      LoadNamesFromFile(OpenDialog.FileName);
  finally
    OpenDialog.Free;
  end;
end;

procedure TfrmMultiRename.cm_LoadNamesFromClipboard(
  const Params: array of string);
var
  AFileList: TStringList;
begin
  AFileList := TStringList.Create;
  try
    AFileList.Text := Clipboard.AsText;
    LoadNamesFromList(AFileList);
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
  AFileList.Free;
end;

{ TfrmMultiRename.cm_EditNames }
procedure TfrmMultiRename.cm_EditNames(const {%H-}Params: array of string);
var
  I: integer;
  AFileName: string;
  AFileList: TStringList;
begin
  AFileList := TStringList.Create;
  AFileName := GetTempFolderDeletableAtTheEnd;
  AFileName := GetTempName(AFileName, 'txt');
  if FNames.Count > 0 then
    AFileList.Assign(FNames)
  else
  begin
    for I := 0 to FFiles.Count - 1 do
      AFileList.Add(FFiles[I].Name);
  end;
  try
    AFileList.SaveToFile(AFileName);
    try
      if ShowMultiRenameWaitForm(AFileName, Self) then
        LoadNamesFromFile(AFileName);
    finally
      mbDeleteFile(AFileName);
    end;
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
  AFileList.Free;
end;

{ TfrmMultiRename.cm_EditNewNames }
procedure TfrmMultiRename.cm_EditNewNames(const {%H-}Params: array of string);
var
  sFileName: string;
  iIndexFile: integer;
  AFileList: TStringList;
begin
  AFileList := TStringList.Create;
  try
    for iIndexFile := 0 to pred(FFiles.Count) do
      AFileList.Add(FreshText(iIndexFile));
    sFileName := GetTempName(GetTempFolderDeletableAtTheEnd, 'txt');
    try
      AFileList.SaveToFile(sFileName);
      try
        if ShowMultiRenameWaitForm(sFileName, Self) then
          LoadNamesFromFile(sFileName);
      finally
        mbDeleteFile(sFileName);
      end;
    except
      on E: Exception do
        MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
  finally
    AFileList.Free;
  end;
end;

{ TfrmMultiRename.cm_Config }
procedure TfrmMultiRename.cm_Config(const {%H-}Params: array of string);
begin
  // [独立版] 配置窗口待实现，暂时弹提示
  MessageDlg('配置功能待实现', mtInformation, [mbOK], 0);
end;

{ TfrmMultiRename.cm_AddFiles }
procedure TfrmMultiRename.cm_AddFiles(const {%H-}Params: array of string);
var
  dlg: TOpenDialog;
  I: integer;
  Paths: array of string;
begin
  dlg := TOpenDialog.Create(Self);
  try
    dlg.Options := dlg.Options + [ofAllowMultiSelect, ofFileMustExist];
    dlg.Title   := '选择文件';
    if dlg.Execute then
    begin
      SetLength(Paths, dlg.Files.Count);
      for I := 0 to dlg.Files.Count - 1 do
        Paths[I] := dlg.Files[I];
      AddFilesToList(Paths);
    end;
  finally
    dlg.Free;
  end;
end;

{ TfrmMultiRename.SortFileList }
// 按 MRConfig.AddSortOrder 对 FFiles 原地排序
procedure TfrmMultiRename.SortFileList;
var
  I, J, MinIdx: integer;
  Tmp: TFile;

  function CompareFiles(A, B: TFile): integer;
  begin
    case MRConfig.AddSortOrder of
      mrsoNameAsc:  Result :=  NaturalCompareFileNames(A.Name, B.Name);
      mrsoNameDesc: Result := -NaturalCompareFileNames(A.Name, B.Name);
      mrsoTimeAsc:  Result :=  CompareDateTime(A.ModificationTime, B.ModificationTime);
      mrsoTimeDesc: Result := -CompareDateTime(A.ModificationTime, B.ModificationTime);
    else
      Result := 0;
    end;
  end;

begin
  if (MRConfig.AddSortOrder = mrsoNone) or (FFiles.Count < 2) then Exit;

  // 选择排序（文件数通常不大，够用）
  for I := 0 to FFiles.Count - 2 do
  begin
    MinIdx := I;
    for J := I + 1 to FFiles.Count - 1 do
      if CompareFiles(TFile(FFiles[J]), TFile(FFiles[MinIdx])) < 0 then
        MinIdx := J;
    if MinIdx <> I then
    begin
      Tmp          := TFile(FFiles[I]);
      FFiles[I]    := FFiles[MinIdx];
      FFiles[MinIdx] := Tmp;
    end;
  end;
end;

{ TfrmMultiRename.AddFilesToList }
// 把路径数组里的文件加入 FFiles，排序后刷新 Grid
procedure TfrmMultiRename.AddFilesToList(const APaths: array of string);
var
  I, J: integer;
  F: TFile;
  SR: TSearchRec;
  Path: string;
  AlreadyExists: boolean;
begin
  for I := 0 to High(APaths) do
  begin
    Path := APaths[I];
    // 跳过目录
    if DirectoryExists(Path) then Continue;
    // 去重：同一完整路径不重复添加
    AlreadyExists := False;
    for J := 0 to FFiles.Count - 1 do
      if CompareText(TFile(FFiles[J]).FullPath, Path) = 0 then
      begin
        AlreadyExists := True;
        Break;
      end;
    if AlreadyExists then Continue;

    F      := TFile.Create(ExtractFilePath(Path));
    F.Name := ExtractFileName(Path);
    if FindFirst(Path, faAnyFile, SR) = 0 then
    begin
      F.ModificationTime := FileDateToDateTime(SR.Time);
      F.Size             := SR.Size;
      FindClose(SR);
    end;
    FFiles.Add(F);
  end;

  SortFileList;

  StringGrid.RowCount := FFiles.Count + 1;
  StringGridTopLeftChanged(StringGrid);
  SetConfigurationState(CONFIG_NOTSAVED);
end;

{ TfrmMultiRename.FormDropFiles }
// OS 级拖拽回调（从资源管理器拖入）
procedure TfrmMultiRename.FormDropFiles(Sender: TObject; const FileNames: array of string);
begin
  AddFilesToList(FileNames);
end;

{ TfrmMultiRename.cmbAddSortChange }
// 排序下拉切换：保存设置并对当前列表重排
procedure TfrmMultiRename.cmbAddSortChange(Sender: TObject);
begin
  MRConfig.AddSortOrder := TMulRenAddSortOrder(cmbAddSort.ItemIndex);
  SortFileList;
  StringGrid.RowCount := FFiles.Count + 1;
  StringGridTopLeftChanged(StringGrid);
end;

{ TfrmMultiRename.cm_Rename }
procedure TfrmMultiRename.cm_Rename(const {%H-}Params: array of string);
var
  AFile: TFile;
  NewName: string;
  I, J, K, OrigCount: integer;
  TempFiles: TStringList;
  OldFiles, NewFiles: TFiles;
  AutoRename: boolean = False;
  LogFileStream: TFileStream;
  OldPath, NewPath, LogName: string;
  FailCount: integer;
  FailMessages: TStringList;
begin
  FActuallyRenamingFile := True;
  try
    if cbLog.Checked then
    begin
      if fneRenameLogFileFilename.FileName = EmptyStr then
        fneRenameLogFileFilename.FileName := FFiles[0].Path + sDEFAULTLOGFILENAME;
      mbForceDirectory(ExtractFileDir(mbExpandFileName(fneRenameLogFileFilename.FileName)));
      FLog := TStringList.Create;
      if cbLogAppend.Checked then
        FLog.Add(';' + DateTimeToStr(Now) + ' - ' + rsMulRenLogStart);
    end;

    OldFiles  := FFiles.Clone;
    OrigCount := FFiles.Count;   // 记录原始文件数，用于区分 temp 两步走的两个阶段
    TempFiles := TStringList.Create;
    NewFiles := TFiles.Create(EmptyStr);
    FslVariableNames.Clear;
    FslVariableValues.Clear; //We don't clear the "Suggestion" parts because we may re-use them as their original values if we ever re-do rename pass witht he same instance.

    // OldNames
    FOldNames.Clear;
    for I := 0 to OldFiles.Count - 1 do
      FOldNames.Add(OldFiles[I].Name, Pointer(PtrInt(I)));

    try
      FNewNames.Clear;
      for I := 0 to FFiles.Count - 1 do
      begin
        AFile := TFile.Create(EmptyStr);
        AFile.Name := FreshText(I);

        //In "FreshText", if there was a "Variable on the fly / [V:Hint]" and the user aborted it, the "FActuallyRenamingFile" will be cleared and so we abort the actual renaming process.
        if not FActuallyRenamingFile then
          Exit;

        // Checking duplicates
        NewName := FFiles[I].Path + AFile.Name;
        J := FNewNames.Find(NewName);
        if J < 0 then
          FNewNames.Add(NewName)
        else
        begin
          if not AutoRename then
          begin
            if MessageDlg(rsMulRenWarningDuplicate + LineEnding +
              NewName + LineEnding + LineEnding + rsMulRenAutoRename,
              mtWarning, [mbYes, mbAbort], 0, mbAbort) <> mrYes then
              Exit;
            AutoRename := True;
          end;
          K := 1;
          while J >= 0 do
          begin
            NewName := FFiles[I].Path + AFile.NameNoExt + ' (' + IntToStr(K) + ')';
            if AFile.Extension <> '' then
              NewName := NewName + ExtensionSeparator + AFile.Extension;
            J := FNewNames.Find(NewName);
            Inc(K);
          end;
          FNewNames.Add(NewName);
          AFile.Name := ExtractFileName(NewName);
        end;

        // Avoid collisions with OldNames
        J := FOldNames.Find(AFile.Name);
        if (J >= 0) and (PtrUInt(FOldNames.List[J]^.Data) <> I) then
        begin
          NewName := AFile.Name;
          // Generate temp file name; store original FFiles index as object
          AFile.FullPath := GetTempName(FFiles[I].Path, IntToStr(I));
          TempFiles.AddObject(NewName, TObject(PtrUInt(I)));
        end;

        NewFiles.Add(AFile);
      end;

      // Rename temp files back
      if TempFiles.Count > 0 then
      begin
        for I := 0 to TempFiles.Count - 1 do
        begin
          // Temp file: OldFiles 里放持有临时名的 TFile clone
          // origIdx 是当初产生临时名时在 FFiles 里的索引
          // 注：AFile 在前面循环里已经把 FullPath 设成了临时文件名，
          //     NewFiles[origIdx] 里存的就是那个带临时名的 AFile
          OldFiles.Add(NewFiles[PtrUInt(TempFiles.Objects[I])].Clone);
          // Real new file name
          AFile := TFile.Create(EmptyStr);
          AFile.Name := TempFiles[I];
          NewFiles.Add(AFile);
        end;
      end;

      // [独立版] 直接用 RenameFile 替代 IFileSource + OperationsManager
      FailCount := 0;
      FailMessages := TStringList.Create;
      try
        for I := 0 to OldFiles.Count - 1 do
        begin
          OldPath := OldFiles[I].FullPath;
          NewPath := OldFiles[I].Path + NewFiles[I].Name;
          if OldPath = NewPath then
            Continue;
          if cbLog.Checked then
          begin
            if MRConfig.FilenameWithFullPathInLog then LogName := OldPath
            else LogName := OldFiles[I].Name;
          end;
          if RenameFile(OldPath, NewPath) then
          begin
            if I < OrigCount then
            begin
              // 第一步：检查该文件是否进入了 temp 两步走
              // 若进入了，此步改成临时名，FFiles 不更新（第二步里写最终名）
              // 若没进入，直接改名成功，立即更新
              if TempFiles.IndexOfObject(TObject(PtrUInt(I))) < 0 then
                FFiles[I].Name := NewFiles[I].Name;
            end
            else
            begin
              // 第二步：临时名 → 最终名，写回原始槽位
              FFiles[PtrUInt(TempFiles.Objects[I - OrigCount])].Name := NewFiles[I].Name;
            end;
            if cbLog.Checked then
              FLog.Add('OK      ' + LogName + ' -> ' + NewFiles[I].Name);
          end
          else
          begin
            Inc(FailCount);
            FailMessages.Add(OldFiles[I].Name + ' -> ' + NewFiles[I].Name +
                             LineEnding + '  ' + SysErrorMessage(GetLastOSError));
            if cbLog.Checked then
              FLog.Add('FAILED  ' + LogName + ' -> ' + NewFiles[I].Name +
                       ' (' + SysErrorMessage(GetLastOSError) + ')');
          end;
        end;

        // 有失败时弹窗汇报（与 DC 原版行为一致）
        if FailCount > 0 then
          MessageDlg(
            Format('重命名失败：%d 个文件' + LineEnding + LineEnding + '%s',
                   [FailCount, FailMessages.Text]),
            mtError, [mbOK], 0);
      finally
        FailMessages.Free;
      end;
      InsertFirstItem(cbExt.Text, cbExt);
      InsertFirstItem(cbName.Text, cbName);
    finally
      if cbLog.Checked then
      begin
        try
          if (cbLogAppend.Checked) and (FileExists(mbExpandFileName(fneRenameLogFileFilename.FileName))) then
          begin
            LogFileStream := TFileStream.Create(mbExpandFileName(fneRenameLogFileFilename.FileName), fmOpenWrite);
            try
              LogFileStream.Seek(0, soEnd);
              FLog.SaveToStream(LogFileStream);
            finally
              LogFileStream.Free;
            end;
          end
          else
          begin
            FLog.SaveToFile(mbExpandFileName(fneRenameLogFileFilename.FileName));
          end;
        except
          on E: Exception do
            MessageDlg(E.Message, mtError, [mbOK], 0);
        end;
        FLog.Free;
      end;
      OldFiles.Free;
      NewFiles.Free;
      TempFiles.Free;
    end;
  finally
    FActuallyRenamingFile := False;
  end;

  StringGridTopLeftChanged(StringGrid);
end;

{ TfrmMultiRename.cm_Close }
procedure TfrmMultiRename.cm_Close(const {%H-}Params: array of string);
begin
  Close;
end;

{ TfrmMultiRename.cm_ShowPresetsMenu }
procedure TfrmMultiRename.cm_ShowPresetsMenu(const {%H-}Params: array of string);
begin
  PopupDynamicMenuAtThisControl(pmPresets, btnPresets);
end;

{ TfrmMultiRename.cm_DropDownPresetList }
procedure TfrmMultiRename.cm_DropDownPresetList(const {%H-}Params: array of string);
begin
  if (not cbPresets.CanFocus) and (not cbPresets.Enabled) then
    if isOkToLosePresetModification = True then
      cbPresets.Enabled := True;

  if cbPresets.CanFocus then
  begin
    cbPresets.SetFocus;
    cbPresets.DroppedDown := True;
  end;
end;

{ TfrmMultiRename.cm_LoadPreset }
procedure TfrmMultiRename.cm_LoadPreset(const Params: array of string);
var
  sPresetName: string;
  PresetIndex: integer;
begin
  if isOkToLosePresetModification then
  begin
    //1.Get the preset name from the parameters.
    sPresetName := GetPresetNameForCommand(Params);

    //2.Make sure we got something.
    if sPresetName <> '' then
    begin
      //3.Make sure it is in our list.
      PresetIndex := FMultiRenamePresetList.Find(sPresetName);
      if PresetIndex <> -1 then
      begin
        cbName.Text := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].FileName;
        cbName.SelStart := UTF8Length(cbName.Text);
        cbExt.Text := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Extension;
        cbExt.SelStart := UTF8Length(cbExt.Text);
        cbNameMaskStyle.ItemIndex := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].FileNameStyle;
        cmbExtensionStyle.ItemIndex := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].ExtensionStyle;
        edFind.Text := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Find;
        edReplace.Text := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Replace;
        cbRepExt.Checked := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].RepExt;
        cbRegExp.Checked := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].RegExp;
        cbUseSubs.Checked := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].UseSubs;
        cbCaseSens.Checked := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].CaseSens;
        cbOnlyFirst.Checked := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].OnlyFirst;
        edPoc.Text := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Counter;
        edInterval.Text := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Interval;
        cmbxWidth.ItemIndex := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Width;

        case MRConfig.SaveRenamingLog of
          mrsrlPerPreset:
          begin
            cbLog.Checked := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Log;
            cbLogAppend.Checked := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].LogAppend;
            fneRenameLogFileFilename.FileName := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].LogFile;
          end;

          mrsrlAppendSameLog:
          begin
            FbRememberLog := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].Log;
            FbRememberAppend := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].LogAppend;
            FsRememberRenameLogFilename := FMultiRenamePresetList.MultiRenamePreset[PresetIndex].LogFile;
            SetOutputGlobalRenameLogFilename;
          end;
        end;

        //4.Preserved the last loaded setup.
        FLastPreset := sPresetName;

        //5.Refresh the whole thing.
        edFindChange(edFind);
        edReplaceChange(edReplace);

        //6.We might come here with parameter "index=x" so make sure we switch also the preset combo box to the same index.
        if PresetIndex >= cbPresets.Items.Count then
          PresetIndex := 0;
        if cbPresets.ItemIndex <> PresetIndex then
          cbPresets.ItemIndex := PresetIndex;

        //7.Since we've load the setup, activate things so we may change setup if necessary.
        SetConfigurationState(CONFIG_SAVED);

        //8. If we're from anything else the preset droplist itself, let's go to focus on the name ready to edit it if necessary..
        if (ActiveControl <> cbPresets) and (ActiveControl <> cbName) and (cbName.Enabled and gbMaska.Enabled) then
        begin
          ActiveControl := cbName;
          cbName.SelStart := UTF8Length(cbName.Text);
        end;
      end;
    end;
  end;
end;

{ TfrmMultiRename.cm_LoadLastPreset }
procedure TfrmMultiRename.cm_LoadLastPreset(const Params: array of string);
begin
  cm_LoadPreset(['index=0']);
end;

{ TfrmMultiRename.cm_SavePreset }
procedure TfrmMultiRename.cm_SavePreset(const Params: array of string);
begin
  if cbPresets.ItemIndex > 0 then
  begin
    SavePreset(cbPresets.Items.Strings[cbPresets.ItemIndex]);
    SetConfigurationState(CONFIG_SAVED);
  end;
end;

{ TfrmMultiRename.cm_SavePresetAs }
procedure TfrmMultiRename.cm_SavePresetAs(const Params: array of string);
var
  sNameForPreset: string;
  bKeepGoing: boolean;
begin
  sNameForPreset := GetPresetNameForCommand(Params);
  if sNameForPreset <> '' then
  begin
    bKeepGoing := True;
  end
  else
  begin
    if (FLastPreset = '') or (FLastPreset = sLASTPRESET) then
      sNameForPreset := rsMulRenDefaultPresetName
    else
      sNameForPreset := FLastPreset;
    bKeepGoing := InputQuery(Caption, rsMulRenPromptForSavedPresetName, sNameForPreset);
    if bKeepGoing then bKeepGoing := (sNameForPreset <> '');
  end;

  if bKeepGoing and (sNameForPreset <> FLastPreset) then
    if FMultiRenamePresetList.Find(sNameForPreset) <> -1 then
      if not MessageDlg(Format(rsMsgPresetAlreadyExists, [sNameForPreset]), mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        bKeepGoing := False;

  if bKeepGoing then
  begin
    SavePreset(sNameForPreset);

    if cbPresets.Items.IndexOf(sNameForPreset) = -1 then
    begin
      cbPresets.Items.Add(sNameForPreset);
    end;

    if cbPresets.ItemIndex <> cbPresets.Items.IndexOf(sNameForPreset) then
      cbPresets.ItemIndex := cbPresets.Items.IndexOf(sNameForPreset);

    SetConfigurationState(CONFIG_SAVED);
    RefreshActivePresetCommands;
  end;
end;

{ TfrmMultiRename.cm_RenamePreset }
// It also allow the at the same time to rename for changing case like "audio files" to "Audio Files".
procedure TfrmMultiRename.cm_RenamePreset(const Params: array of string);
var
  sCurrentName, sNewName: string;
  PresetIndex: integer;
  bKeepGoing: boolean;
begin
  sCurrentName := cbPresets.Items.Strings[cbPresets.ItemIndex];
  sNewName := sCurrentName;
  bKeepGoing := InputQuery(Caption, rsMulRenPromptNewPresetName, sNewName);
  if bKeepGoing and (sNewName <> '') and (sCurrentName <> sNewName) then
  begin
    PresetIndex := FMultiRenamePresetList.Find(sNewName);
    if (PresetIndex = -1) or (SameText(sCurrentName, sNewName)) then
    begin
      if SameText(FMultiRenamePresetList.MultiRenamePreset[cbPresets.ItemIndex].PresetName, cbPresets.Items.Strings[cbPresets.ItemIndex]) then
      begin
        FMultiRenamePresetList.MultiRenamePreset[cbPresets.ItemIndex].PresetName := sNewName;
        cbPresets.Items.Strings[cbPresets.ItemIndex] := sNewName;
      end;
    end
    else
    begin
      if MessageDlg(rsMulRenPromptNewNameExists, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        if SameText(FMultiRenamePresetList.MultiRenamePreset[PresetIndex].PresetName, cbPresets.Items.Strings[PresetIndex]) and SameText(FMultiRenamePresetList.MultiRenamePreset[cbPresets.ItemIndex].PresetName, cbPresets.Items.Strings[cbPresets.ItemIndex]) then
        begin
          FMultiRenamePresetList.MultiRenamePreset[cbPresets.ItemIndex].PresetName := sNewName;
          cbPresets.Items.Strings[cbPresets.ItemIndex] := sNewName;

          cbPresets.Items.Delete(PresetIndex);
          FMultiRenamePresetList.Delete(PresetIndex);
        end;
      end;
    end;
  end;
end;

{ TfrmMultiRename.cm_DeletePreset }
procedure TfrmMultiRename.cm_DeletePreset(const Params: array of string);
var
  Index: integer;
  sPresetName: string;
begin
  sPresetName := GetPresetNameForCommand(Params);

  if sPresetName = '' then
    if cbPresets.ItemIndex > 0 then
      sPresetName := cbPresets.Items.Strings[cbPresets.ItemIndex];

  if sPresetName <> '' then
  begin
    if MessageDlg(Format(rsMsgPresetConfigDelete, [sPresetName]), mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      DeletePreset(sPresetName);
      Index := cbPresets.Items.IndexOf(sPresetName);
      if Index = cbPresets.ItemIndex then
        cbPresets.ItemIndex := 0;
      if Index <> -1 then
        cbPresets.Items.Delete(Index);
      FillPresetsList;
    end;
  end;
end;

{ TfrmMultiRename.cm_SortPresets }
procedure TfrmMultiRename.cm_SortPresets(const Params: array of string);
var
  slLocalPresets: TStringList;
  iSeeker, iPresetIndex: integer;
begin
  if isOkToLosePresetModification then
  begin
    if FMultiRenamePresetList.Count > 1 then
    begin
      slLocalPresets := TStringList.Create;
      try
        for iSeeker := 1 to pred(FMultiRenamePresetList.Count) do
          slLocalPresets.Add(FMultiRenamePresetList.MultiRenamePreset[iSeeker].PresetName);

        if HaveUserSortThisList(Self, rsMulRenSortingPresets, slLocalPresets) = mrOk then
        begin
          for iSeeker := 0 to pred(slLocalPresets.Count) do
          begin
            iPresetIndex := FMultiRenamePresetList.Find(slLocalPresets.Strings[iSeeker]);
            if succ(iSeeker) <> iPresetIndex then
              FMultiRenamePresetList.Move(iPresetIndex, succ(iSeeker));
          end;
          FillPresetsList(cbPresets.Items.Strings[cbPresets.ItemIndex]);
        end;
      finally
        slLocalPresets.Free;
      end;
    end;
  end;
end;

{ TfrmMultiRename.cm_AnyNameMask }
procedure TfrmMultiRename.cm_AnyNameMask(const {%H-}Params: array of string);
begin
  pmFloatingMainMaskMenu.Items.Clear;
  PopulateFilenameMenu(pmFloatingMainMaskMenu);
  PopupDynamicMenuAtThisControl(pmFloatingMainMaskMenu, btnAnyNameMask);
end;

{ TfrmMultiRename.cm_ClearNameMask }
procedure TfrmMultiRename.cm_ClearNameMask(const {%H-}Params: array of string);
begin
  cbName.Text := '';
  cbNameStyleChange(cbExt);
  if cbName.CanFocus then
    cbName.SetFocus;
end;

{ TfrmMultiRename.cm_AnyExtMask }
procedure TfrmMultiRename.cm_AnyExtMask(const {%H-}Params: array of string);
begin
  pmFloatingMainMaskMenu.Items.Clear;
  PopulateExtensionMenu(pmFloatingMainMaskMenu);
  PopupDynamicMenuAtThisControl(pmFloatingMainMaskMenu, btnAnyExtMask);
end;

{ TfrmMultiRename.cm_ClearExtMask }
procedure TfrmMultiRename.cm_ClearExtMask(const {%H-}Params: array of string);
begin
  cbExt.Text := '';
  cbNameStyleChange(cbExt);
  if cbExt.CanFocus then cbExt.SetFocus;
end;

{ TfrmMultiRename.cm_ViewRenameLogFile }
procedure TfrmMultiRename.cm_ViewRenameLogFile(const {%H-}Params: array of string);
var
  sRenameLogFilename: string;
begin
  sRenameLogFilename := mbExpandFileName(fneRenameLogFileFilename.FileName);
  if FileExists(sRenameLogFilename) then
    OpenDocument(sRenameLogFilename)  // [独立版] 用系统默认程序打开，替代 ShowViewerByGlob
  else
    MessageDlg(Format(rsMsgFileNotFound, [sRenameLogFilename]), mtError, [mbOK], 0);
end;

{ ShowMultiRenameForm }
// [独立版] 保留此函数签名以兼容可能的外部调用。
// 正规启动路径是：lpr 将路径写入 MRConfig.StartupPaths，
// 再由 Application.CreateForm(TfrmMultiRename, ...) 触发无参构造函数读取。
// 此函数不再使用。
function ShowMultiRenameForm(const AFilePaths: TStringList; const PresetToLoad: string = ''): boolean;
begin
  Result := True;
  try
    with TfrmMultiRename.Create(Application, AFilePaths, PresetToLoad) do
      Show;
  except
    Result := False;
  end;
end;

initialization
  TFormCommands.RegisterCommandsForm(TfrmMultiRename, HotkeysCategoryMultiRename, @rsHotkeyCategoryMultiRename);

end.

