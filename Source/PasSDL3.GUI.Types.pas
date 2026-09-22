unit PasSDL3.GUI.Types;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

type
  TGuiFloat = Single;

  TGuiPoint = record
  private
    FX: TGuiFloat;
    FY: TGuiFloat;
  public
    property X: TGuiFloat read FX write FX;
    property Y: TGuiFloat read FY write FY;
  end;

  TGuiSize = record
  private
    FWidth: TGuiFloat;
    FHeight: TGuiFloat;
  public
    property Width: TGuiFloat read FWidth write FWidth;
    property Height: TGuiFloat read FHeight write FHeight;
  end;

  TGuiRect = record
  private
    FLeft: TGuiFloat;
    FTop: TGuiFloat;
    FWidth: TGuiFloat;
    FHeight: TGuiFloat;
  public
    property Left: TGuiFloat read FLeft write FLeft;
    property Top: TGuiFloat read FTop write FTop;
    property Width: TGuiFloat read FWidth write FWidth;
    property Height: TGuiFloat read FHeight write FHeight;
  end;

  TGuiBox = record
  private
    FLeft: TGuiFloat;
    FTop: TGuiFloat;
    FRight: TGuiFloat;
    FBottom: TGuiFloat;
  public
    property Left: TGuiFloat read FLeft write FLeft;
    property Top: TGuiFloat read FTop write FTop;
    property Right: TGuiFloat read FRight write FRight;
    property Bottom: TGuiFloat read FBottom write FBottom;
  end;

  TGuiColor = record
  private
    FR: Byte;
    FG: Byte;
    FB: Byte;
    FA: Byte;
  public
    property R: Byte read FR write FR;
    property G: Byte read FG write FG;
    property B: Byte read FB write FB;
    property A: Byte read FA write FA;
  end;

  TGuiTexture = Pointer;

  TGuiBrushKind = (
    gbkNone,
    gbkColor,
    gbkTexture
  );

  TGuiBrush = record
  private
    FKind: TGuiBrushKind;
    FColor: TGuiColor;
    FTexture: TGuiTexture;
  public
    property Kind: TGuiBrushKind read FKind write FKind;
    property Color: TGuiColor read FColor write FColor;
    property Texture: TGuiTexture read FTexture write FTexture;
  end;

  TGuiDrawableKind = (
    gdkNone,
    gdkBrush,
    gdkImage,
    gdkNineSlice,
    gdkLinearGradient
  );

  TGuiDrawable = record
  private
    FKind: TGuiDrawableKind;
    FBrush: TGuiBrush;
    FTexture: TGuiTexture;
    FSourceRect: TGuiRect;
    FSlice: TGuiBox;
    FGradientEnd: TGuiColor;
  public
    property Kind: TGuiDrawableKind read FKind write FKind;
    property Brush: TGuiBrush read FBrush write FBrush;
    property Texture: TGuiTexture read FTexture write FTexture;
    property SourceRect: TGuiRect read FSourceRect write FSourceRect;
    property Slice: TGuiBox read FSlice write FSlice;
    property GradientEnd: TGuiColor read FGradientEnd write FGradientEnd;
  end;

  TGuiMouseCursor = (gmcAuto, gmcArrow, gmcText, gmcHand, gmcMove,
    gmcSizeWE, gmcSizeNS, gmcSizeNWSE, gmcSizeNESW);

  TGuiAlign = (
    gaNone,
    gaTop,
    gaBottom,
    gaLeft,
    gaRight,
    gaClient
  );

  TGuiAnchor = (
    ganLeft,
    ganTop,
    ganRight,
    ganBottom
  );

  TGuiAnchors = set of TGuiAnchor;

  TGuiHorizontalTextAlign = (
    ghtaLeft,
    ghtaCenter,
    ghtaRight
  );

  TGuiVerticalTextAlign = (
    gvtaTop,
    gvtaCenter,
    gvtaBottom
  );

  TGuiOrientation = (
    goHorizontal,
    goVertical
  );

  TGuiControlVisualState = (
    gcvsNormal,
    gcvsHovered,
    gcvsPressed,
    gcvsFocused,
    gcvsDisabled,
    gcvsChecked
  );

  TGuiControlVisualStates = set of TGuiControlVisualState;

  TGuiStyle = record
  private
    FBackground: TGuiDrawable;
    FHoverBackground: TGuiDrawable;
    FPressedBackground: TGuiDrawable;
    FCheckedBackground: TGuiDrawable;
    FSelection: TGuiDrawable;
    FTrack: TGuiDrawable;
    FThumb: TGuiDrawable;
    FBackgroundColor: TGuiColor;
    FHoverBackgroundColor: TGuiColor;
    FPressedBackgroundColor: TGuiColor;
    FCheckedBackgroundColor: TGuiColor;
    FDisabledBackgroundColor: TGuiColor;
    FBorderColor: TGuiColor;
    FHoverBorderColor: TGuiColor;
    FCheckedBorderColor: TGuiColor;
    FFocusedBorderColor: TGuiColor;
    FTextColor: TGuiColor;
    FDisabledTextColor: TGuiColor;
    FTextOffset: TGuiPoint;
    FBorderWidth: TGuiFloat;
    FCornerRadius: TGuiFloat;
    FFocusWidth: TGuiFloat;
    FScrollBarSize: TGuiFloat;
    FScrollTrackColor: TGuiColor;
    FScrollThumbColor: TGuiColor;
    FScrollHoverColor: TGuiColor;
    FScrollPressedColor: TGuiColor;
  public
    property Background: TGuiDrawable read FBackground write FBackground;
    property HoverBackground: TGuiDrawable read FHoverBackground write FHoverBackground;
    property PressedBackground: TGuiDrawable read FPressedBackground write FPressedBackground;
    property CheckedBackground: TGuiDrawable read FCheckedBackground write FCheckedBackground;
    property Selection: TGuiDrawable read FSelection write FSelection;
    property Track: TGuiDrawable read FTrack write FTrack;
    property Thumb: TGuiDrawable read FThumb write FThumb;
    property BackgroundColor: TGuiColor read FBackgroundColor write FBackgroundColor;
    property HoverBackgroundColor: TGuiColor read FHoverBackgroundColor write FHoverBackgroundColor;
    property PressedBackgroundColor: TGuiColor read FPressedBackgroundColor write FPressedBackgroundColor;
    property CheckedBackgroundColor: TGuiColor read FCheckedBackgroundColor write FCheckedBackgroundColor;
    property DisabledBackgroundColor: TGuiColor read FDisabledBackgroundColor write FDisabledBackgroundColor;
    property BorderColor: TGuiColor read FBorderColor write FBorderColor;
    property HoverBorderColor: TGuiColor read FHoverBorderColor write FHoverBorderColor;
    property CheckedBorderColor: TGuiColor read FCheckedBorderColor write FCheckedBorderColor;
    property FocusedBorderColor: TGuiColor read FFocusedBorderColor write FFocusedBorderColor;
    property TextColor: TGuiColor read FTextColor write FTextColor;
    property DisabledTextColor: TGuiColor read FDisabledTextColor write FDisabledTextColor;
    property TextOffset: TGuiPoint read FTextOffset write FTextOffset;
    property BorderWidth: TGuiFloat read FBorderWidth write FBorderWidth;
    property CornerRadius: TGuiFloat read FCornerRadius write FCornerRadius;
    property FocusWidth: TGuiFloat read FFocusWidth write FFocusWidth;
    property ScrollBarSize: TGuiFloat read FScrollBarSize write FScrollBarSize;
    property ScrollTrackColor: TGuiColor read FScrollTrackColor write FScrollTrackColor;
    property ScrollThumbColor: TGuiColor read FScrollThumbColor write FScrollThumbColor;
    property ScrollHoverColor: TGuiColor read FScrollHoverColor write FScrollHoverColor;
    property ScrollPressedColor: TGuiColor read FScrollPressedColor write FScrollPressedColor;
  end;

  TGuiEventKind = (
    gekNone,
    gekMouseMove,
    gekMouseDown,
    gekMouseUp,
    gekMouseWheel,
    gekMouseEnter,
    gekMouseLeave,
    gekKeyDown,
    gekKeyUp,
    gekTextInput,
    gekFocus,
    gekBlur,
    gekGamepadButtonDown,
    gekGamepadButtonUp,
    gekGamepadAxis,
    gekTextEditing,
    gekCancel
  );

  TGuiMouseButton = (
    gmbNone,
    gmbLeft,
    gmbMiddle,
    gmbRight
  );

  TGuiEventModifier = (
    gemShift,
    gemCtrl,
    gemAlt
  );

  TGuiEventModifiers = set of TGuiEventModifier;

  TGuiEvent = record
  private
    FKind: TGuiEventKind;
    FPosition: TGuiPoint;
    FDelta: TGuiPoint;
    FButton: TGuiMouseButton;
    FClicks: Integer;
    FKeyCode: Integer;
    FKeyRepeat: Boolean;
    FModifiers: TGuiEventModifiers;
    FText: UTF8String;
    FHasCompositionRange: Boolean;
    FCompositionStart: Integer;
    FCompositionLength: Integer;
    FHandled: Boolean;
  public
    property Kind: TGuiEventKind read FKind write FKind;
    property Position: TGuiPoint read FPosition write FPosition;
    property Delta: TGuiPoint read FDelta write FDelta;
    property Button: TGuiMouseButton read FButton write FButton;
    property Clicks: Integer read FClicks write FClicks;
    property KeyCode: Integer read FKeyCode write FKeyCode;
    property KeyRepeat: Boolean read FKeyRepeat write FKeyRepeat;
    property Modifiers: TGuiEventModifiers read FModifiers write FModifiers;
    property Text: UTF8String read FText write FText;
    { Composition positions are Unicode scalar counts, not UTF-8 byte offsets.
      Hosts that do not provide ranges leave HasCompositionRange False. }
    property HasCompositionRange: Boolean read FHasCompositionRange write FHasCompositionRange;
    property CompositionStart: Integer read FCompositionStart write FCompositionStart;
    property CompositionLength: Integer read FCompositionLength write FCompositionLength;
    property Handled: Boolean read FHandled write FHandled;
  end;

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

implementation

function GuiMixColor(const AFrom, ATo: TGuiColor; AAmount: TGuiFloat): TGuiColor;
begin
  if AAmount < 0 then AAmount:=0;
  if AAmount > 1 then AAmount:=1;
  Result.R:=Round(AFrom.R + (ATo.R - AFrom.R) * AAmount);
  Result.G:=Round(AFrom.G + (ATo.G - AFrom.G) * AAmount);
  Result.B:=Round(AFrom.B + (ATo.B - AFrom.B) * AAmount);
  Result.A:=Round(AFrom.A + (ATo.A - AFrom.A) * AAmount);
end;

function GuiPoint(AX, AY: TGuiFloat): TGuiPoint;
begin
  Result.X:=AX;
  Result.Y:=AY;
end;

function GuiSize(AWidth, AHeight: TGuiFloat): TGuiSize;
begin
  Result.Width:=AWidth;
  Result.Height:=AHeight;
end;

function GuiRect(ALeft, ATop, AWidth, AHeight: TGuiFloat): TGuiRect;
begin
  Result.Left:=ALeft;
  Result.Top:=ATop;
  Result.Width:=AWidth;
  Result.Height:=AHeight;
end;

function GuiBox(AValue: TGuiFloat): TGuiBox;
begin
  Result.Left:=AValue;
  Result.Top:=AValue;
  Result.Right:=AValue;
  Result.Bottom:=AValue;
end;

function GuiBoxLTRB(ALeft, ATop, ARight, ABottom: TGuiFloat): TGuiBox;
begin
  Result.Left:=ALeft;
  Result.Top:=ATop;
  Result.Right:=ARight;
  Result.Bottom:=ABottom;
end;

function GuiColor(ARed, AGreen, ABlue: Byte; AAlpha: Byte): TGuiColor;
begin
  Result.R:=ARed;
  Result.G:=AGreen;
  Result.B:=ABlue;
  Result.A:=AAlpha;
end;

function GuiEmptyBrush: TGuiBrush;
begin
  Result.Kind:=gbkNone;
  Result.Color:=GuiColor(0, 0, 0, 0);
  Result.Texture:=nil;
end;

function GuiColorBrush(const AColor: TGuiColor): TGuiBrush;
begin
  Result.Kind:=gbkColor;
  Result.Color:=AColor;
  Result.Texture:=nil;
end;

function GuiTextureBrush(ATexture: TGuiTexture): TGuiBrush;
begin
  Result.Kind:=gbkTexture;
  Result.Color:=GuiColor(255, 255, 255);
  Result.Texture:=ATexture;
end;

function GuiEmptyDrawable: TGuiDrawable;
begin
  Result.Kind:=gdkNone;
  Result.Brush:=GuiEmptyBrush;
  Result.Texture:=nil;
  Result.SourceRect:=GuiRect(0, 0, 0, 0);
  Result.Slice:=GuiBox(0);
  Result.GradientEnd:=GuiColor(0, 0, 0, 0);
end;

function GuiBrushDrawable(const ABrush: TGuiBrush): TGuiDrawable;
begin
  Result:=GuiEmptyDrawable;
  Result.Kind:=gdkBrush;
  Result.Brush:=ABrush;
end;

function GuiColorDrawable(const AColor: TGuiColor): TGuiDrawable;
begin
  Result:=GuiBrushDrawable(GuiColorBrush(AColor));
end;

function GuiGradientDrawable(const ATop, ABottom: TGuiColor): TGuiDrawable;
begin
  Result:=GuiColorDrawable(ATop);
  Result.Kind:=gdkLinearGradient;
  Result.GradientEnd:=ABottom;
end;

function GuiImageDrawable(ATexture: TGuiTexture; const ASourceRect: TGuiRect): TGuiDrawable;
begin
  Result:=GuiEmptyDrawable;
  Result.Kind:=gdkImage;
  Result.Texture:=ATexture;
  Result.SourceRect:=ASourceRect;
end;

function GuiNineSliceDrawable(ATexture: TGuiTexture; const ASourceRect: TGuiRect; const ASlice: TGuiBox): TGuiDrawable;
begin
  Result:=GuiEmptyDrawable;
  Result.Kind:=gdkNineSlice;
  Result.Texture:=ATexture;
  Result.SourceRect:=ASourceRect;
  Result.Slice:=ASlice;
end;

function GuiButtonStyle: TGuiStyle;
begin
  Result.BackgroundColor:=GuiColor(52, 64, 84);
  Result.HoverBackgroundColor:=GuiColor(66, 84, 112);
  Result.PressedBackgroundColor:=GuiColor(39, 50, 68);
  Result.CheckedBackgroundColor:=GuiColor(49, 98, 83);
  Result.DisabledBackgroundColor:=GuiColor(36, 43, 53);
  Result.BorderColor:=GuiColor(104, 125, 154);
  Result.HoverBorderColor:=GuiColor(139, 156, 180);
  Result.CheckedBorderColor:=GuiColor(118, 214, 180);
  Result.FocusedBorderColor:=GuiColor(248, 250, 252);
  Result.TextColor:=GuiColor(248, 250, 252);
  Result.DisabledTextColor:=GuiColor(144, 154, 168);
  Result.TextOffset:=GuiPoint(0, 0);
  Result.BorderWidth:=1;
  Result.CornerRadius:=0;
  Result.FocusWidth:=1;
  Result.ScrollBarSize:=12;
  Result.ScrollTrackColor:=GuiColor(28, 33, 41);
  Result.ScrollThumbColor:=GuiColor(102, 116, 136);
  Result.ScrollHoverColor:=GuiColor(145, 158, 178);
  Result.ScrollPressedColor:=GuiColor(118, 214, 180);
  GuiUpdateStyleDrawables(Result);
end;

procedure GuiUpdateStyleDrawables(var AStyle: TGuiStyle);
begin
  AStyle.Background:=GuiColorDrawable(AStyle.BackgroundColor);
  AStyle.HoverBackground:=GuiColorDrawable(AStyle.HoverBackgroundColor);
  AStyle.PressedBackground:=GuiColorDrawable(AStyle.PressedBackgroundColor);
  AStyle.CheckedBackground:=GuiColorDrawable(AStyle.CheckedBackgroundColor);
  AStyle.Selection:=GuiColorDrawable(AStyle.CheckedBackgroundColor);
  AStyle.Track:=GuiColorDrawable(AStyle.PressedBackgroundColor);
  AStyle.Thumb:=GuiColorDrawable(AStyle.CheckedBorderColor);
end;

function GuiResolveBackgroundColor(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiColor;
begin
  Result:=AStyle.BackgroundColor;

  if gcvsDisabled IN AStates then
  begin
    Result:=AStyle.DisabledBackgroundColor;
    if gcvsChecked IN AStates then
      Result:=GuiMixColor(Result, AStyle.CheckedBackgroundColor, 0.25);
    Exit;
  end;

  if gcvsChecked IN AStates then
  begin
    Result:=AStyle.CheckedBackgroundColor;
    if gcvsPressed IN AStates then Result:=GuiMixColor(Result, AStyle.PressedBackgroundColor, 0.4)
    else if gcvsHovered IN AStates then Result:=GuiMixColor(Result, AStyle.HoverBackgroundColor, 0.25);
  end
  else
  if gcvsPressed IN AStates then
    Result:=AStyle.PressedBackgroundColor
  else
  if gcvsHovered IN AStates then
    Result:=AStyle.HoverBackgroundColor;
end;

function GuiResolveBackgroundDrawable(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiDrawable;
begin
  Result:=AStyle.Background;

  if gcvsDisabled IN AStates then
  begin
    if gcvsChecked IN AStates then Result:=AStyle.CheckedBackground;
    if ((Result.Kind = gdkBrush) AND (Result.Brush.Kind = gbkColor)) OR (Result.Kind = gdkLinearGradient) then
      Result:=GuiColorDrawable(GuiResolveBackgroundColor(AStyle, AStates));
    Exit;
  end;

  if gcvsChecked IN AStates then
    Result:=AStyle.CheckedBackground
  else
  if gcvsPressed IN AStates then
    Result:=AStyle.PressedBackground
  else
  if gcvsHovered IN AStates then
    Result:=AStyle.HoverBackground;

  if (gcvsChecked IN AStates) AND ((gcvsHovered IN AStates) OR (gcvsPressed IN AStates)) AND
    (Result.Kind = gdkBrush) AND (Result.Brush.Kind = gbkColor) then
    Result:=GuiColorDrawable(GuiResolveBackgroundColor(AStyle, AStates));
  if (gcvsChecked IN AStates) AND (Result.Kind = gdkLinearGradient) then
  begin
    if gcvsPressed IN AStates then
      Result:=GuiGradientDrawable(GuiMixColor(Result.Brush.Color, AStyle.PressedBackgroundColor, 0.4),
        GuiMixColor(Result.GradientEnd, AStyle.PressedBackgroundColor, 0.4))
    else if gcvsHovered IN AStates then
      Result:=GuiGradientDrawable(GuiMixColor(Result.Brush.Color, AStyle.HoverBackgroundColor, 0.25),
        GuiMixColor(Result.GradientEnd, AStyle.HoverBackgroundColor, 0.25));
  end;
end;

function GuiResolveBorderColor(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiColor;
begin
  Result:=AStyle.BorderColor;

  if (gcvsHovered IN AStates) AND NOT (gcvsDisabled IN AStates) then Result:=AStyle.HoverBorderColor;

  if gcvsChecked IN AStates then
    Result:=AStyle.CheckedBorderColor;
  if gcvsDisabled IN AStates then
    Result:=GuiMixColor(Result, AStyle.DisabledBackgroundColor, 0.5);
end;

function GuiResolveTextColor(const AStyle: TGuiStyle; const AStates: TGuiControlVisualStates): TGuiColor;
begin
  Result:=AStyle.TextColor;

  if gcvsDisabled IN AStates then
    Result:=AStyle.DisabledTextColor;
end;

function GuiInflateRect(const ARect: TGuiRect; const ABox: TGuiBox): TGuiRect;
begin
  Result.Left:=ARect.Left + ABox.Left;
  Result.Top:=ARect.Top + ABox.Top;
  Result.Width:=ARect.Width - ABox.Left - ABox.Right;
  Result.Height:=ARect.Height - ABox.Top - ABox.Bottom;

  if Result.Width < 0 then
    Result.Width:=0;

  if Result.Height < 0 then
    Result.Height:=0;
end;

function GuiRectContains(const ARect: TGuiRect; const APoint: TGuiPoint): Boolean;
begin
  Result:=False;

  if (APoint.X >= ARect.Left) AND (APoint.Y >= ARect.Top) AND
    (APoint.X < ARect.Left + ARect.Width) AND (APoint.Y < ARect.Top + ARect.Height) then
    Result:=True;
end;

end.
