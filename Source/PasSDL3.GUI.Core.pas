unit PasSDL3.GUI.Core;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  Math,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Renderer.Canvas;

type
  TGuiControl = class;
  TGuiPopupControl = class;

  TGuiContextServices = class
  protected
    function GetRoot: TGuiControl; virtual; abstract;
    function GetModalControl: TGuiControl; virtual; abstract;
    function GetHoveredControl: TGuiControl; virtual; abstract;
    function GetFocusedControl: TGuiControl; virtual; abstract;
    function GetPressedControl: TGuiControl; virtual; abstract;
    function GetMousePosition: TGuiPoint; virtual; abstract;
  public
    procedure DetachControl(AControl: TGuiControl); virtual; abstract;
    function SetFocus(AControl: TGuiControl): Boolean; virtual; abstract;
    procedure RestoreFocus; virtual; abstract;
    function RestoreFocusWithin(ARoot, AExcept: TGuiControl): Boolean; virtual; abstract;
    procedure CloseModal(AControl: TGuiControl = nil); virtual; abstract;
    procedure CancelInput; virtual; abstract;
    function ControlContains(AParent, AControl: TGuiControl): Boolean; virtual; abstract;
    procedure ClosePopups(AExcept: TGuiControl); virtual; abstract;
    property Root: TGuiControl read GetRoot;
    property ModalControl: TGuiControl read GetModalControl;
    property HoveredControl: TGuiControl read GetHoveredControl;
    property FocusedControl: TGuiControl read GetFocusedControl;
    property PressedControl: TGuiControl read GetPressedControl;
    property MousePosition: TGuiPoint read GetMousePosition;
  end;

  TGuiLayoutState = record
  private
    FBounds: TGuiRect;
    FPadding: TGuiBox;
    FMargin: TGuiBox;
    FMinWidth: TGuiFloat;
    FMinHeight: TGuiFloat;
    FMaxWidth: TGuiFloat;
    FMaxHeight: TGuiFloat;
    FAlign: TGuiAlign;
    FAnchors: TGuiAnchors;
    FVisible: Boolean;
    FAutoSize: Boolean;
  public
    property Bounds: TGuiRect read FBounds write FBounds;
    property Padding: TGuiBox read FPadding write FPadding;
    property Margin: TGuiBox read FMargin write FMargin;
    property MinWidth: TGuiFloat read FMinWidth write FMinWidth;
    property MinHeight: TGuiFloat read FMinHeight write FMinHeight;
    property MaxWidth: TGuiFloat read FMaxWidth write FMaxWidth;
    property MaxHeight: TGuiFloat read FMaxHeight write FMaxHeight;
    property Align: TGuiAlign read FAlign write FAlign;
    property Anchors: TGuiAnchors read FAnchors write FAnchors;
    property Visible: Boolean read FVisible write FVisible;
    property AutoSize: Boolean read FAutoSize write FAutoSize;
  end;

  TGuiNotifyEvent = procedure(Sender: TGuiControl) of object;
  TGuiMouseEvent = procedure(Sender: TGuiControl; const Event: TGuiEvent) of object;
  TGuiFocusChangedEvent = procedure(Sender: TObject; OldControl, NewControl: TGuiControl) of object;

  TGuiInteractionStage = (
    gisRepeat,
    gisHold,
    gisMotion,
    gisSecondaryRepeat
  );

  TGuiControl = class
  private
    FParent: TGuiControl;
    FContext: TGuiContextServices;
    FChildren: TList;
    FPopupMenu: TGuiPopupControl;
    FLastArrangeWidth: TGuiFloat;
    FLastArrangeHeight: TGuiFloat;
    FHasLastArrangeSize: Boolean;
    FLayoutDirty: Boolean;
    FLayoutState: TGuiLayoutState;
    FOnClick: TGuiNotifyEvent;
    FOnMouseEnter: TGuiNotifyEvent;
    FOnMouseLeave: TGuiNotifyEvent;
    FOnMouseDown: TGuiMouseEvent;
    FOnMouseUp: TGuiMouseEvent;
    FOnMouseMove: TGuiMouseEvent;
    FName: String;
    FStyleClass: String;
    FFontName: String;
    FHint: String;
    FBounds: TGuiRect;
    FMinWidth: TGuiFloat;
    FMinHeight: TGuiFloat;
    FMaxWidth: TGuiFloat;
    FMaxHeight: TGuiFloat;
    FVisible: Boolean;
    FEnabled: Boolean;
    FCanFocus: Boolean;
    FTabStop: Boolean;
    FShowFocus: Boolean;
    FFocusVisible: Boolean;
    FHovered: Boolean;
    FPressed: Boolean;
    FFocused: Boolean;
    FClipChildren: Boolean;
    FAlign: TGuiAlign;
    FAnchors: TGuiAnchors;
    FPadding: TGuiBox;
    FMargin: TGuiBox;
    FBackgroundColor: TGuiColor;
    FBorderColor: TGuiColor;
    FTextColor: TGuiColor;
    FStyle: TGuiStyle;
    FTextHorizontalAlign: TGuiHorizontalTextAlign;
    FTextVerticalAlign: TGuiVerticalTextAlign;
    FTextOffset: TGuiPoint;
    FBorderWidth: TGuiFloat;
    FCaption: String;
    FTag: NativeInt;
    FData: TObject;
    FAutoSize: Boolean;
    FCursor: TGuiMouseCursor;
    function CurrentLayoutState: TGuiLayoutState;
    function GetChildCount: Integer;
    function GetChildren(AIndex: Integer): TGuiControl;
  protected
    property Context: TGuiContextServices read FContext;
    procedure PaintSelf(ACanvas: TGuiCanvas); virtual;
    procedure SetParent(AParent: TGuiControl); virtual;
    function GetChildPaintOffset: TGuiPoint; virtual;
    procedure ClosePopup; virtual;
    procedure DoClick; virtual;
    procedure DoMouseEnter; virtual;
    procedure DoMouseLeave; virtual;
    procedure DoMouseDown(const AEvent: TGuiEvent); virtual;
    procedure DoMouseUp(const AEvent: TGuiEvent); virtual;
    procedure DoMouseMove(const AEvent: TGuiEvent); virtual;
    procedure DrawControlText(ACanvas: TGuiCanvas; const AText: String; const ARect: TGuiRect; const AColor: TGuiColor;
      AHorizontalAlign: TGuiHorizontalTextAlign = ghtaLeft; AVerticalAlign: TGuiVerticalTextAlign = gvtaCenter); virtual;
    procedure DrawControlBorder(ACanvas: TGuiCanvas; const ARect: TGuiRect; const AColor: TGuiColor;
      AWidth: TGuiFloat = -1); virtual;
    procedure PaintItemBackground(ACanvas: TGuiCanvas; const ARect: TGuiRect; ASelected: Boolean); virtual;
    procedure PaintScrollBar(ACanvas: TGuiCanvas; const ATrack, AThumb: TGuiRect;
      AOrientation: TGuiOrientation; ADragging: Boolean; AOverlay: Boolean = False);
    function FullWidthRowRect(const ARect: TGuiRect): TGuiRect;
    function ScrollContentRect(AScrolls: Boolean): TGuiRect;
    procedure CompleteArrange;
  public
    property Name: String read FName write FName;
    property StyleClass: String read FStyleClass write FStyleClass;
    property FontName: String read FFontName write FFontName;
    property Hint: String read FHint write FHint;
    property Bounds: TGuiRect read FBounds write FBounds;
    property MinWidth: TGuiFloat read FMinWidth write FMinWidth;
    property MinHeight: TGuiFloat read FMinHeight write FMinHeight;
    property MaxWidth: TGuiFloat read FMaxWidth write FMaxWidth;
    property MaxHeight: TGuiFloat read FMaxHeight write FMaxHeight;
    property Visible: Boolean read FVisible write FVisible;
    property Enabled: Boolean read FEnabled write FEnabled;
    property CanFocus: Boolean read FCanFocus write FCanFocus;
    property TabStop: Boolean read FTabStop write FTabStop;
    property ShowFocus: Boolean read FShowFocus write FShowFocus;
    property FocusVisible: Boolean read FFocusVisible write FFocusVisible;
    property Hovered: Boolean read FHovered write FHovered;
    property Pressed: Boolean read FPressed write FPressed;
    property Focused: Boolean read FFocused write FFocused;
    property ClipChildren: Boolean read FClipChildren write FClipChildren;
    property Align: TGuiAlign read FAlign write FAlign;
    property Anchors: TGuiAnchors read FAnchors write FAnchors;
    property Padding: TGuiBox read FPadding write FPadding;
    property Margin: TGuiBox read FMargin write FMargin;
    property BackgroundColor: TGuiColor read FBackgroundColor write FBackgroundColor;
    property BorderColor: TGuiColor read FBorderColor write FBorderColor;
    property TextColor: TGuiColor read FTextColor write FTextColor;
    property Style: TGuiStyle read FStyle write FStyle;
    property TextHorizontalAlign: TGuiHorizontalTextAlign read FTextHorizontalAlign write FTextHorizontalAlign;
    property TextVerticalAlign: TGuiVerticalTextAlign read FTextVerticalAlign write FTextVerticalAlign;
    property TextOffset: TGuiPoint read FTextOffset write FTextOffset;
    property BorderWidth: TGuiFloat read FBorderWidth write FBorderWidth;
    property Caption: String read FCaption write FCaption;
    property Tag: NativeInt read FTag write FTag;
    property Data: TObject read FData write FData;
    property AutoSize: Boolean read FAutoSize write FAutoSize;
    property Cursor: TGuiMouseCursor read FCursor write FCursor;
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Add(AControl: TGuiControl); virtual;
    procedure Remove(AControl: TGuiControl); virtual;
    procedure Clear; virtual;
    procedure AttachContext(AContext: TGuiContextServices);
    procedure CaptureLayoutState;
    procedure InvalidateLayout; virtual;
    function LayoutDirty: Boolean;
    procedure Measure(const AAvailableSize: TGuiSize; out ADesiredSize: TGuiSize); virtual;
    procedure Arrange(const ABounds: TGuiRect); virtual;
    procedure Paint(ACanvas: TGuiCanvas); virtual;
    procedure PaintOverlay(ACanvas: TGuiCanvas); virtual;
    procedure HandleEvent(var AEvent: TGuiEvent); virtual;
    function HitTest(const APoint: TGuiPoint): TGuiControl; virtual;
    function HitTestOverlay(const APoint: TGuiPoint): TGuiControl; virtual;
    procedure ClosePopups(AExcept: TGuiControl); virtual;
    function AbsoluteBounds: TGuiRect;
    function MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor; virtual;
    function HasContext(AContext: TGuiContextServices): Boolean;
    procedure BringToFront;
    function IndexOfChild(AControl: TGuiControl): Integer;
    procedure UpdateInteraction(AStage: TGuiInteractionStage); virtual;
    procedure DetachedFromContext; virtual;
    function DispatchShortcut(var AEvent: TGuiEvent): Boolean; virtual;
    function HandleFocusNavigation(AReverse: Boolean): Boolean; virtual;
    procedure PrepareFocusNavigation(AReverse: Boolean); virtual;
    function ActivateWindow: Boolean; virtual;
    function KeepCurrentFocusOnPointerDown: Boolean; virtual;
    function DefinesFocusScope: Boolean; virtual;
    procedure BeforePointerRelease(var AEvent: TGuiEvent); virtual;
    procedure BeforeFocusedActivation(var AEvent: TGuiEvent); virtual;
    procedure PerformClick;
    function SuppressReleaseClick: Boolean; virtual;
    property Parent: TGuiControl read FParent;
    property PopupMenu: TGuiPopupControl read FPopupMenu write FPopupMenu;
    property ChildCount: Integer read GetChildCount;
    property Children[AIndex: Integer]: TGuiControl read GetChildren;
    property OnClick: TGuiNotifyEvent read FOnClick write FOnClick;
    property OnMouseEnter: TGuiNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseLeave: TGuiNotifyEvent read FOnMouseLeave write FOnMouseLeave;
    property OnMouseDown: TGuiMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseUp: TGuiMouseEvent read FOnMouseUp write FOnMouseUp;
    property OnMouseMove: TGuiMouseEvent read FOnMouseMove write FOnMouseMove;
  end;

  TGuiContainer = class(TGuiControl)
  end;

  TGuiPopupControl = class(TGuiControl)
  public
    procedure PopupAt(const APoint: TGuiPoint); virtual;
    function PopupOpen: Boolean; virtual;
  end;

function GuiScrollThumbLength(AViewportLength, AContentLength, ATrackLength, AMinLength: TGuiFloat): TGuiFloat;
function GuiScrollOffsetFromThumbDelta(ADelta, ATrackLength, AThumbLength, AMaxScroll: TGuiFloat): TGuiFloat;
function GuiScrollTrackRect(const ABounds: TGuiRect; AOrientation: TGuiOrientation;
  ASize: TGuiFloat; AStartInset: TGuiFloat = 4; AEndInset: TGuiFloat = 4): TGuiRect;
function GuiVerticalScrollThumbRect(const ATrack: TGuiRect;
  AViewport, AContent, AOffset: TGuiFloat): TGuiRect;
procedure GuiClampControlBounds(AControl: TGuiControl; var ABounds: TGuiRect);
procedure GuiPaintFocusIndicator(ACanvas: TGuiCanvas; const ARect: TGuiRect; const AStyle: TGuiStyle);

implementation

function GuiScrollTrackRect(const ABounds: TGuiRect; AOrientation: TGuiOrientation;
  ASize, AStartInset, AEndInset: TGuiFloat): TGuiRect;
var Length, Thickness: TGuiFloat;
begin
  Result:=ABounds;
  Result.Width:=Max(0, Result.Width);
  Result.Height:=Max(0, Result.Height);
  if AOrientation = goVertical then
  begin
    Length:=Result.Height;
    Thickness:=Result.Width;
  end else
  begin
    Length:=Result.Width;
    Thickness:=Result.Height;
  end;
  AStartInset:=EnsureRange(AStartInset, 0, Length);
  AEndInset:=EnsureRange(AEndInset, 0, Length - AStartInset);
  ASize:=EnsureRange(ASize, 0, Thickness);
  if AOrientation = goVertical then
  begin
    Result.Left:=Result.Left + Result.Width - ASize;
    Result.Width:=ASize;
    Result.Top:=Result.Top + AStartInset;
    Result.Height:=Length - AStartInset - AEndInset;
  end else
  begin
    Result.Top:=Result.Top + Result.Height - ASize;
    Result.Height:=ASize;
    Result.Left:=Result.Left + AStartInset;
    Result.Width:=Length - AStartInset - AEndInset;
  end;
end;

function GuiVerticalScrollThumbRect(const ATrack: TGuiRect;
  AViewport, AContent, AOffset: TGuiFloat): TGuiRect;
var Travel: TGuiFloat;
begin
  Result:=GuiRect(ATrack.Left, ATrack.Top, Max(0, ATrack.Width), 0);
  if AContent <= AViewport then Exit;
  Result.Height:=GuiScrollThumbLength(AViewport, AContent, ATrack.Height, 24);
  Travel:=Max(0, ATrack.Height - Result.Height);
  Result.Top:=Result.Top + Travel * EnsureRange(AOffset / (AContent - AViewport), 0, 1);
end;

function TGuiControl.ScrollContentRect(AScrolls: Boolean): TGuiRect;
var Track: TGuiRect;
begin
  Result:=GuiInflateRect(AbsoluteBounds, Padding);
  if AScrolls then
  begin
    Track:=GuiScrollTrackRect(AbsoluteBounds, goVertical, Max(8, Style.ScrollBarSize));
    Result.Width:=Max(0, Min(Result.Width, Track.Left - 4 - Result.Left));
  end;
end;

function GuiScrollThumbLength(AViewportLength, AContentLength, ATrackLength, AMinLength: TGuiFloat): TGuiFloat;
begin
  Result:=0;

  if (AViewportLength <= 0) OR (AContentLength <= 0) OR (ATrackLength <= 0) then
    Exit;

  Result:=(AViewportLength / AContentLength) * ATrackLength;

  if Result < AMinLength then
    Result:=AMinLength;

  if Result > ATrackLength then
    Result:=ATrackLength;
end;

function GuiScrollOffsetFromThumbDelta(ADelta, ATrackLength, AThumbLength, AMaxScroll: TGuiFloat): TGuiFloat;
var
  MovableLength: TGuiFloat;
begin
  Result:=0;

  if AMaxScroll <= 0 then
    Exit;

  MovableLength:=ATrackLength - AThumbLength;

  if MovableLength > 0 then
    Result:=(ADelta / MovableLength) * AMaxScroll;
end;

procedure GuiClampControlBounds(AControl: TGuiControl; var ABounds: TGuiRect);
begin
  if NOT Assigned(AControl) then
    Exit;

  if ABounds.Width < AControl.MinWidth then
    ABounds.Width:=AControl.MinWidth;

  if ABounds.Height < AControl.MinHeight then
    ABounds.Height:=AControl.MinHeight;

  if (AControl.MaxWidth > 0) AND (ABounds.Width > AControl.MaxWidth) then
    ABounds.Width:=AControl.MaxWidth;

  if (AControl.MaxHeight > 0) AND (ABounds.Height > AControl.MaxHeight) then
    ABounds.Height:=AControl.MaxHeight;
end;

procedure GuiPaintFocusIndicator(ACanvas: TGuiCanvas; const ARect: TGuiRect; const AStyle: TGuiStyle);
var
  Rect: TGuiRect;
  Halo: TGuiColor;
begin
  if AStyle.FocusWidth <= 0 then Exit;
  Rect:=GuiInflateRect(ARect, GuiBox(2));
  Halo:=AStyle.FocusedBorderColor;
  Halo.A:=Round(Halo.A * 0.18);
  ACanvas.DrawRoundedBorder(GuiInflateRect(ARect, GuiBox(1)), Max(0, AStyle.CornerRadius - 1),
    AStyle.FocusWidth + 2, Halo);
  ACanvas.DrawRoundedBorder(Rect, Max(0, AStyle.CornerRadius - 2), AStyle.FocusWidth, AStyle.FocusedBorderColor);
end;

function TGuiControl.FullWidthRowRect(const ARect: TGuiRect): TGuiRect;
begin
  Result:=GuiRect(AbsoluteBounds.Left + 1, ARect.Top, Max(0, AbsoluteBounds.Width - 2), ARect.Height);
end;

procedure TGuiControl.PaintItemBackground(ACanvas: TGuiCanvas; const ARect: TGuiRect; ASelected: Boolean);
var Rect: TGuiRect;
begin
  Rect:=GuiInflateRect(ARect, GuiBoxLTRB(1, 1, 1, 1));
  if ASelected then
  begin
    ACanvas.DrawSurface(Style.Selection, Rect, Min(4, Style.CornerRadius));
    if (Style.Selection.Kind = gdkLinearGradient) OR
      ((Style.Selection.Kind = gdkBrush) AND (Style.Selection.Brush.Kind = gbkColor)) then
      ACanvas.FillRoundedRect(GuiRect(Rect.Left + 2, Rect.Top + 5, 2, Max(0, Rect.Height - 10)),
        1, GuiResolveBorderColor(Style, [gcvsChecked]));
  end
  else if Enabled AND Assigned(FContext) AND (FContext.HoveredControl = Self) AND
    GuiRectContains(ARect, FContext.MousePosition) then
    ACanvas.DrawSurface(Style.HoverBackground, Rect, Min(4, Style.CornerRadius));
end;

procedure TGuiControl.PaintScrollBar(ACanvas: TGuiCanvas; const ATrack, AThumb: TGuiRect;
  AOrientation: TGuiOrientation; ADragging: Boolean; AOverlay: Boolean);
var
  Thumb, Rail: TGuiRect;
  Color, TrackColor: TGuiColor;
  Hot: Boolean;
  Thickness, Radius: TGuiFloat;
begin
  if (ATrack.Width <= 0) OR (ATrack.Height <= 0) then Exit;
  Hot:=Enabled AND Assigned(FContext) AND (FContext.HoveredControl = Self) AND
    GuiRectContains(ATrack, FContext.MousePosition);
  Thickness:=6;
  Color:=Style.ScrollThumbColor;
  if Hot then
  begin
    Thickness:=8;
    Color:=Style.ScrollHoverColor;
  end;
  if ADragging then
  begin
    Thickness:=8;
    Color:=Style.ScrollPressedColor;
  end;
  if NOT Enabled then Color:=GuiMixColor(Color, Style.ScrollTrackColor, 0.6);
  Thumb:=AThumb;
  Rail:=ATrack;
  if AOrientation = goVertical then
  begin
    Thickness:=Min(Thickness, Max(0, ATrack.Width - 4));
    Thumb.Width:=Thickness;
    Thumb.Left:=ATrack.Left + (ATrack.Width - Thickness) / 2;
    Rail.Width:=Max(0, ATrack.Width - 4);
    Rail.Left:=ATrack.Left + 2;
  end else
  begin
    Thickness:=Min(Thickness, Max(0, ATrack.Height - 4));
    Thumb.Height:=Thickness;
    Thumb.Top:=ATrack.Top + (ATrack.Height - Thickness) / 2;
    Rail.Height:=Max(0, ATrack.Height - 4);
    Rail.Top:=ATrack.Top + 2;
  end;
  Radius:=Style.CornerRadius;
  if Radius > 0 then Radius:=Max(ATrack.Width, ATrack.Height);
  TrackColor:=Style.ScrollTrackColor;
  if AOverlay then
  begin
    TrackColor.A:=112;
    ACanvas.FillRect(ATrack, TrackColor);
    TrackColor.A:=48;
  end;
  if (Style.Track.Kind = gdkBrush) AND (Style.Track.Brush.Kind = gbkColor) then
    ACanvas.FillRoundedRect(Rail, Radius, TrackColor)
  else ACanvas.DrawSurface(Style.Track, ATrack, Style.CornerRadius);
  if (Style.Thumb.Kind = gdkBrush) AND (Style.Thumb.Brush.Kind = gbkColor) then
    ACanvas.FillRoundedRect(Thumb, Radius, Color)
  else ACanvas.DrawSurface(Style.Thumb, AThumb, Style.CornerRadius);
end;

function TGuiControl.MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor;
begin
  Result:=gmcArrow;
  if NOT Enabled then
    Exit;
  if Cursor <> gmcAuto then
    Result:=Cursor;
end;

constructor TGuiControl.Create;
begin
  inherited Create;
  FChildren:=TList.Create;
  FLastArrangeWidth:=0;
  FLastArrangeHeight:=0;
  FHasLastArrangeSize:=False;
  FLayoutDirty:=True;
  Bounds:=GuiRect(0, 0, 0, 0);
  Visible:=True;
  Enabled:=True;
  ShowFocus:=True;
  FocusVisible:=False;
  ClipChildren:=False;
  Anchors:=[ganLeft, ganTop];
  Padding:=GuiBox(0);
  Margin:=GuiBox(0);
  BackgroundColor:=GuiColor(0, 0, 0, 0);
  BorderColor:=GuiColor(0, 0, 0, 0);
  TextColor:=GuiColor(232, 236, 242);
  Style:=GuiButtonStyle;
  TextHorizontalAlign:=ghtaLeft;
  TextVerticalAlign:=gvtaCenter;
  TextOffset:=GuiPoint(0, 0);
  BorderWidth:=-1;
end;

destructor TGuiControl.Destroy;
begin
  if Assigned(FParent) then
    FParent.Remove(Self)
  else
    AttachContext(nil);
  Clear;
  FChildren.Free;
  inherited Destroy;
end;

function TGuiControl.GetChildCount: Integer;
begin
  Result:=FChildren.Count;
end;

function TGuiControl.GetChildren(AIndex: Integer): TGuiControl;
begin
  Result:=TGuiControl(FChildren[AIndex]);
end;

procedure TGuiControl.SetParent(AParent: TGuiControl);
begin
  FParent:=AParent;
end;

procedure TGuiControl.AttachContext(AContext: TGuiContextServices);
var
  I: Integer;
begin
  if FContext = AContext then
    Exit;

  if Assigned(FContext) then
    FContext.DetachControl(Self);
  FContext:=AContext;
  for I:=0 to ChildCount - 1 do
    Children[I].AttachContext(AContext);
end;

function TGuiControl.GetChildPaintOffset: TGuiPoint;
begin
  Result:=GuiPoint(0, 0);
end;

procedure TGuiControl.ClosePopup;
begin
end;

procedure TGuiControl.Add(AControl: TGuiControl);
var
  Ancestor: TGuiControl;
begin
  if NOT Assigned(AControl) then
    Exit;

  Ancestor:=Self;
  while Assigned(Ancestor) do
  begin
    if Ancestor = AControl then
      raise EArgumentException.Create('A control cannot contain itself or an ancestor');
    Ancestor:=Ancestor.Parent;
  end;

  if Assigned(AControl.Parent) then
    AControl.Parent.Remove(AControl);

  AControl.SetParent(Self);
  AControl.AttachContext(FContext);
  FChildren.Add(AControl);
  InvalidateLayout;
end;

procedure TGuiControl.Remove(AControl: TGuiControl);
var
  Index: Integer;
begin
  if NOT Assigned(AControl) then
    Exit;

  Index:=FChildren.IndexOf(AControl);
  if Index >= 0 then
  begin
    FChildren.Delete(Index);
    AControl.AttachContext(nil);
    AControl.SetParent(nil);
    InvalidateLayout;
  end;
end;

procedure TGuiControl.Clear;
begin
  if NOT Assigned(FChildren) then
    Exit;
  while FChildren.Count > 0 do
    TGuiControl(FChildren[FChildren.Count - 1]).Free;
  InvalidateLayout;
end;

procedure TGuiControl.InvalidateLayout;
begin
  if FLayoutDirty then
    Exit;

  FLayoutDirty:=True;

  if Assigned(FParent) then
    FParent.InvalidateLayout;
end;

function TGuiControl.LayoutDirty: Boolean;
var
  I: Integer;
  State: TGuiLayoutState;
begin
  State:=CurrentLayoutState;
  Result:=FLayoutDirty OR (NOT CompareMem(@State, @FLayoutState, SizeOf(State)));

  if Result then
    Exit;

  for I:=0 to ChildCount - 1 do
  begin
    Result:=Children[I].LayoutDirty;
    if Result then
      Exit;
  end;
end;

function TGuiControl.CurrentLayoutState: TGuiLayoutState;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Bounds:=Bounds;
  Result.Padding:=Padding;
  Result.Margin:=Margin;
  Result.MinWidth:=MinWidth;
  Result.MinHeight:=MinHeight;
  Result.MaxWidth:=MaxWidth;
  Result.MaxHeight:=MaxHeight;
  Result.Align:=Align;
  Result.Anchors:=Anchors;
  Result.Visible:=Visible;
  Result.AutoSize:=AutoSize;
end;

procedure TGuiControl.CaptureLayoutState;
var
  I: Integer;
begin
  FLayoutState:=CurrentLayoutState;
  FLayoutDirty:=False;
  for I:=0 to ChildCount - 1 do
    Children[I].CaptureLayoutState;
end;

procedure TGuiControl.Measure(const AAvailableSize: TGuiSize; out ADesiredSize: TGuiSize);
var
  DesiredBounds: TGuiRect;
begin
  DesiredBounds:=GuiRect(0, 0, Bounds.Width, Bounds.Height);
  GuiClampControlBounds(Self, DesiredBounds);
  ADesiredSize:=GuiSize(DesiredBounds.Width, DesiredBounds.Height);
end;

procedure TGuiControl.Arrange(const ABounds: TGuiRect);
var
  I: Integer;
  Child: TGuiControl;
  ClientRect: TGuiRect;
  ChildBounds: TGuiRect;
  DeltaWidth: TGuiFloat;
  DeltaHeight: TGuiFloat;
  procedure EnsureNonNegativeRect(var ARect: TGuiRect);
  begin
    if ARect.Width < 0 then
      ARect.Width:=0;

    if ARect.Height < 0 then
      ARect.Height:=0;
  end;
begin
  DeltaWidth:=0;
  DeltaHeight:=0;
  if FHasLastArrangeSize then
  begin
    DeltaWidth:=ABounds.Width - FLastArrangeWidth;
    DeltaHeight:=ABounds.Height - FLastArrangeHeight;
  end;

  Bounds:=ABounds;
  FLastArrangeWidth:=Bounds.Width;
  FLastArrangeHeight:=Bounds.Height;
  FHasLastArrangeSize:=True;
  ClientRect:=GuiInflateRect(GuiRect(0, 0, Bounds.Width, Bounds.Height), Padding);

  for I:=0 to FChildren.Count - 1 do
  begin
    Child:=TGuiControl(FChildren[I]);
    if NOT Child.Visible then
      Continue;
    ChildBounds:=Child.Bounds;

    case Child.Align of
      gaTop:
      begin
        ChildBounds.Left:=ClientRect.Left + Child.Margin.Left;
        ChildBounds.Top:=ClientRect.Top + Child.Margin.Top;
        ChildBounds.Width:=ClientRect.Width - Child.Margin.Left - Child.Margin.Right;
        EnsureNonNegativeRect(ChildBounds);
        GuiClampControlBounds(Child, ChildBounds);
        ClientRect.Top:=ClientRect.Top + ChildBounds.Height + Child.Margin.Top + Child.Margin.Bottom;
        ClientRect.Height:=ClientRect.Height - ChildBounds.Height - Child.Margin.Top - Child.Margin.Bottom;
      end;

      gaBottom:
      begin
        ChildBounds.Left:=ClientRect.Left + Child.Margin.Left;
        ChildBounds.Width:=ClientRect.Width - Child.Margin.Left - Child.Margin.Right;
        EnsureNonNegativeRect(ChildBounds);
        GuiClampControlBounds(Child, ChildBounds);
        ChildBounds.Top:=ClientRect.Top + ClientRect.Height - ChildBounds.Height - Child.Margin.Bottom;
        ClientRect.Height:=ClientRect.Height - ChildBounds.Height - Child.Margin.Top - Child.Margin.Bottom;
      end;

      gaLeft:
      begin
        ChildBounds.Left:=ClientRect.Left + Child.Margin.Left;
        ChildBounds.Top:=ClientRect.Top + Child.Margin.Top;
        ChildBounds.Height:=ClientRect.Height - Child.Margin.Top - Child.Margin.Bottom;
        EnsureNonNegativeRect(ChildBounds);
        GuiClampControlBounds(Child, ChildBounds);
        ClientRect.Left:=ClientRect.Left + ChildBounds.Width + Child.Margin.Left + Child.Margin.Right;
        ClientRect.Width:=ClientRect.Width - ChildBounds.Width - Child.Margin.Left - Child.Margin.Right;
      end;

      gaRight:
      begin
        ChildBounds.Top:=ClientRect.Top + Child.Margin.Top;
        ChildBounds.Height:=ClientRect.Height - Child.Margin.Top - Child.Margin.Bottom;
        EnsureNonNegativeRect(ChildBounds);
        GuiClampControlBounds(Child, ChildBounds);
        ChildBounds.Left:=ClientRect.Left + ClientRect.Width - ChildBounds.Width - Child.Margin.Right;
        ClientRect.Width:=ClientRect.Width - ChildBounds.Width - Child.Margin.Left - Child.Margin.Right;
      end;

      gaClient:
      begin
        ChildBounds:=GuiInflateRect(ClientRect, Child.Margin);
        GuiClampControlBounds(Child, ChildBounds);
      end;

      else
      begin
        if (ganLeft IN Child.Anchors) AND (ganRight IN Child.Anchors) then
          ChildBounds.Width:=ChildBounds.Width + DeltaWidth
        else
        if (NOT (ganLeft IN Child.Anchors)) AND (ganRight IN Child.Anchors) then
          ChildBounds.Left:=ChildBounds.Left + DeltaWidth;

        if (ganTop IN Child.Anchors) AND (ganBottom IN Child.Anchors) then
          ChildBounds.Height:=ChildBounds.Height + DeltaHeight
        else
        if (NOT (ganTop IN Child.Anchors)) AND (ganBottom IN Child.Anchors) then
          ChildBounds.Top:=ChildBounds.Top + DeltaHeight;

        EnsureNonNegativeRect(ChildBounds);
        GuiClampControlBounds(Child, ChildBounds);
      end;
    end;

    if ClientRect.Width < 0 then
      ClientRect.Width:=0;

    if ClientRect.Height < 0 then
      ClientRect.Height:=0;

    Child.Arrange(ChildBounds);
  end;

  FLayoutDirty:=False;
end;

procedure TGuiControl.PaintSelf(ACanvas: TGuiCanvas);
begin
ACanvas.DrawSurface(GuiColorDrawable(BackgroundColor), AbsoluteBounds, Style.CornerRadius);

  if BorderColor.A > 0 then
    DrawControlBorder(ACanvas, AbsoluteBounds, BorderColor);
end;

procedure TGuiControl.Paint(ACanvas: TGuiCanvas);
var
  I: Integer;
  PreviousFont: String;
begin
  if NOT Visible then
    Exit;

  PreviousFont:=ACanvas.FontName;
  ACanvas.FontName:=FontName;
  try
    PaintSelf(ACanvas);
  finally
    ACanvas.FontName:=PreviousFont;
  end;

  if ClipChildren then
  begin
    ACanvas.PushClipRect(AbsoluteBounds);
    try
      for I:=0 to FChildren.Count - 1 do
        TGuiControl(FChildren[I]).Paint(ACanvas);
    finally
      ACanvas.PopClipRect;
    end;
  end else
  begin
    for I:=0 to FChildren.Count - 1 do
      TGuiControl(FChildren[I]).Paint(ACanvas);
  end;
end;

procedure TGuiControl.PaintOverlay(ACanvas: TGuiCanvas);
var
  I: Integer;
begin
  if NOT Visible then
    Exit;

  for I:=0 to FChildren.Count - 1 do
    TGuiControl(FChildren[I]).PaintOverlay(ACanvas);
end;

procedure TGuiControl.DoClick;
begin
  if Assigned(FOnClick) then
    FOnClick(Self);
end;

procedure TGuiControl.DoMouseEnter;
begin
  if Assigned(FOnMouseEnter) then
    FOnMouseEnter(Self);
end;

procedure TGuiControl.DoMouseLeave;
begin
  if Assigned(FOnMouseLeave) then
    FOnMouseLeave(Self);
end;

procedure TGuiControl.DoMouseDown(const AEvent: TGuiEvent);
begin
  if Assigned(FOnMouseDown) then
    FOnMouseDown(Self, AEvent);
end;

procedure TGuiControl.DoMouseUp(const AEvent: TGuiEvent);
begin
  if Assigned(FOnMouseUp) then
    FOnMouseUp(Self, AEvent);
end;

procedure TGuiControl.DoMouseMove(const AEvent: TGuiEvent);
begin
  if Assigned(FOnMouseMove) then
    FOnMouseMove(Self, AEvent);
end;

procedure TGuiControl.DrawControlText(ACanvas: TGuiCanvas; const AText: String; const ARect: TGuiRect; const AColor: TGuiColor;
  AHorizontalAlign: TGuiHorizontalTextAlign; AVerticalAlign: TGuiVerticalTextAlign);
var
  Rect: TGuiRect;
  PreviousFont: String;
begin
  Rect:=ARect;
  Rect.Left:=Rect.Left + Style.TextOffset.X + TextOffset.X;
  Rect.Top:=Rect.Top + Style.TextOffset.Y + TextOffset.Y;
  PreviousFont:=ACanvas.FontName;
  ACanvas.FontName:=FontName;
  try
    ACanvas.DrawText(AText, Rect, AColor, AHorizontalAlign, AVerticalAlign);
  finally
    ACanvas.FontName:=PreviousFont;
  end;
end;

procedure TGuiControl.DrawControlBorder(ACanvas: TGuiCanvas; const ARect: TGuiRect; const AColor: TGuiColor; AWidth: TGuiFloat);
var
  Width: TGuiFloat;
begin
  if AColor.A <= 0 then
    Exit;

  Width:=AWidth;
  if Width < 0 then
  begin
    if BorderWidth >= 0 then
      Width:=BorderWidth
    else
      Width:=Style.BorderWidth;
  end;

  if Width <= 0 then
    Exit;

  ACanvas.DrawRoundedBorder(ARect, Style.CornerRadius, Width, AColor);
end;

procedure TGuiControl.HandleEvent(var AEvent: TGuiEvent);
begin
  if AEvent.Kind = gekCancel then
  begin
    Pressed:=False;
    Hovered:=False;
    Exit;
  end;
  if NOT Enabled then
    Exit;

  case AEvent.Kind of
    gekMouseEnter:
    begin
      Hovered:=True;
      DoMouseEnter;
    end;

    gekMouseLeave:
    begin
      Hovered:=False;
      DoMouseLeave;
    end;

    gekMouseMove: DoMouseMove(AEvent);

    gekMouseDown:
    begin
      Pressed:=True;
      DoMouseDown(AEvent);
    end;

    gekMouseUp:
    begin
      Pressed:=False;
      DoMouseUp(AEvent);
    end;
  end;
end;

function TGuiControl.HitTest(const APoint: TGuiPoint): TGuiControl;
var
  I: Integer;
  Child: TGuiControl;
  Rect: TGuiRect;
begin
  Result:=nil;

  if (NOT Visible) OR (NOT Enabled) then
    Exit;

  Rect:=AbsoluteBounds;
  if NOT GuiRectContains(Rect, APoint) then
    Exit;

  for I:=FChildren.Count - 1 downto 0 do
  begin
    Child:=TGuiControl(FChildren[I]).HitTest(APoint);
    if Assigned(Child) then
    begin
      Result:=Child;
      Exit;
    end;
  end;

  Result:=Self;
end;

function TGuiControl.HitTestOverlay(const APoint: TGuiPoint): TGuiControl;
var
  I: Integer;
  Child: TGuiControl;
begin
  Result:=nil;

  if (NOT Visible) OR (NOT Enabled) then
    Exit;

  for I:=FChildren.Count - 1 downto 0 do
  begin
    Child:=TGuiControl(FChildren[I]).HitTestOverlay(APoint);
    if Assigned(Child) then
    begin
      Result:=Child;
      Exit;
    end;
  end;
end;

procedure TGuiControl.ClosePopups(AExcept: TGuiControl);
var
  I: Integer;
begin
  if Self <> AExcept then
    ClosePopup;

  for I:=0 to FChildren.Count - 1 do
    TGuiControl(FChildren[I]).ClosePopups(AExcept);
end;

function TGuiControl.AbsoluteBounds: TGuiRect;
var
  Control: TGuiControl;
  Offset: TGuiPoint;
begin
  Result:=Bounds;
  Control:=FParent;

  while Assigned(Control) do
  begin
    Offset:=Control.GetChildPaintOffset;
    Result.Left:=Result.Left + Control.Bounds.Left + Offset.X;
    Result.Top:=Result.Top + Control.Bounds.Top + Offset.Y;
    Control:=Control.Parent;
  end;
end;

function TGuiControl.HasContext(AContext: TGuiContextServices): Boolean;
begin
  Result:=FContext = AContext;
end;

procedure TGuiControl.BringToFront;
begin
  if NOT Assigned(FParent) then
    Exit;
  FParent.FChildren.Remove(Self);
  FParent.FChildren.Add(Self);
end;

function TGuiControl.IndexOfChild(AControl: TGuiControl): Integer;
begin
  Result:=FChildren.IndexOf(AControl);
end;

procedure TGuiControl.UpdateInteraction(AStage: TGuiInteractionStage);
begin
end;

procedure TGuiControl.DetachedFromContext;
begin
end;

function TGuiControl.DispatchShortcut(var AEvent: TGuiEvent): Boolean;
var
  I: Integer;
begin
  Result:=False;
  if NOT Visible OR NOT Enabled then
    Exit;
  for I:=ChildCount - 1 downto 0 do
  begin
    Result:=Children[I].DispatchShortcut(AEvent);
    if Result then
      Exit;
  end;
end;

function TGuiControl.HandleFocusNavigation(AReverse: Boolean): Boolean;
begin
  Result:=False;
end;

procedure TGuiControl.PrepareFocusNavigation(AReverse: Boolean);
begin
end;

function TGuiControl.ActivateWindow: Boolean;
begin
  Result:=False;
end;

function TGuiControl.KeepCurrentFocusOnPointerDown: Boolean;
begin
  Result:=False;
end;

function TGuiControl.DefinesFocusScope: Boolean;
begin
  Result:=False;
end;

procedure TGuiControl.BeforePointerRelease(var AEvent: TGuiEvent);
begin
end;

procedure TGuiControl.BeforeFocusedActivation(var AEvent: TGuiEvent);
begin
end;

procedure TGuiControl.CompleteArrange;
begin
  FLastArrangeWidth:=Bounds.Width;
  FLastArrangeHeight:=Bounds.Height;
  FHasLastArrangeSize:=True;
  FLayoutDirty:=False;
end;

procedure TGuiControl.PerformClick;
begin
  DoClick;
end;

function TGuiControl.SuppressReleaseClick: Boolean;
begin
  Result:=False;
end;

procedure TGuiPopupControl.PopupAt(const APoint: TGuiPoint);
begin
end;

function TGuiPopupControl.PopupOpen: Boolean;
begin
  Result:=False;
end;

end.
