program ProgressCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Progress;

var
  CoreProgress: PasSDL3.GUI.Controls.TGuiProgressBar;
  OwnedProgress: PasSDL3.GUI.Controls.Progress.TGuiProgressBar;
  CoreActivity: PasSDL3.GUI.Controls.TGuiActivityIndicator;
  OwnedActivity: PasSDL3.GUI.Controls.Progress.TGuiActivityIndicator;

begin
  OwnedProgress:=PasSDL3.GUI.Controls.Progress.TGuiProgressBar.Create;
  OwnedActivity:=PasSDL3.GUI.Controls.Progress.TGuiActivityIndicator.Create;
  try
    CoreProgress:=OwnedProgress;
    CoreActivity:=OwnedActivity;
    if (CoreProgress <> OwnedProgress) OR (CoreActivity <> OwnedActivity) then
      Halt(1);
  finally
    OwnedActivity.Free;
    OwnedProgress.Free;
  end;
  WriteLn('PASS: aggregate progress compatibility aliases preserve exact type identity');
end.
