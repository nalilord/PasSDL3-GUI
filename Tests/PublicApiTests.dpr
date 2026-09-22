program PublicApiTests;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

uses SysUtils, PasSDL3.GUI;

type TControlClass = class of TGuiControl;

const
  ControlClasses: array[0..22] of TControlClass = (
    TGuiActivityIndicator, TGuiButton, TGuiCheckBox, TGuiCheckListBox,
    TGuiComboBox, TGuiDelayButton, TGuiKnob, TGuiPageIndicator,
    TGuiProgressBar, TGuiRadioButton, TGuiRadioGroup, TGuiRangeSlider,
    TGuiRoundButton, TGuiSlider, TGuiSpinEdit, TGuiToggleSwitch,
    TGuiSwitchListBox, TGuiTabControl, TGuiTabButton, TGuiToolBar,
    TGuiSpeedButton, TGuiSeparator, TGuiWheelPicker);

var
  Context: TGuiContext;
  Control: TGuiControl;
  Button: TGuiButton;
  Dialog: TGuiDialog;
  Rect: TGuiRect;
  Style: TGuiStyle;
  I: Integer;

procedure Check(ACondition: Boolean; const AMessage: String);
begin
  if NOT ACondition then raise Exception.Create(AMessage);
end;

begin
  Context:=TGuiContext.Create;
  try
    for I:=Low(ControlClasses) to High(ControlClasses) do
    begin
      Control:=ControlClasses[I].Create;
      Context.Root.Add(Control);
      Check(Control.ClassType=ControlClasses[I], 'Incorrect control alias');
      Check(Control.Parent=Context.Root, 'Umbrella context ownership');
    end;
    Check(Context.Root.ChildCount=23, 'All 23 standard controls are exposed');
    Rect:=GuiRect(10,20,100,40);
    Check(GuiRectContains(Rect,GuiPoint(50,30)), 'Geometry helpers');
    Check(NOT GuiRectContains(Rect,GuiPoint(0,0)), 'Geometry outside');
    Style:=GuiButtonStyle;
    Style.Background:=GuiColorDrawable(GuiColor(20,30,40));
    Button:=TGuiButton(Context.Root.Children[1]);
    Button.Style:=Style;
    Button.Caption:='Public API';
    Check(Button.Caption='Public API', 'Button facade');
    TGuiSeparator(Context.Root.Children[21]).Orientation:=goVertical;
    Check(TGuiSeparator(Context.Root.Children[21]).Orientation=goVertical,
      'Enum values exposed');
    Dialog:=TGuiDialog.Create;
    try
      Dialog.WindowMode:=gdwmFixed;
      Dialog.TitleButtons:=[gdbClose];
      Check(Dialog.WindowMode=gdwmFixed, 'Dialog mode alias');
      Check(Dialog.TitleButtons=[gdbClose], 'Dialog button set alias');
    finally
      Dialog.Free;
    end;
    Writeln('PASS: umbrella-only consumer, all 23 standard controls and basic helpers');
  finally
    Context.Free;
  end;
end.
