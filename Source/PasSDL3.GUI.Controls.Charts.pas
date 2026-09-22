unit PasSDL3.GUI.Controls.Charts;

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
  TGuiDialGauge = class(TGuiControl)
  private
    FMinValue: TGuiFloat;
    FMaxValue: TGuiFloat;
    FValue: TGuiFloat;
    FStartAngle: TGuiFloat;
    FEndAngle: TGuiFloat;
    FTickCount: Integer;
    FMajorTickEvery: Integer;
    FShowText: Boolean;
    FShowValue: Boolean;
    FNeedleColor: TGuiColor;
    FTickColor: TGuiColor;
    FArcColor: TGuiColor;
    FFillColor: TGuiColor;
    procedure SetMinValue(AValue: TGuiFloat);
    procedure SetMaxValue(AValue: TGuiFloat);
    procedure SetValue(AValue: TGuiFloat);
    function ValueRatio: TGuiFloat;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    property MinValue: TGuiFloat read FMinValue write SetMinValue;
    property MaxValue: TGuiFloat read FMaxValue write SetMaxValue;
    property Value: TGuiFloat read FValue write SetValue;
    property StartAngle: TGuiFloat read FStartAngle write FStartAngle;
    property EndAngle: TGuiFloat read FEndAngle write FEndAngle;
    property TickCount: Integer read FTickCount write FTickCount;
    property MajorTickEvery: Integer read FMajorTickEvery write FMajorTickEvery;
    property ShowText: Boolean read FShowText write FShowText;
    property ShowValue: Boolean read FShowValue write FShowValue;
    property NeedleColor: TGuiColor read FNeedleColor write FNeedleColor;
    property TickColor: TGuiColor read FTickColor write FTickColor;
    property ArcColor: TGuiColor read FArcColor write FArcColor;
    property FillColor: TGuiColor read FFillColor write FFillColor;
  end;

  TGuiScopeMarker = class
  private
    FX: TGuiFloat;
    FY: TGuiFloat;
    FSize: TGuiFloat;
    FColor: TGuiColor;
    FCaption: String;
  public
    constructor Create(AX, AY: TGuiFloat; const AColor: TGuiColor;
      ASize: TGuiFloat; const ACaption: String);
    property X: TGuiFloat read FX write FX;
    property Y: TGuiFloat read FY write FY;
    property Size: TGuiFloat read FSize write FSize;
    property Color: TGuiColor read FColor write FColor;
    property Caption: String read FCaption write FCaption;
  end;

  TGuiScope = class(TGuiControl)
  private
    FMarkers: TList;
    FShowGrid: Boolean;
    FGridDivisions: Integer;
    FShowRings: Boolean;
    FRingCount: Integer;
    FShowCrosshair: Boolean;
    FShowSweep: Boolean;
    FSweepAngle: TGuiFloat;
    FGridColor: TGuiColor;
    FRingColor: TGuiColor;
    FCrosshairColor: TGuiColor;
    FSweepColor: TGuiColor;
    function GetMarker(AIndex: Integer): TGuiScopeMarker;
    function GetMarkerCount: Integer;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddMarker(AX, AY: TGuiFloat; const AColor: TGuiColor;
      ASize: TGuiFloat = 5; const ACaption: String = ''): TGuiScopeMarker;
    procedure ClearMarkers;
    property Markers[AIndex: Integer]: TGuiScopeMarker read GetMarker;
    property MarkerCount: Integer read GetMarkerCount;
    property ShowGrid: Boolean read FShowGrid write FShowGrid;
    property GridDivisions: Integer read FGridDivisions write FGridDivisions;
    property ShowRings: Boolean read FShowRings write FShowRings;
    property RingCount: Integer read FRingCount write FRingCount;
    property ShowCrosshair: Boolean read FShowCrosshair write FShowCrosshair;
    property ShowSweep: Boolean read FShowSweep write FShowSweep;
    property SweepAngle: TGuiFloat read FSweepAngle write FSweepAngle;
    property GridColor: TGuiColor read FGridColor write FGridColor;
    property RingColor: TGuiColor read FRingColor write FRingColor;
    property CrosshairColor: TGuiColor read FCrosshairColor write FCrosshairColor;
    property SweepColor: TGuiColor read FSweepColor write FSweepColor;
  end;

implementation

procedure GuiDrawDialArc(ACanvas: TGuiCanvas; const ACenter: TGuiPoint;
  ARadius, AStartAngle, AEndAngle, ARatio: TGuiFloat;
  const AColor: TGuiColor; AWidth: TGuiFloat);
var
  I: Integer;
  Steps: Integer;
  Angle1: TGuiFloat;
  Angle2: TGuiFloat;
  Range: TGuiFloat;
  Point1: TGuiPoint;
  Point2: TGuiPoint;
begin
  if ARatio <= 0 then
    Exit;
  if ARatio > 1 then
    ARatio:=1;
  Steps:=Max(2, Round(48 * ARatio));
  Range:=(AEndAngle - AStartAngle) * ARatio;
  for I:=0 to Steps - 1 do
  begin
    Angle1:=DegToRad(AStartAngle + (Range * I / Steps));
    Angle2:=DegToRad(AStartAngle + (Range * (I + 1) / Steps));
    Point1:=GuiPoint(
      ACenter.X + Cos(Angle1) * ARadius,
      ACenter.Y - Sin(Angle1) * ARadius
    );
    Point2:=GuiPoint(
      ACenter.X + Cos(Angle2) * ARadius,
      ACenter.Y - Sin(Angle2) * ARadius
    );
    ACanvas.DrawLine(Point1, Point2, AWidth, AColor);
  end;
end;

constructor TGuiDialGauge.Create;
begin
  inherited Create;
  FMinValue:=0;
  FMaxValue:=100;
  FValue:=0;
  FStartAngle:=220;
  FEndAngle:=-40;
  FTickCount:=24;
  FMajorTickEvery:=4;
  FShowText:=True;
  FShowValue:=True;
  FNeedleColor:=GuiColor(255, 232, 170);
  FTickColor:=GuiColor(210, 220, 190, 150);
  FArcColor:=GuiColor(80, 94, 76, 220);
  FFillColor:=GuiColor(118, 214, 180, 230);
  Padding:=GuiBox(6);
  BackgroundColor:=GuiColor(31, 37, 46);
  BorderColor:=GuiColor(78, 92, 112);
  TextHorizontalAlign:=ghtaCenter;
  TextVerticalAlign:=gvtaCenter;
end;

procedure TGuiDialGauge.SetMinValue(AValue: TGuiFloat);
begin
  FMinValue:=AValue;
  if FMaxValue < FMinValue then
    FMaxValue:=FMinValue;
  SetValue(FValue);
end;

procedure TGuiDialGauge.SetMaxValue(AValue: TGuiFloat);
begin
  FMaxValue:=AValue;
  if FMinValue > FMaxValue then
    FMinValue:=FMaxValue;
  SetValue(FValue);
end;

procedure TGuiDialGauge.SetValue(AValue: TGuiFloat);
begin
  if AValue < FMinValue then
    AValue:=FMinValue;
  if AValue > FMaxValue then
    AValue:=FMaxValue;
  FValue:=AValue;
end;

function TGuiDialGauge.ValueRatio: TGuiFloat;
begin
  Result:=0;
  if FMaxValue > FMinValue then
    Result:=(FValue - FMinValue) / (FMaxValue - FMinValue);
  if Result < 0 then
    Result:=0;
  if Result > 1 then
    Result:=1;
end;

procedure TGuiDialGauge.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  InnerRect: TGuiRect;
  Center: TGuiPoint;
  Radius: TGuiFloat;
  Ratio: TGuiFloat;
  States: TGuiControlVisualStates;
  I: Integer;
  Angle: TGuiFloat;
  Point1: TGuiPoint;
  Point2: TGuiPoint;
  TickLength: TGuiFloat;
  TextValue: String;
begin
  States:=[];
  if NOT Enabled then
    Include(States, gcvsDisabled);
  Rect:=AbsoluteBounds;
  InnerRect:=GuiInflateRect(Rect, Padding);
  ACanvas.DrawSurface(
    GuiResolveBackgroundDrawable(Style, States),
    Rect,
    Style.CornerRadius
  );
  Center:=GuiPoint(
    InnerRect.Left + (InnerRect.Width / 2),
    InnerRect.Top + (InnerRect.Height / 2)
  );
  if InnerRect.Width < InnerRect.Height then
    Radius:=InnerRect.Width / 2
  else
    Radius:=InnerRect.Height / 2;
  Radius:=Radius - 4;
  if Radius < 4 then
    Radius:=4;
  Ratio:=ValueRatio;
  GuiDrawDialArc(ACanvas, Center, Radius, FStartAngle, FEndAngle, 1,
    FArcColor, 2);
  GuiDrawDialArc(ACanvas, Center, Radius, FStartAngle, FEndAngle, Ratio,
    FFillColor, 4);
  if FTickCount > 1 then
  begin
    for I:=0 to FTickCount - 1 do
    begin
      Angle:=DegToRad(
        FStartAngle + ((FEndAngle - FStartAngle) * I / (FTickCount - 1))
      );
      TickLength:=7;
      if (FMajorTickEvery > 0) AND ((I MOD FMajorTickEvery) = 0) then
        TickLength:=11;
      Point1:=GuiPoint(
        Center.X + Cos(Angle) * (Radius - TickLength),
        Center.Y - Sin(Angle) * (Radius - TickLength)
      );
      Point2:=GuiPoint(
        Center.X + Cos(Angle) * Radius,
        Center.Y - Sin(Angle) * Radius
      );
      ACanvas.DrawLine(Point1, Point2, 1, FTickColor);
    end;
  end;
  Angle:=DegToRad(FStartAngle + ((FEndAngle - FStartAngle) * Ratio));
  Point2:=GuiPoint(
    Center.X + Cos(Angle) * (Radius - 16),
    Center.Y - Sin(Angle) * (Radius - 16)
  );
  ACanvas.DrawLine(Center, Point2, 2, FNeedleColor);
  ACanvas.FillRect(
    GuiRect(Center.X - 4, Center.Y - 4, 8, 8),
    FNeedleColor
  );
  DrawControlBorder(ACanvas, Rect, GuiResolveBorderColor(Style, States));
  if FShowText AND (Caption <> '') then
  begin
    DrawControlText(
      ACanvas,
      Caption,
      GuiRect(Rect.Left, Rect.Top + Rect.Height - 24, Rect.Width, 20),
      GuiResolveTextColor(Style, States),
      ghtaCenter,
      gvtaCenter
    );
  end;
  if FShowValue then
  begin
    TextValue:=FormatFloat('0', FValue);
    DrawControlText(
      ACanvas,
      TextValue,
      GuiRect(Rect.Left, Center.Y - 12, Rect.Width, 24),
      GuiResolveTextColor(Style, States),
      ghtaCenter,
      gvtaCenter
    );
  end;
end;

constructor TGuiScopeMarker.Create(AX, AY: TGuiFloat;
  const AColor: TGuiColor; ASize: TGuiFloat; const ACaption: String);
begin
  inherited Create;
  FX:=AX;
  FY:=AY;
  FColor:=AColor;
  FSize:=ASize;
  FCaption:=ACaption;
end;

constructor TGuiScope.Create;
begin
  inherited Create;
  FMarkers:=TList.Create;
  FShowGrid:=True;
  FGridDivisions:=4;
  FShowRings:=True;
  FRingCount:=3;
  FShowCrosshair:=True;
  FShowSweep:=False;
  FSweepAngle:=45;
  FGridColor:=GuiColor(95, 160, 105, 95);
  FRingColor:=GuiColor(95, 160, 105, 120);
  FCrosshairColor:=GuiColor(180, 230, 150, 150);
  FSweepColor:=GuiColor(180, 230, 150, 200);
  Padding:=GuiBox(6);
  BackgroundColor:=GuiColor(10, 16, 13, 220);
  BorderColor:=GuiColor(78, 92, 112);
end;

destructor TGuiScope.Destroy;
begin
  ClearMarkers;
  FMarkers.Free;
  inherited Destroy;
end;

function TGuiScope.AddMarker(AX, AY: TGuiFloat;
  const AColor: TGuiColor; ASize: TGuiFloat;
  const ACaption: String): TGuiScopeMarker;
begin
  Result:=TGuiScopeMarker.Create(AX, AY, AColor, ASize, ACaption);
  FMarkers.Add(Result);
end;

procedure TGuiScope.ClearMarkers;
var
  I: Integer;
begin
  for I:=0 to FMarkers.Count - 1 do
    TObject(FMarkers[I]).Free;
  FMarkers.Clear;
end;

function TGuiScope.GetMarker(AIndex: Integer): TGuiScopeMarker;
begin
  Result:=nil;
  if (AIndex >= 0) AND (AIndex < FMarkers.Count) then
    Result:=TGuiScopeMarker(FMarkers[AIndex]);
end;

function TGuiScope.GetMarkerCount: Integer;
begin
  Result:=FMarkers.Count;
end;

procedure TGuiScope.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  ScopeRect: TGuiRect;
  Center: TGuiPoint;
  Radius: TGuiFloat;
  States: TGuiControlVisualStates;
  I: Integer;
  X: TGuiFloat;
  Y: TGuiFloat;
  Marker: TGuiScopeMarker;
  MarkerPoint: TGuiPoint;
  MarkerRect: TGuiRect;
  SweepRadians: TGuiFloat;
begin
  States:=[];
  if NOT Enabled then
    Include(States, gcvsDisabled);
  Rect:=AbsoluteBounds;
  ACanvas.DrawSurface(
    GuiResolveBackgroundDrawable(Style, States),
    Rect,
    Style.CornerRadius
  );
  ScopeRect:=GuiInflateRect(Rect, Padding);
  if ScopeRect.Width < 0 then
    ScopeRect.Width:=0;
  if ScopeRect.Height < 0 then
    ScopeRect.Height:=0;
  Center:=GuiPoint(
    ScopeRect.Left + (ScopeRect.Width / 2),
    ScopeRect.Top + (ScopeRect.Height / 2)
  );
  if ScopeRect.Width < ScopeRect.Height then
    Radius:=ScopeRect.Width / 2
  else
    Radius:=ScopeRect.Height / 2;
  if Radius < 1 then
    Radius:=1;
  if FShowGrid AND (FGridDivisions > 0) then
  begin
    for I:=1 to FGridDivisions - 1 do
    begin
      X:=ScopeRect.Left + (ScopeRect.Width * I / FGridDivisions);
      ACanvas.DrawLine(
        GuiPoint(X, ScopeRect.Top),
        GuiPoint(X, ScopeRect.Top + ScopeRect.Height),
        1,
        FGridColor
      );
      Y:=ScopeRect.Top + (ScopeRect.Height * I / FGridDivisions);
      ACanvas.DrawLine(
        GuiPoint(ScopeRect.Left, Y),
        GuiPoint(ScopeRect.Left + ScopeRect.Width, Y),
        1,
        FGridColor
      );
    end;
  end;
  if FShowRings AND (FRingCount > 0) then
  begin
    for I:=1 to FRingCount do
      GuiDrawDialArc(
        ACanvas,
        Center,
        Radius * I / FRingCount,
        0,
        360,
        1,
        FRingColor,
        1
      );
  end;
  if FShowCrosshair then
  begin
    ACanvas.DrawLine(
      GuiPoint(Center.X, ScopeRect.Top),
      GuiPoint(Center.X, ScopeRect.Top + ScopeRect.Height),
      1,
      FCrosshairColor
    );
    ACanvas.DrawLine(
      GuiPoint(ScopeRect.Left, Center.Y),
      GuiPoint(ScopeRect.Left + ScopeRect.Width, Center.Y),
      1,
      FCrosshairColor
    );
  end;
  if FShowSweep then
  begin
    SweepRadians:=DegToRad(FSweepAngle);
    ACanvas.DrawLine(
      Center,
      GuiPoint(
        Center.X + Cos(SweepRadians) * Radius,
        Center.Y - Sin(SweepRadians) * Radius
      ),
      2,
      FSweepColor
    );
  end;
  for I:=0 to FMarkers.Count - 1 do
  begin
    Marker:=TGuiScopeMarker(FMarkers[I]);
    MarkerPoint:=GuiPoint(
      Center.X + (Marker.X * Radius),
      Center.Y - (Marker.Y * Radius)
    );
    MarkerRect:=GuiRect(
      MarkerPoint.X - (Marker.Size / 2),
      MarkerPoint.Y - (Marker.Size / 2),
      Marker.Size,
      Marker.Size
    );
    ACanvas.FillRect(MarkerRect, Marker.Color);
    ACanvas.DrawBorder(
      GuiRect(
        MarkerRect.Left - 2,
        MarkerRect.Top - 2,
        MarkerRect.Width + 4,
        MarkerRect.Height + 4
      ),
      1,
      Marker.Color
    );
    if Marker.Caption <> '' then
    begin
      DrawControlText(
        ACanvas,
        Marker.Caption,
        GuiRect(
          MarkerPoint.X + Marker.Size + 3,
          MarkerPoint.Y - 9,
          80,
          18
        ),
        Style.TextColor,
        ghtaLeft,
        gvtaCenter
      );
    end;
  end;
  DrawControlBorder(ACanvas, Rect, GuiResolveBorderColor(Style, States));
end;

end.
