{
   Double Commander
   -------------------------------------------------------------------------
   Multi-Rename text range selector dialog window

   Copyright (C) 2007-2020 Alexander Koblov (alexx2000@mail.ru)

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
}

unit fSelectTextRange;

{$mode objfpc}{$H+}

interface

uses
  //Lazarus, Free-Pascal, etc.
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ButtonPanel, Buttons, ExtCtrls,

  //DC
  uOSForms;

type
  { TfrmSelectTextRange }

  TfrmSelectTextRange = class(TModalForm)
    ButtonPanel: TButtonPanel;
    edtSelectText: TEdit;
    gbRangeDescription: TGroupBox;
    gbCountFirstFrom: TGroupBox;
    gbCountLastFrom: TGroupBox;
    lblResult: TLabel;
    lblValueToReturn: TLabel;
    lblSelectText: TLabel;
    rbDescriptionFirstLast: TRadioButton;
    rbFirstFromStart: TRadioButton;
    rbLastFromStart: TRadioButton;
    rbDescriptionFirstLength: TRadioButton;
    rbFirstFromEnd: TRadioButton;
    rbLastFromEnd: TRadioButton;
    procedure edtSelectTextKeyUp(Sender: TObject; var {%H-}Key: word; {%H-}Shift: TShiftState);
    procedure edtSelectTextMouseUp(Sender: TObject; {%H-}Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: integer);
    procedure FormCreate(Sender: TObject);
    procedure SomethingChange(Sender: TObject);
  private
    FCanvaForAutosize: TControlCanvas;
    FSelStart, FSelFinish, FWholeLength: integer;
    FPrefix: string;
    procedure ResfreshHint;
    procedure SaveWindowState;
  public
    property Prefix: string read FPrefix write FPrefix;
  end;

function ShowSelectTextRangeDlg(TheOwner: TCustomForm; const ACaption, AText, sPrefix: string; var sResultingMaskValue: string): boolean;

implementation

{$R *.lfm}

uses
  //Lazarus, Free-Pascal, etc.

  //独立版：窗口状态/单选项改用 MRConfig 统一持久化（替代原 uGlobs）
  uMRConfig;

function ShowSelectTextRangeDlg(TheOwner: TCustomForm; const ACaption, AText, sPrefix: string; var sResultingMaskValue: string): boolean;
begin
  with TfrmSelectTextRange.Create(TheOwner) do
    try
      Result := False;

      Caption := ACaption;
      edtSelectText.Constraints.MinWidth := FCanvaForAutosize.TextWidth(AText) + 20;
      edtSelectText.Text := AText;
      Prefix := sPrefix;
      rbDescriptionFirstLast.Checked   := not MRConfig.SelTextRangeDescByLength;
      rbDescriptionFirstLength.Checked := MRConfig.SelTextRangeDescByLength;
      rbFirstFromStart.Checked := not MRConfig.SelTextRangeFirstFromEnd;
      rbFirstFromEnd.Checked   := MRConfig.SelTextRangeFirstFromEnd;
      rbLastFromStart.Checked  := not MRConfig.SelTextRangeLastFromEnd;
      rbLastFromEnd.Checked    := MRConfig.SelTextRangeLastFromEnd;

      if ShowModal = mrOk then
      begin
        if (FSelFinish >= FSelStart) and (lblValueToReturn.Caption <> '') then
        begin
          sResultingMaskValue := lblValueToReturn.Caption;
          Result := True;
        end;
      end;

      SaveWindowState;
    finally
      Free;
    end;
end;

{ TfrmSelectTextRange }

procedure TfrmSelectTextRange.SomethingChange(Sender: TObject);
begin
  ResfreshHint;
end;

procedure TfrmSelectTextRange.edtSelectTextKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  SomethingChange(Sender);
end;

procedure TfrmSelectTextRange.edtSelectTextMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  SomethingChange(Sender);
end;

procedure TfrmSelectTextRange.FormCreate(Sender: TObject);
begin
  // 从 MRConfig 恢复窗口位置/宽度（0 = 未保存过，使用 LFM 默认值）
  if MRConfig.SelTextRangeWidth > 0 then Width := MRConfig.SelTextRangeWidth;
  if MRConfig.SelTextRangeLeft  > 0 then Left  := MRConfig.SelTextRangeLeft;
  if MRConfig.SelTextRangeTop   > 0 then Top   := MRConfig.SelTextRangeTop;

  // TEdit "edtSelectText" does not have Canvas.
  // We will use "FCanvaForAutosize" to determine the required width to hold the whole text.
  // This way, we will see it all.
  FCanvaForAutosize := TControlCanvas.Create;
  FCanvaForAutosize.Control := edtSelectText;
  FCanvaForAutosize.Font.Assign(edtSelectText.Font);
end;

procedure TfrmSelectTextRange.SaveWindowState;
begin
  MRConfig.SelTextRangeLeft         := Left;
  MRConfig.SelTextRangeTop          := Top;
  MRConfig.SelTextRangeWidth        := Width;
  MRConfig.SelTextRangeDescByLength := rbDescriptionFirstLength.Checked;
  MRConfig.SelTextRangeFirstFromEnd := rbFirstFromEnd.Checked;
  MRConfig.SelTextRangeLastFromEnd  := rbLastFromEnd.Checked;
end;

procedure TfrmSelectTextRange.ResfreshHint;
var
  sTempo: string;
begin
  gbCountLastFrom.Enabled := not rbDescriptionFirstLength.Checked;

  sTempo := '';

  FSelStart := edtSelectText.SelStart + 1;
  FSelFinish := edtSelectText.SelStart + edtSelectText.SelLength;
  FWholeLength := length(edtSelectText.Text);

  if (FSelFinish >= FSelStart) and (FWholeLength > 0) then
  begin
    if rbFirstFromStart.Checked then
    begin
      if FSelFinish = FSelStart then
        sTempo := Format('%d', [FSelStart])
      else
      begin
        if rbDescriptionFirstLength.Checked then
          sTempo := Format('%d,%d', [FSelStart, succ(FSelFinish - FSelStart)])
        else if rbLastFromStart.Checked then
          sTempo := Format('%d:%d', [FSelStart, FSelFinish])
        else
          sTempo := Format('%d:-%d', [FSelStart, succ(FWholeLength - FSelFinish)]);
      end;
    end
    else
    begin
      if FSelFinish = FSelStart then
        sTempo := Format('-%d', [succ(FWholeLength - FSelStart)])
      else
      begin
        if rbDescriptionFirstLength.Checked then
          sTempo := Format('-%d,%d', [succ(FWholeLength - FSelFinish), succ(FSelFinish - FSelStart)])
        else if rbLastFromStart.Checked then
          sTempo := Format('-%d:%d', [succ(FWholeLength - FSelStart), FSelFinish])
        else
          sTempo := Format('-%d:-%d', [succ(FWholeLength - FSelStart), succ(FWholeLength - FSelFinish)]);
      end;
    end;

    lblValueToReturn.Caption := Format('[%s%s]', [Prefix, sTempo]);
  end
  else
  begin
    lblValueToReturn.Caption := '';
  end;
end;

end.










