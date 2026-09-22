unit PasSDL3.GUI.Controls.Buttons;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  Math,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Core;

type
  TGuiIconPlacement = (
    gipLeft,
    gipRight,
    gipTop,
    gipBottom
  );

  TGuiButton = class(TGuiControl)
  private type
    PActivationGuard = ^TActivationGuard;
    TActivationGuard = record
    private
      FPrevious: PActivationGuard;
      FAlive: Boolean;
    public
      property Previous: PActivationGuard read FPrevious write FPrevious;
      property Alive: Boolean read FAlive write FAlive;
    end;
  private
    FActivationGuard: PActivationGuard;
    procedure BeginActivation(var AGuard: TActivationGuard);
    procedure EndActivation(var AGuard: TActivationGuard);
  private
    FAutoRepeat,FRepeatWaiting: Boolean;
    FHoldNotified,FSuppressReleaseClick: Boolean;
    FPressAndHoldInterval: Cardinal;
    FOnPressAndHold: TGuiNotifyEvent;
    procedure SetPressAndHoldInterval(AValue: Cardinal);
    procedure SetOnPressAndHold(AValue: TGuiNotifyEvent);
  private
    FRepeatDelay,FRepeatInterval: Cardinal;
    FRepeatStamp: UInt64;
    FButtonSource: Integer;
    FIcon: TGuiDrawable;
    FIconPlacement: TGuiIconPlacement;
    FIconTextSpacing: TGuiFloat;
    FIconSize: TGuiSize;
    procedure CancelButtonHold;
    procedure SetAutoRepeat(AValue: Boolean);
    procedure SetRepeatDelay(AValue: Cardinal);
    procedure SetRepeatInterval(AValue: Cardinal);
  protected
    function AnimationTime: UInt64; virtual;
    function SupportsAutoRepeat: Boolean; virtual;
    function VisualStates: TGuiControlVisualStates; virtual;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    procedure UpdateRepeat;
    procedure UpdateInteraction(AStage: TGuiInteractionStage); override;
    procedure BeforePointerRelease(var AEvent: TGuiEvent); override;
    procedure BeforeFocusedActivation(var AEvent: TGuiEvent); override;
    function SuppressReleaseClick: Boolean; override;
    destructor Destroy; override;
    property AutoRepeat: Boolean read FAutoRepeat write SetAutoRepeat;
    property RepeatDelay: Cardinal read FRepeatDelay write SetRepeatDelay;
    property RepeatInterval: Cardinal read FRepeatInterval write SetRepeatInterval;
    property PressAndHoldInterval: Cardinal read FPressAndHoldInterval write SetPressAndHoldInterval;
    property OnPressAndHold: TGuiNotifyEvent read FOnPressAndHold write SetOnPressAndHold;
    property Icon: TGuiDrawable read FIcon write FIcon;
    property IconPlacement: TGuiIconPlacement read FIconPlacement write FIconPlacement;
    property IconTextSpacing: TGuiFloat read FIconTextSpacing write FIconTextSpacing;
    property IconSize: TGuiSize read FIconSize write FIconSize;
  end;

  TGuiDelayButton = class(TGuiButton)
  private
    FDelay: Cardinal;
    FStarted: UInt64;
    FHoldSource: Integer;
    FHolding,FChecked: Boolean;
    function GetProgress: TGuiFloat;
    procedure SetDelay(AValue: Cardinal);
    procedure SetChecked(AValue: Boolean);
    procedure BeginHold(ASource: Integer);
    procedure CancelHold;
    function GetOnActivated: TGuiNotifyEvent;
    procedure SetOnActivated(AValue: TGuiNotifyEvent);
  protected
    function AnimationTime: UInt64; override;
    function SupportsAutoRepeat: Boolean; override;
    function VisualStates: TGuiControlVisualStates; override;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
    procedure DoClick; override;
  public
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    procedure UpdateHold;
    procedure UpdateInteraction(AStage: TGuiInteractionStage); override;
    procedure Reset;
    property Delay: Cardinal read FDelay write SetDelay;
    property Progress: TGuiFloat read GetProgress;
    property Checked: Boolean read FChecked write SetChecked;
    property Holding: Boolean read FHolding;
    property OnActivated: TGuiNotifyEvent read GetOnActivated write SetOnActivated;
  end;

  TGuiRoundButton = class(TGuiButton)
  private
    FRadius: TGuiFloat;
    procedure SetRadius(AValue: TGuiFloat);
    function GetEffectiveRadius: TGuiFloat;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    property Radius: TGuiFloat read FRadius write SetRadius;
    property EffectiveRadius: TGuiFloat read GetEffectiveRadius;
  end;

  TGuiSpeedButton = class(TGuiButton)
  private
    FDown, FCheckable, FAllowAllUp: Boolean;
    FGroupIndex: Integer;
    FOnChange: TGuiNotifyEvent;
    procedure SetDown(AValue: Boolean);
    procedure SetGroupIndex(AValue: Integer);
  protected
    procedure SetParent(AParent: TGuiControl); override;
    procedure DoClick; override;
    function VisualStates: TGuiControlVisualStates; override;
  public
    constructor Create; override;
    property Down: Boolean read FDown write SetDown;
    property Checkable: Boolean read FCheckable write FCheckable;
    property GroupIndex: Integer read FGroupIndex write SetGroupIndex;
    property AllowAllUp: Boolean read FAllowAllUp write FAllowAllUp;
    property OnChange: TGuiNotifyEvent read FOnChange write FOnChange;
  end;

  TGuiCheckBoxState = (gcbUnchecked, gcbChecked, gcbGrayed);
  TGuiNextCheckStateEvent = procedure(Sender: TGuiControl;
    var AState: TGuiCheckBoxState) of object;

  TGuiCheckBox = class(TGuiButton)
  private
    FState: TGuiCheckBoxState;
    FAllowGrayed: Boolean;
    FOnChange: TGuiNotifyEvent;
    FOnGetNextState: TGuiNextCheckStateEvent;
    function GetChecked: Boolean;
    procedure SetChecked(AValue: Boolean);
    procedure SetState(AValue: TGuiCheckBoxState);
  protected
    function NextState: TGuiCheckBoxState; virtual;
    procedure DoClick; override;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    property Checked: Boolean read GetChecked write SetChecked;
    property State: TGuiCheckBoxState read FState write SetState;
    { Controls the interactive cycle; State may always represent mixed values. }
    property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed;
    property OnChange: TGuiNotifyEvent read FOnChange write FOnChange;
    property OnGetNextState: TGuiNextCheckStateEvent read FOnGetNextState write FOnGetNextState;
    constructor Create; override;
  end;

  TGuiRadioButton = class(TGuiButton)
  private
    FChecked: Boolean;
    FGroupName: String;
    FOnChange: TGuiNotifyEvent;
    procedure SetChecked(AValue: Boolean);
    procedure SetGroupName(const AValue: String);
  protected
    procedure SetParent(AParent: TGuiControl); override;
    procedure DoClick; override;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    property Checked: Boolean read FChecked write SetChecked;
    property GroupName: String read FGroupName write SetGroupName;
    property OnChange: TGuiNotifyEvent read FOnChange write FOnChange;
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
  end;

  TGuiToggleButton = class(TGuiButton)
  private
    FChecked: Boolean;
    FAutoToggle: Boolean;
    FGroupName: String;
  protected
    procedure DoClick; override;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    property Checked: Boolean read FChecked write FChecked;
    property AutoToggle: Boolean read FAutoToggle write FAutoToggle;
    property GroupName: String read FGroupName write FGroupName;
  end;

  TGuiToggleSwitch = class(TGuiButton)
  private
    FChecked, FPointerDown, FCanDrag, FDragging, FSkipReleaseClick, FReleaseReady: Boolean;
    FStartX, FStartPosition, FDragPosition: TGuiFloat;
    FOnChange: TGuiNotifyEvent;
    procedure SetChecked(AValue: Boolean);
    function GetPosition: TGuiFloat;
    function TrackRect: TGuiRect;
  protected
    procedure DoClick; override;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    property Checked: Boolean read FChecked write SetChecked;
    property ThumbPosition: TGuiFloat read GetPosition;
    property OnChange: TGuiNotifyEvent read FOnChange write FOnChange;
  end;

implementation

constructor TGuiButton.Create;
begin
  inherited Create;
  FRepeatDelay:=300;
  FRepeatInterval:=100;
  FPressAndHoldInterval:=800;
  CanFocus:=True;
  TabStop:=True;
  BackgroundColor:=GuiColor(52, 64, 84);
  BorderColor:=GuiColor(104, 125, 154);
  TextColor:=GuiColor(248, 250, 252);
  Padding:=GuiBoxLTRB(10, 4, 10, 4);
  TextHorizontalAlign:=ghtaCenter;
  TextVerticalAlign:=gvtaCenter;
  Icon:=GuiEmptyDrawable;
  IconPlacement:=gipLeft;
  IconTextSpacing:=6;
  IconSize:=GuiSize(16, 16);
end;

function TGuiButton.VisualStates: TGuiControlVisualStates;
begin
  Result:=[gcvsNormal];
  if Hovered then Include(Result,gcvsHovered);
  if Pressed then Include(Result,gcvsPressed);
  if Focused then Include(Result,gcvsFocused);
  if NOT Enabled then Include(Result,gcvsDisabled);
end;

constructor TGuiRoundButton.Create;
begin
  inherited Create;
  FRadius:=-1;
  Bounds:=GuiRect(0,0,40,40);
  Padding:=GuiBox(4);
end;

procedure TGuiRoundButton.SetRadius(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR ((AValue<0) AND (AValue<>-1)) then
    raise EArgumentException.Create('Invalid round button radius');
  FRadius:=AValue;
end;

function TGuiRoundButton.GetEffectiveRadius: TGuiFloat;
begin
  Result:=Max(0,Min(Bounds.Width,Bounds.Height)/2);
  if FRadius>=0 then Result:=Min(Result,FRadius);
end;

procedure TGuiRoundButton.PaintSelf(ACanvas: TGuiCanvas);
var
  SavedRadius: TGuiFloat;
  CurrentStyle: TGuiStyle;
begin
  SavedRadius:=Style.CornerRadius;
  CurrentStyle:=Style;
  CurrentStyle.CornerRadius:=EffectiveRadius;
  Style:=CurrentStyle;
  try
    inherited;
  finally
    CurrentStyle:=Style;
    CurrentStyle.CornerRadius:=SavedRadius;
    Style:=CurrentStyle;
  end;
end;

constructor TGuiSpeedButton.Create;
var
  CurrentStyle: TGuiStyle;
begin
  inherited Create;
  Bounds:=GuiRect(0,0,32,32);
  Padding:=GuiBox(4);
  StyleClass:='Quiet';
  BackgroundColor:=GuiColor(0,0,0,0);
  BorderColor:=GuiColor(0,0,0,0);
  CurrentStyle:=Style;
  CurrentStyle.Background:=GuiColorDrawable(BackgroundColor);
  CurrentStyle.BorderColor:=BorderColor;
  Style:=CurrentStyle;
end;

procedure TGuiSpeedButton.SetDown(AValue: Boolean);
var I,Group: Integer;
Peer: TGuiSpeedButton;
Changed: Boolean;
  Owner: TGuiControl;
  Guard: TActivationGuard;
begin
  BeginActivation(Guard);
  try
  Changed:=FDown<>AValue;
  FDown:=AValue;
  Owner:=Parent;
  Group:=FGroupIndex;
  if FDown AND (FGroupIndex>0) AND Assigned(Parent) then
  begin
    I:=0;
    while I<Owner.ChildCount do
    begin
      if (Parent.Children[I]<>Self) AND (Parent.Children[I] IS TGuiSpeedButton) then
      begin
        Peer:=TGuiSpeedButton(Parent.Children[I]);
        if (Peer.GroupIndex=FGroupIndex) AND Peer.Down then
        begin
          Peer.Down:=False;
          if NOT Guard.Alive then Exit;
          if (Parent<>Owner) OR (FGroupIndex<>Group) OR NOT FDown then Exit;
          Continue;
        end;
      end;
      Inc(I);
    end;
  end;
  if Changed AND Assigned(FOnChange) then FOnChange(Self);
  finally
    if Guard.Alive then EndActivation(Guard);
  end;
end;

procedure TGuiSpeedButton.SetGroupIndex(AValue: Integer);
begin
  FGroupIndex:=Max(0,AValue);
  if FDown then SetDown(True);
end;

procedure TGuiSpeedButton.SetParent(AParent: TGuiControl);
begin
  inherited;
  if FDown then SetDown(True);
end;

procedure TGuiSpeedButton.DoClick;
var Guard: TActivationGuard;
begin
  if NOT Enabled then Exit;
  BeginActivation(Guard);
  try
  if FGroupIndex>0 then
  begin
    if NOT FDown then Down:=True else if FAllowAllUp then Down:=False;
  end
  else if FCheckable then Down:=NOT Down;
  if Guard.Alive then
    if Enabled then inherited;
  finally
    if Guard.Alive then EndActivation(Guard);
  end;
end;

procedure TGuiButton.BeginActivation(var AGuard: TActivationGuard);
begin
  AGuard.Alive:=True;
  AGuard.Previous:=FActivationGuard;
  FActivationGuard:=@AGuard;
end;

procedure TGuiButton.EndActivation(var AGuard: TActivationGuard);
begin
  FActivationGuard:=AGuard.Previous;
end;

destructor TGuiButton.Destroy;
var Guard: PActivationGuard;
begin
  Guard:=FActivationGuard;
  while Assigned(Guard) do
  begin
    Guard^.Alive:=False;
    Guard:=Guard^.Previous;
  end;
  inherited;
end;

function TGuiButton.AnimationTime: UInt64;
begin
  Result:=TThread.GetTickCount64;
end;

function TGuiButton.SupportsAutoRepeat: Boolean;
begin
  Result:=True;
end;

function TGuiDelayButton.SupportsAutoRepeat: Boolean;
begin
  Result:=False;
end;

procedure TGuiButton.CancelButtonHold;
begin
  FButtonSource:=0;
  FRepeatWaiting:=False;
  FHoldNotified:=False;
  Pressed:=False;
end;

procedure TGuiButton.SetPressAndHoldInterval(AValue: Cardinal);
begin
  if AValue=0 then raise EArgumentException.Create('Button hold interval must be positive');
  CancelButtonHold;
  FPressAndHoldInterval:=AValue;
end;

procedure TGuiButton.SetOnPressAndHold(AValue: TGuiNotifyEvent);
begin
  if Assigned(AValue) AND NOT SupportsAutoRepeat then
    raise EArgumentException.Create('This button uses a specialized hold event');
  CancelButtonHold;
  FOnPressAndHold:=AValue;
end;

procedure TGuiButton.SetAutoRepeat(AValue: Boolean);
begin
  if AValue AND NOT SupportsAutoRepeat then raise EArgumentException.Create('This button uses a specialized hold policy');
  CancelButtonHold;
  FAutoRepeat:=AValue;
end;

procedure TGuiButton.SetRepeatDelay(AValue: Cardinal);
begin
  CancelButtonHold;
  FRepeatDelay:=AValue;
end;

procedure TGuiButton.SetRepeatInterval(AValue: Cardinal);
begin
  if AValue=0 then raise EArgumentException.Create('Button repeat interval must be positive');
  CancelButtonHold;
  FRepeatInterval:=AValue;
end;

procedure TGuiButton.UpdateRepeat;
var Ancestor: TGuiControl;
NowValue,Interval: UInt64;
begin
  if (FButtonSource=0) OR NOT SupportsAutoRepeat then Exit;
  Ancestor:=Self;
  while Assigned(Ancestor) do
  begin
    if NOT Ancestor.Enabled OR NOT Ancestor.Visible then
    begin
      CancelButtonHold;
      Exit;
    end;
    Ancestor:=Ancestor.Parent;
  end;
  if Assigned(Context) AND Assigned(Context.ModalControl) AND
    NOT Context.ControlContains(Context.ModalControl,Self) then
    begin
      CancelButtonHold;
      Exit;
    end;
  NowValue:=AnimationTime;
  if NowValue<FRepeatStamp then
  begin
    CancelButtonHold;
    Exit;
  end;
  if NOT FAutoRepeat then
  begin
    if (FButtonSource=1) AND NOT FHoldNotified AND Assigned(FOnPressAndHold) AND
      (NowValue-FRepeatStamp>=FPressAndHoldInterval) then
    begin
      FHoldNotified:=True;
      FSuppressReleaseClick:=True;
      FOnPressAndHold(Self);
    end;
    Exit;
  end;
  if FRepeatWaiting then Interval:=FRepeatDelay else Interval:=FRepeatInterval;
  if NowValue-FRepeatStamp<Interval then Exit;
  FRepeatWaiting:=False;
  FRepeatStamp:=NowValue;
  DoClick;
end;

function TGuiButton.SuppressReleaseClick: Boolean;
begin
  Result:=FSuppressReleaseClick;
end;

procedure TGuiButton.HandleEvent(var AEvent: TGuiEvent);
var Source: Integer;
begin
  if NOT SupportsAutoRepeat then
  begin
    inherited;
    Exit;
  end;
  if NOT Enabled OR (AEvent.Kind IN [gekCancel,gekBlur]) OR
    ((AEvent.Kind=gekKeyDown) AND (AEvent.KeyCode=27)) then
  begin
    CancelButtonHold;
    inherited;
    Exit;
  end;
  if (FButtonSource=1) AND ((AEvent.Kind=gekMouseLeave) OR
    ((AEvent.Kind=gekMouseMove) AND NOT GuiRectContains(AbsoluteBounds,AEvent.Position))) then CancelButtonHold;
  Source:=0;
  if AEvent.Kind IN [gekMouseDown,gekMouseUp] then
  begin
    if AEvent.Button<>gmbLeft then Exit;
    Source:=1;
  end;
  if AEvent.Kind IN [gekKeyDown,gekKeyUp] then
  begin
    if AEvent.KeyCode=32 then Source:=2 else if AEvent.KeyCode=13 then Source:=3;
  end;
  if (AEvent.Kind IN [gekGamepadButtonDown,gekGamepadButtonUp]) AND (AEvent.KeyCode=0) then Source:=4;
  if Source<>0 then
  begin
    if AEvent.Kind IN [gekMouseDown,gekKeyDown,gekGamepadButtonDown] then
    begin
      if ((AEvent.Kind=gekKeyDown) AND AEvent.KeyRepeat) OR (FAutoRepeat AND (FButtonSource<>0)) then
      begin
        AEvent.Handled:=True;
        Exit;
      end;
      FButtonSource:=Source;
      FRepeatWaiting:=True;
      FRepeatStamp:=AnimationTime;
      Pressed:=True;
      FHoldNotified:=False;
      if Source=1 then FSuppressReleaseClick:=False;
    end
    else
    begin
      if FButtonSource=Source then CancelButtonHold;
      if Source<>1 then AEvent.Handled:=True;
    end;
  end;
  inherited;
end;

function TGuiSpeedButton.VisualStates: TGuiControlVisualStates;
begin
  Result:=inherited VisualStates;
  if FDown then Include(Result,gcvsChecked);
end;

procedure TGuiButton.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  ContentRect: TGuiRect;
  TextRect: TGuiRect;
  IconRect: TGuiRect;
  TextSize: TGuiSize;
  TotalWidth: TGuiFloat;
  TotalHeight: TGuiFloat;
  States: TGuiControlVisualStates;
begin
  States:=VisualStates;
  Rect:=AbsoluteBounds;
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), Rect, Style.CornerRadius);
  DrawControlBorder(ACanvas, Rect, GuiResolveBorderColor(Style, States));
  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, Rect, Style);

  ContentRect:=GuiInflateRect(Rect, Padding);
  TextRect:=ContentRect;

  if Icon.Kind <> gdkNone then
  begin
    TextSize:=ACanvas.MeasureText(Caption);
    IconRect:=GuiRect(0, 0, IconSize.Width, IconSize.Height);

    case IconPlacement of
      gipRight:
      begin
        TotalWidth:=IconSize.Width + IconTextSpacing + TextSize.Width;
        TextRect:=GuiRect(ContentRect.Left + ((ContentRect.Width - TotalWidth) / 2), ContentRect.Top, TextSize.Width, ContentRect.Height);
        IconRect.Left:=TextRect.Left + TextRect.Width + IconTextSpacing;
        IconRect.Top:=ContentRect.Top + ((ContentRect.Height - IconSize.Height) / 2);
      end;

      gipTop:
      begin
        TotalHeight:=IconSize.Height + IconTextSpacing + TextSize.Height;
        IconRect.Left:=ContentRect.Left + ((ContentRect.Width - IconSize.Width) / 2);
        IconRect.Top:=ContentRect.Top + ((ContentRect.Height - TotalHeight) / 2);
        TextRect:=GuiRect(ContentRect.Left, IconRect.Top + IconSize.Height + IconTextSpacing, ContentRect.Width, TextSize.Height);
      end;

      gipBottom:
      begin
        TotalHeight:=IconSize.Height + IconTextSpacing + TextSize.Height;
        TextRect:=GuiRect(ContentRect.Left, ContentRect.Top + ((ContentRect.Height - TotalHeight) / 2), ContentRect.Width, TextSize.Height);
        IconRect.Left:=ContentRect.Left + ((ContentRect.Width - IconSize.Width) / 2);
        IconRect.Top:=TextRect.Top + TextRect.Height + IconTextSpacing;
      end;

      else
      begin
        TotalWidth:=IconSize.Width + IconTextSpacing + TextSize.Width;
        IconRect.Left:=ContentRect.Left + ((ContentRect.Width - TotalWidth) / 2);
        IconRect.Top:=ContentRect.Top + ((ContentRect.Height - IconSize.Height) / 2);
        TextRect:=GuiRect(IconRect.Left + IconSize.Width + IconTextSpacing, ContentRect.Top, TextSize.Width, ContentRect.Height);
      end;
    end;

    if Caption='' then
      IconRect:=GuiRect(ContentRect.Left+(ContentRect.Width-IconSize.Width)/2,
        ContentRect.Top+(ContentRect.Height-IconSize.Height)/2,IconSize.Width,IconSize.Height);
    ACanvas.DrawDrawable(Icon, IconRect);
    DrawControlText(ACanvas, Caption, TextRect, GuiResolveTextColor(Style, States), ghtaCenter, gvtaCenter);
  end else
    DrawControlText(ACanvas, Caption, TextRect, GuiResolveTextColor(Style, States), TextHorizontalAlign, TextVerticalAlign);
end;

constructor TGuiToggleSwitch.Create;
begin
  inherited Create;
  Bounds:=GuiRect(0,0,160,34);
  Padding:=GuiBox(4);
  TextHorizontalAlign:=ghtaLeft;
  Cursor:=gmcHand;
end;

procedure TGuiToggleSwitch.SetChecked(AValue: Boolean);
var Changed: Boolean;
begin
  Changed:=FChecked<>AValue;
  if FPointerDown then FSkipReleaseClick:=True;
  FPointerDown:=False;
  FDragging:=False;
  FChecked:=AValue;
  if Changed AND Assigned(FOnChange) then FOnChange(Self);
end;

function TGuiToggleSwitch.GetPosition: TGuiFloat;
begin
  if FDragging AND Enabled then Result:=FDragPosition else Result:=Ord(FChecked);
end;

function TGuiToggleSwitch.TrackRect: TGuiRect;
var R: TGuiRect;
W,H: TGuiFloat;
begin
  R:=GuiInflateRect(AbsoluteBounds,Padding);
  W:=Max(0,Min(44,R.Width));
  H:=Max(0,Min(22,Min(R.Height,W/2)));
  Result:=GuiRect(R.Left,R.Top+(R.Height-H)/2,W,H);
  if Caption='' then Result.Left:=R.Left+(R.Width-W)/2;
end;

procedure TGuiToggleSwitch.DoClick;
var Guard: TActivationGuard;
begin
  if NOT Enabled then Exit;
  BeginActivation(Guard);
  try
  if Assigned(Context) AND (Context.PressedControl=Self) then
  begin
    if NOT FReleaseReady then Exit;
    FReleaseReady:=False;
  end;
  { Context generates its click after mouse-up even when the drag was handled.
    Skip only that release toggle, never a subsequent keyboard/gamepad action. }
  if FSkipReleaseClick AND Assigned(Context) AND (Context.PressedControl=Self) then
    FSkipReleaseClick:=False
  else
  begin
    FSkipReleaseClick:=False;
    SetChecked(NOT FChecked);
  end;
  if Guard.Alive then
    if Enabled then inherited DoClick;
  finally
    if Guard.Alive then EndActivation(Guard);
  end;
end;

procedure TGuiToggleSwitch.HandleEvent(var AEvent: TGuiEvent);
var R: TGuiRect;
Travel: TGuiFloat;
Commit: Boolean;
begin
  inherited HandleEvent(AEvent);
  if (AEvent.Kind IN [gekCancel,gekBlur]) OR NOT Enabled then
  begin
    FPointerDown:=False;
    FDragging:=False;
    FSkipReleaseClick:=False;
    FReleaseReady:=False;
    Pressed:=False;
    Exit;
  end;
  case AEvent.Kind of
    gekMouseDown:
      begin
        FSkipReleaseClick:=False;
        FReleaseReady:=False;
        FPointerDown:=AEvent.Button=gmbLeft;
        FDragging:=False;
        FStartX:=AEvent.Position.X;
        FStartPosition:=Ord(FChecked);
        FCanDrag:=GuiRectContains(TrackRect,AEvent.Position);
      end;
    gekMouseMove:
      if FPointerDown AND FCanDrag then
      begin
        if Abs(AEvent.Position.X-FStartX)>3 then FDragging:=True;
        if FDragging then
        begin
          R:=TrackRect;
          Travel:=Max(1,R.Width-R.Height);
          FDragPosition:=EnsureRange(FStartPosition+(AEvent.Position.X-FStartX)/Travel,0,1);
          AEvent.Handled:=True;
        end;
      end;
    gekMouseUp:
      if (AEvent.Button=gmbLeft) AND FPointerDown then
      begin
        Commit:=FDragging;
        FPointerDown:=False;
        FReleaseReady:=True;
        if Commit then
        begin
          R:=TrackRect;
          Travel:=Max(1,R.Width-R.Height);
          FDragPosition:=EnsureRange(FStartPosition+(AEvent.Position.X-FStartX)/Travel,0,1);
          FSkipReleaseClick:=True;
          AEvent.Handled:=True;
          SetChecked(FDragPosition>=0.5);
        end;
      end;
    gekKeyDown:
      if (AEvent.KeyCode=27) AND FPointerDown then
      begin
        FPointerDown:=False;
        FDragging:=False;
        FReleaseReady:=False;
        FSkipReleaseClick:=False;
        Pressed:=False;
        AEvent.Handled:=True;
      end
      else if (AEvent.KeyCode=$40000050) OR (AEvent.KeyCode=$4000004F) then
      begin
        AEvent.Handled:=True;
        SetChecked(AEvent.KeyCode=$4000004F);
      end;
  end;
end;

procedure TGuiToggleSwitch.PaintSelf(ACanvas: TGuiCanvas);
var R,Thumb,TextBounds: TGuiRect;
States: TGuiControlVisualStates;
Color: TGuiColor;
  Diameter: TGuiFloat;
begin
  R:=TrackRect;
  if (R.Width<=0) OR (R.Height<=0) then Exit;
  States:=[gcvsNormal];
  if FChecked then Include(States,gcvsChecked);
  if Hovered then Include(States,gcvsHovered);
  if Pressed then Include(States,gcvsPressed);
  if Focused then Include(States,gcvsFocused);
  if NOT Enabled then Include(States,gcvsDisabled);
  ACanvas.PushClipRect(AbsoluteBounds);
  try
    ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style,States),R,R.Height/2);
    ACanvas.DrawRoundedBorder(R,R.Height/2,Max(0,Style.BorderWidth),GuiResolveBorderColor(Style,States));
    Diameter:=Max(0,R.Height-6);
    Thumb:=GuiRect(R.Left+3+ThumbPosition*(R.Width-R.Height),R.Top+3,Diameter,Diameter);
    Color:=GuiResolveTextColor(Style,States);
    ACanvas.FillRoundedRect(Thumb,Diameter/2,Color);
    if Caption<>'' then
    begin
      TextBounds:=GuiInflateRect(AbsoluteBounds,Padding);
      TextBounds.Width:=Max(0,TextBounds.Left+TextBounds.Width-R.Left-R.Width-10);
      TextBounds.Left:=R.Left+R.Width+10;
      DrawControlText(ACanvas,Caption,TextBounds,Color,ghtaLeft,TextVerticalAlign);
    end;
    if Focused AND FocusVisible then GuiPaintFocusIndicator(ACanvas,AbsoluteBounds,Style);
  finally
    ACanvas.PopClipRect;
  end;
end;

constructor TGuiCheckBox.Create;
begin
  inherited Create;
  Checked:=False;
  Padding:=GuiBoxLTRB(26, 4, 8, 4);
  TextHorizontalAlign:=ghtaLeft;
end;

procedure TGuiCheckBox.DoClick;
var Guard: TActivationGuard;
NewState: TGuiCheckBoxState;
begin
  if NOT Enabled then Exit;
  BeginActivation(Guard);
  try
    NewState:=NextState;
    if NOT Guard.Alive then Exit;
    if NOT Enabled then Exit;
    State:=NewState;
    if Guard.Alive then
      if Enabled then inherited DoClick;
  finally
    if Guard.Alive then EndActivation(Guard);
  end;
end;

function TGuiCheckBox.GetChecked: Boolean;
begin
  Result:=FState=gcbChecked;
end;

procedure TGuiCheckBox.SetChecked(AValue: Boolean);
begin
  if AValue then SetState(gcbChecked) else SetState(gcbUnchecked);
end;

procedure TGuiCheckBox.SetState(AValue: TGuiCheckBoxState);
begin
  if (Ord(AValue)<Ord(Low(TGuiCheckBoxState))) OR (Ord(AValue)>Ord(High(TGuiCheckBoxState))) then
    raise EArgumentOutOfRangeException.Create('Invalid checkbox state');
  if FState=AValue then Exit;
  FState:=AValue;
  if Assigned(FOnChange) then FOnChange(Self);
end;

function TGuiCheckBox.NextState: TGuiCheckBoxState;
begin
  if FAllowGrayed then
    case FState of
      gcbUnchecked: Result:=gcbGrayed;
      gcbGrayed: Result:=gcbChecked;
      else Result:=gcbUnchecked;
    end
  else if Checked then Result:=gcbUnchecked else Result:=gcbChecked;
  if Assigned(FOnGetNextState) then FOnGetNextState(Self,Result);
end;

procedure TGuiCheckBox.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  BoxRect: TGuiRect;
  MarkRect: TGuiRect;
  States: TGuiControlVisualStates;
begin
  States:=[gcvsNormal];
  if State<>gcbUnchecked then
    Include(States, gcvsChecked);

  if Hovered then
    Include(States, gcvsHovered);

  if Pressed then
    Include(States, gcvsPressed);

  if Focused then
    Include(States, gcvsFocused);

  if NOT Enabled then
    Include(States, gcvsDisabled);

  Rect:=AbsoluteBounds;
  if (Rect.Width<=0) OR (Rect.Height<=0) then Exit;
  ACanvas.PushClipRect(Rect);
  try
  BoxRect:=GuiRect(Rect.Left + 4, Rect.Top + ((Rect.Height - 18) / 2), 18, 18);
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), BoxRect, Style.CornerRadius);
  DrawControlBorder(ACanvas, BoxRect, GuiResolveBorderColor(Style, States));

  if Checked then
  begin
    MarkRect:=GuiInflateRect(BoxRect, GuiBox(5));
    if (Style.Thumb.Kind = gdkBrush) AND (Style.Thumb.Brush.Kind = gbkColor) then
      ACanvas.DrawCheckMark(MarkRect, GuiResolveTextColor(Style, States))
    else ACanvas.DrawDrawable(Style.Thumb, MarkRect);
  end
  else if State=gcbGrayed then
    ACanvas.FillRoundedRect(GuiRect(BoxRect.Left+4,BoxRect.Top+8,10,2),1,
      GuiResolveTextColor(Style,States));

  DrawControlText(ACanvas, Caption, GuiInflateRect(Rect, Padding), GuiResolveTextColor(Style, States), TextHorizontalAlign, TextVerticalAlign);

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, Rect, Style);
  finally
    ACanvas.PopClipRect;
  end;
end;

constructor TGuiDelayButton.Create;
begin
  inherited;
  FDelay:=3000;
end;

function TGuiDelayButton.AnimationTime: UInt64;
begin
  Result:=TThread.GetTickCount64;
end;

function TGuiDelayButton.GetOnActivated: TGuiNotifyEvent;
begin
  Result:=OnClick;
end;

procedure TGuiDelayButton.SetOnActivated(AValue: TGuiNotifyEvent);
begin
  OnClick:=AValue;
end;

procedure TGuiDelayButton.CancelHold;
begin
  FHolding:=False;
  FHoldSource:=0;
  Pressed:=False;
end;

procedure TGuiDelayButton.Reset;
begin
  CancelHold;
  FChecked:=False;
end;

procedure TGuiDelayButton.SetChecked(AValue: Boolean);
begin
  CancelHold;
  FChecked:=AValue;
end;

procedure TGuiDelayButton.SetDelay(AValue: Cardinal);
begin
  if FDelay=AValue then Exit;
  Reset;
  FDelay:=AValue;
end;

function TGuiDelayButton.GetProgress: TGuiFloat;
var NowValue: UInt64;
begin
  Result:=0;
  if FChecked then
  begin
    Result:=1;
    Exit;
  end;
  if NOT FHolding then Exit;
  NowValue:=AnimationTime;
  if NowValue<FStarted then Exit;
  if (FDelay=0) OR (NowValue-FStarted>=FDelay) then Result:=1
  else Result:=(NowValue-FStarted)/FDelay;
end;

procedure TGuiDelayButton.BeginHold(ASource: Integer);
begin
  if FHoldSource<>0 then Exit;
  FHoldSource:=ASource;
  if FChecked then
  begin
    FChecked:=False;
    Exit;
  end;
  FHolding:=True;
  FStarted:=AnimationTime;
  Pressed:=True;
  UpdateHold;
end;

procedure TGuiDelayButton.UpdateHold;
var Ancestor: TGuiControl;
begin
  if NOT FHolding then Exit;
  Ancestor:=Self;
  while Assigned(Ancestor) do
  begin
    if NOT Ancestor.Enabled OR NOT Ancestor.Visible then
    begin
      CancelHold;
      Exit;
    end;
    Ancestor:=Ancestor.Parent;
  end;
  if Assigned(Context) AND Assigned(Context.ModalControl) AND
    NOT Context.ControlContains(Context.ModalControl,Self) then
    begin
      CancelHold;
      Exit;
    end;
  if AnimationTime<FStarted then
  begin
    CancelHold;
    Exit;
  end;
  if Progress<1 then Exit;
  FHolding:=False;
  FChecked:=True;
  Pressed:=False;
  inherited DoClick;
end;

procedure TGuiDelayButton.DoClick;
begin
  { Only UpdateHold can activate this control. }
end;

function TGuiDelayButton.VisualStates: TGuiControlVisualStates;
begin
  Result:=inherited VisualStates;
  if FChecked then Include(Result,gcvsChecked);
end;

procedure TGuiDelayButton.PaintSelf(ACanvas: TGuiCanvas);
var R: TGuiRect;
Amount: TGuiFloat;
begin
  inherited;
  Amount:=Progress;
  if Amount<=0 then Exit;
  R:=GuiInflateRect(AbsoluteBounds,GuiBox(5));
  R.Top:=R.Top+Max(0,R.Height-3);
  R.Height:=Min(3,R.Height);
  R.Width:=R.Width*Amount;
  if Enabled then ACanvas.FillRoundedRect(R,1.5,Style.CheckedBorderColor)
  else ACanvas.FillRoundedRect(R,1.5,Style.DisabledTextColor);
end;

procedure TGuiDelayButton.HandleEvent(var AEvent: TGuiEvent);
var Source: Integer;
begin
  if NOT Enabled OR (AEvent.Kind IN [gekCancel,gekBlur]) OR
    ((AEvent.Kind=gekKeyDown) AND (AEvent.KeyCode=27)) then
  begin
    CancelHold;
    inherited;
    Exit;
  end;
  if (FHoldSource=1) AND ((AEvent.Kind=gekMouseLeave) OR
    ((AEvent.Kind=gekMouseMove) AND NOT GuiRectContains(AbsoluteBounds,AEvent.Position))) then CancelHold;
  Source:=0;
  if (AEvent.Kind IN [gekMouseDown,gekMouseUp]) AND (AEvent.Button=gmbLeft) then Source:=1;
  if AEvent.Kind IN [gekKeyDown,gekKeyUp] then
  begin
    if AEvent.KeyCode=32 then Source:=2 else if AEvent.KeyCode=13 then Source:=3;
  end;
  if (AEvent.Kind IN [gekGamepadButtonDown,gekGamepadButtonUp]) AND (AEvent.KeyCode=0) then Source:=4;
  if Source<>0 then
  begin
    AEvent.Handled:=True;
    if AEvent.Kind IN [gekMouseDown,gekKeyDown,gekGamepadButtonDown] then
    begin
      if (AEvent.Kind=gekKeyDown) AND AEvent.KeyRepeat then Exit;
      BeginHold(Source);
      Exit;
    end;
    if FHoldSource=Source then
    begin
      if (Source=1) AND NOT GuiRectContains(AbsoluteBounds,AEvent.Position) then
      begin
        CancelHold;
        Exit;
      end;
      { Clear input ownership before callbacks, which may reset or free the control. }
      FHoldSource:=0;
      Pressed:=False;
      if FHolding AND (Progress>=1) then
      begin
        UpdateHold;
        Exit;
      end;
      CancelHold;
    end;
    Exit;
  end;
  inherited;
end;

constructor TGuiRadioButton.Create;
begin
  inherited Create;
  Checked:=False;
  GroupName:='';
  Padding:=GuiBoxLTRB(26, 4, 8, 4);
  TextHorizontalAlign:=ghtaLeft;
end;

procedure TGuiRadioButton.SetChecked(AValue: Boolean);
var
  I: Integer;
  Control: TGuiControl;
  Changed: Boolean;
  Owner: TGuiControl;
  Group: String;
  Guard: TActivationGuard;
begin
  BeginActivation(Guard);
  try
  Changed:=FChecked<>AValue;
  FChecked:=AValue;
  Owner:=Parent;
  Group:=GroupName;
  if FChecked AND Assigned(Parent) then
  begin
    I:=0;
    while I<Owner.ChildCount do
    begin
      Control:=Parent.Children[I];
      if (Control <> Self) AND (Control IS TGuiRadioButton) AND
        (TGuiRadioButton(Control).GroupName = GroupName) AND TGuiRadioButton(Control).Checked then
      begin
        TGuiRadioButton(Control).Checked:=False;
        if NOT Guard.Alive then Exit;
        if (Parent<>Owner) OR (GroupName<>Group) OR NOT FChecked then Exit;
        Continue;
      end;
      Inc(I);
    end;
  end;

  if Changed AND Assigned(FOnChange) then FOnChange(Self);
  finally
    if Guard.Alive then EndActivation(Guard);
  end;
end;

procedure TGuiRadioButton.SetGroupName(const AValue: String);
begin
  FGroupName:=AValue;
  if FChecked then SetChecked(True);
end;

procedure TGuiRadioButton.SetParent(AParent: TGuiControl);
begin
  inherited;
  if FChecked then SetChecked(True);
end;

procedure TGuiRadioButton.DoClick;
var Guard: TActivationGuard;
begin
  if NOT Enabled then Exit;
  BeginActivation(Guard);
  try
    Checked:=True;
    if Guard.Alive then
      if Enabled then inherited DoClick;
  finally
    if Guard.Alive then EndActivation(Guard);
  end;
end;

procedure TGuiRadioButton.HandleEvent(var AEvent: TGuiEvent);
var Step,I,N,Start: Integer;
Candidate: TGuiRadioButton;
begin
  inherited;
  if NOT Enabled OR (AEvent.Kind<>gekKeyDown) OR NOT Assigned(Parent) then Exit;
  case AEvent.KeyCode of
    $40000050,$40000052: Step:=-1;
    $4000004F,$40000051: Step:=1;
    else Exit;
  end;
  N:=Parent.ChildCount;
  Start:=Parent.IndexOfChild(Self);
  for I:=1 to N-1 do
    if Parent.Children[(Start+Step*I+N) MOD N] IS TGuiRadioButton then
    begin
      Candidate:=TGuiRadioButton(Parent.Children[(Start+Step*I+N) MOD N]);
      if (Candidate.GroupName=GroupName) AND Candidate.Visible AND Candidate.Enabled AND Candidate.CanFocus then
      begin
        if Assigned(Context) then Context.SetFocus(Candidate);
        Candidate.Checked:=True;
        AEvent.Handled:=True;
        Exit;
      end;
    end;
  AEvent.Handled:=True;
end;

procedure TGuiRadioButton.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  OuterRect: TGuiRect;
  InnerRect: TGuiRect;
  States: TGuiControlVisualStates;
begin
  States:=[gcvsNormal];
  if Checked then
    Include(States, gcvsChecked);

  if Hovered then
    Include(States, gcvsHovered);

  if Pressed then
    Include(States, gcvsPressed);

  if Focused then
    Include(States, gcvsFocused);

  if NOT Enabled then
    Include(States, gcvsDisabled);

  Rect:=AbsoluteBounds;
  if (Rect.Width<=0) OR (Rect.Height<=0) then Exit;
  ACanvas.PushClipRect(Rect);
  try
  OuterRect:=GuiRect(Rect.Left + 4, Rect.Top + ((Rect.Height - 18) / 2), 18, 18);
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), OuterRect, 9);
  ACanvas.DrawRoundedBorder(OuterRect, 9, Style.BorderWidth, GuiResolveBorderColor(Style, States));

  if Checked then
  begin
    InnerRect:=GuiInflateRect(OuterRect, GuiBox(5));
    if Enabled then ACanvas.DrawSurface(Style.Thumb, InnerRect, InnerRect.Width / 2)
    else ACanvas.FillRoundedRect(InnerRect,InnerRect.Width/2,Style.DisabledTextColor);
  end;

  DrawControlText(ACanvas, Caption, GuiInflateRect(Rect, Padding), GuiResolveTextColor(Style, States), TextHorizontalAlign, TextVerticalAlign);

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, Rect, Style);
  finally
    ACanvas.PopClipRect;
  end;
end;

procedure TGuiButton.UpdateInteraction(AStage: TGuiInteractionStage);
begin
  if AStage = gisRepeat then
    UpdateRepeat;
end;

procedure TGuiButton.BeforePointerRelease(var AEvent: TGuiEvent);
begin
  if (AEvent.Button = gmbLeft) AND NOT AutoRepeat then
    UpdateRepeat;
end;

procedure TGuiButton.BeforeFocusedActivation(var AEvent: TGuiEvent);
begin
  HandleEvent(AEvent);
end;

procedure TGuiDelayButton.UpdateInteraction(AStage: TGuiInteractionStage);
begin
  inherited UpdateInteraction(AStage);
  if AStage = gisHold then
    UpdateHold;
end;

constructor TGuiToggleButton.Create;
begin
  inherited Create;
  Checked:=False;
  AutoToggle:=True;
  GroupName:='';
end;

procedure TGuiToggleButton.DoClick;
var
  I: Integer;
  Control: TGuiControl;
begin
  if GroupName <> '' then
  begin
    if Assigned(Parent) then
    begin
      for I:=0 to Parent.ChildCount - 1 do
      begin
        Control:=Parent.Children[I];
        if (Control IS TGuiToggleButton) AND (TGuiToggleButton(Control).GroupName = GroupName) then
          TGuiToggleButton(Control).Checked:=Control = Self;
      end;
    end else
      Checked:=True;
  end else
  if AutoToggle then
    Checked:=NOT Checked;

  inherited DoClick;
end;

procedure TGuiToggleButton.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  States: TGuiControlVisualStates;
begin
  States:=[gcvsNormal];
  if Checked then
    Include(States, gcvsChecked);

  if Hovered then
    Include(States, gcvsHovered);

  if Pressed then
    Include(States, gcvsPressed);

  if Focused then
    Include(States, gcvsFocused);

  if NOT Enabled then
    Include(States, gcvsDisabled);

  Rect:=AbsoluteBounds;
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), Rect, Style.CornerRadius);
  DrawControlBorder(ACanvas, Rect, GuiResolveBorderColor(Style, States));
  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, Rect, Style);

  DrawControlText(ACanvas, Caption, GuiInflateRect(Rect, Padding), GuiResolveTextColor(Style, States), TextHorizontalAlign, TextVerticalAlign);
end;

end.
