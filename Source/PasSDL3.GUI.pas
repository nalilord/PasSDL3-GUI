unit PasSDL3.GUI;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Resources,
  PasSDL3.GUI.Clipboard,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Core,
  PasSDL3.GUI.Context,
  PasSDL3.GUI.Controls.Base,
  PasSDL3.GUI.Controls.Containers,
  PasSDL3.GUI.Controls.Images,
  PasSDL3.GUI.Controls.Text,
  PasSDL3.GUI.Controls.Buttons,
  PasSDL3.GUI.Controls.Lists,
  PasSDL3.GUI.Controls.Range,
  PasSDL3.GUI.Controls.Progress,
  PasSDL3.GUI.Controls.Charts,
  PasSDL3.GUI.Controls.Pages,
  PasSDL3.GUI.Controls.Menus,
  PasSDL3.GUI.Controls.Bars,
  PasSDL3.GUI.Controls.Dialogs,
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Layout,
  PasSDL3.GUI.Fonts,
  PasSDL3.GUI.Fonts.SDLTTF,
  {$IFNDEF FPC}
  PasSDL3.GUI.Loader.XML,
  {$ENDIF}
  PasSDL3.GUI.Theme,
  PasSDL3.GUI.Theme.Files,
  PasSDL3.GUI.Host.SDL3;

type
  TGuiGroupBox = PasSDL3.GUI.Controls.Containers.TGuiGroupBox;
  TGuiStatusBar = PasSDL3.GUI.Controls.Bars.TGuiStatusBar;
  TGuiTransparentPanel = PasSDL3.GUI.Controls.Containers.TGuiTransparentPanel;
  TGuiTransparentStackPanel = PasSDL3.GUI.Controls.Containers.TGuiTransparentStackPanel;
  TGuiModalResult = PasSDL3.GUI.Controls.Dialogs.TGuiModalResult;
  TGuiDialogWindowMode = PasSDL3.GUI.Controls.Dialogs.TGuiDialogWindowMode;
  TGuiDialogButton = PasSDL3.GUI.Controls.Dialogs.TGuiDialogButton;
  TGuiDialogButtons = PasSDL3.GUI.Controls.Dialogs.TGuiDialogButtons;
  TGuiDialogState = PasSDL3.GUI.Controls.Dialogs.TGuiDialogState;
  TGuiDialog = PasSDL3.GUI.Controls.Dialogs.TGuiDialog;
  TGuiToggleSwitch = PasSDL3.GUI.Controls.Buttons.TGuiToggleSwitch;
  TGuiSeparator = PasSDL3.GUI.Controls.Bars.TGuiSeparator;
  TGuiFloat = PasSDL3.GUI.Types.TGuiFloat;
  TGuiPoint = PasSDL3.GUI.Types.TGuiPoint;
  TGuiSize = PasSDL3.GUI.Types.TGuiSize;
  TGuiRect = PasSDL3.GUI.Types.TGuiRect;
  TGuiBox = PasSDL3.GUI.Types.TGuiBox;
  TGuiColor = PasSDL3.GUI.Types.TGuiColor;
  TGuiTexture = PasSDL3.GUI.Types.TGuiTexture;
  TGuiBrushKind = PasSDL3.GUI.Types.TGuiBrushKind;
  TGuiBrush = PasSDL3.GUI.Types.TGuiBrush;
  TGuiDrawableKind = PasSDL3.GUI.Types.TGuiDrawableKind;
  TGuiDrawable = PasSDL3.GUI.Types.TGuiDrawable;
  TGuiMouseCursor = PasSDL3.GUI.Types.TGuiMouseCursor;
  TGuiAlign = PasSDL3.GUI.Types.TGuiAlign;
  TGuiAnchor = PasSDL3.GUI.Types.TGuiAnchor;
  TGuiAnchors = PasSDL3.GUI.Types.TGuiAnchors;
  TGuiHorizontalTextAlign = PasSDL3.GUI.Types.TGuiHorizontalTextAlign;
  TGuiVerticalTextAlign = PasSDL3.GUI.Types.TGuiVerticalTextAlign;
  TGuiOrientation = PasSDL3.GUI.Types.TGuiOrientation;
  TGuiControlVisualState = PasSDL3.GUI.Types.TGuiControlVisualState;
  TGuiControlVisualStates = PasSDL3.GUI.Types.TGuiControlVisualStates;
  TGuiStyle = PasSDL3.GUI.Types.TGuiStyle;
  TGuiEventKind = PasSDL3.GUI.Types.TGuiEventKind;
  TGuiMouseButton = PasSDL3.GUI.Types.TGuiMouseButton;
  TGuiEventModifier = PasSDL3.GUI.Types.TGuiEventModifier;
  TGuiEventModifiers = PasSDL3.GUI.Types.TGuiEventModifiers;
  TGuiEvent = PasSDL3.GUI.Types.TGuiEvent;
  TGuiControl = PasSDL3.GUI.Core.TGuiControl;
  TGuiContextServices = PasSDL3.GUI.Core.TGuiContextServices;
  TGuiInteractionStage = PasSDL3.GUI.Core.TGuiInteractionStage;
  TGuiPopupControl = PasSDL3.GUI.Core.TGuiPopupControl;
  TGuiContext = PasSDL3.GUI.Context.TGuiContext;
  TGuiPopupMenu = PasSDL3.GUI.Controls.Menus.TGuiPopupMenu;
  TGuiLayoutState = PasSDL3.GUI.Core.TGuiLayoutState;
  TGuiNotifyEvent = PasSDL3.GUI.Core.TGuiNotifyEvent;
  TGuiMouseEvent = PasSDL3.GUI.Core.TGuiMouseEvent;
  TGuiFocusChangedEvent = PasSDL3.GUI.Core.TGuiFocusChangedEvent;
  TGuiContainer = PasSDL3.GUI.Core.TGuiContainer;
  TGuiPanel = PasSDL3.GUI.Controls.Containers.TGuiPanel;
  TGuiFrame = PasSDL3.GUI.Controls.Containers.TGuiFrame;
  TGuiStackPanel = PasSDL3.GUI.Controls.Containers.TGuiStackPanel;
  TGuiGridPanel = PasSDL3.GUI.Controls.Containers.TGuiGridPanel;
  TGuiScrollBox = PasSDL3.GUI.Controls.Containers.TGuiScrollBox;
  TGuiLabel = PasSDL3.GUI.Controls.Text.TGuiLabel;
  TGuiLinkLabel = PasSDL3.GUI.Controls.Text.TGuiLinkLabel;
  TGuiImage = PasSDL3.GUI.Controls.Images.TGuiImage;
  TGuiImageFit = PasSDL3.GUI.Controls.Images.TGuiImageFit;
  TGuiIcon = PasSDL3.GUI.Controls.Images.TGuiIcon;
  TGuiValueLabel = PasSDL3.GUI.Controls.Text.TGuiValueLabel;
  TGuiEditState = PasSDL3.GUI.Controls.Text.TGuiEditState;
  TGuiEdit = PasSDL3.GUI.Controls.Text.TGuiEdit;
  TGuiListBox = PasSDL3.GUI.Controls.Lists.TGuiListBox;
  TGuiWheelWrapMode = PasSDL3.GUI.Controls.Lists.TGuiWheelWrapMode;
  TGuiWheelPicker = PasSDL3.GUI.Controls.Lists.TGuiWheelPicker;
  TGuiRadioGroup = PasSDL3.GUI.Controls.Lists.TGuiRadioGroup;
  TGuiMemo = PasSDL3.GUI.Controls.Text.TGuiMemo;
  TGuiTreeNode = PasSDL3.GUI.Controls.Lists.TGuiTreeNode;
  TGuiTreeView = PasSDL3.GUI.Controls.Lists.TGuiTreeView;
  TGuiHeaderControl = PasSDL3.GUI.Controls.Lists.TGuiHeaderControl;
  TGuiSortDirection = PasSDL3.GUI.Controls.Lists.TGuiSortDirection;
  TGuiColumnSortKind = PasSDL3.GUI.Controls.Lists.TGuiColumnSortKind;
  TGuiIndexArray = PasSDL3.GUI.Controls.Lists.TGuiIndexArray;
  TGuiColumnEvent = PasSDL3.GUI.Controls.Lists.TGuiColumnEvent;
  TGuiCompareRowsEvent = PasSDL3.GUI.Controls.Lists.TGuiCompareRowsEvent;
  TGuiListView = PasSDL3.GUI.Controls.Lists.TGuiListView;
  TGuiItemTemplate = PasSDL3.GUI.Controls.Lists.TGuiItemTemplate;
  TGuiIconPlacement = PasSDL3.GUI.Controls.Buttons.TGuiIconPlacement;
  TGuiButton = PasSDL3.GUI.Controls.Buttons.TGuiButton;
  TGuiDelayButton = PasSDL3.GUI.Controls.Buttons.TGuiDelayButton;
  TGuiRoundButton = PasSDL3.GUI.Controls.Buttons.TGuiRoundButton;
  TGuiSpeedButton = PasSDL3.GUI.Controls.Buttons.TGuiSpeedButton;
  TGuiTabButton = PasSDL3.GUI.Controls.Pages.TGuiTabButton;
  TGuiCheckBoxState = PasSDL3.GUI.Controls.Buttons.TGuiCheckBoxState;
  TGuiNextCheckStateEvent = PasSDL3.GUI.Controls.Buttons.TGuiNextCheckStateEvent;
  TGuiCheckBox = PasSDL3.GUI.Controls.Buttons.TGuiCheckBox;
  TGuiItemCheckEvent = PasSDL3.GUI.Controls.Lists.TGuiItemCheckEvent;
  TGuiCheckListBox = PasSDL3.GUI.Controls.Lists.TGuiCheckListBox;
  TGuiSwitchListBox = PasSDL3.GUI.Controls.Lists.TGuiSwitchListBox;
  TGuiRadioButton = PasSDL3.GUI.Controls.Buttons.TGuiRadioButton;
  TGuiModalOverlay = PasSDL3.GUI.Controls.Dialogs.TGuiModalOverlay;
  TGuiToolBar = PasSDL3.GUI.Controls.Bars.TGuiToolBar;
  TGuiCommandBar = PasSDL3.GUI.Controls.Bars.TGuiCommandBar;
  TGuiSplitter = PasSDL3.GUI.Controls.Containers.TGuiSplitter;
  TGuiSnapMode = PasSDL3.GUI.Controls.Range.TGuiSnapMode;
  TGuiSlider = PasSDL3.GUI.Controls.Range.TGuiSlider;
  TGuiRangeThumb = PasSDL3.GUI.Controls.Range.TGuiRangeThumb;
  TGuiRangeMovedEvent = PasSDL3.GUI.Controls.Range.TGuiRangeMovedEvent;
  TGuiRangeSlider = PasSDL3.GUI.Controls.Range.TGuiRangeSlider;
  TGuiKnobInputMode = PasSDL3.GUI.Controls.Range.TGuiKnobInputMode;
  TGuiWrapDirection = PasSDL3.GUI.Controls.Range.TGuiWrapDirection;
  TGuiKnobWrapEvent = PasSDL3.GUI.Controls.Range.TGuiKnobWrapEvent;
  TGuiKnob = PasSDL3.GUI.Controls.Range.TGuiKnob;
  TGuiScrollBar = PasSDL3.GUI.Controls.Range.TGuiScrollBar;
  TGuiActivityIndicator = PasSDL3.GUI.Controls.Progress.TGuiActivityIndicator;
  TGuiProgressBar = PasSDL3.GUI.Controls.Progress.TGuiProgressBar;
  TGuiDialGauge = PasSDL3.GUI.Controls.Charts.TGuiDialGauge;
  TGuiScopeMarker = PasSDL3.GUI.Controls.Charts.TGuiScopeMarker;
  TGuiScope = PasSDL3.GUI.Controls.Charts.TGuiScope;
  TGuiSpinEdit = PasSDL3.GUI.Controls.Text.TGuiSpinEdit;
  TGuiComboBox = PasSDL3.GUI.Controls.Lists.TGuiComboBox;
  TGuiDropDownButton = PasSDL3.GUI.Controls.Menus.TGuiDropDownButton;
  TGuiPageIndicator = PasSDL3.GUI.Controls.Pages.TGuiPageIndicator;
  TGuiTabPosition = PasSDL3.GUI.Controls.Pages.TGuiTabPosition;
  TGuiTabControl = PasSDL3.GUI.Controls.Pages.TGuiTabControl;
  TGuiPage = PasSDL3.GUI.Controls.Pages.TGuiPage;
  TGuiPageControl = PasSDL3.GUI.Controls.Pages.TGuiPageControl;
  TGuiMenuItem = PasSDL3.GUI.Controls.Menus.TGuiMenuItem;
  TGuiMenuBar = PasSDL3.GUI.Controls.Menus.TGuiMenuBar;
  TGuiToggleButton = PasSDL3.GUI.Controls.Buttons.TGuiToggleButton;
  TGuiLayerControl = PasSDL3.GUI.Context.TGuiLayerControl;
  TGuiLayerKind = PasSDL3.GUI.Context.TGuiLayerKind;
  TGuiResourceRegion = PasSDL3.GUI.Resources.TGuiResourceRegion;
  TGuiResourceCatalog = PasSDL3.GUI.Resources.TGuiResourceCatalog;
  TGuiTextRow = PasSDL3.GUI.Renderer.Canvas.TGuiTextRow;
  TGuiTextRows = PasSDL3.GUI.Renderer.Canvas.TGuiTextRows;
  TGuiCanvas = PasSDL3.GUI.Renderer.Canvas.TGuiCanvas;
  TGuiFontWeight = PasSDL3.GUI.Fonts.TGuiFontWeight;
  TGuiFontSlant = PasSDL3.GUI.Fonts.TGuiFontSlant;
  TGuiFontSpec = PasSDL3.GUI.Fonts.TGuiFontSpec;
  TGuiTextCacheEntry = PasSDL3.GUI.Fonts.SDLTTF.TGuiTextCacheEntry;
  TGuiSDLTTFFontEntry = PasSDL3.GUI.Fonts.SDLTTF.TGuiSDLTTFFontEntry;
  TGuiSDLTTFFontRenderer = PasSDL3.GUI.Fonts.SDLTTF.TGuiSDLTTFFontRenderer;
  TGuiSDLTTFFontCollection = PasSDL3.GUI.Fonts.SDLTTF.TGuiSDLTTFFontCollection;
  TGuiThemeRole = PasSDL3.GUI.Theme.TGuiThemeRole;
  TGuiThemeMetrics = PasSDL3.GUI.Theme.TGuiThemeMetrics;
  TGuiTheme = PasSDL3.GUI.Theme.TGuiTheme;
  TGuiSDL3Host = PasSDL3.GUI.Host.SDL3.TGuiSDL3Host;
  {$IFNDEF FPC}
  TGuiXmlLoader = PasSDL3.GUI.Loader.XML.TGuiXmlLoader;
  {$ENDIF}

const
  gmrNone = PasSDL3.GUI.Controls.Dialogs.gmrNone;
  gmrOk = PasSDL3.GUI.Controls.Dialogs.gmrOk;
  gmrCancel = PasSDL3.GUI.Controls.Dialogs.gmrCancel;
  gmrClose = PasSDL3.GUI.Controls.Dialogs.gmrClose;
  gmrYes = PasSDL3.GUI.Controls.Dialogs.gmrYes;
  gmrNo = PasSDL3.GUI.Controls.Dialogs.gmrNo;
  gmrCustom = PasSDL3.GUI.Controls.Dialogs.gmrCustom;
  gdwmEmbedded = PasSDL3.GUI.Controls.Dialogs.gdwmEmbedded;
  gdwmFixed = PasSDL3.GUI.Controls.Dialogs.gdwmFixed;
  gdwmMovable = PasSDL3.GUI.Controls.Dialogs.gdwmMovable;
  gdwmResizable = PasSDL3.GUI.Controls.Dialogs.gdwmResizable;
  gdbMinimize = PasSDL3.GUI.Controls.Dialogs.gdbMinimize;
  gdbMaximize = PasSDL3.GUI.Controls.Dialogs.gdbMaximize;
  gdbClose = PasSDL3.GUI.Controls.Dialogs.gdbClose;
  gdsNormal = PasSDL3.GUI.Controls.Dialogs.gdsNormal;
  gdsMinimized = PasSDL3.GUI.Controls.Dialogs.gdsMinimized;
  gdsMaximized = PasSDL3.GUI.Controls.Dialogs.gdsMaximized;
  gbkNone = PasSDL3.GUI.Types.gbkNone;
  gbkColor = PasSDL3.GUI.Types.gbkColor;
  gbkTexture = PasSDL3.GUI.Types.gbkTexture;
  gdkNone = PasSDL3.GUI.Types.gdkNone;
  gdkBrush = PasSDL3.GUI.Types.gdkBrush;
  gdkImage = PasSDL3.GUI.Types.gdkImage;
  gdkNineSlice = PasSDL3.GUI.Types.gdkNineSlice;
  gdkLinearGradient = PasSDL3.GUI.Types.gdkLinearGradient;
  gmcAuto = PasSDL3.GUI.Types.gmcAuto;
  gmcArrow = PasSDL3.GUI.Types.gmcArrow;
  gmcText = PasSDL3.GUI.Types.gmcText;
  gmcHand = PasSDL3.GUI.Types.gmcHand;
  gmcMove = PasSDL3.GUI.Types.gmcMove;
  gmcSizeWE = PasSDL3.GUI.Types.gmcSizeWE;
  gmcSizeNS = PasSDL3.GUI.Types.gmcSizeNS;
  gmcSizeNWSE = PasSDL3.GUI.Types.gmcSizeNWSE;
  gmcSizeNESW = PasSDL3.GUI.Types.gmcSizeNESW;
  gaNone = PasSDL3.GUI.Types.gaNone;
  gaTop = PasSDL3.GUI.Types.gaTop;
  gaBottom = PasSDL3.GUI.Types.gaBottom;
  gaLeft = PasSDL3.GUI.Types.gaLeft;
  gaRight = PasSDL3.GUI.Types.gaRight;
  gaClient = PasSDL3.GUI.Types.gaClient;
  ganLeft = PasSDL3.GUI.Types.ganLeft;
  ganTop = PasSDL3.GUI.Types.ganTop;
  ganRight = PasSDL3.GUI.Types.ganRight;
  ganBottom = PasSDL3.GUI.Types.ganBottom;
  ghtaLeft = PasSDL3.GUI.Types.ghtaLeft;
  ghtaCenter = PasSDL3.GUI.Types.ghtaCenter;
  ghtaRight = PasSDL3.GUI.Types.ghtaRight;
  gvtaTop = PasSDL3.GUI.Types.gvtaTop;
  gvtaCenter = PasSDL3.GUI.Types.gvtaCenter;
  gvtaBottom = PasSDL3.GUI.Types.gvtaBottom;
  goHorizontal = PasSDL3.GUI.Types.goHorizontal;
  goVertical = PasSDL3.GUI.Types.goVertical;
  gcvsNormal = PasSDL3.GUI.Types.gcvsNormal;
  gcvsHovered = PasSDL3.GUI.Types.gcvsHovered;
  gcvsPressed = PasSDL3.GUI.Types.gcvsPressed;
  gcvsFocused = PasSDL3.GUI.Types.gcvsFocused;
  gcvsDisabled = PasSDL3.GUI.Types.gcvsDisabled;
  gcvsChecked = PasSDL3.GUI.Types.gcvsChecked;
  gekNone = PasSDL3.GUI.Types.gekNone;
  gekMouseMove = PasSDL3.GUI.Types.gekMouseMove;
  gekMouseDown = PasSDL3.GUI.Types.gekMouseDown;
  gekMouseUp = PasSDL3.GUI.Types.gekMouseUp;
  gekMouseWheel = PasSDL3.GUI.Types.gekMouseWheel;
  gekMouseEnter = PasSDL3.GUI.Types.gekMouseEnter;
  gekMouseLeave = PasSDL3.GUI.Types.gekMouseLeave;
  gekKeyDown = PasSDL3.GUI.Types.gekKeyDown;
  gekKeyUp = PasSDL3.GUI.Types.gekKeyUp;
  gekTextInput = PasSDL3.GUI.Types.gekTextInput;
  gekFocus = PasSDL3.GUI.Types.gekFocus;
  gekBlur = PasSDL3.GUI.Types.gekBlur;
  gekGamepadButtonDown = PasSDL3.GUI.Types.gekGamepadButtonDown;
  gekGamepadButtonUp = PasSDL3.GUI.Types.gekGamepadButtonUp;
  gekGamepadAxis = PasSDL3.GUI.Types.gekGamepadAxis;
  gekTextEditing = PasSDL3.GUI.Types.gekTextEditing;
  gekCancel = PasSDL3.GUI.Types.gekCancel;
  gmbNone = PasSDL3.GUI.Types.gmbNone;
  gmbLeft = PasSDL3.GUI.Types.gmbLeft;
  gmbMiddle = PasSDL3.GUI.Types.gmbMiddle;
  gmbRight = PasSDL3.GUI.Types.gmbRight;
  gemShift = PasSDL3.GUI.Types.gemShift;
  gemCtrl = PasSDL3.GUI.Types.gemCtrl;
  gemAlt = PasSDL3.GUI.Types.gemAlt;
  gifStretch = PasSDL3.GUI.Controls.Images.gifStretch;
  gifContain = PasSDL3.GUI.Controls.Images.gifContain;
  gifCover = PasSDL3.GUI.Controls.Images.gifCover;
  gwwAuto = PasSDL3.GUI.Controls.Lists.gwwAuto;
  gwwEnabled = PasSDL3.GUI.Controls.Lists.gwwEnabled;
  gwwDisabled = PasSDL3.GUI.Controls.Lists.gwwDisabled;
  gsdAscending = PasSDL3.GUI.Controls.Lists.gsdAscending;
  gsdDescending = PasSDL3.GUI.Controls.Lists.gsdDescending;
  gcskText = PasSDL3.GUI.Controls.Lists.gcskText;
  gcskNumber = PasSDL3.GUI.Controls.Lists.gcskNumber;
  gipLeft = PasSDL3.GUI.Controls.Buttons.gipLeft;
  gipRight = PasSDL3.GUI.Controls.Buttons.gipRight;
  gipTop = PasSDL3.GUI.Controls.Buttons.gipTop;
  gipBottom = PasSDL3.GUI.Controls.Buttons.gipBottom;
  gcbUnchecked = PasSDL3.GUI.Controls.Buttons.gcbUnchecked;
  gcbChecked = PasSDL3.GUI.Controls.Buttons.gcbChecked;
  gcbGrayed = PasSDL3.GUI.Controls.Buttons.gcbGrayed;
  gsmNoSnap = PasSDL3.GUI.Controls.Range.gsmNoSnap;
  gsmSnapAlways = PasSDL3.GUI.Controls.Range.gsmSnapAlways;
  gsmSnapOnRelease = PasSDL3.GUI.Controls.Range.gsmSnapOnRelease;
  grtLower = PasSDL3.GUI.Controls.Range.grtLower;
  grtUpper = PasSDL3.GUI.Controls.Range.grtUpper;
  gkiCircular = PasSDL3.GUI.Controls.Range.gkiCircular;
  gkiHorizontal = PasSDL3.GUI.Controls.Range.gkiHorizontal;
  gkiVertical = PasSDL3.GUI.Controls.Range.gkiVertical;
  gwdClockwise = PasSDL3.GUI.Controls.Range.gwdClockwise;
  gwdCounterClockwise = PasSDL3.GUI.Controls.Range.gwdCounterClockwise;
  gtpTop = PasSDL3.GUI.Controls.Pages.gtpTop;
  gtpBottom = PasSDL3.GUI.Controls.Pages.gtpBottom;
  glkWorld = PasSDL3.GUI.Context.glkWorld;
  glkHud = PasSDL3.GUI.Context.glkHud;
  glkDialog = PasSDL3.GUI.Context.glkDialog;
  glkPopup = PasSDL3.GUI.Context.glkPopup;
  glkDebug = PasSDL3.GUI.Context.glkDebug;
  gfwRegular = PasSDL3.GUI.Fonts.gfwRegular;
  gfwMedium = PasSDL3.GUI.Fonts.gfwMedium;
  gfwSemiBold = PasSDL3.GUI.Fonts.gfwSemiBold;
  gfwBold = PasSDL3.GUI.Fonts.gfwBold;
  gfsNormal = PasSDL3.GUI.Fonts.gfsNormal;
  gfsItalic = PasSDL3.GUI.Fonts.gfsItalic;
  gtrWindow = PasSDL3.GUI.Theme.gtrWindow;
  gtrPanel = PasSDL3.GUI.Theme.gtrPanel;
  gtrSurface = PasSDL3.GUI.Theme.gtrSurface;
  gtrCard = PasSDL3.GUI.Theme.gtrCard;
  gtrLabel = PasSDL3.GUI.Theme.gtrLabel;
  gtrLinkLabel = PasSDL3.GUI.Theme.gtrLinkLabel;
  gtrMutedLabel = PasSDL3.GUI.Theme.gtrMutedLabel;
  gtrPriceLabel = PasSDL3.GUI.Theme.gtrPriceLabel;
  gtrSuccessLabel = PasSDL3.GUI.Theme.gtrSuccessLabel;
  gtrButton = PasSDL3.GUI.Theme.gtrButton;
  gtrEdit = PasSDL3.GUI.Theme.gtrEdit;
  gtrMemo = PasSDL3.GUI.Theme.gtrMemo;
  gtrListBox = PasSDL3.GUI.Theme.gtrListBox;
  gtrListView = PasSDL3.GUI.Theme.gtrListView;
  gtrHeaderControl = PasSDL3.GUI.Theme.gtrHeaderControl;
  gtrTreeView = PasSDL3.GUI.Theme.gtrTreeView;
  gtrSlider = PasSDL3.GUI.Theme.gtrSlider;
  gtrScrollBar = PasSDL3.GUI.Theme.gtrScrollBar;
  gtrSplitter = PasSDL3.GUI.Theme.gtrSplitter;
  gtrProgressBar = PasSDL3.GUI.Theme.gtrProgressBar;
  gtrSpinEdit = PasSDL3.GUI.Theme.gtrSpinEdit;
  gtrComboBox = PasSDL3.GUI.Theme.gtrComboBox;
  gtrTabControl = PasSDL3.GUI.Theme.gtrTabControl;
  gtrPageControl = PasSDL3.GUI.Theme.gtrPageControl;
  gtrMenuBar = PasSDL3.GUI.Theme.gtrMenuBar;
  gtrPrimaryButton = PasSDL3.GUI.Theme.gtrPrimaryButton;
  gtrQuietButton = PasSDL3.GUI.Theme.gtrQuietButton;

function GuiPoint(AX, AY: TGuiFloat): TGuiPoint;
function GuiSize(AWidth, AHeight: TGuiFloat): TGuiSize;
function GuiRect(ALeft, ATop, AWidth, AHeight: TGuiFloat): TGuiRect;
function GuiBox(AValue: TGuiFloat): TGuiBox;
function GuiBoxLTRB(ALeft, ATop, ARight, ABottom: TGuiFloat): TGuiBox;
function GuiColor(ARed, AGreen, ABlue: Byte; AAlpha: Byte = 255): TGuiColor;
function GuiMixColor(const AFrom, ATo: TGuiColor; AAmount: TGuiFloat): TGuiColor;
function GuiEmptyBrush: TGuiBrush;
function GuiColorBrush(const AColor: TGuiColor): TGuiBrush;
function GuiTextureBrush(ATexture: TGuiTexture): TGuiBrush;
function GuiEmptyDrawable: TGuiDrawable;
function GuiBrushDrawable(const ABrush: TGuiBrush): TGuiDrawable;
function GuiColorDrawable(const AColor: TGuiColor): TGuiDrawable;
function GuiGradientDrawable(const ATop, ABottom: TGuiColor): TGuiDrawable;
function GuiImageDrawable(ATexture: TGuiTexture; const ASourceRect: TGuiRect): TGuiDrawable;
function GuiNineSliceDrawable(ATexture: TGuiTexture; const ASourceRect: TGuiRect; const ASlice: TGuiBox): TGuiDrawable;
function GuiButtonStyle: TGuiStyle;
procedure GuiUpdateStyleDrawables(var AStyle: TGuiStyle);
function GuiResolveBackgroundColor(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiColor;
function GuiResolveBackgroundDrawable(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiDrawable;
function GuiResolveBorderColor(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiColor;
function GuiResolveTextColor(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiColor;
function GuiInflateRect(const ARect: TGuiRect; const ABox: TGuiBox): TGuiRect;
function GuiRectContains(const ARect: TGuiRect; const APoint: TGuiPoint): Boolean;
function GuiScrollThumbLength(AViewportLength, AContentLength, ATrackLength,
  AMinLength: TGuiFloat): TGuiFloat;
function GuiScrollOffsetFromThumbDelta(ADelta, ATrackLength, AThumbLength,
  AMaxScroll: TGuiFloat): TGuiFloat;
function GuiScrollTrackRect(const ABounds: TGuiRect; AOrientation: TGuiOrientation;
  ASize: TGuiFloat; AStartInset: TGuiFloat = 4;
  AEndInset: TGuiFloat = 4): TGuiRect;
function GuiVerticalScrollThumbRect(const ATrack: TGuiRect;
  AViewport, AContent, AOffset: TGuiFloat): TGuiRect;

implementation

function GuiPoint(AX, AY: TGuiFloat): TGuiPoint;
begin
  Result:=PasSDL3.GUI.Types.GuiPoint(AX, AY);
end;

function GuiSize(AWidth, AHeight: TGuiFloat): TGuiSize;
begin
  Result:=PasSDL3.GUI.Types.GuiSize(AWidth, AHeight);
end;

function GuiRect(ALeft, ATop, AWidth, AHeight: TGuiFloat): TGuiRect;
begin
  Result:=PasSDL3.GUI.Types.GuiRect(ALeft, ATop, AWidth, AHeight);
end;

function GuiBox(AValue: TGuiFloat): TGuiBox;
begin
  Result:=PasSDL3.GUI.Types.GuiBox(AValue);
end;

function GuiBoxLTRB(ALeft, ATop, ARight, ABottom: TGuiFloat): TGuiBox;
begin
  Result:=PasSDL3.GUI.Types.GuiBoxLTRB(ALeft, ATop, ARight, ABottom);
end;

function GuiColor(ARed, AGreen, ABlue: Byte; AAlpha: Byte): TGuiColor;
begin
  Result:=PasSDL3.GUI.Types.GuiColor(ARed, AGreen, ABlue, AAlpha);
end;

function GuiMixColor(const AFrom, ATo: TGuiColor; AAmount: TGuiFloat): TGuiColor;
begin
  Result:=PasSDL3.GUI.Types.GuiMixColor(AFrom, ATo, AAmount);
end;

function GuiEmptyBrush: TGuiBrush;
begin
  Result:=PasSDL3.GUI.Types.GuiEmptyBrush;
end;

function GuiColorBrush(const AColor: TGuiColor): TGuiBrush;
begin
  Result:=PasSDL3.GUI.Types.GuiColorBrush(AColor);
end;

function GuiTextureBrush(ATexture: TGuiTexture): TGuiBrush;
begin
  Result:=PasSDL3.GUI.Types.GuiTextureBrush(ATexture);
end;

function GuiEmptyDrawable: TGuiDrawable;
begin
  Result:=PasSDL3.GUI.Types.GuiEmptyDrawable;
end;

function GuiBrushDrawable(const ABrush: TGuiBrush): TGuiDrawable;
begin
  Result:=PasSDL3.GUI.Types.GuiBrushDrawable(ABrush);
end;

function GuiColorDrawable(const AColor: TGuiColor): TGuiDrawable;
begin
  Result:=PasSDL3.GUI.Types.GuiColorDrawable(AColor);
end;

function GuiGradientDrawable(const ATop, ABottom: TGuiColor): TGuiDrawable;
begin
  Result:=PasSDL3.GUI.Types.GuiGradientDrawable(ATop, ABottom);
end;

function GuiImageDrawable(ATexture: TGuiTexture; const ASourceRect: TGuiRect): TGuiDrawable;
begin
  Result:=PasSDL3.GUI.Types.GuiImageDrawable(ATexture, ASourceRect);
end;

function GuiNineSliceDrawable(ATexture: TGuiTexture; const ASourceRect: TGuiRect; const ASlice: TGuiBox): TGuiDrawable;
begin
  Result:=PasSDL3.GUI.Types.GuiNineSliceDrawable(ATexture, ASourceRect, ASlice);
end;

function GuiButtonStyle: TGuiStyle;
begin
  Result:=PasSDL3.GUI.Types.GuiButtonStyle;
end;

procedure GuiUpdateStyleDrawables(var AStyle: TGuiStyle);
begin
  PasSDL3.GUI.Types.GuiUpdateStyleDrawables(AStyle);
end;

function GuiResolveBackgroundColor(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiColor;
begin
  Result:=PasSDL3.GUI.Types.GuiResolveBackgroundColor(AStyle, AStates);
end;

function GuiResolveBackgroundDrawable(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiDrawable;
begin
  Result:=PasSDL3.GUI.Types.GuiResolveBackgroundDrawable(AStyle, AStates);
end;

function GuiResolveBorderColor(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiColor;
begin
  Result:=PasSDL3.GUI.Types.GuiResolveBorderColor(AStyle, AStates);
end;

function GuiResolveTextColor(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiColor;
begin
  Result:=PasSDL3.GUI.Types.GuiResolveTextColor(AStyle, AStates);
end;

function GuiInflateRect(const ARect: TGuiRect; const ABox: TGuiBox): TGuiRect;
begin
  Result:=PasSDL3.GUI.Types.GuiInflateRect(ARect, ABox);
end;

function GuiRectContains(const ARect: TGuiRect; const APoint: TGuiPoint): Boolean;
begin
  Result:=PasSDL3.GUI.Types.GuiRectContains(ARect, APoint);
end;

function GuiScrollThumbLength(AViewportLength, AContentLength, ATrackLength,
  AMinLength: TGuiFloat): TGuiFloat;
begin
  Result:=PasSDL3.GUI.Core.GuiScrollThumbLength(
    AViewportLength, AContentLength, ATrackLength, AMinLength);
end;

function GuiScrollOffsetFromThumbDelta(ADelta, ATrackLength, AThumbLength,
  AMaxScroll: TGuiFloat): TGuiFloat;
begin
  Result:=PasSDL3.GUI.Core.GuiScrollOffsetFromThumbDelta(
    ADelta, ATrackLength, AThumbLength, AMaxScroll);
end;

function GuiScrollTrackRect(const ABounds: TGuiRect; AOrientation: TGuiOrientation;
  ASize, AStartInset, AEndInset: TGuiFloat): TGuiRect;
begin
  Result:=PasSDL3.GUI.Core.GuiScrollTrackRect(
    ABounds, AOrientation, ASize, AStartInset, AEndInset);
end;

function GuiVerticalScrollThumbRect(const ATrack: TGuiRect;
  AViewport, AContent, AOffset: TGuiFloat): TGuiRect;
begin
  Result:=PasSDL3.GUI.Core.GuiVerticalScrollThumbRect(
    ATrack, AViewport, AContent, AOffset);
end;

end.
