program ChartsTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  Math,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Controls.Charts;

type
  TChartCanvas = class(TGuiCanvas)
  private
    FFillCount: Integer;
    FBorderCount: Integer;
  public
    property FillCount: Integer read FFillCount write FFillCount;
    property BorderCount: Integer read FBorderCount write FBorderCount;
  private
    FLineCount: Integer;
  public
    property LineCount: Integer read FLineCount write FLineCount;
  private
    FTextCount: Integer;
  public
    property TextCount: Integer read FTextCount write FTextCount;
  private
    FClipDepth: Integer;
  public
    property ClipDepth: Integer read FClipDepth write FClipDepth;
  private
    FLastFill: TGuiRect;
  public
    property LastFill: TGuiRect read FLastFill write FLastFill;
  private
    FLastLineStart: TGuiPoint;
  public
    property LastLineStart: TGuiPoint read FLastLineStart write FLastLineStart;
  private
    FLastLineEnd: TGuiPoint;
  public
    property LastLineEnd: TGuiPoint read FLastLineEnd write FLastLineEnd;
  private
    FLastText: String;
  public
    property LastText: String read FLastText write FLastText;
  private
    FLastTextRect: TGuiRect;
  public
    property LastTextRect: TGuiRect read FLastTextRect write FLastTextRect;
    procedure FillRect(const ARect: TGuiRect;
      const AColor: TGuiColor);
      override;
    procedure DrawBorder(const ARect: TGuiRect; ABorderWidth: TGuiFloat;
      const AColor: TGuiColor);
      override;
    procedure DrawLine(const AStart, AEnd: TGuiPoint; AWidth: TGuiFloat;
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

procedure Check(ACondition: Boolean; const AMessage: String);
begin
  if NOT ACondition then
  begin
    WriteLn('FAIL: ', AMessage);
    Halt(1);
  end;
end;

function Near(AValue, AExpected: TGuiFloat): Boolean;
begin
  Result:=Abs(AValue - AExpected) < 0.01;
end;

procedure TChartCanvas.FillRect(const ARect: TGuiRect;
  const AColor: TGuiColor);
begin
  Inc(FFillCount);
  LastFill:=ARect;
end;

procedure TChartCanvas.DrawBorder(const ARect: TGuiRect;
  ABorderWidth: TGuiFloat; const AColor: TGuiColor);
begin
  Inc(FBorderCount);
end;

procedure TChartCanvas.DrawLine(const AStart, AEnd: TGuiPoint;
  AWidth: TGuiFloat; const AColor: TGuiColor);
begin
  Inc(FLineCount);
  LastLineStart:=AStart;
  LastLineEnd:=AEnd;
end;

procedure TChartCanvas.DrawImage(ATexture: TGuiTexture;
  const ARect: TGuiRect);
begin
end;

procedure TChartCanvas.DrawText(const AText: String; const ARect: TGuiRect;
  const AColor: TGuiColor; AHorizontalAlign: TGuiHorizontalTextAlign;
  AVerticalAlign: TGuiVerticalTextAlign);
begin
  Inc(FTextCount);
  LastText:=AText;
  LastTextRect:=ARect;
end;

procedure TChartCanvas.PushClipRect(const ARect: TGuiRect);
begin
  Inc(FClipDepth);
end;

procedure TChartCanvas.PopClipRect;
begin
  Dec(FClipDepth);
end;

procedure TestDial;
var
  Dial: TGuiDialGauge;
  Canvas: TChartCanvas;
begin
  Dial:=TGuiDialGauge.Create;
  Canvas:=TChartCanvas.Create;
  try
    Check((Dial.MinValue = 0) AND (Dial.MaxValue = 100) AND
      (Dial.Value = 0), 'Dial preserves default range and value');
    Check((Dial.StartAngle = 220) AND (Dial.EndAngle = -40) AND
      (Dial.TickCount = 24) AND (Dial.MajorTickEvery = 4),
      'Dial preserves angle and tick defaults');
    Check(Dial.ShowText AND Dial.ShowValue,
      'Dial preserves text visibility defaults');
    Dial.Value:=200;
    Check(Dial.Value = 100, 'Dial clamps values at maximum');
    Dial.Value:=-1;
    Check(Dial.Value = 0, 'Dial clamps values at minimum');
    Dial.MinValue:=80;
    Check((Dial.MinValue = 80) AND (Dial.Value = 80),
      'Dial minimum change clamps the current value');
    Dial.MaxValue:=20;
    Check((Dial.MinValue = 20) AND (Dial.MaxValue = 20) AND
      (Dial.Value = 20), 'Dial preserves a valid collapsed range');
    Dial.MinValue:=0;
    Dial.MaxValue:=100;
    Dial.Value:=50;
    Dial.Bounds:=GuiRect(0, 0, 200, 100);
    Dial.Caption:='Load';
    Dial.Paint(Canvas);
    Check((Canvas.LineCount > 70) AND (Canvas.FillCount > 0) AND
      (Canvas.BorderCount > 0), 'Dial paints arcs, ticks, needle, and frame');
    Check(Near(Canvas.LastLineStart.X, 100) AND
      Near(Canvas.LastLineStart.Y, 50) AND
      Near(Canvas.LastLineEnd.X, 100) AND
      Near(Canvas.LastLineEnd.Y, 26),
      'Dial maps midpoint value to the expected needle endpoint');
    Check((Canvas.TextCount = 2) AND (Canvas.LastText = '50'),
      'Dial paints caption and formatted value');
    Dial.Bounds:=GuiRect(0, 0, 1, 1);
    Dial.Paint(Canvas);
    Check(Canvas.ClipDepth = 0, 'Tiny dial painting keeps canvas state balanced');
  finally
    Canvas.Free;
    Dial.Free;
  end;
end;

procedure TestScope;
var
  Scope: TGuiScope;
  Marker: TGuiScopeMarker;
  Canvas: TChartCanvas;
begin
  Scope:=TGuiScope.Create;
  Canvas:=TChartCanvas.Create;
  try
    Check(Scope.ShowGrid AND (Scope.GridDivisions = 4) AND
      Scope.ShowRings AND (Scope.RingCount = 3) AND
      Scope.ShowCrosshair AND NOT Scope.ShowSweep AND
      (Scope.SweepAngle = 45), 'Scope preserves display defaults');
    Marker:=Scope.AddMarker(1, -1, GuiColor(10, 20, 30), 6, 'edge');
    Check((Scope.MarkerCount = 1) AND (Scope.Markers[0] = Marker) AND
      (Scope.Markers[-1] = nil) AND (Scope.Markers[1] = nil),
      'Scope registers markers and bounds-checks access');
    Check((Marker.X = 1) AND (Marker.Y = -1) AND (Marker.Size = 6) AND
      (Marker.Caption = 'edge'), 'Marker exposes mutable data properties');
    Marker.X:=0.5;
    Marker.X:=1;
    Scope.Bounds:=GuiRect(10, 20, 200, 100);
    Scope.ShowSweep:=True;
    Scope.Paint(Canvas);
    Check((Canvas.LineCount > 150) AND (Canvas.FillCount > 0) AND
      (Canvas.BorderCount > 1), 'Scope paints grid, rings, sweep, and marker');
    Check(Near(Canvas.LastFill.Left, 151) AND
      Near(Canvas.LastFill.Top, 111) AND
      Near(Canvas.LastFill.Width, 6) AND
      Near(Canvas.LastFill.Height, 6),
      'Scope maps normalized marker coordinates into its padded radius');
    Check((Canvas.TextCount = 1) AND (Canvas.LastText = 'edge') AND
      Near(Canvas.LastTextRect.Left, 163) AND
      Near(Canvas.LastTextRect.Top, 105),
      'Scope paints marker labels at the mapped point');
    Scope.ClearMarkers;
    Check((Scope.MarkerCount = 0) AND (Scope.Markers[0] = nil),
      'Scope releases and clears owned markers');
    Scope.Bounds:=GuiRect(0, 0, 0, 0);
    Scope.Paint(Canvas);
    Check(Canvas.ClipDepth = 0, 'Empty scope painting keeps canvas state balanced');
  finally
    Canvas.Free;
    Scope.Free;
  end;
end;

begin
  TestDial;
  TestScope;
  WriteLn('PASS: chart defaults, ranges, ownership, mapping, labels, and painting');
end.
