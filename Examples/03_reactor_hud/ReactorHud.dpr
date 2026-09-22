program ReactorHud;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Math,
  SDL3,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Context,
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Clipboard.SDL3,
  PasSDL3.GUI.Fonts.SDLTTF,
  PasSDL3.GUI.Fonts,
  PasSDL3.GUI.Theme,
  PasSDL3.GUI.Host.SDL3;

type
  TGustavScreen = (
    gsMenu,
    gsHud,
    gsShop
  );

  TPixelGameBackground = class(TGuiControl)
  private
    FShowRail: Boolean;
  public
    property ShowRail: Boolean read FShowRail write FShowRail;
    constructor Create;
    override;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas);
    override;
  end;

  TGustavHudBarKind = (
    hbkArmor,
    hbkCharge,
    hbkMissile,
    hbkZoom
  );

  TGustavReadoutLines = array[0..3] of String;

  TGustavHudBar = class(TGuiControl)
  private
    FValue: TGuiFloat;
  public
    property Value: TGuiFloat read FValue write FValue;
  private
    FMaxValue: TGuiFloat;
  public
    property MaxValue: TGuiFloat read FMaxValue write FMaxValue;
  private
    FCaption: String;
  public
    property Caption: String read FCaption write FCaption;
  private
    FDetail: String;
  public
    property Detail: String read FDetail write FDetail;
  private
    FKind: TGustavHudBarKind;
  public
    property Kind: TGustavHudBarKind read FKind write FKind;
    constructor Create;
    override;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas);
    override;
  end;

  TGustavWindIndicator = class(TGuiControl)
  private
    FDirection: TGuiFloat;
  public
    property Direction: TGuiFloat read FDirection write FDirection;
  private
    FSpeed: TGuiFloat;
  public
    property Speed: TGuiFloat read FSpeed write FSpeed;
    constructor Create;
    override;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas);
    override;
  end;

  TGustavTargetScope = class(TGuiControl)
  private
    FEnemyCount: Integer;
  public
    property EnemyCount: Integer read FEnemyCount write FEnemyCount;
  private
    FTargetLock: TGuiFloat;
  public
    property TargetLock: TGuiFloat read FTargetLock write FTargetLock;
    constructor Create;
    override;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas);
    override;
  end;

  TGustavReadout = class(TGuiControl)
  private
    FTitle: String;
  public
    property Title: String read FTitle write FTitle;
  private
    FLines: TGustavReadoutLines;
  public
    property Lines: TGustavReadoutLines read FLines write FLines;
    constructor Create;
    override;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas);
    override;
  end;

  TGustavBattleHud = class(TGuiControl)
  public
    constructor Create;
    override;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas);
    override;
  end;

  TDemoHandlers = class
  private
    FContext: TGuiContext;
  public
    property Context: TGuiContext read FContext write FContext;
  private
    FMenuLayer: TGuiPanel;
  public
    property MenuLayer: TGuiPanel read FMenuLayer write FMenuLayer;
  private
    FHudLayer: TGuiPanel;
  public
    property HudLayer: TGuiPanel read FHudLayer write FHudLayer;
  private
    FShopLayer: TGuiPanel;
  public
    property ShopLayer: TGuiPanel read FShopLayer write FShopLayer;
  private
    FStatusBar: TGuiStatusBar;
  public
    property StatusBar: TGuiStatusBar read FStatusBar write FStatusBar;
    procedure ShowMenu(Sender: TGuiControl);
    procedure ShowHud(Sender: TGuiControl);
    procedure ShowShop(Sender: TGuiControl);
    procedure ExitApp(Sender: TGuiControl);
    procedure SetScreen(AScreen: TGustavScreen);
  end;

var
  AppRunning: Boolean;

function GustavTheme: TGuiTheme;
var
  Metrics: TGuiThemeMetrics;
begin
  Result:=GuiDarkTheme;
  Result.WindowBackground:=GuiColor(71, 145, 184);
  Result.PanelBackground:=GuiColor(12, 17, 16, 214);
  Result.PanelBorder:=GuiColor(112, 126, 117, 235);
  Result.SurfaceBackground:=GuiColor(13, 18, 17, 222);
  Result.CardBackground:=GuiColor(12, 17, 16, 230);
  Result.CardBorder:=GuiColor(119, 132, 123, 235);
  Result.ControlBackground:=GuiColor(26, 34, 30, 230);
  Result.ControlBorder:=GuiColor(86, 101, 91, 235);
  Result.PrimaryAccent:=GuiColor(196, 230, 112);
  Result.SecondaryAccent:=GuiColor(147, 207, 111);
  Result.FocusAccent:=GuiColor(230, 211, 94);
  Result.Text:=GuiColor(242, 255, 222);
  Result.MutedText:=GuiColor(181, 204, 168);
  Result.PriceText:=GuiColor(248, 219, 117);
  Result.SuccessText:=GuiColor(173, 232, 115);
  Result.ControlTextOffset:=GuiPoint(0, 0);
  Result.ControlBorderWidth:=1;
  Metrics:=Result.Metrics;
  Metrics.ControlHeight:=24;
  Metrics.CompactControlHeight:=20;
  Metrics.ItemHeight:=34;
  Metrics.RowHeight:=24;
  Metrics.HeaderHeight:=24;
  Metrics.LineHeight:=20;
  Metrics.ControlPadding:=GuiBoxLTRB(8, 3, 8, 3);
  Metrics.TextPadding:=GuiBoxLTRB(8, 3, 8, 3);
  Metrics.ButtonPadding:=GuiBoxLTRB(10, 2, 10, 2);
  Result.Metrics:=Metrics;
end;

function AddPanel(AParent: TGuiControl; const ABounds: TGuiRect): TGuiPanel;
begin
  Result:=TGuiPanel.Create;
  Result.Bounds:=ABounds;
  Result.StyleClass:='Surface';
  AParent.Add(Result);
end;

function AddLabel(AParent: TGuiControl; const ACaption: String; const ABounds: TGuiRect; const AClass: String = ''): TGuiLabel;
begin
  Result:=TGuiLabel.Create;
  Result.Caption:=ACaption;
  Result.Bounds:=ABounds;
  Result.StyleClass:=AClass;
  AParent.Add(Result);
end;

function AddButton(AParent: TGuiControl; const ACaption: String; const ABounds: TGuiRect; AOnClick: TGuiNotifyEvent = nil): TGuiButton;
begin
  Result:=TGuiButton.Create;
  Result.Caption:=ACaption;
  Result.Bounds:=ABounds;
  Result.OnClick:=AOnClick;
  Result.ShowFocus:=False;
  AParent.Add(Result);
end;

function AddHudBar(AParent: TGuiControl; const ABounds: TGuiRect; AKind: TGustavHudBarKind; AValue, AMaxValue: TGuiFloat;
  const ACaption, ADetail: String): TGustavHudBar;
begin
  Result:=TGustavHudBar.Create;
  Result.Bounds:=ABounds;
  Result.Kind:=AKind;
  Result.Value:=AValue;
  Result.MaxValue:=AMaxValue;
  Result.Caption:=ACaption;
  Result.Detail:=ADetail;
  AParent.Add(Result);
end;

procedure ApplyGustavStyle(AControl: TGuiControl; const ATheme: TGuiTheme);
var
  I: Integer;
  Button: TGuiButton;
  CurrentStyle: TGuiStyle;
begin
  GuiApplyTheme(AControl, ATheme);
  AControl.ShowFocus:=False;

  if AControl IS TGuiPanel then
  begin
    CurrentStyle:=AControl.Style;
    CurrentStyle.BackgroundColor:=ATheme.PanelBackground;
    CurrentStyle.Background:=GuiColorDrawable(ATheme.PanelBackground);
    CurrentStyle.BorderColor:=ATheme.PanelBorder;
    AControl.Style:=CurrentStyle;
    AControl.BackgroundColor:=ATheme.PanelBackground;
    AControl.BorderColor:=ATheme.PanelBorder;
  end;

  if AControl IS TGuiButton then
  begin
    Button:=TGuiButton(AControl);
    CurrentStyle:=Button.Style;
    CurrentStyle.BackgroundColor:=GuiColor(20, 28, 24, 220);
    CurrentStyle.HoverBackgroundColor:=GuiColor(48, 64, 54, 236);
    CurrentStyle.PressedBackgroundColor:=GuiColor(63, 81, 66, 240);
    CurrentStyle.CheckedBackgroundColor:=CurrentStyle.PressedBackgroundColor;
    CurrentStyle.Background:=GuiColorDrawable(CurrentStyle.BackgroundColor);
    CurrentStyle.HoverBackground:=GuiColorDrawable(CurrentStyle.HoverBackgroundColor);
    CurrentStyle.PressedBackground:=GuiColorDrawable(CurrentStyle.PressedBackgroundColor);
    CurrentStyle.CheckedBackground:=CurrentStyle.PressedBackground;
    CurrentStyle.BorderColor:=GuiColor(82, 96, 86, 220);
    CurrentStyle.TextColor:=ATheme.Text;
    Button.Style:=CurrentStyle;
    Button.TextHorizontalAlign:=ghtaLeft;
  end;

  if AControl IS TGuiStatusBar then
  begin
    CurrentStyle:=AControl.Style;
    CurrentStyle.BackgroundColor:=GuiColor(12, 17, 16, 230);
    CurrentStyle.Background:=GuiColorDrawable(CurrentStyle.BackgroundColor);
    AControl.Style:=CurrentStyle;
  end;

  for I:=0 to AControl.ChildCount - 1 do
    ApplyGustavStyle(AControl.Children[I], ATheme);
end;

constructor TPixelGameBackground.Create;
begin
  inherited Create;
  Enabled:=False;
  ShowRail:=True;
end;

procedure DrawCloud(ACanvas: TGuiCanvas; AX, AY: TGuiFloat);
begin
  ACanvas.FillRect(GuiRect(AX + 0, AY + 14, 42, 10), GuiColor(235, 250, 246, 230));
  ACanvas.FillRect(GuiRect(AX + 18, AY + 6, 42, 18), GuiColor(241, 253, 248, 235));
  ACanvas.FillRect(GuiRect(AX + 50, AY + 12, 58, 12), GuiColor(232, 249, 246, 225));
  ACanvas.FillRect(GuiRect(AX + 10, AY + 24, 96, 8), GuiColor(180, 224, 230, 155));
end;

procedure DrawTree(ACanvas: TGuiCanvas; AX, ABaseline, AScale: TGuiFloat);
var
  H: TGuiFloat;
begin
  H:=90 * AScale;
  ACanvas.FillRect(GuiRect(AX + (8 * AScale), ABaseline - (H * 0.68), 7 * AScale, H * 0.68), GuiColor(47, 61, 42));
  ACanvas.FillRect(GuiRect(AX, ABaseline - H, 25 * AScale, 22 * AScale), GuiColor(27, 89, 74));
  ACanvas.FillRect(GuiRect(AX - (7 * AScale), ABaseline - (H * 0.78), 39 * AScale, 22 * AScale), GuiColor(34, 117, 82));
  ACanvas.FillRect(GuiRect(AX - (12 * AScale), ABaseline - (H * 0.56), 49 * AScale, 26 * AScale), GuiColor(24, 84, 66));
  ACanvas.FillRect(GuiRect(AX - (6 * AScale), ABaseline - (H * 0.32), 37 * AScale, 22 * AScale), GuiColor(19, 70, 57));
end;

constructor TGustavHudBar.Create;
begin
  inherited Create;
  Enabled:=False;
  Value:=0;
  MaxValue:=100;
  Caption:='';
  Detail:='';
  Kind:=hbkArmor;
end;

procedure TGustavHudBar.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  Track: TGuiRect;
  Fill: TGuiRect;
  Ratio: TGuiFloat;
  I: Integer;
  FillColor: TGuiColor;
  BackColor: TGuiColor;
begin
  Rect:=AbsoluteBounds;
  Ratio:=0;

  if MaxValue > 0 then
    Ratio:=Value / MaxValue;

  if Ratio < 0 then
    Ratio:=0;

  if Ratio > 1 then
    Ratio:=1;

  BackColor:=GuiColor(14, 19, 17, 226);
  FillColor:=GuiColor(165, 225, 105);

  case Kind of
    hbkArmor: FillColor:=GuiColor(107, 219, 83);
    hbkCharge: FillColor:=GuiColor(248, 210, 95);
    hbkMissile: FillColor:=GuiColor(221, 87, 78);
    hbkZoom: FillColor:=GuiColor(128, 211, 102);
  end;

  ACanvas.FillRect(Rect, BackColor);
  ACanvas.DrawBorder(Rect, 1, GuiColor(74, 88, 78, 230));
  ACanvas.DrawText(Caption, GuiRect(Rect.Left + 8, Rect.Top + 2, Rect.Width - 16, 16), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);

  Track:=GuiRect(Rect.Left + 8, Rect.Top + Rect.Height - 18, Rect.Width - 16, 8);
  if Kind = hbkCharge then
    Track:=GuiRect(Rect.Left + 8, Rect.Top + 24, Rect.Width - 16, 10);

  ACanvas.FillRect(Track, GuiColor(34, 37, 34, 230));

  if Kind = hbkArmor then
  begin
    for I:=0 to 9 do
      ACanvas.DrawBorder(GuiRect(Track.Left + (I * (Track.Width / 10)), Track.Top - 1, Track.Width / 10 - 2, Track.Height + 2), 1,
        GuiColor(57, 81, 54, 190));
  end;

  if Kind = hbkMissile then
  begin
    for I:=0 to 5 do
      ACanvas.FillRect(GuiRect(Track.Left + (I * (Track.Width / 6)), Track.Top, 1, Track.Height), GuiColor(57, 48, 45, 210));
  end;

  Fill:=Track;
  Fill.Width:=Track.Width * Ratio;
  ACanvas.FillRect(Fill, FillColor);

  if Kind = hbkCharge then
  begin
    ACanvas.DrawLine(GuiPoint(Track.Left + (Track.Width * 0.72), Track.Top - 4), GuiPoint(Track.Left + (Track.Width * 0.72), Track.Top + Track.Height + 5), 1,
      GuiColor(255, 241, 157, 220));
    ACanvas.DrawText(Detail, GuiRect(Rect.Left + 8, Rect.Top + 38, Rect.Width - 16, 18), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);
  end else
    ACanvas.DrawText(Detail, GuiRect(Rect.Left + 8, Rect.Top + 20, Rect.Width - 16, 18), GuiColor(190, 213, 176), ghtaLeft, gvtaCenter);
end;

constructor TGustavWindIndicator.Create;
begin
  inherited Create;
  Enabled:=False;
  Direction:=0.42;
  Speed:=10.9;
end;

procedure TGustavWindIndicator.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  Track: TGuiRect;
  ArrowX: TGuiFloat;
  I: Integer;
begin
  Rect:=AbsoluteBounds;
  ACanvas.FillRect(Rect, GuiColor(13, 18, 17, 224));
  ACanvas.DrawBorder(Rect, 1, GuiColor(112, 126, 117, 235));
  ACanvas.DrawText('WIND', GuiRect(Rect.Left + 10, Rect.Top + 6, 70, 18), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);
  ACanvas.DrawText(Format('%.1f m/s', [Speed]), GuiRect(Rect.Left + Rect.Width - 88, Rect.Top + 6, 76, 18), GuiColor(173, 232, 115), ghtaRight, gvtaCenter);
  ACanvas.DrawText('direction', GuiRect(Rect.Left + 10, Rect.Top + 32, 84, 18), GuiColor(190, 213, 176), ghtaLeft, gvtaCenter);

  Track:=GuiRect(Rect.Left + 90, Rect.Top + 38, Rect.Width - 116, 4);
  ACanvas.FillRect(Track, GuiColor(38, 42, 38, 235));

  for I:=0 to 4 do
    ACanvas.FillRect(GuiRect(Track.Left + (I * (Track.Width / 4)), Track.Top - 8, 2, 20), GuiColor(62, 70, 63, 230));

  ArrowX:=Track.Left + (Track.Width * Direction);
  ACanvas.FillRect(GuiRect(ArrowX - 10, Track.Top - 12, 20, 5), GuiColor(196, 230, 112));
  ACanvas.FillRect(GuiRect(ArrowX - 6, Track.Top - 7, 12, 5), GuiColor(196, 230, 112));
  ACanvas.FillRect(GuiRect(ArrowX - 2, Track.Top - 2, 4, 12), GuiColor(196, 230, 112));
  ACanvas.DrawText('W', GuiRect(Track.Left - 16, Track.Top - 8, 14, 18), GuiColor(190, 213, 176), ghtaCenter, gvtaCenter);
  ACanvas.DrawText('E', GuiRect(Track.Left + Track.Width + 2, Track.Top - 8, 14, 18), GuiColor(190, 213, 176), ghtaCenter, gvtaCenter);
end;

constructor TGustavTargetScope.Create;
begin
  inherited Create;
  Enabled:=False;
  EnemyCount:=2;
  TargetLock:=0.35;
end;

procedure TGustavTargetScope.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  Scope: TGuiRect;
  I: Integer;
  X: TGuiFloat;
begin
  Rect:=AbsoluteBounds;
  ACanvas.FillRect(Rect, GuiColor(13, 18, 17, 224));
  ACanvas.DrawBorder(Rect, 1, GuiColor(112, 126, 117, 235));
  ACanvas.DrawText('TARGETS', GuiRect(Rect.Left + 10, Rect.Top + 5, 130, 18), GuiColor(173, 232, 115), ghtaLeft, gvtaCenter);
  ACanvas.DrawText(Format('ENEMIES %d', [EnemyCount]),
    GuiRect(Rect.Left + Rect.Width - 108, Rect.Top + 5, 94, 18),
    GuiColor(242, 255, 222), ghtaRight, gvtaCenter);

  Scope:=GuiRect(Rect.Left + 12, Rect.Top + 32, Rect.Width - 24, 34);
  ACanvas.FillRect(Scope, GuiColor(18, 26, 21, 230));
  ACanvas.DrawBorder(Scope, 1, GuiColor(57, 70, 60, 235));

  for I:=0 to 7 do
  begin
    X:=Scope.Left + (I * (Scope.Width / 7));
    ACanvas.DrawLine(GuiPoint(X, Scope.Top + 2), GuiPoint(X, Scope.Top + Scope.Height - 2), 1, GuiColor(52, 62, 54, 170));
  end;

  X:=Scope.Left + (Scope.Width * TargetLock);
  ACanvas.DrawLine(GuiPoint(X, Scope.Top + 2), GuiPoint(X, Scope.Top + Scope.Height - 2), 2, GuiColor(196, 230, 112));
  ACanvas.FillRect(GuiRect(X - 12, Scope.Top + 8, 24, 2), GuiColor(196, 230, 112));
  ACanvas.FillRect(GuiRect(X - 12, Scope.Top + Scope.Height - 10, 24, 2), GuiColor(196, 230, 112));
  ACanvas.DrawText('forward contacts', GuiRect(Rect.Left + 12, Rect.Top + 72, Rect.Width - 24, 18), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('no firing solution', GuiRect(Rect.Left + 12, Rect.Top + 92, Rect.Width - 24, 18), GuiColor(190, 213, 176), ghtaLeft, gvtaCenter);
end;

constructor TGustavReadout.Create;
var
  I: Integer;
begin
  inherited Create;
  Enabled:=False;
  Title:='';
  for I:=0 to 3 do
    FLines[I]:='';
end;

procedure TGustavReadout.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  I: Integer;
begin
  Rect:=AbsoluteBounds;
  ACanvas.FillRect(Rect, GuiColor(13, 18, 17, 224));
  ACanvas.DrawBorder(Rect, 1, GuiColor(112, 126, 117, 235));
  ACanvas.DrawText(Title, GuiRect(Rect.Left + 10, Rect.Top + 5, Rect.Width - 20, 18), GuiColor(173, 232, 115), ghtaLeft, gvtaCenter);

  for I:=0 to 3 do
    if Lines[I] <> '' then
      ACanvas.DrawText(Lines[I], GuiRect(Rect.Left + 10, Rect.Top + 28 + (I * 18), Rect.Width - 20, 18), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);
end;

constructor TGustavBattleHud.Create;
begin
  inherited Create;
  Enabled:=False;
end;

procedure DrawHudChrome(ACanvas: TGuiCanvas; const ARect: TGuiRect; const ATitle: String);
var
  Corner: TGuiFloat;
begin
  Corner:=16;
  ACanvas.FillRect(ARect, GuiColor(9, 11, 10, 236));
  ACanvas.DrawBorder(ARect, 2, GuiColor(31, 34, 30, 245));
  ACanvas.DrawBorder(GuiRect(ARect.Left + 3, ARect.Top + 3, ARect.Width - 6, ARect.Height - 6), 1, GuiColor(112, 103, 80, 170));
  ACanvas.FillRect(GuiRect(ARect.Left + 6, ARect.Top + 6, ARect.Width - 12, 18), GuiColor(30, 32, 28, 210));
  ACanvas.FillRect(GuiRect(ARect.Left + 6, ARect.Top + ARect.Height - 8, ARect.Width - 12, 2), GuiColor(221, 238, 190, 45));
  ACanvas.DrawLine(GuiPoint(ARect.Left + Corner, ARect.Top + 5), GuiPoint(ARect.Left + Corner + 34, ARect.Top + 5), 2, GuiColor(210, 186, 120, 155));
  ACanvas.DrawLine(GuiPoint(ARect.Left + 5, ARect.Top + Corner), GuiPoint(ARect.Left + 5, ARect.Top + Corner + 26), 2, GuiColor(210, 186, 120, 115));
  ACanvas.DrawLine(GuiPoint(ARect.Left + ARect.Width - Corner - 34, ARect.Top + ARect.Height - 5),
    GuiPoint(ARect.Left + ARect.Width - Corner, ARect.Top + ARect.Height - 5), 2, GuiColor(210, 186, 120, 130));
  ACanvas.DrawLine(GuiPoint(ARect.Left + ARect.Width - 5, ARect.Top + ARect.Height - Corner - 26),
    GuiPoint(ARect.Left + ARect.Width - 5, ARect.Top + ARect.Height - Corner), 2, GuiColor(210, 186, 120, 110));
  ACanvas.FillRect(GuiRect(ARect.Left + 7, ARect.Top + 7, 6, 6), GuiColor(5, 6, 5, 245));
  ACanvas.FillRect(GuiRect(ARect.Left + ARect.Width - 13, ARect.Top + 7, 6, 6), GuiColor(5, 6, 5, 245));
  ACanvas.FillRect(GuiRect(ARect.Left + 7, ARect.Top + ARect.Height - 13, 6, 6), GuiColor(5, 6, 5, 245));
  ACanvas.FillRect(GuiRect(ARect.Left + ARect.Width - 13, ARect.Top + ARect.Height - 13, 6, 6), GuiColor(5, 6, 5, 245));

  if ATitle <> '' then
    ACanvas.DrawText(ATitle, GuiRect(ARect.Left + 14, ARect.Top + 6, ARect.Width - 28, 18), GuiColor(218, 195, 126), ghtaLeft, gvtaCenter);
end;

procedure DrawArc(ACanvas: TGuiCanvas; const ACenter: TGuiPoint; ARadius, AStartDeg, AEndDeg: TGuiFloat; AColor: TGuiColor);
var
  I: Integer;
  A1: TGuiFloat;
  A2: TGuiFloat;
  P1: TGuiPoint;
  P2: TGuiPoint;
begin
  for I:=0 to 40 do
  begin
    A1:=DegToRad(AStartDeg + ((AEndDeg - AStartDeg) * I / 41));
    A2:=DegToRad(AStartDeg + ((AEndDeg - AStartDeg) * (I + 1) / 41));
    P1:=GuiPoint(ACenter.X + Cos(A1) * ARadius, ACenter.Y - Sin(A1) * ARadius);
    P2:=GuiPoint(ACenter.X + Cos(A2) * ARadius, ACenter.Y - Sin(A2) * ARadius);
    ACanvas.DrawLine(P1, P2, 2, AColor);
  end;
end;

procedure DrawDial(ACanvas: TGuiCanvas; const ACenter: TGuiPoint; ARadius: TGuiFloat; ARatio: TGuiFloat);
var
  I: Integer;
  Angle: TGuiFloat;
  P1: TGuiPoint;
  P2: TGuiPoint;
begin
  ACanvas.FillRect(GuiRect(ACenter.X - ARadius, ACenter.Y - ARadius, ARadius * 2, ARadius * 2), GuiColor(8, 10, 9, 238));
  ACanvas.DrawBorder(GuiRect(ACenter.X - ARadius, ACenter.Y - ARadius, ARadius * 2, ARadius * 2), 2, GuiColor(56, 52, 43, 235));
  ACanvas.DrawBorder(GuiRect(ACenter.X - ARadius + 9, ACenter.Y - ARadius + 9, (ARadius - 9) * 2, (ARadius - 9) * 2), 1, GuiColor(121, 104, 70, 210));

  for I:=0 to 32 do
  begin
    Angle:=DegToRad(220 - (260 * I / 32));
    P1:=GuiPoint(ACenter.X + Cos(Angle) * (ARadius - 12), ACenter.Y - Sin(Angle) * (ARadius - 12));
    P2:=GuiPoint(ACenter.X + Cos(Angle) * (ARadius - 3), ACenter.Y - Sin(Angle) * (ARadius - 3));
    if I < Round(32 * ARatio) then
      ACanvas.DrawLine(P1, P2, 2, GuiColor(142, 210, 72))
    else
      ACanvas.DrawLine(P1, P2, 1, GuiColor(74, 69, 52));
  end;

  Angle:=DegToRad(220 - (260 * ARatio));
  ACanvas.DrawLine(ACenter, GuiPoint(ACenter.X + Cos(Angle) * (ARadius - 22), ACenter.Y - Sin(Angle) * (ARadius - 22)), 3, GuiColor(232, 222, 170));
  ACanvas.FillRect(GuiRect(ACenter.X - 7, ACenter.Y - 7, 14, 14), GuiColor(28, 25, 20));
end;

procedure DrawShell(ACanvas: TGuiCanvas; const ARect: TGuiRect; AColor: TGuiColor);
begin
  ACanvas.FillRect(GuiRect(ARect.Left + 18, ARect.Top + 8, ARect.Width - 34, ARect.Height - 16), AColor);
  ACanvas.DrawLine(GuiPoint(ARect.Left + ARect.Width - 16, ARect.Top + 8), GuiPoint(ARect.Left + ARect.Width - 2, ARect.Top + (ARect.Height / 2)), 4, AColor);
  ACanvas.DrawLine(GuiPoint(ARect.Left + ARect.Width - 16, ARect.Top + ARect.Height - 8),
    GuiPoint(ARect.Left + ARect.Width - 2, ARect.Top + (ARect.Height / 2)), 4, AColor);
  ACanvas.DrawBorder(GuiRect(ARect.Left + 18, ARect.Top + 8, ARect.Width - 34, ARect.Height - 16), 1, GuiColor(210, 197, 161, 130));
  ACanvas.FillRect(GuiRect(ARect.Left + 4, ARect.Top + 13, 16, ARect.Height - 26), GuiColor(48, 45, 39));
end;

procedure DrawTinyTicks(ACanvas: TGuiCanvas; const ARect: TGuiRect; ACount: Integer; AColor: TGuiColor);
var
  I: Integer;
  X: TGuiFloat;
begin
  if ACount <= 1 then
    Exit;

  for I:=0 to ACount - 1 do
  begin
    X:=ARect.Left + (I * (ARect.Width / (ACount - 1)));
    ACanvas.FillRect(GuiRect(X, ARect.Top, 1, ARect.Height), AColor);
  end;
end;

procedure DrawSegmentGauge(ACanvas: TGuiCanvas; const ARect: TGuiRect; ASegments, AFilled: Integer; AFillColor: TGuiColor);
var
  I: Integer;
  Segment: TGuiRect;
  Gap: TGuiFloat;
  WidthValue: TGuiFloat;
begin
  Gap:=3;

  if ASegments <= 0 then
    Exit;

  WidthValue:=(ARect.Width - ((ASegments - 1) * Gap)) / ASegments;

  for I:=0 to ASegments - 1 do
  begin
    Segment:=GuiRect(ARect.Left + (I * (WidthValue + Gap)), ARect.Top, WidthValue, ARect.Height);
    ACanvas.FillRect(Segment, GuiColor(31, 36, 31, 225));
    ACanvas.DrawBorder(Segment, 1, GuiColor(67, 77, 67, 210));
    if I < AFilled then
      ACanvas.FillRect(GuiRect(Segment.Left + 2, Segment.Top + 2, Segment.Width - 4, Segment.Height - 4), AFillColor);
  end;
end;

procedure DrawChargeRail(ACanvas: TGuiCanvas; const ARect: TGuiRect; ARatio: TGuiFloat);
var
  FillRect: TGuiRect;
  I: Integer;
  X: TGuiFloat;
begin
  if ARatio < 0 then
    ARatio:=0;

  if ARatio > 1 then
    ARatio:=1;

  ACanvas.FillRect(ARect, GuiColor(30, 32, 29, 235));
  ACanvas.DrawBorder(ARect, 1, GuiColor(79, 88, 73, 230));
  FillRect:=GuiRect(ARect.Left + 2, ARect.Top + 2, (ARect.Width - 4) * ARatio, ARect.Height - 4);
  ACanvas.FillRect(FillRect, GuiColor(248, 210, 95));

  for I:=0 to 8 do
  begin
    X:=ARect.Left + (I * (ARect.Width / 8));
    ACanvas.DrawLine(GuiPoint(X, ARect.Top - 5), GuiPoint(X, ARect.Top + ARect.Height + 4), 1, GuiColor(95, 89, 63, 190));
  end;

  X:=ARect.Left + (ARect.Width * 0.72);
  ACanvas.DrawLine(GuiPoint(X, ARect.Top - 8), GuiPoint(X, ARect.Top + ARect.Height + 8), 2, GuiColor(255, 245, 166, 220));
end;

procedure TGustavBattleHud.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  TopBar: TGuiRect;
  Panel: TGuiRect;
  Scope: TGuiRect;
  WindTrack: TGuiRect;
  X: TGuiFloat;
  Y: TGuiFloat;
  I: Integer;
begin
  Rect:=AbsoluteBounds;

  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top, Rect.Width, 76), GuiColor(12, 12, 10, 238));
  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top + 70, Rect.Width, 5), GuiColor(44, 39, 29, 245));
  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top + 75, Rect.Width, 2), GuiColor(192, 166, 103, 120));
  TopBar:=GuiRect(Rect.Left + 8, Rect.Top + 10, Rect.Width - 16, 54);
  ACanvas.DrawBorder(TopBar, 2, GuiColor(37, 35, 29, 255));
  ACanvas.DrawBorder(GuiRect(TopBar.Left + 4, TopBar.Top + 4, TopBar.Width - 8, TopBar.Height - 8), 1, GuiColor(112, 103, 80, 165));
  ACanvas.DrawText('SCHWERER GUSTAV', GuiRect(TopBar.Left + 48, TopBar.Top + 8, 210, 22), GuiColor(232, 222, 190), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('ENDLESS SIEGE', GuiRect(TopBar.Left + 78, TopBar.Top + 31, 150, 16), GuiColor(155, 143, 112), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('WAVE 1', GuiRect(TopBar.Left + 278, TopBar.Top + 8, 98, 22), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('FRONT APPROACH', GuiRect(TopBar.Left + 278, TopBar.Top + 31, 130, 16), GuiColor(190, 213, 176), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('KILLS  0', GuiRect(TopBar.Left + 448, TopBar.Top + 8, 90, 22), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('SALVAGE  $80', GuiRect(TopBar.Left + 556, TopBar.Top + 8, 132, 22), GuiColor(248, 219, 117), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('ZOOM', GuiRect(TopBar.Left + 810, TopBar.Top + 8, 70, 22), GuiColor(190, 213, 176), ghtaCenter, gvtaCenter);
  ACanvas.DrawText('100%', GuiRect(TopBar.Left + 810, TopBar.Top + 31, 70, 16), GuiColor(242, 255, 222), ghtaCenter, gvtaCenter);
  ACanvas.DrawText('GUSTAV HP', GuiRect(TopBar.Left + TopBar.Width - 330, TopBar.Top + 8, 120, 18), GuiColor(248, 219, 117), ghtaLeft, gvtaCenter);
  DrawSegmentGauge(ACanvas, GuiRect(TopBar.Left + TopBar.Width - 330, TopBar.Top + 31, 210, 14), 18, 18, GuiColor(128, 211, 102));
  ACanvas.DrawText('100%', GuiRect(TopBar.Left + TopBar.Width - 106, TopBar.Top + 28, 60, 18), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);

  Panel:=GuiRect(Rect.Left + 18, Rect.Top + 100, 334, 120);
  DrawHudChrome(ACanvas, Panel, 'SITUATION REPORT');
  ACanvas.DrawText('> WAVE 1 - FRONT APPROACH', GuiRect(Panel.Left + 18, Panel.Top + 40, 260, 18), GuiColor(173, 232, 115), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('> WEATHER: CLEAR', GuiRect(Panel.Left + 18, Panel.Top + 64, 220, 18), GuiColor(173, 232, 115), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('> VISIBILITY: GOOD', GuiRect(Panel.Left + 18, Panel.Top + 88, 220, 18), GuiColor(173, 232, 115), ghtaLeft, gvtaCenter);

  Panel:=GuiRect(Rect.Left + (Rect.Width / 2) - 160, Rect.Top + 96, 320, 96);
  DrawHudChrome(ACanvas, Panel, 'WIND');
  ACanvas.DrawText('10.9  m/s', GuiRect(Panel.Left + Panel.Width - 96, Panel.Top + 7, 82, 18), GuiColor(173, 232, 115), ghtaRight, gvtaCenter);
  WindTrack:=GuiRect(Panel.Left + 46, Panel.Top + 50, Panel.Width - 92, 5);
  ACanvas.FillRect(WindTrack, GuiColor(39, 43, 38, 235));
  DrawTinyTicks(ACanvas, GuiRect(WindTrack.Left, WindTrack.Top - 10, WindTrack.Width, 24), 7, GuiColor(78, 88, 77, 220));
  X:=WindTrack.Left + (WindTrack.Width * 0.38);
  ACanvas.DrawLine(GuiPoint(X - 24, WindTrack.Top - 14), GuiPoint(X, WindTrack.Top - 14), 4, GuiColor(196, 230, 112));
  ACanvas.DrawLine(GuiPoint(X, WindTrack.Top - 14), GuiPoint(X + 18, WindTrack.Top), 4, GuiColor(196, 230, 112));
  ACanvas.DrawLine(GuiPoint(X, WindTrack.Top - 14), GuiPoint(X + 18, WindTrack.Top - 28), 4, GuiColor(196, 230, 112));
  ACanvas.DrawText('W', GuiRect(WindTrack.Left - 20, WindTrack.Top - 9, 16, 18), GuiColor(190, 213, 176), ghtaCenter, gvtaCenter);
  ACanvas.DrawText('E', GuiRect(WindTrack.Left + WindTrack.Width + 4, WindTrack.Top - 9, 16, 18), GuiColor(190, 213, 176), ghtaCenter, gvtaCenter);

  Panel:=GuiRect(Rect.Left + Rect.Width - 492, Rect.Top + 104, 470, 148);
  DrawHudChrome(ACanvas, Panel, 'TARGETS');
  Scope:=GuiRect(Panel.Left + Panel.Width - 154, Panel.Top + 18, 132, 112);
  ACanvas.FillRect(Scope, GuiColor(16, 24, 20, 232));
  ACanvas.DrawBorder(Scope, 2, GuiColor(29, 31, 28, 255));
  ACanvas.DrawBorder(GuiRect(Scope.Left + 6, Scope.Top + 6, Scope.Width - 12, Scope.Height - 12), 1, GuiColor(69, 95, 68, 190));
  for I:=0 to 4 do
  begin
    X:=Scope.Left + 12 + (I * ((Scope.Width - 24) / 4));
    ACanvas.DrawLine(GuiPoint(X, Scope.Top + 10), GuiPoint(X, Scope.Top + Scope.Height - 10), 1, GuiColor(47, 74, 50, 145));
  end;
  for I:=0 to 4 do
  begin
    Y:=Scope.Top + 10 + (I * ((Scope.Height - 20) / 4));
    ACanvas.DrawLine(GuiPoint(Scope.Left + 10, Y), GuiPoint(Scope.Left + Scope.Width - 10, Y), 1, GuiColor(47, 74, 50, 145));
  end;
  ACanvas.DrawLine(GuiPoint(Scope.Left + (Scope.Width / 2), Scope.Top + 14),
    GuiPoint(Scope.Left + (Scope.Width / 2), Scope.Top + Scope.Height - 14),
    1, GuiColor(84, 130, 76, 170));
  ACanvas.DrawLine(GuiPoint(Scope.Left + 14, Scope.Top + (Scope.Height / 2)),
    GuiPoint(Scope.Left + Scope.Width - 14, Scope.Top + (Scope.Height / 2)),
    1, GuiColor(84, 130, 76, 170));
  ACanvas.DrawText('+500m', GuiRect(Scope.Left + Scope.Width - 44, Scope.Top + 8, 38, 16), GuiColor(242, 255, 222), ghtaRight, gvtaCenter);
  ACanvas.DrawText('-500m', GuiRect(Scope.Left + Scope.Width - 44, Scope.Top + Scope.Height - 22, 38, 16), GuiColor(242, 255, 222), ghtaRight, gvtaCenter);
  DrawSegmentGauge(ACanvas, GuiRect(Panel.Left + 18, Panel.Top + 44, 250, 14), 18, 18, GuiColor(107, 219, 83));
  ACanvas.DrawText('ARMOR 100/100      ENEMIES 2', GuiRect(Panel.Left + 18, Panel.Top + 66, 260, 18), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('FORWARD CONTACTS', GuiRect(Panel.Left + 18, Panel.Top + 96, 200, 18), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('NO TARGETS IN SIGHT', GuiRect(Panel.Left + 18, Panel.Top + 118, 220, 18), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);

  DrawArc(ACanvas, GuiPoint(Rect.Left + 420, Rect.Top + Rect.Height - 94), 292, 64, 174, GuiColor(232, 222, 190, 150));
  DrawArc(ACanvas, GuiPoint(Rect.Left + 420, Rect.Top + Rect.Height - 94), 292, 86, 96, GuiColor(128, 211, 102, 230));
  for I:=0 to 16 do
  begin
    X:=DegToRad(64 + (110 * I / 16));
    ACanvas.DrawLine(GuiPoint(Rect.Left + 420 + Cos(X) * 282, Rect.Top + Rect.Height - 94 - Sin(X) * 282),
      GuiPoint(Rect.Left + 420 + Cos(X) * 292, Rect.Top + Rect.Height - 94 - Sin(X) * 292), 1, GuiColor(232, 222, 190, 120));
  end;
  ACanvas.DrawLine(GuiPoint(Rect.Left + 420, Rect.Top + Rect.Height - 94), GuiPoint(Rect.Left + 420, Rect.Top + 302), 2, GuiColor(232, 222, 190, 115));
  ACanvas.DrawLine(GuiPoint(Rect.Left + 408, Rect.Top + 358), GuiPoint(Rect.Left + 420, Rect.Top + 346), 3, GuiColor(128, 211, 102, 220));
  ACanvas.DrawLine(GuiPoint(Rect.Left + 432, Rect.Top + 358), GuiPoint(Rect.Left + 420, Rect.Top + 346), 3, GuiColor(128, 211, 102, 220));

  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top + Rect.Height - 280, Rect.Width, 28), GuiColor(20, 18, 14, 195));
  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top + Rect.Height - 252, Rect.Width, 8), GuiColor(64, 52, 34, 230));
  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top + Rect.Height - 244, Rect.Width, 172), GuiColor(19, 18, 15, 242));
  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top + Rect.Height - 72, Rect.Width, 72), GuiColor(11, 11, 10, 250));
  ACanvas.DrawLine(GuiPoint(Rect.Left, Rect.Top + Rect.Height - 244),
    GuiPoint(Rect.Left + Rect.Width, Rect.Top + Rect.Height - 244),
    2, GuiColor(112, 103, 80, 160));

  Panel:=GuiRect(Rect.Left + 12, Rect.Top + Rect.Height - 224, 438, 158);
  DrawHudChrome(ACanvas, Panel, 'GUSTAV');
  ACanvas.DrawBorder(GuiRect(Panel.Left + 22, Panel.Top + 34, 152, 68), 1, GuiColor(83, 84, 69, 150));
  ACanvas.DrawLine(GuiPoint(Panel.Left + 44, Panel.Top + 82), GuiPoint(Panel.Left + 150, Panel.Top + 48), 1, GuiColor(153, 150, 116, 120));
  ACanvas.DrawLine(GuiPoint(Panel.Left + 44, Panel.Top + 82), GuiPoint(Panel.Left + 166, Panel.Top + 88), 1, GuiColor(153, 150, 116, 120));
  ACanvas.DrawLine(GuiPoint(Panel.Left + 70, Panel.Top + 66), GuiPoint(Panel.Left + 140, Panel.Top + 80), 4, GuiColor(153, 150, 116, 100));
  ACanvas.DrawText('STATUS       YOUR TURN', GuiRect(Panel.Left + 194, Panel.Top + 36, 220, 18), GuiColor(173, 232, 115), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('MOUNT        ANCHORED', GuiRect(Panel.Left + 194, Panel.Top + 56, 220, 18), GuiColor(173, 232, 115), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('PD AMMO      3 / 6', GuiRect(Panel.Left + 194, Panel.Top + 76, 220, 18), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);
  DrawSegmentGauge(ACanvas, GuiRect(Panel.Left + 20, Panel.Top + 116, 90, 22), 3, 3, GuiColor(248, 219, 117));
  ACanvas.DrawText('WEAPON  800mm AP', GuiRect(Panel.Left + 122, Panel.Top + 116, 150, 22), GuiColor(248, 219, 117), ghtaLeft, gvtaCenter);
  DrawSegmentGauge(ACanvas, GuiRect(Panel.Left + 286, Panel.Top + 116, 116, 22), 5, 4, GuiColor(173, 232, 115));

  Panel:=GuiRect(Rect.Left + (Rect.Width / 2) - 230, Rect.Top + Rect.Height - 250, 460, 184);
  DrawHudChrome(ACanvas, Panel, 'FIRE CONTROL');
  ACanvas.DrawText('ARC', GuiRect(Panel.Left + 36, Panel.Top + 48, 70, 18), GuiColor(190, 213, 176), ghtaCenter, gvtaCenter);
  ACanvas.DrawText('36.0 deg', GuiRect(Panel.Left + 28, Panel.Top + 70, 96, 30), GuiColor(242, 255, 222), ghtaCenter, gvtaCenter);
  ACanvas.DrawText('CHARGE', GuiRect(Panel.Left + Panel.Width - 132, Panel.Top + 48, 90, 18), GuiColor(190, 213, 176), ghtaCenter, gvtaCenter);
  ACanvas.DrawText('105 / 145', GuiRect(Panel.Left + Panel.Width - 148, Panel.Top + 70, 120, 30), GuiColor(242, 255, 222), ghtaCenter, gvtaCenter);
  DrawDial(ACanvas, GuiPoint(Panel.Left + (Panel.Width / 2), Panel.Top + 92), 70, 105 / 145);
  DrawShell(ACanvas, GuiRect(Panel.Left + (Panel.Width / 2) - 24, Panel.Top + 58, 48, 70), GuiColor(195, 178, 135));
  ACanvas.FillRect(GuiRect(Panel.Left + 144, Panel.Top + 134, Panel.Width - 288, 38), GuiColor(116, 28, 24, 235));
  ACanvas.DrawBorder(GuiRect(Panel.Left + 144, Panel.Top + 134, Panel.Width - 288, 38), 2, GuiColor(178, 87, 72, 230));
  ACanvas.DrawText('FIRE', GuiRect(Panel.Left + 144, Panel.Top + 134, Panel.Width - 288, 38), GuiColor(255, 228, 186), ghtaCenter, gvtaCenter);

  Panel:=GuiRect(Rect.Left + Rect.Width - 450, Rect.Top + Rect.Height - 224, 438, 158);
  DrawHudChrome(ACanvas, Panel, 'ORDNANCE');
  ACanvas.DrawText('SELECTED', GuiRect(Panel.Left + 20, Panel.Top + 34, 120, 18), GuiColor(190, 213, 176), ghtaLeft, gvtaCenter);
  ACanvas.DrawText('800mm AP  INF', GuiRect(Panel.Left + 20, Panel.Top + 54, 150, 18), GuiColor(248, 219, 117), ghtaLeft, gvtaCenter);
  DrawShell(ACanvas, GuiRect(Panel.Left + 188, Panel.Top + 42, 120, 34), GuiColor(164, 160, 145));
  ACanvas.DrawText('V3 MISSILE', GuiRect(Panel.Left + 20, Panel.Top + 98, 120, 18), GuiColor(242, 255, 222), ghtaLeft, gvtaCenter);
  DrawSegmentGauge(ACanvas, GuiRect(Panel.Left + 110, Panel.Top + 100, 180, 14), 10, 0, GuiColor(221, 87, 78));
  ACanvas.DrawText('POINT DEFENSE', GuiRect(Panel.Left + 308, Panel.Top + 34, 112, 18), GuiColor(248, 219, 117), ghtaLeft, gvtaCenter);
  DrawDial(ACanvas, GuiPoint(Panel.Left + 360, Panel.Top + 94), 42, 0.62);
end;

procedure TPixelGameBackground.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  I: Integer;
  X: TGuiFloat;
  GroundY: TGuiFloat;
begin
  Rect:=AbsoluteBounds;
  ACanvas.FillRect(Rect, GuiColor(74, 148, 188));
  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top + 124, Rect.Width, 152), GuiColor(179, 225, 230));

  DrawCloud(ACanvas, Rect.Left + 8, Rect.Top + 205);
  DrawCloud(ACanvas, Rect.Left + 210, Rect.Top + 245);
  DrawCloud(ACanvas, Rect.Left + Rect.Width - 330, Rect.Top + 214);
  DrawCloud(ACanvas, Rect.Left + Rect.Width - 150, Rect.Top + 246);

  for I:=0 to 13 do
  begin
    X:=Rect.Left + (I * 110);
    ACanvas.FillRect(GuiRect(X, Rect.Top + 255 + ((I MOD 4) * 12), 150, 180), GuiColor(112, 184, 211));
    ACanvas.FillRect(GuiRect(X + 22, Rect.Top + 286 + ((I MOD 3) * 9), 120, 128), GuiColor(87, 161, 199));
  end;

  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top + 392, Rect.Width, 110), GuiColor(175, 215, 151));
  for I:=0 to 18 do
  begin
    X:=Rect.Left + (I * 82);
    ACanvas.FillRect(GuiRect(X, Rect.Top + 394 + ((I MOD 5) * 10), 92, 86), GuiColor(126, 190, 148, 200));
  end;

  GroundY:=Rect.Top + Rect.Height - 176;
  ACanvas.FillRect(GuiRect(Rect.Left, GroundY - 40, Rect.Width, 72), GuiColor(120, 166, 78));
  for I:=0 to 26 do
    ACanvas.FillRect(GuiRect(Rect.Left + (I * 58), GroundY - 54 - ((I MOD 6) * 9), 84, 68 + ((I MOD 5) * 7)), GuiColor(133, 178, 82));

  for I:=0 to 24 do
    DrawTree(ACanvas, Rect.Left + 32 + (I * 56), GroundY + 44 + ((I MOD 3) * 10), 0.75 + ((I MOD 4) * 0.12));

  ACanvas.FillRect(GuiRect(Rect.Left, GroundY + 54, Rect.Width, Rect.Height - GroundY - 54), GuiColor(117, 153, 76));
  for I:=0 to Trunc(Rect.Width / 8) do
    ACanvas.FillRect(GuiRect(Rect.Left + (I * 8), GroundY + 54, 1, Rect.Height - GroundY - 54), GuiColor(95, 135, 66, 72));

  if ShowRail then
  begin
    ACanvas.FillRect(GuiRect(Rect.Left, GroundY + 24, Rect.Width, 6), GuiColor(60, 50, 43));
    ACanvas.FillRect(GuiRect(Rect.Left, GroundY + 32, Rect.Width, 5), GuiColor(41, 38, 34));
    for I:=0 to Trunc(Rect.Width / 32) do
      ACanvas.FillRect(GuiRect(Rect.Left + (I * 32), GroundY + 22, 18, 18), GuiColor(82, 65, 49));

    ACanvas.FillRect(GuiRect(Rect.Left + 64, GroundY - 20, 146, 38), GuiColor(18, 23, 20));
    ACanvas.FillRect(GuiRect(Rect.Left + 88, GroundY - 54, 118, 36), GuiColor(25, 33, 28));
    ACanvas.DrawLine(GuiPoint(Rect.Left + 146, GroundY - 52), GuiPoint(Rect.Left + 288, GroundY - 124), 4, GuiColor(34, 42, 38));
    ACanvas.DrawLine(GuiPoint(Rect.Left + 150, GroundY - 48), GuiPoint(Rect.Left + 292, GroundY - 120), 1, GuiColor(116, 126, 110));
    ACanvas.FillRect(GuiRect(Rect.Left + 72, GroundY + 10, 22, 22), GuiColor(7, 8, 7));
    ACanvas.FillRect(GuiRect(Rect.Left + 158, GroundY + 10, 22, 22), GuiColor(7, 8, 7));
  end;
end;

procedure TDemoHandlers.SetScreen(AScreen: TGustavScreen);
begin
  MenuLayer.Visible:=AScreen = gsMenu;
  HudLayer.Visible:=(AScreen = gsHud) OR (AScreen = gsShop);
  ShopLayer.Visible:=AScreen = gsShop;

  case AScreen of
    gsMenu: StatusBar.Caption:='GUSTAVWARS command menu';
    gsHud: StatusBar.Caption:='Wave 1 - front approach / no targets in sight';
    gsShop: StatusBar.Caption:='Rail depot - purchases are delivered to Gustav magazine stores';
  end;
end;

procedure TDemoHandlers.ShowMenu(Sender: TGuiControl);
begin
  SetScreen(gsMenu);
end;

procedure TDemoHandlers.ShowHud(Sender: TGuiControl);
begin
  SetScreen(gsHud);
end;

procedure TDemoHandlers.ShowShop(Sender: TGuiControl);
begin
  SetScreen(gsShop);
end;

procedure TDemoHandlers.ExitApp(Sender: TGuiControl);
begin
  AppRunning:=False;
end;

procedure BuildMenu(AParent: TGuiControl; AHandlers: TDemoHandlers);
var
  Panel: TGuiPanel;
begin
  Panel:=AddPanel(AParent, GuiRect(382, 172, 520, 360));
  Panel.Anchors:=[];
  Panel.Padding:=GuiBox(24);
  AddLabel(Panel, 'GUSTAVWARS', GuiRect(26, 22, 240, 24), 'Success');
  AddLabel(Panel, 'Endless railway artillery survival', GuiRect(26, 68, 380, 24));
  AddButton(Panel, '> New Run', GuiRect(36, 116, 180, 28), AHandlers.ShowHud);
  AddButton(Panel, '  Upgrades', GuiRect(36, 150, 180, 28), AHandlers.ShowShop);
  AddButton(Panel, '  Options', GuiRect(36, 184, 180, 28), nil);
  AddButton(Panel, '  Exit', GuiRect(36, 218, 180, 28), AHandlers.ExitApp);
  AddLabel(Panel, 'Arrow keys select. Enter confirms. Esc exits.', GuiRect(26, 292, 420, 24));
end;

procedure BuildHud(AParent: TGuiControl; AHandlers: TDemoHandlers);
var
  Hud: TGustavBattleHud;
begin
  Hud:=TGustavBattleHud.Create;
  Hud.Bounds:=GuiRect(0, 0, 1280, 720);
  Hud.Align:=gaClient;
  AParent.Add(Hud);

  AddButton(AParent, 'DEPOT', GuiRect(1116, 48, 74, 24), AHandlers.ShowShop).Anchors:=[ganTop, ganRight];
  AddButton(AParent, 'MENU', GuiRect(1196, 48, 74, 24), AHandlers.ShowMenu).Anchors:=[ganTop, ganRight];
end;

procedure BuildShop(AParent: TGuiControl; AHandlers: TDemoHandlers);
var
  Panel: TGuiPanel;
  List: TGuiListBox;
  Detail: TGuiPanel;
  ItemPanel: TGuiPanel;
  CurrentStyle: TGuiStyle;
begin
  Panel:=AddPanel(AParent, GuiRect(212, 156, 860, 470));
  Panel.Anchors:=[];
  AddLabel(Panel, 'RAIL DEPOT', GuiRect(18, 10, 180, 18), 'Success');
  AddLabel(Panel, 'Salvage $80        Weapons / Ammo / Support', GuiRect(18, 30, 420, 18));
  AddButton(Panel, 'X', GuiRect(814, 14, 30, 26), AHandlers.ShowHud);
  AddLabel(Panel, 'WEAPONS', GuiRect(28, 60, 100, 18), 'Success');
  AddLabel(Panel, 'AMMO', GuiRect(146, 60, 80, 18));
  AddLabel(Panel, 'SUPPORT', GuiRect(264, 60, 100, 18));
  AddLabel(Panel, 'STORE INVENTORY', GuiRect(18, 84, 180, 18));

  List:=TGuiListBox.Create;
  List.Bounds:=GuiRect(18, 104, 430, 306);
  List.ItemHeight:=34;
  List.Items.Add('800mm AP   INF     DMG 42  BLAST 48   default');
  List.Items.Add('Siege HE  $180     DMG 54  BLAST 64   pack 3');
  List.Items.Add('Earth Shaker $160  DMG 18  BLAST 78   pack 3');
  List.Items.Add('Dora Charge $1000  DMG 82  BLAST 108  pack 3');
  List.Items.Add('Bunker Buster $540 DMG 36  BLAST 44   pack 3');
  List.Items.Add('Mine Rake $220     DMG 14  BLAST 92   pack 3');
  List.Items.Add('APHE Penetrator $420 DMG 48 BLAST 36  pack 2');
  List.Items.Add('Cluster Munitions $420 DMG 5 BLAST 92  pack 3');
  List.SelectedIndex:=4;
  Panel.Add(List);

  Detail:=AddPanel(Panel, GuiRect(466, 104, 376, 314));
  AddLabel(Detail, 'ITEM DETAILS', GuiRect(14, -22, 180, 18), 'Success');
  ItemPanel:=AddPanel(Detail, GuiRect(16, 18, 344, 40));
  CurrentStyle:=ItemPanel.Style;
  CurrentStyle.BackgroundColor:=GuiColor(46, 36, 16, 210);
  ItemPanel.Style:=CurrentStyle;
  AddLabel(ItemPanel, 'AMMUNITION', GuiRect(46, 4, 180, 18), 'Success');
  AddLabel(ItemPanel, 'Bunker Buster', GuiRect(46, 20, 180, 18));
  AddLabel(Detail, 'Pricey concrete drill shell.', GuiRect(16, 74, 300, 20));
  AddLabel(Detail, 'Damage 36   Blast 44', GuiRect(16, 100, 300, 20));
  AddLabel(Detail, 'Terrain 4.2   Stock x0', GuiRect(16, 122, 300, 20));
  AddPanel(Detail, GuiRect(16, 162, 344, 40));
  AddLabel(Detail, '$540 / pack 3', GuiRect(26, 172, 200, 20), 'Price');
  AddLabel(Panel, 'Purchases are delivered to Gustav magazine stores.', GuiRect(18, 430, 520, 22));
end;

var
  Window: PSDL_Window;
  Renderer: PSDL_Renderer;
  SdlEvent: TSDL_Event;
  Context: TGuiContext;
  Host: TGuiSDL3Host;
  FontRenderer: TGuiSDLTTFFontRenderer;
  Theme: TGuiTheme;
  Handlers: TDemoHandlers;
  Background: TPixelGameBackground;
  Width: Integer;
  Height: Integer;
begin
  Window:=nil;
  Renderer:=nil;
  Context:=nil;
  Host:=nil;
  FontRenderer:=nil;
  Handlers:=nil;
  Theme:=GustavTheme;

  if NOT SDL_Init(SDL_INIT_VIDEO OR SDL_INIT_GAMEPAD) then
    raise Exception.CreateFmt('SDL_Init failed: %s', [String(SDL_GetError)]);

  try
    Window:=SDL_CreateWindow('Schwerer Gustav - Endless Siege', 1280, 720, SDL_WINDOW_RESIZABLE);
    if NOT Assigned(Window) then
      raise Exception.CreateFmt('SDL_CreateWindow failed: %s', [String(SDL_GetError)]);

    SDL_StartTextInput(Window);

    Renderer:=SDL_CreateRenderer(Window, nil);
    if NOT Assigned(Renderer) then
      raise Exception.CreateFmt('SDL_CreateRenderer failed: %s', [String(SDL_GetError)]);

    Context:=TGuiContext.Create;
    Context.Resize(1280, 720);
    Context.ShowFocus:=False;

    Host:=TGuiSDL3Host.Create(Renderer, Context);
    FontRenderer:=TGuiSDLTTFFontRenderer.Create(GuiDefaultFontFile(True), 13);
    Host.FontRenderer:=FontRenderer;

    Handlers:=TDemoHandlers.Create;
    Handlers.Context:=Context;

    Background:=TPixelGameBackground.Create;
    Background.Bounds:=GuiRect(0, 0, 1280, 720);
    Background.Align:=gaClient;
    Context.Root.Add(Background);

    Handlers.MenuLayer:=TGuiTransparentPanel.Create;
    Handlers.MenuLayer.Bounds:=GuiRect(0, 0, 1280, 720);
    Handlers.MenuLayer.Align:=gaClient;
    Context.Root.Add(Handlers.MenuLayer);

    Handlers.HudLayer:=TGuiTransparentPanel.Create;
    Handlers.HudLayer.Bounds:=GuiRect(0, 0, 1280, 720);
    Handlers.HudLayer.Align:=gaClient;
    Context.Root.Add(Handlers.HudLayer);

    Handlers.ShopLayer:=TGuiTransparentPanel.Create;
    Handlers.ShopLayer.Bounds:=GuiRect(0, 0, 1280, 720);
    Handlers.ShopLayer.Align:=gaClient;
    Context.Root.Add(Handlers.ShopLayer);

    BuildMenu(Handlers.MenuLayer, Handlers);
    BuildHud(Handlers.HudLayer, Handlers);
    BuildShop(Handlers.ShopLayer, Handlers);

    Handlers.StatusBar:=TGuiStatusBar.Create;
    Handlers.StatusBar.Bounds:=GuiRect(0, 0, 1280, 24);
    Handlers.StatusBar.Align:=gaBottom;
    Context.Root.Add(Handlers.StatusBar);

    ApplyGustavStyle(Context.Root, Theme);
    Handlers.SetScreen(gsMenu);

    AppRunning:=True;
    while AppRunning do
    begin
      while SDL_PollEvent(@SdlEvent) do
      begin
        if TSDL_EventType(SdlEvent.type_) = SDL_EVENT_QUIT then
          AppRunning:=False
        else
        if (TSDL_EventType(SdlEvent.type_) = SDL_EVENT_KEY_DOWN) AND (SdlEvent.key.key = 27) then
        begin
          if Handlers.ShopLayer.Visible then
            Handlers.SetScreen(gsHud)
          else
          if Handlers.HudLayer.Visible then
            Handlers.SetScreen(gsMenu)
          else
            AppRunning:=False;
        end else
        if (TSDL_EventType(SdlEvent.type_) = SDL_EVENT_WINDOW_RESIZED) OR
          (TSDL_EventType(SdlEvent.type_) = SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED) then
        begin
          Width:=SdlEvent.window.data1;
          Height:=SdlEvent.window.data2;
          Host.ProcessEvent(SdlEvent);
        end else
          Host.ProcessEvent(SdlEvent);
      end;

      SDL_SetRenderDrawColor(Renderer, Theme.WindowBackground.R, Theme.WindowBackground.G, Theme.WindowBackground.B, Theme.WindowBackground.A);
      SDL_RenderClear(Renderer);
      Host.Render;
      SDL_RenderPresent(Renderer);
      SDL_Delay(16);
      if FindCmdLineSwitch('smoke-test') then AppRunning:=False;
    end;
  finally
    Handlers.Free;
    Host.Free;
    FontRenderer.Free;
    Context.Free;

    if Assigned(Renderer) then
      SDL_DestroyRenderer(Renderer);

    if Assigned(Window) then
    begin
      SDL_StopTextInput(Window);
      SDL_DestroyWindow(Window);
    end;

    SDL_Quit;
  end;
end.
