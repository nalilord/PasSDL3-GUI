program ProgressImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Progress;

begin
  CheckControlClass(TGuiActivityIndicator);
  CheckControlClass(TGuiProgressBar);
  Pass('Progress');
end.
