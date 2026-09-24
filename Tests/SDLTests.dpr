program SDLTests;
{$IFDEF FPC}
  {$MODE DELPHI}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}
uses
  SysUtils, Math, SDL3, SDL3_ttf, PasSDL3.GUI.Types, PasSDL3.GUI.Context,
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Renderer.SDL3,
  PasSDL3.GUI.Grapheme,
  PasSDL3.GUI.Input.SDL3,
  PasSDL3.GUI.Text,
  PasSDL3.GUI.Host.SDL3, PasSDL3.GUI.Fonts, PasSDL3.GUI.Fonts.SDLTTF;

type
  TStyleDrawableSlot = (
    sdsBackground,
    sdsHoverBackground,
    sdsPressedBackground,
    sdsCheckedBackground,
    sdsSelection,
    sdsTrack,
    sdsThumb
  );
  TStyleColorSlot = (
    scsBackgroundColor,
    scsCheckedBackgroundColor,
    scsDisabledBackgroundColor,
    scsBorderColor,
    scsCheckedBorderColor,
    scsTextColor,
    scsDisabledTextColor
  );
  TStyleFloatSlot = (
    sfsBorderWidth,
    sfsCornerRadius
  );

  TComboNativeProbe = class
  private
    FAccepts: Integer;
    FSelections: Integer;
  public
    property Accepts: Integer read FAccepts write FAccepts;
    property Selections: Integer read FSelections write FSelections;
    procedure Selected(Sender: TGuiControl);
    procedure Accepted(Sender: TGuiControl);
  end;
  TSpinNativeProbe = class
  private
    FCalls: Integer;
    FValue: Integer;
  public
    property Calls: Integer read FCalls write FCalls;
    property Value: Integer read FValue write FValue;
    procedure Modified(Sender: TGuiControl);
  end;
  TTouchProbe = class
  private
    FClicks: Integer;
  public
    property Clicks: Integer read FClicks;
    procedure Clicked(Sender: TGuiControl);
  end;
  TMetricPixelCanvas = class(TGuiSDL3Canvas)
  public
    function MeasureText(const AText: String): TGuiSize;
    override;
  end;
  TWheelPixelCanvas = class(TGuiSDL3Canvas)
  public
    procedure DrawText(const AText: String; const ARect: TGuiRect; const AColor: TGuiColor;
      AHorizontalAlign: TGuiHorizontalTextAlign; AVerticalAlign: TGuiVerticalTextAlign);
      override;
  end;
  TPixelDelay = class(TGuiDelayButton)
  private
    FTicks: UInt64;
  public
    property Ticks: UInt64 read FTicks write FTicks;
  protected
    function AnimationTime: UInt64;
    override;
  end;
  TPixelProgress = class(TGuiProgressBar)
  private
    FTicks: UInt64;
  public
    property Ticks: UInt64 read FTicks write FTicks;
  protected
    function AnimationTime: UInt64;
    override;
  end;
  TPixelActivityIndicator = class(TGuiActivityIndicator)
  private
    FTicks: UInt64;
  public
    property Ticks: UInt64 read FTicks write FTicks;
  protected
    function AnimationTime: UInt64;
    override;
  end;

procedure TComboNativeProbe.Selected(Sender: TGuiControl);
begin
  Inc(FSelections);
end;

procedure TComboNativeProbe.Accepted(Sender: TGuiControl);
begin
  Inc(FAccepts);
end;

procedure TSpinNativeProbe.Modified(Sender: TGuiControl);
begin
  Inc(FCalls);
  Value:=TGuiSpinEdit(Sender).Value;
end;

procedure Check(ACondition: Boolean; const AMessage: String); forward;

procedure TTouchProbe.Clicked(Sender: TGuiControl);
begin
  Inc(FClicks);
end;

procedure TestTouchHost(AHost: TGuiSDL3Host; AWindow: PSDL_Window;
  AButton: TGuiButton);
var
  Event: TSDL_Event;
  Probe: TTouchProbe;
  procedure Finger(AType: TSDL_EventType; AFinger: TSDL_FingerID);
  begin
    Event:=Default(TSDL_Event);
    Event.type_:=AType;
    Event.tfinger.windowID:=SDL_GetWindowID(AWindow);
    Event.tfinger.touchID:=1;
    Event.tfinger.fingerID:=AFinger;
    Event.tfinger.x:=0.3;
    Event.tfinger.y:=0.2;
    AHost.ProcessEvent(Event);
  end;
  procedure Mouse(AType: TSDL_EventType; AWhich: TSDL_MouseID);
  begin
    Event:=Default(TSDL_Event);
    Event.type_:=AType;
    Event.button.windowID:=SDL_GetWindowID(AWindow);
    Event.button.which:=AWhich;
    Event.button.button:=SDL_BUTTON_LEFT;
    Event.button.x:=120;
    Event.button.y:=40;
    AHost.ProcessEvent(Event);
  end;
begin
  Probe:=TTouchProbe.Create;
  try
    AButton.OnClick:=Probe.Clicked;
    Finger(SDL_EVENT_FINGER_DOWN, 1);
    Finger(SDL_EVENT_FINGER_UP, 1);
    Check(Probe.Clicks=1,'Raw finger tap clicks once at scaled coordinates');
    Mouse(SDL_EVENT_MOUSE_BUTTON_DOWN,High(TSDL_MouseID));
    Mouse(SDL_EVENT_MOUSE_BUTTON_UP,High(TSDL_MouseID));
    Check(Probe.Clicks=1,'Synthesized touch mouse events are suppressed');
    Finger(SDL_EVENT_FINGER_DOWN, 1);
    Finger(SDL_EVENT_FINGER_DOWN, 2);
    Finger(SDL_EVENT_FINGER_UP, 2);
    Finger(SDL_EVENT_FINGER_UP, 1);
    Check(Probe.Clicks=2,'Secondary finger does not duplicate tap');
    Finger(SDL_EVENT_FINGER_DOWN, 1);
    Finger(SDL_EVENT_FINGER_CANCELED, 1);
    Finger(SDL_EVENT_FINGER_UP, 1);
    Check(Probe.Clicks=2,'Cancelled finger does not click');
    Finger(SDL_EVENT_FINGER_DOWN, 1);
    AHost.CancelInput;
    Finger(SDL_EVENT_FINGER_UP, 1);
    Check(Probe.Clicks=2,'Closing overlay cancels touch capture');
    Finger(SDL_EVENT_FINGER_DOWN, 1);
    Finger(SDL_EVENT_FINGER_UP, 1);
    Check(Probe.Clicks=3,'Touch capture recovers after cancellation');
    Mouse(SDL_EVENT_MOUSE_BUTTON_DOWN,0);
    Mouse(SDL_EVENT_MOUSE_BUTTON_UP,0);
    Check(Probe.Clicks=4,'Mouse-only touchscreen still clicks');
  finally
    AButton.OnClick:=nil;
    Probe.Free;
  end;
end;

function TPixelActivityIndicator.AnimationTime: UInt64;
begin
  Result:=Ticks;
end;

function TMetricPixelCanvas.MeasureText(const AText: String): TGuiSize;
begin
  Result:=GuiSize(Length(AText)*8,16);
end;

procedure TWheelPixelCanvas.DrawText(const AText: String; const ARect: TGuiRect; const AColor: TGuiColor;
  AHorizontalAlign: TGuiHorizontalTextAlign; AVerticalAlign: TGuiVerticalTextAlign);
begin
  { A deterministic glyph stand-in tests wheel layout/alpha independently of fonts. }
  FillRect(GuiRect(ARect.Left+ARect.Width/2-2,ARect.Top+ARect.Height/2-2,4,4),AColor);
end;

function TPixelDelay.AnimationTime: UInt64;
begin
  Result:=Ticks;
end;

function TPixelProgress.AnimationTime: UInt64;
begin
  Result:=Ticks;
end;

procedure Check(ACondition: Boolean; const AMessage: String);
begin
  if NOT ACondition then raise Exception.Create(AMessage + ': ' + String(SDL_GetError));
  Writeln('PASS: ', AMessage);
end;

procedure SetStyleDrawable(AControl: TGuiControl; ASlot: TStyleDrawableSlot; const AValue: TGuiDrawable);
var
  CurrentStyle: TGuiStyle;
begin
  CurrentStyle:=AControl.Style;
  case ASlot of
    sdsBackground: CurrentStyle.Background:=AValue;
    sdsHoverBackground: CurrentStyle.HoverBackground:=AValue;
    sdsPressedBackground: CurrentStyle.PressedBackground:=AValue;
    sdsCheckedBackground: CurrentStyle.CheckedBackground:=AValue;
    sdsSelection: CurrentStyle.Selection:=AValue;
    sdsTrack: CurrentStyle.Track:=AValue;
    sdsThumb: CurrentStyle.Thumb:=AValue;
  end;
  AControl.Style:=CurrentStyle;
end;

procedure SetStyleColor(AControl: TGuiControl; ASlot: TStyleColorSlot; const AValue: TGuiColor);
var
  CurrentStyle: TGuiStyle;
begin
  CurrentStyle:=AControl.Style;
  case ASlot of
    scsBackgroundColor: CurrentStyle.BackgroundColor:=AValue;
    scsCheckedBackgroundColor: CurrentStyle.CheckedBackgroundColor:=AValue;
    scsDisabledBackgroundColor: CurrentStyle.DisabledBackgroundColor:=AValue;
    scsBorderColor: CurrentStyle.BorderColor:=AValue;
    scsCheckedBorderColor: CurrentStyle.CheckedBorderColor:=AValue;
    scsTextColor: CurrentStyle.TextColor:=AValue;
    scsDisabledTextColor: CurrentStyle.DisabledTextColor:=AValue;
  end;
  AControl.Style:=CurrentStyle;
end;

procedure SetStyleFloat(AControl: TGuiControl; ASlot: TStyleFloatSlot; AValue: TGuiFloat);
var
  CurrentStyle: TGuiStyle;
begin
  CurrentStyle:=AControl.Style;
  case ASlot of
    sfsBorderWidth: CurrentStyle.BorderWidth:=AValue;
    sfsCornerRadius: CurrentStyle.CornerRadius:=AValue;
  end;
  AControl.Style:=CurrentStyle;
end;

procedure SetStyleTextOffset(AControl: TGuiControl; const AValue: TGuiPoint);
var
  CurrentStyle: TGuiStyle;
begin
  CurrentStyle:=AControl.Style;
  CurrentStyle.TextOffset:=AValue;
  AControl.Style:=CurrentStyle;
end;

procedure SetBoundsWidth(AControl: TGuiControl; AValue: TGuiFloat);
var
  CurrentBounds: TGuiRect;
begin
  CurrentBounds:=AControl.Bounds;
  CurrentBounds.Width:=AValue;
  AControl.Bounds:=CurrentBounds;
end;

procedure UpdateStyleDrawables(AControl: TGuiControl);
var
  CurrentStyle: TGuiStyle;
begin
  CurrentStyle:=AControl.Style;
  GuiUpdateStyleDrawables(CurrentStyle);
  AControl.Style:=CurrentStyle;
end;

procedure TestStylePixels(ARenderer: PSDL_Renderer);
var
  Canvas: TGuiSDL3Canvas;
  List: TGuiListBox;
  Table: TGuiListView;
  ListStyle: TGuiStyle;
  I: Integer;
  Surface: PSDL_Surface;
  C: TGuiColor;
  function RedAt(X, Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(Surface, X, Y, @C.R, @C.G, @C.B, @C.A) then
      raise Exception.Create('Cannot read style test pixel');
    Result:=C.R;
  end;
begin
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    SDL_SetRenderDrawColor(ARenderer, 0, 0, 0, 255);
    SDL_RenderClear(ARenderer);
    Canvas.FillRoundedRect(GuiRect(10, 10, 40, 40), 10, GuiColor(255, 255, 255));
    Canvas.DrawRoundedBorder(GuiRect(60, 10, 40, 40), 10, 2, GuiColor(255, 255, 255));
    Canvas.FillRoundedRect(GuiRect(110, 10, 20, 20), 0, GuiColor(255, 255, 255));
    Canvas.FillRoundedRect(GuiRect(140, 10, 20, 20), 999, GuiColor(255, 255, 255));
    Canvas.PushClipRect(GuiRect(170, 10, 10, 20));
    try
      Canvas.FillRoundedRect(GuiRect(170, 10, 20, 20), 4, GuiColor(255, 255, 255));
    finally
      Canvas.PopClipRect;
    end;
    Canvas.FillRoundedRect(GuiRect(200, 10, 20, 20), 5, GuiColor(255, 255, 255, 128));
    Canvas.FillRoundedRect(GuiRect(230, 10, 0, 20), 5, GuiColor(255, 255, 255));
    Canvas.DrawRoundedBorder(GuiRect(260, 10, 20, 20), 5, 0, GuiColor(255, 255, 255));
    Canvas.DrawLine(GuiPoint(300, 10), GuiPoint(320, 30), 4, GuiColor(255, 255, 255));
    Canvas.DrawLine(GuiPoint(340, 30), GuiPoint(360, 10), 4, GuiColor(255, 255, 255));
    Canvas.DrawSurface(GuiGradientDrawable(GuiColor(240, 0, 0), GuiColor(40, 0, 0)), GuiRect(10, 70, 40, 30), 8);
    Canvas.FillRoundedGradient(GuiRect(60, 70, 40, 30), 8, GuiColor(255, 0, 0, 128), GuiColor(255, 0, 0, 128));
    List:=TGuiListBox.Create;
    try
      List.Bounds:=GuiRect(10, 110, 180, 80);
      List.Padding:=GuiBox(4);
      List.ItemHeight:=20;
      ListStyle:=List.Style;
      ListStyle.Background:=GuiColorDrawable(GuiColor(0, 0, 0));
      ListStyle.Selection:=GuiColorDrawable(GuiColor(200, 0, 0));
      ListStyle.ScrollTrackColor:=GuiColor(0, 0, 0);
      ListStyle.ScrollBarSize:=12;
      List.Style:=ListStyle;
      List.BackgroundColor:=GuiColor(0, 0, 0);
      for I:=0 to 9 do List.AddItem('Row');
      List.SelectedIndex:=0;
      List.Paint(Canvas);
    finally
      List.Free;
    end;
    Table:=TGuiListView.Create;
    try
      Table.Bounds:=GuiRect(220, 110, 160, 80);
      SetStyleDrawable(Table, sdsBackground,GuiColorDrawable(GuiColor(0, 0, 0)));
      SetStyleDrawable(Table, sdsHoverBackground,GuiColorDrawable(GuiColor(200, 0, 0)));
      SetStyleColor(Table, scsBorderColor,GuiColor(255, 255, 255));
      SetStyleFloat(Table, sfsBorderWidth,1);
      SetStyleFloat(Table, sfsCornerRadius,10);
      Table.AddColumn('First', 60);
      Table.AddColumn('Last', 40);
      Table.Paint(Canvas);
    finally
      Table.Free;
    end;
    Surface:=SDL_RenderReadPixels(ARenderer, nil);
    Check(Assigned(Surface), 'Read style rendering pixels');
    try
      Check((RedAt(10, 10) = 0) AND (RedAt(30, 30) = 255), 'Rounded fill preserves corners and fills center');
      Check((RedAt(16, 10) > 0) AND (RedAt(16, 10) < 255), 'Rounded edge has fractional coverage');
      Check((RedAt(80, 10) = 255) AND (RedAt(80, 30) = 0), 'Rounded border leaves interior untouched');
      Check(RedAt(110, 10) = 255, 'Zero radius retains square rendering');
      Check((RedAt(140, 10) = 0) AND (RedAt(150, 20) = 255), 'Oversized radius clamps to circle');
      Check((RedAt(175, 20) = 255) AND (RedAt(185, 20) = 0), 'Rounded surfaces respect clipping');
      Check(Abs(Integer(RedAt(210, 20)) - 128) <= 1, 'Rounded fill does not overdraw translucent center');
      Check((RedAt(230, 20) = 0) AND (RedAt(270, 10) = 0), 'Empty fill and zero-width border draw nothing');
      Check((RedAt(310, 20) = 255) AND (RedAt(350, 20) = 255) AND
        (RedAt(310, 26) = 0), 'Diagonal strokes fill both directions with bounded thickness');
      Check((RedAt(30, 70) = 240) AND (RedAt(30, 99) = 40) AND (RedAt(10, 70) = 0), 'Gradient has exact endpoints and rounded corners');
      Check((RedAt(30, 84) > 100) AND (RedAt(30, 84) < 200), 'Gradient interpolates interior rows');
      Check(Abs(Integer(RedAt(80, 84)) - 128) <= 1, 'Equal gradient endpoints preserve translucent fill');
      Check(RedAt(170, 124) = 200, 'Row selection extends beyond text viewport');
      Check((RedAt(179, 124) > 50) AND (RedAt(179, 124) < 180),
        'Selection remains visible beneath dim translucent scrollbar lane');
      Check(RedAt(179, 154) = 0, 'Unselected scrollbar lane retains background');
      Check((RedAt(221, 111) = 0) AND (RedAt(378, 111) = 0),
        'List header preserves both rounded outer corners');
      Check((RedAt(378, 130) = 200) AND (RedAt(379, 130) = 255),
        'Last header cell has one outer border and no inset duplicate');
      Check(RedAt(283, 130) = 255, 'Internal header divider remains visible');
    finally
      SDL_DestroySurface(Surface);
    end;
  finally
    Canvas.Free;
  end;
end;

procedure TestKnobPixels(ARenderer: PSDL_Renderer);
var K: TGuiKnob;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
C: TGuiColor;
  SavedX,SavedY: Single;
  I: Integer;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read knob pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  K:=TGuiKnob.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    K.Value:=50;
    SetStyleDrawable(K, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleColor(K, scsBorderColor,GuiColor(0,0,0));
    SetStyleColor(K, scsCheckedBorderColor,GuiColor(255,255,255));
    SetStyleFloat(K, sfsBorderWidth,0);
    for I:=0 to 1 do
    begin
      if I=1 then K.SetAngles(0,180);
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      K.Paint(Canvas);
      S:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(S),'Read knob rendering');
      try
        if I=0 then Check((RedAt(50,28)=255) AND (RedAt(50,72)=0),'Default knob midpoint points upward')
        else Check((RedAt(50,72)=255) AND (RedAt(50,28)=0),'Custom knob arc rotates the rendered pointer');
        Check((RedAt(0,0)=0) AND (RedAt(50,50)=0),'Knob retains clear margins and bounded radial pointer');
      finally
        SDL_DestroySurface(S);
      end;
    end;
  finally
    K.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestRoundButtonPixels(ARenderer: PSDL_Renderer);
var B: TGuiRoundButton;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
C: TGuiColor;
  SavedX,SavedY: Single;
  I: Integer;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read round button pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  B:=TGuiRoundButton.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    B.Caption:='';
    SetStyleFloat(B, sfsBorderWidth,0);
    SetStyleDrawable(B, sdsBackground,GuiColorDrawable(GuiColor(255,255,255)));
    for I:=0 to 2 do
    begin
      B.Bounds:=GuiRect(10,10,40,40);
      B.Radius:=-1;
      if I=1 then SetBoundsWidth(B, 80);
      if I=2 then B.Radius:=0;
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      B.Paint(Canvas);
      S:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(S),'Read round button surface');
      try
        Check(RedAt(30,30)=255,'Round button fills its center');
        if I=2 then Check(RedAt(10,10)=255,'Explicit zero radius paints square corner')
        else Check((RedAt(10,10)=0) AND (RedAt(10,30)>200),'Automatic circle/pill rounds outer corners');
      finally
        SDL_DestroySurface(S);
      end;
    end;
    B.Radius:=-1;
    B.Icon:=GuiColorDrawable(GuiColor(0,0,0));
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    B.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read round icon alignment');
    try
      Check((RedAt(21,30)=255) AND (RedAt(22,30)=0) AND (RedAt(37,30)=0) AND (RedAt(38,30)=255),
        'Round icon-only button centers its icon exactly');
    finally
      SDL_DestroySurface(S);
    end;
  finally
    B.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestSliderBoundsPixels(ARenderer: PSDL_Renderer);
var S: TGuiSlider;
Canvas: TGuiSDL3Canvas;
Surface: PSDL_Surface;
  C: TGuiColor;
  SavedX,SavedY: Single;
  X,Y: Integer;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  S:=TGuiSlider.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    S.Bounds:=GuiRect(20,20,116,40);
    S.Value:=50;
    S.Enabled:=False;
    SetStyleDrawable(S, sdsThumb,GuiColorDrawable(GuiColor(255,255,255)));
    SetStyleColor(S, scsDisabledTextColor,GuiColor(100,100,100));
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    S.Paint(Canvas);
    Surface:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(Surface),'Read disabled slider');
    try
      Check(SDL_ReadSurfacePixel(Surface,45,40,@C.R,@C.G,@C.B,@C.A),'Read disabled slider fill');
      Check(C.R=100,'Disabled slider fill uses the muted theme color');
    finally
      SDL_DestroySurface(Surface);
    end;
    S.Enabled:=True;
    S.Padding:=GuiBox(0);
    S.Bounds:=GuiRect(20,20,8,3);
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    S.Paint(Canvas);
    Surface:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(Surface),'Read tiny slider');
    try
      for Y:=8 to 36 do for X:=8 to 40 do
        if (X<20) OR (X>=28) OR (Y<20) OR (Y>=23) then
        begin
          if NOT SDL_ReadSurfacePixel(Surface,X,Y,@C.R,@C.G,@C.B,@C.A) then
            raise Exception.Create('Cannot read slider bounds pixel');
          if (C.R<>0) OR (C.G<>0) OR (C.B<>0) then
            raise Exception.Create('Slider painting escaped tiny control bounds');
        end;
      Check(True,'Tiny slider painting remains inside its bounds');
    finally
      SDL_DestroySurface(Surface);
    end;
  finally
    S.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestComboBoundsPixels(ARenderer: PSDL_Renderer);
var S: TGuiComboBox;
Canvas: TGuiSDL3Canvas;
Surface: PSDL_Surface;
  C: TGuiColor;
  SavedX,SavedY: Single;
  X,Y,Mode: Integer;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  S:=TGuiComboBox.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    S.Bounds:=GuiRect(40,40,8,3);
    S.AddItem('Long label');
    for Mode:=0 to 1 do
    begin
      S.Editable:=Mode=1;
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      S.Paint(Canvas);
      Surface:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(Surface),'Read tiny combo');
      try
        for Y:=25 to 55 do for X:=10 to 65 do
          if (X<40) OR (X>=48) OR (Y<40) OR (Y>=43) then
          begin
            if NOT SDL_ReadSurfacePixel(Surface,X,Y,@C.R,@C.G,@C.B,@C.A) then
              raise Exception.Create('Cannot read combo bounds pixel');
            if (C.R<>0) OR (C.G<>0) OR (C.B<>0) then
              raise Exception.Create('Combo painting escaped tiny control bounds');
          end;
        Check(True,'Editable/read-only combo painting stays inside tiny bounds');
      finally
        SDL_DestroySurface(Surface);
      end;
    end;
  finally
    S.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestSpinBoundsPixels(ARenderer: PSDL_Renderer);
var S: TGuiSpinEdit;
Canvas: TGuiSDL3Canvas;
Surface: PSDL_Surface;
  C: TGuiColor;
  SavedX,SavedY: Single;
  X,Y: Integer;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  S:=TGuiSpinEdit.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    S.Bounds:=GuiRect(40,40,8,3);
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    S.Paint(Canvas);
    Surface:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(Surface),'Read tiny spin edit');
    try
      for Y:=25 to 55 do for X:=10 to 65 do
        if (X<40) OR (X>=48) OR (Y<40) OR (Y>=43) then
        begin
          if NOT SDL_ReadSurfacePixel(Surface,X,Y,@C.R,@C.G,@C.B,@C.A) then
            raise Exception.Create('Cannot read spin bounds pixel');
          if (C.R<>0) OR (C.G<>0) OR (C.B<>0) then
            raise Exception.Create('Spin edit painting escaped tiny control bounds');
        end;
      Check(True,'Tiny spin edit painting stays inside bounds');
    finally
      SDL_DestroySurface(Surface);
    end;
  finally
    S.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestRangeBoundsPixels(ARenderer: PSDL_Renderer);
var S: TGuiRangeSlider;
Canvas: TGuiSDL3Canvas;
Surface: PSDL_Surface;
  C: TGuiColor;
  SavedX,SavedY: Single;
  X,Y,I: Integer;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  S:=TGuiRangeSlider.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    S.Padding:=GuiBox(0);
    S.Bounds:=GuiRect(20,20,8,3);
    for I:=0 to 1 do
    begin
      S.Orientation:=TGuiOrientation(I);
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      S.Paint(Canvas);
      Surface:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(Surface),'Read tiny range slider');
      try
        for Y:=8 to 36 do for X:=8 to 40 do
          if (X<20) OR (X>=28) OR (Y<20) OR (Y>=23) then
          begin
            if NOT SDL_ReadSurfacePixel(Surface,X,Y,@C.R,@C.G,@C.B,@C.A) then
              raise Exception.Create('Cannot read range slider bounds pixel');
            if (C.R<>0) OR (C.G<>0) OR (C.B<>0) then
              raise Exception.Create('Range slider painting escaped tiny control bounds');
          end;
        Check(True,'Tiny range slider painting stays inside both-axis bounds');
      finally
        SDL_DestroySurface(Surface);
      end;
    end;
  finally
    S.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestSliderPreviewPixels(ARenderer: PSDL_Renderer);
var S: TGuiSlider;
Canvas: TGuiSDL3Canvas;
Surface: PSDL_Surface;
C: TGuiColor;
  SavedX,SavedY: Single;
  E: TGuiEvent;
  I: Integer;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(Surface,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read slider preview pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  S:=TGuiSlider.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    SetStyleColor(S, scsBorderColor,GuiColor(0,0,0));
    SetStyleFloat(S, sfsBorderWidth,0);
    SetStyleDrawable(S, sdsThumb,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(S, sdsBackground,GuiColorDrawable(GuiColor(255,255,255)));
    SetStyleDrawable(S, sdsPressedBackground,S.Style.Background);
    S.Live:=False;
    for I:=0 to 1 do
    begin
      S.Orientation:=TGuiOrientation(I);
      S.Value:=50;
      E:=Default(TGuiEvent);
      E.Kind:=gekMouseDown;
      E.Button:=gmbLeft;
      if S.Orientation=goHorizontal then
      begin
        S.Bounds:=GuiRect(10,10,116,40);
        E.Position:=GuiPoint(38,30);
      end
      else
      begin
        S.Bounds:=GuiRect(10,10,40,116);
        E.Position:=GuiPoint(30,100.4);
      end;
      S.HandleEvent(E);
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      S.Paint(Canvas);
      Surface:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(Surface),'Read deferred slider thumb');
      try
        if S.Orientation=goHorizontal then
          Check((RedAt(38,30)=255) AND (RedAt(68,30)=0),'Horizontal thumb paints preview rather than committed value')
        else Check((RedAt(30,100)=255) AND (RedAt(30,68)=0),'Vertical thumb paints preview rather than committed value');
        Check((S.Value=50) AND (Abs(S.PreviewValue-20)<0.01),'Rendered slider preview leaves committed value unchanged');
      finally
        SDL_DestroySurface(Surface);
      end;
      E.Kind:=gekMouseUp;
      E.Handled:=False;
      S.HandleEvent(E);
      Check(Abs(S.Value-20)<0.01,'Release commits the rendered preview');
    end;
  finally
    S.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestSpinNativeModification(AHost: TGuiSDL3Host; AWindow: PSDL_Window; ASpin: TGuiSpinEdit);
var P: TSpinNativeProbe;
E: TSDL_Event;
  procedure Input(AKind: UInt32; AText: PAnsiChar);
  begin
    E:=Default(TSDL_Event);
    E.type_:=AKind;
    if AKind=SDL_EVENT_TEXT_INPUT then
    begin
      E.text.windowID:=SDL_GetWindowID(AWindow);
      E.text.text:=AText;
    end
    else
    begin
      E.edit.windowID:=SDL_GetWindowID(AWindow);
      E.edit.text:=AText;
    end;
    AHost.ProcessEvent(E);
  end;
  procedure Key(Code: UInt32);
  begin
    E:=Default(TSDL_Event);
    E.type_:=SDL_EVENT_KEY_DOWN;
    E.key.windowID:=SDL_GetWindowID(AWindow);
    E.key.key:=Code;
    AHost.ProcessEvent(E);
  end;
begin
  P:=TSpinNativeProbe.Create;
  try
    ASpin.OnValueModified:=P.Modified;
    ASpin.Value:=12;
    ASpin.SelectAll;
    Input(SDL_EVENT_TEXT_INPUT,'25');
    Check(P.Calls=0,'SDL deferred spin input does not emit premature user notification');
    Key(13);
    Check((P.Calls=1) AND (P.Value=25),'SDL spin Enter emits committed user notification');
    Key(13);
    Check(P.Calls=1,'SDL unchanged spin Enter emits no duplicate notification');
    ASpin.Live:=True;
    ASpin.Text:='30';
    Check(P.Calls=1,'Programmatic live spin text stays distinct from SDL user input');
    ASpin.SelectAll;
    Input(SDL_EVENT_TEXT_EDITING,'42');
    Check(P.Calls=1,'SDL composition preview emits no spin user notification');
    Input(SDL_EVENT_TEXT_INPUT,'42');
    Check((P.Calls=2) AND (P.Value=42),'SDL composition commit emits live spin user notification');
    Key($40000052);
    Check((P.Calls=3) AND (P.Value=43),'SDL spin arrow key emits user notification');
    ASpin.Live:=False;
    ASpin.SelectAll;
    Input(SDL_EVENT_TEXT_INPUT,'44');
    AHost.Context.ClearFocus;
    Check((P.Calls=4) AND (P.Value=44),'SDL edited buffer emits one user notification on focus loss');
    AHost.Context.SetFocus(ASpin);
  finally
    ASpin.OnValueModified:=nil;
    P.Free;
  end;
end;

procedure TestComboNativeKeyboard(AHost: TGuiSDL3Host; AWindow: PSDL_Window);
var C: TGuiComboBox;
P: TComboNativeProbe;
E: TSDL_Event;
Previous: TGuiControl;
  procedure Key(Code: UInt32; Repeated: Boolean = False);
  begin
    E:=Default(TSDL_Event);
    E.type_:=SDL_EVENT_KEY_DOWN;
    E.key.windowID:=SDL_GetWindowID(AWindow);
    E.key.key:=Code;
    E.key.repeat_:=Repeated;
    AHost.ProcessEvent(E);
  end;
begin
  C:=TGuiComboBox.Create;
  P:=TComboNativeProbe.Create;
  Previous:=AHost.Context.FocusedControl;
  try
    C.Bounds:=GuiRect(0,100,180,30);
    C.AddItem('A');
    C.AddItem('B');
    C.AddItem('C');
    C.OnSelect:=P.Selected;
    C.OnAccept:=P.Accepted;
    AHost.Context.Root.Add(C);
    AHost.Context.SetFocus(C);
    Key(13);
    Key(13,True);
    Key($40000051);
    Check(C.DroppedDown AND (C.HighlightedIndex=1) AND (C.SelectedIndex=0) AND (P.Accepts=0),
      'SDL combo keyboard previews without premature acceptance or repeat toggle');
    Key(13);
    Check((C.SelectedIndex=1) AND (P.Accepts=1) AND (P.Selections=1),'SDL Enter accepts combo preview once');
    Key($4000003D);
    Key($40000051);
    Key(27);
    Check((C.SelectedIndex=1) AND (P.Accepts=1) AND NOT C.DroppedDown,'SDL Escape cancels combo preview');
    Key(13);
    Key(13);
    Check((P.Accepts=2) AND (P.Selections=1),'SDL same-item combo acceptance is distinct from selection change');
    AHost.Render;
    Check(SDL_TextInputActive(AWindow),'Noneditable combo activates native text input for type-ahead');
    C.Items[1]:='Beta';
    C.Items[2]:='Bravo';
    Key(98);
    E:=Default(TSDL_Event);
    E.type_:=SDL_EVENT_TEXT_INPUT;
    E.text.windowID:=SDL_GetWindowID(AWindow);
    E.text.text:='b';
    AHost.ProcessEvent(E);
    Check(C.SelectedIndex=2,'SDL text input searches next noneditable combo match');
    Key(101);
    E:=Default(TSDL_Event);
    E.type_:=SDL_EVENT_TEXT_INPUT;
    E.text.windowID:=SDL_GetWindowID(AWindow);
    E.text.text:='e';
    AHost.ProcessEvent(E);
    Check((C.SelectedIndex=1) AND (C.SearchPrefix='be') AND NOT C.Editing,'SDL keydown plus text input accumulates noneditable search prefix');
    C.Items[1]:='B';
    C.Items[2]:='C';
    C.ClearSearch;
    E:=Default(TSDL_Event);
    E.type_:=SDL_EVENT_TEXT_EDITING;
    E.edit.windowID:=SDL_GetWindowID(AWindow);
    E.edit.text:='C';
    AHost.ProcessEvent(E);
    Key(13);
    Check((C.SelectedIndex=1) AND (P.Accepts=2),'SDL noneditable composition Enter does not accept or open popup');
    E:=Default(TSDL_Event);
    E.type_:=SDL_EVENT_TEXT_INPUT;
    E.text.windowID:=SDL_GetWindowID(AWindow);
    E.text.text:='C';
    AHost.ProcessEvent(E);
    Check(C.SelectedIndex=2,'SDL noneditable composition commit searches choice');
    C.SelectedIndex:=1;
    C.Enabled:=False;
    AHost.Render;
    Check(NOT SDL_TextInputActive(AWindow),'Disabled combo stops native search input');
    C.Enabled:=True;
    AHost.Render;
    Check(SDL_TextInputActive(AWindow),'Reenabled combo resumes native search input');
    C.Editable:=True;
    AHost.Render;
    Check(SDL_TextInputActive(AWindow),'Editable combo activates native text input');
    C.SelectAll;
    E:=Default(TSDL_Event);
    E.type_:=SDL_EVENT_TEXT_INPUT;
    E.text.windowID:=SDL_GetWindowID(AWindow);
    E.text.text:='Custom';
    AHost.ProcessEvent(E);
    Check((C.Text='Custom') AND (C.SelectedIndex=1) AND (P.Accepts=2),'SDL combo typing stays a draft');
    Key(13);
    Check((C.Text='Custom') AND (C.SelectedIndex=-1) AND (P.Accepts=3) AND (C.Items.Count=3),'SDL Enter accepts custom combo value without insertion');
    C.Text:='123456789012345678901234567890';
    C.CaretIndex:=Length(C.Text);
    AHost.Render;
    Check(C.TextInputRect(AHost.Canvas).Left+C.TextInputRect(AHost.Canvas).Width<=150,'SDL editable combo caret stays outside dropdown arrow');
    Key(27);
    Check(C.Text='Custom','SDL Escape restores custom combo value');
    C.SelectAll;
    E:=Default(TSDL_Event);
    E.type_:=SDL_EVENT_TEXT_EDITING;
    E.edit.windowID:=SDL_GetWindowID(AWindow);
    E.edit.text:='Preview';
    AHost.ProcessEvent(E);
    Key(13);
    Check((C.CompositionText='Preview') AND (P.Accepts=3),'SDL composition Enter does not accept combo draft');
    E:=Default(TSDL_Event);
    E.type_:=SDL_EVENT_TEXT_INPUT;
    E.text.windowID:=SDL_GetWindowID(AWindow);
    E.text.text:='C';
    AHost.ProcessEvent(E);
    Key(13);
    Check((C.SelectedIndex=2) AND (P.Accepts=4),'SDL committed composition can select existing combo label');
    C.Items.Add('Beta');
    C.AutoComplete:=True;
    C.SelectAll;
    E:=Default(TSDL_Event);
    E.type_:=SDL_EVENT_TEXT_INPUT;
    E.text.windowID:=SDL_GetWindowID(AWindow);
    E.text.text:='be';
    AHost.ProcessEvent(E);
    Check((C.Text='Beta') AND (C.SelectedText='ta') AND
      (C.SelectedIndex=2) AND (P.Accepts=4),
      'SDL combo insertion completes selected suffix without accepting');
    Key(13);
    Check((C.SelectedIndex=3) AND (P.Accepts=5),'SDL Enter accepts completed combo choice');
    C.Editable:=False;
    C.TypeAhead:=False;
    AHost.Render;
    Check(NOT SDL_TextInputActive(AWindow),'Noneditable combo stops native text input when type-ahead is disabled');
    C.TypeAhead:=True;
    AHost.Context.Root.Enabled:=False;
    AHost.Render;
    Check(NOT SDL_TextInputActive(AWindow),'Disabled ancestry stops native combo search input');
    AHost.Context.Root.Enabled:=True;
  finally
    C.Free;
    P.Free;
    if Assigned(Previous) then AHost.Context.SetFocus(Previous);
  end;
end;

procedure TestButtonPressPixels(ARenderer: PSDL_Renderer);
var B: TGuiButton;
Canvas: TGuiSDL3Canvas;
E: TGuiEvent;
S: PSDL_Surface;
C: TGuiColor;
  SavedX,SavedY: Single;
  procedure CheckCenter(Expected: Byte; const Message: String);
  begin
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    B.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read button press pixels');
    try
      Check(SDL_ReadSurfacePixel(S,70,20,@C.R,@C.G,@C.B,@C.A),'Read button center');
      Check(C.R=Expected,Message);
    finally
      SDL_DestroySurface(S);
    end;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  B:=TGuiButton.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    B.Bounds:=GuiRect(10,10,120,32);
    SetStyleDrawable(B, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(B, sdsPressedBackground,GuiColorDrawable(GuiColor(200,0,0)));
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=32;
    B.HandleEvent(E);
    CheckCenter(200,'Keyboard hold paints pressed button background');
    E.Kind:=gekKeyUp;
    E.Handled:=False;
    B.HandleEvent(E);
    CheckCenter(0,'Keyboard release restores ordinary button background');
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbRight;
    E.Position:=GuiPoint(70,20);
    B.HandleEvent(E);
    CheckCenter(0,'Secondary button does not paint primary pressed feedback');
  finally
    B.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestTabFoundationPixels(ARenderer: PSDL_Renderer);
var Tabs: TGuiTabControl;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
C: TGuiColor;
  E: TGuiEvent;
  SavedX,SavedY: Single;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read tab pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  Tabs:=TGuiTabControl.Create;
  Canvas:=TMetricPixelCanvas.Create(ARenderer);
  try
    Tabs.Bounds:=GuiRect(10,10,180,16);
    SetStyleDrawable(Tabs, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(Tabs, sdsCheckedBackground,GuiColorDrawable(GuiColor(200,0,0)));
    Tabs.AddTab('Selected');
    Tabs.AddTab('Other');
    Tabs.Items.Insert(0,'Before');
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Tabs.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read short mutated tab header');
    try
      Check((RedAt(90,20)=200) AND (RedAt(20,20)=0),'Tab selected background follows inserted row identity');
      Check((RedAt(90,30)=0) AND (RedAt(195,20)=0),'Tall tab header stays within short control bounds');
    finally
      SDL_DestroySurface(S);
    end;
    SetStyleColor(Tabs, scsDisabledBackgroundColor,GuiColor(70,0,0));
    Tabs.TabEnabled[1]:=False;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Tabs.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read disabled tab header');
    try
      Check((RedAt(90,20)=70) AND (RedAt(150,20)=200),'Disabled tab is muted while fallback selection is highlighted');
    finally
      SDL_DestroySurface(S);
    end;
    Tabs.TabWidth:=100;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Tabs.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read overflowing tab header');
    try
      Check((RedAt(100,20)=200) AND (RedAt(180,20)=70),
        'Overflow reveals selection but clips it before disabled end button');
      Check((RedAt(195,20)=0) AND (RedAt(100,30)=0),'Overflow stays inside short control bounds');
    finally
      SDL_DestroySurface(S);
    end;
    Tabs.ScrollOffset:=0;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Tabs.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read manually scrolled tab header');
    try
      Check((RedAt(80,20)=0) AND (RedAt(150,20)=70) AND (RedAt(180,20)=0),
        'Manual scroll paints visible rows and enabled end button without leaking selection');
    finally
      SDL_DestroySurface(S);
    end;
    Tabs.Bounds:=GuiRect(10,10,180,80);
    Tabs.TabPosition:=gtpBottom;
    SetStyleColor(Tabs, scsCheckedBorderColor,GuiColor(111,0,0));
    Tabs.SelectedIndex:=2;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Tabs.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read bottom tab placement');
    try
      Check((RedAt(100,70)=200) AND (RedAt(100,20)=0),'Bottom tab selection paints footer rather than body');
      Check(RedAt(100,60)=111,'Bottom tab selection marker faces the body above');
      Check((RedAt(180,70)=70) AND (RedAt(100,95)=0),'Bottom overflow button and clipping follow footer geometry');
    finally
      SDL_DestroySurface(S);
    end;
    Tabs.Items.Clear;
    Tabs.AddTab('A');
    Tabs.AddTab('Long label');
    Tabs.AddTab('Z');
    Tabs.TabPosition:=gtpTop;
    Tabs.TabWidth:=0;
    Tabs.AutoSizeTabs:=True;
    Tabs.SelectedIndex:=1;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Tabs.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read content-sized tab selection');
    try
      Check((RedAt(60,20)=200) AND (RedAt(150,20)=0),
        'Content-sized selected background uses measured variable-width boundaries');
    finally
      SDL_DestroySurface(S);
    end;
    Tabs.AutoSizeTabs:=False;
    Tabs.TabWidth:=100;
    Tabs.SelectedIndex:=0;
    Tabs.ScrollOffset:=0;
    Tabs.FlickEnabled:=False;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(120,20);
    Tabs.HandleEvent(E);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseMove;
    E.Position:=GuiPoint(60,20);
    Tabs.HandleEvent(E);
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Tabs.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read dragged tab header');
    try
      Check((Tabs.SelectedIndex=0) AND (RedAt(50,20)=200) AND (RedAt(100,20)=0),
        'Dragged tab pixels follow offset without selecting another tab');
    finally
      SDL_DestroySurface(S);
    end;
    E:=Default(TGuiEvent);
    E.Kind:=gekCancel;
    Tabs.HandleEvent(E);
  finally
    Tabs.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestNarrowTabPixels(ARenderer: PSDL_Renderer);
var T: TGuiTabControl;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
  C: TGuiColor;
  SavedX,SavedY: Single;
  Position: Integer;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  T:=TGuiTabControl.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    T.Bounds:=GuiRect(40,40,8,20);
    T.AddTab('');
    SetStyleFloat(T, sfsBorderWidth,0);
    SetStyleDrawable(T, sdsCheckedBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleColor(T, scsCheckedBorderColor,GuiColor(255,0,0));
    for Position:=0 to 1 do
    begin
      T.TabPosition:=TGuiTabPosition(Position);
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      T.Paint(Canvas);
      S:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(S),'Read narrow selected tab');
      try
        if Position=0 then
          Check(SDL_ReadSurfacePixel(S,44,58,@C.R,@C.G,@C.B,@C.A),'Read top-tab indicator')
        else Check(SDL_ReadSurfacePixel(S,44,42,@C.R,@C.G,@C.B,@C.A),'Read bottom-tab indicator');
        Check(C.R>0,'Narrow selected tab retains its selection underline');
      finally
        SDL_DestroySurface(S);
      end;
    end;
  finally
    T.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestComboStatePixels(ARenderer: PSDL_Renderer);
var Combo: TGuiComboBox;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
  Context: TGuiContext;
  C: TGuiColor;
  E: TGuiEvent;
  SavedX,SavedY: Single;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read combo pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  Combo:=TGuiComboBox.Create;
  Canvas:=TMetricPixelCanvas.Create(ARenderer);
  Context:=TGuiContext.Create;
  try
    Combo.Bounds:=GuiRect(10,10,180,30);
    SetStyleDrawable(Combo, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(Combo, sdsHoverBackground,GuiColorDrawable(GuiColor(50,50,50)));
    SetStyleDrawable(Combo, sdsSelection,GuiColorDrawable(GuiColor(200,0,0)));
    Combo.AddItem('A');
    Combo.AddItem('B');
    Combo.AddItem('C');
    Combo.SelectedIndex:=1;
    Combo.DroppedDown:=True;
    Combo.Items.Insert(0,'New');
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseMove;
    E.Position:=GuiPoint(40,85);
    Combo.HandleEvent(E);
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Combo.PaintOverlay(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read mutated combo popup');
    try
      Check(RedAt(40,115)=200,'Combo selection highlight follows row inserted before selected item');
      Check(RedAt(40,85)=50,'Combo hover highlights a different row without changing selection');
      Check((RedAt(40,55)=0) AND (Combo.SelectedIndex=2),'Combo unselected row retains idle background');
    finally
      SDL_DestroySurface(S);
    end;
    Combo.Items.Clear;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Combo.PaintOverlay(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read cleared combo popup');
    try
      Check((RedAt(40,115)=0) AND NOT Combo.DroppedDown,'Clearing combo removes popup highlight');
    finally
      SDL_DestroySurface(S);
    end;
    Context.Resize(400,200);
    Context.Root.Add(Combo);
    Combo.Bounds:=GuiRect(350,170,80,30);
    Combo.AddItem('A');
    Combo.AddItem('B');
    Combo.AddItem('C');
    Combo.DropDownCount:=2;
    Combo.SelectedIndex:=1;
    Combo.DroppedDown:=True;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Combo.PaintOverlay(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read viewport-constrained combo popup');
    try
      Check(RedAt(330,155)=200,'Upward combo popup paints selected row at clamped horizontal position');
      Check((RedAt(330,180)=0) AND (RedAt(310,155)=0),'Constrained combo popup stays above anchor and inside its clamped rectangle');
    finally
      SDL_DestroySurface(S);
    end;
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=$40000051;
    Combo.HandleEvent(E);
    Combo.PaintOverlay(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read combo keyboard preview');
    try
      Check((RedAt(330,155)=50) AND (RedAt(330,125)=200) AND (Combo.SelectedIndex=1),
      'Combo keyboard preview paints independently of committed selection');
    finally
      SDL_DestroySurface(S);
    end;
    Combo.DroppedDown:=False;
    Combo.Bounds:=GuiRect(10,10,180,40);
    Combo.Editable:=True;
    Combo.Text:='123456789012345678901234567890';
    Combo.SelectAll;
    Combo.Focused:=True;
    Combo.CaretBlink:=False;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Combo.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read editable combo selection');
    try
      Check(RedAt(120,30)=200,'Editable combo paints selection in text lane');
      Check((RedAt(182,35)=0) AND (RedAt(195,30)=0),'Editable combo selection stays outside arrow and control edge');
    finally
      SDL_DestroySurface(S);
    end;
    Combo.Items.Add('Completed');
    Combo.Text:='co';
    Combo.CaretIndex:=2;
    Combo.CompleteText;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Combo.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read combo completion suffix');
    try
      Check((RedAt(22,30)=0) AND (RedAt(42,30)=200) AND (Combo.SelectedText='mpleted'),
      'Combo completion selects and paints only the suggested suffix');
    finally
      SDL_DestroySurface(S);
    end;
  finally
    Combo.Free;
    Context.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestSpinPixels(ARenderer: PSDL_Renderer);
var Spin: TGuiSpinEdit;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
C: TGuiColor;
SavedX,SavedY: Single;
  E: TGuiEvent;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read spin pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  Spin:=TGuiSpinEdit.Create;
  Canvas:=TMetricPixelCanvas.Create(ARenderer);
  try
    Spin.Bounds:=GuiRect(10,10,180,40);
    Spin.Focused:=True;
    Spin.CaretBlink:=False;
    SetStyleDrawable(Spin, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(Spin, sdsHoverBackground,GuiColorDrawable(GuiColor(50,50,50)));
    SetStyleDrawable(Spin, sdsPressedBackground,GuiColorDrawable(GuiColor(100,100,100)));
    SetStyleDrawable(Spin, sdsSelection,GuiColorDrawable(GuiColor(200,0,0)));
    SetStyleColor(Spin, scsTextColor,GuiColor(0,0,0));
    Spin.Text:='123456789012345678901234567890';
    Spin.SelectAll;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Spin.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read spin editor selection');
    try
      Check(RedAt(120,30)=200,'Spin editor paints text selection inside edit lane');
      Check(RedAt(170,25)=0,'Spin selection does not cover idle arrow-button face');
      Check(RedAt(195,30)=0,'Spin editor paints no text beyond control bounds');
    finally
      SDL_DestroySurface(S);
    end;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseMove;
    E.Position:=GuiPoint(170,25);
    Spin.HandleEvent(E);
    Spin.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read spin hovered arrow');
    try
      Check((RedAt(170,25)=50) AND (RedAt(170,40)=0),'Only hovered spin arrow uses hover face');
    finally
      SDL_DestroySurface(S);
    end;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(170,25);
    Spin.HandleEvent(E);
    Spin.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read spin pressed arrow');
    try
      Check((RedAt(170,25)=100) AND (RedAt(170,40)=0),'Only held spin arrow uses pressed face');
    finally
      SDL_DestroySurface(S);
    end;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseUp;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(170,25);
    Spin.HandleEvent(E);
    Spin.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read spin released arrow');
    try
      Check(RedAt(170,25)=50,'Spin arrow returns to hover face after release');
    finally
      SDL_DestroySurface(S);
    end;
  finally
    Spin.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestWheelPixels(ARenderer: PSDL_Renderer);
var W: TGuiWheelPicker;
Canvas: TWheelPixelCanvas;
S: PSDL_Surface;
C: TGuiColor;
  SavedX,SavedY: Single;
  I: Integer;
  E: TGuiEvent;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read wheel pixel');
    Result:=C.R;
  end;
  procedure Render;
  begin
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    W.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read wheel rendering');
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  W:=TGuiWheelPicker.Create;
  Canvas:=TWheelPixelCanvas.Create(ARenderer);
  try
    W.Bounds:=GuiRect(10,10,160,180);
    W.Padding:=GuiBox(0);
    SetStyleDrawable(W, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(W, sdsSelection,GuiColorDrawable(GuiColor(40,0,0)));
    SetStyleColor(W, scsTextColor,GuiColor(255,255,255));
    SetStyleColor(W, scsDisabledTextColor,GuiColor(120,120,120));
    for I:=0 to 9 do W.AddItem('X');
    W.ItemIndex:=5;
    Render;
    try
      Check((RedAt(90,28)<RedAt(90,64)) AND (RedAt(90,64)<RedAt(90,100)) AND (RedAt(90,100)=255),
        'Wheel rows fade away from fully opaque centered selection');
      Check((RedAt(30,100)=40) AND (RedAt(30,64)=0),'Wheel selection highlight is confined to center row');
      Check((RedAt(90,5)=0) AND (RedAt(90,195)=0),'Wheel rows stay clipped to bounds');
    finally
      SDL_DestroySurface(S);
    end;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(90,100);
    W.HandleEvent(E);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseMove;
    E.Position:=GuiPoint(90,80);
    W.HandleEvent(E);
    Render;
    try
      Check((RedAt(90,80)>100) AND (RedAt(90,100)=40),'Wheel drag translates rows while highlight stays centered');
    finally
      SDL_DestroySurface(S);
    end;
    W.ItemIndex:=5;
    W.Enabled:=False;
    Render;
    try
      Check(RedAt(90,100)=120,'Disabled wheel text is muted');
    finally
      SDL_DestroySurface(S);
    end;
    W.Items.Clear;
    Render;
    try
      Check(RedAt(30,100)=0,'Empty wheel has no phantom center selection');
    finally
      SDL_DestroySurface(S);
    end;
  finally
    W.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestRangePixels(ARenderer: PSDL_Renderer);
var R: TGuiRangeSlider;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
C: TGuiColor;
  E: TGuiEvent;
  SavedX,SavedY: Single;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read range-slider pixel');
    Result:=C.R;
  end;
  procedure Render;
  begin
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    R.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read range-slider rendering');
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  R:=TGuiRangeSlider.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    R.Bounds:=GuiRect(10,10,220,40);
    SetStyleColor(R, scsBorderColor,GuiColor(60,60,60));
    SetStyleDrawable(R, sdsThumb,GuiColorDrawable(GuiColor(180,0,0)));
    SetStyleColor(R, scsDisabledTextColor,GuiColor(90,90,90));
    SetStyleDrawable(R, sdsBackground,GuiColorDrawable(GuiColor(255,255,255)));
    SetStyleDrawable(R, sdsPressedBackground,R.Style.Background);
    Render;
    try
      Check((RedAt(70,30)=255) AND (RedAt(170,30)=255),'Range slider paints two distinct endpoint thumbs');
      Check((RedAt(40,30)=60) AND (RedAt(120,30)=180) AND (RedAt(200,30)=60),'Range fill covers only the selected interval');
    finally
      SDL_DestroySurface(S);
    end;
    R.Live:=False;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(70,30);
    R.HandleEvent(E);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseMove;
    E.Position:=GuiPoint(120,30);
    R.HandleEvent(E);
    Render;
    try
      Check((RedAt(80,30)=60) AND (RedAt(120,30)=255) AND (RedAt(145,30)=180) AND (R.LowerValue=25),
      'Deferred range rendering follows preview without committing values');
    finally
      SDL_DestroySurface(S);
    end;
    E:=Default(TGuiEvent);
    E.Kind:=gekCancel;
    R.HandleEvent(E);
    R.Orientation:=goVertical;
    R.Bounds:=GuiRect(10,10,40,220);
    Render;
    try
      Check((RedAt(30,70)=255) AND (RedAt(30,170)=255) AND (RedAt(30,120)=180) AND (RedAt(30,40)=60),
      'Vertical range thumbs and interval fill follow upward value direction');
    finally
      SDL_DestroySurface(S);
    end;
    R.Enabled:=False;
    Render;
    try
      Check(RedAt(30,120)=90,'Disabled range interval is muted');
    finally
      SDL_DestroySurface(S);
    end;
    R.Enabled:=True;
    R.SetValues(50,50);
    Render;
    try
      Check((RedAt(30,120)=255) AND (RedAt(30,90)=60),'Coincident range endpoints render without spurious interval fill');
    finally
      SDL_DestroySurface(S);
    end;
  finally
    R.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestDelayPixels(ARenderer: PSDL_Renderer);
var B: TPixelDelay;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
C: TGuiColor;
  E: TGuiEvent;
  SDLEvent: TSDL_Event;
  SavedX,SavedY: Single;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read delay pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  B:=TPixelDelay.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    SDLEvent:=Default(TSDL_Event);
    SDLEvent.type_:=SDL_EVENT_KEY_DOWN;
    SDLEvent.key.key:=32;
    SDLEvent.key.repeat_:=True;
    Check(GuiEventFromSDL3(SDLEvent,E) AND E.KeyRepeat,'SDL preserves key-repeat metadata for timed controls');
    B.Bounds:=GuiRect(10,10,110,40);
    SetStyleColor(B, scsCheckedBorderColor,GuiColor(255,0,0));
    SetStyleColor(B, scsDisabledTextColor,GuiColor(90,90,90));
    SetStyleDrawable(B, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(B, sdsPressedBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(B, sdsCheckedBackground,GuiColorDrawable(GuiColor(0,0,0)));
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(30,20);
    B.HandleEvent(E);
    B.Ticks:=1500;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    B.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read delay progress strip');
    try
      Check((RedAt(30,43)=255) AND (RedAt(90,43)=0),'Delay strip fills exactly elapsed half');
      Check(RedAt(30,38)=0,'Delay strip leaves caption interior unobscured');
      Check(NOT B.Checked,'Painting progress does not trigger activation');
    finally
      SDL_DestroySurface(S);
    end;
    B.Ticks:=3000;
    B.UpdateHold;
    B.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read confirmed delay strip');
    try
      Check((RedAt(110,43)=255) AND B.Checked,'Confirmed delay strip remains fully filled');
    finally
      SDL_DestroySurface(S);
    end;
    B.Enabled:=False;
    B.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read disabled delay strip');
    try
      Check(RedAt(30,43)=90,'Disabled confirmation progress is muted');
    finally
      SDL_DestroySurface(S);
    end;
  finally
    B.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestSwitchListPixels(ARenderer: PSDL_Renderer);
var L: TGuiSwitchListBox;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
C: TGuiColor;
  E: TGuiEvent;
  SavedX,SavedY: Single;
  I: Integer;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read switch-list pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  L:=TGuiSwitchListBox.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    L.Bounds:=GuiRect(10,10,180,110);
    L.Padding:=GuiBox(4);
    L.ItemHeight:=34;
    L.BackgroundColor:=GuiColor(0,0,0);
    SetStyleDrawable(L, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(L, sdsCheckedBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(L, sdsSelection,GuiColorDrawable(GuiColor(120,0,0)));
    SetStyleColor(L, scsTextColor,GuiColor(255,255,255));
    SetStyleColor(L, scsDisabledTextColor,GuiColor(90,90,90));
    for I:=0 to 9 do L.AddItem('');
    L.Checked[1]:=True;
    L.Checked[2]:=True;
    L.ItemEnabled[2]:=False;
    L.SelectedIndex:=1;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    L.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read switch-list rendering');
    try
      Check((RedAt(32,31)=255) AND (RedAt(52,31)=0),'Unchecked row switch thumb is at left');
      Check((RedAt(32,65)=0) AND (RedAt(52,65)=255),'Checked row switch thumb is at right');
      Check(RedAt(52,99)=90,'Disabled switch thumb is dimmed');
      Check(RedAt(160,65)=120,'Switch-list selection spans caption area');
    finally
      SDL_DestroySurface(S);
    end;
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseDown;
    E.Button:=gmbLeft;
    E.Position:=GuiPoint(32,31);
    L.HandleEvent(E);
    E:=Default(TGuiEvent);
    E.Kind:=gekMouseMove;
    E.Position:=GuiPoint(42,31);
    L.HandleEvent(E);
    SDL_RenderClear(ARenderer);
    L.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read switch-list drag preview');
    try
      Check((RedAt(42,31)=255) AND NOT L.Checked[0],'Switch drag renders midpoint without early state commit');
    finally
      SDL_DestroySurface(S);
    end;
  finally
    L.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestCheckListPixels(ARenderer: PSDL_Renderer);
var L: TGuiCheckListBox;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
C: TGuiColor;
  SavedX,SavedY: Single;
  I: Integer;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read checklist pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  L:=TGuiCheckListBox.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    L.Bounds:=GuiRect(10,10,180,110);
    L.Padding:=GuiBox(4);
    L.ItemHeight:=34;
    L.BackgroundColor:=GuiColor(0,0,0);
    SetStyleDrawable(L, sdsSelection,GuiColorDrawable(GuiColor(120,0,0)));
    SetStyleColor(L, scsBorderColor,GuiColor(60,60,60));
    SetStyleColor(L, scsCheckedBorderColor,GuiColor(255,255,255));
    SetStyleColor(L, scsDisabledTextColor,GuiColor(90,90,90));
    for I:=0 to 9 do L.AddItem('');
    L.State[1]:=gcbGrayed;
    L.State[2]:=gcbGrayed;
    L.ItemEnabled[2]:=False;
    L.SelectedIndex:=1;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    L.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read checklist rendering');
    try
      Check((RedAt(31,31)=0) AND (RedAt(31,65)=255) AND (RedAt(31,99)=90),
        'Checklist centers mixed indicators and dims disabled state');
      Check(RedAt(160,65)=120,'Checklist selection spans caption area');
      Check(RedAt(31,60)=120,'Mixed indicator retains unfilled interior above dash');
    finally
      SDL_DestroySurface(S);
    end;
  finally
    L.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestRadioGroupPixels(ARenderer: PSDL_Renderer);
var R: TGuiRadioGroup;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
C: TGuiColor;
  SavedX,SavedY: Single;
  I: Integer;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read radio row pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  R:=TGuiRadioGroup.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    R.Bounds:=GuiRect(10,10,180,110);
    R.Padding:=GuiBox(4);
    R.ItemHeight:=34;
    R.BackgroundColor:=GuiColor(0,0,0);
    SetStyleDrawable(R, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(R, sdsSelection,GuiColorDrawable(GuiColor(120,0,0)));
    SetStyleColor(R, scsBorderColor,GuiColor(60,60,60));
    SetStyleColor(R, scsCheckedBorderColor,GuiColor(255,255,255));
    for I:=0 to 9 do R.AddItem('');
    R.ItemIndex:=1;
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    R.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read full-row radio rendering');
    try
      Check((RedAt(31,31)=0) AND (RedAt(31,65)=255) AND (RedAt(31,99)=0),
        'Radio group paints exactly one centered selected dot');
      Check(RedAt(160,65)=120,'Radio selection spans the caption and full row');
      Check((RedAt(31,56)=255) AND (RedAt(31,58)=120),'Radio group retains circular outline with an unfilled interior');
    finally
      SDL_DestroySurface(S);
    end;
  finally
    R.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestRadioPixels(ARenderer: PSDL_Renderer);
var B: TGuiRadioButton;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
  C: TGuiColor;
  SavedX,SavedY: Single;
  I,Expected: Integer;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  B:=TGuiRadioButton.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    B.Bounds:=GuiRect(10,10,120,36);
    B.Caption:='';
    SetStyleFloat(B, sfsBorderWidth,0);
    SetStyleDrawable(B, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(B, sdsCheckedBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(B, sdsThumb,GuiColorDrawable(GuiColor(255,255,255)));
    SetStyleColor(B, scsDisabledTextColor,GuiColor(80,80,80));
    for I:=0 to 2 do
    begin
      B.Checked:=I>0;
      B.Enabled:=I<2;
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      B.Paint(Canvas);
      S:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(S),'Read radio indicator pixels');
      try
        Check(SDL_ReadSurfacePixel(S,23,28,@C.R,@C.G,@C.B,@C.A),'Read centered radio dot');
        case I of 0: Expected:=0;
        1: Expected:=255;
        else Expected:=80;
        end;
        Check(C.R=Expected,'Radio dot distinguishes unchecked, checked and muted disabled states');
      finally
        SDL_DestroySurface(S);
      end;
    end;
  finally
    B.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestTabButtonPixels(ARenderer: PSDL_Renderer);
var B: TGuiTabButton;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
C: TGuiColor;
  SavedX,SavedY: Single;
  I: Integer;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read tab pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  B:=TGuiTabButton.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    B.Bounds:=GuiRect(10,10,120,36);
    B.Caption:='';
    SetStyleDrawable(B, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(B, sdsCheckedBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleColor(B, scsCheckedBorderColor,GuiColor(255,255,255));
    SetStyleColor(B, scsBorderColor,GuiColor(40,40,40));
    for I:=0 to 1 do
    begin
      B.Down:=I=1;
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      B.Paint(Canvas);
      S:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(S),'Read standalone tab rendering');
      try
        if I=0 then Check((RedAt(60,45)=40) AND (RedAt(60,44)=0),'Unselected tab has a thin baseline')
        else Check((RedAt(60,44)=255) AND (RedAt(60,45)=255) AND (RedAt(12,45)=0),
          'Selected tab has an inset two-pixel accent underline');
        Check(RedAt(10,20)=0,'Standalone tab avoids a duplicate side border');
      finally
        SDL_DestroySurface(S);
      end;
    end;
    B.Down:=True;
    B.Bounds:=GuiRect(10,10,8,3);
    SetStyleColor(B, scsDisabledTextColor,GuiColor(100,100,100));
    for I:=0 to 1 do
    begin
      B.Enabled:=I=0;
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      B.Paint(Canvas);
      S:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(S),'Read narrow tab rendering');
      try
        if I=0 then Check(RedAt(13,11)=255,'Narrow selected tab retains an accent underline')
        else Check(RedAt(13,11)=100,'Narrow disabled selected tab retains a muted underline');
        Check((RedAt(9,11)=0) AND (RedAt(18,11)=0) AND (RedAt(13,13)=0),
          'Narrow tab underline remains inside its bounds');
      finally
        SDL_DestroySurface(S);
      end;
    end;
  finally
    B.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestToolbarPixels(ARenderer: PSDL_Renderer);
var Bar: TGuiToolBar;
Child: TGuiPanel;
Sep: TGuiSeparator;
Canvas: TGuiSDL3Canvas;
  S: PSDL_Surface;
  C: TGuiColor;
  SavedX,SavedY: Single;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read toolbar pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  Bar:=TGuiToolBar.Create;
  Sep:=TGuiSeparator.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    Bar.Bounds:=GuiRect(10,10,80,30);
    Bar.Padding:=GuiBox(0);
    Bar.Spacing:=0;
    Child:=TGuiPanel.Create;
    Child.Bounds:=GuiRect(0,0,160,30);
    Child.Margin:=GuiBox(0);
    Child.BackgroundColor:=GuiColor(200,0,0);
    SetStyleFloat(Child, sfsBorderWidth,0);
    Bar.Add(Child);
    Bar.Arrange(Bar.Bounds);
    Sep.Bounds:=GuiRect(10,60,40,4);
    Sep.Thickness:=100;
    SetStyleColor(Sep, scsBorderColor,GuiColor(150,0,0));
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Bar.Paint(Canvas);
    Sep.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read toolbar and separator rendering');
    try
      Check((RedAt(40,25)=200) AND (RedAt(100,25)=0),'Toolbar clips overflowing embedded child pixels');
      Check((RedAt(20,61)=150) AND (RedAt(20,59)=0) AND (RedAt(20,65)=0),
        'Oversized separator paints only inside its own thickness bounds');
    finally
      SDL_DestroySurface(S);
    end;
  finally
    Bar.Free;
    Sep.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestSpeedButtonPixels(ARenderer: PSDL_Renderer);
var B: TGuiSpeedButton;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
  C: TGuiColor;
  SavedX,SavedY: Single;
  I: Integer;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read speed button pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  B:=TGuiSpeedButton.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    B.Bounds:=GuiRect(10,10,32,32);
    B.Caption:='';
    B.Icon:=GuiColorDrawable(GuiColor(255,255,255));
    SetStyleFloat(B, sfsBorderWidth,0);
    SetStyleFloat(B, sfsCornerRadius,0);
    SetStyleDrawable(B, sdsCheckedBackground,GuiColorDrawable(GuiColor(120,0,0)));
    for I:=0 to 1 do
    begin
      B.Down:=I=1;
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      B.Paint(Canvas);
      S:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(S),'Read speed button rendering');
      try
        Check((RedAt(18,26)=255) AND (RedAt(33,26)=255) AND (RedAt(17,26)=I*120) AND
          (RedAt(34,26)=I*120),'Speed button icon is exactly centered in idle and down states');
        Check(RedAt(12,12)=I*120,'Speed button retains transparent idle and visible checked surface');
      finally
        SDL_DestroySurface(S);
      end;
    end;
  finally
    B.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestDeterminateProgressPixels(ARenderer: PSDL_Renderer);
var P: TGuiProgressBar;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
  C: TGuiColor;
  SavedX,SavedY: Single;
  Axis,Rev,X,Y,Mode: Integer;
  function RedAt(X,Y: Integer): Byte;
  begin
    Check(SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A),'Read progress pixel');
    Result:=C.R;
  end;
  procedure Paint;
  begin
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    P.Paint(Canvas);
    S:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(S),'Read determinate progress');
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  P:=TGuiProgressBar.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    P.Padding:=GuiBox(0);
    SetStyleFloat(P, sfsCornerRadius,0);
    SetStyleFloat(P, sfsBorderWidth,0);
    SetStyleDrawable(P, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(P, sdsTrack,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(P, sdsThumb,GuiColorDrawable(GuiColor(255,255,255)));
    P.Bounds:=GuiRect(20,20,100,20);
    P.MinValue:=-3.0E38;
    P.MaxValue:=3.0E38;
    P.Value:=0;
    Paint;
    try
      Check((RedAt(69,30)=255) AND (RedAt(70,30)=0),
        'Extreme finite range retains exact midpoint progress');
    finally
      SDL_DestroySurface(S);
    end;
    P.ShowThreshold:=True;
    P.ThresholdValue:=0;
    P.ThresholdColor:=GuiColor(180,0,0);
    Paint;
    try
      Check(RedAt(70,30)=180,'Extreme finite range threshold uses the same midpoint');
    finally
      SDL_DestroySurface(S);
    end;
    P.ShowThreshold:=False;
    P.MinValue:=0;
    P.MaxValue:=100;
    P.ShowThreshold:=True;
    P.ThresholdValue:=50;
    P.ShowTicks:=True;
    P.TickCount:=5;
    P.Padding:=GuiBox(4);
    P.Bounds:=GuiRect(20,20,2,2);
    Paint;
    try
      for Y:=15 to 30 do for X:=15 to 30 do
        if (X<20) OR (X>=22) OR (Y<20) OR (Y>=22) then
          Check(RedAt(X,Y)=0,'Tiny decorated progress stays inside control bounds');
    finally
      SDL_DestroySurface(S);
    end;
    P.Bounds:=GuiRect(20,20,0,0);
    Paint;
    try
      Check(RedAt(24,24)=0,'Empty decorated progress paints nothing');
    finally
      SDL_DestroySurface(S);
    end;
    P.ShowThreshold:=False;
    P.ShowTicks:=False;
    P.Padding:=GuiBox(0);
    P.Bounds:=GuiRect(20,20,100,20);
    P.SegmentCount:=High(Integer);
    P.Value:=50;
    Paint;
    try
      Check((RedAt(69,30)=255) AND (RedAt(70,30)=0),
      'Dense segments preserve the continuous progress envelope');
    finally
      SDL_DestroySurface(S);
    end;
    P.ShowTicks:=True;
    P.TickCount:=High(Integer);
    P.TickColor:=GuiColor(180,0,0);
    Paint;
    try
      Check((RedAt(20,30)=180) AND (RedAt(119,30)=180) AND (RedAt(120,30)=0),
      'Dense ticks form a bounded band without escaping the track');
    finally
      SDL_DestroySurface(S);
    end;
    P.ShowTicks:=False;
    P.SegmentCount:=2;
    P.SegmentGap:=20;
    P.Value:=25;
    for Axis:=0 to 1 do for Rev:=0 to 1 do
    begin
      P.Orientation:=TGuiOrientation(Axis);
      P.Reverse:=Rev=1;
      if Axis=0 then P.Bounds:=GuiRect(20,20,100,20)
      else P.Bounds:=GuiRect(20,20,20,100);
      Paint;
      try
        if Axis=0 then
        begin
          if Rev=0 then Check((RedAt(39,30)=255) AND (RedAt(40,30)=0),
            'Quarter progress fills half the first segment')
          else Check((RedAt(100,30)=255) AND (RedAt(99,30)=0),
            'Reversed quarter progress fills half the first segment');
        end else
        begin
          if Rev=0 then Check((RedAt(30,100)=255) AND (RedAt(30,99)=0),
            'Vertical quarter progress fills half the first segment')
          else Check((RedAt(30,39)=255) AND (RedAt(30,40)=0),
            'Reversed vertical quarter progress fills half the first segment');
        end;
      finally
        SDL_DestroySurface(S);
      end;
    end;
    P.Enabled:=False;
    SetStyleColor(P, scsDisabledTextColor,GuiColor(100,100,100));
    for Mode:=0 to 2 do
    begin
      case Mode of
        0: P.SegmentCount:=0;
        1: P.SegmentCount:=2;
        2: P.SegmentCount:=High(Integer);
      end;
      P.Value:=75;
      P.SegmentGap:=20;
      for Axis:=0 to 1 do for Rev:=0 to 1 do
      begin
        P.Orientation:=TGuiOrientation(Axis);
        P.Reverse:=Rev=1;
        if Axis=0 then P.Bounds:=GuiRect(20,20,100,20)
        else P.Bounds:=GuiRect(20,20,20,100);
        Paint;
        try
          if Axis=0 then
          begin
            if Rev=0 then Check((RedAt(30,30)=100) AND (RedAt(85,30)=100),
              'Disabled normal and partial progress fills use disabled color')
            else Check((RedAt(110,30)=100) AND (RedAt(55,30)=100),
              'Disabled reversed progress fills use disabled color');
          end else
          begin
            if Rev=0 then Check((RedAt(30,110)=100) AND (RedAt(30,55)=100),
              'Disabled vertical progress fills use disabled color')
            else Check((RedAt(30,30)=100) AND (RedAt(30,85)=100),
              'Disabled reversed vertical progress fills use disabled color');
          end;
        finally
          SDL_DestroySurface(S);
        end;
      end;
    end;
    P.Enabled:=True;
    P.SegmentCount:=10;
    P.SegmentGap:=100;
    P.Value:=100;
    for Axis:=0 to 1 do for Rev:=0 to 1 do
    begin
      P.Orientation:=TGuiOrientation(Axis);
      P.Reverse:=Rev=1;
      if Axis=0 then P.Bounds:=GuiRect(20,20,100,20)
      else P.Bounds:=GuiRect(20,20,20,100);
      Paint;
      try
        Check((RedAt(19,30)=0) AND (RedAt(120,30)=0) AND
          (RedAt(30,19)=0) AND (RedAt(30,120)=0),
          'Oversized segment gaps never paint outside the track in either direction');
        Check(RedAt(23,23)=255,'Oversized gaps retain visible segments');
      finally
        SDL_DestroySurface(S);
      end;
    end;
  finally
    P.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestMarqueePixels(ARenderer: PSDL_Renderer);
var P: TPixelProgress;
Canvas: TGuiSDL3Canvas;
S: PSDL_Surface;
C: TGuiColor;
  SavedX,SavedY: Single;
  Axis,Rev,Frame: Integer;
  A,B: Byte;
  AtStart: Boolean;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(S,X,Y,@C.R,@C.G,@C.B,@C.A) then raise Exception.Create('Read marquee pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  P:=TPixelProgress.Create;
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    P.Marquee:=True;
    P.MarqueeInterval:=1000;
    P.Padding:=GuiBox(0);
    SetStyleDrawable(P, sdsBackground,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(P, sdsTrack,GuiColorDrawable(GuiColor(0,0,0)));
    SetStyleDrawable(P, sdsThumb,GuiColorDrawable(GuiColor(255,255,255)));
    SetStyleFloat(P, sfsBorderWidth,0);
    for Axis:=0 to 1 do for Rev:=0 to 1 do for Frame:=0 to 1 do
    begin
      P.Orientation:=TGuiOrientation(Axis);
      P.Reverse:=Rev=1;
      P.Ticks:=Frame*500;
      if P.Orientation=goHorizontal then P.Bounds:=GuiRect(10,10,100,20)
      else P.Bounds:=GuiRect(10,10,20,100);
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      P.Paint(Canvas);
      S:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(S),'Read marquee rendering');
      try
        if P.Orientation=goHorizontal then
        begin
          A:=RedAt(20,20);
          B:=RedAt(100,20);
          AtStart:=Frame=Rev;
        end
        else
        begin
          A:=RedAt(20,20);
          B:=RedAt(20,100);
          AtStart:=Frame<>Rev;
        end;
        Check((AtStart AND (A=255) AND (B=0)) OR (NOT AtStart AND (A=0) AND (B=255)),
          'Marquee respects animation endpoints, orientation and reverse');
        Check(RedAt(5,5)=0,'Marquee does not escape its bounds');
      finally
        SDL_DestroySurface(S);
      end;
    end;
  finally
    P.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestOptionButtonBounds(ARenderer: PSDL_Renderer);
var Canvas: TGuiSDL3Canvas;
B: TGuiButton;
Surface: PSDL_Surface;
  C: TGuiColor;
  SavedX,SavedY: Single;
  Kind,X,Y: Integer;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  try
    for Kind:=0 to 1 do
    begin
      if Kind=0 then B:=TGuiCheckBox.Create else B:=TGuiRadioButton.Create;
      try
        B.Bounds:=GuiRect(20,20,8,6);
        B.Caption:='';
        SetStyleDrawable(B, sdsBackground,GuiColorDrawable(GuiColor(255,255,255)));
        SetStyleColor(B, scsBorderColor,GuiColor(255,255,255));
        if Kind=0 then TGuiCheckBox(B).State:=gcbGrayed else TGuiRadioButton(B).Checked:=True;
        SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
        SDL_RenderClear(ARenderer);
        B.Paint(Canvas);
        Surface:=SDL_RenderReadPixels(ARenderer,nil);
        Check(Assigned(Surface),'Read tiny option button');
        try
          for Y:=8 to 42 do for X:=8 to 48 do
            if (X<20) OR (X>=28) OR (Y<20) OR (Y>=26) then
            begin
              if NOT SDL_ReadSurfacePixel(Surface,X,Y,@C.R,@C.G,@C.B,@C.A) then
                raise Exception.Create('Cannot read option bounds pixel');
              if (C.R<>0) OR (C.G<>0) OR (C.B<>0) then
                raise Exception.Create('Checkbox/radio painting escaped tiny control bounds');
            end;
          Check(True,'Checkbox/radio painting stays inside tiny control bounds');
        finally
          SDL_DestroySurface(Surface);
        end;
      finally
        B.Free;
      end;
    end;
  finally
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestPageIndicatorPixels(ARenderer: PSDL_Renderer);
var Canvas: TGuiSDL3Canvas;
D: TGuiPageIndicator;
Surface: PSDL_Surface;
  C: TGuiColor;
  SavedX,SavedY: Single;
  I: Integer;
  function RedAt(X,Y: Integer): Byte;
  begin
    if NOT SDL_ReadSurfacePixel(Surface,X,Y,@C.R,@C.G,@C.B,@C.A) then
      raise Exception.Create('Read page indicator pixel');
    Result:=C.R;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  D:=TGuiPageIndicator.Create;
  try
    D.Bounds:=GuiRect(10,10,100,40);
    D.Padding:=GuiBox(0);
    D.Count:=3;
    SetStyleColor(D, scsBorderColor,GuiColor(80,80,80));
    SetStyleColor(D, scsCheckedBorderColor,GuiColor(255,255,255));
    for I:=0 to 2 do
    begin
      D.SelectedIndex:=I;
      SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
      SDL_RenderClear(ARenderer);
      D.Paint(Canvas);
      Surface:=SDL_RenderReadPixels(ARenderer,nil);
      Check(Assigned(Surface),'Read page indicator rendering');
      try
        Check(RedAt(42+I*18,30)=255,'Selected dot is centered at its exact page position');
        Check(Abs(Integer(RedAt(42+((I+1) MOD 3)*18,30))-40)<=1,'Unselected dots are dim translucent markers');
        Check((RedAt(37,25)=0) AND (RedAt(10,10)=0),'Page dots retain circular corners and clear margins');
      finally
        SDL_DestroySurface(Surface);
      end;
    end;
  finally
    D.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestActivityAndSwitchPixels(ARenderer: PSDL_Renderer);
var Canvas: TGuiSDL3Canvas;
Busy: TPixelActivityIndicator;
Switch: TGuiToggleSwitch;
  Box: TGuiCheckBox;
  SavedX,SavedY: Single;
  Blank,First,Second: UInt64;
  Surface: PSDL_Surface;
  C: TGuiColor;
  procedure Clear;
  begin
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
  end;
  function Hash: UInt64;
  var X,Y: Integer;
  begin
    Surface:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(Surface),'Read new-control pixels');
    try
      Result:=0;
      for Y:=0 to 79 do for X:=0 to 119 do
      begin
        if NOT SDL_ReadSurfacePixel(Surface,X,Y,@C.R,@C.G,@C.B,@C.A) then
          raise Exception.Create('Read control pixel');
        Result:=((Result SHL 5) OR (Result SHR 59)) XOR UInt64(C.R+C.G*256+C.B*65536);
      end;
    finally
      SDL_DestroySurface(Surface);
    end;
  end;
  procedure CheckThumb(AOn: Boolean);
  var L,R: Byte;
  begin
    Switch.Checked:=AOn;
    Clear;
    Switch.Paint(Canvas);
    Surface:=SDL_RenderReadPixels(ARenderer,nil);
    Check(Assigned(Surface),'Read toggle switch thumb');
    try
      Check(SDL_ReadSurfacePixel(Surface,49,30,@C.R,@C.G,@C.B,@C.A),'Read left thumb center');
      L:=C.R;
      Check(SDL_ReadSurfacePixel(Surface,71,30,@C.R,@C.G,@C.B,@C.A),'Read right thumb center');
      R:=C.R;
      Check(((NOT AOn) AND (L=255) AND (R=0)) OR (AOn AND (L=0) AND (R=255)),
        'Switch renders its thumb at the correct checked/unchecked endpoint');
    finally
      SDL_DestroySurface(Surface);
    end;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  Busy:=TPixelActivityIndicator.Create;
  Switch:=TGuiToggleSwitch.Create;
  Box:=TGuiCheckBox.Create;
  try
    Busy.Bounds:=GuiRect(10,10,40,40);
    Clear;
    Blank:=Hash;
    Busy.Ticks:=0;
    Busy.Paint(Canvas);
    First:=Hash;
    Clear;
    Busy.Ticks:=80;
    Busy.Paint(Canvas);
    Second:=Hash;
    Check((First<>Blank) AND (Second<>First),'Activity animation produces distinct visible SDL frames');
    Clear;
    Busy.Animate:=False;
    Busy.Paint(Canvas);
    Check(Hash=Blank,'Stopped activity indicator is absent from SDL pixels');
    Busy.Animate:=True;
    Busy.Enabled:=False;
    Busy.Ticks:=0;
    Clear;
    Busy.Paint(Canvas);
    First:=Hash;
    Busy.Ticks:=80;
    Clear;
    Busy.Paint(Canvas);
    Check((Hash=First) AND (First<>Blank),'Disabled activity indicator renders a static muted frame');
    Switch.Bounds:=GuiRect(10,10,100,40);
    Switch.Caption:='';
    SetStyleColor(Switch, scsBackgroundColor,GuiColor(0,0,0));
    SetStyleColor(Switch, scsCheckedBackgroundColor,GuiColor(0,0,0));
    SetStyleColor(Switch, scsTextColor,GuiColor(255,255,255));
    SetStyleFloat(Switch, sfsBorderWidth,0);
    UpdateStyleDrawables(Switch);
    CheckThumb(False);
    CheckThumb(True);
    Box.Bounds:=GuiRect(10,10,100,40);
    Box.Caption:='';
    SetStyleColor(Box, scsBackgroundColor,GuiColor(0,0,0));
    SetStyleColor(Box, scsCheckedBackgroundColor,GuiColor(0,0,0));
    SetStyleColor(Box, scsDisabledBackgroundColor,GuiColor(0,0,0));
    SetStyleFloat(Box, sfsBorderWidth,0);
    SetStyleColor(Box, scsTextColor,GuiColor(255,255,255));
    SetStyleColor(Box, scsDisabledTextColor,GuiColor(80,80,80));
    UpdateStyleDrawables(Box);
    Clear;
    Box.Paint(Canvas);
    Check(Hash=Blank,'Unchecked checkbox has no indicator mark');
    Box.State:=gcbChecked;
    Clear;
    Box.Paint(Canvas);
    First:=Hash;
    Box.State:=gcbGrayed;
    Clear;
    Box.Paint(Canvas);
    Second:=Hash;
    Check((First<>Blank) AND (Second<>Blank) AND (First<>Second),
      'Checked and mixed checkbox states render distinct visible marks');
    Box.Enabled:=False;
    Clear;
    Box.Paint(Canvas);
    Check((Hash<>Second) AND (Box.State=gcbGrayed),'Disabled mixed checkbox uses muted pixels without losing its state');
  finally
    Box.Free;
    Switch.Free;
    Busy.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestUnicodeEditing(ARenderer: PSDL_Renderer; AFont: TGuiSDLTTFFontRenderer);
var Canvas: TGuiSDL3Canvas;
Edit: TGuiEdit;
Memo: TGuiMemo;
E: TGuiEvent;
  Accent,Emoji,S: String;
  R: TGuiRect;
  X,Width: TGuiFloat;
  I,Rows: Integer;
  procedure Key(Code: Cardinal; Shift: Boolean=False);
  begin
    Edit.PrepareTextLayout(Canvas);
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=Code;
    if Shift then E.Modifiers:=[gemShift];
    Edit.HandleEvent(E);
  end;
begin
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  Edit:=TGuiEdit.Create;
  Memo:=TGuiMemo.Create;
  try
    Canvas.FontRenderer:=AFont;
    Accent:=String(UTF8Encode(UnicodeString('a'+#$0301)));
    Emoji:=String(UTF8Encode(UnicodeString(#$D83D#$DC69#$200D#$D83D#$DCBB)));
    S:='A'+Accent+Emoji+'Z';
    Edit.Text:=S;
    Edit.Bounds:=GuiRect(10,20,350,40);
    SetStyleTextOffset(Edit,GuiPoint(2,1));
    Edit.TextOffset:=GuiPoint(1,0);
    Edit.CaretIndex:=0;
    Key($4000004F);
    Key($4000004F);
    Check(Edit.CaretIndex=1+Length(Accent),'SDL edit advances over a complete combining grapheme');
    Key($4000004F);
    Check(Edit.CaretIndex=Length(S)-1,'SDL edit advances over a complete joined emoji');
    Key(8);
    Check(Edit.Text='A'+Accent+'Z','SDL edit deletes the whole joined emoji');
    Edit.Undo;
    Check(Edit.Text=S,'Unicode deletion undo restores original native String');
    for I:=0 to 1 do
    begin
      if I=0 then Edit.SetSelection(1,Length(S)-1) else Edit.SetSelection(Length(S)-1,1);
      Key($4000004F);
      Check((Edit.CaretIndex=Length(S)-1) AND NOT Edit.HasSelection,
        'Right arrow collapses either selection direction to its end');
      if I=0 then Edit.SetSelection(1,Length(S)-1) else Edit.SetSelection(Length(S)-1,1);
      Key($40000050);
      Check((Edit.CaretIndex=1) AND NOT Edit.HasSelection,
        'Left arrow collapses either selection direction to its start');
    end;
    Edit.CaretIndex:=1+Length(Accent);
    Width:=Canvas.MeasureText(S).Width;
    for I:=0 to 2 do
    begin
      Edit.TextHorizontalAlign:=TGuiHorizontalTextAlign(I);
      R:=Edit.TextInputRect(Canvas);
      X:=0;
      if I=1 then X:=Max(0,(334-Width)/2);
      if I=2 then X:=Max(0,334-Width);
      Check(Abs(R.Left-(18+3+X+Canvas.MeasureText('A'+Accent).Width))<0.01,
        'Unicode caret shares left/center/right text alignment and style offsets');
    end;
    Edit.TextHorizontalAlign:=ghtaLeft;
    Edit.PasswordChar:='*';
    Edit.CaretIndex:=Length(S);
    R:=Edit.TextInputRect(Canvas);
    Check(Abs(R.Left-(18+3+Canvas.MeasureText('****').Width))<0.01,
      'Password caret uses one mask character per grapheme');
    Edit.PasswordChar:=#0;
    Edit.Text:='A'+#13#10+String(UTF8Encode(UnicodeString(#$0085#$2028#$2029)))+'B';
    Check(Edit.Text='AB','Single-line normalization needs no direction-analysis dependency');
    Edit.Text:='AZ';
    Edit.SetSelection(1,1);
    E:=Default(TGuiEvent);
    E.Kind:=gekTextEditing;
    E.Text:=UTF8String(Emoji+'x');
    E.HasCompositionRange:=True;
    E.CompositionStart:=3;
    E.CompositionLength:=1;
    Edit.HandleEvent(E);
    Check((Edit.CompositionCursor=Length(Emoji)) AND (Edit.CompositionSelectionLength=1),
      'SDL composition scalar ranges still map to native Unicode offsets');
    Key(27);
    Check(Edit.CompositionText='','Escape still cancels Unicode composition');
    Memo.Bounds:=GuiRect(10,20,110,80);
    Memo.WordWrap:=True;
    Memo.Text:=S+' '+S+#10+Accent;
    Memo.PrepareTextLayout(Canvas);
    Rows:=Memo.VisualLineCount;
    Check(Rows>2,'Ordinary Unicode memo wraps into visual rows');
    Memo.SelectAll;
    Check(Memo.SelectedText=S+' '+S+#10+Accent,'Wrapped memo selection preserves source text');
    E:=Default(TGuiEvent);
    E.Kind:=gekKeyDown;
    E.KeyCode:=127;
    Memo.HandleEvent(E);
    Memo.Undo;
    Memo.PrepareTextLayout(Canvas);
    Check((Memo.Text=S+' '+S+#10+Accent) AND (Memo.VisualLineCount=Rows),
      'Ordinary Unicode memo undo restores text and wrapped rows');
  finally
    Memo.Free;
    Edit.Free;
    Canvas.Free;
  end;
end;

procedure TestCompositionReplacement(ARenderer: PSDL_Renderer; AFont: TGuiSDLTTFFontRenderer);
var Canvas: TGuiSDL3Canvas;
Edit: TGuiEdit;
E: TGuiEvent;
  SavedX,SavedY: Single;
  PreviewHash,ExpectedHash: UInt64;
  InputRect: TGuiRect;
  I: Integer;
  SelectedUnicode: String;
  ExpectedX: TGuiFloat;
  procedure Compose;
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekTextEditing;
    E.Text:='xy';
    E.HasCompositionRange:=True;
    E.CompositionStart:=1;
    E.CompositionLength:=0;
    Edit.HandleEvent(E);
  end;
  function RenderTextHash: UInt64;
  var Surface: PSDL_Surface;
  X,Y: Integer;
  R,G,B,A: Byte;
  begin
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Edit.Paint(Canvas);
    Surface:=SDL_RenderReadPixels(ARenderer,nil);
    if NOT Assigned(Surface) then raise Exception.Create('Read composition preview pixels');
    try
      Result:=0;
      { Text band only: exclude the composition underline at the bottom. }
      for Y:=25 to 51 do for X:=18 to 351 do
      begin
        if NOT SDL_ReadSurfacePixel(Surface,X,Y,@R,@G,@B,@A) then raise Exception.Create('Read preview pixel');
        Result:=((Result SHL 5) OR (Result SHR 59)) XOR UInt64(R+G*256+B*65536);
      end;
    finally
      SDL_DestroySurface(Surface);
    end;
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  Edit:=TGuiEdit.Create;
  try
    Canvas.FontRenderer:=AFont;
    Edit.Bounds:=GuiRect(10,20,350,40);
    Edit.TextOffset:=GuiPoint(0,0);
    SetStyleTextOffset(Edit,GuiPoint(0,0));
    ExpectedX:=Canvas.MeasureText('Ax').Width;
    Edit.Text:='AxyZ';
    ExpectedHash:=RenderTextHash;
    for I:=0 to 1 do
    begin
      Edit.Text:='AoriginalZ';
      if I=0 then Edit.SetSelection(1,9) else Edit.SetSelection(9,1);
      Compose;
      InputRect:=Edit.TextInputRect(Canvas);
      PreviewHash:=RenderTextHash;
      Check((Edit.Text='AoriginalZ') AND (Edit.SelectedText='original'),
        'Composition preview preserves committed source and original selection');
      Check(Abs(InputRect.Left-(18+ExpectedX))<0.01,
        'Composition caret is relative to replacement start for either selection direction');
      Check(PreviewHash=ExpectedHash,'Composition preview pixels match replacement text, not insertion beside selection');
      E:=Default(TGuiEvent);
      E.Kind:=gekKeyDown;
      E.KeyCode:=27;
      Edit.HandleEvent(E);
      Check((Edit.Text='AoriginalZ') AND (Edit.SelectedText='original') AND (Edit.CompositionText=''),
        'Cancelling replacement preview preserves source and selection');
      Compose;
      E:=Default(TGuiEvent);
      E.Kind:=gekTextInput;
      E.Text:='xy';
      Edit.HandleEvent(E);
      Check((Edit.Text='AxyZ') AND NOT Edit.HasSelection,'Composition commit replaces selection exactly once');
      Edit.Undo;
      Check((Edit.Text='AoriginalZ') AND (Edit.SelectedText='original'),
        'One undo restores selected source without a preview history entry');
    end;
    SelectedUnicode:=String(UTF8Encode(UnicodeString(WideChar($00E4))+WideChar($00E9)));
    Edit.Text:='A'+SelectedUnicode+'Z';
    Edit.SetSelection(1,1+Length(SelectedUnicode));
    Compose;
    PreviewHash:=RenderTextHash;
    Check((PreviewHash=ExpectedHash) AND (Edit.SelectedText=SelectedUnicode),
      'Replacement preview removes selected Unicode text using native String offsets');
  finally
    Edit.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestMemoComposition(ARenderer: PSDL_Renderer; AFont: TGuiSDLTTFFontRenderer);
var Canvas: TGuiSDL3Canvas;
Memo,Reference: TGuiMemo;
E: TGuiEvent;
  SavedX,SavedY: Single;
  Original,Composition,Preview: String;
  D: TGuiDecodedText;
  BeforeRect,AfterRect: TGuiRect;
  OriginalRows,OriginalCaret,I: Integer;
  function TextHash(Control: TGuiMemo): UInt64;
  var Surface: PSDL_Surface;
  X,Y: Integer;
  R,G,B,A: Byte;
  begin
    SDL_SetRenderDrawColor(ARenderer,0,0,0,255);
    SDL_RenderClear(ARenderer);
    Control.Paint(Canvas);
    Surface:=SDL_RenderReadPixels(ARenderer,nil);
    if NOT Assigned(Surface) then raise Exception.Create('Read memo composition pixels');
    try
      Result:=0;
      for Y:=26 to 73 do if ((Y-26) MOD 24>=3) AND ((Y-26) MOD 24<=20) then
        for X:=16 to 100 do
        begin
          if NOT SDL_ReadSurfacePixel(Surface,X,Y,@R,@G,@B,@A) then raise Exception.Create('Read memo preview band');
          Result:=((Result SHL 5) OR (Result SHR 59)) XOR UInt64(R+G*256+B*65536);
        end;
    finally
      SDL_DestroySurface(Surface);
    end;
  end;
  procedure Compose(AStart: Integer);
  begin
    E:=Default(TGuiEvent);
    E.Kind:=gekTextEditing;
    E.Text:=UTF8String(Composition);
    E.HasCompositionRange:=True;
    E.CompositionStart:=AStart;
    E.CompositionLength:=1;
    Memo.HandleEvent(E);
    Memo.PrepareTextLayout(Canvas);
  end;
begin
  SDL_GetRenderScale(ARenderer,@SavedX,@SavedY);
  SDL_SetRenderScale(ARenderer,1,1);
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  Memo:=TGuiMemo.Create;
  Reference:=TGuiMemo.Create;
  try
    Canvas.FontRenderer:=AFont;
    Memo.Bounds:=GuiRect(10,20,110,60);
    Reference.Bounds:=Memo.Bounds;
    Memo.WordWrap:=True;
    Reference.WordWrap:=True;
    SetStyleTextOffset(Memo,GuiPoint(0,0));
    SetStyleTextOffset(Reference,GuiPoint(0,0));
    Original:='AoriginalZ'+#10+'tail';
    Composition:='xy '+String(UTF8Encode(UnicodeString(WideChar($00FC))+WideChar($00DF)))+
      ' 123 abcdefghijklmnop 456';
    Preview:='A'+Composition+'Z'+#10+'tail';
    Memo.Text:=Original;
    Memo.SetSelection(1,9);
    Memo.PrepareTextLayout(Canvas);
    OriginalRows:=Memo.VisualLineCount;
    OriginalCaret:=Memo.CaretIndex;
    Reference.Text:=Preview;
    Reference.PrepareTextLayout(Canvas);
    Compose(0);
    BeforeRect:=Memo.TextInputRect(Canvas);
    Check((Memo.Text=Original) AND (Memo.SelectedText='original') AND
      (Memo.VisualLineCount=Reference.VisualLineCount) AND (Memo.VisualLineCount>OriginalRows),
      'Memo composition owns wrapped display rows without modifying committed selection');
    Check(TextHash(Memo)=TextHash(Reference),'Memo composition text pixels match independently committed replacement layout');
    D:=GuiDecodeText(Composition);
    Compose(Length(D.Scalars));
    AfterRect:=Memo.TextInputRect(Canvas);
    Check((Memo.ScrollY>0) AND (AfterRect.Top>=BeforeRect.Top) AND (AfterRect.Width=1),
      'Memo composition cursor scrolls through wrapped preview rows and updates input area');
    Reference.ScrollY:=Memo.ScrollY;
    Check(TextHash(Memo)=TextHash(Reference),'Scrolled composition preview retains text placement');
    for I:=0 to 2 do
    begin
      E:=Default(TGuiEvent);
      E.Kind:=gekKeyDown;
      case I of 0:E.KeyCode:=8;
      1:E.KeyCode:=13;
      2:E.KeyCode:=$40000050;
      end;
      Memo.HandleEvent(E);
      if (Memo.Text<>Original) OR (Memo.CaretIndex<>OriginalCaret) OR
        (Memo.CompositionText<>Composition) then raise Exception.Create('IME key mutated committed memo');
    end;
    Check(True,'Composition editing keys do not delete, move, or insert into committed memo');
    E.KeyCode:=27;
    Memo.HandleEvent(E);
    Memo.PrepareTextLayout(Canvas);
    BeforeRect:=Memo.TextInputRect(Canvas);
    Check((Memo.CompositionText='') AND (Memo.Text=Original) AND
      (Memo.SelectedText='original') AND (Memo.VisualLineCount=OriginalRows) AND (Memo.ScrollY=0),
      'Cancelling memo composition restores committed rows and caret viewport');
    Compose(0);
    E:=Default(TGuiEvent);
    E.Kind:=gekTextInput;
    E.Text:=UTF8String(Composition);
    Memo.HandleEvent(E);
    Memo.PrepareTextLayout(Canvas);
    Check((Memo.Text=Preview) AND (Memo.CompositionText=''),'Memo composition commit replaces source selection once');
    Memo.Undo;
    Memo.PrepareTextLayout(Canvas);
    Check((Memo.Text=Original) AND (Memo.SelectedText='original') AND (Memo.VisualLineCount=OriginalRows),
      'Memo preview does not add undo entries or corrupt committed row cache');
  finally
    Reference.Free;
    Memo.Free;
    Canvas.Free;
    SDL_SetRenderScale(ARenderer,SavedX,SavedY);
  end;
end;

procedure TestCompositionLifecycle(ARenderer: PSDL_Renderer; AFont: TGuiSDLTTFFontRenderer);
var Canvas: TGuiSDL3Canvas;
Context: TGuiContext;
Edit: TGuiEdit;
Other: TGuiButton;
  E: TGuiEvent;
  Revision,FocusRevision: UInt64;
  I: Integer;
  procedure Compose;
  begin
    Edit.ReadOnly:=False;
    Edit.Text:='original';
    Edit.SetSelection(0,8);
    E:=Default(TGuiEvent);
    E.Kind:=gekTextEditing;
    E.Text:='preview';
    Edit.HandleEvent(E);
    Revision:=Edit.CompositionCancellationRevision;
  end;
begin
  Canvas:=TGuiSDL3Canvas.Create(ARenderer);
  Context:=TGuiContext.Create;
  try
    Canvas.FontRenderer:=AFont;
    Context.Resize(400,200);
    Edit:=TGuiEdit.Create;
    Edit.Bounds:=GuiRect(0,0,200,40);
    Context.Root.Add(Edit);
    Other:=TGuiButton.Create;
    Other.Bounds:=GuiRect(0,60,200,40);
    Context.Root.Add(Other);
    Context.SetFocus(Edit);
    for I:=0 to 5 do
    begin
      Compose;
      case I of
        0:Edit.ReadOnly:=True;
        1:Edit.CaretIndex:=2;
        2:Edit.SetSelection(1,3);
        3:Edit.Text:='replacement';
        4:
        begin
          E:=Default(TGuiEvent);
          E.Kind:=gekKeyDown;
          E.KeyCode:=27;
          Edit.HandleEvent(E);
        end;
        5:
        begin
          Edit.PrepareTextLayout(Canvas);
          E:=Default(TGuiEvent);
          E.Kind:=gekMouseDown;
          E.Button:=gmbLeft;
          E.Position:=GuiPoint(20,20);
          Edit.HandleEvent(E);
          end;
      end;
      Check((Edit.CompositionText='') AND (Edit.CompositionCancellationRevision=Revision+1),
        'Editor state/pointer/escape transition records composition cancellation');
      Edit.CancelComposition;
      Check(Edit.CompositionCancellationRevision=Revision+1,'Repeated composition cancellation is idempotent');
    end;
    Compose;
    FocusRevision:=Context.FocusRevision;
    Context.SetFocus(Other);
    Context.SetFocus(Edit);
    Check((Edit.CompositionText='') AND (Context.FocusRevision=FocusRevision+2),
      'Away-and-back focus changes remain observable before the next host frame');
    Compose;
    FocusRevision:=Context.FocusRevision;
    Edit.Parent.Remove(Edit);
    Check((Context.FocusedControl=nil) AND (Context.FocusRevision>FocusRevision) AND
      (Edit.CompositionText=''),'Detachment cancels focused composition without application callbacks');
    Context.Root.Add(Edit);
    Context.SetFocus(Edit);
    Compose;
    E:=Default(TGuiEvent);
    E.Kind:=gekTextInput;
    E.Text:='committed';
    Edit.HandleEvent(E);
    Check((Edit.Text='committed') AND (Edit.CompositionCancellationRevision=Revision),
      'Normal composition commit is not reported as cancellation');
  finally
    Context.Free;
    Canvas.Free;
  end;
end;

procedure TestTextPlacement(ARenderer: PSDL_Renderer; AFont: TGuiSDLTTFFontRenderer);
var
  P1, P2: TGuiPoint;
  Size: TGuiSize;
  Surface: PSDL_Surface;
  C: TGuiColor;
  X, Y, MinY, MaxY: Integer;
begin
  Size:=GuiSize(17, AFont.MeasureLineHeight);
  P1:=AFont.TextOrigin(Size, GuiRect(10, 10, 80, 34), ghtaCenter, gvtaCenter);
  P2:=AFont.TextOrigin(Size, GuiRect(11, 11, 80, 34), ghtaCenter, gvtaCenter);
  Check((P2.X - P1.X = 1) AND (P2.Y - P1.Y = 1), 'Centered text translates exactly one pixel at odd widths');
  P2:=AFont.TextOrigin(AFont.MeasureText('gyp'), GuiRect(10, 10, 80, 34), ghtaCenter, gvtaCenter);
  Check(P2.Y = P1.Y, 'Descenders do not change the shared text baseline');
  SDL_SetRenderScale(ARenderer, 1, 1);
  SDL_SetRenderDrawColor(ARenderer, 0, 0, 0, 255);
  SDL_RenderClear(ARenderer);
  AFont.DrawText(ARenderer, 'H', GuiRect(10, 10, 80, 34), GuiColor(255, 255, 255), ghtaCenter, gvtaCenter);
  Surface:=SDL_RenderReadPixels(ARenderer, nil);
  Check(Assigned(Surface), 'Read text alignment pixels');
  try
    MinY:=44;
    MaxY:=-1;
    for Y:=10 to 43 do
      for X:=10 to 89 do
      begin
        if NOT SDL_ReadSurfacePixel(Surface, X, Y, @C.R, @C.G, @C.B, @C.A) then
          raise Exception.Create('Cannot read text pixel');
        if C.R > 32 then
        begin
          if Y < MinY then MinY:=Y;
          if Y > MaxY then MaxY:=Y;
        end;
      end;
    Check((MaxY >= MinY) AND (Abs((MinY - 10) - (43 - MaxY)) <= 1), 'Rendered cap-height ink is vertically centered within one pixel');
  finally
    SDL_DestroySurface(Surface);
  end;
  SDL_SetRenderScale(ARenderer, 2, 2);
end;

procedure Run;
var
  Window: PSDL_Window;
  Renderer: PSDL_Renderer;
  Host: TGuiSDL3Host;
  Font, BadFont, MemoryFont: TGuiSDLTTFFontRenderer;
  FontBytes: Pointer;
  FontByteCount: NativeUInt;
  FontFileUtf8: UTF8String;
  InvalidFontData: array[0..7] of Byte;
  Fonts: TGuiSDLTTFFontCollection;
  Button: TGuiButton;
  Edit: TGuiEdit;
  Spin: TGuiSpinEdit;
  Event: TSDL_Event;
  TranslatedEvent: TGuiEvent;
  Viewport: TSDL_Rect;
  NativeInputArea: TSDL_Rect;
  NativeCursor: Integer;
  GuiInputArea: TGuiRect;
  InputX,InputY: Single;
  Desc: TSDL_VirtualJoystickDesc;
  GamepadID: TSDL_JoystickID;
  Size1, Size2: TGuiSize;
  MetricsKey: String;
  Failed: Boolean;
  I: Integer;
begin
  Check(SDL_Init(SDL_INIT_VIDEO OR SDL_INIT_GAMEPAD), 'SDL initialization');
  Window:=nil;
  Renderer:=nil;
  Host:=nil;
  Font:=nil;
  MemoryFont:=nil;
  FontBytes:=nil;
  Fonts:=nil;
  try
    Window:=SDL_CreateWindow('GUI tests', 400, 200, SDL_WINDOW_HIDDEN);
    Check(Assigned(Window), 'Hidden test window');
    Renderer:=SDL_CreateRenderer(Window, 'software');
    Check(Assigned(Renderer), 'Software renderer');
    TestStylePixels(Renderer);
    TestActivityAndSwitchPixels(Renderer);
    TestPageIndicatorPixels(Renderer);
    TestOptionButtonBounds(Renderer);
    TestMarqueePixels(Renderer);
    TestDeterminateProgressPixels(Renderer);
    TestSpeedButtonPixels(Renderer);
    TestToolbarPixels(Renderer);
    TestTabButtonPixels(Renderer);
    TestRadioPixels(Renderer);
    TestRadioGroupPixels(Renderer);
    TestCheckListPixels(Renderer);
    TestSwitchListPixels(Renderer);
    TestDelayPixels(Renderer);
    TestRangePixels(Renderer);
    TestWheelPixels(Renderer);
    TestSpinPixels(Renderer);
    TestComboStatePixels(Renderer);
    TestTabFoundationPixels(Renderer);
    TestNarrowTabPixels(Renderer);
    TestButtonPressPixels(Renderer);
    TestSliderPreviewPixels(Renderer);
    TestSliderBoundsPixels(Renderer);
    TestRangeBoundsPixels(Renderer);
    TestSpinBoundsPixels(Renderer);
    TestComboBoundsPixels(Renderer);
    TestRoundButtonPixels(Renderer);
    TestKnobPixels(Renderer);
    SDL_SetRenderScale(Renderer, 2, 2);
    Host:=TGuiSDL3Host.Create(Renderer);
    SDL_GetRenderViewport(Renderer, @Viewport);
    Writeln('Viewport ', Viewport.w, 'x', Viewport.h, '; GUI ', Host.Context.Root.Bounds.Width:0:0, 'x', Host.Context.Root.Bounds.Height:0:0);
    Check(Host.Context.Root.Bounds.Width = 200, 'Host size accounts for render scale');
    Button:=TGuiButton.Create;
    Button.Bounds:=GuiRect(50, 10, 40, 30);
    Host.Context.Root.Add(Button);
    FillChar(Event, SizeOf(Event), 0);
    Event.type_:=SDL_EVENT_MOUSE_MOTION;
    Event.motion.windowID:=SDL_GetWindowID(Window);
    Event.motion.x:=120;
    Event.motion.y:=40;
    Host.ProcessEvent(Event);
    Check(Host.Context.HoveredControl = Button, 'Mouse input converts to renderer coordinates');
    TestTouchHost(Host,Window,Button);
    Event.motion.windowID:=SDL_GetWindowID(Window) + 1;
    Event.motion.x:=0;
    Host.ProcessEvent(Event);
    Check(Host.Context.HoveredControl = Button, 'Events from another window are ignored');
    FillChar(Desc, SizeOf(Desc), 0);
    Desc.version:=SizeOf(Desc);
    Desc.type_:=Ord(SDL_JOYSTICK_TYPE_GAMEPAD);
    Desc.naxes:=2;
    Desc.nbuttons:=15;
    Desc.axis_mask:=3;
    Desc.button_mask:=$7FFF;
    Desc.name:='GUI virtual controller';
    GamepadID:=SDL_AttachVirtualJoystick(@Desc);
    Check(GamepadID <> 0, 'Virtual gamepad attachment');
    try
      FillChar(Event, SizeOf(Event), 0);
      Event.type_:=SDL_EVENT_GAMEPAD_ADDED;
      Event.gdevice.which:=GamepadID;
      Host.ProcessEvent(Event);
      Check(Assigned(SDL_GetGamepadFromID(GamepadID)), 'Host opens added gamepads');
      Event.type_:=SDL_EVENT_GAMEPAD_REMOVED;
      Host.ProcessEvent(Event);
      Check(NOT Assigned(SDL_GetGamepadFromID(GamepadID)), 'Host closes removed gamepads');
    finally
      SDL_DetachVirtualJoystick(GamepadID);
    end;
    Font:=TGuiSDLTTFFontRenderer.Create(GuiDefaultFontFile, 16);
    FontFileUtf8:=UTF8String(GuiDefaultFontFile);
    FontBytes:=SDL_LoadFile(PAnsiChar(FontFileUtf8),@FontByteCount);
    Check(Assigned(FontBytes) AND (FontByteCount>0),'Load font bytes for memory constructor');
    MemoryFont:=TGuiSDLTTFFontRenderer.CreateFromMemory(FontBytes,FontByteCount,16);
    SDL_free(FontBytes);
    FontBytes:=nil;
    Check(MemoryFont.MeasureText('embedded').Width>0,'Copied memory font survives source release');
    MemoryFont.Free;
    MemoryFont:=nil;
    FillChar(InvalidFontData,SizeOf(InvalidFontData),0);
    Failed:=False;
    try
      BadFont:=TGuiSDLTTFFontRenderer.CreateFromMemory(@InvalidFontData[0],SizeOf(InvalidFontData),16);
      BadFont.Free;
    except
      on E: Exception do Failed:=True;
    end;
    Check(Failed,'Invalid memory font fails without hiding live font');
    TestTextPlacement(Renderer, Font);
    Failed:=False;
    try
      BadFont:=TGuiSDLTTFFontRenderer.Create('missing-test-font.ttf', 16);
      BadFont.Free;
    except
      on E: Exception do Failed:=True;
    end;
    Check(Failed AND (TTF_WasInit > 0) AND (Font.MeasureText('alive').Width > 0), 'Failed font construction preserves live fonts');
    Host.FontRenderer:=Font;
    for I:=1 to 3 do
      Font.DrawText(Renderer, 'cache test', GuiRect(0, 0, 100, 30), GuiColor(255, 255, 255), ghtaLeft, gvtaCenter);
    Check(SDL_RenderPresent(Renderer), 'Repeated cached text renders');
    Check(Font.CacheHits = 2, 'Unchanged text reuses cached rasterization and texture');
    TestUnicodeEditing(Renderer,Font);
    TestCompositionReplacement(Renderer,Font);
    TestMemoComposition(Renderer,Font);
    TestCompositionLifecycle(Renderer,Font);
    Font.ClearCache;
    Fonts:=TGuiSDLTTFFontCollection.Create;
    Fonts.AddFont(GuiFontSpec('small', GuiDefaultFontFile, 10));
    Fonts.AddFont(GuiFontSpec('large', GuiDefaultFontFile, 24));
    Host.Canvas.Fonts:=Fonts;
    Host.Canvas.FontName:='small';
    Size1:=Host.Canvas.MeasureText('Font roles');
    Host.Canvas.FontName:='large';
    Size2:=Host.Canvas.MeasureText('Font roles');
    Check(Size2.Width > Size1.Width, 'Named fonts affect text measurement');
    Host.Canvas.FontName:='';
    Fonts.DefaultFont:=Fonts.FindFont('small');
    MetricsKey:=Host.Canvas.TextMetricsKey;
    Fonts.DefaultFont:=Fonts.FindFont('large');
    Check(MetricsKey <> Host.Canvas.TextMetricsKey, 'Default font replacement invalidates edit metrics key');
    MetricsKey:=Host.Canvas.TextMetricsKey;
    Fonts.DefaultFont.ClearCache;
    Check(MetricsKey <> Host.Canvas.TextMetricsKey, 'Font cache reset invalidates text metrics key');
    Edit:=TGuiEdit.Create;
    Edit.Bounds:=GuiRect(0, 50, 100, 30);
    Host.Context.Root.Add(Edit);
    Host.Context.SetFocus(Edit);
    FillChar(Event, SizeOf(Event), 0);
    Event.type_:=SDL_EVENT_TEXT_EDITING;
    Event.edit.windowID:=SDL_GetWindowID(Window);
    Event.edit.text:='compose';
    Event.edit.start:=2;
    Event.edit.length:=1;
    Host.ProcessEvent(Event);
    Check((Edit.Text = '') AND (Edit.CompositionText = 'compose'), 'IME composition does not commit prematurely');
    Check((Edit.CompositionCursor=2) AND (Edit.CompositionSelectionLength=1),
      'SDL host preserves text-editing cursor and selection range');
    Check(GuiEventFromSDL3(Event,TranslatedEvent) AND TranslatedEvent.HasCompositionRange,
      'SDL editing event exposes explicit range metadata');
    Event.type_:=SDL_EVENT_KEY_UP;
    Check(GuiEventFromSDL3(Event,TranslatedEvent) AND NOT TranslatedEvent.HasCompositionRange AND
      (TranslatedEvent.CompositionStart=-1) AND (TranslatedEvent.CompositionLength=-1),
      'Reused GUI events clear composition-only metadata');
    Event.type_:=SDL_EVENT_TEXT_INPUT;
    Event.text.text:='committed';
    Host.ProcessEvent(Event);
    Check((Edit.Text = 'committed') AND (Edit.CompositionText = ''), 'IME commit inserts once and clears composition');
    Host.Render;
    Check(SDL_GetTextInputArea(Window,@NativeInputArea,@NativeCursor),'Read SDL text input area');
    GuiInputArea:=Edit.TextInputRect(Host.Canvas);
    Check(SDL_RenderCoordinatesToWindow(Renderer,GuiInputArea.Left,GuiInputArea.Top,@InputX,@InputY),
      'Convert editor caret from renderer to native window coordinates');
    Check((NativeInputArea.x=Floor(InputX)) AND (NativeInputArea.y=Floor(InputY)) AND
      (NativeInputArea.w>0) AND (NativeInputArea.w<=3) AND (NativeCursor=0),
      'SDL host synchronizes scaled caret rectangle instead of full editor rectangle');
    Spin:=TGuiSpinEdit.Create;
    Spin.Bounds:=GuiRect(0,100,180,32);
    Spin.Value:=12;
    Host.Context.Root.Add(Spin);
    Host.Context.SetFocus(Spin);
    Host.Render;
    Check(SDL_TextInputActive(Window),'Spin editor activates native SDL text input');
    Spin.SelectAll;
    Event:=Default(TSDL_Event);
    Event.type_:=SDL_EVENT_TEXT_INPUT;
    Event.text.windowID:=SDL_GetWindowID(Window);
    Event.text.text:='35';
    Host.ProcessEvent(Event);
    Check((Spin.Text='35') AND (Spin.Value=12),'SDL text input edits spin buffer without premature numeric commit');
    Event:=Default(TSDL_Event);
    Event.type_:=SDL_EVENT_KEY_DOWN;
    Event.key.windowID:=SDL_GetWindowID(Window);
    Event.key.key:=13;
    Host.ProcessEvent(Event);
    Check((Spin.Value=35) AND NOT Spin.Editing,'SDL Enter commits spin input');
    Spin.Text:='123456789012345678901234567890';
    Spin.CaretIndex:=Length(Spin.Text);
    Host.Render;
    GuiInputArea:=Spin.TextInputRect(Host.Canvas);
    Check((GuiInputArea.Left>=Spin.Bounds.Left) AND (GuiInputArea.Left+GuiInputArea.Width<=Spin.Bounds.Left+Spin.Bounds.Width-27),
      'Long spin input keeps native caret geometry outside arrow-button lane');
    Event.key.key:=27;
    Host.ProcessEvent(Event);
    Check((Spin.Value=35) AND (Spin.Text='35'),'SDL Escape restores spin committed text');
    Spin.Editable:=False;
    Host.Render;
    Check(NOT SDL_TextInputActive(Window),'Noneditable spin disables native text input');
    Event.key.key:=$40000052;
    Host.ProcessEvent(Event);
    Check(Spin.Value=36,'Noneditable spin retains SDL keyboard stepping');
    Spin.Editable:=True;
    Host.Render;
    Check(SDL_TextInputActive(Window),'Re-enabling spin editing resumes native input');
    TestSpinNativeModification(Host,Window,Spin);
    TestComboNativeKeyboard(Host,Window);
    Host.Context.SetFocus(Edit);
    Edit.ReadOnly:=True;
    Host.Render;
    Check(NOT SDL_TextInputActive(Window),'Read-only transition stops native text input');
    Edit.ReadOnly:=False;
    Host.Render;
    Check(SDL_TextInputActive(Window),'Editable transition resumes native text input');
    Host.Context.SetFocus(Button);
    Host.Render;
    Check(NOT SDL_TextInputActive(Window),'Non-editor focus stops native text input');
    Host.Context.SetFocus(Edit);
    Host.Render;
    Check(SDL_TextInputActive(Window),'Editor focus restarts native text input');
    FillChar(Event, SizeOf(Event), 0);
    Event.type_:=SDL_EVENT_WINDOW_FOCUS_LOST;
    Event.window.windowID:=SDL_GetWindowID(Window);
    Host.ProcessEvent(Event);
    Check(Host.Context.FocusedControl = nil, 'Window focus loss cancels GUI input');
    Check(NOT SDL_TextInputActive(Window),'Window focus loss stops native text input');
  finally
    Host.Free;
    Fonts.Free;
    MemoryFont.Free;
    Font.Free;
    SDL_free(FontBytes);
    Check(TTF_WasInit=0,'Font construction and destruction balance SDL_ttf initialization');
    if Assigned(Renderer) then SDL_DestroyRenderer(Renderer);
    if Assigned(Window) then SDL_DestroyWindow(Window);
    SDL_Quit;
  end;
end;

begin
  try
    Run;
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.Message);
      Halt(1);
    end;
  end;
end.
