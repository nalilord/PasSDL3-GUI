unit PasSDL3.GUI.Renderer.SDL3;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SDL3,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Fonts.SDLTTF;

type
  TGuiSDL3Canvas = class(TGuiCanvas)
  private
    FRenderer: PSDL_Renderer;
    FFontRenderer: TGuiSDLTTFFontRenderer;
    FFonts: TGuiSDLTTFFontCollection;
    function ActiveFont: TGuiSDLTTFFontRenderer;
  private
    FClipRects: array of TSDL_Rect;
    FClipEnabled: array of Boolean;
    FClipCount: Integer;
    function ToSDLRect(const ARect: TGuiRect): TSDL_FRect;
    procedure ApplyColor(const AColor: TGuiColor);
  public
    constructor Create(ARenderer: PSDL_Renderer);
    procedure FillRect(const ARect: TGuiRect; const AColor: TGuiColor); override;
    procedure DrawBorder(const ARect: TGuiRect; ABorderWidth: TGuiFloat; const AColor: TGuiColor); override;
    procedure DrawLine(const AStart, AEnd: TGuiPoint; AWidth: TGuiFloat; const AColor: TGuiColor); override;
    procedure DrawImage(ATexture: TGuiTexture; const ARect: TGuiRect); override;
    procedure DrawImagePart(ATexture: TGuiTexture; const ASourceRect, ADestRect: TGuiRect); override;
    procedure DrawText(const AText: String; const ARect: TGuiRect; const AColor: TGuiColor; AHorizontalAlign: TGuiHorizontalTextAlign = ghtaLeft;
      AVerticalAlign: TGuiVerticalTextAlign = gvtaCenter); override;
    function MeasureText(const AText: String): TGuiSize; override;
    function TextMetricsKey: String; override;
    procedure PushClipRect(const ARect: TGuiRect); override;
    procedure PopClipRect; override;
    property Renderer: PSDL_Renderer read FRenderer;
    property FontRenderer: TGuiSDLTTFFontRenderer read FFontRenderer write FFontRenderer;
    property Fonts: TGuiSDLTTFFontCollection read FFonts write FFonts;
  end;

implementation

uses SysUtils;

function TGuiSDL3Canvas.TextMetricsKey: String;
var Font: TGuiSDLTTFFontRenderer;
begin
  Font:=ActiveFont;
  Result:=FontName;
  if Assigned(Font) then
    Result:=Result + ':' + IntToHex(NativeUInt(Font), SizeOf(Pointer) * 2) + ':' + UIntToStr(Font.MetricsRevision);
end;

function TGuiSDL3Canvas.ActiveFont: TGuiSDLTTFFontRenderer;
begin
  Result:=nil;
  if Assigned(FFonts) then
  begin
    Result:=FFonts.FindFont(FontName);
    if NOT Assigned(Result) then Result:=FFonts.DefaultFont;
  end;
  if NOT Assigned(Result) then Result:=FFontRenderer;
end;

constructor TGuiSDL3Canvas.Create(ARenderer: PSDL_Renderer);
begin
  inherited Create;
  FRenderer:=ARenderer;
  FClipCount:=0;
end;

function TGuiSDL3Canvas.ToSDLRect(const ARect: TGuiRect): TSDL_FRect;
begin
  Result.x:=ARect.Left;
  Result.y:=ARect.Top;
  Result.w:=ARect.Width;
  Result.h:=ARect.Height;
end;

procedure TGuiSDL3Canvas.ApplyColor(const AColor: TGuiColor);
begin
  if AColor.A < 255 then
    SDL_SetRenderDrawBlendMode(FRenderer, SDL_BLENDMODE_BLEND)
  else
    SDL_SetRenderDrawBlendMode(FRenderer, SDL_BLENDMODE_NONE);

  SDL_SetRenderDrawColor(FRenderer, AColor.R, AColor.G, AColor.B, AColor.A);
end;

procedure TGuiSDL3Canvas.FillRect(const ARect: TGuiRect; const AColor: TGuiColor);
var
  Rect: TSDL_FRect;
begin
  Rect:=ToSDLRect(ARect);
  ApplyColor(AColor);
  SDL_RenderFillRect(FRenderer, @Rect);
end;

procedure TGuiSDL3Canvas.DrawBorder(const ARect: TGuiRect; ABorderWidth: TGuiFloat; const AColor: TGuiColor);
var
  Rect: TSDL_FRect;
begin
  if ABorderWidth <= 0 then
    Exit;

  ApplyColor(AColor);

  Rect:=ToSDLRect(GuiRect(ARect.Left, ARect.Top, ARect.Width, ABorderWidth));
  SDL_RenderFillRect(FRenderer, @Rect);

  Rect:=ToSDLRect(GuiRect(ARect.Left, ARect.Top + ARect.Height - ABorderWidth, ARect.Width, ABorderWidth));
  SDL_RenderFillRect(FRenderer, @Rect);

  Rect:=ToSDLRect(GuiRect(ARect.Left, ARect.Top, ABorderWidth, ARect.Height));
  SDL_RenderFillRect(FRenderer, @Rect);

  Rect:=ToSDLRect(GuiRect(ARect.Left + ARect.Width - ABorderWidth, ARect.Top, ABorderWidth, ARect.Height));
  SDL_RenderFillRect(FRenderer, @Rect);
end;

procedure TGuiSDL3Canvas.DrawLine(const AStart, AEnd: TGuiPoint; AWidth: TGuiFloat; const AColor: TGuiColor);
const
  Indices: array[0..29] of Integer = (0,1,2, 0,2,3,
    0,4,5, 0,5,1, 1,5,6, 1,6,2, 2,6,7, 2,7,3, 3,7,4, 3,4,0);
var
  I, J: Integer;
  HalfWidth, Extend, DirectionX, DirectionY: TGuiFloat;
  LengthValue, NormalX, NormalY: TGuiFloat;
  Vertices: array[0..7] of TSDL_Vertex;
begin
  if (AWidth <= 0) OR (AColor.A = 0) then
    Exit;

  if (Abs(AStart.X - AEnd.X) < 0.01) OR (Abs(AStart.Y - AEnd.Y) < 0.01) then
  begin
    inherited DrawLine(AStart, AEnd, AWidth, AColor);
    Exit;
  end;

  LengthValue:=Sqrt(Sqr(AEnd.X - AStart.X) + Sqr(AEnd.Y - AStart.Y));
  DirectionX:=(AEnd.X - AStart.X) / LengthValue;
  DirectionY:=(AEnd.Y - AStart.Y) / LengthValue;
  NormalX:=-DirectionY;
  NormalY:=DirectionX;
  { A filled stroke with a transparent fringe avoids gaps between parallel
    SDL lines and keeps diagonal glyph thickness independent of direction. }
  for I:=0 to 7 do
  begin
    J:=I MOD 4;
    HalfWidth:=AWidth / 2;
    Extend:=0;
    if I >= 4 then
    begin
      HalfWidth:=HalfWidth + 0.75;
      Extend:=0.75;
    end;
    if J >= 2 then HalfWidth:=-HalfWidth;
    if (J = 0) OR (J = 3) then
    begin
      Vertices[I].position.x:=AStart.X - DirectionX * Extend + NormalX * HalfWidth;
      Vertices[I].position.y:=AStart.Y - DirectionY * Extend + NormalY * HalfWidth;
    end else
    begin
      Vertices[I].position.x:=AEnd.X + DirectionX * Extend + NormalX * HalfWidth;
      Vertices[I].position.y:=AEnd.Y + DirectionY * Extend + NormalY * HalfWidth;
    end;
    Vertices[I].color.r:=AColor.R / 255;
    Vertices[I].color.g:=AColor.G / 255;
    Vertices[I].color.b:=AColor.B / 255;
    Vertices[I].color.a:=AColor.A / 255;
    if I >= 4 then Vertices[I].color.a:=0;
    Vertices[I].tex_coord.x:=0;
    Vertices[I].tex_coord.y:=0;
  end;
  SDL_SetRenderDrawBlendMode(FRenderer, SDL_BLENDMODE_BLEND);
  if NOT SDL_RenderGeometry(FRenderer, nil, @Vertices[0], 8, @Indices[0], Length(Indices)) then
    inherited DrawLine(AStart, AEnd, AWidth, AColor);
end;

procedure TGuiSDL3Canvas.DrawImage(ATexture: TGuiTexture; const ARect: TGuiRect);
var
  Rect: TSDL_FRect;
begin
  if NOT Assigned(ATexture) then
    Exit;

  Rect:=ToSDLRect(ARect);
  SDL_RenderTexture(FRenderer, PSDL_Texture(ATexture), nil, @Rect);
end;

procedure TGuiSDL3Canvas.DrawImagePart(ATexture: TGuiTexture; const ASourceRect, ADestRect: TGuiRect);
var
  SourceRect: TSDL_FRect;
  DestRect: TSDL_FRect;
begin
  if NOT Assigned(ATexture) then
    Exit;

  SourceRect:=ToSDLRect(ASourceRect);
  DestRect:=ToSDLRect(ADestRect);
  SDL_RenderTexture(FRenderer, PSDL_Texture(ATexture), @SourceRect, @DestRect);
end;

procedure TGuiSDL3Canvas.DrawText(const AText: String; const ARect: TGuiRect; const AColor: TGuiColor; AHorizontalAlign: TGuiHorizontalTextAlign;
  AVerticalAlign: TGuiVerticalTextAlign);
var
  Font: TGuiSDLTTFFontRenderer;
begin
  Font:=ActiveFont;
  if Assigned(Font) then
    Font.DrawText(FRenderer, AText, ARect, AColor, AHorizontalAlign, AVerticalAlign);
end;

function TGuiSDL3Canvas.MeasureText(const AText: String): TGuiSize;
var
  Font: TGuiSDLTTFFontRenderer;
begin
  Result:=GuiSize(0, 0);

  Font:=ActiveFont;
  if Assigned(Font) then
    Result:=Font.MeasureText(AText);
end;

procedure TGuiSDL3Canvas.PushClipRect(const ARect: TGuiRect);
var
  Rect: TSDL_Rect;
  OldRect: TSDL_Rect;
  OldEnabled: Boolean;
  LeftValue: Integer;
  TopValue: Integer;
  RightValue: Integer;
  BottomValue: Integer;
  OldRight: Integer;
  OldBottom: Integer;
begin
  Rect.x:=Round(ARect.Left);
  Rect.y:=Round(ARect.Top);
  Rect.w:=Round(ARect.Width);
  Rect.h:=Round(ARect.Height);

  OldEnabled:=SDL_RenderClipEnabled(FRenderer);
  if OldEnabled then
    SDL_GetRenderClipRect(FRenderer, @OldRect)
  else
  begin
    OldRect.x:=0;
    OldRect.y:=0;
    OldRect.w:=0;
    OldRect.h:=0;
  end;

  if Length(FClipRects) <= FClipCount then
  begin
    SetLength(FClipRects, FClipCount + 8);
    SetLength(FClipEnabled, FClipCount + 8);
  end;

  FClipRects[FClipCount]:=OldRect;
  FClipEnabled[FClipCount]:=OldEnabled;
  Inc(FClipCount);

  if OldEnabled then
  begin
    LeftValue:=Rect.x;
    TopValue:=Rect.y;
    RightValue:=Rect.x + Rect.w;
    BottomValue:=Rect.y + Rect.h;
    OldRight:=OldRect.x + OldRect.w;
    OldBottom:=OldRect.y + OldRect.h;

    if OldRect.x > LeftValue then
      LeftValue:=OldRect.x;

    if OldRect.y > TopValue then
      TopValue:=OldRect.y;

    if OldRight < RightValue then
      RightValue:=OldRight;

    if OldBottom < BottomValue then
      BottomValue:=OldBottom;

    Rect.x:=LeftValue;
    Rect.y:=TopValue;
    Rect.w:=RightValue - LeftValue;
    Rect.h:=BottomValue - TopValue;

    if Rect.w < 0 then
      Rect.w:=0;

    if Rect.h < 0 then
      Rect.h:=0;
  end;

  SDL_SetRenderClipRect(FRenderer, @Rect);
end;

procedure TGuiSDL3Canvas.PopClipRect;
var
  Rect: TSDL_Rect;
begin
  if FClipCount <= 0 then
  begin
    SDL_SetRenderClipRect(FRenderer, nil);
    Exit;
  end;

  Dec(FClipCount);

  if FClipEnabled[FClipCount] then
  begin
    Rect:=FClipRects[FClipCount];
    SDL_SetRenderClipRect(FRenderer, @Rect);
  end else
    SDL_SetRenderClipRect(FRenderer, nil);
end;

end.
