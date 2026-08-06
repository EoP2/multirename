unit uOSForms;
// [独立版存根] 替代 DC 的 uOSForms

{$mode objfpc}{$H+}

interface

uses
  Forms, Classes, SysUtils;

type
  TAloneForm = class(TForm)
  protected
    // 独立版：关闭主窗口时终止整个进程（DC 里由 fMain 控制，独立版没有 fMain）
    procedure DoClose(var CloseAction: TCloseAction); override;
  public
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
  end;

  TModalDialog = class(TAloneForm)
  end;

  TModalForm = TModalDialog;

implementation

constructor TAloneForm.CreateNew(AOwner: TComponent; Num: Integer);
begin
  inherited CreateNew(AOwner, Num);
end;

procedure TAloneForm.DoClose(var CloseAction: TCloseAction);
begin
  inherited DoClose(CloseAction);
  // 只有顶层窗口（TfrmMultiRename）关闭时才退出
  // 对话框（TModalDialog 子类）不触发退出
  if not (Self is TModalDialog) then
    Application.Terminate;
end;

end.
