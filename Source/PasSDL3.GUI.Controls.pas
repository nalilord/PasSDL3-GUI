unit PasSDL3.GUI.Controls;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
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
  PasSDL3.GUI.Context;

type
  TGuiLayoutState = PasSDL3.GUI.Controls.Base.TGuiLayoutState;
  TGuiContextServices = PasSDL3.GUI.Controls.Base.TGuiContextServices;
  TGuiInteractionStage = PasSDL3.GUI.Controls.Base.TGuiInteractionStage;
  TGuiControl = PasSDL3.GUI.Controls.Base.TGuiControl;
  TGuiContainer = PasSDL3.GUI.Controls.Base.TGuiContainer;
  TGuiPopupControl = PasSDL3.GUI.Controls.Base.TGuiPopupControl;
  TGuiContext = PasSDL3.GUI.Context.TGuiContext;
  TGuiLayerKind = PasSDL3.GUI.Context.TGuiLayerKind;
  TGuiLayerControl = PasSDL3.GUI.Context.TGuiLayerControl;
  TGuiNotifyEvent = PasSDL3.GUI.Controls.Base.TGuiNotifyEvent;
  TGuiMouseEvent = PasSDL3.GUI.Controls.Base.TGuiMouseEvent;
  TGuiFocusChangedEvent = PasSDL3.GUI.Controls.Base.TGuiFocusChangedEvent;
  TGuiPanel = PasSDL3.GUI.Controls.Containers.TGuiPanel;
  TGuiFrame = PasSDL3.GUI.Controls.Containers.TGuiFrame;
  TGuiStackPanel = PasSDL3.GUI.Controls.Containers.TGuiStackPanel;
  TGuiGridPanel = PasSDL3.GUI.Controls.Containers.TGuiGridPanel;
  TGuiScrollBox = PasSDL3.GUI.Controls.Containers.TGuiScrollBox;
  TGuiGroupBox = PasSDL3.GUI.Controls.Containers.TGuiGroupBox;
  TGuiTransparentPanel = PasSDL3.GUI.Controls.Containers.TGuiTransparentPanel;
  TGuiTransparentStackPanel = PasSDL3.GUI.Controls.Containers.TGuiTransparentStackPanel;
  TGuiSplitter = PasSDL3.GUI.Controls.Containers.TGuiSplitter;
  TGuiLabel = PasSDL3.GUI.Controls.Text.TGuiLabel;
  TGuiLinkLabel = PasSDL3.GUI.Controls.Text.TGuiLinkLabel;
  TGuiImageFit = PasSDL3.GUI.Controls.Images.TGuiImageFit;
  TGuiImage = PasSDL3.GUI.Controls.Images.TGuiImage;
  TGuiIcon = PasSDL3.GUI.Controls.Images.TGuiIcon;
  TGuiValueLabel = PasSDL3.GUI.Controls.Text.TGuiValueLabel;
  TGuiEditState = PasSDL3.GUI.Controls.Text.TGuiEditState;
  TGuiEdit = PasSDL3.GUI.Controls.Text.TGuiEdit;
  TGuiMemo = PasSDL3.GUI.Controls.Text.TGuiMemo;
  TGuiSpinEdit = PasSDL3.GUI.Controls.Text.TGuiSpinEdit;
  TGuiIconPlacement = PasSDL3.GUI.Controls.Buttons.TGuiIconPlacement;
  TGuiButton = PasSDL3.GUI.Controls.Buttons.TGuiButton;
  TGuiDelayButton = PasSDL3.GUI.Controls.Buttons.TGuiDelayButton;
  TGuiRoundButton = PasSDL3.GUI.Controls.Buttons.TGuiRoundButton;
  TGuiSpeedButton = PasSDL3.GUI.Controls.Buttons.TGuiSpeedButton;
  TGuiTabButton = PasSDL3.GUI.Controls.Pages.TGuiTabButton;
  TGuiToggleButton = PasSDL3.GUI.Controls.Buttons.TGuiToggleButton;
  TGuiToggleSwitch = PasSDL3.GUI.Controls.Buttons.TGuiToggleSwitch;
  TGuiCheckBox = PasSDL3.GUI.Controls.Buttons.TGuiCheckBox;
  TGuiCheckBoxState = PasSDL3.GUI.Controls.Buttons.TGuiCheckBoxState;
  TGuiNextCheckStateEvent = PasSDL3.GUI.Controls.Buttons.TGuiNextCheckStateEvent;
  TGuiRadioButton = PasSDL3.GUI.Controls.Buttons.TGuiRadioButton;
  TGuiDropDownButton = PasSDL3.GUI.Controls.Menus.TGuiDropDownButton;
  TGuiListBox = PasSDL3.GUI.Controls.Lists.TGuiListBox;
  TGuiWheelPicker = PasSDL3.GUI.Controls.Lists.TGuiWheelPicker;
  TGuiWheelWrapMode = PasSDL3.GUI.Controls.Lists.TGuiWheelWrapMode;
  TGuiCheckListBox = PasSDL3.GUI.Controls.Lists.TGuiCheckListBox;
  TGuiSwitchListBox = PasSDL3.GUI.Controls.Lists.TGuiSwitchListBox;
  TGuiItemCheckEvent = PasSDL3.GUI.Controls.Lists.TGuiItemCheckEvent;
  TGuiRadioGroup = PasSDL3.GUI.Controls.Lists.TGuiRadioGroup;
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
  TGuiComboBox = PasSDL3.GUI.Controls.Lists.TGuiComboBox;
  TGuiSlider = PasSDL3.GUI.Controls.Range.TGuiSlider;
  TGuiRangeSlider = PasSDL3.GUI.Controls.Range.TGuiRangeSlider;
  TGuiRangeThumb = PasSDL3.GUI.Controls.Range.TGuiRangeThumb;
  TGuiRangeMovedEvent = PasSDL3.GUI.Controls.Range.TGuiRangeMovedEvent;
  TGuiKnob = PasSDL3.GUI.Controls.Range.TGuiKnob;
  TGuiKnobInputMode = PasSDL3.GUI.Controls.Range.TGuiKnobInputMode;
  TGuiWrapDirection = PasSDL3.GUI.Controls.Range.TGuiWrapDirection;
  TGuiKnobWrapEvent = PasSDL3.GUI.Controls.Range.TGuiKnobWrapEvent;
  TGuiSnapMode = PasSDL3.GUI.Controls.Range.TGuiSnapMode;
  TGuiScrollBar = PasSDL3.GUI.Controls.Range.TGuiScrollBar;
  TGuiProgressBar = PasSDL3.GUI.Controls.Progress.TGuiProgressBar;
  TGuiActivityIndicator = PasSDL3.GUI.Controls.Progress.TGuiActivityIndicator;
  TGuiDialGauge = PasSDL3.GUI.Controls.Charts.TGuiDialGauge;
  TGuiScopeMarker = PasSDL3.GUI.Controls.Charts.TGuiScopeMarker;
  TGuiScope = PasSDL3.GUI.Controls.Charts.TGuiScope;
  TGuiTabControl = PasSDL3.GUI.Controls.Pages.TGuiTabControl;
  TGuiTabPosition = PasSDL3.GUI.Controls.Pages.TGuiTabPosition;
  TGuiPageIndicator = PasSDL3.GUI.Controls.Pages.TGuiPageIndicator;
  TGuiPage = PasSDL3.GUI.Controls.Pages.TGuiPage;
  TGuiPageControl = PasSDL3.GUI.Controls.Pages.TGuiPageControl;
  TGuiMenuItem = PasSDL3.GUI.Controls.Menus.TGuiMenuItem;
  TGuiMenuBar = PasSDL3.GUI.Controls.Menus.TGuiMenuBar;
  TGuiPopupMenu = PasSDL3.GUI.Controls.Menus.TGuiPopupMenu;
  TGuiToolBar = PasSDL3.GUI.Controls.Bars.TGuiToolBar;
  TGuiCommandBar = PasSDL3.GUI.Controls.Bars.TGuiCommandBar;
  TGuiSeparator = PasSDL3.GUI.Controls.Bars.TGuiSeparator;
  TGuiStatusBar = PasSDL3.GUI.Controls.Bars.TGuiStatusBar;
  TGuiModalResult = PasSDL3.GUI.Controls.Dialogs.TGuiModalResult;
  TGuiDialogWindowMode = PasSDL3.GUI.Controls.Dialogs.TGuiDialogWindowMode;
  TGuiDialogButton = PasSDL3.GUI.Controls.Dialogs.TGuiDialogButton;
  TGuiDialogButtons = PasSDL3.GUI.Controls.Dialogs.TGuiDialogButtons;
  TGuiDialogState = PasSDL3.GUI.Controls.Dialogs.TGuiDialogState;
  TGuiDialog = PasSDL3.GUI.Controls.Dialogs.TGuiDialog;
  TGuiModalOverlay = PasSDL3.GUI.Controls.Dialogs.TGuiModalOverlay;

const
  glkWorld = PasSDL3.GUI.Context.glkWorld;
  glkHud = PasSDL3.GUI.Context.glkHud;
  glkDialog = PasSDL3.GUI.Context.glkDialog;
  glkPopup = PasSDL3.GUI.Context.glkPopup;
  glkDebug = PasSDL3.GUI.Context.glkDebug;
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

implementation

end.
