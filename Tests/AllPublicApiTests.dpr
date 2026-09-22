program AllPublicApiTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI;

type
  TGuiControlClass = class of TGuiControl;

  TProbeControl = class(TGuiControl)
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas);
    override;
  end;

const
  CONTROL_CLASSES: array[0..59] of TGuiControlClass = (
    TGuiControl,
    TGuiContainer,
    TGuiPanel,
    TGuiFrame,
    TGuiStackPanel,
    TGuiGridPanel,
    TGuiScrollBox,
    TGuiLabel,
    TGuiLinkLabel,
    TGuiImage,
    TGuiIcon,
    TGuiValueLabel,
    TGuiEdit,
    TGuiListBox,
    TGuiWheelPicker,
    TGuiRadioGroup,
    TGuiMemo,
    TGuiTreeView,
    TGuiHeaderControl,
    TGuiListView,
    TGuiItemTemplate,
    TGuiButton,
    TGuiDelayButton,
    TGuiRoundButton,
    TGuiSpeedButton,
    TGuiTabButton,
    TGuiCheckBox,
    TGuiCheckListBox,
    TGuiSwitchListBox,
    TGuiRadioButton,
    TGuiToggleSwitch,
    TGuiGroupBox,
    TGuiSeparator,
    TGuiStatusBar,
    TGuiTransparentPanel,
    TGuiTransparentStackPanel,
    TGuiDialog,
    TGuiModalOverlay,
    TGuiToolBar,
    TGuiCommandBar,
    TGuiSplitter,
    TGuiSlider,
    TGuiRangeSlider,
    TGuiKnob,
    TGuiScrollBar,
    TGuiActivityIndicator,
    TGuiProgressBar,
    TGuiDialGauge,
    TGuiScope,
    TGuiSpinEdit,
    TGuiComboBox,
    TGuiDropDownButton,
    TGuiPageIndicator,
    TGuiTabControl,
    TGuiPage,
    TGuiPageControl,
    TGuiMenuBar,
    TGuiPopupMenu,
    TGuiToggleButton,
    TGuiLayerControl
  );

procedure Report(const AMessage: String);
begin
  {$I-}
  WriteLn(AMessage);
  IOResult;
  {$I+}
end;

procedure TProbeControl.PaintSelf(ACanvas: TGuiCanvas);
begin
end;

procedure Check(ACondition: Boolean; const AMessage: String);
begin
  if NOT ACondition then
  begin
    Report('FAIL: ' + AMessage);
    Halt(1);
  end;
end;

var
  Context: TGuiContext;
  Control: TGuiControl;
  TreeNode: TGuiTreeNode;
  ScopeMarker: TGuiScopeMarker;
  MenuItem: TGuiMenuItem;
  Probe: TProbeControl;
  LayoutState: TGuiLayoutState;
  EditState: TGuiEditState;
  Indices: TGuiIndexArray;
  NotifyEvent: TGuiNotifyEvent;
  MouseEvent: TGuiMouseEvent;
  FocusEvent: TGuiFocusChangedEvent;
  ColumnEvent: TGuiColumnEvent;
  CompareEvent: TGuiCompareRowsEvent;
  NextStateEvent: TGuiNextCheckStateEvent;
  ItemCheckEvent: TGuiItemCheckEvent;
  RangeEvent: TGuiRangeMovedEvent;
  WrapEvent: TGuiKnobWrapEvent;
  I: Integer;

begin
  FillChar(LayoutState, SizeOf(LayoutState), 0);
  FillChar(EditState, SizeOf(EditState), 0);
  SetLength(Indices, 0);
  NotifyEvent:=nil;
  MouseEvent:=nil;
  FocusEvent:=nil;
  ColumnEvent:=nil;
  CompareEvent:=nil;
  NextStateEvent:=nil;
  ItemCheckEvent:=nil;
  RangeEvent:=nil;
  WrapEvent:=nil;

  Context:=TGuiContext.Create;
  try
    for I:=Low(CONTROL_CLASSES) to High(CONTROL_CLASSES) do
    begin
      Control:=CONTROL_CLASSES[I].Create;
      Check(Control.ClassType = CONTROL_CLASSES[I], 'control class identity');
      Context.Root.Add(Control);
    end;
    Check(Context.Root.ChildCount = Length(CONTROL_CLASSES), 'all public controls construct');
    Check(Ord(gifCover) = 2, 'image enum export');
    Check(Ord(gwwDisabled) = 2, 'wheel enum export');
    Check(Ord(gsdDescending) = 1, 'sort enum export');
    Check(Ord(gcskNumber) = 1, 'column enum export');
    Check(Ord(gipBottom) = 3, 'icon enum export');
    Check(Ord(gcbGrayed) = 2, 'checkbox enum export');
    Check(Ord(gmrCustom) = 6, 'modal result export');
    Check(Ord(gdwmResizable) = 3, 'dialog mode export');
    Check(Ord(gdbClose) = 2, 'dialog button export');
    Check(Ord(gdsMaximized) = 2, 'dialog state export');
    Check(Ord(gsmSnapOnRelease) = 2, 'snap enum export');
    Check(Ord(grtUpper) = 1, 'range thumb export');
    Check(Ord(gkiVertical) = 2, 'knob mode export');
    Check(Ord(gwdCounterClockwise) = 1, 'wrap direction export');
    Check(Ord(gtpBottom) = 1, 'tab position export');
    Check(Ord(glkDebug) = 4, 'layer enum export');
    Check(GuiScrollThumbLength(10, 20, 100, 4) = 50, 'scroll helper export');
  finally
    Context.Free;
  end;

  TreeNode:=TGuiTreeNode.Create('Node', 1);
  TreeNode.Free;
  ScopeMarker:=TGuiScopeMarker.Create(0, 0, GuiColor(1, 2, 3), 4, 'Marker');
  ScopeMarker.Free;
  MenuItem:=TGuiMenuItem.Create('Menu');
  MenuItem.Free;
  Probe:=TProbeControl.Create;
  Probe.Free;

  Check(NOT Assigned(NotifyEvent), 'notify event alias');
  Check(NOT Assigned(MouseEvent), 'mouse event alias');
  Check(NOT Assigned(FocusEvent), 'focus event alias');
  Check(NOT Assigned(ColumnEvent), 'column event alias');
  Check(NOT Assigned(CompareEvent), 'compare event alias');
  Check(NOT Assigned(NextStateEvent), 'state event alias');
  Check(NOT Assigned(ItemCheckEvent), 'item event alias');
  Check(NOT Assigned(RangeEvent), 'range event alias');
  Check(NOT Assigned(WrapEvent), 'wrap event alias');
  Check(Length(Indices) = 0, 'index array alias');
  Report('PASS: umbrella exposes and constructs the complete public Core API');
end.
