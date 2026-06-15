unit uMRStrings;

{$mode objfpc}{$H+}

// 替代 DC 的 uLng。
// 所有 rsMulRen* 常量直接写死为简体中文。
// 以后要做多语言，改成 resourcestring 或 .po 文件即可。

interface

const
  // 文件名样式下拉列表（竖线分隔，ParseLineToList 用）
  rsMulRenFileNameStyleList = '不修改大小写|小写|大写|首字大写|每词首字大写';

  // 对话框标题 / 控件标签（直接对应 fmultirename.lfm 里的 Caption）
  rsMulRenFilename          = '文件名';
  rsMulRenExtension         = '扩展名';
  rsMulRenCounter           = '计数器';
  rsMulRenDate              = '日期';
  rsMulRenTime              = '时间';
  rsMulRenPlugins           = '插件';   // 独立版不显示此菜单，保留常量避免编译报错

  // Mask token 描述（菜单提示）
  rsMulRenMaskName               = '名称';
  rsMulRenMaskCharAtPosXtoY      = '截取名称片段';
  rsMulRenMaskExtension          = '扩展名';
  rsMulRenMaskFullName           = '带路径和扩展名的完整文件名';
  rsMulRenMaskFullNameCharAtPosXtoY = '截取完整文件名片段';
  rsMulRenMaskParent             = '父文件夹';
  rsMulRenMaskCounter            = '计数器';
  rsMulRenMaskGUID               = 'GUID';
  rsMulRenMaskVarOnTheFly        = '动态变量';
  rsMulRenMaskYear2Digits        = '年（01）';
  rsMulRenMaskYear4Digits        = '年（2001）';
  rsMulRenMaskMonth              = '月（2）';
  rsMulRenMaskMonth2Digits       = '月（02）';
  rsMulRenMaskMonthAbrev         = '月（2月）';
  rsMulRenMaskMonthComplete      = '月（二月）';
  rsMulRenMaskDay                = '日（3）';
  rsMulRenMaskDay2Digits         = '日（03）';
  rsMulRenMaskDOWAbrev           = '星期（周四）';
  rsMulRenMaskDOWComplete        = '星期（星期四）';
  rsMulRenMaskCompleteDate       = '完整日期';
  rsMulRenMaskHour               = '时（1）';
  rsMulRenMaskHour2Digits        = '时（01）';
  rsMulRenMaskMin                = '分（2）';
  rsMulRenMaskMin2Digits         = '分（02）';
  rsMulRenMaskSec                = '秒（3）';
  rsMulRenMaskSec2Digits         = '秒（03）';
  rsMulRenMaskCompleteTime       = '完整时间';

  // 操作消息
  rsMulRenWarningDuplicate  = '目标文件名重复：';
  rsMulRenAutoRename        = '是否自动重命名冲突文件？';
  rsMulRenLogStart          = '重命名开始';
  rsMulRenPromptForSavedPresetName  = '请输入预设名称';
  rsMulRenPromptNewPresetName       = '新预设名称：';
  rsMulRenPromptNewNameExists       = '该名称已存在，是否覆盖？';
  rsMulRenSaveModifiedPreset        = '当前预设已修改，是否保存？';
  rsMulRenDefaultPresetName         = '新预设';
  rsMulRenLastPreset                = '[上次使用]';
  rsMulRenSortingPresets            = '排序预设';
  rsMulRenWrongLinesNumber          = '名称列表行数与文件数量不符';
  rsMulRenEnterNameForVar           = '为变量 [V:%s] 输入名称';
  rsMulRenEnterValueForVar          = '为变量 [V:%s] 输入值';
  rsMulRenDefineVariableName        = '定义变量名称';
  rsMulRenDefineVariableValue       = '定义变量值';

  // 错误消息（来自 uLng）
  rsMsgErrRegExpSyntax    = '正则表达式语法错误：%s';
  rsMsgFileNotFound       = '文件未找到：%s';
  rsMsgPresetAlreadyExists= '预设已存在';
  rsMsgPresetConfigDelete = '确定要删除预设"%s"吗？';

  // 杂项
  rsSimpleWordVariable = '变量';


resourcestring
  // 热键分类显示名。TFormCommands.RegisterCommandsForm 需要 PResStringRec，
  // 因此这里必须是 resourcestring，不能是普通 const。
  rsHotkeyCategoryMultiRename = '批量重命名';

implementation

end.
