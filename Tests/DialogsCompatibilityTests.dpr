program DialogsCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Dialogs,
  PasSDL3.GUI.Types;

var
  CoreControl: PasSDL3.GUI.Controls.TGuiControl;
  Dialog: PasSDL3.GUI.Controls.Dialogs.TGuiDialog;
  Overlay: PasSDL3.GUI.Controls.Dialogs.TGuiModalOverlay;
  ModalResult: PasSDL3.GUI.Controls.TGuiModalResult;
  WindowMode: PasSDL3.GUI.Controls.TGuiDialogWindowMode;
  Buttons: PasSDL3.GUI.Controls.TGuiDialogButtons;
  WindowState: PasSDL3.GUI.Controls.TGuiDialogState;
  ActionButton: PasSDL3.GUI.Controls.TGuiButton;

begin
  Dialog:=PasSDL3.GUI.Controls.Dialogs.TGuiDialog.Create;
  Overlay:=PasSDL3.GUI.Controls.Dialogs.TGuiModalOverlay.Create;
  try
    CoreControl:=Dialog;
    CoreControl:=Overlay;
    ModalResult:=PasSDL3.GUI.Controls.gmrCustom;
    WindowMode:=PasSDL3.GUI.Controls.gdwmResizable;
    Buttons:=[PasSDL3.GUI.Controls.gdbMinimize, PasSDL3.GUI.Controls.gdbMaximize,
      PasSDL3.GUI.Controls.gdbClose];
    WindowState:=PasSDL3.GUI.Controls.gdsMaximized;
    if (CoreControl <> Overlay) OR (Ord(ModalResult) <> 6) OR
      (Ord(WindowMode) <> 3) OR (Buttons = []) OR (Ord(WindowState) <> 2) then
      Halt(1);
    Dialog.Padding:=GuiBoxLTRB(18, 56, 18, 18);
    Dialog.Arrange(GuiRect(0, 0, 500, 300));
    ActionButton:=PasSDL3.GUI.Controls.TGuiButton.Create;
    ActionButton.Bounds:=GuiRect(400, 194, 60, 32);
    Dialog.ClientPanel.Add(ActionButton);
    if Dialog.ButtonPanel.Visible then
      Halt(4);
    if Dialog.HitTest(GuiPoint(430, 260)) <> ActionButton then
      Halt(2);
    Dialog.AddButton('OK');
    if NOT Dialog.ButtonPanel.Visible then
      Halt(5);
    if Dialog.HitTest(GuiPoint(430, 260)) = ActionButton then
      Halt(3);
  finally
    Overlay.Free;
    Dialog.Free;
  end;
  WriteLn('PASS: aggregate dialog compatibility aliases preserve exact type identity');
end.
