program MenusCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Menus;

var
  CoreItem: PasSDL3.GUI.Controls.TGuiMenuItem;
  CoreBar: PasSDL3.GUI.Controls.TGuiMenuBar;
  CorePopup: PasSDL3.GUI.Controls.TGuiPopupMenu;
  CoreDropDown: PasSDL3.GUI.Controls.TGuiDropDownButton;
  Item: PasSDL3.GUI.Controls.Menus.TGuiMenuItem;
  Bar: PasSDL3.GUI.Controls.Menus.TGuiMenuBar;
  Popup: PasSDL3.GUI.Controls.Menus.TGuiPopupMenu;
  DropDown: PasSDL3.GUI.Controls.Menus.TGuiDropDownButton;

begin
  Item:=PasSDL3.GUI.Controls.Menus.TGuiMenuItem.Create('item');
  Bar:=PasSDL3.GUI.Controls.Menus.TGuiMenuBar.Create;
  Popup:=PasSDL3.GUI.Controls.Menus.TGuiPopupMenu.Create;
  DropDown:=PasSDL3.GUI.Controls.Menus.TGuiDropDownButton.Create;
  try
    CoreItem:=Item;
    CoreBar:=Bar;
    CorePopup:=Popup;
    CoreDropDown:=DropDown;
    if (CoreItem <> Item) OR (CoreBar <> Bar) OR
      (CorePopup <> Popup) OR (CoreDropDown <> DropDown) then
      Halt(1);
  finally
    DropDown.Free;
    Popup.Free;
    Bar.Free;
    Item.Free;
  end;
  WriteLn('PASS: aggregate menu compatibility aliases preserve exact type identity');
end.
