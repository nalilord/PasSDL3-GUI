program LayoutImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Layout;

begin
  CheckControlClass(TGuiStackPanel);
  CheckControlClass(TGuiGridPanel);
  Pass('Layout');
end.
