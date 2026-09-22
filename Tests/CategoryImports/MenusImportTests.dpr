program MenusImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Menus;

var
  Item: TGuiMenuItem;

begin
  Item:=TGuiMenuItem.Create('Item');
  Item.Free;
  CheckControlClass(TGuiMenuBar);
  CheckControlClass(TGuiPopupMenu);
  CheckControlClass(TGuiDropDownButton);
  Pass('Menus');
end.
