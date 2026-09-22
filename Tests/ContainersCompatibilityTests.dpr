program ContainersCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Containers;

var
  CorePanel: PasSDL3.GUI.Controls.TGuiPanel;
  CoreFrame: PasSDL3.GUI.Controls.TGuiFrame;
  CoreStack: PasSDL3.GUI.Controls.TGuiStackPanel;
  CoreGrid: PasSDL3.GUI.Controls.TGuiGridPanel;
  CoreScroll: PasSDL3.GUI.Controls.TGuiScrollBox;
  CoreGroup: PasSDL3.GUI.Controls.TGuiGroupBox;
  CoreTransparent: PasSDL3.GUI.Controls.TGuiTransparentPanel;
  CoreTransparentStack: PasSDL3.GUI.Controls.TGuiTransparentStackPanel;
  CoreSplitter: PasSDL3.GUI.Controls.TGuiSplitter;
  Panel: PasSDL3.GUI.Controls.Containers.TGuiPanel;
  Frame: PasSDL3.GUI.Controls.Containers.TGuiFrame;
  Stack: PasSDL3.GUI.Controls.Containers.TGuiStackPanel;
  Grid: PasSDL3.GUI.Controls.Containers.TGuiGridPanel;
  Scroll: PasSDL3.GUI.Controls.Containers.TGuiScrollBox;
  Group: PasSDL3.GUI.Controls.Containers.TGuiGroupBox;
  Transparent: PasSDL3.GUI.Controls.Containers.TGuiTransparentPanel;
  TransparentStack: PasSDL3.GUI.Controls.Containers.TGuiTransparentStackPanel;
  Splitter: PasSDL3.GUI.Controls.Containers.TGuiSplitter;

begin
  Panel:=PasSDL3.GUI.Controls.Containers.TGuiPanel.Create;
  Frame:=PasSDL3.GUI.Controls.Containers.TGuiFrame.Create;
  Stack:=PasSDL3.GUI.Controls.Containers.TGuiStackPanel.Create;
  Grid:=PasSDL3.GUI.Controls.Containers.TGuiGridPanel.Create;
  Scroll:=PasSDL3.GUI.Controls.Containers.TGuiScrollBox.Create;
  Group:=PasSDL3.GUI.Controls.Containers.TGuiGroupBox.Create;
  Transparent:=PasSDL3.GUI.Controls.Containers.TGuiTransparentPanel.Create;
  TransparentStack:=PasSDL3.GUI.Controls.Containers.TGuiTransparentStackPanel.Create;
  Splitter:=PasSDL3.GUI.Controls.Containers.TGuiSplitter.Create;
  try
    CorePanel:=Panel;
    CoreFrame:=Frame;
    CoreStack:=Stack;
    CoreGrid:=Grid;
    CoreScroll:=Scroll;
    CoreGroup:=Group;
    CoreTransparent:=Transparent;
    CoreTransparentStack:=TransparentStack;
    CoreSplitter:=Splitter;
    if (CorePanel <> Panel) OR (CoreFrame <> Frame) OR
      (CoreStack <> Stack) OR (CoreGrid <> Grid) OR
      (CoreScroll <> Scroll) OR (CoreGroup <> Group) OR
      (CoreTransparent <> Transparent) OR
      (CoreTransparentStack <> TransparentStack) OR
      (CoreSplitter <> Splitter) then
      Halt(1);
  finally
    Splitter.Free;
    TransparentStack.Free;
    Transparent.Free;
    Group.Free;
    Scroll.Free;
    Grid.Free;
    Stack.Free;
    Frame.Free;
    Panel.Free;
  end;
  WriteLn('PASS: aggregate container compatibility aliases preserve exact type identity');
end.
