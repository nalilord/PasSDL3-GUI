program BarsCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Bars;

var
  CoreControl: PasSDL3.GUI.Controls.TGuiControl;
  Separator: PasSDL3.GUI.Controls.Bars.TGuiSeparator;
  Status: PasSDL3.GUI.Controls.Bars.TGuiStatusBar;
  ToolBar: PasSDL3.GUI.Controls.Bars.TGuiToolBar;
  Command: PasSDL3.GUI.Controls.Bars.TGuiCommandBar;

begin
  Separator:=PasSDL3.GUI.Controls.Bars.TGuiSeparator.Create;
  Status:=PasSDL3.GUI.Controls.Bars.TGuiStatusBar.Create;
  ToolBar:=PasSDL3.GUI.Controls.Bars.TGuiToolBar.Create;
  Command:=PasSDL3.GUI.Controls.Bars.TGuiCommandBar.Create;
  try
    CoreControl:=Separator;
    CoreControl:=Status;
    CoreControl:=ToolBar;
    CoreControl:=Command;
    if CoreControl <> Command then
      Halt(1);
  finally
    Command.Free;
    ToolBar.Free;
    Status.Free;
    Separator.Free;
  end;
  WriteLn('PASS: aggregate bar compatibility aliases preserve exact type identity');
end.
