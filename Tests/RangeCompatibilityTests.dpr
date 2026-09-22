program RangeCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Range;

var
  CoreSlider: PasSDL3.GUI.Controls.TGuiSlider;
  CoreRange: PasSDL3.GUI.Controls.TGuiRangeSlider;
  CoreKnob: PasSDL3.GUI.Controls.TGuiKnob;
  CoreScroll: PasSDL3.GUI.Controls.TGuiScrollBar;
  Slider: PasSDL3.GUI.Controls.Range.TGuiSlider;
  RangeSlider: PasSDL3.GUI.Controls.Range.TGuiRangeSlider;
  Knob: PasSDL3.GUI.Controls.Range.TGuiKnob;
  Scroll: PasSDL3.GUI.Controls.Range.TGuiScrollBar;
  CoreSnap: PasSDL3.GUI.Controls.TGuiSnapMode;
  Snap: PasSDL3.GUI.Controls.Range.TGuiSnapMode;
  CoreThumb: PasSDL3.GUI.Controls.TGuiRangeThumb;
  Thumb: PasSDL3.GUI.Controls.Range.TGuiRangeThumb;
  CoreInput: PasSDL3.GUI.Controls.TGuiKnobInputMode;
  InputMode: PasSDL3.GUI.Controls.Range.TGuiKnobInputMode;
  CoreDirection: PasSDL3.GUI.Controls.TGuiWrapDirection;
  Direction: PasSDL3.GUI.Controls.Range.TGuiWrapDirection;

begin
  Slider:=PasSDL3.GUI.Controls.Range.TGuiSlider.Create;
  RangeSlider:=PasSDL3.GUI.Controls.Range.TGuiRangeSlider.Create;
  Knob:=PasSDL3.GUI.Controls.Range.TGuiKnob.Create;
  Scroll:=PasSDL3.GUI.Controls.Range.TGuiScrollBar.Create;
  try
    CoreSlider:=Slider;
    CoreRange:=RangeSlider;
    CoreKnob:=Knob;
    CoreScroll:=Scroll;
    CoreSnap:=PasSDL3.GUI.Controls.Range.gsmSnapOnRelease;
    Snap:=CoreSnap;
    CoreThumb:=PasSDL3.GUI.Controls.Range.grtUpper;
    Thumb:=CoreThumb;
    CoreInput:=PasSDL3.GUI.Controls.Range.gkiVertical;
    InputMode:=CoreInput;
    CoreDirection:=PasSDL3.GUI.Controls.Range.gwdCounterClockwise;
    Direction:=CoreDirection;
    if (CoreSlider <> Slider) OR (CoreRange <> RangeSlider) OR
      (CoreKnob <> Knob) OR (CoreScroll <> Scroll) OR
      (Snap <> PasSDL3.GUI.Controls.Range.gsmSnapOnRelease) OR
      (Thumb <> PasSDL3.GUI.Controls.Range.grtUpper) OR
      (InputMode <> PasSDL3.GUI.Controls.Range.gkiVertical) OR
      (Direction <> PasSDL3.GUI.Controls.Range.gwdCounterClockwise) then
      Halt(1);
  finally
    Scroll.Free;
    Knob.Free;
    RangeSlider.Free;
    Slider.Free;
  end;
  WriteLn('PASS: aggregate range compatibility aliases preserve exact type identity');
end.
