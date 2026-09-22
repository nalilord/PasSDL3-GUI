unit PasSDL3.GUI.Theme;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  PasSDL3.GUI.Types;

type
  TGuiThemeRole = (
    gtrWindow,
    gtrPanel,
    gtrSurface,
    gtrCard,
    gtrLabel,
    gtrLinkLabel,
    gtrMutedLabel,
    gtrPriceLabel,
    gtrSuccessLabel,
    gtrButton,
    gtrEdit,
    gtrMemo,
    gtrListBox,
    gtrListView,
    gtrHeaderControl,
    gtrTreeView,
    gtrSlider,
    gtrScrollBar,
    gtrSplitter,
    gtrProgressBar,
    gtrSpinEdit,
    gtrComboBox,
    gtrTabControl,
    gtrPageControl,
    gtrMenuBar,
    gtrPrimaryButton,
    gtrQuietButton
  );

  TGuiThemeMetrics = record
  private
    FSpacing: TGuiFloat;
    FSmallSpacing: TGuiFloat;
    FLargeSpacing: TGuiFloat;
    FControlHeight: TGuiFloat;
    FCompactControlHeight: TGuiFloat;
    FItemHeight: TGuiFloat;
    FRowHeight: TGuiFloat;
    FHeaderHeight: TGuiFloat;
    FLineHeight: TGuiFloat;
    FScrollBarSize: TGuiFloat;
    FControlCornerRadius: TGuiFloat;
    FPanelCornerRadius: TGuiFloat;
    FFocusWidth: TGuiFloat;
    FControlPadding: TGuiBox;
    FTextPadding: TGuiBox;
    FButtonPadding: TGuiBox;
    FCheckPadding: TGuiBox;
  public
    property Spacing: TGuiFloat read FSpacing write FSpacing;
    property SmallSpacing: TGuiFloat read FSmallSpacing write FSmallSpacing;
    property LargeSpacing: TGuiFloat read FLargeSpacing write FLargeSpacing;
    property ControlHeight: TGuiFloat read FControlHeight write FControlHeight;
    property CompactControlHeight: TGuiFloat read FCompactControlHeight write FCompactControlHeight;
    property ItemHeight: TGuiFloat read FItemHeight write FItemHeight;
    property RowHeight: TGuiFloat read FRowHeight write FRowHeight;
    property HeaderHeight: TGuiFloat read FHeaderHeight write FHeaderHeight;
    property LineHeight: TGuiFloat read FLineHeight write FLineHeight;
    property ScrollBarSize: TGuiFloat read FScrollBarSize write FScrollBarSize;
    property ControlCornerRadius: TGuiFloat read FControlCornerRadius write FControlCornerRadius;
    property PanelCornerRadius: TGuiFloat read FPanelCornerRadius write FPanelCornerRadius;
    property FocusWidth: TGuiFloat read FFocusWidth write FFocusWidth;
    property ControlPadding: TGuiBox read FControlPadding write FControlPadding;
    property TextPadding: TGuiBox read FTextPadding write FTextPadding;
    property ButtonPadding: TGuiBox read FButtonPadding write FButtonPadding;
    property CheckPadding: TGuiBox read FCheckPadding write FCheckPadding;
  end;

  TGuiTheme = record
  private
    FWindowBackground: TGuiColor;
    FPanelBackground: TGuiColor;
    FPanelBorder: TGuiColor;
    FSurfaceBackground: TGuiColor;
    FCardBackground: TGuiColor;
    FCardBorder: TGuiColor;
    FControlBackground: TGuiColor;
    FControlBorder: TGuiColor;
    FPrimaryAccent: TGuiColor;
    FSecondaryAccent: TGuiColor;
    FFocusAccent: TGuiColor;
    FText: TGuiColor;
    FMutedText: TGuiColor;
    FPriceText: TGuiColor;
    FSuccessText: TGuiColor;
    FControlTextOffset: TGuiPoint;
    FControlBorderWidth: TGuiFloat;
    FSurfaceGradientStrength: TGuiFloat;
    FMetrics: TGuiThemeMetrics;
  public
    property WindowBackground: TGuiColor read FWindowBackground write FWindowBackground;
    property PanelBackground: TGuiColor read FPanelBackground write FPanelBackground;
    property PanelBorder: TGuiColor read FPanelBorder write FPanelBorder;
    property SurfaceBackground: TGuiColor read FSurfaceBackground write FSurfaceBackground;
    property CardBackground: TGuiColor read FCardBackground write FCardBackground;
    property CardBorder: TGuiColor read FCardBorder write FCardBorder;
    property ControlBackground: TGuiColor read FControlBackground write FControlBackground;
    property ControlBorder: TGuiColor read FControlBorder write FControlBorder;
    property PrimaryAccent: TGuiColor read FPrimaryAccent write FPrimaryAccent;
    property SecondaryAccent: TGuiColor read FSecondaryAccent write FSecondaryAccent;
    property FocusAccent: TGuiColor read FFocusAccent write FFocusAccent;
    property Text: TGuiColor read FText write FText;
    property MutedText: TGuiColor read FMutedText write FMutedText;
    property PriceText: TGuiColor read FPriceText write FPriceText;
    property SuccessText: TGuiColor read FSuccessText write FSuccessText;
    property ControlTextOffset: TGuiPoint read FControlTextOffset write FControlTextOffset;
    property ControlBorderWidth: TGuiFloat read FControlBorderWidth write FControlBorderWidth;
    property SurfaceGradientStrength: TGuiFloat read FSurfaceGradientStrength write FSurfaceGradientStrength;
    property Metrics: TGuiThemeMetrics read FMetrics write FMetrics;
  end;

function GuiDefaultThemeMetrics: TGuiThemeMetrics;
function GuiDarkTheme: TGuiTheme;
function GuiReactorTheme: TGuiTheme;
function GuiThemeStyle(const ATheme: TGuiTheme; ARole: TGuiThemeRole): TGuiStyle;
function GuiThemeTextOffset(const ATheme: TGuiTheme; ARole: TGuiThemeRole): TGuiPoint;
procedure GuiApplyThemeMetrics(AControl: TObject; const ATheme: TGuiTheme; ARole: TGuiThemeRole);
procedure GuiApplyTheme(AControl: TObject; const ATheme: TGuiTheme);

implementation

uses
  PasSDL3.GUI.Core,
  PasSDL3.GUI.Controls.Containers,
  PasSDL3.GUI.Controls.Text,
  PasSDL3.GUI.Controls.Buttons,
  PasSDL3.GUI.Controls.Lists,
  PasSDL3.GUI.Controls.Pages,
  PasSDL3.GUI.Controls.Menus,
  PasSDL3.GUI.Controls.Range,
  PasSDL3.GUI.Controls.Progress;

function GuiDefaultThemeMetrics: TGuiThemeMetrics;
begin
  Result.Spacing:=8;
  Result.SmallSpacing:=4;
  Result.LargeSpacing:=16;
  Result.ControlHeight:=34;
  Result.CompactControlHeight:=28;
  Result.ItemHeight:=28;
  Result.RowHeight:=28;
  Result.HeaderHeight:=30;
  Result.LineHeight:=24;
  Result.ScrollBarSize:=12;
  Result.ControlCornerRadius:=6;
  Result.PanelCornerRadius:=8;
  Result.FocusWidth:=2;
  Result.ControlPadding:=GuiBoxLTRB(8, 4, 8, 4);
  Result.TextPadding:=GuiBoxLTRB(8, 4, 8, 4);
  Result.ButtonPadding:=GuiBoxLTRB(10, 4, 10, 4);
  Result.CheckPadding:=GuiBoxLTRB(30, 4, 8, 4);
end;

function GuiDarkTheme: TGuiTheme;
begin
  Result.WindowBackground:=GuiColor(18, 21, 27);
  Result.PanelBackground:=GuiColor(25, 29, 37);
  Result.PanelBorder:=GuiColor(43, 49, 60);
  Result.SurfaceBackground:=GuiColor(21, 25, 32);
  Result.CardBackground:=GuiColor(31, 36, 45);
  Result.CardBorder:=GuiColor(49, 57, 69);
  Result.ControlBackground:=GuiColor(43, 51, 64);
  Result.ControlBorder:=GuiColor(72, 83, 100);
  Result.PrimaryAccent:=GuiColor(99, 194, 174);
  Result.SecondaryAccent:=GuiColor(140, 181, 245);
  Result.FocusAccent:=GuiColor(140, 181, 245);
  Result.Text:=GuiColor(232, 237, 245);
  Result.MutedText:=GuiColor(145, 158, 178);
  Result.PriceText:=GuiColor(255, 214, 102);
  Result.SuccessText:=GuiColor(136, 224, 190);
  Result.ControlTextOffset:=GuiPoint(0, 0);
  Result.ControlBorderWidth:=1;
  Result.SurfaceGradientStrength:=0.06;
  Result.Metrics:=GuiDefaultThemeMetrics;
end;

function GuiReactorTheme: TGuiTheme;
begin
  Result.WindowBackground:=GuiColor(2, 10, 13);
  Result.PanelBackground:=GuiColor(7, 21, 27, 232);
  Result.PanelBorder:=GuiColor(25, 190, 208, 220);
  Result.SurfaceBackground:=GuiColor(4, 17, 22, 235);
  Result.CardBackground:=GuiColor(7, 27, 34, 238);
  Result.CardBorder:=GuiColor(37, 226, 202, 230);
  Result.ControlBackground:=GuiColor(8, 31, 40, 238);
  Result.ControlBorder:=GuiColor(33, 151, 174, 230);
  Result.PrimaryAccent:=GuiColor(84, 239, 165);
  Result.SecondaryAccent:=GuiColor(50, 207, 230);
  Result.FocusAccent:=GuiColor(245, 212, 87);
  Result.Text:=GuiColor(218, 247, 247);
  Result.MutedText:=GuiColor(91, 151, 160);
  Result.PriceText:=GuiColor(245, 212, 87);
  Result.SuccessText:=GuiColor(84, 239, 165);
  Result.ControlTextOffset:=GuiPoint(0, 0);
  Result.ControlBorderWidth:=1;
  Result.SurfaceGradientStrength:=0.025;
  Result.Metrics:=GuiDefaultThemeMetrics;
  Result.FMetrics.ControlHeight:=30;
  Result.FMetrics.ControlCornerRadius:=0;
  Result.FMetrics.PanelCornerRadius:=0;
  Result.FMetrics.CompactControlHeight:=24;
  Result.FMetrics.ItemHeight:=26;
  Result.FMetrics.RowHeight:=26;
  Result.FMetrics.HeaderHeight:=26;
  Result.FMetrics.LineHeight:=22;
  Result.FMetrics.ButtonPadding:=GuiBoxLTRB(8, 3, 8, 3);
end;

function GuiThemeStyle(const ATheme: TGuiTheme; ARole: TGuiThemeRole): TGuiStyle;
var
  MixedColor: TGuiColor;
  function Surface(const AColor: TGuiColor; APressed: Boolean = False): TGuiDrawable;
  var TopColor, BottomColor: TGuiColor;
  begin
    Result:=GuiColorDrawable(AColor);
    if (ATheme.SurfaceGradientStrength <= 0) OR (AColor.A = 0) then Exit;
    TopColor:=GuiMixColor(AColor, GuiColor(255, 255, 255, AColor.A), ATheme.SurfaceGradientStrength);
    BottomColor:=GuiMixColor(AColor, GuiColor(0, 0, 0, AColor.A), ATheme.SurfaceGradientStrength);
    if APressed then Result:=GuiGradientDrawable(BottomColor, AColor)
    else Result:=GuiGradientDrawable(TopColor, BottomColor);
  end;
begin
  Result:=GuiButtonStyle;
  Result.FocusWidth:=ATheme.Metrics.FocusWidth;
  Result.ScrollBarSize:=ATheme.Metrics.ScrollBarSize;
  Result.ScrollTrackColor:=GuiMixColor(ATheme.SurfaceBackground, ATheme.PanelBackground, 0.5);
  Result.ScrollThumbColor:=GuiMixColor(ATheme.ControlBorder, ATheme.MutedText, 0.4);
  Result.ScrollHoverColor:=ATheme.MutedText;
  Result.ScrollPressedColor:=ATheme.PrimaryAccent;
  Result.CornerRadius:=ATheme.Metrics.ControlCornerRadius;
  Result.BorderWidth:=ATheme.ControlBorderWidth;
  Result.FocusedBorderColor:=ATheme.FocusAccent;

  case ARole of
    gtrWindow:
    begin
      Result.BackgroundColor:=ATheme.WindowBackground;
      Result.HoverBackgroundColor:=ATheme.WindowBackground;
      Result.PressedBackgroundColor:=ATheme.WindowBackground;
      Result.CheckedBackgroundColor:=ATheme.WindowBackground;
      Result.BorderColor:=GuiColor(0, 0, 0, 0);
      Result.CheckedBorderColor:=GuiColor(0, 0, 0, 0);
      Result.TextColor:=ATheme.Text;
      Result.DisabledTextColor:=ATheme.MutedText;
    end;

    gtrPanel:
    begin
      Result.BackgroundColor:=ATheme.PanelBackground;
      Result.HoverBackgroundColor:=ATheme.PanelBackground;
      Result.PressedBackgroundColor:=ATheme.PanelBackground;
      Result.CheckedBackgroundColor:=ATheme.PanelBackground;
      Result.BorderColor:=ATheme.PanelBorder;
      Result.CheckedBorderColor:=ATheme.PanelBorder;
      Result.TextColor:=ATheme.Text;
      Result.DisabledTextColor:=ATheme.MutedText;
    end;

    gtrSurface:
    begin
      Result.BackgroundColor:=ATheme.SurfaceBackground;
      Result.HoverBackgroundColor:=ATheme.SurfaceBackground;
      Result.PressedBackgroundColor:=ATheme.SurfaceBackground;
      Result.CheckedBackgroundColor:=ATheme.SurfaceBackground;
      Result.BorderColor:=ATheme.PanelBorder;
      Result.CheckedBorderColor:=ATheme.PanelBorder;
      Result.TextColor:=ATheme.Text;
      Result.DisabledTextColor:=ATheme.MutedText;
    end;

    gtrCard:
    begin
      Result.BackgroundColor:=ATheme.CardBackground;
      Result.HoverBackgroundColor:=ATheme.CardBackground;
      Result.PressedBackgroundColor:=ATheme.CardBackground;
      Result.CheckedBackgroundColor:=ATheme.CardBackground;
      Result.BorderColor:=ATheme.CardBorder;
      Result.CheckedBorderColor:=ATheme.CardBorder;
      Result.TextColor:=ATheme.Text;
      Result.DisabledTextColor:=ATheme.MutedText;
    end;

    gtrLabel:
    begin
      Result.BackgroundColor:=GuiColor(0, 0, 0, 0);
      Result.HoverBackgroundColor:=GuiColor(0, 0, 0, 0);
      Result.PressedBackgroundColor:=GuiColor(0, 0, 0, 0);
      Result.CheckedBackgroundColor:=GuiColor(0, 0, 0, 0);
      Result.BorderColor:=GuiColor(0, 0, 0, 0);
      Result.CheckedBorderColor:=GuiColor(0, 0, 0, 0);
      Result.TextColor:=ATheme.Text;
      Result.DisabledTextColor:=ATheme.MutedText;
    end;

    gtrMutedLabel:
    begin
      Result:=GuiThemeStyle(ATheme, gtrLabel);
      Result.TextColor:=ATheme.MutedText;
    end;

    gtrLinkLabel:
    begin
      Result:=GuiThemeStyle(ATheme, gtrLabel);
      Result.TextColor:=ATheme.SecondaryAccent;
      Result.CheckedBorderColor:=ATheme.PrimaryAccent;
      Result.FocusedBorderColor:=ATheme.FocusAccent;
    end;

    gtrPriceLabel:
    begin
      Result:=GuiThemeStyle(ATheme, gtrLabel);
      Result.TextColor:=ATheme.PriceText;
    end;

    gtrSuccessLabel:
    begin
      Result:=GuiThemeStyle(ATheme, gtrLabel);
      Result.TextColor:=ATheme.SuccessText;
    end;

    gtrPrimaryButton:
    begin
      Result:=GuiThemeStyle(ATheme, gtrButton);
      Result.BackgroundColor:=ATheme.PrimaryAccent;
      Result.HoverBackgroundColor:=GuiMixColor(ATheme.PrimaryAccent, ATheme.Text, 0.15);
      Result.PressedBackgroundColor:=GuiMixColor(ATheme.PrimaryAccent, ATheme.WindowBackground, 0.18);
      Result.CheckedBackgroundColor:=Result.PressedBackgroundColor;
      Result.TextColor:=ATheme.WindowBackground;
      Result.BorderColor:=ATheme.PrimaryAccent;
    end;

    gtrQuietButton:
    begin
      Result:=GuiThemeStyle(ATheme, gtrButton);
      Result.BackgroundColor:=GuiColor(0, 0, 0, 0);
      Result.BorderColor:=GuiColor(0, 0, 0, 0);
    end;

    gtrButton:
    begin
      Result.BackgroundColor:=ATheme.ControlBackground;
      Result.HoverBackgroundColor:=GuiMixColor(ATheme.ControlBackground, ATheme.Text, 0.08);
      Result.PressedBackgroundColor:=GuiMixColor(ATheme.ControlBackground, ATheme.WindowBackground, 0.4);
      Result.CheckedBackgroundColor:=GuiMixColor(ATheme.ControlBackground, ATheme.PrimaryAccent, 0.22);
      Result.BorderColor:=ATheme.ControlBorder;
      Result.CheckedBorderColor:=ATheme.PrimaryAccent;
      Result.FocusedBorderColor:=ATheme.FocusAccent;
      Result.TextColor:=ATheme.Text;
      Result.DisabledTextColor:=ATheme.MutedText;
    end;

    gtrEdit,
    gtrMemo,
    gtrListBox,
    gtrListView,
    gtrHeaderControl,
    gtrTreeView,
    gtrSlider,
    gtrScrollBar,
    gtrSplitter,
    gtrProgressBar,
    gtrSpinEdit,
    gtrComboBox,
    gtrTabControl,
    gtrPageControl,
    gtrMenuBar:
    begin
      Result.BackgroundColor:=ATheme.SurfaceBackground;
      Result.HoverBackgroundColor:=GuiMixColor(ATheme.SurfaceBackground, ATheme.Text, 0.05);
      Result.PressedBackgroundColor:=ATheme.WindowBackground;
      Result.CheckedBackgroundColor:=GuiMixColor(ATheme.SurfaceBackground, ATheme.PrimaryAccent, 0.22);
      Result.BorderColor:=ATheme.ControlBorder;
      Result.CheckedBorderColor:=ATheme.PrimaryAccent;
      Result.FocusedBorderColor:=ATheme.FocusAccent;
      Result.TextColor:=ATheme.Text;
      Result.DisabledTextColor:=ATheme.MutedText;
    end;
  end;

  case ARole of
    gtrWindow, gtrLabel, gtrLinkLabel, gtrMutedLabel, gtrPriceLabel,
    gtrSuccessLabel, gtrHeaderControl, gtrSplitter, gtrMenuBar:
      Result.CornerRadius:=0;
    gtrPanel, gtrSurface, gtrCard, gtrPageControl:
      Result.CornerRadius:=ATheme.Metrics.PanelCornerRadius;
  end;
  GuiUpdateStyleDrawables(Result);
  if ARole IN [gtrButton, gtrPrimaryButton, gtrQuietButton] then
  begin
    Result.Background:=Surface(Result.BackgroundColor);
    Result.HoverBackground:=Surface(Result.HoverBackgroundColor);
    Result.PressedBackground:=Surface(Result.PressedBackgroundColor, True);
    Result.CheckedBackground:=Surface(Result.CheckedBackgroundColor);
  end;
  if ARole IN [gtrListBox, gtrTreeView, gtrListView, gtrComboBox] then
    Result.Selection:=Surface(Result.CheckedBackgroundColor);
  MixedColor:=GuiMixColor(ATheme.SurfaceBackground, ATheme.ControlBackground, 0.3);
  MixedColor.A:=Result.BackgroundColor.A;
  Result.DisabledBackgroundColor:=MixedColor;
  MixedColor:=GuiMixColor(Result.BorderColor, ATheme.Text, 0.25);
  MixedColor.A:=Result.BorderColor.A;
  Result.HoverBorderColor:=MixedColor;
end;

function GuiThemeTextOffset(const ATheme: TGuiTheme; ARole: TGuiThemeRole): TGuiPoint;
begin
  Result:=GuiPoint(0, 0);

  case ARole of
    gtrButton,
    gtrPrimaryButton,
    gtrQuietButton,
    gtrEdit,
    gtrMemo,
    gtrListBox,
    gtrListView,
    gtrHeaderControl,
    gtrTreeView,
    gtrProgressBar,
    gtrSpinEdit,
    gtrComboBox,
    gtrTabControl,
    gtrPageControl,
    gtrMenuBar:
      Result:=ATheme.ControlTextOffset;
  end;
end;

procedure GuiApplyThemeMetrics(AControl: TObject; const ATheme: TGuiTheme; ARole: TGuiThemeRole);
var
  Control: TGuiControl;
begin
  if NOT (AControl IS TGuiControl) then
    Exit;

  Control:=TGuiControl(AControl);

  case ARole of
    gtrButton, gtrPrimaryButton, gtrQuietButton:
      if Control IS TGuiButton then
      begin
        if Control IS TGuiRoundButton then
          TGuiButton(Control).Padding:=GuiBox(4)
        else if Control IS TGuiTabButton then
          TGuiButton(Control).Padding:=ATheme.Metrics.ButtonPadding
        else if Control IS TGuiSpeedButton then
          TGuiButton(Control).Padding:=GuiBox(4)
        else if (Control IS TGuiCheckBox) OR (Control IS TGuiRadioButton) then
          TGuiButton(Control).Padding:=ATheme.Metrics.CheckPadding
        else
          TGuiButton(Control).Padding:=ATheme.Metrics.ButtonPadding;
      end;

    gtrEdit:
      if Control IS TGuiEdit then
        TGuiEdit(Control).Padding:=ATheme.Metrics.TextPadding;

    gtrMemo:
      if Control IS TGuiMemo then
      begin
        TGuiMemo(Control).Padding:=ATheme.Metrics.TextPadding;
        TGuiMemo(Control).LineHeight:=ATheme.Metrics.LineHeight;
      end;

    gtrListBox:
      if Control IS TGuiListBox then
      begin
        TGuiListBox(Control).Padding:=ATheme.Metrics.ControlPadding;
        TGuiListBox(Control).ItemHeight:=ATheme.Metrics.ItemHeight;
      end;

    gtrTreeView:
      if Control IS TGuiTreeView then
      begin
        TGuiTreeView(Control).Padding:=ATheme.Metrics.ControlPadding;
        TGuiTreeView(Control).ItemHeight:=ATheme.Metrics.ItemHeight;
      end;

    gtrListView:
      if Control IS TGuiListView then
      begin
        TGuiListView(Control).Padding:=GuiBox(ATheme.Metrics.SmallSpacing);
        TGuiListView(Control).RowHeight:=ATheme.Metrics.RowHeight;
        TGuiListView(Control).HeaderHeight:=ATheme.Metrics.HeaderHeight;
      end;

    gtrSpinEdit:
      if Control IS TGuiSpinEdit then
        TGuiSpinEdit(Control).Padding:=ATheme.Metrics.TextPadding;

    gtrComboBox:
      if Control IS TGuiComboBox then
      begin
        TGuiComboBox(Control).Padding:=ATheme.Metrics.TextPadding;
        TGuiComboBox(Control).ItemHeight:=ATheme.Metrics.ItemHeight;
      end;

    gtrTabControl:
      if Control IS TGuiTabControl then
        TGuiTabControl(Control).Padding:=ATheme.Metrics.ControlPadding;
  end;
end;

procedure GuiApplyTheme(AControl: TObject; const ATheme: TGuiTheme);
var
  Control: TGuiControl;
  I: Integer;
  Role: TGuiThemeRole;
  CurrentStyle: TGuiStyle;
begin
  if NOT (AControl IS TGuiControl) then
    Exit;

  Control:=TGuiControl(AControl);

  if Control.StyleClass = 'Window' then
    Role:=gtrWindow
  else
  if Control.StyleClass = 'Surface' then
    Role:=gtrSurface
  else
  if Control.StyleClass = 'Card' then
    Role:=gtrCard
  else
  if Control.StyleClass = 'Muted' then
    Role:=gtrMutedLabel
  else
  if Control.StyleClass = 'Price' then
    Role:=gtrPriceLabel
  else
  if Control.StyleClass = 'Success' then
    Role:=gtrSuccessLabel
  else
  if (Control IS TGuiButton) AND (Control.StyleClass = 'Primary') then
    Role:=gtrPrimaryButton
  else
  if (Control IS TGuiButton) AND (Control.StyleClass = 'Quiet') then
    Role:=gtrQuietButton
  else
  if Control IS TGuiButton then
    Role:=gtrButton
  else
  if Control IS TGuiLinkLabel then
    Role:=gtrLinkLabel
  else
  if Control IS TGuiMemo then
    Role:=gtrMemo
  else
  if (Control IS TGuiEdit) AND NOT (Control IS TGuiSpinEdit) AND NOT (Control IS TGuiComboBox) then
    Role:=gtrEdit
  else
  if (Control IS TGuiListBox) OR (Control IS TGuiWheelPicker) then
    Role:=gtrListBox
  else
  if Control IS TGuiListView then
    Role:=gtrListView
  else
  if Control IS TGuiHeaderControl then
    Role:=gtrHeaderControl
  else
  if Control IS TGuiTreeView then
    Role:=gtrTreeView
  else
  if (Control IS TGuiSlider) OR (Control IS TGuiRangeSlider) then
    Role:=gtrSlider
  else
  if Control IS TGuiScrollBar then
    Role:=gtrScrollBar
  else
  if Control IS TGuiSplitter then
    Role:=gtrSplitter
  else
  if (Control IS TGuiProgressBar) OR (Control IS TGuiActivityIndicator) then
    Role:=gtrProgressBar
  else
  if Control IS TGuiSpinEdit then
    Role:=gtrSpinEdit
  else
  if Control IS TGuiComboBox then
    Role:=gtrComboBox
  else
  if (Control IS TGuiTabControl) OR (Control IS TGuiPageIndicator) then
    Role:=gtrTabControl
  else
  if Control IS TGuiPageControl then
    Role:=gtrPageControl
  else
  if Control IS TGuiMenuBar then
    Role:=gtrMenuBar
  else
  if Control IS TGuiLabel then
    Role:=gtrLabel
  else
  if Control IS TGuiPanel then
    Role:=gtrPanel
  else
    Role:=gtrPanel;

  Control.Style:=GuiThemeStyle(ATheme, Role);
  Control.BackgroundColor:=Control.Style.BackgroundColor;
  Control.BorderColor:=Control.Style.BorderColor;
  Control.TextColor:=Control.Style.TextColor;
  Control.TextOffset:=GuiThemeTextOffset(ATheme, Role);
  CurrentStyle:=Control.Style;
  CurrentStyle.BorderWidth:=ATheme.ControlBorderWidth;
  Control.Style:=CurrentStyle;

  if Control IS TGuiFrame then
  begin
    TGuiFrame(Control).HeaderColor:=ATheme.CardBackground;
    TGuiFrame(Control).FooterColor:=ATheme.SurfaceBackground;
    TGuiFrame(Control).HeaderTextColor:=ATheme.SuccessText;
  end;

  GuiApplyThemeMetrics(Control, ATheme, Role);

  for I:=0 to Control.ChildCount - 1 do
    GuiApplyTheme(Control.Children[I], ATheme);
end;

end.
