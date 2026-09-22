program TextCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Text;

var
  CoreLabel: PasSDL3.GUI.Controls.TGuiLabel;
  CoreLink: PasSDL3.GUI.Controls.TGuiLinkLabel;
  CoreValue: PasSDL3.GUI.Controls.TGuiValueLabel;
  CoreEdit: PasSDL3.GUI.Controls.TGuiEdit;
  CoreMemo: PasSDL3.GUI.Controls.TGuiMemo;
  CoreSpin: PasSDL3.GUI.Controls.TGuiSpinEdit;
  LabelControl: PasSDL3.GUI.Controls.Text.TGuiLabel;
  Link: PasSDL3.GUI.Controls.Text.TGuiLinkLabel;
  ValueLabel: PasSDL3.GUI.Controls.Text.TGuiValueLabel;
  Edit: PasSDL3.GUI.Controls.Text.TGuiEdit;
  Memo: PasSDL3.GUI.Controls.Text.TGuiMemo;
  Spin: PasSDL3.GUI.Controls.Text.TGuiSpinEdit;
  CoreState: PasSDL3.GUI.Controls.TGuiEditState;
  State: PasSDL3.GUI.Controls.Text.TGuiEditState;

begin
  LabelControl:=PasSDL3.GUI.Controls.Text.TGuiLabel.Create;
  Link:=PasSDL3.GUI.Controls.Text.TGuiLinkLabel.Create;
  ValueLabel:=PasSDL3.GUI.Controls.Text.TGuiValueLabel.Create;
  Edit:=PasSDL3.GUI.Controls.Text.TGuiEdit.Create;
  Memo:=PasSDL3.GUI.Controls.Text.TGuiMemo.Create;
  Spin:=PasSDL3.GUI.Controls.Text.TGuiSpinEdit.Create;
  try
    CoreLabel:=LabelControl;
    CoreLink:=Link;
    CoreValue:=ValueLabel;
    CoreEdit:=Edit;
    CoreMemo:=Memo;
    CoreSpin:=Spin;
    State.Text:='state';
    State.Caret:=5;
    State.Anchor:=0;
    CoreState:=State;
    if (CoreLabel <> LabelControl) OR (CoreLink <> Link) OR
      (CoreValue <> ValueLabel) OR (CoreEdit <> Edit) OR
      (CoreMemo <> Memo) OR (CoreSpin <> Spin) OR
      (CoreState.Text <> 'state') OR (CoreState.Caret <> 5) OR
      (CoreState.Anchor <> 0) then
      Halt(1);
  finally
    Spin.Free;
    Memo.Free;
    Edit.Free;
    ValueLabel.Free;
    Link.Free;
    LabelControl.Free;
  end;
  WriteLn('PASS: aggregate text compatibility aliases preserve exact type identity');
end.
