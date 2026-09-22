program DialogsImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Dialogs;

var
  ModalResult: TGuiModalResult;
  WindowMode: TGuiDialogWindowMode;
  DialogButton: TGuiDialogButton;
  DialogButtons: TGuiDialogButtons;
  DialogState: TGuiDialogState;

begin
  ModalResult:=gmrCustom;
  WindowMode:=gdwmResizable;
  DialogButton:=gdbClose;
  DialogButtons:=[gdbMinimize, gdbMaximize, gdbClose];
  DialogState:=gdsMaximized;
  if (Ord(ModalResult) <> 6) OR (Ord(WindowMode) <> 3) OR
      (Ord(DialogButton) <> 2) OR (DialogButtons = []) OR
      (Ord(DialogState) <> 2) then
    Halt(1);
  CheckControlClass(TGuiDialog);
  CheckControlClass(TGuiModalOverlay);
  Pass('Dialogs');
end.
