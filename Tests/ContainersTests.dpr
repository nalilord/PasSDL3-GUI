program ContainersTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Core,
  PasSDL3.GUI.Controls.Containers;

type
  TContainerCanvas = class(TGuiCanvas)
  private
    FFillCount: Integer;
    FBorderCount: Integer;
    FFirstClip: TGuiRect;
  public
    property FillCount: Integer read FFillCount write FFillCount;
    property BorderCount: Integer read FBorderCount write FBorderCount;
  private
    FClipDepth: Integer;
  public
    property ClipDepth: Integer read FClipDepth write FClipDepth;
    property FirstClip: TGuiRect read FFirstClip write FFirstClip;
    procedure FillRect(const ARect: TGuiRect;
      const AColor: TGuiColor);
      override;
    procedure DrawBorder(const ARect: TGuiRect; ABorderWidth: TGuiFloat;
      const AColor: TGuiColor);
      override;
    procedure DrawImage(ATexture: TGuiTexture;
      const ARect: TGuiRect);
      override;
    procedure DrawText(const AText: String; const ARect: TGuiRect;
      const AColor: TGuiColor; AHorizontalAlign: TGuiHorizontalTextAlign;
      AVerticalAlign: TGuiVerticalTextAlign);
      override;
    procedure PushClipRect(const ARect: TGuiRect);
    override;
    procedure PopClipRect;
    override;
  end;

  TMoveProbe = class
  private
    FCalls: Integer;
  public
    property Calls: Integer read FCalls write FCalls;
    procedure Moved(Sender: TGuiControl);
  end;

  TDestroyProbe = class(TGuiControl)
  public
    destructor Destroy;
    override;
  end;

var
  DestroyedControls: Integer;

procedure Check(ACondition: Boolean; const AMessage: String);
begin
  if NOT ACondition then
  begin
    WriteLn('FAIL: ', AMessage);
    Halt(1);
  end;
end;

procedure TContainerCanvas.FillRect(const ARect: TGuiRect;
  const AColor: TGuiColor);
begin
  Inc(FFillCount);
end;

procedure TContainerCanvas.DrawBorder(const ARect: TGuiRect;
  ABorderWidth: TGuiFloat; const AColor: TGuiColor);
begin
  Inc(FBorderCount);
end;

procedure TContainerCanvas.DrawImage(ATexture: TGuiTexture;
  const ARect: TGuiRect);
begin
end;

procedure TContainerCanvas.DrawText(const AText: String;
  const ARect: TGuiRect; const AColor: TGuiColor;
  AHorizontalAlign: TGuiHorizontalTextAlign;
  AVerticalAlign: TGuiVerticalTextAlign);
begin
end;

procedure TContainerCanvas.PushClipRect(const ARect: TGuiRect);
begin
  if ClipDepth = 0 then
    FirstClip:=ARect;
  Inc(FClipDepth);
end;

procedure TContainerCanvas.PopClipRect;
begin
  Dec(FClipDepth);
end;

procedure TMoveProbe.Moved(Sender: TGuiControl);
begin
  Inc(FCalls);
end;

destructor TDestroyProbe.Destroy;
begin
  Inc(DestroyedControls);
  inherited Destroy;
end;

procedure TestLayout;
var
  Stack: TGuiStackPanel;
  Grid: TGuiGridPanel;
  First: TGuiControl;
  Second: TGuiControl;
  Frame: TGuiFrame;
  Rect: TGuiRect;
begin
  Stack:=TGuiStackPanel.Create;
  try
    Stack.Bounds:=GuiRect(0, 0, 200, 100);
    Stack.Padding:=GuiBox(10);
    Stack.Spacing:=5;
    Stack.AutoSizeToContent:=False;
    First:=TGuiControl.Create;
    First.Bounds:=GuiRect(0, 0, 20, 20);
    Second:=TGuiControl.Create;
    Second.Bounds:=GuiRect(0, 0, 20, 20);
    Stack.Add(First);
    Stack.Add(Second);
    Stack.Arrange(Stack.Bounds);
    Check((First.Bounds.Left = 10) AND (First.Bounds.Top = 10) AND
      (First.Bounds.Width = 20) AND (First.Bounds.Height = 20),
      'Vertical stack preserves explicit child width and height');
    Check((Second.Bounds.Top = 35) AND (Second.Bounds.Height = 20),
      'Vertical stack applies configured spacing');
    First.MinWidth:=50;
    Stack.Arrange(Stack.Bounds);
    Check(First.Bounds.Width = 50,
      'Stack layout applies child minimum-size constraints');
  finally
    Stack.Free;
  end;

  Grid:=TGuiGridPanel.Create;
  try
    Grid.Bounds:=GuiRect(0, 0, 200, 100);
    Grid.Columns:=2;
    Grid.CellWidth:=40;
    Grid.CellHeight:=30;
    Grid.ColumnSpacing:=5;
    Grid.RowSpacing:=6;
    Grid.AutoSizeToContent:=False;
    First:=TGuiControl.Create;
    Second:=TGuiControl.Create;
    Grid.Add(First);
    Grid.Add(Second);
    Grid.Arrange(Grid.Bounds);
    Check((First.Bounds.Left = 0) AND (First.Bounds.Top = 0) AND
      (First.Bounds.Width = 40) AND (First.Bounds.Height = 30),
      'Grid places the first child in its configured cell');
    Check((Second.Bounds.Left = 45) AND (Second.Bounds.Top = 0),
      'Grid advances by cell width and column spacing');
  finally
    Grid.Free;
  end;

  Frame:=TGuiFrame.Create;
  try
    Frame.Bounds:=GuiRect(0, 0, 200, 100);
    Rect:=Frame.ContentRect;
    Check((Rect.Left = 10) AND (Rect.Top = 36) AND
      (Rect.Width = 180) AND (Rect.Height = 54),
      'Frame content excludes padding and its default header');
    Frame.ShowFooter:=True;
    Frame.FooterHeight:=12;
    Rect:=Frame.ContentRect;
    Check(Rect.Height = 42, 'Frame content excludes an enabled footer');
  finally
    Frame.Free;
  end;
end;

procedure TestScrollAndTransparency;
var
  Scroll: TGuiScrollBox;
  Child: TGuiControl;
  Canvas: TContainerCanvas;
  TransparentPanel: TGuiTransparentPanel;
begin
  Canvas:=TContainerCanvas.Create;
  Scroll:=TGuiScrollBox.Create;
  try
    Scroll.Bounds:=GuiRect(0, 0, 100, 100);
    Child:=TGuiControl.Create;
    Child.Bounds:=GuiRect(0, 0, 300, 200);
    Scroll.Add(Child);
    Scroll.Paint(Canvas);
    Check((Scroll.ViewportWidth = 88) AND (Scroll.ViewportHeight = 88) AND
      (Scroll.MaxScrollX = 212) AND (Scroll.MaxScrollY = 112),
      'Scroll box reserves consistent two-axis gutters');
    Check((Canvas.FirstClip.Width = 88) AND
      (Canvas.FirstClip.Height = 88) AND (Canvas.ClipDepth = 0),
      'Scroll box clips children to its viewport and balances clipping');
    Scroll.ScrollX:=999;
    Scroll.ScrollY:=999;
    Check((Scroll.ScrollX = Scroll.MaxScrollX) AND
      (Scroll.ScrollY = Scroll.MaxScrollY),
      'Scroll offsets clamp to their content ranges');
  finally
    Scroll.Free;
  end;

  TransparentPanel:=TGuiTransparentPanel.Create;
  try
    TransparentPanel.Bounds:=GuiRect(0, 0, 80, 40);
    Canvas.FillCount:=0;
    TransparentPanel.Paint(Canvas);
    Check(Canvas.FillCount = 0, 'Transparent panel paints no surface');
    Check(TransparentPanel.HitTest(GuiPoint(10, 10)) = TransparentPanel,
      'Transparent panel preserves container hit routing');
  finally
    TransparentPanel.Free;
    Canvas.Free;
  end;
end;

procedure TestSplitterAndOwnership;
var
  Target: TGuiPanel;
  Splitter: TGuiSplitter;
  Event: TGuiEvent;
  Probe: TMoveProbe;
  Owner: TGuiPanel;
begin
  Target:=TGuiPanel.Create;
  Splitter:=TGuiSplitter.Create;
  Probe:=TMoveProbe.Create;
  try
    Target.Bounds:=GuiRect(0, 0, 100, 80);
    Splitter.Bounds:=GuiRect(100, 0, 10, 80);
    Splitter.TargetControl:=Target;
    Splitter.OnMoved:=Probe.Moved;
    Event:=Default(TGuiEvent);
    Event.Kind:=gekMouseDown;
    Event.Button:=gmbLeft;
    Event.Position:=GuiPoint(105, 20);
    Splitter.HandleEvent(Event);
    Event.Kind:=gekMouseMove;
    Event.Position:=GuiPoint(135, 20);
    Splitter.HandleEvent(Event);
    Check((Target.Bounds.Width = 130) AND (Splitter.Bounds.Left = 130) AND
      (Splitter.Delta = 30) AND (Probe.Calls = 1),
      'Vertical splitter resizes its target and reports the movement');
    Check(Splitter.MouseCursorAt(GuiPoint(130, 20)) = gmcSizeWE,
      'Vertical splitter exposes the horizontal resize cursor');
    Splitter.Orientation:=goHorizontal;
    Check(Splitter.MouseCursorAt(GuiPoint(130, 20)) = gmcSizeNS,
      'Horizontal splitter exposes the vertical resize cursor');
  finally
    Probe.Free;
    Splitter.Free;
    Target.Free;
  end;

  DestroyedControls:=0;
  Owner:=TGuiPanel.Create;
  Owner.Add(TDestroyProbe.Create);
  Owner.Free;
  Check(DestroyedControls = 1, 'Containers retain ownership of added children');
end;

begin
  TestLayout;
  TestScrollAndTransparency;
  TestSplitterAndOwnership;
  WriteLn('PASS: container layout, scrolling, transparency, splitter, and ownership');
end.
