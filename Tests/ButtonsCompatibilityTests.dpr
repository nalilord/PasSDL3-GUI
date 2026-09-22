program ButtonsCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Buttons;

var
  CoreButton: PasSDL3.GUI.Controls.TGuiButton;
  CoreDelay: PasSDL3.GUI.Controls.TGuiDelayButton;
  CoreRound: PasSDL3.GUI.Controls.TGuiRoundButton;
  CoreSpeed: PasSDL3.GUI.Controls.TGuiSpeedButton;
  CoreToggle: PasSDL3.GUI.Controls.TGuiToggleButton;
  CoreSwitch: PasSDL3.GUI.Controls.TGuiToggleSwitch;
  CoreCheck: PasSDL3.GUI.Controls.TGuiCheckBox;
  CoreRadio: PasSDL3.GUI.Controls.TGuiRadioButton;
  Button: PasSDL3.GUI.Controls.Buttons.TGuiButton;
  Delay: PasSDL3.GUI.Controls.Buttons.TGuiDelayButton;
  RoundButton: PasSDL3.GUI.Controls.Buttons.TGuiRoundButton;
  Speed: PasSDL3.GUI.Controls.Buttons.TGuiSpeedButton;
  Toggle: PasSDL3.GUI.Controls.Buttons.TGuiToggleButton;
  ToggleSwitch: PasSDL3.GUI.Controls.Buttons.TGuiToggleSwitch;
  CheckBox: PasSDL3.GUI.Controls.Buttons.TGuiCheckBox;
  Radio: PasSDL3.GUI.Controls.Buttons.TGuiRadioButton;
  CorePlacement: PasSDL3.GUI.Controls.TGuiIconPlacement;
  Placement: PasSDL3.GUI.Controls.Buttons.TGuiIconPlacement;
  CoreState: PasSDL3.GUI.Controls.TGuiCheckBoxState;
  State: PasSDL3.GUI.Controls.Buttons.TGuiCheckBoxState;

begin
  Button:=PasSDL3.GUI.Controls.Buttons.TGuiButton.Create;
  Delay:=PasSDL3.GUI.Controls.Buttons.TGuiDelayButton.Create;
  RoundButton:=PasSDL3.GUI.Controls.Buttons.TGuiRoundButton.Create;
  Speed:=PasSDL3.GUI.Controls.Buttons.TGuiSpeedButton.Create;
  Toggle:=PasSDL3.GUI.Controls.Buttons.TGuiToggleButton.Create;
  ToggleSwitch:=PasSDL3.GUI.Controls.Buttons.TGuiToggleSwitch.Create;
  CheckBox:=PasSDL3.GUI.Controls.Buttons.TGuiCheckBox.Create;
  Radio:=PasSDL3.GUI.Controls.Buttons.TGuiRadioButton.Create;
  try
    CoreButton:=Button;
    CoreDelay:=Delay;
    CoreRound:=RoundButton;
    CoreSpeed:=Speed;
    CoreToggle:=Toggle;
    CoreSwitch:=ToggleSwitch;
    CoreCheck:=CheckBox;
    CoreRadio:=Radio;
    CorePlacement:=PasSDL3.GUI.Controls.Buttons.gipBottom;
    Placement:=CorePlacement;
    CoreState:=PasSDL3.GUI.Controls.Buttons.gcbGrayed;
    State:=CoreState;
    if (CoreButton <> Button) OR (CoreDelay <> Delay) OR
      (CoreRound <> RoundButton) OR (CoreSpeed <> Speed) OR
      (CoreToggle <> Toggle) OR (CoreSwitch <> ToggleSwitch) OR
      (CoreCheck <> CheckBox) OR (CoreRadio <> Radio) OR
      (Placement <> PasSDL3.GUI.Controls.Buttons.gipBottom) OR
      (State <> PasSDL3.GUI.Controls.Buttons.gcbGrayed) then
      Halt(1);
  finally
    Radio.Free;
    CheckBox.Free;
    ToggleSwitch.Free;
    Toggle.Free;
    Speed.Free;
    RoundButton.Free;
    Delay.Free;
    Button.Free;
  end;
  WriteLn('PASS: aggregate button compatibility aliases preserve exact type identity');
end.
