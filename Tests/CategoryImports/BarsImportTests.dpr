program BarsImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Bars;

begin
  CheckControlClass(TGuiSeparator);
  CheckControlClass(TGuiStatusBar);
  CheckControlClass(TGuiToolBar);
  CheckControlClass(TGuiCommandBar);
  Pass('Bars');
end.
