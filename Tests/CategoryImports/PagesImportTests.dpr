program PagesImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Pages;

var
  Position: TGuiTabPosition;

begin
  Position:=gtpBottom;
  if Ord(Position) <> 1 then
    Halt(1);
  CheckControlClass(TGuiTabButton);
  CheckControlClass(TGuiPageIndicator);
  CheckControlClass(TGuiTabControl);
  CheckControlClass(TGuiPage);
  CheckControlClass(TGuiPageControl);
  Pass('Pages');
end.
