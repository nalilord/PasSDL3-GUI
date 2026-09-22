program PagesCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Pages;

var
  CoreControl: PasSDL3.GUI.Controls.TGuiControl;
  TabButton: PasSDL3.GUI.Controls.Pages.TGuiTabButton;
  Indicator: PasSDL3.GUI.Controls.Pages.TGuiPageIndicator;
  Tabs: PasSDL3.GUI.Controls.Pages.TGuiTabControl;
  Page: PasSDL3.GUI.Controls.Pages.TGuiPage;
  Pages: PasSDL3.GUI.Controls.Pages.TGuiPageControl;
  CorePosition: PasSDL3.GUI.Controls.TGuiTabPosition;
  Position: PasSDL3.GUI.Controls.Pages.TGuiTabPosition;

begin
  TabButton:=PasSDL3.GUI.Controls.Pages.TGuiTabButton.Create;
  Indicator:=PasSDL3.GUI.Controls.Pages.TGuiPageIndicator.Create;
  Tabs:=PasSDL3.GUI.Controls.Pages.TGuiTabControl.Create;
  Page:=PasSDL3.GUI.Controls.Pages.TGuiPage.Create;
  Pages:=PasSDL3.GUI.Controls.Pages.TGuiPageControl.Create;
  try
    CoreControl:=TabButton;
    CoreControl:=Indicator;
    CoreControl:=Tabs;
    CoreControl:=Page;
    CoreControl:=Pages;
    CorePosition:=PasSDL3.GUI.Controls.Pages.gtpBottom;
    Position:=CorePosition;
    if (CoreControl <> Pages) OR
      (Position <> PasSDL3.GUI.Controls.Pages.gtpBottom) then
      Halt(1);
  finally
    Pages.Free;
    Page.Free;
    Tabs.Free;
    Indicator.Free;
    TabButton.Free;
  end;
  WriteLn('PASS: aggregate page compatibility aliases preserve exact type identity');
end.
