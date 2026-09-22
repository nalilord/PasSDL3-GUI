program RangeImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Range;

var
  SnapMode: TGuiSnapMode;
  Thumb: TGuiRangeThumb;
  InputMode: TGuiKnobInputMode;
  Direction: TGuiWrapDirection;
  RangeEvent: TGuiRangeMovedEvent;
  WrapEvent: TGuiKnobWrapEvent;

begin
  SnapMode:=gsmSnapOnRelease;
  Thumb:=grtUpper;
  InputMode:=gkiVertical;
  Direction:=gwdCounterClockwise;
  RangeEvent:=nil;
  WrapEvent:=nil;
  if (Ord(SnapMode) <> 2) OR (Ord(Thumb) <> 1) OR
      (Ord(InputMode) <> 2) OR (Ord(Direction) <> 1) then
    Halt(1);
  CheckControlClass(TGuiSlider);
  CheckControlClass(TGuiRangeSlider);
  CheckControlClass(TGuiKnob);
  CheckControlClass(TGuiScrollBar);
  Pass('Range');
end.
