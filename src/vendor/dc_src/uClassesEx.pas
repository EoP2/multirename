unit uClassesEx;
// [独立版存根] 替代 DC 的 uClassesEx
// 原始依赖 SynEdit，独立版不需要，直接用标准类型

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniPropStorage;

type
  // DC 扩展的 TStringList，独立版直接等同于标准 TStringList
  TStringListEx = TStringList;

  // DC 扩展的 TIniPropStorage，独立版直接等同于标准版
  TIniPropStorageEx = TIniPropStorage;

implementation

end.
