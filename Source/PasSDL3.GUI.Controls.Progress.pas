unit PasSDL3.GUI.Controls.Progress;

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
  TGuiActivityIndicator = class(TGuiControl)
  private
    FAnimate: Boolean;
    FFrameInterval: Cardinal;
    procedure SetFrameInterval(AValue: Cardinal);
    function GetAnimationFrame: Integer;
  protected
    function AnimationTime: UInt64; virtual;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    function HitTest(const APoint: TGuiPoint): TGuiControl; override;
    property Animate: Boolean read FAnimate write FAnimate;
    property FrameInterval: Cardinal read FFrameInterval write SetFrameInterval;
    property AnimationFrame: Integer read GetAnimationFrame;
  end;

  TGuiProgressBar = class(TGuiControl)
  private
    FMarquee: Boolean;
    FMarqueeInterval: Cardinal;
    FMinValue: TGuiFloat;
    FMaxValue: TGuiFloat;
    FValue: TGuiFloat;
    FShowText: Boolean;
    FOrientation: TGuiOrientation;
    FReverse: Boolean;
    FSegmentCount: Integer;
    FSegmentGap: TGuiFloat;
    FShowTicks: Boolean;
    FTickCount: Integer;
    FShowThreshold: Boolean;
    FThresholdValue: TGuiFloat;
    FTickColor: TGuiColor;
    FThresholdColor: TGuiColor;
    procedure SetSegmentCount(AValue: Integer);
    procedure SetTickCount(AValue: Integer);
    procedure SetSegmentGap(AValue: TGuiFloat);
    procedure SetThresholdValue(AValue: TGuiFloat);
    function NormalizeValue(AValue: TGuiFloat): TGuiFloat;
    procedure SetMarqueeInterval(AValue: Cardinal);
    function GetMarqueePosition: TGuiFloat;
    procedure SetMinValue(AValue: TGuiFloat);
    procedure SetMaxValue(AValue: TGuiFloat);
    procedure SetValue(AValue: TGuiFloat);
    function ValueRatio: TGuiFloat;
  protected
    function AnimationTime: UInt64; virtual;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    property MinValue: TGuiFloat read FMinValue write SetMinValue;
    property Marquee: Boolean read FMarquee write FMarquee;
    property MarqueeInterval: Cardinal read FMarqueeInterval write SetMarqueeInterval;
    property MarqueePosition: TGuiFloat read GetMarqueePosition;
    property MaxValue: TGuiFloat read FMaxValue write SetMaxValue;
    property Value: TGuiFloat read FValue write SetValue;
    property ShowText: Boolean read FShowText write FShowText;
    property Orientation: TGuiOrientation read FOrientation write FOrientation;
    property Reverse: Boolean read FReverse write FReverse;
    property SegmentCount: Integer read FSegmentCount write SetSegmentCount;
    property SegmentGap: TGuiFloat read FSegmentGap write SetSegmentGap;
    property ShowTicks: Boolean read FShowTicks write FShowTicks;
    property TickCount: Integer read FTickCount write SetTickCount;
    property ShowThreshold: Boolean read FShowThreshold write FShowThreshold;
    property ThresholdValue: TGuiFloat read FThresholdValue write SetThresholdValue;
    property TickColor: TGuiColor read FTickColor write FTickColor;
    property ThresholdColor: TGuiColor read FThresholdColor write FThresholdColor;
  end;

implementation

constructor TGuiActivityIndicator.Create;
begin
  inherited Create;
  Bounds:=GuiRect(0, 0, 32, 32);
  FAnimate:=True;
  FFrameInterval:=80;
  CanFocus:=False;
  TabStop:=False;
  ShowFocus:=False;
end;

function TGuiActivityIndicator.AnimationTime: UInt64;
begin
  Result:=TThread.GetTickCount64;
end;

procedure TGuiActivityIndicator.SetFrameInterval(AValue: Cardinal);
begin
  if AValue = 0 then
    AValue:=1;
  FFrameInterval:=AValue;
end;

function TGuiActivityIndicator.GetAnimationFrame: Integer;
begin
  Result:=0;
  if FAnimate AND Enabled then
    Result:=Integer((AnimationTime DIV FFrameInterval) MOD 12);
end;

function TGuiActivityIndicator.HitTest(const APoint: TGuiPoint): TGuiControl;
begin
  Result:=nil;
end;

procedure TGuiActivityIndicator.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  Dot: TGuiRect;
  Radius: TGuiFloat;
  Diameter: TGuiFloat;
  Angle: TGuiFloat;
  CenterX: TGuiFloat;
  CenterY: TGuiFloat;
  I: Integer;
  Age: Integer;
  Frame: Integer;
  Color: TGuiColor;
begin
  if NOT FAnimate then
    Exit;
  Rect:=GuiInflateRect(AbsoluteBounds, Padding);
  Diameter:=Min(Rect.Width, Rect.Height);
  if Diameter <= 0 then
    Exit;
  CenterX:=Rect.Left + Rect.Width / 2;
  CenterY:=Rect.Top + Rect.Height / 2;
  Radius:=Diameter * 0.38;
  Diameter:=Max(1, Diameter * 0.16);
  Frame:=AnimationFrame;
  ACanvas.PushClipRect(AbsoluteBounds);
  try
    for I:=0 to 11 do
    begin
      Age:=(Frame - I + 12) MOD 12;
      Color:=Style.CheckedBorderColor;
      if NOT Enabled then
        Color:=Style.DisabledTextColor;
      Color.A:=Round(Color.A * (0.2 + 0.8 * (11 - Age) / 11));
      Angle:=(I * 30 - 90) * Pi / 180;
      Dot:=GuiRect(
        CenterX + Cos(Angle) * Radius - Diameter / 2,
        CenterY + Sin(Angle) * Radius - Diameter / 2,
        Diameter,
        Diameter
      );
      ACanvas.FillRoundedRect(Dot, Diameter / 2, Color);
    end;
  finally
    ACanvas.PopClipRect;
  end;
end;

constructor TGuiProgressBar.Create;
begin
  inherited Create;
  FMarqueeInterval:=1500;
  FMinValue:=0;
  FMaxValue:=100;
  FValue:=0;
  FShowText:=False;
  FOrientation:=goHorizontal;
  FReverse:=False;
  FSegmentCount:=0;
  FSegmentGap:=3;
  FShowTicks:=False;
  FTickCount:=0;
  FShowThreshold:=False;
  FThresholdValue:=0;
  FTickColor:=GuiColor(255, 255, 255, 70);
  FThresholdColor:=GuiColor(255, 230, 120, 220);
  Padding:=GuiBoxLTRB(4, 4, 4, 4);
  BackgroundColor:=GuiColor(31, 37, 46);
  BorderColor:=GuiColor(78, 92, 112);
  TextHorizontalAlign:=ghtaCenter;
  TextVerticalAlign:=gvtaCenter;
end;

procedure TGuiProgressBar.SetMinValue(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Invalid progress minimum');
  FMinValue:=AValue;
  if FMaxValue < FMinValue then
    FMaxValue:=FMinValue;

  SetValue(FValue);
end;

procedure TGuiProgressBar.SetMaxValue(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Invalid progress maximum');
  FMaxValue:=AValue;
  if FMinValue > FMaxValue then
    FMinValue:=FMaxValue;

  SetValue(FValue);
end;

procedure TGuiProgressBar.SetValue(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Invalid progress value');
  if AValue < FMinValue then
    AValue:=FMinValue;

  if AValue > FMaxValue then
    AValue:=FMaxValue;

  FValue:=AValue;
end;

procedure TGuiProgressBar.SetSegmentGap(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<0) then
    raise EArgumentException.Create('Progress segment gap must be finite AND nonnegative');
  FSegmentGap:=AValue;
end;

procedure TGuiProgressBar.SetSegmentCount(AValue: Integer);
begin
  if AValue<0 then raise EArgumentException.Create('Progress segment count must be nonnegative');
  FSegmentCount:=AValue;
end;

procedure TGuiProgressBar.SetTickCount(AValue: Integer);
begin
  if AValue<0 then raise EArgumentException.Create('Progress tick count must be nonnegative');
  FTickCount:=AValue;
end;

procedure TGuiProgressBar.SetThresholdValue(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then
    raise EArgumentException.Create('Progress threshold must be finite');
  FThresholdValue:=AValue;
end;

function TGuiProgressBar.NormalizeValue(AValue: TGuiFloat): TGuiFloat;
var
  LowValue: Double;
  HighValue: Double;
  Value: Double;
begin
  Result:=0;
  if FMaxValue <= FMinValue then
    Exit;
  if AValue <= FMinValue then
    Exit;
  if AValue >= FMaxValue then
  begin
    Result:=1;
    Exit;
  end;
  { Widen before subtraction: opposite finite Single endpoints can have a
    span larger than Single can represent. }
  LowValue:=FMinValue;
  HighValue:=FMaxValue;
  Value:=AValue;
  Result:=(Value - LowValue) / (HighValue - LowValue);
end;

function TGuiProgressBar.ValueRatio: TGuiFloat;
begin
  Result:=NormalizeValue(FValue);
end;

function TGuiProgressBar.AnimationTime: UInt64;
begin
  Result:=TThread.GetTickCount64;
end;

procedure TGuiProgressBar.SetMarqueeInterval(AValue: Cardinal);
begin
  if AValue = 0 then
    AValue:=1;
  FMarqueeInterval:=AValue;
end;

function TGuiProgressBar.GetMarqueePosition: TGuiFloat;
begin
  Result:=0;
  if FMarquee AND Enabled then
    Result:=0.5-0.5*Cos(2*Pi*(AnimationTime MOD FMarqueeInterval)/FMarqueeInterval);
end;

procedure TGuiProgressBar.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  TrackRect: TGuiRect;
  FillRect: TGuiRect;
  SegmentRect: TGuiRect;
  Ratio: TGuiFloat;
  FillDrawable: TGuiDrawable;
  States: TGuiControlVisualStates;
  TextValue: String;
  I: Integer;
  SegmentWidth: TGuiFloat;
  SegmentHeight: TGuiFloat;
  EffectiveGap: TGuiFloat;
  TrackLength: TGuiFloat;
  TickPos: TGuiFloat;
  ThresholdRatio: TGuiFloat;
  ThresholdPos: TGuiFloat;
begin
  FillDrawable:=Style.Thumb;
  if NOT Enabled then FillDrawable:=GuiColorDrawable(Style.DisabledTextColor);
  States:=[];
  if NOT Enabled then
    Include(States, gcvsDisabled);

  Rect:=AbsoluteBounds;
  if (Rect.Width<=0) OR (Rect.Height<=0) then Exit;
  ACanvas.PushClipRect(Rect);
  try
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), Rect, Style.CornerRadius);

  TrackRect:=GuiInflateRect(Rect, Padding);
  if TrackRect.Width < 0 then
    TrackRect.Width:=0;

  if TrackRect.Height < 0 then
    TrackRect.Height:=0;

  Ratio:=ValueRatio;
  if FOrientation=goHorizontal then TrackLength:=TrackRect.Width
  else TrackLength:=TrackRect.Height;

  if Style.Track.Kind <> gdkNone then
    ACanvas.DrawSurface(Style.Track, TrackRect, Style.CornerRadius);

  if FMarquee then
  begin
    FillRect:=TrackRect;
    Ratio:=MarqueePosition;
    if FReverse then
      Ratio:=1 - Ratio;
    if FOrientation=goHorizontal then
    begin
      FillRect.Width:=TrackRect.Width*0.3;
      FillRect.Left:=TrackRect.Left+(TrackRect.Width-FillRect.Width)*Ratio;
    end else
    begin
      FillRect.Height:=TrackRect.Height*0.3;
      FillRect.Top:=TrackRect.Top+(TrackRect.Height-FillRect.Height)*(1-Ratio);
    end;
    if (TrackRect.Width>0) AND (TrackRect.Height>0) then
    begin
      ACanvas.PushClipRect(TrackRect);
      try
        if Enabled then ACanvas.DrawSurface(FillDrawable,FillRect,Style.CornerRadius)
        else ACanvas.FillRoundedRect(FillRect,Style.CornerRadius,Style.DisabledTextColor);
      finally
        ACanvas.PopClipRect;
      end;
    end;
    DrawControlBorder(ACanvas,Rect,GuiResolveBorderColor(Style,States));
    Exit;
  end;

  { Sub-unit cells are indistinguishable at the default GUI scale. Render their
    continuous envelope instead of iterating an unbounded requested count. }
  if (FSegmentCount > 1) AND (FSegmentCount<=TrackLength) then
  begin
    ACanvas.PushClipRect(TrackRect);
    try
    if FOrientation = goHorizontal then
    begin
      EffectiveGap:=Min(Max(0,FSegmentGap),TrackRect.Width/FSegmentCount/2);
      SegmentWidth:=(TrackRect.Width - ((FSegmentCount - 1) * EffectiveGap)) / FSegmentCount;
      for I:=0 to FSegmentCount - 1 do
      begin
        if FReverse then
          SegmentRect:=GuiRect(
            TrackRect.Left + TrackRect.Width - SegmentWidth -
              (I * (SegmentWidth + EffectiveGap)),
            TrackRect.Top,
            SegmentWidth,
            TrackRect.Height
          )
        else
          SegmentRect:=GuiRect(TrackRect.Left + (I * (SegmentWidth + EffectiveGap)), TrackRect.Top, SegmentWidth, TrackRect.Height);

        if Style.Track.Kind <> gdkNone then
          ACanvas.DrawDrawable(Style.Track, SegmentRect)
        else
          ACanvas.FillRect(SegmentRect, GuiColor(0, 0, 0, 55));

        if ((I + 1) / FSegmentCount) <= Ratio then
          ACanvas.DrawDrawable(FillDrawable, SegmentRect)
        else
        if (I / FSegmentCount) < Ratio then
        begin
          FillRect:=SegmentRect;
          FillRect.Width:=SegmentRect.Width * (Ratio * FSegmentCount - I);
          if FillRect.Width < 0 then
            FillRect.Width:=0;
          if FillRect.Width > SegmentRect.Width then
            FillRect.Width:=SegmentRect.Width;
          if FReverse then
            FillRect.Left:=SegmentRect.Left + SegmentRect.Width - FillRect.Width;
          ACanvas.DrawSurface(FillDrawable, FillRect, Style.CornerRadius);
        end;
      end;
    end else
    begin
      EffectiveGap:=Min(Max(0,FSegmentGap),TrackRect.Height/FSegmentCount/2);
      SegmentHeight:=(TrackRect.Height - ((FSegmentCount - 1) * EffectiveGap)) / FSegmentCount;
      for I:=0 to FSegmentCount - 1 do
      begin
        if FReverse then
          SegmentRect:=GuiRect(
            TrackRect.Left,
            TrackRect.Top + (I * (SegmentHeight + EffectiveGap)),
            TrackRect.Width,
            SegmentHeight
          )
        else
          SegmentRect:=GuiRect(
            TrackRect.Left,
            TrackRect.Top + TrackRect.Height - SegmentHeight -
              (I * (SegmentHeight + EffectiveGap)),
            TrackRect.Width,
            SegmentHeight
          );

        if Style.Track.Kind <> gdkNone then
          ACanvas.DrawDrawable(Style.Track, SegmentRect)
        else
          ACanvas.FillRect(SegmentRect, GuiColor(0, 0, 0, 55));

        if ((I + 1) / FSegmentCount) <= Ratio then
          ACanvas.DrawDrawable(FillDrawable, SegmentRect)
        else
        if (I / FSegmentCount) < Ratio then
        begin
          FillRect:=SegmentRect;
          FillRect.Height:=SegmentRect.Height * (Ratio * FSegmentCount - I);
          if FillRect.Height < 0 then
            FillRect.Height:=0;
          if FillRect.Height > SegmentRect.Height then
            FillRect.Height:=SegmentRect.Height;
          if NOT FReverse then
            FillRect.Top:=SegmentRect.Top + SegmentRect.Height - FillRect.Height;
          ACanvas.DrawSurface(FillDrawable, FillRect, Style.CornerRadius);
        end;
      end;
    end;
    finally
      ACanvas.PopClipRect;
    end;
  end else
  begin
    FillRect:=TrackRect;
    if FOrientation = goHorizontal then
    begin
      FillRect.Width:=FillRect.Width * Ratio;
      if FReverse then
        FillRect.Left:=TrackRect.Left + TrackRect.Width - FillRect.Width;
    end else
    begin
      FillRect.Height:=FillRect.Height * Ratio;
      if NOT FReverse then
        FillRect.Top:=TrackRect.Top + TrackRect.Height - FillRect.Height;
    end;

    if (FillRect.Width > 0) AND (FillRect.Height > 0) then
      ACanvas.DrawSurface(FillDrawable, FillRect, Style.CornerRadius);
  end;

  if FShowTicks AND (FTickCount > 1) then
  begin
    if FTickCount>TrackLength+1 then
      ACanvas.FillRect(TrackRect,FTickColor)
    else
    for I:=0 to FTickCount - 1 do
    begin
      if FOrientation = goHorizontal then
      begin
        TickPos:=TrackRect.Left + (TrackRect.Width * I / (FTickCount - 1));
        ACanvas.FillRect(GuiRect(TickPos, TrackRect.Top, 1, TrackRect.Height), FTickColor);
      end else
      begin
        TickPos:=TrackRect.Top + (TrackRect.Height * I / (FTickCount - 1));
        ACanvas.FillRect(GuiRect(TrackRect.Left, TickPos, TrackRect.Width, 1), FTickColor);
      end;
    end;
  end;

  if FShowThreshold AND (FMaxValue > FMinValue) then
  begin
    ThresholdRatio:=NormalizeValue(FThresholdValue);

    if FReverse then
      ThresholdRatio:=1 - ThresholdRatio;

    if FOrientation = goHorizontal then
    begin
      ThresholdPos:=TrackRect.Left + (TrackRect.Width * ThresholdRatio);
      ACanvas.FillRect(GuiRect(ThresholdPos - 1, TrackRect.Top - 3, 2, TrackRect.Height + 6), FThresholdColor);
    end else
    begin
      ThresholdPos:=TrackRect.Top + (TrackRect.Height * (1 - ThresholdRatio));
      ACanvas.FillRect(GuiRect(TrackRect.Left - 3, ThresholdPos - 1, TrackRect.Width + 6, 2), FThresholdColor);
    end;
  end;

  DrawControlBorder(ACanvas, Rect, GuiResolveBorderColor(Style, States));

  if FShowText then
  begin
    TextValue:=FormatFloat('0', Ratio * 100) + '%';
    DrawControlText(ACanvas, TextValue, Rect, GuiResolveTextColor(Style, States), ghtaCenter, gvtaCenter);
  end;
  finally
    ACanvas.PopClipRect;
  end;
end;

end.
