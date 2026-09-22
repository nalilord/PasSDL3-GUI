program ButtonsImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Buttons;

var
  Placement: TGuiIconPlacement;
  State: TGuiCheckBoxState;
  NextStateEvent: TGuiNextCheckStateEvent;

begin
  Placement:=gipBottom;
  State:=gcbGrayed;
  NextStateEvent:=nil;
  if (Ord(Placement) <> 3) OR (Ord(State) <> 2) OR Assigned(NextStateEvent) then
    Halt(1);
  CheckControlClass(TGuiButton);
  CheckControlClass(TGuiDelayButton);
  CheckControlClass(TGuiRoundButton);
  CheckControlClass(TGuiSpeedButton);
  CheckControlClass(TGuiToggleButton);
  CheckControlClass(TGuiToggleSwitch);
  CheckControlClass(TGuiCheckBox);
  CheckControlClass(TGuiRadioButton);
  Pass('Buttons');
end.
