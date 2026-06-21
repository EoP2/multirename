unit uLng;
// [独立版存根] 替代 DC 的 uLng

{$mode objfpc}{$H+}

interface

// uFormCommands 用到的
resourcestring
  rsCmdCategoryListInOrder = '';

// uconvencoding.pas（HexToBin）用到的，独立版存根此前遗漏，
// 一直是潜在的编译期缺口（与本轮热键精简无关，顺手补上）
resourcestring
  rsMsgInvalidHexNumber = 'Invalid hexadecimal number: "%s"';

const
  // uFormCommands 用到的简单词语常量
  rsSimpleWordAll      = 'All';
  rsSimpleWordCommand  = 'Command';
  rsSimpleWordCategory = 'Category';
  rsSimpleWordFilename = 'Filename';
  rsSimpleWordParameter = 'Param';
  rsSimpleWordWorkDir  = 'WorkDir';
  rsSimpleWordResult   = 'Result';
  rsSimpleWordVariable = 'Variable';

implementation

end.
