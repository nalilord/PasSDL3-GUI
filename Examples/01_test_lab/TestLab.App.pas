unit TestLab.App;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils, Math, SDL3,
  PasSDL3.GUI.Types, PasSDL3.GUI.Context, PasSDL3.GUI.Controls,
  PasSDL3.GUI.Host.SDL3,
  PasSDL3.GUI.Fonts, PasSDL3.GUI.Fonts.SDLTTF, PasSDL3.GUI.Resources,
  PasSDL3.GUI.Theme, PasSDL3.GUI.Theme.Files, PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Clipboard.SDL3;

const
  LAB_PAGE_COUNT = 10;

type
  TLabControlClass = class of TGuiControl;
  TTestLab = class
  private
    FWindow: PSDL_Window;
    FRenderer: PSDL_Renderer;
    FHost: TGuiSDL3Host;
    FFonts: TGuiSDLTTFFontCollection;
    FResources: TGuiResourceCatalog;
    FAtlas: PSDL_Texture;
    FPages: array[0..LAB_PAGE_COUNT - 1] of TGuiScrollBox;
    FManual: array[0..LAB_PAGE_COUNT - 1] of String;
    FNavigation: TGuiListBox;
    FInstructions, FLog, FResults, FNotes: TGuiMemo;
    FStatus: TGuiStatusBar;
    FThemeSelect, FFontSelect: TGuiComboBox;
    FEdit: TGuiEdit;
    FMemo: TGuiMemo;
    FTable: TGuiListView;
    FSlider: TGuiSlider;
    FRangeSlider: TGuiRangeSlider;
    FSpinEditor: TGuiSpinEdit;
    FEditableCombo: TGuiComboBox;
    FActivity: TGuiActivityIndicator;
    FLabPages: TGuiPageControl;
    FPageIndicator: TGuiPageIndicator;
    FActivitySwitch: TGuiToggleSwitch;
    FProgress: TGuiProgressBar;
    FDial: TGuiDialGauge;
    FScope: TGuiScope;
    FDynamic: TGuiGridPanel;
    FCount: TGuiSpinEdit;
    FStateTarget: TGuiPanel;
    FXmlParent: TGuiPanel;
    FLabMenu: TGuiMenuBar;
    FLabPopup: TGuiPopupMenu;
    FReport, FCoverage: TStringList;
    FClosedDialogs: TList;
    FCurrentPage, FPending, FPasses, FFailures: Integer;
    FFrames, FEvents: UInt64;
    FStarted, FLastStatus: UInt64;
    FAnimate, FRunning, FReactor, FLogical, FQuiet: Boolean;
    FRenderMs: Double;
    function Place(AClass: TLabControlClass; AParent: TGuiControl; const AName: String;
      AX, AY, AWidth, AHeight: Single): TGuiControl;
    function LabelAt(AParent: TGuiControl; const ACaption: String; AX, AY: Single; AWidth: Single = 920): TGuiLabel;
    function ButtonAt(AParent: TGuiControl; const ACaption: String; AX, AY: Single; AAction: Integer = 0): TGuiButton;
    function MakePage(AIndex: Integer; const ATitle, AInstructions: String; AHeight: Single = 640): TGuiPanel;
    procedure Build;
    procedure BuildButtons;
    procedure BuildText;
    procedure BuildLists;
    procedure BuildRanges;
    procedure BuildLayout;
    procedure BuildMenus;
    procedure BuildDialogs;
    procedure BuildRendering;
    procedure BuildLifetime;
    procedure BuildChecks;
    procedure CreateAtlas;
    procedure Changed(Sender: TGuiControl);
    procedure SpinValueModified(Sender: TGuiControl);
    procedure ComboAccepted(Sender: TGuiControl);
    procedure ComboTextChanged(Sender: TGuiControl);
    procedure ItemChecked(Sender: TGuiControl; AIndex: Integer);
    procedure RangeMoved(Sender: TGuiControl; AThumb: TGuiRangeThumb);
    procedure KnobWrapped(Sender: TGuiControl; ADirection: TGuiWrapDirection);
    procedure MenuCommand(Sender: TObject);
    procedure Action(Sender: TGuiControl);
    procedure FocusChanged(Sender: TObject; OldControl, NewControl: TGuiControl);
    procedure DialogClosed(Sender: TGuiControl);
    procedure SelectPage(AIndex: Integer);
    procedure ApplyTheme;
    procedure ExecuteAction(AAction: Integer);
    procedure OpenDialog(AModal, ANested: Boolean; AMode: TGuiDialogWindowMode = gdwmResizable);
    procedure CollectCoverage(AControl: TGuiControl);
    procedure RunChecks;
    procedure Check(ACondition: Boolean; const AMessage: String);
    procedure Log(const AText: String);
    procedure ExportReport(const AFileName: String);
    procedure Render;
    procedure Tick;
    function CommandValue(const AName: String): String;
  public
    constructor Create;
    destructor Destroy; override;
    function Run: Boolean;
  end;

implementation

uses
  PasSDL3.GUI.Text,
  {$IFNDEF FPC}
  PasSDL3.GUI.Loader.XML,
  {$ENDIF}
  TestLab.Checks;

type
  TCanvasSample = class(TGuiControl)
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas);
    override;
  end;

procedure SetBoundsWidth(AControl: TGuiControl; AValue: TGuiFloat);
var
  CurrentBounds: TGuiRect;
begin
  CurrentBounds:=AControl.Bounds;
  CurrentBounds.Width:=AValue;
  AControl.Bounds:=CurrentBounds;
end;

procedure SetBoundsHeight(AControl: TGuiControl; AValue: TGuiFloat);
var
  CurrentBounds: TGuiRect;
begin
  CurrentBounds:=AControl.Bounds;
  CurrentBounds.Height:=AValue;
  AControl.Bounds:=CurrentBounds;
end;

procedure SetBoundsPosition(AControl: TGuiControl; ALeft, ATop: TGuiFloat);
var
  CurrentBounds: TGuiRect;
begin
  CurrentBounds:=AControl.Bounds;
  CurrentBounds.Left:=ALeft;
  CurrentBounds.Top:=ATop;
  AControl.Bounds:=CurrentBounds;
end;

procedure SetStyleSurfaces(AControl: TGuiControl; const ADrawable: TGuiDrawable);
var
  CurrentStyle: TGuiStyle;
begin
  CurrentStyle:=AControl.Style;
  CurrentStyle.Background:=ADrawable;
  CurrentStyle.HoverBackground:=ADrawable;
  CurrentStyle.PressedBackground:=ADrawable;
  AControl.Style:=CurrentStyle;
end;

const
  PAGE_NAMES: array[0..LAB_PAGE_COUNT - 1] of String = (
    'Buttons & states', 'Text & editing', 'Lists & selection', 'Ranges & HUD',
    'Layout & scrolling', 'Tabs & menus', 'Dialogs & layers', 'Rendering & themes',
    'Lifetime & stress', 'Checks & reports');
  EXPECTED_CLASSES = 'TGuiControl,TGuiContainer,TGuiLayerControl,TGuiPanel,TGuiFrame,TGuiStackPanel,TGuiGridPanel,' +
    'TGuiScrollBox,TGuiLabel,TGuiLinkLabel,TGuiImage,TGuiIcon,TGuiValueLabel,TGuiEdit,TGuiMemo,TGuiListBox,' +
    'TGuiTreeView,TGuiHeaderControl,TGuiListView,TGuiItemTemplate,TGuiButton,TGuiToggleButton,TGuiCheckBox,' +
    'TGuiRadioButton,TGuiGroupBox,TGuiSeparator,TGuiStatusBar,TGuiTransparentPanel,TGuiTransparentStackPanel,' +
    'TGuiDialog,TGuiModalOverlay,TGuiToolBar,TGuiCommandBar,TGuiSplitter,TGuiSlider,TGuiScrollBar,TGuiProgressBar,' +
    'TGuiDialGauge,TGuiScope,TGuiSpinEdit,TGuiComboBox,TGuiDropDownButton,TGuiTabControl,TGuiPage,TGuiPageControl,' +
    'TGuiMenuBar,TGuiPopupMenu,TGuiActivityIndicator,TGuiToggleSwitch,TGuiPageIndicator,TGuiSpeedButton,' +
    'TGuiTabButton,TGuiRadioGroup,TGuiRoundButton,TGuiKnob,TGuiCheckListBox,TGuiSwitchListBox,TGuiDelayButton,' +
    'TGuiRangeSlider,TGuiWheelPicker';

procedure TCanvasSample.PaintSelf(ACanvas: TGuiCanvas);
var
  R: TGuiRect;
  I: Integer;
begin
  R:=AbsoluteBounds;
  ACanvas.FillRect(R, GuiColor(15, 22, 30));
  for I:=0 to 4 do
    ACanvas.DrawLine(GuiPoint(R.Left + 12, R.Top + 14 + I * 24), GuiPoint(R.Left + 175, R.Top + 34 + I * 24), I + 1,
      GuiColor(90 + I * 30, 190, 160));
  ACanvas.PushClipRect(GuiRect(R.Left + 210, R.Top + 16, 180, 112));
  try
    ACanvas.FillRect(GuiRect(R.Left + 190, R.Top, 230, 180), GuiColor(180, 80, 120, 180));
    ACanvas.PushClipRect(GuiRect(R.Left + 240, R.Top + 40, 100, 56));
    try
      ACanvas.FillRect(R, GuiColor(80, 190, 230, 210));
    finally
      ACanvas.PopClipRect;
    end;
  finally
    ACanvas.PopClipRect;
  end;
  ACanvas.DrawBorder(R, 2, GuiColor(130, 190, 220));
end;

constructor TTestLab.Create;
begin
  inherited Create;
  FReport:=TStringList.Create;
  FCoverage:=TStringList.Create;
  FClosedDialogs:=TList.Create;
  FCoverage.Sorted:=True;
  FCoverage.Duplicates:=dupIgnore;
  FCurrentPage:=-1;
  FAnimate:=True;
  FStarted:=TThread.GetTickCount64;
  if NOT SDL_Init(SDL_INIT_VIDEO OR SDL_INIT_GAMEPAD) then
    raise Exception.Create(String(SDL_GetError));
  FWindow:=SDL_CreateWindow('PasSDL3-GUI Test Lab', 1280, 900, SDL_WINDOW_RESIZABLE);
  if NOT Assigned(FWindow) then raise Exception.Create(String(SDL_GetError));
  SDL_SetWindowMinimumSize(FWindow, 1000, 760);
  FRenderer:=SDL_CreateRenderer(FWindow, nil);
  if NOT Assigned(FRenderer) then raise Exception.Create(String(SDL_GetError));
  FHost:=TGuiSDL3Host.Create(FRenderer);
  FFonts:=TGuiSDLTTFFontCollection.Create;
  FFonts.AddFont(GuiFontSpec('body', GuiDefaultFontFile, 16));
  FFonts.AddFont(GuiFontSpec('large', GuiDefaultFontFile, 22));
  FFonts.AddFont(GuiFontSpec('mono', GuiDefaultFontFile(True), 15));
  FHost.Canvas.Fonts:=FFonts;
  FResources:=TGuiResourceCatalog.Create;
  CreateAtlas;
  Build;
  ApplyTheme;
  FHost.Context.OnFocusChanged:=FocusChanged;
  SelectPage(0);
  Log('Ready. Choose a section; exercise its checklist; mark it passed or failed.');
end;

destructor TTestLab.Destroy;
begin
  FHost.Free;
  FFonts.Free;
  FResources.Free;
  if Assigned(FAtlas) then SDL_DestroyTexture(FAtlas);
  if Assigned(FRenderer) then SDL_DestroyRenderer(FRenderer);
  if Assigned(FWindow) then SDL_DestroyWindow(FWindow);
  SDL_Quit;
  FCoverage.Free;
  FClosedDialogs.Free;
  FReport.Free;
  inherited Destroy;
end;

function TTestLab.Place(AClass: TLabControlClass; AParent: TGuiControl; const AName: String;
  AX, AY, AWidth, AHeight: Single): TGuiControl;
begin
  Result:=AClass.Create;
  Result.Name:=AName;
  Result.Caption:=AName;
  Result.Bounds:=GuiRect(AX, AY, AWidth, AHeight);
  Result.OnClick:=Changed;
  AParent.Add(Result);
end;

function TTestLab.LabelAt(AParent: TGuiControl; const ACaption: String; AX, AY: Single; AWidth: Single): TGuiLabel;
begin
  Result:=TGuiLabel(Place(TGuiLabel, AParent, ACaption, AX, AY, AWidth, 26));
end;

function TTestLab.ButtonAt(AParent: TGuiControl; const ACaption: String; AX, AY: Single; AAction: Integer): TGuiButton;
begin
  Result:=TGuiButton(Place(TGuiButton, AParent, ACaption, AX, AY, 176, 34));
  Result.Tag:=AAction;
  if AAction <> 0 then Result.OnClick:=Action;
  Result.Hint:=ACaption + ' - observe the event log below';
end;

function TTestLab.MakePage(AIndex: Integer; const ATitle, AInstructions: String; AHeight: Single): TGuiPanel;
begin
  FPages[AIndex]:=TGuiScrollBox(Place(TGuiScrollBox, FHost.Context.Root, PAGE_NAMES[AIndex], 218, 114, 1046, 610));
  FPages[AIndex].Anchors:=[ganLeft, ganTop, ganRight, ganBottom];
  FPages[AIndex].Visible:=False;
  Result:=TGuiPanel(Place(TGuiPanel, FPages[AIndex], 'Content', 0, 0, 1008, AHeight));
  LabelAt(Result, ATitle, 18, 12).FontName:='large';
  LabelAt(Result, AInstructions, 18, 44, 970).StyleClass:='Muted';
  FManual[AIndex]:='NOT RUN';
end;

procedure TTestLab.Build;
var
  I: Integer;
  Root: TGuiControl;
  B: TGuiButton;
begin
  Root:=FHost.Context.Root;
  Root.StyleClass:='Window';
  LabelAt(Root, 'PasSDL3-GUI / Test Lab', 18, 12, 600).FontName:='large';
  LabelAt(Root, 'Interactive gallery + repeatable checks', 680, 12, 570).StyleClass:='Muted';
  FThemeSelect:=TGuiComboBox(Place(TGuiComboBox, Root, 'Theme', 18, 58, 145, 34));
  FThemeSelect.AddItem('Dark');
  FThemeSelect.AddItem('Reactor');
  FThemeSelect.OnSelect:=Changed;
  FFontSelect:=TGuiComboBox(Place(TGuiComboBox, Root, 'Font', 174, 58, 145, 34));
  FFontSelect.AddItem('body');
  FFontSelect.AddItem('mono');
  FFontSelect.AddItem('large');
  FFontSelect.OnSelect:=Changed;
  B:=ButtonAt(Root, 'Run all checks', 330, 58, 1);
  SetBoundsWidth(B, 154);
  B.StyleClass:='Primary';
  SetBoundsWidth(ButtonAt(Root, 'Export report', 494, 58, 2), 154);
  SetBoundsWidth(ButtonAt(Root, 'Mark page PASS', 658, 58, 3), 154);
  SetBoundsWidth(ButtonAt(Root, 'Mark page FAIL', 822, 58, 4), 154);
  FNavigation:=TGuiListBox(Place(TGuiListBox, Root, 'Sections', 16, 114, 188, 318));
  FNavigation.ItemHeight:=30;
  for I:=0 to LAB_PAGE_COUNT - 1 do FNavigation.AddItem(PAGE_NAMES[I]);
  FNavigation.OnSelect:=Changed;
  FInstructions:=TGuiMemo(Place(TGuiMemo, Root, 'Checklist', 16, 448, 188, 276));
  FInstructions.ReadOnly:=True;
  FInstructions.Anchors:=[ganLeft, ganTop, ganBottom];
  FInstructions.LineHeight:=20;
  FLog:=TGuiMemo(Place(TGuiMemo, Root, 'Event log', 16, 740, 1248, 120));
  FLog.ReadOnly:=True;
  FLog.FontName:='mono';
  FLog.Anchors:=[ganLeft, ganRight, ganBottom];
  FStatus:=TGuiStatusBar(Place(TGuiStatusBar, Root, 'Status', 0, 872, 1280, 28));
  FStatus.Anchors:=[ganLeft, ganRight, ganBottom];
  BuildButtons;
  BuildText;
  BuildLists;
  BuildRanges;
  BuildLayout;
  BuildMenus;
  BuildDialogs;
  BuildRendering;
  BuildLifetime;
  BuildChecks;
end;

procedure TTestLab.BuildButtons;
var
  P: TGuiPanel;
  B: TGuiButton;
  R: TGuiRadioButton;
  Switch: TGuiToggleSwitch;
  CheckBox: TGuiCheckBox;
  DelayButton: TGuiDelayButton;
  I: Integer;
begin
  P:=MakePage(0, 'Buttons, state transitions, and activation', 'Mouse, Tab / Shift+Tab, Enter / Space. Disabled controls must never activate.', 1200);
  ButtonAt(P, 'Primary action', 20, 100).StyleClass:='Primary';
  B:=ButtonAt(P, 'Disabled button', 220, 100);
  B.Enabled:=False;
  Place(TGuiToggleButton, P, 'Toggle', 420, 100, 180, 34);
  TGuiCheckBox(Place(TGuiCheckBox, P, 'Checkbox', 640, 100, 220, 34)).Checked:=True;
  CheckBox:=TGuiCheckBox(Place(TGuiCheckBox,P,'Mixed state',680,198,240,34));
  CheckBox.AllowGrayed:=True;
  CheckBox.State:=gcbGrayed;
  CheckBox.OnChange:=Changed;
  CheckBox.Hint:='Three-state cycle: unchecked, mixed, checked. Space or Enter changes state.';
  LabelAt(P, 'Radio group: exactly one option should remain checked', 20, 160);
  for I:=0 to 2 do
  begin
    R:=TGuiRadioButton(Place(TGuiRadioButton, P, 'Option ' + IntToStr(I + 1), 20 + I * 220, 198, 200, 34));
    R.GroupName:='lab';
    R.Checked:=I = 0;
    R.OnChange:=Changed;
    R.Hint:='Arrow keys select the next option; Space/Enter keep it selected.';
  end;
  LabelAt(P, 'Icon placement and textured backgrounds', 20, 260);
  for I:=0 to 3 do
  begin
    B:=ButtonAt(P, 'Icon ' + IntToStr(I), 20 + I * 220, 304);
    SetBoundsHeight(B, 72);
    B.Icon:=FResources.ImageDrawable('atlas');
    B.IconSize:=GuiSize(20, 20);
    B.IconPlacement:=TGuiIconPlacement(I);
  end;
  Place(TGuiLinkLabel, P, 'Link label (logs only)', 20, 404, 310, 30);
  B:=TGuiButton(Place(TGuiRoundButton,P,'+',360,396,44,44));
  B.OnClick:=Action;
  B:=TGuiButton(Place(TGuiRoundButton,P,'Pill action',430,396,170,44));
  B.OnClick:=Action;
  B:=TGuiButton(Place(TGuiRoundButton,P,'',630,396,44,44));
  B.Icon:=GuiColorDrawable(GuiColor(90,200,160));
  B.OnClick:=Action;
  B.Hint:='Icon-only round button';
  B:=TGuiButton(Place(TGuiRoundButton,P,'Disabled',710,396,190,44));
  B.Enabled:=False;
  FStateTarget:=TGuiPanel(Place(TGuiPanel, P, 'State group', 20, 452, 600, 120));
  ButtonAt(FStateTarget, 'Child 1', 16, 24);
  ButtonAt(FStateTarget, 'Quiet action', 220, 24).StyleClass:='Quiet';
  SetBoundsWidth(ButtonAt(P, 'Enable / disable group', 660, 456, 10), 240);
  SetBoundsWidth(ButtonAt(P, 'Show / hide group', 660, 502, 11), 240);
  LabelAt(P, 'Alignment checks: odd/even heights, capitals, and descenders', 20, 610);
  for I:=0 to 3 do
  begin
    B:=ButtonAt(P, 'HAMBURG 123', 20 + I * 220, 654);
    SetBoundsHeight(B, 28 + I);
    LabelAt(P, IntToStr(28 + I) + ' px', 20 + I * 220, 692, 176).StyleClass:='Muted';
  end;
  ButtonAt(P, 'Apply', 20, 744);
  ButtonAt(P, 'Settings', 240, 744);
  ButtonAt(P, 'gyp / H', 460, 744);
  ButtonAt(P, 'Tab to see focus', 680, 744);
  FActivitySwitch:=TGuiToggleSwitch(Place(TGuiToggleSwitch,P,'Background activity',20,840,280,38));
  FActivitySwitch.Checked:=True;
  FActivitySwitch.OnChange:=Changed;
  Switch:=TGuiToggleSwitch(Place(TGuiToggleSwitch,P,'Disabled switch',340,840,280,38));
  Switch.Checked:=True;
  Switch.Enabled:=False;
  Switch:=TGuiToggleSwitch(Place(TGuiToggleSwitch,P,'Switch off',660,840,260,38));
  Switch.OnChange:=Changed;
  LabelAt(P,'Drag the thumb or click the caption. Space toggles; Left/Right choose a state.',20,894);
  LabelAt(P,'Hold to confirm. Release early or Escape cancels; next press resets a confirmed button.',20,944);
  DelayButton:=TGuiDelayButton(Place(TGuiDelayButton,P,'Hold 1.5s to confirm',20,986,280,44));
  DelayButton.Delay:=1500;
  DelayButton.OnActivated:=Changed;
  DelayButton.Hint:='Hold mouse, Space or Enter until the progress strip fills. Activation logs once.';
  DelayButton:=TGuiDelayButton(Place(TGuiDelayButton,P,'Confirmed / click to reset',340,986,280,44));
  DelayButton.Checked:=True;
  DelayButton.OnActivated:=Changed;
  DelayButton:=TGuiDelayButton(Place(TGuiDelayButton,P,'Disabled confirmation',660,986,260,44));
  DelayButton.Enabled:=False;
  B:=ButtonAt(P,'Hold to repeat',20,1090);
  B.AutoRepeat:=True;
  B.RepeatDelay:=400;
  B.RepeatInterval:=150;
  B.Hint:='Hold mouse, Space, Enter or gamepad confirm; each repeat logs an activation.';
  B:=ButtonAt(P,'Hold for alternate action',260,1090);
  B.PressAndHoldInterval:=900;
  B.Bounds:=GuiRect(260,1090,260,34);
  B.OnPressAndHold:=Changed;
  B.Hint:='A 900 ms mouse hold logs the alternate action and consumes the release click.';
end;

procedure TTestLab.BuildText;
var
  P: TGuiPanel;
  E: TGuiEdit;
  V: TGuiValueLabel;
  I: Integer;
begin
  P:=MakePage(1, 'Editing, Unicode, clipboard, and composition', 'Test selection, Ctrl+A/C/X/V/Z/Y, mouse dragging, emoji deletion, and your native IME.', 830);
  FEdit:=TGuiEdit(Place(TGuiEdit, P, 'Editable text', 20, 104, 620, 36));
  FEdit.Text:='Type here: abc 123';
  FEdit.OnChange:=Changed;
  FEdit.OnSubmit:=Changed;
  ButtonAt(P, 'Load Unicode sample', 700, 104, 20);
  for I:=0 to 2 do
  begin
    E:=TGuiEdit(Place(TGuiEdit, P, 'Edit variant ' + IntToStr(I), 20, 158 + I * 52, 620, 36));
    E.OnChange:=Changed;
    case I of
      0:
      begin
        E.Text:='Read-only: selection and copy are allowed';
        E.ReadOnly:=True;
      end;
      1:
      begin
        E.Text:='secret';
        E.PasswordChar:='*';
      end;
      2:
      begin
        E.MaxLength:=8;
        E.Placeholder:='Maximum 8 string units';
      end;
    end;
  end;
  ButtonAt(P, 'Undo', 700, 158, 21);
  ButtonAt(P, 'Redo', 700, 210, 22);
  ButtonAt(P, 'Select all', 700, 262, 23);
  FMemo:=TGuiMemo(Place(TGuiMemo, P, 'Multiline editor', 20, 326, 864, 230));
  FMemo.WordWrap:=True;
  FMemo.Text:='Editable wrapped memo' + #10 +
    'This is one long source line. Resize the window to reflow it, drag a selection across its visual rows, ' +
    'and try Home, End, Up and Down. Wrapping should never insert line breaks into the text you copy or undo.' + #10#10 +
    'Hard line breaks remain separate from wrapping. Ctrl+Home and Ctrl+End navigate the document; Shift extends selection.';
  FMemo.OnChange:=Changed;
  SetBoundsWidth(ButtonAt(P, 'Toggle memo wrapping', 650, 640, 24), 270);
  FMemo.Hint:='This multiline editor wraps at word boundaries. Hovering this long tooltip demonstrates the same layout helper, ' +
    'while the editor also maps selection, caret movement, scrolling, and undo back to the unchanged source text.';
  for I:=0 to 2 do
  begin
    LabelAt(P, 'Alignment sample', 20 + I * 300, 588, 270).TextHorizontalAlign:=TGuiHorizontalTextAlign(I);
  end;
  V:=TGuiValueLabel(Place(TGuiValueLabel, P, 'Value readout', 20, 640, 500, 42));
  V.ValueText:='42';
  V.UnitText:='units';
  LabelAt(P, 'Unicode input and grapheme-safe editing; native IME needs manual validation.', 20, 716);
  SetBoundsWidth(ButtonAt(P,'Simulate IME preview',20,758,27), 260);
  LabelAt(P,'Simulation only: Escape cancels. This is not a native IME test.',300,764,620);
end;

procedure TTestLab.BuildLists;
var
  P: TGuiPanel;
  L: TGuiListBox;
  Radio: TGuiRadioGroup;
  Checks: TGuiCheckListBox;
  Switches: TGuiSwitchListBox;
  Wheel: TGuiWheelPicker;
  C: TGuiComboBox;
  D: TGuiDropDownButton;
  T: TGuiTreeView;
  V: TGuiListView;
  H: TGuiHeaderControl;
  Item: TGuiItemTemplate;
  I: Integer;
begin
  P:=MakePage(2, 'Lists, trees, headers, and popups', 'Select the last item. Scroll with wheel / keyboard. Open a popup across another control.', 1600);
  L:=TGuiListBox(Place(TGuiListBox, P, 'ListBox / 20 items', 20, 102, 270, 194));
  L.OnSelect:=Changed;
  C:=TGuiComboBox(Place(TGuiComboBox, P, 'ComboBox / 20 items', 330, 104, 280, 36));
  C.OnSelect:=Changed;
  C.OnAccept:=ComboAccepted;
  C.DropDownCount:=4;
  C.Hint:='Type a label prefix to search; repeated letters cycle matches. ' +
    'F4 opens/closes, Enter accepts a popup preview, Escape cancels. Search resets after one second.';
  D:=TGuiDropDownButton(Place(TGuiDropDownButton, P, 'Dropdown / 20 items', 660, 104, 280, 36));
  D.OnSelect:=Changed;
  for I:=0 to 19 do
  begin
    L.AddItem('List item ' + IntToStr(I));
    C.AddItem('Combo item ' + IntToStr(I));
    D.AddItem('Action ' + IntToStr(I));
  end;
  L.SelectedIndex:=1;
  Place(TGuiComboBox, P, 'Empty combo', 330, 170, 280, 36);
  C:=TGuiComboBox(Place(TGuiComboBox, P, 'Single item combo', 660, 170, 280, 36));
  C.AddItem('Only choice');
  LabelAt(P, 'Headers: click to sort, drag dividers to resize. Ctrl/Shift selects rows.', 330, 228, 600);
  T:=TGuiTreeView(Place(TGuiTreeView, P, 'Tree', 20, 334, 300, 300));
  T.OnSelect:=Changed;
  for I:=0 to 7 do
  begin
    T.AddNode('Branch ' + IntToStr(I));
    T.AddNode('Child A', 1);
    T.AddNode('Child B', 1);
    T.AddNode('Grandchild', 2);
  end;
  T.SelectedIndex:=1;
  V:=TGuiListView(Place(TGuiListView, P, 'Table / 100 rows', 354, 334, 580, 300));
  V.OnSelect:=Changed;
  FTable:=V;
  V.AddColumn('Name', 270);
  V.AddColumn('Count', 100);
  V.AddColumn('State', 160);
  V.MultiSelect:=True;
  V.ColumnSortKind[1]:=gcskNumber;
  V.Hint:='Ctrl+A selects all; Shift+arrows extends selection; Ctrl+Space toggles. Alt+Left/Right chooses a header; Alt+Up/Down sorts it.';
  for I:=0 to 99 do V.AddRow(['Row ' + IntToStr(I), IntToStr(I * 3), 'Ready']);
  V.SelectedIndex:=1;
  H:=TGuiHeaderControl(Place(TGuiHeaderControl, P, 'Standalone header', 20, 668, 560, 34));
  H.AddColumn('Header A', 180);
  H.AddColumn('Header B', 180);
  H.AddColumn('Header C', 180);
  Item:=TGuiItemTemplate(Place(TGuiItemTemplate, P, 'Item template', 20, 738, 600, 72));
  Item.Title:='Selected inventory row';
  Item.Subtitle:='Icon / title / detail / swatch';
  Item.DetailText:='120';
  Item.Selected:=True;
  Item.ShowSwatch:=True;
  Item.SwatchColor:=GuiColor(220, 160, 80);
  Item.Icon:=FResources.ImageDrawable('atlas');
  Radio:=TGuiRadioGroup(Place(TGuiRadioGroup,P,'Radio options',650,668,284,142));
  for I:=0 to 11 do Radio.AddItem('Delivery option '+IntToStr(I+1));
  Radio.ItemIndex:=1;
  Radio.OnChange:=Changed;
  Radio.Hint:='Full-row exclusive options; arrows, Home/End, PageUp/PageDown, and wheel.';
  Checks:=TGuiCheckListBox(Place(TGuiCheckListBox,P,'Checklist / mixed and disabled rows',20,866,440,190));
  for I:=0 to 19 do Checks.AddItem('Feature '+IntToStr(I+1));
  Checks.Items[0]:='Enabled feature';
  Checks.Items[1]:='Partially enabled feature';
  Checks.Items[2]:='Locked feature (selectable, not toggleable)';
  Checks.Checked[0]:=True;
  Checks.State[1]:=gcbGrayed;
  Checks.Checked[2]:=True;
  Checks.ItemEnabled[2]:=False;
  Checks.AllowGrayed:=True;
  Checks.SelectedIndex:=1;
  Checks.OnSelect:=Changed;
  Checks.OnCheck:=ItemChecked;
  Checks.Hint:='Click a row or press Space/Enter to cycle its check state; arrows only select. Scroll to check more rows.';
  Switches:=TGuiSwitchListBox(Place(TGuiSwitchListBox,P,'Switch list / click or drag indicators',500,866,434,190));
  for I:=0 to 19 do Switches.AddItem('Setting '+IntToStr(I+1));
  Switches.Items[0]:='Notifications';
  Switches.Items[1]:='Background updates';
  Switches.Items[2]:='Managed setting (locked)';
  Switches.Checked[0]:=True;
  Switches.Checked[2]:=True;
  Switches.ItemEnabled[2]:=False;
  Switches.SelectedIndex:=1;
  Switches.OnSelect:=Changed;
  Switches.OnCheck:=ItemChecked;
  Switches.Hint:='Click row or Space/Enter to toggle; drag a switch to preview and release to commit. Left/Right sets off/on; Escape cancels.';
  LabelAt(P,'Hours / wraps',20,1110,160);
  Wheel:=TGuiWheelPicker(Place(TGuiWheelPicker,P,'Hours',20,1150,160,190));
  for I:=0 to 23 do Wheel.AddItem(Format('%.2d',[I]));
  Wheel.ItemIndex:=12;
  Wheel.OnChange:=Changed;
  Wheel.Hint:='Drag and release to flick. Wheel/arrows select, Escape stops motion.';
  LabelAt(P,'Minutes / wraps',210,1110,160);
  Wheel:=TGuiWheelPicker(Place(TGuiWheelPicker,P,'Minutes',210,1150,160,190));
  for I:=0 to 59 do Wheel.AddItem(Format('%.2d',[I]));
  Wheel.ItemIndex:=30;
  Wheel.OnChange:=Changed;
  LabelAt(P,'Quality / no wrap',400,1110,180);
  Wheel:=TGuiWheelPicker(Place(TGuiWheelPicker,P,'Quality',400,1150,180,190));
  Wheel.VisibleItemCount:=3;
  Wheel.Items.Text:='Low'+#10+'Medium'+#10+'High';
  Wheel.ItemIndex:=1;
  Wheel.Wrap:=False;
  Wheel.OnChange:=Changed;
  LabelAt(P,'Empty wheel',620,1110,140);
  Place(TGuiWheelPicker,P,'Empty wheel',620,1150,140,190);
  LabelAt(P,'Disabled / single',800,1110,160);
  Wheel:=TGuiWheelPicker(Place(TGuiWheelPicker,P,'Disabled wheel',800,1150,140,190));
  Wheel.AddItem('Locked');
  Wheel.Enabled:=False;
  LabelAt(P,'Editable combo: type a label or a custom value, then Enter',20,1410,680);
  FEditableCombo:=TGuiComboBox(Place(TGuiComboBox,P,'Editable sizes',20,1450,360,38));
  FEditableCombo.Items.Text:='Small'+#10+'Medium'+#10+'Large';
  FEditableCombo.SelectedIndex:=1;
  FEditableCombo.Editable:=True;
  FEditableCombo.AutoComplete:=True;
  FEditableCombo.OnSelect:=Changed;
  FEditableCombo.OnChange:=ComboTextChanged;
  FEditableCombo.OnAccept:=ComboAccepted;
  FEditableCombo.Hint:='Type sm, me or la to complete a label. The suffix is selected for replacement; ' +
    'Enter accepts and Escape restores. Custom values are not inserted into Items.';
  C:=TGuiComboBox(Place(TGuiComboBox,P,'Empty editable combo',420,1450,360,38));
  C.Editable:=True;
  C.Placeholder:='Type a custom value';
  C.OnChange:=ComboTextChanged;
  C.OnAccept:=ComboAccepted;
end;

procedure TTestLab.BuildRanges;
var
  P: TGuiPanel;
  S: TGuiSlider;
  Range: TGuiRangeSlider;
  B: TGuiScrollBar;
  Spin: TGuiSpinEdit;
  Progress: TGuiProgressBar;
  Activity: TGuiActivityIndicator;
  Knob: TGuiKnob;
  I: Integer;
begin
  P:=MakePage(3, 'Ranges, instruments, and animation',
    'Drag beyond bounds, use arrow keys, and verify min/max clamping. The main slider drives the gauges.', 1300);
  FSlider:=TGuiSlider(Place(TGuiSlider, P, 'Main range', 20, 112, 560, 36));
  FSlider.MinValue:=0;
  FSlider.MaxValue:=100;
  FSlider.Value:=45;
  FSlider.OnChange:=Changed;
  S:=TGuiSlider(Place(TGuiSlider, P, 'Vertical range', 630, 100, 34, 220));
  S.Orientation:=goVertical;
  S.OnChange:=Changed;
  Spin:=TGuiSpinEdit(Place(TGuiSpinEdit, P, 'Spin / step 5', 710, 106, 200, 36));
  Spin.MinValue:=-20;
  Spin.MaxValue:=120;
  Spin.Increment:=5;
  Spin.OnChange:=Changed;
  B:=TGuiScrollBar(Place(TGuiScrollBar, P, 'Horizontal scrollbar', 20, 180, 560, 28));
  B.Orientation:=goHorizontal;
  B.PageSize:=20;
  B.OnChange:=Changed;
  B:=TGuiScrollBar(Place(TGuiScrollBar, P, 'Vertical scrollbar', 942, 100, 24, 220));
  B.Orientation:=goVertical;
  B.OnChange:=Changed;
  FProgress:=TGuiProgressBar(Place(TGuiProgressBar, P, 'Progress', 20, 250, 560, 36));
  FProgress.ShowText:=True;
  FProgress.Value:=45;
  FProgress.SegmentCount:=10;
  FProgress.ShowTicks:=True;
  FProgress.ShowThreshold:=True;
  FProgress.ThresholdValue:=70;
  Progress:=TGuiProgressBar(Place(TGuiProgressBar, P, 'Reverse vertical', 710, 164, 72, 154));
  Progress.Value:=65;
  Progress.Orientation:=goVertical;
  Progress.Reverse:=True;
  S:=TGuiSlider(Place(TGuiSlider, P, 'Zero range', 20, 314, 300, 32));
  S.MinValue:=0;
  S.MaxValue:=0;
  Progress:=TGuiProgressBar(Place(TGuiProgressBar,P,'Indeterminate progress',350,314,230,24));
  Progress.Marquee:=True;
  Progress.Hint:='Unknown progress: animated marquee, no percentage.';
  S:=TGuiSlider(Place(TGuiSlider,P,'Release-only step slider',20,354,560,28));
  S.StepSize:=10;
  S.SnapMode:=gsmSnapOnRelease;
  S.Live:=False;
  S.OnChange:=Changed;
  S.Hint:='Steps of 10 on release. Value stays unchanged during drag; Escape cancels.';
  FDial:=TGuiDialGauge(Place(TGuiDialGauge, P, 'Dial', 20, 386, 340, 248));
  FDial.Value:=45;
  FDial.ShowValue:=True;
  FScope:=TGuiScope(Place(TGuiScope, P, 'Scope', 402, 386, 320, 248));
  FScope.ShowSweep:=True;
  for I:=0 to 7 do FScope.AddMarker(Cos(I) * 0.7, Sin(I) * 0.7, GuiColor(100, 230, 170), 5, IntToStr(I));
  ButtonAt(P, 'Pause / resume sweep', 754, 406, 30);
  ButtonAt(P, 'Set minimum', 754, 458, 31);
  ButtonAt(P, 'Set maximum', 754, 510, 32);
  Knob:=TGuiKnob(Place(TGuiKnob,P,'Stepped knob',754,566,80,80));
  Knob.StepSize:=10;
  Knob.SnapMode:=gsmSnapAlways;
  Knob.OnChange:=Changed;
  Knob.Hint:='Circular knob, steps of 10; arrows and wheel also work.';
  Knob:=TGuiKnob(Place(TGuiKnob,P,'Wrapping knob',850,566,80,80));
  Knob.Wrap:=True;
  Knob.OnChange:=Changed;
  Knob.OnWrapped:=KnobWrapped;
  Knob.Hint:='Wrapping circular knob; cross the lower gap to wrap.';
  Knob:=TGuiKnob(Place(TGuiKnob,P,'Horizontal drag knob',754,730,80,80));
  Knob.InputMode:=gkiHorizontal;
  Knob.SetAngles(180,360);
  Knob.OnChange:=Changed;
  Knob.Hint:='Horizontal relative drag; custom upper semicircle.';
  Knob:=TGuiKnob(Place(TGuiKnob,P,'Vertical drag knob',850,730,80,80));
  Knob.InputMode:=gkiVertical;
  Knob.Live:=False;
  Knob.OnChange:=Changed;
  Knob.Hint:='Vertical relative drag; value commits on release.';
  FActivity:=TGuiActivityIndicator(Place(TGuiActivityIndicator,P,'Activity indicator',20,680,40,40));
  LabelAt(P,'Background activity (switch on Buttons page)',80,686,500);
  Activity:=TGuiActivityIndicator(Place(TGuiActivityIndicator,P,'Disabled activity indicator',620,680,40,40));
  Activity.Enabled:=False;
  LabelAt(P,'Disabled / static',680,686,220);
  LabelAt(P,'Range selection: Tab visits both handles; Space switches the active handle.',20,864,870);
  Range:=TGuiRangeSlider(Place(TGuiRangeSlider,P,'Live interval',20,910,550,40));
  FRangeSlider:=Range;
  LabelAt(P,'Live interval',20,886,550);
  Range.OnChange:=Changed;
  Range.OnMoved:=RangeMoved;
  Range.Hint:='Drag either handle; they cannot cross. Arrows, Home/End and wheel adjust the active endpoint.';
  Range:=TGuiRangeSlider(Place(TGuiRangeSlider,P,'Deferred interval / step 10',20,980,550,40));
  LabelAt(P,'Deferred interval / step 10',20,956,550);
  Range.Live:=False;
  Range.StepSize:=10;
  Range.SnapMode:=gsmSnapOnRelease;
  Range.OnChange:=Changed;
  Range.OnMoved:=RangeMoved;
  Range.Hint:='Continuous preview; values commit in steps of 10 on release. Escape cancels.';
  Range:=TGuiRangeSlider(Place(TGuiRangeSlider,P,'Disabled interval',20,1050,550,40));
  Range.Enabled:=False;
  LabelAt(P,'Disabled interval',20,1026,550);
  LabelAt(P,'Vertical',630,886,110);
  Range:=TGuiRangeSlider(Place(TGuiRangeSlider,P,'Vertical interval',650,910,40,180));
  Range.Orientation:=goVertical;
  Range.OnChange:=Changed;
  Range.OnMoved:=RangeMoved;
  Range:=TGuiRangeSlider(Place(TGuiRangeSlider,P,'Coincident endpoints',750,940,180,40));
  Range.SetValues(50,50);
  LabelAt(P,'Coincident endpoints',750,910,220);
  Range.OnChange:=Changed;
  Range.OnMoved:=RangeMoved;
  Range.Hint:='Overlapping handles: grab either side or use Tab to separate them.';
  LabelAt(P,'Type and Enter / Escape',20,1160,240);
  FSpinEditor:=TGuiSpinEdit(Place(TGuiSpinEdit,P,'Deferred numeric input',20,1200,220,38));
  FSpinEditor.MinValue:=-100;
  FSpinEditor.Value:=42;
  FSpinEditor.OnChange:=Changed;
  FSpinEditor.OnValueModified:=SpinValueModified;
  FSpinEditor.Hint:='Type a signed integer. Enter or focus loss commits; Escape restores. ' +
    'Hold either arrow to repeat after 400 ms; moving off the arrow cancels.';
  LabelAt(P,'Live numeric input',280,1160,220);
  Spin:=TGuiSpinEdit(Place(TGuiSpinEdit,P,'Live numeric input',280,1200,220,38));
  Spin.MinValue:=-100;
  Spin.Live:=True;
  Spin.Value:=25;
  Spin.OnChange:=Changed;
  Spin.OnValueModified:=SpinValueModified;
  LabelAt(P,'Single-click only',540,1160,180);
  Spin:=TGuiSpinEdit(Place(TGuiSpinEdit,P,'Stepping only',540,1200,180,38));
  Spin.Editable:=False;
  Spin.AutoRepeat:=False;
  Spin.Value:=50;
  Spin.OnChange:=Changed;
  Spin.OnValueModified:=SpinValueModified;
  Spin.Hint:='Noneditable and AutoRepeat=False: one step per click, with ordinary keyboard/wheel stepping.';
  LabelAt(P,'Wrapping 0..9',760,1160,180);
  Spin:=TGuiSpinEdit(Place(TGuiSpinEdit,P,'Wrapping digits',760,1200,180,38));
  Spin.MaxValue:=9;
  Spin.Value:=9;
  Spin.Wrap:=True;
  Spin.OnChange:=Changed;
  Spin.OnValueModified:=SpinValueModified;
  Spin.RepeatDelay:=250;
  Spin.RepeatInterval:=150;
  Spin.Hint:='Hold an arrow to wrap digits. Custom repeat: 250 ms delay, 150 ms interval.';
end;

procedure TTestLab.BuildLayout;
var
  P, Dock, Target: TGuiPanel;
  Stack: TGuiStackPanel;
  Grid: TGuiGridPanel;
  Scroll: TGuiScrollBox;
  CompareMemo: TGuiMemo;
  CompareTree: TGuiTreeView;
  CompareList: TGuiListView;
  Frame: TGuiFrame;
  Splitter: TGuiSplitter;
  C: TGuiControl;
  I: Integer;
begin
  P:=MakePage(4, 'Layout, clipping, anchors, and scrolling',
    'Resize the window; scroll in both directions; drag the splitter; inspect docked child alignment.', 1320);
  Dock:=TGuiPanel(Place(TGuiPanel, P, 'Nested dock panel', 20, 108, 460, 250));
  Dock.Padding:=GuiBox(12);
  C:=Place(TGuiLabel, Dock, 'Top / margin', 0, 0, 100, 38);
  C.Align:=gaTop;
  C.Margin:=GuiBox(4);
  C:=Place(TGuiPanel, Dock, 'Left dock', 0, 0, 96, 40);
  C.Align:=gaLeft;
  LabelAt(C, 'Left', 8, 8, 80);
  C:=Place(TGuiButton, Dock, 'Client fill', 0, 0, 100, 30);
  C.Align:=gaClient;
  C.Margin:=GuiBox(6);
  Frame:=TGuiFrame(Place(TGuiFrame, P, 'Frame', 514, 108, 450, 250));
  Frame.Title:='Header + footer frame';
  Frame.ShowFooter:=True;
  ButtonAt(Frame, 'Anchored child', 220, 174).Anchors:=[ganRight, ganBottom];
  Stack:=TGuiStackPanel(Place(TGuiStackPanel, P, 'Vertical stack', 20, 394, 290, 140));
  Stack.Spacing:=8;
  Stack.AutoSizeToContent:=False;
  for I:=0 to 2 do ButtonAt(Stack, 'Stack ' + IntToStr(I), 0, 0);
  Grid:=TGuiGridPanel(Place(TGuiGridPanel, P, 'Grid', 352, 394, 600, 140));
  Grid.Columns:=3;
  Grid.CellWidth:=180;
  Grid.CellHeight:=48;
  Grid.ColumnSpacing:=8;
  Grid.RowSpacing:=8;
  for I:=0 to 5 do ButtonAt(Grid, 'Cell ' + IntToStr(I), 0, 0);
  Scroll:=TGuiScrollBox(Place(TGuiScrollBox, P, 'Both-axis scrolling', 20, 564, 460, 250));
  for I:=0 to 23 do ButtonAt(Scroll, 'Scrollable ' + IntToStr(I), 12 + (I MOD 4) * 200, 12 + (I DIV 4) * 70);
  Target:=TGuiPanel(Place(TGuiPanel, P, 'Splitter target', 516, 564, 200, 250));
  Target.MinWidth:=100;
  Target.MaxWidth:=390;
  LabelAt(Target, 'Drag the divider', 10, 10, 180);
  Splitter:=TGuiSplitter(Place(TGuiSplitter, P, 'Splitter', 722, 564, 12, 250));
  Splitter.Orientation:=goVertical;
  Splitter.TargetControl:=Target;
  Splitter.OnMoved:=Changed;
  Place(TGuiGroupBox, P, 'Group box', 20, 852, 230, 90);
  C:=Place(TGuiTransparentPanel, P, 'Transparent panel', 276, 852, 250, 90);
  LabelAt(C, 'Transparent panel', 8, 18, 230);
  Stack:=TGuiTransparentStackPanel(Place(TGuiTransparentStackPanel, P, 'Transparent stack', 560, 852, 400, 90));
  Stack.Orientation:=goHorizontal;
  Stack.AutoSizeToContent:=False;
  ButtonAt(Stack, 'A', 0, 0);
  ButtonAt(Stack, 'B', 0, 0);
  // Base classes have explicit samples as well as their derived controls.
  Place(TGuiContainer, P, 'Base container', 970, 100, 20, 20);
  C:=Place(TGuiControl, P, 'Base control', 970, 130, 20, 20);
  C.BackgroundColor:=GuiColor(200, 120, 80);
  LabelAt(P, 'Scrollbar geometry: same outer height, shared edge insets; table starts below its header', 20, 980);
  LabelAt(P, 'Scroll box', 20, 1020, 216);
  LabelAt(P, 'Memo', 260, 1020, 216);
  LabelAt(P, 'Tree view', 500, 1020, 216);
  LabelAt(P, 'List view', 740, 1020, 216);
  Scroll:=TGuiScrollBox(Place(TGuiScrollBox, P, 'Geometry scroll box', 20, 1060, 216, 210));
  CompareMemo:=TGuiMemo(Place(TGuiMemo, P, 'Geometry memo', 260, 1060, 216, 210));
  CompareMemo.ReadOnly:=True;
  CompareTree:=TGuiTreeView(Place(TGuiTreeView, P, 'Geometry tree', 500, 1060, 216, 210));
  CompareList:=TGuiListView(Place(TGuiListView, P, 'Geometry list', 740, 1060, 216, 210));
  CompareList.AddColumn('Rows', 176);
  for I:=0 to 19 do
  begin
    LabelAt(Scroll, 'Row ' + IntToStr(I), 8, 4 + I * 28, 180);
    CompareMemo.AddLine('Row ' + IntToStr(I));
    CompareTree.AddNode('Row ' + IntToStr(I));
    CompareList.AddRow(['Row ' + IntToStr(I)]);
  end;
end;

procedure TTestLab.BuildMenus;
var
  P: TGuiPanel;
  Pages: TGuiPageControl;
  Page: TGuiPage;
  Tabs: TGuiTabControl;
  Menu: TGuiMenuBar;
  RootMenu, SubMenu, Entry: TGuiMenuItem;
  Popup: TGuiPopupMenu;
  Toolbar: TGuiToolBar;
  Speed: TGuiSpeedButton;
  TabButton: TGuiTabButton;
  Sep: TGuiSeparator;
  Command: TGuiCommandBar;
  I: Integer;
begin
  P:=MakePage(5, 'Pages, menus, and command bars', 'Alt+F / F10 opens menus; Ctrl+S logs Save. Right-click this page for context actions.', 820);
  Menu:=TGuiMenuBar(Place(TGuiMenuBar, P, 'Menu bar', 20, 104, 930, 32));
  FLabMenu:=Menu;
  RootMenu:=Menu.AddMenu('&File');
  RootMenu.Add('&New document', MenuCommand);
  SubMenu:=RootMenu.Add('&Recent files');
  SubMenu.Add('Example project', MenuCommand);
  SubMenu.Add('Style test', MenuCommand);
  SubMenu:=SubMenu.Add('More examples');
  SubMenu.Add('Nested command', MenuCommand);
  RootMenu.AddSeparator;
  Entry:=RootMenu.Add('&Save', MenuCommand);
  Entry.ShortcutKey:=Ord('s');
  Entry.ShortcutModifiers:=[gemCtrl];
  RootMenu.Add('Unavailable command', MenuCommand).Enabled:=False;
  RootMenu:=Menu.AddMenu('&Edit');
  RootMenu.Add('Undo', MenuCommand);
  RootMenu.Add('Redo', MenuCommand);
  RootMenu:=Menu.AddMenu('&View');
  Entry:=RootMenu.Add('Show guides', MenuCommand);
  Entry.AutoCheck:=True;
  Entry.Checked:=True;
  RootMenu:=Menu.AddMenu('&Help');
  RootMenu.Add('&About this lab', MenuCommand);
  Menu.OnSelect:=Changed;
  Popup:=TGuiPopupMenu.Create;
  P.Add(Popup);
  P.PopupMenu:=Popup;
  FLabPopup:=Popup;
  Popup.Menu.Add('&Inspect selection', MenuCommand);
  Popup.Menu.Add('A longer command caption with automatic menu sizing', MenuCommand);
  Popup.Menu.AddSeparator;
  Entry:=Popup.Menu.Add('Show &guides', MenuCommand);
  Entry.AutoCheck:=True;
  Popup.Menu.Add('Unavailable', MenuCommand).Enabled:=False;
  Popup.Menu.Add('More actions').Add('Nested context command', MenuCommand);
  Toolbar:=TGuiToolBar(Place(TGuiToolBar, P, 'Toolbar', 20, 156, 930, 48));
  ButtonAt(Toolbar, 'New', 0, 0);
  ButtonAt(Toolbar, 'Save', 0, 0);
  ButtonAt(Toolbar, 'Inspect', 0, 0);
  Sep:=TGuiSeparator(Place(TGuiSeparator,Toolbar,'Toolbar separator',0,0,12,32));
  Sep.Orientation:=goVertical;
  Speed:=TGuiSpeedButton(Place(TGuiSpeedButton,Toolbar,'Grid',0,0,68,32));
  Speed.GroupIndex:=1;
  Speed.Down:=True;
  Speed.OnChange:=Changed;
  Speed:=TGuiSpeedButton(Place(TGuiSpeedButton,Toolbar,'List',0,0,68,32));
  Speed.GroupIndex:=1;
  Speed.OnChange:=Changed;
  Speed:=TGuiSpeedButton(Place(TGuiSpeedButton,Toolbar,'',0,0,32,32));
  Speed.Icon:=GuiColorDrawable(GuiColor(90,200,160));
  Speed.Checkable:=True;
  Speed.Hint:='Icon-only toggle';
  Speed.OnChange:=Changed;
  TGuiEdit(Place(TGuiEdit,Toolbar,'Toolbar search',0,0,150,32)).Placeholder:='Search...';
  Tabs:=TGuiTabControl(Place(TGuiTabControl, P, 'Standalone tabs', 20, 226, 450, 38));
  for I:=0 to 3 do Tabs.AddTab('Tab ' + IntToStr(I + 1));
  Tabs.OnSelect:=Changed;
  Tabs.Items[1]:='Disabled';
  Tabs.TabEnabled[1]:=False;
  Tabs.MinTabWidth:=140;
  Tabs.Hint:='Drag/flick the strip, or use end arrows and the wheel. A click selects on release; keyboard selection reveals its tab.';
  for I:=0 to 2 do
  begin
    TabButton:=TGuiTabButton(Place(TGuiTabButton,P,'View '+IntToStr(I+1),500+I*150,226,150,38));
    TabButton.OnChange:=Changed;
    TabButton.Down:=I=0;
    TabButton.Enabled:=I<>2;
    if I=0 then TabButton.Icon:=GuiColorDrawable(GuiColor(90,200,160));
    TabButton.Hint:='Standalone icon-capable tab; arrow keys select peers.';
  end;
  Pages:=TGuiPageControl(Place(TGuiPageControl, P, 'Page control', 20, 286, 930, 224));
  Pages.OnSelect:=Changed;
  FLabPages:=Pages;
  for I:=0 to 2 do
  begin
    Page:=Pages.AddPage('Page ' + IntToStr(I + 1));
    LabelAt(Page, 'Only this page should accept focus.', 16, 14, 800);
    ButtonAt(Page, 'Page action ' + IntToStr(I + 1), 16, 62);
    TGuiEdit(Place(TGuiEdit, Page, 'Page edit ' + IntToStr(I + 1), 260, 62, 360, 36)).Placeholder:='Focusable text input';
  end;
  FPageIndicator:=TGuiPageIndicator(Place(TGuiPageIndicator,P,'Page indicator',20,512,260,28));
  FPageIndicator.Count:=Pages.PageCount;
  FPageIndicator.SelectedIndex:=Pages.SelectedIndex;
  FPageIndicator.Interactive:=True;
  FPageIndicator.OnSelect:=Changed;
  LabelAt(P,'Dots follow tabs; click or use arrows, Home/End and wheel.',320,512,620);
  Command:=TGuiCommandBar(Place(TGuiCommandBar, P, 'Command bar', 20, 546, 930, 48));
  Command.Title:='Commands';
  Command.ShowSectionSeparators:=True;
  ButtonAt(Command, 'Run', 0, 0);
  ButtonAt(Command, 'Stop', 0, 0);
  Place(TGuiSeparator, P, 'Separator', 20, 610, 930, 6);
  Place(TGuiStatusBar, P, 'Embedded status bar / resize grip', 20, 644, 930, 32);
  Tabs:=TGuiTabControl(Place(TGuiTabControl,P,'Bottom tabs',20,696,600,100));
  Tabs.TabPosition:=gtpBottom;
  Tabs.AutoSizeTabs:=True;
  Tabs.AddTab('Overview');
  Tabs.AddTab('Details');
  Tabs.AddTab('Unavailable');
  Tabs.AddTab('Change history and revisions');
  Tabs.ItemWidths[1]:=160;
  Tabs.TabEnabled[2]:=False;
  Tabs.OnSelect:=Changed;
  LabelAt(Tabs,'Content-sized tabs; Details has an explicit 160-unit width.',12,12,560);
end;

procedure TTestLab.BuildDialogs;
var
  P: TGuiPanel;
  Dialog, Preview: TGuiDialog;
  Overlay: TGuiModalOverlay;
begin
  P:=MakePage(6, 'Dialogs, modal focus, and rendering layers',
    'Open a modal; verify background input is blocked; test Enter / Escape and nested modal closure.', 700);
  ButtonAt(P, 'Open modal', 20, 108, 40);
  ButtonAt(P, 'Nested modals', 236, 108, 41);
  ButtonAt(P, 'Open non-modal', 452, 108, 42);
  ButtonAt(P, 'Toggle debug layer', 668, 108, 43);
  Dialog:=TGuiDialog(Place(TGuiDialog, P, 'Embedded dialog', 20, 190, 440, 250));
  Dialog.Title:='Non-modal preview';
  Dialog.MessageText:='Buttons log their result.';
  Dialog.AddButton('OK', True, gmrOk);
  Dialog.AddButton('Cancel', False, gmrCancel);
  Dialog.OnClose:=Changed;
  Preview:=TGuiDialog.Create;
  Preview.Bounds:=GuiRect(0, 0, 370, 190);
  Preview.Title:='Overlay preview';
  Preview.MessageText:='The surrounding region is dimmed.';
  Overlay:=TGuiModalOverlay.CreateWithDialog(Preview);
  Overlay.Bounds:=GuiRect(500, 190, 460, 250);
  P.Add(Overlay);
  LabelAt(P, 'The preview is not modal. Use the buttons above to test actual input capture.', 20, 486);
  LabelAt(P, 'While dragging another control: release outside the window, switch apps, then return.', 20, 526);
  LabelAt(P, 'With a gamepad: D-pad navigates, south button activates; unplug during interaction.', 20, 566);
  ButtonAt(P, 'Open fixed window', 20, 612, 44);
  ButtonAt(P, 'Open movable window', 270, 612, 45);
  ButtonAt(P, 'Titleless window', 520, 612, 46);
  ButtonAt(P, 'Resize only', 770, 612, 47);
end;

procedure TTestLab.BuildRendering;
var
  P: TGuiPanel;
  Icon: TGuiIcon;
  B: TGuiButton;
  I: Integer;
begin
  P:=MakePage(7, 'Rendering, resources, fonts, and theme files',
    'Inspect clipping, alpha, lines, image fit, and text alignment under both themes and each font.', 840);
  TGuiImage(Place(TGuiImage, P, 'Image', 20, 108, 128, 100)).Texture:=FAtlas;
  for I:=0 to 2 do
  begin
    Icon:=TGuiIcon(Place(TGuiIcon, P, 'Fit ' + IntToStr(I), 220 + I * 220, 108, 180, 100));
    Icon.Drawable:=FResources.ImageDrawable('atlas');
    Icon.Fit:=TGuiImageFit(I);
    LabelAt(P, 'Fit mode ' + IntToStr(I), 220 + I * 220, 222, 180);
  end;
  B:=ButtonAt(P, 'Nine-slice skin', 20, 270);
  B.Name:='Nine-slice skin';
  SetBoundsWidth(B, 380);
  SetBoundsHeight(B, 72);
  Place(TCanvasSample, P, 'Canvas primitives', 450, 270, 470, 154);
  LabelAt(P, 'Nested clip rectangles must stay inside their borders.', 450, 438, 500);
  LabelAt(P, 'Body font: 0123456789 AaBbCc', 20, 476).FontName:='body';
  LabelAt(P, 'Monospace: 0123456789 AaBbCc', 20, 518).FontName:='mono';
  LabelAt(P, 'Large font: 0123456789 AaBbCc', 20, 560).FontName:='large';
  ButtonAt(P, 'Theme INI roundtrip', 20, 620, 50);
  ButtonAt(P, 'Clear font caches', 236, 620, 51);
  ButtonAt(P, 'Toggle logical size', 452, 620, 52);
  LabelAt(P, 'Logical presentation switches to a 1280 x 900 canvas. Resize to test letterboxing and hit testing.', 20, 678);
  LabelAt(P, 'PNG / image loading is not needed: this atlas is generated by SDL at startup.', 20, 720);
end;

procedure TTestLab.BuildLifetime;
var
  P: TGuiPanel;
  Scroll: TGuiScrollBox;
begin
  P:=MakePage(8, 'Dynamic ownership, focus, and stress',
    'Create / clear controls repeatedly, focus a generated item, then remove it. Inspect log and timing.', 740);
  FCount:=TGuiSpinEdit(Place(TGuiSpinEdit, P, 'Generated count', 20, 104, 170, 36));
  FCount.MinValue:=1;
  FCount.MaxValue:=1000;
  FCount.Value:=100;
  FCount.Increment:=25;
  ButtonAt(P, 'Create controls', 220, 104, 60);
  ButtonAt(P, 'Clear controls', 436, 104, 61);
  ButtonAt(P, 'Focus then remove', 652, 104, 62);
  ButtonAt(P, 'Window 1000 x 760', 20, 160, 63);
  ButtonAt(P, 'Window 1280 x 900', 236, 160, 64);
  Scroll:=TGuiScrollBox(Place(TGuiScrollBox, P, 'Generated scroll area', 20, 226, 936, 300));
  FDynamic:=TGuiGridPanel(Place(TGuiGridPanel, Scroll, 'Generated grid', 0, 0, 900, 10));
  FDynamic.Columns:=4;
  FDynamic.CellWidth:=210;
  FDynamic.CellHeight:=42;
  FDynamic.ColumnSpacing:=8;
  FDynamic.RowSpacing:=8;
  LabelAt(P, 'Actions are deferred until event dispatch ends, so the harness does not free the event sender.', 20, 564);
  LabelAt(P, 'Stress is bounded to 1,000 controls. Rendering timings are observational, not performance assertions.', 20, 608);
end;

procedure TTestLab.BuildChecks;
var
  P: TGuiPanel;
begin
  P:=MakePage(9, 'Automated checks and human observations',
    'Run checks, review PASS / FAIL output, and export the report. Manual sections start as NOT RUN.', 1260);
  ButtonAt(P, 'Run all checks', 20, 104, 1);
  ButtonAt(P, 'Export report', 236, 104, 2);
  ButtonAt(P, 'Load XML sample', 452, 104, 70);
  FResults:=TGuiMemo(Place(TGuiMemo, P, 'Check results', 20, 164, 936, 398));
  FResults.ReadOnly:=True;
  FResults.FontName:='mono';
  FXmlParent:=TGuiPanel(Place(TGuiPanel, P, 'XML sample area', 20, 594, 936, 220));
  LabelAt(P, 'XML is Delphi-only. Unsupported functionality is reported as SKIP, never as PASS.', 20, 846);
  LabelAt(P, 'Use -self-test for an unattended run; -report=path writes its report; -capture-dir=path saves page BMPs.', 20, 886);
  LabelAt(P, 'Manual notes (included in the report): OS, input method, controller, reproduction steps', 20, 950);
  FNotes:=TGuiMemo(Place(TGuiMemo, P, 'Manual notes', 20, 992, 936, 200));
end;

procedure TTestLab.CreateAtlas;
var
  OldTarget: PSDL_Texture;
  Rect: TSDL_FRect;
  I: Integer;
begin
  FAtlas:=SDL_CreateTexture(FRenderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, 64, 64);
  if NOT Assigned(FAtlas) then raise Exception.Create(String(SDL_GetError));
  OldTarget:=SDL_GetRenderTarget(FRenderer);
  if NOT SDL_SetRenderTarget(FRenderer, FAtlas) then raise Exception.Create(String(SDL_GetError));
  try
    SDL_SetRenderDrawColor(FRenderer, 45, 75, 98, 255);
    SDL_RenderClear(FRenderer);
    for I:=0 to 3 do
    begin
      SDL_SetRenderDrawColor(FRenderer, 80 + I * 40, 210 - I * 25, 160, 255);
      Rect.x:=8 + (I MOD 2) * 26;
      Rect.y:=8 + (I DIV 2) * 26;
      Rect.w:=22;
      Rect.h:=22;
      SDL_RenderFillRect(FRenderer, @Rect);
    end;
    SDL_SetRenderDrawColor(FRenderer, 160, 235, 215, 255);
    Rect.x:=0;
    Rect.y:=0;
    Rect.w:=64;
    Rect.h:=64;
    SDL_RenderRect(FRenderer, @Rect);
  finally
    SDL_SetRenderTarget(FRenderer, OldTarget);
  end;
  FResources.RegisterRegion('atlas', FAtlas, GuiRect(0, 0, 64, 64));
end;

procedure TTestLab.Log(const AText: String);
begin
  if FQuiet then Exit;
  if Assigned(FLog) then
  begin
    FLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + AText);
    while FLog.Lines.Count > 120 do FLog.Lines.Delete(0);
    FLog.ScrollY:=FLog.MaxScrollY;
  end;
end;

procedure TTestLab.MenuCommand(Sender: TObject);
begin
  Log('Menu command: ' + TGuiMenuItem(Sender).Caption);
end;

procedure TTestLab.KnobWrapped(Sender: TGuiControl; ADirection: TGuiWrapDirection);
begin
  if ADirection=gwdClockwise then Log(Sender.Name+' wrapped clockwise')
  else Log(Sender.Name+' wrapped counterclockwise');
end;

procedure TTestLab.ItemChecked(Sender: TGuiControl; AIndex: Integer);
begin
  Log(Format('%s row %d check state=%d',[Sender.Name,AIndex,Ord(TGuiCheckListBox(Sender).State[AIndex])]));
end;

procedure TTestLab.RangeMoved(Sender: TGuiControl; AThumb: TGuiRangeThumb);
begin
  Log(Format('%s thumb %d preview=%.2f',[Sender.Name,Ord(AThumb),TGuiRangeSlider(Sender).PreviewValue[AThumb]]));
end;

procedure TTestLab.ComboAccepted(Sender: TGuiControl);
begin
  Log('Accepted ['+Sender.Name+'] index='+IntToStr(TGuiComboBox(Sender).SelectedIndex)+' text='+TGuiComboBox(Sender).Text);
end;

procedure TTestLab.ComboTextChanged(Sender: TGuiControl);
begin
  Log('Draft ['+Sender.Name+'] '+TGuiComboBox(Sender).Text);
end;

procedure TTestLab.SpinValueModified(Sender: TGuiControl);
begin
  Log('User modified ['+Sender.Name+'] value='+IntToStr(TGuiSpinEdit(Sender).Value));
end;

procedure TTestLab.Changed(Sender: TGuiControl);
var
  Value: String;
begin
  if Sender = FNavigation then
  begin
    SelectPage(FNavigation.SelectedIndex);
    Exit;
  end;
  if Sender = FThemeSelect then
  begin
    FReactor:=FThemeSelect.SelectedIndex = 1;
    ApplyTheme;
    Exit;
  end;
  if Sender = FFontSelect then
  begin
    if FFontSelect.SelectedIndex >= 0 then FFonts.DefaultFont:=FFonts.FindFont(FFontSelect.Items[FFontSelect.SelectedIndex]);
    Log('Default font changed; observe alignment and caret placement.');
    Exit;
  end;
  Value:='';
  if Sender IS TGuiDelayButton then Value:=' confirmed='+BoolToStr(TGuiDelayButton(Sender).Checked,True);
  if Sender IS TGuiRadioButton then Value:=' checked='+BoolToStr(TGuiRadioButton(Sender).Checked,True);
  if Sender IS TGuiSpeedButton then Value:=' down='+BoolToStr(TGuiSpeedButton(Sender).Down,True);
  if (Sender=FLabPages) AND Assigned(FPageIndicator) then FPageIndicator.SelectedIndex:=FLabPages.SelectedIndex;
  if (Sender=FPageIndicator) AND Assigned(FLabPages) then FLabPages.SelectedIndex:=FPageIndicator.SelectedIndex;
  if Sender IS TGuiPageIndicator then Value:=' index='+IntToStr(TGuiPageIndicator(Sender).SelectedIndex);
  if Sender IS TGuiEdit then Value:=' length=' + IntToStr(Length(TGuiEdit(Sender).Text));
  if Sender IS TGuiSpinEdit then Value:=' value='+IntToStr(TGuiSpinEdit(Sender).Value);
  if Sender IS TGuiComboBox then Value:=' index=' + IntToStr(TGuiComboBox(Sender).SelectedIndex);
  if Sender IS TGuiListView then Value:=' row=' + IntToStr(TGuiListView(Sender).SelectedIndex);
  if Sender IS TGuiListBox then Value:=' index=' + IntToStr(TGuiListBox(Sender).SelectedIndex);
  if Sender IS TGuiSlider then Value:=' value=' + FloatToStr(TGuiSlider(Sender).Value);
  if Sender IS TGuiWheelPicker then Value:=' item='+IntToStr(TGuiWheelPicker(Sender).ItemIndex);
  if Sender IS TGuiRangeSlider then Value:=Format(' interval=%.2f..%.2f',
    [TGuiRangeSlider(Sender).LowerValue,TGuiRangeSlider(Sender).UpperValue]);
  if Sender IS TGuiCheckBox then Value:=' checked=' + BoolToStr(TGuiCheckBox(Sender).Checked, True);
  if Sender IS TGuiToggleSwitch then Value:=' checked='+BoolToStr(TGuiToggleSwitch(Sender).Checked,True);
  if (Sender=FActivitySwitch) AND Assigned(FActivity) then FActivity.Animate:=FActivitySwitch.Checked;
  if Sender = FSlider then
  begin
    FProgress.Value:=FSlider.Value;
    FDial.Value:=FSlider.Value;
  end;
  Log(Sender.ClassName + ' [' + Sender.Name + ']' + Value);
end;

procedure TTestLab.Action(Sender: TGuiControl);
begin
  FPending:=Sender.Tag;
end;

procedure TTestLab.FocusChanged(Sender: TObject; OldControl, NewControl: TGuiControl);
begin
  if Assigned(NewControl) then Log('Focus -> ' + NewControl.Name) else Log('Focus cleared');
end;

procedure TTestLab.SelectPage(AIndex: Integer);
var
  I: Integer;
  Lines: String;
begin
  if (AIndex < 0) OR (AIndex >= LAB_PAGE_COUNT) OR (FCurrentPage = AIndex) then Exit;
  FHost.Context.CancelInput;
  for I:=0 to LAB_PAGE_COUNT - 1 do
  begin
    FPages[I].ClosePopups(nil);
    FPages[I].Visible:=I = AIndex;
  end;
  FCurrentPage:=AIndex;
  FNavigation.SelectedIndex:=AIndex;
  Lines:='MANUAL CHECKLIST' + #10 + #10 + 'State: ' + FManual[AIndex] + #10 + #10;
  case AIndex of
    0: Lines:=Lines + 'Click / release' + #10 + 'Drag outside' + #10 + 'Tab / Shift+Tab' + #10 +
      'Space / Enter' + #10 + 'Disabled parent' + #10 + 'Hidden parent' + #10 + 'Radio exclusivity';
    1: Lines:=Lines + 'Select / drag' + #10 + 'Clipboard' + #10 + 'Undo / redo' + #10 + 'Read-only' + #10 +
      'Password masking' + #10 + 'Emoji deletion' + #10 + 'Native IME' + #10 + 'Multiline selection';
    2: Lines:=Lines + 'Empty / one item' + #10 + 'Last item' + #10 + 'Popup wheel' + #10 +
      'Keyboard arrows' + #10 + 'Expand / collapse' + #10 + 'Table scrolling';
    3: Lines:=Lines + 'Min / max' + #10 + 'Zero range' + #10 + 'Horizontal drag' + #10 +
      'Vertical drag' + #10 + 'Keyboard arrows' + #10 + 'Gauge labels' + #10 + 'Sweep animation';
    4: Lines:=Lines + 'Resize window' + #10 + 'Nested docking' + #10 + 'Anchors / margins' + #10 +
      'Both scroll axes' + #10 + 'Shift+wheel' + #10 + 'Drag splitter';
    5: Lines:=Lines + 'Page switching' + #10 + 'Focus skips pages' + #10 + 'Tab arrow keys' + #10 + 'Menu selection' + #10 + 'Toolbar actions';
    6: Lines:=Lines + 'Background blocked' + #10 + 'Enter / Escape' + #10 + 'Nested modals' + #10 +
      'Non-modal close' + #10 + 'Layer ordering' + #10 + 'App focus loss' + #10 + 'Gamepad hotplug';
    7: Lines:=Lines + 'Both themes' + #10 + 'Each font' + #10 + 'Nested clipping' + #10 +
      'Alpha blending' + #10 + 'Image fit modes' + #10 + 'Nine-slice border' + #10 + 'Logical sizing';
    8: Lines:=Lines + 'Create 100 / 1000' + #10 + 'Clear repeatedly' + #10 + 'Focus + remove' + #10 + 'Resize under load' + #10 + 'Watch event log';
    9: Lines:=Lines + 'Run checks' + #10 + 'Inspect failures' + #10 + 'Export report' + #10 + 'XML (Delphi)' + #10 + 'Manual != auto';
  end;
  FInstructions.Text:=Lines;
  Log('Section: ' + PAGE_NAMES[AIndex]);
end;

procedure TTestLab.ApplyTheme;
var
  Theme: TGuiTheme;
  Layer: TGuiLayerKind;
  procedure Skin(AControl: TGuiControl);
  var I: Integer;
  begin
    if AControl.Name = 'Nine-slice skin' then
    begin
      SetStyleSurfaces(AControl, FResources.NineSliceDrawable('atlas', GuiBox(8)));
    end;
    for I:=0 to AControl.ChildCount - 1 do Skin(AControl.Children[I]);
  end;
begin
  Theme:=GuiDarkTheme;
  if FReactor then Theme:=GuiReactorTheme;
  for Layer:=Low(TGuiLayerKind) to High(TGuiLayerKind) do
  begin
    GuiApplyTheme(FHost.Context.Layers[Layer], Theme);
    if Layer <> glkWorld then
    begin
      FHost.Context.Layers[Layer].BackgroundColor:=GuiColor(0, 0, 0, 0);
      FHost.Context.Layers[Layer].BorderColor:=GuiColor(0, 0, 0, 0);
    end;
    Skin(FHost.Context.Layers[Layer]);
  end;
  FLog.LineHeight:=20;
  FInstructions.LineHeight:=20;
  Log('Theme applied.');
end;

procedure TTestLab.OpenDialog(AModal, ANested: Boolean; AMode: TGuiDialogWindowMode);
var
  Dialog: TGuiDialog;
  Overlay: TGuiModalOverlay;
begin
  Dialog:=TGuiDialog.Create;
  Dialog.Name:='Live dialog';
  Dialog.Bounds:=GuiRect(250, 180, 510, 300);
  Dialog.WindowMode:=AMode;
  Dialog.TitleButtons:=[gdbMinimize, gdbMaximize, gdbClose];
  Dialog.Title:='Dialog interaction test';
  Dialog.MessageText:='Drag title or edges; Enter / Escape closes. Inspect the event log.';
  Dialog.AddButton('OK', True, gmrOk);
  Dialog.AddButton('Cancel', False, gmrCancel);
  Dialog.OnClose:=DialogClosed;
  if ANested then ButtonAt(Dialog.ClientPanel, 'Open nested modal', 12, 24, 40);
  if AModal then
  begin
    Overlay:=TGuiModalOverlay.CreateWithDialog(Dialog);
    Overlay.Name:='Live modal overlay';
    Overlay.Bounds:=FHost.Context.Root.Bounds;
    Overlay.Anchors:=[ganLeft, ganTop, ganRight, ganBottom];
    FHost.Context.ShowModal(Overlay);
  end else
    FHost.Context.Layers[glkDialog].Add(Dialog);
  ApplyTheme;
  Dialog.Activate;
  Log('Opened dialog; modal=' + BoolToStr(AModal, True));
end;

procedure TTestLab.DialogClosed(Sender: TGuiControl);
var
  Closed: TGuiControl;
begin
  Log('Dialog result=' + IntToStr(Ord(TGuiDialog(Sender).ModalResult)));
  if Sender.Parent IS TGuiModalOverlay then
  begin
    FHost.Context.CloseModal(Sender.Parent);
    Sender.Parent.Visible:=False;
    Closed:=Sender.Parent;
  end else
  begin
    Sender.Visible:=False;
    Closed:=Sender;
  end;
  if FClosedDialogs.IndexOf(Closed) < 0 then FClosedDialogs.Add(Closed);
end;

procedure TTestLab.ExecuteAction(AAction: Integer);
var
  I, OldPage: Integer;
  FileName: String;
  Theme, Loaded: TGuiTheme;
  C: TGuiControl;
  CompositionEvent: TGuiEvent;
  {$IFNDEF FPC}
  Loader: TGuiXmlLoader;
  XmlTab: TGuiTabControl;
  XmlBar: TGuiToolBar;
  procedure RejectTabXml(const Xml,Description: String);
  var Rejected: Boolean;
  Control: TGuiControl;
  CountBefore: Integer;
  begin
    Rejected:=False;
    Control:=nil;
    CountBefore:=FXmlParent.ChildCount;
    try
      try
        Control:=Loader.LoadFromString(Xml,FXmlParent);
      except
        on E: EArgumentException do Rejected:=True;
        on E: EConvertError do Rejected:=True;
        end;
    finally
      Control.Free;
    end;
    Check(Rejected AND (FXmlParent.ChildCount=CountBefore),Description);
  end;
  {$ENDIF}
begin
  case AAction of
    1: RunChecks;
    2: ExportReport(ExtractFilePath(ParamStr(0)) + 'TestLab-report-' + FormatDateTime('yyyymmdd-hhnnss-zzz', Now) + '.txt');
    3, 4:
    begin
      if AAction = 3 then FManual[FCurrentPage]:='PASS (human)' else FManual[FCurrentPage]:='FAIL (human)';
      OldPage:=FCurrentPage;
      FCurrentPage:=-1;
      SelectPage(OldPage);
    end;
    10: FStateTarget.Enabled:=NOT FStateTarget.Enabled;
    11: FStateTarget.Visible:=NOT FStateTarget.Visible;
    20: FEdit.Text:=String(UTF8Encode(UnicodeString('Gr' + #$00FC + #$00DF + 'e  a' + #$0301 +
      '  ' + #$D83D#$DC69#$200D#$D83D#$DCBB + '  ' + #$D83C#$DDE9#$D83C#$DDEA + '  ' + #$65E5#$672C)));
    21: FEdit.Undo;
    22: FEdit.Redo;
    23:
    begin
      FHost.Context.SetFocus(FEdit);
      FEdit.SelectAll;
    end;
    24:
    begin
      FMemo.WordWrap:=NOT FMemo.WordWrap;
      Log('Memo wrapping=' + BoolToStr(FMemo.WordWrap, True));
    end;
    27:
    begin
      FHost.Context.SetFocus(FMemo);
      FMemo.SetSelection(0,Min(20,Length(FMemo.Text)));
      CompositionEvent:=Default(TGuiEvent);
      CompositionEvent.Kind:=gekTextEditing;
      CompositionEvent.Text:=UTF8Encode(UnicodeString('Preview '+#$00FC+#$00DF+' 123 replacement text'));
      CompositionEvent.HasCompositionRange:=True;
      CompositionEvent.CompositionStart:=8;
      CompositionEvent.CompositionLength:=3;
      FMemo.HandleEvent(CompositionEvent);
      Log('Simulated composition preview; Escape cancels. Native IME behavior is not tested.');
    end;
    30: FAnimate:=NOT FAnimate;
    31: FSlider.Value:=FSlider.MinValue;
    32: FSlider.Value:=FSlider.MaxValue;
    40: OpenDialog(True, False);
    41: OpenDialog(True, True);
    42: OpenDialog(False, False);
    44: OpenDialog(False, False, gdwmFixed);
    45: OpenDialog(False, False, gdwmMovable);
    46, 47:
    begin
      OpenDialog(False, False, gdwmResizable);
      C:=FHost.Context.Layers[glkDialog].Children[FHost.Context.Layers[glkDialog].ChildCount - 1];
      TGuiDialog(C).Movable:=False;
      TGuiDialog(C).ShowTitleBar:=AAction <> 46;
      TGuiDialog(C).MessageText:='Resize edges; this window cannot move. Escape or Cancel closes.';
    end;
    43:
    begin
      C:=FHost.Context.Layers[glkDebug];
      if C.ChildCount > 0 then C.Clear else LabelAt(C, 'DEBUG LAYER - above dialogs', 770, 8, 470);
    end;
    50:
    begin
      FileName:=ExtractFilePath(ParamStr(0)) + 'TestLab-theme-' + FormatDateTime('yyyymmdd-hhnnss-zzz', Now) + '.ini';
      Theme:=GuiDarkTheme;
      if FReactor then Theme:=GuiReactorTheme;
      GuiSaveThemeToIni(FileName, Theme);
      Loaded:=GuiLoadThemeFromIni(FileName, GuiDarkTheme);
      Check(GuiColorToHex(Loaded.PrimaryAccent) = GuiColorToHex(Theme.PrimaryAccent), 'Theme INI accent roundtrip');
      Check((Loaded.Metrics.ControlCornerRadius = Theme.Metrics.ControlCornerRadius) AND
        (Loaded.Metrics.PanelCornerRadius = Theme.Metrics.PanelCornerRadius), 'Theme INI geometry roundtrip');
      Log('Theme saved and reloaded: ' + FileName);
    end;
    51:
    begin
      FFonts.FindFont('body').ClearCache;
      FFonts.FindFont('mono').ClearCache;
      FFonts.FindFont('large').ClearCache;
      Log('Font caches cleared.');
    end;
    52:
    begin
      FLogical:=NOT FLogical;
      if FLogical then SDL_SetRenderLogicalPresentation(FRenderer, 1280, 900, SDL_LOGICAL_PRESENTATION_LETTERBOX)
      else SDL_SetRenderLogicalPresentation(FRenderer, 0, 0, SDL_LOGICAL_PRESENTATION_DISABLED);
      if FLogical then FHost.Resize(1280, 900) else
      begin
        SDL_GetWindowSize(FWindow, @I, @OldPage);
        FHost.Resize(I, OldPage);
      end;
      Log('Logical presentation=' + BoolToStr(FLogical, True));
    end;
    60:
    begin
      FDynamic.Clear;
      for I:=1 to FCount.Value do ButtonAt(FDynamic, 'Generated ' + IntToStr(I), 0, 0);
      ApplyTheme;
      Log('Created ' + IntToStr(FDynamic.ChildCount) + ' controls.');
    end;
    61:
    begin
      FDynamic.Clear;
      Log('Generated controls freed.');
    end;
    62:
    begin
      if FDynamic.ChildCount = 0 then ButtonAt(FDynamic, 'Temporary', 0, 0);
      C:=FDynamic.Children[0];
      FHost.Context.SetFocus(C);
      C.Free;
      Check(FHost.Context.FocusedControl = nil, 'Focused dynamic control removal clears context reference');
    end;
    63: SDL_SetWindowSize(FWindow, 1000, 760);
    64: SDL_SetWindowSize(FWindow, 1280, 900);
    70:
    begin
      {$IFDEF FPC}
      Log('SKIP: XML loader requires Delphi.');
      FReport.Add('SKIP: XML loader requires Delphi.');
      {$ELSE}
      FXmlParent.Clear;
      Loader:=TGuiXmlLoader.Create;
      try
        Loader.LoadFromString('<panel width="900" height="200"><label x="16" y="12" width="700" height="28" caption="Loaded from XML"/>' +
          '<edit x="16" y="58" width="550" height="36" text="XML text value" hint="XML tooltip"/>'+
          '<toggleswitch x="16" y="108" width="250" height="36" caption="XML switch" checked="true"/>'+
          '<activityindicator x="300" y="108" width="32" height="32" animate="false" frameInterval="120"/>'+
          '<checkbox x="370" y="108" width="230" height="36" caption="Mixed XML checkbox" allowGrayed="true" state="grayed"/>'+
          '<pageindicator x="620" y="108" width="180" height="36" count="5" selectedIndex="2" interactive="true" ' +
          'dotSize="12" spacing="6" maxVisibleDots="3"/>'+
          '<progressbar x="16" y="158" width="550" height="20" marquee="true" marqueeInterval="2000" ' +
          'minValue="-20" maxValue="80" value="30" orientation="vertical" reverse="true" showText="true" ' +
          'segmentCount="5" segmentGap="2" showTicks="true" tickCount="6" showThreshold="true" thresholdValue="60"/>'+
          '<speedbutton x="620" y="154" width="100" height="32" caption="XML tool" checkable="true" down="true" groupIndex="3" allowAllUp="true"/>'+
          '<tabbutton x="740" y="154" width="120" height="32" caption="XML tab" down="true"/>'+
          '<radiobutton x="620" y="58" width="110" height="32" caption="Radio A" groupName="xml" checked="true"/>'+
          '<radiobutton x="740" y="58" width="120" height="32" caption="Radio B" groupName="xml" checked="true"/>'+
          '<radiogroup visible="false" items="Standard|Express|Pickup" itemIndex="1" itemHeight="36"/>'+
          '<slider visible="false" minValue="-20" maxValue="80" value="35" orientation="vertical" stepSize="5" live="false" snapMode="release"/>'+
          '<roundbutton visible="false" radius="7" caption="Round XML"/>'+
          '<knob visible="false" inputMode="horizontal" startAngle="180" endAngle="360" dragDistance="200" wrap="true" stepSize="5" live="false"/>'+
          '<checklistbox visible="false" items="One|Two|Three" states="checked|grayed|unchecked" ' +
          'itemEnabled="true|false|true" selectedIndex="1" allowGrayed="true" itemHeight="36"/>'+
          '<switchlistbox visible="false" items="Sound|Updates" states="checked|unchecked" itemEnabled="true|false" selectedIndex="0"/>'+
          '<delaybutton visible="false" delay="1500" checked="true" caption="Confirm"/>'+
          '<rangeslider visible="false" minValue="-20" maxValue="80" lowerValue="10" upperValue="60" stepSize="5" ' +
          'snapMode="release" live="false" orientation="vertical" activeThumb="upper"/>'+
          '<wheelpicker visible="false" items="Low|Medium|High" itemIndex="1" visibleItemCount="3" wrap="false" ' +
          'flickEnabled="false" deceleration="30" settleDuration="200"/>'+
          '<spinedit visible="false" caption="Not numeric text" minValue="-20" maxValue="120" value="35" increment="5" ' +
          'wrap="true" editable="false" live="true" autoRepeat="false" repeatDelay="250" repeatInterval="150"/>'+
          '<combobox visible="false" items="A|B|C|D|E" selectedIndex="3" itemHeight="24" dropDownCount="4" ' +
          'editable="true" text="Draft" autoComplete="true" searchCaseSensitive="true" typeAhead="false" typeAheadTimeout="250"/>'+
          '<tabcontrol visible="false" width="300" height="40" items="First|Disabled|Last|Extra" ' +
          'tabEnabled="true|false|true|true" selectedIndex="2" tabHeight="28" tabWidth="120" minTabWidth="100" ' +
          'tabPosition="bottom"/>'+
          '<button visible="false" autoRepeat="true" repeatDelay="450" repeatInterval="120" pressAndHoldInterval="950"/>'+
          '</panel>', FXmlParent);
        Check(FXmlParent.ChildCount = 1, 'XML creates a control tree');
        Check((FXmlParent.Children[0].Children[2] IS TGuiToggleSwitch) AND
          TGuiToggleSwitch(FXmlParent.Children[0].Children[2]).Checked,'XML creates a checked toggle switch');
        Check((FXmlParent.Children[0].Children[3] IS TGuiActivityIndicator) AND
          NOT TGuiActivityIndicator(FXmlParent.Children[0].Children[3]).Animate AND
          (TGuiActivityIndicator(FXmlParent.Children[0].Children[3]).FrameInterval=120),
          'XML creates and configures an activity indicator');
        C:=Loader.LoadFromString('<busyindicator frameInterval="4294967295"/>');
        try
          Check((C IS TGuiActivityIndicator) AND
            (TGuiActivityIndicator(C).FrameInterval=High(Cardinal)),
            'XML busy-indicator alias preserves the full Cardinal interval');
        finally
          C.Free;
        end;
        C:=Loader.LoadFromString('<activityindicator frameInterval="0"/>');
        try
          Check(TGuiActivityIndicator(C).FrameInterval=1,'XML zero activity interval matches the property clamp');
        finally
          C.Free;
        end;
        RejectTabXml('<activityindicator frameInterval="bad"/>','XML rejects malformed activity interval');
        RejectTabXml('<activityindicator frameInterval="-1"/>','XML rejects negative activity interval');
        RejectTabXml('<activityindicator frameInterval="4294967296"/>','XML rejects overflowing activity interval');
        Check((FXmlParent.Children[0].Children[4] IS TGuiCheckBox) AND
          TGuiCheckBox(FXmlParent.Children[0].Children[4]).AllowGrayed AND
          (TGuiCheckBox(FXmlParent.Children[0].Children[4]).State=gcbGrayed),
          'XML creates and configures a three-state checkbox');
        Check((FXmlParent.Children[0].Children[5] IS TGuiPageIndicator) AND
          (TGuiPageIndicator(FXmlParent.Children[0].Children[5]).Count=5) AND
          (TGuiPageIndicator(FXmlParent.Children[0].Children[5]).SelectedIndex=2) AND
          TGuiPageIndicator(FXmlParent.Children[0].Children[5]).Interactive,
          'XML creates and configures a page indicator');
        Check((TGuiPageIndicator(FXmlParent.Children[0].Children[5]).DotSize=12) AND
          (TGuiPageIndicator(FXmlParent.Children[0].Children[5]).Spacing=6) AND
          (TGuiPageIndicator(FXmlParent.Children[0].Children[5]).MaxVisibleDots=3),
          'XML configures page indicator geometry and visible window');
        RejectTabXml('<pageindicator count="bad"/>','XML rejects malformed page count');
        RejectTabXml('<pageindicator selectedIndex="bad"/>','XML rejects malformed selected page');
        RejectTabXml('<pageindicator dotSize="bad"/>','XML rejects malformed dot size');
        RejectTabXml('<pageindicator spacing="bad"/>','XML rejects malformed dot spacing');
        RejectTabXml('<pageindicator maxVisibleDots="bad"/>','XML rejects malformed visible-dot count');
        Check((FXmlParent.Children[0].Children[6] IS TGuiProgressBar) AND
          TGuiProgressBar(FXmlParent.Children[0].Children[6]).Marquee AND
          (TGuiProgressBar(FXmlParent.Children[0].Children[6]).MarqueeInterval=2000),
          'XML creates and configures marquee progress');
        Check((TGuiProgressBar(FXmlParent.Children[0].Children[6]).MinValue=-20) AND
          (TGuiProgressBar(FXmlParent.Children[0].Children[6]).MaxValue=80) AND
          (TGuiProgressBar(FXmlParent.Children[0].Children[6]).Value=30) AND
          (TGuiProgressBar(FXmlParent.Children[0].Children[6]).Orientation=goVertical) AND
          TGuiProgressBar(FXmlParent.Children[0].Children[6]).Reverse AND
          TGuiProgressBar(FXmlParent.Children[0].Children[6]).ShowText AND
          (TGuiProgressBar(FXmlParent.Children[0].Children[6]).SegmentCount=5) AND
          (TGuiProgressBar(FXmlParent.Children[0].Children[6]).SegmentGap=2) AND
          TGuiProgressBar(FXmlParent.Children[0].Children[6]).ShowTicks AND
          (TGuiProgressBar(FXmlParent.Children[0].Children[6]).TickCount=6) AND
          TGuiProgressBar(FXmlParent.Children[0].Children[6]).ShowThreshold AND
          (TGuiProgressBar(FXmlParent.Children[0].Children[6]).ThresholdValue=60),
          'XML preserves determinate progress configuration alongside marquee mode');
        RejectTabXml('<progressbar orientation="diagonal"/>','XML rejects invalid progress orientation');
        RejectTabXml('<progressbar value="bad"/>','XML rejects invalid progress value');
        RejectTabXml('<progressbar marqueeInterval="4294967296"/>','XML rejects overflowing marquee interval');
        Check((FXmlParent.Children[0].Children[7] IS TGuiSpeedButton) AND
          TGuiSpeedButton(FXmlParent.Children[0].Children[7]).Down AND
          TGuiSpeedButton(FXmlParent.Children[0].Children[7]).Checkable AND
          TGuiSpeedButton(FXmlParent.Children[0].Children[7]).AllowAllUp AND
          (TGuiSpeedButton(FXmlParent.Children[0].Children[7]).GroupIndex=3),
          'XML creates and configures a speed button');
        Check((FXmlParent.Children[0].Children[8] IS TGuiTabButton) AND
          TGuiTabButton(FXmlParent.Children[0].Children[8]).Down AND
          TGuiTabButton(FXmlParent.Children[0].Children[8]).Checkable AND
          (TGuiTabButton(FXmlParent.Children[0].Children[8]).GroupIndex=1),
          'XML tab button retains exclusive defaults');
        Check((FXmlParent.Children[0].Children[9] IS TGuiRadioButton) AND
          NOT TGuiRadioButton(FXmlParent.Children[0].Children[9]).Checked AND
          TGuiRadioButton(FXmlParent.Children[0].Children[10]).Checked AND
          (TGuiRadioButton(FXmlParent.Children[0].Children[10]).GroupName='xml'),
          'XML radio state is exclusive after attachment to parent');
        Check((FXmlParent.Children[0].Children[11] IS TGuiRadioGroup) AND
          (TGuiRadioGroup(FXmlParent.Children[0].Children[11]).Items.Count=3) AND
          (TGuiRadioGroup(FXmlParent.Children[0].Children[11]).ItemIndex=1) AND
          (TGuiRadioGroup(FXmlParent.Children[0].Children[11]).ItemHeight=36),
          'XML creates radio options and selection');
        RejectTabXml('<radiogroup itemHeight="bad"/>','XML rejects malformed radio row height');
        RejectTabXml('<radiogroup itemIndex="bad"/>','XML rejects malformed radio selection');
        Check((FXmlParent.Children[0].Children[12] IS TGuiSlider) AND
          NOT TGuiSlider(FXmlParent.Children[0].Children[12]).Live AND
          (TGuiSlider(FXmlParent.Children[0].Children[12]).StepSize=5) AND
          (TGuiSlider(FXmlParent.Children[0].Children[12]).MinValue=-20) AND
          (TGuiSlider(FXmlParent.Children[0].Children[12]).MaxValue=80) AND
          (TGuiSlider(FXmlParent.Children[0].Children[12]).Value=35) AND
          (TGuiSlider(FXmlParent.Children[0].Children[12]).Orientation=goVertical) AND
          (TGuiSlider(FXmlParent.Children[0].Children[12]).SnapMode=gsmSnapOnRelease),
          'XML configures slider range, value, orientation and deferred stepping');
        RejectTabXml('<slider orientation="diagonal"/>','XML rejects invalid slider orientation');
        RejectTabXml('<slider minValue="bad"/>','XML rejects malformed slider minimum');
        RejectTabXml('<slider maxValue="bad"/>','XML rejects malformed slider maximum');
        RejectTabXml('<slider value="bad"/>','XML rejects malformed slider value');
        RejectTabXml('<slider stepSize="bad"/>','XML rejects malformed slider step');
        RejectTabXml('<slider stepSize="-1"/>','XML rejects negative slider step');
        RejectTabXml('<slider snapMode="bad"/>','XML rejects unknown slider snap mode');
        Check((FXmlParent.Children[0].Children[13] IS TGuiRoundButton) AND
          (TGuiRoundButton(FXmlParent.Children[0].Children[13]).Radius=7),
          'XML configures round button radius');
        Check((FXmlParent.Children[0].Children[14] IS TGuiKnob) AND
          (TGuiKnob(FXmlParent.Children[0].Children[14]).InputMode=gkiHorizontal) AND
          (TGuiKnob(FXmlParent.Children[0].Children[14]).StartAngle=180) AND
          (TGuiKnob(FXmlParent.Children[0].Children[14]).EndAngle=360) AND
          (TGuiKnob(FXmlParent.Children[0].Children[14]).DragDistance=200) AND
          TGuiKnob(FXmlParent.Children[0].Children[14]).Wrap AND
          NOT TGuiKnob(FXmlParent.Children[0].Children[14]).Live,
          'XML configures knob angles, input mode and drag behavior');
        RejectTabXml('<knob startAngle="bad"/>','XML rejects malformed knob start angle');
        RejectTabXml('<knob endAngle="bad"/>','XML rejects malformed knob end angle');
        RejectTabXml('<knob dragDistance="bad"/>','XML rejects malformed knob drag distance');
        RejectTabXml('<knob dragDistance="0"/>','XML rejects zero knob drag distance');
        RejectTabXml('<knob startAngle="180" endAngle="180"/>','XML rejects empty knob arc');
        Check((FXmlParent.Children[0].Children[15] IS TGuiCheckListBox) AND
          (TGuiCheckListBox(FXmlParent.Children[0].Children[15]).Items.Count=3) AND
          TGuiCheckListBox(FXmlParent.Children[0].Children[15]).Checked[0] AND
          (TGuiCheckListBox(FXmlParent.Children[0].Children[15]).State[1]=gcbGrayed) AND
          NOT TGuiCheckListBox(FXmlParent.Children[0].Children[15]).ItemEnabled[1] AND
          (TGuiCheckListBox(FXmlParent.Children[0].Children[15]).SelectedIndex=1) AND
          TGuiCheckListBox(FXmlParent.Children[0].Children[15]).AllowGrayed AND
          (TGuiCheckListBox(FXmlParent.Children[0].Children[15]).ItemHeight=36),
          'XML configures checklist rows, states, enabled flags and selection');
        Check((FXmlParent.Children[0].Children[16] IS TGuiSwitchListBox) AND
          TGuiSwitchListBox(FXmlParent.Children[0].Children[16]).Checked[0] AND
          NOT TGuiSwitchListBox(FXmlParent.Children[0].Children[16]).ItemEnabled[1] AND
          (TGuiSwitchListBox(FXmlParent.Children[0].Children[16]).ThumbPosition[0]=1),
          'XML configures switch-list rows and states');
        Check((FXmlParent.Children[0].Children[17] IS TGuiDelayButton) AND
          (TGuiDelayButton(FXmlParent.Children[0].Children[17]).Delay=1500) AND
          TGuiDelayButton(FXmlParent.Children[0].Children[17]).Checked AND
          (TGuiDelayButton(FXmlParent.Children[0].Children[17]).Progress=1),
          'XML configures delay button interval and checked state');
        Check((FXmlParent.Children[0].Children[18] IS TGuiRangeSlider) AND
          (TGuiRangeSlider(FXmlParent.Children[0].Children[18]).LowerValue=10) AND
          (TGuiRangeSlider(FXmlParent.Children[0].Children[18]).UpperValue=60) AND
          (TGuiRangeSlider(FXmlParent.Children[0].Children[18]).MinValue=-20) AND
          (TGuiRangeSlider(FXmlParent.Children[0].Children[18]).MaxValue=80) AND
          (TGuiRangeSlider(FXmlParent.Children[0].Children[18]).StepSize=5) AND
          (TGuiRangeSlider(FXmlParent.Children[0].Children[18]).SnapMode=gsmSnapOnRelease) AND
          NOT TGuiRangeSlider(FXmlParent.Children[0].Children[18]).Live AND
          (TGuiRangeSlider(FXmlParent.Children[0].Children[18]).Orientation=goVertical) AND
          (TGuiRangeSlider(FXmlParent.Children[0].Children[18]).ActiveThumb=grtUpper),
          'XML configures range slider endpoints, orientation and drag policy');
        RejectTabXml('<rangeslider minValue="bad"/>','XML rejects malformed range minimum');
        RejectTabXml('<rangeslider maxValue="bad"/>','XML rejects malformed range maximum');
        RejectTabXml('<rangeslider lowerValue="bad"/>','XML rejects malformed lower endpoint');
        RejectTabXml('<rangeslider upperValue="bad"/>','XML rejects malformed upper endpoint');
        RejectTabXml('<rangeslider stepSize="bad"/>','XML rejects malformed range step');
        RejectTabXml('<rangeslider stepSize="-1"/>','XML rejects negative range step');
        RejectTabXml('<rangeslider orientation="bad"/>','XML rejects invalid range orientation');
        RejectTabXml('<rangeslider snapMode="bad"/>','XML rejects invalid range snap mode');
        RejectTabXml('<rangeslider activeThumb="bad"/>','XML rejects invalid range active thumb');
        Check((FXmlParent.Children[0].Children[19] IS TGuiWheelPicker) AND
          (TGuiWheelPicker(FXmlParent.Children[0].Children[19]).Items.Count=3) AND
          (TGuiWheelPicker(FXmlParent.Children[0].Children[19]).ItemIndex=1) AND
          (TGuiWheelPicker(FXmlParent.Children[0].Children[19]).VisibleItemCount=3) AND
          NOT TGuiWheelPicker(FXmlParent.Children[0].Children[19]).Wrap AND
          NOT TGuiWheelPicker(FXmlParent.Children[0].Children[19]).FlickEnabled AND
          (TGuiWheelPicker(FXmlParent.Children[0].Children[19]).Deceleration=30) AND
          (TGuiWheelPicker(FXmlParent.Children[0].Children[19]).SettleDuration=200),
          'XML configures wheel items, selection, wrapping and motion');
        RejectTabXml('<wheelpicker deceleration="bad"/>','XML rejects malformed wheel deceleration');
        RejectTabXml('<wheelpicker deceleration="0"/>','XML rejects zero wheel deceleration');
        RejectTabXml('<wheelpicker visibleItemCount="4"/>','XML rejects even wheel row count');
        RejectTabXml('<wheelpicker visibleItemCount="103"/>','XML rejects oversized wheel row count');
        RejectTabXml('<wheelpicker wrap="bad"/>','XML rejects invalid wheel wrap policy');
        RejectTabXml('<wheelpicker settleDuration="-1"/>','XML rejects negative wheel settling duration');
        RejectTabXml('<wheelpicker settleDuration="4294967296"/>','XML rejects overflowing wheel settling duration');
        Check((FXmlParent.Children[0].Children[20] IS TGuiSpinEdit) AND
          (TGuiSpinEdit(FXmlParent.Children[0].Children[20]).Value=35) AND
          (TGuiSpinEdit(FXmlParent.Children[0].Children[20]).Text='35') AND
          (TGuiSpinEdit(FXmlParent.Children[0].Children[20]).MinValue=-20) AND
          (TGuiSpinEdit(FXmlParent.Children[0].Children[20]).MaxValue=120) AND
          (TGuiSpinEdit(FXmlParent.Children[0].Children[20]).Increment=5) AND
          TGuiSpinEdit(FXmlParent.Children[0].Children[20]).Wrap AND
          TGuiSpinEdit(FXmlParent.Children[0].Children[20]).Live AND
          NOT TGuiSpinEdit(FXmlParent.Children[0].Children[20]).Editable AND
          NOT TGuiSpinEdit(FXmlParent.Children[0].Children[20]).AutoRepeat AND
          (TGuiSpinEdit(FXmlParent.Children[0].Children[20]).RepeatDelay=250) AND
          (TGuiSpinEdit(FXmlParent.Children[0].Children[20]).RepeatInterval=150),
          'XML configures numeric spin state independently of caption');
        RejectTabXml('<spinedit value="bad"/>','XML rejects malformed spin value');
        RejectTabXml('<spinedit minValue="-2147483649"/>','XML rejects overflowing spin minimum');
        RejectTabXml('<spinedit maxValue="2147483648"/>','XML rejects overflowing spin maximum');
        RejectTabXml('<spinedit increment="0"/>','XML rejects zero spin increment');
        RejectTabXml('<spinedit repeatDelay="-1"/>','XML rejects negative spin repeat delay');
        RejectTabXml('<spinedit repeatInterval="0"/>','XML rejects zero spin repeat interval');
        RejectTabXml('<spinedit repeatInterval="4294967296"/>','XML rejects overflowing spin repeat interval');
        Check((FXmlParent.Children[0].Children[21] IS TGuiComboBox) AND
          (TGuiComboBox(FXmlParent.Children[0].Children[21]).Items.Count=5) AND
          (TGuiComboBox(FXmlParent.Children[0].Children[21]).SelectedIndex=3) AND
          (TGuiComboBox(FXmlParent.Children[0].Children[21]).ItemHeight=24) AND
          (TGuiComboBox(FXmlParent.Children[0].Children[21]).DropDownCount=4) AND
          TGuiComboBox(FXmlParent.Children[0].Children[21]).Editable AND
          TGuiComboBox(FXmlParent.Children[0].Children[21]).AutoComplete AND
          TGuiComboBox(FXmlParent.Children[0].Children[21]).SearchCaseSensitive AND
          NOT TGuiComboBox(FXmlParent.Children[0].Children[21]).TypeAhead AND
          (TGuiComboBox(FXmlParent.Children[0].Children[21]).TypeAheadTimeout=250) AND
          (TGuiComboBox(FXmlParent.Children[0].Children[21]).Text='Draft'),
          'XML configures combo items, selection and popup row sizing');
        RejectTabXml('<combobox itemHeight="bad"/>','XML rejects malformed combo row height');
        RejectTabXml('<combobox itemHeight="0"/>','XML rejects zero combo row height');
        RejectTabXml('<combobox dropDownCount="0"/>','XML rejects zero combo popup row count');
        RejectTabXml('<combobox selectedIndex="bad"/>','XML rejects malformed combo selection');
        RejectTabXml('<combobox typeAheadTimeout="0"/>','XML rejects zero combo search timeout');
        RejectTabXml('<combobox typeAheadTimeout="4294967296"/>','XML rejects overflowing combo search timeout');
        XmlTab:=TGuiTabControl(FXmlParent.Children[0].Children[22]);
        Check(TGuiButton(FXmlParent.Children[0].Children[23]).AutoRepeat AND
          (TGuiButton(FXmlParent.Children[0].Children[23]).RepeatDelay=450) AND
          (TGuiButton(FXmlParent.Children[0].Children[23]).RepeatInterval=120) AND
          (TGuiButton(FXmlParent.Children[0].Children[23]).PressAndHoldInterval=950),
          'XML configures button repeat timing');
        RejectTabXml('<button pressAndHoldInterval="0"/>','XML rejects zero button hold interval');
        XmlBar:=TGuiToolBar(Loader.LoadFromString(
          '<toolbar width="200" height="120" orientation="vertical" spacing="7" autoSizeToContent="false">' +
          '<speedbutton width="60" height="24"/><separator width="80" height="3" orientation="horizontal" thickness="2"/>' +
          '<edit width="100" height="24"/></toolbar>'));
        try
          XmlBar.Arrange(XmlBar.Bounds);
          Check((XmlBar.Orientation=goVertical) AND (XmlBar.Spacing=7) AND NOT XmlBar.AutoSizeToContent AND
            (XmlBar.Children[2].Bounds.Top>=XmlBar.Children[1].Bounds.Top+XmlBar.Children[1].Bounds.Height+7),
            'XML vertical toolbar arranges embedded controls with configured spacing');
          Check((TGuiSeparator(XmlBar.Children[1]).Thickness=2) AND
            (TGuiSeparator(XmlBar.Children[1]).Orientation=goHorizontal),
            'XML configures separator orientation and thickness');
        finally
          XmlBar.Free;
        end;
        RejectTabXml('<toolbar orientation="diagonal"/>','XML rejects unknown toolbar orientation');
        RejectTabXml('<toolbar spacing="bad"/>','XML rejects malformed toolbar spacing');
        RejectTabXml('<separator orientation="diagonal"/>','XML rejects unknown separator orientation');
        RejectTabXml('<separator thickness="-1"/>','XML rejects negative separator thickness');
        RejectTabXml('<button repeatInterval="0"/>','XML rejects zero button repeat interval');
        RejectTabXml('<button repeatDelay="-1"/>','XML rejects negative button repeat delay');
        RejectTabXml('<button repeatDelay="4294967296"/>','XML rejects overflowing button repeat delay');
        RejectTabXml('<button repeatInterval="4294967296"/>','XML rejects overflowing button repeat interval');
        RejectTabXml('<button pressAndHoldInterval="4294967296"/>','XML rejects overflowing button hold interval');
        RejectTabXml('<delaybutton autoRepeat="true"/>','XML rejects repeating hold-to-confirm button');
        Check((XmlTab.Items.Count=4) AND (XmlTab.SelectedIndex=2) AND NOT XmlTab.TabEnabled[1] AND
          (XmlTab.TabHeight=28) AND (XmlTab.TabWidth=120) AND (XmlTab.MinTabWidth=100) AND
          (XmlTab.ScrollOffset>0) AND (XmlTab.TabPosition=gtpBottom) AND
          (XmlTab.HeaderViewport.Top=XmlTab.AbsoluteBounds.Top+12),
          'XML configures tab state, sizing, position and selection reveal');
        XmlTab:=TGuiTabControl(Loader.LoadFromString('<tabcontrol items="A|B" tabEnabled="false|true"/>'));
        try
          Check((XmlTab.SelectedIndex=1) AND (XmlTab.TabWidth=0) AND (XmlTab.MinTabWidth=0),
          'XML tab defaults select first enabled tab and retain equal widths');
          finally
            XmlTab.Free;
          end;
        XmlTab:=TGuiTabControl(Loader.LoadFromString('<tabcontrol items="A|B" tabEnabled="false|false"/>'));
        try
          Check(XmlTab.SelectedIndex=-1,'XML all-disabled tabs remain unselected');
        finally
          XmlTab.Free;
        end;
        XmlTab:=TGuiTabControl(Loader.LoadFromString('<tabcontrol width="200" items="A|B|C" tabWidth="100" selectedIndex="-1" scrollOffset="9999"/>'));
        try
          Check((XmlTab.SelectedIndex=-1) AND (XmlTab.ScrollOffset=XmlTab.MaxScrollOffset),
          'XML supports explicit tab deselection and clamped initial scroll');
          finally
            XmlTab.Free;
          end;
        XmlTab:=TGuiTabControl(Loader.LoadFromString('<tabcontrol/>'));
        try
          Check((XmlTab.Items.Count=0) AND (XmlTab.SelectedIndex=-1),
          'XML empty tab control retains empty selection');
          finally
            XmlTab.Free;
          end;
        RejectTabXml('<tabcontrol items="A|B" tabEnabled="true"/>','XML rejects mismatched tab enabled flags');
        RejectTabXml('<tabcontrol items="A" tabEnabled="maybe"/>','XML rejects malformed tab enabled flags');
        RejectTabXml('<tabcontrol tabHeight="0"/>','XML rejects nonpositive tab height');
        RejectTabXml('<tabcontrol tabPosition="sideways"/>','XML rejects unknown tab position');
        XmlTab:=TGuiTabControl(Loader.LoadFromString(
          '<tabcontrol items="A|Long caption" autoSizeTabs="true" itemWidths="80|0" dragScroll="false" ' +
          'flickEnabled="false" deceleration="1800"/>'));
        try
          Check(XmlTab.AutoSizeTabs AND (XmlTab.ItemWidths[0]=80) AND (XmlTab.ItemWidths[1]=0) AND
          NOT XmlTab.DragScroll AND NOT XmlTab.FlickEnabled AND (XmlTab.Deceleration=1800),
          'XML configures per-tab widths and drag/flick policy');
          finally
            XmlTab.Free;
          end;
        RejectTabXml('<tabcontrol deceleration="0"/>','XML rejects nonpositive tab deceleration');
        RejectTabXml('<tabcontrol items="A|B" itemWidths="80"/>','XML rejects mismatched per-tab widths');
        RejectTabXml('<tabcontrol items="A" itemWidths="-1"/>','XML rejects negative per-tab widths');
        RejectTabXml('<tabcontrol items="A" itemWidths="bad"/>','XML rejects malformed per-tab widths');
        RejectTabXml('<tabcontrol tabWidth="-1"/>','XML rejects negative tab width');
        RejectTabXml('<tabcontrol minTabWidth="bad"/>','XML rejects malformed minimum tab width');
        RejectTabXml('<tabcontrol scrollOffset="bad"/>','XML rejects malformed tab scroll offset');
        RejectTabXml('<panel><label/><tabcontrol tabWidth="-1"/></panel>',
          'Failed child configuration removes the partial XML tree from its parent');
        ApplyTheme;
      finally
        Loader.Free;
      end;
      {$ENDIF}
    end;
  end;
end;

procedure TTestLab.CollectCoverage(AControl: TGuiControl);
var I: Integer;
begin
  FCoverage.Add(AControl.ClassName);
  for I:=0 to AControl.ChildCount - 1 do CollectCoverage(AControl.Children[I]);
end;

procedure TTestLab.Check(ACondition: Boolean; const AMessage: String);
var Line: String;
begin
  if ACondition then
  begin
    Inc(FPasses);
    Line:='PASS: ';
  end
  else
  begin
    Inc(FFailures);
    Line:='FAIL: ';
  end;
  Line:=Line + AMessage;
  FReport.Add(Line);
  Writeln(Line);
  if Assigned(FResults) then FResults.Lines.Add(Line);
end;

procedure TTestLab.RunChecks;
var
  Names: TStringList;
  I: Integer;
  Layer: TGuiLayerKind;
begin
  FPasses:=0;
  FFailures:=0;
  FReport.Clear;
  FResults.ClearLines;
  FCoverage.Clear;
  for Layer:=Low(TGuiLayerKind) to High(TGuiLayerKind) do CollectCoverage(FHost.Context.Layers[Layer]);
  Names:=TStringList.Create;
  try
    Names.CommaText:=EXPECTED_CLASSES;
    for I:=0 to Names.Count - 1 do Check(FCoverage.IndexOf(Names[I]) >= 0, 'Gallery includes ' + Names[I]);
  finally
    Names.Free;
  end;
  RunLabChecks(Check);
  Check(FResources.FindRegion('atlas') <> nil, 'SDL atlas registered');
  Check(FFonts.FindFont('large').MeasureText('ABC').Width > FFonts.FindFont('body').MeasureText('ABC').Width, 'Font roles use distinct sizes');
  Log(Format('Automated checks finished: %d passed, %d failed. Manual results unchanged.', [FPasses, FFailures]));
end;

procedure TTestLab.ExportReport(const AFileName: String);
var
  Report: TStringList;
  I: Integer;
begin
  Report:=TStringList.Create;
  try
    Report.Add('PasSDL3-GUI Test Lab / ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    {$IFDEF FPC}
    Report.Add('Compiler: FPC / UTF-8 String');
    {$ELSE}
    Report.Add('Compiler: Delphi / UTF-16 String');
    {$ENDIF}
    Report.Add(Format('Automated results: %d PASS, %d FAIL', [FPasses, FFailures]));
    if FReport.Count = 0 then Report.Add('Automated checks: NOT RUN');
    Report.AddStrings(FReport);
    Report.Add('');
    Report.Add('Manual observations (not inferred from automated checks):');
    for I:=0 to LAB_PAGE_COUNT - 1 do Report.Add(PAGE_NAMES[I] + ': ' + FManual[I]);
    Report.Add('');
    Report.Add('Manual notes:');
    Report.Add(FNotes.Text);
    Report.Add('');
    Report.Add('Known limits: native IME candidate behavior and real-device interactions need separate review.');
    Report.Add('XML is Delphi-only. Frame timings are observations, not benchmark assertions.');
    Report.SaveToFile(AFileName);
  finally
    Report.Free;
  end;
  Log('Report exported: ' + AFileName);
end;

procedure TTestLab.Render;
var Started: UInt64;
begin
  Started:=SDL_GetPerformanceCounter;
  SDL_SetRenderDrawColor(FRenderer, 15, 18, 23, 255);
  SDL_RenderClear(FRenderer);
  FHost.Render;
  FRenderMs:=(SDL_GetPerformanceCounter - Started) * 1000.0 / SDL_GetPerformanceFrequency;
end;

procedure TTestLab.Tick;
var
  NowTime: UInt64;
  Focus, Hover, Capture: String;
begin
  while FClosedDialogs.Count > 0 do
  begin
    TObject(FClosedDialogs[0]).Free;
    FClosedDialogs.Delete(0);
  end;
  NowTime:=TThread.GetTickCount64;
  if FAnimate then FScope.SweepAngle:=((NowTime - FStarted) MOD 6000) * 0.06;
  if NowTime - FLastStatus < 250 then Exit;
  FLastStatus:=NowTime;
  Focus:='none';
  Hover:='none';
  Capture:='none';
  if Assigned(FHost.Context.FocusedControl) then Focus:=FHost.Context.FocusedControl.Name;
  if Assigned(FHost.Context.HoveredControl) then Hover:=FHost.Context.HoveredControl.Name;
  if Assigned(FHost.Context.CapturedControl) then Capture:=FHost.Context.CapturedControl.Name;
  FStatus.Caption:=Format('Render %.2f ms | Events %d | Focus: %s | Hover: %s | Capture: %s | Cache hits %d',
    [FRenderMs, FEvents, Focus, Hover, Capture, FFonts.FindFont('body').CacheHits]);
end;

function TTestLab.CommandValue(const AName: String): String;
var I: Integer;
Prefix: String;
begin
  Result:='';
  Prefix:='-' + AName + '=';
  for I:=1 to ParamCount do if Pos(Prefix, ParamStr(I)) = 1 then Result:=Copy(ParamStr(I), Length(Prefix) + 1, MaxInt);
end;

function TTestLab.Run: Boolean;
var
  Event: TSDL_Event;
  MenuEvent: TGuiEvent;
  WindowA, WindowB: TGuiDialog;
  SavedTooltipDelay: Cardinal;
  I, J, ActionCode: Integer;
  SelfTest: Boolean;
  CaptureDir, FileName, SavedMemoText: String;
  Surface: PSDL_Surface;
  Path: UTF8String;
  procedure CaptureFrame(const AName: String);
  begin
    Render;
    Surface:=SDL_RenderReadPixels(FRenderer, nil);
    Check(Assigned(Surface), 'Capture ' + AName);
    if Assigned(Surface) then
    try
      Path:=UTF8String(IncludeTrailingPathDelimiter(CaptureDir) + AName + '.bmp');
      Check(SDL_SaveBMP(Surface, PAnsiChar(Path)), 'Save screenshot');
    finally
      SDL_DestroySurface(Surface);
    end;
  end;
begin
  SelfTest:=FindCmdLineSwitch('self-test') OR FindCmdLineSwitch('smoke-test');
  CaptureDir:=CommandValue('capture-dir');
  if CaptureDir <> '' then ForceDirectories(CaptureDir);
  if SelfTest then
  begin
    FQuiet:=True;
    RunChecks;
    for J:=0 to 1 do
    begin
      FThemeSelect.SelectedIndex:=J;
      FReactor:=J = 1;
      ApplyTheme;
      for I:=0 to LAB_PAGE_COUNT - 1 do
      begin
        // Navigate through the host, exercising the same input route as a user.
        FillChar(Event, SizeOf(Event), 0);
        Event.type_:=SDL_EVENT_MOUSE_BUTTON_DOWN;
        Event.button.windowID:=SDL_GetWindowID(FWindow);
        Event.button.button:=SDL_BUTTON_LEFT;
        Event.button.x:=FNavigation.Bounds.Left + 20;
        Event.button.y:=FNavigation.Bounds.Top + FNavigation.Padding.Top + (I + 0.5) * FNavigation.ItemHeight;
        FHost.ProcessEvent(Event);
        Event.type_:=SDL_EVENT_MOUSE_BUTTON_UP;
        FHost.ProcessEvent(Event);
        Check(FCurrentPage = I, 'Navigate by SDL mouse event: ' + PAGE_NAMES[I]);
        Render;
        Check(SDL_RenderPresent(FRenderer), 'Render ' + PAGE_NAMES[I] + ' theme ' + IntToStr(J));
        if CaptureDir <> '' then
        begin
          CaptureFrame(Format('page-%.2d-theme-%d', [I, J]));
          if I = 2 then
          begin
            FTable.SortByColumn(1, gsdDescending);
            FTable.SelectedIndex:=1;
            FTable.RowSelected[2]:=True;
            FTable.RowSelected[4]:=True;
            FHost.Context.SetFocus(FTable);
            CaptureFrame(Format('table-selection-theme-%d', [J]));
            FTable.SortByColumn(1, gsdAscending);
            FTable.SelectedIndex:=1;
            FPages[2].ScrollY:=10000;
            FPages[2].ScrollY:=600;
            CaptureFrame(Format('radio-group-theme-%d',[J]));
            FPages[2].ScrollY:=10000;
            CaptureFrame(Format('wheel-picker-theme-%d',[J]));
            FHost.Context.SetFocus(FEditableCombo);
            FEditableCombo.SelectAll;
            CaptureFrame(Format('editable-combo-theme-%d',[J]));
            Event:=Default(TSDL_Event);
            Event.type_:=SDL_EVENT_TEXT_INPUT;
            Event.text.windowID:=SDL_GetWindowID(FWindow);
            Event.text.text:='me';
            FHost.ProcessEvent(Event);
            CaptureFrame(Format('autocomplete-combo-theme-%d',[J]));
            FEditableCombo.DroppedDown:=True;
            CaptureFrame(Format('combo-popup-theme-%d',[J]));
            FEditableCombo.DroppedDown:=False;
            FEditableCombo.CancelEdit;
            FEditableCombo.ClearSelection;
            FPages[2].ScrollY:=0;
          end;
          if I = 0 then
          begin
            FHost.Context.SetFocus(FThemeSelect);
            FillChar(Event, SizeOf(Event), 0);
            Event.type_:=SDL_EVENT_KEY_DOWN;
            Event.key.windowID:=SDL_GetWindowID(FWindow);
            Event.key.key:=9; // Tab: font selector, then primary action.
            FHost.ProcessEvent(Event);
            FHost.ProcessEvent(Event);
            Check(Assigned(FHost.Context.FocusedControl) AND FHost.Context.FocusedControl.FocusVisible,
              'Keyboard navigation exposes focus treatment');
            CaptureFrame(Format('focus-theme-%d', [J]));
            FPages[0].ScrollY:=10000;
            CaptureFrame(Format('alignment-theme-%d', [J]));
            FPages[0].ScrollY:=10000;
            CaptureFrame(Format('delay-button-theme-%d',[J]));
            FPages[0].ScrollY:=0;
          end;
          if I = 3 then
          begin
            FPages[3].ScrollY:=500;
            CaptureFrame(Format('activity-indicator-theme-%d',[J]));
            CaptureFrame(Format('knob-theme-%d',[J]));
            FPages[3].ScrollY:=10000;
            CaptureFrame(Format('range-slider-theme-%d',[J]));
            FHost.Context.SetFocus(FRangeSlider);
            FillChar(Event,SizeOf(Event),0);
            Event.type_:=SDL_EVENT_KEY_DOWN;
            Event.key.windowID:=SDL_GetWindowID(FWindow);
            Event.key.key:=32;
            FHost.ProcessEvent(Event);
            CaptureFrame(Format('range-slider-focus-theme-%d',[J]));
            FHost.Context.SetFocus(FSpinEditor);
            FSpinEditor.SelectAll;
            CaptureFrame(Format('spin-editor-theme-%d',[J]));
            FPages[3].ScrollY:=0;
          end;
          if I = 4 then
          begin
            FPages[4].ScrollY:=370;
            CaptureFrame(Format('scroll-area-theme-%d', [J]));
            FPages[4].ScrollY:=10000;
            CaptureFrame(Format('scrollbar-comparison-theme-%d', [J]));
            FPages[4].ScrollY:=0;
          end;
          if I = 1 then
          begin
            SavedMemoText:=FMemo.Text;
            ExecuteAction(27);
            CaptureFrame(Format('memo-composition-theme-%d',[J]));
            FHost.Context.CancelInput;
            FMemo.Text:=SavedMemoText;
            FMemo.ClearSelection;
            FHost.Context.SetFocus(FMemo);
            FMemo.SetSelection(25, 170);
            CaptureFrame(Format('wrapped-selection-theme-%d', [J]));
            FHost.Context.SetFocus(FThemeSelect);
            FMemo.ClearSelection;
            SavedTooltipDelay:=FHost.Context.TooltipDelay;
            FHost.Context.TooltipDelay:=0;
            MenuEvent:=Default(TGuiEvent);
            MenuEvent.Kind:=gekMouseMove;
            MenuEvent.Position:=GuiPoint(FMemo.AbsoluteBounds.Left + 100, FMemo.AbsoluteBounds.Top + 30);
            FHost.Context.ProcessEvent(MenuEvent);
            CaptureFrame(Format('wrapped-tooltip-theme-%d', [J]));
            FHost.Context.TooltipDelay:=SavedTooltipDelay;
            FHost.Context.CancelInput;
          end;
          if I = 5 then
          begin
            FPages[I].ScrollY:=FPages[I].MaxScrollY;
            CaptureFrame(Format('bottom-tabs-theme-%d',[J]));
            FPages[I].ScrollY:=0;
            FHost.Context.SetFocus(FLabMenu);
            MenuEvent:=Default(TGuiEvent);
            MenuEvent.Kind:=gekKeyDown;
            MenuEvent.KeyCode:=$40000051;
            FLabMenu.HandleEvent(MenuEvent);
            MenuEvent.Handled:=False;
            FLabMenu.HandleEvent(MenuEvent);
            MenuEvent.KeyCode:=$4000004F;
            MenuEvent.Handled:=False;
            FLabMenu.HandleEvent(MenuEvent);
            CaptureFrame(Format('menus-theme-%d', [J]));
            FHost.Context.SetFocus(FThemeSelect);
            FLabPopup.PopupAt(GuiPoint(500, 350));
            CaptureFrame(Format('context-menu-theme-%d', [J]));
            MenuEvent:=Default(TGuiEvent);
            MenuEvent.Kind:=gekKeyDown;
            MenuEvent.KeyCode:=27;
            FLabPopup.HandleEvent(MenuEvent);
          end;
          if I = 6 then
          begin
            OpenDialog(False, False);
            WindowA:=TGuiDialog(FHost.Context.Layers[glkDialog].Children[FHost.Context.Layers[glkDialog].ChildCount - 1]);
            SetBoundsPosition(WindowA, 320, 200);
            OpenDialog(False, False);
            WindowB:=TGuiDialog(FHost.Context.Layers[glkDialog].Children[FHost.Context.Layers[glkDialog].ChildCount - 1]);
            SetBoundsPosition(WindowB, 520, 330);
            CaptureFrame(Format('dialog-windows-theme-%d', [J]));
            WindowB.Close;
            WindowA.Close;
          end;
        end;
      end;
    end;
    SelectPage(8);
    FCount.Value:=1000;
    ExecuteAction(60);
    Render;
    FReport.Add(Format('OBSERVATION: 1000-control frame submission %.2f ms (not a benchmark assertion)', [FRenderMs]));
    Check(FDynamic.ChildCount = 1000, 'Create and render 1000 dynamic controls');
    ExecuteAction(62);
    ExecuteAction(61);
    Check(FDynamic.ChildCount = 0, 'Clear stress controls');
    SelectPage(6);
    OpenDialog(True, True);
    Render;
    OpenDialog(True, False);
    Render;
    FHost.Context.CloseModal;
    FHost.Context.CloseModal;
    Check(FHost.Context.ModalControl = nil, 'Close nested modal stack');
    SelectPage(9);
    ExecuteAction(70);
    FileName:=CommandValue('report');
    if FileName <> '' then ExportReport(FileName);
    Result:=FFailures = 0;
    Writeln(Format('Test Lab finished: %d passed, %d failed.', [FPasses, FFailures]));
    Exit;
  end;
  FRunning:=True;
  while FRunning do
  begin
    while SDL_PollEvent(@Event) do
    begin
      Inc(FEvents);
      if TSDL_EventType(Event.type_) = SDL_EVENT_QUIT then FRunning:=False else FHost.ProcessEvent(Event);
    end;
    if FPending <> 0 then
    begin
      ActionCode:=FPending;
      FPending:=0;
      try
        ExecuteAction(ActionCode);
      except
        on E: Exception do
      begin
        Log('ERROR: ' + E.Message);
        Check(False, E.Message);
      end;
      end;
    end;
    Tick;
    Render;
    SDL_RenderPresent(FRenderer);
    Inc(FFrames);
    SDL_Delay(16);
  end;
  FileName:=CommandValue('report');
  if FileName <> '' then ExportReport(FileName);
  Result:=True;
end;

end.
