{
   Double Commander
   -------------------------------------------------------------------------
   Multi-Rename path range selector dialog window

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

unit fSelectPathRange;

{$mode objfpc}{$H+}

interface

uses
  //Lazarus, Free-Pascal, etc.
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ButtonPanel, Buttons, ExtCtrls,

  //DC
  uOSForms;

type
  { TfrmSelectPathRange }

  TfrmSelectPathRange = class(TModalForm)
    lblSelectDirectories: TLabel;
    lbDirectories: TListBox;
    pnlChoices: TPanel;
    gbCountFrom: TGroupBox;
    rbFirstFromStart: TRadioButton;
    rbFirstFromEnd: TRadioButton;
    edSeparator: TLabeledEdit;
    lblResult: TLabel;
    lblValueToReturn: TLabel;
    ButtonPanel: TButtonPanel;
    procedure FormCreate(Sender: TObject);
    procedure edtSelectTextKeyUp(Sender: TObject; var {%H-}Key: word; {%H-}Shift: TShiftState);
    procedure edtSelectTextMouseUp(Sender: TObject; {%H-}Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: integer);
    procedure lbDirectoriesSelectionChange(Sender: TObject; {%H-}User: boolean);
    procedure SomethingChange(Sender: TObject);
  private
    FPrefix: string;
    procedure ResfreshHint;
    procedure SaveWindowState;
  public
    property Prefix: string read FPrefix write FPrefix;
  end;

function ShowSelectPathRangeDlg(TheOwner: TCustomForm; const ACaption, AText, sPrefix: string; var sResultingMaskValue: string): boolean;

implementation

{$R *.lfm}

uses
  //Lazarus, Free-Pascal, etc.

  //独立版：窗口状态/分隔符改用 MRConfig 统一持久化（替代原 uGlobs）
  uMRConfig;

{ TfrmSelectPathRange }

{ TfrmSelectPathRange.FormCreate }
procedure TfrmSelectPathRange.FormCreate(Sender: TObject);
begin
  // 从 MRConfig 恢复窗口位置/宽度（0 = 未保存过，使用 LFM 默认值）
  if MRConfig.SelPathRangeWidth > 0 then Width := MRConfig.SelPathRangeWidth;
  if MRConfig.SelPathRangeLeft  > 0 then Left  := MRConfig.SelPathRangeLeft;
  if MRConfig.SelPathRangeTop   > 0 then Top   := MRConfig.SelPathRangeTop;
end;

{ TfrmSelectPathRange.SaveWindowState }
procedure TfrmSelectPathRange.SaveWindowState;
begin
  MRConfig.SelPathRangeLeft    := Left;
  MRConfig.SelPathRangeTop     := Top;
  MRConfig.SelPathRangeWidth   := Width;
  MRConfig.SelPathRangeFromEnd := rbFirstFromEnd.Checked;
end;

{ TfrmSelectPathRange.edtSelectTextKeyUp }
procedure TfrmSelectPathRange.edtSelectTextKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  SomethingChange(Sender);
end;

{ TfrmSelectPathRange.edtSelectTextMouseUp }
procedure TfrmSelectPathRange.edtSelectTextMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  SomethingChange(Sender);
end;

{ TfrmSelectPathRange.lbDirectoriesSelectionChange }
procedure TfrmSelectPathRange.lbDirectoriesSelectionChange(Sender: TObject; User: boolean);
begin
  SomethingChange(Sender);
end;

{ TfrmSelectPathRange.SomethingChange }
procedure TfrmSelectPathRange.SomethingChange(Sender: TObject);
begin
  ResfreshHint;
end;

{ TfrmSelectPathRange.ResfreshHint }
procedure TfrmSelectPathRange.ResfreshHint;
var
  sTempo: string;
  iSeeker: integer;
begin
  rbFirstFromEnd.Checked := not rbFirstFromStart.Checked;
  sTempo := '';
  for iSeeker := 0 to pred(lbDirectories.Items.Count) do
    if lbDirectories.Selected[iSeeker] then
    begin
      if sTempo <> '' then sTempo += edSeparator.Text;
      if rbFirstFromStart.Checked then
        sTempo += '[' + Prefix + IntToStr(iSeeker) + ']'
      else
        sTempo += '[' + Prefix + '-' + IntToStr(lbDirectories.Items.Count - iSeeker) + ']';
    end;

  lblValueToReturn.Caption := sTempo;
end;

{ ShowSelectPathRangeDlg }
function ShowSelectPathRangeDlg(TheOwner: TCustomForm; const ACaption, AText, sPrefix: string; var sResultingMaskValue: string): boolean;
var
  Directories: TStringArray;
  sDirectory: string;
begin
  with TfrmSelectPathRange.Create(TheOwner) do
    try
      Result := False;

      rbFirstFromStart.Checked := not MRConfig.SelPathRangeFromEnd;
      rbFirstFromEnd.Checked   := MRConfig.SelPathRangeFromEnd;
      edSeparator.Text := MRConfig.PathRangeSeparator;

      Caption := ACaption;
      Directories := (Trim(AText)).Split([PathDelim]);
      for sDirectory in Directories do
        lbDirectories.Items.Add(sDirectory);
      Prefix := sPrefix;

      if ShowModal = mrOk then
      begin
        if lblValueToReturn.Caption <> '' then
        begin
          MRConfig.PathRangeSeparator := edSeparator.Text;
          sResultingMaskValue := lblValueToReturn.Caption;
          Result := True;
        end;
      end;

      SaveWindowState;
    finally
      Free;
    end;
end;



end.

