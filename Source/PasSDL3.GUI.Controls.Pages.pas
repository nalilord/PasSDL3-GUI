unit PasSDL3.GUI.Controls.Pages;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  Math,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.StateStrings,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Core,
  PasSDL3.GUI.Controls.Buttons,
  PasSDL3.GUI.Controls.Containers;

type
  TGuiTabButton = class(TGuiSpeedButton)
  protected
    procedure DrawControlBorder(ACanvas: TGuiCanvas; const ARect: TGuiRect;
      const AColor: TGuiColor; AWidth: TGuiFloat = -1); override;
  public
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
  end;

  TGuiPageIndicator = class(TGuiControl)
  private
    FCount,FSelectedIndex,FMaxVisibleDots,FPressedIndex: Integer;
    FInteractive: Boolean;
    FDotSize,FSpacing: TGuiFloat;
    FOnSelect: TGuiNotifyEvent;
    procedure SetCount(AValue: Integer);
    procedure SetSelectedIndex(AValue: Integer);
    procedure SetInteractive(AValue: Boolean);
    procedure SetMaxVisibleDots(AValue: Integer);
    procedure SetDotSize(AValue: TGuiFloat);
    procedure SetSpacing(AValue: TGuiFloat);
    procedure DotLayout(out AFirst,ANumber: Integer; out ARect: TGuiRect; out AStep: TGuiFloat);
    function IndexAtPoint(const APoint: TGuiPoint): Integer;
  protected
    procedure PaintIndicator(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect;
      ASelected,APressed: Boolean); virtual;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
    procedure DoClick; override;
  public
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function HitTest(const APoint: TGuiPoint): TGuiControl; override;
    property Count: Integer read FCount write SetCount;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property Interactive: Boolean read FInteractive write SetInteractive;
    property DotSize: TGuiFloat read FDotSize write SetDotSize;
    property Spacing: TGuiFloat read FSpacing write SetSpacing;
    property MaxVisibleDots: Integer read FMaxVisibleDots write SetMaxVisibleDots;
    property OnSelect: TGuiNotifyEvent read FOnSelect write FOnSelect;
  end;

  TGuiTabPosition = (gtpTop, gtpBottom);

  TGuiTabControl = class(TGuiControl)
  private type
    PTabEventGuard = ^TTabEventGuard;
    TTabEventGuard = record
    private
      FPrevious: PTabEventGuard;
      FAlive: Boolean;
    public
      property Previous: PTabEventGuard read FPrevious write FPrevious;
      property Alive: Boolean read FAlive write FAlive;
    end;
  private
    FTabEventGuard: PTabEventGuard;
  private
    FDragScroll,FFlickEnabled,FPointerDown,FDragging,FAnimating,FSuppressClick: Boolean;
    FDragIndex: Integer;
    FDragStartX,FDragStartOffset,FLastDragOffset,FDeceleration: TGuiFloat;
    FGestureBounds: TGuiRect;
    FGestureContent: TGuiFloat;
    FSampleTime,FMotionStart: UInt64;
    FVelocity,FStartVelocity,FStartOffset: Double;
    procedure CancelTabMotion;
    procedure UpdateTabMotion;
    function GetMoving: Boolean;
    procedure SetDragScroll(AValue: Boolean);
    procedure SetFlickEnabled(AValue: Boolean);
    procedure SetDeceleration(AValue: TGuiFloat);
  private
    FAutoSizeTabs,FLayoutValid: Boolean;
    FLayoutWidth: TGuiFloat;
    FTabOffsets,FLayoutWidths,FMeasuredWidths: array of TGuiFloat;
    FTabMetricsKey: String;
    procedure SetAutoSizeTabs(AValue: Boolean);
    function GetItemWidth(AIndex: Integer): TGuiFloat;
    procedure SetItemWidth(AIndex: Integer; AValue: TGuiFloat);
    procedure UpdateTabMetrics(ACanvas: TGuiCanvas);
    procedure EnsureTabLayout;
    function GetContentWidth: TGuiFloat;
  private
    FTabPosition: TGuiTabPosition;
    FTabWidth,FMinTabWidth,FScrollOffset,FLastHeaderWidth: TGuiFloat;
    FRevealSelection: Boolean;
    procedure SetTabPosition(AValue: TGuiTabPosition);
    procedure SetTabWidth(AValue: TGuiFloat);
    procedure SetMinTabWidth(AValue: TGuiFloat);
    procedure SetScrollOffset(AValue: TGuiFloat);
    function GetScrollOffset: TGuiFloat;
    function GetHeaderViewport: TGuiRect;
    function GetMaxScrollOffset: TGuiFloat;
    procedure NormalizeTabScroll;
  private
    function GetTabEnabled(AIndex: Integer): Boolean;
    procedure SetTabEnabled(AIndex: Integer; AValue: Boolean);
    function FindEnabledTab(AStart, ADirection: Integer): Integer;
  private
    FSyncingItems: Boolean;
    FItemsCount,FItemsRevision: Integer;
    FSelectionCaption: String;
    procedure ItemsChanged(Sender: TObject);
    procedure ApplySelection(AIndex: Integer; AReplaced: Boolean);
    procedure SetTabHeight(AValue: TGuiFloat);
  private
    FItems: TStringList;
    FSelectedIndex: Integer;
    FTabHeight: TGuiFloat;
    FOnSelect: TGuiNotifyEvent;
    procedure SetSelectedIndex(AValue: Integer);
    function TabIndexAtPoint(const APoint: TGuiPoint): Integer;
  protected
    function AnimationTime: UInt64; virtual;
    procedure DoClick; override;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddTab(const ACaption: String): Integer;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function TabRect(AIndex: Integer): TGuiRect;
    procedure ScrollTabIntoView(AIndex: Integer);
    property TabWidth: TGuiFloat read FTabWidth write SetTabWidth;
    property ItemWidths[AIndex: Integer]: TGuiFloat read GetItemWidth write SetItemWidth;
    property AutoSizeTabs: Boolean read FAutoSizeTabs write SetAutoSizeTabs;
    property DragScroll: Boolean read FDragScroll write SetDragScroll;
    property FlickEnabled: Boolean read FFlickEnabled write SetFlickEnabled;
    property Deceleration: TGuiFloat read FDeceleration write SetDeceleration;
    property Moving: Boolean read GetMoving;
    property ContentWidth: TGuiFloat read GetContentWidth;
    property MinTabWidth: TGuiFloat read FMinTabWidth write SetMinTabWidth;
    property ScrollOffset: TGuiFloat read GetScrollOffset write SetScrollOffset;
    property MaxScrollOffset: TGuiFloat read GetMaxScrollOffset;
    property HeaderViewport: TGuiRect read GetHeaderViewport;
    property TabEnabled[AIndex: Integer]: Boolean read GetTabEnabled write SetTabEnabled;
    property Items: TStringList read FItems;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property TabHeight: TGuiFloat read FTabHeight write SetTabHeight;
    property TabPosition: TGuiTabPosition read FTabPosition write SetTabPosition;
    property OnSelect: TGuiNotifyEvent read FOnSelect write FOnSelect;
  end;

  TGuiPage = class(TGuiPanel)
  public
    constructor Create; override;
  end;

  TGuiPageControl = class(TGuiControl)
  private
    FPages: TList;
    FSelectedIndex: Integer;
    FTabHeight: TGuiFloat;
    FOnSelect: TGuiNotifyEvent;
    procedure SetSelectedIndex(AValue: Integer);
    function GetPageCount: Integer;
    function GetPages(AIndex: Integer): TGuiPage;
    function TabIndexAtPoint(const APoint: TGuiPoint): Integer;
    function PageBounds: TGuiRect;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddPage(const ACaption: String): TGuiPage;
    procedure Remove(AControl: TGuiControl); override;
    procedure Arrange(const ABounds: TGuiRect); override;
    procedure Paint(ACanvas: TGuiCanvas); override;
    procedure PaintOverlay(ACanvas: TGuiCanvas); override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function HitTest(const APoint: TGuiPoint): TGuiControl; override;
    function DispatchShortcut(var AEvent: TGuiEvent): Boolean; override;
    property PageCount: Integer read GetPageCount;
    property Pages[AIndex: Integer]: TGuiPage read GetPages;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property TabHeight: TGuiFloat read FTabHeight write FTabHeight;
    property OnSelect: TGuiNotifyEvent read FOnSelect write FOnSelect;
  end;

implementation

type
  TGuiTabItems = class(TGuiIdentityStrings)
  private
    FWidths: array of TGuiFloat;
    function GetWidth(AIndex: Integer): TGuiFloat;
    procedure SetWidth(AIndex: Integer; AValue: TGuiFloat);
  protected
    procedure InsertItem(Index: Integer; const S: string; AObject: TObject);
    override;
  public
    procedure Clear;
    override;
    procedure Delete(Index: Integer);
    override;
    procedure Exchange(Index1,Index2: Integer);
    override;
    property Widths[Index: Integer]: TGuiFloat read GetWidth write SetWidth;
  end;

function TGuiTabItems.GetWidth(AIndex: Integer): TGuiFloat;
begin
  if (AIndex<0) OR (AIndex>=Count) then raise EStringListError.Create('Invalid tab width index');
  Result:=FWidths[AIndex];
end;

procedure TGuiTabItems.SetWidth(AIndex: Integer; AValue: TGuiFloat);
begin
  if GetWidth(AIndex)=AValue then Exit;
  Changing;
  FWidths[AIndex]:=AValue;
  Changed;
end;

procedure TGuiTabItems.InsertItem(Index: Integer; const S: string; AObject: TObject);
var I: Integer;
begin
  BeginUpdate;
  try
    inherited;
    SetLength(FWidths,Count);
    for I:=Count-1 downto Index+1 do FWidths[I]:=FWidths[I-1];
    FWidths[Index]:=0;
  finally
    EndUpdate;
  end;
end;

procedure TGuiTabItems.Clear;
begin
  BeginUpdate;
  try
    inherited;
    SetLength(FWidths,0);
  finally
    EndUpdate;
  end;
end;

procedure TGuiTabItems.Delete(Index: Integer);
var I: Integer;
begin
  BeginUpdate;
  try
    inherited;
    for I:=Index to Count-1 do FWidths[I]:=FWidths[I+1];
    SetLength(FWidths,Count);
  finally
    EndUpdate;
  end;
end;

procedure TGuiTabItems.Exchange(Index1,Index2: Integer);
var Width: TGuiFloat;
begin
  BeginUpdate;
  try
    inherited;
    Width:=FWidths[Index1];
    FWidths[Index1]:=FWidths[Index2];
    FWidths[Index2]:=Width;
  finally
    EndUpdate;
  end;
end;

constructor TGuiTabButton.Create;
begin
  inherited Create;
  Bounds:=GuiRect(0,0,120,36);
  Padding:=GuiBoxLTRB(10,4,10,4);
  Checkable:=True;
  GroupIndex:=1;
end;

procedure TGuiTabButton.DrawControlBorder(ACanvas: TGuiCanvas; const ARect: TGuiRect;
  const AColor: TGuiColor; AWidth: TGuiFloat);
var R: TGuiRect;
Color: TGuiColor;
Inset: TGuiFloat;
begin
  R:=ARect;
  R.Top:=R.Top+Max(0,R.Height-1);
  R.Height:=Min(1,R.Height);
  Color:=Style.BorderColor;
  if Down then
  begin
    Inset:=Min(8,Max(0,ARect.Width)/4);
    R:=GuiRect(ARect.Left+Inset,ARect.Top+Max(0,ARect.Height-2),
      Max(0,ARect.Width-2*Inset),Min(2,ARect.Height));
    Color:=Style.CheckedBorderColor;
  end;
  if NOT Enabled AND Down then Color:=Style.DisabledTextColor;
  if (R.Width>0) AND (R.Height>0) then ACanvas.FillRect(R,Color);
end;

procedure TGuiTabButton.HandleEvent(var AEvent: TGuiEvent);
var Step,I,N,Start: Integer;
Candidate: TGuiTabButton;
begin
  inherited;
  if NOT Enabled OR (AEvent.Kind<>gekKeyDown) OR NOT Assigned(Parent) OR (GroupIndex=0) then Exit;
  Step:=0;
  case AEvent.KeyCode of
    $40000050,$40000052: Step:=-1;
    $4000004F,$40000051: Step:=1;
    else Exit;
  end;
  N:=Parent.ChildCount;
  Start:=Parent.IndexOfChild(Self);
  for I:=1 to N-1 do
    if Parent.Children[(Start+Step*I+N) MOD N] IS TGuiTabButton then
    begin
      Candidate:=TGuiTabButton(Parent.Children[(Start+Step*I+N) MOD N]);
      if (Candidate.GroupIndex=GroupIndex) AND Candidate.Visible AND Candidate.Enabled AND Candidate.CanFocus then
      begin
        if Assigned(Context) then Context.SetFocus(Candidate);
        Candidate.Down:=True;
        AEvent.Handled:=True;
        Exit;
      end;
    end;
  AEvent.Handled:=True;
end;

constructor TGuiPageIndicator.Create;
begin
  inherited Create;
  Bounds:=GuiRect(0,0,160,28);
  FSelectedIndex:=-1;
  FPressedIndex:=-1;
  FDotSize:=10;
  FSpacing:=8;
  FMaxVisibleDots:=9;
  CanFocus:=False;
  TabStop:=False;
end;

procedure TGuiPageIndicator.SetCount(AValue: Integer);
begin
  AValue:=Max(0,AValue);
  if FCount=AValue then Exit;
  FCount:=AValue;
  FPressedIndex:=-1;
  Pressed:=False;
  CanFocus:=FInteractive AND (FCount>0);
  TabStop:=CanFocus;
  SetSelectedIndex(FSelectedIndex);
end;

procedure TGuiPageIndicator.SetSelectedIndex(AValue: Integer);
begin
  if FCount=0 then AValue:=-1 else AValue:=EnsureRange(AValue,0,FCount-1);
  if FSelectedIndex=AValue then Exit;
  FSelectedIndex:=AValue;
  if Assigned(FOnSelect) then FOnSelect(Self);
end;

procedure TGuiPageIndicator.SetInteractive(AValue: Boolean);
begin
  FInteractive:=AValue;
  CanFocus:=AValue AND (FCount>0);
  TabStop:=CanFocus;
  if AValue then Cursor:=gmcHand else Cursor:=gmcArrow;
  if NOT AValue then
  begin
    FPressedIndex:=-1;
    Pressed:=False;
  end;
end;

procedure TGuiPageIndicator.SetMaxVisibleDots(AValue: Integer);
begin
  FMaxVisibleDots:=EnsureRange(AValue,1,1024);
end;

procedure TGuiPageIndicator.SetDotSize(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Invalid indicator dot size');
  FDotSize:=EnsureRange(AValue,1,4096);
end;

procedure TGuiPageIndicator.SetSpacing(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Invalid indicator spacing');
  FSpacing:=EnsureRange(AValue,0,4096);
end;

procedure TGuiPageIndicator.DotLayout(out AFirst,ANumber: Integer; out ARect: TGuiRect; out AStep: TGuiFloat);
var R: TGuiRect;
Width: TGuiFloat;
begin
  AFirst:=0;
  ANumber:=0;
  ARect:=GuiRect(0,0,0,0);
  AStep:=FDotSize+FSpacing;
  R:=GuiInflateRect(AbsoluteBounds,Padding);
  if (FCount=0) OR (R.Width<=0) OR (R.Height<=0) then Exit;
  ANumber:=Min(FCount,FMaxVisibleDots);
  if R.Width<ANumber*AStep-FSpacing then
    ANumber:=Max(1,Floor((R.Width+FSpacing)/AStep));
  AFirst:=EnsureRange(FSelectedIndex-ANumber DIV 2,0,FCount-ANumber);
  Width:=ANumber*AStep-FSpacing;
  ARect:=GuiRect(R.Left+(R.Width-Width)/2,R.Top+(R.Height-FDotSize)/2,FDotSize,FDotSize);
end;

function TGuiPageIndicator.IndexAtPoint(const APoint: TGuiPoint): Integer;
var First,N,I: Integer;
R: TGuiRect;
Step: TGuiFloat;
begin
  Result:=-1;
  if NOT GuiRectContains(GuiInflateRect(AbsoluteBounds,Padding),APoint) then Exit;
  DotLayout(First,N,R,Step);
  if N=0 then Exit;
  if (APoint.X<R.Left-FSpacing/2) OR (APoint.X>=R.Left+(N-1)*Step+R.Width+FSpacing/2) then Exit;
  I:=Floor((APoint.X-R.Left+FSpacing/2)/Step);
  if (I>=0) AND (I<N) then Result:=First+I;
end;

function TGuiPageIndicator.HitTest(const APoint: TGuiPoint): TGuiControl;
begin
  Result:=nil;
  if FInteractive AND (FCount>0) then Result:=inherited HitTest(APoint);
end;

procedure TGuiPageIndicator.DoClick;
begin
  if FInteractive AND Enabled AND (FCount>0) then inherited DoClick;
end;

procedure TGuiPageIndicator.HandleEvent(var AEvent: TGuiEvent);
var Index: Integer;
begin
  inherited HandleEvent(AEvent);
  if (AEvent.Kind IN [gekCancel,gekBlur]) OR NOT Enabled OR NOT FInteractive then
  begin
    FPressedIndex:=-1;
    Pressed:=False;
    Exit;
  end;
  case AEvent.Kind of
    gekMouseDown:
      if AEvent.Button=gmbLeft then
      begin
        Index:=IndexAtPoint(AEvent.Position);
        FPressedIndex:=Index;
        AEvent.Handled:=Index>=0;
        if Index>=0 then SetSelectedIndex(Index);
      end;
    gekMouseUp: FPressedIndex:=-1;
    gekKeyDown:
      begin
        Index:=FSelectedIndex;
        case AEvent.KeyCode of
          $40000050,$40000052: Dec(Index);
          $4000004F,$40000051: Inc(Index);
          $4000004A: Index:=0;
          $4000004D: Index:=FCount-1;
          else Exit;
        end;
        AEvent.Handled:=True;
        SetSelectedIndex(Index);
      end;
    gekMouseWheel:
      begin
        Index:=FSelectedIndex;
        if AEvent.Delta.Y>0 then Dec(Index) else if AEvent.Delta.Y<0 then Inc(Index);
        if FCount=0 then Exit;
        Index:=EnsureRange(Index,0,FCount-1);
        AEvent.Handled:=Index<>FSelectedIndex;
        SetSelectedIndex(Index);
      end;
  end;
end;

procedure TGuiPageIndicator.PaintIndicator(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect;
  ASelected,APressed: Boolean);
var Color: TGuiColor;
begin
  Color:=Style.BorderColor;
  if ASelected then Color:=Style.CheckedBorderColor;
  if APressed then Color:=Style.FocusedBorderColor;
  if NOT Enabled then Color:=Style.DisabledTextColor;
  if NOT ASelected then Color.A:=Round(Color.A*0.5);
  ACanvas.FillRoundedRect(ARect,ARect.Width/2,Color);
end;

procedure TGuiPageIndicator.PaintSelf(ACanvas: TGuiCanvas);
var First,N,I: Integer;
R: TGuiRect;
Step: TGuiFloat;
begin
  DotLayout(First,N,R,Step);
  if N=0 then Exit;
  ACanvas.PushClipRect(AbsoluteBounds);
  try
    for I:=0 to N-1 do
    begin
      PaintIndicator(ACanvas,First+I,R,FSelectedIndex=First+I,Pressed AND (FPressedIndex=First+I));
      R.Left:=R.Left+Step;
    end;
    if FInteractive AND Focused AND FocusVisible then GuiPaintFocusIndicator(ACanvas,AbsoluteBounds,Style);
  finally
    ACanvas.PopClipRect;
  end;
end;

constructor TGuiTabControl.Create;
begin
  inherited Create;
  FDragScroll:=True;
  FFlickEnabled:=True;
  FDeceleration:=2500;
  FItems:=TGuiTabItems.Create;
  FItems.OnChange:=ItemsChanged;
  FSelectedIndex:=-1;
  FTabHeight:=32;
  CanFocus:=True;
  TabStop:=True;
  Padding:=GuiBox(0);
end;

destructor TGuiTabControl.Destroy;
var Guard: PTabEventGuard;
begin
  Guard:=FTabEventGuard;
  while Guard<>nil do
  begin
    Guard^.Alive:=False;
    Guard:=Guard^.Previous;
  end;
  FItems.Free;
  inherited Destroy;
end;

function TGuiTabControl.AddTab(const ACaption: String): Integer;
begin
  Result:=FItems.Add(ACaption);
end;

procedure TGuiTabControl.SetSelectedIndex(AValue: Integer);
begin
  CancelTabMotion;
  AValue:=EnsureRange(AValue,-1,FItems.Count-1);
  if (AValue>=0) AND NOT TabEnabled[AValue] then Exit;
  ApplySelection(AValue,False);
end;

function TGuiTabControl.GetTabEnabled(AIndex: Integer): Boolean;
begin
  Result:=(TGuiStateStrings(FItems).ItemState[AIndex] AND 2)=0;
end;

procedure TGuiTabControl.SetTabEnabled(AIndex: Integer; AValue: Boolean);
var State: Integer;
begin
  State:=TGuiStateStrings(FItems).ItemState[AIndex];
  TGuiStateStrings(FItems).ItemState[AIndex]:=(State AND NOT 2) OR (Ord(NOT AValue)*2);
end;

function TGuiTabControl.FindEnabledTab(AStart, ADirection: Integer): Integer;
begin
  Result:=AStart;
  while (Result>=0) AND (Result<FItems.Count) do
  begin
    if TabEnabled[Result] then Exit;
    Inc(Result,ADirection);
  end;
  Result:=-1;
end;

procedure TGuiTabControl.SetTabHeight(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<=0) then
    raise EArgumentException.Create('Tab height must be positive and finite');
  CancelTabMotion;
  FTabHeight:=AValue;
  InvalidateLayout;
end;

procedure TGuiTabControl.SetTabPosition(AValue: TGuiTabPosition);
begin
  if NOT (AValue IN [gtpTop,gtpBottom]) then raise EArgumentException.Create('Invalid tab position');
  if FTabPosition=AValue then Exit;
  CancelTabMotion;
  FTabPosition:=AValue;
  Pressed:=False;
  InvalidateLayout;
end;

procedure TGuiTabControl.SetTabWidth(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<0) then
    raise EArgumentException.Create('Tab width must be nonnegative and finite');
  CancelTabMotion;
  FTabWidth:=AValue;
  FLayoutValid:=False;
  FRevealSelection:=True;
  NormalizeTabScroll;
  InvalidateLayout;
end;

procedure TGuiTabControl.SetMinTabWidth(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<0) then
    raise EArgumentException.Create('Minimum tab width must be nonnegative and finite');
  CancelTabMotion;
  FMinTabWidth:=AValue;
  FLayoutValid:=False;
  FRevealSelection:=True;
  NormalizeTabScroll;
  InvalidateLayout;
end;

procedure TGuiTabControl.SetAutoSizeTabs(AValue: Boolean);
begin
  if FAutoSizeTabs=AValue then Exit;
  CancelTabMotion;
  FAutoSizeTabs:=AValue;
  FLayoutValid:=False;
  FRevealSelection:=True;
  NormalizeTabScroll;
  InvalidateLayout;
end;

function TGuiTabControl.GetItemWidth(AIndex: Integer): TGuiFloat;
begin
  Result:=TGuiTabItems(FItems).Widths[AIndex];
end;

procedure TGuiTabControl.SetItemWidth(AIndex: Integer; AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<0) then
    raise EArgumentException.Create('Item width must be nonnegative and finite');
  TGuiTabItems(FItems).Widths[AIndex]:=AValue;
end;

procedure TGuiTabControl.UpdateTabMetrics(ACanvas: TGuiCanvas);
var I: Integer;
Key: String;
begin
  if NOT FAutoSizeTabs OR (FTabWidth<>0) then Exit;
  Key:=ACanvas.TextMetricsKey;
  if (Length(FMeasuredWidths)=FItems.Count) AND (FTabMetricsKey=Key) then Exit;
  CancelTabMotion;
  SetLength(FMeasuredWidths,FItems.Count);
  for I:=0 to FItems.Count-1 do FMeasuredWidths[I]:=Max(0,ACanvas.MeasureText(FItems[I]).Width)+24;
  FTabMetricsKey:=Key;
  FLayoutValid:=False;
  FRevealSelection:=True;
end;

procedure TGuiTabControl.EnsureTabLayout;
var I,Flexible: Integer;
Available,FixedWidth,Width: TGuiFloat;
begin
  Available:=Max(0,AbsoluteBounds.Width);
  if FLayoutValid AND (FLayoutWidth=Available) then Exit;
  SetLength(FLayoutWidths,FItems.Count);
  SetLength(FTabOffsets,FItems.Count+1);
  FixedWidth:=0;
  Flexible:=0;
  for I:=0 to FItems.Count-1 do
  begin
    Width:=ItemWidths[I];
    if Width=0 then Width:=FTabWidth;
    if (Width=0) AND FAutoSizeTabs then
    begin
      if Length(FMeasuredWidths)=FItems.Count then Width:=FMeasuredWidths[I]
      else Width:=Length(FItems[I])*8+24;
    end;
    if Width=0 then Inc(Flexible)
    else
    begin
      Width:=Max(FMinTabWidth,Width);
      FixedWidth:=FixedWidth+Width;
    end;
    FLayoutWidths[I]:=Width;
  end;
  Width:=0;
  if Flexible>0 then
  begin
    Width:=Max(0,Available-FixedWidth)/Flexible;
    { An over-constrained strip must scroll, not hide its flexible tabs. }
    if Width=0 then Width:=Max(24,Available/FItems.Count);
  end;
  FTabOffsets[0]:=0;
  for I:=0 to FItems.Count-1 do
  begin
    if FLayoutWidths[I]=0 then FLayoutWidths[I]:=Max(FMinTabWidth,Width);
    FTabOffsets[I+1]:=FTabOffsets[I]+FLayoutWidths[I];
  end;
  FLayoutWidth:=Available;
  FLayoutValid:=True;
end;

function TGuiTabControl.GetContentWidth: TGuiFloat;
begin
  EnsureTabLayout;
  Result:=FTabOffsets[FItems.Count];
end;

function TGuiTabControl.GetHeaderViewport: TGuiRect;
var ButtonWidth: TGuiFloat;
begin
  Result:=AbsoluteBounds;
  Result.Width:=Max(0,Result.Width);
  Result.Height:=Min(FTabHeight,Max(0,Result.Height));
  if FTabPosition=gtpBottom then Result.Top:=AbsoluteBounds.Top+Max(0,AbsoluteBounds.Height)-Result.Height;
  if ContentWidth>Result.Width then
  begin
    ButtonWidth:=Min(24,Result.Width/3);
    Result.Left:=Result.Left+ButtonWidth;
    Result.Width:=Result.Width-2*ButtonWidth;
  end;
end;

function TGuiTabControl.GetMaxScrollOffset: TGuiFloat;
begin
  Result:=Max(0,ContentWidth-HeaderViewport.Width);
end;

procedure TGuiTabControl.NormalizeTabScroll;
var Width,ItemWidth,Start: TGuiFloat;
begin
  Width:=HeaderViewport.Width;
  if (FRevealSelection OR (Width<>FLastHeaderWidth)) AND (FSelectedIndex>=0) then
  begin
    Start:=FTabOffsets[FSelectedIndex];
    ItemWidth:=FLayoutWidths[FSelectedIndex];
    if Start<FScrollOffset then FScrollOffset:=Start
    else if Start+ItemWidth>FScrollOffset+Width then
      FScrollOffset:=Min(Start,Start+ItemWidth-Width);
  end;
  FScrollOffset:=EnsureRange(FScrollOffset,0,GetMaxScrollOffset);
  FLastHeaderWidth:=Width;
  FRevealSelection:=False;
end;

procedure TGuiTabControl.SetScrollOffset(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Tab scroll offset must be finite');
  CancelTabMotion;
  NormalizeTabScroll;
  FScrollOffset:=EnsureRange(AValue,0,GetMaxScrollOffset);
end;

function TGuiTabControl.GetScrollOffset: TGuiFloat;
begin
  UpdateTabMotion;
  NormalizeTabScroll;
  Result:=FScrollOffset;
end;

function TGuiTabControl.TabRect(AIndex: Integer): TGuiRect;
begin
  if (AIndex<0) OR (AIndex>=FItems.Count) then raise EStringListError.Create('Invalid tab index');
  NormalizeTabScroll;
  Result:=HeaderViewport;
  Result.Left:=Result.Left+FTabOffsets[AIndex]-FScrollOffset;
  Result.Width:=FLayoutWidths[AIndex];
end;

procedure TGuiTabControl.ScrollTabIntoView(AIndex: Integer);
var R,Viewport: TGuiRect;
begin
  CancelTabMotion;
  R:=TabRect(AIndex);
  Viewport:=HeaderViewport;
  if R.Left<Viewport.Left then ScrollOffset:=FScrollOffset+R.Left-Viewport.Left
  else if R.Left+R.Width>Viewport.Left+Viewport.Width then
    ScrollOffset:=FScrollOffset+R.Left-Viewport.Left+Min(0,R.Width-Viewport.Width);
end;

procedure TGuiTabControl.ApplySelection(AIndex: Integer; AReplaced: Boolean);
var I: Integer;
NewCaption: String;
Changed: Boolean;
begin
  AIndex:=EnsureRange(AIndex,-1,FItems.Count-1);
  NewCaption:='';
  if AIndex>=0 then NewCaption:=FItems[AIndex];
  Changed:=AReplaced OR (AIndex<>FSelectedIndex) OR (NewCaption<>FSelectionCaption);
  FSelectedIndex:=AIndex;
  FSelectionCaption:=NewCaption;
  FSyncingItems:=True;
  try
    for I:=0 to FItems.Count-1 do
      TGuiStateStrings(FItems).ItemState[I]:=(
        TGuiStateStrings(FItems).ItemState[I] AND NOT 1) OR Ord(I=AIndex);
  finally
    FSyncingItems:=False;
  end;
  FRevealSelection:=True;
  NormalizeTabScroll;
  if Changed AND Assigned(FOnSelect) then FOnSelect(Self);
end;

procedure TGuiTabControl.ItemsChanged(Sender: TObject);
var I,Index,NextIndex: Integer;
Replaced: Boolean;
begin
  if FSyncingItems then Exit;
  CancelTabMotion;
  FLayoutValid:=False;
  SetLength(FMeasuredWidths,0);
  Index:=-1;
  for I:=0 to FItems.Count-1 do
    if (TGuiStateStrings(FItems).ItemState[I] AND 1)<>0 then
    begin
      Index:=I;
      Break;
    end;
  Replaced:=(FSelectedIndex>=0) AND (Index<0);
  if Index<0 then
  begin
    Index:=Min(FSelectedIndex,FItems.Count-1);
    if (FItemsCount=0) AND (FItems.Count>0) then Index:=0;
  end;
  if (Index>=0) AND NOT TabEnabled[Index] then
  begin
    NextIndex:=FindEnabledTab(Index+1,1);
    if NextIndex<0 then NextIndex:=FindEnabledTab(Index-1,-1);
    Index:=NextIndex;
  end;
  FItemsCount:=FItems.Count;
  Inc(FItemsRevision);
  Pressed:=False;
  InvalidateLayout;
  ApplySelection(Index,Replaced);
end;

function TGuiTabControl.TabIndexAtPoint(const APoint: TGuiPoint): Integer;
var
  Rect: TGuiRect;
  X: TGuiFloat;
  I: Integer;
begin
  Result:=-1;

  if FItems.Count <= 0 then
    Exit;

  NormalizeTabScroll;
  Rect:=HeaderViewport;
  if NOT GuiRectContains(Rect,APoint) then
    Exit;

  X:=APoint.X-Rect.Left+FScrollOffset;
  for I:=0 to FItems.Count-1 do
    if (X>=FTabOffsets[I]) AND (X<FTabOffsets[I+1]) then
    begin
      Result:=I;
      Exit;
    end;
end;

procedure TGuiTabControl.PaintSelf(ACanvas: TGuiCanvas);
var
  I: Integer;
  Rect: TGuiRect;
  BodyRect: TGuiRect;
  ItemRect,Viewport,ButtonRect: TGuiRect;
  X,Y,Direction,Inset: TGuiFloat;
  States: TGuiControlVisualStates;
begin
  UpdateTabMetrics(ACanvas);
  UpdateTabMotion;
  NormalizeTabScroll;
  Rect:=AbsoluteBounds;
  Viewport:=HeaderViewport;
  ACanvas.PushClipRect(Rect);
  try
  BodyRect:=GuiRect(Rect.Left, Rect.Top + Min(FTabHeight,Max(0,Rect.Height)), Rect.Width, Max(0,Rect.Height - FTabHeight));
  if FTabPosition=gtpBottom then BodyRect.Top:=Rect.Top;
  ACanvas.DrawSurface(Style.Background, BodyRect, Style.CornerRadius);
  DrawControlBorder(ACanvas, BodyRect, Style.BorderColor);

  if FItems.Count > 0 then
  begin
    ACanvas.PushClipRect(Viewport);
    try
    for I:=0 to FItems.Count - 1 do
    begin
      States:=[gcvsNormal];
      if I = FSelectedIndex then
        Include(States, gcvsChecked);

      if NOT Enabled OR NOT TabEnabled[I] then
        Include(States, gcvsDisabled);

      ItemRect:=TabRect(I);
      if (ItemRect.Left+ItemRect.Width<=Viewport.Left) OR
        (ItemRect.Left>=Viewport.Left+Viewport.Width) then Continue;
      ACanvas.PushClipRect(ItemRect);
      try
      ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), ItemRect, Style.CornerRadius);
      if I = FSelectedIndex then
      begin
        Y:=ItemRect.Top+ItemRect.Height-3;
        if FTabPosition=gtpBottom then Y:=ItemRect.Top+1;
        Inset:=Min(8,Max(0,ItemRect.Width)/4);
        ACanvas.FillRoundedRect(GuiRect(ItemRect.Left + Inset, Y,
          Max(0, ItemRect.Width - 2*Inset), 2), 1, GuiResolveBorderColor(Style, States));
      end;
      DrawControlText(ACanvas, FItems[I], GuiInflateRect(ItemRect, GuiBoxLTRB(8, 2, 8, 2)), GuiResolveTextColor(Style, States), ghtaCenter, gvtaCenter);
      finally
        ACanvas.PopClipRect;
      end;
    end;
    finally
      ACanvas.PopClipRect;
    end;
  end;
  if GetMaxScrollOffset>0 then
  begin
    for I:=0 to 1 do
    begin
      ButtonRect:=GuiRect(Rect.Left,Viewport.Top,Viewport.Left-Rect.Left,Viewport.Height);
      Direction:=-1;
      if I=1 then
      begin
        ButtonRect.Left:=Viewport.Left+Viewport.Width;
        Direction:=1;
      end;
      States:=[gcvsNormal];
      if NOT Enabled OR ((I=0) AND (FScrollOffset<=0)) OR
        ((I=1) AND (FScrollOffset>=GetMaxScrollOffset)) then Include(States,gcvsDisabled);
      ACanvas.PushClipRect(ButtonRect);
      try
      ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style,States),ButtonRect,Style.CornerRadius);
      X:=ButtonRect.Left+ButtonRect.Width/2;
      Y:=ButtonRect.Top+ButtonRect.Height/2;
      ACanvas.DrawLine(GuiPoint(X-2*Direction,Y-4),GuiPoint(X+2*Direction,Y),1.5,GuiResolveTextColor(Style,States));
      ACanvas.DrawLine(GuiPoint(X+2*Direction,Y),GuiPoint(X-2*Direction,Y+4),1.5,GuiResolveTextColor(Style,States));
      finally
        ACanvas.PopClipRect;
      end;
    end;
  end;

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, Rect, Style);
  finally
    ACanvas.PopClipRect;
  end;
end;

function TGuiTabControl.AnimationTime: UInt64;
begin
  Result:=TThread.GetTickCount64;
end;

procedure TGuiTabControl.CancelTabMotion;
begin
  if FPointerDown OR FDragging then FSuppressClick:=True;
  FPointerDown:=False;
  FDragging:=False;
  FAnimating:=False;
  FVelocity:=0;
  Pressed:=False;
end;

procedure TGuiTabControl.SetDragScroll(AValue: Boolean);
begin
  CancelTabMotion;
  FDragScroll:=AValue;
end;

procedure TGuiTabControl.SetFlickEnabled(AValue: Boolean);
begin
  CancelTabMotion;
  FFlickEnabled:=AValue;
end;

procedure TGuiTabControl.SetDeceleration(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<=0) then
    raise EArgumentException.Create('Tab deceleration must be positive and finite');
  CancelTabMotion;
  FDeceleration:=AValue;
end;

function TGuiTabControl.GetMoving: Boolean;
begin
  UpdateTabMotion;
  Result:=FDragging OR FAnimating;
end;

procedure TGuiTabControl.UpdateTabMotion;
var Ancestor: TGuiControl;
R: TGuiRect;
NowValue: UInt64;
  Elapsed,Time,StopTime,Offset,Direction,Limit: Double;
begin
  if NOT FPointerDown AND NOT FAnimating then Exit;
  Ancestor:=Self;
  while Assigned(Ancestor) do
  begin
    if NOT Ancestor.Enabled OR NOT Ancestor.Visible then
    begin
      CancelTabMotion;
      Exit;
    end;
    Ancestor:=Ancestor.Parent;
  end;
  if Assigned(Context) AND Assigned(Context.ModalControl) AND
    NOT Context.ControlContains(Context.ModalControl,Self) then
    begin
      CancelTabMotion;
      Exit;
    end;
  R:=AbsoluteBounds;
  if (R.Left<>FGestureBounds.Left) OR (R.Top<>FGestureBounds.Top) OR
    (R.Width<>FGestureBounds.Width) OR (R.Height<>FGestureBounds.Height) OR
    (ContentWidth<>FGestureContent) then
    begin
      CancelTabMotion;
      Exit;
    end;
  NowValue:=AnimationTime;
  if NowValue<FSampleTime then
  begin
    CancelTabMotion;
    Exit;
  end;
  if NOT FAnimating then Exit;
  if NowValue<FMotionStart then
  begin
    CancelTabMotion;
    Exit;
  end;
  Elapsed:=(NowValue-FMotionStart)/1000;
  StopTime:=Abs(FStartVelocity)/FDeceleration;
  Time:=Min(Elapsed,StopTime);
  Direction:=1;
  if FStartVelocity<0 then Direction:=-1;
  Offset:=FStartOffset+Direction*(Abs(FStartVelocity)*Time-FDeceleration*Time*Time/2);
  Limit:=GetMaxScrollOffset;
  FScrollOffset:=EnsureRange(Offset,0,Limit);
  if (Elapsed>=StopTime) OR (Offset<=0) OR (Offset>=Limit) then FAnimating:=False;
end;

procedure TGuiTabControl.DoClick;
begin
  if Enabled AND NOT FSuppressClick then inherited;
end;

procedure TGuiTabControl.HandleEvent(var AEvent: TGuiEvent);
var
  Index,Revision: Integer;
  Viewport,Header: TGuiRect;
  NowValue,Elapsed: UInt64;
  Delta: Double;
  Guard: TTabEventGuard;
begin
  Guard.Previous:=FTabEventGuard;
  Guard.Alive:=True;
  FTabEventGuard:=@Guard;
  try
  if AEvent.Kind IN [gekCancel,gekBlur] then
  begin
    CancelTabMotion;
    inherited;
    Exit;
  end;
  UpdateTabMotion;
  if NOT Enabled then
  begin
    CancelTabMotion;
    Exit;
  end;
  if (AEvent.Kind IN [gekMouseDown,gekMouseUp]) AND (AEvent.Button<>gmbLeft) then Exit;
  if AEvent.Kind IN [gekMouseDown,gekKeyDown,gekMouseWheel] then CancelTabMotion;
  if AEvent.Kind IN [gekMouseDown,gekKeyDown] then FSuppressClick:=False;
  if AEvent.Kind=gekMouseDown then
  begin
    Index:=TabIndexAtPoint(AEvent.Position);
    if (Index>=0) AND NOT TabEnabled[Index] AND NOT (FDragScroll AND (GetMaxScrollOffset>0)) then
    begin
      FSuppressClick:=True;
      AEvent.Handled:=True;
      Exit;
    end;
  end;
  Revision:=FItemsRevision;
  inherited HandleEvent(AEvent);
  if NOT Guard.Alive then Exit;
  if NOT Enabled then
  begin
    CancelTabMotion;
    Exit;
  end;
  if Revision<>FItemsRevision then
  begin
    AEvent.Handled:=True;
    Exit;
  end;

  NormalizeTabScroll;
  Viewport:=HeaderViewport;
  Header:=AbsoluteBounds;
  Header.Top:=Viewport.Top;
  Header.Height:=Viewport.Height;
  if (AEvent.Kind=gekMouseMove) AND FPointerDown then
  begin
    if Abs(AEvent.Position.X-FDragStartX)>=4 then FDragging:=True;
    if FDragging then
    begin
      FSuppressClick:=True;
      Pressed:=False;
      FScrollOffset:=EnsureRange(FDragStartOffset+FDragStartX-AEvent.Position.X,0,GetMaxScrollOffset);
      NowValue:=AnimationTime;
      if NowValue<FSampleTime then
      begin
        CancelTabMotion;
        AEvent.Handled:=True;
        Exit;
      end;
      Elapsed:=NowValue-FSampleTime;
      Delta:=FScrollOffset-FLastDragOffset;
      if Elapsed>120 then FVelocity:=0
      else if (Elapsed>0) AND (Delta<>0) then FVelocity:=EnsureRange(Delta*1000/Elapsed,-4000,4000);
      if Delta<>0 then
      begin
        FSampleTime:=NowValue;
        FLastDragOffset:=FScrollOffset;
      end;
    end;
    AEvent.Handled:=True;
    Exit;
  end;
  if (AEvent.Kind=gekMouseUp) AND FPointerDown then
  begin
    FPointerDown:=False;
    Pressed:=False;
    AEvent.Handled:=True;
    if FDragging then
    begin
      FDragging:=False;
      FSuppressClick:=True;
      NowValue:=AnimationTime;
      if NowValue<FSampleTime then
      begin
        CancelTabMotion;
        Exit;
      end;
      if NowValue-FSampleTime>120 then FVelocity:=0;
      FStartOffset:=FScrollOffset;
      FStartVelocity:=FVelocity;
      FMotionStart:=NowValue;
      FAnimating:=FFlickEnabled AND (Abs(FVelocity)>=20);
      Exit;
    end;
    Index:=TabIndexAtPoint(AEvent.Position);
    if (Index=FDragIndex) AND (Index>=0) AND TabEnabled[Index] then SelectedIndex:=Index
    else FSuppressClick:=True;
    Exit;
  end;
  if (GetMaxScrollOffset>0) AND GuiRectContains(Header,AEvent.Position) then
  begin
    if AEvent.Kind=gekMouseWheel then
    begin
      ScrollOffset:=FScrollOffset-(AEvent.Delta.X+AEvent.Delta.Y)*Max(32,Viewport.Width/2);
      AEvent.Handled:=True;
      Exit;
    end;
    if (AEvent.Kind=gekMouseDown) AND NOT GuiRectContains(Viewport,AEvent.Position) then
    begin
      if AEvent.Position.X<Viewport.Left then ScrollOffset:=FScrollOffset-Max(32,Viewport.Width*0.75)
      else ScrollOffset:=FScrollOffset+Max(32,Viewport.Width*0.75);
      Pressed:=False;
      FSuppressClick:=True;
      AEvent.Handled:=True;
      Exit;
    end;
  end;

  case AEvent.Kind of
    gekMouseDown:
    begin
      Index:=TabIndexAtPoint(AEvent.Position);
      if FDragScroll AND (GetMaxScrollOffset>0) AND GuiRectContains(Viewport,AEvent.Position) then
      begin
        FPointerDown:=True;
        FDragIndex:=Index;
        FDragStartX:=AEvent.Position.X;
        FDragStartOffset:=FScrollOffset;
        FLastDragOffset:=FScrollOffset;
        FSampleTime:=AnimationTime;
        FGestureBounds:=AbsoluteBounds;
        FGestureContent:=ContentWidth;
        AEvent.Handled:=True;
        Exit;
      end;
      if Index >= 0 then
      begin
        AEvent.Handled:=True;
        SelectedIndex:=Index;
      end;
    end;

    gekKeyDown:
    begin
      case AEvent.KeyCode of
        $40000050, $40000052:
        begin
          AEvent.Handled:=True;
          if FSelectedIndex<0 then Index:=FindEnabledTab(0,1)
          else Index:=FindEnabledTab(FSelectedIndex-1,-1);
          if Index>=0 then SelectedIndex:=Index;
        end;

        $4000004F, $40000051:
        begin
          AEvent.Handled:=True;
          Index:=FindEnabledTab(FSelectedIndex+1,1);
          if Index>=0 then SelectedIndex:=Index;
        end;
        $4000004A:
        begin
          AEvent.Handled:=True;
          Index:=FindEnabledTab(0,1);
          if Index>=0 then SelectedIndex:=Index;
        end;
        $4000004D:
        begin
          AEvent.Handled:=True;
          Index:=FindEnabledTab(FItems.Count-1,-1);
          if Index>=0 then SelectedIndex:=Index;
        end;
      end;
    end;
  end;
  finally
    if Guard.Alive then FTabEventGuard:=Guard.Previous;
  end;
end;

constructor TGuiPage.Create;
begin
  inherited Create;
  ClipChildren:=True;
  Padding:=GuiBox(8);
  StyleClass:='Surface';
end;

constructor TGuiPageControl.Create;
begin
  inherited Create;
  FPages:=TList.Create;
  FSelectedIndex:=-1;
  FTabHeight:=32;
  CanFocus:=True;
  TabStop:=True;
  Padding:=GuiBox(0);
end;

destructor TGuiPageControl.Destroy;
begin
  FreeAndNil(FPages);
  inherited Destroy;
end;

procedure TGuiPageControl.Remove(AControl: TGuiControl);
var
  Index, I: Integer;
begin
  if Assigned(FPages) then
  begin
    Index:=FPages.IndexOf(AControl);
    if Index >= 0 then
    begin
      FPages.Delete(Index);
      if Index < FSelectedIndex then Dec(FSelectedIndex);
      FSelectedIndex:=Min(FSelectedIndex, FPages.Count - 1);
      for I:=0 to FPages.Count - 1 do TGuiPage(FPages[I]).Visible:=I = FSelectedIndex;
    end;
  end;
  inherited Remove(AControl);
end;

function TGuiPageControl.AddPage(const ACaption: String): TGuiPage;
begin
  Result:=TGuiPage.Create;
  Result.Caption:=ACaption;
  Result.Visible:=False;
  FPages.Add(Result);
  inherited Add(Result);

  if FSelectedIndex < 0 then
    SelectedIndex:=0
  else
    Result.Visible:=FPages.IndexOf(Result) = FSelectedIndex;

  InvalidateLayout;
end;

procedure TGuiPageControl.SetSelectedIndex(AValue: Integer);
var
  I: Integer;
begin
  if AValue < -1 then
    AValue:=-1;

  if AValue >= FPages.Count then
    AValue:=FPages.Count - 1;

  if FSelectedIndex = AValue then
    Exit;

  FSelectedIndex:=AValue;
  for I:=0 to FPages.Count - 1 do
    TGuiPage(FPages[I]).Visible:=I = FSelectedIndex;

  if Assigned(FOnSelect) then
    FOnSelect(Self);
end;

function TGuiPageControl.GetPageCount: Integer;
begin
  Result:=FPages.Count;
end;

function TGuiPageControl.GetPages(AIndex: Integer): TGuiPage;
begin
  Result:=TGuiPage(FPages[AIndex]);
end;

function TGuiPageControl.TabIndexAtPoint(const APoint: TGuiPoint): Integer;
var
  Rect: TGuiRect;
  TabWidth: TGuiFloat;
begin
  Result:=-1;

  if FPages.Count <= 0 then
    Exit;

  Rect:=AbsoluteBounds;
  if NOT GuiRectContains(GuiRect(Rect.Left, Rect.Top, Rect.Width, FTabHeight), APoint) then
    Exit;

  TabWidth:=Rect.Width / FPages.Count;
  if TabWidth <= 0 then
    Exit;

  Result:=Trunc((APoint.X - Rect.Left) / TabWidth);
  if Result >= FPages.Count then
    Result:=FPages.Count - 1;
end;

function TGuiPageControl.PageBounds: TGuiRect;
begin
  Result:=GuiRect(0, FTabHeight, Bounds.Width, Bounds.Height - FTabHeight);

  if Result.Height < 0 then
    Result.Height:=0;
end;

procedure TGuiPageControl.PaintSelf(ACanvas: TGuiCanvas);
var
  I: Integer;
  Rect: TGuiRect;
  BodyRect: TGuiRect;
  TabRect: TGuiRect;
  TabWidth: TGuiFloat;
  States: TGuiControlVisualStates;
begin
  Rect:=AbsoluteBounds;
  BodyRect:=GuiRect(Rect.Left, Rect.Top + FTabHeight, Rect.Width, Rect.Height - FTabHeight);
  ACanvas.DrawSurface(Style.Background, BodyRect, Style.CornerRadius);
  DrawControlBorder(ACanvas, BodyRect, Style.BorderColor);

  if FPages.Count > 0 then
  begin
    TabWidth:=Rect.Width / FPages.Count;
    for I:=0 to FPages.Count - 1 do
    begin
      States:=[gcvsNormal];
      if I = FSelectedIndex then
        Include(States, gcvsChecked);

      if NOT Enabled then
        Include(States, gcvsDisabled);

      TabRect:=GuiRect(Rect.Left + (I * TabWidth), Rect.Top, TabWidth, FTabHeight + 1);
      ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), TabRect, Style.CornerRadius);
      if I = FSelectedIndex then
        ACanvas.FillRoundedRect(GuiRect(TabRect.Left + 8, TabRect.Top + TabRect.Height - 3,
          Max(0, TabRect.Width - 16), 2), 1, GuiResolveBorderColor(Style, States));
      DrawControlText(ACanvas, TGuiPage(FPages[I]).Caption, GuiInflateRect(TabRect, GuiBoxLTRB(8, 2, 8, 2)),
        GuiResolveTextColor(Style, States), ghtaCenter, gvtaCenter);
    end;
  end;

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, Rect, Style);
end;

procedure TGuiPageControl.Arrange(const ABounds: TGuiRect);
var
  I: Integer;
begin
  Bounds:=ABounds;

  for I:=0 to FPages.Count - 1 do
    TGuiPage(FPages[I]).Arrange(PageBounds);

  CompleteArrange;
end;

procedure TGuiPageControl.Paint(ACanvas: TGuiCanvas);
begin
  if NOT Visible then
    Exit;

  PaintSelf(ACanvas);
  if (FSelectedIndex >= 0) AND (FSelectedIndex < FPages.Count) then
    TGuiPage(FPages[FSelectedIndex]).Paint(ACanvas);
end;

procedure TGuiPageControl.PaintOverlay(ACanvas: TGuiCanvas);
begin
  if NOT Visible then
    Exit;

  if (FSelectedIndex >= 0) AND (FSelectedIndex < FPages.Count) then
    TGuiPage(FPages[FSelectedIndex]).PaintOverlay(ACanvas);
end;

procedure TGuiPageControl.HandleEvent(var AEvent: TGuiEvent);
var
  Index: Integer;
begin
  inherited HandleEvent(AEvent);

  case AEvent.Kind of
    gekMouseDown:
    begin
      Index:=TabIndexAtPoint(AEvent.Position);
      if Index >= 0 then
      begin
        SelectedIndex:=Index;
        AEvent.Handled:=True;
      end;
    end;

    gekKeyDown:
    begin
      case AEvent.KeyCode of
        $40000050, $40000052:
        begin
          SelectedIndex:=FSelectedIndex - 1;
          AEvent.Handled:=True;
        end;

        $4000004F, $40000051:
        begin
          SelectedIndex:=FSelectedIndex + 1;
          AEvent.Handled:=True;
        end;
      end;
    end;
  end;
end;

function TGuiPageControl.HitTest(const APoint: TGuiPoint): TGuiControl;
begin
  Result:=nil;

  if (NOT Visible) OR (NOT Enabled) then
    Exit;

  if NOT GuiRectContains(AbsoluteBounds, APoint) then
    Exit;

  if TabIndexAtPoint(APoint) >= 0 then
  begin
    Result:=Self;
    Exit;
  end;

  if (FSelectedIndex >= 0) AND (FSelectedIndex < FPages.Count) then
    Result:=TGuiPage(FPages[FSelectedIndex]).HitTest(APoint);

  if NOT Assigned(Result) then
    Result:=Self;
end;

function TGuiPageControl.DispatchShortcut(var AEvent: TGuiEvent): Boolean;
begin
  Result:=False;
  if NOT Visible OR NOT Enabled OR (SelectedIndex < 0) OR
    (SelectedIndex >= PageCount) then
    Exit;
  Result:=Pages[SelectedIndex].DispatchShortcut(AEvent);
end;

end.
