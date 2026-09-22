program ChartsCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Charts;

var
  CoreDial: PasSDL3.GUI.Controls.TGuiDialGauge;
  OwnedDial: PasSDL3.GUI.Controls.Charts.TGuiDialGauge;
  CoreScope: PasSDL3.GUI.Controls.TGuiScope;
  OwnedScope: PasSDL3.GUI.Controls.Charts.TGuiScope;
  CoreMarker: PasSDL3.GUI.Controls.TGuiScopeMarker;
  OwnedMarker: PasSDL3.GUI.Controls.Charts.TGuiScopeMarker;

begin
  OwnedDial:=PasSDL3.GUI.Controls.Charts.TGuiDialGauge.Create;
  OwnedScope:=PasSDL3.GUI.Controls.Charts.TGuiScope.Create;
  OwnedMarker:=PasSDL3.GUI.Controls.Charts.TGuiScopeMarker.Create(
    0, 0, Default(TGuiColor), 5, ''
  );
  try
    CoreDial:=OwnedDial;
    CoreScope:=OwnedScope;
    CoreMarker:=OwnedMarker;
    if (CoreDial <> OwnedDial) OR (CoreScope <> OwnedScope) OR
      (CoreMarker <> OwnedMarker) then
      Halt(1);
  finally
    OwnedMarker.Free;
    OwnedScope.Free;
    OwnedDial.Free;
  end;
  WriteLn('PASS: aggregate chart compatibility aliases preserve exact type identity');
end.
