program BasicWindow;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{$APPTYPE CONSOLE}

uses
  SysUtils,
  SDL3,
  PasSDL3.GUI,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Resources,
  PasSDL3.GUI.Clipboard.SDL3,
  PasSDL3.GUI.Fonts,
  PasSDL3.GUI.Fonts.SDLTTF,
  PasSDL3.GUI.Theme,
  PasSDL3.GUI.Theme.Files,
  PasSDL3.GUI.Host.SDL3;

type
  TDemoHandlers = class
  private
    FContext: TGuiContext;
  public
    property Context: TGuiContext read FContext write FContext;
  private
    FModalOverlay: TGuiControl;
  public
    property ModalOverlay: TGuiControl read FModalOverlay write FModalOverlay;
  private
    FStatusBar: TGuiStatusBar;
  public
    property StatusBar: TGuiStatusBar read FStatusBar write FStatusBar;
  private
    FResources: TGuiResourceCatalog;
  public
    property Resources: TGuiResourceCatalog read FResources write FResources;
  private
    FThemeSelector: TGuiComboBox;
  public
    property ThemeSelector: TGuiComboBox read FThemeSelector write FThemeSelector;
  private
    FThemeButton: TGuiButton;
  public
    property ThemeButton: TGuiButton read FThemeButton write FThemeButton;
  private
    FDialog: TGuiDialog;
  public
    property Dialog: TGuiDialog read FDialog write FDialog;
  private
    FTextOffsetSpin: TGuiSpinEdit;
  public
    property TextOffsetSpin: TGuiSpinEdit read FTextOffsetSpin write FTextOffsetSpin;
    procedure BuyClicked(Sender: TGuiControl);
    procedure ShowDialog(Sender: TGuiControl);
    procedure CloseDialog(Sender: TGuiControl);
    procedure ApplySelectedTheme;
    procedure ApplyTextOffset(AControl: TGuiControl; AOffsetY: Integer);
    procedure TextOffsetChanged(Sender: TGuiControl);
    procedure EditSubmitted(Sender: TGuiControl);
    procedure CheckChanged(Sender: TGuiControl);
    procedure SliderChanged(Sender: TGuiControl);
    procedure ComboSelected(Sender: TGuiControl);
  end;

procedure TDemoHandlers.BuyClicked(Sender: TGuiControl);
begin
  Writeln('Buy button clicked');
end;

procedure TDemoHandlers.ShowDialog(Sender: TGuiControl);
begin
  if Assigned(Context) AND Assigned(ModalOverlay) then
  begin
    Context.ShowModal(ModalOverlay);

    if Assigned(StatusBar) then
      StatusBar.Caption:='Modal dialog is open';
  end;
end;

procedure TDemoHandlers.CloseDialog(Sender: TGuiControl);
begin
  if Assigned(Context) AND Assigned(ModalOverlay) then
  begin
    Context.CloseModal(ModalOverlay);

    if Assigned(StatusBar) then
      StatusBar.Caption:='PasSDL3-GUI common controls gallery';
  end;
end;

procedure TDemoHandlers.ApplySelectedTheme;
var
  Theme: TGuiTheme;
  CurrentStyle: TGuiStyle;
begin
  if NOT Assigned(Context) then
    Exit;

  Theme:=GuiDarkTheme;
  if Assigned(ThemeSelector) AND (ThemeSelector.SelectedIndex = 1) then
    Theme:=GuiReactorTheme;

  GuiApplyTheme(Context.Root, Theme);

  if Assigned(ModalOverlay) then
  begin
    GuiApplyTheme(ModalOverlay, Theme);
    ModalOverlay.BackgroundColor:=GuiColor(0, 0, 0, 0);
    if ModalOverlay IS TGuiModalOverlay then
      TGuiModalOverlay(ModalOverlay).DimColor:=GuiColor(3, 6, 10, 150);
  end;

  if Assigned(Resources) AND Assigned(ThemeButton) then
  begin
    CurrentStyle:=ThemeButton.Style;
    CurrentStyle.Background:=Resources.NineSliceDrawable('button.normal', GuiBox(8));
    CurrentStyle.HoverBackground:=Resources.NineSliceDrawable('button.hover', GuiBox(8));
    CurrentStyle.PressedBackground:=Resources.NineSliceDrawable('button.pressed', GuiBox(8));
    CurrentStyle.CheckedBackground:=CurrentStyle.PressedBackground;
    CurrentStyle.BorderColor:=GuiColor(0, 0, 0, 0);
    ThemeButton.Style:=CurrentStyle;
  end;

  if Assigned(Resources) AND Assigned(Dialog) then
  begin
    CurrentStyle:=Dialog.Style;
    CurrentStyle.Background:=Resources.NineSliceDrawable('dialog.panel', GuiBox(10));
    CurrentStyle.BorderColor:=GuiColor(0, 0, 0, 0);
    Dialog.Style:=CurrentStyle;
  end;

  if Assigned(TextOffsetSpin) then
  begin
    ApplyTextOffset(Context.Root, TextOffsetSpin.Value);
    ApplyTextOffset(ModalOverlay, TextOffsetSpin.Value);
  end;
end;

procedure TDemoHandlers.ApplyTextOffset(AControl: TGuiControl; AOffsetY: Integer);
var
  I: Integer;
begin
  if NOT Assigned(AControl) then
    Exit;

  AControl.TextOffset:=GuiPoint(0, AOffsetY);

  for I:=0 to AControl.ChildCount - 1 do
    ApplyTextOffset(AControl.Children[I], AOffsetY);
end;

procedure TDemoHandlers.TextOffsetChanged(Sender: TGuiControl);
var
  OffsetY: Integer;
begin
  if NOT (Sender IS TGuiSpinEdit) then
    Exit;

  OffsetY:=TGuiSpinEdit(Sender).Value;
  ApplyTextOffset(Context.Root, OffsetY);
  ApplyTextOffset(ModalOverlay, OffsetY);

  if Assigned(StatusBar) then
    StatusBar.Caption:='Text offset Y: ' + IntToStr(OffsetY);
end;

procedure TDemoHandlers.EditSubmitted(Sender: TGuiControl);
begin
  if Sender IS TGuiEdit then
    Writeln('Submitted: ' + TGuiEdit(Sender).Text);
end;

procedure TDemoHandlers.CheckChanged(Sender: TGuiControl);
begin
  if Sender IS TGuiCheckBox then
    Writeln('Checkbox: ' + BoolToStr(TGuiCheckBox(Sender).Checked, True));
end;

procedure TDemoHandlers.SliderChanged(Sender: TGuiControl);
begin
  if Sender IS TGuiSlider then
    Writeln('Slider: ' + FormatFloat('0.0', TGuiSlider(Sender).Value));
end;

procedure TDemoHandlers.ComboSelected(Sender: TGuiControl);
begin
  if Sender = ThemeSelector then
  begin
    ApplySelectedTheme;
    Exit;
  end;

  if (Sender IS TGuiComboBox) AND (TGuiComboBox(Sender).SelectedIndex >= 0) then
    Writeln('Combo: ' + TGuiComboBox(Sender).Items[TGuiComboBox(Sender).SelectedIndex]);
end;

function CreateThemeAtlas(ARenderer: PSDL_Renderer): PSDL_Texture;
var
  PreviousTarget: PSDL_Texture;
  Rect: TSDL_FRect;
begin
  Result:=SDL_CreateTexture(ARenderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, 192, 64);
  if NOT Assigned(Result) then
    Exit;

  SDL_SetTextureBlendMode(Result, SDL_BLENDMODE_BLEND);
  PreviousTarget:=SDL_GetRenderTarget(ARenderer);
  SDL_SetRenderTarget(ARenderer, Result);
  try
    SDL_SetRenderDrawBlendMode(ARenderer, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(ARenderer, 0, 0, 0, 0);
    SDL_RenderClear(ARenderer);

    SDL_SetRenderDrawColor(ARenderer, 49, 68, 93, 255);
    Rect.x:=0;
    Rect.y:=0;
    Rect.w:=48;
    Rect.h:=48;
    SDL_RenderFillRect(ARenderer, @Rect);
    SDL_SetRenderDrawColor(ARenderer, 122, 151, 190, 255);
    SDL_RenderRect(ARenderer, @Rect);

    SDL_SetRenderDrawColor(ARenderer, 57, 86, 116, 255);
    Rect.x:=48;
    SDL_RenderFillRect(ARenderer, @Rect);
    SDL_SetRenderDrawColor(ARenderer, 139, 176, 220, 255);
    SDL_RenderRect(ARenderer, @Rect);

    SDL_SetRenderDrawColor(ARenderer, 33, 48, 66, 255);
    Rect.x:=96;
    SDL_RenderFillRect(ARenderer, @Rect);
    SDL_SetRenderDrawColor(ARenderer, 118, 214, 180, 255);
    SDL_RenderRect(ARenderer, @Rect);

    SDL_SetRenderDrawColor(ARenderer, 36, 43, 53, 255);
    Rect.x:=144;
    Rect.y:=0;
    Rect.w:=48;
    Rect.h:=64;
    SDL_RenderFillRect(ARenderer, @Rect);
    SDL_SetRenderDrawColor(ARenderer, 118, 214, 180, 255);
    SDL_RenderRect(ARenderer, @Rect);
    SDL_SetRenderDrawColor(ARenderer, 78, 92, 112, 255);
    Rect.x:=148;
    Rect.y:=4;
    Rect.w:=40;
    Rect.h:=56;
    SDL_RenderRect(ARenderer, @Rect);
  finally
    SDL_SetRenderTarget(ARenderer, PreviousTarget);
  end;
end;

var
  Window: PSDL_Window;
  Renderer: PSDL_Renderer;
  SdlEvent: TSDL_Event;
  Context: TGuiContext;
  Host: TGuiSDL3Host;
  FontRenderer: TGuiSDLTTFFontRenderer;
  MenuBar: TGuiMenuBar;
  ToolBar: TGuiCommandBar;
  ToolButtonNew: TGuiButton;
  ToolButtonSave: TGuiButton;
  ToolButtonRun: TGuiButton;
  ToolButtonModal: TGuiButton;
  ToolDropDown: TGuiDropDownButton;
  ThemeSelector: TGuiComboBox;
  Panel: TGuiPanel;
  Splitter: TGuiSplitter;
  SidePanel: TGuiPanel;
  Frame: TGuiFrame;
  LabelControl: TGuiLabel;
  LinkLabel: TGuiLinkLabel;
  Edit: TGuiEdit;
  ReadOnlyEdit: TGuiEdit;
  CheckBox: TGuiCheckBox;
  Separator: TGuiSeparator;
  GroupBox: TGuiGroupBox;
  RadioEasy: TGuiRadioButton;
  RadioNormal: TGuiRadioButton;
  RadioHard: TGuiRadioButton;
  Slider: TGuiSlider;
  VerticalSlider: TGuiSlider;
  ProgressBar: TGuiProgressBar;
  DialGauge: TGuiDialGauge;
  Scope: TGuiScope;
  SpinEdit: TGuiSpinEdit;
  ComboBox: TGuiComboBox;
  PageControl: TGuiPageControl;
  StatsPage: TGuiPage;
  InfoPage: TGuiPage;
  LogPage: TGuiPage;
  PageLabel: TGuiLabel;
  ValueLabel: TGuiValueLabel;
  ItemTemplate: TGuiItemTemplate;
  Button: TGuiButton;
  TreeView: TGuiTreeView;
  Memo: TGuiMemo;
  ListView: TGuiListView;
  StatusBar: TGuiStatusBar;
  ModalOverlay: TGuiModalOverlay;
  ModalDialog: TGuiDialog;
  Resources: TGuiResourceCatalog;
  ThemeAtlas: PSDL_Texture;
  Handler: TDemoHandlers;
  Theme: TGuiTheme;
  Running: Boolean;
begin
  Window:=nil;
  Renderer:=nil;
  Context:=nil;
  Host:=nil;
  FontRenderer:=nil;
  Resources:=nil;
  ThemeAtlas:=nil;
  Handler:=nil;
  Theme:=GuiDarkTheme;

  if NOT SDL_Init(SDL_INIT_VIDEO OR SDL_INIT_GAMEPAD) then
    raise Exception.CreateFmt('SDL_Init failed: %s', [String(SDL_GetError)]);

  try
    Window:=SDL_CreateWindow('PasSDL3-GUI basic window', 960, 540, SDL_WINDOW_RESIZABLE);
    if NOT Assigned(Window) then
      raise Exception.CreateFmt('SDL_CreateWindow failed: %s', [String(SDL_GetError)]);

    SDL_StartTextInput(Window);

    Renderer:=SDL_CreateRenderer(Window, nil);
    if NOT Assigned(Renderer) then
      raise Exception.CreateFmt('SDL_CreateRenderer failed: %s', [String(SDL_GetError)]);

    Resources:=TGuiResourceCatalog.Create;
    ThemeAtlas:=CreateThemeAtlas(Renderer);
    Resources.RegisterRegion('button.normal', ThemeAtlas, GuiRect(0, 0, 48, 48));
    Resources.RegisterRegion('button.hover', ThemeAtlas, GuiRect(48, 0, 48, 48));
    Resources.RegisterRegion('button.pressed', ThemeAtlas, GuiRect(96, 0, 48, 48));
    Resources.RegisterRegion('dialog.panel', ThemeAtlas, GuiRect(144, 0, 48, 64));

    Context:=TGuiContext.Create;
    Context.Resize(960, 540);
    Host:=TGuiSDL3Host.Create(Renderer, Context);
    FontRenderer:=TGuiSDLTTFFontRenderer.Create(GuiDefaultFontFile, 18);
    Host.FontRenderer:=FontRenderer;
    Handler:=TDemoHandlers.Create;
    Handler.Context:=Context;
    Handler.Resources:=Resources;

    MenuBar:=TGuiMenuBar.Create;
    MenuBar.Bounds:=GuiRect(0, 0, 960, 26);
    MenuBar.Anchors:=[ganLeft, ganTop, ganRight];
    MenuBar.AddItem('File');
    MenuBar.AddItem('Edit');
    MenuBar.AddItem('View');
    MenuBar.AddItem('Help');
    Context.Root.Add(MenuBar);

    ToolBar:=TGuiCommandBar.Create;
    ToolBar.Bounds:=GuiRect(0, 26, 960, 42);
    ToolBar.Anchors:=[ganLeft, ganTop, ganRight];
    ToolBar.ShowSectionSeparators:=True;
    Context.Root.Add(ToolBar);

    ToolButtonNew:=TGuiButton.Create;
    ToolButtonNew.Bounds:=GuiRect(0, 0, 74, 30);
    ToolButtonNew.Caption:='New';
    ToolBar.Add(ToolButtonNew);

    ToolButtonSave:=TGuiButton.Create;
    ToolButtonSave.Bounds:=GuiRect(0, 0, 74, 30);
    ToolButtonSave.Caption:='Save';
    ToolBar.Add(ToolButtonSave);

    ToolButtonRun:=TGuiButton.Create;
    ToolButtonRun.Bounds:=GuiRect(0, 0, 74, 30);
    ToolButtonRun.Caption:='Run';
    ToolButtonRun.Icon:=GuiColorDrawable(GuiColor(118, 214, 180));
    ToolButtonRun.IconSize:=GuiSize(10, 10);
    ToolBar.Add(ToolButtonRun);

    ThemeSelector:=TGuiComboBox.Create;
    ThemeSelector.Bounds:=GuiRect(0, 0, 128, 30);
    ThemeSelector.AddItem('Dark');
    ThemeSelector.AddItem('Reactor');
    ThemeSelector.SelectedIndex:=0;
    ThemeSelector.OnSelect:=Handler.ComboSelected;
    ToolBar.Add(ThemeSelector);
    Handler.ThemeSelector:=ThemeSelector;

    ToolButtonModal:=TGuiButton.Create;
    ToolButtonModal.Bounds:=GuiRect(0, 0, 82, 30);
    ToolButtonModal.Caption:='Dialog';
    ToolButtonModal.OnClick:=Handler.ShowDialog;
    ToolBar.Add(ToolButtonModal);
    Handler.ThemeButton:=ToolButtonModal;

    ToolDropDown:=TGuiDropDownButton.Create;
    ToolDropDown.Bounds:=GuiRect(0, 0, 118, 30);
    ToolDropDown.Caption:='Options';
    ToolDropDown.AddItem('Fast');
    ToolDropDown.AddItem('Balanced');
    ToolDropDown.AddItem('Quality');
    ToolBar.Add(ToolDropDown);

    Panel:=TGuiPanel.Create;
    Panel.Bounds:=GuiRect(48, 74, 620, 414);
    Panel.MinWidth:=320;
    Panel.MinHeight:=380;
    Panel.Anchors:=[ganLeft, ganTop, ganBottom];
    Context.Root.Add(Panel);

    Splitter:=TGuiSplitter.Create;
    Splitter.Bounds:=GuiRect(676, 74, 8, 414);
    Splitter.Anchors:=[ganLeft, ganTop, ganBottom];
    Splitter.Orientation:=goVertical;
    Splitter.TargetControl:=Panel;
    Context.Root.Add(Splitter);

    SidePanel:=TGuiPanel.Create;
    SidePanel.Bounds:=GuiRect(700, 74, 220, 414);
    SidePanel.Anchors:=[ganTop, ganRight, ganBottom];
    Context.Root.Add(SidePanel);

    LabelControl:=TGuiLabel.Create;
    LabelControl.Bounds:=GuiRect(24, 24, 300, 32);
    LabelControl.Caption:='Shop preview';
    Panel.Add(LabelControl);

    LinkLabel:=TGuiLinkLabel.Create;
    LinkLabel.Bounds:=GuiRect(320, 24, 230, 28);
    LinkLabel.Anchors:=[ganTop, ganRight];
    LinkLabel.Caption:='Open documentation';
    Panel.Add(LinkLabel);

    Edit:=TGuiEdit.Create;
    Edit.Bounds:=GuiRect(24, 78, 250, 36);
    Edit.Anchors:=[ganLeft, ganTop, ganRight];
    Edit.Placeholder:='Item name';
    Edit.OnSubmit:=Handler.EditSubmitted;
    Panel.Add(Edit);

    ReadOnlyEdit:=TGuiEdit.Create;
    ReadOnlyEdit.Bounds:=GuiRect(24, 124, 250, 36);
    ReadOnlyEdit.Anchors:=[ganLeft, ganTop, ganRight];
    ReadOnlyEdit.Text:='Read-only text';
    ReadOnlyEdit.ReadOnly:=True;
    Panel.Add(ReadOnlyEdit);

    CheckBox:=TGuiCheckBox.Create;
    CheckBox.Bounds:=GuiRect(24, 176, 180, 32);
    CheckBox.Caption:='Enable upgrades';
    CheckBox.OnClick:=Handler.CheckChanged;
    Panel.Add(CheckBox);

    Separator:=TGuiSeparator.Create;
    Separator.Bounds:=GuiRect(24, 214, 250, 8);
    Separator.Anchors:=[ganLeft, ganTop, ganRight];
    Panel.Add(Separator);

    GroupBox:=TGuiGroupBox.Create;
    GroupBox.Bounds:=GuiRect(320, 78, 230, 130);
    GroupBox.Anchors:=[ganTop, ganRight];
    GroupBox.Caption:='Difficulty';
    Panel.Add(GroupBox);

    RadioEasy:=TGuiRadioButton.Create;
    RadioEasy.Bounds:=GuiRect(16, 28, 150, 28);
    RadioEasy.Caption:='Easy';
    RadioEasy.GroupName:='difficulty';
    RadioEasy.Checked:=True;
    GroupBox.Add(RadioEasy);

    RadioNormal:=TGuiRadioButton.Create;
    RadioNormal.Bounds:=GuiRect(16, 60, 150, 28);
    RadioNormal.Caption:='Normal';
    RadioNormal.GroupName:='difficulty';
    GroupBox.Add(RadioNormal);

    RadioHard:=TGuiRadioButton.Create;
    RadioHard.Bounds:=GuiRect(16, 92, 150, 28);
    RadioHard.Caption:='Hard';
    RadioHard.GroupName:='difficulty';
    GroupBox.Add(RadioHard);

    Slider:=TGuiSlider.Create;
    Slider.Bounds:=GuiRect(24, 226, 250, 34);
    Slider.Anchors:=[ganLeft, ganTop, ganRight];
    Slider.MinValue:=0;
    Slider.MaxValue:=100;
    Slider.Value:=35;
    Slider.OnChange:=Handler.SliderChanged;
    Panel.Add(Slider);

    VerticalSlider:=TGuiSlider.Create;
    VerticalSlider.Bounds:=GuiRect(570, 226, 28, 112);
    VerticalSlider.Anchors:=[ganTop, ganRight];
    VerticalSlider.Orientation:=goVertical;
    VerticalSlider.MinValue:=0;
    VerticalSlider.MaxValue:=100;
    VerticalSlider.Value:=72;
    Panel.Add(VerticalSlider);

    ProgressBar:=TGuiProgressBar.Create;
    ProgressBar.Bounds:=GuiRect(24, 272, 250, 28);
    ProgressBar.Anchors:=[ganLeft, ganTop, ganRight];
    ProgressBar.Value:=68;
    ProgressBar.ShowText:=True;
    ProgressBar.SegmentCount:=10;
    ProgressBar.ShowTicks:=True;
    ProgressBar.TickCount:=11;
    ProgressBar.ShowThreshold:=True;
    ProgressBar.ThresholdValue:=75;
    Panel.Add(ProgressBar);

    DialGauge:=TGuiDialGauge.Create;
    DialGauge.Bounds:=GuiRect(458, 344, 82, 62);
    DialGauge.Anchors:=[ganRight, ganBottom];
    DialGauge.Caption:='Charge';
    DialGauge.Value:=72;
    DialGauge.ShowValue:=True;
    DialGauge.TickCount:=13;
    DialGauge.MajorTickEvery:=3;
    Panel.Add(DialGauge);

    Button:=TGuiButton.Create;
    Button.Bounds:=GuiRect(24, 356, 160, 44);
    Button.Anchors:=[ganLeft, ganBottom];
    Button.Caption:='Buy item';
    Button.OnClick:=Handler.BuyClicked;
    Panel.Add(Button);

    ComboBox:=TGuiComboBox.Create;
    ComboBox.Bounds:=GuiRect(24, 306, 250, 36);
    ComboBox.Anchors:=[ganLeft, ganTop, ganRight];
    ComboBox.AddItem('Warrior');
    ComboBox.AddItem('Mage');
    ComboBox.AddItem('Rogue');
    ComboBox.OnSelect:=Handler.ComboSelected;
    Panel.Add(ComboBox);

    PageControl:=TGuiPageControl.Create;
    PageControl.Bounds:=GuiRect(320, 226, 230, 112);
    PageControl.Anchors:=[ganTop, ganRight];
    StatsPage:=PageControl.AddPage('Stats');
    ValueLabel:=TGuiValueLabel.Create;
    ValueLabel.Bounds:=GuiRect(8, 8, 190, 24);
    ValueLabel.Caption:='Health';
    ValueLabel.ValueText:='68';
    ValueLabel.UnitText:='/100';
    ValueLabel.ValueColor:=GuiColor(118, 214, 180);
    StatsPage.Add(ValueLabel);
    ValueLabel:=TGuiValueLabel.Create;
    ValueLabel.Bounds:=GuiRect(8, 34, 190, 24);
    ValueLabel.Caption:='Armor';
    ValueLabel.ValueText:='14';
    ValueLabel.ValueColor:=GuiColor(139, 176, 220);
    StatsPage.Add(ValueLabel);
    InfoPage:=PageControl.AddPage('Info');
    PageLabel:=TGuiLabel.Create;
    PageLabel.Bounds:=GuiRect(8, 8, 190, 24);
    PageLabel.Caption:='Current class: Rogue';
    InfoPage.Add(PageLabel);
    ItemTemplate:=TGuiItemTemplate.Create;
    ItemTemplate.Bounds:=GuiRect(8, 36, 198, 48);
    ItemTemplate.Title:='Steel blade';
    ItemTemplate.Subtitle:='Rare / equipped';
    ItemTemplate.DetailText:='+12';
    ItemTemplate.ShowSwatch:=True;
    ItemTemplate.SwatchColor:=GuiColor(255, 214, 102);
    ItemTemplate.Selected:=True;
    InfoPage.Add(ItemTemplate);
    LogPage:=PageControl.AddPage('Log');
    PageLabel:=TGuiLabel.Create;
    PageLabel.Bounds:=GuiRect(8, 8, 190, 24);
    PageLabel.Caption:='No pending alerts';
    LogPage.Add(PageLabel);
    Scope:=TGuiScope.Create;
    Scope.Bounds:=GuiRect(104, 28, 106, 66);
    Scope.Anchors:=[ganTop, ganRight, ganBottom];
    Scope.ShowSweep:=True;
    Scope.SweepAngle:=32;
    Scope.AddMarker(-0.45, 0.24, GuiColor(118, 214, 180), 5, '');
    Scope.AddMarker(0.36, -0.32, GuiColor(255, 214, 102), 5, '');
    Scope.AddMarker(0.14, 0.52, GuiColor(139, 176, 220), 4, '');
    LogPage.Add(Scope);
    Panel.Add(PageControl);

    SpinEdit:=TGuiSpinEdit.Create;
    SpinEdit.Bounds:=GuiRect(320, 352, 120, 34);
    SpinEdit.Anchors:=[ganTop, ganRight];
    SpinEdit.MinValue:=-6;
    SpinEdit.MaxValue:=6;
    SpinEdit.Value:=0;
    SpinEdit.OnChange:=Handler.TextOffsetChanged;
    Panel.Add(SpinEdit);
    Handler.TextOffsetSpin:=SpinEdit;

    Frame:=TGuiFrame.Create;
    Frame.Bounds:=GuiRect(14, 14, 192, 118);
    Frame.Anchors:=[ganLeft, ganTop, ganRight];
    Frame.Title:='Project';
    Frame.HeaderHeight:=28;
    SidePanel.Add(Frame);

    TreeView:=TGuiTreeView.Create;
    TreeView.Bounds:=GuiRect(8, 36, 176, 72);
    TreeView.Anchors:=[ganLeft, ganTop, ganRight, ganBottom];
    TreeView.AddNode('Project');
    TreeView.AddNode('Source', 1);
    TreeView.AddNode('Controls.pas', 2);
    TreeView.AddNode('Themes.pas', 2);
    TreeView.AddNode('Renderer.SDL3.pas', 2);
    TreeView.AddNode('Examples', 1);
    TreeView.AddNode('BasicWindow', 2);
    TreeView.AddNode('ShopMenu', 2);
    TreeView.AddNode('Assets', 1);
    TreeView.AddNode('Icons', 2);
    TreeView.Nodes[5].Expanded:=False;
    Frame.Add(TreeView);

    Memo:=TGuiMemo.Create;
    Memo.Bounds:=GuiRect(14, 146, 192, 112);
    Memo.Anchors:=[ganLeft, ganTop, ganRight];
    Memo.AddLine('Memo / log view');
    Memo.AddLine('Line 1: initialized');
    Memo.AddLine('Line 2: controls ready');
    Memo.AddLine('Line 3: theme applied');
    Memo.AddLine('Line 4: scrolling works');
    Memo.AddLine('Line 5: more text');
    Memo.AddLine('Line 6: more text');
    Memo.AddLine('Line 7: more text');
    Memo.AddLine('Line 8: more text');
    SidePanel.Add(Memo);

    ListView:=TGuiListView.Create;
    ListView.Bounds:=GuiRect(14, 272, 192, 118);
    ListView.Anchors:=[ganLeft, ganTop, ganRight, ganBottom];
    ListView.AddColumn('Name', 86);
    ListView.AddColumn('Qty', 42);
    ListView.AddColumn('State', 52);
    ListView.AddRow(['Sword', '1', 'Ready']);
    ListView.AddRow(['Potion', '6', 'Stock']);
    ListView.AddRow(['Boots', '1', 'Ready']);
    ListView.AddRow(['Charm', '2', 'New']);
    ListView.AddRow(['Shield', '1', 'Ready']);
    ListView.AddRow(['Ring', '1', 'New']);
    SidePanel.Add(ListView);

    StatusBar:=TGuiStatusBar.Create;
    StatusBar.Bounds:=GuiRect(0, 510, 960, 30);
    StatusBar.Anchors:=[ganLeft, ganRight, ganBottom];
    StatusBar.Caption:='PasSDL3-GUI common controls gallery';
    Context.Root.Add(StatusBar);
    Handler.StatusBar:=StatusBar;

    ModalDialog:=TGuiDialog.Create;
    ModalDialog.Bounds:=GuiRect(0, 0, 360, 236);
    ModalDialog.Title:='Modal dialog';
    ModalDialog.MessageText:='This dialog lives on the dialog layer and captures input until it is closed.';
    ModalDialog.OnClose:=Handler.CloseDialog;
    ModalDialog.AddButton('OK', True);
    ModalDialog.AddButton('Close');
    Handler.Dialog:=ModalDialog;

    ModalOverlay:=TGuiModalOverlay.CreateWithDialog(ModalDialog);
    ModalOverlay.Bounds:=GuiRect(0, 0, 960, 540);
    ModalOverlay.Anchors:=[ganLeft, ganTop, ganRight, ganBottom];
    ModalOverlay.DimColor:=GuiColor(3, 6, 10, 150);
    Handler.ModalOverlay:=ModalOverlay;

    Handler.ApplySelectedTheme;

    Context.SetFocus(Edit);

    Running:=True;
    while Running do
    begin
      while SDL_PollEvent(@SdlEvent) do
      begin
        if TSDL_EventType(SdlEvent.type_) = SDL_EVENT_QUIT then
          Running:=False
        else
          Host.ProcessEvent(SdlEvent);
      end;

      SDL_SetRenderDrawColor(Renderer, 14, 16, 20, 255);
      SDL_RenderClear(Renderer);
      Host.Render;
      SDL_RenderPresent(Renderer);
      SDL_Delay(16);
      if FindCmdLineSwitch('smoke-test') then Running:=False;
    end;
  finally
    Handler.Free;
    Host.Free;
    FontRenderer.Free;
    Context.Free;
    Resources.Free;

    if Assigned(ThemeAtlas) then
      SDL_DestroyTexture(ThemeAtlas);

    if Assigned(Renderer) then
      SDL_DestroyRenderer(Renderer);

    if Assigned(Window) then
    begin
      SDL_StopTextInput(Window);
      SDL_DestroyWindow(Window);
    end;

    SDL_Quit;
  end;
end.
