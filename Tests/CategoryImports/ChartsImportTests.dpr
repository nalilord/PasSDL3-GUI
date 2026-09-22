program ChartsImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Charts;

var
  Marker: TGuiScopeMarker;

begin
  CheckControlClass(TGuiDialGauge);
  CheckControlClass(TGuiScope);
  Marker:=nil;
  if Assigned(Marker) then
    Halt(1);
  Pass('Charts');
end.
