unit uDCVersion;
// [独立版存根] 替代 DC 的 uDCVersion
// 原始版本依赖 dcrevision.inc（由构建系统生成，不在 git 中）
// 独立版提供固定的版本常量

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  // DC 版本号（uHotkeyManager 等只用来做兼容性检查，填固定值即可）
  dcVersionMajor   = 1;
  dcVersionMinor   = 0;
  dcVersionMicro   = 0;
  dcVersionBuild   = 0;
  dcVersion        = '1.0.0.0';
  dcRevision       = '0';

var
  // 运行时版本字符串（uHotkeyManager 会读这个）
  dcVersionString: string = '1.0.0';

implementation

end.
