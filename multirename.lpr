program multirename;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}
  {$R app.rc}  // 嵌入 Windows manifest（视觉样式、DPI 感知、长路径支持）
{$ENDIF}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,  // LCL widgetset
  Forms,
  SysUtils,
  Classes,
  FileUtil,    // compatibility helpers
  fMultiRename,
  uMRConfig,
  uMRApp;

var
  Form1: TfrmMultiRename;
  I: Integer;

begin
  Application.Initialize;
  Application.Title := '批量重命名';

  // 初始化配置（从可执行文件所在目录读取）
  MRConfig := TMRConfig.Create(MRGetConfigDir + 'multirename.ini');
  MRConfig.Load;
  try
    // 将命令行路径存入 MRConfig，供无参构造函数读取。
    // Application.CreateForm 只能调用无参构造函数，无法直接传参，
    // 因此通过 MRConfig 作为中转。
    for I := 1 to ParamCount do
      MRConfig.StartupPaths.Add(ParamStr(I));

    // 标准 LCL 做法：CreateForm 自动将第一个窗体设为 Application.MainForm，
    // 窗体关闭（caFree）后消息循环自动退出，进程正常结束。
    Application.CreateForm(TfrmMultiRename, Form1);
    Application.Run;
  finally
    MRConfig.Free;
  end;
end.
