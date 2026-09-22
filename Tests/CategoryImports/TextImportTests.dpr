program TextImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Text;

var
  EditState: TGuiEditState;

begin
  FillChar(EditState, SizeOf(EditState), 0);
  CheckControlClass(TGuiLabel);
  CheckControlClass(TGuiLinkLabel);
  CheckControlClass(TGuiValueLabel);
  CheckControlClass(TGuiEdit);
  CheckControlClass(TGuiMemo);
  CheckControlClass(TGuiSpinEdit);
  Pass('Text');
end.
