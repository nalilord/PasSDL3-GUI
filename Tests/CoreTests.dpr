program CoreTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  SysUtils, Classes, IniFiles, Math, PasSDL3.GUI.Types, PasSDL3.GUI.Core, PasSDL3.GUI.Text,
  PasSDL3.GUI.StateStrings,
  PasSDL3.GUI.Controls, PasSDL3.GUI.Controls.Buttons, PasSDL3.GUI.Controls.Menus,
  PasSDL3.GUI.Controls.Bars,
  PasSDL3.GUI.Clipboard,
  PasSDL3.GUI.Theme, PasSDL3.GUI.Theme.Files,
  PasSDL3.GUI.Renderer.Canvas;

type
  TTabMutationProbe = class
  public
    procedure DeleteFirst(Sender: TGuiControl; const Event: TGuiEvent);
    procedure Disable(Sender: TGuiControl; const Event: TGuiEvent);
  end;
  TTypeAheadCombo = class(TGuiComboBox)
  private
    FTicks: UInt64;
  public
    property Ticks: UInt64 read FTicks write FTicks;
  protected
    function SearchTime: UInt64;
    override;
  end;
  TComboStateProbe = class
  private
    FCalls: Integer;
    FAccepts: Integer;
    FMode: Integer;
  public
    property Calls: Integer read FCalls write FCalls;
    property Accepts: Integer read FAccepts write FAccepts;
    property Mode: Integer read FMode write FMode;
  private
    FOrder: String;
  public
    property Order: String read FOrder write FOrder;
  private
    FClosedOnSelect: Boolean;
  public
    property ClosedOnSelect: Boolean read FClosedOnSelect write FClosedOnSelect;
    procedure Selected(Sender: TGuiControl);
    procedure Accepted(Sender: TGuiControl);
    procedure ReplaceItems(Sender: TGuiControl; const Event: TGuiEvent);
  end;
  TSpinModificationProbe = class
  private
    FChanges: Integer;
    FModified: Integer;
    FMode: Integer;
    FObservedValue: Integer;
  public
    property Changes: Integer read FChanges write FChanges;
    property Modified: Integer read FModified write FModified;
    property Mode: Integer read FMode write FMode;
    property ObservedValue: Integer read FObservedValue write FObservedValue;
  private
    FOrder: String;
    FObservedText: String;
  public
    property Order: String read FOrder write FOrder;
    property ObservedText: String read FObservedText write FObservedText;
  private
    FFreeWhenModified: Boolean;
  public
    property FreeWhenModified: Boolean read FFreeWhenModified write FFreeWhenModified;
    procedure Changed(Sender: TGuiControl);
    procedure ValueModified(Sender: TGuiControl);
  end;
  TSpinRepeatProbe = class(TGuiSpinEdit)
  private
    FTicks: UInt64;
  public
    property Ticks: UInt64 read FTicks write FTicks;
  private
    FCalls: Integer;
  public
    property Calls: Integer read FCalls write FCalls;
  private
    FCancelOnChange: Boolean;
    FFreeOnChange: Boolean;
  public
    property CancelOnChange: Boolean read FCancelOnChange write FCancelOnChange;
    property FreeOnChange: Boolean read FFreeOnChange write FFreeOnChange;
    procedure Changed(Sender: TGuiControl);
  protected
    function AnimationTime: UInt64;
    override;
  end;
  TNamedSpin = class(TGuiSpinEdit)
  protected
    function FormatValue(AValue: Integer): String;
    override;
    function TryParseValue(const AText: String; out AValue: Integer): Boolean;
    override;
  end;
  TWheelProbe = class(TGuiWheelPicker)
  private
    FTicks: UInt64;
  public
    property Ticks: UInt64 read FTicks write FTicks;
  private
    FPainted: Integer;
    FCenterIndex: Integer;
  public
    property Painted: Integer read FPainted write FPainted;
    property CenterIndex: Integer read FCenterIndex write FCenterIndex;
  private
    FCenterRect: TGuiRect;
  public
    property CenterRect: TGuiRect read FCenterRect write FCenterRect;
  protected
    function AnimationTime: UInt64;
    override;
    procedure PaintWheelItem(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect;
      ADisplacement: TGuiFloat);
      override;
  end;
  TRangeEventProbe = class
  private
    FChanges: Integer;
    FMoves: Integer;
  public
    property Changes: Integer read FChanges write FChanges;
    property Moves: Integer read FMoves write FMoves;
  private
    FLastThumb: TGuiRangeThumb;
  public
    property LastThumb: TGuiRangeThumb read FLastThumb write FLastThumb;
  private
    FLower: TGuiFloat;
    FUpper: TGuiFloat;
  public
    property Lower: TGuiFloat read FLower write FLower;
    property Upper: TGuiFloat read FUpper write FUpper;
    procedure Changed(Sender: TGuiControl);
    procedure Moved(Sender: TGuiControl; AThumb: TGuiRangeThumb);
  end;
  TDelayProbe = class(TGuiDelayButton)
  private
    FTicks: UInt64;
  public
    property Ticks: UInt64 read FTicks write FTicks;
    procedure ClickNow;
  protected
    function AnimationTime: UInt64;
    override;
  end;
  TRangeLifetimeProbe = class
  private
    FMode: Integer;
    FChanges: Integer;
    FMoves: Integer;
  public
    property Mode: Integer read FMode write FMode;
    property Changes: Integer read FChanges write FChanges;
    property Moves: Integer read FMoves write FMoves;
    procedure Changed(Sender: TGuiControl);
    procedure Moved(Sender: TGuiControl; AThumb: TGuiRangeThumb);
  end;
  TDelayLifetimeProbe = class
  private
    FCalls: Integer;
  public
    property Calls: Integer read FCalls write FCalls;
    procedure Activated(Sender: TGuiControl);
  end;
  TCheckListEventProbe = class
  private
    FFreeOnCheck: Boolean;
  public
    property FreeOnCheck: Boolean read FFreeOnCheck write FFreeOnCheck;
  private
    FChanges: Integer;
    FLastIndex: Integer;
  public
    property Changes: Integer read FChanges write FChanges;
    property LastIndex: Integer read FLastIndex write FLastIndex;
  private
    FObservedState: TGuiCheckBoxState;
  public
    property ObservedState: TGuiCheckBoxState read FObservedState write FObservedState;
    procedure Checked(Sender: TGuiControl; AIndex: Integer);
    procedure DeleteFirst(Sender: TGuiControl; const Event: TGuiEvent);
    procedure RemoveSelected(Sender: TGuiControl);
  end;
  TStateListProbe = class(TGuiListBox)
  protected
    function CreateItems: TStringList;
    override;
  end;
  TKnobWrapProbe = class
  private
    FFreeOnWrap: Boolean;
  public
    property FreeOnWrap: Boolean read FFreeOnWrap write FFreeOnWrap;
  private
    FClockwise: Integer;
    FCounterClockwise: Integer;
  public
    property Clockwise: Integer read FClockwise write FClockwise;
    property CounterClockwise: Integer read FCounterClockwise write FCounterClockwise;
  private
    FObservedValue: TGuiFloat;
  public
    property ObservedValue: TGuiFloat read FObservedValue write FObservedValue;
    procedure Wrapped(Sender: TGuiControl; ADirection: TGuiWrapDirection);
  end;
  TSpeedProbe = class(TGuiSpeedButton)
  public
    procedure ClickNow;
    function CheckedVisual: Boolean;
  end;
  TProgressProbe = class(TGuiProgressBar)
  private
    FTicks: UInt64;
  public
    property Ticks: UInt64 read FTicks write FTicks;
  protected
    function AnimationTime: UInt64;
    override;
  end;
  TPageIndicatorProbe = class(TGuiPageIndicator)
  private
    FPainted: Integer;
    FFirstIndex: Integer;
    FLastIndex: Integer;
    FSelectedDots: Integer;
    FPressedDots: Integer;
  public
    property Painted: Integer read FPainted write FPainted;
    property FirstIndex: Integer read FFirstIndex write FFirstIndex;
    property LastIndex: Integer read FLastIndex write FLastIndex;
    property SelectedDots: Integer read FSelectedDots write FSelectedDots;
    property PressedDots: Integer read FPressedDots write FPressedDots;
  private
    FFirstRect: TGuiRect;
  public
    property FirstRect: TGuiRect read FFirstRect write FFirstRect;
    procedure Reset;
  protected
    procedure PaintIndicator(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect;
      ASelected, APressed: Boolean);
      override;
  end;
  TActivityProbe = class(TGuiActivityIndicator)
  private
    FTicks: UInt64;
  public
    property Ticks: UInt64 read FTicks write FTicks;
  protected
    function AnimationTime: UInt64;
    override;
  end;
  TButtonLifetimeEvents = class
  private
    FMode: Integer;
    FChanges: Integer;
    FClicks: Integer;
  public
    property Mode: Integer read FMode write FMode;
    property Changes: Integer read FChanges write FChanges;
    property Clicks: Integer read FClicks write FClicks;
  private
    FVictim: TGuiControl;
  public
    property Victim: TGuiControl read FVictim write FVictim;
    procedure Changed(Sender: TGuiControl);
    procedure Clicked(Sender: TGuiControl);
    procedure NextState(Sender: TGuiControl; var State: TGuiCheckBoxState);
  end;

  TButtonRepeatProbe = class(TGuiButton)
  private
    FTicks: UInt64;
  public
    property Ticks: UInt64 read FTicks write FTicks;
  protected
    function AnimationTime: UInt64;
    override;
  end;
  TButtonRepeatEvents = class
  private
    FCalls: Integer;
  public
    property Calls: Integer read FCalls write FCalls;
  private
    FCancelOnClick: Boolean;
    FFreeOnClick: Boolean;
  public
    property CancelOnClick: Boolean read FCancelOnClick write FCancelOnClick;
    property FreeOnClick: Boolean read FFreeOnClick write FFreeOnClick;
    procedure Clicked(Sender: TGuiControl);
  end;

  TTabMotionProbe = class(TGuiTabControl)
  private
    FTicks: UInt64;
  public
    property Ticks: UInt64 read FTicks write FTicks;
  protected
    function AnimationTime: UInt64;
    override;
  end;

  TControlEventProbe = class
  private
    FChanges: Integer;
    FClicks: Integer;
    FNextCalls: Integer;
  public
    property Changes: Integer read FChanges write FChanges;
    property Clicks: Integer read FClicks write FClicks;
    property NextCalls: Integer read FNextCalls write FNextCalls;
  private
    FClickState: TGuiCheckBoxState;
  public
    property ClickState: TGuiCheckBoxState read FClickState write FClickState;
    procedure Changed(Sender: TGuiControl);
    procedure Clicked(Sender: TGuiControl);
    procedure NextChecked(Sender: TGuiControl; var AState: TGuiCheckBoxState);
  end;
  TCheckBoxProbe = class(TGuiCheckBox)
  public
    procedure ClickNow;
  end;

  TTableProbe = class
  private
    FClicks: Integer;
    FSelections: Integer;
  public
    property Clicks: Integer read FClicks write FClicks;
    property Selections: Integer read FSelections write FSelections;
    procedure ColumnClick(Sender: TGuiControl; AColumn: Integer);
    procedure Selection(Sender: TGuiControl);
    procedure Compare(Sender: TGuiControl; L, R: TStrings; AColumn: Integer; var AResult: Integer);
  end;

  TTestCanvas = class(TGuiCanvas)
  private
    FLastText: String;
  public
    property LastText: String read FLastText write FLastText;
  private
    FFillCount: Integer;
    FImageCount: Integer;
  public
    property FillCount: Integer read FFillCount write FFillCount;
    property ImageCount: Integer read FImageCount write FImageCount;
  private
    FTextDrawCount: Integer;
  public
    property TextDrawCount: Integer read FTextDrawCount write FTextDrawCount;
  private
    FMetricScale: TGuiFloat;
  public
    property MetricScale: TGuiFloat read FMetricScale write FMetricScale;
  private
    FClipDepth: Integer;
  public
    property ClipDepth: Integer read FClipDepth write FClipDepth;
  private
    FFirstClip: TGuiRect;
    FContentClip: TGuiRect;
    FLastFill: TGuiRect;
    FTailHeaderText: TGuiRect;
  public
    property FirstClip: TGuiRect read FFirstClip write FFirstClip;
    property ContentClip: TGuiRect read FContentClip write FContentClip;
    property LastFill: TGuiRect read FLastFill write FLastFill;
    property TailHeaderText: TGuiRect read FTailHeaderText write FTailHeaderText;
  private
    FLastTextRect: TGuiRect;
  public
    property LastTextRect: TGuiRect read FLastTextRect write FLastTextRect;
  private
    FLastColor: TGuiColor;
  public
    property LastColor: TGuiColor read FLastColor write FLastColor;
    procedure FillRect(const ARect: TGuiRect; const AColor: TGuiColor);
    override;
    procedure DrawBorder(const ARect: TGuiRect; AWidth: TGuiFloat; const AColor: TGuiColor);
    override;
    procedure DrawImage(ATexture: TGuiTexture; const ARect: TGuiRect);
    override;
    procedure DrawText(const AText: String; const ARect: TGuiRect; const AColor: TGuiColor;
      AHorizontal: TGuiHorizontalTextAlign; AVertical: TGuiVerticalTextAlign);
      override;
    function MeasureText(const AText: String): TGuiSize;
    override;
    function TextMetricsKey: String;
    override;
    procedure PushClipRect(const ARect: TGuiRect);
    override;
    procedure PopClipRect;
    override;
  end;

  TProbe = class(TGuiButton)
  private
    FKeyUps: Integer;
  public
    property KeyUps: Integer read FKeyUps write FKeyUps;
  private
    FMenuClicks: Integer;
  public
    property MenuClicks: Integer read FMenuClicks write FMenuClicks;
    procedure MenuClick(Sender: TObject);
    procedure HandleEvent(var AEvent: TGuiEvent);
    override;
  end;

procedure Check(ACondition: Boolean; const AMessage: String);
forward;

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

procedure SetBoundsLeft(AControl: TGuiControl; AValue: TGuiFloat);
var
  CurrentBounds: TGuiRect;
begin
  CurrentBounds:=AControl.Bounds;
  CurrentBounds.Left:=AValue;
  AControl.Bounds:=CurrentBounds;
end;

procedure SetStyleScrollBarSize(AControl: TGuiControl; AValue: TGuiFloat);
var
  CurrentStyle: TGuiStyle;
begin
  CurrentStyle:=AControl.Style;
  CurrentStyle.ScrollBarSize:=AValue;
  AControl.Style:=CurrentStyle;
end;

procedure SetStyleTrack(AControl: TGuiControl; const AValue: TGuiDrawable);
var
  CurrentStyle: TGuiStyle;
begin
  CurrentStyle:=AControl.Style;
  CurrentStyle.Track:=AValue;
  AControl.Style:=CurrentStyle;
end;

procedure SetStyleThumb(AControl: TGuiControl; const AValue: TGuiDrawable);
var
  CurrentStyle: TGuiStyle;
begin
  CurrentStyle:=AControl.Style;
  CurrentStyle.Thumb:=AValue;
  AControl.Style:=CurrentStyle;
end;

procedure SetThemeGeometry(var ATheme: TGuiTheme; AControlRadius, APanelRadius, AFocusWidth: TGuiFloat);
var
  Metrics: TGuiThemeMetrics;
begin
  Metrics:=ATheme.Metrics;
  Metrics.ControlCornerRadius:=AControlRadius;
  Metrics.PanelCornerRadius:=APanelRadius;
  Metrics.FocusWidth:=AFocusWidth;
  ATheme.Metrics:=Metrics;
end;

procedure SetThemeLineHeight(var ATheme: TGuiTheme; AValue: TGuiFloat);
var
  Metrics: TGuiThemeMetrics;
begin
  Metrics:=ATheme.Metrics;
  Metrics.LineHeight:=AValue;
  ATheme.Metrics:=Metrics;
end;

procedure TSpinModificationProbe.Changed(Sender: TGuiControl);
begin
  Inc(FChanges);
  Order:=Order+'C';
  case Mode of
    1:
    begin
      Mode:=0;
      TGuiSpinEdit(Sender).Value:=40;
    end;
    2: TGuiSpinEdit(Sender).Increment:=2;
    3: Sender.Free;
    4:
    begin
      Mode:=0;
      TGuiSpinEdit(Sender).StepBy(1);
    end;
    5: raise Exception.Create('Expected spin callback exception');
    6:
    begin
      Mode:=3;
      TGuiSpinEdit(Sender).StepBy(1);
    end;
    7: TGuiSpinEdit(Sender).Value:=TGuiSpinEdit(Sender).Value;
  end;
end;

procedure TSpinModificationProbe.ValueModified(Sender: TGuiControl);
begin
  Inc(FModified);
  Order:=Order+'M';
  ObservedValue:=TGuiSpinEdit(Sender).Value;
  ObservedText:=TGuiSpinEdit(Sender).Text;
  if FreeWhenModified then Sender.Free;
end;

function SpinClipboardText: String;
begin
  Result:='67';
end;

procedure TestSpinModification;
var C: TGuiContext;
S: TSpinRepeatProbe;
P: TSpinModificationProbe;
Canvas: TTestCanvas;
  E: TGuiEvent;
  Rejected: Boolean;
  procedure ResetProbe;
  begin
    P.Changes:=0;
    P.Modified:=0;
    P.Order:='';
  end;
  procedure Key(Code: Integer; Ctrl: Boolean = False);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    if Ctrl then E.Modifiers:=[gemCtrl];
    C.ProcessEvent(E);
  end;
  procedure Input(const AText: String);
  begin
    S.SelectAll;
    E:=Default(TGuiEvent);
    E.Kind:=gekTextInput;
    E.Text:=UTF8String(AText);
    C.ProcessEvent(E);
  end;
  procedure NewSpin;
  begin
    S:=TSpinRepeatProbe.Create;
    S.Bounds:=GuiRect(0,0,200,40);
    C.Root.Add(S);
    C.SetFocus(S);
    S.OnChange:=P.Changed;
    S.OnValueModified:=P.ValueModified;
  end;
begin
  C:=TGuiContext.Create;
  P:=TSpinModificationProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(300,200);
    NewSpin;
    S.Value:=12;
    Check((P.Order='C') AND (P.Modified=0),'Programmatic spin value emits only general change');
    S.Live:=True;
    ResetProbe;
    S.Text:='24';
    Check((S.Value=24) AND (P.Order='C'),'Programmatic live spin Text does not emit user modification');
    S.Live:=False;
    S.Text:='35';
    ResetProbe;
    S.Live:=True;
    Check((S.Value=35) AND (P.Order='C'),'Enabling live mode commits pending text without user notification');
    ResetProbe;
    S.MinValue:=40;
    Check((S.Value=40) AND (P.Order='C'),'Range clamping is programmatic, not user modification');
    S.MinValue:=0;
    S.Live:=False;
    ResetProbe;
    Input('42');
    Check(P.Order='','Deferred typing emits no numeric events');
    Key(13);
    Check((P.Order='CM') AND (P.ObservedValue=42) AND (P.ObservedText='42'),'Enter notifies general then user event with committed state');
    ResetProbe;
    Key(13);
    Check(P.Order='','Repeated unchanged commit does not notify');
    Input('43');
    C.ClearFocus;
    Check((S.Value=43) AND (P.Order='CM'),'Focus-loss commit reports user modification');
    C.SetFocus(S);
    ResetProbe;
    Input('bad');
    Key(13);
    Input('44');
    Key(27);
    Check((S.Value=43) AND (P.Order=''),'Invalid commit and Escape do not report numeric modifications');
    ResetProbe;
    Input('999');
    Key(13);
    Check((S.Value=100) AND (P.Order='CM'),'Out-of-range commit reports clamped user value once');
    ResetProbe;
    S.StepBy(1);
    Check(P.Order='','Unchanged endpoint step does not report modification');
    S.Value:=50;
    ResetProbe;
    S.StepBy(1);
    Check(P.Order='CM','Explicit StepBy is a user-style edit command');
    ResetProbe;
    Key($40000051);
    Check((S.Value=50) AND (P.Order='CM'),'Keyboard stepping reports user modification');
    S.Editable:=False;
    ResetProbe;
    Key($4000004A);
    Key($4000004D);
    Check((S.Value=100) AND (P.Order='CMCM'),'Noneditable Home/End report user changes');
    S.Editable:=True;
    S.Live:=True;
    ResetProbe;
    Input('25');
    Check((P.Order='CM') AND (P.ObservedText='25'),'Live input reports user numeric change without rewriting buffer');
    ResetProbe;
    Input('-');
    Check(P.Order='','Incomplete live input does not report numeric change');
    Input('30');
    ResetProbe;
    Key(90,True);
    Check(P.Order='','Undo to invalid pending text does not change live value');
    Key(90,True);
    Check((S.Value=25) AND (P.Order='CM'),'Keyboard undo reports changed live value');
    ResetProbe;
    S.Redo;
    Check(P.Order='','Redo to invalid buffer does not notify');
    S.Redo;
    Check((S.Value=30) AND (P.Order='CM'),'Explicit redo command reports live user modification');
    GuiRegisterClipboardProvider(SpinClipboardText,nil);
    ResetProbe;
    S.SelectAll;
    Key(86,True);
    Check((S.Value=67) AND (P.Order='CM'),'Keyboard paste reports live user modification');
    ResetProbe;
    S.SetSelection(1,2);
    Key(88,True);
    Check((S.Value=6) AND (P.Order='CM'),'Keyboard cut reports live user modification');
    ResetProbe;
    S.SelectAll;
    S.PasteFromClipboard;
    Check((S.Value=67) AND (P.Order='CM'),'Explicit paste command reports live user modification');
    ResetProbe;
    Key(8);
    Check((S.Value=6) AND (P.Order='CM'),'Backspace reports changed live numeric value');
    ResetProbe;
    E:=Default(TGuiEvent);
    E.Kind:=gekTextEditing;
    E.Text:='88';
    C.ProcessEvent(E);
    Check(P.Order='','Composition preview does not report numeric change');
    Key(13);
    Check(P.Order='','Enter during composition does not commit spin value');
    Input('88');
    Check((S.Value=88) AND (P.Order='CM'),'Committed composition text reports user numeric change');
    S.Enabled:=False;
    ResetProbe;
    Key($40000052);
    Input('90');
    S.StepBy(1);
    Check(P.Order='','Disabled routed input and stepping emit no user notifications');
    S.Enabled:=True;
    S.Live:=False;
    S.Value:=50;
    ResetProbe;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseWheel;
    E.Delta:=GuiPoint(0,1);
    C.SetFocus(S);
    S.HandleEvent(E);
    Check(E.Handled AND (P.Order='CM'),'Wheel reports user modification and consumes changed value');
    ResetProbe;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(190,10);
    S.Ticks:=1000;
    C.ProcessEvent(E);
    S.Ticks:=1400;
    C.Paint(Canvas);
    Check(P.Order='CMCM','Primary press and held repeat each report one user change');
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseUp;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(190,10);
    C.ProcessEvent(E);
    ResetProbe;
    P.Mode:=1;
    S.StepBy(1);
    Check((S.Value=40) AND (P.Order='CC'),'Callback replacement suppresses stale user notification');
    ResetProbe;
    P.Mode:=2;
    S.StepBy(1);
    Check(P.Order='C','Callback configuration change suppresses stale user notification');
    ResetProbe;
    P.Mode:=7;
    S.StepBy(1);
    Check(P.Order='C','Explicit same-value replacement suppresses outer user notification');
    P.Mode:=0;
    S.Increment:=1;
    ResetProbe;
    P.Mode:=4;
    S.StepBy(1);
    Check(P.Order='CCM','Nested user change reports inner value, not stale outer value');
    ResetProbe;
    P.Mode:=5;
    Rejected:=False;
    try
      S.StepBy(1);
    except
      on Exception do Rejected:=True;
    end;
    Check(Rejected AND (P.Order='C'),'Callback exception propagates without user event');
    P.Mode:=0;
    ResetProbe;
    S.StepBy(1);
    Check(P.Order='CM','Notification guard recovers after callback exception');
    ResetProbe;
    P.Mode:=3;
    S.StepBy(1);
    S:=nil;
    Check((C.Root.ChildCount=0) AND (P.Order='C'),'General callback removal suppresses second event safely');
    P.Mode:=0;
    NewSpin;
    ResetProbe;
    P.FreeWhenModified:=True;
    S.StepBy(1);
    S:=nil;
    Check((C.Root.ChildCount=0) AND (P.Order='CM'),'User callback may remove spin safely');
    P.FreeWhenModified:=False;
    NewSpin;
    ResetProbe;
    P.Mode:=6;
    S.StepBy(1);
    S:=nil;
    Check((C.Root.ChildCount=0) AND (P.Order='CC'),'Nested callback removal invalidates all notification guards');
    P.Mode:=0;
    NewSpin;
    S.Live:=True;
    Input('12');
    Input('34');
    ResetProbe;
    P.FreeWhenModified:=True;
    S.Undo;
    S:=nil;
    Check((C.Root.ChildCount=0) AND (P.Order='CM'),'Live undo may remove spin after history restoration');
    P.FreeWhenModified:=False;
    NewSpin;
    S.Ticks:=1000;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(190,10);
    C.ProcessEvent(E);
    ResetProbe;
    P.FreeWhenModified:=True;
    S.Ticks:=1400;
    C.Paint(Canvas);
    S:=nil;
    Check((C.Root.ChildCount=0) AND (P.Order='CM'),'Held-repeat user callback may remove spin before traversal');
  finally
    GuiRegisterClipboardProvider(nil,nil);
    Canvas.Free;
    P.Free;
    C.Free;
  end;
end;

function TSpinRepeatProbe.AnimationTime: UInt64;
begin
  Result:=Ticks;
end;

procedure TSpinRepeatProbe.Changed(Sender: TGuiControl);
begin
  Inc(FCalls);
  if CancelOnChange then Value:=Value;
  if FreeOnChange then Free;
end;

procedure TestSpinRepeat;
var C: TGuiContext;
S: TSpinRepeatProbe;
Canvas: TTestCanvas;
  E: TGuiEvent;
  Before: Integer;
  Rejected: Boolean;
  procedure Mouse(Kind: TGuiEventKind; X,Y: Single);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,Y);
    C.ProcessEvent(E);
  end;
  procedure Start;
  begin
    Mouse(gekMouseUp,190,10);
    S.Value:=50;
    S.Ticks:=1000;
    Mouse(gekMouseDown,190,10);
  end;
  procedure Tick(ATime: UInt64);
  begin
    S.Ticks:=ATime;
    C.Paint(Canvas);
  end;
begin
  C:=TGuiContext.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(300,200);
    S:=TSpinRepeatProbe.Create;
    S.Bounds:=GuiRect(0,0,200,40);
    C.Root.Add(S);
    S.OnChange:=S.Changed;
    Check(S.AutoRepeat AND (S.RepeatDelay=400) AND (S.RepeatInterval=75),'Spin repeat has default delay and interval');
    Start;
    Check(S.Value=51,'Spin held arrow steps immediately');
    Tick(1399);
    Check(S.Value=51,'Spin repeat waits initial delay');
    Tick(1400);
    Check(S.Value=52,'Spin repeat starts exactly at delay');
    Tick(1474);
    Check(S.Value=52,'Spin repeat waits interval');
    Tick(1475);
    Check(S.Value=53,'Captured and focused spin repeats only once per timestamp');
    Tick(100000);
    Check(S.Value=54,'Stalled frame emits one spin step, not a catch-up burst');
    Mouse(gekMouseUp,190,10);
    Tick(100100);
    Check(S.Value=54,'Release stops spin repeat');
    S.Value:=50;
    S.Ticks:=1000;
    Mouse(gekMouseDown,190,30);
    Tick(1400);
    Check(S.Value=48,'Down arrow repeats in decreasing direction');
    Mouse(gekMouseUp,190,30);
    S.Value:=99;
    S.Ticks:=1000;
    Mouse(gekMouseDown,190,10);
    Before:=S.Calls;
    Tick(1400);
    Check((S.Value=100) AND (S.Calls=Before),'Repeat at endpoint does not notify unchanged value');
    Mouse(gekMouseUp,190,10);
    S.Wrap:=True;
    S.Value:=99;
    S.Ticks:=1000;
    Mouse(gekMouseDown,190,10);
    Tick(1400);
    Check(S.Value=0,'Held arrow wraps through range endpoint');
    S.Wrap:=False;
    Start;
    Mouse(gekMouseMove,190,30);
    Tick(2000);
    Check(S.Value=51,'Moving to opposite arrow cancels without reversing');
    Mouse(gekMouseMove,190,10);
    Tick(3000);
    Check(S.Value=51,'Returning to arrow does not restart cancelled repeat');
    Start;
    C.ClearFocus;
    Tick(2000);
    Check(S.Value=51,'Blur cancels spin repeat');
    Start;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=27;
    C.ProcessEvent(E);
    Tick(2000);
    Check(S.Value=51,'Escape cancels spin repeat');
    Start;
    C.Root.Enabled:=False;
    Tick(2000);
    C.Root.Enabled:=True;
    Tick(3000);
    Check(S.Value=51,'Disabled ancestry cancels rather than suspends spin repeat');
    Start;
    S.Visible:=False;
    Tick(2000);
    S.Visible:=True;
    Tick(3000);
    Check(S.Value=51,'Hidden spin cancels repeat');
    Start;
    S.Value:=51;
    Tick(2000);
    Check(S.Value=51,'Same-value assignment cancels spin repeat');
    Start;
    S.Increment:=2;
    Tick(2000);
    Check(S.Value=51,'Increment change cancels spin repeat');
    S.Increment:=1;
    Start;
    S.MaxValue:=90;
    Tick(2000);
    Check(S.Value=51,'Range change cancels spin repeat');
    S.MaxValue:=100;
    Start;
    S.RepeatDelay:=500;
    Tick(2000);
    Check(S.Value=51,'Repeat timing change cancels current hold');
    S.RepeatDelay:=400;
    Start;
    S.Text:='60';
    Tick(2000);
    Check(S.Value=51,'Text replacement cancels spin repeat');
    Start;
    Tick(999);
    Tick(2000);
    Check(S.Value=51,'Clock rollback cancels spin repeat');
    Start;
    Tick(High(UInt64));
    Check(S.Value=52,'Huge timestamp safely emits one repeat');
    S.AutoRepeat:=False;
    Start;
    Tick(2000);
    Check(S.Value=51,'AutoRepeat false retains single click');
    S.AutoRepeat:=True;
    S.RepeatDelay:=0;
    S.RepeatInterval:=10;
    Start;
    Tick(1000);
    Check(S.Value=52,'Zero delay starts on next update');
    Tick(1010);
    Check(S.Value=53,'Custom repeat interval is honored');
    Rejected:=False;
    try
      S.RepeatInterval:=0;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (S.RepeatInterval=10),'Zero repeat interval is rejected without mutation');
    S.RepeatDelay:=400;
    Start;
    S.CancelOnChange:=True;
    Tick(1400);
    Before:=S.Value;
    Tick(2000);
    Check((Before=52) AND (S.Value=Before),'Reentrant value assignment cancels further repeats');
    S.CancelOnChange:=False;
    Start;
    S.FreeOnChange:=True;
    Tick(1400);
    S:=nil;
    Check(C.Root.ChildCount=0,'Repeat callback may remove spin before paint traversal');
  finally
    Canvas.Free;
    C.Free;
  end;
end;

function TNamedSpin.FormatValue(AValue: Integer): String;
begin
  Result:='Level '+IntToStr(AValue);
end;

function TNamedSpin.TryParseValue(const AText: String; out AValue: Integer): Boolean;
begin
  Result:=Copy(AText,1,6)='Level ';
  AValue:=0;
  if Result then Result:=TryStrToInt(Copy(AText,7,MaxInt),AValue);
end;

procedure TestSpinEditing;
var C: TGuiContext;
S: TGuiSpinEdit;
Named: TNamedSpin;
P: TControlEventProbe;
  E: TGuiEvent;
  Before: Integer;
  Canvas: TTestCanvas;
  procedure Input(const TextValue: String);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekTextInput;
    E.Text:=UTF8String(TextValue);
    C.ProcessEvent(E);
  end;
  procedure ReplaceText(const TextValue: String);
  begin
    S.SelectAll;
    Input(TextValue);
  end;
  procedure Key(Code: Integer);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  P:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(300,200);
    S:=TGuiSpinEdit.Create;
    S.Bounds:=GuiRect(0,0,200,40);
    C.Root.Add(S);
    S.MinValue:=-100;
    S.Value:=12;
    S.OnChange:=P.Changed;
    C.SetFocus(S);
    Check(S.Editable AND NOT S.Live AND (S.Text='12') AND S.InputValid,'Spin editor starts with synchronized numeric text and deferred input');
    ReplaceText('34');
    Check((S.Value=12) AND (S.Text='34') AND S.Editing AND (P.Changes=0),'Typing changes edit buffer without committing numeric value');
    Key(13);
    Check((S.Value=34) AND NOT S.Editing AND (P.Changes=1),'Enter commits spin input once');
    S.Live:=True;
    ReplaceText('-');
    Check((S.Value=34) AND NOT S.InputValid,'Incomplete minus remains editable without changing live value');
    Input('5');
    Check((S.Value=-5) AND (S.Text='-5') AND S.InputValid,'Live input accepts valid signed integer without rewriting buffer');
    S.CancelEdit;
    Check(S.Value=-5,'Cancelling live text retains already committed numeric changes');
    S.Live:=False;
    Before:=P.Changes;
    ReplaceText('junk');
    Check(NOT S.CommitEdit AND (S.Text='-5') AND (P.Changes=Before),'Invalid spin text reverts without changing value');
    ReplaceText('200');
    Check(NOT S.InputValid AND (S.Value=-5),'Out-of-range spin buffer remains pending');
    Check(S.CommitEdit AND (S.Value=100) AND (S.Text='100'),'Commit clamps parsed integer to numeric range');
    ReplaceText('999999999999999999999');
    Check(NOT S.CommitEdit AND (S.Value=100),'Overflowing input is rejected safely');
    ReplaceText('$10');
    Check(NOT S.CommitEdit AND (S.Value=100),'Default spin parser rejects hexadecimal syntax');
    S.Increment:=5;
    Before:=P.Changes;
    ReplaceText('40');
    S.StepBy(1);
    Check((S.Value=45) AND (S.Text='45') AND (P.Changes=Before+1),'Stepping pending input combines parse and increment into one numeric change');
    ReplaceText('60');
    Key(27);
    Check((S.Value=45) AND (S.Text='45'),'Escape restores committed spin text');
    ReplaceText('70');
    C.ClearFocus;
    Check((S.Value=70) AND NOT S.Editing,'Focus loss commits valid spin input');
    C.SetFocus(S);
    S.Editable:=False;
    ReplaceText('20');
    Check(S.Value=70,'Noneditable spin ignores text input');
    Key($40000052);
    Check((S.Value=75) AND (S.Text='75'),'Noneditable spin still supports arrow stepping');
    S.Editable:=True;
    ReplaceText('12');
    Input('3');
    S.Undo;
    Check(S.Text='12','Spin editor preserves text undo');
    S.Redo;
    Check(S.Text='123','Spin editor preserves text redo');
    S.CancelEdit;
    ReplaceText('20');
    E:=Default(TGuiEvent);
    E.Kind:=gekTextEditing;
    E.Text:='9';
    C.ProcessEvent(E);
    Before:=S.Value;
    Key($40000052);
    Key(13);
    Check((S.Value=Before) AND (S.CompositionText='9'),'Composition blocks spin stepping and premature Enter commit');
    Key(27);
    Check((S.CompositionText='') AND (S.Text='20'),'Escape cancels composition without discarding pending numeric buffer');
    S.CancelEdit;
    S.Paint(Canvas);
    Check((Canvas.LastTextRect.Left+Canvas.LastTextRect.Width<=172) AND (Canvas.ClipDepth=0),'Spin text layout reserves arrow-button lane');
    Check(S.MouseCursorAt(GuiPoint(190,10))=gmcArrow,'Spin arrow buttons do not show a text cursor');
    Named:=TNamedSpin.Create;
    try
      Named.Value:=7;
      Check(Named.Text='Level 7','Custom spin formatter applies to programmatic values');
      Named.Text:='Level 12';
      Check(Named.CommitEdit AND (Named.Value=12),'Custom parser commits named numeric representation');
    finally
      Named.Free;
    end;
  finally
    Canvas.Free;
    P.Free;
    C.Free;
  end;
end;

procedure TestSpinStepping;
var S: TGuiSpinEdit;
P: TControlEventProbe;
E: TGuiEvent;
Before: Integer;
Rejected: Boolean;
  procedure Key(Code: Integer);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    S.HandleEvent(E);
  end;
  procedure Mouse(Button: TGuiMouseButton; Y: TGuiFloat);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=Button;
    E.Position:=GuiPoint(190,Y);
    S.HandleEvent(E);
  end;
  procedure Wheel(Direction: TGuiFloat);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseWheel;
    E.Delta:=GuiPoint(0,Direction);
    S.HandleEvent(E);
  end;
begin
  S:=TGuiSpinEdit.Create;
  P:=TControlEventProbe.Create;
  try
    S.Bounds:=GuiRect(0,0,200,40);
    S.OnChange:=P.Changed;
    Check((S.Value=0) AND (S.Increment=1) AND NOT S.Wrap,'Spin defaults remain nonwrapping with unit increment');
    S.Value:=50;
    Before:=P.Changes;
    S.Enabled:=False;
    Key($40000052);
    Mouse(gmbLeft,10);
    Wheel(1);
    S.StepBy(5);
    Check((S.Value=50) AND (P.Changes=Before),'Disabled spin ignores direct keys, pointer, wheel and stepping');
    S.Value:=40;
    Check(S.Value=40,'Programmatic spin assignment remains available while disabled');
    S.Enabled:=True;
    Before:=P.Changes;
    Mouse(gmbRight,10);
    Mouse(gmbMiddle,30);
    Check((S.Value=40) AND (P.Changes=Before),'Secondary mouse buttons cannot step spin editor');
    Mouse(gmbLeft,10);
    Check(S.Value=41,'Primary up button increments');
    Mouse(gmbLeft,30);
    Check(S.Value=40,'Primary down button decrements');
    S.Increment:=5;
    Wheel(1);
    Check((S.Value=45) AND E.Handled,'Wheel increments spin value and consumes changed input');
    Wheel(-1);
    Check(S.Value=40,'Wheel decrements spin value');
    S.Value:=100;
    Before:=P.Changes;
    Wheel(1);
    Check((S.Value=100) AND NOT E.Handled AND (P.Changes=Before),'Unchanged endpoint wheel can bubble without notifying');
    S.Wrap:=True;
    Wheel(1);
    Check((S.Value=0) AND E.Handled,'Wrapping spin advances from maximum to minimum');
    Wheel(-1);
    Check(S.Value=100,'Wrapping spin reverses from minimum to maximum');
    S.Value:=98;
    S.StepBy(1);
    Check(S.Value=0,'Wrapped overshoot lands on opposite endpoint');
    S.Wrap:=False;
    S.MinValue:=Low(Integer);
    S.MaxValue:=High(Integer);
    S.Increment:=10;
    S.Value:=High(Integer)-1;
    Key($40000052);
    Check(S.Value=High(Integer),'Positive spin overflow clamps to maximum, not minimum');
    S.Value:=Low(Integer)+1;
    Key($40000051);
    Check(S.Value=Low(Integer),'Negative spin overflow clamps to minimum, not maximum');
    S.Wrap:=True;
    S.StepBy(-1);
    Check(S.Value=High(Integer),'Wrapping handles full signed integer limits');
    S.Wrap:=False;
    S.Increment:=High(Integer);
    S.Value:=0;
    S.StepBy(High(Integer));
    Check(S.Value=High(Integer),'Large positive step count uses wide arithmetic');
    S.StepBy(Low(Integer));
    Check(S.Value=Low(Integer),'Large negative step count uses wide arithmetic');
    Rejected:=False;
    try
      S.Increment:=0;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (S.Increment=High(Integer)),'Zero increment rejected without mutation');
    Rejected:=False;
    try
      S.Increment:=-1;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected,'Negative increment rejected');
    S.MinValue:=7;
    S.MaxValue:=7;
    Before:=P.Changes;
    S.Wrap:=True;
    S.StepBy(1);
    S.StepBy(-1);
    S.StepBy(0);
    Check((S.Value=7) AND (P.Changes=Before),'Collapsed spin range never notifies unchanged steps');
  finally
    P.Free;
    S.Free;
  end;
end;

procedure TWheelProbe.PaintWheelItem(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect;
  ADisplacement: TGuiFloat);
begin
  Inc(FPainted);
  if Abs(ADisplacement)<0.001 then
  begin
    CenterIndex:=AIndex;
    CenterRect:=ARect;
  end;
  inherited;
end;

function TWheelProbe.AnimationTime: UInt64;
begin
  Result:=Ticks;
end;

procedure TestWheelLifetime;
var C: TGuiContext;
W: TWheelProbe;
P: TButtonLifetimeEvents;
E: TGuiEvent;
  I,Action: Integer;
  procedure Mouse(Kind: TGuiEventKind; Y: Single; Ticks: UInt64);
  begin
    W.Ticks:=Ticks;
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(80,Y);
    C.ProcessEvent(E);
    end;
begin
  C:=TGuiContext.Create;
  P:=TButtonLifetimeEvents.Create;
  try
    C.Resize(300,300);
    for Action:=0 to 1 do
    begin
      W:=TWheelProbe.Create;
      C.Root.Add(W);
      W.Bounds:=GuiRect(0,0,160,200);
      W.Padding:=GuiBox(0);
      for I:=0 to 19 do W.AddItem(IntToStr(I));
      W.ItemIndex:=5;
      P.Changes:=0;
      if Action=0 then P.Mode:=1 else P.Mode:=3;
      Mouse(gekMouseDown,100,1000);
      Mouse(gekMouseMove,60,1100);
      W.OnChange:=P.Changed;
      Mouse(gekMouseUp,20,1120);
      if Action=0 then Check((C.Root.ChildCount=0) AND (C.FocusedControl=nil) AND (P.Changes=1),
        'Wheel release callback may free its sender')
      else Check(NOT W.Enabled AND NOT W.Moving AND (P.Changes=1),
        'Wheel release callback disabling sender prevents inertia from starting');
      C.CancelInput;
      C.Root.Clear;
    end;
  finally
    P.Free;
    C.Free;
  end;
end;

procedure TestWheelMotion;
var C: TGuiContext;
W: TWheelProbe;
Canvas: TTestCanvas;
E: TGuiEvent;
I: Integer;
Rejected: Boolean;
  procedure Mouse(Kind: TGuiEventKind; Y: TGuiFloat; Ticks: UInt64);
  begin
    W.Ticks:=Ticks;
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(80,Y);
    C.ProcessEvent(E);
  end;
  procedure Flick(Index: Integer);
  begin
    W.ItemIndex:=Index;
    Mouse(gekMouseDown,100,1000);
    Mouse(gekMouseMove,60,1100);
    Mouse(gekMouseUp,60,1120);
  end;
begin
  C:=TGuiContext.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(300,300);
    W:=TWheelProbe.Create;
    C.Root.Add(W);
    W.Bounds:=GuiRect(0,0,160,200);
    W.Padding:=GuiBox(0);
    for I:=0 to 19 do W.AddItem(IntToStr(I));
    Check(W.FlickEnabled AND (W.Deceleration=20) AND (W.SettleDuration=150),'Wheel defaults enable flick and 150ms settling');
    Flick(5);
    Check(W.Moving AND (W.ItemIndex=6),'Release preserves recent drag velocity');
    W.Ticks:=1620;
    C.Paint(Canvas);
    Check(W.Moving AND (Abs(W.ScrollPosition-8.5)<0.001) AND (W.ItemIndex=9),'Context frame advances analytic wheel deceleration');
    W.Ticks:=1695;
    W.UpdateMotion;
    Check(W.Moving AND (Abs(W.ScrollPosition-8.9375)<0.001),'Wheel smoothly eases toward nearest row after deceleration');
    W.Ticks:=1770;
    W.UpdateMotion;
    Check(NOT W.Moving AND (W.ScrollPosition=9),'Wheel finishes exactly at centered row');
    Flick(5);
    W.Ticks:=1770;
    W.UpdateMotion;
    Check(NOT W.Moving AND (W.ItemIndex=9),'Sparse and dense frame updates produce identical flick destination');
    Flick(5);
    W.Ticks:=1620;
    W.UpdateMotion;
    Mouse(gekMouseDown,100,1620);
    Check(NOT W.Moving AND (Abs(W.ScrollPosition-8.5)<0.001),'Grabbing a moving wheel stops inertia without snapping its displayed position');
    Mouse(gekMouseUp,100,1640);
    Flick(19);
    W.Ticks:=1770;
    W.UpdateMotion;
    Check(NOT W.Moving AND (W.ItemIndex=3),'Flick continues across wrapping boundary');
    W.Wrap:=False;
    Flick(18);
    W.Ticks:=1220;
    W.UpdateMotion;
    Check(NOT W.Moving AND (W.ItemIndex=19),'Nonwrapping flick stops at terminal row');
    W.Wrap:=True;
    W.ItemIndex:=5;
    Mouse(gekMouseDown,100,2000);
    Mouse(gekMouseMove,50,2100);
    Mouse(gekMouseUp,50,2400);
    W.Ticks:=2550;
    W.UpdateMotion;
    Check(NOT W.Moving AND (W.ItemIndex=6),'Pause before release discards stale flick velocity but settles fraction');
    Flick(5);
    C.ClearFocus;
    W.Ticks:=1770;
    W.UpdateMotion;
    Check(NOT W.Moving AND (W.ItemIndex=6),'Focus loss cancels kinetic motion');
    Flick(5);
    C.Root.Enabled:=False;
    W.Ticks:=1770;
    C.Paint(Canvas);
    Check(NOT W.Moving AND (W.ItemIndex=6),'Disabled ancestry cancels inertia before frame callbacks');
    C.Root.Enabled:=True;
    Flick(5);
    W.Items.Delete(0);
    W.Ticks:=1770;
    W.UpdateMotion;
    Check(NOT W.Moving AND (W.ItemIndex=6),'Collection mutation cancels inertia');
    Flick(5);
    W.Ticks:=1119;
    W.UpdateMotion;
    Check(NOT W.Moving,'Clock rollback cancels wheel animation');
    Flick(5);
    W.Ticks:=High(UInt64);
    W.UpdateMotion;
    Check(NOT W.Moving AND (W.ItemIndex=9),'Huge elapsed time reaches final centered row without stepping frames');
    Rejected:=False;
    try
      W.Deceleration:=0;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (W.Deceleration=20),'Invalid deceleration rejected without mutation');
    W.FlickEnabled:=False;
    W.SettleDuration:=0;
    W.ItemIndex:=5;
    Mouse(gekMouseDown,100,3000);
    Mouse(gekMouseMove,50,3100);
    Mouse(gekMouseUp,50,3120);
    Check(NOT W.Moving AND (W.ScrollPosition=6),'Flick and animated settling can both be disabled');
  finally
    Canvas.Free;
    C.Free;
  end;
end;

procedure TestWheelPicker;
var C: TGuiContext;
W: TWheelProbe;
P: TControlEventProbe;
Canvas: TTestCanvas;
  E: TGuiEvent;
  I,Before: Integer;
  Rejected: Boolean;
  procedure Mouse(Kind: TGuiEventKind; Y: TGuiFloat);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(80,Y);
    C.ProcessEvent(E);
  end;
  procedure Key(Code: Integer);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  P:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(300,300);
    W:=TWheelProbe.Create;
    W.Bounds:=GuiRect(0,0,160,200);
    W.Padding:=GuiBox(0);
    C.Root.Add(W);
    W.FlickEnabled:=False;
    W.SettleDuration:=0;
    W.OnChange:=P.Changed;
    Check((W.ItemIndex=-1) AND (W.VisibleItemCount=5) AND NOT W.Wrap,'Wheel starts empty with automatic wrapping');
    W.AddItem('Only');
    Check((W.ItemIndex=0) AND (P.Changes=1) AND NOT W.Wrap,'First wheel item becomes current and notifies');
    W.ItemIndex:=-1;
    Check(W.ItemIndex=0,'Nonempty wheel always has a current item');
    for I:=1 to 9 do W.AddItem(IntToStr(I));
    Check(W.Wrap,'Automatic wheel wrapping enables when items exceed visible rows');
    C.SetFocus(W);
    Key($40000052);
    Check(W.ItemIndex=9,'Up wraps from first wheel item to last');
    Key($40000051);
    Check(W.ItemIndex=0,'Down wraps back to first wheel item');
    W.Wrap:=False;
    Before:=P.Changes;
    Key($40000052);
    Check((W.ItemIndex=0) AND (P.Changes=Before),'Nonwrapping wheel clamps without duplicate notification');
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseWheel;
    E.Delta:=GuiPoint(0,1);
    W.HandleEvent(E);
    Check(NOT E.Handled,'Wheel input at nonwrapping endpoint can bubble to parent');
    Key($4000004D);
    Check(W.ItemIndex=9,'End selects last wheel item');
    Key($4000004A);
    Key($4000004E);
    Check(W.ItemIndex=5,'PageDown advances by visible row count');
    W.ItemIndex:=4;
    Mouse(gekMouseDown,140);
    Mouse(gekMouseUp,140);
    Check(W.ItemIndex=5,'Clicking neighboring row centers it');
    W.ItemIndex:=4;
    Mouse(gekMouseDown,100);
    Mouse(gekMouseMove,40);
    Check(W.Moving AND (W.ItemIndex=6),'Dragging wheel updates current item continuously');
    Mouse(gekMouseUp,20);
    Check((W.ItemIndex=6) AND NOT W.Moving,'Wheel settles using final release coordinate');
    W.ItemIndex:=4;
    Mouse(gekMouseDown,100);
    Mouse(gekMouseMove,80);
    W.Items.Delete(0);
    Mouse(gekMouseUp,20);
    Check((W.ItemIndex=5) AND NOT W.Moving,'Collection mutation cancels pending wheel gesture');
    W.ItemIndex:=4;
    Mouse(gekMouseDown,100);
    Mouse(gekMouseMove,40);
    Key(27);
    Before:=W.ItemIndex;
    Mouse(gekMouseUp,20);
    Check((W.ItemIndex=Before) AND NOT W.Moving,'Escape settles live wheel selection without later release changes');
    W.ItemIndex:=4;
    W.Painted:=0;
    W.CenterIndex:=-1;
    W.Paint(Canvas);
    Check((W.Painted=5) AND (W.CenterIndex=4) AND (W.CenterRect.Top=80) AND (W.CenterRect.Height=40) AND (Canvas.ClipDepth=0),
      'Wheel paints centered selection and exactly visible rows with balanced clipping');
    Rejected:=False;
    try
      W.VisibleItemCount:=4;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (W.VisibleItemCount=5),'Even visible row count is rejected before mutation');
    W.VisibleItemCount:=3;
    W.WrapMode:=gwwAuto;
    Check(W.Wrap,'Automatic wrap can be restored');
    W.Items.Clear;
    Check((W.ItemIndex=-1) AND NOT W.Wrap,'Cleared wheel restores empty invariant');
    W.Items.Text:='A'+#10+'B';
    Check(NOT W.Wrap,'Short wheel lists do not wrap automatically');
    W.Wrap:=True;
    Key($40000052);
    Check(W.ItemIndex=1,'Explicit wrapping also supports short lists');
    W.Enabled:=False;
    Before:=P.Changes;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$40000051;
    W.HandleEvent(E);
    Check(P.Changes=Before,'Disabled wheel ignores direct keyboard input');
    W.Enabled:=True;
    W.Items.BeginUpdate;
    try
      for I:=0 to 9999 do W.Items.Add('Large item');
    finally
      W.Items.EndUpdate;
    end;
    W.ItemIndex:=9999;
    W.Painted:=0;
    W.Paint(Canvas);
    Check(W.Painted=3,'Large wheel paints only the configured visible rows');
  finally
    Canvas.Free;
    P.Free;
    C.Free;
  end;
end;

procedure TRangeEventProbe.Changed(Sender: TGuiControl);
begin
  Inc(FChanges);
  Lower:=TGuiRangeSlider(Sender).LowerValue;
  Upper:=TGuiRangeSlider(Sender).UpperValue;
end;

procedure TRangeEventProbe.Moved(Sender: TGuiControl; AThumb: TGuiRangeThumb);
begin
  Inc(FMoves);
  LastThumb:=AThumb;
end;

procedure TRangeLifetimeProbe.Changed(Sender: TGuiControl);
begin
  Inc(FChanges);
  if Mode=0 then Sender.Free else Sender.Enabled:=False;
end;

procedure TRangeLifetimeProbe.Moved(Sender: TGuiControl; AThumb: TGuiRangeThumb);
begin
  Inc(FMoves);
  if Mode=2 then Sender.Free;
end;

procedure TestRangeSliderLifetime;
var C: TGuiContext;
R: TGuiRangeSlider;
P: TRangeLifetimeProbe;
  E: TGuiEvent;
  Input,Action: Integer;
  procedure Mouse(Kind: TGuiEventKind; X: Single);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,20);
    C.ProcessEvent(E);
    end;
begin
  C:=TGuiContext.Create;
  P:=TRangeLifetimeProbe.Create;
  try
    C.Resize(300,100);
    for Input:=0 to 2 do for Action:=0 to 2 do
    begin
      C.CancelInput;
      C.Root.Clear;
      P.Mode:=Action;
      P.Changes:=0;
      P.Moves:=0;
      R:=TGuiRangeSlider.Create;
      C.Root.Add(R);
      R.Bounds:=GuiRect(0,0,120,40);
      C.SetFocus(R);
      if Input=2 then
      begin
        R.Live:=False;
        Mouse(gekMouseDown,20);
      end;
      if Action<>2 then R.OnChange:=P.Changed;
      R.OnMoved:=P.Moved;
      case Input of
        0:
        begin
          E:=Default(TGuiEvent);
          E.Kind:=gekKeyDown;
          E.KeyCode:=$4000004F;
          C.ProcessEvent(E);
        end;
        1: Mouse(gekMouseDown,20);
        2: Mouse(gekMouseUp,50);
      end;
      if Action=1 then Check(NOT R.Enabled AND (P.Changes=1) AND (P.Moves=0),
        'Range slider disabling OnChange suppresses OnMoved')
      else Check((C.Root.ChildCount=0) AND (C.FocusedControl=nil) AND
        (((Action=0) AND (P.Changes=1) AND (P.Moves=0)) OR
         ((Action=2) AND (P.Changes=0) AND (P.Moves=1))),
        'Range slider callback can free sender during keyboard, live drag and deferred release');
    end;
  finally
    P.Free;
    C.Free;
  end;
end;

procedure TestRangeSlider;
var C: TGuiContext;
R: TGuiRangeSlider;
P: TRangeEventProbe;
BeforeButton,AfterButton: TGuiButton;
  E: TGuiEvent;
  Before: Integer;
  Canvas: TTestCanvas;
  procedure Mouse(Kind: TGuiEventKind; X,Y: TGuiFloat);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,Y);
    C.ProcessEvent(E);
  end;
  procedure Key(Code: Integer; Shift: Boolean=False);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    if Shift then E.Modifiers:=[gemShift];
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  P:=TRangeEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(300,300);
    BeforeButton:=TGuiButton.Create;
    BeforeButton.Bounds:=GuiRect(0,250,100,30);
    C.Root.Add(BeforeButton);
    R:=TGuiRangeSlider.Create;
    R.Bounds:=GuiRect(0,0,220,40);
    C.Root.Add(R);
    AfterButton:=TGuiButton.Create;
    AfterButton.Bounds:=GuiRect(150,250,100,30);
    C.Root.Add(AfterButton);
    R.OnChange:=P.Changed;
    R.OnMoved:=P.Moved;
    Check((R.LowerValue=25) AND (R.UpperValue=75) AND R.Live AND
      (R.Position(grtLower)=0.25),
      'Range slider defaults to ordered quarter/three-quarter endpoints');
    R.SetValues(10,90);
    Check((P.Changes=1) AND (P.Lower=10) AND (P.Upper=90) AND (P.Moves=0),'Atomic endpoint update notifies once with both new values');
    R.LowerValue:=95;
    Check((R.LowerValue=90) AND (R.UpperValue=90),'Lower endpoint cannot cross upper');
    R.UpperValue:=20;
    Check((R.LowerValue=90) AND (R.UpperValue=90),'Upper assignment cannot move lower endpoint');
    R.SetValues(80,20);
    Check((R.LowerValue=20) AND (R.UpperValue=20),'Atomic reversed endpoints clamp lower to requested upper');
    R.MinValue:=30;
    Check((R.LowerValue=30) AND (R.UpperValue=30),'Minimum clamps both endpoints');
    R.MaxValue:=10;
    Check((R.MinValue=10) AND (R.LowerValue=10) AND (R.Position(grtUpper)=0),'Collapsed range stays valid');
    R.MinValue:=0;
    R.MaxValue:=100;
    R.StepSize:=10;
    Check((R.ValueAt(0.26)=30) AND (R.ValueAt(-1)=0) AND (R.ValueAt(2)=100),'ValueAt clamps position and applies explicit step');
    R.StepSize:=0;
    R.SetValues(25,75);
    Before:=P.Changes;
    Mouse(gekMouseDown,66,20);
    Check(P.Changes=Before,'Grabbing thumb off-center does not jump value');
    Mouse(gekMouseMove,86,20);
    Mouse(gekMouseUp,86,20);
    Check((R.LowerValue=35) AND (R.UpperValue=75) AND (P.LastThumb=grtLower),'Drag preserves grab offset and moves only lower endpoint');
    R.SetValues(25,75);
    R.Live:=False;
    Before:=P.Changes;
    Mouse(gekMouseDown,60,20);
    Mouse(gekMouseMove,110,20);
    Check((R.LowerValue=25) AND (R.PreviewValue[grtLower]=50) AND (P.Changes=Before),'Deferred range drag updates preview but not committed values');
    Mouse(gekMouseUp,130,20);
    Check(Abs(R.LowerValue-60)<0.001,'Deferred release commits final pointer position');
    R.SetValues(25,75);
    Mouse(gekMouseDown,60,20);
    Mouse(gekMouseMove,100,20);
    Key(27);
    Mouse(gekMouseUp,100,20);
    Check((R.LowerValue=25) AND (R.PreviewValue[grtLower]=25),'Escape discards deferred range preview');
    R.StepSize:=10;
    R.SnapMode:=gsmSnapOnRelease;
    Mouse(gekMouseDown,60,20);
    Mouse(gekMouseMove,117,20);
    Check(Abs(R.PreviewValue[grtLower]-53.5)<0.001,'Release-snap allows continuous range preview');
    Mouse(gekMouseUp,117,20);
    Check(R.LowerValue=50,'Release-snap rounds committed endpoint');
    R.Live:=True;
    R.SnapMode:=gsmSnapAlways;
    R.SetValues(20,80);
    Mouse(gekMouseDown,50,20);
    Mouse(gekMouseMove,64,20);
    Check(R.LowerValue=30,'Always-snap applies during live range dragging');
    Mouse(gekMouseUp,64,20);
    R.SetValues(25,75);
    Key($4000004F);
    Check(R.LowerValue=35,'Keyboard steps retain off-grid offset independently of pointer snap mode');
    R.SnapMode:=gsmNoSnap;
    R.StepSize:=0;
    R.SetValues(25,75);
    Mouse(gekMouseDown,160,20);
    Mouse(gekMouseUp,20,20);
    Check((R.LowerValue=25) AND (R.UpperValue=25),'Upper drag stops at lower endpoint');
    Mouse(gekMouseDown,64,20);
    Mouse(gekMouseUp,104,20);
    Check(R.UpperValue>R.LowerValue,'Coincident thumbs can be separated by choosing upper side');
    R.SetValues(25,75);
    R.ActiveThumb:=grtLower;
    C.SetFocus(R);
    Key(9);
    Check((C.FocusedControl=R) AND (R.ActiveThumb=grtUpper),'Tab first advances to upper thumb');
    Key(9);
    Check(C.FocusedControl=AfterButton,'Tab after upper thumb leaves range slider');
    Key(9,True);
    Check((C.FocusedControl=R) AND (R.ActiveThumb=grtUpper),'Reverse Tab enters upper thumb');
    Key(9,True);
    Check(R.ActiveThumb=grtLower,'Reverse Tab visits lower thumb');
    Key(9,True);
    Check(C.FocusedControl=BeforeButton,'Reverse Tab after lower thumb leaves slider');
    C.SetFocus(R);
    R.StepSize:=5;
    Key($4000004F);
    Check(R.LowerValue=30,'Arrow adjusts active endpoint by configured step');
    Key(32);
    Key($40000050);
    Check((R.ActiveThumb=grtUpper) AND (R.UpperValue=70),'Space selects other thumb for keyboard adjustment');
    Key($4000004A);
    Check(R.UpperValue=R.LowerValue,'Home respects other endpoint');
    R.Orientation:=goVertical;
    R.Bounds:=GuiRect(0,0,40,220);
    R.StepSize:=0;
    R.SetValues(25,75);
    Mouse(gekMouseDown,20,60);
    Mouse(gekMouseUp,20,20);
    Check((Abs(R.UpperValue-95)<0.001) AND (R.LowerValue=25),'Vertical range increases upward');
    R.Paint(Canvas);
    Check(Canvas.ClipDepth=0,'Range painting balances canvas clipping');
    R.Enabled:=False;
    Before:=P.Changes;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$4000004D;
    R.HandleEvent(E);
    Check(P.Changes=Before,'Disabled range slider ignores direct input');
    R.Enabled:=True;
    R.MinValue:=-3e38;
    R.MaxValue:=3e38;
    R.SetValues(0,3e38);
    R.ActiveThumb:=grtLower;
    R.StepSize:=0;
    Key($4000004F);
    Check(Abs(R.LowerValue/3e37-1)<0.0001,'Extreme range slider retains default one-twentieth step');
    R.StepSize:=3e38;
    Key($4000004B);
    Check(R.LowerValue=R.UpperValue,'Extreme range slider PageUp clamps before narrowing');
    Key($4000004E);
    Check(R.LowerValue=R.MinValue,'Extreme range slider PageDown clamps before narrowing');
  finally
    Canvas.Free;
    P.Free;
    C.Free;
  end;
end;

function TDelayProbe.AnimationTime: UInt64;
begin
  Result:=Ticks;
end;

procedure TDelayLifetimeProbe.Activated(Sender: TGuiControl);
begin
  Inc(FCalls);
  Sender.Free;
end;

procedure TDelayProbe.ClickNow;
begin
  DoClick;
end;

procedure TestDelayButton;
var C: TGuiContext;
B: TDelayProbe;
P: TControlEventProbe;
Canvas: TTestCanvas;
  E: TGuiEvent;
  Before: Integer;
  Lifetime: TDelayLifetimeProbe;
  procedure Mouse(Kind: TGuiEventKind; X: TGuiFloat);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,20);
    C.ProcessEvent(E);
  end;
  procedure Key(Kind: TGuiEventKind; Code: Integer);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.KeyCode:=Code;
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  P:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(300,200);
    B:=TDelayProbe.Create;
    C.Root.Add(B);
    B.Bounds:=GuiRect(0,0,180,40);
    B.OnActivated:=P.Changed;
    Check((B.Delay=3000) AND (B.Progress=0) AND NOT B.Checked,'Delay button starts idle with 3000ms delay');
    B.ClickNow;
    Check(P.Changes=0,'Generic click cannot bypass delay');
    B.Ticks:=100;
    Mouse(gekMouseDown,60);
    B.Ticks:=1600;
    Check(B.Holding AND (Abs(B.Progress-0.5)<0.001) AND (P.Changes=0),'Delay progress tracks elapsed hold without accessor side effects');
    Mouse(gekMouseUp,60);
    Check((B.Progress=0) AND NOT B.Checked AND (P.Changes=0),'Early release cancels without activation or click');
    B.Ticks:=2000;
    Mouse(gekMouseDown,60);
    B.Ticks:=5000;
    C.Paint(Canvas);
    Check(B.Checked AND NOT B.Holding AND (B.Progress=1) AND (P.Changes=1),'Context frame activates completed hold without further input');
    C.Paint(Canvas);
    Mouse(gekMouseUp,60);
    B.ClickNow;
    Check(P.Changes=1,'Completed hold never activates twice during repaint or release');
    Mouse(gekMouseDown,60);
    Mouse(gekMouseUp,60);
    Check(NOT B.Checked AND (B.Progress=0) AND (P.Changes=1),'Next press resets latched checked state');
    Mouse(gekMouseDown,60);
    B.Ticks:=8000;
    Mouse(gekMouseUp,60);
    Check(B.Checked AND (P.Changes=2),'Release at threshold activates even without intervening repaint');
    B.Reset;
    Mouse(gekMouseDown,60);
    B.Ticks:=11000;
    Mouse(gekMouseUp,250);
    Check(NOT B.Checked AND (P.Changes=2),'Release outside cannot confirm a stale hold');
    Mouse(gekMouseDown,60);
    Mouse(gekMouseMove,250);
    Mouse(gekMouseMove,60);
    B.Ticks:=14000;
    Mouse(gekMouseUp,60);
    Check(NOT B.Checked,'Leaving button cancels hold without restarting on reentry');
    Key(gekKeyDown,32);
    B.Ticks:=15000;
    Key(gekKeyDown,32);
    B.Ticks:=17000;
    C.Paint(Canvas);
    Check(B.Checked AND (P.Changes=3),'Repeated Space down does not restart timer');
    Key(gekKeyUp,32);
    B.Reset;
    Key(gekKeyDown,13);
    Key(gekKeyUp,32);
    Check(B.Holding,'Unrelated key release does not end Enter hold');
    Key(gekKeyDown,27);
    B.Ticks:=20000;
    C.Paint(Canvas);
    Key(gekKeyUp,13);
    Check(NOT B.Checked AND NOT B.Holding,'Escape cancels keyboard confirmation');
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=13;
    E.KeyRepeat:=True;
    C.ProcessEvent(E);
    B.Ticks:=23000;
    C.Paint(Canvas);
    Check(NOT B.Holding AND NOT B.Checked,'OS key repeat cannot restart cancelled confirmation');
    Key(gekKeyDown,32);
    C.ClearFocus;
    B.Ticks:=23000;
    B.UpdateHold;
    Check(NOT B.Checked AND NOT B.Holding,'Focus loss cancels keyboard confirmation');
    C.SetFocus(B);
    Key(gekGamepadButtonDown,0);
    B.Ticks:=26000;
    C.Paint(Canvas);
    Key(gekGamepadButtonUp,0);
    Check(B.Checked AND (P.Changes=4),'Gamepad activation is held and released through delay control');
    B.Reset;
    Key(gekKeyDown,32);
    C.Root.Enabled:=False;
    B.Ticks:=29000;
    C.Paint(Canvas);
    Check(NOT B.Checked AND NOT B.Holding,'Disabled ancestor cancels pending activation before paint');
    C.Root.Enabled:=True;
    Key(gekKeyUp,32);
    B.Delay:=0;
    Before:=P.Changes;
    Mouse(gekMouseDown,60);
    Mouse(gekMouseUp,60);
    Check(B.Checked AND (P.Changes=Before+1),'Zero delay activates immediately once');
    B.Reset;
    B.Delay:=3000;
    B.Ticks:=100;
    Mouse(gekMouseDown,60);
    B.Delay:=1000;
    B.Ticks:=High(UInt64);
    B.UpdateHold;
    Check(NOT B.Checked,'Changing delay cancels old hold');
    Mouse(gekMouseUp,60);
    B.Ticks:=100;
    Mouse(gekMouseDown,60);
    B.Ticks:=99;
    B.UpdateHold;
    Check(NOT B.Holding,'Clock rollback safely cancels hold');
    Mouse(gekMouseUp,60);
    B.Ticks:=100;
    Mouse(gekMouseDown,60);
    B.Ticks:=High(UInt64);
    B.UpdateHold;
    Check(B.Checked AND (B.Progress=1),'Large elapsed time clamps progress safely');
    Mouse(gekMouseUp,60);
    B.Reset;
    Lifetime:=TDelayLifetimeProbe.Create;
    try
      B.OnActivated:=Lifetime.Activated;
      B.Ticks:=100;
      Mouse(gekMouseDown,60);
      B.Ticks:=1100;
      C.Paint(Canvas);
      Check((Lifetime.Calls=1) AND (C.Root.ChildCount=0) AND (C.FocusedControl=nil),
        'Timed activation callback can free its control before frame traversal');
      Mouse(gekMouseUp,60);
      C.Paint(Canvas);
      Check(Lifetime.Calls=1,'Freed delay button leaves no pending frame or release callback');
      B:=TDelayProbe.Create;
      C.Root.Add(B);
      B.Bounds:=GuiRect(0,0,180,40);
      B.Delay:=1000;
      B.OnActivated:=Lifetime.Activated;
      B.Ticks:=100;
      Mouse(gekMouseDown,60);
      B.Ticks:=1100;
      Mouse(gekMouseUp,60);
      Check((Lifetime.Calls=2) AND (C.Root.ChildCount=0) AND (C.FocusedControl=nil),
        'Delay release-time activation can free sender without a stale click');
      B:=TDelayProbe.Create;
      C.Root.Add(B);
      B.Bounds:=GuiRect(0,0,180,40);
      B.Delay:=0;
      B.OnActivated:=Lifetime.Activated;
      Mouse(gekMouseDown,60);
      Mouse(gekMouseUp,60);
      C.Paint(Canvas);
      Check((Lifetime.Calls=3) AND (C.Root.ChildCount=0) AND (C.FocusedControl=nil),
        'Immediate delay activation can free sender during mouse-down');
    finally
      Lifetime.Free;
    end;
  finally
    Canvas.Free;
    P.Free;
    C.Free;
  end;
end;

procedure TCheckListEventProbe.Checked(Sender: TGuiControl; AIndex: Integer);
begin
  Inc(FChanges);
  LastIndex:=AIndex;
  ObservedState:=TGuiCheckListBox(Sender).State[AIndex];
  if FreeOnCheck then Sender.Free;
end;

procedure TCheckListEventProbe.RemoveSelected(Sender: TGuiControl);
begin
  Inc(FChanges);
  Sender.Free;
end;

procedure TestDelegateLifetime;
var C: TGuiContext;
L: TGuiCheckListBox;
P: TCheckListEventProbe;
  E: TGuiEvent;
  Kind,Mode: Integer;
  procedure Mouse(AKind: TGuiEventKind; X: TGuiFloat);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=AKind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,20);
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  P:=TCheckListEventProbe.Create;
  try
    C.Resize(300,200);
    P.FreeOnCheck:=True;
    for Kind:=0 to 1 do for Mode:=0 to 3 do
    begin
      C.CancelInput;
      C.Root.Clear;
      P.Changes:=0;
      if Kind=0 then L:=TGuiCheckListBox.Create else L:=TGuiSwitchListBox.Create;
      C.Root.Add(L);
      L.Bounds:=GuiRect(0,0,240,110);
      L.Padding:=GuiBox(4);
      L.ItemHeight:=30;
      L.Items.Add('First');
      L.Items.Add('Second');
      L.SelectedIndex:=0;
      L.OnCheck:=P.Checked;
      C.SetFocus(L);
      case Mode of
        0:
        begin
          E:=Default(TGuiEvent);
          E.Kind:=gekKeyDown;
          E.KeyCode:=32;
          C.ProcessEvent(E);
        end;
        1:
        begin
          Mouse(gekMouseDown,120);
          Mouse(gekMouseUp,120);
        end;
        2:
        begin
          L.SelectedIndex:=-1;
          L.OnSelect:=P.RemoveSelected;
          Mouse(gekMouseDown,120);
          Mouse(gekMouseUp,120);
        end;
        3:
        begin
          Mouse(gekMouseDown,22);
          Mouse(gekMouseMove,42);
          Mouse(gekMouseUp,42);
        end;
      end;
      Check((P.Changes=1) AND (C.Root.ChildCount=0) AND (C.FocusedControl=nil),
        'Delegate callbacks can free sender during key, click, selection or drag dispatch');
    end;
  finally
    P.Free;
    C.Free;
  end;
end;

procedure TCheckListEventProbe.DeleteFirst(Sender: TGuiControl; const Event: TGuiEvent);
begin
  TGuiCheckListBox(Sender).Items.Delete(0);
end;

procedure TestSwitchListBox;
var C: TGuiContext;
L: TGuiSwitchListBox;
P: TCheckListEventProbe;
E: TGuiEvent;
I,Before: Integer;
  procedure Mouse(Kind: TGuiEventKind; X,Y: TGuiFloat);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,Y);
    C.ProcessEvent(E);
  end;
  procedure Key(Code: Cardinal);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  P:=TCheckListEventProbe.Create;
  try
    C.Resize(300,200);
    L:=TGuiSwitchListBox.Create;
    C.Root.Add(L);
    L.Bounds:=GuiRect(0,0,240,110);
    L.Padding:=GuiBox(4);
    L.ItemHeight:=30;
    L.OnCheck:=P.Checked;
    for I:=0 to 19 do L.AddItem('Switch '+IntToStr(I));
    Mouse(gekMouseDown,120,20);
    Mouse(gekMouseUp,120,20);
    Check(L.Checked[0] AND (P.Changes=1),'Switch row caption click toggles once');
    L.AllowGrayed:=True;
    Key(32);
    Check(L.State[0]=gcbUnchecked,'Switch interaction stays two-state despite inherited mixed-cycle flag');
    Key($4000004F);
    Key($4000004F);
    Check(L.Checked[0] AND (P.Changes=3),'Right sets switch on without repeated change event');
    Key($40000050);
    Check(NOT L.Checked[0],'Left sets switch off');
    Before:=P.Changes;
    Mouse(gekMouseDown,22,20);
    Mouse(gekMouseMove,30,20);
    Check((Abs(L.ThumbPosition[0]-0.4)<0.001) AND NOT L.Checked[0] AND (P.Changes=Before),'Switch drag previews fractional thumb without early commit');
    Mouse(gekMouseUp,42,20);
    Check(L.Checked[0] AND (P.Changes=Before+1),'Switch drag commits final release position exactly once');
    Mouse(gekMouseDown,42,20);
    Mouse(gekMouseMove,22,20);
    Key(27);
    Mouse(gekMouseUp,22,20);
    Check(L.Checked[0] AND (L.ThumbPosition[0]=1),'Escape cancels switch drag and restores thumb');
    Mouse(gekMouseDown,42,20);
    Mouse(gekMouseMove,22,20);
    L.Items.Insert(0,'New');
    Mouse(gekMouseUp,22,20);
    Check(NOT L.Checked[0] AND L.Checked[1],'Item mutation cancels switch drag without changing replacement');
    L.Items.Delete(0);
    L.ItemEnabled[0]:=False;
    Before:=P.Changes;
    Mouse(gekMouseDown,42,20);
    Mouse(gekMouseMove,22,20);
    Mouse(gekMouseUp,22,20);
    Key(32);
    Check(L.Checked[0] AND (P.Changes=Before),'Disabled switch row ignores drag and keyboard toggle');
    L.ItemEnabled[0]:=True;
    L.OnMouseUp:=P.DeleteFirst;
    Mouse(gekMouseDown,42,20);
    Mouse(gekMouseMove,22,20);
    Mouse(gekMouseUp,22,20);
    L.OnMouseUp:=nil;
    Check(NOT L.Checked[0],'Switch release callback mutation does not commit to replacement row');
    L.State[0]:=gcbGrayed;
    Check(L.ThumbPosition[0]=0.5,'Explicit mixed state has centered switch thumb');
    Key(32);
    Check(L.Checked[0],'Explicit mixed switch state resolves to on');
    Key($40000051);
    Check((L.SelectedIndex=1) AND NOT L.Checked[1],'Switch list navigation remains independent of check state');
    Mouse(gekMouseDown,120,50);
    Mouse(gekMouseMove,160,50);
    Mouse(gekMouseUp,160,50);
    Check(L.Checked[1],'Caption gesture uses row click, not switch-thumb positioning');
    L.Checked[0]:=False;
    Mouse(gekMouseDown,22,20);
    Mouse(gekMouseMove,0,20);
    L.Checked[0]:=True;
    Before:=P.Changes;
    Check(L.ThumbPosition[0]=1,'Programmatic switch-row change clears drag preview');
    Mouse(gekMouseUp,0,20);
    Check(L.Checked[0] AND (P.Changes=Before),'Stale switch drag cannot overwrite programmatic row state');
  finally
    P.Free;
    C.Free;
  end;
end;

procedure TestCheckListBox;
var C: TGuiContext;
L: TGuiCheckListBox;
P: TCheckListEventProbe;
  E: TGuiEvent;
  I,Before: Integer;
  Canvas: TTestCanvas;
  procedure Mouse(Kind: TGuiEventKind; X,Y: TGuiFloat);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,Y);
    C.ProcessEvent(E);
  end;
  procedure Key(Code: Cardinal);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  P:=TCheckListEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(300,200);
    L:=TGuiCheckListBox.Create;
    C.Root.Add(L);
    L.Bounds:=GuiRect(0,0,240,110);
    L.Padding:=GuiBox(4);
    L.ItemHeight:=30;
    L.OnCheck:=P.Checked;
    Check((L.SelectedIndex=-1) AND NOT L.AllowGrayed,'Checklist starts empty and two-state');
    for I:=0 to 19 do L.AddItem('Option '+IntToStr(I));
    Check((P.Changes=0) AND NOT L.Checked[0] AND L.ItemEnabled[0],'New checklist rows default enabled and unchecked');
    Mouse(gekMouseDown,120,20);
    Check(NOT L.Checked[0],'Checklist waits for release before checking');
    Mouse(gekMouseUp,120,20);
    Check(L.Checked[0] AND (P.Changes=1) AND (P.LastIndex=0) AND (P.ObservedState=gcbChecked),'Caption click checks once and event observes new state');
    L.Checked[0]:=True;
    Check(P.Changes=1,'Unchanged assignment does not notify');
    Key($40000051);
    Check((L.SelectedIndex=1) AND NOT L.Checked[1],'Arrow navigation does not toggle checks');
    Key(32);
    Check(L.Checked[1] AND L.Checked[0],'Space independently checks selected row');
    Key(13);
    Check(NOT L.Checked[1],'Enter toggles selected row');
    L.AllowGrayed:=True;
    Key(32);
    Check(L.State[1]=gcbGrayed,'Three-state cycle enters mixed state');
    Key(32);
    Check(L.Checked[1],'Mixed state cycles to checked');
    Key(32);
    Check(L.State[1]=gcbUnchecked,'Checked state cycles to unchecked');
    L.ItemEnabled[1]:=False;
    Before:=P.Changes;
    Key(32);
    Check((P.Changes=Before) AND NOT L.Checked[1],'Disabled row ignores keyboard toggle');
    L.Checked[1]:=True;
    Check(L.Checked[1] AND NOT L.ItemEnabled[1],'Programmatic check preserves disabled flag');
    L.AllowGrayed:=False;
    L.Checked[0]:=False;
    Mouse(gekMouseDown,120,20);
    C.CancelInput;
    Mouse(gekMouseUp,120,20);
    Check(NOT L.Checked[0],'Cancelled checklist press does not toggle');
    Mouse(gekMouseDown,120,20);
    Mouse(gekMouseUp,120,80);
    Check(NOT L.Checked[0] AND NOT L.Checked[2],'Release over another row does not toggle either row');
    Mouse(gekMouseDown,120,20);
    Mouse(gekMouseUp,234,20);
    Check(NOT L.Checked[0],'Releasing in scrollbar lane does not check row');
    Before:=P.Changes;
    Mouse(gekMouseDown,234,20);
    Mouse(gekMouseUp,234,20);
    Check(P.Changes=Before,'Scrollbar gesture does not check rows');
    L.ScrollY:=0;
    Mouse(gekMouseDown,120,20);
    Key($40000051);
    Mouse(gekMouseUp,120,20);
    Check(NOT L.Checked[0],'Keyboard navigation cancels pending pointer check');
    Mouse(gekMouseDown,120,20);
    L.Items.Insert(0,'Inserted');
    Mouse(gekMouseUp,120,20);
    Check(NOT L.Checked[0] AND NOT L.Checked[1],'Mutation cancels pending row click');
    L.OnMouseUp:=P.DeleteFirst;
    Mouse(gekMouseDown,120,20);
    Mouse(gekMouseUp,120,20);
    L.OnMouseUp:=nil;
    Check(NOT L.Checked[0],'Release callback mutation cannot toggle replacement row');
    Mouse(gekMouseDown,120,20);
    L.Checked[0]:=True;
    Before:=P.Changes;
    Mouse(gekMouseUp,120,20);
    Check(L.Checked[0] AND (P.Changes=Before),'Stale checklist click cannot overwrite programmatic row state');
    L.Checked[0]:=False;
    L.Enabled:=False;
    Before:=P.Changes;
    L.ToggleCheck(0);
    Check(P.Changes=Before,'Disabled checklist ignores explicit user-style toggle');
    L.Enabled:=True;
    L.Items.Exchange(0,1);
    Check(L.Checked[0] AND NOT L.ItemEnabled[0],'Reordering retains checks and disabled flags');
    L.SelectedIndex:=19;
    Canvas.TextDrawCount:=0;
    L.Paint(Canvas);
    Check((L.ScrollY>0) AND (Canvas.TextDrawCount<=5) AND (Canvas.ClipDepth=0),'Checklist reveals selection and only paints visible rows');
    L.Items.Clear;
    C.SetFocus(L);
    Key(32);
    Key(13);
    Check((L.SelectedIndex=-1) AND (L.ScrollY=0),'Empty checklist safely accepts activation keys');
  finally
    Canvas.Free;
    P.Free;
    C.Free;
  end;
end;

function TStateListProbe.CreateItems: TStringList;
begin
  Result:=TGuiStateStrings.Create;
end;

function DescendingStateStrings(List: TStringList; L,R: Integer): Integer;
begin
  Result:=CompareStr(List[R],List[L]);
end;

procedure TestStateStrings;
var S,CopyList: TGuiStateStrings;
Obj: TObject;
I: Integer;
Rejected: Boolean;
List: TStateListProbe;
begin
  S:=TGuiStateStrings.Create;
  CopyList:=TGuiStateStrings.Create;
  Obj:=TObject.Create;
  try
    S.AddObject('b',Obj);
    S.ItemState[0]:=7;
    S.Insert(0,'a');
    S.ItemState[0]:=3;
    Check((S.ItemState[1]=7) AND (S.Objects[1]=Obj),'State-list insertion preserves existing state and application object');
    S.Add('a');
    S.ItemState[2]:=5;
    S.Sort;
    Check((S[0]='a') AND (S.ItemState[0]=3) AND (S.ItemState[1]=5) AND
      (S[2]='b') AND (S.ItemState[2]=7) AND (S.Objects[2]=Obj),
      'Stable sorting preserves distinct duplicate states and Objects');
    S.Move(2,0);
    Check((S[0]='b') AND (S.ItemState[0]=7),'Moving list item moves its state');
    S.Exchange(0,2);
    Check((S[2]='b') AND (S.ItemState[2]=7),'Exchanging list items exchanges states');
    S[2]:='c';
    Check(S.ItemState[2]=7,'Renaming list item retains state');
    S.Delete(1);
    Check((S.Count=2) AND (S[1]='c') AND (S.ItemState[1]=7),'Deleting list item shifts remaining states');
    CopyList.Assign(S);
    Check((CopyList.ItemState[1]=7) AND (CopyList.Objects[1]=Obj),'Assigning state list copies states without taking over Objects');
    S.CustomSort(DescendingStateStrings);
    Check((S[0]='c') AND (S.ItemState[0]=7),'Custom comparator sorting moves state with row');
    S.Sorted:=True;
    I:=S.Add('b');
    Check((S[I]='b') AND (S.ItemState[I]=0),'Automatic sorted insertion initializes new state');
    Check(S.ItemState[S.IndexOf('c')]=7,'Automatic sort preserves old check-state data');
    Rejected:=False;
    try
      S.Delete(999);
    except
      on EStringListError do Rejected:=True;
    end;
    Check(Rejected AND (S.Count=3),'Invalid deletion leaves state list intact');
    S.Clear;
    Check(S.Count=0,'State list clears all rows');
    S.Add('new');
    Check(S.ItemState[0]=0,'Reusing cleared state list initializes state');
    S.Sorted:=False;
    S.Clear;
    S.BeginUpdate;
    try
      for I:=999 downto 0 do
      begin
        S.Add(Format('%.4d',[I]));
        S.ItemState[S.Count-1]:=I;
      end;
    finally
      S.EndUpdate;
    end;
    S.Sort;
    for I:=0 to S.Count-1 do if S.ItemState[I]<>I then raise Exception.Create('Large state sort lost row identity');
    Check(S.Count=1000,'Large stable state sort preserves every row state');
  finally
    CopyList.Free;
    S.Free;
    Obj.Free;
  end;
  List:=TStateListProbe.Create;
  try
    List.AddItem('z');
    TGuiStateStrings(List.Items).ItemState[0]:=1;
    List.AddItem('a');
    List.SelectedIndex:=0;
    List.Items.Sort;
    Check((List.SelectedIndex=0) AND (TGuiStateStrings(List.Items).ItemState[1]=1),
      'List collection hook keeps row state independent from positional selection');
  finally
    List.Free;
  end;
end;

procedure TKnobWrapProbe.Wrapped(Sender: TGuiControl; ADirection: TGuiWrapDirection);
begin
  if ADirection=gwdClockwise then Inc(FClockwise) else Inc(FCounterClockwise);
  ObservedValue:=TGuiKnob(Sender).PreviewValue;
  if FreeOnWrap then Sender.Free;
end;

procedure TestKnobWrapLifetime;
var C: TGuiContext;
K: TGuiKnob;
P: TKnobWrapProbe;
E: TGuiEvent;
Input: Integer;
begin
  C:=TGuiContext.Create;
  P:=TKnobWrapProbe.Create;
  try
    C.Resize(300,200);
    P.FreeOnWrap:=True;
    for Input:=0 to 2 do
    begin
      K:=TGuiKnob.Create;
      C.Root.Add(K);
      K.Wrap:=True;
      K.Value:=100;
      K.InputMode:=gkiHorizontal;
      K.DragDistance:=100;
      K.OnWrapped:=P.Wrapped;
      C.SetFocus(K);
      E:=Default(TGuiEvent);
      if Input=0 then
      begin
        E.Kind:=gekKeyDown;
        E.KeyCode:=$4000004F;
      end
      else if Input=1 then
      begin
        E.Kind:=gekMouseWheel;
        E.Delta:=GuiPoint(0,1);
      end
      else
      begin
        E.Kind:=gekMouseDown;
        E.Button:=gmbLeft;
        E.Position:=GuiPoint(50,50);
        C.ProcessEvent(E);
        E:=Default(TGuiEvent);
        E.Kind:=gekMouseUp;
        E.Button:=gmbLeft;
        E.Position:=GuiPoint(80,50);
      end;
      C.ProcessEvent(E);
      Check((C.Root.ChildCount=0) AND (C.FocusedControl=nil) AND (P.Clockwise=Input+1),
        'Knob OnWrapped can free sender during key, wheel and pointer release');
    end;
  finally
    P.Free;
    C.Free;
  end;
end;

procedure TestKnobBoundaries;
var C: TGuiContext;
K: TGuiKnob;
P: TKnobWrapProbe;
E: TGuiEvent;
Span,I: Integer;
  procedure Angle(Kind: TGuiEventKind; Degrees: Single);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(50+40*Cos(Degrees*Pi/180),50+40*Sin(Degrees*Pi/180));
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  P:=TKnobWrapProbe.Create;
  try
    C.Resize(400,200);
    K:=TGuiKnob.Create;
    C.Root.Add(K);
    K.OnWrapped:=P.Wrapped;
    for Span:=1 to 4 do
    begin
      K.SetAngles(0,Span*90);
      K.Wrap:=False;
      K.Value:=0;
      Angle(gekMouseDown,0);
      for I:=1 to 12 do
      begin
        Angle(gekMouseMove,I*30);
        if I*30>=Span*90 then Check(Abs(K.Value-100)<0.01,'Non-wrapping knob stays at endpoint through gap/full revolution');
      end;
      Angle(gekMouseUp,360);
      Check((P.Clockwise=0) AND (P.CounterClockwise=0),'Non-wrapping drag emits no wrapped events');
      K.Wrap:=True;
      Angle(gekMouseDown,0);
      for I:=1 to 12 do Angle(gekMouseMove,I*30);
      Angle(gekMouseUp,360);
      Check((P.Clockwise=1) AND (P.CounterClockwise=0),'Circular arc emits one clockwise wrap, not another on release');
      Angle(gekMouseDown,0);
      for I:=1 to 12 do Angle(gekMouseMove,-I*30);
      Angle(gekMouseUp,-360);
      Check(P.CounterClockwise=1,'Circular arc reports counterclockwise wrapping');
      P.Clockwise:=0;
      P.CounterClockwise:=0;
    end;
    K.InputMode:=gkiHorizontal;
    K.DragDistance:=100;
    K.Value:=90;
    K.Live:=False;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(50,50);
    C.ProcessEvent(E);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseMove;
    E.Position:=GuiPoint(80,50);
    C.ProcessEvent(E);
    Check((P.Clockwise=1) AND (K.Value=90) AND (Abs(P.ObservedValue-20)<0.001),
      'Deferred relative wrap event observes updated preview without committing value');
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseUp;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(80,50);
    C.ProcessEvent(E);
    Check((P.Clockwise=1) AND (Abs(K.Value-20)<0.001),'Relative release commits without duplicate wrapped notification');
    K.Value:=100;
    C.SetFocus(K);
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$4000004F;
    C.ProcessEvent(E);
    Check((P.Clockwise=2) AND (P.ObservedValue=0),'Keyboard wrap event observes updated value');
    K.Value:=50;
    Check(P.Clockwise=2,'Programmatic knob writes emit no wrapped event');
    K.Value:=0;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseWheel;
    E.Delta:=GuiPoint(0,-1);
    K.HandleEvent(E);
    Check((P.CounterClockwise=1) AND (P.ObservedValue=100),'Wheel wrap reports counterclockwise direction after updating value');
    K.MaxValue:=K.MinValue;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$4000004F;
    C.ProcessEvent(E);
    Check(P.Clockwise=2,'Degenerate range cannot emit a wrap');
    K.MinValue:=-3e38;
    K.MaxValue:=3e38;
    K.Value:=0;
    K.Live:=True;
    K.InputMode:=gkiCircular;
    K.Wrap:=False;
    K.SetAngles(0,180);
    Angle(gekMouseDown,90);
    Angle(gekMouseUp,90);
    Check(Abs(K.Value/3e38)<0.0001,'Extreme circular knob range maps midpoint to zero');
    K.Wrap:=True;
    K.Value:=0;
    K.StepSize:=0;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$4000004F;
    C.ProcessEvent(E);
    Check(Abs(K.Value/3e37-1)<0.0001,'Extreme wrapping knob retains default keyboard step');
    K.Value:=2e38;
    K.StepSize:=3e38;
    E.Handled:=False;
    C.ProcessEvent(E);
    Check(K.Value=K.MinValue,'Extreme wrapping knob crosses maximum without overflow');
  finally
    P.Free;
    C.Free;
  end;
end;

procedure TSpeedProbe.ClickNow;
begin
  DoClick;
end;
function TSpeedProbe.CheckedVisual: Boolean;
begin
  Result:=gcvsChecked IN VisualStates;
end;

procedure TestKnobInputModes;
var C: TGuiContext;
K: TGuiKnob;
E: TGuiEvent;
Rejected: Boolean;
  procedure Mouse(Kind: TGuiEventKind; X,Y: Single);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,Y);
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  try
    C.Resize(400,300);
    K:=TGuiKnob.Create;
    C.Root.Add(K);
    K.DragDistance:=100;
    K.InputMode:=gkiHorizontal;
    K.Value:=40;
    Mouse(gekMouseDown,30,50);
    Check(K.Value=40,'Relative knob press does not jump to pointer value');
    Mouse(gekMouseMove,60,90);
    Check(K.Value=70,'Horizontal knob drag uses relative X only');
    Mouse(gekMouseUp,70,90);
    Check(K.Value=80,'Relative knob release includes final pointer delta');
    K.InputMode:=gkiVertical;
    K.Live:=False;
    K.Value:=40;
    Mouse(gekMouseDown,50,50);
    Mouse(gekMouseMove,80,20);
    Check((K.Value=40) AND (K.PreviewValue=70),'Vertical deferred knob increases upward without committing');
    Mouse(gekMouseUp,80,10);
    Check(K.Value=80,'Vertical knob release commits relative preview');
    K.Wrap:=True;
    K.Live:=True;
    K.Value:=90;
    Mouse(gekMouseDown,50,50);
    Mouse(gekMouseUp,50,20);
    Check(Abs(K.Value-20)<0.001,'Relative knob wraps excess motion across maximum');
    K.Value:=10;
    Mouse(gekMouseDown,50,50);
    Mouse(gekMouseUp,50,80);
    Check(Abs(K.Value-80)<0.001,'Relative knob wraps below minimum');
    K.Live:=False;
    Mouse(gekMouseDown,50,50);
    Mouse(gekMouseMove,50,20);
    K.InputMode:=gkiCircular;
    Mouse(gekMouseUp,50,20);
    Check(K.Value=80,'Input-mode change cancels deferred knob gesture');
    K.Wrap:=False;
    K.Live:=True;
    K.SetAngles(0,180);
    Mouse(gekMouseDown,90,50);
    Mouse(gekMouseUp,90,50);
    Check(K.Value=0,'Custom arc maps start angle to minimum');
    Mouse(gekMouseDown,50,90);
    Mouse(gekMouseUp,50,90);
    Check(K.Value=50,'Custom arc maps midpoint correctly');
    Mouse(gekMouseDown,10,50);
    Mouse(gekMouseUp,10,50);
    Check(K.Value=100,'Custom arc maps end angle to maximum');
    Rejected:=False;
    try
      K.SetAngles(10,400);
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (K.StartAngle=0) AND (K.EndAngle=180),'Invalid angle span is rejected atomically');
    Rejected:=False;
    try
      K.DragDistance:=0;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (K.DragDistance=100),'Invalid drag distance preserves previous value');
  finally
    C.Free;
  end;
end;

procedure TestCircularKnob;
var C: TGuiContext;
K: TGuiKnob;
P: TControlEventProbe;
Canvas: TTestCanvas;
E: TGuiEvent;
  procedure Mouse(Kind: TGuiEventKind; X,Y: Single);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,Y);
    C.ProcessEvent(E);
  end;
  procedure Key(Code: Cardinal);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  P:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(300,150);
    K:=TGuiKnob.Create;
    C.Root.Add(K);
    K.OnChange:=P.Changed;
    K.StepSize:=10;
    K.SnapMode:=gsmSnapAlways;
    Mouse(gekMouseDown,90,50);
    Mouse(gekMouseUp,90,50);
    Check(K.Value=80,'Circular knob maps clockwise pointer position and snaps');
    K.Live:=False;
    Mouse(gekMouseDown,20,20);
    Check((K.Value=80) AND (K.PreviewValue=30),'Knob inherits deferred preview');
    Mouse(gekMouseUp,80,80);
    Check(K.Value=100,'Knob release commits final circular position');
    Mouse(gekMouseDown,20,20);
    Key(27);
    Mouse(gekMouseUp,20,20);
    Check(K.Value=100,'Escape cancels deferred knob gesture');
    K.Live:=True;
    Mouse(gekMouseDown,80,80);
    Mouse(gekMouseMove,20,80);
    Mouse(gekMouseUp,20,80);
    Check(K.Value=100,'Non-wrapping knob stops when dragged across lower gap');
    K.Wrap:=True;
    Mouse(gekMouseDown,80,80);
    Mouse(gekMouseMove,20,80);
    Mouse(gekMouseUp,20,80);
    Check(K.Value=0,'Wrapping knob crosses from maximum to minimum');
    C.SetFocus(K);
    Key($40000050);
    Check(K.Value=100,'Wrapping knob keyboard crosses minimum');
    Key($4000004F);
    Check(K.Value=0,'Wrapping knob keyboard crosses maximum');
    Mouse(gekMouseDown,50,50);
    Mouse(gekMouseUp,50,50);
    Check(K.Value=0,'Knob center has no undefined-angle jump');
    K.Enabled:=False;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseWheel;
    E.Delta:=GuiPoint(0,1);
    K.HandleEvent(E);
    Check(K.Value=0,'Disabled knob ignores wheel');
    K.Enabled:=True;
    K.Paint(Canvas);
    Check((Canvas.FillCount>0) AND (Canvas.ClipDepth=0),'Knob renders bounded arc/body/pointer and balances clipping');
    K.Bounds:=GuiRect(0,0,0,0);
    K.Paint(Canvas);
    Check(Canvas.ClipDepth=0,'Empty knob is safe to paint');
  finally
    Canvas.Free;
    P.Free;
    C.Free;
  end;
end;

procedure TestRoundButton;
var C: TGuiContext;
B: TGuiRoundButton;
P: TControlEventProbe;
Canvas: TTestCanvas;
  E: TGuiEvent;
  Saved: TGuiFloat;
  Rejected: Boolean;
begin
  C:=TGuiContext.Create;
  P:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(200,100);
    B:=TGuiRoundButton.Create;
    C.Root.Add(B);
    B.OnClick:=P.Clicked;
    Check((B.Radius=-1) AND (B.EffectiveRadius=20),'Round button defaults to an automatic circle');
    B.Bounds:=GuiRect(0,0,120,40);
    Check(B.EffectiveRadius=20,'Wide round button becomes a pill');
    B.Radius:=6;
    GuiApplyTheme(B,GuiDarkTheme);
    Saved:=B.Style.CornerRadius;
    B.Paint(Canvas);
    Check((B.EffectiveRadius=6) AND (B.Style.CornerRadius=Saved),'Explicit radius survives theme and painting restores style');
    GuiApplyTheme(B,GuiReactorTheme);
    Check((B.Radius=6) AND (B.Padding.Left=4),'Theme changes retain round radius and compact padding');
    B.Radius:=1000;
    Check(B.EffectiveRadius=20,'Oversized round radius clamps to geometry');
    B.Radius:=0;
    Check(B.EffectiveRadius=0,'Zero radius explicitly supports square corners');
    B.Radius:=-1;
    B.Bounds:=GuiRect(0,0,60,60);
    Check(B.EffectiveRadius=30,'Automatic radius follows resizing');
    Rejected:=False;
    try
      B.Radius:=-0.5;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (B.Radius=-1),'Invalid negative radius is rejected without changing state');
    C.SetFocus(B);
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=32;
    C.ProcessEvent(E);
    Check(P.Clicks=1,'Round button retains keyboard activation');
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(30,30);
    C.ProcessEvent(E);
    C.CancelInput;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseUp;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(30,30);
    C.ProcessEvent(E);
    Check(P.Clicks=1,'Round button retains pointer cancellation');
    B.Enabled:=False;
    C.SetFocus(B);
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=13;
    C.ProcessEvent(E);
    Check(P.Clicks=1,'Disabled round button cannot be activated');
  finally
    Canvas.Free;
    P.Free;
    C.Free;
  end;
end;

procedure TestKnobLifetime;
var C: TGuiContext;
K: TGuiKnob;
P: TButtonLifetimeEvents;
  E: TGuiEvent;
  Wrapping,Action: Integer;
begin
  C:=TGuiContext.Create;
  P:=TButtonLifetimeEvents.Create;
  try
    C.Resize(300,200);
    for Wrapping:=0 to 1 do for Action:=0 to 2 do
    begin
      C.CancelInput;
      C.Root.Clear;
      P.Changes:=0;
      P.Clicks:=0;
      P.Mode:=1;
      K:=TGuiKnob.Create;
      C.Root.Add(K);
      K.Wrap:=Wrapping=1;
      K.Value:=100;
      K.OnChange:=P.Changed;
      K.OnMoved:=P.Clicked;
      C.SetFocus(K);
      if Action=1 then P.Mode:=3;
      if Action=2 then
      begin
        K.OnChange:=nil;
        K.OnMoved:=P.Changed;
      end;
      E:=Default(TGuiEvent);
      E.Kind:=gekKeyDown;
      if Wrapping=1 then E.KeyCode:=$4000004F else E.KeyCode:=$40000050;
      C.ProcessEvent(E);
      if Action=1 then Check(NOT K.Enabled AND (P.Changes=1) AND (P.Clicks=0),
        'Knob disabling OnChange suppresses subsequent moved notification')
      else Check((C.Root.ChildCount=0) AND (C.FocusedControl=nil) AND
        (P.Changes=1) AND (P.Clicks=0),'Knob callback may free sender with wrapping enabled or disabled');
    end;
  finally
    P.Free;
    C.Free;
  end;
end;

procedure TestSliderLifetime;
var C: TGuiContext;
S: TGuiSlider;
P: TButtonLifetimeEvents;
  E: TGuiEvent;
  Input,Action: Integer;
  procedure Mouse(Kind: TGuiEventKind; X: Single);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,20);
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  P:=TButtonLifetimeEvents.Create;
  try
    C.Resize(300,100);
    for Input:=0 to 2 do for Action:=0 to 2 do
    begin
      C.CancelInput;
      C.Root.Clear;
      P.Changes:=0;
      P.Clicks:=0;
      P.Mode:=1;
      S:=TGuiSlider.Create;
      C.Root.Add(S);
      S.Bounds:=GuiRect(0,0,116,40);
      S.OnChange:=P.Changed;
      S.OnMoved:=P.Clicked;
      C.SetFocus(S);
      if Action=1 then P.Mode:=3;
      if Input=2 then
      begin
        S.Live:=False;
        S.OnMoved:=nil;
        Mouse(gekMouseDown,31);
        S.OnMoved:=P.Clicked;
      end;
      if Action=2 then
      begin
        S.OnChange:=nil;
        S.OnMoved:=P.Changed;
      end;
      case Input of
        0:
        begin
          E:=Default(TGuiEvent);
          E.Kind:=gekKeyDown;
          E.KeyCode:=$4000004F;
          C.ProcessEvent(E);
        end;
        1: Mouse(gekMouseDown,31);
        2: Mouse(gekMouseUp,69);
      end;
      if Action=1 then
        Check(NOT S.Enabled AND (P.Changes=1) AND (P.Clicks=0),'Slider disabling change callback suppresses subsequent moved notification')
      else Check((C.Root.ChildCount=0) AND (C.FocusedControl=nil) AND (P.Changes=1) AND (P.Clicks=0),
        'Slider change/moved callback can free sender during key, live drag or deferred release');
    end;
  finally
    P.Free;
    C.Free;
  end;
end;

procedure TestSliderModes;
var C: TGuiContext;
S: TGuiSlider;
Changed,Moved: TControlEventProbe;
  E: TGuiEvent;
  Before: Integer;
  procedure Mouse(Kind: TGuiEventKind; X: Single; Button: TGuiMouseButton=gmbLeft);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Position:=GuiPoint(X,20);
    E.Button:=Button;
    C.ProcessEvent(E);
  end;
  procedure Key(Code: Cardinal);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  Changed:=TControlEventProbe.Create;
  Moved:=TControlEventProbe.Create;
  try
    C.Resize(300,100);
    S:=TGuiSlider.Create;
    C.Root.Add(S);
    S.Bounds:=GuiRect(0,0,116,40);
    S.OnChange:=Changed.Changed;
    S.OnMoved:=Moved.Changed;
    Check(S.Live AND (S.StepSize=0) AND (S.SnapMode=gsmNoSnap),'Slider preserves continuous live defaults');
    S.Live:=False;
    S.StepSize:=10;
    S.SnapMode:=gsmSnapAlways;
    Mouse(gekMouseDown,31);
    Check((S.Value=50) AND (S.PreviewValue=20) AND (Changed.Changes=0) AND (Moved.Changes=1),
      'Non-live slider previews snapped position without changing value');
    Mouse(gekMouseUp,69);
    Check((S.Value=60) AND (Changed.Changes=1),'Release uses final pointer position and commits exactly once');
    Mouse(gekMouseDown,31);
    Key(27);
    Mouse(gekMouseUp,31);
    Check((S.Value=60) AND (S.PreviewValue=60),'Escape discards deferred slider preview');
    Mouse(gekMouseDown,31);
    C.CancelInput;
    Mouse(gekMouseUp,31);
    Check(S.Value=60,'Focus cancellation discards deferred slider preview');
    Mouse(gekMouseDown,31);
    S.Value:=70;
    Mouse(gekMouseUp,31);
    Check(S.Value=70,'Programmatic value change disarms pending drag commit');
    S.SnapMode:=gsmSnapOnRelease;
    Mouse(gekMouseDown,31);
    Check(Abs(S.PreviewValue-23)<0.01,'Snap-on-release allows continuous preview');
    Mouse(gekMouseUp,31);
    Check(S.Value=20,'Snap-on-release commits nearest step');
    S.Live:=True;
    S.SnapMode:=gsmNoSnap;
    Mouse(gekMouseDown,31);
    Check(Abs(S.Value-23)<0.01,'No-snap live drag retains continuous values');
    C.CancelInput;
    Check(Abs(S.Value-23)<0.01,'Cancelling live drag retains already-reported value');
    Before:=Changed.Changes;
    Mouse(gekMouseDown,90,gmbRight);
    Mouse(gekMouseUp,90,gmbRight);
    Check(Changed.Changes=Before,'Secondary mouse button does not move slider');
    C.SetFocus(S);
    S.Value:=20;
    Key($40000052);
    Check(S.Value=30,'Up increases by configured slider step');
    Key($40000051);
    Check(S.Value=20,'Down decreases by configured slider step');
    Key($4000004D);
    Before:=Moved.Changes;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseWheel;
    E.Delta:=GuiPoint(0,1);
    S.HandleEvent(E);
    Check(NOT E.Handled AND (Moved.Changes=Before),'Wheel at slider endpoint bubbles without moved notification');
    S.Enabled:=False;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$4000004A;
    S.HandleEvent(E);
    Check(S.Value=100,'Disabled slider rejects direct input');
    S.Enabled:=True;
    S.Live:=False;
    Mouse(gekMouseDown,31);
    S.MinValue:=80;
    Mouse(gekMouseUp,31);
    Check(S.Value=100,'Changing slider range cancels pending pointer commit');
    S.MinValue:=0;
    S.Value:=50;
    S.SnapMode:=gsmSnapAlways;
    Mouse(gekMouseDown,31);
    Mouse(gekMouseUp,250);
    Check(S.Value=100,'Captured release outside slider reaches clamped endpoint');
    S.Live:=True;
    S.SnapMode:=gsmNoSnap;
    S.StepSize:=0;
    S.MinValue:=-3.0E38;
    S.MaxValue:=3.0E38;
    S.Value:=0;
    Mouse(gekMouseDown,58);
    Mouse(gekMouseUp,58);
    Check(NOT IsNan(S.Value) AND NOT IsInfinite(S.Value) AND (Abs(S.Value)<1.0E30),
      'Extreme finite slider range maps the track midpoint to zero');
    C.SetFocus(S);
    Key($4000004F);
    Check(NOT IsInfinite(S.Value) AND (S.Value>2.9E37) AND (S.Value<3.1E37),
      'Extreme finite slider range retains its default one-twentieth keyboard step');
    S.Value:=0;
    S.StepSize:=3.0E38;
    Key($4000004B);
    Check(S.Value=S.MaxValue,'Oversized slider PageUp clamps before narrowing to Single');
    Key($4000004E);
    Check(S.Value=S.MinValue,'Oversized slider PageDown clamps before narrowing to Single');
  finally
    Moved.Free;
    Changed.Free;
    C.Free;
  end;
end;

procedure TestRadioGroup;
var C: TGuiContext;
R: TGuiRadioGroup;
Probe: TControlEventProbe;
Canvas: TTestCanvas;
  E: TGuiEvent;
  I,Before: Integer;
  OldY: TGuiFloat;
  Rejected: Boolean;
  procedure Key(Code: Cardinal);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  Probe:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(300,200);
    R:=TGuiRadioGroup.Create;
    C.Root.Add(R);
    R.Bounds:=GuiRect(0,0,240,110);
    R.OnChange:=Probe.Changed;
    Check((R.ItemIndex=-1) AND (R.Items.Count=0),'Radio group starts empty');
    for I:=0 to 19 do R.AddItem('Option '+IntToStr(I));
    Check((R.ItemIndex=0) AND (Probe.Changes=1),'Adding first radio option selects it and notifies once');
    C.SetFocus(R);
    Key($4000004D);
    Check((R.ItemIndex=19) AND (R.ScrollY>0),'End selects and reveals last radio option');
    Before:=Probe.Changes;
    R.ItemHeight:=1;
    Check((R.ScrollY=0) AND (R.ItemIndex=19) AND (Probe.Changes=Before),
      'Shrinking radio rows immediately reconciles scroll without selection notifications');
    R.ItemHeight:=34;
    Check((R.ScrollY>0) AND (R.ScrollY=R.MaxScrollY),
      'Growing radio rows immediately reveals the selected last option');
    Rejected:=False;
    try
      R.ItemHeight:=NaN;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (R.ItemHeight=34),'Radio rows reject NaN heights atomically');
    Rejected:=False;
    try
      R.ItemHeight:=Infinity;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (R.ItemHeight=34),'Radio rows reject infinite heights atomically');
    Key($4000004A);
    Key($4000004F);
    Check(R.ItemIndex=1,'Home and Right navigate radio options');
    Before:=Probe.Changes;
    Key(32);
    Key(13);
    Check((R.ItemIndex=1) AND (Probe.Changes=Before),'Space/Enter retain current exclusive radio option');
    Key($4000004E);
    Check(R.ItemIndex>1,'PageDown advances by visible radio rows');
    R.ScrollY:=0;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(180,20);
    C.ProcessEvent(E);
    Check(R.ItemIndex=0,'Clicking radio row caption area selects its option');
    C.CancelInput;
    Check(R.ItemIndex=0,'Cancelling clears gesture while retaining press-time row selection');
    Before:=Probe.Changes;
    OldY:=R.ScrollY;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseWheel;
    E.Delta:=GuiPoint(0,-1);
    R.HandleEvent(E);
    Check((R.ScrollY>OldY) AND (Probe.Changes=Before),'Wheel scrolls radio options without changing selection');
    R.Enabled:=False;
    Before:=R.ItemIndex;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$4000004D;
    R.HandleEvent(E);
    Check(R.ItemIndex=Before,'Disabled radio group ignores direct input');
    R.Enabled:=True;
    R.ItemIndex:=19;
    Before:=Probe.Changes;
    R.Items.Delete(19);
    Check((R.ItemIndex=18) AND (Probe.Changes=Before+1),'Removing selected tail clamps radio index and notifies');
    R.Items.Clear;
    Check((R.ItemIndex=-1) AND (R.ScrollY=0),'Clearing radio options clears selection and scrolling');
    R.Items.Text:='First'+#10+'Second';
    R.ItemIndex:=1;
    R.ItemIndex:=1;
    R.Paint(Canvas);
    Check((Canvas.TextDrawCount=2) AND (Canvas.LastTextRect.Left=38) AND (Canvas.ClipDepth=0),
      'Radio group reserves indicator space and balances row clipping');
    R.ItemIndex:=-1;
    C.SetFocus(R);
    Key(32);
    Check(R.ItemIndex=0,'Space selects first option after explicit clear');
    R.Items.BeginUpdate;
    try
      for I:=0 to 9999 do R.Items.Add('Large option');
    finally
      R.Items.EndUpdate;
    end;
    R.ItemIndex:=R.Items.Count-1;
    Canvas.TextDrawCount:=0;
    R.Paint(Canvas);
    Check((Canvas.TextDrawCount<=5) AND (Canvas.ClipDepth=0),'Large radio group paints only visible rows');
  finally
    Canvas.Free;
    Probe.Free;
    C.Free;
  end;
end;

procedure TestRadioState;
var C: TGuiContext;
A,B,D: TGuiRadioButton;
Other: TGuiPanel;
  Probe: TControlEventProbe;
  E: TGuiEvent;
  Before: Integer;
  procedure Key(Code: Cardinal);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  Probe:=TControlEventProbe.Create;
  try
    C.Resize(500,200);
    A:=TGuiRadioButton.Create;
    B:=TGuiRadioButton.Create;
    D:=TGuiRadioButton.Create;
    C.Root.Add(A);
    C.Root.Add(D);
    C.Root.Add(B);
    A.Bounds:=GuiRect(0,0,120,36);
    D.Bounds:=GuiRect(130,0,120,36);
    B.Bounds:=GuiRect(260,0,120,36);
    A.OnChange:=Probe.Changed;
    B.OnChange:=Probe.Changed;
    A.Checked:=True;
    A.Checked:=True;
    B.Checked:=True;
    Check(B.Checked AND NOT A.Checked AND (Probe.Changes=3),'Programmatic radio selection enforces exclusivity and exact notifications');
    A.GroupName:='other';
    A.Checked:=True;
    Check(A.Checked AND B.Checked,'Named radio groups can select independently');
    A.GroupName:='';
    Check(A.Checked AND NOT B.Checked,'Changing group name reconciles checked state');
    Other:=TGuiPanel.Create;
    Other.Bounds:=GuiRect(0,80,400,80);
    C.Root.Add(Other);
    Other.Add(B);
    B.Checked:=True;
    Check(A.Checked AND B.Checked,'Radio groups are scoped to parent');
    C.Root.Add(B);
    Check(B.Checked AND NOT A.Checked,'Reparenting checked radio reconciles new group');
    D.Enabled:=False;
    C.SetFocus(B);
    Key($4000004F);
    Check(A.Checked AND NOT B.Checked AND (C.FocusedControl=A),'Radio arrow navigation wraps and moves selection/focus');
    Key($4000004F);
    Check(B.Checked AND NOT A.Checked,'Radio arrow navigation skips disabled peers');
    A.Visible:=False;
    Key($4000004F);
    Check(B.Checked,'Radio arrows skip hidden peers');
    A.Visible:=True;
    Before:=Probe.Changes;
    Key(32);
    Key(13);
    Check(B.Checked AND (Probe.Changes=Before),'Activating selected radio preserves state without duplicate change');
    B.Checked:=False;
    Check(NOT A.Checked AND NOT B.Checked,'Programmatic radio clear remains supported');
    B.Enabled:=False;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$40000050;
    B.HandleEvent(E);
    Check(NOT A.Checked AND NOT B.Checked,'Disabled radio rejects direct navigation');
    B.Enabled:=True;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(20,20);
    C.ProcessEvent(E);
    C.CancelInput;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseUp;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(20,20);
    C.ProcessEvent(E);
    Check(NOT A.Checked,'Cancelled radio click leaves state unchanged');
  finally
    Probe.Free;
    C.Free;
  end;
end;

procedure TestTabButtons;
var C: TGuiContext;
A,B,D: TGuiTabButton;
E: TGuiEvent;
Probe: TControlEventProbe;
  Canvas: TTestCanvas;
  procedure Key(Code: Cardinal);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  Probe:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(500,100);
    A:=TGuiTabButton.Create;
    B:=TGuiTabButton.Create;
    D:=TGuiTabButton.Create;
    C.Root.Add(A);
    C.Root.Add(D);
    C.Root.Add(B);
    A.Bounds:=GuiRect(0,0,120,36);
    D.Bounds:=GuiRect(130,0,120,36);
    B.Bounds:=GuiRect(260,0,120,36);
    A.OnChange:=Probe.Changed;
    D.Enabled:=False;
    Check(A.Checkable AND (A.GroupIndex=1) AND NOT A.AllowAllUp,'Tab buttons default to exclusive selection');
    A.Down:=True;
    C.SetFocus(A);
    Key($4000004F);
    Check(B.Down AND NOT A.Down AND (C.FocusedControl=B),'Tab arrow navigation skips disabled peers and moves focus');
    Key($4000004F);
    Check(A.Down AND NOT B.Down,'Tab arrow navigation wraps the group');
    B.Visible:=False;
    Key($40000050);
    Check(A.Down,'Tab navigation skips hidden peers');
    B.Visible:=True;
    Key(32);
    Check(A.Down,'Space retains selected tab');
    C.SetFocus(B);
    Key(13);
    Check(B.Down AND NOT A.Down,'Enter selects a focused tab exclusively');
    B.Enabled:=False;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$40000050;
    B.HandleEvent(E);
    Check(B.Down AND NOT A.Down,'Disabled tab ignores arrow navigation');
    B.Enabled:=True;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(20,20);
    C.ProcessEvent(E);
    C.CancelInput;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseUp;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(20,20);
    C.ProcessEvent(E);
    Check(B.Down AND NOT A.Down,'Cancelled tab press does not change selection');
    A.Down:=True;
    A.Paint(Canvas);
    Check((Canvas.LastFill.Left=8) AND (Canvas.LastFill.Top=34) AND
      (Canvas.LastFill.Width=104) AND (Canvas.LastFill.Height=2),'Selected tab paints an inset two-pixel underline');
    Check(Probe.Changes=5,'Tab state transitions emit exact change notifications');
  finally
    Canvas.Free;
    Probe.Free;
    C.Free;
  end;
end;

procedure TestSeparatorBounds;
var S: TGuiSeparator;
Canvas: TTestCanvas;
B: TGuiToolBar;
Rejected: Boolean;
Before: Integer;
begin
  S:=TGuiSeparator.Create;
  Canvas:=TTestCanvas.Create;
  B:=TGuiToolBar.Create;
  try
    S.Bounds:=GuiRect(10,20,30,4);
    S.Thickness:=100;
    S.Paint(Canvas);
    Check((Canvas.LastFill.Top=20) AND (Canvas.LastFill.Height=4),'Oversized horizontal separator stays within its bounds');
    S.Orientation:=goVertical;
    S.Bounds:=GuiRect(10,20,4,30);
    S.Paint(Canvas);
    Check((Canvas.LastFill.Left=10) AND (Canvas.LastFill.Width=4),'Oversized vertical separator stays within its bounds');
    S.Thickness:=0;
    Before:=Canvas.FillCount;
    S.Paint(Canvas);
    Check(Canvas.FillCount=Before,'Zero thickness explicitly hides separator');
    S.Thickness:=1;
    S.Bounds:=GuiRect(0,0,0,20);
    S.Paint(Canvas);
    Check(Canvas.FillCount=Before,'Zero-sized separator emits no paint');
    Rejected:=False;
    try
      S.Thickness:=-1;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (S.Thickness=1),'Negative separator thickness rejected without mutation');
    Rejected:=False;
    try
      S.Thickness:=NaN;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected,'Nonfinite separator thickness rejected');
    Rejected:=False;
    try
      B.Spacing:=Infinity;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (B.Spacing=4),'Nonfinite toolbar spacing rejected without corrupting layout');
  finally
    S.Free;
    Canvas.Free;
    B.Free;
  end;
end;

procedure TestToolbarAliases;
var Control: TGuiControl;
begin
  Control:=PasSDL3.GUI.Controls.Buttons.TGuiRoundButton.Create;
  try
    Check(Control.ClassType=TGuiRoundButton,'Categorized round button alias is the core implementation');
  finally
    Control.Free;
  end;
  Control:=PasSDL3.GUI.Controls.Buttons.TGuiSpeedButton.Create;
  try
    Check(Control.ClassType=TGuiSpeedButton,'Categorized speed button alias is the core implementation');
  finally
    Control.Free;
  end;
  Control:=PasSDL3.GUI.Controls.Bars.TGuiToolBar.Create;
  try
    Check(Control.ClassType=TGuiToolBar,'Categorized toolbar alias is the core implementation');
  finally
    Control.Free;
  end;
  Control:=PasSDL3.GUI.Controls.Bars.TGuiSeparator.Create;
  try
    Check(Control.ClassType=TGuiSeparator,'Categorized separator alias is the core implementation');
  finally
    Control.Free;
  end;
  Control:=PasSDL3.GUI.Controls.TGuiToolBar.Create;
  try
    Check(Control.ClassType=TGuiToolBar,'Aggregate toolbar alias is the core implementation');
  finally
    Control.Free;
  end;
end;

procedure TestSpeedButtonsAndToolbar;
var C: TGuiContext;
Bar,Other: TGuiToolBar;
A,B: TSpeedProbe;
  Edit: TGuiEdit;
  Sep: TGuiSeparator;
  Probe: TControlEventProbe;
  Canvas: TTestCanvas;
  E: TGuiEvent;
  I,Before: Integer;
begin
  C:=TGuiContext.Create;
  Probe:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(500,300);
    Bar:=TGuiToolBar.Create;
    Bar.Bounds:=GuiRect(0,0,400,48);
    C.Root.Add(Bar);
    Other:=TGuiToolBar.Create;
    Other.Bounds:=GuiRect(0,100,400,100);
    C.Root.Add(Other);
    A:=TSpeedProbe.Create;
    B:=TSpeedProbe.Create;
    Bar.Add(A);
    Bar.Add(B);
    A.OnChange:=Probe.Changed;
    A.OnClick:=Probe.Clicked;
    Check((A.StyleClass='Quiet') AND NOT A.Down AND NOT A.Checkable AND (A.GroupIndex=0),
      'Speed button defaults to a quiet momentary toolbar command');
    A.ClickNow;
    Check((Probe.Clicks=1) AND (Probe.Changes=0),'Momentary command does not latch');
    A.Checkable:=True;
    A.ClickNow;
    A.Down:=True;
    Check(A.Down AND A.CheckedVisual AND (Probe.Changes=1),'Checkable speed button latches and notifies once');
    C.SetFocus(A);
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=32;
    C.ProcessEvent(E);
    Check(NOT A.Down,'Space toggles focused speed button');
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=13;
    C.ProcessEvent(E);
    Check(A.Down,'Enter toggles focused speed button');
    A.GroupIndex:=2;
    B.GroupIndex:=2;
    B.Down:=True;
    Check(B.Down AND NOT A.Down,'Programmatic group selection unchecks sibling');
    B.ClickNow;
    Check(B.Down,'Exclusive group retains active button on repeated click');
    B.AllowAllUp:=True;
    B.ClickNow;
    Check(NOT B.Down,'AllowAllUp permits clearing a selected group');
    A.Down:=True;
    B.Down:=True;
    Other.Add(B);
    A.Down:=True;
    Check(A.Down AND B.Down,'Speed button groups are scoped to their parent');
    Bar.Add(B);
    Check(B.Down AND NOT A.Down,'Reparenting a down button restores group exclusivity');
    A.Enabled:=False;
    Before:=Probe.Clicks;
    A.ClickNow;
    Check(NOT A.Down AND (Probe.Clicks=Before),'Disabled speed button cannot activate');
    A.Enabled:=True;
    Bar.Arrange(Bar.Bounds);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(A.AbsoluteBounds.Left+10,A.AbsoluteBounds.Top+10);
    C.ProcessEvent(E);
    C.CancelInput;
    E.Kind:=gekMouseUp;
    C.ProcessEvent(E);
    Check(NOT A.Down,'Cancelled toolbar press does not toggle');
    A.GroupIndex:=0;
    A.Down:=False;
    A.Bounds:=GuiRect(0,0,32,32);
    A.Padding:=GuiBox(4);
    A.Caption:='';
    A.Icon:=GuiColorDrawable(GuiColor(255,255,255));
    for I:=0 to 3 do
    begin
      A.IconPlacement:=TGuiIconPlacement(I);
      A.Paint(Canvas);
      Check((Abs(Canvas.LastFill.Left-A.AbsoluteBounds.Left-8)<0.01) AND
        (Abs(Canvas.LastFill.Top-A.AbsoluteBounds.Top-8)<0.01),'Icon-only button centers independently of placement');
    end;
    GuiApplyTheme(A,GuiDarkTheme);
    Check(A.Padding.Left=4,'Theme preserves compact toolbar padding');
    Sep:=TGuiSeparator.Create;
    Sep.Bounds:=GuiRect(0,0,10,32);
    Sep.Orientation:=goVertical;
    Bar.Add(Sep);
    Edit:=TGuiEdit.Create;
    Edit.Bounds:=GuiRect(0,0,100,32);
    Bar.Add(Edit);
    Bar.Arrange(Bar.Bounds);
    Check((Edit.Bounds.Left>Sep.Bounds.Left+Sep.Bounds.Width) AND NOT Sep.CanFocus AND
      (Sep.HitTest(GuiPoint(Sep.AbsoluteBounds.Left,Sep.AbsoluteBounds.Top))=nil),
      'Horizontal toolbar lays out embedded edit and passive separator');
    Bar.Orientation:=goVertical;
    Bar.Bounds:=GuiRect(0,0,200,240);
    Bar.Arrange(Bar.Bounds);
    Check(Edit.Bounds.Top>Sep.Bounds.Top+Sep.Bounds.Height,'Vertical toolbar stacks arbitrary controls');
    Sep.Orientation:=goHorizontal;
    Sep.Paint(Canvas);
    Check(Abs(Canvas.LastFill.Height-Sep.Thickness)<0.01,'Horizontal separator paints configured thickness');
    Sep.Orientation:=goVertical;
    Sep.Paint(Canvas);
    Check(Abs(Canvas.LastFill.Width-Sep.Thickness)<0.01,'Vertical separator paints configured thickness');
  finally
    Canvas.Free;
    Probe.Free;
    C.Free;
  end;
end;

function TProgressProbe.AnimationTime: UInt64;
begin
  Result:=Ticks;
end;

procedure TestMarqueeProgress;
var P: TProgressProbe;
Canvas: TTestCanvas;
Rejected: Boolean;
begin
  P:=TProgressProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    Check(NOT P.Marquee AND (P.MarqueeInterval=1500),'Progress retains determinate default');
    P.SegmentCount:=4;
    Rejected:=False;
    try
      P.SegmentCount:=-1;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (P.SegmentCount=4),'Progress rejects negative segment count atomically');
    P.TickCount:=5;
    Rejected:=False;
    try
      P.TickCount:=-1;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (P.TickCount=5),'Progress rejects negative tick count atomically');
    P.Bounds:=GuiRect(0,0,100,20);
    P.Padding:=GuiBox(0);
    P.SegmentCount:=High(Integer);
    P.TickCount:=High(Integer);
    P.ShowTicks:=True;
    Canvas.FillCount:=0;
    P.Paint(Canvas);
    Check((Canvas.FillCount<100) AND (Canvas.ClipDepth=0),
      'Dense progress counts have bounded drawing work and balanced clipping');
    Check((P.SegmentCount=High(Integer)) AND (P.TickCount=High(Integer)),
      'Dense rendering preserves requested model counts');
    P.SegmentCount:=0;
    P.TickCount:=0;
    P.ShowTicks:=False;
    P.SegmentGap:=4;
    Rejected:=False;
    try
      P.SegmentGap:=NaN;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (P.SegmentGap=4),'Progress rejects NaN gap atomically');
    Rejected:=False;
    try
      P.SegmentGap:=-1;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (P.SegmentGap=4),'Progress rejects negative gap atomically');
    Rejected:=False;
    try
      P.SegmentGap:=Infinity;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (P.SegmentGap=4),'Progress rejects infinite gap atomically');
    P.ThresholdValue:=42;
    Rejected:=False;
    try
      P.ThresholdValue:=NaN;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (P.ThresholdValue=42),'Progress rejects NaN threshold atomically');
    Rejected:=False;
    try
      P.ThresholdValue:=NegInfinity;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (P.ThresholdValue=42),'Progress rejects infinite threshold atomically');
    P.MinValue:=-50;
    P.MaxValue:=50;
    P.Value:=100;
    Check(P.Value=50,'Progress clamps to maximum');
    P.Value:=-100;
    Check(P.Value=-50,'Progress clamps to minimum');
    Rejected:=False;
    try
      P.Value:=NaN;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (P.Value=-50),'Progress rejects NaN without changing value');
    Rejected:=False;
    try
      P.MinValue:=NegInfinity;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (P.MinValue=-50),'Progress rejects infinite minimum atomically');
    Rejected:=False;
    try
      P.MaxValue:=Infinity;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (P.MaxValue=50),'Progress rejects infinite maximum atomically');
    P.MinValue:=80;
    Check((P.MaxValue=80) AND (P.Value=80),'Raising minimum collapses and clamps range');
    P.MaxValue:=20;
    Check((P.MinValue=20) AND (P.Value=20),'Lowering maximum collapses and clamps range');
    P.MinValue:=0;
    P.MaxValue:=100;
    P.Value:=37;
    P.Marquee:=True;
    P.MarqueeInterval:=1000;
    P.Ticks:=0;
    Check(Abs(P.MarqueePosition)<0.001,'Marquee starts at track origin');
    P.Ticks:=250;
    Check(Abs(P.MarqueePosition-0.5)<0.001,'Marquee smoothly traverses the track');
    P.Ticks:=500;
    Check(Abs(P.MarqueePosition-1)<0.001,'Marquee reaches opposite endpoint');
    P.Ticks:=1000;
    Check(Abs(P.MarqueePosition)<0.001,'Marquee wraps its cycle');
    P.Ticks:=High(UInt64);
    Check((P.MarqueePosition>=0) AND (P.MarqueePosition<=1),'Marquee handles large monotonic times');
    P.ShowText:=True;
    P.ShowTicks:=True;
    P.ShowThreshold:=True;
    P.SegmentCount:=10;
    P.Paint(Canvas);
    Check((Canvas.TextDrawCount=0) AND (Canvas.ClipDepth=0),'Marquee hides determinate text and balances clipping');
    P.Enabled:=False;
    P.Ticks:=500;
    Check(P.MarqueePosition=0,'Disabled marquee has static position');
    P.Bounds:=GuiRect(0,0,0,0);
    P.Paint(Canvas);
    Check(Canvas.ClipDepth=0,'Empty marquee balances clipping');
    P.MarqueeInterval:=0;
    Check(P.MarqueeInterval=1,'Zero marquee interval clamps safely');
    P.Marquee:=False;
    Check(P.Value=37,'Switching progress modes preserves determinate value');
  finally
    Canvas.Free;
    P.Free;
  end;
end;

procedure TPageIndicatorProbe.Reset;
begin
  Painted:=0;
  SelectedDots:=0;
  PressedDots:=0;
end;

procedure TPageIndicatorProbe.PaintIndicator(ACanvas: TGuiCanvas; AIndex: Integer;
  const ARect: TGuiRect; ASelected, APressed: Boolean);
begin
  if Painted=0 then
  begin
    FirstIndex:=AIndex;
    FirstRect:=ARect;
  end;
  Inc(FPainted);
  LastIndex:=AIndex;
  if ASelected then Inc(FSelectedDots);
  if APressed then Inc(FPressedDots);
  inherited;
end;

procedure TestPageIndicator;
var C: TGuiContext;
D: TPageIndicatorProbe;
Canvas: TTestCanvas;
  Probe: TControlEventProbe;
  E: TGuiEvent;
  Before: Integer;
  Rejected: Boolean;
  procedure Paint;
  begin
    D.Reset;
    D.Paint(Canvas);
  end;
  procedure Key(Code: Cardinal);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    C.ProcessEvent(E);
  end;
begin
  C:=TGuiContext.Create;
  Canvas:=TTestCanvas.Create;
  Probe:=TControlEventProbe.Create;
  try
    C.Resize(300,100);
    D:=TPageIndicatorProbe.Create;
    C.Root.Add(D);
    D.Bounds:=GuiRect(0,0,160,28);
    D.Padding:=GuiBox(0);
    D.OnSelect:=Probe.Changed;
    Check((D.Count=0) AND (D.SelectedIndex=-1) AND NOT D.Interactive AND NOT D.CanFocus,
      'Page indicator defaults to empty and passive');
    D.Count:=3;
    D.Count:=3;
    D.SelectedIndex:=0;
    Check((Probe.Changes=1) AND (D.SelectedIndex=0) AND (D.HitTest(GuiPoint(80,14))=nil),
      'First page is selected once without intercepting passive input');
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$4000004F;
    D.HandleEvent(E);
    Check(D.SelectedIndex=0,'Passive indicator ignores navigation');
    D.Interactive:=True;
    C.SetFocus(D);
    Check(D.CanFocus AND D.TabStop AND (D.HitTest(GuiPoint(80,14))=D),'Interactive indicator accepts focus and hits');
    Key($4000004F);
    Check(D.SelectedIndex=1,'Right selects next page');
    Key($4000004D);
    Check(D.SelectedIndex=2,'End selects last page');
    Before:=Probe.Changes;
    Key($4000004F);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseWheel;
    E.Delta:=GuiPoint(0,-1);
    D.HandleEvent(E);
    Check((Probe.Changes=Before) AND NOT E.Handled,'Clamped navigation emits no duplicate event and wheel bubbles');
    Key($4000004A);
    Paint;
    Check((D.Painted=3) AND (D.SelectedDots=1) AND (Abs(D.FirstRect.Left-57)<0.01),
      'Dots are centered with one selected delegate');
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(98,14);
    C.ProcessEvent(E);
    Paint;
    Check((D.SelectedIndex=2) AND (D.PressedDots=1),'Press selects target dot with pressed feedback');
    C.CancelInput;
    Paint;
    Check((D.SelectedIndex=2) AND (D.PressedDots=0),'Cancel clears feedback without undoing press-time selection');
    D.Enabled:=False;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$4000004A;
    D.HandleEvent(E);
    Check(D.SelectedIndex=2,'Disabled indicator ignores input');
    D.Enabled:=True;
    D.Count:=1000000;
    D.SelectedIndex:=500000;
    D.MaxVisibleDots:=5;
    Paint;
    Check((D.Painted=5) AND (D.FirstIndex=499998) AND (D.LastIndex=500002) AND
      (D.SelectedDots=1),'Large page counts paint only a selected-centered dot window');
    D.Bounds:=GuiRect(0,0,30,28);
    Paint;
    Check((D.Painted=2) AND (Canvas.ClipDepth=0),'Narrow indicator reduces dots and balances clipping');
    D.Count:=1;
    Check(D.SelectedIndex=0,'Count shrink clamps selected page');
    D.Count:=0;
    Paint;
    Check((D.SelectedIndex=-1) AND (D.Painted=0) AND NOT D.CanFocus AND
      (D.HitTest(GuiPoint(10,10))=nil),'Empty indicator clears selection, painting and focusability');
    D.DotSize:=0;
    D.Spacing:=-5;
    D.MaxVisibleDots:=0;
    Check((D.DotSize=1) AND (D.Spacing=0) AND (D.MaxVisibleDots=1),'Indicator geometry setters clamp invalid sizes');
    Rejected:=False;
    try
      D.DotSize:=NaN;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (D.DotSize=1),'Indicator rejects NaN dot size without changing state');
    Rejected:=False;
    try
      D.Spacing:=Infinity;
    except
      on E: EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (D.Spacing=0),'Indicator rejects infinite spacing without changing state');
    D.Count:=High(Integer);
    D.SelectedIndex:=High(Integer)-1;
    D.Bounds:=GuiRect(0,0,160,28);
    D.MaxVisibleDots:=5;
    D.DotSize:=10;
    D.Spacing:=8;
    Paint;
    Check((D.Painted=5) AND (D.LastIndex=High(Integer)-1) AND (D.SelectedDots=1),
      'Maximum page count keeps a bounded window containing the last selected page');
    D.Interactive:=False;
    Before:=Probe.Changes;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseWheel;
    E.Delta:=GuiPoint(0,1);
    D.HandleEvent(E);
    Check((Probe.Changes=Before) AND NOT D.CanFocus AND NOT D.TabStop AND
      (D.HitTest(GuiPoint(80,14))=nil),'Returning to passive mode removes navigation and hit targets');
  finally
    Probe.Free;
    Canvas.Free;
    C.Free;
  end;
end;

function TActivityProbe.AnimationTime: UInt64;
begin
  Result:=Ticks;
end;
procedure TControlEventProbe.Changed(Sender: TGuiControl);
begin
  Inc(FChanges);
end;
procedure TControlEventProbe.Clicked(Sender: TGuiControl);
begin
  Inc(FClicks);
  if Sender IS TGuiCheckBox then ClickState:=TGuiCheckBox(Sender).State;
end;
procedure TControlEventProbe.NextChecked(Sender: TGuiControl; var AState: TGuiCheckBoxState);
begin
  Inc(FNextCalls);
  AState:=gcbChecked;
end;
procedure TCheckBoxProbe.ClickNow;
begin
  DoClick;
end;

procedure TestThreeStateCheckBox;
var Context: TGuiContext;
Box: TCheckBoxProbe;
Probe: TControlEventProbe;
  E: TGuiEvent;
  Before: Integer;
  Rejected: Boolean;
  procedure Key(Code: Cardinal);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    Context.ProcessEvent(E);
  end;
begin
  Context:=TGuiContext.Create;
  Probe:=TControlEventProbe.Create;
  try
    Context.Resize(300,100);
    Box:=TCheckBoxProbe.Create;
    Box.Bounds:=GuiRect(0,0,180,34);
    Context.Root.Add(Box);
    Context.SetFocus(Box);
    Box.OnChange:=Probe.Changed;
    Box.OnClick:=Probe.Clicked;
    Check(NOT Box.Checked AND NOT Box.AllowGrayed AND (Box.State=gcbUnchecked),'Checkbox retains two-state defaults');
    Box.Checked:=True;
    Box.Checked:=True;
    Check((Box.State=gcbChecked) AND (Probe.Changes=1) AND (Probe.Clicks=0),
      'Checked property updates state and emits only actual changes');
    Box.State:=gcbGrayed;
    Check(NOT Box.Checked AND (Probe.Changes=2),'Mixed checkbox is distinct from Checked=True');
    Key(32);
    Check((Box.State=gcbChecked) AND (Probe.Changes=3) AND (Probe.Clicks=1),
      'Two-state user cycle resolves a programmatic mixed state to checked');
    Box.State:=gcbUnchecked;
    Box.AllowGrayed:=True;
    Key(32);
    Check((Box.State=gcbGrayed) AND (Probe.ClickState=gcbGrayed),'Tri-state Space activation enters mixed state before OnClick');
    Key(13);
    Check(Box.State=gcbChecked,'Tri-state Enter activation advances mixed to checked');
    Key(32);
    Check((Box.State=gcbUnchecked) AND (Probe.Changes=7) AND (Probe.Clicks=4),
      'Three-state cycle returns to unchecked with one notification per transition');
    Box.OnGetNextState:=Probe.NextChecked;
    Key(32);
    Key(32);
    Check(Box.Checked AND (Probe.NextCalls=2) AND (Probe.Changes=8) AND (Probe.Clicks=6),
      'Custom state policy is called per activation without duplicate change notifications');
    Box.OnGetNextState:=nil;
    Box.State:=gcbGrayed;
    Box.AllowGrayed:=False;
    Check(Box.State=gcbGrayed,'AllowGrayed controls user cycling without discarding aggregate state');
    Box.Checked:=False;
    Check(Box.State=gcbUnchecked,'Checked=False clears a mixed state');
    Before:=Probe.Changes;
    Box.Enabled:=False;
    Box.ClickNow;
    Check((Probe.Changes=Before) AND NOT Box.Checked,'Disabled direct activation cannot change checkbox state');
    Box.Enabled:=True;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(40,15);
    Context.ProcessEvent(E);
    Context.CancelInput;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseUp;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(40,15);
    Context.ProcessEvent(E);
    Check(Probe.Changes=Before,'Cancelled checkbox press never advances the state cycle');
    Rejected:=False;
    try
      Box.State:=TGuiCheckBoxState(3);
    except
      on E: EArgumentOutOfRangeException do Rejected:=True;
    end;
    Check(Rejected AND (Box.State=gcbUnchecked),'Invalid checkbox states are rejected without changing state');
  finally
    Context.Free;
    Probe.Free;
  end;
end;

procedure TestActivityAndSwitch;
var Context: TGuiContext;
Switch: TGuiToggleSwitch;
Other: TGuiButton;
  Busy: TActivityProbe;
  Probe: TControlEventProbe;
  Canvas: TTestCanvas;
  E: TGuiEvent;
  Before: Integer;
  procedure Mouse(Kind: TGuiEventKind; X,Y: TGuiFloat; Button: TGuiMouseButton=gmbLeft);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Position:=GuiPoint(X,Y);
    E.Button:=Button;
    Context.ProcessEvent(E);
  end;
  procedure Key(Code: Cardinal);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    Context.ProcessEvent(E);
  end;
begin
  Context:=TGuiContext.Create;
  Probe:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  Busy:=TActivityProbe.Create;
  try
    Context.Resize(400,200);
    Switch:=TGuiToggleSwitch.Create;
    Switch.Bounds:=GuiRect(10,10,160,34);
    Switch.Caption:='Switch';
    Switch.OnChange:=Probe.Changed;
    Switch.OnClick:=Probe.Clicked;
    Context.Root.Add(Switch);
    Other:=TGuiButton.Create;
    Other.Bounds:=GuiRect(200,10,100,34);
    Context.Root.Add(Other);
    Mouse(gekMouseDown,120,25);
    Mouse(gekMouseUp,120,25);
    Check(Switch.Checked AND (Probe.Changes=1) AND (Probe.Clicks=1),
      'Switch caption click changes state and emits each event once');
    Switch.Checked:=True;
    Check(Probe.Changes=1,'Unchanged switch assignment emits no change');
    Key(32);
    Check(NOT Switch.Checked AND (Probe.Changes=2) AND (Probe.Clicks=2),
      'Focused switch toggles through standard Space activation');
    Key($4000004F);
    Key($4000004F);
    Check(Switch.Checked AND (Probe.Changes=3),'Switch arrow keys select a state without duplicate changes');
    Key($40000050);
    Mouse(gekMouseDown,24,25);
    Mouse(gekMouseMove,46,25);
    Check((Switch.ThumbPosition=1) AND NOT Switch.Checked,'Switch drag previews thumb position before commit');
    Mouse(gekMouseUp,46,25);
    Check(Switch.Checked AND (Probe.Changes=5) AND (Probe.Clicks=3),
      'Switch drag commits once without toggling again on context release');
    Mouse(gekMouseDown,46,25);
    Mouse(gekMouseMove,24,25);
    Context.CancelInput;
    Check(Switch.Checked AND (Switch.ThumbPosition=1) AND NOT Switch.Pressed AND (Probe.Changes=5),
      'Switch cancellation restores committed state and clears drag feedback');
    Mouse(gekMouseDown,46,25);
    Mouse(gekMouseMove,0,25);
    Mouse(gekMouseUp,0,25);
    Check(NOT Switch.Checked AND (Probe.Changes=6),'Captured switch drag can finish outside its bounds');
    Context.SetFocus(Switch);
    Key(32);
    Check(Switch.Checked AND (Probe.Changes=7) AND (Probe.Clicks=4),
      'Outside drag release never suppresses the next keyboard activation');
    Mouse(gekMouseDown,46,25);
    Context.SetFocus(Other);
    Mouse(gekMouseUp,46,25);
    Check(Switch.Checked AND (Probe.Changes=7) AND (Probe.Clicks=4),
      'Switch blur cancels the pending pointer activation');
    Mouse(gekMouseDown,46,25,gmbRight);
    Mouse(gekMouseUp,46,25);
    Check(Probe.Changes=7,'A non-primary press cannot arm switch activation');
    Mouse(gekMouseDown,46,25);
    Switch.Checked:=False;
    Mouse(gekMouseUp,46,25);
    Check(NOT Switch.Checked AND (Probe.Changes=8),'Programmatic switch change cancels a pending pointer toggle');
    Switch.Enabled:=False;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$4000004F;
    Switch.HandleEvent(E);
    Check(NOT Switch.Checked AND (Probe.Changes=8),'Disabled switch ignores direct input');
    Switch.Enabled:=True;
    Before:=Probe.Changes;
    Mouse(gekMouseDown,24,25);
    Mouse(gekMouseMove,46,25);
    Key(27);
    Mouse(gekMouseUp,46,25);
    Check(NOT Switch.Checked AND NOT Switch.Pressed AND (Probe.Changes=Before),
      'Escape cancels switch dragging without a release-time toggle');
    Mouse(gekMouseDown,24,25);
    Mouse(gekMouseMove,46,25);
    Mouse(gekMouseUp,24,25);
    Check(NOT Switch.Checked AND (Probe.Changes=Before),
      'Switch drag commits the final release coordinate rather than stale motion');
    Switch.Paint(Canvas);
    Check(Canvas.ClipDepth=0,'Switch rendering balances clipping');
    Busy.Ticks:=0;
    Check(Busy.Animate AND NOT Busy.CanFocus AND NOT Busy.TabStop AND (Busy.AnimationFrame=0),
      'Activity indicator defaults to animation without keyboard focus');
    Check(Busy.HitTest(GuiPoint(1,1))=nil,'Activity overlay does not intercept mouse input');
    Busy.Ticks:=79;
    Check(Busy.AnimationFrame=0,'Activity interval retains frame until its boundary');
    Busy.Ticks:=80;
    Check(Busy.AnimationFrame=1,'Activity frame advances at the configured interval');
    Busy.Ticks:=960;
    Check(Busy.AnimationFrame=0,'Activity animation wraps after twelve frames');
    Before:=Canvas.FillCount;
    Busy.Paint(Canvas);
    Check((Canvas.FillCount>Before) AND (Canvas.ClipDepth=0),'Activity renders clipped vector dots');
    Busy.Animate:=False;
    Before:=Canvas.FillCount;
    Busy.Paint(Canvas);
    Check(Canvas.FillCount=Before,'Stopped activity indicator paints no dots');
    Busy.Animate:=True;
    Busy.Enabled:=False;
    Busy.Ticks:=80;
    Check(Busy.AnimationFrame=0,'Disabled activity indicator is static');
    Busy.Enabled:=True;
    Busy.FrameInterval:=High(Cardinal);
    Busy.Ticks:=UInt64(High(Cardinal))-1;
    Check(Busy.AnimationFrame=0,'Maximum activity interval retains its first frame');
    Busy.Ticks:=High(Cardinal);
    Check(Busy.AnimationFrame=1,'Maximum activity interval advances without truncation');
    Busy.Enabled:=True;
    Busy.FrameInterval:=0;
    Busy.Ticks:=High(UInt64);
    Check((Busy.FrameInterval=1) AND (Busy.AnimationFrame>=0) AND (Busy.AnimationFrame<12),
      'Activity interval and long-running clock values stay valid');
    Busy.Bounds:=GuiRect(0,0,0,0);
    Before:=Canvas.FillCount;
    Busy.Paint(Canvas);
    Check(Canvas.FillCount=Before,'Zero-size activity indicator emits no drawing');
  finally
    Busy.Free;
    Canvas.Free;
    Context.Free;
    Probe.Free;
  end;
end;

procedure TTableProbe.ColumnClick(Sender: TGuiControl; AColumn: Integer);
begin
  Inc(FClicks);
end;

procedure TTableProbe.Selection(Sender: TGuiControl);
begin
  Inc(FSelections);
end;

procedure TTableProbe.Compare(Sender: TGuiControl; L, R: TStrings; AColumn: Integer; var AResult: Integer);
begin
  AResult:=-CompareText(L[0], R[0]);
end;

procedure TTestCanvas.FillRect(const ARect: TGuiRect; const AColor: TGuiColor);
begin
  Inc(FFillCount);
  LastFill:=ARect;
  LastColor:=AColor;
end;
procedure TTestCanvas.DrawBorder(const ARect: TGuiRect; AWidth: TGuiFloat; const AColor: TGuiColor);
begin
end;
procedure TTestCanvas.DrawImage(ATexture: TGuiTexture; const ARect: TGuiRect);
begin
  Inc(FImageCount);
end;
procedure TTestCanvas.DrawText(const AText: String; const ARect: TGuiRect; const AColor: TGuiColor;
  AHorizontal: TGuiHorizontalTextAlign; AVertical: TGuiVerticalTextAlign);
begin
  LastText:=AText;
  Inc(FTextDrawCount);
  LastTextRect:=ARect;
  if AText = 'Tail' then TailHeaderText:=ARect;
end;
function TTestCanvas.MeasureText(const AText: String): TGuiSize;
begin
  if MetricScale > 0 then Result:=GuiSize(Length(AText) * 8 * MetricScale, 16 * MetricScale)
  else Result:=GuiSize(Length(AText) * 8, 16);
end;
function TTestCanvas.TextMetricsKey: String;
begin
  Result:=FontName + ':' + FloatToStr(MetricScale);
end;
procedure TTestCanvas.PushClipRect(const ARect: TGuiRect);
begin
  if ClipDepth = 0 then FirstClip:=ARect;
  if ClipDepth = 1 then ContentClip:=ARect;
  Inc(FClipDepth);
end;
procedure TTestCanvas.PopClipRect;
begin
  Dec(FClipDepth);
end;

procedure TProbe.MenuClick(Sender: TObject);
begin
  Inc(FMenuClicks);
end;

procedure TProbe.HandleEvent(var AEvent: TGuiEvent);
begin
  if AEvent.Kind = gekKeyUp then Inc(FKeyUps);
  inherited HandleEvent(AEvent);
end;

procedure Key(AControl: TGuiControl; ACode: Integer; AModifiers: TGuiEventModifiers = []);
var
  Event: TGuiEvent;
begin
  Event:=Default(TGuiEvent);
  Event.Kind:=gekKeyDown;
  Event.KeyCode:=ACode;
  Event.Modifiers:=AModifiers;
  AControl.HandleEvent(Event);
end;

procedure Input(AControl: TGuiControl; const AText: UTF8String);
var
  Event: TGuiEvent;
begin
  Event:=Default(TGuiEvent);
  Event.Kind:=gekTextInput;
  Event.Text:=AText;
  AControl.HandleEvent(Event);
end;

procedure TestEditing;
var
  Edit: TGuiEdit;
  Memo: TGuiMemo;
  Canvas: TTestCanvas;
begin
  Canvas:=TTestCanvas.Create;
  Edit:=TGuiEdit.Create;
  Memo:=TGuiMemo.Create;
  try
    Input(Edit, 'abc');
    Edit.Undo;
    Check(Edit.Text = '', 'Undo first insertion');
    Edit.Redo;
    Check(Edit.Text = 'abc', 'Redo insertion');
    Edit.SetSelection(1, 3);
    Input(Edit, 'X');
    Check(Edit.Text = 'aX', 'Typing replaces selection');
    Edit.Undo;
    Check(Edit.Text = 'abc', 'Selection replacement is one undo operation');
    Input(Edit, 'Y');
    Edit.Redo;
    Check(Edit.Text <> 'aX', 'New edit discards redo branch');
    Edit.ReadOnly:=True;
    Edit.Text:='fixed';
    Key(Edit, 8);
    Input(Edit, 'x');
    Check(Edit.Text = 'fixed', 'Read-only blocks keyboard edits');
    Memo.Bounds:=GuiRect(0, 0, 120, 80);
    Input(Memo, 'one');
    Key(Memo, 13);
    Input(Memo, 'two');
    Check((Memo.Text = 'one' + #10 + 'two') AND (Memo.Lines.Count = 2), 'Memo newline and lines stay synchronized');
    Key(Memo, $40000052);
    Check(Memo.CaretIndex = 3, 'Memo up preserves column');
    Key(Memo, $4000004A);
    Check(Memo.CaretIndex = 0, 'Memo home moves to line start');
    Memo.SelectAll;
    Input(Memo, 'replacement');
    Memo.Undo;
    Check(Memo.Lines.Count = 2, 'Memo undo restores lines');
    Memo.Lines[0]:='changed';
    Check(Pos('changed', Memo.Text) = 1, 'External Lines changes update editor');
    Memo.Paint(Canvas);
    Memo.ClearLines;
    Memo.Paint(Canvas);
    Check(Memo.Text = '', 'Empty memo paints safely');
  finally
    Memo.Free;
    Edit.Free;
    Canvas.Free;
  end;
end;

procedure TComboStateProbe.Selected(Sender: TGuiControl);
begin
  Inc(FCalls);
  Order:=Order+'S';
  ClosedOnSelect:=NOT TGuiComboBox(Sender).DroppedDown;
  case Mode of
    1:
    begin
      Mode:=0;
      TGuiComboBox(Sender).SelectedIndex:=0;
    end;
    2: Sender.Free;
    3:
    begin
      Mode:=0;
      TGuiComboBox(Sender).Items.Clear;
    end;
  end;
end;

procedure TComboStateProbe.Accepted(Sender: TGuiControl);
begin
  Inc(FAccepts);
  Order:=Order+'A';
  Check(NOT TGuiComboBox(Sender).DroppedDown,'Combo acceptance callback observes closed popup');
  if Mode=4 then Sender.Free;
end;

procedure TComboStateProbe.ReplaceItems(Sender: TGuiControl; const Event: TGuiEvent);
begin
  TGuiComboBox(Sender).Items.Delete(0);
end;

function TTypeAheadCombo.SearchTime: UInt64;
begin
  Result:=Ticks;
end;

procedure TTabMutationProbe.DeleteFirst(Sender: TGuiControl; const Event: TGuiEvent);
begin
  TGuiTabControl(Sender).Items.Delete(0);
end;

procedure TTabMutationProbe.Disable(Sender: TGuiControl; const Event: TGuiEvent);
begin
  Sender.Enabled:=False;
end;

procedure TestTabLifetime;
var C: TGuiContext;
T: TGuiTabControl;
P: TButtonLifetimeEvents;
  E: TGuiEvent;
  Mode: Integer;
begin
  C:=TGuiContext.Create;
  P:=TButtonLifetimeEvents.Create;
  try
    C.Resize(300,200);
    P.Mode:=1;
    for Mode:=0 to 2 do
    begin
      T:=TGuiTabControl.Create;
      C.Root.Add(T);
      T.Bounds:=GuiRect(0,0,200,60);
      T.AddTab('First');
      T.AddTab('Second');
      C.SetFocus(T);
      P.Changes:=0;
      if Mode=2 then T.OnClick:=P.Changed else T.OnSelect:=P.Changed;
      E:=Default(TGuiEvent);
      if Mode=0 then
      begin
        E.Kind:=gekKeyDown;
        E.KeyCode:=$4000004F;
      end
      else
      begin
        E.Kind:=gekMouseDown;
        E.Button:=gmbLeft;
        E.Position:=GuiPoint(150,15);
      end;
      C.ProcessEvent(E);
      if Mode=2 then
      begin
        E:=Default(TGuiEvent);
        E.Kind:=gekMouseUp;
        E.Button:=gmbLeft;
        E.Position:=GuiPoint(150,15);
        C.ProcessEvent(E);
        end;
      Check((C.Root.ChildCount=0) AND (C.FocusedControl=nil) AND (P.Changes=1),
        'Tab selection/click callback may free sender during keyboard or pointer input');
      C.CancelInput;
    end;
  finally
    P.Free;
    C.Free;
  end;
end;

procedure TestTabFoundation;
var T: TGuiTabControl;
P: TControlEventProbe;
Mutation: TTabMutationProbe;
Canvas: TTestCanvas;
  E: TGuiEvent;
  A,B: TObject;
  Before: Integer;
  Rejected: Boolean;
  procedure Key(Code: Integer);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    T.HandleEvent(E);
  end;
  procedure Mouse(Button: TGuiMouseButton; X,Y: Single);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=Button;
    E.Position:=GuiPoint(X,Y);
    T.HandleEvent(E);
  end;
begin
  T:=TGuiTabControl.Create;
  P:=TControlEventProbe.Create;
  Mutation:=TTabMutationProbe.Create;
  Canvas:=TTestCanvas.Create;
  A:=TObject.Create;
  B:=TObject.Create;
  try
    T.Bounds:=GuiRect(0,0,300,100);
    T.OnSelect:=P.Changed;
    T.Items.AddObject('Duplicate',A);
    T.Items.AddObject('Duplicate',B);
    T.AddTab('Last');
    Check((T.SelectedIndex=0) AND (P.Changes=1),'Direct tab population selects first row once');
    T.SelectedIndex:=1;
    Before:=P.Changes;
    T.Items.Insert(0,'Before');
    Check((T.SelectedIndex=2) AND (T.Items.Objects[2]=B) AND (P.Changes=Before+1),'Tab insertion preserves selected duplicate row');
    T.Items.Delete(0);
    Check((T.SelectedIndex=1) AND (T.Items.Objects[1]=B),'Tab deletion before selection follows row identity');
    T.Items.Move(1,2);
    Check((T.SelectedIndex=2) AND (T.Items.Objects[2]=B),'Tab selection follows move');
    T.Items.Sort;
    Check(T.Items.Objects[T.SelectedIndex]=B,'Tab sort preserves selected duplicate and application object');
    Before:=P.Changes;
    T.Items[T.SelectedIndex]:='Renamed';
    Check(P.Changes=Before+1,'Selected tab rename notifies once');
    T.Items.Exchange(T.SelectedIndex,0);
    Check(T.SelectedIndex=0,'Tab selection follows exchange');
    Before:=P.Changes;
    T.Items.Delete(0);
    Check((T.SelectedIndex=0) AND (P.Changes=Before+1),'Deleting selected tab chooses replacement at same index and notifies');
    T.SelectedIndex:=-1;
    Before:=P.Changes;
    T.Items.Add('Extra');
    Check((T.SelectedIndex=-1) AND (P.Changes=Before),'Appending tabs preserves explicit deselection');
    T.Items.Clear;
    Check(T.SelectedIndex=-1,'Clearing tab list normalizes selection immediately');
    Before:=P.Changes;
    T.Items.BeginUpdate;
    try
      T.AddTab('A');
      T.AddTab('B');
      T.AddTab('C');
    finally
      T.Items.EndUpdate;
    end;
    Check((T.SelectedIndex=0) AND (P.Changes=Before+1),'Batched tab population notifies once');
    T.SelectedIndex:=2;
    T.Items.BeginUpdate;
    try
      T.Items.Delete(0);
      T.Items.Insert(0,'New');
    finally
      T.Items.EndUpdate;
    end;
    Check((T.SelectedIndex=2) AND (T.Items[2]='C'),'Batch tab changes preserve selected item');
    T.Items.Assign(T.Items);
    Check(T.SelectedIndex=2,'Tab self-assignment preserves selection');
    T.Items.Text:='First'+#10+'Second';
    Check(T.SelectedIndex=1,'Replacing tab items clamps old selection');
    Before:=P.Changes;
    Mouse(gmbRight,10,10);
    Check((T.SelectedIndex=1) AND (P.Changes=Before),'Secondary click cannot select tab');
    T.Enabled:=False;
    Mouse(gmbLeft,10,10);
    Key($40000050);
    Check((T.SelectedIndex=1) AND (P.Changes=Before),'Disabled tab ignores pointer and keyboard input');
    T.Pressed:=True;
    E:=Default(TGuiEvent);
    E.Kind:=gekCancel;
    T.HandleEvent(E);
    Check(NOT T.Pressed,'Disabled tab still clears press on cancellation');
    T.Enabled:=True;
    Key($4000004A);
    Key($40000050);
    Check(T.SelectedIndex=0,'Tab Home and Left clamp to first item');
    Key($4000004D);
    Key($4000004F);
    Check(T.SelectedIndex=1,'Tab End and Right clamp to last item');
    T.SelectedIndex:=1;
    T.Bounds:=GuiRect(0,0,300,16);
    Mouse(gmbLeft,10,25);
    Check(T.SelectedIndex=1,'Tab header cannot accept clicks below short control bounds');
    Mouse(gmbLeft,10,8);
    Check(T.SelectedIndex=0,'Short tab header remains clickable inside actual bounds');
    T.OnMouseDown:=Mutation.DeleteFirst;
    Mouse(gmbLeft,200,8);
    Check((T.Items.Count=1) AND (T.SelectedIndex=0),'Mouse callback mutation cancels stale tab hit');
    T.OnMouseDown:=nil;
    T.AddTab('Next');
    T.OnMouseDown:=Mutation.Disable;
    Before:=P.Changes;
    Mouse(gmbLeft,200,8);
    Check((T.SelectedIndex=0) AND NOT T.Pressed AND (P.Changes=Before),'Mouse callback disabling tab prevents selection and clears press');
    T.Enabled:=True;
    T.OnMouseDown:=nil;
    Rejected:=False;
    try
      T.TabHeight:=0;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (T.TabHeight=32),'Zero tab height rejected without mutation');
    Rejected:=False;
    try
      T.TabHeight:=NaN;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected,'Nonfinite tab height rejected');
    T.Paint(Canvas);
    Check(Canvas.ClipDepth=0,'Tab rendering restores clipping for short bounds');
  finally
    T.Free;
    P.Free;
    Mutation.Free;
    Canvas.Free;
    A.Free;
    B.Free;
  end;
end;

procedure TButtonLifetimeEvents.Changed(Sender: TGuiControl);
begin
  Inc(FChanges);
  case Mode of
    1: Sender.Free;
    2:
    begin
      Victim.Free;
      Victim:=nil;
    end;
    3: Sender.Enabled:=False;
  end;
end;

procedure TButtonLifetimeEvents.Clicked(Sender: TGuiControl);
begin
  Inc(FClicks);
end;

procedure TButtonLifetimeEvents.NextState(Sender: TGuiControl; var State: TGuiCheckBoxState);
begin
  Changed(Sender);
end;

procedure TestButtonCallbackLifetime;
var C: TGuiContext;
P: TButtonLifetimeEvents;
Box: TGuiCheckBox;
  Switch: TGuiToggleSwitch;
  Canvas: TTestCanvas;
  Radio,RadioPeer: TGuiRadioButton;
  Speed,SpeedPeer: TGuiSpeedButton;
  E: TGuiEvent;
  procedure Activate(Control: TGuiControl);
  begin
    C.SetFocus(Control);
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=32;
    C.ProcessEvent(E);
  end;
  procedure Reset;
  begin
    C.CancelInput;
    C.Root.Clear;
    P.Changes:=0;
    P.Clicks:=0;
    P.Mode:=1;
  end;
begin
  C:=TGuiContext.Create;
  P:=TButtonLifetimeEvents.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(400,200);
    Reset;
    Switch:=TGuiToggleSwitch.Create;
    C.Root.Add(Switch);
    Switch.OnChange:=P.Changed;
    Switch.OnClick:=P.Clicked;
    Activate(Switch);
    Check((C.Root.ChildCount=0) AND (P.Changes=1) AND (P.Clicks=0),
      'Switch OnChange may free sender without subsequent click');
    Reset;
    P.Mode:=3;
    Switch:=TGuiToggleSwitch.Create;
    C.Root.Add(Switch);
    Switch.OnChange:=P.Changed;
    Switch.OnClick:=P.Clicked;
    Activate(Switch);
    Check(Switch.Checked AND NOT Switch.Enabled AND (P.Changes=1) AND (P.Clicks=0),
      'Switch OnChange disabling sender prevents subsequent click');
    Reset;
    Switch:=TGuiToggleSwitch.Create;
    C.Root.Add(Switch);
    Switch.Bounds:=GuiRect(0,0,160,34);
    Switch.Caption:='Drag';
    Switch.OnChange:=P.Changed;
    Switch.OnClick:=P.Clicked;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(10,17);
    C.ProcessEvent(E);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseMove;
    E.Position:=GuiPoint(40,17);
    C.ProcessEvent(E);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseUp;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(40,17);
    C.ProcessEvent(E);
    Check((C.Root.ChildCount=0) AND (P.Changes=1) AND (P.Clicks=0),
      'Switch drag commit may free sender without a stale release click');
    Reset;
    Box:=TGuiCheckBox.Create;
    C.Root.Add(Box);
    Box.OnChange:=P.Changed;
    Box.OnClick:=P.Clicked;
    Activate(Box);
    Check((C.Root.ChildCount=0) AND (P.Changes=1) AND (P.Clicks=0),'Checkbox OnChange may free sender without subsequent click');
    Reset;
    Box:=TGuiCheckBox.Create;
    C.Root.Add(Box);
    Box.OnGetNextState:=P.NextState;
    Box.OnClick:=P.Clicked;
    Activate(Box);
    Check((C.Root.ChildCount=0) AND (P.Changes=1) AND (P.Clicks=0),'Checkbox next-state callback may free sender before state assignment');
    Reset;
    P.Mode:=3;
    Box:=TGuiCheckBox.Create;
    C.Root.Add(Box);
    Box.OnChange:=P.Changed;
    Box.OnClick:=P.Clicked;
    Activate(Box);
    Check(NOT Box.Enabled AND (P.Clicks=0),'Checkbox change callback disabling sender prevents click');
    Reset;
    Radio:=TGuiRadioButton.Create;
    C.Root.Add(Radio);
    Radio.OnChange:=P.Changed;
    Radio.OnClick:=P.Clicked;
    Activate(Radio);
    Check((C.Root.ChildCount=0) AND (P.Changes=1) AND (P.Clicks=0),'Radio OnChange may free sender without subsequent click');
    Reset;
    Speed:=TGuiSpeedButton.Create;
    C.Root.Add(Speed);
    Speed.Checkable:=True;
    Speed.OnChange:=P.Changed;
    Speed.OnClick:=P.Clicked;
    Activate(Speed);
    Check((C.Root.ChildCount=0) AND (P.Changes=1) AND (P.Clicks=0),'Speed button OnChange may free sender without subsequent click');
    Reset;
    RadioPeer:=TGuiRadioButton.Create;
    C.Root.Add(RadioPeer);
    RadioPeer.Checked:=True;
    Radio:=TGuiRadioButton.Create;
    C.Root.Add(Radio);
    Radio.OnClick:=P.Clicked;
    RadioPeer.OnChange:=P.Changed;
    Activate(Radio);
    Check((C.Root.ChildCount=1) AND Radio.Checked AND (P.Clicks=1),'Radio group tolerates peer removing itself during uncheck');
    Reset;
    P.Mode:=2;
    RadioPeer:=TGuiRadioButton.Create;
    C.Root.Add(RadioPeer);
    RadioPeer.Checked:=True;
    Radio:=TGuiRadioButton.Create;
    C.Root.Add(Radio);
    Radio.OnClick:=P.Clicked;
    P.Victim:=Radio;
    RadioPeer.OnChange:=P.Changed;
    Activate(Radio);
    Check((C.Root.ChildCount=1) AND (P.Victim=nil) AND (P.Clicks=0),'Radio peer callback can remove activating button without stale access');
    Reset;
    SpeedPeer:=TGuiSpeedButton.Create;
    SpeedPeer.GroupIndex:=1;
    C.Root.Add(SpeedPeer);
    SpeedPeer.Down:=True;
    Speed:=TGuiSpeedButton.Create;
    Speed.GroupIndex:=1;
    C.Root.Add(Speed);
    Speed.OnClick:=P.Clicked;
    SpeedPeer.OnChange:=P.Changed;
    Activate(Speed);
    Check((C.Root.ChildCount=1) AND Speed.Down AND (P.Clicks=1),'Speed group tolerates peer removing itself during uncheck');
    Reset;
    P.Mode:=2;
    SpeedPeer:=TGuiSpeedButton.Create;
    SpeedPeer.GroupIndex:=1;
    C.Root.Add(SpeedPeer);
    SpeedPeer.Down:=True;
    Speed:=TGuiSpeedButton.Create;
    Speed.GroupIndex:=1;
    C.Root.Add(Speed);
    Speed.OnClick:=P.Clicked;
    P.Victim:=Speed;
    SpeedPeer.OnChange:=P.Changed;
    Activate(Speed);
    Check((C.Root.ChildCount=1) AND (P.Victim=nil) AND (P.Clicks=0),'Speed peer callback can remove activating button without stale access');
    Reset;
    Speed:=TGuiSpeedButton.Create;
    C.Root.Add(Speed);
    Speed.Bounds:=GuiRect(0,0,100,40);
    Speed.Checkable:=True;
    Speed.AutoRepeat:=True;
    Speed.RepeatDelay:=0;
    Speed.OnChange:=P.Changed;
    Speed.OnClick:=P.Clicked;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(30,20);
    C.ProcessEvent(E);
    C.Paint(Canvas);
    Check((C.Root.ChildCount=0) AND (P.Changes=1) AND (P.Clicks=0),
      'Repeating speed button may be freed by OnChange before frame traversal');
    Check(Canvas.ClipDepth=0,'Derived button callback removal preserves safe frame traversal');
  finally
    C.Free;
    P.Free;
    Canvas.Free;
  end;
end;

function TButtonRepeatProbe.AnimationTime: UInt64;
begin
  Result:=Ticks;
end;

procedure TButtonRepeatEvents.Clicked(Sender: TGuiControl);
begin
  Inc(FCalls);
  if CancelOnClick then TGuiButton(Sender).AutoRepeat:=False;
  if FreeOnClick then Sender.Free;
end;

procedure TestButtonHold;
var C: TGuiContext;
B: TButtonRepeatProbe;
H: TButtonRepeatEvents;
P: TControlEventProbe;
  Canvas: TTestCanvas;
  E: TGuiEvent;
  Before: Integer;
  Rejected: Boolean;
  procedure Mouse(Kind: TGuiEventKind; X: Single=30);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,20);
    C.ProcessEvent(E);
  end;
  procedure Tick(Value: UInt64);
  begin
    B.Ticks:=Value;
    C.Paint(Canvas);
  end;
begin
  C:=TGuiContext.Create;
  H:=TButtonRepeatEvents.Create;
  P:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(300,200);
    B:=TButtonRepeatProbe.Create;
    C.Root.Add(B);
    B.Bounds:=GuiRect(0,0,100,40);
    B.OnClick:=P.Clicked;
    B.OnPressAndHold:=H.Clicked;
    Check(B.PressAndHoldInterval=800,'Ordinary button hold interval defaults to 800 ms');
    B.Ticks:=1000;
    Mouse(gekMouseDown);
    Tick(1799);
    Check(H.Calls=0,'Hold event waits for interval');
    Tick(1800);
    Tick(2500);
    Check(H.Calls=1,'Hold fires once at threshold without repeat');
    Mouse(gekMouseUp);
    Check(P.Clicks=0,'Recognized hold consumes ordinary release click');
    B.Ticks:=3000;
    Mouse(gekMouseDown);
    Tick(3100);
    Mouse(gekMouseUp);
    Check(P.Clicks=1,'Following short click is not suppressed by previous hold');
    B.Ticks:=3200;
    Mouse(gekMouseDown);
    B.Ticks:=4000;
    Mouse(gekMouseUp);
    Check((H.Calls=2) AND (P.Clicks=1),'Release at hold deadline is recognized even without an intervening frame');
    H.Calls:=1;
    B.Ticks:=4000;
    Mouse(gekMouseDown);
    Mouse(gekMouseMove,150);
    Tick(5000);
    Mouse(gekMouseUp,150);
    Check(H.Calls=1,'Pointer leave cancels pending hold');
    B.Ticks:=6000;
    Mouse(gekMouseDown);
    C.CancelInput;
    Tick(7000);
    Check(H.Calls=1,'Input cancellation prevents delayed hold event');
    B.Ticks:=8000;
    Mouse(gekMouseDown);
    B.Enabled:=False;
    Tick(9000);
    Check(H.Calls=1,'Disabled button cannot deliver hold event');
    B.Enabled:=True;
    C.CancelInput;
    B.Ticks:=10000;
    Mouse(gekMouseDown);
    Tick(9999);
    Tick(12000);
    Check(H.Calls=1,'Clock rollback cancels pending hold');
    C.CancelInput;
    B.AutoRepeat:=True;
    B.Ticks:=13000;
    Mouse(gekMouseDown);
    Tick(14000);
    Check(H.Calls=1,'Auto-repeat suppresses ordinary hold notification');
    Mouse(gekMouseUp);
    B.AutoRepeat:=False;
    C.SetFocus(B);
    B.Ticks:=15000;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=32;
    C.ProcessEvent(E);
    Tick(17000);
    Check(H.Calls=1,'Keyboard activation does not synthesize pointer hold');
    C.CancelInput;
    Rejected:=False;
    try
      B.PressAndHoldInterval:=0;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (B.PressAndHoldInterval=800),'Zero hold interval rejected without mutation');
    B.Ticks:=18000;
    Mouse(gekMouseDown);
    B.PressAndHoldInterval:=100;
    Tick(19000);
    Check(H.Calls=1,'Changing hold interval cancels pending gesture');
    C.CancelInput;
    B.Ticks:=20000;
    Mouse(gekMouseDown);
    Before:=P.Clicks;
    H.FreeOnClick:=True;
    Tick(20100);
    Check((C.Root.ChildCount=0) AND (H.Calls=2) AND (P.Clicks=Before),
      'Hold callback can free button before painting without clicking');
    C.Paint(Canvas);
    Check(Canvas.ClipDepth=0,'Removed held button leaves safe painting');
    B:=TButtonRepeatProbe.Create;
    C.Root.Add(B);
    B.Bounds:=GuiRect(0,0,100,40);
    B.OnPressAndHold:=H.Clicked;
    B.OnClick:=P.Clicked;
    B.Ticks:=30000;
    Mouse(gekMouseDown);
    B.Ticks:=30800;
    Mouse(gekMouseUp);
    Check((C.Root.ChildCount=0) AND (H.Calls=3) AND (P.Clicks=Before),
      'Release-time hold callback may free button without stale mouse-up dispatch');
  finally
    C.Free;
    H.Free;
    P.Free;
    Canvas.Free;
  end;
end;

procedure TestButtonRepeat;
var C: TGuiContext;
B: TButtonRepeatProbe;
P: TButtonRepeatEvents;
Canvas: TTestCanvas;
  E: TGuiEvent;
  Before: Integer;
  Rejected: Boolean;
  Delay: TGuiDelayButton;
  procedure Mouse(Kind: TGuiEventKind; X: Single=30; Button: TGuiMouseButton=gmbLeft);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=Button;
    E.Position:=GuiPoint(X,20);
    C.ProcessEvent(E);
  end;
  procedure Key(Kind: TGuiEventKind; Code: Integer; Repeated: Boolean=False);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.KeyCode:=Code;
    E.KeyRepeat:=Repeated;
    C.ProcessEvent(E);
  end;
  procedure Start;
  begin
    C.CancelInput;
    B.Enabled:=True;
    B.AutoRepeat:=True;
    B.Ticks:=1000;
    Mouse(gekMouseDown);
  end;
  procedure Tick(Value: UInt64);
  begin
    B.Ticks:=Value;
    C.Paint(Canvas);
  end;
begin
  C:=TGuiContext.Create;
  P:=TButtonRepeatEvents.Create;
  Canvas:=TTestCanvas.Create;
  try
    C.Resize(400,200);
    B:=TButtonRepeatProbe.Create;
    B.Bounds:=GuiRect(0,0,100,40);
    C.Root.Add(B);
    B.OnClick:=P.Clicked;
    Check(NOT B.AutoRepeat AND (B.RepeatDelay=300) AND (B.RepeatInterval=100),'Buttons default to no repeat with configurable delay and interval');
    Mouse(gekMouseDown);
    Tick(10000);
    Check(P.Calls=0,'Normal mouse hold does not activate before release');
    Mouse(gekMouseUp);
    Check(P.Calls=1,'Normal mouse release activates once');
    Key(gekKeyDown,32);
    Check(B.Pressed AND (P.Calls=2),'Keyboard activation shows pressed state and clicks once');
    Key(gekKeyDown,32,True);
    Check(P.Calls=2,'OS key-repeat does not repeat an ordinary button');
    Key(gekKeyUp,32);
    Check(NOT B.Pressed,'Keyboard release clears visual press');
    Before:=P.Calls;
    Start;
    Tick(1299);
    Check(P.Calls=Before,'Repeat waits for configured initial delay');
    Tick(1300);
    Check(P.Calls=Before+1,'Mouse hold repeats at exact delay');
    Tick(1300);
    Check(P.Calls=Before+1,'Captured and focused repeat runs once per timestamp');
    Tick(1399);
    Check(P.Calls=Before+1,'Repeat waits for interval');
    Tick(1400);
    Check(P.Calls=Before+2,'Repeat fires at exact interval');
    Mouse(gekMouseUp);
    Check(P.Calls=Before+3,'Repeat button retains final release click');
    Tick(2000);
    Check(P.Calls=Before+3,'Released button stops repeating');
    Start;
    Before:=P.Calls;
    Mouse(gekMouseMove,150);
    Tick(1500);
    Mouse(gekMouseUp,150);
    Check((P.Calls=Before) AND NOT B.Pressed,'Leaving button cancels hold and outside release does not click');
    Start;
    Before:=P.Calls;
    C.ClearFocus;
    Tick(1500);
    Check(P.Calls=Before,'Focus loss cancels repeat');
    Start;
    Before:=P.Calls;
    B.Enabled:=False;
    Tick(1500);
    Check((P.Calls=Before) AND NOT B.Pressed,'Disabling button cancels repeat before activation');
    Start;
    Before:=P.Calls;
    C.Root.Enabled:=False;
    Tick(1500);
    Check(P.Calls=Before,'Disabled ancestor cancels button repeat');
    C.Root.Enabled:=True;
    Start;
    Before:=P.Calls;
    B.Visible:=False;
    Tick(1500);
    Check(P.Calls=Before,'Hidden button cancels repeat');
    B.Visible:=True;
    Start;
    Before:=P.Calls;
    B.RepeatDelay:=400;
    Tick(1500);
    Check(P.Calls=Before,'Changing repeat delay cancels pending button activation');
    B.RepeatDelay:=300;
    Start;
    Before:=P.Calls;
    Tick(900);
    Tick(2000);
    Check(P.Calls=Before,'Clock rollback cancels repeat');
    Start;
    Before:=P.Calls;
    Tick(High(UInt64));
    Check(P.Calls=Before+1,'Long frame emits only one repeat without catch-up burst');
    C.CancelInput;
    B.Ticks:=1000;
    C.SetFocus(B);
    Before:=P.Calls;
    Key(gekKeyDown,13);
    Check(P.Calls=Before+1,'Repeat-enabled Enter activates immediately');
    Key(gekKeyDown,13,True);
    Tick(1300);
    Check(P.Calls=Before+2,'Keyboard hold uses configured timer rather than OS repeat');
    Key(gekKeyUp,32);
    Tick(1400);
    Check(P.Calls=Before+3,'Unrelated key release does not end Enter hold');
    Key(gekKeyUp,13);
    Tick(1600);
    Check(P.Calls=Before+3,'Matching key release ends repeat without second release activation');
    C.CancelInput;
    B.Ticks:=1000;
    C.SetFocus(B);
    Before:=P.Calls;
    Key(gekGamepadButtonDown,0);
    Check(P.Calls=Before+1,'Gamepad activation enters repeatable button hold');
    Tick(1300);
    Check(P.Calls=Before+2,'Gamepad hold repeats on timer');
    Key(gekGamepadButtonUp,0);
    Tick(1500);
    Check(P.Calls=Before+2,'Gamepad release ends repeat');
    Start;
    P.CancelOnClick:=True;
    Before:=P.Calls;
    Tick(1300);
    Tick(2000);
    Check(P.Calls=Before+1,'Repeat callback can disable repetition without later repeats');
    P.CancelOnClick:=False;
    Rejected:=False;
    try
      B.RepeatInterval:=0;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (B.RepeatInterval=100),'Zero repeat interval rejected without mutation');
    Delay:=TGuiDelayButton.Create;
    try
      Rejected:=False;
      try
        Delay.AutoRepeat:=True;
      except
        on EArgumentException do Rejected:=True;
      end;
      Check(Rejected AND NOT Delay.AutoRepeat,'Delay button rejects incompatible repeat mode');
    finally
      Delay.Free;
    end;
    Start;
    P.FreeOnClick:=True;
    Before:=P.Calls;
    Tick(1300);
    Check((P.Calls=Before+1) AND (C.Root.ChildCount=0) AND (C.FocusedControl=nil),'Repeat callback may free button before frame traversal');
    C.Paint(Canvas);
    Check(Canvas.ClipDepth=0,'Button removal leaves painting safe');
  finally
    C.Free;
    P.Free;
    Canvas.Free;
  end;
end;

function TTabMotionProbe.AnimationTime: UInt64;
begin
  Result:=Ticks;
end;

procedure TestTabMotion;
var Context: TGuiContext;
T: TTabMotionProbe;
P: TControlEventProbe;
Canvas: TTestCanvas;
  E: TGuiEvent;
  I,Before,Clicks: Integer;
  Offset: Single;
  Rejected: Boolean;
  procedure Mouse(Kind: TGuiEventKind; X: Single; Button: TGuiMouseButton=gmbLeft);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=Button;
    E.Position:=GuiPoint(X,16);
    Context.ProcessEvent(E);
  end;
  procedure Reset;
  begin
    Context.CancelInput;
    T.Enabled:=True;
    T.Visible:=True;
    T.Ticks:=1000;
    T.SelectedIndex:=0;
    T.ScrollOffset:=0;
    T.FlickEnabled:=True;
    T.DragScroll:=True;
  end;
  procedure Drag;
  begin
    Mouse(gekMouseDown,180);
    T.Ticks:=1050;
    Mouse(gekMouseMove,80);
  end;
begin
  Context:=TGuiContext.Create;
  P:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    Context.Resize(400,200);
    T:=TTabMotionProbe.Create;
    Context.Root.Add(T);
    T.Bounds:=GuiRect(0,0,300,40);
    T.TabWidth:=120;
    for I:=0 to 4 do T.AddTab(IntToStr(I));
    T.OnSelect:=P.Changed;
    T.OnClick:=P.Clicked;
    Reset;
    Mouse(gekMouseDown,160);
    Check(T.SelectedIndex=0,'Overflow press defers selection until click release');
    Mouse(gekMouseUp,160);
    Check((T.SelectedIndex=1) AND (P.Clicks=1),'Overflow click selects and clicks once on release');
    Reset;
    Before:=P.Changes;
    Clicks:=P.Clicks;
    Drag;
    Check(T.Moving AND (T.ScrollOffset=100) AND (T.SelectedIndex=0),'Drag scrolls header without selecting pressed tab');
    Mouse(gekMouseUp,80);
    T.Ticks:=1150;
    Context.Paint(Canvas);
    Check(T.Moving AND (Abs(T.ScrollOffset-287.5)<0.01),'Flick follows analytic deceleration after release');
    Check((P.Changes=Before) AND (P.Clicks=Clicks),'Drag and flick emit no selection or click callbacks');
    T.Ticks:=High(UInt64);
    Context.Paint(Canvas);
    Check(NOT T.Moving AND (T.ScrollOffset=T.MaxScrollOffset),'Large timestamp safely stops motion at strip boundary');
    Reset;
    Drag;
    T.Ticks:=1300;
    Mouse(gekMouseUp,80);
    Check(NOT T.Moving AND (T.ScrollOffset=100),'Pause before release suppresses stale flick velocity');
    Reset;
    T.FlickEnabled:=False;
    Drag;
    Mouse(gekMouseUp,80);
    Check(NOT T.Moving AND (T.ScrollOffset=100),'Flick can be disabled while preserving dragging');
    Reset;
    Drag;
    Context.CancelInput;
    Check(NOT T.Moving AND NOT T.Pressed,'Input cancellation clears drag and press');
    Offset:=T.ScrollOffset;
    T.Ticks:=2000;
    Context.Paint(Canvas);
    Check(T.ScrollOffset=Offset,'Cancelled drag cannot coast later');
    Reset;
    Drag;
    Mouse(gekMouseUp,80);
    T.Ticks:=900;
    Context.Paint(Canvas);
    Check(NOT T.Moving,'Clock rollback cancels flick');
    Reset;
    Drag;
    T.Items.Insert(0,'New');
    Check(NOT T.Moving,'Item mutations cancel stale drag geometry');
    T.Items.Delete(0);
    Reset;
    Drag;
    T.Bounds:=GuiRect(0,0,280,40);
    Context.Paint(Canvas);
    Check(NOT T.Moving,'Resize cancels tab drag');
    T.Bounds:=GuiRect(0,0,300,40);
    Reset;
    Drag;
    Mouse(gekMouseUp,80);
    T.Enabled:=False;
    Context.Paint(Canvas);
    Check(NOT T.Moving,'Disabled tabs stop coasting');
    Reset;
    Drag;
    Mouse(gekMouseUp,80);
    Context.ClearFocus;
    Check(NOT T.Moving,'Focus loss stops coasting');
    Reset;
    Drag;
    Mouse(gekMouseUp,80);
    T.Ticks:=1100;
    Context.Paint(Canvas);
    T.Ticks:=1150;
    Context.Paint(Canvas);
    Check(Abs(T.ScrollOffset-287.5)<0.01,'Coasting is independent of intermediate frame count');
    Mouse(gekMouseDown,80);
    Check(NOT T.Moving,'New pointer press stops existing coast before re-grabbing');
    Context.CancelInput;
    Reset;
    Drag;
    Mouse(gekMouseUp,80);
    Context.Root.Enabled:=False;
    Check(NOT T.Moving,'Disabled ancestor cancels tab motion');
    Context.Root.Enabled:=True;
    Reset;
    Drag;
    Mouse(gekMouseUp,80);
    T.Visible:=False;
    Check(NOT T.Moving,'Hidden tab reports cancelled motion');
    T.Visible:=True;
    Reset;
    Drag;
    Mouse(gekMouseUp,80);
    Key(T,$4000004D);
    Check(NOT T.Moving AND (T.SelectedIndex=4),'Keyboard navigation interrupts coast and reveals selection');
    Reset;
    Drag;
    T.ScrollOffset:=25;
    Check(NOT T.Moving AND (T.ScrollOffset=25),'Explicit scrolling cancels drag');
    Reset;
    Drag;
    T.SelectedIndex:=4;
    Check(NOT T.Moving AND (T.SelectedIndex=4),'Explicit selection cancels motion and reveals tab');
    Reset;
    T.TabEnabled[1]:=False;
    Drag;
    Mouse(gekMouseUp,80);
    Check((T.SelectedIndex=0) AND T.Moving,'Disabled tab can serve as drag surface without selection');
    T.TabEnabled[1]:=True;
    Reset;
    T.DragScroll:=False;
    Mouse(gekMouseDown,160);
    Check(T.SelectedIndex=1,'DragScroll opt-out retains immediate click selection');
    T.Ticks:=1050;
    Mouse(gekMouseMove,80);
    Check(NOT T.Moving,'DragScroll opt-out prevents drag motion');
    Mouse(gekMouseUp,80);
    Reset;
    Mouse(gekMouseDown,160,gmbRight);
    Mouse(gekMouseMove,80);
    Check(NOT T.Moving AND (T.SelectedIndex=0),'Secondary button cannot start tab drag');
    Rejected:=False;
    try
      T.Deceleration:=0;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (T.Deceleration=2500),'Nonpositive tab deceleration rejected');
    Check(Canvas.ClipDepth=0,'Motion rendering retains balanced clip stack');
  finally
    Context.Free;
    P.Free;
    Canvas.Free;
  end;
end;

procedure TestTabWidths;
var T,Other: TGuiTabControl;
Canvas: TTestCanvas;
Obj: TObject;
R: TGuiRect;
  E: TGuiEvent;
  I: Integer;
  Rejected: Boolean;
begin
  T:=TGuiTabControl.Create;
  Other:=TGuiTabControl.Create;
  Canvas:=TTestCanvas.Create;
  Obj:=TObject.Create;
  try
    T.Bounds:=GuiRect(0,0,300,40);
    T.AddTab('A');
    T.Items.AddObject('Medium',Obj);
    T.AddTab('LongLong');
    T.AutoSizeTabs:=True;
    T.Paint(Canvas);
    Check((T.TabRect(0).Width=32) AND (T.TabRect(1).Width=72) AND (T.ContentWidth=192),
      'Content-sized tabs use measured captions plus padding');
    Canvas.MetricScale:=2;
    T.Paint(Canvas);
    Check((T.TabRect(1).Width=120) AND (T.ContentWidth=312),'Metric changes rebuild natural widths and overflow');
    T.ItemWidths[1]:=77.5;
    T.Paint(Canvas);
    Check(T.TabRect(1).Width=77.5,'Explicit per-tab width overrides measured width with fractional precision');
    T.TabWidth:=90;
    T.Paint(Canvas);
    Check((T.TabRect(0).Width=90) AND (T.TabRect(1).Width=77.5),'Uniform width overrides autosizing except explicit rows');
    T.TabWidth:=0;
    T.AutoSizeTabs:=False;
    T.Paint(Canvas);
    Check((T.TabRect(0).Width=111.25) AND (T.TabRect(1).Width=77.5) AND (T.ContentWidth=300),
      'Flexible tabs divide space remaining after explicit rows');
    T.SelectedIndex:=0;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(120,10);
    T.HandleEvent(E);
    Check(T.SelectedIndex=1,'Mixed-width hit testing uses cumulative offsets');
    T.TabEnabled[1]:=False;
    T.Items.Insert(0,'Before');
    T.Items.Move(2,3);
    T.Items.Exchange(3,0);
    T.Items.Sort;
    I:=T.Items.IndexOfObject(Obj);
    Check((T.ItemWidths[I]=77.5) AND NOT T.TabEnabled[I],'Explicit width follows row identity independently of disabled state and Objects');
    T.Items.Assign(T.Items);
    Check(T.ItemWidths[I]=77.5,'Self-assignment retains explicit widths');
    Other.Items.Assign(T.Items);
    Check(Other.ItemWidths[I]=0,'Assignment creates new rows without importing private widths');
    T.Items.Delete(I);
    T.Items.Text:='Short'+#10+'Long caption';
    T.AutoSizeTabs:=True;
    Canvas.MetricScale:=1;
    T.Paint(Canvas);
    R:=T.TabRect(1);
    Check((R.Width=120) AND (T.ItemWidths[1]=0),'Replacement rows reset widths and remeasure captions');
    T.Items[1]:='X';
    T.Paint(Canvas);
    Check(T.TabRect(1).Width=32,'Caption changes invalidate measured widths');
    T.MinTabWidth:=80;
    Check(T.TabRect(1).Width=80,'Minimum width applies to natural tabs');
    T.ItemWidths[1]:=40;
    Check(T.TabRect(1).Width=80,'Minimum width also bounds explicit tabs');
    T.ItemWidths[1]:=0;
    Check(T.ItemWidths[1]=0,'Zero per-tab width restores inherited sizing');
    T.AutoSizeTabs:=False;
    T.MinTabWidth:=0;
    T.Items.Clear;
    for I:=0 to 6 do T.AddTab(IntToStr(I));
    T.Bounds:=GuiRect(0,0,100,32);
    Check(T.MaxScrollOffset=0,'Fractional equal widths do not create spurious overflow');
    T.SelectedIndex:=6;
    T.ItemWidths[0]:=200;
    R:=T.TabRect(6);
    Check(T.ScrollOffset<=T.MaxScrollOffset,'Changing width normalizes selected row scroll');
    Check(R.Width>0,'Flexible tabs remain visible when fixed tabs consume all available space');
    Check((R.Left>=T.HeaderViewport.Left) AND
      (R.Left+R.Width<=T.HeaderViewport.Left+T.HeaderViewport.Width),
      'Over-constrained selected tab is revealed inside scroll viewport');
    T.DragScroll:=False;
    T.SelectedIndex:=0;
    T.ScrollTabIntoView(6);
    R:=T.TabRect(6);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(R.Left+R.Width/2,R.Top+8);
    T.HandleEvent(E);
    Check(T.SelectedIndex=6,'Over-constrained flexible tab retains a working pointer target');
    T.ItemWidths[0]:=0;
    Check((T.MaxScrollOffset=0) AND (Abs(T.TabRect(6).Width-100/7)<0.01),
      'Removing fixed width restores equal-fit tabs without stale overflow');
    T.ItemWidths[0]:=200;
    Rejected:=False;
    try
      T.ItemWidths[0]:=NaN;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (T.ItemWidths[0]=200),'Nonfinite explicit width rejected without mutation');
    Rejected:=False;
    try
      T.ItemWidths[-1]:=20;
    except
      on EStringListError do Rejected:=True;
    end;
    Check(Rejected,'Invalid explicit width index raises list error');
    T.Items.Clear;
    T.AutoSizeTabs:=True;
    T.Paint(Canvas);
    Check((T.ContentWidth=0) AND (Canvas.ClipDepth=0),'Empty autosized tabs retain balanced rendering');
  finally
    T.Free;
    Other.Free;
    Canvas.Free;
    Obj.Free;
  end;
end;

procedure TestTabPosition;
var T: TGuiTabControl;
E: TGuiEvent;
R: TGuiRect;
Canvas: TTestCanvas;
Offset: Single;
  procedure Mouse(Kind: TGuiEventKind; X,Y: Single);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,Y);
    E.Delta:=GuiPoint(0,-1);
    T.HandleEvent(E);
  end;
begin
  T:=TGuiTabControl.Create;
  Canvas:=TTestCanvas.Create;
  try
    T.Bounds:=GuiRect(10,20,300,100);
    T.AddTab('A');
    T.AddTab('B');
    T.AddTab('C');
    Check(T.TabPosition=gtpTop,'Tabs default to top placement');
    T.Pressed:=True;
    T.TabPosition:=gtpBottom;
    R:=T.HeaderViewport;
    Check((R.Top=88) AND (R.Height=32) AND NOT T.Pressed,'Bottom position anchors header and clears stale press');
    Mouse(gekMouseDown,160,30);
    Check(T.SelectedIndex=0,'Bottom tab ignores pointer in top body');
    Mouse(gekMouseDown,160,100);
    Check(T.SelectedIndex=1,'Bottom tab hit testing uses footer geometry');
    T.MinTabWidth:=140;
    Offset:=T.ScrollOffset;
    Mouse(gekMouseWheel,160,30);
    Check(T.ScrollOffset=Offset,'Body wheel cannot scroll bottom header');
    Mouse(gekMouseWheel,160,100);
    Check(T.ScrollOffset>Offset,'Wheel scrolls bottom header');
    T.ScrollOffset:=0;
    Mouse(gekMouseDown,300,100);
    Check(T.ScrollOffset>0,'Bottom overflow arrow scrolls footer strip');
    Key(T,$4000004D);
    Check(T.SelectedIndex=2,'Bottom tabs retain keyboard navigation');
    T.TabHeight:=24;
    Check(T.HeaderViewport.Top=96,'Bottom header reanchors after height change');
    T.Bounds:=GuiRect(10,20,300,12);
    T.Paint(Canvas);
    R:=T.TabRect(2);
    Check((R.Top=20) AND (R.Height=12) AND (Canvas.ClipDepth=0),'Short bottom header stays in control bounds');
    T.TabPosition:=gtpTop;
    Check(T.HeaderViewport.Top=20,'Switching to top restores header origin');
    T.Bounds:=GuiRect(10,20,300,0);
    T.TabPosition:=gtpBottom;
    T.Paint(Canvas);
    Check((T.HeaderViewport.Height=0) AND (Canvas.ClipDepth=0),'Zero-height bottom tabs paint safely');
  finally
    T.Free;
    Canvas.Free;
  end;
end;

procedure TestTabOverflow;
var T: TGuiTabControl;
Canvas: TTestCanvas;
P: TControlEventProbe;
  E: TGuiEvent;
  R,V: TGuiRect;
  I,Before: Integer;
  Rejected: Boolean;
  Offset: Single;
  procedure Mouse(X,Y: Single; Kind: TGuiEventKind; Delta: Single=0);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,Y);
    E.Delta:=GuiPoint(0,Delta);
    T.HandleEvent(E);
  end;
  procedure CheckVisible(Index: Integer; const Message: String);
  begin
    R:=T.TabRect(Index);
    V:=T.HeaderViewport;
    Check((R.Left>=V.Left-0.01) AND (R.Left+R.Width<=V.Left+V.Width+0.01),Message);
  end;
begin
  T:=TGuiTabControl.Create;
  Canvas:=TTestCanvas.Create;
  P:=TControlEventProbe.Create;
  try
    T.Bounds:=GuiRect(0,0,300,100);
    T.OnSelect:=P.Changed;
    for I:=0 to 4 do T.AddTab('Tab '+IntToStr(I));
    R:=T.TabRect(0);
    Check((T.TabWidth=0) AND (T.MinTabWidth=0) AND (R.Width=60) AND (T.MaxScrollOffset=0),'Default tabs retain equal-width layout');
    T.MinTabWidth:=100;
    V:=T.HeaderViewport;
    Check((V.Left=24) AND (V.Width=252) AND (T.MaxScrollOffset=248),'Overflow reserves two bounded navigation buttons');
    Before:=P.Changes;
    Mouse(290,16,gekMouseDown);
    Check((T.ScrollOffset>0) AND (T.SelectedIndex=0) AND (P.Changes=Before),'Overflow arrow scrolls without selecting');
    Offset:=T.ScrollOffset;
    T.Paint(Canvas);
    Check((T.ScrollOffset=Offset) AND (Canvas.ClipDepth=0),'Painting preserves manual scrolling and balances clips');
    Mouse(100,16,gekMouseWheel,-1);
    Check(T.ScrollOffset>Offset,'Wheel scrolls overflowing header');
    Offset:=T.ScrollOffset;
    Mouse(100,80,gekMouseWheel,1);
    Check(T.ScrollOffset=Offset,'Body wheel does not scroll tab header');
    T.ScrollOffset:=0;
    T.SelectedIndex:=4;
    CheckVisible(4,'Programmatic selection reveals final tab');
    T.TabEnabled[3]:=False;
    Key(T,$40000050);
    Check(T.SelectedIndex=2,'Overflow navigation skips disabled tab');
    CheckVisible(2,'Keyboard-selected tab remains visible');
    Key(T,$4000004A);
    CheckVisible(0,'Home reveals first tab');
    Key(T,$4000004D);
    CheckVisible(4,'End reveals final tab');
    T.Bounds:=GuiRect(0,0,180,100);
    T.Paint(Canvas);
    CheckVisible(4,'Shrinking control reveals selected tab');
    T.ScrollTabIntoView(0);
    CheckVisible(0,'Explicit reveal can show unselected tab');
    Check(T.SelectedIndex=4,'Explicit scrolling does not change selection');
    T.ScrollOffset:=10000;
    Check(T.ScrollOffset=T.MaxScrollOffset,'Scroll offset clamps to end');
    T.ScrollOffset:=-20;
    Check(T.ScrollOffset=0,'Scroll offset clamps to start');
    T.Bounds:=GuiRect(0,0,800,100);
    T.Paint(Canvas);
    Check((T.MaxScrollOffset=0) AND (T.ScrollOffset=0) AND (T.HeaderViewport.Width=800),'Expansion removes overflow buttons and stale offset');
    T.MinTabWidth:=0;
    T.TabWidth:=100;
    R:=T.TabRect(4);
    Check((R.Left=400) AND (R.Width=100),'Fixed-width tabs do not stretch into spare space');
    T.SelectedIndex:=0;
    Mouse(750,16,gekMouseDown);
    Check(T.SelectedIndex=0,'Unused header space cannot select final tab');
    T.Bounds:=GuiRect(0,0,300,100);
    T.ScrollOffset:=100;
    Mouse(30,16,gekMouseDown);
    Mouse(30,16,gekMouseUp);
    Check(T.SelectedIndex=1,'Scrolled hit testing matches visible tab geometry');
    T.Enabled:=False;
    Offset:=T.ScrollOffset;
    Mouse(290,16,gekMouseDown);
    Mouse(100,16,gekMouseWheel,-1);
    Check(T.ScrollOffset=Offset,'Disabled control cannot scroll through pointer input');
    T.Enabled:=True;
    T.Bounds:=GuiRect(0,0,12,8);
    T.SelectedIndex:=4;
    T.Paint(Canvas);
    R:=T.TabRect(4);
    V:=T.HeaderViewport;
    Check((V.Width=4) AND (R.Left=V.Left) AND (Canvas.ClipDepth=0),'Tiny viewport anchors oversized selected tab and balances clipping');
    T.Bounds:=GuiRect(0,0,0,0);
    T.Paint(Canvas);
    Check(Canvas.ClipDepth=0,'Zero-sized overflowing header paints safely');
    T.Items.Clear;
    T.Paint(Canvas);
    Check((T.ScrollOffset=0) AND (T.MaxScrollOffset=0),'Clearing tabs clears overflow');
    Rejected:=False;
    try
      T.TabWidth:=-1;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (T.TabWidth=100),'Negative tab width rejected without mutation');
    Rejected:=False;
    try
      T.MinTabWidth:=NaN;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected,'Nonfinite minimum tab width rejected');
    Rejected:=False;
    try
      T.ScrollOffset:=Infinity;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected,'Nonfinite tab scroll offset rejected');
  finally
    T.Free;
    Canvas.Free;
    P.Free;
  end;
end;

procedure TestDisabledTabs;
var T: TGuiTabControl;
P: TControlEventProbe;
E: TGuiEvent;
  Before: Integer;
  Rejected: Boolean;
  Obj: TObject;
begin
  T:=TGuiTabControl.Create;
  P:=TControlEventProbe.Create;
  Obj:=TObject.Create;
  try
    T.Bounds:=GuiRect(0,0,400,32);
    T.OnSelect:=P.Changed;
    T.AddTab('A');
    T.Items.AddObject('B',Obj);
    T.AddTab('C');
    T.AddTab('D');
    Check(T.TabEnabled[0] AND T.TabEnabled[1],'New tabs default enabled');
    Before:=P.Changes;
    T.TabEnabled[1]:=False;
    T.TabEnabled[1]:=False;
    Check((T.SelectedIndex=0) AND (P.Changes=Before),'Disabling inactive tab does not notify selection');
    T.SelectedIndex:=1;
    Check(T.SelectedIndex=0,'Programmatic selection rejects disabled tab');
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(150,16);
    T.HandleEvent(E);
    Check((T.SelectedIndex=0) AND NOT T.Pressed AND E.Handled,'Disabled tab click is consumed without pressing');
    Key(T,$4000004F);
    Check(T.SelectedIndex=2,'Right skips disabled tab');
    Key(T,$40000050);
    Check(T.SelectedIndex=0,'Left skips disabled tab');
    T.TabEnabled[0]:=False;
    Check((T.SelectedIndex=2) AND (P.Changes=Before+3),'Disabling selected tab chooses next enabled and notifies once');
    T.TabEnabled[3]:=False;
    Key(T,$4000004D);
    Check(T.SelectedIndex=2,'End skips disabled trailing tab');
    Key(T,$4000004A);
    Check(T.SelectedIndex=2,'Home skips disabled leading tabs');
    Key(T,$40000050);
    Key(T,$4000004F);
    Check(T.SelectedIndex=2,'Arrows retain selection at enabled bounds');
    T.TabEnabled[2]:=False;
    Check(T.SelectedIndex=-1,'All disabled tabs clear selection');
    Key(T,$4000004A);
    Key(T,$4000004D);
    Key(T,$40000050);
    Key(T,$4000004F);
    Check(T.SelectedIndex=-1,'All disabled tabs ignore navigation safely');
    Before:=P.Changes;
    T.TabEnabled[2]:=True;
    Check((T.SelectedIndex=-1) AND (P.Changes=Before),'Re-enabling a tab preserves deselection');
    Key(T,$40000050);
    Check(T.SelectedIndex=2,'Navigation from no selection finds first enabled tab');
    T.TabEnabled[0]:=True;
    T.TabEnabled[2]:=False;
    Check(T.SelectedIndex=0,'Disabling last enabled candidate falls back to previous tab');
    T.Items.Insert(0,'Before');
    Check(NOT T.TabEnabled[2] AND (T.Items.Objects[2]=Obj),'Disabled state follows insertion');
    T.Items.Move(2,4);
    Check(NOT T.TabEnabled[4] AND (T.Items.Objects[4]=Obj),'Disabled state follows move');
    T.Items.Exchange(4,0);
    Check(NOT T.TabEnabled[0] AND (T.Items.Objects[0]=Obj),'Disabled state follows exchange');
    T.Items.Sort;
    Check(NOT T.TabEnabled[T.Items.IndexOfObject(Obj)],'Disabled state follows sorting');
    T.Items.Assign(T.Items);
    Check(NOT T.TabEnabled[T.Items.IndexOfObject(Obj)],'Self-assignment preserves disabled state');
    T.Items.BeginUpdate;
    try
      T.TabEnabled[T.SelectedIndex]:=False;
      T.Items.Delete(T.Items.IndexOf('Before'));
    finally
      T.Items.EndUpdate;
    end;
    Check(T.SelectedIndex=-1,'Batched mutations normalize selection after removing final enabled tab');
    T.Items.Text:='New'+#10+'Other';
    Check(T.TabEnabled[0] AND T.TabEnabled[1],'Replacement rows reset disabled flags');
    Rejected:=False;
    try
      T.TabEnabled[-1]:=False;
    except
      on EStringListError do Rejected:=True;
    end;
    Check(Rejected,'Invalid tab state index raises list error');
  finally
    T.Free;
    P.Free;
    Obj.Free;
  end;
end;

procedure TestComboTypeAhead;
var Context: TGuiContext;
C: TTypeAheadCombo;
P: TComboStateProbe;
E: TGuiEvent;
  Before: Integer;
  Rejected: Boolean;
  U: UnicodeString;
  Prefix: String;
  procedure Key(Code: Integer);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    Context.ProcessEvent(E);
  end;
  procedure Input(const AText: String);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekTextInput;
    E.Text:=UTF8String(AText);
    Context.ProcessEvent(E);
  end;
begin
  Context:=TGuiContext.Create;
  P:=TComboStateProbe.Create;
  try
    Context.Resize(400,240);
    C:=TTypeAheadCombo.Create;
    C.Bounds:=GuiRect(0,0,200,40);
    Context.Root.Add(C);
    C.Items.Text:='Alpha'+#10+'Alpine'+#10+'Beta'+#10+'Bravo'+#10+'Zulu';
    C.SelectedIndex:=2;
    C.OnSelect:=P.Selected;
    C.OnAccept:=P.Accepted;
    Context.SetFocus(C);
    Check(C.TypeAhead AND (C.TypeAheadTimeout=1000) AND NOT C.Editable,'Combo defaults to enabled noneditable type-ahead');
    C.Ticks:=100;
    Key(97);
    Input('a');
    Check((C.SelectedIndex=0) AND (C.Text='Alpha') AND (C.SearchPrefix='a') AND NOT C.Editing AND (P.Order='S'),
      'Noneditable text input searches without editing text or accepting');
    C.Ticks:=200;
    Key(108);
    Input('l');
    C.Ticks:=400;
    Key(112);
    Input('p');
    Check((C.SearchPrefix='alp') AND (C.SelectedIndex=0) AND (P.Calls=1),'Printable keydown does not reset accumulated type-ahead prefix');
    C.Ticks:=1400;
    Input('b');
    Check((C.SearchPrefix='b') AND (C.SelectedIndex=2),'Type-ahead timeout starts fresh at exact boundary');
    Input('b');
    Check(C.SelectedIndex=3,'Repeated letter cycles to next matching combo item');
    Input('b');
    Check(C.SelectedIndex=2,'Repeated letter wraps among matches');
    Input('z');
    Check((C.SelectedIndex=4) AND (C.SearchPrefix='z'),'Failed longer prefix falls back to new character');
    Before:=P.Calls;
    Input('q');
    Check((C.SelectedIndex=4) AND (P.Calls=Before),'Unmatched type-ahead does not notify or deselect');
    C.ClearSearch;
    Check(C.SearchPrefix='','ClearSearch explicitly resets incremental input');
    C.Ticks:=2000;
    Input('a');
    C.Ticks:=1999;
    Input('b');
    Check((C.SearchPrefix='b') AND (C.SelectedIndex=2),'Clock rollback starts fresh type-ahead search');
    C.Ticks:=High(UInt64);
    Input('z');
    Check(C.SelectedIndex=4,'Huge search timestamp does not overflow timeout calculation');
    C.SelectedIndex:=2;
    C.Ticks:=100;
    C.DroppedDown:=True;
    Before:=P.Calls;
    Input('a');
    Check((C.HighlightedIndex=0) AND (C.SelectedIndex=2) AND (P.Calls=Before),'Open popup type-ahead moves only highlighted preview');
    Key(13);
    Check((C.SelectedIndex=0) AND (P.Accepts=1),'Enter accepts type-ahead popup preview');
    C.DroppedDown:=True;
    Input('b');
    Key(27);
    Check((C.SelectedIndex=0) AND NOT C.DroppedDown AND (C.SearchPrefix=''),'Escape cancels type-ahead preview and prefix');
    Input('a');
    C.Items.Add('Later');
    Check(C.SearchPrefix='','Combo model mutation resets incremental search');
    Input('a');
    C.SelectedIndex:=2;
    Check(C.SearchPrefix='','Programmatic selection resets incremental search');
    Input('a');
    Context.ClearFocus;
    Check(C.SearchPrefix='','Focus loss clears type-ahead session');
    Context.SetFocus(C);
    Input('a');
    C.TypeAheadTimeout:=200;
    Check(C.SearchPrefix='','Changing search timing resets prefix');
    Rejected:=False;
    try
      C.TypeAheadTimeout:=0;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (C.TypeAheadTimeout=200),'Zero search timeout is rejected without mutation');
    C.TypeAhead:=False;
    Before:=P.Calls;
    Input('z');
    C.Search('z');
    Check((P.Calls=Before) AND (C.SearchPrefix=''),'Disabled type-ahead ignores routed and direct search');
    C.TypeAhead:=True;
    C.Enabled:=False;
    C.Search('z');
    Check(P.Calls=Before,'Disabled combo ignores direct search');
    C.Enabled:=True;
    C.SearchCaseSensitive:=True;
    C.ClearSearch;
    C.SelectedIndex:=2;
    Input('a');
    Check(C.SelectedIndex=2,'Type-ahead honors case-sensitive search setting');
    Input('A');
    Check(C.SelectedIndex=0,'Matching case finds combo prefix');
    C.Items.Add('New York');
    C.Items.Add('New Jersey');
    C.ClearSearch;
    Input('New');
    Key(32);
    Input(' ');
    Input('J');
    Check(NOT C.DroppedDown AND (C.SearchPrefix='New J') AND (C.Items[C.SelectedIndex]='New Jersey'),
      'Space extends active multiword type-ahead instead of toggling popup');
    C.Ticks:=C.Ticks+C.TypeAheadTimeout;
    Key(32);
    Check(C.DroppedDown,'Space opens popup after search timeout');
    C.DroppedDown:=False;
    U:=UnicodeString('e')+WideChar($0301); {$IFDEF FPC}Prefix:=UTF8Encode(U);{$ELSE}Prefix:=U;{$ENDIF}
    C.Items.Add(Prefix+'clair');
    C.ClearSearch;
    Input(Prefix);
    Check(C.SelectedIndex=C.Items.Count-1,'Type-ahead accepts Unicode committed text');
    C.ClearSearch;
    Before:=P.Calls;
    E:=Default(TGuiEvent);
    E.Kind:=gekTextEditing;
    E.Text:='Beta';
    Context.ProcessEvent(E);
    Key(13);
    Check((P.Calls=Before) AND (C.SearchPrefix=''),'Composition preview and Enter do not prematurely search or accept');
    Input('Beta');
    Check(C.SelectedIndex=2,'Committed composition performs noneditable search');
    C.Editable:=True;
    Before:=P.Calls;
    C.Search('Zulu');
    Check(P.Calls=Before,'Editable combos retain editor semantics instead of type-ahead');
    C.Editable:=False;
    P.Mode:=2;
    C.Search('Zulu');
    C:=nil;
    Check(Context.Root.ChildCount=0,'Type-ahead selection callback may remove combo safely');
  finally
    P.Free;
    Context.Free;
  end;
end;

procedure TestComboCompletion;
var Context: TGuiContext;
C: TGuiComboBox;
P: TControlEventProbe;
E: TGuiEvent;
  U: UnicodeString;
  Cluster: String;
  Before: Integer;
  procedure Input(const AText: String);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekTextInput;
    E.Text:=UTF8String(AText);
    Context.ProcessEvent(E);
  end;
  procedure Key(Code: Integer);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    Context.ProcessEvent(E);
  end;
begin
  Context:=TGuiContext.Create;
  P:=TControlEventProbe.Create;
  try
    Context.Resize(400,240);
    C:=TGuiComboBox.Create;
    C.Bounds:=GuiRect(0,0,200,40);
    Context.Root.Add(C);
    C.Items.Text:='Alpha'+#10+'Alpine'+#10+'Beta';
    C.SelectedIndex:=2;
    C.Editable:=True;
    Context.SetFocus(C);
    Check(NOT C.AutoComplete AND NOT C.SearchCaseSensitive,'Combo completion is opt-in with case-insensitive prefix lookup');
    Check((C.FindPrefix('al')=0) AND (C.FindPrefix('al',1)=1) AND (C.FindPrefix('al',2)=-1),
      'Combo prefix lookup supports a start index without implicit wrapping');
    Check((C.FindPrefix('')=-1) AND (C.FindPrefix('missing')=-1) AND (C.FindPrefix('al',100)=-1) AND (C.FindPrefix('al',-10)=0),
      'Combo prefix lookup handles empty, missing and out-of-range starts');
    C.SearchCaseSensitive:=True;
    Check((C.FindPrefix('al')=-1) AND (C.FindPrefix('Al')=0),'Case-sensitive combo prefix lookup is explicit');
    C.SearchCaseSensitive:=False;
    C.OnChange:=P.Changed;
    C.AutoComplete:=True;
    C.SelectAll;
    Before:=P.Changes;
    Input('a');
    Check((C.Text='Alpha') AND (C.SelectedText='lpha') AND (C.SelectedIndex=2) AND C.Editing AND (P.Changes=Before+1),
      'Combo insertion completes selected suffix as one draft change without selecting item');
    Input('l');
    Check((C.Text='Alpha') AND (C.SelectedText='pha'),'Typing replaces completion suffix and extends prefix');
    Key(8);
    Check((C.Text='Al') AND NOT C.HasSelection,'Backspace removes suggestion without immediately restoring it');
    Input('p');
    Check(C.SelectedText='ha','Completion resumes on next insertion');
    C.Undo;
    Check(C.Text='Al','Undo reverses typed prefix plus completion atomically');
    C.Redo;
    Check((C.Text='Alpha') AND (C.SelectedText='ha'),'Redo restores completion and suffix selection');
    Key(13);
    Check((C.SelectedIndex=0) AND NOT C.Editing,'Enter accepts completed item');
    C.Text:='al';
    C.CaretIndex:=2;
    Check(C.Text='al','Programmatic combo Text does not autocomplete');
    Check(C.CompleteText AND (C.Text='Alpha') AND (C.SelectedText='pha'),'Explicit CompleteText completes draft');
    C.Undo;
    Check(C.Text='al','Explicit completion is undoable');
    C.Text:='alpha';
    C.CaretIndex:=5;
    Check(C.CompleteText AND (C.Text='Alpha') AND NOT C.HasSelection,
      'Full case-insensitive match canonicalizes item spelling without phantom suffix');
    Check(NOT C.CompleteText,'Already completed exact label is unchanged');
    C.Text:='Al';
    C.CaretIndex:=1;
    Check(NOT C.CompleteText,'Middle-of-text caret prevents completion');
    C.SelectAll;
    Check(NOT C.CompleteText,'Explicit selection prevents completion');
    C.MaxLength:=2;
    C.Text:='a';
    C.CaretIndex:=1;
    Check(NOT C.CompleteText AND (C.Text='a'),'Completion respects editor maximum length');
    C.MaxLength:=0;
    C.SearchCaseSensitive:=True;
    C.SelectAll;
    Input('a');
    Check(C.Text='a','Case-sensitive completion leaves unmatched lowercase draft');
    C.SearchCaseSensitive:=False;
    C.Text:='';
    C.CaretIndex:=0;
    Check(NOT C.CompleteText,'Empty combo draft is not completed');
    C.Text:='No match';
    C.CaretIndex:=Length(C.Text);
    Check(NOT C.CompleteText,'Unknown combo draft remains custom text');
    C.Text:='al';
    C.CaretIndex:=2;
    C.Enabled:=False;
    Check(NOT C.CompleteText,'Disabled combo cannot complete');
    C.Enabled:=True;
    C.Editable:=False;
    Check(NOT C.CompleteText,'Noneditable combo cannot complete text');
    C.Editable:=True;
    C.SelectAll;
    E:=Default(TGuiEvent);
    E.Kind:=gekTextEditing;
    E.Text:='al';
    Before:=P.Changes;
    Context.ProcessEvent(E);
    Check((P.Changes=Before) AND NOT C.CompleteText,'Composition preview does not trigger completion');
    Input('al');
    Check((C.Text='Alpha') AND (C.SelectedText='pha'),'Committed composition may complete item label');
    GuiRegisterClipboardProvider(SpinClipboardText,nil);
    C.Items.Add('6789');
    C.SelectAll;
    C.PasteFromClipboard;
    Check((C.Text='6789') AND (C.SelectedText='89'),'Clipboard insertion can complete a combo prefix');
    U:=UnicodeString('e')+WideChar($0301);
    {$IFDEF FPC}
    Cluster:=UTF8Encode(U);
    {$ELSE}
    Cluster:=U;
    {$ENDIF}
    C.Items.Add(Cluster+'clair');
    C.SelectAll;
    Input('e');
    Check((C.Text='e') AND NOT C.HasSelection,'Completion refuses to split a grapheme between typed prefix and suffix');
    C.SelectAll;
    Input(Cluster);
    Check((C.Text=Cluster+'clair') AND (C.SelectedText='clair'),'Complete Unicode grapheme prefix can be completed safely');
    C.Items.Insert(0,'Bad'+#10+'label');
    C.Text:='Bad';
    C.CaretIndex:=3;
    Check(NOT C.CompleteText,'Single-line combo completion rejects multiline item text');
    C.AutoComplete:=False;
    C.SelectAll;
    Input('al');
    Check(C.Text='al','Disabling AutoComplete restores ordinary text insertion');
  finally
    GuiRegisterClipboardProvider(nil,nil);
    P.Free;
    Context.Free;
  end;
end;

procedure TestComboEditing;
var Context: TGuiContext;
C: TGuiComboBox;
P: TComboStateProbe;
TextProbe: TControlEventProbe;
  E: TGuiEvent;
  Canvas: TTestCanvas;
  Before: Integer;
  U: UnicodeString;
  Cluster: String;
  procedure Key(Code: Integer);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    Context.ProcessEvent(E);
  end;
  procedure Input(const AText: String);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekTextInput;
    E.Text:=UTF8String(AText);
    Context.ProcessEvent(E);
  end;
  procedure ReplaceText(const AText: String);
  begin
    C.SelectAll;
    Input(AText);
  end;
begin
  Context:=TGuiContext.Create;
  P:=TComboStateProbe.Create;
  TextProbe:=TControlEventProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    Context.Resize(400,240);
    C:=TGuiComboBox.Create;
    C.Bounds:=GuiRect(0,0,200,40);
    Context.Root.Add(C);
    C.AddItem('Alpha');
    C.AddItem('Beta');
    C.AddItem('Gamma');
    Context.SetFocus(C);
    Check(NOT C.Editable AND C.ReadOnly AND (C.Text='Alpha'),'Combo defaults to noneditable and exposes selected text');
    C.OnChange:=TextProbe.Changed;
    C.OnSelect:=P.Selected;
    C.OnAccept:=P.Accepted;
    Input('Ignored');
    Check((C.Text='Alpha') AND (TextProbe.Changes=0),'Noneditable combo ignores text input');
    C.Editable:=True;
    ReplaceText('Beta');
    Check(C.Editing AND (C.Text='Beta') AND (C.SelectedIndex=0) AND (P.Order='') AND (TextProbe.Changes=1),
      'Editable combo buffers typing separately from item selection');
    Key(13);
    Check((C.SelectedIndex=1) AND NOT C.Editing AND (P.Order='SA'),'Enter accepts exact existing combo text');
    Before:=TextProbe.Changes;
    P.Order:='';
    C.SelectedIndex:=2;
    Check((C.Text='Gamma') AND (TextProbe.Changes=Before) AND (P.Order='S'),'Selection synchronizes editor without edit-buffer notification');
    P.Order:='';
    ReplaceText('Custom value');
    Key(13);
    Check((C.SelectedIndex=-1) AND (C.Text='Custom value') AND (C.Items.Count=3) AND NOT C.Editing AND (P.Order='SA'),
      'Unmatched combo text is accepted without adding an item');
    P.Order:='';
    Key(13);
    Check(P.Order='A','Reaccepting custom combo text emits acceptance only');
    C.Items.Add('Suggestion');
    Check((C.Text='Custom value') AND (C.SelectedIndex=-1),'Adding combo choices preserves accepted unmatched text');
    C.Items.Delete(C.Items.Count-1);
    ReplaceText('Discard');
    Key(27);
    Check((C.Text='Custom value') AND NOT C.Editing,'Escape restores last accepted custom text');
    C.Text:='Beta';
    Check((C.SelectedIndex=-1) AND C.Editing,'Programmatic Text remains a buffer assignment');
    C.AcceptText;
    Check((C.SelectedIndex=1) AND (C.Text='Beta'),'Explicit text acceptance matches existing item');
    Check((C.FindText('Beta')=1) AND (C.FindText('beta')=-1) AND (C.FindText('Missing')=-1),'Combo FindText performs exact label lookup');
    ReplaceText('Pending');
    C.Items.Insert(0,'Before');
    Check((C.Text='Pending') AND (C.SelectedIndex=2) AND C.Editing,'Unrelated insertion preserves pending combo draft and selected row');
    C.Items[C.SelectedIndex]:='Renamed';
    Check((C.Text='Renamed') AND NOT C.Editing,'Selected item rename replaces stale combo draft');
    C.SelectedIndex:=1;
    ReplaceText('Draft');
    C.SelectedIndex:=1;
    Check((C.Text='Alpha') AND NOT C.Editing,'Explicit same-index selection restores combo label');
    ReplaceText('Undo me');
    C.Undo;
    Check(C.Text='Alpha','Combo inherits editor undo');
    C.Redo;
    Check(C.Text='Undo me','Combo inherits editor redo');
    C.CancelEdit;
    C.CaretIndex:=Length(C.Text);
    Key($4000004A);
    Check((C.CaretIndex=0) AND (C.SelectedIndex=1),'Editable closed combo Home moves caret, not selection');
    Key($4000004D);
    Check(C.CaretIndex=Length(C.Text),'Editable closed combo End moves caret');
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(20,20);
    Context.ProcessEvent(E);
    Check(NOT C.DroppedDown,'Clicking editable combo text does not open popup');
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseMove;
    E.Position:=GuiPoint(50,20);
    Context.ProcessEvent(E);
    E.Kind:=gekMouseUp;
    E.Button:=gmbLeft;
    E.Handled:=False;
    Context.ProcessEvent(E);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(190,20);
    Context.ProcessEvent(E);
    Check(C.DroppedDown,'Clicking editable combo arrow opens popup');
    E.Kind:=gekMouseUp;
    E.Handled:=False;
    Context.ProcessEvent(E);
    Key(27);
    ReplaceText('Draft');
    Context.ClearFocus;
    Check(C.Editing AND (C.Text='Draft'),'Focus loss preserves unaccepted combo text without auto-insertion');
    Context.SetFocus(C);
    E:=Default(TGuiEvent);
    E.Kind:=gekTextEditing;
    E.Text:='Compose';
    Context.ProcessEvent(E);
    Before:=P.Accepts;
    Key(13);
    Check((P.Accepts=Before) AND (C.CompositionText='Compose'),'Composition Enter does not prematurely accept combo');
    Key(27);
    Check((C.Text='Draft') AND (C.CompositionText=''),'Composition Escape preserves combo draft');
    Key(27);
    Check(C.Text='Alpha','Second Escape restores accepted combo label');
    C.Text:='123456789012345678901234567890';
    C.CaretIndex:=Length(C.Text);
    C.PrepareTextLayout(Canvas);
    Check(C.TextInputRect(Canvas).Left+C.TextInputRect(Canvas).Width<=170,'Combo native text caret stays outside arrow lane');
    Check((C.MouseCursorAt(GuiPoint(20,20))=gmcText) AND (C.MouseCursorAt(GuiPoint(190,20))=gmcArrow),
      'Editable combo uses text cursor only in editor lane');
    GuiRegisterClipboardProvider(SpinClipboardText,nil);
    C.SelectAll;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=86;
    E.Modifiers:=[gemCtrl];
    Context.ProcessEvent(E);
    Check((C.Text='67') AND C.Editing,'Editable combo routes Ctrl+V through shared clipboard editor');
    U:=UnicodeString('e')+WideChar($0301);
    {$IFDEF FPC}
    Cluster:=UTF8Encode(U);
    {$ELSE}
    Cluster:=U;
    {$ENDIF}
    ReplaceText(Cluster+'x');
    C.CaretIndex:=0;
    Key($4000004F);
    Check(C.CaretIndex=Length(Cluster),'Editable combo caret crosses complete Unicode grapheme');
    Key(8);
    Check(C.Text='x','Editable combo deletion preserves Unicode grapheme boundaries');
    C.Editable:=False;
    Check((C.Text='Alpha') AND C.ReadOnly AND NOT C.Editing,'Disabling editing restores selection and read-only mode');
    C.Items.Clear;
    C.Editable:=True;
    ReplaceText('New draft');
    C.AddItem('First suggestion');
    Check((C.Text='New draft') AND (C.SelectedIndex=-1) AND C.Editing,'Populating empty editable combo preserves pending draft');
  finally
    GuiRegisterClipboardProvider(nil,nil);
    Canvas.Free;
    TextProbe.Free;
    P.Free;
    Context.Free;
  end;
end;

procedure TestComboKeyboard;
var Context: TGuiContext;
C: TGuiComboBox;
P: TComboStateProbe;
Canvas: TTestCanvas;
  E: TGuiEvent;
  procedure Key(Code: Integer; RepeatKey: Boolean = False);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    E.KeyRepeat:=RepeatKey;
    Context.ProcessEvent(E);
  end;
  procedure ResetProbe;
  begin
    P.Calls:=0;
    P.Accepts:=0;
    P.Order:='';
  end;
  procedure NewCombo;
  var I: Integer;
  begin
    C:=TGuiComboBox.Create;
    C.Bounds:=GuiRect(0,0,200,30);
    Context.Root.Add(C);
    for I:=0 to 9 do C.AddItem(IntToStr(I));
    C.DropDownCount:=3;
    C.OnSelect:=P.Selected;
    C.OnAccept:=P.Accepted;
    Context.SetFocus(C);
  end;
begin
  Context:=TGuiContext.Create;
  P:=TComboStateProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    Context.Resize(300,200);
    NewCombo;
    Key(32);
    Check(C.DroppedDown AND (C.HighlightedIndex=0),'Space opens combo with current item highlighted');
    Key(32,True);
    Check(C.DroppedDown AND (P.Accepts=0),'Repeated opening key cannot immediately accept combo');
    Key($40000051);
    Key($40000051);
    Check((C.HighlightedIndex=2) AND (C.SelectedIndex=0) AND (P.Calls=0),'Open combo arrows preview without committing selection');
    Context.Paint(Canvas);
    Check(C.HighlightedIndex=2,'Popup paint preserves keyboard highlight');
    Key(27);
    Check(NOT C.DroppedDown AND (C.SelectedIndex=0) AND (P.Order=''),'Escape cancels preview without events');
    Key(13);
    Key($4000004E);
    Check(C.HighlightedIndex=3,'PageDown advances by actual popup rows');
    Key($4000004D);
    Check(C.HighlightedIndex=9,'Open combo End highlights last row');
    Key($40000051);
    Check(C.HighlightedIndex=9,'Open combo highlight clamps at last row');
    Key($4000004B);
    Check(C.HighlightedIndex=6,'PageUp moves highlighted row by popup capacity');
    Key(13);
    Check((C.SelectedIndex=6) AND (P.Order='SA'),'Enter commits preview then emits acceptance once');
    ResetProbe;
    Key(13);
    Key(13);
    Check(P.Order='A','Accepting current combo item emits acceptance without selection change');
    ResetProbe;
    Key($40000052);
    Check((C.SelectedIndex=5) AND (P.Order='S'),'Closed combo arrows retain immediate selection semantics');
    ResetProbe;
    C.SelectedIndex:=3;
    Check(P.Order='S','Programmatic combo selection does not imply acceptance');
    ResetProbe;
    Key($4000003D);
    Key($40000051);
    Key($4000003D,True);
    Check(C.DroppedDown AND (C.HighlightedIndex=4),'F4 opens and ignores OS repeat');
    Key($4000003D);
    Check(NOT C.DroppedDown AND (C.SelectedIndex=3) AND (P.Order=''),'F4 closes without accepting preview');
    Key(13);
    Key($4000004D);
    Context.ClearFocus;
    Check(NOT C.DroppedDown AND (C.SelectedIndex=3) AND (P.Order=''),'Focus loss cancels combo preview');
    Context.SetFocus(C);
    Key(13);
    Key($4000004D);
    C.SelectedIndex:=1;
    Check(C.HighlightedIndex=1,'Programmatic selection replaces open keyboard preview');
    ResetProbe;
    C.Items.Delete(1);
    Check(C.HighlightedIndex=C.SelectedIndex,'Item mutation discards stale keyboard preview');
    C.DroppedDown:=False;
    C.SelectedIndex:=0;
    ResetProbe;
    Key(13);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseMove;
    E.Position:=GuiPoint(10,105);
    Context.ProcessEvent(E);
    Check(C.HighlightedIndex=2,'Pointer hover sets combo acceptance highlight');
    Key(13);
    Check((C.SelectedIndex=2) AND (P.Order='SA'),'Enter accepts pointer-highlighted row');
    ResetProbe;
    Key(13);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseWheel;
    E.Position:=GuiPoint(10,50);
    E.Delta:=GuiPoint(E.Delta.X, -2);
    Context.ProcessEvent(E);
    Key(13);
    Check(NOT C.DroppedDown AND (P.Order=''),'Scrolling clears stale highlight and Enter closes without hidden acceptance');
    C.SelectedIndex:=-1;
    ResetProbe;
    Key(13);
    Key($40000051);
    Key(13);
    Check((C.SelectedIndex=0) AND (P.Order='SA'),'Unselected combo can keyboard-highlight and accept first row');
    C.DroppedDown:=True;
    E:=Default(TGuiEvent);
    E.Kind:=gekCancel;
    Context.ProcessEvent(E);
    ResetProbe;
    C.Enabled:=False;
    C.AcceptSelection;
    Check(P.Order='','Disabled combo ignores explicit acceptance');
    C.Enabled:=True;
    C.DroppedDown:=False;
    C.SelectedIndex:=0;
    ResetProbe;
    Key(13);
    Key($40000051);
    P.Mode:=1;
    Key(13);
    Check((C.SelectedIndex=0) AND (P.Order='SS'),'Callback replacement suppresses stale combo acceptance');
    ResetProbe;
    Key(13);
    Key($40000051);
    P.Mode:=3;
    Key(13);
    Check((C.Items.Count=0) AND (P.Accepts=0),'Callback item replacement suppresses stale acceptance');
    C.Free;
    NewCombo;
    ResetProbe;
    Key(13);
    Key($40000051);
    P.Mode:=2;
    Key(13);
    C:=nil;
    Check((Context.Root.ChildCount=0) AND (P.Order='S'),'Selection callback can remove combo before acceptance');
    P.Mode:=0;
    NewCombo;
    ResetProbe;
    P.Mode:=4;
    C.AcceptSelection;
    C:=nil;
    Check((Context.Root.ChildCount=0) AND (P.Order='A'),'Acceptance callback can remove combo safely');
    P.Mode:=0;
    NewCombo;
    ResetProbe;
    C.DroppedDown:=True;
    P.Mode:=2;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(10,75);
    Context.ProcessEvent(E);
    C:=nil;
    Check((Context.Root.ChildCount=0) AND (P.Order='S'),
      'Pointer popup selection may free combo without a stale acceptance event');
    P.Mode:=0;
    NewCombo;
    ResetProbe;
    C.Editable:=True;
    C.Text:='Custom';
    P.Mode:=4;
    Key(13);
    C:=nil;
    Check((Context.Root.ChildCount=0) AND (P.Order='SA'),
      'Editable custom-text acceptance may free combo after selection notification');
  finally
    Canvas.Free;
    P.Free;
    Context.Free;
  end;
end;

procedure TestComboLayout;
var Context: TGuiContext;
C: TGuiComboBox;
R: TGuiRect;
E: TGuiEvent;
  Canvas: TTestCanvas;
  I: Integer;
  Rejected: Boolean;
begin
  Context:=TGuiContext.Create;
  Canvas:=TTestCanvas.Create;
  try
    Context.Resize(400,200);
    C:=TGuiComboBox.Create;
    C.Bounds:=GuiRect(350,150,100,30);
    Context.Root.Add(C);
    for I:=0 to 19 do C.AddItem(IntToStr(I));
    R:=C.PopupBounds;
    Check((C.DropDownCount=6) AND (C.VisibleItemCount=5) AND (R.Left=300) AND (R.Top=0) AND (R.Height=150),
      'Combo flips above bottom anchor and clamps popup to right viewport edge');
    C.Bounds:=GuiRect(-20,5,120,30);
    R:=C.PopupBounds;
    Check((R.Left=0) AND (R.Top=35) AND (R.Height=150),'Combo uses complete rows below and clamps left edge');
    C.DropDownCount:=3;
    R:=C.PopupBounds;
    Check((C.VisibleItemCount=3) AND (R.Height=90),'Combo exposes configurable maximum popup row count');
    C.ItemHeight:=20;
    C.DropDownCount:=8;
    R:=C.PopupBounds;
    Check((C.VisibleItemCount=8) AND (R.Height=160),'Combo row height and maximum count share layout');
    C.Bounds:=GuiRect(0,100,500,30);
    C.ItemHeight:=30;
    C.DropDownCount:=6;
    R:=C.PopupBounds;
    Check((R.Width=400) AND (R.Top=10) AND (R.Height=90),'Oversized combo popup narrows to viewport and uses roomier side');
    C.SelectedIndex:=19;
    C.DroppedDown:=True;
    Context.Paint(Canvas);
    Context.Resize(400,100);
    C.Bounds:=GuiRect(0,70,200,30);
    Context.Paint(Canvas);
    R:=C.PopupBounds;
    Check((C.VisibleItemCount=2) AND (R.Top=10) AND (R.Height=60),'Resize reduces visible combo rows');
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(10,55);
    C.HandleEvent(E);
    Check((C.SelectedIndex=19) AND NOT C.DroppedDown,'Resized popup keeps selected last row visible and hittable');
    C.SelectedIndex:=0;
    C.DroppedDown:=True;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseWheel;
    E.Delta:=GuiPoint(E.Delta.X, -100);
    C.HandleEvent(E);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(10,55);
    C.HandleEvent(E);
    Check(C.SelectedIndex=19,'Constrained popup scrolls through all items using actual visible rows');
    Context.Resize(400,40);
    C.Bounds:=GuiRect(0,10,200,20);
    C.DroppedDown:=True;
    R:=C.PopupBounds;
    Check((R.Top=30) AND (R.Height=10) AND (C.VisibleItemCount=1),'Tiny viewport offers a clipped row when no complete row fits');
    Context.Resize(400,30);
    C.Bounds:=GuiRect(0,0,400,30);
    R:=C.PopupBounds;
    Check((R.Top=0) AND (R.Height=30),'Viewport-filling anchor still permits a usable popup');
    Context.Resize(0,0);
    C.PaintOverlay(Canvas);
    Check(NOT C.DroppedDown AND (C.VisibleItemCount=0),'Zero-height viewport closes combo popup');
    Context.Resize(0,100);
    C.DroppedDown:=True;
    Check(NOT C.DroppedDown AND (C.VisibleItemCount=0),'Zero-width viewport cannot open invisible combo popup');
    Rejected:=False;
    try
      C.DropDownCount:=0;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (C.DropDownCount=6),'Invalid combo dropdown count rejected without mutation');
    Context.Resize(400,100);
    C.Bounds:=GuiRect(0,0,200,20);
    C.ItemHeight:=23.7;
    Check(C.VisibleItemCount=3,'Fractional row heights do not invent an extra popup row from rounding');
    Context.Resize(400,200);
    C.Bounds:=GuiRect(0,0,200,30);
    C.ItemHeight:=20;
    C.DropDownCount:=3;
    C.SelectedIndex:=0;
    C.DroppedDown:=True;
    C.PaintOverlay(Canvas);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(Canvas.LastFill.Left+Canvas.LastFill.Width/2,Canvas.LastFill.Top+Canvas.LastFill.Height/2);
    C.HandleEvent(E);
    C.Bounds:=GuiRect(0,100,200,30);
    E.Kind:=gekMouseMove;
    E.Handled:=False;
    E.Position:=GuiPoint(E.Position.X, E.Position.Y + 80);
    C.HandleEvent(E);
    C.PaintOverlay(Canvas);
    Check(Abs(Canvas.LastFill.Top-C.PopupBounds.Top-4)<0.001,'Moving popup cancels thumb drag even when visible row count is unchanged');
    Context.Resize(400,200);
    C.ItemHeight:=0.0001;
    C.DropDownCount:=2;
    Check(C.PopupBounds.Height>0,'Tiny row height does not overflow viewport row-count arithmetic');
    Check(Canvas.ClipDepth=0,'Adaptive combo popup restores clipping after rendering');
  finally
    Canvas.Free;
    Context.Free;
  end;
end;

procedure TestComboState;
var C: TGuiComboBox;
P: TComboStateProbe;
E: TGuiEvent;
I,Before: Integer;
  A,B: TObject;
  Other: TGuiStateStrings;
  Canvas: TTestCanvas;
  Rejected: Boolean;
  procedure Key(Code: Integer);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    C.HandleEvent(E);
  end;
  procedure Mouse(Button: TGuiMouseButton; Y: Single);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=Button;
    E.Position:=GuiPoint(10,Y);
    C.HandleEvent(E);
  end;
begin
  C:=TGuiComboBox.Create;
  P:=TComboStateProbe.Create;
  Canvas:=TTestCanvas.Create;
  A:=TObject.Create;
  B:=TObject.Create;
  Other:=TGuiStateStrings.Create;
  try
    C.Bounds:=GuiRect(0,0,200,30);
    C.OnSelect:=P.Selected;
    C.DroppedDown:=True;
    Check(NOT C.DroppedDown,'Empty combo cannot open popup');
    C.Items.AddObject('Same',A);
    C.Items.AddObject('Same',B);
    C.Items.Add('Last');
    Check((C.SelectedIndex=0) AND (P.Calls=1),'Direct combo Items.Add selects first item once');
    C.SelectedIndex:=1;
    Before:=P.Calls;
    C.Items.Insert(0,'Before');
    Check((C.SelectedIndex=2) AND (C.Items.Objects[C.SelectedIndex]=B) AND (P.Calls=Before+1),'Combo insert preserves selected duplicate row identity');
    C.Items.Delete(0);
    Check((C.SelectedIndex=1) AND (C.Items.Objects[1]=B),'Combo delete before selection follows same item');
    C.Items.Move(1,2);
    Check((C.SelectedIndex=2) AND (C.Items.Objects[2]=B),'Combo selection follows moved row');
    C.Items.Sort;
    Check(C.Items.Objects[C.SelectedIndex]=B,'Combo sort preserves selected duplicate and application object');
    Before:=P.Calls;
    C.Items[C.SelectedIndex]:='Renamed';
    Check((C.Items.Objects[C.SelectedIndex]=B) AND (P.Calls=Before+1),'Selected combo rename notifies without losing identity');
    Before:=P.Calls;
    I:=C.SelectedIndex;
    C.Items.Delete(I);
    Check((C.SelectedIndex=Min(I,C.Items.Count-1)) AND (P.Calls=Before+1),'Deleting selected combo row selects nearest replacement and notifies');
    C.SelectedIndex:=-1;
    Before:=P.Calls;
    C.Items.Add('New');
    Check((C.SelectedIndex=-1) AND (P.Calls=Before),'Appending to nonempty combo preserves explicit no selection');
    C.SelectedIndex:=0;
    C.Items.Exchange(0,C.Items.Count-1);
    Check(C.SelectedIndex=C.Items.Count-1,'Combo selection follows exchange');
    C.DroppedDown:=True;
    C.Items.Clear;
    Check((C.SelectedIndex=-1) AND NOT C.DroppedDown,'Clearing combo resets selection and closes popup');
    C.Items.BeginUpdate;
    try
      C.Items.Add('Z');
      C.Items.Add('A');
      C.Items.Add('M');
    finally
      C.Items.EndUpdate;
    end;
    Check(C.SelectedIndex=0,'Batch-populated empty combo selects first row');
    C.SelectedIndex:=2;
    Before:=P.Calls;
    C.Items.BeginUpdate;
    try
      C.Items.Delete(0);
      C.Items.Insert(0,'B');
      C.Items.Sort;
    finally
      C.Items.EndUpdate;
    end;
    Check((C.Items[C.SelectedIndex]='M') AND (P.Calls=Before),'Batched mutation preserves selected row and avoids redundant index event');
    Other.Add('one');
    Other.Add('two');
    Other.ItemState[0]:=1;
    Other.ItemState[1]:=1;
    C.Items.Assign(Other);
    Check(C.SelectedIndex=1,'Combo assignment does not import another state list selection markers');
    C.Items.Delete(0);
    Check(C.SelectedIndex=0,'Assigned combo rows retain a single selection marker');
    C.Items.Assign(C.Items);
    Check(C.SelectedIndex=0,'Self-assignment preserves combo selection');
    C.DroppedDown:=False;
    Mouse(gmbRight,10);
    Check(NOT C.DroppedDown,'Right click cannot open combo');
    C.DroppedDown:=True;
    Before:=P.Calls;
    Mouse(gmbRight,45);
    Check(C.DroppedDown AND (P.Calls=Before),'Right click cannot select or close combo popup');
    C.Enabled:=False;
    Key($40000051);
    Mouse(gmbLeft,10);
    Check(NOT C.DroppedDown AND (P.Calls=Before),'Disabled direct combo input is ignored and popup closes');
    C.DroppedDown:=True;
    Check(NOT C.DroppedDown,'Disabled combo cannot reopen programmatically');
    C.Enabled:=True;
    C.Items.Add('three');
    C.SelectedIndex:=0;
    Key($40000052);
    Check(C.SelectedIndex=0,'Combo Up clamps at first item, not no selection');
    Key($4000004D);
    Check(C.SelectedIndex=1,'Combo End selects last item');
    Key($4000004A);
    Check(C.SelectedIndex=0,'Combo Home selects first item');
    C.DroppedDown:=True;
    Mouse(gmbLeft,75);
    Check((C.SelectedIndex=1) AND P.ClosedOnSelect,'Selection callback observes already-closed combo popup');
    C.DroppedDown:=True;
    E:=Default(TGuiEvent);
    E.Kind:=gekCancel;
    C.HandleEvent(E);
    Check(NOT C.DroppedDown,'Explicit combo cancellation closes popup');
    C.DroppedDown:=True;
    C.OnMouseDown:=P.ReplaceItems;
    Before:=P.Calls;
    Mouse(gmbLeft,45);
    Check((C.Items.Count=1) AND C.DroppedDown AND (P.Calls=Before+1),'Callback item mutation cancels stale row selection');
    C.OnMouseDown:=nil;
    Rejected:=False;
    try
      C.ItemHeight:=0;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (C.ItemHeight=30),'Combo rejects zero row height without mutation');
    Rejected:=False;
    try
      C.ItemHeight:=NaN;
    except
      on EArgumentException do Rejected:=True;
    end;
    Check(Rejected AND (C.ItemHeight=30),'Combo rejects nonfinite row height');
    C.ItemHeight:=24;
    C.Paint(Canvas);
    C.PaintOverlay(Canvas);
    Check(Canvas.ClipDepth=0,'Mutated combo popup paints with balanced clipping');
    C.DroppedDown:=True;
    C.Enabled:=False;
    C.PaintOverlay(Canvas);
    Check(NOT C.DroppedDown,'Rendering after disabling combo closes its popup without waiting for input');
  finally
    Other.Free;
    C.Free;
    P.Free;
    Canvas.Free;
    A.Free;
    B.Free;
  end;
end;

procedure TestWidgets;
var
  Context: TGuiContext;
  Combo: TGuiComboBox;
  Scroll: TGuiScrollBox;
  Child: TGuiButton;
  Canvas: TTestCanvas;
  Event: TGuiEvent;
  I: Integer;
begin
  Context:=TGuiContext.Create;
  Canvas:=TTestCanvas.Create;
  try
    Context.Resize(500, 500);
    Combo:=TGuiComboBox.Create;
    Combo.Bounds:=GuiRect(0, 0, 100, 30);
    for I:=0 to 9 do Combo.AddItem(IntToStr(I));
    Context.Root.Add(Combo);
    Combo.DroppedDown:=True;
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseWheel;
    Event.Position:=GuiPoint(10, 45);
    Event.Delta:=GuiPoint(0, -4);
    Context.ProcessEvent(Event);
    Event.Kind:=gekMouseDown;
    Event.Button:=gmbLeft;
    Event.Handled:=False;
    Event.Position:=GuiPoint(10, 195);
    Context.ProcessEvent(Event);
    Check(Combo.SelectedIndex = 9, 'Mouse can select tenth combo item after scrolling');
    Context.CancelInput;
    Scroll:=TGuiScrollBox.Create;
    Scroll.Bounds:=GuiRect(200, 0, 100, 100);
    Context.Root.Add(Scroll);
    Child:=TGuiButton.Create;
    Child.Bounds:=GuiRect(0, 0, 300, 30);
    Scroll.Add(Child);
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseWheel;
    Event.Position:=GuiPoint(210, 20);
    Event.Delta:=GuiPoint(-1, 0);
    Context.ProcessEvent(Event);
    Check((Scroll.ScrollX = 42) AND (Child.AbsoluteBounds.Left = 158), 'Horizontal wheel translates child coordinates');
    Scroll.ScrollX:=10000;
    Check(Scroll.ScrollX = Scroll.MaxScrollX, 'Horizontal scrolling clamps to content');
    Child.Hint:='Tooltip test';
    Scroll.ScrollX:=0;
    Context.TooltipDelay:=0;
    Event.Kind:=gekMouseMove;
    Event.Handled:=False;
    Context.ProcessEvent(Event);
    Context.Paint(Canvas);
    Check(Canvas.LastText = 'Tooltip test', 'Hover paints delayed tooltip');
    Child.Free;
    Context.Paint(Canvas);
    Check(Context.HoveredControl = nil, 'Freeing hovered control clears tooltip target');
  finally
    Canvas.Free;
    Context.Free;
  end;
end;

procedure Check(ACondition: Boolean; const AMessage: String);
begin
  if NOT ACondition then raise Exception.Create(AMessage);
  Writeln('PASS: ', AMessage);
end;

procedure TestCore;
var
  Context: TGuiContext;
  Panel: TGuiPanel;
  Button, Other: TProbe;
  Event: TGuiEvent;
  Edit: TGuiEdit;
  Rect: TGuiRect;
  Pages: TGuiPageControl;
  Page: TGuiPage;
  Modal: TGuiPanel;
begin
  Context:=TGuiContext.Create;
  try
    Context.Resize(500, 500);
    Panel:=TGuiPanel.Create;
    Panel.Bounds:=GuiRect(50, 40, 200, 200);
    Context.Root.Add(Panel);
    Button:=TProbe.Create;
    Button.Bounds:=GuiRect(0, 0, 50, 25);
    Panel.Add(Button);
    Other:=TProbe.Create;
    Other.Bounds:=GuiRect(300, 0, 50, 25);
    Context.Root.Add(Other);
    Panel.Visible:=False;
    Context.FocusFirst;
    Check(Context.FocusedControl = Other, 'Focus skips hidden ancestors');
    Panel.Visible:=True;
    Panel.Enabled:=False;
    Check(NOT Context.SetFocus(Button), 'Focus rejects disabled ancestors');
    Panel.Enabled:=True;
    Context.SetFocus(Button);
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseMove;
    Event.Position:=GuiPoint(310, 10);
    Context.ProcessEvent(Event);
    Event:=Default(TGuiEvent);
    Event.Kind:=gekKeyUp;
    Context.ProcessEvent(Event);
    Check((Button.KeyUps = 1) AND (Other.KeyUps = 0), 'Key-up reaches focused control');
    Button.Align:=gaClient;
    Context.UpdateLayout;
    Rect:=Button.AbsoluteBounds;
    Check((Rect.Left = 50) AND (Rect.Top = 40), 'Nested docking uses local coordinates');
    Panel.Padding:=GuiBox(10);
    Context.UpdateLayout;
    Check(Button.Bounds.Left = 10, 'Direct layout changes trigger arrangement');
    Panel.Remove(Button);
    Check(Context.FocusedControl = nil, 'Removal clears focus');
    Button.Free;
    Button:=TProbe.Create;
    Panel.Add(Button);
    Context.SetFocus(Button);
    Button.Free;
    Check((Panel.ChildCount = 0) AND (Context.FocusedControl = nil), 'Free detaches owned controls');
    Pages:=TGuiPageControl.Create;
    Context.Root.Add(Pages);
    Page:=Pages.AddPage('first');
    Pages.AddPage('second');
    Page.Free;
    Check((Pages.PageCount = 1) AND (Pages.Pages[0].Caption = 'second'), 'Freeing a page updates its page collection');
    Pages.Clear;
    Check(Pages.PageCount = 0, 'Clearing a page control detaches every page');
    Modal:=TGuiPanel.Create;
    Context.ShowModal(Modal);
    Check(NOT Context.SetFocus(Other), 'Modal focus cannot escape into background');
    Modal.Free;
    Check(Context.ModalControl = nil, 'Freeing a modal removes its stack entry');
  finally
    Context.Free;
  end;
  Edit:=TGuiEdit.Create;
  try
    {$IFDEF FPC}
    Edit.Text:=#$F0#$9F#$98#$80;
    {$ELSE}
    Edit.Text:=#$D83D#$DE00;
    {$ENDIF}
    Edit.CaretIndex:=Length(Edit.Text);
    Event:=Default(TGuiEvent);
    Event.Kind:=gekKeyDown;
    Event.KeyCode:=8;
    Edit.HandleEvent(Event);
    Check(Edit.Text = '', 'Backspace removes a complete Unicode character');
    {$IFDEF FPC}
    Edit.Text:=#$F0#$9F#$98#$80;
    {$ELSE}
    Edit.Text:=#$D83D#$DE00;
    {$ENDIF}
    Edit.CaretIndex:=1;
    Check(Edit.CaretIndex = 0, 'Caret cannot split a Unicode character');
    Key(Edit, 127);
    Check(Edit.Text = '', 'Forward delete removes a complete Unicode character');
  finally
    Edit.Free;
  end;
end;

procedure TestScrollRefinement;
var
  Context: TGuiContext;
  Scroll: TGuiScrollBox;
  Child: TGuiButton;
  Bar: TGuiScrollBar;
  Canvas: TTestCanvas;
  Event: TGuiEvent;
begin
  Context:=TGuiContext.Create;
  Canvas:=TTestCanvas.Create;
  try
    Context.Resize(400, 300);
    Scroll:=TGuiScrollBox.Create;
    Scroll.Bounds:=GuiRect(0, 0, 100, 100);
    Context.Root.Add(Scroll);
    Child:=TGuiButton.Create;
    Child.Bounds:=GuiRect(0, 0, 300, 200);
    Scroll.Add(Child);
    Scroll.Paint(Canvas);
    Check((Scroll.MaxScrollX = 212) AND (Scroll.MaxScrollY = 112), 'Both scroll ranges account for reserved gutters');
    Check((Canvas.FirstClip.Width = 88) AND (Canvas.FirstClip.Height = 88) AND (Canvas.ClipDepth = 0),
      'Scroll content clips to viewport without painting beneath bars');
    Check((Scroll.HitTest(GuiPoint(95, 50)) = Scroll) AND
      (Scroll.HitTest(GuiPoint(50, 95)) = Scroll) AND (Scroll.HitTest(GuiPoint(95, 95)) = Scroll),
      'Scrollbar gutters and shared corner never hit underlying child');
    Scroll.ScrollX:=999;
    Scroll.ScrollY:=999;
    Child.Bounds:=GuiRect(0, 0, 50, 50);
    Scroll.Paint(Canvas);
    Check((Scroll.MaxScrollX = 0) AND (Scroll.MaxScrollY = 0) AND
      (Scroll.ScrollX = 0) AND (Scroll.ScrollY = 0), 'Shrinking content removes gutters and clamps offsets');
    Child.Bounds:=GuiRect(0, 0, 95, 150);
    Scroll.Paint(Canvas);
    Check((Scroll.MaxScrollX = 7) AND (Scroll.MaxScrollY = 62), 'Vertical gutter can induce horizontal overflow');
    SetStyleScrollBarSize(Scroll, 16);
    Scroll.Paint(Canvas);
    Check((Canvas.FirstClip.Width = 84) AND (Canvas.FirstClip.Height = 84), 'Configured scrollbar size affects viewport geometry');
    Bar:=TGuiScrollBar.Create;
    Bar.Bounds:=GuiRect(0, 120, 200, 20);
    Bar.Padding:=GuiBox(0);
    Bar.Orientation:=goHorizontal;
    Bar.PageSize:=50;
    Bar.Value:=50;
    Context.Root.Add(Bar);
    Bar.Paint(Canvas);
    Check((Canvas.LastFill.Height = 6) AND (Canvas.LastColor.R = Bar.Style.ScrollThumbColor.R),
      'Idle scrollbar uses slim neutral thumb');
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseMove;
    Event.Position:=GuiPoint(70, 130);
    Context.ProcessEvent(Event);
    Bar.Paint(Canvas);
    Check((Canvas.LastFill.Height = 8) AND (Canvas.LastColor.R = Bar.Style.ScrollHoverColor.R),
      'Hover widens and highlights the thumb');
    Event.Kind:=gekMouseDown;
    Event.Button:=gmbLeft;
    Event.Handled:=False;
    Context.ProcessEvent(Event);
    Check(Abs(Bar.Value - 50) < 0.001, 'Grabbing thumb off-center does not jump the value');
    Bar.Paint(Canvas);
    Check(Canvas.LastColor.R = Bar.Style.ScrollPressedColor.R, 'Dragging thumb uses active accent');
    Event.Kind:=gekMouseMove;
    Event.Position:=GuiPoint(90, Event.Position.Y);
    Event.Handled:=False;
    Context.ProcessEvent(Event);
    Check(Abs(Bar.Value - 65) < 0.001, 'Thumb drag preserves pointer offset');
    Event.Kind:=gekMouseUp;
    Event.Handled:=False;
    Context.ProcessEvent(Event);
    Bar.Bounds:=GuiRect(220, 0, 20, 200);
    Bar.Orientation:=goVertical;
    Bar.Value:=50;
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseDown;
    Event.Position:=GuiPoint(230, 70);
    Event.Button:=gmbLeft;
    Context.ProcessEvent(Event);
    Check(Abs(Bar.Value - 50) < 0.001, 'Vertical thumb preserves off-center grab');
    Event.Kind:=gekMouseMove;
    Event.Position:=GuiPoint(Event.Position.X, 90);
    Event.Handled:=False;
    Context.ProcessEvent(Event);
    Check(Abs(Bar.Value - 65) < 0.001, 'Vertical drag uses the same travel mapping');
    Event.Kind:=gekMouseUp;
    Event.Handled:=False;
    Context.ProcessEvent(Event);
    Bar.Bounds:=GuiRect(0, 120, 200, 20);
    Bar.Orientation:=goHorizontal;
    Bar.MaxValue:=0;
    Bar.PageSize:=0;
    Bar.Paint(Canvas);
    Check(Canvas.LastFill.Width = 200, 'Zero-range scrollbar fills its track');
    Bar.Bounds:=GuiRect(0, 120, 6, 6);
    Bar.Paint(Canvas);
    Check((Canvas.LastFill.Width >= 0) AND (Canvas.LastFill.Height >= 0), 'Tiny scrollbar geometry stays nonnegative');
    SetStyleTrack(Bar, GuiImageDrawable(Pointer(1), GuiRect(0, 0, 8, 8)));
    SetStyleThumb(Bar, GuiImageDrawable(Pointer(1), GuiRect(0, 0, 8, 8)));
    Canvas.ImageCount:=0;
    Bar.Paint(Canvas);
    Check(Canvas.ImageCount = 2, 'Custom scrollbar track and thumb skins retain their drawing path');
  finally
    Canvas.Free;
    Context.Free;
  end;
end;

procedure TestScrollGeometryConsistency;
var
  Canvas: TTestCanvas;
  Scroll: TGuiScrollBox;
  Child: TGuiControl;
  Tree: TGuiTreeView;
  Memo: TGuiMemo;
  List: TGuiListView;
  Reference, Track, Thumb: TGuiRect;
  I: Integer;
  Event: TGuiEvent;
begin
  Canvas:=TTestCanvas.Create;
  Scroll:=TGuiScrollBox.Create;
  Tree:=TGuiTreeView.Create;
  Memo:=TGuiMemo.Create;
  List:=TGuiListView.Create;
  try
    Scroll.Bounds:=GuiRect(30, 40, 200, 200);
    Tree.Bounds:=Scroll.Bounds;
    Memo.Bounds:=Scroll.Bounds;
    List.Bounds:=Scroll.Bounds;
    Child:=TGuiControl.Create;
    Child.Bounds:=GuiRect(0, 0, 40, 400);
    Scroll.Add(Child);
    Tree.Padding:=GuiBoxLTRB(8, 4, 8, 4);
    Memo.Padding:=Tree.Padding;
    List.Padding:=Tree.Padding;
    List.HeaderHeight:=0;
    Tree.ItemHeight:=20;
    Memo.LineHeight:=20;
    List.RowHeight:=20;
    List.AddColumn('Rows', 100);
    for I:=1 to 20 do
    begin
      Tree.AddNode('Row');
      Memo.AddLine('Row');
      List.AddRow(['Row']);
    end;
    Scroll.Paint(Canvas);
    Reference:=Canvas.LastFill;
    Tree.Paint(Canvas);
    Check((Canvas.LastFill.Left = Reference.Left) AND (Canvas.LastFill.Width = Reference.Width) AND
      (Canvas.LastFill.Top = Reference.Top), 'Tree thumb matches scroll-box edge position, width and top inset');
    Check((Canvas.FirstClip.Left = 31) AND (Canvas.FirstClip.Width = 198) AND
      (Canvas.ContentClip.Left + Canvas.ContentClip.Width = 214),
      'Tree row background spans the control while text stays clear of the gutter');
    Check(Abs(Canvas.LastFill.Height - 192 * 192 / 400) < 0.001, 'Tree thumb proportion uses padded visible content height');
    Memo.Paint(Canvas);
    Check((Canvas.LastFill.Left = Reference.Left) AND (Canvas.LastFill.Top = Reference.Top) AND
      (Canvas.FirstClip.Left + Canvas.FirstClip.Width = 214), 'Memo shares tree gutter and content gap');
    List.Paint(Canvas);
    Check((Canvas.LastFill.Left = Reference.Left) AND (Canvas.LastFill.Top = Reference.Top),
      'Headerless list view shares the same scrollbar geometry');
    Tree.Padding:=GuiBoxLTRB(18, 16, 24, 16);
    Tree.Paint(Canvas);
    Check((Canvas.LastFill.Left = Reference.Left) AND (Canvas.LastFill.Top = Reference.Top),
      'Custom content padding does not move the scrollbar inward');
    Check((Canvas.ContentClip.Left + Canvas.ContentClip.Width = 206) AND
      (Abs(Canvas.LastFill.Height - 192 * 168 / 400) < 0.001),
      'Larger content padding remains respected and reduces thumb proportion');
    Tree.ScrollY:=Tree.MaxScrollY;
    Tree.Paint(Canvas);
    Check(Abs(Canvas.LastFill.Top + Canvas.LastFill.Height - 236) < 0.001,
      'Tree thumb reaches the shared four-pixel bottom inset');
    List.HeaderHeight:=30;
    List.ScrollY:=List.MaxScrollY;
    List.Paint(Canvas);
    Check((Canvas.LastFill.Left = Reference.Left) AND
      (Abs(Canvas.LastFill.Top + Canvas.LastFill.Height - 236) < 0.001),
      'Table header changes track start but not right or bottom alignment');
    SetStyleScrollBarSize(Tree, 16);
    Tree.ScrollY:=0;
    Tree.Paint(Canvas);
    Check(Canvas.LastFill.Left = 219, 'Larger gutter retains a centered six-pixel idle thumb');
    Tree.Padding:=GuiBoxLTRB(8, 4, 8, 4);
    SetStyleScrollBarSize(Tree, 12);
    Tree.SelectedIndex:=0;
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseDown;
    Event.Button:=gmbLeft;
    Event.Position:=GuiPoint(224, 220);
    Tree.HandleEvent(Event);
    Check((Tree.ScrollY > 0) AND (Tree.SelectedIndex = 0), 'Edge-anchored track click scrolls without selecting a row');
    SetBoundsHeight(Tree, 600);
    Tree.Paint(Canvas);
    Check(Tree.ScrollY = 0, 'Growing tree viewport clamps obsolete scroll offset');
    Memo.ScrollY:=Memo.MaxScrollY;
    SetBoundsHeight(Memo, 600);
    Memo.Paint(Canvas);
    Check(Memo.ScrollY = 0, 'Growing memo viewport clamps obsolete scroll offset');
    List.ScrollY:=List.MaxScrollY;
    SetBoundsHeight(List, 600);
    List.Paint(Canvas);
    Check(List.ScrollY = 0, 'Growing table viewport clamps obsolete scroll offset');
    Track:=GuiScrollTrackRect(GuiRect(0, 0, 6, 3), goVertical, 12, 34);
    Check((Track.Left >= 0) AND (Track.Top <= 3) AND (Track.Height = 0),
      'Tiny control and oversized header keep track bounds nonnegative');
    Thumb:=GuiVerticalScrollThumbRect(GuiRect(0, 4, 12, 192), 192, 400, 9999);
    Check(Abs(Thumb.Top + Thumb.Height - 196) < 0.001, 'Shared thumb geometry clamps oversized offsets');
  finally
    List.Free;
    Memo.Free;
    Tree.Free;
    Scroll.Free;
    Canvas.Free;
  end;
end;

procedure TestInteractionPolish;
var
  Context: TGuiContext;
  Dialog: TGuiDialog;
  Header: TGuiHeaderControl;
  Edit: TGuiEdit;
  Bar: TGuiMenuBar;
  Popup: TGuiPopupMenu;
  RootMenu, Item: TGuiMenuItem;
  Probe: TProbe;
  Canvas: TTestCanvas;
  Event: TGuiEvent;
  procedure Mouse(AKind: TGuiEventKind; X, Y: TGuiFloat; AButton: TGuiMouseButton = gmbLeft);
  begin
    Event:=Default(TGuiEvent);
    Event.Kind:=AKind;
    Event.Button:=AButton;
    Event.Position:=GuiPoint(X, Y);
    Context.ProcessEvent(Event);
  end;
  procedure SendKey(ACode: Integer; AModifiers: TGuiEventModifiers = []);
  begin
    Event:=Default(TGuiEvent);
    Event.Kind:=gekKeyDown;
    Event.KeyCode:=ACode;
    Event.Modifiers:=AModifiers;
    Context.ProcessEvent(Event);
  end;
begin
  Context:=TGuiContext.Create;
  Probe:=TProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    Context.Resize(800, 600);
    Dialog:=TGuiDialog.Create;
    Dialog.Bounds:=GuiRect(300, 100, 300, 200);
    Dialog.WindowMode:=gdwmResizable;
    Context.Root.Add(Dialog);
    Mouse(gekMouseMove, 301, 101);
    Check(Context.MouseCursor = gmcSizeNWSE, 'Window corner exposes diagonal resize cursor');
    Mouse(gekMouseDown, 301, 101);
    Mouse(gekMouseMove, 250, 70);
    Check(Context.MouseCursor = gmcSizeNWSE, 'Captured drag retains cursor outside original bounds');
    Context.CancelInput;
    Check(Context.MouseCursor = gmcArrow, 'Cancel resets drag cursor');
    Mouse(gekMouseMove, Dialog.Bounds.Left + 50, Dialog.Bounds.Top + 16);
    Check(Context.MouseCursor = gmcMove, 'Title exposes move cursor');
    Dialog.Movable:=False;
    Check(Context.MouseCursor = gmcArrow, 'Disabling movement removes move cursor');
    Header:=TGuiHeaderControl.Create;
    Header.Bounds:=GuiRect(10, 90, 200, 30);
    Header.AddColumn('A', 80);
    Header.AddColumn('B', 80);
    Context.Root.Add(Header);
    Mouse(gekMouseMove, 90, 100);
    Check(Context.MouseCursor = gmcSizeWE, 'Header divider exposes horizontal resize cursor');
    Header.ColumnsResizable:=False;
    Check(Context.MouseCursor = gmcArrow, 'Disabled column resizing has no resize cursor');
    Edit:=TGuiEdit.Create;
    Edit.Bounds:=GuiRect(10, 140, 200, 32);
    Context.Root.Add(Edit);
    Mouse(gekMouseMove, 30, 150);
    Check(Context.MouseCursor = gmcText, 'Editor exposes text cursor');
    Edit.Cursor:=gmcHand;
    Check(Context.MouseCursor = gmcHand, 'Application can override automatic cursor');
    Bar:=TGuiMenuBar.Create;
    Bar.Bounds:=GuiRect(10, 10, 240, 30);
    Context.Root.Add(Bar);
    RootMenu:=Bar.AddMenu('&File');
    Item:=RootMenu.Add('&Save', Probe.MenuClick);
    Item.ShortcutKey:=Ord('s');
    Item.ShortcutModifiers:=[gemCtrl];
    Check(Item.ShortcutCaption = 'Ctrl+S', 'Shortcut display label derives from binding');
    Context.SetFocus(Edit);
    SendKey(Ord('s'), [gemCtrl]);
    Check(Probe.MenuClicks = 1, 'Unconsumed application shortcut invokes menu command');
    Item.Enabled:=False;
    SendKey(Ord('s'), [gemCtrl]);
    Check(Probe.MenuClicks = 1, 'Disabled menu shortcut cannot invoke');
    Item.Enabled:=True;
    SendKey(Ord('f'), [gemAlt]);
    Check(Context.FocusedControl = Bar, 'Alt mnemonic focuses and opens menu');
    SendKey(Ord('s'));
    Check(Probe.MenuClicks = 2, 'Open-menu mnemonic invokes command');
    SendKey($40000043);
    Check(Bar.HitTestOverlay(GuiPoint(20, 50)) = Bar, 'F10 opens keyboard menu');
    SendKey(27);
    Popup:=TGuiPopupMenu.Create;
    Context.Root.Add(Popup);
    Edit.PopupMenu:=Popup;
    Popup.Menu.Add('Context command', Probe.MenuClick);
    Popup.Menu.Add('A longer command caption that should expand the menu width');
    Context.SetFocus(Edit);
    Mouse(gekMouseDown, 30, 150, gmbRight);
    Check((Context.FocusedControl = Popup) AND (Popup.HitTestOverlay(GuiPoint(40, 165)) = Popup),
      'Right click opens assigned context menu at pointer');
    Popup.PaintOverlay(Canvas);
    Check(Canvas.FirstClip.Width > 240, 'Menu grows to fit long captions within configured maximum');
    SendKey($40000051);
    SendKey(13);
    Check((Probe.MenuClicks = 3) AND (Context.FocusedControl = Edit), 'Context command restores previous focus');
    Mouse(gekMouseDown, 30, 150, gmbRight);
    SendKey(27);
    Check(Context.FocusedControl = Edit, 'Escape dismisses context menu and restores focus');
    Popup.Free;
    Check(Edit.PopupMenu = nil, 'Removing menu clears non-owning popup references');
    Context.ShowModal(Dialog);
    Dialog.Activate;
    SendKey(Ord('s'), [gemCtrl]);
    Check(Probe.MenuClicks = 3, 'Modal blocks background application shortcuts');
    Context.CloseModal(Dialog);
    Check(Canvas.ClipDepth = 0, 'Context menu rendering restores clipping');
  finally
    Canvas.Free;
    Probe.Free;
    Context.Free;
  end;
end;

procedure TestGraphemeEditing;
var Edit: TGuiEdit;
Memo: TGuiMemo;
Canvas: TTestCanvas;
E: TGuiEvent;
  Cluster, Joined: String;
  U: UnicodeString;
  Rows: TGuiTextRows;
  I: Integer;
  procedure Key(Code: Integer; Mods: TGuiEventModifiers);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    E.Modifiers:=Mods;
    Edit.HandleEvent(E);
  end;
  procedure Input(const Value: UnicodeString);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekTextInput;
    E.Text:=UTF8Encode(Value);
    Edit.HandleEvent(E);
  end;
begin
  Edit:=TGuiEdit.Create;
  Memo:=TGuiMemo.Create;
  Canvas:=TTestCanvas.Create;
  try
    for I:=0 to 3 do
    begin
      case I of
        0: U:='a' + UnicodeString(WideChar($0301));
        1: U:=UnicodeString(WideChar($D83D)) + WideChar($DC69) + WideChar($200D) + WideChar($D83D) + WideChar($DCBB);
        2: U:=UnicodeString(WideChar($D83C)) + WideChar($DDE9) + WideChar($D83C) + WideChar($DDEA);
        3: U:=UnicodeString(WideChar($0915)) + WideChar($094D) + WideChar($0915);
      end;
      {$IFDEF FPC}
      Cluster:=UTF8Encode(U);
      {$ELSE}
      Cluster:=U;
      {$ENDIF}
      Edit.Text:=Cluster + 'x';
      Edit.CaretIndex:=1;
      Check(Edit.CaretIndex = 0, 'Caret cannot enter cluster ' + IntToStr(I));
      Key($4000004F, []);
      Check(Edit.CaretIndex = Length(Cluster), 'Right crosses whole cluster ' + IntToStr(I));
      Key($40000050, [gemShift]);
      Check(Edit.SelectedText = Cluster, 'Shift selects whole cluster ' + IntToStr(I));
      Edit.SetSelection(0,0);
      Key(127, []);
      Check(Edit.Text = 'x', 'Delete removes whole cluster ' + IntToStr(I));
      Edit.Undo;
      Check(Edit.Text = Cluster + 'x', 'Undo restores whole cluster ' + IntToStr(I));
      Edit.SetSelection(Length(Cluster), Length(Cluster));
      Key(8, []);
      Check((Edit.Text = 'x') AND (Edit.CaretIndex = 0), 'Backspace removes whole cluster ' + IntToStr(I));
      Edit.Text:=Cluster + 'x';
      Edit.PasswordChar:='*';
      Edit.Paint(Canvas);
      Check(Canvas.LastText = '**', 'Password masks one glyph per cluster ' + IntToStr(I));
      Edit.PasswordChar:=#0;
      Rows:=GuiLayoutText(nil, Cluster + 'x', 8, True);
      Check((Length(Rows) = 2) AND (Rows[0].TextLength = Length(Cluster)),
        'Wrapping preserves whole cluster ' + IntToStr(I));
      Memo.WordWrap:=True;
      Memo.Bounds:=GuiRect(0,0,40,200);
      Memo.Padding:=GuiBox(0);
      Memo.Text:=Cluster + 'x';
      Memo.CaretIndex:=0;
      E:=Default(TGuiEvent);
      E.Kind:=gekKeyDown;
      E.KeyCode:=$4000004F;
      Memo.HandleEvent(E);
      Check(Memo.CaretIndex = Length(Cluster), 'Memo navigates whole cluster ' + IntToStr(I));
      Edit.MaxLength:=Length(Cluster)-1;
      Edit.Text:=Cluster;
      Check(Edit.Text = '', 'MaxLength never truncates inside cluster ' + IntToStr(I));
      Input(U);
      Check(Edit.Text = '', 'Input limit never inserts partial cluster ' + IntToStr(I));
      Edit.MaxLength:=0;
    end;
    U:='a' + UnicodeString(WideChar($0301));
    {$IFDEF FPC}Joined:=UTF8Encode(U);{$ELSE}Joined:=U;{$ENDIF}
    Edit.Text:='a';
    Edit.SetSelection(1,1);
    Input(UnicodeString(WideChar($0301)));
    Check((Edit.Text = Joined) AND (Edit.CaretIndex = Length(Joined)), 'Inserted combining mark joins preceding base');
    Edit.Undo;
    Check((Edit.Text = 'a') AND (Edit.CaretIndex = 1), 'Undo invalidates grapheme map');
    Edit.Redo;
    Check(Edit.CaretIndex = Length(Joined), 'Redo restores cluster-end caret');
    Edit.Text:=Copy(Joined,2,MaxInt);
    Edit.SetSelection(0,0);
    Input('a');
    Check((Edit.Text = Joined) AND (Edit.CaretIndex = Length(Joined)), 'Insertion joining suffix moves caret to resulting cluster end');
    Edit.Text:=Joined + 'b';
    Edit.SetSelection(0,0);
    Key($4000004F,[gemCtrl]);
    Check(Edit.CaretIndex = Length(Edit.Text), 'Ctrl Right cannot strand combining marks');
    Key(8,[gemCtrl]);
    Check(Edit.Text = '', 'Ctrl Backspace deletes whole accented word');
    Rows:=GuiLayoutText(nil, 'a' + #13#10 + 'b', 8, True);
    Check((Length(Rows) = 2) AND (Rows[0].TextLength = 1) AND (Rows[1].StartIndex = 3),
      'Layout consumes CRLF as one hard break');
  finally
    Canvas.Free;
    Memo.Free;
    Edit.Free;
  end;
end;

procedure TestWrapping;
var
  Context: TGuiContext;
  Memo: TGuiMemo;
  Button: TGuiButton;
  Canvas: TTestCanvas;
  Rows: TGuiTextRows;
  Event: TGuiEvent;
  Original: String;
  I: Integer;
  procedure Mouse(AKind: TGuiEventKind; X, Y: TGuiFloat; Shift: Boolean = False);
  begin
    Event:=Default(TGuiEvent);
    Event.Kind:=AKind;
    Event.Button:=gmbLeft;
    Event.Position:=GuiPoint(X, Y);
    if Shift then Event.Modifiers:=[gemShift];
    Context.ProcessEvent(Event);
  end;
begin
  Context:=TGuiContext.Create;
  Canvas:=TTestCanvas.Create;
  try
    Context.Resize(400, 300);
    Rows:=GuiLayoutText(Canvas, 'a' + #10#10 + 'b' + #10, 40, True);
    Check((Length(Rows) = 4) AND (Rows[1].TextLength = 0) AND (Rows[3].StartIndex = 5),
      'Wrapping preserves blank lines and trailing hard break');
    {$IFDEF FPC}
    Original:='A' + #$F0#$9F#$98#$80 + 'BC';
    {$ELSE}
    Original:='A' + #$D83D#$DE00 + 'BC';
    {$ENDIF}
    Rows:=GuiLayoutText(Canvas, Original, 9, True);
    for I:=0 to High(Rows) do
      Check((GuiTextBoundary(Original, Rows[I].StartIndex) = Rows[I].StartIndex) AND
        (GuiTextBoundary(Original, Rows[I].StartIndex + Rows[I].TextLength) = Rows[I].StartIndex + Rows[I].TextLength),
        'Narrow wrapping never splits a Unicode code point');
    Memo:=TGuiMemo.Create;
    Memo.Bounds:=GuiRect(0, 0, 92, 100);
    Memo.Padding:=GuiBox(4);
    Memo.LineHeight:=20;
    Memo.WordWrap:=True;
    Memo.Text:='abcd efgh ijkl mnop';
    Context.Root.Add(Memo);
    Context.SetFocus(Memo);
    Memo.Paint(Canvas);
    Check((Memo.VisualLineCount = 2) AND (Memo.Lines.Count = 1) AND (Memo.Text = 'abcd efgh ijkl mnop'),
      'Word wrap creates visual rows without inserting source newlines');
    Memo.CaretIndex:=3;
    Key(Memo, $40000051);
    Check(Memo.CaretIndex = 13, 'Down follows visual row and pixel column');
    Key(Memo, $4000004A);
    Check(Memo.CaretIndex = 10, 'Home moves to visual row start');
    Key(Memo, $40000052);
    Key(Memo, $4000004D, [gemShift]);
    Check((Memo.SelectionStart = 0) AND (Memo.SelectionEnd = 10), 'Shift End selects to soft row boundary');
    Memo.Paint(Canvas);
    Key(Memo, $4000004A);
    Check(Memo.CaretIndex = 0, 'Soft-boundary caret affinity survives repaint');
    Key(Memo, $4000004D, [gemCtrl]);
    Check(Memo.CaretIndex = Length(Memo.Text), 'Ctrl End reaches document end');
    Mouse(gekMouseDown, 28, 34);
    Mouse(gekMouseUp, 28, 34);
    Check(Memo.CaretIndex = 13, 'Mouse hit testing maps wrapped row to source offset');
    Mouse(gekMouseDown, 12, 14, True);
    Mouse(gekMouseUp, 12, 14);
    Check((Memo.SelectionStart = 1) AND (Memo.SelectionEnd = 13), 'Shift click extends selection across visual rows');
    Memo.ClearSelection;
    SetBoundsHeight(Memo, 44);
    Memo.Paint(Canvas);
    Check((Memo.VisualLineCount = 4) AND (Memo.MaxScrollY = 44), 'Wrapping accounts for scrollbar gutter and visual scroll range');
    SetBoundsWidth(Memo, 200);
    Memo.Paint(Canvas);
    Check((Memo.VisualLineCount = 1) AND (Memo.ScrollY = 0), 'Resize reflows rows and clamps obsolete scrolling');
    Canvas.MetricScale:=2;
    Memo.Paint(Canvas);
    Check(Memo.VisualLineCount > 1, 'Font metrics key invalidates wrapping at unchanged control size');
    Canvas.MetricScale:=0;
    Memo.WordWrap:=False;
    Memo.Paint(Canvas);
    Check(Memo.VisualLineCount = 1, 'Disabling wrap restores hard-line layout');
    Memo.WordWrap:=True;
    SetBoundsWidth(Memo, 92);
    SetBoundsHeight(Memo, 100);
    Memo.Text:='abcdefghijklmno';
    Memo.Paint(Canvas);
    Check(Memo.VisualLineCount = 2, 'Oversized words break safely at character boundaries');
    Memo.CaretIndex:=5;
    Input(Memo, 'Z');
    Memo.Paint(Canvas);
    Memo.Undo;
    Memo.Paint(Canvas);
    Check(Memo.Text = 'abcdefghijklmno', 'Undo restores source text and wrapped layout');
    Memo.Text:='';
    Memo.Paint(Canvas);
    Check((Memo.VisualLineCount = 1) AND (Memo.MaxScrollY = 0), 'Empty wrapped memo remains editable without overflow');
    Memo.Visible:=False;
    Context.Resize(200, 120);
    Context.TooltipDelay:=0;
    Context.TooltipMaxWidth:=90;
    Button:=TGuiButton.Create;
    Button.Bounds:=GuiRect(150, 85, 45, 30);
    Button.Hint:='A tooltip with several words that must wrap near the window edge.';
    Context.Root.Add(Button);
    Mouse(gekMouseMove, 160, 95);
    Canvas.TextDrawCount:=0;
    Context.Paint(Canvas);
    Check((Canvas.TextDrawCount > 2) AND (Canvas.FirstClip.Left + Canvas.FirstClip.Width <= 200) AND
      (Canvas.FirstClip.Top + Canvas.FirstClip.Height <= 120) AND (Canvas.ClipDepth = 0),
      'Tooltips wrap into multiple lines and stay clipped inside the viewport');
  finally
    Canvas.Free;
    Context.Free;
  end;
end;

procedure TestWindowButtons;
var
  Context: TGuiContext;
  Dialog: TGuiDialog;
  Button: TGuiButton;
  Event: TGuiEvent;
  procedure Mouse(AKind: TGuiEventKind; X, Y: TGuiFloat);
  begin
    Event:=Default(TGuiEvent);
    Event.Kind:=AKind;
    Event.Button:=gmbLeft;
    Event.Position:=GuiPoint(X, Y);
    Context.ProcessEvent(Event);
  end;
  procedure Click(X, Y: TGuiFloat);
  begin
    Mouse(gekMouseDown, X, Y);
    Mouse(gekMouseUp, X, Y);
  end;
begin
  Context:=TGuiContext.Create;
  try
    Context.Resize(800, 600);
    Dialog:=TGuiDialog.Create;
    Dialog.Bounds:=GuiRect(100, 100, 400, 240);
    Dialog.WindowMode:=gdwmFixed;
    Dialog.TitleButtons:=[gdbClose, gdbMaximize, gdbMinimize];
    Context.Root.Add(Dialog);
    Button:=Dialog.AddButton('OK', True);
    Dialog.Activate;
    Click(452, 116);
    Check((Dialog.WindowState = gdsMaximized) AND (Dialog.Bounds.Width = 800) AND
      (Dialog.Bounds.Height = 600), 'Maximize button works independently of resizable flag');
    Context.Resize(900, 650);
    Context.UpdateLayout;
    Check((Dialog.Bounds.Width = 900) AND (Dialog.Bounds.Height = 650), 'Maximized window follows parent resize');
    Dialog.Minimize;
    Check((Dialog.WindowState = gdsMinimized) AND NOT Dialog.ClientPanel.Visible AND
      NOT Dialog.ButtonPanel.Visible AND (Dialog.Bounds.Height = 34) AND
      (Context.FocusedControl = Dialog), 'Minimize collapses to accessible title bar and transfers focus');
    Dialog.Restore;
    Check((Dialog.WindowState = gdsMaximized) AND (Context.FocusedControl = Button),
      'Restore from minimized remembers maximized state and focused child');
    Dialog.Restore;
    Check((Dialog.WindowState = gdsNormal) AND (Dialog.Bounds.Left = 100) AND
      (Dialog.Bounds.Top = 100) AND (Dialog.Bounds.Width = 400) AND (Dialog.Bounds.Height = 240),
      'Restore preserves original normal geometry');
    Click(422, 116);
    Check(Dialog.WindowState = gdsMinimized, 'Minimize title button collapses window');
    Click(422, 116);
    Check(Dialog.WindowState = gdsNormal, 'Minimized title button restores window');
    Dialog.TitleButtons:=[gdbClose];
    Mouse(gekMouseDown, 482, 116);
    Mouse(gekMouseUp, 550, 180);
    Check(Dialog.Visible, 'Releasing outside close button cancels activation');
    Mouse(gekMouseDown, 482, 116);
    Context.CancelInput;
    Mouse(gekMouseUp, 482, 116);
    Check(Dialog.Visible, 'Input cancellation clears pressed title button');
    Dialog.ShowTitleBar:=False;
    Click(482, 116);
    Check(Dialog.Visible, 'Hidden title bar has no invisible window-button hit target');
    Dialog.ShowTitleBar:=True;
    Click(482, 116);
    Check(NOT Dialog.Visible AND (Dialog.ModalResult = gmrClose), 'Close button uses dialog close result');
  finally
    Context.Free;
  end;
end;

procedure TestDialogOptions;
var
  Dialog: TGuiDialog;
  Canvas: TTestCanvas;
  Event: TGuiEvent;
begin
  Dialog:=TGuiDialog.Create;
  Canvas:=TTestCanvas.Create;
  try
    Dialog.Bounds:=GuiRect(0, 0, 300, 200);
    Dialog.WindowMode:=gdwmResizable;
    Dialog.Paint(Canvas);
    Check((Dialog.TitleBarHeight = 32) AND (Canvas.LastTextRect.Top = 1) AND
      (Canvas.LastTextRect.Height = 31), 'Compact title text uses exact painted title-bar rectangle');
    Dialog.ShowTitleBar:=False;
    Dialog.Arrange(Dialog.Bounds);
    Canvas.LastText:='untouched';
    Dialog.Paint(Canvas);
    Check((Canvas.LastText = 'untouched') AND (Dialog.ClientPanel.Bounds.Top = 8),
      'Hidden title draws no caption and releases its content space');
    Dialog.TitleBarHeight:=48;
    Check(Dialog.Padding.Top = 8, 'Changing hidden title height preserves content spacing');
    Dialog.ShowTitleBar:=True;
    Dialog.Arrange(Dialog.Bounds);
    Check(Dialog.ClientPanel.Bounds.Top = 56, 'Showing title restores configured height plus content gap');
    Dialog.ShowTitleBar:=False;
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseDown;
    Event.Button:=gmbLeft;
    Event.Position:=GuiPoint(50, 10);
    Dialog.HandleEvent(Event);
    Event.Kind:=gekMouseMove;
    Event.Position:=GuiPoint(80, 30);
    Dialog.HandleEvent(Event);
    Check(Dialog.Bounds.Left = 0, 'Titleless content is not a hidden move handle');
    Dialog.WindowMode:=gdwmFixed;
    Dialog.Resizable:=True;
    Dialog.Movable:=False;
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseDown;
    Event.Button:=gmbLeft;
    Event.Position:=GuiPoint(298, 198);
    Dialog.HandleEvent(Event);
    Event.Kind:=gekMouseMove;
    Event.Position:=GuiPoint(318, 218);
    Dialog.HandleEvent(Event);
    Check((Dialog.Bounds.Width = 320) AND (Dialog.Bounds.Height = 220),
      'Titleless non-movable window can independently support resizing');
    Dialog.Resizable:=False;
    Event.Position:=GuiPoint(348, 248);
    Dialog.HandleEvent(Event);
    Check(Dialog.Bounds.Width = 320, 'Disabling resize ends an ongoing drag');
    Check(Canvas.ClipDepth = 0, 'Title rendering restores clipping');
  finally
    Canvas.Free;
    Dialog.Free;
  end;
end;

procedure TestDialogWindows;
var
  Context: TGuiContext;
  A, B, ModalDialog: TGuiDialog;
  Overlay: TGuiModalOverlay;
  Button: TGuiButton;
  Event: TGuiEvent;
  Saved: TGuiRect;
  procedure Mouse(AKind: TGuiEventKind; X, Y: TGuiFloat);
  begin
    Event:=Default(TGuiEvent);
    Event.Kind:=AKind;
    Event.Button:=gmbLeft;
    Event.Position:=GuiPoint(X, Y);
    Context.ProcessEvent(Event);
  end;
begin
  Context:=TGuiContext.Create;
  try
    Context.Resize(800, 600);
    A:=TGuiDialog.Create;
    A.Bounds:=GuiRect(50, 60, 300, 200);
    Context.Layers[glkDialog].Add(A);
    Check(A.WindowMode = gdwmEmbedded, 'Dialog defaults to compatible embedded mode');
    A.WindowMode:=gdwmResizable;
    Button:=A.AddButton('OK', True);
    B:=TGuiDialog.Create;
    B.Bounds:=GuiRect(400, 60, 300, 200);
    B.WindowMode:=gdwmMovable;
    Context.Layers[glkDialog].Add(B);
    B.Activate;
    Check(B.Active AND NOT A.Active, 'Dialog activation follows focused descendants');
    Mouse(gekMouseDown, 80, 80);
    Mouse(gekMouseMove, 120, 130);
    Mouse(gekMouseUp, 120, 130);
    Check((A.Bounds.Left = 90) AND (A.Bounds.Top = 110), 'Title drag moves window by pointer delta');
    Check(A.Active AND (Context.FocusedControl = Button) AND
      (A.Parent.Children[A.Parent.ChildCount - 1] = A), 'Title activation raises dialog and focuses default button');
    Mouse(gekMouseDown, 388, 308);
    Mouse(gekMouseMove, 448, 348);
    Mouse(gekMouseUp, 448, 348);
    Check((A.Bounds.Width = 360) AND (A.Bounds.Height = 240), 'Corner drag resizes both axes');
    Saved:=A.Bounds;
    Mouse(gekMouseDown, 448, 348);
    Mouse(gekMouseMove, 100, 100);
    Check((A.Bounds.Width = 260) AND (A.Bounds.Height = 160), 'Resize respects minimum window size');
    Key(A, 27);
    Mouse(gekMouseUp, 100, 100);
    Check((A.Bounds.Width = Saved.Width) AND (A.Bounds.Height = Saved.Height) AND A.Visible,
      'Escape cancels resize without closing window');
    Mouse(gekMouseDown, 120, 130);
    Mouse(gekMouseMove, 130, 140);
    Saved:=A.Bounds;
    Context.CancelInput;
    Mouse(gekMouseMove, 200, 200);
    Mouse(gekMouseUp, 200, 200);
    Check((A.Bounds.Left = Saved.Left) AND (A.Bounds.Top = Saved.Top),
      'Focus-loss cancellation stops dialog movement');
    A.Activate;
    Context.FocusNext;
    Check(A.Active, 'Tab traversal remains in active window');
    A.WindowMode:=gdwmFixed;
    Saved:=A.Bounds;
    Mouse(gekMouseDown, 120, 130);
    Mouse(gekMouseMove, 150, 150);
    Mouse(gekMouseUp, 150, 150);
    Check(A.Bounds.Left = Saved.Left, 'Fixed window cannot be dragged');
    B.Activate;
    A.Activate;
    A.Close;
    Check(NOT A.Visible AND B.Active, 'Closing non-modal window restores previous dialog focus');
    ModalDialog:=TGuiDialog.Create;
    ModalDialog.Bounds:=GuiRect(0, 0, 300, 200);
    ModalDialog.WindowMode:=gdwmResizable;
    Overlay:=TGuiModalOverlay.CreateWithDialog(ModalDialog);
    Overlay.Bounds:=GuiRect(0, 0, 800, 600);
    Context.ShowModal(Overlay);
    Context.UpdateLayout;
    ModalDialog.Activate;
    Saved:=ModalDialog.Bounds;
    Mouse(gekMouseDown, Saved.Left + 30, Saved.Top + 20);
    Mouse(gekMouseMove, Saved.Left + 80, Saved.Top + 40);
    Mouse(gekMouseUp, Saved.Left + 80, Saved.Top + 40);
    Saved:=ModalDialog.Bounds;
    Overlay.Arrange(Overlay.Bounds);
    Check(ModalDialog.Bounds.Left = Saved.Left, 'Modal layout preserves user-moved position');
    B.Activate;
    Check(ModalDialog.Active, 'Background window cannot activate through a modal');
    ModalDialog.Close;
    Check((Context.ModalControl = nil) AND B.Active, 'Closing modal restores previous focused window');
    B.Free;
    Context.RestoreFocus;
    Check(Context.FocusedControl = nil, 'Removed controls are pruned from focus restoration history');
  finally
    Context.Free;
  end;
end;

procedure TestMenus;
var
  Context: TGuiContext;
  Menu: TGuiMenuBar;
  RootMenu, SubMenu, Toggle: TGuiMenuItem;
  Probe: TProbe;
  Canvas: TTestCanvas;
  Event: TGuiEvent;
  I: Integer;
  procedure Click(X, Y: TGuiFloat);
  begin
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseDown;
    Event.Button:=gmbLeft;
    Event.Position:=GuiPoint(X, Y);
    Context.ProcessEvent(Event);
    Event.Kind:=gekMouseUp;
    Event.Handled:=False;
    Context.ProcessEvent(Event);
  end;
begin
  Context:=TGuiContext.Create;
  Probe:=TProbe.Create;
  Canvas:=TTestCanvas.Create;
  try
    Context.Resize(640, 400);
    Menu:=TGuiMenuBar.Create;
    Menu.Bounds:=GuiRect(10, 10, 400, 30);
    Context.Root.Add(Menu);
    RootMenu:=Menu.AddMenu('File');
    RootMenu.Add('Disabled', Probe.MenuClick).Enabled:=False;
    RootMenu.AddSeparator;
    Toggle:=RootMenu.Add('Toggle', Probe.MenuClick);
    Toggle.AutoCheck:=True;
    SubMenu:=RootMenu.Add('Submenu');
    SubMenu.Add('Run', Probe.MenuClick);
    Click(20, 20);
    Check(Context.Root.HitTestOverlay(GuiPoint(20, 60)) = Menu, 'Menu popup participates in overlay hit testing');
    Click(20, 55);
    Check((Probe.MenuClicks = 0) AND (Context.Root.HitTestOverlay(GuiPoint(20, 60)) = Menu),
      'Disabled menu command neither activates nor dismisses');
    Key(Menu, $40000051);
    Key(Menu, 13);
    Check(Toggle.Checked AND (Probe.MenuClicks = 1), 'Keyboard skips disabled items and separators and toggles command');
    Check(Menu.HitTestOverlay(GuiPoint(20, 60)) = nil, 'Command closes popup before returning');
    Click(20, 20);
    Key(Menu, $4000004D);
    Key(Menu, $4000004F);
    Menu.PaintOverlay(Canvas);
    Check(Canvas.ClipDepth = 0, 'Nested menus restore canvas clipping');
    Key(Menu, 13);
    Check(Probe.MenuClicks = 2, 'Keyboard opens submenu and invokes nested command');
    Click(20, 20);
    Key(Menu, 27);
    Check(Menu.HitTestOverlay(GuiPoint(20, 60)) = nil, 'Escape dismisses menu');
    Click(20, 20);
    Click(500, 350);
    Check(Menu.HitTestOverlay(GuiPoint(20, 60)) = nil, 'Outside click dismisses menu');
    Click(20, 20);
    Context.CancelInput;
    Check(Menu.HitTestOverlay(GuiPoint(20, 60)) = nil, 'Focus cancellation dismisses menu');
    Click(20, 20);
    Menu.Items.Clear;
    Check(Menu.HitTestOverlay(GuiPoint(20, 60)) = nil, 'Changing top-level items closes stale popups');
    RootMenu:=Menu.AddMenu('Long');
    for I:=0 to 39 do RootMenu.Add('Command', Probe.MenuClick);
    Click(20, 20);
    Key(Menu, $4000004D);
    Menu.PaintOverlay(Canvas);
    Key(Menu, 13);
    Check(Probe.MenuClicks = 3, 'Keyboard reaches commands in viewport-clamped long menus');
    SetBoundsLeft(Menu, 500);
    Click(510, 20);
    Menu.PaintOverlay(Canvas);
    Check(Canvas.FirstClip.Left + Canvas.FirstClip.Width <= 640, 'Menu popup stays inside right viewport edge');
    Menu.Items.Clear;
    SetBoundsLeft(Menu, 10);
    RootMenu:=Menu.AddMenu('Mouse');
    SubMenu:=RootMenu.Add('Nested');
    SubMenu.Add('Execute', Probe.MenuClick);
    Click(20, 20);
    Click(20, 55);
    Click(260, 60);
    Check(Probe.MenuClicks = 4, 'Mouse opens submenu and invokes its command');
    Menu.AddMenu('Disabled root').Enabled:=False;
    Menu.AddMenu('Next').Add('Command', Probe.MenuClick);
    Menu.SelectedIndex:=0;
    Key(Menu, $4000004F);
    Check(Menu.SelectedIndex = 2, 'Keyboard skips disabled top-level menus');
  finally
    Canvas.Free;
    Probe.Free;
    Context.Free;
  end;
end;

procedure TestPopupScrollbars;
var
  Context: TGuiContext;
  Control: TGuiControl;
  Combo: TGuiComboBox;
  Drop: TGuiDropDownButton;
  Canvas: TTestCanvas;
  Event: TGuiEvent;
  I, Kind: Integer;
  SavedTop: TGuiFloat;
  procedure Mouse(AKind: TGuiEventKind; X, Y: TGuiFloat);
  begin
    Event:=Default(TGuiEvent);
    Event.Kind:=AKind;
    Event.Button:=gmbLeft;
    Event.Position:=GuiPoint(X, Y);
    Context.ProcessEvent(Event);
  end;
begin
  for Kind:=0 to 1 do
  begin
    Context:=TGuiContext.Create;
    Canvas:=TTestCanvas.Create;
    try
      Context.Resize(400, 400);
      Combo:=nil;
      Drop:=nil;
      if Kind = 0 then
      begin
        Combo:=TGuiComboBox.Create;
        Control:=Combo;
        for I:=0 to 19 do Combo.AddItem('Row');
        Combo.DroppedDown:=True;
      end else
      begin
        Drop:=TGuiDropDownButton.Create;
        Control:=Drop;
        for I:=0 to 19 do Drop.AddItem('Row');
        Drop.DroppedDown:=True;
      end;
      Control.Bounds:=GuiRect(10, 10, 200, 30);
      SetStyleScrollBarSize(Control, 12);
      Context.Root.Add(Control);
      Control.PaintOverlay(Canvas);
      Check((Canvas.LastFill.Left = 201) AND (Canvas.LastFill.Top = 44),
        'Popup scrollbar uses shared edge inset and thumb width');
      Mouse(gekMouseDown, 204, 210);
      Control.PaintOverlay(Canvas);
      SavedTop:=Canvas.LastFill.Top;
      Check(SavedTop > 44, 'Popup track click advances scroll position');
      Context.CancelInput;
      if Assigned(Combo) then Combo.DroppedDown:=True else Drop.DroppedDown:=True;
      Mouse(gekMouseMove, 204, 45);
      Control.PaintOverlay(Canvas);
      Check(Canvas.LastFill.Top = SavedTop, 'Input cancellation ends popup thumb drag');
      Event:=Default(TGuiEvent);
      Event.Kind:=gekMouseWheel;
      Event.Position:=GuiPoint(20, 55);
      Event.Delta:=GuiPoint(Event.Delta.X, 100);
      Context.ProcessEvent(Event);
      Mouse(gekMouseDown, 204, 48);
      Mouse(gekMouseMove, 300, 350);
      Mouse(gekMouseUp, 300, 350);
      if Assigned(Combo) then
        Check(Combo.DroppedDown AND (Combo.SelectedIndex = 0), 'Combo drag keeps popup open and selection unchanged')
      else
        Check(Drop.DroppedDown AND (Drop.SelectedIndex = 0), 'Dropdown drag keeps popup open and selection unchanged');
      Control.PaintOverlay(Canvas);
      Check(Abs(Canvas.LastFill.Top + Canvas.LastFill.Height - 216) < 0.001,
        'Popup thumb reaches bottom while pointer is outside popup');
      Mouse(gekMouseDown, 20, 55);
      Mouse(gekMouseUp, 20, 55);
      if Assigned(Combo) then
        Check((Combo.SelectedIndex = 14) AND NOT Combo.DroppedDown, 'Combo selects scrolled row after thumb release')
      else
        Check((Drop.SelectedIndex = 14) AND NOT Drop.DroppedDown, 'Dropdown selects scrolled row after thumb release');
      Check(Canvas.ClipDepth = 0, 'Popup scrollbar painting restores clipping');
      if Assigned(Combo) then
      begin
        Combo.Items.Clear;
        Combo.AddItem('Only');
        Combo.DroppedDown:=True;
      end
      else
      begin
        Drop.Items.Clear;
        Drop.AddItem('Only');
        Drop.DroppedDown:=True;
      end;
      Mouse(gekMouseDown, 204, 55);
      Mouse(gekMouseUp, 204, 55);
      if Assigned(Combo) then
        Check((Combo.SelectedIndex = 0) AND NOT Combo.DroppedDown, 'Short combo has no scrollbar hit area')
      else
        Check((Drop.SelectedIndex = 0) AND NOT Drop.DroppedDown, 'Short dropdown has no scrollbar hit area');
    finally
      Canvas.Free;
      Context.Free;
    end;
  end;
end;

procedure TestTableFeatures;
var V: TGuiListView;
E: TGuiEvent;
I: Integer;
Indices: TGuiIndexArray;
Probe: TTableProbe;
  procedure Key(Code: Integer; Mods: TGuiEventModifiers);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    E.Modifiers:=Mods;
    V.HandleEvent(E);
  end;
  procedure Mouse(Kind: TGuiEventKind; X, Y: TGuiFloat);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=Kind;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(X,Y);
    V.HandleEvent(E);
  end;
begin
  V:=TGuiListView.Create;
  Probe:=TTableProbe.Create;
  try
    V.OnColumnClick:=Probe.ColumnClick;
    V.OnSelect:=Probe.Selection;
    V.Bounds:=GuiRect(0,0,300,140);
    V.AddColumn('Name', 100);
    V.AddColumn('Number', 100);
    V.AddRow(['B','10']);
    V.AddRow(['A','2']);
    V.AddRow(['C','2']);
    Check(V.SelectedCount = 1, 'Table initially selects first row');
    V.MultiSelect:=True;
    V.RowSelected[2]:=True;
    V.ColumnSortKind[1]:=gcskNumber;
    Probe.Selections:=0;
    V.SortByColumn(1);
    Check(Probe.Selections = 0, 'Sorting does not emit identity selection changes');
    Check((V.CellText[0,0] = 'A') AND (V.CellText[1,0] = 'C') AND (V.CellText[2,0] = 'B'),
      'Table numeric sort is stable');
    Check((V.SelectedIndex = 1) AND V.RowSelected[1] AND V.RowSelected[2] AND
      (V.SelectedCount = 2), 'Sorting preserves focused and selected row identities');
    V.SortByColumn(1, gsdDescending);
    Check((V.CellText[0,0] = 'B') AND (V.CellText[1,0] = 'A') AND (V.CellText[2,0] = 'C'),
      'Descending numeric sort preserves equal-row order');
    V.SelectedIndex:=0;
    Key($40000051, [gemShift]);
    Check((V.SelectedCount = 2) AND V.RowSelected[0] AND V.RowSelected[1],
      'Shift Down selects anchored range');
    Key($40000051, [gemCtrl]);
    Check((V.SelectedIndex = 2) AND (V.SelectedCount = 2) AND NOT V.RowSelected[2],
      'Ctrl Down moves focus without changing membership');
    Key(32, [gemCtrl]);
    Check(V.SelectedCount = 3, 'Ctrl Space toggles focused row');
    Key(32, [gemCtrl]);
    Check(V.SelectedCount = 2, 'Ctrl Space can deselect focused row');
    V.MultiSelect:=False;
    Check((V.SelectedCount = 1) AND V.RowSelected[2], 'Single-select mode keeps only focused row');
    V.MultiSelect:=True;
    Key(97, [gemCtrl]);
    Check(V.SelectedCount = 3, 'Ctrl A selects all table rows');
    V.ClearSelection;
    Check((V.SelectedCount = 0) AND (V.SelectedIndex = -1), 'ClearSelection clears focus and membership');
    Mouse(gekMouseDown, 30, 10);
    Mouse(gekMouseUp, 30, 10);
    Check((V.SortColumn = 0) AND (V.SortDirection = gsdAscending), 'Header click sorts ascending');
    Mouse(gekMouseDown, 30, 10);
    Mouse(gekMouseUp, 30, 10);
    Check(V.SortDirection = gsdDescending, 'Repeated header click reverses sorting');
    Mouse(gekMouseDown, 30, 10);
    Mouse(gekMouseUp, 30, 80);
    Check(V.SortDirection = gsdDescending, 'Release outside header cancels command');
    V.SortOnHeaderClick:=False;
    Mouse(gekMouseDown, 130, 10);
    Mouse(gekMouseUp, 130, 10);
    Check(V.SortColumn = 0, 'Header automatic sorting can be disabled');
    Check(Probe.Clicks = 3, 'Header commands fire once per completed click even without sorting');
    V.OnCompareRows:=Probe.Compare;
    V.SortByColumn(0);
    Check(V.CellText[0,0] = 'C', 'Custom row comparison overrides default ordering');
    V.OnCompareRows:=nil;
    V.SortByColumn(1);
    I:=V.AddRow(['New','1']);
    Check((I = 0) AND (V.CellText[0,0] = 'New'), 'Insert maintains active sort and returns current index');
    V.CellText[0,1]:='100';
    Check(V.CellText[3,0] = 'New', 'Editing sort key repositions row');
    for I:=0 to 99 do V.AddRow(['Extra', IntToStr(I + 200)]);
    V.SelectedIndex:=0;
    Key($4000004D, [gemShift]);
    Check((V.SelectedCount = V.RowCount) AND (V.ScrollY > 0), 'Shift End selects and reveals distant range');
    Indices:=V.SelectedIndices;
    Check((Length(Indices) = V.RowCount) AND (Indices[High(Indices)] = V.RowCount - 1),
      'SelectedIndices follows display order');
    Key($4000004A, []);
    Check((V.SelectedCount = 1) AND (V.ScrollY = 0), 'Home replaces selection and reveals first row');
    V.ClearRows;
    Check((V.SelectedCount = 0) AND (V.RowCount = 0), 'ClearRows drops selected row references');
    Key($40000051, [gemShift]);
    Check(V.SelectedIndex = -1, 'Empty table navigation remains safe');
    V.ClearColumns;
    V.SortByColumn(0);
    Check(V.SortColumn = -1, 'ClearColumns resets sort state');
  finally
    V.Free;
    Probe.Free;
  end;
end;

procedure TestColumnResizing;
var
  Context: TGuiContext;
  Header: TGuiHeaderControl;
  List: TGuiListView;
  Event: TGuiEvent;
  procedure Mouse(AKind: TGuiEventKind; X, Y: TGuiFloat);
  begin
    Event:=Default(TGuiEvent);
    Event.Kind:=AKind;
    Event.Button:=gmbLeft;
    Event.Position:=GuiPoint(X, Y);
    Context.ProcessEvent(Event);
  end;
begin
  Context:=TGuiContext.Create;
  Context.Resize(400, 300);
  try
    Header:=TGuiHeaderControl.Create;
    Header.Bounds:=GuiRect(10, 10, 200, 30);
    Header.AddColumn('A', 60);
    Header.AddColumn('B', 60);
    Context.Root.Add(Header);
    Mouse(gekMouseDown, 70, 20);
    Mouse(gekMouseMove, 100, 80);
    Check(Header.ColumnWidth[0] = 90, 'Header resize keeps capture outside header');
    Mouse(gekMouseUp, 100, 80);
    Mouse(gekMouseMove, 130, 20);
    Check(Header.ColumnWidth[0] = 90, 'Mouse release ends column resize');
    Mouse(gekMouseDown, 100, 20);
    Mouse(gekMouseMove, -100, 20);
    Check(Header.ColumnWidth[0] = 32, 'Header drag respects minimum column width');
    Mouse(gekMouseUp, -100, 20);
    Header.ColumnsResizable:=False;
    Mouse(gekMouseDown, 42, 20);
    Mouse(gekMouseMove, 80, 20);
    Mouse(gekMouseUp, 80, 20);
    Check(Header.ColumnWidth[0] = 32, 'Column dragging can be disabled');
    List:=TGuiListView.Create;
    List.Bounds:=GuiRect(10, 100, 200, 160);
    List.Padding:=GuiBox(4);
    List.AddColumn('A', 60);
    List.AddColumn('B', 60);
    List.AddRow(['A', 'B']);
    Context.Root.Add(List);
    Mouse(gekMouseDown, 74, 110);
    Mouse(gekMouseMove, 104, 180);
    Check((List.ColumnWidth[0] = 90) AND (List.SelectedIndex = 0),
      'List header resize updates width without changing row selection');
    Event:=Default(TGuiEvent);
    Event.Kind:=gekCancel;
    List.HandleEvent(Event);
    Mouse(gekMouseMove, 150, 110);
    Check(List.ColumnWidth[0] = 90, 'Cancel stops column resize');
    Mouse(gekMouseUp, 150, 110);
    Mouse(gekMouseDown, 104, 110);
    Mouse(gekMouseMove, 500, 110);
    Check(List.ColumnWidth[0] = 162, 'List resize reserves minimum space for fill column');
    List.ClearColumns;
    Mouse(gekMouseMove, 100, 110);
    Mouse(gekMouseUp, 100, 110);
    Check(List.ColumnCount = 0, 'Clearing columns safely cancels active resize');
  finally
    Context.Free;
  end;
end;

procedure TestListViewHeaderWidth;
var
  List: TGuiListView;
  Canvas: TTestCanvas;
  I: Integer;
begin
  List:=TGuiListView.Create;
  Canvas:=TTestCanvas.Create;
  try
    List.Bounds:=GuiRect(30, 40, 200, 200);
    List.Padding:=GuiBox(4);
    List.AddColumn('First', 60);
    List.AddColumn('Tail', 30);
    List.Paint(Canvas);
    Check((Canvas.TailHeaderText.Left = 102) AND
      (Canvas.TailHeaderText.Left + Canvas.TailHeaderText.Width = 221),
      'Last header fills remaining interior width while preserving column alignment');
    Check((Canvas.TailHeaderText.Top = 43) AND
      (Canvas.TailHeaderText.Top + Canvas.TailHeaderText.Height = 72),
      'Header attaches to top frame and preserves row start position');
    for I:=0 to 30 do List.AddRow(['Row', 'Value']);
    List.Paint(Canvas);
    Check(Canvas.TailHeaderText.Left + Canvas.TailHeaderText.Width = 221,
      'Scrollbar does not shorten the last header cell');
    SetBoundsWidth(List, 260);
    List.Paint(Canvas);
    Check(Canvas.TailHeaderText.Left + Canvas.TailHeaderText.Width = 281,
      'Last header cell grows with the control');
    SetBoundsWidth(List, 80);
    List.Paint(Canvas);
    Check(Canvas.ClipDepth = 0, 'Narrow header restores clipping');
  finally
    Canvas.Free;
    List.Free;
  end;
end;

procedure TestListBoxScrolling;
var
  Context: TGuiContext;
  List: TGuiListBox;
  Canvas: TTestCanvas;
  Event: TGuiEvent;
  I: Integer;
  OldY: TGuiFloat;
begin
  Context:=TGuiContext.Create;
  Canvas:=TTestCanvas.Create;
  try
    Context.Resize(400, 300);
    List:=TGuiListBox.Create;
    List.Bounds:=GuiRect(0, 0, 200, 100);
    List.Padding:=GuiBox(4);
    List.ItemHeight:=20;
    Context.Root.Add(List);
    for I:=0 to 19 do List.AddItem('Row ' + IntToStr(I));
    Check(List.MaxScrollY = 308, 'List box exposes overflow range');
    List.SelectedIndex:=19;
    Check(List.ScrollY = List.MaxScrollY, 'Programmatic list selection scrolls into view');
    Key(List, $4000004A);
    Check((List.SelectedIndex = 0) AND (List.ScrollY = 0), 'List Home selects and reveals first row');
    Key(List, $4000004E);
    Check(List.SelectedIndex = 4, 'List Page Down advances by visible rows');
    Key(List, $4000004D);
    Check(List.SelectedIndex = 19, 'List End reveals last row');
    List.ScrollY:=0;
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseWheel;
    Event.Position:=GuiPoint(20, 20);
    Event.Delta:=GuiPoint(Event.Delta.X, -1);
    Context.ProcessEvent(Event);
    Check((List.ScrollY = 60) AND Event.Handled, 'List wheel scrolls without changing selection');
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseDown;
    Event.Position:=GuiPoint(20, 14);
    Event.Button:=gmbLeft;
    Context.ProcessEvent(Event);
    Check(List.SelectedIndex = 3, 'List click maps through scroll offset');
    Event.Kind:=gekMouseUp;
    Event.Handled:=False;
    Context.ProcessEvent(Event);
    List.ScrollY:=0;
    OldY:=List.ScrollY;
    Event.Kind:=gekMouseDown;
    Event.Position:=GuiPoint(194, 8);
    Event.Handled:=False;
    Context.ProcessEvent(Event);
    Check(List.ScrollY = OldY, 'List thumb grab does not jump');
    Event.Kind:=gekMouseMove;
    Event.Position:=GuiPoint(Event.Position.X, 60);
    Event.Handled:=False;
    Context.ProcessEvent(Event);
    Check((List.ScrollY > OldY) AND (List.SelectedIndex = 3), 'List thumb drag scrolls without selecting a row');
    Event.Kind:=gekCancel;
    Event.Handled:=False;
    List.HandleEvent(Event);
    OldY:=List.ScrollY;
    Event.Kind:=gekMouseMove;
    Event.Position:=GuiPoint(Event.Position.X, 90);
    Event.Handled:=False;
    List.HandleEvent(Event);
    Check(List.ScrollY = OldY, 'Cancel stops list scrollbar drag');
    List.ScrollY:=List.MaxScrollY;
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseWheel;
    Event.Delta:=GuiPoint(Event.Delta.X, -1);
    List.HandleEvent(Event);
    Check(NOT Event.Handled, 'List wheel at the end remains available for parent scrolling');
    List.Paint(Canvas);
    Check((Canvas.FirstClip.Width = 198) AND (Canvas.ContentClip.Width = 180) AND (Canvas.ClipDepth = 0),
      'List row backgrounds span the interior but text excludes scrollbar lane');
    List.Items.Clear;
    Check((List.SelectedIndex = -1) AND (List.ScrollY = 0) AND (List.MaxScrollY = 0), 'Clearing list items resets selection and scrollbar');
    List.ItemHeight:=0;
    List.Paint(Canvas);
    Key(List, $4000004D);
    Check(List.SelectedIndex = -1, 'Empty list and zero item height remain safe');
  finally
    Canvas.Free;
    Context.Free;
  end;
end;

procedure TestFocusAppearance;
var
  Context: TGuiContext;
  Button: TGuiButton;
  Event: TGuiEvent;
begin
  Context:=TGuiContext.Create;
  try
    Context.Resize(200, 100);
    Button:=TGuiButton.Create;
    Button.Bounds:=GuiRect(10, 10, 100, 34);
    Context.Root.Add(Button);
    Event:=Default(TGuiEvent);
    Event.Kind:=gekKeyDown;
    Event.KeyCode:=9;
    Context.ProcessEvent(Event);
    Check((Context.FocusedControl = Button) AND Button.FocusVisible, 'Tab shows focus outline by default');
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseDown;
    Event.Position:=GuiPoint(20, 20);
    Event.Button:=gmbLeft;
    Context.ProcessEvent(Event);
    Check(Button.Focused AND NOT Button.FocusVisible, 'Mouse focus retains focus without keyboard outline');
    Event.Kind:=gekMouseUp;
    Event.Handled:=False;
    Context.ProcessEvent(Event);
    Event:=Default(TGuiEvent);
    Event.Kind:=gekGamepadButtonDown;
    Event.KeyCode:=12;
    Context.ProcessEvent(Event);
    Check(Button.FocusVisible, 'Gamepad navigation restores visible focus');
    Context.ShowFocus:=False;
    Check(NOT Button.FocusVisible, 'Context focus appearance opt-out is respected');
    Button.ShowFocus:=False;
    Context.ShowFocus:=True;
    Check(NOT Button.FocusVisible, 'Per-control focus appearance opt-out is respected');
  finally
    Context.Free;
  end;
end;

procedure TestStyles;
var
  Theme: TGuiTheme;
  Style: TGuiStyle;
  Canvas: TTestCanvas;
  Button: TGuiButton;
  Memo: TGuiMemo;
  D: TGuiDrawable;
  Loaded: TGuiTheme;
  ID: TGUID;
  FileName: String;
  Ini: TMemIniFile;
begin
  Theme:=GuiDarkTheme;
  Style:=GuiThemeStyle(Theme, gtrButton);
  Check(Style.CornerRadius = 6, 'Modern controls use shared corner radius');
  Check(Style.Background.Kind = gdkLinearGradient, 'Modern buttons use procedural gradients');
  Check(Style.FocusWidth = 2, 'Theme supplies distinct keyboard focus width');
  Theme.SurfaceGradientStrength:=0;
  Check(GuiThemeStyle(Theme, gtrButton).Background.Kind = gdkBrush, 'Zero gradient strength restores flat colour surfaces');
  Theme:=GuiDarkTheme;
  Check(GuiThemeStyle(GuiReactorTheme, gtrButton).CornerRadius = 0, 'Reactor retains square geometry');
  Theme.SurfaceBackground:=GuiColor(90, 20, 30);
  Theme.Text:=GuiColor(190, 200, 210);
  Style:=GuiThemeStyle(Theme, gtrEdit);
  Check((Style.BackgroundColor.R = 90) AND (Style.TextColor.R = 190), 'Input styles derive from supplied palette');
  D:=GuiResolveBackgroundDrawable(Style, [gcvsDisabled, gcvsHovered, gcvsPressed]);
  Check(GuiColorToHex(D.Brush.Color) = GuiColorToHex(Style.DisabledBackgroundColor), 'Disabled surface ignores hover and press');
  Check(GuiColorToHex(GuiResolveBackgroundColor(Style, [gcvsChecked])) <>
    GuiColorToHex(GuiResolveBackgroundColor(Style, [gcvsChecked, gcvsHovered])), 'Checked controls retain hover feedback');
  CreateGUID(ID);
  FileName:=ExtractFilePath(ParamStr(0)) + 'style-test-' + GUIDToString(ID) + '.ini';
  try
    SetThemeGeometry(Theme, 3.5, 9, 3);
    Theme.SurfaceGradientStrength:=0.04;
    GuiSaveThemeToIni(FileName, Theme);
    Loaded:=GuiLoadThemeFromIni(FileName, GuiReactorTheme);
    Check((Loaded.Metrics.ControlCornerRadius = 3.5) AND (Loaded.Metrics.PanelCornerRadius = 9), 'Theme INI preserves geometry metrics');
    Check((Loaded.Metrics.FocusWidth = 3) AND (Abs(Loaded.SurfaceGradientStrength - 0.04) < 0.0001), 'Theme INI preserves focus and gradient settings');
    Ini:=TMemIniFile.Create(FileName);
    try
      Ini.DeleteKey('Metrics', 'ControlCornerRadius');
      Ini.DeleteKey('Metrics', 'PanelCornerRadius');
      Ini.UpdateFile;
    finally
      Ini.Free;
    end;
    Loaded:=GuiLoadThemeFromIni(FileName, GuiDarkTheme);
    Check((Loaded.Metrics.ControlCornerRadius = 6) AND (Loaded.Metrics.PanelCornerRadius = 8), 'Legacy INI inherits missing geometry from base theme');
  finally
    DeleteFile(FileName);
  end;
  Button:=TGuiButton.Create;
  Memo:=TGuiMemo.Create;
  Canvas:=TTestCanvas.Create;
  try
    Button.StyleClass:='Primary';
    GuiApplyTheme(Button, Theme);
    Check(GuiColorToHex(Button.Style.BackgroundColor) = GuiColorToHex(Theme.PrimaryAccent), 'Primary button uses accent surface');
    Button.StyleClass:='Quiet';
    GuiApplyTheme(Button, Theme);
    Check((Button.Style.BackgroundColor.A = 0) AND (Button.Style.BorderColor.A = 0), 'Quiet button has no resting surface or border');
    SetThemeLineHeight(Theme, 29);
    GuiApplyTheme(Memo, Theme);
    Check(Memo.LineHeight = 29, 'Memo gets memo metrics instead of edit metrics');
    Canvas.DrawSurface(GuiImageDrawable(Pointer(1), GuiRect(0, 0, 8, 8)), GuiRect(0, 0, 40, 40), 6);
    Check((Canvas.ImageCount = 1) AND (Canvas.FillCount = 0), 'Rounded surface preserves image drawable dispatch');
    Canvas.ImageCount:=0;
    Canvas.DrawSurface(GuiNineSliceDrawable(Pointer(1), GuiRect(0, 0, 8, 8), GuiBox(2)), GuiRect(0, 0, 40, 40), 6);
    Check((Canvas.ImageCount = 9) AND (Canvas.FillCount = 0), 'Rounded surface preserves nine-slice dispatch');
    Canvas.FillRoundedRect(GuiRect(0, 0, 1000, 1000), 6, GuiColor(255, 255, 255));
    Check(Canvas.FillCount < 100, 'Large rounded panels batch straight sections');
  finally
    Canvas.Free;
    Memo.Free;
    Button.Free;
  end;
end;

begin
  try
    TestStyles;
    TestActivityAndSwitch;
    TestThreeStateCheckBox;
    TestPageIndicator;
    TestMarqueeProgress;
    TestSpeedButtonsAndToolbar;
    TestSeparatorBounds;
    TestToolbarAliases;
    TestTabButtons;
    TestRadioState;
    TestRadioGroup;
    TestSliderModes;
    TestSliderLifetime;
    TestKnobLifetime;
    TestKnobWrapLifetime;
    TestRoundButton;
    TestCircularKnob;
    TestKnobInputModes;
    TestKnobBoundaries;
    TestStateStrings;
    TestCheckListBox;
    TestSwitchListBox;
    TestDelegateLifetime;
    TestDelayButton;
    TestRangeSlider;
    TestRangeSliderLifetime;
    TestWheelPicker;
    TestWheelMotion;
    TestWheelLifetime;
    TestSpinStepping;
    TestSpinEditing;
    TestSpinRepeat;
    TestSpinModification;
    TestComboState;
    TestComboLayout;
    TestComboKeyboard;
    TestComboEditing;
    TestComboCompletion;
    TestComboTypeAhead;
    TestTabFoundation;
    TestTabLifetime;
    TestDisabledTabs;
    TestTabOverflow;
    TestTabPosition;
    TestTabWidths;
    TestTabMotion;
    TestButtonRepeat;
    TestButtonHold;
    TestButtonCallbackLifetime;
    TestFocusAppearance;
    TestScrollRefinement;
    TestScrollGeometryConsistency;
    TestListViewHeaderWidth;
    TestColumnResizing;
    TestTableFeatures;
    TestPopupScrollbars;
    TestMenus;
    TestDialogWindows;
    TestDialogOptions;
    TestInteractionPolish;
    TestWindowButtons;
    TestWrapping;
    TestGraphemeEditing;
    TestListBoxScrolling;
    TestCore;
    TestEditing;
    TestWidgets;
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.Message);
      Halt(1);
    end;
  end;
end.
