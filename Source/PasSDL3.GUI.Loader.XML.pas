unit PasSDL3.GUI.Loader.XML;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils,
  Classes,
  Variants,
  Xml.XMLDoc,
  Xml.XMLIntf,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Core,
  PasSDL3.GUI.Controls.Containers,
  PasSDL3.GUI.Controls.Text,
  PasSDL3.GUI.Controls.Buttons,
  PasSDL3.GUI.Controls.Lists,
  PasSDL3.GUI.Controls.Pages,
  PasSDL3.GUI.Controls.Menus,
  PasSDL3.GUI.Controls.Bars,
  PasSDL3.GUI.Controls.Dialogs,
  PasSDL3.GUI.Controls.Range,
  PasSDL3.GUI.Controls.Images,
  PasSDL3.GUI.Controls.Progress,
  PasSDL3.GUI.Controls.Charts;

type
  TGuiXmlControlCreatedEvent = procedure(Sender: TObject; AControl: TGuiControl; const ANode: IXMLNode) of object;

  TGuiXmlLoader = class
  private
    FOnControlCreated: TGuiXmlControlCreatedEvent;
    function Attr(const ANode: IXMLNode; const AName, ADefault: String): String;
    function AttrFloat(const ANode: IXMLNode; const AName: String; ADefault: TGuiFloat): TGuiFloat;
    function AttrBool(const ANode: IXMLNode; const AName: String; ADefault: Boolean): Boolean;
    procedure ApplyCommonAttributes(AControl: TGuiControl; const ANode: IXMLNode);
    procedure LoadChildren(AParent: TGuiControl; const ANode: IXMLNode);
  protected
    function CreateControlForNode(const ANode: IXMLNode): TGuiControl; virtual;
  public
    function LoadFromFile(const AFileName: String; AParent: TGuiControl = nil): TGuiControl;
    function LoadFromString(const AXml: String; AParent: TGuiControl = nil): TGuiControl;
    property OnControlCreated: TGuiXmlControlCreatedEvent read FOnControlCreated write FOnControlCreated;
  end;

implementation

uses Math;

function TGuiXmlLoader.Attr(const ANode: IXMLNode; const AName, ADefault: String): String;
begin
  Result:=ADefault;

  if Assigned(ANode) AND ANode.HasAttribute(AName) then
    Result:=VarToStr(ANode.Attributes[AName]);
end;

function TGuiXmlLoader.AttrFloat(const ANode: IXMLNode; const AName: String; ADefault: TGuiFloat): TGuiFloat;
begin
  Result:=StrToFloatDef(Attr(ANode, AName, ''), ADefault);
end;

function TGuiXmlLoader.AttrBool(const ANode: IXMLNode; const AName: String; ADefault: Boolean): Boolean;
var
  Value: String;
begin
  Value:=LowerCase(Attr(ANode, AName, ''));

  if (Value = 'true') OR (Value = '1') OR (Value = 'yes') then
    Result:=True
  else
  if (Value = 'false') OR (Value = '0') OR (Value = 'no') then
    Result:=False
  else
    Result:=ADefault;
end;

procedure TGuiXmlLoader.ApplyCommonAttributes(AControl: TGuiControl; const ANode: IXMLNode);
var
  AlignValue: String;
  CaptionValue: String;
  RowValues: TStringList;
  DelayValue: Int64;
  I: Integer;
begin
  if NOT Assigned(AControl) then
    Exit;

  AControl.Name:=Attr(ANode, 'name', AControl.Name);
  AControl.StyleClass:=Attr(ANode, 'class', AControl.StyleClass);
  AControl.FontName:=Attr(ANode, 'font', AControl.FontName);
  AControl.Hint:=Attr(ANode, 'hint', AControl.Hint);
  AControl.Visible:=AttrBool(ANode, 'visible', AControl.Visible);
  AControl.Enabled:=AttrBool(ANode, 'enabled', AControl.Enabled);
  AControl.CanFocus:=AttrBool(ANode, 'canFocus', AControl.CanFocus);
  AControl.TabStop:=AttrBool(ANode, 'tabStop', AControl.TabStop);
  AControl.AutoSize:=AttrBool(ANode, 'autoSize', AControl.AutoSize);
  AControl.Tag:=StrToInt64Def(Attr(ANode, 'tag', IntToStr(AControl.Tag)), AControl.Tag);

  CaptionValue:=Attr(ANode, 'caption', Attr(ANode, 'text', AControl.Caption));
  AControl.Caption:=CaptionValue;
  if AControl IS TGuiStackPanel then
  begin
    if ANode.HasAttribute('orientation') then
    begin
      AlignValue:=LowerCase(Trim(Attr(ANode,'orientation','')));
      if AlignValue='horizontal' then TGuiStackPanel(AControl).Orientation:=goHorizontal
      else if AlignValue='vertical' then TGuiStackPanel(AControl).Orientation:=goVertical
      else raise EArgumentException.Create('Invalid stack orientation');
    end;
    if ANode.HasAttribute('spacing') then TGuiStackPanel(AControl).Spacing:=StrToFloat(Attr(ANode,'spacing','0'));
    TGuiStackPanel(AControl).AutoSizeToContent:=AttrBool(ANode,'autoSizeToContent',TGuiStackPanel(AControl).AutoSizeToContent);
  end;
  if AControl IS TGuiSeparator then
  begin
    AlignValue:=LowerCase(Trim(Attr(ANode,'orientation','horizontal')));
    if AlignValue='horizontal' then TGuiSeparator(AControl).Orientation:=goHorizontal
    else if AlignValue='vertical' then TGuiSeparator(AControl).Orientation:=goVertical
    else raise EArgumentException.Create('Invalid separator orientation');
    TGuiSeparator(AControl).Thickness:=StrToFloat(Attr(ANode,'thickness','1'));
  end;
  if AControl IS TGuiKnob then
  begin
    TGuiKnob(AControl).Wrap:=AttrBool(ANode,'wrap',False);
    TGuiKnob(AControl).SetAngles(StrToFloat(Attr(ANode,'startAngle','135')),StrToFloat(Attr(ANode,'endAngle','405')));
    TGuiKnob(AControl).DragDistance:=StrToFloat(Attr(ANode,'dragDistance','150'));
    AlignValue:=LowerCase(Attr(ANode,'inputMode','circular'));
    if AlignValue='horizontal' then TGuiKnob(AControl).InputMode:=gkiHorizontal
    else if AlignValue='vertical' then TGuiKnob(AControl).InputMode:=gkiVertical
    else if AlignValue='circular' then TGuiKnob(AControl).InputMode:=gkiCircular
    else raise EArgumentException.Create('Invalid knob input mode');
    { Range/value/step/live/snap are configured by the shared slider block below. }
  end;
  if AControl IS TGuiRoundButton then
    TGuiRoundButton(AControl).Radius:=AttrFloat(ANode,'radius',-1);
  if AControl IS TGuiRangeSlider then
  begin
    TGuiRangeSlider(AControl).MinValue:=StrToFloat(Attr(ANode,'minValue','0'));
    TGuiRangeSlider(AControl).MaxValue:=StrToFloat(Attr(ANode,'maxValue','100'));
    TGuiRangeSlider(AControl).SetValues(StrToFloat(Attr(ANode,'lowerValue','25')),StrToFloat(Attr(ANode,'upperValue','75')));
    TGuiRangeSlider(AControl).StepSize:=StrToFloat(Attr(ANode,'stepSize','0'));
    TGuiRangeSlider(AControl).Live:=AttrBool(ANode,'live',True);
    AlignValue:=LowerCase(Attr(ANode,'orientation','horizontal'));
    if AlignValue='vertical' then TGuiRangeSlider(AControl).Orientation:=goVertical
    else if AlignValue<>'horizontal' then raise EArgumentException.Create('Invalid range-slider orientation');
    AlignValue:=LowerCase(Attr(ANode,'snapMode','none'));
    if AlignValue='always' then TGuiRangeSlider(AControl).SnapMode:=gsmSnapAlways
    else if AlignValue='release' then TGuiRangeSlider(AControl).SnapMode:=gsmSnapOnRelease
    else if AlignValue<>'none' then raise EArgumentException.Create('Invalid range-slider snap mode');
    AlignValue:=LowerCase(Attr(ANode,'activeThumb','lower'));
    if AlignValue='upper' then TGuiRangeSlider(AControl).ActiveThumb:=grtUpper
    else if AlignValue<>'lower' then raise EArgumentException.Create('Invalid range-slider active thumb');
  end;
  if AControl IS TGuiDelayButton then
  begin
    DelayValue:=StrToInt64(Attr(ANode,'delay','3000'));
    if (DelayValue<0) OR (DelayValue>High(Cardinal)) then
      raise EArgumentException.Create('Delay must be between 0 and 4294967295 milliseconds');
    TGuiDelayButton(AControl).Delay:=Cardinal(DelayValue);
    TGuiDelayButton(AControl).Checked:=AttrBool(ANode,'checked',False);
  end;
  if AControl IS TGuiSlider then
  begin
    TGuiSlider(AControl).MinValue:=StrToFloat(Attr(ANode,'minValue','0'));
    TGuiSlider(AControl).MaxValue:=StrToFloat(Attr(ANode,'maxValue','100'));
    TGuiSlider(AControl).Value:=StrToFloat(Attr(ANode,'value','50'));
    TGuiSlider(AControl).StepSize:=StrToFloat(Attr(ANode,'stepSize','0'));
    AlignValue:=LowerCase(Trim(Attr(ANode,'orientation','horizontal')));
    if AlignValue='vertical' then TGuiSlider(AControl).Orientation:=goVertical
    else if AlignValue='horizontal' then TGuiSlider(AControl).Orientation:=goHorizontal
    else raise EArgumentException.Create('Invalid slider orientation');
    TGuiSlider(AControl).Live:=AttrBool(ANode,'live',True);
    AlignValue:=LowerCase(Attr(ANode,'snapMode','none'));
    if AlignValue='always' then TGuiSlider(AControl).SnapMode:=gsmSnapAlways
    else if AlignValue='release' then TGuiSlider(AControl).SnapMode:=gsmSnapOnRelease
    else if AlignValue='none' then TGuiSlider(AControl).SnapMode:=gsmNoSnap
    else raise EArgumentException.Create('Invalid slider snap mode');
  end;
  if AControl IS TGuiCheckListBox then
  begin
    TGuiCheckListBox(AControl).Items.Text:=StringReplace(Attr(ANode,'items',''),'|',#10,[rfReplaceAll]);
    TGuiCheckListBox(AControl).ItemHeight:=Max(1,AttrFloat(ANode,'itemHeight',34));
    TGuiCheckListBox(AControl).AllowGrayed:=AttrBool(ANode,'allowGrayed',False);
    TGuiCheckListBox(AControl).SelectedIndex:=StrToIntDef(Attr(ANode,'selectedIndex','-1'),-1);
    RowValues:=TStringList.Create;
    try
      RowValues.Text:=StringReplace(Attr(ANode,'states',''),'|',#10,[rfReplaceAll]);
      if (RowValues.Count<>0) AND (RowValues.Count<>TGuiCheckListBox(AControl).Items.Count) then
        raise EArgumentException.Create('Checklist states must match item count');
      for I:=0 to RowValues.Count-1 do
      begin
        AlignValue:=LowerCase(Trim(RowValues[I]));
        if AlignValue='checked' then TGuiCheckListBox(AControl).State[I]:=gcbChecked
        else if AlignValue='grayed' then TGuiCheckListBox(AControl).State[I]:=gcbGrayed
        else if AlignValue<>'unchecked' then raise EArgumentException.Create('Invalid checklist state');
      end;
      RowValues.Text:=StringReplace(Attr(ANode,'itemEnabled',''),'|',#10,[rfReplaceAll]);
      if (RowValues.Count<>0) AND (RowValues.Count<>TGuiCheckListBox(AControl).Items.Count) then
        raise EArgumentException.Create('Checklist itemEnabled must match item count');
      for I:=0 to RowValues.Count-1 do
      begin
        AlignValue:=LowerCase(Trim(RowValues[I]));
        if AlignValue='false' then TGuiCheckListBox(AControl).ItemEnabled[I]:=False
        else if AlignValue<>'true' then raise EArgumentException.Create('Invalid checklist itemEnabled value');
      end;
    finally
      RowValues.Free;
    end;
  end;
  if AControl IS TGuiRadioGroup then
  begin
    TGuiRadioGroup(AControl).Items.Text:=StringReplace(Attr(ANode,'items',''),'|',#10,[rfReplaceAll]);
    TGuiRadioGroup(AControl).ItemHeight:=StrToFloat(Attr(ANode,'itemHeight','34'));
    TGuiRadioGroup(AControl).ItemIndex:=StrToInt(Attr(ANode,'itemIndex','0'));
  end;
  if AControl IS TGuiWheelPicker then
  begin
    TGuiWheelPicker(AControl).Items.Text:=StringReplace(Attr(ANode,'items',''),'|',#10,[rfReplaceAll]);
    TGuiWheelPicker(AControl).VisibleItemCount:=StrToInt(Attr(ANode,'visibleItemCount','5'));
    TGuiWheelPicker(AControl).ItemIndex:=StrToInt(Attr(ANode,'itemIndex','0'));
    AlignValue:=LowerCase(Attr(ANode,'wrap','auto'));
    if AlignValue='true' then TGuiWheelPicker(AControl).Wrap:=True
    else if AlignValue='false' then TGuiWheelPicker(AControl).Wrap:=False
    else if AlignValue<>'auto' then raise EArgumentException.Create('Invalid wheel wrapping policy');
    TGuiWheelPicker(AControl).FlickEnabled:=AttrBool(ANode,'flickEnabled',True);
    TGuiWheelPicker(AControl).Deceleration:=StrToFloat(Attr(ANode,'deceleration','20'));
    DelayValue:=StrToInt64(Attr(ANode,'settleDuration','150'));
    if (DelayValue<0) OR (DelayValue>High(Cardinal)) then raise EArgumentException.Create('Invalid wheel settle duration');
    TGuiWheelPicker(AControl).SettleDuration:=Cardinal(DelayValue);
  end;
  if AControl IS TGuiRadioButton then
  begin
    TGuiRadioButton(AControl).GroupName:=Attr(ANode,'groupName','');
    TGuiRadioButton(AControl).Checked:=AttrBool(ANode,'checked',False);
  end;
  if AControl IS TGuiSpeedButton then
  begin
    TGuiSpeedButton(AControl).Checkable:=AttrBool(ANode,'checkable',TGuiSpeedButton(AControl).Checkable);
    TGuiSpeedButton(AControl).AllowAllUp:=AttrBool(ANode,'allowAllUp',False);
    TGuiSpeedButton(AControl).GroupIndex:=StrToIntDef(
      Attr(ANode,'groupIndex',IntToStr(TGuiSpeedButton(AControl).GroupIndex)),
      TGuiSpeedButton(AControl).GroupIndex);
    TGuiSpeedButton(AControl).Down:=AttrBool(ANode,'down',False);
  end;
  if AControl IS TGuiProgressBar then
  begin
    TGuiProgressBar(AControl).MinValue:=StrToFloat(Attr(ANode,'minValue','0'));
    TGuiProgressBar(AControl).MaxValue:=StrToFloat(Attr(ANode,'maxValue','100'));
    TGuiProgressBar(AControl).Value:=StrToFloat(Attr(ANode,'value','0'));
    TGuiProgressBar(AControl).ShowText:=AttrBool(ANode,'showText',False);
    AlignValue:=LowerCase(Attr(ANode,'orientation','horizontal'));
    if AlignValue='horizontal' then TGuiProgressBar(AControl).Orientation:=goHorizontal
    else if AlignValue='vertical' then TGuiProgressBar(AControl).Orientation:=goVertical
    else raise EArgumentException.Create('Invalid progress orientation');
    TGuiProgressBar(AControl).Reverse:=AttrBool(ANode,'reverse',False);
    TGuiProgressBar(AControl).SegmentCount:=StrToInt(Attr(ANode,'segmentCount','0'));
    TGuiProgressBar(AControl).SegmentGap:=StrToFloat(Attr(ANode,'segmentGap','3'));
    TGuiProgressBar(AControl).ShowTicks:=AttrBool(ANode,'showTicks',False);
    TGuiProgressBar(AControl).TickCount:=StrToInt(Attr(ANode,'tickCount','0'));
    TGuiProgressBar(AControl).ShowThreshold:=AttrBool(ANode,'showThreshold',False);
    TGuiProgressBar(AControl).ThresholdValue:=StrToFloat(Attr(ANode,'thresholdValue','0'));
    TGuiProgressBar(AControl).Marquee:=AttrBool(ANode,'marquee',False);
    DelayValue:=StrToInt64(Attr(ANode,'marqueeInterval','1500'));
    if (DelayValue<0) OR (DelayValue>High(Cardinal)) then raise EArgumentException.Create('Invalid marquee interval');
    TGuiProgressBar(AControl).MarqueeInterval:=Cardinal(DelayValue);
  end;
  if AControl IS TGuiPageIndicator then
  begin
    TGuiPageIndicator(AControl).Count:=StrToInt(Attr(ANode,'count','0'));
    TGuiPageIndicator(AControl).SelectedIndex:=StrToInt(Attr(ANode,'selectedIndex','0'));
    TGuiPageIndicator(AControl).Interactive:=AttrBool(ANode,'interactive',False);
    TGuiPageIndicator(AControl).DotSize:=StrToFloat(Attr(ANode,'dotSize','10'));
    TGuiPageIndicator(AControl).Spacing:=StrToFloat(Attr(ANode,'spacing','8'));
    TGuiPageIndicator(AControl).MaxVisibleDots:=StrToInt(Attr(ANode,'maxVisibleDots','9'));
  end;
  if AControl IS TGuiCheckBox then
  begin
    TGuiCheckBox(AControl).AllowGrayed:=AttrBool(ANode,'allowGrayed',False);
    TGuiCheckBox(AControl).Checked:=AttrBool(ANode,'checked',False);
    AlignValue:=LowerCase(Attr(ANode,'state',''));
    if AlignValue='grayed' then TGuiCheckBox(AControl).State:=gcbGrayed
    else if AlignValue='checked' then TGuiCheckBox(AControl).State:=gcbChecked
    else if AlignValue='unchecked' then TGuiCheckBox(AControl).State:=gcbUnchecked
    else if AlignValue<>'' then raise EArgumentException.Create('Invalid checkbox state: '+AlignValue);
  end;
  if AControl IS TGuiToggleSwitch then
    TGuiToggleSwitch(AControl).Checked:=AttrBool(ANode,'checked',False);
  if AControl IS TGuiActivityIndicator then
  begin
    TGuiActivityIndicator(AControl).Animate:=AttrBool(ANode,'animate',True);
    DelayValue:=StrToInt64(Attr(ANode,'frameInterval','80'));
    if (DelayValue<0) OR (DelayValue>High(Cardinal)) then
      raise EArgumentException.Create('Invalid activity frame interval');
    TGuiActivityIndicator(AControl).FrameInterval:=Cardinal(DelayValue);
  end;
  if AControl IS TGuiEdit then
  begin
    if NOT (AControl IS TGuiSpinEdit) AND NOT (AControl IS TGuiComboBox) then TGuiEdit(AControl).Text:=CaptionValue;
    TGuiEdit(AControl).ReadOnly:=AttrBool(ANode, 'readOnly', TGuiEdit(AControl).ReadOnly);
    TGuiEdit(AControl).Placeholder:=Attr(ANode, 'placeholder', '');
  end;
  if AControl IS TGuiButton then
  begin
    TGuiButton(AControl).AutoRepeat:=AttrBool(ANode,'autoRepeat',False);
    DelayValue:=StrToInt64(Attr(ANode,'repeatDelay','300'));
    if (DelayValue<0) OR (DelayValue>High(Cardinal)) then raise EArgumentException.Create('Invalid button repeat delay');
    TGuiButton(AControl).RepeatDelay:=Cardinal(DelayValue);
    DelayValue:=StrToInt64(Attr(ANode,'repeatInterval','100'));
    if (DelayValue<=0) OR (DelayValue>High(Cardinal)) then raise EArgumentException.Create('Invalid button repeat interval');
    TGuiButton(AControl).RepeatInterval:=Cardinal(DelayValue);
    DelayValue:=StrToInt64(Attr(ANode,'pressAndHoldInterval','800'));
    if (DelayValue<=0) OR (DelayValue>High(Cardinal)) then raise EArgumentException.Create('Invalid button hold interval');
    TGuiButton(AControl).PressAndHoldInterval:=Cardinal(DelayValue);
  end;
  if AControl IS TGuiSpinEdit then
  begin
    TGuiSpinEdit(AControl).MinValue:=StrToInt(Attr(ANode,'minValue','0'));
    TGuiSpinEdit(AControl).MaxValue:=StrToInt(Attr(ANode,'maxValue','100'));
    TGuiSpinEdit(AControl).Increment:=StrToInt(Attr(ANode,'increment','1'));
    TGuiSpinEdit(AControl).Wrap:=AttrBool(ANode,'wrap',False);
    TGuiSpinEdit(AControl).Value:=StrToInt(Attr(ANode,'value','0'));
    TGuiSpinEdit(AControl).Editable:=AttrBool(ANode,'editable',NOT TGuiSpinEdit(AControl).ReadOnly);
    TGuiSpinEdit(AControl).Live:=AttrBool(ANode,'live',False);
    TGuiSpinEdit(AControl).AutoRepeat:=AttrBool(ANode,'autoRepeat',True);
    DelayValue:=StrToInt64(Attr(ANode,'repeatDelay','400'));
    if (DelayValue<0) OR (DelayValue>High(Cardinal)) then raise EArgumentException.Create('Invalid spin repeat delay');
    TGuiSpinEdit(AControl).RepeatDelay:=Cardinal(DelayValue);
    DelayValue:=StrToInt64(Attr(ANode,'repeatInterval','75'));
    if (DelayValue<=0) OR (DelayValue>High(Cardinal)) then raise EArgumentException.Create('Invalid spin repeat interval');
    TGuiSpinEdit(AControl).RepeatInterval:=Cardinal(DelayValue);
  end;
  if AControl IS TGuiComboBox then
  begin
    TGuiComboBox(AControl).Items.Text:=StringReplace(Attr(ANode,'items',''),'|',#10,[rfReplaceAll]);
    TGuiComboBox(AControl).ItemHeight:=StrToFloat(Attr(ANode,'itemHeight','30'));
    TGuiComboBox(AControl).DropDownCount:=StrToInt(Attr(ANode,'dropDownCount','6'));
    TGuiComboBox(AControl).SelectedIndex:=StrToInt(Attr(ANode,'selectedIndex','0'));
    TGuiComboBox(AControl).Editable:=AttrBool(ANode,'editable',NOT TGuiComboBox(AControl).ReadOnly);
    TGuiComboBox(AControl).Text:=Attr(ANode,'text',TGuiComboBox(AControl).Text);
    TGuiComboBox(AControl).AutoComplete:=AttrBool(ANode,'autoComplete',False);
    TGuiComboBox(AControl).SearchCaseSensitive:=AttrBool(ANode,'searchCaseSensitive',False);
    TGuiComboBox(AControl).TypeAhead:=AttrBool(ANode,'typeAhead',True);
    DelayValue:=StrToInt64(Attr(ANode,'typeAheadTimeout','1000'));
    if (DelayValue<=0) OR (DelayValue>High(Cardinal)) then raise EArgumentException.Create('Invalid combo type-ahead timeout');
    TGuiComboBox(AControl).TypeAheadTimeout:=Cardinal(DelayValue);
  end;

  AControl.Bounds:=GuiRect(
    AttrFloat(ANode, 'x', AControl.Bounds.Left),
    AttrFloat(ANode, 'y', AControl.Bounds.Top),
    AttrFloat(ANode, 'width', AControl.Bounds.Width),
    AttrFloat(ANode, 'height', AControl.Bounds.Height));

  if AControl IS TGuiTabControl then
  begin
    TGuiTabControl(AControl).Items.Text:=StringReplace(Attr(ANode,'items',''),'|',#10,[rfReplaceAll]);
    TGuiTabControl(AControl).TabHeight:=StrToFloat(Attr(ANode,'tabHeight','32'));
    AlignValue:=LowerCase(Trim(Attr(ANode,'tabPosition','top')));
    if AlignValue='top' then TGuiTabControl(AControl).TabPosition:=gtpTop
    else if AlignValue='bottom' then TGuiTabControl(AControl).TabPosition:=gtpBottom
    else raise EArgumentException.Create('Invalid tab position');
    TGuiTabControl(AControl).TabWidth:=StrToFloat(Attr(ANode,'tabWidth','0'));
    TGuiTabControl(AControl).MinTabWidth:=StrToFloat(Attr(ANode,'minTabWidth','0'));
    TGuiTabControl(AControl).AutoSizeTabs:=AttrBool(ANode,'autoSizeTabs',False);
    TGuiTabControl(AControl).DragScroll:=AttrBool(ANode,'dragScroll',True);
    TGuiTabControl(AControl).FlickEnabled:=AttrBool(ANode,'flickEnabled',True);
    TGuiTabControl(AControl).Deceleration:=StrToFloat(Attr(ANode,'deceleration','2500'));
    RowValues:=TStringList.Create;
    try
      RowValues.Text:=StringReplace(Attr(ANode,'itemWidths',''),'|',#10,[rfReplaceAll]);
      if (RowValues.Count<>0) AND (RowValues.Count<>TGuiTabControl(AControl).Items.Count) then
        raise EArgumentException.Create('Tab widths must match item count');
      for I:=0 to RowValues.Count-1 do TGuiTabControl(AControl).ItemWidths[I]:=StrToFloat(RowValues[I]);
      RowValues.Text:=StringReplace(Attr(ANode,'tabEnabled',''),'|',#10,[rfReplaceAll]);
      if (RowValues.Count<>0) AND (RowValues.Count<>TGuiTabControl(AControl).Items.Count) then
        raise EArgumentException.Create('Tab enabled flags must match item count');
      for I:=0 to RowValues.Count-1 do
      begin
        AlignValue:=LowerCase(Trim(RowValues[I]));
        if AlignValue='false' then TGuiTabControl(AControl).TabEnabled[I]:=False
        else if AlignValue<>'true' then raise EArgumentException.Create('Invalid tab enabled flag');
      end;
    finally
      RowValues.Free;
    end;
    if ANode.HasAttribute('selectedIndex') then
      TGuiTabControl(AControl).SelectedIndex:=StrToInt(Attr(ANode,'selectedIndex','-1'));
    if ANode.HasAttribute('scrollOffset') then
      TGuiTabControl(AControl).ScrollOffset:=StrToFloat(Attr(ANode,'scrollOffset','0'));
  end;

  AControl.MinWidth:=AttrFloat(ANode, 'minWidth', AControl.MinWidth);
  AControl.MinHeight:=AttrFloat(ANode, 'minHeight', AControl.MinHeight);
  AControl.MaxWidth:=AttrFloat(ANode, 'maxWidth', AControl.MaxWidth);
  AControl.MaxHeight:=AttrFloat(ANode, 'maxHeight', AControl.MaxHeight);

  AlignValue:=LowerCase(Attr(ANode, 'align', ''));
  if AlignValue = 'top' then
    AControl.Align:=gaTop
  else
  if AlignValue = 'bottom' then
    AControl.Align:=gaBottom
  else
  if AlignValue = 'left' then
    AControl.Align:=gaLeft
  else
  if AlignValue = 'right' then
    AControl.Align:=gaRight
  else
  if AlignValue = 'client' then
    AControl.Align:=gaClient
  else
  if AlignValue = 'none' then
    AControl.Align:=gaNone;
end;

function TGuiXmlLoader.CreateControlForNode(const ANode: IXMLNode): TGuiControl;
var
  Kind: String;
begin
  Result:=nil;
  Kind:=LowerCase(ANode.NodeName);

  if (Kind = 'gui') OR (Kind = 'root') then
    Result:=TGuiPanel.Create
  else
  if Kind = 'panel' then
    Result:=TGuiPanel.Create
  else
  if Kind = 'scrollbox' then
    Result:=TGuiScrollBox.Create
  else
  if Kind = 'stackpanel' then
    Result:=TGuiStackPanel.Create
  else
  if Kind = 'gridpanel' then
    Result:=TGuiGridPanel.Create
  else
  if Kind = 'label' then
    Result:=TGuiLabel.Create
  else
  if Kind = 'linklabel' then
    Result:=TGuiLinkLabel.Create
  else
  if Kind = 'icon' then
    Result:=TGuiIcon.Create
  else
  if Kind = 'valuelabel' then
    Result:=TGuiValueLabel.Create
  else
  if Kind = 'edit' then
    Result:=TGuiEdit.Create
  else
  if Kind = 'button' then
    Result:=TGuiButton.Create
  else
  if Kind = 'delaybutton' then
    Result:=TGuiDelayButton.Create
  else
  if Kind = 'roundbutton' then
    Result:=TGuiRoundButton.Create
  else
  if Kind = 'speedbutton' then
    Result:=TGuiSpeedButton.Create
  else
  if Kind = 'tabbutton' then
    Result:=TGuiTabButton.Create
  else
  if Kind = 'togglebutton' then
    Result:=TGuiToggleButton.Create
  else
  if Kind = 'toggleswitch' then
    Result:=TGuiToggleSwitch.Create
  else
  if (Kind = 'activityindicator') OR (Kind = 'busyindicator') then
    Result:=TGuiActivityIndicator.Create
  else
  if Kind = 'checkbox' then
    Result:=TGuiCheckBox.Create
  else
  if Kind = 'radiobutton' then
    Result:=TGuiRadioButton.Create
  else
  if Kind = 'groupbox' then
    Result:=TGuiGroupBox.Create
  else
  if Kind = 'listbox' then
    Result:=TGuiListBox.Create
  else
  if Kind = 'wheelpicker' then
    Result:=TGuiWheelPicker.Create
  else
  if Kind = 'checklistbox' then
    Result:=TGuiCheckListBox.Create
  else
  if Kind = 'switchlistbox' then
    Result:=TGuiSwitchListBox.Create
  else
  if Kind = 'radiogroup' then
    Result:=TGuiRadioGroup.Create
  else
  if Kind = 'memo' then
    Result:=TGuiMemo.Create
  else
  if Kind = 'treeview' then
    Result:=TGuiTreeView.Create
  else
  if Kind = 'listview' then
    Result:=TGuiListView.Create
  else
  if Kind = 'itemtemplate' then
    Result:=TGuiItemTemplate.Create
  else
  if Kind = 'slider' then
    Result:=TGuiSlider.Create
  else
  if Kind = 'rangeslider' then
    Result:=TGuiRangeSlider.Create
  else
  if Kind = 'knob' then
    Result:=TGuiKnob.Create
  else
  if Kind = 'scrollbar' then
    Result:=TGuiScrollBar.Create
  else
  if Kind = 'progressbar' then
    Result:=TGuiProgressBar.Create
  else
  if Kind = 'dialgauge' then
    Result:=TGuiDialGauge.Create
  else
  if Kind = 'scope' then
    Result:=TGuiScope.Create
  else
  if Kind = 'spinedit' then
    Result:=TGuiSpinEdit.Create
  else
  if Kind = 'combobox' then
    Result:=TGuiComboBox.Create
  else
  if Kind = 'dropdownbutton' then
    Result:=TGuiDropDownButton.Create
  else
  if Kind = 'tabcontrol' then
    Result:=TGuiTabControl.Create
  else
  if Kind = 'pageindicator' then
    Result:=TGuiPageIndicator.Create
  else
  if Kind = 'pagecontrol' then
    Result:=TGuiPageControl.Create
  else
  if Kind = 'page' then
    Result:=TGuiPage.Create
  else
  if Kind = 'menubar' then
    Result:=TGuiMenuBar.Create
  else
  if Kind = 'popupmenu' then
    Result:=TGuiPopupMenu.Create
  else
  if Kind = 'toolbar' then
    Result:=TGuiToolBar.Create
  else
  if Kind = 'commandbar' then
    Result:=TGuiCommandBar.Create
  else
  if Kind = 'separator' then
    Result:=TGuiSeparator.Create
  else
  if Kind = 'statusbar' then
    Result:=TGuiStatusBar.Create
  else
  if Kind = 'dialog' then
    Result:=TGuiDialog.Create;
end;

procedure TGuiXmlLoader.LoadChildren(AParent: TGuiControl; const ANode: IXMLNode);
var
  I: Integer;
  ChildNode: IXMLNode;
  ChildControl: TGuiControl;
begin
  for I:=0 to ANode.ChildNodes.Count - 1 do
  begin
    ChildNode:=ANode.ChildNodes[I];

    if ChildNode.NodeType <> ntElement then
      Continue;

    ChildControl:=CreateControlForNode(ChildNode);
    if NOT Assigned(ChildControl) then
      Continue;

    try
      ApplyCommonAttributes(ChildControl, ChildNode);
    except
      ChildControl.Free;
      raise;
    end;
    AParent.Add(ChildControl);

    if Assigned(FOnControlCreated) then
      FOnControlCreated(Self, ChildControl, ChildNode);

    LoadChildren(ChildControl, ChildNode);
  end;
end;

function TGuiXmlLoader.LoadFromFile(const AFileName: String; AParent: TGuiControl): TGuiControl;
var
  Document: IXMLDocument;
begin
  Document:=TXMLDocument.Create(nil);
  Document.LoadFromFile(AFileName);
  Document.Active:=True;

  Result:=CreateControlForNode(Document.DocumentElement);
  try
  ApplyCommonAttributes(Result, Document.DocumentElement);

  if Assigned(AParent) then
    AParent.Add(Result);

  if Assigned(FOnControlCreated) then
    FOnControlCreated(Self, Result, Document.DocumentElement);

  LoadChildren(Result, Document.DocumentElement);
  except
    Result.Free;
    raise;
  end;
end;

function TGuiXmlLoader.LoadFromString(const AXml: String; AParent: TGuiControl): TGuiControl;
var
  Document: IXMLDocument;
begin
  Document:=TXMLDocument.Create(nil);
  Document.LoadFromXML(AXml);
  Document.Active:=True;

  Result:=CreateControlForNode(Document.DocumentElement);
  try
  ApplyCommonAttributes(Result, Document.DocumentElement);

  if Assigned(AParent) then
    AParent.Add(Result);

  if Assigned(FOnControlCreated) then
    FOnControlCreated(Self, Result, Document.DocumentElement);

  LoadChildren(Result, Document.DocumentElement);
  except
    Result.Free;
    raise;
  end;
end;

end.
