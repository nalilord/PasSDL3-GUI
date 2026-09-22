program ContainersImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Containers;

begin
  CheckControlClass(TGuiPanel);
  CheckControlClass(TGuiFrame);
  CheckControlClass(TGuiStackPanel);
  CheckControlClass(TGuiGridPanel);
  CheckControlClass(TGuiScrollBox);
  CheckControlClass(TGuiGroupBox);
  CheckControlClass(TGuiTransparentPanel);
  CheckControlClass(TGuiTransparentStackPanel);
  CheckControlClass(TGuiSplitter);
  Pass('Containers');
end.
